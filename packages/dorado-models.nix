{ pkgs, lib, ... }:

let
  name = "ont-dorado-models";

  sources = with pkgs; {
    ont-dorado-models = fetchurl {
      url = "https://cdn.oxfordnanoportal.com/apt/pool/non-free/o/ont-dorado-models-for-mk1c/ont-dorado-models-for-mk1c_7.6.7-1_all.deb";
      hash = "sha256-gX2X/Eu9ZlXK5LTlSBnrbcqyA9dlTGnrllWdpSBRDNA=";
    };
  };

  unpackedONTDoradoModels = with pkgs; stdenv.mkDerivation {
    name = "ont-dorado-models";

    nativeBuildInputs = [
      dpkg
    ];

    buildInputs = [  ];

    src = sources.ont-dorado-models;

    unpackPhase = ''
      runHook preUnpack

      dpkg-deb -x $src temp

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r temp/opt $out/

      runHook postInstall
    '';
  };

  passthru = { };
  
  meta = with lib; {
    platforms = [ "aarch64-linux" ];
    maintainers = with maintainers; [  ];
  };
in
unpackedONTDoradoModels
