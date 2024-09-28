{ lib
, pkgs

# Path to use as the Home Manager channel.
, path ? null
}:

let

  src = ../.;
  pathStr =
    if path == null then ""
    else if path == pkgs.path # `path` argument is not passed to `callPackage`
    then "${src}"
    else path;

in

# inherit and override the home-manager package definition from nixpkgs
pkgs.home-manager.overrideAttrs (

  { pname ? "home-manager"
  , passthru ? { }
  , meta ? { }
  , postFixup ? ""
  , ...
  }:

  # remove `version` attributes as we are rolling released
  lib.flip removeAttrs [ "version" ] {
    name = pname;
    inherit src;
    preferLocalBuild = true;

    meta = removeAttrs meta [ "version" ] // {
      maintainers = [ lib.maintainers.rycee ];
    };

    postFixup = ''
      substituteInPlace $out/bin/home-manager \
        --subst-var-by HOME_MANAGER_PATH '${pathStr}' \
    '' + postFixup;

    # remove nixpkgs `updateScript`
    passthru = removeAttrs passthru [ "updateScript" ];
  }
)
