# Neovim の見た目

`Captain0hamu/nix_conf` の Neovim 設定から、表示に関する部分だけを移植。
設定は `files/nvim/init.lua`、依存は `home/modules/neovim.nix` で管理する。

- nightfox.nvim の **carbonfox**、灰色背景の選択範囲
- indent-blankline.nvim の虹色ガイド
- mini.indentscope の点線が伸びるスコープアニメーション
- rainbow-delimiters.nvim の括弧色分け（既存）
- mini.cursorword / statusline / tabline / icons / notify
- gitsigns.nvim の変更行表示
- JetBrains Mono Nerd Font（既存の Kitty のフォント指定は変更しない）

lazy.nvim / mini.deps / Mason は導入せず、プラグインは既存の
`flake.lock` に固定された nixpkgs から供給する。二重描画を避けるため、
mini.diff は追加せず、indent-blankline 側のスコープ表示は無効にする。
スコープアニメーションは特殊バッファや大きなファイルでは描画しない。

既存の LSP 起動・補完・診断・キー操作・2スペースのインデント幅、
クリップボードや描画負荷の設定、`NVIM_MINIMAL=1` は維持する。
参照先の Kitty／X11 タッチパッド対策はコピーせず、このマシンの
システム側の対策をそのまま使用する。

## 反映前の確認

```sh
nix build --impure '.#homeConfigurations."razero@dev".activationPackage' --no-link --print-out-paths
python3 tests/test-neovim-ui.py /nix/store/…-home-manager-generation
```

ビルドとテストだけでは設定は反映されない。普段使っている
Home Manager／NixOS の反映手順を実行し、Neovim を再起動する。
