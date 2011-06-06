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
  module C
    module Structs

      @OUTFILE = "structs.h"
      def write(description)
        
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE)
        genH(output, description)
        output.close()
      end
      module_function :write
      
      private
      def genH(output, description)
        libPrefix = description.config.libname

        output.printf("#ifndef __#{libPrefix}_structs_h__\n");
        output.printf("#define __#{libPrefix}_structs_h__\n");
        
        description.entries.each() {|name, entry|
          output.printf("typedef struct ___#{libPrefix}_%s {\n", entry.name);
          entry.fields.each() {|field|
            case field.attribute
            when :sort
              output.printf("\tstruct ___#{libPrefix}_%s** s_%s;\n", field.data_type, field.name)
              output.printf("\tunsigned long n_%s;\n", field.name)
            when :pass
              # Do NADA
            when :meta,:container,:none
              case field.category
              when :simple
                case field.qty
                when :single
                  output.printf("\t%s %s;\n", field.data_type, field.name)
                when :list
                  output.printf("\t%s* %s;\n", field.data_type, field.name)
                  output.printf("\tunsigned long %sLen;\n", field.name)
                end

              when :intern
                output.printf("\tstruct ___#{libPrefix}_%s* %s;\n", field.data_type, field.name)
              end

            end

          }        
          output.printf("\tstruct ___#{libPrefix}_%s* next;\n", entry.name) if entry.attribute == :listable
          output.printf("\tvoid* _private;\n");
          output.printf("} __#{libPrefix}_%s;\n\n", entry.name);
        }
        output.printf("\n\n");
        output.printf("#endif /* __#{libPrefix}_structs_h__ */\n");
      end
      module_function :genH
    end
  end
end
