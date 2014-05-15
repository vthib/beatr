TARGET=../libdfftw3.so
SRC=$(wildcard *.d)
OBJ=$(SRC:.d=.o)

DC=dmd
DFLAGS=-gc -fPIC
IFLAGS=
LDFLAGS=-L-lfftw3 -L-lfftw3f -L-lfftw3l -L-lfftw3 -L-lfftw3_omp -L-lfftw3f_omp -L-lfftw3l_omp

.PHONY=clean test

all:$(TARGET)

$(TARGET): $(OBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -shared -defaultlib=libphobos2.so -L-L/usr/local/lib/ $^ 

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

clean:
	rm -rf $(OBJ) $(TARGET)
	cd tests && $(MAKE) clean

test:
	cd tests && $(MAKE) test
