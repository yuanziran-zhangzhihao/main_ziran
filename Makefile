CC ?= gcc
CFLAGS += -O0 -g -Wall -Wextra -fno-stack-protector -no-pie

all: routerd

routerd: routerd.c
	$(CC) $(CFLAGS) -o routerd routerd.c

clean:
	rm -f routerd
