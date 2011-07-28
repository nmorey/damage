Damage (DAtabase MetA GEnerator) is a ruby script to create simple and fast databases schemes to use as internal storage in any applications.
From a short YAML description, damage generates DTD, parsers, dumpers, C&Java structures to easily load, edit and generate databases and Ruby bindings along with complete document of the generated API.
Although XML is supported as input/output format, binary formats are prefered for faster access on large databases.

To create a DAMAGE library, create a YAML description (or use the example.yaml) and run
$ ruby translate.rb description.yaml

This will generate all the files and Makefiles to compile the C libraries.

To generate the java version, C structures information needs to be extracted using pahole (available from "dwarves" package).
Simply run
$ pahole gen/$(LIBNAME)/obj/i686/libsigmacDB.a > gen/$(LIBNAME)/pahole.output

Then use translate.rb again to generate the Java sources:
$ ruby  translate.rb description.yaml gen/$(LIBNAME)/pahole.output