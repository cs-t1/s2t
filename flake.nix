{
  description = "spotify_to_tidal — sync Spotify playlists to Tidal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;

        runtimeDeps = ps: with ps; [
          spotipy
          tidalapi
          pyyaml
          tqdm
          sqlalchemy
        ];

        devDeps = ps: with ps; [
          pytest
          pytest-mock
        ];

        pythonEnv = python.withPackages (ps: runtimeDeps ps ++ devDeps ps);

        spotify_to_tidal = python.pkgs.buildPythonApplication {
          pname = "spotify_to_tidal";
          version = "1.0.7";
          pyproject = true;
          src = ./.;
          build-system = [ python.pkgs.setuptools ];
          dependencies = runtimeDeps python.pkgs;
          nativeCheckInputs = devDeps python.pkgs;
          pythonImportsCheck = [ "spotify_to_tidal" ];
        };
      in {
        packages.default = spotify_to_tidal;

        apps.default = {
          type = "app";
          program = "${spotify_to_tidal}/bin/spotify_to_tidal";
        };

        devShells.default = pkgs.mkShell {
          packages = [ pythonEnv ];
          shellHook = ''
            export PYTHONPATH="$PWD/src''${PYTHONPATH:+:$PYTHONPATH}"
            echo "spotify_to_tidal devshell — $(python --version)"
            echo "  run:  python -m spotify_to_tidal"
            echo "  test: pytest"
          '';
        };
      });
}
