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
        module Writer

            @OUTFILE = "xml_writer.c"
            @OUTFILE_H = "xml_writer.h"
            def write(description)
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/", @OUTFILE_H)
                genWriterH(output, description)
                output.close()
                description.entries.each() {|name, entry|
                    output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "xml_writer__#{name}.c")
                    genWriter(output, description, entry)
                    output.close()
                    output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", "xml_writer_wrapper__#{name}.c")
                    genWriterWrapper(output, description, entry)
                    output.close()
                }
            end
            module_function :write
            
            private 
            def addXmlElt(output, name, text, opts={})
                quotes = "\"" if opts[:quote ] == true
                str = opts[:prefix]
                parent = "node"
                parent = opts[:parent] if opts[:parent] != nil
                if opts[:is_attr] == true
                    function="xmlNewProp"
                else
                    function="xmlNewChild"
                    namespace="NULL, "
                end
                output.printf("\t\t%s%s(%s, %sBAD_CAST \"%s\", BAD_CAST %s%s%s);\n", 
                              str, function, parent, namespace, name, quotes, text, quotes);
            end

            def genWriterH(output, description)
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_xml_writer_h__")
                output.puts("#define __#{libName}_xml_writer_h__\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup xml_write XML Writer API
 * @{
 **/
");
                description.entries.each() {|name, entry|
                    output.puts("
/**
 * Internal: Write a complete #__#{libName}_#{entry.name} structure and its children in XML form to an open file.
 * This function uses longjmp to the \"__#{libName}_error_happened\".
 * Thus it needs to be set up properly before calling this function.
 * @param[in] node XML node to attach the structure too
 * @param[in] ptr Structure to write
 * @return node
 */");
                    output.printf("xmlNodePtr __#{libName}_create_%s_xml_node(xmlNodePtr node, const __#{libName}_%s *ptr);\n", entry.name, entry.name);
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
                    output.printf("int __#{libName}_%s_xml_dump_file(const char* file, const __#{libName}_%s *ptr, __#{libName}_options opts);\n\n", entry.name, entry.name)
                }
                output.printf("\n\n");

                output.puts("
/** @} */
/** @} */
")
                output.puts("#endif /* __#{libName}_xml_writer_h__ */\n")
            end
            module_function :genWriterH
            def genWriter(output, description, entry)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
                output.printf("\n")
                output.printf("\n\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup xml_write XML Writer API
 * @{
 **/
");


                output.printf("xmlNodePtr __#{libName}_create_%s_xml_node(xmlNodePtr node, const __#{libName}_%s *ptr)\n{\n",
                              entry.name, entry.name)

                if entry.enums.length > 0 then
                    entry.enums.each() { |field|
                        output.printf("\tconst char *#{field.name}_enum_str[] =\n\t{"); 
                        # Enumerate allowed keyword
                        output.printf("\"N_A\", ");
                        field.enum.each() {|str, enum|
                            output.printf("\"%s\", ", str) ;
                        }
                        output.printf("NULL };\n");
                    }
                end

                output.printf("\tif(node == NULL){ node = xmlNewNode(NULL, BAD_CAST \"%s\"); }\n", entry.name);
                entry.fields.each() { |field|
                    next if field.target == :mem

                    case field.qty
                    when :single
                        case field.category
                        when :string
                            output.printf("\tif(ptr->%s)\n", field.name);
                            addXmlElt(output, field.name, "ptr->#{field.name}", {:is_attr => field.is_attribute})
                        when :simple
                            raise("Unsupported simple type #{field.data_type}") if field.printf == nil
                            output.printf("\t{\n");
                            output.printf("\t\tchar numStr[64];\n");
                            output.printf("\t\tsnprintf(numStr, 64, \"%%#{field.printf}\", ptr->%s);\n", field.name);
                            addXmlElt(output, field.name, "numStr", {:is_attr => field.is_attribute})
                            output.printf("\t}\n");
                        when :intern
                            output.printf("\tif(ptr->%s){\n", field.name);
                            addXmlElt(output, field.name, "NULL", {:prefix => "xmlNodePtr child = "})
                            output.printf("\t\t\t__#{libName}_create_%s_xml_node(child, ptr->%s);\n",
                                          field.data_type, field.name);
                            output.printf("\t}\n\n");
                        when :id, :idref
                            output.printf("\tif(ptr->%s_str)\n", field.name);
                            addXmlElt(output, field.name, "ptr->#{field.name}_str", {:is_attr => field.is_attribute})
                        when :enum
                            addXmlElt(output, field.name, "#{field.name}_enum_str[(ptr->#{field.name} < #{field.enum.length + 1}) ? ptr->#{field.name} : 0]", {:is_attr => field.is_attribute})
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");

                        end
                    when :list
                        case field.category
                        when :string
                            output.printf("\tif(ptr->%s){\n", field.name);
                            output.printf("\t\tunsigned int lCount;\n");
                            output.printf("\t\tfor(lCount=0; lCount < ptr->%sLen; lCount++){\n", field.name);
                            addXmlElt(output, field.name, "ptr->#{field.name}[lCount]")
                            output.printf("\t\t}\n");
                            output.printf("\t}\n\n");
                        when :simple
                            raise("Unsupported simple type #{field.data_type}") if field.printf == nil
                            output.printf("\tif(ptr->%s){\n", field.name);
                            output.printf("\t\tchar numStr[64];\n");
                            output.printf("\t\tunsigned int lCount;\n");
                            output.printf("\t\tfor(lCount=0; lCount < ptr->%sLen; lCount++){\n", field.name);
                            output.printf("\t\t\tsnprintf(numStr, 64, \"%%#{field.printf}\", ptr->%s[lCount]);\n", field.name);
                            addXmlElt(output, field.name, "numStr")
                            output.printf("\t\t}\n");
                            output.printf("\t}\n\n");
                        when :intern
                            output.printf("\tif(ptr->%s){\n", field.name);
                            output.printf("\t\t__#{libName}_%s* elnt;\n", field.data_type);
                            output.printf("\t\tfor(elnt = ptr->%s; elnt != NULL; elnt = elnt->next){\n", field.name);
                            addXmlElt(output, field.name, "NULL", {:prefix => "xmlNodePtr child = "})
                            output.printf("\t\t\t__#{libName}_create_%s_xml_node(child, elnt);\n", field.data_type, field.name);
                            output.printf("\t\t}\n");
                            output.printf("\t}\n\n");
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");

                        end
                    when :container
                        output.printf("\tif(ptr->%s){\n", field.name);
                        addXmlElt(output, field.name, "NULL", {:prefix => "xmlNodePtr container = "})
                        output.printf("\t\t__#{libName}_%s* elnt;\n", field.data_type);
                        output.printf("\t\tfor(elnt = ptr->%s; elnt != NULL; elnt = elnt->next){\n", field.name);
                        addXmlElt(output, field.data_type, "NULL", {:prefix => "xmlNodePtr child = ", :parent => "container"})
                        output.printf("\t\t\t__#{libName}_create_%s_xml_node(child, elnt);\n", field.data_type, field.name);
                        output.printf("\t\t}\n");
                        output.printf("\t}\n\n");
                    end
                }
                output.printf("\treturn node;\n");
                output.printf("}\n\n");

                output.puts("
/** @} */
/** @} */
")
            end

            def genWriterWrapper(output, description, entry)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/_common.h\"\n")
                output.printf("#include <unistd.h>\n")
                output.printf("#include <libxml/xmlsave.h>\n")
                output.printf("\n")
                output.printf("\n\n")
                output.puts("

/** \\addtogroup #{libName} DAMAGE #{libName} Library
 * @{
**/
/** \\addtogroup xml_write XML Writer API
 * @{
 **/
");
                output.printf("int __#{libName}_%s_xml_dump_file(const char* file, const __#{libName}_%s *ptr, __#{libName}_options opts)\n{\n", entry.name, entry.name)
                output.printf("\txmlDocPtr doc = NULL;\n")
                output.printf("\txmlNodePtr node = NULL;\n")
                output.printf("\txmlSaveCtxtPtr ctx = NULL;\n")
                output.printf("\tuint32_t ret;\n")
                output.printf("\tint fd;\n")
                output.printf("\n")
                output.printf("\tret = setjmp(__#{libName}_error_happened);\n");
                output.printf("\tif (ret != 0) {\n");
                output.printf("\t\terrno = ret;\n");
                output.printf("\t\treturn -1;\n");
                output.printf("\t}\n\n");

               output.printf("\tdoc = xmlNewDoc(BAD_CAST \"1.0\");\n")
                output.printf("\tif(opts & __#{libName.upcase}_OPTION_GZIPPED)\n")
                output.printf("\t\txmlSetDocCompressMode(doc, 9);\n")
                output.printf("\tnode = __#{libName}_create_%s_xml_node(NULL, ptr);\n", entry.name)
                output.printf("\txmlDocSetRootElement(doc, node);\n")
                output.printf("\n")
                output.printf("\tif((fd = __#{libName}_open_fd(file, 0)) == -1)\n");
                output.printf("\t\t__#{libName}_error(\"Failed to lock output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n");
                output.printf("\tif(ftruncate(fd, 0) != 0)\n");
                output.printf("\t\t__#{libName}_error(\"Failed to truncate output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n");

                output.printf("\tif((ctx = xmlSaveToFd(fd, NULL, XML_SAVE_FORMAT)) == NULL)\n");
                output.printf("\t\t__#{libName}_error(\"Failed to write to output file %%s: %%s\", ENOENT, file, strerror(errno));\n\n");
                output.printf("\txmlSaveDoc(ctx, doc);\n");
                output.printf("\txmlSaveFlush(ctx);\n\n");
                output.printf("\txmlSaveClose(ctx);\n");
                output.printf("\txmlFreeDoc(doc);\n\n");
                output.printf("\tif((opts & __#{libName.upcase}_OPTION_KEEPLOCKED) == 0)\n");
                output.printf("\t\t__#{libName}_release_flock(file);\n");
                output.printf("\treturn 0;\n");
                output.printf("}\n");

                output.puts("
/** @} */
/** @} */
")
            end
            module_function :genWriter,:genWriterWrapper, :addXmlElt
        end
    end
end
