#!/usr/bin/env bash
set -euo pipefail

dataset="${1}"

dstype="$(zfs get -H -p -o value type "${dataset}")"
selfmntns="$(readlink "/proc/$$/ns/mnt")"

get_mp_status () {
	proc="${1}"
	device="${2}"

	# Try to find the mountpoint.
	mountpoint="$(findmnt --tab-file "${proc}/mountinfo" -nr -o target -S "${device}" 2>/dev/null)"
	[ -z "${mountpoint}" ] && return 1

	# If we're in different namespace, use nsenter
	nse=()
	mntns="${proc}/ns/mnt"
	if ! [ "$(readlink "${mntns}")" = "${selfmntns}" ]; then
		nse+=(nsenter --no-fork --mount="${mntns}")
	fi

	# Check if something is using the dataset
	#lsof -Fp "${mountpoint}" | sed 's/^p//'
	if ${nse[@]} lsof -Fp "${mountpoint}" &> /dev/null; then
		echo "in_use:${mntns}"
		return 0
	else
		echo "mounted:${mntns}"
		return 0
	fi
}


declare -A visited_ns
visited_ns["${selfmntns}"]="1"

# Check if we have it mounted in this namespace
if get_mp_status /proc/self "${dataset}"; then
	exit 0
fi

# Dig in the mount namespaces
for proc in /proc/[0-9]*; do
	mntns="$(readlink "${proc}/ns/mnt")"

	# XXX: need to relaxen the unbound variable check here.
	set +u
	if [[ "${visited_ns["${mntns}"]}" == "1" ]]; then # Skip already visited namespaces
		set -u
		continue
	fi
	set -u

	visited_ns["${mntns}"]="1"

	if get_mp_status "${proc}" "${dataset}"; then
		exit 0
	fi
done

# If it's a snapshot, check if there are any holds
if [ "${dstype}" = "snapshot" ] && [ "$(zfs holds -H "${dataset}" | wc -l)" -gt 0 ]; then
	echo "holds"
	exit 0
fi

echo "unknown"
