require 'sinatra'
require 'haml'
require 'json'
require 'fileutils'
require 'digest'

require './controllers/controller.rb'
require './analysis.rb'

controller = WebController.new

get '/' do
  haml :index
end
    
get '/messages/count' do
    
  haml :queued, :locals => {
    :waiting => controller.count
  }
    
end

get '/scan/:id' do
      
    scan = controller.scan params[:id]
    halt 404 if scan.nil?
      
    haml :scan, :locals => {
      :details => scan.created_at,
      :patterns => scan.patterns
    }
end


get '/pattern/:id' do

  pattern = controller.pattern params[:id]
  halt 404 if pattern.nil?
  
  haml :pattern, :locals => {
    :pattern => pattern
  }
    
end  

get '/scan/new/all' do
  controller.analyze(1)
end
  

get '/scan/new' do

end

