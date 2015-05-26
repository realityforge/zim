module Zim
  COMMANDS = {}

  class << self

    def repository
      @repository ||= Repository.new
    end

    # Run system command and raise an exception if it returns a non-zero exit status
    def mysystem(command)
      puts "system (#{Dir.pwd}): #{command}" if @verbose
      system(command) || (raise "Error executing #{command} in #{Dir.pwd}")
    end

    # Evaluate block after changing directory to specified directory
    def in_dir(dir, &block)
      begin
        Dir.chdir(dir)
        block.call
      ensure
        Dir.chdir(dir)
      end
    end

    # change to the base directory before evaluating block
    def in_base_dir(&block)
      in_dir(@base_dir, &block)
    end

    # change to the specified applications directory before evaluating block
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
  end
end
