TARGET=libbeatr.so
DIRS=util chroma exc file analysis
SRC=$(shell find $(DIRS) -type f -name '*.d' -print)
OBJ=$(SRC:.d=.o)

3RDDIR=../3rdptylib
3RDLIBS=$(3RDDIR)/libdavcodec.so $(3RDDIR)/libdavformat.so $(3RDDIR)/libdavutil.so $(3RDDIR)/libdfftw3.so

DC=dmd
DFLAGS=-unittest -debug -gc -fPIC -version=full_decomp
IFLAGS=-I$(shell pwd) -I$(shell pwd)/../3rdptylib
LDFLAGS=-L-L$(3RDDIR) -L-ldavcodec -L-ldavformat -L-ldfftw3

.PHONY=clean
all:$(TARGET)

$(TARGET): $(OBJ) $(3RDLIBS)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -shared -defaultlib=libphobos2.so -L-rpath=$(shell pwd)/../3rdptylib -L-L/usr/local/lib $(OBJ)

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(3RDLIBS):
	cd $(3RDDIR) && $(MAKE)

clean:
	rm -rf $(OBJ) $(TARGET)
