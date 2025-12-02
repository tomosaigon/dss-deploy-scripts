rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "4e44f84f67a90f69f3b76a4b2cacc05e6756b4a9";
    ref = "compat/1.13.0-semver";
  };
}
