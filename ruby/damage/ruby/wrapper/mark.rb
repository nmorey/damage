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
      module Mark
        def write(output, entry, libName, params)
          output.puts("
/** Mark function */
void #{params[:funcPrefix]}_mark(#{params[:cType]} *ptr) {
    if(ptr == NULL) return;
");
          # Look for children and mark them
          
          entry.fields.each() { |field|
            next if field.target != :both
            if field.category == :intern 
              if field.qty == :list || field.qty == :container
                output.puts("
    { __#{libName}_#{field.data_type}* elt;
        for(elt = ptr->#{field.name}; elt; elt = elt->next)
            if(elt->_private != NULL) {
                rb_gc_mark((VALUE) elt->_private);
            }
    }
")
              elsif field.qty == :single
                output.puts("
    { if(ptr->#{field.name})
            if(ptr->#{field.name}->_private != NULL) {
                rb_gc_mark((VALUE) ptr->#{field.name}->_private);
            }
    }
");
              end
            end
          }
          output.puts("
}
");
          if entry.attribute == :listable
            output.puts("
/** Mark function */
void #{params[:funcPrefixList]}_mark(#{params[:cTypeList]} *ptr) {
    #{params[:cType]} *elnt;
    if(ptr == NULL) return;
    for(elnt = ptr->first; elnt; elnt = elnt->next){
        if(elnt->_private != NULL) rb_gc_mark((VALUE)elnt->_private);
    }
    return;
}
");

          end

            #
            # rowip
            #
            output.puts("
/** Mark function */
void #{params[:funcPrefix]}_markRowip(#{params[:cType]} *ptr) {
    if(ptr == NULL) return;
");
            # Look for children and mark them
            
            entry.fields.each() { |field|
              next if field.target != :both
              if field.category == :intern 
                if field.qty == :list || field.qty == :container
                  output.puts("
    { __#{libName}_#{field.data_type}* elt;
        for(elt = __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name}); elt; elt =  __#{libName.upcase}_ROWIP_PTR(elt, next))
            if(elt->_private != NULL) {
                rb_gc_mark((VALUE) elt->_private);
            }
    }
")
                elsif field.qty == :single
                  output.puts("
    { if(ptr->#{field.name})
            if(__#{libName.upcase}_ROWIP_PTR(ptr,#{field.name})->_private != NULL) {
                rb_gc_mark((VALUE) __#{libName.upcase}_ROWIP_PTR(ptr, #{field.name})->_private);
            }
    }
");
                end
              end
            }
            output.puts("
}
");
            if entry.attribute == :listable
              output.puts("
/** Mark function */
void #{params[:funcPrefixList]}_markRowip(#{params[:cTypeList]} *ptr) {
    #{params[:cType]} *elnt;
    if(ptr == NULL) return;
    for(elnt = ptr->first; elnt; elnt = __#{libName.upcase}_ROWIP_PTR(elnt, next)){
        if(elnt->_private != NULL) rb_gc_mark((VALUE)elnt->_private);
    }
    return;
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
