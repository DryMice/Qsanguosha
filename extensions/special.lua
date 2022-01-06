module("extensions.special", package.seeall)
extension = sgs.Package("special")

sgs.LoadTranslationTable{
	["special"] = "特殊武將",
}

--崔琰
cuiyan = sgs.General(extension, "cuiyan", "wei2", 3)

yawang = sgs.CreateTriggerSkill{
	name = "yawang",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw and RIGHT(self, player) then
				local x = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getHp() == player:getHp() then
						x = x + 1
					end
				end
				room:broadcastSkillInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				player:drawCards(x)
				room:setPlayerMark(player, "yawang-Clear", x)
				return true
			elseif player:getPhase() == sgs.Player_Play and player:getMark("yawang_stop-Clear") ~= 0 then
				room:setPlayerCardLimitation(player, "use", ".", false)
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:getMark("yawang_stop-Clear") ~= 0 then
			room:removePlayerCardLimitation(player, "use", ".")
		end
	end
}

cuiyan:addSkill(yawang)
ol_xunzhi = sgs.CreatePhaseChangeSkill{
	name = "ol_xunzhi", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:getPhase() == sgs.Player_Start and p:getNextAlive():objectName() == player:objectName() and p:getHp() ~= player:getHp() and player:getNextAlive():getHp() ~= player:getHp() and room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(player)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player, "@Maxcards", 2)
					room:removePlayerMark(player, self:objectName().."engine")
				end
				break
			end
		end
	end
}
cuiyan:addSkill(ol_xunzhi)

sgs.LoadTranslationTable{
["cuiyan"] = "崔琰",
["#cuiyan"] = "伯夷之風",
["illustrator:ol_quancong"] = "F.源",
["yawang"] = "雅望",
[":yawang"] = "鎖定技，摸牌階段開始時，你放棄摸牌，然後摸X張牌，令你於此回合的出牌階段內使用的牌數不大於X。（X為體力值與你相同的角色數）",--ZY按：若X為3且你執行兩個出牌階段，第一個出牌階段使用兩張牌，第二個出牌階段就只能使用一張牌了
["$yawang1"] = "琰，定不負諸位雅望。",
["$yawang2"] = "君子，當以正氣，立於亂世！",
["ol_xunzhi"] = "殉志",
[":ol_xunzhi"] = "準備階段開始時，若你的上家與下家的體力值均與你不相同，你可以失去1點體力，令你的手牌上限+2。",
["$ol_xunzhi1"] = "成大義者，這點兒犧牲，算不得什麼！",
["$ol_xunzhi2"] = "春秋大業，自在我心！",
["~cuiyan"] = "爾等，盡是欺世盜名之輩......",
}	

--皇甫嵩
huangfusong = sgs.General(extension, "huangfusong", "qun2",4,true,true)

