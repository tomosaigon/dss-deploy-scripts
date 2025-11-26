# nix/srcs.nix
rec {
  dapptools = fetchGit {
    url = "https://github.com/tomosaigon/dapptools";
    rev = "253efa39919ce5663a68195ff3b1f3fa1034d403";
  };

  makerpkgsSrc = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "f7a40da6f2b9ecf34d8be9d7b517bba9f7a5ba1d";
  };
}