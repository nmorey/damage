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
        module Duplicate
            
            @OUTFILE_H = "duplicate.h"
            @OUTFILE_C = "duplicate.c"

            def write(description)
                description.entries.each() { |name, entry|
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "duplicate__#{name}.c")
                    self.genC(outputC, description, entry)
                    outputC.close()
                }


                outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE_H)
                self.genH(outputH, description)
                outputH.close()
            end
            module_function :write


            private
            def genC(output, description, entry)
                libName = description.config.libname

                output.printf("#include <assert.h>\n")
                output.printf("#include <errno.h>\n")
                output.printf("#include <stdlib.h>\n")
                output.printf("#include <stdio.h>\n")
                output.printf("#include <string.h>\n")
                output.printf("#include <setjmp.h>\n")
                output.printf("#include <libxml/xmlreader.h>\n")
                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup duplicate Duplication API
 * @{
 **/
");
                
                hasNext = (entry.attribute == :listable) ? ", int siblings" : ""

                output.printf("__#{libName}_%s* __#{libName}_%s_duplicate(const __#{libName}_const_%s *ptr#{hasNext}){\n", 
                              entry.name, entry.name, entry.name)
                output.printf("\t__#{libName}_%s *first = NULL;\n\n", entry.name);
                output.printf("\tif(ptr == NULL) { return NULL;}\n");
                source="ptr"
                dest="first"
                indent="\t"
                if entry.attribute == :listable then
                    output.printf("\tconst __#{libName}_const_%s *el;\n\t__#{libName}_%s *new, **last=&first;\n\tfor(el = ptr; el != NULL; el = el->next) {\n",entry.name,entry.name)
                    source="el"
                    dest="new"
                    indent="\t\t"
                end

                output.printf("#{indent}#{dest} = __#{libName}_#{entry.name}_alloc();\n");
                
                if entry.attribute == :listable then
                    output.printf("#{indent}*last = #{dest};\n#{indent}last = &(#{dest}->next);\n")
                end

                entry.fields.each() { |field|
                    if field.target == :both then
                        case field.qty
                        when :single
                            case field.category
                            when :simple, :enum, :genum
                                # Do nothing
                                output.printf("#{indent}#{dest}->#{field.name} = #{source}->#{field.name};\n");
                            when :string
                                output.printf("#{indent}if(#{source}->%s)\n", field.name)
                                output.printf("#{indent}\t#{dest}->#{field.name} = __#{libName}_strdup(#{source}->#{field.name});\n")
                            when :intern
                                if field.attribute == :sort then
                                    # We will regen it at the end
                                    next
                                else
                                    output.printf("#{indent}if(#{source}->%s)\n", field.name)
                                    output.printf("#{indent}\t#{dest}->#{field.name} = __#{libName}_#{field.data_type}_duplicate(#{source}->#{field.name});\n")
                                end
                            when :id, :idref
                                output.printf("#{indent}#{dest}->#{field.name} = #{source}->#{field.name};\n");
                                output.printf("#{indent}if(#{source}->%s_str)\n", field.name)
                                output.printf("#{indent}\t#{dest}->#{field.name} = __#{libName}_strdup(#{source}->#{field.name}_str);\n")
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                            end
                        when :list, :container
                            case field.category
                            when :simple
                                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                                output.printf("#{indent}\t#{dest}->#{field.name}Len = #{source}->#{field.name}Len;\n")
                                output.printf("#{indent}\t#{dest}->#{field.name} = __#{libName}_malloc(#{dest}->#{field.name}Len * sizeof(*#{dest}->#{field.name}));\n")
                                output.printf("#{indent}\tmemcpy(#{dest}->#{field.name}, #{source}->#{field.name},#{dest}->#{field.name}Len * sizeof(*#{dest}->#{field.name}));\n");
                                output.printf("#{indent}}\n")
                            when :string
                                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                                output.printf("#{indent}\tunsigned int i;\n");
                                output.printf("#{indent}\t#{dest}->#{field.name}Len = #{source}->#{field.name}Len;\n")
                                output.printf("#{indent}\t#{dest}->#{field.name} = __#{libName}_malloc(#{dest}->#{field.name}Len * sizeof(*#{dest}->#{field.name}));\n")
                                output.printf("#{indent}\tfor(i = 0; i < #{source}->%sLen; i++){\n", 
                                              field.name);
                                output.printf("#{indent}\t\tif(#{source}->%s[i])\n", field.name);
                                output.printf("#{indent}\t\t\t#{dest}->#{field.name}[i] = __#{libName}_strdup(#{source}->#{field.name}[i]);\n")
                                output.printf("#{indent}\t}\n");
                                output.printf("#{indent}}\n")
                            when :intern
                                output.printf("#{indent}if(#{source}->%s)\n", field.name)
                                output.printf("#{indent}\t#{dest}->#{field.name} = __#{libName}_#{field.data_type}_duplicate(#{source}->#{field.name}, 1);\n")

                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                            end
                        end
                    end
                }
                # Autosort generation
                entry.sort.each() {|field|
                    output.printf("#{indent}__#{libName}_#{entry.name}_sort_#{field.name}(#{dest});\n")
                } 
                output.printf("\t#{entry.cleanup}(#{dest});\n") if entry.cleanup != nil 

                if entry.attribute == :listable 
                    output.printf("\t\tif(siblings == 0){\n\t\t\treturn first;\n\t\t}\n")
                    output.printf("\t}\n") 
                end
                output.printf("\treturn first;\n")
                output.printf("}\n\n")

                output.puts("
/** @} */
/** @} */
") 
            end

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_duplicate_h__\n")
                output.printf("#define __#{libName}_duplicate_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup duplicate Duplication API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Duplicate a #__#{libName}_#{entry.name} 
 * @param[in] ptr Tree to duplicate");
output.puts(" * @param[in] siblings Copy siblings")                     if entry.attribute == :listable 
output.puts(" * @return A valid pointer to a #__#{libName}_#{entry.name}. Exit with an error message if duplicate failed.
*/")
                    hasNext = (entry.attribute == :listable) ? ", int siblings" : ""
                    output.printf("__#{libName}_%s *__#{libName}_%s_duplicate(const __#{libName}_const_%s *ptr#{hasNext});\n", entry.name, entry.name, entry.name)
                }
                output.puts("
/** @} */
/** @} */
")
                output.printf("#endif /* __#{libName}_duplicate_h__ */\n")
            end
            module_function :genC, :genH
        end
    end
end
