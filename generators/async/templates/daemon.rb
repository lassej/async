#!/usr/bin/env ruby

require File.join( File.dirname(__FILE__), "..", "..", "config", "environment")

running = true
Signal.trap( "TERM") do 
  running = false
end

while running do
  sleep 5 unless task = AsyncTask.execute_next!
end

