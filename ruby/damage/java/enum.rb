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
      module Enum
        def write(output, libName, entry, pahole, params)
            entry.fields.each() {|field|
                next if field.category != :enum
                output.printf("
\t/**
\t * Match an int (C equivalent) ##{field.java_type} value 
\t */
")
                output.printf("\tpublic static #{field.java_type} idTo#{field.java_type}(int value) "+
                              "throws IndexOutOfBoundsException{\n");
                output.printf("\t\tswitch(value){\n")
                output.printf("\t\t\tcase 0: return #{field.java_type}.N_A;\n")
                count = 1;
                field.enum.each() { |str, val|
                    output.printf("\t\t\tcase #{count}: return #{field.java_type}.#{val};\n")
                    count+=1
                }
                output.printf("\t\t\tdefault: throw new IndexOutOfBoundsException();\n")
                output.printf("\t\t}\n");
                output.printf("\t}\n\n");

                output.printf("
\t/**
\t * Match a ##{field.java_type} value to an int (C equivalent) 
\t */
")
                output.printf("\tpublic static int "+
                              "#{field.java_type.slice(0,1).downcase + field.java_type.slice(1..-1)}ToId(#{field.java_type} value) "+
                              "throws IndexOutOfBoundsException{\n");
                output.printf("\t\tswitch(value){\n")
                output.printf("\t\t\tcase N_A: return 0;\n")
                count = 1;
                field.enum.each() { |str, val|
                    output.printf("\t\t\tcase #{val}: return #{count};\n")
                    count+=1
                }
                output.printf("\t\t\tdefault: throw new IndexOutOfBoundsException();\n")
                output.printf("\t\t}\n");
                output.printf("\t}\n\n");
            }

            output.puts("\n\n");
        end
        module_function :write
        
        private
    end
  end
end
