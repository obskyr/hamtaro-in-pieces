.PHONY: all clean separate_tools

# Large tools are those that have their own makefiles and directories,
# while small tools are single .cr files in the source directory.
LARGE_TOOLS = dazzlie
SMALL_TOOLS = asmdependencies decompress

TOOLS = $(LARGE_TOOLS) $(SMALL_TOOLS)

all: $(TOOLS)

clean:
	find ./ -maxdepth 1 -type f -not -path ./Makefile -not -path ./shard.yml -not -path ./shard.lock -delete

$(LARGE_TOOLS):
	$(MAKE) --no-print-directory -C source/$@
	mv source/$@/$@ ./

$(SMALL_TOOLS): %: source/%.cr
	crystal build -o $@ $<

lib: shard.yml shard.lock
	crystal deps install
	@touch lib
