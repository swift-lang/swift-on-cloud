bin = md
src = md.c

CC = gcc
#CFLAGS = -O3 -ffast-math

$(bin): $(src)
	$(CC) -o $@ $(bin).c -lm

.PHONY: clean
clean:
	rm -f $(obj) $(bin)

.PHONY: install
install:
	cp $(bin) ../../bin/$(bin)

.PHONY: uninstall
uninstall:
	rm -f ../../bin/$(bin)
