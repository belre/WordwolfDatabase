

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
	has_many :tbl_game_vote, :class_name => "TblGameVote", :primary_key => :uId_elected, :foreign_key => :uId_elected
	has_many :tbl_game_vote, :class_name => "TblGameVote", :primary_key => :uId_target, :foreign_key => :uId_target
	has_many :tbl_game_player, :class_name => "TblGamePlayer", :primary_key => :uId, :foreign_key => :uId
	has_many :tbl_game_answer, :class_name => "TblGameAnswer", :primary_key => :uId, :foreign_key => :uId
	has_many :tbl_talk_message, :class_name => "TblGamePlayer", :primary_key => :uId, :foreign_key => :uId
	has_many :tbl_talk_reply, :class_name => "TblGameAnswer", :primary_key => :uId, :foreign_key => :uId
end

# TblGameInfo （ゲーム情報テーブル)
class TblGameInfo < ActiveRecord::Base
	belongs_to :tbl_battle_info, :class_name => "TblBattleInfo", :foreign_key => :Id
	belongs_to :tbl_game_rule_setting, :class_name => "TblGameRuleSetting", :foreign_key => :gsId
	belongs_to :tbl_game_result, :class_name => "TblGameResult", :foreign_key => :grId
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :guId_gamemaster
	has_many :tbl_game_vote, :class_name => "TblGameVote", :primary_key => :gId, :foreign_key => :gId
	has_many :tbl_game_player, :class_name => "TblGamePlayer", :primary_key => :gId, :foreign_key => :gId
	has_many :tbl_game_answer, :class_name => "TblGameAnswer", :primary_key => :gId, :foreign_key => :gId
	has_many :tbl_talk_message, :class_name => "TblGamePlayer", :primary_key => :gId, :foreign_key => :gId
	has_many :tbl_talk_reply, :class_name => "TblGameAnswer", :primary_key => :gId, :foreign_key => :gId
end
	


# TblGameVote（投票テーブル）
class TblGameVote < ActiveRecord::Base
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :uId_elected
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :uId_target
	belongs_to :tbl_game_info, :class_name => "TblGameVote", :foreign_key => :gId
end


# TblGamePlayer（プレイヤーテーブル）
class TblGamePlayer < ActiveRecord::Base
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :uId
	belongs_to :tbl_game_info, :class_name => "TblGameVote", :foreign_key => :gId
end


# TblAnswer（回答・逆転テーブル）
class TblGameAnswer < ActiveRecord::Base
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :uId
	belongs_to :tbl_game_info, :class_name => "TblGameVote", :foreign_key => :gId
end


# TblTalkMessage（発言・質問テーブル）
class TblTalkMessage < ActiveRecord::Base
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :uId
	belongs_to :tbl_game_info, :class_name => "TblGameVote", :foreign_key => :gId
end


