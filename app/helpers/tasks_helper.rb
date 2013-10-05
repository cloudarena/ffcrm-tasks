
# load the main application task_helpers.
helper_path = Rails.application.helpers_paths.reject {|p| p == File.dirname(__FILE__)}.first
load(File.expand_path('tasks_helper.rb', helper_path))

# override
module TasksHelper

  def task_assignee(task)
    task.assigned_to || task.user.id
  end

  def hide_task_and_possibly_bucket(task, bucket)
    text = "jQuery('##{dom_id(task)}').remove();\n"
    text << "jQuery('#user_#{task_assignee(task)} #list_#{h bucket.to_s}').fadeOut({ duration:500 });\n" if Task.bucket_empty?(bucket, User.find_by_id(task_assignee(task)), @view)
    text.html_safe
  end

  def replace_content(task, bucket = nil)
    partial = (task.assigned_to && task.assigned_to != current_user.id) ? "assigned" : "pending"
    html = render(:partial => "tasks/#{partial}", :collection => [ task ], :locals => { :bucket => bucket })
    text = "jQuery('##{dom_id(task)}').html('#{ j html }');\n".html_safe
  end

  #----------------------------------------------------------------------------
  def insert_content(task, bucket, view)
    text = "jQuery('#user_#{task_assignee(task)} #list_#{bucket}').show();\n".html_safe
    html = render(:partial => view, :collection => [ task ], :locals => { :bucket => bucket })
    text << "jQuery('#user_#{task_assignee(task)} ##{h bucket.to_s}').prepend('#{ j html }');\n".html_safe
    text << "jQuery('##{dom_id(task)}').effect('highlight', { duration:1500 });\n".html_safe
    text
  end

  def reassign(task)
    text = "".html_safe
    if @view == "pending" && task_assignee(task)  !=  task_assignee(@task_before_update)
      text << hide_task_and_possibly_bucket(task, @task_before_update.bucket)
      text << tasks_flash( t(:task_assigned, (h @task.assignee.try(:full_name))) + " (#{link_to(t(:view_assigned_tasks), url_for(:controller => :tasks, :view => :assigned))})" )
      text << insert_content(task, task.bucket, @view)
    elsif @view == "assigned" && @task.assigned_to.blank?
      text << hide_task_and_possibly_bucket(task, @task_before_update.bucket)
      text << tasks_flash( t(:task_pending) + " (#{link_to(t(:view_pending_tasks), tasks_url)}.")
      text << insert_content(task, task.bucket, @view)   if @task.assigned_to
    else
      text << replace_content(@task, @task.bucket)
    end
    text << refresh_sidebar(:index, :filters)
    text
  end

  def show_bucket(task, bucket)
    text = "".html_safe
    text << "jQuery('#list_#{h bucket.to_s}').fadeOut({ duration:500 });\n" if Task.bucket_empty?(bucket, current_user, @view)
    text.html_safe
  end

end
