{ stdenvNoCC, lib, bash, callPackage, coreutils, findutils, gettext, gnused, jq
, less, ncurses, inetutils
# used for pkgs.path for nixos-option
, pkgs
, installShellFiles

# Path to use as the Home Manager channel.
, path ? null }:

let

  pathStr = if path == null then "" else path;

  nixos-option = pkgs.nixos-option or (callPackage
    (pkgs.path + "/nixos/modules/installer/tools/nixos-option") { });

in stdenvNoCC.mkDerivation (finalAttrs: {
  name = "home-manager";
  src = ../.;
  preferLocalBuild = true;
  nativeBuildInputs = [ gettext installShellFiles ];
  meta = with lib; {
    mainProgram = "home-manager";
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.unix;
    license = licenses.mit;
  };
dontConfigure = true;
dontBuild = true;
installPhase = ''
  runHook preInstall

  install -v -D -m755 home-manager/home-manager $out/bin/home-manager
  install -v -D -m755 lib/bash/home-manager.sh $out/share/bash/home-manager.sh

  substituteInPlace $out/bin/home-manager \
    --subst-var-by bash "${bash}" \
    --subst-var-by DEP_PATH "${
      lib.makeBinPath [
        coreutils
        findutils
        gettext
        gnused
        jq
        less
        ncurses
        nixos-option
        inetutils # for `hostname`
      ]
    }" \
    --subst-var-by HOME_MANAGER_LIB '$out/share/bash/home-manager.sh' \
    --subst-var-by HOME_MANAGER_PATH '${if path == pkgs.path /* `path` is not passed to `callPackage` */ then finalAttrs.src else pathStr}' \
    --subst-var-by OUT "$out"

  installShellCompletion --bash --name home-manager.bash home-manager/completion.bash
  installShellCompletion --zsh --name _home-manager home-manager/completion.zsh
  installShellCompletion --fish --name home-manager.fish home-manager/completion.fish

  for pofile in home-manager/po/*.po; do
    lang="''${pofile##*/}"
    lang="''${lang%%.*}"
    mkdir -p "$out/share/locale/$lang/LC_MESSAGES"
    msgfmt -o "$out/share/locale/$lang/LC_MESSAGES/home-manager.mo" "$pofile"
  done

  runHook postInstall
'';
})
