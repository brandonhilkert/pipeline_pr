require 'bundler'
Bundler.require

get '/' do
  'OMG'
end

post '/' do
  # Only trigger message when a new PR is opened
  if payload['action'] == 'opened'
    hipchat_msg = format_text_for_pr_message(payload['pull_request'])
    send_to_dev_underground(hipchat_msg)
  end
end

def format_text_for_pr_message(pr)
  str = ""
  str << "New Pull Request:"
  str << "\n"
  str << pr['html_url']
end

def send_to_dev_underground(msg)
  client = HipChat::Client.new(ENV['HIPCHAT_API'])
  client['Dev Underground'].send('Mr. Hubot', msg)
end
