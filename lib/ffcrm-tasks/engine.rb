module FfcrmTasks
  class Engine < ::Rails::Engine

    # 
    # move earger load out to move it's actually load order to later of load chain
    # 
    def eager_load!
      # empty so that the engine's stuff is not loaded in primary rails eager_load process
    end

    # 
    #   Load all stuff that belongs to ffcrm-tasks engine. 
    #
    def engine_eager_load! 
      railties.all(&:eager_load!)
      config.eager_load_paths.each do |load_path|
        matcher = /\A#{Regexp.escape(load_path)}\/(.*)\.rb\Z/
        Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
          # remove the previous class (if exists) and require again (with new load path/order)
          name = file.sub(matcher, '\1')
          class_name = ActiveSupport::Inflector.camelize name
          Object.send(:remove_const, class_name) if Object.const_defined?(class_name)
          require_dependency name
        end
      end
    end


    # 
    # Here is trick to override the rails applicatioin's controller. 
    # notice it's not good idea to override the main application, since it's fighting back to framework rules. 
    # so use it with caution! and use only in case that you really understand the Rails bootstrap process clearly.
    # - Frank.
    #
    initializer :override_app_autoloads_paths do
      mod_all_autoload_paths  = _all_autoload_paths
      mod_all_autoload_once_paths = _all_autoload_once_paths
      mod_engine = self

      ActiveSupport.on_load(:after_initialize) do
        ActiveSupport::Dependencies.autoload_paths -= mod_all_autoload_paths
        ActiveSupport::Dependencies.autoload_paths.unshift(*mod_all_autoload_paths)
        ActiveSupport::Dependencies.autoload_once_paths -= mod_all_autoload_once_paths
        ActiveSupport::Dependencies.autoload_once_paths.unshift(*mod_all_autoload_once_paths)
#        ActiveSupport::Dependencies.clear
        mod_engine.engine_eager_load!
      end
    end

  end
end

