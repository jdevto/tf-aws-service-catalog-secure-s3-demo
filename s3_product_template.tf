locals {
  # CloudFormation template for the secure S3 bucket product
  cloudformation_template = <<-EOT
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Secure S3 bucket with encryption, versioning, lifecycle management, and optional logging'

Parameters:
  BucketNamePrefix:
    Type: String
    Description: 'Prefix for the S3 bucket name (will append random suffix)'
    MaxLength: 37
    AllowedPattern: '^[a-z0-9-]+$'

  EnableLogging:
    Type: String
    Default: 'false'
    Description: 'Enable access logging for this bucket'
    AllowedValues:
      - 'true'
      - 'false'

  LifecycleTransitionIADays:
    Type: Number
    Default: 30
    Description: 'Number of days before transitioning objects to Standard-IA storage class'

  LifecycleTransitionGlacierDays:
    Type: Number
    Default: 90
    Description: 'Number of days before transitioning objects to Glacier storage class'

  LifecycleExpirationDays:
    Type: Number
    Default: 90
    Description: 'Number of days before expiring old object versions'

  Application:
    Type: String
    Default: 'Unknown'
    Description: 'Application name for tagging'

  Environment:
    Type: String
    Default: 'demo'
    Description: 'Environment for tagging'

  Owner:
    Type: String
    Default: 'terraform'
    Description: 'Owner of the resource for tagging'

Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '$${BucketNamePrefix}-bucket-$${AWS::AccountId}-$${AWS::Region}'
      VersioningConfiguration:
        Status: Enabled
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      LifecycleConfiguration:
        Rules:
          - Id: TransitionToIA
            Status: Enabled
            Transitions:
              - TransitionInDays: !Ref LifecycleTransitionIADays
                StorageClass: STANDARD_IA
          - Id: TransitionToGlacier
            Status: Enabled
            Transitions:
              - TransitionInDays: !Ref LifecycleTransitionGlacierDays
                StorageClass: GLACIER
          - Id: ExpireOldVersions
            Status: Enabled
            NoncurrentVersionExpirationInDays: !Ref LifecycleExpirationDays
      LoggingConfiguration: !If
        - EnableLoggingCondition
        - DestBucketName: !Ref LoggingBucket
          LogFilePrefix: access-logs/
        - !Ref AWS::NoValue
      Tags:
        - Key: Name
          Value: !Sub '$${BucketNamePrefix}-bucket'
        - Key: Application
          Value: !Ref Application
        - Key: Environment
          Value: !Ref Environment
        - Key: Owner
          Value: !Ref Owner
        - Key: ManagedBy
          Value: aws-service-catalog

  LoggingBucket:
    Type: AWS::S3::Bucket
    Condition: EnableLoggingCondition
    Properties:
      BucketName: !Sub '$${BucketNamePrefix}-logs-$${AWS::AccountId}-$${AWS::Region}'
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      LifecycleConfiguration:
        Rules:
          - Id: DeleteOldLogs
            Status: Enabled
            ExpirationInDays: 365
      Tags:
        - Key: Name
          Value: !Sub '$${BucketNamePrefix}-logs'
        - Key: Application
          Value: !Ref Application
        - Key: Environment
          Value: !Ref Environment
        - Key: Owner
          Value: !Ref Owner
        - Key: ManagedBy
          Value: aws-service-catalog

  S3BucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref S3Bucket
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Sid: DenyInsecureConnections
            Effect: Deny
            Principal: '*'
            Action: s3:*
            Resource:
              - !Sub 'arn:aws:s3:::$${S3Bucket}/*'
              - !Sub 'arn:aws:s3:::$${S3Bucket}'
            Condition:
              Bool:
                aws:SecureTransport: 'false'

  LoggingBucketPolicy:
    Type: AWS::S3::BucketPolicy
    Condition: EnableLoggingCondition
    Properties:
      Bucket: !Ref LoggingBucket
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Sid: DenyInsecureConnections
            Effect: Deny
            Principal: '*'
            Action: s3:*
            Resource:
              - !Sub 'arn:aws:s3:::$${LoggingBucket}/*'
              - !Sub 'arn:aws:s3:::$${LoggingBucket}'
            Condition:
              Bool:
                aws:SecureTransport: 'false'

Conditions:
  EnableLoggingCondition: !Equals [!Ref EnableLogging, 'true']

Outputs:
  BucketName:
    Description: 'Name of the created S3 bucket'
    Value: !Ref S3Bucket

  BucketArn:
    Description: 'ARN of the created S3 bucket'
    Value: !GetAtt S3Bucket.Arn

  LoggingBucketName:
    Condition: EnableLoggingCondition
    Description: 'Name of the logging bucket'
    Value: !Ref LoggingBucket
EOT
}
