{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # Pin an older nixpkgs that still contains webkitgtk_4_0
    nixpkgs-25-05.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nvim-config = {
      url = "github:reilandeubank/nvim-config";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-25-05,
    ...
  } @ inputs: {
    overlays.default = final: prev: let
      old = import nixpkgs-25-05 {
        system = prev.stdenv.hostPlatform.system or prev.system;
        config = {allowUnfree = true;};
      };
    in {
      citrix_workspace = prev.citrix_workspace.overrideAttrs (oa: {
        # 1) feed legacy WebKitGTK 4.0 to satisfy libwebkit2gtk-4.0.so.37 & libjavascriptcoregtk-4.0.so.18
        buildInputs = (oa.buildInputs or []) ++ [old.webkitgtk_4_0];
        # 2) unmark the package as broken so evaluation proceeds
        meta = (oa.meta or {}) // {broken = false;};
      });
    };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ({...}: {
          nixpkgs.overlays = [inputs.self.overlays.default];
          nixpkgs.config = {
            allowUnfree = true;
          };
        })
        ./configuration.nix
      ];
    };
  };
}
