#!/usr/bin/ruby
$LOAD_PATH.push("./ruby/")

require 'yaml'
require 'damage'

f = File.open(ARGV[0])
tree = YAML::load(f)
p tree
desc = Damage::Description::Description.new(tree)
p desc
Damage::Structs::write(desc)
