{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    devenv.url = "github:cachix/devenv";
    flake-utils.url = "github:numtide/flake-utils";
    crane = {
      url = "github:ipetkov/crane";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , devenv
    , fenix
    , flake-utils
    , crane
    , ...
    } @ inputs:
    flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ] (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs) lib;

      rustVersion = "stable";
      fenixPkgs = fenix.packages.${system}.${rustVersion};
      toolchain = fenixPkgs.toolchain;
      craneLib = crane.lib.${system}.overrideToolchain toolchain;

      runtimeInputs = with pkgs; [ ];
      buildInputs = with pkgs; [
        mold
        clang
      ];

      src = craneLib.cleanCargoSource (craneLib.path ./.);

      commonArgs = {
        inherit buildInputs src;
        pname = "__pacakge__";
      };

      cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
        pname = "__pacakge__-deps";
      });

      __package__ = craneLib.buildPackage (commonArgs // {
        inherit cargoArtifacts;
      });
    in
    {
      packages = {
        default = __package__;
      };
      checks = {
        inherit __package__;

        __package__-clippy = craneLib.cargoClippy (commonArgs // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        });

        __package__-doc = craneLib.cargoDoc (commonArgs // {
          inherit cargoArtifacts;
        });

        __package__-fmt = craneLib.cargoFmt {
          inherit src;
        };
      };

      devShells.default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          ({
            languages.rust.enable = true;
            languages.rust.version = rustVersion;
            packages = with pkgs; [
              rustfmt
              cargo-whatfeatures
              cargo-watch
              fenixPkgs.clippy
            ] ++ runtimeInputs ++ buildInputs;
          })
        ];
      };
    });
}
