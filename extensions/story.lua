module("extensions.story", package.seeall)
extension = sgs.Package("story")

sgs.LoadTranslationTable{
	["story"] = "OL新將",
}

local skills = sgs.SkillList()

--更改勢力

--[[
turn_length = sgs.CreateTriggerSkill{
	name = "turn_length",
	global = true,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data, room)
		local n = 15
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			n = math.min(p:getSeat(), n)
		end
		if player:getSeat() == n and not room:getTag("ExtraTurn"):toBool() then
			room:setPlayerMark(player, "@clock_time", room:getTag("TurnLengthCount"):toInt()+1)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, mark in sgs.list(p:getMarkNames()) do
					if string.find(mark, "_lun") and p:getMark(mark) > 0 then
						room:setPlayerMark(p, mark, 0)
					end
				end
			end
		end
		return false
	end
}

player:getNextAlive()

]]--

turn_length = sgs.CreateTriggerSkill{
	name = "turn_length",
	events = {sgs.GameStart,sgs.EventPhaseChanging},
	global = true,
	priority = -999,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isLord() then
					room:setPlayerMark(p, "@clock_time", 1)
				end
			end

		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart and not room:getTag("ExtraTurn"):toBool() then
				if player:getMark("@AG_Changeturn") > 0 then
					local lord_player
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isLord() or (p:getMark("@clock_time") > 0) then
							lord_player = p
							break
						end
					end
					if lord_player then
						if lord_player:getMark("@stop_invoke") == 0 then
							room:setPlayerMark(lord_player, "@clock_time", lord_player:getMark("@clock_time") + 1)
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								for _, mark in sgs.list(p:getMarkNames()) do
									if string.find(mark, "_lun") and p:getMark(mark) > 0 then
										room:setPlayerMark(p, mark, 0)
									end
								end
							end
						else
							--room:setPlayerMark(lord_player, "@stop_invoke", 0)
						end
					end
				end
			elseif change.to == sgs.Player_NotActive and not room:getTag("ExtraTurn"):toBool()  then
				
				if player:getMark("@stop_invoke") > 0 then
					room:setPlayerMark(player, "@stop_invoke", 0)
				end

				if player:getMark("@AG_Changeturn") > 0 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, "@stop_invoke", 0)
						room:setPlayerMark(p, "@AG_Changeturn", 0)
					end
				end


				local nextplayer = player:getNextAlive()
				if nextplayer:isLord() or (nextplayer:getMark("@clock_time") > 0) then
					if nextplayer then
						if nextplayer:getMark("@stop_invoke") == 0 then
							room:setPlayerMark(nextplayer, "@clock_time", nextplayer:getMark("@clock_time") + 1)
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								for _, mark in sgs.list(p:getMarkNames()) do
									if string.find(mark, "_lun") and p:getMark(mark) > 0 then
										room:setPlayerMark(p, mark, 0)
									end
								end
							end
						end
					end
					
				elseif not nextplayer:faceup() then
					local q
					local after_lord = false
					for i = 1,8,1 do
						q = q:getNextAlive()
						if not q:faceup() then
							if after_lord then
								room:setPlayerMark(q, "@AG_Changeturn", 1)
							end
							if q:isLord() or q:getMark("AG_firstplayer") > 0 then
								after_lord = true
							end
						else
							break
						end
					end
				end

			end
			return false
		end
	end
}

clearAG = sgs.CreateTriggerSkill{
	name = "clearAG",
	global = true,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data, room)
		local effect = data:toCardEffect()
		if effect.card and effect.card:isKindOf("AmazingGrace") and room:getTag("AmazingGrace"):toIntList():length() == 0 then return true end
	end,
	can_trigger = function(self, target)
		return target
	end
}

JUDGE_BUG = sgs.CreateTriggerSkill{
	name = "JUDGE_BUG",
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		if judge.reason ~= self:objectName() then return false end
		judge.pattern = tostring(judge.card:getEffectiveId())
	end,
	can_trigger = function(self, target)
		return target
	end
}

damage_record = sgs.CreateTriggerSkill{
	name = "damage_record",
	events = {sgs.DamageComplete},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:isAlive() then
			room:addPlayerMark(damage.from, self:objectName(), damage.damage)
			room:addPlayerMark(damage.from, self:objectName().."-Clear", damage.damage)
			if damage.from:getPhase() == sgs.Player_Play then
				room:addPlayerMark(damage.from, self:objectName().."play-Clear", damage.damage)
			end
		end
		--受傷標記
		if damage.to and damage.to:isAlive() then
			room:addPlayerMark(damage.to, "damaged_record", damage.damage)
			room:addPlayerMark(damage.to, "damaged_record-Clear", damage.damage)

			--荀諶〖謀識〗專用
			for _, mark in sgs.list(damage.to:getMarkNames()) do
				if string.find(mark, "last_damage_card") and damage.to:getMark(mark) > 0 then
					room:setPlayerMark(damage.to, mark, 0)
				end
			end
			if damage.card and GetColor(damage.card) then
				room:setPlayerMark(damage.to,"last_damage_card"..GetColor(damage.card),1)
				if damage.to:hasSkill("mobile_mouzhi") then
					room:setPlayerMark(damage.to,"@mobile_mouzhi_"..GetColor(damage.card),1)
				end
			end
		end
		if damage.from and damage.to and damage.from:isAlive() and damage.to:isAlive() then
			if damage.to:getMark( "juguan_"..damage.from:objectName() ) > 0 then
				room:setPlayerMark(damage.to, "juguan_"..damage.from:objectName() ,0)
				room:setPlayerMark(damage.to, "juguan_invoke" ,0)
			end
		end

		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("damage_record_lun") == 0 then
				room:addPlayerMark(p, "damage_record_lun")
			end
		end
	end
}

people_count = sgs.CreateTriggerSkill{
	name = "people_count",
	--events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.Death},
	--events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded,sgs.CardFinished},
	events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.Death,sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded,sgs.CardFinished},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local num,n,m = 0,0,0
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getRole() == "rebel" then
				num = num + 1
			end
			if p:getRole() == "loyalist" then
				n = n + 1
			end
			if p:isFemale() then
				m = m + 1
			end
		end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			room:setPlayerMark(p, "dingpan", num)
			room:setPlayerMark(p, "fenyue", n)
			--room:setPlayerMark(p, "xiefang", m)
			local x = 0
			for _,q in sgs.qlist(room:getAlivePlayers()) do
				if (not isSameTeam(p,q)) then
					x = x + 1
				end
			end
			room:setPlayerMark(p, "ol_fenyue", x)

			--鳳營技能
			if p:hasSkill("fengying") then
				local less_hp = 999
				for _,q in sgs.qlist(room:getAlivePlayers()) do
					less_hp = math.min(less_hp,q:getHp())
				end
				for _,q in sgs.qlist(room:getAlivePlayers()) do
					if isSameTeam(p,q) then
						if less_hp == q:getHp() then
							room:setPlayerMark(q,"fengying_target",1)
						end
					else
						room:setPlayerMark(q,"fengying_target",0)
					end
				end
			end
		end
	end
}

death_count = sgs.CreateTriggerSkill{
	name = "death_count",
	events = {sgs.Death},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Death then
			local death = data:toDeath()
			if player:isAlive() then
				room:addPlayerMark(player, "death_count", 1)
				room:addPlayerMark(player, "qiluan_po-Clear", 1)

				if death.damage then
					if death.damage.from and death.damage.from:objectName() == player:objectName() then
						room:addPlayerMark(player, "qiluan_po-Clear", 2)
						room:addPlayerMark(player, "lua_lianpo_start", 1)
						if player:hasSkill("lua_lianpo") then
							local current = room:getCurrent()
							local msg = sgs.LogMessage()
							msg.type = "#LianpoRecord"
							msg.from = player
							msg.to:append(death.who)
							msg.arg = current:getGeneralName()
							room:sendLog(msg)							
						end
					end
				end
			end

			if death.who and death.who:objectName() == player:objectName() then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					--清除頌詞
					if p:getMark("ol_songci" .. player:objectName()) > 0 then
						room:setPlayerMark(p,"ol_songci" .. player:objectName() ,0)
						room:removePlayerMark(p,"@songci")
					end
					--清除威儀
					if p:getMark("weiyi" .. player:objectName()) > 0 then
						room:setPlayerMark(p,"weiyi" .. player:objectName() ,0)
						room:removePlayerMark(p,"@weiyi")
					end
					--清除SP香香
					if p:getMark("lua_liangzhu_draw" .. player:objectName()) > 0 then
						room:removePlayerMark(p,"@liangzhu_draw")
						room:setPlayerMark(p,"lua_liangzhu_draw"..player:objectName(),0)
					end
					--手殺羊徽瑜清除「弘儀」標記
					if player:getMark("mobile_hongyi"..p:objectName().."_target") > 0 then
						room:setPlayerMark(p, "@mobile_hongyi_target", 0)
						room:setPlayerMark(player, "mobile_hongyi"..p:objectName().."_target", 0)
					end

					--手殺袁渙清除「奉節」標記
					if player:getMark("fengjie"..p:objectName().."_target") > 0 then
						room:setPlayerMark(p, "@fengjie", 0)
						room:setPlayerMark(player, "fengjie"..p:objectName().."_target", 0)
					end

					--界魯肅清除「好施」標記
					if player:getMark("haoshi_po"..p:objectName().."_target") > 0 then
						room:setPlayerMark(p, "@haoshi_po", 0)
						room:setPlayerMark(player, "haoshi_po"..p:objectName().."_target", 0)
					end

					--曹嵩清除「翊正」標記
					if player:getMark("csyizheng"..p:objectName().."_target") > 0 then
						room:setPlayerMark(p, "@csyizheng", 0)
						room:setPlayerMark(player, "csyizheng"..p:objectName().."_target", 0)
					end

					--陸郁生、王甫趙累、戲志才死亡清除標記
					if p:getMark("zhiwei_target"..player:objectName()) > 0 then
						room:setPlayerMark(p, "@zhiwei_target", 0)
						room:setPlayerMark(p, "zhiwei_target"..player:objectName() , 0)
					end
					if p:getMark("mobile_xunyi_target"..player:objectName()) > 0 then
						room:setPlayerMark(p, "@mobile_yi", 0)
						room:setPlayerMark(p, "mobile_xunyi_target"..player:objectName() , 0)
					end
					if p:getMark("fu"..player:objectName() ) > 0 then
						room:setPlayerMark(p, "fu"..player:objectName() , 0)
						room:removePlayerMark(p, "@xianfu" )
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

mute_e = sgs.CreateTriggerSkill{
	name = "mute_e",
	events = {sgs.PreCardUsed, sgs.CardResponded},
	global = true,
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "_ol_rende" and use.card:isKindOf("BasicCard") then
					if use.from:isMale() then
						room:broadcastSkillInvoke(use.card:objectName())
					else
						sgs.Sanguosha:playAudioEffect("audio/card/female/"..use.card:objectName()..".ogg", false)
					end
					return true
				end
				if player:hasSkill("ol_shichou") and use.card:isKindOf("Slash") and use.to:length() > 1 then
					room:broadcastSkillInvoke("ol_shichou")
				end
				if use.from:hasFlag(self:objectName()) then
					use.card:setSkillName("_"..self:objectName())
					data:setValue(use)
					room:broadcastSkillInvoke(self:objectName(), 2)
				end
				if skill == "jiewei" then
					room:broadcastSkillInvoke(skill, 2)
					return true
				end
--				if skill == "weijing" then
--					if card:isKindOf("Slash") then
--					--room:broadcastSkillInvoke(skill, 1)
--					else
--					--room:broadcastSkillInvoke(skill, 2)
--					end
--					return true
--				end
				if skill == "wusheng" and use.from:hasSkill("nosfuhun") and not use.from:hasInnateSkill("wusheng") then
					room:broadcastSkillInvoke("nosfuhun", 1)
					return true
				end
				if skill == "dingpan" or skill == "_mizhao" or skill == "duliang" or skill == "_ol_zhongyong"
				or skill == "jiyu" or skill == "kuangbi"  or skill == "fenyue" or skill == "_fenyue"
				or skill == "shuimeng" or skill == "_shensu" or skill == "shanjia" or skill == "_shanjia"
				or skill == "jixu" or skill == "qinguo" or skill == "poxi" or skill == "ol_shanjia"
				or skill == "yanjiao"
				then
					return true
				end
			end
--		else
--			local res = data:toCardResponse()
--			local skill = res.m_card:getSkillName()
--			if skill == "weijing" then
--				if res.m_card:isKindOf("Slash") then
--				--room:broadcastSkillInvoke(skill, 1)
--				else
--				--room:broadcastSkillInvoke(skill, 2)
--				end
--				return true
--			end
		end
	end
}
hand_skill = sgs.CreateTriggerSkill{
	name = "hand_skill",
	events = {sgs.EventPhaseProceeding},
	global = true,
	priority = -1,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Discard then
			local extra, black = false, false
			for _, card in sgs.list(player:getHandcards()) do
				if card:isBlack() then
					black = true
				end
			end
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() == "qun" then
					extra = true
				end
			end
			if player:hasLordSkill("xueyi") and extra then
				room:sendCompulsoryTriggerLog(player, "xueyi")
				if player:getGeneralName() == "yuanshao_po" then
					room:broadcastSkillInvoke("xueyi")
				end
			end
			if player:hasSkill("jugu") then
				room:sendCompulsoryTriggerLog(player, "jugu")
				room:broadcastSkillInvoke("jugu", 1)
			end
			if player:hasSkill("zongshi") then
				room:sendCompulsoryTriggerLog(player, "zongshi")
				room:broadcastSkillInvoke("zongshi")
			end
			if player:hasSkill("shenju") then
				room:sendCompulsoryTriggerLog(player, "shenju")
				room:broadcastSkillInvoke("shenju")
			end
			if player:hasSkill("juejing") then
				room:sendCompulsoryTriggerLog(player, "juejing")
			end
			if player:hasSkill("yingzi") then
				room:sendCompulsoryTriggerLog(player, "yingzi")
			end
		end
	end
}
ExtraCollateralCard = sgs.CreateSkillCard{
	name = "ExtraCollateral",
	filter = function(self, targets, to_select)
		local coll = sgs.Card_Parse(sgs.Self:property("extra_collateral"):toString())
		if (not coll) then return false end
		local tos = sgs.Self:property("extra_collateral_current_targets"):toString():split("+")
		if #targets == 0 then
			return not table.contains(tos, to_select:objectName()) and not sgs.Self:isProhibited(to_select, coll) and coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
		else
			return coll:targetFilter(targetsTable2QList(targets), to_select, sgs.Self)
		end
	end,
	about_to_use = function(self, room, use)
		local killer = use.to:first()
		local victim = use.to:last()
		killer:setFlags("ExtraCollateralTarget")
		local _data = sgs.QVariant()
		_data:setValue(victim)
		killer:setTag("collateralVictim", _data)
	end
}
ExtraCollateral = sgs.CreateZeroCardViewAsSkill{
	name = "ExtraCollateral",
	response_pattern = "@@ExtraCollateral",
	view_as = function()
		return ExtraCollateralCard:clone()
	end
}
fulin_ex = sgs.CreateTriggerSkill{
	name = "fulin_ex",
	global = true,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and not move.card_ids:isEmpty() then
			for _, id in sgs.qlist(move.card_ids) do
				room:addPlayerMark(player, "fulin"..id.."-Clear")
				if move.reason.m_skillName and move.reason.m_skillName ~= "zhuosheng" then
					room:addPlayerMark(player, "zhuosheng_"..id.."_lun")
				end

				if move.reason.m_skillName and move.reason.m_skillName == "poxiang" then
					room:addPlayerMark(player, "poxiang"..id.."-Clear")
				end
			end
		end
		return false
	end
}

--卡牌使用紀錄
card_used = sgs.CreateTriggerSkill{
	name = "card_used",
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	global = true,
	priority = -1,
	on_trigger = function(self, event, player, data, room)
		local card
		local invoke = true
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			if data:toCardResponse().m_isUse then
				card = data:toCardResponse().m_card
			else
				invoke = false
			end
		end
		if card and (not card:isKindOf("SkillCard")) and card:getSkillName() ~= "xiongzhi" then
			if card:isKindOf("Slash") or use.card:isKindOf("Duel") then
				room:addPlayerMark(player, "ol_fengpo-Clear")
			end
			if card:getSubcards():length() > 1 or card:getSuit() > 3 then
				room:addPlayerMark(player, "guanwei_break-Clear")
			else
				if player:getMark("used_suit"..card:getSuit().."-Clear") == 0 then
					room:setPlayerMark(player, "used_suit_num-Clear", player:getMark("used_suit_num-Clear") + 1)
				end
				room:addPlayerMark(player, "used_suit"..card:getSuit().."-Clear")
			end
			
			if player:getMark("used_cardtype"..card:getTypeId().."-Clear") == 0 then 				
				room:setPlayerMark(player, "used_cardtype_num-Clear", player:getMark("used_cardtype-Clear") + 1)
			end
			room:addPlayerMark(player, "used_cardtype"..card:getTypeId().."-Clear")
			if player:getPhase() == sgs.Player_Play then
				room:addPlayerMark(player, "used_cardtype"..card:getTypeId().."_Play")
			end

			if player:getMark("used_suit_num-Clear") > 1 then
				room:addPlayerMark(player, "guanwei_break-Clear")
			end

			room:setPlayerMark(player, "used-before-Clear", card:getSuit() + 1)

			if invoke then
				room:addPlayerMark(player, "used-Clear")
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "used_Play")
				end
			end
			room:addPlayerMark(player, "us-Clear")
			if player:getPhase() == sgs.Player_Play then
				room:addPlayerMark(player, "us_Play")
			end
			if card:isKindOf("Slash") then
				room:addPlayerMark(player, "used_slash-Clear")
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "used_slash_Play")
				end
			end

			if card:isKindOf("TrickCard") then
				room:addPlayerMark(player, "used_trick-Clear")
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "used_trick_Play")
				end
			end

			--非基本牌
			if not card:isKindOf("BasicCard") then
				room:addPlayerMark(player, "used_non_basic-Clear")
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "used_non_basic_Play")
				end
			end

			--群蘇飛技能「諍薦」
			if player:getMark("@zhengjian") == 1 then
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "zhengjian_can_draw") then
						room:setPlayerMark(player,mark ,player:getMark(mark) +1 )
					end
				end
			end

			room:addPlayerMark(player, "card_used_num_Play")
			if not card:isKindOf("EquipCard") then
				room:addPlayerMark(player, "card_used_num_without_equip_Play")
			end

			--崔琰雅望

			if player:getMark("yawang-Clear") > 0 then
				if player:getMark("yawang-Clear") == player:getMark("card_used_num_Play") then
					room:setPlayerCardLimitation(player, "use", ".", false)
					room:addPlayerMark(player, "yawang_stop-Clear")
				end
			end

			if player:hasSkill("yb_quanbian") then
				if player:getMaxHp() == player:getMark("card_used_num_without_equip_Play") then
					room:setPlayerCardLimitation(player, "use", ".", false)
					room:addPlayerMark(player, "yb_quanbian_stop-Clear")
				end
			end

			--文姬默識
			if (not player:hasSkill("moshi")) and player:getPhase() == sgs.Player_Play then
				local promptlist = player:property("moshi"):toString():split(":")				
				table.insert(promptlist, card:objectName() )
				room:setPlayerProperty(player, "moshi", sgs.QVariant( table.concat(promptlist,":") ))
				--ChoiceLog(player, player:property("moshi"):toString())
			end

			--張翼執義
			if card:isKindOf("BasicCard") or card:isNDTrick() then
				local zhiyi_promptlist = player:property("zhiyi"):toString():split(":")				
				table.insert(zhiyi_promptlist, card:objectName() )
				room:setPlayerProperty(player, "zhiyi", sgs.QVariant( table.concat(zhiyi_promptlist,":") ))
			end

			--樊玉鳳 醮影
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "jiaoying_invoke_") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end

			--墨影
			if (card:isKindOf("BasicCard") or card:isNDTrick()) and player:getPhase() == sgs.Player_Play then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("juanhui"..p:objectName()) > 0 and p:hasSkill("juanhui") then
						room:setPlayerMark(p, "@juanhui_can_use"..card:objectName() , 1)
					end
				end
			end

			--紅牌
			if card:isRed() then
				room:addPlayerMark(player, "used_Red-Clear")
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "used_Red_Play")
				end
			end

			--本回合第一張殺給flag
			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				n = n + p:getMark("used_slash-Clear")
			end
			if n == 1 then
				room:setCardFlag(card , "first_slash_by_every_player-Clear")
			end

			if player:getMark("used_slash-Clear") == 1 then
				room:setCardFlag(card , "first_slash-Clear")
			elseif player:getMark("used_slash-Clear") == 2 then
				room:setCardFlag(card , "second_slash-Clear")
			end
			--本局使用的牌總數
			room:addPlayerMark(player, "card_used_num")

		end
		return false
	end
}


--卡牌獲得/失去紀錄
move_card_record = sgs.CreateTriggerSkill{
	name = "move_card_record" ,
	events = { sgs.BeforeCardsMove,sgs.CardsMoveOneTime},
	priority = -1,
	global = true,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if not room:getTag("FirstRound"):toBool() then
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE then
				room:setPlayerMark(player,"acquire_card-Clear",1)
			end
			--if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)) then
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
				room:setPlayerMark(player,"lose_card-Clear",1)
			end

			--留贊、手殺郭淮、孟獲用
			if event == sgs.CardsMoveOneTime and move.to_place == sgs.Player_DiscardPile then
				room:addPlayerMark(player,"enter_discard_pile-Clear" ,move.card_ids:length())
				if player:getPhase() ~= sgs.Player_NotActive and player:hasSkill("liji") then
					room:setPlayerMark(player, "@liji_count-Clear", player:getMark("enter_discard_pile-Clear"))
					local n = math.floor(player:getMark("@liji_count-Clear") / player:getMark("liji_alivenum-Clear"))
					room:setPlayerMark(player,"liji_canusetime-Clear",n)
				end

				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isRed() then
						room:addPlayerMark(player,"enter_discard_pile_red_card-Clear" ,move.card_ids:length())
					end
				end
			end

			if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				room:setPlayerMark(player,"has_discard-Clear",1)
			end
		end
	end
}


damage_card_record = sgs.CreateTriggerSkill{
	name = "damage_card_record",
	events = {sgs.DamageComplete, sgs.CardFinished},
	priority = -100,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.card then
				room:setCardFlag(damage.card, "damage_record")

				--界挑畔用
				room:setCardFlag(damage.card, "tiaoxin_po_damage_record")

				--手殺高覽用
				if damage.card:getSkillName() == "jungong" then
					room:addPlayerMark(player , "jungong_can_not_use-Clear")
				end

				--單張卡牌造成的傷害
				local n = damage.card:getTag("damage_num"):toInt() + damage.damage
				damage.card:setTag("damage_num", sgs.QVariant(n))

			end
		else
			local use = data:toCardUse()
			if use.card then

				room:setCardFlag(use.card, "-damage_record")

				room:setCardFlag(use.card , "-first_slash_by_every_player-Clear")
				room:setCardFlag(use.card , "-first_slash-Clear")
				room:setCardFlag(use.card , "-second_slash-Clear")

				--手殺高覽用
				if use.card:getSkillName() == "jungong" and use.card:isKindOf("Slash") then
					room:addPlayerMark(player , "jungong-Clear")
				end

				--消除手殺暗箭標記
				if use.to:length() > 0 then
					for _, p in sgs.qlist(use.to) do
						room:setPlayerFlag(p, "-mobile_anjian_buff")
					end
				end

				if use.card:hasFlag("zhaosong_song") then
					room:setCardFlag(use.card, "-zhaosong_song")
					if use.card:getTag("damage_num"):toInt() < 2 and player:isAlive() then
						room:loseHp(player)
					end
				end
				if use.card:getTag("damage_num"):toInt() > 0 then
					use.card:removeTag("damage_num")
				end

			end
		end
	end
}

function ALLAPPEAR(room, player, mark, right)
	if right then
		room:addPlayerMark(player, "@"..mark, player:getMark(mark))
		room:setPlayerMark(player, mark, 0)
	end
end

kuanshiing = sgs.CreateTriggerSkill{
	name = "kuanshiing",
	events = {sgs.DamageInflicted},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		--if damage.damage > 1 and (damage.to:getMark("@kuanshi_start") > 0 or damage.to:getMark("kuanshi_start") > 0) then
		if damage.damage > 1 then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				--if p:getMark("kuanshi"..damage.to:objectName()..damage.to:getMark("@kuanshi_start")) > 0 or p:getMark("kuanshi"..damage.to:objectName()..damage.to:getMark("kuanshi_start")) then
				if damage.to:getMark("kuanshi_target_"..p:objectName()) > 0 or damage.to:getMark("@kuanshi_target_"..p:objectName()) > 0 then
					if p:getMark("kuanshi_player_"..p:objectName()) > 0 or p:getMark("@kuanshi_player_"..p:objectName()) > 0 then
						--if p:getMark("kuanshi"..damage.to:objectName()..damage.to:getMark("kuanshi_start")) > 0 then
						if p:getMark("kuanshi_player_"..p:objectName()) > 0 then
							--ALLAPPEAR(room, damage.to, "kuanshi_start", true)
							ALLAPPEAR(room, damage.to, "kuanshi_target_"..p:objectName(), true)
						end
						--if p:getMark("kuanshi"..damage.to:objectName()..damage.to:getMark("@kuanshi_start")) > 0 then
						if p:getMark("@kuanshi_player_"..p:objectName()) > 0 then
							--ALLAPPEAR(room, damage.to, "@kuanshi_start", true)
							ALLAPPEAR(room, damage.to, "@kuanshi_target_"..p:objectName(), true)
						end
						room:broadcastSkillInvoke("kuanshi", 2)
						room:sendCompulsoryTriggerLog(p, "kuanshi")
						--room:removePlayerMark(damage.to, "@kuanshi_start")
						--room:removePlayerMark(damage.to, "kuanshi_start")
						--room:removePlayerMark(p, "kuanshi"..damage.to:objectName()..damage.to:getMark("@kuanshi_start"))
						--room:removePlayerMark(p, "kuanshi"..damage.to:objectName()..damage.to:getMark("kuanshi_start"))
						room:removePlayerMark(damage.to, "kuanshi_target_"..p:objectName())
						room:removePlayerMark(damage.to, "@kuanshi_target_"..p:objectName())
						room:removePlayerMark(p, "kuanshi_player_"..p:objectName())
						room:removePlayerMark(p, "@kuanshi_player_"..p:objectName())
						room:addPlayerMark(p, "skip_draw")
						return true
					end
				end
			end
		end
	end
}
skip = sgs.CreateTriggerSkill{
	name = "skip",
	events = {sgs.EventPhaseChanging,sgs.EventPhaseSkipping},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_Draw and player:getMark("skip_draw") > 0 then
				room:setPlayerMark(player, "skip_draw",0)
				player:skip(sgs.Player_Draw)

				if player:getMark("@mobile_qian") > 0 then
					room:removePlayerMark(player,"@mobile_qian")
				end
			end

			if data:toPhaseChange().to == sgs.Player_Play and player:getMark("skip_play") > 0 then
				room:setPlayerMark(player, "skip_play",0)
				player:skip(sgs.Player_Play)
			end

			if data:toPhaseChange().to == sgs.Player_Discard and player:getMark("skip_discard") > 0 then
				room:setPlayerMark(player, "skip_discard",0)
				player:skip(sgs.Player_Discard)
			end
		elseif event == sgs.EventPhaseSkipping then
			room:addPlayerMark(player, "pingkou-Clear")
			if player:getPhase() == sgs.Player_Play then
				room:addPlayerMark(player, "has_skipped_play-Clear")
			end
		end
	end
}

--遊戲開始時更改體力值
GameStartChangeHp = sgs.CreateTriggerSkill{
	name = "GameStartChangeHp",	
	events = {sgs.GameStart,sgs.DrawInitialCards},
	global = true,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			local n = player:getMaxHp()
			if player:getGeneralName() == "shenganning" or player:getGeneral2Name() == "shenganning" then
				n = n - 3
			end
			if player:getGeneralName() == "shen_sunce" or player:getGeneral2Name() == "shen_sunce" then
				n = n - 5
			end
			if player:getGeneralName() == "whlw_lijue" or player:getGeneral2Name() == "whlw_lijue" then
				n = n - 2
			end
			if player:getGeneralName() == "hujinding" or player:getGeneral2Name() == "hujinding" then
				n = n - 4
			end
			if player:getGeneralName() == "xingdaorong" or player:getGeneral2Name() == "xingdaorong" then
				n = n - 2
			end
			if player:getGeneralName() == "mobile_shenpei" or player:getGeneral2Name() == "mobile_shenpei" then
				n = n - 1
			end
			if player:getGeneralName() == "ol_sunjian" or player:getGeneral2Name() == "ol_sunjian" then
				n = n - 1
			end
			if player:getGeneralName() == "yb_simashi" or player:getGeneral2Name() == "yb_simashi" then
				n = n - 1
			end
			if player:getGeneralName() == "qiuliju" or player:getGeneral2Name() == "qiuliju" then
				n = n - 2
			end

			--雙將時確保最小體力值為1
			n = math.max(n,1)
			room:setPlayerProperty(player, "hp", sgs.QVariant(n))

			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() ~= "god" then
					if p:getKingdom() == "wei2" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					elseif p:getKingdom() == "shu2" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					elseif p:getKingdom() == "wu2" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					elseif p:getKingdom() == "qun2" or p:getKingdom() == "qun3" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					end
				end
			end

		elseif event == sgs.DrawInitialCards then
			--進行勢力更換
			if string.find(player:getGeneralName(), "sk_shen") or string.find(player:getGeneralName(), "sy_") or string.find(player:getGeneralName(), "key_")  then
			   room:setPlayerProperty(player, "kingdom", sgs.QVariant("god"))
			end
			
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() ~= "god" then
					if p:getKingdom() == "wei2" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					elseif p:getKingdom() == "shu2" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					elseif p:getKingdom() == "wu2" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					elseif p:getKingdom() == "qun2" or p:getKingdom() == "qun3" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					--秦勢力
					elseif p:getKingdom() == "qin" then
						local pkingdom_list = {"wei","shu","wu","qun","jin"}
						local pkingdom = pkingdom_list[math.random(1,5)]
						room:setPlayerProperty(p,"kingdom",sgs.QVariant(pkingdom))
						local msg = sgs.LogMessage()
						msg.type = "#changeKD"
						msg.from = p
						msg.to:append(p)
						msg.arg = p:getKingdom()
						room:sendLog(msg)
					end
				end
			end

			if player:hasSkill("zongzuo") then
				local extra = 0
				local kingdom_set = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					local flag = true
					for _, k in ipairs(kingdom_set) do
						if p:getKingdom() == k then
							flag = false
							break
						end
					end
					if flag then table.insert(kingdom_set, p:getKingdom()) end
				end
				extra = #kingdom_set
				room:sendCompulsoryTriggerLog(player, "zongzuo") 
				room:broadcastSkillInvoke("zongzuo",1)
				room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+extra))
				room:setPlayerProperty(player,"hp",sgs.QVariant(player:getMaxHp()))
			end
		end
	end,
}


--曹叡技能「恢拓」配音

huituo_audio = sgs.CreateTriggerSkill{
	name = "huituo_audio", 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForRetrial,sgs.PreCardUse,sgs.CardsMoveOneTime}, 
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForRetrial then 
			local judge = data:toJudge()
			if judge.reason == "huituo" and player:objectName() == judge.who:objectName() then
				room:broadcastSkillInvoke("huituo")
			end
		elseif event == sgs.PreCardUse then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				local audio_invoke = false
				for _, p in sgs.qlist(use.to) do
					if p:hasSkill("manyi_hm") then
						audio_invoke = true
						room:notifySkillInvoked(p, "manyi_hm" )
						room:sendCompulsoryTriggerLog(p, "manyi_hm" ) 
					end
				end
				if audio_invoke then
					room:broadcastSkillInvoke("manyi_hm")
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to then
				if move.reason.m_skillName == "qiaoshi" and move.to:objectName() == player:objectName() then
					room:broadcastSkillInvoke("qiaoshi")
				end
				if move.reason.m_skillName == "yjyanyu" then
					room:broadcastSkillInvoke("yjyanyu")
				end
				if move.reason.m_skillName == "zuoding" then
					room:broadcastSkillInvoke("zuoding")
				end
				if move.reason.m_skillName == "shifei" then
					room:broadcastSkillInvoke("shifei")
				end
				if move.reason.m_skillName == "jigong" then
					room:broadcastSkillInvoke("jigong")
				end
			end
		end
	end
}

--清除無限用牌效果
--[[
unlimitusecard = sgs.CreateTriggerSkill{
	name = "unlimitusecard",  
	events = {sgs.EventPhaseChanging,sgs.Death}, 
	global = true,
	on_trigger = function(self, event, gaoshun, data)
		if (triggerEvent == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		local room = gaoshun:getRoom()
		local target = gaoshun:getTag("XianzhenTarget"):toPlayer()
		if (triggerEvent == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName() ~= gaoshun:objectName() then
				if death.who:objectName() == target:objectName() then
					room:setFixedDistance(gaoshun, target, -1);
					gaoshun:removeTag("XianzhenTarget");
					room:setPlayerFlag(gaoshun, "-XianzhenSuccess");
				end
				return false;
			end
		end
		if target then
			local assignee_list = gaoshun:property("extra_slash_specific_assignee"):toString():split("+")
			table.removeOne(assignee_list,target:objectName())
			room:setPlayerProperty(gaoshun, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")));
			room:setFixedDistance(gaoshun, target, -1);
			gaoshun:removeTag("XianzhenTarget");
			room:removePlayerMark(target, "Armor_Nullified");
		end
		return false;
	end,
	can_trigger = function(self, target)
		return target and target:getTag("XianzhenTarget"):toPlayer()
	end,
}
]]--

target_count = sgs.CreateTriggerSkill{
	name = "target_count" ,
	events = {sgs.TargetConfirmed} ,
	priority = 100,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and player:hasSkill("danshou_po") and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) then
				room:addPlayerMark(player, "has_been_target-Clear")
				if player:hasSkill("danshou_po") then
					room:setPlayerMark(player, "@danshou_po-Clear" , player:getMark("has_been_target-Clear"))
				end
			end

		end
		return false
	end,
}

--廢除裝備欄、判定區
AbolishPlace = sgs.CreateTriggerSkill{
	name = "AbolishPlace",
	global = true,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded,sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip then
				for i = 0, move.card_ids:length() - 1, 1 do
					local card_id = move.card_ids:at(i)
					local card = sgs.Sanguosha:getCard(card_id)
					if card:isKindOf("Weapon") and player:getMark("@AbolishWeapon") > 0 then
						room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, false)
					elseif card:isKindOf("Armor") and player:getMark("@AbolishArmor") > 0 then
						room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, false)
					elseif card:isKindOf("DefensiveHorse") and player:getMark("@AbolishDefensiveHorse") > 0 then
						room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, false)
					elseif card:isKindOf("OffensiveHorse") and player:getMark("@AbolishOffensiveHorse") > 0 then
						room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, false)
					elseif card:isKindOf("Treasure") and player:getMark("@AbolishTreasure") > 0 then
						room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, false)
					end
				end
			end

			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceDelayedTrick then
				for i = 0, move.card_ids:length() - 1, 1 do
					local card_id = move.card_ids:at(i)
					local card = sgs.Sanguosha:getCard(card_id)
					if card:isKindOf("DelayedTrick") and player:getMark("@AbolishJudge") > 0 then
						room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, false)
					end
				end
			end

			return false
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}

AbolishPlacePs = sgs.CreateProhibitSkill{
	name = "AbolishPlacePs",
	global = true,
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		if card:isKindOf("Weapon") and to:getMark("@AbolishWeapon") > 0 then
			return true
		elseif card:isKindOf("Armor") and to:getMark("@AbolishArmor") > 0 then
			return true
		elseif card:isKindOf("DefensiveHorse") and to:getMark("@AbolishDefensiveHorse") > 0 then
			return true
		elseif card:isKindOf("OffensiveHorse") and to:getMark("@AbolishOffensiveHorse") > 0 then
			return true
		elseif card:isKindOf("Treasure") and to:getMark("@AbolishTreasure") > 0 then
			return true
		elseif card:isKindOf("DelayedTrick") and to:getMark("@AbolishJudge") > 0 then
			return true
		else
			return false
		end

	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}

