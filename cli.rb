# frozen_string_literal: true

require 'tty'
require 'uri'
require 'net/http'

# A CLI to register and view API keys for the Food Network API
module FoodNetworkCli
  puts File.open('greeting.txt').read

  # Handles Register and Login Actions
  class Action
    API_BASE_URL = 'http://localhost:3000'
    def initialize
      @email = nil
      @password = nil
      @password_confirmation = nil
      @complete = false
      @error = nil
      @prompt = TTY::Prompt.new
    end

    ###############
    #   ACTIONS   #
    ###############
    def register
      registration_form until @complete

      success = submit_registration
      puts
      if success
        puts "Created an account for #{@user[:email]}"
        create_key
      else
        puts @error
        nil
      end
    end

    ###############
    #    FORMS    #
    ###############
    def registration_form
      puts @error if @error
      @email = @prompt.ask('What is your email?')
      return email_error unless check_email

      @password = @prompt.mask('Please enter a password:')
      @password_confirmation = @prompt.mask('Please confirm your password:')

      return false unless check_password

      @complete = true
    end

    def create_key
      puts
      continue = @prompt.yes?('Would you like to create an API key for the Food Network API?')

      if continue
        puts
        @password = @prompt.mask('Please re-enter your password:')
        success = post_create_key
        puts success ? api_key_message(@api_key) : @error
      else
        puts 'Okay, then there is nothing left to do. Restart the program when you would like to login and create an API key.'
      end
    end

    ################
    #  SUBMISSION  #
    ################
    def submit_registration
      uri = URI("#{API_BASE_URL}/sign-up")
      res = Net::HTTP.post_form(uri, 'email' => @email, 'password' => @password)
      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body).to_h.transform_keys(&:to_sym)
        @user = data[:user].transform_keys(&:to_sym)
        reset_form
        true
      else
        @error = 'Unable to create an account. Please try again.'
        false
      end
    end

    def post_create_key
      uri = URI("#{API_BASE_URL}/api-keys")

      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: uri.scheme == 'https',
                      verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        request = Net::HTTP::Post.new uri.request_uri
        request.basic_auth @user[:email], @password

        res = http.request request

        if res.is_a?(Net::HTTPSuccess)
          data = JSON.parse(res.body)
          data.transform_keys!(&:to_sym)
          @api_key = data[:token]
          true
        else
          @error = 'Unable to create an API key. Please try again.'
          false
        end
      end
    end

    ################
    #    CHECKS    #
    ################
    def check_email
      @email =~ email_regex
    end

    def check_password
      return nil_password_error if @password.nil? || @password_confirmation.nil?
      return password_confirm_error if @password != @password_confirmation

      true
    end

    def email_regex
      /\A[\w+\-.]+@[a-z\d-]+(\.[a-z]+)*\.[a-z]+\z/i
    end

    def reset_form
      @email = nil
      @password = nil
      @password_confirmation = nil
    end

    ################
    #    ERRORS    #
    ################
    def email_error
      @error = 'Please enter a valid email'
      false
    end

    def nil_password_error
      @error = 'Password cannot be blank'
      false
    end

    def password_confirm_error
      @error = 'Password and confirmation did not match.'
      false
    end

    def api_key_message(key)
      <<-EOM
      Your Food Network API key: #{key}
      Keep it safe!

      If you need to view your API key again or get a new one, you can login using this program.
      Thanks for checking out my project! -Parker
      EOM
    end
  end

  # initial prompt
  prompt = TTY::Prompt.new
  puts
  action = prompt.select('What would you like to do?', ['register for API key', 'login to manage API keys'])

  case action
  when 'register for API key'
    puts
    Action.new.register
  when 'login to view API key'
    puts
    puts 'logging in'
  end
end
