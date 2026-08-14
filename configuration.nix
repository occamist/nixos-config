{ config, pkgs, inputs, ... }:

{
  nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # NixOS's built-in nix.gc module has no count-based "keep last N
  # generations" option - nix-collect-garbage only supports -d (delete ALL
  # old generations unconditionally) or --delete-older-than (age-based).
  # "Keep last 20 always" needs `nix-env --delete-generations +20`
  # directly (confirmed: +N keeps the N most recent, deletes the rest),
  # so this replaces the declarative nix.gc module with a custom timer.
  # (boot.loader.systemd-boot.configurationLimit, which only bounds
  # boot-menu entries rather than pruning generations, was considered and
  # deliberately left unset - default is show-all, and this timer already
  # keeps the underlying generation count in check.)
  systemd.services.nix-gc-keep-generations = {
    description = "Prune Nix system profile to the last 20 generations, then garbage collect";
    serviceConfig.Type = "oneshot";
    script = ''
      ${config.nix.package}/bin/nix-env --delete-generations --profile /nix/var/nix/profiles/system +20
      ${config.nix.package}/bin/nix-collect-garbage
    '';
  };
  systemd.timers.nix-gc-keep-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  # nix-ld: lets Zed's downloaded LSP servers/extension binaries (pre-built,
  # dynamically linked, expect a standard FHS layout) resolve their dynamic
  # libraries on NixOS without manual wrapping.
  programs.nix-ld.enable = true;

  # --- Boot ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # --- Networking ---
  networking.hostName = "bumblebee";
  networking.networkmanager.enable = true;

  # --- Locale / keyboard (matches current Arch localectl/timedatectl output) ---
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_NUMERIC = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
  };
  console.keyMap = "uk";

  # --- Desktop (GNOME/Wayland via GDM, matching current setup) ---
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "gb";
    model = "pc105";
    options = "terminate:ctrl_alt_bksp";
  };
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.gnome-keyring.enable = true;
  # epiphany installs by default with core-apps; not wanted (Firefox/Chromium used instead)
  services.gnome.core-apps.excludePackages = [ pkgs.epiphany ];
  services.gvfs.enable = true; # already mkDefault true via core-shell, set explicitly anyway

  # --- Audio (pipewire, replacing pulseaudio-era packages) ---
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  security.rtkit.enable = true;

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # --- GPU (AMD iGPU, Radeon 840M/860M "Krackan") ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- Docker ---
  virtualisation.docker.enable = true;

  # --- Swap ---
  zramSwap.enable = true;

  # --- Solaar (Logitech wireless devices) ---
  hardware.logitech.wireless.enable = true;

  # --- User ---
  users.users.occamist = {
    isNormalUser = true;
    description = "Talha Altinel";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "input" "networkmanager" ];
  };
  # root stays on the NixOS default (bash) - only occamist's login shell is fish
  programs.fish.enable = true; # registers fish in /etc/shells; config itself lives in home.nix

  # --- GNOME extension packages ---
  # enabling them (dconf enabled-extensions list) is handled in home.nix,
  # NOT here - installing the package alone does not activate it.
  environment.systemPackages = with pkgs; [
    gnome-shell-extensions # provides user-theme, status-icons
  ] ++ (with pkgs.gnomeExtensions; [
    blur-my-shell
    caffeine
    appindicator # verify exact attr name for "appindicatorsupport" on search.nixos.org
    # ding
    # solaar-extension: verify exact nixpkgs attr name, may need an overlay/fetched package
  ]) ++ [
    # --- TODO: bulk of the ~225 direct-rename CLI/GUI packages from
    # arch-explicit-pkgs.txt go here. All system-wide on purpose - this is
    # a single-user machine, so per-user home-manager packages would just
    # be a second place to look for no benefit. home.nix is reserved for
    # things that actually need home-manager's structured program modules
    # (programs.git, programs.zed-editor, dconf.settings).
    # Deliberately left unfilled rather than guessing 200+ nixpkgs attr
    # names without verifying each one against search.nixos.org.
    # Already-certain ones to start from:
    git
    vim
    wget
    # gcc/gnumake: "base"/"base-devel" themselves don't map to packages -
    # Nix's own internal build sandbox has its own toolchain, separate from
    # what's in your shell PATH - but confirmed real usage of gcc/make
    # directly (fish history: repeated `make DAY=N`, a "use gcc for c++23"
    # commit, main.cc files) means these need adding explicitly
    gcc
    gnumake
    # efibootmgr dropped - not needed by systemd-boot (unlike GRUB, which
    # used it internally), and no evidence of manual use either
    # smartmontools dropped - no evidence of smartctl/smartd usage
    docker-buildx
    docker-compose
    ripgrep
    fd
    fzf
    jq
    tree
    btop
    fastfetch
    go
    golangci-lint
    kubectl
    k9s
    helm

    # --- Category A: dev tools / language & infra tooling ---
    dbeaver-bin # renamed from "dbeaver"
    beekeeper-studio
    git-lfs
    gh # renamed from "github-cli"
    goreleaser
    graphviz
    hugo
    pnpm
    shellcheck
    uv
    libappindicator-gtk3 # renamed from "libappindicator", used by tray-icon apps (e.g. solaar)

    # --- Category B: CLI utilities ---
    _7zip-zstd # zstd/brotli/lz4 fork, not the official 7zz - deliberate choice
    alsa-utils
    asciinema
    asciiquarium
    rclone
    aspell
    aspellDicts.en
    du-dust
    inxi
    less
    mandoc
    nano
    usbutils
    wl-clipboard
    xdg-utils
    yt-dlp
    # iwd / wireless_tools dropped - NetworkManager is confirmed using its
    # default wpa_supplicant backend, iwd.service was disabled/unused

    # --- Category C: GUI apps (only ones NOT already covered by GNOME's
    # default core-apps/core-shell package sets - see notes above) ---
    celluloid
    chromium
    converseen
    deja-dup
    evince # papers is what GNOME's core-apps installs by default; evince
           # (older GTK3 viewer) is a separate package, added explicitly
    firefox
    geary
    gnome-tweaks # not in core-apps/core-shell defaults either - another
                 # early unverified assumption, actually checked now
    impression
    kooha
    libreoffice-still
    mpv
    obsidian
    pavucontrol
    papirus-icon-theme # was a manually-dropped ~/.icons dir on Arch, not a
                       # pacman package - found via `gsettings get
                       # org.gnome.desktop.interface icon-theme`
    rygel # UPnP/DLNA media sharing, actually used
    solaar
    tor-browser # renamed from "torbrowser-launcher" - that's a download/verify/launch
                # utility for distros without a direct package; Nix already
                # builds+verifies the browser itself, so the launcher's job is moot
    vlc
    texlive.combined.scheme-full # covers Thai + every other language collection
    # grilo-plugins dropped - already a runtime dep of gnome-music/showtime's
    # own nixpkgs derivation, not something to declare separately
    # network-manager-applet dropped - redundant under full GNOME Shell,
    # which has native network/VPN UI in Quick Settings
    # orca dropped - not actively used
    # xdg-desktop-portal-gnome dropped - core-os-services already sets
    # xdg.portal.extraPortals to include it
    # wireplumber dropped - its enable option defaults to services.pipewire.enable
    # libpulse dropped - apps that need it (gnome-shell confirmed via /proc
    # maps, likely firefox/mpv/vlc/pavucontrol too) are all built from
    # source by nixpkgs and get it via normal RPATH linking automatically;
    # no confirmed case where nix-ld/an explicit package would be needed
  ];

  # --- Fonts ---
  # Nerd fonts: the whole collection, not a curated list - trades ~3GB of
  # disk space for never having to maintain a per-font attribute list again.
  # The old nerdfonts.override { fonts = [...]; } shortcut was removed from
  # nixpkgs (23.11+), so this attrValues one-liner is the actual replacement,
  # not a workaround. filterAttrs+isDerivation guards against non-derivation
  # entries in the set (e.g. stray meta/override attrs).
  fonts.packages = with pkgs; [
    freefont_ttf # renamed from "gnu-free-fonts"
    sarabun-font # Thai font, was a manually-dropped file in /usr/share/fonts on
                 # Arch, owned by no package - not something pacman-based
                 # migration would've caught either, found by checking fc-list
  ] ++ (builtins.attrValues (pkgs.lib.filterAttrs (_: pkgs.lib.isDerivation) pkgs.nerd-fonts));

  system.stateVersion = "26.05";
}
