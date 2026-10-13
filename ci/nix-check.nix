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
  eval = lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      stubs
      (import ../nix/home-manager.nix self)
      {
        programs.qs-niri = {
          enable = true;
          settings = { launcher.favorites = [ "firefox" ]; gaming.appIds = [ "^heroic" ]; };
        };
      }
    ];
  };
  c = eval.config;
in
assert builtins.length c.home.packages > 3;
assert c.xdg.configFile ? "quickshell/shell.json";
assert c.systemd.user.services ? qs-niri;
pkgs.runCommand "qs-niri-module-ok" { json = c.xdg.configFile."quickshell/shell.json".source; } ''
  cat $json
  grep -q heroic $json
  touch $out
''
