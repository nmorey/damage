module Damage
  module Ruby
    module Wrapper
      module MethodSet
        def write(output, entry, libName, params)
          entry.fields.each() {|field|
            next if field.target != :both
            setStr="static VALUE #{params[:funcPrefix]}_#{field.name}_set(VALUE self, VALUE val)"
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
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    ptr->#{field.name} = NUM2ULONG(val);
    return self;
}
");              when "double"
                  output.puts("
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