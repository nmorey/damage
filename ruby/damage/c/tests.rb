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
    module Tests

      def write(description)
        libName = description.config.libname
        output = Damage::Files.createAndOpen("gen/#{libName}/.db/", "dummy")
        self.genTest1(description)
        self.genTest2(description)
        self.genTest3(description)
      end
      module_function :write

      

      private

      def genDBCreator(output, description, nb_neighbours=1)
        libName = description.config.libname
        description.entries.each() { |name, entry|
          output.puts "__#{libName}_#{entry.name}* create#{entry.name}(int first);"
        }

        description.entries.each() { |name, entry|
          output.puts "__#{libName}_#{entry.name}* create#{entry.name}(int first __attribute__((unused))){
\t__#{libName}_#{entry.name}* ptr = NULL;"
          if entry.attribute == :listable
            output.puts "\t__#{libName}_#{entry.name}* prev = NULL, *pfirst = NULL;" 
            output.puts "\twhile(first >=0){" 
          end
output.puts "
\tptr = __#{libName}_#{entry.name}_alloc();"
          entry.fields.each() { |field|
            if field.target != :mem && field.category == :intern then
              output.puts "\tptr->#{field.name} = create#{field.data_type}(#{nb_neighbours});"
            end
          }
          if entry.attribute == :listable then
            output.puts "\tfirst--;"
            output.puts "\tif(prev){"
            output.puts "\t\tprev->next = ptr;"
            output.puts "\t} else {"
            output.puts "\t\tpfirst = ptr;"
            output.puts "\t}"
            output.puts "\tprev = ptr;"
            output.puts "\t}"
            output.puts "\treturn pfirst;\n}\n"
          else

            output.puts "
\treturn ptr;
}"
          end
        }
      end
      module_function :genDBCreator

      def genTest1(description)  
        libName = description.config.libname
        output = Damage::Files.createAndOpen("gen/#{libName}/test/", "create_dump_and_reload.c")
        output.puts "
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <#{libName}.h>
#include <string.h>

"
        genDBCreator(output, description)
        output.puts "
int main()
{
   char* file=\".db/test1.xml\";

	__#{libName}_#{description.top_entry.name} *ptr = create#{description.top_entry.name}(1);
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(file, ptr, 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", file);
		exit(2);
	}
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(file, ptr, 1) < 0) {
		fprintf(stderr, \"Failed writing to %s in gzipped mode\\n\", file);
		exit(3);
	}

	__#{libName}_#{description.top_entry.name}_free(ptr);

	ptr = __#{libName}_#{description.top_entry.name}_xml_parse_file(file);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(4);
    }
	__#{libName}_#{description.top_entry.name}_free(ptr);
	return 0;
}

"
        output.close()

      end
      module_function :genTest1

      def genTest2(description)  
        libName = description.config.libname
         output = Damage::Files.createAndOpen("gen/#{libName}/test/", "create_dump_and_reload_binary.c")
       output.puts "
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <#{libName}.h>
#include <string.h>

"
        genDBCreator(output, description, 2)
        output.puts "
int main()
{
   char* file=\".db/test2.db\";
   char* xml=\".db/test2.xml.org\";
   char* xml2=\".db/test2.xml.db\";

	__#{libName}_#{description.top_entry.name} *ptr = create#{description.top_entry.name}(1);

	if (__#{libName}_#{description.top_entry.name}_binary_dump_file(file, ptr) == 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", file);
		exit(2);
	}
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml, ptr, 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(2);
	}
	__#{libName}_#{description.top_entry.name}_free(ptr);

	ptr = __#{libName}_#{description.top_entry.name}_binary_load_file(file);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(3);
    }
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml2, ptr, 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(2);
	}

	__#{libName}_#{description.top_entry.name}_free(ptr); 
	return 0;
}

"
      end
      module_function :genTest2

     def genTest3(description)  
       libName = description.config.libname
       output = Damage::Files.createAndOpen("gen/#{libName}/test/", "create_dump_and_reload_binary_long.c")
       output.puts "
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <#{libName}.h>
#include <string.h>

"
        genDBCreator(output, description, 15)
        output.puts "
int main()
{
   char* file=\".db/test3.db\";
   char* xml=\".db/test3.xml.org\";

	__#{libName}_#{description.top_entry.name} *ptr = create#{description.top_entry.name}(1);

	if (__#{libName}_#{description.top_entry.name}_binary_dump_file(file, ptr) == 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", file);
		exit(2);
	}
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml, ptr, 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(2);
	}
	__#{libName}_#{description.top_entry.name}_free(ptr);

	ptr = __#{libName}_#{description.top_entry.name}_binary_load_file(file);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(3);
    }
	__#{libName}_#{description.top_entry.name}_free(ptr); 

    ptr = __#{libName}_#{description.top_entry.name}_xml_parse_file(xml);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", xml);
		exit(4);
    }
	__#{libName}_#{description.top_entry.name}_free(ptr); 

	return 0;
}

"
      end
      module_function :genTest3
    end
  end
end
