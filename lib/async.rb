

path = File.join(File.dirname(__FILE__), 'app', 'models')
$LOAD_PATH << path
ActiveSupport::Dependencies.load_paths << path
ActiveSupport::Dependencies.load_once_paths.delete( path)

module Async

  def async( action, options = {})
    AsyncTask.async( self, action, options)
  end

  def schedule( time, action, options = {})
    AsyncTask.schedule( time, self, action, options)
  end

end

ActiveRecord::Base.send( :include, Async)
Class.send( :include, Async)
Module.send( :include, Async)

