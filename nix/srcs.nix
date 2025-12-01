rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "12f3297ccc312dc89ad8ff4ea73d976691898739";
    ref = "compat/1.13.0-semver";
  };
}
