#!/usr/bin/env bash

expected_ruby_version="2.7.3"
expected_bundle_version="2.2.24"
intended_bundle_version="2.2.22"

export BUNDLER_VERSION="$intended_bundle_version"  ##  Set default version for bundle command when multiple versions are installed


echo " --- --- Cleaning up from previous runs"

echo " --- Uninstalling old versions of system gems"
gem cleanup  ##  removes intended_bundle_version

echo " --- Removing bundle installation and cache"
rm -rf vendor

echo " --- Removing binstub"
rm bin/bundle

echo " --- Removing lockfile"
rm Gemfile.lock


echo " --- --- Attempting to reproduce bug"

echo " --- Ensuring ruby version"
rbenv install -s

echo " --- Confirming ruby version"
ruby_version=`ruby --version | cut -d " " -f 2`
ruby_match="${ruby_version#$expected_ruby_version}"  ##  See https://stackoverflow.com/a/37073155/776723
if [ "$ruby_match" == "$ruby_version" ]; then
	echo "!!! Unexpected result: ruby version is ${ruby_version} (expected ${expected_ruby_version})"
else
	echo "Expected result: ruby version is ${ruby_version}"
fi

echo " --- Ensuring latest gem command"
gem update --system

echo " --- Confirming default bundler version"
bundle_version_line=`bundle --version`  ##  Would use BUNDLER_VERSION, but it's not installed yet
bundle_version="${bundle_version_line#Bundler version }"
if [ "$bundle_version" != "$expected_bundle_version" ]; then
	echo "!!! Unexpected result: default bundler version is ${bundle_version} (expected ${expected_bundle_version})"
else
	echo "Expected result: default bundler version is ${bundle_version}"
fi

echo " --- Installing bundler version"
gem install bundler -v "$intended_bundle_version"

echo " --- Confirming installed bundler version"
bundle_version_line=`bundle --version`  ##  uses BUNDLER_VERSION
bundle_version="${bundle_version_line#Bundler version }"
if [ "$bundle_version" != "$intended_bundle_version" ]; then
	echo "!!! Unexpected result: installed bundler version is \"${bundle_version}\" (expected ${intended_bundle_version})"
	gem list bundle
else
	echo "Expected result: installed bundler version is ${bundle_version}"
fi

echo " --- Installing & caching dependencies"
bundle cache  ##  uses BUNDLER_VERSION

echo " --- Confirming bundled bundler version"
bundle_version_line=`bundle exec bundle --version`
bundle_version="${bundle_version_line#Bundler version }"
if [ "$bundle_version" != "$intended_bundle_version" ]; then
	echo "!!! Unexpected result: bundled bundler version is ${bundle_version} (expected ${intended_bundle_version})"
else
	echo "Expected result: bundled bundler version is ${bundle_version}"
fi

echo " --- Generating binstubs"
bundle binstubs --all  ##  `bundle binstubs bundler` sometimes fails with "Sorry, Bundler can only be run via RubyGems", but `bundle binstubs --all` always generates a binstub for bundle
if [ -f "bin/bundle" ]; then
	echo "Expected result: bin/bundle is a file; `ls -al bin/bundle`"
else
	echo "!!! Unexpected result: bin/bundle is not a file; `ls -al bin/bundle 2>&1`"
fi

echo " --- Confirming binstub bundler version"
bundle_version_line=`bin/bundle --version`
bundle_version="${bundle_version_line#Bundler version }"
if [ "$bundle_version" == "$expected_bundle_version" ]; then
	echo "!!! BUG CONFIRMED: binstub bundle version is ruby default ${expected_bundle_version} rather than older ${intended_bundle_version} in the Gemfile"
	echo " --- Demonstrating unusability"
	bin/bundle update
	echo " --- Demonstrating failure with _${intended_bundle_version}_"
	bin/bundle "_${intended_bundle_version}_" update
	echo " --- Annotated output from verbosified binstub:"
	bin/bundle_verbose --version
	echo " --- Confirming corrected binstub bundler version"
	bundle_version_line=`bin/bundle_corrected --version`
	bundle_version="${bundle_version_line#Bundler version }"
	if [ "$bundle_version" != "$intended_bundle_version" ]; then
		echo "!!! Unexpected result: corrected binstub bundler version is \"${bundle_version}\" (expected ${intended_bundle_version})"
		gem list bundle
	else
		echo "Expected result: corrected binstub bundler version is ${bundle_version}"
	fi
	echo " --- Diff of binstub and corrected binstub"
	diff bin/bundle bin/bundle_corrected
elif [ "$bundle_version" == "$intended_bundle_version" ]; then
	echo "BUG FIXED: binstub bundle version is ${intended_bundle_version} from the Gemfile (not the expected ruby default ${expected_bundle_version})"
else
	echo "!!! Unexpected result: bundled bundler version is \"${bundle_version}\" (expected ${expected_bundle_version} to confirm the bug or ${intended_bundle_version} indicating the bug is fixed)"
fi
