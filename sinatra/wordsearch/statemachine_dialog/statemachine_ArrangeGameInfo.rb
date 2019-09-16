
require 'sinatra'

# --- active_record
require 'active_record'

require_relative './statemachine_module'
require_relative './database_management'


require 'date'

require "securerandom"

class StateManagement_ArrangeGameInfo 
	include IFStateDialog
	
	attr_accessor :_form_attributes
	attr_accessor :_internal_attributes
	attr_accessor :_internal_thumbnail_upload
	
	def init_form_attributes()
		return { :issearchmode => false, :searchmode_valid => false, :searchmode_rule => nil, :searchmode_voterule => nil, :searchmode_comebackrule => nil,
			:searchmode_wolfnumber => 0, :playerinfo => nil, :state_playerinfo => false,
			:value_gamemaster => nil, :list_targetrules => nil}
	end
	
	def init_internal_attributes()
		return { :isend_preempt => false, :proctype => nil, :update_flag => false, :istransact_db_gameinfo => false, :thumbnail_info => nil,
				 :isget_gamerulesetting => false}
	end
	
	def initialize(common_params)
		@_common_params = common_params
		
		self._form_attributes = self.init_form_attributes
		self._internal_attributes = self.init_internal_attributes
	end

	"
	paraemterをロードするメソッド
	"
	def preempt(params)
		# 内部状態の初期化(Temporary扱いであるので、常に更新する)
		self._internal_attributes = self.init_internal_attributes
		self._internal_attributes[:isend_preempt] = true
		self._internal_attributes[:proctype] = params[:proctype]		
		self._internal_attributes[:thumbnail_info] = { :isexecute => false }
		
		
		# フォーム情報の取得(同じ画面が表示されている限り永続して保持する)
		self._form_attributes[:value_gamemaster] = params[:gamemaster]
		self._form_attributes[:form_playerinfo] = { :number => params[:playernumber].to_i , :playername => Hash.new, :thumbnailpath => Hash.new}
		(0..(params[:playernumber].to_i-1)).each do |i|
			key_username = ("player_name_" + i.to_s).to_sym
			if params[key_username] != nil then
				self._form_attributes[:form_playerinfo][:playername][key_username] = params[key_username]
			end
			
			key_thumbnail = ("player_thumbnail_path_" + i.to_s).to_sym
			if params[key_thumbnail] != nil then
				self._form_attributes[:form_playerinfo][:thumbnailpath][key_thumbnail] = params[key_thumbnail]
			end
		end
		
		
		# 同一画面の遷移の場合
		if self._internal_attributes[:proctype] == "checkself" then
			self._internal_attributes[:update_flag] = true								# 同じ画面を更新する
			self._internal_attributes[:istransact_db_gameinfo] = false					# データベースに対して変更をしない
			
			# ルールの検索のモード変更(ルール指定→ルール変更)
			if params[:button_event] == "changeRule"  then
				self._form_attributes[:issearchmode] = true
				self._form_attributes[:list_targetrules] = params[:list_targetrules]				
				self._internal_attributes[:isget_gamerulesetting] = true
			# ルールの検索のモード変更(ルール変更→ルール指定)
			elsif params[:button_event] == "updateRule" then
				self._form_attributes[:issearchmode] = false				
				if self._form_attributes[:searchmode_valid] == false then
					self._form_attributes[:searchmode_valid] = true
				end
				self._form_attributes[:searchmode_rule] = params[:list_rule]
				self._form_attributes[:searchmode_voterule] = params[:list_voterule]
				self._form_attributes[:searchmode_comebackrule] = params[:list_comebackrule]
				self._form_attributes[:searchmode_wolfnumber] = params[:list_wolfnumber]
			# プレイヤー情報登録へモード変更、または同じ呼び出しの場合
			elsif params[:button_event] == "updatePlayerInfo" then
				self._form_attributes[:state_playerinfo] = true
				
				# サムネイル画像取得イベントが発生した場合
				if params[:thumbnail_event] != nil then
					if params[params[:thumbnail_event]] != nil then
						self._internal_attributes[:thumbnail_info] = { 
								:isexecute => true,
								:target_uiname => params[:thumbnail_event], 
								:formdata => params[params[:thumbnail_event]]
						}
					end
				end
			end
		# SelectGame画面への遷移の場合
		elsif self._internal_attributes[:proctype] == "selectgame" then
			self._internal_attributes[:update_flag] = false					# 違う画面に遷移する
			self._internal_attributes[:istransact_db_gameinfo] = false		# データベースに対して変更をしない
			self._form_attributes[:state_playerinfo] = false				# サムネイルファイルへのアクセスはしない
		# ArrangeRemarks画面への遷移の場合
		elsif self._internal_attributes[:proctype] == "arrangeremarks" then
			self._internal_attributes[:update_flag] = false					# 同じ画面を更新する
			self._internal_attributes[:istransact_db_gameinfo] = true		# データベースに対して変更をする
			self._form_attributes[:state_playerinfo] = false				# サムネイルファイルへのアクセスはしない
		else
			403
		end
	end
	
	"
	関数を実行する
	"
	def execute()
		# ルール変更モード移行時のDBアクセス
		if self._internal_attributes[:isget_gamerulesetting] then
			dbdata = {}
			DatabaseQueryController.addToDbData_GameRuleSetting( @_common_params, dbdata)
			ruleitem = dbdata[:GameRuleSetting].where(:gsId => self._form_attributes[:list_targetrules].to_i).first
			if ruleitem != nil then 
				self._form_attributes[:searchmode_rule] = ruleitem.rule
				self._form_attributes[:searchmode_voterule] = ruleitem.voterule
				self._form_attributes[:searchmode_comebackrule] = ruleitem.comebackrule
				self._form_attributes[:searchmode_wolfnumber] = ruleitem.wolfnumber
			end
		end
		
		
		# サムネイル画像更新処理
		if self._internal_attributes[:thumbnail_info] != nil then
			if self._internal_attributes[:thumbnail_info][:isexecute] == true then
				begin
					p self._internal_attributes[:thumbnail_info][:formdata]
					
					filename = SecureRandom.hex(32) + ".png"
					filepath = "./public/resource/thumbnails/" + filename
					File.open(filepath, File::WRONLY|File::CREAT|File::EXCL, ) do |f|
						f.write self._internal_attributes[:thumbnail_info][:formdata][:tempfile].read
					end
					
					#p self._internal_attributes[:thumbnail_info][:target_uiname]
					self._form_attributes[:form_playerinfo][:thumbnailpath][self._internal_attributes[:thumbnail_info][:target_uiname].to_sym] = filename
				rescue Errno::EEXIST
					# ファイルが存在してたらリトライ
					retry
				end
				
				p "Thumbnail Changed!"
				
			end
		end
		
		# DBゲーム情報登録処理
		if self._internal_attributes[:istransact_db_gameinfo] then
			DatabaseQueryController.transact_gameinfo(@_common_params[:battle_id], @_common_params[:select_index], self._form_attributes)
		end
		
		
	end
	
	"
	テンプレートとして取得すべきページを表す。
	"
	def getTemplatePage()
		return :'/management/management_entry_arrangegameinfo'
	end
	
	def getDataViewFromTables()
		dbdata = {}
		DatabaseQueryController.addToDbData_GameInfo(@_common_params, dbdata)
		DatabaseQueryController.addToDbData_UserInfo(@_common_params, dbdata)
		DatabaseQueryController.addToDbData_GameRuleSetting( @_common_params, dbdata)
		return dbdata
	end
	
	"
	次の画面遷移の情報を与える。
	返値として次のオブジェクトを生成すること。
	"
	def getNextState(params)
		params = @_common_params
		
		
		params['form_attributes'] = self._form_attributes
		# 次状態決定
		if self._internal_attributes[:update_flag] then
			@_nextstatus = self
		else 
			if self._internal_attributes[:proctype] == "selectgame" then
				common_params = {}
				common_params[:battle_id] = @_common_params[:battle_id]
				@_nextstatus = StateManagement_SelectGame.new(common_params)
			elsif self._internal_attributes[:proctype] == "arrangeremarks" then
				common_params = {}
				common_params[:battle_id] = @_common_params[:battle_id]
				@_nextstatus = StateManagement_ArrangeRemarks.new(@_common_params)
			else
				throw "Transition Error (ArrangeGameInfo)"
			end
		end
		
		return [@_nextstatus, params]
	end
	
	
	def isPostRequest()
		return false;
	end
	
	def isDestroyed()
		return false
	end
end


