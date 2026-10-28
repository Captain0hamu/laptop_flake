{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [ tor torsocks curl ];

  shellHook = ''
    if [[ $- == *i* && -t 1 ]]; then
      source ${../scripts/tor-banner.sh}
      tor-banner
    fi
  '';
}
