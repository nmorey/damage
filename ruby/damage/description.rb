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
    module Description
        class Field
            attr_accessor :name, :data_type, :default_val, :category, :attribute, :qty, :target
            attr_accessor :is_attribute, :required, :enum
            attr_accessor :printf, :ruby2val, :val2ruby

            # Data used only for SORT fields
            attr_accessor :sort_field, :sort_key
            def initialize(field)

                raise ("Field #{field} has no name!") if field["name"] == nil
                @name = field["name"]
                
                @default_val = field["default"]
                @attribute = :none
                @qty = :single
                @target = :both
                @is_attribute = false
                @sort_field = field["sort_field"]
                @sort_key = field["sort_key"]


                @required = false
                @required = true if field["required"] != nil

             
                case field["quantity"]
                when "SINGLE", nil
                    @qty = :single
                when "LIST"
                    @qty = :list
                    # when "ARRAY"
                    #   @qty = :array
                end
                case field["attribute"]
                when "META"
                    @attribute = :meta
                    @target = :mem
                when "SORT"
                    @attribute = :sort
                    @target = :mem
                when "PASS"
                    @attribute = :pass
                    @target = :parser
                when "CONTAINER"
                    @attribute = :container
                    @target = :both
                    @qty = :container
                when nil
                else
                    raise("Unknown field attribute #{field["attribute"]}")
                end

                case field["type"]
                when "String"
                    @data_type = "char*"
                    @category = :simple
                    @is_attribute = true if @qty == :single
                    @default_val = "NULL"
                when "UL"
                    @data_type="unsigned long"
                    @category = :simple
                    @printf = "lu"
                    @val2ruby = "ULONG2NUM"
                    @ruby2val = "NUM2ULONG"
                    @is_attribute = true if @qty == :single
                    
                    if @qty == :list
                        @data_type="uint32_t" 
                        @printf="u"
                        @val2ruby = "UINT2NUM"
                        @ruby2val = "NUM2UINT"
                        @default_val = "0";
                    end
                    @default_val = "0UL"
                when "SL"
                    @data_type="signed long"
                    @category = :simple
                    @printf="ld"
                    @val2ruby = "LONG2NUM"
                    @ruby2val = "NUM2LONG"
                    @is_attribute = true if @qty == :singl
                    if @qty == :liste
                        @data_type="int32_t" 
                        @printf="d"
                        @val2ruby = "INT2NUM"
                        @ruby2val = "NUM2INT"
                        @default_val = "0";
                    end
                    @default_val = "0L"
                when "DL"
                    @data_type="double"
                    @category = :simple
                    @is_attribute = true if @qty == :single
                    @default_val = "0.0"
                    @printf="lf"
                    @val2ruby = "rb_float_new"
                    @ruby2val = "NUM2DBL"
                when "UI"
                    @data_type = "uint32_t"
                    @category = :simple
                    @is_attribute = true if @qty == :single
                    @printf="u"
                    @val2ruby = "UINT2NUM"
                    @ruby2val = "NUM2UINT"
                    @default_val = "0";
                when "SI"
                    @data_type = "int32_t"
                    @category = :simple
                    @is_attribute = true if @qty == :single
                    @printf="d"
                    @val2ruby = "INT2NUM"
                    @ruby2val = "NUM2INT"
                    @default_val = "0";
                when /ENUM\(([^)]*)\)/
                    @data_type = "uint32_t"
                    @category = :enum
                    raise("Enums cannot be used as containers or list") if @qty != :single
                    @is_attribute = true if @qty == :single
                    @printf="u"
                    @val2ruby = "UINT2NUM"
                    @ruby2val = "NUM2UINT"
                    @default_val = "0";
                    @enum={}
                    $1.split('|').each() {|e|
                        @enum[e] = e.sub(/[^[:alnum:]]/, "_").upcase
                    }
                when /T\(([\w+ ]*)\)/
                    @data_type = $1
                    @category = :simple
                    @is_attribute = true if @qty == :single
                when /(S|STRUCT)\(([\w+ ]*)\)/
                    @data_type = $2
                    @category = :intern
                    @default_val = "NULL"
                    puts "This format is not DTD compatible (Field #{@name} has type #{@data_type})" if ((@data_type != @name) && (@target != :mem) && (@attribute != :container))
                when /(A|ARRAY)\(([\w+ ]*)\)/
                    @data_type = "#{$2}*"
                    @category = :intern
                    @default_val = "NULL"
                when "ID"
                    @category = :id
                    @default_val = "0UL"
                    @is_attribute = true
                when /IDREF\(([\w+ ]*)\)/
                    @data_type = $1
                    @category = :idref
                    @default_val = "0UL"
                    @is_attribute = true
                when nil
                    @data_type = @name
                    @category = :intern
                    @default_val = "NULL"
                    puts "This format is not DTD compatible (Field #{@name} has type #{@data_type})" if ((@data_type != @name) && (@target != :mem) && (@attribute != :container))

                else
                    raise("Field #{@name} has no data type...")
                end
                
            end
        end

        class Entry
            attr_accessor :name, :attribute, :fields, :children, :attributes, :sort, :containers, :enums, :cleanup, :postcleanup
            def initialize(entry)
                @name = entry["name"]
                @attribute = :none
                @cleanup = entry["cleanup"]
                @postcleanup = entry["postcleanup"]
                @fields = []
                @children = []
                @attributes = []
                @sort = []
                @containers = {}
                @enums=[]

                case entry["attribute"]
                when "TOP"
                    @attribute = :top
                when "LISTABLE"
                    @attribute = :listable
                when nil
                else
                    raise("Unknown entry attribute #{entry["attribute"]}")
                end
                entry["fields"].each() { |field|
                    _field =  Field.new(field)
                    
                    # Top cannot have attributes
                    _field.is_attribute = false if @attribute == :top && _field.is_attribute == true

                    @fields << _field

                    @children << _field if _field.is_attribute == false && _field.target != :mem
                    @attributes << _field if _field.is_attribute == true && _field.target != :mem
                    @enums << _field if _field.category == :enum
                    if _field.attribute == :sort then
                        @sort << _field 
                    elsif field["sort_key"] != nil && _field.category == :intern && 
                            (_field.qty == :list || _field.qty == :container)
                        # This is a shortcut to define a sorted array !
                        field["attribute"] = "SORT"
                        field["sort_field"] = field["name"]
                        field["quantity"] = "SINGLE"
                        _field2 = Field.new(field)
                        @fields << _field2
                        @sort << _field2

                    end
                    @containers[_field.name] = _field.data_type if _field.qty == :container




                } if entry["fields"] != nil
            end
        end
        class Config
            attr_accessor :libname, :hfiles
            def initialize(config)
                @libname = config["libname"]
              if config["hfiles"] != nil
                @hfiles = config["hfiles"].split 
              else
                @hfiles=[]
              end
            end
        end
        class Description
            attr_accessor :config
            attr_accessor :entries, :top_entry, :containers

            def initialize(tree)
                @config = Config.new(tree["config"])
                @entries = {}
                @containers = {}

                tree["entries"].each() { |entry|
                    _entry = Entry.new(entry)
                    @top_entry = _entry if (_entry.attribute == :top)
                    _entry.containers.each() { |name, data_type|
                        raise("At least two containers with name '#{name}' are defined and used differents types (#{@containers[name]} and #{data_type}).") if (@containers[name] != nil && @containers[name] != data_type)
                        @containers[name] = data_type

                    }
                    @entries[_entry.name] = _entry
                }
            end
        end
    end
end
