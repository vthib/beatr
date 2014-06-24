SRC=unittesting.d test_mfiles.d
OBJ=$(SRC:.d=.o)
TARGET=$(OBJ:.o=)

BEATRPATH=..
BEATRDIR=$(BEATRPATH)/util $(BEATRPATH)/exc $(BEATRPATH)/file $(BEATRPATH)/analysis $(BEATRPATH)/chroma
BEATRSRC=$(shell find $(BEATRDIR) -name '*.d')
BSRC=$(shell for i in $(BEATRSRC); do echo src/`basename $$i`; done)
BOBJ=$(BSRC:src/%.d=%.o)

3RDDIR=$(shell pwd)/../../3rdptylib
3RDLIBS=$(3RDDIR)/libdavcodec.so $(3RDDIR)/libdavformat.so $(3RDDIR)/libdavutil.so $(3RDDIR)/libdfftw3.so

DC=dmd
DFLAGS?=-unittest -cov
IFLAGS=-I$(shell pwd)/$(BEATRPATH) -I$(3RDDIR)
LDFLAGS=-L-L$(3RDDIR) -L-ldavcodec -L-ldavformat -L-ldfftw3 -L-ldavresample -L-ldavutil -L-lavutil -L-lavcodec -L-lavformat -L-lfftw3 -L-lavresample

.PHONY=clean test copy
all: $(TARGET)

copy:
	cp -u $(BEATRSRC) src

$(BOBJ): %.o : copy
	dmd $(DFLAGS) $(IFLAGS) -of$@ -c src/$*.d

$(OBJ): %.o : %.d
	$(DC) $(DFLAGS) $(IFLAGS) -of$@ -c $<

$(TARGET): % : %.o $(BOBJ)
	$(DC) $(DFLAGS) $(LDFLAGS) -defaultlib=libphobos2.so -L-rpath=$(3RDDIR) -of$@ $^

clean:
	rm -rf $(OBJ) $(TARGET) $(BOBJ) src *.lst
	mkdir src

test: $(TARGET)
	./unittesting
	./test_mfiles

unittest: unittesting
	./unittesting

coverage: test_mfiles
	./test_mfiles
