require 'spec_helper'

describe 'S3 Bucket' do
  let(:bucket_name_prefix) { vars.bucket_name_prefix }
  let(:topic_name_prefix) { vars.topic_name_prefix }
  let(:region) { vars.region }
  let(:deployment_identifier) { vars.deployment_identifier }
  let(:trusted_principals) { vars.trusted_principals }

  let(:bucket_arn) { output_for(:harness, 'infrastructure_events_bucket_arn') }

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
    it { should exist }

    it 'has tags' do
      tags = s3_client.get_bucket_tagging({bucket: subject.name}).to_h

      expect(tags[:tag_set]).to(
          include({key: 'Component', value: 'common'}))
      expect(tags[:tag_set]).to(
          include({key: 'Name', value: subject.name}))
      expect(tags[:tag_set]).to(
          include({key: 'DeploymentIdentifier',
              value: deployment_identifier.to_s}))
    end

    it 'allows all access from the owning account' do
      policy_document = JSON.parse(subject.policy.policy.read)
      owning_account_statement =
          policy_document["Statement"].find do |statement|
            statement["Sid"] == "AllowEverythingForOwningAccount"
          end

      expect(owning_account_statement["Effect"]).to(eq("Allow"))
      expect(owning_account_statement["Resource"]).to(eq("#{bucket_arn}/*"))
      expect(owning_account_statement["Action"]).to(eq("s3:*"))
      expect(owning_account_statement["Principal"]["AWS"])
          .to(eq("arn:aws:iam::#{account.account}:root"))
    end

    it 'allows access to get and put objects from all trusted accounts' do
      policy_document = JSON.parse(subject.policy.policy.read)
      trusted_principal_arns =
          trusted_principals.map { |id| "arn:aws:iam::#{id}:root" }
      trusted_principals_statement =
          policy_document["Statement"].find do |statement|
            statement["Sid"] == "AllowGetAndPutFromTrustedAccounts"
          end

      expect(trusted_principals_statement["Effect"]).to(eq("Allow"))
      expect(trusted_principals_statement["Resource"]).to(eq("#{bucket_arn}/*"))
      expect(trusted_principals_statement["Action"]).to(contain_exactly(
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
      ))
      expect(trusted_principals_statement["Principal"]["AWS"])
          .to(contain_exactly(*trusted_principal_arns))
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
      expect(output_for(:harness, 'infrastructure_events_bucket'))
          .to(eq(subject.name))
    end
  end
end