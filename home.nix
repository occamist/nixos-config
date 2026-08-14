{ config, pkgs, lib, inputs, ... }:

{
  home.username = "occamist";
  home.homeDirectory = "/home/occamist";
  home.stateVersion = "26.05"; # match configuration.nix's system.stateVersion

  # --- SSH (ported from ~/.ssh/config - linode dropped, not carried over) ---
  programs.ssh = {
    enable = true;
    matchBlocks."*" = {
      identityFile = [ "~/.ssh/github" "~/.ssh/namecheap" ];
      addKeysToAgent = "yes";
    };
  };

  # allowed_signers only contains public key material (matches github.pub),
  # not a secret like the private keys - safe to generate declaratively
  # and commit, unlike the actual key files.
  home.file.".ssh/allowed_signers".text =
    "22800416+occamist@users.noreply.github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ1/cTs8rLtx6SUCNN0/dQQfZ4Rvm50ygVpJj5NKb1MK 22800416+occamist@users.noreply.github.com\n";

  # --- Git (ported from ~/.gitconfig, SSH-based commit signing) ---
  programs.git = {
    enable = true;
    userName = "Talha Altinel";
    userEmail = "22800416+occamist@users.noreply.github.com";
    signing = {
      key = "~/.ssh/github.pub";
      format = "ssh";
      signByDefault = true;
    };
    extraConfig = {
      url."ssh://git@github.com/".insteadOf = [ "https://github.com/" "http://github.com/" ];
      url."ssh://git@gitlab.com/".insteadOf = [ "https://gitlab.com/" "http://gitlab.com/" ];
      filter.lfs = {
        required = true;
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
      };
      core.editor = "vim";
      pull.ff = "only";
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      tag.gpgSign = true;
    };
  };

  # --- Zed editor (declarative extensions + settings, ported from ~/.config/zed/settings.json) ---
  programs.zed-editor = {
    enable = true;
    extensions = [
      "astro"
      "coverage-lsp"
      "csv"
      "dockerfile"
      "html"
      "kubernetes-snippets"
      "make"
      "markdownlint"
      "material-icon-theme"
      "one-dark-pro"
      "rainbow-csv"
      "scss"
      "sql"
      "terraform"
      "toml"
    ];
    userSettings = {
      lsp_document_colors = "background";
      cli_default_open_behavior = "new_window";
      colorize_brackets = true;

      agent_servers = {
        codex-acp = { type = "registry"; };
        claude-acp = {
          default_config_options = {
            model = "sonnet";
            mode = "acceptEdits";
          };
          type = "registry";
        };
      };

      edit_predictions = {
        mode = "subtle";
        provider = "zed";
      };

      project_panel.dock = "left";
      outline_panel.dock = "left";
      collaboration_panel = {
        button = false;
        dock = "left";
      };

      agent = {
        terminal_init_command = "";
        sidebar_side = "right";
        dock = "right";
        favorite_models = [ ];
        model_parameters = [ ];
      };

      git_panel = {
        tree_view = true;
        dock = "left";
      };

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      session.trust_all_worktrees = true;

      base_keymap = "JetBrains";
      icon_theme = "Material Icon Theme";

      ui_font_size = 16;
      ui_font_family = ".ZedSans";
      buffer_font_size = 16.0;
      buffer_font_family = ".ZedMono";
      buffer_font_features.calt = false;

      theme = {
        mode = "dark";
        light = "One Light";
        dark = "One Dark Pro";
      };

      languages = {
        Markdown.preferred_line_length = 80;
        TypeScript.preferred_line_length = 120;
        Go.semantic_tokens = "combined";
        Astro = {
          prettier.allowed = true;
          preferred_line_length = 120;
          semantic_tokens = "combined";
        };
      };

      global_lsp_settings.semantic_token_rules = [
        { token_type = "namespace"; foreground_color = "#E5C17C"; }
        { token_type = "type"; token_modifiers = [ "declaration" ]; foreground_color = "#E5C17C"; }
        { token_type = "type"; token_modifiers = [ "definition" ]; foreground_color = "#E5C17C"; }
        { token_type = "type"; foreground_color = "#c679dd"; }
        { token_type = "parameter"; foreground_color = "#D19A66"; }
        { token_type = "variable"; foreground_color = "#D19A66"; }
        { token_type = "property"; foreground_color = "#D19A66"; }
        { token_type = "operator"; foreground_color = "#61AFEF"; }
      ];

      theme_overrides."One Dark Pro".syntax = {
        namespace.color = "#E5C17C";
        variable.color = "#D19A66";
        property.color = "#D19A66";
        type.color = "#c679dd";
      };
    };
  };

  # --- GNOME extensions: enable state (packages come from configuration.nix) ---
  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "solaar-extension@sidevesh"
        "appindicatorsupport@rgcjonas.gmail.com"
        "caffeine@patapon.info"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "status-icons@gnome-shell-extensions.gcampax.github.com"
      ];
    };
    "org/gnome/desktop/interface" = {
      icon-theme = "Papirus"; # package added in configuration.nix
      monospace-font-name = "MesloLGL Nerd Font 10"; # what GNOME Console
        # actually reads (its own custom-font field is unused while
        # use-system-font stays true, which is its default)
      accent-color = "slate";
    };
    "org/gnome/Console" = {
      theme = "night"; # dark-mode override, separate from the system light/dark preference
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,close"; # adds a minimize button, GNOME's default omits it
    };
    "org/gnome/mutter" = {
      workspaces-only-on-primary = false; # workspaces span all monitors, relevant given the external display
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      click-method = "fingers";
      two-finger-scrolling-enabled = true;
    };
    "org/gnome/nautilus/compression" = {
      default-compression-format = "7z";
    };
    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small-plus";
    };
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      search-filter-time-type = "last_modified";
    };
    "org/gnome/Geary" = {
      spell-check-languages = [ "en_GB" ];
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file://${config.home.homeDirectory}/.config/background";
      picture-uri-dark = "file://${config.home.homeDirectory}/.config/background";
      picture-options = "zoom";
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>t";
      command = "kgx"; # GNOME Console - pending confirmation, see chat re: gnome-terminal
      name = "terminal";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>b";
      command = "firefox";
      name = "browser";
    };
  };

  # Wallpaper - a real personal image file, not a package. Copied into this
  # repo (assets/wallpaper.jpeg) so it's version-controlled and reproducible
  # rather than relying on a file that only exists on the old machine.
  home.file.".config/background".source = ./assets/wallpaper.jpeg;

  # All CLI/dev/GUI packages now live in configuration.nix's
  # environment.systemPackages instead of here - single-user machine, so
  # per-user home.packages just duplicated the lookup with no payoff.
  # home.nix is reserved for things that need home-manager's structured
  # program modules (git config generation, Zed settings.json generation,
  # dconf, shell integration) rather than a plain package install.

  # --- Fish (ported from ~/.config/fish/config.fish) ---
  # System-level `programs.fish.enable` in configuration.nix registers
  # fish in /etc/shells; this generates the actual user config.
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    shellAliases = {
      zed = "zeditor";
    };
  };

  # starship needs real per-shell init-hook generation (not just a binary),
  # so it's a home-manager program rather than a systemPackages entry.
  # enableFishIntegration/enableBashIntegration default to true, so this
  # also wires up bash even though only fish sourced it on Arch.
  programs.starship.enable = true;

  # rustup replacement: per-project toolchains via inputs.rust-overlay,
  # e.g. in a project flake: rust-bin.stable.latest.default.override {
  #   extensions = [ "clippy" "rustfmt" "rust-analyzer" ];
  # }
  # nvm replacement: fnm, or per-project nodejs_xx in a dev shell

  # PATH additions ported from config.fish - genuinely user-specific
  # (GOPATH, cargo, local installs), not a general system PATH policy.
  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin" # target dir used by the Antigravity CLI installer
  ];
}
