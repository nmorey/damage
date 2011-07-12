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
        module BinaryWriter

            def write(description)
                outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "binary_writer.c")
                self.genBinaryWriter(outputC, description)
                outputC.close()

                outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/", "binary_writer.h")
                self.genBinaryWriterH(outputH, description)
                outputH.close()

            end
            module_function :write
            
            private

            def genBinaryWriterH(output, description)
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_binary_writer_h__")
                output.puts("#define __#{libName}_binary_writer_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_writer Binary Writer API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Internal: Write a complete #__#{libName}_#{entry.name} structure and its children in binary form to an open file.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] ptr Structure to write
 * @param[in] file Pointer to the FILE
 * @param[in] offset Position of the beginning of the struct within the file
 * @return offset + number of bytes written
 */");
                    output.puts "uint32_t __#{libName}_#{entry.name}_binary_dump(__#{libName}_#{entry.name}* ptr, FILE* file, uint32_t offset);\n"
                    output.puts("
/**
 * Write a complete #__#{libName}_#{entry.name} structure and its children in binary form to a file
 * @param[in] file Filename
 * @param[in] ptr Structure to write
 * @param[in] opts Options to writer (compression, read-only, etc)
 * @return Amount of bytes wrote to file
 * @retval 0 in case of error
 */");
                    output.printf("unsigned long __#{libName}_%s_binary_dump_file(const char* file, __#{libName}_%s *ptr, __#{libName}_options opts);\n\n", entry.name, entry.name)

                }
                output.printf("\n\n");

                output.puts("
/** @} */
/** @} */
")
                output.puts("#endif /* __#{libName}_binary_writer_h__ */\n")
            end
            module_function :genBinaryWriterH
            def genBinaryWriter(output, description)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("#include <stdint.h>\n")
                output.printf("\n\n") 
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_writer Binary Writer API
 * @{
 **/
");

                description.entries.each() { |name, entry|
                    output.puts "
uint32_t __#{libName}_#{entry.name}_binary_dump(__#{libName}_#{entry.name}* ptr, 
                                                     FILE* file, uint32_t offset);\n"
                }
                output.printf("\n\n") 

                description.entries.each() { |name, entry|
                    output.puts"
uint32_t __#{libName}_#{entry.name}_binary_dump(__#{libName}_#{entry.name}* ptr, 
                                                     FILE* file, uint32_t offset){
"
                    output.printf("\tuint32_t child_offset = offset + sizeof(*ptr);\n")

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
                        next if field.target == :parser
                        if field.target == :mem
                            if field.attribute == :sort
                                output.printf("#{indent}val.s_%s = NULL;\n", field.name)
                                output.printf("#{indent}val.n_%s = 0;\n", field.name)
                            elsif field.attribute == :meta && field.category == :intern
                                output.printf("#{indent}val.%s = NULL;\n", field.name)
                            end
                            next
                        end
                        case field.qty
                        when :single
                            case field.category
                            when :simple, :enum
                            when :string
                                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                                output.printf("#{indent}\tuint32_t len = strlen(#{source}->%s) + 1;\n", field.name)
                                output.printf("#{indent}\tval.%s = (char*)(unsigned long) child_offset;\n", field.name)
                                output.printf("#{indent}\t__#{libName}_fseek(file, child_offset, SEEK_SET);\n")
                                output.printf("#{indent}\t__#{libName}_fwrite(&len, sizeof(len), 1, file);\n", field.name)
                                output.printf("#{indent}\t__#{libName}_fwrite(#{source}->%s, sizeof(char), len, file);\n", field.name)
                                output.printf("#{indent}\tchild_offset += len + sizeof(len);\n", field.name)
                                output.printf("#{indent}}\n")
                            when :intern
                                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                                output.printf("#{indent}\tval.%s = (__#{libName}_%s*)(unsigned long)child_offset;\n", field.name, field.name)
                                output.printf("#{indent}\tchild_offset = __#{libName}_%s_binary_dump(#{source}->%s, file, child_offset);\n", 
                                              field.data_type, field.name)
                                output.printf("#{indent}}\n")
                            when :id, :idref
                                output.printf("#{indent}if(#{source}->%s_str){\n", field.name)
                                output.printf("#{indent}\tuint32_t len = strlen(#{source}->%s_str) + 1;\n", field.name)
                                output.printf("#{indent}\tval.%s_str = (char*) (unsigned long)child_offset;\n", field.name)
                                output.printf("#{indent}\t__#{libName}_fseek(file, child_offset, SEEK_SET);\n")
                                output.printf("#{indent}\t__#{libName}_fwrite(&len, sizeof(len), 1, file);\n", field.name)
                                output.printf("#{indent}\tif(len > 0)\n");
                                output.printf("#{indent}\t__#{libName}_fwrite(#{source}->%s_str, sizeof(char), len, file);\n", field.name)
                                output.printf("#{indent}\tchild_offset += len + sizeof(len);\n", field.name)
                                output.printf("#{indent}}\n")
                                output.printf("#{indent}\t__#{libName}_fseek(file, child_offset, SEEK_SET);\n")
                                output.printf("#{indent}\t__#{libName}_fwrite(&#{source}->%s, sizeof(unsigned long), 1, file);\n", field.name)
                                output.printf("#{indent}\tchild_offset += sizeof(unsigned long);\n", field.name)
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                            end
                        when :list, :container
                            case field.category
                            when :simple
                                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                                output.printf("#{indent}\tval.%s = (void*)(unsigned long)child_offset;\n", field.name)
                                output.printf("#{indent}\t__#{libName}_fwrite(#{source}->%s, sizeof(*#{source}->%s), #{source}->%sLen, file);\n",
                                              field.name, field.name, field.name);
                                output.printf("#{indent}\tchild_offset += (sizeof(*#{source}->%s) * #{source}->%sLen);\n",
                                              field.name, field.name)
                                output.printf("#{indent}}\n")
                            when :string
                                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                                output.printf("#{indent}\t__#{libName}_fseek(file, child_offset, SEEK_SET);\n")
                                output.printf("#{indent}\tuint32_t *tmp_array = __#{libName}_malloc(#{source}->%sLen * sizeof(*tmp_array));\n", field.name)
                                output.printf("#{indent}\tunsigned int i; for(i = 0; i < #{source}->%sLen; i++){\n", 
                                              field.name);
                                output.printf("#{indent}\t\tif(#{source}->%s[i]){\n", field.name);
                                output.printf("#{indent}\t\t\tuint32_t len = strlen(#{source}->%s[i]) + 1;\n", field.name)
                                output.printf("#{indent}\t\t\ttmp_array[i] = child_offset;\n")
                                output.printf("#{indent}\t\t\t__#{libName}_fwrite(&len, sizeof(len), 1, file);\n", field.name)
                                output.printf("#{indent}\t\t\t__#{libName}_fwrite(#{source}->%s[i], sizeof(char), len, file);\n", field.name)
                                output.printf("#{indent}\t\t\tchild_offset += len + sizeof(len);\n", field.name)
                                output.printf("#{indent}\t\t}\n")
                                output.printf("#{indent}\t}\n\n");
                                
                                output.printf("#{indent}\tval.%s = (char**)(unsigned long)child_offset;\n", field.name)
                                output.printf("#{indent}\t__#{libName}_fwrite(tmp_array, sizeof(*tmp_array), #{source}->%sLen, file);\n",
                                              field.name, field.name);
                                output.printf("#{indent}\tchild_offset += (sizeof(*#{source}->%s) * #{source}->%sLen);\n",
                                              field.name, field.name)
                                output.printf("#{indent}\t__#{libName}_free(tmp_array);\n")

                                output.printf("#{indent}}\n")

                            when :intern
                                output.printf("#{indent}if(#{source}->%s){\n", field.name)
                                output.printf("#{indent}\tval.%s = (void*)(unsigned long)child_offset;\n", field.name)
                                output.printf("#{indent}\tchild_offset = __#{libName}_%s_binary_dump(#{source}->%s, file, child_offset);\n", 
                                              field.data_type, field.name)
                                output.printf("#{indent}}\n")
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                            end
                        end
                    }

                    
                    output.printf("#{indent}if(el->next != NULL) {val.next = (void*)(unsigned long)child_offset;}\n") if entry.attribute == :listable 
                    if description.config.rowip == true
                        output.printf("#{indent}val._rowip_pos = offset;\n")
                        output.printf("#{indent}val._rowip = NULL;\n")
                    end
                    output.printf("#{indent}val._private = NULL;\n")


                    output.printf("#{indent}__#{libName}_fseek(file, offset, SEEK_SET);\n")
                    output.printf("#{indent}__#{libName}_fwrite(&val, sizeof(val), 1, file);\n")

                    if entry.attribute == :listable  then
                        output.printf("#{indent}if(el->next != NULL){\n")
                        output.printf("#{indent}\toffset = child_offset;\n") 
                        output.printf("#{indent}\tchild_offset += sizeof(*ptr);\n") 
                        output.printf("#{indent}};\n") 
                        output.printf("\t}\n") 
                    end

                    output.puts "\treturn child_offset;"
                    output.puts "}"
                }

                description.entries.each() { | name, entry|
                    output.printf("unsigned long __#{libName}_%s_binary_dump_file(const char* file, __#{libName}_%s *ptr, __#{libName}_options opts)\n{\n", entry.name, entry.name)
                    output.printf("\tuint32_t ret;\n")
                    output.printf("\tFILE* output;\n")
                    output.printf("\n")

                    output.printf("\tret = setjmp(__#{libName}_error_happened);\n");
                    output.printf("\tif (ret != 0) {\n");
                    output.printf("\t\terrno = ret;\n");
                    output.printf("\t\treturn 0UL;\n");
                    output.printf("\t}\n\n");

                    output.printf("\tif(__#{libName}_acquire_flock(file, 1))\n");
                    output.printf("\t\t__#{libName}_error(\"Failed to lock output file %%s: %%s\", ENOENT, file, strerror(errno));\n");

                    output.printf("\tif((output = fopen(file, \"w+\")) == NULL)\n");
                    output.printf("\t\t__#{libName}_error(\"Failed to open output file %%s\", errno, file);\n");

                    output.printf("\tret = __#{libName}_%s_binary_dump(ptr, output, sizeof(uint32_t));\n", entry.name)
                    output.printf("\t__#{libName}_fseek(output, 0, SEEK_SET);\n")
                    output.printf("\t__#{libName}_fwrite(&ret, sizeof(ret), 1, output);\n");
                    output.printf("\tfclose(output);\n")
                    output.printf("\tif(opts & __#{libName.upcase}_OPTION_UNLOCKED)\n");
                    output.printf("\t\t__#{libName}_release_flock(file);\n");
                    output.printf("\treturn (unsigned long)ret;\n");
                    output.printf("}\n");
                }
                output.puts("
/** @} */
/** @} */
")
                
            end
            module_function :genBinaryWriter

        end
    end
end
