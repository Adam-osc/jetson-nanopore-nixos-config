{
  description = "A flake to deploy services for sequencing with MinION on Jetson Xavier NX devices.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
          cudaCapabilities = [ "7.2" ];
        };
      };
    in {
      nixosConfigurations.jetson = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/jetson/configuration.nix
        ];
      };
    };
}
