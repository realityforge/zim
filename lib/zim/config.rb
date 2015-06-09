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

  # Class used to configure the Zim library
  class Config

    @base_directory = nil
    @log_level = nil

    class << self
      attr_writer :base_directory

      def base_directory
        @base_directory || (raise 'Base directory undefined')
      end

      def source_tree_directory
        "#{base_directory}/#{Zim.repository.current_source_tree.directory}"
      end

      def log_level=(log_level)
        valid_log_levels = [:normal, :verbose, :quiet]
        raise "Invalid log level #{log_level} expected to be one of #{valid_log_levels.inspect}" unless valid_log_levels.include?(log_level)
        @log_level = log_level
      end

      def log_level
        @log_level || :info
      end

      def verbose?
        self.log_level == :verbose
      end

      def quiet?
        self.log_level == :verbose
      end
    end
  end
end
