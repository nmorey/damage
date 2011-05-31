module Damage
  module Doc
    require File.dirname(__FILE__) + '/doc/dot'
    require File.dirname(__FILE__) + '/doc/dtd'

    def generate(description)
      Dot::write(description)
      DTD::write(description)
    end
    module_function :generate
  end
end
