module("extensions.mobilelimit", package.seeall)
extension = sgs.Package("mobilelimit")

sgs.LoadTranslationTable{
	["mobilelimit"] =  "手殺界限突破",
}

local skills = sgs.SkillList()

--界朱靈
mobile_zhuling = sgs.General(extension, "mobile_zhuling", "wei2", 4, true)

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

mobile_zhanyiBasicCard = sgs.CreateSkillCard{
	name = "mobile_zhanyiBasic",
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
		local card = sgs.Self:getTag("mobile_zhanyiBasic"):toCard()
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
		local card = sgs.Self:getTag("mobile_zhanyiBasic"):toCard()
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
		local card = sgs.Self:getTag("mobile_zhanyiBasic"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_mobile_zhanyiBasic = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local mobile_zhanyiBasic_list = {}
			table.insert(mobile_zhanyiBasic_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(mobile_zhanyiBasic_list, "normal_slash")
				table.insert(mobile_zhanyiBasic_list, "thunder_slash")
				table.insert(mobile_zhanyiBasic_list, "fire_slash")
			end
			to_mobile_zhanyiBasic = room:askForChoice(player, "mobile_zhanyiBasic_slash", table.concat(mobile_zhanyiBasic_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_mobile_zhanyiBasic == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_mobile_zhanyiBasic == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_mobile_zhanyiBasic
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_mobile_zhanyiBasic")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_mobile_zhanyiBasic
		if user_str == "peach+analeptic" then
			local mobile_zhanyiBasic_list = {}
			table.insert(mobile_zhanyiBasic_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(mobile_zhanyiBasic_list, "analeptic")
			end
			to_mobile_zhanyiBasic = room:askForChoice(user, "mobile_zhanyiBasic_saveself", table.concat(mobile_zhanyiBasic_list, "+"))
		elseif user_str == "slash" then
			local mobile_zhanyiBasic_list = {}
			table.insert(mobile_zhanyiBasic_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(mobile_zhanyiBasic_list, "normal_slash")
				table.insert(mobile_zhanyiBasic_list, "thunder_slash")
				table.insert(mobile_zhanyiBasic_list, "fire_slash")
			end
			to_mobile_zhanyiBasic = room:askForChoice(user, "mobile_zhanyiBasic_slash", table.concat(mobile_zhanyiBasic_list, "+"))
		else
			to_mobile_zhanyiBasic = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_mobile_zhanyiBasic == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_mobile_zhanyiBasic == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_mobile_zhanyiBasic
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_mobile_zhanyiBasic")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end
}
mobile_zhanyiBasic = sgs.CreateViewAsSkill{
	name = "mobile_zhanyiBasic&",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isKindOf("BasicCard")
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local skillcard = mobile_zhanyiBasicCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE 
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		end
		local c = sgs.Self:getTag("mobile_zhanyiBasic"):toCard()
		if c then
			skillcard:setUserString(c:objectName())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		else
			return nil
		end
	end, 
	enabled_at_play = function(self, player)
		if sgs.Self:getMark("mobile_zhanyi_Basic_play") == 0 then return false end
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
		if sgs.Self:getMark("mobile_zhanyi_Basic_play") == 0 then return false end
        if string.startsWith(pattern, ".") or string.startsWith(pattern, "@") then return false end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
        return pattern ~= "nullification"
	end
}
mobile_zhanyiBasic:setGuhuoDialog("l")

mobile_zhanyiCard = sgs.CreateSkillCard{
	name = "mobile_zhanyiCard",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source,1)
		room:broadcastSkillInvoke("mobile_zhanyi")
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:isKindOf("BasicCard") then
			room:setPlayerMark(source,"mobile_zhanyi_Basic_play",1)
		elseif card:isKindOf("TrickCard") then
			source:drawCards(3)
			room:setPlayerMark(source,"mobile_zhanyi_Trick_play",1)
		elseif card:isKindOf("EquipCard") then
			room:setPlayerMark(source,"mobile_zhanyi_Equip_play",1)
		end
	end
}


mobile_zhanyiVS = sgs.CreateViewAsSkill{
	name = "mobile_zhanyi",
	n =  1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = mobile_zhanyiCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_zhanyiCard")
	end, 
}

mobile_zhanyi = sgs.CreateTriggerSkill{
	name = "mobile_zhanyi",
	view_as_skill = mobile_zhanyiVS,
	events = {sgs.EventAcquireSkill,sgs.GameStart,sgs.EventPhaseEnd,sgs.PreHpRecover,sgs.ConfirmDamage,sgs.TargetSpecified,sgs.PreCardUse},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event == sgs.GameStart then
			if player:hasSkill("mobile_zhanyi") then
				room:attachSkillToPlayer(player,"mobile_zhanyiBasic")
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				room:setPlayerMark(player,"mobile_zhanyi_Basic_play",0)
				room:setPlayerMark(player,"mobile_zhanyi_Basic_Use_play",0)
				room:setPlayerMark(player,"mobile_zhanyi_Trick_play",0)
				room:setPlayerMark(player,"mobile_zhanyi_Equip_play",0)
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:isKindOf("BasicCard") and player:getMark("mobile_zhanyi_Basic_play") > 0 and player:getMark("mobile_zhanyi_Basic_Use_play") == 0 then
				room:setPlayerMark(player,"mobile_zhanyi_Basic_Use_play",1)
				local log = sgs.LogMessage()
				log.type = "$new_longhunREC"
				log.from = player
				room:sendLog(log)
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("BasicCard") and player:getMark("mobile_zhanyi_Basic_play") > 0 and player:getMark("mobile_zhanyi_Basic_Use_play") == 0 then
				room:setPlayerMark(player,"mobile_zhanyi_Basic_Use_play",1)
				local log = sgs.LogMessage()
				log.type = "$new_longhunDMG"
				log.from = player
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getMark("mobile_zhanyi_Equip_play") > 0 then
				for _, p in sgs.qlist(use.to) do
					local cards = room:askForExchange(p, self:objectName(), math.min(p:getHandcardNum(), 2), 2, false, "mobile_zhanyi_slash")
					if cards then
						local ids = sgs.IntList()
						for _,id in sgs.qlist(cards:getSubcards()) do
							ids:append(id)					
						end
						room:fillAG(ids)
						local ask_id = room:askForAG(player, ids, false, self:objectName())
						room:obtainCard(player, ask_id, true)
						room:clearAG()
					end
				end
			end
		elseif event == sgs.PreCardUse then
			local use = data:toCardUse()
			if use.card:isNDTrick() and player:getMark("mobile_zhanyi_Trick_play") > 0 then
				use.card:toTrick():setCancelable(true)
			end
		end
		return false
	end
}

mobile_zhuling:addSkill(mobile_zhanyi)

if not sgs.Sanguosha:getSkill("mobile_zhanyiBasic") then skills:append(mobile_zhanyiBasic) end

sgs.LoadTranslationTable{
	["#mobile_zhuling"] = "良將之亞",
	["mobile_zhuling"] = "朱靈",
	["&mobile_zhuling"] = "朱靈",
	["mobile_zhanyi"] = "戰意",
	["mobile_zhanyiBasic"] = "戰意",
	[":mobile_zhanyi"] = "<font color = 'green'><b>出牌階段限一次</b></font>，你可以棄置一張牌並失去1點體力，若此牌為：\
	●基本牌，此階段你可以將一張基本牌當任意一張基本牌使用或打出，且你使用的第一張基本牌的傷害或回復值+1；\
	●錦囊牌，你摸三張牌此階段使用錦囊牌不能被無懈可擊響應\
	●裝備牌，你於此階段使用【殺】指定一個目標後，你令其棄置兩張牌，然後你獲得其中一張。 ",
	["@zhanyiequip_discard"] = "<font color=\"yellow\">戰意</font> 請棄置兩張牌。" ,
	["mobile_zhanyi_slash"] = "受到“戰意”影響，你須棄置兩張牌",
}

--手殺界孫堅
mobile_sunjian = sgs.General(extension, "mobile_sunjian", "wu2", 4, true,true)

mobile_poluCard = sgs.CreateSkillCard{
	name = "mobile_poluCard",
	filter = function(self, targets, to_select, erzhang)
		return #targets < 99
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source,"@mobile_polu")
		local n = source:getMark("@mobile_polu")
		for _, p in ipairs(targets) do
			p:drawCards(n)	
		end	
	end
}
mobile_poluVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_polu",
	response_pattern = "@@mobile_polu",
	view_as = function()
		return mobile_poluCard:clone()
	end
}

mobile_polu = sgs.CreateTriggerSkill{
	name = "mobile_polu",
	frequency = sgs.Skill_Frequency,
	events = {sgs.Death},
	view_as_skill = mobile_poluVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if death.damage and death.damage.from then
				if death.damage.from:objectName() == player:objectName() then
					room:askForUseCard(player, "@@mobile_polu", "@mobile_polu-card")
				end
			end
			if death.who:objectName() == player:objectName() then
				room:askForUseCard(player, "@@mobile_polu", "@mobile_polu-card")
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end
}

mobile_sunjian:addSkill("yinghun")
mobile_sunjian:addSkill(mobile_polu)

sgs.LoadTranslationTable{
	["#mobile_sunjian"] = "武烈帝",
	["mobile_sunjian"] = "手殺界孫堅",
	["&mobile_sunjian"] = "孫堅",
	["illustrator:sunjian"] = "LiuHeng",
	["yinghun"] = "英魂",
	[":yinghun"] = "準備階段開始時，若你已受傷，你可以選擇一名其他角色並選擇一項：令其摸一張牌，然後棄置X張牌，或令其摸X張牌，然後棄置一張牌。（X為你已損失的體力值）",
	["mobile_polu"] = "破虜",
	[":mobile_polu"] = "每當你殺死一名其他角色或死亡後，你可以令任意名角色各摸X張牌(X為此技能發動次數)",
	["@mobile_polu-card"] = "你可以令任意名角色摸一張牌",
	["~mobile_polu"] = "選擇任意名角色 -> 點擊確定",
}

--界曹丕
mobile_caopi = sgs.General(extension, "mobile_caopi", "wei2", 3, true,true)

mobile_xingshang = sgs.CreateTriggerSkill{
	name = "mobile_xingshang",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() or player:isNude() then return false end
		if player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, "mobile_xingshang", "mobile_xingshang1+mobile_xingshang2")
			if splayer:hasSkill("juece") then
				room:broadcastSkillInvoke(self:objectName(),3)
			elseif splayer:isMale() then
				room:broadcastSkillInvoke(self:objectName(),1)
			else
				room:broadcastSkillInvoke(self:objectName(),2)
			end
			room:doAnimate(1, player:objectName(), splayer:objectName())
			if choice == "mobile_xingshang1" then
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
			elseif choice == "mobile_xingshang2" then
				room:recover(player, sgs.RecoverStruct(player))
			end
		end
		return false
	end
}

mobile_fangzhu = sgs.CreateMasochismSkill{
	name = "mobile_fangzhu",
	on_damaged = function(self, player)
		local room = player:getRoom()
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fangzhu-invoke", player:getMark("JilveEvent") ~= 35, true)
		if to then
			room:setPlayerFlag(player,"mobile_fangzhu_from")
			if to:hasSkill("juece") then
				room:broadcastSkillInvoke(self:objectName(),3)
			else
				room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
			end
			room:doAnimate(1, player:objectName(), to:objectName())
			local choice = room:askForChoice(to, "mobile_fangzhu", "mobile_fangzhu1+mobile_fangzhu2")
			if choice == "mobile_fangzhu1" then
				to:drawCards(player:getLostHp(), self:objectName())
				to:turnOver()
			elseif choice == "mobile_fangzhu2" then
				local n = player:getLostHp()
				room:askForDiscard(to,"mobile_fangzhu",n,n, false, true)
				room:loseHp(to)
			end
			room:setPlayerFlag(player,"-mobile_fangzhu_from")
		end
	end
}

mobile_caopi:addSkill(mobile_xingshang)
mobile_caopi:addSkill(mobile_fangzhu)
mobile_caopi:addSkill("songwei")

sgs.LoadTranslationTable{
	["#mobile_caopi"] = "霸業的繼承者",
	["&mobile_caopi"] = "曹丕",
	["mobile_caopi"] = "手殺界曹丕",
	["illustrator:caop_poi"] = "SoniaTang",
	["mobile_xingshang"] = "行殤",
	[":mobile_xingshang"] = "每當一名其他角色死亡時，你可以選擇一項1.獲得該角色的所有牌。2.回復一點體力",
	["mobile_xingshang1"] = "獲得該角色的所有牌",
	["mobile_xingshang2"] = "回復一點體力",
	["mobile_fangzhu"] = "放逐",
	[":mobile_fangzhu"] = "每當你受到傷害後，你可以令一名其他角色選擇一項：1.摸X張牌，然後將其武將牌翻面。2.棄置X張牌，然後失去一點體力（X為你已損失的體力值）",
	["fangzhu-invoke"] = "你可以發動“放逐”<br/> <b>操作提示</b>: 選擇一名其他角色→點擊確定<br/>",
	["mobile_fangzhu1"] = "摸X張牌，然後將其武將牌翻面",
	["mobile_fangzhu2"] = "棄置X張牌，然後失去一點體力",
}

--界鄧艾
mobile_dengai = sgs.General(extension, "mobile_dengai", "wei2", 4, true,true)

mobile_tuntian = sgs.CreateTriggerSkill{
	name = "mobile_tuntian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.FinishJudge, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
				if not player:askForSkillInvoke("mobile_tuntian", data) then return end
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				if judge:isGood() then
					player:addToPile("field", judge.card:getEffectiveId())
				else
					player:obtainCard(judge.card)
				end
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				player:removePileByName("field")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_NotActive
	end
}

mobile_tuntianDistance = sgs.CreateDistanceSkill{
	name = "#mobile_tuntianDistance",
	correct_func = function(self, from, to)
		if from:hasSkill("mobile_tuntian") then
			return - from:getPile("field"):length()
		else
			return 0
		end
	end  
}

mobile_dengai:addSkill(mobile_tuntian)
mobile_dengai:addSkill(mobile_tuntianDistance)
mobile_dengai:addSkill("zaoxian")

sgs.LoadTranslationTable{
	["#mobile_dengai"] = "矯然的壯士",
	["mobile_dengai"] = "手殺界鄧艾",
	["&mobile_dengai"] = "鄧艾",
	["mobile_tuntian"] = "屯田",
	[":mobile_tuntian"] = "你的回合外，每當你失去一次牌後，你可以進行判定：若為紅桃，你獲得此判定牌；不為紅桃，將判定牌置於武將牌上，稱為“田”。你與其他角色的距離-X。（X為“田”的數量）",
	["#mobile_tuntianDistance"] = "屯田",
}

--界姜維
mobile_jiangwei = sgs.General(extension, "mobile_jiangwei", "shu2", 4, true,true)

--挑釁
mobile_tiaoxinCard = sgs.CreateSkillCard{
	name = "mobile_tiaoxinCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to,effect.from, "@tiaoxin-slash:" .. effect.from:objectName())
		end
		if (not use_slash) and effect.from:canDiscard(effect.to, "he") then
			room:throwCard(room:askForCardChosen(effect.from,effect.to, "he", "mobile_tiaoxin", false, sgs.Card_MethodDiscard), effect.to, effect.from)
		end
	end
}
mobile_tiaoxin = sgs.CreateViewAsSkill{
	name = "mobile_tiaoxin",
	n = 0 ,
	view_as = function()
		return mobile_tiaoxinCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_tiaoxinCard")
	end
}

mobile_jiangwei:addSkill(mobile_tiaoxin)
mobile_jiangwei:addSkill("zhiji")

sgs.LoadTranslationTable{
	["#mobile_jiangwei"] = "龍的衣缽",
	["mobile_jiangwei"] = "手殺界姜維",
	["&mobile_jiangwei"] = "姜維",
	["mobile_tiaoxin"] = "挑釁",
	[":mobile_tiaoxin"] = "階段技。你可以令的一名角色對你使用一張【殺】(有距離限制)，否則你棄置其一張牌。",
	["@tiaoxin-slash"] = "%src 對你發動“挑釁”，請對其使用一張【殺】",
	["mobile_zhiji"] = "志繼",
	[":mobile_zhiji"] = "覺醒技。準備階段開始時，若你沒有手牌，你失去1點體力上限，然後回復1點體力或摸兩張牌，並獲得“觀星”。",
	["zhiji:draw"] = "摸兩張牌",
	["zhiji:recover"] = "回復1點體力",
	["$ZhijiAnimate"] = "image=image/animate/zhiji.png",
}

--界蔡文姬
mobile_caiwenji = sgs.General(extension, "mobile_caiwenji", "qun2", 3, false,true)
--悲歌
mobile_beige = sgs.CreateTriggerSkill{
	name = "mobile_beige",
	events = {sgs.Damaged, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card == nil or not damage.card:isKindOf("Slash") or damage.to:isDead() then
				return false
			end
			for _, caiwenji in sgs.qlist(room:getAllPlayers()) do
				if not caiwenji or caiwenji:isDead() or not caiwenji:hasSkill(self:objectName()) then continue end
				if caiwenji:canDiscard(caiwenji, "he") and room:askForCard(caiwenji, "..", "@mobile_beige", data, self:objectName()) then
					room:notifySkillInvoked(caiwenji, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.play_animation = false
					judge.who = player
					judge.reason = self:objectName()
					room:judge(judge)
					local suit = judge.card:getSuit()
					if suit == sgs.Card_Heart then
						room:recover(player, sgs.RecoverStruct(caiwenji, nil, damage.damage))
					elseif suit == sgs.Card_Diamond then
						player:drawCards(3, self:objectName())
					elseif suit == sgs.Card_Club then
						if damage.from and damage.from:isAlive() then
							room:askForDiscard(damage.from, self:objectName(), 2, 2, false, true)
						end
					elseif suit == sgs.Card_Spade then
						if damage.from and damage.from:isAlive() then
							damage.from:turnOver()
						end
					end
				end
			end
		else
			local judge = data:toJudge()
			if judge.reason ~= self:objectName() then return false end
			judge.pattern = tostring(judge.card:getEffectiveId())
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

mobile_caiwenji:addSkill(mobile_beige)
mobile_caiwenji:addSkill("duanchang")

sgs.LoadTranslationTable{
	["#mobile_caiwenji"] = "異鄉的孤女",
	["mobile_caiwenji"] = "手殺界蔡文姬",
	["&mobile_caiwenji"] = "蔡文姬",
	["illustrator:mobile_caiwenji"] = "SoniaTang",
	["mobile_beige"] = "悲歌",
	[":mobile_beige"] = "每當一名角色受到一次【殺】的傷害後，你可以棄置一張牌令該角色進行判定：若結果為紅桃，該角色回復1點體力；方塊，該角色摸三張牌；黑桃，傷害來源將其武將牌翻面；梅花，傷害來源棄置兩張牌。",
	["@mobile_beige"] = "你可以棄置一張牌發動“悲歌”",
}

--袁紹
mobile_yuanshao = sgs.General(extension, "mobile_yuanshao$", "qun2",4,true,true)

mobile_luanjiVS = sgs.CreateViewAsSkill{
	name = "mobile_luanji",
	n = 2,
	view_filter = function(self, selected, to_select)
		return  #selected < 2 and not to_select:isEquipped() and sgs.Self:getMark(self:objectName()..to_select:getSuitString().."-Clear") == 0
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_SuitToBeDecided, 0)
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		card:setSkillName(self:objectName())
		return card
	end
}
mobile_luanji = sgs.CreateTriggerSkill{
	name = "mobile_luanji", 
	view_as_skill = mobile_luanjiVS, 
	events = {sgs.CardUsed, sgs.CardEffected, sgs.CardResponded,sgs.CardFinished,sgs.Damage}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local s = room:findPlayerBySkillName(self:objectName())
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == "mobile_luanji" then
				for _,id in sgs.qlist(use.card:getSubcards()) do
					room:addPlayerMark(player, self:objectName()..sgs.Sanguosha:getCard(id):getSuitString().."-Clear")
				end
				room:addPlayerMark(player,"luanjiDamage-Clear")
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:getSkillName() == "mobile_luanji" then
				room:addPlayerMark(player, "luanji-Clear")
			end
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			if response.m_card:isKindOf("Jink") and response.m_isRetrial == false and response.m_isUse == false and player:getMark("luanji-Clear") > 0 then
				local _data = sgs.QVariant()
				_data:setValue(player)
				if s:askForSkillInvoke(self:objectName(), _data) then
					player:drawCards(1, self:objectName())
				end
				room:removePlayerMark(player, "luanji-Clear")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "mobile_luanji" then
				if player:getMark("luanjiDamage-Clear") > 0 then
					player:drawCards(use.to:length())
					room:removePlayerMark(player, "luanjiDamage-Clear")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to:getMark("luanji-Clear") > 0 then
				room:removePlayerMark(damage.from, "luanjiDamage-Clear")
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}



mobile_yuanshao:addSkill(mobile_luanji)
mobile_yuanshao:addSkill("xueyi")

sgs.LoadTranslationTable{
["mobile_yuanshao"] = "手殺界袁紹",
["&mobile_yuanshao"] = "袁紹",
["#mobile_yuanshao"] = "高貴的名門",
["mobile_luanji"] = "亂擊",
[":mobile_luanji"] = "你可以將兩張於此回合內未以此法轉化過的花色的手牌當【萬箭齊發】使用；當已受傷的角色響應此牌時，令其摸一張牌。",
["$mobile_luanji1"] = "放箭！放箭！",
["$mobile_luanji2"] = "箭支充足，儘管取用~",
["$xueyi1"] = "世受皇恩，威震海內！",
["$xueyi2"] = "四世三公，名冠天下！",
["~mobile_yuanshao"] = "我袁家~怎麼會輸？",
}


--劉禪
mobile_liushan = sgs.General(extension, "mobile_liushan$", "shu2", "3", true,true)

mobile_fangquanCard = sgs.CreateSkillCard{
	name = "mobile_fangquan",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local _player = effect.to
		local p = _player
		local playerdata = sgs.QVariant()
		playerdata:setValue(p)
		room:setTag("mobile_fangquanTarget", playerdata)		
	end
}
mobile_fangquanVS = sgs.CreateViewAsSkill{
	name = "mobile_fangquan",
	response_pattern = "@@mobile_fangquan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = mobile_fangquanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function()
		return false
	end,
}

mobile_fangquan = sgs.CreateTriggerSkill{
	name = "mobile_fangquan" ,
	view_as_skill = mobile_fangquanVS,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			local invoked = false
			if player:isSkipped(sgs.Player_Play) then return false end
			if room:askForSkillInvoke(player,self:objectName(),data) then
				player:setFlags("mobile_fangquan")
				player:skip(sgs.Player_Play)
			end
		elseif change.to == sgs.Player_NotActive then
			if player:hasFlag("mobile_fangquan") then
				if player:canDiscard(player, "h") then
					room:askForUseCard(player, "@@mobile_fangquan", "@mobile_fangquan-give", -1, sgs.Card_MethodDiscard)
				end
			end
		end
		return false
	end
}
mobile_fangquanGive = sgs.CreateTriggerSkill{
	name = "mobile_fangquanGive" ,
	events = {sgs.EventPhaseStart} ,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if room:getTag("mobile_fangquanTarget") and player:getPhase() == sgs.Player_NotActive then
			local target = room:getTag("mobile_fangquanTarget"):toPlayer()
			room:removeTag("mobile_fangquanTarget")
			if target and target:isAlive() then

				local msg = sgs.LogMessage()
				msg.type = "#Fangquan"
				msg.from = player
				msg.to:append(target)
				room:sendLog(msg)

				room:setTag("ExtraTurn",sgs.QVariant(true))
				target:gainAnExtraTurn()
				room:setTag("ExtraTurn",sgs.QVariant(false))
			end
		end
		return false
	end ,
	priority = 1
}

mobile_fangquanMax = sgs.CreateMaxCardsSkill{
	name = "#mobile_fangquanMax", 
	frequency = sgs.Skill_Compulsory ,
	fixed_func = function(self, target)
		if target:hasFlag("mobile_fangquan") then
			return target:getMaxHp()
		end
		return -1
	end
}

mobile_liushan:addSkill("xiangle")
mobile_liushan:addSkill(mobile_fangquan)
mobile_liushan:addSkill(mobile_fangquanMax)
mobile_liushan:addSkill("ruoyu")

if not sgs.Sanguosha:getSkill("mobile_fangquanGive") then skills:append(mobile_fangquanGive) end

sgs.LoadTranslationTable{
	["#mobile_liushan"] = "無為的真命主",
	["&mobile_liushan"] = "劉禪",
	["mobile_liushan"] = "手殺界劉禪",
	["illustrator:mobile_liushan"] = "LiuHeng",

	["mobile_fangquan"] = "放權",
	[":mobile_fangquan"] = "你可以跳過你的出牌階段，並令你本回合的手牌上限等於體力上限。若以此法跳過出牌階段，結束階段開始時你可以棄置一張手牌並選擇一名其他角色：若如此做，該角色進行一個額外的回合。",
	["@mobile_fangquan-give"] = "你可以棄置一張手牌令一名其他角色進行一個額外的回合",
	["~mobile_fangquan"] = "選擇一張手牌→選擇一名其他角色→點擊確定",
	["ruoyu"] = "若愚",

	["#Fangquan"] = "%to 將進行一個額外的回合",
}

--界孫策
mobile_sunce = sgs.General(extension, "mobile_sunce$", "wu2", "4", true,true)

mobile_hunzi = sgs.CreateTriggerSkill{
	name = "mobile_hunzi" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke("mobile_hunzi")
		room:doSuperLightbox("mobile_sunce","mobile_hunzi")
		if player:getHp() <= 2 then
			local msg = sgs.LogMessage()
			msg.type = "#MobileHunziWake"
			msg.from = player
			msg.to:append(player)
			msg.arg = player:getHp()
			msg.arg2 = self:objectName()
			room:sendLog(msg)
		end
		room:addPlayerMark(player, "mobile_hunzi")
		room:addPlayerMark(player, "hunzi")
		if room:changeMaxHpForAwakenSkill(player) then
			room:handleAcquireDetachSkills(player, "yingzi|yinghun")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("mobile_hunzi") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getHp() <= 2 or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}


mobile_sunce:addSkill("jiang")
mobile_sunce:addSkill(mobile_hunzi)
mobile_sunce:addSkill("zhiba")

sgs.LoadTranslationTable{
	["#mobile_sunce"] = "江東的小霸王",
	["mobile_sunce"] = "手殺界孫策",
	["&mobile_sunce"] = "孫策",
	["mobile_hunzi"] = "魂姿",
	[":mobile_hunzi"] = "覺醒技。準備階段開始時，若你的體力值不大於2，你失去1點體力上限，然後獲得“英姿”和“英魂”。",
	["$HunziAnimate"] = "image=image/animate/hunzi.png",
	["#MobileHunziWake"] = "%from 的體力值為 <font color=\"yellow\"><b> %arg </b></font>，觸發“%arg2”覺醒",
}

--界張昭＆張纮
mobile_erzhang = sgs.General(extension, "mobile_erzhang", "wu2", "3", true,true)

mobile_zhijianCard = sgs.CreateSkillCard{
	name = "mobile_zhijian",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, erzhang)
		if #targets ~= 0 or to_select:objectName() == erzhang:objectName() then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	on_effect = function(self, effect)
		local erzhang = effect.from
		local msg = sgs.LogMessage()
		msg.type = "$ZhijianEquip"
		msg.from = effect.to
		msg.card = self:objectName()
		room:sendLog(msg)

		erzhang:getRoom():moveCardTo(self, erzhang, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, erzhang:objectName(), "zhijian", ""))
		erzhang:drawCards(1, "zhijian")
	end
}
mobile_zhijianVS = sgs.CreateOneCardViewAsSkill{
	name = "mobile_zhijian",	
	filter_pattern = "EquipCard|.|.|hand",
	view_as = function(self, card)
		local zhijian_card = mobile_zhijianCard:clone()
		zhijian_card:addSubcard(card)
		zhijian_card:setSkillName(self:objectName())
		return zhijian_card
	end
}

mobile_zhijian = sgs.CreateTriggerSkill{
	name = "mobile_zhijian",
	frequency = sgs.Skill_Frequent,
	view_as_skill = mobile_zhijianVS,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("EquipCard") and player:getPhase() == sgs.Player_Play then
				room:sendCompulsoryTriggerLog(player, "mobile_zhijian")
				player:drawCards(1)
			end
		end
	end,
}

mobile_erzhang:addSkill(mobile_zhijian)
mobile_erzhang:addSkill("guzheng")

sgs.LoadTranslationTable{
["#mobile_erzhang"] = "經天緯地",
["mobile_erzhang"] = "界張昭＆張纮",
["&mobile_erzhang"] = "張昭張纮",
["illustrator:mobile_erzhang"] = "廢柴男",
["mobile_zhijian"] = "直諫",
[":mobile_zhijian"] = "出牌階段，你可以將你手牌中的一張裝備牌置於一名其他角色裝備區內：若如此做，你摸一張牌；當你於出牌階段使用一張牌時，你摸一張牌",
["~guzheng"] = "選擇一張牌 -> 點擊確定" ,
["$ZhijianEquip"] = "%from 被裝備了 %card",
}

--界典韋(手殺)
mobile_dianwei = sgs.General(extension, "mobile_dianwei", "wei2", "4", true,true)

mobile_qiangxiCard = sgs.CreateSkillCard{
	name = "mobile_qiangxiCard", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() or to_select:getMark("mobile_qiangxi-Clear") > 0 then return false end--根据描述应该可以选择自己才对
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		return sgs.Self:inMyAttackRange(to_select, rangefix);
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then 
			room:loseHp(effect.from)
		end
		room:setPlayerMark(effect.to,"mobile_qiangxi-Clear",1)
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
	end
}
mobile_qiangxi = sgs.CreateViewAsSkill{
	name = "mobile_qiangxi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("Weapon") and not sgs.Self:isJilei(to_select)
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return mobile_qiangxiCard:clone()
		elseif #cards == 1 then
			local card = mobile_qiangxiCard:clone()
			card:addSubcard(cards[1])
			return card
		else 
			return nil
		end
	end,
}

mobile_dianwei:addSkill(mobile_qiangxi)

sgs.LoadTranslationTable{
["#mobile_dianwei"] = "古之惡來",
["&mobile_dianwei"] = "典韋",
["mobile_dianwei"] = "手殺界典韋",
["illustrator:mobile_dianwei"] = "小冷",
["mobile_qiangxi"] = "強襲",
[":mobile_qiangxi"] = "出牌階段，你可以失去1點體力或棄置一張武器牌，並選擇攻擊範圍內本回合未選擇過的一名角色：若如此做，你對該角色造成1點傷害。",
}

--徐盛
mobile_xusheng = sgs.General(extension, "mobile_xusheng", "wu2", "4", true)
--破軍
mobile_pojun = sgs.CreateTriggerSkill{
	name = "mobile_pojun",
	events = {sgs.TargetSpecified,sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, to in sgs.qlist(use.to) do
				local _data = sgs.QVariant()
				_data:setValue(to)
				if player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:setPlayerFlag(to, "Fake_Move")
						local x = to:getHp()
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						local card_ids = sgs.IntList()
						local original_places = sgs.IntList()
						for i = 0, x - 1 do
							if not player:canDiscard(to, "he") then break end
							local to_throw = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							card_ids:append(to_throw)
							original_places:append(room:getCardPlace(card_ids:at(i)))
							room:throwCard(sgs.Sanguosha:getCard(to_throw), to, player)
							dummy:addSubcard(card_ids:at(i))
							room:getThread():delay()
						end
						to:addToPile("mobile_pojun", dummy, false)
						room:setPlayerFlag(to, "-Fake_Move")
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") then
					if (damage.to:getHandcardNum() <= damage.from:getHandcardNum()) and ((damage.to:getEquips():length()) <= (damage.from:getEquips():length())) then
						damage.damage = damage.damage + 1
						local msg = sgs.LogMessage()
							msg.type = "#Pojun"
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
		return false
	end
}

mobile_xusheng:addSkill(mobile_pojun)

sgs.LoadTranslationTable{
	["#mobile_xusheng"] = "江東的鐵壁",
	["mobile_xusheng"] = "界徐盛",
	["&mobile_xusheng"] = "徐盛",
	["designer:mobile_xusheng"] = "阿江",
	["illustrator:mobile_xusheng"] = "天空之城",
	["mobile_pojun"] = "破軍",
	[":mobile_pojun"] = "當你使用【殺】指定目標後，你可以將其至多X張牌移出遊戲外（X為其體力值），若如此做，當前回合結束時，其獲得這些牌。"..
	"你使用【殺】對手牌數與裝備數均不大於你的角色造成傷害時，此傷害+1",
	["#Pojun"] = "%from 的技能 “<font color=\"yellow\"><b>破軍</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--徐盛
xusheng_po = sgs.General(extension, "xusheng_po", "wu2", "4", true)
--破軍
pojun_po = sgs.CreateTriggerSkill{
	name = "pojun_po",
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, to in sgs.qlist(use.to) do
				local _data = sgs.QVariant()
				_data:setValue(to)
				if player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:setPlayerFlag(to, "Fake_Move")
						local x = to:getHp()
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						local card_ids = sgs.IntList()
						local original_places = sgs.IntList()
						for i = 0, x - 1 do
							if not player:canDiscard(to, "he") then break end
							local to_throw = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							card_ids:append(to_throw)
							original_places:append(room:getCardPlace(card_ids:at(i)))
							room:throwCard(sgs.Sanguosha:getCard(to_throw), to, player)
							room:getThread():delay()
							
							if sgs.Sanguosha:getCard(to_throw):isKindOf("TrickCard") and not player:hasFlag("pojun_po_Trick") then
								room:setPlayerFlag(player, "pojun_po_Trick")
							end
							if sgs.Sanguosha:getCard(to_throw):isKindOf("EquipCard") and not player:hasFlag("pojun_po_Equip") then
								room:setPlayerFlag(player, "pojun_po_Equip")
							end
						end

						if player:hasFlag("pojun_po_Equip") and card_ids:length() > 0 then
							room:fillAG(card_ids)
							--room:getThread():delay()

							local id = room:askForAG(player, card_ids, false, "pojun_po")
							room:throwCard(id,player,player)

							card_ids:removeOne(id)
							room:clearAG()
							room:setPlayerFlag(player, "-pojun_po_Equip")
						end

						if player:hasFlag("pojun_po_Trick") then
							player:drawCards(1)
							room:setPlayerFlag(player, "-pojun_po_Trick")
						end
						if card_ids:length() > 0 then
							for i = 0, card_ids:length() - 1 do
								dummy:addSubcard(card_ids:at(i))
							end
						end

						to:addToPile("pojun_po", dummy, false)
						room:setPlayerFlag(to, "-Fake_Move")
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}

pojun_poStart = sgs.CreateTriggerSkill{
	name = "pojun_poStart",
	global = true,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
        	if player:getPhase() == sgs.Player_NotActive then
        		for _, p in sgs.qlist(room:getAlivePlayers()) do
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _,cd in sgs.qlist(p:getPile("mobile_pojun")) do
						dummy:addSubcard(cd)
					end
					room:obtainCard(p, dummy)

					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _,cd in sgs.qlist(p:getPile("pojun_po")) do
						dummy:addSubcard(cd)
					end
					room:obtainCard(p, dummy)
				end
			end
		end
		return false
	end
}

xusheng_po:addSkill(pojun_po)


if not sgs.Sanguosha:getSkill("pojun_poStart") then skills:append(pojun_poStart) end 

sgs.LoadTranslationTable{
	["#xusheng_po"] = "江東的鐵壁",
	["xusheng_po"] = "界徐盛--二版",
	["&xusheng_po"] = "徐盛",
	["designer:xusheng_po"] = "阿江",
	["illustrator:xusheng_po"] = "天空之城",
	["pojun_po"] = "破軍",
	[":pojun_po"] = "當你使用【殺】指定目標後，你可以將其至多X張牌移出遊戲外（X為其體力值），若如此做，當前回合結束時，其獲得這些牌。"..
	"若其中有裝備牌，你棄置其中一張牌；若其中有錦囊牌，你摸一張牌",
}

--步練師
mobile_bulianshi = sgs.General(extension, "mobile_bulianshi", "wu2", "3", false,true)

mobile_anxuCard = sgs.CreateSkillCard{
	name = "mobile_anxu",
	filter = function(self, targets, to_select, player)
		if to_select:objectName() == player:objectName() then return false end
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			return (not to_select:isNude())
		else
			return false
		end
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
--[[
	about_to_use = function(self, room, cardUse)
		local huangyueying = cardUse.from

		local l = sgs.LogMessage()
		l.from = huangyueying
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)

		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		thread:trigger(sgs.PreCardUsed, room, huangyueying, data)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, huangyueying:objectName(), 
			"", "mobile_anxu", "")
		room:moveCardTo(self, huangyueying, nil, sgs.Player_DiscardPile, reason, true)
		thread:trigger(sgs.CardUsed, room, huangyueying, data)
		thread:trigger(sgs.CardFinished, room, huangyueying, data)
	end,
	]]--

	on_use = function(self, room, source, targets)
		local from, to
		from = targets[1]
		to = targets[2]
		local id = room:askForCardChosen(from, to, "he", "mobile_anxu")

		local cd = sgs.Sanguosha:getCard(id)

		if not cd:isEquipped() then
			source:drawCards(1, "mobile_anxu")
		end

		from:obtainCard(cd)

	end
}
mobile_anxuVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_anxu",
	view_as = function() 
		return mobile_anxuCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_anxu")
	end,
}

mobile_anxu = sgs.CreateTriggerSkill{
	name = "mobile_anxu",
	view_as_skill = mobile_anxuVS,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == self:objectName() then

				local who
				if use.to:first():getHandcardNum() > use.to:last():getHandcardNum() then
					who = use.to:last()
				elseif use.to:first():getHandcardNum() < use.to:last():getHandcardNum() then
					who = use.to:first()
				end

				if who then
					local _data = sgs.QVariant()
					_data:setValue(who)
					if room:askForSkillInvoke(player, "mobile_anxu", _data) then
						who:drawCards(1)
					end
				end
			end
		end
		return false
	end
}

mobile_bulianshi:addSkill(mobile_anxu)
mobile_bulianshi:addSkill("zhuiyi")

sgs.LoadTranslationTable{
["#mobile_bulianshi"] = "無冕之后",
["mobile_bulianshi"] = "手殺界步練師",
["&mobile_bulianshi"] = "步練師",
["designer:mobile_bulianshi"] = "Anais",
["illustrator:mobile_bulianshi"] = "紫喬",
["mobile_anxu"] = "安卹",
[":mobile_anxu"] = "階段技。妳可以選擇兩名其他角色：令先選擇的角色獲得另一名角色的一張牌。若此牌不為裝備區內的牌，妳摸一張牌。其獲得牌後妳可以令手牌數較少的角色摸一張牌。",
["zhuiyi"] = "追憶",
[":zhuiyi"] = "妳死亡時，妳可以令一名其他角色（除殺死妳的角色）摸三張牌並回復1點體力。",
["zhuiyi-invoke"] = "妳可以發動“追憶”<br/> <b>操作提示</b>: 選擇一名其他角色→點擊確定<br/>",
["zhuiyi-invokex"] = "妳可以發動“追憶”<br/> <b>操作提示</b>: 選擇除 %src 外的一名其他角色→點擊確定<br/>",
}

--界潘璋＆馬忠
mobile_panzhangmazhong = sgs.General(extension, "mobile_panzhangmazhong", "wu2", "4", true,true)

mobile_duodao = sgs.CreateTriggerSkill{
	name = "mobile_duodao" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:getWeapon() then
			local _data = sgs.QVariant()
			_data:setValue(damage.from)
			if room:askForSkillInvoke(player,"mobile_duodao",_data) then
				player:obtainCard(damage.from:getWeapon())
			end
		end
	end
}

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

mobile_anjian = sgs.CreateTriggerSkill{
	name = "mobile_anjian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if not p:inMyAttackRange(player) then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if room:askForSkillInvoke(player,"mobile_duodao",_data) then

						room:setPlayerFlag(p,"mobile_anjian_target")

						local choice = room:askForChoice(player, "mobile_anjian", "mobile_anjian1+mobile_anjian2+cancel", data)
						room:setPlayerFlag(p,"-mobile_anjian_target")
						ChoiceLog(player, choice, p)
						if choice == "mobile_anjian1" then
							room:notifySkillInvoked(player, "mobile_anjian")
							room:broadcastSkillInvoke(self:objectName(), math.random(1,2))

							local msg = sgs.LogMessage()
							msg.type = "#Liegong1"
							msg.from = player
							msg.to:append(p)
							msg.arg = self:objectName()
							msg.arg2 = use.card:objectName()
							msg.card_str = use.card:toString()
							room:sendLog(msg)	
							jink_table[index] = 0

						elseif choice == "mobile_anjian2" then
							room:setCardFlag(use.card, "mobile_anjian_buff")
							room:setPlayerFlag(p, "mobile_anjian_buff")
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.DamageCaused then 
			local damage = data:toDamage()
			if damage.chain or damage.transfer or not damage.by_user then return false end
			if damage.from and damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("mobile_anjian_buff") and damage.to:hasFlag("mobile_anjian_buff") then
				room:notifySkillInvoked(damage.from, self:objectName())
				damage.damage = damage.damage + 1

				local msg = sgs.LogMessage()
				msg.type = "#AnjianBuff"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)

				data:setValue(damage)
	        end
        	return false
        end
	end,
}

