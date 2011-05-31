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
headers  := $(wildcard include/*.h include/#{libName}/*.h)
lib      := obj/i686/lib#{libName}.a
lib64    := obj/x86_64/lib#{libName}.a

main_header := include/#{libName}.h
install_header := $(wildcard include/#{libName}/*.h)

ARCH	:= $(shell uname -m)

CFLAGS= -Iinclude/ $(cflags) -Wall -Wextra -Werror -g -I/usr/include/libxml2 -Werror -O3 -fPIC
ifeq ($(ARCH), x86_64)
	libs := $(lib) $(lib64) 
	install-libs := install-lib install-lib64
else
	libs := $(lib) 
	install-libs := install-lib
endif


all: ruby/lib#{libName}_ruby.so 

$(lib): $(srcs) $(headers)
	+make -f Makefile

$(lib64):  $(srcs) $(headers)
	+make -f Makefile

ruby/lib#{libName}_ruby.so: ruby/ruby_#{libName}.c $(libs) 
	+cd ruby; ruby extconf.rb; make $(MFLAGS)

install: ruby/libscp2dir_ruby.so
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/include/sigmaC/IRS/
	install ruby/libscp2dir_ruby.so $(SIGMAC_TOOLCHAIN_DIR)/share/sigmaC/IRS/

clean:
	if [ -f ruby/Makefile ]; then cd ruby; make $(MFLAGS) clean; fi

"
      end
      module_function :genMakefile
    end
  end
end