sgs.LoadTranslationTable{
	["AbolishWeapon"] = "廢除武器欄",
	["AbolishArmor"] = "廢除防具欄",
	["AbolishHorse"] = "廢除坐騎欄",
	["AbolishDefensiveHorse"] = "廢除防禦坐騎欄",
	["AbolishOffensiveHorse"] = "廢除進攻坐騎欄",
	["AbolishTreasure"] = "廢除寶物欄",

	["RecoverWeapon"] = "恢復武器欄",
	["RecoverArmor"] = "恢復防具欄",
	["RecoverHorse"] = "恢復坐騎欄",
	["RecoverDefensiveHorse"] = "恢復防禦坐騎欄",
	["RecoverOffensiveHorse"] = "恢復進攻坐騎欄",
	["RecoverTreasure"] = "恢復寶物欄",
	
	["#Abolish1Equip"] = "%from 發動技能 “<font color=\"yellow\"><b> %arg </b></font>”，%arg2 ",
	["#Recover1Equip"] = "%from 發動技能 “<font color=\"yellow\"><b> %arg </b></font>”，%arg2 ",
	["#RecoverAllEquip"] = "%from 發動技能 “<font color=\"yellow\"><b> %arg </b></font>”，恢復所有裝備欄 ",
}

if not sgs.Sanguosha:getSkill("turn_length") then skills:append(turn_length) end
if not sgs.Sanguosha:getSkill("JUDGE_BUG") then skills:append(JUDGE_BUG) end
if not sgs.Sanguosha:getSkill("damage_record") then skills:append(damage_record) end
if not sgs.Sanguosha:getSkill("clearAG") then skills:append(clearAG) end
if not sgs.Sanguosha:getSkill("people_count") then skills:append(people_count) end
if not sgs.Sanguosha:getSkill("death_count") then skills:append(death_count) end
if not sgs.Sanguosha:getSkill("mute_e") then skills:append(mute_e) end
if not sgs.Sanguosha:getSkill("hand_skill") then skills:append(hand_skill) end
if not sgs.Sanguosha:getSkill("ExtraCollateral") then skills:append(ExtraCollateral) end
if not sgs.Sanguosha:getSkill("fulin_ex") then skills:append(fulin_ex) end
if not sgs.Sanguosha:getSkill("card_used") then skills:append(card_used) end
if not sgs.Sanguosha:getSkill("move_card_record") then skills:append(move_card_record) end
if not sgs.Sanguosha:getSkill("damage_card_record") then skills:append(damage_card_record) end
if not sgs.Sanguosha:getSkill("kuanshiing") then skills:append(kuanshiing) end
if not sgs.Sanguosha:getSkill("skip") then skills:append(skip) end
if not sgs.Sanguosha:getSkill("GameStartChangeHp") then skills:append(GameStartChangeHp) end
if not sgs.Sanguosha:getSkill("huituo_audio") then skills:append(huituo_audio) end
if not sgs.Sanguosha:getSkill("target_count") then skills:append(target_count) end
if not sgs.Sanguosha:getSkill("AbolishPlace") then skills:append(AbolishPlace) end
if not sgs.Sanguosha:getSkill("AbolishPlacePs") then skills:append(AbolishPlacePs) end

sgs.LoadTranslationTable{
	["#changeKD"] = "%from 的國籍改變為 %arg",
}

--清除標記與flag
clear_mark = sgs.CreateTriggerSkill{
	name = "clear_mark",
	global = true,
	priority = -100,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, splayer, data, room)
		local change = data:toPhaseChange()
		for _, player in sgs.qlist(room:getAlivePlayers()) do
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "_biu") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
		end
		if change.to == sgs.Player_NotActive then
			for _, player in sgs.qlist(room:getAlivePlayers()) do
				for _, skill in sgs.qlist(player:getSkillList(false, false)) do
					if string.find(skill:objectName(), "_clear") then
						room:detachSkillFromPlayer(player, skill:objectName(), true)
						room:filterCards(player, player:getCards("h"), true)
					end
				end
				if player:getMark("ol_huxiao-Clear") > 0 then
					local assignee_list = room:getCurrent():property("extra_slash_specific_assignee"):toString():split("+")
					for _, pp in sgs.qlist(room:getAlivePlayers()) do
						if pp:getMark("ol_huxiao-Clear") > 0 then
							table.removeOne(assignee_list, pp:objectName())
						end
					end
					room:setPlayerProperty(room:getCurrent(), "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
				end

				if player:getMark("kill_caocao-Clear") > 0 then
					local assignee_list = room:getCurrent():property("extra_slash_specific_assignee"):toString():split("+")
					for _, pp in sgs.qlist(room:getAlivePlayers()) do
						if pp:getMark("be_killed-Clear") > 0 then
							room:setFixedDistance(player, pp, -1)
							for i = 1,pp:getMark("be_killed-Clear"),1 do
								table.removeOne(assignee_list, pp:objectName())
							end
						end
						if pp:getMark("Armor_Nullified-Clear") > 0 then
							room:setPlayerMark(player,"Armor_Nullified",0)
						end

					end
					room:setPlayerProperty(room:getCurrent(), "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
				end

				if player:getMark("funan-Clear") > 0 then
					room:removePlayerCardLimitation(player, "use,response", card:toString())
				end
				if player:getMark("@weilu-Clear") > 0 then
					room:recover(player, sgs.RecoverStruct(player, nil, player:getMark("@weilu-Clear")))
				end
				if player:getMark("lijun_limit") > 0 then
					room:removePlayerMark(player, "lijun_limit")
				end
				if player:getMark("skill_invalidity-Clear") > 0 then
					room:removePlayerMark(player, "skill_invalidity-Clear")
					room:removePlayerMark(player, "@skill_invalidity")
				end
				if player:getMark("ban_ur") > 0 then
					room:removePlayerMark(player, "ban_ur")
					room:removePlayerCardLimitation(player, "use,response", ".|.|.|hand")
				end
				for _, mark in sgs.list(player:getMarkNames()) do
					if player:getMark(mark) > 0 and string.find(mark, "_skillClear") then
						if player:hasSkill(string.sub(mark, 1, string.len(mark) - 11)) then
							room:detachSkillFromPlayer(player, string.sub(mark, 1, string.len(mark) - 11))
							room:filterCards(player, player:getCards("h"), true)
						end
						room:setPlayerMark(player, mark, 0)
					end
					if splayer:objectName() == player:objectName() then
						if string.find(mark, "_flag") and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
						end
						if string.find(mark, "_manmanlai") and player:getMark(mark) > 0 then
							room:removePlayerMark(player, mark)
						end
					end
					if string.find(mark, "-Clear") and player:getMark(mark) > 0 then
						if mark == "turnOver-Clear" and player:getMark("turnOver-Clear") > 1 and player:faceup() then
							room:addPlayerMark(player, "stop")
						end
						if string.find(mark, "funan") then
							room:removePlayerCardLimitation(player, "use,response", sgs.Sanguosha:getCard(tonumber(string.sub(mark, 6, string.len(mark) - 6))):toString())
						end
						room:setPlayerMark(player, mark, 0)
					end
				end

				--清除默識
				room:setPlayerProperty(player, "moshi", sgs.QVariant(""))
				room:setPlayerProperty(player, "zhiyi", sgs.QVariant(""))
			end
		elseif change.to == sgs.Player_Play then
			for _, player in sgs.qlist(room:getAlivePlayers()) do
				for _, mark in sgs.list(player:getMarkNames()) do
					if splayer:objectName() == player:objectName() and string.find(mark, "_play") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
					end
					if string.find(mark, "_Play") and player:getMark(mark) > 0 then
						if mark == "zhongjian_Play" then
							sgs.Sanguosha:addTranslationEntry(":zhongjian", ""..string.gsub(sgs.Sanguosha:translate(":zhongjian"), sgs.Sanguosha:translate(":zhongjian"), sgs.Sanguosha:translate(":zhongjian")))
						end
						room:setPlayerMark(player, mark, 0)
					end
				end
			end
		elseif change.to == sgs.Player_Discard then
			for _, player in sgs.qlist(room:getAlivePlayers()) do
				if room:getCurrent():objectName() == player:objectName() then
					for _, card in sgs.list(player:getHandcards()) do
						if player:getMark("luoshen"..card:getId().."-Clear") > 0 then
							room:setPlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(card:getId()):toString(), false)
						end
					end
				end
			end
--		elseif change.to == sgs.Player_Start then
--			if splayer:getMark("ol_hunshang-Clear") > 0 and change.to == sgs.Player_Start and splayer:isWounded() then
--				local to = room:askForPlayerChosen(splayer, room:getOtherPlayers(splayer), "yinghun", "yinghun-invoke", true, true)
--				local x = splayer:getLostHp()
--				local choices = {"yinghun1"}
--				if to then
--					if not to:isNude() and x ~= 1 then
--						table.insert(choices, "yinghun2")
--					end
--					local choice = room:askForChoice(splayer, "yinghun", table.concat(choices, "+"))
--					ChoiceLog(splayer, choice)
--					if choice == "yinghun1" then
--						to:drawCards(1)
--						room:askForDiscard(to, self:objectName(), x, x, false, true)
--						room:broadcastSkillInvoke("yinghun", 3)
--					else
--						to:drawCards(x)
--						room:askForDiscard(to, self:objectName(), 1, 1, false, true)
--						room:broadcastSkillInvoke("yinghun", 4)
--					end
--				end
--			end
		elseif change.to == sgs.Player_RoundStart then
			for _, player in sgs.qlist(room:getAlivePlayers()) do
				if room:getCurrent():objectName() == player:objectName() then
					room:addPlayerMark(player, "turn")

					if player:getMark("skill_invalidity-turnclear") > 0 then
						room:removePlayerMark(player, "skill_invalidity-turnclear")
						room:removePlayerMark(player, "@skill_invalidity")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
turn_clear = sgs.CreatePhaseChangeSkill{
	name = "turn_clear",
	global = true,
	priority = 0,
	on_phasechange = function(self, splayer)
		local room = splayer:getRoom()
		for _, player in sgs.qlist(room:getAlivePlayers()) do
			if player:getPhase() == sgs.Player_RoundStart then
				if splayer:objectName() == player:objectName() then
					--[[
					for _, skill in sgs.qlist(player:getVisibleSkillList()) do
						if player:getMark("Duorui"..skill:objectName()) > 0 then
							room:addPlayerMark(player, "Qingcheng"..skill:objectName())
						end
					end
					]]--
				end
				
				--OL馬良協穆
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("rexiemu"..p:objectName().."_start") > 0 then
						room:setPlayerMark(p, "@ol_xiemu", 0)
					end
				end

				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "_start") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
					end

					--技能清除

					if player:getMark(mark) > 0 and string.find(mark, "_skillstart") then
						if player:hasSkill(string.sub(mark, 1, string.len(mark) - 11)) then
							room:detachSkillFromPlayer(player, string.sub(mark, 1, string.len(mark) - 11))
							room:filterCards(player, player:getCards("h"), true)
						end
						room:setPlayerMark(player, mark, 0)
					end

					--手殺王凌清除「立」標記

					if string.find(mark, "nos_mobile_mouli") and player:getMark(mark) > 0 then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if player:getMark("nos_mobile_mouli"..p:objectName()) > 0 then
								room:setPlayerMark(p, "@mobile_li", 0)
								if p:hasSkill("nos_mobile_mouli_bill") then
									room:detachSkillFromPlayer(p, "nos_mobile_mouli_bill", true)
									room:setPlayerMark(p,"nos_mobile_mouli_has_draw",0)
								end
							end
						end
						room:setPlayerMark(player, mark, 0)
					end
					--手殺周群清除命運籤效果
					if string.find(mark, "mobile_tiansuan_trigger") and player:getMark(mark) > 0 then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if player:getMark("mobile_tiansuan_trigger"..p:objectName()) > 0 then
								room:setPlayerMark(p, "@mobile_tiansuan1", 0)
								room:setPlayerMark(p, "@mobile_tiansuan2", 0)
								room:setPlayerMark(p, "@mobile_tiansuan3", 0)
								room:setPlayerMark(p, "@mobile_tiansuan4", 0)
								room:setPlayerMark(p, "@mobile_tiansuan5", 0)
							end
						end
						room:setPlayerMark(player, mark, 0)
					end

					--手殺羊徽瑜清除「弘儀」標記

					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("mobile_hongyi"..p:objectName().."_target") > 0 then
							room:setPlayerMark(p, "@mobile_hongyi_target", 0)
							room:setPlayerMark(player, "mobile_hongyi"..p:objectName().."_target", 0)
						end
					end

					--手殺袁渙清除「奉節」標記

					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("fengjie"..p:objectName().."_target") > 0 then
							room:setPlayerMark(p, "@fengjie", 0)
							room:setPlayerMark(player, "fengjie"..p:objectName().."_target", 0)
						end
					end

					--界魯肅清除「好施」標記
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("haoshi_po"..p:objectName().."_target") > 0 then
							room:setPlayerMark(p, "@haoshi_po", 0)
							room:setPlayerMark(player, "haoshi_po"..p:objectName().."_target", 0)
						end
					end

					--曹嵩清除「翊正」標記
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("csyizheng"..p:objectName().."_target") > 0 then
							room:setPlayerMark(p, "@csyizheng", 0)
							room:setPlayerMark(player, "csyizheng"..p:objectName().."_target", 0)
						end
					end

					--手殺孫卲清除「定儀」標記

					for _, p in sgs.qlist(room:getAlivePlayers()) do
						for _, mark in sgs.list(p:getMarkNames()) do
							if string.find(mark, "@mobile_dingyi") and p:getMark(mark) > 0 then
								room:setPlayerMark(p, mark, 1)
							end
						end
					end
				end

			end
			
			--以下預防翻面不觸發系統清flag
			if player:hasFlag("weikui_fix") then
				room:setPlayerFlag(player, "-weikui_fix")
			end
			--保險這裡也清一下魅步第三版flag
			if player:hasFlag("meibu_third_rev_range") then
				room:setPlayerFlag(player, "-meibu_third_rev_range")
			end
			if player:hasFlag("twyj_zhuchen_dis_fix") then
				room:setPlayerFlag(player, "-twyj_zhuchen_dis_fix")
			end
		end
	end
}

end_clear = sgs.CreateTriggerSkill{
	name = "end_clear",
	global = true,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, splayer, data, room)
		if splayer:getPhase() == sgs.Player_Discard then
			for _, player in sgs.qlist(room:getAlivePlayers()) do
				if room:getCurrent():objectName() == player:objectName() then
					for _, card in sgs.list(player:getHandcards()) do
						if player:getMark("luoshen"..card:getId().."-Clear") > 0 then
							room:removePlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(card:getId()):toString().."$0")
						end
					end
				end
			end
		elseif splayer:getPhase() == sgs.Player_Play then
			for _, player in sgs.qlist(room:getAlivePlayers()) do
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "_replay") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
						if mark == "wanglie_replay" then
							room:removePlayerCardLimitation(player, "use, response", ".|.|.|hand")
						end
					end
				end
			end
		end
	end
}

--手殺仁區

mobile_ren_area_limit = sgs.CreateTriggerSkill{
	name = "mobile_ren_area_limit",
	global = true,
	events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.Death,sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end



			if player:isAlive() and lord_player:getPile("mobile_ren_area"):length() > 6 then
				local cardIds = sgs.IntList()
				local n = lord_player:getPile("mobile_ren_area"):length() - 6
				for _, id in sgs.qlist( lord_player:getPile("mobile_ren_area") ) do
					if n > 0 then
						cardIds:append(id)
						n = n - 1
					end
				end

				local move2 = sgs.CardsMoveStruct(cardIds, nil, nil, sgs.Player_PlaceSpecial, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move2, false)
			end

		return false
	end
}

mobile_ren_area_transfer = sgs.CreateTriggerSkill{
	name = "mobile_ren_area_transfer",
	global = true,
	events = {sgs.Death,sgs.EventLoseSkill,sgs.EventAcquireSkill},
	priority = -1,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			if player:isAlive() and splayer:getPile("mobile_ren_area"):length() > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local cards = splayer:getPile("mobile_ren_area")
				for _,card in sgs.qlist(cards) do
					dummy:addSubcard(card)
				end
				if cards:length() > 0 then
					player:addToPile("mobile_ren_area", dummy)
				end
				dummy:deleteLater()
			end
		end
		--沒有仁區相關技能時仁區牌棄光
			local lord_player
			for _, pp in sgs.qlist(room:getAlivePlayers()) do
				if pp:isLord() or pp:getMark("@clock_time") > 0 then
					lord_player = pp
					break
				end
			end

			local invoke = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkills("mobile_yuanqing|mobile_shuchen|gebo|mobile_songshu|binglun|liaoyi|mobile_jishi|hxrenshi|debao|buqi") then
					invoke = false
				end
			end

			if invoke and lord_player and lord_player:getPile("mobile_ren_area"):length() > 0 then
				local cardIds = sgs.IntList()
				for _, id in sgs.qlist( lord_player:getPile("mobile_ren_area") ) do
					cardIds:append(id)
				end

				local move2 = sgs.CardsMoveStruct(cardIds, nil, nil, sgs.Player_PlaceSpecial, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "mobile_ren_area_limit", ""))
				room:moveCardsAtomic(move2, false)
			end

		--順便清除神孫策平定標記、司馬徽技能
			local invoke = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkills("yingba|scfuhai") then
					invoke = false
				end
			end

			if invoke then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p , "@pingding", 0)
				end
			end

			local invoke = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("jianjie") then
					invoke = false
				end
			end

			if invoke then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("jianjie_yeyan") then
						room:handleAcquireDetachSkills(player, "-jianjie_yeyan", true)
					end
					if p:hasSkill("jianjie_huoji") then
						room:handleAcquireDetachSkills(player, "-jianjie_huoji", true)
					end
					if p:hasSkill("jianjie_lianhuan") then
						room:handleAcquireDetachSkills(player, "-jianjie_lianhuan", true)
					end

					room:setPlayerMark(p , "@dragon", 0)
					room:setPlayerMark(p , "@phoenix", 0)
				end
			end


	end,
	can_trigger = function(self, target)
		return target
	end
}