mobile_panzhangmazhong:addSkill(mobile_duodao)
mobile_panzhangmazhong:addSkill(mobile_anjian)

sgs.LoadTranslationTable{
["#mobile_panzhangmazhong"] = "擒龍伏虎",
["mobile_panzhangmazhong"] = "手殺界潘璋＆馬忠",
["&mobile_panzhangmazhong"] = "潘璋馬忠",
["designer:mobile_panzhangmazhong"] = "風殘葉落",
["illustrator:mobile_panzhangmazhong"] = "zzyzzyy",
["mobile_duodao"] = "奪刀",
[":mobile_duodao"] = "當你受到傷害後，你可以獲得來源裝備區的武器牌。",
["mobile_anjian"] = "暗箭",
[":mobile_anjian"] = "鎖定技，當你使用【殺】指定目標後，若你不在其攻擊範圍內，你選擇一項1.其不能響應此牌；2.此牌對其傷害+1。",
["#AnjianBuff"] = "%from 的“<font color=\"yellow\"><b>暗箭</b></font>”效果被觸發，傷害從 %arg 點增加至 %arg2 點" ,
["mobile_anjian1"] = "令其不能響應此牌",
["mobile_anjian2"] = "此牌對其傷害+1。",
}

--公孫瓚
mobile_gongsunzan = sgs.General(extension, "mobile_gongsunzan", "qun2", "4", true,true)

