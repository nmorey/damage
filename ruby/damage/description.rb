# -*- coding: utf-8 -*-
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

    # Description modules
    # Defines all the classes that are required
    # for the memory representation of the DB format
    module Description

        # DAMAGE Field
        # This define a data uynit stores in an         
        class Field
            # Name of the field
            attr_accessor :name
            # C data type
            attr_accessor :data_type
            # Java data type
            attr_accessor :java_type
            # Ruby type return or used for get/set
            attr_accessor :ruby_type
            # Type size on file (of rsimple types only)
            attr_accessor :type_size
            # Default value set after allocation
            attr_accessor :default_val
            # Java Default value set after allocation
            attr_accessor :java_default_val

            # Category of data
            # * :simple for straight forward C types
            # * :string for string
            # * :intern for DAMAGE Entry
            # * :enum for an enum (C enum in memory, string in XML)
            # * :id, :idref for XML id, idref (untested)
            attr_accessor :category

            # Field attribute
            # * :meta for memory/runtime data that needs not be stored/loaded from file
            # * :sort for field that is automatically constructed as an index array of another Field of the same entry
            #    Sort fields are not stored/loaded from file
            # * :container for list of Entry that output a special border element in XML mode
            attr_accessor :attribute

            # Field quantity
            # * :single for a single element
            # * :list for a list of elements (if the element is an Entry, it must have the Entry.attributes == :listable)
            # * :container for a list of elements with a specific border element in XML mode
            attr_accessor :qty

            # Wheter the Field exists in the memory representation, the file drepresentation or both
            # * :mem Memory only representation
            # * :file File only representation
            # * :both Memory AND file representation
            attr_accessor :target

            # Wheter the Field can be stored as an XML attribute or nor
            attr_accessor :is_attribute

            # Wheter the field is compulsory (DTD)
            attr_accessor :required

            # Possible values of the field  if category is :enum
            attr_accessor :enum
            # Possible values  of the field  if category is :enum in DTD form
            attr_accessor :enumList
            # Prefix for enum name
            attr_accessor :enumPrefix
            # Field description for documentation
            attr_accessor :description
            # Wheter this field is comparable
            attr_accessor :comparable
            # Modifier to use in printf to print the field value
            attr_accessor :printf
            # Ruby method to convert a ruby VALUE to the field real value
            attr_accessor :ruby2val
            # Ruby method to convert the field real value to a ruby VALUE
            attr_accessor :val2ruby

            # For field with category :sort:
            # Other field (must have cateogyr :intern) from this struct to index automatically
            attr_accessor :sort_field

            # For field with category :sort:
            # Name of the other field to use to sort the Entry
            attr_accessor :sort_key

            # Build a new Field from a parsed YAML tree
            def initialize(libName, entry, field)

                raise ("Field #{field} has no name!") if field["name"] == nil
                @name = field["name"]
                
                @default_val = field["default"]
                @java_default_val = field["default_java"]
                @java_default_val = default_val if @java_default_val == nil

                @attribute = :none
                @qty = :single
                @target = :both
                @is_attribute = false
                @sort_field = field["sort_field"]
                @sort_key = field["sort_key"]
                @description = field["description"]
                @printf = nil
                @enumPrefix = nil

                @required = false
                @required = true if field["required"] != nil

                case field["comparable"]
                when true, nil
                    @comparable=true
                when false
                    @comparable=false
                else
                    raise("Unknown comparable value #{field["comparable"]}")
                end

                case field["quantity"]
                when "SINGLE", "single", nil
                    @qty = :single
                when "LIST", "list"
                    @qty = :list
                    # when "ARRAY"
                    #   @qty = :array
                else
                    raise("Unknown quantity value #{field["quantity"]}")
                end

                case field["attribute"]
                when "META", "meta"
                    @attribute = :meta
                    @target = :mem
                when "SORT", "sort"
                    @attribute = :sort
                    @target = :mem
                when "CONTAINER", "container"
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
                    @java_type = "String"
                    @ruby_type = "string"
                    @category = :string
                    @is_attribute = true if @qty == :single
                    if @default_val == nil then
                        @default_val = "NULL"
                        @java_default_val="null"
                    end
                when "UL"
                    @data_type="unsigned long long"
                    @java_type = "long"
                    @ruby_type = "integer"
                    @category = :simple
                    @printf = "llu"
                    @val2ruby = "ULL2NUM"
                    @ruby2val = "NUM2ULL"
                    @type_size = 8
                    @is_attribute = true if @qty == :single
                    if @default_val == nil then
                        @default_val = "0ULL" 
                        @java_default_val = "0L" 
                    end
                when "SL"
                    @data_type="signed long long"
                    @java_type = "long"
                    @ruby_type = "integer"
                    @category = :simple
                    @printf="lld"
                    @val2ruby = "LL2NUM"
                    @ruby2val = "NUM2LL"
                    @type_size = 8
                    @is_attribute = true if @qty == :singl
                    if @default_val == nil then
                        @default_val = "0LL" 
                        @java_default_val = "0LL" 
                    end
                when "DL"
                    @data_type="double"
                    @java_type = "double"
                    @ruby_type = "float"
                    @category = :simple
                    @type_size = 8
                    if @qty == :single then
                        @is_attribute = true
                    else 
                        @default_val = "NULL"
                    end
                    if @default_val == nil then
                        @default_val = "0.0"
                        @java_default_val = "0.0d"
                    end
                    @printf="lf"
                    @val2ruby = "rb_float_new"
                    @ruby2val = "NUM2DBL"
                when "UI"
                    @data_type = "unsigned int"
                    @java_type = "int"
                    @ruby_type = "integer"

                    @type_size = 4
                    @category = :simple
                    @is_attribute = true if @qty == :single
                    @printf="u"
                    @val2ruby = "UINT2NUM"
                    @ruby2val = "NUM2UINT"
                    if @default_val == nil then
                        @java_default_val = @default_val = "0"
                    end
                when "SI"
                    @data_type = "signed int"
                    @java_type = "int"
                    @ruby_type = "integer"
                    @type_size = 4
                    @category = :simple
                    @is_attribute = true if @qty == :single
                    @printf="d"
                    @val2ruby = "INT2NUM"
                    @ruby2val = "NUM2INT"
                    if @default_val == nil then
                        @java_default_val = @default_val = "0"
                    end
                when /ENUM\(([^)]*)\)/
                    @data_type = "unsigned int"
                    @java_type = @name.slice(0,1).upcase + @name.slice(1..-1)
                    @ruby_type = ":label"
                    @category = :enum
                    @type_size = 4
                    @enumPrefix="__#{libName.upcase}_#{entry.name.upcase}_#{@name.upcase}"
                    raise("Enums cannot be used as containers or list") if @qty != :single
                    @is_attribute = true if @qty == :single
                    @printf="u"
                    @val2ruby = "UINT2NUM"
                    @ruby2val = "NUM2UINT"
                    @enumList="(#{$1})"
                    @enum={}
                    $1.split('|').each() {|e|
                        @enum[e] = e.sub(/[^[:alnum:]]/, "_").upcase
                    }
                    if @default_val == nil then 
                        @default_val = "0"  
                        @java_default_val = "#{@java_type}.N_A"
                    else
                        @java_default_val = "#{@java_type}.#{@default_val.sub(/[^[:alnum:]]/, "_").upcase}"
                        @default_val = "#{@enumPrefix}_#{@default_val.sub(/[^[:alnum:]]/, "_").upcase}"  
                    end

                when /(S|STRUCT)\(([\w+ ]*)\)/
                    @data_type = $2
                    @java_type = @data_type.slice(0,1).upcase + @data_type.slice(1..-1)
                    @ruby_type = @java_type
                    @category = :intern
                    if @default_val == nil then 
                        @default_val = "NULL"
                        @java_default_val = "null"
                    end
                    puts "This format is not DTD compatible (Field #{@name} has type #{@data_type})" if ((@data_type != @name) && (@target != :mem) && (@attribute != :container))
                when /(A|ARRAY)\(([\w+ ]*)\)/
                    @data_type = "#{$2}*"
                    @java_type = $2.slice(0,1).upcase + $2.slice(1..-1) +"[]"
                    @category = :intern
                    if @default_val == nil then
                        @default_val = "NULL"  
                        @java_default_val = "null"
                    end
                when "ID"
                    @category = :id
                    @default_val = "0UL"  if @default_val == nil
                    @is_attribute = true
                when /IDREF\(([\w+ ]*)\)/
                    @data_type = $1
                    @category = :idref
                    @default_val = "0UL" if @default_val == nil
                    @is_attribute = true
                when nil
                    @data_type = @name
                    @java_type = @data_type.slice(0,1).upcase + @data_type.slice(1..-1)
                    @ruby_type = @java_type

                    @category = :intern
                    if @default_val == nil then 
                        @default_val = "NULL" 
                        @java_default_val = "null"
                    end
                    puts "This format is not DTD compatible (Field #{@name} has type #{@data_type})" if ((@data_type != @name) && (@target != :mem) && (@attribute != :container))

                else
                    raise("Field #{@name} has no data type...")
                end
                @java_default_val = "null" if @qty == :list && @category == :simple
            end
        end

        # DAMAGE Entry
        # An entry is a structure than contains data (standard types or pointers to other entries)
        class Entry
            # Name of the entry used for class and struct generation
            attr_accessor :name
            # Entry attribute (TOP if top entry or LISTABLE if they need to be used as a chained list)
            attr_accessor :attribute
            # List of the fields (data) stored in the Entry
            attr_accessor :fields
            # List of the fields which needs to be stored as children (not attributes) in XML mode
            attr_accessor :children
            # List of the fields which needs to be stored as attributes (not children) in XML mode
            attr_accessor :attributes
            # List of the fields that are automatically sorted lists  (see Field for more info)
            attr_accessor :sort
            # List of the fields that are containers (see Field for more info)
            attr_accessor :containers
            # List of the fields that are enums (see Field for more info)
            attr_accessor :enums
            # Name of the eventual cleanup functioon (called after parsing the entry)
            attr_accessor :cleanup
            # Name of the eventual postcleanup functioon (called after freeing the entry)
            attr_accessor :postcleanup
            # Description of the entry (for documentation)
            attr_accessor :description
            # Wheter two entries of this types are comparable or not. If not, they are always equals
            attr_accessor :comparable

            # Build an entry from a parsed YAML tree

            def initialize(libName, entry)
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

                @description = entry["description"]

                case entry["attribute"]
                when "TOP"
                    @attribute = :top
                when "LISTABLE"
                    @attribute = :listable
                when nil
                else
                    raise("Unknown entry attribute #{entry["attribute"]}")
                end

                case entry["comparable"]
                when "YES","yes", "true", "TRUE", true, nil
                    @comparable= true
                when "NO","no","false", "FALSE",false
                    @comparable= false
                else
                    raise("Unknown comparable value #{entry["comparable"]}")
                end

                entry["fields"].each() { |field|
                    _field =  Field.new(libName, self, field)
                    
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
                        # Add the new implied field
                        field["attribute"] = "SORT"
                        field["sort_field"] = field["name"]
                        field["quantity"] = "SINGLE"
                        _field2 = Field.new(libName, self, field)
                        @fields << _field2
                        @sort << _field2

                    end
                    @containers[_field.name] = _field.data_type if _field.qty == :container




                } if entry["fields"] != nil
            end
        end

        # DAMAGE library config
        # Contains settings for the code generation
        class Config
            # Name of the library
            attr_accessor :libname
            # List of headers to include in the global damahe header
            attr_accessor :hfiles
            # Version of the generated library
            attr_accessor :version
            # Description of the library for documentation
            attr_accessor :description
            # Should ROWIP be generated or not
            attr_accessor :rowip
            # Java package prefix
            attr_accessor :package
            #Version of damage
            attr_accessor :damage_version

            # Build a new config from a parsed YAML tree
            def initialize(config)
                @libname = config["libname"]
                raise("Missing a library name") if @libname == nil
                @description = config["description"]
                @version="N/A"
                @package=config["package"]
                if config["hfiles"] != nil
                    @hfiles = config["hfiles"].split 
                else
                    @hfiles=[]
                end
                @version = config["version"] if config["version"] != nil
                @rowip = true
                @rowip = false if config["norowip"] != nil
            end
        end

        # Contains a DAMAGE database description
        # including library config, and entry list
        class Description
            # Return the Config associated with the description
            attr_accessor :config
            # Returns a map of the DB entries index by their name
            attr_accessor :entries
            # Returns the top entry (highesht entry of all)
            attr_accessor :top_entry
            # Returns a list of all the containers defined in the entries
            # This is useful are containers are implied entries only defined as field
            attr_accessor  :containers
            # Pointer to pahole description
            attr_accessor :pahole

            # Build a description from a parsed YAML tree
            def initialize(tree)
                @config = Config.new(tree["config"])
                @entries = {}
                @containers = {}

                #Iterate one each entry and eventually store it as top or store its containers as needed
                tree["entries"].each() { |entry|
                    _entry = Entry.new(config.libname, entry)
                    @top_entry = _entry if (_entry.attribute == :top)
                    _entry.containers.each() { |name, data_type|
                        raise("At least two containers with name '#{name}' are defined and used differents types (#{@containers[name]} and #{data_type}).") if (@containers[name] != nil && @containers[name] != data_type)
                        @containers[name] = data_type

                    }
                    @entries[_entry.name] = _entry
                }
            end
        end

        class Pahole
            attr_accessor :entries
            def to_s
                str=""
                entries.each(){ |name, vals|
                    str+= "Struct: #{name} - Size: #{vals[:size]}\n"
                    vals.each(){|field, params|
                        next if field == :size
                        str += "\tField: #{field} - Offset/Size: #{params[:offset]}/#{params[:size]}\n"
                    }
                    
                }
                return str
            end
            def initialize(prefix, input)
                inStruct = false
                @entries={}
                input.each_line() { |line|
                    if inStruct == false then
                        next if line =~ /^struct ___#{prefix}_db_lock\s+\{\s*$/
                        next if line !~ /^struct ___#{prefix}_(.*)\s+\{\s*$/
                        inStruct = $1
                        @entries[inStruct] = {}
                    else
                        if line =~ /^\};.*$/ then
                            inStruct = false
                            next
                        elsif line =~ /^(.*)\s(\S+);\s+\/\*\s+([0-9]+)\s+([0-9]+)\s+\*\/\s*$/
                            field=$2
                            offset=$3
                            size=$4
                            @entries[inStruct][field]={}
                            @entries[inStruct][field][:offset] = offset
                            @entries[inStruct][field][:size] = size
                        elsif line =~ /^\s*\/\*\s+size:\s+([0-9]+), .*\*\/\s*$/
                            @entries[inStruct][:size] = $1
                        else
                            #Ignore line
                        end
                    end
                }
            end
        end
    end
end
