require 'spec_helper'
require 'json'
require 'pp'

describe 'Topic' do
  let(:topic_name_prefix) { vars.topic_name_prefix }
  let(:bucket_name_prefix) { vars.bucket_name_prefix }
  let(:region) { vars.region }
  let(:deployment_identifier) { vars.deployment_identifier }

  let(:topics) do
    sns_client.list_topics.data[:topics].map do |topic|
      sns_client.get_topic_attributes(topic_arn: topic[:topic_arn])
    end
  end

  let(:bucket) do
    s3_bucket("#{bucket_name_prefix}-#{region}-#{deployment_identifier}")
  end

  subject do
    topics.find do |topic|
      topic.attributes['DisplayName'] ==
          "#{topic_name_prefix}-#{region}-#{deployment_identifier}"
    end
  end

  context 'topic' do
    it { should_not be_nil }

    it 'allows publishing from the infrastructure events bucket' do
      policy = JSON.parse(subject.attributes['Policy'])
      statement = policy['Statement'][0]

      expect(statement['Effect']).to eq('Allow')
      expect(statement['Principal']['Service']).to eq('s3.amazonaws.com')
      expect(statement['Action']).to eq('SNS:Publish')
      expect(statement['Resource']).to eq(subject.attributes['TopicArn'])
      expect(statement['Condition']['ArnLike']['aws:SourceArn'])
          .to(eq("arn:aws:s3:::#{bucket.name}"))
    end
  end

  context 'outputs' do
    it 'outputs the infrastructure events topic ARN' do
      expect(output_for(:harness, 'infrastructure_events_topic_arn'))
          .to(eq(subject.attributes['TopicArn']))
    end
  end
end