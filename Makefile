CFLAGS=-O2 -Isrc -DNDEBUG -Wno-implicit-function-declaration $(OPTFLAGS)
LDFLAGS=$(OPTLIBS)
PREFIX?=/usr/local

HEADERS:=$(wildcard src/**/*.h)
HEADERS+=$(wildcard tests/minunit.h)

SOURCES=$(wildcard src/**/*.c src/*.c)
OBJECTS=$(patsubst %.c,%.o,$(SOURCES))

TEST_SRC=$(wildcard tests/*_tests.c)
TESTS=$(patsubst %.c,%,$(TEST_SRC))

TARGET=build/liblcthw.a

OS=$(shell lsb_release -si)
ifeq ($(OS),Ubuntu)
	LDLIBS=-llcthw -lbsd -L./build -lm
endif

# The Target Build
all: $(TARGET) tests

dev: CFLAGS=-g -O2 -Isrc -rdynamic -Wno-implicit-function-declaration $(OPTFLAGS)
dev: all

$(TARGET): CFLAGS += -fPIC
$(TARGET): build $(OBJECTS)
	ar rcs $@ $(OBJECTS)
	ranlib $@

build:
	@mkdir -p build
	@mkdir -p bin

# The Unit Tests
.PHONY: tests
tests: LDLIBS += $(TARGET)
tests: $(TESTS)
	sh ./tests/runtests.sh

valgrind:
	VALGRIND="valgrind --log-file=/tmp/valgrind-%p.log" $(MAKE)

# The Cleaner
clean:
	rm -rf build $(OBJECTS) $(TESTS)
	rm -f tests/tests.log 
	find . -name "*.gc*" -exec rm {} \;
	rm -rf `find . -name "*.dSYM" -print`

# The Install
install: all
	sudo install -d $(DESTDIR)/$(PREFIX)/lib/
	sudo install $(TARGET) $(DESTDIR)/$(PREFIX)/lib/
	sudo install -d $(DESTDIR)/$(PREFIX)/include/lcthw/
	sudo install -m 644 $(HEADERS) /$(PREFIX)/include/lcthw/

# The Checker
check:
	@echo Files with potentially dangerous functions.
	@egrep '[^_.>a-zA-Z0-9](str(n?cpy|n?cat|xfrm|n?dup|str|pbrk|tok|_)|stpn?cpy|a?sn?printf|byte_)' $(SOURCES) || true

