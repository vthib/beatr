DIRS=${shell find -mindepth 1 -maxdepth 1 ${ROOT_DIRECTORY} -type d -print}
COMPDIRS=$(DIRS:=.comp)
TESTDIRS=$(DIRS:=.test)
CLEANDIRS=$(DIRS:=.clean)

.PHONY=clean comp test $(COMPDIRS) $(TESTDIRS) $(CLEANDIRS)

all: comp

comp: $(COMPDIRS)
test: $(TESTDIRS)
clean: $(CLEANDIRS)

%.comp: %
	cd $<; $(MAKE)

%.test: %
	cd $<; $(MAKE) test

%.clean: %
	cd $<; $(MAKE) clean
