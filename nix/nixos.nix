# NixOS module: the login screen (greetd). Home Manager can't do this, greetd
# is a system service.
#
#   imports = [ inputs.qs-niri.nixosModules.default ];
#   programs.qs-niri-system = {
#     enable = true;
#     profile = "bloated";          # bloated: One UI greeter; minimal/base: tuigreet
#     greeter.user = "kullanici";
#     greeter.wallpaper = ./wall.png;
#   };
#
# Keep the profile equal to programs.qs-niri.profile in Home Manager.
self: { config, lib, pkgs, ... }:

let
  cfg = config.programs.qs-niri-system;
  g = cfg.greeter;
  oneui = lib.concatStringsSep " " [
    "${pkgs.cage}/bin/cage -s -d --"
    "${pkgs.coreutils}/bin/env"
    "QS_GREETER_CMD=${lib.escapeShellArg g.command}"
    (lib.optionalString (g.user != "") "QS_GREETER_USER=${lib.escapeShellArg g.user}")
    (lib.optionalString (g.wallpaper != null) "QS_GREETER_WALLPAPER=${g.wallpaper}")
    "${cfg.quickshell}/bin/quickshell -p ${cfg.package}/greeter.qml"
  ];
  tui = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${lib.escapeShellArg g.command}";
in
{
  options.programs.qs-niri-system = {
    enable = lib.mkEnableOption "the qs-niri system parts (login screen)";

    profile = lib.mkOption {
      type = lib.types.enum [ "minimal" "base" "bloated" ];
      default = "base";
      description = "bloated gets the One UI greeter, the other profiles get tuigreet.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "qs-niri.packages.\${system}.default";
      description = "The shell's QML tree (the greeter is its `greeter.qml`).";
    };

    quickshell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      defaultText = lib.literalExpression "pkgs.quickshell";
      description = "The Quickshell package used to run the One UI greeter.";
    };

    greeter = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Configure greetd. Set to false to keep your own greetd setup.";
      };
      command = lib.mkOption {
        type = lib.types.str;
        default = "niri-session";
        description = "Session started after login.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "User name prefilled in the One UI greeter (tuigreet remembers the last user itself).";
      };
      wallpaper = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Wallpaper for the One UI greeter. Copied to the store, so the greeter user can read it.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && g.enable) {
    services.greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
        command = if cfg.profile == "bloated" then oneui else tui;
      };
    };
  };
}
