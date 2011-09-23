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
        def write(output, entry, libName, params, rowip)
         output.puts("
/*
 * call-seq:
 *   #{params[:className]}.load_xml(filename, options) -> #{params[:className]}
 *
 * Load a #{params[:className]} from a XML file
 *
 * Options can be:
 *   :readonly => File is open in read only mode
 *
 * Usage:
 *   #{params[:className]}.load_xml(\"file.xml\", { :readonly => true }) -> #{params[:className]}
 *   
 */
static VALUE #{params[:funcPrefix]}_load_xml(VALUE klass, VALUE filePath, VALUE mode){

    __#{libName}_options opts;
    #{params[:cType]}* ptr;

    Check_Type(filePath, T_STRING);
    opts = __#{libName}_get_options(mode);

    ptr = __#{libName}_#{entry.name}_xml_load_file(StringValuePtr(filePath), opts);

    if(ptr == NULL)
        rb_raise(rb_eArgError, \"Failed to load XML file\");
    return #{params[:funcPrefix]}_decorate(#{params[:funcPrefix]}_wrap(ptr));
}
")
         output.puts("
/*
 * call-seq:
 *   #{params[:className]}.load_binary(filename, options) -> #{params[:className]}
 *
 * Load a #{params[:className]} from a binary file
 *
 * Options can be:
 *   :readonly => File is open in read only mode
 *   :gzipped  => Binary file is gzipped
 *
 * Usage:
 *   #{params[:className]}.load_binary(\"file.db\", {:gzipped => true}) -> #{params[:className]}
 */
static VALUE #{params[:funcPrefix]}_load_binary(VALUE klass, VALUE filePath, VALUE mode){

    __#{libName}_options opts;
    #{params[:cType]}* ptr;

    Check_Type(filePath, T_STRING);
    opts = __#{libName}_get_options(mode);

    ptr = __#{libName}_#{entry.name}_binary_load_file(StringValuePtr(filePath), opts);

    if(ptr == NULL)
        rb_raise(rb_eArgError, \"Failed to load binary file\");
    if(ptr->_private)
        #{params[:funcPrefix]}_cleanup(ptr);
    return #{params[:funcPrefix]}_decorate(#{params[:funcPrefix]}_wrapFirst(ptr));
}
")
         output.puts("
/*
 * call-seq:
 *   #{params[:className]}.load_binary_rowip(filename, options) -> #{params[:className]}
 *
 * Load a #{params[:className]} from a binary file in place
 *
 * Options can be:
 *   
 *   
 * Usage:
 *   #{params[:className]}.load_binary_rowip(\"file.db\", nil) -> #{params[:className]}
 */
static VALUE #{params[:funcPrefix]}_load_binary_rowip(VALUE klass, VALUE filePath, VALUE mode){

     __#{libName}_options opts;
    #{params[:cType]}* ptr;

    Check_Type(filePath, T_STRING);
    opts = __#{libName}_get_options(mode);

    ptr = __#{libName}_#{entry.name}_binary_load_file_rowip(StringValuePtr(filePath), opts);

    if(ptr == NULL)
        rb_raise(rb_eArgError, \"Failed to load binary file\");
    if(ptr->_private)
        #{params[:funcPrefix]}_cleanupRowip(ptr);
    return #{params[:funcPrefix]}_decorateRowip(#{params[:funcPrefix]}_wrapFirstRowip(ptr));
}
") if rowip == true
        end
        module_function :write
        
        private
      end
    end
  end
end
