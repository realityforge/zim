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

module Zim # nodoc

  # Class used to run the command line tool
  class Driver
    class << self

      def process(args)

        initial_args = args.dup

        customization_file = "#{Dir.pwd}/_zim.rb"
        require customization_file if File.exist?(customization_file)

        optparse = OptionParser.new do |opts|
          opts.on('-s', '--source-tree-set SOURCE_TREE_SET', 'Specify the set of projects to process') do |source_tree_key|
            unless Zim.repository.source_tree_exists?(source_tree_key)
              puts "Bad source tree set #{source_tree_key} specified. Specify one of:\n#{Zim.repository.source_trees.collect { |c| "  * #{c.key}" }.join("\n")}"
              exit
            end
            Zim.repository.current_source_tree_key = source_tree_key
          end

          opts.on('--first-app APP_NAME', 'The first app to process actions for') do |app_key|
            Zim::Config.first_app = app_key
          end

          opts.on('-c', '--changed', 'Only run commands if source tree is already modified.') do
            Zim::Config.only_modify_changed = true
          end

          opts.on('-v', '--verbose', 'More verbose logging') do
            Zim::Config.log_level = :verbose
          end

          opts.on('-d', '--base-directory DIR', 'Base directory in which source trees are stored') do |dir|
            Zim::Config.base_directory = dir
          end

          opts.on('-q', '--quiet', 'Be very very quiet, we are hunting wabbits') do
            Zim::Config.log_level = :quiet
          end

          opts.on('-i', '--include TAG', 'Specify application tags that must appear when selecting applications') do |tag|
            Zim::Config.include_tags << tag
          end

          opts.on('-e', '--exclude TAG', 'Specify application tags that must not appear when selecting applications') do |tag|
            Zim::Config.exclude_tags << tag
          end

          opts.on('-f', '--filter CMD', 'Specify command that must return success to include project') do |filter|
            Zim::Config.filters << filter
          end

          opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
          end
        end

        optparse.parse!(args)

        begin
          Zim::Config.base_directory
        rescue
          puts 'No base directory defined. Set Zim::Config.base_directory in _zim.rb or on the command line via: --base-directory DIR'
          exit
        end

        if 0 == args.size
          puts "No commands specified. Specify one of:\n#{Zim::COMMANDS.keys.sort.collect { |c| "  * #{Zim::COMMANDS[c].help_text}" }.join("\n")}"
          exit
        end

        unless Zim.repository.current_source_tree?
          puts 'No source tree set. Set one by passing parameters: -s SET'
          exit
        end

        args.each do |command|
          unless Zim::COMMANDS[command]
            puts "Unknown command specified: #{command}"
            exit
          end
        end

        if Zim::Config.verbose?
          puts "Source Tree Directory: #{Zim::Config.source_tree_directory}"
          puts "Commands specified: #{args.collect { |c| c.to_s }.join(', ')}"
        end

        FileUtils.mkdir_p Zim::Config.source_tree_directory

        skip_apps = !Zim::Config.first_app.nil?
        Zim.context do
          Zim.repository.current_source_tree.applications.each do |app|
            skip_apps = false if !Zim::Config.first_app.nil? && Zim::Config.first_app == app.key
            if skip_apps
              puts "Skipping #{app.key}" if Zim::Config.verbose?
            else
              if Zim::Config.include_tags.size > 0 || Zim::Config.exclude_tags.size > 0
                if Zim::Config.include_tags.size > 0
                  next unless Zim::Config.include_tags.all? { |t| app.tags.include?(t) }
                end
                if Zim::Config.exclude_tags.size > 0
                  next if Zim::Config.exclude_tags.any? { |t| app.tags.include?(t) }
                end
              end
              if Zim::Config.filters.size > 0
                matched = true
                in_app_dir(app.key) do
                  Zim::Config.filters.each do |t|
                    `#{t} 2>&1`
                    matched = false unless $?.exitstatus == 0
                  end
                end
                next unless matched
              end
              if run?(app)
                puts "Processing #{app.key}" unless Zim::Config.quiet?
                in_base_dir do
                  args.each do |key|
                    begin
                      run(key, app.key)
                    rescue Exception => e
                      Zim::Driver.print_command_error(app.key, initial_args, "Error processing stage #{key} on application '#{app.key}'.")
                      raise e
                    end
                  end
                end
              end
            end
          end
        end
      end

      def print_command_error(app, initial_args, message)
        puts message
        puts 'Fix the problem and rerun the command via:'

        args = []
        skip_next = false
        initial_args.each do |arg|
          if skip_next
            skip_next = false
            next
          end
          if arg == '--first-app'
            skip_next = true
          else
            args << arg
          end
        end

        puts " #{$0} --first-app #{app} #{args.join(' ')} "
      end
    end
  end
end
