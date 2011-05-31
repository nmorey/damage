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
      module NewFile
        def write(output, entry, libName, params)
         output.puts("
/** Load from XML */
static VALUE #{params[:funcPrefix]}_new_file(int argc, VALUE *argv, VALUE klass){

    VALUE filePath;
    #{params[:cType]}* ptr;
    rb_scan_args(argc, argv, \"1\", &filePath);
    Check_Type(filePath, T_STRING);
    ptr = __#{libName}_#{entry.name}_xml_parse_file(StringValuePtr(filePath));

    if(ptr == NULL)
        rb_raise(rb_eArgError, \"Failed to load XML file\");
    return #{params[:funcPrefix]}_decorate(#{params[:funcPrefix]}_wrap(ptr));
}
")
        end
        module_function :write
        
        private
      end
    end
  end
end
