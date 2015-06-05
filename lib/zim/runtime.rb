#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
      in_dir(Zim::Config.source_tree_directory, &block)
    end

    # change to the specified applications directory before evaluating block
    def in_app_dir(app, &block)
      in_dir("#{Zim::Config.source_tree_directory}/#{File.basename(app)}", &block)
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
