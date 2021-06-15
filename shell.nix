{ pkgs ? import ./pinned.nix { }
, ghcVer ? "ghc8104"
}:

let
  inherit (pkgs) callPackage lib mkShell;

  # NOTE: Workaround for some 'libtinfo' issues that crop up on NixOS.
  ncurses = callPackage ./ncurses.nix { };

  libraries = [
    pkgs.gmp
    ncurses
    pkgs.icu
    pkgs.zlib
  ];
in

mkShell {
  buildInputs = libraries ++ [
    pkgs.cabal-install
    pkgs.haskell.compiler.${ghcVer}
  ];

  LD_LIBRARY_PATH =
    lib.concatStringsSep ":" (builtins.map (pkg: "${pkg}/lib") libraries);
}
