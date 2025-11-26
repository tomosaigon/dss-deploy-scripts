rec {
  dapptools = fetchGit {
    url = "https://github.com/tomosaigon/dapptools";
    rev = "253efa39919ce5663a68195ff3b1f3fa1034d403";
  };

  makerpkgs = import (fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "b8aac14157fcb6c49e9cfa82f294433b77df6126";
  }) {
    dapptoolsOverrides = pkgs: {
      haskellPackages =
        pkgs.haskellPackages.override (old: {
          overrides = pkgs.lib.composeExtensions
            (old.overrides or (_: _: {}))
            (self-hs: super-hs: {
              semver-range =
                (super-hs.semver-range.override {})
                  .overrideAttrs (oldAttrs: {
                    src = pkgs.fetchurl {
                      url = "https://hackage.haskell.org/package/semver-range-0.2.8/semver-range-0.2.8.tar.gz";
                      sha256 = "1df663zkcf7y7a8cf5llf111rx4bsflhsi3fr1f840y4kdgxlvkf";
                    };
                  });
            });
        });
    };
  };
}