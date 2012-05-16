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
  module Files

    require 'fileutils'
    class DFile < File
        attr_accessor :dir, :name
        attr_accessor :copyOnClose

        def initialize(dir, name, mode="w")
            FileUtils.mkdir_p dir
            @dir = dir
            @name = name
            if File.exists?("#{dir}/#{name}") then
                super("#{dir}/#{name}_", mode);
                @copyOnClose = true
            else
                super("#{dir}/#{name}", mode);
                @copyOnClose = false
            end
        end

        def close()
            super
            if @copyOnClose == true then
                if FileUtils.compare_file("#{dir}/#{name}_", "#{dir}/#{name}") == true
                else
#                    STDOUT.puts "Copying #{dir}/#{name}_ -> #{dir}/#{name}"
                    FileUtils.mv("#{dir}/#{name}_",  "#{dir}/#{name}")
                end
            end
        end
    end
    def createAndOpen(dir, name, mode="w")
        return DFile.new(dir, name, mode)
    end
    module_function :createAndOpen
  end
end
