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
      module XmlReader
        def write(output, libName, entry, pahole, params)
         uppercaseLibName = libName.slice(0,1).upcase + libName.slice(1..-1)
         output.puts("
\t/**
\t * Xml Reader from an Element 
\t */
")
	output.printf("\tstatic public #{params[:class]} XmlRead(Element el) {\n");
	output.printf("\t\t#{params[:class]} obj=new #{params[:class]}();\n");
            entry.fields.each() {|field|
	    output.printf("\t\ttry {\n");
                case field.attribute
		when :sort
                when :meta
		when :container,:none
                    case field.category
                    when :simple, :enum, :string
                        case field.qty
                        when :single
			    if field.category == :enum then
				output.printf("\t\tobj._#{field.name}=StrTo#{field.java_type}(el.attributeValue(\"#{field.name}\"));\n");
				else
				output.printf("\t\tobj._#{field.name}=el.attributeValue(\"#{field.name}\");\n") if field.java_type == "String"
				output.printf("\t\tobj._#{field.name}=Integer.parseInt(el.attributeValue(\"#{field.name}\"));\n") if field.java_type == "int"
				output.printf("\t\tobj._#{field.name}=Double.parseDouble(el.attributeValue(\"#{field.name}\"));\n") if field.java_type == "double"
				output.printf("\t\tobj._#{field.name}=Byte.parseByte(el.attributeValue(\"#{field.name}\"));\n") if field.java_type == "byte"
				output.printf("\t\tobj._#{field.name}=Short.parseShort(el.attributeValue(\"#{field.name}\"));\n") if field.java_type == "short"
				output.printf("\t\tobj._#{field.name}=el.attributeValue(\"#{field.name}\").charAt(0);\n") if field.java_type == "char"
				output.printf("\t\tobj._#{field.name}=Float.parseFloat(el.attributeValue(\"#{field.name}\"));\n") if field.java_type == "float"
				output.printf("\t\tobj._#{field.name}=Long.parseLong(el.attributeValue(\"#{field.name}\"));\n") if field.java_type == "long"
				end
			    end
                    when :intern
                        if field.qty == :single then
			    output.printf("\t\tobj._#{field.name}=#{field.java_type}.XmlRead(el.element(\"#{field.name}\"));\n");
                        else
                            output.printf("\t\tobj._#{field.name}=new java.util.ArrayList<#{field.java_type}>();\n");
			    output.printf("\t\t\t{\n");
			    if field.attribute == :container
				output.printf("\t\t\tjava.util.List<Element> tmp=el.element(\"#{field.name}\").elements(\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\");\n") 
			    else
				output.printf("\t\t\tjava.util.List<Element> tmp=el.elements(\"#{field.name}\");\n")
		            end
			    output.printf("\t\t\tfor (int i=0;i<tmp.size();i++) {\n");
			    output.printf("\t\t\t\tobj._#{field.name}.add(#{field.java_type}.XmlRead(tmp.get(i)));\n");
			    output.printf("\t\t\t\t}\n");
			    output.printf("\t\t\t}\n");
                        end
                    else
                        raise("Unsupported data category for #{entry.name}.#{field.name}");
                    end
                else
                    raise("Unsupported data attribute for #{entry.name}.#{field.name}");
                end
 	    output.printf("\t\t}\n");
	    output.printf("\t\tcatch(Exception ex) {}\n");
            }
            

            entry.fields.each() {|field|
                case field.attribute
                when :sort
			output.printf("\t\tobj.sort_#{field.name}_by_#{field.sort_key}();\n");
		end
	    }

	    output.puts("\t\tCleanupSigmacDBObjectVisitor.instance.visit(obj);\n");
	    output.puts("\t\treturn obj;\n");
	    output.puts("\n\t}\n\n");
        end
        module_function :write
        
        private
    end
  end
end
