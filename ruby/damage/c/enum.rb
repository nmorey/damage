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
        module Enum

            @OUTFILE = "enum.h"
            def write(description)
                
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE)
                genH(output, description)
                output.close()
            end
            module_function :write
            

            private

            def genEnum(output, libName, entry)


                entry.fields.each() {|field|
                    if field.category == :enum then
                        enumPrefix="__#{libName.upcase}_#{entry.name.upcase}_#{field.name.upcase}"
                        output.printf("typedef enum {\n");
                        output.printf("\t#{enumPrefix}_N_A = 0,\n")
                        count = 1;
                        sep="\t"
                        field.enum.each() { |str, val|
                            output.printf("#{sep}#{enumPrefix}_#{val} = #{count}")
                            count+=1
                            sep=",\n\t"
                        }
                        output.printf("\n} #{enumPrefix};\n\n");
                    end

                }       

            end
            module_function :genEnum

            def genH(output, description)
                libName = description.config.libname

                output.printf("#ifndef __#{libName}_enum_h__\n");
                output.printf("#define __#{libName}_enum_h__\n");
                
                description.entries.each() {|name, entry|
                    genEnum(output, libName, entry)

                }
                output.printf("\n\n");
                output.printf("#endif /* __#{libName}_enu_h__ */\n");
            end
            module_function :genH
        end
    end
end
