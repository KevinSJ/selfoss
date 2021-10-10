{
  description = "selfoss feed reader and aggregator";

  inputs = {
    # Shim to make flake.nix work with stable Nix.
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # Repository with software packages.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    utils.url = "github:numtide/flake-utils";

    # Package expression for old PHP versions.
    phps.url = "github:fossar/nix-phps";
  };

  outputs = { self, flake-compat, nixpkgs, phps, utils }:
    let
      # Configure the development shell here (e.g. for CI).

      # By default, we use the default PHP version from Nixpkgs.
      matrix.phpPackage = "php";
    in
    # For each supported platform,
    utils.lib.eachDefaultSystem (system:
      let
        # Get Nixpkgs packages for current platform.
        pkgs = nixpkgs.legacyPackages.${system};

        # Create a PHP package from the selected PHP package, with some extra extensions enabled.
        php = phps.packages.${system}.${matrix.phpPackage}.withExtensions ({ enabled, all }: with all; enabled ++ [
          imagick
        ]);

        # Create a Python package with some extra packages installed.
        python = pkgs.python3.withPackages (pp: with pp; [
          # For integration tests.
          bcrypt
          requests
        ]);
      in
      {
        # Expose shell environment for development.
        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            # Composer and PHP for back-end.
            php
            php.packages.composer

            # Back-end code validation.
            php.packages.psalm
            php.packages.phpstan

            # npm for front-end.
            pkgs.nodejs_latest

            # For building zip archive.
            pkgs.jq

            # For building zip archive and integration tests.
            python

            # Website generator.
            pkgs.zola
          ];

          # node-gyp wants some locales, let’s make them available through an environment variable.
          LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        };
      }
    );
}
