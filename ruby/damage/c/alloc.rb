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
    module Alloc
      
      @OUTFILE_H = "alloc.h"
      @OUTFILE_C = "alloc.c"

      def write(description)
        outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", @OUTFILE_C)
        outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE_H)
        self.genC(outputC, description)
        self.genH(outputH, description)
        outputC.close()
        outputH.close()
      end
      module_function :write


      private
      def genC(output, description)
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
          output.printf("__#{libName}_%s *__#{libName}_%s_alloc()\n",
                        entry.name, entry.name)
          output.printf("{\n")
          output.printf("\t__#{libName}_%s *ptr;\n", entry.name)
          output.printf("\tptr = __#{libName}_malloc(sizeof(*ptr));\n\n")

          entry.fields.each() { |field|
            case field.attribute
            when :sort
              output.printf("\tptr->s_%s = NULL;\n", field.name)
              output.printf("\tptr->n_%s = 0UL;\n", field.name)
            when :pass
            else
              output.printf("\tptr->%s = %s;\n", field.name, field.default_val)
            end
            output.printf("\tptr->%sLen = 0UL;\n", field.name) if ((field.qty == :list) && (field.category == :simple))
            output.printf("\tptr->%s_str = NULL;\n", field.name) if ((field.category == :id) || (field.category == :idref))
          }

          output.printf("\tptr->next = NULL;\n")         if entry.attribute == :listable
          output.printf("\tptr->_private = NULL;\n")
          output.printf("\tptr->_rowip = NULL;\n")
          output.printf("\treturn ptr;\n")
          output.printf("}\n\n")
          output.printf("void __#{libName}_%s_free(__#{libName}_%s *ptr){\n", 
                        entry.name, entry.name)
          source="ptr"
          indent="\t"
          if entry.attribute == :listable then
            output.printf("\t__#{libName}_%s *el, *next;\n\tfor(el = ptr; el != NULL; el = next) {\n",entry.name)
            output.printf("\t\tnext = el->next;\n");
            source="el"
            indent="\t\t"
          end
          entry.fields.each() { |field|
            if field.target != :parser then
              case field.qty
              when :single
                case field.category
                when :simple
                  if(field.data_type == "char*") then
                    output.printf("#{indent}if(#{source}->%s)\n", field.name)
                    output.printf("#{indent}\t__#{libName}_free(#{source}->%s);\n", field.name)
                  end
                when :intern
                  if field.attribute == :sort then
                    output.printf("#{indent}if(#{source}->s_%s)\n", field.name)
                    output.printf("#{indent}\t__#{libName}_free(#{source}->s_%s);\n", field.name)
                  else
                    output.printf("#{indent}if(#{source}->%s)\n", field.name)
                    output.printf("#{indent}\t__#{libName}_%s_free(#{source}->%s);\n", 
                                  field.data_type, field.name)
                  end
                when :id, :idref
                    output.printf("#{indent}if(#{source}->%s_str)\n", field.name)
                    output.printf("#{indent}\t__#{libName}_free(#{source}->%s_str);\n", field.name)
                end
              when :list, :container
                case field.category
                when :simple
                  if(field.data_type == "char*") then
                    output.printf("#{indent}if(#{source}->%s){\n", field.name)
                    output.printf("#{indent}\t{ unsigned int i; for(i = 0; i < #{source}->%sLen; i++){\n", 
                                  field.name);
                    output.printf("#{indent}\t\tif(#{source}->%s[i])\n", field.name);
                    output.printf("#{indent}\t\t\t__#{libName}_free(#{source}->%s[i]);\n", 
                                  field.name) ;
                    output.printf("#{indent}\t} }\n");
                    output.printf("#{indent}\t__#{libName}_free(#{source}->%s);\n", field.name)
                    output.printf("#{indent}}\n")
                  else
                    output.printf("#{indent}if(#{source}->%s)\n", field.name)
                    output.printf("#{indent}\t__#{libName}_free(#{source}->%s);\n", field.name)
                  end
                when :intern
                  output.printf("#{indent}if(#{source}->%s)\n", field.name)
                  output.printf("#{indent}\t__#{libName}_%s_free(#{source}->%s);\n", 
                                field.data_type, field.name)
                end
              end
            end
          }


          output.printf("#{indent}__#{libName}_free(#{source});\n")

          output.printf("\t}\n") if entry.attribute == :listable 

          output.printf("\treturn;\n")
          output.printf("}\n\n")
        }
      end

      def genH(output, description)
        libName = description.config.libname

        output.printf("#ifndef __#{libName}_alloc_h__\n")
        output.printf("#define __#{libName}_alloc_h__\n")
        output.printf("#include <libxml/xmlreader.h>\n")

        description.entries.each() {|name, entry|
          output.printf("__#{libName}_%s *__#{libName}_%s_alloc();\n", entry.name, entry.name)
          output.printf("void __#{libName}_%s_free(__#{libName}_%s *ptr);\n", entry.name, entry.name)

          output.printf("__#{libName}_%s *__#{libName}_%s_xml_parse_file(const char* file);\n", entry.name, entry.name);
          output.printf("__#{libName}_%s *__#{libName}_%s_xml_parse(xmlNodePtr node);\n", entry.name, entry.name)

          output.printf("int __#{libName}_%s_xml_dump_file(const char* file, __#{libName}_%s *ptr, int zipped);\n", entry.name, entry.name)
          output.printf("xmlNodePtr __#{libName}_create_%s_xml_node(xmlNodePtr node, __#{libName}_%s* ptr);\n", entry.name, entry.name)

          output.printf("unsigned long __#{libName}_%s_binary_dump_file(const char* file, __#{libName}_%s *ptr);\n", entry.name, entry.name)
          output.printf("__#{libName}_%s *__#{libName}_%s_binary_load_file(const char* file);\n", entry.name, entry.name);

          output.printf("unsigned long __#{libName}_%s_binary_dump_file_rowip(__#{libName}_%s *ptr);\n", entry.name, entry.name)
          output.printf("__#{libName}_%s *__#{libName}_%s_binary_load_file_rowip(const char* file);\n", entry.name, entry.name);


          output.printf("\n")
        }
        output.printf("#endif /* __#{libName}_alloc_h__ */\n")
      end
      module_function :genC, :genH
    end
  end
end
