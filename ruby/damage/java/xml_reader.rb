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
         output.puts("
\t/**
\t * XML Reader from an Element 
\t */
")
	output.printf("\tstatic public #{params[:class]} xmlRead(Element el) {\n");
	output.printf("\t\t#{params[:class]} obj=new #{params[:class]}();\n");
	check = 0
            entry.fields.each() {|field|
	    output.printf("\t\ttry {\n");
                case field.attribute
		when :sort
			check = 1
                when :meta
			check = 1
		when :container,:none
                    case field.category
                    when :simple, :enum, :string,:id, :idref
                        case field.qty
                        when :single
			check = 1
                        output.printf("\t\t\tString tmp = el.attributeValue(\"#{field.name}\");\n");
                        output.printf("\t\t\tif (tmp != null) {\n");
			    if field.category == :enum then
				output.printf("\t\t\t\tfor (#{field.java_type} tmp#{field.java_type}: #{field.java_type}.values()) {\n");
        output.printf("\t\t\t\t\tif (tmp.equals(tmp#{field.java_type}.toString())) {\n");
        output.printf("\t\t\t\t\t\tobj._#{field.name} = tmp#{field.java_type};\n");
        output.printf("\t\t\t\t\t\tbreak;\n");
        output.printf("\t\t\t\t\t}\n");
        output.printf("\t\t\t\t}\n");
				else
					case field.java_type
					when "String"
						output.printf("\t\t\t\tobj._#{field.name}=tmp.intern();\n")
					when "int"
						output.printf("\t\t\t\tobj._#{field.name}=Integer.parseInt(tmp);\n")
					when "double"
						output.printf("\t\t\t\tobj._#{field.name}=Double.parseDouble(tmp);\n")
					when "byte"
						output.printf("\t\t\t\tobj._#{field.name}=Byte.parseByte(tmp);\n")
					when "short"
						output.printf("\t\t\t\tobj._#{field.name}=Short.parseShort(tmp);\n")
					when "char"
						output.printf("\t\t\t\tobj._#{field.name}=tmp.charAt(0);\n")
					when "float"
						output.printf("\t\t\t\tobj._#{field.name}=Float.parseFloat(tmp);\n")
					when "long"		
						output.printf("\t\t\t\tobj._#{field.name}=Long.parseLong(tmp);\n")
					else
						raise("Unsupported java-type for #{entry.name}.#{field.name}");
					end
				end
                         output.printf("\t\t\t}\n");
			when :list
			check = 1
				output.printf("\t\t\t@SuppressWarnings(\"unchecked\")\n");
                                output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.elements(\"#{field.name}\");\n")
				output.printf("\t\t\tobj._#{field.name}=new #{field.java_type}[tmp.size()];\n");
                                output.printf("\t\t\tint count = 0;\n");
				output.printf("\t\t\tfor (Element #{field.name}Element: tmp) {\n");
                                output.printf("\t\t\t\tString #{field.name}String = #{field.name}Element.getTextTrim();\n");
				case field.java_type
					when "String"
						output.printf("\t\t\t\tobj._#{field.name}[count++]=#{field.name}String.intern();\n")
					when "int"
						output.printf("\t\t\t\tobj._#{field.name}[count++]=Integer.parseInt(#{field.name}String);\n")
					when "double"
						output.printf("\t\t\t\tobj._#{field.name}[count++]=Double.parseDouble(#{field.name}String);\n")
					when "byte"
						output.printf("\t\t\t\tobj._#{field.name}[count++]=Byte.parseByte(#{field.name}String);\n")
					when "short"
						output.printf("\t\t\t\tobj._#{field.name}[count++]=Short.parseShort(#{field.name}String);\n")
					when "char"
						output.printf("\t\t\t\tobj._#{field.name}[count++]=#{field.name}String.charAt(0);\n")
					when "float"
						output.printf("\t\t\t\tobj._#{field.name}[count++]=Float.parseFloat(#{field.name}String);\n")
					when "long"		
						output.printf("\t\t\t\tobj._#{field.name}[count++]=Long.parseLong(#{field.name}String);\n")
					else
						raise("Unsupported java-type for #{entry.name}.#{field.name}");
					end
				output.printf("\t\t\t}\n");
			else
				raise("Unsupported data qty for #{entry.name}.#{field.name}");
			end
                    when :intern
                        case field.qty
                        when :single
			check = 1
                            output.printf("\t\t\tElement #{field.name}Element = el.element(\"#{field.name}\");\n");
                            output.printf("\t\t\tif (#{field.name}Element != null)\n");
			    output.printf("\t\t\t\tobj._#{field.name}=#{field.java_type}.xmlRead(#{field.name}Element);\n");
                        when :list, :container
			check = 1
			    output.printf("\t\t\t@SuppressWarnings(\"unchecked\")\n");
			    if field.attribute == :container
				output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.element(\"#{field.name}\").elements(\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\");\n") 
			    else
				output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.elements(\"#{field.name}\");\n")
		            end
          output.printf("\t\t\tobj._#{field.name}=new java.util.ArrayList<#{field.java_type}>(tmp.size());\n");
			    output.printf("\t\t\tfor (Element xmlElement: tmp) {\n");
			    output.printf("\t\t\t\tobj._#{field.name}.add(#{field.java_type}.xmlRead(xmlElement));\n");
			    output.printf("\t\t\t}\n");
			else raise("Unsupported data qty for #{entry.name}.#{field.name}") if field.attribute != :container
                        end
                    else
                        raise("Unsupported data category for #{entry.name}.#{field.name}");
                    end
                else
                    raise("Unsupported data attribute for #{entry.name}.#{field.name}");
                end
	    raise("#{entry.name}.#{field.name} is not manage from java XML reader [qty:#{field.qty},category:#{field.category};attribute:#{field.attribute}]") if (check == 0)
 	    output.printf("\t\t}\n");
	    output.printf("\t\tcatch(Exception ex) {}\n");
            }
            

            entry.fields.each() {|field|
                case field.attribute
                when :sort
			output.printf("\t\tobj.sort_#{field.name}_by_#{field.sort_key}();\n");
		end
	    }

	    output.puts("\t\tCleanup#{params[:uppercase_libname]}ObjectVisitor.instance.visit(obj);\n");
	    output.puts("\t\treturn obj;\n");
	    output.puts("\t}\n\n");
        end
        module_function :write
        
        private
    end
  end
end
