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
      msg = message_for_new_pr(payload['pull_request'])
      send_to_dev_underground(msg)
    elsif payload['action'] == 'closed' && payload['pull_request']['merged']
      msg = message_for_pr_merge(payload['pull_request'])
      send_to_operations_talk(msg)
    end
  end
end

def message_for_new_pr(pr)
  "PR: #{pr['head']['repo']['name']}/#{pr['number']} - <a href='#{pr['html_url']}' >#{pr['title']}</a> (#{pr['user']['login']})"
end

def message_for_pr_merge(pr)
  "<strong>MERGED</strong>: #{pr['head']['repo']['name']}/#{pr['number']} - <a href='#{pr['html_url']}' >#{pr['title']}</a> (#{pr['user']['login']})"
end

def send_to_dev_underground(msg)
  hipchat_client['Engineering'].send('Github', msg)
end

def send_to_operations_talk(msg)
  hipchat_client['Operations talk'].send('Github', msg, color: "green")
end

def hipchat_client
  HipChat::Client.new(ENV['HIPCHAT_API'])
end

