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
        module Header

            def write(description)
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/", "#{description.config.libname}.h")
                self.genHeader(output, description)
                output.close()
            end
            module_function :write


            private
            def genHeader(output, description)  
                libName = description.config.libname

                output.puts("#ifndef __#{libName}_h__")
                output.puts("#define __#{libName}_h__\n")
                output.puts("#include <stdio.h>")
                output.puts("#include <stdint.h>")
                output.puts("#include <libxml/tree.h>")
                output.puts("#include <#{libName}/enum.h>")
                output.puts("#include <#{libName}/structs.h>")
                output.puts("#include <#{libName}/alloc.h>")
                output.puts("#include <#{libName}/sort.h>")
                output.puts("#include <#{libName}/xml_reader.h>")
                output.puts("#include <#{libName}/xml_writer.h>")
                output.puts("#include <#{libName}/binary_reader.h>")
                output.puts("#include <#{libName}/binary_writer.h>")
                output.puts("#include <#{libName}/binary_rowip.h>")
                description.config.hfiles.each() {|hfile|
                    output.puts("#include <#{libName}/#{hfile}>");
                }
                output.puts("#endif /* __#{libName}_h__ */\n")
            end
            module_function :genHeader

        end
    end
end
