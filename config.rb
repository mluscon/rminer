require 'parseconfig'

class RminerConf
  attr_reader(
    :amqp_server,
    :amqp_channel,
    :workers,
    :cache_size,
    :logfile,
    :host,
    :database,
    :user,
    :password,
    :adapter,
    :web_port,
    :web_secret
  )


  def initialize
    config = ParseConfig.new($pwd + '/rminer.conf')
    @amqp_server = config['amqp_server'] or 'localhost'
    @amqp_channel = config['amqp_channel'] or 'rminer'
    @workers = config['workers'].to_i or 1
    @cache_size = config['cache'].to_i or 1000
    @logfile = $pwd + config['logfile'] or $pwd + '/logs/rminer.log'

    @host = config['db_host'] or 'localhost'
    @database = config['db_database'] or 'rminer'
    @user = config['db_user'] or 'rminer'
    @password = config['db_password'] or 'rminer'
    @adapter = config['db_adapter'] or 'postgres'
    @web_secret = config['web_secret'] or None
    @web_port = config['web_port'] or 9292
    @plugins_path = $pwd + config['plugins_path'] or $pwd + '/plugins/'
  end
end
