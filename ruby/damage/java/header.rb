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
      module Header
        def write(output, libName, entry, pahole, params)
         output.puts("
package #{params[:package]};

public class #{params[:class]} {

")
            entry.fields.each() {|field|
                case field.attribute
                when :sort
                    next #FIXME
                    # output.printf("\t/** Sorted array (index) of \"#{field.sort_field}\" by #{field.sort_key} (not necessary dense) */\n")
                    # output.printf("\tstruct ___#{libName}_#{field.data_type}** s_#{field.name} __#{libName.upcase}_ALIGN__;\n")
                    # output.printf("\t/** Length of the s_#{field.name} array */\n")
                    # output.printf("\tuint32_t n_%s;\n", field.name)
                when :meta,:container,:none
                    case field.category
                    when :simple, :enum, :string
                        case field.qty
                        when :single
                            output.printf("\t/** #{field.description} */\n") if field.description != nil
                            output.printf("\t/** Field is an enum of type #{field.name.slice(0,1).upcase}#{field.name.slice(1..-1)}*/\n") if field.category == :enum
                            output.printf("\t%s %s;\n", field.java_type, field.name)
                        when :list
                            output.printf("\t/** Array of elements #{field.description} */\n")
                            output.printf("\t#{field.data_type}[] #{field.name};\n")
                            output.printf("\t/** Number of elements in the %s array */\n", field.name)
                            output.printf("\tint %sLen ;\n", field.name)
                        end
                    when :intern
                        output.printf("\t/** #{field.description} */\n") if field.description != nil
                        output.printf("\t#{field.java_type} #{field.name};\n")
                    else
                        raise("Unsupported data category for #{entry.name}.#{field.name}");
                    end
                else
                    raise("Unsupported data attribute for #{entry.name}.#{field.name}");
                end
            } 
    
        end
        module_function :write
        
        private
    end
  end
end
