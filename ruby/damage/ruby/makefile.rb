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
  module Ruby
    module Makefile


      def write(description)
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/", "Makefile.ruby")
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
r_srcs     := $(wildcard ruby/*.c)
headers  := $(wildcard include/*.h include/#{libName}/*.h)
lib      := obj/i686/lib#{libName}.a
lib64    := obj/x86_64/lib#{libName}.a

main_header := include/#{libName}.h
install_header := $(wildcard include/#{libName}/*.h)

ARCH	:= $(shell uname -m)

PREFIX  := /usr
SUFFIX  := #{libName}

CFLAGS= -Iinclude/ $(cflags) -Wall -Wextra -Werror -g -I/usr/include/libxml2 -Werror -O3 -fPIC
ifeq ($(ARCH), x86_64)
	libs := $(lib) $(lib64) 
	install-libs := install-lib install-lib64
    LIBDIR:=$(LIBDIR64)
else
	libs := $(lib) 
	install-libs := install-lib
    LIBDIR:=$(LIBDIR32)
endif


all: ruby/lib#{libName}_ruby.so doc/ruby/index.html

$(lib): $(srcs) $(headers)
	+make -f Makefile

$(lib64):  $(srcs) $(headers)
	+make -f Makefile

ruby/lib#{libName}_ruby.so: ruby/ruby_#{libName}.c $(libs) 
	+cd ruby; ruby extconf.rb; make $(MFLAGS)

doc/ruby/index.html: ruby/ruby_#{libName}.c $(r_srcs)
	@mkdir -p obj/ doc/; rm -Rf doc/ruby
	@cat $(r_srcs) > obj/#{libName}.c
	rdoc --quiet -o doc/ruby obj/#{libName}.c

install: ruby/lib#{libName}_ruby.so doc/ruby/index.html
	mkdir -p $(PREFIX)/share/$(SUFFIX)
	install ruby/lib#{libName}_ruby.so $(PREFIX)/share/$(SUFFIX)
	cp -R doc/ruby $(PREFIX)/share/$(SUFFIX)/

clean:
	if [ -f ruby/Makefile ]; then cd ruby; make $(MFLAGS) clean; fi
	[ -d doc ] && rm -Rf doc/ruby

"
      end
      module_function :genMakefile
    end
  end
end
