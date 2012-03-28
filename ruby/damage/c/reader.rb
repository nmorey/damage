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
        module Reader
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

                    description.containers.each() {|name, type|
                        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "xml_reader_container__#{name}#{type}.c")
                        genReaderContainer(output, description, name, type)
                        output.close()
                    }
                }
            end
            module_function :write

            private
            def genReaderH(output, description)
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_xml_reader_h__")
                output.puts("#define __#{libName}_xml_reader_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup xml_reader XML Reader API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Internal: Read a complete #__#{libName}_#{entry.name} structure and its children from a parsed XML tree.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] node XML subtree 
 * @return Pointer to a valid #__#{libName}_#{entry.name} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */");
                    output.printf("__#{libName}_%s *__#{libName}_%s_xml_load(", entry.name, entry.name);
                    output.printf("xmlNodePtr node);\n");
                    output.puts("
/**
 * Read a complete #__#{libName}_#{entry.name} structure and its children in XML from a file
 * @param[in] file Filename
 * @param[in] opts Options to parser (compression, read-only, etc)
 * @return Pointer to a #__#{libName}_#{entry.name} structure
 * @retval NULL Failed to read the file
 * @retval !=NULL Valid structure
 */");
                    output.printf("__#{libName}_%s *__#{libName}_%s_xml_load_file(const char* file, __#{libName}_options opts);\n", entry.name, entry.name);
                }
                description.containers.each() {|name, type|
                    output.puts("
/**
 * Internal: Read a complete #__#{libName}_#{type} structure and its children from a parsed XML tree.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] node XML subtree 
 * @return Pointer to a valid #__#{libName}_#{type} structure. If something fails, it executes a longjmp to __#{libName}_error_happened
 */");
                    output.printf("__#{libName}_%s *__#{libName}_%s%sContainer_xml_load(", type, name, type);
                    output.printf("xmlNodePtr node);\n\n");
                }
                output.printf("\n\n");

                output.puts("
/** @} */
/** @} */
")
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

                output.printf("__#{libName}_%s *__#{libName}_%s%sContainer_xml_load(", type, name, type);
                output.printf("xmlNodePtr node){\n");
                output.printf("\tconst char *name;\n");
                output.printf("\t__#{libName}_%s *ptr = NULL;\n", type);
                output.printf("\t__#{libName}_%s **last_%s = &(ptr);\n", 
                              type, type)
                output.printf("\tconst char *matches_children[] = { \"%s\", NULL };\n", type); 
                output.printf("\txmlNodePtr child;\n");
                output.printf("\n\tfor(child = node->children; child; child = child->next) {\n");
                output.printf("\t\tif(child->type != XML_ELEMENT_NODE) continue;\n\n");
                output.printf("\t\tname = (char*)child->name;\n\n");
                output.printf("\t\tswitch (__#{libName}_compare(name, matches_children)) {\n");  
                output.printf("\t\tcase 0:\n"  );
                output.printf("\t\t\t/* %s */\n", type)
                output.printf("\t\t\t*last_%s = __#{libName}_%s_xml_load(child);\n",
                              type, type) ;
                output.printf("\t\t\tlast_%s = &((*last_%s)->next);\n",
                              type, type);
                output.printf("\t\t\tbreak;\n");

                output.printf("\t\tdefault:\n");
                output.printf("\t\t\t__#{libName}_error\n");
                output.printf("\t\t\t\t(\"%s: Invalid node \\\"%%s\\\" at line %%d in XML file\",\n",
                              type);
                output.printf("\t\t\t\tEINVAL, name, child->line);\n");
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

                output.printf("__#{libName}_%s *__#{libName}_%s_xml_load(", struct, struct);
                output.printf("xmlNodePtr node)\n{\n");
                output.printf("\t__#{libName}_%s *ptr = __#{libName}_%s_alloc();\n", struct, struct);
                output.printf("\tconst char *name;\n");
                if entry.children.length > 0 then
                    output.printf("\txmlNodePtr child;\n");
                    output.printf("\tconst char *matches_children[] =\n\t{"); 
                    # Enumerate allowed keyword
                    entry.children.each() {|field|
                        output.printf("\"%s\", ", field.name) ;
                    }
                    output.printf("NULL };\n");
                end

                if entry.attributes.length > 0 then
                    output.printf("\txmlAttrPtr attribute;\n");
                    output.printf("\tconst char *matches_attributes[] =\n\t{"); 
                    # Enumerate allowed keyword
                    entry.attributes.each() {|field|
                        output.printf("\"%s\", ", field.name) ;
                    }
                    output.printf("NULL };\n");
                end
                if entry.enums.length > 0 then
                    entry.enums.each() { |field|
                        output.printf("\tconst char *#{field.name}_enum_str[] =\n\t{"); 
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

                if entry.attributes.length > 0 then
                    output.printf("\n\tfor(attribute = node->properties; attribute; attribute = attribute->next) {\n");
                    output.printf("\t\tif(attribute->type != XML_ATTRIBUTE_NODE) continue;\n\n", entry.name);
                    output.printf("\t\tname = (char*)attribute->name;\n\n");
                    output.printf("\t\tswitch (__#{libName}_compare(name, matches_attributes)) {\n");
                    caseCount=0
                    entry.attributes.each() {|field|
                        case field.qty
                        when :single
                            output.printf("\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t/* %s */\n", field.name);
                            case field.category
                            when :simple, :string
                                case field.data_type
                                when "char*"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_str_attr(attribute);\n",
                                                  field.name) ;
                                when "uint32_t", "unsigned int"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_ulong_attr(attribute);\n",
                                                  field.name) ;
                                when "int32_t", "signed int"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_slong_attr(attribute);\n",
                                                  field.name) ;
                                when "uint64_t", "unsigned long long"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_ullong_attr(attribute);\n",
                                                  field.name) ;
                                when "int64_t", "signed long long"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_sllong_attr(attribute);\n",
                                                  field.name) ;
                                when "double"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_double_attr(attribute);\n",
                                                  field.name) ;
                                else
                                    raise("Unsupported type #{field.data_type}\n")
                                end
                            when :enum
                                output.printf("\t\t\tname =  __#{libName}_read_value_str_attr_nocopy(attribute);\n\n");
                                output.printf("\t\t\tswitch (__#{libName}_compare(name, #{field.name}_enum_str)) {\n");
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

                                output.printf("\t\t\t}\n");

                            when :id, :idref
                                # Every id or idref must be of the form:
                                # type-integer. We store the whole string within
                                # field.name_str variable and only the integer in
                                # field.name.
                                output.printf("\t\t\tptr->%s_str = __#{libName}_read_value_str_attr(attribute);\n",
                                              field.name) ;
                                output.printf("\t\t\tchar *tmp_result = strchr(ptr->%s_str, '-');\n", field.name);
                                # We check that id or idref have a '-' in their
                                # name.
                                output.printf("\t\t\tif (tmp_result == NULL) {\n");
                                output.printf("\t\t\t\t__#{libName}_error\n");
                                output.printf("\t\t\t\t\t(\"%s: Invalid id or idref \\\"%%s\\\" at line %%d in XML file\",\n",
                                              struct);
                                output.printf("\t\t\t\t\tEINVAL, name, node->line);\n");
                                output.printf("\t\t\t\tbreak;\n");
                                output.printf("\t\t\t}\n");

                                output.print("\t\t\tchar *end_ptr = NULL;\n");
                                output.printf("\t\t\tptr->%s = strtoul(tmp_result + 1, &end_ptr, 10);\n", field.name);
                                # If end_ptr equals starting address it means that
                                # there were no digit at all, which is an error.
                                # If end_ptr is not '\0', it means an invalid
                                # character was found.
                                output.printf("\t\t\tif ((end_ptr == (tmp_result+1)) || (*end_ptr != '\\0')) {\n");
                                output.printf("\t\t\t\t__#{libName}_error\n");
                                output.printf("\t\t\t\t\t(\"%s: Invalid id or idref integer \\\"%%s\\\" at line %%d in XML file\",\n",
                                              struct);
                                output.printf("\t\t\t\t\tEINVAL, name, node->line);\n");
                                output.printf("\t\t\t\tbreak;\n");
                                output.printf("\t\t\t}\n");
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                            output.printf("\t\t\tbreak;\n");
                        when :list
                            output.printf("\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t/* %s */\n", field.name);
                            case field.data_type
                            when "char*"
                                output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                              "* (ptr->%sLen + 1));\n",
                                              field.name, field.name, field.name, field.name) ;
                                output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_str_attr(attribute);\n",
                                              field.name, field.name) ;
                            when "uint32_t", "unsigned int"
                                output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                              " * (ptr->%sLen + 1));\n",
                                              field.name, field.name, field.name, field.name) ;
                                output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_ulong_attr(attribute);\n",
                                              field.name, field.name) ;
                            when "int32_t", "signed int"
                                output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                              " * (ptr->%sLen + 1));\n",
                                              field.name, field.name, field.name, field.name) ;
                                output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_slong_attr(attribute);\n",
                                              field.name, field.name) ;
                            when "uint64_t", "unsigned long long"
                                output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                              " * (ptr->%sLen + 1));\n",
                                              field.name, field.name, field.name, field.name) ;
                                output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_ullong_attr(attribute);\n",
                                              field.name, field.name) ;
                            when "int64_t", "signed long long"
                                output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                              " * (ptr->%sLen + 1));\n",
                                              field.name, field.name, field.name, field.name) ;
                                output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_sllong_attr(attribute);\n",
                                              field.name, field.name) ;
                            when "double"
                                output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                              " * (ptr->%sLen + 1));\n",
                                              field.name, field.name, field.name, field.name) ;
                                output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_double_attr(attribute);\n",
                                              field.name, field.name) ;
                            else
                                raise("Unsupported type #{field.data_type}\n")
                            end
                            output.printf("\t\t\tbreak;\n");
                        end
                        caseCount+=1
                    }
                    output.printf("\t\tdefault:\n");
                    output.printf("\t\t\t__#{libName}_error\n");
                    output.printf("\t\t\t\t(\"%s: Invalid property \\\"%%s\\\" at line %%d in XML file\",\n",
                                  struct);
                    output.printf("\t\t\t\tEINVAL, name, attribute->children->line);\n");
                    output.printf("\t\t\tbreak;\n");
                    output.printf("\t\t}\n");
                    output.print("\t}\n\n");         
                end

                if entry.children.length > 0 then
                    output.printf("\n\tfor(child = node->children; child; child = child->next) {\n");
                    output.printf("\t\tif(child->type != XML_ELEMENT_NODE) continue;\n\n", entry.name);
                    output.printf("\t\tname = (char*)child->name;\n\n");
                    output.printf("\t\tswitch (__#{libName}_compare(name, matches_children)) {\n");
                    caseCount=0
                    entry.children.each() {|field|
                        case field.qty
                        when :single
                            output.printf("\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t/* %s */\n", field.name);
                            case field.category
                            when :simple
                                case field.data_type
                                when "char*"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_str(child);\n",
                                                  field.name) ;
                                when "unsigned long", "uint32_t"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_ulong(child);\n",
                                                  field.name) ;
                                when "signed long", "int32_t"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_slong(child);\n",
                                                  field.name) ;
                                when "double"
                                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_double(child);\n",
                                                  field.name) ;
                                else
                                    raise("Unsupported type #{field.data_type}\n")
                                end
                            when :intern
                                output.printf("\t\t\tptr->%s = __#{libName}_%s_xml_load(child);\n",
                                              field.name, field.data_type) ;
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                            output.printf("\t\t\tbreak;\n");
                        when :list
                            output.printf("\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t/* %s */\n", field.name);
                            case field.category
                            when :simple, :string
                                case field.data_type
                                when "char*"
                                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  "* (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_str(child);\n",
                                                  field.name, field.name) ;
                                when "unsigned int", "uint32_t"
                                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_ulong(child);\n",
                                                  field.name, field.name) ;
                                when "signed int", "int32_t"
                                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_slong(child);\n",
                                                  field.name, field.name) ;
                                when "unsigned long long", "uint64_t"
                                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_ullong(child);\n",
                                                  field.name, field.name) ;
                                when "signed long long", "int64_t"
                                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_sllong(child);\n",
                                                  field.name, field.name) ;
                                when "double"
                                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                                  " * (ptr->%sLen + 1));\n",
                                                  field.name, field.name, field.name, field.name) ;
                                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_double(child);\n",
                                                  field.name, field.name) ;
                                else
                                    raise("Unsupported type #{field.data_type}\n")
                                end
                            when :intern
                                output.printf("\t\t\t*last_%s = __#{libName}_%s_xml_load(child);\n",
                                              field.name, field.data_type) ;
                                output.printf("\t\t\tlast_%s = &((*last_%s)->next);\n",
                                              field.name, field.name);
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                            output.printf("\t\t\tbreak;\n");
                        when :container
                            output.printf("\t\tcase %d:\n", caseCount);
                            output.printf("\t\t\t/* %s */\n", field.name);
                            output.printf("\t\t\tptr->%s = __#{libName}_%s%sContainer_xml_load(child);\n",
                                          field.name, field.name, field.data_type) ;
                            output.printf("\t\t\tbreak;\n");
                        end
                        caseCount+=1
                    }
                    output.printf("\t\tdefault:\n");
                    output.printf("\t\t\t__#{libName}_error\n");
                    output.printf("\t\t\t\t(\"%s: Invalid node \\\"%%s\\\" at line %%d in XML file\",\n",
                                  struct);
                    output.printf("\t\t\t\tEINVAL, name, child->line);\n");
                    output.printf("\t\t\tbreak;\n");
                    output.printf("\t\t}\n");
                    output.print("\t}\n\n");
                end
                # Autosort generation
                entry.sort.each() {|field|
                    output.printf("\t__#{libName}_#{entry.name}_sort_#{field.name}(ptr);\n")
                }


                output.printf("\t#{entry.cleanup}(ptr);\n") if entry.cleanup != nil 

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
                output.printf("\t__#{libName}_%s *ptr = NULL;\n", entry.name);
                
                output.printf("\tint ret, fd;\n");
                output.printf("\txmlDocPtr document = NULL;\n\n");
                output.printf("\txmlNode* root;\n");

                output.printf("\tret = setjmp(__#{libName}_error_happened);\n");
                output.printf("\tif (ret != 0) {\n");
                output.printf("\t\tif (document != NULL){\n");
                output.printf("\t\t\txmlFreeDoc(document);\n");
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
                output.printf("\t\t\twrite(unzippedFd, &buf, nbytes);\n");
                output.printf("\t\t}\n");
                output.printf("\t\tlseek(unzippedFd, 0, SEEK_SET);\n");
                output.printf("\t\tfd = unzippedFd;\n");
                output.printf("\t}\n");

                output.printf("\tdocument = xmlReadFd(fd, NULL, NULL, 0);\n\n");
                
                output.printf("\tif (document == NULL) {\n");
                output.printf("\t\t__#{libName}_error(\"Failed to open XML file %%s\",\n");
                output.printf("\t\t\t  ENOENT, file);\n");
                output.printf("\t\treturn NULL;\n");
                output.printf("\t}\n\n");
                output.printf("\troot = xmlDocGetRootElement(document);\n");
                output.printf("\tif(root == NULL)\n");
                output.printf("\t\t__#{libName}_error(\"No root element in XML file %%s\", ENOENT, file);\n\n");
                
                output.printf("\tif(!strcmp((char*)root->name, \"%s\")){\n", entry.name);
                output.printf("\t\tptr = __#{libName}_%s_xml_load(root);\n", entry.name, entry.name) ;
                output.printf("\t} else {\n");
                output.printf("\t\t__#{libName}_error\n");
                output.printf("\t\t\t(\"%s: Invalid node \\\"%%s\\\" at line %%d in XML file\",\n", entry.name);
                output.printf("\t\t\tEINVAL, root->name, root->line);\n");
                output.printf("\t}\n");
                output.printf("\tif (opts & __#{libName.upcase}_OPTION_READONLY) {\n");
                output.printf("\t__#{libName}_release_flock(file);\n");
                output.printf("\t}\n");
                output.printf("\txmlFreeDoc(document);\n");
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
