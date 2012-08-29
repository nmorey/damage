#!/usr/bin/ruby
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

$LOAD_PATH.push(File.dirname(__FILE__) + "/ruby/")

require 'yaml'
require 'damage'
require 'optparse'

def mergeYAML(tree1, tree2)
    raise("Cannot merge this sections (Hash vs Array)") if tree1.class != tree2.class
    if(tree1.class == Hash) then
        tree2.each(){|name, subsubtree|
            if(tree1[name] == nil)
                tree1[name] = tree2[name]
            else
                mergeYAML(tree1[name], tree2[name])
            end
        }
    elsif(tree1.class == Array)
        tree2.each(){|el|
            tree1 << el
        }
    else
        raise("Unsupported subtree to merge")
    end
end

opts={}
opts[:file] = []
optsParser = OptionParser.new(nil, 60)
optsParser.banner = "Usage: #{File.basename(__FILE__)} [OPTIONS...] --file file.yaml [--file file2.yaml...]"
optsParser.separator ""
optsParser.separator "Options:"

optsParser.on("-f", "--file <file.yaml>", String, "YAML DB description.") {|val| opts[:file] << val}
optsParser.on("-p", "--pahole <pahole.result>", String, "Path to pahole size infos.") {|val| opts[:pahole] = val}
optsParser.on("-h", "--help",  "Display usage.") { |val| puts optsParser.to_s; exit 0 }
rest = optsParser.parse(ARGV);

raise("Required YAML files")  if opts[:file].length == 0
tree = nil
opts[:file].each(){|fName|
    f = File.open(fName)
    subtree = YAML::load(f)
    if tree != nil
        mergeYAML(tree, subtree)
    else
        tree = subtree
    end
    f.close()
}
desc = Damage::Description::Description.new(tree)
desc.config.damage_version = `cd #{File.dirname(__FILE__)}; git rev-parse HEAD; cd - > /dev/null`.chomp()

if opts[:pahole] == nil then 
    Damage::Doc::generate(desc)
    Damage::C::generate(desc)
    Damage::Ruby::generate(desc)
else
    input = File.open(opts[:pahole])
    desc.pahole = Damage::Description::Pahole.new(desc.config.libname, input)
    Damage::Java::generate(desc, desc.pahole)
end
