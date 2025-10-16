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
            require  File.dirname(__FILE__) + '/wrapper/method_compare.rb'

            def generate(description)
                genWrappers(description)
            end
            module_function :generate

            private
            def genWrapperC(output, description, entry, libName, rowip)
                params=Damage::Ruby::nameToParams(libName, entry.name)
                Header::write(output, entry, libName, params, rowip)
                Mark::write(output, entry, libName, params, rowip)
                Memory::write(output, entry, libName, params, rowip)
                Decorate::write(output, entry, libName, params, rowip)
                ToFile::write(output, entry, libName, params, rowip)
                NewFile::write(output, entry, libName, params, rowip)
                MethodGet::write(output, entry, libName, params, rowip)
                MethodSet::write(output, description, entry, libName, params, rowip)
                MethodCompare::write(output, entry, libName, params, rowip)
                if(entry.attribute == :listable)
                    MethodArray::write(output, entry, libName, params, rowip)
                end
                ToS::write(output, entry, libName, params, rowip)
                #        MethodAcc::write(output, entry, params, rowip)
                Init::write(output, entry, libName, params, rowip)
            end
            def genWrapperEnum(output, description, entry, libName, rowip)
                params=Damage::Ruby::nameToParams(libName, entry.name)
                Header::write(output, entry, libName, params, rowip)
                Init::write(output, entry, libName, params, rowip)
            end
            def genWrapperH(output, entry)
            end

            def genWrappers(description)
                libName = description.config.libname
                outdir = "gen/#{libName}/ruby/"

                
                description.entries.each(){ |name, entry|
                    params=Damage::Ruby::nameToParams(libName, entry.name)
                    
                    #          outputH = Damage::Files.createAndOpen(outdir, "ruby_#{entry.name}.h")
                    outputC = Damage::Files.createAndOpen(outdir, "ruby_#{entry.name}.c") 
                    genWrapperC(outputC, description, entry, libName, description.config.rowip);
                    #          genWrapperH(outputH, entry);
                    outputC.close()
                    #          outputH.close()

                } 

                description.enums.each(){ |name, entry|
                    params=Damage::Ruby::nameToParams(libName, entry.name)
                    
                    #          outputH = Damage::Files.createAndOpen(outdir, "ruby_#{entry.name}.h")
                    outputC = Damage::Files.createAndOpen(outdir, "ruby_#{entry.name}.c") 
                    genWrapperEnum(outputC, description, entry, libName, description.config.rowip);
                    #          genWrapperH(outputH, entry);
                    outputC.close()
                    #          outputH.close()

                } 
            end
            module_function :genWrapperC, :genWrapperH, :genWrappers, :genWrapperEnum

        end
    end
end
