TARGET=../libdavresample.so
SRC=$(wildcard *.d)
OBJ=$(SRC:.d=.o)

DC=dmd
DFLAGS=-gc -fPIC
IFLAGS=-I..
LDFLAGS=-L-lavresample

.PHONY=clean test

all:$(TARGET)

$(TARGET): $(OBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -shared -defaultlib=libphobos2.so -L-L/usr/local/lib/ $^ 

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

clean:
	rm -rf $(OBJ) $(TARGET)

test:
