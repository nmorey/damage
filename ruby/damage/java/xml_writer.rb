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
   module Java
      module XmlWriter
         def write(output, libName, entry, pahole, params)
            output.puts("
\t/**
\t * XML Writer
\t * @return a DOM Element
\t */
")
            output.printf("\tpublic DOMElement xmlWrite() {\n");
            output.printf("\t\tDOMElement ret = new DOMElement(\"#{params[:name]}\");\n");
            entry.fields.each() {|field|
               case field.attribute
               when :container,:none
                  case field.category
                  when :simple, :enum, :string,:id, :idref
                     case field.qty
                     when :single
                           output.printf("\t\t/** Writing #{field.name} */\n");
                           if field.category == :enum then
                                output.printf("\t\tif (_#{field.name} != #{field.java_type}.N_A)\n");
                                output.printf("\t\t\tret.add(new org.dom4j.dom.DOMAttribute(new org.dom4j.QName(\"#{field.name}\"), _#{field.name}.toString()));\n");
                           else 
                               if field.java_type == "String" then
                                   output.printf("\t\tif (_#{field.name} != null)\n");
                                   output.printf("\t\t\tret.add(new org.dom4j.dom.DOMAttribute(new org.dom4j.QName(\"#{field.name}\"), _#{field.name}));\n");
                               else
                                   output.printf("\t\tret.add(new org.dom4j.dom.DOMAttribute(new org.dom4j.QName(\"#{field.name}\"), String.valueOf(_#{field.name})));\n");
                               end
                           end
                     when :list
                           output.printf("\t\t/** Writing #{field.name} */\n");
                           output.printf("\t\tif (_#{field.name} != null) {\n");
                           output.printf("\t\t\tfor (#{field.java_type} i: _#{field.name}) {\n");
                           output.printf("\t\t\t\tDOMElement dom_#{field.name} = new DOMElement(\"#{field.name}\");\n");
                           output.printf("\t\t\t\tret.add(dom_#{field.name});\n");
                           output.printf("\t\t\t\tdom_#{field.name}.add(new org.dom4j.dom.DOMCDATA(String.valueOf(i)));\n");
                           output.printf("\t\t\t}\n");
                           output.printf("\t\t}\n");
                     end
                  when :intern
                     case field.qty
                     when :single
                        output.printf("\t\t/** Writing #{field.name} */\n");
			output.printf("\t\tif (_#{field.name} != null) {\n");
			output.printf("\t\t\tDOMElement dom_#{field.name} = _#{field.name}.xmlWrite();\n");
			output.printf("\t\t\tret.add(dom_#{field.name});\n");
			output.printf("\t\t}\n");
                     when :list, :container
                        if field.attribute == :container
                           output.printf("\t\tif (_#{field.name} != null) {\n");
                           output.printf("\t\t\tDOMElement dom_#{field.name} = new DOMElement(\"#{field.name}\");\n");
                           output.printf("\t\t\tret.add(dom_#{field.name});\n");
                           output.printf("\t\t\tfor (#{field.java_type} i: _#{field.name}) {\n");
                           output.printf("\t\t\t\tDOMElement ei = i.xmlWrite();\n");
                           output.printf("\t\t\t\tdom_#{field.name}.add(ei);\n");
                           output.printf("\t\t\t}\n");
                           output.printf("\t\t}\n");
                        else
                           output.printf("\t\tif (_#{field.name} != null) {\n");
                           output.printf("\t\t\tfor (#{field.java_type} i: _#{field.name}) {\n");
                           output.printf("\t\t\t\tDOMElement dom = i.xmlWrite();\n");
                           output.printf("\t\t\t\tret.add(dom);\n");
                           output.printf("\t\t\t}\n");
                           output.printf("\t\t}\n");
                        end
                     else raise("Unsupported data qty for #{entry.name}.#{field.name}") if field.attribute != :container
                     end
                  else
                     raise("Unsupported data category for #{entry.name}.#{field.name}");
                  end
               when :sort, :meta
                  output.printf("\t\t/** no xml generation for _#{field.name} */\n"); 
               else
                  raise("Unsupported data attribute for #{entry.name}.#{field.name}");
               end
            }


            output.puts("\t\treturn ret;\n");
            output.puts("\n\t}\n\n");
         end
         module_function :write

         private
      end
   end
end