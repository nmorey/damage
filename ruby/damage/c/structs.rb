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
        module Structs

            @OUTFILE = "structs.h"
            def write(description)
                
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE)
                genH(output, description)
                output.close()
            end
            module_function :write
            

            private

            def genStruct(output, libName, entry)

                output.printf("/** Structure __#{libName}_%s: #{entry.description} */\n", entry.name)
                output.printf("typedef struct ___#{libName}_%s {\n", entry.name);
                entry.fields.each() {|field|
                    case field.attribute
                    when :sort
                        output.printf("\t/** Sorted array (index) of \"#{field.sort_field}\" by #{field.sort_key} (not necessary dense) */\n")
                        output.printf("\tstruct ___#{libName}_%s** s_%s __#{libName.upcase}_ALIGN__;\n", field.data_type, field.name)
                        output.printf("\t/** Length of the s_%s array */\n", field.name)
                        output.printf("\tunsigned long n_%s __#{libName.upcase}_ALIGN__;\n", field.name)
                    when :pass
                        # Do NADA
                    when :meta,:container,:none
                        case field.category
                        when :simple, :enum, :string
                            case field.qty
                            when :single
                                output.printf("\t/** #{field.description} */\n") if field.description != nil
                                output.printf("\t/** Field is an enum of type #__#{libName.upcase}_#{entry.name.upcase}_#{field.name.upcase} #{field.enumList}*/\n") if field.category == :enum
                                output.printf("\t%s %s __#{libName.upcase}_ALIGN__;\n", field.data_type, field.name)
                            when :list
                                output.printf("\t/** Array of elements #{field.description} */\n")
                                output.printf("\t%s* %s __#{libName.upcase}_ALIGN__;\n", field.data_type, field.name)
                                output.printf("\t/** Number of elements in the %s array */\n", field.name)
                                output.printf("\tunsigned long %sLen __#{libName.upcase}_ALIGN__;\n", field.name)
                            end
                        when :intern
                            output.printf("\t/** #{field.description} */\n") if field.description != nil
                            output.printf("\tstruct ___#{libName}_%s* %s __#{libName.upcase}_ALIGN__;\n", field.data_type, field.name)
                        when :id, :idref
                            output.printf("\t/** Field ID: #{field.description} */\n")
                            output.printf("\tchar* %s_str; __#{libName.upcase}_ALIGN__\n", field.name)
                            output.printf("\t/** Field ID as string */\n")
                            output.printf("\tunsigned long %s; __#{libName.upcase}_ALIGN__\n", field.name)
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    end

                }       
                if entry.attribute == :listable then
                    output.printf("\t/** Pointer to the next element in the list */\n")
                    output.printf("\tstruct ___#{libName}_%s* next  __#{libName.upcase}_ALIGN__;\n", entry.name) 
                end
                output.printf("\t/** Internal: Pointer to the ruby VALUE when using the ruby wrapper  */\n")
                output.printf("\tvoid* _private  __#{libName.upcase}_ALIGN__;\n");
                output.printf("\t/** Internal: Offset in the binary DB */\n")
                output.printf("\tunsigned long _rowip_pos  __#{libName.upcase}_ALIGN__;\n");
                output.printf("\t/** Internal: DB infos */\n")
                output.printf("\tvoid* _rowip  __#{libName.upcase}_ALIGN__;\n");
                output.printf("} __#{libName}_%s;\n\n", entry.name);

            end
            module_function :genStruct

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_structs_h__\n");
                output.printf("#define __#{libName}_structs_h__\n\n");
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup structs Structure definitions
 * @{
 **/
");
                output.puts("/** We need to force alignment to ptr%8 to avoid compatibility problem for binary format between x86 and x86_64*/");
                output.printf("#define __#{libName.upcase}_ALIGN__ __attribute__((aligned(8)))\n\n");
                
                description.entries.each() {|name, entry|
                    genStruct(output, libName, entry)

                }
                output.printf("\n\n");
                output.printf("/** Internal structure for ROWIP maintenant */\n");
                output.printf("typedef struct ___#{libName}_rowip_header {\n");
                output.printf("\t/** Source filename */\n");
                output.printf("\tchar* filename;\n");
                output.printf("\t/** Source file length */\n");
                output.printf("\tunsigned long len;\n");
                output.printf("\t/** Source FILE* */\n");
                output.printf("\tFILE* file;\n");
                output.printf("\t/** Base memory address */\n");
                output.printf("\tvoid* base_adr;\n");
                output.printf("} __#{libName}_rowip_header;\n\n");
                output.puts("
/** @} */
/** @} */
")
                output.printf("#endif /* __#{libName}_structs_h__ */\n");
            end
            module_function :genH
        end
    end
end
