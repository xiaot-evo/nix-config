{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "pumpkin";
  version = "nightly-2026-07-11";

  src = fetchurl {
    url = "https://github.com/Pumpkin-MC/Pumpkin/releases/download/nightly/pumpkin-X64-Linux";
    hash = "sha256-TqjKfQBa6e0IjPYUPkMd3+S+JvKOOLrYmCcGsFUTy2Y=";
  };

  # 预编译二进制，无需解压源码
  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # Rust 二进制通常依赖 libgcc_s
  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/pumpkin
    runHook postInstall
  '';

  meta = with lib; {
    description = "A fast, high-performance Minecraft server written in Rust";
    longDescription = ''
      Pumpkin is a fast, customizable, and high-performance Minecraft
      server written in Rust. It aims to provide a modern alternative
      to the vanilla Minecraft server with better performance and
      memory efficiency.
    '';
    homepage = "https://pumpkinmc.org";
    changelog = "https://github.com/Pumpkin-MC/Pumpkin/releases/tag/nightly";
    license = licenses.gpl3Only;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "pumpkin";
    maintainers = with maintainers; [ ];
  };
}
