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

get '/root/:notebook/:page' do |notebook, page|	
	@rz = Rootz::Root.new(notebook, page)
	@rz.parse

	haml :index	
end

get '*' do
	@settings = JSON.parse File.read("#{File.expand_path "..", __FILE__}/settings")
	notebook = @settings["default_notebook"]
	redirect to("/root/#{notebook}/1")
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
