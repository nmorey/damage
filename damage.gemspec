Gem::Specification.new do |s|
  s.name        = 'damage'
  s.version     = `git describe --tags`.chomp().gsub(/^v/, "").gsub(/-([0-9]+)-g/, '-\1.g')
  s.date        = `git show HEAD --format='format:%ci' -s | awk '{ print $1}'`.chomp()
  s.summary     = "Your ultimate script for maintaining stable branches and releasing your project."
  s.description = "Damage (DAtabase MetA GEnerator) is a ruby script to create simple and fast databases schemes to use as internal storage in any applications."
  s.authors     = ["Nicolas Morey"]
  s.email       = 'nicolas@morey.ovh'
  s.executables << 'damage'
  s.files       = [
    "COPYING",
    "README.md",
  ] + Dir['lib/**/*.rb'].keep_if { |file| File.file?(file) }
  s.homepage    =
    'https://github.com/nmorey/git-maintain'
  s.license       = 'GPL-2.0-or-later'
end
