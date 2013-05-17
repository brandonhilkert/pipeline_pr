require 'bundler'
require 'logger'
Bundler.require

$logger = Logger.new('app.log')

get '/' do
  $logger.info "What the hell is wrong with this logger"
  $stdout << "Hit the index page\n"
  'OMG'
end

post '/' do
  $logger.info params[:payload]
  payload = JSON.parse(params[:payload])
  $stdout << "Received #{payload} from Github\n"
  # url = payload['head_commit']['url']
  # msg = payload['head_commit']['message']
  # user = payload['head_commit']['author']['username']
  # hipchat_msg = format_text_for_pr_message(url, user, msg)
  # send_to_dev_underground(payload.inspect)
end

def format_text_for_pr_message(url, user, msg)
  str = ""
  str << "New Pull Request from #{user}"
  str << "\n"
  str << msg
  str << "\n"
  str << url
end

def send_to_dev_underground(msg)
  client = HipChat::Client.new(ENV['HIPCHAT_API'])
  client['Dev Underground'].send('Mr. Hubot', msg)
end
