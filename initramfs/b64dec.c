#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static signed char decode_char(int ch)
{
	if (ch >= 'A' && ch <= 'Z')
		return (signed char)(ch - 'A');
	if (ch >= 'a' && ch <= 'z')
		return (signed char)(ch - 'a' + 26);
	if (ch >= '0' && ch <= '9')
		return (signed char)(ch - '0' + 52);
	if (ch == '+')
		return 62;
	if (ch == '/')
		return 63;
	if (ch == '=')
		return -2;
	if (isspace((unsigned char)ch))
		return -3;
	return -1;
}

static int write_quantum(FILE *out, int q[4])
{
	unsigned char buf[3];

	if (q[0] < 0 || q[1] < 0)
		return -1;

	buf[0] = (unsigned char)((q[0] << 2) | (q[1] >> 4));
	if (fwrite(buf, 1, 1, out) != 1)
		return -1;

	if (q[2] == -2)
		return 0;
	if (q[2] < 0)
		return -1;

	buf[1] = (unsigned char)(((q[1] & 0x0f) << 4) | (q[2] >> 2));
	if (fwrite(buf + 1, 1, 1, out) != 1)
		return -1;

	if (q[3] == -2)
		return 0;
	if (q[3] < 0)
		return -1;

	buf[2] = (unsigned char)(((q[2] & 0x03) << 6) | q[3]);
	if (fwrite(buf + 2, 1, 1, out) != 1)
		return -1;

	return 0;
}

int main(int argc, char **argv)
{
	FILE *in = stdin;
	FILE *out = stdout;
	int quantum[4];
	int idx = 0;
	int ch;

	if (argc > 3) {
		fprintf(stderr, "usage: %s [input] [output]\n", argv[0]);
		return 1;
	}

	if (argc >= 2) {
		in = fopen(argv[1], "rb");
		if (in == NULL) {
			fprintf(stderr, "open %s failed: %s\n", argv[1], strerror(errno));
			return 1;
		}
	}

	if (argc == 3) {
		out = fopen(argv[2], "wb");
		if (out == NULL) {
			fprintf(stderr, "open %s failed: %s\n", argv[2], strerror(errno));
			if (in != stdin)
				fclose(in);
			return 1;
		}
	}

	while ((ch = fgetc(in)) != EOF) {
		signed char v = decode_char(ch);

		if (v == -3)
			continue;
		if (v == -1) {
			fprintf(stderr, "invalid base64 byte: 0x%02x\n", ch & 0xff);
			goto fail;
		}

		quantum[idx++] = v;
		if (idx == 4) {
			if (write_quantum(out, quantum) != 0) {
				fprintf(stderr, "decode/write failure\n");
				goto fail;
			}
			if (quantum[2] == -2 || quantum[3] == -2)
				break;
			idx = 0;
		}
	}

	if (idx != 0) {
		fprintf(stderr, "truncated base64 input\n");
		goto fail;
	}

	if (out != stdout)
		fclose(out);
	if (in != stdin)
		fclose(in);
	return 0;

fail:
	if (out != stdout)
		fclose(out);
	if (in != stdin)
		fclose(in);
	return 1;
}
