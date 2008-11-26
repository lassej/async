require 'test/unit'
require File.dirname(__FILE__) + '/test_helper.rb'

class AsyncTest < Test::Unit::TestCase

  def test_async_method
    t = SomeClass.new
    assert( task = t.async( :some_method))
    assert( task.id)
  end

  def test_async_class_method
    assert( task = SomeClass.async( :some_method))
    assert( task.id)
  end

  def test_schedule_method
    time = Time.local( 2008, 12, 1, 13, 45)

    assert( task = SomeClass.schedule( time, :some_method))
    assert task.id
    assert_equal time, task.scheduled_at
  end

end
