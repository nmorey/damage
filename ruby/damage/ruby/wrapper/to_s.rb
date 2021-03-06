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
            module ToS
                def write(output, entry, libName, params, rowip)
                    output.puts("
VALUE #{params[:funcPrefix]}_xml_to_string(VALUE self, int indent){
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    VALUE string = rb_str_new2(strdup(\"\"));
    int first __attribute__((unused)) = 1;
");
                    if entry.attribute == :listable then
                        output.puts("    int listable = 1;")
                    else
                        output.puts("    int listable = 0;")
                    end
                    entry.fields.each() {|field|
                        next if field.target != :both
                        case field.qty
                        when :single
                            case field.category
                            when :string
                                output.puts("
    indentToString(string, indent, listable, first);
    first = 0;    
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \\\"\")));
    if(ptr->#{field.name} != NULL){
        string = rb_str_concat(string, rb_str_new2(strdup(ptr->#{field.name})));
    }
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\\"\\n\")));
")

                            when :simple
                                raise("Unsupported simple type #{field.data_type}") if field.printf == nil
                                output.puts("
    {
    char numstr[256];
    indentToString(string, indent, listable, first);
    first = 0;    
    sprintf(numstr, \"#{field.name}: %#{field.printf}\\n\", ptr->#{field.name});
    string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
    }
")
                            when :raw
                                output.puts("
    {
    char numstr[256];
    indentToString(string, indent, listable, first);
    first = 0;    
    sprintf(numstr, \"#{field.name}: N/A\\n\");
    string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
    }
")
                            when :intern
                                tParams = Damage::Ruby::nameToParams(libName, field.data_type)
                                output.puts("
    if(ptr->#{field.name} != NULL){
        indentToString(string, indent, listable, first);
        first = 0;
        string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}:\\n\")));
        string = rb_str_concat(string, #{tParams[:funcPrefix]}_xml_to_string((VALUE)ptr->#{field.name}->_private, indent+1));
    }
")
                            when :enum
                                output.puts("
    {
    indentToString(string, indent, listable, first);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(__#{params[:libName]}_#{entry.name}_#{field.name}_strings[ptr->#{field.name}])));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    }
")
                            when :genum
                                output.puts("
    {
    indentToString(string, indent, listable, first);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(__#{params[:libName]}_#{field.genumEntry}_#{field.genumField}_strings[ptr->#{field.name}])));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    }
")
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                            end
                        when :list, :container
                            case field.category
                            when :string
                                output.puts("
    indentToString(string, indent, listable, first);
    first = 0;
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            indentToString(string, indent + 1, 1, 1);
            if(ptr->#{field.name}[i]){
                string = rb_str_concat(string, rb_str_new2(strdup(ptr->#{field.name}[i])));
            }
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
");
                                
                            when :simple
                                raise("Unsupported simple type #{field.data_type}") if field.printf == nil

                                output.puts("
   indentToString(string, indent, listable, first);
    first = 0;
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            char numstr[256];
            sprintf(numstr, \"#{field.name}: %#{field.printf}\\n\", ptr->#{field.name}[i]);
            indentToString(string, indent + 1, 1, 1);
            string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
");                   when :raw

                                output.puts("
   indentToString(string, indent, listable, first);
    first = 0;
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            char numstr[256];
            sprintf(numstr, \"#{field.name}: N/A\\n\");
            indentToString(string, indent + 1, 1, 1);
            string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
");               
                            when :intern
                                tParams=Damage::Ruby::nameToParams(libName, field.data_type)
                                output.puts("
   indentToString(string, indent, listable, first);
    first = 0;
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        #{tParams[:cType]}* p;
        for(p = ptr->#{field.name}; p; p = p->next){
            string = rb_str_concat(string, #{tParams[:funcPrefix]}_xml_to_string((VALUE)p->_private, indent+1));
        }

    }

");
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");
                            end
                        end
                    }
                    output.puts("
    return string;
}

/*
 * call-seq:
 *   #{params[:name]}.to_s -> string
 *
 * Returns a #{params[:className]} as a string
 */
static VALUE #{params[:funcPrefix]}_to_s(VALUE self){
    return rb_str_concat(rb_str_new2(strdup(\"#{entry.name}:\\n\")), #{params[:funcPrefix]}_xml_to_string(self, 1));
}
");



                    #
                    #
                    # ROWIP
                    #
                    if rowip == true
                        output.puts("
VALUE #{params[:funcPrefix]}_xml_to_stringRowip(VALUE self, int indent){
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    VALUE string = rb_str_new2(strdup(\"\"));
   int first __attribute__((unused)) = 1;
");
                        if entry.attribute == :listable then
                            output.puts("    int listable = 1;")
                        else
                            output.puts("    int listable = 0;")
                        end

                        entry.fields.each() {|field|
                            next if field.target != :both
                            case field.qty
                            when :single
                                case field.category
                                when :string
                                    output.puts("
    indentToString(string, indent, listable, first);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \\\"\")));
    if(ptr->#{field.name} != NULL){
        string = rb_str_concat(string, rb_str_new2(strdup(__#{libName.upcase}_ROWIP_STR(ptr, #{field.name}))));
    }
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\\"\\n\")));
")
                                when :simple
                                    raise("Unsupported simple type #{field.data_type}") if field.printf == nil

                                    output.puts("
    {
    char numstr[256];
    indentToString(string, indent, listable, first);
    sprintf(numstr, \"#{field.name}: %#{field.printf}\\n\", ptr->#{field.name});
    string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
    }
")
                                when :intern
                                    tParams = Damage::Ruby::nameToParams(libName, field.data_type)
                                    output.puts("
    if(ptr->#{field.name} != NULL){
        indentToString(string, indent, listable, first);
        string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}:\\n\")));
        string = rb_str_concat(string, #{tParams[:funcPrefix]}_xml_to_stringRowip((VALUE)__#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})->_private, indent+1));
    }
")
                                when :enum
                                    output.puts("
    {
    indentToString(string, indent, listable, first);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \\\"\")));
    string = rb_str_concat(string, rb_str_new2(strdup(#{entry.name}_#{field.name}_enum[ptr->#{field.name}])));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\\"\\n\")));
    }
")
                                else
                                    raise("Unsupported data type #{field.data_type}" )
                                end
                            when :list, :container
                                case field.category

                                when :string
                                    output.puts("
    indentToString(string, indent, listable, first);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            indentToString(string, indent + 1, 1, 1);
            if(__#{libName.upcase}_ROWIP_STR_ARRAY(ptr, #{field.name}, i)){
               string = rb_str_concat(string, rb_str_new2(strdup(__#{libName.upcase}_ROWIP_STR_ARRAY(ptr, #{field.name}, i))));
            }
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
");

                                when :simple
                                    raise("Unsupported simple type #{field.data_type}") if field.printf == nil
                                    output.puts("
   indentToString(string, indent, listable, first);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            char numstr[256];
            sprintf(numstr, \"#{field.name}: %#{field.printf}\\n\", __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})[i]);
            indentToString(string, indent + 1, 1, 1);
            string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
"); 
                                when :intern
                                    tParams=Damage::Ruby::nameToParams(libName, field.data_type)
                                    output.puts("
   indentToString(string, indent, listable, first);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        #{tParams[:cType]}* p;
        for(p = __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name}); p; p = __#{libName.upcase}_ROWIP_PTR(p, next)){
            string = rb_str_concat(string, #{tParams[:funcPrefix]}_xml_to_stringRowip((VALUE)p->_private, indent+1));
        }

    }

");
                                else
                                    raise("Unsupported data category for #{entry.name}.#{field.name}");
                                end
                            end

                        }
                        output.puts("
    return string;
}

/*
 * call-seq:
 *   #{params[:classNameRowip]}.to_s -> string
 *
 * Returns a #{params[:classNameRowip]} as a string
 */
static VALUE #{params[:funcPrefix]}_to_sRowip(VALUE self){
    return rb_str_concat(rb_str_new2(strdup(\"#{entry.name}:\\n\")), #{params[:funcPrefix]}_xml_to_stringRowip(self, 1));
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
