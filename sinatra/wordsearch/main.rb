require 'sinatra'

# --- active_record
require 'active_record'

# --- CSRF
require 'rack/csrf'

require './statemachine_dialog/load_src'

enable :sessions

# --- Management関連の画面に関するオブジェクト --- #
#status_management = StatusManagement.new
statedialog_management = StateManagement_Init.new

configure do
	### Configure CSRF
	#use Rack::Session::Cookie, :secret => "sjkmfmklac"
	#use Rack::Csrf, :raise => true
	
	### Configure Database
	ActiveRecord::Base.configurations = YAML.load_file('database.yml')
	ActiveRecord::Base.establish_connection(:development)
	ActiveRecord::Base.logger = Logger.new("sql.log", 'daily')
	ActiveRecord::Base.pluralize_table_names = false
	
	
	### Management Object Initialization
	#status_management = StatusManagement.new
	statedialog_management = StateManagement_Init.new
	
	#class Contents < ActiveRecord::Base
	#end	
end
# --- CSRF

helpers do
	def csrf_token
		Rack::Csrf.csrf_token(env)
	end
	
	def csrf_tag
		Rack::Csrf.csrf_tag(env)
	end
end



#error Rack::Csrf::InvalidCsrfToken do
#	"CSRF exception!!"
#end

error 403 do
	"Access Forbidden"
end

get '/' do
	erb:index
end

post '/upload' do
	@mes = ""
	save_path = ""
	if params[:fileloader] != nil
		save_path ="./public/images/#{params[:fileloader][:filename]}"
		
		File.open(save_path, 'wb') do |f|
			f.write params[:fileloader][:tempfile].read
		end
		
		@mes = "Succeeded"
	else
		@mes = "failed"
	end
	
	@mes
end
	
get '/wordsearch/' do
	erb:wordsearch_menu
end


post '/wordsearch/management/link1' do	
	#contents = Contents.new
	#contents.name = "Otona"
	#contents.date = "2019-08-01";
	#contents.save
	#@testmessage = params[:val]
	
	redirect '/wordsearch/management/' 
end



get '/wordsearch/management/' do
	#@testdblist = Contents.all
	erb:'management/management_main'
end


get '/wordsearch/management/entrybattle' do
	p params[:entrymode]
	
	if params[:entrymode] == nil or params[:entrymode] == "arrange_oldbattle" then
		statedialog_management = StateManagement_Init_ArrangeOldGame.new
		@dbdataview = statedialog_management.getDataViewFromTables()
		erb:'management/management_arrange_oldgame_main'	
	elsif params[:entrymode] == "new" then
		statedialog_management = StateManagement_Init.new
		erb:'management/management_entry_main'
	else
		403
	end
end



post '/wordsearch/management/entrybattle/processing' do
	# - State Pattern (For Page Transition)- 
	# * input:current status(export erb or error page)
	# * other parameters: ...(params?)
	# * procedure : use params
	# * output: export erb or error page
	
	if statedialog_management.isDestroyed() == true then
		# destroy時は特定のPOSTの時のみページを再生成する。(ロックやエラーへの対策)
		statedialog_management = statedialog_management.getNextState()					
	end
	
	statedialog_management.preempt(params)
	statedialog_management.execute()
	nextobj = statedialog_management.getNextState(params)
	statedialog_management = nextobj[0]
	@params = nextobj[1]
	
	p "Selector" + params[:select_index].to_s
	
	@dbdataview = statedialog_management.getDataViewFromTables()
	
	if statedialog_management.getTemplatePage() != nil then
		erb(statedialog_management.getTemplatePage())
	elsif statedialog_management.isPostRequest() == true then
		call env.merge('PATH_INFO' => '/wordsearch/management/entrybattle/processing')
	end
		
end



delete '/wordsearch/management/del' do
	contents = Contents.all
	contents
		.where('name == ?', params[:guiparam])	
		.delete_all		
	
	redirect '/wordsearch/management/'
end	



