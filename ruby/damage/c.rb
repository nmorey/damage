module Damage
  module C
    require File.dirname(__FILE__) + '/c/structs'
    require File.dirname(__FILE__) + '/c/alloc'
    require File.dirname(__FILE__) + '/c/header'
    require File.dirname(__FILE__) + '/c/reader'
    require File.dirname(__FILE__) + '/c/writer'
    require File.dirname(__FILE__) + '/c/makefile'
    require File.dirname(__FILE__) + '/c/tests'

    def generate(description)
      Structs::write(description)
      Alloc::write(description)
      Header::write(description)
      Reader::write(description)
      Writer::write(description)
      Makefile::write(description)
      Tests::write(description)
    end
    module_function :generate
  end
end
