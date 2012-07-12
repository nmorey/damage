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

                description.enums.each(){ |name, entry|
                    params=Damage::Ruby::nameToParams(libName, entry.name)

                    output.puts("void #{params[:funcPrefix]}_init();");
 
                }
                description.entries.each(){ |name, entry|
                    params=Damage::Ruby::nameToParams(libName, entry.name)

                    output.puts("void #{params[:funcPrefix]}_init();");
                    output.puts("VALUE #{params[:funcPrefix]}_wrap(#{params[:cType]}* ptr);");
                    output.puts("VALUE #{params[:funcPrefix]}_wrapFirst(#{params[:cType]}* ptr);");
                    output.puts("VALUE #{params[:funcPrefix]}_wrapRowip(#{params[:cType]}* ptr);");
                    output.puts("VALUE #{params[:funcPrefix]}_wrapFirstRowip(#{params[:cType]}* ptr);");
                    output.puts("VALUE #{params[:funcPrefix]}_decorate(VALUE self);\n\n");
                    output.puts("VALUE #{params[:funcPrefix]}_decorateRowip(VALUE self);\n\n");
                    output.puts("void #{params[:funcPrefix]}_cleanup(#{params[:cType]}* ptr);\n\n");
                    output.puts("void #{params[:funcPrefix]}_cleanupRowip(#{params[:cType]}* ptr);\n\n");
                    output.puts("VALUE #{params[:funcPrefix]}_xml_to_string(VALUE self, int indent);\n");
                    output.puts("VALUE #{params[:funcPrefix]}_xml_to_stringRowip(VALUE self, int indent);\n");
                    if entry.attribute == :listable
                        output.puts("
typedef struct {
    #{params[:cType]} **parent;
    #{params[:cType]} *first;
    #{params[:cType]} *last;
    VALUE _private;
} #{params[:cTypeList]};


VALUE #{params[:funcPrefixList]}_wrap(#{params[:cTypeList]}* ptr);
VALUE #{params[:funcPrefixList]}_wrapRowip(#{params[:cTypeList]}* ptr);
VALUE #{params[:funcPrefixList]}_decorate(VALUE self);

")
                    end
                }
                output.puts("
VALUE indentToString(VALUE string, int indent, int listable, int first);
__#{libName}_options __#{libName}_get_options(VALUE hash);
");
            end


            # Generate the main loader file
            def genGlobC(output, description, module_name)
                libName = description.config.libname
                moduleName= description.config.libname.slice(0,1).upcase + description.config.libname.slice(1..-1)
                output.puts("
#include <ruby.h>
#include <#{libName}.h>
#include \"ruby_#{libName}.h\"

VALUE #{moduleName};

VALUE indentToString(VALUE string, int indent, int listable, int first){
    char str[256], *ptr;
    VALUE _str;
    int i;
    ptr=str;
    if(indent == 0)
        return string;
    for(i = 0; i< indent; i++){
        ptr += sprintf(ptr, \"\\t\");
    }
    _str = rb_str_concat(string, rb_str_new2(strdup(str)));
    if(listable){
        if(first){
            _str = rb_str_concat(_str, rb_str_new2(strdup(\"- \")));
        } else {
            _str = rb_str_concat(_str, rb_str_new2(strdup(\"  \")));
        }
    }
    return _str;
}

__#{libName}_options __#{libName}_get_options(VALUE hash){
    VALUE val;
    __#{libName}_options opts = 0;
    if(NIL_P(hash))
        return opts;
    Check_Type(hash, T_HASH);

    val = rb_hash_aref(hash, ID2SYM(rb_intern(\"readonly\")));
    if(val == Qtrue)
        opts |= __#{libName.upcase}_OPTION_READONLY;

    val = rb_hash_aref(hash, ID2SYM(rb_intern(\"keeplocked\")));
    if(val == Qtrue)
        opts |= __#{libName.upcase}_OPTION_KEEPLOCKED;

    val = rb_hash_aref(hash, ID2SYM(rb_intern(\"gzipped\")));
    if(val == Qtrue)
        opts |= __#{libName.upcase}_OPTION_GZIPPED;

    return opts;
}
/*
 * call-seq:
 *   #{moduleName}::set_dtd_path = String
 *
 * Set the DTD search path for XMl validation
 *
 */
static VALUE rub#{moduleName}_set_dtd(VALUE obj, VALUE val){
     Check_Type(val, T_STRING);
   __#{libName}_set_dtd_path(StringValuePtr(val));
   return val;
}

/*
 * #{moduleName}  DAMAGE Module
 * 
 * #{description.config.description}
 */
static void Init_#{moduleName}(void){
    /*
     * Document-module: #{moduleName}
     *
     * == Summary
     *
     * Damage Generate Module: #{moduleName}
     * Version: #{description.config.version}
     * #{description.config.description}     *
     * == Classes
     *")
                description.entries.each(){ |name, entry|
                    params=Damage::Ruby::nameToParams(libName, entry.name)
                    output.puts("     * - #{moduleName}::#{params[:className]}")
                    output.puts("     * - #{moduleName}::#{params[:classNameRowip]}") if description.config.rowip == true
                    if entry.attribute == :listable
                        output.puts("     * - #{moduleName}::#{params[:classNameList]}")
                        output.puts("     * - #{moduleName}::#{params[:classNameListRowip]}") if description.config.rowip == true
                    end

                }
                output.puts(
                            "     *
     */
    #{moduleName} = rb_define_module(\"#{moduleName}\");
    rb_define_module_function(#{moduleName}, \"set_dtd_path\", rub#{moduleName}_set_dtd, 1);
}
void Init_lib#{libName}_ruby(){
    Init_#{moduleName}();

");
                description.entries.each(){ |name, entry|
                    params=Damage::Ruby::nameToParams(libName, entry.name)
                    output.puts("    #{params[:funcPrefix]}_init();");
                }
                description.enums.each(){ |name, entry|
                    params=Damage::Ruby::nameToParams(libName, entry.name)
                    output.puts("    #{params[:funcPrefix]}_init();");
                }
                output.puts("}");
            end
            module_function :genGlobH, :genGlobC

        end
    end
end
