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
            module ToFile
                def write(output, entry, libName, params, rowip)
                    output.puts("
static VALUE #{params[:funcPrefix]}_to_xml(VALUE self, VALUE filePath){
    int ret;
    Check_Type(filePath, T_STRING);

    ret = __#{libName}_#{entry.name}_xml_dump_file(StringValuePtr(filePath), DATA_PTR(self), 1, 1);

    if(ret < 0)
        rb_raise(rb_eArgError, \"Could not write XML file\");
    return self;
}
")        
                    output.puts("
static VALUE #{params[:funcPrefix]}_to_xmluz(VALUE self, VALUE filePath){
    int ret;
    Check_Type(filePath, T_STRING);

    ret = __#{libName}_#{entry.name}_xml_dump_file(StringValuePtr(filePath), DATA_PTR(self), 0, 1);

    if(ret < 0)
        rb_raise(rb_eArgError, \"Could not write XML file\");
    return self;
}
")
                    output.puts("
static VALUE #{params[:funcPrefix]}_to_binary(VALUE self, VALUE filePath){
    int ret;
    Check_Type(filePath, T_STRING);

    ret = __#{libName}_#{entry.name}_binary_dump_file(StringValuePtr(filePath), DATA_PTR(self), 1);

    if(ret < 0)
        rb_raise(rb_eArgError, \"Could not write binary file\");
    return self;
}
")

                    output.puts("
static VALUE #{params[:funcPrefix]}_to_binary_rowip(VALUE self){
    int ret;

    ret = __#{libName}_#{entry.name}_binary_dump_file_rowip( DATA_PTR(self), 1);

    if(ret < 0)
        rb_raise(rb_eArgError, \"Could not write binary file\");
    return self;
}
") if rowip == true
                end
                module_function :write
                
                private
            end
        end
    end
end
