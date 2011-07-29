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
        module BinaryReader

            def write(description)
                description.entries.each() {|name, entry|
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_reader__#{name}.c")
                    self.genBinaryReader(outputC, description, entry)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_reader_wrapper__#{name}.c")
                    self.genBinaryReaderWrapper(outputC, description, entry)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_reader_partial__#{name}.c")
                    self.genBinaryReaderPartial(outputC, description, entry)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_reader_wrapper_partial__#{name}.c")
                    self.genBinaryReaderWrapperPartial(outputC, description, entry)
                    outputC.close()
                }
                outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/",
                                                      "binary_reader.h")
                self.genBinaryReaderH(outputH, description)
                outputH.close()

            end
            module_function :write
            
            private
            def genBinaryReaderH(output, description)
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_binary_reader_h__")
                output.puts("#define __#{libName}_binary_reader_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_reader Binary Reader API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Internal: Read a partial #__#{libName}_#{entry.name} structure and its children in binary form from an open file.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] file Pointer to the FILE.
 * @param[in] offset Position of the beginning of the struct within the file.
 * @param[in] opt Pointer to the partial options that describes the structures to parse.
 * @return Pointer to a valid #__#{libName}_#{entry.name} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */");

                    output.puts "__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load_partial(FILE* file, uint32_t offset, __#{libName}_partial_options *opt);\n"
                    output.puts("
/**
 * Read a partial #__#{libName}_#{entry.name} structure and its children in binary form from a file
 * @param[in] file Filename
 * @param[in] opts Options to parser (compression, read-only, etc)
 * @param[in] partial_opts Pointer to the partial options that describes the structures to parse.
 * @return Pointer to a #__#{libName}_#{entry.name} structure
 * @retval NULL Failed to read the file
 * @retval !=NULL Valid structure
 */");
                    output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file_partial(const char* file, __#{libName}_options opts, __#{libName}_partial_options *partial_opts);\n", entry.name, entry.name)

                    output.puts("
/**
 * Internal: Read a complete #__#{libName}_#{entry.name} structure and its children in binary form from an open file.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] file Pointer to the FILE
 * @param[in] offset Position of the beginning of the struct within the file
 * @return Pointer to a valid #__#{libName}_#{entry.name} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */");

                    output.puts "__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load(FILE* file, uint32_t offset);\n"
                    output.puts("
/**
 * Read a complete #__#{libName}_#{entry.name} structure and its children in binary form from a file
 * @param[in] file Filename
 * @param[in] opts Options to parser (compression, read-only, etc)
 * @return Pointer to a #__#{libName}_#{entry.name} structure
 * @retval NULL Failed to read the file
 * @retval !=NULL Valid structure
 */");
                    output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file(const char* file, __#{libName}_options opts);\n\n", entry.name, entry.name)
                }
                output.printf("\n\n");

                output.puts("
/** @} */
/** @} */
")
                output.puts("#endif /* __#{libName}_binary_reader_h__ */\n")
            end
            module_function :genBinaryReaderH
            def genBinaryReaderPartial(output, description, entry)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("#include <stdint.h>\n")
                output.printf("#include <sys/stat.h>\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_reader Binary Reader API
 * @{
 **/
");

                output.puts"
__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load_partial(FILE* file, uint32_t offset, __#{libName}_partial_options *opt){
"
                
                output.printf("\t__#{libName}_%s *el;\n",entry.name)
                output.printf("\t__#{libName}_%s *prev = NULL, *first = NULL;\n",entry.name) if entry.attribute == :listable 

                output.printf("\tif(!opt->#{entry.name})\n");
                output.printf("\t\treturn NULL;\n\n");
               source="el"
                if entry.attribute == :listable then
                    output.printf "\tdo {\n"
                    indent="\t\t"
                else
                    indent="\t"
                end
                output.printf("#{indent}el = __#{libName}_#{entry.name}_alloc();\n\n")
                # Set next field if we have a predecessor
                output.printf("\t\tif(prev){\n\t\t\tprev->next = el;\n\t\t} else {\n\t\t\tfirst = el;\n\t\t}\n") if entry.attribute == :listable

                output.printf("#{indent}__#{libName}_fseek(file, offset, SEEK_SET);\n")
                output.printf("#{indent}__#{libName}_fread(el, sizeof(*el), 1, file);\n")

                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple, :enum
                        when :string
                            output.printf("#{indent}if(#{source}->%s){\n", field.name)
                            output.printf("#{indent}\tuint32_t len;\n")
                            output.printf("#{indent}\t__#{libName}_fseek(file, (unsigned long)#{source}->%s, SEEK_SET);\n", field.name)
                            output.printf("#{indent}\t__#{libName}_fread(&len, sizeof(len), 1, file);\n")
                            output.printf("#{indent}\t#{source}->%s = __#{libName}_malloc(len * sizeof(char));\n", field.name)
                            output.printf("#{indent}\t__#{libName}_fread(#{source}->%s, sizeof(char), len, file);\n", field.name)
                            output.printf("#{indent}}\n")
                        when :intern
                            output.printf("#{indent}if((opt->#{field.data_type} != 0) && (#{source}->%s != NULL)){\n", field.name)
                            output.printf("#{indent}\t#{source}->%s = __#{libName}_%s_binary_load(file, (uint32_t)(unsigned long)(#{source}->%s));\n", 
                                          field.name, field.data_type, field.name)
                            output.printf("#{indent}} else {\n#{indent}\t#{source}->#{field.name} = NULL;\n#{indent}}\n")
                        when :id, :idref
                            output.printf("#{indent}if(#{source}->%s_str){\n", field.name)
                            output.printf("#{indent}\tuint32_t len;\n")
                            output.printf("#{indent}\t__#{libName}_fseek(file, (unsigned long)#{source}->%s_str, SEEK_SET);\n", field.name)
                            output.printf("#{indent}\t__#{libName}_fread(&len, sizeof(len), 1, file);\n")
                            output.printf("#{indent}\t#{source}->%s_str = __#{libName}_malloc(len * sizeof(char));\n", field.name)
                            output.printf("#{indent}\t__#{libName}_fread(#{source}->%s_str, sizeof(char), len, file);\n", field.name)
                            output.printf("#{indent}}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                            
                        when :simple
                            output.printf("#{indent}if(#{source}->%s){\n", field.name)
                            # Alloc and read the array of data
                            output.printf("#{indent}\t%s* array = __#{libName}_malloc(#{source}->%sLen * sizeof(*array));\n", 
                                          field.data_type, field.name, field.data_type)
                            output.printf("#{indent}\t__#{libName}_fseek(file, (unsigned long)#{source}->%s, SEEK_SET);\n", field.name)
                            output.printf("#{indent}\t__#{libName}_fread(array, sizeof(*array), #{source}->%sLen, file);\n",
                                          field.name, field.name);
                            output.printf("#{indent}\t#{source}->%s = array;\n", field.name)              
                            output.printf("#{indent}}\n")
                        when :string
                            output.printf("#{indent}if(#{source}->%s){\n", field.name)
                            # Alloc and read the array of data
                            output.printf("#{indent}\tuint32_t *tmp_array = __#{libName}_malloc(#{source}->%sLen * sizeof(*tmp_array));\n", 
                                          field.name)
                            output.printf("#{indent}\t%s* array = __#{libName}_malloc(#{source}->%sLen * sizeof(*array));\n", 
                                          field.data_type, field.name)

                            output.printf("#{indent}\t__#{libName}_fseek(file, (unsigned long)#{source}->%s, SEEK_SET);\n", field.name)
                            output.printf("#{indent}\t__#{libName}_fread(tmp_array, sizeof(*tmp_array), #{source}->%sLen, file);\n",
                                          field.name, field.name);
                            output.printf("#{indent}\t#{source}->%s = array;\n", field.name)

                            # Read the string at each index
                            output.printf("#{indent}\tunsigned int i; for(i = 0; i < #{source}->%sLen; i++){\n", 
                                          field.name);

                            output.printf("#{indent}\t\tif(tmp_array[i]){\n", field.name);
                            output.printf("#{indent}\t\t\t__#{libName}_fseek(file, (unsigned long)tmp_array[i], SEEK_SET);\n")
                            output.printf("#{indent}\t\t\tuint32_t len;\n")
                            # get the string size
                            output.printf("#{indent}\t\t\t__#{libName}_fread(&len, sizeof(len), 1, file);\n")
                            # Alloc it and read it
                            output.printf("#{indent}\t\t\tarray[i] = __#{libName}_malloc(sizeof(char) * len);\n")
                            output.printf("#{indent}\t\t\t__#{libName}_fread(array[i], sizeof(char), len, file);\n", field.name)
                            output.printf("#{indent}\t\t}\n")
                            output.printf("#{indent}\t}\n");    
                            output.printf("#{indent}free(tmp_array);\n");
                            output.printf("#{indent}}\n")
                        when :intern
                            output.printf("#{indent}if((opt->#{field.data_type} != 0) && (#{source}->%s != NULL)){\n", field.name)
                            output.printf("#{indent}\t#{source}->%s = __#{libName}_%s_binary_load(file, (uint32_t)(unsigned long)(#{source}->%s));\n", 
                                          field.name, field.data_type, field.name)
                            output.printf("#{indent}} else {\n#{indent}\t#{source}->#{field.name} = NULL;\n#{indent}}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    end
                }
                # Autosort generation
                entry.sort.each() {|field|
                    output.printf("\t__#{libName}_#{entry.name}_sort_#{field.name}(#{source});\n")
                }
                
                if entry.attribute == :listable  then
                    
                    output.printf("#{indent}prev = el;\n") 
                    output.printf("#{indent}offset = (uint32_t)(unsigned long)el->next;\n");
                    output.printf("\t} while (el->next != NULL);\n") 
                    output.printf("\t#{entry.cleanup}(first);\n") if entry.cleanup != nil 

                    output.puts "\treturn first;"
                else
                    output.printf("\t#{entry.cleanup}(el);\n") if entry.cleanup != nil 
                    output.puts "\treturn el;"
                end

                output.puts "}"

                output.puts("
/** @} */
/** @} */
")


            end
            module_function :genBinaryReaderPartial

            def genBinaryReader(output, description, entry)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("#include <stdint.h>\n")
                output.printf("#include <sys/stat.h>\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_reader Binary Reader API
 * @{
 **/
");
                output.puts "__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load(FILE* file, uint32_t offset){\n"
                output.printf("\t__#{libName}_partial_options opt;\n")
                output.printf("\n")

                output.printf("\t__#{libName}_partial_options_parse_#{entry.name}(&opt);\n");
                output.printf("\treturn __#{libName}_#{entry.name}_binary_load_partial(file, offset, &opt);\n")
                output.printf("}\n");

                output.puts("
/** @} */
/** @} */
")
            end
            module_function :genBinaryReader

            def genBinaryReaderWrapperPartial(output, description, entry)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("#include <stdint.h>\n")
                output.printf("#include <sys/stat.h>\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_reader Binary Reader API
 * @{
 **/
");

                output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file_partial(const char* file, __#{libName}_options opts, __#{libName}_partial_options *partial_opts)\n{\n", entry.name, entry.name)
                output.printf("\tint ret;\n")
                output.printf("\t__#{libName}_%s *ptr = NULL;\n", entry.name);
                output.printf("\tFILE* output;\n")
                output.printf("\t__#{libName}_binary_header header;\n")
                output.printf("\tstruct stat fStat;\n")
                output.printf("\n")

                output.printf("\tret = setjmp(__#{libName}_error_happened);\n");
                output.printf("\tif (ret != 0) {\n");
                output.printf("\t\tif (ptr != NULL)\n");
                output.printf("\t\t\t__#{libName}_%s_free(ptr);\n", entry.name);
                output.printf("\t\terrno = ret;\n");
                output.printf("\t\treturn NULL;\n");
                output.printf("\t}\n\n");
                
                output.printf("\tif(__#{libName}_acquire_flock(file, opts & __#{libName.upcase}_OPTION_READONLY))\n");
                output.printf("\t\t__#{libName}_error(\"Failed to lock output file %%s: %%s\", ENOENT, file, strerror(errno));\n");
                output.printf("\tif((output = fopen(file, \"r\")) == NULL)\n");
                output.printf("\t\t__#{libName}_error(\"Failed to open input file %%s\", errno, file);\n\n");

                output.printf("\t\t__#{libName}_fread(&header, sizeof(header), 1, output);\n")
                output.printf("\t\tif(header.version != #{description.config.version})\n")
                output.printf("\t\t__#{libName}_error(\"Version from file %%s is incompatible.\", EACCES, file);\n\n");

                output.printf("\t\tret = fstat(fileno(output), &fStat);\n")
                output.printf("\t\tif(ret != 0){\n")
                output.printf("\t\t\t__#{libName}_error(\"Failed to read from DB.\", errno);\n")
                output.printf("\t\t}\n")
                output.printf("\t\tif(header.length != fStat.st_size)\n")
                output.printf("\t\t__#{libName}_error(\"DB file %%s is corrupted: size does not match header.\", EIO, file);\n\n");

                output.printf("\tptr = __#{libName}_%s_binary_load_partial(output, sizeof(header), partial_opts);\n", entry.name)
                output.printf("\tfclose(output);\n")
                output.printf("\tif (opts & __#{libName.upcase}_OPTION_READONLY ) {\n");
                output.printf("\t__#{libName}_release_flock(file);\n");
                output.printf("\t}\n");

                output.printf("\treturn ptr;\n");
                output.printf("}\n");

                output.puts("
/** @} */
/** @} */
")


            end
            module_function :genBinaryReaderWrapperPartial

            def genBinaryReaderWrapper(output, description, entry)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("#include <stdint.h>\n")
                output.printf("#include <sys/stat.h>\n")
                output.printf("\n\n") 

                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup binary_reader Binary Reader API
 * @{
 **/
");

                output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file(const char* file, __#{libName}_options opts)\n{\n", entry.name, entry.name)
              output.printf("\t__#{libName}_partial_options opt;\n")
                output.printf("\n")

                output.printf("\t__#{libName}_partial_options_parse_#{entry.name}(&opt);\n");
                output.printf("\treturn __#{libName}_#{entry.name}_binary_load_file_partial(file, opts, &opt);\n")
                output.printf("}\n");
                output.puts("
/** @} */
/** @} */
")


            end
            module_function :genBinaryReaderWrapper
        end
    end
end
