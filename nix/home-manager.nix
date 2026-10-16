# Home Manager module for qs-niri.
#
#   programs.qs-niri = {
#     enable = true;
#     settings = {
#       launcher.favorites = [ "firefox" "kitty" ];
#       gaming.appIds = [ "^heroic" ];
#       paths.screenshotsDir = "~/Pictures/Screenshots";
#     };
#   };
#
# `settings` is written to ~/.config/quickshell/shell.json (the same file the
# shell watches, see README "Configuration Reference"); keys you leave out keep
# the shell's built-in defaults.
self: { config, lib, pkgs, ... }:

let
  cfg = config.programs.qs-niri;
  json = pkgs.formats.json { };
in
{
  options.programs.qs-niri = {
    enable = lib.mkEnableOption "the qs-niri Quickshell desktop shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "qs-niri.packages.\${system}.default";
      description = "The shell's QML tree (without shell.json, which is generated from `settings`).";
    };

    quickshell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      defaultText = lib.literalExpression "pkgs.quickshell";
      description = "The Quickshell package used to run the shell.";
    };

    profile = lib.mkOption {
      type = lib.types.enum [ "minimal" "base" "bloated" ];
      default = "base";
      description = ''
        How much of the shell is switched on (and which runtime tools get installed):

        - minimal: bar, launcher, control center, notifications; nothing extra.
        - base: minimal plus gaming mode, screen recording, hotspot, speed test, task manager, clipboard history.
        - bloated: base plus night light / airplane / VPN tiles, live network speed and the taskbar.

        Single features can be overridden with `settings.features.<name>`.
      '';
    };

    settings = lib.mkOption {
      type = json.type;
      default = { };
      example = lib.literalExpression ''
        {
          launcher.favorites = [ "firefox" "kitty" ];
          gaming = { autoDetect = true; appIds = [ "^heroic" ]; };
        }
      '';
      description = "Contents of shell.json. Anything omitted falls back to the shell's defaults.";
    };

    installDependencies = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the runtime tools the shell shells out to (wl-clipboard,
        playerctl, brightnessctl, grim, ...). Which ones depends on `profile`.
        Disable if you already provide them.
      '';
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start the shell with the graphical session (systemd user service).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ cfg.quickshell ]
      ++ lib.optionals cfg.installDependencies (with pkgs;
        [ wl-clipboard playerctl brightnessctl grim slurp libnotify pywal
          (pkgs.noto-fonts-color-emoji or pkgs.noto-fonts-emoji) ] # last one: emoji picker font
        ++ lib.optionals (cfg.profile != "minimal") [
          gpu-screen-recorder power-profiles-daemon papirus-icon-theme
          cliphist qrencode
        ]
        ++ lib.optionals (cfg.profile == "bloated") [
          wlsunset util-linux # util-linux provides rfkill
        ]);

    # The QML tree is the Quickshell config directory; shell.json is generated.
    xdg.configFile."quickshell" = {
      source = cfg.package;
      recursive = true;
    };
    xdg.configFile."quickshell/shell.json".source =
      json.generate "qs-niri-shell.json" (lib.recursiveUpdate { inherit (cfg) profile; } cfg.settings);

    systemd.user.services.qs-niri = lib.mkIf cfg.autostart {
      Unit = {
        Description = "qs-niri Quickshell shell";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${cfg.quickshell}/bin/quickshell";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
