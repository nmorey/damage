module Damage
  module Ruby
    module Wrapper
      module MethodGet

        def write(output, entry, libName, params)
          entry.fields.each() {|field|
            getStr="static VALUE #{params[:funcPrefix]}_#{field.name}_get(VALUE self)"
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
")
                when "unsigned long"
                  output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return ULONG2NUM((long)ptr->#{field.name});
}
")            when "double"
                  output.puts("
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