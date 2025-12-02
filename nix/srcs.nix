rec {
  # Default import pinned pkgs
  makerpkgs = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "b9ff07530e1334f972dfe2815a74923f68241676";
    ref = "compat/1.13.0-semver";
  };
}
