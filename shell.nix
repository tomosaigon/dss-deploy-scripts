# shell.nix
let
  srcs = import ./nix/srcs.nix;

  semverOverlay = self: super: {
    haskellPackages = super.haskellPackages.override (old: {
      overrides = super.lib.composeExtensions
        (old.overrides or (_: _: {}))
        (self-hs: super-hs: {
          semver-range =
            (super-hs.semver-range.override {})
              .overrideAttrs (oldAttrs: {
                src = super.fetchurl {
                  url = "https://hackage.haskell.org/package/semver-range-0.2.8/semver-range-0.2.8.tar.gz";
                  sha256 = "1df663zkcf7y7a8cf5llf111rx4bsflhsi3fr1f840y4kdgxlvkf";
                };
              });
        });
    });
  };

  makerpkgsSources = import (srcs.makerpkgsSrc + "/nix/sources.nix");

  nixpkgsWithSemver = import makerpkgsSources.nixpkgs {
    overlays = [ semverOverlay ];
  };
in

{ pkgs ? import srcs.makerpkgsSrc { pkgs = nixpkgsWithSemver; }
, doCheck ? false
, githubAuthToken ? null
}@args: with pkgs;

let
  dds = import ./. args;
in
mkShell {
  buildInputs = dds.bins ++ [
    dds
    dapp2nix
    procps
  ];

  shellHook = ''
    export NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    unset SSL_CERT_FILE

    setup-env() {
      . ${dds}/lib/setup-env.sh
    }
    export -f setup-env
    setup-env || echo Re-run setup script with \'setup-env\'
  '';
}