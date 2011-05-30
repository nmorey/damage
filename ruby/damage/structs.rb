module Damage
  module Structs

    @OUTFILE = "structs.h"
    def write(description)
      
      output = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}", @OUTFILE)
      genH(output, description)
      output.close()
    end
    module_function :write
    
    private
    def genH(output, description)
      libPrefix = description.config.libname

      output.printf("#ifndef __#{libPrefix}_structs_h__\n");
      output.printf("#define __#{libPrefix}_structs_h__\n");
      
      description.entries.each() {|name, entry|
        output.printf("typedef struct ___#{libPrefix}_%s {\n", entry.name);
        entry.fields.each() {|field|
          case field.attribute
          when :sort
            output.printf("\tstruct ___#{libPrefix}_%s* s_%s;\n", field.data_type, field.name)
            output.printf("\tunsigned long n_%s;\n", field.name)
          when :pass
            # Do NADA
          when :meta,:container,:none
            case field.category
            when :simple
              case field.qty
              when :single
                output.printf("\t%s %s;\n", field.data_type, field.name)
              when :list
                output.printf("\t%s* %s;\n", field.data_type, field.name)
                output.printf("\tunsigned long %sLen;\n", field.name)
              end

            when :intern
              output.printf("\tstruct ___#{libPrefix}_%s* %s;\n", field.data_type, field.name)
            end

          end

        }        
        output.printf("\tstruct ___#{libPrefix}_%s* next;\n", entry.name) if entry.attribute == :listable
        output.printf("\tvoid* _private;\n");
        output.printf("} __#{libPrefix}_%s;\n\n", entry.name);
      }
      output.printf("\n\n");
      topStruct = description.top_entry
      output.printf("typedef __#{libPrefix}_%s __#{libPrefix}_tree;\n", topStruct.name);
      output.printf("__#{libPrefix}_tree *__#{libPrefix}_parse(const char *file);\n\n", topStruct.name);
      output.printf("int __#{libPrefix}_dumpXML(const char *file, __#{libPrefix}_tree* ptr);\n\n", topStruct, topStruct);
      output.printf("void __#{libPrefix}_tree_free(__#{libPrefix}_tree *ptr);\n\n");
      output.printf("#endif /* __#{libPrefix}_structs_h__ */\n");
    end
    module_function :genH
  end
end
