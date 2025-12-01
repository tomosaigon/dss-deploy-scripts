rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "6afbf1bf4cea038ff79730330f1e1d9d5aad7ef7";
    ref = "compat/1.13.0-semver";
  };
}
