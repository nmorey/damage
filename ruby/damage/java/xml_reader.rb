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
			    if field.category == :enum then
				output.printf("\t\tobj._#{field.name}=StrTo#{field.java_type}(el.attributeValue(\"#{field.name}\"));\n");
				else
					case field.java_type
					when "String"
						output.printf("\t\tobj._#{field.name}=el.attributeValue(\"#{field.name}\");\n")
					when "int"
						output.printf("\t\tobj._#{field.name}=Integer.parseInt(el.attributeValue(\"#{field.name}\"));\n")
					when "double"
						output.printf("\t\tobj._#{field.name}=Double.parseDouble(el.attributeValue(\"#{field.name}\"));\n")
					when "byte"
						output.printf("\t\tobj._#{field.name}=Byte.parseByte(el.attributeValue(\"#{field.name}\"));\n")
					when "short"
						output.printf("\t\tobj._#{field.name}=Short.parseShort(el.attributeValue(\"#{field.name}\"));\n")
					when "char"
						output.printf("\t\tobj._#{field.name}=el.attributeValue(\"#{field.name}\").charAt(0);\n")
					when "float"
						output.printf("\t\tobj._#{field.name}=Float.parseFloat(el.attributeValue(\"#{field.name}\"));\n")
					when "long"		
						output.printf("\t\tobj._#{field.name}=Long.parseLong(el.attributeValue(\"#{field.name}\"));\n")
					else
						raise("Unsupported java-type for #{entry.name}.#{field.name}");
					end
				end
			when :list
			check = 1
				output.printf("\t\t{\n\t\t\tStringTokenizer ST=new StringTokenizer(el.elementText(\"#{field.name}\"),\",\");\n");
				output.printf("\t\t\tobj._#{field.name}=new #{field.java_type}[ST.countTokens()];\n");
				output.printf("\t\t\tint count=0;\n");
				output.printf("\t\t\twhile (ST.hasMoreElements()) {\n");
				case field.java_type
					when "String"
						output.printf("\t\tobj._#{field.name}[count++]=el.attributeValue(ST.nextElement().toString());\n")
					when "int"
						output.printf("\t\tobj._#{field.name}[count++]=Integer.parseInt(el.attributeValue(ST.nextElement().toString()));\n")
					when "double"
						output.printf("\t\tobj._#{field.name}[count++]=Double.parseDouble(el.attributeValue(ST.nextElement().toString()));\n")
					when "byte"
						output.printf("\t\tobj._#{field.name}[count++]=Byte.parseByte(el.attributeValue(ST.nextElement().toString()));\n")
					when "short"
						output.printf("\t\tobj._#{field.name}[count++]=Short.parseShort(el.attributeValue(ST.nextElement().toString()));\n")
					when "char"
						output.printf("\t\tobj._#{field.name}[count++]=el.attributeValue(ST.nextElement().toString()).charAt(0);\n")
					when "float"
						output.printf("\t\tobj._#{field.name}[count++]=Float.parseFloat(el.attributeValue(ST.nextElement().toString()));\n")
					when "long"		
						output.printf("\t\tobj._#{field.name}[count++]=Long.parseLong(el.attributeValue(ST.nextElement().toString()));\n")
					else
						raise("Unsupported java-type for #{entry.name}.#{field.name}");
					end
				output.printf("\t\t\t}\n");
				output.printf("\t\t}\n");
			else
				raise("Unsupported data qty for #{entry.name}.#{field.name}");
			end
                    when :intern
                        case field.qty
                        when :single
			check = 1
			    output.printf("\t\tobj._#{field.name}=#{field.java_type}.XmlRead(el.element(\"#{field.name}\"));\n");
                        when :list, :container
			check = 1
                            output.printf("\t\tobj._#{field.name}=new java.util.ArrayList<#{field.java_type}>();\n");
			    output.printf("\t\t\t{\n");
			    if field.attribute == :container
				output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.element(\"#{field.name}\").elements(\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\");\n") 
			    else
				output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.elements(\"#{field.name}\");\n")
		            end
			    output.printf("\t\t\tfor (int i=0;i<tmp.size();i++) {\n");
			    output.printf("\t\t\t\tobj._#{field.name}.add(#{field.java_type}.XmlRead(tmp.get(i)));\n");
			    output.printf("\t\t\t\t}\n");
			    output.printf("\t\t\t}\n");
			else raise("Unsupported data qty for #{entry.name}.#{field.name}") if field.attribute != :container
                        end
                    else
                        raise("Unsupported data category for #{entry.name}.#{field.name}");
                    end
                else
                    raise("Unsupported data attribute for #{entry.name}.#{field.name}");
                end
	    raise("#{entry.name}.#{field.name} is not manage from java Xml reader [qty:#{field.qty},category:#{field.category};attribute:#{field.attribute}]") if (check == 0)
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
