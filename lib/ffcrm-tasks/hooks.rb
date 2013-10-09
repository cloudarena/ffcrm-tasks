

#
# Inejct task model with the necessary mode here. 
#
ActiveSupport.on_load(:fat_free_crm_task) do 
  class_eval do

    # requireemnt for entity controllers.
    uses_user_permissions
    acts_as_taggable_on :tags
    sortable :by => [ "name ASC", "due_at DESC", "created_at DESC", "updated_at DESC" ], :default => "created_at DESC"


    # ar scopes

    #  actual my tasks scope. 
    # :myy is previously  :my. since :my is taken by `uses_user_permission`. rename it to :myy
    scope :myy, lambda { |*args|
      options = args[0] || {}
      user_option = (options.is_a?(Hash) ? options[:user] : options) || User.current_user
      includes(:assignee).
      where('(user_id = ? AND assigned_to IS NULL) OR assigned_to = ?', user_option, user_option).
      order(options[:order] || 'name ASC').
      limit(options[:limit]) # nil selects all records
    }



    # required for comment new
    # support email integration is not in current scope. but make it empty better than raising exception.
    def email_ids
      []
    end

    # fix the task mode's bug. 
    # task mode doesn't works good when you just wanna update some column and save. here is fix.
    def specific_time
      parse_calendar_date if self.bucket == "specific_time" and self.calendar
    rescue ArgumentError
      errors.add(:calendar, :invalid_date)
    end


    # collect all tasks in user array
    def self.tasks_of_users(users, view)
      mapping = {}  # uid -> tasks mapping.
      tasks_all = []
      users.each do |user| 
        tasks = Task.find_all_grouped(user,view)
        tasks_all += tasks.map(&:second).flatten
      end
      tasks_all
    end # def


    # transfer to use :myy scope  (which is previously :my scope, :my scope now is cancan based and permission tunnable)
    def self.find_all_grouped(user, view)
      settings = (view == "completed" ? Setting.task_completed : Setting.task_bucket)
      Hash[
           settings.map do |key, value|
             [ key, view == "assigned" ? assigned_by(user).send(key).pending : myy(user).send(key).send(view) ]
           end
          ]
    end

    # Returns bucket if it's empty (i.e. we have to hide it), nil otherwise.
    # (transfer to use :myy scope)
    def self.bucket_empty?(bucket, user, view = "pending")
      return false if bucket.blank?
      if view == "assigned"
        assigned_by(user).send(bucket).pending.count
      else
        myy(user).send(bucket).send(view).count
      end == 0
    end

    
    # override to count all tasks of group  in sidebar.
    # note  use :myy scope for now
    def self.totals(user, view = "pending")
      users_in_group = User.users_in_group(user)
      settings = (view == "completed" ? Setting.task_completed : Setting.task_bucket)
      settings.inject({ :all => 0 }) do |hash, key|
        hash[key] ||= 0
        users_in_group.each {|user|
          hash[key] += (view == "assigned" ? assigned_by(user).send(key).pending.count : myy(user).send(key).send(view).count)
          hash[:all] += hash[key]
        }
        hash
      end
    end

  end
end


###
## Hooks on User model!
#
#  Changes: 
#          add 'tasks(view)' method so that to retrieve tasks for each user in 'group task page'
#


ActiveSupport.on_load(:fat_free_crm_user) do 
  
  class_eval do

    #  get user's tasks for proper views
    def tasks(view)
      Task.find_all_grouped(self, view)
    end

    # return all users share groups
    def  self.users_in_group(user)
      users = user.groups.map{|g| g.users}.flatten.uniq
      users.tap{|users| users.delete(user); users.unshift(user);}
    end

  end # class_eval
end



####
#  Hook for cancan ability model
#  
#  relax the task's acces scope to all users in my group.
#

ActiveSupport.on_load(:fat_free_crm_ability) do

  class_eval do

    # rename previous initialize
    alias :offical_initialize  :initialize

    def initialize(user)
      # accept all previous persmission setting
      offical_initialize(user)
      
      # for tasks, grant access to tasks that belongs to group users
      if user.present?
        ids_users_in_group = User.users_in_group(user).map(&:id)
        can :manage, Task, :user_id => ids_users_in_group
        can :manage, Task, :assigned_to => ids_users_in_group
      end

    end
  end

end
