{ pkgs, lib, ... }:

let
  name = "ont-dorado-server";

  sources = with pkgs; {
    ont-dorado-server = fetchurl {
      url = "http://cdn.oxfordnanoportal.com/apt/pool/non-free/o/ont-dorado-server-for-mk1c/ont-dorado-server-for-mk1c_7.6.7-1~bionic-mk1c_arm64.deb";
      hash = "sha256-Nus/2ci/RqAfRNWA/wl4DjLzhNphFE9WLgaa6iE3EZw=";
    };
  };

  unpackedONTDoradoServer = with pkgs; stdenv.mkDerivation {
    name = "ont-dorado-server";

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
      dpkg
    ];

    buildInputs = [
      zeromq.out
      zlib.out
      zstd.out
      libaec.out
      numactl.out
      gfortran7.cc.lib
    ];

    src = sources.ont-dorado-server;

    unpackPhase = ''
      runHook preUnpack

      dpkg-deb -x $src temp

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      pushd temp/opt/ont/dorado || exit 1
      rm lib/libaec.so* lib/libsz.so* lib/libzstd.so* lib/libgfortran.so* lib/libgomp.so*
      popd

      mkdir -p $out
      cp -r temp/opt $out/

      runHook postInstall
    '';

    postInstall = ''
      for bin in /opt/ont/dorado/bin/dorado /opt/ont/dorado/bin/dorado_basecall_server; do
          wrapProgram $out/$bin --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib"
      done
    '';
  };

  passthru = { };

  meta = with lib; {
    platforms = [ "aarch64-linux" ];
    maintainers = with maintainers; [  ];
  };
in
unpackedONTDoradoServer
