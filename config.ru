#\ -o 0.0.0.0  -p 80

$pwd = Dir.pwd
$LOAD_PATH.unshift(File.expand_path './')

require "./web.rb"
run MyApp
