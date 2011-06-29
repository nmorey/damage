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
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", @OUTFILE)
                genWriter(output, description)
                output.close()
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
                description.entries.each() {|name, entry|
                    output.printf("xmlNodePtr __#{libName}_create_%s_xml_node(xmlNodePtr node, __#{libName}_%s *ptr);\n", entry.name, entry.name);
                    output.printf("int __#{libName}_%s_xml_dump_file(const char* file, __#{libName}_%s *ptr, int zipped, int unlock);\n\n", entry.name, entry.name)
                }
                output.printf("\n\n");
               output.puts("#endif /* __#{libName}_xml_writer_h__ */\n")
            end
            module_function :genWriterH
            def genWriter(output, description)
                libName = description.config.libname

                output.printf("#include \"#{libName}.h\"\n")
                output.printf("#include \"_#{libName}/common.h\"\n")
                output.printf("\n")
                output.printf("jmp_buf __#{libName}_error_happened;\n")
                output.printf("\n\n")

                description.entries.each() {|name, entry|
                    output.printf("xmlNodePtr __#{libName}_create_%s_xml_node(xmlNodePtr node, __#{libName}_%s *ptr);\n", entry.name, entry.name);
                }

                description.entries.each() {|name, entry|
                    output.printf("xmlNodePtr __#{libName}_create_%s_xml_node(xmlNodePtr node, __#{libName}_%s *ptr)\n{\n",
                                  entry.name, entry.name)

                    if entry.enums.length > 0 then
                        entry.enums.each() { |field|
                            output.printf("\tconst char *#{field.name}_enum_str[] =\n\t{"); 
                            # Enumerate allowed keyword
                            output.printf("\"N/A\", ");
                            field.enum.each() {|enum|
                                output.printf("\"%s\", ", enum) ;
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
                            when :simple
                                case field.data_type
                                when "char*"
                                    output.printf("\tif(ptr->%s)\n", field.name);
                                    addXmlElt(output, field.name, "ptr->#{field.name}", {:is_attr => field.is_attribute})
                                when "unsigned long", "signed long", "uint32_t", "int32_t", "double"
                                    output.printf("\t{\n");
                                    output.printf("\t\tchar numStr[64];\n");
                                    output.printf("\t\tsnprintf(numStr, 64, \"%%#{field.printf}\", ptr->%s);\n", field.name);
                                    addXmlElt(output, field.name, "numStr", {:is_attr => field.is_attribute})
                                    output.printf("\t}\n");
                                else
                                    raise("Unsupported type #{field.data_type}\n")
                                end
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
                            when :simple
                                case field.data_type
                                when "char*"
                                    output.printf("\tif(ptr->%s){\n", field.name);
                                    output.printf("\t\tunsigned int lCount;\n");
                                    output.printf("\t\tfor(lCount=0; lCount < ptr->%sLen; lCount++){\n", field.name);
                                    addXmlElt(output, field.name, "ptr->#{field.name}[lCount]")
                                    output.printf("\t\t}\n");
                                    output.printf("\t}\n\n");
                                when "unsigned long", "signed long", "uint32_t", "int32_t", "double"
                                    output.printf("\tif(ptr->%s){\n", field.name);
                                    output.printf("\t\tchar numStr[64];\n");
                                    output.printf("\t\tunsigned int lCount;\n");
                                    output.printf("\t\tfor(lCount=0; lCount < ptr->%sLen; lCount++){\n", field.name);
                                    output.printf("\t\t\tsnprintf(numStr, 64, \"%%#{field.printf}\", ptr->%s[lCount]);\n", field.name);
                                    addXmlElt(output, field.name, "numStr")
                                    output.printf("\t\t}\n");
                                    output.printf("\t}\n\n");
                                else
                                    raise("Unsupported type #{field.data_type}\n")
                                end
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
                }

                description.entries.each() { | name, entry|
                    output.printf("int __#{libName}_%s_xml_dump_file(const char* file, __#{libName}_%s *ptr, int zipped, int unlock)\n{\n", entry.name, entry.name)
                    output.printf("\txmlDocPtr doc = NULL;\n")
                    output.printf("\txmlNodePtr node = NULL;\n")
                    output.printf("\tint ret;\n")
                    output.printf("\n")
                    output.printf("\tdoc = xmlNewDoc(BAD_CAST \"1.0\");\n")
                    output.printf("\tif(zipped)\n")
                    output.printf("\t\txmlSetDocCompressMode(doc, 9);\n")
                    output.printf("\tnode = __#{libName}_create_%s_xml_node(NULL, ptr);\n", entry.name)
                    output.printf("\txmlDocSetRootElement(doc, node);\n")
                    addXmlElt(output, "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance", {:is_attr =>true, :quote =>true})
                    addXmlElt(output, "xsi:noNamespaceSchemaLocation", "sigmaC.xsd", {:is_attr =>true, :quote =>true})
                    output.printf("\n")
                    output.printf("\tif(__#{libName}_acquire_flock(file, 1))\n");
                    output.printf("\t\t__#{libName}_error(\"Failed to lock XML file %%s\",\n");
                    output.printf("\t\t\t  ENOENT, file);\n");
                    output.printf("\tret = xmlSaveFormatFileEnc(file, doc, \"us-ascii\", 1);\n");
                    output.printf("\txmlFreeDoc(doc);\n\n");
                    output.printf("\tif(unlock)\n");
                    output.printf("\t\t__#{libName}_release_flock();\n");
                    output.printf("\treturn ret;\n");
                    output.printf("}\n");
                }      

            end
            module_function :genWriter, :addXmlElt
        end
    end
end
