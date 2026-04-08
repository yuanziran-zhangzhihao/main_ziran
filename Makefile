ifneq ($(KERNELRELEASE),)
obj-m := babydriver.o
else
KDIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)
CC ?= gcc
CFLAGS += -O2 -Wall

.PHONY: all module exp exp-static clean

all: module exp

module:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

exp: exp.c
	$(CC) $(CFLAGS) -o exp exp.c

exp-static: exp.c
	$(CC) $(CFLAGS) -static -o exp.static exp.c

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	$(RM) exp exp.static
endif
