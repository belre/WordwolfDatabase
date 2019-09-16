

# --- active_record
require 'active_record'
require 'activerecord-import'


# TblBattleInfo (対戦情報テーブル)
class TblBattleInfo < ActiveRecord::Base
	has_many :tbl_game_info, :class_name => "TblGameInfo", :primary_key => :Id, :foreign_key => :Id
end


# TblGameRuleSetting (ゲームルール設定テーブル)
class TblGameRuleSetting < ActiveRecord::Base
	has_many :tbl_game_info, :class_name => "TblGameInfo", :primary_key => :gsId, :foreign_key => :gsId
	
end

# TblGameResult（ゲーム勝敗結果テーブル)
class TblGameResult < ActiveRecord::Base
	has_many :tbl_game_info, :class_name => "TblGameInfo", :primary_key => :grId, :foreign_key => :grId

end


# TblUserInfo（ユーザ情報テーブル)
class TblUserInfo < ActiveRecord::Base
	has_many :tbl_game_info, :class_name => "TblGameInfo", :primary_key => :guId_gamemaster, :foreign_key => :guId_gamemaster

	
end

# TblGameInfo （ゲーム情報テーブル)
class TblGameInfo < ActiveRecord::Base
	belongs_to :tbl_battle_info, :class_name => "TblBattleInfo", :foreign_key => :Id
	belongs_to :tbl_game_rule_setting, :class_name => "TblGameRuleSetting", :foreign_key => :gsId
	belongs_to :tbl_game_result, :class_name => "TblGameResult", :foreign_key => :grId
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :guId_gamemaster
end
	


# TblGameVote（投票テーブル）
class TblGameVote < ActiveRecord::Base
	
	
end


# TblWolfRole（人狼テーブル）
class TblGameWolves < ActiveRecord::Base
	
	
end


# TblAnswer（回答・逆転テーブル）
class TblGameAnswer < ActiveRecord::Base
	
	
end


# TblTalkMessage（発言・質問テーブル）
class TblTalkMessage < ActiveRecord::Base
	
	
end


# TblTalkReply（YesNoGray回答テーブル）
class TblTalkReply < ActiveRecord::Base
	
	
end


# Database用のクエリコントローラ
class DatabaseQueryController
	
	### バトル情報の追加処理
	def self.transact_entrybattle(localparams)
		outparams = localparams
		begin
			TblBattleInfo.transaction do
				TblGameInfo.transaction do	
					# battleinfoを追加
					tbl_battleinfo = TblBattleInfo.new					
					tbl_battleinfo.host = localparams[:battle_host]
					tbl_battleinfo.starttime =localparams[:battle_starttime]
					tbl_battleinfo.endtime = localparams[:battle_endtime]
					tbl_battleinfo.createdate = localparams[:battle_createdate]
					tbl_battleinfo.save!
					
					last_primary_id = TblBattleInfo.find_by_sql('SELECT last_insert_rowid();').first
					gid_primary = last_primary_id["last_insert_rowid()"]
					outparams[:battle_lastid] = gid_primary
					
					# gameinfoに空データをn行追加
					empty_gamelists = []
					(localparams[:battle_num_battle].to_i).times do |i| 
						empty_gamelists << TblGameInfo.new(
						#:Id => tbl_battleinfo, 
						:Id => gid_primary, 
						:gameindex => (i+1), :gsId => 2, :grId => 1, :guId_gamemaster => 2, :word_villager => "", :word_wolf => "", 
						:starttime => localparams[:battle_starttime], :limittime_min => 10, :limittime_sec => 0, :extendtime_min => 10, :extendtime_sec => 0)
					end
					
					TblGameInfo.import empty_gamelists
				end
			end
		rescue ActiveRecord::Roleback
			raise "Roleback Error"
		end
		
		#return outparams
	end
	
	
	def self.transact_gameinfo(id, gameindex, form_attributes)

		### tbl_user_info ###
		begin 
			TblBattleInfo.transaction do
				# 現在時刻取得
				nowtime = DateTime.now
				str = (('%04d' % nowtime.year)+ "-"+ ('%02d' % (nowtime.month + 1))+ "-" + ('%02d' % nowtime.day) + "T" + 
				('%02d' % nowtime.hour) + ":" + ('%02d' % nowtime.min) + ":" + ('%02d' % nowtime.sec))
				
				isinsertuser = false
				
				newuserlist = []
				
				# GM情報の追加が必要かを確認
				currentuserlist = TblUserInfo.where(:username => form_attributes[:value_gamemaster])
				if currentuserlist.count == 0 then
					newuserlist << TblUserInfo.new(
						:username => form_attributes[:value_gamemaster],
						:thumbnailpath => "master.png",
						:createdate => str,
						:npcstatus => 1				# NPC扱い
					)
					isinsertuser = true
				end
				
				# プレイヤー情報の追加が必要かを確認
				playerinfo = form_attributes[:form_playerinfo]
				(0..(playerinfo[:number]-1)).each do |i| 
					symkey = ("player_name_" + i.to_s).to_sym
					symimgkey = ("player_thumbnail_path_" + i.to_s).to_sym
					
					currentuserlist = TblUserInfo.where(:username => playerinfo[:playername][symkey])
					if currentuserlist.count == 0 then
						newuserlist << TblUserInfo.new(
							:username => playerinfo[:playername][symkey],
							:thumbnailpath => playerinfo[:thumbnailpath][symimgkey],
							:createdate => str,
							:npcstatus => 0				# NPC扱い
						)
					end
					isinsertuser = true
				end
				
				# Bulk Insert
				if isinsertuser then
					TblUserInfo.import newuserlist
				end
			end
		rescue ActiveRecord::Roleback
			raise "Roleback Error"
		end
			
				
		dbdata = {}
		
		dbdata[:userinfo] = TblUserInfo
		p dbdata[:userinfo].all
		
		#p id
		#p gameindex
		#p form_attributes
		
		dbdata[:all] = TblGameInfo
			.includes(:tbl_battle_info)
			.includes(:tbl_game_rule_setting)
			.includes(:tbl_game_result)
			.includes(:tbl_user_info)
			.where(:Id => id)
			.where(:gameindex => gameindex)
			.first
		
		#dbdata.update( :
		
		p dbdata[:all]
		
		# GameMaster変更
		
		p form_attributes
		
		
		
	end
	
	def self.transact_renewgameinfo(form_attributes)
	end
	
	
	def self.transact_arrangegameinfo(localparams)
		
	end
	
	
	
	
	
	def self.addToDbData_GameInfo(common_params, dbdata)
		dbdata[:GameInfo] = TblGameInfo
			.includes(:tbl_battle_info)
			.includes(:tbl_game_rule_setting)
			.includes(:tbl_game_result)
			.includes(:tbl_user_info)
			.where(:Id => common_params[:battle_id])
		#return dbdata
	end
	
	def self.addToDbData_UserInfo(common_params, dbdata)
		dbdata[:UserInfo] = TblUserInfo
			#.where(:NpcStatus => 0)
	end
	
	def self.addToDbData_GameRuleSetting(common_params, dbdata)
		dbdata[:GameRuleSetting] = TblGameRuleSetting
			.where('text != ""')
	end
	
	
	
end





class Contents < ActiveRecord::Base
end	

