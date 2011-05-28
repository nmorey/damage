module Damage
  module Files

    require 'fileutils'
    
    def createAndOpen(dir, name, mode="w")
       FileUtils.mkdir_p dir
      return File.open("#{dir}/#{name}", mode)
    end
    module_function :createAndOpen
  end
end
