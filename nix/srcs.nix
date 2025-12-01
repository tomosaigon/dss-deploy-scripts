rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "d51cbcba9024ba4010e75a8e34c3cc68bde13b42";
    ref = "compat/1.13.0-semver";
  };
}
