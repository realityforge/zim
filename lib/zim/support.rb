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

  # Contains all the support methods for performing actions in code bases

  class << self

    # Execute a ruby command within the context of rbenv environment.
    # e.g.
    #
    #    rbenv_exec('bundle install')
    #
    def rbenv_exec(command)
      mysystem("unset RBENV_DIR; unset RBENV_VERSION; unset RBENV_ROOT; unset RBENV_HOOK_PATH; rbenv exec #{command}")
    end

    # Patch a particular file in block, returning updated contents from block
    # If the file has been modified in the block, then it will be added to the
    # git index and the method will return true.
    # e.g.
    #
    #    patched = patch_file('.ruby-version') do |content|
    #      content.gsub('2.1.2', '2.1.3')
    #    end
    #    if patched
    #      mysystem('git commit -m "Update to the latest version of ruby."')
    #    end
    #
    def patch_file(file, &block)
      filename = "#{Dir.pwd}/#{file}"
      if File.exist?(filename)
        contents = IO.read(filename)
        new_contents = block.call(contents.dup)
        if contents != new_contents
          File.open(filename, 'wb') { |f| f.write new_contents }
          mysystem("git add #{file}")
          return true
        end
      end
      false
    end

    # Update the versions for specified dependencies to a target version.
    # The command assumes that dependencies are stored in build.yaml as per
    # buildr requirements. If the build.yaml has not been modified then the
    # method will return false. Otherwise the updated build.yaml will
    # be committed to repository.
    # e.g.
    #
    #    patched = patch_versions(app, %w(com.icegreen:greenmail:jar), '1.4.0')
    #    if patched
    #      puts "Greenmail was updated!"
    #    end
    #
    def patch_versions(app, dependencies, target_version, options = {})
      dependencies = dependencies.is_a?(Array) ? dependencies : [dependencies]
      source_versions = options[:source_versions]
      name = options[:name] || dependencies[0].gsub(/\:.*/, '')

      patched =
        patch_dependencies_in_file('build.yaml', dependencies, source_versions, target_version) ||
        patch_dependencies_in_file('README.md', dependencies, source_versions, target_version)
      if patched
        mysystem("git commit -m \"Update the #{name} dependency.\"")
        puts "Update the #{name} dependency in #{app}"
      end
    end

    def patch_dependencies_in_file(filename, dependencies, source_versions, target_version)
      patch_file(filename) do |content|
        dependencies.each do |dependency|
          if source_versions
            source_versions.each do |source_version|
              content.gsub!("#{dependency}:#{source_version}", "#{dependency}:#{target_version}")
            end
          else
            content.gsub!(/#{dependency.gsub(':', "\\:").gsub('.', "\\.")}\:.*/, "#{dependency}:#{target_version}")
          end
        end
        content
      end
    end

    # Update the coordinates of specified dependencies and changed version to a target version.
    # The command assumes that dependencies are stored in build.yaml as per
    # buildr requirements. If the build.yaml has not been modified then the
    # method will return false. Otherwise the updated build.yaml will
    # be committed to repository.
    # e.g.
    #
    #    patch_dependency_coordinates(app,
    #                                 {
    #                                   'iris.calendar:calendar-ux:jar' => 'iris.calendar:calendar-gwt:jar',
    #                                   'iris.calendar:calendar-ux-qa:jar' => 'iris.calendar:calendar-gwt-qa-support:jar',
    #                                   'iris.calendar:calendar-client:jar' => 'iris.calendar:calendar-soap-client:jar',
    #                                   'iris.calendar:calendar-fake:jar' => 'iris.calendar:calendar-soap-qa-support:jar'
    #                                 },
    #                                 '1ae6f3a-546')
    #
    def patch_dependency_coordinates(app, dependencies, target_version, options = {})
      source_versions = options[:source_versions]
      name = options[:name] || dependencies.keys[0].gsub(/\:.*/, '')

      patched = patch_file('build.yaml') do |content|
        dependencies.each do |source_dependency, target_dependency|
          if source_versions
            source_versions.each do |source_version|
              content.gsub!("#{source_dependency}:#{source_version}", "#{target_dependency}:#{target_version}")
            end
          else
            content.gsub!(/#{source_dependency.gsub(':', "\\:").gsub('.', "\\.")}\:.*/, "#{target_dependency}:#{target_version}")
          end
        end
        content
      end
      if patched
        mysystem("git commit -m \"Update the #{name} dependency coordinates.\"")
        puts "Update the #{name} dependency coordinates in #{app}"
      end
    end

    # Patch the Gemfile in block, returning updated contents from block
    # If the Gemfile has not been modified in the block then the method will return false.
    # Otherwise bundler will be invoked to regenerate Gemfile.lock and the updated
    # Gemfile and Gemfile.lock (if checked in) will be committed to repository.
    # e.g.
    #
    #    patched = patch_gemfile('Update to the latest version of Buildr gem.') do |content|
    #      content.
    #        gsub("gem 'buildr', '= 1.4.20'", "gem 'buildr', '= 1.4.22'").
    #        gsub("gem 'buildr', '= 1.4.21'", "gem 'buildr', '= 1.4.22'")
    #    end
    #    if patched
    #      puts "Buildr was updated!"
    #    end
    #
    def patch_gemfile(commit_message, &block)
      filename = "#{Dir.pwd}/Gemfile"
      if File.exist?(filename)
        contents = IO.read(filename)
        new_contents = block.call(contents.dup)
        if contents != new_contents
          File.open(filename, 'wb') { |f| f.write new_contents }
          mysystem('rm -f Gemfile.lock')
          rbenv_exec('bundle install')
          mysystem('git add Gemfile')
          begin
            # Not all repos have lock files checked in
            mysystem('git ls-files Gemfile.lock --error-unmatch > /dev/null 2> /dev/null && git add Gemfile.lock')
          rescue
          end
          mysystem("git commit -m \"#{commit_message}\"")
          return true
        end
      end
      false
    end

    # Execute braid update on path if the path is present.
    # This command assumes rbenv context with braid installed.
    # e.g.
    #
    #    braid_update(app, 'vendor/plugins/dbt')
    #
    def braid_update(app, path)
      if File.exist?(path)
        begin
          rbenv_exec("braid update #{path}")
        rescue
          mysystem("git remote rm master/braid/#{path} >/dev/null 2>/dev/null") rescue
            rbenv_exec("braid update #{path}")
        end
        puts "Upgraded #{path} in #{app}"
      end
    end

    # Execute braid diff for path if the path is present.
    # This command assumes rbenv context with braid installed.
    # e.g.
    #
    #    braid_diff(app, 'vendor/plugins/dbt')
    #
    def braid_diff(app, path)
      if File.exist?(path)
        puts "Braid Diff #{path} in #{app}"
        rbenv_exec("braid diff #{path}")
      end
    end

    # Add a command that updates the version of a dependency family
    # in projects (assuming all dependencies are in build.yaml)
    #
    # e.g. Updating a dependency with a single coordinate
    #
    #    dependency(:greenmail, %w(com.icegreen:greenmail:jar), '1.4.0')
    #
    # e.g. Updating multiple dependencies with related coordinates
    #
    #    dependency(:iris, %w(iris:iris-db:jar iris:iris-soap-qa-support:jar iris:iris-soap-client:jar), 'e846707-879')
    #
    def dependency(code, artifacts, target_version, source_versions = nil)
      desc "Update the #{code} dependencies in build.yaml"
      command(:"patch_#{code}_dep") do |app|
        patch_versions(app, artifacts, target_version, :source_versions => source_versions)
      end
    end

    # Define braid update and diff tasks for single path.
    # e.g.
    #
    #    braid_tasks('dbt', 'vendor/plugins/dbt')
    #
    def braid_tasks(key, path)
      command(:"braid_update_#{key}") do |app|
        braid_update(app, path)
      end
      command(:"braid_diff_#{key}") do |app|
        braid_diff(app, path)
      end
    end
  end
end
