# 独自パッチと flake 更新時の確認

このドキュメントは、このリポジトリのアップストリーム依存の変更を更新時に
点検するためのメモです。特にロック画面の QML は、ビルドに成功しても実行時に
表示や認証後の遷移が壊れる可能性があります。更新・切り替えの前に、作業を
保存し、以前の NixOS generation から起動できる状態を残してください。

## 基本的な仕組み

`flake.lock` は nixpkgs などの入力を固定します。通常の rebuild は固定された
バージョンを使いますが、`nix flake update` で入力を更新すると、パッチ対象の
ソース、Qt / KDE API、NixOS のオプションも変わり得ます。

`overrideAttrs` / overlay の変更は Nix store 内の完成品を直接書き換えるのでは
なく、パッケージのビルド時にソースやビルド手順へ適用されます。パッチの一行が
変わっただけでも、そのパッケージや依存先の再ビルドが必要になることがあります。
特に `plasma-desktop` は大きいため、QML の変更でもコンパイルに時間がかかります。

QML は Qt の UI 記述言語であり Plasma 専用ではありません。ただし、この設定の
QML は Qt のほか KDE / Plasma の部品・プロパティにも依存します。SDDM と
Plasma ロック画面は別プロセス・別パッケージなので、片方だけ壊れることもあります。

## 独自変更の一覧

| 対象 | 適用元と目的 | 更新時に注意する点 |
| --- | --- | --- |
| Plasma ロック画面 | `modules/nixos/plasma-customisation.nix` が `files/plasma/patch-lockscreen.py` で上流の `LockScreenUi.qml` を変更。共通背景、単一セッション時のユーザー一覧非表示、認証後の遷移を追加 | `replace_once` は対象文字列がちょうど1回でなければビルドを失敗させる。文字列が一致しても、認証シグナルや QML の挙動が変わると実行時に解除できなくなる可能性がある |
| Plasma Kickoff | 同じ overlay で `files/plasma/kickoff.patch` と `LauncherHighlight.qml`、`LauncherToolButton.qml`、`LauncherTabButton.qml` を適用。ランチャーの選択色やボタンの見た目を変更 | 上流の QML / CMake の変更でパッチ適用に失敗したり、ビルドは通っても検索・表示・操作が壊れたりする可能性がある |
| SDDM / ロック / KSplash の背景 | `modules/nixos/desktop.nix` と上記 overlay が `files/sddm/Gently-Blur-SDDM-6/`、`files/plasma/SharedScene.qml`、`Splash.qml` を各パッケージへコピー | 画像26枚の順序は `anim/frames.js`、切り替え・暗幕は `AnimatedBackground.qml`、SDDM 側の暗幕は `Main.qml`、ロック / KSplash の暗幕は `SharedScene.qml`。Qt / KDE の QML 部品の変更、画像欠落、描画エラーに注意 |
| Breeze ベースの半透明テーマ | `home/plasma.nix` が `files/plasma/build-translucent-theme.py` で上流 SVG を加工 | 元 SVG のパスや `opacity:0.85` の個数が変わるとスクリプトが失敗する。元の見た目や SVG の構造が変わった場合は生成結果も目視確認 |
| GRUB | `modules/nixos/bootloader.nix` が `files/grub/keep-menu-on-boot.patch` を `grub2` に追加。テーマ表示中の明示的な起動操作でメニューを残す | GRUB のソース変更でパッチが当たらない可能性がある。ビルド成功後も次回起動時にメニュー・起動を確認。起動経路に関わるため以前の generation / 復旧手段を確保 |
| Plymouth | `modules/nixos/plymouth.nix` が `files/plymouth/` のテーマ生成と設定、`plymouth-quit` 等をカスタマイズ | テーマ生成、initrd・systemd のオプション、起動時の画面遷移を確認。上流オプション廃止時はエラーの説明を読み、代替の要否を確認する。以前 `boot.initrd.verbose` が廃止された例がある |
| Kamoso | `modules/nixos/packages.nix` が `modules/nixos/patches/kamoso-record-state.patch` を適用。録画状態を `Kamoso.isRecording` に統一 | パッチ失敗や QML API 変更のほか、録画開始・停止が実際にできるか確認 |
| v4l2loopback | `modules/nixos/boot.nix` の `overrideAttrs` で `DEPMOD=true` を指定 | 上流のビルド手順やカーネル更新との互換性を確認。ビルドだけでなく仮想カメラの読み込み・利用も確認 |

なお、過去の Mozc 向け Qt 互換バックポートは、新しい上流 Mozc に修正が
取り込まれたため削除済みです。再び Mozc のビルドが失敗した場合は、以前の
パッチを無条件に戻さず、まず上流ソースと nixpkgs のビルド手順を確認します。

