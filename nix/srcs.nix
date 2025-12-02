rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "c4f56a3c685471baab42764697212f4a78cf7c12";
    ref = "compat/1.13.0-semver";
  };
}
