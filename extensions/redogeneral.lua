module("extensions.redogeneral", package.seeall)
extension = sgs.Package("redogeneral")
extension_wind = sgs.Package("redowind", sgs.Package_GeneralPack)

sgs.LoadTranslationTable{
	["redogeneral"] = "OL武將改版",
	["redowind"] = "風包改版",
}
--風包部分

--黃忠
local skills = sgs.SkillList()

ol_huangzhong = sgs.General(extension_wind, "ol_huangzhong", "shu2", "4", true)
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

ol_liegong = sgs.CreateTriggerSkill{
	name = "ol_liegong",
	events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)

		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() and use.from:hasSkill(self:objectName()) and use.card:isKindOf("Slash") then
				local index, up = 1, 0
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for _, p in sgs.qlist(use.to) do
					if not player:isAlive() then break end
					local invoke,jink,dama = false, false, false
					if p:getHandcardNum() <= player:getHandcardNum() then
						invoke = true
						jink = true
					end
					if p:getHp() >= player:getHp() then
						invoke = true
						dama = true
					end
					local _data = sgs.QVariant()
					_data:setValue(p)
					if invoke and room:askForSkillInvoke(player, self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							if jink then
								local msg = sgs.LogMessage()
								msg.type = "#Liegong1"
								msg.from = player
								msg.to:append(p)
								msg.arg = self:objectName()
								msg.arg2 = use.card:objectName()
								msg.card_str = use.card:toString()
								room:sendLog(msg)

								jink_table[index] = 0
							end
							if dama then
								up = up + 1
							end
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
					index = index+1
				end
				if up > 0 then
					room:addPlayerMark(player, "ol_liegong_Play", up)
					room:setCardFlag(use.card, "ol_liegong_Play")
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.by_user and not damage.chain and not damage.transfer and damage.card:hasFlag("ol_liegong_Play") then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#Liegong2"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("ol_liegong_Play") then
				room:setCardFlag(use.card, "-ol_liegong_Play")
				room:setPlayerMark(player, "ol_liegong_Play", 0)
			end
		end
		return false
	end
}

