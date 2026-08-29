{ config, pkgs, inputs, ... }:

let
  pkgs-latest = import inputs.nixpkgs-latest {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # nix-ld: lets Zed's downloaded LSP servers/extension binaries (pre-built,
  # dynamically linked, expect a standard FHS layout) resolve their dynamic
  # libraries on NixOS without manual wrapping.
  programs.nix-ld.enable = true;

  # --- Bootloader / Kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.enableRedistributableFirmware = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- Networking
  networking.hostName = "angmar";
  networking.networkmanager.enable = true;

  # --- Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # --- Locale
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };
  console.keyMap = "uk";

  # --- GNOME
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [ pkgs.epiphany ];
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };
  services.gnome.gnome-browser-connector.enable = true;

  # --- CUPS to print docs
  services.printing.enable = true;

  # --- Audio (Pipewire)
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  security.rtkit.enable = true;

  # --- Nix GC
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

  # --- Docker
  virtualisation.docker.enable = true;

  # --- Swap
  zramSwap.enable = true;

  # --- User
  # GDM/GNOME Settings read the account avatar from AccountsService, not
  # ~/.face, so register it declaratively via the same D-Bus call GNOME
  # Settings itself makes. Runs after accounts-daemon so it self-heals if
  # /var/lib/AccountsService is ever wiped.
  systemd.services.set-user-icon = {
    description = "Register occamist's AccountsService icon";
    wantedBy = [ "graphical.target" ];
    after = [ "accounts-daemon.service" ];
    requires = [ "accounts-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.glib}/bin/gdbus call --system --dest org.freedesktop.Accounts --object-path /org/freedesktop/Accounts/User1000 --method org.freedesktop.Accounts.User.SetIconFile ${./assets/ring.jpeg}";
    };
  };
  users.users."occamist" = {
    isNormalUser = true;
    description = "occamist";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "input"
    ];
    packages = with pkgs; [
      beekeeper-studio
      celluloid
      chromium
      converseen
      dbeaver-bin
      deja-dup
      evince # older GTK3 viewer, pre-cursor to papers GTK4
      geary
      gnome-tweaks
      impression
      kooha
      libreoffice
      mpv
      obsidian
      pavucontrol
      tor-browser
      vlc
    ];
  };
  programs.fish.enable = true; # to register to /etc/shells

  # List packages installed in system
  environment.systemPackages =
    with pkgs;
    [
      alsa-utils
      asciinema
      asciiquarium
      aspell
      aspellDicts.en
      btop
      claude-code
      discord
      docker-buildx
      docker-compose
      dust
      fastfetch
      fd
      fzf
      gcc
      gh
      go
      golangci-lint
      helm
      hugo
      inxi
      jq
      k9s
      kubectl
      mandoc
      nil
      nixd
      (papirus-icon-theme.override { color = "paleorange"; })
      pnpm
      python3
      rclone
      ripgrep
      shellcheck
      # texlive.combined.scheme-full // uncommented LaTeX support for testing updates sizes weekly
      tori
      tree
      usbutils
      uv
      vim
      wget
      wl-clipboard
      yt-dlp
    ]
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      blur-my-shell
      caffeine
      status-icons
    ])
    ++ [
      pkgs-latest.fetch
      inputs.keyboard-app.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  # --- Nerd Fonts
  fonts.packages =
    with pkgs;
    [
      freefont_ttf
      sarabun-font
      # Only the Nerd Font actually referenced (home.nix monospace-font-name).
      # Installing all of pkgs.nerd-fonts costs 7.7 GiB of closure that is
      # re-downloaded in full on every nixpkgs mass rebuild.
      nerd-fonts.meslo-lg
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05";
}
