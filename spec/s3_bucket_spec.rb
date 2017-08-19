require 'spec_helper'

describe 'S3 Bucket' do
  let(:bucket_name_prefix) { vars.bucket_name_prefix }
  let(:topic_name_prefix) { vars.topic_name_prefix }
  let(:region) { vars.region }
  let(:deployment_identifier) { vars.deployment_identifier }

  subject {
    s3_bucket("#{bucket_name_prefix}-#{region}-#{deployment_identifier}")
  }

  let(:topics) do
    sns_client.list_topics.data[:topics].map do |topic|
      sns_client.get_topic_attributes(topic_arn: topic[:topic_arn])
    end
  end

  let(:topic) do
    topics.find do |topic|
      topic.attributes['DisplayName'] ==
          "#{topic_name_prefix}-#{region}-#{deployment_identifier}"
    end
  end

  context 'bucket' do
    it {should exist}

    it 'has tags' do
      tags = s3_client.get_bucket_tagging({bucket: subject.name}).to_h

      expect(tags[:tag_set]).to(
          include({key: 'Component', value: 'common'}))
      expect(tags[:tag_set]).to(
          include({key: 'Name', value: subject.name}))
      expect(tags[:tag_set]).to(
          include({key: 'DeploymentIdentifier',
                   value: deployment_identifier}))
    end
  end

  context 'event notifications' do
    it 'publishes object created and removed to the infrastructure events topic' do
      notifications = s3_client.get_bucket_notification_configuration(
          {bucket: subject.name})
      topic_configuration = notifications.topic_configurations[0]

      expect(topic_configuration.topic_arn).to(eq(topic.attributes['TopicArn']))
      expect(topic_configuration.events)
          .to(contain_exactly('s3:ObjectCreated:*', 's3:ObjectRemoved:*'))
    end
  end

  context 'outputs' do
    it 'outputs the infrastructure events bucket name' do
      expect(output_with_name('infrastructure_events_bucket'))
          .to(eq(subject.name))
    end
  end
end