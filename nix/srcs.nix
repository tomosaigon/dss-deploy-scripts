rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "474c1d0577aab05e34ffde2874e96f1794f6f3ea";
    ref = "compat/1.13.0-semver";
  };
}
