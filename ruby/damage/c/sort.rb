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
        module Sort
            @OUTFILE = "sort.c"
            @OUTFILE_H = "sort.h"

            def write(description)
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", @OUTFILE)
                genSorter(output, description)
                output.close()
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/", @OUTFILE_H)
                genHeader(output, description)
                output.close()
            end
            module_function :write

            private
            def genHeader(output, description)
                libName = description.config.libname
 
                output.puts("#ifndef __#{libName}_sort_h__")
                output.puts("#define __#{libName}_sort_h__\n")
output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup sort Sort API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    entry.sort.each() {|field|
                        output.puts("
/**
 * Generates an array of #__#{libName}_#{field.data_type} indexed by their #{field.sort_key} field.
 * The array is stored at ptr->s_#{field.name} and its length at ptr->n_#{field.name}.
 * @param[in] ptr Structure containing the list to sort and where to store the indexed array
 * @return Nothing
*/");
                        output.printf("void __#{libName}_#{entry.name}_sort_#{field.name}(__#{libName}_#{entry.name}* ptr);\n\n")
   
                    }
                }

output.puts("
/** @} */
/** @} */
")
                   output.puts("#endif /* __#{libName}_sort_h__ */\n")
            end
            module_function :genHeader
            def genSorter(output, description)
                libName = description.config.libname
                output.printf("#include \"#{libName}.h\"\n");
                output.printf("#include \"_#{libName}/common.h\"\n");
                output.printf("\n");
                output.printf("jmp_buf __#{libName}_error_happened;\n");
                output.printf("\n\n");
                description.entries.each() {|name, entry|
                    entry.sort.each() {|field|
                        output.printf("void __#{libName}_#{entry.name}_sort_#{field.name}(__#{libName}_#{entry.name}* ptr){\n")
                        output.printf("\tif (ptr != NULL) {\n");
                        output.printf("\t\tunsigned long count = 0UL;\n");
                        output.printf("\t\t__#{libName}_%s * %s;\n", field.data_type, field.name);
                        output.printf("\t\tfor(%s = ptr->%s; %s != NULL;%s = %s->next){\n",
                                      field.name, field.sort_field, field.name, field.name, field.name);
                        output.printf("\t\t\tcount = (%s->%s >= count) ? (%s->%s+1) : count;\n\t\t\t\t\t}\n\n",
                                      field.name, field.sort_key, field.name, field.sort_key);
                        output.printf("\t\tif(count > 0) {\n")
                        output.printf("\t\t\tptr->s_%s = __#{libName}_malloc(count * sizeof(*(ptr->s_%s)));\n",
                                      field.name, field.name);
                        output.printf("\t\t\tmemset(ptr->s_%s, 0, (count * sizeof(*(ptr->s_%s))));\n",
                                      field.name, field.name);
                        output.printf("\t\t\tptr->n_%s = count;\n", field.name);
                        output.printf("\t\t\tfor(%s = ptr->%s; %s != NULL;%s = %s->next){\n",
                                      field.name, field.sort_field, field.name, field.name, field.name);
                        output.printf("\t\t\t\tassert(%s->%s < count);\n", field.name, field.sort_key);
                        output.printf("\t\t\t\tptr->s_%s[%s->%s] = %s;\n", field.name, field.name, field.sort_key, field.name);
                        output.printf("\t\t\t}\n");
                        output.printf("\t\t}\n");
                        output.printf("\t}\n");
                        output.printf("}\n\n");
                    }
                }
            end
            module_function :genSorter
        end
    end
end
