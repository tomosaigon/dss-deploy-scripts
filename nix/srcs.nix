rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "1bb221c994d5c4ec0b7cc9b205acdf520a700da8";
    ref = "compat/1.13.0-semver";
  };
}
