.PHONY: all clean

TOOLS = asmdependencies decompress

all: $(TOOLS)

clean:
	find ./ -maxdepth 1 -type f -not -path ./Makefile -delete

$(TOOLS): %: source/%.cr
	crystal build -o $@ $<