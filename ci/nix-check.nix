# Evaluates nix/home-manager.nix against stub Home Manager options and checks
# the generated shell.json / service, so the module is exercised without a
# full Home Manager checkout.
let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;
  flake = import ../flake.nix;
  self = {
    packages.${pkgs.stdenv.hostPlatform.system}.default = pkgs.runCommand "qs-niri-src" { } "mkdir $out";
  };
  stubs = { lib, ... }: {
    options = {
      home.packages = lib.mkOption { type = lib.types.listOf lib.types.package; default = [ ]; };
      xdg.configFile = lib.mkOption { type = lib.types.attrsOf lib.types.attrs; default = { }; };
      systemd.user.services = lib.mkOption { type = lib.types.attrsOf lib.types.attrs; default = { }; };
    };
  };
  evalWith = profile: lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      stubs
      (import ../nix/home-manager.nix self)
      {
        programs.qs-niri = {
          enable = true;
          inherit profile;
          settings = { launcher.favorites = [ "firefox" ]; gaming.appIds = [ "^heroic" ]; };
        };
      }
    ];
  };
  # NixOS module (greetd) against stub options
  nixosWith = profile: (lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      ({ lib, ... }: { options.services.greetd = {
        enable = lib.mkOption { type = lib.types.bool; default = false; };
        settings = lib.mkOption { type = lib.types.attrs; default = { }; };
      }; })
      (import ../nix/nixos.nix self)
      { programs.qs-niri-system = { enable = true; inherit profile; greeter.user = "kullanici"; }; }
    ];
  }).config.services.greetd.settings.default_session.command;
  greeterBloated = nixosWith "bloated";
  greeterBase = nixosWith "base";
  c = (evalWith "base").config;
  nMin = builtins.length (evalWith "minimal").config.home.packages;
  nBloat = builtins.length (evalWith "bloated").config.home.packages;
in
assert builtins.length c.home.packages > 3;
assert nMin < builtins.length c.home.packages && builtins.length c.home.packages < nBloat;
assert c.xdg.configFile ? "quickshell/shell.json";
assert c.systemd.user.services ? qs-niri;
assert lib.hasInfix "quickshell" greeterBloated && lib.hasInfix "QS_GREETER_USER=kullanici" greeterBloated;
assert lib.hasInfix "tuigreet" greeterBase;
pkgs.runCommand "qs-niri-module-ok" { json = c.xdg.configFile."quickshell/shell.json".source; } ''
  cat $json
  grep -q heroic $json
  grep -q '"profile": "base"' $json
  touch $out
''
