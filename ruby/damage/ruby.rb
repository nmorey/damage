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

    require File.dirname(__FILE__) + '/ruby/global'
    require File.dirname(__FILE__) + '/ruby/wrapper'
    require File.dirname(__FILE__) + '/ruby/makefile'
    require File.dirname(__FILE__) + '/ruby/tests'


    def generate(description)
      Makefile::write(description)
      Global::write(description)
      #Generate C files per class
      Wrapper::generate(description)
      #      
      genExtConf(description)
      Tests::write(description)
    end
    module_function :generate


    #Generate class name, C type  and prefixes from an entry or field name
    def nameToParams(libName, name)
      params={}
      params[:className] = name.slice(0,1).upcase + name.slice(1..-1)
      params[:classNameList] = name.slice(0,1).upcase + name.slice(1..-1) + "List"
      params[:funcPrefix] = "rub#{params[:className]}"
      params[:funcPrefixList] = "rub#{params[:className]}List"
      params[:classValue] = "cDAMAGE#{params[:className]}"
      params[:classValueList] = "cDAMAGE#{params[:className]}List"
      params[:cType] = "__#{libName}_#{name}"
      params[:cTypeList] = "__#{libName}_#{name}List"
      return params
    end
    module_function :nameToParams

    private
    def genExtConf(description)
      libName = description.config.libname
      output = Damage::Files.createAndOpen("gen/#{libName}/ruby/", "extconf.rb")
      arch=`uname -m`.chomp
      output.printf('
    require \'mkmf\'
    $CFLAGS = $CFLAGS + " -I../include/ " + `xml2-config --cflags`
    $LIBS = $LIBS + " ../obj/' + arch +'/lib%s.a " + `xml2-config --libs`
    create_makefile("lib%s_ruby")
    ', libName, libName);
      output.close()
    end
    module_function :genExtConf

  end
end
