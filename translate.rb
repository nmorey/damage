#!/usr/bin/ruby
$LOAD_PATH.push(File.dirname(__FILE__) + "/ruby/")

require 'yaml'
require 'damage'

f = File.open(ARGV[0])
tree = YAML::load(f)
desc = Damage::Description::Description.new(tree)
Damage::Doc::generate(desc)
Damage::C::generate(desc)
Damage::Ruby::generate(desc)
