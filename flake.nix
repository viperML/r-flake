{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];

      perSystem = {pkgs, ...}: let
        nv = pkgs.callPackages ./generated.nix {};
        pythonEnv = pkgs.python3.withPackages (p: [
          p.jupyter
          p.jupyter_console
          p.jupyterlab-lsp
          p.notebook
          p.pip
        ]);
      in {
        devShells.default = pkgs.mkShellNoCC {
          JUPYTER_PATH = pkgs.runCommandLocal "jupyer-path" {} ''
            mkdir -pv $out/kernels/R
            cp -vr ${./kernel.json} $out/kernels/R/kernel.json
          '';
          shellHook = ''
            # R LSP fix
            ln -sfvT / .lsp_symlink
            # Vscode is dumb and can't find python
            ln -sfvT "${pythonEnv}" "$PWD/.venv"
          '';
          packages = [
            pythonEnv
            (pkgs.rWrapper.override {
              packages = with pkgs.rPackages; [
                tidyverse
                IRkernel
                (languageserver.overrideAttrs (old:
                  with nv.languageserver; {
                    name = "r-languageserver-${date}";
                    inherit src;
                  }))
                littler
              ];
            })
          ];
        };
      };
    };
}
