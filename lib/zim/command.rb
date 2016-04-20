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
  # Class used to represent commands within zim
  class Command < BaseElement
    attr_accessor :description
    attr_accessor :action

    def initialize(key, options, &block)
      super(key, options, &block)
    end

    def help_text
      @description.nil? ? self.key.to_s : "#{key}: #{@description}"
    end

    attr_writer :in_app_dir

    def in_app_dir?
      @in_app_dir.nil? ? true : !!@in_app_dir
    end

    def run?(app)
      return true unless Zim::Config.only_modify_changed?
      if in_app_dir?
        in_app_dir(app) do
          return Zim.cwd_has_unpushed_changes?
        end
      else
        Zim.in_base_dir do
          return false unless File.exist?(dir_for_app(app))
          in_app_dir(app) do
            return Zim.cwd_has_unpushed_changes?
          end
        end
      end
    end

    def run(app)
      if in_app_dir?
        in_app_dir(app) do
          action.call(app)
        end
      else
        Zim.in_base_dir do
          action.call(app)
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
  end
end
