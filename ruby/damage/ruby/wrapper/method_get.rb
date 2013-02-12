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
            module MethodGet

                def write(output, entry, libName, params, rowip)
                    entry.fields.each() {|field|
                        retType=(field.qty == :list || field.qty == :container) ? ((field.category == :intern) ? (field.ruby_type + "List") : (field.ruby_type + "[]" )): field.ruby_type
                        getStr="
/*
 * Get the #{retType} located at the field #{field.name} of a #{params[:className]}
 * 
 * #{field.description}
 *
 * call-seq:
 *   #{params[:name]}.#{field.name} -> #{retType}
 *
 */
static VALUE #{params[:funcPrefix]}_#{field.name}_get(VALUE self)"
                        getStrRowip="
/*
 * Get the #{retType} located at the field #{field.name} of a #{params[:classNameRowip]}
 * 
 * #{field.description}
 *
 * call-seq:
 *   #{params[:name]}.#{field.name} -> #{retType}
 *
 */
static VALUE #{params[:funcPrefix]}_#{field.name}_getRowip(VALUE self)"

                        aliasFunc="#define #{params[:funcPrefix]}_#{field.name}_getRowip #{params[:funcPrefix]}_#{field.name}_get"



                        if field.target == :mem && field.attribute == :sort then
                        getStr="
/*
 * Get the array of #{retType} located at the field #{field.sort_field} of a #{params[:className]} indexed by #{field.sort_key}
 * 
 * #{field.description}
 *
 * call-seq:
 *   #{params[:name]}.s_#{field.name} -> #{retType}
 *
 */
static VALUE #{params[:funcPrefix]}_s_#{field.name}_get(VALUE self)"
                        getStrRowip="
/*
 * Get the array of #{retType} located at the field #{field.sort_field} of a #{params[:classNameRowip]} indexed by #{field.sort_key}
 * 
 * #{field.description}
 *
 * call-seq:
 *   #{params[:name]}.s_#{field.name} -> #{retType}
 *
 */
static VALUE #{params[:funcPrefix]}_s_#{field.name}_getRowip(VALUE self)"


                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    __#{libName}_#{field.data_type} *elnt;
    VALUE array = rb_ary_new();
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    for(elnt = ptr->#{field.sort_field}; elnt; elnt = elnt->next){
        rb_ary_store(array, elnt->#{field.sort_key}, (VALUE)elnt->_private);
    }
    return array;
}
")           
                            next
                        end
                        next if field.target != :both

                        case field.qty
                        when :single
                            case field.category
                            when :simple
                                raise("Unsupported simple type #{field.data_type}") if field.val2ruby == nil
                                
                                output.puts("
#{aliasFunc}") if rowip == true
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return #{field.val2ruby}(ptr->#{field.name});
}
")           

                            when :string
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return rb_str_new2(ptr->#{field.name});
}");
                                output.puts("
#{getStrRowip}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return rb_str_new2(__#{libName.upcase}_ROWIP_STR(ptr, #{field.name}));
}
") if rowip == true
                            when :id, :idref
                                getStr_str="static VALUE #{params[:funcPrefix]}_#{field.name}_str_get(VALUE self)"
                                getStrRowip_str="static VALUE #{params[:funcPrefix]}_#{field.name}_str_getRowip(VALUE self)"

                                output.puts("
#{getStr_str}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name}_str == NULL)
        return Qnil;
    return rb_str_new2(ptr->#{field.name}_str);
}");
                                output.puts("
#{getStrRowip_str}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name}_str == NULL)
        return Qnil;
    return rb_str_new2(__#{libName.upcase}_ROWIP_STR(ptr, #{field.name}_str));
}
") if rowip == true
                                output.puts("
#{aliasFunc}
") if rowip == true
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return ULONG2NUM((long)ptr->#{field.name});
}")               
                            when :intern
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return (VALUE)ptr->#{field.name}->_private;
}")
                                output.puts("
#{getStrRowip}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    if(ptr->#{field.name} == NULL)
        return Qnil;
    return (VALUE)__#{libName.upcase}_ROWIP_PTR(ptr,#{field.name})->_private;
}
") if rowip == true
                            when :enum
                                output.puts("
#{aliasFunc}
") if rowip == true
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return ID2SYM(#{entry.name}_#{field.name}_enumId[ptr->#{field.name}]);
}
")
                            when :genum
                                output.puts("
#{aliasFunc}
") if rowip == true
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    extern ID #{field.genumEntry}_#{field.genumField}_enumId[];
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);
    return ID2SYM(#{field.genumEntry}_#{field.genumField}_enumId[ptr->#{field.name}]);
}
")
                            when :raw
                                #Ignore
                            else
                                raise("Unsupported data category for #{entry.name}.#{field.name}");

                            end
                        when :list, :container
                            case field.category
                            when :string
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, rb_str_new2(ptr->#{field.name}[i]));
    }
    return array;
}
")
                                output.puts("
#{getStrRowip}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, rb_str_new2(__#{libName.upcase}_ROWIP_STR_ARRAY(ptr,#{field.name}, i)));
    }
    return array;
}
") if rowip == true

                            when :simple
                                raise("Unsupported simple type #{field.data_type}") if field.val2ruby == nil
                                output.puts("
#{getStr}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, #{field.val2ruby}(ptr->#{field.name}[i]));
    }
    return array;
}
")
                                output.puts("
#{getStrRowip}{
    #{params[:cType]}* ptr;
    VALUE array;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    unsigned long i;
    assert(ptr);
    array = rb_ary_new2(ptr->#{field.name}Len);
    for(i = 0; i < ptr->#{field.name}Len; i++){
         rb_ary_store(array, i, #{field.val2ruby}(__#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})[i]));
    }
    return array;
}
") if rowip == true
                            when :intern
                                tParams=Damage::Ruby::nameToParams(libName, field.data_type)
                                output.puts("
#{getStr}{
    #{params[:cType]} *ptr;
    #{tParams[:cTypeList]}* list;
    #{tParams[:cType]} *elt;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);

    list = malloc(sizeof(*list));
    list->parent = &(ptr->#{field.name});
    list->_private = Qnil;
    if(ptr->#{field.name} != NULL){
        list->first = ptr->#{field.name};
        for(elt = list->first; elt->next != NULL; elt = elt->next){}
        list->last = elt;
    } else {
       list->first = list->last = NULL;
    }
    return #{tParams[:funcPrefixList]}_wrap(list);
}
")
                                output.puts("
#{getStrRowip}{
    #{params[:cType]} *ptr;
    #{tParams[:cTypeList]}* list;
    #{tParams[:cType]} *elt;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    assert(ptr);

    list = malloc(sizeof(*list));
    list->parent = &(ptr->#{field.name});
    list->_private = Qnil;
    if(ptr->#{field.name} != NULL){
        list->first = __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name});
        for(elt = list->first; elt->next != NULL; elt = __#{libName.upcase}_ROWIP_PTR(elt, next)){}
        list->last = elt;
    } else {
       list->first = list->last = NULL;
    }
    return #{tParams[:funcPrefixList]}_wrapRowip(list);
}
") if rowip == true
                            when :raw
                                #Ignore

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
