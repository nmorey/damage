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
        def write(output, entry, libName, params)
          output.puts("
VALUE #{params[:funcPrefix]}_xml_to_string(VALUE self, int indent){
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    VALUE string = rb_str_new2(strdup(\"\"));

");
          entry.fields.each() {|field|
            next if field.target != :both
            case field.qty
            when :single
              case field.category
              when :simple
                case field.data_type
                when "char*"
                  output.puts("
    indentToString(string, indent);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    if(ptr->#{field.name} != NULL){
        string = rb_str_concat(string, rb_str_new2(strdup(ptr->#{field.name})));
    }
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
")
                when "unsigned long"
                  output.puts("
    {
    char numstr[256];
    indentToString(string, indent);
    sprintf(numstr, \"#{field.name}: %lu\\n\", ptr->#{field.name});
    string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
    }
")
                when "double"
                  output.puts("
    {
    char numstr[256];
    indentToString(string, indent);
    sprintf(numstr, \"#{field.name}: %lf\\n\", ptr->#{field.name});
    string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
    }
")
                else
                   raise("Unsupported data type #{field.data_type}" )
               end
              when :intern
                tParams = Damage::Ruby::nameToParams(libName, field.data_type)
                output.puts("
    if(ptr->#{field.name} != NULL){
        indentToString(string, indent);
        string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}:\\n\")));
        string = rb_str_concat(string, #{tParams[:funcPrefix]}_xml_to_string((VALUE)ptr->#{field.name}->_private, indent+1));
    }
")
              end
            when :list, :container
              case field.category
              when :simple
                case field.data_type
                when "char*"
                  output.puts("
    indentToString(string, indent);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            indentToString(string, indent + 1);
            string = rb_str_concat(string, rb_str_new2(strdup(ptr->#{field.name}[i])));
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
");

                when "unsigned long"
                  output.puts("
   indentToString(string, indent);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            char numstr[256];
            sprintf(numstr, \"#{field.name}: %lu\\n\", ptr->#{field.name}[i]);
            indentToString(string, indent + 1);
            string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
");
                when "double"
                  output.puts("
   indentToString(string, indent);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        unsigned long i;
        for(i = 0; i < ptr->#{field.name}Len; i++){
            char numstr[256];
            sprintf(numstr, \"#{field.name}: %lf\\n\", ptr->#{field.name}[i]);
            indentToString(string, indent + 1);
            string = rb_str_concat(string, rb_str_new2(strdup(numstr)));
            string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
        }

    }
");
                else
                  raise("Unsupported data type #{field.data_type}" )
                end
              when :intern
                tParams=Damage::Ruby::nameToParams(libName, field.data_type)
                output.puts("
   indentToString(string, indent);
    string = rb_str_concat(string, rb_str_new2(strdup(\"#{field.name}: \")));
    string = rb_str_concat(string, rb_str_new2(strdup(\"\\n\")));
    if(ptr->#{field.name} != NULL){
        #{tParams[:cType]}* p;
        for(p = ptr->#{field.name}; p; p = p->next){
            string = rb_str_concat(string, #{tParams[:funcPrefix]}_xml_to_string((VALUE)p->_private, indent+1));
        }

    }

");
              end
            end

            }
            output.puts("
    return string;
}

static VALUE #{params[:funcPrefix]}_to_s(VALUE self){
    return rb_str_concat(rb_str_new2(strdup(\"#{entry.name}:\\n\")), #{params[:funcPrefix]}_xml_to_string(self, 1));
}
");
          end
          module_function :write
          
          private
        end
      end
    end
  end
