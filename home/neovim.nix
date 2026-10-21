{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    withRuby = true;
    withPython3 = true;
    initLua = builtins.readFile ../files/nvim/init.lua;
    # Plugin revisions and parser sources follow the pinned nixpkgs input.
    plugins = with pkgs.vimPlugins; [
      monokai-pro-nvim
      mini-nvim
      rainbow-delimiters-nvim
      (nvim-treesitter.withPlugins (parsers: with parsers; [
        bash c c_sharp cpp css html javascript json nix python
      ]))
    ];
  };
}
