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

    hermes-agent.url = "github:NousResearch/hermes-agent";
  };

  outputs = { self, nixpkgs, home-manager, mcp-servers-nix, hermes-agent, ... }:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ 
        mcp-servers-nix.overlays.default
      ];
    };
  in
  {
    homeConfigurations.dustin =
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

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
        pkgs = pkgs;
        specialArgs = {
          inherit hermes-agent;
        };

        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
             home-manager.extraSpecialArgs = {
               inherit mcp-servers-nix;
              };
              home-manager.users.dustin = import ./home.nix;
            }
          ];
        };
  };
}