## 更新前・更新後の手順

1. 開いているファイルを保存し、別の TTY へ切り替えてログインできることと、
   GRUB で以前の generation を選べることを確認します。`lsgen` で既存の
   generation を確認し、正常動作が確認できるまで削除や GC をしないでください。
   ロック画面のテスト前にも、未保存の作業を残さないようにします。
2. `git status --short` と `git diff` で現在の変更を把握してから `nix flake update`
   を実行します。`flake.lock` の変更は内容を確認してください。`nix-channel --update`
   はこの flake のロックファイルを更新しません。
3. まず切り替えずに評価・ビルドを確認します。リポジトリのディレクトリで:

   ```bash
   nix eval --impure --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
   nixos-rebuild build --flake .#nixos --impure
   python3 tests/test-lockscreen-patch.py
   ```

   最初のコマンドは評価のみでビルドしません。`nixos-rebuild build` はビルド
   しますがシステムを有効化しません。テストは Node.js を使用し、認証成功時の
   QML JavaScript の分岐を疑似的に確認します。テスト用の固定入力を使うため、
   新しい Plasma との互換性や実際の PAM 認証を保証するものではありません。

   リモートビルダーを使う場合は、実際のビルダーを `local.nix` に設定した上で
   以下を使えます。通常の `build` は成果物をローカルにもコピーします。ビルダー
   にはビルド入力・出力が送られるため、信頼できるホストだけを使用してください。

   ```bash
   build_host=$(nix eval --impure --raw --file local.nix --apply 'local: local.remoteBuildHost or ""')
   test -n "$build_host" && nixos-rebuild build --flake .#nixos --impure --build-host "$build_host"
   ```

   `rebuild_n_switch --remote` はビルド確認専用ではなく、最後に**ローカルへ
   適用する**コマンドです。`NIXOS_BUILD_HOST` を使う設定なら、その値を
   `--build-host` に指定することもできます。
4. 成功したら設定を適用し、再起動後に GRUB、Plymouth、SDDM ログイン、
   Plasma 起動を確認します。通常の `switch` だけでは現在のディスプレイ
   マネージャーや Plasma セッションが新しくならない場合があります。
5. 保存済みの状態で手動ロックし、正しいパスワードで戻れるか確認します。
   誤入力後の再試行、利用している場合は指紋認証、複数セッション時の
   ユーザー切り替えも確認します。あわせて Kickoff の検索・起動、Kamoso の
   録画、仮想カメラ、パネルやダイアログの見た目を確認します。

## 失敗したとき

### 評価・ビルド時

- `option ... has been removed` / `no longer has any effect`: エラーに示された
  NixOS オプションとリリースノートを確認します。廃止オプションを残したまま
  では評価できない場合があります。
- `patch ... FAILED` / `Plasma lockscreen changed: expected one ...`: 対象の上流
  ソースとローカルパッチを比較します。上流で修正済みなら不要なパッチは削除し、
  必要なら新しい上流構造に合わせて更新します。失敗を無視する変更で済ませず、
  元の認証・ユーザー操作を保っているか確認します。
- `expected nine Breeze background fills`: 上流の SVG と
  `files/plasma/build-translucent-theme.py` の前提を確認します。
- ビルドログが必要ならエラーに出た `.drv` パスに対して `nix log /nix/store/…drv`
  を実行します。リモートビルドのログはリモート側で確認が必要な場合があります。

### ログイン画面・ロック解除・起動時

ビルド成功は安全なログイン・ロック解除を保証しません。ログインできない場合は
TTY（通常 `Ctrl+Alt+F3` など）を試し、実際のログイン資格情報で入ります。
認証を迂回したり、ロック画面のプロセスを無理に終了したりせず、まず状態を
確認してください。ログは例えば以下で確認できます。

```bash
journalctl -b -u display-manager --no-pager
journalctl --user -b --no-pager | grep -Ei 'kscreenlocker|ksplash|qml|plasma'
```

TTY にも入れない場合や起動経路が壊れた場合は、GRUB の以前の NixOS
generation を選んで起動します。**GRUB から以前の世代を選ぶことと、今後の
デフォルト設定を恒久的に戻すことは別**です。復旧後、どの generation が
正常かを確認してから設定やブート選択を修復してください。再起動やログアウトで
未保存の作業は失われます。

### パッチを修正するときの注意

ロック画面はセキュリティ境界です。背景だけでなく `onSucceeded`、
`stopAuthenticating()`、失敗時の再試行、タイマー、指紋やパスワード不要時の
分岐にも独自変更が関係します。処理の順序や `Qt.quit()` を安易に変更せず、
上流の認証フローと比較してください。見た目の確認だけでなく、上記の手動
認証テストを行ってから以前の正常世代を削除するか判断します。
