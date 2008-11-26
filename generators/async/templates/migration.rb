class CreateAsyncTasks < ActiveRecord::Migration
  def self.up
    create_table :async_tasks, :force => true do |t|
      t.column :object_id,   :integer
      t.column :object_type, :string,   :null => false
      t.column :action,             :string,   :null => false
      t.column :args_binary_id,     :integer
      t.column :result_binary_id,   :integer
      t.column :parent_id,          :integer
      t.column :priority,           :integer,  :null => false
      t.column :pass_task,          :boolean,  :null => false, :default => false
      t.column :success,            :boolean
      t.column :scheduled_at,       :datetime, :null => false
      t.column :started_at,         :datetime
      t.column :finished_at,        :datetime
      t.column :created_at,         :datetime
    end

    add_index :async_tasks, :object_id
    add_index :async_tasks, :object_type
    add_index :async_tasks, :parent_id
    add_index :async_tasks, :args_binary_id
    add_index :async_tasks, :result_binary_id

    create_table :unfinished_tasks, :force => true do |t|
      t.column :async_task_id, :integer,  :null => false
      t.column :priority,      :integer,  :null => false
      t.column :scheduled_at,  :datetime, :null => false
      t.column :started,       :boolean,  :null => false
    end

    add_index :unfinished_tasks, :async_task_id
    add_index :unfinished_tasks, :priority
    add_index :unfinished_tasks, :scheduled_at
    add_index :unfinished_tasks, :started

    create_table :async_binaries, :force => true do |t|
      t.column :binary,        :binary,   :null => false
    end

  end

  def self.down
    drop_table :async_binaries
    drop_table :unfinished_tasks
    drop_table :async_tasks
  end
end
