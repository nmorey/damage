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
      attr_accessor :name, :attribute, :fields
      def initialize(entry)
        @name = entry["name"]
        @attribute = :none
        @cleanup = nil
        @fields = []
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
          @fields << Field.new(field)
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
      attr_accessor :entries, :top_entry

      def initialize(tree)
        @config = Config.new(tree["config"])
        @entries = {}
        tree["entries"].each() { |entry|
          _entry = Entry.new(entry)
          @top_entry = _entry if (_entry.attribute == :top)
          @entries[_entry.name] = _entry
        }
      end
    end
  end
end
