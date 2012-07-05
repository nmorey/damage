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

            def genStruct(output, libName, entry, rowip)
                nextPart=""
                postPart=""
                output.printf("/** Structure __#{libName}_%s: #{entry.description} */\n", entry.name)
                output.printf("typedef struct ___#{libName}_%s {\n", entry.name);
                entry.fields.each() {|field|
                    case field.attribute
                    when :sort
                        nextPart += "\t/** Sorted array (index) of \"#{field.sort_field}\" by #{field.sort_key} (not necessary dense) */\n"
                        nextPart += "\tstruct ___#{libName}_#{field.data_type}** s_#{field.name} __#{libName.upcase}_ALIGN__;\n"
                        output.printf("\t/** Length of the s_#{field.name} array */\n")
                        output.printf("\tuint32_t n_%s;\n", field.name)
                    when :meta,:container,:none
                        case field.category
                        when :simple, :enum, :genum
                            case field.qty
                            when :single
                                output.printf("\t/** #{field.description} */\n") if field.description != nil
                                output.printf("\t/** Field is an enum of type #__#{libName}_#{entry.name}_#{field.name} #{field.enumList}*/\n") if field.category == :enum
                                if field.data_type == "unsigned long" || field.data_type == "signed long" then
                                    output.printf("\t%s %s __#{libName.upcase}_ALIGN__;\n", field.data_type, field.name)
                                    output.printf("#if __WORDSIZE == 32\n");
                                    output.printf("\t/** Padding field for #{field.name} as long have different size on different arch */\n")
                                    output.printf("\tunsigned int __padding#{field.name};\n")
                                    output.printf("#endif /* __WORDSIZE == 32 */ \n");

                                elsif field.data_type == "double" || field.data_type == "unsigned long long" || 
                                        field.data_type == "signed long long"
                                    output.printf("\t%s %s __#{libName.upcase}_ALIGN__;\n", field.data_type, field.name)
                                else
                                    output.printf("\t%s %s;\n", field.data_type, field.name)
                                end
                            when :list
                                nextPart += "\t/** Array of elements #{field.description} */\n"
                                nextPart += "\t#{field.data_type}* #{field.name} __#{libName.upcase}_ALIGN__;\n"
                                output.printf("\t/** Number of elements in the %s array */\n", field.name)
                                output.printf("\tuint32_t %sLen ;\n", field.name)
                            end
                        when :string
                           case field.qty
                            when :single
                               nextPart += "\t/** #{field.description} */\n" if field.description != nil
                               nextPart += "\t#{field.data_type} #{field.name} __#{libName.upcase}_ALIGN__;\n"
                            when :list
                               nextPart += "\t/** Array of elements #{field.description} */\n"
                               nextPart += "\t#{field.data_type}* #{field.name} __#{libName.upcase}_ALIGN__;\n"
                               output.printf("\t/** Number of elements in the #{field.name} array */\n")
                               output.printf("\tuint32_t #{field.name}Len;\n")
                           end
                        when :intern
                               postPart += "\t/** #{field.description} */\n" if field.description != nil
                               postPart += "\tstruct ___#{libName}_#{field.data_type}* #{field.name} __#{libName.upcase}_ALIGN__;\n"
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
                output.puts nextPart
                output.puts postPart

                if entry.attribute == :listable then
                    output.printf("\t/** Pointer to the next element in the list */\n")
                    output.printf("\tstruct ___#{libName}_%s* next  __#{libName.upcase}_ALIGN__;\n", entry.name) 
                end
                output.printf("\t/** Internal: Pointer to the ruby VALUE when using the ruby wrapper  */\n")
                output.printf("\tvoid* _private  __#{libName.upcase}_ALIGN__;\n");
                output.printf("\t/** Internal: Offset in the binary DB */\n")
                output.printf("\tunsigned long _rowip_pos  __#{libName.upcase}_ALIGN__;\n");

                if rowip == true
                    output.printf("\t/** Internal: DB infos */\n")
                    output.printf("\tvoid* _rowip  __#{libName.upcase}_ALIGN__;\n");
                end
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
                    genStruct(output, libName, entry, description.config.rowip)

                }
                output.printf("\n\n");
                if description.config.rowip == true
                    output.printf("/** Internal structure for ROWIP maintenant */\n");
                    output.printf("typedef struct ___#{libName}_rowip_header {\n");
                    output.printf("\t/** Source filename */\n");
                    output.printf("\tchar* filename;\n");
                    output.printf("\t/** Source file length */\n");
                    output.printf("\tunsigned long len;\n");
                    output.printf("\t/** Source file descriptor */\n");
                    output.printf("\tint file;\n");
                    output.printf("\t/** Base memory address */\n");
                    output.printf("\tvoid* base_adr;\n");
                    output.printf("} __#{libName}_rowip_header;\n\n");
                end

                output.printf("/** Internal structure for DB info */\n");
                output.printf("typedef struct ___#{libName}_binary_header {\n");
                output.printf("\t/** DB Version */\n");
                output.printf("\tuint32_t version;\n");
                output.printf("\t/** File Length */\n");
                output.printf("\tint32_t length;\n");
                output.printf("\t/** Damage Version */\n");
                output.printf("\tchar damage_version[41];\n");
                output.printf("} __#{libName}_binary_header;\n\n");

                output.printf("
/** Option for reader and writer*/
typedef enum {
\t__#{libName.upcase}_OPTION_NONE = 0x0,
\t__#{libName.upcase}_OPTION_READONLY = 0x1,
\t__#{libName.upcase}_OPTION_KEEPLOCKED = 0x2,
\t__#{libName.upcase}_OPTION_GZIPPED = 0x4,
\t__#{libName.upcase}_OPTION_NO_SIBLINGS = 0x8
} __#{libName}_options;
");
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