--額外目標部分
extra_targetCard = sgs.CreateSkillCard{
	name = "extra_target",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("extra_target_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "extra_target_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets < sgs.Self:getMark("extra_target_num") and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets < sgs.Self:getMark("extra_target_num") and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
	end,
	about_to_use = function(self, room, use)
		room:addPlayerMark(use.to:first(), self:objectName())
		--if use.from:getMark("@fumian1") > 0 or use.from:getMark("ol_fumian1_manmanlai") == 2 then
			for _, p in sgs.qlist(use.to) do
				room:addPlayerMark(p, self:objectName())
			end
		--end
		room:addPlayerMark(use.from, "stop_fumian_bug-Clear")
	end
}

extra_targetVS = sgs.CreateZeroCardViewAsSkill{
	name = "extra_target",
	response_pattern = "@@extra_target",
	view_as = function()
		return extra_targetCard:clone()
	end
}
extra_target = sgs.CreateTriggerSkill{
	name = "extra_target",
	events = {sgs.PreCardUsed},
	view_as_skill = extra_targetVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.from:objectName() == player:objectName() and not use.card:isKindOf("Collateral") and not use.card:isKindOf("EquipCard") and not use.card:isKindOf("SkillCard") then
			--額外目標數
			local x = 0
			if ((player:getMark("fumian2_manmanlai") > 0 and player:getMark("fumian2now_manmanlai") == 0) or (player:getMark("ol_fumian2_manmanlai") == 3 and player:getMark("stop_fumian_bug-Clear") == 0)) and use.card:isRed() then
				if player:getMark("fumian2_manmanlai") > 0 and player:getMark("fumian2now_manmanlai") == 0 and player:getPhase() ~= sgs.Player_NotActive then
					x = x + 1
					if sgs.Self:getMark("@fumian1") > 0 then
						x = x + 1
					end
				end
				if player:getMark("ol_fumian2_manmanlai") == 3 and player:getMark("stop_fumian_bug-Clear") == 0 then
					x = x + 1
					if player:getMark("ol_fumian1_manmanlai") == 2 then
						x = x + 1
					end
				end
			end

			if player:hasSkill("dangmo") and use.card:isKindOf("Slash") then
				x = x + (player:getHp() - 1)
			end

			if player:getMark("@luanz") > 0 and (use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.card:isBlack() and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification"))) then
				x = x + player:getMark("@luanz")
			end

			if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:length() == 1 and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification") and player:getMark("@hf_jieying") > 0 then
				x = x + 1
			end

			if use.card:isKindOf("BasicCard") and use.card:isRed() and player:hasSkill("tongyuan") and player:getMark("tongyuan_Trick") > 0 and player:getMark("tongyuan_Basic") > 0 and (not use.card:isKindOf("Jink")) then
				x = x + 1
			end

			if use.card:isNDTrick() and player:getMark("ol_qirang"..use.card:getEffectiveId().."-Clear") > 0 and use.to:length() == 1 and player:hasSkill("ol_qirang") then
				x = x + 1
			end

			if player:getMark("@zhaosong_song") > 0 and use.card:isKindOf("Slash") and use.to:length() == 1 then
				if room:askForSkillInvoke(player, "zhaoson_song", data) then
					room:removePlayerMark(player, "@zhaosong_song")
					room:setCardFlag(use.card, "zhaosong_song")
					x = x + 2
				end
			end
			room:setPlayerMark(player,"extra_target_num",x)
			if x > 0 then 
-------------------------------------------------------------------------------------
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if use.to:contains(p) or room:isProhibited(player, p, use.card) then
					room:addPlayerMark(p, self:objectName())
					end
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark(self:objectName()) == 0 then
						if use.card:isVirtualCard() then
							room:setPlayerMark(player, "extra_target_virtual_card", 1)
							room:setPlayerMark(player, "extra_target_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
							room:askForUseCard(player, "@@extra_target", "@extra_target:"..player:getMark("extra_target_num"))
							room:setPlayerMark(player, "extra_target_virtual_card", 0)
							room:setPlayerMark(player, "extra_target_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
						elseif not use.card:isVirtualCard() then
							room:setPlayerMark(player, "extra_target_not_virtual_card", 1)
							room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
							room:askForUseCard(player, "@@extra_target", "@extra_target:"..player:getMark("extra_target_num"))
							room:setPlayerMark(player, "extra_target_not_virtual_card", 0)
							room:setPlayerMark(player, "card_id", 0)
						end
						break
					end
				end

				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark(self:objectName()) > 0 and not room:isProhibited(player, p, use.card) then
						room:removePlayerMark(p, self:objectName())
						if not use.to:contains(p) then
							use.to:append(p)
						end
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		elseif use.from:objectName() == player:objectName() and use.card:isKindOf("Collateral") and use.card:isRed() then
			local x = 0
			if player:getMark("fumian2_flag") > 0 and player:getMark("fumian2now_flag") == 0 then
				x = x + 1
				if sgs.Self:getMark("@fumian1") > 0 then
					x = x + 1
				end
			end
			for i = 1, x do
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
				if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then continue end
					if use.card:targetFilter(sgs.PlayerList(), p, player) then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local tos = {}
				for _, t in sgs.qlist(use.to) do
					table.insert(tos, t:objectName())
				end
				room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
				room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
				local used = room:askForUseCard(player, "@@ExtraCollateral", "@qiaoshui-add:::collateral")
				room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(""))
				room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant("+"))
				if not used then return false end
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("ExtraCollateralTarget") then
						p:setFlags("-ExtraColllateralTarget")
						extra = p
						break
					end
				end
				if extra == nil then return false end
				use.to:append(extra)
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
	end
}


if not sgs.Sanguosha:getSkill("clear_mark") then skills:append(clear_mark) end
if not sgs.Sanguosha:getSkill("turn_clear") then skills:append(turn_clear) end
if not sgs.Sanguosha:getSkill("end_clear") then skills:append(end_clear) end
if not sgs.Sanguosha:getSkill("mobile_ren_area_limit") then skills:append(mobile_ren_area_limit) end
if not sgs.Sanguosha:getSkill("mobile_ren_area_transfer") then skills:append(mobile_ren_area_transfer) end
if not sgs.Sanguosha:getSkill("extra_target") then skills:append(extra_target) end

sgs.LoadTranslationTable{
	["#MakeChoice"] = "%from %arg 選擇了： %arg2",
	["wei2"] = "魏", 
	["shu2"] = "蜀",
	["wu2"] = "吳",
	["qun2"] = "群",
	["qun3"] = "群",
	["mobile_ren_area_limit"] = "仁區",
	["@extra_target"] = "你可以額外任意 %src 名角色也成為目標)",
	["~extra_target"] = "選擇若干名角色→點擊確定",

}
--關索
guansuo = sgs.General(extension,"guansuo","shu","4",true)
--其他技能(為了配音)
--武聖
wusheng_gs = sgs.CreateOneCardViewAsSkill{
	name = "wusheng_gs",
	response_or_use = true,
	view_filter = function(self, card)
		if not card:isRed() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
--當先
dangxian_gs = sgs.CreateTriggerSkill{
	name = "dangxian_gs" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			room:setPlayerFlag(player, "dangxian_po_extraphase")
			player:setPhase(sgs.Player_Play)
			room:broadcastProperty(player, "phase")
			local thread = room:getThread()
			if not thread:trigger(sgs.EventPhaseStart, room, player) then
				thread:trigger(sgs.EventPhaseProceeding, room, player)
			end
			thread:trigger(sgs.EventPhaseEnd, room, player)
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			player:setPhase(sgs.Player_RoundStart)
			room:broadcastProperty(player, "phase")
		elseif player:getPhase() == sgs.Player_Play then
			if player:hasFlag("dangxian_po_extraphase") then
				room:setPlayerFlag(player, "-dangxian_po_extraphase")
				room:broadcastSkillInvoke(self:objectName())
				if room:askForSkillInvoke(player, "dangxian_po", data) then
					room:loseHp(player,1)
					local point_six_card = sgs.IntList()
					if room:getDiscardPile():length() > 0 then
						for _,id in sgs.qlist(room:getDiscardPile()) do
							if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
								point_six_card:append(id)
							end
						end
					end
					if not point_six_card:isEmpty() then
						room:obtainCard(player, point_six_card:at(math.random(1,point_six_card:length())-1), false)
					end
				end
			end
		end
		return false
	end
}

--制蠻
zhiman_gs = sgs.CreateTriggerSkill{
	name = "zhiman_gs",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local log = sgs.LogMessage()
		  	log.from = player
			log.to:append(damage.to)
			log.arg = self:objectName()
			log.type = "#Yishi"
			room:sendLog(log)
			room:addPlayerMark(player, self:objectName().."engine")
			room:broadcastSkillInvoke(self:objectName())
			if player:getMark(self:objectName().."engine") > 0 then
				if damage.to:hasEquip() or damage.to:getJudgingArea():length() > 0 then
					local card = room:askForCardChosen(player, damage.to, "ej", self:objectName())
					room:obtainCard(player, card, false)
				end
				room:removePlayerMark(player, self:objectName().."engine")
				return true
			end
		end
		return false
	end
}

--征南
zhengnan = sgs.CreateTriggerSkill{
	name = "zhengnan",
	events = {sgs.Death},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() then return false end
		if player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:drawCards(player, 3, "zhengnan")
			local skilllist = {}
			if (not player:hasSkill("dangxian_gs")) then
				table.insert(skilllist, "dangxian_gs")
			end
			if (not player:hasSkill("wusheng_gs")) then
				table.insert(skilllist, "wusheng_gs")
			end
			if (not player:hasSkill("zhiman_gs")) then
				table.insert(skilllist, "zhiman_gs")
			end
			if #skilllist > 0 then
				sk = skilllist[math.random(1, #skilllist)]
				room:acquireSkill(player, sk)
			end
		end
		return false
	end
}
--頡芳
xiefang = sgs.CreateDistanceSkill{
	name = "xiefang",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return -from:getMark(self:objectName())
		end
		return 0
	end
}
if not sgs.Sanguosha:getSkill("wusheng_gs") then skills:append(wusheng_gs) end
if not sgs.Sanguosha:getSkill("zhiman_gs") then skills:append(zhiman_gs) end
if not sgs.Sanguosha:getSkill("dangxian_gs") then skills:append(dangxian_gs) end
guansuo:addSkill(zhengnan)
guansuo:addSkill(xiefang)
guansuo:addRelateSkill("wusheng_gs")
guansuo:addRelateSkill("zhiman_gs")
guansuo:addRelateSkill("dangxian_gs")

sgs.LoadTranslationTable{
	["guansuo"] = "關索",
	["#guansuo"] = "倜儻孑俠",
	["zhengnan"] = "征南",
	["$zhengnan"] = "末將願承父志，隨丞相出征~",
	[":zhengnan"] = "當其他角色死亡後，你可以摸三張牌。若如此做，你隨機獲得下列技能其中一個：“武聖”、“當先”、“制蠻”",
	["$zhengnan1"] = "末将愿承父志，随丞相出征~",

	["wusheng_gs"] = "武聖",
	[":wusheng_gs"] = "你可以將一張紅色牌當【殺】使用或打出。",
	["zhiman_gs"] = "制蠻",
	[":zhiman_gs"] = "當你對其他角色造成傷害時，你可以防止此傷害，獲得其裝備區或判定區裡的一張牌。",
	["dangxian_gs"] = "當先",
	[":dangxian_gs"] = "回合開始時，你執行一個額外的出牌階段。",

	["$wusheng_gs"] = "逆賊！可識得關氏之勇！",
	["$zhiman_gs"] = "蠻夷可撫，不能剿。",
	["$dangxian_gs"] = "各位將軍，且讓小輩先行出戰！",

	["xiefang"] = "撷芳",
	["xiefang"] = "頡芳",
	[":xiefang"] = "鎖定技，你與其他角色的距離減少X(X為場上女性角色的數量)"
}

--十週年關索
ty_guansuo = sgs.General(extension,"ty_guansuo","shu2","4",true,true)
--征南
ty_zhengnan = sgs.CreateTriggerSkill{
	name = "ty_zhengnan",
	events = {sgs.EnterDying},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
		room:sortByActionOrder(players)
		for _, p in sgs.qlist(players) do			
			if p:isAlive() and player:getMark("ty_zhengnan"..p:objectName()) == 0 then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:addPlayerMark(player, "ty_zhengnan"..p:objectName())
					room:addPlayerMark(player, "@ty_zhengnan")
					room:broadcastSkillInvoke(self:objectName())
					local skilllist = {}
					if (not p:hasSkill("dangxian_gs")) then
						table.insert(skilllist, "dangxian_gs")
					end
					if (not p:hasSkill("wusheng_gs")) then
						table.insert(skilllist, "wusheng_gs")
					end
					if (not p:hasSkill("zhiman_gs")) then
						table.insert(skilllist, "zhiman_gs")
					end
					if #skilllist > 0 then
						sk = skilllist[math.random(1, #skilllist)]
						room:acquireSkill(p, sk)
						room:drawCards(p, 1, "ty_zhengnan")
					else
						room:drawCards(p, 3, "ty_zhengnan")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


ty_guansuo:addSkill(ty_zhengnan)
ty_guansuo:addSkill(xiefang)
ty_guansuo:addRelateSkill("wusheng_gs")
ty_guansuo:addRelateSkill("zhiman_gs")
ty_guansuo:addRelateSkill("dangxian_gs")

sgs.LoadTranslationTable{
	["ty_guansuo"] = "十週年關索",
	["&ty_guansuo"] = "關索",
	["#ty_guansuo"] = "倜儻孑俠",
	["ty_zhengnan"] = "征南",
	["$ty_zhengnan"] = "末將願承父志，隨丞相出征~",
	[":ty_zhengnan"] = "每名角色限一次，當有角色進入瀕死狀態後，你可以摸一張牌並隨機獲得下列技能其中一個：“武聖”、“當先”、“制蠻”；若均已獲得，則改為摸三張牌",
	["$ty_zhengnan1"] = "末将愿承父志，随丞相出征~",


	["$wusheng_gs"] = "逆賊！可識得關氏之勇！",
	["$zhiman_gs"] = "蠻夷可撫，不能剿。",
	["$dangxian_gs"] = "各位將軍，且讓小輩先行出戰！",

	["xiefang"] = "撷芳",
	["xiefang"] = "頡芳",
	[":xiefang"] = "鎖定技，你與其他角色的距離減少X(X為場上女性角色的數量)"
}

--SP龐德
ol_pangde = sgs.General(extension, "ol_pangde", "wei2", "4", true)

juesiCard = sgs.CreateSkillCard{
	name = "juesi", 
	filter = function(self, targets, to_select) 
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix+card:getRange() - sgs.Self:getAttackRange(false)
			rangefix = rangefix+card:getRange() - sgs.Self:getAttackRange(false)
		end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select, rangefix) and not to_select:isNude()
	end, 
	on_use = function(self, room, source, targets)
		local card = room:askForCard(targets[1], ".|.|.|.!", "@juesi", sgs.QVariant(), self:objectName())
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("_"..self:objectName())
		if card and not card:isKindOf("Slash") and source:getHp() <= targets[1]:getHp() and not source:isCardLimited(duel, sgs.Card_MethodUse) and not source:isProhibited(targets[1], duel) then
			room:useCard(sgs.CardUseStruct(duel, source, targets[1]))
		end
		duel:deleteLater()
	end
}
juesi = sgs.CreateOneCardViewAsSkill{
	name = "juesi", 
	filter_pattern = "Slash", 
	view_as = function(self, card) 
		local cards = juesiCard:clone()
		cards:addSubcard(card)
		return cards
	end
}

ol_pangde:addSkill(juesi)
ol_pangde:addSkill("mashu")

sgs.LoadTranslationTable{
["ol_pangde"] = "SP龐德",
["&ol_pangde"] = "龐德",
["#ol_pangde"] = "抬櫬之悟",
["juesi"] = "決死",
[":juesi"] = "出牌階段，你可以棄置一張【殺】並選擇一名攻擊範圍內的有牌的角色，令其棄置一張牌，若之不為【殺】且你的體力值不大於其，視為對其使用【決鬥】。",
["$juesi1"] = "死都不怕，還能怕你？",
["$juesi2"] = "抬棺而戰，不死不休~",
["~ol_pangde"] = "受魏王厚恩，唯以死報之~",
["@juesi"] = "請棄置一張牌<br/> <b>操作提示</b>: 選擇一一張牌→點擊確定<br/>",
}

--兀突骨
wutugu = sgs.General(extension, "wutugu", "qun2", "15", true)
--燃殤:鎖定技，當你受到1點火焰傷害後，你獲得1枚“燃”標記；結束階段開始時，你失去X點體力（X為“燃”標記的數量）。
ranshang = sgs.CreateTriggerSkill{
	name = "ranshang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Fire then
				room:sendCompulsoryTriggerLog(player, "ranshang") 
				room:broadcastSkillInvoke(self:objectName(),1)
				player:gainMark("@ranshang",damage.damage)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:getMark("@ranshang") > 0 then
				room:sendCompulsoryTriggerLog(player, "ranshang")
				room:broadcastSkillInvoke(self:objectName(),2) 
				room:loseHp(player, player:getMark("@ranshang"))

				if player:getMark("@ranshang") >= 2 then
					room:loseMaxHp(player, 2)
					player:drawCards(2)
				end
			end
		end
	end,
}
--悍勇:當你使用【南蠻入侵】或【萬箭齊發】時，若你的體力值小於遊戲輪數，你可以令此牌造成的傷害+1。
hanyong = sgs.CreateTriggerSkill{
	name = "hanyong",
	events = {sgs.CardUsed, sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local lord_player
			for _, pp in sgs.qlist(room:getAlivePlayers()) do
				if pp:isLord() or pp:getMark("@clock_time") > 0 then
					lord_player = pp
					break
				end
			end
			if lord_player and player:getHp() < lord_player:getMark("@clock_time") then
				local use = data:toCardUse()
				if (use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") or (use.card:isKindOf("Slash") and use.card:getSuit() == sgs.Card_Spade)) and room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")

					if player:getHp() > lord_player:getMark("@clock_time") then
						player:gainMark("@ranshang",damage.damage)
					end

					if player:getMark(self:objectName().."engine") > 0 then
						room:setCardFlag(use.card, self:objectName())
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
			--end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag(self:objectName()) then
				local log = sgs.LogMessage()
				log.type = "$hanyong"
				log.from = player
				log.card_str = damage.card:toString()
				log.arg = self:objectName()
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished and data:toCardUse().card:hasFlag(self:objectName()) then
			--room:clearCardFlag(data:toCardUse().card)
			room:setCardFlag(data:toCardUse().card, "-"..self:objectName())
		end
		return false
	end
}
wutugu:addSkill(ranshang)
wutugu:addSkill(hanyong)

sgs.LoadTranslationTable{
	["wutugu"] = "兀突骨",
	["&wutugu"] = "兀突骨",
	["#wutugu"] = "",
	["ranshang"] = "燃殤",
	--[":ranshang"] = "鎖定技，當你受到1點火焰傷害後，你獲得1枚“燃”標記；結束階段開始時，你失去X點體力（X為“燃”標記的數量）。",
	[":ranshang"] = "鎖定技，當你受到1點火焰傷害後，你獲得1枚「燃」標記；結束階段，你失去X點體力（X為「燃」標記的數量），然後若「燃」標記的數量超過2個，則你減2點體力上限並摸兩張牌。",
	["hanyong"] = "悍勇",
	--[":hanyong"] = "當你使用【南蠻入侵】或【萬箭齊發】時，若你的體力值小於遊戲輪數，你可以令此牌造成的傷害+1。",
	[":hanyong"] = "當你使用【南蠻入侵】、【萬箭齊發】或黑桃普通【殺】時，若你已受傷，你可以令此牌造成的傷害+1。然後若你的體力值大於遊戲輪數，你獲得一個「燃」標記。",
	["$ranshang1"] = "战火燃尽英雄胆~",
	["$ranshang2"] = "尔等竟如此歹毒！",
	["@ranshang"] = "燃",
	["$hanyong"] = "%from 發動技能 ”%arg“ ，%card 的傷害值 +1 ",
	["$hanyong1"] = "犯我者，杀！",
	["$hanyong2"] = "藤甲军从无对手，不服来战！",
}

--OL趙襄
ol_zhaoxiang = sgs.General(extension, "ol_zhaoxiang", "shu2", "4", false,true)

--芳魂
ol_fanghunCard = sgs.CreateSkillCard{
	name = "ol_fanghun",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		if self:subcardsLength() ~= 0 and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local targets_list = sgs.PlayerList()
			for _, target in ipairs(targets) do
				targets_list:append(target)
			end
			local aocaistring = self:getUserString()
			local slash = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
			slash:addSubcard(self:getSubcards():first())
			slash:setSkillName("longdan")
			slash:deleteLater()
			return slash:targetFilter(targets_list, to_select, sgs.Self)
		end
		return false
	end,
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and self:getUserString() == "slash" then
			return #targets > 0
		else
			return #targets == 0
		end
	end,
	on_validate = function(self, use)
		local data = sgs.QVariant()
		data:setValue(use.from)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), card:getSuit(), card:getNumber())
		use_card:setSkillName("longdan")
		use_card:addSubcard(self:getSubcards():first())
		for _, to in sgs.qlist(use.to) do
			if use.from:getRoom():isProhibited(use.from, to, use_card) then
				use.to:removeOne(to)
			end
		end
		use_card:deleteLater()
		skill(self, use.from:getRoom(), use.from, true)
		use.from:loseMark("@meiying")
		room:addPlayerMark(player,"ol_fanghun")
		use.from:drawCards(1, self:objectName())
		return use_card
	end,
	on_validate_in_response = function(self, player)
		local data = sgs.QVariant()
		data:setValue(player)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), card:getSuit(), card:getNumber())
		use_card:setSkillName("longdan")
		use_card:addSubcard(self:getSubcards():first())
		use_card:deleteLater()
		skill(self, player:getRoom(), player, true)
		player:loseMark("@meiying")
		room:addPlayerMark(player,"ol_fanghun")
		player:drawCards(1, self:objectName())
		return use_card
	end
}
ol_fanghunVS = sgs.CreateOneCardViewAsSkill{
	name = "ol_fanghun",
	response_or_use = true,
	view_filter = function(self, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return to_select:isKindOf("Jink")
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "slash" then
				return to_select:isKindOf("Jink")
			else
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, card)
		local dragon = "jink"
		if card:isKindOf("Jink") then
			dragon = "slash"
		end
		local cards = ol_fanghunCard:clone()
		cards:addSubcard(card)
		cards:setUserString(dragon)
		return cards
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getMark("@meiying") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink") and player:getMark("@meiying") > 0
	end
}
ol_fanghun = sgs.CreateTriggerSkill{
	name = "ol_fanghun",
	view_as_skill = ol_fanghunVS,
	events = {sgs.Damage,sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					player:gainMark("@meiying",damage.damage)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					player:gainMark("@meiying",damage.damage)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
--扶漢
ol_fuhan = sgs.CreateTriggerSkill{
	name = "ol_fuhan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@ol_fuhan", 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local x = player:getMark("ol_fanghun") + player:getMark("@meiying")
			if player:getPhase() == sgs.Player_RoundStart and x > 0 and player:getMark("@ol_fuhan") > 0 then				
				if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("up:"..x)) then
					room:removePlayerMark(player, "@ol_fuhan")
					room:notifySkillInvoked(player,self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("ol_zhaoxiang","ol_fuhan")

					player:drawCards(x)
					x = math.max(x,2)

					local Chosens = {}
					local generals = generate_all_general_list(player, {"shu","shu2"}, {})
					for i = 1, 5 , 1 do
						if #generals > 0 then
							local j = math.random(1, #generals)
							local getGeneral = generals[j]
							table.insert(Chosens, getGeneral)
							table.remove(generals, j)

							local log = sgs.LogMessage()
							log.type = "#getGeneralCard"
							log.from = player	
							log.arg = getGeneral
							room:sendLog(log)

						end
					end
	
					local general = room:askForGeneral(player, table.concat(Chosens, "+"))
					local isSecondaryHero = not (sgs.Sanguosha:getGeneral(player:getGeneralName()):hasSkill("ol_fuhan"))
					local original_kingdom = player:getKingdom()
					room:changeHero(player, general, false, true, isSecondaryHero)
					room:setPlayerProperty(player,"kingdom",sgs.QVariant(original_kingdom))		
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(x))
					room:setPlayerMark(player, "@meiying", 0)
					room:setPlayerMark(player, "ol_fanghun", 0)
					if player:getMaxHp() > player:getHp() then
						local theRecover = sgs.RecoverStruct()
						theRecover.recover = 1
						theRecover.who = player
						room:recover(player, theRecover)
					end
				end
			end
		end
	end,
}
ol_zhaoxiang:addSkill(ol_fanghun)
ol_zhaoxiang:addSkill(ol_fuhan)

sgs.LoadTranslationTable{
	["ol_zhaoxiang"] = "OL趙襄",
	["&ol_zhaoxiang"] = "趙襄",
	["#ol_zhaoxiang"] = "驚鴻魅影",
	["ol_fanghun"] = "芳魂",
	[":ol_fanghun"] = "鎖定技，每當妳使用【殺】造成1點傷害；或受到【殺】造成的1點傷害後，妳獲得1個“梅影”標記；妳可以移去1個“梅影”標記來發動“龍膽”並摸一張牌",
	["ol_fuhan"] = "扶漢",
	[":ol_fuhan"] = "限定技，回合開始時，妳可以移去所有“梅影”標記並摸相同數量的牌，隨機觀看五名未登場的角色，將武將牌替換為其中一名角色，並將體力上限數調整為本局遊戲中移去“梅影”標記的數量(最小為3)，然後若妳的體力小於體力上限，妳恢復一點體力",
	["@meiying"] = "梅影",
	["$ol_fanghun1"] = "萬花凋落盡，一梅獨傲霜。",
	["$ol_fanghun2"] = "暗香疏影處，凌風踏雪來~",
	["ol_fuhan:up"] = "你想發動“扶漢”令体力上限為 %src 嗎?",
	["$ol_fuhan1"] = "承先父之志，扶漢興劉~",
	["$ol_fuhan2"] = "天將降大任於我！",
	["ol_fuhan:up"] = "你想發動「扶漢」令體力上限為%src嗎?",
}

--趙襄
zhaoxiang = sgs.General(extension, "zhaoxiang", "shu", "4", false)
--芳魂
fanghunCard = sgs.CreateSkillCard{
	name = "fanghun",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		if self:subcardsLength() ~= 0 and (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local targets_list = sgs.PlayerList()
			for _, target in ipairs(targets) do
				targets_list:append(target)
			end
			local aocaistring = self:getUserString()
			local slash = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
			slash:addSubcard(self:getSubcards():first())
			slash:setSkillName("longdan")
			slash:deleteLater()
			return slash:targetFilter(targets_list, to_select, sgs.Self)
		end
		return false
	end,
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and self:getUserString() == "slash" then
			return #targets > 0
		else
			return #targets == 0
		end
	end,
	on_validate = function(self, use)
		local data = sgs.QVariant()
		data:setValue(use.from)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), card:getSuit(), card:getNumber())
		use_card:setSkillName("longdan")
		use_card:addSubcard(self:getSubcards():first())
		for _, to in sgs.qlist(use.to) do
			if use.from:getRoom():isProhibited(use.from, to, use_card) then
				use.to:removeOne(to)
			end
		end
		use_card:deleteLater()
		skill(self, use.from:getRoom(), use.from, true)
		use.from:loseMark("@meiying")
		use.from:drawCards(1, self:objectName())
		return use_card
	end,
	on_validate_in_response = function(self, player)
		local data = sgs.QVariant()
		data:setValue(player)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), card:getSuit(), card:getNumber())
		use_card:setSkillName("longdan")
		use_card:addSubcard(self:getSubcards():first())
		use_card:deleteLater()
		skill(self, player:getRoom(), player, true)
		player:loseMark("@meiying")
		player:drawCards(1, self:objectName())
		return use_card
	end
}
fanghunVS = sgs.CreateOneCardViewAsSkill{
	name = "fanghun",
	response_or_use = true,
	view_filter = function(self, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return to_select:isKindOf("Jink")
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "slash" then
				return to_select:isKindOf("Jink")
			else
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, card)
		local dragon = "jink"
		if card:isKindOf("Jink") then
			dragon = "slash"
		end
		local cards = fanghunCard:clone()
		cards:addSubcard(card)
		cards:setUserString(dragon)
		return cards
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getMark("@meiying") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink") and player:getMark("@meiying") > 0
	end
}


fanghun = sgs.CreateTriggerSkill{
	name = "fanghun",
	events = {sgs.TargetSpecified, sgs.TargetConfirmed},
	view_as_skill = fanghunVS,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.from and use.to and use.card and (((event == sgs.TargetConfirmed and use.to:contains(player) and use.from:objectName() ~= player:objectName()) or (event == sgs.TargetSpecified and use.from:objectName() == player:objectName())))
		and not use.card:isKindOf("SkillCard") and use.card:isKindOf("Slash") then
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				player:gainMark("@meiying",1)
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}
--扶漢
fuhan = sgs.CreateTriggerSkill{
	name = "fuhan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@fuhan",
	view_as_skill = fuhanVS, 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart and player:getMark("@meiying") > 0 and player:getMark("@fuhan") > 0 then
				if room:askForSkillInvoke(player, "fuhan", data) then

					local x = player:getMark("@meiying")
					room:removePlayerMark(player, "@fuhan")
				 	player:drawCards(x)
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("zhaoxiang","fuhan")
					room:notifySkillInvoked(player,self:objectName())

					local Huashens = {}
					local generals = generate_all_general_list(player, {"shu","shu2"}, {})
					for i2 = 1, 5, 1 do
						if #generals > 0 then
							local n = math.random(1, #generals)
							local log = sgs.LogMessage()
							log.type = "#getGeneralCard"
							log.from = player	
							log.arg = generals[n]
							room:sendLog(log)

							table.insert(Huashens, generals[n])
							table.remove(generals, n)
						end
					end
					--local general_name = room:askForGeneral(player, table.concat(Huashens, "+"))	
					--local general = sgs.Sanguosha:getGeneral(general_name)		
					--for _,sk in sgs.qlist(general:getVisibleSkillList()) do
					--	room:acquireSkill(player, sk)
					--end

					local sks = {}
						
					for _,general_name in ipairs(Huashens) do		
						local general = sgs.Sanguosha:getGeneral(general_name)
						for _,sk in sgs.qlist(general:getVisibleSkillList()) do
							--if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake and
							--  not string.find(sk:getDescription(), sgs.Sanguosha:translate("MissionSkill")) and not string.find(sk:getDescription(), sgs.Sanguosha:translate("KingdomSkill"))  then
							if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
								local can_use = true
								for _,p in sgs.qlist( room:getAlivePlayers() ) do
									if p:hasSkill(sk:objectName()) then
										can_use = false
									end
								end
								if can_use then
									table.insert(sks, sk:objectName())
								end
							end
						end
					end


					for i = 1,2 do
						local choice = room:askForChoice(player, "qianhuan", table.concat(sks, "+"))
						table.removeOne(sks, choice)
						if not player:hasSkill(choice) then			
							room:acquireSkill(player, choice)
						end
					end
					

					
					room:setPlayerMark(player, "@meiying", 0)

					local player_hp = {}
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						table.insert(player_hp, p:getHp())
					end

					if player:getHp() == math.min(unpack(player_hp)) then
						local theRecover = sgs.RecoverStruct()
						theRecover.recover = 1
						theRecover.who = player
						room:recover(player, theRecover)
					end
				end
			end
		end
	end,
}
zhaoxiang:addSkill(fanghun)
zhaoxiang:addSkill(fuhan)

sgs.LoadTranslationTable{
	["zhaoxiang"] = "趙襄",
	["#zhaoxiang"] = "驚鴻魅影",
	["fanghun"] = "芳魂",
	[":fanghun"] = "當妳使用【殺】指定目標；或成為【殺】的目標後，妳獲得1個“梅影”標記；妳可以移去1個“梅影”標記來發動“龍膽”並摸一張牌",
	["fuhan"] = "扶漢",
	[":fuhan"] = "限定技，回合開始時，妳可以移去所有“梅影”標記並摸相同數量的牌，然後從五張未加入遊戲的蜀勢力武將牌中選擇並獲得至多兩個技能（鎖定技、覺醒技、主公技除外），然後若妳的體力值最小，妳恢復一點體力",
	["@meiying"] = "梅影",
	["$fanghun1"] = "萬花凋落盡，一梅獨傲霜。",
	["$fanghun2"] = "暗香疏影處，凌風踏雪來~",
	["$fuhan1"] = "承先父之志，扶漢興劉~",
	["$fuhan2"] = "天將降大任於我！",
	["MissionSkill"] = "使命技",
	["KingdomSkill"] = "勢力技",
}

--戲志才
xizhicai = sgs.General(extension, "xizhicai", "wei", "3", true)
--天妒

--先輔
--[[
xianfu = sgs.CreateTriggerSkill{
	name = "xianfu" ,
	events = {sgs.GameStart,sgs.HpRecover,sgs.Damage} ,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:hasSkill("xianfu") then
			room:notifySkillInvoked(player,self:objectName())
			local q = room:askForPlayerChosen(player, room:getOtherPlayers(player), "xianfu", "@xianfu-choose", true)
			if q then
				room:doAnimate(1, player:objectName(), q:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				q:gainMark("@xianfu", 1)
				room:setPlayerMark(q,"xianfu"..player:objectName()..q:objectName(),1)
				local msg = sgs.LogMessage()
				msg.type = "#xianfu"
				msg.from = player
				msg.to:append(q)
				msg.arg = self:objectName()
				room:sendLog(msg)
			else
				local q
				local _targets = room:getOtherPlayers(player)
				local length = _targets:length()
				local n = math.random(1, length)
				local q = _targets:at(n-1)
				room:setPlayerMark(q,"xianfu"..player:objectName()..q:objectName(),1)
				room:doAnimate(1, player:objectName(), q:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				q:gainMark("@xianfu", 1)
				local msg = sgs.LogMessage()
				msg.type = "#xianfu"
				msg.from = player
				msg.to:append(q)
				msg.arg = self:objectName()
				room:sendLog(msg)
			end
		elseif event == sgs.HpRecover then
			if not player:isAlive() then return false end
			if player:getMark("@xianfu") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("xianfu") and player:getMark("xianfu"..p:objectName()..player:objectName()) == 1 then
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(5,6))
						room:notifySkillInvoked(p,self:objectName())
						local rec = data:toRecover()
						local recover = sgs.RecoverStruct()
						recover.who = rec.who
						recover.recover = rec.recover
						room:recover(p, recover)
					end
				end
			end
			return false
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to:getMark("@xianfu") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("xianfu") and damage.to:getMark("xianfu"..p:objectName()..damage.to:objectName()) == 1 then
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
						room:notifySkillInvoked(p,self:objectName())
						local damage2 = sgs.DamageStruct()
						damage2.from = damage.from
						damage2.to = p
						damage2.damage = damage.damage
						damage2.nature = damage.nature
						room:damage(damage2)
					end
				end
			end
		end
	end
}
]]--

xianfu = sgs.CreateTriggerSkill{
	name = "xianfu",
	events = {sgs.GameStart, sgs.HpRecover, sgs.Damaged},
	global = true,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and RIGHT(self, player) then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xianfu-invoke", false, sgs.GetConfig("face_game", true))
			if to then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--room:addPlayerMark(to, "@xianfu")
					room:addPlayerMark(to, "fu"..player:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		else
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark("fu"..p:objectName()) > 0 and player:isAlive() then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					if player:getMark("@xianfu") == 0 then
						room:addPlayerMark(player, "@xianfu")
					end
					if event == sgs.Damaged then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
						room:damage(sgs.DamageStruct(self:objectName(), nil, p, data:toDamage().damage))
					else
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
						room:recover(p, sgs.RecoverStruct(p, nil, data:toRecover().recover))
					end
				end
			end
		end
		return false
	end
}

--籌策 
chouce = sgs.CreateTriggerSkill{
	name = "chouce",
	events = {sgs.Damaged, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			for i = 0, damage.damage - 1, 1 do
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player,self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.play_animation = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge.card:isRed() then
						local to_draw = room:askForPlayerChosen(player, room:getAlivePlayers(), "chouce1", "@chouce-draw", true)
						if to_draw then
							room:doAnimate(1, player:objectName(), to_draw:objectName())
							room:broadcastSkillInvoke(self:objectName(), 1)
							if to_draw:getMark("@xianfu") > 0 then
								room:drawCards(to_draw, 2, "chouce")
							else
								room:drawCards(to_draw, 1, "chouce")
							end
						end
					elseif judge.card:isBlack() then
						local _targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if player:canDiscard(p, "hej") then _targets:append(p) end
						end
						if not _targets:isEmpty() then
							local to_discard = room:askForPlayerChosen(player, _targets, "chouce2", "@chouce-discard", true)
							if to_discard then
								room:broadcastSkillInvoke(self:objectName(), 2)
								room:doAnimate(1, player:objectName(), to_discard:objectName())
								room:throwCard(room:askForCardChosen(player, to_discard, "hej", "chouce", false, sgs.Card_MethodDiscard), to_discard, player)
							end
						end
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = sgs.JudgeStruct()
			if judge.reason ~= self:objectName() then return false end
			judge.pattern = tostring(judge.card:getSuit())
		end
		return false
	end
}
xizhicai:addSkill("tiandu")
xizhicai:addSkill(xianfu)
xizhicai:addSkill(chouce)

sgs.LoadTranslationTable{
	["xizhicai"] = "戲志才",
	["#xizhicai"] = "負俗天才",
	["tiandu_lua"] = "天妒",
	[":tiandu_lua"] = "每當你的判定牌生效後，你可以獲得之。",
	["xianfu"] = "先輔",
	["@xianfu"] = "先輔",
	[":xianfu"] = "鎖定技，遊戲開始時，你選擇一名其他角色，當其受到傷害後，你受到等量的傷害，當其回復體力後，你回復等量的體力。",
	["chouce"] = "籌略",
	["chouce1"] = "籌略",
	["chouce2"] = "籌略",
	[":chouce"] = "當你受到1點傷害後，你可以判定，若結果為：黑色，你棄置一名角色區域裡的一張牌；紅色，你選擇一名角色，其摸一張牌，若其是“先輔”選擇的角色，改為其摸兩張牌",
	["xianfu-invoke"]="你選擇一名其他角色（當其受到傷害後，你受到等量的傷害，當其回復體力後，你回復等量的體力）",
	["@chouce-draw"] = "請選擇一名角色，令其摸一張牌，若其是“先輔”選擇的角色，改為其摸兩張牌",
	["@chouce-discard"] = "請選擇一名角色，你棄置其區域里的一张牌",
	["#xianfu"] = "%from %arg 選擇的角色為： %to",
}

--步騭
buzhi = sgs.General(extension, "buzhi", "wu", "3", true)

hongde = sgs.CreateTriggerSkill{
	name = "hongde",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if (not room:getTag("FirstRound"):toBool()) and move.card_ids:length() >= 2 and ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) or (move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))) then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "hongde-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					target:drawCards(1, self:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}


--【定叛】出牌阶段限X次，你可以令一名装备区里有牌的角色摸一张牌，然后其选择一项：1.令你弃置其装备区里的一张牌；2.获得其装备区里的所有牌，若如此做，你对其造成1点伤害（X为场上存活的反贼数）。
dingpanCard = sgs.CreateSkillCard{
	name = "dingpan" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:getEquips():length() > 0
	end,
	on_use = function(self, room, source, targets)	
		room:drawCards(targets[1], 1, "dingpan")	
		local choices = {"dingpan1", "dingpan2"}
		local choice = room:askForChoice(targets[1], "dingpan", table.concat(choices, "+"))
		local msg = sgs.LogMessage()
		msg.type = "#MakeChoice"
		msg.from = targets[1]
		msg.arg = "dingpan"
		msg.arg2 = choice
		room:sendLog(msg)
		if choice == "dingpan1" then
			local id = room:askForCardChosen(source, targets[1], "e", "dingpan") 
			room:throwCard(id, targets[1], source)
		elseif choice == "dingpan2" then
			local ids = sgs.IntList()
			for _, jcard in sgs.qlist(targets[1]:getEquips()) do
				ids:append(jcard:getEffectiveId())
			end
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = targets[1]
			move.to_place = sgs.Player_PlaceHand
			room:moveCardsAtomic(move, true)
			room:damage(sgs.DamageStruct(nil,source,targets[1],1,sgs.DamageStruct_Normal))
		end
	end
}

dingpan = sgs.CreateZeroCardViewAsSkill{
	name = "dingpan",
	view_as = function()
		return dingpanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#dingpan") < player:getMark("dingpan")
	end
}

buzhi:addSkill(hongde)
buzhi:addSkill(dingpan)
sgs.LoadTranslationTable{
	["buzhi"] = "步騭",
	["&buzhi"] = "步騭",
	["#buzhi"] = "寬宏折節",
	["hongde"] = "弘德",
	["#hongde"] = "弘德",
	["dingpan"] = "定叛",
	[":hongde"] = "當你一次性獲得或失去至少兩張牌時，你可以令一名其他角色摸一張牌。",
	[":dingpan"] = "出牌階段限Ｘ次，你可以選擇一名裝備區內有牌的角色，令其摸一張牌，然後令其選擇一項：1.你棄置其一張裝備牌；2.收回裝備區裡的牌，你對其造成1點傷害。(Ｘ為場上存活的反賊數)",
	["hongde-invoke"] = "你可以發動「弘德」令一名其他角色摸一張牌",
	["dingpan1"] = "棄置一張裝備牌",
	["dingpan2"] = "收回裝備區的牌，然後受到發起者造成的1點傷害",
	["$hongde1"] = "德無單行，福必雙至。",
	["$hongde2"] = "江南重義，東吳尚德。",
	["$dingpan1"] = "從孫者生，從劉者死！",
	["$dingpan2"] = "多行不義，必自斃！",
}
--闞澤
kanze = sgs.General(extension, "kanze", "wu", 3, true)
--下書
xiashu = sgs.CreatePhaseChangeSkill{
	name = "xiashu" ,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xiashu-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:obtainCard(target, player:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""), false)
					if not target:isNude() then
					--local cards = room:askForExchange(target, self:objectName(), target:getHandcardNum(), 1, false, "@xiashu")
					local cards = room:askForExchange(target, self:objectName(), target:getHandcardNum(), 1, false, "@xiashu-invoke")
					local list = target:getCards("h")
					for _,id in sgs.qlist(cards:getSubcards()) do
						room:showCard(target, id)
						list:removeOne(sgs.Sanguosha:getCard(id))
					end
					local choices = {"xiashu1"}
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					if not list:isEmpty() then
						table.insert(choices, "xiashu2")
						dummy:addSubcards(list)
					end
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
						if choice == "xiashu1" then
							room:obtainCard(player, cards, false)
						else
							room:obtainCard(player, dummy, false)
						end
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
kanze:addSkill(xiashu)
--寬釋
kuanshi = sgs.CreatePhaseChangeSkill{
	name = "kuanshi",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "kuanshi-invoke", true, false)
			if target then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
						skill(self, room, player, false)
						--room:addPlayerMark(target, "kuanshi_start")
						--room:addPlayerMark(player, "kuanshi"..target:objectName()..target:getMark("kuanshi_start"))
						room:addPlayerMark(target, "kuanshi_target_"..player:objectName())
						room:addPlayerMark(player, "kuanshi_player_"..player:objectName())

					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("kuanshi_target") or p:getMark("@kuanshi_target") then
					room:removePlayerMark(p, "kuanshi_target_"..player:objectName())
					room:removePlayerMark(p, "@kuanshi_target_"..player:objectName())
					room:removePlayerMark(player, "kuanshi_player_"..player:objectName())
					room:removePlayerMark(player, "@kuanshi_player_"..player:objectName())
				end
			end
		end
		return false
	end
}

kanze:addSkill(kuanshi)

sgs.LoadTranslationTable{
["kanze"] = "闞澤",
["#kanze"] = "慧眼的博士",
["illustrator:kanze"] = "LiuHeng",
--["cv:kanze"] = "倪康"​​,
["xiashu"] = "下書",
["xiashu-invoke"] = "你可以發動“下書”<br/> <b>操作提示</b>: 選擇一名其他角色→點擊確定<br/>",
["@xiashu-invoke"] = "請展示若干張牌<br/> <b>操作提示</b>: 選擇若干張牌→點擊確定<br/>",
["xiashu1"] = "獲得其展示的牌",
["xiashu2"] = "獲得其未展示的手牌",
[":xiashu"] = "出牌階段開始時，你可以將所有手牌交給一名角色，然後令其展示至少一張手牌，你選擇一項：1.獲得其展示的牌；2 .獲得其未展示的手牌。",
["$xiashu1"] = "吾有密信，特來獻予將軍。",
["$xiashu2"] = "將軍若不信，可親自驗看。",
["kuanshi"] = "寬釋",
["kuanshi-invoke"] = "你可以發動“寬釋”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
[":kuanshi"] = "結束階段開始時，你可以選擇一名角色，若如此做，當其於你的下回合開始前受到下一次大於1點的傷害時，防止此傷害，然後你跳過下回合的摸牌階段。",
["$kuanshi1"] = "不知者，無罪~",
["$kuanshi2"] = "罰酒三杯，下不為例~",
["~kanze"] = "我~早已做好了犧牲的準備~",
}
--嚴白虎
yanbaihu = sgs.General(extension, "yanbaihu", "qun2", "4", true)
--雉盜
zhidao = sgs.CreateTriggerSkill{
	name = "zhidao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if not damage.to:isAllNude() and damage.to:objectName() ~= player:objectName() and player:getPhase() == sgs.Player_Play and player:getMark("zhidao_Play") == 0 then
			SendComLog(self, player)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				if not damage.to:isKongcheng() then
					local id1 = room:askForCardChosen(player, damage.to, "h", self:objectName())
					dummy:addSubcard(id1)
				end
				if not damage.to:getEquips():isEmpty() then
					local id2 = room:askForCardChosen(player, damage.to, "e", self:objectName())
					dummy:addSubcard(id2)
				end
				if not damage.to:getJudgingArea():isEmpty() then
					local id3 = room:askForCardChosen(player, damage.to, "j", self:objectName())
					dummy:addSubcard(id3)
				end
				if dummy:subcardsLength() > 0 then
					room:obtainCard(player, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
					room:addPlayerMark(player, "zhidao_Play")
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
zhidaoPS = sgs.CreateProhibitSkill{
	name = "#zhidaoPS",
	is_prohibited = function(self, from, to, card)
		return from:hasSkill("zhidao") and not card:isKindOf("SkillCard") and from:objectName() ~= to:objectName() and from:getMark("zhidao_Play") ~= 0
	end
}
--寄黎
jili = sgs.CreateTriggerSkill{
	name = "jili" ,
	events = {sgs.TargetConfirming} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local s = room:findPlayerBySkillName(self:objectName())
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if use.card and use.from and use.to and use.card:isRed() and use.from:objectName() ~= p:objectName()
				 and not use.to:contains(p) and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
				 and not use.card:isKindOf("Collateral") and player:distanceTo(p) == 1 
				 and not room:isProhibited(use.from, p, use.card) then
	
					room:sendCompulsoryTriggerLog(p, "jili") 			
					room:notifySkillInvoked(p, "jili")
					if use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo") or use.card:isKindOf("Analeptic") then
						room:broadcastSkillInvoke("jili", 2)
					else
						room:broadcastSkillInvoke("jili", 1)
					end
					use.to:append(p)
					room:sortByActionOrder(use.to)
					--room:getThread():trigger(sgs.TargetConfirming, room, p, data)
					local msg = sgs.LogMessage()
					msg.type = "#Jili"
					msg.from = p
					msg.to:append(player)
					msg.card_str = use.card:toString()
					room:sendLog(msg)
					data:setValue(use)
				end
			end		
		end		
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

yanbaihu:addSkill(zhidao)
yanbaihu:addSkill(zhidaoPS)
yanbaihu:addSkill(jili)
extension:insertRelatedSkills("zhidao","#zhidaoPS")

sgs.LoadTranslationTable{
	["yanbaihu"] = "嚴白虎",
	["#yanbaihu"] = "豺牙落澗",
	["zhidao"] = "雉盜",
	["jili"] = "寄籬",
	[":zhidao"] = "鎖定技，當你於出牌階段內第一次對區域裡有牌的其他角色造成傷害後，你獲得其手牌、裝備區和判定區裡的各一張牌，然後直到回合結束，其他角色不能被選擇為你使用牌的目標。",
	[":jili"] = "鎖定技，當一名其他角色成為一張紅色基本牌/非延時錦囊牌的目標時，若該角色與你的距離為1，且你不是此牌的使用者或目標，你成為此牌的額外目標。",
	["#Jili"] = "%from 受到技能 “<font color=\"yellow\"><b>寄籬</b></font>”的影響，成為了 %card 的額外目標 ",
["$zhidao1"] = "誰有地盤，誰（就）是老大！",
["$zhidao2"] = "亂世之中，能者為王！",
["$jili1"] = "寄人籬下的日子，不好過啊~",
["$jili2"] = "這份恩德，白虎記下了~",
}

--李通 4血 稱號：萬億吾獨往
litong = sgs.General(extension, "litong", "wei2", "4", true)

--推鋒 
tuifeng = sgs.CreateTriggerSkill{
	name = "tuifeng",
	events ={sgs.Damaged, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			for i = 1, damage.damage, 1 do
				if not player:isNude() then
					--local id = room:askForExchange(player, self:objectName(), 1, 1, true, "tuifeng-invoke", true):getSubcards():first()
					local tuifeng_card = room:askForExchange(player, self:objectName(), 1, 1, true, "#tuifeng", true)
					local id = -1
					if tuifeng_card then
						id = tuifeng_card:getSubcards():first()
					end
					if id ~= -1 then
						skill(self, room, player, true, 2)
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							player:addToPile("feng", id, false)
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_Start then
				local x = player:getPile("feng"):length()
				if x > 0 then
					room:sendCompulsoryTriggerLog(player,self:objectName(),true)
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:addPlayerMark(player, self:objectName().."engine", 2)
					if player:getMark(self:objectName().."engine") > 0 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _,cd in sgs.qlist(player:getPile("feng")) do
							dummy:addSubcard(cd)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", player:objectName(), self:objectName(), "")
						room:throwCard(dummy, reason, nil)
						player:drawCards(2*x)
						room:addPlayerMark(player, "@Slash-Clear", x)
						room:removePlayerMark(player, self:objectName().."engine", 2)
					end
				end
			end
		end
	end
}
tuifengtm = sgs.CreateTargetModSkill{
	name = "#tuifengtm",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("tuifeng") then
			return player:getMark("@Slash-Clear")
		end
	end,
}

litong:addSkill(tuifeng)
litong:addSkill(tuifengtm)
extension:insertRelatedSkills("tuifeng","#tuifengtm")

sgs.LoadTranslationTable{
	["litong"] = "李通",
	["#litong"] = "萬億吾獨往",
	["&litong"] = "李通",
	["tuifeng"] = "推鋒",
	[":tuifeng"] = "1.當你受到1點傷害後，你可以將一張牌置於武將牌上，稱為“鋒”。 2.準備階段開始時，若你的武將牌上有“鋒”，你將所有“鋒”置入棄牌堆，摸2X張牌，然後你於此回合的出牌階段內使用【殺】的次數上限+X（X為你此次置入棄牌堆的“鋒”數）。",
	["feng"] = "鋒",
	["#tuifeng"] = "你可以將一張牌置於武將牌上，稱為“鋒”",
	["$tuifeng1"] = "摧鋒陷陣，以殺賊首！",
	["$tuifeng2"] = "敵鋒之銳，我已盡知。",
}
--蹋頓
tadun = sgs.General(extension, "tadun", "qun2", "4", true)
--亂戰
--[[
luanzhanCard = sgs.CreateSkillCard{
	name = "luanzhan",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("luanzhan_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "luanzhan_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets < sgs.Self:getMark("@luanz") and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets < sgs.Self:getMark("@luanz") and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _, p in pairs(targets) do
				room:addPlayerMark(p, self:objectName())
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
luanzhanVS = sgs.CreateZeroCardViewAsSkill{
	name = "luanzhan",
	response_pattern = "@@luanzhan",
	view_as = function()
		return luanzhanCard:clone()
	end
}
]]--
luanzhan = sgs.CreateTriggerSkill{
	name = "luanzhan",
	events = {sgs.PreCardUsed, sgs.TargetSpecified, sgs.Damage, sgs.Damaged},
	--view_as_skill = luanzhanVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			--[[
			local use = data:toCardUse()
			if player:getMark("@luanz") > 0 and (use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.card:isBlack() and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification"))) then
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, self:objectName())
				end
				if use.card:isVirtualCard() then
					room:setPlayerMark(player, "luanzhan_virtual_card", 1)
					room:setPlayerMark(player, "luanzhan_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
					room:askForUseCard(player, "@@luanzhan", "@luanzhan")
					room:setPlayerMark(player, "luanzhan_virtual_card", 0)
					room:setPlayerMark(player, "luanzhan_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
				elseif not use.card:isVirtualCard() then
					room:setPlayerMark(player, "extra_target_not_virtual_card", 1)
					room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
					room:askForUseCard(player, "@@luanzhan", "@luanzhan")
					room:setPlayerMark(player, "extra_target_not_virtual_card", 0)
					room:setPlayerMark(player, "card_id", 0)
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark(self:objectName()) > 0 and not room:isProhibited(player, p, use.card) then
						room:removePlayerMark(p, self:objectName())
						if not use.to:contains(p) then
							use.to:append(p)
						end
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
							]]--
			if use.card:isKindOf("Collateral") and use.card:isBlack() then
				local targets = sgs.SPlayerList()
				for i = 1, player:getMark("@luanz") do
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if use.to:contains(p) or room:isProhibited(player, p, use.card) then continue end
						if use.card:targetFilter(sgs.PlayerList(), p, player) then
							targets:append(p)
						end
					end
					if targets:isEmpty() then return false end
					local tos = {}
					for _, t in sgs.qlist(use.to) do
						table.insert(tos, t:objectName())
					end
					room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
					room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
					local used = room:askForUseCard(player, "@@ExtraCollateral", "@qiaoshui-add:::collateral")
					room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(""))
					room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant("+"))
					if not used then return false end
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:hasFlag("ExtraCollateralTarget") then
								p:setFlags("-ExtraColllateralTarget")
								extra = p
								break
							end
						end
						if extra == nil then return false end
						use.to:append(extra)
						room:sortByActionOrder(use.to)
						data:setValue(use)
						room:removePlayerMark(player, self:objectName().."engine")
					else
						return false
					end
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.card:isBlack())) and use.to:length() < player:getMark("@luanz") then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					player:loseMark("@luanz",  player:getMark("@luanz")/2)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.Damage or event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.damage and damage.damage > 0 then
				player:gainMark("@luanz")
			end
		end
	end,
}

tadun:addSkill(luanzhan)

sgs.LoadTranslationTable{
	["tadun"] = "蹋頓",
	["#tadun"] = "北狄王",
	["luanzhan"] = "亂戰",
	[":luanzhan"] = "你使用【殺】或黑色普通錦囊牌可以多選擇X名角色為目標；當你使用【殺】或黑色普通錦囊牌指定目標後，若此牌的目標角色數小於X，則X減半（向下取整）。 （X為你於本局遊戲內造成過傷害和受到傷害的次數之和）",
	["$luanzhan1"] = "現，正是我烏桓崛起之機！",
	["$luanzhan2"] = "受袁氏大恩，當效死力！",
	["@luanz"] = "亂",
	["@luanzhan"] = "你可以發動“亂戰”",
	["~luanzhan"] = "選擇目標角色→點“確定”",
}

--SP卑彌呼 女, 群, 3 體力
beimihu = sgs.General(extension, "beimihu", "qun2", "3", false)
--縱傀--回合開始時，你可以指定一名未擁有“傀”標記的其他角色，令其獲得一枚“傀”標記。每輪遊戲開始時，體力值最少且沒有“傀”標記的一名其他角色也獲得一個“傀”標記。  
zongkui = sgs.CreateTriggerSkill{
	name = "zongkui",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		local phase = change.to
		if phase == sgs.Player_RoundStart and (player:getMark("AG_firstplayer") > 0 or player:getMark("@leader") > 0 or player:isLord()) and (not room:getTag("ExtraTurn"):toBool()) and player:getMark("@stop_invoke") == 0 then
			for _, p in sgs.qlist(room:findPlayersBySkillName("zongkui")) do
				local players = sgs.SPlayerList()
				local n = p:getHp()
				for _,pp in sgs.qlist(room:getOtherPlayers(p)) do
					n = math.min(n, pp:getHp())
				end
				for _,pp in sgs.qlist(room:getOtherPlayers(p)) do
					if pp:getHp() == n and pp:getMark("@puppet") == 0 then
						players:append(pp)
					end
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(p, players, self:objectName(), "zongkui-invoke", true, true)
					if target then
						room:notifySkillInvoked(player, self:objectName())
						if player:getGeneralName() == "tw_beimihu" then
							room:broadcastSkillInvoke(self:objectName(), 4)
						else
							room:broadcastSkillInvoke(self:objectName(), 3)
						end
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							target:gainMark("@puppet")
							room:removePlayerMark(p, self:objectName().."engine")
						end
					end
				end
			end
		end

		if phase == sgs.Player_RoundStart and player:hasSkill("zongkui") then
			local players = sgs.SPlayerList()
			for _,pp in sgs.qlist(room:getOtherPlayers(player)) do
				if pp:getMark("@puppet") == 0 then
					players:append(pp)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "zongkui-invoke", false, true)
				if target then
					room:notifySkillInvoked(player, self:objectName())
					if player:getGeneralName() == "tw_beimihu" then
						room:broadcastSkillInvoke(self:objectName(), 3)
					else
						room:broadcastSkillInvoke(self:objectName(), 1)
					end
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						target:gainMark("@puppet")
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
}

--骨疽--鎖定技，擁有“傀”標記的角色受到傷害後，你摸一張牌。
guju = sgs.CreateTriggerSkill{
	name = "guju",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if player:getMark("@puppet") > 0 then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getGeneralName() == "tw_beimihu" then
					SendComLog(self, p, math.random(3,4))
				else
					SendComLog(self, p, math.random(1,2))
				end
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					if p:hasSkill("tw_bingzhao") and p:getMark("tw_bingzhao" .. player:getKingdom()) > 0 then
						p:drawCards(2, self:objectName())
						room:addPlayerMark(p, "@goochi",2)
					else
						p:drawCards(1, self:objectName())
						room:addPlayerMark(p, "@goochi")
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--蠶食--一名角色使用基本牌或非延時錦囊牌指定你為唯一目標時，若其有“傀”標記，你可以取消之，然後其失去“傀”標記；你使用牌僅指定一名角色為目標時，你可以額外指定任意名帶有“傀”標記的角色為目標，然後其失去“傀”標記。

canshibCard = sgs.CreateSkillCard{
	name = "canshib",
	filter = function(self, targets, to_select)
		--return to_select:getMark(self:objectName()) == 0 and to_select:getMark("@puppet") > 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self)
		return to_select:getMark(self:objectName()) == 0 and to_select:getMark("@puppet") > 0
	end,
	on_effect = function(self, effect)
		--room:addPlayerMark(effect.from, self:objectName().."engine")
		effect.from:getRoom():addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
			effect.to:getRoom():addPlayerMark(effect.to, self:objectName())
			--room:removePlayerMark(effect.from, self:objectName().."engine")
			effect.from:getRoom():removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
canshibVS = sgs.CreateZeroCardViewAsSkill{
	name = "canshib",
	response_pattern = "@@canshib",
	view_as = function()
		--if sgs.Self:getMark("card_id") > 0 then
		if sgs.Self:getMark("not_Collateral") > 0 then
			return canshibCard:clone()
		else
			return canshibEXCard:clone()
		end
	end
}

canshib = sgs.CreateTriggerSkill{
	name = "canshib",
	view_as_skill = canshibVS,
	events = {sgs.TargetSpecifying},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.to:length() == 1 then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if use.from:getMark("@puppet") > 0 and use.to:contains(p) and not use.card:isKindOf("SkillCard") and room:askForSkillInvoke(p, self:objectName(), data) then
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						use.from:loseMark("@puppet")
						use.to:removeOne(p)
						room:removePlayerMark(p, self:objectName().."engine")
					end
				end
				if use.from:objectName() == p:objectName() and (not use.card:isKindOf("Collateral") and not use.card:isKindOf("SkillCard") and not use.card:isKindOf("EquipCard") and not use.card:isKindOf("DelayedTrick")) then
					for _, pe in sgs.qlist(use.to) do
						room:addPlayerMark(pe, self:objectName())
					end
					--room:setPlayerMark(p, "card_id", use.card:getEffectiveId())
					room:setPlayerMark(p, "not_Collateral", 1)
					room:setTag("canshibData", data)
					room:askForUseCard(p, "@@canshib", "@canshib")
					room:removeTag("canshibData")
					--room:setPlayerMark(p, "card_id", 0)
					room:setPlayerMark(p, "not_Collateral", 0)

					local msg = sgs.LogMessage()
					msg.type = "#ExtraTarget"
					msg.from = p

					for _, pe in sgs.qlist(room:getAllPlayers()) do
						if pe:getMark(self:objectName()) > 0 and not room:isProhibited(p, pe, use.card) then
							room:setPlayerMark(pe, self:objectName(), 0)


							if not use.to:contains(pe) then
								pe:loseMark("@puppet")
								use.to:append(pe)
								msg.to:append(pe)
							end
						end
					end

					msg.arg = self:objectName()
					msg.card_str = use.card:toString()
					if msg.to:length() > 0 then
						room:sendLog(msg)
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


canshibtm = sgs.CreateTargetModSkill{
	name = "#canshibtm" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("canshibtm")) then
			return 1000
		end
		return 0
	end
}
--拜假--覺醒技，準備階段，若你因〖骨疽〗獲得牌不小於 7 張，則你增加 1 點體力上限，回復 1 點體力，然後令所有未擁有“傀”標記的其他角色獲得“傀”標記，最後失去技能〖骨疽〗，並獲得技能〖蠶食〗。						  　
baijia = sgs.CreateTriggerSkill{
	name = "baijia",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@goochi") >= 7 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:addPlayerMark(player, "baijia")
			if room:changeMaxHpForAwakenSkill(player, 1) then
				if player:getGeneralName() == "tw_beimihu" then
					room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
				else
					room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
				end
				if player:getMark("@goochi") >= 7 then
					local msg = sgs.LogMessage()
					msg.type = "#BaijiaWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = player:getMark("@goochi")
					msg.arg2 = self:objectName()
					room:sendLog(msg)
				end

				room:doSuperLightbox("beimihu","baijia")
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("@puppet") == 0 then
					 	p:gainMark("@puppet")
					end
				end
				room:acquireSkill(player, "canshib")
				room:detachSkillFromPlayer(player, "guju")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("baijia")
				and target:isAlive()
				and (target:getMark("baijia") == 0)
	end
}
beimihu:addSkill(zongkui)
beimihu:addSkill(guju)
beimihu:addSkill(baijia)
beimihu:addRelateSkill("canshib")
beimihu:addRelateSkill("#canshibtm")

extension:insertRelatedSkills("canshib","#canshibtm")
if not sgs.Sanguosha:getSkill("canshib") then skills:append(canshib) end
if not sgs.Sanguosha:getSkill("#canshibtm") then skills:append(canshibtm) end

sgs.LoadTranslationTable{
	["beimihu"] = "卑彌呼",
	[":beimihu"] = "",
	["zongkui"] = "縱傀",
	[":zongkui"] = "回合開始時，你可以指定一名未擁有“傀”標記的其他角色，令其獲得一枚“傀”標記。每輪遊戲開始時，體力值最少且沒有“傀”標記的一名其他角色也獲得一個“傀”標記。", 
	["@puppet"] = "傀",
	["guju"] = "骨疽",
	[":guju"] = "鎖定技，擁有“傀”標記的角色受到傷害後，你摸一張牌。",
	["canshib"] = "蠶食",
	[":canshib"] = "一名角色使用基本牌或非延時錦囊牌指定你為唯一目標時，若其有“傀”標記，你可以取消之，然後其失去“傀”標記；你使用牌僅指定一名角色為目標時，你可以額外指定任意名帶有“傀”標記的角色為目標，然後其失去“傀”標記。",
	["baijia"] = "拜假",
	[":baijia"] = "覺醒技，準備階段，若你因〖骨疽〗獲得牌不小於 7 張，則你增加 1 點體力上限，回復 1 點體力，然後令所有未擁有“傀”標記的其他角色獲得“傀”標記，最後失去技能〖骨疽〗，並獲得技能〖蠶食〗",
	["zongkui-invoke"] = "請選擇一名角色，令其獲得一個「傀」標記",
	["@canshib"] = "你可以發動“縱傀”",
	["~canshib"] = "點選成為目標的角色 -> 點擊「確定」",
	["@goochi"] = "疽",
	["#ExtraTarget"] = "%from 發動技能 “<font color=\"yellow\"><b> %arg </b></font>”， %card 額外增加了目標 %to",
	["#BaijiaWake"] = "%from 因〖骨疽〗獲得的牌數達到 %arg 張，觸發“%arg2”覺醒",
	["$zongkui1"] = "准备好，听候女王的差遣了吗？",
	["$zongkui2"] = "契约已定！",
	["$guju1"] = "我能看到，你的灵魂在颤抖。",
	["$guju2"] = "你死后，我将超度你的亡魂。",
	["$baijia1"] = "以邪马台的名义！",
	["$baijia2"] = "我要摧毁你的一切，然后建立我的国度。",
	["$canshib1"] = "是你在召唤我吗？",
	["$canshib2"] = "这片土地的人真是太有趣了。",
}
--麴義
quyi = sgs.General(extension, "quyi", "qun2", "4", true)
--伏騎
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

fuji = sgs.CreateTriggerSkill{
	name = "fuji",
	--events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.TrickCardCanceling, sgs.CardFinished},
	events = {sgs.CardUsed, sgs.TargetSpecified, sgs.TrickCardCanceling},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local invoke = false
			for _, p in sgs.qlist(use.to) do
				if p:distanceTo(use.from) == 1 then
					invoke = true
				end
			end
			if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and not use.card:isKindOf("SkillCard") and invoke and use.from:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and not use.card:isKindOf("SkillCard") and use.from and RIGHT(self, use.from) then
				local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				local msg = sgs.LogMessage()
				msg.type = "#fuji"
				msg.from = player

				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if p:distanceTo(use.from) == 1 then
						jink_table[index] = 0
						msg.to:append(p)
					end
					index = index + 1
				end
				msg.card_str = use.card:toString()
				room:sendLog(msg)

				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_"..use.card:toString(), jink_data)
			end
		--以下對多目標使用殺時會有BUG，可能目標都能閃或是目標都不能閃
		--[[
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and not use.card:isKindOf("SkillCard") then
				use.from:setTag("FujiSlash", sgs.QVariant(use.from:getTag("FujiSlash"):toInt() + 1))
				if RIGHT(self, use.from) and player:distanceTo(use.from) == 1 then
					local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
					jink_table[use.from:getTag("FujiSlash"):toInt() - 1] = 0
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					use.from:setTag("Jink_" .. use.card:toString(), jink_data)
				end
			end
		]]--
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and RIGHT(self, effect.from) and player:distanceTo(effect.from) == 1 then return true end
		--以下不需要，因為用其他非tag方式實現
		--[[
		else
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and not use.card:isKindOf("SkillCard") then
				player:setTag("FujiSlash", sgs.QVariant(0))
			end
		]]--
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--[[
fuji = sgs.CreateTriggerSkill{
	name = "fuji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = ".|.|.|hand$1"
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player, "fuji")
				room:setPlayerFlag(player, "usefuji")
				local msg = sgs.LogMessage()
				msg.type = "#fuji"
				msg.from = player
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:distanceTo(player) <= 1 then
						room:setPlayerCardLimitation(p, "use,response", pattern, false)
						room:setPlayerMark(p, "@beenfuji", 1)
						msg.to:append(p)
					end
				end
				msg.arg = use.card:objectName()
				room:sendLog(msg)	
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				if player:hasFlag("usefuji") then
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand$1")
						room:setPlayerMark(p, "@beenfuji", 0)
					end
					room:setPlayerFlag(player, "-usefuji")
				end
			end
		end
	end,
}
]]--
--骄恣:锁定技，若你的手牌数为全场唯一最多，你造成或受到的伤害值+1。
jiaozi = sgs.CreateTriggerSkill{
	name = "jiaozi",
	events = {sgs.DamageForseen},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from:hasSkill("jiaozi") or damage.to:hasSkill("jiaozi") then
			local player_card = {}
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				table.insert(player_card, p:getHandcardNum())
			end
			if (damage.from:getHandcardNum() == math.max(unpack(player_card)) and damage.from:hasSkill("jiaozi")) or
			(damage.to:getHandcardNum() == math.max(unpack(player_card)) and damage.to:hasSkill("jiaozi")) then
				if damage.from:hasSkill("jiaozi") then
					room:sendCompulsoryTriggerLog(damage.from, "jiaozi")
				elseif damage.to:hasSkill("jiaozi") then
					room:sendCompulsoryTriggerLog(damage.to, "jiaozi")
				end

				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				if damage.from:hasSkill("jiaozi") then
					room:broadcastSkillInvoke(self:objectName(),2)
					msg.type = "#Jiaozi1"
 				elseif damage.to:hasSkill("jiaozi") then
					room:broadcastSkillInvoke(self:objectName(),1)
					msg.type = "#Jiaozi2"
				end

				if damage.from:hasSkill("jiaozi")then
					msg.from = damage.from
					msg.to:append(damage.to)
 				elseif damage.to:hasSkill("jiaozi") then
 					msg.from = damage.to
					msg.to:append(damage.from)
				end
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)		
			end
		end
	end,
}

quyi:addSkill(fuji)
quyi:addSkill(jiaozi)

sgs.LoadTranslationTable{
	["quyi"] = "麴義",
	[":quyi"] = "",
	["fuji"] = "伏騎",
	[":fuji"] = "鎖定技，與你距離為1的其他角色不能使用或打出牌響應你使用的牌",
	["jiaozi"] = "驕恣",
	[":jiaozi"] = "鎖定技，若你的手牌數為全場唯一最多，你造成或受到的傷害值+1。",
	["#Jiaozi1"] = "%from 的技能“<font color=\"yellow\"><b>驕恣</b></font>”被觸發，對 %to 造成的傷害由 %arg 點增加到"..
"%arg2 點",
	["#Jiaozi2"] = "%from 的技能“<font color=\"yellow\"><b>驕恣</b></font>”被觸發，%to 對 %from 造成的傷害由 %arg 點增加到"..
"%arg2 點",
	["#fuji"] = "%from 的技能 “<font color=\"yellow\"><b>伏騎</b></font>”被觸發，與 %from 距離為1的其他角色 %to 無法響應此 %card ",
}

--董允
dongyun = sgs.General(extension, "dongyun", "shu", "3", true)
--捨宴
sheyan = sgs.CreateTriggerSkill{
	name = "sheyan" ,
	events = {sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and 
		 ((room:alivePlayerCount() > (use.to:length() + 1)) or (use.to:length() > 1)) then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if room:alivePlayerCount() > (use.to:length() + 1) then
					if (not use.to:contains(p)) and p ~= use.from then
						_targets:append(p)
					end
				end
				if use.to:length() > 1 then
					if use.to:contains(p) then
						_targets:append(p)
					end	
				end
			end
			if not _targets:isEmpty() then
				room:setTag("sheyanData", data)
				local s = room:askForPlayerChosen(player, _targets, "sheyan", "@sheyan:"..use.card:objectName(), true)
				if s then
					room:doAnimate(1, player:objectName(), s:objectName())
					room:notifySkillInvoked(player, "sheyan")
					if not use.to:contains(s) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						use.to:append(s)
						room:sortByActionOrder(use.to)
						room:getThread():trigger(sgs.TargetConfirming, room, s, data)
						local msg = sgs.LogMessage()
						msg.type = "#sheyan1"
						msg.from = player
						msg.to:append(s)
						msg.arg = use.card:objectName()
						room:sendLog(msg)
						data:setValue(use)
					elseif use.to:contains(s) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						use.to:removeOne(s)
						room:sortByActionOrder(use.to)
						local msg = sgs.LogMessage()
						msg.type = "#sheyan2"
						msg.from = player
						msg.to:append(s)
						msg.arg = use.card:objectName()
						room:sendLog(msg)
						data:setValue(use)
					end
				end
				room:removeTag("sheyanData")
			end
		end
		return false
	end
}
--秉正
function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

bingzheng = sgs.CreateTriggerSkill{
	name = "bingzheng",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() ~= p:getHp() then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local s = room:askForPlayerChosen(player, _targets, "bingzheng", "@bingzheng-choose", true)
				if s then
					room:doAnimate(1, player:objectName(), s:objectName())
					room:notifySkillInvoked(player, "bingzheng")
					room:setPlayerFlag(s, "bingzhengtarget")
					room:broadcastSkillInvoke(self:objectName())
					if not s:isKongcheng() then
						local choices = {"bingzheng_draw", "bingzheng_discard"}
						local choice = room:askForChoice(player, "bingzheng", table.concat(choices, "+"))
						if choice == "bingzheng_draw" then
							room:drawCards(s, 1, "bingzheng")
						end
						if choice == "bingzheng_discard" then
							room:askForDiscard(s, "bingzheng", 1, 1, false, false)
						end
					else
						room:drawCards(s, 1, "bingzheng")
					end
					if s:getHandcardNum() == s:getHp() then
						room:drawCards(player, 1, "bingzheng")
						if s:objectName() ~= player:objectName() then
							local players = sgs.SPlayerList()
							players:append(s)
							room:askForYiji(player,getIntList(player:getCards("he")), self:objectName(), false, false, true, 1, players, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), s:objectName(), self:objectName(), ""), "bingzheng-distribute:"..s:objectName(), true)
						end
					end
					room:setPlayerFlag(s, "-bingzhengtarget")
				end
			end
		end
	end,
}

dongyun:addSkill(sheyan)
dongyun:addSkill(bingzheng)
sgs.LoadTranslationTable{
	["dongyun"] = "董允",
	["#dongyun"] = "骨鲠良相",
	["sheyan"] = "捨宴",
	[":sheyan"] = "當你成為一張普通錦囊牌的目標時，你可以為此牌增加一個目標或減少一個目標（目標數至少為一）。 ",
	["bingzheng"] = "秉正",
	[":bingzheng"] = "出牌階段結束時，你可以令手牌數不等於體力值的一名角色棄置一張手牌或摸一張牌。然後若其手牌數等於體力值，你摸一張牌，且可以交給該角色一張牌。",
	["@bingzheng-choose"] = "請選擇一名角色",
	["bingzheng_draw"] = "令其摸一張牌",
	["bingzheng_discard"] = "令其棄一張牌",
	["@sheyan"] = "你可以令 %src 增加/減少一個目標",
	["#sheyan1"] = "%from 發動技能 “<font color=\"yellow\"><b>捨宴</b></font>”， %arg 額外增加了目標 %to",
	["#sheyan2"] = "%from 發動技能 “<font color=\"yellow\"><b>捨宴</b></font>”， %arg 減少了目標 %to",
	["$bingzheng1"] = "自古~就是邪不勝正！",
	["$bingzheng2"] = "主公面前，豈容小人搬弄是非！",
	["$sheyan1"] = "公事為重~宴席，不去也罷~",
	["$sheyan2"] = "還是改日吧~",
	["bingzheng-distribute"] = "你可以交給 %src 一张牌",
}
--蔡夫人
no_bug_caifuren = sgs.General(extension, "no_bug_caifuren", "qun2", 3, false)
lua_xianzhouCard = sgs.CreateSkillCard {
	name = "lua_xianzhou",
	target_fixed = false,
	filter = function(self, targets, to_select, player, data)
		if player:hasFlag("lua_xianzhou_target") then
			return #targets < player:getMark("lua_xianzhou_count") and player:inMyAttackRange(to_select) and to_select:objectName() ~= player:objectName()
		end
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		if source:hasFlag("lua_xianzhou_target") then
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.reason = "lua_xianzhou"
			for _, p in ipairs(targets) do
				damage.to = p
				room:damage(damage)
			end
			room:setPlayerFlag(source, "-lua_xianzhou_target")
			room:setPlayerMark(source, "lua_xianzhou_count", 0)
		else
			room:doSuperLightbox("no_bug_caifuren","lua_xianzhou")
			local target = targets[1]
			room:removePlayerMark(source, "@handover")
			self:addSubcards(source:getEquips())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "lua_xianzhou", "")
			room:moveCardTo(self, target, sgs.Player_PlaceHand, reason, false)
			local choices = {}
			if source:isWounded() then
				table.insert(choices, "xianzhou_recover")
			end
			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if target:inMyAttackRange(p) then
				n = n + 1
				end
			end
			if n > 0 then
				table.insert(choices, "xianzhou_damage")
			end
			if #choices > 0 then
				local choice = room:askForChoice(target, "lua_xianzhou", table.concat(choices, "+"))
				if choice == "xianzhou_recover" then
					local recover = sgs.RecoverStruct()
					recover.who = target
					recover.recover = math.min(source:getMaxHp() - source:getHp(), self:subcardsLength())
					room:recover(source, recover)
				elseif choice == "xianzhou_damage" then
					room:setPlayerFlag(target, "lua_xianzhou_target")
					room:setPlayerMark(target, "lua_xianzhou_count", self:subcardsLength())
					room:askForUseCard(target, "@@lua_xianzhou", "@lua_xianzhou")
				end
			end
		end
	end,
}
lua_xianzhouVS = sgs.CreateZeroCardViewAsSkill{
	name = "lua_xianzhou",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self)
		local card = lua_xianzhouCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:hasEquip() and player:getMark("@handover") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@lua_xianzhou"
	end,
}

lua_xianzhou = sgs.CreateTriggerSkill{
	name = "lua_xianzhou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@handover",
	view_as_skill = lua_xianzhouVS,
	on_trigger = function()
	end
}
no_bug_caifuren:addSkill("qieting")
no_bug_caifuren:addSkill(lua_xianzhou)

sgs.LoadTranslationTable{
["#no_bug_caifuren"] = "襄江的蒲葦",
["no_bug_caifuren"] = "蔡夫人",
["illustrator:no_bug_caifuren"] = "Dream彼端",
["designer:no_bug_caifuren"] = "B.LEE",
["lua_xianzhou"] = "獻州",
[":lua_xianzhou"] = "限定技，出牌階段，你可以將裝備區裡的所有牌交給一名角色，令其選擇一項：1．令你回復X點體力；2．選擇其攻擊範圍內的一至X名角色，然後對這些角色各造成1點傷害。（X為你以此法交給其的牌數）",
["xianzhou_damage"] = "對攻擊範圍內一至X名角色造成傷害",
["xianzhou_recover"] = "讓蔡夫人回復X點體力",
["@lua_xianzhou"] = "你可以對一至X名角色造成傷害",
["~lua_xianzhou"] = "選擇若干名角色→點擊確定",
["$lua_xianzhou1"] = "獻荊襄九郡，圖一世之安。",
["$lua_xianzhou2"] = "丞相挾天威而至，吾等安敢不降？",
["~no_bug_caifuren"] = "孤兒寡母，何必趕盡殺絕呢...",
}

--SP蔡文姬
no_bug_caiwenji = sgs.General(extension, "no_bug_caiwenji", "wei2", 3, false)
lua_chenqing = sgs.CreateTriggerSkill{
	name = "lua_chenqing",
	events = {sgs.AskForPeaches, sgs.AskForPeachesDone},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local current = room:getCurrent()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark(self:objectName().."_lun") == 0 and p:getMark("no_more_ask_"..self:objectName()) == 0 then
					local players = sgs.SPlayerList()
					for _, pp in sgs.qlist(room:getAlivePlayers()) do
						if pp:objectName() ~= dying.who:objectName() and pp:objectName() ~= p:objectName() then
							players:append(pp)
						end
					end
					local target = room:askForPlayerChosen(p, players, self:objectName(), "ChenqingAsk", true, true)
					if target == nil then
						room:addPlayerMark(p, "no_more_ask_"..self:objectName())
					end
					if target and target:isAlive() then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							room:addPlayerMark(p, self:objectName().."_lun")
							target:drawCards(4, self:objectName())
							local chenqing_throw_cards = room:askForExchange(target, self:objectName(), 4, 4, true, "ChenqingDiscard")
							room:throwCard(chenqing_throw_cards, target, nil)
							local suits = {}
							for _,id in sgs.qlist(chenqing_throw_cards:getSubcards()) do
								if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuit()) then
									table.insert(suits, sgs.Sanguosha:getCard(id):getSuit())
								end
							end
							if #suits == 4 then
								local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
								peach:setSkillName(self:objectName())
								room:useCard(sgs.CardUseStruct(peach, target, dying.who))
							end
						end
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("no_more_ask_"..self:objectName()) > 0 then
					room:setPlayerMark(p, "no_more_ask_"..self:objectName(), 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}

lua_moshiVS = sgs.CreateOneCardViewAsSkill{
	name = "lua_moshi",
	filter_pattern = ".",
	response_or_use = true,
	response_pattern = "@@lua_moshi",
	view_as = function(self, card)
		local DCR = sgs.Self:property("moshi"):toString():split(":")[1]
		local shortage = sgs.Sanguosha:cloneCard(DCR,card:getSuit(),card:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(card)
		return shortage
	end,
	enabled_at_play = function(self, player)
		return false
	end
}

lua_moshi = sgs.CreateTriggerSkill{
	name = "lua_moshi",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = lua_moshiVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				local promptlist = player:property("moshi"):toString():split(":")
				for i = 1,2,1 do
					if #promptlist > 0 then
						local class_name = promptlist[1]
						local DCR_card = sgs.Sanguosha:cloneCard(class_name, sgs.Card_NoSuit, -1)
						if DCR_card:isAvailable(player) and (DCR_card:isNDTrick() or DCR_card:isKindOf("BasicCard")) then
							if room:askForUseCard(player, "@@lua_moshi", "@lua_moshi:" .. class_name, -1, sgs.Card_MethodUse, false) then
								table.remove(promptlist,1)
								room:setPlayerProperty(player, "moshi", sgs.QVariant( table.concat(promptlist,":") ))
							else
								break
							end
						end
					end
				end
			end
		end
	end
}

no_bug_caiwenji:addSkill(lua_chenqing)
no_bug_caiwenji:addSkill(lua_moshi)
--no_bug_caiwenji:addSkill("moshi")


sgs.LoadTranslationTable{
["no_bug_caiwenji"] = "OL蔡文姬",
["&no_bug_caiwenji"] = "蔡文姬",
["#no_bug_caiwenji"] = "金壁之才",
["ChenqingAsk"] = "你可以發動“陳情”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["ChenqingDiscard"] = "請棄置四張牌<br/> <b>操作提示</b>: 選擇四張牌→點擊確定<br/>",
["lua_chenqing"] = "陳情",
[":lua_chenqing"] = "<font color=\"green\"><b>每輪限一次，</b></font>當一名角色處於瀕死狀態時，你可以令另一名其他角色摸四張牌，"
.."然後棄置四張牌。若其以此法棄置的四張牌花色各不相同，則視為該角色對瀕死的角色使用一張【桃】。",
["$lua_chenqing1"] = "亂世陳情,字字血淚。",
["$lua_chenqing2"] = "陳，生死離別之苦；悲，亂世之跌宕。~",
["~no_bug_caiwenji"] = "命運弄人~",

["lua_moshi"] = "默識" ,
[":lua_moshi"] = "結束階段開始時，妳可以將一張手牌當妳本回合出牌階段使用的第一張基本或非延時類錦囊牌使用。然後，妳可以將一張手牌當妳本回合出牌階段使用的第二張基本或非延時類錦囊牌使用。" ,
["@lua_moshi"] = "妳可以將一張牌當作【%src】使用",
["~lua_moshi"] = "按照此牌使用方式指定角色→點擊確定",
}


--群馬超
ol_machao = sgs.General(extension, "ol_machao", "qun2", 4, true)

ol_shichou = sgs.CreateTargetModSkill{
	name = "ol_shichou",
	pattern = "Slash",
	frequency = sgs.Skill_Frequent,
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return math.max(player:getLostHp(),1)
		end
	end,
}
ol_shichouvoice = sgs.CreateTriggerSkill{
	name = "#ol_shichouvoice" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				if use.to:length() > 1 then
					room:broadcastSkillInvoke("ol_shichou")
				end
			end
		end
	end
}

ol_machao:addSkill("zhuiji")
ol_machao:addSkill(ol_shichou)
ol_machao:addSkill(ol_shichouvoice)
extension:insertRelatedSkills("ol_shichou","#ol_shichouvoice")

sgs.LoadTranslationTable{
	["ol_machao"] = "群馬超",
	["&ol_machao"] = "馬超",
	["ol_shichou"] = "誓仇",
	[":ol_shichou"] = "你使用【殺】可以多選擇至多X名角色為目標（X為你已經損失的體力值且至少為1）",
	["$ol_shichou1"] = "滅族之恨，不共戴天！",
	["$ol_shichou2"] = "休想跑~",
}

--馬雲祿 
ol_mayunlu = sgs.General(extension, "ol_mayunlu", "shu", "4", false)
--鳳魄
ol_fengpo = sgs.CreateTriggerSkill{
	name = "ol_fengpo",
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and player:getMark("ol_fengpo-Clear") == 0 and use.to:length() == 1 and player:getPhase() ~= sgs.Player_NotActive then
				for _, p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if player:askForSkillInvoke(self:objectName(), _data) then
							room:doAnimate(1, player:objectName(), p:objectName())
							room:notifySkillInvoked(player, "ol_fengpo")
							room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
							local choices = {"fengpo1", "fengpo2"}
							local choice = room:askForChoice(player, "ol_fengpo", table.concat(choices, "+"))
							local n = 0
							local msg1 = sgs.LogMessage()
							msg1.type = "#MakeChoice"
							msg1.from = player
							msg1.arg = "ol_fengpo"
							msg1.arg2 = choice
							room:sendLog(msg1)
							--room:showAllCards(p)
							for _, card in sgs.qlist(p:getHandcards()) do
								if card:getSuit() == sgs.Card_Diamond then
									n = n + 1 
								end
							end
							if choice == "fengpo2" then
								use.card:setTag("ol_fengpoBuffed", sgs.QVariant(n))
							elseif choice == "fengpo1" then
								player:drawCards(n)
							end
						end
					end
				end
			end
		end
	end
}
ol_mayunlu:addSkill("mashu")
ol_mayunlu:addSkill(ol_fengpo)

sgs.LoadTranslationTable{
	["ol_mayunlu"] = "OL馬雲祿",
	["#ol_mayunlu"] = "戰場的少女",
	["&ol_mayunlu"] = "馬雲祿",
	["ol_fengpo"] = "鳳魄",
	["fengpo1"] = "摸X張牌",
	["fengpo2"] = "此牌造成的傷害+X。",
	[":ol_fengpo"] = "你在回合內使用第一張【殺】或【決鬥】指定一個目標後，你可以選擇一項：1.摸X張牌；2.此牌造成的傷害+X。 （X為其方塊手牌數）",
	["#ol_fengpo"] = "%from 發動技能 “<font color=\"yellow\"><b>鳳魄</b></font>”，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--董白
dongbai = sgs.General(extension, "dongbai", "qun2", 3, false)
lianzhuCard = sgs.CreateSkillCard{
	name = "lianzhu",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local need = sgs.Sanguosha:getCard(self:getSubcards():first()):isBlack()
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), true)
			if need then
				if not room:askForDiscard(targets[1], "lianzhu", 2, 2, true,true,"@lianzhu:"..source:objectName()) then
					source:drawCards(2, self:objectName())
				end
			else
				source:drawCards(1, self:objectName())
			end
			room:removePlayerMark(source, self:objectName().."engine")
		else
			room:showCard(source, self:getSubcards():first())
		end
	end
}
lianzhu = sgs.CreateOneCardViewAsSkill{
	name = "lianzhu",
	filter_pattern = ".",
	view_as = function(self, card)
		local skill_card = lianzhuCard:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lianzhu")
	end
}
dongbai:addSkill(lianzhu)

xiahui = sgs.CreateTriggerSkill{
	name = "xiahui",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd, sgs.CardsMoveOneTime, sgs.Damaged, sgs.HpLost},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard and RIGHT(self, player) then
				room:setPlayerCardLimitation(player, "discard", ".|black|.|hand", true)
			elseif change.to == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("lose_xiahui_card-Clear") > 0 then
						local has_xiahui_card = false
						for _,c in sgs.qlist(p:getHandcards()) do
							if c:hasFlag(self:objectName()) then
								has_xiahui_card = true
							end
						end
						if has_xiahui_card then
							room:loseHp(p)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Discard then
				room:removePlayerCardLimitation(player, "discard", ".|black|.|hand$1")
			end
		elseif event == sgs.CardsMoveOneTime and RIGHT(self, player) then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() ~= player:objectName() and move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
				for _,id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isBlack() then
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							room:setPlayerCardLimitation(BeMan(room, move.to), "use,response,discard",sgs.Sanguosha:getCard(id):toString(), false)
							room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
							room:addPlayerMark(BeMan(room, move.to), self:objectName())
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
			if (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
				for _,c in sgs.qlist(player:getCards("he")) do
					if c:hasFlag(self:objectName()) then
						room:removePlayerCardLimitation(player, "use,response,discard", c:toString().."$0")
						room:removePlayerMark(player, self:objectName())
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			--補上失去牌後可使用條件
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName()
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				local lost_xiahui_black_card = false
				for _,id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
						lost_xiahui_black_card = true
					end
				end
				--Player類型轉至ServerPlayer
				local move_from_player
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() == move.from:objectName() then
						move_from_player = p
					end
				end
				if lost_xiahui_black_card and move_from_player then
					for _,id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
							room:removePlayerCardLimitation(move_from_player, "use,response,discard", sgs.Sanguosha:getCard(id):toString().."$0")
							room:removePlayerMark(move_from_player, self:objectName())
							room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName())
							room:addPlayerMark(move_from_player, "lose_xiahui_card-Clear")
						end
					end
				end
			end
		--elseif event == sgs.HpChanged then
		elseif event == sgs.Damaged or event == sgs.HpLost then
			local int = 0
			if data:toDamage() and data:toDamage().damage > 0 then
				int = data:toDamage().damage
			elseif data:toInt() > 0 then
				int = data:toInt()
			end
			if int > 0 and player:getMark(self:objectName()) > 0 then
				for _,c in sgs.qlist(player:getHandcards()) do
					if c:hasFlag(self:objectName()) then
						room:removePlayerCardLimitation(player, "use,response,discard", c:toString().."$0")
						room:removePlayerMark(player, self:objectName())
						room:setCardFlag(c, "-"..self:objectName())
					end
				end
			end
		end
	end
}

xiahuimc = sgs.CreateMaxCardsSkill{
	name = "#xiahuimc",
	extra_func = function(self, target)
		if target:hasSkill("xiahui") then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:isBlack() then
					x = x + 1
				end
			end
			return x
		end
	end
}

dongbai:addSkill(xiahui)
dongbai:addSkill(xiahuimc)

sgs.LoadTranslationTable{
	["dongbai"] = "董白",
	["#dongbai"] = "魔姬",
	["illustrator:dongbai"] = "Sonia Tang",
	["lianzhu"] = "連誅",
	[":lianzhu"] = "出牌階段限一次，你可以展示一張牌並將之交給一名角色，若之為紅色，你摸一張牌；若之為黑色，其選擇是否棄置兩張牌，若其選擇否，你摸兩張牌。",
	["$lianzhu1"] = "若有不臣之心，定當株連九族！",
	["$lianzhu2"] = "你們都是一條繩上的螞蚱~",
	["@lianzhu"] = "你可以弃置两张牌，否则使用者摸两张牌。",
	["xiahui"] = "黠慧",
	["xiahui_self"] = "黠慧",
	["xiahuimc"] = "黠慧",
	--[":xiahui"] = "鎖定技，你於棄牌階段內黑色手牌不計入手牌數且不能棄置；鎖定技，當你因其他角色獲得而失去黑色牌後，令其於其扣減體力或失去此牌前不能使用、打出或棄置之。",
	[":xiahui"] = "鎖定技，妳的黑色手牌不計入手牌上限；當妳因其他角色獲得而失去黑色牌後，令其於其扣減體力或失去此牌前不能使用、打出或棄置之；若其本回合失去過「黠慧」牌且手上沒有「黠慧」牌，其失去一點體力。",
	["~dongbai"] = "放肆！我要讓爺爺，賜你們死罪！",
}
--馬忠
mazhong = sgs.General(extension,"mazhong","shu2","4",true)
--撫蠻：出牌階段，你可以將一張【殺】交給一名其他角色（每名角色每回合限一次）。直到其下回合結束，當該角色使用此【殺】時，你摸一張牌。
fuman_filter = sgs.CreateFilterSkill{
	name = "#fuman_filter",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		return room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
	end,
	view_as = function(self, originalCard)
		local room = sgs.Sanguosha:currentRoom()
		local id = originalCard:getEffectiveId()
		local player = room:getCardOwner(id)
		local card_name
		local card_id

			if player:getMark("fuman_view_as"..originalCard:getId()) > 0 then
				local peach = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
				peach:setSkillName("fuman")
				local card = sgs.Sanguosha:getWrappedCard(id)
				card:takeOver(peach)
				return card
			end

		return originalCard
	end
}

if not sgs.Sanguosha:getSkill("#fuman_filter") then skills:append(fuman_filter) end

fumanCard = sgs.CreateSkillCard{
	name = "fuman" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("fuman_Play") == 0
	end,
	on_use = function(self, room, source, targets)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "fuman","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason, false)

		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:hasSkill("#fuman_filter") then
				room:acquireSkill(p, "#fuman_filter")
			end
		end

		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		--room:addPlayerMark(targets[1], "fuman"..self:getSubcards():first()..source:objectName().."_flag")
		room:addPlayerMark(targets[1], "fuman"..self:getSubcards():first()..source:objectName())
		room:addPlayerMark(targets[1], "fuman_view_as"..self:getSubcards():first())
		room:addPlayerMark(targets[1], "fuman_Play")
	end
}
fumanVS = sgs.CreateViewAsSkill{
	name = "fuman" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		--return to_select:isKindOf("Slash")
		return true
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = fumanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng())
	end
}
--[[
fuman = sgs.CreateTriggerSkill{
	name = "fuman" ,
	global = true,
	events = {sgs.CardUsed,sgs.EventPhaseEnd, sgs.CardResponded} ,
	view_as_skill = fumanVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local card = data:toCardUse().card
			if card and (not card:isKindOf("SkillCard")) then
				local n = card:getSubcards():length()
				if n > 0 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						for _, id in sgs.qlist(card:getSubcards()) do
							if player:getMark("fuman"..id..p:objectName().."_flag") > 0 then
								room:sendCompulsoryTriggerLog(p, self:objectName())
								p:drawCards(1, self:objectName())
							end
						end
					end
				else
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("fuman"..card:getEffectiveId()..p:objectName().."_flag") > 0 then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							p:drawCards(1, self:objectName())
						end
					end
				end	
			end
		end
		if event == sgs.CardResponded then
			local card = data:toCardResponse().m_card
			if card and (not card:isKindOf("SkillCard")) then
				local n = card:getSubcards():length()
				if n > 0 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						for _, id in sgs.qlist(card:getSubcards()) do
							if player:getMark("fuman"..id..p:objectName().."_flag") > 0 then
								room:sendCompulsoryTriggerLog(p, self:objectName())
								p:drawCards(1, self:objectName())
							end
						end
					end
				else
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("fuman"..card:getEffectiveId()..p:objectName().."_flag") > 0 then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							p:drawCards(1, self:objectName())
						end
					end
				end
			end
		end
	end,
}
]]--

fuman = sgs.CreateTriggerSkill{
	name = "fuman",
	events = {sgs.CardFinished, sgs.CardResponded,sgs.CardsMoveOneTime},
	view_as_skill = fumanVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished or event == sgs.CardResponded then
			local card
			if event == sgs.CardFinished then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if card and not card:isKindOf("SkillCard") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					--for _, id in sgs.qlist(card:getSubcards()) do
						if player:getMark(self:objectName()..card:getId()..p:objectName()) > 0 then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							if card:hasFlag("damage_record") then
								p:drawCards(2, self:objectName())
							else
								p:drawCards(1, self:objectName())
							end
						end
					--end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and move.from_places:contains(sgs.Player_PlaceHand)) or (move.to and move.to_place == sgs.Player_PlaceHand) then
				if not player:isKongcheng() then
					room:filterCards(player, player:getHandcards(), true)

					for _, c in sgs.qlist(player:getHandcards()) do
						if player:getMark("fuman_view_as"..c:getId()) > 0 then
							local show_card_log = sgs.LogMessage()
							show_card_log.type = "$fuman"
							show_card_log.from = player
							show_card_log.to:append(player)
							show_card_log.card_str = c:getEffectiveId()
							show_card_log.arg = "fuman"
							room:sendLog(show_card_log)
						end
					end
				end
			end

			if move.to_place == sgs.Player_DiscardPile then
				for _, id in sgs.qlist(move.card_ids) do
					if player:getMark("fuman_view_as"..id) > 0 then
						room:setPlayerMark(player,"fuman_view_as"..id,0)

						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if player:getMark(self:objectName()..id..p:objectName()) > 0 then
								room:setPlayerMark(player,self:objectName()..id..p:objectName(),0)
							end
						end
					end
				end
			end
		end
		return false
	end
}