mobile_yicong = sgs.CreateDistanceSkill{
	name = "mobile_yicong" ,
	correct_func = function(self, from, to)
		local correct = 0
		if from:hasSkill(self:objectName()) then
			correct = correct - (from:getHp() - 1)
		end
		if to:hasSkill(self:objectName()) then
			correct = correct + (to:getLostHp() - 1)
		end
		return correct
	end
}

mobile_gongsunzan:addSkill(mobile_yicong)
mobile_gongsunzan:addSkill("qiaomeng")

sgs.LoadTranslationTable{
["#mobile_gongsunzan"] = "白馬將軍",
["mobile_gongsunzan"] = "手殺界公孫瓚",
["&mobile_gongsunzan"] = "公孫瓚",
["illustrator:gongsunzan"] = "Vincent",
["mobile_yicong"] = "義從",
[":mobile_yicong"] = "鎖定技。你與其他角色的距離-X(X為你的體力值-1)；其他角色與你的距離+Y(Y為你的體力值+1)。",
["qiaomeng"] = "趫猛",
[":qiaomeng"] = "每當你使用黑色【殺】對一名角色造成傷害後，你可以棄置該角色裝備區的一張牌：若此牌為坐騎牌，此牌置入棄牌堆時你獲得之。",
}

--劉表
mobile_liubiao = sgs.General(extension, "mobile_liubiao", "qun2", "3", true,true)

