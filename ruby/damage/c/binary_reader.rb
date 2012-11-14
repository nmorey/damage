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
                    self.genBinaryReader(outputC, description, entry, false)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_reader_gz__#{name}.c")
                    self.genBinaryReader(outputC, description, entry, true)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", 
                                                          "binary_reader_wrapper__#{name}.c")
                    self.genBinaryReaderWrapper(outputC, description, entry)
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
 * Internal: Read a partial #__#{libName}_#{entry.name} structure and its children in binary form from an open GZ file .
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] file Pointer to the gzipped file
 * @param[in] offset Position of the beginning of the struct within the file.
 * @param[in] opt Pointer to the partial options that describes the structures to parse.
 * @return Pointer to a valid #__#{libName}_#{entry.name} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */");

                    output.puts "__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load_partial_gz(gzFile, uint32_t offset, __#{libName}_partial_options *opt);\n"

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
 * Internal: Read a complete #__#{libName}_#{entry.name} structure and its children in binary form from an open GZ file.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] file Pointer to the gzipped file
 * @param[in] offset Position of the beginning of the struct within the file
 * @return Pointer to a valid #__#{libName}_#{entry.name} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */");

                    output.puts "__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load_gz(gzFile file, uint32_t offset);\n"

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

            def cRead(output, libName, zipped, indent, dest, size, qty, file)
                if zipped == true
                    output.printf("#{indent}__#{libName}_gzread(#{file}, #{dest}, #{size} * #{qty});\n")
                else
                    output.printf("#{indent}__#{libName}_fread(#{dest}, #{size}, #{qty}, #{file});\n")
                end
            end
            module_function :cRead

            def genBinaryReader(output, description, entry, zipped)
                libName = description.config.libname
                fExt= (zipped == true) ? "_gz" : ""

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
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
                if zipped == true
                    output.puts"
