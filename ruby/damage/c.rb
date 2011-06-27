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
    module C
        require File.dirname(__FILE__) + '/c/structs'
        require File.dirname(__FILE__) + '/c/alloc'
        require File.dirname(__FILE__) + '/c/header'
        require File.dirname(__FILE__) + '/c/common'
        require File.dirname(__FILE__) + '/c/sort'
        require File.dirname(__FILE__) + '/c/reader'
        require File.dirname(__FILE__) + '/c/writer'
        require File.dirname(__FILE__) + '/c/binary_reader'
        require File.dirname(__FILE__) + '/c/binary_writer'
        require File.dirname(__FILE__) + '/c/binary_rowip'
        require File.dirname(__FILE__) + '/c/makefile'
        require File.dirname(__FILE__) + '/c/tests'


        def generate(description)
            Structs::write(description)
            Alloc::write(description)
            Header::write(description)
            Common::write(description)
            Sort::write(description)
            Reader::write(description)
            Writer::write(description)
            BinaryReader::write(description)
            BinaryWriter::write(description)
            BinaryRowip::write(description)
            Makefile::write(description)
            Tests::write(description)
        end
        module_function :generate
    end
end