mobile_zongshi = sgs.CreatePhaseChangeSkill{
	name = "mobile_zongshi",
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Start and player:getHandcardNum() > player:getHp() then
			player:getRoom():setPlayerMark(player,"@mobile_zongshi_slash-Clear",1)
		end
		return false
	end
}

mobile_zongshiMC = sgs.CreateMaxCardsSkill{
	name = "#mobile_zongshiMC" ,
	extra_func = function(self, target)
		local extra = 0
		local kingdom_set = {}
		table.insert(kingdom_set, target:getKingdom())
		for _, p in sgs.qlist(target:getSiblings()) do
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
		if target:hasSkill("mobile_zongshi") then
			return extra
		else
			return 0
		end
	end
}

mobile_zongshiTM = sgs.CreateTargetModSkill{
	name = "#mobile_zongshiTM" ,
	pattern = "Slash" ,
	residue_func = function(self, from)
		if from:hasSkill("mobile_zongshi") and from:getMark("@mobile_zongshi_slash-Clear") > 0 then
			return 1000
		end
		return 0
	end,
}

mobile_liubiao:addSkill(mobile_zongshi)
mobile_liubiao:addSkill(mobile_zongshiMC)
mobile_liubiao:addSkill(mobile_zongshiTM)
mobile_liubiao:addSkill("olzishou")

