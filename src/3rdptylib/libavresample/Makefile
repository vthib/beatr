TARGET=../libdavresample.a
SRC=$(wildcard *.d)
OBJ=$(SRC:.d=.o)

DC=dmd
DFLAGS?=-O -inline -release -noboundscheck -fPIC
IFLAGS=-I..
#LDFLAGS=-L-lavresample

.PHONY=clean test

all:$(TARGET)

$(TARGET): $(OBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -lib $^

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

clean:
	rm -rf $(OBJ) $(TARGET)

test:
