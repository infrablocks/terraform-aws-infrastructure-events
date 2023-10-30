# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk'

describe 'S3 bucket' do
  let(:region) do
    var(role: :root, name: 'region')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:bucket_name_prefix) do
    var(role: :root, name: 'bucket_name_prefix')
  end
  let(:trusted_principals) do
    var(role: :root, name: 'trusted_principals')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root)
    end

    it 'creates a bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .once)
    end

    it 'includes the bucket name prefix in the bucket name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :bucket, including(bucket_name_prefix)
              ))
    end

    it 'includes the region in the bucket name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :bucket, including(region)
              ))
    end

    it 'includes the deployment identifier in the bucket name' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :bucket, including(deployment_identifier)
              ))
    end

    it 'includes the component and deployment identifier as tags ' \
       'on the bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: 'common',
                  DeploymentIdentifier: deployment_identifier
                )
              ))
    end

    it 'includes the bucket name as a tag on the bucket' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Name: including(bucket_name_prefix)
                          .and(including(region))
                          .and(including(deployment_identifier))
                )
              ))
    end

    it 'allows all access from the owning account' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  Sid: 'AllowEverythingForOwningAccount',
                  Effect: 'Allow',
                  Action: 's3:*',
                  Principal: {
                    AWS: '325795806661'
                  }
                )
              ))
    end

    it 'allows access to get and put objects from all trusted accounts' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket')
              .with_attribute_value(
                :policy,
                a_policy_with_statement(
                  Sid: 'AllowGetAndPutFromTrustedAccounts',
                  Effect: 'Allow',
                  Action: contain_exactly(
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
                  ),
                  Principal: a_hash_including(
                    AWS: match_array(trusted_principals)
                  )
                )
              ))
    end

    it 'creates a bucket notification' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_notification')
              .once)
    end

    it 'notifies on object created and removed' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_s3_bucket_notification')
              .with_attribute_value(
                [:topic, 0, :events],
                contain_exactly(
                  's3:ObjectCreated:*', 's3:ObjectRemoved:*'
                )
              ))
    end

    it 'outputs the infrastructure events bucket name' do
      expect(@plan)
        .to(include_output_creation(name: 'infrastructure_events_bucket'))
    end
  end
end
