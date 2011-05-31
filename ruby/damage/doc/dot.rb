module Damage
  module Doc
    module Dot
      def write(description)
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/doc/", "#{description.config.libname}.dot")
        genDot(output, description)
        output.close()
      end
      module_function :write

      private
      def genDot(output, description)
        libName = description.config.libname
        output.printf("digraph #{libName} {\n");
        output.printf("compound=true;\n node [shape=plaintext, fontsize=12];\n edge [arrowsize=1, color=\"#666666\", fontsize=10, labeldistance=2];\n");
        description.entries.each() {|name, entry|
          output.printf("%sType [ label=<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\" ALIGN=\"LEFT\">\n", entry.name);
          output.printf("<TR><TD BGCOLOR=\"#000000\" ALIGN=\"LEFT\"><FONT POINT-SIZE=\"14\" COLOR=\"#FFFFFF\">%s</FONT></TD></TR>\n",
                        entry.name);

          entry.fields.each() {|field|
            if(field.target != :mem)
              case field.category
              when :simple
                typeField=": #{field.data_type}"
              else
                typeField=""
              end
              output.printf("<TR><TD PORT=\"%s\">%s%s</TD></TR>\n", field.name, field.name, typeField)
            end
          }
          output.printf("</TABLE>>];\n");
        }
        description.entries.each() {|name, entry|
          entry.fields.each() {|field|
            if(field.target != :mem && field.category == :intern)
              output.printf("%sType:%s -> %sType;\n", entry.name, field.name, field.data_type);
            end
          }
        }
        output.printf("}\n");

      end
      module_function :genDot
    end
  end
end
