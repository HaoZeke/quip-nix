{ stdenv, fetchFromGitHub, pythonPackages, gfortran, openblas, gcc9, lib
, pythonEnv }:

stdenv.mkDerivation rec {

  name = "quip";
  src = lib.cleanSource ./../QUIP;
  buildInputs = [ gfortran openblas gcc9 pythonEnv ];

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
    make install-quippy
  '';

  installPhase = ''
    make install
  '';

  meta = with stdenv.lib; {
    description = "";
    longDescription = "";
    homepage = "";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = [ maintainers.HaoZeke ];
  };
}
