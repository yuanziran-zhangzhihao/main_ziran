CC ?= gcc
CFLAGS += -O0 -g -Wall -Wextra -fno-stack-protector -no-pie
STATIC ?= 0

ifeq ($(STATIC),1)
CFLAGS += -static
endif

all: routerd

routerd: routerd.c
	$(CC) $(CFLAGS) -o routerd routerd.c

clean:
	rm -f routerd
