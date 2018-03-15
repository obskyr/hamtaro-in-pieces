.PHONY: all clean

BASE_ROM = base.gbc

OUTPUT_ROMS = Hamtaro\ -\ Ham-Hams\ Unite!\ (U).gbc
OBJECTS_WITHOUT_BUILD_DIRECTORY = entry_points.o startup.o compression.o
OBJECTS = $(OBJECTS_WITHOUT_BUILD_DIRECTORY:%.o=build/%.o)

all: $(OUTPUT_ROMS) compare

clean:
	rm -f build/*

$(OUTPUT_ROMS): $(OBJECTS)
	rgblink -n "$(@:.gbc=.sym)" -O "$(BASE_ROM)" -o "$@" $^
	rgbfix -v -t HAMUTARO2 -i B86E -C -k 01 -m 0x1B -r 0x02 -j "$@"

compare: $(OUTPUT_ROMS)
	cmp "$(BASE_ROM)" "$<"

# rgbasm -h doesn't put in automatic nops after halts.
$(OBJECTS): build/%.o: source/%.asm
	rgbasm -i source/ -h -E -o $@ $<

DEPENDENCY_SCAN_EXIT_STATUS := $(shell cd source && ../tools/asmdependencies $(OBJECTS:build/%.o=%.asm) > ../build/dependencies.d; echo $$?)
ifneq ($(DEPENDENCY_SCAN_EXIT_STATUS), 0)
$(error Dependency scan failed)
endif
include build/dependencies.d
