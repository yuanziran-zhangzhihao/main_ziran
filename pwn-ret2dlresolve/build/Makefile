CC ?= gcc
CHALLENGE_CFLAGS ?= -O0 -g -fno-stack-protector -no-pie -fcf-protection=none
LAUNCHER_CFLAGS ?= -O2 -static -s
RUNTIME_DIR := runtime
CHALLENGE_BIN := $(RUNTIME_DIR)/home/ctf/pwn
LAUNCHER_BIN := $(RUNTIME_DIR)/app/launcher

.PHONY: all runtime clean clean-runtime

all: runtime

runtime: clean-runtime $(CHALLENGE_BIN) $(LAUNCHER_BIN)
	@set -eu; \
	copy_with_deps() { \
		src="$$1"; \
		dest="$(RUNTIME_DIR)$$src"; \
		mkdir -p "$$(dirname "$$dest")"; \
		cp -L "$$src" "$$dest"; \
		ldd "$$src" | awk '{for (i=1;i<=NF;i++) if (index($$i, "/") == 1) print $$i}' | sort -u | \
		while read -r dep; do \
			[ -e "$$dep" ] || continue; \
			dep_dest="$(RUNTIME_DIR)$$dep"; \
			mkdir -p "$$(dirname "$$dep_dest")"; \
			cp -L "$$dep" "$$dep_dest"; \
		done; \
	}; \
	copy_with_deps /bin/sh; \
	copy_with_deps /bin/cat

$(CHALLENGE_BIN): src/challenge.c
	@mkdir -p $(dir $(CHALLENGE_BIN))
	$(CC) $(CHALLENGE_CFLAGS) -o $@ $<

$(LAUNCHER_BIN): src/launcher.c
	@mkdir -p $(dir $(LAUNCHER_BIN))
	$(CC) $(LAUNCHER_CFLAGS) -o $@ $<

clean:
	rm -rf $(RUNTIME_DIR)

clean-runtime:
	rm -rf $(RUNTIME_DIR)
