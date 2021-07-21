#!/usr/bin/env bash

export BUNDLER_VERSION="2.2.22"  ##  Matching Gemfile, version supported by deployment target
rbenv install -s "2.7.3"         ##  Matching Gemfile, version supported by deployment target
gem update --system
gem install bundler -v "$BUNDLER_VERSION"
bundle cache  ##  uses BUNDLER_VERSION
bundle binstubs --all  ##  --all to avoid "Sorry, Bundler can only be run via RubyGems"
bin/bundle update  ## binstub invokes 2.2.24 and fails
