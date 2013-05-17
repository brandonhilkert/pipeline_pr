require 'bundler'
require 'logger'
Bundler.require

$logger = Logger.new('app.log')

get '/' do
  'Got it!'
  send_to_dev_underground 'Hey Players!'
end

post '/' do
  $logger.info params[:payload].inspect
  # puts params[:payload]
  # push = JSON.parse(params[:payload])
  # "I got some JSON: #{push.inspect}"
end

def send_to_dev_underground(msg)
  client = HipChat::Client.new(ENV['HIPCHAT_API'])
  client['Dev Underground'].send('Mr. Hubot', msg)
end
