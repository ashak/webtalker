require "socket"
require "json"
require "net/http"
require "uri"
require "websocket-client-simple"
require 'pry-byebug'

TELNET_PORT = 2323
AUTH_URL    = URI("http://localhost:3002/telnet_session")
WS_URL      = "ws://localhost:3002/cable"

server = TCPServer.new(TELNET_PORT)
puts "Telnet proxy listening on #{TELNET_PORT}"

loop do
  socket = server.accept

  Thread.new(socket) do |client|
    begin
      client.write("Email address: ")
      username = client.gets&.strip

      if username&.empty?
        client.close
        next
      end

      client.write("Password: ")
      password = client.gets&.strip
      unless password
        client.close
        next
      end

      # --- Authenticate via Rails ---
      http = Net::HTTP.new(AUTH_URL.host, AUTH_URL.port)
      req  = Net::HTTP::Post.new(AUTH_URL, {
        "Content-Type" => "application/json"
      })
      req.body = { email_address: username, password: password }.to_json

      res = http.request(req)
      unless res.is_a?(Net::HTTPSuccess)
        client.write("Auth failed\r\n")
        client.close
        next
      end

      puts "body #{res.body}"
      parsed_body = JSON.parse(res.body)
      puts "parsed_body #{parsed_body}"
      token = parsed_body["access_token"]
      puts "token #{token}"
      refresh_token = parsed_body["refresh_token"]

      # --- WebSocket connection ---
      ws = WebSocket::Client::Simple.connect(
        WS_URL,
        headers: {
          "X-Telnet-Token" => token,
          "Origin" => "telnet_ws_proxy"
        }
      )

      ws.on(:open) do
        # client.write("Connected.\r\n")
        subscribe_message = {
          command: "subscribe",
          identifier: {
            channel: "TelnetChannel"
          }.to_json
        }

        ws.send(subscribe_message.to_json)
      end

      ws.on(:message) do |msg|
        data = JSON.parse(msg.data) rescue nil
        puts "data: #{data}"
        puts "data class: #{data.class}"
        puts "kind_of? Hash: #{data&.kind_of?(Hash)}"
        puts "dig: #{data&.dig('identifier') != '{"channel":TelnetChannel"}'}" if data&.kind_of?(Hash)
        next if !data&.kind_of?(Hash) || data&.dig('identifier') != '{"channel":"TelnetChannel"}'
        client.write(data['message'])
        #data: {"type" => "disconnect", "reason" => "server_restart", "reconnect" => true}
      end

      ws.on(:close) do
        client.close
      end

      ws.on(:error) do |_|
        client.close
      end

      # --- Telnet input loop ---
      while (line = client.gets)
        line.strip!
        payload = {
          command: "message",
          identifier: {
            channel: "TelnetChannel"
          }.to_json,
          data: {
            message: line
          }.to_json
        }

        ws.send(payload.to_json)
      end

    rescue => e
      warn e.message
    ensure
      ws&.close
      client&.close
    end
  end
end
