# -*- coding: utf-8 -*-
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
                self.genTest4(description) if description.config.rowip == true
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
                        next if field.target != :both
                        case field.category
                        when :intern
                            output.puts "\tptr->#{field.name} = create#{field.data_type}(#{nb_neighbours});"
                        when :string
                            if field.qty != :single
                                output.puts "ptr->#{field.name}Len = rand()%10;"
                                output.puts "ptr->#{field.name} = malloc(sizeof(*ptr->#{field.name}) * ptr->#{field.name}Len);"
                                output.puts "\tfor(unsigned _idx = 0; _idx < ptr->#{field.name}Len; ++_idx)"
                            end
                            output.puts "\t{\n"
                            output.puts "\t\tunsigned long i, len = rand()%128;\n"
                            output.puts "\t\tchar _str[129];\n"
                            output.puts "\t\tfor(i=0; i < len; i++){ _str[i] = (rand() % 26) + 'a';}\n"
                            output.puts "\t\t_str[len] = 0;\n"
                            if field.qty != :single
                                output.puts "\t\tptr->#{field.name}[_idx] = strdup(_str);\n"
                            else
                                output.puts "\t\tptr->#{field.name} = strdup(_str);\n"
                            end
                            output.puts "\t}\n"
                        when :simple
                            next if field.qty != :single
                            case field.data_type
                            when "int"
                                output.puts "\tptr->#{field.name} = 42;"
                            when "long"
                                output.puts "\tptr->#{field.name} = 0;"
                            when "double"
                                output.puts "\tptr->#{field.name} = drand48();"
                            end
                        when :id, :idref
                            output.puts "\t{\n"
                            output.puts "\t\tchar _str[1024];;\n"
                            if field.category == :id then
                                output.puts "\t\tsnprintf(_str, 1024, \"#{entry.name}-%d\", first);\n"
                            else
                                output.puts "\t\tsnprintf(_str, 1024, \"#{field.data_type}-%d\", first);\n"
                            end
                            output.puts "\t\tptr->#{field.name}_str = strdup(_str);\n"
                            output.puts "\t\tptr->#{field.name} = first;\n"
                            output.puts "\t}\n"
                        when :enum
                            next if field.qty != :single
                            output.puts "\tptr->#{field.name} = 1;"
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


            def genDBModifyer(output, description, rowip = false)
                libName = description.config.libname
                funcPrefix=""
                funcPrefix="rowip_" if rowip != false
                description.entries.each() { |name, entry|
                    output.puts "void #{funcPrefix}modify#{entry.name}(__#{libName}_#{entry.name}* ptr);"
                }

                description.entries.each() { |name, entry|
                    output.puts "void #{funcPrefix}modify#{entry.name}(__#{libName}_#{entry.name}* ptr){
\t__#{libName}_#{entry.name}* el __attribute__ ((unused)) = NULL;"
                    if entry.attribute == :listable
                        if rowip != false
                            output.puts "\tfor(el = ptr; el != NULL; el = __#{libName.upcase}_ROWIP_PTR(el, next)){" 
                        else
                            output.puts "\tfor(el = ptr; el != NULL; el = el->next){"
                        end
                    else
                        output.puts "\tel = ptr;"
                    end
                    entry.fields.each() { |field|
                        if field.target != :mem then
                            if field.category == :intern then
                                output.puts "\tif(el->#{field.name} != NULL)"
                                if rowip != false
                                    output.puts "\t\t#{funcPrefix}modify#{field.data_type}(__#{libName.upcase}_ROWIP_PTR(el, #{field.name}));"
                                else
                                    output.puts "\t\t#{funcPrefix}modify#{field.data_type}(el->#{field.name});"
                                end
                            elsif field.data_type == "unsigned long"
                                output.puts "\tel->#{field.name} = 42;"
                                #                output.printf("\printf(\"#{funcPrefix}Changing %s.%s to 42\\n\");\n", entry.name, field.name)
                            elsif field.data_type == "double"
                                output.puts "\tel->#{field.name} = 42.0;"
                            end
                        end
                    }
                    if entry.attribute == :listable then
                        output.puts "\t}"
                    end

                    output.puts "}"

                }
            end
            module_function :genDBModifyer

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
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(file, CONSTIFY(ptr), 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", file);
		exit(2);
	}
    printf(\"Generated DB\\n\");
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(file, CONSTIFY(ptr), __SIGMACDB_OPTION_GZIPPED) < 0) {
		fprintf(stderr, \"Failed writing to %s in gzipped mode\\n\", file);
		exit(3);
	}
    printf(\"Wrote XML DB\\n\");
	__#{libName}_#{description.top_entry.name} *ptr2;
	ptr2 = __#{libName}_#{description.top_entry.name}_xml_load_file(file, __SIGMACDB_OPTION_GZIPPED);
	if (ptr2 == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(4);
    }
     printf(\"Parsed XML DB\\n\");
   if(__#{libName}_#{description.top_entry.name}_compare_single(ptr, ptr2) == 0){
        fprintf(stderr, \"Dumped and reloaded version differ ! \\n\");
        exit(5);
    }
    printf(\"Compared created and dumped DB\\n\");
	__#{libName}_#{description.top_entry.name}_free(ptr);
    printf(\"Freed DB\\n\");
	__#{libName}_#{description.top_entry.name}_free(ptr2);
    printf(\"Freed DB\\n\");
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
	__#{libName}_#{description.top_entry.name} *ptr2;

	if (__#{libName}_#{description.top_entry.name}_binary_dump_file(file, ptr, __SIGMACDB_OPTION_GZIPPED) == 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", file);
		exit(2);
	}
    printf(\"Wrote Binary DB\\n\");

	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml, CONSTIFY(ptr), 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(3);
	}
    printf(\"Wrote XML DB\\n\");

	ptr2 = __#{libName}_#{description.top_entry.name}_binary_load_file(file, __SIGMACDB_OPTION_GZIPPED);
	if (ptr2 == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(4);
    }
    printf(\"Loaded binary DB\\n\");
    if(__#{libName}_#{description.top_entry.name}_compare_single(ptr, ptr2) == 0){
        fprintf(stderr, \"Dumped and reloaded version differ ! \\n\");
        exit(5);
    }
    printf(\"Compared created and dumped DB\\n\");
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml2, CONSTIFY(ptr2), 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(6);
	}
     printf(\"Dumped XML DB DB\\n\");

	__#{libName}_#{description.top_entry.name}_free(ptr);
    printf(\"Freed DB\\n\");
	__#{libName}_#{description.top_entry.name}_free(ptr2); 
    printf(\"Freed DB\\n\");
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
                genDBCreator(output, description, 10)
                output.puts "
int main()
{
   char* file=\".db/test3.db\";
   char* xml=\".db/test3.xml.org\";

	__#{libName}_#{description.top_entry.name} *ptr = create#{description.top_entry.name}(1);
	__#{libName}_#{description.top_entry.name} *ptr2, *ptr3;

	if (__#{libName}_#{description.top_entry.name}_binary_dump_file(file, ptr, 0) == 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", file);
		exit(2);
	}
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml, CONSTIFY(ptr), __SIGMACDB_OPTION_GZIPPED) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(2);
	}
	ptr2 = __#{libName}_#{description.top_entry.name}_binary_load_file(file, 0);
	if (ptr2 == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(3);
    }
    if(__#{libName}_#{description.top_entry.name}_compare_single(ptr, ptr2) == 0){
        fprintf(stderr, \"Dumped and reloaded version differ ! \\n\");
        exit(4);
    }
	__#{libName}_#{description.top_entry.name}_free(ptr2);


    ptr3 = __#{libName}_#{description.top_entry.name}_xml_load_file(xml, __SIGMACDB_OPTION_GZIPPED);
	if (ptr3 == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", xml);
		exit(5);
    }

    if(__#{libName}_#{description.top_entry.name}_compare_single(ptr, ptr3) == 0){
        fprintf(stderr, \"Dumped and reloaded version differ ! \\n\");
        exit(6);
    }
	__#{libName}_#{description.top_entry.name}_free(ptr);
	__#{libName}_#{description.top_entry.name}_free(ptr3); 

	return 0;
}

"
            end
            module_function :genTest3

            # Test ROWIP feature
            def genTest4(description)  
                libName = description.config.libname
                output = Damage::Files.createAndOpen("gen/#{libName}/test/", "create_dump_and_reload_rowip.c")
                output.puts "
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <#{libName}.h>
#include <string.h>

"
                genDBCreator(output, description, 10)
                genDBModifyer(output, description)
                genDBModifyer(output, description, 1)
                output.puts "

int main()
{
   char* file=\".db/test4.db\";
   char* xml=\".db/test4.xml.org\";
   char* xml2=\".db/test4.xml.v2\";

	__#{libName}_#{description.top_entry.name} *ptr = create#{description.top_entry.name}(1);

	if (__#{libName}_#{description.top_entry.name}_binary_dump_file(file, ptr, 0) == 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", file);
		exit(2);
	}
	__#{libName}_#{description.top_entry.name}_free(ptr);
	ptr = __#{libName}_#{description.top_entry.name}_binary_load_file(file, 0);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(3);
    }
    modify#{description.top_entry.name}(ptr);
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml, CONSTIFY(ptr), 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(4);
	}
	__#{libName}_#{description.top_entry.name}_free(ptr); 

	ptr = __#{libName}_#{description.top_entry.name}_binary_load_file_rowip(file);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(5);
    }
    rowip_modify#{description.top_entry.name}(ptr);
	if (__#{libName}_#{description.top_entry.name}_binary_dump_file_rowip(ptr) == 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(6);
	}

	ptr = __#{libName}_#{description.top_entry.name}_binary_load_file(file);
	if (ptr == NULL) {
		fprintf(stderr, \"Failed to parse %s\\n\", file);
		exit(7);
    }
	if (__#{libName}_#{description.top_entry.name}_xml_dump_file(xml2, CONSTIFY(ptr), 0) < 0) {
		fprintf(stderr, \"Failed writing to %s\\n\", xml);
		exit(8);
	}
	__#{libName}_#{description.top_entry.name}_free(ptr); 


	return 0;
}

"
            end
            module_function :genTest4
        end
    end
end
