.PHONY: all clean

BASE_ROM = base.gbc
OUTPUT_ROMS = Hamtaro\ -\ Ham-Hams\ Unite!\ (U).gbc

ASM_FILES := $(shell find source/ -type f -name "*.asm")
OBJECTS = $(ASM_FILES:source/%.asm=build/%.o)

all: $(OUTPUT_ROMS) compare

clean:
	rm -rf build/*

$(OUTPUT_ROMS): $(OBJECTS)
	rgblink -n "$(@:.gbc=.sym)" -O "$(BASE_ROM)" -o "$@" $^
	rgbfix -v -t HAMUTARO2 -i B86E -C -k 01 -m 0x1B -r 0x02 -j "$@"

compare: $(OUTPUT_ROMS)
	cmp "$(BASE_ROM)" "$<"

# rgbasm -h doesn't put in automatic nops after halts.
$(OBJECTS): build/%.o: source/%.asm
	@mkdir -p $(@D)
	rgbasm -i source/ -h -E -o $@ $<

build/%.2bpp: source/%.png source/%.args
	@mkdir -p $(@D)
	tools/dazzlie encode --format gb_2bpp $(shell cat source/$*.args) -i $< -o $@

DEPENDENCY_SCAN_EXIT_STATUS := $(shell tools/asmdependencies -s source/ -b build/ $(ASM_FILES:source/%=%) > build/dependencies.d; echo $$?)
ifneq ($(DEPENDENCY_SCAN_EXIT_STATUS), 0)
$(error Dependency scan failed)
endif
include build/dependencies.d
