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
      module Decorate
        def write(output, entry, libName, params)
         output.puts("
/** Link C subtree to Ruby classes */
VALUE #{params[:funcPrefix]}_decorate(VALUE self){
    #{params[:cType]}* ptr;
    Data_Get_Struct(self, #{params[:cType]}, ptr);
    ptr->_private = (void*)self;
");
        entry.fields.each() { |field|
            next if field.target != :both
          if field.category == :intern 
            tParams = Damage::Ruby::nameToParams(libName, field.data_type)
            if field.qty == :list || field.qty == :container
              output.puts("
    { __#{libName}_#{field.data_type}* elt;
        for(elt = ptr->#{field.name}; elt; elt = elt->next){
            #{tParams[:funcPrefix]}_decorate(#{tParams[:funcPrefix]}_wrapFirst(elt));
        }
    }

");
            elsif field.qty == :single
              output.puts("
        if(ptr->#{field.name}) #{tParams[:funcPrefix]}_decorate(#{tParams[:funcPrefix]}_wrapFirst(ptr->#{field.name}));
");
            end
          end
        }
        output.puts("
    return self;
}
")
        end
        module_function :write
        
        private
      end
    end
  end
end
