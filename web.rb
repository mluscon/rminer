require 'sinatra'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'haml'
require 'json'
require 'fileutils'
require 'digest'
require 'tempfile'
require 'warden'
require 'logger'

require './controllers/controller.rb'
require './helpers/helper.rb'
require './config.rb'

class MyApp < Sinatra::Application
  conf = RminerConf.new
  controller = WebController.new

  set :static, true
  set :port, conf.web_port
  set :sessions => true
  set :session_secret => conf.web_secret
  set :environment => :production
  register Sinatra::Flash

  logger = Logger.new('./logs/web.log')
  use Rack::CommonLogger, logger


  # setup authentication
  use Warden::Manager do |config|
    config.serialize_into_session{|user| user.id }
    config.serialize_from_session{|id| User.get(id) }

    config.scope_defaults :default,
                          strategies: [:password],
                          action: 'auth/unauthenticated'

    config.failure_app = self
  end

  Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end


  Warden::Strategies.add(:password) do
    def valid?
      params['username'] && params['password']
    end

    def authenticate!
      user = User.first(:username => params['username'])

      if user.nil?
        throw(:warden, message: "The username you entered does not exist.")
      elsif user.authenticate(params['password'])
        success!(user)
      else
        throw(:warden, message: "The username and password combination ")
      end
    end
  end


  get '/' do
    env['warden'].authenticate!

    haml :index
  end


  get '/algorithms/?' do
    env['warden'].authenticate!

    algs = get_algorithms($pwd + '/plugins/')
    JSON.generate algs
  end


  get '/auth/login/?' do
    haml :login
  end


  post '/auth/login/?' do
    env['warden'].authenticate!
    flash[:success] = env['warden'].message

    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end


  get '/auth/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout
    redirect '/auth/login/', :success => 'Successfully logged out'
  end


  post '/auth/unauthenticated' do
    session[:return_to] = env['warden.options'][:attempted_path]
    puts env['warden.options'][:attempted_path]
    flash[:error] = env['warden'].message || "You must log in"
    redirect '/auth/login'
  end


  get '/download/?' do
    env['warden'].authenticate!
    controller.results {|path| send_file path,
                               :filename => "patterns.json",
                               :type => 'Text/json'
                       }
  end


  get '/info/?' do
    env['warden'].authenticate!

    info = controller.info
    JSON.generate info
  end


  get '/messages/?' do
    env['warden'].authenticate!

    msgs = controller.messages
    halt 404 if not msgs
    if params.include? "json"
      JSON.generate msgs
    else
      haml :messages, :locals => {
        :messages => msgs
      }
    end
  end


  delete '/patterns/:id' do
    env['warden'].authenticate!
    halt 404 if params.nil?

    controller.pattern_remove params["id"].to_i
  end


  post '/patterns/:id' do
    env['warden'].authenticate!
    halt 404 if params[:id].nil? or not params.include? "json"

    new_pattern = JSON.parse(request.env["rack.input"].read)
    halt 404 if not controller.pattern_save new_pattern
  end


  get '/patterns/finalized/?' do
    env['warden'].authenticate!

    if params.include? "json"
      JSON.generate Pattern.all(:finalized=>true)
    else
      haml :patterns
    end
  end


  post '/patterns/finalize/?' do
    env['warden'].authenticate!
    halt 404 if params.nil?

    params = JSON.parse(request.env["rack.input"].read)
    halt 404 if not controller.pattern_finalize(params["id"])
  end


  delete '/patterns/finalize/?' do
    env['warden'].authenticate!
    halt 404 if params.nil?

    params = JSON.parse(request.env["rack.input"].read)
    halt 404 if not controller.pattern_unfinalize(params["id"])
  end


  get '/patterns/:id/messages/?' do
    env['warden'].authenticate!
    halt 400 if not params[:id] or not params.include? "json"

    result = controller.messages(params[:id].to_i)
    if result
      JSON.generate result
    else
      halt 404
    end
  end

  get '/patterns/:id' do
    env['warden'].authenticate!
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


  get '/scans/?' do
    env['warden'].authenticate!

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
    env['warden'].authenticate!
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


  delete '/scans/:id' do
    env['warden'].authenticate!
    halt 404 if params.nil?

    controller.scan_remove(params["id"].to_i)
  end


  post '/scan/new/?' do
    env['warden'].authenticate!
    params = JSON.parse(request.env["rack.input"].read)
    halt 400 if params.nil?

    sensitivity = params["sensitivity"].to_f
    msg_ids = params["msgs"]
    parent = params["parent"]
    algorithm = params["algorithm"]
    separator = params["separator"] or ' '

    halt 400 if sensitivity == 0 || sensitivity > 1
    halt 400 if msg_ids.nil?
    halt 400 if algorithm.nil? or algorithm == ""

    halt 404 if not controller.analyze(msg_ids,
                                       parent,
                                       algorithm,
                                       sensitivity,
                                       separator)
  end


  post '/scan/finalize/?' do
    env['warden'].authenticate!
    params = JSON.parse(request.env["rack.input"].read)
    halt 404 if params["id"].nil?

    halt 404 if not controller.scan_finalize(params["id"])
  end


  get '/variables/?' do
    env['warden'].authenticate!
    if params.include? "json"
      vars = controller.variables
      JSON.generate vars
    else
      haml :variables
    end
  end


  post '/variables/?' do
    env['warden'].authenticate!
    halt 400 if params.nil?
    params = JSON.parse(request.env["rack.input"].read)

    File.open("./variables.yml.new", "w") {|file| file.write(params.to_yaml)}
  end

end


