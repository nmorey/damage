module Damage
  module Ruby
    module Wrapper
      module NewFile
        def write(output, entry, libName, params)
         output.puts("
/** Load from XML */
static VALUE #{params[:funcPrefix]}_new_file(int argc, VALUE *argv, VALUE klass){

    VALUE filePath;
    #{params[:cType]}* ptr;
    rb_scan_args(argc, argv, \"1\", &filePath);
    Check_Type(filePath, T_STRING);
    ptr = __#{libName}_#{entry.name}_xml_parse_file(StringValuePtr(filePath));

    if(ptr == NULL)
        rb_raise(rb_eArgError, \"Failed to load XML file\");
    return #{params[:funcPrefix]}_decorate(#{params[:funcPrefix]}_wrap(ptr));
}
")
        end
        module_function :write
        
        private
      end
    end
  end
end
