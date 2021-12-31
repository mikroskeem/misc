#!/usr/bin/env bash
set -euo pipefail

set +e
read -r -d '' derivation <<'EOF'
{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib }:

let
  contPkgs = [
    pkgs.bash
    pkgs.coreutils
    pkgs.zfs
  ];

  usrbin = pkgs.symlinkJoin {
    name = "usrbin-zfs";
    paths = contPkgs;
  };
in
pkgs.dockerTools.buildLayeredImage rec {
  name = "zfs-nixos";

  contents = [
    usrbin
  ];

  extraCommands = ''
    mkdir -p usr
    ln -s ${usrbin}/bin usr/bin
  '';

  config = {
    Entrypoint = [ "${pkgs.dumb-init}/bin/dumb-init" "--" "${pkgs.coreutils}/bin/env" "PATH=/usr/bin" ];
    Cmd = [ "${pkgs.bash}/bin/bash" "-i" ];
  };
}
EOF
set -e

imagegz="$(nix-build --no-out-link - <<< "${derivation}")"
imagename="$(gunzip -c "${imagegz}" | docker image load -q | sed 's/^.\+:\s//')"

docker run --rm -ti --privileged -v /dev/zfs:/dev/zfs "${imagename}"
