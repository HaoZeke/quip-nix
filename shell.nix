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
  quip = pkgs.stdenv.mkDerivation {
    name = "quip";
    src = pkgs.lib.cleanSource ./QUIP;
    buildInputs = with pkgs; [ gfortran openblas gcc9 ];

    preConfigure = ''
      export QUIP_ARCH=linux_x86_64_gfortran
      export QUIP_INSTALLDIR=$out/bin
      export QUIP_STRUCTS_DIR=$PWD/structs
      mkdir -p build/$QUIP_ARCH
      mkdir -p $QUIP_INSTALLDIR
      cp Makefile.inc build/$QUIP_ARCH
    '';

    buildPhase = ''
      make
    '';
    installPhase = ''
      make install
    '';
    meta = with pkgs.stdenv.lib; {
      description = "";
      longDescription = "";
      homepage = "";
      license = licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
      maintainers = [ maintainers.HaoZeke ];
    };
  };
  f90wrap = mach-nix.buildPythonPackage {
    pname = "f90wrap";
    version = "0.2.3";
    src = pkgs.fetchFromGitHub {
      owner = "jameskermode";
      repo = "f90wrap";
      rev = "master";
      sha256 = "0d06nal4xzg8vv6sjdbmg2n88a8h8df5ajam72445mhzk08yin23";
    };
    buildInputs = with pkgs; [ gfortran stdenv ];
    requirements = ''
      numpy
      setuptools
      setuptools-git
      wheel
    '';
    propagatedBuildInputs = with mach-nix.python; [
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
  # quippy = mach-nix.buildPythonPackage {
  #   name = "quippy";
  #   src = ./QUIP;
  #   # _.buildInputs = with pkgs; [ quip gfortran openblas gcc9 ];

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
  # };
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "2.3.0";
  });
  customPython = mach-nix.mkPython {
    pypi_deps_db_commit = "ed2da0e9bd68cf7050c44f874c54f924675a61b5";
    pypi_deps_db_sha256 =
      "0gkklm0zb3pjxkkvvsda0ckvxb54mnqyxz31pwcjxjpx9jlqlbld";
    requirements = builtins.readFile ./requirements.txt;
    extra_pkgs = [ f90wrap ];
    providers = { pytest = "nixpkgs"; };
    overrides_pre = [
      (pythonSelf: pythonSuper: {
        pytest = pythonSuper.pytest.overrideAttrs (oldAttrs: {
          doCheck = false;
          doInstallCheck = false;
        });
        pkgs = pkgs;
        disable_checks = true;
      })
    ];
  };
in pkgs.mkShell {
  buildInputs = with pkgs; [
    # Required for the shell
    zsh
    perl
    git
    direnv
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
