# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------


#
# Chagne task controller to inherit controller.  so that it support neccessary facilities in ffcrm-tasks
# (this require to fix up task model simutaneously, since entity controller have callback/filters 
# that impose more requirement to model class. note for model class change code, it is injected with hooks ). 
# 

class TasksController < EntitiesController
  before_filter :set_current_tab, :only => [ :index, :show ]
  before_filter :update_sidebar, :only => :index

  # GET /tasks
  #----------------------------------------------------------------------------
  def index
    @view = params[:view] || "pending"
    @users = current_user.groups.map{|g| g.users}.flatten.uniq
    @users.tap{|users| 
      users.delete(current_user);
      users.unshift(current_user);
    }
    @mapping = {}  # uid -> tasks mapping.
    @tasks = []
    @users.each do |user| 
      tasks = Task.find_all_grouped(user,@view)
      @tasks += tasks.map(&:second).flatten
    end

    respond_with @tasks do |format|
      format.xls { render :layout => 'header' }
      format.csv { render :csv => @tasks }
      format.xml { render :xml => @tasks, :except => [:subscribed_users] }
    end
  end

  # GET /tasks/1
  #----------------------------------------------------------------------------
  def show
    @task = Task.tracked_by(current_user).find(params[:id])

    respond_with(@task)
  end

  # GET /tasks/new
  #----------------------------------------------------------------------------
  def new
    @view = params[:view] || "pending"
    @task = Task.new
    @bucket = Setting.unroll(:task_bucket)[1..-1] << [ t(:due_specific_date, :default => 'On Specific Date...'), :specific_time ]
    @category = Setting.unroll(:task_category)

    if params[:related]
      model, id = params[:related].split(/_(\d+)/)
      if related = model.classify.constantize.my.find_by_id(id)
        instance_variable_set("@asset", related)
      else
        respond_to_related_not_found(model) and return
      end
    end

    respond_with(@task)
  end

  # GET /tasks/1/edit                                                      AJAX
  #----------------------------------------------------------------------------
  def edit
    @view = params[:view] || "pending"
    @task = Task.tracked_by(current_user).find(params[:id])
    @bucket = Setting.unroll(:task_bucket)[1..-1] << [ t(:due_specific_date, :default => 'On Specific Date...'), :specific_time ]
    @category = Setting.unroll(:task_category)
    @asset = @task.asset if @task.asset_id?

    if params[:previous].to_s =~ /(\d+)\z/
      @previous = Task.tracked_by(current_user).find_by_id($1) || $1.to_i
    end

    respond_with(@task)
  end

  # POST /tasks
  #----------------------------------------------------------------------------
  def create
    @view = params[:view] || "pending"
    @task = Task.new(params[:task]) # NOTE: we don't display validation messages for tasks.

    respond_with(@task) do |format|
      if @task.save
        update_sidebar if called_from_index_page?
      end
    end
  end

  # PUT /tasks/1
  #----------------------------------------------------------------------------
  def update
    @view = params[:view] || "pending"
    @task = Task.tracked_by(current_user).find(params[:id])
    @task_before_update = @task.dup

    if @task.due_at && (@task.due_at < Date.today.to_time)
      @task_before_update.bucket = "overdue"
    else
      @task_before_update.bucket = @task.computed_bucket
    end

    respond_with(@task) do |format|
      if @task.update_attributes(params[:task])
        @task.bucket = @task.computed_bucket
        if called_from_index_page?
          if Task.bucket_empty?(@task_before_update.bucket, current_user, @view)
            @empty_bucket = @task_before_update.bucket
          end
          update_sidebar
        end
      end
    end
  end

  # DELETE /tasks/1
  #----------------------------------------------------------------------------
  def destroy
    @view = params[:view] || "pending"
    @task = Task.tracked_by(current_user).find(params[:id])
    @task.destroy

    # Make sure bucket's div gets hidden if we're deleting last task in the bucket.
    if Task.bucket_empty?(params[:bucket], current_user, @view)
      @empty_bucket = params[:bucket]
    end

    update_sidebar if called_from_index_page?
    respond_with(@task) do |format|
      format.html { redirect_to tasks_path }
    end
  end

  # PUT /tasks/1/complete
  #----------------------------------------------------------------------------
  def complete
    @task = Task.tracked_by(current_user).find(params[:id])
    @task.update_attributes(:completed_at => Time.now, :completed_by => current_user.id) if @task

    # Make sure bucket's div gets hidden if it's the last completed task in the bucket.
    if Task.bucket_empty?(params[:bucket], current_user)
      @empty_bucket = params[:bucket]
    end

    update_sidebar unless params[:bucket].blank?
    respond_with(@task)
  end

  # POST /tasks/auto_complete/query                                        AJAX
  #----------------------------------------------------------------------------
  # Handled by ApplicationController :auto_complete

  # Ajax request to filter out a list of tasks.                            AJAX
  #----------------------------------------------------------------------------
  def filter
    @view = params[:view] || "pending"

    update_session do |filters|
      if params[:checked].true?
        filters << params[:filter]
      else
        filters.delete(params[:filter])
      end
    end
  end

  # task timeline 
  def timeline(asset)
    (asset.comments + asset.emails).sort { |x, y| y.created_at <=> x.created_at }
  end


private

  # Yields array of current filters and updates the session using new values.
  #----------------------------------------------------------------------------
  def update_session
    name = "filter_by_task_#{@view}"
    filters = (session[name].nil? ? [] : session[name].split(","))
    yield filters
    session[name] = filters.uniq.join(",")
  end

  # Collect data necessary to render filters sidebar.
  #----------------------------------------------------------------------------
  def update_sidebar
    @view = params[:view]
    @view = "pending" unless %w(pending assigned completed).include?(@view)
    @task_total = Task.totals(current_user, @view)

    # Update filters session if we added, deleted, or completed a task.
    if @task
      update_session do |filters|
        if @empty_bucket  # deleted, completed, rescheduled, or reassigned and need to hide a bucket
          filters.delete(@empty_bucket)
        elsif !@task.deleted_at && !@task.completed_at # created new task
          filters << @task.computed_bucket
        end
      end
    end

    # Create default filters if filters session is empty.
    name = "filter_by_task_#{@view}"
    unless session[name]
      filters = @task_total.keys.select { |key| key != :all && @task_total[key] != 0 }.join(",")
      session[name] = filters unless filters.blank?
    end
  end

end

