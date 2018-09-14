require 'http'
require 'json'

game_id = nil
key = nil

ENDPOINT = "http://localhost:4567"

loop do
  print "> "
  input = gets.chomp
  command = input.split[0]

  case command
  when 'new'
    app = input.split[1]
    data = JSON.parse(Http.get("#{ENDPOINT}/apps/#{app}/new").to_s)
    puts data['id']
    game_id = data['id']
  when 'key'
    key = input.split[1]
  when 'msg'
    action = input.split[1]
    other_args = input.split
    other_args.shift
    other_args.shift

    puts %x{ http --json POST #{ENDPOINT}/apps/#{game_id}/message action=#{action} key=#{key} #{other_args.join " "} }
  when 'state'
    puts Http.post("#{ENDPOINT}/apps/#{game_id}/state", json: { key: key })
  else
    puts "Unknown"
  end
end