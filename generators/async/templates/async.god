
require "optparse"

RAILS_ROOT = File.join( File.dirname( __FILE__), "..")

def parse_number
  number = 1
  OptionParser.new do |opts|
    opts.on( "-n N", Integer) do |n|
      number = n
    end
  end.parse( ARGV)
  return number
end

def command_for( action, uid)
  File.join( RAILS_ROOT, "script", "async") + " #{action} --uid=#{uid}"
end

def pid_file( uid)
  File.join(RAILS_ROOT, "log", "async", "async#{uid}.pid")
end

parse_number.times do |uid|
  God.watch do |w|
    w.name          = "async#{uid}"
    w.interval      = 30.seconds # default      
    w.start         = command_for( "start", uid)
    w.stop          = command_for( "stop", uid)
    w.restart       = command_for( "restart", uid)
    w.group         = "async"
    w.start_grace   = 10.seconds
    w.restart_grace = 10.seconds
    w.pid_file      = pid_file( uid)
    
    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 180.megabytes
        c.times = [12, 12]
      end
    end
  end
end
