rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "ac588f408fa7ce0af6abb9ca124a784c8665fcf9";
    ref = "compat/1.13.0-semver";
  };
}
