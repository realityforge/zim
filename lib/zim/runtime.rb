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
      original_dir = Dir.pwd
      begin
        Dir.chdir(dir)
        block.call
      ensure
        Dir.chdir(original_dir)
      end
    end

    # change to the base directory before evaluating block
    def in_base_dir(&block)
      in_dir(Zim::Config.source_tree_directory, &block)
    end

    def desc(description)
      @next_description = description
    end

    def command(key, options = {:in_app_dir => true}, &block)
      raise "Attempting to define duplicate command #{key}" if COMMANDS[key.to_s]
      description = @next_description
      @next_description = nil
      COMMANDS[key.to_s] = Command.new(key, options.merge(:action => block, :description => description))
    end

    def run?(app)
      return true unless Zim::Config.project_select_mode != :all
      Zim.in_base_dir do
        return false unless File.exist?(dir_for_app(app.key))
        in_app_dir(app.key) do
          if Zim::Config.only_modify_unchanged?
            return !Zim.cwd_has_unpushed_changes?
          elsif Zim::Config.only_modify_changed?
            return Zim.cwd_has_unpushed_changes?
          end
        end
      end
    end

    # change to the specified applications directory before evaluating block
    def in_app_dir(app, &block)
      Zim.in_dir(dir_for_app(app), &block)
    end

    def dir_for_app(app)
      "#{Zim::Config.source_tree_directory}/#{File.basename(app)}"
    end

    def run(key, app)
      command = COMMANDS[key.to_s]
      raise "Unknown command specified: #{key}" unless command
      puts "Processing #{command.key} on #{app}" if Zim::Config.verbose?
      command.run(app)
    end
  end
end