fenyueCard = sgs.CreateSkillCard{
	name = "fenyue", 
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:isKongcheng()
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if source:pindian(targets[1], self:objectName(), self) then
				room:broadcastSkillInvoke(self:objectName(), 2)
				local choices = "fenyue1"
				if source:canSlash(targets[1], nil, false) then
					choices = "fenyue1+fenyue2"
				end
				local choice = room:askForChoice(source, self:objectName(), choices)
				if choice == "fenyue2" then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("_"..self:objectName())
					room:useCard(sgs.CardUseStruct(slash, source, targets[1]))
				else
					room:addPlayerMark(targets[1], "ban_ur")
					room:setPlayerCardLimitation(targets[1], "use,response", ".|.|.|hand", false)
				end
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:setPlayerFlag(source, "Global_PlayPhaseTerminated")
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

fenyue = sgs.CreateOneCardViewAsSkill{
	name = "fenyue", 
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local skillcard = fenyueCard:clone()
		skillcard:addSubcard(card:getId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#fenyue") < player:getMark("fenyue")
	end
}
huangfusong:addSkill(fenyue)

sgs.LoadTranslationTable{
["huangfusong"] = "忠膽皇甫嵩",
["&huangfusong"] = "皇甫嵩",
["#huangfusong"] = "志定雪霜",
["illustrator:huangfusong"] = "秋呆呆",
["fenyue"] = "奮鉞",
[":fenyue"] = "<font color=\"green\"><b>出牌階段限X次，</b></font>你可以與一名角色拼點：若你贏，你選擇是否視為對其使用【殺】，若選擇否，其於此回合內不能使用或打出手牌；若你沒贏後，你結束此階段。（X為忠臣數）",
["fenyue1"] = "其於此回合內不能使用或打出手牌",
["fenyue2"] = "視為對其使用【殺】",
["$fenyue1"] = "逆賊勢大，且紮營寨，擊其懈怠。",
["$fenyue2"] = "兵有其變，不在眾寡 。",
["~huangfusong"] = "吾只恨黃巾未平，不能報效朝廷。",
}



--台灣一將

--TW曹洪
twyj_caohong = sgs.General(extension, "twyj_caohong", "wei2", 4, true, true)
--護主
twyj_huzhuCard = sgs.CreateSkillCard{
	name = "twyj_huzhu",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local card = room:askForCard(targets[1], ".|.|.|hand!", "@twyj_huzhu:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
		if card then
			room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
			local ids = sgs.IntList()
			for _, e in sgs.qlist(source:getCards("e")) do
				ids:append(e:getEffectiveId())
			end
			if ids:length() > 0 then
				room:fillAG(ids)
				local card_id = room:askForAG(targets[1], ids, false, self:objectName())
				if card_id ~= -1 then
					room:obtainCard(targets[1], card_id, true)
				end
				room:clearAG()
				local _data = sgs.QVariant()
				_data:setValue(targets[1])
				if targets[1]:getHp() <= source:getHp() and targets[1]:isWounded() and room:askForSkillInvoke(source, self:objectName(), _data) then
					room:recover(targets[1], sgs.RecoverStruct(targets[1]))
				end
			end
		end
	end
}
twyj_huzhu = sgs.CreateZeroCardViewAsSkill{
	name = "twyj_huzhu",
	view_as = function(self, cards)
		return twyj_huzhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#twyj_huzhu") and not player:getEquips():isEmpty()
	end
}
twyj_caohong:addSkill(twyj_huzhu)
--斂財
twyj_liancai = sgs.CreateTriggerSkill{
	name = "twyj_liancai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.TurnOver},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
			player:turnOver()
			local ids = sgs.IntList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, e in sgs.qlist(p:getCards("e")) do
					ids:append(e:getEffectiveId())
				end
			end
			if ids:length() > 0 then
				room:fillAG(ids)
				local card_id = room:askForAG(player, ids, false, self:objectName())
				if card_id ~= -1 then
					room:obtainCard(player, card_id, true)
				end
				room:clearAG()
			end
		elseif event == sgs.TurnOver then
			if player:hasSkill(self:objectName()) and player:getHp() - player:getHandcardNum() > 0 and room:askForSkillInvoke(player, "twyj_liancai_turnover", data) then
				room:broadcastSkillInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				player:drawCards(player:getHp() - player:getHandcardNum(), self:objectName())
			end
		end
		return false
	end
}
twyj_caohong:addSkill(twyj_liancai)

sgs.LoadTranslationTable{
["twyj_caohong"] = "TW曹洪",
["&twyj_caohong"] = "曹洪",
["#twyj_caohong"] = "驃騎將軍",
["illustrator:twyj_caohong"] = "黃人尤",
["twyj_huzhu"] = "護主",
[":twyj_huzhu"] = "出牌階段限一次，若你的裝備區有牌，你可以指定一名其他角色，交給你一張手牌，並獲得你裝備區的一張牌。若其體力值不大於你，你可以令其回复1點體力。",
["@twyj_huzhu"] = "請交給 %src 一張手牌",
["twyj_liancai"] = "斂財",
[":twyj_liancai"] = "結束階段，你可以翻面，並獲得一名角色裝備區裡的一張牌；每當你翻面時，你可以將手牌補至體力值。",
["twyj_liancai_turnover"] = "手牌補至體力值",
}

twyj_dingfeng = sgs.General(extension, "twyj_dingfeng", "wu2", 4, true, true)
twyj_qijiaCard = sgs.CreateSkillCard{
	name = "twyj_qijia",
	will_throw = true,
	filter = function(self, targets, to_select)
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and sgs.Self:getOffensiveHorse() and sgs.Self:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select) and sgs.Self:canSlash(to_select, true, rangefix)
	end,
	about_to_use = function(self, room, use)
		local id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(id)
		local equip_index = card:getRealCard():toEquipCard():location()
		room:setPlayerMark(use.from, self:objectName().."_"..equip_index.."-Clear", 1)
		room:throwCard(id, use.from, use.from)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
		slash:setSkillName(self:objectName())
		room:useCard(sgs.CardUseStruct(slash, use.from, use.to))
	end
}
twyj_qijia = sgs.CreateOneCardViewAsSkill{
	name = "twyj_qijia",
	view_filter = function(self, card)
		if card:isEquipped() then
			local equip_index = card:getRealCard():toEquipCard():location()
			return card:isEquipped() and not sgs.Self:isJilei(card) and sgs.Self:canDiscard(sgs.Self, "e") and sgs.Self:getMark(self:objectName().."_"..equip_index.."-Clear") == 0
		end
		return false
	end,
	view_as = function(self, card)
		local skillcard = twyj_qijiaCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
twyj_dingfeng:addSkill(twyj_qijia)
twyj_zhuchenCard = sgs.CreateSkillCard{
	name = "twyj_zhuchen",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(targets[1], "twyj_zhuchen_dis_fix")
	end
}
twyj_zhuchen = sgs.CreateOneCardViewAsSkill{
	name = "twyj_zhuchen",
	view_filter = function(self, card)
		return card:isKindOf("Peach") or card:isKindOf("Analeptic")
	end,
	view_as = function(self, card)
		local skillcard = twyj_zhuchenCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
twyj_dingfeng:addSkill(twyj_zhuchen)

sgs.LoadTranslationTable{
["twyj_dingfeng"] = "TW丁奉",
["&twyj_dingfeng"] = "丁奉",
["#twyj_dingfeng"] = "勇冠全軍",
["illustrator:twyj_dingfeng"] = "柯鬱萍",
["twyj_qijia"] = "棄甲",
[":twyj_qijia"] = "出牌階段<font color=\"green\"><b>（裝備區每個位置限一次），</b></font>你可以棄置一張在裝備區的牌，視為對一名攻擊範圍內的其他角色使用【殺】（你以此法使用的【殺】不計入出牌階段【殺】的使用次數）。",
["twyj_zhuchen"] = "誅綝",
[":twyj_zhuchen"] = "出牌階段，你可以棄置一張【酒】或【桃】並指定一名角色，此階段視為與該角色距離為1。",
}
--馬良
twyj_maliang = sgs.General(extension, "twyj_maliang", "shu2", 3, true, true)
twyj_rangyiUseCard = sgs.CreateSkillCard{
	name = "twyj_rangyiUse",
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
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, card in sgs.list(use.from:getHandcards()) do
			if card:hasFlag("twyj_rangyi") and card:getEffectiveId() ~= self:getSubcards():first() then
				dummy:addSubcard(card:getEffectiveId())
			end
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("twyj_rangyi_source") > 0 then
				room:obtainCard(p, dummy, false)
				break
			end
		end
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
twyj_rangyiCard = sgs.CreateSkillCard{
	name = "twyj_rangyi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "twyj_rangyi_source", 1)
		local ids = sgs.IntList()
		for _, card in sgs.list(source:getHandcards()) do
			ids:append(card:getEffectiveId())
		end
		for _, id in sgs.qlist(ids) do
			room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
		end
		room:obtainCard(targets[1], source:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		if not room:askForUseCard(targets[1], "@@twyj_rangyi", "@twyj_rangyi") then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 1))
		end
		for _, id in sgs.qlist(ids) do
			room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName())
		end
		room:setPlayerMark(source, "twyj_rangyi_source", 0)
	end
}
twyj_rangyi = sgs.CreateViewAsSkill{
	n = 1,
	name = "twyj_rangyi",
	response_pattern = "@@twyj_rangyi",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@twyj_rangyi" then
			return to_select:hasFlag(self:objectName()) and to_select:isAvailable(sgs.Self)
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@twyj_rangyi" then
			if #cards ~= 1 then return nil end
			local skillcard = twyj_rangyiUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
		if #cards ~= 0 then return nil end
		return twyj_rangyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and not player:hasUsed("#twyj_rangyi")
	end
}
twyj_maliang:addSkill(twyj_rangyi)
twyj_baimei = sgs.CreateTriggerSkill{
	name = "twyj_baimei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if player:isKongcheng() then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal or (damage.card and damage.card:isKindOf("TrickCard"))) and damage.to and damage.to:objectName() == player:objectName() then
				local msg = sgs.LogMessage()
				msg.type = "#twyj_baimei_Protect"
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
twyj_maliang:addSkill(twyj_baimei)

sgs.LoadTranslationTable{
["twyj_maliang"] = "TW馬良",
["&twyj_maliang"] = "馬良",
["#twyj_maliang"] = "白眉令士",
["illustrator:twyj_maliang"] = "廖昌翊",
["twyj_rangyi"] = "攘夷",
--[":twyj_rangyi"] = "出牌階段限一次，你可以將所有手牌（至少一張）交給一名其他角色，該角色可以從你給的手牌中合理使用一張手牌，即目標獲得使用一張手牌的額外出牌階段。該張牌結算前，需把剩餘手牌還給你，若其不使用手牌，則視為你對其造成1點傷害且手牌不能還給你。",
[":twyj_rangyi"] = "出牌階段限一次，你可以將所有手牌（至少一張）交給一名其他角色，該角色可以從你給的手牌中合理使用一張手牌（即目標獲得使用一張手牌的額外出牌階段），該張牌結算前，需把剩餘手牌還給你。若其不使用手牌，則視為你對其造成1點傷害且手牌不能還給你。",
["@twyj_rangyi"] = "請使用一張手牌",
["~twyj_rangyi"] = "選擇一張牌→選擇目標→點擊確定",
["twyj_baimei"] = "白眉",
[":twyj_baimei"] = "鎖定技，若你沒有手牌，你防止你受到的任何的錦囊牌的傷害和屬性的傷害。",
["#twyj_baimei_Protect"] = "%from 的“<font color=\"yellow\"><b>白眉</b></font>”效果被觸發，防止了%arg 點傷害[%arg2]" ,
}

--呂蒙
heg_lvmeng = sgs.General(extension, "heg_lvmeng", "wu", 4, true)
heg_keji = sgs.CreateTriggerSkill{
	name = "heg_keji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") then
				if use.card:getSuit() == sgs.Card_Spade then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Heart then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Club then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Diamond then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				end
				local suit = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, self:objectName().."_") and player:getMark(mark) > 0 then
						table.insert(suit, mark:split("_")[4])
					end
				end
				if #suit >= 2 then
					room:setPlayerMark(player, self:objectName().."-Clear", 1)
				else
					room:setPlayerMark(player, self:objectName().."-Clear", 0)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_Discard and player:hasSkill(self:objectName()) and player:getHandcardNum() >= player:getMaxCards() - 4 and player:getMark(self:objectName().."-Clear") == 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
heg_lvmeng:addSkill(heg_keji)
heg_mouduanCard = sgs.CreateSkillCard{
	name = "heg_mouduan",
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
					if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) and p:hasJudgeArea() then
						tos:append(p)
					end
				end
			end
			local tag = sgs.QVariant()
			tag:setValue(targets[1])
			room:setTag("heg_mouduanTarget", tag)
			--local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to" .. card:objectName())
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@heg_mouduan-to")
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("heg_mouduanTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
heg_mouduanVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_mouduan",
	view_as = function(self, cards)
		return heg_mouduanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@heg_mouduan"
	end
}
heg_mouduan = sgs.CreateTriggerSkill{
	name = "heg_mouduan",
	view_as_skill = heg_mouduanVS,
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") then
				
				room:addPlayerMark(player, self:objectName().."_type_"..use.card:getTypeId().."_-Clear")
				
				if use.card:getSuit() == sgs.Card_Spade then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Heart then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Club then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Diamond then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				end
				local suit = {}
				local types = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, self:objectName().."_suit_") and player:getMark(mark) > 0 then
						table.insert(suit, mark:split("_")[4])
					end
					if string.find(mark, self:objectName().."_type_") and player:getMark(mark) > 0 then
						table.insert(types, mark:split("_")[4])
					end
				end
				if #suit >= 4 or #types >= 3 then
					room:setPlayerMark(player, self:objectName().."-Clear", 1)
				else
					room:setPlayerMark(player, self:objectName().."-Clear", 0)
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and player:getMark(self:objectName().."-Clear") > 0 then
			room:askForUseCard(player, "@heg_mouduan", "@heg_mouduan")
		end
		return false
	end
}
heg_lvmeng:addSkill(heg_mouduan)

sgs.LoadTranslationTable{
["#heg_lvmeng"] = "士別三日",
["heg_lvmeng"] = "呂蒙-國",
["&heg_lvmeng"] = "呂蒙",
["illustrator:heg_lvmeng"] = "櫻花閃亂",
["heg_keji"] = "克己",
[":heg_keji"] = "鎖定技，若你未於出牌階段內使用過顏色不同的牌，則你本回合的手牌上限+4。",
["$heg_keji1"] = "蓄力待時，不爭首功",
["$heg_keji2"] = "最好的機會還在等著我",
["heg_mouduan"] = "謀斷",
[":heg_mouduan"] = "結束階段，若你於出牌階段內使用過四種花色或三種類別的牌，則你可以移動場上的一張牌。",
["@heg_mouduan"] = "你可以移動場上的一張牌",
["~heg_mouduan"] = "選擇一名角色→點擊確定",
["@heg_mouduan-to"] = "請選擇移動此卡牌的目標角色",
["$heg_mouduan1"] = "",
["$heg_mouduan2"] = "",
["~heg_lvmeng"] = "你……給我等著！",
}

--曹彰
sec_caozhang = sgs.General(extension, "sec_caozhang", "wei2", 4, true, true)
sec_jiangchi = sgs.CreateTriggerSkill{
	name = "sec_jiangchi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw and player:hasSkill(self:objectName()) then
			local choices = {"sec_jiangchi_draw"}
			if not player:isKongcheng() and player:canDiscard(player, "he") then
				table.insert(choices, "sec_jiangchi_discard")
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			if choice ~= "cancel" then
				ChoiceLog(player, choice)
				if choice == "sec_jiangchi_draw" then
					room:drawCards(player, 1, self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:setPlayerCardLimitation(player, "use,response", "Slash", true)
					room:addPlayerMark(effect.from, "sec_jiangchi_draw-Clear");
				elseif choice == "sec_jiangchi_discard" then
					room:askForDiscard(player, self:objectName(), 1, 1, false, true)
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setPlayerFlag(player, "JiangchiInvoke")
				end
			end
		elseif event == sgs.EventPhaseChanging and player:getMark("sec_jiangchi_draw-Clear") > 0  then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				room:setPlayerCardLimitation(player, "discard", "Slash", true)
			end
		elseif event == sgs.EventPhaseEnd and player:getMark("sec_jiangchi_draw-Clear") > 0 then
			if player:getPhase() == sgs.Player_Discard then
				room:removePlayerCardLimitation(player, "discard", "Slash")
			end
		end
		return false
	end
}

sec_jiangchimc = sgs.CreateMaxCardsSkill{
	name = "#sec_jiangchimc",
	extra_func = function(self, target)
		if target:getMark("sec_jiangchi_draw-Clear") > 0 then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:isKindOf("Slash") then
					x = x + 1
				end
			end
			return x
		end
	end
}

sec_caozhang:addSkill(sec_jiangchi)
sec_caozhang:addSkill(sec_jiangchimc)

sgs.LoadTranslationTable{
["#sec_caozhang"] = "黃須兒",
["sec_caozhang"] = "曹彰-第二版",
["&sec_caozhang"] = "曹彰",
["designer:sec_caozhang"] = "潛龍勿用",
["illustrator:sec_caozhang"] = "Yi章",
["sec_jiangchi"] = "將馳",
--[":sec_jiangchi"] = "摸牌階段結束時，你可以選擇一項：1．摸一張牌，若如此做，你於此回合內不能使用或打出【殺】，且【殺】不計入手牌上限；2．棄置一張牌，若如此做，你於出牌階段內使用【殺】無距離限制且額外次數上限+1。",
[":sec_jiangchi"] = "摸牌階段結束時，你可以選擇一項：1．摸一張牌，若如此做，你於此回合內不能使用或打出【殺】，且【殺】不計入手牌上限；2．棄置一張牌，若如此做，你於出牌階段內使用【殺】無距離限制且額外次數上限+1。",
["sec_jiangchi_draw"] = "摸一張牌",
["sec_jiangchi_discard"] = "棄置一張牌",
["$sec_jiangchi1"] = "謹遵父訓，不可逞匹夫之勇。",
["$sec_jiangchi2"] = "吾定當身先士卒，震魏武雄風！",
["~sec_caozhang"] = "子桓，你害我！",
}

--[[
率善中郎將 難升米 ○ ○ ○
持節：遊戲開始時，你可以選擇一個現有勢力，你的勢力視為該勢力。

外使：出牌階段限一次，你可以用至多X張牌交換一名其他角色等量的手牌（X為現存勢力數），然後若其與你勢力相同或手牌多於你，你摸一張牌。

忍涉：當你受到傷害後，你可以選擇一項：1.將勢力改為現存的另一個勢力；2.或可以額外發動一次「外使」直到你的下個出牌階段結束；3.或與另一名其他角色各摸一張牌。

持節：按照女王的命令，選擇目標吧。
外使：貴國的繁榮，在下都看到了。/希望我們兩國，可以世代修好。
忍涉：一定不能辜負女王的期望。/無論風雨再大，都無法阻止我的腳步。
陣亡：請把這身殘軀，帶回我的家鄉。
]]--
nashime = sgs.General(extension, "nashime", "qun", 3, true)

tw_chijie = sgs.CreateTriggerSkill{
	name = "tw_chijie" ,
	events = {sgs.GameStart} ,
	priority = 9,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:broadcastSkillInvoke(self:objectName())
			local kingdoms = {}
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

			local choice = room:askForChoice(player, "tw_chijie", table.concat(kingdoms, "+"))
			ChoiceLog(player, choice)
			room:setPlayerProperty(player,"kingdom",sgs.QVariant(choice))
		end
	end
}

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

tw_waishiCard = sgs.CreateSkillCard{
	name = "tw_waishi" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local max_num = math.min(getKingdomsFuli(source),targets[1]:getHandcardNum())
		local cards = room:askForExchange(source, self:objectName(), 1, max_num, true, "@tw_waishi")
		local n = cards:getSubcards():length()
		local cards2 = room:askForExchange(targets[1], self:objectName(), n,n, true, "@tw_waishi")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "tw_waishi","")
		room:moveCardTo(cards:getSubcards(), targets[1] ,sgs.Player_PlaceHand,reason)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), "tw_waishi","")
		room:moveCardTo(cards2:getSubcards(), source ,sgs.Player_PlaceHand,reason)
		if targets[1]:getKingdom() == source:getKingdom() or targets[1]:getHandcardNum() > source:getHandcardNum() then
			source:drawCards(1)
		end
	end
}

