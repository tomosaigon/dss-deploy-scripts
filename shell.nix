# shell.nix
let
  srcs = import ./nix/srcs.nix;

  semverOverlay = import ./nix/semver-overlay.nix;

  makerpkgsSources = import (srcs.makerpkgsSrc + "/nix/sources.nix");

  nixpkgsWithSemver = import makerpkgsSources.nixpkgs {
    overlays = [ semverOverlay ];
  };
in

{ pkgs ? import srcs.makerpkgsSrc { pkgs = nixpkgsWithSemver; }
, doCheck ? false
, githubAuthToken ? null
}@args:

with pkgs;

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