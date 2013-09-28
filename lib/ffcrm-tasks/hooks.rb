

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


  end
end
