require 'bundler'
Bundler.require

get '/' do
  'Got it!'
  send_to_dev_underground 'Hey Players!'
end

post '/' do
  push = JSON.parse(params[:payload])
  "I got some JSON: #{push.inspect}"
end

def send_to_dev_underground(msg)
  client = HipChat::Client.new(ENV['HIPCHAT_API'])
  client['Dev Underground'].send('Mr. Hubot', msg)
end
