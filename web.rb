require 'sinatra'
require 'haml'
require 'json'
require 'fileutils'
require 'digest'

require './controllers/controller.rb'
require './analysis.rb'

controller = WebController.new

get '/' do
  haml :index, :locals => {
    :unprocessed => controller.waiting,
    :active => controller.scan_count(true),
    :scans => controller.scan_count
  }
end

get '/scans/' do
  haml :scans, :locals => {
    :scans => controller.scans
  }
end


get '/scans/:id' do
      
  scan = controller.scan params[:id]
  halt 404 if scan.nil?
      
  haml :scan, :locals => {
    :details => scan.created_at,
    :patterns => scan.patterns
  }
end


get '/patterns/:id' do

  pattern = controller.pattern params[:id]
  halt 404 if pattern.nil?
  
  haml :patterns, :locals => {
    :pattern => pattern
  }
    
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
  

post '/scan/new/all' do
  controller.analyze(1)
end
  

post '/scan/new' do
  msgs = params[:msgs]
  sens = params[:sensitivity].to_i
  
  halt 404 if msgs.nil? 
  
  msgs[0] = ''
  msgs[-1] = ''
  msgs = msgs.split(', ')
  
  
  controller.analyze(sens, msgs)
  
  redirect "/scans/"
end

