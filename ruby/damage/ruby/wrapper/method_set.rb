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
      module MethodSet
        def write(output, entry, libName, params)
          entry.fields.each() {|field|
            next if field.target != :both
            setStr="static VALUE #{params[:funcPrefix]}_#{field.name}_set(VALUE self, VALUE val)"
            setStrRowip="static VALUE #{params[:funcPrefix]}_#{field.name}_setRowip(VALUE self, VALUE val)"
            aliasFunc="#define #{params[:funcPrefix]}_#{field.name}_setRowip #{params[:funcPrefix]}_#{field.name}_set"
            
            case field.qty
            when :single
              case field.category
              when :simple
                case field.data_type
                when "char*"
                  output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name}) free(ptr->#{field.name});
    ptr->#{field.name} = strdup(StringValuePtr(val));
    return self;
}
");
                when "unsigned long"
                  output.puts("
#{aliasFunc}
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    ptr->#{field.name} = NUM2ULONG(val);
    return self;
}
");              when "double"
                  output.puts("
#{aliasFunc}
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    ptr->#{field.name} = NUM2DBL(val);
    return self;
}
");
                else
                  raise("Unsupported data type #{field.data_type}" )
                end
              when :intern
                output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    __#{libName}_#{field.data_type} *ptr2;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    Data_Get_Struct(val, __#{libName}_#{field.data_type}, ptr2);
    assert(ptr); assert(ptr2);
    ptr->#{field.name} = ptr2;
    return self;
}
");
              end
            when :list, :container
              case field.category
              when :simple
                case field.data_type
                when "char*"
                  output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}){
        for(i = 0; i < ptr->#{field.name}Len; i++){
            free(ptr->#{field.name}[i]);
        }
        free(ptr->#{field.name});
    }
    ptr->#{field.name}Len = RARRAY_LEN(val);
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        ptr->#{field.name}[i] = strdup(StringValuePtr(elnt));
    }
    return self;
}
");

                when "unsigned long"
                  output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}){
        free(ptr->#{field.name});
    }
    ptr->#{field.name}Len = RARRAY_LEN(val);
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        ptr->#{field.name}[i] = NUM2ULONG(elnt);
    }
    return self;
}
#{setStrRowip}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}Len != RARRAY_LEN(val)){
        rb_raise(rb_eArgError, \"Can not set an array of different size\");
    }
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})[i] = NUM2ULONG(elnt);
    }
    return self;
}
");              when "double"
                  output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}){
        free(ptr->#{field.name});
    }
    ptr->#{field.name}Len = RARRAY_LEN(val);
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        ptr->#{field.name}[i] = NUM2DBL(elnt);
    }
    return self;
}
#{setStrRowip}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}Len != RARRAY_LEN(val)){
        rb_raise(rb_eArgError, \"Can not set an array of different size\");
    }
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})[i] = NUM2BDL(elnt);
    }
    return self;
}
");
                else
                  raise("Unsupported data type #{field.data_type}" )
                end
              when :intern
                output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    __#{libName}_#{field.data_type} *elnt, **last;

    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(!ptr->#{field.name}){
        last = &(ptr->#{field.name});
    } else {
        for(elnt = ptr->#{field.name}; elnt->next != NULL; elnt = elnt->next){}
        last = &(elnt->next);
    }
    while(RARRAY_LEN(val) != 0){
        VALUE aElnt = rb_ary_shift(val);
        Data_Get_Struct(aElnt, __#{libName}_#{field.data_type}, elnt);
        *last = elnt;
        last = &(elnt->next);
    }
    return self;
}
");
              end
            end

          }

        end
        module_function :write
      end
    end
  end
end
