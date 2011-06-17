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
      module MethodGet

        def write(output, entry, libName, params)
          entry.fields.each() {|field|
            getStr="static VALUE #{params[:funcPrefix]}_#{field.name}_get(VALUE self)"
            getStrRowip="static VALUE #{params[:funcPrefix]}_#{field.name}_getRowip(VALUE self)"
            aliasFunc="#define #{params[:funcPrefix]}_#{field.name}_getRowip #{params[:funcPrefix]}_#{field.name}_get"
            next if field.target != :both

            case field.qty
            when :single
              case field.category
              when :simple
                case field.data_type
                when "char*"
                  output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return rb_str_new2(ptr->#{field.name});
}
#{getStrRowip}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return rb_str_new2(__#{libName.upcase}_ROWIP_STR(ptr, #{field.name}));
}
")
                when "unsigned long"
                  output.puts("
#{aliasFunc}
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return ULONG2NUM((long)ptr->#{field.name});
}
")            when "double"
                  output.puts("
#{aliasFunc}
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return rb_float_new((long)ptr->#{field.name});
}
")
                else
                  raise("Unsupported data type #{field.data_type}" )
                end
              when :id, :idref
                getStr_str="static VALUE #{params[:funcPrefix]}_#{field.name}_str_get(VALUE self)"
                getStrRowip_str="static VALUE #{params[:funcPrefix]}_#{field.name}_str_getRowip(VALUE self)"

                   output.puts("
#{getStr_str}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name}_str == NULL)
        return Qnil;
    return rb_str_new2(ptr->#{field.name}_str);
}
#{getStrRowip_str}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name}_str == NULL)
        return Qnil;
    return rb_str_new2(__#{libName.upcase}_ROWIP_STR(ptr, #{field.name}_str));
}
")
                  output.puts("
#{aliasFunc}
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return ULONG2NUM((long)ptr->#{field.name});
}")               
              when :intern
                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return (VALUE)ptr->#{field.name}->_private;
}
#{getStrRowip}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return (VALUE)__#{libName.upcase}_ROWIP_PTR(ptr,#{field.name})->_private;
}
")
              end
            when :list, :container
              case field.category
              when :simple
                case field.data_type
                when "char*"
                  output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, rb_str_new2(ptr->#{field.name}[i]));
    }
    return array;
}
#{getStrRowip}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, rb_str_new2(__#{libName.upcase}_ROWIP_STR_ARRAY(ptr,#{field.name}, i)));
    }
    return array;
}
");

                when "unsigned long"
                  output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, ULONG2NUM(ptr->#{field.name}[i]));
    }
    return array;
}
#{getStrRowip}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, ULONG2NUM(__#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})[i]));
    }
    return array;
}
");            when "double"
                  output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, rb_float_new(ptr->#{field.name}[i]));
    }
    return array;
}
#{getStrRowip}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, rb_float_new(__#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})[i]));
    }
    return array;
}
");

                else
                  raise("Unsupported data type #{field.data_type}" )
                end
              when :intern
                tParams=Damage::Ruby::nameToParams(libName, field.data_type)
                output.puts("
#{getStr}{
    #{params[:cType]} *ptr;
    #{tParams[:cTypeList]}* list;
    #{tParams[:cType]} *elt;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);

    list = malloc(sizeof(*list));
    list->parent = &(ptr->#{field.name});
    list->_private = Qnil;
    if(ptr->#{field.name} != NULL){
        list->first = ptr->#{field.name};
        for(elt = list->first; elt->next != NULL; elt = elt->next){}
        list->last = elt;
    } else {
       list->first = list->last = NULL;
    }
    return #{tParams[:funcPrefixList]}_wrap(list);
}

#{getStrRowip}{
    #{params[:cType]} *ptr;
    #{tParams[:cTypeList]}* list;
    #{tParams[:cType]} *elt;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);

    list = malloc(sizeof(*list));
    list->parent = &(ptr->#{field.name});
    list->_private = Qnil;
    if(ptr->#{field.name} != NULL){
        list->first = __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name});
        for(elt = list->first; elt->next != NULL; elt = __#{libName.upcase}_ROWIP_PTR(elt, next)){}
        list->last = elt;
    } else {
       list->first = list->last = NULL;
    }
    return #{tParams[:funcPrefixList]}_wrapRowip(list);
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
