require 'bundler'
Bundler.require
require 'fogbugz'

PIPELINE_COLLABORATORS = ['brandonhilkert', 'gammons', 'chadoh', 'TheOddLinguist']

get '/' do
  'OMG'
end

post '/' do
  if params[:payload]
    payload = JSON.parse(params[:payload])

    # Only trigger message when a new PR is opened
    if payload['action'] == 'opened'

      # May return nil if it's not being merged into develop (project pr)
      collaborator = pick_random_collaborator(payload['pull_request'])

      hipchat_msg = format_text_for_pr_message(payload['pull_request'], collaborator)
      send_to_dev_underground(hipchat_msg)

      if collaborator
        add_comment_with_collaborator(payload['pull_request'], collaborator)
        update_pr_assignee(payload['pull_request'], collaborator)
      end

      resolve_fogbugz_ticket(payload['pull_request'])
    end
  end
end

def assign_collaborator?(pr)
  pr["base"]["ref"] == "develop"
end

def format_text_for_pr_message(pr, collaborator)
  message = "New PR ##{pr['number']}: <a href='#{pr['html_url']}' >#{pr['title']}</a> - @#{pr['user']['login']}"
  message += " w/ collaborator @#{collaborator}" if collaborator
  message
end

def send_to_dev_underground(msg)
  client = HipChat::Client.new(ENV['HIPCHAT_API'])
  client['Dev Underground'].send('Github', msg)
end

def pick_random_collaborator(pr)
  if assign_collaborator?(pr)
    potential_collaborators = PIPELINE_COLLABORATORS - Array(pr["user"]["login"])
    potential_collaborators.sample
  else
    nil
  end
end

def add_comment_with_collaborator(pr, collaborator)
  RestClient.post(
    "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{pr["number"]}/comments?access_token=#{ENV['GITHUB_ACCESS_TOKEN']}",
    { "body" => "Collaborator: @#{collaborator }" }.to_json,
    content_type: :json,
    accept: :json)
end

def update_pr_assignee(pr, collaborator)
  RestClient.post(
    "https://api.github.com/repos/PipelineDeals/pipeline_deals/issues/#{pr["number"]}?access_token=#{ENV['GITHUB_ACCESS_TOKEN']}",
    { "assignee" => collaborator }.to_json,
    content_type: :json,
    accept: :json)
end

def resolve_fogbugz_ticket(pr)
  fb_ticket_number = extract_fogbugz_ticket_number(pr['title'])
  if fb_ticket_number
    fogbugz = Fogbugz::Interface.new(token: ENV['FOGBUGZ_TOKEN'], uri: ENV['FOGBUGZ_HOST'])
    fogbugz.command(:resolve, ixBug: fb_ticket_number, sEvent: pr['html_url'])
  end
end

def extract_fogbugz_ticket_number(string)
  string.scan(/\#(\d+)/).first.first
rescue
  nil
end