mazhong:addSkill(fuman)

sgs.LoadTranslationTable{
	["mazhong"] = "馬忠",
	["#mazhong"] = "",
	["&mazhong"] = "馬忠",
	["fuman"] = "撫蠻",
	--[":fuman"] = "出牌階段，你可以將一張【殺】交給一名其他角色（每名角色每回合限一次）。直到其下回合結束，當該角色使用此【殺】時，你摸一張牌。",
	[":fuman"] = "出牌階段每名角色限一次，你可以將一張手牌交給一名其他角色並標記為「撫蠻」且「撫蠻」牌的牌名視為【殺】。"..
"然後當一名角色使用「撫蠻」牌結算結束後，你摸一張牌。若此牌造成過傷害，則改為摸兩張牌。",
	["$fuman1"] = "恩威并施，蛮夷可为我所用。",
	["$fuman2"] = "发兵器啦！",
		["$fuman"] = "因 %arg 效果影響， %from 的手牌為 %card 視為【 殺 】",
}

--賀齊
heqi = sgs.General(extension,"heqi","wu","4",true)
--綺冑：鎖定技，若裝備區裡的花色數：不小於1，你擁有“馬術”；不小於2，你擁有“英姿”；不小於3，你擁有“短兵”；為4，你擁有“奮威”。

