# Copyright (C) 2012  Nicolas Morey-Chaisemartin <nicolas@morey-chaisemartin.com>
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
        module XMLWriter
            
            @OUTFILE_H = "xml_writer.h"

            def write(description)

                description.entries.each() { |name, entry|
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "xml_writer__#{name}.c")
                    self.genC(outputC, description, entry, false)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "xml_writer_gz__#{name}.c")
                    self.genC(outputC, description, entry, true)
                    outputC.close()
                    outputC = Damage::Files.createAndOpen("gen/#{description.config.libname}/src", "xml_writer_wrapper__#{name}.c")
                    self.genCWrapper(outputC, description, entry)
                    outputC.close()
                }

                outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE_H)
                self.genH(outputH, description)
                outputH.close()
            end
            module_function :write


            private
            def genC(output, description, entry, zipped)

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
/** \\addtogroup #{libName}_xml_write XML Writer API
 * @{
 **/
");

                if(zipped) then
                    paddFunc="__#{libName}_paddOutputGz"
                    printFunc="__#{libName}_gzPrintf"
                    ext="_gz"
                    output.printf("void __#{libName}_#{entry.name}_xml_dump_within_gz(gzFile file, const __#{libName}_const_#{entry.name} *ptr, int indent){\n")
                else
                    paddFunc="__#{libName}_paddOutput"
                    printFunc="fprintf"
                    ext=""
                    output.printf("void __#{libName}_#{entry.name}_xml_dump_within(FILE* file, const __#{libName}_const_#{entry.name} *ptr, int indent){\n")
                end
                output.printf("\t#{paddFunc}(file, indent, 0, 0);\n")
                output.printf("\t#{printFunc}(file, \"<#{entry.name}\");\n")
                hasChildren = false
                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple
                            output.printf("\t#{printFunc}(file, \" #{field.name}=\\\"%%#{field.printf}\\\"\", ptr->#{field.name});\n");
                        when :enum
                            output.printf("\tif(ptr->#{field.name} > 0)\n")
                            output.printf("\t\t#{printFunc}(file, \" #{field.name}=\\\"%%s\\\"\", __#{libName}_#{entry.name}_#{field.name}_strings[ptr->#{field.name}]);\n")
                        when :genum
                            output.printf("\tif(ptr->#{field.name} > 0)\n")
                            output.printf("\t\t#{printFunc}(file, \" #{field.name}=\\\"%%s\\\"\", __#{libName}_#{field.genumEntry}_#{field.genumField}_strings[ptr->#{field.name}]);\n")
                        when :string
                            output.printf("\tif(ptr->#{field.name} != NULL){\n");
                            output.printf("\t\t char *str = __#{libName}_xml_encode_str(ptr->#{field.name});\n");
                            output.printf("\t\t#{printFunc}(file, \" #{field.name}=\\\"%%s\\\"\", str);\n");
                            output.printf("\t\tfree(str);\n");
                            output.printf("\t}\n");
                        when :raw
                            output.printf("\tif(ptr->#{field.name} != NULL){\n");
                            output.printf("\t\tchar* data = __#{libName}_malloc(ptr->#{field.name}Length * 4 / 3 + 4);\n");
                            output.printf("\t\t__#{libName}_base64_encode(ptr->#{field.name}, ptr->#{field.name}Length," +
                                          "data, ptr->#{field.name}Length * 4 / 3 + 4);\n");
                            output.printf("\t\t#{printFunc}(file, \" #{field.name}=\\\"%%s\\\"\", data);\n");
                            output.printf("\t\tfree(data);\n");
                            output.printf("\t}\n");
                        when :intern
                            hasChildren = true
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    else
                        hasChildren = true
                    end
                }
                if hasChildren == true then
                    output.printf("\t#{printFunc}(file, \">\\n\");\n")
                else
                    output.printf("\t#{printFunc}(file, \"/>\\n\");\n")
                end
                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple
                        when :enum, :genum
                        when :string
                        when :raw
                        when :intern
                            output.printf("\tif(ptr->#{field.name} != NULL){\n");
                            output.printf("\t\t__#{libName}_#{field.data_type}_xml_dump_within#{ext}(file, ptr->#{field.name}, indent+1);\n");
                            output.printf("\t}\n");

                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                        when :simple
                            output.printf("\t{\n");
                            output.printf("\t\tunsigned int i;\n");
                            output.printf("\t\tfor(i = 0; i < ptr->#{field.name}Len; i++){\n");
                            output.printf("\t\t\t#{paddFunc}(file, indent + 1, 0, 0);\n")
                            output.printf("\t\t\t#{printFunc}(file, \"<#{field.name}>%%#{field.printf}</#{field.name}>\\n\", ptr->#{field.name}[i]);\n");
                            output.printf("\t\t}\n");
                            output.printf("\t}\n");
                        when :string
                            output.printf("\t{\n");
                            output.printf("\t\tunsigned int i;\n");
                            output.printf("\t\tfor(i = 0; i < ptr->#{field.name}Len; i++){\n");
                            output.printf("\t\t\t#{paddFunc}(file, indent + 1, 0, 0);\n")
                            output.printf("\t\t\tchar *str = __#{libName}_xml_encode_str(ptr->#{field.name[i]});\n");
                            output.printf("\t\t\t#{printFunc}(file, \"<#{field.name}>%%s</#{field.name}>\\n\", str);\n");
                            output.printf("\t\t\tfree(str);\n");
                            output.printf("\t\t}\n");
                            output.printf("\t}\n");
                        when :raw
                            output.printf("\t{\n");
                            output.printf("\t\tunsigned int i;\n");
                            output.printf("\t\tfor(i = 0; i < ptr->#{field.name}Len; i++){\n");
                            output.printf("\t\t\t#{paddFunc}(file, indent + 1, 0, 0);\n")
                            output.printf("\t\t\tif(ptr->#{field.name}[i] != NULL){\n");
                            output.printf("\t\t\t\tchar* data = __#{libName}_malloc(ptr->#{field.name}Length[i] * 4 / 3 + 4);\n");
                            output.printf("\t\t\t\t__#{libName}_base64_encode(ptr->#{field.name}[i], ptr->#{field.name}Length[i]," +
                                          "data, ptr->#{field.name}Length[i] * 4 / 3 + 4);\n");
                            output.printf("\t\t\t\t#{printFunc}(file, \" #{field.name}=\\\"%%s\\\"\", data);\n");
                            output.printf("\t\t\t\tfree(data);\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                            output.printf("\t}\n");
                        when :intern
                            output.printf("\tif(ptr->#{field.name}){\n");
                            output.printf("\t\tconst __#{libName}_const_#{field.data_type} *el;\n");

                            if field.qty == :container
                                output.printf("\t\t#{paddFunc}(file, indent + 1, 0, 0);\n") 
                                output.printf("\t\t#{printFunc}(file, \"<#{field.name}>\\n\");");
                            end

                            output.printf("\t\tfor(el = ptr->#{field.name}; el; el = el->next){\n");
                            output.printf("\t\t\t__#{libName}_#{field.data_type}_xml_dump_within#{ext}(file, el, indent+2);\n");
                            output.printf("\t\t}\n");

                            if field.qty == :container
                                output.printf("\t\t#{paddFunc}(file, indent + 1, 0, 0);\n") 
                                output.printf("\t\t#{printFunc}(file, \"</#{field.name}>\\n\");");
                            end

                            output.printf("\t}\n");
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end                  
                    else
                        raise("Unsupported quantitiy for #{entry.name}.{field.name}")
                    end
                }
                if hasChildren == true then
                    output.printf("\t#{paddFunc}(file, indent, 0, 0);\n")
                    output.printf("\t#{printFunc}(file, \"</#{entry.name}>\\n\");\n")
             end
                output.printf("\t}\n\n")

                if zipped then 
                    output.printf("void __#{libName}_#{entry.name}_xml_dump_gz(gzFile file, " +
                                  "const __#{libName}_const_#{entry.name} *ptr){\n")
                else 
                    output.printf("void __#{libName}_#{entry.name}_xml_dump(FILE* file, " +
                                  "const __#{libName}_const_#{entry.name} *ptr){\n")
                end
                output.printf("\t#{printFunc}(file, \"<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\\n" +
                              "<!DOCTYPE #{entry.name} SYSTEM \\\"#{libName}.dtd\\\" >\\n\");\n")
                output.printf("\t__#{libName}_#{entry.name}_xml_dump_within#{ext}(file, ptr, 0);\n")
                output.printf("}\n\n")

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

                output.printf("int __#{libName}_%s_xml_dump_file(const char* file, const __#{libName}_const_%s *ptr, __#{libName}_options opts)\n{\n", entry.name, entry.name)
                output.printf("\n\tuint32_t ret = 0;\n")
                output.printf("\tFILE* output = NULL;\n")
                output.printf("\tgzFile outputGz = NULL;\n")
                output.printf("\n")

                output.printf("\tret = setjmp(__#{libName}_error_happened);\n");
                output.printf("\tif (ret != 0) {\n");
                output.printf("\t\terrno = ret;\n");
                output.printf("\t\treturn -1;\n");
                output.printf("\t}\n\n");

   

                output.printf("\tif(opts & __#{libName.upcase}_OPTION_GZIPPED){\n")
                output.printf("\t\tif((outputGz = __#{libName}_open_gzFile(file, __#{libName.upcase}_OPTION_NONE, \"w\")) == NULL)\n")
                output.printf("\t\t\t__#{libName}_error(\"Failed to open output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n");
                output.printf("\t\t__#{libName}_%s_xml_dump_gz(outputGz, ptr);\n", entry.name)
                output.printf("\t\tgzflush(outputGz, Z_FINISH);\n")
                output.printf("\t} else {\n")
                 output.printf("\t\tif((output = __#{libName}_open_FILE(file, __#{libName.upcase}_OPTION_NONE, \"w\")) == NULL)\n")
                output.printf("\t\t\t__#{libName}_error(\"Failed to open output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n");
                output.printf("\t\tif(ftruncate(fileno(output), 0) != 0)\n");
                output.printf("\t\t\t__#{libName}_error(\"Failed to truncate output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n");

                output.printf("\t\t__#{libName}_%s_xml_dump(output, ptr);\n", entry.name)
                output.printf("\t\tfflush(output);\n")
                output.printf("\t}\n")
                output.printf("\tif((opts & __#{libName.upcase}_OPTION_KEEPLOCKED) == 0)\n");
                output.printf("\t\t__#{libName}_release_flock(file);\n");
                output.printf("\treturn 0;\n");
                output.printf("}\n");

                output.puts("
/** @} */
/** @} */
")          

            end

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_xml_writer_h__\n")
                output.printf("#define __#{libName}_xml_writer_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup #{libName}_xml_write XML Writer API
 * @{
 **/

");
                description.entries.each() { |name, entry|
                    output.puts("
/**
 * Internal: Write a complete #__#{libName}_#{entry.name} structure and its children in XML form to an open file.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] file Opened FILE*
 * @param[in] ptr Structure to write
 * @param[in] indent Indentation of current node
 * @return node
 */");
                    output.printf("\tvoid __#{libName}_#{entry.name}_xml_dump_within(FILE* file, const __#{libName}_const_#{entry.name} *ptr, int indent);") 
                    output.puts("
/**
 * Internal: Write a complete #__#{libName}_#{entry.name} structure and its children in XML form to an open GZ file.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] file Opened gzFile
 * @param[in] ptr Structure to write
 * @param[in] indent Indentation of current node
 * @return node
 */"); 
                   output.printf("\tvoid __#{libName}_#{entry.name}_xml_dump_within_gz(gzFile file, const __#{libName}_const_#{entry.name} *ptr, int indent);") 

                    output.puts("
/**
 * Write a complete #__#{libName}_#{entry.name} structure and its children in XML form to an open file
 * @param[in] file Filename
 * @param[in] ptr Structure to write
 * @return Status
 * @retval 0 Success
 * @retval -1 in case of error
 */");
                    output.printf("\tvoid __#{libName}_#{entry.name}_xml_dump(FILE* file, const __#{libName}_const_#{entry.name} *ptr);\n")
                    output.puts("
 /**
 * Write a complete #__#{libName}_#{entry.name} structure and its children in XML form to an open gzipped file
 * @param[in] file Filename
 * @param[in] ptr Structure to write
 * @return Status
 * @retval 0 Success
 * @retval -1 in case of error
 */");                   output.printf("\tvoid __#{libName}_#{entry.name}_xml_dump_gz(gzFile file, const __#{libName}_const_#{entry.name} *ptr);\n")
                    output.puts("
/**
 * Write a complete #__#{libName}_#{entry.name} structure and its children in XML form to a file
 * @param[in] file Filename
 * @param[in] ptr Structure to write
 * @param[in] opts Options to writer (compression, read-only, etc)
 * @return Status
 * @retval 0 Success
 * @retval -1 in case of error
 */");
                    output.printf("int __#{libName}_%s_xml_dump_file(const char* file, const __#{libName}_const_%s *ptr, __#{libName}_options opts);\n\n", entry.name, entry.name)
                }
                output.puts("
/** @} */
/** @} */
")
                output.printf("#endif /* __#{libName}_xml_writer_h__ */\n")
            end
            module_function :genC, :genCWrapper, :genH
        end
    end
end
