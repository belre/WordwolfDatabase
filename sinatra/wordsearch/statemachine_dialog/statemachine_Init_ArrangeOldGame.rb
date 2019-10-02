
require 'sinatra'

# --- active_record
require 'active_record'

require_relative './statemachine_module'
require_relative './database_management'


require 'date'



class StateManagement_Init_ArrangeOldGame
	include IFStateDialog
	
	def initialize()
		@_isend_preempt =false
	end
	
	"
	parameterをロードするメソッド
	"
	def preempt(params)
		@_iscreate_query = false
		@_localparams = {}
		
		p params
		
		@common_id = nil
		if params[:game_selector_id] != nil then
			p "------"
			p params[:game_selector_id]
			@_localparams[:battle_lastid] = params[:game_selector_id].to_i
		end
		
		@_isend_preempt =true
		
	end
	
	"
	関数を実行する
	"
	def execute()
		return nil
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		throw "Transition Error (Init/Arrange)"
	end
	
	def getDataViewFromTables()
		dbdata = {}
		DatabaseQueryController.addToDbData_GameInfoAll(dbdata)
		return dbdata
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