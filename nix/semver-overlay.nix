# nix/semver-overlay.nix
self: super: {
  # Intercept the broken GitHub tarball used by old nixpkgs 20.03
  fetchzip = args:
    let
      # Normalise to a single URL string, regardless of whether the
      # call used `url =` or `urls =` (string or list).
      url =
        if args ? url then
          args.url
        else if args ? urls then
          if builtins.isList args.urls then builtins.head args.urls else args.urls
        else
          null;
    in
      if url == "https://github.com/dmjio/semver-range/archive/patch-1.tar.gz"
      then
        super.fetchzip (args // {
          # Rewrite to the Hackage tarball & known-good hash
          url = "https://hackage.haskell.org/package/semver-range-0.2.8/semver-range-0.2.8.tar.gz";
          urls = null; # avoid confusion if the caller passed `urls`
          sha256 = "1df663zkcf7y7a8cf5llf111rx4bsflhsi3fr1f840y4kdgxlvkf";
        })
      else
        super.fetchzip args;

  # Keep your explicit semver-range override in haskellPackages as well
  haskellPackages = super.haskellPackages.override (old: {
    overrides = super.lib.composeExtensions
      (old.overrides or (_: _: {}))
      (self-hs: super-hs: {
        semver-range =
          (super-hs.semver-range.override {})
            .overrideAttrs (_: {
              src = super.fetchurl {
                url = "https://hackage.haskell.org/package/semver-range-0.2.8/semver-range-0.2.8.tar.gz";
                sha256 = "1df663zkcf7y7a8cf5llf111rx4bsflhsi3fr1f840y4kdgxlvkf";
              };
            });
      });
  });
}