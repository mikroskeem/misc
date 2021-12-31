#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <libgen.h>
#include <limits.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char **argv) {
	int r = 0;
	if (argc < 2 || argc > 3) {
		fprintf(stderr, "USAGE: %s <namespace> [pid]\n", argv[0]);
		return 2;
	}

	size_t len;
	char *ns = alloca((len = strnlen(argv[1], 32)) + 1);
	strncpy(ns, argv[1], len+1);
	ns = basename(ns);

	pid_t pid_to_check = getpid();
	if (argc == 3) {
		unsigned long p = strtoul(argv[2], NULL, 10);
		if (p == ULONG_MAX) {
			fprintf(stderr, "unable to parse pid '%s': %s\n", argv[2], strerror(errno));
			return 2;
		}

		pid_to_check = p;
	}

	char root_ns[4096], self_ns[4096];
	snprintf(root_ns, sizeof(root_ns)-1, "/proc/%d/ns/%s", 1, ns);
	snprintf(self_ns, sizeof(self_ns)-1, "/proc/%d/ns/%s", pid_to_check, ns);

	struct stat root_stat, self_stat;
	if (stat(root_ns, &root_stat) < 0) {
		fprintf(stderr, "stat root_ns: %s\n", strerror(errno));
		return 2;
	}
	if (stat(self_ns, &self_stat) < 0) {
		fprintf(stderr, "stat self_ns: %s\n", strerror(errno));
		return 2;
	}

	int res = root_stat.st_dev == self_stat.st_dev && root_stat.st_ino == self_stat.st_ino;
	fprintf(stderr, "%s == %s: %d\n", root_ns, self_ns, res);
	return !res;
}
