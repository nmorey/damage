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
        module ParserOptions
            
            @OUTFILE_H = "parser_options.h"

            def write(description)
                outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE_H)

                self.genH(outputH, description)
                outputH.close()
                
                description.entries.each() { |name, entry|
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "parser_options__#{name}.c")
                    self.genC(outputC, description, entry)
                    outputC.close()
                }

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
/** \\addtogroup #{libName}_alloc Allocation API
 * @{
 **/
");
                output.printf("void __#{libName}_partial_options_parse_%s(__#{libName}_partial_options *opt){\n", entry.name)

                output.printf("\topt->#{entry.name} = 1;\n\n")

                entry.fields.each() { |field|
                    next if field.target != :both
                    next if field.category != :intern
                    output.printf("\t__#{libName}_partial_options_parse_#{field.data_type}(opt);\n");
                }

                output.printf("\treturn;\n")
                output.printf("}\n\n")

                output.puts("
/** @} */
/** @} */
") 
            end

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_parser_options_h__\n")
                output.printf("#define __#{libName}_parser_options_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup #{libName}_parser_options Configuration API for partial binary reader
 * @{
 **/
");

                output.puts("
/** Partial binary parser configuration structure */
typedef struct ___#{libName}_partial_options {
\t/** Internal: Means full parsing so no need to seek */
\t char _all;
")
                description.entries.each() {|name, entry|
                    output.puts("
\t/** Parse the #{entry.name} structures */
\tchar #{entry.name};")
                }
                output.puts("} __#{libName}_partial_options;")
                output.printf("/** Initializer to set a partial option to 0 */\n")
                output.printf("#define __#{libName.upcase}_PARTIAL_OPTIONS_INITIALIZER \\\n { 0")
                
                description.entries.each() {|name, entry|
                    output.printf(", 0")
                }
                output.puts "}"

                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Configure partial options to parse #__#{libName}_#{entry.name} structs and their children
 * @param[in] opt Pointer to the partial options to configure.
 * @return Nothing.
*/")
                    output.printf("void __#{libName}_partial_options_parse_%s(__#{libName}_partial_options *opt);\n", entry.name)
                    output.printf("\n")
                }

                output.puts("
/** @} */
/** @} */
")
                output.printf("#endif /* __#{libName}_parser_options_h__ */\n")
            end
            module_function :genC, :genH
        end
    end
end
