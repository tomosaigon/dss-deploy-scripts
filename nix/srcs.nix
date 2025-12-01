rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "a96d715d15c1e72aa7bddc023a738420e13bf8b3";
    ref = "compat/1.13.0-semver";
  };
}
