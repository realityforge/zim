module Zim
  COMMANDS = {}

  class << self
    def mysystem(command)
      puts "system (#{Dir.pwd}): #{command}" if @verbose
      system(command) || (raise "Error executing #{command} in #{Dir.pwd}")
    end

    def in_dir(dir, &block)
      begin
        Dir.chdir(dir)
        block.call
      ensure
        Dir.chdir(dir)
      end
    end

    def in_base_dir(&block)
      in_dir(@base_dir, &block)
    end

    def in_app_dir(app, &block)
      in_dir("#{@base_dir}/#{File.basename(app)}", &block)
    end

    def command(key, options = {:in_app_dir => true}, &block)
      raise "Attempting to define duplicate command #{key}" if COMMANDS[key.to_s]
      params = options.dup
      COMMANDS[key.to_s] = Proc.new do |app|
        if params[:in_app_dir]
          in_app_dir(app) do
            block.call(app)
          end
        else
          in_base_dir do
            block.call(app)
          end
        end
      end
    end

    def run(key, app)
      puts "Unknown command specified: #{key}" unless COMMANDS[key.to_s]
      COMMANDS[key.to_s].call(app)
    end

    def context(&block)
      self.instance_eval &block
    end
  end
end