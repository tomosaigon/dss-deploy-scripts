rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "7b07ec0d6c504f42ede4a77e3a80a2a2516b463b";
    ref = "compat/1.13.0-semver";
  };
}
