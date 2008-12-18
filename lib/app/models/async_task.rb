class AsyncTask < ActiveRecord::Base

  belongs_to :parent,        :class_name => 'AsyncTask',   :foreign_key => :parent_id
  belongs_to :args_binary,   :class_name => 'AsyncBinary', :foreign_key => :args_binary_id,   :dependent => :destroy
  belongs_to :result_binary, :class_name => 'AsyncBinary', :foreign_key => :result_binary_id, :dependent => :destroy

  has_many   :children,      :class_name => 'AsyncTask',   :foreign_key => :parent_id
  has_one    :unfinished_task, :dependent => :destroy

  before_save :save_object
  validate    :validate_object

  cattr_accessor :default_priority
  cattr_accessor :default_schedule_priority

  self.default_priority          = 10
  self.default_schedule_priority = 20


  def self.async( object, action, options = {})
    options = options.reverse_merge({
      :scheduled_at => Time.now.utc,
      :pass_task    => false,
      :priority     => self.default_priority
    })

    task = AsyncTask.new({
      :object       => object,
      :args         => options[:args].to_a,
      :action       => action.to_s,
      :pass_task    => options[:pass_task],
      :scheduled_at => options[:scheduled_at].utc,
      :parent       => options[:parent],
      :priority     => options[:priority]
    })

    task.unfinished_task = UnfinishedTask.new({
      :async_task   => task,
      :priority     => task.priority,
      :scheduled_at => task.scheduled_at,
      :started      => false
    })

    task.save!

    return task
  end

  def self.schedule( time, object, action, options = {})
    options = options.reverse_merge( :priority => self.default_schedule_priority)
    options[:scheduled_at] = time
    async( object, action, options)
  end

  def self.next!
    task     = nil
    continue = true

    while continue
      transaction do
        unfinished_task = UnfinishedTask.find( :first, {
          :order      => "priority desc, scheduled_at asc, id asc",
          :conditions => [ "started = ? AND scheduled_at <= ?", false, Time.now.utc ]
        })

        if unfinished_task
          locked_task = UnfinishedTask.find_by_id( unfinished_task.id, :lock => true)

          if locked_task && !locked_task.started?
            locked_task.update_attributes( :started => true)

            task = locked_task.async_task
            task.update_attributes( :started_at => Time.now.utc)
            continue = false
          end
        elsif !unfinished_task
          continue = false
        end
      end
    end

    return task
  end

  def self.execute_next!
    if task = self.next!
      task.execute!
      return task
    end
  end

  def execute!
    begin
      result  = object.send( action, *call_arguments)
      success = true
    rescue => e
      result  = e
      success = false
    end

    transaction do
      update_attributes({
        :finished_at => Time.now.utc,
        :result      => result,
        :success     => success
      })
      unfinished_task.destroy
    end

    return self.result
  end

  def cancel!
    transaction do
      self.update_attributes( :cancelled => true, :finished_at => Time.now.utc)
      if u = self.unfinished_task
        u.destroy
      end
    end
  end

  def started?
    started_at ? true : false
  end

  def finished?
    finished_at ? true : false
  end

  def object
    @object ||= object_from_db
  end

  def object=( object)
    @object = object
  end

  def args
    args_binary ? args_binary.binary : []
  end

  def args=( args)
    if ! args.blank?
      if args_binary
        args_binary.update_attribute :binary, args
      else
        self.args_binary = AsyncBinary.new( :binary => args)
      end
    else
      []
    end
  end

  def result
    result_binary ? result_binary.binary : nil
  end

  def result=( result)
    if ! result.nil?
      if result_binary
        result_binary.update_attribute :binary, result
      else
        self.result_binary = AsyncBinary.new( :binary => result)
      end
    end
  end

  protected

  def object_from_db
    if object_type && object_id
      object_type.constantize.find_by_id( object_id)
    elsif object_type
      object_type.constantize
    end
  end

  def call_arguments
    if self.pass_task
      [self] + self.args
    else
      self.args
    end
  end

  def save_object
    if object_new_record?
      object.save
    end

    if object_active_record?
      self.object_type = object.class.to_s
      self.object_id   = object.id
    else
      self.object_type = object.to_s
    end
  end

  def validate_object
    if object_new_record?
      errors.add_to_base( "object is invalid") unless object.valid?
    end
  end

  def object_active_record?
    object.kind_of?( ActiveRecord::Base)
  end

  def object_new_record?
    object_active_record? && object.new_record?
  end

end
