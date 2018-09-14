require 'http'
require 'json'

game_id = nil

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
  when 'msg'
    action = input.split[1]
    other_args = input.split
    other_args.shift
    other_args.shift

    %x{ http --json POST #{ENDPOINT}/apps/#{game_id}/message action=#{action} #{other_args.join} }
  when 'state'
    puts JSON.parse(Http.get("#{ENDPOINT}/apps/#{game_id}/state").to_s)
  else
    puts "Unknown"
  end
end