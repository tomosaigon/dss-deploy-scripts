rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "787a0ad9579271ddb0eb1d43796ce76f1387754a";
    ref = "compat/1.13.0-semver";
  };
}
