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

get '/scans/' do
  if params.include? "json"
    json = controller.scans_serial
    puts JSON.generate(json.reverse)
    JSON.generate(json.reverse)
  else
    haml :scans, :locals => {
      :scans => controller.scans
    }
  end
end


get '/scans/:id' do

  scan = controller.scan params[:id]
  halt 404 if scan.nil?

  patterns = scan.patterns(:final => false)

  haml :scan, :locals => {
    :tag => scan.tag,
    :details => scan.created_at,
    :patterns => patterns
  }
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
    JSON.generate( res )
  else
    haml :patterns, :locals => {
         :pattern => pattern
    }
  end

end

get '/messages/' do

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

post '/scan/new' do
  halt 404 if params.nil?

  params = JSON.parse(request.env["rack.input"].read)
  sensitivity = params["sensitivity"].to_i
  msg_ids = params["msgs"]
  tag = params["tag"]
  parent = params["parent"]

  halt 404 if sensitivity == 0 || sensitivity > 1
  halt 404 if msg_ids.nil? || tag.nil?

  controller.analyze(params["sensitivity"], params["msgs"], params["separator"], params["tag"], params["parent"])
end

post '/scan/hide/' do

  params = JSON.parse(request.env["rack.input"].read)
  puts "id: " + params["id"].to_s
  controller.scan_hide(params["id"])
end

post '/remove/' do
  halt 404 if params.nil? or
  params = JSON.parse(request.env["rack.input"].read)


  controller.remove(params["msgs"])
end

post '/final/' do
  halt 404 if params.nil?
  params = JSON.parse(request.env["rack.input"].read)
  controller.final(params["id"])
end

