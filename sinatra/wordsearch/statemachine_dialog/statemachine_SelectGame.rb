
require 'sinatra'

# --- active_record
require 'active_record'

require_relative './statemachine_module'
require_relative './database_management'

require 'date'




class StateManagement_SelectGame
	include IFStateDialog
	
	def initialize(common_params)
		@_isend_preempt =false
		@_common_params = common_params
		@_proctype = nil
		@_select_index = nil
	end
	
	"
	paraemterをロードするメソッド
	"
	def preempt(params)
		@_isend_preempt =true
		@_proctype = params[:proctype]
		@_select_index = params[:selector].to_i
	end
	
	"
	関数を実行する
	"
	def execute()
		
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		return :'/management/management_entry_selectgame'
	end
	
	def getDataViewFromTables()
		dbdata = {}
		DatabaseQueryController.addToDbData_GameInfo(@_common_params[:battle_id], dbdata)
		return dbdata
	end
	
	"
	次の画面遷移の情報を与える。
	返値として次のオブジェクトを生成すること。
	"
	def getNextState(params)
		# 次状態決定
		if @_proctype == "deletegame" then
			@_common_params[:select_index] = @_select_index
			@_nextstatus = StateManagement_DeleteGame.new(@_common_params)
		elsif @_proctype == "arrangegameinfo" then
			@_common_params[:select_index] = @_select_index
			@_nextstatus = StateManagement_ArrangeGameInfo.new(@_common_params)
		else
			throw "Transition Error (Select Game)"
		end
		
		params = @_common_params
		return [@_nextstatus, @_common_params]
	end
	
	
	def isPostRequest()
		return false;
	end
	
	def isDestroyed()
		return false
	end
end

class StateManagement_DeleteGame 
	include IFStateDialog
	
	def initialize(common_params)
		@_isend_preempt =false
		@_common_params = common_params
		@_proctype = nil
	end
	
	"
	paraemterをロードするメソッド
	"
	def preempt(params)
		@_isend_preempt =true
		@_proctype = params[:proctype]
	end
	
	"
	関数を実行する
	"
	def execute()
		# 次状態決定
		if @_proctype == "deletegame" then
			@_nextstatus = StateManagement_SelectGame.new(@_common_params)
		else
			throw "Transition Error (Delete Game)"
		end
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		return nil
	end
	
	def getDataViewFromTables()
		return nil
	end
	
	"
	次の画面遷移の情報を与える。
	返値として次のオブジェクトを生成すること。
	"
	def getNextState(params)
		params = @_common_params
		return [@_nextstatus, @_common_params]
	end
	
	
	def isPostRequest()
		return true;
	end
	
	def isDestroyed()
		return false
	end
end
