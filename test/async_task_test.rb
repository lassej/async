require File.dirname(__FILE__) + '/test_helper.rb'

class AsyncTaskTest < Test::Unit::TestCase
  load_schema

  def test_started?
    task = AsyncTask.new
    assert_equal false, task.started?

    task.started_at = Time.now
    assert_equal true, task.started?
  end

  def test_finished?
    task = AsyncTask.new
    assert_equal false, task.finished?

    task.finished_at = Time.now
    assert_equal true, task.finished?
  end

  def test_unfinished_task_is_generated
    task = SomeClass.async( :some_method)
    
    assert( unfinished_task = UnfinishedTask.find_by_async_task_id( task.id))
    assert_equal task, unfinished_task.async_task
  end

  def test_execute!
    t = SomeClass.new
    t.expects( :some_method).once.returns( { :test => "test result" })

    task = t.async( :some_method)
    result = task.execute!

    task.reload

    assert task.finished?
    assert_equal( { :test => "test result" }, result)
    assert_equal( { :test => "test result" }, task.result)
  end

  def test_execute_of_class_method
    SomeClass.expects( :some_method).once.returns( "test result")

    task = SomeClass.async( :some_method)
    result = task.execute!

    assert task.finished?
    assert_equal "test result", result
    assert_equal "test result", task.result
  end

  def test_results_are_stored
    SomeClass.expects( :some_method).once.returns( "test result")

    task = SomeClass.async( :some_method)
    AsyncTask.find( task.id).execute!
    task = AsyncTask.find( task.id)

    assert_equal "test result", task.result
  end

  def test_arguments_are_stored
    task = SomeClass.async( :some_method, :args => [1, 2, 3])
    task = AsyncTask.find( task.id)

    assert_equal [1, 2, 3], task.args

    task.destroy
  end

  def test_dependencies_are_destroyed
    SomeClass.expects( :some_method).with( 1).once.returns( "test result")
    task = SomeClass.async( :some_method, :args => [ 1 ])
    task.execute!
    task.reload

    assert( args_binary = task.args_binary)
    assert( result_binary = task.result_binary)

    task.destroy

    args_binary.reload
    assert_nil args_binary.id

    result_binary.reload
    assert_nil result_binary.id
  end

  def test_unfinished_task_is_destroyed_on_task_destroy
    task = SomeClass.async( :some_method)
    task = AsyncTask.find( task.id)

    assert( unfinished_task = task.unfinished_task)
    task.destroy

    unfinished_task.reload
    assert_nil unfinished_task.id
  end

  def test_execute_with_arguments
    t = SomeClass.new
    task = t.async( :some_method, :args => "test")

    t.expects( :some_method).once.with( "test")

    task.execute!
  end

  def test_execute_with_arguments_and_pass_task
    t = SomeClass.new
    task = t.async( :some_method, :args => "test", :pass_task => true)

    t.expects( :some_method).once.with( task, "test")

    task.execute!
  end

  def test_unfinished_task_is_destroyed_after_execute
    SomeClass.stubs( :some_method)
    task = SomeClass.async( :some_method)

    task.reload
    assert_not_nil task.unfinished_task

    task.execute!
    task.reload

    assert_nil task.unfinished_task
  end

  def test_errors_are_catched
    SomeClass.stubs( :some_method).raises( "some error")

    task = SomeClass.async( :some_method)
    task.execute!
    task.reload

    assert_equal false, task.success
    assert task.finished?
    assert_equal RuntimeError, task.result.class
    assert_equal "some error", task.result.message
    assert_not_nil task.result.backtrace
  end

  def test_next!
    AsyncTask.destroy_all
    t = SomeClass.new
    
    task1 = t.async( :some_method)
    task2 = t.async( :some_method)

    assert_equal task1, AsyncTask.next!
    assert_equal task2, AsyncTask.next!
    assert_equal nil,  AsyncTask.next!
  end

  def test_sorting_of_next!
    eight_minutes_ago = 8.minutes.ago

    task1 = SomeClass.async( :some_method) # default priority 20
    task2 = SomeClass.async( :some_method, :priority => 28)
    task3 = SomeClass.async( :some_method, :priority => 25)
    task4 = SomeClass.async( :some_method, :priority => 25, :scheduled_at => 5.minutes.ago)
    task5 = SomeClass.async( :some_method, :priority => 25, :scheduled_at => eight_minutes_ago)
    task6 = SomeClass.async( :some_method, :priority => 25, :scheduled_at => eight_minutes_ago)
    task7 = SomeClass.async( :some_method, :scheduled_at => eight_minutes_ago) # default priority 20
    task8 = SomeClass.schedule( eight_minutes_ago, :some_method) # default priority 10

    assert_equal task2, AsyncTask.next!
    assert_equal task5, AsyncTask.next!
    assert_equal task6, AsyncTask.next!
    assert_equal task4, AsyncTask.next!
    assert_equal task3, AsyncTask.next!
    assert_equal task8, AsyncTask.next!
    assert_equal task7, AsyncTask.next!
    assert_equal task1, AsyncTask.next!
  end

  def test_next_does_not_return_tasks_scheduled_in_future
    task = SomeClass.schedule( 2.days.from_now, :some_method)

    assert_nil AsyncTask.next!
  end

  def test_execute_next!
    AsyncTask.destroy_all
    t = SomeClass.new
    
    task = t.async( :some_method)
    SomeClass.any_instance.expects( :some_method).once.returns( "test result")

    task = AsyncTask.execute_next!

    assert task.finished?
    assert_equal "test result", task.result
  end

  def test_execute_returns_task_with_correct_target
    t = SomeClass.new
    task = t.async( :some_method)
    SomeClass.any_instance.expects( :some_method).once.returns( "test result")

    task = AsyncTask.next!

    assert_equal t, task.object
    task.execute!
    assert_equal t, task.object
  end

  def test_execute_next_with_no_remaining_tasks
    AsyncTask.destroy_all

    assert_nil AsyncTask.execute_next!
  end

end

