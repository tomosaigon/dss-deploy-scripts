rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "71239f26d4a817e516a5d2a20f6678e5c9d29da7";
    ref = "compat/1.13.0-semver";
  };
}
