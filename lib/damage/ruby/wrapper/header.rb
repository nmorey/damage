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
    module Wrapper
      module Header
        def write(output, entry, libName, params, rowip)
         output.puts("
#include <ruby.h>
#include <libxml/xmlreader.h>
#include <#{libName}.h>
#include <setjmp.h>
#include <_#{libName}/_common.h>
#include <assert.h>
#include \"ruby_#{libName}.h\"

extern VALUE #{params[:moduleName]};


/** Global class type for the file */
VALUE #{params[:classValue]};
");
output.puts("
/** Global class type for the file in Rowip Mode */
VALUE #{params[:classValueRowip]};
") if rowip == true


          if entry.attribute == :listable
output.puts("
/** Global class type List for the file */
VALUE #{params[:classValueList]};
");

output.puts("
/** Global class type List for the file in Rowip Mode */
VALUE #{params[:classValueListRowip]};
") if rowip == true
          end
            entry.enums.each(){|field|
                output.puts("#{entry.attribute == :enum ? "" : "static"} ID #{entry.name}_#{field.name}_enumId[#{field.enum.length + 1}];")
                
            }
        end
        module_function :write
        
        private
      end
    end
  end
end