tw_waishi = sgs.CreateZeroCardViewAsSkill{
	name = "tw_waishi",
	view_as = function()
		return tw_waishiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:isKongcheng() and player:usedTimes("#tw_waishi") < player:getMark("tw_renshe_play")
	end
}

tw_renshe = sgs.CreateTriggerSkill{
	name = "tw_renshe" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local choice = room:askForChoice(player , "tw_renshe", "tw_renshe1+tw_renshe2+tw_renshe3+cancel")
			ChoiceLog(player, choice)
			if choice == "tw_renshe1" then
				room:broadcastSkillInvoke(self:objectName())
				local kingdoms = {}
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

				local choice2 = room:askForChoice(player, "tw_chijie", table.concat(kingdoms, "+"))
				ChoiceLog(player, choice2)
				room:setPlayerProperty(player,"kingdom",sgs.QVariant(choice2))
			elseif choice == "tw_renshe2" then
				room:addPlayerMark(player,"tw_renshe_play")
			elseif choice == "tw_renshe3" then				
				local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "tw_renshe", "@tw_renshe-choose", true)
				if s then
					s:drawCards(1)
					player:drawCards(1)
				end
			end
		end
	end
}

nashime:addSkill(tw_chijie)
nashime:addSkill(tw_waishi)
nashime:addSkill(tw_renshe)

