SRC=$(wildcard *.d)
SRCLIB=$(wildcard ../*.d)
OBJ=$(SRC:.d=.o)
OBJLIB=$(SRCLIB:../%.d=%.o)
TARGETS=$(SRC:.d=)

FFTWLIB=../libdfftw3.so

DC=dmd
DFLAGS=-gc -fPIC -unittest -version=fftwunittests
IFLAGS=-I..
LDFLAGS=-L-lfftw3 -L-lfftw3f -L-lfftw3l -L-lfftw3 -L-lfftw3_omp -L-lfftw3f_omp -L-lfftw3l_omp

.PHONY=clean test $(RUNTARGETS)

all:$(TARGETS)

$(TARGETS): $(OBJ) $(OBJLIB) $(FFTWLIB)
	$(DC) $(DFLAGS) $(LDFLAGS) -of$@ $(OBJ) $(OBJLIB)

$(OBJ): $(SRC)
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(OBJLIB): $(SRCLIB)
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(FFTWLIB):
	cd .. && $(MAKE)

clean:
	rm -rf $(OBJ) $(OBJLIB) $(TARGETS)

test: $(TARGETS)
	./$^
