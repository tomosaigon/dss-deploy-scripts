rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "26dd5b24a587041b24a3a1e8a56fb86547739ba2";
    ref = "compat/1.13.0-semver";
  };
}
