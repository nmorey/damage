module Damage
  module GenTests

    def write(description)
      output = Damage::Files.createAndOpen("gen/#{description.config.libname}/test/", "create_dump_and_reload.c")
      self.genTest1(output, description)
      output.close()
    end
    module_function :write


    private
    def genTest1(output, description)  
      libName = description.config.libname
      output.puts "
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <#{libName}.h>
#include <string.h>

"
      description.entries.each() { |name, entry|
        output.puts "__#{libName}_#{entry.name}* create#{entry.name}(int first);"
      }

      description.entries.each() { |name, entry|
        output.puts "__#{libName}_#{entry.name}* create#{entry.name}(int first __attribute__((unused))){
\t__#{libName}_#{entry.name}* ptr = __#{libName}_#{entry.name}_alloc();"
        entry.fields.each() { |field|
          if field.target != :mem && field.category == :intern then
            output.puts "\tptr->#{field.name} = create#{field.data_type}(1);"
          end
        }
        if entry.attribute == :listable then
          output.puts "\tif(first)"
          output.puts "\t\tptr->next = create#{entry.name}(0);"
        end

        output.puts "
\treturn ptr;
}"
      }
        output.puts "
int main(int argc, char *argv[])
{
	__#{libName}_#{description.top_entry.name} *ptr = create#{description.top_entry.name}(1);
	if (argc < 2) {
		fprintf(stderr, \"Usage: %s file\\n\", argv[0]);
		exit(1);
	}
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(argv[1], ptr) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", argv[1]);
		exit(2);
	}
	__#{libName}_#{description.top_entry.name}_free(ptr);

	ptr = __#{libName}_#{description.top_entry.name}_xml_parse_file(argv[1]);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", argv[1]);
		exit(3);
    }
	__#{libName}_#{description.top_entry.name}_free(ptr);
	return 0;
}

"
    end
    module_function :genTest1
  end
end
