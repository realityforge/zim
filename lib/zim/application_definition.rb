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

  class ApplicationDefinition < BaseElement
    attr_reader :source_tree
    attr_accessor :git_url

    def initialize(source_tree, key, options, &block)
      source_tree.send(:register_application, key, self)
      @source_tree = source_tree
      super(key, options, &block)
    end
  end
end
