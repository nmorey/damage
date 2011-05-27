module Damage
  module Description
    class Field
      attr_accessor :name, :data_type, :default_val, :category, :attribute, :qty

      # Data used only for SORT fields
      attr_accessor :sort_field, :sort_key
      def initialize(tree)
        @name = tree["name"]
        @default_val = tree["default"]
        case tree["quantity"]
        when "SINGLE", nil
          @qty = :single
        when "LIST"
          @qty = :list
        when "ARRAY"
          @qty = :array
        end
        case tree["attribute"]
        when "META"
          @attribute = :meta
        when "SORT"
          @attribute = :sort
          @sort_field = tree["sort_field"]
          @sort_key = tree["sort_key"]
        when "PASS"
          @attribute = :pass
        else
          @attribute = :none
        end

        case tree["type"]
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
        when /STRUCT\(([\w+ ]*)\)/
          @data_type = $1
          @category = :intern
        end
        
      end
    end

    class Struct
    end
  end
end
