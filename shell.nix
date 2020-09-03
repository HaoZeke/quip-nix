{ pythonVersion ? "38" }:
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
     export PYTHONPATH="$(pwd)/_build/pip_packages/lib/python3.8/site-packages"
     unset SOURCE_DATE_EPOCH
    # quippy Stuff
     export QUIPPY_INSTALL_OPTS="--prefix $PIP_PREFIX"
  '';
  libuv = libuv.overrideAttrs (oldAttrs: {
    doCheck = false;
    doInstallCheck = false;
  });
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "2.2.2";
  });
  customPython = mach-nix.mkPython {
    pypi_deps_db_commit = "b5cd0ee30c9a3e4f076374fc4c90cdc4e5f17d3c";
    pypi_deps_db_sha256 =
      "0gkklm0zb3pjxkkvvsda0ckvxb54mnqyxz31pwcjxjpx9jlqlbld";
    requirements = ''
      f90wrap
      ase
      snakemake
      matplotlib
      scipy
      pandas
      numpy
      ipython
      ipykernel
      pip
    '';
    providers = { pytest = "nixpkgs"; };
    overrides_pre = [
      (pythonSelf: pythonSuper: {
        pytest = pythonSuper.pytest.overrideAttrs (oldAttrs: {
          doCheck = false;
          doInstallCheck = false;
        });
        f90wrap = pythonSelf.buildPythonPackage rec {
          pname = "f90wrap";
          version = "0.2.3";
          src = pkgs.fetchFromGitHub {
            owner = "jameskermode";
            repo = "f90wrap";
            rev = "master";
            sha256 = "0d06nal4xzg8vv6sjdbmg2n88a8h8df5ajam72445mhzk08yin23";
          };
          buildInputs = with pkgs; [ gfortran stdenv ];
          propagatedBuildInputs = with pythonSelf; [
            setuptools
            setuptools-git
            wheel
            numpy
          ];
          preConfigure = ''
            export F90=${pkgs.gfortran}/bin/gfortran
          '';
          doCheck = false;
          doIstallCheck = false;
        };
      })
    ];
    pkgs = pkgs;
    extra_pkgs = [ libuv ];
    disable_checks = true;
  };
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

    customPython
    # https://github.com/sveitser/i-am-emotion/blob/294971493a8822940a153ba1bf211bad3ae396e6/gpt2/shell.nix
  ];
  shellHook = hook;
}
