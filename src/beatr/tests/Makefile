SRC=unittesting.d test_mfiles.d
OBJ=$(SRC:.d=.o)
TARGET=$(OBJ:.o=)

BEATRPATH=..
BEATRDIR=$(BEATRPATH)/util $(BEATRPATH)/exc $(BEATRPATH)/audio $(BEATRPATH)/analysis $(BEATRPATH)/chroma
BEATRSRC=$(shell find $(BEATRDIR) -name '*.d')
BSRC=$(shell for i in $(BEATRSRC); do echo src/`basename $$i`; done)
BOBJ=$(BSRC:src/%.d=obj/%.o)

3RDDIR=$(shell pwd)/../../3rdptylib
3RDLIBS=$(3RDDIR)/libdavcodec.so $(3RDDIR)/libdavformat.so $(3RDDIR)/libdavutil.so $(3RDDIR)/libdfftw3.so

DC=dmd
DFLAGS?=-unittest -cov -gc -debug
IFLAGS=-I$(shell pwd)/$(BEATRPATH) -I$(3RDDIR)
LDFLAGS=-L-L$(3RDDIR) -L-ldavcodec -L-ldavformat -L-ldfftw3 -L-ldavresample -L-ldavutil -L-lavutil -L-lavcodec -L-lavformat -L-lfftw3 -L-lavresample

.PHONY=clean test copy compile
all: compile

copy:
	cp -u $(BEATRSRC) src

$(BOBJ): obj/%.o : src/%.d
	dmd $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(TARGET): % : %.o $(BOBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -defaultlib=libphobos2.so -L-rpath=$(3RDDIR) -of$@ $^

compile: copy $(TARGET)

clean:
	rm -rf $(TARGET) $(BOBJ) $(OBJ) src obj *.lst
	mkdir src obj

test: compile
	./unittesting
	./test_mfiles

unittest: compile unittesting
	./unittesting

coverage: compile test_mfiles
	./test_mfiles
