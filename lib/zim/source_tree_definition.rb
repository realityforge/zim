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

  class SourceTreeDefinition < BaseElement
    attr_reader :repository
    attr_accessor :base_git_url

    def initialize(repository, key, options, &block)
      @repository = repository
      @applications = {}
      repository.send(:register_source_tree, key, self)

      options = options.dup
      applications = options.delete(:applications) || {}

      if applications.is_a?(Array)
        applications.each do |app|
          self.application(app, :git_url => app)
        end
      else
        applications.each_pair do |app, config|
          self.application(app, config)
        end
      end

      super(key, options, &block)
    end

    def directory
      @directory || key
    end

    attr_writer :directory

    def application(key, config = {})
      ApplicationDefinition.new(self, key, config)
    end

    def applications
      application_map.values
    end

    def application_by_name(key)
      application = application_map[key.to_s]
      raise "Unable to locate application definition by key '#{key}'" unless application
      application
    end

    def application_exists?(key)
      !!application_map[key.to_s]
    end

    protected

    def application_map
      @applications ||= {}
    end

    def register_application(key, application)
      raise "Attempting to register duplicate application definition with key '#{key}'" if application_exists?(key)
      application_map[key] = application
    end
  end
end