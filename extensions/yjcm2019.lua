module("extensions.yjcm2019", package.seeall)
extension = sgs.Package("yjcm2019")

sgs.LoadTranslationTable{
	["yjcm2019"] = "2019新武將",
}

local skills = sgs.SkillList()

--張琪瑛
zhangqiying = sgs.General(extension, "zhangqiying", "qun2", "3", false)
--法籙
falu = sgs.CreateTriggerSkill{
	name = "falu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:setPlayerMark(player, "@falu_ziwei", 1)
			room:setPlayerMark(player, "@falu_houtu", 1)
			room:setPlayerMark(player, "@falu_yuqing", 1)
			room:setPlayerMark(player, "@falu_gouchen", 1)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:hasSkill(self:objectName()) and move.from and move.from:objectName() == player:objectName()
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			and move.to_place == sgs.Player_DiscardPile
			then
				local play_vo = false
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getSuit() == sgs.Card_Spade and player:getMark("@falu_ziwei") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_ziwei", 1)
					elseif card:getSuit() == sgs.Card_Club and player:getMark("@falu_houtu") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_houtu", 1)
					elseif card:getSuit() == sgs.Card_Heart and player:getMark("@falu_yuqing") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_yuqing", 1)
					elseif card:getSuit() == sgs.Card_Diamond and player:getMark("@falu_gouchen") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_gouchen", 1)
					end
				end
				if play_vo then
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:notifySkillInvoked(player, self:objectName())
				end
			end
		end
		return false
	end
}
zhangqiying:addSkill(falu)
--真儀
zhenyiVS = sgs.CreateViewAsSkill{
	name = "zhenyi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
			peach:setSkillName(self:objectName())
			peach:addSubcard(id)
			return peach
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		local phase = player:getPhase()
		if phase == sgs.Player_NotActive and player:getMark("@falu_houtu") > 0 then
			return string.find(pattern, "peach")
		end
		return false
	end
}


zhenyi = sgs.CreateTriggerSkill{
	name = "zhenyi",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = zhenyiVS,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.AskForRetrial, sgs.AskForPeaches, sgs.DamageCaused, sgs.Damaged, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart or event == sgs.EventAcquireSkill then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:handleAcquireDetachSkills(p, "#zhenyi_spade_5_judge|#zhenyi_heart_5_judge", false)
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if player:hasSkill(self:objectName()) and player:getMark("@falu_ziwei") > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:setPlayerMark(player, "@falu_ziwei", 0)
				local choice = room:askForChoice(player, self:objectName(), "zhenyi_Spade+zhenyi_Heart")
				if choice == "zhenyi_Spade" then
					room:setCardFlag(judge.card, "zhenyi_spade_5_judge")
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
					
					--已下只對判定條件有judge:isGood()有效
--					room:handleAcquireDetachSkills(judge.who, "#zhenyi_spade_5_judge", false)
--					local cardlists = sgs.CardList()
--					cardlists:append(judge.card)
--					room:filterCards(judge.who, cardlists, true)
--					judge:updateResult()
--					room:handleAcquireDetachSkills(judge.who, "-#zhenyi_spade_5_judge", false)
				elseif choice == "zhenyi_Heart" then
					room:setCardFlag(judge.card, "zhenyi_heart_5_judge")
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
					
					--已下只對判定條件有judge:isGood()有效
--					room:handleAcquireDetachSkills(judge.who, "#zhenyi_heart_5_judge", false)
--					local cardlists = sgs.CardList()
--					cardlists:append(judge.card)
--					room:filterCards(judge.who, cardlists, true)
--					judge:updateResult()
--					room:handleAcquireDetachSkills(judge.who, "-#zhenyi_heart_5_judge", false)
				end
			end
			--[[
		elseif event == sgs.AskForPeaches then
			local dying = data:toDying()
			if dying.who and player:hasSkill(self:objectName()) and player:getMark("@falu_houtu") > 0 and player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(dying.who, "zhenyi_dying_who", 1)
				if room:askForUseCard(player, "@zhenyi", "@zhenyi", -1, sgs.Card_MethodNone) then
					room:setPlayerMark(player, "@falu_houtu", 0)
				end
				room:setPlayerMark(dying.who, "zhenyi_dying_who", 0)
				
				--以下木馬中的牌看不到
				--local card = room:askForCard(dying.who, ".|.|.|hand", "@zhenyi", data, sgs.Card_MethodNone)
				--if card then
				--	room:setPlayerMark(dying.who, "@falu_houtu", 0)
				--	local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
				--	peach:addSubcard(card:getEffectiveId())
				--	peach:setSkillName(self:objectName())
				--	room:useCard(sgs.CardUseStruct(peach, dying.who, dying.who))
				--end
			end
]]--
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "zhenyi" and use.from:objectName() == player:objectName() then
				room:setPlayerMark(player, "@falu_houtu", 0)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName()) and damage.from:objectName() == player:objectName() and damage.by_user and not damage.chain and not damage.transfer and damage.from:getMark("@falu_yuqing") > 0 and room:askForSkillInvoke(damage.from, self:objectName(), data) then
				room:setPlayerMark(damage.from, "@falu_yuqing", 0)
				room:broadcastSkillInvoke(self:objectName())

					local log = sgs.LogMessage()
					log.type = "$addDamage"
					log.from = damage.from
					if damage.card then
						log.card_str = damage.card:toString()
					else
						log.card_str = -1
					end
					log.arg = self:objectName()
					room:sendLog(log)
					damage.damage = damage.damage + 1
					data:setValue(damage)
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:hasSkill(self:objectName()) and damage.to:objectName() == player:objectName() and damage.to:getMark("@falu_gouchen") > 0 and damage.nature ~= sgs.DamageStruct_Normal
			and room:askForSkillInvoke(damage.to, self:objectName(), data) then
				room:setPlayerMark(damage.to, "@falu_gouchen", 0)
				room:broadcastSkillInvoke(self:objectName())
				local zhenyi_cards = {}
				local zhenyi_basic_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and zhenyi_basic_count < 1 then
						zhenyi_basic_count = zhenyi_basic_count + 1
						table.insert(zhenyi_cards, id)
					end
				end
				local zhenyi_trick_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and zhenyi_trick_count < 1 then
						zhenyi_trick_count = zhenyi_trick_count + 1
						table.insert(zhenyi_cards, id)
					end
				end
				local zhenyi_equip_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") and zhenyi_equip_count < 1 then
						zhenyi_equip_count = zhenyi_equip_count + 1
						table.insert(zhenyi_cards, id)
					end
				end
				
				if #zhenyi_cards > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _,id in ipairs(zhenyi_cards) do
						dummy:addSubcard(id)
					end
					room:obtainCard(damage.to, dummy, false)
				end
			end
		end
		return false
	end
}
zhangqiying:addSkill(zhenyi)
zhenyi_spade_5_judge = sgs.CreateFilterSkill{
	name = "#zhenyi_spade_5_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("zhenyi_spade_5_judge")
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("zhenyi")
		new_card:setSuit(sgs.Card_Spade)
		new_card:setNumber(5)
		new_card:setModified(true)
		return new_card
	end
}

if not sgs.Sanguosha:getSkill("#zhenyi_spade_5_judge") then skills:append(zhenyi_spade_5_judge) end

zhenyi_heart_5_judge = sgs.CreateFilterSkill{
	name = "#zhenyi_heart_5_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("zhenyi_heart_5_judge")
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("zhenyi")
		new_card:setSuit(sgs.Card_Heart)
		new_card:setNumber(5)
		new_card:setModified(true)
		return new_card
	end
}
if not sgs.Sanguosha:getSkill("#zhenyi_heart_5_judge") then skills:append(zhenyi_heart_5_judge) end
clear_zhenyi_judge_card_flag = sgs.CreateTriggerSkill{
	name = "clear_zhenyi_judge_card_flag",
	global = true,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		for _, id in sgs.qlist(move.card_ids) do
			if sgs.Sanguosha:getCard(id):hasFlag("zhenyi_spade_5_judge") then
				room:setCardFlag(sgs.Sanguosha:getCard(id), "-zhenyi_spade_5_judge")
			end
			if sgs.Sanguosha:getCard(id):hasFlag("zhenyi_heart_5_judge") then
				room:setCardFlag(sgs.Sanguosha:getCard(id), "-zhenyi_heart_5_judge")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("clear_zhenyi_judge_card_flag") then skills:append(clear_zhenyi_judge_card_flag) end

--點化
dianhua = sgs.CreatePhaseChangeSkill{
	name = "dianhua",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local num = player:getMark("@falu_ziwei") + player:getMark("@falu_houtu") + player:getMark("@falu_yuqing") + player:getMark("@falu_gouchen")
		if player:hasSkill(self:objectName()) and num > 0 and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			local cards = room:getNCards(num, false)
			room:askForGuanxing(player, cards, sgs.Room_GuanxingUpOnly)
		end
	end
}
zhangqiying:addSkill(dianhua)

sgs.LoadTranslationTable{
["#zhangqiying"] = "青黃龍母",
["zhangqiying"] = "張琪瑛",
["illustrator:zhangqiying"] = "OL",
["falu"] = "法籙",
[":falu"] = "鎖定技，當你的牌因棄置而置入棄牌堆後，若其中有：黑桃牌，你獲得一枚“紫微”；梅花牌，你獲得一枚“后土”；紅桃牌，你獲得一枚“玉清”；方塊牌，你獲得一枚“勾陳”（每種標記至多同時擁有一枚）。鎖定技，遊戲開始時，你獲得已上四種標記。",
["$falu1"] = "求法之道，以司籙籍。",
["$falu2"] = "取捨有法，方得其法。",
["zhenyi"] = "真儀",
[":zhenyi"] = "你可以在以下時機棄置相應的標記來發動以下效果：「紫微」，將任意判定結果修改為黑桃5或紅桃5；「后土」，你的回合外，將一張手牌當【桃】使用；「玉清」，當你造成傷害時，此傷害+1；「勾陳」，當你受到屬性傷害後，從牌堆中隨機獲得三種類型的牌各一張。",
["$zhenyi1"] = "不疾不徐，自愛自重。",
["$zhenyi2"] = "紫薇星辰，斗數之儀。",
["zhenyi_Spade"] = "黑桃5",
["zhenyi_Heart"] = "紅桃5",
["@zhenyi"] = "你可以將一張手牌當【桃】使用",
["~zhenyi"] = "選擇一張手牌→點擊確定",
["dianhua"] = "點化",
[":dianhua"] = "準備階段或結束階段，你可以觀看牌堆頂X張牌（X為你的“紫微”、“后土”、“玉清”、“勾陳”數量之和）。若如此做，你將這些牌以任意順序置於牌堆頂。",
["$dianhua1"] = "大道無形，點化無為。",
["$dianhua2"] = "得此點化，必得大道。",
["~zhangqiying"] = "米碎面散，我心欲絕。",
["$addDamage"] = "%from 執行“%arg”的效果，%card 的傷害值+1",
}

--衛溫諸葛直
weiwenzhugezhi = sgs.General(extension, "weiwenzhugezhi", "wu2", "4", true)
--浮海
fuhaiCard = sgs.CreateSkillCard{
	name = "fuhai",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local player_table = {}
		local next_player = source
		repeat
			next_player = next_player:getNextAlive()
			if next_player:objectName() ~= source:objectName() then
				table.insert(player_table, next_player)
			end
		until next_player:objectName() == source:objectName()
		
		local player_table_check = table.copyFrom(player_table)
		
		local choices = {}
		if #player_table > 0 then
			if player_table[1]:getMark("fuhai_target-Clear") == 0 and not player_table[1]:isKongcheng() then
				table.insert(choices, "fuhai_next")
			end
			if player_table[#player_table]:getMark("fuhai_target-Clear") == 0 and not player_table[#player_table]:isKongcheng() then
				table.insert(choices, "fuhai_previous")
			end
		end
		
		local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
		ChoiceLog(source, choice)
		if choice == "fuhai_next" then
			table.insert(player_table, source)
		elseif choice == "fuhai_previous" then
			player_table = sgs.reverse(player_table)
			table.insert(player_table, source)
		end
		
		for _, p in ipairs(player_table) do
			if p:isKongcheng() or p:getMark("fuhai_target-Clear") > 0 or source:isKongcheng() then
				break
			end
			if not p:isKongcheng() and p:getMark("fuhai_target-Clear") == 0 and not source:isKongcheng() then
				local card_source = room:askForCard(source, ".|.|.|hand!", "@fuhai-source-show", sgs.QVariant(), sgs.Card_MethodNone)
				local card_target = nil
				if card_source then
					room:showCard(source, card_source:getEffectiveId())
					card_target = room:askForCard(p, ".|.|.|hand!", "@fuhai-show", sgs.QVariant(card_source:getEffectiveId()), sgs.Card_MethodNone)
				end
				if card_source and card_target then
					room:addPlayerMark(source, "fuhai_draw_num-Clear")
					room:addPlayerMark(p, "fuhai_target-Clear")
					room:showCard(p, card_target:getEffectiveId())
					if card_source:getNumber() >= card_target:getNumber() then
						room:throwCard(card_source, source, source)
					else
						room:throwCard(card_target:getEffectiveId(), p, p)
						room:addPlayerMark(source, "fuhai-Clear")
						p:drawCards(source:getMark("fuhai_draw_num-Clear"), self:objectName())
						source:drawCards(source:getMark("fuhai_draw_num-Clear"), self:objectName())
						break
					end
				end
			end
		end
		
		if #player_table_check > 0 then
			if player_table_check[1]:getMark("fuhai_target-Clear") > 0 or player_table_check[1]:isKongcheng() then
				room:addPlayerMark(source, "fuhai_next_check-Clear")
			end
			if player_table_check[#player_table_check]:getMark("fuhai_target-Clear") > 0 or player_table_check[#player_table_check]:isKongcheng() then
				room:addPlayerMark(source, "fuhai_previous_check-Clear")
			end
		end
	end
}
fuhaiVS = sgs.CreateZeroCardViewAsSkill{
	name = "fuhai",
	view_as = function(self, cards)
		return fuhaiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and player:getMark("fuhai-Clear") == 0 and (player:getMark("fuhai_next_check-Clear") == 0 or player:getMark("fuhai_previous_check-Clear") == 0)
	end
}
fuhai = sgs.CreateTriggerSkill{
	name = "fuhai",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = fuhaiVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
			local player_table = {}
			local next_player = player
			repeat
				next_player = next_player:getNextAlive()
				if next_player:objectName() ~= player:objectName() then
					table.insert(player_table, next_player)
				end
			until next_player:objectName() == player:objectName()
			if #player_table > 0 then
				if player_table[1]:isKongcheng() then
					room:addPlayerMark(player, "fuhai_next_check-Clear")
				end
				if player_table[#player_table]:isKongcheng() then
					room:addPlayerMark(player, "fuhai_previous_check-Clear")
				end
			end
		end
		return false
	end
}
weiwenzhugezhi:addSkill(fuhai)

sgs.LoadTranslationTable{
["#weiwenzhugezhi"] = "夷洲使節",
["weiwenzhugezhi"] = "衛溫&諸葛直",
["&weiwenzhugezhi"] = "衛溫諸葛直",
["illustrator:weiwenzhugezhi"] = "秋呆呆",
["fuhai"] = "浮海",
--[":fuhai"] = "出牌階段對每名角色限一次，你可以展示一張手牌並選擇上家或下家。該角色展示一張手牌，若你的牌點數不小於其展示的牌的點數，你棄置你展示的牌，然後繼續對其上家或下家重複此流程；若你展示的牌點數小於其展示的牌的點數，則其棄置其展示的牌，然後你與其各摸X張牌（X為你此回合發動此技能選擇的角色數），且你於此階段不能再發動此技能。",
[":fuhai"] = "<font color=\"green\"><b>出牌階段對每名角色限一次，</b></font>你可以選擇上家或下家，你和該角色各展示一張手牌。若你的牌點數不小於其展示的牌的點數，你棄置你展示的牌，然後繼續對其上家或下家重複此流程；若你展示的牌點數小於其展示的牌的點數，則其棄置其展示的牌，然後你與其各摸X張牌（X為你此回合發動此技能選擇的角色數），且你於此階段不能再發動此技能。" ,
["$fuhai1"] = "宦海沉浮，生死難料！",
["$fuhai2"] = "跨海南征，波濤起浮。",
["fuhai_next"] = "下家",
["fuhai_previous"] = "上家",
["@fuhai-source-show"] = "請展示一張手牌",
["@fuhai-show"] = "請展示一張手牌",
["~weiwenzhugezhi"] = "吾皆海岱清士，豈料生死易逝。",
}
--張恭
zhanggong = sgs.General(extension, "zhanggong", "wei2", "3", true)
--遣信
qianxinbCard = sgs.CreateSkillCard{
	name = "qianxinb",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local alive_num = room:getAlivePlayers():length()
		if room:getDrawPile():length() >= alive_num then
			local choices = {}
			for i = alive_num, math.min(room:getDrawPile():length(), alive_num * self:getSubcards():length()), alive_num do
				local card_id = self:getSubcards():at(i / alive_num - 1)
				local ids = room:getNCards(i - 1, false)
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), source, sgs.Player_DrawPile)
				room:setTag("qianxinb_card_"..card_id, sgs.QVariant(true))
				room:addPlayerMark(targets[1], "qianxinb_"..targets[1]:objectName().."_"..card_id)
				room:setPlayerMark(targets[1], "@qianxinb_target", 1)
				room:returnToTopDrawPile(ids)
			end			
			--room:setPlayerMark(source, "qianxinb_drawpile", 1)
		end
		room:setPlayerMark(source, "qianxinb_drawpile", 1)
	end
}
qianxinbVS = sgs.CreateViewAsSkill{
	name = "qianxinb",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = qianxinbCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("qianxinb_drawpile") == 0
	end
}
qianxinb = sgs.CreateTriggerSkill{
	name = "qianxinb",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = qianxinbVS,
	events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			
			if player:hasSkill(self:objectName()) and change.to and change.to == sgs.Player_Play then
				if room:getDrawPile():length() < room:getAlivePlayers():length() then
					room:setPlayerMark(player, "qianxinb_drawpile", 1)
				end
			end
			
			if change.to and change.to == sgs.Player_Play then
				for _, c in sgs.list(player:getHandcards()) do
					if player:getMark("has_qianxinb_card_in_hand-Clear") > 0 then
						local log = sgs.LogMessage()
						log.type = "$qianxinb_card_in_hand"
						log.from = player
						log.arg = self:objectName()
						room:sendLog(log)
						break
					end
				end
			end
			
			for _, c in sgs.list(player:getHandcards()) do
				if change.to and change.to == sgs.Player_Discard and player:getMark("qianxinb_"..player:objectName().."_"..c:getEffectiveId()) > 0 and player:getMark("has_qianxinb_card_in_hand-Clear") > 0 then
					local log = sgs.LogMessage()
					log.type = "$qianxinb_debuff"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					
					room:setPlayerMark(player, "has_qianxinb_card_in_hand-Clear", 0)
					room:setPlayerMark(player, "@qianxinb_target", 0)
					
					local choices = {"qianxinb_maxcard"}
					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if p:isAlive() then
							if p:getHandcardNum() < 4 then
								table.insert(choices, "qianxinb_draw")
							end
							local _data = sgs.QVariant()
							_data:setValue(p)
							local choice = room:askForChoice(player, "qianxinb-draw-maxcard", table.concat(choices, "+"), _data)
							ChoiceLog(player, choice)
							if choice == "qianxinb_draw" then
								for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
									if 4 - p:getHandcardNum() > 0 then
										p:drawCards(4 - p:getHandcardNum(), self:objectName())
									end
								end
							elseif choice == "qianxinb_maxcard" then
								room:setPlayerMark(player, "qianxinb_debuff-Clear", 1)
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			
			local has_qianxinb_card = false
			for _,id in sgs.qlist(room:getDrawPile()) do
				if room:getTag("qianxinb_card_"..id):toBool() then
					has_qianxinb_card = true
				end
			end
			if has_qianxinb_card then
				room:setPlayerMark(player, "qianxinb_drawpile", 1)
			else
				room:setPlayerMark(player, "qianxinb_drawpile", 0)
			end
			
			if move.to and move.to:objectName() == player:objectName() then
				for _,id in sgs.qlist(move.card_ids) do
					if room:getTag("qianxinb_card_"..id):toBool() then
						room:setPlayerMark(player, "has_qianxinb_card_in_hand-Clear", 1)
					end
				end
			end

			--自行加入
			if move.to_place == sgs.Player_DiscardPile then
				for _,id in sgs.qlist(move.card_ids) do
					if room:getTag("qianxinb_card_"..id):toBool() then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							room:setPlayerMark(p, "qianxinb_"..p:objectName().."_"..id)
						end
					end
				end
			end

		end
		return false
	end
}

qianxinbMaxCard = sgs.CreateMaxCardsSkill{
	name = "#qianxinbCard", 
	extra_func = function(self, target)
		if target:getMark("qianxinb_debuff-Clear") > 0 then
			return -2
		end
	end
}

zhanggong:addSkill(qianxinb)
zhanggong:addSkill(qianxinbMaxCard)

--鎮行
zhenxing = sgs.CreateTriggerSkill{
	name = "zhenxing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish) or event == sgs.Damaged then
			local choice = room:askForChoice(player, "zhenxing_choose_number", "1+2+3+cancel")
			if choice ~= "cancel" then
				room:broadcastSkillInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				local ids = sgs.IntList()
				for _,id in sgs.qlist(room:getDrawPile()) do
					if ids:length() < tonumber(choice) then
						ids:append(id)
					end
				end
				--local ids = room:getNCards(tonumber(choice), false)
				local being_show_cards = {}
				for _, id in sgs.qlist(ids) do
					table.insert(being_show_cards, id)
				end
				--已下json去掉第一個角色名參數，因為原碼S_COMMAND_SHOW_ALL_CARDS會將這些牌和這個角色綁定成手牌。尤其是受到火攻的時後，只能展示這張牌，其他手牌不能展示。
				--解決方式如下，讓系統找不到這個綁定角色名，那這些牌也不會被綁定。
				--自定包其他用這方式展示牌的技能也同步修改(都是看牌)
				local json_value = {
					"",
					false,
					being_show_cards,
				}
				room:doNotify(player, sgs.CommandType.S_COMMAND_SHOW_ALL_CARDS, json.encode(json_value))
				
				local ag_ids = sgs.IntList()
				for _, id in sgs.qlist(ids) do
					ag_ids:append(id)
				end
				local spade_tables = {}
				local club_tables = {}
				local heart_tables = {}
				local diamond_tables = {}
				for _, id in sgs.qlist(ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getSuitString() == "spade" then
						table.insert(spade_tables, card:getSuitString())
					elseif card:getSuitString() == "club" then
						table.insert(club_tables, card:getSuitString())
					elseif card:getSuitString() == "heart" then
						table.insert(heart_tables, card:getSuitString())
					elseif card:getSuitString() == "diamond" then
						table.insert(diamond_tables, card:getSuitString())
					end
				end
				if #spade_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "spade" then
							ag_ids:removeOne(id)
						end
					end
				end
				if #club_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "club" then
							ag_ids:removeOne(id)
						end
					end
				end
				if #heart_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "heart" then
							ag_ids:removeOne(id)
						end
					end
				end
				if #diamond_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "diamond" then
							ag_ids:removeOne(id)
						end
					end
				end
				if not ag_ids:isEmpty() then
					room:fillAG(ag_ids, player)
					local card_id = room:askForAG(player, ag_ids, false, self:objectName())
					if card_id ~= -1 then
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
					end
					room:clearAG()
				end
			end
		end
		return false
	end
}
zhanggong:addSkill(zhenxing)

sgs.LoadTranslationTable{
["#zhanggong"] = "西域長歌",
["zhanggong"] = "張恭",
["illustrator:zhanggong"] = "B_Lee",
["qianxinb"] = "遣信",
[":qianxinb"] = "出牌階段限一次，若牌堆中沒有“信”，你可以選擇一名角色並將任意張手牌放置於牌堆中X倍數的位置（X為存活角色數），稱為“信”。該角色棄牌階段開始時，若其手牌有其本回合獲得的“信”，其選擇一項：1.令你將手牌摸至四張；2.其本回合手牌上限-2。",
["$qianxinb_card_in_hand"] = "%from 手牌中有“信” (%arg 技能)",
["$qianxinb_debuff"] = "%from 手牌中有本回合獲得的“信”且是 %arg 技能目標",
["qianxinb-draw-maxcard"] = "遣信",
["qianxinb_draw"] = "令其手牌摸至四張",
["qianxinb_maxcard"] = "本回合手牌上限-2",
["$qianxinb1"] = "兵困絕地，將至如歸！",
["$qianxinb2"] = "臨危之際，速速來援！",
["zhenxing"] = "鎮行",
[":zhenxing"] = "結束階段開始時或當你受到傷害後，你可以觀看牌堆頂至多三張牌，然後你獲得其中與其餘牌花色均不相同的一張牌。",
["zhenxing_choose_number"] = "觀看牌數量",
["$zhenxing1"] = "東征西討，募軍百里挑一。",
["$zhenxing2"] = "眾口鑠金，積毀銷骨。",
["~zhanggong"] = "大漠孤煙，孤立無援啊。",
}
--呂凱
lukai = sgs.General(extension, "lukai", "shu2", "3", true)
--圖南
tunanUseCard = sgs.CreateSkillCard{
	name = "tunanUse",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if sgs.Self:hasFlag("useAsSlash") then
			card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card:setSkillName("_tunan")
		end
		return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end, 
	feasible = function(self, targets)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if sgs.Self:hasFlag("useAsSlash") then
			card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card:setSkillName("_tunan")
		end
		return card and card:targetsFeasible(targets_list, sgs.Self)
	end,
	about_to_use = function(self, room, use)
		local _guojia = sgs.SPlayerList()
		_guojia:append(use.from)
		local move_to = sgs.CardsMoveStruct(self:getSubcards(), use.from, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
		local moves_to = sgs.CardsMoveList()
		moves_to:append(move_to)
		room:notifyMoveCards(true, moves_to, false, _guojia)
		room:notifyMoveCards(false, moves_to, false, _guojia)
		room:setPlayerFlag(use.from, "-Fake_Move")
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setCardFlag(card, "-"..self:objectName())
		local card_for_use = sgs.Sanguosha:getCard(self:getSubcards():first())
		if use.from:hasFlag("useAsSlash") then
			card_for_use = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card_for_use:addSubcard(card)
			card_for_use:setSkillName("_tunan")
		end
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card_for_use) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card_for_use, use.from, targets_list))
	end
}
tunanCard = sgs.CreateSkillCard{
	name = "tunan",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		if room:getDrawPile():length() > 0 then
			local to = targets[1]
			--local ids = room:getNCards(1, false)
			--local tunan_id = ids:first()
			local ids = sgs.IntList()
			local tunan_id = room:getDrawPile():first()
			ids:append(tunan_id)
			
			room:setCardFlag(sgs.Sanguosha:getCard(tunan_id), self:objectName())
			room:setPlayerFlag(to, "Fake_Move")
			local _guojia = sgs.SPlayerList()
			_guojia:append(to)
			local move = sgs.CardsMoveStruct(ids, nil, to, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			local choiceList = {}
			local card, choiceOne, choiceTwo = sgs.Sanguosha:getCard(tunan_id), false, false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not choiceOne and card:isAvailable(to) and not room:isProhibited(to, p, card) and card:targetFilter(sgs.PlayerList(), p, to) then
					choiceOne = true
					table.insert(choiceList, "tunan_use")
				end
				if choiceTwo then continue end
				local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
				slash:setSkillName("_tunan")
				if slash:isAvailable(to) and not room:isProhibited(to, p, slash) and slash:targetFilter(sgs.PlayerList(), p, to) then
					choiceTwo = true
					table.insert(choiceList, "tunan_slash")
				end
				slash:deleteLater()
			end
			if #choiceList > 0 then
				local choice = room:askForChoice(to, self:objectName(), table.concat(choiceList, "+"))
				ChoiceLog(to, choice)
				if choice == "tunan_use" then
					room:askForUseCard(to, "@@tunan!", "@tunan_useCard")
				else
					room:setPlayerFlag(to, "useAsSlash")
					room:askForUseCard(to, "@@tunan!", "@tunan")
					room:setPlayerFlag(to, "-useAsSlash")
				end
			else
				--room:getThread():delay(2000)
				local move_to = sgs.CardsMoveStruct(ids, to, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
				local moves_to = sgs.CardsMoveList()
				moves_to:append(move_to)
				room:notifyMoveCards(true, moves_to, false, _guojia)
				room:notifyMoveCards(false, moves_to, false, _guojia)
				room:setPlayerFlag(to, "-Fake_Move")
			end
			room:setCardFlag(sgs.Sanguosha:getCard(tunan_id), "-"..self:objectName())
		end
	end
}
tunan = sgs.CreateViewAsSkill{
	n = 1,
	name = "tunan",
	response_pattern = "@@tunan!",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@tunan!" then
			return to_select:hasFlag(self:objectName())
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@tunan!" then
			if #cards ~= 1 then return nil end
			local skillcard = tunanUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
		if #cards ~= 0 then return nil end
		return tunanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tunan")
	end
}

tunanTM = sgs.CreateTargetModSkill{
	name = "#tunanTM",
	pattern = ".",
	distance_limit_func = function(self, from, card)
		if card:hasFlag("tunan") and card:getSkillName() ~= "_tunan" then
			return 1000
		end
	end
}

lukai:addSkill(tunan)
lukai:addSkill(tunanTM)
--閉境
bijing = sgs.CreateTriggerSkill{
	name = "bijing",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Finish then
					if not player:isKongcheng() then
						local card = room:askForCard(player, ".|.|.|hand", "@bijing", data, sgs.Card_MethodNone)
						if card then
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							local log = sgs.LogMessage()
							log.type = "#InvokeSkill"
							log.from = player
							log.arg = self:objectName()
							room:sendLog(log)
							room:addPlayerMark(player, "bijing_card_id_"..card:getEffectiveId())
							room:setPlayerMark(player, "@bijing_card", 1)
						end
					end
				end
				if player:getPhase() == sgs.Player_Start then
					for _, c in sgs.list(player:getHandcards()) do
						if player:getMark("bijing_card_id_"..c:getEffectiveId()) > 0 then
							room:throwCard(c:getEffectiveId(), player, player)
						end
					end
					for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "bijing_card_id_") and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
							room:setPlayerMark(player, "@bijing_card", 0)
						end
					end
				end
			end
			
			local bijing_target
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, mark in sgs.list(p:getMarkNames()) do
					if string.find(mark, "bijing_card_id_") and p:getMark(mark) > 0 then
						bijing_target = p
					end
				end
			end
			
			if bijing_target then
				if player:getPhase() == sgs.Player_Discard then
					if player:getMark("bijing_debuff-Clear") > 0 then
						local log = sgs.LogMessage()
						log.type = "$bijing_discard"
						log.from = player
						log.to:append(bijing_target)
						room:sendLog(log)
						room:askForDiscard(player, self:objectName(), 2, 2, false, true)
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							for _, mark in sgs.list(p:getMarkNames()) do
								if string.find(mark, "bijing_card_id_") and p:getMark(mark) > 0 then
									room:setPlayerMark(p, mark, 0)
									room:setPlayerMark(p, "@bijing_card", 0)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and move.from_places:contains(sgs.Player_PlaceHand) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				for _, mark in sgs.list(player:getMarkNames()) do
					for _,id in sgs.qlist(move.card_ids) do
						if player:getMark("bijing_card_id_"..id) > 0 then
							room:addPlayerMark(room:getCurrent(), "bijing_debuff-Clear")
						end
					end
				end
			end
		end
		return false
	end
}
lukai:addSkill(bijing)

sgs.LoadTranslationTable{
["#lukai"] = "武昌烈臣",
["lukai"] = "呂凱",
["illustrator:lukai"] = "OL",
["tunan"] = "圖南",
[":tunan"] = "出牌階段限一次，你可以令一名其他角色觀看牌堆頂的一張牌，然後其選擇一項：1.使用此牌（無距離限制）；2.將此牌當【殺】使用。",
["tunan_slash"] = "將此牌當【殺】使用",
["tunan_use"] = "使用此牌（無距離限制）",
["@tunan"] = "請選擇【殺】的目標",
["~tunan"] = "選擇一張牌→選擇目標→點擊確定",
["@tunan_useCard"] = "請選擇此牌的目標",
["~tunan_useCard"] = "選擇一張牌→選擇目標→點擊確定",
["$tunan1"] = "敢問丞相，何日揮師南下？",
["$tunan2"] = "攻伐之道，一念之間。",
["bijing"] = "閉境",
[":bijing"] = "結束階段開始時，你可以令你的一張手牌於你的下回合開始之前稱為“閉境”牌。其他角色的棄牌階段開始時，若你於此回合失去過“閉境”牌，則其須棄置兩張牌。準備階段開始時，你棄置手牌中的“閉境”牌。",
["@bijing"] = "你可以令一張手牌為“閉境”牌",
["$bijing_discard"] = "因 %to 此回合失去過“閉境”牌，%from 須棄置兩張牌",
["$bijing1"] = "拒吳閉境，臣，誓保永昌！",
["$bijing2"] = "一臣無二主，可戰不可降！",
["~lukai"] = "守節不易，吾願捨身為蜀。",
}

--唐諮
sec_tangzi = sgs.General(extension, "sec_tangzi", "wei2")

--興棹
xingzhao_xunxun  = sgs.CreatePhaseChangeSkill{
	name = "xingzhao_xunxun",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			local card_ids = room:getNCards(4)
			for i = 1, 2 do
				room:fillAG(card_ids, player)
				local id = room:askForAG(player, card_ids, false, self:objectName())
				card_ids:removeOne(id)
				room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_DrawPile)
				room:clearAG()
			end
			room:askForGuanxing(player, card_ids, sgs.Room_GuanxingDownOnly)
		end
		return false
	end
}

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

sec_xingzhao = sgs.CreateTriggerSkill{
	name = "sec_xingzhao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local wounded_num = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isWounded() then
					wounded_num = wounded_num + 1
				end
			end
			if player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				equip_change_acquire_or_detach_skill(room, player, "-xingzhao_xunxun")
				if wounded_num >= 1 then
					equip_change_acquire_or_detach_skill(room, player, "xingzhao_xunxun")
					if wounded_num >= 2 then
						room:setPlayerMark(player, "sec_xingzhao_euqip_draw-Clear", 1)
						if wounded_num >= 3 then
							room:setPlayerMark(player, "sec_xingzhao_skip_discard_phase-Clear", 1)
						end
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:hasSkill(self:objectName()) and use.card and use.card:isKindOf("EquipCard") and use.from:getMark("sec_xingzhao_euqip_draw-Clear") > 0 then
				room:sendCompulsoryTriggerLog(use.from, self:objectName())
				room:notifySkillInvoked(use.from, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				use.from:drawCards(1, self:objectName())
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player:hasSkill(self:objectName()) and change.to and change.to == sgs.Player_Discard and player:getMark("sec_xingzhao_skip_discard_phase-Clear") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				player:skip(sgs.Player_Discard)
			end
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("xingzhao_xunxun") then skills:append(xingzhao_xunxun) end
sec_tangzi:addSkill(sec_xingzhao)
sec_tangzi:addRelateSkill("xingzhao_xunxun")

sgs.LoadTranslationTable{
["sec_tangzi"] = "唐諮-第二版",
["&sec_tangzi"] = "唐諮",
["#sec_tangzi"] = "工學之奇才",
["illustrator:sec_tangzi"] = "NOVART",
["sec_xingzhao"] = "興棹",
[":sec_xingzhao"] = "鎖定技，你的回合開始時，若場上受傷的角色數為：1，你本回合擁有“恂恂”；2.你本回合使用裝備牌時摸一張牌；3.你本回合跳過棄牌階段。",
["$sec_xingzhao1"] = "拿些上好的木料來。",
["$sec_xingzhao2"] = "精挑細選，方能成百年之計。",
["$xingzhao_xunxun1"] = "讓我先探他一探。",
["$xingzhao_xunxun2"] = "船也不是一天就能造出來。",
["~sec_xingzhao"] = "偷工減料，要不得呀！",
["xingzhao_xunxun"] = "恂恂",
[":xingzhao_xunxun"] = "摸牌階段開始時，你可以放棄摸牌並觀看牌堆頂的四張牌：若如此做，你獲得其中的兩張牌，然後將其餘的牌置於牌堆底。",
}

--蘇飛
sec_sufei = sgs.General(extension, "sec_sufei", "wu2")
--聯翩
sec_lianpian = sgs.CreateTriggerSkill{
	name = "sec_lianpian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecifying, sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			local invoke = false
			if not use.card:isKindOf("SkillCard") then
				for _, p in sgs.qlist(use.to) do
					if p:getMark(self:objectName()..player:objectName().."_Play") > 0 then
						invoke = true
						break
					end
				end
			end
			for _, p in sgs.qlist(use.to) do
				if use.to:contains(p) then
					room:addPlayerMark(p, self:objectName()..player:objectName().."_Play")
				end
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark(self:objectName()..player:objectName().."_Play") > 0 and not use.to:contains(p) then
					room:setPlayerMark(p, self:objectName()..player:objectName().."_Play", 0)
				end
			end
			if invoke and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and player:getMark("sec_lianpian_used_times-Clear") < 3 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, "sec_lianpian_used_times-Clear")
				room:broadcastSkillInvoke(self:objectName())
				local card_ids = room:getNCards(1, false)
				--player:drawCards(1, self:objectName())
				local move = sgs.CardsMoveStruct(card_ids, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, player:objectName(), self:objectName(), ""))
				room:moveCardsAtomic(move, false)
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(use.to) do
					if p:getMark(self:objectName()..player:objectName().."_Play") > 1 then
						players:append(p)
					end
				end
				local target = room:askForPlayerChosen(player, players, self:objectName(), "sec_lianpian-invoke", true, true)
				if target then
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:first()), player, target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""))
				end
			end
		elseif event == sgs.EventPhaseEnd then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark(self:objectName()..player:objectName().."_Play") > 0 then
					room:setPlayerMark(p, self:objectName()..player:objectName().."_Play", 0)
				end
			end
		else
			local n = 0
			if event == sgs.CardUsed then
				n = data:toCardUse().to
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if n == 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark(self:objectName()..player:objectName().."_Play") > 0 then
						room:setPlayerMark(p, self:objectName()..player:objectName().."_Play", 0)
					end
				end
			end
		end
		return false
	end
}
sec_sufei:addSkill(sec_lianpian)

sgs.LoadTranslationTable{
["sec_sufei"] = "蘇飛-第二版",
["&sec_sufei"] = "蘇飛",
["#sec_sufei"] = "與子同胞",
["illustrator:sec_sufei"] = "興遊",
["sec_lianpian"] = "聯翩",
[":sec_lianpian"] = "你於出牌階段使用牌連續指定同一名角色為目標(或之一)時，你可以摸一張牌。若如此做，你可以將此牌交給該角色。此效果每回合至多觸發三次。",
["$sec_lianpian1"] = "",
["$sec_lianpian2"] = "",
["sec_lianpian-invoke"] = "你可以將此摸牌交給其中一名角色",
["~sec_sufei"] = "",
}

--黃權
sec_huangquan = sgs.General(extension, "sec_huangquan", "shu2", "3")
--點虎
sec_dianhu = sgs.CreateTriggerSkill{
	name = "sec_dianhu",
	global = true,
	events = {sgs.GameStart, sgs.Damaged, sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and RIGHT(self, player) then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "sec_dianhu-invoke", false, true)
			if to then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(to, "@aim")
					room:addPlayerMark(to, "sec_aim"..player:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.to and damage.to:getMark("sec_aim"..damage.from:objectName()) > 0 and damage.from:isAlive() and damage.from:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(damage.from, self:objectName())
				room:notifySkillInvoked(damage.from, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				damage.from:drawCards(1, self:objectName())
			end
		elseif event == sgs.HpRecover then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark("sec_aim"..p:objectName()) > 0 and player:isAlive() then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					p:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end
}
sec_huangquan:addSkill(sec_dianhu)
--諫計
sec_jianjiUseCard = sgs.CreateSkillCard{
	name = "sec_jianjiUse",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end, 
	feasible = function(self, targets)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and card:targetsFeasible(targets_list, sgs.Self)
	end,
	about_to_use = function(self, room, use)
		--local _guojia = sgs.SPlayerList()
		--_guojia:append(use.from)
		--local move_to = sgs.CardsMoveStruct(self:getSubcards(), use.from, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
		--local moves_to = sgs.CardsMoveList()
		--moves_to:append(move_to)
		--room:notifyMoveCards(true, moves_to, false, _guojia)
		--room:notifyMoveCards(false, moves_to, false, _guojia)

		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setCardFlag(card, "-"..self:objectName())
		local card_for_use = sgs.Sanguosha:getCard(self:getSubcards():first())
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card_for_use) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card_for_use, use.from, targets_list))
	end
}

sec_jianjiCard = sgs.CreateSkillCard{
	name = "sec_jianji",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local to = targets[1]
		local card_ids = room:getNCards(1, false)
		local id = card_ids:first()
		if targets[1]:hasSkill("cunmu") then
			id = room:getDrawPile():last()
		end

		local ids = sgs.IntList()
		ids:append(id)

		room:setCardFlag(id, "sec_jianji")


		local move = sgs.CardsMoveStruct(ids, nil, to, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
		room:moveCardsAtomic(move, true)

		if sgs.Sanguosha:getCard(id):isAvailable(targets[1]) then
			--room:askForUseCard(targets[1], ""..id, "@sec_jianji")
			room:askForUseCard(targets[1], "@@sec_jianji", "@sec_jianji_useCard", -1, sgs.Card_MethodUse)
		end

		room:setCardFlag(id, "-sec_jianji")
	end
}

sec_jianji = sgs.CreateViewAsSkill{
	n = 1,
	name = "sec_jianji",
	response_pattern = "@@sec_jianji",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@sec_jianji" then
			return to_select:hasFlag(self:objectName())
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@sec_jianji" then
			if #cards ~= 1 then return nil end
			local skillcard = sec_jianjiUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
		if #cards ~= 0 then return nil end
		return sec_jianjiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sec_jianji")
	end
}

sec_huangquan:addSkill(sec_jianji)

sgs.LoadTranslationTable{
["sec_huangquan"] = "黃權-第二版",
["&sec_huangquan"] = "黃權",
["#sec_huangquan"] = "道絕殊途",
["illustrator:sec_huangquan"] = "興遊",
["sec_dianhu"] = "點虎",
[":sec_dianhu"] = "鎖定技，遊戲開始時，你指定一名其他角色。當你對該角色其造成傷害後或該角色回復體力後，你摸一張牌。",
["sec_dianhu-invoke"] = "你可以發動“點虎”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["$sec_dianhu1"] = "",
["$sec_dianhu2"] = "",
["sec_jianji"] = "諫計",
["@sec_jianji"] = "你可以發動“諫計”使用牌",
[":sec_jianji"] = "出牌階段限一次，你可以令一名其他角色摸一張牌，然後其可以使用之。",
["$sec_jianji1"] = "",
["$sec_jianji2"] = "",
["~sec_huangquan"] = "",
["@sec_jianji_useCard"] = "請選擇此牌的目標",
["~sec_jianji"] = "選擇一張牌→選擇目標→點擊確定",

["$SearchFailed"] = "牌堆無技能要找的牌",
}
--曹純
ol_caochun = sgs.General(extension, "ol_caochun", "wei2")
--繕甲
ol_shanjiaCard = sgs.CreateSkillCard{
	name = "ol_shanjia",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local invoke = true
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
				invoke = false
			end
		end
		if invoke then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			for _, cd in sgs.qlist(self:getSubcards()) do
				slash:addSubcard(cd)
			end
			slash:deleteLater()
			return slash:targetFilter(targets_list, to_select, sgs.Self)
		end
		return #targets < 0
	end,
	feasible = function(self, targets)
		local invoke = true
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
				invoke = false
			end
		end
		if invoke then
			return #targets > 0 or #targets == 0
		end
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			room:broadcastSkillInvoke(self:objectName(), 2)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		else
			room:broadcastSkillInvoke(self:objectName(), 1)
		end
	end
}
ol_shanjiaVS = sgs.CreateViewAsSkill{
	name = "ol_shanjia",
	n = 3,
	view_filter = function(self, selected, to_select)
		local x = 3 - sgs.Self:getMark("@ol_shanjia")
		return #selected < x and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		local x = 3 - sgs.Self:getMark("@ol_shanjia")
		if x == 0 then return ol_shanjiaCard:clone() end
		if #cards ~= x then return nil end
		local card = ol_shanjiaCard:clone()
		for _, cd in ipairs(cards) do
			card:addSubcard(cd)
		end
		return card
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@ol_shanjia")
	end
}
ol_shanjia = sgs.CreateTriggerSkill{
	name = "ol_shanjia",
	view_as_skill = ol_shanjiaVS,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards(3, self:objectName())
			room:askForUseCard(player, "@@ol_shanjia!", "@ol_shanjia", -1, sgs.Card_MethodNone)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and (move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceHand))
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				local i = 0
				for _,id in sgs.qlist(move.card_ids) do
					if (move.from_places:at(i) == sgs.Player_PlaceEquip or move.from_places:at(i) == sgs.Player_PlaceHand) and sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
						if player:getMark("@ol_shanjia") < 3 then
							room:addPlayerMark(player, "@ol_shanjia")
						end
					end
					i = i + 1
				end
			end
		end
		return false
	end
}
ol_shanjiaTargetMod = sgs.CreateTargetModSkill{
	name = "#ol_shanjiaTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "ol_shanjia" then
			return 1000
		end
	end,
}

ol_caochun:addSkill(ol_shanjia)
ol_caochun:addSkill(ol_shanjiaTargetMod)

sgs.LoadTranslationTable{
["ol_caochun"] = "界曹純",
["&ol_caochun"] = "曹純",
["#ol_caochun"] = "虎豹騎首",
["illustrator:ol_caochun"] = "depp",
["ol_shanjia"] = "繕甲",
[":ol_shanjia"] = "出牌階段開始時，你可以摸三張牌，然後棄置三張牌（本局遊戲你每失去過一張裝備牌，便少棄置一張），若你本次沒有棄置基本牌或錦囊牌，你可視為使用【殺】（不計入使用次數限制）。",
["@ol_shanjia"] = "請棄置若干張牌",
["~ol_shanjia"] = "選擇若干張牌（若有）→點擊確定",
["$ol_shanjia1"] = "",
["$ol_shanjia2"] = "",
["~ol_caochun"] = "",
}
--忙牙長
mangyazhang = sgs.General(extension, "mangyazhang", "qun2")
--截刀
jiedao = sgs.CreateTriggerSkill{
	name = "jiedao",
	global = true,
	events = {sgs.DamageCaused, sgs.DamageComplete, sgs.Death,sgs.TurnStart},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		--local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				if player:getMark("damaged_record-Clear") == 0 and player:getLostHp() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
					local choices = {}
					for i = player:getLostHp(), 1, -1 do
						table.insert(choices, i)
					end
					local choice = room:askForChoice(player, "jiedao_increase_num", table.concat(choices, "+"))
					local increase_damage = tonumber(choice)
					room:broadcastSkillInvoke(self:objectName())
					local log = sgs.LogMessage()
					log.type = "$jiedao_increase_damage"
					log.from = player
					if damage.card then
						log.card_str = damage.card:toString()
					else
						log.card_str = -1
					end
					log.arg = self:objectName()
					log.arg2 = increase_damage
					room:sendLog(log)
					damage.damage = damage.damage + increase_damage
					data:setValue(damage)
					room:addPlayerMark(player, "jiedao_invoke_"..increase_damage.."_-Clear")
				end
			end
		elseif event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.from and damage.to and damage.to:isAlive() then
				local increase_damage = 0
				for _, mark in sgs.list(damage.from:getMarkNames()) do
					if string.find(mark, "jiedao_invoke_") and damage.from:getMark(mark) > 0 and tonumber(mark:split("_")[3]) > 0 then
						increase_damage = mark:split("_")[3]
						room:askForDiscard(damage.from, self:objectName(), increase_damage, increase_damage, false, true)
						room:setPlayerMark(damage.from, mark, 0)
					end
				end
			end
		elseif event == sgs.Death then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, mark in sgs.list(p:getMarkNames()) do
					if string.find(mark, "jiedao_invoke_") and p:getMark(mark) > 0 then
						room:setPlayerMark(p, mark, 0)
					end
				end
			end
		end
		return false
	end
}
mangyazhang:addSkill(jiedao)

sgs.LoadTranslationTable{
["mangyazhang"] = "忙牙長",
["#mangyazhang"] = "截頭蠻鋒",
["illustrator:mangyazhang"] = "北★MAN",
["jiedao"] = "截刀",
[":jiedao"] = "當你每回合第一次造成傷害時，你可令此傷害至多+X（X為你損失的體力值）。然後若受到此傷害的角色沒有死亡，你棄置等同於此傷害加值的牌。",
["jiedao_increase_num"] = "加傷害量",
["$jiedao_increase_damage"] = "%from 執行“%arg”的效果，%card 的傷害值+%arg2",
["$jiedao1"] = "",
["$jiedao2"] = "",
["~mangyazhang"] = "",
}

--許貢
xugong = sgs.General(extension, "xugong", "wu2", 3)
--表召
biaozhao = sgs.CreateTriggerSkill{
	name = "biaozhao",
	global = true,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and player:getPile("biao"):isEmpty() then
			local id = room:askForCard(player, "..", "@biaozhao", sgs.QVariant(), sgs.Card_MethodNone)
			if id then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				player:addToPile("biao", id)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:getPile("biao"):isEmpty() and p:hasSkill(self:objectName()) then
						local biao_cards = {}
						for _, biao_id in sgs.qlist(p:getPile("biao")) do
							for _,id in sgs.qlist(move.card_ids) do
								local biao_card = sgs.Sanguosha:getCard(biao_id)
								local move_card = sgs.Sanguosha:getCard(id)
								if biao_card:getSuit() == move_card:getSuit() and biao_card:getNumber() == move_card:getNumber() then
									room:sendCompulsoryTriggerLog(p, self:objectName())
									room:notifySkillInvoked(p, self:objectName())
									--room:broadcastSkillInvoke(self:objectName())
									room:loseHp(p, 1)
									if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and move.from then
										--Player類型轉至ServerPlayer
										local move_from_player
										for _,pp in sgs.qlist(room:getAlivePlayers()) do
											if pp:objectName() == move.from:objectName() then
												move_from_player = pp
											end
										end
										room:obtainCard(move_from_player, biao_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), move.from:objectName(), self:objectName(), ""), false)
									else
										room:throwCard(biao_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", p:objectName(), self:objectName(), ""), nil)
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:hasSkill(self:objectName()) and not player:getPile("biao"):isEmpty() then
				for _, biao_id in sgs.qlist(player:getPile("biao")) do
					room:throwCard(sgs.Sanguosha:getCard(biao_id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", player:objectName(), self:objectName(), ""), nil)
				end
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "biaozhao-invoke", false, true)
				if target then
					room:broadcastSkillInvoke(self:objectName(), 1)
					if target:isWounded() then
						room:recover(target, sgs.RecoverStruct(target))
					end
					local max_handcard_num = 0
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						max_handcard_num = math.max(max_handcard_num, p:getHandcardNum())
					end
					if max_handcard_num > target:getHandcardNum() then
						target:drawCards(math.min(5, max_handcard_num - target:getHandcardNum()), self:objectName())
					end
				end
			end
		end
		return false
	end
}
xugong:addSkill(biaozhao)
--業仇
yechou = sgs.CreateTriggerSkill{
	name = "yechou",
	events = {sgs.Death, sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who and death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getLostHp() > 1 then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "yechou-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(target, "yechou_invoke")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("yechou_invoke") > 0 then
						for _, pp in sgs.qlist(room:getAllPlayers(true)) do
							if not pp:isAlive() and pp:hasSkill(self:objectName()) then
								room:sendCompulsoryTriggerLog(pp, self:objectName())
							end
						end
						room:loseHp(p, 1)
					end
				end
			end
			if change.to and change.to == sgs.Player_RoundStart and player:getMark("yechou_invoke") > 0 then
				room:setPlayerMark(player, "yechou_invoke", 0)
			end
		end
		return false
	end
}
xugong:addSkill(yechou)

sgs.LoadTranslationTable{
["xugong"] = "許貢",
["#xugong"] = "獨計擊流",
["illustrator:xugong"] = "紅字蝦",
["biaozhao"] = "表召",
[":biaozhao"] = "結束階段開始時，你可以將一張牌置於武將牌上，稱為“表”。當有一張與“表”花色點數均相同的牌進入棄牌堆時，移去“表”且你失去1點體力，若此牌是其他角色因棄置而進入棄牌堆，則改為該角色獲得“表”。準備階段開始時，若你的武將牌上有“表”，則移去“表”然後你選擇一名角色，該角色回复1點體力且將手牌摸至與全場手牌數最多的人相同（最多摸五張）。",
["@biaozhao"] = "你可以將一張牌置於武將牌上",
["biao"] = "表",
["biaozhao-invoke"] = "選擇一名角色回复1點體力且將手牌摸至與全場手牌數最多的人相同（最多摸五張）",
["$biaozhao1"] = "",
["$biaozhao2"] = "",
["yechou"] = "業仇",
[":yechou"] = "當你死亡時，你可以選擇一名已損失體力值大於1的角色。每個回合結束時，該角色失去1點體力直到其回合開始時。",
["yechou-invoke"] = "你可以發動“業仇”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["$yechou1"] = "",
["$yechou2"] = "",
["~xugong"] = "",
}
--張昌蒲
zhangchangpu = sgs.General(extension, "zhangchangpu", "wei2", 3, false)
--嚴教
function GenPermutation(a, n)
	if n == 0 then
		coroutine.yield(a)
	else
		for i = 1, n do
			a[n], a[i] = a[i], a[n]
			GenPermutation(a, n - 1)
			a[n], a[i] = a[i], a[n]
		end
	end
end

function permutation_list(a)
	local co = coroutine.create(function() GenPermutation(a, #a) end)
	return function()		--iterator
		local code, res = coroutine.resume(co)
		return res
	end
end

function Get2EqualSumPartitionTable(array)
	if type(array) ~= "table" then return nil end
	local sum = 0
	for _, c in ipairs(array) do
		sum = sum + c:getNumber()
	end
	if math.mod(sum, 2) ~= 0 then return nil end
	local set1 = {}
	local set2 = {}
	for permutation_array in permutation_list(array) do
		local leftsum = 0
		set1 = {}
		for i = 1, #permutation_array, 1 do
			leftsum = leftsum + permutation_array[i]:getNumber()
			table.insert(set1, permutation_array[i])
			local rightsum = 0
			set2 = {}
			for j = i + 1, #permutation_array, 1 do
				rightsum = rightsum + permutation_array[j]:getNumber()
				table.insert(set2, permutation_array[j])
			end
			if leftsum == rightsum and leftsum ~= sum then
				return set1, set2
			end
		end
	end
	return nil
end

yanjiaoCard = sgs.CreateSkillCard{
	name = "yanjiao",
	will_throw = false,
	filter = function(self, targets, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@yanjiao" then
			return #targets < 0
		end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@yanjiao" then
			local card_table = {}
			for _,id in sgs.qlist(self:getSubcards()) do
				table.insert(card_table, sgs.Sanguosha:getCard(id))
			end
			local invoke = false
			if Get2EqualSumPartitionTable(card_table) then
				invoke = true
			end
			return #targets == 0 and self:getSubcards():length() > 1 and invoke
		end
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@yanjiao" then
			for _,id in sgs.qlist(self:getSubcards()) do
				room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName().."_obtain")
			end
		else
			room:broadcastSkillInvoke(self:objectName())
			local increase_card_num = math.min(4, source:getMark("@xingshen_invoke"))
			local watched_num = 4 + increase_card_num
			--local ids = room:getNCards(watched_num)
			local ids = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if ids:length() < watched_num then
					ids:append(id)
				end
			end
			
			local being_show_cards = {}
			for _, id in sgs.qlist(ids) do
				table.insert(being_show_cards, id)
			end
			local json_value = {
				"",
				false,
				being_show_cards,
			}
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= targets[1]:objectName() then
					room:doNotify(p, sgs.CommandType.S_COMMAND_SHOW_ALL_CARDS, json.encode(json_value))
				end
			end
			
			room:setPlayerFlag(targets[1], "Fake_Move")
			local _guojia = sgs.SPlayerList()
			_guojia:append(targets[1])
			local move = sgs.CardsMoveStruct(ids, nil, targets[1], sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			
			for _, id in sgs.qlist(ids) do
				room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
			end
			room:askForUseCard(targets[1], "@yanjiao", "@yanjiao")
			for _, id in sgs.qlist(ids) do
				room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName())
			end
			
			local move_to = sgs.CardsMoveStruct(ids, targets[1], nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
			local moves_to = sgs.CardsMoveList()
			moves_to:append(move_to)
			room:notifyMoveCards(true, moves_to, false, _guojia)
			room:notifyMoveCards(false, moves_to, false, _guojia)
			room:setPlayerFlag(targets[1], "-Fake_Move")
			
			local card_table = {}
			for _, id in sgs.qlist(ids) do
				if sgs.Sanguosha:getCard(id):hasFlag(self:objectName().."_obtain") then
					table.insert(card_table, sgs.Sanguosha:getCard(id))
				end
			end
			if #card_table > 0 and Get2EqualSumPartitionTable(card_table) then
				local set1, set2 = Get2EqualSumPartitionTable(card_table)
				local dummy1 = sgs.Sanguosha:cloneCard("slash")
				for _, c in ipairs(set1) do
					dummy1:addSubcard(c:getEffectiveId())
				end
				local dummy2 = sgs.Sanguosha:cloneCard("slash")
				for _, c in ipairs(set2) do
					dummy2:addSubcard(c:getEffectiveId())
				end
				
				local ag_ids = sgs.IntList()
				for _, c in ipairs(card_table) do
					ag_ids:append(c:getEffectiveId())
				end
				local obtain_yanjiao_set1 = false
				local obtain_yanjiao_set2 = false
				room:fillAG(ag_ids, targets[1])
				for i = 1, #card_table do
					local id = room:askForAG(targets[1], ag_ids, false, self:objectName())
					if id ~= -1 then
						ag_ids:removeOne(id)
						room:takeAG(targets[1], id, false)
						for _, c in ipairs(set1) do
							if c:getEffectiveId() == id then
								obtain_yanjiao_set1 = true
								break
							end
						end
						for _, c in ipairs(set2) do
							if c:getEffectiveId() == id then
								obtain_yanjiao_set2 = true
								break
							end
						end
						if obtain_yanjiao_set1 or obtain_yanjiao_set2 then break end
					end
					if ag_ids:isEmpty() then break end
				end
				room:clearAG()
				if obtain_yanjiao_set1 then
					room:obtainCard(targets[1], dummy1, true)
					room:obtainCard(source, dummy2, true)
				elseif obtain_yanjiao_set2 then
					room:obtainCard(source, dummy1, true)
					room:obtainCard(targets[1], dummy2, true)
				end
			end
			
			local dummy3 = sgs.Sanguosha:cloneCard("slash")
			for _, id in sgs.qlist(ids) do
				if not sgs.Sanguosha:getCard(id):hasFlag(self:objectName().."_obtain") then
					dummy3:addSubcard(id)
				end
			end
			if dummy3:subcardsLength() > 0 then
				room:throwCard(dummy3, nil, source)
			end
			if dummy3:subcardsLength() > 1 then
				room:addPlayerMark(source, "yanjiao_max_card-Clear")
			end
			
			for _, id in sgs.qlist(ids) do
				if sgs.Sanguosha:getCard(id):hasFlag(self:objectName().."_obtain") then
					room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName().."_obtain")
				end
			end
			--以下移至最後面給AI抓資料
			room:setPlayerMark(source, "@xingshen_invoke", 0)
		end
	end
}

yanjiao = sgs.CreateViewAsSkill{
	name = "yanjiao",
	n = 999,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@yanjiao" then
			return to_select:hasFlag(self:objectName())
		end
		return true
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@yanjiao" then
			local skillcard = yanjiaoCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			return skillcard
		else
			if #cards ~= 0 then return nil end
			return yanjiaoCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#yanjiao")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@yanjiao"
	end
}

yanjiaoMaxCard = sgs.CreateMaxCardsSkill{
	name = "#yanjiaoCard", 
	extra_func = function(self, target)
		if target:getMark("yanjiao_max_card-Clear") > 0 then
			return -1
		end
	end
}


zhangchangpu:addSkill(yanjiao)
zhangchangpu:addSkill(yanjiaoMaxCard)

--省身
xingshen = sgs.CreateTriggerSkill{
	name = "xingshen",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local min_card_num = 1000
		local min_hp_num = 1000
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			min_card_num = math.min(min_card_num, p:getHandcardNum())
			min_hp_num = math.min(min_hp_num, p:getHp())
		end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			if player:getHandcardNum() == min_card_num then
				player:drawCards(2, self:objectName())
			else
				player:drawCards(1, self:objectName())
			end
			if player:getHp() == min_hp_num then
				room:addPlayerMark(player, "@xingshen_invoke", 2)
			else
				room:addPlayerMark(player, "@xingshen_invoke")
			end
		end
		return false
	end
}
zhangchangpu:addSkill(xingshen)

sgs.LoadTranslationTable{
["zhangchangpu"] = "張昌蒲",
["#zhangchangpu"] = "矜嚴明訓",
["illustrator:zhangchangpu"] = "biou09",
["yanjiao"] = "嚴教",
[":yanjiao"] = "出牌階段限一次，你可以選擇一名其他角色。從牌堆頂亮出四張牌，該角色將這些牌分成點數之和相等的兩組，你與其各獲得其中一組，然後將剩餘未分組的牌置入棄牌堆。若未分組的牌超過一張，你本回合手牌上限-1。",
["@yanjiao"] = "你可以發動“嚴教”",
["~yanjiao"] = "選擇可分成兩組點數之和相等之若干張牌(兩組一起選)→點擊確定",
["$yanjiao1"] = "",
["$yanjiao2"] = "",
["xingshen"] = "省身",
[":xingshen"] = "當你受到傷害後，你可以摸一張牌且下一次發動“嚴教”亮出的牌數+1。若你的手牌數為全場最少，則改為摸兩張牌；若你的體力值為全場最少，則“嚴教”亮出的牌數改為+2（總數不能超過4）",
["$xingshen1"] = "",
["$xingshen2"] = "",
["~zhangchangpu"] = "",
}

--伊籍
spyiji = sgs.General(extension, "spyiji", "shu2", 3, true)
jijieCard = sgs.CreateSkillCard{
	name = "jijie",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if room:getDrawPile():length() > 0 then
			local id = room:getDrawPile():last()
			local being_show_cards = {}
			table.insert(being_show_cards, id)
			local json_value = {
				"",
				false,
				being_show_cards,
			}
			room:doNotify(source, sgs.CommandType.S_COMMAND_SHOW_ALL_CARDS, json.encode(json_value))
			local target = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), "jijie-invoke", false, true)
			if target then
				room:moveCardTo(sgs.Sanguosha:getCard(id), source, target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), self:objectName(), ""))
				--room:obtainCard(target, id, false)
			end
		end
	end
}
jijie = sgs.CreateZeroCardViewAsSkill{
	name = "jijie",
	view_as = function(self, cards)
		return jijieCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#jijie")
	end
}
spyiji:addSkill(jijie)

jiyuan = sgs.CreateTriggerSkill{
	name = "jiyuan",
	events = {sgs.EnterDying, sgs.CardsMoveOneTime},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:getCurrentDyingPlayer():drawCards(1)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			
			--[[
			if move.from and move.from:hasSkill(self:objectName()) and move.from:objectName() == player:objectName() and move.to and move.to:objectName() ~= player:objectName()
			and move.reason.m_reason == sgs.CardMoveReason_S_REASON_GIVE then
			]]--
			
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) and move.reason.m_reason == sgs.CardMoveReason_S_REASON_GIVE
			then
				--Player類型轉至ServerPlayer
				local move_from
				local move_to
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() == move.from:objectName() then
						move_from = p
					end
					if p:objectName() == move.to:objectName() then
						move_to = p
					end
				end
				
				if room:askForSkillInvoke(move_from, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					move_to:drawCards(1)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
spyiji:addSkill(jiyuan)

sgs.LoadTranslationTable{
	["spyiji"] = "伊籍",
	["#spyiji"] = "禮人同渡",
	["illustrator:spyiji"] = "DH",
	["jijie"] = "機捷",
	[":jijie"] = "出牌階段限一次，你可以觀看牌堆底的一張牌，然後交給任意名角色。",
	["$jijie1"] = "",
	["$jijie2"] = "",
	["jijie-invoke"] = "選擇一名角色獲得此牌<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	["jiyuan"] = "急援",
	[":jiyuan"] = "當一名角色進入瀕死狀態或你交給一名其他角色牌時，你可令該角色摸一張牌。",
	["$jiyuan1"] = "",
	["$jiyuan2"] = "",
	["~spyiji"] = "",
}

--蔣幹
jianggan = sgs.General(extension, "jianggan", "wei2", "3", true)
--偽誠：你交給其他角色手牌，或你的手牌被其他角色獲得後，若你的手牌數小於當前體力值，則你摸一張牌。
weicheng = sgs.CreateTriggerSkill{
	name = "weicheng",
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() 
					and (move.from_places:contains(sgs.Player_PlaceHand))
					and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)
					and move.to then		
				if player:getHandcardNum() < player:getHp() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:notifySkillInvoked(player, "weicheng")
						room:broadcastSkillInvoke("weicheng")
						room:drawCards(player, 1, "weicheng")
					end
				end
			end				
		end
	end,
}

--盜書：出牌階段限一次，你可以選擇一名角色並選擇一種花色，然後獲得該角色一張手牌。若此牌與你選擇的花色相同，你對其造成1點傷害且此技能視為未發動過；若花色不同，則你交給該角色一張其他花色的手牌（若沒有需展示所有手牌）
daoshuCard = sgs.CreateSkillCard{
	name = "daoshu",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end, 
	on_effect = function(self, effect)
		local zhouyu = effect.from
		local target = effect.to
		local room = zhouyu:getRoom()
		local card_id = target:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(card_id)
		local suit = room:askForSuit(zhouyu, "nos_fanjian")
		room:getThread():delay()
		zhouyu:obtainCard(card)
		room:showCard(zhouyu, card_id)
		if card:getSuit() == suit then
			room:damage(sgs.DamageStruct("daoshu", zhouyu, target))
			room:addPlayerHistory(zhouyu, "#daoshu",-1)
		else
			local pattern = ".|"
			if suit ~= sgs.Card_Spade then
				pattern = pattern.."spade,"
			end
			if suit ~= sgs.Card_Heart then
				pattern = pattern.."heart,"
			end
			if suit ~= sgs.Card_Club then
				pattern = pattern.."club,"
			end
			if suit ~= sgs.Card_Diamond then
				pattern = pattern.."diamond,"
			end
			pattern = pattern.."|.|hand"

			local suitstring = card:getSuitString()	
			local id = room:askForCard(zhouyu, pattern , "@daoshu-give:"..target:objectName(),sgs.QVariant(suitstring), sgs.Card_MethodNone)
			if id then						
				room:obtainCard(target, id, true)
			else
				local DPHeart = sgs.IntList()
				if not zhouyu:isKongcheng() then
					for _, cd in sgs.qlist(zhouyu:getHandcards()) do
						if card:getSuit() ~= cd:getSuit() then
							DPHeart:append(cd:getId())
						end
					end
				end
				if DPHeart:length() ~= 0 then
					local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
					local get_card = sgs.Sanguosha:getCard(get_id)
					room:obtainCard(target, get_card)
				else
					room:showAllCards(zhouyu)	
				end
			end
		end
	end
}
daoshu = sgs.CreateZeroCardViewAsSkill{
	name = "daoshu",
	
	view_as = function()
		return daoshuCard:clone()
	end,

	enabled_at_play = function(self, player)
		return (not player:hasUsed("#daoshu"))
	end
}

jianggan:addSkill(weicheng)
jianggan:addSkill(daoshu)

sgs.LoadTranslationTable{
	["jianggan"] = "蔣幹",
	["#jianggan"] = "",
	["weicheng"] = "偽誠",
	[":weicheng"] = "你交給其他角色手牌，或你的手牌被其他角色獲得後，若你的手牌數小於當前體力值，則你摸一張牌。",
	["daoshu"] = "盜書",
	[":daoshu"] = "出牌階段限一次，你可以選擇一名角色並選擇一種花色，然後獲得該角色一張手牌。若此牌與你選擇的花色相同，你對其造成1點傷害且此技能視為未發動過；若花色不同，則你交給該角色一張其他花色的手牌（若沒有需展示所有手牌）。",
	["@daoshu-give"] = "請交給 %src 一張其他花色的手牌",
}

--文鴦
wenyang = sgs.General(extension, "wenyang", "wei2",5,true)

--膂力：每回合限一次，當你造成傷害後，你可以將手牌摸至與體力值相同或將體力回復至與手牌數相同。
lvli = sgs.CreateTriggerSkill{
	name = "lvli", 
	events = {sgs.Damage,sgs.Damaged}, 
	on_trigger = function(self, event, player, data, room) 
		if ((event == sgs.Damage and player:getMark("lvli_Play") == 0 and player:getMark("lvli") == 0)
				 or (event == sgs.Damage and player:getMark("lvli_Play") < 2 and player:getMark("lvli") == 1) 
				 or (player:getMark("lvli_Play") < 2 and player:getMark("lvli") == 2)) and (player:getHandcardNum() ~= player:getHp()) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				if player:getHandcardNum() < player:getHp() then
					room:setPlayerMark(player, "lvli_Play", player:getMark("lvli_Play") + 1)
					local n = player:getHp() - player:getHandcardNum()
					player:drawCards(n)
				elseif player:getHandcardNum() > player:getHp() then
					room:setPlayerMark(player, "lvli_Play", player:getMark("lvli_Play") + 1)
					local n = player:getHandcardNum() - player:getHp()
					room:recover(player, sgs.RecoverStruct(player, nil, n))
				end
			end
		end
	end,
}

lvli_clear = sgs.CreateTriggerSkill{
	name = "#lvli_clear",  
	events = {sgs.TurnStart}, 
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("lvli") then
				room:setPlayerMark(p, "lvli_Play", 0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil and target:isAlive()
	end
}
wenyang:addSkill(lvli)
wenyang:addSkill(lvli_clear)

extension:insertRelatedSkills("lvli", "#lvli_clear")

--仇決：覺醒技，每個回合結束時，若你的手牌數和體力值相差3或更多，你減1點體力上限並獲得技能“背水”，然後“膂力”改為“在自己的回合時每回合限兩次”。
choujue = sgs.CreatePhaseChangeSkill{
	name = "choujue",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if (math.abs(player:getHandcardNum() - player:getHp()) >= 3) or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			if room:changeMaxHpForAwakenSkill(player) then
				if (math.abs(player:getHandcardNum() - player:getHp()) >= 3) then
					local msg = sgs.LogMessage()
					msg.type = "#ChoujueWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = math.abs(player:getHandcardNum() - player:getHp())
					msg.arg2 = self:objectName()
					room:sendLog(msg)
				end
				room:broadcastSkillInvoke("choujue")
				room:setPlayerMark(player, self:objectName(), 1)
				room:doSuperLightbox("wenyang","choujue")	
				room:acquireSkill(player, "beishui")
				room:setPlayerMark(player, "lvli", 1)
				sgs.Sanguosha:addTranslationEntry(":lvli", ""..string.gsub(sgs.Sanguosha:translate(":lvli"), sgs.Sanguosha:translate(":lvli"), sgs.Sanguosha:translate(":lvli1")))
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish 
		and target:getMark(self:objectName()) == 0 
	end
}
wenyang:addSkill(choujue)
--背水：覺醒技，準備階段，若你的手牌數或體力值小於2，你減1點體力上限並獲得技能“清剿”，然後“膂力”改為受到傷害後也可發動。
beishui = sgs.CreateTriggerSkill{
	name = "beishui",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getHandcardNum() < 2 or player:getHp() < 2) or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:addPlayerMark(player, "beishui")
			if room:changeMaxHpForAwakenSkill(player) then
				room:broadcastSkillInvoke(self:objectName())
				if (math.abs(player:getHandcardNum() - player:getHp()) >= 3) then
					local msg = sgs.LogMessage()
					msg.type = "#BeishuiWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = self:objectName()
					room:sendLog(msg)
				end
				room:doSuperLightbox("wenyang","beishui")
	
				room:acquireSkill(player, "qingjiao")
				room:setPlayerMark(player, "lvli", 2)
				sgs.Sanguosha:addTranslationEntry(":lvli", ""..string.gsub(sgs.Sanguosha:translate(":lvli"), sgs.Sanguosha:translate(":lvli"), sgs.Sanguosha:translate(":lvli2")))
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("beishui")
				and target:isAlive()
				and (target:getMark("beishui") == 0)
	end
}

if not sgs.Sanguosha:getSkill("beishui") then skills:append(beishui) end
wenyang:addRelateSkill("beishui")
--清剿：出牌階段開始時，你可以棄置所有手牌，然後從牌堆或棄牌堆中隨機獲得八張牌名各不相同且副類別不同的牌。若如此做，結束階段，你棄置所有牌。

function TrueName(card)
	if card == nil then return "" end
	if (card:objectName() == "fire_slash" or card:objectName() == "thunder_slash") then return "slash" end
	return card:objectName()
end

qingjiao = sgs.CreateTriggerSkill{
	name = "qingjiao" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, "qingjiao", data) then
				room:setPlayerFlag(player, "use_qingjiao")
				room:notifySkillInvoked(player,"qingjiao")
				room:broadcastSkillInvoke("qingjiao")
				room:throwCard(player:wholeHandCards(),player,player)
				local GetCardList = sgs.IntList()
				local get_pattern = {}
				for i = 1,8,1 do
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if not table.contains(get_pattern, TrueName(card)) then
								DPHeart:append(id)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
						GetCardList:append(get_id)

						local card = sgs.Sanguosha:getCard(get_id)
						table.insert(get_pattern, TrueName(card))
					end
				end
				if GetCardList:length() ~= 0 then
					local move = sgs.CardsMoveStruct()
					move.card_ids = GetCardList
					move.to = player
					move.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(move, true)
				end
			end	
		elseif player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("use_qingjiao") then
				player:throwAllHandCardsAndEquips()
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("qingjiao") then skills:append(qingjiao) end
wenyang:addRelateSkill("qingjiao")

sgs.LoadTranslationTable{
	["wenyang"] = "文鴦",
	["lvli"] = "膂力",
	[":lvli"] = "每回合限一次，當你造成傷害後，你可以將手牌摸至與體力值相同或將體力回復至與手牌數相同。",
	[":lvli1"] = "每回合限兩次，當你造成傷害後，你可以將手牌摸至與體力值相同或將體力回復至與手牌數相同。",
	[":lvli2"] = "每回合限一次，當你造成傷害或受到傷害後，你可以將手牌摸至與體力值相同或將體力回復至與手牌數相同。",
	["choujue"] = "仇決",
	[":choujue"] = "覺醒技，每個回合結束時，若你的手牌數和體力值相差3或更多，你減1點體力上限並獲得技能“背水”，然後“膂力”改為“在自己的回合時每回合限兩次”。",
	["beishui"] = "背水",
	[":beishui"] = "覺醒技，準備階段，若你的手牌數或體力值小於2，你減1點體力上限並獲得技能“清剿”，然後“膂力”改為受到傷害後也可發動。",
	["qingjiao"] = "清剿",
	[":qingjiao"] = "出牌階段開始時，你可以棄置所有手牌，然後從牌堆或棄牌堆中隨機獲得八張牌名各不相同且副類別不同的牌。若如此做，結束階段，你棄置所有牌。",
	["#ChoujueWake"] = "%from 手牌數與體力值相差 %arg ，觸發“%arg2”覺醒",
	["#BeishuiWake"] = "%from 手牌數小於2，觸發“%arg”覺醒",
}

--管輅 魏 3 男 問天通神
guanlu = sgs.General(extension, "guanlu", "wei2",3,true)
--【推演】 出牌階段開始時，你可以觀看牌堆頂的兩張牌。
tuiyan = sgs.CreateTriggerSkill{
	name = "tuiyan" ,
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, "tuiyan", data) then
				local ids = room:getNCards(3)
				room:fillAG(ids)
				room:getThread():delay()
				room:clearAG()
				room:returnToTopDrawPile(ids)
			end	
		end
	end
}
--【卜算】 出牌階段限一次，你可以選擇一名其他角色，然後選擇至多兩張不同的卡牌名稱（限基本牌或錦囊牌）。該角色下次摸牌階段摸牌時，
--改為從牌堆或棄牌堆中獲得你選擇的牌。
busuanCard = sgs.CreateSkillCard{
	name = "busuan",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		room:setPlayerFlag(tiger,"busuan_target")
		local choices = {"slash","fire_slash","thunder_slash","jink","peach","analeptic","duel",
				 "fire_attack","savage_assault","archery_attack","dismantlement","snatch","god_salvation",
				 "amazing_grace","iron_chain","collateral","ex_nihilo","nullification","indulgence"
				 ,"supply_shortage","lightning"}
		local choice = room:askForChoice(source, "busuan", table.concat(choices, "+"))
		room:setPlayerMark(tiger, "busuan"..choice, 1)
		table.removeOne(choices,choice)
		table.insert(choices,"cancel")
		local choice = room:askForChoice(source, "busuan", table.concat(choices, "+"))
		if choice ~= "cancel" then
			room:setPlayerMark(tiger, "busuan"..choice, 1)
		end
		room:setPlayerFlag(tiger,"-busuan_target")
	end
}
busuan = sgs.CreateZeroCardViewAsSkill{
	name = "busuan",
	view_as = function(self, cards) 
		return busuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#busuan")) 
	end, 
}
busuanStart = sgs.CreateTriggerSkill{
	name = "#busuanStart" ,
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.DrawNCards} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "busuan") and player:getMark(mark) > 0 then
					local count = 0
					data:setValue(count)
				end
			end
			local GetCardList = sgs.IntList()
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "busuan") and player:getMark(mark) > 0 then
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if "busuan"..card:objectName() == mark then
								DPHeart:append(id)
							end
						end
					end
					if room:getDiscardPile():length() > 0 then
						for _, id in sgs.qlist(room:getDiscardPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if "busuan"..card:objectName() == mark then
								DPHeart:append(id)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
						GetCardList:append(get_id)
						local card = sgs.Sanguosha:getCard(get_id)
					end
					room:setPlayerMark(player, mark, 0)
				end
			end
			if GetCardList:length() ~= 0 then
				local move = sgs.CardsMoveStruct()
				move.card_ids = GetCardList
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
			end
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("#busuanStart") then skills:append(busuanStart) end
--【命戒】 結束階段，你可以摸一張牌，若此牌為紅色，你可以重複此流程直到摸到黑色牌或摸到第三張牌
--。當你以此法摸到黑色牌時，你失去1點體力。
mingjie = sgs.CreateTriggerSkill{
	name = "mingjie" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			for i = 1,3,1 do
				if room:askForSkillInvoke(player, "mingjie", data) then
					local drawpile=room:getDrawPile()
					drawpile=sgs.QList2Table(drawpile)
					local id=drawpile[1]
					local card = sgs.Sanguosha:getCard(id)
					room:obtainCard(player,card)
					if card:isRed() then

					else
						if player:getHp()> 1 then
							room:loseHp(player,1)
						end
						break
					end
				else
					break
				end
			end	
		end
	end
}
guanlu:addSkill(tuiyan)
guanlu:addSkill(busuan)
guanlu:addSkill(mingjie)

sgs.LoadTranslationTable{
	["guanlu"] = "管輅",
	["tuiyan"] = "推演",
	[":tuiyan"] = "出牌階段開始時，你可以觀看牌堆頂的兩張牌。",
	["busuan"] = "卜算",
	[":busuan"] = "出牌階段限一次，你可以選擇一名其他角色，然後選擇至多兩張不同的卡牌名稱（限基本牌或錦囊"..
	"牌）。該角色下次摸牌階段摸牌時，改為從牌堆或棄牌堆中獲得你選擇的牌。",
	["mingjie"] = "命戒",
	[":mingjie"] = "結束階段，你可以摸一張牌，若此牌為紅色，你可以重複此流程直到摸到黑色牌或摸到第三張牌"..
	"。當你以此法摸到黑色牌時，若你的體力值大於1，你失去1點體力。",
}

--葛玄 吳 3 男 太極仙翁
--gexuan lianhua danxie zhafu
gexuan = sgs.General(extension, "gexuan", "wu2",3,true)
--【煉化】 你的回合外，每當有其他角色受到傷害後，你獲得一個“丹血”標記（該角色與你陣營一致為紅色，不一致為黑色，
--此顏色對玩家不可見）直到你的準備階段開始。準備階段，根據你獲得的“丹血”標記的數量和顏色，你獲得相應的遊戲牌以及獲得相應
--技能直到回合結束。 3枚或以下：“英姿”和【桃】；超過3枚且紅色“丹血”較多：“觀星”和【無中生有】；超過3枚且黑色“丹血”較多
--：“直言”和【順手牽羊】；超過3枚且紅色和黑色一樣多：【殺】、【決鬥】和“攻心”。

function isSameTeam(p,q)
	if (p:getRole() == "rebel") and (q:getRole() == "rebel") then
		return true
	elseif (p:getRole() == "renegade") and (q:getRole() == "renegade") then
		return true
	elseif ((p:getRole() == "loyalist") or (p:getRole() == "lord")) and 
		((q:getRole() == "loyalist") or (q:getRole() == "lord")) then
		return true
	else
		return false
	end
end

lianhua_Damage = sgs.CreateTriggerSkill{
	name = "#lianhua_Damage",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getPhase() == sgs.Player_NotActive and p:hasSkill("lianhua") then
					if isSameTeam(player,p) then
						p:gainMark("@danxie")
						room:setPlayerMark(p,"danxie_red",player:getMark("danxie_red")+1)
					else
						p:gainMark("@danxie")
						room:setPlayerMark(p,"danxie_black",player:getMark("danxie_black")+1)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}



lianhua = sgs.CreateTriggerSkill{
	name = "lianhua",
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if player:getMark("@danxie") <= 3 then
					if not player:hasSkill("yingzi") then
						room:setPlayerMark(player,"danxie_skill",1)
						room:acquireSkill(player,"yingzi")
					end
					getpatterncard_for_each_pattern(player,{"Peach"},true,true)
				elseif player:getMark("danxie_red") > player:getMark("danxie_black") then
					if not player:hasSkill("guanxing") then
						room:acquireSkill(player,"guanxing")
						getpatterncard_for_each_pattern(player,{"ExNihilo"},true,true)
					end
					room:setPlayerMark(player,"danxie_skill",2)
				elseif player:getMark("danxie_red") < player:getMark("danxie_black") then
					if not player:hasSkill("zhiyan") then
						room:acquireSkill(player,"zhiyan")
						room:setPlayerMark(player,"danxie_skill",3)
					end
					getpatterncard_for_each_pattern(player,{"Snatch"},true,true)
				else
					if not player:hasSkill("gongxin") then
						room:acquireSkill(player,"gongxin")
						room:setPlayerMark(player,"danxie_skill",4)
					end
					getpatterncard_for_each_pattern(player, {"Slash","Duel"},true,true)
				end
				room:setPlayerMark(player,"@danxie",0)
				room:setPlayerMark(player,"danxie_red",0)
				room:setPlayerMark(player,"danxie_black",0)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_NotActive then
				if player:getMark("danxie_skill") == 1 then
					room:detachSkillFromPlayer(player, "yingzi")
				elseif player:getMark("danxie_skill") == 2 then
					room:detachSkillFromPlayer(player, "guanxing")
				elseif player:getMark("danxie_skill") == 3 then
					room:detachSkillFromPlayer(player, "zhiyan")
				elseif player:getMark("danxie_skill") == 4 then
					room:detachSkillFromPlayer(player, "gongxin")
				end
				room:setPlayerMark(player,"danxie_skill",0)
			end
		end
	end
}

--【札符】 限定技，出牌階段，你可以選擇一名其他角色。該角色的下一個棄牌階段開始時，其選擇保留一張手牌，然後將其餘的手牌交給你。
zhafuCard = sgs.CreateSkillCard{
	name = "zhafu",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("gexuan","zhafu")
		room:removePlayerMark(source, "@zhafu")
		local tiger = targets[1]
		room:setPlayerMark(tiger, "zhafu"..source:objectName()..tiger:objectName(), 1)
	end
}
zhafuVS = sgs.CreateZeroCardViewAsSkill{
	name = "zhafu",
	view_as = function(self, cards) 
		return zhafuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@zhafu") > 0
	end, 
}

zhafu = sgs.CreateTriggerSkill{
		name = "zhafu",
		frequency = sgs.Skill_Limited,
		limit_mark = "@zhafu",
		view_as_skill = zhafuVS ,
		on_trigger = function() 
		end
}

zhafuStart = sgs.CreateTriggerSkill{
	name = "#zhafuStart" ,
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("zhafu"..p:objectName()..player:objectName()) > 0 then
						local n1 = player:getHandcardNum()
						local n2 = 1
						room:sendCompulsoryTriggerLog(p, "zhafu") --這句話表示XX被觸發
						if (n1-n2) > 0 then
							local prompt1 = string.format("zhafugive:%s", p:objectName())
							local to_exchange = room:askForExchange(player, "zhafu", (n1-n2), (n1-n2), false, prompt1)
							room:moveCardTo(to_exchange, p,sgs.Player_PlaceHand, false)
							room:setPlayerMark(player, "zhafu"..p:objectName()..player:objectName(), 0)
							room:getThread():delay()
						end
					end
				end
			end
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("#zhafuStart") then skills:append(zhafuStart) end
gexuan:addSkill(lianhua)
gexuan:addSkill(lianhua_Damage)
gexuan:addSkill(zhafu)
extension:insertRelatedSkills("lianhua", "#lianhua_Damage")

sgs.LoadTranslationTable{
	["gexuan"] = "葛玄",
	["lianhua"] = "煉化",
	[":lianhua"] = "你的回合外，每當有其他角色受到傷害後，你獲得一個“丹血”標記（該角色與你陣營一致為紅色，"..
	"不一致為黑色，此顏色對玩家不可見）直到你的準備階段開始。準備階段，根據你獲得的“丹血”標記的數量和顏色，"..
	"你獲得相應的遊戲牌以及獲得相應技能直到回合結束。 3枚或以下：“英姿”和【桃】；超過3枚且紅色“丹血”較多："..
	"“觀星”和【無中生有】；超過3枚且黑色“丹血”較多:“直言”和【順手牽羊】；超過3枚且紅色和黑色一樣多："..
	"【殺】、【決鬥】和“攻心”。",
	["@danxie"] = "丹血",
	["zhafu"] = "札符",
	[":zhafu"] = "限定技，出牌階段，你可以選擇一名其他角色。該角色的下一個棄牌階段開始時，其"..
	"選擇保留一張手牌，然後將其餘的手牌交給你。",
	["zhafugive"] = "請交给該角色（%src）超過體力值數量的手牌",
}

--辛毗 勢力:魏 體力:3 性別:男 稱號:一節肅六軍
xinpi = sgs.General(extension, "xinpi", "wei2",3,true)
--持節:每個回合限一次，當你成為其他角色使用牌的目標後，若此牌對你造成傷害，你可以防止此牌對其他角色造成傷害；若此牌沒有對任何角色造成傷害，你獲得之。
chijie = sgs.CreateTriggerSkill{
	name = "chijie",
	events = {sgs.EventPhaseStart,sgs.CardFinished,sgs.Damaged,sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then				
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("chijie") then
						room:setPlayerMark(p,"chijie_used",0)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.to:length() > 0 and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				for _,p in sgs.qlist(use.to) do
					if p:hasSkill("chijie") and p:getMark("chijie_used") == 0 and (not use.card:hasFlag("chijie_hasdamagecard")) and (p:objectName() ~= use.from:objectName()) then
						if room:askForSkillInvoke(p, "chijie1", data) then
							room:setPlayerMark(p,"chijie_used",1)
							p:obtainCard(use.card)
						end
					end
				end
			end
			room:setCardFlag(use.card, "-chijie_hasdamagecard")
			room:setCardFlag(use.card, "-chijie_invokecard")
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card then
				room:setCardFlag(damage.card, "chijie_hasdamagecard")
				if player:hasSkill("chijie") and player:getMark("chijie_used") == 0 then
					if room:askForSkillInvoke(player, "chijie2", data) then
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerMark(player,"chijie_used",1)
						room:setCardFlag(damage.card, "chijie_invokecard")
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card:hasFlag("chijie_invokecard") then
				room:notifySkillInvoked(player, "chijie")
				room:broadcastSkillInvoke("chijie")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = "normal_nature"
				room:sendLog(msg)
				return true
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}
--引裾:限定技，出牌階段，指定一名其他角色。直到你的回合結束，防止你對其造成的傷害並改為令其回復等量的體力，且你使用牌指定該角色為目標後，你摸一張牌。
yinjuCard = sgs.CreateSkillCard{
	name = "yinju",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("xinpi","yinju")
		room:removePlayerMark(source, "@yinju")
		room:addPlayerMark(targets[1],"yinju_target-Clear")
		--room:acquireSkill(targets[1], "#yinju_clear")
	end,
}
yinjuVS = sgs.CreateViewAsSkill{
	name = "yinju",
	n = 0,
	view_as = function(self, cards)
		local skillcard = yinjuCard:clone()
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@yinju") > 0
	end
}

yinju = sgs.CreateTriggerSkill{
	name = "yinju",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Limited,
	limit_mark = "@yinju",
	view_as_skill = yinjuVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") then
				for _, p in sgs.qlist(use.to) do
					if p:getMark("yinju_target-Clear") > 0 then
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to:getMark("yinju_target-Clear") > 0 then
				room:notifySkillInvoked(player, "yinju")
				room:broadcastSkillInvoke("yinju")
				local msg = sgs.LogMessage()
				msg.type = "$ChijieLog"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = damage.damage
				room:sendLog(msg)
				if player:isWounded() then
					local recover=sgs.RecoverStruct()
					recover.recover=math.min(damage.damage,player:getLostHp())
					room:recover(player,recover)
				end
				return true
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}

xinpi:addSkill(chijie)
xinpi:addSkill(yinju)

sgs.LoadTranslationTable{
	["xinpi"] = "辛毗",
	["#xinpi"] = "一節肅六軍",
	["chijie"] = "持節",
	["chijie1"] = "持節",
	["chijie2"] = "持節",
	[":chijie"] = "每個回合限一次，當你成為其他角色使用牌的目標後，若此牌對你造成傷害，你可以防止此牌對其他角色造成傷害；"..
	"若此牌沒有對任何角色造成傷害，你獲得之。",
	["yinju"] = "引裾",
	[":yinju"] = "限定技，出牌階段，指定一名其他角色。直到你的回合結束，防止你對其造成的傷害並改為令其回復等量的體力"
	.."，且你使用牌指定該角色為目標後，你摸一張牌。",
	["$ChijieLog"] = "%from 的技能“引裾”被觸發，對 %to 的傷害改為令其恢復 %arg 點體力",
}

--李肅 群 2體力稱號：魔使 
lisu = sgs.General(extension, "lisu", "qun2",2,true,true)
--【利熏】鎖定技，當你受到傷害時，你防止此傷害，然後獲得等同於傷害值的“珠”標記。出牌階段開始時，你進行一次判定，若結果點數小於“珠”的數量，你棄置等同於“珠”數量的手牌（若棄牌的牌數不夠，則失去剩餘數量的體力值）。
lixun = sgs.CreateTriggerSkill{
	name = "lixun",
	events = {sgs.DamageInflicted,sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
				room:notifySkillInvoked(player, "lixun")
				room:broadcastSkillInvoke("lixun")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = "normal_nature"
				room:sendLog(msg)
				player:gainMark("@ball",damage.damage)
				return true
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.reason = "lixun"
				room:judge(judge)
				if judge.card:getNumber() < player:getMark("@ball") then
					local n = player:getMark("@ball")
					local cards = room:askForExchange(player, self:objectName(), n, 1, false, "@kuizhu_ls_ask")
					if cards then
						local n2 = cards:getSubcards():length()
						local n3 = n - n2
						room:loseHp(player,n3)
					end
				end
			end
		end
	end,
	priority = -1,
}
--【饋珠】出牌階段結束時，你可以選擇體力值全場最多的一名其他角色，將手牌摸至與該角色相同（最多摸至五張），
--然後該角色觀看你的手牌，棄置任意張手牌並從觀看的牌中獲得等量的牌。若其獲得的牌大於一張，則你選擇一項：
--移去一個“珠”；或令其對其攻擊範圍內的一名角色造成1點傷害。
kuizhu_ls = sgs.CreateTriggerSkill{
	name = "kuizhu_ls",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				local _targets = sgs.SPlayerList()
				local player_hp = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					table.insert(player_hp, p:getHp())
				end
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHp() == math.max(unpack(player_hp)) and p:getHandcardNum() > player:getHandcardNum() then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local target = room:askForPlayerChosen(player,_targets,self:objectName(),"#kuizhu_ls1",true,true)
					if target then
						room:broadcastSkillInvoke(self:objectName())
						local n =math.min(5,(target:getHandcardNum())) - player:getHandcardNum()
						if n > 0 then
							player:drawCards(n)
							local ids = sgs.IntList()
							--room:doGongxin(target, player, ids)
							local cards = room:askForExchange(target, self:objectName(),n,1, (target:getHandcardNum()), false, "@kuizhu_ls_ask")
							if cards then
								room:throwCard(cards, target, target)

								room:getThread():delay()
								n2 = cards:getSubcards():length()
								local ids = sgs.IntList()
								for _, cd in sgs.qlist(player:getHandcards()) do
									ids:append(cd:getEffectiveId())
								end

								local get_ids = sgs.IntList()
								for i = 1,n2,1 do
									local card_id = room:doGongxin(target, player, ids)
									get_ids:append(card_id)
									ids:removeOne(card_id)
								end

								--room:getThread():delay()
								if not get_ids:isEmpty() then
									local move3 = sgs.CardsMoveStruct()
									move3.card_ids = get_ids
									move3.to_place = sgs.Player_PlaceHand
									move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), "str_zhijao","")
									move3.to = target						
									room:moveCardsAtomic(move3, true)
								end

								if get_ids:length() > 1 then
									local choices = {"kuizhu_ls2"}
									if player:getMark("@ball") > 0 then
										table.insert(choices, "kuizhu_ls1")
									end
									local choice = room:askForChoice(player, "kuizhu_ls", table.concat(choices, "+"))
									if choice == "kuizhu_ls1" then
										player:loseMark("@ball")
									else
										local _targets2 = sgs.SPlayerList()
										for _, p in sgs.qlist(room:getOtherPlayers(target)) do
											if target:inMyAttackRange(p) then _targets2:append(p) end
										end
										if not _targets2:isEmpty() then
											local s = room:askForPlayerChosen(player,_targets2,self:objectName(),"#kuizhu_ls2",true,true)
											if s then
												room:damage(sgs.DamageStruct("kuizhu_ls",target,s,1,sgs.DamageStruct_Normal))
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end,
}


lisu:addSkill(lixun)
lisu:addSkill(kuizhu_ls)

sgs.LoadTranslationTable{
	["lisu"] = "李肅",
	["#lisu"] = "魔使",
	["lixun"] = "利熏",
	[":lixun"] = "鎖定技，當你受到傷害時，你防止此傷害，然後獲得等同於傷害值的“珠”標記。出牌階段開始時，你進行一次判定，若結果點數小於“珠”的數量，你棄置等同於“珠”數量的手牌（若棄牌的牌數不夠，則失去剩餘數量的體力值）。",
	["kuizhu_ls"] = "饋珠",
	[":kuizhu_ls"] = "出牌階段結束時，你可以選擇體力值全場最多的一名其他角色，將手牌摸至與該角色相同（最多摸至五張），"..
"然後該角色觀看你的手牌，棄置任意張手牌並從觀看的牌中獲得等量的牌。若其獲得的牌大於一張，則你選擇一項："..
"移去一個“珠”；或令其對其攻擊範圍內的一名角色造成1點傷害。",
	["kuizhu_ls1"] = "移去一個“珠”",
	["kuizhu_ls2"] = "令其對其攻擊範圍內的一名角色造成1點傷害。",
	["#kuizhu_ls1"] = "你可以選擇體力值全場最多的一名其他角色，將手牌摸至與該角色相同（最多摸至五張）",
	["#kuizhu_ls2"] = "令其對其攻擊範圍內的一名角色造成1點傷害。",
	["@ball"] = "珠",
}

--[[
張溫

勢力
吳
體力
3
性別
男
稱號 沖天孤鷺
擴展包 上兵伐謀
頌蜀
出牌階段限一次，你可以與一名其他角色拼點，若你沒贏，該角色摸2張牌；若你贏，本回合內此技能視為未發動過。
思辨
摸牌階段，你可以放棄摸牌，改為亮出牌堆頂的四張牌，然後獲得其中所有點數最大與點數最小的牌。
若獲得的牌是兩張且點數之差小於存活人數，則你可以將剩餘的牌交給手牌數最少的角色
]]--

zhangwen = sgs.General(extension, "zhangwen", "wu2",3,true)

songshucard = sgs.CreateSkillCard{
	name = "songshu", 
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local success = source:pindian(target, "songshu", self)
		room:setPlayerFlag(effect.to, "kangnangtarget")
		local data = sgs.QVariant()
		data:setValue(target)
	end,
}
songshuvs = sgs.CreateViewAsSkill{
	name = "songshu", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = songshucard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#songshu")) and (not player:isKongcheng())
	end
}

songshu = sgs.CreateTriggerSkill{
	name = "songshu",   
	events = {sgs.Pindian}, 
	view_as_skill = songshuvs, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "songshu" and pindian.from == player then
				--if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				if pindian.from_number > pindian.to_number then
					--贏
					if pindian.from:objectName() == player:objectName() then
						room:addPlayerHistory(pindian.from, "#songshu",-1)
					end
				elseif pindian.from_number <= pindian.to_number then
					--輸
					if pindian.from:objectName() == player:objectName() then
						pindian.to:drawCards(2)
					end
				end
			end
		end		
	end,
}

function maximum_forlist(a)
	local mi = 1
	local m = a[mi]
	for i,val in ipairs(a) do
		if val > m then
			mi = i
			m = val
		end
	end
	return m
end

function minimum_forlist(a)
	local mi = 1
	local m = a[mi]
	for i,val in ipairs(a) do
		if val < m then
			mi = i
			m = val
		end
	end
	return m
end


sibian = sgs.CreateTriggerSkill{
	name = "sibian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if data:toInt() > 0 then
				if room:askForSkillInvoke(player,self:objectName(),data) then
					data:setValue(0)
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local ids = room:getNCards(4)
					room:fillAG(ids)
					room:getThread():delay()
					room:clearAG()
					--local basic = 0
					local slashs = sgs.IntList()
					local last = sgs.IntList()
					local numbers_list = {}

					for _,id in sgs.qlist(ids) do
						local card = sgs.Sanguosha:getCard(id)
						table.insert(numbers_list, card:getNumber())
					end

					for _,id in sgs.qlist(ids) do
						local card = sgs.Sanguosha:getCard(id)
						if card:getNumber() == math.min(unpack(numbers_list)) or card:getNumber() == math.max(unpack(numbers_list)) then
							slashs:append(id)				
						else
							last:append(id)
						end
					end

					if not slashs:isEmpty() then
						local dummycard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
						dummycard:deleteLater()			
						for _,id in sgs.qlist(slashs) do
							local card = sgs.Sanguosha:getCard(id)
			 				dummycard:addSubcard(card)
			 			end
			 			if player:isAlive() then
			 				player:obtainCard(dummycard)
			 			end	
					end				
					if not last:isEmpty() then
						if (slashs:length() == 2) and ( math.max(unpack(numbers_list)) - math.min(unpack(numbers_list)) ) < room:alivePlayerCount() then
							local player_card = {}
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								table.insert(player_card, p:getHandcardNum())
							end
			 				local _targets = sgs.SPlayerList()
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if p:getHandcardNum() == math.min(unpack(player_card)) then 
									_targets:append(p)
								end
							end
							local t = room:askForPlayerChosen(player, _targets, "sibian", "@sibian_obtain", true)
							if t then
								room:doAnimate(1, player:objectName(), t:objectName())
								local dummycard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
								dummycard:deleteLater()			
								for _,id in sgs.qlist(last) do
									local card = sgs.Sanguosha:getCard(id)
				 					dummycard:addSubcard(card)
				 				end
				 				if t:isAlive() then
				 					player:obtainCard(dummycard)
				 				end
				 			else
					 			for _,id in sgs.qlist(last) do
									local card = sgs.Sanguosha:getCard(id) 
									room:moveCardTo(card, nil, sgs.Player_DiscardPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "", "sibian"), true)
								end
							end
				 		else
				 			for _,id in sgs.qlist(last) do
								local card = sgs.Sanguosha:getCard(id) 
								room:moveCardTo(card, nil, sgs.Player_DiscardPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "", "sibian"), true)
							end
						end
					end
				end
			end
		end
	end
}

zhangwen:addSkill(songshu)
zhangwen:addSkill(sibian)

sgs.LoadTranslationTable{
	["zhangwen"] = "張溫",
	["#zhangwen"] = "沖天孤鷺",
	["songshu"] = "頌蜀",
	[":songshu"] = "出牌階段限一次，你可以與一名其他角色拼點，若你沒贏，該角色摸2張牌；若你贏，本回合內此技能視為未發動過。",
	["sibian"] = "思辨",
	[":sibian"] = "摸牌階段，你可以放棄摸牌，改為亮出牌堆頂的四張牌，然後獲得其中所有點數最大與點數最小的牌。"..
		"若獲得的牌是兩張且點數之差小於存活人數，則你可以將剩餘的牌交給手牌數最少的角色",
	["@sibian_obtain"] = "你可以將剩餘的牌交給手牌數最少的角色",
}

--蒲元
puyuan = sgs.General(extension, "puyuan", "shu2",4,true)
--天匠
tianjiangCard = sgs.CreateSkillCard{
	name = "tianjiang",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, erzhang)
		if #targets ~= 0 or to_select:objectName() == erzhang:objectName() then return false end
		return true
	end,
	on_effect = function(self, effect)
		local erzhang = effect.from
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		local room = erzhang:getRoom()
		if effect.to:getEquip(equip_index) ~= nil then
			local ori_card = effect.to:getEquip(equip_index)
						room:moveCardTo(ori_card, nil, sgs.Player_DiscardPile, 
						  sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
						  effect.to:objectName(), "", "tianjiang"), true)
		end
		room:moveCardTo(self, erzhang, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, erzhang:objectName(), "tianjiang", ""))
		if card:isKindOf("RedSword") or card:isKindOf("LiecuiBlade") or card:isKindOf("WaterSword") or card:isKindOf("PoisonDagger") or card:isKindOf("ThunderKnife") then
			erzhang:drawCards(2)
		end
	end
}
tianjiang = sgs.CreateOneCardViewAsSkill{
	name = "tianjiang",	
	filter_pattern = "EquipCard|.|.|equipped",
	view_as = function(self, card)
		local zhijian_card = tianjiangCard:clone()
		zhijian_card:addSubcard(card)
		zhijian_card:setSkillName(self:objectName())
		return zhijian_card
	end
} 

tianjiangGS = sgs.CreateTriggerSkill{
	name = "#tianjiang" ,
	events = {sgs.GameStart} ,
	on_trigger = function(self, event, player, data, room)
		local equip_type_table = {"Weapon", "Armor", "DefensiveHorse", "OffensiveHorse", "Treasure"}
		for _, card in sgs.qlist(player:getCards("e")) do
			if card:isKindOf("Weapon") or player:getMark("@AbolishWeapon") > 0 then
				table.removeOne(equip_type_table, "Weapon")
			elseif card:isKindOf("Armor") or player:getMark("@AbolishArmor") > 0 then
				table.removeOne(equip_type_table, "Armor")
			elseif card:isKindOf("DefensiveHorse") or player:getMark("@AbolishDefensiveHorse") > 0 then
				table.removeOne(equip_type_table, "DefensiveHorse")
			elseif card:isKindOf("OffensiveHorse") or player:getMark("@AbolishOffensiveHorse") > 0 then
				table.removeOne(equip_type_table, "OffensiveHorse")
			elseif card:isKindOf("Treasure") or player:getMark("@AbolishTreasure") > 0 then
				table.removeOne(equip_type_table, "Treasure")
			end
		end
		local usable_count = 2
		if player:getEquips():length() + usable_count > 5 then
			usable_count = 5 - player:getEquips():length()
		end
		while usable_count > 0 and #equip_type_table > 0 do
			local equip_type_index = math.random(1, #equip_type_table)
			local equips = sgs.CardList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf(equip_type_table[equip_type_index]) then
					local equip_index = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()
				 	if player:getEquip(equip_index) == nil  then
						equips:append(sgs.Sanguosha:getCard(id))
					end
				end
			end
			if not equips:isEmpty() then
				local card = equips:at(math.random(0, equips:length() - 1))
				room:useCard(sgs.CardUseStruct(card, player, player))
				usable_count = usable_count - 1
			end
			table.removeOne(equip_type_table, equip_type_table[equip_type_index])
		end
	end
}

--鑄刃
zhurenCard = sgs.CreateSkillCard{
	name = "zhuren",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local player = source
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local getweaponfail = false
		local success_p = 0
		if card:getNumber() == 13 then
			success_p = 100
		elseif card:getNumber() >= 9 then
			success_p = 95
		elseif card:getNumber() >= 5 then
			success_p = 90
		else
			success_p = 85
		end
		if card:isKindOf("Lightning") then
			if room:getTag("TK_ID"):toInt() > 0 and player:getMark("hasequip_TK") == 0 then
			 	for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_TK",1)
				end
				local getcard = sgs.Sanguosha:getCard(room:getTag("TK_ID"):toInt())
				player:obtainCard(getcard)
			else
				getweaponfail = true
			end
		elseif card:getSuit() == sgs.Card_Heart then
			if room:getTag("RS_ID"):toInt() > 0 and math.random(1,100) <= success_p
			 and player:getMark("hasequip_RS") == 0 then
			 	for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_RS",1)
				end
				local getcard = sgs.Sanguosha:getCard(room:getTag("RS_ID"):toInt())
				player:obtainCard(getcard)
			else
				getweaponfail = true
			end
		elseif card:getSuit() == sgs.Card_Diamond then
			if room:getTag("LB_ID"):toInt() > 0 and math.random(1,100) <= success_p
			 and player:getMark("hasequip_LB") == 0 then
			 	for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_LB",1)
				end
				local getcard = sgs.Sanguosha:getCard(room:getTag("LB_ID"):toInt())
				player:obtainCard(getcard)
			else
				getweaponfail = true
			end
		elseif card:getSuit() == sgs.Card_Club then
			if room:getTag("WS_ID"):toInt() > 0 and math.random(1,100) <= success_p
			 and player:getMark("hasequip_WS") == 0 then
			 	for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_WS",1)
				end
				local getcard = sgs.Sanguosha:getCard(room:getTag("WS_ID"):toInt())
				player:obtainCard(getcard)
			else
				getweaponfail = true
			end
		elseif card:getSuit() == sgs.Card_Spade then
			if room:getTag("PD_ID"):toInt() > 0 and math.random(1,100) <= success_p
			 and player:getMark("hasequip_PD") == 0 then
			 	for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_PD",1)
				end
				local getcard = sgs.Sanguosha:getCard(room:getTag("PD_ID"):toInt())
				player:obtainCard(getcard)
			else
				getweaponfail = true
			end
		end
		if getweaponfail then
			local point_six_card = sgs.IntList()
			if room:getDrawPile():length() > 0 then
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
						point_six_card:append(id)
					end
				end
			end
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
}
zhuren = sgs.CreateOneCardViewAsSkill{
	name = "zhuren",	
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local zhuren_card = zhurenCard:clone()
		zhuren_card:addSubcard(card)
		zhuren_card:setSkillName(self:objectName())
		return zhuren_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zhuren")
	end
} 

puyuan:addSkill(tianjiang)
puyuan:addSkill(tianjiangGS)
puyuan:addSkill(zhuren)

extension:insertRelatedSkills("tianjiang","#tianjiang")

sgs.LoadTranslationTable{
	["puyuan"] = "蒲元",
	["#puyuan"] = "淬煉百兵",
	["tianjiang"] = "天匠", 
	[":tianjiang"] = "遊戲開始時，你隨機獲得兩張不同副類別的裝備牌，並置入你的裝備區。出牌階段，你裝備區裡的牌可以移動至其他角色的裝備區並替換其原有裝備，若你移動的是“鑄刃”打造的裝備，你摸兩張牌。",
	["zhuren"] = "鑄刃",
	[":zhuren"] = "出牌階段限一次，你可以棄置一張手牌。根據此牌的花色點數，你有一定概率打造成功並獲得一張武器牌"..
	"（若打造失敗或武器已有則改為摸一張【殺】，花色決定武器名稱，點數決定成功率）。此武器牌進入棄牌堆時，將其移出遊戲。",
}

--[[
許靖 蜀 3 選賢拔才
【譽虛】
出牌階段，你使用一張牌後，可以摸一張牌。若如此做，你使用下一張牌後，棄置一張牌。
【實薦】
一名其他角色的出牌階段，該角色在本階段使用的第二張牌結算後，你可以棄置一張牌，令其獲得“譽虛”直到回合結束。
]]--

xujing = sgs.General(extension, "xujing", "shu2",3,true)

yuxu = sgs.CreateTriggerSkill{
	name = "yuxu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		local card
		local invoke = true
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			if data:toCardResponse().m_isUse then
				card = data:toCardResponse().m_card
			else
				invoke = false
			end
		end

		if card:getTypeId() ~= sgs.Card_TypeSkill and player:getPhase() == sgs.Player_Play then
			if player:hasFlag("yuxu_used") then
				room:setPlayerFlag(player,"-yuxu_used")
				room:askForDiscard(player, self:objectName(), 1, 1, false, true)
			else
				if room:askForSkillInvoke(player, "yuxu", data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
					room:setPlayerFlag(player,"yuxu_used")
				end
			end
		end
	end,
}

shijian = sgs.CreateTriggerSkill{
	name = "shijian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			local invoke = true
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				else
					invoke = false
				end
			end
			if (not card:isKindOf("SkillCard")) and player:getPhase() == sgs.Player_Play then
				if player:getMark("card_used_num_Play") == 2 then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasSkill("shijian") and (not player:hasSkill("yuxu")) then
							local gcard = room:askForCard(p, ".,Equip", "#shijian_give:"..player:objectName(),sgs.QVariant(), self:objectName())
							if gcard then
								room:broadcastSkillInvoke(self:objectName())
								room:setPlayerMark(player,"yuxu_round",1)
								room:acquireSkill(player, "yuxu")
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase ==  sgs.Player_NotActive then
				room:setPlayerMark(player,"shijian_count",0)
				if player:hasSkill("yuxu") and player:getMark("yuxu_round") == 1 then
					room:detachSkillFromPlayer(player, "yuxu")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:isAlive()
	end
}

xujing:addSkill(yuxu)
xujing:addSkill(shijian)
sgs.LoadTranslationTable{
	["xujing"] = "許靖",
	["#xujing"] = "選賢拔才",
	["yuxu"] = "譽虛", 
	[":yuxu"] = "出牌階段，你使用一張牌後，可以摸一張牌。若如此做，你使用下一張牌後，棄置一張牌。",
	["shijian"] = "實薦",
	[":shijian"] = "一名其他角色的出牌階段，該角色在本階段使用的第二張牌結算後，你可以棄置一張牌，令其獲得“譽虛”直到回合結束。",
	["#shijian_give"] = "你可以棄置一張牌，令 %src 獲得“譽虛”直到回合結束",
}

--[[
懷舊花鬘 3 芳踪載馨
蠻裔：鎖定技，【南蠻入侵】對你無效。
蠻嗣：當一名角色使用的【南蠻入侵】結算完畢後，你可以摸X張牌（X為此【南蠻入侵】造成傷害的角色數）。
藪影：每個回合限一次，當你對一名男性角色造成傷害（或一名男性角色對你）造成傷害時，若此傷害是你對其
（或其對你）造成的第二次傷害，你可以棄置一張手牌令此傷害+1（或-1）。
戰緣：覺醒技，準備階段，若你已因“蠻嗣”累計獲得超過七張牌，你加1點體力上限，並可以選擇一名男性角色，你與其獲
得技能“系力”，然後你失去技能“蠻嗣”。
☆系力：你的回合外，當其他擁有【系力】技能的角色在其回合內使用【殺】指定目標後，你可以棄置一張手牌，令此【殺】傷害
+1。
]]--
nos_huaman = sgs.General(extension, "nos_huaman", "shu2",3,false,true)

manyi_hm = sgs.CreateTriggerSkill{
	name = "manyi_hm",
	events = {sgs.CardEffected},
	frequency =sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return true
		else
			return false
		end
	end
}

nos_mansi = sgs.CreateTriggerSkill{
	name = "nos_mansi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardFinished, sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("SavageAssault") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("nos_mansi") then
						if room:askForSkillInvoke(p, self:objectName(), data) then
							p:drawCards(p:getMark("nos_mansi_damage"))
							room:setPlayerMark(p, "@nos_mansi_draw", p:getMark("@nos_mansi_draw")+p:getMark("nos_mansi_damage"))
						end
					end
				end
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("nos_mansi") then
					room:setPlayerMark(p, "nos_mansi_damage", 0)
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local lianji_source = nil
			if damage.card and damage.card:isKindOf("SavageAssault") and damage.damage > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("nos_mansi") then
						room:setPlayerMark(p, "nos_mansi_damage", p:getMark("nos_mansi_damage")+1)
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

nos_souying = sgs.CreateTriggerSkill{
	name = "nos_souying" ,
	events = {sgs.DamageCaused, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			local pattern = "."
			if damage.to and damage.to:isAlive() and (player:getMark("nos_souying_damage"..damage.to:objectName().."-Clear") > 0) and player:canDiscard(player, "h") and room:askForCard(player, pattern, "@nos_souying-increase:" .. damage.to:objectName(), data, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:notifySkillInvoked(player, self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local pattern = "."
			if damage.from and damage.from:isAlive() and (damage.from:getMark("nos_souying_damage"..player:objectName().."-Clear") > 0) and player:canDiscard(player, "h") and room:askForCard(player, pattern, "@nos_souying-decrease:" .. damage.from:objectName(), data, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:notifySkillInvoked(player, self:objectName())
				if damage.damage > 1 then
					damage.damage = damage.damage - 1
					data:setValue(damage)
				else
					return true
				end
				return false
			end
		end
	end
}

nos_souying_recond = sgs.CreateTriggerSkill{
	name = "#nos_souying",
	events = {sgs.Damage},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:objectName() ~= damage.to:objectName() then
				room:addPlayerMark(damage.from, "nos_souying_damage"..damage.to:objectName().."-Clear")
			end
		end
	end,
	can_trigger=function()
		return true
	end
}

nos_zhanyuan = sgs.CreatePhaseChangeSkill{
	name = "nos_zhanyuan",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and (player:getMark("@nos_mansi_draw") >= 7 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) and player:getMark(self:objectName()) == 0 then
			SendComLog(self, player)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				room:addPlayerMark(player, self:objectName())
				if room:changeMaxHpForAwakenSkill(player, 1) then
					room:doSuperLightbox("nos_huaman","nos_zhanyuan")
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:isMale() then
							targets:append(p)
						end
					end
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "yongdi-invoke", true, true)
					if target then
						room:handleAcquireDetachSkills(player, "nos_xili|-nos_mansi")
						room:handleAcquireDetachSkills(target, "nos_xili")
					end
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}

nos_xili = sgs.CreateTriggerSkill{
	name = "nos_xili" ,
	events = {sgs.TargetSpecified,sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:hasSkill("nos_xili") then 
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("nos_xili") and p:getPhase() == sgs.Player_NotActive then
						local cd = room:askForCard(p, ".", "@nos_xili", data, self:objectName())
						if cd then
							room:setCardFlag(use.card,"nos_xili_card")
						end
					end
				end
			end

		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and damage.card:hasFlag("nos_xili_card") then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#nos_xiliPD"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
				end
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("nos_xili") then skills:append(nos_xili) end
nos_huaman:addSkill(manyi_hm)
nos_huaman:addSkill(nos_mansi)
nos_huaman:addSkill(nos_souying)
nos_huaman:addSkill(nos_souying_recond)
nos_huaman:addSkill(nos_zhanyuan)
extension:insertRelatedSkills("nos_souying","#nos_souying")

sgs.LoadTranslationTable{
	["nos_huaman"] = "花鬘--懷舊",
	["&nos_huaman"] = "花鬘",
	["#nos_huaman"] = "芳踪載馨",
	["manyi_hm"] = "蠻裔", 
	[":manyi_hm"] = "鎖定技，【南蠻入侵】對你無效。",
	["nos_mansi"] = "蠻嗣", 
	[":nos_mansi"] = "當一名角色使用的【南蠻入侵】結算完畢後，你可以摸X張牌（X為此【南蠻入侵】造成傷害的角色數）。",
	["nos_souying"] = "藪影", 
	[":nos_souying"] = "每個回合限一次，當你對一名男性角色造成傷害（或一名男性角色對你）造成傷害時，若此傷害是你對其"
	.."（或其對你）造成的第二次傷害，你可以棄置一張手牌令此傷害+1（或-1）。",
	["nos_zhanyuan"] = "戰緣",
	[":nos_zhanyuan"] = "覺醒技，準備階段，若你已因“蠻嗣”累計獲得超過七張牌，你加1點體力上限，並可以選擇一名男性角色，"
	.."你與其獲得技能“系力”，然後你失去技能“蠻嗣”。",
	["nos_xili"] = "系力",
	[":nos_xili"] = "你的回合外，當其他擁有【系力】技能的角色在其回合內使用【殺】指定目標後，你可以棄置一張手牌，令此【殺】傷害+1。",
	["@nos_xili"] = "你可以棄置一張手牌，令此【殺】傷害+1。",
	["@nos_souying-increase"] = "你可以棄置一張牌令 %src 受到的傷害+1",
	["@nos_souying-decrease"] = "你可以棄置一張牌令 %src 造成的傷害-1",
	["#nos_souyingIncrease"] = "%from 發動了“<font color=\"yellow\"><b>藪影</b></font>”，傷害點數從 %arg 點增加至 %arg2 點" ,
	["#nos_souyingDecrease"] = "%from 發動了“<font color=\"yellow\"><b>藪影</b></font>”，傷害點數從 %arg 點減少至 %arg2 點" ,
	["#nos_xiliPD"] = "%from 發動了“<font color=\"yellow\"><b>系力</b></font>”，傷害點數從 %arg 點增加至 %arg2 點" ,
}

--[[
花鬘
]]--
huaman = sgs.General(extension, "huaman", "shu2",3,false)

--蠻嗣
mansiVS = sgs.CreateZeroCardViewAsSkill{
	name = "mansi",
	view_as = function(self)
		local card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, 0)
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("used_mansi-Clear") == 0 and not player:isKongcheng()
	end
}

mansi = sgs.CreateTriggerSkill{
	name = "mansi",
	view_as_skill = mansiVS,
	events = {sgs.CardFinished, sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("SavageAssault") then
				if use.card:getSkillName() == "mansi" then
					room:setPlayerMark(use.from, "used_mansi-Clear",1)
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("SavageAssault") and damage.damage > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("mansi") then
						p:drawCards(1)
						room:setPlayerMark(p, "@mansi_draw", p:getMark("@mansi_draw") + 1)
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

souying = sgs.CreateTriggerSkill{
	name = "souying" ,
	events = {sgs.TargetConfirmed, sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and (not use.card:isKindOf("SkillCard")) and (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:length() == 1 and player:getMark("souying_used-Clear") == 0 then
				local pattern = ".."
				if player:isAlive() and (use.from:getMark("souying_useto"..player:objectName().."-Clear") > 0) and player:canDiscard(player, "h") and room:askForCard(player, pattern, "@souying-target", data, self:objectName()) then	
					room:broadcastSkillInvoke(self:objectName())
					player:setFlags("-ZhenlieTarget")
					player:setFlags("ZhenlieTarget")
					if player:isAlive() and player:hasFlag("ZhenlieTarget") then
						room:addPlayerMark(player, "souying_used-Clear")
						player:setFlags("-ZhenlieTarget")
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)	
					end
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (not use.card:isKindOf("SkillCard")) and (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:length() == 1 and player:getMark("souying_used-Clear") == 0 then
				for _, p in sgs.qlist(use.to) do
					local pattern = ".."
					if player:isAlive() and (player:getMark("souying_useto"..p:objectName().."-Clear") > 0) and player:canDiscard(player, "h")  then	
						room:broadcastSkillInvoke(self:objectName())
						if room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_PlaceTable then
							if room:askForCard(player, pattern, "@souying-use", data, self:objectName()) then
								player:obtainCard(use.card)
								room:addPlayerMark(player, "souying_used-Clear")
							end
						end
					end
				end
			end
		end
		return false
	end
}

souying_recond = sgs.CreateTriggerSkill{
	name = "#souying",
	priority = -1,
	global = true,
	events = {sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if (not use.card:isKindOf("SkillCard")) and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				for _, p in sgs.qlist(use.to) do
					if use.from:objectName() ~= p:objectName() then
						room:addPlayerMark(use.from, "souying_useto"..p:objectName().."-Clear")
					end
				end
			end
		end
	end,
}

zhanyuan = sgs.CreatePhaseChangeSkill{
	name = "zhanyuan",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and (player:getMark("@mansi_draw") >= 7 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) and player:getMark(self:objectName()) == 0 then
			SendComLog(self, player)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				room:addPlayerMark(player, self:objectName())
				if room:changeMaxHpForAwakenSkill(player, 1) then
					room:doSuperLightbox("huaman","zhanyuan")
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:isMale() then
							targets:append(p)
						end
					end
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "zhanyuan-invoke", true, true)
					if target then
						room:handleAcquireDetachSkills(player, "xili|-mansi")
						room:handleAcquireDetachSkills(target, "xili")
					end
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}

xili = sgs.CreateTriggerSkill{
	name = "xili" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from:hasSkill("xili") and not damage.to:hasSkill("xili") then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill("xili") and p:getMark("xili_use-Clear") == 0 then
						local cd = room:askForCard(p, "..", "@xili", data, self:objectName())
						if cd then
							room:addPlayerMark(p,"xili_use-Clear")
							damage.damage = damage.damage + 1
							local msg = sgs.LogMessage()
							msg.type = "#XiliPD"
							msg.from = p
							msg.to:append(damage.to)
							msg.arg = tostring(damage.damage - 1)
							msg.arg2 = tostring(damage.damage)
							room:sendLog(msg)	
							data:setValue(damage)
							p:drawCards(2)
							damage.from:drawCards(2)
						end
					end
				end
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("xili") then skills:append(xili) end

huaman:addSkill(manyi_hm)
huaman:addSkill(mansi)
huaman:addSkill(souying)
huaman:addSkill(souying_recond)
huaman:addSkill(zhanyuan)
extension:insertRelatedSkills("souying","#souying")

sgs.LoadTranslationTable{
	["huaman"] = "花鬘",
	["#huaman"] = "芳踪載馨",

	["mansi"] = "蠻嗣", 
	[":mansi"] = "階段技，妳可以將所有手牌當做「南蠻入侵」使用；當一名角色受到【南蠻入侵】的傷害後，妳摸一張牌。",
	["souying"] = "藪影", 
	[":souying"] = "每個回合限一次，當妳對其他角色/其他角色對妳使用牌指定唯一目標後，若此牌不是妳對其"
	.."/其對妳使用的第一張牌，妳可以棄置一張牌並獲得此牌/令此牌對妳無效。",
	["zhanyuan"] = "戰緣",
	[":zhanyuan"] = "覺醒技，準備階段，若妳已因“蠻嗣”累計獲得超過七張牌，你加1點體力上限，並可以選擇一名男性角色，"
	.."你與其獲得技能“系力”，然後妳失去技能“蠻嗣”。",
	["xili"] = "系力",
	[":xili"] = "每回合限一次，當其他擁有【系力】技能的角色在其回合內對沒有「系力」的角色造成傷害時，你可以棄置一張手牌令此傷害+1，然後你與其各摸兩張牌。",
	["@xili"] = "你可以棄置一張手牌，令此傷害+1。",
	["@souying-target"] = "妳可以棄置一張牌令此牌對妳無效",
	["@souying-use"] = "妳可以棄置一張牌並獲得使用的牌",

	["zhanyuan-invoke"] = "妳可以令一名男性角色與妳獲得技能”系力“（若妳沒有選擇腳色則保有“蠻嗣”）",

	["#XiliPD"] = "%from 發動了“<font color=\"yellow\"><b>系力</b></font>”，傷害點數從 %arg 點增加至 %arg2 點" ,
}

--OL皇甫嵩
ol_huangfusong = sgs.General(extension, "ol_huangfusong", "qun2")

ol_fenyueCard = sgs.CreateSkillCard{
	name = "ol_fenyue", 
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and (not sgs.Self:isKongcheng())
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if source:pindian(targets[1], self:objectName(), self) then
				room:broadcastSkillInvoke(self:objectName(), 2)

				if sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() <= 5 then
					room:obtainCard(source,room:askForCardChosen(source, targets[1], "he", "ol_fenyue", false, sgs.Card_MethodDiscard), true)
				end
				if sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() <= 9 then
					getpatterncard(source, {"Slash"},true,true)
				end
				if sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() <= 13 then
					local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("_"..self:objectName())
					if not source:isProhibited(targets[1], slash) then
						room:useCard(sgs.CardUseStruct(slash, source, targets[1]))
					end
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

ol_fenyue = sgs.CreateOneCardViewAsSkill{
	name = "ol_fenyue", 
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local skillcard = ol_fenyueCard:clone()
		skillcard:addSubcard(card:getId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#ol_fenyue") < player:getMark("ol_fenyue")
	end
}
ol_huangfusong:addSkill(ol_fenyue)

sgs.LoadTranslationTable{
["ol_huangfusong"] = "OL皇甫嵩",
["&ol_huangfusong"] = "皇甫嵩",
["#ol_huangfusong"] = "志定雪霜",
["illustrator:ol_huangfusong"] = "秋呆呆",
["ol_fenyue"] = "奮鉞",
[":ol_fenyue"] = "<font color=\"green\"><b>出牌階段限X次（X為與你陣營不同的角色數），</b></font>你可以與一名角色拼點：若你贏且你拼點的牌的點：不大於K，你選擇是否對其使用一張【雷殺】，不大於9，你隨機獲得牌堆中的一張「殺」，不大於5，你獲得其一張牌。",
["ol_fenyue1"] = "其於此回合內不能使用或打出手牌",
["ol_fenyue2"] = "視為對其使用【殺】",
["$ol_fenyue1"] = "逆賊勢大，且紮營寨，擊其懈怠。",
["$ol_fenyue2"] = "兵有其變，不在眾寡 。",
["~ol_huangfusong"] = "吾只恨黃巾未平，不能報效朝廷。",
}

--袁譚袁尚
yuantanyuanshang = sgs.General(extension, "yuantanyuanshang", "qun2",4)
--內伐
neifa = sgs.CreateTriggerSkill{
	name = "neifa",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.PreCardUsed,sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local froms = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						 if (p:getJudgingArea():length() > 0 or p:getEquips():length() > 0) then
						 	froms:append(p)
						 end
					end
					local from = room:askForPlayerChosen(player, froms, self:objectName(), "@neifa-from",true)
					if from then
						local card_id = room:askForCardChosen(player, from, "ej", self:objectName())
						room:obtainCard(player,card_id)
					else
						player:drawCards(2)
					end
					room:broadcastSkillInvoke(self:objectName())
					local card = room:askForCard(player, ".,Equip!", "@neifa", data, sgs.Card_MethodDiscard)

					if card:isKindOf("BasicCard") then
						room:setPlayerMark(player,"neifa_B-Clear",1)
					else
						room:setPlayerMark(player,"neifa_NB-Clear",1)
					end

					local n = 0
					for _, cd in sgs.qlist(player:getHandcards()) do
						local can_not_use = true
						if cd:isAvailable(player) and not player:isLocked(cd) then
							for _,p in sgs.qlist(room:getOtherPlayers(player)) do
								if not sgs.Sanguosha:isProhibited(player, p, cd) then
									can_not_use = false
								end
							end
						end
						if can_not_use then
							n = n + 1
						end
					end
					n  = math.min(5,n)
					room:setPlayerMark(player,"@neifa_Cannot_Use_Card-Clear",n)
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getMark("neifa_NB-Clear") == 1 then
				if use.card:isNDTrick() and (not use.card:isKindOf("Collateral")) then
					if (sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY) then return false end
					local available_targets = sgs.SPlayerList()
					if (not use.card:isKindOf("AOE")) and (not use.card:isKindOf("GlobalEffect")) then
						room:setPlayerFlag(player, "neifaExtraTarget")
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then continue end
							if (use.card:targetFixed()) then
								--if (not use.card:isKindOf("Peach")) or (p:isWounded()) then
									available_targets:append(p)
								--end
							else
								if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
									available_targets:append(p)
								end
							end
						end
						room:setPlayerFlag(player, "-neifaExtraTarget")
					end
					local choices = {}
					table.insert(choices, "cancel")
					if (use.to:length() > 1) then table.insert(choices, 1, "remove") end
					if (not available_targets:isEmpty()) then table.insert(choices, 1, "add") end
					if #choices == 1 then return false end
					local choice = room:askForChoice(player, "qiaoshui", table.concat(choices, "+"), data)
					if (choice == "cancel") then
						return false
					elseif choice == "add" then
						local extra = nil
						extra = room:askForPlayerChosen(player, available_targets, "qiaoshui", "@qiaoshui-add:::" .. use.card:objectName())
						if extra then
							room:doAnimate(1, player:objectName(), extra:objectName())
							use.to:append(extra)
						end
						room:sortByActionOrder(use.to)
					else
						local removed = room:askForPlayerChosen(player, use.to, "qiaoshui", "@qiaoshui-remove:::" .. use.card:objectName())
						room:doAnimate(1, player:objectName(), removed:objectName())
						use.to:removeOne(removed)
					end
					data:setValue(use)
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:getMark("neifa_NB-Clear") == 1 and player:getMark("neifa_NB_Equip-Clear") < 2 then
				if use.card:isKindOf("EquipCard") then
					player:drawCards(player:getMark("@neifa_Cannot_Use_Card-Clear"))
					room:setPlayerMark(player,"neifa_NB_Equip-Clear",player:getMark("neifa_NB_Equip-Clear")+1)
				end
			end
		end
	end
}

neifaTM = sgs.CreateTargetModSkill{
	name = "#neifa" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	residue_func = function(self, player, card)
		if player:getMark("neifa_B-Clear") > 0 and card:isKindOf("Slash") then
			return player:getMark("@neifa_Cannot_Use_Card-Clear")
		end
	end,
	distance_limit_func = function(self, player, card)
		if (player:hasFlag("neifaExtraTarget")) then
			return 1000
		end
		return 0
	end,
	extra_target_func = function(self, player, card)
		if player:getMark("neifa_B-Clear") > 0 and card:isKindOf("Slash") then
			return 1
		end
	end,
}

neifaPs = sgs.CreateProhibitSkill{
	name = "#neifaPs",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		if from:getMark("neifa_B-Clear") > 0 then
			if card:isKindOf("EquipCard") or card:isKindOf("TrickCard") then
				return true
			end
		elseif from:getMark("neifa_NB-Clear") > 0 then
			if card:isKindOf("BasicCard") then
				return true
			end
		end
		return false
	end
}

yuantanyuanshang:addSkill(neifa)
yuantanyuanshang:addSkill(neifaTM)
yuantanyuanshang:addSkill(neifaPs)

sgs.LoadTranslationTable{
	["yuantanyuanshang"] = "袁譚袁尚",
	["#yuantanyuanshang"] = "兄弟鬩牆",
	["illustrator:yuantanyuanshang"] = "紫喬",
	["neifa"] = "內伐",
	[":neifa"] = "出牌階段開始時，你可以摸兩張牌或獲得場上的一張牌，然後棄置一張牌。若你以此法棄置基本牌，則本回合你不能使用非基本牌，"..
	"且你使用「殺」的次數上限+X，且目標數+1；若你以此法棄置非基本牌，則本回合你不能使用基本牌，且你使用普通錦囊牌時，可以額外增加一個目標或"..
	"減少一個目標，且你使用前兩張裝備牌時，你摸X張牌(X為你發動技能時，手中不能使用的牌數，且至多為5)",
	["@neifa-from"] = "你可以獲得場上的一張牌，若你沒有選擇角色，你可以摸兩張牌",
	["@neifa"] = "你需棄置一張牌",
}

--王雙
wangshuang = sgs.General(extension, "wangshuang", "wei2", "8", true)

zhuilie = sgs.CreateTriggerSkill{
	name = "zhuilie" ,
	events = {sgs.TargetSpecified,sgs.DamageCaused,sgs.CardUsed} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				if (not player:inMyAttackRange(p)) then
					room:setPlayerFlag(p , "zhuilie_target")
					if (not player:hasFlag("zhuilie_nolimit")) then
						room:setPlayerFlag(player , "zhuilie_nolimit")
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasFlag("zhuilie_nolimit") then
				if use.m_addHistory then
					room:addPlayerHistory(player, use.card:getClassName(),-1)
					room:setPlayerFlag(player , "-zhuilie_nolimit")
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and damage.to:hasFlag("zhuilie_target") then
					-- For AI
					room:setPlayerMark(damage.to,"zhuilie_target",1)
					local judge = sgs.JudgeStruct()
					judge.pattern = "Weapon,OffensiveHorse,DefensiveHorse|.|.|."
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						local origin_damage = damage.damage
						damage.damage = damage.to:getHp()
						local msg = sgs.LogMessage()
						msg.type = "#Zhuilie"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(origin_damage)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
						data:setValue(damage)
					else
						room:loseHp(player)
					end
					room:setPlayerMark(damage.to,"zhuilie_target",0)
				end
			end
		end
	end
}
zhuilieTargetMod = sgs.CreateTargetModSkill{
	name = "#zhuilieTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("zhuilie") then
			return 1000
		end
	end,
}
wangshuang:addSkill(zhuilie)
wangshuang:addSkill(zhuilieTargetMod)
extension:insertRelatedSkills("zhuilie","#zhuilieTargetMod")
sgs.LoadTranslationTable{
	["wangshuang"] = "王雙",
	["#wangshuang"] = "遏北的悍鋒",
	["zhuilie"] = "追獵",
	[":zhuilie"] = "鎖定技，你的【殺】無距離限制；當你使用【殺】指定攻擊範圍外的角色為目標後，此【殺】不計次數且你進行判定："
	.."若結果為武器或坐騎牌，此【殺】傷害值等於其體力值；若為其他結果，你失去1點體力。",
	["#Zhuilie"] = "%from 的技能 “<font color=\"yellow\"><b>追獵</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--[[
孫邵
]]--
sunshao = sgs.General(extension, "sunshao", "wu2", 3, true)

--弼政
bizheng = sgs.CreateTriggerSkill{
	name = "bizheng",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "bizheng", "@bizheng-choose", true)
			if s then
				room:doAnimate(1, player:objectName(), s:objectName())
				room:notifySkillInvoked(player, "bizheng")
				room:drawCards(s, 2, "bizheng")
				if player:getHandcardNum() > player:getMaxHp() then
					room:askForDiscard(player, "bizheng", 2, 2, false, false)
				end
				if s:getHandcardNum() > s:getMaxHp() then
					room:askForDiscard(s, "bizheng", 2, 2, false, false)
				end
			end
		end
	end,
}

--佚典
yidian = sgs.CreateTriggerSkill{
	name = "yidian" ,
	events = {sgs.PreCardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()

			if (room:alivePlayerCount() > 2) and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and
			 not use.card:isKindOf("Jink") and not use.card:isKindOf("Nullification") and
			 not use.card:isKindOf("Collateral") then
			 	local can_invoke = true

			 	if room:getDiscardPile():length() > 0 then
					for _, id in sgs.qlist(room:getDiscardPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:objectName() == use.card:objectName() then
							can_invoke = false
							break
						end
					end
				end

				if can_invoke then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if room:alivePlayerCount() > (use.to:length() + 1) then
							if (not use.to:contains(p)) and p ~= use.from then
								_targets:append(p)
							end
						end
					end
					if not _targets:isEmpty() then
						room:setTag("yidianData", data)
						local s = room:askForPlayerChosen(player, _targets, "yidian", "@yidian:"..use.card:objectName(), true)
						if s then
							room:doAnimate(1, player:objectName(), s:objectName())
							room:notifySkillInvoked(player, "yidian")
							if not use.to:contains(s) then
								room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
								use.to:append(s)
								room:sortByActionOrder(use.to)
								--local msg = sgs.LogMessage()
								--msg.type = "#yidian1"
								--msg.from = player
								--msg.to:append(s)
								--msg.arg = use.card:objectName()
								--room:sendLog(msg)
								data:setValue(use)
							end
						end
						room:removeTag("yidianData")
					end
				end
			end
		end
		return false
	end
}

sunshao:addSkill(bizheng)
sunshao:addSkill(yidian)

sgs.LoadTranslationTable{
	["sunshao"] = "孫邵",
	["#sunshao"] = "",
	["bizheng"] = "弼政",
	[":bizheng"] = "摸牌階段結束時，你可令一名其他角色摸兩張牌，然後你與其之中，手牌數大於體力上限的角色棄置兩張牌。",
	["@bizheng-choose"] = "你可以對一名角色發動「弼政」",
	["yidian"] = "佚典",
	[":yidian"] = "若你使用的基本牌或普通錦囊在棄牌堆中沒有同名牌，你可以為此牌指定一個額外目標（借刀除外，無視距離）。",
	["@yidian"] = "你可以額外指定一名角色角色成為 %src 的目標",
	["~yidian"] = "點選成為目標的角色 -> 點擊「確定」",
}

--神曹丕 5
shencaopi = sgs.General(extension, "shencaopi", "god", 5, true)
--儲元
chuyuan = sgs.CreateTriggerSkill{
	name = "chuyuan",
	events  = {sgs.Damaged},
	can_trigger = function(self, target)
		return target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("chuyuan") and p:getPile("chu"):length() < p:getMaxHp() then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					player:drawCards(1)
					local prompt1 = string.format("chuyuan_put:%s", player:objectName())
					local card = room:askForExchange(player, "chuyuan", 1,1, false, prompt1)
					room:broadcastSkillInvoke("chuyuan")
					p:addToPile("chu",card)
				end
			end
		end
	end,
}

--登極 覺醒技，回合開始時，若你的儲為3或更多，你獲得所有儲，減少一點體力上限，獲得技能天行，奸雄
dengji = sgs.CreatePhaseChangeSkill{
	name = "dengji",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPile("chu"):length() >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			if room:changeMaxHpForAwakenSkill(player) then
				local id2s = sgs.IntList()
				local n = player:getPile("chu"):length()
				if player:getPile("chu"):length() >= 3 then
					local msg = sgs.LogMessage()
					msg.type = "#dengjiWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = player:getPile("chu"):length()
					msg.arg2 = self:objectName()
					room:sendLog(msg)
				end

				for i = 1, n,1 do
					local ids = player:getPile("chu")
					local id = ids:at(i-1)
					local card = sgs.Sanguosha:getCard(id)
					id2s:append(card:getEffectiveId())
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = id2s
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)

				room:broadcastSkillInvoke("dengji")
				room:setPlayerMark(player, self:objectName(), 1)
				room:doSuperLightbox("shencaopi","dengji")	
				room:acquireSkill(player, "jianxiong_po")
				room:acquireSkill(player, "tianxing")
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_RoundStart 
		and target:getMark(self:objectName()) == 0 
	end
}
--天行 覺醒技，回合開始時，若你的儲為3或更多，你獲得所有儲，減少一點體力上限，失去技能儲元，選擇獲得以下技能之一一：仁德/制衡/亂擊/放權

tianxing = sgs.CreateTriggerSkill{
	name = "tianxing",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPile("chu"):length() >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:addPlayerMark(player, "tianxing")
			if room:changeMaxHpForAwakenSkill(player) then
				room:broadcastSkillInvoke(self:objectName())

				if player:getPile("chu"):length() >= 3 then
					local msg = sgs.LogMessage()
					msg.type = "#dengjiWake"
					msg.from = player
					msg.to:append(player)
					msg.arg = player:getPile("chu"):length()
					msg.arg2 = self:objectName()
					room:sendLog(msg)
				end

				room:doSuperLightbox("shencaopi","tianxing")

				local id2s = sgs.IntList()
				local n = player:getPile("chu"):length()
				for i = 1, n,1 do
					local ids = player:getPile("chu")
					local id = ids:at(i-1)
					local card = sgs.Sanguosha:getCard(id)
					id2s:append(card:getEffectiveId())
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = id2s
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)

				local choices = {}
				if not player:hasSkill("ol_rende") then
					table.insert(choices, "ol_rende")
				end
				if not player:hasSkill("luanji_po") then
					table.insert(choices, "luanji_po")
				end
				if not player:hasSkill("zhiheng_po") then
					table.insert(choices, "zhiheng_po")
				end

				room:detachSkillFromPlayer(player, "chuyuan")
				if #choices > 0 then
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					room:acquireSkill(player, choice)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_RoundStart)
				and target:hasSkill("tianxing")
				and target:isAlive()
				and (target:getMark("tianxing") == 0)
	end
}

shencaopi:addSkill(chuyuan)
shencaopi:addSkill(dengji)
if not sgs.Sanguosha:getSkill("tianxing") then skills:append(tianxing) end

sgs.LoadTranslationTable{
	["shencaopi"] = "神曹丕",
	["&shencaopi"] = "神曹丕",
	["#shencaopi"] = "詔天仰頌",
	["chuyuan"] = "儲元",
	["chu"] = "儲",
	["#chuyuan"] = "儲元",
	["chuyuan_put"] = "請將一張牌置於 %src 的武將牌上，稱為儲",
	[":chuyuan"] = "每當一名角色受到傷害後，若你的「儲」的數量小於你的體力上限，你可令其摸1張牌，然後其選擇一張手牌置於你的武將牌上，稱為「儲」",
	["dengji"] = "登極",
	[":dengji"] = "覺醒技，回合開始時，若你的儲為3或更多，你獲得所有儲，減少一點體力上限，獲得技能天行，奸雄",
	["tianxing"] = "天行",
	[":tianxing"] = "覺醒技，回合開始時，若你的儲為3或更多，你獲得所有儲，減少一點體力上限，失去技能儲元，選擇獲得以下技能之一：仁德/制衡/亂擊/放權",
	["#dengjiWake"] = "%from 的“儲”為 %arg 張，觸發“%arg2”覺醒",
}

--神甄姬
shenzhenji = sgs.General(extension, "shenzhenji", "god", 3, false)
--神賦
shenfu = sgs.CreateTriggerSkill{
	name = "shenfu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				while (not player:hasFlag("shenfu_end")) do
					room:setPlayerFlag(player, "shenfu_end")
					if player:getHandcardNum() % 2 == 0 then
						local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "shenfu", "@shenfu-chain", true)
						if s then
							room:doAnimate(1, player:objectName(), s:objectName())
							local choice
							if s:isKongcheng() or s:objectName() == player:objectName() then
								choice = "shenfu_draw"
							else
								choice = room:askForChoice(player, self:objectName(), "shenfu_discard+shenfu_draw")
							end
							if choice == "shenfu_discard" then
								local card_id = room:askForCardChosen(player, s, "h", "shenfu")
								room:throwCard(card_id, s, player)
							elseif choice == "shenfu_draw" then
								room:drawCards(s, 1, self:objectName())
							end
							if s:getHandcardNum() == s:getHp() then
								room:setPlayerFlag(player, "-shenfu_end")
							end
						end
					elseif player:getHandcardNum() % 2 == 1 then
						local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "shenfu", "@shenfu-damage", true)
						if s then
							room:broadcastSkillInvoke(self:objectName())
							room:doAnimate(1, player:objectName(), s:objectName())
							room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Thunder))
						end
					end
				end
				room:setPlayerFlag(player, "-shenfu_end")
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if death.damage and death.damage.from then
				if death.damage.from:objectName() == player:objectName() and death.damage.reason and death.damage.reason == self:objectName()  then
					room:setPlayerFlag(player, "-shenfu_end")
				end
			end
		end
	end,
}

qixian = sgs.CreateMaxCardsSkill{
	name = "qixian", 
	frequency = sgs.Skill_Compulsory ,
	fixed_func = function(self, player)
		if player:hasSkill("qixian") then
			return 7
		end
		return -1
	end
}

shenzhenji:addSkill(shenfu)
shenzhenji:addSkill(qixian)

sgs.LoadTranslationTable{
	["shenzhenji"] = "神甄姬",
	["&shenzhenji"] = "神甄姬",
	["#shenzhenji"] = "洛水凌波",
	["shenfu"] = "神賦",
	[":shenfu"] = "回合結束時，如果妳的手牌數量為：奇數，可對一名其他角色造成一點雷電傷害，若造成其死亡，妳可重複此流程；"..
	"偶數，可令一名角色摸一張牌或棄置其一張手牌，若執行後該角色手牌數等於體力數，妳可重複此流程。",
	["@shenfu-chain"] = "妳可令一名角色摸一張牌或棄置其一張手牌",
 	["shenfu_discard"] = "妳棄置其一張手牌",
	["shenfu_draw"] = "摸一張牌",
	["@shenfu-damage"] = "妳可對一名其他角色造成一點雷電傷害",
	["qixian"] = "七弦",
	[":qixian"] = "鎖定技，妳的手牌上限為7",
}

--神張遼
--奪銳：當你於出牌階段內對一名其他角色造成傷害後，若其未因“奪銳”導致技能無效，你可以令該角色的武將牌上的一個
--技能於下回合結束之前無效。若如此做，（在所有結算完成後）你結束出牌階段。
--止啼：鎖定技，你攻擊範圍內已受傷的角色手牌上限-1；若場上受傷角色的數量：不小於1，你的手牌上限+1；不小於3，
--你摸牌階段摸牌數量+1；不小於5，你的回合結束時，廢除一名角色一個隨機的裝備區。

--神張遼
ol_shenzhangliao = sgs.General(extension,"ol_shenzhangliao","god","4",true)

ol_duorui = sgs.CreateTriggerSkill{
	name = "ol_duorui",  
	events = {sgs.Damage, sgs.CardFinished}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and player:getPhase() == sgs.Player_Play and not player:hasFlag("ol_duorui_used") then

				local _data = sgs.QVariant()
				_data:setValue(damage.to)
				if room:askForSkillInvoke(player, self:objectName(), _data) then
					local sks = {}

					local general = sgs.Sanguosha:getGeneral(damage.to:getGeneralName())		
					for _,sk in sgs.qlist(general:getVisibleSkillList()) do
						if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
							if damage.to:hasSkill( sk:objectName() ) then
								table.insert(sks, sk:objectName())
							end
						end
					end

					if damage.to:getGeneral2() then
						local general2 = sgs.Sanguosha:getGeneral(damage.to:getGeneral2Name())
						for _,sk in sgs.qlist(general2:getVisibleSkillList()) do
							if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
								if damage.to:hasSkill( sk:objectName() ) then
									table.insert(sks, sk:objectName())
								end
							end
						end
					end

					if #sks > 0 then
						table.insert(sks, "cancel")
						local skill_choice = room:askForChoice(player,self:objectName(),table.concat(sks, "+"))
						if skill_choice ~= "cancel" then

							local log = sgs.LogMessage()
							log.type = "#Duoruilog"
							log.from = player
							log.to:append(damage.to)
							log.arg = skill_choice
							room:sendLog(log)

							room:addPlayerMark(damage.to, "Duorui_to"..skill_choice)
							room:addPlayerMark(damage.to, "Qingcheng"..skill_choice)
							room:setPlayerFlag(damage.from, "ol_duorui_used")
						end
					end
					
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:hasFlag("ol_duorui_used") then
				room:setPlayerFlag(player, "-ol_duorui_used")
				room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
			end
		end
	end,
}
--[[

function ChooseThrowEquipArea(self, player,cancel,random)
	local room = player:getRoom()
	local abolishlist = {"AbolishWeapon","AbolishArmor","AbolishHorse","AbolishTreasure"}
	local choicelist = {}
	for _,canabolish in pairs(abolishlist) do
		if player:getMark("@"..canabolish) == 0 then
			table.insert(choicelist, canabolish)
		end
	end
	if cancel then
		table.insert(choices, "cancel")
	end
	local choice
	if random then
		choice = choicelist[math.random(1,#choicelist)]
	else
		choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"))
	end
	if choice ~= "cancel" then
		room:setPlayerMark(player,"@"..choice,1)
		return choice
	end
	return -1
end


function throwEquipArea(self ,player, choice)
	local room = player:getRoom()
	room:setPlayerMark(player,"@"..choice,1)
	if choice == "AbolishWeapon" then
		if player:getWeapon() then
			room:moveCardTo(player:getWeapon(), nil, sgs.Player_DiscardPile)
		end
	elseif choice == "AbolishArmor" then

		if player:getArmor() then
			room:moveCardTo(player:getArmor(), nil, sgs.Player_DiscardPile)
		end
	elseif choice == "AbolishHorse" then
		if player:getDefensiveHorse() then
			room:moveCardTo(player:getDefensiveHorse(), nil, sgs.Player_DiscardPile)
		end
		if player:getOffensiveHorse() then
			room:moveCardTo(player:getOffensiveHorse(), nil, sgs.Player_DiscardPile)
		end
	elseif choice == "AbolishTreasure" then
		if player:getTreasure() then
			room:moveCardTo(player:getTreasure(), nil, sgs.Player_DiscardPile)
		end
	end
	local msg = sgs.LogMessage()
	msg.type = "#Abolish1Equip"
	msg.from = player
	msg.to:append(player)
	msg.arg = self:objectName()
	msg.arg2 = choice
	room:sendLog(msg)
end
]]--

ol_zhiti = sgs.CreateTriggerSkill{
	name = "ol_zhiti",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DrawNCards,sgs.EventPhaseChanging,sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data,room)
		local wound_players = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isWounded() then
				wound_players = wound_players + 1
			end
		end
		if event == sgs.DrawNCards then
			if wound_players >= 3 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				local n = data:toInt()
				n = n + 1
				data:setValue(n)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if wound_players >= 5 then
					local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "ol_zhiti", "ol_zhiti_abolish", true, true)
					if s then
						local n = ChooseThrowEquipArea(self, s,false,true,true)
						if n ~= -1 then
							room:sendCompulsoryTriggerLog(player, self:objectName()) 
							throwEquipArea(self,s, n)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if wound_players >= 1 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
				end
			end
		end
	end,
}

ol_zhitiMC = sgs.CreateMaxCardsSkill{
	name = "#ol_zhitiMC", 
	extra_func = function(self, target)
		local extra = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if target:isWounded() and target:inMyAttackRange(p) and p:hasSkill("ol_zhiti") and target:objectName() ~= p:objectName() then
				extra = extra - 1
			end
		end
		local wound_players = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if p:isWounded() then
				wound_players = wound_players + 1
			end
		end
		if wound_players >= 1 and target:hasSkill("ol_zhiti") then
			extra = extra + 1
		end
		return extra
	end
}


ol_shenzhangliao:addSkill(ol_duorui)
ol_shenzhangliao:addSkill(ol_zhiti)
ol_shenzhangliao:addSkill(ol_zhitiMC)
extension:insertRelatedSkills("ol_zhiti","#ol_zhitiMC")

sgs.LoadTranslationTable{
	["ol_shenzhangliao"] = "OL神張遼",
	["&ol_shenzhangliao"] = "神張遼",
	["ol_duorui"] = "奪銳",
	[":ol_duorui"] = "當你於出牌階段內對一名其他角色造成傷害後，若其未因“奪銳”導致技能無效，你可以令該角色的武將牌上的一個"..
"技能於下回合結束之前無效。若如此做，（在所有結算完成後）你結束出牌階段。",
	["ol_zhiti"] = "止啼",
	[":ol_zhiti"] = "鎖定技，你攻擊範圍內已受傷的角色手牌上限-1；若場上受傷角色的數量：不小於1，你的手牌上限+1；不小於3，"..
"你摸牌階段摸牌數量+1；不小於5，你的回合結束時，廢除一名角色一個隨機的裝備區。",
	["ol_zhiti_abolish"] = "你可以廢除一個角色的隨機裝備區",
	["$ol_duorui1"] = "夺敌军锐气，杀敌方士气。",
	["$ol_duorui2"] = "尖锐之势，吾亦可一人夺之。",
	["$ol_zhiti1"] = "江东小儿安敢啼哭？",
	["$ol_zhiti2"] = "娃闻名止啼，孙损十万休！",
	["~ol_shenzhangliao"] = "我也有被孙仲谋所伤之时？",
}

--[[
邢道榮
]]--
xingdaorong = sgs.General(extension, "xingdaorong", "qun2", "5", true)

xuxie = sgs.CreateTriggerSkill{
	name = "xuxie" ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd} ,
	frequency = sgs.Skill_NotFrequent ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:loseMaxHp(player)
					local card = room:askForCard(player, "..", "@xuxie", sgs.QVariant(), sgs.Card_MethodDiscard)
					if not card then
						player:drawCards(1)
					end
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:distanceTo(p) <= 1 then
							room:doAnimate(1, player:objectName(), p:objectName())
							if card then
								if player:canDiscard(p, "he") then
									room:throwCard(room:askForCardChosen(player, p, "he", "xuxie", false, sgs.Card_MethodDiscard), p, player)
								end
							else
								p:drawCards(1)
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				local n = 0
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					n = math.min(n, p:getMaxHp())
				end
				if player:getMaxHp() == n then

					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = player
					msg.arg = 1
					room:sendLog(msg)

					room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+1))
				end
			end
		end
		return false
	end
}

xingdaorong:addSkill(xuxie)

sgs.LoadTranslationTable{
	["xingdaorong"] = "邢道榮",
	["#xingdaorong"] = "零陵上將",
	["xuxie"] = "虛猲",
	[":xuxie"] = "出牌階段開始時，你可以減一點體力上限，令距離1以內的人（包括自己）各摸一張牌或你棄置這些角色各一張牌；出牌階段結束時，若體力上限最小，則加一點體力上限。",
	["@xuxie"] = "你可以棄置一張牌並令棄置距離1以內的角色各一張牌，否則你與這些角色各摸一張牌",
}

--[[
曹爽
【託孤】限定技，一名角色死亡時，你可令其選擇其武將牌上的一個技能（限定、覺醒技、主公技除外），你獲得此技能。

【擅專】 每當你對一名其他角色造成傷害後，若其判定區沒有牌，你可將其手牌或裝備區的一張牌置於其判定區。若此牌不是延時錦囊牌，
那麼紅色牌視為【樂不思蜀】，黑色牌視為【兵糧寸斷】。回合結束時，若你本回合未造成過傷害，你可摸一張牌。

]]--
caoshuang = sgs.General(extension, "caoshuang", "wei2", "4", true)

tuogu = sgs.CreateTriggerSkill{
	name = "tuogu" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then
			local _data = sgs.QVariant()
			_data:setValue(death.who)
			if room:askForSkillInvoke(player, self:objectName(), _data) then
				room:notifySkillInvoked(player, "tuogu")
				room:broadcastSkillInvoke("tuogu")
				room:doSuperLightbox("caoshuang","tuogu")

				local skills = {}

				local general = sgs.Sanguosha:getGeneral(death.who:getGeneralName())		
				for _,sk in sgs.qlist(general:getVisibleSkillList()) do
					if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
						--if death.who:hasSkill( sk:objectName() ) then
							table.insert(skills, sk:objectName())
						--end
					end
				end

				if death.who:getGeneral2() then
					local general2 = sgs.Sanguosha:getGeneral(death.who:getGeneral2Name())
					for _,sk in sgs.qlist(general2:getVisibleSkillList()) do
						if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
							--if death.who:hasSkill( sk:objectName() ) then
								table.insert(skills, sk:objectName())
							--end
						end
					end
				end

				local choice = room:askForChoice(death.who, self:objectName(), table.concat(skills, "+"))

					for _, skill in sgs.qlist(player:getVisibleSkillList()) do
						if player:getMark("tuoguskill"..skill:objectName()) > 0 then
							room:setPlayerMark(player,"tuoguskill"..skill:objectName(),1)
							room:detachSkillFromPlayer(player, skill:objectName(), true)
							room:filterCards(player, player:getCards("h"), true)
						end
					end

				room:handleAcquireDetachSkills(player, choice, false)
				room:setPlayerMark(player,"tuoguskill"..choice,1)				
			end			
			return false
		end
	end,
}

shanzhuan = sgs.CreateTriggerSkill{
	name = "shanzhuan",
	events = {sgs.Damage,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()

			if damage.to and damage.to:isAlive() and damage.to:objectName() ~= player:objectName() and (not damage.to:isNude()) and damage.to:getJudgingArea():isEmpty() then
				local _data = sgs.QVariant()
				_data:setValue(damage.to)
				if room:askForSkillInvoke(player, self:objectName(), _data) then
					local card_id = room:askForCardChosen(player, damage.to, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(card_id)
					if card:isRed() and not card:isKindOf("DelayedTrick") then
						local indulgence = sgs.Sanguosha:cloneCard("indulgence",card:getSuit(),card:getNumber())
						indulgence:setSkillName(self:objectName())
						indulgence:addSubcard(card)
						if not player:isProhibited(damage.to, indulgence) then 
							room:useCard(sgs.CardUseStruct(indulgence, player, damage.to), true)
						else
							indulgence:deleteLater()
						end
					elseif card:isBlack() and not card:isKindOf("DelayedTrick") then
						local shortage = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
						shortage:setSkillName(self:objectName())
						shortage:addSubcard(card)
						if not player:isProhibited(damage.to, shortage) then 
							room:useCard(sgs.CardUseStruct(shortage, player, damage.to), true)
						else
							shortage:deleteLater()
						end
					elseif card:isKindOf("DelayedTrick") then
						room:useCard(sgs.CardUseStruct(card, player, damage.to), true)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:getMark("damage_record-Clear") == 0 then
				player:drawCards(1)
			end
		end
	end
}

caoshuang:addSkill(tuogu)
caoshuang:addSkill(shanzhuan)

sgs.LoadTranslationTable{
	["caoshuang"] = "曹爽",
	["#caoshuang"] = "",
	["tuogu"] = "託孤",
	[":tuogu"] = "一名角色死亡時，你可令其選擇其武將牌上的一個技能（限定、覺醒技、主公技除外），你失去以此法獲得的上一個技能並獲得此技能。",
	["shanzhuan"] = "擅專",
	[":shanzhuan"] = "每當你對一名其他角色造成傷害後，若其判定區沒有牌，你可將其手牌或裝備區的一張牌置於其判定區。若此牌不是延時錦囊牌，那麼紅色牌視為【樂不思蜀】，黑色牌視為【兵糧寸斷】。回合結束時，若你本回合未造成過傷害，你可摸一張牌。",
}

--OL留贊
ol_liuzan = sgs.General(extension, "ol_liuzan", "wu2", "4", true)

ol_fenyin = sgs.CreateTriggerSkill{
	name = "ol_fenyin" ,
	events = {sgs.CardsMoveOneTime} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile and player:getPhase() ~= sgs.Player_NotActive then
				for _, id in sgs.qlist(move.card_ids) do
					if player:getMark("ol_fenyin"..sgs.Sanguosha:getCard(id):getSuit().."-Clear") == 0 then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1)
						room:setPlayerMark(player, "ol_fenyin"..sgs.Sanguosha:getCard(id):getSuit().."-Clear", 1)
					end
				end
			end
		end
		return false
	end
}

function skill(self, room, player, open, n)
	local log = sgs.LogMessage()
	log.type = "#InvokeSkill"
	log.from = player
	log.arg = self:objectName()
	room:sendLog(log)
	room:notifySkillInvoked(player, self:objectName())
	if open then
		if n then
			room:broadcastSkillInvoke(self:objectName(), n)
		else
			room:broadcastSkillInvoke(self:objectName())
		end
	end
end

lijiCard = sgs.CreateSkillCard{
	name = "liji",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	about_to_use = function(self, room, use)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, use.from:objectName(), "", self:objectName(), "")
		room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason, true)
		skill(self, room, use.from, true)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			room:damage(sgs.DamageStruct(self:objectName(), use.from, use.to:first(), 1, sgs.DamageStruct_Normal))
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
lijiVS = sgs.CreateOneCardViewAsSkill{
	name = "liji",
	filter_pattern = ".",
	view_as = function(self, card)
		local first = lijiCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and player:usedTimes("#liji") < player:getMark("liji_canusetime-Clear")
	end
}

liji = sgs.CreateTriggerSkill{
	name = "liji" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = lijiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if room:alivePlayerCount() <= 4 then
					room:setPlayerMark(player, "liji_alivenum-Clear", 4)
				else
					room:setPlayerMark(player, "liji_alivenum-Clear", 8)
				end
			end
		end
		return false
	end
}

ol_liuzan:addSkill(ol_fenyin)
ol_liuzan:addSkill(liji)

sgs.LoadTranslationTable{
["#ol_liuzan"] = "嘯天亢音",
["ol_liuzan"] = "留贊",
["ol_fenyin"] = "奮音",
[":ol_fenyin"] = "鎖定技，當一種花色的牌於你的回合內第一次進入棄牌堆時，你可以摸一張牌。",
["liji"] = "力激",
[":liji"] = "出牌階段限0次，你可以棄置一張牌然後對一名角色造成一點傷害；你的回合內，當進入棄牌堆的牌數達到8的倍數時(4人以下則改成4)；本回合動此技能的次數+1",
}

--何進
ol_hejin = sgs.General(extension, "ol_hejin", "qun2", "4", true)

ol_mouzhuCard = sgs.CreateSkillCard{
	name = "ol_mouzhu",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choicelist1 = {"mouzhu:distance1","mouzhu:same_hp"}
		local choice1 = room:askForChoice(source, "ol_mouzhu1", table.concat(choicelist1, "+"))
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if (source:distanceTo(p) <= 1 and choice1 == "mouzhu:distance1") or (source:getHp() == p:getHp() and choice1 == "mouzhu:same_hp") then
				ChoiceLog(source, choice1)
				if p:isKongcheng() then return end
				local card = nil
				if p:getHandcardNum() > 1 then
					card = room:askForCard(p, ".!", "@mouzhu-give:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if not card then
						card = p:getHandcards():at(math.fmod(math.random(1, p:getHandcardNum())))
					end
				else
					card = p:getHandcards():first()
				end
				if card == nil then return end
				source:obtainCard(card, false)
				if not source:isAlive() or not p:isAlive() then return end
				if source:getHandcardNum() > p:getHandcardNum() then
					local choicelist = {}
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
					duel:setSkillName(self:objectName())
					if not p:isLocked(slash) and p:canSlash(source, slash, false) then
						table.insert(choicelist, "mouzhu:slash")
					end
					if not p:isLocked(duel) and not p:isProhibited(source, duel) then
						table.insert(choicelist, "mouzhu:duel")
					end
					if #choicelist == 0 then return end
					local choice = room:askForChoice(p, self:objectName(), table.concat(choicelist, "+"))
					local use = sgs.CardUseStruct()
					use.from = p
					use.to:append(source)
					if choice == "mouzhu:slash" then
						use.card = slash
					elseif choice == "mouzhu:duel" then
						use.card = duel
					end
					room:useCard(use)
				end
			end
		end
	end,
}
ol_mouzhu = sgs.CreateViewAsSkill{
	name = "ol_mouzhu",
	n = 0,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ol_mouzhu")
	end,
	view_as = function(self, cards)
		return ol_mouzhuCard:clone()
	end,
}

ol_hejin:addSkill(ol_mouzhu)

sgs.LoadTranslationTable{
["#ol_hejin"] = "色厲內荏",
["ol_hejin"] = "何進",
["illustrator:ol_hejin"] = "G.G.G.",
["ol_mouzhu"] = "謀誅",
[":ol_mouzhu"] = "階段技。你可以你距離為1的其他角色或與你體力值相同的其他角色依次執行：交給你一張手牌：若你的手牌多於該角色，該角色選擇一項：視為對你使用一張無距離限制的【殺】，或視為對你使用一張【決鬥】。",
["mouzhu:slash"] = "視為使用一張【殺】",
["mouzhu:duel"] = "視為使用一張【決鬥】",
["mouzhu:distance1"] = "距離為1",
["mouzhu:same_hp"] = "體力值相同",
["@mouzhu-give"] = "請交給 %src 一張手牌",
}

--[[
SP張遼
]]--
sp_zhangliao = sgs.General(extension, "sp_zhangliao", "qun2", "4", true)

function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

mubing = sgs.CreateTriggerSkill{
	name = "mubing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, "mubing")
					room:broadcastSkillInvoke("mubing")
					local card_ids
					if player:getMark("diaoling") > 0 then
						card_ids = room:getNCards(4)
					else
						card_ids = room:getNCards(3)
					end
					room:fillAG(card_ids)

					local dis_cards = room:askForExchange(player, self:objectName(), 5, 0, true,"@mubing")
					if dis_cards and (not dis_cards:getSubcards():isEmpty()) then
						room:throwCard(dis_cards, player, player)
						room:getThread():delay()

						local n = 0
						for _,id in sgs.qlist(dis_cards:getSubcards()) do
							n = n + sgs.Sanguosha:getCard(id):getNumber()
						end


						local to_get = sgs.IntList()
						local to_throw = sgs.IntList()
						while not card_ids:isEmpty() do
							local card_id = room:askForAG(player, card_ids, false, "shelie")
							card_ids:removeOne(card_id)
							to_get:append(card_id)--弃置剩余所有符合花色的牌(原文：throw the rest cards that matches the same suit)
							local card = sgs.Sanguosha:getCard(card_id)
							room:takeAG(player, card_id, false)
							n = n - card:getNumber()

							for i = 0, 4 do--这一句不加的话 涉猎很多牌可能会bug，150可以改，数值越大，越精准，一般和你涉猎的牌数相等是没有bug的
								for _,id in sgs.qlist(card_ids) do
									local c = sgs.Sanguosha:getCard(id)
									if c:getNumber() > n then
										card_ids:removeOne(id)
										room:takeAG(nil, id, false)
										to_throw:append(id)
									end
								end
							end

						end

						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						if not to_get:isEmpty() then
							for _, id in sgs.qlist(to_get) do
								dummy:addSubcard(sgs.Sanguosha:getCard(id))

								local c = sgs.Sanguosha:getCard(id)
								if c:isKindOf("Weapon") or c:isKindOf("Slash")
									or c:isKindOf("Duel")
									or c:isKindOf("FireAttack") or c:isKindOf("SavageAssault")
									or c:isKindOf("ArcheryAttack") or c:isKindOf("Drowning") then
									room:addPlayerMark(player, "@diaoling_card")
								end

							end
							player:obtainCard(dummy)

							if player:getMark("diaoling") > 0 then
								while room:askForYiji(player, to_get, self:objectName(), true, false, true, to_get:length(), room:getAlivePlayers()) do

								end
							end
						end
						dummy:clearSubcards()
						if not to_throw:isEmpty() then
							for _, id in sgs.qlist(to_throw) do
								dummy:addSubcard(sgs.Sanguosha:getCard(id))
							end

							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(),"")
							room:throwCard(dummy, reason, nil)
						end
						dummy:deleteLater()
						room:clearAG()
					end
				end
			end
		end
		return false	
	end
}

ziqu = sgs.CreateTriggerSkill{
	name = "ziqu",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to:getMark("ziqu_invoke") > 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:setPlayerMark(damage.to,"ziqu_invoke",1)
				local log = sgs.LogMessage()
				log.from = player
				log.to:append(damage.to)
				log.arg = self:objectName()
				log.type = "#Yishi"
				room:sendLog(log)
				room:addPlayerMark(player, self:objectName().."engine")
				room:broadcastSkillInvoke(self:objectName())
				if player:getMark(self:objectName().."engine") > 0 then
					local n = 0
					local basic = {}
					for _, hand in sgs.qlist(player:getHandcards()) do
						n = math.max(hand:getNumber() , n)
					end
					room:setPlayerMark(damage.to,"ziqu_number",n)
					local c = room:askForCard(damage.to, ".|.|"..tostring(n).."|.!", "@ziqu", sgs.QVariant(), self:objectName())
					if c then
						player:obtainCard(c)
					end
					room:setPlayerMark(damage.to,"ziqu_number",0)
					room:removePlayerMark(player, self:objectName().."engine")
					return true
				end
			end
		end
		return false
	end
}

diaoling = sgs.CreateTriggerSkill{
	name = "diaoling" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isWounded() then
			if room:askForChoice(player, "zhiji", "recover+draw") == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			else
				room:drawCards(player, 2)
			end
		else
			room:drawCards(player, 2)
		end
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("sp_zhangliao","diaoling")
		room:addPlayerMark(player, "diaoling")
		sgs.Sanguosha:addTranslationEntry(":mubing", ""..string.gsub(sgs.Sanguosha:translate(":mubing"), sgs.Sanguosha:translate(":mubing"), sgs.Sanguosha:translate(":mubing1")))
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("diaoling") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("@diaoling_card") >= 6 or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}

sp_zhangliao:addSkill(mubing)
sp_zhangliao:addSkill(ziqu)
sp_zhangliao:addSkill(diaoling)

sgs.LoadTranslationTable{
["#sp_zhangliao"] = "前將軍",
["sp_zhangliao"] = "SP張遼",
["&sp_zhangliao"] = "張遼",
["illustrator:sp_zhangliao"] = "紫喬",
["mubing"] = "募兵",
[":mubing"] = "出牌階段開始時，你可以展示牌堆頂的3張牌，然後你可棄置任意張手牌，獲得任意張展示的牌（你棄置的牌點數和不得"..
"小於你獲得的牌的點數之和） ，將其餘牌置入棄牌堆。",
[":mubing1"] = "出牌階段開始時，你可以展示牌堆頂的4張牌，然後你可棄置任意張手牌，獲得任意張展示的牌（你棄置的牌點數和不得"..
"小於你獲得的牌的點數之和） ，將其餘牌置入棄牌堆，然後你可將以此法獲得的牌以任意方式交給其他角色。",
["ziqu"] = "資取",
[":ziqu"] = "每名角色限一次，當你對其他角色造成傷害時，你可防止此傷害，令其將一張點數最大的牌交給你。",
["@ziqu"] = "將一張點數最大的牌交給發起者。",
["diaoling"] = "調令",
[":diaoling"] = "覺醒技，回合開始時，若你已以“募兵”獲得了的武器、【殺】或傷害錦囊至少為6張，你回复1點體力或摸兩張牌，並修改“募兵”。",
["@mubing"] = "你可棄置任意張手牌",
}
--曹性
caoxing = sgs.General(extension, "caoxing", "qun2", "4", true)

liushiCard = sgs.CreateSkillCard{
	name = "liushi",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("liushi")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		local move = sgs.CardsMoveStruct(self:getSubcards():first(), source, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, source:objectName(), self:objectName(), ""))
		room:moveCardsAtomic(move, false)

		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("liushi")
				room:useCard(sgs.CardUseStruct(slash, source, targets_list))
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}

liushiVS = sgs.CreateViewAsSkill{
	name = "liushi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local skillcard = liushiCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			return skillcard
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng())
	end
	
}

liushi = sgs.CreateTriggerSkill{
	name = "liushi",
	events = {sgs.Damage},
	view_as_skill = liushiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "liushi" and damage.by_user and not damage.chain and not damage.transfer then
				room:addPlayerMark(damage.to,"@liushi_damage")
			end
		end
		return false
	end	
}

liushiTargetMod = sgs.CreateTargetModSkill{
	name = "#liushiTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "liushi" then
			return 1000
		end
	end,
}

liushiMc = sgs.CreateMaxCardsSkill{
	name = "#liushiMc", 
	frequency = sgs.Skill_Compulsory, 
	extra_func = function(self, target)
		if target:getMark("@liushi_damage") > 0 then
			return -target:getMark("@liushi_damage")
		end
	end
}

zhanwang = sgs.CreateTriggerSkill{
	name = "zhanwang",
	global = true,
	frequency =sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					room:addPlayerMark(player, "zhanwang-Clear", move.card_ids:length())
				end
			else
				if player:getMark("zhanwang-Clear") > 0 and player:getMark("@liushi_damage") > 0 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasSkill("zhanwang") then
							room:doAnimate(1, p:objectName(), player:objectName())
							room:notifySkillInvoked(p, self:objectName())
							room:sendCompulsoryTriggerLog(p, self:objectName()) 
							room:broadcastSkillInvoke(self:objectName())
							room:drawCards(p, player:getMark("zhanwang-Clear"))
						end
					end
					room:setPlayerMark(player, "@liushi_damage" ,0)
				end
			end
		end
	end
}

caoxing:addSkill(liushi)
caoxing:addSkill(liushiTargetMod)
caoxing:addSkill(liushiMc)
caoxing:addSkill(zhanwang)

sgs.LoadTranslationTable{
["caoxing"] = "曹性",
["#caoxing"] = "健兒",
["illustrator:caoxing"] = "",
["liushi"] = "流矢",
["liushi"] = "流矢",
[":liushi"] = "出牌階段，你可以將一張紅桃牌置於牌堆頂，視為對一名角色使用一張【殺】（不計入次數且無距離限制）。"..
"若此【殺】造成傷害，該角色手牌上限-1。",
["@liushi"] = "你可以視為對一名角色使用一張【殺】",
["~liushi"] = "選擇一名角色→點擊確定",
["zhanwang"] = "斬腕",
[":zhanwang"] = "鎖定技，受到『流矢』效果影響的角色若棄牌階段有棄牌，你摸等量的牌，然後移除『流矢』的效果。",
}

--[[
忠鑑 出牌階段限一次，你可以選擇一名角色並選擇一項直到你的下回合開始：1.該角色下次造成傷害後，其棄置兩張牌；2.該角色下次受
到傷害後，該角色摸兩張牌。忠鑑觸發後你摸一張牌。
才識 摸牌階段結束時，若你此階段摸的牌花色相同，則“忠鑑”改為“出牌階段限兩次”，但不能選擇相同的角色；若花色不同，你可以回
复1點體力，然後本回合不能對自己使用牌。
]]--

--辛憲英
ol_xinxianying = sgs.General(extension,"ol_xinxianying","wei2","3",false)
--忠鑑
ol_zhongjianCard = sgs.CreateSkillCard{
	name = "ol_zhongjian",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("ol_zhongjian_target_Play") == 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local choice = room:askForChoice(source, self:objectName(), "ol_zhongjian1+ol_zhongjian2")
			room:setPlayerMark(targets[1],"@"..choice,1)
			room:setPlayerMark(targets[1],"ol_zhongjian_target_Play",1)
			room:setPlayerMark(source,choice..targets[1]:objectName(),1)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
ol_zhongjian = sgs.CreateZeroCardViewAsSkill{
	name = "ol_zhongjian",
	view_as = function()
		return ol_zhongjianCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:getMark("ol_zhongjian_Play") > 0 then
			return player:usedTimes("#ol_zhongjian") < 2
		end
		return not player:hasUsed("#ol_zhongjian")
	end
}

ol_zhongjianing = sgs.CreateTriggerSkill{
	name = "ol_zhongjianing",
	events = {sgs.Damage, sgs.Damaged,sgs.Death,sgs.EventPhaseStart},
	global = true,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			if player:getMark("@ol_zhongjian1") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("ol_zhongjian") and p:getMark("ol_zhongjian1"..player:objectName())  > 0 then
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:askForDiscard(player, "ol_zhongjian", 2, 2, false, false)
						p:drawCards(1)
					end
				end
			end
		elseif event ==  sgs.Damaged then
			if player:getMark("@ol_zhongjian2") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("ol_zhongjian") and p:getMark("ol_zhongjian2"..player:objectName())  > 0 then
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName())
						player:drawCards(2)
						p:drawCards(1)
					end
				end
			end
		elseif event ==  sgs.Death then
			if data:toDeath().who:objectName() == player:objectName() then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("ol_zhongjian1"..p:objectName()) > 0 then
						room:setPlayerMark(p,"@ol_zhongjian1",0)
						room:setPlayerMark(player,"ol_zhongjian1"..p:objectName(),0)
					end
					if player:getMark("ol_zhongjian2"..p:objectName()) > 0 then
						room:setPlayerMark(p,"@ol_zhongjian2",0)
						room:setPlayerMark(player,"ol_zhongjian2"..p:objectName(),0)
					end
				end
			end
		elseif (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark("ol_zhongjian1"..p:objectName()) > 0 then
					room:setPlayerMark(p,"@ol_zhongjian1",0)
					room:setPlayerMark(player,"ol_zhongjian1"..p:objectName(),0)
				end
				if player:getMark("ol_zhongjian2"..p:objectName()) > 0 then
					room:setPlayerMark(p,"@ol_zhongjian2",0)
					room:setPlayerMark(player,"ol_zhongjian2"..p:objectName(),0)
				end
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("ol_zhongjianing") then skills:append(ol_zhongjianing) end--才識
ol_caishi = sgs.CreateTriggerSkill{
	name = "ol_caishi",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_Draw then 
				local move = data:toMoveOneTime()
				local ids = move.card_ids
				if ids:isEmpty() then return false end
				if move.to:objectName() == player:objectName() then
					local suits = {}
					for _,id in sgs.qlist(ids) do
						if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuit()) then
							table.insert(suits, sgs.Sanguosha:getCard(id):getSuit())
						end
					end
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						if #suits == 1 then
							room:addPlayerMark(player, "ol_zhongjian_Play")
						else
							if room:askForSkillInvoke(player, "ol_caishi", data) then
								room:broadcastSkillInvoke(self:objectName(), 1)
								room:recover(player, sgs.RecoverStruct(player))
								room:addPlayerMark(player, "ol_caishi-Clear")
							end
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end

		end
		return false
	end
}
ol_caishiPS = sgs.CreateProhibitSkill{
	name = "#ol_caishiPS" ,
	is_prohibited = function(self, from, to, card)
		return (from:hasSkill("ol_caishi") and (to:getMark("ol_caishi-Clear") > 0) and (not card:isKindOf("SkillCard")))
	end
}


ol_xinxianying:addSkill(ol_zhongjian)
ol_xinxianying:addSkill(ol_caishi)
ol_xinxianying:addSkill(ol_caishiPS)

extension:insertRelatedSkills("ol_caishi","#ol_caishiPS")

sgs.LoadTranslationTable{
	["ol_xinxianying"] = "OL辛憲英",
	["&ol_xinxianying"] = "辛憲英",
	["#ol_xinxianying"] = "名門智女",
	["ol_zhongjian"] = "忠鑑",
	["ol_zhongjianing"] = "忠鑑",
	[":ol_zhongjian"] = "出牌階段限一次，妳可以選擇一名角色並選擇一項直到妳的下回合開始：1.該角色下次造成傷害後，其棄置兩張牌；2.該角色下次受到傷害後，該角色摸兩張牌。忠鑑觸發後妳摸一張牌。",
	["ol_caishi"] = "才識",
	[":ol_caishi"] = "摸牌階段結束時，若你此階段摸的牌花色相同，則“忠鑑”改為“出牌階段限兩次”，但不能選擇相同的角色；若花色不同，你可以回復1點體力，然後本回合不能對自己使用牌。。",

	["ol_zhongjian1"] = "該角色下次造成傷害後，其棄置兩張牌",
	["ol_zhongjian2"] = "該角色下次受到傷害後，該角色摸兩張牌",

	["$ol_zhongjian1"] = "浊世风云变幻，当以明眸洞察。",
	["$ol_zhongjian2"] = "心中自有明镜，可鉴奸佞忠良。",
	["$ol_caishi1"] = "清识难尚，至德可师。",
	["$ol_caishi2"] = "知书达礼，博古通今。",
	["~ol_xinxianying"] = "吾一生明鉴，竟错看于你……",
}
--[[
許劭
]]--
xushao = sgs.General(extension,"xushao","qun2","4",true)

function Getskill_pingjian(zuoci,type_num)
	local room = zuoci:getRoom()
	local all_sks = {}
	local sks = {}
	if type_num == 0 then
		all_sks = {"ol_rende","yijue_po","zhiheng_po","qixi","fanjian","guose",
"jieyin_po","qingnang","lijian","qiangxi_po","quhu","tianyi","luanji_po","dimeng","ol_jiuchi",
"zhijian","sanyao_po","jianyan","ganlu","mingce","xianzhen_po","gongqi","qice","mieji","shenxing",
"ol_mingjian","furong_po",
"ol_anguo","huaiyi_po","qiangwu","mizhao","quji","limu","guolun","ziyuan","shanxi",
"ol_xueji","kuangfu_po","tanbei","lueming","jijie","ol_songci","daoshu","mansi","ol_fenyue","yanjiao",
"gongxin"}
	elseif type_num == 1 then
		all_sks = {"biyue_po","ol_jushou","zuilun_sec_rev","zhengu","olmiji","jingce_po","kunfen","juece","pingkou","bingyi","junbing",
"lua_moshi","ol_youdi","tunjiang","fujian","jujian"}
	elseif type_num == 2 then
		all_sks = {"jianxiong_po","fankui","ganglie","yiji_po","jieming","fangzhu","enyuan_po","zhichi","zhiyu","chengxiang",
"yuce","huituo","yaoming_po","wangxi","benyu","ol_guixin"}
	end

	for _, sk in ipairs(all_sks) do
		if zuoci:getMark("pingjian"..type_num.."_use"..sk) == 0 and not zuoci:hasSkill(sk) then
			table.insert(sks, sk)
		end
	end

	if #sks > 0 then
		local choose_sks = {}
		for i = 1,math.min(3,#sks),1 do 
			local random1 = math.random(1, #sks)
			table.insert(choose_sks, sks[random1])
			table.remove(sks, random1)
		end
	--	table.insert(choose_sks,"cancel")
	--	choose_sks = sks
		local choice = room:askForChoice(zuoci, "choose_skill", table.concat(choose_sks, "+"))	

		if choice ~= "cancel" then		
			room:acquireSkill(zuoci, choice)
			for _, ski2 in sgs.qlist(sgs.Sanguosha:getRelatedSkills(choice)) do
				room:handleAcquireDetachSkills(zuoci,ski2:objectName())
			end

			room:addPlayerMark(zuoci, choice.."_skillClear")
			room:addPlayerMark(zuoci, "pingjian"..type_num.."_use"..choice)
			table.removeOne(choose_sks, choice)
		end
	end
end

pingjianCard = sgs.CreateSkillCard{
	name = "pingjian",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			Getskill_pingjian(source,0)
		end
	end
}
pingjianVS = sgs.CreateZeroCardViewAsSkill{
	name = "pingjian",
	view_as = function(self, cards)
		return pingjianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#pingjian")
	end
}

pingjian = sgs.CreateTriggerSkill{
	name = "pingjian",
	events = {sgs.Damaged,sgs.EventPhaseChanging},
	view_as_skill = pingjianVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				Getskill_pingjian(player,2)
			
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			--[[
			if change.to == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					Getskill_pingjian(player,0)
			
				end
			elseif change.to == sgs.Player_Finish then
			]]--
			if change.to == sgs.Player_Finish then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					Getskill_pingjian(player,1)
			
				end
			end
		end
	end,
	priority = 10000,
}

pingjian_clear = sgs.CreateTriggerSkill{
	name = "pingjian_clear",
	global = true,
	events = {sgs.Damaged,sgs.EventPhaseChanging,sgs.EventPhaseEnd,sgs.CardFinished},
	--view_as_skill = pingjianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			for _, skill in sgs.qlist(player:getSkillList(false, false)) do
				if player:getMark("pingjian2_use"..skill:objectName()) > 0 then
					room:detachSkillFromPlayer(player, skill:objectName(), true)
					room:filterCards(player, player:getCards("h"), true)
					for _, ski in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill)) do
						room:handleAcquireDetachSkills(player,"-"..ski:objectName())
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (use.card:getSkillName() == "ol_rende" or
			  use.card:getSkillName() == "qixi" or
			  use.card:getSkillName() == "luanji_po") and player:getPhase() == sgs.Player_Play then
				if player:getMark("pingjian0_use"..use.card:getSkillName() ) > 0 and player:hasSkill(use.card:getSkillName()) then
					room:detachSkillFromPlayer(player, use.card:getSkillName(), true)
					room:filterCards(player, player:getCards("h"), true)
					for _, ski in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill)) do
						room:handleAcquireDetachSkills(player,"-"..ski:objectName())
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive or change.from == sgs.Player_Play then
				for _, skill in sgs.qlist(player:getSkillList(false, false)) do
					if player:getMark("pingjian1_use"..skill:objectName()) > 0 or player:getMark("pingjian0_use"..skill:objectName()) > 0 then
						room:detachSkillFromPlayer(player, skill:objectName(), true)
						room:filterCards(player, player:getCards("h"), true)
						for _, ski in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill)) do
							room:handleAcquireDetachSkills(player,"-"..ski:objectName())
						end
					end
				end
			end
		end
	end,
	priority = -10000,
	can_trigger = function(self, target)
		return target
	end
}

xushao:addSkill(pingjian)

if not sgs.Sanguosha:getSkill("pingjian_clear") then skills:append(pingjian_clear) end
sgs.LoadTranslationTable{
	["xushao"] = "許劭",
	["#xushao"] = "識人讀心",
	["pingjian"] = "評薦",
	[":pingjian"] = "你可以於以下時機發動“評薦”：出牌階段限一次；結束階段開始時；當你受到傷害後。從你的已開通武將中隨機出現三張擁有此時機可發動技能的武將牌，你選擇其中一個武將並發動其技能。每個技能只能發動一次。",
	["pingjian0_1"] = "出牌階段限一次",
	["pingjian0_2"] = "每階段限一次，當你於出牌階段內",
	["pingjian0_3"] = "階段技",
	["pingjian1_1"] = "結束階段",
	["pingjian1_2"] = "結束階段開始時",
	["pingjian2_1"] = "當你受到傷害",
	["pingjian2_2"] = "當你受到1點傷害",
}

--[[
劉宏 群 4 男 漢靈帝
【鬻爵】
出牌階段限一次，你可以你廢除你的一個裝備欄，然後選擇有手牌的一名其他角色，令其交給你一張手牌，然後其獲得技能“執笏”直到你的下回合開始
（執笏：鎖定技，當你對其他角色造成傷害後，你摸兩張牌（每回合限兩次）。
【圖興】
鎖定技，每當你廢除一個裝備欄時，你加1點體力上限並回復1點體力。你所有裝備欄均廢除後，你減4點體力上限，
然後本局遊戲你造成的傷害+1。
]]--
liuhong = sgs.General(extension,"liuhong","qun2",4)

yujueCard = sgs.CreateSkillCard{
	name = "yujue" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName() and to_select:getHandcardNum() > 0
	end,
	on_use = function(self, room, source, targets)
		local choice = ChooseThrowEquipArea(self, source,false,false)
		throwEquipArea(self,source, choice)
		local card = room:askForCard(targets[1], ".!", "@feijun_give", sgs.QVariant(), sgs.Card_MethodNone)
		if card then
			room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
			room:acquireSkill(targets[1], "zhihu")
		end

	end
}

yujue = sgs.CreateZeroCardViewAsSkill{
	name = "yujue",
	view_as = function(self,cards)
		return yujueCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#yujue") < 1 and not (player:getMark("@AbolishWeapon") > 0 and player:getMark("@AbolishDefensiveHorse") > 0 and player:getMark("@AbolishOffensiveHorse") > 0 and player:getMark("@AbolishTreasure") > 0 and player:getMark("@AbolishArmor") > 0)
	end
}

zhihu = sgs.CreateTriggerSkill{
	name = "zhihu",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if player:getMark("zhihu_invoke-Clear") < 2 then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player,"zhihu_invoke-Clear")
					player:drawCards(2)
				end
			end
		end
		return false
	end
}

zhihu_clear = sgs.CreateTriggerSkill{
	name = "zhihu_clear",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging}, 
	global = true, 
	priority = 9999, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("zhihu") then
						room:detachSkillFromPlayer(p, "zhihu")
					end
				end
			end	
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill("yujue")
	end,
}

tuxing = sgs.CreateTriggerSkill{
	name = "tuxing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data,room)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
				if damage.from:getMark("@tuxing_wake") > 0 then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#Tuxing"
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

liuhong:addSkill(yujue)
liuhong:addSkill(tuxing)

if not sgs.Sanguosha:getSkill("zhihu") then skills:append(zhihu) end
if not sgs.Sanguosha:getSkill("zhihu_clear") then skills:append(zhihu_clear) end
sgs.LoadTranslationTable{
	["liuhong"] = "劉宏",
	["#liuhong"] = "漢靈帝",
	["yujue"] = "鬻爵",
	[":yujue"] = "出牌階段限一次，你可以你廢除你的一個裝備欄，然後選擇有手牌的一名其他角色，令其交給你一張手牌，然後其獲得技能“執笏”直到你的下回合開始。",
	["zhihu"] = "執笏",
	[":zhihu"] = "鎖定技，當你對其他角色造成傷害後，你摸兩張牌（每回合限兩次）。",
	["tuxing"] = "圖興",
	[":tuxing"] = "鎖定技，每當你廢除一個裝備欄時，你加1點體力上限並回復1點體力。你所有裝備欄均廢除後，你減4點體力上限，然後本局遊戲你造成的傷害+1。",
	["#Tuxing"] = "%from 的技能 “<font color=\"yellow\"><b>圖興</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--[[
韓遂 群 4 男 雄踞北疆
【逆亂】 出牌階段，你可以將一張黑色牌當【殺】對體力值大於你的角色使用，若此【殺】沒有造成傷害則不計入使用次數。
【違忤】 出牌階段限一次，你可以將一張紅色牌當【順手牽羊】對手牌數大於你的角色使用。
]]--
ol_hansui = sgs.General(extension,"ol_hansui","qun2",4)

ol_niluanVS = sgs.CreateOneCardViewAsSkill{
	name = "ol_niluan",
	view_filter = function(self, card)
		if not card:isBlack() then return false end
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
}

ol_niluan = sgs.CreateTriggerSkill{
	name = "ol_niluan",
	view_as_skill = ol_niluanVS, 
	events = {sgs.Damage,sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "ol_niluan" then
				room:setCardFlag(damage.card,"ol_niluanFlag")
				room:setPlayerFlag(player,"ol_niluanFlag")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "ol_niluan" then
				if not player:hasFlag("ol_niluanFlag") and not damage.card:hasFlag("ol_niluanFlag") then
					room:addPlayerHistory(player, use.card:getClassName(),-1)
				else
					room:setCardFlag(damage.card,"-ol_niluanFlag")
					room:setPlayerFlag(player,"-ol_niluanFlag")
				end
			end
		end
		return false
	end,
}

ol_niluanPS = sgs.CreateProhibitSkill{
	name = "#ol_niluanPS",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return from:getHp() >= to:getHp() and (card:isKindOf("Slash")) and card:getSkillName() == "ol_niluan"
	end
}

weiwuVS = sgs.CreateOneCardViewAsSkill{
	name = "weiwu", 
	filter_pattern = ".|red",
	view_as = function(self, card) 
		local acard = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
		acard:addSubcard(card:getId())
		acard:setSkillName(self:objectName())
		return acard
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("weiwu-Clear") == 0
	end, 
}

weiwu = sgs.CreateTriggerSkill{
	name = "weiwu",
	view_as_skill = weiwuVS, 
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "weiwu" then
				room:setPlayerMark(player,"weiwu-Clear",1)
			end
		end
		return false
	end,
}

weiwuPS = sgs.CreateProhibitSkill{
	name = "#weiwuPS",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return from:getHandcardNum() >= to:getHandcardNum() and card:getSkillName() == "weiwu"
	end
}

ol_hansui:addSkill(ol_niluan)
ol_hansui:addSkill(ol_niluanPS)
ol_hansui:addSkill(weiwu)
ol_hansui:addSkill(weiwuPS)

sgs.LoadTranslationTable{
	["ol_hansui"] = "韓遂",
	["#ol_hansui"] = "雄踞北疆",
	["ol_niluan"] = "逆亂",
	[":ol_niluan"] = "出牌階段，你可以將一張黑色牌當【殺】對體力值大於你的角色使用，若此【殺】沒有造成傷害則不計入使用次數。",
	["weiwu"] = "違忤",
	[":weiwu"] = "出牌階段限一次，你可以將一張紅色牌當【順手牽羊】對手牌數大於你的角色使用。",
}

--[[
朱儁 群 4 男 徵無遺慮。
【攻堅】 每名角色的回合限一次，當你使用【殺】指定目標後，若此【殺】與上一張【殺】有相同的目標，則你可以棄置其至多兩張牌，並獲得其中的【殺】。
【潰蟒】 鎖定技，一名角色死亡時，若你對其造成過傷害，你摸兩張牌。
]]--
zhujun = sgs.General(extension,"zhujun","qun2",4)

gongjian = sgs.CreateTriggerSkill{
	name = "gongjian" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				if player:getMark("gongjian_target"..p:objectName()) > 0 and player:getMark("gongjian-Clear") == 0 then
					for i= 1,2,1 do
						local _data = sgs.QVariant()
						_data:setValue(p)
						if room:askForSkillInvoke(player, self:objectName(), _data) then
							room:broadcastSkillInvoke(self:objectName())
							if player:canDiscard(p, "he") then
								room:setPlayerMark(player,"gongjian-Clear",1)
								local id = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
									room:obtainCard(id, player)
								else
									room:throwCard(id, p, player)
								end
							end
						else
							break
						end
					end
				end
			end
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "gongjian_target") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
			for _, p in sgs.qlist(use.to) do
				room:setPlayerMark(player,"gongjian_target"..p:objectName(),1)	
			end
		end
	end
}

kuimang = sgs.CreateTriggerSkill{
	name = "kuimang",
	events = {sgs.Damage,sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.damage > 0 then
				room:setPlayerMark(player,"kuimang_target"..damage.to:objectName(),1)
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			if player:isAlive() and player:getMark("kuimang_target"..splayer:objectName()) > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(player, 2, "kuimang")
				
			end
		end
		return false
	end
}

zhujun:addSkill(gongjian)
zhujun:addSkill(kuimang)

sgs.LoadTranslationTable{
	["zhujun"] = "朱儁",
	["#zhujun"] = "徵無遺慮",
	["gongjian"] = "攻堅",
	[":gongjian"] = "每名角色的回合限一次，當你使用【殺】指定目標後，若此【殺】與上一張【殺】有相同的目標，則你可以棄置其至多兩張牌，並獲得其中的【殺】。",
	["kuimang"] = "潰蟒",
	[":kuimang"] = "鎖定技，一名角色死亡時，若你對其造成過傷害，你摸兩張牌。",
}
--[[
丁原 群 4 男 養虎為患
【慈孝】 準備階段，若場上沒有“義子”標記，你可令一名其他角色獲得一個“義子”標記；若場上有“義子”標記，你可以棄置一張牌移動“義子”標記。擁有“義子”標記的角色獲得技能“叛弒”
（叛弒：鎖定技，準備階段，交給有“慈孝”技能的角色一張手牌；你於出牌階段使用的【殺】對其造成的傷害+1且使用【殺】對其造成傷害後結束出牌階段）。
【先率】 鎖定技，有角色造成傷害後，若此傷害是本輪第一次造成傷害，則你摸一張牌；若傷害來源是你，則你對受傷角色再造成1點傷害。
]]--
dingyuan = sgs.General(extension,"dingyuan","qun2",4)

cixiaoCard = sgs.CreateSkillCard{
	name = "cixiao",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:getMark("@yizi") > 0 then
				room:setPlayerMark(p,"@yizi",0)
				room:detachSkillFromPlayer(p, "panshi")
			end
		end
		room:setPlayerMark(targets[1],"@yizi",1)
		room:acquireSkill(targets[1], "panshi")

	end
}
cixiaoVS = sgs.CreateOneCardViewAsSkill{
	name = "cixiao",
	filter_pattern = ".",
	response_pattern = "@@cixiao",
	view_as = function(self, card)
		local skill_card = cixiaoCard:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return false
	end

}

cixiao = sgs.CreateTriggerSkill{
	name = "cixiao",
	view_as_skill = cixiaoVS, 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart then
				local has_yizi_mark = false
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("@yizi") > 0 then
						has_yizi_mark = true
					end
				end
				if has_yizi_mark then
					room:askForUseCard(player, "@@cixiao", "@cixiao")
				else
					local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "cixiao", "cixiao-invoke", true)
					if s then
						room:notifySkillInvoked(player, "cixiao")
						room:doAnimate(1, player:objectName(), s:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerMark(s,"@yizi",1)
						room:setPlayerMark(s,"yizi"..player:objectName(),1)
						room:acquireSkill(s, "panshi")
					end
				end
			end
		end
		return false
	end,
}


panshi = sgs.CreateTriggerSkill{
	name = "panshi",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart,sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("cixiao") then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local to = room:askForPlayerChosen(player, _targets, self:objectName(), "panshi-give", false, true)
					local card = room:askForCard(player, ".!", "@feijun_give", sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, to, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), to:objectName(), self:objectName(), ""))
					end
				end
			end	
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and damage.to:hasSkill("cixiao") then
					room:setPlayerMark(player,"cixiao_invoke-Clear",1)
					room:setCardFlag(damage.card,"cixiao_card")
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#Panshi"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
					room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
				end
			end
			--[[
		elseif  event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:getMark("cixiao_invoke-Clear") > 0 and use.card:hasFlag("cixiao_card") then
				room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
				room:setPlayerFlag(player, "cixiao")
			end
			]]--
		end
	end,
}

xianshuai = sgs.CreateTriggerSkill{
	name = "xianshuai",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("xianshuai") and p:getMark("damage_record_lun") == 0 and damage.reason ~= "xianshuai" then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					p:drawCards(1)
					if p:objectName() == damage.from:objectName() then
						room:getThread():delay()
						room:damage(sgs.DamageStruct(self:objectName(), damage.from, damage.to))
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

dingyuan:addSkill(cixiao)
dingyuan:addSkill(xianshuai)

if not sgs.Sanguosha:getSkill("panshi") then skills:append(panshi) end
sgs.LoadTranslationTable{
	["dingyuan"] = "丁原",
	["#dingyuan"] = "養虎為患",
	["cixiao"] = "慈孝",
	[":cixiao"] = "準備階段，若場上沒有“義子”標記，你可令一名其他角色獲得一個“義子”標記；若場上有“義子”標記，你可以棄置一張牌移動“義子”標記。擁有“義子”標記的角色獲得技能「叛弒」",
	["cixiao-invoke"]= "你可令一名其他角色獲得一個“義子”標記",
	["@cixiao"] = "你可以棄置一張牌移動“義子”標記",
	["panshi"] = "叛弒",
	[":panshi"] = "鎖定技，準備階段，你需交給有“慈孝”技能的角色一張手牌；你於出牌階段使用的【殺】對其造成的傷害+1且使用【殺】對其造成傷害後結束出牌階段",
	["panshi-give"] = "請選擇一名有“慈孝”技能的角色，你需交給其一張手牌",

	["xianshuai"] = "先率",
	[":xianshuai"] = "鎖定技，有角色造成傷害後，若此傷害是本輪第一次造成傷害，則你摸一張牌；若傷害來源是你，則你對受傷角色再造成1點傷害。",
	["@yizi"] = "義子",
	["#Panshi"] = "%from 的技能 “<font color=\"yellow\"><b>叛弒</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--[[
韓馥 群 4 男 度勢恇然
【節應】 結束階段，你可以選擇一名其他角色，該角色下回合使用僅指定一個目標的【殺】或普通錦囊牌無距離限制且可多指定一個目標，且當其造成傷害後，其無法再使用牌直到回合結束。
【危迫】 鎖定技，其他角色使用【殺】或普通錦囊牌指定你為目標後，你將手牌摸至體力上限，然後若此牌結算完畢時，你的手牌數有所減少，你交給使用者一張手牌且此技能失效直到你的下回合開始。 
]]--
hanfu = sgs.General(extension,"hanfu","qun2",4)

hf_jieyingCard = sgs.CreateSkillCard{
	name = "hf_jieying",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("hf_jieying_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "hf_jieying_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets < 1 and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets < 1 and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
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
hf_jieyingVS = sgs.CreateZeroCardViewAsSkill{
	name = "hf_jieying",
	response_pattern = "@@hf_jieying",
	view_as = function()
		return hf_jieyingCard:clone()
	end
}
hf_jieying = sgs.CreateTriggerSkill{
	name = "hf_jieying",
	events = {sgs.PreCardUsed, sgs.Damage,sgs.EventPhaseStart},
	view_as_skill = hf_jieyingVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed and player:getMark("@hf_jieying") > 0 then
			--[[
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:length() == 1 and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification") then
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, self:objectName())
				end
				if use.card:isVirtualCard() then
					room:setPlayerMark(player, "hf_jieying_virtual_card", 1)
					room:setPlayerMark(player, "hf_jieying_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
					room:askForUseCard(player, "@@hf_jieying", "@hf_jieying")
					room:setPlayerMark(player, "hf_jieying_virtual_card", 0)
					room:setPlayerMark(player, "hf_jieying_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
				elseif not use.card:isVirtualCard() then
					room:setPlayerMark(player, "hf_jieying_not_virtual_card", 1)
					room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
					room:askForUseCard(player, "@@hf_jieying", "@hf_jieying")
					room:setPlayerMark(player, "hf_jieying_not_virtual_card", 0)
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
			end
			]]--
		elseif event == sgs.Damage and player:getMark("@hf_jieying") > 0 then
			local damage = data:toDamage()
			if damage.damage and damage.damage > 0 then
				room:addPlayerMark(player, "ban_ur")
				room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", false)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				room:setPlayerMark(player,"@hf_jieying",0)
				if RIGHT(self, player) then
					local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "hf_jieying", "hf_jieying-invoke", true)
					if s then
						room:broadcastSkillInvoke("hf_jieying")
						room:doAnimate(1, player:objectName(), s:objectName())
						room:setPlayerMark(s,"@hf_jieying",1)
					end
				end		
				return false
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

weipo = sgs.CreateTriggerSkill{
	name = "weipo" ,
	events = {sgs.TargetConfirmed,sgs.CardFinished} ,
	frequency= sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and RIGHT(self, player) and player:getMark("@can_not_use_weipo_start") == 0 then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					local n = player:getMaxHp() - player:getHandcardNum()
					if n > 0 then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(n)
						room:setPlayerMark(player,"weipo-invoke",player:getHandcardNum())
						room:setCardFlag(use.card,"weipo_card")
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("weipo_card") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("weipo") and p:getMark("weipo-invoke") > 0 then
						if p:getMark("weipo-invoke") > p:getHandcardNum() then
							local card = room:askForCard(p, ".!", "@feijun_give", sgs.QVariant(), sgs.Card_MethodNone)
							if card then
								room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(), ""))
								room:setPlayerMark(p,"weipo-invoke",player:getHandcardNum())
							end
							room:setPlayerMark(p,"@can_not_use_weipo_start",1)
						end
						room:setPlayerMark(p,"weipo-invoke",0)
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

hf_jieyingTM = sgs.CreateTargetModSkill{
	name = "#hf_jieyingTM" ,
	pattern = "Slash,TrickCard+^DelayedTrick+^IronChain" ,
	distance_limit_func = function(self, from)
		if from:getMark("@hf_jieying") > 0 then
			return 1000
		end
		return 0
	end
}

hanfu:addSkill(hf_jieying)
hanfu:addSkill(hf_jieyingTM)
hanfu:addSkill(weipo)

sgs.LoadTranslationTable{
	["hanfu"] = "韓馥",
	["#hanfu"] = "度勢恇然",
	["hf_jieying"] = "節應",
	[":hf_jieying"] = "結束階段，你可以選擇一名其他角色，該角色下回合使用僅指定一個目標的【殺】或普通錦囊牌無距離限制且可多指定一個目標，且當其造成傷害後，其無法再使用牌直到回合結束。",
	["@hf_jieying"] = "你可以發動“節應”的效果，多指定一個目標",
	["~hf_jieying"] = "選擇目標角色→點“確定”",
	["weipo"] = "危迫",
	[":weipo"] = "鎖定技，其他角色使用【殺】或普通錦囊牌指定你為目標後，你將手牌摸至體力上限，然後若此牌結算完畢時，你的手牌數有所減少，你交給使用者一張手牌且此技能失效直到你的下回合開始。",
	["hf_jieying-invoke"] = "你可以發動“節應”",
}

--[[
王榮 群 3 女 靈懷皇后
【敏思】 出牌階段限一次，你可以棄置任意張點數之和為13的牌，然後摸兩倍數量的牌。以此法獲得的牌中，黑色牌本回合無距離限制，紅色牌本回合不計入手牌上限。
【吉境】 當你受到傷害後，你可以進行一次判定，然後若你棄置任意張點數之和與判定結果點數相同的牌，你回復1點體力。
【追德】 你死亡時，可令一名其他角色摸四張不同牌名的基本牌
]]--
wangrong = sgs.General(extension,"wangrong","qun2",3, false)

minsiCard = sgs.CreateSkillCard{
	name = "minsi" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:drawCards(2*self:getSubcards():length(),"minsi")
	end
}
minsiVS = sgs.CreateViewAsSkill{
	name = "minsi" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected == 0 then
			return true
		elseif #selected > 0 then
			local count = 0
			for i = 1, #selected ,1 do
				local card1 = selected[i]			
				count = count + card1:getNumber()
			end
			if to_select:getNumber() + count <= 13 then
				return true
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
		local card = minsiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self,player)
		return player:usedTimes("#minsi") < 1
	end
}

minsi = sgs.CreateTriggerSkill{
	name = "minsi",
	view_as_skill = minsiVS,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if player:getMark(self:objectName()..id.."-Clear") > 0 and sgs.Sanguosha:getCard(id):isRed() then
						room:setPlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString(), false)
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if player:getMark(self:objectName()..id.."-Clear") > 0 and sgs.Sanguosha:getCard(id):isRed() then
						room:removePlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString().."$0")
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then		
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and not move.card_ids:isEmpty() and move.reason.m_skillName == "minsi" then
				for _, id in sgs.qlist(move.card_ids) do
					room:addPlayerMark(player, "minsi"..id.."-Clear")
				end
			end
			return false
		end
	end
}

minsimc = sgs.CreateMaxCardsSkill{
	name = "#minsimc",
	extra_func = function(self, target)
		local x = 0
		if target:hasSkill("minsi") then
			for _, card in sgs.list(target:getHandcards()) do
				if target:getMark("minsi"..card:getId().."-Clear") > 0 and card:isRed() then
					x = x + 1
				end
				--if target:getMark("andong-Clear") > 0 and card:getSuit() == sgs.Card_Heart and target:getPhase() == sgs.Player_Discard then
				--	x = x + 1
				--end
			end
			return x
		end
	end
}

minsitm = sgs.CreateTargetModSkill{
	name = "#minsitm",
	pattern = ".",
	distance_limit_func = function(self, from, card)
		local n = 0

		if card:isBlack() and from:getMark("minsi"..card:getEffectiveId().."-Clear" ) > 0 then
			n = n + 1000
		end
		return n
	end
}

jijingCard = sgs.CreateSkillCard{
	name = "jijing" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:recover(source, sgs.RecoverStruct(source))
	end,
}
jijingVS = sgs.CreateViewAsSkill{
	name = "jijing" ,
	response_pattern = "@@jijing",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected == 0 then
			return true
		elseif #selected > 0 then
			local count = 0
			for i = 1, #selected ,1 do
				local card1 = selected[i]			
				count = count + card1:getNumber()
			end
			if to_select:getNumber() + count <= sgs.Self:getMark("jijing_judgeresult") then
				return true
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
		if count ~= sgs.Self:getMark("jijing_judgeresult") then return nil end
		local card = jijingCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}

jijing = sgs.CreateTriggerSkill{
	name = "jijing" ,
	events = {sgs.Damaged} ,
	view_as_skill = jijingVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = "."
			judge.play_animation = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			room:setPlayerMark(player,"jijing_judgeresult",judge.card:getNumber())
			if room:askForUseCard(player, "@@jijing", "@jijing-invoke", -1, sgs.Card_MethodDiscard) then
			end
		end
	end
}

zhuide = sgs.CreateTriggerSkill{
	name = "zhuide" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local target = room:askForPlayerChosen(player,room:getAlivePlayers(), "zhuide","zhuide-invoke", true, true)
		if target then
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:doAnimate(1, player:objectName(), target:objectName())
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local basic = {}
			for k=1,4,1 do
				local check = sgs.IntList()
				for _, id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("BasicCard") and not table.contains(basic, TrueName(card)) then
						check:append(id)
					end
				end
				for _, id in sgs.qlist(room:getDiscardPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("BasicCard") and not table.contains(basic, TrueName(card)) then
						check:append(id)
					end
				end
				if not check:isEmpty() then
					local getid = check:at(math.random(0, check:length() - 1))
					local getcard = sgs.Sanguosha:getCard(getid)
					table.insert(basic, TrueName(getcard))
					dummy:addSubcard(getcard:getId())
				end
			end

			dummy:deleteLater()
			target:obtainCard(dummy)
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

wangrong:addSkill(minsi)
wangrong:addSkill(minsimc)
wangrong:addSkill(minsitm)
wangrong:addSkill(zhuide)
wangrong:addSkill(jijing)

sgs.LoadTranslationTable{
	["wangrong"] = "王榮",
	["#wangrong"] = "靈懷皇后",
	["minsi"] = "敏思",
	[":minsi"] = "出牌階段限一次，妳可以棄置任意張點數之和為13的牌，然後摸兩倍數量的牌。以此法獲得的牌中，黑色牌本回合無距離限制，紅色牌本回合不計入手牌上限。",
	["jijing"] = "吉境",
	[":jijing"] = "當你受到傷害後，妳可以進行一次判定，然後若妳棄置任意張點數之和與判定結果點數相同的牌，妳回復1點體力。",
	["~jijing"] = "選擇任意張牌→點擊確定",
	["@jijing-invoke"] = "妳可以棄置任意張點數和與判定結果點數相同的牌，妳回復1點體力",
	["zhuide"] = "追德",
	[":zhuide"] = "妳死亡時，可令一名其他角色摸四張不同牌名的基本牌。",
	["zhuide-invoke"] = "你可以發動“追憶”<br/> <b>操作提示</b>: 選擇一名其他角色→點擊確定<br/>",
}

--[[
劉辯 群	3	男	弘農懷王	
【詩怨】每回合每項限一次，當你成為其他角色使用牌的目標後：1.若其體力值比你多，你摸三張牌；2.若其體力值與你相同，你摸兩張牌；3.若其體力值比你少，你摸一張牌。
【毒逝】鎖定技，你處於瀕死狀態時，其他角色不能對你使用【桃】。你死亡時，你選擇一名其他角色獲得「毒逝」。
備注：若超時未選擇則默認殺死你的角色獲得，若沒有傷害來源則改為隨機獲得。
【余威】主公技，鎖定技，其他群雄角色的回合內，詩怨改為每回合每項限兩次。
]]--
liubian = sgs.General(extension,"liubian$","qun2",3)

shiyuan = sgs.CreateTriggerSkill{
	name = "shiyuan" , 
	frequency= sgs.Skill_Frequent,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if not use.card:isKindOf("SkillCard") then
					if use.from:getHp() > player:getHp() and (player:getMark("shiyuan_1-Clear") == 0 or (player:getMark("shiyuan_1-Clear") < 2 and current:getKingdom() == "qun" and player:hasLordSkill("yuwe"))) then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:addPlayerMark(player,"shiyuan_1-Clear")
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(3)
						end
					elseif use.from:getHp() == player:getHp() and (player:getMark("shiyuan_2-Clear") == 0 or (player:getMark("shiyuan_2-Clear") < 2 and current:getKingdom() == "qun" and player:hasLordSkill("yuwe"))) then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:addPlayerMark(player,"shiyuan_2-Clear")
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(2)
						end
					elseif use.from:getHp() < player:getHp() and (player:getMark("shiyuan_3-Clear") == 0 or (player:getMark("shiyuan_3-Clear") < 2 and current:getKingdom() == "qun" and player:hasLordSkill("yuwe"))) then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:addPlayerMark(player,"shiyuan_3-Clear")
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		end
		return false
	end
}

ol_dushi = sgs.CreateTriggerSkill{
	name = "ol_dushi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches, sgs.QuitDying, sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			if dying.who:hasSkill(self:objectName()) then
				if dying.who:objectName() == player:objectName() then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					local log = sgs.LogMessage()
					log.from = dying.who
					log.arg = self:objectName()
					log.type = "#OlDushi"
					room:sendLog(log)
				end
				if dying.who:objectName() ~= player:objectName() then
					room:setPlayerMark(player, "Global_PreventPeach", 1)
				end
			end
		elseif event == sgs.QuitDying then
			if player:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("Global_PreventPeach") > 0 then
						room:setPlayerMark(p, "Global_PreventPeach", 0)
					end
				end
			end
		end

		if event == sgs.Death then
			local death = data:toDeath()		
			if death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) then

				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("Global_PreventPeach") > 0 then
						room:setPlayerMark(p, "Global_PreventPeach", 0)
					end
				end

				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),"ol_dushi-invoke",true,true)
				if target then
					room:doAnimate(1, player:objectName(), target:objectName())
					room:notifySkillInvoked(player, "ol_dushi")
					room:broadcastSkillInvoke("ol_dushi")
					room:doSuperLightbox("liubian", "ol_dushi")				
					room:handleAcquireDetachSkills(target, "ol_dushi")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


yuwe = sgs.CreateTriggerSkill{
	name = "yuwe$", 
	frequency = sgs.Skill_Compulsory,  
	on_trigger = function()

	end, 
}

liubian:addSkill(shiyuan)
liubian:addSkill(ol_dushi)
liubian:addSkill(yuwe)

sgs.LoadTranslationTable{
	["liubian"] = "劉辯",
	["#liubian"] = "弘農懷王",
	["shiyuan"] = "詩怨",
	[":shiyuan"] = "每回合每項限一次，當你成為其他角色使用牌的目標後：1.若其體力值比你多，你摸三張牌；2.若其體力值與你相同，你摸兩張牌；3.若其體力值比你少，你摸一張牌。",
	["ol_dushi"] = "毒逝",
	[":ol_dushi"] = "鎖定技，你處於瀕死狀態時，其他角色不能對你使用【桃】。你死亡時，你選擇一名其他角色獲得「毒逝」。",
	["#OlDushi"] = "%from 的“%arg”被觸發，只能 %from 自救",
	["ol_dushi-invoke"] = "選擇一名其他角色獲得「毒逝」",
	["yuwe"] = "餘威",
	[":yuwe"] = "主公技，鎖定技，其他群雄角色的回合內，詩怨改為每回合每項限兩次。",
}

--[[
張陵
〖虎騎〗鎖定技，你與其他角色的距離-1，你於回合外受到傷害後進行判定，若結果為紅色，視為你對傷害來源使用一張【殺】。

〖授符〗出牌階段限一次，你可摸一張牌，然後將一張手牌置於一名沒有“籙”的角色的武將牌上，稱為“籙”；其不能使用和打出與“籙”同類型的牌。
該角色受傷時，或於棄牌階段棄置至少2張與“籙”同類型的牌後，將“籙”置入棄牌堆。
]]--
zhangling = sgs.General(extension,"zhangling","qun2",3,true)

huqi = sgs.CreateTriggerSkill{
	name = "huqi",
	events = {sgs.Damaged, sgs.FinishJudge},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:getThread():delay()
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge.card:isRed() then
					if player:canSlash(damage.from, nil, false) then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("_huqi")
						room:useCard(sgs.CardUseStruct(slash, player, damage.from))
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

huqiDistance = sgs.CreateDistanceSkill{
	name = "#huqi",
	frequency = sgs.Skill_Compulsory,
	correct_func = function(self, from, to)
		if from:hasSkill("huqi") then
			return -1
		else
			return 0
		end
	end
}

shoufuCard = sgs.CreateSkillCard{
	name = "shoufu",
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getPile("lu"):isEmpty()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			source:drawCards(1)

			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= source:objectName() and p:getPile("lu"):isEmpty() then
					players:append(p)
				end
			end

			local target = room:askForPlayerChosen(source, players, self:objectName(), "qinqing-invoke", false, true)
			if target then
				local cards = room:askForExchange(source, self:objectName(), 1, 1, true, "@shoufu")
				target:addToPile("lu", cards:getSubcards())
			end
		end
	end
}
shoufuVS = sgs.CreateZeroCardViewAsSkill{
	name = "shoufu",
	view_as = function()
		return shoufuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#shoufu")
	end
}
shoufu = sgs.CreateTriggerSkill{
	name = "shoufu",
	events = {sgs.Damaged,sgs.CardsMoveOneTime},
	view_as_skill = shoufuVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		local invoke = false
		if event == sgs.Damaged then
			invoke = true
		elseif event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_Discard then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					local n = 0
					for _,id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id) and sgs.Sanguosha:getCard(id):getTypeId() == sgs.Sanguosha:getCard(player:getPile("lu"):first()):getTypeId() then
							n = n + 1
						end
					end
					if n >= 2 then
						invoke = true
					end
				end
			end
		end
		if invoke then
			if player:getPile("lu"):length() > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _,cd in sgs.qlist(player:getPile("lu")) do
					dummy:addSubcard(cd)
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", player:objectName(), self:objectName(), "")
				room:throwCard(dummy, reason, nil)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

shoufuPS = sgs.CreateProhibitSkill{
	name = "#shoufuPS",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
			if not card:isKindOf("SkillCard") and from:getPile("lu"):length() > 0 and card:getTypeId() == sgs.Sanguosha:getCard(from:getPile("lu"):first()):getTypeId() then
				return true
			end
		return false
	end
}

zhangling:addSkill(huqi)
zhangling:addSkill(huqiDistance)
zhangling:addSkill(shoufu)
zhangling:addSkill(shoufuPS)

sgs.LoadTranslationTable{
	["zhangling"] = "張陵",
	["#zhangling"] = "五斗米師",
	["huqi"] = "虎騎",
	[":huqi"] = "鎖定技，你與其他角色的距離-1，你於回合外受到傷害後進行判定，若結果為紅色，視為你對傷害來源使用一張【殺】。",
	["shoufu"] = "授符",
	[":shoufu"] = "出牌階段限一次，你可摸一張牌，然後將一張手牌置於一名沒有“籙”的角色的武將牌上，稱為“籙”；其不能使用和打出與“籙”同類型的牌。該角色受傷時，或於棄牌階段棄置至少2張與“籙”同類型的牌後，將“籙”置入棄牌堆。",
	["lu"] = "籙",
	["@shoufu"] = "將一張手牌置於該角色的武將牌上",
}

--[[
郭照 魏	3	女	碧海青天
【偏寵】摸牌階段，你可以改為從牌堆獲得紅牌和黑牌各一張，然後選擇一項直到你的下回合開始：1.你每失去一張紅色牌時摸一張黑色牌，2.你每失去一張黑色牌時摸一張紅色牌。
【尊位】出牌階段限一次，你可以選擇一名其他角色，並選擇執行以下一項，然後移除該選項：
1.將手牌數摸至與該角色相同（最多摸五張），
2.隨機使用牌堆中的裝備牌至與該角色相同，
3.將體力值回復至與該角色相同。
]]--
guozhao = sgs.General(extension,"guozhao","wei2",3,false)

pianchong = sgs.CreateTriggerSkill{
	name = "pianchong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards,sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if room:askForSkillInvoke(player, "pianchong", data) then
				room:broadcastSkillInvoke("pianchong")
				getcolorcard(player,"black",true,false)
				getcolorcard(player,"red",true,false)
				local choices = {"pianchong_red","pianchong_black"}
				local choice = room:askForChoice(player,self:objectName(), table.concat(choices, "+") ,data)
				ChoiceLog(player, choice)
				room:setPlayerMark(player,"@"..choice.."_start",1)
				local count = 0
				data:setValue(count)
			end
			--[[
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:setPlayerMark(player,"pianchong_red",0)
				room:setPlayerMark(player,"pianchong_black",0)
			end
			]]--
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)) then
				for _,fid in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(fid):isRed() and player:getMark("@pianchong_red_start") > 0 then
						getcolorcard(player,"black",true,false)
					end
					if sgs.Sanguosha:getCard(fid):isBlack() and player:getMark("@pianchong_black_start") > 0 then
						getcolorcard(player,"red",true,false)
					end
				end
			end
		end	

	end
}

zunweiCard = sgs.CreateSkillCard{
	name = "zunwei",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self,room,source,targets)
		local choices = {}
		if targets[1]:getHandcardNum() > source:getHandcardNum() and source:getMark("zunwei1") == 0 then
			table.insert(choices, "zunwei1")
		end
		if targets[1]:getHp() > source:getHp() and source:getMark("zunwei2") == 0 then
			table.insert(choices, "zunwei2")
		end
		if targets[1]:getEquips():length() > source:getEquips():length() and source:getMark("zunwei3") == 0 then
			table.insert(choices, "zunwei3")
		end
		if #choices > 0 then
			local choice = room:askForChoice(source,self:objectName(), table.concat(choices, "+"))
			room:setPlayerMark(source,choice,1)

			if choice == "zunwei1" then
				source:drawCards( targets[1]:getHandcardNum() - source:getHandcardNum() )
			end
			if choice == "zunwei2" then

				local n = math.min((targets[1]:getHp() - source:getHp()) , source:getLostHp())
				room:recover(source, sgs.RecoverStruct(source, nil,  n ))
			end
			if choice == "zunwei3" then
				while targets[1]:getEquips():length() > source:getEquips():length() do
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if card:isKindOf("EquipCard") then
								DPHeart:append(id)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
						local get_card = sgs.Sanguosha:getCard(get_id)
						local use = sgs.CardUseStruct()
						use.card = get_card
						use.from = source
						room:useCard(use)
						if targets[1]:getEquips():length() == source:getEquips():length() then
							break
						end
					else
						break
					end
				end
			end
		end
	end
}

zunwei = sgs.CreateViewAsSkill{
	name = "zunwei",
	n = 0,
	view_as = function(self,cards)
		return zunweiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zunwei")
	end
}

guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)

sgs.LoadTranslationTable{
	["guozhao"] = "郭照",
	["#guozhao"] = "碧海青天",
	["pianchong"] = "偏寵",
	[":pianchong"] = "摸牌階段，你可以改為從牌堆獲得紅牌和黑牌各一張，然後選擇一項直到你的下回合開始：1.你每失去一張紅色牌時摸一張黑色牌，2.你每失去一張黑色牌時摸一張紅色牌。",
	["zunwei"] = "尊位",
	[":zunwei"] = "出牌階段限一次，你可以選擇一名其他角色，並選擇執行以下一項，然後移除該選項："..
"1.將手牌數摸至與該角色相同（最多摸五張），"..
"2.隨機使用牌堆中的裝備牌至與該角色相同，"..
"3.將體力值回復至與該角色相同。",

	["pianchong_red"] = "你每失去一張紅色牌時摸一張黑色牌",
	["pianchong_black"] = "你每失去一張黑色牌時摸一張紅色牌。",
	["zunwei1"] = "將手牌數摸至與該角色相同（最多摸五張）",
	["zunwei2"] = "隨機使用牌堆中的裝備牌至與該角色相同",
	["zunwei3"] = "將體力值回復至與該角色相同。",

}

--[[]
臥龍鳳雛  蜀 4體力
游龍：轉換技，陽，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的普通錦囊牌；
陰，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的基本牌。
鸞鳳：限定技，一名角色進入瀕死時，若其體力上限不小於你，你可令其回復至3點體力，恢復其被廢除的裝備欄，
令其手牌補至6-X張（X為以此法恢復的裝備欄數量）。若該角色是你，重置你「游龍」使用過的牌名。
]]--

wolongfengchu = sgs.General(extension,"wolongfengchu","shu2",4,true)

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end
function generateAllCardObjectNameTablePatterns()
	local patterns = {}
	for i = 0, 10000 do
		local card = sgs.Sanguosha:getEngineCard(i)
		if card == nil then break end
		if (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) and not table.contains(patterns, card:objectName()) then
			table.insert(patterns, card:objectName())
		end
	end
	return patterns
end
function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end
local pos = 0
youlong_select = sgs.CreateSkillCard{
	name = "youlong",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
--		for _, name in ipairs(patterns) do
--			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
--			poi:setSkillName("youlong")
--			poi:addSubcard(self:getSubcards():first())
--			if poi:isAvailable(source) and source:getMark("youlong"..name) == 0 and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
--				table.insert(choices, name)
--			end
--		end
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("youlong"..card:objectName()) == 0  and source:getMark("AG_BANCard"..card:objectName()) == 0 and
				  ((card:isKindOf("BasicCard") and source:getMark("@youlong_yang") == 0 and source:getMark("@youlong_yin") == 1) or 
				   (card:isNDTrick() and source:getMark("@youlong_yang") == 1 and source:getMark("@youlong_yin") == 0)) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "youlong", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("youlong")
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "youlongpos", pos)
					room:setPlayerProperty(source, "youlong", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@youlong", "@youlong:"..pattern)--%src
				end
			end
		end
	end
}
youlongCard = sgs.CreateSkillCard{
	name = "youlongCard",
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
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if user:getMark("youlong"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(user, "youlong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:setSkillName("youlong")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if card_use.from:getMark("youlong"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(card_use.from, "youlong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("youlong")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card)	then
				available = false
				break
			end
		end
		if not available then return nil end
		return use_card
	end
}
youlongVS = sgs.CreateViewAsSkill{
	name = "youlong",
	n = 0,
	response_or_use = true,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 0 then
				return youlong_select:clone()
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = youlongCard:clone()
			if pattern and pattern == "@@youlong" then
				pattern = patterns[sgs.Self:getMark("youlongpos")]
				acard:addSubcard(sgs.Self:property("youlong"):toInt())
				if #cards > 0 then return end
			else
				if #cards > 0 then return end
			end
			if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
				pattern = "analeptic"
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		if (player:getMark("@AbolishWeapon") > 0 and player:getMark("@AbolishDefensiveHorse") > 0 and player:getMark("@AbolishOffensiveHorse") > 0 and player:getMark("@AbolishTreasure") > 0 and player:getMark("@AbolishArmor") > 0) then return false end
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) and player:getMark("youlong"..name) == 0 then
				table.insert(choices, name)
			end
		end
		return next(choices) and (player:getMark("youlong_yin_lun") == 0 or player:getMark("youlong_yang_lun") == 0)
	end,
	enabled_at_response = function(self, player, pattern)
		if (player:getMark("@AbolishWeapon") > 0 and player:getMark("@AbolishDefensiveHorse") > 0 and player:getMark("@AbolishOffensiveHorse") > 0 and player:getMark("@AbolishTreasure") > 0 and player:getMark("@AbolishArmor") > 0) then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		for _, p in pairs(pattern:split("+")) do
			if player:getMark(self:objectName()..p) == 0 then
				local poi = sgs.Sanguosha:cloneCard(p, sgs.Card_NoSuit, -1)
				if poi then
					if player:getMark("@youlong_yang") == 0 and player:getMark("@youlong_yin") == 1 and poi:isKindOf("BasicCard") and player:getMark("youlong_yin_lun") == 0 then
						return true
					end
					if player:getMark("@youlong_yang") == 1 and player:getMark("@youlong_yin") == 0 and poi:isNDTrick() and player:getMark("youlong_yang_lun") == 0 then
						return true
					end
				elseif p == "@@youlong" then
					return true
				end
			end
		end
		return false
	end,
	enabled_at_nullification = function(self, player, pattern)
		if (player:getMark("@AbolishWeapon") > 0 and player:getMark("@AbolishHorse") > 0 and player:getMark("@AbolishTreasure") > 0 and player:getMark("@AbolishArmor") > 0) then
			return false
		else
			return player:getMark("youlongnullification") == 0 and player:getMark("@youlong_yang") == 1 and player:getMark("@youlong_yin") == 0 and player:getMark("youlong_yang_lun") == 0
		end
	end
}
youlong = sgs.CreateTriggerSkill{
	name = "youlong",
	view_as_skill = youlongVS,
	events = {sgs.PreCardUsed, sgs.CardResponded,sgs.EventAcquireSkill,sgs.GameStart,sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and not card:isKindOf("SkillCard") and card:getHandlingMethod() == sgs.Card_MethodUse then
				if card:getSkillName() == "youlong" and player:getMark("youlong"..card:objectName()) == 0 then
					room:addPlayerMark(player, "youlong"..card:objectName())
					if player:getMark("@youlong_yang") == 1 and player:getMark("@youlong_yin") == 0 then
						room:addPlayerMark(player, "youlong_yang_lun")
						room:setPlayerMark(player,"@youlong_yang",0)
						room:setPlayerMark(player,"@youlong_yin",1)
						sgs.Sanguosha:addTranslationEntry(":youlong", ""..string.gsub(sgs.Sanguosha:translate(":youlong"), sgs.Sanguosha:translate(":youlong"), sgs.Sanguosha:translate(":youlong2")))
					elseif player:getMark("@youlong_yang") == 0 and player:getMark("@youlong_yin") == 1 then
						room:addPlayerMark(player, "youlong_yin_lun")
						room:setPlayerMark(player,"@youlong_yang",1)
						room:setPlayerMark(player,"@youlong_yin",0)
						sgs.Sanguosha:addTranslationEntry(":youlong", ""..string.gsub(sgs.Sanguosha:translate(":youlong"), sgs.Sanguosha:translate(":youlong"), sgs.Sanguosha:translate(":youlong1")))
					end
					room:setPlayerFlag(player,"abolish_equip")
					local n = ChooseThrowEquipArea(self, player,false,false)
					throwEquipArea(self,player, n)
					room:setPlayerFlag(player,"-abolish_equip")
				end
			end
		end
		if ((event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart) then
			room:setPlayerMark(player,"@youlong_yang",1)
			room:setPlayerMark(player,"@youlong_yin",0)
			sgs.Sanguosha:addTranslationEntry(":youlong", ""..string.gsub(sgs.Sanguosha:translate(":youlong"), sgs.Sanguosha:translate(":youlong"), sgs.Sanguosha:translate(":youlong1")))
			--ChangeCheck(player, "yanyan")
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player,"@youlong_yang",0)
			room:setPlayerMark(player,"@youlong_yin",0)
		end
	end
}

luanfeng = sgs.CreateTriggerSkill{
	name = "luanfeng",
	events = {sgs.EnterDying},
	frequency = sgs.Skill_Limited,
	limit_mark = "@luanfeng",
	on_trigger = function(self, event, player, data, room)
		local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
		room:sortByActionOrder(players)
		for _, p in sgs.qlist(players) do			
			if p:isAlive() and p:getMark("@luanfeng") > 0 and player:getMaxHp() >= p:getMaxHp() then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("wolongfengchu", "luanfeng")
					room:removePlayerMark(p, "@luanfeng")
					room:recover(player, sgs.RecoverStruct(player, nil, 3-player:getHp()  ))

					local  n = 0
					local abolishlist = {"Weapon","Armor","DefensiveHorse","OffensiveHorse","Treasure"}
					local choicelist = {}
					for _,canabolish in pairs(abolishlist) do
						if player:getMark("@Abolish"..canabolish) > 0 then
							n = n + 1
							room:setPlayerMark(player,"@Abolish"..canabolish,0)
						end
					end
					if n > 0 then
						local msg = sgs.LogMessage()
						msg.type = "#RecoverAllEquip"
						msg.from = player
						msg.to:append(player)
						msg.arg = self:objectName()
						room:sendLog(msg)
					end

					if player:getHandcardNum() < (6-n) then
						player:drawCards( 6- n - player:getHandcardNum())
					end

					if p:objectName() == player:objectName() then
						for _, mark in sgs.list(player:getMarkNames()) do
							if string.find(mark, "youlong") and (not string.find(mark, "@youlong")) and player:getMark(mark) > 0 then
								room:setPlayerMark(player, mark, 0)
							end
						end
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

wolongfengchu:addSkill(youlong)
wolongfengchu:addSkill(luanfeng)

sgs.LoadTranslationTable{
	["wolongfengchu"] = "臥龍鳳雛",
	["#wolongfengchu"] = "扭轉乾坤",
	["youlong"] = "游龍",
	[":youlong"] = "轉換技，陽，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的普通錦囊牌；陰，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的基本牌。",

	[":youlong1"] = "轉換技，陽，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的普通錦囊牌；<font color=\" #01A5AF\"><s>陰，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的基本牌。</s></font>。" ,
	[":youlong2"] = "轉換技，<font color=\"#01A5AF\"><s>陽，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的普通錦囊牌</s></font>；陰，每輪限一次，你可以廢除你裝備區里的一個裝備欄，視為使用一張未以此法使用過的基本牌。" ,

	["youlongcard"] = "游龍",
	["@youlong"] = "請選擇目標",
	["~youlong"] = "選擇若干名角色→點擊確定",
	["luanfeng"] = "鸞鳳",
	[":luanfeng"] = "限定技，一名角色進入瀕死時，若其體力上限不小於你，你可令其回復至3點體力，恢復其被廢除的裝備欄，令其手牌補至6-X張（X為以此法恢復的裝備欄數量）。若該角色是你，重置你「游龍」使用過的牌名。",
}

--[[
樊玉鳳 群	 女 紅鸞寡宿

【把盞】轉換技，出牌階段限一次，陽：你可以交給一名其他角色一張手牌；陰：你可以獲得一名其他角色一張手牌。然後若此牌為【酒】或紅桃你可令獲得此牌的角色回復1點體力或復原武將牌。

【醮影】鎖定技，其他角色獲得你的手牌後，該角色本回合不能使用或打出與此牌顏色相同的牌。然後此回合結束時，若其本回合沒有再使用牌，你令一名角色將手牌摸至體力上限（最多摸至五張）。
]]--
fanyufeng = sgs.General(extension,"fanyufeng","qun2","3",false)

bazhanCard = sgs.CreateSkillCard{
	name = "bazhan",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
		not (to_select:isKongcheng() and sgs.Self:getMark("@bazhan_yin") == 1 and sgs.Self:getMark("@bazhan_yang") == 0)
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local invoke = false

			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if source:getMark("@bazhan_yin") == 1 and source:getMark("@bazhan_yang") == 0 then				
				for i = 1,2,1 do
					if not targets[1]:isKongcheng() then
						local id1 = room:askForCardChosen(source, targets[1], "h", self:objectName())
						dummy:addSubcard(id1)
						local card = sgs.Sanguosha:getCard(id1)
						if card:isKindOf("Analeptic") or card:getSuit() == sgs.Card_Heart then
							invoke = true
						end
					end
				end
				if dummy:subcardsLength() > 0 then
					room:obtainCard(source, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName()), false)
				end
				room:setPlayerMark(source,"@bazhan_yang",1)
				room:setPlayerMark(source,"@bazhan_yin",0)
				sgs.Sanguosha:addTranslationEntry(":bazhan", ""..string.gsub(sgs.Sanguosha:translate(":bazhan"), sgs.Sanguosha:translate(":bazhan"), sgs.Sanguosha:translate(":bazhan1")))

			elseif source:getMark("@bazhan_yin") == 0 and source:getMark("@bazhan_yang") == 1 then
				for _, id in sgs.qlist(self:getSubcards()) do
					dummy:addSubcard(id)
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("Analeptic") or card:getSuit() == sgs.Card_Heart then
						invoke = true
					end
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "ziyuan", "")
				room:obtainCard(targets[1], self, reason, false)

				room:setPlayerMark(source,"@bazhan_yang",0)
				room:setPlayerMark(source,"@bazhan_yin",1)
				sgs.Sanguosha:addTranslationEntry(":bazhan", ""..string.gsub(sgs.Sanguosha:translate(":bazhan"), sgs.Sanguosha:translate(":bazhan"), sgs.Sanguosha:translate(":bazhan2")))
			end
			if invoke then

				local choices = {}
				if targets[1]:isWounded() then
					table.insert(choices, "recover")
				end
				if targets[1]:isChained() then
					table.insert(choices, "reset")
				end

				if #choices > 0 then
					table.insert(choices, "cancel")
					local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
					if choice == "recover" then
						ChoiceLog(source, choice)
						room:recover(targets[1], sgs.RecoverStruct(source, nil, 1))
					elseif choice == "reset" then
						ChoiceLog(source, choice)
						room:setPlayerProperty(targets[1], "chained", sgs.QVariant(false))
					end
				end
			end
		end
	end
}
bazhanVS = sgs.CreateViewAsSkill{
	name = "bazhan",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("@bazhan_yin") == 0 and sgs.Self:getMark("@bazhan_yang") == 1 then
			return true
		elseif sgs.Self:getMark("@bazhan_yin") == 1 and sgs.Self:getMark("@bazhan_yang") == 0 then
			return false
		end
	end,
	view_as = function(self, cards)
		if sgs.Self:getMark("@bazhan_yin") == 0 and sgs.Self:getMark("@bazhan_yang") == 1 then
			if #cards > 0 then
				local acard = bazhanCard:clone()
				for _, c in ipairs(cards) do
					acard:addSubcard(c)
				end
				return acard
			end
		elseif sgs.Self:getMark("@bazhan_yin") == 1 and sgs.Self:getMark("@bazhan_yang") == 0 then
			local acard = bazhanCard:clone()
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#bazhan")
	end
}


bazhan = sgs.CreateTriggerSkill{
	name = "bazhan",
	events = {sgs.GameStart,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	view_as_skill = bazhanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart) and player:getMark("@bazhan_yin") == 0 and player:getMark("@bazhan_yang") == 0 then
			room:setPlayerMark(player,"@bazhan_yang",1)
			room:setPlayerMark(player,"@bazhan_yin",0)
			sgs.Sanguosha:addTranslationEntry(":bazhan", ""..string.gsub(sgs.Sanguosha:translate(":bazhan"), sgs.Sanguosha:translate(":bazhan"), sgs.Sanguosha:translate(":bazhan1")))
			--ChangeCheck(player, "ol_xuyou")	
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player,"@bazhan_yin",0)
			room:setPlayerMark(player,"@bazhan_yang",0)
		end
	end,
}


jiaoying = sgs.CreateTriggerSkill{
	name = "jiaoying",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
	--[[
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.from and move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and not move.card_ids:isEmpty() and move.from:hasSkill("jiaoying") then
				local card_fromer
				for _,pp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if move.to:objectName() == pp:objectName() then
						card_fromer = pp
					end
				end
				if move.from_places:contains(sgs.Player_PlaceHand) then
					room:notifySkillInvoked(card_fromer, self:objectName())
					room:sendCompulsoryTriggerLog(card_fromer, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
				end

				for i=0, (move.card_ids:length()-1), 1 do
					local id = move.card_ids:at(i)
					if move.from_places:at(i) == sgs.Player_PlaceHand then
						local card = sgs.Sanguosha:getCard(id)
						room:setPlayerMark(player, "@qianxi_"..GetColor(card), 1)
						room:setPlayerMark(player, "jiaoying_"..GetColor(card), 1)
						room:setPlayerMark(player, "jiaoying_"..move.from:objectName(), 1)
						room:setPlayerCardLimitation(player, "use, response", ".|"..GetColor(card), true)
					end
				end
			end
		end
		]]--

		if event == sgs.CardsMoveOneTime and RIGHT(self, player) then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() ~= player:objectName() and move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
				--[[
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
				]]--

				room:notifySkillInvoked( player , self:objectName())
				room:sendCompulsoryTriggerLog( player , self:objectName())
				room:broadcastSkillInvoke(self:objectName())

				--for i=0, (move.card_ids:length()-1), 1 do
				for _,id in sgs.qlist(move.card_ids) do
					--local id = move.card_ids:at(i)
					--if move.from_places:at(i) == sgs.Player_PlaceHand then
						local card = sgs.Sanguosha:getCard(id)
						room:setPlayerMark(BeMan(room, move.to), "@qianxi_"..GetColor(card), 1)
						room:setPlayerMark(BeMan(room, move.to), "jiaoying_invoke_"..player:objectName().."-Clear", 1)
						if BeMan(room, move.to):getMark("jiaoying_"..GetColor(card)) == 0 then
							room:setPlayerCardLimitation(BeMan(room, move.to), "use, response", ".|"..GetColor(card), true)
						end
						room:setPlayerMark(BeMan(room, move.to), "jiaoying_"..GetColor(card), 1)
					--end
				end
			end
		end

		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("jiaoying_red") > 0 then
						room:setPlayerMark(p,"jiaoying_red",0)
						room:setPlayerMark(p,"@qianxi_red",0)
						room:removePlayerCardLimitation(p, "use,response", ".|red$1")
					end
					if p:getMark("jiaoying_black") > 0 then
						room:setPlayerMark(p,"jiaoying_black",0)
						room:setPlayerMark(p,"@qianxi_black",0)
						room:removePlayerCardLimitation(p, "use,response", ".|black$1")
					end
					for _,pp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if p:getMark("jiaoying_invoke_"..pp:objectName().."-Clear") > 0 and pp:hasSkill("jiaoying") then
							local to = room:askForPlayerChosen(pp, room:getAlivePlayers(), "jiaoying", "jiaoying-invoke", true, true)
							if not to then break end
							local x = 5 - to:getHandcardNum()
							if x <= 0 then
							else
								room:notifySkillInvoked(pp, self:objectName())
								room:doAnimate(1, pp:objectName(), to:objectName())
								to:drawCards(x)
							end

						end
					end
				end
			end
		end
		return false
	end,
}

fanyufeng:addSkill(bazhan)
fanyufeng:addSkill(jiaoying)

sgs.LoadTranslationTable{
	["fanyufeng"] = "樊玉鳳",
	["#fanyufeng"] = "紅鸞寡宿",
	["bazhan"] = "把盞",
	[":bazhan"] = "轉換技，出牌階段限一次，陽：妳可以交給一名其他角色至多兩張手牌；陰：妳可以獲得一名其他角色至多兩張手牌。然後若其中有【酒】或紅桃妳可令獲得此牌的角色回復1點體力或復原武將牌。",

	[":bazhan1"] = "轉換技，出牌階段限一次，陽：妳可以交給一名其他角色至多兩張手牌；<font color=\" #01A5AF\"><s>陰：妳可以獲得一名其他角色至多兩張手牌</s></font>。然後若此牌為【酒】或紅桃妳可令獲得此牌的角色回復1點體力或復原武將牌。" ,
	[":bazhan2"] = "轉換技，出牌階段限一次，<font color=\"#01A5AF\"><s>陽：妳可以交給一名其他角色至多兩張手牌</s></font>；陰：妳可以獲得一名其他角色至多兩張手牌。然後若此牌為【酒】或紅桃妳可令獲得此牌的角色回復1點體力或復原武將牌。",

	["reset"] = "復原武將牌",

	["jiaoying"] = "醮影",
	[":jiaoying"] = "鎖定技，其他角色獲得妳的手牌後，該角色本回合不能使用或打出與此牌顏色相同的牌。然後此回合結束時，若其本回合沒有再使用牌，妳令一名角色將手牌摸至五張。",
	["jiaoying-invoke"] = "令一名角色將手牌摸至五張。",
}

--趙忠
zhaozhong = sgs.General(extension,"zhaozhong","qun2","6",true)

yangzhong = sgs.CreateTriggerSkill{
	name = "yangzhong" ,
	events = {sgs.Damage,sgs.Damaged} ,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.to and damage.from:isAlive() and damage.to:isAlive() and (damage.from:getHandcardNum() + damage.from:getEquips():length()) >= 2 then
			room:setTag("CurrentDamageStruct", data)
			local cards = room:askForExchange(damage.from, self:objectName(), 2, 2, true, "@yangzhong", true)
			if cards then
				room:getThread():delay()
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:doAnimate(1, damage.from:objectName(), damage.to:objectName())
				room:throwCard(cards, damage.from, damage.from)
				room:loseHp(damage.to)
			end
			
			room:removeTag("CurrentDamageStruct")
			return false
		end
	end,
}

huangkong = sgs.CreateTriggerSkill{
	name = "huangkong" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and player:getPhase() == sgs.Player_NotActive and canCauseDamage(use.card) and player:isKongcheng() and use.to:length() == 1 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2)
			end
		end
		return false
	end
}

zhaozhong:addSkill(yangzhong)
zhaozhong:addSkill(huangkong)

sgs.LoadTranslationTable{
	["zhaozhong"] = "趙忠",
	["yangzhong"] = "殃眾",
	[":yangzhong"] = "當你造成或受到傷害後，若受傷角色和傷害來源均存活，則傷害來源可棄置兩張牌，然後令受傷角色失去1點體力。",
	["@yangzhong"] = "你可以棄置兩張牌，令受傷角色失去1點體力。",
	["huangkong"] = "惶恐",
	[":huangkong"] = "鎖定技，當你於回合外成為【殺】或傷害類錦囊牌的唯一目標後，若你沒有手牌，則你摸兩張牌。",
}


--曹嵩
caosong = sgs.General(extension,"caosong","wei2","4",true)

csliluCard = sgs.CreateSkillCard{
	name = "cslilu",
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "cslilu","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		if self:getSubcards():length() > source:getMark("@cslilu") then
			room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1))
			local msg = sgs.LogMessage()
			msg.type = "#GainMaxHp"
			msg.from = source
			msg.arg = 1
			room:sendLog(msg)
			room:recover(source, sgs.RecoverStruct(source, nil, 1))
		end
		room:setPlayerMark(source,"@cslilu",self:getSubcards():length())
	end
}
csliluVS = sgs.CreateViewAsSkill{
	name = "cslilu" ,
	response_pattern = "@@cslilu!",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		return (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = csliluCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}

cslilu = sgs.CreateTriggerSkill{
	name = "cslilu",
	events = {sgs.DrawNCards},
	view_as_skill = csliluVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards and math.min(5,player:getMaxHp()) > player:getHandcardNum() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local count = math.min(5,player:getMaxHp()) - player:getHandcardNum()
				data:setValue(0)
				player:drawCards(count)
				room:askForUseCard(player, "@@cslilu!", "@cslilu", -1)
			end
		end
	end
}

csyizheng = sgs.CreateTriggerSkill{
	name = "csyizheng",
	events = {sgs.PreHpRecover, sgs.ConfirmDamage,sgs.EventPhaseStart},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if player:getMark("@csyizheng") > 0 then
				for _, pp in sgs.qlist(room:getAlivePlayers()) do
					if pp:getMark("csyizheng"..player:objectName().."_target") > 0 and pp:getMaxHp() > player:getMaxHp() then
						room:loseMaxHp(pp)
						room:notifySkillInvoked(pp, self:objectName())
						room:sendCompulsoryTriggerLog(pp, self:objectName()) 
						local log = sgs.LogMessage()
						log.type = "$csyizhengREC"
						log.from = player
						log.to:append(pp)
						room:sendLog(log)
						rec.recover = rec.recover + 1
						data:setValue(rec)						
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if player:getMark("@csyizheng") > 0 then
				for _, pp in sgs.qlist(room:getAlivePlayers()) do
					if pp:getMark("csyizheng"..player:objectName().."_target") > 0 and pp:getMaxHp() > player:getMaxHp() then
						room:loseMaxHp(pp)
						room:notifySkillInvoked(pp, self:objectName())
						room:sendCompulsoryTriggerLog(pp, self:objectName()) 
						local log = sgs.LogMessage()
						log.type = "$csyizhengDMG"
						log.from = player
						log.to:append(pp)
						room:sendLog(log)
						damage.damage = damage.damage + 1
						data:setValue(damage)				
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and RIGHT(self, player) then
				local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "csyizheng", "csyizheng-invoke", true)
				if s then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), s:objectName())
					room:addPlayerMark(player,"csyizheng"..s:objectName().."_target")
					room:addPlayerMark(s,"@csyizheng")
				end
			end
		end
		return false
	end
}

caosong:addSkill(cslilu)
caosong:addSkill(csyizheng)

sgs.LoadTranslationTable{
	["caosong"] = "曹嵩",
	["#caosong"] = "依權弼子",
	["cslilu"] = "禮賂",

	[":cslilu"] = "摸牌階段，你可以放棄摸牌，改為將手牌摸至X張，然後將至少一張手牌交給一名其他角色。若你以此法給出的牌數大於你上次以此法給出的牌數，則你加1點體力上限並回復1點體力。(X為你的體力上限且最多為5)",
	["csyizheng"] = "翊正",
	[":csyizheng"] = "結束階段開始時，你可以選擇一名其他角色。你的下回合開始前，當該角色造成傷害或回復體力時，若其體力上限小於你，則你減1點體力上限，且令此傷害值/回復值+1。",
	["$csyizhengREC"] = "%from 受到 %to 的技能“翊正”影響，回復值+1",
	["$csyizhengDMG"] = "%from 受到 %to 的技能“翊正”影響，傷害值+1",
	["csyizheng-invoke"] = "你可以選擇一名角色發動「翊正」",
	["@cslilu"] = "將至少一張手牌交給一名其他角色",
	["~cslilu"] = "選擇任意張手牌，並選擇一名角色",
}

--夏侯杰
xiahoujie = sgs.General(extension,"xiahoujie","wei2","5",true)

liedan = sgs.CreateTriggerSkill{
	name = "liedan",
	events = {sgs.EventPhaseChanging},
	frequency =sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:objectName() ~= p:objectName() and p:getMark("@zhuangdan") == 0 then
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						local n = 0
						if p:getHandcardNum() > player:getHandcardNum() then
							n = n + 1
						end
						if p:getHp() > player:getHp() then
							n = n + 1
						end
						if p:getEquips():length() > player:getEquips():length() then
							n = n + 1
						end
						if n > 0 then
							p:drawCards(n)
						end
						if n == 3 then
							local msg = sgs.LogMessage()
							msg.type = "#GainMaxHp"
							msg.from = player
							msg.arg = 1
							room:sendLog(msg)
							room:setPlayerProperty(p,"maxhp",sgs.QVariant(p:getMaxHp()+1))
						end

						if n == 0 then
							room:loseHp(p)
							room:addPlayerMark(p,"@liedan_mark")
						end
					end
				end
				if player:hasSkill(self:objectName()) and player:getMark("@liedan_mark") >= 4 and player:getMark("@zhuangdan") == 0 then
					room:killPlayer(player)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

zhuangdan = sgs.CreateTriggerSkill{
	name = "zhuangdan",
	events = {sgs.EventPhaseChanging},
	frequency =sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:objectName() ~= p:objectName() and p:getMark("@zhuangdan") == 0 then
						local player_card = {}
						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							table.insert(player_card, pp:getHandcardNum())
						end
						if p:getHandcardNum() == math.max(unpack(player_card)) then
							room:notifySkillInvoked(p, self:objectName())
							room:sendCompulsoryTriggerLog(p, self:objectName()) 
							room:broadcastSkillInvoke(self:objectName())
							room:addPlayerMark(p,"@zhuangdan")
						end
					end
				end
				if player:hasSkill(self:objectName()) and player:getMark("@zhuangdan") > 0 then
					room:setPlayerMark(player,"@zhuangdan",0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

xiahoujie:addSkill(liedan)
xiahoujie:addSkill(zhuangdan)

sgs.LoadTranslationTable{
["xiahoujie"] = "夏侯杰",
["liedan"] = "裂膽",
[":liedan"] = "鎖定技，其他角色的準備階段開始時，若X大於0，則你摸X張牌。若X等於3，則你加1點體力上限。若X為0，則你失去1點體力並獲得一枚「裂」（X為你的手牌數，體力值，裝備區牌數中大於其的數量）。準備階段，若「裂」數大於4，則你死亡。",
["zhuangdan"] = "壯膽",
["@liedan_mark"] = "裂",
[":zhuangdan"] = "鎖定技，其他角色的回合結束時，若你的手牌數為全場唯一最多，則你令〖裂膽〗失效直到你下回合結束。",
}
--阮瑀
ruanyu = sgs.General(extension,"ruanyu","wei2","3",true)
--興作
xingzuoCard = sgs.CreateSkillCard{
	name = "xingzuo",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if self:getSubcards():length() >= 3 then
			local move = sgs.CardsMoveStruct(self:getSubcards(), source, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, source:objectName(), self:objectName(), ""))
			room:moveCardsAtomic(move, false)

			local card_ids = room:getNCards( self:getSubcards():length() )
			room:askForGuanxing(source, card_ids, sgs.Room_GuanxingDownOnly)
		end
		room:removePlayerMark(source, self:objectName().."engine")

	end
}	
xingzuoVS = sgs.CreateViewAsSkill{
	name = "xingzuo",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected < 3 then
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
		return true
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@xingzuo!" then
			if #cards == 3 then
				local skillcard = xingzuoCard:clone()
				for _, c in ipairs(cards) do
					skillcard:addSubcard(c)
				end
				return skillcard
			end
		end
		return nil
	end,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xingzuo!"
	end
}

xingzuo = sgs.CreateTriggerSkill{
	name = "xingzuo",
	events = {sgs.EventPhaseStart},
	view_as_skill = xingzuoVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					--room:setPlayerFlag(player, "Fake_Move")
					--local _guojia = sgs.SPlayerList()
					--_guojia:append(player)

					local idt = sgs.IntList()
					local drawpiles = sgs.QList2Table(room:getDrawPile())
					drawpiles = sgs.reverse(drawpiles)
					for _, id in ipairs(drawpiles) do
						if idt:length() < 3 then
							idt:append(id)
						end
					end

					local move = sgs.CardsMoveStruct(idt, nil, player,sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
					room:moveCardsAtomic(move, false)
					--local move_to = sgs.CardsMoveStruct(idt, nil, player,sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
					--local moves_to = sgs.CardsMoveList()
					--moves_to:append(move_to)
					--room:notifyMoveCards(true, moves_to, false, _guojia)
					--room:notifyMoveCards(false, moves_to, false, _guojia)
					--room:setPlayerFlag(player, "-Fake_Move")

					room:askForUseCard(player, "@@xingzuo!", "@xingzuo")
					room:setPlayerMark(player,"xingzuo-Clear",1)

				end
			elseif player:getPhase() == sgs.Player_Finish and player:getMark("xingzuo-Clear") > 0 then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHandcardNum() > 0 then _targets:append(p) end
				end
				if not _targets:isEmpty() then
					local target = room:askForPlayerChosen(player, _targets, self:objectName(), "xingzuo-invoke", true, true)
					if target then

						local idt = sgs.IntList()
						local n = room:getDrawPile():length()
						if n > 0 then
							idt:append( room:getDrawPile():at(n) )
						end
						if n > 1 then
							idt:append( room:getDrawPile():at(n-1) )
						end
						if n > 2 then
							idt:append( room:getDrawPile():at(n-2) )
						end

						local n2 = target:handCards():length()
						for _,id in sgs.qlist(target:handCards()) do
							local move = sgs.CardsMoveStruct(id, target, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), ""))
							room:moveCardsAtomic(move, false)

							local card_ids = room:getNCards(1)
							room:askForGuanxing(target, card_ids, sgs.Room_GuanxingDownOnly)
						end

						local move = sgs.CardsMoveStruct(idt, nil, target,sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
						room:moveCardsAtomic(move, false)

						if n2 - idt:length() >= 3 then
							room:loseHp(player)
						end
					end
				end
			end
		end
	end
}

--妙弦
miaoxian_select = sgs.CreateSkillCard{
	name = "miaoxian",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("AG_BANCard"..card:objectName()) == 0 and card:isNDTrick() then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "miaoxian", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("miaoxian")
					poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "miaoxianpos", pos)
					room:setPlayerProperty(source, "miaoxian", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@miaoxian", "@miaoxian:"..pattern)--%src
				end
			end
		end
	end
}
miaoxianCard = sgs.CreateSkillCard{
	name = "miaoxianCard",
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
				if user:getMark("miaoxian"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(user, "miaoxian", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("miaoxian")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if card_use.from:getMark("miaoxian"..name) == 0 then
					table.insert(uses, name)
				end
			end
			local name = room:askForChoice(card_use.from, "miaoxian", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("miaoxian")
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
miaoxianVS = sgs.CreateViewAsSkill{
	name = "miaoxian",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@miaoxian" then
			return false
		else
			return to_select:isBlack()
		end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = miaoxian_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			local acard = miaoxianCard:clone()
			if pattern and pattern == "@@miaoxian" then
				pattern = patterns[sgs.Self:getMark("miaoxianpos")]
				acard:addSubcard(sgs.Self:property("miaoxian"):toInt())
				if #cards ~= 0 then return end
			else
				if #cards ~= 1 then return end
				acard:addSubcard(cards[1]:getId())
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return hasOnlyOneBlackCard(player) and player:getMark("miaoxian-Clear") == 0 
	end,
	enabled_at_nullification = function(self, player)
		return hasOnlyOneBlackCard(player) and player:getMark("miaoxian-Clear") == 0 
	end
}

miaoxian = sgs.CreateTriggerSkill{
	name = "miaoxian",
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	view_as_skill = miaoxianVS,
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
		if card and (not card:isKindOf("SkillCard")) then
			if card:isRed() and hasOnlyOneRedCard(player) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
			elseif card:isBlack() and hasOnlyOneBlackCard(player) and card:getSkillName() == "miaoxian" then
				room:addPlayerMark(player,"miaoxian-Clear")
			end
		end
		return false
	end
}

ruanyu:addSkill(xingzuo)
ruanyu:addSkill(miaoxian)

sgs.LoadTranslationTable{
["ruanyu"] = "阮瑀",
["xingzuo"] = "興作",
[":xingzuo"] = "出牌階段開始時，你可觀看牌堆底的三張牌並用任意張手牌替換其中等量的牌。若如此做，結束階段，你可令一名有手牌的角色用所有手牌替換牌堆底的三張牌。若其因此法失去的牌多於三張，則你失去1點體力。",
["@xingzuo"] = "將三張牌置於牌堆底",
["~xingzuo"] = "點選三張牌-->點擊確定",
["xingzuo-invoke"] = "你可以發動「興作」",
["miaoxian"] = "妙弦",
[":miaoxian"] = "若你的手牌中僅有一張黑色牌，你可將此牌當作任意一張普通錦囊牌使用（每種牌名每回合限一次）；若你的手牌中僅有一張紅色牌，你使用此牌時摸一張牌。",
}


--潘淑
panshu = sgs.General(extension,"panshu","wu2","3",false)

--威儀
-- 每名角色限一次。當有角色受到傷害後，你可選擇：①若其體力值不小於你，則其失去1點體力。②若其體力值不大於你且其已受傷，則其回復1點體力。"

weiyi = sgs.CreateTriggerSkill{
	name = "weiyi", 
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.damage > 0 and player:isAlive() then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:isAlive() and player:getMark("weiyi"..p:objectName()) == 0 then
						local _data = sgs.QVariant()
						_data:setValue(player)
						room:setPlayerFlag(player,"weiyi_target")
						if player:getHp() > p:getHp() then
							if room:askForSkillInvoke(p, "weiyi-lose", _data) then
								room:doAnimate(1, p:objectName(), player:objectName())
								room:broadcastSkillInvoke(self:objectName(),1)
								room:loseHp(player)
								room:addPlayerMark(player,"@weiyi")
								room:addPlayerMark(player,"weiyi"..p:objectName())
							end
						elseif player:getHp() < p:getHp() and player:isWounded() then
							if room:askForSkillInvoke(p, "weiyi-recover", _data) then
								room:doAnimate(1, p:objectName(), player:objectName())
								room:broadcastSkillInvoke(self:objectName(),2)
								room:recover(player, sgs.RecoverStruct(player, nil, 1))
								room:addPlayerMark(player,"@weiyi")
								room:addPlayerMark(player,"weiyi"..p:objectName())
							end
						else
							if room:askForSkillInvoke(p, "weiyi", _data) then
								room:doAnimate(1, p:objectName(), player:objectName())
								local weiyi_choice = room:askForChoice(p, "weiyi", "weiyi_losehp+weiyi_recoverhp",data)
								if weiyi_choice == "weiyi_losehp" then
									room:broadcastSkillInvoke(self:objectName(),1)
									room:loseHp(player)
								elseif weiyi_choice == "weiyi_recoverhp" then
									room:broadcastSkillInvoke(self:objectName(),2)
									room:recover(player, sgs.RecoverStruct(player, nil, 1))
								end
								room:addPlayerMark(player,"@weiyi")
								room:addPlayerMark(player,"weiyi"..p:objectName())
							end
						end	
						room:setPlayerFlag(player,"-weiyi_target")					
					end
				end
			end
		end
	end,
	can_trigger = function()
		return true
	end
}

--錦織
jinzhiCard = sgs.CreateSkillCard{
	name = "jinzhi",
	will_throw = false,
	filter = function(self, targets, to_select)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
				and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = sgs.Self:getTag("jinzhi"):toCard()
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
	end,
	target_fixed = function(self)		
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("jinzhi"):toCard()
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("jinzhi"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_jinzhi = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local jinzhi_list = {}
			table.insert(jinzhi_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(jinzhi_list, "normal_slash")
				table.insert(jinzhi_list, "thunder_slash")
				table.insert(jinzhi_list, "fire_slash")
			end
			to_jinzhi = room:askForChoice(player, "jinzhi_slash", table.concat(jinzhi_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_jinzhi == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_jinzhi == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_jinzhi
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_jinzhi")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_jinzhi
		if user_str == "peach+analeptic" then
			local jinzhi_list = {}
			table.insert(jinzhi_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(jinzhi_list, "analeptic")
			end
			to_jinzhi = room:askForChoice(user, "jinzhi_saveself", table.concat(jinzhi_list, "+"))
		elseif user_str == "slash" then
			local jinzhi_list = {}
			table.insert(jinzhi_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(jinzhi_list, "normal_slash")
				table.insert(jinzhi_list, "thunder_slash")
				table.insert(jinzhi_list, "fire_slash")
			end
			to_jinzhi = room:askForChoice(user, "jinzhi_slash", table.concat(jinzhi_list, "+"))
		else
			to_jinzhi = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_jinzhi == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_jinzhi == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_jinzhi
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_jinzhi")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end
}
jinzhi = sgs.CreateViewAsSkill{
	name = "jinzhi",
	n = 99,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected < (sgs.Self:getMark("@jinzhi_lun") + 1) then
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= (sgs.Self:getMark("@jinzhi_lun") + 1) then return nil end
		local skillcard = jinzhiCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE 
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())

			local isSameColor = true
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
				if card:isRed() ~= cards[1]:isRed() then
					isSameColor = false
				end				
			end
			if isSameColor then
				return skillcard
			end
		end
		local c = sgs.Self:getTag("jinzhi"):toCard()
		if c then
			skillcard:setUserString(c:objectName())


			local isSameColor = true
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
				if card:isRed() ~= cards[1]:isRed() then
					isSameColor = false
				end				
			end
			if isSameColor then
				return skillcard
			end
			
		else
			return nil
		end
	end, 
	enabled_at_play = function(self, player)
		local basic = {"slash", "peach"}
		if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
			table.insert(basic, "thunder_slash")
			table.insert(basic, "fire_slash")
			table.insert(basic, "analeptic")
		end
		for _, patt in ipairs(basic) do
			local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
			if poi and poi:isAvailable(player) and not(patt == "peach" and not player:isWounded()) then
				return true
			end
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if string.startsWith(pattern, ".") or string.startsWith(pattern, "@") then return false end
		if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
		return pattern ~= "nullification"
	end
}
jinzhi:setGuhuoDialog("l")


panshu:addSkill(weiyi)
panshu:addSkill(jinzhi)

sgs.LoadTranslationTable{
["panshu"] = "潘淑",
["weiyi"] = "威儀",
[":weiyi"] = "每名角色限一次。當有角色受到傷害後，你可選擇：①若其體力值不小於你，則其失去1點體力。②若其體力值不大於你且其已受傷，則其回復1點體力。",
["weiyi_losehp"] = "令其失去1點體力",
["weiyi_recoverhp"] = "令其恢復1點體力",
["weiyi-lose"] = "威儀掉血",
["weiyi-recover"] = "威儀回血",
["jinzhi"] = "錦織",
[":jinzhi"] = "當你需要使用或打出一張基本牌時，你可棄置X張牌並摸一張牌。若你以此法棄置的牌均為同一顏色，則視為你使用或打出了此牌。",
}

--黃祖
huangzu = sgs.General(extension,"huangzu","qun2","4",true)
--輓弓
wangong = sgs.CreateTriggerSkill{
	name = "wangong" ,
	events = {sgs.PreCardUsed,sgs.DamageCaused,sgs.CardFinished} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (not use.card:isKindOf("SkillCard")) then
				if use.card:isKindOf("BasicCard") then
					room:setPlayerMark(player,"@wangong_use",1)
				else
					room:setPlayerMark(player,"@wangong_use",0)
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("BasicCard") and player:getMark("@wangong_use") > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:setCardFlag(use.card,"wangong_use_card")
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and damage.card:hasFlag("wangong_use_card") then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#Wangong"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == "wangong" then
				room:setPlayerMark(player,"@wangong_use",0)
			end
		end
	end
}
wangongTargetMod = sgs.CreateTargetModSkill{
	name = "#wangongTargetMod",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("wangong") and player:getMark("@wangong_use") > 0 then
			return 1000
		end
	end,
	residue_func = function(self, player, card)
		if player:hasSkill("wangong") and player:getMark("@wangong_use") > 0 then
			return 1000
		end
	end,
}

huangzu:addSkill(wangong)
huangzu:addSkill(wangongTargetMod)

sgs.LoadTranslationTable{
["huangzu"] = "黃祖",
["wangong"] = "輓弓",
[":wangong"] = "鎖定技，當你使用基本牌時，你獲得如下效果：當你使用下一張牌時，若此牌為【殺】，則此牌無次數和距離限制且傷害+1。",
["#Wangong"] = "%from 的技能 “<font color=\"yellow\"><b>輓弓</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}



--[[
黃承彥 群 3體力
觀虛 出牌階段限一次，你可觀看一名其他角色的手牌，然後你可將其中一張手牌與牌堆頂5張牌中的一張交換。若如此做，你棄置其手牌中3張花色相同的牌。
雅士 每當你受到一次傷害後，你可選擇一項：1.令傷害來源的非鎖定技無效直到其下個回合開始2.對一名其他角色發動【觀虛】
]]--

huangchengyan = sgs.General(extension,"huangchengyan","qun2","3",true)

--觀虛
guanxuCard = sgs.CreateSkillCard{
	name = "guanxu",
	will_throw = false,
	filter = function(self, targets, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@guanxu" or sgs.Sanguosha:getCurrentCardUsePattern() == "@guanxu_less" then
			return #targets < 0
		end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@guanxu" or sgs.Sanguosha:getCurrentCardUsePattern() == "@guanxu_less" then
			return #targets == 0
		end
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@guanxu" then
			for _,id in sgs.qlist(self:getSubcards()) do
				room:setCardFlag(sgs.Sanguosha:getCard(id), "guanxu")
			end
		else
			if targets[1] then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(source, self:objectName().."engine")
				if source:getMark(self:objectName().."engine") > 0 then
					local ids = sgs.IntList()
					
					room:showAllCards(targets[1], source)

					local ids = room:getNCards(5, false)
					room:fillAG(ids)
					room:getThread():delay()
					local card_id = room:askForAG(source, ids, false, self:objectName())
					room:clearAG()
					local card = sgs.Sanguosha:getCard(card_id)
					room:obtainCard(targets[1], card, true)

					local ids = sgs.IntList()
					for _, card in sgs.qlist(targets[1]:getHandcards()) do
						ids:append(card:getEffectiveId())
					end

					--置於牌堆頂部分
					local card_id = room:doGongxin(source, targets[1], ids)
					if (card_id == -1) then return end
					source:setFlags("Global_GongxinOperator")
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), nil, "guanxu", nil)
					room:moveCardTo(sgs.Sanguosha:getCard(card_id), targets[1], nil, sgs.Player_DrawPile, reason, true)
					source:setFlags("-Global_GongxinOperator")
			

					--棄牌部分
					for _,id in sgs.qlist(targets[1]:handCards()) do
						room:setCardFlag(sgs.Sanguosha:getCard(id), "guanxu_target_card")
					end
					local ids = targets[1]:handCards()
					room:setPlayerFlag(source, "Fake_Move")
					local _guojia = sgs.SPlayerList()
					_guojia:append(source)
					local move = sgs.CardsMoveStruct(ids, targets[1], source, sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
					local moves = sgs.CardsMoveList()
					moves:append(move)
					room:notifyMoveCards(true, moves, false, _guojia)
					room:notifyMoveCards(false, moves, false, _guojia)
					local invoke = room:askForUseCard(source, "@guanxu", "@guanxu")			
					local idt = sgs.IntList()

					for _,id in sgs.qlist(targets[1]:handCards()) do
						if ids:contains(id) then
							idt:append(id)
						end
					end
					local move_to = sgs.CardsMoveStruct(idt, source, targets[1], sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
					local moves_to = sgs.CardsMoveList()
					moves_to:append(move_to)
					room:notifyMoveCards(true, moves_to, false, _guojia)
					room:notifyMoveCards(false, moves_to, false, _guojia)
					room:setPlayerFlag(source, "-Fake_Move")
					if invoke then
						local dummy = sgs.Sanguosha:cloneCard("slash")
						for _,id in sgs.qlist(targets[1]:handCards()) do
							if sgs.Sanguosha:getCard(id):hasFlag("guanxu") then
								dummy:addSubcard(id)
							end
						end
						if dummy:subcardsLength() > 0 then
							room:throwCard(dummy, targets[1], source)
						end
					end
					room:removePlayerMark(source, self:objectName().."engine")
				end
			end
		end
	end
}	
guanxu = sgs.CreateViewAsSkill{
	name = "guanxu",
	n = 3,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@guanxu" then
			for _,c in sgs.list(selected) do
				if c:getSuit() ~= to_select:getSuit() or not to_select:hasFlag("guanxu_target_card") then return false end
			end
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select) and to_select:hasFlag("guanxu_target_card")
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@guanxu" then
			if #cards ~= 3 then return nil end
			local skillcard = guanxuCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			return skillcard
		else
			if #cards ~= 0 then return nil end
			return guanxuCard:clone()
		end
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#guanxu")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@guanxu" or pattern == "@@guanxu_invoke"
	end
}

yashi = sgs.CreateTriggerSkill{
	name = "yashi",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local choices = {"yashi2"}
			if damage.from and damage.from:isAlive() then
				table.insert(choices, "yashi1")
			end
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"),data)
			room:broadcastSkillInvoke(self:objectName(),1)
			if choice == "yashi1" then
				room:setPlayerMark(damage.from, "skill_invalidity-turnclear",1)
				room:setPlayerMark(damage.from, "@skill_invalidity",1)
			else
				room:askForUseCard(player, "@@guanxu_invoke", "@guanxu_invoke", -1)
			end
		end
	end,
}

huangchengyan:addSkill(guanxu)
huangchengyan:addSkill(yashi)


sgs.LoadTranslationTable{
["huangchengyan"]="黃承彥",
["guanxu"] = "觀虛",
[":guanxu"] = "出牌階段限一次，你可觀看一名其他角色的手牌，然後你可將其中一張手牌與牌堆頂5張牌中的一張交換。若如此做，你棄置其手牌中3張花色相同的牌。",
["yashi"] = "雅士",
[":yashi"] = "每當你受到一次傷害後，你可選擇一項：1.令傷害來源的非鎖定技無效直到其下個回合開始；2.對一名其他角色發動【觀虛】",
["yashi1"] = "令傷害來源的非鎖定技無效直到其下個回合開始",
["yashi2"] = "對一名其他角色發動【觀虛】",
["@guanxu"] = "你可以發動“觀虛”",
["@guanxu_invoke"] = "你可以發動“觀虛”",
["~yashi"] = "選擇你要對其發動“觀虛”的角色->點選確定",
["@guanxu_less"] = "你可以發動“觀虛”",
["~guanxu"] = "選擇三張花色相同的手牌→點擊確定",
["~guanxu_less"] = "點擊技能→點擊確定",

}

--[[
華歆  淵清玉潔

【望歸】	每回合限觸發一次，當你造成或受到傷害後，若你未發動過「息兵」，你可對一名其他角色造成1點傷害；
若你發動過「息兵」，你可令至多三名角色各摸一張牌。
【息兵】	當一名其他角色在其出牌階段內使用第一張黑色【殺】或黑色普通錦囊牌指定唯一角色為目標後，你可令該角色將手牌
摸至當前體力值且本回合不能再使用手牌。
]]--
huaxin = sgs.General(extension, "huaxin", "wei", 3, true)

--望歸
wanggui = sgs.CreateTriggerSkill{
	name = "wanggui", 
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage and player:getMark("wanggui-Clear") == 0 then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getKingdom() ~= p:getKingdom() then _targets:append(p) end
			end
			local s = room:askForPlayerChosen(player, _targets, "wanggui1", "@wanggui-damage", true)
			if s then
				room:getThread():delay()
				room:setPlayerMark(player,"wanggui-Clear",1)
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), s:objectName())
				room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))
			end

		elseif event == sgs.Damaged then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getKingdom() == p:getKingdom() then _targets:append(p) end
			end
			local s = room:askForPlayerChosen(player, _targets, "wanggui2", "@wanggui-draw", true)
			if s then
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), s:objectName())
				s:drawCards(1)
				if s:objectName() ~= player:objectName() then
					player:drawCards(1)
				end
			end
		end
		return false
	end
}

heg_xibing = sgs.CreateTriggerSkill{
	name = "heg_xibing" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if use.card then
				if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.card:isBlack() and player:getPhase() == sgs.Player_Play and player:getHp() > player:getHandcardNum() then
					if use.to:length() == 1 then
						local players = room:findPlayersBySkillName(self:objectName())
						room:sortByActionOrder(players)
						for _, p in sgs.qlist(players) do
							if p:objectName() ~= player:objectName() then
								local _data = sgs.QVariant()
								_data:setValue(player)
								if room:askForSkillInvoke(p, self:objectName(), _data) then
									room:broadcastSkillInvoke(self:objectName())
									room:doAnimate(1, p:objectName(), player:objectName())
									local n = player:getHp() - player:getHandcardNum()
									if n > 0 then
										player:drawCards(n)
										room:addPlayerMark(player, "ban_ur")
										room:setPlayerCardLimitation(player, "use,response", ".|.|.|hand", false)
									end
								end
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

huaxin:addSkill(wanggui)
huaxin:addSkill(heg_xibing)

sgs.LoadTranslationTable{
	["huaxin"] = "華歆",
	["#huaxin"] = "淵清玉潔",
	["wanggui"] = "望歸",
	["wanggui1"] = "望歸",
	["wanggui2"] = "望歸",
	["@wanggui-damage"] = "你可以對與你勢力不同的一名角色造成1點傷害",
	["@wanggui-draw"] = "你可令你勢力相同的一名角色摸一張牌",
	[":wanggui"] = "當你造成傷害後，你可以對與你勢力不同的一名角色造成1點傷害（每回合限一次）；當你受到傷害後，你可令你勢力相同的一名角色摸一張牌，若該角色不是你，你也摸一張牌。",
	["heg_xibing"] = "息兵",
	[":heg_xibing"] = "一名其他角色在其出牌階段內使用黑色【殺】或黑色普通錦囊牌指定唯一角色為目標後，你可令該角色將手牌摸至當前體力值。若其因此摸牌，其本回合不能再使用手牌。",
	["@wanggui-card"] = "你可以令至多三名角色摸一張牌",
	["@wanggui-damage"] = "對一名角色造成一點傷害",
}

--[[
陸郁生 義姑
]]--
luyusheng = sgs.General(extension, "luyusheng", "wu",3,false)

zhente = sgs.CreateTriggerSkill{
	name = "zhente",
	global = true,
	events = {sgs.TargetConfirmed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and player:hasSkill("zhente") then
				if (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						local choice = room:askForChoice(use.from, "zhente", "zhente1+zhente2")
						if choice == "zhente1" then
							room:setPlayerMark(use.from, "@qianxi_"..GetColor(use.card), 1)
							room:setPlayerMark(use.from, "zhente"..GetColor(use.card), 1)
							room:setPlayerCardLimitation(use.from, "use, response", ".|"..GetColor(use.card), true)
						end
						if choice == "zhente2" then
							player:setFlags("-ZhenlieTarget")
							player:setFlags("ZhenlieTarget")
							if player:isAlive() and player:hasFlag("ZhenlieTarget") then
								player:setFlags("-ZhenlieTarget")
								local nullified_list = use.nullified_list
								table.insert(nullified_list, player:objectName())
								use.nullified_list = nullified_list
								data:setValue(use)
							end
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("zhente_red") > 0 then
						room:setPlayerMark(p,"zhente_red",0)
						room:setPlayerMark(p,"@qianxi_red",0)
					elseif p:getMark("zhente_black") > 0 then
						room:setPlayerMark(p,"zhente_black",0)
						room:setPlayerMark(p,"@qianxi_black",0)
					end
				end
			end
		end
		return false
	end,
}

zhiwei = sgs.CreateTriggerSkill{
	name = "zhiwei",
	events = {sgs.Damaged, sgs.Damage,sgs.CardsMoveOneTime,sgs.Death,sgs.GameStart,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and RIGHT(self, player) then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "zhiwei-invoke", false,true)
			if to then
				room:doAnimate(1, player:objectName(), to:objectName())
				room:doSuperLightbox("luyusheng","zhiwei")
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:addPlayerMark(to, "@zhiwei_target")
				room:addPlayerMark(to, "zhiwei_target"..player:objectName() )
			end
		elseif event == sgs.CardsMoveOneTime and RIGHT(self, player) then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_Discard then
				local ids = sgs.IntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						ids:append(card_id)
					end
				end
				if ids:length() > 0 then
					local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _,cid in sgs.qlist(ids) do
						dummy:addSubcard(cid)
					end
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("zhiwei_target"..player:objectName()) > 0 and p:isAlive() then
							room:obtainCard(p,dummy, true)
							break
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart and RIGHT(self, player) and player:getMark("zhiwei-rechoose") > 0 then
			room:setPlayerFlag(player,"zhiwei_rechoose")
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "zhiwei-invoke", true,true)
			room:setPlayerFlag(player,"-zhiwei_rechoose")
			room:setPlayerMark(player,"zhiwei-rechoose",0)
			if to then
				room:doAnimate(1, player:objectName(), to:objectName())
				room:doSuperLightbox("luyusheng","zhiwei")
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:addPlayerMark(to, "@zhiwei_target")
				room:addPlayerMark(to, "zhiwei_target"..player:objectName() )
			end
		elseif event == sgs.Death and RIGHT(self, player) then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			if player:isAlive() and splayer:getMark("zhiwei_target"..player:objectName()) > 0 then
				room:setPlayerMark(player,"zhiwei-rechoose",1)
			end
		elseif event == sgs.Damaged or event == sgs.Damage then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark("zhiwei_target"..p:objectName()) > 0 and player:isAlive() then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					if event == sgs.Damaged then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						--room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
						local loot_cards = sgs.QList2Table(p:getCards("h"))
						if #loot_cards > 0 then
							room:throwCard(loot_cards[math.random(1, #loot_cards)],p, p)
						end
					elseif event == sgs.Damage then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						--room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
						p:drawCards(1)
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

luyusheng:addSkill(zhente)
luyusheng:addSkill(zhiwei)

sgs.LoadTranslationTable{
	["luyusheng"] = "陸郁生",
	["#luyusheng"] = "義姑",
	["zhente"] = "貞特",
	[":zhente"] = "每名角色的回合限一次，當妳成為其他角色使用基本牌或普通錦囊牌的目標後，妳可令使用者選擇一項：1.本回合不能再使用此顏色的牌；2.此牌對妳無效。",
	["zhente1"] = "本回合不能再使用此顏色的牌",
	["zhente2"] = "此牌對發起者無效。",
	["zhiwei"] = "至微",
	[":zhiwei"] = "遊戲開始時，妳選擇一名其他角色。該角色造成傷害後，妳摸一張牌，該角色受到傷害後，妳隨機棄置一張手牌。妳棄牌階段棄置的牌均被該角色獲得。若該角色死亡時，妳可以於回合開始時重新選擇一名其他角色。",
	["zhiwei-invoke"] = "選擇一名角色對其發動「至微」",
}

--唐姬
tangji = sgs.General(extension,"tangji","qun2",3,false)

kangge = sgs.CreateTriggerSkill{
	name = "kangge",
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime,sgs.EnterDying,sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Start and player:getMark("turn") == 1 then
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kangge-invoke", true,true)
				if to then
					room:notifySkillInvoked(player,self:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					room:doSuperLightbox("tangji","kangge")
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:addPlayerMark(to, "@kangge")
						room:addPlayerMark(to, "kangge"..player:objectName())
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and player:getPhase() == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("kangge"..p:objectName()) > 0  and p:getMark("kangge1-Clear") == 0 then
						room:notifySkillInvoked(p,self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(math.min(move.card_ids:length(),3))
						room:addPlayerMark(p,"kangge1-Clear")
					end
				end
			end
		elseif event == sgs.EnterDying then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark("kangge"..p:objectName()) > 0 and p:getMark("kangge2_lun") == 0 then
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp() ))
						room:addPlayerMark(p, "kangge2_lun")
					end
				end
			end
		elseif event == sgs.Death and RIGHT(self, player) then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			if player:isAlive() and splayer:getMark("kangge"..player:objectName()) > 0 then
				player:throwAllHandCardsAndEquips()
				room:loseHp(player,1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

jielie = sgs.CreateTriggerSkill{
	name = "jielie",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local can_invoke = false
		if not damage.from then
			can_invoke = true
		end
		if damage.from and damage.from:objectName() ~= player:objectName() and damage.from:getMark("kangge"..player:objectName()) == 0 then
			can_invoke = true
		end
		if can_invoke then
			if room:askForSkillInvoke(player, "jielie", data) then
				local kangge_player
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("kangge"..player:objectName()) > 0 then
						kangge_player = p
						break
					end
				end
				room:broadcastSkillInvoke(self:objectName())
				if kangge_player then

					local suit = room:askForSuit(player, "jielie")
					local GetCardList = sgs.IntList()
					local DPHeart = sgs.IntList()

					if room:getDiscardPile():length() > 0 then
						for _, id in sgs.qlist(room:getDiscardPile()) do
							if sgs.Sanguosha:getCard(id):getSuit() == suit then
								DPHeart:append(id)
							end
						end
					end
					for i = 1,damage.damage,1 do
						if DPHeart:length() > 0 then
							local get_id = DPHeart:at( math.random(1,DPHeart:length()) -1)
							GetCardList:append(get_id)
							DPHeart:removeOne(get_id)
						end
					end
					if GetCardList:length() > 0 then
						local move = sgs.CardsMoveStruct()
						move.card_ids = GetCardList
						move.to = kangge_player
						move.to_place = sgs.Player_PlaceHand
						room:moveCardsAtomic(move, true)
					end
				end

				room:loseHp(player,damage.damage)
				return true
			end
		end
	end
}

tangji:addSkill(kangge)
tangji:addSkill(jielie)

sgs.LoadTranslationTable{
["tangji"] = "唐姬",
["#tangji"] = "弘農王妃",
["kangge"] = "抗歌",
[":kangge"] = "妳的第一個回合開始時，選擇一名其他角色：每回合限一次，該角色每次於其回合外獲得牌時，妳摸等量的牌（最多三張）；其進入瀕死狀態時，妳可令其回復體力至1點（每輪限一次）。該角色死亡時，妳棄置所有牌並失去1點體力。",
["kangge-invoke"] = "妳可以對一名角色發動「抗歌」",
["jielie"] = "節烈",
[":jielie"] = "當妳受到除自己和「抗歌」角色以外的角色造成的傷害時，妳可以防止此傷害並選擇一種花色，然後妳失去X點體力，令「抗歌」角色從棄牌堆中隨機獲得X張此花色的牌（X為傷害值）。",
}

--楊婉
yangwan = sgs.General(extension,"yangwan","shu2",3,false)
--誘言
youyan = sgs.CreateTriggerSkill{
	name = "youyan",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and
			  bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and
			  move.card_ids:length() > 0 and player:getMark("youyan_biu") == 0 and (player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_Discard) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player,"youyan_biu")
					local give_suit_name_table = {"spade", "club", "heart", "diamond"}
					for _, id in sgs.qlist(move.card_ids) do
						local c = sgs.Sanguosha:getCard(id)
						if c:getSuitString() == "spade" then
							table.removeOne(give_suit_name_table, c:getSuitString())
						elseif c:getSuitString() == "club" then
							table.removeOne(give_suit_name_table, c:getSuitString())
						elseif c:getSuitString() == "heart" then
							table.removeOne(give_suit_name_table, c:getSuitString())
						elseif c:getSuitString() == "diamond" then
							table.removeOne(give_suit_name_table, c:getSuitString())
						end
					end

					local GetCardList = sgs.IntList()


					for _, patt in ipairs(give_suit_name_table) do
						local DPHeart = sgs.IntList()
						if room:getDrawPile():length() > 0 then
							for _, id in sgs.qlist(room:getDrawPile()) do
								local card = sgs.Sanguosha:getCard(id)
								if card:getSuitString() == patt then
									DPHeart:append(id)
								end
							end
						end
						if DPHeart:length() > 0 then
							local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
							GetCardList:append(get_id)
							local card = sgs.Sanguosha:getCard(get_id)
						end
					end
					if GetCardList:length() > 0 then
						local move = sgs.CardsMoveStruct()
						move.card_ids = GetCardList
						move.to = player
						move.to_place = sgs.Player_PlaceHand
						room:moveCardsAtomic(move, true)
					end
				end
			end
		end
		return false
	end
}

--追還
zhuihuan = sgs.CreateTriggerSkill{
	name = "zhuihuan",
	--設定priority用來讓界鐵騎可以封劫營技能(時機相同)
	priority = 6,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "zhuihuan-invoke", true, false)
			if target then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(target,"zhuihuan_target",1)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end,
}

zhuihuan_invoke = sgs.CreateTriggerSkill{
	name = "zhuihuan_invoke",
	global = true,
	events = {sgs.EventPhaseStart,sgs.DamageComplete},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("zhuihuan_target") > 0 then
			room:setPlayerMark(player,"zhuihuan_target",0 )
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("zhuihuan_invoke"..player:objectName() ) > 0 then
					room:setPlayerMark(p,"zhuihuan_invoke"..player:objectName(),0 )
					if p:isAlive() and p:objectName() ~= player:objectName() then
						if p:getHp() > player:getHp() then
							room:doAnimate(1, player:objectName(), p:objectName())
							room:notifySkillInvoked(player, self:objectName())
							room:damage(sgs.DamageStruct(self:objectName(), player, p, 2))
						elseif p:getHp() <= player:getHp() then
							room:doAnimate(1, player:objectName(), p:objectName())
							room:notifySkillInvoked(player, self:objectName())
							local loot_cards = sgs.QList2Table(p:getCards("h"))
							for i = 1,2,1 do
								if #loot_cards > 0 then
									local random_card = loot_cards[math.random(1, #loot_cards)]
									room:throwCard(random_card, p,p)
									table.removeOne(loot_cards,random_card)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.from and damage.to and damage.to:getMark("zhuihuan_target") > 0 then
				room:setPlayerMark(damage.from,"zhuihuan_invoke"..damage.to:objectName(),1 )

			end
		end
		return false
	end,
}

yangwan:addSkill(youyan)
yangwan:addSkill(zhuihuan)

if not sgs.Sanguosha:getSkill("zhuihuan_invoke") then skills:append(zhuihuan_invoke) end

sgs.LoadTranslationTable{
["yangwan"] = "楊婉",
["youyan"] = "誘言",
[":youyan"] = "妳的出牌階段與棄牌階段各限一次，當妳的牌因棄置進入棄牌堆後，妳可以從牌堆中獲得本次棄牌中沒有的花色的牌各一張。",
["zhuihuan"] = "追還",
[":zhuihuan"] = "結束階段，妳可以選擇一名角色（其他角色不可見），直到該角色的下個準備階段，此期間內對其造成過傷害的角色：若體力值大於該角色，則受到其造成的2點傷害；若體力值小於等於該角色，則隨機棄置兩張手牌。",
["zhuihuan-invoke"] = "妳可以選擇一名角色，對其發動「追還」",
}

--OL鮑三娘
ol_baosanniang = sgs.General(extension,"ol_baosanniang","shu2","4",false)

ol_wuniang = sgs.CreateTriggerSkill{
	name = "ol_wuniang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:getMark("ol_wuniang-Clear") == 0 and use.to:length() == 1 and player:getPhase() ~=sgs.Player_NotActive then
				if room:askForSkillInvoke(player,self:objectName(),data) then
					for _, p in sgs.qlist(use.to) do
						room:askForUseSlashTo(p, player, "#ol_wuniang:"..player:objectName(),false)
					end
					room:addPlayerMark(player, "ol_wuniang-Clear")
					player:drawCards(1)
				end
			end
		end
		return false
	end
}

ol_wuniangtm = sgs.CreateTargetModSkill{
	name = "#ol_wuniangtm",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("ol_wuniang") then
			return player:getMark("ol_wuniang-Clear")
		end
	end,
}

--許身
ol_xushen = sgs.CreateTriggerSkill{
	name = "ol_xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@ol_xushen",
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			if player:getMark("@ol_xushen") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("baosanniang","ol_xushen")
					room:removePlayerMark(player, "@ol_xushen")
					room:recover(player, sgs.RecoverStruct(player, nil, (1 - player:getHp()) ))
					room:acquireSkill(player, "ol_zhennan")
					
					local has_guansuo = false
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo" or p:getGeneralName() == "ty_guansuo" or p:getGeneral2Name() == "ty_guansuo" then
							has_guansuo = true
						end
					end
					if not has_guansuo and player:hasSkill(self:objectName()) then

						local _targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:isMale() then _targets:append(p) end
						end

						if not _targets:isEmpty() then
							local target = room:askForPlayerChosen(player, _targets, self:objectName(), "ol_xushen-invoke", true, true)
							if target then
								if room:askForSkillInvoke(target, self:objectName(), data) then
									target:drawCards(3)
									room:changeHero(target, "guansuo", false, false)
								end
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

ol_zhennanCard = sgs.CreateSkillCard{
	name = "ol_zhennan",
	will_throw = false,
	filter = function(self, targets, to_select)
		local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
		savage_assault:setSkillName("ol_zhennan")
		for _, cd in sgs.qlist(self:getSubcards()) do
			savage_assault:addSubcard(cd)
		end
		savage_assault:deleteLater()
		return #targets < self:getSubcards():length() and not sgs.Self:isProhibited(to_select, savage_assault )

	end,
	feasible = function(self, targets)
		--if self:getSubcards():length() ~= #targets then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
		savage_assault:setSkillName(self:objectName())
		for _, cd in sgs.qlist(self:getSubcards()) do
			savage_assault:addSubcard(cd)
		end

		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if not source:isProhibited(target, savage_assault) then
				targets_list:append(target)
			end
		end

		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not targets_list:contains(p) then
				room:setPlayerMark(p,"ol_zhennan_cancel_target" ,1)
			end
		end

		savage_assault:deleteLater()
		if targets_list:length() > 0 then
			room:useCard(sgs.CardUseStruct(savage_assault, source, targets_list))
		end

	end
}
ol_zhennanVS = sgs.CreateViewAsSkill{
	name = "ol_zhennan",
	n = 99,
	view_filter = function(self, selected, to_select)
		return #selected < 99 and not sgs.Self:isJilei(to_select) and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local card = ol_zhennanCard:clone()
		for _, cd in ipairs(cards) do
			card:addSubcard(cd)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ol_zhennan")
	end,
}

ol_zhennan = sgs.CreateTriggerSkill{
	name = "ol_zhennan",
	events = {sgs.CardEffected,sgs.PreCardUsed},
	view_as_skill = ol_zhennanVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("SavageAssault") then
				return true
			else
				return false
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "ol_zhennan" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("ol_zhennan_cancel_target") > 0 then
						room:setPlayerMark(p,"ol_zhennan_cancel_target" ,0)
						if use.to:contains(p) then
							use.to:removeOne(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
						end
					end
				end
			end
		end
	end
}

--[[
ol_zhennanPS = sgs.CreateProhibitSkill{
	name = "#ol_zhennanPS",
	is_prohibited = function(self, from, to, card)
		return not card:isKindOf("SkillCard") and card:getSkillName() == "ol_zhennan"  and to:getMark("ol_zhennan_ban") > 0
	end
}
]]--

ol_baosanniang:addSkill(ol_wuniang)
ol_baosanniang:addSkill(ol_wuniangtm)
ol_baosanniang:addSkill(ol_xushen)
if not sgs.Sanguosha:getSkill("ol_zhennan") then skills:append(ol_zhennan) end
ol_baosanniang:addRelateSkill("ol_zhennan")
	

sgs.LoadTranslationTable{
	["ol_baosanniang"] = "OL鮑三娘",
	["&ol_baosanniang"] = "鮑三娘",
	["ol_wuniang"] = "武娘",
	[":ol_wuniang"] = "每回合限一次，當你於回合內使用的【殺】結算完成後，若此【殺】對應的目標數為1，則妳可以令目標角色選擇是否對你使用使用【殺】。妳於其選擇結算完成後摸一張牌，且本回合內使用【殺】的次數上限+1。",
	["#ol_wuniang"] = "你可以對 %src 使用一張【殺】",
	["ol_xushen"] = "許身",
	[":ol_xushen"] = "限定技，當妳進入瀕死狀態時，妳可將體力回復至1點並獲得技能〖鎮南〗。然後若場上沒有存活的「關索」，則妳可以令一名其他男性角色選擇是否將一張武將牌替換為「關索」。",
	["ol_zhennan"] = "鎮南",
	["#ol_zhennanPS"] = "鎮南",
	[":ol_zhennan"] = "【南蠻入侵】對妳無效。出牌階段限一次，妳可以將任意張手牌當做【南蠻入侵】對等量的角色使用。",
}


--張橫
zhangheng = sgs.General(extension,"zhangheng","qun2",8, true)

dangzaiCard = sgs.CreateSkillCard{
	name = "dangzai",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getJudgingArea():length() > 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if targets[1]:getJudgingArea():length() == 0 then return end
			local card_id = room:askForCardChosen(source, targets[1], "j", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)


			if not source:isProhibited(source, card) and not source:containsTrick(card:objectName()) then
				room:moveCardTo(card, targets[1], source, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
		end
	end
}
dangzaiVS = sgs.CreateZeroCardViewAsSkill{
	name = "dangzai",
	view_as = function()
		return dangzaiCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@dangzai"
	end,
}

dangzai = sgs.CreateTriggerSkill{
	name = "dangzai",
	frequency = sgs.Skill_Frequency,
	events = {sgs.EventPhaseStart},
	view_as_skill = dangzaiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local can_invoke = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:getJudgingArea():isEmpty() then
					can_invoke = true
				end
			end
			if can_invoke then
				room:askForUseCard(player, "@@dangzai", "@dangzai", -1, sgs.Card_MethodNone)
			end
		end
	end,
}

liangjue = sgs.CreateTriggerSkill{
	name = "liangjue" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceDelayedTrick)) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if (move.from_places:at(i) == sgs.Player_PlaceEquip or move.from_places:at(i) == sgs.Player_PlaceJudge) and
				 sgs.Sanguosha:getCard(move.card_ids:at(i)):isBlack() and player:getHp() > 1 then
				 	SendComLog(self, player)
					room:loseHp(player,1)
					player:drawCards(1)
				end
			end
		end
		if move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceEquip or move.to_place == sgs.Player_PlaceDelayedTrick) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if sgs.Sanguosha:getCard(move.card_ids:at(i)):isBlack() and player:getHp() > 1 then
					SendComLog(self, player)
					room:loseHp(player,1)
					player:drawCards(2)
				end
			end
		end
		return false
	end
}

zhangheng:addSkill(dangzai)
zhangheng:addSkill(liangjue)

sgs.LoadTranslationTable{
["zhangheng"] = "張橫",
["dangzai"] = "擋災",
[":dangzai"] = "出牌階段開始時，你可將一名其他角色判定區內的一張牌移動至你的判定區內。",
["@dangzai"] = "你可將一名其他角色判定區內的一張牌移動至你的判定區內",
["~dangzai"] = "選擇一名角色->點擊確定",
["liangjue"] = "糧絕",
[":liangjue"] = "鎖定技，當有黑色牌進入或者離開你的判定區或裝備區後，若你的體力值大於1，你失去1點體力，然後摸兩張牌。",
}

--董承
re_dongcheng = sgs.General(extension,"re_dongcheng","qun2",4,true)

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
--血詔
xuezhaoCard = sgs.CreateSkillCard{
	name = "xuezhao",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getHp()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _, p in ipairs(targets) do
				local card = room:askForCard(p, ".", "@xuezhao_give", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), source:objectName(), self:objectName(), ""))
					p:drawCards(1)
					room:addPlayerMark(source, "xuezhao_extra-Clear")
				else					
					room:addPlayerMark(p, "xuezhao_to-Clear")
					room:addPlayerMark(source, "xuezhao_from-Clear")
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
xuezhaoVS = sgs.CreateOneCardViewAsSkill{
	name = "xuezhao",
	filter_pattern = ".",
	view_as = function(self, card)
		local cards = xuezhaoCard:clone()
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#xuezhao")
	end
}

xuezhao = sgs.CreateTriggerSkill{
	name = "xuezhao",
	--events = {sgs.CardUsed, sgs.TargetConfirmed, sgs.TrickCardCanceling, sgs.CardFinished},
	events = {sgs.CardUsed, sgs.TargetSpecified, sgs.TrickCardCanceling},
	view_as_skill = xuezhaoVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local invoke = false
			for _, p in sgs.qlist(use.to) do
				if p:getMark("xuezhao_to-Clear") > 0 and use.from:getMark("xuezhao_from-Clear") > 0 then
					invoke = true
				end
			end
			if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and not use.card:isKindOf("SkillCard") and invoke and use.from:hasSkill(self:objectName()) then
				--room:sendCompulsoryTriggerLog(player, self:objectName())
				--room:broadcastSkillInvoke(self:objectName())
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
				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if p:getMark("xuezhao_to-Clear") > 0 and use.from:getMark("xuezhao_from-Clear") > 0 then
						jink_table[index] = 0
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_"..use.card:toString(), jink_data)
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and RIGHT(self, effect.from) and player:getMark("xuezhao_to-Clear") > 0 and effect.from:getMark("xuezhao_from-Clear") > 0 then return true end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

xuezhaoTM = sgs.CreateTargetModSkill{
	name = "#xuezhaoTM",
	residue_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			return from:getMark("xuezhao_extra-Clear")
		end
		return 0
	end
}

re_dongcheng:addSkill(xuezhao)
re_dongcheng:addSkill(xuezhaoTM)

sgs.LoadTranslationTable{
["re_dongcheng"] = "董承",
["xuezhao"] = "血詔",
[":xuezhao"] = "出牌階段限一次，你可棄置一張手牌並選擇至多X名其他角色(X為你的體力值）。這些角色依次選擇是否交給你一張牌，若選擇是，該角色摸一張牌且你本回合可多使用一張【殺】；若選擇否，該角色本回合無法響應你使用的牌。",
["@xuezhao_give"] = "交給發起者一張牌，否則你本回合無法響應其使用的牌。",
}

--胡車兒
re_hucheer = sgs.General(extension,"re_hucheer","qun2",4,true)
--盜戟
redaoji = sgs.CreateTriggerSkill{
	name = "redaoji",
	events = {sgs.CardUsed, sgs.CardResponded},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local card
		local invoke = true
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			if data:toCardResponse().m_isUse then
				card = data:toCardResponse().m_card
			else
				invoke = false
			end
		end
		if card and (not card:isKindOf("SkillCard")) then
			if card:isKindOf("Weapon") and player:getMark("first_use_weapon") == 0 then
				room:setPlayerMark(player , "first_use_weapon",1)
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:doAnimate(1, p:objectName(), player:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local choice = room:askForChoice(p, "redaoji", "redaoji1+redaoji2+cancel" )
					ChoiceLog(p, choice)
					if choice == "redaoji1" then
						p:obtainCard(card)
						return true
					end
					if choice == "redaoji2" then
						room:setPlayerMark(player,"redaoji_can_not_slash-Clear",1)
					end
				end
			end
		end
		return false
	end
}

redaojiProhibit = sgs.CreateProhibitSkill{
	name = "#redaoji",
	is_prohibited = function(self, from, to, card)
		return from:getMark("redaoji_can_not_slash-Clear") > 0 and card:isKindOf("Slash")
	end
}

--負重
fuzhong = sgs.CreateTriggerSkill{
	name = "fuzhong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart,sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime and not room:getTag("FirstRound"):toBool() then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive  then
			--if move.to and move.to:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive and player:getMark("fuzhong-Clear") == 0 then
				--room:addPlayerMark(player,"fuzhong-Clear")
				player:gainMark("@zhong", 1)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("@zhong") > 3 then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "cuike-invoke", true, true)
			if target then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, target))
				player:loseAllMarks("@zhong")
			end
		elseif event == sgs.DrawNCards then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			data:setValue(data:toInt() + 1)
		end
		return false
	end
}

fuzhongMC = sgs.CreateMaxCardsSkill{
	name = "#fuzhongMC",
	extra_func = function(self, player)
		if player:hasSkill("fuzhong") and player:getMark("@zhong") > 0 then
			return 1
		end
		return 0
	end
}

fuzhongDis = sgs.CreateDistanceSkill{
	name = "#fuzhongDis",
	correct_func = function(self, from, to)
		if from:hasSkill("fuzhong") and from:getMark("@zhong") > 1 then
			return - 1
		end
	end
}

re_hucheer:addSkill(redaoji)
re_hucheer:addSkill(redaojiProhibit)
re_hucheer:addSkill(fuzhong)
re_hucheer:addSkill(fuzhongMC)
re_hucheer:addSkill(fuzhongDis)

sgs.LoadTranslationTable{
["re_hucheer"] = "胡車兒",
["redaoji"] = "盜戟",
[":redaoji"] = "其他角色第一次使用武器牌時，你可選擇一項：①獲得此牌。②令其本回合內不能使用或打出【殺】。",
["redaoji1"] = "獲得此牌。",
["redaoji2"] = "令其本回合內不能使用或打出【殺】。",
["fuzhong"] = "負重",
[":fuzhong"] = "鎖定技，當你於回合外獲得牌後，你獲得一枚「重」標記。若X：大於0，你的手牌上限+1；大於1，你至其他角色的距離-1；大於2，你於摸牌階段開始時令額定摸牌數+1；大於3，準備階段，你對一名其他角色造成1點傷害，然後移去X枚「重」（X為「重」數）。",
["@zhong"] = "負重",
}

--高幹
gaogan = sgs.General(extension,"gaogan","qun2",4,true)
--拒關


juguanCard = sgs.CreateSkillCard{
	name = "juguan",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {"slash","duel"}
		
		if next(choices) ~= nil then
			--table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "juguan", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local pos = 0
				pos = getPos(patterns, pattern)
				room:setPlayerMark(source, "juguanpos", pos)
				room:setPlayerProperty(source, "juguan", sgs.QVariant(self:getSubcards():first()))
				room:askForUseCard(source, "@@juguan", "@juguan:"..pattern)--%src
			end
		end
	end
}

juguanVS = sgs.CreateViewAsSkill{
	name = "juguan",
	n = 1,
	response_or_use = true,
	response_pattern = "@@juguan",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@juguan" then
			return false
		else return not to_select:isEquipped() end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = juguanCard:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern and pattern == "@@juguan" then

				local patterns = generateAllCardObjectNameTablePatterns()
				local DCR = patterns[sgs.Self:getMark("juguanpos")]
				local shortage = sgs.Sanguosha:cloneCard(DCR, sgs.Card_NoSuit, 0)
				shortage:setSkillName("juguan")
				shortage:addSubcard(sgs.Self:property("juguan"):toInt())
				return shortage

			end
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#juguan")
	end,
}

juguan = sgs.CreateTriggerSkill{
	name = "juguan",
	events = {sgs.DamageComplete,sgs.DrawNCards},
	global = true,
	view_as_skill = juguanVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageComplete then
			local damage = data:toDamage()
			local current = room:getCurrent()
			if damage.card and damage.card:getSkillName() == "juguan" and damage.to then
				room:setPlayerMark(current , "juguan_"..damage.to:objectName(), 1 )
				room:setPlayerMark(current , "juguan_invoke", 1 )
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("juguan_invoke") > 0 then
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "juguan_") and player:getMark(mark) > 0 then
						room:setPlayerMark(player,mark,0)
					end
				end
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				local n = data:toInt()
				data:setValue(n+2)
			end
		end
	end
}

gaogan:addSkill(juguan)

sgs.LoadTranslationTable{
	["gaogan"] = "高幹",
	["juguan"] = "拒關",
	[":juguan"] = "出牌階段限一次，你可將一張手牌當【殺】或【決鬥】使用。若受到此牌傷害的角色未在你的下回合開始前對你造成過傷害，你的下個摸牌階段摸牌數+2。",
}

--杜襲
duxi = sgs.General(extension,"duxi","wei2",3,true)
--驅徙
quxiCard = sgs.CreateSkillCard{
	name = "quxi",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark(self:objectName()) > 0 then
			if sgs.Self:getMark(self:objectName()) == 3 then
				return #targets < 2
			else
				return #targets == 0
			end
		elseif sgs.Self:getMark("@quxi_mark") > 0 then
			if #targets == 0 then
				return true
			else
				return to_select:getHandcardNum() ~= targets[1]:getHandcardNum()
			end
		else
			if (#targets == 0 and to_select:getMark("@fong") > 0) or (#targets == 1 and to_select:getMark("@fong") == 0) then
				return true
			elseif (#targets == 0 and to_select:getMark("@chian") > 0) or (#targets == 1 and to_select:getMark("@chian") == 0) then
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
						use.to:first():gainMark("@fong")
						use.to:last():gainMark("@chian")
					else
						use.to:first():gainMark("@fong")
						use.to:first():gainMark("@chian")
					end
				else
					if use.from:getMark(self:objectName()) == 1 then
						use.to:first():gainMark("@fong")
					else
						use.to:first():gainMark("@chian")
					end
				end
			elseif use.from:getMark("@quxi_mark") > 0 then

				if use.to:first():getHandcardNum() > use.to:last():getHandcardNum() then
					use.to:first():gainMark("@chian")
					use.to:last():gainMark("@fong")
					room:setPlayerMark(use.to:first(),"quxi_winner",1)
					room:setPlayerMark(use.to:last(),"quxi_loser",1)
				else
					use.to:first():gainMark("@fong")
					use.to:last():gainMark("@chian")
					room:setPlayerMark(use.to:first(),"quxi_loser",1)
					room:setPlayerMark(use.to:last(),"quxi_winner",1)
				end
			else
				local choices = {}
				if use.to:first():getMark("@fong") > 0 then
					table.insert(choices, "fong_move")
				end
				if use.to:first():getMark("@chian") > 0 then
					table.insert(choices, "chian_move")
				end
				local choice = room:askForChoice(use.from, self:objectName(), table.concat(choices, "+"))
				if choice == "fong_move" then
					use.to:first():loseMark("@fong")
					use.to:last():gainMark("@fong")
				else
					use.to:first():loseMark("@chian")
					use.to:last():gainMark("@chian")
				end
			end
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
quxiVS = sgs.CreateZeroCardViewAsSkill{
	name = "quxi",
	view_as = function(self)
		return quxiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@quxi")
	end
}
quxi = sgs.CreateTriggerSkill{
	name = "quxi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@quxi_mark", 
	events = {sgs.EventPhaseEnd, sgs.Death,sgs.EventPhaseChanging,sgs.DrawNCards},
	view_as_skill = quxiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:getMark("@quxi_mark") > 0 and RIGHT(self, player) then
				if room:askForUseCard(player, "@@quxi", "@quxi_first") then
					--room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("duxi","quxi")

					local winner
					local loser

					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("quxi_winner") > 0 then
							winner = p
							room:setPlayerMark(p,"quxi_winner",0)
						end
						if p:getMark("quxi_loser") > 0 then
							loser = p
							room:setPlayerMark(p,"quxi_loser",0)
						end
					end


					local id = room:askForCardChosen(loser, winner, "he", "mobile_anxu")

					local cd = sgs.Sanguosha:getCard(id)

					loser:obtainCard(cd)


					room:removePlayerMark(player,"@quxi_mark")
					room:addPlayerMark(player,"skip_discard")
					player:turnOver()
					
				end
		elseif event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_RoundStart and (player:getMark("AG_firstplayer") > 0 or player:getMark("@leader") > 0 or player:isLord()) and (not room:getTag("ExtraTurn"):toBool()) and player:getMark("@stop_invoke") == 0 then
				local can_move = false
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("@fong") > 0 or p:getMark("@chian") > 0 then
						can_move = true
						break
					end
				end
				if can_move then
					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						room:askForUseCard(p, "@@quxi", "@quxi")
					end
				end
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("@fong") > 0 then
				local n = data:toInt()
				data:setValue(n+1)
			end
			if player:getMark("@chian") > 0 then
				local n = data:toInt()
				data:setValue(n-1)
			end
		else
			local death = data:toDeath()
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if (death.who:getMark("@fong") > 0 and p:getMark("@fong") == 0) or (death.who:getMark("@chian") > 0 and p:getMark("@chian") == 0) then
					players:append(p)
				end
			end
			if death.who:objectName() == player:objectName() and not players:isEmpty() then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if death.who:getMark("@fong") > 0 then
						room:addPlayerMark(p, self:objectName())
					end
					if death.who:getMark("@chian") > 0 then
						room:addPlayerMark(p, self:objectName(), 2)
					end
					room:askForUseCard(p, "@@quxi", "@quxi")
					room:setPlayerMark(p, self:objectName(), 0)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}

bixiong = sgs.CreateTriggerSkill{
	name = "bixiong",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				  and move.card_ids:length() > 0 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					for _, id in sgs.qlist(move.card_ids) do
						if player:getMark("bixiong"..sgs.Sanguosha:getCard(id):getSuit().."_start") == 0 then
							room:setPlayerMark(player, "bixiong"..sgs.Sanguosha:getCard(id):getSuit().."_start", 1)
						end
					end
				end
			end
		end
		return false
	end
}

bixiongPS = sgs.CreateProhibitSkill{
	name = "#bixiongPS",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("bixiong") and from:getPhase() == sgs.Player_Play and not card:isKindOf("SkillCard") and to:getMark("bixiong"..card:getSuit().."_start") > 0
	end
}

duxi:addSkill(quxi)
duxi:addSkill(bixiong)
duxi:addSkill(bixiongPS)


sgs.LoadTranslationTable{
	["duxi"] = "杜襲",
	["quxi"] = "驅徙",
	[":quxi"] = "限定技。出牌階段結束時，你可跳過下個棄牌階段並選擇兩名手牌數不同的其他角色。你將武將牌翻至背面，"..
	"令這兩名角色中手牌數較少的角色獲得另一名角色的一張牌並獲得一枚「豐」，另一名角色獲得一枚「歉」。擁有「豐」/「歉」的角"..
	"色的摸牌階段額定摸牌數+1/-1。擁有「豐」/「歉」的角色死亡時，或一輪遊戲開始時，你可轉移「豐」/「歉」。",
	["@quxi_first"] = "你可以發動“驅徙”，跳過下個棄牌階段並選擇兩名手牌數不同的其他角色",
	["@quxi"] = "你可以發動“驅徙”",
	["~quxi"] = "選擇角色→點擊確定",
	["fong_move"] = "轉移「豐」標記",
	["chian_move"] = "轉移「歉」標記",
	["@fong"] = "豐標記",
	["@chian"] = "歉標記",

	["bixiong"] = "避凶",
	[":bixiong"] = "鎖定技，當你於棄牌階段棄置手牌後，你不能成為與這些牌花色相同的牌的目標直到你下回合開始。",
}

--OL鄒氏
ol_zoushi = sgs.General(extension,"ol_zoushi","qun2",3,false)

ol_huoshuiCard = sgs.CreateSkillCard{
	name = "ol_huoshui", 
	target_fixed = false,
	filter = function(self, targets, to_select) 
		return #targets < math.max(1,sgs.Self:getLostHp())
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:setPlayerMark(effect.to, "skill_invalidity-Clear",1)
		room:setPlayerMark(effect.to, "@skill_invalidity",1)
	end,
}

ol_huoshuiVS = sgs.CreateZeroCardViewAsSkill{
	name = "ol_huoshui",
	response_pattern = "@@ol_huoshui",
	view_as = function(self) 
		return ol_huoshuiCard:clone()
	end, 
}

ol_huoshui = sgs.CreateTriggerSkill{
	name = "ol_huoshui", 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = ol_huoshuiVS,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event ==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:askForUseCard(player, "@@ol_huoshui", "@ol_huoshui-invoke:"..math.max(1,player:getLostHp()) )
			end
		end
	end,
}

ol_qingchengCard = sgs.CreateSkillCard{
	name = "ol_qingcheng", 
	target_fixed = false,
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:isMale() and to_select:getHandcardNum() < sgs.Self:getHandcardNum()
	end,
	on_use = function(self, room, source, targets)
		local exchangeMove = sgs.CardsMoveList()
		exchangeMove:append(sgs.CardsMoveStruct(source:handCards(), targets[1], sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), targets[1]:objectName(), self:objectName(), "")))
		exchangeMove:append(sgs.CardsMoveStruct(targets[1]:handCards(), source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, targets[1]:objectName(), source:objectName(), self:objectName(), "")))
		room:moveCardsAtomic(exchangeMove, false)
	end,
}

ol_qingcheng = sgs.CreateZeroCardViewAsSkill{
	name = "ol_qingcheng",
	view_as = function(self) 
		return ol_qingchengCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#ol_qingcheng")
	end,
}

ol_zoushi:addSkill(ol_huoshui)
ol_zoushi:addSkill(ol_qingcheng)

sgs.LoadTranslationTable{
["#ol_zoushi"] = "惑心之魅",
["ol_zoushi"] = "OL鄒氏",
["&ol_zoushi"] = "鄒氏",
["illustrator:ol_zoushi"] = "Tuu.",
["ol_huoshui"] = "禍水",
[":ol_huoshui"] = "準備階段，你可以選擇至多X名角色（X為你已損失的體力值且至少為1），這些角色本回合非鎖定技失效。",
["ol_qingcheng"] = "傾城",
[":ol_qingcheng"] = "出牌階段限一次，你可以選擇手牌數小於等於你的一名男性角色，然後與其交換手牌。",
["@ol_huoshui-invoke"] = "你可以對至多 %src 名角色發動“禍水”",
}

--OL諸葛果
ol_zhugeguo = sgs.General(extension,"ol_zhugeguo","shu2",3,false)
--[[
ol_qirangCard = sgs.CreateSkillCard{
	name = "ol_qirang",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("ol_qirang_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "ol_qirang_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets == 0 and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets == 0 and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
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
ol_qirangVS = sgs.CreateZeroCardViewAsSkill{
	name = "ol_qirang",
	response_pattern = "@@ol_qirang",
	view_as = function()
		return ol_qirangCard:clone()
	end
}
]]--
ol_qirang = sgs.CreateTriggerSkill{
	name = "ol_qirang",
	events = {sgs.PreCardUsed, sgs.CardFinished},
	--view_as_skill = ol_qirangVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			--[[
			if use.card:isNDTrick() and player:getMark(self:objectName()..use.card:getEffectiveId().."-Clear") > 0 and use.to:length() == 1 then			  	
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, self:objectName())
				end
				if use.card:isVirtualCard() then
					room:setPlayerMark(player, "ol_qirang_virtual_card", 1)
					room:setPlayerMark(player, "ol_qirang_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
					room:askForUseCard(player, "@@ol_qirang", "@ol_qirang")
					room:setPlayerMark(player, "ol_qirang_virtual_card", 0)
					room:setPlayerMark(player, "ol_qirang_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
				elseif not use.card:isVirtualCard() then
					room:setPlayerMark(player, "ol_qirang_not_virtual_card", 1)
					room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
					room:askForUseCard(player, "@@ol_qirang", "@ol_qirang")
					room:setPlayerMark(player, "ol_qirang_not_virtual_card", 0)
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
			end
			]]--
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeEquip then
				local point_six_card = sgs.IntList()
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
						point_six_card:append(id)
					end
				end
				if not point_six_card:isEmpty() then
					local aid = point_six_card:at(math.random(0,point_six_card:length()-1))
					room:obtainCard(player, sgs.Sanguosha:getCard(aid) , false)
					room:setPlayerMark(player, self:objectName()..aid.."-Clear", 1)
				end
			end
		end
		return false
	end,
}

ol_yuhua = sgs.CreateTriggerSkill{
	name = "ol_yuhua" ,
	frequency = sgs.Skill_Compulsory ,
	global = true ,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseEnd,sgs.EventPhaseStart} ,   
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging and player:hasSkill("ol_yuhua") then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if not sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
						room:setPlayerMark(player, self:objectName()..id.."-Clear" ,1)
						room:setPlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString(), false)
					end
				end
			end
		elseif event == sgs.EventPhaseEnd and player:hasSkill("ol_yuhua") then
			if player:getPhase() == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if player:getMark(self:objectName()..id.."-Clear") > 0 then
						room:removePlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString().."$0")
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:hasSkill("ol_yuhua") then
			if player:getPhase() == sgs.Player_Finish and player:getHandcardNum() > player:getHp() then
				local cards = room:getNCards(1)
				room:askForGuanxing(player, cards, 0)
			end
		end
		return false
	end
}

ol_yuhuamc = sgs.CreateMaxCardsSkill{
	name = "#ol_yuhuamc",
	extra_func = function(self, target)
		if target:hasSkill("ol_yuhua") then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if not card:isKindOf("BasicCard") then
					x = x + 1
				end
			end
			return x
		end
	end
}

ol_zhugeguo:addSkill(ol_qirang)
ol_zhugeguo:addSkill(ol_yuhua)
ol_zhugeguo:addSkill(ol_yuhuamc)

sgs.LoadTranslationTable{
["ol_zhugeguo"] = "OL諸葛果",
["&ol_zhugeguo"] = "諸葛果",
["#ol_zhugeguo"] = "鳳閣乘煙",
["illustrator:ol_zhugeguo"] = "手機三國殺",
["ol_qirang"] = "祈禳",
[":ol_qirang"] = "當妳使用一張裝備牌時，妳可以從牌堆里獲得一張錦囊牌。若該錦囊為非延時類錦囊，妳本回合使用此錦囊牌指定唯一目標時，可以額外增加一個目標。",
["#ol_qirang-failed"] = "牌堆中沒有錦囊牌，取消“<font color=\"yellow\"><b>祈禳</b></font>”的後續效果",
["ol_yuhua"] = "羽化",
[":ol_yuhua"] = "鎖定技。棄牌階段內，妳的非基本牌不計入手牌數，且妳不能棄置妳的非基本牌，結束階段，若妳的手牌數大於體力值，妳可以觀星牌堆頂的一張牌。",
["#olyuhua-effect"] = "受技能“<font color=\"yellow\"><b>羽化</b></font>”的影響，%from 的手牌數視為 %arg" ,
["@ol_qirang"] = "妳可以多選擇一個目標。",
["~ol_qirang"] = "選擇目標角色→點“確定”",
}

--丘力居

qiuliju = sgs.General(extension,"qiuliju","qun2",6,true)

koulve = sgs.CreateTriggerSkill{
	name = "koulve",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage and player:getPhase() == sgs.Player_Play then
			local damage = data:toDamage()
			local _data = sgs.QVariant()
			_data:setValue(damage.to)
			if room:askForSkillInvoke(player, self:objectName(), _data) then
				local card = damage.to:getRandomHandCard()
				room:showCard(damage.to, card:getEffectiveId())
				if canCauseDamage(card) then
					player:obtainCard(card)
				end
				if card:isRed() then
					if player:isWounded() then
						room:loseMaxHp(player)
					else
						room:loseHp(player)
					end
					player:drawCards(2)
				end
			end
		end
		return false
	end,
}

qljsuiren = sgs.CreateTriggerSkill{
	name = "qljsuiren",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if data:toDeath().who:objectName() == player:objectName() then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "qljsuiren-invoke", true, true)
			if target then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())

					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					local cards = player:getCards("he")
					for _,card in sgs.qlist(cards) do
						if canCauseDamage(card) then
							dummy:addSubcard(card)
						end
					end
					if cards:length() > 0 then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
						room:obtainCard(target, dummy, reason, false)
					end
					dummy:deleteLater()

					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

qiuliju:addSkill(koulve)
qiuliju:addSkill(qljsuiren)

sgs.LoadTranslationTable{
["qiuliju"] = "丘力居",
["#qiuliju"] = "",
["koulve"] = "宼略",
[":koulve"] = "當你於出牌階段內對其他角色造成傷害後，你可以展示其一張手牌。若此牌：為帶有傷害標籤的基本牌或錦囊牌，則你獲得之；為紅色牌，你失去1點體力（若已受傷則改為減1點體力上限），然後摸兩張牌。",
["qljsuiren"] = "隨認",
[":qljsuiren"] = "當你死亡時，你可以將手牌中所有的帶有傷害標籤的基本牌或錦囊牌交給一名其他角色。",
["qljsuiren-invoke"] = "你可以發動“隨認”",
}

--[[
舊版張虎
]]--

nos_zhanghu = sgs.General(extension,"nos_zhanghu","wei2",4,true,true)

--摧堅
nos_cuijianCard = sgs.CreateSkillCard{
	name = "nos_cuijian",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local has_jink = false
			for _, card in sgs.qlist(targets[1]:getHandcards()) do
				if card:isKindOf("Jink") then
					has_jink = true
				end
			end
			if has_jink then
				local lirang_card = sgs.IntList()
				for _, card in sgs.qlist(targets[1]:getCards("he")) do
					if card:isKindOf("Jink") or card:isKindOf("Armor") then
						lirang_card:append(card:getId())
					end
				end
				if lirang_card:length() > 0 then
					local move3 = sgs.CardsMoveStruct()
					move3.card_ids = lirang_card
					move3.to_place = sgs.Player_PlaceHand
					--move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), "nos_cuijian","")
					move3.to = source					
					room:moveCardsAtomic(move3, true)

					local card
					local n = lirang_card:length()
					if source:getMark("nos_tongyuan_Peach") > 0 then
						card = room:askForExchange(source, self:objectName(), 1, 1, false, "@nos_cuijian2:"..targets[1]:objectName() )
					else
						card = room:askForExchange(source, self:objectName(), n, n, false, "@nos_cuijian1:"..targets[1]:objectName() )
					end
					local move = sgs.CardsMoveStruct(card:getSubcards(), source, targets[1], sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),targets[1]:objectName(), "nos_cuijian","") )
					room:moveCardsAtomic(move, true)
				end
			else
				if source:getMark("nos_tongyuan_Nullification") > 0 then
					source:drawCards(1)
				else
					room:askForDiscard(source, self:objectName(), 1, 1, false, true)
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
nos_cuijian = sgs.CreateZeroCardViewAsSkill{
	name = "nos_cuijian",
	view_as = function(self, cards)
		local card = nos_cuijianCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#nos_cuijian")
	end
}

nos_tongyuan = sgs.CreateTriggerSkill{
	name = "nos_tongyuan",
	events = {sgs.CardUsed, sgs.CardResponded,sgs.TrickCardCanceling,sgs.PreHpRecover,sgs.PreCardUsed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed or event == sgs.CardResponded and RIGHT(self, player) then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and player:getPhase() == sgs.Player_NotActive then
				if card:isKindOf("Peach") and player:getMark("nos_tongyuan_Peach") == 0  then
					SendComLog(self, player)
					room:addPlayerMark(player,"nos_tongyuan_Peach")
				elseif card:isKindOf("Nullification") and player:getMark("nos_tongyuan_Nullification") == 0 then
					SendComLog(self, player)
					room:addPlayerMark(player,"nos_tongyuan_Nullification")
				end
			end
		elseif event == sgs.PreCardUsed and RIGHT(self, player) then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card then
				if card:isKindOf("Peach") and player:getMark("nos_tongyuan_Peach") > 0 and player:getMark("nos_tongyuan_Nullification") > 0 then
					room:setCardFlag(card , "nos_tongyuan_usecard_Peach")
				end
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Nullification") and RIGHT(self, effect.from)
			 and effect.from:getMark("nos_tongyuan_Peach") > 0 and effect.from:getMark("nos_tongyuan_Nullification") > 0 then
				SendComLog(self, effect.from)
				room:addPlayerMark(effect.from, self:objectName().."engine")
				if effect.from:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(effect.from, self:objectName().."engine")
					return true
				end
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:isKindOf("Peach") and rec.card:hasFlag("nos_tongyuan_usecard_Peach") then
			  	SendComLog(self, player)
				local log = sgs.LogMessage()
				log.type = "$nos_tongyuanREC"
				log.from = player
				room:sendLog(log)
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

nos_zhanghu:addSkill(nos_cuijian)
nos_zhanghu:addSkill(nos_tongyuan)

sgs.LoadTranslationTable{
["nos_zhanghu"] = "舊版張虎",
["&nos_zhanghu"] = "張虎",
["#nos_zhanghu"] = "晉陽侯",
["nos_cuijian"] = "摧堅",
[":nos_cuijian"] = "出牌階段限一次，你可以選擇一名有手牌的其他角色。若其手牌中：有【閃】，其將裝備區內的防具牌和所有【閃】"..
"交給你，然後你交給其等量的牌；沒有【閃】，你棄置一張手牌。",
["@nos_cuijian1"] = "請交給 %src 等量的牌",
["@nos_cuijian2"] = "請交給 %src 一張牌",
["nos_tongyuan"] = "同援",
[":nos_tongyuan"] = "鎖定技。①當你於回合外使用【無懈可擊】時，你將〖摧堅〗中的「棄置一張手牌」改為「摸一張牌」；②當你於回合"..
"外使用【桃】時，你將〖摧堅〗中的「等量的牌」改為「一張牌」。③當你使用【無懈可擊】/【桃】時，若你已發動過〖摧堅①〗和"..
"〖摧堅②〗，則此牌不可被響應/回復值+1。",
["$nos_tongyuanREC"] = "%from 的“同援”被觸發，此【桃】的回復值+1",
}

--[[
張虎
]]--
zhanghu = sgs.General(extension,"zhanghu","wei2",4,true)

--摧堅
cuijianCard = sgs.CreateSkillCard{
	name = "cuijian",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local has_jink = false
			for _, card in sgs.qlist(targets[1]:getHandcards()) do
				if card:isKindOf("Jink") then
					has_jink = true
				end
			end
			if has_jink then
				local lirang_card = sgs.IntList()
				for _, card in sgs.qlist(targets[1]:getCards("he")) do
					if card:isKindOf("Jink") or card:isKindOf("Armor") then
						lirang_card:append(card:getId())
					end
				end
				if lirang_card:length() > 0 then
					local move3 = sgs.CardsMoveStruct()
					move3.card_ids = lirang_card
					move3.to_place = sgs.Player_PlaceHand
					--move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), "cuijian","")
					move3.to = source					
					room:moveCardsAtomic(move3, true)

					local card
					local n = lirang_card:length()
					if source:getMark("zhtongyuan_Basic") > 0 then
						card = room:askForExchange(source, self:objectName(), 1, 1, false, "@cuijian2:"..targets[1]:objectName() )
					else
						card = room:askForExchange(source, self:objectName(), n, n, false, "@cuijian1:"..targets[1]:objectName() )
					end
					local move = sgs.CardsMoveStruct(card:getSubcards(), source, targets[1], sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),targets[1]:objectName(), "cuijian","") )
					room:moveCardsAtomic(move, true)
				end
			else
				if source:getMark("zhtongyuan_Trick") > 0 then
					source:drawCards(2)
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
cuijian = sgs.CreateZeroCardViewAsSkill{
	name = "cuijian",
	view_as = function(self, cards)
		local card = cuijianCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#cuijian")
	end
}

zhtongyuan = sgs.CreateTriggerSkill{
	name = "zhtongyuan",
	events = {sgs.CardUsed, sgs.CardResponded,sgs.TrickCardCanceling},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.CardUsed or event == sgs.CardResponded) and RIGHT(self, player) then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and card:isRed() then
				if card:isKindOf("BasicCard") and player:getMark("zhtongyuan_Basic") == 0  then
					SendComLog(self, player)
					room:addPlayerMark(player,"zhtongyuan_Basic")
				elseif card:isKindOf("TrickCard") and player:getMark("zhtongyuan_Trick") == 0 then
					SendComLog(self, player)
					room:addPlayerMark(player,"zhtongyuan_Trick")
				end
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("TrickCard") and effect.card:isRed() and RIGHT(self, effect.from)
			 and effect.from:getMark("zhtongyuan_Trick") > 0 and effect.from:getMark("zhtongyuan_Basic") > 0 then
				SendComLog(self, effect.from)
				room:addPlayerMark(effect.from, self:objectName().."engine")
				if effect.from:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(effect.from, self:objectName().."engine")
					return true
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

zhanghu:addSkill(cuijian)
zhanghu:addSkill(zhtongyuan)

sgs.LoadTranslationTable{
["zhanghu"] = "張虎",
["#zhanghu"] = "晉陽侯",
["cuijian"] = "摧堅",
[":cuijian"] = "出牌階段限一次，你可以選擇一名有手牌的其他角色。若其手牌中：有【閃】，其將裝備區內的防具牌和所有【閃】"..
"交給你，然後你交給其等量的牌",
["@cuijian1"] = "請交給 %src 等量的牌",
["@cuijian2"] = "請交給 %src 一張牌",
["zhtongyuan"] = "同援",
[":zhtongyuan"] = "鎖定技。①當你使用紅色錦囊牌後，你將〖摧堅〗增加描述的「；沒有【閃】，你摸兩張牌」；②當你"..
"使用紅色基本牌時，你刪除〖摧堅〗中的「然後你交給其等量的牌」。③若你已發動過〖摧堅①〗和"..
"〖摧堅②〗，則你使用紅色基本牌目標+1，紅色錦囊牌無法被響應。",
}

--OL潘淑
ol_panshu = sgs.General(extension,"ol_panshu","wu2",3,false)
--織紝
zhiren = sgs.CreateTriggerSkill{
	name = "zhiren" ,
	events = {sgs.CardUsed} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (not use.card:isVirtualCard()) and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and 
			  sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):objectName() == use.card:objectName() and
			  player:getMark("used-Clear") == 1 and (player:getPhase() ~= sgs.Player_NotActive or player:getMark("@zhiren_start") > 0) then
			  	if room:askForSkillInvoke(player, self:objectName(), data) then
				  	room:broadcastSkillInvoke(self:objectName())
				  	local n = string.len(sgs.Sanguosha:translate(use.card:objectName()))/3
				  	if n >= 1 then
						local cards = room:getNCards(n)
						room:askForGuanxing(player, cards, 0)
					end
					if n >= 2 then
						local _targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if player:canDiscard(p, "ej") then _targets:append(p) end
						end
						if not _targets:isEmpty() then
							local s = room:askForPlayerChosen(player, _targets, "zhiren", "@zhiren-discard", true)
							if s then
								room:doAnimate(1, player:objectName(), s:objectName())
								room:throwCard(room:askForCardChosen(player, s, "ej", "sk_yaoming", false, sgs.Card_MethodDiscard), s, player)
							end
						end
					end
					if n >= 3 and player:isWounded() then
						room:recover(player, sgs.RecoverStruct(player))
					end
					if n >= 4 then
						player:drawCards(3)
					end
				end
			end
		end
	end,
}
--燕爾
yaner = sgs.CreateTriggerSkill{
	name = "yaner",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from  and move.from_places:contains(sgs.Player_PlaceHand) and move.from:objectName() ~= player:objectName() and 
		  move.is_last_handcard and move.from:getPhase() == sgs.Player_Play and player:getMark("yaner-Clear") == 0 then
		  	local _data = sgs.QVariant()
			_data:setValue( BeMan(room, move.from) )
			if room:askForSkillInvoke(player, self:objectName(), _data) then
				room:doAnimate(1, player:objectName(), move.from:objectName())
				room:addPlayerMark(player,"yaner-Clear")
				room:notifySkillInvoked(player, "yaner")
				room:broadcastSkillInvoke("yaner")
				BeMan(room, move.from):drawCards(2,"yaner")
				player:drawCards(2,"yaner")
				room:setPlayerFlag(player,"yaner_invoke")
				room:setPlayerFlag( BeMan(room, move.from) ,"yaner_target")
			end
		end

		if move.to and move.to:objectName() == player:objectName() and move.reason.m_skillName == "yaner" then
			if sgs.Sanguosha:getCard(move.card_ids:at(1)):getTypeId() == sgs.Sanguosha:getCard(move.card_ids:at(2)):getTypeId() then
				if player:hasFlag("yaner_target") then
					room:recover(player, sgs.RecoverStruct(player))
				elseif player:hasFlag("yaner_invoke") then
					room:addPlayerMark(player,"@zhiren_start")
				end
			end
		end
		return false
	end
}

ol_panshu:addSkill(zhiren)
ol_panshu:addSkill(yaner)

sgs.LoadTranslationTable{
["ol_panshu"] = "OL潘淑",
["&ol_panshu"] = "潘淑",
["zhiren"] = "織紝",
[":zhiren"] = "當你於你的回合內使用第一張牌時，你可依次執行以下選項中的前X項：①卜算X。②棄置場上的一張裝備牌和延時錦囊牌。③回復1點體力。④摸三張牌。（X為此牌的名稱的字數）",
["yaner"] = "燕爾",
[":yaner"] = "每回合限一次。當有其他角色於其出牌階段內失去手牌後，若其沒有手牌，則你可以與其各摸兩張牌。若其以此法摸得的兩張牌類型相同，則其回復1點體力。若你以此法摸得的兩張牌類型相同，則你將〖織紝〗中的「你的回合內」改為「一回合內」。",
["@zhiren-discard"] = "請選擇失去牌的角色",
}

--曹安民
caoanmin = sgs.General(extension,"caoanmin","wei2",4,true)

--險衛
xianwei = sgs.CreateTriggerSkill{
	name = "xianwei",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				local choice = ChooseThrowEquipArea(self, player,false,false)
				throwEquipArea(self,player, choice)

				local n = player:getMark("@AbolishWeapon") + player:getMark("@AbolishDefensiveHorse")
				 + player:getMark("@AbolishOffensiveHorse") + player:getMark("@AbolishTreasure")
				  + player:getMark("@AbolishArmor")
				player:drawCards(5 - n)

				local players = sgs.SPlayerList()
				if choice == "AbolishWeapon" then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:getWeapon() and p:getMark("@AbolishWeapon") == 0 then
							players:append(p)
						end
					end
				elseif choice == "AbolishArmor" then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:getArmor() and p:getMark("@AbolishArmor") == 0 then
							players:append(p)
						end
					end
				elseif choice == "AbolishDefensiveHorse" then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:getDefensiveHorse() and p:getMark("@AbolishDefensiveHorse") == 0 then
							players:append(p)
						end
					end
				elseif choice == "AbolishOffensiveHorse" then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:getOffensiveHorse() and p:getMark("@AbolishOffensiveHorse") == 0 then
							players:append(p)
						end
					end
				elseif choice == "AbolishTreasure" then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:getTreasure() and p:getMark("@AbolishTreasure") == 0 then
							players:append(p)
						end
					end
				end
				local target = room:askForPlayerChosen(player, players, self:objectName(), "xianwei-invoke", true, true)
				if target then
					local equips = sgs.CardList()
					for _, id in sgs.qlist(room:getDrawPile()) do				
						if (choice == "AbolishWeapon" and sgs.Sanguosha:getCard(id):isKindOf("Weapon") ) or
						(choice == "AbolishArmor" and sgs.Sanguosha:getCard(id):isKindOf("Armor") ) or
						(choice == "AbolishDefensiveHorse" and sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse")) or
						(choice == "AbolishOffensiveHorse" and sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse")) or
						(choice == "AbolishTreasure" and sgs.Sanguosha:getCard(id):isKindOf("Treasure")) then
							local equip_index = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()
						 	if target:getEquip(equip_index) == nil  then
								equips:append(sgs.Sanguosha:getCard(id))
							end
						end
					end
					if not equips:isEmpty() then
						local card = equips:at(math.random(0, equips:length() - 1))
						if not room:isProhibited(target, target, card) then
							room:useCard(sgs.CardUseStruct(card, target, target))
						else
							target:drawCards(1)
						end
					else
						target:drawCards(1)
					end

				end
			end
		end
		return false
	end,
}

xianweitm = sgs.CreateDistanceSkill{
	name = "#xianweitm",
	correct_func = function(self, from, to)
		if from:getMark("@xianwei_wake") > 0 or to:getMark("@xianwei_wake") > 0 then
			return -1000
		end
		return 0
	end
}

caoanmin:addSkill(xianwei)
caoanmin:addSkill(xianweitm)

sgs.LoadTranslationTable{
["caoanmin"] = "曹安民",
["#caoanmin"] = "履薄臨深",
["xianwei"] = "險衛",
[":xianwei"] = "鎖定技，準備階段，你廢除一個裝備欄並摸X張牌（X為你尚未廢除的裝備欄數），然後令一名其他角色對其自己使用一張牌堆中的一張與此裝備欄副類別相同的裝備牌（沒有可使用的牌則改為摸一張牌）。當你廢除所有裝備欄後，你加2點體力上限，然後你與所有其他角色視為在彼此的攻擊範圍內。",
["xianwei-invoke"] = "令一名其他角色對其自己使用一張牌堆中的一張與此裝備欄副類別相同的裝備牌",
}

--OL馬良
re_maliang = sgs.General(extension,"re_maliang","shu2",3,true,true)

rexiemu = sgs.CreateTriggerSkill{
	name = "rexiemu",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventPhaseStart,sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self,event,player,data,room)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Finish then
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "rexiemu-invoke", true, true)
				if to then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:addPlayerMark(to, "@ol_xiemu")
						room:setPlayerMark(player, "rexiemu"..to:objectName().."_start",1)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
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
			if card and (not card:isKindOf("SkillCard")) and player:getPhase() == sgs.Player_NotActive then
				local can_invoke = false
				for _,p in sgs.qlist( room:getAlivePlayers() ) do
					if p:getMark("rexiemu"..player:objectName().."_start") > 0 then
						p:drawCards(1)
						can_invoke = true
					end

					if player:getMark("rexiemu"..p:objectName().."_start") > 0 then
						p:drawCards(1)
						can_invoke = true
					end
				end
				if can_invoke then
					player:drawCards(1)
				end
			end
		end
	end,
}

heliCard = sgs.CreateSkillCard{
	name = "heli",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHandcardNum() < sgs.Self:getHandcardNum()
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local hasBasic = false
			local hasTrick = false
			local hasEquip = false
			if not targets[1]:isKongcheng() then
				room:showAllCards(targets[1])
				for _, card in sgs.qlist( targets[1]:getHandcards()) do
					if card:isKindOf("BasicCard") then
						hasBasic = true
					end
					if card:isKindOf("TrickCard") then
						hasTrick = true
					end
					if card:isKindOf("EquipCard") then
						hasEquip = true
					end
				end
			end
			local pattern_list = {}
			if not hasBasic then
				table.insert(pattern_list , "BasicCard")
			end
			if not hasTrick then
				table.insert(pattern_list , "TrickCard")
			end
			if not hasEquip then
				table.insert(pattern_list , "EquipCard")
			end
			if #pattern_list  > 0 then
				getpatterncard_for_each_pattern(targets[1], pattern_list,true,false)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

heli = sgs.CreateZeroCardViewAsSkill{
	name = "heli",
	view_as = function(self, cards)
		return heliCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heli")
	end
}

re_maliang:addSkill(rexiemu)
re_maliang:addSkill(heli)

sgs.LoadTranslationTable{
["re_maliang"] = "OL馬良",
["&re_maliang"] = "馬良",
["rexiemu"] = "協穆",
[":rexiemu"] = "結束階段，若全場沒有「協穆」標記，你可以選擇一名角色獲得「協穆」標記直到你的下回合開始。你或該角色在各自的"..
"回合外使用或打出手牌時，你與其各摸一張牌（每回合限一次）。",
["rexiemu-invoke"] = "你可以發動“協穆”",
["heli"] = "賀勵",
[":heli"] = "出牌階段限一次，你可以選擇手牌數比你少的一名其他角色。該角色展示所有手牌，然後每缺少一種類型的牌，便從牌"..
"堆中隨機獲得一張此類型的牌。",
}

--鄧芝
ol_dengzhi = sgs.General(extension,"ol_dengzhi","shu2",3,true)
--
ol_xiuhao = sgs.CreateTriggerSkill{
	name = "ol_xiuhao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if damage.to and damage.to:isAlive() and damage.to:objectName() ~= player:objectName() and player:getMark("ol_xiuhao-Clear") == 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:addPlayerMark(player,"ol_xiuhao-Clear")
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), damage.to:objectName())
					player:drawCards(2)
					return true
				end
			end
		elseif event == sgs.DamageInflicted then
			if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() and player:getMark("ol_xiuhao-Clear") == 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:addPlayerMark(player,"ol_xiuhao-Clear")
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), damage.from:objectName())
					damage.from:drawCards(2)
					return true
				end
			end
		end
		return false
	end
}

ol_sujian = sgs.CreateTriggerSkill{
	name = "ol_sujian",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if not player:isSkipped(change.to) and (change.to == sgs.Player_Discard) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				player:skip(change.to)

				--
				local ids = sgs.IntList()

				for _, card in sgs.qlist(player:getHandcards()) do
					if player:getMark("fulin"..card:getEffectiveId().."-Clear") == 0 then
						ids:append(card:getEffectiveId())
					end
				end
				room:setPlayerMark(player,"ol_sujian",ids:length())
				local choice = room:askForChoice(player , "ol_sujian", "ol_sujian1+ol_sujian2")
				if choice == "ol_sujian1" then
					while room:askForYiji(player, ids, self:objectName(), false, true, false, -1, room:getOtherPlayers(player)) do
						if ids:isEmpty() then break end
					end
				elseif choice == "ol_sujian2" then
					if not ids:isEmpty() then
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = nil
						move.to_place = sgs.Player_DiscardPile
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "sk_quanlue", nil)
						room:moveCardsAtomic(move, true)
						room:getThread():delay()
						local players = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if not p:isKongcheng() then
								players:append(p)
							end
						end
						if not players:isEmpty() then
							local to = room:askForPlayerChosen(player, players, self:objectName(), "ol_sujian-invoke", true, true)
							if to then
								room:addPlayerMark(player, self:objectName().."engine")
								if player:getMark(self:objectName().."engine") > 0 then
									room:setPlayerFlag(to, "Fake_Move")
									local x = ids:length()
									local n = 0
									local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
									local card_ids = sgs.IntList()
									local original_places = sgs.IntList()
									for i = 0, x - 1 do
										if not player:canDiscard(to, "he") then break end
										local to_throw = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
										card_ids:append(to_throw)
										original_places:append(room:getCardPlace(card_ids:at(i)))
										dummy:addSubcard(card_ids:at(i))
										room:throwCard(sgs.Sanguosha:getCard(to_throw), to, player)
										--to:addToPile("#xuehen", card_ids:at(i), false)
										room:getThread():delay()
									end
									room:setPlayerFlag(to, "-Fake_Move")
								end
							end
						end
					end
				end
				room:setPlayerMark(player,"ol_sujian",0)
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}

ol_dengzhi:addSkill(ol_xiuhao)
ol_dengzhi:addSkill(ol_sujian)

sgs.LoadTranslationTable{
["ol_dengzhi"] = "OL鄧芝",
["&ol_dengzhi"] = "鄧芝",
["ol_xiuhao"] = "修好",
[":ol_xiuhao"] = "每回合限一次。當你受到其他角色造成的傷害時，或對其他角色造成傷害時，你可防止此傷害，然後令傷害來源摸兩張牌。",
["ol_sujian"] = "素儉",
[":ol_sujian"] = "鎖定技。棄牌階段開始前，你跳過此階段。然後你選擇一項：①將所有不為本回合獲得的手牌分配給其他角色。"
.."②棄置這些手牌，然後棄置一名其他角色等量的牌。",
["ol_sujian1"] = "將所有不為本回合獲得的手牌分配給其他角色。",
["ol_sujian2"] = "棄置這些手牌，然後棄置一名其他角色等量的牌。",
["ol_sujian-invoke"] = "你可以棄置一名其他角色等量的牌",
}

--卞夫人
ol_bianhuanghou = sgs.General(extension, "ol_bianhuanghou", "wei2", 3, false)

fuwei = sgs.CreateTriggerSkill{
	name = "fuwei",
	frequency = sgs.Skill_Frequency,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local room = player:getRoom()
		if move.from and move.from:objectName() == player:objectName() and ((move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE
		  and move.reason.m_playerId ~= move.reason.m_targetId) or (move.to and move.to:isAlive() and
		  move.from:objectName() ~= move.to:objectName() and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE and
		   move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_USE)) and player:getMark(self:objectName().."-Clear") == 0 then
			if move.card_ids then
				for _, id in sgs.qlist(move.card_ids) do
					local point_six_card = sgs.IntList()
					for _,id2 in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id2):objectName() == sgs.Sanguosha:getCard(id):objectName() then
							point_six_card:append(id2)
						end
					end

					if room:askForSkillInvoke(player, self:objectName(), data) then
						if not point_six_card:isEmpty() then
							room:obtainCard(player, point_six_card:at(math.random(0,point_six_card:length()-1)), false)
							room:addPlayerMark(player, self:objectName().."-Clear")
							room:broadcastSkillInvoke(self:objectName())
						else
							player:drawCards(1)
							room:addPlayerMark(player, self:objectName().."-Clear")
							room:broadcastSkillInvoke(self:objectName())
						end
					end
				end
			end
		end
		return false
	end
}

ol_yuejian = sgs.CreateTriggerSkill{
	name = "ol_yuejian",
	frequency = sgs.Skill_Frequency,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if use.card and not use.card:isKindOf("SkillCard") and use.from then
			for _, p in sgs.qlist(use.to) do
				if use.from:isAlive() and p:hasSkill("ol_yuejian") and p:isAlive() and p:objectName() ~= use.from:objectName() then
					if use.card:getSuit() <= 3 then
						local can_invoke = true
						for _, c in sgs.qlist(p:getHandcards()) do
							if c:getSuit() == use.card:getSuit() then
								can_invoke = false
							end
						end

						for _, id in sgs.list(use.card:getSubcards()) do
							if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
							
							else
								can_invoke = false
							end
						end

						if can_invoke and p:getMark("ol_yuejian-Clear") < 2 then
							if room:askForSkillInvoke(p, self:objectName(), data) then
								room:broadcastSkillInvoke(self:objectName())
								room:addPlayerMark(p,"ol_yuejian-Clear")
								player:obtainCard(use.card)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

ol_bianhuanghou:addSkill(fuwei)
ol_bianhuanghou:addSkill(ol_yuejian)

sgs.LoadTranslationTable{
["ol_bianhuanghou"] = "卞夫人",
["&ol_bianhuanghou"] = "卞夫人",
["fuwei"] = "扶危",
[":fuwei"] = "每回合限一次。當你的牌被其他角色棄置或獲得後，你可從牌堆中獲得一張與此牌名稱相同的牌（若沒有則改為摸一張牌）。",
["ol_yuejian"] = "約儉",
[":ol_yuejian"] = "每回合限兩次。當其他角色對你使用的牌A結算結束後，你可展示所有手牌。若牌A有花色且你的手牌中沒有同花色的牌，"
.."則你獲得牌A對應的所有實體牌。",
}

--[[
杜夫人 沛王太妃
【異色】其他角色獲得你的牌後，若此牌為紅色，你可令其回復1點體力；若此牌為黑色，其下次受到【殺】的傷害時，此傷害+1。
【順世】準備階段或當你於回合外受到傷害後，你可交給除傷害來源之外的一名其他角色一張牌。若如此做，你獲得以下效果：
下個摸牌階段摸牌數+1、下個出牌階段使用【殺】次數+1、下個棄牌階段手牌上限+1。 
]]--
dufuren = sgs.General(extension, "dufuren", "wei2", 3, false)

yise = sgs.CreateTriggerSkill{
	name = "yise",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() ~= player:objectName() and move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
				room:notifySkillInvoked( player , self:objectName())
				room:sendCompulsoryTriggerLog( player , self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local target = BeMan(room, move.to)
				for _,id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isRed() then
						room:setPlayerFlag(target,"yiseTarget")
						room:obtainCard(player, card, false)
						local choices = {"recover", "cancel"}
						local choice = room:askForChoice(player, "yise", table.concat(choices, "+"))
						if choice == "recover" then
							local recover = sgs.RecoverStruct()
							recover.who = target
							room:recover(player, recover)
						end
						room:setPlayerFlag(target,"-yiseTarget")
					elseif card:isBlack() then
						room:addPlayerMark(target, "@yiseDebuff" )
					end
				end
			end
		end

		return false
	end,
}

shunshi = sgs.CreateTriggerSkill{
	name = "shunshi",
	global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.Damaged,sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if player:getMark("@shunshi_flag") > 0 then
				data:setValue(data:toInt() +  player:getMark("@shunshi_flag") )
			end
		elseif ((event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) or (event == sgs.Damaged and player:getPhase() ~= sgs.Player_NotActive)) and RIGHT(self, player) and (not player:isKongcheng()) then
			if room:askForSkillInvoke(player, "shunshi", data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if event == sgs.Damaged then
						local damage = data:toDamage()
						if p:objectName() ~= damage.from:objectName() then
							targets:append(p)
						end
					else
						targets:append(p)
					end
				end
				if room:askForYiji(player, getIntList(player:getCards("he")), self:objectName(), true, false, true, 1, targets, sgs.CardMoveReason(), "@shunshi", true)  then
					room:addPlayerMark(player,"@shunshi_flag")
				end
			end
			return false
		end
	end
}

shunshitm = sgs.CreateTargetModSkill{
	name = "#shunshitm",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:getMark("@shunshi_flag") > 0 then
			return player:getMark("@shunshi_flag")
		end
	end,
}

shunshimc = sgs.CreateMaxCardsSkill{
	name = "#shunshimc", 
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if target:getMark("@shunshi_flag") > 0 then
			return player:getMark("@shunshi_flag")
		end
	end
}

dufuren:addSkill(yise)
dufuren:addSkill(shunshi)
dufuren:addSkill(shunshitm)
dufuren:addSkill(shunshimc)

sgs.LoadTranslationTable{
["dufuren"] = "杜夫人",
["&dufuren"] = "杜夫人",
["#dufuren"] = "沛王太妃",
["yise"] = "異色",
[":yise"] = "其他角色獲得妳的牌後，若此牌為紅色，妳可令其回復1點體力；若此牌為黑色，其下次受到【殺】的傷害時，此傷害+1。",
["shunshi"] = "順世",
["#shunshimc"] = "順世",
["#shunshitm"] = "順世",
[":shunshi"] = "準備階段或當妳於回合外受到傷害後，妳可交給除傷害來源之外的一名其他角色一張牌。若如此做，妳獲得以下效果："..
"下個摸牌階段摸牌數+1、下個出牌階段使用【殺】次數+1、下個棄牌階段手牌上限+1。。",
["@shunshi"] = "妳可交給除傷害來源之外的一名其他角色一張牌並發動【順世】",
}


--[[
呂玲綺 群 4勾玉 女
幗武：出牌階段開始時，你可以展示全部手牌，根據你展示的型別數，你獲得對應效果：至少一類，從棄牌堆獲得一張【殺】；至少兩類，
此階段使用牌無距離限制；至少三類，此階段使用【殺】或普通錦囊牌可以多指定兩個目標。

妝戎：覺醒技，每個回合結束時，若你的體力值或手牌數為1，你減1點體力上限並回滿體力，將手牌摸至體力上限，然後獲得“神威”和“
無雙”。

☆神威：鎖定技，摸牌階段，你多摸2張牌，你的手牌上限+2。

☆無雙：鎖定技，當你使用【殺】指定一個目標後，該角色需依次使用兩張【閃】才能抵消此【殺】；當你使用【決鬥】指定一個目標後，
或成為一名角色使用【決鬥】的目標後，該角色每次響應此【決鬥】需依次打出兩張【殺】。
]]--
lvlingqi = sgs.General(extension, "lvlingqi", "qun2", 4, false)

guowu = sgs.CreateTriggerSkill{
	name = "guowu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if player:askForSkillInvoke(self:objectName(),data) then
					room:broadcastSkillInvoke(self:objectName())
					room:showAllCards(player)
					local hasBasic = false
					local hasTrick = false
					local hasEquip = false
					for _, card in sgs.qlist( player:getHandcards()) do
						if card:isKindOf("BasicCard") then
							hasBasic = true
						end
						if card:isKindOf("TrickCard") then
							hasTrick = true
						end
						if card:isKindOf("EquipCard") then
							hasEquip = true
						end
					end
					local n = 0
					if hasBasic then
						n = n + 1
					end
					if hasTrick then
						n = n + 1
					end
					if hasEquip then
						n = n + 1
					end
					if n >= 1 then
						getpatterncard(player, {"Slash"} ,false,true)
					end
					if n >= 2 then
						room:setPlayerMark(player, "guowu_Play",n)
					end
				end
			end
		end	
		return false
	end
}

guowuTM = sgs.CreateTargetModSkill{
	name = "#guowuTM",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash,TrickCard",
	distance_limit_func = function(self, player)
		if player:getMark("guowu_Play") >= 2 then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player)
		if player:getMark("guowu_Play") >= 3 then
			return 2
		else
			return 0
		end
	end,
}

zhuangrong = sgs.CreateTriggerSkill{
	name = "zhuangrong",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("zhuangrong") and p:getMark("zhuangrong") == 0 then
				if p:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 or p:getHp() == 1 or p:getHandcardNum() == 1 then
					room:setPlayerMark(p, "zhuangrong", 1)
					if room:changeMaxHpForAwakenSkill(p) and p:getMark("zhuangrong") == 1 then
						--[[
						if invoke then
							local msg = sgs.LogMessage()
							msg.type = "#fanxiangWake"
							msg.from = player
							msg.to:append(player)
							room:sendLog(msg)
						end
						]]--
						if p:getLostHp() > 0 then
							local recover = sgs.RecoverStruct()
							recover.who = p
							recover.recover = p:getLostHp()
							room:recover(p, recover)
						end

						local n = player:getMaxHp() - player:getHandcardNum()

						if n > 0 then
							player:drawCards(n)
						end

						room:broadcastSkillInvoke(self:objectName())
						room:doSuperLightbox("lvlingqi","zhuangrong")
						room:handleAcquireDetachSkills(p, "wushuang|shenwei")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
				and (target:getPhase() == sgs.Player_Finish)
	end
}

lvlingqi:addSkill(guowu)
lvlingqi:addSkill(guowuTM)
lvlingqi:addSkill(zhuangrong)
lvlingqi:addRelateSkill("wushuang")
lvlingqi:addRelateSkill("shenwei")

sgs.LoadTranslationTable{
["#lvlingqi"] = "",
["lvlingqi"] = "呂玲綺",
["&lvlingqi"] = "呂玲綺",
["guowu"] = "幗武",
["#guowuTM"] = "幗武",
[":guowu"] = "出牌階段開始時，妳可以展示全部手牌，根據妳展示的型別數，妳獲得對應效果：至少一類，從棄牌堆獲得一張【殺】；至少兩類，此階段使用牌無距離限制；至少三類，此階段使用【殺】或普通錦囊牌可以多指定兩個目標。",
["zhuangrong"] = "妝戎",
[":zhuangrong"] = "覺醒技，每個回合結束時，若妳的體力值或手牌數為1，妳減1點體力上限並回滿體力，將手牌摸至體力上限，然後獲得“神威”和“無雙”。",
}

--[[
周夷 吳 3勾玉 女

逐寇：當妳於每個回合的出牌階段(別人回合也算)第一次造成傷害後，妳可以摸X張牌( X為本回合妳已使用的牌數)。妳的結束階段，
若妳本回合沒有造成傷害，妳可以對所有其他角色造成1點傷害。

氓情：覺醒技，準備階段若其他角色均已受傷，妳加3點體力上限並回復3點體力，失去“逐寇”，獲得“玉殞”。

☆玉殞：鎖定技，出牌階段開始時，若妳的體力上限大於1，妳失去1點體力或體力上限，然後選擇一項（若妳已損失體力值大於1，
則多選一項）：1. 摸兩張牌；2. 本回合使用黑色【殺】無距離和次數限制；3.本回合沒有手牌上限；4.棄置一名其他角色一張手牌和
一張裝備區中的牌；5.令手牌最少的一名其他角色將手牌摸至體力上限（最多摸至5）。
]]--
zhouyi = sgs.General(extension, "zhouyi", "wu2", "3", false)

zhukouCard = sgs.CreateSkillCard{
	name = "zhukou",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
			room:removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
zhukouVS = sgs.CreateZeroCardViewAsSkill{
	name = "zhukou",
	response_pattern = "@@zhukou",
	view_as = function(self, card)
		return zhukouCard:clone()
	end
}

zhukou = sgs.CreateTriggerSkill{
	name = "zhukou",
	view_as_skill = zhukouVS,
	events = {sgs.Damage,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			local current = room:getCurrent()
			if current and current:getPhase() == sgs.Player_Play and player:getMark("damage_record-Clear") == 0 and player:getMark("used-Clear") > 0 then
				if room:askForSkillInvoke(player, "zhukou", data) then
					player:drawCards(player:getMark("used-Clear"))
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:getMark("damage_record-Clear") == 0  then
			room:askForUseCard(player, "@@zhukou", "@zhukou", -1, sgs.Card_MethodUse)
		end
	end
}

yuyun = sgs.CreateTriggerSkill{
	name = "yuyun",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:getMaxHp() > 1 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local result = room:askForChoice(player, "yuyun_lost", "hp+maxhp")
				if result == "hp" then
					room:loseHp(player)
				else
					room:loseMaxHp(player)
				end


				local n = math.min(5,player:getLostHp())
				local choices = {"yuyun1","yuyun2","yuyun3","yuyun4","yuyun5"}
				for i = 1,n,1 do					
					local choice = room:askForChoice(player, "yuyun", table.concat(choices, "+"))
					ChoiceLog(player, choice)
					table.removeOne(choices,choice)
					if choice == "yuyun1" then
						player:drawCards(2)
					elseif choice == "yuyun2" then
						local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "yuyun_2", "@yuyun2", true)
						if s then
							room:broadcastSkillInvoke(self:objectName())
							room:doAnimate(1, player:objectName(), s:objectName())
							room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))

							local assignee_list = player:property("extra_slash_specific_assignee"):toString():split("+")
							table.insert(assignee_list, s:objectName())
							room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
							room:setPlayerMark(s, "ol_huxiao-Clear",1)
						end
					elseif choice == "yuyun3" then
						room:addPlayerMark(player,"@yuyun3-Clear")
					elseif choice == "yuyun4" then
						local targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if not p:isNude() then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							room:setPlayerFlag(player,"yuyun4")
							local s = room:askForPlayerChosen(player, targets, "yuyun_4", "@yuyun4", true)
							room:setPlayerFlag(player,"-yuyun4")
							if s then
								local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								if not s:isKongcheng() then
									local id1 = room:askForCardChosen(player, s, "h", self:objectName())
									dummy:addSubcard(id1)
								end
								if not s:getEquips():isEmpty() then
									local id2 = room:askForCardChosen(player, s, "e", self:objectName())
									dummy:addSubcard(id2)
								end
								if dummy:subcardsLength() > 0 then
									room:throwCard(dummy, s,player)
								end
							end
						end

					elseif choice == "yuyun5" then
						local targets = sgs.SPlayerList()

						local player_card = {}

						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:getMaxHp() > p:getHandcardNum() then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							room:setPlayerFlag(player,"yuyun5")
							local s = room:askForPlayerChosen(player, targets, "yuyun_5", "@yuyun5", true)
							room:setPlayerFlag(player,"-yuyun5")
							if s and math.min(5,s:getMaxHp()) > s:getHandcardNum() then
								s:drawCards( math.min(5,s:getMaxHp()) - s:getHandcardNum() )
							end
						end
					end
				end
			end
		end
	end
}

mangqing = sgs.CreatePhaseChangeSkill{
	name = "mangqing",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 then
			local n = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isWounded() then
					n = n + 1
				end
			end

			if (n > player:getHp()) or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
				SendComLog(self, player)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player, self:objectName())
					room:doSuperLightbox("zhouyi","mangqing")
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 3))
					room:recover(player, sgs.RecoverStruct(player,nil,3))

					room:handleAcquireDetachSkills(player, "yuyun|-zhukou")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}

yuyuntm = sgs.CreateTargetModSkill{
	name = "#yuyuntm",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:getMark("@yuyun2-Clear") > 0 and card:isBlack() then
			return 1000
		end
	end,
	residue_func = function(self, player, card)
		if player:getMark("@yuyun2-Clear") > 0 and card:isBlack() then
			return 1000
		end
	end,
}

yuyunmc = sgs.CreateMaxCardsSkill{
	name = "#yuyunmc", 
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if target:getMark("@yuyun3-Clear") > 0 then
			return 1000
		end
	end
}


zhouyi:addSkill(zhukou)
zhouyi:addSkill(mangqing)
zhouyi:addRelateSkill("yuyun")
zhouyi:addRelateSkill("#yuyuntm")
zhouyi:addRelateSkill("#yuyunmc")

if not sgs.Sanguosha:getSkill("yuyun") then skills:append(yuyun) end
if not sgs.Sanguosha:getSkill("#yuyuntm") then skills:append(yuyuntm) end
if not sgs.Sanguosha:getSkill("#yuyunmc") then skills:append(yuyunmc) end

sgs.LoadTranslationTable{
["#zhouyi"] = "靛情雨黛",
["zhouyi"] = "周夷",
["&zhouyi"] = "周夷",
["zhukou"] = "逐寇",
["@zhukou"] = "你可以對至多兩名其他角色各造成1點傷害",
["~zhukou"] = "選擇角色 -> 點擊「確定」",
[":zhukou"] = "當妳於每個回合的出牌階段(別人回合也算)第一次造成傷害後，妳可以摸X張牌( X為本回合妳已使用的牌數)。妳的結束階段，若妳本回合沒有造成傷害，妳可以對至多兩名其他角色各造成1點傷害。",
["mangqing"] = "氓情",
[":mangqing"] = "覺醒技，準備階段，若已受傷的角色數大於妳的體力值，妳加3點體力上限並回復3點體力，失去“逐寇”，獲得“玉殞”。",
["yuyun"] = "玉殞",
["yuyun_lost"] = "玉殞",
["yuyun_2"] = "玉殞",
["yuyun_4"] = "玉殞",
["yuyun_5"] = "玉殞",
[":yuyun"] = "鎖定技，出牌階段開始時，若妳的體力上限大於1，妳失去1點體力或體力上限，然後選擇一項（若妳已損失體力值大於1，"..
"則多選一項）：1. 摸兩張牌；2. 對一名其他角色造成一點傷害，然後本回合對其使用【殺】無距離和次數限制；3.本回合沒有手牌上限；4.棄置一名其他角色區域內的一張牌；"..
"5.令一名其他角色將手牌摸至體力上限（最多摸至5）。",
["yuyun1"] = "摸兩張牌",
["yuyun2"] = "對一名其他角色造成一點傷害，然後本回合對其使用【殺】無距離和次數限制",
["@yuyun2"] = "對一名其他角色造成一點傷害，然後本回合對其使用【殺】無距離和次數限制",
["yuyun3"] = "本回合沒有手牌上限",
["yuyun4"] = "棄置一名其他角色區域內的一張牌",
["@yuyun4"] = "妳可以棄置一名其他角色區域內的一張牌",
["yuyun5"] = "令一名其他角色將手牌摸至體力上限（最多摸至5）。",
["@yuyun5"] = "妳可以令一名其他角色將手牌摸至體力上限（最多摸至5）。",
}


--[[
南華老仙
]]--

nanhualaoxian = sgs.General(extension, "nanhualaoxian", "qun2", 4, true)

gongxiu = sgs.CreateTriggerSkill{
	name = "gongxiu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:getMark("jinghe_used-Clear") > 0 then
				local choice = room:askForChoice(player, "gongxiu", "gongxiu1+gongxiu2+cancel")
				if choice ~= "cancel" then
					ChoiceLog(player, choice)
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())

					if choice == "gongxiu1" then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark("jinghe-Clear") > 0 then
								p:drawCards(1)
							end
						end
					elseif choice == "gongxiu2" then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark("jinghe-Clear") == 0 then
								room:askForDiscard(p,self:objectName(),1,1)
							end
						end
					end
				end
			end
		end
	end,
}

jingheCard = sgs.CreateSkillCard{
	name = "jinghe" ,
	filter = function(self, targets, to_select)
		return #targets < self:subcardsLength()
	end,
	will_throw =false,
	on_use = function(self, room, source, targets)
		ShowManyCards(source, self:getSubcards())
		room:addPlayerMark(source,"jinghe_used-Clear")
		local all_sks = {"tuxi","biyue","olleiji","zhiyan","mingce","nhyinbing","nhhuoqi","nhguizhu","nhxianshou","nhlundao","nhguanyue","nhyanzheng"}	
		for _,p in pairs(targets) do
			local choice = room:askForChoice(p, "jinghe", table.concat(all_sks, "+"))
			table.removeOne(all_sks,choice)
			if not p:hasSkill(choice) then
				room:addPlayerMark(p,"jinghe|"..choice.."|"..source:objectName())	
				room:addPlayerMark(p,"jinghe-Clear")				
				room:handleAcquireDetachSkills(p, choice)
				room:filterCards(p, p:getCards("h"), true)
			end
		end
	end
}
jinghe = sgs.CreateViewAsSkill{
	name = "jinghe" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			local card1 = selected[1]
			if to_select:objectName() ~= card1:objectName() then
				return true
			end
		elseif #selected == 2 then
			local card1 = selected[1]
			local card2 = selected[2]
			if to_select:objectName() ~= card1:objectName() and to_select:objectName() ~= card2:objectName() then
				return true
			end
		elseif #selected == 3 then
			local card1 = selected[1]
			local card2 = selected[2]
			local card3 = selected[3]
			if to_select:objectName() ~= card1:objectName() and to_select:objectName() ~= card2:objectName() and to_select:objectName() ~= card3:objectName()  then
				return true
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = jingheCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("jinghe_used-Clear") == 0
	end
}

jinghe_clear = sgs.CreateTriggerSkill{
	name = "jinghe_clear",
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then

				for _, skill in sgs.qlist(player:getSkillList(false, false)) do
					if player:getMark("jinghe|"..skill:objectName().."|"..player:objectName() ) > 0 then
						room:handleAcquireDetachSkills(player,"-"..skill:objectName())
						room:filterCards(player, player:getCards("h"), true)
					end
				end

				for _, p in sgs.qlist(room:getAlivePlayers()) do
					for _, skill in sgs.qlist(p:getSkillList(false, false)) do
						if p:getMark("jinghe|"..skill:objectName().."|"..player:objectName() ) > 0 then
							room:handleAcquireDetachSkills(p,"-"..skill:objectName())
							room:filterCards(p, p:getCards("h"), true)
						end
					end
				end
			end
		end
	end,
	priority = -10000,
	can_trigger = function(self, target)
		return target
	end
}

if not sgs.Sanguosha:getSkill("jinghe_clear") then skills:append(jinghe_clear) end

nanhualaoxian:addSkill(gongxiu)
nanhualaoxian:addSkill(jinghe)

sgs.LoadTranslationTable{
["nanhualaoxian"] = "南華老仙",
["gongxiu"] = "共修",
[":gongxiu"] = "你的回合結束階段，你可以選擇一項：1.所有在本回合通過“經合”獲得過技能的角色摸一張牌。2.所有在本回合未通過“經合”獲得過技能的其他角色棄置一張手牌。",
["gongxiu1"] = "所有在本回合通過“經合”獲得過技能的角色摸一張牌。",
["gongxiu2"] = "所有在本回合未通過“經合”獲得過技能的其他角色棄置一張手牌。",
["jinghe"] = "經合",
[":jinghe"] = "牌階段限一次，你可以展示至多四張牌名各不相同的牌，並選擇等量的角色。然後每名角色可以從“寫滿技能的天書”中選擇並獲得一個技能直到你的下回合開始。",
}

--[[
▲寫滿技能的天書

]]--

--☆雷擊：當你使用或打出【閃】時，你可以令一名其他角色進行判定，若結果為：黑桃，你對其造成2點雷電傷害；梅花，你回覆1點體力，然後對其造成1點雷電傷害。
--☆閉月：結束階段，你可以摸一張牌。
--☆突襲：摸牌階段，你可以放棄摸牌，改為獲得至多兩名其他角色的各一張手牌。
--☆明策：出牌階段限一次，你可以將一張裝備牌或【殺】交給一名其他角色，然後其選擇一項：1.視為對其攻擊範圍內你選擇的另一名角色使用一張【殺】；2.摸一張牌。
--☆直言：結束階段，你可以令一名角色摸一張牌並展示之，若此牌為裝備牌，則該角色使用此牌，然後其回覆1點體力。

--☆陰兵：鎖定技， 你使用的【殺】造成傷害改為失去體力。其他角色失去體力後，你摸一張牌。

nhyinbing = sgs.CreateTriggerSkill{
	name = "nhyinbing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpLost,sgs.Predamage},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.HpLost then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("nhyinbing") then
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					p:drawCards(1)
				end
			end
		elseif event == sgs.Predamage then
			local damage = data:toDamage()
			if damage.from:hasSkill("nhyinbing") and damage.card and damage.card:isKindOf("Slash") then
				room:notifySkillInvoked(damage.from, self:objectName())
				room:sendCompulsoryTriggerLog(damage.from, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(damage.to, damage.damage)
				return true
			end
		end
	end,

	can_trigger = function(self,target)
		return target:isAlive()
	end
}


--☆活氣：出牌階段限一次，你可以棄置一張牌，然後令體力值最少的一名角色回覆1點體力並摸一張牌。
nhhuoqiCard = sgs.CreateSkillCard{
	name = "nhhuoqi",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local n = sgs.Self:getHp()
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			n = math.max(n, p:getHp())
		end
		return #targets == 0 and to_select:getHp() == n
	end,
	on_use = function(self, room, source, targets)
		room:recover(targets[1], sgs.RecoverStruct(targets[1]))
		targets[1]:drawCards(1)
	end
}
nhhuoqi = sgs.CreateOneCardViewAsSkill{
	name = "nhhuoqi",
	filter_pattern = ".",
	view_as = function(self, card)
		local first = nhhuoqiCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#nhhuoqi")
	end
}

--☆鬼助：一名角色進入瀕死狀態時，你可以摸兩張牌（每回合限一次）。
--nhguizhu
nhguizhu = sgs.CreateTriggerSkill{
	name = "nhguizhu",
	events = {sgs.EnterDying},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
		room:sortByActionOrder(players)
		for _, p in sgs.qlist(players) do			
			if p:isAlive() and p:getMark("nhguizhu-Clear") == 0 then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:addPlayerMark(p, "nhguizhu-Clear")
					room:broadcastSkillInvoke(self:objectName())
					room:drawCards(p, 2, "nhguizhu")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

--☆仙授：出牌階段限一次，你可以選擇一名角色令其摸一張牌。若其體力值滿，則多摸一張。
--nhxianshou

nhxianshouCard = sgs.CreateSkillCard{
	name = "nhxianshou",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		if targets[1]:isWounded() then
			targets[1]:drawCards(1)
		else
			targets[1]:drawCards(2)
		end
	end,
}

nhxianshou = sgs.CreateZeroCardViewAsSkill{
	name = "nhxianshou",
	view_as = function()
		return nhxianshouCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#nhxianshou")
	end
}

--☆論道：當你受到傷害後，若傷害來源比你手牌多，你可以棄置其一張牌；若傷害來源比你手牌少，你摸一張牌。
--nhlundao

nhlundao = sgs.CreateMasochismSkill{
	name = "nhlundao" ,
	on_damaged = function(self, target, damage)
		local room = target:getRoom()
		if damage.from then
			local data = sgs.QVariant()
			data:setValue(damage.from)
			if room:askForSkillInvoke(target, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				if damage.from:getHandcardNum() > target:getHandcardNum() then
					local id2 = room:askForCardChosen(target, damage.from, "he", "nhlundao") 
					room:throwCard(id2, damage.from, target)
				end
				if damage.from:getHandcardNum() < target:getHandcardNum() then
					target:drawCards(1)
				end
			end
		end
	end
}

--☆觀月：結束階段，你可以觀看牌堆頂兩張牌，然後獲得其中一張，另一張放回牌堆頂。
--nhguanyue

nhguanyue = sgs.CreateTriggerSkill{
	name = "nhguanyue",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(player, self:objectName(), data) then
				local cards = room:getNCards(2, false)
				room:broadcastSkillInvoke(self:objectName())
				room:askForGuanxing(player, cards, sgs.Room_GuanxingUpOnly)
				room:obtainCard(player, room:getDrawPile():first(), false)
			end
		end
	end
}

--☆言政：準備階段，若你的手牌數大於1，你可以保留一張手牌棄置其餘的牌，然後選擇至多等於棄牌數量的角色，對這些角色各造成1點傷害。
--nhyanzheng
nhyanzhengCard = sgs.CreateSkillCard{
	name = "nhyanzheng", 
	filter = function(self, targets, to_select)
		return #targets < self:subcardsLength()
	end,
	will_throw = true,
	on_use = function(self, room, source, targets)
		for _,p in pairs(targets) do
			room:damage(sgs.DamageStruct(self:objectName(), source, p))
		end
	end
}
nhyanzhengVS = sgs.CreateViewAsSkill{
	name = "nhyanzheng", 
	n = 999,
	response_pattern = "@@nhyanzheng",
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		local count = sgs.Self:getHandcardNum() - 1
		if #cards == count then
			local srjiwucard = nhyanzhengCard:clone()
			for _,card in ipairs(cards) do
				srjiwucard:addSubcard(card)
			end
			srjiwucard:setSkillName(self:objectName())
			return srjiwucard
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end
}

nhyanzheng = sgs.CreateTriggerSkill{
	name = "nhyanzheng",
	view_as_skill = nhyanzhengVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_RoundStart and player:getHandcardNum() > 1 then
			room:askForUseCard(player, "@@nhyanzheng", "@nhyanzheng", -1, sgs.Card_MethodUse)
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("nhyinbing") then skills:append(nhyinbing) end
if not sgs.Sanguosha:getSkill("nhhuoqi") then skills:append(nhhuoqi) end
if not sgs.Sanguosha:getSkill("nhguizhu") then skills:append(nhguizhu) end
if not sgs.Sanguosha:getSkill("nhxianshou") then skills:append(nhxianshou) end
if not sgs.Sanguosha:getSkill("nhlundao") then skills:append(nhlundao) end
if not sgs.Sanguosha:getSkill("nhguanyue") then skills:append(nhguanyue) end
if not sgs.Sanguosha:getSkill("nhyanzheng") then skills:append(nhyanzheng) end

sgs.LoadTranslationTable{
["nhyinbing"] = "陰兵",
[":nhyinbing"] = "鎖定技，你使用的【殺】造成傷害改為失去體力。其他角色失去體力後，你摸一張牌。",

["nhhuoqi"] = "活氣",
[":nhhuoqi"] = "出牌階段限一次，你可以棄置一張牌，然後令體力值最少的一名角色回覆1點體力並摸一張牌。",

["nhguizhu"] = "鬼助",
[":nhguizhu"] = "一名角色進入瀕死狀態時，你可以摸兩張牌（每回合限一次）。",

["nhxianshou"] = "仙授",
[":nhxianshou"] = "出牌階段限一次，你可以選擇一名角色令其摸一張牌。若其體力值滿，則多摸一張。",

["nhlundao"] = "論道",
[":nhlundao"] = "當你受到傷害後，若傷害來源比你手牌多，你可以棄置其一張牌；若傷害來源比你手牌少，你摸一張牌。",

["nhguanyue"] = "觀月",
[":nhguanyue"] = "結束階段，你可以觀看牌堆頂兩張牌，然後獲得其中一張，另一張放回牌堆頂。",

["nhyanzheng"] = "言政",
[":nhyanzheng"] = "準備階段，若你的手牌數大於1，你可以保留一張手牌棄置其餘的牌，然後選擇至多等於棄牌數量的角色，對這些角色各造成1點傷害。",

["@@nhyanzheng"] = "選擇至多等於棄牌數量的角色，對這些角色各造成1點傷害。",
["~nhyanzheng"] = "選擇至多等於棄牌數量的角色-->點擊確定",
}

--OL王榮
ol_wangrong = sgs.General(extension,"ol_wangrong","qun2","3",false)
--豐姿
olfengzi = sgs.CreateTriggerSkill{
	name = "olfengzi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed,sgs.CardFinished},
	on_trigger = function(self, event, player, data,room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and
			 use.to:length() > 0 and player:getMark("olfengzi_Play") == 0 and
			 player:getPhase() == sgs.Player_Play then
				local card
				if use.card:isKindOf("BasicCard") then
					card = room:askForCard(player, "BasicCard", "@olfengzi", data, self:objectName())
				else
					card = room:askForCard(player, "TrickCard", "@olfengzi", data, self:objectName())
				end
				if card then
					room:addPlayerMark(player,"olfengzi_Play")
					room:setCardFlag(use.card,"olfengzi_card")
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and use.to:length() > 0 and use.card:hasFlag("olfengzi_card") then
				room:setCardFlag(use.card,"-olfengzi_card")		
				local use2 = sgs.CardUseStruct()
				use2.card = use.card
				use2.from = use.from
				for _, p in sgs.qlist(use.to) do
					if (not room:isProhibited(player, p, use.card)) then
						use2.to:append(p)
					end
				end

				if use2.to:isEmpty() then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:getThread():delay()
					room:useCard(use2)
				end
			end
		end
	end,
}

--吉占
oljizhan = sgs.CreateTriggerSkill{
	name = "oljizhan", 
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data,room)
		if event == sgs.DrawNCards then
			if data:toInt() > 0 then
				if room:askForSkillInvoke(player, "oljizhan", data) then
					room:notifySkillInvoked(player, "oljizhan")
					room:broadcastSkillInvoke("oljizhan")
					local card_to_get = {}
					local n1 = 0
					local n2 = 0
					while true do
						room:setPlayerMark(player,"oljizhan" , n1)
						local choice
						if n1 > 0 then
							room:setPlayerMark(player,"oljizhan" , n1)
							choice = room:askForChoice(player, "oljizhan", "oljizhan1+oljizhan2")
						end

						local ids = room:getNCards(1, false)
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = player
						move.to_place = sgs.Player_PlaceTable
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, 
							player:objectName(), self:objectName(), nil)
						room:moveCardsAtomic(move, true)
						room:getThread():delay()
						local id = ids:at(0)
						local card = sgs.Sanguosha:getCard(id)					
						n2 = card:getNumber()

						if n1 == 0 or (choice == "oljizhan1" and n2 > n1) or (choice == "oljizhan2" and n2 < n1)  then
							n1 = n2
							table.insert(card_to_get, id)
						else
							n1 = n2
							table.insert(card_to_get, id)
							break
						end
					end
					if #card_to_get > 0 then
						for _,card in pairs(card_to_get) do
							room:obtainCard(player, card, true)
						end
					end
					data:setValue(0)
					return true
				end
			end
		end
		return false
	end
}

--賦頌
olfusong = sgs.CreateTriggerSkill{
	name = "olfusong", 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data, room) 
		local death = data:toDeath()		
		if death.who:objectName() == player:objectName() then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMaxHp() > player:getMaxHp() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then			
				local target = room:askForPlayerChosen(player, targets, self:objectName(),"olfusong-invoke",true,true)
				if target then
					room:notifySkillInvoked(player, "olfusong")
					room:broadcastSkillInvoke("olfusong")
					room:doSuperLightbox("ol_wangrong", "olfusong")

					local choice = room:askForChoice(player, self:objectName(), "olfengzi+oljizhan")					
					room:handleAcquireDetachSkills(target, choice, false)					
				end
			end
		end
		return false
	end, 
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end
}

ol_wangrong:addSkill(olfengzi)
ol_wangrong:addSkill(oljizhan)
ol_wangrong:addSkill(olfusong)

sgs.LoadTranslationTable{
["ol_wangrong"] = "OL王榮",
["&ol_wangrong"] = "王榮",
["olfengzi"] = "豐姿",
[":olfengzi"] = "出牌階段限一次。當妳使用有目標的基本牌或普通錦囊牌時，妳可棄置一張與此牌類型相同的牌，然後令此牌結算兩次。",
["@olfengzi"] = "妳可棄置一張與此牌類型相同的牌，然後令此牌結算兩次",
["oljizhan"] = "吉占",
[":oljizhan"] = "摸牌階段開始時，妳可以放棄摸牌。妳展示牌堆頂的一張牌，並猜測牌堆頂的下一張牌點數大於或小於此牌。若妳猜對，妳可繼續重復此流程。然後妳獲得以此法展示的所有牌。",
["oljizhan1"] = "下一張牌點數大於此牌",
["oljizhan2"] = "下一張牌點數小於此牌",
["olfusong"] = "賦頌",
[":olfusong"] = "當妳死亡時，妳可以令一名體力上限大於妳的其他角色獲得〖吉占〗或〖豐姿〗。",
["olfusong-invoke"] = "妳可以發動〖賦頌〗",
}

--OL陶謙
ol_taoqian = sgs.General(extension, "ol_taoqian", "qun2", "3", true, true)
--義襄
ol_yixiang = sgs.CreateTriggerSkill{
	name = "ol_yixiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted,sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)		
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName()
			 and damage.card and damage.card:isKindOf("SkillCard")
			 and damage.from:getMark("used_Play") == 1 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())			
				local log = sgs.LogMessage()
				log.type = "#OlYixiangDecrease"
				log.from = player
				log.arg = damage.damage
				log.arg2 = damage.damage - 1
				room:sendLog(log)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					if damage.damage > 1 then
						damage.damage = damage.damage - 1
						data:setValue(damage)
					else
						return true
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.from:getMark("used_Play") == 2 and use.card:isBlack() then

						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						player:setFlags("-ZhenlieTarget")
						player:setFlags("ZhenlieTarget")
						if player:isAlive() and player:hasFlag("ZhenlieTarget") then
							player:setFlags("-ZhenlieTarget")
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
						end
				end
			end
		end
		return false
	end
}

--揖讓
ol_yirang = sgs.CreatePhaseChangeSkill{
	name = "ol_yirang",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local ids = sgs.IntList()
		local kind = {}
		for _, card in sgs.qlist(player:getCards("he")) do
			if not card:isKindOf("BasicCard") then
				ids:append(card:getId())
			end
		end
		if player:getPhase() == sgs.Player_Play and not ids:isEmpty() then
			local target = room:askForPlayerChosen(player,  room:getOtherPlayers(player) , self:objectName(), "ol_yirang-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(ids)
				target:obtainCard(dummy)
				if target:getMaxHp() > player:getMaxHp() then
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(target:getMaxHp()))
					room:recover(player, sgs.RecoverStruct(player, nil,  ids:length() ))
				end
			end
		end
		return false
	end
}

ol_taoqian:addSkill("zhaohuo")
ol_taoqian:addSkill(ol_yixiang)
ol_taoqian:addSkill(ol_yirang)



sgs.LoadTranslationTable{
["ol_taoqian"] = "陶謙",
["ol_yixiang"] = "義襄",
[":ol_yixiang"] = "鎖定技，其他角色於其出牌階段內使用的第一張牌對你的傷害-1；其使用的第二張牌若為黑色，則對你無效。",

["zhaohuo"] = "招禍",
[":zhaohuo"] = "鎖定技，當其他角色進入瀕死狀態時，你減X點體力上限，然後摸等量的牌。（X為你的體力上限-1）",
["ol_yirang"] = "揖讓",
[":ol_yirang"] = "出牌階段開始時，你可以將所有非基本牌交給一名角色，若其體力上限大於你，你將體力上限調整至與其相同，回復X點體力。（X為你以此法交給其的牌的類別數）",
["ol_yirang-invoke"] = "選擇一名其他角色，你可以將所有非基本牌交給他並發動「揖讓」", 

["#OlYixiangDecrease"] = "%from 的“<font color=\"yellow\"><b>義襄</b></font>”被觸發，傷害點數從 %arg 點減少至 %arg2 點" ,
}

--[[
童淵[新服]  群 4/4
]]--

tongyuan = sgs.General(extension, "tongyuan", "qun2", "4", true, true)

zhaofeng = sgs.CreateTriggerSkill{
	name = "zhaofeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if event == sgs.DamageCaused and player:getMark("zhaofeng_Play") == 0 then
			local card_limit = room:askForCard(player, ".", "@zhaofeng", data, self:objectName())
			if card_limit then
				room:addPlayerMark(player,"zhaofeng_Play")
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
				if damage.card then
					if GetColor(card_limit) == GetColor(damage.card) then
						player:drawCards(1)
					end
					if card_limit:getTypeId() == damage.card:getTypeId() then
						room:doAnimate(1, player:objectName(), damage.to:objectName())
						local log = sgs.LogMessage()
						log.type = "#ZhaofengIncrease"
						log.from = player
						log.arg = damage.damage
						log.arg2 = damage.damage + 1
						room:sendLog(log)
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							damage.damage = damage.damage + 1
							data:setValue(damage)
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
		end
		return false
	end
}

chuanshu = sgs.CreateTriggerSkill{
	name = "chuanshu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Limited,
	limit_mark = "@chuanshu", 
	on_trigger = function(self, event, player, data, room)
		if player:isWounded() and player:getMark("@chuanshu") > 0 and player:getPhase() == sgs.Player_Start then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "chuanshu-invoke", true, true)
			if target then
				room:removePlayerMark(player, "@chuanshu")
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("tongyuan","chuanshu")
				room:handleAcquireDetachSkills(target, "zhaofeng")						
				room:handleAcquireDetachSkills(player, "longdan|congjian|chuanyun")
			end
		end
	end,
}

chuanyun = sgs.CreateTriggerSkill{
	name = "chuanyun",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data,room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					if p:getEquips():length() > 0 then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if room:askForSkillInvoke(player, self:objectName(), _data) then
							
							local ids = getIntList(p:getCards("e"))
							local id = ids:at(math.random(0, ids:length() - 1))
							room:throwCard(card, p, nil)

						end
					end
				end
			end
		end
		return false
	end
}

tongyuan:addSkill(zhaofeng)
tongyuan:addSkill(chuanshu)
if not sgs.Sanguosha:getSkill("chuanyun") then skills:append(chuanyun) end
tongyuan:addRelateSkill("longdan")
tongyuan:addRelateSkill("congjian")
tongyuan:addRelateSkill("chuanyun")

sgs.LoadTranslationTable{
["tongyuan"] = "童淵",
["#tongyuan"] = "蓬萊槍神散人",
["zhaofeng"] = "朝鳳",
[":zhaofeng"] = "出牌階段限一次，當你造成傷害時，你可以棄置一張手牌，然後摸一張牌。若棄置的牌與造成傷害的牌顏色相同，則多摸一張牌；若棄置的牌與造成傷害的牌類別相同，則此傷害+1。",
["#ZhaofengIncrease"] = "%from 發動了“<font color=\"yellow\"><b>朝鳳</b></font>”，傷害點數從 %arg 點增加至 %arg2 點" ,
["chuanshu"] = "傳術",
[":chuanshu"] = "限定技，準備階段，若你已受傷，你可令一名其他角色獲得「朝鳳」，然後獲得「龍膽」、「從諫」和「穿雲」。",
["chuanyun"] = "穿雲",
[":chuanyun"] = "當你使用【殺】指定目標後，你可令該角色隨機棄置一張裝備區里的牌。",
["#ChuanshuWake"] = "%from 已受傷，觸發“%arg”覺醒",
["chuanshu-invoke"] = "令一名其他角色獲得「朝鳳」",
["@zhaofeng"] = "你可以發動“朝鳳”",
}

--[[
劉永[新服]  蜀 3/3

〖誅佞〗出牌階段限一次，你可以交給一名其他角色任意張牌，這些牌標記為「隙」，然後你可以視為使用—張不計次數的【殺】或傷害類錦囊牌，然後若此牌沒有造成傷害，此技能改為「出牌階段限兩次」。

〖封鄉〗鎖定技，當你受到傷害後，手牌中「隙」唯一最多的角色回復1點體力（沒有唯一最多的角色則改為你摸一張牌）；當有角色因手牌數改變而使「隙」唯一最多的角色改變時，你摸一張牌。
]]--
liuyong = sgs.General(extension, "liuyong", "shu2", "3", true)

zhuningCard = sgs.CreateSkillCard{
	name = "zhuning", 
	will_throw = false, 
	mute = true,
	handling_method = sgs.Card_MethodNone, 
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _,id in sgs.qlist(self:getSubcards()) do
				room:addPlayerMark(targets[1], "xi"..id )
			end

			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "zhuning", "")
			room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)

			local patterns = generateAllCardObjectNameTablePatterns()
			local choices = {}
			
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
					if card:isAvailable(source) and source:getMark("AG_BANCard"..card:objectName()) == 0 and (card:isKindOf("BasicCard") or card:isNDTrick()) and canCauseDamage(card) then
						table.insert(choices, card:objectName())
					end
				end
			end
			
			if next(choices) ~= nil then
				table.insert(choices,  "cancel" )
				local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
				if choice ~= "cancel" then
					room:setPlayerProperty(source, "zhuning", sgs.QVariant(choice))
					room:askForUseCard(source, "@@zhuning", "@zhuning", -1, sgs.Card_MethodUse)
					room:setPlayerProperty(source, "zhuning", sgs.QVariant())
				end
			end

			room:removePlayerMark(source, self:objectName().."engine")
		end
	end, 
}
zhuningVS = sgs.CreateViewAsSkill{
	name = "zhuning", 
	n = 999, 
	response_pattern = "@@zhuning", 
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@zhuning" then return false end
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@zhuning" then
			if #cards == 0 then
				local name = sgs.Self:property("zhuning"):toString()
				local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
				card:setSkillName("_zhuning")
				return card
			end
		else
			if #cards > 0 then
				local rende = zhuningCard:clone()
				for _, c in ipairs(cards) do
					rende:addSubcard(c)
				end
				rende:setSkillName("zhuning")
				return rende
			end
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("zhuning_Play") > 0 then
			return player:usedTimes("#zhuning") < 2 and not player:isKongcheng()
		end
		return not player:hasUsed("#zhuning") and not player:isKongcheng()
	end,
}

zhuning = sgs.CreateTriggerSkill{
	name = "zhuning",
	events = {sgs.CardFinished,sgs.CardsMoveOneTime},
	view_as_skill = zhuningVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()

			if move.to_place == sgs.Player_DiscardPile and move.from and move.from:objectName() == player:objectName() then
				for _, id in sgs.qlist(move.card_ids) do
					if player:getMark("xi"..id) > 0 then
						room:setPlayerMark(player,"xi"..id,0)
					end
				end
			end
		elseif event == sgs.CardFinished then		
			local use = data:toCardUse()
			if use.card and (not use.card:hasFlag("damage_record")) and use.card:getSkillName() == "_zhuning" and player:getMark("zhuning_Play") == 0 and player:isAlive() then
				room:addPlayerMark(player, "zhuning_Play")
				--room:addPlayerMark(player, "@zhuning_Play")
			end
		end
		return false
	end
}

fengxiang = sgs.CreateTriggerSkill{
	name = "fengxiang",
	events = {sgs.Damaged,sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local max_card_num = 0

		for _, p in sgs.qlist(room:getAlivePlayers()) do
			local n = 0
			for _, c in sgs.qlist(p:getHandcards()) do
				if p:getMark("xi"..c:getId()) > 0 then
					n = n + 1
				end
			end
			room:setPlayerMark(p,"fengxiang_card_num" , n)
			max_card_num = math.max(max_card_num,n)
		end

		local all_max_card_players = {}

		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if max_card_num == p:getMark("fengxiang_card_num") then
				table.insert(all_max_card_players, p)
			end
		end
		if #all_max_card_players > 0 then

			if event == sgs.Damaged then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				if #all_max_card_players == 1 then

					room:recover( all_max_card_players[1] , sgs.RecoverStruct( all_max_card_players[1] ))
				else
					player:drawCards(1,"fengxiang")
				end
			end
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if (not room:getTag("FirstRound"):toBool()) and move.reason.m_skillName ~= "fengxiang" and ((move.to and move.to_place == sgs.Player_PlaceHand
				 and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) or
				  (move.from and (move.from_places:contains(sgs.Player_PlaceHand)
				  or move.from_places:contains(sgs.Player_PlaceEquip)) and not (move.to and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))) then

				  	for _, p in sgs.qlist(room:getAlivePlayers()) do
						local n = 0
						for _, c in sgs.qlist(p:getHandcards()) do
							if p:getMark("xi"..c:getId()) > 0 then
								n = n + 1
							end
						end
						if n > 0 then
							local msg = sgs.LogMessage()
							msg.type = "#Fengxiang"
							msg.from = p
							msg.arg =  tostring(n)
							room:sendLog(msg)
						end
					end

					if #all_max_card_players == 1 then
						local msg = sgs.LogMessage()
						msg.type = "#FengxiangMax"
						msg.from = all_max_card_players[1]
						room:sendLog(msg)
					end

					local fengxiang_target = room:getTag("fengxiangTarget"):toPlayer()
					if fengxiang_target then

							local msg = sgs.LogMessage()
							msg.type = "#FengxiangMaxTag"
							msg.from = fengxiang_target
							room:sendLog(msg)

						if #all_max_card_players == 1 then
							if fengxiang_target:objectName() ~= all_max_card_players[1]:objectName() then
								player:drawCards(1,"fengxiang")
							end
						else
							room:notifySkillInvoked(player, self:objectName())
							room:sendCompulsoryTriggerLog(player, self:objectName()) 
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1,"fengxiang")
						end
					elseif #all_max_card_players == 1 then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1,"fengxiang")
					end
				end
			end

			if #all_max_card_players == 1 then
				local tag = sgs.QVariant()
				tag:setValue( all_max_card_players[1] )
				room:setTag("fengxiangTarget", tag)
			else
				room:setTag("fengxiangTarget",  sgs.QVariant() )
			end
		end
	end,
}

liuyong:addSkill(zhuning)
liuyong:addSkill(fengxiang)

sgs.LoadTranslationTable{
["liuyong"] = "劉永",
["zhuning"] = "誅佞",
["_zhuning"] = "誅佞",
["@zhuning"] = "你可以視為使用此牌",
["~zhuning"] = "選擇目標角色→點“確定”",
[":zhuning"] = "出牌階段限一次，你可以交給一名其他角色任意張牌，這些牌標記為「隙」，然後你可以視為使用—張不計次數的【殺】或傷害類錦囊牌，然後若此牌沒有造成傷害，此技能改為「出牌階段限兩次」。",
["fengxiang"] = "封鄉",
[":fengxiang"] = "鎖定技，當你受到傷害後，手牌中「隙」唯一最多的角色回復1點體力（沒有唯一最多的角色則改為你摸一張牌）；當有角色因手牌數改變而使「隙」唯一最多的角色改變時，你摸一張牌。",
["#Fengxiang"] = "%from 共有 %arg 張「隙」 ",
["#FengxiangMax"] = "%from 的「隙」為全場最多 ",
["#FengxiangMaxTag"] = "%from 的「隙」被記錄為全場最多 ",
}


--[[
張寧[新服]  群 3/3

〖天則〗其他角色於其出牌階段內使用一張黑桃手牌結算完畢後，你可以棄置一張黑色牌對其造成1點傷害（每回合限觸發1次）。其他角色的判定結果為黑桃時，你摸一張牌。

〖地法〗你的回合內，若你從牌堆摸到了紅桃牌，你可以棄置此牌，然後選擇一張錦囊牌從牌堆或棄牌堆獲得。 
]]--
zhangning = sgs.General(extension, "zhangning", "qun2", "3", false)

tianze = sgs.CreateTriggerSkill{
	name = "tianze" ,
	events = {sgs.FinishJudge,sgs.CardFinished} ,
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.card and judge.card:isBlack() then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("tianze") and judge.who:objectName() ~= p:objectName() then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(1, self:objectName())
					end
				end
			end
		else
			local card = data:toCardUse().card
			if card and (not card:isKindOf("SkillCard")) and card:getSkillName() ~= "xiongzhi" and player:getPhase() == sgs.Player_Play and card:isBlack() then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill("tianze") and p:getMark("tianze_invoke-Clear") == 0 then
						room:setPlayerFlag(player, "tianze_target")
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForCard(p, ".|black", "@tianze:" .. player:objectName(), _data, sgs.Card_MethodDiscard) then
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerFlag(player, "-tianze_target")
							room:addPlayerMark(p, "tianze_invoke-Clear")
							room:damage(sgs.DamageStruct(self:objectName(), p, player, 1, sgs.DamageStruct_Normal))
						end
					end
				end
			end
		end
	end
}

difa = sgs.CreateTriggerSkill{
	name = "difa",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if event == sgs.CardsMoveOneTime and (not room:getTag("FirstRound"):toBool()) and move.to and move.to:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_NotActive and player:getMark("difa-Clear") == 0 then
			--for i = 0, (move.card_ids:length() - 1), 1 do
			--	local id = move.card_ids:at(i)
			--and move.from_places:at(i) == sgs.Player_DrawPile
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isRed() then
					if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:addPlayerMark(player,"difa-Clear")
							room:broadcastSkillInvoke(self:objectName())
							local DPHeart = sgs.IntList()
							DPHeart:append(id)
						
							room:broadcastSkillInvoke(self:objectName())
							local move2 = sgs.CardsMoveStruct()
							move2.card_ids = DPHeart
							move2.to = nil
							move2.to_place = sgs.Player_DiscardPile
							move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "difa", nil)
							room:moveCardsAtomic(move2, true)

							local choices = {}
							for i = 0, 10000 do
								local card = sgs.Sanguosha:getEngineCard(i)
								if card == nil then break end
								if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) and player:getMark("AG_BANCard"..card:objectName()) == 0 then
									if card:isNDTrick() then
										table.insert(choices, card:objectName())
									end
								end
							end

							local pattern = room:askForChoice(player, "difa", table.concat(choices, "+"))

							--table.insert(choices, "binglinchengxia")
							table.insert(choices, "cancel")

							local GetCardList = sgs.IntList()
							local DPHeart = sgs.IntList()
							if room:getDrawPile():length() > 0 then
								for _, id in sgs.qlist(room:getDrawPile()) do
									local card = sgs.Sanguosha:getCard(id)
									if card:objectName() == pattern then
										DPHeart:append(id)
									end
								end
							end
							if room:getDiscardPile():length() > 0 then
								for _, id in sgs.qlist(room:getDiscardPile()) do
									local card = sgs.Sanguosha:getCard(id)
									if card:objectName() == pattern then
										DPHeart:append(id)
									end
								end
							end
							if DPHeart:length() > 0 then
								local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
								GetCardList:append(get_id)
								local card = sgs.Sanguosha:getCard(get_id)
							end
							if GetCardList:length() > 0 then
								local move3 = sgs.CardsMoveStruct()
								move3.card_ids = GetCardList
								move3.to = player
								move3.to_place = sgs.Player_PlaceHand
								room:moveCardsAtomic(move3, true)
							end
						end
					end
				end
			end
		end
		return false
	end,
}

zhangning:addSkill(tianze)
zhangning:addSkill(difa)

sgs.LoadTranslationTable{
["zhangning"] = "張寧",
["#zhangning"] = "大賢後人",
["tianze"] = "天則",
[":tianze"] = "每回合限一次，其他角色於其出牌階段內使用一張黑色手牌結算完畢後，妳可以棄置一張黑色牌對其造成1點傷害（每回合限觸發1次）。其他角色的黑色判定牌生效時，妳摸一張牌。",
["difa"] = "地法",
[":difa"] = "妳的回合內限一次，若妳從牌堆摸到了紅色牌，妳可以棄置此牌，然後選擇一張錦囊牌名並從牌堆或棄牌堆獲得之。",
["@tianze"] = "妳可以棄置一張黑色牌並對 %src 造成1點傷害",
}

--[[
萬年公主
【枕戈】準備階段，你可以選擇一名角色，該角色本局遊戲的攻擊範圍+1（至多+5）。若此時全場角色都在該角色的攻擊範圍內，
你可以令其視為對另一名角色使用了一張【殺】。

【興漢】鎖定技，每回合的第一張【殺】造成傷害後，若此【殺】的使用者是你對其發動過“枕戈”的角色，
你摸一張牌。若你的手牌數不是全場唯一最多的，則改為摸X張牌（X為該角色的攻擊範圍且最多為5）。
]]--
wanniangongzhu = sgs.General(extension, "wanniangongzhu", "qun2", 3,false)

zhenge = sgs.CreateTriggerSkill{
	name = "zhenge",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				local p = room:askForPlayerChosen(player, room:getAlivePlayers(), "zhenge", "@zhenge-choose", true)
				if p then
					room:addPlayerMark(p,"@zhenge")
					room:addPlayerMark(p,"zhenge"..player:objectName())
					local can_use_slash = true
					for _,pp in sgs.qlist(room:getOtherPlayers(p)) do
						if not p:inMyAttackRange(pp) then
							can_use_slash = false
						end
					end
					if can_use_slash then
						local _targets = sgs.SPlayerList()
						for _, pp in sgs.qlist(room:getOtherPlayers(p)) do
							if p:canSlash(pp, nil, false) then _targets:append(pp) end
						end
						if not _targets:isEmpty() then
							local target = room:askForPlayerChosen(player, _targets, "zhenge2", "@zhenge2-choose", true)
							if target then
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:setSkillName("_zhenge")
								room:useCard(sgs.CardUseStruct(slash, p, target))
							end
						end
					end	
				end
			end
		end
	end,
}
--[[
zhengeTM = sgs.CreateTargetModSkill{
	name = "#zhenge",
	pattern = ".",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("zhenge") and card:isKindOf("Slash") then
			return from:getMark("@zhenge")
		end
	end
}
]]--
zhengeTM = sgs.CreateAttackRangeSkill{
	name = "#zhenge",
	extra_func = function(self, player, include_weapon)
		return player:getMark("@zhenge")
	end ,
}

xinghan = sgs.CreateTriggerSkill{
	name = "xinghan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("first_slash_by_every_player-Clear") then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("zhenge"..p:objectName()) > 0 then
						--檢定是否手牌唯一最多
						local most_card = true
						for _, pp in sgs.qlist(room:getOtherPlayers(p)) do
							if pp:getHandcardNum() >= p:getHandcardNum() then
								most_card = false
								break	
							end
						end
						if most_card then
							p:drawCards(1)
						else
							local n = math.min( player:getAttackRange()  ,5)
							p:drawCards(n)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

wanniangongzhu:addSkill(zhenge)
wanniangongzhu:addSkill(zhengeTM)
wanniangongzhu:addSkill(xinghan)

sgs.LoadTranslationTable{
["wanniangongzhu"] = "萬年公主",
["#wanniangongzhu"] = "還漢明珠",
["zhenge"] = "枕戈",
[":zhenge"] = "準備階段，妳可以選擇一名角色，該角色本局遊戲的攻擊範圍+1（至多+5）。若此時全場角色都在該角色的攻擊範圍內，妳可以令其視為對另一名角色使用了一張【殺】。",
["@zhenge-choose"] = "妳可以選擇一名角色並發動「枕戈」",
["zhenge2"] = "枕戈",
["@zhenge2-choose"] = "妳可以令其視為對另一名角色使用【殺】",
["xinghan"] = "興漢",
[":xinghan"] = "鎖定技，每回合的第一張【殺】造成傷害後，若此【殺】的使用者是妳對其發動過“枕戈”的角色，妳摸一張牌。若妳的手牌數不是全場唯一最多的，則改為摸X張牌（X為該角色的攻擊範圍且最多為5）。",
}


--[[
荀諶[新服]  群 3/3

〖鋒略〗出牌階段限一次，你可以和一名其他角色拼點。若你贏，該角色交給你其區域內的兩張牌；若點數相同，此技能額視為未發動過；若你輸，該角色獲得你拼點的牌。

〖暗湧〗當一名角色於其回合內第一次對另一名角色造成傷害後，若此傷害值為1，你可以棄置一張牌然後對相同的角色造成1點傷害。 
]]--
re_xunchen = sgs.General(extension, "re_xunchen", "qun2", 3,true,true)

refenglveCard = sgs.CreateSkillCard{
	name = "refenglve",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			source:pindian(targets[1], "refenglve", sgs.Sanguosha:getCard(self:getSubcards():first()))
		end
	end
}

refenglveVS = sgs.CreateOneCardViewAsSkill{
	name = "refenglve",
	--filter_pattern = ".|.|.|hand!",
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local aaa = refenglveCard:clone()
		aaa:addSubcard(card)
		return aaa
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#refenglve") < 1 + player:getMark("refenglve-Clear")
	end
}

refenglve = sgs.CreateTriggerSkill{
	name = "refenglve",
	view_as_skill = refenglveVS,
	events = {sgs.Pindian}, 
	on_trigger = function(self, event, player, data, room) 
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason ~= self:objectName() then return false end
			if pindian.from_number > pindian.to_number then
				local give_cards = room:askForExchange(pindian.to, self:objectName(), 2,2, true, "refenglve_exchange")
				if give_cards then
					room:obtainCard(pindian.from, give_cards, false)
				end
			elseif pindian.from_number < pindian.to_number and room:getCardPlace(pindian.from_card:getEffectiveId()) == sgs.Player_PlaceTable then
				room:obtainCard(pindian.to, pindian.from_card, false)
			else
				room:addPlayerMark(pindian.from,"refenglve-Clear")
				
			end
		end	
	end,
}





anyong = sgs.CreateTriggerSkill{
	name = "anyong",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.from and damage.from:getPhase() ~= sgs.Player_NotActive and damage.from:getMark("damage_record-Clear") == 0 and damage.damage == 1 and damage.reason == self:objectName() then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:setPlayerFlag(damage.to, "anyong_target")
					local _data = sgs.QVariant()
					_data:setValue(damage.to)
					if room:askForCard(p, "..", "@anyong:" .. damage.to:objectName(), _data, sgs.Card_MethodDiscard) then
						room:notifySkillInvoked(damage.to, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerFlag(damage.to, "-anyong_target")
						room:addPlayerMark(p, "anyong_invoke-Clear")
						room:damage(sgs.DamageStruct(self:objectName(), p, damage.to, 1, sgs.DamageStruct_Normal))
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

re_xunchen:addSkill(refenglve)
re_xunchen:addSkill(anyong)

sgs.LoadTranslationTable{
["re_xunchen"] = "新服荀諶",
["&re_xunchen"] = "荀諶",
["#re_xunchen"] = "",
["refenglve"] = "鋒略",
[":refenglve"] = "出牌階段限一次，你可以和一名其他角色拼點。若你贏，該角色交給你其區域內的兩張牌；若點數相同，此技能額視為未發動過；若你輸，該角色獲得你拼點的牌。",
["anyong"] = "暗湧",
[":anyong"] = "當一名角色於其回合內第一次對另一名角色造成傷害後，若此傷害值為1，你可以棄置一張牌然後對相同的角色造成1點傷害。",
["@anyong"] = "你可以棄置一張牌並對 %src 造成1點傷害",
}

--[[
何晏
]]--
heyan = sgs.General(extension, "heyan", "wei2", 3,true)

yachai = sgs.CreateTriggerSkill{
	name = "yachai",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() ~= player:objectName() then
				local _data = sgs.QVariant()
				_data:setValue(damage.from)
				if room:askForSkillInvoke(player, self:objectName(), _data) then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local choices = {"yachai1","yachai2","yachai3"}
						local choice = room:askForChoice(damage.from, self:objectName(), table.concat(choices, "+"), data)

						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						ChoiceLog(damage.from, choice)
						if choice == "yachai1" then
							if (not damage.from:isKongcheng()) then
								local n = (damage.from:getHandcardNum() + 1) / 2
								local qiaosi_give_cards = room:askForExchange(damage.from, self:objectName(), n, n, true, "qiaosi_exchange")
								if qiaosi_give_cards then
									room:throwCard(qiaosi_give_cards,player,player)
								end
							end
						elseif choice == "yachai2" then
							room:addPlayerMark(damage.from, "ban_ur")
							room:setPlayerCardLimitation(damage.from, "use,response", ".|.|.|hand", false)
							player:drawCards(2)
						elseif choice == "yachai3" then
							if (not damage.from:isKongcheng()) then
								room:showAllCards(damage.from)
								local give_suit_name_table = {}
								for _, c in sgs.qlist(damage.from:getHandcards()) do
									if c:getSuitString() == "spade" and not table.contains(give_suit_name_table, c:getSuitString()) then
										table.insert(give_suit_name_table, c:getSuitString())
									elseif c:getSuitString() == "club" and not table.contains(give_suit_name_table, c:getSuitString()) then
										table.insert(give_suit_name_table, c:getSuitString())
									elseif c:getSuitString() == "heart" and not table.contains(give_suit_name_table, c:getSuitString()) then
										table.insert(give_suit_name_table, c:getSuitString())
									elseif c:getSuitString() == "diamond" and not table.contains(give_suit_name_table, c:getSuitString()) then
										table.insert(give_suit_name_table, c:getSuitString())
									end
								end

								local give_suit_name_choice = room:askForChoice(damage.from, "yachai_suit", table.concat(give_suit_name_table, "+"))
								
								local ids = sgs.IntList()
								for _, card in sgs.qlist( damage.from:getHandcards() ) do
									if card:getSuitString() == give_suit_name_choice then
										ids:append(card:getEffectiveId())
									end
								end

								local move3 = sgs.CardsMoveStruct()
								move3.card_ids = ids
								move3.to_place = sgs.Player_PlaceHand
								move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, damage.from:objectName(), player:objectName(), "yachai","")
								move3.to = player						
								room:moveCardsAtomic(move3, true)
							end
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end,
}

qingtanCard = sgs.CreateSkillCard{
	name = "qingtan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if not source:isKongcheng() then
			local card = room:askForCard(source, ".", "@qingtan", sgs.QVariant(), sgs.Card_MethodNone)
			room:setPlayerMark(source, self:objectName(), card:getEffectiveId() )
		end
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if not p:isKongcheng() then
				local card = room:askForCard(p, ".", "@qingtan", sgs.QVariant(), sgs.Card_MethodNone)
				--room:showCard(p, card:getEffectiveId())
				room:setPlayerMark(p, self:objectName(), card:getEffectiveId() )
			end
		end

		if not source:isKongcheng() then
			room:showCard(source, source:getMark(self:objectName()) )
		end
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if not p:isKongcheng() then
				room:showCard(p, p:getMark(self:objectName()) )
			end
		end

		local spade_count = 0
		local club_count = 0
		local heart_count = 0
		local diamond_count = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			local card = sgs.Sanguosha:getCard(p:getMark(self:objectName()))
			if card:getSuitString() == "spade" then
				spade_count = spade_count + 1
			elseif card:getSuitString() == "club" then
				club_count = club_count + 1
			elseif card:getSuitString() == "heart" then
				heart_count = heart_count + 1
			elseif card:getSuitString() == "diamond" then
				diamond_count = diamond_count + 1
			end
		end

		local choices = {}
		if spade_count == math.max(spade_count,club_count,heart_count,diamond_count) then
			table.insert(choices, "spade" )
		end
		if club_count == math.max(spade_count,club_count,heart_count,diamond_count) then
			table.insert(choices, "club" )
		end
		if heart_count == math.max(spade_count,club_count,heart_count,diamond_count) then
			table.insert(choices, "heart" )
		end
		if diamond_count == math.max(spade_count,club_count,heart_count,diamond_count) then
			table.insert(choices, "diamond" )
		end

		if #choices == 1 then
			local choice = room:askForChoice(source, "qingtan", table.concat(choices, "+"))

			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark(self:objectName()) > 0 then
					local card2 = sgs.Sanguosha:getCard(p:getMark(self:objectName()))
					if card2:getSuitString() == choice then
						room:obtainCard(source,card2,true)
						p:drawCards(1)
					else
						room:throwCard(card2,nil,nil)
					end
				end
			end
		end
	end,
}

qingtan = sgs.CreateZeroCardViewAsSkill{
	name = "qingtan",
	view_as = function()
		return qingtanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#qingtan")
	end
}

heyan:addSkill(yachai)
heyan:addSkill(qingtan)


sgs.LoadTranslationTable{
["heyan"] = "何晏",
["yachai"] = "崖柴",
[":yachai"] = "當你受到傷害後，你可令傷害來源選擇一項：①棄置半數手牌（向上取整）；②其本回合不能再使用手牌，你摸兩張牌"
.."；③其展示所有手牌，然後將手牌中一種花色的所有牌交給你。",
["yachai_suit"] = "崖柴",
["yachai1"] = "棄置半數手牌（向上取整）",
["yachai2"] = "其本回合不能再使用手牌，你摸兩張牌",
["yachai3"] = "其展示所有手牌，然後將手牌中一種花色的所有牌交給你",
["qingtan"] = "清談",
[":qingtan"] = "出牌階段限一次，你可令所有有手牌的角色同時選擇一張手牌並同時展示。你可以獲得其中花色唯一最多的牌，然後展示"
.."此花色牌的角色各摸一張牌。若如此做，棄置其他的牌。",
["@qingtan"] = "“清談”技能效果，請展示一張手牌",
}

--[[
朱靈
急陷  摸牌階段結束時，你可以視為對滿足以下任意條件的目標使用一張【殺】並摸X張牌（X為滿足的條件數）：
裝備區有防具，技能數多於你，未受傷；若此【殺】沒有對其造成傷害，你失去一點體力。
]]--
ol_zhuling = sgs.General(extension, "ol_zhuling", "wei2", 4, true)

zljixianCard = sgs.CreateSkillCard{
	name = "zljixian",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			if target:getArmor() or (target:getVisibleSkillList():length() > sgs.Self:getVisibleSkillList():length())
			 or (not target:isWounded()) then
				targets_list:append(target)
			end
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("_"..self:objectName())
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if not targets_list:isEmpty() then
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("_"..self:objectName())
				room:useCard(sgs.CardUseStruct(slash, source, targets_list))
				room:removePlayerMark(source, self:objectName().."engine")
			end

			local n = 0
			if targets[1]:getArmor() then
				n = n + 1
			end
			if targets[1]:getVisibleSkillList():length() > source:getVisibleSkillList():length() then
				n = n + 1
			end
			if not targets[1]:isWounded() then
				n = n + 1
			end
			source:drawCards(n)
		end
	end
}
zljixianVS = sgs.CreateZeroCardViewAsSkill{
	name = "zljixian",
	view_as = function()
		return zljixianCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@zljixian"
	end
}
zljixian = sgs.CreateTriggerSkill{
	name = "zljixian",
	view_as_skill = zljixianVS,
	events = {sgs.EventPhaseEnd,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Draw then
				player:getRoom():askForUseCard(player, "@@zljixian", "@zljixian")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (not use.card:hasFlag("damage_record")) and use.card:getSkillName() == "_zljixian" then
				room:loseHp(player,1)
			end
		end
		return false
	end
}

zljixiantm = sgs.CreateTargetModSkill{
	name = "#zljixiantm",
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		local n = 0
		if card:getSkillName() == "zljixian" then
			return 1000
		end
	end
}

ol_zhuling:addSkill(zljixian)
ol_zhuling:addSkill(zljixiantm)

sgs.LoadTranslationTable{
["#ol_zhuling"] = "",
["ol_zhuling"] = "OL朱靈",
["&ol_zhuling"] = "朱靈",
["zljixian"] = "急陷",
[":zljixian"] = "摸牌階段結束時，你可以視為對滿足以下任意條件的目標使用一張【殺】並摸X張牌（X為滿足的條件數）：裝備區有防具，技能數多於你，未受傷；若此【殺】沒有對其造成傷害，你失去一點體力。",
	["@zljixian"] = "你可以發動“影箭”",
	["~zljixian"] = "選擇一名角色→點擊確定",
}

--[[
楊儀（3勾玉血量

狷狹 回合結束時，你可從僅指定單一目標的普通錦囊牌中選擇至多兩張，視為對一名其他角色依次使用選擇的牌，若如此做，
該角色下回合結束時可視為對你使用等量張【殺】。

定措 每回合限一次，當你造成或受到傷害後，你可以摸兩張牌；若這兩張牌顏色不同，你棄置一張手牌。
]]--
ol_yangyi = sgs.General(extension, "ol_yangyi", "shu2", 3, true,true)

juanxia = sgs.CreateTriggerSkill{
	name = "juanxia",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				if RIGHT(self, player) then
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "juanxia-invoke",true, true)
					if target then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						for ii = 1,2,1 do
							local patterns = generateAllCardObjectNameTablePatterns()
							local choices = {}
							
							for i = 0, 10000 do
								local card = sgs.Sanguosha:getEngineCard(i)
								if card == nil then break end
								if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
									if card:isAvailable(player) and player:getMark("AG_BANCard"..card:objectName()) == 0 and card:isNDTrick() and
									  (not card:isKindOf("AOE")) and (not card:isKindOf("Collateral")) then
										table.insert(choices, card:objectName())
									end
								end
							end
							
							if next(choices) ~= nil then
								table.insert(choices, "cancel")
								local pattern = room:askForChoice(player, "juanxia", table.concat(choices, "+"))
								if pattern and pattern ~= "cancel" then
									local DCR_card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
									DCR_card:setSkillName("_juanxia")
									if DCR_card:isAvailable(player) and DCR_card:isNDTrick() then
										
										room:useCard(sgs.CardUseStruct(DCR_card, player, target))

										room:addPlayerMark(target,"juanxia_target"..player:objectName())
									end
								end
							end
						end
					end
				end
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("juanxia_target"..p:objectName()) > 0 then
							for i = 1,player:getMark("juanxia_target"..p:objectName()),1 do
								if player:canSlash(p, nil, false) then
									local _data = sgs.QVariant()
									_data:setValue(p)
									if room:askForSkillInvoke(player, self:objectName(), _data) then
										local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
										slash:setSkillName("juanxia_slash")
										room:useCard(sgs.CardUseStruct(slash, player, p))
									end
								end
							end
						end
					end

					for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "juanxia_target") and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
						end
					end
			end
		end
	end
}



dingcuo = sgs.CreateTriggerSkill{
	name = "dingcuo", 
	events = {sgs.Damage, sgs.Damaged,sgs.CardsMoveOneTime}, 
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.Damage or event == sgs.Damaged) and player:getMark("dingcuo-Clear") == 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player,"dingcuo-Clear")
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2,self:objectName())
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and move.reason.m_skillName == self:objectName() then
				if GetColor(sgs.Sanguosha:getCard(move.card_ids:at(0))) ~= GetColor(sgs.Sanguosha:getCard(move.card_ids:at(1))) then
					room:askForDiscard(player, "dingcuo", 1, 1, false, false)
				end
			end
		end
		return false
	end
}

ol_yangyi:addSkill(juanxia)
ol_yangyi:addSkill(dingcuo)

sgs.LoadTranslationTable{
["#ol_yangyi"] = "",
["ol_yangyi"] = "OL楊儀",
["&ol_yangyi"] = "楊儀",

["juanxia"] = "狷狹",
[":juanxia"] = "回合結束時，你可從僅指定單一目標的普通錦囊牌中選擇至多兩張，視為對一名其他角色依次使用選擇的牌，若如此做，該角色下回合結束時可視為對你使用等量張【殺】。",
["juanxia-invoke"] = "你可以發動“狷狹”",

["dingcuo"] = "定措",
[":dingcuo"] = "每回合限一次，當你造成或受到傷害後，你可以摸兩張牌；若這兩張牌顏色不同，你棄置一張手牌。",

}


--[[
馮方女
【妝梳】一名角色的回合開始時,你可棄置一張手牌,然後根據此牌的類型,將一張場上沒有的「寶梳」置於其寶物區:基本牌,【瓊梳】;錦囊牌,【犀梳】;裝備牌,【金梳】。「寶梳」在離開裝備區後銷毀。

【垂涕】 每回合限一次,你的一張牌因棄置置入棄牌堆後,若你能使用此牌則你可以使用之。

【瓊梳】裝備寶物:每回合限一次,你使用【殺】指定唯一目標後,可選擇一名與目標體力值相同或手牌相同的額外目標,且額外目標不能響應此【殺】。

【犀梳】裝備寶物:判定階段開始時,你可棄置一張牌跳過你的判定階段;棄牌階段開始時,你可以棄置一張牌跳過你的棄牌階段。

【金梳】裝備寶物牌:鎖定技,出牌階段開始時,你摸牌至手牌上限。
]]--

fengfangnu = sgs.General(extension, "fengfangnu", "qun2", "3",false,true)

qiongshu = sgs.CreateTreasure{
	name = "qiongshu",
	class_name = "qiongshu",
	suit = sgs.Card_Spade,
	number = 12,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("qiongshuSkill")
		room:getThread():addTriggerSkill(skill)
	end
}

qiongshuSkill = sgs.CreateTriggerSkill{
	name = "qiongshuSkill",
	events = {sgs.PreCardUsed,sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:length() == 1 then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not use.to:contains(p) and not room:isProhibited(player, p, use.card) and
					  (use.to:at(0):getHandcardNum() == p:getHandcardNum() or use.to:at(0):getHp() == p:getHp()) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:setTag("qiongshuSkillData", data)
					local target = room:askForPlayerChosen(player, players, "qiongshu","qiongshu-invoke", true, false)
					room:removeTag("qiongshuSkillData")
					if target then
						room:addPlayerMark(target, "qiongshuSkill-Clear")
						use.to:append(target)
						room:sortByActionOrder(use.to)
						data:setValue(use)
						local msg = sgs.LogMessage()
						msg.type = "#ExtraTarget"
						msg.from = player
						msg.to:append(target)
						msg.arg = self:objectName()
						msg.card_str = use.card:toString()
						room:sendLog(msg)
					end
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player and player:isAlive() then
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1

				for _, p in sgs.qlist(use.to) do
					if p:getMark("qiongshuSkill-Clear") > 0 then
						jink_table[index] = 0
						index = index + 1
						room:setPlayerMark(p,"qiongshuSkill-Clear",0)
					end
				end

				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("qiongshu")
	end,
}

xishu = sgs.CreateTreasure{
	name = "xishu",
	class_name = "xishu",
	suit = sgs.Card_Club,
	number = 12,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("xishuSkill")
		room:getThread():addTriggerSkill(skill)
	end
}

xishuSkill = sgs.CreateTriggerSkill{
	name = "xishuSkill",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_Judge then
				if room:askForCard(srcaocao, "..", "xishu-judge", sgs.QVariant(), sgs.Card_MethodDiscard) then
					player:skip(sgs.Player_Judge)
				end
			end

			if data:toPhaseChange().to == sgs.Player_Discard then
				if room:askForCard(srcaocao, "..", "xishu-discard", sgs.QVariant(), sgs.Card_MethodDiscard) then
					player:skip(sgs.Player_Discard)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("xishu")
	end,
}

jinshu = sgs.CreateTreasure{
	name = "jinshu",
	class_name = "jinshu",
	suit = sgs.Card_Heart,
	number = 12,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("jinshuSkill")
		room:getThread():addTriggerSkill(skill)
	end
}

jinshuSkill = sgs.CreateTriggerSkill{
	name = "jinshuSkill",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:getMaxHp() > player:getHandcardNum() then
				local n = player:getMaxHp() - player:getHandcardNum()
				player:drawCards(n)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("jinshu")
	end,
}

qiongshu:setParent(extension)
xishu:setParent(extension)
jinshu:setParent(extension)

if not sgs.Sanguosha:getSkill("qiongshuSkill") then skills:append(qiongshuSkill) end
if not sgs.Sanguosha:getSkill("xishuSkill") then skills:append(xishuSkill) end
if not sgs.Sanguosha:getSkill("jinshuSkill") then skills:append(jinshuSkill) end

zhuangshu = sgs.CreateTriggerSkill{
	name = "zhuangshu" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill("zhuangshu") and (not player:isNude()) then
							
						
							local id = room:askForCard(p, ".", "@zhuangshu", data, sgs.Card_MethodDiscard)
							if id then
								room:doAnimate(1, p:objectName(), player:objectName())
								if id:isKindOf("BasicCard") and player:getMark("hasequip_QS") == 0 then
									for _, pp in sgs.qlist(room:getAlivePlayers()) do
										room:setPlayerMark(pp,"hasequip_QS",1)
									end
									local eid = room:getTag("QS_ID"):toInt()
									--local getcard = sgs.Sanguosha:getCard(room:getTag("QS_ID"):toInt())
									local move = sgs.CardsMoveStruct(eid, nil, player, room:getCardPlace(eid), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
									room:moveCardsAtomic(move, false)
								end
								if id:isKindOf("TrickCard") and player:getMark("hasequip_XS") == 0 then
									for _, pp in sgs.qlist(room:getAlivePlayers()) do
										room:setPlayerMark(pp,"hasequip_XS",1)
									end
									local eid = room:getTag("XS_ID"):toInt()
									--local getcard = sgs.Sanguosha:getCard(room:getTag("XS_ID"):toInt())
									local move = sgs.CardsMoveStruct(eid, nil, player, room:getCardPlace(eid), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
									room:moveCardsAtomic(move, false)
								end
								if id:isKindOf("EquipCard") and player:getMark("hasequip_JS") == 0 then
									for _, pp in sgs.qlist(room:getAlivePlayers()) do
										room:setPlayerMark(pp,"hasequip_JS",1)
									end
									local eid = room:getTag("JS_ID"):toInt()
									--local getcard = sgs.Sanguosha:getCard(room:getTag("JS_ID"):toInt())
									local move = sgs.CardsMoveStruct(eid, nil, player, room:getCardPlace(eid), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
									room:moveCardsAtomic(move, false)
								end
								room:broadcastSkillInvoke(self:objectName())
							end
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

chuitiCard = sgs.CreateSkillCard{
	name = "chuiti",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end, 
	feasible = function(self, targets)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and card:targetsFeasible(targets_list, sgs.Self)
	end,
	about_to_use = function(self, room, use)
		local ids = sgs.IntList()
		local list = use.from:property(self:objectName()):toString():split("+")
		if #list > 0 then
			for _,l in pairs(list) do
				ids:append(tonumber(l))
			end
		end
		local _guojia = sgs.SPlayerList()
		_guojia:append(use.from)
		local move_to = sgs.CardsMoveStruct(ids, use.from, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
		local moves_to = sgs.CardsMoveList()
		moves_to:append(move_to)
		room:notifyMoveCards(true, moves_to, false, _guojia)
		room:notifyMoveCards(false, moves_to, false, _guojia)
		ids:removeOne(self:getSubcards():first())
		room:setPlayerFlag(use.from, "-Fake_Move")
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setCardFlag(card, "-"..self:objectName())
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card, use.from, targets_list))
		room:setPlayerFlag(use.from, "Fake_Move")
		local move = sgs.CardsMoveStruct(ids, nil, use.from, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
		local moves = sgs.CardsMoveList()
		moves:append(move)
		room:notifyMoveCards(true, moves, false, _guojia)
		room:notifyMoveCards(false, moves, false, _guojia)
		room:setPlayerProperty(use.from, self:objectName(), sgs.QVariant(table.concat(sgs.QList2Table(ids), "+")))
	end
}
chuitiVS = sgs.CreateOneCardViewAsSkill{
	name = "chuiti",
	view_filter = function(self, card)
		return not sgs.Self:isJilei(card) and card:hasFlag(self:objectName()) and card:isAvailable(sgs.Self)
	end,
	view_as = function(self, card)
		local skillcard = chuitiCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@chuiti"
	end
}
chuiti = sgs.CreateTriggerSkill{
	name = "chuiti",
	view_as_skill = chuitiVS, 
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime and RIGHT(self, player) then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				room:broadcastSkillInvoke(self:objectName())

				local ids = sgs.IntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						ids:append(card_id)
					end
				end

				if not ids:isEmpty() then
					for _, id in sgs.qlist(ids) do
						room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
					end
					room:setPlayerFlag(player, "Fake_Move")
					local _guojia = sgs.SPlayerList()
					_guojia:append(player)
					local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
					local moves = sgs.CardsMoveList()
					moves:append(move)
					room:notifyMoveCards(true, moves, false, _guojia)
					room:notifyMoveCards(false, moves, false, _guojia)
					room:setPlayerProperty(player, self:objectName(), sgs.QVariant(table.concat(sgs.QList2Table(ids), "+")))
					room:askForUseCard(player, "@chuiti", "@chuiti")
					room:setTag(self:objectName(), sgs.QVariant())
					local move_to = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile, sgs.CardMoveReason())
					local moves_to = sgs.CardsMoveList()
					moves_to:append(move_to)
					room:notifyMoveCards(true, moves_to, false, _guojia)
					room:notifyMoveCards(false, moves_to, false, _guojia)
					room:setPlayerFlag(player, "-Fake_Move")
					local dumm = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in sgs.qlist(ids) do
						local card = sgs.Sanguosha:getCard(id)
						if card:hasFlag(self:objectName()) then
							room:setCardFlag(card, "-"..self:objectName())
							dumm:addSubcard(card:getId())
						end
					end
					room:throwCard(dumm, nil, player)
				end
			end
		end
		return false
	end
}

--fengfangnu:addSkill(zhuangshu)
fengfangnu:addSkill(chuiti)

sgs.LoadTranslationTable{
["fengfangnu"] = "馮方女",
["zhuangshu"] = "妝梳",
[":zhuangshu"] = "一名角色的回合開始時,你可棄置一張手牌,然後根據此牌的類型,將一張場上沒有的「寶梳」置於其寶物區:基本牌,【瓊梳】;錦囊牌,【犀梳】;裝備牌,【金梳】。「寶梳」在離開裝備區後銷毀。",
["@zhuangshu"] = "你可以棄置一張手牌發動“妝梳”",

["chuiti"] = "垂涕",
[":chuiti"] = "每回合限一次,你的一張牌因棄置置入棄牌堆後,若你能使用此牌則你可以使用之。",
["@chuiti"] = "你可以使用“垂涕”的牌",
["~chuiti"] = "選擇一張可以使用的牌->點擊確定",

["qiongshu"] = "瓊梳",
["xishu"] = "犀梳",
["jinshu"] = "金梳",
[":qiongshu"] = "裝備牌·寶物<br /><b>寶物技能</b>：<br />"..
"每回合限一次,你使用【殺】指定唯一目標後,可選擇一名與目標體力值相同或手牌相同的額外目標,且額外目標不能響應此【殺】。",
[":xishu"] = "裝備牌·寶物<br /><b>寶物技能</b>：<br />"..
"判定階段開始時,你可棄置一張牌跳過你的判定階段;棄牌階段開始時,你可以棄置一張牌跳過你的棄牌階段。",
[":jinshu"] = "裝備牌·寶物<br /><b>寶物技能</b>：<br />"..
"鎖定技,出牌階段開始時,你摸牌至手牌上限。",

["qiongshuSkill"] = "瓊梳",
["xishuSkill"] = "犀梳",
["jinshuSkill"] = "金梳",

["qiongshu-invoke"] = "你可以發動“瓊梳”",
["xishu-judge"] = "你可以發動“犀梳”，棄置一張牌跳過你的判定階段",
["xishu-discard"] = "你可以發動“犀梳”，棄置一張牌跳過你的棄牌階段",
}

--十週年程昱
chengyu_po = sgs.General(extension, "chengyu_po", "wei2", "3",true)

shefu_poCard = sgs.CreateSkillCard{
	name = "shefu_po",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, TrueName(card) )) then
				if (card:isKindOf("BasicCard") or card:isNDTrick()) and source:getMark("AG_BANCard"..card:objectName()) == 0 and source:getMark("shefu_po"..TrueName(card)) == 0 then
					table.insert(choices, TrueName(card) )
				end
			end
		end
		
		if next(choices) ~= nil then
			local choice = room:askForChoice(source, "shefu_po", table.concat(choices, "+"))
			
			local msg = sgs.LogMessage()
			msg.type = "$ShefuRecord"
			msg.from = source
			msg.arg = choice
			msg.card_str = sgs.Sanguosha:getCard(self:getSubcards():first()):toString()
			room:sendLog(msg)

			source:addToPile("ambush", self)
			room:addPlayerMark(source,"shefu_po"..choice)
			
		end
	end
}

shefu_poVS = sgs.CreateViewAsSkill{
	name = "shefu_po",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = shefu_poCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@shefu_po")
	end
}
shefu_po = sgs.CreateTriggerSkill{
	name = "shefu_po",
	view_as_skill = shefu_poVS,
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Finish and (not player:isKongcheng()) then
				room:askForUseCard(player, "@@shefu_po", "@shefu_po-prompt")
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and (not use.card:isKindOf("SkillCard")) and (not use.card:isKindOf("EquipCard")) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getMark("shefu_po"..TrueName(use.card)) > 0 then
						if room:askForSkillInvoke(p,"shefu_po_cancel", sgs.QVariant("data:"..TrueName(use.card) )) then
							room:removePlayerMark(p,"shefu_po"..TrueName(use.card))
							room:notifySkillInvoked(p, self:objectName())
							room:broadcastSkillInvoke(self:objectName())

							room:getThread():delay(100)
							local msg = sgs.LogMessage()
							msg.type = "$shefu_po"
							msg.from = use.from
							msg.to:append(p)
							msg.arg = self:objectName()
							msg.card_str = use.card:toString()
							room:sendLog(msg)


							if p:getPile("ambush"):length() > 0 then
								local cardIds = sgs.IntList()
								for _, id in sgs.qlist( p:getPile("ambush") ) do
									cardIds:append(id)
									break
								end
								local move2 = sgs.CardsMoveStruct(cardIds, p, nil, sgs.Player_PlaceSpecial, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
								room:moveCardsAtomic(move2, false)
							end

							local current = room:getCurrent()
							if current:objectName() == use.from:objectName() then

								local msg = sgs.LogMessage()
								msg.type = "$Shefu_poNull"
								msg.from = use.from
								msg.arg = self:objectName()
								room:sendLog(msg)

								for _,sk in sgs.qlist(use.from:getVisibleSkillList()) do
									if use.from:hasSkill( sk:objectName() ) then
										room:addPlayerMark(use.from, "Shefu_po"..sk:objectName() )
										room:addPlayerMark(use.from, "Qingcheng"..sk:objectName() )
									end
								end

							end

							return true
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}



chengyu_po:addSkill(shefu_po)
chengyu_po:addSkill("benyu")

sgs.LoadTranslationTable{
["#chengyu_po"] = "泰山捧日",
["chengyu_po"] = "十週年程昱",
["&chengyu_po"] = "程昱",
["illustrator:chengyu_po"] = "GH",
["shefu_po"] = "設伏",
[":shefu_po"] = "結束階段開始時，你可以將一張手牌扣置於武將牌旁，稱為“伏兵”，並為該牌記錄一種基本牌或錦囊牌的牌名（與其他“伏兵”均不相同）。你的回合外，每當一名角色使用基本牌或錦囊牌時，若此牌的牌名與一張“伏兵”的記錄相同，你可以將此“伏兵”置入棄牌堆：若如此做，此牌無效。若此時是使用者的回合，則其本回合所有技能失效。",
["ambush"] = "伏兵",
["@shefu_po-prompt"] = "你可以發動“設伏”",
["~shefu_po"] = "在對話框中選擇牌名→選擇一張手牌→點擊確定",
["$shefu_po"] = "由於 %to 發動技能 <font color=\"yellow\"><b>設伏</b></font> ，%from 使用的 %card 無效",
["shefu_po_cancel:data"] = "你可以發動“設伏”令【%src】無效<br/> <b>注</b>: 若你無對應牌名的“伏兵”則沒有任何效果",
["benyu"] = "賁育",
[":benyu"] = "每當你受到有來源的傷害後，若傷害來源存活，若你的手牌數：小於X，你可以將手牌補至X（至多為5）張；大於X ，你可以棄置至少X+1張手牌，然後對傷害來源造成1點傷害。（X為傷害來源的手牌數）",
["@benyu-discard"] = "你可以發動“賁育”棄置至少 %arg 張手牌對 %dest 造成1點傷害",
["~benyu"] = "選擇足量的手牌→點擊確定",
["$ShefuRecord"] = "%from 為 %card 記錄牌名【%arg】",

["$Shefu_poNull"] = "%from 的技能由於“<font color=\"yellow\"><b>設伏</b></font>”效果，本回合無效。",
}

sgs.Sanguosha:addSkills(skills)

