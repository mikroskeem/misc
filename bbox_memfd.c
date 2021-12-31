// for memfd_create
#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <libgen.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <string.h>
#include <unistd.h>

int find_path(const char *path, const char *name, char **found) {
	int r = 0;
	char *pathdup = alloca(strlen(path) + 1), *namedup = alloca(strlen(name) + 1), *dir = NULL;
	strcpy(pathdup, path);
	strcpy(namedup, name);

	namedup = basename(namedup);

	for (dir = strtok(pathdup, ":"); dir; dir = strtok(NULL, ":")) {
		size_t binpath_sz = strlen(dir) + 1 + strlen(namedup) + 1;
		char *binpath = alloca(binpath_sz);
		snprintf(binpath, binpath_sz, "%s/%s", dir, namedup);

		struct stat s;
		if ((r = stat(binpath, &s)) < 0) {
			int err = errno;
			switch (err) {
				case EACCES:
				case ELOOP:
				case ENAMETOOLONG:
				case ENOENT:
				case ENOTDIR:
					continue;
				default:
					return -1;
			}
		} else if (S_ISREG(s.st_mode) && (s.st_mode & S_IXOTH) != 0) {
			char *_found = malloc(binpath_sz);
			strcpy(_found, binpath);
			*found = _found;
			return 0;
		}
	}

	return -1;
}

int main(int argc, char **argv) {
	int r;

	char *bbox_path = NULL;
	if ((r = find_path(getenv("PATH"), "busybox", &bbox_path)) < 0) {
		perror("find_path");
		return 1;
	}

	int memfd = r = memfd_create("", MFD_CLOEXEC);
	if (r < 0) {
		perror("memfd_create");
		return 1;
	}

	int bbox_fd = open(bbox_path, O_RDONLY | O_CLOEXEC);
	if (r < 0) {
		perror("open");
		return 1;
	}
	free(bbox_path);

	char buf[1024];
	while ((r = read(bbox_fd, buf, 1024)) > 0) {
		if ((r = write(memfd, buf, r)) < 0) {
			perror("write");
			return 1;
		}
	}
	if (r < 0) {
		perror("splice");
		return 1;
	}

	snprintf(buf, sizeof(buf)-1, "/proc/self/fd/%i", memfd);

	pid_t child = fork();
	if (child == 0) {
		execl(buf, "ash", "-i", NULL);
		perror("execl");
		_exit(1);
	} else if (child < 0) {
		perror("fork");
		return 1;
	}

	waitpid(child, NULL, 0);

	return 0;
}
