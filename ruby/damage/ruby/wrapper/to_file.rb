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
/*
 * call-seq:
 *   #{params[:name]}.to_xml(filename, options)
 *
 * Write the #{params[:className]} to a XML file 
 *
 * Options can be:
 *   :gzipped    => File will be gzipped
 *   :keeplocked => Keep file locked after writing
 *
 * Usage:
 *   #{params[:name]}.to_xml(\"file.xml\", { :gzipped => true })
 *   
 */
static VALUE #{params[:funcPrefix]}_to_xml(VALUE self, VALUE filePath, VALUE mode){
    int ret;
     __#{libName}_options opts;

    Check_Type(filePath, T_STRING);
    opts = __#{libName}_get_options(mode);

    ret = __#{libName}_#{entry.name}_xml_dump_file(StringValuePtr(filePath), DATA_PTR(self), opts);

    if(ret < 0)
        rb_raise(rb_eArgError, \"Could not write XML file\");
    return self;
}
")        

                    output.puts("
/*
 * call-seq:
 *   #{params[:name]}.to_binary(filename, options)
 *
 * Write the #{params[:className]} to a binary file
 *
 * Options can be:
 *   :gzipped    => File will be gzipped
 *   :keeplocked => Keep file locked after writing
 *
 * Usage:
 *   #{params[:name]}.to_binary(\"file.db\", { :gzipped => true, :keeplocked => true })
 *   
 */
static VALUE #{params[:funcPrefix]}_to_binary(VALUE self, VALUE filePath, VALUE mode){
    int ret;
     __#{libName}_options opts;

    Check_Type(filePath, T_STRING);
    opts = __#{libName}_get_options(mode);

    ret = __#{libName}_#{entry.name}_binary_dump_file(StringValuePtr(filePath), DATA_PTR(self), opts);

    if(ret <= 0)
        rb_raise(rb_eArgError, \"Could not write binary file\");
    return self;
}
")

                    output.puts("
/*
 * call-seq:
 *   #{params[:name]}.to_binary_rowip(filename, options)
 *
 * Write the #{params[:classNameRowip]} to a binary file
 *
 * Options can be:
 *   :keeplocked => Keep file locked after writing
 *
 * Usage:
 *   #{params[:name]}.to_binary_rowip(\"file.db\", { :keeplocked => true })
 *   
 */
static VALUE #{params[:funcPrefix]}_to_binary_rowip(int argc, VALUE *argv, VALUE self){
    int ret;
    VALUE mode;
    __#{libName}_options opts;

    rb_scan_args(argc, argv, \"01\", &mode);
    opts = __#{libName}_get_options(mode);

    ret = __#{libName}_#{entry.name}_binary_dump_file_rowip( DATA_PTR(self), opts);

    if(ret <= 0)
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
