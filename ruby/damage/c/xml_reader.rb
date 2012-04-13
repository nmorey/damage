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
        module XMLReader
            @OUTFILE = "xml_reader.c"
            @OUTFILE_H = "xml_reader.h"

            def write(description)
                 output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/", @OUTFILE_H)
                genReaderH(output, description)
                output.close()
               description.entries.each() { |name, entry|
                    output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "xml_reader__#{name}.c")
                    genReader(output, description, entry)
                    output.close()
                    output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "xml_reader_wrapper__#{name}.c")
                    genReaderWrapper(output, description, entry)
                    output.close()
                }
                description.containers.each() {|name, type|
                    output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "xml_reader_container__#{name}#{type}.c")
                    genReaderContainer(output, description, name, type)
                    output.close()
                }
            end
            module_function :write

            private
            def genReaderH(output, description)
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_xml_reader_h__")
                output.puts("#define __#{libName}_xml_reader_h__\n")
                description.entries.each() { |name, entry|
                    output.printf("
/**
 * Internal: Read a complete #__#{libName}_#{entry.name} structure and its children from a XLM reader.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] reader XML reader pointing to the start element
 * @param[in] endElement Name of the closing element
 * @return Pointer to a valid #__#{libName}_#{entry.name} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */
__#{libName}_#{name} *__#{libName}_#{name}_xml_load_element(xmlTextReaderPtr reader, const char* endElement);
 
/**
 * Read a complete #__#{libName}_#{entry.name} structure and its children in XML from a file
 * @param[in] file Filename
 * @param[in] opts Options to parser (compression, read-only, etc)
 * @return Pointer to a #__#{libName}_#{entry.name} structure
 * @retval NULL Failed to read the file
 * @retval !=NULL Valid structure
 */
__#{libName}_#{name} *__#{libName}_#{name}_xml_load_file(const char* file, __#{libName}_options opts);
")
            }
                description.containers.each() {|name, type|
                    output.printf("
/**
 * Internal: Read a complete #__#{libName}_#{type} structure and its children from a XML reader.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] reader XML reader pointing to the start element
 * @return Pointer to a valid #__#{libName}_#{type} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */
__#{libName}_#{type} *__#{libName}_#{name}#{type}Container_xml_load_elements(xmlTextReaderPtr reader);
")
                }
               output.puts("#endif /* __#{libName}_xml_reader_h__ */\n")
            end
            module_function :genReaderH

            
            def genReaderContainer(output, description, name, type)
                libName = description.config.libname

                
                output.printf("#include \"#{libName}.h\"\n");
                output.printf("#include \"_#{libName}/_common.h\"\n");
                output.printf("\n");
                output.printf("\n\n");


                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup xml_reader XML Reader API
 * @{
 **/
");

                output.printf("__#{libName}_%s *__#{libName}_%s%sContainer_xml_load_elements(xmlTextReaderPtr reader){", 
                              type, name, type);
                output.printf("\tconst char *name;\n");
                output.printf("\t__#{libName}_%s *ptr = NULL;\n", type);
                output.printf("\t__#{libName}_%s **last_%s = &(ptr);\n", 
                              type, type)
                output.printf("\tstatic const char *matches_children[] = { \"%s\", NULL };\n", type); 
                output.printf("\n\twhile (xmlTextReaderRead(reader) == 1) {\n");
                output.printf("\t\tname = __#{libName}_get_name(reader);\n\n");
                output.printf("\t\tswitch (xmlTextReaderNodeType(reader)) {\n");
                output.printf("\t\tcase 1:\n");
                output.printf("\t\t\t/* There is an element, parse it ! */\n");
                output.printf("\t\t\tswitch (__#{libName}_compare(name, matches_children)) {\n");  
                output.printf("\t\t\tcase 0:\n"  );
                output.printf("\t\t\t\t/* %s */\n", type)
                output.printf("\t\t\t\t*last_%s = __#{libName}_%s_xml_load_element(reader, \"#{type}\");\n",
                              type, type) ;
                output.printf("\t\t\t\tlast_%s = &((*last_%s)->next);\n",
                              type, type);
                output.printf("\t\t\t\tbreak;\n");

                output.printf("\t\t\tdefault:\n");
                output.printf("\t\t\t\t__#{libName}_error\n");
                output.printf("\t\t\t\t\t(\"%s: Invalid node \\\"%%s\\\" at line %%d in XML file\",\n",
                              type);
                output.printf("\t\t\t\t\tEINVAL, name, xmlTextReaderGetParserLineNumber(reader));\n");
                output.printf("\t\t\t\tbreak;\n");
                output.printf("\t\t\t}\n");
                output.printf("\t\tcase 15:\n");
                output.printf("\t\t\tif(!strcmp(name, \"#{name}\")) {\n");
                output.printf("\t\t\t\t/* End of the descriptor, let's leave */\n");
                output.printf("\t\t\t\t__#{libName}_eat_elnt(reader);\n");
                output.printf("\t\t\t\treturn ptr;\n");
                output.printf("\t\t\t}\n");
                output.printf("\t\tdefault:\n");
                output.printf("\t\t\t/* Ignore */\n");
                output.printf("\t\t\tbreak;\n");
                output.printf("\t\t}\n");

                output.print("\t}\n\n");
                output.printf("\treturn ptr;\n");
                output.printf("}\n");

                output.puts("
/** @} */
/** @} */
")
            end
            module_function :genReaderContainer

            def genReader(output, description, entry)
                libName = description.config.libname

                
                output.printf("#include \"#{libName}.h\"\n");
                output.printf("#include \"_#{libName}/_common.h\"\n");
                output.printf("\n");
                output.printf("\n\n");


                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup xml_reader XML Reader API
 * @{
 **/
");

                struct = entry.name

                output.printf("__#{libName}_%s *__#{libName}_%s_xml_load_element(xmlTextReaderPtr reader, const char* endElement){\n",
                              struct, struct);
                output.printf("\t__#{libName}_%s *ptr = __#{libName}_%s_alloc();\n", struct, struct);
                output.printf("\tconst char *name;\n");
                output.printf("\tint i;\n");
                output.printf("\tstatic const char *matches_children[] =\n\t{"); 
                if entry.children.length > 0 then
                    # Enumerate allowed keyword
                    entry.children.each() {|field|
                        output.printf("\"%s\", ", field.name) ;
                    }
                end
                output.printf("NULL };\n");

                output.printf("\tstatic const char *matches_attributes[] =\n\t{"); 
                if entry.attributes.length > 0 then
                    # Enumerate allowed keyword
                    entry.attributes.each() {|field|
                        output.printf("\"%s\", ", field.name) ;
                    }
                end
                output.printf("NULL };\n");

                if entry.enums.length > 0 then
                    entry.enums.each() { |field|
                        output.printf("\tstatic const char *#{field.name}_enum_str[] =\n\t{"); 
                        # Enumerate allowed keyword
                        output.printf("\"N_A\", ");
                        field.enum.each() {|enum|
                            output.printf("\"%s\", ", enum[:str]) ;
                        }
                        output.printf("NULL };\n");
                    }
                end
                #Get second level pointer to maneg "nexts" lists
                entry.children.each() {|field|
                    if field.qty == :list  && field.category == :intern
                        output.printf("\t__#{libName}_%s **last_%s = &(ptr->%s);\n", 
                                      field.data_type, field.name, field.name)
                    end
                }

                
                output.printf("\n\ti = xmlTextReaderAttributeCount(reader);\n");
                output.printf("\tif(i > 0){\n");
                output.printf("\t\tfor(i = xmlTextReaderMoveToFirstAttribute(reader); i == 1; i = xmlTextReaderMoveToNextAttribute(reader)) {\n");
                output.printf("\t\t\tconst char *name = (const char *)xmlTextReaderConstLocalName(reader);\n");
                output.printf("\t\t\tconst char *value = (const char *)xmlTextReaderConstValue(reader);\n") if entry.attributes.length > 0 
                output.printf("\t\t\tswitch (__#{libName}_compare(name, matches_attributes)) {\n");
                if entry.attributes.length > 0 then
                    caseCount=0
                    entry.attributes.each() {|field|
                        case field.qty
                        when :single
                            output.printf("\t\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t\t/* %s */\n", field.name);
                            case field.category
                            when :simple, :string
                                case field.data_type
                                when "char*"
                                    output.printf("\t\t\t\tptr->%s = strdup(value);\n",
                                                  field.name) ;
                                when "uint32_t", "unsigned int"
                                    output.printf("\t\t\t\tptr->%s = strtoul(value, NULL, 10);\n",
                                                  field.name) ;
                                when "int32_t", "signed int"
                                    output.printf("\t\t\t\tptr->%s = strtol(value, NULL, 10);\n",
                                                  field.name) ;
                                when "uint64_t", "unsigned long long"
                                    output.printf("\t\t\t\tptr->%s = strtoull(value, NULL, 10);\n",
                                                  field.name) ;
                                when "int64_t", "signed long long"
                                    output.printf("\t\t\t\tptr->%s = strtoll(value, NULL, 10);\n",
                                                  field.name) ;
                                when "double"
                                    output.printf("\t\t\t\tptr->%s = strtod(value, NULL);\n",
                                                  field.name) ;
                                else
                                    raise("Unsupported type #{field.data_type}\n")
                                end
                            when :enum
                                output.printf("\t\t\t\tswitch (__#{libName}_compare(value, #{field.name}_enum_str)) {\n");
                                subCaseCount=1
                                field.enum.each() {|enum|
                                    output.printf("\t\t\t\tcase %d:\n", subCaseCount);
                                    output.printf("\t\t\t\t\t/* %s */\n", enum[:str]);
                                    output.printf("\t\t\t\t\tptr->%s = #{field.enumPrefix}_#{enum[:label]};\n", field.name) ;
                                    output.printf("\t\t\t\t\tbreak;\n");
                                    subCaseCount+=1
                                }
                                output.printf("\t\t\t\tdefault:\n");
                                output.printf("\t\t\t\t\t/* N/A or something else*/\n");
                                output.printf("\t\t\t\t\tptr->%s = #{field.enumPrefix}_N_A;\n", field.name) ;
                                output.printf("\t\t\t\t\tbreak;\n");
                                output.printf("\t\t\t\t}\n");

                            when :id, :idref
                                # Every id or idref must be of the form:
                                # type-integer. We store the whole string within
                                # field.name_str variable and only the integer in
                                # field.name.
                                output.printf("\t\t\t\tptr->%s_str = strdup(value);\n",
                                              field.name) ;
                                output.printf("\t\t\t\tchar *tmp_result = strchr(ptr->%s_str, '-');\n", field.name);
                                # We check that id or idref have a '-' in their
                                # name.
                                output.printf("\t\t\t\tif (tmp_result == NULL) {\n");
                                output.printf("\t\t\t\t\t__#{libName}_error\n");
                                output.printf("\t\t\t\t\t\t(\"%s: Invalid id or idref \\\"%%s\\\" at line %%d in XML file\",\n",
                                              struct);
                                output.printf("\t\t\t\t\t\tEINVAL, name, node->line);\n");
                                output.printf("\t\t\t\t\tbreak;\n");
                                output.printf("\t\t\t\t}\n");

                                output.print("\t\t\t\tchar *end_ptr = NULL;\n");
                                output.printf("\t\t\t\tptr->%s = strtoul(tmp_result + 1, &end_ptr, 10);\n", field.name);
                                # If end_ptr equals starting address it means that
                                # there were no digit at all, which is an error.
                                # If end_ptr is not '\0', it means an invalid
                                # character was found.
                                output.printf("\t\t\t\tif ((end_ptr == (tmp_result+1)) || (*end_ptr != '\\0')) {\n");
                                output.printf("\t\t\t\t\t__#{libName}_error\n");
                                output.printf("\t\t\t\t\t\t(\"%s: Invalid id or idref integer \\\"%%s\\\" at line %%d in XML file\",\n",
                                              struct);
                                output.printf("\t\t\t\t\t\tEINVAL, name, node->line);\n");
                                output.printf("\t\t\t\t\tbreak;\n");
                                output.printf("\t\t\t\t}\n");
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                        output.printf("\t\t\t\tbreak;\n");
                        caseCount+=1
                    }
                end
                output.printf("\t\t\tdefault:\n");
                output.printf("\t\t\t\t__#{libName}_error\n");
                output.printf("\t\t\t\t\t(\"%s: Invalid property \\\"%%s\\\" at line %%d in XML file\",\n",
                              struct);
                output.printf("\t\t\t\t\tEINVAL, name,  xmlTextReaderGetParserLineNumber(reader));\n");
                output.printf("\t\t\t\tbreak;\n");
                output.printf("\t\t\t}\n");
                output.printf("\t\t}\n");
                output.printf("\txmlTextReaderMoveToElement(reader);\n");
                output.printf("\t}\n");

                output.printf("\n\tif(xmlTextReaderIsEmptyElement(reader)){\n");                
                output.printf("\t\tgoto __#{libName}_#{entry.name}_xml_load_exit;\n");
                output.printf("\t}\n");
                output.printf("\n\twhile (xmlTextReaderRead(reader) == 1) {\n");
                output.printf("\t\tname = __#{libName}_get_name(reader);\n\n");
                output.printf("\t\tswitch (xmlTextReaderNodeType(reader)) {\n");

                output.printf("\t\tcase 1:\n");
                output.printf("\t\t\t/* There is an element, parse it ! */\n");
                output.printf("\t\t\tswitch (__#{libName}_compare(name, matches_children)) {\n");
                if entry.children.length > 0 then
                    caseCount=0
                    entry.children.each() {|field|
                        case field.qty
                        when :single
                            output.printf("\t\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t\t/* %s */\n", field.name);
                            case field.category
                            when :intern
                                output.printf("\t\t\t\tptr->%s = __#{libName}_%s_xml_load_element(reader, name);\n",
                                              field.name, field.data_type) ;
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                            output.printf("\t\t\t\tbreak;\n");
                        when :list
                            output.printf("\t\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t\t/* %s */\n", field.name);                            
                            case field.category
                            when :simple, :string
                                output.printf("\t\t\t\t__#{libName}_eat_elnt(reader);\n", field.name);
                                case field.data_type
                                when "char*"
                                    output.printf("\t\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  "* (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_xml_read_value_str(reader);\n",
                                                  field.name, field.name) ;
                                when "unsigned int", "uint32_t"
                                    output.printf("\t\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_xml_read_value_ulong(reader);\n",
                                                  field.name, field.name) ;
                                when "signed int", "int32_t"
                                    output.printf("\t\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_xml_read_value_slong(reader);\n",
                                                  field.name, field.name) ;
                                when "unsigned long long", "uint64_t"
                                    output.printf("\t\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_xml_read_value_ullong(reader);\n",
                                                  field.name, field.name) ;
                                when "signed long long", "int64_t"
                                    output.printf("\t\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_xml_read_value_sllong(reader);\n",
                                                  field.name, field.name) ;
                                when "double"
                                    output.printf("\t\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_xml_read_value_double(reader);\n",
                                                  field.name, field.name) ;
                                else
                                    raise("Unsupported type #{field.data_type}\n")
                                end
                            when :intern
                                output.printf("\t\t\t\t*last_%s = __#{libName}_%s_xml_load_element(reader, name);\n",
                                              field.name, field.data_type) ;
                                output.printf("\t\t\t\tlast_%s = &((*last_%s)->next);\n",
                                              field.name, field.name);
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                            output.printf("\t\t\t\tbreak;\n");
                        when :container
                            output.printf("\t\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t\t/* %s */\n", field.name);
                            output.printf("\t\t\t\tptr->%s = __#{libName}_%s%sContainer_xml_load_elements(reader);\n",
                                          field.name, field.name, field.data_type) ;
                            output.printf("\t\t\t\tbreak;\n");
                        end
                        caseCount+=1
                    }
                   end
                output.printf("\t\t\tdefault:\n");
                output.printf("\t\t\t\t__#{libName}_error\n");
                output.printf("\t\t\t\t\t\t(\"%s: Invalid node \\\"%%s\\\" at line %%d in XML file\",\n",
                              struct);
                output.printf("\t\t\t\t\t\tEINVAL, name, xmlTextReaderGetParserLineNumber(reader));\n");
                output.printf("\t\t\t\tbreak;\n");
                output.printf("\t\t\t}\n");
                output.printf("\t\t\tbreak;\n");



                output.printf("\t\tcase 15:\n");
                output.printf("\t\t\tif(!strcmp(name, endElement)) {\n");
                output.printf("\t\t\t\t/* End of the descriptor, let's leave */\n");
                output.printf("\t\t\t\t__#{libName}_eat_elnt(reader);\n");
                output.printf("\t\t\t\tgoto __#{libName}_#{entry.name}_xml_load_exit;\n");

  


                output.printf("\t\t\t\treturn ptr;\n");
                output.printf("\t\t\t}\n\n");
                output.printf("\t\t\tbreak;\n");
                output.printf("\t\tdefault:\n");
                output.printf("\t\t\t/* Ignore */\n");
                output.printf("\t\t\tbreak;\n");
                output.printf("\t\t}\n");
                output.printf("\t}\n");
                output.printf("\t__#{libName}_#{entry.name}_xml_load_exit:\n");
                # Autosort generation
                entry.sort.each() {|field|
                    output.printf("\t\t\t\t__#{libName}_#{entry.name}_sort_#{field.name}(ptr);\n")
                }
                output.printf("\t\t\t\t#{entry.cleanup}(ptr);\n") if entry.cleanup != nil 
                output.printf("\treturn ptr;\n");
                output.printf("}\n\n");
                output.puts("
/** @} */
/** @} */
")
            end
            module_function :genReader


            def genReaderWrapper(output, description, entry)
                libName = description.config.libname

                
                output.printf("#include \"#{libName}.h\"\n");
                output.printf("#include \"_#{libName}/_common.h\"\n");
                output.printf("\n");
                output.printf("\n\n");


                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup xml_reader XML Reader API
 * @{
 **/
");
                output.printf("__#{libName}_%s *__#{libName}_%s_xml_load_file(const char* file, __#{libName}_options opts){\n", entry.name, entry.name);
                output.printf("\tconst char *matches[] =\n\t{ \"%s\", NULL};", entry.name); 
                output.printf("\t__#{libName}_%s *ptr = NULL;\n", entry.name);
                
                output.printf("\tint ret, fd;\n");
                output.printf("\txmlTextReaderPtr reader = NULL;\n\n");

                output.printf("\tret = setjmp(__#{libName}_error_happened);\n");
                output.printf("\tif (ret != 0) {\n");
                output.printf("\t\tif (reader != NULL){\n");
                output.printf("\t\t\txmlFreeTextReader(reader);\n");
                output.printf("\t\t\txmlCleanupParser();\n");
                output.printf("\t\t}\n");
                output.printf("\t\tif (ptr != NULL)\n");
                output.printf("\t\t\t__#{libName}_%s_free(ptr);\n", entry.name);
                output.printf("\t\terrno = ret;\n");
                output.printf("\t\treturn NULL;\n");
                output.printf("\t}\n\n");
                
                output.printf("\tif((fd = __#{libName}_open_fd(file, opts & __#{libName.upcase}_OPTION_READONLY)) == -1)\n");
                output.printf("\t\t__#{libName}_error(\"Failed to lock input file %%s: %%s\", ENOENT, file, strerror(errno));\n");
                output.printf("\tif (opts & __#{libName.upcase}_OPTION_GZIPPED) {\n");
                output.printf("\t\tint nbytes;\n");
                output.printf("\t\tchar buf[8192];\n");
                output.printf("\t\tint unzippedFd = mkstemp(strdup(\"/tmp/#{libName}.uz.XXXXXX\"));\n");
                output.printf("\t\tgzFile gzFd = gzdopen(fd, \"r\");\n");
                output.printf("\t\twhile(1){\n");
                output.printf("\t\t\tnbytes =  gzread(gzFd, &buf, sizeof(buf));\n");
                output.printf("\t\t\tif(nbytes <= 0) break;\n");
                output.printf("\t\t\tint sum = 0;\n");
                output.printf("\t\t\twhile(sum < nbytes){\n");
                output.printf("\t\t\t\tint ret = write(unzippedFd, &buf, nbytes);\n");
                output.printf("\t\t\t\tif(ret == -1){\n");
                output.printf("\t\t\t\t\tperror(\"Damage error\");\n");
                output.printf("\t\t\t\t\texit(EXIT_FAILURE);\n");
                output.printf("\t\t\t\t}\n");
                output.printf("\t\t\t\tsum += ret;\n");
                output.printf("\t\t\t}\n");
                output.printf("\t\t}\n");
                output.printf("\t\tlseek(unzippedFd, 0, SEEK_SET);\n");
                output.printf("\t\tfd = unzippedFd;\n");
                output.printf("\t}\n");
                output.printf("\tconst char* dtd_path = __#{libName}_get_dtd_path();");
                output.printf("\tint parse_options = dtd_path != NULL ? (XML_PARSE_DTDVALID | XML_PARSE_DTDLOAD) : 0;");
                output.printf("\treader = xmlReaderForFd(fd, dtd_path, NULL, parse_options);\n\n");
                
                output.printf("\tif (reader == NULL) {\n");
                output.printf("\t\t__#{libName}_error(\"Failed to open XML file %%s\",\n");
                output.printf("\t\t\t  ENOENT, file);\n");
                output.printf("\t\treturn NULL;\n");
                output.printf("\t}\n\n");
                output.printf("\txmlTextReaderSetErrorHandler(reader, __#{libName}_xmlTextReaderError, (void*)file);\n");
                output.printf("\n\twhile (xmlTextReaderRead(reader) == 1) {\n");
                output.printf("\t\tconst char *name = __#{libName}_get_name(reader);\n\n");
                output.printf("\t\tswitch (xmlTextReaderNodeType(reader)) {\n");
                output.printf("\t\tcase 1:\n");
                output.printf("\t\t\t/* There is an element, parse it ! */\n");
                output.printf("\t\t\tswitch (__#{libName}_compare(name, matches)) {\n");
                output.printf("\t\t\tcase 0:\n");
                output.printf("\t\t\t\t/* %s */\n", entry.name);
                output.printf("\t\t\t\tptr = __#{libName}_%s_xml_load_element(reader, \"%s\");\n", entry.name, entry.name) ;
                output.printf("\t\t\t\tbreak;\n");
                output.printf("\t\t\tdefault:\n");
                output.printf("\t\t\t\t__#{libName}_error\n");
                output.printf("\t\t\t\t\t(\"%s: Invalid node \\\"%%s\\\" at line %%d in XML file\",\n", entry.name);
                output.printf("\t\t\t\t\tEINVAL, name, xmlTextReaderGetParserLineNumber(reader));\n");
                output.printf("\t\t\t\tbreak;\n");
                output.printf("\t\t\t}\n");
                output.printf("\t\t\tbreak;\n");
                output.printf("\t\tdefault:\n");
                output.printf("\t\t\t/* Ignore */\n");
                output.printf("\t\t\tbreak;\n");
                output.printf("\t\t}\n");
                output.printf("\t}\n\n");
                output.printf("\tif (dtd_path && !xmlTextReaderIsValid(reader)) {\n");
                output.printf("\t__#{libName}_error(\"XML file does not follow the DTD\\n\", EINVAL);\n");
                output.printf("\t}\n");
                output.printf("\tif (opts & __#{libName.upcase}_OPTION_READONLY) {\n");
                output.printf("\t__#{libName}_release_flock(file);\n");
                output.printf("\t}\n");
                output.printf("\txmlFreeTextReader(reader);\n");
                output.printf("\txmlCleanupParser();\n");
                output.printf("\treturn ptr;\n");
                output.printf("}\n\n");

                output.puts("
/** @} */
/** @} */
")
            end
            module_function :genReaderWrapper
        end
    end
end
