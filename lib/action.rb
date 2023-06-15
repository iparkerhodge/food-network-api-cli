# frozen_string_literal: true

module FoodNetworkCli
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
      puts "email: #{@email}"
      puts "password #{@password}"

      res = submit_registration
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

    ################
    #  SUBMISSION  #
    ################
    def submit_registration
      uri = URI("#{API_BASE_URL}/sign-up")
      data = { 'email': @email, 'password': @password }
      res = Net::HTTP.post_form(uri, { user: data })
      puts res.body if res.is_a?(Net::HTTPSuccess)
      res.body
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
  end
end
