require "rails_sanitize"

module XssTerminate
  def self.included(base)
    base.extend(ClassMethods)
    # sets up default of stripping tags for all fields
    base.send(:xss_terminate)
  end

  module ClassMethods
    def xss_terminate(options = {})
      before_save :sanitize_fields

      class_attribute :xss_terminate_options
      self.xss_terminate_options = {
        :except => (options[:except] || []),
        :sanitize => (options[:sanitize] || [])
      }

      include XssTerminate::InstanceMethods
    end
  end

  module InstanceMethods

    def sanitize_fields
      # fix a bug with Rails internal AR::Base models that get loaded before
      # the plugin, like CGI::Sessions::ActiveRecordStore::Session
      return if xss_terminate_options.nil?

      self.class.columns.each do |column|
        next unless (column.type == :string || column.type == :text)

        field = column.name.to_sym
        value = self[field]

        next if value.nil? || !value.is_a?(String)

        if xss_terminate_options[:except].include?(field)
          next
        elsif xss_terminate_options[:sanitize].include?(field)
          self[field] = RailsSanitize.white_list_sanitizer.sanitize(value)
        else
          self[field] = RailsSanitize.full_sanitizer.sanitize(value)
        end
      end

    end
  end
end

ActiveRecord::Base.send(:include, XssTerminate)
