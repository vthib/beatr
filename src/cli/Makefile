SRC=$(wildcard *.d)
OBJ=$(SRC:.d=.o)
TARGET=main

DIRBEATR=../beatr
#LIBBEATR=$(DIRBEATR)/libbeatr.so

DIR3RDLIB=../beatr/3rdptylib

DC=dmd
DFLAGS=-unittest -debug -gc
IFLAGS=-I.. -I$(DIRBEATR) -I$(DIR3RDLIB)
LDFLAGS=-L-L$(DIR3RDLIB) -L-ldfftw3 -L-lavutil -L-lavcodec -L-lavformat -L-lfftw3 #-L-lbeatr -L-L$(DIRBEATR)

.PHONY=clean mrproper
all:$(TARGET)

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(TARGET): $(OBJ) $(LIBBEATR)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -defaultlib=libphobos2.so -L-rpath=$(shell pwd)/$(DIR3RDLIB) $(OBJ)

$(LIBBEATR):
	cd $(DIRBEATR); $(MAKE)

clean:
	rm -rf $(TARGET) $(OBJ)

mrproper: clean
	cd $(DIRBEATR); $(MAKE) clean
