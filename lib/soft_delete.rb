ActiveSupport.on_load(:active_record) do
  # include the SoftDeleteable module into ActiveRecord
  ActiveRecord::Base.send(:include, SoftDeletable)
end
