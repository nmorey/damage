module Damage
  module Ruby
    module Global


      def write(description)
        libName = description.config.libname
        outdir = "gen/#{libName}/ruby/"
        outputH = Damage::Files.createAndOpen(outdir, "ruby_#{libName}.h")
        outputC = Damage::Files.createAndOpen(outdir, "ruby_#{libName}.c")
        genGlobH(outputH, description)
        genGlobC(outputC, description, libName)
        outputC.close()
        outputH.close()
      end
      module_function :write


      #Generate Headers
      private
      def genGlobH(output, description)
        libName = description.config.libname

        description.entries.each(){ |name, entry|
          params=Damage::Ruby::nameToParams(libName, entry.name)

          output.puts("void #{params[:funcPrefix]}_init();");
          output.puts("VALUE #{params[:funcPrefix]}_wrap(#{params[:cType]}* ptr);");
          output.puts("VALUE #{params[:funcPrefix]}_decorate(VALUE self);\n\n");
          output.puts("VALUE #{params[:funcPrefix]}_xml_to_string(VALUE self, int indent);\n");
          if entry.attribute == :listable
            output.puts("
typedef struct {
    #{params[:cType]} **parent;
    #{params[:cType]} *first;
    #{params[:cType]} *last;
    VALUE _private;
} #{params[:cTypeList]};


VALUE #{params[:funcPrefixList]}_wrap(#{params[:cTypeList]}* ptr);
VALUE #{params[:funcPrefixList]}_decorate(VALUE self);

")
            end
        }
        output.puts("
VALUE indentToString(VALUE string, int indent);
");
      end


      # Generate the main loader file
      def genGlobC(output, description, module_name)
        libName = description.config.libname
        output.puts("
#include <ruby.h>
#include <#{libName}.h>
#include \"ruby_#{libName}.h\"

VALUE #{libName};

VALUE indentToString(VALUE string, int indent){
    char str[256], *ptr;
    int i;
    ptr=str;
    if(indent == 0)
        return string;
    for(i = 0; i< indent; i++){
        ptr += sprintf(ptr, \"\\t\");
    }
    return rb_str_concat(string, rb_str_new2(strdup(str)));
}
void Init_lib#{libName}_ruby(){
    #{libName} = rb_define_module(\"#{libName}\");

");
        description.entries.each(){ |name, entry|
          params=Damage::Ruby::nameToParams(libName, entry.name)
          output.puts("    #{params[:funcPrefix]}_init();");
        }
        output.puts("}");
      end
      module_function :genGlobH, :genGlobC

    end
  end
end
