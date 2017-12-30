Terraform AWS Infrastructure Events
===================================

[![CircleCI](https://circleci.com/gh/infrablocks/terraform-aws-infrastructure-events.svg?style=svg)](https://circleci.com/gh/infrablocks/terraform-aws-infrastructure-events)

A Terraform module allowing other modules to publish events about 
their activities.

Usage
-----

To use the module, include something like the following in your terraform 
configuration:

```hcl-terraform
module "infrastructure-events" {
  source = "infrablocks/infrastructure-events/aws"
  version = "0.1.8"
  
  region = "eu-west-2"
  
  deployment_identifier = "1a32db46"
  
  bucket_name_prefix = "infra-events-bucket"
  topic_name_prefix = "infra-events-topic"
}
```


### Inputs

| Name                        | Description                                          | Default | Required |
|-----------------------------|------------------------------------------------------|:-------:|:--------:|
| region                      | The region into which to deploy the bucket and topic | -       | yes      |
| deployment_identifier       | An identifier for this instantiation                 | -       | yes      |
| bucket_name_prefix          | The prefix to use for the bucket name                | -       | yes      |
| topic_name_prefix           | The prefix to use for the topic name                 | -       | yes      |


### Outputs

| Name                            | Description            |
|---------------------------------|------------------------|
| infrastructure_events_bucket    | The name of the bucket |
| infrastructure_events_topic_arn | The ARN of the topic   |


Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed 
on your development machine:

* Ruby (2.3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 2.3.1
rbenv rehash
rbenv local 2.3.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

To provision module infrastructure, run tests and then destroy that 
infrastructure, execute:

```bash
./go
```

To provision the module contents:

```bash
./go deployment:harness:provision[<deployment_identifier>]
```

To destroy the module contents:

```bash
./go deployment:harness:destroy[<deployment_identifier>]
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at 
https://github.com/tobyclemson/terraform-aws-infrastructure-events. This project 
is intended to be a safe, welcoming space for collaboration, and contributors 
are expected to adhere to the 
[Contributor Covenant](http://contributor-covenant.org) code of conduct.


License
-------

The library is available as open source under the terms of the 
[MIT License](http://opensource.org/licenses/MIT).
