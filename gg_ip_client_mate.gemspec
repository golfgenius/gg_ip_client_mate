# frozen_string_literal: true

require_relative 'lib/gg_ip_client_mate/version'

Gem::Specification.new do |spec|
  spec.name = 'gg_ip_client_mate'
  spec.version = GgIpClientMate::VERSION
  spec.authors = ['Golf Genius Team']
  spec.email = ['support@golfgenius.com']

  spec.summary = 'Golf Genius Identity Provider Client intergration helper'
  spec.homepage = 'https://github.com/golfgenius/gg_ip_client_mate'
  spec.required_ruby_version = '>= 3.2.2'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/golfgenius/gg_ip_client_mate'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency('openid_connect', '~> 2.2.0')

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
