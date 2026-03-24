{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;


  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [
    mesa
  ];

  services.xserver.videoDrivers = ["amdgpu"];


  # Fix for horrific slow boot
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "performance";

  boot.kernelModules = [ "acpi_cpufreq" ];
  #
  

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  virtualisation.docker.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
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

    openclaw-gateway

    archipelago

    google-chrome 
    
    unzip
    curl

    vim
    vscode
    docker
    element-desktop
    wget
    discord
    steam
    
    steam-run
    
    nodejs
    
    git
    meld
    sublime-merge

    p7zip
    xorg.xkill

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

  system.stateVersion = "22.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