sgs.LoadTranslationTable{
	["nashime"] = "難升米",
	["#nashime"] = "率善中郎將",
	["tw_chijie"] = "持節",
	[":tw_chijie"] = "遊戲開始時，你可以選擇一個現有勢力，你的勢力視為該勢力。",
	["tw_waishi"] = "外使",
	[":tw_waishi"] = "出牌階段限一次，你可以用至多X張牌交換一名其他角色等量的手牌（X為現存勢力數），然後若其與你勢力相同或手牌多於你，你摸一張牌。",
	["tw_renshe"] = "忍涉",
	[":tw_renshe"] = "當你受到傷害後，你可以選擇一項：1.將勢力改為現存的另一個勢力；2.或可以額外發動一次「外使」直到你的下個出牌階段結束；3.或與另一名其他角色各摸一張牌。",
	["tw_renshe1"] = "將勢力改為現存的另一個勢力",
	["tw_renshe2"] = "你可以額外發動一次「外使」直到你的下個出牌階段結束",
	["tw_renshe3"] = "與另一名其他角色各摸一張牌。",
	["~tw_chijie"] = "按照女王的命令，選擇目標吧。",
	["~tw_waishi1"] = "貴國的繁榮，在下都看到了。",
	["~tw_waishi2"] = "希望我們兩國，可以世代修好。",
	["~tw_renshe1"] = "一定不能辜負女王的期望。",
	["~tw_renshe2"] = "無論風雨再大，都無法阻止我的腳步。",
	["~nashime"] = "請把這身殘軀，帶回我的家鄉。",
}

--TW卑彌呼
tw_beimihu = sgs.General(extension, "tw_beimihu$", "qun", "3", false, true)

