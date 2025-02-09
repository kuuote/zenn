{
  description = "Zenn Preview";

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      forAllSystems =
        fn:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: fn nixpkgs.legacyPackages.${system});
    in
    {
      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${pkgs.zenn-cli}/bin/zenn";
        };
      });
      devShells = forAllSystems (pkgs: rec {
        default = shell;
        shell = pkgs.mkShell {
          packages = [ pkgs.zenn-cli ];
        };
      });
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
}