ol_liegongTargetMod = sgs.CreateTargetModSkill{
	name = "#ol_liegongTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("ol_liegong") then
			return math.max(card:getNumber() - player:getAttackRange(), 0)
		end
	end,
}
ol_huangzhong:addSkill(ol_liegong)
ol_huangzhong:addSkill(ol_liegongTargetMod)
extension_wind:insertRelatedSkills("ol_liegong","#ol_liegongTargetMod")
sgs.LoadTranslationTable{
	["ol_huangzhong"] = "OL黃忠",
	["&ol_huangzhong"] = "黃忠",
	["#ol_huangzhong"] = "百步穿楊",
	["ol_liegong"] = "烈弓",
	[":ol_liegong"] = "你使用【殺】無距離限制，當你使用【殺】指定目標後，你可以根據下列條件執行效果：1.其手牌數小於等於你的手牌數，此【殺】不能被「閃」響應；2.其體力值大於等於你的體力值，此【殺】傷害+1",
	["#Liegong1"] = "%from 的技能 “<font color=\"yellow\"><b> %arg </b></font>”被觸發，%to 無法響應此 %card ",
	["#Liegong2"] = "%from 的技能 “<font color=\"yellow\"><b>烈弓</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--界魏延
ol_weiyan = sgs.General(extension_wind, "ol_weiyan", "shu2", "4", true)
--狂骨
ol_kuanggu = sgs.CreateTriggerSkill{
	name = "ol_kuanggu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.PreDamageDone},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if (event == sgs.PreDamageDone) and damage.from and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() then
			local weiyan = damage.from
			weiyan:setTag("invokeol_kuanggu", sgs.QVariant((weiyan:distanceTo(damage.to) <= 1)))
		elseif (event == sgs.Damage) and player:hasSkill(self:objectName()) and player:isAlive() then
			local invoke = player:getTag("invokeol_kuanggu"):toBool()
			player:setTag("invokeol_kuanggu", sgs.QVariant(false))
			if invoke then
				if player:getGeneralName() == "weiyan_po" then
					room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
				else
					room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
				end
				for i = 1, damage.damage, 1 do
					if player:isWounded() then
						local choices = {"kuanggu2", "kuanggu1"}
						local choice = room:askForChoice(player , "ol_kuanggu", table.concat(choices, "+"))
						if choice == "kuanggu2" then
							local recover = sgs.RecoverStruct()
							recover.who = player
							recover.recover = 1
							room:recover(player, recover)
						else
							room:drawCards(player, 1, "ol_kuanggu")
						end
					else
						room:drawCards(player, 1, "ol_kuanggu")
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
--奇謀
qimouCard = sgs.CreateSkillCard{
	name = "qimouCard",
	target_fixed = true,
	on_use = function(self, room, source)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:doSuperLightbox("ol_weiyan","qimou")
			local lose_num = {}
			for i = 1, source:getHp() do
				table.insert(lose_num, tostring(i))
			end
			local choice = room:askForChoice(source, "qimou", table.concat(lose_num, "+"))
			room:removePlayerMark(source, "@qimou")
			room:loseHp(source, tonumber(choice))
			room:addPlayerMark(source, "@qimou-Clear", tonumber(choice))
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
qimouVS = sgs.CreateZeroCardViewAsSkill{
	name = "qimou",
	view_as = function()
		return qimouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@qimou") >= 1 and player:getHp() > 1
	end
}
qimou = sgs.CreateTriggerSkill{
	name = "qimou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@qimou",
	view_as_skill = qimouVS,
	on_trigger = function()
	end
}

qimouDistance = sgs.CreateDistanceSkill{
	name = "#qimouDistance",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return  - from:getMark("@qimou-Clear")
		else
			return 0
		end
	end  
}
qimouTargetMod = sgs.CreateTargetModSkill{
	name = "#qimouTargetMod",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("qimou") then
			return player:getMark("@qimou-Clear")
		else
			return 0
		end
	end,
}
ol_weiyan:addSkill(ol_kuanggu)
ol_weiyan:addSkill(qimou)
ol_weiyan:addSkill(qimouDistance)
ol_weiyan:addSkill(qimouTargetMod)
extension_wind:insertRelatedSkills("qimou","#qimouDistance")
extension_wind:insertRelatedSkills("qimou","#qimouTargetMod")

sgs.LoadTranslationTable{
    ["ol_weiyan"] = "OL魏延",
    ["&ol_weiyan"] = "魏延",
	["#ol_weiyan"] = "子午奇謀",
	["qimou"] = "奇謀",
	[":qimou"] = "限定技，出牌階段，你可以失去任意點體力，若如此做，你與其他角色的距離減少X，且你可以多出X張殺(X為你本回合失去的體力數)",
	["qimou-lost"] = "選擇失去的體力量",
	["ol_kuanggu"] = "狂骨",
	[":ol_kuanggu"] = "鎖定技，每當你對距離1以內的一名角色造成1點傷害後，你選擇一項：1.回復1點體力，2.摸一張牌。",
	["kuanggu2"] = "回復1點體力",
	["kuanggu1"] = "摸一張牌",
}
--界徐晃
ol_xuhuang = sgs.General(extension_wind, "ol_xuhuang", "wei2", 4, true)

ol_duanliang = sgs.CreateOneCardViewAsSkill{
	name = "ol_duanliang",
	filter_pattern = "BasicCard,EquipCard|black",
	response_or_use = true,
	view_as = function(self, card)
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(card)
		return shortage
	end
}
ol_duanliang_buff = sgs.CreateTargetModSkill{
	name = "#ol_duanliang",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("ol_duanliang") then
			return 100
		end
		return 0
	end
}

ol_duanliang_Ban = sgs.CreateProhibitSkill{
	name = "#ol_duanliang_Ban" ,
	frequency = sgs.Skill_Compulsory ,
	is_prohibited = function(self, from, to, card)
		if (to:getHandcardNum() < from:getHandcardNum()) and card:isKindOf("SupplyShortage") and from:distanceTo(to) > 1 and from:hasSkill("ol_duanliang")
		--排除技能
		and (not (from:getMark("used_Play") == 0 and from:hasSkill("wanglie")))
		and from:getMark("chenglve" .. card:getSuitString() .. "-Clear") == 0
		and from:getMark("jueyan_horse-Clear") == 0
		and card:getSkillName() ~= "shenduan_po"
		and card:getSkillName() ~= "shenduan"
		and (not from:hasSkill("shenen"))
		and (not from:hasSkill("dg_longxian"))
		and (not from:hasSkill("qicai"))
		and (not from:hasSkill("nosqicai")) then
			return true
		end
	end
}

ol_xuhuang:addSkill(ol_duanliang)
ol_xuhuang:addSkill(ol_duanliang_buff)
ol_xuhuang:addSkill(ol_duanliang_Ban)
extension_wind:insertRelatedSkills("ol_duanliang", "#ol_duanliang")
extension_wind:insertRelatedSkills("ol_duanliang", "#ol_duanliang_Ban")

jiezi = sgs.CreateTriggerSkill{
	name = "jiezi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseSkipping},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Draw then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				room:broadcastSkillInvoke(self:objectName(), n)
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					p:drawCards(1, self:objectName())
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
ol_xuhuang:addSkill(jiezi)

sgs.LoadTranslationTable{
    ["ol_xuhuang"] = "OL徐晃",
    ["&ol_xuhuang"] = "徐晃",
	["#ol_xuhuang"] = "",
["ol_duanliang"] = "斷糧",
[":ol_duanliang"] = "你可以將一張黑色的基本牌或裝備牌當【兵糧寸斷】使用；你對手牌數大於等於你的角色使用【兵糧寸斷】無距離限制。",
["$ol_duanliang1"] = "人是鐵，飯是鋼。",
["$ol_duanliang2"] = "截其源，斷其糧，賊可擒也。",
["jiezi"] = "截輜",
[":jiezi"] = "鎖定技，當一名角色跳過摸牌階段後，你摸一張牌。",
	["$jiezi1"] = "",
	["$jiezi2"] = "",
	["~ol_xuhuang"] = "一顿不吃饿得慌。",
}

--曹仁
ol_caoren = sgs.General(extension_wind, "ol_caoren", "wei2", "4", true)
--據守
ol_jushou = sgs.CreateTriggerSkill{
	name = "ol_jushou" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Finish then return false end
		if room:askForSkillInvoke(player, "ol_jushou", data) then
			room:notifySkillInvoked(player, "ol_jushou")
			room:broadcastSkillInvoke(self:objectName())
			player:turnOver()
			player:drawCards(4)
			local card = room:askForCard(player,".|.|.|hand!", "@jushou", data, sgs.Card_MethodNone)
			if card then
				if card:isKindOf("EquipCard") then
					local use = sgs.CardUseStruct()
					use.card = card
					use.from = player
					use.to:append(player)
					room:useCard(use)
--					local self_weapon = player:getWeapon()
--					local self_dh = player:getDefensiveHorse()
--					local self_oh = player:getOffensiveHorse()
--					local self_armor = player:getArmor()
--					if (not self_weapon) and card:isKindOf("Weapon") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					elseif (not self_dh) and card:isKindOf("DefensiveHorse") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					elseif (not self_oh) and card:isKindOf("OffensiveHorse") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					elseif (not self_armor) and card:isKindOf("Armor") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					else
--						room:throwCard(card, player, player)
--					end
				else
					room:throwCard(card, player, player)
				end
			end
		end
		return false
	end
}
--解圍
ol_jieweiCard = sgs.CreateSkillCard{
	name = "ol_jiewei",
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
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@ol_jiewei-to".. card:objectName())
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
ol_jieweiVS = sgs.CreateOneCardViewAsSkill{
	name = "ol_jiewei",
	view_filter = function(self, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "nullification" then return to_select:isEquipped() end
		return true
	end,
	view_as = function(self, first)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "nullification" then
			local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
			ncard:addSubcard(first)
			ncard:setSkillName(self:objectName())
			return ncard
		else
			local card = ol_jieweiCard:clone()
			card:addSubcard(first)
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "nullification" or pattern == "@ol_jiewei"
	end,
	enabled_at_nullification = function(self, player)
		return player:hasEquip()
	end
}
ol_jiewei = sgs.CreateTriggerSkill{
	name = "ol_jiewei",
	view_as_skill = ol_jieweiVS,
	events = {sgs.TurnedOver},
	on_trigger = function(self, event, player, data, room)
		if player:faceUp() and room:askForUseCard(player, "@ol_jiewei", "@ol_jiewei", -1, sgs.Card_MethodNone) then end
	end
}
ol_caoren:addSkill(ol_jushou)
ol_caoren:addSkill(ol_jiewei)

sgs.LoadTranslationTable{
	["ol_caoren"] = "風曹仁",
	["&ol_caoren"] = "曹仁",
	["#ol_caoren"] = "神勇禦敵",
	["ol_jiewei"] = "解圍",
	["@jushou"] = "請棄置一張手牌",
	["ol_jushou"] = "據守",
	[":ol_jiewei"] = "你可以將裝備區裡的牌當【無懈可擊】使用；當你從背面翻至正面時，你可以棄置一張牌，然後移動場上的一張牌。",
	[":ol_jushou"] = "結束階段，你可以翻面並摸四張牌，然後棄置一張手牌，若以此法棄置的是裝備牌，則你改為使用之。",
	["@ol_jushou"]="請棄置一張牌，若以此法棄置的是裝備牌，則你改為使用之",
	["@ol_jiewei"] = "你可以棄置一張牌，然後移動場上的一張牌。",
	["~ol_jiewei"] = "選擇一張牌→選擇一名角色→點擊確定",
	["@ol_jiewei-to"] = "請選擇移動【%src】的目標角色",
}
--SP曹仁
bug_caoren = sgs.General(extension_wind,"bug_caoren","wei2","4",true)
--偽潰
weikuiCard = sgs.CreateSkillCard{
	name = "weikui", 
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end, 
	on_use = function(self, room, source, targets)
		room:loseHp(source)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local bug = sgs.IntList()
			for _, card in sgs.qlist(targets[1]:getHandcards()) do
				if not card:isKindOf("Jink") then
					bug:append(card:getEffectiveId())
				end
			end
			local id = room:doGongxin(source, targets[1], bug, self:objectName())
			if bug:length() == targets[1]:getHandcardNum() then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, source:objectName(), nil, self:objectName(), nil)
				if id ~= -1 then
					room:throwCard(sgs.Sanguosha:getCard(id), reason, targets[1], source)
				else
					room:throwCard(targets[1]:getRandomHandCard(), reason, targets[1], source)
				end
			else
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("_"..self:objectName())
				if sgs.Slash_IsAvailable(source) and source:canSlash(targets[1], nil, false) and not source:isProhibited(targets[1], slash) then
					local players = sgs.SPlayerList()
					players:append(targets[1])
					room:useCard(sgs.CardUseStruct(slash, source, players))
					room:setPlayerFlag(targets[1], "weikui_fix")	--yun
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
weikui = sgs.CreateZeroCardViewAsSkill{
	name = "weikui", 
	view_as = function(self, cards)
		local card = weikuiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#weikui") and player:getHp() > 0
	end
}
weikuiDistance = sgs.CreateDistanceSkill{
	name = "#weikuiDistance",
	correct_func = function(self, from, to)
		if from:hasSkill("weikui") and to:hasFlag("weikui_fix") then
			return -99
		else
			return 0
		end
	end  
}
--厲戰
lizhanCard = sgs.CreateSkillCard{
	name = "lizhan",
	filter = function(self, targets, to_select, erzhang)
		return #targets < 99 and to_select:isWounded()
	end,
	on_effect = function(self, effect)
		effect.to:drawCards(1)		
	end
}
lizhanVS = sgs.CreateZeroCardViewAsSkill{
	name = "lizhan",
	response_pattern = "@@lizhan",
	view_as = function()
		return lizhanCard:clone()
	end
}
lizhan = sgs.CreatePhaseChangeSkill{
	name = "lizhan",
	view_as_skill = lizhanVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local invoke = false
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:isWounded() then
				invoke = true
			end
		end
		if player:getPhase() == sgs.Player_Finish and invoke then
			room:askForUseCard(player, "@@lizhan", "@lizhan-card")
		end
		return false
	end
}

bug_caoren:addSkill(lizhan)
bug_caoren:addSkill(weikui)
bug_caoren:addSkill(weikuiDistance)

extension_wind:insertRelatedSkills("weikui","#weikuiDistance")

sgs.LoadTranslationTable{
	["bug_caoren"] = "SP曹仁",
	["&bug_caoren"] = "曹仁",
	["#bug_caoren"] = "",
	["lizhan"] = "勵戰",
	["~lizhan"] = "選擇任意名已受傷的角色 -> 點擊確定",
	[":lizhan"] = "結束階段，你可以然後令任意名已受傷的角色摸一張牌",
	["weikui"] = "偽潰",
	[":weikui"] = "出牌階段限一次，你可以失去一點體力，然後展示一名角色的所有手牌，若其中有「閃」，視為你對其使用了一張【殺】，且你本回合與其的距離視為1；否則你棄置其中一張牌",
	["@lizhan-card"] = "你可以令任意名已受傷的角色摸一張牌",
}

--新龐德
fire_pangde = sgs.General(extension_wind, "fire_pangde", "qun", "4", true)
--鞬出——当你使用【杀】指定一名角色为目标后，你可以弃置其一张牌，若以此法弃置的牌为装备牌，此【杀】不可被【闪】响应，若不为装备牌，该角色获得此【杀】。
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
jianchu = sgs.CreateTriggerSkill{
	name = "jianchu",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:isKindOf("Slash") then
			local index = 1
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			for _, p in sgs.qlist(use.to) do
				if not player:isAlive() then break end
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:canDiscard(p, "he") and room:askForSkillInvoke(player, self:objectName(), _data) then
					room:addPlayerMark(player, "jianchu-Clear")
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local id = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(id), p, player)
						if not sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
							jink_table[index] = 0
						else
							local ids = sgs.IntList()
							if use.card:isVirtualCard() then
								ids = use.card:getSubcards()
							else
								ids:append(use.card:getEffectiveId())
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
									p:obtainCard(use.card)
								end
							end
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
				index = index+1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		end
		return false
	end
}

jianchutm = sgs.CreateTargetModSkill{
	name = "#jianchutm",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:getMark("jianchu-Clear") > 0 then
			return 1
		end
	end,
}

fire_pangde:addSkill("mashu")
fire_pangde:addSkill(jianchu)
fire_pangde:addSkill(jianchutm)

sgs.LoadTranslationTable{
	["fire_pangde"] = "界龐德",
	["&fire_pangde"] = "龐德",
	[":fire_pangde"] = "",
	["jianchu"] = "鞬出",
	["$jianchu1"] = "我要杀你们个片甲不留！",
	["$jianchu2"] = "你，可敢挡我？",
	[":jianchu"] = "當你使用【殺】指定一名角色為目標後，你可以棄置其一張牌，若此牌：不為基本牌，此【殺】不可被【閃】響應，且你此階段可以多使用一張【殺】；為基本牌，該角色獲得此【殺】。",
}

--界夏侯淵
ol_xiahouyuan = sgs.General(extension_wind, "ol_xiahouyuan", "wei2", 4, true)
ol_shensuCard = sgs.CreateSkillCard{
	name = "ol_shensu",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
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
		if targets_list:length() > 0 then
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				room:useCard(sgs.CardUseStruct(slash, source, targets_list))
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
ol_shensuVS = sgs.CreateViewAsSkill{
	name = "ol_shensu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "2") then
			return #selected == 0 and to_select:isKindOf("EquipCard") and not sgs.Self:isJilei(to_select)
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") or string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "3") then
			return #cards == 0 and ol_shensuCard:clone() or nil
		else
			if #cards ~= 1 then
				return nil
			end
			local card = ol_shensuCard:clone()
			for _, cd in ipairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@ol_shensu")
	end
}
ol_shensu = sgs.CreateTriggerSkill{
	name = "ol_shensu",
	events = {sgs.EventPhaseChanging},
	view_as_skill = ol_shensuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge)
			and not player:isSkipped(sgs.Player_Draw) then
			if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, "@@ol_shensu1", "@shensu1", 1) then
				player:skip(sgs.Player_Judge)
				player:skip(sgs.Player_Draw)
			end
		elseif sgs.Slash_IsAvailable(player) and change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
			if player:canDiscard(player, "he") and room:askForUseCard(player, "@@ol_shensu2", "@shensu2", 2, sgs.Card_MethodDiscard) then
				player:skip(sgs.Player_Play)
			end
		elseif change.to == sgs.Player_Discard and not player:isSkipped(sgs.Player_Discard) then
			if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, "@@ol_shensu3", "@shensu3", 3) then
				player:skip(sgs.Player_Discard)
				player:turnOver()
			end
		end
		return false
	end
}

ol_shensuTargetMod = sgs.CreateTargetModSkill{
	name = "#ol_shensuTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "ol_shensu" then
			return 1000
		end
	end,
}

--設變
shebianCard = sgs.CreateSkillCard{
	name = "shebian",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getEquips():length() > 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if not targets[1]:hasEquip() and targets[1]:getJudgingArea():length() == 0 then return end
			local card_id = room:askForCardChosen(source, targets[1], "e", self:objectName())
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
					if not source:isProhibited(p, card) then
						tos:append(p)
					end
				end
			end
			local tag = sgs.QVariant()
			tag:setValue(targets[1])
			room:setTag("QiaobianTarget", tag)
			--local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to" .. card:objectName())
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@shebian-to"..card:objectName())
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
shebianVS = sgs.CreateZeroCardViewAsSkill{
	name = "shebian",
	view_as = function(self, first)
		local card = shebianCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@shebian"
	end,
}
shebian = sgs.CreateTriggerSkill{
	name = "shebian",
	view_as_skill = shebianVS,
	events = {sgs.TurnedOver},
	on_trigger = function(self, event, player, data, room)
		if room:askForUseCard(player, "@shebian", "@shebian", -1, sgs.Card_MethodNone) then end
	end
}

ol_xiahouyuan:addSkill(ol_shensu)
ol_xiahouyuan:addSkill(ol_shensuTargetMod)
ol_xiahouyuan:addSkill(shebian)
extension_wind:insertRelatedSkills("ol_shensu", "#ol_shensuTargetMod")

sgs.LoadTranslationTable{
	["ol_xiahouyuan"] = "界夏侯淵",
	["&ol_xiahouyuan"] = "夏侯淵",
	["#ol_xiahouyuan"] = "疾行的獵豹",
	["illustrator:ol_xiahouyuan"] = "",
	["ol_shensu"] = "神速",
	[":ol_shensu"] = "你可以：跳過判定階段和摸牌階段；棄置一張裝備牌並跳過出牌階段；跳過棄牌階段並翻面。若如此做，視為使用【殺】（無距離限制）。",
	["$ol_shensu1"] = "吾善於千里襲人！",
	["$ol_shensu2"] = "取汝首級猶如探囊取物！",
	["~ol_xiahouyuan"] = "竟然比我還…快……",
	["~ol_shensu1"] = "選擇一名角色→點擊確定",
	["~ol_shensu2"] = "選擇一張裝備牌→選擇一名角色→點擊確定",
	["~ol_shensu3"] = "選擇一名角色→點擊確定",
	["@shensu3"] = "你可以跳過棄牌階段並翻面發動“神速”",
	["shebian"] = "設變",
	["@shebian"] = "你可以移動場上的一張裝備牌",
	[":shebian"] = "當你翻面時，你可以移動場上的一張裝備牌",
	["~shebian"] = "選擇一張牌→選擇一名角色→點擊確定",
	["@shebian-to"] = "請選擇移動【%src】的目標角色",
}

--小喬
ol_xiaoqiao = sgs.General(extension_wind, "ol_xiaoqiao", "wu2", 3, false)

--[[
hongyan_po_move = sgs.CreateTriggerSkill{
	name = "#hongyan_po_move",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive then
			local can_invoke = false
			for _, id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
--]]

hongyanMax = sgs.CreateMaxCardsSkill{
	name = "#hongyan_poMax",
	extra_func = function(self, target)
		if target:hasSkill("hongyan") then
			local has_heart_equip = false
			for _,card in sgs.qlist(target:getEquips()) do
				if card:getSuit() == sgs.Card_Heart then
					has_heart_equip = true
				end
			end
			if has_heart_equip then
				return target:getMaxHp() - target:getHp()
			end
		end
	end
}

ol_xiaoqiao:addSkill("hongyan")
ol_xiaoqiao:addSkill(hongyanMax)
--ol_xiaoqiao:addSkill(hongyan_po_move)
--extension_wind:insertRelatedSkills("hongyan_po", "#hongyan_po_move")

ol_tianxiangCard = sgs.CreateSkillCard{
	name = "ol_tianxiang",
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local damage = source:getTag("olTianxiangDamage"):toDamage()	--yun
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 and damage.from then
			local choices = {"tianxiang1"}
			if targets[1]:getHp() > 0 then
				table.insert(choices, "tianxiang2")
			end
			local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
			if choice == "tianxiang1" then
				--room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
				room:damage(sgs.DamageStruct(self:objectName(), damage.from, targets[1]))
				if targets[1]:isAlive() then
					targets[1]:drawCards(math.min(targets[1]:getLostHp(), 5), "tianxiang")
				end
			else
				room:loseHp(targets[1])
				if targets[1]:isAlive() then
					room:obtainCard(targets[1], self)
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
ol_tianxiangVS = sgs.CreateOneCardViewAsSkill{
	name = "ol_tianxiang",
	view_filter = function(self, selected)
		return selected:getSuit() == sgs.Card_Heart and not sgs.Self:isJilei(selected)
	end,
	view_as = function(self, card)
		local tianxiangCard = ol_tianxiangCard:clone()
		tianxiangCard:addSubcard(card)
		return tianxiangCard
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@ol_tianxiang"
	end
}
ol_tianxiang = sgs.CreateTriggerSkill{
	name = "ol_tianxiang",
	events = {sgs.DamageInflicted},
	view_as_skill = ol_tianxiangVS,
	on_trigger = function(self, event, player, data, room)
		if player:canDiscard(player, "h") then
			player:setTag("olTianxiangDamage", data)	--yun
			return room:askForUseCard(player, "@@ol_tianxiang", "@ol_tianxiang", -1, sgs.Card_MethodDiscard)
		end
		return false
	end
}

ol_xiaoqiao:addSkill(ol_tianxiang)

--飄零 piaoling

piaoling = sgs.CreateTriggerSkill{
	name = "piaoling",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.who = player
					judge.reason = self:objectName()
					judge.good = true
					room:judge(judge)
					if judge:isGood() then
						--以下是為了ai所使用的代碼
						local c = judge.card:getEffectiveId()
						if sgs.Sanguosha:getEngineCard(c):getSuit() == sgs.Card_Heart then
							room:setPlayerFlag(player,"piaoling_heart")
						elseif sgs.Sanguosha:getEngineCard(c):getSuit() == sgs.Card_Spade and sgs.Sanguosha:getEngineCard(c):getNumber() >= 2 and sgs.Sanguosha:getEngineCard(c):getNumber() <= 9 then
							room:setPlayerFlag(player,"piaoling_canlightning")
						end

						local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "piaoling", "@piaoling-give", true, true)
						if target then
							room:notifySkillInvoked(player, self:objectName())
							room:obtainCard(target, judge.card)
							if target:objectName() == player:objectName() then
								room:askForDiscard(player, self:objectName(), 1, 1, false, true)
							end
						else
							reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
							move = sgs.CardsMoveStruct(judge.card, nil, sgs.Player_DrawPile, reason)
							room:moveCardsAtomic(move, true)
						end

						if player:hasFlag("piaoling_heart") then
							room:setPlayerFlag(player,"piaoling_heart")
						elseif player:hasFlag("piaoling_canlightning") then
							room:setPlayerFlag(player,"piaoling_canlightning")
						end
					end
				end
			end
		end
	end,
}

ol_xiaoqiao:addSkill(piaoling)

sgs.LoadTranslationTable{
	["ol_xiaoqiao"] = "小喬",
	["#ol_xiaoqiao"] = "矯情之花",
	["illustrator:ol_xiaoqiao"] = "Town",
	--["hongyan_po"] = "紅顏",
	--[":hongyan_po"] = "鎖定技。妳的黑桃牌視為紅桃牌；當妳於回合外失去紅桃牌時，妳摸ㄧ張牌。",
	["ol_tianxiang"] = "天香",
	[":ol_tianxiang"] = "當你受到傷害時，你可以棄置一張紅桃牌並防止此傷害並選擇一名其他角色，你選擇一項：1.來源對其造成1點傷害，其摸X張牌；2.其失去1點體力，獲得你以此法棄置的牌。（X為其已損失的體力值且至多為5）",
	["$ol_tianxiang1"] = "替我擋著~",
	["$ol_tianxiang2"] = "接著哦~",
	["~ol_xiaoqiao"] = "公瑾…我先走一步……",
	["@ol_tianxiang"] = "請選擇“天香”的目標",
	["~ol_tianxiang"] = "選擇一張<font color=\"red\">♥</font>牌→選擇一名其他角色→點擊確定",
	["tianxiang1"] = "其摸X張牌",
	["tianxiang2"] = "其失去1點體力，獲得你以此法棄置的牌。",

	["piaoling"] = "飄零",
	[":piaoling"] = "結束階段，妳可判定，若為♥妳選擇一項：1.將此牌交給一名角色，若為妳則棄置一張牌；2.將此牌置於牌堆頂。",
	["@piaoling-give"] = "將此牌交給一名角色，否則妳將此牌置於牌堆頂。",
}

--新神趙雲
new_godzhaoyun = sgs.General(extension_wind,"new_godzhaoyun","god","2",true)
--絕境

--[[]
new_juejing = sgs.CreateTriggerSkill{
	name = "new_juejing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() > 0 then
				if player:hasFlag("pre_dying") then
					room:broadcastSkillInvoke("new_juejing",1)
					player:drawCards(1)
					room:setPlayerFlag(player, "-pre_dying")
				end
			elseif player:getHp() <= 0 then
				if not player:hasFlag("pre_dying") then
					room:broadcastSkillInvoke("new_juejing",2)
					player:drawCards(1)
					room:setPlayerFlag(player, "pre_dying")
				end
			end
		end
	end,
}
]]--
new_juejing = sgs.CreateTriggerSkill{
	name = "new_juejing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying, sgs.QuitDying},
	on_trigger = function(self, event, player, data, room)
		room:broadcastSkillInvoke(self:objectName())
		room:sendCompulsoryTriggerLog(player, self:objectName())
		player:drawCards(1, self:objectName())
		return false
	end
}

new_juejingMaxCard = sgs.CreateMaxCardsSkill{
	name = "#new_juejingCard", 
	extra_func = function(self, target)
		if target:hasSkill("new_juejing") then
			return 2
		end
	end
}

--龍魂
new_longhunBuff = sgs.CreateTriggerSkill{
	name = "new_longhunBuff",
	global = true,
	events = {sgs.PreHpRecover, sgs.ConfirmDamage, sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:getSkillName() == "new_longhunBuff" then
				local log = sgs.LogMessage()
				log.type = "$new_longhunREC"
				log.from = splayer
				room:sendLog(log)
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "new_longhunBuff" then
				local log = sgs.LogMessage()
				log.type = "$new_longhunDMG"
				log.from = splayer
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		else
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				--local response = data:toCardResponse()
				--if response.m_isUse then
				--	card = response.m_card
				--end
				card = data:toCardResponse().m_card	
			end
			if card and card:isBlack() and card:getSkillName() == "new_longhunBuff" then
				local current = room:getCurrent()
				if current:isNude() then return false end
				room:doAnimate(1, splayer:objectName(), current:objectName())
				local id = room:askForCardChosen(splayer, current, "he", "new_longhun", false, sgs.Card_MethodDiscard)
				room:throwCard(id, current, splayer)
			end
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("new_longhunBuff") then skills:append(new_longhunBuff) end 

new_longhun = sgs.CreateViewAsSkill{
	name = "new_longhun",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if (#selected > 1) or to_select:hasFlag("using") then return false end
		if #selected > 0 then
			return to_select:getSuit() == selected[1]:getSuit()
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() or (to_select:getSuit() == sgs.Card_Heart) then
				return true
			elseif sgs.Slash_IsAvailable(sgs.Self) and (to_select:getSuit() == sgs.Card_Diamond) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Club
			elseif pattern == "nullification" then
				return to_select:getSuit() == sgs.Card_Spade
			elseif string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= 1 and #cards ~= 2 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			if #cards == 1 then
				new_card:setSkillName(self:objectName())
			else
				new_card:setSkillName("new_longhunBuff")
			end
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
		return player:isWounded() or sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
				or (pattern == "jink")
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
				or (pattern == "nullification")
	end,
	enabled_at_nullification = function(self, player)
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
	end
}

new_godzhaoyun:addSkill(new_juejing)
new_godzhaoyun:addSkill(new_juejingMaxCard)
new_godzhaoyun:addSkill(new_longhun)
extension_wind:insertRelatedSkills("new_juejing","#new_juejingCard")

sgs.LoadTranslationTable{
	["new_godzhaoyun"]="新神趙雲",
	["&new_godzhaoyun"] = "神趙雲",
	["#new_godzhaoyun"] = "神威如龍",
	["new_longhun"] = "龍魂",
	["new_longhunBuff"] = "龍魂",
	[":new_longhun"] = "你可以將至多兩張同花色的牌按照以下規則使用或打出：紅桃當【桃】；方塊當火【殺】；梅花當【閃】；黑桃當【無懈可擊】。若你以此法使用了兩張紅色牌，則此牌的回復值或傷害值 +1。若你以此法使用了兩張黑色牌，則你棄置當前回合角色一張牌。",
	["new_juejing"] = "絕境",
	[":new_juejing"] = "鎖定技，你的手牌上限+2；當你進入或脫離瀕死狀態時，你摸一張牌。",
	["$new_longhunREC"] = "%from 發動“龍魂”使用了兩張紅色牌，此【桃】的回復值+1",
	["$new_longhunDMG"] = "%from 發動“龍魂”使用了兩張紅色牌，此【殺】的傷害值+1",
	["$new_juejing1"] = "置于死地，方能后生！",
	["$new_juejing2"] = "背水一战，不胜便死！",
	["$new_longhun1"] = "常山赵子龙在此！",
	["$new_longhun2"] = "能屈能伸，才是大丈夫！",
}

--神關羽buff

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

wushenBuff = sgs.CreateTriggerSkill{
	name = "wushenBuff",
	events = {sgs.TargetSpecified} ,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:getSuit() == sgs.Card_Heart and player:hasSkill("wushen") then 
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
						local _data = sgs.QVariant()
						_data:setValue(p)
						--if player:askForSkillInvoke(self:objectName(), _data) then
							room:notifySkillInvoked(player, "wushenBuff")
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
						--end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
	end
}

wushenBuffTM = sgs.CreateTargetModSkill{
	name = "#wushenBuffTM" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("wushen") and card:getSuit() == sgs.Card_Heart then
			return 1000
		end
		return 0
	end,
	residue_func = function(self, from, card)
		if from:hasSkill("wushen") and card:getSuit() == sgs.Card_Heart then
			return 1000
		end
		return 0
	end,
}

if not sgs.Sanguosha:getSkill("wushenBuff") then skills:append(wushenBuff) end 
if not sgs.Sanguosha:getSkill("#wushenBuffTM") then skills:append(wushenBuffTM) end 

sgs.LoadTranslationTable{
	["wushenBuff"] = "武神",
}

--新神曹操
ol_shencaocao = sgs.General(extension_wind, "ol_shencaocao", "god", 3)

ol_guixin = sgs.CreateMasochismSkill{
	name = "ol_guixin",
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local n = player:getMark("GuixinTimes")
		player:setMark("LuaGuixinTimes", 0)
		local data = sgs.QVariant()
		data:setValue(damage)
		for i = 0, damage.damage - 1, 1 do
			player:addMark("GuixinTimes")
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("shencaocao",self:objectName())
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				player:setFlags("GuixinUsing")
				local choices = {"ol_guixin:h", "ol_guixin:e", "ol_guixin:j"}
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+") )
				ChoiceLog(player, choice)

				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					local loot_cards

					if choice == "ol_guixin:j" then loot_cards = sgs.QList2Table(p:getCards("j")) end
					if choice == "ol_guixin:h" then loot_cards = sgs.QList2Table(p:getCards("h")) end
					if choice == "ol_guixin:e" then loot_cards = sgs.QList2Table(p:getCards("e")) end

					if #loot_cards == 0 then loot_cards = sgs.QList2Table(p:getCards("h")) end
					if #loot_cards == 0 then loot_cards = sgs.QList2Table(p:getCards("e")) end
					if #loot_cards == 0 then loot_cards = sgs.QList2Table(p:getCards("j")) end

					if #loot_cards > 0 then
						room:obtainCard(player, loot_cards[math.random(1, #loot_cards)], false)
					end

				end
				player:turnOver()
				player:setFlags("-GuixinUsing")
			else
				break
			end
		end
		player:setMark("ol_guixinTimes", n)
	end
}

ol_shencaocao:addSkill(ol_guixin)
ol_shencaocao:addSkill("feiying")

sgs.LoadTranslationTable{
	["ol_shencaocao"]="OL神曹操",
	["&ol_shencaocao"] = "神曹操",
	--["#ol_shencaocao"] = "神威如龍",

	["ol_guixin"] = "歸心",
	[":ol_guixin"] = "當你受到1點傷害後，你可以獲得所有其他角色各你選擇的有牌區域里的隨機一張牌，然後翻面。",
	["$ol_guixin1"] = "掃清六合，席捲八荒！",
	["$ol_guixin2"] = "民之歸吾，如水之就下！",
	["~ol_shencaocao"] = "神龜雖壽，猶有盡時···",
	["ol_guixin:h"] = "手牌",
	["ol_guixin:e"] = "裝備區",
	["ol_guixin:j"] = "判定區",

}

--界祖茂
ol_zumao = sgs.General(extension, "ol_zumao", "wu2", 4, true)

ol_zumao:addSkill("yinbing")
--絕地
ol_juedi = sgs.CreateTriggerSkill{
	name = "ol_juedi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start and not player:getPile("yinbing"):isEmpty() then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getHp() <= player:getHp() then
					targets:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ol_juedi", false, true)
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				if target:objectName() == player:objectName() then
					player:clearOnePrivatePile("yinbing")
					if player:getHandcardNum() < player:getMaxHp() then
						player:drawCards(player:getMaxHp() - player:getHandcardNum())
					end		
				else
					local dummy = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
					local x = player:getPile("yinbing"):length()
					for _,c in sgs.qlist(player:getPile("yinbing")) do
						dummy:addSubcard(c)
					end
					room:obtainCard(target, dummy)
					dummy:deleteLater()
					room:recover(target, sgs.RecoverStruct(player))
					target:drawCards(x)	
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
ol_zumao:addSkill(ol_juedi)

sgs.LoadTranslationTable{
["ol_zumao"] = "界祖茂",
["&ol_zumao"] = "祖茂",
["#ol_zumao"] = "碧血染赤幘",
["illustrator:ol_zumao"] = "",
["ol_juedi"] = "絕地",
["@ol_juedi"] = "你可以發動“絕地”<br/> <b>操作提示</b>: 選擇一名角色（若選擇的角色為你，執行選項1，不為你，執行選項2）→點擊確定<br/>",
[":ol_juedi"] = "鎖定技，準備階段開始時，你選擇一項：1．將所有“幘”置入棄牌堆，然後將手牌補至體力上限；2．將所有“幘”交給體力值不大於你的一名其他角色，若如此做，其回复1點體力，摸等量的牌。",
["$ol_juedi1"] = "困獸之鬥，以詮忠義！",
["$ol_juedi2"] = "提起武器，最後一搏！",
["~ol_zumao"] = "孫將軍，已經安全了吧。",
}

--李典
ol_lidian = sgs.General(extension_star, "ol_lidian", "wei", 3, true, sgs.GetConfig("EnableHidden", true))--his xunxun is very important!
ol_xunxun = sgs.CreatePhaseChangeSkill{
	name = "ol_xunxun",
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
ol_lidian:addSkill(ol_xunxun)
ol_lidian:addSkill("wangxi")

sgs.LoadTranslationTable{
["ol_lidian"] = "李典",
["#ol_lidian"] = "功在青州",
["cv:ol_lidian"] = "黑冰",
["illustrator:ol_lidian"] = "zero",
["ol_xunxun"] = "恂恂",
[":ol_xunxun"] = "摸牌階段開始時，你可以觀看牌堆頂四張牌，將其中兩張牌置於牌堆頂，其餘兩張牌置於牌堆底。",
["$ol_xunxun1"] = "大將之範，當有恂恂之風。",
["$ol_xunxun2"] = "矜嚴重禮，進退恂恂。",
["$wangxi_ol_lidian1"] = "典豈可因私憾而忘公義？",
["$wangxi_ol_lidian2"] = "義忘私隙，端國正己。",
["~ol_lidian"] = "隙仇俱忘，怎奈……",
}


--新周倉
ol_zhoucang = sgs.General(extension, "ol_zhoucang", "shu2", 4, true)
--忠勇
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

ol_zhongyong = sgs.CreateTriggerSkill{
	name = "ol_zhongyong",
	events = {sgs.SlashMissed, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)	
		if event == sgs.SlashMissed then
			room:addPlayerMark(player, self:objectName()..data:toSlashEffect().jink:getEffectiveId())
		else
			local use = data:toCardUse()
			local friends, targets = sgs.SPlayerList(), sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not use.to:contains(player) then
					friends:append(p)
				end
				if player:inMyAttackRange(p) then
					targets:append(p)
				end
			end
			for _,p in sgs.qlist(use.to) do
				friends:removeOne(p)
			end
			if use.card and use.card:isKindOf("Slash") then
				local ids, slash = sgs.IntList(), sgs.IntList()
				for _, id in sgs.list(use.card:getSubcards()) do
					if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
						slash:append(id)
						ids:append(id)
					end
				end
				for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
					local id = tonumber(string.sub(mark, 13, string.len(mark)))
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable and room:getCardPlace(id) ~= sgs.Player_DiscardPile then continue end
					ids:append(id)
					room:setPlayerMark(player, mark, 0)
				end
				end
				if not friends:isEmpty() then
					room:fillAG(ids, player)
					local id = room:askForAG(player, ids, true, self:objectName())
					local help = false
					if id ~= -1 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						skill(self, room, player, false)
						local friend = room:askForPlayerChosen(player, friends, self:objectName(), "@ol_zhongyong", false, true)
						if friend then
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								room:broadcastSkillInvoke(self:objectName(), 1)
								for _, i in sgs.list(slash) do
									if sgs.Sanguosha:getCard(i):isRed() then help = true end
									ids:removeOne(i)
								end
								if slash:contains(id) then
									dummy:addSubcards(slash)
								else
									help = false
									for _, i in sgs.list(ids) do
										if sgs.Sanguosha:getCard(i):isRed() then help = true end
									end
									dummy:addSubcards(ids)
								end
								room:obtainCard(friend, dummy)
								room:removePlayerMark(player, self:objectName().."engine")
							end
						end
						if not targets:isEmpty() and help then
							room:setPlayerFlag(friend, self:objectName())
							if room:askForUseSlashTo(friend, targets, self:objectName(), false, false, false) then
								room:broadcastSkillInvoke(self:objectName(), 1)
							end
							room:setPlayerFlag(friend, "-"..self:objectName())
						end
					end
					room:clearAG(player)
				end
			end
		end
		return false
	end
}
ol_zhoucang:addSkill(ol_zhongyong)

sgs.LoadTranslationTable{
["ol_zhoucang"] = "OL周倉",
["&ol_zhoucang"] = "周倉",
["#ol_zhoucang"] = "披肝瀝膽",
["illustrator:ol_zhoucang"] = "",
["ol_zhongyong"] = "忠勇",
[":ol_zhongyong"] = "當你使用的【殺】結算完畢後，你可以將此【殺】或目標角色使用的【閃】交給其以外的一名其他角色，若其中有紅色牌，其可以對你攻擊範圍內的角色使用【殺】。",
["$ol_zhongyong1"] = "為將軍提刀攜馬，萬死不辭！",
["$ol_zhongyong2"] = "驅刀飛血，直取寇首！",
["~ol_zhoucang"] = "為將軍操刀牽馬，此生無憾...",
["@ol_zhongyong"] = "將此【殺】或目標角色使用的【閃】交給一名角色",
}

--OL李典

--新靈雎
ol_lingju = sgs.General(extension, "ol_lingju", "qun2", 3, false)

ol_jieyuan = sgs.CreateTriggerSkill{
	name = "ol_jieyuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			local card_limit = player:getMark("@fenxin3") > 0 and player:canDiscard(player, "he") or player:canDiscard(player, "h")
			if damage.to and damage.to:isAlive() and (damage.to:getHp() >= player:getHp() or player:getMark("@fenxin1") > 0)
			and damage.to:objectName() ~= player:objectName() and card_limit
			and room:askForCard(player, player:getMark("@fenxin3") > 0 and ".." or ".black", "@jieyuan-increase:"..damage.to:objectName(), data, self:objectName())
			then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				local log = sgs.LogMessage()
				log.type = "#JieyuanIncrease"
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
		elseif event == sgs.DamageInflicted then
			local card_limit = player:getMark("@fenxin3") > 0 and player:canDiscard(player, "he") or player:canDiscard(player, "h")
			if damage.from and damage.from:isAlive() and (damage.from:getHp() >= player:getHp() or player:getMark("@fenxin2") > 0)
			and damage.from:objectName() ~= player:objectName() and card_limit
			and room:askForCard(player, player:getMark("@fenxin3") > 0 and ".." or ".red", "@jieyuan-decrease:"..damage.from:objectName(), data, self:objectName())
			then
				room:broadcastSkillInvoke(self:objectName(), 2)
				
				local log = sgs.LogMessage()
				log.type = "#JieyuanDecrease"
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
		end
		return false
	end
}

ol_lingju:addSkill(ol_jieyuan)

ol_fenxin = sgs.CreateTriggerSkill{
	name = "ol_fenxin", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Death}, 
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if death.who:objectName() ~= p:objectName() then
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					if death.who:getRole() == "loyalist" then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:setPlayerMark(p, "@fenxin2", 1)
					elseif death.who:getRole() == "rebel" then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:setPlayerMark(p, "@fenxin1", 1)
					elseif death.who:getRole() == "renegade" then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:setPlayerMark(p, "@fenxin3", 1)
					end
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
		return false
	end, 
}
ol_lingju:addSkill(ol_fenxin)

sgs.LoadTranslationTable{
	["ol_lingju"] = "界靈雎",
	["&ol_lingju"] = "靈雎",
	["#ol_lingju"] = "情随梦逝",
	["illustrator:ol_lingju"] = "木美人",
	["ol_fenxin"] = "焚心",
	[":ol_fenxin"] = "鎖定技，一名其他角色死亡後，若其身分為：忠臣，你發動「竭緣」減少傷害無體力值限制；反賊，你發動「竭緣」增加傷害無體力值限制；內奸，將「竭緣」中的黑色手牌和紅色手牌改為一張牌。",
	["$ol_fenxin1"] = "杀人，诛心！",
	["$ol_fenxin2"] = "主上，这是最后的机会！",
	["~ol_lingju"] = "主上……对不起……",
	["ol_jieyuan"] = "竭緣",
	[":ol_jieyuan"] = "當你對其他角色造成傷害時，若其體力值不小於你，則你可以棄置一張黑色手牌，然後此傷害+1；當你受到其他角色造成的傷害時，若其體力值不小於你，則你可以棄置一張紅色手牌，然後此傷害-1。",
	["@jieyuan-increase"] = "你可以棄置一張黑色手牌令 %src 受到的傷害+1",
	["@jieyuan-decrease"] = "你可以棄置一張紅色手牌令 %src 造成的傷害-1",
	["#JieyuanIncrease"] = "%from 發動了“<font color=\"yellow\"><b>竭緣</b></font>”，傷害點數從 %arg 點增加至 %arg2 點" ,
	["#JieyuanDecrease"] = "%from 發動了“<font color=\"yellow\"><b>竭緣</b></font>”，傷害點數從 %arg 點減少至 %arg2 點" ,
}

--SP關銀屏
ol_guanyinping = sgs.General(extension, "ol_guanyinping", "shu", "3", false)
--血祭——出牌阶段限一次，你可以弃置一张红色牌，然后选择至多X名角色，横置这些角色并对其中一名角色造成1点火焰伤害。（X为你已损失的体力值数且至少为1）


ol_xuejiCard = sgs.CreateSkillCard{
	name = "ol_xueji",
	filter = function(self, targets, to_select)
		--return #targets < math.max(sgs.Self:getLostHp(), 1) and not to_select:isChained()
		return #targets < math.max(sgs.Self:getLostHp(), 1)
	end,
	about_to_use = function(self, room, use)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, use.from:objectName(), "", self:objectName(), "")
		room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason, true)
		skill(self, room, use.from, true)
		for _, p in sgs.qlist(use.to) do
			room:doAnimate(1, use.from:objectName(), p:objectName())
		end
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			for _, p in sgs.qlist(use.to) do
				if not p:isChained() then
					room:setPlayerProperty(p, "chained", sgs.QVariant(true))
				end
			end
			room:doAnimate(1, use.from:objectName(), use.to:first():objectName())
			room:damage(sgs.DamageStruct(self:objectName(), use.from, use.to:first(), 1, sgs.DamageStruct_Fire))
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
ol_xueji = sgs.CreateOneCardViewAsSkill{
	name = "ol_xueji",
	filter_pattern = ".|red!",
	view_as = function(self, card)
		local first = ol_xuejiCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#ol_xueji")
	end
}
--虎啸——锁定技，当你造成火焰伤害后，受到此伤害的角色各摸一张牌，本回合你对这些角色使用牌没有次数限制。
ol_huxiao = sgs.CreateTriggerSkill{
	name = "ol_huxiao" ,
	events = {sgs.Damage, sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.nature == sgs.DamageStruct_Fire then
				room:sendCompulsoryTriggerLog(player, "ol_huxiao")
				damage.to:drawCards(1, "ol_huxiao")

				if damage.to:getMark("ol_huxiao-Clear") == 0 then
					if damage.to:objectName() == player:objectName() then
						room:setPlayerMark(damage.to, "ol_huxiao_target-Clear",1)
						room:setPlayerMark(damage.to, "ol_huxiao-Clear",1)
					else
						local assignee_list = player:property("extra_slash_specific_assignee"):toString():split("+")
						table.insert(assignee_list, damage.to:objectName())
						room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
						room:setPlayerMark(damage.to, "ol_huxiao-Clear",1)
					end
				end
			end
		end	
	end
}

ol_huxiaoTM = sgs.CreateTargetModSkill{
	name = "#ol_huxiaoTM",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Analeptic",
	residue_func = function(self, player)
		if player:hasSkill("ol_huxiao") and player:getMark("ol_huxiao_target-Clear") > 0 then
			return 1000
		else
			return 0
		end
	end,
}
--武继——觉醒技，结束阶段，若你于此回合内造成过3点或更多伤害，你加1点体力上限并回复1点体力，失去“虎啸”，然后从场上、牌堆或弃牌堆中获得【青龙偃月刀】
ol_wuji = sgs.CreatePhaseChangeSkill{
	name = "ol_wuji",
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
			room:broadcastSkillInvoke("ol_wuji")
			room:setPlayerMark(player, self:objectName(), 1)
			room:doSuperLightbox("ol_guanyinping","ol_wuji")	
			room:recover(player, sgs.RecoverStruct(player))
			room:detachSkillFromPlayer(player, "ol_huxiao")
			
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				local weapon = p:getWeapon()
				if weapon and weapon:objectName() == "blade" then					
					player:obtainCard(weapon)
				end
			end
			local ids = room:getDrawPile()
			local ids_2 = room:getDiscardPile()
			for i2 = 1,150,1 do
				local id
				if (i2) <= ids:length() then
					id = ids:at(i2-1)
				else
					id = ids_2:at(i2-1-ids:length())
				end
				local card = sgs.Sanguosha:getCard(id)
				if card:objectName() == "blade" then
					player:obtainCard(card)
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish 
		and target:getMark(self:objectName()) == 0 and (target:getMark("damage_record-Clear") >= 3  or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}
ol_guanyinping:addSkill(ol_xueji)
ol_guanyinping:addSkill(ol_huxiao)
ol_guanyinping:addSkill(ol_wuji)
ol_guanyinping:addSkill(ol_huxiaoTM)

extension:insertRelatedSkills("ol_huxiao","#ol_huxiaoTM")

sgs.LoadTranslationTable{
    ["ol_guanyinping"] = "OL關銀屏",
    ["&ol_guanyinping"] = "關銀屏",
	["ol_xueji"] = "血祭",
	[":ol_xueji"] = "出牌階段限一次，你可以棄置一張紅色牌，然後選擇至多X名角色，橫置這些角色並對其中一名角色造成1點火焰傷害。（X為你已損失的體力值數且至少為1)",
	["$ol_xueji1"] = "这炽热的鲜血，父亲，你可感觉得到？",
	["$ol_xueji2"] = "取你首级，祭先父之灵！",
	["ol_huxiao"] = "虎嘯",
	[":ol_huxiao"] = "鎖定技，當你造成火焰傷害後，受到此傷害的角色各摸一張牌，本回合你對這些角色使用牌沒有次數限制。",
	["$ol_huxiao1"] = "大仇未报，还不能放弃！",
	["$ol_huxiao2"] = "虎父无犬女！",
	["ol_wuji"] = "武繼",
	[":ol_wuji"] = "覺醒技，結束階段，若你於此回合內造成過3點或更多傷害，你加1點體力上限並回复1點體力，失去“虎嘯”",
	["@ol_xueji-damage"] = "你要對哪一名角色造成1點火焰傷害？",
	["#WujiWake"] = "%from 於此回合內造成過 %arg 點傷害，觸發“%arg2”覺醒",
	["$ol_wuji1"] = "我感受到了……父亲的力量！",
	["$ol_wuji2"] = "我也要像父亲那样坚强！",
}

--新曹真
ol_caozhen = sgs.General(extension,"ol_caozhen","wei2","4",true)
--司敵：其他角色出牌階段開始時，你可以棄置一張與你裝備區裡的牌顏色相同的非基本牌，然後該角色於此階段內不能使用或打出與此牌顏色相同的牌。此階段結束時，若其此階段沒有使用【殺】，視為你對其使用了【殺】。

function GetColor(card)
	if card:isRed() then return "red" elseif card:isBlack() then return "black" end
end

ol_sidi = sgs.CreateTriggerSkill{
	name = "ol_sidi",
	global = true,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and p:objectName() ~= player:objectName() and p:hasEquip() then
				local _data = sgs.QVariant()
				_data:setValue(player)
				local extra = ""
				for _,card in sgs.qlist(p:getCards("e")) do
					if extra ~= "" then extra = extra.."," end
					extra = extra..GetColor(card)
				end
				local card = room:askForCard(p, "^BasicCard|"..extra, "@ol_sidi:"..player:objectName(), _data, self:objectName())
				if card then
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						room:setPlayerMark(player, "@qianxi_"..GetColor(card), 1)
						room:setPlayerMark(player, "ol_sidi_"..GetColor(card), 1)
						room:setPlayerCardLimitation(player, "use, response", ".|"..GetColor(card), true)
						player:setFlags(self:objectName())
						room:removePlayerMark(p, self:objectName().."engine")
					end
				end
			end
			if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
				if player:hasFlag(self:objectName()) then
					if player:getMark("used_slash-Clear") == 0 and p:canSlash(player, nil, false) then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("_ol_sidi")
						room:useCard(sgs.CardUseStruct(slash, p, player))
					end
					if player:getMark("ol_sidi_red") > 0 then
						room:setPlayerMark(player,"ol_sidi_red",0)
						room:setPlayerMark(player,"@qianxi_red",0)
					elseif player:getMark("ol_sidi_black") > 0 then
						room:setPlayerMark(player,"ol_sidi_black",0)
						room:setPlayerMark(player,"@qianxi_black",0)
					end
				end
			end
		end
		return false
	end
}

ol_caozhen:addSkill(ol_sidi)

sgs.LoadTranslationTable{
	["ol_caozhen"] = "新曹真",
	["&ol_caozhen"] = "曹真",
	["ol_sidi"] = "司敵",
	[":ol_sidi"] = "其他角色出牌階段開始時，你可以棄置一張非基本牌，然後該角色於此階段內不能使用或打出與此牌顏色相同的牌。此階段結束時，若其此階段沒有使用【殺】，視為你對其使用了【殺】。",
	["@ol_sidi_use"] = "你可以棄置一張與你裝備區裡的牌顏色相同的非基本牌，然後 %src 於此階段內不能使用或打出與此牌顏色相同的牌",
}

--陳群
ol_chenqun = sgs.General(extension,"ol_chenqun","wei2","3",true)
--品第：出牌階段，你可以棄置一張牌並選擇一名其他角色（不能棄置相同類型牌且不能指定相同的角色），然後令其執行一項：摸X張牌；棄置X張牌（ X為本回合此技能發動次數）。若其已受傷，你須橫置自身。
pindicard = sgs.CreateSkillCard{
	name = "pindicard", 
	target_fixed = false, 
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("pindi".."_Play") == 0 
	end, 
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setPlayerMark(source, "pindi"..card:getTypeId().."_Play",1)
		room:setPlayerMark(tiger, "pindi".."_Play",1)
		local n = source:usedTimes("#pindicard")
		local choices = {"pindi1", "pindi2"}
		local choice = room:askForChoice(source, "pindi", table.concat(choices, "+"))
		if choice == "pindi1" then
			room:drawCards(tiger, n, "pindi")
			--room:broadcastSkillInvoke("pindi",2)
		elseif choice == "pindi2" then
			--room:broadcastSkillInvoke("pindi",1)
			room:askForDiscard(tiger, "pindi", n, n, false, true)
		end
		if tiger:isWounded() and not source:isChained() then
			room:setPlayerProperty(source, "chained", sgs.QVariant(true))
		end
	end
}
pindi = sgs.CreateViewAsSkill{
	name = "pindi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return sgs.Self:getMark("pindi"..to_select:getTypeId().."_Play") == 0
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = pindicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
}

--法恩：當一名角色翻至正面或橫置後，你可以令其摸一張。
ol_faen = sgs.CreateTriggerSkill{
	name = "ol_faen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnedOver, sgs.ChainStateChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ChainStateChanged and player:isChained()) or (event == sgs.TurnedOver and player:faceUp()) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("ol_faen") then
					local _data = sgs.QVariant()
					_data:setValue(player)
					if room:askForSkillInvoke(p,self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						player:drawCards(1)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
} 

ol_chenqun:addSkill(pindi)
ol_chenqun:addSkill(ol_faen)

sgs.LoadTranslationTable{
	["ol_chenqun"] = "界陳群",
	["&ol_chenqun"] = "陳群",
	["pindi"] = "品第",
	[":pindi"] = "出牌階段，你可以棄置一張牌並選擇一名其他角色（不能棄置相同類型牌且不能指定相同的角色），然後令其執行一項：摸X張牌；棄置X張牌（X為本回合此技能發動次數）。若其已受傷，你須橫置自身。",
	["pindi1"] = "摸X張牌",
	["pindi2"] = "棄置X張牌（X為本回合此技能發動次數）",
	["ol_faen"] = "法恩",
	[":ol_faen"] = "當一名角色翻至正面或橫置後，你可以令其摸一張牌",
}


--馬良
ol_maliang = sgs.General(extension, "ol_maliang", "shu", "3", true, true)
--自書：鎖定技，你的回合外，你獲得的牌均會在當前回合結束後置入棄牌堆；你的回合內，當你不因此技能效果獲得牌時，額外摸一張牌。
zishu = sgs.CreateTriggerSkill{
	name = "zishu",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_NotActive then
					for _,id in sgs.qlist(move.card_ids) do
						if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
							room:addPlayerMark(player, self:objectName()..id)
						end
					end
				elseif player:getPhase() ~= sgs.Player_NotActive and move.reason.m_skillName ~= "zishu" and RIGHT(self, player) then
					for _,id in sgs.qlist(move.card_ids) do
						if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
							SendComLog(self, player, 1)
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								player:drawCards(1, self:objectName())
								room:removePlayerMark(player, self:objectName().."engine")
								break
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, card in sgs.list(p:getHandcards()) do
					if p:getMark(self:objectName()..card:getEffectiveId()) > 0 then
						dummy:addSubcard(card:getEffectiveId())
					end
				end
				if dummy:subcardsLength() > 0 then
					SendComLog(self, p, 2)
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, p:objectName(), self:objectName(), nil), p)
						room:removePlayerMark(p, self:objectName().."engine")
					end
					if player:getNextAlive():objectName() == p:objectName() then
						room:getThread():delay(2500)
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
--應援：當你於回合內使用的牌置入棄牌堆後，你可以將之交給一名其他角色（相同牌名的牌每回合限一次）。
yingyuan = sgs.CreateTriggerSkill{
	name = "yingyuan",
	--events = {sgs.CardsMoveOneTime, sgs.CardUsed},
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			
--			local invoke = false
--			for _,id in sgs.qlist(move.card_ids) do
--				if sgs.Sanguosha:getCard(id):hasFlag("yingyuan") then
--					invoke = true
--				end
--			end
			
			local is_nullification = false
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id) and sgs.Sanguosha:getCard(id):isKindOf("Nullification") then
					is_nullification = true
				end
			end
			
			local move_card_can_yingyuan = false
			for _,id in sgs.qlist(move.card_ids) do
				if player:getMark(self:objectName()..TrueName(sgs.Sanguosha:getCard(id)).."-Clear") == 0 then
					move_card_can_yingyuan = true
				end
			end

			--if move.from and move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE
			--and (move.from:objectName() == player:objectName() or invoke) and player:getPhase() ~= sgs.Player_NotActive then
			if move.from
			and ((move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile) or (is_nullification and move.to_place == sgs.Player_PlaceTable))
			--is_nullification and move.to_place == sgs.Player_PlaceTable為神殺處理無懈可擊的特殊狀況(move.to_place == 7)
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE
			and move.from:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_NotActive and move_card_can_yingyuan then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _,id in sgs.qlist(move.card_ids) do
					--if player:getMark(self:objectName()..TrueName(sgs.Sanguosha:getCard(id):getClassName()).."-Clear") == 0 then
					--if player:getMark(self:objectName()..TrueName(sgs.Sanguosha:getCard(id)).."-Clear") == 0 then
						dummy:addSubcard(id)
						--room:addPlayerMark(player, self:objectName()..TrueName(sgs.Sanguosha:getCard(id):getClassName()).."-Clear")
						room:addPlayerMark(player, self:objectName()..TrueName(sgs.Sanguosha:getCard(id)).."-Clear")
					--end
				end
				if dummy:subcardsLength() > 0 then
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yingyuan-invoke", true, true)
					if target then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							--target:obtainCard(dummy)
							room:obtainCard(target, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""), false)
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
--		else
--			local use = data:toCardUse()
--			if use.from and use.from:hasSkill(self:objectName()) and use.card and use.card:getClassName() == "Nullification" then
--				room:setCardFlag(use.card, "yingyuan")
--			end
		end
	end
}

ol_maliang:addSkill(zishu)
ol_maliang:addSkill(yingyuan)

sgs.LoadTranslationTable{
	["ol_maliang"] = "馬良--舊版",
	["&ol_maliang"] = "馬良",
	["#ol_maliang"] = "白眉智士",
	["illustrator:ol_maliang"] = "depp",
	["zishu"] = "自書",
	[":zishu"] = "鎖定技，當你於回合內不因「自書」而獲得牌後，你摸一張牌；鎖定技，其他角色的回合結束時，你將於此回合內獲得的手牌置入棄牌堆。",
	["$zishu1"] = "慢著，讓我來。",
	["$zishu2"] = "身外之物，不要也罷。",
	["yingyuan"] = "應援",
	["yingyuan-invoke"] = "你可以發動「應援」<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	[":yingyuan"] = "當你於回合內使用牌置入棄牌堆後，若之與你於此回合內以此法交給其他角色的牌名均不同，你可以將之交給一名角色。",
	["$yingyuan1"] = "接好嘞。",
	["$yingyuan2"] = "好牌只用一次怎麼夠？",
	["~ol_maliang"] = "我的使命完成了嗎……",
}

--自創靈雎
str_linggi = sgs.General(extension, "str_linggi", "qun", "3", false, true)
--竭緣:當你對其他角色造成傷害時，若其體力值大於等於你，則你可以棄置一張黑色手牌，然後此傷害+1；當你受到其他角色造成的傷害時，若其體力值大於等於你，則你可以棄置一張紅色手牌，然後此傷害-1。
str_jeiyuan = sgs.CreateTriggerSkill{
	name = "str_jeiyuan",
	events = {sgs.DamageInflicted,sgs.Damaged},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			--room:broadcastSkillInvoke(self:objectName())
			local s = room:findPlayerBySkillName(self:objectName())
			if damage.from:objectName() == s:objectName() then
				local card = nil
				if s:getMark("jeiyuan_upgrade") > 0 then
					card = room:askForCard(s,".|.|.|.","@str_jeiyuan_plus_change",sgs.QVariant(),sgs.CardDiscarded)
				else
					card = room:askForCard(s,".|black|.|hand","@str_jeiyuan_plus",sgs.QVariant(),sgs.CardDiscarded)
				end
				if card ~= nil then
					room:broadcastSkillInvoke("jieyuan",1)
					damage.damage = damage.damage + 1
					data:setValue(damage)
					if card:isKindOf("TrickCard") and s:getMark("jeiyuan_upgrade") > 1 then
						room:drawCards(s,1)
					end
				end
			elseif damage.to:objectName() == s:objectName() then
				local card = nil
				if s:getMark("jeiyuan_upgrade") > 0 then
					card = room:askForCard(s,".|.|.|.","@str_jeiyuan_minus_change",sgs.QVariant(),sgs.CardDiscarded)
				else
					card=room:askForCard(s,".|red|.|hand","@str_jeiyuan_minus",sgs.QVariant(),sgs.CardDiscarded)
				end
				if card ~= nil then
					room:broadcastSkillInvoke("jieyuan",2)
					damage.damage = damage.damage - 1
					data:setValue(damage)
					if card:isKindOf("TrickCard") and s:getMark("jeiyuan_upgrade") > 1 then
						room:drawCards(s,1)
					end
				end
			end
		end
	end,
	can_trigger=function()
		return true
	end
}
--焚心：鎖定技，一名其他角色死亡後，若其身份為：忠臣，你發動"竭緣"減少傷害無體力值限制；反賊，你發動"竭緣"增加傷害無體力值限制；內奸，你發動"竭緣"棄置牌無顏色限制且可棄置裝備牌。
str_fengxin = sgs.CreateTriggerSkill{
	name = "str_fengxin",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			if room:askForSkillInvoke(player, "str_fengxin", data) then
				for i = 1, damage.damage ,1 do
					if player:getMark("jeiyuan_upgrade") < 2 then
						local choice = room:askForChoice(player, self:objectName(), "fengxin_upgrade+fengxin_draw")
						if choice == "fengxin_upgrade" then
							room:broadcastSkillInvoke("fenxin")
							room:setPlayerMark(player,"jeiyuan_upgrade",player:getMark("jeiyuan_upgrade") + 1)
						elseif choice == "fengxin_draw" then
							room:broadcastSkillInvoke("fenxin")
							room:drawCards(player,1)
						end
					else
						room:broadcastSkillInvoke("fenxin")
						room:drawCards(player,1)
					end
				end
			end
			return false
		end
	end
}
str_linggi:addSkill(str_jeiyuan)
str_linggi:addSkill(str_fengxin)

sgs.LoadTranslationTable{
	["str_linggi"] = "亂世靈雎",
	["&str_linggi"] = "靈雎",
	["@str_jeiyuan_plus"] = "你可以棄置一張黑色手牌，然後此傷害+1",
	["@str_jeiyuan_minus"] = "你可以棄置一張紅色手牌，然後此傷害-1",
	["@str_jeiyuan_plus_change"] = "你可以棄置一張牌，然後此傷害+1",
	["@str_jeiyuan_minus_change"] = "你可以棄置一張牌，然後此傷害-1",
	["str_jeiyuan"] = "竭緣",
	["str_fengxin"] = "焚心",
	["fengxin_upgrade"] = "修改技能「竭緣",
	["fengxin_draw"] = "摸一張牌",
	[":str_jeiyuan"] = "當你對其他角色造成傷害時，則你可以棄置一張黑色手牌，然後此傷害+1；當你受到其他角色造成的傷害時，則你可以棄置一張紅色手牌，然後此傷害-1",
	[":str_fengxin"] = "當妳受到一點傷害時，你可以選擇：1.修改技能「竭緣」2.摸一張牌",
}

--朱治 男, 吳, 4 體力
ol_zhuzhi = sgs.General(extension,"ol_zhuzhi","wu","4",true)
--安國：出牌階段限一次，你可以選擇一名其他角色，若其手牌數為全場最少，其摸一張牌；體力值為全場最低，回復一點體力；裝備區內牌數為全場最少，隨機使用一張裝備牌。然後若該角色有未執行的效果且你滿足條件，你執行之。
ol_anguoCard = sgs.CreateSkillCard{
	name = "ol_anguoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self,room,source,targets)
		local tiger = targets[1]
		local player_card = {}
		local player_hp = {}
		local player_equip = {}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			table.insert(player_card, p:getHandcardNum())
			table.insert(player_hp, p:getHp())
			table.insert(player_equip, p:getEquips():length())
		end
		if tiger:getHandcardNum() == math.min(unpack(player_card)) then
			tiger:drawCards(1)
		elseif source:getHandcardNum() == math.min(unpack(player_card)) then
			source:drawCards(1)
		end
		if tiger:getHp() == math.min(unpack(player_hp)) then
			local theRecover = sgs.RecoverStruct()
			theRecover.recover = 1
			theRecover.who = source
			room:recover(tiger, theRecover)
		elseif source:getHp() == math.min(unpack(player_hp)) then
			local theRecover = sgs.RecoverStruct()
			theRecover.recover = 1
			theRecover.who = source
			room:recover(source, theRecover)
		end
		local t
		if tiger:getEquips():length() == math.min(unpack(player_equip)) then
			t = tiger
		elseif source:getEquips():length()== math.min(unpack(player_equip)) then
			t = source
		end
		if t ~= nil then
			local DPHeart = sgs.IntList()
			if room:getDrawPile():length() > 0 then
				for _, id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("EquipCard") then
						DPHeart:append(id)
					end
				end
			end
			if room:getDiscardPile():length() > 0 then
				for _, id in sgs.qlist(room:getDiscardPile()) do
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
				use.from = t
				room:useCard(use)
			end
		end
	end
}

ol_anguo = sgs.CreateViewAsSkill{
	name = "ol_anguo",
	n = 0,
	view_as = function(self,cards)
		return ol_anguoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#ol_anguoCard")
	end
}
ol_zhuzhi:addSkill(ol_anguo)

sgs.LoadTranslationTable{
	["ol_zhuzhi"] = "OL朱治",
	["&ol_zhuzhi"] = "朱治",
	["ol_anguo"] = "安國",
	[":ol_anguo"] = "出牌階段限一次，你可以選擇一名其他角色，若其手牌數為全場最少，其摸一張牌；體力值為全場最低，回復一點體力；裝備區內牌數為全場最少，隨機使用一張裝備牌。然後若該角色有未執行的效果且你滿足條件，你執行之。",
}


--朱桓
ol_zhuhuan = sgs.General(extension, "ol_zhuhuan", "wu", "4", true)
--奮勵
fenli = sgs.CreateTriggerSkill{
	name = "fenli",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		local hp, hand, equip = true, true, player:hasEquip()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHandcardNum() > player:getHandcardNum() then
				hp = false
			end
			if p:getHp() > player:getHp() then
				hand = false
			end
			if p:getEquips():length() > player:getEquips():length() then
				equip = false
			end
		end
		if not player:isSkipped(change.to) and ((hp and change.to == sgs.Player_Draw) or (hand and change.to == sgs.Player_Play) or (equip and change.to == sgs.Player_Discard)) and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				player:skip(change.to)
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}
--平寇
pingkouCard = sgs.CreateSkillCard{
	name = "pingkou",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark(self:objectName().."-Clear") and to_select:objectName() ~= sgs.Self:objectName()
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
pingkouVS = sgs.CreateZeroCardViewAsSkill{
	name = "pingkou",
	response_pattern = "@@pingkou",
	view_as = function(self, card)
		return pingkouCard:clone()
	end
}
pingkou = sgs.CreateTriggerSkill{
	name = "pingkou",
	view_as_skill = pingkouVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive and player:getMark(self:objectName().."-Clear") > 0 then
			room:askForUseCard(player, "@@pingkou", "@pingkou:"..tostring(player:getMark(self:objectName().."-Clear")), -1, sgs.Card_MethodUse)
		end
	end
}

ol_zhuhuan:addSkill(fenli)
ol_zhuhuan:addSkill(pingkou)

sgs.LoadTranslationTable{
    ["ol_zhuhuan"] = "界朱桓",
    ["&ol_zhuhuan"] = "朱桓",
	["fenli"] = "奮勵",
	[":fenli"] = "若你的手牌數為全場最多，你可以跳過摸牌階段；若你的體力值為全場最多，你可以跳過出牌階段；若你的裝備數為全場最多，你可以跳過棄牌階段",
	["fenlidiscard"] = "奮勵，跳過棄牌階段",
	["fenlidraw"] = "奮勵，跳過摸牌階段",
	["fenliplay"] = "奮勵，跳過出牌階段",
	["$fenli1"] = "以逸待劳，坐收渔利！",
	["$fenli2"] = "以主制客，占尽优势。",
	["pingkou"] = "平寇",
	[":pingkou"] = "回合結束時，你可以對至多X名其他角色各造成1點傷害（X為你本回合跳過的階段數）",
	["@pingkou"] = "你可以對至多 %src 名其他角色各造成1點傷害",
	["~pingkou"] = "選擇角色 -> 點擊「確定」",
	["$pingkou1"] = "对敌人仁慈就是对自己残忍！",
	["$pingkou2"] = "反守为攻，直捣黄龙。",
}

--孫魯育
third_rev_sunluyu = sgs.General(extension,"third_rev_sunluyu","wu","3",false)
--穆穆：出牌階段開始時，你可以選擇一項：1.棄置一名其他角色裝備區裡的一張牌；2.獲得一名角色裝備區裡的一張防具牌，若如此做，你本回合不能使用或打出【殺】。
mumu_third_revCard = sgs.CreateSkillCard{
	name = "mumu_third_rev",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:getEquips():isEmpty() and sgs.Self:canDiscard(to_select, "e")
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local id = room:askForCardChosen(effect.from, effect.to, "e", self:objectName(), false, sgs.Card_MethodDiscard)
			if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
				local choice = room:askForChoice(effect.from, self:objectName(), "discard+obtain")
				if choice == "obtain" then
					room:addPlayerMark(effect.from, "mumu_third_rev_obtain-Clear")
					room:obtainCard(effect.from, id)
				else
					room:throwCard(sgs.Sanguosha:getCard(id), effect.to, effect.from)
				end
			else
				room:throwCard(sgs.Sanguosha:getCard(id), effect.to, effect.from)
			end
		end
	end
}
mumu_third_revVS = sgs.CreateZeroCardViewAsSkill{
	name = "mumu_third_rev",
	view_as = function()
		return mumu_third_revCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@mumu_third_rev"
	end
}
mumu_third_rev = sgs.CreateTriggerSkill{
	name = "mumu_third_rev",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = mumu_third_revVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local invoke = false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:getEquips():isEmpty() then
				invoke = true
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and invoke and player:hasSkill(self:objectName()) then
			if room:askForUseCard(player, "@mumu_third_rev", "@mumu_third_rev") then
				if player:getMark("mumu_third_rev_obtain-Clear") > 0 then
					room:setPlayerCardLimitation(player, "use,response", "Slash", true)
				end
			end
		end
	end
}
--魅步：其他角色的出牌階段開始時，你可以棄置一張牌，令該角色於本回合內擁有“止息”。若你以此法棄置的牌不是【殺】或黑色錦囊牌，則本回合其與你距離視為1。
meibu_third_rev = sgs.CreateTriggerSkill{
	name = "meibu_third_rev",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:inMyAttackRange(p) then
					local card = room:askForCard(p, ".,Equip", "@meibu_third_rev:"..player:objectName(), sgs.QVariant(), sgs.CardDiscarded)
					if card then
						room:notifySkillInvoked(player, self:objectName())
						room:handleAcquireDetachSkills(player, "zhixi_third_rev", false)
						room:broadcastSkillInvoke("meibu_third_rev")
						if card:isKindOf("Slash") or (card:isBlack() and card:isKindOf("TrickCard")) then
			
						else
							room:setPlayerFlag(player, "mebu_from")
						end
					end
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:hasSkill("zhixi_third_rev") then
				room:detachSkillFromPlayer(player, "zhixi_third_rev")
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
meibu_third_revDistance = sgs.CreateDistanceSkill{
	name = "#meibu_third_revDistance",
	correct_func = function(self, from, to)
		if to:hasSkill("meibu_third_rev") and from:hasFlag("mebu_from") then
			return -99
		else
			return 0
		end
	end  
}

--止息：鎖定技，出牌階段你可至多使用X張牌，你使用了錦囊牌後不能再使用牌（X為你的體力值）。
zhixi_third_rev = sgs.CreateTriggerSkill{
	name = "zhixi_third_rev",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd, sgs.HpRecover},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
				local x = player:getHp()
				room:setPlayerMark(player, "zhixi_third_rev-Clear", x)
			elseif player:getPhase() == sgs.Player_Play and player:getMark("zhixi_third_rev_stop-Clear") ~= 0 then
				room:setPlayerCardLimitation(player, "use", ".", false)
			end
		elseif player:getPhase() == sgs.Player_Play and (event == sgs.CardUsed or event == sgs.CardResponded) and player:hasSkill(self:objectName()) then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and card:isKindOf("TrickCard") then
				room:setPlayerMark(player, "zhixi_third_rev-Clear", 0)
				room:setPlayerCardLimitation(player, "use", ".", false)
				room:addPlayerMark(player, "zhixi_third_rev_stop-Clear")
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and player:getMark("zhixi_third_rev-Clear") > 0 then
				room:removePlayerMark(player, "zhixi_third_rev-Clear")
				if player:getMark("zhixi_third_rev-Clear") == 0 then
					room:setPlayerCardLimitation(player, "use", ".", false)
					room:addPlayerMark(player, "zhixi_third_rev_stop-Clear")
				end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
			room:removePlayerCardLimitation(player, "use", ".")
		elseif event == sgs.HpRecover then
			local recover_struct = data:toRecover()
			if recover_struct and recover_struct.recover > 0 then
				room:addPlayerMark(player, "zhixi_third_rev-Clear", recover_struct.recover)
				room:removePlayerCardLimitation(player, "use", ".")
			end
		end
		return false
	end
}

third_rev_sunluyu:addSkill(mumu_third_rev)
third_rev_sunluyu:addSkill(meibu_third_rev)
third_rev_sunluyu:addSkill(meibu_third_revDistance)

if not sgs.Sanguosha:getSkill("zhixi_third_rev") then skills:append(zhixi_third_rev) end

extension:insertRelatedSkills("meibu_third_rev","#meibu_third_revDistance")

sgs.LoadTranslationTable{
	["third_rev_sunluyu"] = "OL孫魯育",
	["&third_rev_sunluyu"] = "孫魯育",
	["mumu_third_rev"] = "穆穆",
	[":mumu_third_rev"] = "出牌階段開始時，你可以選擇一項：1.棄置一名其他角色裝備區裡的一張牌；2.獲得一名角色裝備區裡的一張防具牌，若如此做，你本回合不能使用或打出【殺】。",
	["mumu_third_rev1"] = "棄置一名其他角色裝備區裡的一張牌",
	["mumu_third_rev2"] = "獲得一名角色裝備區裡的一張防具牌，若如此做，你本回合不能使用或打出【殺】。",
	["@mumu_third_rev"] = "你可以發動“穆穆”",
	["~mumu_third_rev"] = "選擇一名有裝備牌的角色→點擊確定",
	["meibu_third_rev"] = "魅步",
	[":meibu_third_rev"] = "其他角色的出牌階段開始時，若你在其攻擊範圍內，你可以棄置一張牌，令該角色於本回合內擁有“止息”。若你以此法棄置的牌不是【殺】或黑色錦囊牌，則本回合其與你距離視為1。",
	["zhixi_third_rev"] = "止息",
	[":zhixi_third_rev"] = "鎖定技，出牌階段你可至多使用X張牌，你使用了錦囊牌後不能再使用牌（X為你的體力值）。",
	["@meibu_third_rev"] = "你可以棄置一張牌，令 %src 於本回合內擁有“止息”",
}

--大喬小喬
sec_rev_daqiaoxiaoqiao = sgs.General(extension,"sec_rev_daqiaoxiaoqiao","wu","3",false)
--【星舞】棄牌階段開始時，你可將一張手牌置於武將牌上。若所有星舞牌的花色數大於2，你將三張花色均不相同的星舞牌置入棄牌堆，然後選擇一名其他角色，你棄置其裝備區裡的所有牌。若其為男/女性角色，你對其造成2/1點傷害。
--【落雁】鎖定技，若你有"星舞"牌，你視為擁有"天香"和"流離"。

xingwu_sec_revCard = sgs.CreateSkillCard{
	name = "xingwu_sec_rev",
	will_throw = false,
	handling_method = sgs.Card_MethodDiscard,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		if self:getSubcards():length() == 2 then
			source:turnOver()
			room:moveCardTo(self, nil, sgs.Player_DiscardPile, false)
		else
			room:moveCardTo(self, nil, sgs.Player_DiscardPile, false)
		end
		targets[1]:throwAllEquips()
		if targets[1]:isMale() then
			room:damage(sgs.DamageStruct("xingwu_sec_rev", source, targets[1], 2, sgs.DamageStruct_Normal))
		else
			room:damage(sgs.DamageStruct("xingwu_sec_rev", source, targets[1], 1, sgs.DamageStruct_Normal))
		end
	end,
}
xingwu_sec_revVS = sgs.CreateViewAsSkill{
	name = "xingwu_sec_rev", 
	n = 3,
	response_pattern = "@@xingwu_sec_rev",
	expand_pile = "dance_sec_rev",
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			if to_select:getSuit() ~= selected[1]:getSuit() and sgs.Self:getPile("dance_sec_rev"):contains(selected[1]:getId()) then
				return sgs.Self:getPile("dance_sec_rev"):contains(to_select:getId())
			end
			if not sgs.Self:getPile("dance_sec_rev"):contains(selected[1]:getId()) then
				return not sgs.Self:getPile("dance_sec_rev"):contains(to_select:getId())
			end
		elseif #selected == 2 then
			if to_select:getSuit() ~= selected[1]:getSuit() and to_select:getSuit() ~= selected[2]:getSuit() then
				return sgs.Self:getPile("dance_sec_rev"):contains(to_select:getId())
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if (#cards ~= 3 and #cards ~= 2) then return nil end
		local can_invoke = true
		for _, c in ipairs(cards) do
			if #cards == 2 and sgs.Self:getPile("dance_sec_rev"):contains(c:getId()) then
				can_invoke = false
			elseif #cards == 3 and not sgs.Self:getPile("dance_sec_rev"):contains(c:getId()) then
				can_invoke = false
			end
		end

		if can_invoke then
			local card = xingwu_sec_revCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
}
xingwu_sec_rev = sgs.CreateTriggerSkill{
	name = "xingwu_sec_rev",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	view_as_skill = xingwu_sec_revVS,  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then

				local card = room:askForCard(player,"..","@xingwu_sec_rev_put",data,self:objectName())
				if card then
					player:addToPile("dance_sec_rev", card)
					room:broadcastSkillInvoke("xingwu_sec_rev", math.random(1,2))
				end
				room:askForUseCard(player, "@@xingwu_sec_rev", "@xingwu_sec_rev-discard", -1, sgs.Card_MethodNone)
			end	
		end
	end,
}

sec_rev_daqiaoxiaoqiao:addSkill(xingwu_sec_rev)

luoyan_sec_rev = sgs.CreateTriggerSkill{
	name = "luoyan_sec_rev",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				room:handleAcquireDetachSkills(player, "-ol_tianxiang|-liuli", true)
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toString() == self:objectName() then
				if not player:getPile("dance_sec_rev"):isEmpty() then
					room:notifySkillInvoked(player, self:objectName())
					room:handleAcquireDetachSkills(player, "ol_tianxiang|liuli", true)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local move = data:toMoveOneTime()
				if move.to and move.to:objectName() == player:objectName() and move.to_place and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name and move.to_pile_name == "dance_sec_rev" then
					if player:getPile("dance_sec_rev"):length() == 1 then
						room:notifySkillInvoked(player, self:objectName())
						room:handleAcquireDetachSkills(player, "ol_tianxiang|liuli", true)
					end
				elseif move.from and move.from:objectName() == player:objectName()
				and move.from_places and move.from_places:contains(sgs.Player_PlaceSpecial)
				and move.from_pile_names and table.contains(move.from_pile_names, "dance_sec_rev") then
					if player:getPile("dance_sec_rev"):isEmpty() then
						room:handleAcquireDetachSkills(player, "-ol_tianxiang|-liuli", true)
					end
				end
			end
		end
	end
}
sec_rev_daqiaoxiaoqiao:addSkill(luoyan_sec_rev)

sgs.LoadTranslationTable{
	["sec_rev_daqiaoxiaoqiao"] = "OL大喬小喬",
	["&sec_rev_daqiaoxiaoqiao"] = "大喬小喬",
	["xingwu_sec_rev"] = "星舞",
	[":xingwu_sec_rev"] = "棄牌階段開始時，妳可將一張手牌置於武將牌上。若所有星舞牌的花色數大於2，妳將三張花色均不相同的星舞牌置入棄牌堆，然後選擇一名其他角色，妳棄置其裝備區裡的所有牌。若其為男/女性角色，妳對其造成2/1點傷害。",
	["@xingwu_sec_rev_put"] = "妳可將一張手牌置於武將牌上",
	["@xingwu_sec_rev-discard"] = "將三張花色均不相同的星舞牌置入棄牌堆，然後選擇一名其他角色",
	["~xingwu_sec_rev"] = "點擊「星舞」牌 -> 點選「確定」",	
	["dance_sec_rev"] = "星舞",
	["luoyan_sec_rev"] = "落雁",
	[":luoyan_sec_rev"] = "鎖定技，若有“舞”，你擁有“天香”和“流離”。",
	["~sec_rev_daqiaoxiaoqiao"] = "伯符、公瑾，請一定守護住我們的江東哦……",
	["dance_sec_rev"] = "舞",
}

--全琮
ol_quancong = sgs.General(extension, "ol_quancong", "wu2", 4)

yaoming = sgs.CreateTriggerSkill{
	name = "yaoming", 
	events = {sgs.Damage, sgs.Damaged}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHandcardNum() ~= player:getHandcardNum() then
				players:append(p)
			end
		end
		if not room:getCurrent():hasFlag(self:objectName()..player:objectName()) then
			local target = room:askForPlayerChosen(player, players, self:objectName(), "yaoming-invoke", true, true)
			if target then
				room:getCurrent():setFlags(self:objectName()..player:objectName())
				if target:getHandcardNum() > player:getHandcardNum() then
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local to_throw = room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(to_throw), target, player)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				elseif target:getHandcardNum() < player:getHandcardNum() then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						target:drawCards(1)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}
ol_quancong:addSkill(yaoming)

sgs.LoadTranslationTable{
["ol_quancong"] = "OL全琮",
["&ol_quancong"] = "全琮",
["#ol_quancong"] = "白馬王子",
["illustrator:ol_quancong"] = "東公子",
["yaoming"] = "邀名",
[":yaoming"] = "每名角色的回合限一次，當你造成或受到傷害後，你可以選擇一項：1.棄置一名手牌數大於你的角色一張手牌；2.令一名手牌數小於你的角色摸一張牌。",
["$yaoming1"] = "看我如何以無用之栗，換己所需，哈哈哈......",
["$yaoming2"] = "民不足食，何以養君。",
["~ol_quancong"] = "患難可共濟，生死不同等...",
["yaoming-invoke"] = "你可以發動“邀名”<br/> <b>操作提示</b>: 選擇一名手牌數與你不同的角色→點擊確定<br/><b提示</b>: 你可以棄置一名手牌數大於你的角色一張手牌，或是令一名手牌數小於你的角色摸一張牌。<br/>",
}

--曹休
ol_caoxiu = sgs.General(extension, "ol_caoxiu", "wei2", 4, true)

qianju = sgs.CreateDistanceSkill{
	name = "qianju", 
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return - from:getLostHp()
		end
	end
}

ol_caoxiu:addSkill(qianju)
qingxi = sgs.CreateTriggerSkill{
	name = "qingxi", 
	events = {sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if player:getWeapon() == nil then return false end
		local x = player:getWeapon():getRealCard():toWeapon():getRange()
		if damage.card and damage.card:isKindOf("Slash") and damage.by_user and not damage.chain and not damage.transfer and room:askForSkillInvoke(player, self:objectName(), data) then 
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				if room:askForDiscard(damage.to, self:objectName(), x, x, true, true) then
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:throwCard(player:getWeapon(), player, damage.to)
				else
					room:broadcastSkillInvoke(self:objectName(), 2)
					damage.damage = damage.damage+1
					data:setValue(damage)
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
ol_caoxiu:addSkill(qingxi)

sgs.LoadTranslationTable{
["ol_caoxiu"] = "OL曹休",
["&ol_caoxiu"] = "曹休",
["#ol_caoxiu"] = "諸神的黃昏",
["illustrator:ol_caoxiu"] = "諸神黃昏",
["qianju"] = "千駒",
[":qianju"] = "鎖定技，你與其他角色的距離-X。（X為你已損失的體力值）",
["qingxi"] = "傾襲",
[":qingxi"] = "當你使用【殺】對目標角色造成傷害時，若你的裝備區裡有武器牌，你可以令其選擇一項：1.棄置X張牌，然後棄置你的武器牌；2.傷害值+1。（X為此武器牌的攻擊範圍）",
["$qingxi1"] = "你本領再高，也鬥不過我的~",
["$qingxi2"] = "傾兵所有，襲敵不意！",
["~ol_caoxiu"] = "孤軍深入，犯了兵家大忌！",
}

--曹叡
ol_caorui = sgs.General(extension, "ol_caorui$", "wei2", 3)

ol_caorui:addSkill("huituo")

ol_mingjianCard = sgs.CreateSkillCard{
	name = "ol_mingjian", 
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end, 
	on_use = function(self, room, source, targets)
		room:obtainCard(targets[1], source:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:addPlayerMark(targets[1], "@ol_mingjian_flag")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
ol_mingjianVS = sgs.CreateZeroCardViewAsSkill{
	name = "ol_mingjian", 
	view_as = function(self, cards)
		return ol_mingjianCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and not player:hasUsed("#ol_mingjian")
	end
}

ol_mingjian = sgs.CreateTriggerSkill{
	name = "ol_mingjian",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = ol_mingjianVS,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish and player:getMark("@ol_mingjian_flag") > 0 then
			room:setPlayerMark(player, "@ol_mingjian_flag", 0)
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}

ol_mingjiantm = sgs.CreateTargetModSkill{
	name = "#ol_mingjiantm",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:getMark("@ol_mingjian_flag") > 0 then
			return 1
		end
	end,
}

ol_mingjianmc = sgs.CreateMaxCardsSkill{
	name = "#ol_mingjianmc", 
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if target:getMark("@ol_mingjian_flag") > 0 then
			return 1
		end
	end
}

ol_caorui:addSkill(ol_mingjian)
ol_caorui:addSkill("xingshuai")
ol_caorui:addSkill(ol_mingjiantm)
ol_caorui:addSkill(ol_mingjianmc)
extension:insertRelatedSkills("ol_mingjian","#ol_mingjiantm")
extension:insertRelatedSkills("ol_mingjian","#ol_mingjianmc")

sgs.LoadTranslationTable{
	["ol_caorui"] = "OL曹叡",
	["&ol_caorui"] = "曹叡",
	["#ol_caorui"] = "魏明皇",
	["illustrator:ol_caorui"] = "王立雄",
["ol_mingjian"] = "明鑑",
[":ol_mingjian"] = "出牌階段限一次，你可以將所有手牌交給一名角色，令其於其的下回合內使用【殺】的次數上限+1且手牌上限+1。 ",
["$ol_mingjian1"] = "以卿之才學，何愁此戰不勝？",
["$ol_mingjian2"] = "用人自當不疑，卿大可放心！",
["~ol_caorui"] = "愧為人主，何顏見父......",
}

--士燮
ol_shixie = sgs.General(extension, "ol_shixie", "qun2", 3)

function CDM(room, player, a, b)
	local x = math.min(player:getMark(a), player:getMark(b))
	room:removePlayerMark(player, a, x)
	room:removePlayerMark(player, b, x)
end
--[[
ol_biluan = sgs.CreatePhaseChangeSkill{
	name = "ol_biluan", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:distanceTo(player) == 1 then
				if player:getPhase() == sgs.Player_Draw and room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:addPlayerMark(player, "@biluan", getKingdoms(player))
						CDM(room, player, "@biluan", "@lixia")
						room:removePlayerMark(player, self:objectName().."engine")
						return true
					end
				end
				break
			end
		end
		return false
	end
}
]]--
ol_biluan = sgs.CreateTriggerSkill{
	name = "ol_biluan" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local  can_trigger = false
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:distanceTo(player) == 1 then
						can_trigger = true
						break
					end
				end	
				if	can_trigger then	
					if room:askForCard(player, ".|.|.|.", "@ol_biluan", data, self:objectName()) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							local n = math.min(room:alivePlayerCount(),4)
							room:addPlayerMark(player, "@biluan", n)
							CDM(room, player, "@biluan", "@lixia")

							msg.type = "#DistanceLog"
							msg.from = p
							msg.arg = tostring( p:getMark("@biluan") - p:getMark("@lixia") )
							room:sendLog(msg)

							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
		end
		return false
	end
}

ol_lixia = sgs.CreatePhaseChangeSkill{
	name = "ol_lixia", 
	global = true, 
	frequency = sgs.Skill_Compulsory, 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:objectName() ~= player:objectName() and not player:inMyAttackRange(p) then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						local choice = room:askForChoice(p, self:objectName(), "lixia1+lixia2")
						if choice == "lixia1" then
							room:broadcastSkillInvoke(self:objectName(), 2)
							p:drawCards(1, self:objectName())
						else
							room:broadcastSkillInvoke(self:objectName(), 1)
							--player:drawCards(1, self:objectName())
							player:drawCards(2, self:objectName())
						end
						room:addPlayerMark(p, "@lixia")
						CDM(room, p, "@biluan", "@lixia")

						local msg = sgs.LogMessage()

						msg.type = "#DistanceLog"
						msg.from = p
						msg.arg = tostring( p:getMark("@biluan") - p:getMark("@lixia") )
						room:sendLog(msg)

						room:removePlayerMark(p, self:objectName().."engine")
					end
				end
			end
		end
	end
}

ol_biluandistance = sgs.CreateDistanceSkill{
	name = "#ol_biluandistance", 
	correct_func = function(self, from, to)
		return to:getMark("@biluan") - to:getMark("@lixia")
	end
}

ol_shixie:addSkill(ol_biluan)
ol_shixie:addSkill(ol_lixia)
ol_shixie:addSkill(ol_biluandistance)

sgs.LoadTranslationTable{
["ol_shixie"] = "OL士燮",
["&ol_shixie"] = "士燮",
["#ol_shixie"] = "雄長百越",
["illustrator:ol_shixie"] = "銘zmy",
["ol_biluan"] = "避亂",
["#ol_biluandistance"] = "避亂",
--[":ol_biluan"] = "摸牌階段開始時，若有角色與你的距離為1，你可以放棄摸牌，若如此做，其他角色與你的距離+X。（X為勢力數）" ,
[":ol_biluan"] = "結束階段，若有其他角色計算與你的距離為1，則你可以棄置一張牌，令其他角色計算與你的距離+X（X為場上存活人數且最多為4）" ,
["@ol_biluan"] = "你可以棄置一張牌發動技能「避亂」",
["$ol_biluan1"] = "身處亂世，自保足矣~",
["$ol_biluan2"] = "避一時之亂，求長世安穩~",
["ol_lixia"] = "禮下",
--[":ol_lixia"] = "鎖定技，其他角色的結束階段開始時，若你不在其攻擊範圍內，你選擇一項：1.摸一張牌；2.其摸一張牌。若如此做，其他角色與你的距離-1。",
[":ol_lixia"] = "鎖定技，其他角色的結束階段，若你不在其攻擊範圍內，則你選擇一項：1.摸一張牌；2.令其摸兩張牌。選擇完成後，其他角色計算與你的距離-1。",
["$ol_lixia1"] = "將軍，真乃國之棟樑~",
["$ol_lixia2"] = "英雄可安身立命於交州之地~",
["lixia1"] = "你摸一張牌",
--["lixia2"] = "其摸一張牌",
["lixia2"] = "其摸兩張牌",
["#DistanceLog"] = " 其他角色計算與 %from 的距離額外增加 %arg ",
}

--于禁
super_yujin = sgs.General(extension, "super_yujin", "wei2", 4, true)
--鎮軍
zhenjun = sgs.CreatePhaseChangeSkill{
	name = "zhenjun",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHandcardNum() > math.max(p:getHp(), 0) then
				players:append(p)
			end
		end
		if player:getPhase() == sgs.Player_Start and not players:isEmpty() then
			local to = room:askForPlayerChosen(player, players, self:objectName(), "zhenjun-invoke", true, true)
			if to then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerFlag(to, "Fake_Move")
					local x = to:getHandcardNum() - math.max(to:getHp(), 0)
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
					for i = 0, dummy:subcardsLength() - 1, 1 do
						--room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), to, original_places:at(i), false)
						if not sgs.Sanguosha:getCard(card_ids:at(i)):isKindOf("EquipCard") then
							n = n + 1
						end
					end
					room:setPlayerFlag(to, "-Fake_Move")
--					if dummy:subcardsLength() > 0 then
--						room:throwCard(dummy, to, player)
--					end
					if n > 0 then
						local cards = room:askForExchange(player, self:objectName(), n, n, true, "@zhenjun", true)
						if cards then
							room:throwCard(cards, player, player)
						else
							--if n == 0 and not room:askForSkillInvoke(player, self:objectName()) then return false end
							to:drawCards(x, self:objectName())
						end
					end
					if n == 0 and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..x)) then
						to:drawCards(x, self:objectName())
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
super_yujin:addSkill(zhenjun)

sgs.LoadTranslationTable{
	["super_yujin"] = "OL于禁",
	["&super_yujin"] = "于禁",
	["#super_yujin"] = "臨危不懼",
	["illustrator:super_yujin"] = "",
	["zhenjun"] = "鎮軍",
	[":zhenjun"] = "準備階段開始時，你可以選擇一名手牌數大於體力值的角色，棄置其X張牌，然後選擇是否棄置其中非裝備牌數量的牌，若選擇否，其摸等量的牌。（X為其手牌數與體力值之差）",
	["zhenjun:draw"] = "你想發動“鎮軍”令對方摸 %src 張牌嗎?",
	["$zhenjun1"] = "",
	["$zhenjun2"] = "",
	["~super_yujin"] = "我…無顏面對丞相了……",
	["@zhenjun"] = "你可以棄置一定數量的牌。<br/> <b>操作提示</b>: 選擇若干張牌→點擊確定<br/>",
	["zhenjun-invoke"] = "你可以發動“鎮軍”<br/> <b>操作提示</b>: 選擇一名手牌數大於體力值的角色→點擊確定<br/>",
}

--界張寶
ol_zhangbao = sgs.General(extension, "ol_zhangbao", "qun2", 3, true, true)

ol_zhoufuCard = sgs.CreateSkillCard{
	name = "ol_zhoufu",
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getPile("incantation"):isEmpty()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			targets[1]:addToPile("incantation", self)
			--room:addPlayerMark(targets[1], "ol_yingbingput"..targets[1]:getPile("incantation"):first()..source:objectName())
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
ol_zhoufuVS = sgs.CreateOneCardViewAsSkill{
	name = "ol_zhoufu",
	filter_pattern = ".|.|.|hand",
	view_as = function(self, cards)
		local card = ol_zhoufuCard:clone()
		card:addSubcard(cards)
		return card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#ol_zhoufu")
	end
}
ol_zhoufu = sgs.CreateTriggerSkill{
	name = "ol_zhoufu",
	events = {sgs.StartJudge, sgs.EventPhaseChanging,sgs.Death},
	view_as_skill = ol_zhoufuVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.StartJudge then
			if not player:getPile("incantation"):isEmpty() then
				local judge = data:toJudge()
				judge.card = sgs.Sanguosha:getCard(player:getPile("incantation"):first())
				room:moveCardTo(judge.card, nil, judge.who,sgs.Player_PlaceJudge,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGE,judge.who:objectName(),self:objectName(),"",judge.reason),true)
				judge:updateResult()
				room:setTag("SkipGameRule",sgs.QVariant(true))
				room:addPlayerMark(player, self:objectName().."-Clear")
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:setPlayerMark(player, self:objectName()..player:getPile("incantation"):first()..p:objectName(),0)
					room:setPlayerMark(player, "ol_yingbingput"..player:getPile("incantation"):first()..p:objectName(),0)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark(self:objectName().."-Clear") > 0 then
						local target = room:findPlayerBySkillName(self:objectName())
						if target then
							room:addPlayerMark(target, self:objectName().."engine")
							if target:getMark(self:objectName().."engine") > 0 then
								room:broadcastSkillInvoke(self:objectName())
								room:loseHp(p)
								room:removePlayerMark(target, self:objectName().."engine")
							end
						else
							room:loseHp(p)
						end
					end
				end
			end
			--[[
		else
			local death = data:toDeath()		
			if death.who:objectName() == player:objectName() then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (not p:getPile("incantation"):isEmpty()) and p:getMark("ol_yingbingput"..p:getPile("incantation"):first()..player:objectName()) > 0 then
						room:throwCard(sgs.Sanguosha:getCard(p:getPile("incantation"):first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", p:objectName(), self:objectName(), ""), nil)
					end
				end
			end
			]]--
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
ol_zhangbao:addSkill(ol_zhoufu)
ol_yingbing = sgs.CreateTriggerSkill{
	name = "ol_yingbing",
	events = {sgs.CardUsed, sgs.CardResponded},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			local response = data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		if card and card:getHandlingMethod() == sgs.Card_MethodUse and card:getSuit() == sgs.Sanguosha:getCard(player:getPile("incantation"):first()):getSuit() then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				--if player:getMark(self:objectName().."put"..player:getPile("incantation"):first()..p:objectName()) > 0  then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(1, self:objectName())
						--room:addPlayerMark(player, self:objectName()..player:getPile("incantation"):first()..p:objectName())
						room:addPlayerMark(player, self:objectName()..player:getPile("incantation"):first() )
						--if player:getMark(self:objectName()..player:getPile("incantation"):first()..p:objectName()) == 2 then
						if player:getMark(self:objectName()..player:getPile("incantation"):first() ) == 2 then
							--room:setPlayerMark(player, self:objectName()..player:getPile("incantation"):first()..p:objectName(), 0)
							--room:setPlayerMark(player, self:objectName().."put"..player:getPile("incantation"):first()..p:objectName(), 0)
							room:setPlayerMark(player, self:objectName()..player:getPile("incantation"):first(), 0)
							if not player:getPile("incantation"):isEmpty() then
								room:throwCard(sgs.Sanguosha:getCard(player:getPile("incantation"):first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", p:objectName(), self:objectName(), ""), nil)
							end
						end
						room:removePlayerMark(p, self:objectName().."engine")
					end
				--end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and not target:getPile("incantation"):isEmpty()
	end
}
ol_zhangbao:addSkill(ol_yingbing)

sgs.LoadTranslationTable{
	["ol_zhangbao"] = "OL張寶",
	["&ol_zhangbao"] = "張寶",
	["#ol_zhangbao"] = "地公將軍",
	["illustrator:ol_zhangbao"] = "大佬榮",
	["ol_zhoufu"] = "咒縛",
	[":ol_zhoufu"] = "出牌階段限一次，你可以將一張手牌置於一名沒有“咒”的其他角色的武將牌上，稱為“咒”；當擁有“咒”的角色判定時，其將一張“咒”當判定牌；一名角色的回合結束時，於此回合內因判定而失去“咒”的角色各失去1點體力。",
	["$ol_zhoufu1"] = "違吾咒者，傾死滅亡！",
	["$ol_zhoufu2"] = "咒保符命，速顯威靈！",
	["ol_yingbing"] = "影兵",
	[":ol_yingbing"] = "鎖定技，當擁有“咒”的角色使用與“咒”花色相同的牌時，你摸一張牌，然後若你因其的此“咒”以此法摸過兩張牌，將此“咒”置入棄牌堆。",
	["$ol_yingbing1"] = "所呼立至，所召立前！",
	["$ol_yingbing2"] = "朱雀玄武，侍衛我真！",
	["~ol_zhangbao"] = "黃天！為何……",
}

--OL潘鳳
panfeng_po = sgs.General(extension, "panfeng_po", "qun2", "4", true)

kuangfu_po_select = sgs.CreateSkillCard{
	name = "kuangfu_po",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:getEquips():length() > 0
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local card_id = room:askForCardChosen(source, targets[1], "e", self:objectName())
		room:throwCard(card_id, targets[1], source)
		if source:objectName() == targets[1]:objectName() then
			room:setPlayerFlag(source,"kuangfu_po_self_equip")
		else
			room:setPlayerFlag(source,"kuangfu_po_other_equip")
		end
		room:askForUseCard(source, "@@kuangfu_po!", "@kuangfu_po")
	end
}

kuangfu_poCard = sgs.CreateSkillCard{
	name = "kuangfu_poCard",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("kuangfu_po")
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
		if targets_list:length() > 0 then
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("kuangfu_po")
				room:useCard(sgs.CardUseStruct(slash, source, targets_list))
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}

kuangfu_poVS = sgs.CreateViewAsSkill{
	name = "kuangfu_po",
	n = 0,
	response_pattern = "@@kuangfu_po!",
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@kuangfu_po!" then
			return kuangfu_poCard:clone()
		else
			return kuangfu_po_select:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kuangfu_po")
	end,
}


kuangfu_po = sgs.CreateTriggerSkill{
	name = "kuangfu_po",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished},
	view_as_skill = kuangfu_poVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == "kuangfu_po" then
				if use.card:hasFlag("damage_record") then
					--room:setPlayerFlag(player,"-kuangfu_po_damage")
					if player:hasFlag("kuangfu_po_self_equip") then
						player:drawCards(2)
						room:setPlayerFlag(player,"-kuangfu_po_self_equip")
					elseif player:hasFlag("kuangfu_po_other_equip") then
						room:setPlayerFlag(player,"-kuangfu_po_other_equip")
					end
				else
					if player:hasFlag("kuangfu_po_self_equip") then
						room:setPlayerFlag(player,"-kuangfu_po_self_equip")
					elseif player:hasFlag("kuangfu_po_other_equip") then
						room:askForDiscard(player,"kuangfu_po",2,2)
						room:setPlayerFlag(player,"-kuangfu_po_other_equip")
					end
				end
			end
		end
		return false
	end	
}

kuangfu_poTargetMod = sgs.CreateTargetModSkill{
	name = "#kuangfu_poTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "kuangfu_po" then
			return 1000
		end
	end,
}

panfeng_po:addSkill(kuangfu_po)
panfeng_po:addSkill(kuangfu_poTargetMod)

sgs.LoadTranslationTable{
["#panfeng_po"] = "聯軍上將",
["panfeng_po"] = "OL潘鳳",
["&panfeng_po"] = "潘鳳",
["illustrator:panfeng_po"] = "吐槽",
["kuangfu_po"] = "狂斧",
["kuangfu_poCard"] = "狂斧",
[":kuangfu_po"] = "出牌階段限一次，你可以將任意角色裝備區裡的一張牌當【殺】使用（無視距離，不計次數）。若此【殺】不是你的牌且未造成傷害"..
"，你棄置兩張手牌；若此【殺】是你的牌且造成了傷害，你摸兩張牌。",
	["~kuangfu_po"] = "選擇一名角色→點擊確定",
	["@kuangfu_po"] = "你可以視為使用一張【殺】",
}


--界張寶二版
sec_ol_zhangbao = sgs.General(extension, "sec_ol_zhangbao", "qun2", 3, true)

function RIGHT(self, player)
	if player and player:isAlive() and player:hasSkill(self:objectName()) then return true else return false end
end

sec_ol_zhangbao:addSkill(ol_zhoufu)

sec_ol_yingbing = sgs.CreateTriggerSkill{
	name = "sec_ol_yingbing",
	events = {sgs.CardUsed, sgs.CardResponded},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			local response = data:toCardResponse()
			if response.m_isUse then
				card = response.m_card
			end
		end
		if card and card:getHandlingMethod() == sgs.Card_MethodUse and GetColor(card) == GetColor(sgs.Sanguosha:getCard(player:getPile("incantation"):first())) then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				--if player:getMark("ol_yingbingput"..player:getPile("incantation"):first()..p:objectName()) > 0  then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(1, self:objectName())
						room:addPlayerMark(player, self:objectName()..player:getPile("incantation"):first() )
						--if player:getMark(self:objectName()..player:getPile("incantation"):first()..p:objectName()) == 2 then
						if player:getMark(self:objectName()..player:getPile("incantation"):first() ) == 2 then
							--room:setPlayerMark(player, self:objectName()..player:getPile("incantation"):first()..p:objectName(), 0)
							--room:setPlayerMark(player, "ol_yingbingput"..player:getPile("incantation"):first()..p:objectName(), 0)
							room:setPlayerMark(player, self:objectName()..player:getPile("incantation"):first(), 0)
							if not player:getPile("incantation"):isEmpty() then
								local card = sgs.Sanguosha:getCard(player:getPile("incantation"):first())
								room:obtainCard(p, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(), self:objectName(), ""))
							end
						end
						room:removePlayerMark(p, self:objectName().."engine")
					end
				--end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and not target:getPile("incantation"):isEmpty()
	end
}

sec_ol_zhangbao:addSkill(sec_ol_yingbing)

sgs.LoadTranslationTable{
	["sec_ol_zhangbao"] = "OL張寶--二版",
	["&sec_ol_zhangbao"] = "張寶",
	["#sec_ol_zhangbao"] = "地公將軍",
	["illustrator:sec_ol_zhangbao"] = "大佬榮",

	["sec_ol_yingbing"] = "影兵",
	[":sec_ol_yingbing"] = "鎖定技，當擁有“咒”的角色使用與“咒”顏色相同的牌時，你摸一張牌，然後若你因其的此“咒”以此法摸過兩張牌，你獲得此“咒”。",
	["$sec_ol_yingbing1"] = "所呼立至，所召立前！",
	["$sec_ol_yingbing2"] = "朱雀玄武，侍衛我真！",
	["~sec_ol_zhangbao"] = "黃天！為何……",
}

--諸葛誕
ol_zhugedan = sgs.General(extension, "ol_zhugedan", "wei2", 4, true)

ol_juyi = sgs.CreateTriggerSkill{
	name = "ol_juyi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMaxHp() > room:alivePlayerCount() or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			room:addPlayerMark(player, "ol_juyi")
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

				player:drawCards(player:getMaxHp())
				room:doSuperLightbox("zhugedan","ol_juyi")				

				room:acquireSkill(player, "ol_weizhong")
				room:acquireSkill(player, "benghuai")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("ol_juyi")
				and target:isAlive()
				and (target:getMark("ol_juyi") == 0)
	end
}

ol_weizhong = sgs.CreateTriggerSkill{
	name = "ol_weizhong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.MaxHpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
		player:drawCards(1, self:objectName())

		local n = player:getHandcardNum()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			n = math.min(n, p:getHandcardNum())
		end
		if p:getHandcardNum() == n then
			player:drawCards(1, self:objectName())
		end
	end
}

if not sgs.Sanguosha:getSkill("ol_weizhong") then skills:append(ol_weizhong) end

ol_zhugedan:addSkill("gongao")
ol_zhugedan:addSkill(ol_juyi)
ol_zhugedan:addRelateSkill("ol_weizhong")
ol_zhugedan:addRelateSkill("benghuai")

sgs.LoadTranslationTable{
	["#ol_zhugedan"] = "薤露蒿里",
	["ol_zhugedan"] = "OL諸葛誕",
	["&ol_zhugedan"] = "諸葛誕",
	["illustrator:ol_zhugedan"] = "雪君S",
	["gongao"] = "功獒",
	[":gongao"] = "鎖定技。每當一名其他角色死亡時，你增加1點體力上限，回復1點體力。",
	["ol_juyi"] = "舉義",
	[":ol_juyi"] = "覺醒技。準備階段開始時，若你的體力上限大於角色數，你摸等同體力上限數量的牌，然後獲得“崩壞”和“威重”（鎖定技。每當你的體力上限改變後，你摸一張牌；若你的手牌最少，則多摸一張牌）。",
	["ol_weizhong"] = "威重",
	[":ol_weizhong"] = "鎖定技。每當你的體力上限改變後，你摸一張牌；若你的手牌最少，則多摸一張牌。",
	["$JuyiAnimate"] = "image=image/animate/juyi.png",
	["#JuyiWake"] = "%from 的體力上限(%arg)大於角色數(%arg2)，觸發“<font color=\"yellow\"><b>舉義</b></font> ”覺醒",
}

--OL郭淮
ol_guohuai = sgs.General(extension,"ol_guohuai","wei2","4",true)
--精策
ol_jingce = sgs.CreateTriggerSkill{
	name = "ol_jingce", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(player:getMark("used_cardtype_num-Clear"), self:objectName())
				end
			end
		end
	end
}

ol_jingceMax = sgs.CreateMaxCardsSkill{
	name = "#ol_jingceMax",
	extra_func = function(self, target)
		if target:hasSkill("ol_jingce") then
			return target:getMark("used_suit_num-Clear")
		end
	end
}

ol_guohuai:addSkill(ol_jingce)
ol_guohuai:addSkill(ol_jingceMax)

sgs.LoadTranslationTable{
	["ol_guohuai"] = "OL郭淮",
	["&ol_guohuai"] = "郭淮",
	["#ol_guohuai"] = "",
	["ol_jingce"] = "精策",
	[":ol_jingce"] = "出牌階段，你每使用一種花色的手牌，你本回合手牌上限+1；出牌階段結束時，你可摸X張牌（X是你本回合使用過牌的類型數）。",
}

--OL諸葛恪
ol_zhugeke = sgs.General(extension,"ol_zhugeke","wu2","3",true)

local json = require("json")

function view(room, player, ids, enabled, disabled)
	local result = -1;
	local jsonLog = {
		"$ViewDrawPile",
		player:objectName(),
		"",
		table.concat(sgs.QList2Table(ids),"+"),
		"",
		""
	}
	room:doNotify(player, sgs.CommandType.S_COMMAND_LOG_SKILL, json.encode(jsonLog))
	room:notifySkillInvoked(player, "ol_aocai")
	if enabled:isEmpty() then
		local jsonValue = {
			".",
			false,
			sgs.QList2Table(ids)
		}
		room:doNotify(player,sgs.CommandType.S_COMMAND_SHOW_ALL_CARDS, json.encode(jsonValue))
	else
		room:fillAG(ids, player, disabled)
		local id = room:askForAG(player, enabled, true, "ol_aocai");
		if id ~= -1 then
			ids:removeOne(id)
			result = id
		end
		room:clearAG(player)
	end
	room:returnToTopDrawPile(ids)--用这个函数将牌放回牌堆顶
	if result == -1 then
		room:setPlayerFlag(player, "Global_ol_aocaiFailed")
	end

	return result
end

ol_aocaiCard = sgs.CreateSkillCard{
	name = "ol_aocaiCard",
	will_throw = false ,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
	end ,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
		end
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local ids
		if user:isKongcheng() then
			ids = room:getNCards(4, false)
		else
			ids = room:getNCards(2, false)
		end
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names,"fire_slash")
			table.insert(names,"thunder_slash")
		end
		local enabled, disabled = sgs.IntList(), sgs.IntList()
		for _,id in sgs.qlist(ids) do
			if table.contains(names, sgs.Sanguosha:getCard(id):objectName()) then
				enabled:append(id)
			else
				disabled:append(id)
			end
		end
		local id = view(room, user, ids, enabled, disabled)
		return sgs.Sanguosha:getCard(id)
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
		local ids
		room:broadcastSkillInvoke("ol_aocai")
		if user:isKongcheng() then
			ids = room:getNCards(4, false)
		else
			ids = room:getNCards(2, false)
		end
		local aocaistring = self:getUserString()
		local names = aocaistring:split("+")
		if table.contains(names, "slash") then
			table.insert(names, "fire_slash")
			table.insert(names, "thunder_slash")
		end
		local enabled, disabled = sgs.IntList(), sgs.IntList()
		for _,id in sgs.qlist(ids) do
			if table.contains(names, sgs.Sanguosha:getCard(id):objectName()) then
				enabled:append(id)
			else
				disabled:append(id)
			end
		end
		local id = view(room, user, ids, enabled, disabled)
		return sgs.Sanguosha:getCard(id)
	end
}

ol_aocaiVS = sgs.CreateZeroCardViewAsSkill{
	name = "ol_aocai",
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive or player:hasFlag("Global_ol_aocaiFailed") then return end
		if pattern == "slash" then
			return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		elseif pattern == "peach" then
			return not player:hasFlag("Global_PreventPeach")
		elseif string.find(pattern, "analeptic") then
			return true
		end
		return false
	end,
	view_as = function(self)
		local acard = ol_aocaiCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
			pattern = "analeptic"
		end
		acard:setUserString(pattern)
		return acard
	end
}


ol_aocai = sgs.CreateTriggerSkill{
	name = "ol_aocai",
	view_as_skill = ol_aocaiVS,
	events = {sgs.CardAsked},
	on_trigger = function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_NotActive then return end
		local room = player:getRoom()

		local pattern = data:toStringList()[1]
		if pattern == "slash" or pattern == "jink" then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local ids
				room:broadcastSkillInvoke(self:objectName())
				if player:isKongcheng() then
					ids = room:getNCards(4, false)
				else
					ids = room:getNCards(2, false)
				end
				local enabled, disabled = sgs.IntList(), sgs.IntList()
				for _,id in sgs.qlist(ids) do
					if (pattern == "slash" and sgs.Sanguosha:getCard(id):isKindOf("Slash"))
					or (pattern == "jink" and sgs.Sanguosha:getCard(id):isKindOf("Jink")) then
						enabled:append(id)
					else
						disabled:append(id)
					end
				end
				local id = view(room, player, ids, enabled, disabled)
				if id ~= -1 then
					local card = sgs.Sanguosha:getCard(id)
					room:provide(card)
					return true
				end
			end
		end
	end,
}

ol_duwuCard = sgs.CreateSkillCard{
	name = "ol_duwu" ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or (math.max(0, to_select:getHp()) ~= self:subcardsLength()) then return false end
		if sgs.Self:getWeapon() and self:getSubcards():contains(sgs.Self:getWeapon():getId()) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			local distance_fix = weapon:getRange() - sgs.Self:getAttackRange(false)
			if sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
				distance_fix = distance_fix + 1
			end
			return sgs.Self:inMyAttackRange(to_select, distance_fix)
		elseif sgs.Self:getOffensiveHorse() and self:getSubcards():contains(sgs.Self:getOffensiveHorse():getId()) then
			return sgs.Self:inMyAttackRange(to_select, 1)
		else
			return sgs.Self:inMyAttackRange(to_select)
		end
	end ,
	on_effect = function(self, effect)
		effect.from:getRoom():damage(sgs.DamageStruct("ol_duwu", effect.from, effect.to))
	end
}
ol_duwuVS = sgs.CreateViewAsSkill{
	name = "ol_duwu" ,
	n = 999 ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and (not player:hasFlag("ol_duwuEnterDying"))
	end ,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local duwu = ol_duwuCard:clone()
		if #cards ~= 0 then
			for _, c in ipairs(cards) do
				duwu:addSubcard(c)
			end
		end
		return duwu
	end ,
}
ol_duwu = sgs.CreateTriggerSkill{
	name = "ol_duwu" ,
	events = {sgs.QuitDying} ,
	view_as_skill = ol_duwuVS ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and dying.damage:getReason() == "ol_duwu" and not dying.damage.chain and not dying.damage.transfer and dying.who:isAlive() then
			local from = dying.damage.from
			if from and from:isAlive() then
				room:setPlayerFlag(from, "ol_duwuEnterDying")
				room:loseHp(from,1)
			end
		end
		return false
	end,
}

ol_zhugeke:addSkill(ol_aocai)
ol_zhugeke:addSkill(ol_duwu)

sgs.LoadTranslationTable{
["#ol_zhugeke"] = "興家赤族",
["&ol_zhugeke"] = "諸葛恪",
["ol_zhugeke"] = "OL諸葛恪",
["illustrator:ol_zhugeke"] = "LiuHeng",
["ol_aocai"] = "傲才",
[":ol_aocai"] = "你的回合外，當你需要使用或打出基本牌時，你可以觀看牌堆頂的兩張牌（若你沒有手牌，改為四張），並且可以使用或打出其中的基本牌。 ",
["ol_duwu"] = "黷武",
[":ol_duwu"] = "出牌階段，你可以選擇你攻擊範圍內的一名其他角色並棄置X張牌（X為該角色的體力值），然後對其造成1點傷害。若該角色因此進入了瀕死狀態並且被救回，則你失去1點體力，且此技能失效，直到回合結束。",
["#AocaiUse"] = "%from 發動 %arg 使用/打出了牌堆頂的第 %arg2 張牌",
}

--SP黃月英
ol_sp_huangyueying = sgs.General(extension,"ol_sp_huangyueying","qun2","3",false)

ol_jiqiaoCard = sgs.CreateSkillCard{
	name = "ol_jiqiao",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local n = self:getSubcards():length() * 2
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local ids = room:getNCards(n, false)
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = source
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(), nil)
		room:moveCardsAtomic(move, true)
		room:getThread():delay()
		for _, id in sgs.qlist(ids) do
			if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
				dummy2:addSubcard(id)
			else
				dummy:addSubcard(id)
			end
		end
		if dummy:subcardsLength() > 0 then
			room:obtainCard(source, dummy, false)
		end
		if dummy2:subcardsLength() > 0 then
			room:throwCard(dummy2, nil, nil)
		end
	end
}
ol_jiqiaoVS = sgs.CreateViewAsSkill{
	name = "ol_jiqiao",
	n = 999 ,
	response_pattern = "@@ol_jiqiao",
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = ol_jiqiaoCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return false
	end
}
ol_jiqiao = sgs.CreateTriggerSkill{
	name = "ol_jiqiao",
	events = {sgs.EventPhaseStart},
	view_as_skill = ol_jiqiaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Play then
			room:askForUseCard(player, "@@ol_jiqiao", "@ol_jiqiao")
		end
	end
}

linglongtm = sgs.CreateTargetModSkill{
	name = "#linglongtm",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("linglong") and (not player:getWeapon()) then
			return 1
		end
	end,
}

ol_sp_huangyueying:addSkill(ol_jiqiao)
ol_sp_huangyueying:addSkill("linglong")
ol_sp_huangyueying:addSkill(linglongtm)

sgs.LoadTranslationTable{
["ol_sp_huangyueying"] = "OL群黃月英" ,
["&ol_sp_huangyueying"] = "黃月英" ,
["#ol_sp_huangyueying"] = "閨中璞玉" ,
["ol_jiqiao"] = "機巧",
[":ol_jiqiao"] = "出牌階段開始時，你可以棄置X張裝備牌（X不小於1），然後亮出牌堆頂2X張牌，你獲得其中的非裝備牌，將其餘的牌置入棄牌堆。" ,
["@ol_jiqiao"] = "你可以發動“<font color=\"yellow\"><b>機巧</b></font>”",
["~ol_jiqiao"] = "選擇任意張裝備牌→點擊確定",
["linglong"] = "玲瓏",
[":linglong"] = "鎖定技。若你的裝備區裡沒有武器牌，你使用【殺】的次數+1；若你的裝備區沒有防具牌，視為你裝備【八卦陣】；若你的裝備區沒有坐騎牌，你的手牌上限+1；你的裝備區沒有寶物牌，視為你擁有技能“奇才”。",
["#linglong-treasure"] = "玲瓏",
}

--新馬良二版
ol_maliang_sec_rev = sgs.General(extension, "ol_maliang_sec_rev", "shu", "3", true)

--應援：當你於回合內使用一張牌後，你可以令一名其他角色從牌堆獲得一張與該牌類型相同的牌（每種類型的牌每回合限一次）
yingyuan_sec_rev = sgs.CreateTriggerSkill{
	name = "yingyuan_sec_rev",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local card = data:toCardUse().card
			if player:getMark("yingyuan_sec_rev"..card:getTypeId().."-Clear") == 0 and not card:isKindOf("SkillCard") and player:getPhase() ~= sgs.Player_NotActive then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yingyuan_sec_rev-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						if card:isKindOf("BasicCard") then
							getpatterncard(target, {"BasicCard"},true,false)
						elseif card:isKindOf("EquipCard") then
							getpatterncard(target, {"EquipCard"},true,false)
						elseif card:isKindOf("TrickCard") then
							getpatterncard(target, {"TrickCard"},true,false)
						end

						room:addPlayerMark(player, "yingyuan_sec_rev"..card:getTypeId().."-Clear")
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}

ol_maliang_sec_rev:addSkill(zishu)
ol_maliang_sec_rev:addSkill(yingyuan_sec_rev)

sgs.LoadTranslationTable{
	["ol_maliang_sec_rev"] = "OL馬良",
	["&ol_maliang_sec_rev"] = "馬良",
	["#ol_maliang_sec_rev"] = "白眉智士",
	["illustrator:ol_maliang"] = "depp",
	["yingyuan_sec_rev"] = "應援",
	["yingyuan_sec_rev-invoke"] = "你可以發動「應援」<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	[":yingyuan_sec_rev"] = "當你於回合內使用一張牌後，你可以令一名其他角色從牌堆獲得一張與該牌類型相同的牌（每種類型的牌每回合限一次）。",
	["$yingyuan_sec_rev1"] = "接好嘞。",
	["$yingyuan_sec_rev2"] = "好牌只用一次怎麼夠？",
	["~ol_maliang_sec_rev"] = "我的使命完成了嗎……",
}

--OL陳琳
ol_chenlin = sgs.General(extension,"ol_chenlin","wei2","3",true)

ol_songciCard = sgs.CreateSkillCard{
	name = "ol_songci" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getMark("ol_songci".. sgs.Self:objectName()) == 0)
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:addPlayerMark(effect.to,"@songci")
		room:addPlayerMark(effect.to, "ol_songci" .. effect.from:objectName() )
		if effect.to:getHandcardNum() > effect.to:getHp() then
			room:broadcastSkillInvoke("songci",2)
			room:askForDiscard(effect.to, "ol_songci", 2, 2, false, true)
		else
			room:broadcastSkillInvoke("songci",1)
			effect.to:drawCards(2, "ol_songci")
		end
	end
}
ol_songciVS = sgs.CreateZeroCardViewAsSkill{
	name = "ol_songci",
	view_as = function()
		return ol_songciCard:clone()
	end ,
	enabled_at_play = function(self, player)
		if player:getMark("ol_songci" .. player:objectName() ) == 0 then return true end
		for _, sib in sgs.qlist(player:getSiblings()) do
			if sib:getMark("ol_songci" .. player:objectName() ) == 0 then return true end
		end
		return false
	end 
}

ol_songci = sgs.CreateTriggerSkill{
	name = "ol_songci",
	events = {sgs.PreCardUsed},
	view_as_skill = ol_songciVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local card = data:toCardUse().card
			local invoke = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("ol_songci" .. player:objectName() ) == 0 then
					invoke = false
				end
			end
			if invoke and card and card:getSkillName() == "bifa" then
				player:drawCards(1)
			end
		end
	end
}

ol_chenlin:addSkill("bifa")
ol_chenlin:addSkill(ol_songci)

sgs.LoadTranslationTable{
["#ol_chenlin"] = "破竹之咒",
["ol_chenlin"] = "陳琳",
["illustrator:ol_chenlin"] = "木美人",
["bifa"] = "筆伐",
[":bifa"] = "結束階段開始時，你可以將一張手牌扣置於一名無“筆伐牌”的其他角色旁：若如此做，該角色的回合開始時，其觀看此牌，然後選擇一項：1.交給你一張與此牌類型相同的牌並獲得此牌；2.將此牌置入棄牌堆，然後失去1點體力。",
["@bifa-remove"] = "你可以發動“筆伐”",
["~bifa"] = "選擇一張手牌→選擇一名其他角色→點擊確定",
["@bifa-give"] = "請交給目標角色一張類型相同的手牌",
["ol_songci"] = "頌詞",
[":ol_songci"] = "出牌階段，你可以選擇一項：1.令一名手牌數小於等於其體力值的角色摸兩張牌；2.令一名手牌數大於其體力值的角色棄置兩張牌。每名角色限一次。若你對所有存活角色均發動過「頌詞」，則你每次發動「筆伐」前摸一張牌。",
["$BifaView"] = "%from 觀看了 %arg 牌 %card",
["@songci"] = "頌詞",
}

--OL丁奉
ol_dingfeng = sgs.General(extension,"ol_dingfeng","wu2","4",true)
--短兵
ol_duanbing = sgs.CreateTriggerSkill{
	name = "ol_duanbing",
	events = {sgs.PreCardUsed,sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getPhase() ~= sgs.Player_NotActive then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not use.to:contains(p) and not room:isProhibited(player, p, use.card) and player:distanceTo(p) == 1 then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:setTag("ol_duanbingData", data)
					local target = room:askForPlayerChosen(player, players, "ol_duanbing", nil, true, false)
					room:removeTag("ol_duanbingData")
					if target then
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
			if use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) then
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					if player:distanceTo(p) == 1 then
						room:notifySkillInvoked(player, "ol_duanbing")
						if jink_list[index] == 1 then
							jink_list[index] = 2
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end,

}


ol_fenxunCard = sgs.CreateSkillCard{
	name = "ol_fenxun", 
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:setPlayerMark(targets[1], "ol_fenxun"..source:objectName().."-Clear",1)
			room:setPlayerMark(source, "ol_fenxun_has_used-Clear",1)
		end
	end
}
ol_fenxun = sgs.CreateZeroCardViewAsSkill{
	name = "ol_fenxun", 
	view_as = function(self, cards)
		local card = ol_fenxunCard:clone()
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ol_fenxun")
	end
}
ol_fenxunDistance = sgs.CreateDistanceSkill{
	name = "#ol_fenxunDistance",
	correct_func = function(self, from, to)
		if from:hasSkill("ol_fenxun") and to:getMark("ol_fenxun"..from:objectName().."-Clear") > 0 then
			return -99
		else
			return 0
		end
	end  
}


ol_fenxun_damage_record = sgs.CreateTriggerSkill{
	name = "ol_fenxun_damage_record",
	events = {sgs.EventPhaseStart,sgs.PreDamageDone},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventPhaseStart) then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("ol_fenxun_damage_record-Clear") == 0 and player:getMark("ol_fenxun_has_used-Clear") > 0 then
					room:askForDiscard(player, "ol_fenxun", 1, 1, false, false)
				end
			end
		elseif event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.from and damage.to and damage.to:getMark("ol_fenxun"..damage.from:objectName().."-Clear") then
				room:addPlayerMark(damage.from, "ol_fenxun_damage_record-Clear", 1)
			end
		end
	end
}

ol_dingfeng:addSkill(ol_duanbing)
ol_dingfeng:addSkill(ol_fenxun)
ol_dingfeng:addSkill(ol_fenxunDistance)

if not sgs.Sanguosha:getSkill("ol_fenxun_damage_record") then skills:append(ol_fenxun_damage_record) end

sgs.LoadTranslationTable{
["#ol_dingfeng"] = "清側重臣",
["ol_dingfeng"] = "OL丁奉",
["&ol_dingfeng"] = "丁奉",
["illustrator:ol_dingfeng"] = "紫喬",
["ol_duanbing"] = "短兵",
["#ol_fenxunDistance"] = "奮迅",
[":ol_duanbing"] = "當你使用【殺】選擇目標後，你可以令一名距離為1的角色也成為此【殺】的目標。當你使用【殺】指定距離為1的角色為目標後，該角色需依次使用兩張【閃】才能抵消此【殺】。",
["ol_fenxun"] = "奮迅",
[":ol_fenxun"] = "出牌階段限一次，你可以選擇一名其他角色，本回合你計算與其的距離視為1，然後直到回合結束時，若你未對其造成過傷害，你棄置一張牌。",
}

sgs.Sanguosha:addSkills(skills)


return {extension, extension_wind}

