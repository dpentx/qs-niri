{
  description = "qs-niri: a Samsung One UI 8 flavoured Quickshell shell for niri";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # the file manager's copy engine (not in nixpkgs)
  inputs.cppp = { url = "github:dpentx/cppp"; flake = false; };

  outputs = { self, nixpkgs, cppp }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # The QML tree, minus repo tooling and the sample shell.json (the
      # Home Manager module generates that one from `programs.qs-niri.settings`).
      packages = forAll (pkgs:
        let
          src = pkgs.lib.cleanSourceWith {
          src = ./.;
          name = "qs-niri-source";
          filter = path: type:
            let
              rel = pkgs.lib.removePrefix (toString ./. + "/") (toString path);
              skip = [ ".git" ".github" "ci" "nix" "flake.nix" "flake.lock" "shell.json" ];
            in
            !(builtins.elem rel skip) && pkgs.lib.cleanSourceFilter path type;
          };
        in
        {
          cppp = pkgs.stdenv.mkDerivation {
            pname = "cppp";
            version = "git";
            src = cppp;
            nativeBuildInputs = [ pkgs.cmake ];
            buildInputs = [ pkgs.openssl ];
            # upstream builds with AddressSanitizer; a packaged binary should not
            postPatch = "sed -i 's/ -fsanitize=address -g//' CMakeLists.txt";
            installPhase = "install -Dm755 cppp $out/bin/cppp";
            meta.mainProgram = "cppp";
          };

          # The same tree plus a REV file, so the About page can show which commit is installed.
          default = pkgs.runCommand "qs-niri-source" { } ''
            cp -r ${src} $out
            chmod -R u+w $out
            echo ${self.shortRev or self.dirtyShortRev or "unknown"} > $out/REV
          '';
        });

      homeManagerModules.default = import ./nix/home-manager.nix self;
      nixosModules.default = import ./nix/nixos.nix self;
      nixosModules.qs-niri = self.nixosModules.default;
      homeManagerModules.qs-niri = self.homeManagerModules.default;

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.quickshell pkgs.nixpkgs-fmt ];
        };
      });
    };
}
