{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    with import nixpkgs { system = "x86_64-linux"; };
    let
      python = pkgs.python310;
      overrides = poetry2nix.overrides.withDefaults (self: super: {
      });
      pythonBuildInputs = with pkgs.python310Packages; [
      ];
    in
    {
      APP_UNDERSCORE = pkgs.poetry2nix.mkPoetryApplication {
        inherit overrides python;
        projectDir = ./.;
        buildInputs = pythonBuildInputs;
      };

      dockerImage = pkgs.dockerTools.buildImage {
        name = "APP-DASH";
        config = {
          Cmd = [ "${APP_UNDERSCORE}/bin/APP_UNDERSCORE" ];
        };
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          poetry
          python310Packages.autopep8
          (pkgs.poetry2nix.mkPoetryEnv {
            inherit overrides python;
            projectDir = ./.;
            editablePackageSources = {
              manager = ./.;
            };
          })
        ] ++ pythonBuildInputs;
      };
    };

}
