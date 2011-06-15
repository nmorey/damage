# Copyright (C) 2011  Nicolas Morey-Chaisemartin <nicolas@morey-chaisemartin.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Damage
  module C
    module Makefile


      def write(description)
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/", "Makefile")
        genMakefile(output, description)
        output.close()
      end
      module_function :write

      private
      def genMakefile(output, description)
        libName = description.config.libname
        output.puts "
LIBDIR32  := $(shell if [ -f /etc/debian_version -a -d /usr/lib32/ ]; then echo \"lib32\"; else echo \"lib\"; fi)
LIBDIR64  := $(shell if [ -f /etc/debian_version -a -d /usr/lib32/ ]; then echo \"lib\"; else echo \"lib64\"; fi)

srcs     := $(wildcard src/*.c)
headers  := $(wildcard include/*.h include/#{libName}/*.h)
objs     := $(patsubst src/%.c,obj/i686/%.o,$(srcs))
objs64   := $(patsubst src/%.c,obj/x86_64/%.o,$(srcs))
tests_src:= $(wildcard test/*.c)
tests    := $(patsubst test/%.c,obj/tests/%,$(tests_src))
lib      := obj/i686/lib#{libName}.a
lib64    := obj/x86_64/lib#{libName}.a
dlib      := obj/i686/lib#{libName}.so
dlib64    := obj/x86_64/lib#{libName}.so

main_header := include/#{libName}.h
install_headers := $(wildcard include/#{libName}/*.h)

ARCH	:= $(shell uname -m)

CC=gcc
CFLAGS  := -Iinclude/ $(cflags) -Wall -Wextra -Werror -g -I/usr/include/libxml2 -Werror -O3 -fPIC

ifeq ($(ARCH), x86_64)
	libs := $(lib) $(lib64) $(dlib) $(dlib64)
	install-libs := install-lib install-lib64
else
	libs := $(lib) $(dlib)
	install-libs := install-lib
endif


all: $(libs) # wrapper/lib#{libName}_ruby.so test1

tests: $(tests)

obj/tests/%: test/%.c $(libs)
	@if [ ! -d obj/tests/ ]; then mkdir -p obj/tests/; fi
	$(CC) -o $@ $< $(CFLAGS) -Lobj/x86_64 -Lobj/i686 -l#{libName} -lxml2

$(lib): $(objs)
	rm -f $@
	ar rc $@ $(objs)
	ranlib $@

$(lib64): $(objs64)
	rm -f $@
	ar rc $@ $(objs64)
	ranlib $@

$(dlib): $(objs)
	$(CC) -m32 -shared -o $@ $(objs) -lxml2 -lz -lm

$(dlib64): $(objs64)
	$(CC) -shared -o $@ $(objs64) -lxml2 -lz -lm 

#wrapper/lib#{libName}_ruby.so: wrapper/ruby_scp2dir.c $(libs) 
#	+cd wrapper; ruby extconf.rb; make $(MFLAGS)

obj/i686/%.o:src/%.c $(headers)
	@if [ ! -d obj/i686/ ]; then mkdir -p obj/i686/; fi
	$(CC) $(CFLAGS) -m32 -o $@ -c $<

obj/x86_64/%.o:src/%.c $(headers)
	@if [ ! -d obj/x86_64/ ]; then mkdir -p obj/x86_64/; fi
	$(CC) $(CFLAGS) -o $@ -c $<

install: $(install-libs) # ruby/sigmaC.xsd ruby/scp2dir.rb wrapper/libscp2dir_ruby.so
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/include/sigmaC/IRS/#{libName}/
	install $(main_header) $(SIGMAC_TOOLCHAIN_DIR)/include/sigmaC/IRS/
	install $(install_headers) $(SIGMAC_TOOLCHAIN_DIR)/include/sigmaC/IRS/#{libName}/
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/share/sigmaC/IRS/
#	install wrapper/libscp2dir_ruby.so ruby/sigmaC.xsd ruby/scp2dir.rb $(SIGMAC_TOOLCHAIN_DIR)/share/sigmaC/IRS/

install-lib: $(lib) $(dlib)
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR32)/sigmaC/IRS/
	install $(lib) $(dlib) $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR32)/sigmaC/IRS/

install-lib64: $(lib64) $(dlib64)
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR64)/sigmaC/IRS/
	install $(lib64) $(dlib64) $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR64)/sigmaC/IRS/

clean:
	rm -Rf .commit/
	rm -Rf obj/
	rm -Rf $(awksrcs) $(awkheaders)
	if [ -f Makefile.ruby ]; then make $(MFLAGS) -f Makefile.ruby clean; fi

"
      end
      module_function :genMakefile
    end
  end
end
