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
  class Repository
    def source_tree(key, config = {})
      SourceTreeDefinition.new(self, key, config)
    end

    def source_trees
      source_tree_map.values
    end

    def source_tree_by_name(key)
      source_tree = source_tree_map[key.to_s]
      raise "Unable to locate source tree by key '#{key}'" unless source_tree
      source_tree
    end

    def source_tree_exists?(key)
      !!source_tree_map[key.to_s]
    end

    protected

    def source_tree_map
      @source_trees ||= {}
    end

    def register_source_tree(source_tree)
      key = source_tree.key.to_s
      raise "Attempting to register duplicate source tree with key '#{key}'" if source_tree_exists?(key)
      source_tree_map[key] = source_tree
    end
  end
end