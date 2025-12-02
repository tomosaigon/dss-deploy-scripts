let
  srcs = import ./nix/srcs.nix;
in
{ dapptoolsOverrides ? {}
, pkgs ?
    let
      # Original makerpkgs import
      basePkgs = import srcs.makerpkgs {
        inherit dapptoolsOverrides;
      };

      # Apply our local overlay that intercepts the broken semver-range fetchzip URL
      pkgsWithSemverFix = basePkgs.extend (import ./semver-range-override.nix);
    in pkgsWithSemverFix
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
