module Damage
  module Ruby
    module Wrapper
      module ToFile
        def write(output, entry, libName, params)
         output.puts("
static VALUE #{params[:funcPrefix]}_to_file(VALUE self, VALUE filePath){
    int ret;
    Check_Type(filePath, T_STRING);

    ret = __#{libName}_#{entry.name}_xml_dump_file(StringValuePtr(filePath), DATA_PTR(self));

    if(ret < 0)
        rb_raise(rb_eArgError, \"Could not write XML file\");
    return self;
}
")
        end
        module_function :write
        
        private
      end
    end
  end
end
