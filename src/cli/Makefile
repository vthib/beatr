SRC=$(wildcard *.d)
OBJ=$(SRC:.d=.o)
TARGET=beatr

DIRBEATR=../beatr
LIBBEATR=$(DIRBEATR)/libbeatr.so

DIR3RDLIB=../3rdptylib

DC=dmd
#DFLAGS=-unittest -debug -gc #-profile
DFLAGS?=-O -inline -release -noboundscheck
IFLAGS=-I.. -I$(DIRBEATR) -I$(DIR3RDLIB)
LDFLAGS=-L-L$(DIR3RDLIB) -L-lbeatr -L-L$(DIRBEATR)

.PHONY=clean mrproper full
all:$(TARGET)

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(TARGET): $(OBJ) $(LIBBEATR)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -defaultlib=libphobos2.so -L-rpath=$(shell pwd)/$(DIRBEATR) -L-rpath=$(shell pwd)/$(DIR3RDLIB) $(OBJ)

$(LIBBEATR):
	cd $(DIRBEATR); $(MAKE)

clean:
	rm -rf $(TARGET) $(OBJ)

mrproper: clean
	cd $(DIRBEATR); $(MAKE) clean

full:
	cd $(DIRBEATR); $(MAKE)
	$(MAKE)
