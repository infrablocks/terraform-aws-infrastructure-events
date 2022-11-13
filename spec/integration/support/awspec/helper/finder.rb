# frozen_string_literal: true

require 'aws-sdk'

module Awspec
  module Helper
    module Finder
      def sns_client
        @sns_client ||= Aws::SNS::Client.new
      end
    end
  end
end
