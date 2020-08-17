# Define
let
  overlay = (self: super: rec {
    python38 = super.python38.override {
      packageOverrides = self: super: {
        pytest = super.pytest.overrideAttrs (old: { doCheck = false; });
        scipy = super.scipy.overrideAttrs (old: { doCheck = false; });
      };
    };
    python38Packages = python38.pkgs;
  });

  myPythonPackages = ps: with ps; [ numpy ase ipykernel ipython ];

  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { overlays = [ overlay ]; };
  inherit (pkgs.lib) optional optionals;
  # Import
  buildpkgs = import ./nix { };
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
    openblas
    (python38.withPackages myPythonPackages)
  ];
  shellHook = hook;
}
