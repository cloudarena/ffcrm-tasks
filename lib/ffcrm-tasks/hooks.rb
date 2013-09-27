


# inject empty stuff here
ActiveSupport.on_load(:fat_free_crm_task) do 
  class_eval do
    def email_ids
      []
    end
  end
end
