#!/usr/bin/env ruby
require 'steam-condenser'
require 'childprocess'

class ServerWatchdog
  def initialize(dir,cmd,ip,port,rcon_pw)
    @ip = ip
    @port = port
    @rcon_pw = rcon_pw
    @process = ChildProcess.build(*cmd.split)
    @process.cwd = dir
    @process.environment["LD_LIBRARY_PATH"] = ".:bin:#{ENV['LD_LIBRARY_PATH']}"
  end

  def spawn()
    @process.io.inherit!
    @process.duplex
    @process.start
    @process.wait
  end

  def healthy?()
    server = SourceServer.new(@ip,@port)

    begin
      server.rcon_auth(@rcon_pw)
      puts "===== Watchdog tick; #{Time.now} ====="
      server.rcon_exec('status')
      return true
    rescue
      puts "!!!!! Stopped Responding, ending !!!!!"
      return false
    end
  end

  def die()
    @process.stop
    Kernel.exit
  end
end

startup_dir = "/home/jon/objective/nmrih_ds"
startup_cmd = './srcds_linux -game ./nmrih "$@" -console +map nmo_quarantine +ip 66.254.110.111 +rcon_password nope'
srv = ServerWatchdog.new(startup_dir, startup_cmd, '66.254.110.111', '27015', 'nope')

Thread.new do
  srv.spawn
end

loop do
  sleep 60
  srv.die if not srv.healthy?
end
