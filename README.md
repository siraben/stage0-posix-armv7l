This folder contains the armv7l specific parts of stage0-posix and was separated out to make integration in other projects in easier.

To use this in your project:
1) add it as a git submodule (or just extract into a folder) named armv7l
2) create a kaem.armv7l file (if you are using bootstrap-seeds)
3) create an after.kaem file to hook your tools you wish to have built after these

The master location of this code is: https://github.com/oriansj/stage0-posix-armv7l

GAS source status:

* `GAS/M0_armv7l.S`, `GAS/cc_armv7l.S`, `GAS/hex1_armv7l.S`, and
  `GAS/hex2_armv7l.S` are ARMv7L sources. Older copies used `_x86` suffixes
  even though the contents were ARM assembly.
* `hex0_armv7l.hex0`, `hex1_armv7l.hex0`, `hex2_armv7l.hex1`,
  `kaem-minimal.hex0`, `M0_armv7l.hex2`, and `cc_armv7l.hex2` are generated
  from the GAS sources with ARMv7L GNU binutils.