sgs.LoadTranslationTable{
["#mobile_liubiao"] = "跨蹈漢南",
["&mobile_liubiao"] = "劉表",
["mobile_liubiao"] = "手殺界劉表",
["designer:mobile_liubiao"] = "管樂",
["illustrator:mobile_liubiao"] = "關東煮",

["olzishou"] = "自守",
[":olzishou"] = "摸牌階段摸牌時，你可以額外摸X張牌（X為現存勢力數）。若如此做，你於本回合出牌階段內使用的牌不能指定其他角色為目標。",

["mobile_zongshi"] = "宗室",
["#mobile_zongshiMC"] = "宗室",
["#mobile_zongshiTM"] = "宗室",
[":mobile_zongshi"] = "鎖定技。你的手牌上限+X。（X為現存勢力數），準備階段，若你的手牌數大於體力值，本回合你使用「殺」無數量限制",
}
--曹植
mobile_caozhi = sgs.General(extension, "mobile_caozhi", "wei2", "3", true,true)

function gettrickcard(player)
	local room = player:getRoom()
	local GetCardList = sgs.IntList()
		local DPHeart = sgs.IntList()
		if room:getDrawPile():length() > 0 then
			for _, id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("TrickCard") then
						DPHeart:append(id)
				end
			end
		end
		if DPHeart:length() ~= 0 then
			local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
			GetCardList:append(get_id)
			local card = sgs.Sanguosha:getCard(get_id)
		end

	if GetCardList:length() ~= 0 then
		local move = sgs.CardsMoveStruct()
		move.card_ids = GetCardList
		move.to = player
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move, true)
	end
end

mobile_jiushivs = sgs.CreateViewAsSkill{
	name = "mobile_jiushi",
	n = 0,
	view_as = function(self, cards)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		return analeptic
	end,
	enabled_at_play = function(self, player)
		return sgs.Analeptic_IsAvailable(player) and player:faceUp()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic") and player:faceUp()
	end
}
mobile_jiushi = sgs.CreateTriggerSkill{
	name = "mobile_jiushi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreCardUsed, sgs.PreDamageDone, sgs.DamageComplete,sgs.TurnedOver},
	view_as_skill = mobile_jiushivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:getSkillName() == "mobile_jiushi" then
				player:turnOver()
			end
		elseif event == sgs.PreDamageDone then
			room:setTag("PredamagedFace", sgs.QVariant(player:faceUp()))
		elseif event == sgs.DamageComplete then
			local faceup = room:getTag("PredamagedFace"):toBool()
			room:removeTag("PredamagedFace")
			if not (faceup or player:faceUp()) then
				if player:askForSkillInvoke("mobile_jiushi", data) then
					player:turnOver()
					if player:getMark("mobile_jiushi_change") == 0 then
						gettrickcard(player)
					end
				end
			end
		elseif event == sgs.TurnedOver then
			if player:getMark("mobile_jiushi_change") > 0 then
				gettrickcard(player)
			end
		end
	end
}

chengzhang = sgs.CreateTriggerSkill{
	name = "chengzhang",
	frequency = sgs.Skill_Wake,
	priority = -1,
	events = {sgs.Damage,sgs.Damaged,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage or event == sgs.Damaged then
			local damage = data:toDamage()
			room:addPlayerMark(player, "@chengzhang_count",damage.damage)
		elseif event ==  sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (player:getMark("@chengzhang_count") >= 7 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) and change.to == sgs.Player_RoundStart then
				room:doSuperLightbox("mobile_caozhi","chengzhang")
				room:addPlayerMark(player, self:objectName())
				room:addPlayerMark(player, "@chengzhang_count")
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end,
}

mobile_caozhi:addSkill("luoying")
mobile_caozhi:addSkill(mobile_jiushi)
mobile_caozhi:addSkill(chengzhang)

sgs.LoadTranslationTable{
["#mobile_caozhi"] = "八斗之才",
["&mobile_caozhi"] = "曹植",
["mobile_caozhi"] = "手殺曹植",
["designer:mobile_caozhi"] = "Foxear",
["illustrator:mobile_caozhi"] = "木美人",
["luoying"] = "落英",
[":luoying"] = "其他角色的牌因判定或棄置而置入棄牌堆時，你可以獲得其中至少一張梅花牌。",
["mobile_jiushi"] = "酒詩",
[":mobile_jiushi"] = "若你的武將牌正面朝上，你可以將武將牌翻面，視為你使用了一張【酒】。每當你受到傷害扣減體力前，若武將牌背面朝上，你可以在傷害結算後將武將牌翻至正面朝上並隨機獲得牌堆裡的一張錦囊牌。",
["chengzhang"] = "成章",
[":chengzhang"] = "覺醒技。準備階段開始時，若你造成或受到的傷害和不小於7，你回復一點體力並摸一張牌，然後修改「酒詩」。",
}

--凌統
mobile_lingtong = sgs.General(extension, "mobile_lingtong", "wu2", "4", true,true)

mobile_xuanfengCard = sgs.CreateSkillCard{
	name = "mobile_xuanfeng",
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if not targets[1]:hasEquip() and targets[1]:getJudgingArea():length() == 0 then return end
			local card_id = room:askForCardChosen(source, targets[1], "ej", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local equip_index = -1
			if place == sgs.Player_PlaceEquip then
				local equip = card:getRealCard():toEquipCard()
				equip_index = equip:location()
			end
			local tos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if equip_index ~= -1 then
					--if not p:getEquip(equip_index) and p:hasEquipArea(equip_index) then
					if not p:getEquip(equip_index) and
((p:getMark("@AbolishWeapon") == 0 and equip_index == 0) or
(p:getMark("@AbolishArmor") == 0 and equip_index == 1) or
(p:getMark("@AbolishHorse") == 0 and equip_index == 2) or
(p:getMark("@AbolishHorse") == 0 and equip_index == 3) or
(p:getMark("@AbolishTreasure") == 0 and equip_index == 4)) then
						tos:append(p)
					end
				else
					if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
						tos:append(p)
					end
				end
			end
			local tag = sgs.QVariant()
			tag:setValue(targets[1])
			room:setTag("QiaobianTarget", tag)
			--local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to" .. card:objectName())
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@mobile_xuanfeng-to".. card:objectName())
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
mobile_xuanfengVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_xuanfeng",
	view_as = function()
		return mobile_xuanfengCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@mobile_xuanfeng"
	end,
}

mobile_xuanfeng = sgs.CreateTriggerSkill{
	name = "mobile_xuanfeng" ,
	events = {sgs.CardsMoveOneTime} ,
	view_as_skill = mobile_xuanfengVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard)
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				room:setPlayerMark(player,"mobile_xuanfeng-Clear", player:getMark("mobile_xuanfeng-Clear") + move.card_ids:length())
			end
			if ((player:getMark("mobile_xuanfeng-Clear") >= 2) and (not player:hasFlag("mobile_xuanfengUsed"))) or move.from_places:contains(sgs.Player_PlaceEquip) then
				if room:askForUseCard(player, "@@mobile_xuanfeng", "@mobile_xuanfeng", -1, sgs.Card_MethodNone) then

				else

					for i = 1,2,1 do
					
						local targets = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							if player:canDiscard(p, "he") then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							local target = room:askForPlayerChosen(player, targets, "mobile_xuanfeng2", "mobile_xuanfeng-invoke", true, true)
							if target then
								room:addPlayerMark(player, self:objectName().."engine")
								if player:getMark(self:objectName().."engine") > 0 then
									local id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
									room:throwCard(id, target, player)
									room:removePlayerMark(player, self:objectName().."engine")
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

mobile_lingtong:addSkill(mobile_xuanfeng)

sgs.LoadTranslationTable{
["#mobile_lingtong"] = "豪情烈膽",
["mobile_lingtong"] = "手殺界凌統",
["&mobile_lingtong"] = "凌統",
["illustrator:mobile_lingtong"] = "紫喬",
["mobile_xuanfeng"] = "旋風",
["mobile_xuanfeng2"] = "旋風",
[":mobile_xuanfeng"] = "當你於棄牌階段棄置過至少兩張牌，或當你失去裝備區的牌後，你可以選擇一項:1、棄置至多兩名其他角色的共計兩張牌;將一名其他角色裝備區內的一張牌移動到另一名其他角色的對應區域。",
["mobile_xuanfeng-invoke"] = "你可以發動“旋風”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["@mobile_xuanfeng-to"] = "請選擇移動【%src】的目標角色",
}

--吳國太
mobile_wuguotai = sgs.General(extension, "mobile_wuguotai", "wu2", "3", false,true)

function swapEquip(first, second)
	local room = first:getRoom()
	local equips1, equips2 = sgs.IntList(), sgs.IntList()
	for _, equip in sgs.qlist(first:getEquips()) do
		equips1:append(equip:getId())
	end
	for _, equip in sgs.qlist(second:getEquips()) do
		equips2:append(equip:getId())
	end
	local exchangeMove = sgs.CardsMoveList()
	local move1 = sgs.CardsMoveStruct(equips1, second, sgs.Player_PlaceEquip, 
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, first:objectName(), second:objectName(), "mobile_ganlu", ""))
	local move2 = sgs.CardsMoveStruct(equips2, first, sgs.Player_PlaceEquip,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, first:objectName(), second:objectName(), "mobile_ganlu", ""))
	exchangeMove:append(move2)
	exchangeMove:append(move1)
	room:moveCards(exchangeMove, false)
end

mobile_ganluCard = sgs.CreateSkillCard{
	name = "mobile_ganlu" ,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			local n1 = targets[1]:getEquips():length()
			local n2 = to_select:getEquips():length()
			return (math.abs(n1 - n2) <= sgs.Self:getLostHp() or to_select:objectName() == sgs.Self:objectName() or targets[1]:objectName() == sgs.Self:objectName())
		else
			return false
		end
	end ,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		swapEquip(targets[1], targets[2])
	end
}
mobile_ganlu = sgs.CreateViewAsSkill{
	name = "mobile_ganlu" ,
	n = 0 ,
	view_as = function()
		return mobile_ganluCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_ganlu")
	end
}

mobile_wuguotai:addSkill(mobile_ganlu)
mobile_wuguotai:addSkill("buyi")

sgs.LoadTranslationTable{
["#mobile_wuguotai"] = "武烈皇后",
["&mobile_wuguotai"] = "吳國太",
["mobile_wuguotai"] = "手殺界吳國太",
["designer:mobile_wuguotai"] = "章魚咬你哦",
["illustrator:mobile_wuguotai"] = "zoo",
["mobile_ganlu"] = "甘露",
[":mobile_ganlu"] = "階段技。你可以令裝備區的牌數量差不超過你已損失體力值的兩名角色交換他們裝備區的裝備牌。",
["buyi"] = "補益",
[":buyi"] = "每當一名角色進入瀕死狀態時，你可以展示該角色的一張手牌：若此牌為非基本牌，該角色棄置此牌，然後回復1點體力。 ",
["#GanluSwap"] = "%from 交換了 %to 的裝備",
}

--鐘會
mobile_zhonghui = sgs.General(extension, "mobile_zhonghui", "wei2", "4", true,true)

