ifeq ($(and $(wildcard xvargs.S),$(wildcard tiny-pf.S)),)
  $(error install dependencies or run the docker image)
else
endif


CC = gcc
CFLAGS = -c
XVARGS_FLAGS =
TINY_PF_FLAGS =
LDFLAGS = -nostartfiles
EXECUTABLE = bfi
OBJS = bfi.o tiny-pf.o xvargs.o lexer.o exec.o info.o
DEBUG = -g

.PHONY: all clean

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJS)
	$(CC) $^ -o $@ $(LDFLAGS)

info.o: info.S
	$(CC) $(CFLAGS) $< -o $@ $(DEBUG)

exec.o: exec.S
	$(CC) $(CFLAGS) $< -o $@ $(DEBUG)

lexer.o: lexer.S
	$(CC) $(CFLAGS) $< -o $@ $(DEBUG)

bfi.o: bfi.S
	$(CC) $(CFLAGS) $< -o $@ $(DEBUG)

xvargs.o: xvargs.S
	$(CC) $(CFLAGS) $(XVARGS_FLAGS) $< -o $@

tiny-pf.o: tiny-pf.S
	$(CC) $(CFLAGS) $(TINY_PF_FLAGS) $< -o $@

clean:
	rm -rf $(OBJS) $(EXECUTABLE)
