require "test_helper"
require "rails"
require "rails_refdocs/railtie"

class RailtieTest < Minitest::Test
  class Application < Rails::Application
    config.eager_load = false
    config.root = File.expand_path("../tmp/railtie", __dir__)
    config.logger = Logger.new(nil)
  end

  def test_adds_the_refdocs_rake_tasks
    Application.initialize! unless Application.initialized?
    Application.load_tasks
    %w[refdocs:update refdocs:check refdocs:locked refdocs:link].each do |task|
      assert Rake::Task.task_defined?(task), "#{task} is not defined"
    end
  end
end
