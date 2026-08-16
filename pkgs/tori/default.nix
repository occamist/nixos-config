{
  lib,
  rustPlatform,
  src,
  mpv-unwrapped,
  libxcb,
  makeWrapper,
  python3,
  yt-dlp,
}:

rustPlatform.buildRustPackage {
  pname = "tori";
  inherit src;

  # Both of these read straight out of the source tree, so re-tagging the
  # `tori-src` flake input is the only edit a version bump needs — there is no
  # hash here to forget. Neither is IFD: flake inputs are fetched before
  # evaluation begins, so this is a plain read of an already-realised path.
  version = (lib.importTOML "${src}/tori/Cargo.toml").package.version;
  cargoLock.lockFile = "${src}/Cargo.lock";

  # The workspace also holds `tori-player`, an unfinished alternative audio
  # backend that pulls in ffmpeg/alsa and isn't in tori's default features.
  cargoBuildFlags = [ "--package" "tori" ];
  cargoTestFlags = [ "--package" "tori" ];

  nativeBuildInputs = [
    python3 # xcb 0.8's build script runs a Python generator over its vendored XML
    makeWrapper
  ];

  buildInputs = [
    mpv-unwrapped # libmpv, linked directly — the mpv binary is never spawned
    libxcb # clipboard, via the `clip` feature
  ];

  # tori shells out to yt-dlp for song metadata, and libmpv's built-in ytdl_hook
  # calls it again to resolve streams.
  # --suffix, not --prefix: a system yt-dlp wins if present (it needs to stay
  # fresh to keep up with YouTube), and this is the fallback so tori can't break.
  postInstall = ''
    wrapProgram $out/bin/tori \
      --suffix PATH : ${lib.makeBinPath [ yt-dlp ]}
  '';

  meta = {
    description = "Frictionless music player for the terminal";
    homepage = "https://github.com/LeoRiether/tori";
    changelog = "https://github.com/LeoRiether/tori/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    mainProgram = "tori";
    platforms = lib.platforms.linux;
  };
}
