# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe 'topic' do
  let(:region) do
    var(role: :root, name: 'region')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:bucket_name_prefix) do
    var(role: :root, name: 'bucket_name_prefix')
  end
  let(:topic_name_prefix) do
    var(role: :root, name: 'topic_name_prefix')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a topic' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_sns_topic')
              .once)
    end

    it 'includes the topic name prefix in the topic name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_sns_topic')
              .with_attribute_value(
                :name, including(topic_name_prefix)
              ))
    end

    it 'includes the region in the topic name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_sns_topic')
              .with_attribute_value(
                :name, including(region)
              ))
    end

    it 'includes the deployment identifier in the topic name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_sns_topic')
              .with_attribute_value(
                :name, including(deployment_identifier)
              ))
    end

    it 'creates a topic policy' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_sns_topic_policy')
              .once)
    end

    it 'allows publishing from the infrastructure events bucket' do
      bucket_name =
        "#{bucket_name_prefix}-#{region}-#{deployment_identifier}"
      expect(@plan)
        .to(include_resource_creation(type: 'aws_sns_topic_policy')
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  Effect: 'Allow',
                  Principal: {
                    Service: 's3.amazonaws.com'
                  },
                  Action: 'SNS:Publish',
                  Condition: {
                    ArnLike: {
                      'aws:SourceArn': "arn:aws:s3:::#{bucket_name}"
                    }
                  }
                )
              ))
    end

    it 'outputs the infrastructure events topic ARN' do
      expect(@plan)
        .to(include_output_creation(name: 'infrastructure_events_topic_arn'))
    end
  end
end
