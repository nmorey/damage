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

      def write(description)
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/src/", @OUTFILE)
        genReader(output, description)
        output.close()
      end
      module_function :write

      private
      def genReader(output, description)
        libName = description.config.libname

       
        output.printf("#include \"#{libName}.h\"\n");
        output.printf("#include \"_#{libName}/common.h\"\n");
        output.printf("\n");
        output.printf("jmp_buf __#{libName}_error_happened;\n");
        output.printf("\n\n");
        description.entries.each() {|name, entry|
          output.printf("__#{libName}_%s *__#{libName}_%s_xml_parse(", entry.name, entry.name);
          output.printf("xmlNodePtr node);\n");
        }
        description.containers.each() {|name, type|
          output.printf("__#{libName}_%s *__#{libName}_%s%sContainer_xml_parse(", type, name, type);
          output.printf("xmlNodePtr node);\n");
        }
        output.printf("\n\n");

        description.containers.each() {|name, type|
          output.printf("__#{libName}_%s *__#{libName}_%s%sContainer_xml_parse(", type, name, type);
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
          output.printf("\t\t\t*last_%s = __#{libName}_%s_xml_parse(child);\n",
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
        }
        description.entries.each() {|name, entry|
          struct = entry.name

          output.printf("__#{libName}_%s *__#{libName}_%s_xml_parse(", struct, struct);
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
                when :simple
                    case field.data_type
                    when "char*"
                        output.printf("\t\t\tptr->%s = __#{libName}_read_value_str_attr(attribute);\n",
                                        field.name) ;
                    when "unsigned long"
                        output.printf("\t\t\tptr->%s = __#{libName}_read_value_ulong_attr(attribute);\n",
                                        field.name) ;
                    when "double"
                        output.printf("\t\t\tptr->%s = __#{libName}_read_value_double_attr(attribute);\n",
                                        field.name) ;
                    else
                        raise("Unsupported type #{field.data_type}\n")
                    end
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
                when "unsigned long"
                  output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                " * (ptr->%sLen + 1));\n",
                                field.name, field.name, field.name, field.name) ;
                  output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_ulong_attr(attribute);\n",
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
                  when "unsigned long"
                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_ulong(child);\n",
                                  field.name) ;
                  when "double"
                    output.printf("\t\t\tptr->%s = __#{libName}_read_value_double(child);\n",
                                  field.name) ;
                  else
                    raise("Unsupported type #{field.data_type}\n")
                  end
                when :intern
                  output.printf("\t\t\tptr->%s = __#{libName}_%s_xml_parse(child);\n",
                                field.name, field.data_type) ;
                end
                output.printf("\t\t\tbreak;\n");
              when :list
                output.printf("\t\tcase %d:\n", caseCount);
                output.printf("\t\t\t/* %s */\n", field.name);
                case field.category
                when :simple
                  case field.data_type
                  when "char*"
                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                  "* (ptr->%sLen + 1));\n",
                                  field.name, field.name, field.name, field.name) ;
                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_str(child);\n",
                                  field.name, field.name) ;
                  when "unsigned long"
                    output.printf("\t\t\tptr->%s = __#{libName}_realloc(ptr->%s, sizeof(*(ptr->%s))" +
                                  " * (ptr->%sLen + 1));\n",
                                  field.name, field.name, field.name, field.name) ;
                    output.printf("\t\t\tptr->%s[ptr->%sLen++] = __#{libName}_read_value_ulong(child);\n",
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
                  output.printf("\t\t\t*last_%s = __#{libName}_%s_xml_parse(child);\n",
                                field.name, field.data_type) ;
                  output.printf("\t\t\tlast_%s = &((*last_%s)->next);\n",
                                field.name, field.name);
                end
                output.printf("\t\t\tbreak;\n");
              when :container
                output.printf("\t\tcase %d:\n", caseCount);
                output.printf("\t\t\t/* %s */\n", field.name);
                output.printf("\t\t\tptr->%s = __#{libName}_%s%sContainer_xml_parse(child);\n",
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
            output.printf("\tif (ptr != NULL) {\n");
            output.printf("\t\tunsigned long count = 0UL;\n");
            output.printf("\t\t__#{libName}_%s * %s;\n", field.data_type, field.name);
            output.printf("\t\tfor(%s = ptr->%s; %s != NULL;%s = %s->next){\n",
                          field.name, field.sort_field, field.name, field.name, field.name);
            output.printf("\t\t\tcount = (%s->%s >= count) ? (%s->%s+1) : count;\n\t\t\t\t\t}\n\n",
                          field.name, field.sort_key, field.name, field.sort_key);
            output.printf("\t\tptr->s_%s = __#{libName}_malloc(count * sizeof(*(ptr->s_%s)));\n",
                          field.name, field.name);
            output.printf("\t\tmemset(ptr->s_%s, 0, (count * sizeof(*(ptr->s_%s))));\n",
                          field.name, field.name);
            output.printf("\t\tptr->n_%s = count;\n", field.name);
            output.printf("\t\tfor(%s = ptr->%s; %s != NULL;%s = %s->next){\n",
                          field.name, field.sort_field, field.name, field.name, field.name);
            output.printf("\t\t\tassert(%s->%s < count);\n", field.name, field.sort_key);
            output.printf("\t\t\tptr->s_%s[%s->%s] = %s;\n", field.name, field.name, field.sort_key, field.name);
            output.printf("\t\t}\n");
            output.printf("\t}\n");
          }


          output.printf("\t#{entry.cleanup}(ptr);\n") if entry.cleanup != nil 

          output.printf("\treturn ptr;\n");
          output.printf("}\n\n");
        }

        
        # Generate file parser
        description.entries.each() { | name, entry|
          output.printf("__#{libName}_%s *__#{libName}_%s_xml_parse_file(const char* file){\n", entry.name, entry.name);
          output.printf("\t__#{libName}_%s *ptr = NULL;\n", entry.name);
          
          output.printf("\tint ret;\n");
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
          
          output.printf("\tif(__#{libName}_acquire_flock(file))\n");
          output.printf("\t\t__#{libName}_error(\"Failed to lock XML file %%s\",\n");
          output.printf("\t\t\t  ENOENT, file);\n");
          output.printf("\tdocument = xmlReadFile(file, NULL, 0);\n\n");
          
          output.printf("\tif (document == NULL) {\n");
          output.printf("\t\t__#{libName}_error(\"Failed to open XML file %%s\",\n");
          output.printf("\t\t\t  ENOENT, file);\n");
          output.printf("\t\treturn NULL;\n");
          output.printf("\t}\n\n");
          output.printf("\troot = xmlDocGetRootElement(document);\n");
          output.printf("\tif(root == NULL)\n");
          output.printf("\t\t__#{libName}_error(\"No root element in XML file %%s\", ENOENT, file);\n\n");
          
          output.printf("\tif(!strcmp((char*)root->name, \"%s\")){\n", entry.name);
          output.printf("\t\tptr = __#{libName}_%s_xml_parse(root);\n", entry.name, entry.name) ;
          output.printf("\t} else {\n");
          output.printf("\t\t__#{libName}_error\n");
          output.printf("\t\t\t(\"%s: Invalid node \\\"%%s\\\" at line %%d in XML file\",\n", entry.name);
          output.printf("\t\t\tEINVAL, root->name, root->line);\n");
          output.printf("\t}\n");
          
          output.printf("\txmlFreeDoc(document);\n");
          output.printf("\txmlCleanupParser();\n");
          output.printf("\treturn ptr;\n");
          output.printf("}\n\n");
        }
      end
      module_function :genReader
    end
  end
end
