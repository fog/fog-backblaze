require 'json'

module Fog
  module Backblaze
    module JSONResponse

      attr_writer :json

      def raw_body
        @body
      end

      def json
        @json ||= ::JSON.parse(raw_body)
      end

      def assign_json_body!
        self.body = json
      end

      def json_response?
        headers['Content-Type'].start_with?("application/json")
      end

    end
  end
end
