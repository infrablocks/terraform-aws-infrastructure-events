# frozen_string_literal: true

require 'spec_helper'

describe 'full' do
  let(:bucket_name_prefix) do
    var(role: :root, name: 'bucket_name_prefix')
  end
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
  let(:topic_name_prefix) do
    var(role: :full, name: 'topic_name_prefix')
  end
  let(:region) do
    var(role: :full, name: 'region')
  end
  let(:deployment_identifier) do
    var(role: :full, name: 'deployment_identifier')
  end
  let(:trusted_principals) do
    var(role: :full, name: 'trusted_principals')
  end

  let(:bucket_arn) do
    output(role: :full, name: 'infrastructure_events_bucket_arn')
  end

  before(:context) do
    apply(role: :full)
  end

  after(:context) do
    destroy(
      role: :full,
      only_if: -> { !ENV['FORCE_DESTROY'].nil? || ENV['SEED'].nil? }
    )
  end

  describe 'S3 bucket' do
    subject(:infrastructure_events_bucket) do
      s3_bucket("#{bucket_name_prefix}-#{region}-#{deployment_identifier}")
    end

    it { is_expected.to exist }

    # rubocop:disable RSpec/MultipleExpectations
    it 'has tags' do
      tags = s3_client.get_bucket_tagging(
        bucket: infrastructure_events_bucket.name
      ).to_h

      expect(tags[:tag_set]).to(
        include({ key: 'Component', value: 'common' })
      )
      expect(tags[:tag_set]).to(
        include({ key: 'Name', value: infrastructure_events_bucket.name })
      )
      expect(tags[:tag_set]).to(
        include({ key: 'DeploymentIdentifier',
                  value: deployment_identifier.to_s })
      )
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows all access from the owning account' do
      policy_document =
        JSON.parse(infrastructure_events_bucket.policy.policy.read)
      owning_account_statement =
        policy_document['Statement'].find do |statement|
          statement['Sid'] == 'AllowEverythingForOwningAccount'
        end

      expect(owning_account_statement['Effect']).to(eq('Allow'))
      expect(owning_account_statement['Resource']).to(eq("#{bucket_arn}/*"))
      expect(owning_account_statement['Action']).to(eq('s3:*'))
      expect(owning_account_statement['Principal']['AWS'])
        .to(eq("arn:aws:iam::#{account.account}:root"))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows access to get and put objects from all trusted accounts' do
      policy_document =
        JSON.parse(infrastructure_events_bucket.policy.policy.read)
      trusted_principal_arns =
        trusted_principals.map { |id| "arn:aws:iam::#{id}:root" }
      trusted_principals_statement =
        policy_document['Statement'].find do |statement|
          statement['Sid'] == 'AllowGetAndPutFromTrustedAccounts'
        end

      expect(trusted_principals_statement['Effect']).to(eq('Allow'))
      expect(trusted_principals_statement['Resource']).to(eq("#{bucket_arn}/*"))
      expect(trusted_principals_statement['Action'])
        .to(contain_exactly(
              's3:GetObject',
              's3:PutObject',
              's3:DeleteObject',
              's3:GetObjectVersion',
              's3:DeleteObjectVersion',
              's3:GetObjectAcl',
              's3:PutObjectAcl',
              's3:GetObjectVersionAcl',
              's3:PutObjectVersionAcl',
              's3:GetObjectTagging',
              's3:PutObjectTagging',
              's3:DeleteObjectTagging',
              's3:GetObjectVersionTagging',
              's3:PutObjectVersionTagging',
              's3:DeleteObjectVersionTagging'
            ))
      expect(trusted_principals_statement['Principal']['AWS'])
        .to(match_array(trusted_principal_arns))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'publishes object created and removed to the infrastructure ' \
       'events topic' do
      notifications = s3_client.get_bucket_notification_configuration(
        { bucket: infrastructure_events_bucket.name }
      )
      topic_configuration = notifications.topic_configurations[0]

      expect(topic_configuration.topic_arn).to(eq(topic.attributes['TopicArn']))
      expect(topic_configuration.events)
        .to(contain_exactly('s3:ObjectCreated:*', 's3:ObjectRemoved:*'))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe 'topic' do
    subject(:infrastructure_events_topic) do
      topics.find do |topic|
        topic.attributes['DisplayName'] ==
          "#{topic_name_prefix}-#{region}-#{deployment_identifier}"
      end
    end

    let(:bucket) do
      s3_bucket("#{bucket_name_prefix}-#{region}-#{deployment_identifier}")
    end

    it { is_expected.not_to be_nil }

    # rubocop:disable RSpec/MultipleExpectations
    it 'allows publishing from the infrastructure events bucket' do
      policy = JSON.parse(infrastructure_events_topic.attributes['Policy'])
      statement = policy['Statement'][0]

      expect(statement['Effect']).to eq('Allow')
      expect(statement['Principal']['Service']).to eq('s3.amazonaws.com')
      expect(statement['Action']).to eq('SNS:Publish')
      expect(statement['Resource'])
        .to(eq(infrastructure_events_topic.attributes['TopicArn']))
      expect(statement['Condition']['ArnLike']['aws:SourceArn'])
        .to(eq("arn:aws:s3:::#{bucket.name}"))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
