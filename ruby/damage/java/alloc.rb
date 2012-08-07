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
        module Alloc
            
            def write(output, libName, entry, pahole, params)
                output.printf("\t/** Default constructor */\n")
                output.printf("\tpublic #{params[:class]}(){\n")

                entry.fields.each() { |field|
                    case field.attribute
                    when :sort
                        output.printf("\t\t_%s_by_%s = null;\n", field.sort_field, field.sort_key)
                    else
                        output.printf("\t\t_%s = %s;\n", field.name, field.java_default_val)
                    end
                }

                output.printf("\t}\n\n")
                output.printf("\t@Override\n")
                output.printf("\tpublic void visit(I#{params[:uppercase_libname]}ObjectVisitor v) {\n")
                output.printf("\t\tv.visit(this);\n")
                output.printf("\t}\n\n")
                
                entry.fields.each() { |field|
                  case field.attribute
                  when :sort
                    output.printf("\t/** Sort #{field.sort_field}\ by #{field.sort_key} */\n")
                    output.printf("\tpublic void sort_#{field.sort_field}_by_#{field.sort_key}() {\n")
                    output.printf("\t\tif (_#{field.sort_field}_by_#{field.sort_key} == null) {\n")
                    output.printf("\t\t\t_#{field.sort_field}_by_#{field.sort_key} = new java.util.HashMap<Integer, #{field.java_type}>();\n")
                    output.printf("\t\t} else {\n")
                    output.printf("\t\t\t_#{field.sort_field}_by_#{field.sort_key}.clear();\n")
                    output.printf("\t\t}\n")
                    output.printf("\t\tfor (#{field.java_type} obj: _#{field.sort_field}) {\n")
                    output.printf("\t\t\t_#{field.sort_field}_by_#{field.sort_key}.put(obj._#{field.sort_key}, obj);\n")
                    output.printf("\t\t}\n")
                    output.printf("\t}\n\n")
                  end
                }
                
#                when :meta,:container,:none
#                    case field.category
#                    when :simple, :enum, :string
#                        case field.qty
#                        when :single
#                            output.printf("\t/** #{field.description} */\n") if field.description != nil
#                            output.printf("\tpublic %s get_%s() {\n", field.java_type, field.name)
#                            output.printf("\t\treturn %s;\n", field.name)
#                            output.printf("\t}\n")
#
#                            output.printf("\t/** #{field.description} */\n") if field.description != nil
#                            output.printf("\tpublic void set_%s(%s value) {\n", field.name, field.java_type)
#                            output.printf("\t\t%s = value;\n", field.name)
#                            output.printf("\t}\n")
#                        when :list
#                            output.printf("\t/** Array of elements #{field.description} */\n")
#                            output.printf("\tprivate #{field.java_type}[] _#{field.name};\n")
#                        end
#                    when :intern
#                        output.printf("\t/** #{field.description} */\n") if field.description != nil
#                        if field.qty == :single
#                            output.printf("\tprivate #{field.java_type} _#{field.name};\n")
#                        else
#                            output.printf("\tprivate java.util.List<#{field.java_type}> _#{field.name};\n")
#                        end
#                        output.printf("\t/** Offset of the element in DB file (valid after partial load and _#{field.name} is nil */\n");
#                        output.printf("\tprivate int _#{field.name}_offset;\n");
#                    else
#                        raise("Unsupported data category for #{entry.name}.#{field.name}");
#                    end
#                else
#                    raise("Unsupported data attribute for #{entry.name}.#{field.name}");
#                end
#                }
              end

            module_function :write
        end
    end
end
