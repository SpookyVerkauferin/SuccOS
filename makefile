#  makefile
#
#  Copyright (c) 2017-2020, Joshua Riek
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Build tools
CC           ?= gcc
LD           ?= ld
AR           ?= ar
NASM         ?= nasm
OBJCOPY      ?= objcopy
DD           ?= dd

# Other tools
QEMU         ?= qemu-system-i386

# Output directory
SRCDIR        = ./src
OBJDIR        = ./obj
BINDIR        = ./bin

# Build flags
CFLAGS       +=
LDFLAGS      +=
ARFLAGS      +=
LDFLAGS      += -m elf_i386 -Ttext=0x1000
NASMFLAGS    += -isrc/inc/ -O0 -f elf -g3 -F dwarf
OBJCOPYFLAGS += -O binary

# Disk image file
DISKIMG       = floppy.img

# For Windows compatibility (using an i686-elf cross-compiler)
ifeq ($(OS), Windows_NT)
  CC         := i686-elf-gcc
  LD         := i686-elf-ld
  AR         := i686-elf-ar 
endif


# Set phony targets
.PHONY: all clean clobber kernel install debug run


# Rule to make targets
all: kernel


# Makefile target for the kernel
kernel: $(BINDIR)/kernel.bin

$(BINDIR)/kernel.bin: $(BINDIR)/kernel.elf
	$(OBJCOPY) $^ $(OBJCOPYFLAGS) $@

$(BINDIR)/kernel.elf: $(OBJDIR)/kernel.o | $(BINDIR)
	$(LD) $^ $(LDFLAGS) -o $@

$(OBJDIR)/kernel.o: $(SRCDIR)/kernel.asm | $(OBJDIR)
	$(NASM) $^ $(NASMFLAGS) -o $@

$(OBJDIR):
	@mkdir -p $@

$(BINDIR):
	@mkdir -p $@


# Clean produced files
clean:
	rm -f $(OBJDIR)/* $(BINDIR)/*.bin $(BINDIR)/*.elf

# Clean files from emacs
clobber: clean
	rm -f $(SRCDIR)/*~ $(SRCDIR)\#*\# ./*~


# Fix for error "cp: cannot create regular file"
# mount B: \b

# Write the kernel to a disk image
install: 
	cp $(BINDIR)/1440k.img $(DISKIMG)
	imdisk -a -f $(DISKIMG) -m B:
	cp $(BINDIR)/kernel.bin B:/kernel.bin
	imdisk -D -m B:

#install:
#	cp $(BINDIR)/kernel.bin B:/kernel.bin
#	rawcopy -l -m \\\.\B: $(DISKIMG)

# Run the disk image
run:
	$(QEMU) -serial stdio -rtc base=localtime -fda $(DISKIMG)


# Start a debug session with qemu
debug:
	$(QEMU) -serial stdio -rtc base=localtime -S -s -fda $(DISKIMG)
