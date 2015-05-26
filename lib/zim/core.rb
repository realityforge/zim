module Zim

  # Base class used for elements configurable via options
  class ConfigElement

    def initialize(options, &block)
      self.options = options
      yield self if block_given?
    end

    def options=(options)
      options.each_pair do |k, v|
        keys = k.to_s.split('.')
        target = self
        keys[0, keys.length - 1].each do |target_accessor_key|
          target = target.send target_accessor_key.to_sym
        end
        begin
          target.send "#{keys.last}=", v
        rescue NoMethodError
          raise "Attempted to configure property \"#{keys.last}\" on #{self.class} but property does not exist."
        end
      end
    end
  end

  class << self
    def context(&block)
      self.instance_eval &block
    end
  end
end