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
    module Binary

      def write(description)
        outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "binary_writer.c")
        self.genBinaryWriter(outputC, description)
        outputC.close()

        outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "binary_reader.c")
        self.genBinaryReader(outputC, description)
        outputC.close()

      end
      module_function :write
      
      private
      def genBinaryWriter(output, description)
        libName = description.config.libname

        output.printf("#include <assert.h>\n")
        output.printf("#include <errno.h>\n")
        output.printf("#include <stdlib.h>\n")
        output.printf("#include <stdio.h>\n")
        output.printf("#include <string.h>\n")
        output.printf("#include <setjmp.h>\n")
        output.printf("#include <libxml/xmlreader.h>\n")
        output.printf("#include \"#{libName}.h\"\n")
        output.printf("#include \"#{libName}/common.h\"\n")
        output.printf("\n\n") 

        description.entries.each() { |name, entry|
          output.puts "
unsigned long __#{libName}_#{entry.name}_binary_dump(__#{libName}_#{entry.name}* ptr, 
                                                     FILE* file, unsigned long offset);\n"
        }
        output.printf("\n\n") 

        description.entries.each() { |name, entry|
          output.puts"
unsigned long __#{libName}_#{entry.name}_binary_dump(__#{libName}_#{entry.name}* ptr, 
                                                     FILE* file, unsigned long offset){
"
          output.printf("\tunsigned long child_offset = offset + sizeof(*ptr);\n")

          if entry.attribute == :listable then
            output.printf("\t__#{libName}_%s *el, *next;\n\tfor(el = ptr; el != NULL; el = next) {\n",entry.name)
            output.printf("\t\tnext = el->next;\n");
            source="el"
            indent="\t\t"
          else
            indent="\t"
            source="ptr"
          end
          output.printf("#{indent}__#{libName}_#{entry.name} val = *(#{source});\n\n")

          entry.fields.each() { |field|
            next if field.target != :both
            case field.qty
            when :single
              case field.category
              when :simple
                if(field.data_type == "char*") then
                  output.printf("#{indent}if(#{source}->%s){\n", field.name)
                  output.printf("#{indent}\tunsigned long len = strlen(#{source}->%s);\n", field.name)
                  output.printf("#{indent}\tval.%s = (char*) child_offset;\n", field.name)
                  output.printf("#{indent}\tfseek(file, child_offset, SEEK_SET);\n")
                  output.printf("#{indent}\tfwrite(#{source}->%s, sizeof(char), len, file);\n", field.name)
                  output.printf("#{indent}\tchild_offset += len;\n", field.name)
                  output.printf("#{indent}}\n")
                end
              when :intern
                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                output.printf("#{indent}\tval.%s = (__#{libName}_%s*)child_offset;\n", field.name, field.name)
                output.printf("#{indent}\tchild_offset = __#{libName}_%s_binary_dump(#{source}->%s, file, child_offset);\n", 
                              field.data_type, field.name)
                output.printf("#{indent}}\n")
              end
            when :list, :container
              case field.category
              when :simple
                if(field.data_type == "char*") then
                  output.printf("#{indent}if(#{source}->%s){\n", field.name)
                  output.printf("#{indent}\tfseek(file, child_offset, SEEK_SET);\n")
                  output.printf("#{indent}\tchar** tmp_array = __#{libName}_malloc(#{source}->%sLen * sizeof(char*));\n", field.name)
                  output.printf("#{indent}\tunsigned int i; for(i = 0; i < #{source}->%sLen; i++){\n", 
                                field.name);
                  output.printf("#{indent}\t\tif(#{source}->%s[i]){\n", field.name);
                  output.printf("#{indent}\t\t\tunsigned long len = strlen(#{source}->%s[i]);\n", field.name)
                  output.printf("#{indent}\t\t\ttmp_array[i] = (void*)child_offset;\n")
                  output.printf("#{indent}\t\t\tfwrite(#{source}->%s[i], sizeof(char), len, file);\n", field.name)
                  output.printf("#{indent}\t\t\tchild_offset += len;\n", field.name)
                  output.printf("#{indent}\t\t}\n")
                  output.printf("#{indent}\t}\n\n");
                  
                  output.printf("#{indent}\tval.%s = (char**)child_offset;\n", field.name)
                  output.printf("#{indent}\tfwrite(tmp_array, sizeof(*#{source}->%s), #{source}->%sLen, file);\n",
                                field.name, field.name);
                  output.printf("#{indent}\tchild_offset += (sizeof(*#{source}->%s) * #{source}->%sLen);\n",
                                field.name, field.name)
                  output.printf("#{indent}\t__#{libName}_free(tmp_array);\n")

                  output.printf("#{indent}}\n")
                else
                  output.printf("#{indent}if(#{source}->%s){\n", field.name)
                  output.printf("#{indent}\tval.%s = (void*)child_offset;\n", field.name)
                  output.printf("#{indent}\tfwrite(tmp_array, sizeof(*#{source}->%s), #{source}->%sLen, file);\n",
                                field.name, field.name);
                  output.printf("#{indent}\tchild_offset += (sizeof(*#{source}->%s) * #{source}->%sLen);\n",
                                field.name, field.name)
                    output.printf("#{indent}}\n")
              end
              when :intern
                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                output.printf("#{indent}\tval.%s = (void*)child_offset;\n", field.name)
                output.printf("#{indent}\tchild_offset = __#{libName}_%s_binary_dump(#{source}->%s, file, child_offset);\n", 
                              field.data_type, field.name)
                output.printf("#{indent}}\n")
              end
            end
          }

          
          output.printf("#{indent}val.next = (void*)child_offset;\n") if entry.attribute == :listable 

          output.printf("#{indent}fseek(file, offset, SEEK_SET);\n")
          output.printf("#{indent}fwrite(&val, sizeof(val), 1, file);\n")


          if entry.attribute == :listable  then
            output.printf("#{indent}offset = child_offset;\n") 
            output.printf("#{indent}child_offset += sizeof(*ptr);\n") 
            output.printf("\t}\n") 
          end

          output.puts "\treturn child_offset;"
          output.puts "}"
        }

         description.entries.each() { | name, entry|
          output.printf("unsigned long __#{libName}_%s_binary_dump_file(const char* file, __#{libName}_%s *ptr)\n{\n", entry.name, entry.name)
          output.printf("\tunsigned long ret;\n")
          output.printf("\tFILE* output;\n")
          output.printf("\n")
          output.printf("\tif(__#{libName}_acquire_flock(file))\n");
          output.printf("\t\t__#{libName}_error(\"Failed to lock output file %%s\", ENOENT, file);\n");
          output.printf("\tif((output = fopen(file, \"w+\")) == NULL)\n");
          output.printf("\t\t__#{libName}_error(\"Failed to open output file %%s\", errno, file);\n");

          output.printf("\tret = __#{libName}_%s_binary_dump(ptr, output, 0UL);\n", entry.name)
          output.printf("\tfclose(output);\n")
          output.printf("\t__#{libName}_release_flock(file);\n");
          output.printf("\treturn ret;\n");
          output.printf("}\n");
        }
      end
      module_function :genBinaryWriter

      def genBinaryReader(output, description)
      end
      module_function :genBinaryReader
    end
  end
end
