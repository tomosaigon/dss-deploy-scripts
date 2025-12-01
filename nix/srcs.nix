rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "66b5d406e42b0a7391e2e313d769b34236acb3c2";
    ref = "compat/1.13.0-semver";
  };
}
