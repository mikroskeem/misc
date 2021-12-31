#!/bin/sh

m=/mnt/ov
up=${m}/tmpfs
l=${m}/zfs
w=$up/work
u=$up/up

mkdir -p $u
mkdir -p $l
mkdir -p $m

unshare --mount sh -c "
	set -eux

	mount -t tmpfs tmpfs /mnt

	mkdir -p $up
	mount -t tmpfs -o nosuid tmpfs $up

	mkdir -p $l $w $u

	zfs_opts=( rw )
	if ! [ \"\$(zfs get -H -p -o value mountpoint rpool/overlay_test)\" = \"legacy\" ]; then
		zfs_opts+=(zfsutil)
	fi
	mount -t zfs -o \"\$(IFS=, ; echo \"\${zfs_opts[*]}\")\" rpool/overlay_test $l
	date > $l/date.txt

	mount -t overlay -o lowerdir=$l,upperdir=$u,workdir=$w overlay $m
	cd /mnt
	mount | grep /mnt/ov
	exec sh -i
"
