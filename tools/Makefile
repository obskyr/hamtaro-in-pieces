.PHONY: all clean libs

TOOLS = asmdependencies decompress decodegraphics
LIBS = lib/stumpy_png lib/stumpy_core

all: $(TOOLS)

clean:
	find ./ -maxdepth 1 -type f -not -path ./Makefile -not -path ./shard.yml -not -path ./shard.lock -delete

LIB_FILES := $(foreach dir,$(LIBS),$(shell find $(dir) -type f 2> /dev/null))

$(TOOLS): %: source/%.cr $(LIBS) $(LIB_FILES)
	crystal build -o $@ $<

libs:
	crystal deps install

ifneq ($(shell crystal deps check > /dev/null 2> /dev/null; echo $$?), 0)
$(LIBS): libs
endif
