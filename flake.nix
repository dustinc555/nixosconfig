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

    # Fix OpenClaw gateway packaging: ensure bundled extension manifests are installed.
    # Upstream source ships `extensions/*/openclaw.plugin.json`, but the built
    # `dist/extensions/*` output can be missing them, which breaks CLI configure
    # flows (e.g. LINE runtime not initialized).
    openclawGatewayManifestsOverlay = final: prev: {
      openclaw-gateway = prev.openclaw-gateway.overrideAttrs (old: {
        installPhase = (old.installPhase or "") + ''

          # Ensure bundled extension manifests are present in the built output.
          if [ -d "${old.src}/extensions" ] && [ -d "$out/lib/openclaw/dist/extensions" ]; then
            echo "[nix] installing bundled extension manifests"
            count=0
            for mf in "${old.src}"/extensions/*/openclaw.plugin.json; do
              [ -e "$mf" ] || continue
              extName="$(basename "$(dirname "$mf")")"
              targetDir="$out/lib/openclaw/dist/extensions/$extName"
              if [ -d "$targetDir" ]; then
                cp -f "$mf" "$targetDir/openclaw.plugin.json"
                count=$((count + 1))
              fi
            done
            echo "[nix] installed $count extension manifests"
          fi

          # Ensure bundled skills are available (doctor/configure expects them).
          if [ -d "${old.src}/skills" ] && [ -d "$out/lib/openclaw" ] && [ ! -d "$out/lib/openclaw/skills" ]; then
            echo "[nix] installing bundled skills"
            cp -r "${old.src}/skills" "$out/lib/openclaw/"
          fi
        '';
      });
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ 
        nix-openclaw.overlays.default
        mcp-servers-nix.overlays.default
        openclawGatewayManifestsOverlay
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
          inherit mcp-servers-nix nix-openclaw;
        };
      };

    nixosConfigurations.default =
      nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = pkgs;

        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
            home-manager.extraSpecialArgs = {
              inherit mcp-servers-nix nix-openclaw;
            };
            home-manager.users.dustin = import ./home.nix;
          }
        ];
      };
  };
}
