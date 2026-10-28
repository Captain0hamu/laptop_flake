# nixos-flake

[English](README.md) | 日本語

このマシン向けのNixOSとHome Managerの設定を、SDDMテーマ、仮想カメラのサポート、依存関係グラフのビューアーとともに管理するリポジトリです。共通の開発用シェルとTor Browserも用意しています。

## 目次

- [構成](#構成)
- [セットアップ](#セットアップ)
- [よく使うコマンド](#よく使うコマンド)
- [Tor開発用シェル](#tor開発用シェル)
- [アセットと再現性](#アセットと再現性)
- [依存関係グラフ](#依存関係グラフ)
- [スピーカーとログイン画面](#スピーカーとログイン画面)

## 構成

- `flake.nix`: NixOSとHome Managerのエントリーポイント、および `local.nix` の読み込み処理。
- `configuration.nix`: ホストのシステムモジュールを読み込みます。
- `local.nix`: パスワードやGitのユーザー情報などを保存します。Gitの管理対象外です。
- `local.nix.example`: `local.nix` のテンプレート。
- `home/`: Home Managerのモジュールとプロファイル。
- `files/`: Nixモジュールから参照するファイル。
- `modules/nixos/`: 起動、ブートローダー、デスクトップなどのNixOSモジュール。
- `scripts/nixos-functions.sh`: `environment.interactiveShellInit` で読み込むシェル関数。

## セットアップ

まだ `local.nix` がない場合はテンプレートをコピーし、最初の再ビルド前に値を変更してください。

```bash
cp -n local.nix.example local.nix
$EDITOR local.nix
```

`local.nix` はGitの管理対象外で、flakeからは直接参照できません。そのため絶対パスで読み込んでおり、評価には `--impure` が必要です。再ビルド用の関数は自動で `--impure` を付けますが、`nixos-rebuild` や `home-manager` を直接実行する場合は自分で付けてください。`--impure` がないと評価に失敗し、`--impure` があっても `local.nix` がない場合は、管理対象の `local.nix.example` が使われます。

**サンプルのパスワードは使わないでください。** 両方のハッシュは公開されているパスワード `changeme` に対応しています。設定を適用する前に固有のパスワードハッシュに変更し、実際の `local.nix` や秘密鍵をコミットしないでください。Nixストアの内容は他のローカルユーザーから読める場合があるため、ストアパスになる値に平文の秘密情報を含めないでください。

## よく使うコマンド

| コマンド | 用途 |
| --- | --- |
| `drybuild` | システムを切り替えずにビルドを確認します。 |
| `rebuild_n_switch` | NixOSの設定をビルドして適用します。 |
| `loadgen` | 設定をビルドし、次回起動時に使うようにします。 |
| `switch-dev`, `switch-lab` | 対応するHome Managerプロファイルを適用します。 |
| `build-dev`, `build-lab` | Home Managerプロファイルを適用せずにビルドします。 |
| `tor-start`, `tor-stop` | 共通のTorクライアントを起動・停止します。 |
| `tor-shell` | 共通のTor開発用シェルに入ります。 |

シェル関数のデフォルト設定は次のとおりです。

```bash
NIXOS_FLAKE_DIR=/home/nix/nixos-flake
NIXOS_FLAKE_HOST=nixos
```

`rebuild_n_switch --remote` を使うと、ローカルで評価し、このマシンにsudoで結果を適用します。ビルド済みのローカルシステムがあれば再利用し、なければ `local.nix` の `remoteBuildHost`（または環境変数 `NIXOS_BUILD_HOST`）で指定したSSHホストでビルドします。利用前にビルダーの公開署名鍵を `remoteBuildPublicKeys` に設定し、ローカルの設定を適用してください。ビルダーは出力に署名し、対象アーキテクチャに対応し、実行ユーザーからのSSH接続を受け付ける必要があります。入力と出力が共有されるため、信頼できるビルダーだけを使ってください。`--remote` を付けない場合はローカルでビルドします。

ログイン名は `razero`（UID 1000）です。既存のパスやVMのディスクマウントを維持するため、ホームディレクトリは `/home/nix` のままです。Home Managerのプロファイルは `razero@dev` と `razero@lab` です。復旧用アカウント `razero-trial` はUID 1001、ホームディレクトリ `/home/razero` を使い、メインのHome Managerプロファイルは適用されません。

## Tor開発用シェル

Tor Browserはシステムパッケージとしてインストールされ、ブラウザ自身の通信をTor経由にします。以下の開発用シェルはコマンドラインツール向けで、Tor Browserのクライアントは使用・操作しません。

### クライアントの起動と確認

どのディレクトリからでも、Torクライアントをバックグラウンドで起動できます。

```bash
tor-start
```

ログを確認し、今回の起動について `Bootstrapped 100%` と表示されるまで待ってください。ログは起動のたびに残ります。Ctrl+Cでログの表示を終了しても、Torは動き続けます。

```bash
tail -f "$HOME/.local/share/tor-dev-shell/tor.log"
```

続いて共通のシェルに入ります。作業ディレクトリは変わらず、そのディレクトリにあるプロジェクトの開発用シェルも読み込まれません。

```bash
tor-shell
```

`tor-start` と `tor-shell` では、端末のサイズに合わせたバナーが表示されます。端末のサイズを変更した後は、シェル内で `tor-banner` を実行すると再表示できます。環境変数 `NO_COLOR` を設定すると色を無効にできます。

これらの関数はシステムのシェル設定で読み込まれます。再ビルド前のBashセッションですぐに使うには、`source /home/nix/nixos-flake/scripts/nixos-functions.sh` を実行してください。シェルには次のコマンドでも直接入れます。

```bash
nix develop /home/nix/nixos-flake#tor --impure
```

このシェルでは `tor`、`torsocks`、`curl` が使えますが、Torの起動やコマンドのTor経由への切り替えは自動では行いません。対応するコマンドを明示的にTor経由で実行します。

```bash
torsocks curl https://check.torproject.org/api/ip
```

レスポンスに `"IsTor": true` と表示されればTor経由です。`exit` でシェルから出てもTorクライアントは停止しません。使い終わったら別途停止してください。

```bash
tor-stop
```

クライアントは `127.0.0.1:9050` を使い、状態、PIDファイル、ログを `~/.local/share/tor-dev-shell/` に保存します。すでに別のTorクライアントがポート9050で待ち受けている場合は、2つ目を起動せずにそちらを使ってください。`tor-stop` が停止するのは `tor-start` で起動したクライアントだけです。

**プライバシー上の注意:** 通常のコマンドは自動的にプロキシ経由になりません。また、`torsocks` はすべてのアプリやUDP通信を扱えるわけではありません。このシェルはネットワークを分離せず、直接通信も遮断しません。プロジェクト固有の開発用シェルと共通Torシェルも自動では合成されません。

## アセットと再現性

SDDMのアニメーション背景は、`files/sddm/Gently-Blur-SDDM-6/AnimatedBackground.qml` からの相対パスで `anim/frames.js` と `anim/*.jpg` を読み込みます。全26フレームと `anim/scanlines.png` はこのリポジトリで管理しており、`~/Downloads` は参照しません。デスクトップモジュールはビルド時にテーマ全体をNixストアへコピーします。

`files/fonts/BankGothic.ttf` はGRUB、Plymouth、SDDMで共通して使うフォントです。Plymouthの元画像は `files/plymouth/gtg/assets/` にあります。これらはホームディレクトリへのシンボリックリンクではなく、リポジトリ内の通常のファイルです。

Neovimのプラグインと、Bash、C、C#、C++、CSS、HTML、JavaScript、JSON、Nix、Python用のTree-sitterパーサーは `home/neovim.nix` で宣言しています。バージョンは `flake.lock` に従い、Neovim起動時にプラグインのクローンや `TSUpdate` は実行しません。`dl-msc` 関数もNix管理の `yt-dlp` を使い、`$HOME/Downloads/m4a` に出力します。

Nixpkgs、Home Manager、上流のGRUBテーマは、`flake.lock` でバージョンを固定した外部入力です。このチェックアウト外のファイルには依存しません。一方、`local.nix`、ホームディレクトリとユーザー名、`hardware-configuration.nix` と `modules/nixos/filesystems.nix` のディスクUUIDやマウント設定はホスト固有です。別の場所にチェックアウトした場合は、impureなflake評価時に `NIXOS_FLAKE_DIR` にその絶対パスを設定してください。

## 依存関係グラフ

`graph/showcase.html` では、カスタムのGRUB、Plymouth、SDDM、ターミナル、エディターを対話的に確認できます。依存関係マップへのリンクや、関連する設定の表示も用意しています。ソースのスナップショットやテーマのプレビューの更新方法は `graph/README.md` を参照してください。

`graph/index.html` は、このリポジトリのflake構造を表示する単体で動作するビューアーです。設定の変更後や `nix flake update` の実行後は、次のコマンドでデータを再生成できます。

```bash
./graph/update.sh
xdg-open graph/index.html
```

## スピーカーとログイン画面

`home/easyeffects.nix` は、内蔵のFujitsu/Raptor Lake Speaker出力専用に、控えめなEQと緩やかなコンプレッサーのプリセットを設定します。EasyEffectsは必要なときに手動で起動してください。このプリセットはヘッドホンやHDMIには適用されません。EQは実測に基づく補正ではないため、安全な音量で聴きながらEasyEffectsの6バンドを調整してください。プリセットとデバイス別の自動読み込みファイルは `~/.local/share/easyeffects/` にあります。

SDDM、Plasmaのロック画面、KSplashは、`files/sddm/Gently-Blur-SDDM-6/anim` にある同じアニメーション背景を使います。ロック画面は復旧時の動作を含め、Plasma標準の認証操作を維持しています。パスワードによるロック解除時とPlasmaの起動スプラッシュでは、デスクトップへフェード・ズームする演出が入ります。SDDMでもログイン成功時に同じ演出が始まりますが、完了前にディスプレイマネージャーが終了する場合があります。
