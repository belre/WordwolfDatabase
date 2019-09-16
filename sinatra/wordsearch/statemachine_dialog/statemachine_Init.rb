
require 'sinatra'

# --- active_record
require 'active_record'

require_relative './statemachine_module'
require_relative './database_management'


require 'date'



class StateManagement_Init 
	include IFStateDialog
	
	def initialize()
		@_isend_preempt =false
	end
	
	"
	parameterをロードするメソッド
	"
	def preempt(params)
		@_iscreate_query = false
		@_localparams = nil
		
		if params[:proctype] == "creategame" then
			@_iscreate_query = true
			
			# 現在時刻の取得
			nowtime = DateTime.now
			str = (('%04d' % nowtime.year)+ "-"+ ('%02d' % (nowtime.month + 1))+ "-" + ('%02d' % nowtime.day) + "T" + 
			('%02d' % nowtime.hour) + ":" + ('%02d' % nowtime.min) + ":" + ('%02d' % nowtime.sec))
			
			@_localparams = {}
			@_localparams[:battle_host] = params[:battle_host]
			@_localparams[:battle_num_battle] = params[:battle_num_battle]
			@_localparams[:battle_starttime] = params[:battle_starttime]
			@_localparams[:battle_endtime] = params[:battle_endtime]
			@_localparams[:battle_createdate] = str
		else
			@_iscreate_query = false
		end
		
		@_isend_preempt =true
	end
	
	"
	関数を実行する
	"
	def execute()
		db_data = {}
		
		if( @_iscreate_query == true) then
			DatabaseQueryController.transact_entrybattle(@_localparams )
		end
		
		return db_data
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		throw "Transition Error (Init)"
	end
	
	def getDataViewFromTables()
		return nil
	end
	
	"
	次の画面遷移の情報を与える。
	返値として次のオブジェクトを生成すること。
	"
	def getNextState(params)
		common_params = {}
		common_params[:battle_id] = @_localparams[:battle_lastid]
		@statedialog_management = StateManagement_SelectGame.new(common_params)
		
		return [@statedialog_management, common_params]
	end
	
	
	def isPostRequest()
		return false;
	end
	
	def isDestroyed()
		return false
	end
end