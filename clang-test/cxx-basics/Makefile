# This Makefile call clang++ to build test C++17 program
# for different PLATFORMS.
# It uses clang++ and llvm as a driver to system-installed
# platform dependend GCC cross-compiler
#
# Originally Broadcom provides the following cross-toolchains
#   Nexus-16.2
#      /opt/toolchains/stbgcc-4.8-1.5
#      ARM only tested
#      build and run(arriswb20) tested
#   Nexus-15.3
#      /opt/toolchains/stbgcc-4.5.4-2.9
#      MIPSEL only tested
#      build and run(tchhydra) tested
#   Nexus-14.2
#      /opt/toolchains/stbgcc-4.2.0
#      MIPSEL only
#      build only tested
#
# stbgcc-4.8-1.5/ARM seems fully supported by clang/llvm.ld
#   - Require extra CFLAGS to add -I option
#   - Require extra LDFLAGS to add -L option
#
# stbgcc-4.5.4-2.9/MIPSEL have 3 isues:
#   - Require extra CFLAGS to add -I option
#   - Require extra LDFLAGS to add -L option
#   - https://bugs.llvm.org/show_bug.cgi?id=13364#c2
#     could be workarounded but in every c++ source file
#   - https://bugs.llvm.org/show_bug.cgi?id=13373
#     requires to modify the G++ internal header
#   - Linker issue seems introduced by Broadcom at toolchain build time
#     Require extra symlink for GCC's internal runtime
#       cd $(SYSROOT)/usr/lib
#       ln -s ../../../../lib/gcc/mipsel-linux-uclibc/4.5.4/crtbegin.o
#       ln -s ../../../../lib/gcc/mipsel-linux-uclibc/4.5.4/crtend.o
#   - Redefine program interpretter for uClibc
#       -Wl,-dynamic-linker -Wl,/lib/ld-uClibc.so.0
#
# stbgcc-4.2.0 is too old for C++11/C++14/C++17.
#   - The maximum version supported is gnu++98
#   - Require extra CFLAGS to add -I option
#   - Require extra LDFLAGS to add -L option
#   - Linker issue seems introduced by Broadcom at toolchain build time
#     Require extra symlink for GCC's internal runtime
#       cd $(SYSROOT)/lib
#       ln -s ../../lib/gcc/mipsel-linux-uclibc/4.2.0/crtbegin.o
#       ln -s ../../lib/gcc/mipsel-linux-uclibc/4.2.0/crtend.o
#   - Still here is a warning like this:
#       ld.lld: warning: /opt/toolchains/stbgcc_ip_zebra-4.2.0/mipsel-linux-uclibc/lib/../lib/crtbegin.o:
#           linking non-abicalls code with abicalls code /opt/toolchains/stbgcc_ip_zebra-4.2.0/mipsel-linux-uclibc/lib/../lib/crt1.o
#       ld.lld: warning: /opt/toolchains/stbgcc_ip_zebra-4.2.0/mipsel-linux-uclibc/lib/../lib/crtend.o:
#           linking non-abicalls code with abicalls code /opt/toolchains/stbgcc_ip_zebra-4.2.0/mipsel-linux-uclibc/lib/../lib/crt1.o
#
CXX	= clang++

PLATFORM	?= arm
EXTRA_DEFS	=
EXTRA_IDIRS	=
EXTRA_LDIRS	=

LDSONAME	=

ifeq ($(PLATFORM),arm)
# WB20
	TARGET		= arm-linux-gnueabihf
	CROSSPATH	= /opt/toolchains/stbgcc-4.8-1.5
	SYSROOT		= $(CROSSPATH)/$(TARGET)/sys-root
	EXTRA_IDIRS	+= -I$(SYSROOT)/usr/include
	EXTRA_LDIRS	+= -L$(SYSROOT)/usr/lib
