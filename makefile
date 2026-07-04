CC = gcc
CFLAGS = -c
XVARGS_FLAGS =
TINY_PF_FLAGS =
LDFLAGS = -nostartfiles
EXECUTABLE = bfi
OBJS = bfi.o libs/tiny-pf.o libs/xvargs.o lexer.o exec.o info.o
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

libs/xvargs.o: libs/xvargs.S
	$(CC) $(CFLAGS) $(XVARGS_FLAGS) $< -o $@

libs/tiny-pf.o: libs/tiny-pf.S
	$(CC) $(CFLAGS) $(TINY_PF_FLAGS) $< -o $@

clean:
	rm -rf $(OBJS) $(EXECUTABLE)
