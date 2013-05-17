require 'bundler'
Bundler.require

get '/' do
  'OMG'
end

def redis
  @redis ||= (
    url = URI(ENV['REDISTOGO_URL'] || "redis://127.0.0.1:6379")

    base_settings = {
      host: url.host,
      port: url.port,
      db: url.path[1..-1],
      password: url.password
    }

    Redis::Namespace.new("pr:#{env}", redis: Redis.new(base_settings))
  )
end

post '/' do
  if params[:payload]
    payload = JSON.parse(params[:payload])
    redis.set 'github', params[:payload]
  end

  # Only trigger message when a new PR is opened
  # if payload['action'] == 'opened'
  #   hipchat_msg = format_text_for_pr_message(payload['pull_request'])
  #   send_to_dev_underground(hipchat_msg)
  # end
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
