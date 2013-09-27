


# inject empty stuff here
ActiveSupport.on_load(:fat_free_crm_task) do 
  class_eval do
    def email_ids
      []
    end

    # fix the task mode's bug. only new record
    def specific_time
      parse_calendar_date if self.bucket == "specific_time" and self.calendar
    rescue ArgumentError
      errors.add(:calendar, :invalid_date)
    end
  end
end
