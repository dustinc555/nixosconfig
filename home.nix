{ lib, pkgs, mcp-servers-nix, ... }:

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
  nixpkgs.overlays = [
    mcp-servers-nix.overlays.default
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
}
