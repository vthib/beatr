TARGET=libbeatr.a
DIRS=util chroma exc audio analysis
SRC=$(shell find $(DIRS) -type f -name '*.d' -print)
OBJ=$(SRC:.d=.o)

3RDDIR=../3rdptylib
3RDLIBS=$(3RDDIR)/libdavcodec.a $(3RDDIR)/libdavformat.a $(3RDDIR)/libdavutil.a $(3RDDIR)/libdavresample.a $(3RDDIR)/libdfftw3.a

DC=dmd
#DFLAGS?=-debug -gc -fPIC #-profile
DFLAGS?=-O -inline -release -noboundscheck -fPIC
IFLAGS=-I$(shell pwd) -I$(shell pwd)/../3rdptylib
LDFLAGS=

.PHONY=clean test
all:$(TARGET)

$(TARGET): $(OBJ) $(3RDLIBS)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -lib $^

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(3RDLIBS):
	cd $(3RDDIR) && $(MAKE)

clean:
	rm -rf $(OBJ) $(TARGET)

test:
	cd tests; $(MAKE) test
