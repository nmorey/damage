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
                        next #FIXME
                        output.printf("\t\ts_%s = NULL;\n", field.name)
                        output.printf("\t\tn_%s = 0UL;\n", field.name)
                    else
                        output.printf("\t\t_%s = %s;\n", field.name, field.java_default_val)
                    end
                    if ((field.qty == :list) && (field.category == :simple || field.category == :enum))
                        output.printf("\t\t_%sLen = 0;\n", field.name) 
                    end
                }

                output.printf("\t\t_next = null;\n")         if entry.attribute == :listable
                output.printf("\t}\n\n")
            end

            module_function :write
        end
    end
end
