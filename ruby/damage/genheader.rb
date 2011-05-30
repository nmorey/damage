module Damage
  module GenHeader

    def write(description)
      outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/", "#{description.config.libname}.h")
      self.genHeader(outputH, description)
      outputH.close()
      outputH = Damage::Files.createAndOpen("gen/#{description.config.libname}/include/#{description.config.libname}/", "common.h")
      self.genCommonH(outputH, description)
      outputH.close()
    end
    module_function :write


    private
    def genHeader(output, description)  
      libName = description.config.libname

      output.puts("#ifndef __#{libName}_h__")
      output.puts("#define __#{libName}_h__\n")
      output.puts("#include <#{libName}/structs.h>")
      output.puts("#include <#{libName}/alloc.h>")
#      output.puts("#include <#{libName}/structs.h")
      output.puts("#endif /* __#{libName}_h__ */\n")
    end
    module_function :genHeader

    def genCommonH(output, description)
      libName = description.config.libname
output.puts "
#ifndef __#{libName}_common_h__
#define __#{libName}_common_h__

void *__#{libName}_malloc(unsigned long size);
void *__#{libName}_realloc(void *ptr, unsigned long size);
void __#{libName}_free(void *ptr);
int __#{libName}_compare(const char *name, const char *matches[]);
char *__#{libName}_read_value_str(xmlNodePtr reader);
unsigned long __#{libName}_read_value_ulong(xmlNodePtr reader);
double __#{libName}_read_value_double(xmlNodePtr reader);
char *__#{libName}_read_value_str_attr(xmlAttrPtr reader);
unsigned long __#{libName}_read_value_ulong_attr(xmlAttrPtr reader);
double __#{libName}_read_value_double_attr(xmlAttrPtr reader);
int __#{libName}_acquire_flock(const char* filename);
int __#{libName}_release_flock();

#define __#{libName}_error(str, err, arg...) {								\\
		fprintf(stderr, \"error: #{libName}:\" str \"\\n\", ##arg);			\\
		longjmp(__#{libName}_error_happened, err);} while(0)

extern jmp_buf __#{libName}_error_happened;
extern int __#{libName}_line;
#endif /* __#{libName}_common_h__ */
"
    end
    module_function :genCommonH
  end
end
