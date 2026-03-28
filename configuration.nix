{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [ mesa ];
  services.xserver.videoDrivers = ["amdgpu"];

  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  boot.kernelModules = [ "acpi_cpufreq" ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;
  virtualisation.docker.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.tailscale.enable = true;

  security.auditd.enable = true;

  # optional but required for exec logging
  security.audit.enable = true;

  # define rules
  security.audit.rules = [
    "-a always,exit -F arch=b64 -S execve"
  ];

  users.users.dustin = {
    isNormalUser = true;
    description = "Dustin Cook";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
      kdePackages.kate
      godot_4
      spotify
    ];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "dustin";

  environment.systemPackages = with pkgs; [
    home-manager
    home-manager

    archipelago

    google-chrome 
    google-cloud-sdk
    
    unzip
    curl

    vim
    vscode
    docker
    element-desktop
    telegram-desktop
    wget
    discord
    steam
    
    steam-run
    
    nodejs
    
    git
    meld
    sublime-merge

    p7zip
    xkill

    pandoc
    texlive.combined.scheme-full

    wineWow64Packages.stable

    asciiquarium-transparent
    crawl

    (python3.withPackages (ps: [
      ps.beautifulsoup4
      ps.folium
      ps.progressbar2
      ps.ijson
      ps.requests
      ps.black
      ps.numpy
      ps.pandas
      ps.aiohttp
      ps.django
      ps.mypy
      ps.django-stubs
      ps.pywebview
      ps.screeninfo
      ps.scipy
      ps.pillow
      ps.matplotlib
      ps.scikit-learn
      ps.torch
      ps.torchvision
      ps.tqdm
      ps.discordpy
    ]))

    libreoffice-qt
    zsh
    jdk17

    nodejs
    yarn
    yarn2nix

    graphviz
    gotop
    gimp

    cool-retro-term
    ghostty

    unityhub
  ];

  environment.sessionVariables = {
    BUN_INSTALL = "$HOME/.bun";
    PATH = "$HOME/.bun/bin:$PATH";
  };

  programs.nix-ld.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  system.autoUpgrade.enable = true;
  
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
    };
    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "aussiegeek";
    };
  };

  users.defaultUserShell = pkgs.zsh;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8888 38281 ];
  };

  services.ollama.enable = true;

  system.stateVersion = "22.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
