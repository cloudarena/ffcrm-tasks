require 'spec_helper'

describe TasksController do
  def update_sidebar
    @task_total = { :key => :value, :pairs => :etc }
    Task.stub(:totals).and_return(@task_total)
  end

  def produce_tasks(user, view)
    settings = (view != "completed" ? Setting.task_bucket : Setting.task_completed)

    settings.inject({}) do | hash, due |
      hash[due] ||= []
      if Date.tomorrow == Date.today.end_of_week && due == :due_tomorrow
        due = :due_this_week
        hash[due] ||= []
      end
      hash[due] << case view
                   when "pending"
                     FactoryGirl.create(:task, :user => user, :bucket => due.to_s)
                   when "assigned"
                     FactoryGirl.create(:task, :user => user, :bucket => due.to_s, :assigned_to => 1)
                   when "completed"
                     completed_at = case due
                                    when :completed_today
                                      Date.yesterday + 1.day
                                    when :completed_yesterday
                                      Date.yesterday
                                    when :completed_last_week
                                      Date.today.beginning_of_week - 7.days
                                    when :completed_this_month
                                      Date.today.beginning_of_month
                                    when :completed_last_month
                                      Date.today.beginning_of_month - 1.day
                                    end
                     FactoryGirl.create(:task, :user => user, :bucket => due.to_s, :completed_at => completed_at)
                   end
      hash
    end
  end

  before(:each) do
    require_user
    set_current_tab(:tasks)
  end
  

  ###############
  # Tasks#index
  ###############
  describe "responding to GET index" do

    before do
      @group = FactoryGirl.create(:group)
      @user = FactoryGirl.create(:user)
      @group.users << current_user <<  @user
      @group.save!
    end

    # for all task statuses.
    TASK_STATUSES.each do |view|

      it "show expose all tasks belongs to my groups as @tasks and render [index] template for #{view} " do
        @tasks = produce_tasks(current_user, view).values.flatten +  produce_tasks(@user, view).values.flatten
        get :index, :view=>view
        (assigns(:tasks) - @tasks).should == []
        response.should render_template("tasks/index")
      end
    end


  end

  ###############
  # Tasks#show
  ###############

  describe "responding to GET show" do
    
    it "show a detail page for a task of my as @task and render [show] template" do
      @task = FactoryGirl.create(:task, :user=>current_user)
      get :show, :id=>@task.id
      assigns(:task).id.should == @task.id
      response.should render_template("tasks/show")
    end

    it "redirect to task index page if the task is not mine" do
      @task = FactoryGirl.create(:task)
      get :show, :id=>@task.id
      response.should redirect_to(:action=>:index)
    end

    it "redirect to task index page if the task doesn't exist" do
      id = 999999 && (id += 1 while Task.find_by_id(id))  #get a task id that not exists.
      get :show, :id=>id
      response.should redirect_to(:action=>:index)
    end

  end

  ###############
  # Tasks#subscribe  | unscribe
  ###############
  describe "responding to POST subscribe/unsubscribe" do
    before  do
        @task = FactoryGirl.create(:task, :user=>current_user)
    end

    it "should be in task's subscribed users list after subscribe, and render [subsribe]" do
      olds_users = @task.subscribed_users
      xhr :post, :subscribe, :id=>@task.id
      @task.reload
      (@task.subscribed_users - olds_users).should include(current_user.id)
      response.should render_template("entities/subscription_update")
    end

    it "should remove from task's subscribed list after unsubscribe, and render [entities/subscription_update]" do
      olds_users = @task.subscribed_users << current_user.id
      @task.save!  # ensure user is already subscribed

      xhr :post, :unsubscribe, :id=>@task.id
      @task.reload

      (olds_users - @task.subscribed_users).should include(current_user.id)
      response.should render_template("entities/subscription_update")
    end
  end


  ###############
  # Tasks#filter
  ###############
  describe "responding to GET filter" do

    TASK_STATUSES.each do |view|
      it "should remove a filter from session and render [filter] template for #{view} view" do
        name = "filter_by_task_#{view}"
        session[name] = "due_asap,due_today,due_tomorrow"

        xhr :get, :filter, :filter => "due_asap", :view => view
        session[name].should_not include("due_asap")
        session[name].should include("due_today")
        session[name].should include("due_tomorrow")
        response.should render_template("tasks/filter")
      end

      it "should add a filter from session and render [filter] template for #{view} view" do
          name = "filter_by_task_#{view}"
          session[name] = "due_today,due_tomorrow"

          xhr :get, :filter, :checked => "true", :filter => "due_asap", :view => view
          session[name].should include("due_asap")
          session[name].should include("due_today")
          session[name].should include("due_tomorrow")
          response.should render_template("tasks/filter")
        end
      end
    end
  end

