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
            module MethodCompare

                def write(output, entry, libName, params)
                    output.puts("static VALUE #{params[:funcPrefix]}_compare_list(VALUE self, VALUE other) {")
                    output.puts("\tint ret;")
                    output.puts("\tCheck_Type(self, rb_type(other));")
                    output.puts("\tret = __#{libName}_#{entry.name}_compare_list(DATA_PTR(self), DATA_PTR(other));")
                    output.puts("\treturn ret?Qtrue:Qfalse;\n}")
                end
                module_function :write
            end
        end
    end
end
