#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bubblewrap rlwrap
set -euo pipefail

h=/home/mark/fte
sv=/home/mark/fteqw-code/engine/release/fteqw-sv

cd "${h}" || exit 1

bwrap="$(readlink -f -- "$(command -v bwrap)")"
rlwrap="$(readlink -f -- "$(command -v rlwrap)")"
bash="$(readlink -f -- "$(command -v bash)")"
env -i TERM="${TERM}" HOME=/data \
        "${bwrap}" --unshare-all \
        --share-net \
        --bind "${h}" / \
        --bind "${h}/data" /data \
        --ro-bind /nix /nix \
        --ro-bind /etc /etc \
        --ro-bind "${sv}" "/$(basename -- ${sv})" \
        --uid 0 --gid 0 \
        --hostname "quake" \
        --dir /dev --dev /dev \
        --dir /proc --proc /proc \
        --dir /tmp --tmpfs /tmp \
        -- "${rlwrap}" "/$(basename -- ${sv})" -nohome -basedir /data -game ad
