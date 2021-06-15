{ ncurses, stdenv, ... }:
let
  inherit (ncurses) abiVersion;
in

ncurses.overrideAttrs (oldAttrs: {
  configureFlags = oldAttrs.configureFlags ++ [
    "--with-termlib"
  ];

  preConfigure = oldAttrs.preConfigure + ''
    configureFlagsArray+=(
      --with-versioned-symbols=$PWD/package/ncursestw.map
    )
  '';

  postFixup =
    let
      abiVersion-extension = if stdenv.isDarwin then "${abiVersion}.$dylibtype" else "$dylibtype.${abiVersion}"; in
    ''
      # Determine what suffixes our libraries have
      suffix="$(awk -F': ' 'f{print $3; f=0} /default library suffix/{f=1}' config.log)"
      libs="$(ls $dev/lib/pkgconfig | tr ' ' '\n' | sed "s,\(.*\)$suffix\.pc,\1,g")"
      suffixes="$(echo "$suffix" | awk '{for (i=1; i < length($0); i++) {x=substr($0, i+1, length($0)-i); print x}}')"
      # Get the path to the config util.
      cfg=$(basename $dev/bin/ncurses*-config)
      # Symlink the full suffixed include directory.
      ln -svf . $dev/include/ncurses$suffix
      for dylibtype in so; do
        if [ -e "$out/lib/libncurses$suffix.$dylibtype" ]; then
          # Create linker script for -lncurses to pull in -ltinfo
          rm $out/lib/libncurses$suffix.$dylibtype
          echo "INPUT(libncurses$suffix.${abiVersion-extension} -ltinfo$suffix)" > $out/lib/libncurses$suffix.$dylibtype
        fi
      done
      for newsuffix in $suffixes ""; do
        # Create a non-abi versioned config util links
        ln -svf $cfg $dev/bin/ncurses$newsuffix-config
        # Allow for end users who #include <ncurses?w/*.h>
        ln -svf . $dev/include/ncurses$newsuffix
        for library in $libs; do
          for dylibtype in so; do
            if [ -e "$out/lib/lib$library$suffix.$dylibtype" ]; then
              echo "INPUT(-l$library$suffix)" > $out/lib/lib$library$newsuffix.$dylibtype
            fi
          done
          for dylibtype in dll dylib; do
            if [ -e "$out/lib/lib''${library}$suffix.$dylibtype" ]; then
              ln -svf lib''${library}$suffix.$dylibtype $out/lib/lib$library$newsuffix.$dylibtype
              ln -svf lib''${library}$suffix.${abiVersion-extension} $out/lib/lib$library$newsuffix.${abiVersion-extension}
            fi
          done
          for statictype in a dll.a la; do
            if [ -e "$out/lib/lib''${library}$suffix.$statictype" ]; then
              ln -svf lib''${library}$suffix.$statictype $out/lib/lib$library$newsuffix.$statictype
            fi
          done
          ln -svf ''${library}$suffix.pc $dev/lib/pkgconfig/$library$newsuffix.pc
        done
      done
      # Move some utilities to '$bin'.
      #
      # These programs are used at runtime and don't really belong in '$dev'.
      moveToOutput 'bin/clear'     "$out"
      moveToOutput 'bin/reset'     "$out"
      moveToOutput 'bin/tabs'      "$out"
      moveToOutput 'bin/tic'       "$out"
      moveToOutput 'bin/tput'      "$out"
      moveToOutput 'bin/tset'      "$out"
      moveToOutput 'bin/captoinfo' "$out"
      moveToOutput 'bin/infotocap' "$out"
      moveToOutput 'bin/infocmp'   "$out"
    '';
})
