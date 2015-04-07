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


get '/patterns/:pattern_id/messages/?' do
  pattern = controller.pattern params[:pattern_id]
  halt 404 if pattern.nil?
  puts pattern.messages
  JSON.generate pattern.messages
end

post '/patterns/:id' do
  pattern = controller.pattern params[:id]
  halt 404 if pattern.nil? or not params.include? "json"
  puts params
  new_pattern = JSON.parse(request.env["rack.input"].read)

  pattern.body = new_pattern["body"]
  pattern.body_split = body_split(pattern.body)
  pattern.final = new_pattern["final"]
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


post '/final/?' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)
  controller.final(params["id"])
end

