{ pythonVersion ? "38" }:
# Define
let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  stdenv = pkgs.stdenv;
  quip = pkgs.callPackage ./pkgs/quip.nix { pythonEnv = customPython; };
  inherit (pkgs.lib) optional optionals;
  # Import
  buildpkgs = import ./nix { };
  libuv = libuv.overrideAttrs (oldAttrs: {
    doCheck = false;
    doInstallCheck = false;
  });
  # Python
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix.git";
    ref = "refs/tags/3.3.0";
  }) {
    pkgs = pkgs;
    python = "python38";
  };
  f90wrap = mach-nix.buildPythonPackage {
    pname = "f90wrap";
    version = "0.2.6";
    src = pkgs.fetchFromGitHub {
      owner = "jameskermode";
      repo = "f90wrap";
      rev = "v0.2.6";
      sha256 = "sha256-1W1aFU9Q4lh1gnFTAVCJGyK1PpdJKnFjzUuL93n5BlQ=";
    };
    buildInputs = with pkgs; [ gfortran stdenv ];
    requirements = ''
      numpy
      setuptools
      setuptools-git
      wheel
    '';
    propagatedBuildInputs = with customPython.python.pkgs; [
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
  customPython = (mach-nix.mkPython {
    requirements = builtins.readFile ./requirements.txt;
    packagesExtra = [ f90wrap ];
    providers = { pytest = "nixpkgs"; };
    overridesPre = [
      (pythonSelf: pythonSuper: {
        pytest = pythonSuper.pytest.overrideAttrs (oldAttrs: {
          doCheck = false;
          doInstallCheck = false;
        });
        disable_checks = true;
      })
    ];
  }).override (oa: { ignoreCollisions = true; });
  # Shell Hook
  # https://churchman.nl/2019/01/22/using-nix-to-create-python-virtual-environments/
  # https://discourse.nixos.org/t/how-to-create-a-nix-shell-environment-with-different-python-version-as-default/3236/3
  hook = ''
    # QUIP Stuff
     export QUIP_ARCH=linux_x86_64_gfortran
     export PATH=$PATH:$QUIP_INSTALLDIR
    # Python Stuff
     export PIP_PREFIX="$(pwd)/_build/pip_packages"
     export PYTHONPATH="$PIP_PREFIX/${customPython.python.sitePackages}:$PYTHONPATH"
     export PATH="$PIP_PREFIX/bin:$PATH"
     unset SOURCE_DATE_EPOCH
    # Nixy stuff
     export PYTHONROOT=${customPython}
     export MKLROOT=${pkgs.mkl}
     export LD_PRELOAD="${pkgs.mkl}/lib/libmkl_core.so:${pkgs.mkl}/lib/libmkl_sequential.so"
    # quippy Stuff
     export QUIPPY_INSTALL_OPTS="--prefix $PIP_PREFIX"
  '';
  # quippy = pkgs.python38.toPythonModule (pkgs.callPackage ./pkgs/quip {
  #   enablePython = true;
  #   pythonPackages = pkgs.python3Packages;
  # });

  # quippy = mach-nix.buildPythonPackage {
  #   name = "quippy";
  #   src = ./QUIP;
  #   buildInputs = with pkgs; [ quip gfortran openblas gcc9 mach-nix ];

  #   preConfigure = ''
  #     export QUIP_ARCH=linux_x86_64_gfortran
  #     export QUIP_INSTALLDIR=$out/bin
  #     export QUIP_STRUCTS_DIR=$PWD/structs
  #     mkdir -p build/$QUIP_ARCH
  #     mkdir -p $QUIP_INSTALLDIR
  #     cp Makefile.inc build/$QUIP_ARCH
  #   '';

  #   buildPhase = ''
  #     make install-quippy
  #   '';

  #   requirements = ''
  #     numpy
  #     setuptools
  #     setuptools-git
  #     wheel
  #   '';
  # };
in pkgs.mkShell {
  buildInputs = with pkgs; [
    # Required for the shell
    zsh
    perl
    git
    direnv
    ag
    fd
    # quip

    # Building thigns
    gcc9
    gfortran
    mkl
    customPython
    # https://github.com/sveitser/i-am-emotion/blob/294971493a8822940a153ba1bf211bad3ae396e6/gpt2/shell.nix
  ];
  shellHook = hook;
  GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  LOCALE_ARCHIVE = pkgs.lib.optionalString stdenv.isLinux
    "${pkgs.glibcLocales}/lib/locale/locale-archive";
}

# extra_pkgs = [
#   mach-nix.buildPythonPackage
#   rec {
#     name = "quippy";
#     src = ./QUIP;
#     buildInputs = [ quip ];
#     doCheck = true;
#     preConfigure = ''
#       export QUIP_ARCH=linux_x86_64_gfortran
#       export QUIP_INSTALLDIR=$out/bin
#       export QUIP_STRUCTS_DIR=$PWD/structs
#       mkdir -p build/$QUIP_ARCH
#       mkdir -p $QUIP_INSTALLDIR
#       cp Makefile.inc build/$QUIP_ARCH
#     '';
#     buildPhase = ''
#       make install-quippy
#     '';
#   }
# ];
# _.f90wrap.buildInputs = with pkgs; [ gfortran stdenv ];
# _.f90wrap.propagatedBuildInputs = with pkgs.python3Packages; [
#   setuptools
#   setuptools-git
#   wheel
#   numpy
# ];
# preConfigure = ''
#   export F90=${pkgs.gfortran}/bin/gfortran
# '';
# doCheck = false;
# doIstallCheck = false;
