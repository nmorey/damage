module Damage
  module Ruby
    module Wrapper
      module Mark
        def write(output, entry, libName, params)
          output.puts("
/** Mark function */
void #{params[:funcPrefix]}_mark(#{params[:cType]} *ptr) {
    if(ptr == NULL) return;
");
          # Look for children and mark them
          
          entry.fields.each() { |field|
            next if field.target != :both
            if field.category == :intern 
              if field.qty == :list || field.qty == :container
                output.puts("
    { __#{libName}_#{field.data_type}* elt;
        for(elt = ptr->#{field.name}; elt; elt = elt->next)
            if(elt->_private != NULL) {
                rb_gc_mark((VALUE) elt->_private);
            }
    }
")
              elsif field.qty == :single
                output.puts("
    { if(ptr->#{field.name})
            if(ptr->#{field.name}->_private != NULL) {
                rb_gc_mark((VALUE) ptr->#{field.name}->_private);
            }
    }
");
              end
            end
          }
          output.puts("
}
");
          if entry.attribute == :listable
            output.puts("
/** Mark function */
void #{params[:funcPrefixList]}_mark(#{params[:cTypeList]} *ptr) {
    #{params[:cType]} *elnt;
    if(ptr == NULL) return;
    for(elnt = ptr->first; elnt; elnt = elnt->next){
        if(elnt->_private != NULL) rb_gc_mark((VALUE)elnt->_private);
    }
    return;
}
");
          end

        end
        module_function :write
        
        private
      end
    end
  end
end
