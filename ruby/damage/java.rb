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
    module Java
        require File.dirname(__FILE__) + '/java/header'
        
        def generate(description, pahole)
            libName = description.config.libname
            outdir = "gen/#{libName}/java/"
            description.entries.each(){ |name, entry|
                output = Damage::Files.createAndOpen(outdir, "#{entry.name}.java") 
                params = nameToParams(libName, name)
                Header::write(output, libName, entry, pahole.entries[name], params)
                output.close()
            }
        end
        module_function :generate

        def nameToParams(libName, name)
            params={}
            params[:package] = libName.slice(0,1).upcase + libName.slice(1..-1)
            params[:class] = name.slice(0,1).upcase + name.slice(1..-1)
            return params
        end
        module_function :nameToParams
    end
end
