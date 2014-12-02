#!/usr/bin/env ruby

#     Copyright (C) 2010  Iñaki Baz Castillo <ibc@aliax.net>
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


require "socket"
require "timeout"
begin
  require "openssl"
rescue ::LoadError
  #puts "WARNING: Ruby OpenSSL non installed, cannot use SIP TLS transport"
end

module NagiosSipPlugin

  # Custom errors.
  class TransportError < StandardError ; end
  class ConnectTimeout < StandardError ; end
  class RequestTimeout < StandardError ; end
  class ResponseTimeout < StandardError ; end
  class NonExpectedStatusCode < StandardError ; end
  class WrongResponse < StandardError ; end


  class Utils

    def self.random_string(length=6, chars="abcdefghjkmnpqrstuvwxyz0123456789")
      string = ''
      length.downto(1) { |i| string << chars[rand(chars.length - 1)] }
      string
    end

    def self.generate_tag()
      random_string(8)
    end

    def self.generate_branch()
      'z9hG4bK' + random_string(8)
    end

    def self.generate_callid()
      random_string(10)
    end

    def self.generate_cseq()
      rand(999)
    end

  end  # class Utils


  class Request

    def initialize(options = {})
      @server_address = options[:server_address]
      @server_port = options[:server_port]
      @transport = options[:transport]
      @local_ip = options[:local_ip] || get_local_ip()
      @from_uri = options[:from_uri]
      @ruri = options[:ruri]
      @request = get_request()
      @expected_status_code = options[:expected_status_code]
      @timeout = options[:timeout]
      @ca_path = options[:ca_path]
      @verify_tls = options[:verify_tls]
    end

    def get_local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true
      UDPSocket.open do |s|
        begin
          s.connect @server_address, @server_port
        rescue SocketError => e
          raise TransportError, "Couldn't get the server address '#{@server_address}' (#{e.class}: #{e.message})"
        rescue => e
          raise TransportError, "Couldn't get local IP (#{e.class}: #{e.message})"
        end
        s.addr.last
      end
    end
    private :get_local_ip

    def connect
      begin
        case @transport
        when "udp"
          @io = UDPSocket.new
          Timeout::timeout(@timeout) {
            @io.bind(@local_ip, 0)
            @io.connect(@server_address, @server_port)
          }
        when "tcp"
          Timeout::timeout(@timeout) {
            @io = TCPSocket.new(@server_address, @server_port, @local_ip)
          }
        when "tls"
          Timeout::timeout(@timeout) {
            sock = TCPSocket.new(@server_address, @server_port, @local_ip)
            ssl_context = OpenSSL::SSL::SSLContext.new
            if @verify_tls
              ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
              ssl_context.ca_path =  @ca_path
            else
              ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            ssl_context.ssl_version = :TLSv1

            @io = OpenSSL::SSL::SSLSocket.new(sock, ssl_context)
            @io.sync_close = true
            @io.connect
          }
        end
      rescue Timeout::Error => e
        raise ConnectTimeout, "Timeout when connecting the server via #{@transport.upcase} (#{e.class}: #{e.message})"
      rescue => e
        raise TransportError, "Couldn't create the #{@transport.upcase} socket (#{e.class}: #{e.message})"
      end
    end
    private :connect

    def send
      if ! connect
        return false
      end
      begin
        Timeout::timeout(@timeout) {
          if @transport == "tls"
            @io.syswrite(@request)
          else
            @io.send(@request,0)
          end
        }
      rescue Timeout::Error => e
        raise RequestTimeout, "Timeout sending the request via #{@transport.upcase} (#{e.class}: #{e.message}"
      rescue => e
        raise TransportError, "Couldn't send the request via #{@transport.upcase} (#{e.class}: #{e.message}"
      end
    end

  end  # class Request


  class OptionsRequest < Request

    attr_reader :request

    def get_request
      headers = <<-END_HEADERS
        OPTIONS #{@ruri} SIP/2.0
        Via: SIP/2.0/#{@transport.upcase} #{@local_ip};rport;branch=#{Utils.generate_branch}
        Max-Forwards: 5
        To: <#{@ruri}>
        From: <#{@from_uri}>;tag=#{Utils.generate_tag}
        Call-ID: #{Utils.generate_callid}@#{@local_ip}
        CSeq: #{Utils.generate_cseq} OPTIONS
        Content-Length: 0
      END_HEADERS
      headers.gsub!(/^[\s\t]*/,"")
      headers.gsub!(/\n/,"\r\n")
      return headers + "\r\n"
    end
    private :get_request

    def receive
      response_first_line = ""
      begin
        Timeout::timeout(@timeout) {
          response_first_line = @io.readline("\r\n")
        }
      rescue Timeout::Error => e
        raise ResponseTimeout, "Timeout receiving the response via #{@transport.upcase} (#{e.class}: #{e.message})"
      rescue => e
        raise TransportError, "Couldn't receive the response via #{@transport.upcase} (#{e.class}: #{e.message})"
      end
      if response_first_line !~ /^SIP\/2\.0 \d{3} [^\n]*/i
        raise WrongResponse, "Wrong response first line received: \"#{response_first_line.gsub(/[\n\r]/,'')}\""
      end

      status_code = response_first_line.split(" ")[1]
      if @expected_status_code && @expected_status_code != status_code
        raise NonExpectedStatusCode, "Received a #{status_code} but #{@expected_status_code} was required"
      end
      return status_code

    end  # def receive

  end  # class OptionsRequest

