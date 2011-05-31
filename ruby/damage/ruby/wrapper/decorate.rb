module Damage
  module Ruby
    module Wrapper
      module Decorate
        def write(output, entry, libName, params)
         output.puts("
/** Link C subtree to Ruby classes */
VALUE #{params[:funcPrefix]}_decorate(VALUE self){
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    ptr->_private = (void*)self;
");
        entry.fields.each() { |field|
            next if field.target != :both
          if field.category == :intern 
            tParams = Damage::Ruby::nameToParams(libName, field.data_type)
            if field.qty == :list || field.qty == :container
              output.puts("
    { __#{libName}_#{field.data_type}* elt;
        for(elt = ptr->#{field.name}; elt; elt = elt->next){
            #{tParams[:funcPrefix]}_decorate(#{tParams[:funcPrefix]}_wrap(elt));
        }
    }

");
            elsif field.qty == :single
              output.puts("
        if(ptr->#{field.name}) #{tParams[:funcPrefix]}_decorate(#{tParams[:funcPrefix]}_wrap(ptr->#{field.name}));
");
            end
          end
        }
        output.puts("
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
