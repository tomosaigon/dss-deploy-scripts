# shell.nix
let
  # Args passed by the caller (e.g. `nix-shell shell.nix --arg ...`).
  # By default we just use an empty set.
  args = { };

  srcs = import ./nix/srcs.nix;

  # Allow overriding the makerpkgs source via environment
  makerpkgsPath =
    let p = builtins.getEnv "MAKERPKGS_PATH";
    in if p != "" then p else srcs.makerpkgs;

  # Local DappTools override: force semver-range 0.2.8 from Hackage
  localDapptoolsOverrides = {
    semver-range = hself: hsuper: {
      semver-range = hsuper.callHackage "semver-range" "0.2.8" {};
    };
  };

  # Base pkgs from makerpkgs, with our semver-range override wired in.
  # If the caller wants to add more dapptoolsOverrides, they can pass
  # args.dapptoolsOverrides and we merge it here.
  basePkgs = import makerpkgsPath {
    dapptoolsOverrides =
      (args.dapptoolsOverrides or { }) // localDapptoolsOverrides;
  };

  # Apply URL-based override that rewrites the GitHub patch-1 URL → Hackage
  pkgs = basePkgs.extend (import ./semver-range-override.nix);

  # Import dss-deploy-scripts/default.nix using this pkgs set
  dds = import ./. (args // { pkgs = pkgs; });
in
pkgs.mkShell {
  buildInputs = dds.bins ++ [
    dds
    pkgs.dapp2nix
    pkgs.procps
  ];

  shellHook = ''
    export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    unset SSL_CERT_FILE

    setup-env() {
      . ${dds}/lib/setup-env.sh
    }
    export -f setup-env
    setup-env || echo Re-run setup script with \'setup-env\'
  '';
}