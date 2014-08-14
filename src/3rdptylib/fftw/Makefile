TARGET=../libdfftw3.a
SRC=$(wildcard *.d)
OBJ=$(SRC:.d=.o)

DC=dmd
DFLAGS?=-O -inline -release -noboundscheck -fPIC
IFLAGS=
#LDFLAGS=-L-lfftw3 -L-lfftw3f -L-lfftw3l -L-lfftw3 -L-lfftw3_omp -L-lfftw3f_omp -L-lfftw3l_omp

.PHONY=clean test

all:$(TARGET)

$(TARGET): $(OBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -lib $^ 

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

clean:
	rm -rf $(OBJ) $(TARGET)
	cd tests && $(MAKE) clean

test:
	cd tests && $(MAKE) test
