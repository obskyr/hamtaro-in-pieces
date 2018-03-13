.PHONY: all clean
.SECONDEXPANSION: # Required for expanding static patterns into variable names.

BASE_ROM = base.gbc

OUTPUT_ROMS = Hamtaro\ -\ Ham-Hams\ Unite!\ (U).gbc
OBJECTS_WITHOUT_BUILD_DIRECTORY = hamtaro.o wram.o
OBJECTS = $(OBJECTS_WITHOUT_BUILD_DIRECTORY:%.o=build/%.o)

# This approach is adapted from the one the Telefang disassembly project uses!
$(if $(wildcard tools/asmdependencies),,$(error asmdependencies not found. Please run `(cd tools && make)`))
$(foreach obj, $(OBJECTS), \
	$(eval $(obj:build/%.o=%)_autodependencies := $(shell tools/asmdependencies $(obj:build/%.o=%.asm))) \
)

all: $(OUTPUT_ROMS) compare

clean:
	rm -f build/*

$(OUTPUT_ROMS): $(OBJECTS)
	rgblink -n "$(@:.gbc=.sym)" -O "$(BASE_ROM)" -o "$@" $^
	rgbfix -v -t HAMUTARO2 -i B86E -C -k 01 -m 0x1B -r 0x02 -j "$@"

compare: $(OUTPUT_ROMS)
	cmp "$(BASE_ROM)" "$<"

# rgbasm -h doesn't put in automatic nops after halts.
$(OBJECTS): build/%.o: %.asm $$($$*_autodependencies)
	rgbasm -h -E -o $@ $<
