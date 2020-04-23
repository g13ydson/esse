# frozen_string_literal: true

module Esse
  # https://github.com/elastic/elasticsearch-ruby/blob/master/elasticsearch-api/lib/elasticsearch/api/actions/indices/put_settings.rb
  class Index
    module ClassMethods
      # Define /_settings definition by each index.
      #
      # +hash+: The body of the request includes the updated settings.
      # +block+: Overwrite default :as_json from IndexSetting instance
      #
      # Example:
      #
      #   class UserIndex < Esse::Index
      #     settings {
      #       number_of_replicas: 4,
      #     }
      #   end
      #
      #   class UserIndex < Esse::Index
      #     settings do
      #       file = File.open('path/to/json')
      #       JSON.parse(file.read)
      #     end
      #   end
      def settings(hash = {}, &block)
        @setting = Esse::IndexSetting.new(self, hash)
        return unless block_given?

        @setting.define_singleton_method(:as_json, &block)
      end

      private

      def setting
        @setting ||= Esse::IndexSetting.new(self)
      end
    end

    extend ClassMethods
  end
end
