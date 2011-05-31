module Damage
  module Ruby
    module Wrapper
      module Header
        def write(output, entry, libName, params)
         output.puts("
#include <ruby.h>
#include <libxml/xmlreader.h>
#include <#{libName}.h>
#include <setjmp.h>
#include <#{libName}/common.h>
#include <assert.h>
#include \"ruby_#{libName}.h\"

/** Global class type for the file */
VALUE #{params[:classValue]};

extern VALUE #{libName};

");
          if entry.attribute == :listable
output.puts("
/** Global class type List for the file */
VALUE #{params[:classValue]}List;

")
          end
        end
        module_function :write
        
        private
      end
    end
  end
end
