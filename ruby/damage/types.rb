module Damage
  module Description
    class Field
      attr_accessor :name, :data_type, :default_val, :category, :attribute, :qty

      # Data used only for SORT fields
      attr_accessor :sort_field, :sort_key
      def initialize(field)
        @name = field["name"]
        @default_val = field["default"]
        @attribute = :none
        @qty = :single
        case field["quantity"]
        when "SINGLE", nil
          @qty = :single
        when "LIST"
          @qty = :list
        when "ARRAY"
          @qty = :array
        end
        case field["attribute"]
        when "META"
          @attribute = :meta
        when "SORT"
          @attribute = :sort
          @sort_field = field["sort_field"]
          @sort_key = field["sort_key"]
        when "PASS"
          @attribute = :pass
        when "CONTAINER"
          @attribute = :container
        else
          raise("Unknown field attribute #{field["attribute"]}")
        end

        case field["type"]
        when "String"
          @data_type = "char*"
          @category = :simple
          @is_attribute = true if @qty == :single
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
        else
          raise("Unknown entry attribute #{entry["attribute"]}")
        end
        entry["fields"].each() { |field|
          @fields << Field.new(field)
        }
      end
    end
    class Config
      attr_accessor :libname
      def initialize(config)
        @libname = config["libname"]
      end
    end
    class Descriptrion
      attr_accessor :config
      attr_accessor :entries, :top_entry

      def initialize(tree)
        @config = Config.new(tree["config"])
        @entries = []
        tree["entries"].each() { |entry|
          _entry = Entry.new(entry)
          @top_entry = _entry if (_entry.attribute == :top)
          @entries << _entry
        }
      end
    end
  end
end
