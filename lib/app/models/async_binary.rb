class AsyncBinary < ActiveRecord::Base

  def binary
    Marshal::load( read_attribute( :binary))
  end

  def binary=( object)
    write_attribute( :binary, Marshal::dump( object))
  end
end
