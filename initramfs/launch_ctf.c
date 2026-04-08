#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

int main(void)
{
	if (chdir("/home/ctf") != 0) {
		fprintf(stderr, "chdir /home/ctf failed: %s\n", strerror(errno));
		return 1;
	}

	if (setgid(1000) != 0) {
		fprintf(stderr, "setgid failed: %s\n", strerror(errno));
		return 1;
	}

	if (setuid(1000) != 0) {
		fprintf(stderr, "setuid failed: %s\n", strerror(errno));
		return 1;
	}

	setenv("HOME", "/home/ctf", 1);
	setenv("USER", "ctf", 1);
	setenv("LOGNAME", "ctf", 1);
	setenv("PS1", "ctf$ ", 1);

	execl("/bin/sh", "sh", "-i", (char *)NULL);

	fprintf(stderr, "exec /bin/sh failed: %s\n", strerror(errno));
	return 1;
}
