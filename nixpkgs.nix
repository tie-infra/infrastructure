{ inputs, lib, ... }:
{
  perSystem =
    { system, ... }:
    let
      packagesOverlay =
        final: _:
        lib.packagesFromDirectoryRecursive {
          inherit (final) callPackage;
          directory = ./packages;
        };

      nixpkgsArgs = {
        localSystem = {
          inherit system;
        };

        overlays = [
          inputs.steam-games.overlays.default
          inputs.btrfs-rollback.overlays.default
          packagesOverlay
          (import ./overlays/zapret/default.nix)
          (import ./overlays/sonarr/default.nix)
        ];

        config.allowUnfreePredicate =
          let
            allowUnfree = {
              steamworks-sdk-redist = true;
              satisfactory-server = true;
              rust-server = true;
              palworld-server = true;
              eco-server = true;
            };
          in
          pkg: builtins.hasAttr (lib.getName pkg) allowUnfree;

        # For rust-server.oxide.
        config.allowInsecurePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "dotnet-runtime"
            "dotnet-sdk"
          ]
          && lib.versions.major (lib.getVersion pkg) == "7";
      };

      nixpkgsFun = newArgs: import inputs.nixpkgs (nixpkgsArgs // newArgs);
    in
    {
      _module.args = {
        pkgs = nixpkgsFun { };
        pkgsCross = {
          x86-64 = nixpkgsFun { crossSystem.config = "x86_64-unknown-linux-gnu"; };
        };
      };
    };
}