__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load_partial_gz(gzFile file, uint32_t offset, __#{libName}_partial_options *opt){
"
                else
                    output.puts"
__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load_partial(FILE* file, uint32_t offset, __#{libName}_partial_options *opt){
"
                end
                
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

                output.printf("#{indent}if(opt->_all != 1)\n")
                if zipped == true
                    output.printf("#{indent}\t__#{libName}_gzseek(file, offset, SEEK_SET);\n")
                else
                    output.printf("#{indent}\t__#{libName}_fseek(file, offset, SEEK_SET);\n")
                end
                cRead(output, libName, zipped, indent, "el", "sizeof(*el)", "1", "file")

                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple, :enum, :genum
                        when :string
                            output.printf("#{indent}if(#{source}->%s){\n", field.name)
                            output.printf("#{indent}\tuint32_t len;\n")
                            cRead(output, libName, zipped, "#{indent}\t", "&len", "sizeof(len)", "1", "file")

                            output.printf("#{indent}\tif(len > 0) {\n")
                            output.printf("#{indent}\t\t#{source}->%s = __#{libName}_malloc(len * sizeof(char));\n", field.name)
                            cRead(output, libName, zipped, "#{indent}\t", "#{source}->#{field.name}", "sizeof(char)", "len", "file")
                            output.printf("#{indent}\t} else {\n")
                            output.printf("#{indent}\t\t#{source}->%s = NULL;\n", field.name)
                            output.printf("#{indent}\t} \n")

                            output.printf("#{indent}} else {\n")
                            output.printf("#{indent}\tuint32_t len;\n")
                            cRead(output, libName, zipped, "#{indent}\t", "&len", "sizeof(len)", "1", "file")
                            output.printf("#{indent}}\n")
                        when :intern
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                            
                        when :simple
                            output.printf("#{indent}if(#{source}->%s){\n", field.name)
                            # Alloc and read the array of data
                            output.printf("#{indent}\tif(#{source}->#{field.name}Len){\n")
                            output.printf("#{indent}\t\t%s* array = __#{libName}_malloc(#{source}->%sLen * sizeof(*array));\n", 
                                          field.data_type, field.name, field.data_type)
                            cRead(output, libName, zipped, "#{indent}\t\t", "array", "sizeof(*array)",
                                  "#{source}->#{field.name}Len", "file")

                            output.printf("#{indent}\t\t#{source}->%s = array;\n", field.name)              
                            output.printf("#{indent}\t} else {\n")
                            output.printf("#{indent}\t\t#{source}->%s = NULL;\n", field.name)
                            output.printf("#{indent}\t}\n")
                            output.printf("#{indent}}\n")
                        when :string
                            output.printf("#{indent}if(#{source}->%s){\n", field.name)
                            output.printf("#{indent}\tif(#{source}->#{field.name}Len){\n")

                            output.printf("#{indent}\t\tuint32_t len;\n")
                            # Alloc and read the array of data
                            output.printf("#{indent}\t\t%s* array = __#{libName}_malloc(#{source}->%sLen * sizeof(*array));\n", 
                                          field.data_type, field.name)

                            output.printf("#{indent}\t\t#{source}->%s = array;\n", field.name)

                            # Read the string at each index
                            output.printf("#{indent}\t\tunsigned int i;\n")
                            output.printf("#{indent}\t\t\tfor(i = 0; i < #{source}->%sLen; i++){\n", 
                                          field.name);

                            # get the string size
                            cRead(output, libName, zipped, "#{indent}\t\t\t", "&len", "sizeof(len)", "1", "file")
                            # Alloc it and read it
                            output.printf("#{indent}\t\t\tif(len > 0) {\n");
                            output.printf("#{indent}\t\t\t\tarray[i] = __#{libName}_malloc(sizeof(char) * len);\n")
                            cRead(output, libName, zipped, "#{indent}\t\t\t\t", "array[i]", "sizeof(char)", "len", "file")
                            output.printf("#{indent}\t\t\t} else {\n")
                            output.printf("#{indent}\t\t\t\tarray[i] = NULL;\n")
                            output.printf("#{indent}\t\t\t}\n")
                            output.printf("#{indent}\t\t}\n")
                            output.printf("#{indent}\t} else {\n")
                            output.printf("#{indent}\t\t#{source}->%s = NULL;\n", field.name)
                            output.printf("#{indent}\t}\n")

                            output.printf("#{indent}}\n")
                        when :intern
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    end
                }

                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple, :enum, :genum
                        when :string
                        when :intern
                            output.printf("#{indent}if((opt->#{field.data_type} != 0) && (#{source}->%s != NULL)){\n", field.name)
                            output.printf("#{indent}\t#{source}->%s = __#{libName}_%s_binary_load_partial#{fExt}(file, (uint32_t)(unsigned long)(#{source}->%s), opt);\n", 
                                          field.name, field.data_type, field.name)
                            output.printf("#{indent}} else {\n#{indent}\t#{source}->#{field.name} = NULL;\n#{indent}}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                            
                        when :simple
                        when :string
                        when :intern
                            output.printf("#{indent}if((opt->#{field.data_type} != 0) && (#{source}->%s != NULL)){\n", field.name)
                            output.printf("#{indent}\t#{source}->%s = __#{libName}_%s_binary_load_partial#{fExt}(file, (uint32_t)(unsigned long)(#{source}->%s), opt);\n", 
                                          field.name, field.data_type, field.name)
                            output.printf("#{indent}} else {\n#{indent}\t#{source}->#{field.name} = NULL;\n#{indent}}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    end
                }
                # Autosort generation
                entry.sort.each() {|field|
                    output.printf("#{indent}__#{libName}_#{entry.name}_sort_#{field.name}(#{source});\n")
                }
                
                if entry.attribute == :listable  then
                    
                    output.printf("#{indent}prev = el;\n") 
                    output.printf("#{indent}offset = (uint32_t)(unsigned long)el->next;\n");
                    output.printf("#{indent}#{entry.cleanup}(el);\n") if entry.cleanup != nil 
                    output.printf("\t} while (el->next != NULL);\n") 

                    output.puts "\treturn first;"
                else
                    output.printf("\t#{entry.cleanup}(el);\n") if entry.cleanup != nil 
                    output.puts "\treturn el;"
                end

                output.puts "}"

                output.puts "__#{libName}_#{entry.name}* __#{libName}_#{entry.name}_binary_load#{fExt}(#{(zipped == true) ? "gzFile" : "FILE*"} file, uint32_t offset){\n"
                output.printf("\t__#{libName}_partial_options opt = __#{libName.upcase}_PARTIAL_OPTIONS_INITIALIZER;\n")
                output.printf("\n")

                output.printf("\t__#{libName}_partial_options_parse_#{entry.name}(&opt);\n");
                output.printf("\treturn __#{libName}_#{entry.name}_binary_load_partial#{fExt}(file, offset, &opt);\n")
                output.printf("}\n");
                output.puts("
/** @} */
/** @} */
")


            end
            module_function :genBinaryReader


            def genBinaryReaderWrapper(output, description, entry)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
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
                output.printf("\tgzFile outputGz;\n")
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
                
;
                output.printf("\tif(opts & __#{libName.upcase}_OPTION_GZIPPED){\n")
                output.printf("\t\tif((outputGz = __#{libName}_open_gzFile(file, opts, \"r\")) == NULL)\n")
                output.printf("\t\t\t__#{libName}_error(\"Failed to open output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n"); 

                cRead(output, libName, true, "\t\t", "&header", "sizeof(header)", "1", "outputGz")
                output.printf("\t\tif(header.version != __#{libName.upcase}_DB_FORMAT)\n")
                output.printf("\t\t__#{libName}_error(\"Version from file %%s is incompatible.\", EACCES, file);\n\n");

                output.printf("\t\tif(strcmp(header.damage_version, __#{libName.upcase}_DAMAGE_VERSION))\n")
                output.printf("\t\t__#{libName}_error(\"Version from file %%s is incompatible.\", EACCES, file);\n\n");
                output.printf("\tptr = __#{libName}_%s_binary_load_partial_gz(outputGz, sizeof(header), partial_opts);\n\n", entry.name)


                output.printf("\t} else {\n")
                output.printf("\t\tif((output = __#{libName}_open_FILE(file, opts, \"r\")) == NULL)\n")
                output.printf("\t\t\t__#{libName}_error(\"Failed to open output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n");

                cRead(output, libName, false, "\t\t", "&header", "sizeof(header)", "1", "output")
                output.printf("\t\tif(header.version != __#{libName.upcase}_DB_FORMAT)\n")
                output.printf("\t\t__#{libName}_error(\"Version from file %%s is incompatible.\", EACCES, file);\n\n");

                output.printf("\t\tif(strcmp(header.damage_version, __#{libName.upcase}_DAMAGE_VERSION))\n")
                output.printf("\t\t__#{libName}_error(\"Version from file %%s is incompatible.\", EACCES, file);\n\n");

                output.printf("\t\tret = fstat(fileno(output), &fStat);\n")
                output.printf("\t\tif(ret != 0){\n")
                output.printf("\t\t\t__#{libName}_error(\"Failed to read from DB.\", errno);\n")
                output.printf("\t\t}\n")
                output.printf("\t\tif(header.length != fStat.st_size)\n")
                output.printf("\t\t__#{libName}_error(\"DB file %%s is corrupted: size does not match header.\", EIO, file);\n\n");
                output.printf("\tptr = __#{libName}_%s_binary_load_partial(output, sizeof(header), partial_opts);\n\n", entry.name)
                output.printf("\t}\n")



                output.printf("\tif (opts & __#{libName.upcase}_OPTION_READONLY ) {\n");
                output.printf("\t__#{libName}_release_flock(file);\n");
                output.printf("\t}\n");

                output.printf("\treturn ptr;\n");
                output.printf("}\n");
              output.printf("__#{libName}_%s* __#{libName}_%s_binary_load_file(const char* file, __#{libName}_options opts)\n{\n", entry.name, entry.name)
                output.printf("\t__#{libName}_partial_options opt = __#{libName.upcase}_PARTIAL_OPTIONS_INITIALIZER;\n")
                output.printf("\n")

                output.printf("\t__#{libName}_partial_options_parse_#{entry.name}(&opt);\n");
                output.printf("\topt._all = 1;\n");
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
