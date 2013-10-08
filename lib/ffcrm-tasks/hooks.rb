

#
# Inejct task model with the necessary mode here. 
#
ActiveSupport.on_load(:fat_free_crm_task) do 
  class_eval do

    # requireemnt for entity controllers.
    acts_as_taggable_on :tags
    sortable :by => [ "name ASC", "due_at DESC", "created_at DESC", "updated_at DESC" ], :default => "created_at DESC"

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

    # override to count all task in group
    def self.totals(user, view = "pending")
      users_in_group = User.users_in_group(user)
      settings = (view == "completed" ? Setting.task_completed : Setting.task_bucket)
      settings.inject({ :all => 0 }) do |hash, key|
        hash[key] ||= 0
        users_in_group.each {|user|
          hash[key] += (view == "assigned" ? assigned_by(user).send(key).pending.count : my(user).send(key).send(view).count)
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
