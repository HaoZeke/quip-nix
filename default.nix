let

  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs { };
  quip = pkgs.callPackage ./pkgs/quip.nix { pythonEnv = customPython; };
  inherit (pkgs.lib) optional optionals;

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
  mach-nix = import (builtins.fetchGit {
    url = "https://github.com/DavHau/mach-nix/";
    ref = "2.3.0";
  });
  customPython = mach-nix.mkPython {
    pypi_deps_db_commit = "ed2da0e9bd68cf7050c44f874c54f924675a61b5";
    pypi_deps_db_sha256 =
      "04fn0bsdmwgagj75libnb6ppjjkw4mb1zgvsw7ixg0d83l6vq9r5";
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
in pkgs.buildEnv {
  name = "quip-env";
  paths = [ quip ];
}