function equip_change_acquire_or_detach_skill(room, player, skill_name_list)
	local skill_name_table = skill_name_list:split("|")
	for _, skill_name in ipairs(skill_name_table) do
		if string.startsWith(skill_name, "-") then
			local real_skill_name = string.gsub(skill_name, "-", "")
			if player:hasSkill(real_skill_name) then
				room:handleAcquireDetachSkills(player, skill_name, true)
			end
		else
			if not player:hasSkill(skill_name) then
				room:handleAcquireDetachSkills(player, skill_name, true)
			end
		end
	end
end

qizhou_fenwei_use_check = sgs.CreateTriggerSkill{
	name = "qizhou_fenwei_use_check",
	events = {sgs.CardUsed},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == "fenwei" and use.from and use.from:hasSkill("qizhou") then
			room:addPlayerMark(use.from, "used_fenwei")
		end
	end
}

if not sgs.Sanguosha:getSkill("qizhou_fenwei_use_check") then skills:append(qizhou_fenwei_use_check) end

qizhou = sgs.CreateTriggerSkill{
	name = "qizhou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip)) or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) then
			local suit = {}
			for _,card in sgs.qlist(player:getEquips()) do
				if not table.contains(suit, card:getSuit()) then
				table.insert(suit, card:getSuit())
				end
			end
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if #suit >= 1 then
				room:broadcastSkillInvoke(self:objectName())
				equip_change_acquire_or_detach_skill(room, player, "mashu|-yingzi|-ol_duanbing|-fenwei")
				if #suit >= 2 then
					equip_change_acquire_or_detach_skill(room, player, "mashu|yingzi|-ol_duanbing|-fenwei")
					if #suit >= 3 then
						equip_change_acquire_or_detach_skill(room, player, "mashu|yingzi|ol_duanbing|-fenwei")
						if #suit >= 4 then
							equip_change_acquire_or_detach_skill(room, player, "mashu|yingzi|ol_duanbing|fenwei")
							if player:getMark("used_fenwei") > 0 then
								room:removePlayerMark(player, "@fenwei")
							end
						end
					end
				end
			end
			if #suit == 0 then
				equip_change_acquire_or_detach_skill(room, player, "-mashu|-yingzi|-ol_duanbing|-fenwei")
			end
			--以下有些狀況(尤其重複脫或裝裝備)會無法獲得技能
--			if #suit >= 1 then
--				room:broadcastSkillInvoke(self:objectName())
--				room:acquireSkill(player, "mashu")
--				if #suit >= 2 then
--					room:acquireSkill(player, "nosyingzi")
--					if #suit >= 3 then
--						room:acquireSkill(player, "ol_duanbing")
--						if #suit >= 4 then
--							room:acquireSkill(player, "fenwei")
--							if player:getMark("used_fenwei") > 0 then
--								room:removePlayerMark(player, "@fenwei")
--							end
--						else
--							if player:getMark("@fenwei") == 0 then
--								room:addPlayerMark(player, "used_fenwei")
--							end
--							room:detachSkillFromPlayer(player, "fenwei", false, true)
--						end
--					else
--						room:detachSkillFromPlayer(player, "ol_duanbing", false, true)
--					end
--				else
--					room:detachSkillFromPlayer(player, "nosyingzi", false, true)
--				end
--			else
--				room:detachSkillFromPlayer(player, "mashu", false, true)
--			end
		end
	end
}
--閃襲：出牌階段限一次，你可以棄置攻擊範圍內的一名其他角色的一張牌，若棄置的牌是【閃】，你觀看其手牌，若棄置的不是【閃】，其觀看你的手牌。

shanxiCard = sgs.CreateSkillCard{
	name = "shanxi",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select) and sgs.Self:canDiscard(to_select, "he")
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local card = sgs.Sanguosha:getCard(room:askForCardChosen(source, targets[1], "he", self:objectName(), false, sgs.Card_MethodDiscard))
			room:throwCard(card, targets[1], source)
			if card:isKindOf("Jink") and not targets[1]:isKongcheng() then
				room:showAllCards(targets[1], source)
			elseif not card:isKindOf("Jink") and not source:isKongcheng() then
				room:showAllCards(source, targets[1])
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
shanxi = sgs.CreateOneCardViewAsSkill{
	name = "shanxi",
	filter_pattern = "BasicCard|red",
	view_as = function(self, card)
		local aaa = shanxiCard:clone()
		aaa:addSubcard(card)
		return aaa
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#shanxi")
	end
}
heqi:addSkill(shanxi)
heqi:addSkill(qizhou)
heqi:addRelateSkill("mashu")
--heqi:addRelateSkill("nosyingzi")
heqi:addRelateSkill("yingzi")
heqi:addRelateSkill("ol_duanbing")
heqi:addRelateSkill("fenwei")

sgs.LoadTranslationTable{
	["heqi"] = "賀齊",
	["#heqi"] = "",
	["&heqi"] = "賀齊",
	["qizhou"] = "綺冑",
	[":qizhou"] = "鎖定技，若裝備區裡的花色數：不小於1，你擁有“馬術”；不小於2，你擁有“英姿”；不小於3，你擁有“短兵”；為4，你擁有“奮威”。",
	["shanxi"] = "閃襲",
	[":shanxi"] = "出牌階段限一次，你可以棄置攻擊範圍內的一名其他角色的一張牌，若棄置的牌是【閃】，你觀看其手牌，若棄置的不是【閃】，其觀看你的手牌。",
	["$qizhou1"] = "人靠衣装，马靠鞍~",
	["$qizhou2"] = "可真是把好刀啊~",
	["$qizhou3"] = "我的船队，要让全建业城都看见~",
	["$shanxi1"] = "敌援未到，需要速战速决！",
	["$shanxi2"] = "快马加鞭，赶在敌人戒备之前！",
}

--麋竺
mizhu = sgs.General(extension,"mizhu","shu","3",true)
--資援
ziyuanCard = sgs.CreateSkillCard{
	name = "ziyuan" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "ziyuan","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		local theRecover = sgs.RecoverStruct()
		theRecover.recover = 1
		theRecover.who = source
		room:recover(targets[1], theRecover)
	end
}
ziyuan = sgs.CreateViewAsSkill{
	name = "ziyuan" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected == 0 then
			return (not to_select:isEquipped())
		elseif #selected > 0 then
			local count = 0
			for i = 1, #selected ,1 do
				local card1 = selected[i]			
				count = count + card1:getNumber()
			end
			if to_select:getNumber() + count <= 13 then
				return (not to_select:isEquipped())
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local count = 0
		for _, c in ipairs(cards) do
			count = count + c:getNumber()
		end
		if count ~= 13 then return nil end
		local card = ziyuanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self,player)
		return player:usedTimes("#ziyuan") < 1
	end
}
--
jugu = sgs.CreateTriggerSkill{
	name = "jugu" ,
	events = {sgs.GameStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(player:getMaxHp())
		end
	end
}

juguMax = sgs.CreateMaxCardsSkill{
	name = "#jugu", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		if target:hasSkill("jugu") then
			return target:getMaxHp()
		end
	end
}


mizhu:addSkill(ziyuan)
mizhu:addSkill(jugu)
mizhu:addSkill(juguMax)
extension:insertRelatedSkills("jugu","#jugu")

sgs.LoadTranslationTable{
	["mizhu"] = "糜竺",
	["#mizhu"] = "富賈一方",
	["ziyuan"] = "資援",
	[":ziyuan"] = "出牌階段限一次，你可以將任意張點數之和為13的手牌交給一名其他角色，然後該角色回復1點體力。",
	["jugu"] = "巨賈",
	[":jugu"] = "鎖定技，你的手牌上限+X；遊戲開始時，你多摸X張牌。 （X為你的體力上限數）",
["$ziyuan1"] = "區區薄禮，萬望使君笑納~",
["$ziyuan2"] = "雪中送炭，以解君愁。",
["$jugu1"] = "錢~要多少有多少！",
["$jugu2"] = "君子愛財，取之有道~",
}
--孫乾
sunqian = sgs.General(extension,"sunqian","shu","3",true)
--謙雅
qianya = sgs.CreateTriggerSkill{
	name = "qianya" ,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.to:contains(player) and use.card:isKindOf("TrickCard") and not player:isKongcheng() then
			if room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, -1, sgs.SPlayerList(), sgs.CardMoveReason(), "@qianya", true) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
--説盟
shuimeng = sgs.CreateTriggerSkill{
	name = "shuimeng" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ==  sgs.Player_Play and not player:isKongcheng() then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					_targets:append(p)
				end
			end
			if not _targets:isEmpty() then
				local s = room:askForPlayerChosen(player, _targets, "shuimeng", "shuimeng-invoke", true)
				if s then
					--room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player, "shuimeng")
					room:doAnimate(1, player:objectName(), s:objectName())
					local success = player:pindian(s, "shuimeng", nil)
					if success then
						local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
						ex_nihilo:setSkillName("shuimeng")
						local use = sgs.CardUseStruct()
						use.card = ex_nihilo
						use.from = player
						--local dest = s
						--use.to:append(player)
						room:useCard(use)
					else
						local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
						dismantlement:setSkillName("shuimeng")
						local use = sgs.CardUseStruct()
						use.card = dismantlement
						use.from = s
						local dest = player
						use.to:append(dest)
						room:useCard(use)
					end
				end
			end
		end
	end
}

sunqian:addSkill(qianya)
sunqian:addSkill(shuimeng)

sgs.LoadTranslationTable{
	["sunqian"] = "孫乾",
	["#sunqian"] = "",
	["qianya"] = "謙雅",
	[":qianya"] = "當你成為錦囊牌的目標後，你可以將任意張手牌交給一名其他角色。",
	["shuimeng"] = "說盟",
	[":shuimeng"] = "出牌階段結束時，你可以與一名角色拼點，若你贏，視為你使用【無中生有】；若你沒贏，視為其對你使用【過河拆橋】",
	["@qianya"] = "你可以將任意張手牌交給一名其他角色",
	["~qianya"] = "選擇任意手牌，然後點選一名角色",
	["shuimeng-invoke"] = "你可以發動“說盟”",
}
--王朗
wanglang = sgs.General(extension, "wanglang", "wei", 3, true)

