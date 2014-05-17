TARGET=libbeatr.so
DIRS=exc file
SRC=$(shell find $(DIRS) -type f -name '*.d' -print)
OBJ=$(SRC:.d=.o)

DC=dmd
DFLAGS=-unittest -debug -gc -fPIC
IFLAGS=-I. -I../3rdptylib
LDFLAGS=-L-L../3rdptylib -L-ldavcodec -L-ldavformat -L-ldfftw3

.PHONY=clean
all:$(TARGET)

$(TARGET): $(OBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -shared -defaultlib=libphobos2.so -L-rpath=$(shell pwd)/../3rdptylib -L-L/usr/local/lib $^ 

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

clean:
	rm -rf $(OBJ) $(TARGET)