end  # module NagiosSipPlugin


def show_help
  puts <<-END_HELP

Usage mode:    nagios-sip-plugin.rb [OPTIONS]

  OPTIONS:
    -t (tls|tcp|udp) :    Protocol to use (default 'udp').
    -s SERVER_IP     :    IP or domain of the server (required).
    -p SERVER_PORT   :    Port of the server (default '5060').
    -r REQUEST_URI   :    Request URI (default 'sip:ping@SERVER_IP:SERVER_PORT').
    -f FROM_URI      :    From URI (default 'sip:nagios@SERVER_IP').
    -c SIP_CODE      :    Expected status code (i.e: '200'). If null then any code is valid.
    -T SECONDS       :    Timeout in seconds (default '2').
    -vt              :    Verify server's TLS certificate when using SIP TLS (default false).
    -ca CA_PATH      :    Directory with public PEM files for validating server's TLS certificate (default '/etc/ssl/certs/').

  Homepage:
    https://github.com/ibc/nagios-sip-plugin

END_HELP
end

def suggest_help
  puts "\nGet help by running:    ruby nagios-sip-plugin.rb -h\n"
end

def time_diff_milli(start, finish)
   ((finish - start) * 1000.0).to_i
end

def log_ok(text)
  $stdout.puts "OK:#{text}"
  exit 0
end

def log_warning(text)
  $stdout.puts "WARNING:#{text}"
  exit 1
end

def log_critical(text)
  $stdout.puts "CRITICAL:#{text}"
  exit 2
end

def log_unknown(text)
  $stdout.puts "UNKNOWN:#{text}"
  exit 3
end



### Run the script.

include NagiosSipPlugin

# Asking for help?
if (ARGV[0] == "-h" || ARGV[0] == "--help")
  show_help
  exit
end

args = ARGV.join(" ")

start_time = Time.now
transport = args[/-t ([^\s]*)/,1] || "udp"
server_address = args[/-s ([^\s]*)/,1] || nil
server_port = args[/-p ([^\s]*)/,1] || 5060
server_port = server_port.to_i
ruri = args[/-r ([^\s]*)/,1] || "sip:ping@" + server_address + (server_port ? ":" + server_port.to_s : "")
from_uri = args[/-f ([^\s]*)/,1] ||"sip:nagios@" + server_address
expected_status_code = args[/-c ([^\s]*)/,1] || nil
timeout = args[/-T ([^\s]*)/,1] || 2
timeout = timeout.to_i
verify_tls = args =~ /-vt/ ? true : false
ca_path = args[/-ca ([^\s]*)/,1] || "/etc/ssl/certs/"

# Check parameters.
log_unknown "transport protocol (-t) must be 'tls', 'udp', or 'tcp'"  unless transport =~ /^(tls|udp|tcp)$/
log_unknown "'tls' transport not supported (Ruby OpenSSL not installed)"  if (transport == "tls" and not defined? ::OpenSSL)
log_unknown "server address (-s) is required"  unless server_address
log_unknown "expected status code (-c) must be [123456]XX"  unless expected_status_code =~ /^[123456][0-9]{2}$/ or not expected_status_code
log_unknown "timeout (-T) must be greater than 0"  unless timeout > 0


begin
  options = OptionsRequest.new({
    :server_address => server_address,
    :server_port => server_port,
    :transport => transport,
    :ruri => ruri,
    :from_uri => from_uri,
    :expected_status_code => expected_status_code,
    :timeout => timeout,
    :verify_tls => verify_tls,
    :ca_path => ca_path
  })
  options.send
  status_code = options.receive
  duration = time_diff_milli start_time, Time.now
  log_ok "status code = #{status_code}|rta=#{duration}ms"
rescue NonExpectedStatusCode => e
  duration = time_diff_milli start_time, Time.now
  log_warning "#{e.message}|rta=#{duration}ms"
rescue TransportError, ConnectTimeout, RequestTimeout, ResponseTimeout, WrongResponse => e
  duration = time_diff_milli start_time, Time.now
  log_critical "#{e.message}|rta=#{duration}ms"
end

