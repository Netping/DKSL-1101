/*
 * A simple program for testing IRQs via userspace gpio sysfs
 *
 * Copyright (c) 2016-2017 Daniel Santos <daniel.santos@pobox.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>

static void usage(const char *argv0) {
	fprintf(stderr, "USAGE: %s <file_name>\n\n", argv0);
	fprintf(stderr, "    Where file_name is the name of a sysfs gpio value file.\n");
	fprintf(stderr, "    Example: %s /sys/class/gpio/GP510/value\n\n", argv0);
	fprintf(stderr, "See Documentation/gpio/sysfs.txt for more info\n");
	exit(1);
}

static void poll_pin(const char *fn) {
	struct pollfd fdlist[1];
	int fd;

	fd = open(fn, O_RDONLY);
	if (fd == -1) {
		perror("open");
		fprintf(stderr, "Failed to open file %s\n", fn);
		return;
	}
	fdlist[0].fd = fd;
	fdlist[0].events = POLLPRI;

	while (1) {
		int ret;
		char buf[3];

		if (poll(fdlist, 1, -1) == -1) {
			perror("poll");
			return;
		}

		ret = read(fdlist[0].fd, buf, 2);
		if (ret == -1) {
			perror("read");
			return;
		}
		buf[ret] = 0;
		printf("event on pin %s, value = %c\n", fn, buf[0]);

		if (lseek(fd, 0, SEEK_SET) == -1) {
			perror("lseek");
			return;
		}
	}
}

int main(int argc, char *argv[]) {
	if (argc != 2)
		usage(argv[0]);

	poll_pin(argv[1]);

	return 0;
}