gusheCard = sgs.CreateSkillCard{
	name = "gushe", 
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 3 and (not to_select:isKongcheng())
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if #targets == 1 then
				source:pindian(targets[1], "gushe", sgs.Sanguosha:getCard(self:getSubcards():first()))
				source:setFlags("-jiciused")
				return
			end
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:addSubcard(self:getSubcards():first())
			local moves = sgs.CardsMoveList()
			local move = sgs.CardsMoveStruct(self:getSubcards(), source, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, source:objectName(), self:objectName(), ""))
			moves:append(move)
			for _, p in pairs(targets) do
				local card = room:askForExchange(p, self:objectName(), 1, 1, false, "@gushe_Pindian:"..source:objectName())
				slash:addSubcard(card:getSubcards():first())
				room:setPlayerMark(p, "gusheid", card:getSubcards():first()+1)
				local move = sgs.CardsMoveStruct(card:getSubcards(), p, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, p:objectName(), self:objectName(), ""))
				moves:append(move)
			end
			room:moveCardsAtomic(moves, true)
			for i = 1, #targets, 1 do
				local pindian = sgs.PindianStruct()
				pindian.from = source
				pindian.to = targets[i]
				pindian.from_card = sgs.Sanguosha:getCard(self:getSubcards():first())
				pindian.to_card = sgs.Sanguosha:getCard(targets[i]:getMark("gusheid") - 1)
				if not source:hasFlag("jiciused") then
					pindian.from_number = pindian.from_card:getNumber()
				else
					pindian.from_number = pindian.from_card:getNumber() + source:getMark("@tongue")
				end
				pindian.to_number = pindian.to_card:getNumber()
				pindian.reason = "gushe"
				room:setPlayerMark(targets[i], "gusheid", 0)
				local data = sgs.QVariant()
				data:setValue(pindian)
				local log = sgs.LogMessage()
				log.type = "$PindianResult"
				log.from = pindian.from
				log.card_str = pindian.from_card:toString()
				room:sendLog(log)
				log.from = pindian.to
				log.card_str = pindian.to_card:toString()
				room:sendLog(log)
				if not source:hasFlag("jiciused") then
					room:getThread():trigger(sgs.PindianVerifying, room, source, data)
				end
				room:getThread():trigger(sgs.Pindian, room, source, data)
			end
			source:setFlags("-jiciused")
			local move2 = sgs.CardsMoveStruct(slash:getSubcards(), nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
			room:moveCardsAtomic(moves, true)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
gusheVS = sgs.CreateOneCardViewAsSkill{
	name = "gushe", 
	filter_pattern = ".|.|.|hand!",
	view_as = function(self, card)
		local aaa = gusheCard:clone()
		aaa:addSubcard(card)
		return aaa
	end, 
	enabled_at_play = function(self, player)
		return player:usedTimes("#gushe") < 1 + player:getMark("jiciextra-Clear")
	end
}
gushe = sgs.CreateTriggerSkill{
	name = "gushe", 
	events = {sgs.Pindian, sgs.CardFinished},
	view_as_skill = gusheVS, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason ~= self:objectName() then return false end
			local winner
			local loser
			if pindian.from_number > pindian.to_number then
				winner = pindian.from
				loser = pindian.to
				local log = sgs.LogMessage()
				log.type = "#PindianSuccess"
				log.from = winner
				log.to:append(loser)
				room:sendLog(log)
			elseif pindian.from_number < pindian.to_number then
				winner = pindian.to
				loser = pindian.from
				local log = sgs.LogMessage()
				log.type = "#PindianFailure"
				log.from = loser
				log.to:append(winner)
				room:sendLog(log)
				pindian.from:gainMark("@tongue")
			else
				pindian.from:gainMark("@tongue")
				if pindian.from:isAlive()  and not room:askForDiscard(pindian.from, self:objectName(), 1, 1, true, true,"@gushePunish:"..pindian.from:objectName()) then
					pindian.from:drawCards(1, self:objectName())
				end
				if pindian.to:isAlive() then
					if pindian.from:isAlive() then
						if not room:askForDiscard(pindian.to, self:objectName(), 1, 1, true, true,"@gushePunish:"..pindian.from:objectName()) then
							pindian.from:drawCards(1, self:objectName())
						end
					else
						room:askForDiscard(pindian.to, self:objectName(), 1, 1, true)
					end
				end
				return false
			end
			if pindian.from:isAlive() then
				if loser:isAlive() and not room:askForDiscard(loser, self:objectName(), 1, 1, true, true,"@gushePunish:"..pindian.from:objectName()) then
					pindian.from:drawCards(1, self:objectName())
				end
			else
				if loser:isAlive() and not loser:isNude() then
					room:askForDiscard(loser, self:objectName(), 1, 1)
					--room:askForDiscard(loser, self:objectName(), 1, 1, true, true)
				end
			end
			if pindian.from:hasSkill("gushe") and pindian.from:getMark("@tongue") >= 7 then
				room:killPlayer(pindian.from)
			end
		else
			if player:hasSkill("gushe") and player:getMark("@tongue") >= 7 then
				room:killPlayer(player)
			end
		end
		return false
	end, 
	can_trigger = function(self, player)
		return player and player:isAlive()
	end
}
wanglang:addSkill(gushe)
jici = sgs.CreateTriggerSkill{
	name = "jici", 
	events = sgs.PindianVerifying, 
	on_trigger = function(self, event, player, data, room)
		local pindian = data:toPindian()
		if pindian.reason == "gushe" and pindian.from:objectName() == player:objectName() then
			local x = player:getMark("@tongue")
			if pindian.from_number <= x and player:askForSkillInvoke(self:objectName()) then
				if pindian.from_number < x then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						player:setFlags("jiciused")
						local log = sgs.LogMessage()
						log.type = "#jicipindian"
						log.from = pindian.from
						log.arg = pindian.from_number
						pindian.from_number = pindian.from_number + x
						if pindian.from_number > 13 then pindian.from_number = 13 end
						log.arg2 = pindian.from_number
						room:sendLog(log)
						data:setValue(pindian)
						room:removePlayerMark(player, self:objectName().."engine")
						--return
					end
				end
				if pindian.from_number == x then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:setPlayerFlag(player, "jiciused")
						room:addPlayerMark(player, "jiciextra-Clear")
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}
wanglang:addSkill(jici)

sgs.LoadTranslationTable{
	["wanglang"] = "王朗",
	["&wanglang"] = "王朗",
	["#wanglang"] = "鳳鶥",
	["cv:wanglang"] = "無",
	["illustrator:wanglang"] = "無",

	["gushe"] = "鼓舌",
	[":gushe"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可用一張手牌與一至三名角色同時拼點，然後依次結算：若你沒贏，你獲得1枚“饒舌”標記，然後若你擁有的“饒舌”標記數為7，你死亡；拼點沒贏的角色選擇一項：1. 棄置一張牌；2. 令你摸一張牌。",
	["@tongue"] = "饒舌",
	["@gusheDiscard"] = "請棄置一張牌，否則 %src 摸一張牌",

	["jici"] = "激詞",
	[":jici"] = "當你發動“鼓舌”拼點的牌亮出後，若此牌的點數：小於X，你可令此牌的點數於此次拼點中+X；等於X ，你於此階段內發動“鼓舌”的次數上限+1。（X為你擁有的“饒舌”標記數）",
	["jici:Increase"] = "你可發動“激詞”令你拼點的牌點數 + %arg",
	["#jiciIncrease"] = "%from 發動了“<font color=\"yellow\"><b>激詞</b></font>”，拼點的牌點數增加為 %arg",
	["#jiciExtra"] = "%from 拼點的牌點數為%arg （與“饒舌”標記數相同），發動“<font color=\"yellow\"><b>鼓舌</b>< /font>”的次數上限+ <font color=\"yellow\"><b>1</b></font>",
	["@gushePunish"] = "請棄置一張牌，否則 %src 摸一張牌",
	["@gushe_Pindian"] = " %src 發起鼓舌拼點，你需出一張牌拼點",
	["$gushe1"] = "公既知天命，識時務，為何要興無名之師？犯我疆界？",
	["$gushe2"] = "你若倒戈卸甲，以禮來降，仍不失封侯之位，國安民樂，豈不美哉？",
	["$jici1"] = "諒爾等腐草之熒光，如何比得上天空之皓月~",
	["$jici2"] = "你……諸葛村夫，你敢……",
}

--懷舊王允
nos_wangyun = sgs.General(extension, "nos_wangyun", "qun2", 4, true, true)
--連計

nos_lianji_use = sgs.CreateOneCardViewAsSkill{
	name = "nos_lianji_use",
	view_filter = function(self, card)
		return card:hasFlag("nos_lianji") and not card:isKindOf("Lightning")
	end,
	view_as = function(self, card)
		card:setSkillName("nos_lianji")
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@nos_lianji_use"
	end
}
if not sgs.Sanguosha:getSkill("nos_lianji_use") then skills:append(nos_lianji_use) end

nos_lianjiCard = sgs.CreateSkillCard{
	name = "nos_lianji",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "nos_lianji_source-Clear")
		room:addPlayerMark(targets[1], "nos_lianji_target-Clear")
		local give_card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:obtainCard(targets[1], give_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		useEquipFornos_wangyun(room, targets[1], "Weapon", true)
		room:setCardFlag(give_card, "nos_lianji")
		if give_card:isAvailable(targets[1]) and room:askForUseCard(targets[1], "@@nos_lianji_use", "@nos_lianji_use", -1, sgs.Card_MethodUse) then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("nos_lianji_victim-Clear") > 0 then
					players:append(p)
				end
			end
			local weapon_to_victim = room:askForPlayerChosen(targets[1], players, self:objectName(), "nos_lianji-invoke", false, true)
			local target_weapon = targets[1]:getWeapon()
			if weapon_to_victim and target_weapon then
				if weapon_to_victim:objectName() ~= targets[1]:objectName() then
					room:moveCardTo(target_weapon, weapon_to_victim, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), weapon_to_victim:objectName(), self:objectName(), ""))
				else
					room:moveCardTo(target_weapon, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
				end
			end
		else
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= source:objectName() and p:objectName() ~= targets[1]:objectName() then
					room:addPlayerMark(p, "nos_lianji_cancel_observer-Clear")
				end
			end
			
			if not give_card:isKindOf("Nullification") and not give_card:isKindOf("Collateral")
			and not give_card:isKindOf("DelayedTrick")
			then
				local virtual_use_card = sgs.Sanguosha:cloneCard(give_card:objectName(), give_card:getSuit(), give_card:getNumber())
				virtual_use_card:setSkillName(self:objectName())
				room:useCard(sgs.CardUseStruct(virtual_use_card, source, targets[1]))
			end
			
			local target_weapon = targets[1]:getWeapon()
			if target_weapon then
				room:moveCardTo(target_weapon, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
			end
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("nos_lianji_cancel_observer-Clear") > 0 then
				room:setPlayerMark(p, "nos_lianji_cancel_observer-Clear", 0)
			end
		end
		room:setPlayerMark(source, "nos_lianji_source-Clear", 0)
		room:setPlayerMark(targets[1], "nos_lianji_target-Clear", 0)
		room:setCardFlag(give_card, "-nos_lianji")
	end
}
nos_lianjiVS = sgs.CreateOneCardViewAsSkill{
	name = "nos_lianji",
	view_filter = function(self, card)
		return card:isKindOf("Slash") or (card:isBlack() and card:isKindOf("TrickCard"))
	end,
	view_as = function(self, card)
		local nos_lianjicard = nos_lianjiCard:clone()
		nos_lianjicard:addSubcard(card)
		return nos_lianjicard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#nos_lianji")
	end
}
nos_lianji = sgs.CreateTriggerSkill{
	name = "nos_lianji",
	events = {sgs.CardUsed, sgs.Damage},
	view_as_skill = nos_lianjiVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:hasFlag("nos_lianji") then
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, "nos_lianji_victim-Clear")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local nos_lianji_source = nil
			--if damage.card and damage.card:hasFlag("nos_lianji") and damage.damage > 0 then
			if damage.card and damage.card:getSkillName() == "nos_lianji" and damage.damage > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("nos_lianji_source-Clear") > 0 then
						nos_lianji_source = p
					end
				end
				if nos_lianji_source then
					for i = 1, damage.damage, 1 do
						room:addPlayerMark(nos_lianji_source, "@nos_lianji_damge_counter")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
nos_lianjiProhibit = sgs.CreateProhibitSkill{
	name = "#nos_lianjiProhibit",
	is_prohibited = function(self, from, to, card)
		return (from:getMark("nos_lianji_target-Clear") > 0 and to:getMark("nos_lianji_source-Clear") > 0) or (to:getMark("nos_lianji_cancel_observer-Clear") > 0)
	end
}
nos_wangyun:addSkill(nos_lianji)
nos_wangyun:addSkill(nos_lianjiProhibit)
--謀逞
nos_moucheng = sgs.CreateTriggerSkill{
	name = "nos_moucheng",
	frequency = sgs.Skill_Wake,
	priority = -1,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if (p:getMark("@nos_lianji_damge_counter") == 3 or p:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) and p:getMark(self:objectName()) == 0 and p:getMark("nos_lianji_source-Clear") > 0 and p:hasSkill("nos_moucheng") then
				room:doSuperLightbox("wangyun","nos_moucheng")
				room:addPlayerMark(p, self:objectName())
				room:sendCompulsoryTriggerLog(p, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:handleAcquireDetachSkills(p, "-nos_lianji|nos_jingong")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
nos_wangyun:addSkill(nos_moucheng)

nos_jingong_do_not_randomize_tag_clearer = sgs.CreateTriggerSkill{
	name = "nos_jingong_do_not_randomize_tag_clearer",
	global = true,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if player:getTag("nos_jingong_do_not_randomize"):toString() ~= "" and player:getPhase() == sgs.Player_Play then
			player:setTag("nos_jingong_do_not_randomize", sgs.QVariant())
		end
		if player:getTag("mobile_nos_jingong"):toString() ~= "" and player:getPhase() == sgs.Player_Play then
			player:setTag("mobile_nos_jingong", sgs.QVariant())
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

if not sgs.Sanguosha:getSkill("nos_jingong_do_not_randomize_tag_clearer") then skills:append(nos_jingong_do_not_randomize_tag_clearer) end


nos_jingong_select = sgs.CreateSkillCard{
	name = "nos_jingong",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		if source:getTag("nos_jingong_do_not_randomize"):toString() ~= "" then
			local already_generate_choice_lists = source:getTag("nos_jingong_do_not_randomize"):toString():split("+")
			for _, list in ipairs(already_generate_choice_lists) do
				local list_card = sgs.Sanguosha:cloneCard(list, sgs.Card_NoSuit, -1)
				if list_card:isAvailable(source) then
					table.insert(choices, list)
				end
			end
		else
			local available_tricks = {}
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(available_tricks, card:objectName())) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
					if card:isKindOf("TrickCard") and card:isAvailable(source) then
						table.insert(available_tricks, card:objectName())
					end
				end
			end
			if next(available_tricks) ~= nil then
				table.insert(choices, available_tricks[math.random(1, #available_tricks)])
				source:setTag("nos_jingong_do_not_randomize", sgs.QVariant(table.concat(choices, "+")))
			end
		end
		if not table.contains(choices, "meirenji") then
			table.insert(choices, "meirenji")
		end
		if not table.contains(choices, "xiaolicangdao") then
			table.insert(choices, "xiaolicangdao")
		end
		table.insert(choices, "cancel")
		local pattern = room:askForChoice(source, "nos_jingong", table.concat(choices, "+"))
		if pattern and pattern ~= "cancel" then
			local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
			if poi:targetFixed() then
				poi:setSkillName("nos_jingong")
				poi:addSubcard(self:getSubcards():first())
				room:useCard(sgs.CardUseStruct(poi, source, source),true)
			else
				pos = getPos(patterns, pattern)
				room:setPlayerMark(source, "nos_jingongpos", pos)
				room:setPlayerProperty(source, "nos_jingong", sgs.QVariant(self:getSubcards():first()))
				room:askForUseCard(source, "@@nos_jingong", "@nos_jingong:"..pattern)--%src
			end
		end
	end
}
nos_jingongCard = sgs.CreateSkillCard{
	name = "nos_jingong_validate",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			card:addSubcard(self:getSubcards():first())
			if card and card:targetFixed() then
				return false
			else
				return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			end
		end
		return true
	end,
	target_fixed = function(self)
		local name = ""
		local card
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(user, "nos_jingong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("nos_jingong")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(card_use.from, "nos_jingong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("nos_jingong")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card)	then
				available = false
				break
			end
		end
		if not available then return nil end
		use_card:addSubcard(self:getSubcards():first())
		return use_card
	end
}
nos_jingongVS = sgs.CreateViewAsSkill{
	name = "nos_jingong",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@nos_jingong" then
			return false
		end
		return to_select:isKindOf("Slash") or to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local skillcard = nos_jingong_select:clone()
				skillcard:addSubcard(cards[1]:getId())
				return skillcard
			end
		else
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@@nos_jingong" then
				local need_target_skillcard = nos_jingongCard:clone()
				pattern = patterns[sgs.Self:getMark("nos_jingongpos")]
				need_target_skillcard:addSubcard(sgs.Self:property("nos_jingong"):toInt())
				if #cards ~= 0 then return end
				need_target_skillcard:setUserString(pattern)
				return need_target_skillcard
			end
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("nos_jingong-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@nos_jingong"
	end
}
nos_jingong = sgs.CreateTriggerSkill{
	name = "nos_jingong",
	view_as_skill = nos_jingongVS,
	events = {sgs.Damage, sgs.EventPhaseChanging, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName()) and damage.by_user
			and damage.card and damage.card:getSkillName() == self:objectName() and damage.damage > 0 then
				room:addPlayerMark(damage.from, "nos_jingong_has_damge")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				if player:getMark("nos_jingong_has_damge") == 0 and player:getMark("nos_jingong-Clear") > 0 then
					local log = sgs.LogMessage()
					log.type = "$nos_jingong_fail"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					room:loseHp(player)
					room:setPlayerMark(player, "nos_jingong_has_damge", 0)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == self:objectName() and use.card:getTypeId() ~= 0 then
				room:addPlayerMark(player, "nos_jingong-Clear")
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("nos_jingong") then skills:append(nos_jingong) end

nos_wangyun:addRelateSkill("nos_jingong")

sgs.LoadTranslationTable{
	["nos_wangyun"] = "懷舊王允",
	["&nos_wangyun"] = "王允",
	["#nos_wangyun"] = "忠魂不泯",
	["illustrator:nos_wangyun"] = "Thinking",
	["nos_lianji"] = "連計",
	["moblile_nos_lianji"] = "連計",
	[":nos_lianji"] = "出牌階段限一次，你可以交給一名其他角色一張【殺】或黑色錦囊牌，並令該角色使用牌堆中的隨機一張武器牌。然後該角色選擇一項：1.對除你以外的角色使用該牌，並將裝備區裡的武器牌交給該牌的一個目標角色；2.視為你對其使用此牌，並將裝備區內的武器牌交給你。",
	["@nos_lianji_use"] = "你可以使用“連計”的牌，點取消視為其對你使用此牌",
	["~nos_lianji_use"] = "選擇“連計”牌→若有目標選擇目標→點擊確定",
	["nos_lianji-invoke"] = "請選擇你目前武器要給的目標",
	["$nos_lianji1"] = "兩計扣用，以摧強勢。",
	["$nos_lianji2"] = "容老夫細細思量。",
	["nos_moucheng"] = "謀逞",
	[":nos_moucheng"] = "覺醒技，當其他角色使用因“連計”交給其的牌累計造成傷害達到3點後，你失去技能“連計”，然後獲得技能“矜功”。" ,
	["$nos_moucheng1"] = "董賊伏誅，天下太平！",
	["$nos_moucheng2"] = "叫天不應，叫地不靈，今天就是你的死期。",
	["nos_jingong"] = "矜功",
	[":nos_jingong"] = "出牌階段限一次，你可以將一張裝備牌或【殺】當一張隨機錦囊牌使用（三選一），然後本回合的結束階段，若你於本回合內未造成過傷害，你失去1點體力。（包含專屬錦囊【美人計】和【笑裡藏刀】）",
	["@nos_jingong"] = "請選擇目標",
	["~nos_jingong"] = "選擇若干名角色→點擊確定",
	["$nos_jingong1"] = "董賊舊部，可盡誅之。",
	["$nos_jingong2"] = "若無老夫之謀，爾等皆化為腐土也。",
	["~nos_wangyun"] = "努力謝關東諸公，勤以國家為念。",
}

--王允
wangyun = sgs.General(extension, "wangyun", "qun2", 4, true)
--連計  出牌階段限一次，你可以棄置一張手牌，令一名角色使用牌堆中的一張隨機武器牌。然後其選擇一項：對你指定的一名角色使用一張【殺】，或令你將其裝備區里的武器牌交給任意角色。

lianjiCard = sgs.CreateSkillCard{
	name = "lianji",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		useEquipForWangYun(room, targets[1], "Weapon", true)

		local victim = room:askForPlayerChosen(source, room:getOtherPlayers(targets[1]), "lianji_slash", "@dummy-slash2:" .. targets[1]:objectName())
		room:addPlayerMark(source,"lianji_source-Clear")
		room:addPlayerMark(targets[1],"lianji_target-Clear")
		if not room:askForUseSlashTo(targets[1], victim, "zhongyong_po_slash", false, false, false) then
			local weapon_to_victim = room:askForPlayerChosen(source, room:getOtherPlayers(targets[1]), self:objectName(), "lianji-invoke", true, true)
			local target_weapon = targets[1]:getWeapon()
			if weapon_to_victim and target_weapon then
				room:moveCardTo(target_weapon, weapon_to_victim, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), weapon_to_victim:objectName(), self:objectName(), ""))
			end
		end
		room:removePlayerMark(source,"lianji_source-Clear")
		room:removePlayerMark(targets[1],"lianji_target-Clear")
	end
}
lianjiVS = sgs.CreateOneCardViewAsSkill{
	name = "lianji",
	view_filter = function(self, card)
		return not card:isEquipped()
	end,
	view_as = function(self, card)
		local lianjicard = lianjiCard:clone()
		lianjicard:addSubcard(card)
		return lianjicard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lianji")
	end
}
lianji = sgs.CreateTriggerSkill{
	name = "lianji",
	events = {sgs.CardUsed, sgs.Damage},
	view_as_skill = lianjiVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:hasFlag("lianji") then
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, "lianji_victim-Clear")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local lianji_source = nil
			--if damage.card and damage.card:hasFlag("lianji") and damage.damage > 0 then
			if damage.card and damage.damage > 0 and player:getMark("lianji_target-Clear") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("lianji_source-Clear") > 0 then
						lianji_source = p
					end
				end
				if lianji_source then
					for i = 1, damage.damage, 1 do
						room:addPlayerMark(lianji_source, "@lianji_damge_counter")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

wangyun:addSkill(lianji)

--謀逞  覺醒技，準備階段，若有角色因你發動〖連計〗使用【殺】而造成過傷害，則你失去〖連計〗並獲得〖矜功〗。
moucheng = sgs.CreateTriggerSkill{
	name = "moucheng",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_RoundStart then
			if (player:getMark("@lianji_damge_counter") > 0 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) and player:getMark(self:objectName()) == 0 then
				room:doSuperLightbox("wangyun","moucheng")
				room:addPlayerMark(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:handleAcquireDetachSkills(player, "-lianji|jingong")
			end
		end
		return false
	end,

}
wangyun:addSkill(moucheng)

jingong_do_not_randomize_tag_clearer = sgs.CreateTriggerSkill{
	name = "jingong_do_not_randomize_tag_clearer",
	global = true,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if player:getTag("jingong_do_not_randomize"):toString() ~= "" and player:getPhase() == sgs.Player_Play then
			player:setTag("jingong_do_not_randomize", sgs.QVariant())
		end
		if player:getTag("mobile_jingong"):toString() ~= "" and player:getPhase() == sgs.Player_Play then
			player:setTag("mobile_jingong", sgs.QVariant())
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

if not sgs.Sanguosha:getSkill("jingong_do_not_randomize_tag_clearer") then skills:append(jingong_do_not_randomize_tag_clearer) end


jingong_select = sgs.CreateSkillCard{
	name = "jingong",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		if source:getTag("jingong_do_not_randomize"):toString() ~= "" then
			local already_generate_choice_lists = source:getTag("jingong_do_not_randomize"):toString():split("+")
			for _, list in ipairs(already_generate_choice_lists) do
				local list_card = sgs.Sanguosha:cloneCard(list, sgs.Card_NoSuit, -1)
				if list_card:isAvailable(source) then
					table.insert(choices, list)
				end
			end
		else
			local available_tricks = {}
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(available_tricks, card:objectName())) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
					if card:isKindOf("TrickCard") and card:isAvailable(source) then
						table.insert(available_tricks, card:objectName())
					end
				end
			end
			if next(available_tricks) ~= nil then
				table.insert(choices, available_tricks[math.random(1, #available_tricks)])
				source:setTag("jingong_do_not_randomize", sgs.QVariant(table.concat(choices, "+")))
			end
		end
		if not table.contains(choices, "meirenji") then
			table.insert(choices, "meirenji")
		end
		if not table.contains(choices, "xiaolicangdao") then
			table.insert(choices, "xiaolicangdao")
		end
		table.insert(choices, "cancel")
		local pattern = room:askForChoice(source, "jingong", table.concat(choices, "+"))
		if pattern and pattern ~= "cancel" then
			local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
			if poi:targetFixed() then
				poi:setSkillName("jingong")
				poi:addSubcard(self:getSubcards():first())
				room:useCard(sgs.CardUseStruct(poi, source, source),true)
			else
				pos = getPos(patterns, pattern)
				room:setPlayerMark(source, "jingongpos", pos)
				room:setPlayerProperty(source, "jingong", sgs.QVariant(self:getSubcards():first()))
				room:askForUseCard(source, "@@jingong", "@jingong:"..pattern)--%src
			end
		end
	end
}
jingongCard = sgs.CreateSkillCard{
	name = "jingong_validate",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			card:addSubcard(self:getSubcards():first())
			if card and card:targetFixed() then
				return false
			else
				return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			end
		end
		return true
	end,
	target_fixed = function(self)
		local name = ""
		local card
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		card:addSubcard(self:getSubcards():first())
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(user, "jingong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("jingong")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(card_use.from, "jingong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("jingong")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card)	then
				available = false
				break
			end
		end
		if not available then return nil end
		use_card:addSubcard(self:getSubcards():first())
		return use_card
	end
}
jingongVS = sgs.CreateViewAsSkill{
	name = "jingong",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@jingong" then
			return false
		end
		return to_select:isKindOf("Slash") or to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local skillcard = jingong_select:clone()
				skillcard:addSubcard(cards[1]:getId())
				return skillcard
			end
		else
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@@jingong" then
				local need_target_skillcard = jingongCard:clone()
				pattern = patterns[sgs.Self:getMark("jingongpos")]
				need_target_skillcard:addSubcard(sgs.Self:property("jingong"):toInt())
				if #cards ~= 0 then return end
				need_target_skillcard:setUserString(pattern)
				return need_target_skillcard
			end
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("jingong-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jingong"
	end
}

jingong = sgs.CreateTriggerSkill{
	name = "jingong",
	view_as_skill = jingongVS,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == self:objectName() and use.card:getTypeId() ~= 0 then
				room:addPlayerMark(player, "nos_jingong-Clear")
			end
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("jingong") then skills:append(jingong) end

wangyun:addRelateSkill("jingong")

sgs.LoadTranslationTable{
	["wangyun"] = "王允",
	["#wangyun"] = "忠魂不泯",
	["illustrator:wangyun"] = "Thinking",
	["lianji"] = "連計",
	["moblile_lianji"] = "連計",
	[":lianji"] = "出牌階段限一次，你可以棄置一張手牌，令一名角色使用牌堆中的一張隨機武器牌。然後其選擇一項：對你指定的一名角色使用一張【殺】，或令你將其裝備區里的武器牌交給任意角色。",
	["@lianji_use"] = "你可以使用“連計”的牌，點取消視為其對你使用此牌",
	["~lianji_use"] = "選擇“連計”牌→若有目標選擇目標→點擊確定",
	["lianji-invoke"] = "請選擇你目前武器要給的目標",
	["$lianji1"] = "兩計扣用，以摧強勢。",
	["$lianji2"] = "容老夫細細思量。",
	["moucheng"] = "謀逞",
	[":moucheng"] = "覺醒技，準備階段，若有角色因你發動〖連計〗使用【殺】而造成過傷害，則你失去〖連計〗並獲得〖矜功〗。" ,
	["$moucheng1"] = "董賊伏誅，天下太平！",
	["$moucheng2"] = "叫天不應，叫地不靈，今天就是你的死期。",
	["jingong"] = "矜功",
	[":jingong"] = "出牌階段限一次，你可以將一張【殺】或裝備牌當做三張隨機錦囊牌中的一張使用。",
	["@jingong"] = "請選擇目標",
	["~jingong"] = "選擇若干名角色→點擊確定",
	["$jingong1"] = "董賊舊部，可盡誅之。",
	["$jingong2"] = "若無老夫之謀，爾等皆化為腐土也。",
	["~wangyun"] = "努力謝關東諸公，勤以國家為念。",
}

--SP劉琦 男, 蜀, 3 體力
liuqi = sgs.General(extension,"liuqi","qun2",3, true)
--〖問計〗 出牌階段開始時，你可以令一名其他角色交給你一張牌。你於本回合內使用與該牌同名的牌不能被其他角色響應。
wenji = sgs.CreatePhaseChangeSkill{
	name = "wenji",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			--if not p:isKongcheng() then
			if not p:isNude() then
				players:append(p)
			end
		end
		if player:getPhase() == sgs.Player_Play and not players:isEmpty() then
			local to = room:askForPlayerChosen(player, players, self:objectName(), "wenji-invoke", true, true)
			if to then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local card = room:askForCard(to, "..!", "@wenji", sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, to:objectName(), player:objectName(), self:objectName(), ""))
						room:addPlayerMark(player, "wenji"..card:getClassName().."-Clear")
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}

wenji_buff = sgs.CreateTriggerSkill{
	name = "wenji_buff",
	global = true,
	events = {sgs.TargetSpecified, sgs.TrickCardCanceling},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:getMark("wenji"..use.card:getClassName().."-Clear") > 0 and use.card and not use.card:isKindOf("SkillCard") then
				if string.find(use.card:getClassName(), "Slash") then
					local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
					local index = 1
					for _, p in sgs.qlist(use.to) do
						local _data = sgs.QVariant()
						_data:setValue(p)
						jink_table[index] = 0
						index = index + 1
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					player:setTag("Jink_"..use.card:toString(), jink_data)
				--else
				--	room:setCardFlag(use.card, "wenji")
				end
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and effect.from:hasSkill("wenji") and effect.from:getMark("wenji"..effect.card:getClassName().."-Clear") > 0 then return true end
		end
	end
}

if not sgs.Sanguosha:getSkill("wenji_buff") then skills:append(wenji_buff) end

getKingdoms = function(player)
	local kingdoms = {}
	for _, p in sgs.qlist(player:getRoom():getAlivePlayers()) do
		local flag = true
		for _, k in ipairs(kingdoms) do
			if p:getKingdom() == k then
				flag = false
				break
			end
		end
		if flag then table.insert(kingdoms, p:getKingdom()) end
	end
	return #kingdoms
end

--〖屯江〗 結束階段，若你未跳過本回合的出牌階段，且你於本回合出牌階段內未使用牌指定過其他角色為目標，則你可以摸 X 張牌 (X 為全場勢力數)。
tunjiang = sgs.CreateTriggerSkill{		--yun
	name = "tunjiang",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Frequent,
	--on_phasechange = function(self, player)
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if not player:isSkipped(change.to) and change.to == sgs.Player_Play then
			room:setPlayerMark(player, "tunjiang-Clear", 1)
			return false
		end
		--local room = player:getRoom()
		--if player:getPhase() == sgs.Player_Finish and player:getMark("qieting") == 0 and room:askForSkillInvoke(player, self:objectName()) then
		if not player:isSkipped(change.to) and player:getMark("tunjiang-Clear") > 0 and change.to == sgs.Player_Finish and player:getMark("qieting") == 0 and room:askForSkillInvoke(player, self:objectName()) then
			room:setPlayerMark(player, "tunjiang-Clear", 0)
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				player:drawCards(getKingdoms(player), self:objectName())
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
liuqi:addSkill(wenji)
liuqi:addSkill(tunjiang)

sgs.LoadTranslationTable{
	["#liuqi"] = "",
	["liuqi"] = "劉琦",
	["wenji"] = "問計",
	[":wenji"] = "出牌階段開始時，你可以令一名其他角色交給你一張牌。你於本回合內使用與該牌同名的牌不能被其他角色響應。",
	["wenji-invoke"] = "令一名其他角色交給你一張牌。你於本回合內使用與該牌同名的牌不能被其他角色響應。",
	["@wenji"] = "請交給其一張牌",
	["tunjiang"] = "屯江",
	[":tunjiang"] = "結束階段，若你未跳過本回合的出牌階段，且你於本回合出牌階段內未使用牌指定過其他角色為目標，則你可以摸 X 張牌 (X 為全場勢力數)。",
	["#wenji"] = "%from 的技能 “<font color=\"yellow\"><b>問計</b></font>”被觸發，其他角色 %to 無法響應此 %arg ",
}

--魯芝	男, 魏,  3  體力
luzhi = sgs.General(extension,"luzhi","wei",3, true)
--〖清忠〗 出牌階段開始時，你可以摸兩張牌，若如此做，本階段結束時，你與手牌數最少的角色交換手牌。			  　
qingzhong = sgs.CreateTriggerSkill{
	name = "qingzhong",
	global = true,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				player:drawCards(2, self:objectName())
				room:addPlayerMark(player, self:objectName().."_replay")
				room:removePlayerMark(player, self:objectName().."engine")
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:getMark(self:objectName().."_replay") > 0 then
			local players = sgs.SPlayerList()
			local n = player:getHandcardNum()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				n = math.min(p:getHandcardNum(), n)
			end
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() == n then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "qingzhong-invoke", player:getHandcardNum() == n, true)
				if target then
					room:broadcastSkillInvoke(self:objectName(), 2)
					local exchangeMove = sgs.CardsMoveList()
					exchangeMove:append(sgs.CardsMoveStruct(player:handCards(), target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), target:objectName(), self:objectName(), "")))
					exchangeMove:append(sgs.CardsMoveStruct(target:handCards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), player:objectName(), self:objectName(), "")))
					room:moveCardsAtomic(exchangeMove, false)
				end
			end
		end
	end
}
--〖衛境〗 每輪限一次，你可以視為使用一張【殺】或【閃】。
weijingVS = sgs.CreateZeroCardViewAsSkill{
	name = "weijing",
	view_as = function(self)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern ~= "jink" then
			pattern = "slash"
		end
		local cards = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
		cards:setSkillName(self:objectName())
		return cards
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getMark("@weijing_lun") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink") and player:getMark("@weijing_lun") == 0 and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	end
}
weijing = sgs.CreateTriggerSkill{
	name = "weijing",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = weijingVS, 
	events = {sgs.PreCardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:getSkillName() == self:objectName() then
			player:addMark("@weijing_lun")
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) 
	end
}
luzhi:addSkill(qingzhong)
luzhi:addSkill(weijing)

sgs.LoadTranslationTable{
	["#luzhi"] = "",
	["luzhi"] = "魯芝",
	["qingzhong"] = "清忠",
	[":qingzhong"] = "出牌階段開始時，你可以摸兩張牌，若如此做，本階段結束時，你與手牌數最少的角色交換手牌",
	["weijing"] = "衛境",
	[":weijing"] = "每輪限一次，你可以視為使用一張【殺】或【閃】",
	["@weijing"] = "衛境",
	["qingzhong-invoke"] = "選擇一名手牌數最少的角色，你與其交換手牌",
}
--司馬徽
simahui = sgs.General(extension, "simahui", "qun2", "3", true)
--薦傑
--薦傑衍生技能
function Fire(player,target,damagePoint)
	local damage = sgs.DamageStruct()
	damage.from = player
	damage.to = target
	damage.damage = damagePoint
	damage.nature = sgs.DamageStruct_Fire
	player:getRoom():damage(damage)
end
function toSet(self)
	local set = {}
	for _,ele in pairs(self)do
		if not table.contains(set,ele) then
			table.insert(set,ele)
		end
	end
	return set
end
--[[
dajianjieCard = sgs.CreateSkillCard{
	name = "dajianjie",
	skill_name = "yeyan",
	filter = function(self, targets, to_select)
		local i = 0
		for _,p in pairs(targets)do
			if p:objectName() == to_select:objectName() then
				i = i + 1
			end
		end
		local maxVote = math.max(3-#targets,0)+i
		return maxVote
	end,
	feasible = function(self, targets)
		if self:getSubcards():length() ~= 4 then return false end
		local all_suit = {}
		for _,id in sgs.qlist(self:getSubcards())do
			local c = sgs.Sanguosha:getCard(id)
			if not table.contains(all_suit,c:getSuit()) then
				table.insert(all_suit,c:getSuit())
			else
				return false
			end
		end
		if #toSet(targets) == 1 then
			return true
		elseif #toSet(targets) == 2 then
			return #targets == 3
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@dragon")
		source:loseMark("@phoenix")
		local criticaltarget = 0
		local totalvictim = 0
		local map = {}
		for _,sp in pairs(targets)do
			if map[sp:objectName()] then
				map[sp:objectName()] = map[sp:objectName()] + 1
			else
				map[sp:objectName()] = 1
			end
		end
		if #targets == 1 then
			map[targets[1]:objectName()] = map[targets[1]:objectName()] + 2
		end
		local target_table = sgs.SPlayerList()
		for sp,va in pairs(map)do
			if va > 1 then criticaltarget = criticaltarget + 1  end
			totalvictim = totalvictim + 1
			for _,p in pairs(targets)do
				if p:objectName() == sp then
					target_table:append(p)
					break
				end
			end
		end
		if criticaltarget > 0 then
			room:removePlayerMark(source, "@flame")	
			room:loseHp(source, 3)	
			room:sortByActionOrder(target_table)
			for _,sp in sgs.qlist(target_table)do
				Fire(source, sp, map[sp:objectName()])
			end
		end
	end
}
xiaojianjieCard = sgs.CreateSkillCard{
	name = "xiaojianjie",
	skill_name = "yeyan",
	filter = function(self, targets, to_select)
		return #targets < 3
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@dragon")
		source:loseMark("@phoenix")
		for _,sp in sgs.list(targets)do
			Fire(source, sp, 1)
		end
	end
}
jianjievsCard = sgs.CreateSkillCard{
	name = "jianjievs",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local name, vs = "lianhuan", "iron_chain"
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isRed() then
			name = "huoji"
			vs = "fire_attack"
		end
		local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		card:addSubcard(self:getSubcards():first())
		card:setSkillName(name)
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local name, vs = "lianhuan", "iron_chain"
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isRed() then
			name = "huoji"
			vs = "fire_attack"
		end
		local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		card:addSubcard(self:getSubcards():first())
		card:setSkillName(name)
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, use)
		local room = use.from:getRoom()
		local name, vs = "lianhuan", "iron_chain"
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isRed() then
			name = "huoji"
			vs = "fire_attack"
		end
		local use_card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName(name)
		local available = true
		for _,p in sgs.qlist(use.to) do
			if use.from:isProhibited(p, use_card)	then
				available = false
				break
			end
		end
		room:addPlayerMark(use.from, name.."_Play")
		available = available and use_card:isAvailable(use.from)
		if not available then return nil end
		return use_card	
	end
}
jianjievs = sgs.CreateViewAsSkill{
	name = "jianjievs&",
	response_or_use = true,
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected == 0 and ((sgs.Self:getMark("@dragon") > 0 and to_select:isRed()) or (#selected == 0 and sgs.Self:getMark("@phoenix") > 0 and to_select:getSuit() == sgs.Card_Club) or (sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and sgs.Self:getHandcardNum() >= 4)) then
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		elseif sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and #selected > 0 and #selected < 4 then
			for _,ca in sgs.list(selected)do
				if ca:getSuit() == to_select:getSuit() then return false end
			end
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and #cards == 4 then
			local skillcard = dajianjieCard:clone()
			for _,card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		elseif sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and #cards == 0 then
			return xiaojianjieCard:clone()
		elseif #cards == 1 then
			if sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("huoji_Play") < 3 and cards[1]:isRed() then
				local skillcard = jianjievsCard:clone()
				skillcard:setSkillName("huoji")
				skillcard:addSubcard(cards[1])
				return skillcard
			elseif sgs.Self:getMark("@phoenix") > 0 and sgs.Self:getMark("lianhuan_Play") < 3 and cards[1]:getSuit() == sgs.Card_Club then
				local skillcard = jianjievsCard:clone()
				skillcard:setSkillName("lianhuan")
				skillcard:addSubcard(cards[1])
				return skillcard
			end
		end
		return nil
	end
}

if not sgs.Sanguosha:getSkill("jianjievs") then skills:append(jianjievs) end
]]--

jianjie_dayeyanCard = sgs.CreateSkillCard{
	name = "jianjie_dayeyan",
	skill_name = "yeyan",
	filter = function(self, targets, to_select)
		local i = 0
		for _,p in pairs(targets)do
			if p:objectName() == to_select:objectName() then
				i = i + 1
			end
		end
		local maxVote = math.max(3-#targets,0)+i
		return maxVote
	end,
	feasible = function(self, targets)
		if self:getSubcards():length() ~= 4 then return false end
		local all_suit = {}
		for _,id in sgs.qlist(self:getSubcards())do
			local c = sgs.Sanguosha:getCard(id)
			if not table.contains(all_suit,c:getSuit()) then
				table.insert(all_suit,c:getSuit())
			else
				return false
			end
		end
		if #toSet(targets) == 1 then
			return true
		elseif #toSet(targets) == 2 then
			return #targets == 3
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@dragon")
		source:loseMark("@phoenix")
		room:doSuperLightbox("shenzhouyu","yeyan")
		local criticaltarget = 0
		local totalvictim = 0
		local map = {}
		for _,sp in pairs(targets)do
			if map[sp:objectName()] then
				map[sp:objectName()] = map[sp:objectName()] + 1
			else
				map[sp:objectName()] = 1
			end
		end
		if #targets == 1 then
			map[targets[1]:objectName()] = map[targets[1]:objectName()] + 2
		end
		local target_table = sgs.SPlayerList()
		for sp,va in pairs(map)do
			if va > 1 then criticaltarget = criticaltarget + 1  end
			totalvictim = totalvictim + 1
			for _,p in pairs(targets)do
				if p:objectName() == sp then
					target_table:append(p)
					break
				end
			end
		end
		if criticaltarget > 0 then
			room:removePlayerMark(source, "@flame")	
			room:loseHp(source, 3)	
			room:sortByActionOrder(target_table)
			for _,sp in sgs.qlist(target_table)do
				Fire(source, sp, map[sp:objectName()])
			end
		end
	end
}
jianjie_xiaoyeyanCard = sgs.CreateSkillCard{
	name = "jianjie_xiaoyeyan",
	skill_name = "yeyan",
	filter = function(self, targets, to_select)
		return #targets < 3
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@dragon")
		source:loseMark("@phoenix")
		room:doSuperLightbox("shenzhouyu","yeyan")
		for _,sp in sgs.list(targets)do
			Fire(source, sp, 1)
		end
	end
}

jianjie_yeyan = sgs.CreateViewAsSkill{
	name = "jianjie_yeyan",
	response_or_use = true,
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected == 0 and (sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and sgs.Self:getHandcardNum() >= 4) then
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		elseif sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and #selected > 0 and #selected < 4 then
			for _,ca in sgs.list(selected)do
				if ca:getSuit() == to_select:getSuit() then return false end
			end
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and #cards == 4 then
			local skillcard = jianjie_dayeyanCard:clone()
			for _,card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		elseif sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("@phoenix") > 0 and #cards == 0 then
			return jianjie_xiaoyeyanCard:clone()
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@dragon") > 0 and player:getMark("@phoenix") > 0
	end
}


jianjie_huojiCard = sgs.CreateSkillCard{
	name = "jianjie_huoji",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local name, vs = "huoji", "fire_attack"
		local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		card:addSubcard(self:getSubcards():first())
		card:setSkillName(name)
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local name, vs = "huoji", "fire_attack"
		local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		card:addSubcard(self:getSubcards():first())
		card:setSkillName(name)
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, use)
		local room = use.from:getRoom()
		local name, vs = "huoji", "fire_attack"
		local use_card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName(name)
		local available = true
		for _,p in sgs.qlist(use.to) do
			if use.from:isProhibited(p, use_card) then
				available = false
				break
			end
		end
		room:addPlayerMark(use.from, name.."_Play")
		available = available and use_card:isAvailable(use.from)
		if not available then return nil end
		return use_card
	end
}
jianjie_huoji = sgs.CreateViewAsSkill{
	name = "jianjie_huoji",
	response_or_use = true,
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected == 0 and to_select:isRed() then
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			if sgs.Self:getMark("@dragon") > 0 and sgs.Self:getMark("huoji_Play") < 3 and cards[1]:isRed() then
				local skillcard = jianjie_huojiCard:clone()
				skillcard:setSkillName("huoji")
				skillcard:addSubcard(cards[1])
				return skillcard
			end
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		if player:hasSkill("jianjie") then
			return player:getMark("@dragon") > 0 and player:getMark("huoji_Play") < 3
		end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("jianjie") then
				return player:getMark("@dragon") > 0 and player:getMark("huoji_Play") < 3
			end
		end
		return false
	end
}

jianjie_lianhuanCard = sgs.CreateSkillCard{
	name = "jianjie_lianhuan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local name, vs = "lianhuan", "iron_chain"
		local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		card:addSubcard(self:getSubcards():first())
		card:setSkillName(name)
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local name, vs = "lianhuan", "iron_chain"
		local card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		card:addSubcard(self:getSubcards():first())
		card:setSkillName(name)
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, use)
		local room = use.from:getRoom()
		local name, vs = "lianhuan", "iron_chain"
		local use_card = sgs.Sanguosha:cloneCard(vs, sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit(), sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber())
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName(name)
		local available = true
		for _,p in sgs.qlist(use.to) do
			if use.from:isProhibited(p, use_card) then
				available = false
				break
			end
		end
		room:addPlayerMark(use.from, name.."_Play")
		available = available and use_card:isAvailable(use.from)
		if not available then return nil end
		return use_card
	end
}
jianjie_lianhuan = sgs.CreateViewAsSkill{
	name = "jianjie_lianhuan",
	response_or_use = true,
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected == 0 and to_select:getSuit() == sgs.Card_Club then
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			if sgs.Self:getMark("@phoenix") > 0 and sgs.Self:getMark("lianhuan_Play") < 3 and cards[1]:getSuit() == sgs.Card_Club then
				local skillcard = jianjie_lianhuanCard:clone()
				skillcard:setSkillName("lianhuan")
				skillcard:addSubcard(cards[1])
				return skillcard
			end
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		if player:hasSkill("jianjie") then
			return player:getMark("@phoenix") > 0 and player:getMark("lianhuan_Play") < 3
		end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("jianjie") then
				return player:getMark("@phoenix") > 0 and player:getMark("lianhuan_Play") < 3
			end
		end
		return false
	end
}

jianjieUsedTimes = sgs.CreateTriggerSkill{
	name = "jianjieUsedTimes",
	global = true,
	priority = 10,
	events = {sgs.PreCardUsed,sgs.CardFinished},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "jianjie_huoji" then
				room:addPlayerMark(splayer, "huoji_Play")
			end
			if use.card and use.card:getSkillName() == "jianjie_lianhuan" then
				room:addPlayerMark(splayer, "lianhuan_Play")
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("jianjie_yeyan") then skills:append(jianjie_yeyan) end
if not sgs.Sanguosha:getSkill("jianjie_huoji") then skills:append(jianjie_huoji) end
if not sgs.Sanguosha:getSkill("jianjie_lianhuan") then skills:append(jianjie_lianhuan) end
if not sgs.Sanguosha:getSkill("jianjieUsedTimes") then skills:append(jianjieUsedTimes) end

--主技能
jianjieCard = sgs.CreateSkillCard{
	name = "jianjie",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark(self:objectName()) > 0 then
			if sgs.Self:getMark(self:objectName()) == 3 then
				return #targets < 2
			else
				return #targets == 0
			end
		elseif sgs.Self:getMark("turn") == 1 then
			return #targets < 2
		else
			if (#targets == 0 and to_select:getMark("@dragon") > 0) or (#targets == 1 and to_select:getMark("@dragon") == 0) then
				return true
			elseif (#targets == 0 and to_select:getMark("@phoenix") > 0) or (#targets == 1 and to_select:getMark("@phoenix") == 0) then
				return true
			end
		end
		return false
	end,
	feasible = function(self, targets)
		if sgs.Self:getMark(self:objectName()) == 0 then
			return #targets == 2
		end
		if sgs.Self:getMark(self:objectName()) == 3 then
			return #targets == 2
		else
			return #targets == 1
		end
		return #targets < 3
	end,
	about_to_use = function(self, room, use)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			if use.from:getMark(self:objectName()) > 0 then
				if use.from:getMark(self:objectName()) == 3 then
					if use.to:last() then
					use.to:first():gainMark("@dragon")
					use.to:last():gainMark("@phoenix")
					else
					use.to:first():gainMark("@dragon")
					use.to:first():gainMark("@phoenix")
					end
				else
					if use.from:getMark(self:objectName()) == 1 then
					use.to:first():gainMark("@dragon")
					else
					use.to:first():gainMark("@phoenix")
					end
				end
			elseif use.from:getMark("turn") == 1 then
				use.to:first():gainMark("@dragon")
				use.to:last():gainMark("@phoenix")
			else
				local choices = {}
				if use.to:first():getMark("@dragon") > 0 then
					table.insert(choices, "dragon_move")
				end
				if use.to:first():getMark("@phoenix") > 0 then
					table.insert(choices, "phoenix_move")
				end
				local choice = room:askForChoice(use.from, self:objectName(), table.concat(choices, "+"))
				if choice == "dragon_move" then
					use.to:first():loseMark("@dragon")
					use.to:last():gainMark("@dragon")
				else
					use.to:first():loseMark("@phoenix")
					use.to:last():gainMark("@phoenix")
				end
			end

			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@dragon") > 0 and not p:hasSkill("huoji") and not p:hasSkill("huoji_po") and not p:hasSkill("jianjie_huoji") then
					room:acquireSkill(p, "jianjie_huoji")
				end

				if p:getMark("@phoenix") > 0 and not p:hasSkill("lianhuan") and not p:hasSkill("lianhuan_po") and not p:hasSkill("jianjie_lianhuan") then
					room:acquireSkill(p, "jianjie_lianhuan")
				end

				if p:getMark("@dragon") > 0 and p:getMark("@phoenix") > 0 and not p:hasSkill("yeyan") and not p:hasSkill("jianjie_yeyan") then
					room:acquireSkill(p, "jianjie_yeyan")
				end

				if p:getMark("@dragon") == 0 and p:hasSkill("jianjie_huoji") then
					room:handleAcquireDetachSkills(p,"-jianjie_huoji")
				end
				if p:getMark("@phoenix") == 0 and p:hasSkill("jianjie_lianhuan") then
					room:handleAcquireDetachSkills(p,"-jianjie_lianhuan")
				end
				if (p:getMark("@dragon") == 0 or p:getMark("@phoenix") == 0) and p:hasSkill("jianjie_yeyan") then
					room:handleAcquireDetachSkills(p,"-jianjie_yeyan")
				end

			end

			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
jianjieVS = sgs.CreateZeroCardViewAsSkill{
	name = "jianjie",
	--response_pattern = "@@jianjie",
	view_as = function(self)
		return jianjieCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("turn") > 1 and not player:hasUsed("#jianjie")
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@jianjie")
	end
}
jianjie = sgs.CreateTriggerSkill{
	name = "jianjie",
	events = {sgs.EventPhaseStart, sgs.Death},
	view_as_skill = jianjieVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and RIGHT(self, player) and player:getMark("first_"..self:objectName()) == 0 then
				if room:askForUseCard(player, "@@jianjie!", "@jianjie") then
					room:broadcastSkillInvoke(self:objectName())
				end
				room:addPlayerMark(player, "first_"..self:objectName())
			end
		else
			local death = data:toDeath()
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if (death.who:getMark("@dragon") > 0 and p:getMark("@dragon") == 0) or (death.who:getMark("@phoenix") > 0 and p:getMark("@phoenix") == 0) then
					players:append(p)
				end
			end
			if death.who:objectName() == player:objectName() and not players:isEmpty() then
--				if death.who:getMark("@dragon") > 0 then
--					room:addPlayerMark(player, self:objectName())
--				end
--				if death.who:getMark("@phoenix") > 0 then
--					room:addPlayerMark(player, self:objectName(), 2)
--				end
--				local simahui = room:findPlayerBySkillName("jianjie")
--				if simahui and (simahui:getGeneralName() == "simahui" or simahui:getGeneral2Name() == "simahui") and room:askForSkillInvoke(simahui, "jianjie_death_move", data) then
--					room:askForUseCard(player, "@@jianjie", "@jianjie")
--					room:setPlayerMark(player, self:objectName(), 0)
--				end
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if death.who:getMark("@dragon") > 0 then
						room:addPlayerMark(p, self:objectName())
					end
					if death.who:getMark("@phoenix") > 0 then
						room:addPlayerMark(p, self:objectName(), 2)
					end
					room:askForUseCard(p, "@@jianjie", "@jianjie_move")
					room:setPlayerMark(p, self:objectName(), 0)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}
--稱好
chenghao = sgs.CreateTriggerSkill{
	name = "chenghao",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal and not damage.chain and player:isChained() and player:objectName() == damage.to:objectName() then
				local n = 0
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isChained() then
						n = n + 1
					end
				end
				if n > 0 and room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						local _guojia = sgs.SPlayerList()
						_guojia:append(p)
						local yiji_cards = room:getNCards(n, false)
						local move = sgs.CardsMoveStruct(yiji_cards, nil, p, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
										sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, p:objectName(), self:objectName(), nil))
						local moves = sgs.CardsMoveList()
						moves:append(move)
						room:notifyMoveCards(true, moves, false, _guojia)
						room:notifyMoveCards(false, moves, false, _guojia)
						local origin_yiji = sgs.IntList()
						for _, id in sgs.qlist(yiji_cards) do
							origin_yiji:append(id)
						end
						while room:askForYiji(p, yiji_cards, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
							local move = sgs.CardsMoveStruct(sgs.IntList(), p, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
										sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, p:objectName(), self:objectName(), nil))
							for _, id in sgs.qlist(origin_yiji) do
								if room:getCardPlace(id) ~= sgs.Player_DrawPile then
									move.card_ids:append(id)
									yiji_cards:removeOne(id)
								end
							end
							origin_yiji = sgs.IntList()
							for _, id in sgs.qlist(yiji_cards) do
								origin_yiji:append(id)
							end
							local moves = sgs.CardsMoveList()
							moves:append(move)
							room:notifyMoveCards(true, moves, false, _guojia)
							room:notifyMoveCards(false, moves, false, _guojia)
							if not p:isAlive() then return end
						end
						if not yiji_cards:isEmpty() then
							local move = sgs.CardsMoveStruct(yiji_cards, p, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
										sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, p:objectName(), self:objectName(), nil))
							local moves = sgs.CardsMoveList()
							moves:append(move)
							room:notifyMoveCards(true, moves, false, _guojia)
							room:notifyMoveCards(false, moves, false, _guojia)
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							for _, id in sgs.qlist(yiji_cards) do
								dummy:addSubcard(id)
							end
							p:obtainCard(dummy, false)
						end
						room:removePlayerMark(p, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
yinshi = sgs.CreateTriggerSkill{
	name = "yinshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if player:getMark("@dragon") + player:getMark("@phoenix") == 0 and not player:getArmor() then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal or (damage.card and damage.card:isKindOf("TrickCard"))) and damage.to and damage.to:objectName() == player:objectName() then
				local msg = sgs.LogMessage()
				msg.type = "#YinshiProtect"
				msg.from = player
				msg.arg = damage.damage
				if damage.nature == sgs.DamageStruct_Fire then
					msg.arg2 = "fire_nature"
				elseif damage.nature == sgs.DamageStruct_Thunder then
					msg.arg2 = "thunder_nature"
				elseif damage.nature == sgs.DamageStruct_Normal then
					msg.arg2 = "normal_nature"
				end
				room:sendLog(msg)
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(player, self:objectName().."engine")
					return true
				end
			end
		end
	end
}

simahui:addSkill(jianjie)
simahui:addSkill(chenghao)
simahui:addSkill(yinshi)

sgs.LoadTranslationTable{
	["simahui"] = "司馬徽",
	["jianjie"] = "薦傑",
	["@dragon"] = "龍印",
	["@phoenix"] = "鳳印",
	["jianjievs"] = "薦傑",
	["$jianjie1"] = "",
	["$jianjie2"] = "",
	["$chenghao1"] = "",
	["$chenghao2"] = "",
	["$yinshi1"] = "",
	["$yinshi2"] = "",
	["@jianjie"] = "你可以發動“薦傑” <br/> <b>操作提示</b>:第一個角色獲得龍印，第二個角色獲得鳳印<br/>",
	["@jianjie_move"] = "你可以發動“薦傑”",
	["~jianjie"] = "選擇角色→點擊確定",
	["chenghao"] = "稱好",
	["yinshi"] = "隱士",
	["jianjieCard"] = "薦傑",
	[":jianjie"] = "你的第一個準備階段，你令兩名不同的角色分別獲得龍印與鳳印；出牌階段限一次（你的第一個回合除外），或當擁有龍印、鳳印的角色死亡時，你可以轉移龍印、鳳印。\
	\
	<font color='grey'>龍印：獲得火計（一回合限使用三次）。</font>\
	<font color='grey'>鳳印：獲得連環（一回合限使用三次）。</font>\
	<font color='grey'>龍印和鳳印集全獲得業炎，業炎發動後移除龍鳳印。</font>",

	["dragon_move"] = "轉移龍印",
	["phoenix_move"] = "轉移鳳印",

	[":chenghao"] = "當一名角色受到屬性傷害時，若其處於連環狀態且是傷害傳導的起點，你可以觀看牌堆頂的 X 張牌並分配給任意角色(X 為橫置的角色數量)。",
	[":yinshi"] = "鎖定技，若你沒有龍印、鳳印且沒裝備防具，防止你受到的屬性傷害和錦囊牌造成的傷害。",
	["#YinshiProtect"] = "%from 的「<font color=\"yellow\"><b>隱士</b></font>」效果被觸發，防止了 %arg 點傷害[%arg2]",
["jianjie_huoji"] = "火計",
[":jianjie_huoji"] = "出牌階段限三次，你可以將一張紅色手牌當【火攻】使用。",
["jianjie_lianhuan"] = "連環",
[":jianjie_lianhuan"] = "出牌階段限三次，你可以將一張梅花手牌當【鐵索連環】使用或重鑄。",
["jianjie_yeyan"] = "業炎",
[":jianjie_yeyan"] = "限定技。出牌階段，你可以移除龍印與鳳印，然後選擇一項對一至三名角色各造成1點火焰傷害；或你可以棄置四種花色的手牌各一張，失去3點體力並選擇一至兩名角色：若如此做，你對這些角色造成共計至多3點火焰傷害且對其中一名角色造成至少2點火焰傷害。",

}

--SP賈詡
ol_jiaxu = sgs.General(extension,"ol_jiaxu","wei2","3",true)
--縝略——鎖定技，你使用的非延時類錦囊牌不能被【無懈可擊】響應；你不能被選擇為延時類錦囊的目標。
--[[
zhenlve = sgs.CreateTriggerSkill{
	name = "zhenlve",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isNDTrick() then
				use.card:toTrick():setCancelable(true)
			end
			return false
		end		
	end
}
]]--

zhenlve = sgs.CreateTriggerSkill{
	name = "zhenlve",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TrickCardCanceling},
	on_trigger = function(self, event, player, data, room)
		local effect = data:toCardEffect()
		if RIGHT(self, effect.from) then
			SendComLog(self, effect.from)
			room:addPlayerMark(effect.from, self:objectName().."engine")
			if effect.from:getMark(self:objectName().."engine") > 0 then
				room:removePlayerMark(effect.from, self:objectName().."engine")
				return true
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

zhenlvePs = sgs.CreateProhibitSkill{
	name = "#zhenlvePs",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("zhenlve") and (card:isKindOf("DelayedTrick"))
	end
}

--間書
--[[
jianshuCard = sgs.CreateSkillCard{
	name = "jianshu", 
	will_throw = false, 
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:removePlayerMark(source, "@book")
			room:doSuperLightbox("ol_jiaxu","jianshu")
			room:obtainCard(targets[1], sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""))
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(targets[1])) do
				if p:inMyAttackRange(targets[1]) and p:objectName() ~= source:objectName() and not p:isKongcheng() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local player = room:askForPlayerChosen(source, players, self:objectName(), "@book")
				targets[1]:pindian(player, self:objectName(),nil)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jianshuVS = sgs.CreateOneCardViewAsSkill{
	name = "jianshu", 
	filter_pattern = ".|black", 
	view_as = function(self, card) 
		local cards = jianshuCard:clone()
		cards:addSubcard(card)
		return cards
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@book") > 0
	end
}
jianshu = sgs.CreateTriggerSkill{
	name = "jianshu", 
	view_as_skill = jianshuVS, 
	frequency = sgs.Skill_Limited, 
	limit_mark = "@book", 
	events = {sgs.Pindian}, 
	on_trigger = function(self, event, player, data, room)
		local pindian = data:toPindian()
		if pindian.reason == self:objectName() then
			local winner = pindian.from
			local loser = pindian.to
			local players = sgs.SPlayerList()
			if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
				winner = pindian.to
				loser = pindian.from
			elseif pindian.from_card:getNumber() == pindian.to_card:getNumber() then
				players:append(winner)
				winner = nil
			end
			players:append(loser)
			if winner then
				room:askForDiscard(winner, self:objectName(), 2, 2, false, true)
			end
			room:sortByActionOrder(players)
			for _, p in sgs.qlist(players) do
				if p:isAlive() then
					room:loseHp(p)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
]]--
jianshuCard = sgs.CreateSkillCard{
	name = "jianshu", 
	will_throw = false, 
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:removePlayerMark(source, "@book")
			room:doSuperLightbox("ol_jiaxu","jianshu")
			room:obtainCard(targets[1], sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""))
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(targets[1])) do
				if p:objectName() ~= source:objectName() and not p:isKongcheng() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local player = room:askForPlayerChosen(source, players, self:objectName(), "@book")
				targets[1]:pindian(player, self:objectName(),nil)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jianshuVS = sgs.CreateOneCardViewAsSkill{
	name = "jianshu", 
	filter_pattern = ".|black", 
	view_as = function(self, card) 
		local cards = jianshuCard:clone()
		cards:addSubcard(card)
		return cards
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@book") > 0
	end
}
jianshu = sgs.CreateTriggerSkill{
	name = "jianshu", 
	view_as_skill = jianshuVS, 
	frequency = sgs.Skill_Limited, 
	limit_mark = "@book", 
	events = {sgs.Pindian}, 
	on_trigger = function(self, event, player, data, room)
		local pindian = data:toPindian()
		if pindian.reason == self:objectName() then
			local winner = pindian.from
			local loser = pindian.to
			local players = sgs.SPlayerList()
			if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
				winner = pindian.to
				loser = pindian.from
			elseif pindian.from_card:getNumber() == pindian.to_card:getNumber() then
				players:append(winner)
				winner = nil
			end
			players:append(loser)
			if winner then
				room:askForDiscard(winner, self:objectName(), 2, 2, false, true)
			end
			room:sortByActionOrder(players)
			for _, p in sgs.qlist(players) do
				if p:isAlive() then
					room:loseHp(p)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
--擁嫡——限定技，當你受到傷害後，你可令一名其他男性角色加1點體力上限，然後其摸三張牌。
yongdi = sgs.CreateTriggerSkill{
	name = "yongdi", 
	limit_mark = "@yong", 
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart,sgs.Damaged},	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) or event == sgs.Damaged then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isMale() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() and player:getMark("@yong") > 0 then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@yongdi-invoke", true, true)
				if target then
					room:doAnimate(1, player:objectName(), target:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("ol_jiaxu","yongdi")
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:removePlayerMark(player, "@yong")
						room:setPlayerProperty(target,"maxhp",sgs.QVariant(target:getMaxHp()+1))

						local msg = sgs.LogMessage()
						msg.type = "#GainMaxHp"
						msg.from = target
						msg.arg = 1
						room:sendLog(msg)

						local lord = {}
						for _, skill in sgs.qlist(target:getGeneral():getVisibleSkillList()) do
							if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) and not target:isLord() then
								table.insert(lord, skill:objectName())
							end
						end
						if target:getGeneral2() then
							for _, skill in sgs.qlist(target:getGeneral2():getVisibleSkillList()) do
								if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) and not target:isLord() then
									table.insert(lord, skill:objectName())
								end
							end
						end
						room:handleAcquireDetachSkills(target, table.concat(lord, "|"))
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}

ol_jiaxu:addSkill(zhenlve)
ol_jiaxu:addSkill(zhenlvePs)
ol_jiaxu:addSkill(jianshu)
ol_jiaxu:addSkill(yongdi)
extension:insertRelatedSkills("zhenlve","#zhenlvePs")

sgs.LoadTranslationTable{
	["ol_jiaxu"] = "SP賈詡",
	["&ol_jiaxu"] = "賈詡",
	["zhenlve"] = "縝略",
	[":zhenlve"] = "鎖定技，你使用的非延時類錦囊牌不能被【無懈可擊】響應；你不能被選擇為延時類錦囊的目標。",
	["jianshu"] = "間書",
	[":jianshu"] = "限定技，出牌階段，你可以將一張黑色手牌交給一名角色並令其與由你選擇的另一名其他角色拼點：贏的角色棄置兩張牌，沒贏的角色失去1點體力。 ",
	["yongdi"] = "擁嫡",
	[":yongdi"] = "限定技，當你受到傷害後，或你的回合開始時，你可以選擇一名其他男性角色，令其加1點體力上限，然後若其不為主公且其武將牌上有主公技，其獲得此主公技。",
	["@yongdi-invoke"] = "你可以選擇一名其他男性角色，令其加1點體力上限",
	["$jianshu1"] = "縱有千軍萬馬，離心，則難成大事~",
	["$jianshu2"] = "來~讓我看一出好戲吧~",
	["$yongdi1"] = "臣，願為世子，肝腦塗地~",
	["$yongdi2"] = "嫡庶有別~尊卑有序~",
	["@jianshu"] = "你發動“間書”選擇一名角色<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
}

--懷舊鮑三娘
nos_baosanniang = sgs.General(extension,"nos_baosanniang","shu","3",false, true, true)
--武娘：當你使用或打出【殺】時，你可以獲得一名其他角色的一張牌，然後其摸一張牌，如果武將“關索”在場，你可以令“關索”也摸一張牌。
nos_wuniang = sgs.CreateTriggerSkill{
	name = "nos_wuniang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("Slash") and player:hasSkill(self:objectName()) then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isNude() and p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "nos_wuniang-invoke", true, true)
				if target then
					local id = room:askForCardChosen(player, target, "he", self:objectName())
					room:obtainCard(player, id, false)
					target:drawCards(1)
					room:broadcastSkillInvoke(self:objectName())
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo" or p:getGeneralName() == "ty_guansuo" or p:getGeneral2Name() == "ty_guansuo" then
							if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..p:getSeat())) then
								p:drawCards(1)
							end
						end
					end
				end
			end
		end
		return false
	end
}
--鎮南：當你成為【南蠻入侵】的目標時，你可以對一名其他角色造成1~3點隨機傷害。
nos_zhennan = sgs.CreateTriggerSkill{
	name = "nos_zhennan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("SavageAssault") and use.to and use.to:contains(player) and player:hasSkill(self:objectName()) then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "nos_zhennan-invoke", true, true)
			if target then
				room:damage(sgs.DamageStruct(self:objectName(), player, target, math.random(1,3)))
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
--許身：限定技，當其他男性角色令你離開瀕死狀態後，如果“關索”不在場，其可以選擇是否用“關索”代替其武將，然後你回復1點體力並獲得技能“鎮南”。
nos_xushen = sgs.CreateTriggerSkill{
	name = "nos_xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@nos_xushen",
	events = {sgs.TargetConfirmed, sgs.HpChanged, sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local source = data:toCardUse().from
			if source and source:isMale() and source:objectName() ~= player:objectName() and player:getHp() <= 0 and player:hasSkill(self:objectName()) then
				room:addPlayerMark(source, "nos_xushen_healer")
			end
		elseif event == sgs.HpChanged then
			if player:getHp() < 1 and player:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("nos_xushen_healer") > 0 then
						room:setPlayerMark(p, "nos_xushen_healer", 0)
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local healer
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("nos_xushen_healer") > 0 then
					healer = p
					room:removePlayerMark(p, "nos_xushen_healer")
				end
			end
			local has_guansuo = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo" or p:getGeneralName() == "ty_guansuo" or p:getGeneral2Name() == "ty_guansuo" then
					has_guansuo = true
				end
			end
			if not has_guansuo and healer and player:getMark("@nos_xushen") > 0 and player:hasSkill(self:objectName()) then
				if room:askForSkillInvoke(healer, self:objectName(), data) then
					room:changeHero(healer, "guansuo", false, false)
					room:recover(player, sgs.RecoverStruct(player))
					room:acquireSkill(player, "zhennan")
					room:broadcastSkillInvoke(self:objectName())
					room:removePlayerMark(player, "@nos_xushen")
				end
			end
		end
		return false
	end
}

nos_baosanniang:addSkill(nos_wuniang)
nos_baosanniang:addSkill(nos_xushen)
if not sgs.Sanguosha:getSkill("nos_zhennan") then skills:append(nos_zhennan) end
nos_baosanniang:addRelateSkill("nos_zhennan")

sgs.LoadTranslationTable{
	["nos_baosanniang"] = "懷舊鮑三娘",
	["&nos_baosanniang"] = "鮑三娘",
	["nos_wuniang"] = "武娘",
	[":nos_wuniang"] = "當你使用或打出【殺】時，你可以獲得一名其他角色的一張牌，然後其摸一張牌，如果武將“關索”在場，你可以令“關索”也摸一張牌。",
	["$nos_wuniang1"] = "虽为女子身，不输男儿郎",
	["$nos_wuniang2"] = "剑舞轻盈，沙场克敌",
	["nos_wuniang-invoke"] = "你可以獲得一名其他角色的一張牌，然後其摸一張牌<br/> <b>操作提示</b>: 選擇一名與你不同且有手牌的角色→點擊確定<br/>",
	["nos_wuniang:draw"] = "你想發動“武娘”令座位 %src 號關索玩家摸一張牌嗎?",
	["nos_zhennan"] = "鎮南",
	[":nos_zhennan"] = "當你成為【南蠻入侵】的目標時，你可以對一名其他角色造成1~3點隨機傷害。",
	["nos_zhennan-invoke"] = "你可以對一名其他角色造成1~3點隨機傷害<br/> <b>操作提示</b>: 選擇一名與你不同的角色→點擊確定<br />",
	["$nos_zhennan1"] = "镇守南中，夫君无忧",
	["$nos_zhennan2"] = "与君携手，定平蛮夷",
	["nos_xushen"] = "許身",
	[":nos_xushen"] = "限定技，當其他男性角色令你離開瀕死狀態後，如果“關索”不在場，其可以選擇是否用“關索”代替其武將，然後你回復1點體力並獲得技能“鎮南”。",
	["$nos_xushen1"] = "救命之恩，涌泉相报",
	["$nos_xushen2"] = "解我危难，报君华彩",
	["wuniang_kuansho_draw"] = "你可以令“關索”也摸一張牌。",
	["@str_zangnan-damage"] = "你可以對一名角色造成1~3點隨機傷害",
	["nos_xushen_changehero"] = "變身為「關索」",
}

--鮑三娘
baosanniang = sgs.General(extension,"baosanniang","shu2","3",false)

wuniang = sgs.CreateTriggerSkill{
	name = "wuniang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("Slash") and player:hasSkill(self:objectName()) then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isNude() and p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "wuniang-invoke", true, true)
				if target then
					local id = room:askForCardChosen(player, target, "he", self:objectName())
					room:obtainCard(player, id, false)
					target:drawCards(1)
					room:broadcastSkillInvoke(self:objectName())
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo" or p:getGeneralName() == "ty_guansuo" or p:getGeneral2Name() == "ty_guansuo" then
							if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..p:getSeat())) then
								p:drawCards(1)
							end
						end
					end
				end
			end
		end
		return false
	end
}
--鎮南
zhennan = sgs.CreateTriggerSkill{
	name = "zhennan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.to and use.to:contains(player) and use.to:length() >= 2 and player:hasSkill(self:objectName()) and (not use.card:isKindOf("SkillCard")) then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "zhennan-invoke", true, true)
			if target then
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
--許身
xushen = sgs.CreateTriggerSkill{
	name = "xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@xushen",
	events = {sgs.EnterDying, sgs.QuitDying},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			if player:getMark("@xushen") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("baosanniang","xushen")
					room:removePlayerMark(player, "@xushen")
					room:addPlayerMark(player,"xushen_invoke")
					room:recover(player, sgs.RecoverStruct(player))
					room:acquireSkill(player, "zhennan")
					
				end
			end
		elseif event == sgs.QuitDying then
			local has_guansuo = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo" or p:getGeneralName() == "ty_guansuo" or p:getGeneral2Name() == "ty_guansuo" then
					has_guansuo = true
				end
			end
			if not has_guansuo and player:hasSkill(self:objectName()) and player:getMark("xushen_invoke") > 0 then
				room:removePlayerMark(player,"xushen_invoke")
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xushen-invoke", true, true)
				if target then
					if room:askForSkillInvoke(target, self:objectName(), data) then
						target:drawCards(3)
						room:changeHero(target, "ty_guansuo", false, false)
					end
				end
			end
		end
		return false
	end
}

baosanniang:addSkill(wuniang)
baosanniang:addSkill(xushen)
if not sgs.Sanguosha:getSkill("zhennan") then skills:append(zhennan) end
baosanniang:addRelateSkill("zhennan")

sgs.LoadTranslationTable{
	["baosanniang"] = "十週年鮑三娘",
	["&baosanniang"] = "鮑三娘",
	["wuniang"] = "武娘",
	[":wuniang"] = "當妳使用或打出【殺】時，妳可以獲得一名其他角色的一張牌。若如此做，其摸一張牌。 （若妳已發動許身，則關索也摸一張牌）",
	["$wuniang1"] = "虽为女子身，不输男儿郎",
	["$wuniang2"] = "剑舞轻盈，沙场克敌",
	["wuniang-invoke"] = "妳可以獲得一名其他角色的一張牌，然後其摸一張牌<br/> <b>操作提示</b>: 選擇一名與妳不同且有手牌的角色→點擊確定<br/>",
	["zhennan"] = "鎮南",
	[":zhennan"] = "當有角色使用普通錦囊牌指定目標後，若此牌目標數大於1，妳可以對一名其他角色造成1點傷害。",
	["$zhennan1"] = "镇守南中，夫君无忧",
	["$zhennan2"] = "与君携手，定平蛮夷",
	["xushen"] = "許身",
	[":xushen"] = "限定技，當妳進入瀕死狀態後，妳可以回復1點體力並獲得技能“鎮南”，然後如果妳脫離瀕死狀態且“關索”不在場，"..
	"妳可令一名其他角色選擇是否用“關索”代替其武將並令其摸三張牌。",
	["xushen-invoke"] = "妳可令一名其他角色選擇是否用“關索”代替其武將並令其摸三張牌<br/> <b>操作提示</b>: 選擇一名與妳不同的角色→點擊確定<br/>",
	["zhennan-invoke"] = "妳可以對一名其他角色造成1點傷害<br/> <b>操作提示</b>: 選擇一名與妳不同的角色→點擊確定<br />",
	["$xushen1"] = "救命之恩，涌泉相报",
	["$xushen2"] = "解我危难，报君华彩",
	["wuniang_kuansho_draw"] = "你可以令“關索”也摸一張牌。",
	["@str_zangnan-damage"] = "你可以對一名角色造成1點隨機傷害",
	["xushen_changehero"] = "變身為「關索」",
}


--曹嬰
caoying = sgs.General(extension,"caoying","wei2","4",false)
--凌人：出牌階段限一次，當你使用【殺】或傷害類錦囊牌指定目標後，你可以猜測其中一個目標的手牌是否有基本牌、錦囊牌或裝備牌。至少猜對一項則此牌對其傷害+1；至少猜對兩項則你摸兩張牌；猜對三項則你獲得“奸雄”和“行殤”直到你下回合開始。
lingren = sgs.CreateTriggerSkill{
	name = "lingren",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetSpecified,sgs.DamageCaused},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if canCauseDamage(use.card) and player:getPhase() == sgs.Player_Play and player:getMark("lingren_Play") == 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local s = room:askForPlayerChosen(player,use.to,self:objectName(),"@lingrenask",true,true)
					if s then
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerMark(player,"lingren_Play",1)
						local n1 = 0
						local n2 = 0
						local n3 = 0
						local correct_guess = 0
						if s:isKongcheng() then
						
						else
							for _, card in sgs.qlist(s:getHandcards()) do
								if card:isKindOf("BasicCard") then
									n1 = n1 + 1
								end
								if card:isKindOf("TrickCard") then
									n2 = n2 + 1
								end
								if card:isKindOf("EquipCard") then
									n3 = n3 + 1
								end
							end
						end
						room:setPlayerMark(player, "lingren_target", (n1+n2+n3))

						local choices = {"has_Basic", "no_Basic"}
						local choice = room:askForChoice(player, "lingren1", table.concat(choices, "+"))
						if (choice == "has_Basic" and n1 > 0) or (choice == "no_Basic" and n1 == 0) then
							correct_guess = correct_guess + 1
						end
						if not player:getAI() then
							room:getThread():delay()
						end
						choices = {"has_Trick", "no_Trick"}
						choice = room:askForChoice(player, "lingren2", table.concat(choices, "+"))
						if (choice == "has_Trick" and n2 > 0) or (choice == "no_Trick" and n2 == 0) then
							correct_guess = correct_guess + 1
						end
						if not player:getAI() then
							room:getThread():delay()
						end
						choices = {"has_Equip", "no_Equip"}
						choice = room:askForChoice(player, "lingren3", table.concat(choices, "+"))
						if (choice == "has_Equip" and n3 > 0) or (choice == "no_Equip" and n3 == 0) then
							correct_guess = correct_guess + 1
						end
						local msg = sgs.LogMessage()
						msg.type = "#lingzen"
						msg.from = player
						msg.to:append(s)
						msg.arg = tostring(correct_guess)
						room:sendLog(msg)
						if correct_guess >= 1 then
							room:setCardFlag(use.card, "damageplus_card")
							s:setFlags("Lingzen_plus")
						end
						if correct_guess >= 2 then
							player:drawCards(2)
						end
						if correct_guess >= 3 then
							if not player:hasSkills("jianxiong|jianxiong_po") then
								room:acquireSkill(player, "lingren_jianxiong")
								room:addPlayerMark(player,"lingren_jianxiong_skillstart")
							end
							if not player:hasSkills("xingshang|mobile_xingshang") then
								room:acquireSkill(player, "lingren_xingshang")
								room:addPlayerMark(player,"lingren_xingshang_skillstart")
							end
						end
						room:setPlayerMark(player, "lingren_target",0)
					end
				end
			end
		elseif event == sgs.DamageCaused then		
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card:hasFlag("damageplus_card") and damage.to:hasFlag("Lingzen_plus") then
				room:setCardFlag(damage.card, "-damageplus_card")
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#lingzen2"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)
			end	
		end
	end,
}

lingren_jianxiong = sgs.CreateMasochismSkill{
	name = "lingren_jianxiong" ,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		local choices = {"draw+cancel"}
		local card = damage.card
		if card then
			local ids = sgs.IntList()
			if card:isVirtualCard() then
				ids = card:getSubcards()
			else
				ids:append(card:getEffectiveId())
			end
			if ids:length() > 0 then
				local all_place_table = true
				for _, id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
						break
					end
				end
				if all_place_table then
					table.insert(choices, "obtain")
				end
			end
		end
		local choice = room:askForChoice(player, "jianxiong", table.concat(choices, "+"), data)
		if choice ~= "cancel" then
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			if choice == "obtain" then
				player:obtainCard(card)
			else
				player:drawCards(1, self:objectName())
			end
		end
	end
}

lingren_xingshang = sgs.CreateTriggerSkill{
	name = "lingren_xingshang",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() or player:isNude() then return false end
		if player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:doAnimate(1, player:objectName(), splayer:objectName())
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local cards = splayer:getCards("he")
			for _,card in sgs.qlist(cards) do
				dummy:addSubcard(card)
			end
			if cards:length() > 0 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
				room:obtainCard(player, dummy, reason, false)
			end
			dummy:deleteLater()
		end
		return false
	end
}



--伏間：鎖定技，結束階段，你隨機觀看一名角色的X張手牌（X為全場手牌數最少的角色手牌數）。
fujian = sgs.CreateTriggerSkill{
	name = "fujian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
			local min_handcard_num = 1000
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				min_handcard_num = math.min(min_handcard_num, p:getHandcardNum())
			end
			local all_alive_players = {}
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				table.insert(all_alive_players, p)
			end
			local random_target = all_alive_players[math.random(1, #all_alive_players)]
			local being_show_cards = {}
			for _, c in sgs.qlist(random_target:getCards("h")) do
				if #being_show_cards < min_handcard_num then
					table.insert(being_show_cards, c:getId())
				end
			end
			
			if #being_show_cards > 0 then
				room:broadcastSkillInvoke(self:objectName())
				
				local fujian_log = sgs.LogMessage()
				fujian_log.type = "$fujian_to_all_log"
				fujian_log.from = player
				fujian_log.to:append(random_target)
				fujian_log.arg = self:objectName()
				room:sendLog(fujian_log)
				
				local show_card_log = sgs.LogMessage()
				show_card_log.type = "$fujian_show_card"
				show_card_log.from = player
				show_card_log.to:append(random_target)
				show_card_log.card_str = table.concat(being_show_cards, "+")
				show_card_log.arg = self:objectName()
				room:sendLog(show_card_log, player)
				
				room:doAnimate(1, player:objectName(), random_target:objectName())
				local json_value = {
					"",
					false,
					being_show_cards,
				}
				room:doNotify(player, sgs.CommandType.S_COMMAND_SHOW_ALL_CARDS, json.encode(json_value))
			end
		end
	end
}

caoying:addSkill(lingren)
caoying:addSkill(fujian)

if not sgs.Sanguosha:getSkill("lingren_jianxiong") then skills:append(lingren_jianxiong) end
if not sgs.Sanguosha:getSkill("lingren_xingshang") then skills:append(lingren_xingshang) end

sgs.LoadTranslationTable{
	["caoying"] = "曹嬰",
	["#caoying"] = "大都督",
	["lingren"] = "凌人",
	["lingren1"] = "凌人",
	["lingren2"] = "凌人",
	["lingren3"] = "凌人",
	[":lingren"] = "出牌階段限一次，當你使用【殺】或傷害類錦囊牌指定目標後，你可以猜測其中一個目標的手牌是否有基本牌、錦囊牌或裝備牌。至少猜對一項則此牌對其傷害+1；至少猜對兩項則你摸兩張牌；猜對三項則你獲得“奸雄”和“行殤”直到你下回合開始。",
	["@lingrenask"]= "猜測其中一個目標的手牌是否有基本牌、錦囊牌或裝備牌",
	["#lingzen"] = "%from 凌人對： %to 共猜中 %arg 項",
	["#Fujang"] = "%from 伏間觀看： %to 的 %arg 張手牌",
	["has_Basic"] = "有基本牌", 
	["no_Basic"] = "沒有基本牌",
	["has_Trick"] = "有錦囊牌", 
	["no_Trick"] = "沒有錦囊牌",
	["has_Equip"] = "有裝備牌",
	["no_Equip"] = "沒有裝備牌",
	["fujian"] = "伏間",
	[":fujian"] = "鎖定技，結束階段，你隨機觀看一名角色的X張手牌（X為全場手牌數最少的角色手牌數）。",
	["#lingzen2"] = "%from 觸發技能 “<font color=\"yellow\"><b>凌人</b></font>”，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
	["$lingren1"] = "敌势已缓，修要走了，老贼！",
	["$lingren2"] = "精兵如炬，困龙难飞！",
	["$fujian1"] = "兵者，诡道也。",
	["$fujian2"] = "良资军备，一览无遗。",
	["~caoying"] = "曹魏天下存，魂归故土安。",
	["$fujian_to_all_log"] = "%from 觀看了 %to 若干張手牌",
	["$fujian_show_card"] = "因 %arg 技能，你 ( %from ) 觀看 %to 的手牌為 %card",
	["lingren_jianxiong"] = "奸雄",
	[":lingren_jianxiong"] = "每當你受到傷害後，你可以選擇一項：獲得對你造成傷害的牌，或摸一張牌。",
	["lingren_xingshang"] = "行殤",
	[":lingren_xingshang"] = "每當一名其他角色死亡時，你可以獲得該角色的牌。",
}

--OL夏侯霸
xiahoubawitholshensu = sgs.General(extension, "xiahoubawitholshensu", "shu2", "4", true)

local function BaobianPoChange(room, player, hp, skill_name)
	local baobian_skills = player:getTag("BaobianPoSkills"):toString():split("+")
	if player:getHp() <= hp then
		if not table.contains(baobian_skills, skill_name) then
			room:notifySkillInvoked(player, "baobian_po")
			if player:getHp() == hp then
				room:broadcastSkillInvoke("baobian", 4 - hp)
			end
			table.insert(BaobianWithOlShensu_acquired_skills, skill_name)
			table.insert(baobian_skills, skill_name)
		end
	else
		if table.contains(baobian_skills, skill_name) then
			table.insert(BaobianWithOlShensu_detached_skills, "-"..skill_name)
			table.removeOne(baobian_skills, skill_name)
		end
	end
	player:setTag("BaobianPoSkills", sgs.QVariant(table.concat(baobian_skills, "+")))
end

baobian_po = sgs.CreateTriggerSkill{
	name = "baobian_po",
	events = {sgs.GameStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local baobian_skills = player:getTag("BaobianPoSkills"):toString():split("+")
				local detachList = {}
				for _, skill_name in ipairs(baobian_skills) do
					table.insert(detachList, "-"..skill_name)
				end
				room:handleAcquireDetachSkills(player, table.concat(detachList,"|"))
				player:setTag("BaobianPoSkills", sgs.QVariant())
			end
			return false
		elseif event == sgs.EventAcquireSkill then
			if data:toString() ~= self:objectName() then return false end
		end
		if not player:isAlive() or not player:hasSkill(self:objectName(), true) then return false end
		BaobianWithOlShensu_acquired_skills = {}
		BaobianWithOlShensu_detached_skills = {}
		BaobianPoChange(room, player, 1, "ol_shensu")
		BaobianPoChange(room, player, 2, "paoxiao_po")
		BaobianPoChange(room, player, 3, "tiaoxin_po")
		if #BaobianWithOlShensu_acquired_skills > 0 or #BaobianWithOlShensu_detached_skills > 0 then
			local final_skill_list = {}
			for _,item in ipairs(BaobianWithOlShensu_acquired_skills) do
				table.insert(final_skill_list, item)
			end
			for _,item in ipairs(BaobianWithOlShensu_detached_skills) do
				table.insert(final_skill_list, item)
			end
			room:handleAcquireDetachSkills(player, table.concat(final_skill_list,"|"))
		end
		return false
	end
}
xiahoubawitholshensu:addSkill(baobian_po)

sgs.LoadTranslationTable{
["#xiahoubawitholshensu"] = "棘途壯志",
["xiahoubawitholshensu"] = "OL夏侯霸",
["&xiahoubawitholshensu"] = "夏侯霸",
["illustrator:xiahoubawitholshensu"] = "熊貓探員",
["baobian_po"] = "豹變",
[":baobian_po"] = "鎖定技，若你的體力值：不大於3，你擁有“挑釁”；不大於2，你擁有“咆哮”；為1，你擁有“神速”。",
["$tiaoxin5"] = "跪下受降，饒你不死！",
["$tiaoxin6"] = "黃口小兒，可聽過將軍名號？",
["$paoxiao6"] = "喝啊~~~",
["$paoxiao7"] = "受死吧！",
["$ol_shensu3"] = "衝殺敵陣，來去如電！",
["$ol_shensu4"] = "今日有恙在身，須得速戰速決！",
["~xiahoubawitholshensu"] = "棄魏投蜀，死而無憾……",
}

--王朗
sec_wanglang = sgs.General(extension, "sec_wanglang", "wei2", 3, true, true)

sec_gusheCard = sgs.CreateSkillCard{
	name = "sec_gushe", 
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 3 and (not to_select:isKongcheng())
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if #targets == 1 then
				source:pindian(targets[1], "sec_gushe", sgs.Sanguosha:getCard(self:getSubcards():first()))
				source:setFlags("-sec_jiciused")
				return
			end
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:addSubcard(self:getSubcards():first())
			local moves = sgs.CardsMoveList()
			local move = sgs.CardsMoveStruct(self:getSubcards(), source, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, source:objectName(), self:objectName(), ""))
			moves:append(move)
			for _, p in pairs(targets) do
				local card = room:askForExchange(p, self:objectName(), 1, 1, false, "@sec_gushe_Pindian:"..source:objectName())
				slash:addSubcard(card:getSubcards():first())
				room:setPlayerMark(p, "sec_gusheid", card:getSubcards():first()+1)
				local move = sgs.CardsMoveStruct(card:getSubcards(), p, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, p:objectName(), self:objectName(), ""))
				moves:append(move)
			end
			room:moveCardsAtomic(moves, true)
			for i = 1, #targets, 1 do
				local pindian = sgs.PindianStruct()
				pindian.from = source
				pindian.to = targets[i]
				pindian.from_card = sgs.Sanguosha:getCard(self:getSubcards():first())
				pindian.to_card = sgs.Sanguosha:getCard(targets[i]:getMark("sec_gusheid") - 1)
				if not source:hasFlag("sec_jiciused") then
					pindian.from_number = pindian.from_card:getNumber()
				else
					pindian.from_number = pindian.from_card:getNumber() + source:getMark("@tongue")
				end
				pindian.to_number = pindian.to_card:getNumber()
				pindian.reason = "sec_gushe"
				room:setPlayerMark(targets[i], "sec_gusheid", 0)
				local data = sgs.QVariant()
				data:setValue(pindian)
				local log = sgs.LogMessage()
				log.type = "$PindianResult"
				log.from = pindian.from
				log.card_str = pindian.from_card:toString()
				room:sendLog(log)
				log.from = pindian.to
				log.card_str = pindian.to_card:toString()
				room:sendLog(log)
				if not source:hasFlag("sec_jiciused") then
					room:getThread():trigger(sgs.PindianVerifying, room, source, data)
				end
				room:getThread():trigger(sgs.Pindian, room, source, data)
			end
			source:setFlags("-sec_jiciused")
			local move2 = sgs.CardsMoveStruct(slash:getSubcards(), nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
			room:moveCardsAtomic(moves, true)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
sec_gusheVS = sgs.CreateOneCardViewAsSkill{
	name = "sec_gushe", 
	filter_pattern = ".|.|.|hand!",
	view_as = function(self, card)
		local aaa = sec_gusheCard:clone()
		aaa:addSubcard(card)
		return aaa
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@tongue") + player:getMark("@sec_gushe_wintimes-Clear") < 7
	end
}
sec_gushe = sgs.CreateTriggerSkill{
	name = "sec_gushe", 
	events = {sgs.Pindian, sgs.CardFinished},
	view_as_skill = sec_gusheVS, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason ~= self:objectName() then return false end
			local winner
			local loser
			if pindian.from_number > pindian.to_number then
				winner = pindian.from
				loser = pindian.to
				local log = sgs.LogMessage()
				log.type = "#PindianSuccess"
				log.from = winner
				log.to:append(loser)
				room:sendLog(log)
				room:addPlayerMark(pindian.from,"@sec_gushe_wintimes-Clear")
			elseif pindian.from_number < pindian.to_number then
				winner = pindian.to
				loser = pindian.from
				local log = sgs.LogMessage()
				log.type = "#PindianFailure"
				log.from = loser
				log.to:append(winner)
				room:sendLog(log)
				pindian.from:gainMark("@tongue")
			else
				pindian.from:gainMark("@tongue")
				if pindian.from:isAlive() and not room:askForCard(pindian.to, ".,Equip", "@sec_gushePunish:"..pindian.from:objectName(), sgs.QVariant(), sgs.Card_MethodDiscard) then
					pindian.from:drawCards(1, self:objectName())
				end
				if pindian.to:isAlive() then
					if pindian.from:isAlive() then
						if not room:askForDiscard(pindian.to, self:objectName(), 1, 1, true) then
							pindian.from:drawCards(1, self:objectName())
						end
					else
						room:askForDiscard(pindian.to, self:objectName(), 1, 1, true)
					end
				end
				return false
			end
			if pindian.from:isAlive() then
				if loser:isAlive() and not room:askForCard(loser, ".,Equip", "@sec_gushePunish:"..pindian.from:objectName(), sgs.QVariant(), sgs.Card_MethodDiscard) then
					pindian.from:drawCards(1, self:objectName())
				end
			else
				if loser:isAlive() and not loser:isNude() then
					room:askForDiscard(loser, self:objectName(), 1, 1)
				end
			end
			if pindian.from:hasSkill("sec_gushe") and pindian.from:getMark("@tongue") >= 7 then
				room:killPlayer(pindian.from)
			end
		else
			if player:hasSkill("sec_gushe") and player:getMark("@tongue") >= 7 then
				room:killPlayer(player)
			end
		end
		return false
	end, 
	can_trigger = function(self, player)
		return player and player:isAlive()
	end
}
sec_wanglang:addSkill(sec_gushe)
sec_jici = sgs.CreateTriggerSkill{
	name = "sec_jici", 
	events = {sgs.PindianVerifying,sgs.Pindian, sgs.CardFinished,sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			if pindian.reason == "sec_gushe" and pindian.from:objectName() == player:objectName() then
				local x = player:getMark("@tongue")
				if pindian.from_number <= x then
					if pindian.from_number < x then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then

							room:addPlayerMark(player, self:objectName().."invoke")
							player:setFlags("sec_jiciused")
							local log = sgs.LogMessage()
							log.type = "#sec_jiciIncrease"
							log.from = pindian.from
							log.arg = pindian.from_number
							pindian.from_number = pindian.from_number + x
							if pindian.from_number > 13 then pindian.from_number = 13 end
							log.arg2 = pindian.from_number
							room:sendLog(log)
							data:setValue(pindian)
							room:removePlayerMark(player, self:objectName().."engine")
							--return
						end
					end
				end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason ~= "sec_gushe" then return false end
			if player:getMark(self:objectName().."invoke") > 0 then
				if pindian.from_card:getNumber() > player:getMark("sec_jici_obtain_card_num") then
					room:setPlayerMark(player, "sec_jici_obtain_card", pindian.from_card:getEffectiveId())
					room:setPlayerMark(player, "sec_jici_obtain_card_num", pindian.from_card:getNumber())
				end
				if pindian.to_card:getNumber() > player:getMark("sec_jici_obtain_card_num") then
					room:setPlayerMark(player, "sec_jici_obtain_card", pindian.to_card:getEffectiveId())
					room:setPlayerMark(player, "sec_jici_obtain_card_num", pindian.to_card:getNumber())
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:getMark("sec_jici_obtain_card") > 0 and use.card:getSkillName() == "sec_gushe" and player:isAlive() then
				local id = player:getMark("sec_jici_obtain_card")
				room:setPlayerMark(player, "sec_jici_obtain_card", 0)
				room:setPlayerMark(player, "sec_jici_obtain_card_num", 0)
				if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
					local card = sgs.Sanguosha:getCard(id)
					room:obtainCard(player, card, true)
				end
			end
		elseif event ==  sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer
			if death.damage then
				killer = death.damage.from
			else
				killer = nil
			end
			if killer and killer:objectName() ~= player:objectName() then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				--room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), killer:objectName())
				local n = 7 - player:getMark("@tongue")
				room:loseHp(killer,1)
				if n > 0 then
					room:askForDiscard(killer,self:objectName(),n,n,false,true)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil and target:hasSkill(self:objectName())
	end ,
}
sec_wanglang:addSkill(sec_jici)

sgs.LoadTranslationTable{
	["sec_wanglang"] = "bug王朗",
	["&sec_wanglang"] = "王朗",
	["#sec_wanglang"] = "鳳鶥",
	["cv:sec_wanglang"] = "無",
	["illustrator:sec_wanglang"] = "無",

	["sec_gushe"] = "鼓舌",
	[":sec_gushe"] = "出牌階段，若X小於7，則你可以用一張手牌與至多三名角色同時拼點，然後依次結算拼點結果，沒贏的角色選擇一項：1.棄置一張牌；2.令你摸一張牌。若你沒贏，你獲得一個「饒舌」標記。當你獲得第7個「饒舌」標記時，你死亡。（X為你的「饒舌」標記數與本回合因「鼓舌」拼點而勝利的次數之和）",
	["@tongue"] = "饒舌",
	["@sec_gusheDiscard"] = "請棄置一張牌，否則 %src 摸一張牌",

	["sec_jici"] = "激詞",
	[":sec_jici"] = "鎖定技，當你展示拼點牌後，若此牌的點數不大於X，則你令此牌點數+X，並獲得此次拼點中原點數最大的拼點牌。當你死亡時，你令殺死你的角色棄置7-X張牌並失去1點體力。（X為你的「饒舌」標記數）",
	["sec_jici:Increase"] = "你可發動“激詞”令你拼點的牌點數 + %arg",
	["#sec_jiciIncrease"] = "%from 的“<font color=\"yellow\"><b>激詞</b></font>被觸發”，拼點的牌點數增加為 %arg",
	["#sec_jiciExtra"] = "%from 拼點的牌點數為 %arg （與“饒舌”標記數相同），發動“<font color=\"yellow\"><b>鼓舌</b>< /font>”的次數上限+ <font color=\"yellow\"><b>1</b></font>",
	["@sec_gushePunish"] = "請棄置一張牌，否則 %src 摸一張牌",
	["@sec_gushe_Pindian"] = " %src 發起鼓舌拼點，你需出一張牌拼點",
	["$sec_gushe1"] = "公既知天命，識時務，為何要興無名之師？犯我疆界？",
	["$sec_gushe2"] = "你若倒戈卸甲，以禮來降，仍不失封侯之位，國安民樂，豈不美哉？",
	["$sec_jici1"] = "諒爾等腐草之熒光，如何比得上天空之皓月~",
	["$sec_jici2"] = "你……諸葛村夫，你敢……",
}

--[[
王允
連計 出牌階段限一次，你可棄置一張手牌，然後令一名其他角色使用牌堆中的一張隨機武器牌，令其對你指定的一名角色使用【殺】，
若其沒有使用【殺】，則將其裝備區的武器交給任意角色。
謀逞 覺醒技，回合開始時，若你發動的「連計」中使用的【殺】造成過傷害，則你失去「連計」，獲得「矜功」。
矜功 出牌階段限一次，你可以將一張裝備牌或【殺】當一張錦囊牌使用（三選一）
]]--

--通用技能
--手牌上限
str_allMaxCard = sgs.CreateMaxCardsSkill{
	name = "#str_allMaxCard", 
	extra_func = function(self, target)
		return target:getMark("@Maxcards") - target:getMark("@zhongjian")
	end
}
--主公觀星模式
--nl_lordguanxin = sgs.CreateTriggerSkill{
--	name = "#nl_lordguanxin" ,
--	events = {sgs.EventPhaseStart} ,
--	global = true,
--	on_trigger = function(self, event, player, data)
--		local room = player:getRoom()
--		if player:getPhase() == sgs.Player_Start then
--			local cards = room:getNCards(3)
--			room:askForGuanxing(player, cards, 0)
--		end
--	end ,
--	can_trigger = function(self, target)
--		return target:isLord()
--	end
--}

if not sgs.Sanguosha:getSkill("#str_allMaxCard") then skills:append(str_allMaxCard) end

---------------------------------------------------------------------------------------
--Lua化技能
lua_zhenggong = sgs.CreateTriggerSkill{
	name = "lua_zhenggong" ,
	events = {sgs.TurnStart} ,
	on_trigger = function(self, event, player, data,room)
		local room = player:getRoom()
		for _, dengshizai in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if dengshizai and dengshizai:faceUp() then
				if dengshizai:askForSkillInvoke(self:objectName()) then
					room:setTag("ExtraTurn",sgs.QVariant(true))
					dengshizai:gainAnExtraTurn()
					room:setTag("ExtraTurn",sgs.QVariant(false))
					dengshizai:turnOver()
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and not target:hasSkill(self:objectName())
	end
}

sgs.LoadTranslationTable{
["lua_zhenggong"] = "爭功",
[":lua_zhenggong"] = "其他角色的回合開始前，若你的武將牌正面朝上，你可以獲得一個額外的回合，此回合結束後，你將武將牌翻面。嘻嘻",
}

lua_baiyin = sgs.CreatePhaseChangeSkill{
	name = "lua_baiyin" ,
	frequency = sgs.Skill_Wake ,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:setPlayerMark(player,"lua_baiyin", 1)
		if room:changeMaxHpForAwakenSkill(player) then
			room:broadcastSkillInvoke("lua_baiyin")
			if player:getMark("@bear") >= 4 then
				local msg = sgs.LogMessage()
				msg.type = "#BaiyinWake"
				msg.from = player
				msg.to:append(player)
				msg.arg = tostring(player:getMark("@bear"))
				room:sendLog(msg)
			end
			room:doSuperLightbox("shensimayi","lua_baiyin")
			room:acquireSkill(player, "jilve")
		end
		return false
	end ,
	can_trigger = function(self,target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("lua_baiyin") == 0)
				and (target:getMark("@bear") >= 4 or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}

sgs.LoadTranslationTable{
["lua_baiyin"] ="拜印",
[":lua_baiyin"] ="覺醒技。準備階段開始時，若你擁有四枚或更多的“忍”，你失去1點體力上限，然後獲得“極略”（你可以棄一枚“忍”並發動以下技能之一：“鬼才”、“放逐”、“集智”、“制衡”、“完殺”）。",
["#BaiyinWake"] = "%from 的“忍”為 %arg 個，觸發“<font color=\"yellow\"><b>拜印</b></font>”覺醒",
}

lua_qianxin = sgs.CreateTriggerSkill{
	name = "lua_qianxin",
	frequency = sgs.Skill_Wake ,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) and player:isAlive() and (player:isWounded() or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) then
			room:setPlayerMark(player,"baiyin_po", 1)
			if room:changeMaxHpForAwakenSkill(player) then
				room:broadcastSkillInvoke("qianxin")
				if player:isWounded()  then
					local msg = sgs.LogMessage()
					msg.type = "#QianxinWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = self:objectName()
					room:sendLog(msg)
				end
				room:doSuperLightbox("st_xushu","lua_qianxin")
				room:acquireSkill(player, "jianyan")
			end
		end
		return false
	end,
}

sgs.LoadTranslationTable{
["lua_qianxin"] = "潛心",
[":lua_qianxin"] = "覺醒技。每當你造成傷害後，若你已受傷，你失去1點體力上限，然後獲得“薦言”（階段技。你可以選擇一種牌的類別或顏色，然後你依次亮出牌堆頂的牌直到與你的選擇相符，然後你令一名男性角色獲得此牌，再將亮出的牌置入棄牌堆）。",
["#QianxinWake"] = "%from 已受傷，觸發“%arg”覺醒",
}

lua_qinxue = sgs.CreateTriggerSkill{
	name = "lua_qinxue" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("lua_qinxue") == 0 then
				local n = player:getHandcardNum() > player:getHp()
				local n2
				if room:alivePlayerCount() >= 7 then
					n2 = 2
				else
					n2 = 3
				end
				if (n >= n2 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) then
					room:addPlayerMark(player, "lua_qinxue")
					if room:changeMaxHpForAwakenSkill(player) then
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke("qinxue")
						if n >= n2 then
							local msg = sgs.LogMessage()
							msg.type = "#QinxueWake"
							msg.from = player
							msg.to:append(player)
							msg.arg = n
							msg.arg2 = self:objectName()
							room:sendLog(msg)
						end
						room:doSuperLightbox("lvmeng","lua_qinxue")
						room:acquireSkill(player, "gongxin")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
	end
}

sgs.LoadTranslationTable{
["lua_qinxue"] = "勤學",
[":lua_qinxue"] = "覺醒技。準備階段開始時，若你的手牌數比體力值多3（七人及以上游戲為2）或更多，你失去1點體力上限，然後獲得“攻心”。",
["$QinxueAnimate"] = "image=image/animate/qinxue.png",
["#QinxueWake"] = "%from 手牌數比體力值多 %arg，觸發“%arg2”覺醒",
}

sgs.LoadTranslationTable{
[":lua_baoling"] = "覺醒技。出牌階段結束時，若你本局遊戲發動過“橫徵”，你增加3點體力上限，回復3點體力，然後獲得“崩壞”。",

}
--鑿險
lua_zaoxian = sgs.CreateTriggerSkill{
	name = "lua_zaoxian" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("lua_zaoxian") == 0 then
				if player:getPile("field"):length() >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
					room:addPlayerMark(player, "lua_zaoxian")
					if room:changeMaxHpForAwakenSkill(player) then
						room:notifySkillInvoked(player,self:objectName())
						if player:getGeneralName() == "mobile_dengai" then
							room:broadcastSkillInvoke("zaoxian")
						else
							room:broadcastSkillInvoke("zaoxian")
						end
						if player:getPile("field"):length() >= 3 then
							local msg = sgs.LogMessage()
							msg.type = "#ZaoxianWake"
							msg.from = player
							msg.to:append(player)
							msg.arg = player:getPile("field"):length()
							msg.arg2 = self:objectName()
							room:sendLog(msg)
						end
						if player:getGeneralName() == "mobile_dengai" then
							room:doSuperLightbox("mobile_dengai","lua_zaoxian")
						else
							room:doSuperLightbox("dengai","lua_zaoxian")
						end
						room:acquireSkill(player, "jixi")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
	end
}

sgs.LoadTranslationTable{
["lua_zaoxian"] = "鑿險",
[":lua_zaoxian"] = "覺醒技。準備階段開始時，若你的“田”大於或等於三張，你失去1點體力上限，然後獲得“急襲”（你可以將一張“田”當【順手牽羊】使用）。",
["#ZaoxianWake"] = "%from 的“田”為 %arg 張，觸發“%arg2”覺醒",
}

lua_zhiji = sgs.CreateTriggerSkill{
	name = "lua_zhiji" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:changeMaxHpForAwakenSkill(player) then
			if player:isKongcheng() then
				local msg = sgs.LogMessage()
				msg.type = "#ZhijiWake"
				msg.from = player
				msg.to:append(player)
				msg.arg = self:objectName()
				room:sendLog(msg)
			end
			if player:getGeneralName() == "mobile_jiangwei" then
				room:broadcastSkillInvoke("zhiji",math.random(3,4))
			else
				room:broadcastSkillInvoke("zhiji",math.random(1,2))
			end

			if player:getGeneralName() == "mobile_jiangwei" then
				room:doSuperLightbox("mobile_jiangwei","lua_zhiji")
			else
				room:doSuperLightbox("jiangwei","lua_zhiji")
			end

			if player:getGeneralName() == "jiangwei" then
				room:acquireSkill(player, "guanxing")
			else
				room:acquireSkill(player, "guanxing_po")
			end
		end
		if player:isWounded() then
			if room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2)
			end
		else
			room:drawCards(player, 2)
		end
		room:addPlayerMark(player, "lua_zhiji")
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("lua_zhiji") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:isKongcheng() or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}

sgs.LoadTranslationTable{
["lua_zhiji"] = "志繼",
["#ZhijiWake"] = "%from 沒有手牌，觸發“%arg”覺醒",
[":lua_zhiji"] = "覺醒技。準備階段開始時，若你沒有手牌，你失去1點體力上限，然後回復1點體力或摸兩張牌，並獲得“觀星”。",

}

lua_ruoyu = sgs.CreateTriggerSkill{
	name = "lua_ruoyu$",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end
		if can_invoke or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			if can_invoke then
				local msg = sgs.LogMessage()
				msg.type = "#RuoyuWake"
				msg.from = player
				msg.to:append(player)
				msg.arg = player:getHp()
				msg.arg2 = self:objectName()
				room:sendLog(msg)
			end
			room:addPlayerMark(player, "lua_ruoyu")
			if room:changeMaxHpForAwakenSkill(player, 1) then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)

				if player:getGeneralName() == "mobile_liushan" then
					room:broadcastSkillInvoke(self:objectName())
				else
					room:broadcastSkillInvoke(self:objectName())
				end

				if player:getGeneralName() == "mobile_liushan" then
					room:doSuperLightbox("mobile_liushan", self:objectName())
				else
					room:doSuperLightbox("liushan", self:objectName())
				end
				room:acquireSkill(player, "jijiang")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasLordSkill("lua_ruoyu")
				and target:isAlive()
				and (target:getMark("lua_ruoyu") == 0)
	end
}

sgs.LoadTranslationTable{
["lua_ruoyu"] = "若愚",
[":lua_ruoyu"] = "主公技。覺醒技。準備階段開始時，若你的體力值為場上最少（或之一），你增加1點體力上限，回復1點體力，然後獲得“激將”。",
["#RuoyuWake"] = "%from 的體力值 %arg 為場上最少，觸發“%arg2”覺醒",
}

lua_hunzi = sgs.CreateTriggerSkill{
	name = "lua_hunzi" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke("hunzi")
		room:doSuperLightbox("sunce_po","hunzi")
		if player:getHp() == 1 then
			local msg = sgs.LogMessage()
			msg.type = "#HunziWake"
			msg.from = player
			msg.to:append(player)
			msg.arg = self:objectName()
			room:sendLog(msg)
		end
		room:addPlayerMark(player, "lua_hunzi")
		room:addPlayerMark(player, "hunzi")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "yingzi|yinghun")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("lua_hunzi") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getHp() <= 1 or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}

sgs.LoadTranslationTable{
["lua_hunzi"] = "魂姿",
[":lua_hunzi"] = "覺醒技。準備階段開始時，若你的體力值為1，你失去1點體力上限，然後獲得“英姿”和“英魂”。",
["#HunziWake"] = "%from 的體力值為 <font color=\"yellow\"><b>1</b></font>，觸發“%arg”覺醒",
}


lua_jiehuo = sgs.CreateTriggerSkill{
	name = "lua_jiehuo",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@shouye") >= 7 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:addPlayerMark(player, "lua_jiehuo")
			if room:changeMaxHpForAwakenSkill(player) then
				room:broadcastSkillInvoke(self:objectName())
				if player:getMark("@shouye") >= 7 then
					local msg = sgs.LogMessage()
					msg.type = "#JiehuoWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = player:getMark("@shouye")
					msg.arg2 = self:objectName()
					room:sendLog(msg)
				end

				room:doSuperLightbox("wis_shuijing","lua_jiehuo")
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				room:setPlayerMark(player,"@shouye",0)
				room:setPlayerMark(player,"jiehuo",1)
				room:acquireSkill(player, "shien")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("lua_jiehuo")
				and target:isAlive()
				and (target:getMark("lua_jiehuo") == 0)
	end
}




sgs.LoadTranslationTable{
	["lua_jiehuo"] = "解惑",
[":lua_jiehuo"] = "<font color=\"purple\"><b>覺醒技，</b></font>當你發動“授業”不少於7人次時，須減1點體力上限，並獲得技能“師恩”（其他角色使用非延時錦囊時，可以讓你摸一張牌）。",
	["#JiehuoWake"] = "%from 發動〖授業〗的次數達到 %arg 張，觸發“%arg2”覺醒",
}

lua_danji = sgs.CreateTriggerSkill{
	name = "lua_danji",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
			and target:getMark("lua_danji") == 0 and (target:getHandcardNum() > target:getHp() or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local lord = room:getLord()
		if (lord and (string.find(lord:getGeneralName(), "caocao") or string.find(lord:getGeneral2Name(), "caocao"))) or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:setPlayerMark(player, "lua_danji", 1)
			if room:changeMaxHpForAwakenSkill(player) and player:getMark("lua_danji") == 1 then
				if player:getHandcardNum() > player:getHp() then
					local msg = sgs.LogMessage()
					msg.type = "#DanjiWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = tostring(player:getHandcardNum())
					msg.arg2 = tostring(player:getHp())
					room:sendLog(msg)
				end
				room:broadcastSkillInvoke("danqi")
				room:doSuperLightbox("sp_guanyu","lua_danji")
				room:acquireSkill(player, "mashu")
			end
		end
	end,
}

sgs.LoadTranslationTable{
["lua_danji"] = "單騎",
[":lua_danji"] = "覺醒技。準備階段開始時，若你的手牌數大於體力值，且本局遊戲主公為曹操，你失去1點體力上限，然後獲得“馬術”。",

}

lua_wuji = sgs.CreatePhaseChangeSkill{
	name = "lua_wuji",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if room:changeMaxHpForAwakenSkill(player, 1) then
			if player:getMark("damage_record-Clear") >= 3 then
				local msg = sgs.LogMessage()
				msg.type = "#WujiWake"
				msg.from = player
				msg.to:append(player)
				msg.arg = player:getMark("damage_record-Clear")
				msg.arg2 = self:objectName()
				room:sendLog(msg)
			end
			room:broadcastSkillInvoke("wuji")
			room:setPlayerMark(player, self:objectName(), 1)
			room:doSuperLightbox("guanyinping","lua_wuji")	
			room:recover(player, sgs.RecoverStruct(player))
			room:detachSkillFromPlayer(player, "huxiao")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish 
		and target:getMark(self:objectName()) == 0 and (target:getMark("damage_record-Clear") >= 3  or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}


sgs.LoadTranslationTable{
["lua_wuji"] = "武繼",
[":lua_wuji"] = "覺醒技。結束階段開始時，若你於本回合造成了至少3點傷害，你增加1點體力上限，回復1點體力，然後失去“虎嘯”。",
["#WujiWake"] = "%from 於此回合內造成過 %arg 點傷害，觸發“%arg2”覺醒",
}

lua_juyi = sgs.CreateTriggerSkill{
	name = "lua_juyi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMaxHp() > room:alivePlayerCount() or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:addPlayerMark(player, "lua_juyi")
			if room:changeMaxHpForAwakenSkill(player, 1) then
				room:broadcastSkillInvoke(self:objectName())
				if player:getMaxHp() > room:alivePlayerCount() then
					local msg = sgs.LogMessage()
					msg.type = "#JuyiWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = tostring(player:getMaxHp())
					msg.arg2 = tostring(room:alivePlayerCount())
					room:sendLog(msg)
				end

				if player:getMaxHp() > player:getHandcardNum() then
					player:drawCards( player:getMaxHp() - player:getHandcardNum() )
				end
				room:doSuperLightbox("zhugedan","lua_juyi")				

				room:acquireSkill(player, "weizhong")
				room:acquireSkill(player, "benghuai")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("lua_juyi")
				and target:isAlive()
				and (target:getMark("lua_juyi") == 0)
	end
}


sgs.LoadTranslationTable{
["lua_juyi"] = "舉義",
["#JuyiWake"] = "%from 的體力上限(%arg)大於角色數(%arg2)，觸發“<font color=\"yellow\"><b>舉義</b></font> ”覺醒",
[":lua_juyi"] = "覺醒技。準備階段開始時，若你已受傷且體力上限大於角色數，你將手牌補至體力上限，然後獲得“崩壞”和“威重”（鎖定技。每當你的體力上限改變後，你摸一張牌）。",
}

lua_zhiri = sgs.CreateTriggerSkill{
	name = "lua_zhiri" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("lua_zhiri") == 0 then
				if player:getPile("burn"):length() >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
					room:addPlayerMark(player, "lua_zhiri")
					if room:changeMaxHpForAwakenSkill(player) then
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke("zhiri")
						if player:getPile("burn"):length() >= 3 then
							local msg = sgs.LogMessage()
							msg.type = "#ZhiriWake"
							msg.from = player
							msg.to:append(player)
							msg.arg = player:getPile("burn"):length()
							msg.arg2 = self:objectName()
							room:sendLog(msg)
						end
						room:doSuperLightbox("hanba","lua_zhiri")
						room:acquireSkill(player, "xintan")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
	end
}

sgs.LoadTranslationTable{
["burn"] = "焚",
["lua_zhiri"] = "炙日",
[":lua_zhiri"] = "覺醒技，準備階段開始時，若“焚”數不小於3，你減1點體力上限，然後獲得技能“心惔”（出牌階段限一次，你可以將兩張“焚”置入棄牌堆並選擇一名角色，該角色失去一點體力）。",
["hanba"] = "旱魃",
["xintan"] = "心惔",
["#ZhiriWake"] = "%from 的“焚”為 %arg 張，觸發“%arg2”覺醒",
}

lua_liangzhu = sgs.CreateTriggerSkill{
	name = "lua_liangzhu",
	events = {sgs.HpRecover},
	on_trigger = function(self, event, player, data, room)
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local choice = room:askForChoice(p, self:objectName(), "lua_liangzhu:draw+lua_liangzhu:letdraw+lua_liangzhu:dismiss")
			if choice == "lua_liangzhu:draw" then
				room:broadcastSkillInvoke("liangzhu")
				room:doAnimate(1, p:objectName(), player:objectName())
				p:drawCards(1)
			elseif choice == "lua_liangzhu:letdraw" then
				room:broadcastSkillInvoke("liangzhu")
				room:doAnimate(1, p:objectName(), player:objectName())
				player:drawCards(2)
				room:setPlayerMark(player,"@liangzhu_draw",1)
				room:setPlayerMark(player,"lua_liangzhu_draw"..p:objectName(),1)
			elseif choice == "lua_liangzhu:dismiss" then

			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getPhase() == sgs.Player_Play
	end
}

lua_fanxiang = sgs.CreateTriggerSkill{
	name = "lua_fanxiang",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local invoke = false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isAlive() and p:getMark("lua_liangzhu_draw"..player:objectName()) > 0 and p:isWounded() then
				invoke = true
			end
		end
		if invoke or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:setPlayerMark(player, "lua_fanxiang", 1)
			if room:changeMaxHpForAwakenSkill(player,1) and player:getMark("lua_fanxiang") == 1 then
				--[[
				if invoke then
					local msg = sgs.LogMessage()
					msg.type = "#fanxiangWake"
					msg.from = player
					msg.to:append(player)
					room:sendLog(msg)
				end
				]]--

				room:broadcastSkillInvoke("fanxiang")
				room:doSuperLightbox("jsp_sunshangxiang","fanxiang")
				room:handleAcquireDetachSkills(player, "xiaoji|-lua_liangzhu")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("lua_fanxiang") == 0)
	end
}

sgs.LoadTranslationTable{
["jsp_sunshangxiang"] = "J.SP孫尚香",
["&jsp_sunshangxiang"] = "孫尚香",
["#jsp_sunshangxiang"] = "夢醉良緣",
["lua_liangzhu"] = "良助",
[":lua_liangzhu"] = "當一名角色於其出牌階段內回復體力時，你可以選擇一項：摸一張牌，或令該角色摸兩張牌。",
["lua_liangzhu:draw"] = "摸一張牌",
["lua_liangzhu:letdraw"] = "讓其摸兩張牌",
["lua_liangzhu:dismiss"] = "取消",
["lua_fanxiang"] = "返鄉",
[":lua_fanxiang"] = "覺醒技。準備階段開始時，若全場有至少一名已受傷角色，且你曾發動過“良助”令其摸牌，" ..
"則你回復1點體力和體力上限，失去技能“良助”並獲得技能“梟姬”。",
}

lua_jspdanqi = sgs.CreateTriggerSkill{
	name = "lua_jspdanqi",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
			and target:getMark("lua_jspdanqi") == 0 and (target:getHandcardNum() > target:getHp() or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local lord = room:getLord()
		if (lord and not (string.find(lord:getGeneralName(), "liubei") or string.find(lord:getGeneral2Name(), "liubei"))) or (not lord) or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:setPlayerMark(player, "lua_jspdanqi", 1)
			if room:changeMaxHpForAwakenSkill(player) and player:getMark("lua_jspdanqi") == 1 then
				if player:getHandcardNum() > player:getHp() then
					local msg = sgs.LogMessage()
					msg.type = "#DanjiWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = tostring(player:getHandcardNum())
					msg.arg2 = tostring(player:getHp())
					room:sendLog(msg)
				end
				if player:getGeneralName() == "jsp_guanyu" then
					room:broadcastSkillInvoke("jspdanqi")
				else
					room:broadcastSkillInvoke("jspdanqi")
				end
				if player:getGeneralName() == "jsp_guanyu" then
					room:doSuperLightbox("jsp_guanyu","lua_jspdanqi")
				else
					room:doSuperLightbox("jsp_guanyu_po","lua_jspdanqi")
				end


				room:acquireSkill(player, "mashu")
				room:acquireSkill(player, "nuzhan")
			end
		end
	end,
}

sgs.LoadTranslationTable{
["jsp_guanyu"] = "J.SP關羽",
["&jsp_guanyu"] = "關羽",
["#jsp_guanyu"] = "漢壽亭侯",
["illustrator:jsp_guanyu"] = "Zero",
["lua_jspdanqi"] = "單騎",
[":lua_jspdanqi"] = "覺醒技。準備階段開始時，若你的手牌數大於你的體力值且主公不為劉備，你減1點體力上限，然後獲得“馬術”和“怒斬” 。",
["nuzhan"] = "怒斬",
[":nuzhan"] = "鎖定技。你使用的由一張錦囊牌轉化而來的【殺】不計入限制的使用次數；鎖定技。你使用的由一張裝備牌轉化而來的【殺】的傷害值基數+1。",
["#DanjiWake"] = "%from 手牌數(%arg)大於體力值(%arg2)，觸發“<font color=\"yellow\"><b>單騎</b></font> ”覺醒",
}

lua_oljixi = sgs.CreateTriggerSkill{
	name = "lua_oljixi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("oljixi_turn") >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:addPlayerMark(player, "lua_oljixi")
			if room:changeMaxHpForAwakenSkill(player, 1) then
				room:broadcastSkillInvoke(self:objectName())
				if player:getMark("oljixi_turn") >= 3 then
					local msg = sgs.LogMessage()
					msg.type = "#oljixi-wake"
					msg.from = player
					msg.to:append(player)
					room:sendLog(msg)
				end
				room:doSuperLightbox("ol_yuanshu","lua_oljixi")
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
				local has_lord_skill = false
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isLord() then
						for _, skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
							if skill:isLordSkill() and p:hasLordSkill(skill:objectName()) then
								has_lord_skill = true
							end
						end
						for _, skill in sgs.qlist(p:getGeneral2():getVisibleSkillList()) do
							if skill:isLordSkill() and p:hasLordSkill(skill:objectName()) then
								has_lord_skill = true
							end
						end
					end
				end

				if has_lord_skill and room:askForChoice(player, self:objectName(), "oljixi:wangzun+oljixi:lordskill") == "oljixi:lordskill" then
					player:drawCards(2)
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isLord() then
							for _, skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
								if skill:isLordSkill() and p:hasLordSkill(skill:objectName()) then
									room:acquireSkill(player, skill:objectName())
								end
							end
							for _, skill in sgs.qlist(p:getGeneral2():getVisibleSkillList()) do
								if skill:isLordSkill() and p:hasLordSkill(skill:objectName()) then
									room:acquireSkill(player, skill:objectName())
								end
							end
						end
					end
				else
					room:acquireSkill(player, "wangzun")
				end
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Finish)
				and target:hasSkill("lua_oljixi")
				and target:isAlive()
				and (target:getMark("lua_oljixi") == 0)
	end
}


sgs.LoadTranslationTable{
["lua_oljixi"] = "覬璽",
[":lua_oljixi"] = "覺醒技，你的回合結束時，若你連續三回合沒有失去過體力，則你加1點體力上限並回復1點體力，然後選擇一項：1．獲得技能“妄尊”；2．摸兩張牌並獲得當前主公的主公技。",
["#oljixi-wake"] = "%from 連續三個回合沒有失去過體力，觸發“<font color=\"yellow\"><b>覬璽</b></font>”覺醒",
["oljixi:wangzun"] = "獲得技能“妄尊”",
["oljixi:lordskill"] = "摸兩張牌並獲得主公技",
["oljixi_lordskill"] = "覬璽",
}

lua_kegou = sgs.CreateTriggerSkill{
	name = "lua_kegou",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local invoke = true
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:isAlive() and (p:getKingdom() == "wu")
					and (not p:isLord()) and (p:objectName() ~= player:objectName()) then
				invoke = false
			end
		end
		if invoke or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:setPlayerMark(player, "lua_kegou", 1)
			if room:changeMaxHpForAwakenSkill(player) and player:getMark("kegou") == 1 then
				if invoke then
					local msg = sgs.LogMessage()
					msg.type = "#kegouWake"
					msg.from = player
					msg.to:append(player)
					room:sendLog(msg)
				end

				room:broadcastSkillInvoke("jspdanqi")
				room:doSuperLightbox("lukang","lua_kegou")
				room:acquireSkill(player, "nos_lianying")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("lua_kegou") == 0)
				and (target:getKingdom() == "wu")
				and (not target:isLord())
	end
}

sgs.LoadTranslationTable{
["lukang"] = "陸抗",
["lua_kegou"] = "克構",
[":lua_kegou"] = "<font color=\"purple\"><b>覺醒技，</b></font>準備階段開始時，若你是除主公外唯一的吳勢力角色，你減少1點體力上限，獲得技能“連營”。",
["#KegouWake"] = "%from 是場上唯一的吳勢力角色，滿足“克構”的覺醒條件",
}

lua_zili = sgs.CreateTriggerSkill{
	name = "lua_zili" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("lua_zili") == 0 then

				local kingdom_set = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					local kingdom = p:getKingdom()
					if not table.contains(kingdom_set, kingdom) then
						table.insert(kingdom_set, kingdom)
					end
				end

				if player:getPile("power"):length() >= #kingdom_set or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
					room:addPlayerMark(player, "lua_zili")
					if room:changeMaxHpForAwakenSkill(player) then
						room:notifySkillInvoked(player,self:objectName())
						if player:getGeneralName() == "mobile_zhonghui" then
							room:broadcastSkillInvoke("zili")
						else
							room:broadcastSkillInvoke("zili")
						end
						if player:getPile("power"):length() >= #kingdom_set then
							local msg = sgs.LogMessage()
							msg.type = "#ZiliWake"
							msg.from = player
							msg.to:append(player)
							msg.arg = player:getPile("power"):length()
							msg.arg2 = self:objectName()
							room:sendLog(msg)
						end
						if player:getGeneralName() == "mobile_zhonghui" then
							room:doSuperLightbox("mobile_zhonghui","lua_zili")
						else
							room:doSuperLightbox("zhonghui","lua_zili")
						end

						if player:isWounded() and room:askForChoice(player, self:objectName(), "zili:recover+zili:draw") == "zili:recover" then
							room:recover(player, sgs.RecoverStruct(player))
						else
							room:drawCards(player, 2)
						end

						room:acquireSkill(player, "paiyi")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
	end
}

sgs.LoadTranslationTable{
["lua_zili"] = "自立",
[":lua_zili"] = "覺醒技。準備階段開始時，若“權”大於或等於三張，你失去1點體力上限，摸兩張牌或回復1點體力，然後獲得“排異”（階段技。你可以將一張“權”置入棄牌堆並選擇一名角色：若如此做，該角色摸兩張牌：若其手牌多於你，該角色受到1點傷害）。" ,
["#ZiliWake"] = "%from 的“權”為 %arg 張，觸發“%arg2”覺醒",
["zili:draw"] = "摸兩張牌",
["zili:recover"] = "回復1點體力",
["power"] = "權",
["$ZiliAnimate"] = "image=image/animate/zili.png",
["paiyi"] = "排異",
[":paiyi"] = "階段技。你可以將一張“權”置入棄牌堆並選擇一名角色：若如此做，該角色摸兩張牌：若其手牌多於你，該角色受到1點傷害。",
}

lua_tiandu = sgs.CreateTriggerSkill{
	name = "lua_tiandu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and player:askForSkillInvoke(self:objectName(), card_data) then
			if player:getGeneralName() == "xizhicai" then
				room:broadcastSkillInvoke(self:objectName(), math.random(5,6))
			elseif player:getGeneralName() == "nos_guojia" then
				room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
			else
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			end
			player:obtainCard(card)
		end
	end
}

sgs.LoadTranslationTable{
	["lua_tiandu"] = "天妒",
	[":lua_tiandu"] = "每當你的判定牌生效後，你可以獲得之。",
}

lua_skill_change = sgs.CreateTriggerSkill{
	name = "lua_skill_change",
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	global = true,
	on_trigger=function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill or event == sgs.GameStart then
			local skill_list = {"zhenggong","qianxin","qinxue","zaoxian","zhiji",
			  "ruoyu","hunzi","jiehuo","danji","wuji","juyi","zhiri","liangzhu","fanxiang",
			  "jspdanqi","oljixi","kegou","zili","tiandu"}
			for _, sk in ipairs(skill_list) do
				if player:hasSkill(sk) then
					room:handleAcquireDetachSkills(player, "lua_"..sk.."|-"..sk)
				end
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("lua_skill_change") then skills:append(lua_skill_change) end
if not sgs.Sanguosha:getSkill("lua_zhenggong") then skills:append(lua_zhenggong) end
if not sgs.Sanguosha:getSkill("lua_qianxin") then skills:append(lua_qianxin) end
if not sgs.Sanguosha:getSkill("lua_qinxue") then skills:append(lua_qinxue) end
if not sgs.Sanguosha:getSkill("lua_zaoxian") then skills:append(lua_zaoxian) end
if not sgs.Sanguosha:getSkill("lua_zhiji") then skills:append(lua_zhiji) end
if not sgs.Sanguosha:getSkill("lua_ruoyu") then skills:append(lua_ruoyu) end
if not sgs.Sanguosha:getSkill("lua_hunzi") then skills:append(lua_hunzi) end
if not sgs.Sanguosha:getSkill("lua_jiehuo") then skills:append(lua_jiehuo) end
if not sgs.Sanguosha:getSkill("lua_danji") then skills:append(lua_danji) end
if not sgs.Sanguosha:getSkill("lua_wuji") then skills:append(lua_wuji) end
if not sgs.Sanguosha:getSkill("lua_juyi") then skills:append(lua_juyi) end
if not sgs.Sanguosha:getSkill("lua_zhiri") then skills:append(lua_zhiri) end
if not sgs.Sanguosha:getSkill("lua_liangzhu") then skills:append(lua_liangzhu) end
if not sgs.Sanguosha:getSkill("lua_fanxiang") then skills:append(lua_fanxiang) end
if not sgs.Sanguosha:getSkill("lua_jspdanqi") then skills:append(lua_jspdanqi) end
if not sgs.Sanguosha:getSkill("lua_oljixi") then skills:append(lua_oljixi) end
if not sgs.Sanguosha:getSkill("lua_kegou") then skills:append(lua_kegou) end
if not sgs.Sanguosha:getSkill("lua_zili") then skills:append(lua_zili) end
if not sgs.Sanguosha:getSkill("lua_tiandu") then skills:append(lua_tiandu) end

sgs.Sanguosha:addSkills(skills)

