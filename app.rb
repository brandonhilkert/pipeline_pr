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
      send_to_dev_underground_in_hipchat(payload['pull_request'])
      send_to_engineering_in_slack(payload['pull_request'])
    elsif payload['action'] == 'closed' && payload['pull_request']['merged']
      send_to_operations_talk_in_hipchat(payload['pull_request'])
      send_to_operations_in_slack(payload['pull_request'])
    end
  end
end

def send_to_dev_underground_in_hipchat(pr)
  msg = "#{pr['head']['repo']['name']}/#{pr['number']} - <a href='#{pr['html_url']}' >#{pr['title']}</a> (#{pr['user']['login']})"
  hipchat_client['Engineering'].send('Github', msg)
end

def send_to_operations_talk_in_hipchat(pr)
  msg = "<strong>MERGED</strong>: #{pr['head']['repo']['name']}/#{pr['number']} - <a href='#{pr['html_url']}' >#{pr['title']}</a> (#{pr['user']['login']})"
  hipchat_client['Operations talk'].send('Github', msg)
end

def send_to_engineering_in_slack(pr)
  text = "*#{pr['head']['repo']['name']}/#{pr['number']}* - <#{pr['html_url']}|#{pr['title']}> (#{pr['user']['login']})"
  attachment = {
    text: text,
    color: "warning",
    mrkdwn_in: ["text"],
  }
  RestClient.post ENV["SLACK_WEBHOOK_URL"], { attachments: [attachment] }.to_json, content_type: :json, accept: :json
end

def send_to_operations_in_slack(pr)
  text = "*MERGED*: #{pr['head']['repo']['name']}/#{pr['number']} - <#{pr['html_url']}|#{pr['title']}> (#{pr['user']['login']})"
  attachment = {
    text: text,
    color: "warning",
    mrkdwn_in: ["text"],
  }
  RestClient.post ENV["SLACK_WEBHOOK_URL"], { attachments: [attachment], channel: "#operations" }.to_json, content_type: :json, accept: :json
end

def slack_attachment(text)

end

def hipchat_client
  HipChat::Client.new(ENV['HIPCHAT_API'])
end
