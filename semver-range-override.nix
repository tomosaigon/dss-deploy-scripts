# semver-range-override.nix
self: super:
let
  _ =
    builtins.trace
      "SEMRANGE-OVERLAY-LOADED (dss-deploy-scripts)"
      true;

  badUrl =
    "https://github.com/dmjio/semver-range/archive/patch-1.tar.gz";

  hackageUrl =
    "https://hackage.haskell.org/package/semver-range-0.2.8/semver-range-0.2.8.tar.gz";

  wrapFetchurl = orig: args@{ url ? "", ... }:
    let
      needsFix = (url == badUrl);

      fixedArgs =
        if needsFix then
          builtins.trace
            "SEMRANGE-FETCHURL-OVERRIDE (dss-deploy-scripts): redirecting semver-range patch-1 to Hackage"
            (args // { url = hackageUrl; })
        else
          args;
    in
      orig fixedArgs;
in
{
  # Intercept pkgs.fetchurl and rewrite ONLY the bad semver-range URL.
  fetchurl = wrapFetchurl super.fetchurl;
}