
require 'sinatra'

# --- active_record
require 'active_record'

require_relative './statemachine_module'
require_relative './database_management'


require 'date'




class StateManagement_Destroy
	include IFStateDialog
	
	def initialize()
		@_isend_preempt = true
	end
	
	"
	paraemterをロードするメソッド
	"
	def preempt(params)
		throw "Transition Error (Destroy)"
	end
	
	"
	関数を実行する
	"
	def execute()
		throw "Transition Error (Destroy)"
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		throw "Transition Error (Destroy)"
	end
	
	def getDataViewFromTables()
		return nil
	end
	
	
	"
	次の画面遷移の情報を与える。
	返値として次のオブジェクトを生成すること。
	"
	def getNextState(params)
		@statedialog_management = StateManagement_Init.new	
		return [@statedialog_management, nil]
	end
	
	
	def isPostRequest()
		return false;
	end
	
	def isDestroyed()
		return true
	end
end
