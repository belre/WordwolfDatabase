
require 'sinatra'

# --- active_record
require 'active_record'

require_relative './statemachine_module'
require_relative './database_management'


require 'date'


class StateManagement_ArrangeRemarks
	include IFStateDialog
	
	attr_accessor :_internal_attributes
	
	def init_internal_attributes()
		return {}
	end
	
	
	def initialize(common_params)
		@_isend_preempt =false
		@_common_params = common_params
		@_proctype = nil
		
		self._internal_attributes = self.init_internal_attributes
	end
	
	"
	paraemterをロードするメソッド
	"
	def preempt(params)
		self._internal_attributes = self.init_internal_attributes
		
		@_isend_preempt =true
		@_proctype = params[:proctype]	
		
		if params["messageloader"] != nil then
			self._internal_attributes[:jsonmessageinfo] = params["messageloader"]
		end
	end
	
	"
	関数を実行する
	"
	def execute()
		
		
		
		if self._internal_attributes[:jsonmessageinfo] != nil then
			self._internal_attributes[:jsonmessageinfo].each do |jsonobj|
				
				File.open(jsonobj[:tempfile]) do |f|
					jsonparam = JSON.load(f)
					
					DatabaseQueryController.transact_arrangeremarks(@_common_params[:battle_id], @_common_params[:select_index], jsonparam)
				end
				
			end
			
			
			
		end
		
		
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		return :'/management/management_entry_arrangeremarks'
	end
	
	def getDataViewFromTables()
		dbdata = {}
		DatabaseQueryController.addToDbData_GameInfoOne(@_common_params[:battle_id], @_common_params[:select_index], dbdata)
		DatabaseQueryController.addToDbData_TalkMessage(@_common_params[:battle_id], @_common_params[:select_index], dbdata)
		DatabaseQueryController.addToDbData_TalkReply(@_common_params[:battle_id], @_common_params[:select_index], dbdata)
		
		
		return dbdata
	end
	
	"
	次の画面遷移の情報を与える。
	返値として次のオブジェクトを生成すること。
	"
	def getNextState(params)

		# 次状態決定
		if @_proctype == "selectgame" then
			@_nextstatus = StateManagement_SelectGame.new(@_common_params)
		else
			@_nextstatus = self
			#throw "Transition Error (ArrangeRemarks)"
		end
		
		params = @_common_params
		return [@_nextstatus, params]
	end
	
	
	
	def isPostRequest()
		return false;
	end
	
	def isDestroyed()
		return false
	end
end


