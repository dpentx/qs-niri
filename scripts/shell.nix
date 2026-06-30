{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3Packages.playwright
    pkgs.python3Packages.beautifulsoup4
    pkgs.playwright-driver.browsers
  ];

  # Playwright kendi indirdiği (genel Linux için derlenmiş, NixOS'ta
  # çalışmayan) Chromium'u değil, nixpkgs'in patchlenmiş sürümünü kullansın.
  PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
}
