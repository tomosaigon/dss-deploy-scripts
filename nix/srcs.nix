rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "f6769a656a603cebcb1d0db53cc8da3d99289736";
    ref = "compat/1.13.0-semver";
  };
}
