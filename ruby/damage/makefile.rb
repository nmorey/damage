module Damage
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

rubydeps := $(shell [ -d lib ] && find lib -name \"*.rb\")
srcs     := $(wildcard src/*.c)
headers  := $(wildcard include/*.h include/#{libName}/*.h)
objs     := $(patsubst src/%.c,obj/i686/%.o,$(srcs))
objs64   := $(patsubst src/%.c,obj/x86_64/%.o,$(srcs))
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


all: $(libs) # wrapper/lib#{libName}_ruby.so test1

tests: obj/test1

obj/test1: test/create_dump_and_reload.c $(libs)
	gcc -o $@ $< $(CFLAGS) -Lobj/x86_64 -Lobj/i686 -l#{libName} -lxml2

$(lib): $(objs)
	rm -f $@
	ar rc $@ $(objs)
	ranlib $@

$(lib64): $(objs64)
	rm -f $@
	ar rc $@ $(objs64)
	ranlib $@

#wrapper/lib#{libName}_ruby.so: wrapper/ruby_scp2dir.c $(rubydeps) $(libs) 
#	+cd wrapper; ruby extconf.rb; make $(MFLAGS)

obj/i686/%.o:src/%.c $(headers)
	@if [ ! -d obj/i686/ ]; then mkdir -p obj/i686/; fi
	gcc $(CFLAGS) -m32 -o $@ -c $<

obj/x86_64/%.o:src/%.c $(headers)
	@if [ ! -d obj/x86_64/ ]; then mkdir -p obj/x86_64/; fi
	gcc $(CFLAGS) -o $@ -c $<

install: $(install-libs) # ruby/sigmaC.xsd ruby/scp2dir.rb wrapper/libscp2dir_ruby.so
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/include/sigmaC/IRS/#{libName}/
	install $(main_header) $(SIGMAC_TOOLCHAIN_DIR)/include/sigmaC/IRS/
	install $(install_headers) $(SIGMAC_TOOLCHAIN_DIR)/include/sigmaC/IRS/#{libName}/
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/share/sigmaC/IRS/
#	install wrapper/libscp2dir_ruby.so ruby/sigmaC.xsd ruby/scp2dir.rb $(SIGMAC_TOOLCHAIN_DIR)/share/sigmaC/IRS/

install-lib: $(lib)
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR32)/sigmaC/IRS/
	install $(lib) $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR32)/sigmaC/IRS/

install-lib64: $(lib64)
	mkdir -p $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR64)/sigmaC/IRS/
	install $(lib64) $(SIGMAC_TOOLCHAIN_DIR)/$(LIBDIR64)/sigmaC/IRS/

clean:
	rm -Rf .commit/
	rm -Rf obj/
	rm -f Doxyfile
	rm -Rf doc
	rm -Rf $(awksrcs) $(awkheaders) ruby/*
	if [ -f wrapper/Makefile ]; then cd wrapper; make $(MFLAGS) clean; fi

"
    end
    module_function :genMakefile
  end
end
