class AsyncGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.migration_template 'migration.rb', File.join( 'db', 'migrate'), :migration_file_name => 'create_async_tasks'

      m.directory File.join( 'lib', 'async')
      m.file 'daemon.rb', File.join( 'lib', 'async', 'daemon.rb')
      m.file 'async',     File.join( 'script', 'async'), :chmod => 0755
      m.file 'async.god', File.join( 'config', 'async.god')

      m.directory File.join( 'log', 'async')
    end
  end

end
