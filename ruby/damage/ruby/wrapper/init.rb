module Damage
  module Ruby
    module Wrapper
      module Init
        def write(output, entry, module_name, params)
          output.puts("
/** Class Ruby Damage */
void #{params[:funcPrefix]}_init(void){
    #{params[:classValue]} = rb_define_class_under(#{module_name}, \"#{params[:className]}\", rb_cObject);

    rb_define_alloc_func(#{params[:classValue]}, #{params[:funcPrefix]}_alloc);
    rb_define_method(#{params[:classValue]}, \"initialize\", #{params[:funcPrefix]}_initialize, -1);
    rb_define_method(#{params[:classValue]}, \"to_file\", #{params[:funcPrefix]}_to_file, 1);
    rb_define_singleton_method(#{params[:classValue]}, \"new_file\", #{params[:funcPrefix]}_new_file, -1);
    rb_define_method(#{params[:classValue]}, \"to_s\", #{params[:funcPrefix]}_to_s, 0);
");

          entry.fields.each() {|field|
            next if field.target != :both
            getStr="#{params[:funcPrefix]}_#{field.name}_get"
            setStr="#{params[:funcPrefix]}_#{field.name}_set"

            output.puts("    rb_define_method(#{params[:classValue]}, \"#{field.name}\", #{getStr}, 0);");
            output.puts("    rb_define_method(#{params[:classValue]}, \"#{field.name}=\", #{setStr}, 1);");
          }

          if entry.attribute == :listable
            output.puts("
    #{params[:classValueList]} = rb_define_class_under(#{module_name}, \"#{params[:classNameList]}\", rb_cObject);

    rb_define_alloc_func(#{params[:classValueList]}, #{params[:funcPrefixList]}_alloc);
    rb_define_method(#{params[:classValueList]}, \"initialize\", #{params[:funcPrefixList]}_initialize, -1);
    rb_include_module(#{params[:classValueList]}, rb_mEnumerable);
    rb_define_method(#{params[:classValueList]}, \"[]\", #{params[:funcPrefixList]}_arrayGet, 1);
    rb_define_method(#{params[:classValueList]}, \"each\", #{params[:funcPrefixList]}_arrayEach, 0);
    rb_define_method(#{params[:classValueList]}, \"length\", #{params[:funcPrefixList]}_arrayLength, 0);
    rb_define_method(#{params[:classValueList]}, \"<<\", #{params[:funcPrefixList]}_arrayAdd, 1);

")
          end


          output.puts("
}
");
        end
        module_function :write
      end
    end
  end
end
