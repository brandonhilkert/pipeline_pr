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
      collaborator = pick_random_collaborator(payload['pull_request'])
      hipchat_msg = format_text_for_pr_message(payload['pull_request'], collaborator)
      send_to_dev_underground(hipchat_msg)
      add_comment_with_collaborator(payload['pull_request'], collaborator)
      update_pr_assignee(payload['pull_request'], collaborator)
      resolve_fogbugz_ticket(payload['pull_request']['title'])
    end
  end
end

def format_text_for_pr_message(pr, collaborator)
  "New PR ##{pr['number']}: <a href='#{pr['html_url']}' >#{pr['title']}</a> - @#{pr['user']['login']} w/ collaborator @#{collaborator}"
end

def send_to_dev_underground(msg)
  client = HipChat::Client.new(ENV['HIPCHAT_API'])
  client['Dev Underground'].send('Github', msg)
end

def pick_random_collaborator(pr)
  potential_collaborators = PIPELINE_COLLABORATORS - Array(pr["user"]["login"])
  potential_collaborators.sample
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

def resolve_fogbugz_ticket(title)
  fb_ticket_number = extract_fogbugz_ticket_number(title)
  if fb_ticket_number
    fogbugz = Fogbugz::Interface.new(token: ENV['FOGBUGZ_TOKEN'], uri: ENV['FOGBUGZ_HOST'])
    fogbugz.command(:resolve, :ixBug => fb_ticket_number)
  end
end

def extract_fogbugz_ticket_number(string)
  string.scan(/\#(\d+)/).first.first
rescue
  nil
end
