PROLOG    = swipl -O
PROLOG_LD = swipl-ld
CC        = gcc
CFLAGS    = -cc $(CC) -Wall -Wextra -ansi -pedantic -O4

all: trim compile test

trim:
	@# Remove trailing whitespace and such. Not vital.
	@- trim *.md *.pl src/*.pl src/bson/*.pl src/mongo/*.pl ext/*.c

test: compile
	@ echo "--- Running test suite and exiting ..."
	$(PROLOG) -g "[load], test, halt"

stay: compile
	@ echo "--- Running test suite and staying open ..."
	$(PROLOG) -g "[load], test"

compile: lib/bson_bits

lib/bson_bits: Makefile ext/bson_bits.c
	@ mkdir -p lib
	@ echo "--- Compiling foreign library 'bson_bits' ..."
	$(PROLOG_LD) -shared -o $@.dylib ext/bson_bits.c $(CFLAGS)
	@ mv $@.dylib $@

clean:
	rm -rf lib/*
