# Define
let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  inherit (pkgs.lib) optional optionals;
  # Import
  buildpkgs = import ./nix { };
  # Shell Hook
  # https://churchman.nl/2019/01/22/using-nix-to-create-python-virtual-environments/
  # https://discourse.nixos.org/t/how-to-create-a-nix-shell-environment-with-different-python-version-as-default/3236/3
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
    # https://github.com/sveitser/i-am-emotion/blob/294971493a8822940a153ba1bf211bad3ae396e6/gpt2/shell.nix
    (python3.buildEnv.override {
      extraLibs = with python3Packages; [
        (fire.overridePythonAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        }))
        (pytest.overridePythonAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        }))
        (numpy.overridePythonAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        }))
        (scipy.overridePythonAttrs (old: {
          doCheck = false;
          doInstallCheck = false;
        }))
        regex
        ipython
        python-language-server
        flask
        black
        unidecode
      ];
      ignoreCollisions = true;
    })
  ];
  shellHook = hook;
}
