# Define
let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  inherit (pkgs.lib) optional optionals;
  # Import
  buildpkgs = import ./nix { };
  # Python
  pythonEnv =
    pkgs.python38.withPackages (ps: with ps; [ numpy ase ipykernel ipython ]);
  # Shell Hook
  hook = ''
    export QUIP_ARCH=linux_x86_64_gfortran
    export QUIP_INSTALLDIR=$PWD/out/bin
    export QUIP_STRUCTS_DIR=$PWD/structs
    export PATH=$PATH:$QUIP_INSTALLDIR
  '';
in pkgs.mkShell {
  buildInputs = with pkgs; [
    # Required for the shell
    zsh
    perl
    git
    direnv
    fzf
    ag
    fd

    # Building thigns
    gcc9
    gfortran
    liblapack
    blas
    # pythonEnv
    conda
  ];
  shellHook = hook;
}
