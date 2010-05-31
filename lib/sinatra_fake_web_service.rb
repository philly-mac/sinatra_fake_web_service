require 'sinatra/base'
require 'net/http'
require 'socket'

class SinatraFakeWebService

  attr_accessor :host, :port
  attr_accessor :current_thread
  attr_accessor :server

  def initialize(options = {})
    @server = Class.new(Sinatra::Base)
    @server.class_eval do
      enable :method_override
    end

    @host = options[:host] ||= 'localhost'
    @port = options[:port] ? options[:port].to_i : 4567
  end

  def running?
    self.current_thread.alive? rescue false
  end

  def run!
    find_free_port

    self.current_thread = Thread.new do
      @server.run! :post => @host, :port => @port
    end

    sleep 0.1 until alive?
  end

  def find_free_port
    @port += 1 while alive?
  end

  def alive?
    s = TCPSocket.new( @host, @port )
    s.close
    s
  rescue Errno::ECONNREFUSED
    false
  end

  def method_missing(method, *args, &block)
    @server.instance_eval do |base|
      route method.to_s.upcase, *args, &block
    end
  end

  class TestClient
    attr_accessor :host, :port

    def initialize( app )
      @host, @port = app.host, app.port
    end

    def get(action)
      res = Net::HTTP.start(self.host, self.port) do |http|
        http.get(action)
      end
    end

    def delete(action, data = "", headers = nil, dest = nil)
      data = data.empty? ? "_method=delete" : data += "&_method=delete"
      post(action, data, headers, dest)
    end

    def put(action, data = "", headers = nil, dest = nil)
      data = data.empty? ? "_method=put" : data += "&_method=put"
      post(action, data, headers, dest)
    end

    def post(action, data, headers = nil, dest = nil)
      res = Net::HTTP.start(self.host, self.port) do |http|
        http.post(action, data, headers, dest)
      end
    end
  end
end

