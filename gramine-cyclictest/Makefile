# Copyright (C) 2023 Gramine contributors
# SPDX-License-Identifier: BSD-3-Clause

CFLAGS = -Wall -Wextra
LDFLAGS = -lrt -lpthread


ifeq ($(DEBUG),1)
GRAMINE_LOG_LEVEL = debug
CFLAGS += -g
else
GRAMINE_LOG_LEVEL = error
CFLAGS += -O3
endif

.PHONY: all
all: cyclictest cyclictest.manifest
ifeq ($(SGX),1)
all: cyclictest.manifest.sgx cyclictest.sig
endif

cyclictest: cyclictest.o rt-utils.o error.o


rt-utils.o: rt-utils.c
	$(CC) -c $(CFLAGS) $< -o $@

error.o: error.c
	$(CC) -c $(CFLAGS) $< -o $@

cyclictest.o: cyclictest.c

cyclictest.manifest: cyclictest.manifest.template cyclictest
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		$< $@
	gramine-manifest-check $@

cyclictest.sig cyclictest.manifest.sgx &: cyclictest.manifest
	gramine-sgx-sign \
		--manifest $< \
		--output $<.sgx
	gramine-manifest-check $<.sgx

ifeq ($(SGX),)
GRAMINE = gramine-direct
else
GRAMINE = gramine-sgx
endif


.PHONY: clean
clean:
	$(RM) *.sig *.manifest.sgx *.manifest *.o cyclictest OUTPUT 

.PHONY: distclean
distclean: clean
