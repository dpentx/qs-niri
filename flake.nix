{
  description = "qs-niri: a Samsung One UI 8 flavoured Quickshell shell for niri";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # The QML tree, minus repo tooling and the sample shell.json (the
      # Home Manager module generates that one from `programs.qs-niri.settings`).
      packages = forAll (pkgs: {
        default = pkgs.lib.cleanSourceWith {
          src = ./.;
          name = "qs-niri-source";
          filter = path: type:
            let
              rel = pkgs.lib.removePrefix (toString ./. + "/") (toString path);
              skip = [ ".git" ".github" "ci" "nix" "flake.nix" "flake.lock" "shell.json" "FINAL_FIXES_COMPLETE.md" ];
            in
            !(builtins.elem rel skip) && pkgs.lib.cleanSourceFilter path type;
        };
      });

      homeManagerModules.default = import ./nix/home-manager.nix self;
      homeManagerModules.qs-niri = self.homeManagerModules.default;

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.quickshell pkgs.nixpkgs-fmt ];
        };
      });
    };
}