mobile_quanji = sgs.CreateTriggerSkill{
	name = "mobile_quanji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local x = damage.damage
			for i = 0, x - 1, 1 do
				if player:askForSkillInvoke(self:objectName()) then
					room:broadcastSkillInvoke("quanji")
					room:drawCards(player, 1, self:objectName())
					if not player:isKongcheng() then
						local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						if player:getHandcardNum() == 1 then
							card_id = player:handCards():first()
							room:getThread():delay()
						else
							card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush"):getSubcards():first()
						end
						player:addToPile("power", card_id)
					end
				end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:getHandcardNum() > player:getHp() then
			if player:askForSkillInvoke(self:objectName()) then
				room:broadcastSkillInvoke("quanji")
				room:drawCards(player, 1, self:objectName())
				if not player:isKongcheng() then
					local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					if player:getHandcardNum() == 1 then
						card_id = player:handCards():first()
						room:getThread():delay()
					else
						card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush"):getSubcards():first()
					end
					player:addToPile("power", card_id)
				end
			end
		end
	end
}

mobile_quanji_mc = sgs.CreateMaxCardsSkill{
	name = "#mobile_quanji_mc",
	frequency = sgs.Skill_Frequent,
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getPile("power"):length()
		else
			return 0
		end
	end
}

mobile_zhonghui:addSkill(mobile_quanji)
mobile_zhonghui:addSkill(mobile_quanji_mc)
mobile_zhonghui:addSkill("zili")

sgs.LoadTranslationTable{
["#mobile_zhonghui"] = "桀驁的野心家",
["&mobile_zhonghui"] = "鐘會",
["mobile_zhonghui"] = "手殺界鐘會",
["illustrator:mobile_zhonghui"] = "紫喬",
["mobile_quanji"] = "權計",
[":mobile_quanji"] = "出牌階段結束時，若你的手牌數大於體力值，或當你受到1點傷害後，你可以摸一張牌，然後將一張手牌置於武將牌上，稱為“權”。每有一張“權”，你的手牌上限+1。",
["QuanjiPush"] = "請將一張手牌置於武將牌上",
["zili"] = "自立",
[":zili"] = "覺醒技。準備階段開始時，若“權”大於或等於三張，你失去1點體力上限，摸兩張牌或回復1點體力，然後獲得“排異”（階段技。你可以將一張“權”置入棄牌堆並選擇一名角色：若如此做，該角色摸兩張牌：若其手牌多於你，該角色受到1點傷害）。" ,
["#ZiliWake"] = "%from 的“權”為 %arg 張，觸發“%arg2”覺醒",
["zili:draw"] = "摸兩張牌",
["zili:recover"] = "回復1點體力",
["power"] = "權",
["$ZiliAnimate"] = "image=image/animate/zili.png",
["paiyi"] = "排異",
[":paiyi"] = "階段技。你可以將一張“權”置入棄牌堆並選擇一名角色：若如此做，該角色摸兩張牌：若其手牌多於你，該角色受到1點傷害。",
}

--手殺小喬
mobile_xiaoqiao = sgs.General(extension, "mobile_xiaoqiao", "wu2", "3", false,true)

mobile_hongyan = sgs.CreateFilterSkill{
	name = "mobile_hongyan",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end
}

mobile_hongyan_trigger = sgs.CreateTriggerSkill{
	name = "#mobile_hongyan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.AskForRetrial},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart or event == sgs.EventAcquireSkill then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:handleAcquireDetachSkills(p, "#mobile_hongyan_spade_judge|#mobile_hongyan_diamond_judge|#mobile_hongyan_club_judge", false)
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if player:hasSkill(self:objectName()) and judge.card:getSuit() == sgs.Card_Heart and room:askForSkillInvoke(player, self:objectName(), data) then
				local choice = room:askForChoice(player, "mobile_hongyan", "mobile_hongyan_Spade+mobile_hongyan_Club+mobile_hongyan_Diamond")
				if choice == "mobile_hongyan_Spade" then
					room:setCardFlag(judge.card, "mobile_hongyan_spade_judge")
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
					
					--已下只對判定條件有judge:isGood()有效
--					room:handleAcquireDetachSkills(judge.who, "#mobile_hongyan_spade_5_judge", false)
--					local cardlists = sgs.CardList()
--					cardlists:append(judge.card)
--					room:filterCards(judge.who, cardlists, true)
--					judge:updateResult()
--					room:handleAcquireDetachSkills(judge.who, "-#mobile_hongyan_spade_5_judge", false)
				elseif choice == "mobile_hongyan_Club" then
					room:setCardFlag(judge.card, "mobile_hongyan_club_judge")
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
				elseif choice == "mobile_hongyan_Diamond" then
					room:setCardFlag(judge.card, "mobile_hongyan_diamond_judge")
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
					
					--已下只對判定條件有judge:isGood()有效
--					room:handleAcquireDetachSkills(judge.who, "#mobile_hongyan_heart_5_judge", false)
--					local cardlists = sgs.CardList()
--					cardlists:append(judge.card)
--					room:filterCards(judge.who, cardlists, true)
--					judge:updateResult()
--					room:handleAcquireDetachSkills(judge.who, "-#mobile_hongyan_heart_5_judge", false)
				end
			end
		end
		return false
	end
}

mobile_xiaoqiao:addSkill(mobile_hongyan)
mobile_xiaoqiao:addSkill(mobile_hongyan_trigger)
mobile_xiaoqiao:addSkill("ol_tianxiang")
extension:insertRelatedSkills("mobile_hongyan","#mobile_hongyan")

mobile_hongyan_spade_judge = sgs.CreateFilterSkill{
	name = "#mobile_hongyan_spade_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("mobile_hongyan_spade_judge")
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("mobile_hongyan")
		new_card:setSuit(sgs.Card_Spade)
		new_card:setModified(true)
		return new_card
	end
}

if not sgs.Sanguosha:getSkill("#mobile_hongyan_spade_judge") then skills:append(mobile_hongyan_spade_judge) end

mobile_hongyan_diamond_judge = sgs.CreateFilterSkill{
	name = "#mobile_hongyan_diamond_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("mobile_hongyan_diamond_judge")
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("mobile_hongyan")
		new_card:setSuit(sgs.Card_Diamond)
		new_card:setModified(true)
		return new_card
	end
}

if not sgs.Sanguosha:getSkill("#mobile_hongyan_diamond_judge") then skills:append(mobile_hongyan_diamond_judge) end

mobile_hongyan_club_judge = sgs.CreateFilterSkill{
	name = "#mobile_hongyan_club_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("mobile_hongyan_club_judge")
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("mobile_hongyan")
		new_card:setSuit(sgs.Card_Club)
		new_card:setModified(true)
		return new_card
	end
}

if not sgs.Sanguosha:getSkill("#mobile_hongyan_club_judge") then skills:append(mobile_hongyan_club_judge) end

sgs.LoadTranslationTable{
["#mobile_xiaoqiao"] = "矯情之花",
["&mobile_xiaoqiao"] = "小喬",
["mobile_xiaoqiao"] = "手殺小喬",
["mobile_hongyan"] = "紅顏",
["#mobile_hongyan"] = "紅顏",
[":mobile_hongyan"] = "鎖定技。妳的黑桃牌視為紅桃牌。當一張紅心判定牌生效前，妳可以令判定結果改為其他花色",
["mobile_hongyan_spade_judge"] = "紅顏",
["mobile_hongyan_diamond_judge"] = "紅顏",
["mobile_hongyan_club_judge"] = "紅顏",
["mobile_hongyan_Spade"] = "黑桃",
["mobile_hongyan_Diamond"] = "方塊",
["mobile_hongyan_Club"] = "梅花",
}

--界虞翻
mobile_yufan = sgs.General(extension, "mobile_yufan", "wu2", 3, true, true)

mobile_zongxuanUseCard = sgs.CreateSkillCard{
	name = "mobile_zongxuanUse",
	target_fixed = true,
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local sbs = {}
		if source:getTag("mobile_zongxuan"):toString() ~= "" then
			sbs = source:getTag("mobile_zongxuan"):toString():split("+")
		end
		for _,cdid in sgs.qlist(self:getSubcards()) do table.insert(sbs, tostring(cdid))  end
		source:setTag("mobile_zongxuan", sgs.QVariant(table.concat(sbs, "+")))
	end
}

mobile_zongxuanCard = sgs.CreateSkillCard{
	name = "mobile_zongxuan",
	target_fixed = true,
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		source:drawCards(1)
		local card = room:askForCard(source, ".!", "@mobile_zongxuan", sgs.QVariant(), sgs.Card_MethodNone)
		if card then
			local move = sgs.CardsMoveStruct(card:getEffectiveId(), source, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, source:objectName(), self:objectName(), ""))
			room:moveCardsAtomic(move, false)
		end
	end
}

mobile_zongxuanVS = sgs.CreateViewAsSkill{
	name = "mobile_zongxuan",
	n = 998,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@mobile_zongxuan" then
			local str = sgs.Self:property("mobile_zongxuan"):toString()
			return string.find(str, tostring(to_select:getEffectiveId()))
		else
			return false
		end
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@mobile_zongxuan" then
			if #cards ~= 0 then
				local card = mobile_zongxuanUseCard:clone()
				for var=1,#cards do card:addSubcard(cards[var]) end
				return card
			end
		else
			return mobile_zongxuanCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_zongxuan")
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@mobile_zongxuan"
	end,
}
function listIndexOf(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
mobile_zongxuan = sgs.CreateTriggerSkill{
	name = "mobile_zongxuan",
	view_as_skill = mobile_zongxuanVS,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if not move.from or source:objectName() ~= player:objectName() then return end
		local reason = move.reason.m_reason
		if move.to_place == sgs.Player_DiscardPile then
			if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local zongxuan_card = sgs.IntList()
				for i=0, (move.card_ids:length()-1), 1 do
					local card_id = move.card_ids:at(i)
					if room:getCardOwner(card_id):getSeat() == source:getSeat()
						and (move.from_places:at(i) == sgs.Player_PlaceHand
						or move.from_places:at(i) == sgs.Player_PlaceEquip) then
						zongxuan_card:append(card_id)
					end
				end
				if zongxuan_card:isEmpty() then
					return
				end
				local zongxuantable = sgs.QList2Table(zongxuan_card)
				room:setPlayerProperty(player, "mobile_zongxuan", sgs.QVariant(table.concat(zongxuantable, "+")))
				while not zongxuan_card:isEmpty() do
					if not room:askForUseCard(player, "@@mobile_zongxuan", "@zongxuan-put") then break end
					local subcards = sgs.IntList()
					local subcards_variant = player:getTag("mobile_zongxuan"):toString():split("+")
					if #subcards_variant>0 then
						for _,ids in ipairs(subcards_variant) do 
							subcards:append(tonumber(ids)) 
						end
						local zongxuan = player:property("mobile_zongxuan"):toString():split("+")
						for _, id in sgs.qlist(subcards) do
							zongxuan_card:removeOne(id)
							table.removeOne(zongxuan,tonumber(id))
							if move.card_ids:contains(id) then
								move.from_places:removeAt(listIndexOf(move.card_ids, id))
								move.card_ids:removeOne(id)
								data:setValue(move)
							end
							room:setPlayerProperty(player, "zongxuan_move", sgs.QVariant(tonumber(id)))
							room:moveCardTo(sgs.Sanguosha:getCard(id), player, nil ,sgs.Player_DrawPile, move.reason, true)
							if not player:isAlive() then break end
						end
					end
					player:removeTag("mobile_zongxuan")
				end
			end
		end
		return
	end,
}

mobile_yufan:addSkill(mobile_zongxuan)
mobile_yufan:addSkill("zhiyan")

sgs.LoadTranslationTable{
["#mobile_yufan"] = "狂直之士",
["&mobile_yufan"] = "虞翻",
["mobile_yufan"] = "手殺界虞翻",
["designer:mobile_yufan"] = "幻島",
["illustrator:yufan"] = "L",
["mobile_zongxuan"] = "縱玄",
["mobile_zongxuanUse"] = "縱玄",
[":mobile_zongxuan"] = "當你的牌因棄置而進入棄牌堆後，你可以將其以任意順序置於牌堆頂。出牌階段限一次，你可以摸一張牌，然後將一張牌置於牌堆頂。",
["@mobile_zongxuan"] = "你需將一張牌置於牌堆頂。",
["@zongxuan-put"] = "你可以發動“縱玄”",
["~mobile_zongxuan"] = "選擇任意數量的牌→點擊確定（這些牌將以與你點擊順序相反的順序置於牌堆頂）",
["zhiyan"] = "直言",
[":zhiyan"] = "結束階段開始時，你可以令一名角色摸一張牌並展示之：若此牌為裝備牌，該角色回復1點體力，然後使用之。",
["zhiyan-invoke"] = "你可以發動“直言”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
}
--界李儒
mobile_liru = sgs.General(extension, "mobile_liru", "qun2", 3, true, true)

mobile_juece = sgs.CreateTriggerSkill{
	name = "mobile_juece",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("lose_card-Clear") > 0 then
							_targets:append(p) 
						end
					end
					if not _targets:isEmpty() then
						local s = room:askForPlayerChosen(player, _targets, "juece", "@mobile_juece", true)
						if s then
							room:broadcastSkillInvoke(self:objectName())
							room:doAnimate(1, player:objectName(), s:objectName())
							room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))
						end
					end
			end
		end
	end,
	priority = 8,
}

