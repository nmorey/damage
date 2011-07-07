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
        module Compare
            
            @OUTFILE_H = "compare.h"
            @OUTFILE_C = "compare.c"

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
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup compare Comparison API
 * @{
 **/
");
                description.entries.each() { |name, entry|
                    offset = "\t"
                    if (entry.comparable == false)
                        output.printf("int __#{libName}_%s_compare_single(__#{libName}_%s *ptr1 __#{libName.upcase}_UNUSED__, __#{libName}_%s *ptr2 __#{libName.upcase}_UNUSED__) {\n", entry.name, entry.name, entry.name)
                        output.printf("#{offset}return 1;\n}\n\n")
                        next
                    else
                        output.printf("int __#{libName}_%s_compare_single(__#{libName}_%s *ptr1, __#{libName}_%s *ptr2 ) {\n", entry.name, entry.name, entry.name)
                    end

                    output.printf("#{offset}if (ptr1 == ptr2) {\n")
                    output.printf("#{offset}\treturn 1;\n#{offset}}\n")
                    
                    # If only one is null
                    output.printf("#{offset}if (((ptr1 != 0) && (ptr2 == 0)) || ((ptr1 == 0) && (ptr2 != 0))) {\n")
                    output.printf("#{offset}\treturn 0;\n#{offset}}\n")

                    # In case of fields with quantity greater than 1, we
                    # must use a local variable for the 'for' loop but
                    # don't define it more than once.
                    loopVariableDefined = false

                    entry.fields.each() { |field|
                        if (field.comparable == true)
                            if field.target == :both then
                                case field.qty
                                    when :single
                                        case field.category
                                            when :intern
                                                output.printf("#{offset}if (!__#{libName}_%s_compare_single(ptr1->%s, ptr2->%s)) {\n", field.data_type, field.name, field.name)
                                                output.printf("#{offset}\treturn 0;\n#{offset}}\n")
                                            when :string
                                                output.printf("#{offset}if (ptr1->%s != ptr2->%s) {\n", field.name, field.name)
                                                output.printf("#{offset}\tif (((ptr1->%s == 0) && (ptr2->%s !=0)) || ((ptr1->%s != 0) && (ptr2->%s == 0))) {\n", field.name, field.name, field.name, field.name)
                                                output.printf("#{offset}\t\treturn 0;\n#{offset}\t}\n")
                                                output.printf("#{offset}\telse {\n")
                                                output.printf("#{offset}\t\tif (strcmp(ptr1->%s, ptr2->%s) != 0) {\n", field.name, field.name)
                                                output.printf("#{offset}\t\t\treturn 0;\n#{offset}\t\t}\n")
                                                output.printf("#{offset}\t}\n#{offset}}\n")
                                            when :simple, :enum, :id, :idref
                                                output.printf("#{offset}if (ptr1->%s != ptr2->%s) {\n", field.name, field.name)
                                                output.printf("#{offset}\treturn 0;\n#{offset}}\n")
                                            else
                                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                                        end
                                    when :list, :container
                                        case field.category
                                            when :intern
                                                output.printf("#{offset}if (!__#{libName}_%s_compare_list(ptr1->%s, ptr2->%s)) {\n", field.data_type, field.name, field.name)
                                                output.printf("#{offset}\treturn 0;\n#{offset}}\n")
                                            when :string
                                                output.printf("#{offset}if (ptr1->%sLen != ptr2->%sLen) {\n", field.name, field.name)
                                                output.printf("#{offset}\treturn 0;\n#{offset}}\n")
                                                if (!loopVariableDefined)
                                                    loopVariableDefined = true
                                                    output.printf("#{offset}unsigned i = 0;\n")
                                                end
                                                output.printf("#{offset}for (i = 0; i < ptr1->%sLen; ++i) {\n", field.name)
                                                output.printf("#{offset}\tif (ptr1->%s[i] != ptr2->%s[i]) {\n", field.name, field.name)
                                                output.printf("#{offset}\t\tif (((ptr1->%s[i] == 0) && (ptr2->%s[i] !=0)) || ((ptr1->%s != 0) && (ptr2->%s == 0))) {\n", field.name, field.name, field.name, field.name)
                                                output.printf("#{offset}\t\t\treturn 0;\n#{offset}\t\t}\n")
                                                output.printf("#{offset}\t\telse {\n")
                                                output.printf("#{offset}\t\t\tif (strcmp(ptr1->%s[i], ptr2->%s[i]) != 0) {\n", field.name, field.name)
                                                output.printf("#{offset}\t\t\t\treturn 0;\n#{offset}\t\t\t}\n")
                                                output.printf("#{offset}\t\t}\n#{offset}\t}\n")
                                                output.printf("#{offset}}\n")
                                            when :simple, :enum, :id, :idref
                                                output.printf("#{offset}if (ptr1->%sLen != ptr2->%sLen) {\n", field.name, field.name)
                                                output.printf("#{offset}\treturn 0;\n#{offset}}\n")
                                                if (!loopVariableDefined)
                                                    loopVariableDefined = true
                                                    output.printf("#{offset}unsigned i = 0;\n")
                                                end
                                                output.printf("#{offset}for (i = 0; i < ptr1->%sLen; ++i) {\n", field.name)
                                                output.printf("#{offset}\tif (ptr1->%s[i] != ptr2->%s[i]) {\n", field.name, field.name)
                                                output.printf("#{offset}\t\treturn 0;\n#{offset}\t}\n")
                                                output.printf("#{offset}}\n")
                                            else
                                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                                        end
                                    else 
                                        raise("Unsupported data quantity for #{entry.name}.#{field.name}");
                                end
                            end
                        end
                    }

                    # If we are not listable and didn't already
                    # returned, it means that elements were equal.
                    output.print("\treturn 1;\n")

                    output.print("}\n\n")


                    output.printf("int __#{libName}_%s_compare_list(__#{libName}_%s *ptr1, __#{libName}_%s *ptr2) {\n", 
                            entry.name, entry.name, entry.name)
 
                    offset = "\t"

                    if (entry.comparable == false)
                        output.printf("#{offset}return 1;\n}\n\n")
                        next
                    end
 
                    output.printf("#{offset}__#{libName}_%s *el1, *el2;\n", entry.name)
                    output.printf("#{offset}el1 = ptr1;\n")
                    output.printf("#{offset}el2 = ptr2;\n")
                    if (entry.attribute == :listable)
                        output.printf("#{offset}while (el1 && el2) {\n")
                        offset += "\t"
                    end
 
                    output.printf("#{offset}if (!__#{libName}_%s_compare_single(el1, el2)) {\n", entry.name)
                    output.printf("#{offset}\treturn 0;\n#{offset}}\n")

                    if (entry.attribute == :listable)
                        output.printf("#{offset}el1 = el1->next;\n")
                        output.printf("#{offset}el2 = el2->next;\n")
                        output.printf("\t}\n\n")

                        # We return true only if we reached the end of
                        # both lists and didn't already return 0.
                        output.print("\tif (!el1 && !el2) {\n\t\treturn 1;\n\t}\n\telse {\n\t\treturn 0;\n\t}\n")
                    else
                        # If we are not listable and didn't already
                        # returned, it means that elements were equal.
                        output.print("\treturn 1;\n")
                    end
                    output.print("}\n\n")
            }

            output.puts("
/** @} */
/** @} */
") 
            end

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_compare_h__\n")
                output.printf("#define __#{libName}_compare_h__\n\n")

                output.printf("/**\n * We define comparison functions even for elements which are not comparable.\n")
                output.printf(" * We need to define parameters as unused to remove warning but its needs\n")
                output.printf(" * a little trick to work correctly with doxygen.\n */\n")
                output.printf("#define __#{libName.upcase}_UNUSED__ __attribute__((unused))\n\n")

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup compare Comparison API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Compare two #__#{libName}_#{entry.name}, their siblings and children (if any).
 * @param[in] ptr1 Pointer to the first structure to compare
 * @param[in] ptr2 Pointer to the second structure to compare
 * @return int 1 if both structures are equal, 0 if not equal.
*/")

                    if (entry.comparable == false)
                        output.printf("int __#{libName}_%s_compare_list(__#{libName}_%s *ptr1 __#{libName.upcase}_UNUSED__, __#{libName}_%s *ptr2 __#{libName.upcase}_UNUSED__);\n", entry.name, entry.name, entry.name)
                        output.printf("\n")
                    else
                        output.printf("int __#{libName}_%s_compare_list(__#{libName}_%s *ptr1, __#{libName}_%s *ptr2);\n", entry.name, entry.name, entry.name)
                        output.printf("\n")
                    end

                    output.puts("
/**
 * Compare two #__#{libName}_#{entry.name} but not their siblings nor children.
 * @param[in] ptr1 Pointer to the first structure to compare
 * @param[in] ptr2 Pointer to the second structure to compare
 * @return int 1 if both structures are equal, 0 if not equal.
*/")
                    if (entry.comparable == false)
                        output.printf("int __#{libName}_%s_compare_single(__#{libName}_%s *ptr1 __#{libName.upcase}_UNUSED__, __#{libName}_%s *ptr2 __#{libName.upcase}_UNUSED__);\n", entry.name, entry.name, entry.name)
                        output.printf("\n")
                    else
                        output.printf("int __#{libName}_%s_compare_single(__#{libName}_%s *ptr1, __#{libName}_%s *ptr2);\n", entry.name, entry.name, entry.name)
                        output.printf("\n")
                    end
                }

                output.puts("
/** @} */
/** @} */
")
                output.printf("#endif /* __#{libName}_compare_h__ */\n")
            end
            module_function :genC, :genH
        end
    end
end
