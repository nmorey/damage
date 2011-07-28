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
        module Dump
            
            def write(output, libName, entry, pahole, params)
                output.printf("\tprivate void indentToString(int indent, boolean listable, boolean first){\n")
                output.printf("\t\tfor(int i = 0; i < indent; ++i){;\n")
                output.printf("\t\t\tSystem.out.print(\"\\t\");\n")
                output.printf("\t\t}\n")
                output.printf("\t\tif(listable == true){\n")
                output.printf("\t\t\tif(first == true){\n")
                output.printf("\t\t\t\tSystem.out.print(\"- \");\n")
                output.printf("\t\t\t} else {\n")
                output.printf("\t\t\t\tSystem.out.print(\"  \");\n")
                output.printf("\t\t\t}\n")
                output.printf("\t\t}\n")
                output.printf("\t}\n")


                output.printf("\tvoid dumpWithIndent(int indent){\n")
                output.printf("\t\tboolean first = true;\n");

                if entry.attribute == :listable then
                    output.puts("\t\tboolean listable = true;")
                else
                    output.puts("\t\tboolean listable = false;")
                end
                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple
                            output.printf("\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\tfirst = false;\n")
                            output.printf("\t\tSystem.out.println(\"#{field.name}: \" + this._#{field.name});\n");
                        when :enum
                            output.printf("\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\tfirst = false;\n")
                            output.printf("\t\tSystem.out.println(\"#{field.name}: \" + " +
                                          " #{params[:class]}._#{field.name}_strings[#{params[:class]}." +
                                          "#{field.java_type.slice(0,1).downcase + field.java_type.slice(1..-1)}"+
                                          "ToId(this._#{field.name})]);\n");
                        when :string
                            output.printf("\t\tif(this._#{field.name} != null){\n");
                            output.printf("\t\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\t\tfirst = false;\n")
                            output.printf("\t\t\tSystem.out.println(\"#{field.name}: \\\"\" + this._#{field.name} + \"\\\"\");\n");
                            output.printf("\t\t}\n");
                        when :intern
                            output.printf("\t\tif(this._#{field.name} != null){\n");
                            output.printf("\t\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\t\tfirst = false;\n")
                            output.printf("\t\t\tSystem.out.println(\"#{field.name}: \");\n");
                            output.printf("\t\t\tthis._#{field.name}.dumpWithIndent(indent+1);\n");
                            output.printf("\t\t}\n");




                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                        when :simple
                            output.printf("\t\t{\n");
                            output.printf("\t\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\t\tfirst = false;\n")
                            output.printf("\t\t\tSystem.out.println(\"#{field.name}:\");\n");
                            output.printf("\t\t\tfor(int i = 0; i < this._#{field.name}.length; i++){\n");
                            output.printf("\t\t\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\t\t\tSystem.out.println(this._#{field.name}[i]);\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                        when :string
                            output.printf("\t\t{\n");
                            output.printf("\t\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\t\tfirst = false;\n")
                            output.printf("\t\t\tSystem.out.println(\"#{field.name}:\");\n");
                            output.printf("\t\t\tfor(int i = 0; i < this._#{field.name}.length; i++){\n");
                            output.printf("\t\t\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\t\t\tSystem.out.println(\"\\\"\" + this._#{field.name}[i] + \"\\\"\");\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                        when :intern
                            output.printf("\t\t{\n");
                            output.printf("\t\t\tindentToString(indent, listable, first);\n")
                            output.printf("\t\t\tfirst = false;\n")
                            output.printf("\t\t\tSystem.out.println(\"#{field.name}:\");\n");
                            output.printf("\t\t\tfor(#{field.java_type} el = this._#{field.name}; el != null; el = el._next){\n");
                            output.printf("\t\t\t\tel.dumpWithIndent(indent+1);\n");
                            output.printf("\t\t\t}\n");
                            output.printf("\t\t}\n");
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end                  
                    else
                        raise("Unsupported quantitiy for #{entry.name}.{field.name}")
                    end
                }

                output.printf("\t}\n\n")
                output.printf("\tpublic void dump(){\n")
                output.printf("\t\tSystem.out.println(\"#{entry.name}:\");\n")
                output.printf("\t\tthis.dumpWithIndent(1);\n")
                output.printf("\t}\n\n")
         end


            module_function :write
        end
    end
end
