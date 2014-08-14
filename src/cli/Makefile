SRC=$(wildcard *.d)
OBJ=$(SRC:.d=.o)
TARGET=beatr

DIRBEATR=../beatr
LIBBEATR=$(DIRBEATR)/libbeatr.a

DC=dmd
#DFLAGS=-unittest -debug -gc #-profile
DFLAGS?=-O -inline -release -noboundscheck
IFLAGS=-I$(DIRBEATR) -I../3rdptylib
LDFLAGS=-L-lavresample -L-lavutil -L-lavcodec -L-lavformat -L-lfftw3

.PHONY=clean mrproper full
all:$(TARGET)

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(TARGET): $(OBJ) $(LIBBEATR)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ $^

$(LIBBEATR):
	cd $(DIRBEATR); $(MAKE)

clean:
	rm -rf $(TARGET) $(OBJ)

mrproper: clean
	cd $(DIRBEATR); $(MAKE) clean

full:
	cd $(DIRBEATR); $(MAKE)
	$(MAKE)
