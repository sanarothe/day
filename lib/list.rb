class List

  attr_accessor :tasks, :current_context, :context_entrance_time

  def initialize(task_list, current_context, context_entrance_time)
    @tasks = []
    if task_list
      task_list.each do |task|
        #task.first refers to the key (task name), since the task is stored [key, val] and key = name
        #[:day_fulfillment][0] is the date and [1] is the accumulator.
        task_instance = Task.new(task.first, task[1][:days], task[1][:commitment], task[1][:fulfillment], task[1][:day_fulfillment])
        @tasks << task_instance if task_instance.valid_today?
      end
    end

    @current_context = current_context if current_context
    @context_entrance_time = context_entrance_time if context_entrance_time
  end

  def printout
    puts "Day.rb (#{VERSION})"
    puts "Today's tasks:"
    puts ""
    ii = 0
    @tasks.each_with_index do |task, ii|
      print ii.to_s + ': ' + task.name
      if task.time_commitment
        print_fulfillment(task.fulfillment, task.time_commitment, task.day_fulfillment)
      else
        print "\n"
      end
    end
    puts "\n"
    if @current_context
      current_task = find_task_by_number(@current_context)
      time_difference_minutes = (Time.now.getutc - @context_entrance_time) / 60
      time_diff_today = current_task.day_fulfillment + time_difference_minutes if current_task.day_fulfillment
      print "Current task: " + " (#{@current_context}) " + current_task.name
      if current_task.time_commitment
        print_fulfillment(time_difference_minutes, current_task.time_commitment, time_diff_today)
      else
        puts "\n"
        print_time(time_difference_minutes)
      end
      puts "\n"
    end
  end

  def print_fulfillment(fulfillment, commitment, day_fulfillment)
    if fulfillment
      diff = fulfillment.to_f / commitment.to_f * 100
      print " [#{'%2.1f' %fulfillment}/#{commitment}] "
      print " [#{'%2.1f' % diff}%]"
      if day_fulfillment
        puts " (#{'%2.1f' % day_fulfillment} minutes today)"
      else
        puts ""
      end
    else
      puts " [0/#{commitment}] "
    end
  end

  def switch(config, histclass, context_number)

    if @tasks.empty?
      raise RuntimeError, "No tasks are defined."
    end

    unless (0..@tasks.size-1).member?(context_number.to_i)
      raise ArgumentError, "Context choice out of bounds."
    end

    unless @current_context
      puts "Enter context: " + find_task_by_number(context_number).name
      config.save_context_switch(context_number)
    end

    if @current_context == context_number
      current_task = find_task_by_number(@current_context)
      puts "Exit Context: " + current_task.name
      time_difference = (Time.now.getutc - @context_entrance_time) / 60
      config.update_fulfillment(current_task.name, time_difference) if current_task.time_commitment
      print_time(time_difference)
      histclass.save_history(current_task.name, @context_entrance_time, Time.now.getutc)
      config.clear_current_context
      return
    end

    if @current_context && @context_entrance_time
      current_task = find_task_by_number(@current_context)
      puts "Exit context: " + current_task.name
      time_difference = (Time.now.getutc - @context_entrance_time) / 60
      print_time(time_difference)
      config.update_fulfillment(current_task.name, time_difference)
      puts "Enter context: " + find_task_by_number(context_number).name
      histclass.save_history(current_task.name, @context_entrance_time, Time.now.getutc)
      config.clear_current_context
      config.save_context_switch(context_number)
    end
  end

  def print_time(time_difference)
    puts "Time: " + ('%.1f' % (time_difference)).to_s + " minutes."
  end

  def find_task_by_number(numeric_selection)
    if @tasks[numeric_selection.to_i]
      return @tasks[numeric_selection.to_i]
    else
      return nil
    end
  end

  def clear_fulfillments(config)
    config.data[:tasks].each do |key, value|
      value[:fulfillment] = nil
      value[:day_fulfillment] = nil
    end
    config.save_self
  end

end