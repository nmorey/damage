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
        module Offset
            def write(output, libName, entry, pahole, params)
                output.puts("
\t/** Compute object offset in binary file */
\tpublic int computeOffset(int offset){
\t\tint cur_offset = offset;
\t\tthis.__binary_offset = cur_offset;
\t\tcur_offset += #{pahole[:size]};
")
                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple, :enum, :genum
                        when :string
                            output.printf("\t\tcur_offset += computeStringLength(this._#{field.name});\n")
                        when :intern
                            output.printf("\t\tif(this._%s != null){\n", field.name)
                            output.printf("\t\t\tcur_offset = this._%s.computeOffset(cur_offset);\n", 
                                          field.data_type, field.name)
                            output.printf("\t\t}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                        when :simple
                            output.printf("\t\tif(this._%s != null){\n", field.name)
                            output.printf("\t\t\tcur_offset += (#{field.type_size} * this._%s.length);\n",
                                          field.name)
                            output.printf("\t\t}\n")
                        when :string
                            output.printf("\t\tcur_offset += computeStringArrayLength(this._#{field.name});\n")
                        when :intern
                            output.printf("\t\tfor (#{field.java_type} i: _#{field.name}) {\n")
                            output.printf("\t\t\tcur_offset = i.computeOffset(cur_offset);\n", 
                                          field.data_type, field.name)
                            output.printf("\t\t}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    end
                }
                output.puts("
\t\treturn cur_offset;
\t}\n\n");
            end
            module_function :write
            
            private
        end
    end
end
