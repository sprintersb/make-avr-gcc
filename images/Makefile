RM = rm -rf --

.PHONY: all clean all-images clean-images
.PHONY: dot png svg clean-dot clean-svg clean-png

all: dot png svg

all-images: all
clean-images: clean

dot: make.dot make-host.dot make-canadian.dot
png: make.png make-host.png make-canadian.png
svg: make.svg make-host.svg make-canadian.svg

%.png: %.dot
	dot $< -Tpng > $@

%.svg: %.dot
	dot $< -Tsvg > $@

CPP = gcc -undef -C -P -E
CPP = m4

make.dot: make.h cluster-host.h cluster-canadian.h
	$(CPP) $< > $@

make-host.dot: make-host.h cluster-host.h
	$(CPP) $< > $@

make-canadian.dot: make-canadian.h cluster-canadian.h
	$(CPP) $< > $@

clean-dot:
	$(RM) $(wildcard make.dot make-host.dot make-canadian.dot)

clean-svg:
	$(RM) $(wildcard *.svg)

clean-png:
	$(RM) $(wildcard *.png)

clean: clean-dot clean-svg clean-png
