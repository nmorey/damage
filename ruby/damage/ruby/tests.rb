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
  module Ruby
    module Tests

      def write(description)
        output = Damage::Files.createAndOpen("gen/#{description.config.libname}/test/", "create_dump_and_reload.rb")
        self.genTest1(output, description)
        output.close()
      end
      module_function :write

      private
      def genTest1(output, description)  
        libName = description.config.libname
        moduleName= description.config.libname.slice(0,1).upcase + description.config.libname.slice(1..-1)

        output.puts "
#!/usr/bin/ruby

$LOAD_PATH.push( File.dirname(__FILE__) + \"/../ruby/\")
require 'lib#{libName}_ruby'

"
        description.entries.each() { |name, entry|
          params = Damage::Ruby::nameToParams(libName, name)
          output.puts "def create#{params[:className]}(first=1)
\tptr = #{moduleName}::#{params[:className]}.new()"
          entry.fields.each() { |field|
            if field.target == :both && field.category == :intern then
              paramsT = Damage::Ruby::nameToParams(libName, field.data_type)
              if field.qty == :single
                output.puts "\tptr.#{field.name} = create#{paramsT[:className]}()"
              else
                output.puts "\tptr.#{field.name} << create#{paramsT[:className]}()"
              end
            end
          }
#          if entry.attribute == :listable then
#            output.puts "\tif(first)"
#            output.puts "\t\tptr->next = create#{entry.name}(0);"
#          end

          output.puts "
\treturn ptr
end
"
        }
        output.puts "

	ptr = create#{description.top_entry.name}()

    ptr.to_file(ARGV[0])
#	__#{libName}_#{description.top_entry.name}_free(ptr);

	ptr = #{moduleName}::#{description.top_entry.name}.new_file(ARGV[0])

"
      end
      module_function :genTest1
    end
  end
end
