#!/usr/bin/env bash
set -euo pipefail

docker container ps --filter label=eu.mikroskeem.zentria.emperor.server-name --format '{{ .Names }}' | while read -r cont_name; do
	id="$(docker container inspect "${cont_name}" | jq -r '.[0].Id')"
	cg=/sys/fs/cgroup/system.slice/docker-"${id}".scope
	echo "${cont_name} -> ${id}: $(< "${cg}"/pids.current)"
done
