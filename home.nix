{ config, lib, pkgs, mcp-servers-nix, ... }:

let
  mcpConfig =
    (mcp-servers-nix.lib.evalModule pkgs {
      programs = {
        playwright.enable = true;
        context7.enable = true;
        github = {
          enable = true;
          env = {
            GITHUB_TOOLSETS = "context,repos,issues,pull_requests";
          };
          passwordCommand = {
            GITHUB_PERSONAL_ACCESS_TOKEN = [
              "${pkgs.gh}/bin/gh"
              "auth"
              "token"
            ];
          };
        };
      };
    }).config;
in
{
  imports = [ ];

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

    context = ''
      # Communication Rules

      - Never use performative agreement or validation phrases when the user reports a problem, corrects you, or expresses frustration.
      - Never say "You're right", "You are right", or variants of those phrases as a conversational opener or apology substitute.
      - Those phrases usually make the user more frustrated because they delay the actual fix.
      - The only helpful response is to identify the problem, fix it, and communicate clearly what changed or what is blocking the fix.
      - Keep responses concise and direct.
      - Talk like a senior engineer in a design review.
      - Prefer formulas, examples, and clear decisions over paragraphs.
      - Do not over-explain unless the user asks for detail.
    '';
  };

  programs.bash.enable = true;

  systemd.user.services.beeper-life-guardian = {
    Unit = {
      Description = "Beeper Desktop for Hermes scheduled messaging";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.beeper}/bin/beeper";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.zsh = {
    enable = true;
    sessionVariables = {
      ZDOTDIR = "\${HOME}/.config/zsh";
    };
    initExtra = "";
  };
}