--
tw_bingzhao = sgs.CreateTriggerSkill{
	name = "tw_bingzhao$", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.GameStart} ,
	priority = 9,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and player:hasLordSkill(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			local kingdoms = {}
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

			local choice = room:askForChoice(player, "tw_bingzhao", table.concat(kingdoms, "+"))
			ChoiceLog(player, choice)
			room:setPlayerMark(player,"tw_bingzhao" .. choice, 1)
		end
	end, 
}

tw_beimihu:addSkill("zongkui")
tw_beimihu:addSkill("guju")
tw_beimihu:addSkill("baijia")
tw_beimihu:addSkill(tw_bingzhao)

sgs.LoadTranslationTable{
	["tw_beimihu"] = "TW卑彌呼",
	["&tw_beimihu"] = "卑彌呼",
	["tw_bingzhao"] = "秉詔",
	[":tw_bingzhao"] = "主公技，遊戲開始時你選擇一個其他勢力，若妳因該勢力的角色受到傷害而發動“骨疽” ，妳可以額外摸一張牌。", 
}

--[[
雷銅 4血
【潰擊】：出牌階段限一次，你可以將一張黑色基本牌當作【兵糧寸斷】置於你的判定區，然後摸一張牌。若如此做，
你可以對體力值最多的一名對手造成2點傷害。對手因此進入瀕死狀態時，你或隊友體力值最少的一方回復	1點體力
]]--
leitong = sgs.General(extension, "leitong", "shu2", 4, true)

