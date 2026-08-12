{
  description = "A very basic flake";

  inputs = {
    # nixpkgs before ~2026-04 shipped claude-code from npm (2.1.88 was yanked → 404).
    # Stay on a recent nixos-unstable; run `nix flake update` if claude-code fetch fails.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nvim-config = {
      url = "github:reilandeubank/nvim-config";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    ...
  } @ inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ({...}: {
          nixpkgs.config = {
            allowUnfree = true;
          };
        })
        ./configuration.nix
      ];
    };
  };
}