mobile_miejiCard = sgs.CreateSkillCard{
	name = "mobile_mieji",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "mobile_miejiengine")
		if source:getMark("mobile_miejiengine") > 0 then
			local move = sgs.CardsMoveStruct(self:getSubcards():first(), source, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, source:objectName(), self:objectName(), ""))
			room:moveCardsAtomic(move, false)
			local card = room:askForCard(targets[1], ".!", "@mobile_mieji", sgs.QVariant(), sgs.Card_MethodNone)
			if card then
				if card:isKindOf("TrickCard") then
					room:obtainCard(card, source,true)
				else
					room:throwCard(card, targets[1], targets[1])
					room:setPlayerFlag(targets[1],"mobile_mieji_discard")
					local card2 = room:askForCard(targets[1], "^TrickCard!", "@mobile_mieji", sgs.QVariant(), sgs.Card_MethodNone)
					room:throwCard(card2, targets[1], targets[1])
					room:setPlayerFlag(targets[1],"-mobile_mieji_discard")
				end
			end
		end
	end
}
mobile_mieji = sgs.CreateOneCardViewAsSkill{
	name = "mobile_mieji",
	view_filter = function(self, card)
		return card:isKindOf("TrickCard") and card:isBlack()
	end,
	view_as = function(self,card)
		local skillcard = mobile_miejiCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_mieji")
	end
}

mobile_liru:addSkill(mobile_juece)
mobile_liru:addSkill(mobile_mieji)
mobile_liru:addSkill("fencheng")

sgs.LoadTranslationTable{
["#mobile_liru"] = "魔仕",
["&mobile_liru"] = "李儒",
["mobile_liru"] = "手殺界李儒",
["illustrator:mobile_liru"] = "MSNZero",
["mobile_juece"] = "絕策",
[":mobile_juece"] = "結束階段，你可以對一名本回合內失去過牌的角色造成1點傷害。",
["@mobile_juece"] = "你可以發動“絕策”<br/> <b>操作提示</b>: 選擇一名本回合內失去過牌的角色→點擊確定<br/>",
["mobile_mieji"] = "滅計",
[":mobile_mieji"] = "階段技，你可以將一張黑色錦囊牌置於牌堆頂，然後令一名有牌的其他角色選擇一項：交給你一張錦囊牌，或依次棄置兩張非錦囊牌。",
["fencheng"] = "焚城",
[":fencheng"] = "限定技。出牌階段，你可以令所有其他角色：棄置至少X張牌，否則受到2點火焰傷害。（X為上一名進行選擇的角色以此法棄置的牌數+1）",
["@fencheng"] = "請棄置至少 %arg 張牌（包括裝備區的牌）",
["$FenchengAnimate"] = "image=image/animate/fencheng.png",
}

--滿寵
mobile_manchong = sgs.General(extension, "mobile_manchong", "wei2", 3, true, true)


mobile_junxingCard = sgs.CreateSkillCard{
	name = "mobile_junxing" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		if not targets[1]:isAlive() then return end
		local n = self:getSubcards():length()
		local choice = room:askForChoice(targets[1], "mobile_fangzhu", "mobile_fangzhu1+mobile_fangzhu2")
		if choice == "mobile_fangzhu1" then
			targets[1]:drawCards(n, self:objectName())
			targets[1]:turnOver()
		elseif choice == "mobile_fangzhu2" then
			room:askForDiscard(targets[1],"mobile_fangzhu",n,n, false, true)
			room:loseHp(targets[1])
		end
	end
}
mobile_junxing = sgs.CreateViewAsSkill{
	name = "mobile_junxing" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = mobile_junxingCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and (not player:hasUsed("#mobile_junxing"))
	end
}

mobile_manchong:addSkill(mobile_junxing)
mobile_manchong:addSkill("yuce")

sgs.LoadTranslationTable{
	["#mobile_manchong"] = "政法兵謀",
	["mobile_manchong"] = "手殺界滿寵",
	["&mobile_manchong"] = "滿寵",
	["designer:mobile_manchong"] = "SamRosen",
	["illustrator:mobile_manchong"] = "Aimer彩三",
	["mobile_junxing"] = "峻刑",
	[":mobile_junxing"] = "階段技。你可以棄置任意張手牌並選擇一名其他角色。該角色選擇一項：1.棄置X張牌並失去1點體力。2.翻面並摸X張牌。（X為你棄置的牌數）",
	["@junxing-discard"] = "請棄置一張與“峻刑”棄牌類型均不同的手牌",
	["yuce"] = "禦策",
	[":yuce"] = "每當你受到傷害後，你可以展示一張手牌：若如此做且此傷害有來源，傷害來源須棄置一張與此牌類型不同的手牌，否則你回复1點體力。",
	["@yuce-show"] = "你可以發動“禦策”展示一張手牌",
	["@yuce-discard"] = "%src 發動了“禦策”，請棄置一張 %arg 或 %arg2",
	["mobile_fangzhu1"] = "摸X張牌，然後將其武將牌翻面",
	["mobile_fangzhu2"] = "棄置X張牌，然後失去一點體力",
}

--手殺界荀彧
mobile_xunyu = sgs.General(extension, "mobile_xunyu", "wei2", 3, true, true)

mobile_jieming = sgs.CreateTriggerSkill{
	name = "mobile_jieming" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "mobile_jieming-invoke", true, true)
			if to then
				to:drawCards(2)
				if to:getHandcardNum() < to:getMaxHp() then
					player:drawCards(1)
				end
			end
		end
	end
}

mobile_xunyu:addSkill("quhu")
mobile_xunyu:addSkill(mobile_jieming)

sgs.LoadTranslationTable{
["#mobile_xunyu"] = "王佐之才",
["mobile_xunyu"] = "手殺界荀彧",
["&mobile_xunyu"] = "荀彧",
["illustrator:mobile_xunyu"] = "紫喬",
["quhu"] = "驅虎",
[":quhu"] = "階段技。你可以與一名體力值大於你的角色拼點：若你贏，該角色對其攻擊範圍內的一名由你選擇的角色造成1點傷害；若你沒贏，該角色對你造成1點傷害。",
["@quhu-damage"] = "請選擇 %src 攻擊範圍內的一名角色",
["mobile_jieming"] = "節命",
[":mobile_jieming"] = "當你受到1點傷害後，你可以令一名角色摸兩張牌。然後若其手牌數小於體力上限，則你摸一張牌。",
["mobile_jieming-invoke"] = "你可以發動“節命”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",

}
--陳群
mobile_chenqun = sgs.General(extension, "mobile_chenqun", "wei2", 3, true, true)

mobile_dingpinCard = sgs.CreateSkillCard{
    name = "mobile_dingpin" ,
    filter = function(self, targets, to_select, Self)
        return #targets == 0 and to_select:getMark("mobile_dingpin_target-Clear") == 0
    end ,
    on_effect = function(self, effect) 
        local room = effect.from:getRoom()
        local judge = sgs.JudgeStruct()
        judge.who = effect.to
        judge.good = true
        judge.pattern = ".|black"
        judge.reason = "mobile_dingpin"
        room:judge(judge)
        if (judge:isGood()) then
            room:addPlayerMark(effect.to,"mobile_dingpin_target-Clear")
            effect.to:drawCards(math.min(3,effect.to:getHp()), "mobile_dingpin")
        elseif judge.card:getSuit() == sgs.Card_Diamond then
            effect.from:turnOver()
        end
        if judge.card:getSuit() == sgs.Card_Heart then
        	room:addPlayerMark(effect.from, "mobile_dingpin"..sgs.Sanguosha:getCard(self:getSubcards():first()).."-Clear")
        end
    end ,
}

mobile_dingpin = sgs.CreateOneCardViewAsSkill{
    name = "mobile_dingpin" ,
    view_filter = function(self, card)
        return sgs.Self:getMark("used_cardtype"..card:getTypeId().."-Clear") == 0 and sgs.Self:getMark("mobile_dingpin"..card:getTypeId().."-Clear") == 0
    end ,
    view_as = function(self, card)
        local dp = mobile_dingpinCard:clone()
        dp:addSubcard(card)
        return dp
    end ,

    enabled_at_play = function(self, player)
        return true
    end ,
}

mobile_chenqun:addSkill(mobile_dingpin)
mobile_chenqun:addSkill("faen")

sgs.LoadTranslationTable{
["#mobile_chenqun"] = "萬世臣表",
["mobile_chenqun"] = "手殺界陳群",
["&mobile_chenqun"] = "陳群",
["illustrator:mobile_chenqun"] = "DH",
["designer:mobile_chenqun"] = "To Joanna",
["mobile_dingpin"] = "定品",
[":mobile_dingpin"] = "出牌階段，你可以棄置一張與你本回合已使用或棄置的牌類別均不同的手牌，然後令一名已受傷的角色進行判定：若結果為黑色，該角色摸X張牌，且你本階段不能對該角色發動“定品”；方塊，你將武將牌翻面；紅心：你使用的牌不計入”定品“。（X為該角色體力值且最多為3）",
["faen"] = "法恩",
[":faen"] = "每當一名角色的武將牌翻面或橫置時，你可以令其摸一張牌。",
}

--手殺郭淮
mobile_guohuai = sgs.General(extension, "mobile_guohuai", "wei2", 3, true, true)

--精策
mobile_jingce = sgs.CreateTriggerSkill{
	name = "mobile_jingce", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("enter_discard_pile-Clear") >= player:getHp() and room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(2)
				end
			end
		end
	end
}

mobile_guohuai:addSkill(mobile_jingce)

