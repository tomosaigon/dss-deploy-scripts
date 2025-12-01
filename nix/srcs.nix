rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "e161765790732a9b58e0f3bc7f31308f4949d239";
    ref = "compat/1.13.0-semver";
  };
}
