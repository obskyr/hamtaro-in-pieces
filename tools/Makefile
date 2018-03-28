.PHONY: all clean

TOOLS = asmdependencies decompress decodegraphics

all: $(TOOLS)

clean:
	find ./ -maxdepth 1 -type f -not -path ./Makefile -not -path ./shard.yml -not -path ./shard.lock -delete

LIB_FILES := $(shell find lib/ -type f -name "*.cr" 2> /dev/null)

$(TOOLS): %: source/%.cr lib $(LIB_FILES)
	crystal build -o $@ $<

lib: shard.yml shard.lock
	crystal deps install
	@touch lib
