require 'bundler'
Bundler.require

get '/' do
  'OMG'
end

post '/' do
  if params[:payload]
    payload = JSON.parse(params[:payload])

    # Only trigger message when a new PR is opened
    if payload['action'] == 'opened'

      hipchat_msg = format_text_for_pr_message(payload['pull_request'])
      send_to_dev_underground(hipchat_msg)
    end
  end
end

def format_text_for_pr_message(pr)
  "PR ##{pr['number']}: <a href='#{pr['html_url']}' >#{pr['title']}</a> - #{pr['repository']['name']} (#{pr['user']['login']})"
end

def send_to_dev_underground(msg)
  client = HipChat::Client.new(ENV['HIPCHAT_API'])
  client['Engineering'].send('Github', msg)
end
