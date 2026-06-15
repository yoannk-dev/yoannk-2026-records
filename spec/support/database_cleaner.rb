require "database_cleaner/active_record"

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    # System specs run the app via Capybara (potentially in a separate thread/connection),
    # so data must be committed before the request is made — use truncation to guarantee
    # visibility across connections. All other spec types share a connection and can use
    # the faster transaction strategy.
    DatabaseCleaner.strategy = example.metadata[:type] == :system ? :truncation : :transaction
    DatabaseCleaner.cleaning { example.run }
  end

  # Truncation only cleans AFTER each example; if a previous example left dirty data
  # (e.g. after a crash or early failure), the next example would start with stale rows.
  # This pre-flight clean guarantees a fresh state regardless of prior cleanup outcome.
  config.before(:each, type: :system) do
    DatabaseCleaner.clean_with(:truncation)
  end
end
