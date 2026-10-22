# Manjaro in one file: the config (manix) and the shell (qs-niri) are fetched from GitHub, so no git
# checkout to keep in sync. Put this file in ~/.config/maos/ and run once:
#   nix run --accept-flake-config home-manager -- switch --flake ~/.config/maos#manjaro -b backup
# After that, `rebuild` (zsh alias set below) does `nix flake update` + switch: that is the whole update.
{
  description = "Manjaro: manix + qs-niri straight from GitHub";

  nixConfig = {
    extra-substituters = [ "https://dpentx.cachix.org" ];
    extra-trusted-public-keys = [ "dpentx.cachix.org-1:LUimyvpOmN+reXprnlaRof/pkA+RXVgFxf1UgKXsm1M=" ];
  };

  inputs = {
    manix = {
      url = "github:dpentx/manix/manjaro-ci";
      inputs.qs-niri.follows = "qs-niri";   # one copy of the shell for both
    };
    nixpkgs.follows = "manix/nixpkgs";
    home-manager.follows = "manix/home-manager";
    qs-niri = {
      url = "github:dpentx/qs-niri/oneui8-adapt";
      inputs.nixpkgs.follows = "manix/nixpkgs";
    };
  };

  outputs = { manix, nixpkgs, home-manager, qs-niri, ... }:
    let
      user = "asus";   # your Manjaro login name
      dir = "~/.config/maos";
    in
    {
      homeConfigurations.manjaro = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
        extraSpecialArgs.inputs = manix.inputs // { inherit qs-niri; };
        modules = [
          (manix + "/manjaro/home.nix")
          ({ lib, ... }: {
            home.username = lib.mkForce user;
            # 40 beats the mkForce (50) of the alias in manjaro/home.nix, which expects a git checkout
            programs.zsh.shellAliases.rebuild = lib.mkOverride 40
              "nix flake update --flake ${dir} && home-manager switch --flake ${dir}#manjaro -b backup";
          })
        ];
      };
    };
}
