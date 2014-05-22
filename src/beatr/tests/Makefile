SRC=$(shell find $(DIRS) -type f -name '*.d' -print)
OBJ=$(SRC:.d=.o)
TARGETS=$(SRC:.d=)

BEATRDIR=..
BEATRLIB=$(BEATRDIR)/libbeatr.so

DC=dmd
DFLAGS=-unittest -gc
IFLAGS=-I$(BEATRDIR) -I../../3rdptylib
LDFLAGS=-L-L$(BEATRDIR) -L-lbeatr

.PHONY=clean test
all:$(TARGETS)

$(TARGETS): % : %.o $(BEATRLIB)
	$(DC) $(DFLAGS) $(LDFLAGS) -defaultlib=libphobos2.so -of$@ -L-rpath=$(shell pwd)/$(BEATRDIR) $<

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(BEATRLIB):
	cd $(BEATRDIR) && $(MAKE)

clean:
	rm -rf $(OBJ) $(TARGETS)

test: $(TARGETS)
	$(shell for i in $(TARGETS); do echo $$i; done)
