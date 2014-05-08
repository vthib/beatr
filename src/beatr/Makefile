TARGET=libbeatr.so
DIRS=${shell find ${ROOT_DIRECTORY} -type d -print}
SRC=$(shell find . -type f -name '*.d' -print)
OBJ=$(SRC:.d=.o)

DC=dmd
DFLAGS=-unittest -debug -gc -fPIC
IFLAGS=
LDFLAGS=-L-lavutil -L-lavcodec -L-lavformat -L-lfftw3

.PHONY=clean
all:$(TARGET)

$(TARGET): $(OBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ -shared -defaultlib=libphobos2.so -L-L/usr/local/lib/ $^ 

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

clean:
	rm -rf $(OBJ) $(TARGET)
