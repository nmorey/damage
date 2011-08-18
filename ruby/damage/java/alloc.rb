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
                uppercaseLibName = libName.slice(0,1).upcase + libName.slice(1..-1)
                output.printf("\t/** Default constructor */\n")
                output.printf("\tpublic #{params[:class]}(){\n")

                entry.fields.each() { |field|
                    case field.attribute
                    when :sort
                        output.printf("\t\t_%s_by_%s = null;\n", field.name, field.sort_key)
                    else
                        output.printf("\t\t_%s = %s;\n", field.name, field.java_default_val)
                    end
                }

                output.printf("\t}\n\n")
                output.printf("\t@Override\n")
                output.printf("\tpublic void visit(I#{uppercaseLibName}ObjectVisitor v) {\n")
                output.printf("\t\tv.visit(this);\n")
                output.printf("\t}\n\n")
                
#                entry.fields.each() { |field|
#                case field.attribute
#                when :sort
#                    next #FIXME
#                    # output.printf("\t/** Sorted array (index) of \"#{field.sort_field}\" by #{field.sort_key} (not necessary dense) */\n")
#                    # output.printf("\tstruct ___#{libName}_#{field.data_type}** s_#{field.name} __#{libName.upcase}_ALIGN__;\n")
#                    # output.printf("\t/** Length of the s_#{field.name} array */\n")
#                    # output.printf("\tuint32_t n_%s;\n", field.name)
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
