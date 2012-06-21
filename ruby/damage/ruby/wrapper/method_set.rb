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
            module MethodSet
                def write(output, description, entry, libName, params, rowip)
                    entry.fields.each() {|field|
                        next if field.target != :both
                         retType=(field.qty == :list || field.qty == :container) ? ((field.category == :intern) ? (field.ruby_type + "List") : (field.ruby_type + "[]" )): field.ruby_type
                       setStr="
/*
 * call-seq:
 *   #{params[:name]}.#{field.name} = #{retType}
 *
 * Store a #{retType} in the field #{field.name} of a #{params[:className]}
 * 
 * #{field.description}
 *
 */
static VALUE #{params[:funcPrefix]}_#{field.name}_set(VALUE self, VALUE val)"
                        setStrRowip="
/*
 * call-seq:
 *   #{params[:name]}.#{field.name} = #{retType}
 *
 * Store a #{retType} in the field #{field.name} of a #{params[:classNameRowip]}
 * 
 * #{field.description}
 *
 */
static VALUE #{params[:funcPrefix]}_#{field.name}_setRowip(VALUE self, VALUE val)"
                        aliasFunc="#define #{params[:funcPrefix]}_#{field.name}_setRowip #{params[:funcPrefix]}_#{field.name}_set"
                        
                        case field.qty
                        when :single
                            case field.category
                            when :simple
                                raise("Unsupported simple type #{field.data_type}") if field.ruby2val == nil
                                output.puts("
#{aliasFunc}
") if rowip == true
                                output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    ptr->#{field.name} = #{field.ruby2val}(val);
    return self;
}
");
                            when :string
                                output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    Check_Type(val, #{field.rubyType});
    if(ptr->#{field.name}) free(ptr->#{field.name});
    ptr->#{field.name} = strdup(StringValuePtr(val));
    return self;
}
");

                            when :id, :idref
                                setStr_str="static VALUE #{params[:funcPrefix]}_#{field.name}_str_set(VALUE self, VALUE val)"
                                setStrRowip_str="static VALUE #{params[:funcPrefix]}_#{field.name}_str_setRowip(VALUE self, VALUE val)"

                                output.puts("
#{setStr_str}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name}_str) free(ptr->#{field.name}_str);
    ptr->#{field.name}_str = strdup(StringValuePtr(val));
    return self;
}
");
                                output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    ptr->#{field.name} = NUM2ULONG(val);
    return self;
}
"); 

                            when :intern
                                subParams = Damage::Ruby::nameToParams(libName, field.data_type)
                                output.puts("
#{setStr}{
    extern VALUE #{subParams[:classValue]};
    #{params[:cType]}* ptr;
    __#{libName}_#{field.data_type} *ptr2;
    Check_Type(val, #{field.rubyType});
    if(CLASS_OF(val) != #{subParams[:classValue]}){
        rb_raise(rb_eArgError, \"Using object of class '%s' while expecting class '%s'\\n\", 
            rb_obj_classname(val), rb_class2name(#{subParams[:classValue]}));
    }

    Data_Get_Struct(self, #{params[:cType]}, ptr);
    Data_Get_Struct(val, __#{libName}_#{field.data_type}, ptr2);
    assert(ptr); assert(ptr2);
    ptr->#{field.name} = ptr2;
    return self;
}
");
                            when :enum
                                output.puts("
#{aliasFunc}
") if rowip == true
                                output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    int i;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    Check_Type(val, #{field.rubyType});

    for(i = 0; i < #{field.enum.length + 1}; i++){
        if(#{entry.name}_#{field.name}_enumId[i] == SYM2ID(val)){
            ptr->#{field.name} = i;
            return self;
        }
    }

    rb_raise(rb_eArgError, \"Invalid argument for enum #{entry.name}.#{field.name}\");
    return self;
}
");
                            when :genum
                                output.puts("
#{aliasFunc}
") if rowip == true
                                _field = description.enums[field.genumEntry].s_fields[field.genumField]
                                output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    int i;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    Check_Type(val, #{field.rubyType});
    extern ID #{field.genumEntry}_#{field.genumField}_enumId[];

    for(i = 0; i < #{_field.enum.length + 1}; i++){
        if(#{field.genumEntry}_#{field.genumField}_enumId[i] == SYM2ID(val)){
            ptr->#{field.name} = i;
            return self;
        }
    }

    rb_raise(rb_eArgError, \"Invalid argument for enum #{entry.name}.#{field.name}\");
    return self;
}
");
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                        when :list, :container
                            case field.category
                            when :string
                                    output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}){
        for(i = 0; i < ptr->#{field.name}Len; i++){
            free(ptr->#{field.name}[i]);
        }
        free(ptr->#{field.name});
    }
    ptr->#{field.name}Len = RARRAY_LEN(val);
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        Check_Type(elnt, #{field.rubyType});
        ptr->#{field.name}[i] = strdup(StringValuePtr(elnt));
    }
    return self;
}
");

                            when :simple
                                raise("Unsupported simple type #{field.data_type}") if field.ruby2val == nil

                                    output.puts("
#{setStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}){
        free(ptr->#{field.name});
    }
    ptr->#{field.name}Len = RARRAY_LEN(val);
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        Check_Type(elnt, #{field.rubyType});
        ptr->#{field.name}[i] = #{field.ruby2val}(elnt);
    }
    return self;
}
")
                                output.puts("
#{setStrRowip}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    Check_Type(val, T_ARRAY); 
    if(ptr->#{field.name}Len != RARRAY_LEN(val)){
        rb_raise(rb_eArgError, \"Can not set an array of different size\");
    }
    for(i = 0; i < ptr->#{field.name}Len; i++){
        VALUE elnt = rb_ary_shift(val);
        Check_Type(elnt, #{field.rubyType});
        __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})[i] = #{field.ruby2val}(elnt);
    }
    return self;
}
") if rowip == true                 
                            when :intern
                                subParams = Damage::Ruby::nameToParams(libName, field.data_type)
                                
                                output.puts("
extern VALUE #{subParams[:classValueList]};
#{setStr}{
    #{params[:cType]}* ptr;
    Check_Type(val, #{field.rubyType});
    if(CLASS_OF(val) != #{subParams[:classValueList]}){
        rb_raise(rb_eArgError, \"Using object of class '%s' while expecting class '%s'\\n\", 
            rb_obj_classname(val), rb_class2name(#{subParams[:classValueList]}));
    }
   #{subParams[:cTypeList]}* list;

    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    Check_Type(val, rb_type(#{subParams[:classValueList]})); 
    Data_Get_Struct(val, #{subParams[:cTypeList]}, list);
    ptr->#{field.name} = list->first;
    return self;
}
");
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                        end

                    }

                end
                module_function :write
            end
        end
    end
end
