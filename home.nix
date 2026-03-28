{ config, lib, pkgs, mcp-servers-nix, ... }:

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
  };

  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    sessionVariables = {
      ZDOTDIR = "\${HOME}/.config/zsh";
    };
    initExtra = "";
  };
}
