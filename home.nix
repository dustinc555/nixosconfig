{ config, lib, pkgs, mcp-servers-nix, nix-openclaw, ... }:

let
  mcpConfig =
    (mcp-servers-nix.lib.evalModule pkgs {
      programs = {
        playwright.enable = true;
        context7.enable = true;
      };
    }).config;
in
{
  imports = [
    nix-openclaw.homeManagerModules.openclaw
  ];

  home = {
    username = "dustin";
    homeDirectory = "/home/dustin";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  programs.mcp = {
    enable = true;
    servers = mcpConfig.settings.servers // {
      atlassian = {
        type = "sse";
        url = "https://mcp.atlassian.com/v1/mcp";
      };
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
  };

  programs.bash.enable = true;
  programs.bash.initExtra = ''
    # Load OpenClaw gateway token for interactive commands.
    if [ -f "$HOME/.config/openclaw/openclaw.env" ]; then
      set -a
      . "$HOME/.config/openclaw/openclaw.env"
      set +a
    fi
  '';

  programs.openclaw = {
    enable = true;

    # Use the gateway package directly (avoids the openclaw wrapper pointing at
    # an older openclaw-gateway store path).
    package = pkgs.openclaw-gateway;

    # IMPORTANT: don't let nix-openclaw manage workspace docs.
    # When enabled, it symlinks AGENTS.md/SOUL.md/TOOLS.md from the Nix store
    # into the workspace, which is read-only and causes EROFS when the agent
    # tries to update them.
    documents = null;

    instances.default = {
      enable = true;

      package = pkgs.openclaw-gateway;

      # Minimal, stable config: local gateway only.
      # Token comes from systemd EnvironmentFile (not the Nix store).
      config = {
        gateway = {
          mode = "local";
          port = 18789;
          bind = "loopback";
          auth = {
            mode = "token";
            token = "\${OPENCLAW_GATEWAY_TOKEN}";
          };
          tailscale = {
            mode = "off";
            resetOnExit = false;
          };
        };

        # `openclaw onboard` currently expects LINE to be available.
        # Without this, it errors with: "LINE runtime not initialized - plugin not registered".
        plugins = {
          entries = {
            line = {
              enabled = true;
            };
          };
        };
      };
    };
  };

  # Clean slate helpers (do not touch ~/.openclaw automatically).
  home.activation.openclawRemoveLegacyUserUnit = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    set -euo pipefail

    unit="$HOME/.config/systemd/user/openclaw-gateway.service"
    if [ -e "$unit" ] && [ ! -L "$unit" ]; then
      rm -f "$unit"
    fi
  '';

  home.activation.openclawEnvFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    envDir="$HOME/.config/openclaw"
    envFile="$envDir/openclaw.env"

    if [ ! -f "$envFile" ]; then
      mkdir -p "$envDir"
      umask 077
      token="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
      printf 'OPENCLAW_GATEWAY_TOKEN=%s\n' "$token" > "$envFile"
    fi
  '';

  # Seed writable workspace docs (regular files, not Nix store symlinks).
  home.activation.openclawWritableDocs = lib.hm.dag.entryAfter [ "openclawDirs" ] ''
    set -euo pipefail

    ws="$HOME/.openclaw/workspace"
    mkdir -p "$ws"

    for f in AGENTS.md SOUL.md TOOLS.md; do
      target="$ws/$f"

      # Replace store symlink with a real file.
      if [ -L "$target" ]; then
        rm -f "$target"
      fi

      if [ ! -e "$target" ]; then
        cp -f "${./openclaw-documents}/$f" "$target"
        chmod 0644 "$target" || true
      fi
    done
  '';

  home.activation.openclawStatePerms = lib.hm.dag.entryAfter [ "openclawDirs" ] ''
    if [ -d "$HOME/.openclaw" ]; then
      chmod 700 "$HOME/.openclaw" || true
    fi
  '';


  systemd.user.services.openclaw-gateway.Service.EnvironmentFile = "%h/.config/openclaw/openclaw.env";
  systemd.user.services.openclaw-gateway.Install.WantedBy = [ "default.target" ];
}
