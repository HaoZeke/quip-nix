# Define
let
  # https://discourse.nixos.org/t/how-to-create-a-nix-shell-environment-with-different-python-version-as-default/3236/3
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
  # https://churchman.nl/2019/01/22/using-nix-to-create-python-virtual-environments/
  hook = ''
    # QUIP Stuff
     export QUIP_ARCH=linux_x86_64_gfortran
     export QUIP_INSTALLDIR=$PWD/out/bin
     export QUIP_STRUCTS_DIR=$PWD/structs
     export PATH=$PATH:$QUIP_INSTALLDIR
    # Python Stuff
     export PIP_PREFIX="$(pwd)/_build/pip_packages"
     export PYTHONPATH="$(pwd)/_build/pip_packages/lib/python3.8/site-packages:$PYTHONPATH"
     unset SOURCE_DATE_EPOCH
  '';
  # Apparently pip needs 1980 or above
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
