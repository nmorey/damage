#!/usr/bin/ruby
$LOAD_PATH.push(File.dirname(__FILE__) + "/ruby/")

require 'yaml'
require 'damage'

f = File.open(ARGV[0])
tree = YAML::load(f)
desc = Damage::Description::Description.new(tree)
Damage::Structs::write(desc)
Damage::DTD::write(desc)