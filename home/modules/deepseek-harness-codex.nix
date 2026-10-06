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
      default = "0.1.0-rc.8";
      description = "DeepSeek Harness npm version installed for the Codex OAuth plugin.";
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
          runtime="$DSH_HOME/runtime"
          dsh_bin="$runtime/node_modules/.bin/dsh"

          if [ ! -x "$dsh_bin" ]; then
            echo "Installing DeepSeek Harness ${cfg.dshVersion} into $runtime ..."
            mkdir -p "$runtime"
            npm install --prefix "$runtime" --no-save --package-lock=false ${lib.escapeShellArg dsh}
          fi

          # The plugin installer delegates to `dsh plugin add`; putting the
          # exact compatible runtime first prevents it from downloading the
          # current (and potentially incompatible) DSH release via npx.
          export PATH="$runtime/node_modules/.bin:$PATH"
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
          auth_bin="$DSH_HOME/profiles/web/node_modules/.bin/dsh-codex-oauth"
          if [ ! -x "$auth_bin" ]; then
            echo "Codex OAuth plugin is not installed. Run dsh-codex-install first." >&2
            exit 1
          fi
          # Runs OpenAI's device-code OAuth flow and saves the result in $DSH_HOME.
          exec "$auth_bin" login --method device "$@"
        '';
      })
      (pkgs.writeShellApplication {
        name = "dsh-codex-web";
        runtimeInputs = [ pkgs.nodejs_24 pkgs.pnpm ];
        text = ''
          ${withDshHome}
          dsh_bin="$DSH_HOME/runtime/node_modules/.bin/dsh"
          if [ ! -x "$dsh_bin" ]; then
            echo "DeepSeek Harness is not installed. Run dsh-codex-install first." >&2
            exit 1
          fi
          exec "$dsh_bin" web "$@"
        '';
      })
    ];
  };
}
