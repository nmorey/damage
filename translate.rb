#!/usr/bin/ruby
$LOAD_PATH.push(File.dirname(__FILE__) + "/ruby/")

require 'yaml'
require 'damage'

f = File.open(ARGV[0])
tree = YAML::load(f)
desc = Damage::Description::Description.new(tree)
Damage::Structs::write(desc)
Damage::DTD::write(desc)
Damage::Makefile::write(desc)
Damage::Alloc::write(desc)
Damage::GenHeader::write(desc)
Damage::Dot::write(desc)
Damage::Reader::write(desc)
Damage::Writer::write(desc)
