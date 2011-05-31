module Damage
  module Ruby
    module Wrapper
      module Memory
        def write(output, entry, libName, params)
          free(output, entry, params)
          wrapper(output, entry, params)
          allocator(output, entry, params)
          initializer(output, entry, params)
        end
        module_function :write
        
        private


        def wrapper(output, entry, params)
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

")
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

")

          end
        end


        def free(output, entry, params)
          output.puts("
/** Free function */
void #{params[:funcPrefix]}_free(#{params[:cType]} *ptr) {
    if(ptr == NULL) return;
    ptr->_private = NULL;
    return;
}
")          
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
/**  Class allocator */
static VALUE #{params[:funcPrefix]}_alloc(VALUE klass) {
    return Data_Wrap_Struct(klass, #{params[:funcPrefix]}_mark, #{params[:funcPrefix]}_free, NULL);
}
")
          if entry.attribute == :listable
          output.puts("
/**  Class allocator */
static VALUE #{params[:funcPrefixList]}_alloc(VALUE klass) {
    return Data_Wrap_Struct(klass, #{params[:funcPrefixList]}_mark, #{params[:funcPrefixList]}_free, NULL);
}
")
          end
        end
        def initializer(output, entry, params)
          output.puts("
/** Object initializer */
static VALUE #{params[:funcPrefix]}_initialize(int argc, VALUE *argv, VALUE self) {
    #{params[:cType]} *ptr = #{params[:cType]}_alloc();
    ptr->_private = (void*) self;
    DATA_PTR(self) = ptr;
    return self;
}
")
          if entry.attribute == :listable
            output.puts("
/** Object initializer */
static VALUE #{params[:funcPrefixList]}_initialize(int argc, VALUE *argv, VALUE self) {
    VALUE parentAdr;
    #{params[:cTypeList]} *ptr;
    #{params[:cType]} *elnt;
    rb_scan_args(argc, argv, \"1\", &parentAdr);

    ptr = malloc(sizeof(*ptr));
    ptr->first = ptr->last = NULL;
    ptr->parent = (#{params[:cType]}**)(NUM2ULONG(parentAdr));
    if(*ptr->parent != NULL){
        ptr->first = *ptr->parent;
        for(elnt = ptr->first; elnt->next; elnt = elnt->next){}
        ptr->last = elnt;
    }
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
