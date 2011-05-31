module Damage
  module Ruby
    module Wrapper
      module MethodArray
        def write(output, entry, libName, params)
          if entry.attribute == :listable
            output.puts("
static VALUE #{params[:funcPrefixList]}_arrayGet(VALUE self, VALUE idx){
    #{params[:cTypeList]} *ptr;
    #{params[:cType]} *elnt;
    unsigned count, index;

    Data_Get_Struct(self, #{params[:cTypeList]}, ptr);
    assert(ptr);
    index = NUM2INT(idx);

    for(elnt = ptr->first, count=1; elnt && count != index; elnt = elnt->next, count++){}
    if(elnt)
        return (VALUE)elnt->_private;

    return Qnil;
}

static VALUE #{params[:funcPrefixList]}_arrayAdd(VALUE self, VALUE obj){
    #{params[:cTypeList]} *ptr;
    #{params[:cType]} *elnt;

    Data_Get_Struct(self, #{params[:cTypeList]}, ptr);
    Data_Get_Struct(obj, #{params[:cType]}, elnt);
    assert(ptr);

    if(ptr->first == NULL){
        ptr->last = ptr->first = elnt;
        *ptr->parent = elnt;
        return self;
    }

    ptr->last->next = elnt;
    ptr->last = elnt;
    return self;

}

static VALUE #{params[:funcPrefixList]}_arrayEach(VALUE self){
    #{params[:cTypeList]} *ptr;
    #{params[:cType]} *elnt, *next;

    Data_Get_Struct(self, #{params[:cTypeList]}, ptr);
    assert(ptr);

    elnt = ptr->first;
    while(elnt != NULL){
        next = elnt->next;
        rb_yield((VALUE)elnt->_private); 
        elnt = next;
    }
    return self;

}

static VALUE #{params[:funcPrefixList]}_arrayLength(VALUE self){
    #{params[:cTypeList]} *ptr;
    #{params[:cType]} *elnt;
    unsigned long count = 0;
    Data_Get_Struct(self, #{params[:cTypeList]}, ptr);
    assert(ptr);


    for(elnt = ptr->first, count=0; elnt; elnt = elnt->next, count++){}
    return ULONG2NUM(count);

}
")
          end
        end
        module_function :write
      end
    end
  end
end
