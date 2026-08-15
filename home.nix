{ pkgs, inputs, ...}:

let
  pkgs-latest = import inputs.nixpkgs-latest {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  home.username = "occamist";
  home.homeDirectory = "/home/occamist";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    shellAliases = {
      zed = "zeditor";
    };
  };
  programs.starship.enable = true;

  # --- SSH
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      IdentityFile = [ "~/.ssh/github" ];
      AddKeysToAgent = "yes";
    };
  };
  home.file.".ssh/allowed_signers".text =
    "22800416+occamist@users.noreply.github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHEF5OE1lUdjl9wb5rtPib8o+TldrE1PEnlYEKBpAQ/ 22800416+occamist@users.noreply.github.com\n";

  # --- Git
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      key = "~/.ssh/github.pub";
      format = "ssh";
      signByDefault = true;
    };
    settings = {
      user.name = "Talha Altinel";
      user.email = "22800416+occamist@users.noreply.github.com";
      url."ssh://git@github.com/".insteadOf = [
        "https://github.com/"
        "http://github.com/"
      ];
      url."ssh://git@gitlab.com/".insteadOf = [
        "https://gitlab.com/"
        "http://gitlab.com/"
      ];
      core.editor = "vim";
      pull.ff = "only";
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };
  };

  # --- GNOME extensions & settings
  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "caffeine@patapon.info"
        #"appindicatorsupport@rgcjonas.gmail.com" # AppIndicator and KStatusNotifierItem by by 3v1n0 (legacy)
        #"status-icons@gnome-shell-extensions.gcampax.github.com" # Status Icons by fmuellner (new)
      ];
    };
    "org/gnome/desktop/interface" = {
      icon-theme = "Papirus";
      monospace-font-name = "MesloLGL Nerd Font 10";
      accent-color = "slate";
    };
    "org/gnome/Console" = {
      theme = "night";
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,close";
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
      picture-uri = "file://${pkgs.nixos-artwork.wallpapers.dracula.src}";
      picture-uri-dark = "file://${pkgs.nixos-artwork.wallpapers.dracula.src}";
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
      command = "kgx";
      name = "terminal";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Super>b";
      command = "firefox";
      name = "browser";
    };
  };
  home.file.".face".source = ./assets/ring.jpeg;

  # --- Firefox
  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      nativeMessagingHosts = [ pkgs.gnome-browser-connector ];
    };

    profiles.occamist = {
      isDefault = true;

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        refined-github
        yomitan
        languagetool
        gnome-shell-integration
        search-by-image
      ];

      # Extensions disabled by default, auto-enable them on install.
      settings."extensions.autoDisableScopes" = 0;

      # Trim down the Firefox Home / New Tab page.
      settings."browser.newtabpage.activity-stream.feeds.section.topstories" = false; # Stories (Pocket)
      settings."browser.newtabpage.activity-stream.showSponsored" = false; # Sponsored stories
      settings."browser.newtabpage.activity-stream.showSponsoredTopSites" = false; # Sponsored shortcuts
      settings."browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false; # "Support Firefox" checkbox group in Settings > Home
      settings."browser.topsites.contile.enabled" = false; # Sponsored top-site tile provider (Contile)
      settings."browser.newtabpage.activity-stream.showWeather" = false; # Weather widget
      settings."browser.newtabpage.activity-stream.logowordmark.alwaysVisible" = false; # Firefox logo/wordmark (still shows unless all sections above are also disabled)

      # Hide the Bookmarks.
      settings."browser.toolbars.bookmarks.visibility" = "never";

      # Privacy & Security: don't send data to Mozilla Corporation.
      settings."datareporting.healthreport.uploadEnabled" = false;
      settings."datareporting.usage.uploadEnabled" = false;

      # Block all the AI features.
      settings."browser.ai.control.default" = "blocked";
      settings."browser.ai.control.linkPreviewKeyPoints" = "blocked";
      settings."browser.ai.control.pdfjsAltText" = "blocked";
      settings."browser.ai.control.sidebarChatbot" = "blocked";
      settings."browser.ai.control.smartTabGroups" = "blocked";
      settings."browser.ai.control.smartWindow" = "blocked";
      settings."browser.ai.control.translations" = "blocked";
      settings."browser.ml.chat.enabled" = false;
      settings."browser.ml.chat.page" = false;
      settings."browser.ml.linkPreview.enabled" = false;
      settings."browser.tabs.groups.smart.enabled" = false;
      settings."browser.tabs.groups.smart.userEnabled" = false;

      # Forget all Passwords & Autofill.
      settings."signon.rememberSignons" = false; # Save logins and passwords
      settings."extensions.formautofill.addresses.enabled" = false; # Save and fill addresses
      settings."extensions.formautofill.creditCards.enabled" = false; # Save and fill payment methods
      settings."privacy.clearOnShutdown_v2.formdata" = true; # Clear form data on shutdown
    };
  };

  # --- Zed editor
  programs.zed-editor = {
    enable = true;
    package = pkgs-latest.zed-editor;
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
      "nix"
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
        codex-acp = {
          type = "registry";
        };
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
        {
          token_type = "namespace";
          foreground_color = "#E5C17C"; # yellow
        }
        {
          token_type = "type";
          token_modifiers = [ "declaration" ];
          foreground_color = "#E5C17C"; # yellow
        }
        {
          token_type = "type";
          token_modifiers = [ "definition" ];
          foreground_color = "#E5C17C"; # yellow
        }
        {
          token_type = "type";
          foreground_color = "#c679dd"; # purple
        }
        {
          token_type = "parameter";
          foreground_color = "#D19A66"; # orange
        }
        {
          token_type = "variable";
          foreground_color = "#D19A66"; # orange
        }
        {
          token_type = "property";
          foreground_color = "#D19A66"; # orange
        }
        {
          token_type = "operator";
          foreground_color = "#61AFEF"; # blue
        }
      ];

      theme_overrides."One Dark Pro".syntax = {
        namespace.color = "#E5C17C"; # yellow
        variable.color = "#D19A66"; # orange
        property.color = "#D19A66"; # orange
        type.color = "#c679dd"; # purple
      };
    };
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
  ];
}
