require 'daemons'

$LOAD_PATH.unshift(File.expand_path './')
$pwd = Dir.pwd

Daemons.run('./main.rb')
