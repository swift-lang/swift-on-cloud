#obj = c-ray-mt.o
bin = c-ray

CC = gcc
CFLAGS = -O3 -ffast-math

$(bin): $(obj)
	$(CC) -o $@ $(bin).c -lm -lpthread

#$(bin): $(obj)
#	$(CC) -o $@ $(obj) -lm -lpthread

.PHONY: clean
clean:
	rm -f $(obj) $(bin)

.PHONY: install
install:
	cp $(bin) ../../bin/$(bin)

.PHONY: uninstall
uninstall:
	rm -f ../../bin/$(bin)
