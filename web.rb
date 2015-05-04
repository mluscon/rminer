require 'sinatra'
require 'haml'
require 'json'
require 'fileutils'
require 'digest'

require './controllers/controller.rb'
require './helpers/helper.rb'

controller = WebController.new

get '/' do
  haml :index
end

get '/algorithms/?' do
  algs = get_algorithms('/plugins/')
  puts JSON.generate algs
  JSON.generate algs
end

get '/login/' do
  haml :login
end

get '/variables/?' do
  if params.include? "json"
    JSON.generate controller.variables
  else
    haml :variables
  end
end

get '/scans/?' do
  if params.include? "json"
    json = controller.scans_serial
    JSON.generate(json.reverse)
  else
    haml :scans, :locals => {
      :scans => controller.scans
    }
  end
end

get '/scans/:id' do
  scan = controller.scan params[:id]
  halt 404 if scan.nil? or not params.include? "json"

  res = []
  scan.messages.each do |msg|
    res << {
            :id => msg.id,
            :body => msg.body
           }
  end
  JSON.generate res
end

get '/patterns/finalized/?' do
  if params.include? "json"
    JSON.generate Pattern.all(:finalized=>true)
  else
    haml :patterns
  end
end

get '/patterns/:id' do
  pattern = controller.pattern params[:id]
  halt 404 if pattern.nil?

  if params.include? "json"
    res = []
    pattern.messages.each do |msg|
      res << { :id => msg.id,
              :body => msg.body
             }
    end
    JSON.generate res
  else
    haml :patterns, :locals => {
         :pattern => pattern
    }
  end
end


get '/patterns/:id/messages/?' do
  pattern = controller.pattern params[:id]
  halt 404 if pattern.nil?
  JSON.generate pattern.messages
end

post '/patterns/:id' do

  halt 404 if params[:id].nil? or not params.include? "json"
  new_pattern = JSON.parse(request.env["rack.input"].read)

  controller.pattern_save new_pattern
end


post '/patterns/finalize/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)

  controller.pattern_finalize(params["id"])
end

delete '/patterns/finalize/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)

  controller.pattern_unfinalize(params["id"])
end


get '/messages/?' do
  msgs = controller.messages
  if params.include? "json"
    res = []
    msgs.each do |msg|
      res << { :id => msg.id,
               :body => msg.body
             }
    end
    JSON.generate( res )
  else
    haml :messages, :locals => {
      :messages => msgs
    }
  end
end

get '/info/?' do
  info = controller.info
  JSON.generate(info)
end

post '/scan/new/?' do
  halt 404 if params.nil?

  params = JSON.parse(request.env["rack.input"].read)
  sensitivity = params["sensitivity"].to_f
  msg_ids = params["msgs"]
  parent = params["parent"]
  algorithm = params["algorithm"]

  halt 404 if sensitivity == 0 || sensitivity > 1
  halt 404 if msg_ids.nil?
  halt 404 if algorithm.nil? or algorithm == ""

  controller.analyze(msg_ids, parent, algorithm, sensitivity, params["separator"])
end

post '/scan/packed/?' do
  params = JSON.parse(request.env["rack.input"].read)
  halt 404 if params["id"].nil?
  controller.scan_pack(params["id"], params["value"])
end

post '/scan/finalize/?' do
  params = JSON.parse(request.env["rack.input"].read)
  halt 404 if params["id"].nil?

  controller.scan_finalize(params["id"])
end

delete '/scans/:id' do
  halt 404 if params.nil?

  controller.scan_remove(params["id"].to_i)
end

delete '/patterns/:id' do
  halt 404 if params.nil?

  controller.pattern_remove(params["id"].to_i)
end

post '/final/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)
  controller.final(params["id"])
end

get '/treenode/?' do
  haml :treenode
end

get '/variables/?' do
  if params.include? "json"
    JSON.generate controller.variables
  else
    haml :variables
  end
end

post '/variables/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)

  File.open("./variables.yml", "w") { |file| file.write(params.to_yaml) }
end

