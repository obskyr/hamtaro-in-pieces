# Hamtaro in Pieces: a disassembly of *Hamtaro: Ham-Hams Unite!*

This is an incomplete disassembly of the stellar, delightful, and pulchritudinous Game Boy Color game *[Hamtaro: Ham-Hams Unite!](https://en.wikipedia.org/wiki/Hamtaro_(video_game_series)#Ham-Hams_Unite!)*. Why would I disassemble *Ham-Hams Unite*, you ask? Because I thought I'd get some reverse-engineering and disassembly practice in, and I love this game to bits.

## ROM built

This disassembly builds the North American version of the game, with the MD5 hash `48ce279084e1fc7a9136cc211f4fad5d`.

I'm not from North America, but I do like variable-width fonts (which makes the Japanese version less alluring), and disassembling a language switching system would be a whole lot of pain for very little of interest (which makes for a no on the European version).

## How to build

First of all, since the disassembly isn't complete, you'll have to supply a base ROM. To do this, obtain a ROM of the North American version of *Hamtaro: Ham-Hams Unite!*, name it `base.gbc`, and place it in the top-level directory. To check that you have the right ROM, you can run `md5sum base.gbc` and check that it matches:

```
$ md5sum base.gbc
48ce279084e1fc7a9136cc211f4fad5d  base.gbc
```

The following are required to build the disassembly:

* [Crystal](https://crystal-lang.org/) – for speed and fun (but mostly speed), the disassembly uses tools written in Crystal. Follow [the official installation instructions](https://crystal-lang.org/docs/installation/)!
  
  At the time of writing, Crystal isn't available natively for Windows, so you'll need to use [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10) (available on Windows 10) and follow the Linux instructions.
* [RGBDS](https://github.com/rednex/rgbds) version 0.3.6 or newer – follow the instructions in the readme on the GitHub page to install.

Once preparation is done, use Make to first build the tools, and then build the ROM itself:

```bash
make -C tools
make
```

Presto! The finished ROM is now available as `Hamtaro - Ham-Hams Unite! (U).gbc`, alongside a `.sym` file that lets you see all the labels in the debugger of your emulator of choice.

# That's it!

Questions? Wishes? Problems? Just wanna talk? [Open an issue](https://github.com/obskyr/hamtaro-in-pieces/issues) here on GitHub or write to [@obskyr on Twitter](https://twitter.com/obskyr)!
