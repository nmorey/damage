# Copyright (C) 2011  Nicolas Morey-Chaisemartin <nicolas@morey-chaisemartin.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Damage
    module Ruby
        module Wrapper
            module Init
                def write(output, entry, module_name, params)
                    output.puts("

/*
 * Ruby class for #{entry.name} structure
 *
 * #{entry.description}
 */
static
void Init_#{params[:className]}(void){
    #{params[:classValue]} = rb_define_class_under(#{params[:moduleName]}, \"#{params[:className]}\", rb_cObject);
    rb_define_alloc_func(#{params[:classValue]}, #{params[:funcPrefix]}_alloc);
    rb_define_method(#{params[:classValue]}, \"initialize\", #{params[:funcPrefix]}_initialize, -1);
    rb_define_method(#{params[:classValue]}, \"to_binary\", #{params[:funcPrefix]}_to_binary, 1);
    rb_define_method(#{params[:classValue]}, \"to_xml\", #{params[:funcPrefix]}_to_xml, 1);
    rb_define_method(#{params[:classValue]}, \"==\", #{params[:funcPrefix]}_compare_list, 1);
    rb_define_method(#{params[:classValue]}, \"to_xmluz\", #{params[:funcPrefix]}_to_xmluz, 1);
    rb_define_singleton_method(#{params[:classValue]}, \"load_xml\", #{params[:funcPrefix]}_load_xml, -1);
    rb_define_singleton_method(#{params[:classValue]}, \"load_binary\", #{params[:funcPrefix]}_load_binary, -1);
    rb_define_method(#{params[:classValue]}, \"to_s\", #{params[:funcPrefix]}_to_s, 0);
")
                    entry.fields.each() {|field|
                        next if field.target != :both
                        getStr="#{params[:funcPrefix]}_#{field.name}_get"
                        setStr="#{params[:funcPrefix]}_#{field.name}_set"

                        output.puts("    rb_define_method(#{params[:classValue]}, \"#{field.name}\", #{getStr}, 0);");
                        output.puts("    rb_define_method(#{params[:classValue]}, \"#{field.name}=\", #{setStr}, 1);");
                        if ((field.category == :id) || (field.category == :idref))
                            getStr_str="#{params[:funcPrefix]}_#{field.name}_str_get"
                            setStr_str="#{params[:funcPrefix]}_#{field.name}_str_set"
                            output.puts("    rb_define_method(#{params[:classValue]}, \"#{field.name}_str\", #{getStr_str}, 0);");
                            output.puts("    rb_define_method(#{params[:classValue]}, \"#{field.name}_str=\", #{setStr_str}, 1);");
                        end
                    }
                    output.puts("
}

/*
 * Ruby class for #{entry.name} structure in ROWIP (Read or Write In Place)
 *
 * #{entry.description}
 */
static
void Init_#{params[:classNameRowip]}(void){
    #{params[:classValueRowip]} = rb_define_class_under(#{params[:moduleName]}, \"#{params[:classNameRowip]}\", rb_cObject);
    rb_define_method(#{params[:classValueRowip]}, \"to_binary_rowip\", #{params[:funcPrefix]}_to_binary_rowip, 0);
    rb_define_singleton_method(#{params[:classValueRowip]}, \"load_binary_rowip\", #{params[:funcPrefix]}_load_binary_rowip, -1);
    rb_define_method(#{params[:classValueRowip]}, \"to_s\", #{params[:funcPrefix]}_to_sRowip, 0);

")
                    entry.fields.each() {|field|
                        next if field.target != :both
                        getStr="#{params[:funcPrefix]}_#{field.name}_get"
                        setStr="#{params[:funcPrefix]}_#{field.name}_set"

                        output.puts("    rb_define_method(#{params[:classValueRowip]}, \"#{field.name}\", #{getStr}Rowip, 0);");
                        output.puts("    rb_define_method(#{params[:classValueRowip]}, \"#{field.name}=\", #{setStr}Rowip, 1);") if (field.category == :simple and field.data_type != "char*")
                        if ((field.category == :id) || (field.category == :idref))
                            output.puts("    rb_define_method(#{params[:classValueRowip]}, \"#{field.name}_str\", #{getStr_str}Rowip, 0);");
                        end
                    }
                    output.puts("
}
");

                    if entry.attribute == :listable
                        output.puts("
/*
 * Ruby class for an enumarable of #{entry.name} structure
 *
 * #{entry.description}
 */
static
void Init_#{params[:classNameList]}(){
    #{params[:classValueList]} = rb_define_class_under(#{params[:moduleName]}, \"#{params[:classNameList]}\", rb_cObject);
    #{params[:classValueListRowip]} = rb_define_class_under(#{params[:moduleName]}, \"#{params[:classNameListRowip]}\", rb_cObject);

    rb_define_alloc_func(#{params[:classValueList]}, #{params[:funcPrefixList]}_alloc);
    rb_define_method(#{params[:classValueList]}, \"initialize\", #{params[:funcPrefixList]}_initialize, -1);

    rb_include_module(#{params[:classValueList]}, rb_mEnumerable);
    rb_define_method(#{params[:classValueList]}, \"[]\", #{params[:funcPrefixList]}_arrayGet, 1);
    rb_define_method(#{params[:classValueList]}, \"each\", #{params[:funcPrefixList]}_arrayEach, 0);
    rb_define_method(#{params[:classValueList]}, \"length\", #{params[:funcPrefixList]}_arrayLength, 0);
    rb_define_method(#{params[:classValueList]}, \"<<\", #{params[:funcPrefixList]}_arrayAdd, 1);
}

/*
 * Ruby class for an enumarable of #{entry.name} structure  in ROWIP (Read or Write In Place)
 *
 * #{entry.description}
 */
static
void Init_#{params[:classNameListRowip]}(){
    #{params[:classValueListRowip]} = rb_define_class_under(#{params[:moduleName]}, \"#{params[:classNameListRowip]}\", rb_cObject);
    rb_include_module(#{params[:classValueListRowip]}, rb_mEnumerable);
    rb_define_method(#{params[:classValueListRowip]}, \"[]\", #{params[:funcPrefixList]}_arrayGetRowip, 1);
    rb_define_method(#{params[:classValueListRowip]}, \"each\", #{params[:funcPrefixList]}_arrayEachRowip, 0);
    rb_define_method(#{params[:classValueListRowip]}, \"length\", #{params[:funcPrefixList]}_arrayLengthRowip, 0);
}
")
                    end
                    output.puts("
void #{params[:funcPrefix]}_init(void){
    Init_#{params[:className]}();
    Init_#{params[:classNameRowip]}();

");
                    output.puts "    Init_#{params[:classNameList]}();" if entry.attribute == :listable
                    output.puts "    Init_#{params[:classNameListRowip]}();" if entry.attribute == :listable
                    
                    entry.enums.each() {|field|
                        output.puts("
    {
        int i;
        for(i = 0; i < #{field.enum.length + 1}; i++){
            #{entry.name}_#{field.name}_enumId[i] = rb_intern(#{entry.name}_#{field.name}_enum[i]);
        }
    }
") }
                    output.puts("
}
");
                end
                module_function :write
            end
        end
    end
end
