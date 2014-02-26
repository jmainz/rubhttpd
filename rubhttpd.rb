#!/usr/bin/ruby
=begin

	rhttpd/0.1.0 25 February 2014

	LICENSE:

	Copyright (c) 2014, John Mainz
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

		Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
		Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


	This webserver is designed as a small project to better help me understand HTTP as well as writing servers in general and should not be used in a production environment!
	~John Mainz (john.mainz@live.com)
=end

require "socket"
require "inifile"
require "logger"

#Need to rewrite this so that we don't have problems with files later on
def get_content_type(path)
	ext = File.extname(path)

	mime = {".html"=>"text/html", ".htm"=>"text/html", ".shtml"=>"text/html", ".shtm"=>"text/html", ".txt"=>"text/plain", ".css"=>"text/css", ".json"=>"text/json", ".xml"=>"text/xml", ".xsl"=>"text/xml", ".xslt"=>"text/xml", ".js"=>"application/x-javascript", ".torrent"=>"application/x-bittorrent", ".ogg"=>"application/ogg", ".pdf"=>"application/pdf", ".swf"=>"application/x-shockwave-flash", ".jpg"=>"image/jpeg", ".jpeg"=>"image/jpeg", "image"=>"image/x-icon", ".gif"=>"image/gif", ".png"=>"image/png", ".bmp"=>"image/bmp", ".svg"=>"image/svg+xml", ".mpg"=>"video/mpeg", ".mpeg"=>"video/mpeg", ".webm"=>"video/webm", ".mov"=>"video/quicktime", ".mp4"=>"video/mp4", ".m4v"=>"video/x-m4v", ".avi"=>"video/x-msvideo" }

	if mime.has_key?(ext)
		return mime[ext]
	else
		return "application/octet-stream"
	end
end



#main block 
server = TCPServer.new(80) #http port
version = "rubhttpd/0.1.0"
date_updated = "25 February 2014"
base_path = "/opt/rubhttpd/sites/pubweb/"
Dir.chdir("/opt/rubhttpd/")
connlog = Logger.new("connections.log", "monthly")
reqlog = Logger.new("requests.log", "monthly")
Dir.chdir(base_path)

loop do
	Thread.start server.accept do |client|

		sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
		request = client.gets
		date = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")

		connlog.info("Client connected from: #{remote_ip}")
		reqlog.info("#{request}")
		puts request

		case request
		when /^GET\ \//
			resource = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '').chomp
			other = request.gsub(/GET\ /, '').gsub(/\ HTTP.*/, '').chomp

			while tmp = client.gets

				puts tmp
				
				if tmp == "\r\n"
					break
				else
					request << tmp
				end
			end

			
			if resource == ""
				resource = "./"
			else
				resource = "./#{resource}"
			end

			if !File.exist? resource
				client.puts "HTTP/1.1 404/File Not Found\r\nDate: #{date}\r\nConnection: close\r\n\r\n"
				client.puts "<html><head><title>404 - File Not Found</title></head><body>"
				client.puts "<center><h1>404 - File Not Found</h1></center>"
				client.puts "<hr><center>#{version} - #{date_updated}</center></body><html>"
			elsif File.directory? resource

				if File.exist? (resource << "index.html")
					ct = get_content_type(resource)
					client.puts "HTTP/1.1 200/OK\r\nServer: #{version}\r\nDate: #{date}\r\nContent-Type: #{ct}\r\n\r\n"
				
					File.open(resource, "rb") do |f|  #b flag just required on windows machines, but used here for safety's sake
				
						while !f.eof?
							buf = f.read(1024)
							client.write(buf)
						end
					end
				else
					base_dir = Dir.new(resource)
					client.puts "HTTP/1.1 200/OK\r\nDate: #{date}\r\nServer: #{version}\r\nConnection: close\r\nContent-Type:text/html\r\n\r\n"
					client.puts "<html><head><title>Index of #{other}</title></head><body><h1>Index of #{other}</h1><hr><pre>"
					
					base_dir.entries.each do |e|
						
						if File.directory? e 
							client.puts "<a href = \"#{e}/\">#{e}/</a>"
						else
							client.puts "<a href = \"#{e}\">#{e}</a>"
						end
					end
					client.puts "</pre><hr></body></html>"
				end
			else
				ct = get_content_type(resource)
				client.puts "HTTP/1.1 200/OK\r\nServer: #{version}\r\nDate: #{date}\r\nContent-Type: #{ct}\r\n\r\n"
				
				File.open(resource, "rb") do |f|  #b flag just required for windoze machines
				
					while !f.eof?
						buf = f.read(1024)
						client.write(buf)
					end
				end
			end
		when /^POST\ \//
			client.puts "HTTP/1.1 501/Not Implemented\r\nServer: #{version}\r\nDate: #{date}\r\nContent-Type: #{ct}\r\n\r\n"
		when /^HEAD\ \//
			client.puts "HTTP/1.1 200/OK\r\nServer: #{version}r\nDate: #{date}\r\nContent-Type: #{ct}\r\n\r\n"
		else
			client.puts "HTTP/1.1 400/WTF\r\nServer: #{version}\r\nDate: #{date}\r\nContent-Type: #{ct}\r\n\r\n"
		end
	
		client.close
	end
end

puts "EOF"