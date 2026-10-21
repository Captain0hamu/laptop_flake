# nix → razero

移行済みです。以下は実施手順と復旧方法の記録です。
移行スクリプトを再実行する必要はありません。通常のrebuildを利用できます。

| ログイン名 | UID | ホーム |
| --- | --- | --- |
| razero（旧 nix） | 1000 | /home/nix |
| razero-trial（試用アカウント） | 1001 | /home/razero |

ホーム、VMイメージ、マウント先は移動しません。所有者のUIDも維持します。
旧 nix のユーザーパッケージとHome Manager設定をrazeroに適用します。

## 実行

1. 作業を保存し、VMを停止します。TTY（Ctrl+Alt+F3など）でrootとして
   ログインできることを確認し、そのrootセッションを残します。
2. nixのデスクトップとrazeroの試用シェルからログアウトします。
3. rootのTTYで `pgrep -a -u 1000,1001` を確認します。プロセスが残る場合は
   終了元を確認してください。作業保存済みであれば
   `loginctl terminate-user nix` と `loginctl terminate-user razero` で
   各ユーザーの残りのプロセスを終了できます。この操作はCodexも切断します。
4. rootのTTYで次を実行します。

```bash
bash /home/nix/nixos-flake/scripts/migrate-user-to-razero.sh \
  /nix/store/cxvrlm3qbc6jpzmwnbfr04j4pi45rhdd-nixos-system-nixos-26.11.20261011.7fd4004
```

スクリプトは実行中プロセスがあると停止します。改名前にアカウント情報と
NixOSのユーザー管理状態を `/root/razero-migration.*` に保存します。
データの移動・削除・再帰的なchownは行いません。

5. rootのTTYを残したまま、別のTTYまたはログイン画面でrazeroを試します。
   `id` がUID 1000、`echo "$HOME"` が `/home/nix` になることを確認します。
   sudo、デスクトップ、Home Manager、既存VMの表示・起動も確認します。

## 復旧

世代のロールバックだけでは手動のアカウント改名は戻りません。
適用後に戻す場合は両ユーザーからログアウトし、rootのTTYで操作します。
まず `getent passwd nix razero razero-trial` で途中状態を確認してください。
両方の改名が済んでいる場合の逆操作は次のとおりです。

```bash
usermod -l nix razero
usermod -l razero razero-trial
migration_backup=$(cat /root/razero-migration-latest)
migration_previous=$(cat "$migration_backup/previous-system")
nix-env -p /nix/var/nix/profiles/system --set "$migration_previous"
"$migration_previous/bin/switch-to-configuration" switch
```

旧構成に戻した後は、このリポジトリの移行設定も元に戻すまでrebuildを行わないでください。
試用アカウントとそのホームは、移行確認が終わるまで保持します。
