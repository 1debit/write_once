# frozen_string_literal: true

require_relative "write_once/version"
require_relative "write_once/configuration"
require "active_record"
require "active_support/concern"
require "active_support/hash_with_indifferent_access"

class WriteOnceAttributeError < StandardError; end

module WriteOnce
  extend ActiveSupport::Concern

  included do
    class_attribute :_attr_write_once, instance_accessor: false, default: []
  end

  def self.configure(&block)
    block.call(config)
  end

  def self.config
    @config ||= Configuration.new
  end

  module ClassMethods
    # Attributes listed as write_once will be used to create a new record.
    # Assigning a new value to a write_once attribute that is NOT currently nil
    # and is attempting to be changed on a persisted record raises an error.
    #
    # ==== Examples
    #
    #   class Post < ActiveRecord::Base
    #     attr_write_once :title
    #   end
    #
    #   post = Post.create!(title: "Introducing Ruby on Rails!")
    #   post.title = "a different title" # raises write_onceAttributeError
    #   post.update(title: "a different title") # raises write_onceAttributeError
    #
    #   post_with_nil = Post.create!(title: nil)
    #   post_with_nil.title = "a different title" # works fine
    #
    #   post_with_nil2 = Post.create!(title: nil)
    #   post_with_nil2.update(title: "a different title") # works fine
    def attr_write_once(*attributes)
      self._attr_write_once |= attributes.map(&:to_s)

      include(HasWriteOnceAttributes)
    end

    # Returns an array of all the attributes that have been specified as write_once.
    def write_once_attributes
      _attr_write_once
    end

    def write_once_attribute?(name) # :nodoc:
      _attr_write_once.include?(name)
    end
  end

  module HasWriteOnceAttributes # :nodoc:
    def valid_change?(attr_name, new_value)
      current_value = send(attr_name)
      current_value.nil? || current_value == new_value
    end

    def attr_is_write_only?(attr_name)
      self.class.write_once_attribute?(attr_name.to_s)
    end

    def write_attribute(attr_name, value)
      if !new_record? && attr_is_write_only?(attr_name) && !valid_change?(attr_name, value)
        handle_error(attr_name, value)
      end

      super
    end

    def _write_attribute(attr_name, value)
      if !new_record? && attr_is_write_only?(attr_name) && !valid_change?(attr_name, value)
        handle_error(attr_name, value)
      end

      super
    end

    def handle_error(attr_name, value)
      if WriteOnce.config.enforce_errors
        raise WriteOnceAttributeError, attr_name
      else
        WriteOnce.config.logger.warn(
          message: "Write once attribute #{attr_name} changed",
          old_value: send(attr_name),
          new_value: value,
        )
      end
    end
  end
end
