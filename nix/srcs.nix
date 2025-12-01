rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "d6fd1a1410c1dfd41657c68815c3642b33642787";
    ref = "compat/1.13.0-semver";
  };
}