sgs.LoadTranslationTable{
	["mobile_guohuai"] = "界郭淮",
	["&mobile_guohuai"] = "郭淮",
	["#mobile_guohuai"] = "",
	["mobile_jingce"] = "精策",
	[":mobile_jingce"] = "結束階段，若此回合因使用或打出而置入棄牌堆的牌的數量不小於你的體力值，則你可以摸兩張牌。",
}

--界廖化
mobile_liaohua = sgs.General(extension,"mobile_liaohua","shu2","4",true,true)
--當先 
mobile_dangxian = sgs.CreateTriggerSkill{
	name = "mobile_dangxian" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			getpatterncard(player, {"Slash"},false,true)
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
		end
		return false
	end
}

--伏櫪 限定技，當你處於瀕死狀態時，你可以將體力回復至X點且手牌摸至X張（X為全場勢力數），
--然後“當先”中失去體力的效果改為可選。若X大於等於3，你翻面。
--當先•改後 鎖定技，回合開始時，你執行一個額外的出牌階段。此階段開始時，
--你可以失去1點體力並從棄牌堆獲得一張【殺】
getKingdomsFuli = function(yuanshu)
	local kingdoms = {}
	local room = yuanshu:getRoom()
	for _, p in sgs.qlist(room:getAlivePlayers()) do
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
mobile_fuli = sgs.CreateTriggerSkill{
	name = "mobile_fuli" ,
	frequency = sgs.Skill_Limited ,
	events = {sgs.AskForPeaches} ,
	limit_mark = "@laoji",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who:objectName() ~= player:objectName() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:removePlayerMark(player, "@laoji")
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:doSuperLightbox("liaohua","mobile_fuli")

			local recover = sgs.RecoverStruct()
			recover.recover = math.min( getKingdomsFuli(player), player:getMaxHp()) - player:getHp()
			room:recover(player, recover)

			local can_invoke = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getHp() <= p:getHp() then
					can_invoke = false
					break
				end
			end
			if can_invoke then
				player:turnOver()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName())) and (target:getMark("@laoji") > 0)
	end
}

mobile_liaohua:addSkill(mobile_dangxian)
mobile_liaohua:addSkill(mobile_fuli)

sgs.LoadTranslationTable{
	["mobile_liaohua"] = "手殺界廖化",
	["&mobile_liaohua"] = "廖化",
	["#mobile_liaohua"] = "歷經滄桑",
	["mobile_dangxian"] = "當先",
	[":mobile_dangxian"] = "鎖定技，回合開始時，你從棄牌堆中獲得一張【殺】並進行一個額外的出牌階段。",
	["mobile_fuli"] = "伏櫪",
	[":mobile_fuli"] = "限定技，當你處於瀕死狀態時，你可以將體力值回復至X點（X為勢力數）。然後若你的體力值為全場唯一最多，你翻面。",
}

--界簡雍
mobile_jianyong = sgs.General(extension,"mobile_jianyong","shu2","3",true,true)

mobile_qiaoshuiUseCard = sgs.CreateSkillCard{
	name = "mobile_qiaoshuiUse" ,
	filter = function(self, targets, to_select)
		if #targets >= sgs.Self:getMark("mobile_qiaoshui_success") then return false end
		if to_select:hasFlag("notZangshiTarget") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			p:setFlags("zangshiTarget")
		end
	end
}

mobile_qiaoshuiCard = sgs.CreateSkillCard{
	name = "mobile_qiaoshui" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName()) and to_select:getMark("mobile_qiaoshui_target-Clear") == 0
	end ,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "mobile_qiaoshui", nil)
		room:addPlayerMark(targets[1], "mobile_qiaoshui_target-Clear")
		if (success) then
			room:addPlayerMark(source, "mobile_qiaoshui_success")
		else
			room:setPlayerCardLimitation(source, "use", "TrickCard", true)
		end
	end
}

mobile_qiaoshuiVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_qiaoshui" ,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@mobile_qiaoshui")
	end ,
	view_as = function()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@mobile_qiaoshui" then
			return mobile_qiaoshuiUseCard:clone()
		else
			return mobile_qiaoshuiCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#mobile_qiaoshui")) and (not player:isKongcheng())
	end,  
}

mobile_qiaoshui = sgs.CreateTriggerSkill{
	name = "mobile_qiaoshui" ,
	view_as_skill = mobile_qiaoshuiVS ,
	events = {sgs.PreCardUsed,sgs.EventPhaseChanging,sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and
			 not use.card:isKindOf("Jink") and not use.card:isKindOf("Nullification") and
			  not use.card:isKindOf("Collateral") and player:getMark("mobile_qiaoshui_success") > 0 then

					room:setPlayerFlag(player, "mobile_qiaoshuitm")
					room:setTag("mobile_qiaoshuiData", data)	
					if room:askForUseCard(player, "@@mobile_qiaoshui", "@mobile_qiaoshui-use:::"..use.card:objectName(), -1, sgs.Card_MethodDiscard) then
						room:removeTag("mobile_qiaoshuiData")
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasFlag("zangshiTarget") and not room:isProhibited(player, p, use.card) and not use.to:contains(p)  then
								p:setFlags("-zangshiTarget")
								use.to:append(p)
								room:sortByActionOrder(use.to)
								data:setValue(use)

								local msg = sgs.LogMessage()
								msg.type = "#ExtraTarget"
								msg.from = player
								msg.to:append(p)
								msg.arg = self:objectName()
								msg.arg2 = use.card:objectName()
								room:sendLog(msg)
							elseif p:hasFlag("zangshiTarget") and use.to:contains(p) then
								use.to:removeOne(p)
								room:sortByActionOrder(use.to)
								data:setValue(use)
							end
						end
					end
					room:setPlayerFlag(player, "-mobile_qiaoshuitm")
					room:setPlayerMark(player,"mobile_qiaoshui_success",0)
			end
		end
	end,
}
mobile_qiaoshuiTargetMod = sgs.CreateTargetModSkill{
	name = "#mobile_qiaoshui-target" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("mobile_qiaoshuitm")) then
			return 1000
		end
		return 0
	end
}



mobile_zongshih = sgs.CreateTriggerSkill{
	name = "mobile_zongshih" ,
	events = {sgs.Pindian} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data, room)
		local pindian = data:toPindian()
		local to_obtain = nil
		local jianyong = nil
		if (pindian.from and pindian.from:isAlive() and pindian.from:hasSkill(self:objectName())) then
			jianyong = pindian.from
			if pindian.from_number > pindian.to_number then
				to_obtain = pindian.to_card
			else
				to_obtain = pindian.from_card
			end
		elseif (pindian.to and pindian.to:isAlive() and pindian.to:hasSkill(self:objectName())) then
			jianyong = pindian.to
			if pindian.from_number < pindian.to_number then
				to_obtain = pindian.from_card
			else
				to_obtain = pindian.to_card
			end
		end
		if jianyong then
			local ids = sgs.IntList()
			ids:append(room:drawCard())
			if to_obtain and (room:getCardPlace(to_obtain:getEffectiveId()) == sgs.Player_PlaceTable) then
				ids:append(to_obtain:getEffectiveId())
			end
			if ids:length() > 0 then
				if room:askForSkillInvoke(jianyong, self:objectName(), data) then					
					room:fillAG(ids, jianyong)
					local card_id = room:askForAG(jianyong, ids, false, self:objectName())
					if card_id ~= -1 then
						jianyong:obtainCard( sgs.Sanguosha:getCard(card_id) )
					end
					room:clearAG(jianyong)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

mobile_jianyong:addSkill(mobile_qiaoshui)
mobile_jianyong:addSkill(mobile_qiaoshuiTargetMod)
mobile_jianyong:addSkill(mobile_zongshih)

sgs.LoadTranslationTable{
["#mobile_jianyong"] = "優游風議",
["mobile_jianyong"] = "手殺界簡雍",
["&mobile_jianyong"] = "簡雍",
["designer:mobile_jianyong"] = "Nocihoo",
["illustrator:mobile_jianyong"] = "紫喬",
["mobile_qiaoshui"] = "巧說",
["mobile_qiaoshuiUse"] = "巧說",
["mobile_qiaoshuiuse"] = "巧說",
[":mobile_qiaoshui"] = "出牌階段限一次，你可以和一名其他角色拼點。若你贏，則你本階段內使用的下一張基本牌或普通錦囊牌可以增加減少一個目標。若你沒贏，你本階段內不能使用錦囊牌。",
["mobile_qiaoshui:add"] = "增加一名目標",
["mobile_qiaoshui:remove"] = "減少一名目標",

["@mobile_qiaoshui-use"] = "請選擇【%arg】的額外目標，或是減少的目標",

["~mobile_qiaoshui"] = "選擇目標角色→點擊確定",

["mobile_zongshih"] = "縱適",
[":mobile_zongshih"] = "當你拼點後，你可以觀看牌堆頂的一張牌，然後選擇一項：獲得此牌，或獲得兩張拼點牌中點數較小的一張。",
["#QiaoshuiAdd"] = "%from 發動了“%arg”為 %card 增加了額外目標 %to",
["#QiaoshuiRemove"] = "%from 發動了“%arg”為 %card 減少了目標 %to",
}

--朱然
mobile_zhuran = sgs.General(extension,"mobile_zhuran","wu2","4",true,true)
--膽守
mobile_danshou = sgs.CreateTriggerSkill{
	name = "mobile_danshou" ,
	events = {sgs.TargetConfirmed,sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("mobile_danshou") then
						if p:getMark("has_been_target-Clear") == 0 then
							player:drawCards(1)
						else
							local n = p:getMark("has_been_target-Clear")
							if n > 0 and ((p:getHandcardNum() + p:getEquips():length()) >= n) then
								local cards = room:askForExchange(p, self:objectName(), n, n, true, "@mobile_danshou_ask", true)
								if cards then
									room:broadcastSkillInvoke(self:objectName())
									room:doAnimate(1, p:objectName(), player:objectName())
									room:throwCard(cards, p, p)
									room:damage(sgs.DamageStruct("mobile_danshou", p, player, 1, sgs.DamageStruct_Normal))
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}

mobile_zhuran:addSkill(mobile_danshou)

sgs.LoadTranslationTable{
	["mobile_zhuran"] = "手殺界朱然",
	["&mobile_zhuran"] = "朱然",
	["#mobile_zhuran"] = "不動之督",
	["illustrator:mobile_zhuran"] = "",
	["mobile_danshou"] = "膽守",
	[":mobile_danshou"] = "一名其他角色的結束階段開始時，若X：為0，你摸一張牌；不等於0，你可棄置X張牌並對其造成1點傷害（X為其本回合內使用的目標包含你的牌的數量）",
	["@mobile_danshou_ask"] = "你可以棄置與其手牌數相同的牌數對其造成1點傷害。<br/> <b>操作提示</b>: 選擇若干張牌→點擊確定<br/>",
	["@mobile_danshou"] = "膽守",
}

--[[
xin_fuhuanghou:'手殺伏皇后',
xinzhuikong:'惴恐',
xinzhuikong_info:'每輪限一次，其他角色的回合開始時，若其體力值不小於你，你可與其拼點。若你贏，其本回合無法使用牌指定除其以外的角色為目標；若你沒贏，你獲得其拼點的牌，然後其視為對你使用一張【殺】。',
xinqiuyuan:'求援',
xinqiuyuan_info:'當你成為【殺】的目標時，你可以令另一名其他角色交給你一張除【殺】以外的基本牌，否則其也成為此【殺】的目標。',
]]--

sgs.Sanguosha:addSkills(skills)

