self: super: {
  haskellPackages =
    super.haskellPackages.override (old: {
      overrides = self.lib.composeExtensions
        (old.overrides or (_: _: {}))
        (self-hs: super-hs: {
          semver-range = (super-hs.semver-range.override {}).overrideAttrs (oldAttrs: {
            src = self.pkgs.fetchurl {
              url = "https://hackage.haskell.org/package/semver-range-0.2.8/semver-range-0.2.8.tar.gz";
              sha256 = "1df663zkcf7y7a8cf5llf111rx4bsflhsi3fr1f840y4kdgxlvkf";
            };
          });
        });
    });
}
