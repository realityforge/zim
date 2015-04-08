module Zim
  class << self
    def context(&block)
      self.instance_eval &block
    end
  end
end