else ifeq ($(PLATFORM),mips)
# WB11, Hydra
	GCCVER		= 4.5.4
	GCCEXTRAVER	= 2.9
	TARGET		= mipsel-linux-uclibc
	CROSSPATH	= /opt/toolchains/stbgcc-$(GCCVER)-$(GCCEXTRAVER)
	SYSROOT		= $(CROSSPATH)/$(TARGET)/sys-root
	# Override default to point to LDSO from uClibc
	LDSONAME	= -Wl,-dynamic-linker -Wl,/lib/ld-uClibc.so.0
	EXTRA_IDIRS	+= -I$(CROSSPATH)/$(TARGET)/include/c++/$(GCCVER)
	EXTRA_IDIRS	+= -I$(CROSSPATH)/$(TARGET)/include/c++/$(GCCVER)/$(TARGET)
	EXTRA_IDIRS	+= -I$(SYSROOT)/usr/include
	EXTRA_LDIRS	+= -L$(CROSSPATH)/lib/gcc/$(TARGET)/$(GCCVER)
	EXTRA_LDIRS	+= -L$(CROSSPATH)/$(TARGET)/lib
	EXTRA_LDIRS	+= -L$(SYSROOT)/usr/lib
	# Despite of --gcc-toolchain gcc-4.5.4 still needs workaround for linkage
	# cd $(SYSROOT)/usr/lib
	# ln -s ../../../../lib/gcc/mipsel-linux-uclibc/4.5.4/crtbegin.o
	# ln -s ../../../../lib/gcc/mipsel-linux-uclibc/4.5.4/crtend.o
else ifeq ($(PLATFORM),backport)
# C5320
	GCCVER		= 4.2.0
	TARGET		= mipsel-linux-uclibc
	CROSSPATH	= /opt/toolchains/stbgcc_ip_zebra-$(GCCVER)
	SYSROOT		= $(CROSSPATH)/$(TARGET)
	LDSONAME	= -Wl,-dynamic-linker -Wl,/lib/ld-uClibc.so.0
	# GCC-4.2.0 does not support C++17 at all
	EXTRA_DEFS	= -DNO_GNU_17=1
	EXTRA_IDIRS	+= -I$(CROSSPATH)/$(TARGET)/include/c++/$(GCCVER)
	EXTRA_IDIRS	+= -I$(CROSSPATH)/$(TARGET)/include/c++/$(GCCVER)/$(TARGET)
	EXTRA_LDIRS	+= -L$(CROSSPATH)/lib/gcc/$(TARGET)/$(GCCVER)
	# Despite of --gcc-toolchain gcc-4.2.0 still needs workaround for linkage
	# cd $(SYSROOT)/lib
	# ln -s ../../lib/gcc/mipsel-linux-uclibc/4.2.0/crtbegin.o
	# ln -s ../../lib/gcc/mipsel-linux-uclibc/4.2.0/crtend.o
else
	$(error "Unknown platform: $(PLATFORM)")
endif

CLANGFLAGS	 = -v
CLANGFLAGS	+= -target $(TARGET)
CLANGFLAGS	+= --target=$(TARGET)
CLANGFLAGS	+= --gcc-toolchain=$(CROSSPATH)
CLANGFLAGS	+= --sysroot=$(SYSROOT)

CXXFLAGS	= -std=gnu++17
CXXFLAGS	+= $(EXTRA_DEFS)
CXXFLAGS	+= $(EXTRA_IDIRS)

LDFLAGS		= -fuse-ld=lld
LDFLAGS		+= $(LDSONAME)
LDFLAGS		+= $(EXTRA_LDIRS)

SRCS	= $(wildcard *.cpp)
PPXS	= $(SRCS:%.cpp=%.i)
OBJS	= $(SRCS:%.cpp=%.o)

PROG	= clng-tst

all: $(PROG)

$(PROG): $(OBJS)
	$(CXX) $(CLANGFLAGS) $(LDFLAGS) -o $@ $(OBJS)

%.i: %.cpp
	$(CXX) $(CLANGFLAGS) -E -dM -o $@ $< $(CXXFLAGS)

%.o: %.cpp
	$(CXX) $(CLANGFLAGS) -c -o $@ $< $(CXXFLAGS)

$(OBJS): $(PPXS)

clean:
	rm -f $(PROG)
	rm -f $(PPXS)
	rm -f $(OBJS)
