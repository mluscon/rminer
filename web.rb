require 'sinatra'
require 'haml'
require 'json'
require 'fileutils'
require 'digest'

require './controllers/controller.rb'
require './analysis.rb'
require './helpers/helper.rb'

controller = WebController.new

get '/' do
  haml :index
end

get '/login/' do
  haml :login
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

delete '/scans/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)

  scan = Pattern.get(params["id"])
  controller.scan_remove(scan)
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

post '/patterns/:id' do
  pattern = controller.pattern params[:id]
  halt 404 if pattern.nil? or not params.include? "json"
  puts params
  new_pattern = JSON.parse(request.env["rack.input"].read)

  pattern.body = new_pattern["body"]
  pattern.body_split = body_split(pattern.body)
  pattern.save
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

post '/scan/new/?' do
  halt 404 if params.nil?

  params = JSON.parse(request.env["rack.input"].read)
  sensitivity = params["sensitivity"].to_f
  msg_ids = params["msgs"]
  parent = params["parent"]

  halt 404 if sensitivity == 0 || sensitivity > 1
  halt 404 if msg_ids.nil?

  controller.analyze(sensitivity, msg_ids, params["separator"], parent)
end

post '/scan/packed/?' do
  params = JSON.parse(request.env["rack.input"].read)
  controller.scan_pack(params["id"], params["value"])
end

post '/remove/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)
  controller.remove(params["msgs"])
end

post '/final/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)
  controller.final(params["id"])
end

