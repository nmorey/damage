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
      module Memory
        def write(output, entry, libName, params, rowip)
          free(output, entry, params, rowip)
          wrapper(output, entry, params, rowip)
          allocator(output, entry, params)
          initializer(output, entry, params)
        end
        module_function :write
        
        private


        def wrapper(output, entry, params, rowip)
          output.puts("
/**  Class Wrapper */
VALUE #{params[:funcPrefix]}_wrap(#{params[:cType]}* ptr) {
    VALUE node;
    if(ptr->_private != NULL)
        return (VALUE)ptr->_private;

    node = Data_Wrap_Struct(#{params[:classValue]}, #{params[:funcPrefix]}_mark, #{params[:funcPrefix]}_free, ptr);
    ptr->_private = (void*)node;
    return node;
}
/**  Class Wrapper */
VALUE #{params[:funcPrefix]}_wrapFirst(#{params[:cType]}* ptr) {
    VALUE node;

    node = Data_Wrap_Struct(#{params[:classValue]}, #{params[:funcPrefix]}_mark, #{params[:funcPrefix]}_free, ptr);
    ptr->_private = (void*)node;
    return node;
}
");

output.puts("
/**  Class Wrapper */
VALUE #{params[:funcPrefix]}_wrapRowip(#{params[:cType]}* ptr) {
    VALUE node;
    if(ptr->_private != NULL)
        return (VALUE)ptr->_private;

    node = Data_Wrap_Struct(#{params[:classValueRowip]}, #{params[:funcPrefix]}_markRowip, #{params[:funcPrefix]}_freeRowip, ptr);
    ptr->_private = (void*)node;
    return node;
}
/**  Class Wrapper */
VALUE #{params[:funcPrefix]}_wrapFirstRowip(#{params[:cType]}* ptr) {
    VALUE node;

    node = Data_Wrap_Struct(#{params[:classValueRowip]}, #{params[:funcPrefix]}_markRowip, #{params[:funcPrefix]}_freeRowip, ptr);
    ptr->_private = (void*)node;
    return node;
}

") if rowip == true

          if entry.attribute == :listable
          output.puts("
/**  Class Wrapper */
VALUE #{params[:funcPrefixList]}_wrap(#{params[:cTypeList]}* ptr) {
    VALUE node;
    if(ptr->_private != Qnil)
        return (VALUE)ptr->_private;

    node = Data_Wrap_Struct(#{params[:classValueList]}, #{params[:funcPrefixList]}_mark, #{params[:funcPrefixList]}_free, ptr);
    ptr->_private = node;
    return node;
}
");

output.puts("
/**  Class Wrapper */
VALUE #{params[:funcPrefixList]}_wrapRowip(#{params[:cTypeList]}* ptr) {
    VALUE node;
    if(ptr->_private != Qnil)
        return (VALUE)ptr->_private;

    node = Data_Wrap_Struct(#{params[:classValueListRowip]}, #{params[:funcPrefixList]}_markRowip, #{params[:funcPrefixList]}_free, ptr);
    ptr->_private = node;
    return node;
}

") if rowip == true

          end
        end


        def free(output, entry, params, rowip)
          output.puts("
/** Free function */
void #{params[:funcPrefix]}_free(#{params[:cType]} *ptr) {
    if(ptr == NULL) return;
    ptr->_private = NULL;
    return;
}
")          
             output.puts("
/** Free function */
void #{params[:funcPrefix]}_freeRowip(#{params[:cType]} *ptr) {
    return;
}
") if rowip == true

          if entry.attribute == :listable
          output.puts("
/** Free function */
void #{params[:funcPrefixList]}_free(#{params[:cTypeList]} *ptr) {
    if(ptr == NULL) return;
    ptr->_private = Qnil;
    return;
}
")          
          end
        end
        def allocator(output, entry, params)
          output.puts("
static VALUE #{params[:funcPrefix]}_alloc(VALUE klass) {
    return Data_Wrap_Struct(klass, #{params[:funcPrefix]}_mark, #{params[:funcPrefix]}_free, NULL);
}
")
          if entry.attribute == :listable
          output.puts("
static VALUE #{params[:funcPrefixList]}_alloc(VALUE klass) {
    return Data_Wrap_Struct(klass, #{params[:funcPrefixList]}_mark, #{params[:funcPrefixList]}_free, NULL);
}
")
          end
        end
        def initializer(output, entry, params)
          output.puts("
/*
 * call-seq:
 *   #{params[:className]}.new -> #{params[:className]}
 *
 * Returns a new #{params[:className]}
 */
static VALUE #{params[:funcPrefix]}_initialize(VALUE self) {
    #{params[:cType]} *ptr = #{params[:cType]}_alloc();
    ptr->_private = (void*) self;
    DATA_PTR(self) = ptr;
    return self;
}
")
          if entry.attribute == :listable
            output.puts("
/*
 * call-seq:
 *   #{params[:classNameList]}.new -> #{params[:classNameList]}
 *
 * Returns a new #{params[:classNameList]}
 */
static VALUE #{params[:funcPrefixList]}_initialize(VALUE self) {
    #{params[:cTypeList]} *ptr;

    ptr = malloc(sizeof(*ptr));
    ptr->first = ptr->last = NULL;
    ptr->parent = NULL;
    ptr->_private = self;
    DATA_PTR(self) = ptr;
    return self;
}
")
          end
        end
        module_function :wrapper, :free, :allocator, :initializer
      end
    end
  end
end
