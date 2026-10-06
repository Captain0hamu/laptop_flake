{ config, lib, pkgs, ... }:

let
  cfg = config.programs.deepseekHarnessCodex;
  inherit (lib) mkEnableOption mkIf mkOption types;

  # This integration is intentionally kept separate from Codex CLI credentials.
  # The Harness plugin owns and refreshes its OAuth grant in DSH_HOME.
  withDshHome = ''
    export DSH_HOME=${lib.escapeShellArg cfg.dshHome}
  '';
  dsh = "@deepseek-ai/dsh@${cfg.dshVersion}";
in
{
  options.programs.deepseekHarnessCodex = {
    enable = mkEnableOption "DeepSeek Harness with the community Codex OAuth adapter";

    dshHome = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.dsh";
      description = ''
        Directory used by DeepSeek Harness for its profiles and credentials. The
        Codex OAuth plugin stores its refreshable credential in
        {file}`$DSH_HOME/codex-oauth.json`; it does not read Codex CLI's
        {file}`~/.codex/auth.json`.
      '';
    };

    dshVersion = mkOption {
      type = types.str;
      default = "0.1.0-rc.6";
      description = "DeepSeek Harness npm version used by the wrapper commands.";
    };

    pluginUrl = mkOption {
      type = types.str;
      default = "https://github.com/birat-chapagain/dsh-codex-oauth/releases/download/v0.1.5/dsh-codex-oauth.tgz";
      description = "Pinned release archive for the community Codex OAuth plugin.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "dsh-codex-install";
        runtimeInputs = [ pkgs.nodejs_24 pkgs.pnpm ];
        text = ''
          ${withDshHome}
          # The plugin's installer configures its required pnpm build approvals
          # and adds the plugin to the web profile. This changes only $DSH_HOME.
          exec npx --yes ${lib.escapeShellArg cfg.pluginUrl} install
        '';
      })
      (pkgs.writeShellApplication {
        name = "dsh-codex-login";
        runtimeInputs = [ pkgs.nodejs_24 pkgs.pnpm ];
        text = ''
          ${withDshHome}
          # Runs OpenAI's device-code OAuth flow and saves the result in $DSH_HOME.
          exec npx --yes dsh-codex-oauth login --method device "$@"
        '';
      })
      (pkgs.writeShellApplication {
        name = "dsh-codex-web";
        runtimeInputs = [ pkgs.nodejs_24 pkgs.pnpm ];
        text = ''
          ${withDshHome}
          exec npx --yes ${dsh} web "$@"
        '';
      })
    ];
  };
}
