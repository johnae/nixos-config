{ stdenv,
  lib,
  fetchgit,
  rustPlatform,
  cmake,
  makeWrapper,
  expat,
  pkgconfig,
  freetype,
  fontconfig,
  libX11,
  gperf,
  libXcursor,
  libXxf86vm,
  libXi,
  libXrandr,
  libGL,
  xclip }:

with rustPlatform;

let
  rpathLibs = [
    expat
    freetype
    fontconfig
    libX11
    libXcursor
    libXxf86vm
    libXrandr
    libGL
    libXi
  ];
in buildRustPackage rec {

  name = "alacritty-unstable-${version}";
  version = "378d0395ad86652d70131cd99d96c5ad69e24ac2";

  src = fetchgit {
    url = https://github.com/johnae/alacritty.git;
    rev = "${version}";
    sha256 = "01zbd4cy2v85j11zd9haw37ndfrmk75j1x0qrzr7h06z74sbkr49";
    fetchSubmodules = true;
  };

  cargoSha256 = "0kzsknhpcsm9cq9zs0s1jh9nml8k1hq33bhpjhsnx0b3p1q81r78";

  nativeBuildInputs = [
    cmake
    makeWrapper
    pkgconfig
  ];

  buildInputs = rpathLibs;

  postPatch = ''
    substituteInPlace copypasta/src/x11.rs \
      --replace Command::new\(\"xclip\"\) Command::new\(\"${xclip}/bin/xclip\"\)
  '';

  installPhase = ''
    runHook preInstall

    install -D target/release/alacritty $out/bin/alacritty
    patchelf --set-rpath "${stdenv.lib.makeLibraryPath rpathLibs}" $out/bin/alacritty

    install -D Alacritty.desktop $out/share/applications/alacritty.desktop

    runHook postInstall
  '';

  dontPatchELF = true;

  meta = with stdenv.lib; {
    description = "GPU-accelerated terminal emulator";
    homepage = https://github.com/jwilm/alacritty;
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ johnae ];
    platforms = platforms.linux;
  };
}
