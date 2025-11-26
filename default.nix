# default.nix
let
  srcs = import ./nix/srcs.nix;

  # Global semver-range override on the pinned nixpkgs
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

  # Import makerpkgs' pinned sources.nix to get the nixpkgs pin
  makerpkgsSources = import (srcs.makerpkgsSrc + "/nix/sources.nix");

  # Instantiate THAT pinned nixpkgs with our overlay
  nixpkgsWithSemver = import makerpkgsSources.nixpkgs {
    overlays = [ semverOverlay ];
  };
in

{ pkgs ? import srcs.makerpkgsSrc { pkgs = nixpkgsWithSemver; }
, doCheck ? false
, githubAuthToken ? null
}: with pkgs;

let
  inherit (builtins) replaceStrings;
  inherit (lib) mapAttrs optionalAttrs id;
  inherit (callPackage ./dapp2.nix {}) specs packageSpecs package;
  inherit (specs.this) deps;
  optinalFunc = x: fn: if x then fn else id;

  # Update GitHub repo URLs and add a auth token for private repos
  addGithubToken = spec: spec // (let
    url = replaceStrings
      [ "https://github.com" ]
      [ "https://${githubAuthToken}@github.com" ]
      spec.repo.url;
  in rec {
    repo = spec.repo // { inherit url; };
  });

  # Recursively add GitHub auth token to spec
  recAddGithubToken = spec: addGithubToken (spec // {
    deps = mapAttrs (_: recAddGithubToken) spec.deps;
  });

  # Update dependency specs with default values
  deps' = (mapAttrs (_: spec:
    (optinalFunc (! isNull githubAuthToken) recAddGithubToken)
      (spec // {
        inherit doCheck;
        solc = solc-versions.solc_0_5_12;
      })
  ) deps);

  # Create derivations from lock file data
  packages = packageSpecs (deps' // {
    # Package overrides
    clipper-mom = deps'.clipper-mom                 // { name = "clipper-mom-optimized";       solcFlags = "--optimize --optimize-runs 200"; solc = solc-static-versions.solc_0_6_12; };
    ilk-registry = deps'.ilk-registry               // { name = "ilk-registry-optimized";      solcFlags = "--optimize --optimize-runs 1000000"; solc = solc-static-versions.solc_0_6_12; };
    dss-auto-line = deps'.dss-auto-line             // { name = "dss-auto-line-optimized";     solcFlags = "--optimize --optimize-runs 1000000"; solc = solc-static-versions.solc_0_6_11; };
    dss-flash = deps'.dss-flash                     // { name = "dss-flash";                   solc = solc-static-versions.solc_0_6_12; };
    dss-proxy-actions = deps'.dss-proxy-actions     // { name = "dss-proxy-actions-optimized"; solcFlags = "--optimize"; };
    dss-deploy-1_2 = deps'.dss-deploy-1_2           // { name = "dss-deploy-1_2";              solc = solc-versions.solc_0_5_12; };
    dss-deploy = deps'.dss-deploy                   // { name = "dss-deploy";                  solc = solc-static-versions.solc_0_6_12; };
    dss-deploy-optimized-runs-1 = deps'.dss-deploy  // { name = "dss-deploy-optimized-runs-1"; solcFlags = "--optimize --optimize-runs 1"; solc = solc-static-versions.solc_0_6_12; };
    symbolic-voting = deps'.symbolic-voting         // { name = "symbolic-voting";             solc = solc-static-versions.solc_0_6_6; };
    vote-delegate = deps'.vote-delegate             // { name = "vote-delegate-optimized";     solcFlags = "--optimize --optimize-runs 200"; solc = solc-static-versions.solc_0_6_12; };
    dss-vest-1_0_1 = deps'.dss-vest-1_0_1           // { name = "dss-vest-1_0_1-optimized";    solcFlags = "--optimize --optimize-runs 200"; solc = solc-static-versions.solc_0_6_12; };
    dss-vest = deps'.dss-vest                       // { name = "dss-vest-optimized";          solcFlags = "--optimize --optimize-runs 200"; solc = solc-static-versions.solc_0_6_12; };
    dss-chain-log = deps'.dss-chain-log             // { name = "dss-chain-log-optimized";     solcFlags = "--optimize --optimize-runs 200"; solc = solc-static-versions.solc_0_6_12; };
  });

in
makerScriptPackage {
  name = "dss-deploy-scripts";
  extraBins = [ dappPkgsVersions.hevm-0_43_1.dapp ];
  src = lib.sourceByRegex ./. [
    "bin" "bin/.*"
    "lib" "lib/.*"
    "libexec" "libexec/.*"
    "config" "config/.*"
  ];
  solidityPackages = builtins.attrValues packages;
}