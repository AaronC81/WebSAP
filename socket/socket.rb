# This allows a client to "subscribe" to WebSAP state changes for a given app
# ID.
require 'socket'

# TODO: This is bad long term because $socket_clients becomes clogged with
# dead connections

# Format: [ [sessions, conn] ]
$socket_clients = []

def socket_state_update(session_id)
  puts "Checking for clients interested in #{session_id} (#{$socket_clients.length})"
  $socket_clients.each do |client|
    begin
      p client
      next unless client[0].include? session_id
      client[1].print('S')
      puts "A client has been informed of a state change"
    rescue e
      # Ignore, though we could remove this client I suppose
      puts "Failed to verify client: #{e}"
    end
  end
end

Thread.start do
  socket_server = TCPServer.open(10471)

  loop do
    # Connect clients
    Thread.start(socket_server.accept) do |conn|
      begin
        puts "A client has connected"
        # When a client connects, they must send a CSV of sessions they're 
        # interested in, followed by a line terminator. Like:
        #   a7812_,buas81\n
        sessions = conn.gets.strip.split(',')
        $socket_clients << [sessions, conn]
        puts "A client is interested in: #{sessions.join(',')}"
        
        # Write a confirmation which also prompts them to download first state
        conn.print('S')
      rescue e
        # If the client breaks something, just ignore them
        puts "A client socket encountered an exception: #{e}"
      end
    end
  end
end
