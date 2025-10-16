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
        module Dump
            
            @OUTFILE_H = "dump.h"
            @OUTFILE_C = "dump.c"
            
            def write(description)

                 description.entries.each() { |name, entry|
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "dump__#{name}.c")
                    self.genC(outputC, description, entry)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "dump_wrapper__#{name}.c")
                    self.genCWrapper(outputC, description, entry)
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
                output.printf("#include <stdlib.h>\n")
                output.printf("#include <stdio.h>\n")
                output.printf("#include <string.h>\n")
                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup #{libName}_dump Dump API
 * @{
 **/
");

                output.printf("\tvoid __#{libName}_#{entry.name}_dumpWithIndent(FILE* file, const __#{libName}_#{entry.name} *ptr, int indent){\n")
                output.printf("\t\tint first = 1;\n");

                if entry.attribute == :listable then
                    output.puts("\t\tint listable = 1;")
                else
                    output.puts("\t\tint listable = 0;")
                end
                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple
                            output.printf("\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\tfirst = 0;\n")
                            output.printf("\t\tfprintf(file, \"#{field.name}: %%#{field.printf}\\n\", ptr->#{field.name});\n");
                        when :enum
                            output.printf("\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\tfirst = 0;\n")
                            output.printf("\t\tfprintf(file, \"#{field.name}: %%s\\n\", "+
                                          "__#{libName}_#{entry.name}_#{field.name}_strings[ptr->#{field.name}]);\n") 
                        when :genum
                            output.printf("\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\tfirst = 0;\n")
                            output.printf("\t\tfprintf(file, \"#{field.name}: %%s\\n\", "+
                                          "__#{libName}_#{field.genumEntry}_#{field.genumField}_strings[ptr->#{field.name}]);\n") 

                        when :string
                            output.printf("\t\tif(ptr->#{field.name} != NULL){\n");
                            output.printf("\t\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\t\tfirst = 0;\n")
                            output.printf("\t\t\tfprintf(file, \"#{field.name}: \\\"%%s\\\"\\n\", ptr->#{field.name});\n");
                            output.printf("\t\t}\n");
                       when :raw
                            output.printf("\t\tif(ptr->#{field.name} != NULL){\n");
                            output.printf("\t\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\t\tfirst = 0;\n")
                            output.printf("\t\t\tchar* data = __#{libName}_malloc(ptr->#{field.name}Length * 4 / 3 + 3);\n");
                            output.printf("\t\t\t__#{libName}_base64_encode(ptr->#{field.name}, ptr->#{field.name}Length," +
                                          "data, ptr->#{field.name}Length * 4 / 3 + 3);\n");
                            output.printf("\t\t\tfprintf(file, \"#{field.name}: \\\"%%s\\\"\\n\", data);\n");
                            output.printf("\t\t\tfree(data);\n");
                            output.printf("\t\t}\n");
                        when :intern
                            output.printf("\t\tif(ptr->#{field.name} != NULL){\n");
                            output.printf("\t\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\t\tfirst = 0;\n")
                            output.printf("\t\t\tfprintf(file, \"#{field.name}: \\n\");\n");
                            output.printf("\t\t\t__#{libName}_#{field.data_type}_dumpWithIndent(file, ptr->#{field.name}, indent+1);\n");
                            output.printf("\t\t}\n");

                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                        when :simple
                            output.printf("\t\t{\n");
                            output.printf("\t\t\tunsigned int i;\n");
                            output.printf("\t\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\t\tfirst = 0;\n")
                            output.printf("\t\t\tfprintf(file, \"#{field.name}:\\n\");\n");
                            output.printf("\t\t\tfor(i = 0; i < ptr->#{field.name}Len; i++){\n");
                            output.printf("\t\t\t\t__#{libName}_paddOutput(file, indent + 1, 1, 1);\n")
                            output.printf("\t\t\t\tfprintf(file, \"%%#{field.printf}\\n\", ptr->#{field.name}[i]);\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                        when :string
                            output.printf("\t\t{\n");
                            output.printf("\t\t\tunsigned int i;\n");
                            output.printf("\t\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\t\tfirst = 0;\n")
                            output.printf("\t\t\tfprintf(file, \"#{field.name}:\\n\");\n");
                            output.printf("\t\t\tfor(i = 0; i < ptr->#{field.name}Len; i++){\n");
                            output.printf("\t\t\t\t__#{libName}_paddOutput(file, indent + 1, 1, 1);\n")
                            output.printf("\t\t\t\tfprintf(file, \"\\\"%%s\\\"\\n\", ptr->#{field.name}[i]);\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                        when :raw
                            output.printf("\t\t{\n");
                            output.printf("\t\t\tunsigned int i;\n");
                            output.printf("\t\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\t\tfirst = 0;\n")
                            output.printf("\t\t\tfprintf(file, \"#{field.name}:\\n\");\n");
                            output.printf("\t\t\tfor(i = 0; i < ptr->#{field.name}Len; i++){\n");
                            output.printf("\t\t\t\t__#{libName}_paddOutput(file, indent + 1, 1, 1);\n")
                            output.printf("\t\t\t\tchar* data = __#{libName}_malloc(ptr->#{field.name}Length[i] * 4 / 3 + 3);\n");
                            output.printf("\t\t\t\t__#{libName}_base64_encode(ptr->#{field.name}[i], ptr->#{field.name}Length[i]," +
                                          "data, ptr->#{field.name}Length[i] * 4 / 3 + 3);\n");
                            output.printf("\t\t\t\tfprintf(file, \"\\\"%%s\\\"\\n\", data);\n");
                            output.printf("\t\t\t\tfree(data);\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                        when :intern
                            output.printf("\t\t{\n");
                            output.printf("\t\t\t__#{libName}_#{field.data_type} *el;\n");
                            output.printf("\t\t\t__#{libName}_paddOutput(file, indent, listable, first);\n")
                            output.printf("\t\t\tfirst = 0;\n")
                            output.printf("\t\t\tfprintf(file, \"#{field.name}:\\n\");\n");
                            output.printf("\t\t\tfor(el = ptr->#{field.name}; el; el = el->next){\n");
                            output.printf("\t\t\t\t__#{libName}_#{field.data_type}_dumpWithIndent(file, el, indent+1);\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end                  
                    else
                        raise("Unsupported quantitiy for #{entry.name}.{field.name}")
                    end
                }

                output.printf("\t}\n\n")
                output.puts("
/** @} */
/** @} */
")  
            end

            def genCWrapper(output, description, entry)

                libName = description.config.libname
                output.printf("#include <stdlib.h>\n")
                output.printf("#include <stdio.h>\n")
                output.printf("#include <string.h>\n")
                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup #{libName}_dump Dump API
 * @{
 **/
");

                output.printf("\tvoid __#{libName}_#{entry.name}_dump(FILE* file, const __#{libName}_#{entry.name} *ptr, __#{libName}_options opts #{entry.attribute == :listable ? "" : ("__" + libName.upcase + "_UNUSED__")}){\n")
                
                output.printf("\t\tfprintf(file, \"#{entry.name}:\\n\");\n")
                output.printf("\t\tdo {\n")
                output.printf("\t\t\t__#{libName}_#{entry.name}_dumpWithIndent(file, ptr, 1);\n")
                if entry.attribute == :listable
                    output.printf("\t\t\tptr = ptr->next;\n")
                    output.printf("\t\t}while(ptr != NULL && (opts & __#{libName.upcase}_OPTION_NO_SIBLINGS) == 0);\n")
                else
                    output.printf("\t\t}while(0);\n")
                end
                output.printf("\t}\n\n")
                output.puts("
/** @} */
/** @} */
")          

            end

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_dump_h__\n")
                output.printf("#define __#{libName}_dump_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup #{libName}_dump Dump API
 * @{
 **/

/**
 * We define wrapper functions with options even for elements which are not listable.
 * We need to define parameters as unused to remove warning but it needs
 * a little trick to work correctly with doxygen.
 */
#define __#{libName.upcase}_UNUSED__ __attribute__((unused))

");
                description.entries.each() { |name, entry|
                    output.puts("
/**
 * Internal: Dump a #__#{libName}_#{entry.name} to YAML form
 * @param[in] file Output file
 * @param[in] ptr Pointer to the objet to dump (without siblings)
 * @param[in] indent Number of header tabs
 * @return A valid pointer to a #__#{libName}_#{entry.name}. Exit with an error message if alloc failed.
*/")
                    output.printf("\tvoid __#{libName}_#{entry.name}_dumpWithIndent(FILE* file, const __#{libName}_#{entry.name} *ptr, int indent);") 

                    output.puts("
/**
 * Dump a #__#{libName}_#{entry.name} to YAML form
 * @param[in] file Output file
 * @param[in] ptr Pointer to the objet to dump (without siblings)
 * @param[in] opts Options to dumper (dump simblings, etc)
 * @return A valid pointer to a #__#{libName}_#{entry.name}. Exit with an error message if alloc failed.
*/")
                    output.printf("\tvoid __#{libName}_#{entry.name}_dump(FILE* file, const __#{libName}_#{entry.name} *ptr, __#{libName}_options opts);\n")
                }

                output.puts("
/** @} */
/** @} */
")
                output.printf("#endif /* __#{libName}_dump_h__ */\n")
            end
            module_function :genC, :genCWrapper, :genH
        end
    end
end
