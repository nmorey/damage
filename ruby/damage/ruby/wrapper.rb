module Damage
  module Ruby
    module Wrapper

      require  File.dirname(__FILE__) + '/wrapper/header.rb'
      require  File.dirname(__FILE__) + '/wrapper/memory.rb'
      require  File.dirname(__FILE__) + '/wrapper/mark.rb'
      require  File.dirname(__FILE__) + '/wrapper/decorate.rb'
      require  File.dirname(__FILE__) + '/wrapper/to_file.rb'
      require  File.dirname(__FILE__) + '/wrapper/new_file.rb'
      require  File.dirname(__FILE__) + '/wrapper/method_get.rb'
      require  File.dirname(__FILE__) + '/wrapper/method_set.rb'
      require  File.dirname(__FILE__) + '/wrapper/method_array.rb'
      require  File.dirname(__FILE__) + '/wrapper/to_s.rb'
      require  File.dirname(__FILE__) + '/wrapper/init.rb'

      def generate(description)
        genWrappers(description)
      end
      module_function :generate

      private
      def genWrapperC(output, entry, libName)
        params=Damage::Ruby::nameToParams(libName, entry.name)
        Header::write(output, entry, libName, params)
        Mark::write(output, entry, libName, params)
        Memory::write(output, entry, libName, params)
        Decorate::write(output, entry, libName, params)
        ToFile::write(output, entry, libName, params)
        NewFile::write(output, entry, libName, params)
        MethodGet::write(output, entry, libName, params)
        MethodSet::write(output, entry, libName, params)
        if(entry.attribute == :listable)
          MethodArray::write(output, entry, libName, params)
        end
        ToS::write(output, entry, libName, params)
        #        MethodAcc::write(output, entry, params)
        Init::write(output, entry, libName, params)
      end

      def genWrapperH(output, entry)
      end

      def genWrappers(description)
        libName = description.config.libname
        outdir = "gen/#{libName}/ruby/"

        
        description.entries.each(){ |name, entry|
          params=Damage::Ruby::nameToParams(libName, entry.name)
          
          outputH = Damage::Files.createAndOpen(outdir, "ruby_#{entry.name}.h")
          outputC = Damage::Files.createAndOpen(outdir, "ruby_#{entry.name}.c") 
          genWrapperC(outputC, entry, libName);
          genWrapperH(outputH, entry);
          outputC.close()
          outputH.close()

        } 
      end
      module_function :genWrapperC, :genWrapperH, :genWrappers

    end
  end
end
