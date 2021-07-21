# `bundle binstubs --all` generates a binstub for `bundle` that invokes the wrong version of Bundler

Reproduction of [rubygems issue #4774](https://github.com/rubygems/rubygems/issues/4774)

Found on macOS 11.4 with homebrew rbenv 1.1.2, using ruby 2.7.3 and bundler 2.2.22

The generated binstub correctly finds the bundler version from the Gemfile, but then intentionally approximates the requirement, then resolves that requirement to an incompatible newer version of bundler

This reproduction requires `bash` and `rbenv`.  Run `runme.sh` to generate the binstub and demonstrate the problem.

I've included a corrected binstub at [bin/bundle_corrected](bin/bundle_corrected), but didn't look in to how the binstub is generated to propose a patch for the generator

## Bullet points from [guide](https://github.com/rubygems/rubygems/blob/master/bundler/doc/contributing/ISSUES.md#user-content-reporting-unresolved-problems):

* What I'm trying to accomplish

Use binstubs to get project-specific versions of everything, while using the versions of ruby and bundler supported by my deployment target

* The command you ran

See `runme.sh`

* What you expected to happen

I expected the binstub for `bundle` to invoke the version given in the `Gemfile` and execute the commands

* What actually happened

The binstub for `bundle` invoked a different version and failed with the error below

* The exception backtrace(s), if any

Error messages of the form
```
Bundler could not find compatible versions for gem "bundler":
  In Gemfile:
    bundler (= 2.2.22)

  Current Bundler version:
    bundler (2.2.24)

Your bundle requires a different version of Bundler than the one you're running.
Install the necessary version with `gem install bundler:2.2.22` and rerun bundler using `bundle _2.2.22_ update`
```
repeating with `_2.2.22_` gives the error
```
Could not find command "_2.2.22_".
```

* Everything output by running bundle env

## Environment

```
Bundler       2.2.24
  Platforms   ruby, x86_64-darwin-20
Ruby          2.7.3p183 (2021-04-05 revision 6847ee089d7655b2a0eea4fee3133aeacd4cc7cc) [x86_64-darwin20]
  Full Path   /Users/sxs5ith/.rbenv/versions/2.7.3/bin/ruby
  Config Dir  /Users/sxs5ith/.rbenv/versions/2.7.3/etc
RubyGems      3.2.24
  Gem Home    /Users/sxs5ith/.rbenv/versions/2.7.3/lib/ruby/gems/2.7.0
  Gem Path    /Users/sxs5ith/.gem/ruby/2.7.0:/Users/sxs5ith/.rbenv/versions/2.7.3/lib/ruby/gems/2.7.0
  User Home   /Users/sxs5ith
  User Path   /Users/sxs5ith/.gem/ruby/2.7.0
  Bin Dir     /Users/sxs5ith/.rbenv/versions/2.7.3/bin
Tools         
  Git         2.24.3 (Apple Git-128)
  RVM         not installed
  rbenv       rbenv 1.1.2
  chruby      not installed
```

## Bundler Build Metadata

```
Built At          2021-07-15
Git SHA           d78b1ee235
Released Version  true
```

## Bundler settings

```
cache_all
  Set for your local app (/Users/sxs5ith/Documents/Repositories/BugReport-Bundler-Binstub/.bundle/config): true
cache_all_platforms
  Set for your local app (/Users/sxs5ith/Documents/Repositories/BugReport-Bundler-Binstub/.bundle/config): true
gemfile
  Set via BUNDLE_GEMFILE: "/Users/sxs5ith/Documents/Repositories/BugReport-Bundler-Binstub/Gemfile"
path
  Set for your local app (/Users/sxs5ith/Documents/Repositories/BugReport-Bundler-Binstub/.bundle/config): "vendor/bundle"
```

## Gemfile

### Gemfile

```ruby
ruby "2.7.3"

source "https://rubygems.org/"

gem "bundler", "2.2.22"
```

### Gemfile.lock

```
GEM
  remote: https://rubygems.org/
  specs:

PLATFORMS
  x86_64-darwin-20

DEPENDENCIES
  bundler (= 2.2.22)

RUBY VERSION
   ruby 2.7.3p183

BUNDLED WITH
   2.2.22
```

## Extra notes

These are not necessary to fix this bug, but struck me as possibly related

* `bundle cache` neither caches nor installs `bundler` in `./vendor`
* `bundle binstubs --all --standalone` generates the same `bundle` binstub as `bundle binstubs --all`
* Reliably/automatically generating binstubs for Bundler requires `bundle binstubs --all`, it sometimes refuses to generate binstubs just for Bundler when running `bundle binstubs bundler`, giving an error like `Sorry, Bundler can only be run via RubyGems.`
