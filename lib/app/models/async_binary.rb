class AsyncBinary < ActiveRecord::Base

  def binary
    autoload_missing_constants do
      Marshal::load( Base64.decode64( read_attribute( :binary)))
    end
  end

  def binary=( object)
    write_attribute( :binary, Base64.encode64( Marshal::dump( object)))
  end


  def autoload_missing_constants
    yield
  rescue ArgumentError => e
    lazy_load ||= Hash.new { |hash, key| hash[key] = true; false }

    retry if e.to_s.include?('undefined class') && !lazy_load[e.to_s.split.last.constantize]
    raise e
  end  

end
