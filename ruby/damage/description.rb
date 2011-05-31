module Damage
  module Description
    class Field
      attr_accessor :name, :data_type, :default_val, :category, :attribute, :qty, :target, :is_attribute, :required, :enum

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

        @required = false
        @required = true if field["required"] != nil

        @enum=field["enum"]
        
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
          @sort_field = field["sort_field"]
          @sort_key = field["sort_key"]
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
          @is_attribute = true if @qty == :single
          @default_val = "0UL"
        when "DL"
          @data_type="double"
          @category = :simple
          @is_attribute = true if @qty == :single
          @default_val = "0.0"
        when /T\(([\w+ ]*)\)/
          @data_type = $1
          @category = :simple
          @is_attribute = true if @qty == :single
        when /EXT\(([\w+ ]*)\)/
          @data_type = $1
          @category = :simple
        when /(S|STRUCT)\(([\w+ ]*)\)/
          @data_type = $2
          @category = :intern
          @default_val = "NULL"
          puts "This format is not DTD compatible (Field #{@name} has type #{@data_type})" if ((@data_type != @name) && (@target != :mem) && (@attribute != :container))
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
      attr_accessor :name, :attribute, :fields, :children, :attributes, :sort, :containers
      def initialize(entry)
        @name = entry["name"]
        @attribute = :none
        @cleanup = nil
        @fields = []
        @children = []
        @attributes = []
        @sort = []
        @containers = {}

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
          @children << _field if _field.is_attribute == false && _field.target != :mem
          @attributes << _field if _field.is_attribute == true && _field.target != :mem
          @sort << _field if _field.attribute == :sort
          @containers[_field.name] = _field.data_type if _field.qty == :container

          @fields << _field
        } if entry["fields"] != nil
      end
    end
    class Config
      attr_accessor :libname
      def initialize(config)
        @libname = config["libname"]
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
