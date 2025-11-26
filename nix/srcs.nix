# nix/srcs.nix
rec {
  dapptools = fetchGit {
    url = "https://github.com/tomosaigon/dapptools";
    rev = "253efa39919ce5663a68195ff3b1f3fa1034d403";
  };

  makerpkgsSrc = fetchGit {
    url = "https://github.com/tomosaigon/makerpkgs";
    rev = "56eadc75fd3518702670105ed4c26d669b162b84";
  };
}