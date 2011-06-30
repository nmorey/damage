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
        module Enum

            @OUTFILE = "enum.h"
            @OUTFILE_C = "enum.c"
            def write(description)
                
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE)
                genH(output, description)
                output.close()

                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", @OUTFILE_C)
                genC(output, description)
                output.close()
            end
            module_function :write
            

            private

            def genEnum(output, libName, entry)


                entry.fields.each() {|field|
                    if field.category == :enum then
                        enumPrefix="__#{libName.upcase}_#{entry.name.upcase}_#{field.name.upcase}"
                        output.puts("
/** Enum for the #{field.name} field of a #__#{libName}_#{entry.name} structure */");
                        output.printf("typedef enum {\n");
                        output.printf("\t#{enumPrefix}_N_A /** Undefined */= 0")
                        count = 1;
                        field.enum.each() { |str, val|
                            output.printf(",\n\t#{enumPrefix}_#{val} /** #{field.name} = \"#{str}\"*/ = #{count}")
                            count+=1
                        }
                        output.printf("\n} #{enumPrefix};\n");
output.puts("
/** Array containing the string for each enum entry */");
                        output.printf("extern const char*__#{libName}_#{entry.name}_#{field.name}_strings[#{field.enum.length+1}];\n\n");
                    end

                }       

            end
            module_function :genEnum

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_enum_h__\n");
                output.printf("#define __#{libName}_enum_h__\n");
                
  output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup enum Enum definitions
 * @{
 **/
");

              description.entries.each() {|name, entry|
                    genEnum(output, libName, entry)

                }
                output.printf("\n\n");
 
output.puts("
/** @} */
/** @} */
")
               output.printf("#endif /* __#{libName}_enu_h__ */\n");
            end
            module_function :genH

            def genC(output, description)
                libName = description.config.libname

                output.printf("#include <sigmacDB.h>\n");

                
                description.entries.each() {|name, entry|
                    entry.fields.each() {|field|
                        if field.category == :enum then
                            output.printf("const char*__#{libName}_#{entry.name}_#{field.name}_strings[#{field.enum.length+1}] = {\n");
                            output.printf("\t\"N/A\"")
                            field.enum.each() { |str, val|
                                output.printf(",\n\t\"#{str}\"")
                            } 
                            output.printf("\n};\n");
                        end

                    }       

                }
                output.printf("\n\n");
            end
            module_function :genC
        end
    end
end
