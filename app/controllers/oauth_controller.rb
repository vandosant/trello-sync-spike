class OauthController < ApplicationController

  before_action do
    @client = Google::APIClient.new(
      :application_name => 'Trello Sync',
      :application_version => '1.0.0'
    )

    new_authorization = Signet::OAuth2::Client.new
    new_authorization.client_id = ENV["GOOGLE_CLIENT_ID"]
    new_authorization.client_secret = ENV["GOOGLE_CLIENT_SECRET"]
    new_authorization.authorization_uri = 'https://accounts.google.com/o/oauth2/auth'
    new_authorization.token_credential_uri = 'https://accounts.google.com/o/oauth2/token'
    new_authorization.redirect_uri = oauth_callback_url
    new_authorization.access_token = session[:access_token]
    new_authorization.refresh_token = session[:refresh_token]
    new_authorization.expires_in = session[:expires_in]
    new_authorization.issued_at = session[:issued_at]
    new_authorization.scope = 'https://www.googleapis.com/auth/calendar'

    @client.authorization = new_authorization
    @user_credentials = @client.authorization
    @calendar = @client.discovered_api('calendar', 'v3')
  end

  def index
    if @user_credentials.access_token
      result = @client.execute(
        :api_method => @calendar.events.list,
        :parameters => { 'calendarId' => ENV["GOOGLE_CALENDAR_ID"] }
      )

      render json: result.data.to_json
    else
      redirect_to '/oauth2authorize'
    end
  end

  def trello
    key = ENV["TRELLO_KEY"]
    board = ENV["TRELLO_BOARD"]
    token = ENV["TRELLO_TOKEN"]

    unless token
      redirect_to "https://trello.com/1/authorize?key=#{key}&name=Trello+Google+Calendar&expiration=never&response_type=token"
    else
      require 'open-uri'
      result = open("https://api.trello.com/1/board/#{board}?key=#{key}&token=#{token}")
      render text: result.read
    end
  end

  def create
    event = {
      'summary' => "Test Event",
      'location' => "Test location",
      'start' => { 'dateTime' => 10.minutes.from_now.to_datetime.rfc3339 },
      'end' => { 'dateTime' => 15.minutes.from_now.to_datetime.rfc3339 },
    }

    result = @client.execute(
      :api_method => @calendar.events.insert,
      :parameters => { 'calendarId' => ENV["GOOGLE_CALENDAR_ID"] },
      :body => event.to_json,
      :headers => { 'Content-Type' => 'application/json' }
    )

    render json: result.data.to_json
  end

  def authorize
    redirect_to @client.authorization.authorization_uri(
      :access_type => :offline
    ).to_s
  end

  def callback
    @user_credentials.code = params[:code] if params[:code]
    @user_credentials.fetch_access_token!

    session[:access_token] = @user_credentials.access_token
    session[:refresh_token] = @user_credentials.refresh_token
    session[:expires_in] = @user_credentials.expires_in
    session[:issued_at] = @user_credentials.issued_at

    redirect_to root_path
  end

end