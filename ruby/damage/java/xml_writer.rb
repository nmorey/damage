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
       /*
        * XML writer
        */
       @Override
       protected void xmlWrite(Writer w, int indent) throws IOException {
         indent(w, indent);
         w.write(\"<#{params[:name]} \");
");

        entry.fields.each() {|field|
          case field.attribute
          when :container,:none
            case field.category
            when :simple, :enum, :string,:id, :idref
              case field.qty
              when :single
                output.printf("\t\t/** Writing #{field.name} */\n");
                if field.category == :enum then
                  output.printf("\t\tif (_#{field.name} != #{field.java_type}.N_A) {\n");
                  output.printf("\t\t\tw.write(\"#{field.name}=\\\"\");\n");
                  output.printf("\t\t\tw.write(_#{field.name}.toString());\n");
                  output.printf("\t\t\tw.write(\"\\\" \");\n");
                  output.printf("\t\t}\n");
                else
                  if field.java_type == "String" then
                    output.printf("\t\tif (_#{field.name} != null) {\n");
                    output.printf("\t\t\tw.write(\"#{field.name}=\\\"\");\n");
                    output.printf("\t\t\tw.write(_#{field.name}.toString());\n");
                    output.printf("\t\t\tw.write(\"\\\" \");\n");
                    output.printf("\t\t}\n");
                  else
                    output.printf("\t\tw.write(\"#{field.name}=\\\"\");\n");
                    output.printf("\t\tw.write(String.valueOf(_#{field.name}));\n");
                    output.printf("\t\tw.write(\"\\\" \");\n");
                  end
                end
              end
            end
          end
        }
        output.printf("\t\tw.write(\">\\n\");\n");

        entry.fields.each() {|field|
          case field.attribute
          when :container,:none
            case field.category
            when :simple, :enum, :string,:id, :idref
              case field.qty
              when :single
                # already treated
              when :list
                output.printf("\t\t/** Writing #{field.name} */\n");
                output.printf("\t\tif (_#{field.name} != null) {\n");
                output.printf("\t\t\tfor (#{field.java_type} i: _#{field.name}) {\n");
                output.printf("\t\t\tindent(w, indent==-1?-1:indent+1);\n");
                output.printf("\t\t\tw.write(\"<#{field.name}><![CDATA[\");\n");
                output.printf("\t\t\tw.write(String.valueOf(i));\n");
                output.printf("\t\t\tw.write(\"]]></#{field.name}>\\n\");\n");
                output.printf("\t\t\t}\n");
                output.printf("\t\t}\n");
              end
            when :intern
              case field.qty
              when :single
                output.printf("\t\t/** Writing #{field.name} */\n");
                output.printf("\t\tif (_#{field.name} != null) {\n");
                output.printf("\t\t\t_#{field.name}.xmlWrite(w, indent==-1?-1:indent+1);\n");
                output.printf("\t\t}\n");
              when :list, :container
                if field.attribute == :container
                  output.printf("\t\tif (_#{field.name} != null) {\n");
                  output.printf("\t\t\tindent(w, indent==-1?-1:indent+1);\n");
                  output.printf("\t\t\tw.write(\"<#{field.name}>\\n\");\n");
                  output.printf("\t\t\tfor (#{field.java_type} i: _#{field.name}) {\n");
                  output.printf("\t\t\t\ti.xmlWrite(w, indent==-1?-1:indent+2);\n");
                  output.printf("\t\t\t}\n");
                  output.printf("\t\t\tindent(w, indent==-1?-1:indent+1);\n");
                  output.printf("\t\t\tw.write(\"</#{field.name}>\\n\");\n");
                  output.printf("\t\t}\n");
                else
                  output.printf("\t\tif (_#{field.name} != null) {\n");
                  output.printf("\t\t\tfor (#{field.java_type} i: _#{field.name}) {\n");
                  output.printf("\t\t\t\ti.xmlWrite(w, indent==-1?-1:indent+1);\n");
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

        output.printf("
         indent(w, indent);
         w.write(\"</\");
         w.write(\"#{params[:name]}\");
         w.write(\">\\n\");
         }


");
      end
      module_function :write

      private
    end
  end
end
