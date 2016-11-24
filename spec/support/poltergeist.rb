CAPYBARA_TIMEOUT_RETRIES = 6

# HACK: workaround for Capybara Poltergeist StatusFailErrors, simply retries
# from https://gist.github.com/afn/c04ccfe71d648763b306
RSpec.configure do |config|
  config.around(:each, type: :feature) do |ex|
    example = RSpec.current_example
    CAPYBARA_TIMEOUT_RETRIES.times do
      sleep 1
      example.instance_variable_set("@exception", nil)
      __init_memoized
      ex.run

      puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
      puts "poltergeist.rb: #{__LINE__},  method: #{__method__}"
      puts "example.exception = #{example.exception.ai}"
      puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"

      is_multiple_exception = example.exception.is_a?(RSpec::Core::MultipleExceptionError)

      break unless example.exception.is_a?(Capybara::Poltergeist::StatusFailError) ||
                   is_multiple_exception

      if is_multiple_exception
        m_exceptions = example.exception.all_exceptions
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
        puts "poltergeist.rb: #{__LINE__},  method: #{__method__}"
        puts "m_exceptions = #{m_exceptions.ai}"
        puts "m_exceptions.first.class < SystemCallError is "\
             "{m_exceptions.first.class < SystemCallError}"
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"

        idx = m_exceptions.find_index do |exception|
          exception.is_a?(Capybara::Poltergeist::StatusFailError) ||
            exception.class < SystemCallError
        end
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
        puts "poltergeist.rb: #{__LINE__},  method: #{__method__}"
        puts "idx = #{idx.ai}"
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"

        break unless idx
      end

      puts("\nCapybara::Poltergeist::StatusFailError at #{example.location}\n   Restarting phantomjs and retrying...")
      PhantomJSRestart.call
    end
  end
end

module PhantomJSRestart
  def self.call
    puts "-> Restarting phantomjs: iterating through capybara sessions..."
    session_pool = Capybara.send("session_pool")
    session_pool.each do |mode, session|
      msg = "  => #{mode} -- "
      driver = session.driver
      if driver.is_a?(Capybara::Poltergeist::Driver)
        msg += "restarting"
        driver.restart
      else
        msg += "not poltergeist: #{driver.class}"
      end
      puts msg
    end
  end
end
