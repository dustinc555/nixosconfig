{
  description = "Dustin NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, mcp-servers-nix, nix-openclaw, ... }:
  let
    system = "x86_64-linux";
  in
  {
    homeConfigurations.dustin =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        modules = [
          ./home.nix
        ];

        extraSpecialArgs = {
          inherit mcp-servers-nix;
        };
      };

    nixosConfigurations.default =
      nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ nix-openclaw.overlays.default ];
        };

        modules = [
          ./configuration.nix
        ];
      };
  };
}
