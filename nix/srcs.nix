rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "f1af4a4b9fae8cb5d02e1e1f2c7459ed7d1c065f";
    ref = "compat/1.13.0-semver";
  };
}
