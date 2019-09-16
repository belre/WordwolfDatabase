
require 'sinatra'

# --- active_record
require 'active_record'

require_relative './statemachine_module'
require_relative './database_management'


require 'date'


class StateManagement_ArrangeRemarks
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
		if @_proctype == "selectgame" then
			@_nextstatus = StateManagement_SelectGame.new(@_common_params)
		else
			throw "Transition Error (ArrangeRemarks)"
		end
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		return :'/management/management_entry_arrangeremarks'
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
		return false;
	end
	
	def isDestroyed()
		return false
	end
end


