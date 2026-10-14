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
  c = (evalWith "base").config;
  nMin = builtins.length (evalWith "minimal").config.home.packages;
  nBloat = builtins.length (evalWith "bloated").config.home.packages;
in
assert builtins.length c.home.packages > 3;
assert nMin < builtins.length c.home.packages && builtins.length c.home.packages < nBloat;
assert c.xdg.configFile ? "quickshell/shell.json";
assert c.systemd.user.services ? qs-niri;
pkgs.runCommand "qs-niri-module-ok" { json = c.xdg.configFile."quickshell/shell.json".source; } ''
  cat $json
  grep -q heroic $json
  grep -q '"profile": "base"' $json
  touch $out
''