kuijiCard = sgs.CreateSkillCard{
	name = "kuiji",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		local player_hp = {}
		table.insert(player_hp, sgs.Self:getHp())
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			table.insert(player_hp, p:getHp())
		end
		return (#targets == 0) and to_select:getHp() == math.max(unpack(player_hp))
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local c = sgs.Sanguosha:getCard(self:getSubcards():first())
			local card = sgs.Sanguosha:cloneCard("supply_shortage", c:getSuit(), c:getNumber())
			card:addSubcard(c:getEffectiveId())
			card:setSkillName(self:getSkillName())
			room:useCard(sgs.CardUseStruct(card, source, source), true)

			
			room:damage(sgs.DamageStruct("kuiji", source, targets[1], 2, sgs.DamageStruct_Normal))

			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
kuijiVS = sgs.CreateOneCardViewAsSkill{
	name = "kuiji",
	filter_pattern = "BasicCard|black",
	response_or_use = true,
	view_as = function(self, card)
		local lm = kuijiCard:clone()
		lm:addSubcard(card:getEffectiveId())
		lm:setSkillName(self:objectName())
		return lm
	end,
	enabled_at_play = function(self, player)
		local card = sgs.Sanguosha:cloneCard("supply_shortage")
		card:deleteLater()
		return not player:containsTrick("supply_shortage") and not player:isProhibited(player, card) and not player:hasUsed("#kuiji")
	end
}

kuiji = sgs.CreateTriggerSkill{
	name = "kuiji",
	view_as_skill = kuijiVS,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to:getHp() <= damage.damage and damage.reason == self:objectName() then
				local players = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getHp() <= player:getHp() then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(player, players, self:objectName(), "kuiji-recover", true)
					if target then
						room:recover(target, sgs.RecoverStruct(target))
					end
				end
			end
		end
		return false
	end,
}

leitong:addSkill(kuiji)


sgs.LoadTranslationTable{
["#leitong"] = "",
["leitong"] = "雷銅",
["&leitong"] = "雷銅",
["illustrator:leitong"] = "紫喬",

["kuiji"] = "潰擊",
[":kuiji"] = "出牌階段限一次，你可以將一張黑色基本牌當作【兵糧寸斷】置於你的判定區，然後摸一張牌。若如此做，你可以對體力值最多的一名角色造成2點傷害。對手因此進入瀕死狀態時，你令一名體力不大於你的角色回復1點體力。",
["kuiji-invoke"] = "你可以對體力值最多的一名角色造成2點傷害",
["kuiji-recover"] = "你可以令一名體力不大於你的角色回復1點體力",
}

--[[
吳蘭 4血
【挫銳】：出牌階段開始時，你可以棄置你或隊友區域裡的一張牌。若如此做，你選擇一項：1.棄置對手裝備區里至多兩張與此牌顏色相同的牌
；2.展示對手的共計兩張手牌，然後獲得其中與此牌顏色相同的牌。
]]--
wulan = sgs.General(extension, "wulan", "shu2", 4, true)

function GetColor(card)
	if card:isRed() then return "red" elseif card:isBlack() then return "black" end
end

function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

wl_cuorui = sgs.CreateTriggerSkill{
	name = "wl_cuorui",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local card = room:askForCard(player, "..", "@wl_cuorui", sgs.QVariant(), sgs.Card_MethodDiscard)
			if card then

				room:setPlayerMark(player,"wl_cuorui"..GetColor(card).."-Clear",1)

				local choice = room:askForChoice(player, self:objectName(), "wl_cuorui1+wl_cuorui2")

				if choice == "wl_cuorui1" then
					local ids = sgs.IntList()
					local dis_ids = sgs.IntList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						for _, cd in sgs.qlist(p:getCards("e")) do
							if GetColor(card) == GetColor(cd) then
								ids:append(cd:getId())
							end
						end
					end
					if (not ids:isEmpty()) then
						room:fillAG(ids)
						for i = 1, 2 do
							if (not ids:isEmpty()) then
								local id = room:askForAG(player, ids, i ~= 1, self:objectName())
								if id == -1 then break end
								ids:removeOne(id)
								dis_ids:append(id)
								room:throwCard(id, nil, player)
								--room:throwCard(sgs.Sanguosha:getCard(id), player, player)
								room:takeAG(player, id, false)
								if ids:isEmpty() then break end
							end
						end
						room:clearAG()
					end
				elseif choice == "wl_cuorui2" then

					local players = sgs.SPlayerList()

					local target1
					if not players:isEmpty() then
						target1 = room:askForPlayerChosen(player, players, self:objectName(), "wl_cuorui-choose", true, false)
						if target1:getHandcardNum() == 1 then
							players:removeOne(target1)
						end
					end


					if target1 then
						local ids = getIntList(target1:getHandcards())
						local id = ids:at(math.random(0, ids:length() - 1))
						room:showCard(target1, id)
						if GetColor(sgs.Sanguosha:getCard(id)) == GetColor(card) then
							room:obtainCard(player,id)
						end
					end

					local target2
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if (not p:isKongcheng()) then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						target2 = room:askForPlayerChosen(player, players, self:objectName(), "wl_cuorui-choose", true, false)
					end

					if target2 then
						local ids = getIntList(target2:getHandcards())
						local id = ids:at(math.random(0, ids:length() - 1))
						room:showCard(target2, id)
						if GetColor(sgs.Sanguosha:getCard(id)) == GetColor(card) then
							room:obtainCard(player,id)
						end
					end
				end
			end
		end
		return false
	end
}

wulan:addSkill(wl_cuorui)

sgs.LoadTranslationTable{
["#wulan"] = "",
["wulan"] = "吳蘭",
["&wulan"] = "吳蘭",
["illustrator:wulan"] = "紫喬",

["wl_cuorui"] = "挫銳",
["@wl_cuorui"] = "你可以棄置一張牌並發動「挫銳」",
[":wl_cuorui"] = "出牌階段開始時，你可以棄置你或隊友區域裡的一張牌。若如此做，你選擇一項：1.棄置其他角色裝備區里至多兩張與此牌顏色相同的牌；2.展示其他的共計兩張手牌，然後獲得其中與此牌顏色相同的牌。",
["wl_cuorui1"] = "棄置其他角色裝備區里至多兩張與此牌顏色相同的牌",
["wl_cuorui2"] = "展示其他角色共計兩張手牌，然後獲得其中與此牌顏色相同的牌。",
["wl_cuorui-choose"] = "你可以展示一名角色的手牌。",
}

--賈充
jiachong = sgs.General(extension,"jiachong","qun2","4",true)

beiniCard = sgs.CreateSkillCard{
	name = "beini" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and not to_select:isKongcheng() and to_select:getHp() < sgs.Self:getHp()
	end,
	on_use = function(self, room, source, targets)	
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local choice = room:askForChoice(player, "beini", "beini1+beini2", data)
			if (choice == "beini1") then
				source:drawCards(2)
				if targets[1]:canSlash(source, nil, false) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("beini")
					room:useCard(sgs.CardUseStruct(slash, targets[1], source))
				end
			elseif (choice == "beini2") then
				targets[1]:drawCards(2)
				if source:canSlash(targets[1], nil, false) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("beini")
					room:useCard(sgs.CardUseStruct(slash, source, targets[1]))
				end
			end			
		end
	end
}

beini = sgs.CreateZeroCardViewAsSkill{
	name = "beini",
	view_as = function(self,cards)
		return beiniCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#beini") < 1
	end
}


dingfa = sgs.CreateTriggerSkill{
	name = "dingfa",
	global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				for _,id in sgs.qlist(move.card_ids) do
					room:addPlayerMark(player, "dingfa_lose_card_num-Clear")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("dingfa_lose_card_num-Clear") > 0 then
						local lose_num = p:getMark("dingfa_lose_card_num-Clear")
						if lose_num > 0 and lose_num >= p:getHp() and room:askForSkillInvoke(p, self:objectName(), data) then
							
							local _targets = sgs.SPlayerList()
							for _, p in sgs.qlist(room:getOtherPlayers(player)) do
								_targets:append(p)
							end
							_targets:append(player)
							if not _targets:isEmpty() then
								local target = room:askForPlayerChosen(player, _targets, "dingfa", "dingfa-hp", true)
								if target then
									room:notifySkillInvoked(player,"dingfa")
									if target:objectName() ~= player:objectName() then
										room:broadcastSkillInvoke(self:objectName(), 2)
										room:doAnimate(1, player:objectName(), target:objectName())
										room:damage(sgs.DamageStruct(self:objectName(), player, target ))
									else
										room:broadcastSkillInvoke(self:objectName())
										room:recover(player, sgs.RecoverStruct(player))
									end
								else
									room:broadcastSkillInvoke(self:objectName())
									room:recover(player, sgs.RecoverStruct(player))
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

jiachong:addSkill(beini)
jiachong:addSkill(dingfa)

sgs.LoadTranslationTable{
["jiachong"] = "賈充",
["beini"] = "悖逆",
[":beini"] = "出牌階段限一次，你可以選擇一名體力值不小於你的角色，令你或其摸兩張牌，然後未摸牌的角色視為對摸牌的角色使用一"..
"張【殺】。",
["dingfa"] = "定法",
[":dingfa"] = "棄牌階段結束時，若本回合你失去的牌數不小於你的體力值，你可以選擇一項：1、回復1點體力；2、對一名其他角色造成"..
"1點傷害。 ",
}

--朵思大王
duosidawang = sgs.General(extension,"duosidawang","qun2","4",true)

equan = sgs.CreateTriggerSkill{
	name = "equan",
	events = {sgs.Damaged,sgs.EventPhaseStart,sgs.EnterDying},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.Damaged then
			local currnet = room:getCurrent()
			local damage = data:toDamage()
			if currnet:hasSkill(self:objectName()) then
				room:addPlayerMark(player,"@equan",damage.damage)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and RIGHT(self, player) then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("@equan") > 0 then
						room:setPlayerFlag(p,"equan_lose_effect")
						room:loseHp(p, p:getMark("@equan"))
						room:setPlayerFlag(p,"-equan_lose_effect")
					end
				end
			end
		elseif event == sgs.EnterDying then
			if player:hasFlag("equan_lose_effect") then
				room:setPlayerMark(player, "skill_invalidity-Clear",1)
				room:setPlayerMark(player, "@skill_invalidity",1)
			end
		end
	end,
	can_trigger = function(self,target)
		return target:isAlive()
	end
}

manji = sgs.CreateTriggerSkill{
	name = "manji",
	events = {sgs.HpLost},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.HpLost then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("manji") then
					if p:getHp() <= player:getHp() then
						room:recover(p, sgs.RecoverStruct(p))
					end
					if p:getHp() >= player:getHp() then
						p:drawCards(1)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target:isAlive()
	end
}

duosidawang:addSkill(equan)
duosidawang:addSkill(manji)

sgs.LoadTranslationTable{
["duosidawang"] = "朵思大王",
["equan"] = "惡泉",
[":equan"] = "鎖定技。①當有角色於你的回合內受到傷害後，其獲得X枚「毒」（X為傷害值）。②準備階段，你令所有擁有「毒」標記的"
.."角色移去所有「毒」標記並失去等量的體力。③當有角色因〖惡泉②〗進入瀕死狀態時，你令其所有非鎖定技失效直到回合結束。",
["@poison"] = "毒",
["manji"] = "蠻汲",
[":manji"] = "鎖定技。其他角色失去體力後，若你的體力值：不大於該角色，你回復1點體力；不小於該角色，你摸一張牌。",
}

--吳班
wuban = sgs.General(extension,"wuban","shu2","4",true)

jintao = sgs.CreateTriggerSkill{
	name = "jintao",
	--events = {sgs.PreCardUsed,sgs.TargetSpecified, sgs.DamageCaused, sgs.CardFinished},
	events = {sgs.TargetSpecified, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		--[[
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getMark("used_slash_Play") == 0 then
				room:setCardFlag(use.card, "jintao1_Play")
			elseif player:getMark("used_slash_Play") == 1 then
				room:setCardFlag(use.card, "jintao2_Play")
			end
			]]--
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() and use.from:hasSkill(self:objectName()) and use.card:isKindOf("Slash") and use.card:hasFlag("second_slash-Clear") then
				local index = 1
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				room:broadcastSkillInvoke(self:objectName())
				local msg = sgs.LogMessage()
				msg.type = "#Jintao1"
				msg.from = player

				for _, p in sgs.qlist(use.to) do
					if not player:isAlive() then break end
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						msg.to:append(p)
						jink_table[index] = 0
					end
				end
						
				msg.arg = self:objectName()
				msg.arg2 = use.card:objectName()
				room:sendLog(msg)

				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.by_user and not damage.chain and not damage.transfer and damage.card:hasFlag("first_slash-Clear") then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#Jintao2"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
			end
			--[[
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("jintao1_Play") then
				room:setCardFlag(use.card, "-jintao1_Play")
			end
			if use.card:hasFlag("jintao2_Play") then
				room:setCardFlag(use.card, "-jintao2_Play")
			end
			]]--
		end
		return false
	end
}

jintaoTargetMod = sgs.CreateTargetModSkill{
	name = "#jintaoTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("jintao") then
			return 1
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill("jintao") then
			return 1000
		else
			return 0
		end
	end,
}

wuban:addSkill(jintao)
wuban:addSkill(jintaoTargetMod)

sgs.LoadTranslationTable{
["wuban"] = "吳班",
["jintao"] = "進討",
[":jintao"] = "鎖定技，你使用【殺】無距離限制且次數上限+1。你於出牌階段內使用的第一張【殺】傷害+1，第二張【殺】不可被響應。",
	["#Jintao1"] = "%from 的技能 “<font color=\"yellow\"><b> %arg </b></font>”被觸發，%to 無法響應此 %arg2 ",
	["#Jintao2"] = "%from 的技能 “<font color=\"yellow\"><b>進討</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--樂就
yuejiu = sgs.General(extension,"yuejiu","qun2","4",true)
--催進
cuijin = sgs.CreateTriggerSkill{
	name = "cuijin",
	events = {sgs.CardUsed,sgs.CardFinished, sgs.ConfirmDamage},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if (use.from:inMyAttackRange(p) or use.from:objectName() == p:objectName()) and p:hasSkill("cuijin") then
						if room:askForCard(p, "..", "@cuijin", data, self:objectName()) then

							local promptlist = use.card:getTag("cuijin_buff"):toString():split(":")
							table.insert(promptlist, p:objectName() )
							use.card:setTag("cuijin_buff", sgs.QVariant( table.concat(promptlist,":")))
						end
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				local promptlist = damage.card:getTag("cuijin_buff"):toString():split(":")
				if #promptlist > 0 then
					local log = sgs.LogMessage()
					log.type = "$kannan"
					log.from = player
					log.card_str = damage.card:toString()
					log.arg = self:objectName()
					log.arg2 = #promptlist
					room:sendLog(log)
					damage.damage = damage.damage + #promptlist
					data:setValue(damage)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				local dmgpromptlist = use.card:getTag("cuijin_buff"):toString():split(":")
				if not use.card:hasFlag("damage_record") then
					for _, dmger in ipairs(dmgpromptlist) do
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:objectName() == dmger then
								room:doAnimate(1, p:objectName(), player:objectName())
								room:damage(sgs.DamageStruct(nil,p,player,1,sgs.DamageStruct_Normal))
							end
						end
					end
				end
				if use.card:getTag("cuijin_buff") then
					use.card:removeTag("cuijin_buff")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

yuejiu:addSkill(cuijin)

sgs.LoadTranslationTable{
["yuejiu"] = "樂就",
["#yuejiu"] = "仲軍家督",
["cuijin"] = "催進",
[":cuijin"] = "當你或你攻擊範圍內的角色使用【殺】時，你可以棄置一張牌並獲得如下效果：此【殺】的傷害值基數+1，且當此【殺】"
.."結算結束後，若未造成過傷害，則你對使用者造成1點傷害。",
["@cuijin"] = "你可以棄置一張牌並發動「催進」",
}

--[[
曹洪
〖援護〗出牌階段限一次，你可以將一張裝備牌置入一名角色的裝備區里，然後根據此牌的副類別執行以下效果：武器牌，你棄置與該角色距離為1的一名角色區域里的一張牌；防具牌，該角色摸一張牌；坐騎牌，該角色回復1點體力。若你「援護」選擇的目標體力值或手牌數不大於你，則你可摸一張牌，然後於本回合結束階段可再發動此技能。

〖決助〗限定技，準備階段，你可以廢除一個坐騎欄，令一名角色獲得技能「飛影」並廢除其判定區。你「決助」選擇的角色死亡後，你恢復因此技能廢除的坐騎欄。

☆〖飛影〗鎖定技，其他角色計算與你的距離+1。
juezhu 
]]--
ol_caohong = sgs.General(extension, "ol_caohong", "wei2", "4",true)

ol_yuanhuCard = sgs.CreateSkillCard{
	name = "ol_yuanhu",
	will_throw = false ,
	mute = true,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if #targets ~= 0 then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local room = source:getRoom()
		room:moveCardTo(self, source, effect.to, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "ol_yuanhu", ""))
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())

		--配音
		if string.find(effect.to:getGeneralName(), "caocao") then
			room:broadcastSkillInvoke("yuanhu",4)
		elseif effect.from:objectName() == effect.to:objectName() then
			room:broadcastSkillInvoke("yuanhu",5)
		else
			if card:isKindOf("Weapon") then
				room:broadcastSkillInvoke("yuanhu",1)
			elseif card:isKindOf("Armor") then
				room:broadcastSkillInvoke("yuanhu",2)
			elseif card:isKindOf("Horse") then
				room:broadcastSkillInvoke("yuanhu",3)
			end
		end

		if (effect.to:getHandcardNum() <= effect.from:getHandcardNum()) or (effect.to:getHp() <= effect.from:getHp()) then
			effect.from:drawCards(1, "ol_yuanhu")
			room:addPlayerMark(effect.from,"ol_yuanhu-Clear")
		end

		if card:isKindOf("Weapon") then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if effect.to:distanceTo(p) == 1 and source:canDiscard(p, "hej") then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local to_dismantle = room:askForPlayerChosen(source, targets, "ol_yuanhu", "@yuanhu-discard:"..effect.to:objectName())
				local card_id = room:askForCardChosen(source, to_dismantle, "hej", "ol_yuanhu", false, sgs.Card_MethodDiscard)
				room:throwCard(sgs.Sanguosha:getCard(card_id), to_dismantle, source)
			end
		elseif card:isKindOf("Armor") then
			effect.to:drawCards(1, "ol_yuanhu")
		elseif card:isKindOf("Horse") then
			room:recover(effect.to, sgs.RecoverStruct(source))
		end

	end
}
ol_yuanhuVS = sgs.CreateOneCardViewAsSkill{
	name = "ol_yuanhu",
	filter_pattern = "EquipCard",
	response_pattern = "@@ol_yuanhu",
	view_as = function(self, card)
		local first = ol_yuanhuCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ol_yuanhu") and not player:isNude()
	end,
}
ol_yuanhu = sgs.CreatePhaseChangeSkill{
	name = "ol_yuanhu",
	view_as_skill = ol_yuanhuVS,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish and (not player:isNude()) and player:getMark("ol_yuanhu-Clear") > 0 then
			player:getRoom():askForUseCard(player, "@@ol_yuanhu", "@yuanhu-equip", -1, sgs.Card_MethodNone)
		end
		return false
	end
}

juezhu = sgs.CreateTriggerSkill{
	name = "juezhu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@juezhu",
	events = {sgs.EventPhaseStart,sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("@juezhu") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:removePlayerMark(player, "@juezhu")
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("ol_caohong","juezhu")
					local choice = ChooseThrowEquipArea(self, player,false,false)
					throwEquipArea(self,player, choice)
					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "juezhu", "juezhu-invoke")
					if s then
						room:handleAcquireDetachSkills(s,"feiying")
						room:addPlayerMark(player,"juezhu"..s:objectName())
						room:addPlayerMark(player,"juezhu".. string.sub(choice, 8, string.len(choice) ) )
						room:addPlayerMark(s, "@AbolishJudge")
					end
				end
			end
		else
			local death = data:toDeath()
			local splayer = death.who
			if player:isAlive() and player:getMark("juezhu"..splayer:objectName()) > 0 then
				room:removePlayerMark(player,"juezhu"..splayer:objectName())
				for _, mark in sgs.list(player:getMarkNames()) do
					if player:getMark(mark) > 0 and string.find(mark, "juezhu") then
						local msg = sgs.LogMessage()
						msg.type = "#Recover1Equip"
						msg.from = player
						msg.to:append(player)
						msg.arg = self:objectName()
						msg.arg2 = "Recover"..string.sub(mark, 7, string.len(mark) )
						room:sendLog(msg)
						room:setPlayerMark(player,"@Abolish"..string.sub(mark, 7, string.len(mark) ),0)
					end
				end
			end
		end
		return false
	end,
}

ol_caohong:addSkill(ol_yuanhu)
ol_caohong:addSkill(juezhu)

sgs.LoadTranslationTable{
["#ol_caohong"] = "福將",
["ol_caohong"] = "OL曹洪",
["&ol_caohong"] = "曹洪",
["illustrator:ol_caohong"] = "LiuHeng",
["ol_yuanhu"] = "援護",
[":ol_yuanhu"] = "出牌階段限一次，你可以將一張裝備牌置入一名角色的裝備區里，然後根據此牌的副類別執行以下效果：武器牌，你棄置與該角色距離為1的一名角色區域里的一張牌；防具牌，該角色摸一張牌；坐騎牌，該角色回復1點體力。若你「援護」選擇的目標體力值或手牌數不大於你，則你可摸一張牌，然後於本回合結束階段可再發動此技能。",
["@ol_yuanhu-equip"] = "你可以發動“援護”",
["@ol_yuanhu-discard"] = "請選擇 %src 距離1的一名角色",
["~ol_yuanhu"] = "選擇一張裝備牌→選擇一名角色→點擊確定",

["cv:ol_caohong"] = "喵小林",
["$ol_yuanhu1"] = "持吾兵戈，隨我殺敵！", --武器
["$ol_yuanhu2"] = "汝今勢微，吾當助汝。", --防具
["$ol_yuanhu3"] = "公急上馬，洪敵賊軍！", --坐騎
["$ol_yuanhu4"] = "天下可無洪，不可無公。", --曹操
["$ol_yuanhu5"] = "持戈整兵，列陣禦敵！", --自己
["~ol_caohong"] = "主公已安，洪縱死亦何惜……",

["juezhu"] = "決助",
[":juezhu"] = "限定技，準備階段，你可以廢除一個坐騎欄，令一名角色獲得技能「飛影」並廢除其判定區。你「決助」選擇的角色死亡後，你恢復因此技能廢除的坐騎欄。",
["juezhu-invoke"] = "選擇一名角色獲得技能「飛影」並廢除其判定區",

["feiying"] = "飛影",
[":feiying"] = "鎖定技。其他角色與你的距離+1",
}

--馬雲祿 
tw_mayunlu = sgs.General(extension, "tw_mayunlu", "shu2", "4", false, true)
--鳳魄
tw_fengpo = sgs.CreateTriggerSkill{
	name = "tw_fengpo",
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to:length() == 1 and player:getPhase() ~= sgs.Player_NotActive then
				for _, p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if player:askForSkillInvoke(self:objectName(), _data) then
							room:showAllCards(p,player)
							room:doAnimate(1, player:objectName(), p:objectName())
							room:notifySkillInvoked(player, "tw_fengpo")
							room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
							local choices = {"fengpo1", "fengpo2"}
							local choice = room:askForChoice(player, "tw_fengpo", table.concat(choices, "+"))
							local n = 0
							local msg1 = sgs.LogMessage()
							msg1.type = "#MakeChoice"
							msg1.from = player
							msg1.arg = "tw_fengpo"
							msg1.arg2 = choice
							room:sendLog(msg1)
							--room:showAllCards(p)
							for _, card in sgs.qlist(p:getHandcards()) do
								if card:getSuit() == sgs.Card_Diamond then
									n = n + 1 
								end
							end
							if choice == "fengpo2" then
								use.card:setTag("tw_fengpoBuffed", sgs.QVariant(n))
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

tw_mayunlu:addSkill("mashu")
tw_mayunlu:addSkill(tw_fengpo)

sgs.LoadTranslationTable{
	["tw_mayunlu"] = "TW馬雲祿",
	["#tw_mayunlu"] = "戰場的少女",
	["&tw_mayunlu"] = "馬雲祿",
	["tw_fengpo"] = "鳳魄",
	["fengpo1"] = "摸X張牌",
	["fengpo2"] = "此牌造成的傷害+X。",
	[":tw_fengpo"] = "你在回合內使用第一張【殺】或【決鬥】指定一個目標後，你可以選擇一項：1.摸X張牌；2.此牌造成的傷害+X。 （X為其方塊手牌數）",
	["#tw_fengpo"] = "%from 發動技能 “<font color=\"yellow\"><b>鳳魄</b></font>”，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}



