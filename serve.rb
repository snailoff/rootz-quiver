require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'rouge'
require 'logger'
require 'pathname'
require 'json'

require './rootz'
require './version'

set :show_exceptions, :after_handler

configure do
	enable :reloader
end

get '/root/*' do |path|	

	@rz = Rootz::Root.new path
	@rz.parse

	haml :index
	
end

get '*' do
  redirect to('/root/')
end

error Rootz::InvalidPathError do
	logger.error "#{env['sinatra.error'].message}"
	logger.error "#{env['sinatra.error'].object.redirect_url}"
	redirect to env['sinatra.error'].object.redirect_url
end

error Rootz::InvalidConfigError do
	logger.error "#{env['sinatra.error'].message}"
	haml :error
end