# TblTalkReply（YesNoGray回答テーブル）
class TblTalkReply < ActiveRecord::Base
	belongs_to :tbl_user_info, :class_name => "TblUserInfo", :foreign_key => :uId
	belongs_to :tbl_game_info, :class_name => "TblGameVote", :foreign_key => :gId
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
						:gameindex => (i+1), :gsId => 2, :grId => 1, :guId_gamemaster => 1, :word_villager => "", :word_wolf => "", 
						:starttime => localparams[:battle_starttime], :limittime_min => 10, :limittime_sec => 0, :isgiveup => false, :extendtime_min => 10, :extendtime_sec => 0)
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
		
		dbdata = {}
		
		# id, gameindexをもとに、
		# 現在更新しようとしているデータを取得する
		dbdata[:all] = TblGameInfo
			.includes(:tbl_battle_info)
			.includes(:tbl_game_rule_setting)
			.includes(:tbl_game_result)
			.includes(:tbl_user_info)
			.where(:Id => id)
			.where(:gameindex => gameindex)
			.first
		
		if !self.updateNewUser(form_attributes) then
			raise "Transaction Error - 1"
		end
		
		dbdata[:gamevote] = TblGameVote.includes(:tbl_user_info).includes(:tbl_game_info)
		dbdata[:gameplayer] = TblGamePlayer.includes(:tbl_user_info).includes(:tbl_game_info)
		dbdata[:gameanswer] = TblGameAnswer.includes(:tbl_user_info).includes(:tbl_game_info)
		dbdata[:userinfo] = TblUserInfo
		
		begin
			# tbl_game_info
			begin
				
				update_gId = nil
				TblGameInfo.transaction do
					# TblGameResultに既存項目があるかを確認
					tmpdbdata = dbdata[:all].tbl_game_result
					isupdate = false
					if tmpdbdata.result_status == 0 then
						isupdate = true
					end
					
					# tbl_game_result
					TblGameResult.transaction do
						### ゲーム結果 ###
						# この条件の場合は、TblGameResultに新規のクエリを追加しておき、追加した添字を取得する。
						if isupdate then
							tbl_game_result = TblGameResult.new
							tbl_game_result.result_status = 1
							tbl_game_result.iscomeback_villager = 0
							tbl_game_result.iscomeback_wolf = 0
							tbl_game_result.save!
							
							# GameResultのパラメータを変更する
							dbdata[:all].grId = tbl_game_result.grId							
						end
						
						### GM ###
						# 追加されたGMのユーザIDを確認
						dbdata[:gamemaster_tbl] = TblUserInfo
							.where(:username => form_attributes[:value_gamemaster])
							.first
						
						if dbdata[:gamemaster_tbl] == nil then
							raise "Registration Error"
						end
						
						dbdata[:all].guId_gamemaster = dbdata[:gamemaster_tbl].uId
						
						
						### それ以外のパラメータ ###
						# word
						dbdata[:all].word_villager = form_attributes[:form_word_villagers]
						dbdata[:all].word_wolf = form_attributes[:form_word_wolves]
						
						# winlose
						dbdata[:all].tbl_game_result.result_status = form_attributes[:form_winlose]	
						dbdata[:all].tbl_game_result.iscomeback_villager = form_attributes[:form_comeback_villagers] == true ? 1 : 2
						dbdata[:all].tbl_game_result.iscomeback_wolf = form_attributes[:form_comeback_wolves] == true ? 1 : 2
						dbdata[:all].starttime = form_attributes[:form_game_starttime]
						dbdata[:all].limittime_min = form_attributes[:form_game_limittime_min]
						dbdata[:all].limittime_sec = form_attributes[:form_game_limittime_sec]
						dbdata[:all].isgiveup = form_attributes[:form_game_giveup] == true ? 1 : 2
						dbdata[:all].extendtime_min = form_attributes[:form_game_extendtime_min]
						dbdata[:all].extendtime_sec = form_attributes[:form_game_extendtime_sec]
						
						dbdata[:all].tbl_game_result.save!
						dbdata[:all].save!
						
						
						
						# 登録対象のgIdを取得
						update_gId = dbdata[:all].gId
						#p "gId:" + update_gId.to_s
					end
				end
				
				if update_gId == nil then
					raise "Register Error"
				end
				
				TblGameVote.transaction do
					# TblGameVoteに既存項目があるかを確認
					tmpdbdata = dbdata[:gamevote].where(:gId => update_gId)
					isupdate = false
					if tmpdbdata.count == 0 then
						isupdate = true
					end
					# 存在しない場合は追加する
					if isupdate then
						p 'TblGameVote-新規作成'
						(1..form_attributes[:form_playerinfo][:number]).each do |i|
							tbl_game_vote = TblGameVote.new
							tbl_game_vote.gId = update_gId
							tbl_game_vote.uId_elected = 1
							tbl_game_vote.uId_target = dbdata[:gamemaster_tbl].uId
							tbl_game_vote.numvotes = 0
							tbl_game_vote.isdisposed = 0
							tbl_game_vote.isghost = 0
							tbl_game_vote.save!
						end
					end
					
					TblGamePlayer.transaction do
						# TblGamePlayerに既存項目があるかを確認
						tmpdbdata = dbdata[:gameplayer].where(:gId => update_gId)
						isupdate = false
						if tmpdbdata.count == 0 then
							isupdate = true
						end
						# 存在しない場合は追加する
						if isupdate then
							p 'TblGamePlayer-新規作成'
							(1..form_attributes[:form_playerinfo][:number]).each do |i|
								tbl_game_player = TblGamePlayer.new
								tbl_game_player.gId = update_gId
								tbl_game_player.uId = 1
								tbl_game_player.role = ''
								tbl_game_player.isvillagers = 0
								tbl_game_player.iswolves = 0
								tbl_game_player.save!
							end
						end
						
						dbdata[:gamevote] = dbdata[:gamevote].where(:gId => update_gId) 
						dbdata[:gameplayer] = dbdata[:gameplayer].where(:gId => update_gId)
						dbdata[:gameanswer] = dbdata[:gameanswer].where(:gId => update_gId)
						
						
						# 更新する
						p dbdata[:gamevote].count
						(0..dbdata[:gamevote].count-1).each do |i|
							# ユーザID取得
							firstuserinfo = dbdata[:userinfo].where(:username => form_attributes[:form_playerinfo][:playerinfo][("player_name_" + i.to_s).to_sym]).first
							dbdata[:gamevote][i].uId_elected = firstuserinfo.uId
							
							#(UI未実装のため省略)
							dbdata[:gamevote][i].numvotes = form_attributes[:form_playerinfo][:playerinfo][("player_numvotes_" + i.to_s).to_sym]
							dbdata[:gamevote][i].isdisposed = form_attributes[:form_playerinfo][:playerinfo][("player_isdisposed_" + i.to_s).to_sym] == "on"
							dbdata[:gamevote][i].isghost = form_attributes[:form_playerinfo][:playerinfo][("player_isghost_" + i.to_s).to_sym] == "on"
							dbdata[:gamevote][i].save!
							
							dbdata[:gameplayer][i].gId = update_gId
							dbdata[:gameplayer][i].uId = firstuserinfo.uId
							if form_attributes[:form_playerinfo][:playerinfo][("player_iswolf_" + i.to_s).to_sym] == "on" then
								dbdata[:gameplayer][i].role = '人狼'
								dbdata[:gameplayer][i].iswolves = 1		
								dbdata[:gameplayer][i].isvillagers = 0
							else								
								dbdata[:gameplayer][i].role = '村人'
								dbdata[:gameplayer][i].iswolves = 0
								dbdata[:gameplayer][i].isvillagers = 1
							end
							dbdata[:gameplayer][i].save!
							
							comebackword = form_attributes[:form_playerinfo][:playerinfo][("player_comebackword_" + i.to_s).to_sym]
							p 'comebackword読み出し'
							comebackdbdata = dbdata[:gameanswer].where(:gId => update_gId).where(:uId => firstuserinfo.uId).first
							p 'comebackdbdata-新規作成'
							p firstuserinfo.uId
							
							if comebackword == "" then
								if comebackdbdata != nil then
									comebackdbdata.word_answer = ''
									comebackdbdata.save!
									#p 'comebackdbdata-destroy'
									#p comebackdbdata
									#comebackdbdata.delete!
									#comebackdbdata.word_answer = "" 
								end
							else
								p 'comebackdbdata-create'
								if comebackdbdata == nil then
									comebackdbdata = TblGameAnswer.new
								end
								comebackdbdata.gId = update_gId
								comebackdbdata.uId = firstuserinfo.uId
								comebackdbdata.word_answer = comebackword
								comebackdbdata.save!
							end
						end
					end
				end
			end
		rescue ActiveRecord::Roleback
			raise "Roleback Error"
		end
		
		
		
	end
	
	def self.transact_arrangeremarks(battle_id, select_index, jsonparam)
		tmpdbdata = {}
		addToDbData_GameInfo(battle_id, tmpdbdata)
		gId = tmpdbdata[:GameInfo].where(:gameindex => select_index).first.gId
		
		
		
		dbdata = {}
		self.addToDbData_GamePlayer(battle_id, select_index, dbdata)
		self.addToDbData_GameInfoOne(battle_id, select_index, dbdata)
		
		# 表示用に暫定にしよう
		user = []
		dbdata[:GamePlayer].each do |obj|
			user.push(obj.tbl_user_info.username)
		end
		user.push(dbdata[:GameInfoOne][0].tbl_user_info.username)
		
		# ここがほんちゃん
		user_userid = []
		dbdata[:GamePlayer].each do |obj|
			tmp = []
			tmp.push(obj.tbl_user_info.uId)
			tmp.push(obj.tbl_user_info.username)
			
			user_userid.push(tmp)
		end
		
		tmp = []
		tmp.push(dbdata[:GameInfoOne][0].tbl_user_info.uId)
		tmp.push(dbdata[:GameInfoOne][0].tbl_user_info.username)
		user_userid.push(tmp)
		
		
		TblTalkMessage.transaction do
			TblTalkReply.transaction do
				### --- JSON Reply Appendの番号コードの分離 --- ###
				reply_append_list = {}
				jsonparam["Reply_Append"].each do |k , v|
					tmp_reply_append = {}
					
					# #~@の領域を抽出
					remarkno_sign_ind = k.index('#')
					speaker_sign_ind = k.index('@')
					if  remarkno_sign_ind == nil or speaker_sign_ind == nil then
						next
					end
					if  remarkno_sign_ind - 1 >= speaker_sign_ind then
						next
					end
					
					
					remarkno_len = speaker_sign_ind - 1
					speaker_len = k.length - speaker_sign_ind - 1
					
					remarkno_str = k[remarkno_sign_ind+1, remarkno_len]
					speaker_str = k[speaker_sign_ind+1, speaker_len]
					
					if remarkno_str.to_i(0) == 0 then
						next
					end
					
					
					puts speaker_str
					
					tmp_reply_append[:remarkno] = (remarkno_str.to_i(0))
					tmp_reply_append[:speaker] = (speaker_str)
					tmp_reply_append[:remark_append] = v
					reply_append_list[tmp_reply_append[:remarkno]] = tmp_reply_append
				end
				
				
				
				
				### --- JSON 情報を読み出しする --- ###
				puts "経過時間:" + jsonparam["PassedTime"].to_s 
				
				user_userid.each do |cuser|
					if jsonparam["Message"][cuser[1]] != nil
						puts "Q." + cuser[1] + " "+ jsonparam["Message"][cuser[1]] 
						tbl_talk_message = TblTalkMessage.new
						tbl_talk_message.gId = gId
						tbl_talk_message.uId = cuser[0]
						tbl_talk_message.passedtime_min	= 1
						tbl_talk_message.passedtime_sec	= 0
						tbl_talk_message.limittime_min	= 5
						tbl_talk_message.limittime_sec	= 0
						tbl_talk_message.message = jsonparam["Message"][cuser[1]] 
						tbl_talk_message.save!
						
						#tbl_talk_message.role = ''
						#tbl_talk_message.isvillagers = 0
						#tbl_talk_message.iswolves = 0
						#tbl_talk_message.save!
					end
				end
				
				user.each do |name|
					if jsonparam["Reply"][name] != nil
						puts "A." + name + " " + jsonparam["Reply"][name]
					end
				end
				
				
				
				reply_append_list.each do |k, v|
					if user.include?(v[:speaker].to_s) then
						puts k.to_s + " " + v[:speaker].to_s + " " + v[:remark_append].to_s 
						
					end
				end
				puts "----------------"
				
				
				
			end
		end
		
		
		
		
	end
	
	
	
	def self.transact_renewgameinfo(form_attributes)
	end
	
	
	def self.transact_arrangegameinfo(localparams)
		
	end
	
	def self.updateNewUser(form_attributes)
		begin 
			TblUserInfo.transaction do
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
					
					p playerinfo[:playerinfo]
					
					currentuserlist = TblUserInfo.where(:username => playerinfo[:playerinfo][symkey])
					if currentuserlist.count == 0 then
						newuserlist << TblUserInfo.new(
						:username => playerinfo[:playerinfo][symkey],
						:thumbnailpath => playerinfo[:playerinfo][symimgkey],
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
			return false
		end
		
		return true
	end
	
	def self.addToDbData_GameInfoAll(dbdata)
		dbdata[:GameInfoAll] = TblGameInfo
			.includes(:tbl_battle_info)
			.includes(:tbl_game_rule_setting)
			.includes(:tbl_game_result)
			.includes(:tbl_user_info)
			.all
		
		dbdata[:BattleInfo] = TblBattleInfo.order(Id: :desc).all
	end
	
	
	def self.addToDbData_GameInfo(battle_id, dbdata)
		dbdata[:GameInfo] = TblGameInfo
			.includes(:tbl_battle_info)
			.includes(:tbl_game_rule_setting)
			.includes(:tbl_game_result)
			.includes(:tbl_user_info)
			.where(:Id => battle_id)
			
		#return dbdata
	end
	
	def self.addToDbData_GameInfoOne(battle_id, select_index, dbdata)
		dbdata[:GameInfoOne] = TblGameInfo
		.includes(:tbl_battle_info)
		.includes(:tbl_game_rule_setting)
		.includes(:tbl_game_result)
		.includes(:tbl_user_info)
		.where(:Id => battle_id)
		.where(:gameindex => select_index)
		
		#return dbdata
	end
	
	def self.addToDbData_UserInfo( dbdata)
		dbdata[:UserInfo] = TblUserInfo
			#.where(:NpcStatus => 0)
	end
	
	def self.addToDbData_GameRuleSetting(dbdata)
		dbdata[:GameRuleSetting] = TblGameRuleSetting
			.where('text != ""')
	end
	
	def self.addToDbData_GamePlayer(battle_id, select_index, dbdata)
		tmpdbdata = {}
		addToDbData_GameInfo(battle_id, tmpdbdata)
		gId = tmpdbdata[:GameInfo].where(:gameindex => select_index).first.gId
		
		dbdata[:GamePlayer] = TblGamePlayer
			.includes(:tbl_user_info)
			.where(:gId => gId)		
	end
	
	
	def self.addToDbData_GameVote(battle_id, select_index, dbdata)
		tmpdbdata = {}
		addToDbData_GameInfo(battle_id, tmpdbdata)
		gId = tmpdbdata[:GameInfo].where(:gameindex => select_index).first.gId
		
		dbdata[:GameVote] = TblGameVote
			.includes(:tbl_user_info)
			.where(:gId => gId)	
	end
	
	def self.addToDbData_GameAnswer(battle_id, select_index, dbdata)
		tmpdbdata = {}
		addToDbData_GameInfo(battle_id, tmpdbdata)
		gId = tmpdbdata[:GameInfo].where(:gameindex => select_index).first.gId
		
		dbdata[:GameAnswer] = TblGameAnswer
			.includes(:tbl_user_info)
			.where(:gId => gId)	
	end
	
	def self.addToDbData_TalkMessage(battle_id, select_index, dbdata)
		tmpdbdata = {}
		addToDbData_GameInfo(battle_id, tmpdbdata)
		gId = tmpdbdata[:GameInfo].where(:gameindex => select_index).first.gId
		
		dbdata[:TalkMessage] = TblTalkMessage
			.includes(:tbl_user_info)
			.where(:gId => gId)
		
	end
	
	def self.addToDbData_TalkReply(battle_id, select_index, dbdata)
		tmpdbdata = {}
		addToDbData_GameInfo(battle_id, tmpdbdata)
		gId = tmpdbdata[:GameInfo].where(:gameindex => select_index).first.gId
		
		dbdata[:TalkReply] = TblTalkReply
			.includes(:tbl_user_info)
			.where(:gId => gId)
		
		
		
	end
	
	
	
	
end





class Contents < ActiveRecord::Base
end	

