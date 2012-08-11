require 'lib/soft_delete.rb'

module SoftDeletable
  def self.included(klass)
    klass.send(:extend, MacroMethods)
  end

  module InstanceMethods
    def soft_delete!
      update_attribute :deleted_at, Time.zone.now

      # soft_delete all dependencies (down the chain)
      self.class.aasd_dependents.each do |assoc|
        self.send(assoc).each do |r|
          r.soft_delete!
        end
      end
    end

    def recover!
      update_attribute :deleted_at, nil

      # recover all dependencies
      self.class.aasd_dependents.each do |assoc|
        self.send(assoc).unscoped.deleted.each do |r|
          r.recover!
        end
      end

      # recover all depends_on
      self.class.aasd_depends_on.each do |assoc|
        self.send(assoc).recover! if self.send(assoc).deleted?
      end
    end

    def deleted?
      deleted_at.present?
    end
  end

  module MacroMethods
    def acts_as_soft_deletable(opts={})
      cattr_accessor :aasd_dependents, :aasd_depends_on, :table_name

      self.aasd_dependents = opts[:dependents] || {}
      self.aasd_depends_on = opts[:depends_on] || {}
      self.table_name = opts[:table_name] || self.to_s.tableize
      self.send(:include, InstanceMethods)

      # need to add the table name to the query to avoid ambiguous columns
      default_scope where("#{table_name}.deleted_at IS NULL")
      scope :deleted, where("#{table_name}.deleted_at IS NOT NULL")
    end
  end
end