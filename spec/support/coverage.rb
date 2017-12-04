if ENV['ENV'] == 'coverage'

  require 'simplecov'

  # simple coverage configuration
  SimpleCov.start do
    add_filter %r{^/spec/*.spec.rb}
    command_name 'rspec'
    minimum_coverage 90
    coverage_dir 'docs/coverage'
  end
end
