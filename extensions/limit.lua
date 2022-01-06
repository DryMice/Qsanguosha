module("extensions.limit", package.seeall)
extension = sgs.Package("limit")

sgs.LoadTranslationTable{
	["limit"] =  "界限突破武將",
}

local skills = sgs.SkillList()

--黃忠
huangzhong_po = sgs.General(extension, "huangzhong_po", "shu2",4,true,true)

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

liegong_po = sgs.CreateTriggerSkill{
	name = "liegong_po", 
	events = {sgs.TargetSpecified, sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if event == sgs.TargetSpecified and player:objectName() == use.from:objectName() and use.from:hasSkill(self:objectName()) and use.card:isKindOf("Slash") and player:getMark("liegong_play") == 0 and player:getPhase() == sgs.Player_Play then
			local index = 1
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			for _, p in sgs.qlist(use.to) do
				if not player:isAlive() or player:getMark("liegong_play") ~= 0  then break end
				local invoke = 0
				if p:getAttackRange() <= player:getAttackRange() then
					invoke = invoke+1
				end
				if p:getHandcardNum() >= player:getHandcardNum() then
					invoke = invoke+1
				end
				if p:getHp() >= player:getHp() then
					invoke = invoke+1
				end
				room:addPlayerMark(player, "liegong_play")	
				local _data = sgs.QVariant()
				_data:setValue(p)
				if invoke >= 1 and room:askForSkillInvoke(player, self:objectName(), _data) then
					jink_table[index] = 0
					if invoke >= 2 then
						room:setCardFlag(use.card, "liegong_play"..p:objectName())	
					end
				end
				index = index+1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("liegong_play"..damage.to:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#Hanyong"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
			end
		end
		return false
	end
}
huangzhong_po:addSkill(liegong_po)

sgs.LoadTranslationTable{
["huangzhong_po"] = "Po黃忠",
["&huangzhong_po"] = "黃忠",
["#huangzhong_po"] = "老當益壯",
["liegong_po"] = "烈弓",
[":liegong_po"] = "當你於出牌階段內使用【殺】指定一個目標後，若滿足下列條件中（1.其攻擊範圍不大於你；2.其手牌數不小於你；3 .其體力值不小於你）：至少1條，你可以令其不能使用【閃】響應此【殺】；至少2條，當此【殺】對其造成傷害時，你可以令傷害值+1 。每階段限一次。",
["$liegong_po1"] = "",
["$liegong_po2"] = "",
["~huangzhong_po"] = "",
}

--孫堅
sunjian_po = sgs.General(extension, "sunjian_po", "wu2",4,true,true)
--英魂
yinghun_po = sgs.CreatePhaseChangeSkill{
	name = "yinghun_po", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:isWounded() then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yinghun-invoke", true, true)
			local x = player:getLostHp()
			if player:getEquips():length() >= player:getHp() then
				x = player:getMaxHp()
			end
			local choices = {"yinghun1"}
			if to then
				if not to:isNude() and x ~= 1 then
					table.insert(choices, "yinghun2")
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice == "yinghun1" then
					to:drawCards(1)
					room:askForDiscard(to, self:objectName(), x, x, false, true)
				else
					to:drawCards(x)
					room:askForDiscard(to, self:objectName(), 1, 1, false, true)
				end
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
sunjian_po:addSkill(yinghun_po)

sgs.LoadTranslationTable{
["sunjian_po"] = "界孫堅",
["&sunjian_po"] = "孫堅",
["#sunjian_po"] = "武烈帝",
["yinghun_po"] = "英魂",
[":yinghun_po"] = " 準備階段開始時，若你已受傷，你可以選擇一名其他角色，然後選擇一項：1.令其摸一張牌，然後棄置X張牌；2.令其摸X張牌，然後棄置一張牌。（若你的裝備區裡的牌數不小於體力值，X為你的體力上限，否則X為你已損失的體力值）",
["$yinghun_po1"] = "",
["$yinghun_po2"] = "",
["~sunjian_po"] = "",
}

--曹節
caojie_po = sgs.General(extension, "caojie_po", "qun2", 3, false, true)
zuyin = sgs.CreateTriggerSkill{
	name = "zuyin", 
	events = {sgs.TargetConfirmed, sgs.CardEffected}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			for _, p in sgs.qlist(use.to) do
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player and player:isAlive() and player:hasSkill(self:objectName()) and p:objectName() ~= use.from:objectName() and use.from:objectName() ~= player:objectName() and (use.card:isKindOf("Slash") or use.card:isNDTrick()) and player:distanceTo(p) < 2 and room:askForSkillInvoke(player, self:objectName(), _data) then
					local ids = sgs.IntList()
					for _, id in sgs.qlist(room:getDrawPile()) do
						if not sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
							ids:append(id)
							break
						end
					end
					if not ids:isEmpty() then
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = player
						move.to_place = sgs.Player_PlaceTable
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
						room:moveCardsAtomic(move, true)
						local card = sgs.Sanguosha:getCard(ids:first())
						if card:getSuit() == use.card:getSuit() then
							room:addPlayerMark(p, self:objectName().."-Clear", use.card:getId())
							room:setCardFlag(use.card, self:objectName())
							room:throwCard(card, nil, nil)
						else
							player:obtainCard(card)
						end
					end
				end
			end
		else
			local effect = data:toCardEffect()
			if effect.card:hasFlag(self:objectName()) and (effect.card:isKindOf("Slash") or effect.card:isNDTrick()) and effect.to:getMark(self:objectName().."-Clear") == effect.card:getId() then
				room:setPlayerMark(effect.to, self:objectName().."-Clear", 0)
				return true 
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
caojie_po:addSkill(zuyin)

cjtianzuoEXCard = sgs.CreateSkillCard{
	name = "cjtianzuoEX", 
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("cjtianzuo") and (not to_select:getEquips():isEmpty() or not to_select:getJudgingArea():isEmpty())
	end, 
	on_use = function(self, room, source, targets)
		local players = sgs.SPlayerList()
		for i = 1, #targets do
			if not targets[i]:isNude() then
				local id = room:askForCardChosen(source, targets[i], "ej", "cjtianzuo", false, sgs.Card_MethodDiscard)
				if room:getCardPlace(id) == sgs.Player_PlaceEquip then
					room:addPlayerMark(targets[i], "cjtianzuoEX")
				end
				room:throwCard(id, targets[i], source)
			end
		end
		for _, player in sgs.qlist(room:getAlivePlayers()) do
			if player:getMark("cjtianzuoEX") > 0 then
				room:removePlayerMark(player, "cjtianzuoEX")
				if player:isWounded() then
					room:recover(player, sgs.RecoverStruct(source))
				end
			end
		end
	end
}
cjtianzuoEX = sgs.CreateZeroCardViewAsSkill{
	name = "cjtianzuoEX", 
	response_pattern = "@@cjtianzuoEX", 
	view_as = function()
		return cjtianzuoEXCard:clone()
	end
}

cjtianzuo = sgs.CreatePhaseChangeSkill{
	name = "cjtianzuo", 
	frequency = sgs.Skill_Compulsory, 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getHandcardNum() > player:getHp() then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, card in sgs.qlist(player:getHandcards()) do
				if not card:isKindOf("BasicCard") then
					dummy:addSubcard(card:getId())
				end
			end
			room:throwCard(dummy, player, player)
			room:addPlayerMark(player, self:objectName(), dummy:subcardsLength())
			room:askForUseCard(player, "@@cjtianzuoEX", "@cjtianzuoEX")
			room:setPlayerMark(player, self:objectName(), 0)
		end
		return false
	end
}
caojie_po:addSkill(cjtianzuoEX)
caojie_po:addSkill(cjtianzuo)

sgs.LoadTranslationTable{
["caojie_po"] = "曹節",
["zuyin"] = "族蔭",
[":zuyin"] = "當一名角色成為另一名其他角色使用【殺】或非延時類錦囊牌的目標後，若你與其距離不大於1，你可以展示牌堆頂一張非基本牌，若之與此牌花色：相同，此牌對其無效；不同，你獲得之。",
["cjtianzuo"] = "天祚",
["cjtianzuoEX"] = "天祚",
[":cjtianzuo"] = "鎖定技，準備階段開始時，若你的手牌數大於體力值，你棄置其中所有非基本牌，然後選擇至多X名裝備區或判定區裡有牌的角色，棄置這些角色裝備區或判定區裡各一張牌，然後以此法棄置裝備區裡的牌的角色回复1點體力。",
}

--界劉備
super_liubei = sgs.General(extension, "super_liubei$", "shu", "4", true)
--仁德：出牌階段每名角色限一次，你可以將任意張手牌交給一名其他角色。當你於本階段以此法給出第二張牌時，你可以視為使用一張基本牌（視為使用【殺】有距離限制且計入出牌階段使用限制）。 
ol_rendeCard = sgs.CreateSkillCard{
	name = "ol_rende", 
	will_throw = false, 
	mute = true,
	handling_method = sgs.Card_MethodNone, 
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName() and (not sgs.Self:hasUsed("#ol_rende") or  to_select:getMark(self:objectName().."_Play") == 0)
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:addPlayerMark(source, self:objectName().."_Play", self:getSubcards():length())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "ol_rende", "")
			room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)
			room:addPlayerMark(targets[1], self:objectName().."_Play")
			if source:getMark(self:objectName().."_Play") >= 2 and not source:hasFlag(self:objectName()) then
				source:setFlags(self:objectName())
				local Set = function(list)
					local set = {}
					for _, l in ipairs(list) do set[l] = true end
					return set
				end
				local basic = {"slash", "peach", "cancel"}
				if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
					table.insert(basic, 2, "thunder_slash")
					table.insert(basic, 2, "fire_slash")
					table.insert(basic, "analeptic")
				end
				for _, patt in ipairs(basic) do
					local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
					if poi and (not poi:isAvailable(source)) or (patt == "peach" and not source:isWounded()) then
					table.removeOne(basic, patt)
					if patt == "slash" then
						table.removeOne(basic, "thunder_slash")
						table.removeOne(basic, "fire_slash")
					end
					end
				end
				local choice = room:askForChoice(source, self:objectName(), table.concat(basic, "+"))
				if choice ~= "cancel" then
					room:setPlayerProperty(source, "ol_rende", sgs.QVariant(choice))
					room:askForUseCard(source, "@@ol_rende", "@ol_rende", -1, sgs.Card_MethodUse)
					room:setPlayerProperty(source, "ol_rende", sgs.QVariant())
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end, 
}
ol_rende = sgs.CreateViewAsSkill{
	name = "ol_rende", 
	n = 999, 
	response_pattern = "@@ol_rende", 
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ol_rende" then return false end
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@ol_rende" then
			if #cards == 0 then
				local name = sgs.Self:property("ol_rende"):toString()
				local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
				card:setSkillName("_ol_rende")
				return card
			end
		else
			if #cards > 0 then
				local rende = ol_rendeCard:clone()
				for _, c in ipairs(cards) do
				rende:addSubcard(c)
				end
				rende:setSkillName("ol_rende")
				return rende
			end
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end
}

super_liubei:addSkill(ol_rende)
super_liubei:addSkill("jijiang")

sgs.LoadTranslationTable{
	["super_liubei"] = "界劉備",
	["&super_liubei"] = "劉備",
	["#super_liubei"] = "漢昭烈帝",
	["ol_rende"] = "仁德",
	[":ol_rende"] = "出牌階段每名角色限一次，你可以將任意張手牌交給一名其他角色。當你於本階段以此法給出第二張牌時，你可以視為使用一張基本牌（視為使用【殺】有距離限制且計入出牌階段使用限制）。",
	["@ol_rende"] = "你可以使用殺",
	["~ol_rende"] = "選擇一名角色→點擊確定",
	["$ol_rende1"] = "仁德之君，则所向披靡也",
	["$ol_rende2"] = "上报国家，下安黎庶",
}

--界香香
sunshangxiang_po = sgs.General(extension,"sunshangxiang_po","wu","3",false)
--〖結姻〗：出牌階段限一次，選擇一名男性角色，棄置一張手牌或將一張裝備牌置入其裝備區：你與其體力值較高者摸一張牌，體力值較低者回復 1 點體力。 
jieyin_poCard = sgs.CreateSkillCard{
	name = "jieyin_poCard", 
	target_fixed = false, 
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:isMale()
	end, 
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:isKindOf("EquipCard") then
			local equip = card:getRealCard():toEquipCard()
			local equip_index = equip:location()
			if card:isEquipped() and targets[1]:getEquip(equip_index) == nil then
				room:moveCardTo(self, source, targets[1], sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "jieyin_po", ""))
			elseif card:isKindOf("EquipCard") and targets[1]:getEquip(equip_index) == nil then
				room:moveCardTo(self, source, targets[1], sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "jieyin_po", ""))
			else
				room:throwCard(self,source,source)
			end
		else
			room:throwCard(self,source,source)
		end
		if source:getHp() > targets[1]:getHp() then
			source:drawCards(2)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(targets[1], recover)
		elseif source:getHp() < targets[1]:getHp() then
			source:drawCards(1)
			targets[1]:drawCards(1)
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
	end
}
jieyin_po = sgs.CreateViewAsSkill{
	name = "jieyin_po", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = jieyin_poCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#jieyin_poCard"))
	end
}

sunshangxiang_po:addSkill(jieyin_po)
sunshangxiang_po:addSkill("xiaoji")

sgs.LoadTranslationTable{
	["sunshangxiang_po"] = "新孫尚香",
	["&sunshangxiang_po"] = "孫尚香",
	["jieyin_po"] = "結姻",
	[":jieyin_po"] = "出牌階段限一次，妳可以選擇一名男性角色，然後棄置一張手牌或將一張裝備牌置入該角色的裝備區：你與其體力值較高者摸一張牌，體力值較低者回復一點體力。 ",
}

--新趙雲
zhaoyun_po = sgs.General(extension, "zhaoyun_po", "shu2")
--涯角
yajiao_po = sgs.CreateTriggerSkill {
	name = "yajiao_po",
	events = {sgs.CardUsed, sgs.CardResponded},
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_NotActive then return end
		local room = player:getRoom()

		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end

		if not card or (card:getHandlingMethod() ~= sgs.Card_MethodUse and card:getHandlingMethod() ~= sgs.Card_MethodResponse) then return end

		if card:getTypeId() == sgs.Card_TypeSkill then return end

		if card:isVirtualCard() and card:subcardsLength() == 0 then return end

		if not player:askForSkillInvoke(self:objectName(), data) then return end

		local ids = room:getNCards(1, false)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
		local move = sgs.CardsMoveStruct(ids, player, sgs.Player_PlaceTable, reason)
		room:moveCardsAtomic(move, true)

		room:setPlayerMark(player,"yajiao",ids:first())
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "yajiao", "@yajiao_po-give:"..sgs.Sanguosha:getCard(ids:first()):objectName(), true, true)
		if target then
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:obtainCard(target, ids:first())
			if sgs.Sanguosha:getCard(ids:first()):getTypeId() ~= card:getTypeId() then
				room:askForDiscard(player, self:objectName(), 1, 1, false, true)
			end
		else
			reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
			move = sgs.CardsMoveStruct(ids, nil, sgs.Player_DrawPile, reason)
			room:moveCardsAtomic(move, true)
		end
		return false
	end
}
zhaoyun_po:addSkill(yajiao_po)
zhaoyun_po:addSkill("longdan")

sgs.LoadTranslationTable{
	["zhaoyun_po"] = "新趙雲",
	["&zhaoyun_po"] = "趙雲",
	["#zhaoyun_po"] = "虎威將軍",
	["yajiao_po"] = "涯角",
	[":yajiao_po"] = "當你於回合外使用或打出手牌時，你可以展示牌堆頂的一張牌並將其交給一名角色。若這兩張牌類別不同，你棄置一張牌",
	["@yajiao_po-give"] = "你可以令一名角色獲得 %src ",
}

--新張遼
zhangliao_po = sgs.General(extension, "zhangliao_po", "wei2")
--突襲
tuxi_poCard = sgs.CreateSkillCard{
	name = "tuxi_poCard",
	filter = function(self, targets, to_select)
		if #targets >= sgs.Self:getMark("tuxi_po") or to_select:objectName() == sgs.Self:objectName() then return false end
		return not to_select:isKongcheng()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("tuxi_poTarget")
	end
}
tuxi_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "tuxi_po",
	response_pattern = "@@tuxi_po",
	view_as = function() 
		return tuxi_poCard:clone()
	end
}
tuxi_po = sgs.CreateTriggerSkill{
	name = "tuxi_po" ,
	view_as_skill = tuxi_poVS,
	priority = -1,	
	events = {sgs.DrawNCards,sgs.AfterDrawNCards},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() > 0 then
					targets:append(p)
				end
			end
			local n = data:toInt()
			local num = math.min(targets:length(), n )
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				p:setFlags("-tuxi_poTarget")
			end
			if num > 0 then
				room:setPlayerMark(player, "tuxi_po", num)
				local count = 0
				if room:askForUseCard(player, "@@tuxi_po", "@tuxi-card:::" .. tostring(num)) then
					room:broadcastSkillInvoke("tuxi")
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:hasFlag("tuxi_poTarget") then
							count = count + 1
						end
					end
				else 
					room:setPlayerMark(player, "tuxi_po", 0)
				end
				data:setValue(n - count)
			else
				data:setValue(n)
			end
		else
			if player:getMark("tuxi_po") == 0 then return false end
			room:setPlayerMark(player, "tuxi_po", 0)
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("tuxi_poTarget") then
					p:setFlags("-tuxi_poTarget")
					targets:append(p)
				end
			end
			for _, p in sgs.qlist(targets) do
				if not player:isAlive() then
					break
				end
				if p:isAlive() and not p:isKongcheng() then
					local card_id = room:askForCardChosen(player, p, "h", "tuxi_po")
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
				end
			end
			return false
		end
	end,
}

zhangliao_po:addSkill(tuxi_po)

sgs.LoadTranslationTable{
	["zhangliao_po"] = "新張遼",
	["&zhangliao_po"] = "張遼",
	["#zhangliao_po"] = "前將軍",
["tuxi_po"] = "突襲",
[":tuxi_po"] = "摸牌階段，你可以少摸至少一張牌並選擇等量的其他角色：若如此做，你依次獲得這些角色各一張手牌。",
["@tuxi-card"] = "你可以發動“突襲”選擇至多 %arg 名其他角色",
["~tuxi_po"] = "選擇若干名其他角色→點擊確定",
}

--新黃月英 新月月
huangyueying_po = sgs.General(extension, "huangyueying_po", "shu2",3,false)
--集智
jizhi_po = sgs.CreateTriggerSkill{
	name = "jizhi_po" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (use.card:isNDTrick()) then
				if not (player:getMark("JilveEvent") > 0) then
					if not room:askForSkillInvoke(player, self:objectName()) then return false end
				end
				room:notifySkillInvoked(player, self:objectName())
				if player:hasSkill("jueyan") and player:getMark("jizhi_po_skillClear") > 0 then
					room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
				else
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				end
				local ids = room:getNCards(1, false)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local id = ids:first()
				local card = sgs.Sanguosha:getCard(id)
				player:obtainCard(card)
				if card:isKindOf("BasicCard") then
						local card_data = sgs.QVariant()
						card_data:setValue(card)
						if not card:isKindOf("Peach") then
							player:setFlags("jizhi_poGetPeach")
						end					
						if room:askForSkillInvoke(player, "jizhi_po_discard" ,card_data) then 
							room:throwCard(card, reason, nil)
							player:gainMark("@jizhi_hand-Clear",1)
						end
						player:setFlags("-jizhi_poGetPeach")
				end
			end
		end
		return false
	end
}

jizhi_poMax = sgs.CreateMaxCardsSkill{
	name = "#jizhi_po", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		--if target:hasSkill("jizhi_po") then
			return target:getMark("@jizhi_hand-Clear")
		--end
	end
}

huangyueying_po:addSkill(jizhi_po)
huangyueying_po:addSkill(jizhi_poMax)
huangyueying_po:addSkill("qicai")
extension:insertRelatedSkills("jizhi_po","#jizhi_po")

sgs.LoadTranslationTable{
	["huangyueying_po"] = "新黃月英",
	["&huangyueying_po"] = "黃月英",
	["#huangyueying_po"] = "歸隱的傑女",
	["jizhi_po"] = "集智",
	[":jizhi_po"] = "當你使用普通錦囊牌時，你可以摸一張牌。若此牌是基本牌，你可以棄置此牌然後本回合手牌上限+1。",
	["jizhi_po_discard"] = "集智棄牌",
	["@jizhi_hand-Clear"] = "集智",
}

--新夏侯惇
xiahoudun_po = sgs.General(extension, "xiahoudun_po", "wei2")
--新清儉
function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

qingjian_po = sgs.CreateTriggerSkill{
	name = "qingjian_po",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not room:getTag("FirstRound"):toBool()) and player:getPhase() ~= sgs.Player_Draw and move.to and move.to:objectName() == player:objectName() and player:getMark("qingjian_used-Clear") == 0 then
				local ids = sgs.IntList()
				for _,id in sgs.qlist(move.card_ids) do
					if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then
						ids:append(id)
					end
				end
				if ids:isEmpty() then return false end	
				player:setTag("QingjianCurrentMoveSkill", sgs.QVariant(move.reason.m_skillName))
				room:setPlayerFlag(player, "qingjian_poMove")
				if room:askForYiji(player, getIntList(player:getCards("he")), self:objectName(), false, false, true, -1, sgs.SPlayerList(), sgs.CardMoveReason(), "@qingjian-distribute", true) then
					room:setPlayerMark(player, "qingjian_used-Clear", 1)
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
				end
			end
			if player:hasFlag("qingjian_poMove") then
				local current = room:getCurrent()
				local cardtype = {}
				for i=0, (move.card_ids:length()-1), 1 do
					local card_id = move.card_ids:at(i)
					local card = sgs.Sanguosha:getCard(card_id)
					local newtype = true
					if #cardtype > 0 then
						for _, value in pairs(cardtype) do
							if value == card:getTypeId() then
								newtype = false
							end
						end
						if newtype then
							table.insert(cardtype, card:getTypeId())
						end
					else
						table.insert(cardtype, card:getTypeId())
					end
				end
				room:setPlayerMark(current, "@qingjian_hand-Clear", #cardtype)
				room:setPlayerFlag(player, "-qingjian_poMove")
			end
		end
		return false
	end,
}

qingjian_poMax = sgs.CreateMaxCardsSkill{
	name = "#qingjian_po", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		return target:getMark("@qingjian_hand-Clear")
	end
}

xiahoudun_po:addSkill(qingjian_po)
xiahoudun_po:addSkill(qingjian_poMax)

xiahoudun_po:addSkill("ganglie")
extension:insertRelatedSkills("qingjian_po","#qingjian_po")

sgs.LoadTranslationTable{
	["xiahoudun_po"] = "新夏侯惇",
	["&xiahoudun_po"] = "夏侯惇",
	["#xiahoudun_po"] = "獨眼的羅剎",
	["qingjian_po"] = "清儉",
	[":qingjian_po"] = "每回合限一次，當你於摸牌階段外獲得牌後，你可以展示任意張牌並交給一名其他角色。當前回合角色本回合手牌上限+X（X為你以此法展示的牌的類別數）",
	["@qingjian_po"] = "清儉",
}

--新關羽
guanyu_po = sgs.General(extension, "guanyu_po", "shu2")
--武聖
wusheng_po = sgs.CreateOneCardViewAsSkill{
	name = "wusheng_po",
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

--義絕
yijue_pocard = sgs.CreateSkillCard{
	name = "yijue_poCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return (to_select:objectName() ~= sgs.Self:objectName()) and not to_select:isKongcheng()
		end
		return false
	end ,
	on_use = function(self, room, source, targets)
		local card = room:askForCard(targets[1] ,".,!","@yijue_po-show",sgs.QVariant(), sgs.Card_MethodNone)
		room:showCard(targets[1], card:getEffectiveId())
		if card:isRed() then
			room:setPlayerFlag(targets[1],"YijueTarget")
			room:obtainCard(source, card, false)
			local choices = {"recover", "cancel"}
			local choice = room:askForChoice(source, "yijue_po", table.concat(choices, "+"))
			if choice == "recover" then
				local recover = sgs.RecoverStruct()
				recover.who = targets[1]
				room:recover(source, recover)
			end
			room:setPlayerFlag(targets[1],"-YijueTarget")

		elseif card:isBlack() then
			room:setPlayerCardLimitation(targets[1], "use,response", ".|.|.|hand", false)
			room:setPlayerMark(targets[1], "ban_ur", 1)
			room:addPlayerMark(targets[1], "skill_invalidity-Clear")
			room:addPlayerMark(targets[1], "@skill_invalidity")
			room:addPlayerMark(targets[1], "yijue_po"..source:objectName().."-Clear" )
		end
	end
}
yijue_po = sgs.CreateOneCardViewAsSkill{
	name = "yijue_po" ,
	filter_pattern = ".,Equip", 
	view_as = function(self,card)
		local cards = yijue_pocard:clone()
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#yijue_poCard") < 1
	end
}

wushengtm = sgs.CreateTargetModSkill{
	name = "#wushengtm" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("wusheng_po") and card:isKindOf("Slash") and card:getSuit() == sgs.Card_Diamond then
			return 1000
		end
		return 0
	end
}

guanyu_po:addSkill(wusheng_po)
guanyu_po:addSkill(wushengtm)
guanyu_po:addSkill(yijue_po)
extension:insertRelatedSkills("wusheng_po","#wushengtm")

sgs.LoadTranslationTable{
	["guanyu_po"] = "新關羽",
	["&guanyu_po"] = "關羽",
	["#guanyu_po"] = "武聖",
	["wusheng_po"] = "武聖",
	[":wusheng_po"] = "你可以將一張紅色牌當【殺】使用或打出；你使用方塊【殺】無距離限制。",
	["yijue_po"] = "義絕",
	[":yijue_po"] = "出牌階段限一次，你可以棄置一張牌，然後令一名其他角色展示一張手牌。若此牌為黑色，則其本回合非鎖定技失效且不能使用或打出手牌，你對其使用的紅桃【殺】傷害+1；若此牌為紅色，則你獲得之，然後你可令該角色回复1點體力。",
	["#yijue_po"] = "%from 觸發技能 “<font color=\"yellow\"><b>義絕</b></font>”，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
	["@yijue_po-show"] = "請展示一張手牌",
}

--新SP關羽

sp_guanyu_po = sgs.General(extension, "sp_guanyu_po", "wei2", "4", true)

sp_guanyu_po:addSkill(wusheng_po)
sp_guanyu_po:addSkill("jspdanqi")

sgs.LoadTranslationTable{
	["sp_guanyu_po"] = "新SP關羽",
	["&sp_guanyu_po"] = "關羽",
	["#sp_guanyu_po"] = "紫喬",
	["illustrator:jsp_guanyu"] = "Zero",
	["jspdanqi"] = "單騎",
	[":jspdanqi"] = "覺醒技。準備階段開始時，若你的手牌數大於你的體力值且主公不為劉備，你減1點體力上限，然後獲得“馬術”和“怒斬” 。",
	["nuzhan"] = "怒斬",
	[":nuzhan"] = "鎖定技。你使用的由一張錦囊牌轉化而來的【殺】不計入限制的使用次數；鎖定技。你使用的由一張裝備牌轉化而來的【殺】的傷害值基數+1。",
}

--新呂布
lvbu_po = sgs.General(extension, "lvbu_po", "qun2",5)

--利馭
liyu_po = sgs.CreateTriggerSkill{
	name = "liyu_po", 
	events = {sgs.Damage}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") and damage.to:isAlive() and (not damage.to:isNude()) then
					local _data = sgs.QVariant()
					_data:setValue(damage.to)
					if room:askForSkillInvoke(player, "liyu_po", _data) then
						room:broadcastSkillInvoke(self:objectName())
						local id = room:askForCardChosen(player, damage.to, "he", "liyu_po")
						room:obtainCard(player, id, true)
						local obcard = sgs.Sanguosha:getCard(id)
						if obcard and obcard:isKindOf("EquipCard") then
							local targets = sgs.SPlayerList()
							local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if not room:isProhibited(player, p, duel) and damage.to:objectName() ~= p:objectName() and player:objectName() ~= p:objectName() then
									targets:append(p)
								end
							end
							if targets:length() > 0 then
								local s = room:askForPlayerChosen(damage.to, targets, "liyu_po", "@liyu:"..player:objectName(), false, true)
								if s then
									room:broadcastSkillInvoke(self:objectName())
									room:doAnimate(1, player:objectName(),s:objectName())
									local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
									duel:setSkillName("liyu_po")
									local use = sgs.CardUseStruct()
									use.card = duel
									use.from = player
									local dest = s
									use.to:append(dest)
									room:useCard(use)
								end
							end
						else
							damage.to:drawCards(1)
						end
					end	
				end
			end		
		end
		return false
	end
}


lvbu_po:addSkill("wushuang")
lvbu_po:addSkill(liyu_po)

sgs.LoadTranslationTable{
	["lvbu_po"] = "新呂布",
	["&lvbu_po"] = "呂布",
	["#lvbu_po"] = "不敗戰神",
	["liyu_po"] = "利馭",
	[":liyu_po"] = "當你使用【殺】對一名其他角色造成傷害後，你可獲得其區域裡的一張牌。然後若獲得的牌不是裝備牌，其摸一張牌；若獲得的是裝備牌，則視為你對由其指定的另一名角色使用一張【決鬥】。",
	["@liyu"] = "請選擇一名其他角色視為 %src 對其使用一張【決鬥】",
}

--新南蠻夫婦
--孟獲
menghuo_po = sgs.General(extension, "menghuo_po", "shu2",4,true)

zaiqi_poCard = sgs.CreateSkillCard{
	name = "zaiqi_po",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("enter_discard_pile_red_card-Clear")
	end,
	on_use = function(self, room, source, targets)
		for i=1, #targets, 1 do
			local t = targets[i]
			local choices = {"zaiqi_draw"}
			if source:isWounded() then
				table.insert(choices,"zaiqi_recover")
			end
			local choice = room:askForChoice(t, "zaiqi_po", table.concat(choices, "+"))
			if choice == "zaiqi_recover" then
				local recover = sgs.RecoverStruct()
				recover.who = source
				room:recover(source, recover)
			elseif choice == "zaiqi_draw" then
				t:drawCards(1)
			end
		end	
	end
}
zaiqi_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "zaiqi_po",
	response_pattern = "@@zaiqi_po",
	view_as = function()
		return zaiqi_poCard:clone()
	end
}
zaiqi_po = sgs.CreateTriggerSkill{
	name = "zaiqi_po",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging} ,
	view_as_skill = zaiqi_poVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getMark("enter_discard_pile_red_card-Clear") > 0 and player:getPhase() == sgs.Player_Finish then
			room:askForUseCard(player, "@@zaiqi_po", "@zaiqi_po:::" .. tostring(player:getMark("enter_discard_pile_red_card-Clear")))
		end
	end
}


menghuo_po:addSkill("huoshou")
menghuo_po:addSkill(zaiqi_po)

sgs.LoadTranslationTable{
	["menghuo_po"] = "新孟獲",
	["&menghuo_po"] = "孟獲",
	["#menghuo_po"] = "南蠻王",
	["zaiqi_po"] = "再起",
	[":zaiqi_po"] = "棄牌階段開始時，你可以選擇一至X名角色，這些角色各選擇一項：1、摸一張牌；2、令你回復1點體力。（X為於此回合內置入棄牌堆的紅色牌數）",
	["@zaiqi_po"] = "你可以對選擇至多 %arg 名角色",
	["~zaiqi_po"] = "選擇若干名角色→點擊確定",
	["$zaiqi_po1"] = "",
	["$zaiqi_po2"] = "",
	["~menghuo_po"] = "",
	["zaiqi_draw"] = "摸一張牌",
	["zaiqi_recover"] = "令發起者回復1點體力",
}

--新祝融
zhurong_po = sgs.General(extension, "zhurong_po", "shu2",4,false)

--新烈刃
lieren_po = sgs.CreateTriggerSkill{
	name = "lieren_po" ,
	events = {sgs.TargetSpecified,sgs.Pindian} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				if not player:isKongcheng() and not p:isKongcheng() then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if player:askForSkillInvoke(self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName(),1)
						local success = player:pindian(p, "lieren_po", nil)
						if success then
							if not p:isNude() then
								room:broadcastSkillInvoke(self:objectName(),2)
								local id = room:askForCardChosen(player, p, "he", "lieren_po")
								room:obtainCard(player, id, true)
							end
						end
					end
				end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "lieren_po" and  pindian.to_number > pindian.from_number and pindian.from:objectName() == player:objectName() then
				if pindian.to_card:getNumber() > pindian.from_card:getNumber() then
					room:obtainCard(player, pindian.to_card, true)
				elseif pindian.to_card:getNumber() < pindian.from_card:getNumber() then
					room:obtainCard(player, pindian.from_card, true)
				end
			end
		end
	end
}

zhurong_po:addSkill(lieren_po)
zhurong_po:addSkill("juxiang")

sgs.LoadTranslationTable{
	["zhurong_po"] = "新祝融",
	["&zhurong_po"] = "祝融",
	["#zhurong_po"] = "野性的女王",
	["lieren_po"] = "烈刃",
	[":lieren_po"] = "當你使用【殺】指定一個目標後，你可以與其拼點：若你贏，你獲得其一張牌；若你沒贏，你可以獲得兩張拼點的牌中點數大的一張。 ",
	["$lieren_po1"] = "",
	["$lieren_po2"] = "",
	["~zhurong_po"] = "",
}

--新孫權
sunquan_po = sgs.General(extension, "sunquan_po$", "wu2", "4", true)
--新制衡
zhiheng_poCard = sgs.CreateSkillCard{
	name = "zhiheng_poCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			if source:hasSkill("tianxing") then
				room:broadcastSkillInvoke("zhiheng_po_audio",math.random(3,4))
			else
				room:broadcastSkillInvoke("zhiheng_po_audio",math.random(1,2))
			end

			local n = 0
			for _, id in sgs.qlist(self:getSubcards()) do
				if sgs.Sanguosha:getCard(id):hasFlag("zhiheng_po_handcard") then
					room:setCardFlag(id, "-zhiheng_po_handcard")
					n = n + 1
				end
			end

			for _,c in sgs.qlist(source:getHandcards()) do
				room:setCardFlag(c, "-zhiheng_po_handcard")
			end

			if source:getMark("zhiheng_po_handcard_num") == n then
				room:drawCards(source, self:subcardsLength() + 1, "zhiheng_po")
			else
				room:drawCards(source, self:subcardsLength(), "zhiheng_po")
			end

			room:setPlayerMark(source,"zhiheng_po_handcard_num",0)
		end
	end
}
zhiheng_po = sgs.CreateViewAsSkill{
	name = "zhiheng_po",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zhiheng_card = zhiheng_poCard:clone()
		for _,card in pairs(cards) do
			zhiheng_card:addSubcard(card)
		end
		zhiheng_card:setSkillName(self:objectName())
		return zhiheng_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zhiheng_poCard") and player:canDiscard(player, "he")
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@zhiheng_po"
	end
}

zhiheng_po_audio = sgs.CreateTriggerSkill{
	name = "zhiheng_po_audio",
	events = {},
	on_trigger = function()
	end
}

zhiheng_po_buff = sgs.CreateTriggerSkill{
	name = "zhiheng_po_buff",
	global = true,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:objectName() == "zhiheng_poCard" and player:getHandcardNum() > 0 then
				room:setPlayerMark(player,"zhiheng_po_handcard_num",player:getHandcardNum())
				for _,c in sgs.qlist(player:getHandcards()) do
					room:setCardFlag(c, "zhiheng_po_handcard")
				end
			end
		end
		return false
	end,
}


--新救援
jiuyuan_po = sgs.CreateTriggerSkill{
	name = "jiuyuan_po$",
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		local sunquan_pos = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasLordSkill(self:objectName()) then
				sunquan_pos:append(p)
			end
		end
		if not sunquan_pos:isEmpty() then
			local _data = sgs.QVariant()
			for _, p in sgs.qlist(sunquan_pos) do
				_data:setValue(p)
				if use.card and use.card:isKindOf("Peach") and player:objectName() ~= p:objectName() and use.to:contains(player) and player:getHp() > p:getHp() and room:askForSkillInvoke(player, self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:recover(p, sgs.RecoverStruct(p))
					use.to = sgs.SPlayerList()
					data:setValue(use)
					player:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getKingdom() == "wu"
	end
}
sunquan_po:addSkill(zhiheng_po)
sunquan_po:addSkill(jiuyuan_po)

if not sgs.Sanguosha:getSkill("zhiheng_po_audio") then skills:append(zhiheng_po_audio) end
if not sgs.Sanguosha:getSkill("zhiheng_po_buff") then skills:append(zhiheng_po_buff) end
sunquan_po:addRelateSkill("zhiheng_po_audio")

sgs.LoadTranslationTable{
["#sunquan_po"] = "年輕的賢君",
["&sunquan_po"] = "孫權",
["sunquan_po"] = "新孫權",
["zhiheng_po"] = "制衡",
["zhiheng_po_audio"] = "制衡",
[":zhiheng_po"] = "階段技。你可以棄置至少一張牌：若如此做，你摸等量的牌。若你以此法棄置所有手牌，你額外摸一張牌",
["jiuyuan_po"] = "救援",
[":jiuyuan_po"] = "主公技，當其他吳勢力角色對其使用【桃】時，若其體力值大於你，其可以終止此【桃】結算，若如此做，你回復1點體力，其摸一張牌。 ",
["$jiuyuan_po1"] = "好舒服啊",
["$jiuyuan_po2"] = "有汝輔佐，甚好！",
["~sunquan_po"] = "父親，大哥，仲謀愧矣……",
}

--神司馬懿(2019)
shensimayi_po = sgs.General(extension, "shensimayi_po", "god", "4", true)

--2019拜印
baiyin_po = sgs.CreatePhaseChangeSkill{
	name = "baiyin_po" ,
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:setPlayerMark(player,"baiyin_po", 1)
		if room:changeMaxHpForAwakenSkill(player) then
			room:broadcastSkillInvoke("baiyin")
			if player:getMark("@bear") >= 4 then
				local msg = sgs.LogMessage()
				msg.type = "#BaiyinWake"
				msg.from = player
				msg.to:append(player)
				msg.arg = tostring(player:getMark("@bear"))
				room:sendLog(msg)
			end
			room:doSuperLightbox("shensimayi","baiyin_po")
			room:acquireSkill(player, "jilve_po")
		end
		return false
	end ,
	can_trigger = function(self,target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("baiyin_po") == 0)
				and (target:getMark("@bear") >= 4 or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}
--2019極略
jilve_poCard = sgs.CreateSkillCard{
	name = "jilve_poCard",
	target_fixed = true,
	about_to_use = function(self, room, use)
		local shensimayi = use.from
		local choices = {}
		if shensimayi:getMark("jilveZhiheng-Clear") == 0 and shensimayi:canDiscard(shensimayi, "he") then
			table.insert(choices,"zhiheng_po")
		end
		if shensimayi:getMark("jilveWansha-Clear") == 0 then
			table.insert(choices,"wansha")
		end
		table.insert(choices,"cancel")
		if #choices == 1 then return end
		local choice = room:askForChoice(shensimayi, "jilve_po", table.concat(choices,"+"))
		if choice == "cancel" then
			room:addPlayerHistory(shensimayi, "#jilve_poCard", -1)
			return
		end
		shensimayi:loseMark("@bear")
		room:notifySkillInvoked(shensimayi, "jilve_po")
		if choice == "wansha" then
			room:broadcastSkillInvoke("jilve",3)
			room:setPlayerMark(shensimayi,"jilveWansha-Clear",1)
			room:acquireSkill(shensimayi, "wansha_po")
			room:setPlayerMark(shensimayi, "wansha_po_skillClear",1)
		else
			room:broadcastSkillInvoke("jilve",4)
			room:setPlayerMark(shensimayi,"jilveZhiheng-Clear",1)
			room:askForUseCard(shensimayi, "@zhiheng_po", "@jilve-zhiheng", -1, sgs.Card_MethodDiscard)
		end
	end
}
jilve_poVS = sgs.CreateZeroCardViewAsSkill{--完杀和制衡
	name = "jilve_po",
	enabled_at_play = function(self,player)
		return player:usedTimes("#jilve_poCard") < 2 and player:getMark("@bear") > 0
	end,
	view_as = function()
		return jilve_poCard:clone()
	end
}
jilve_po = sgs.CreateTriggerSkill{
	name = "jilve_po",
	events = {sgs.CardUsed, sgs.AskForRetrial, sgs.Damaged},--分别为集智、鬼才、放逐
	view_as_skill = jilve_poVS,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("@bear") > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:setMark("JilveEvent",tonumber(event))
		if event == sgs.CardUsed then
			local jizhi = sgs.Sanguosha:getTriggerSkill("jizhi_po")
			local use = data:toCardUse()
			if jizhi and use.card and use.card:isNDTrick() and player:askForSkillInvoke("jilve_jizhi", data) then
				room:broadcastSkillInvoke("jilve",5)
				room:notifySkillInvoked(player, self:objectName())
				player:loseMark("@bear")
				jizhi:trigger(event, room, player, data)
			end
		elseif event == sgs.AskForRetrial then
			local guicai = sgs.Sanguosha:getTriggerSkill("guicai")
			if guicai and not player:isKongcheng() and player:askForSkillInvoke("jilve_guicai", data) then
				room:broadcastSkillInvoke("jilve",1)
				room:notifySkillInvoked(player, self:objectName())
				player:loseMark("@bear")
				guicai:trigger(event, room, player, data)
			end
		elseif event == sgs.Damaged then
			local fangzhu = sgs.Sanguosha:getTriggerSkill("fangzhu")
			if fangzhu and player:askForSkillInvoke("jilve_fangzhu", data) then
				room:broadcastSkillInvoke("jilve",2)
				room:notifySkillInvoked(player, self:objectName())
				player:loseMark("@bear")
				fangzhu:trigger(event, room, player, data)
			end
		end
		player:setMark("JilveEvent", 0)
		return false
	end
}


lua_lianpo = sgs.CreateTriggerSkill{
	name = "lua_lianpo" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_NotActive then
			for _, shensimayi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if shensimayi and shensimayi:getMark("lua_lianpo_start") > 0 and shensimayi:askForSkillInvoke(self:objectName()) then
					local msg = sgs.LogMessage()
					msg.type = "#LianpoCanInvoke"
					msg.from = shensimayi
					msg.to:append(shensimayi)
					msg.arg = tostring(shensimayi:getMark("lua_lianpo_start"))
					msg.arg2 = self:objectName()
					room:sendLog(msg)

					room:setTag("ExtraTurn",sgs.QVariant(true))
					shensimayi:gainAnExtraTurn()
					room:setTag("ExtraTurn",sgs.QVariant(false))
				end
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}

if not sgs.Sanguosha:getSkill("jilve_po") then skills:append(jilve_po) end

shensimayi_po:addSkill("renjie")
shensimayi_po:addSkill(baiyin_po)
shensimayi_po:addSkill(lua_lianpo)
shensimayi_po:addRelateSkill("jilve_po")

sgs.LoadTranslationTable{
["#shensimayi_po"] = "晉國之祖",
["shensimayi_po"] = "神司馬懿-2019",
["&shensimayi_po"] = "神司馬懿",
["@bear"] = "忍",
["baiyin_po"] = "拜印",
[":baiyin_po"] ="覺醒技。準備階段開始時，若你擁有四枚或更多的“忍”，你失去1點體力上限，然後獲得“極略”（你可以棄一枚“忍”並發動以下技能之一：“鬼才”、“放逐”、“集智”、“制衡”、“完殺”）。",
["$BaiyinAnimate"] = "image=image/animate/baiyin.png",
["jilve_po"] = "極略",
[":jilve_po"] = "你可以棄一枚“忍”並發動以下技能之一：“鬼才”、“放逐”、“集智”、“制衡”、“完殺”。",
["jilve_jizhi"] = "極略（集智）",
["jilve_guicai"] = "極略（鬼才）",
["jilve_fangzhu"] = "極略（放逐）",
["@jilve-zhiheng"] = "請發動“制衡”",
["~zhiheng_po"] = "選擇需要棄置的牌→點擊確定",
["#BaiyinWake"] = "%from 的“忍”為 %arg 個，觸發“<font color=\"yellow\"><b>拜印</b></font>”覺醒",

["lua_lianpo"] = "連破",
[":lua_lianpo"] = "每當一名角色的回合結束後，若你於本回合殺死至少一名角色，你可以進行一個額外的回合。",
["#LianpoCanInvoke"] = "%from 在本回合內殺死了 %arg 名角色，滿足“%arg2”的發動條件",
["#LianpoRecord"] = "%from 殺死了 %to，可在 %arg 回合結束後進行一個額外的回合",
}

--新張飛
zhangfei_po = sgs.General(extension, "zhangfei_po", "shu2", "4", true)
--咆哮：鎖定技，你使用【殺】無次數限制；你的出牌階段，若你於當前階段使用過【殺】，你於此階段使用【殺】無距離限制。
paoxiao_po = sgs.CreateTriggerSkill{
	name = "paoxiao_po" ,
	events = {sgs.TargetSpecified} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isVirtualCard() then return false end
			if use.card:isKindOf("Slash") then
				if player:getMark("used_slash_Play") > 1 then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke("paoxiao")
				end
			end
		end
	end
}

paoxiao_poTM = sgs.CreateTargetModSkill{
	name = "#paoxiao_poTM",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("paoxiao_po") and from:getMark("used_slash_Play") > 0 then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, from, card)
		if from:hasSkill("paoxiao_po") then
			return 1000
		else
			return 0
		end
	end,
}
--替身：出牌階段結束時，你可以棄置所有錦囊牌和坐騎牌，然後直到你的下回合開始，獲得所有以你為目標且未對你造成傷害的【殺】。
tishen_po = sgs.CreateTriggerSkill{
	name = "tishen_po",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
		if event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Play then
				room:removeTag("tishencard")
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke("tishen")
					--local cards = player:getHandcards()
					local cards = player:getCards("he")
					local ids = sgs.IntList()
					for _, card in sgs.qlist(cards) do
						if card:isKindOf("TrickCard") then
							ids:append(card:getEffectiveId())
						end
						if card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse") then
							ids:append(card:getEffectiveId())
						end
					end
					if not ids:isEmpty() then
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = nil
						move.to_place = sgs.Player_DiscardPile
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "tishen_po", nil)
						room:moveCardsAtomic(move, true)
					end
					room:setPlayerMark(player, "@tishen_invoke", 1)
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				if player:getMark("@tishen_invoke") > 0 then 			
					room:setPlayerMark(player, "@tishen_invoke", 0)
					local DPHeart = sgs.IntList()
					if room:getDiscardPile():length() > 0 then
						for _, id in sgs.qlist(room:getDiscardPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if player:getMark("tishen_po_card"..card:getEffectiveId()) > 0 then
								DPHeart:append(id)
								room:setPlayerMark(player, "tishen_po_card"..card:getEffectiveId(), 0)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						local move = sgs.CardsMoveStruct()
						move.card_ids = DPHeart
						move.to = player
						move.to_place = sgs.Player_PlaceHand
						room:moveCardsAtomic(move, true)
					end
				end
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "tishen_po_card") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
					end
				end
			end
		end
		return false
	end,
}

tishen_pomove = sgs.CreateTriggerSkill{
	name = "#tishen_po",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished,sgs.Damaged, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local s = room:findPlayerBySkillName("tishen_po")
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.to:contains(s) and s:getMark("@tishen_invoke") > 0 and s:hasFlag("can_tishen") and use.card:isVirtualCard() then
				local n = use.card:getSubcards():length()
				if n > 0 then
					for i = 1, n, 1 do
						local ids = use.card:getSubcards()
						local id = ids:at(i-1)
						local card = sgs.Sanguosha:getCard(id)

						room:setPlayerMark(s, "tishen_po_card"..card:getEffectiveId(), 1)
					end
				else
					room:setPlayerMark(s, "tishen_po_card"..use.card:getEffectiveId(), 1)
				end	

			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card then
				if damage.card:isKindOf("Slash") and s:hasFlag("can_tishen") and (damage.from == s or damage.to == s) then
					room:setPlayerFlag(s, "-can_tishen")
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.to:contains(s) and use.card:isKindOf("Slash") then
				room:setPlayerFlag(s, "can_tishen")
			end
		end		
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

zhangfei_po:addSkill(paoxiao_po)
zhangfei_po:addSkill(paoxiao_poTM)
zhangfei_po:addSkill(tishen_po)
zhangfei_po:addSkill(tishen_pomove)
extension:insertRelatedSkills("tishen_po","#tishen_po")

sgs.LoadTranslationTable{
["#zhangfei_po"] = "萬夫不當",
["zhangfei_po"] = "新張飛",
["&zhangfei_po"] = "張飛",
["illustrator:zhangfei_po"] = "SONGQIJIN",
["paoxiao_po"] = "咆哮",
[":paoxiao_po"] = "鎖定技，你使用【殺】無次數限制；你的出牌階段，若你於當前階段使用過【殺】，你於此階段使用【殺】無距離限制。",
["tishen_po"] = "替身",
[":tishen_po"] = "出牌階段結束時，你可以棄置所有錦囊牌和坐騎牌，然後直到你的下回合開始，獲得所有以你為目標且未對你造成傷害的【殺】。",
}

--新貂蟬
diaochan_po = sgs.General(extension, "diaochan_po", "qun2", "3", false)
--閉月:結束階段，你可以摸一張牌。若你沒有手牌，則改為摸兩張牌。
biyue_po = sgs.CreatePhaseChangeSkill{
	name = "biyue_po",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				room:notifySkillInvoked(player,"biyue_po")
				room:broadcastSkillInvoke("biyue")
				if player:isKongcheng() then
					player:drawCards(2, self:objectName())
				else
					player:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end
}

diaochan_po:addSkill("lijian")
diaochan_po:addSkill(biyue_po)

sgs.LoadTranslationTable{
["#diaochan_po"] = "絕世的舞姬",
["diaochan_po"] = "新貂蟬",
["&diaochan_po"] = "貂蟬",
["illustrator:diaochan"] = "木美人",
["biyue_po"] = "閉月",
[":biyue_po"] = "結束階段，你可以摸一張牌。若你沒有手牌，則改為摸兩張牌。",
}

--新許褚
xuchu_po = sgs.General(extension, "xuchu_po", "wei2", "4", true)
--新裸衣
luoyi_poBuff = sgs.CreateTriggerSkill{
	name = "#luoyi_poBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.chain or damage.transfer or (not damage.by_user) then return false end
		local reason = damage.card
		if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
			damage.damage = damage.damage + 1
			local msg = sgs.LogMessage()
			msg.type = "#LuoyiBuff"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = tostring(damage.damage-1)
			msg.arg2 = tostring(damage.damage)					
			room:sendLog(msg)
			data:setValue(damage)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getMark("@luoyi_po") > 0 and target:isAlive()
	end
}
luoyi_po = sgs.CreateTriggerSkill{
	name = "luoyi_po",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local count = data:toInt()
			if player:getMark("@luoyi_po") > 0 then
				count = 0
				--room:setPlayerFlag(player, "luoyi_po")
				data:setValue(count)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "@luoyi_po", 0)
			elseif player:getPhase() == sgs.Player_Draw then
				local ids = room:getNCards(3)

				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, 
					player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)				


				local slashs = sgs.IntList()
				local last = sgs.IntList()
				for _,id in sgs.qlist(ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("BasicCard") or card:isKindOf("Duel") or card:isKindOf("Weapon") then
						slashs:append(id)				
					else
						last:append(id)
					end
				end		
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player,"luoyi_po")
					room:broadcastSkillInvoke("luoyi")
					room:setPlayerMark(player, "@luoyi_po", 1)
					for _,id in sgs.qlist(last) do
						local card = sgs.Sanguosha:getCard(id) 
						room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
						  sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
						  player:objectName(), "", "luoyi_po"), true)
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
				else
					for _,id in sgs.qlist(ids) do
						local card = sgs.Sanguosha:getCard(id) 
						room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
						  sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
						  player:objectName(), "", "luoyi_po"), true)
					end
				end
 			end			
		end
	end
}
xuchu_po:addSkill(luoyi_po)
xuchu_po:addSkill(luoyi_poBuff)
extension:insertRelatedSkills("luoyi_po","#luoyi_poBuff")

sgs.LoadTranslationTable{
["#xuchu_po"] = "虎痴",
["xuchu_po"] = "新許褚",
["&xuchu_po"] = "許褚",
["illustrator:xuchu"] = "巴薩小馬",
["luoyi_po"] = "裸衣",
[":luoyi_po"] = "摸牌階段開始時，你亮出牌堆頂的三張牌，然後你可以獲得其中的基本牌、武器牌或【決鬥】。若如此做，你放棄摸牌，且直到你的下回合開始，你為傷害來源的【殺】或【決鬥】造成傷害時，此傷害+1。",
["#LuoyiBuff"] = "%from 的“<font color=\"yellow\"><b>裸衣</b></font>”效果被觸發，傷害從 %arg 點增加至 %arg2 點",
}
--新甄姬
zhenji_po = sgs.General(extension, "zhenji_po", "wei2", "3", false)
--洛神:準備階段，你可以進行判定，若結果為黑色，你獲得此牌，然後你可以重複此流程。以此法獲得的牌本回合不計入手牌上限。
luoshen_po = sgs.CreateTriggerSkill{
	name = "luoshen_po",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.FinishJudge,sgs.EventPhaseChanging,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local cards = player:getHandcards()
				local ids = sgs.IntList()
				for _, card in sgs.qlist(cards) do			
					if card:hasFlag("luoshen_getcard") then
						room:setCardFlag(card, "-luoshen_getcard")
					end
				end
				while player:askForSkillInvoke(self:objectName()) do
					room:notifySkillInvoked(player,"luoshen_po")
					room:broadcastSkillInvoke("luoshen")
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
						break
					end
				end
				--[[
			elseif player:getPhase() == sgs.Player_Discard then
				local cards = player:getHandcards()
				room:setTag("FirstRound" , sgs.QVariant(true))
				local ids = sgs.IntList()
				for _, card in sgs.qlist(cards) do			
					if card:hasFlag("luoshen_getcard") then
						ids:append(card:getEffectiveId())
						room:notifySkillInvoked(player,"luoshen_po")
						room:setCardFlag(card, "-luoshen_getcard")
					end
				end
				player:addToPile("luoshen_po", ids)
				room:setTag("FirstRound" , sgs.QVariant(false))
				]]--
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isBlack() then
					--room:setCardFlag(card, "luoshen_getcard")
					room:setPlayerMark(player, "luoshen"..card:getId().."-Clear", 1)
					player:obtainCard(card)
					return true
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard then
				for _, card in sgs.list(player:getHandcards()) do
					if player:getMark("luoshen"..card:getId().."-Clear") > 0 then
						room:removePlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(card:getId()):toString().."$0")
					end
				end
			end
		--[[
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Discard then
				room:setTag("FirstRound" , sgs.QVariant(true))
				local id2s = sgs.IntList()
				if player:getPile("luoshen_po"):length() > 0 then
					local n = player:getPile("luoshen_po"):length()
					for i = 1, n,1 do
						local ids = player:getPile("luoshen_po")
						local id = ids:at(i-1)
						local card = sgs.Sanguosha:getCard(id)
						id2s:append(card:getEffectiveId())
					end
				end
				room:broadcastSkillInvoke(self:objectName())
				local move = sgs.CardsMoveStruct()
				move.card_ids = id2s
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
				room:setTag("FirstRound" , sgs.QVariant(false))
			end
		]]--
		end
		return false
	end
}

luoshen_pomc = sgs.CreateMaxCardsSkill{
	name = "#luoshen_pomc", 
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if target:hasSkill("luoshen_po") then
			local n = 0
			for _, card in sgs.list(target:getHandcards()) do
				if target:getMark("luoshen"..card:getId().."-Clear") > 0 then
					n = n + 1
				end
			end
			return n
		end
	end
}

zhenji_po:addSkill(luoshen_po)
zhenji_po:addSkill(luoshen_pomc)
zhenji_po:addSkill("qingguo")

sgs.LoadTranslationTable{
["#zhenji_po"] = "薄倖的美人",
["zhenji_po"] = "新甄姬",
["&zhenji_po"] = "甄姬",
["luoshen_po"] = "洛神",
[":luoshen_po"] = "準備階段開始時，妳可以進行判定：若結果為黑色，判定牌生效後你獲得之，然後你可以再次發動“洛神”。妳以此法獲得的牌，於此回合內不計入手牌上限",
["qingguo"] = "傾國",
[":qingguo"] = "妳可以將一張黑色手牌當【閃】使用或打出。",
}

--2019關興張苞
guanxingzhangbao_po = sgs.General(extension, "guanxingzhangbao_po", "shu2", "4", true)

fuhun_poVS = sgs.CreateViewAsSkill{
	name = "fuhun_po" ,
	n = 2,
	view_filter = function(self, selected, to_select)
		return (#selected < 2) and (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_SuitToBeDecided, 0)
		slash:setSkillName(self:objectName())
		slash:addSubcard(cards[1])
		slash:addSubcard(cards[2])
		return slash
	end ,
	enabled_at_play = function(self, player)
		return (player:getHandcardNum() >= 2) and sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return (player:getHandcardNum() >= 2) and (pattern == "slash")
	end
}
fuhun_po = sgs.CreateTriggerSkill{
	name = "fuhun_po" ,
	events = {sgs.Damage} ,
	view_as_skill = fuhun_poVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) and (player and player:isAlive() and player:hasSkill(self:objectName())) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:getSkillName() == self:objectName())
			  and (player:getPhase() == sgs.Player_Play) then
			  	if player:hasSkill("wusheng_po") then
					room:handleAcquireDetachSkills(player, "wusheng_po")
					room:addPlayerMark(player,"wusheng_po_skillClear")
				end
			  	if player:hasSkill("paoxiao_po") then
					room:handleAcquireDetachSkills(player, "paoxiao_po")
					room:addPlayerMark(player,"paoxiao_po_skillClear")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
guanxingzhangbao_po:addSkill(fuhun_po)

sgs.LoadTranslationTable{
["#guanxingzhangbao_po"] = "將門虎子",
["guanxingzhangbao_po"] = "關興＆張苞-2019",
["&guanxingzhangbao_po"] = "關興張苞",
["illustrator:guanxingzhangbao_po"] = "HOOO",
["fuhun_po"] = "父魂",
[":fuhun_po"] = "你可以將兩張手牌當普通【殺】使用或打出。每當你於出牌階段內以此法使用【殺】造成傷害後，你擁有“武聖(新)”、 “咆哮(新)”，直到回合結束。",
}

--新郭嘉
guojia_po = sgs.General(extension, "guojia_po", "wei2", "3", true)
--新遺計
yiji_po = sgs.CreateTriggerSkill{
	name = "yiji_po",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
		if not player:isAlive() then return end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards((x*2))
			room:notifySkillInvoked(player,"yiji_po")
			room:broadcastSkillInvoke("yiji")
			--原本的手牌數
			local n1 = player:getHandcardNum()
			--可以遺計給出去的牌數
			local n2 = x*2
			while room:askForYiji(player, getIntList(player:getCards("h")), self:objectName(), true, false, true, n2, room:getAlivePlayers()) do
				local n3 = player:getHandcardNum()
				n2 = (n2 - (n1 - n3))
				n1 = player:getHandcardNum()
			end
		end
		return false
	end
}
guojia_po:addSkill("tiandu")
guojia_po:addSkill(yiji_po)

sgs.LoadTranslationTable{
["#guojia_po"] = "早終的先知",
["guojia_po"] = "新郭嘉",
["&guojia_po"] = "郭嘉",
["illustrator:guojia_po"] = "木美人",
["yiji_po"] = "遺計",
[":yiji_po"] = "當你受到1點傷害後，你可以摸兩張牌，然後你可以將至多兩張手牌交給一至兩名其他角色。",
["@yiji"] = "你可以選擇至多兩名角色扣置“遺計牌”",
["YijiGive"] = "請在 %dest 武將牌旁扣置至多 %arg 張手牌",
["~yiji"] = "選擇一至兩名角色→點擊確定",
}

--新曹操
caocao_po = sgs.General(extension, "caocao_po$", "wei2", "4", true)

--奸雄
jianxiong_po = sgs.CreateMasochismSkill{
	name = "jianxiong_po" ,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local card = damage.card
		if not card then return end
		local ids = sgs.IntList()
		if card:isVirtualCard() then
			ids = card:getSubcards()
		else
			ids:append(card:getEffectiveId())
		end
		if ids:isEmpty() then return end
		for _, id in sgs.qlist(ids) do
			if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
		end
		local data = sgs.QVariant()
		data:setValue(damage)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			if player:hasSkill("dengji") then
				room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
			else
				room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
			end
			player:obtainCard(card)
			player:drawCards(1)
		end
	end
}

caocao_po:addSkill("hujia")
caocao_po:addSkill(jianxiong_po)

sgs.LoadTranslationTable{
["#caocao_po"] = "魏武帝",
["caocao_po"] = "新曹操",
["&caocao_po"] = "曹操",
["illustrator:caocao_po"] = "青騎士",
["jianxiong_po"] = "奸雄",
[":jianxiong_po"] = "當你受到傷害後，你可以獲得對你造成傷害的牌並摸一張牌。",
}

--新諸葛亮
zhugeliang_po = sgs.General(extension, "zhugeliang_po", "shu2", "3", true)
--觀星
guanxing_po = sgs.CreateTriggerSkill{
	name = "guanxing_po",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				if player:hasSkill("lua_zhiji") and player:getGeneralName() == "jiangwei_po" then
					room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
				elseif player:hasSkill("lua_zhiji") and player:getGeneralName() == "mobile_jiangwei" then
					room:broadcastSkillInvoke(self:objectName(), math.random(5,6))
				else
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				end
				local count = 5
				if room:alivePlayerCount() < 4 then
					count = 3
				end

				local before_cards = sgs.IntList()
				for i=1, count, 1 do
					local ids = room:getDrawPile()
					local id
					id = ids:at(i)
					before_cards:append(id)
				end

				local cards = room:getNCards(count)
				room:askForGuanxing(player,cards)

				local after_cards = sgs.IntList()
				for i=1, count, 1 do
					local ids = room:getDrawPile()
					local id
					id = ids:at(i)
					after_cards:append(id)
				end
				local all_put_buttom = true
				for i = 1,count,1 do
					for j = 1,count,1 do
						if before_cards:at(i-1) == after_cards:at(j-1) then
							all_put_buttom = false
							break
						end
					end
				end
				if all_put_buttom then
					room:setPlayerMark(player,"extra_guanxing_po-Clear",1)
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:getMark("extra_guanxing_po-Clear") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local count = 5
					if room:alivePlayerCount() < 4 then
						count = 3
					end
					local cards = room:getNCards(count)
					room:askForGuanxing(player,cards)
				end
			end
		end
	end
}

zhugeliang_po:addSkill(guanxing_po)
zhugeliang_po:addSkill("kongcheng")

sgs.LoadTranslationTable{
["#zhugeliang_po"] = "遲暮的丞相",
["zhugeliang_po"] = "新諸葛亮",
["&zhugeliang_po"] = "諸葛亮",
["guanxing_po"] = "觀星",
[":guanxing_po"] = "準備階段，你可以觀看牌堆頂的五張牌（存活人數小於4時改為三張），然後以任意順序放回牌堆頂或牌堆底。若你將這些牌均放至牌堆底，則結束階段你可以再次發動此技能。",
["kongcheng"] = "空城",
}

--界華雄
huaxiong_po = sgs.General(extension, "huaxiong_po", "qun2", "6", true)

yaowu_po = sgs.CreateTriggerSkill{
	name = "yaowu_po" ,
	events = {sgs.DamageInflicted} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card then
			room:broadcastSkillInvoke(self:objectName())
			if damage.card:isRed() then
				if damage.from and damage.from:isAlive() then
					damage.from:drawCards(1)
				end
			else
				player:drawCards(1)
			end
		end
		return false
	end
}

huaxiong_po:addSkill(yaowu_po)

sgs.LoadTranslationTable{
["#huaxiong_po"] = "飛揚跋扈",
["huaxiong_po"] = "華雄",
["yaowu_po"] = "耀武",
[":yaowu_po"] = "鎖定技，當你受到傷害時，若造成傷害的牌為紅色，傷害來源摸一張牌；若此牌不為紅色，你摸一張牌。",
["yaowu:recover"] = "回复1點體力",
["yaowu:draw"] = "摸一張牌",
}

--界呂蒙
lvmeng_po = sgs.General(extension, "lvmeng_po", "wu2", "4", true)

lvmeng_po:addSkill("keji")
lvmeng_po:addSkill("qinxue")
lvmeng_po:addSkill("botu")

sgs.LoadTranslationTable{
["#lvmeng_po"] = "士別三日",
["lvmeng_po"] = "新呂蒙",
["&lvmeng_po"] = "呂蒙",
["illustrator:lvmeng_po"] = "櫻花閃亂",
}

--OL界趙雲
--龍膽 你可以將一張【殺】當【閃】、【閃】當【殺】、【酒】當【桃】、【桃】當【酒】使用或打出。
--涯角 當你於回合外使用或打出手牌時，你可以展示牌堆頂的一張牌。若這兩張牌的類別相同，你可以將展示的牌交給一名角色；
--若類別不同，你可棄置攻擊範圍內包含你的角色區域裡的一張牌

ol_zhaoyun = sgs.General(extension, "ol_zhaoyun", "shu2", "4", true)

ol_longdan = sgs.CreateOneCardViewAsSkill{
	name = "ol_longdan" ,
	response_or_use = true,
	view_filter = function(self, card)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() and card:isKindOf("Analeptic") then
				return true
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				slash:addSubcard(card:getEffectiveId())
				slash:deleteLater()
				return slash:isAvailable(sgs.Self)
			elseif card:isKindOf("Peach") then
				local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, -1)
				analeptic:addSubcard(card:getEffectiveId())
				analeptic:deleteLater()
				return analeptic:isAvailable(sgs.Self)
			else
				return false
			end
		elseif usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			elseif pattern == "jink" then
				return card:isKindOf("Slash")
			end
			if (string.find(pattern, "peach") and player:getMark("Global_PreventPeach") == 0) and card:isKindOf("Analeptic") then
				return true
			end
			if string.find(pattern, "analeptic") and card:isKindOf("Peach") then
				return true
			end
		else
			return false
		end
	end ,
	view_as = function(self, card)
		if card:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:addSubcard(card)
			jink:setSkillName(self:objectName())
			return jink
		elseif card:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card)
			slash:setSkillName(self:objectName())
			return slash
		elseif card:isKindOf("Peach") then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
			analeptic:addSubcard(card)
			analeptic:setSkillName(self:objectName())
			return analeptic
		elseif card:isKindOf("Analeptic") then
			local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
			peach:addSubcard(card)
			peach:setSkillName(self:objectName())
			return peach
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target) or sgs.Analeptic_IsAvailable(target)
	end,


	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
				or (pattern == "jink")
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
				or  string.find(pattern, "analeptic")
	end,
}

ol_yajiao = sgs.CreateTriggerSkill {
	name = "ol_yajiao",
	events = {sgs.CardUsed, sgs.CardResponded},
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_NotActive then return end
		local room = player:getRoom()

		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end

		if not card or (card:getHandlingMethod() ~= sgs.Card_MethodUse and card:getHandlingMethod() ~= sgs.Card_MethodResponse) then return end

		if card:getTypeId() == sgs.Card_TypeSkill then return end

		if card:isVirtualCard() and card:subcardsLength() == 0 then return end

		if not player:askForSkillInvoke(self:objectName(), data) then return end

		local ids = room:getNCards(1, false)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), "")
		local move = sgs.CardsMoveStruct(ids, player, sgs.Player_PlaceTable, reason)
		room:moveCardsAtomic(move, true)

		room:setPlayerMark(player,"yajiao",ids:first())
		if sgs.Sanguosha:getCard(ids:first()):getTypeId() == card:getTypeId() then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), "yajiao", "@ol_yajiao-give:"..sgs.Sanguosha:getCard(ids:first()):objectName(), true, true)
			if target then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke("yajiao")
				room:obtainCard(target, ids:first())
			else
				reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
				move = sgs.CardsMoveStruct(ids, nil, sgs.Player_DrawPile, reason)
				room:moveCardsAtomic(move, true)
			end
		else
			reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
			move = sgs.CardsMoveStruct(ids, nil, sgs.Player_DrawPile, reason)
			room:moveCardsAtomic(move, true)
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:distanceTo(player) <= p:getAttackRange() and player:canDiscard(p, "he") then
					_targets:append(p)
				end
			end
			if not _targets:isEmpty() then
				local to_discard = room:askForPlayerChosen(player, _targets, "chezheng", "@ol_yajiao-discard", true)
				if to_discard then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke("yajiao")
					room:throwCard(room:askForCardChosen(player, to_discard, "he", "ol_yajiao", false, sgs.Card_MethodDiscard), to_discard, player)
				end
			end
		end
		return false
	end
}
ol_zhaoyun:addSkill(ol_longdan)
ol_zhaoyun:addSkill(ol_yajiao)

sgs.LoadTranslationTable{
	["ol_zhaoyun"] = "OL界趙雲",
	["&ol_zhaoyun"] = "趙雲",
	["#ol_zhaoyun"] = "虎威將軍",

	["ol_longdan"] = "龍膽",
	[":ol_longdan"] = "你可以將一張【殺】當【閃】、【閃】當【殺】、【酒】當【桃】、【桃】當【酒】使用或打出。",
	["@ol_yajiao-discard"] = "你可以棄置其中一名角色的一張牌",
	["ol_yajiao"] = "涯角",
	[":ol_yajiao"] = "當你於回合外使用或打出手牌時，你可以展示牌堆頂的一張牌。若這兩張牌的類別相同，你可以將展示的牌交給一名角色；若類別不同，你可棄置攻擊範圍內包含你的角色區域裡的一張牌",
	["@ol_yajiao-give"] = "你可以令一名角色獲得 %src ",
}

--OL界張飛
--咆哮 鎖定技，你使用【殺】無次數限制。若你使用的【殺】被【閃】抵消，你本回合下一次造成【殺】的傷害時，此傷害+1。
--替身 限定技，準備階段，你可以將體力回復至上限，然後摸X張牌(X為你回复的體力值)。

ol_zhangfei = sgs.General(extension, "ol_zhangfei", "shu2", "4", true)

ol_paoxiao = sgs.CreateTriggerSkill{
	name = "ol_paoxiao" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.SlashMissed,sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isVirtualCard() then return false end
			if use.card:isKindOf("Slash") then
				if player:hasFlag("ol_paoxiao") then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke("paoxiao")
				else
					room:setPlayerFlag(player, "ol_paoxiao")
				end
			end
		elseif event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			room:setPlayerMark(player,"ol_paoxiao_PD-Clear",player:getMark("ol_paoxiao_PD-Clear")+1)
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and player:getMark("ol_paoxiao_PD-Clear") > 0 then
					damage.damage = damage.damage + player:getMark("ol_paoxiao_PD-Clear")
					local msg = sgs.LogMessage()
						msg.type = "#ol_paoxiao"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - player:getMark("ol_paoxiao_PD-Clear") )
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
				end
			end
		end
	end
}

ol_paoxiaoTM = sgs.CreateTargetModSkill{
	name = "#ol_paoxiaoTM",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, from, card)
		if from:hasSkill("ol_paoxiao") then
			return 1000
		else
			return 0
		end
	end,
}

ol_tishen = sgs.CreateTriggerSkill{
	name = "ol_tishen",
	frequency = sgs.Skill_Limited ,
	events = {sgs.EventPhaseStart},
	limit_mark = "@ol_tishen",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				if player:getMark("@ol_tishen") > 0 and player:isWounded() then 
					if room:askForSkillInvoke(player, "ol_tishen", data) then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke("tishen")	
						room:doSuperLightbox("zhangfei", self:objectName())	
						room:setPlayerMark(player, "@ol_tishen", 0)
						local n = player:getMaxHp() - player:getHp()
						local recover = sgs.RecoverStruct()
						recover.recover = n
						room:recover(player, recover)
						player:drawCards(n)
					end
				end
			end
		end
		return false
	end,
}

ol_zhangfei:addSkill(ol_paoxiao)
ol_zhangfei:addSkill(ol_paoxiaoTM)
ol_zhangfei:addSkill(ol_tishen)

extension:insertRelatedSkills("ol_paoxiaoTM","#ol_paoxiaoTM")

sgs.LoadTranslationTable{
	["ol_zhangfei"] = "OL界張飛",
	["&ol_zhangfei"] = "張飛",
	["#ol_zhangfei"] = "",
	["ol_paoxiao"] = "咆哮",
	[":ol_paoxiao"] = "鎖定技，你使用【殺】無次數限制。若你使用的【殺】被【閃】抵消，你本回合下一次造成【殺】的傷害時，此傷害+1。",
	["#ol_paoxiao"] = "%from 的技能 “<font color=\"yellow\"><b>咆哮</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",

	["ol_tishen"] = "替身",
	[":ol_tishen"] = "限定技，準備階段，你可以將體力回復至上限，然後摸X張牌(X為你回复的體力值)。",

}

--界魏延
weiyan_po = sgs.General(extension, "weiyan_po", "shu2", "4", true)
--狂骨

--奇謀
qimou_poCard = sgs.CreateSkillCard{
	name = "qimou_poCard",
	target_fixed = true,
	on_use = function(self, room, source)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:doSuperLightbox("weiyan_po","qimou_po")
			local lose_num = {}
			for i = 1, source:getHp() do
				table.insert(lose_num, tostring(i))
			end
			local choice = room:askForChoice(source, "qimou_po", table.concat(lose_num, "+"))
			room:removePlayerMark(source, "@qimou_po")
			room:loseHp(source, tonumber(choice))
			source:drawCards(tonumber(choice))
			room:addPlayerMark(source, "@qimou_po-Clear", tonumber(choice))
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
qimou_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "qimou_po",
	view_as = function()
		return qimou_poCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@qimou_po") >= 1 and player:getHp() > 1
	end
}
qimou_po = sgs.CreateTriggerSkill{
	name = "qimou_po",
	frequency = sgs.Skill_Limited,
	limit_mark = "@qimou_po",
	view_as_skill = qimou_poVS,
	on_trigger = function()
	end
}

qimou_poDistance = sgs.CreateDistanceSkill{
	name = "#qimou_poDistance",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return  - from:getMark("@qimou_po-Clear")
		else
			return 0
		end
	end  
}
qimou_poTargetMod = sgs.CreateTargetModSkill{
	name = "#qimou_poTargetMod",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("qimou_po") then
			return player:getMark("@qimou_po-Clear")
		else
			return 0
		end
	end,
}
weiyan_po:addSkill("ol_kuanggu")
weiyan_po:addSkill(qimou_po)
weiyan_po:addSkill(qimou_poDistance)
weiyan_po:addSkill(qimou_poTargetMod)
extension:insertRelatedSkills("qimou_po","#qimou_poDistance")
extension:insertRelatedSkills("qimou_po","#qimou_poTargetMod")

sgs.LoadTranslationTable{
	["weiyan_po"] = "界魏延",
	["&weiyan_po"] = "魏延",
	["#weiyan_po"] = "子午奇謀",
	["qimou_po"] = "奇謀",
	[":qimou_po"] = "限定技，出牌階段，你可以失去任意點體力，若如此做，你摸X張牌，與其他角色的距離減少X，且你可以多出X張殺(X為你本回合失去的體力數)",
	["qimou_po-lost"] = "選擇失去的體力量",
}

--廖化
liaohua_po = sgs.General(extension,"liaohua_po","shu2","4",true)
--當先 鎖定技，回合開始時，你執行一個額外的出牌階段，此階段開始時你失去1點體力並從棄牌堆獲得一張【殺】。
dangxian_po = sgs.CreateTriggerSkill{
	name = "dangxian_po" ,
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
				local invoke = false
				if player:getMark("dangxian_po_change") == 0 then
					invoke = true
				elseif player:getMark("dangxian_po_change") == 1 then 
					if room:askForSkillInvoke(player, "dangxian_po", data) then
						invoke = true
					end
				end
				if invoke then
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
fuli_po = sgs.CreateTriggerSkill{
	name = "fuli_po" ,
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
			room:doSuperLightbox("liaohua","fuli_po")
			room:setPlayerMark(player,"dangxian_po_change",1)
			sgs.Sanguosha:addTranslationEntry(":dangxian_po", ""..string.gsub(sgs.Sanguosha:translate(":dangxian_po"), sgs.Sanguosha:translate(":dangxian_po"), sgs.Sanguosha:translate(":dangxian_po2")))
			local recover = sgs.RecoverStruct()
			recover.recover = math.min(getKingdomsFuli(player), player:getMaxHp()) - player:getHp()
			room:recover(player, recover)
			local n = getKingdomsFuli(player) - player:getHandcardNum()
			if n > 0 then
				player:drawCards(n)
			end
			if getKingdomsFuli(player) >= 3 then
				player:turnOver()
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName())) and (target:getMark("@laoji") > 0)
	end
}

liaohua_po:addSkill(dangxian_po)
liaohua_po:addSkill(fuli_po)

sgs.LoadTranslationTable{
	["liaohua_po"] = "界廖化",
	["&liaohua_po"] = "廖化",
	["#liaohua_po"] = "歷經滄桑",
	["dangxian_po"] = "當先",
	[":dangxian_po"] = "鎖定技，回合開始時，你執行一個額外的出牌階段，此階段開始時你失去1點體力並從棄牌堆獲得一張【殺】。",
	[":dangxian_po2"] = "鎖定技，回合開始時，你執行一個額外的出牌階段。此階段開始時，你可以失去1點體力並從棄牌堆獲得一張【殺】。",
	["fuli_po"] = "伏櫪",
	[":fuli_po"] = "限定技，當你處於瀕死狀態時，你可以將體力回復至X點且手牌摸至X張（X為全場勢力數），"..
"然後“當先”中失去體力的效果改為可選。若X大於等於3，你翻面。",
}

--郭淮
guohuai_po = sgs.General(extension,"guohuai_po","wei2","4",true)
--精策
jingce_po = sgs.CreateTriggerSkill{
	name = "jingce_po", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:getMark("card_used_num_Play") >= player:getHp() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())

					local choice
					if player:getMark("used_suit_num-Clear") < player:getHp() then 
						choice = room:askForChoice(player, self:objectName(), "jingce_po1+jingce_po2")
					end
					if choice == "jingce_po1" or player:getMark("used_suit_num-Clear") >= player:getHp() then
						local msg = sgs.LogMessage()
						msg.type = "#ExtraDrawPhase"
						msg.from = player
						msg.arg = self:objectName()
						room:sendLog(msg)

						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())

						player:setPhase(sgs.Player_Draw)
						room:broadcastProperty(player, "phase")
						local thread = room:getThread()
						if not thread:trigger(sgs.EventPhaseStart, room, player) then
							thread:trigger(sgs.EventPhaseProceeding, room, player)
						end
						thread:trigger(sgs.EventPhaseEnd, room, player)

					end
					if choice ==  "jingce_po2" or player:getMark("used_suit_num-Clear") >= player:getHp() then
						local msg = sgs.LogMessage()
						msg.type = "#ExtraPlayPhase"
						msg.from = player
						msg.arg = self:objectName()
						room:sendLog(msg)

						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())

						player:setPhase(sgs.Player_Play)
						room:broadcastProperty(player, "phase")
						local thread = room:getThread()
						if not thread:trigger(sgs.EventPhaseStart, room, player) then
							thread:trigger(sgs.EventPhaseProceeding, room, player)
						end
						thread:trigger(sgs.EventPhaseEnd, room, player)
					end

					player:setPhase(sgs.Player_Finish)
					room:broadcastProperty(player, "phase")

				end
			end
		end
	end
}



guohuai_po:addSkill(jingce_po)

sgs.LoadTranslationTable{
	["guohuai_po"] = "界郭淮",
	["&guohuai_po"] = "郭淮",
	["#guohuai_po"] = "",
	["jingce_po"] = "精策",
	[":jingce_po"] = "結束階段，若你於此回合內使用過的牌數量大於等於你的體力值，則你可以執行一個額外的摸牌或出牌階段。若這些牌的花色數也大於等於你的體力值，則兩項都選。",
	["jingce_po1"] = "執行一個額外的摸牌階段",
	["jingce_po2"] = "執行一個額外的出牌階段",
	["#ExtraDrawPhase"] = "%from 觸發“%arg”，將執行一個額外的摸牌階段",
	["#ExtraPlayPhase"] = "%from 觸發“%arg”，將執行一個額外的出牌階段",
}

--吳懿
wuyi_po = sgs.General(extension,"wuyi_po","shu2","4",true)
--奔襲 鎖定技，當你於回合內使用牌時，本回合你計算與其他角色的距離-1；你的回合內，若你與所
--有其他角色的距離均為1，則你使用僅指定一個目標的【殺】或普通錦囊牌時依次選擇至多兩項：
--1.此牌目標+1；2.此牌無視防具；3.此牌不能被抵消；4.此牌造成傷害時，摸一張牌。
function isAllAdjacent(from, card)
	local rangefix = 0
	if card then
		if card:isVirtualCard() and from:getOffensiveHorse()
			and card:getSubcards():contains(from:getOffensiveHorse():getEffectiveId()) then
			rangefix = 1
		end
	end
	for _, p in sgs.qlist(from:getAliveSiblings()) do
		if from:distanceTo(p, rangefix) ~= 1 then
			return false
		end
	end
	return true
end

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

benxi_poCard = sgs.CreateSkillCard{
	name = "benxi_po",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("benxi_po_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "benxi_po_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
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
				room:addPlayerMark(p, "benxi_po_extra")
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
benxi_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "benxi_po",
	response_pattern = "@@benxi_po",
	view_as = function()
		return benxi_poCard:clone()
	end
}

benxi_po = sgs.CreateTriggerSkill{
	name = "benxi_po",
	frequency = sgs.Skill_Compulsory,
	view_as_skill = benxi_poVS,
	global = true,
	events = {sgs.EventPhaseChanging, sgs.PreCardUsed, sgs.CardFinished, sgs.EventAcquireSkill, sgs.EventLoseSkill,sgs.TargetSpecified,sgs.TrickCardCanceling},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "@benxi_po", 0)
				room:setPlayerMark(player, "benxi_po", 0)
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if isAllAdjacent(player, nil) and (use.card:isKindOf("Slash") or use.card:isNDTrick())
			  and use.to:length() == 1 and player:getPhase() ~= sgs.Player_NotActive and player:hasSkill("benxi_po") then
			  	local choices = {"benxi_po_armor","benxi_po_draw","benxi_po_nores"}
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not use.to:contains(p) and not room:isProhibited(player, p, use.card) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					table.insert(choices,"benxi_po_extra")
				end
				table.insert(choices,"cancel")
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				for i = 1,2,1 do
					local choice = room:askForChoice(player, "benxi_po", table.concat(choices, "+"))
					ChoiceLog(player, choice)
					if choice == "benxi_po_extra" then
						for _, p in sgs.qlist(use.to) do
							room:addPlayerMark(p, "benxi_po_extra")
						end
						if use.card:isVirtualCard() then
							room:setPlayerMark(player, "benxi_po_virtual_card", 1)
							room:setPlayerMark(player, "benxi_po_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
							room:askForUseCard(player, "@@benxi_po", "@benxi_po")
							room:setPlayerMark(player, "benxi_po_virtual_card", 0)
							room:setPlayerMark(player, "benxi_po_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
						elseif not use.card:isVirtualCard() then
							room:setPlayerMark(player, "benxi_po_not_virtual_card", 1)
							room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
							room:askForUseCard(player, "@@benxi_po", "@benxi_po")
							room:setPlayerMark(player, "benxi_po_not_virtual_card", 0)
							room:setPlayerMark(player, "card_id", 0)
						end
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:getMark("benxi_po_extra") > 0 and not room:isProhibited(player, p, use.card) then
								room:removePlayerMark(p, "benxi_po_extra")
								if not use.to:contains(p) then
									use.to:append(p)
								end
							end
						end
						room:sortByActionOrder(use.to)
						data:setValue(use)
					elseif choice == "benxi_po_armor" then
						player:addQinggangTag(use.card)
					elseif choice == "benxi_po_nores" then
						room:setCardFlag(use.card, "benxi_po_nores")
					elseif choice == "benxi_po_draw" then
						room:setPlayerFlag(player, "benxi_po_drawer")
						room:setCardFlag(use.card, "benxi_po_drawcard")

					elseif choice == "cancel" then
						break

					end
					table.removeOne(choices,choice)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill
				and player:isAlive() and player:getPhase() ~= sgs.Player_NotActive then
				room:addPlayerMark(player, "benxi_po")
				if player:hasSkill("benxi_po") then
					room:setPlayerMark(player, "@benxi_po", player:getMark("benxi_po"))
					if player:hasFlag("benxi_po_nores") then
						room:setPlayerFlag(player, "-benxi_po_nores")
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand$1")
						end
					elseif player:hasFlag("benxi_po_draw") then
						room:setPlayerFlag(player, "-benxi_po_drawer")
						room:setCardFlag(use.card, "-benxi_po_drawcard")
					end
				end
			end
		elseif event == sgs.EventAcquireSkill or event == sgs.EventLoseSkill then
			if data:toString() ~= "benxi_po" then return false end
			local num = 0
			if event == sgs.EventAcquireSkill then
				num = player:getMark("benxi_po")
			else

			end
			room:setPlayerMark(player, "@benxi_po", num)

		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.card and not use.card:isKindOf("SkillCard") and use.card:hasFlag("benxi_po_nores") and string.find(use.card:getClassName(), "Slash") and RIGHT(self, use.from) then
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
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and effect.from:hasSkill(self:objectName()) and effect.card:hasFlag("benxi_po_nores") then
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

benxi_poDistance = sgs.CreateDistanceSkill{
	name = "#benxi_poDistance",
	correct_func = function(self, from, to)
		if from:hasSkill("benxi_po") and from:getPhase() ~= sgs.Player_NotActive then
			return -from:getMark("benxi_po")
		end
		return 0
	end,
}

benxi_po_drawskill = sgs.CreateTriggerSkill{
	name = "benxi_po_drawskill",
	events = {sgs.DamageComplete},
	priority = -1,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("benxi_po_drawcard") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag("benxi_po_drawer") then
						p:drawCards(1)
					end
				end
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("benxi_po_drawskill") then skills:append(benxi_po_drawskill) end

wuyi_po:addSkill(benxi_po)
wuyi_po:addSkill(benxi_poDistance)

sgs.LoadTranslationTable{
	["wuyi_po"] = "界吳懿",
	["&wuyi_po"] = "吳懿",
	["#wuyi_po"] = "",
	["benxi_po"] = "奔襲",
	[":benxi_po"] = "鎖定技，當你於回合內使用牌時，本回合你計算與其他角色的距離-1；你的回合內，若你與所"..
	"有其他角色的距離均為1，則你使用僅指定一個目標的【殺】或普通錦囊牌時依次選擇至多兩項："..
	"1.此牌目標+1；2.此牌無視防具；3.此牌不能被抵消；4.此牌造成傷害時，摸一張牌。",
	["benxi_po_extra"] = "選擇一個額外的目標",
	["benxi_po_armor"] = "此牌無視防具",
	["benxi_po_draw"] = "此牌造成傷害時，摸一張牌。",
	["benxi_po_nores"] = "此牌不能被抵消",
	["benxi_po_drawskill"] = "奔襲",
	
	["@benxi_po"] = "你可以多選擇一個目標。",
	["~benxi_po"] = "選擇目標角色→點“確定”",
}

--全琮
quancong_po = sgs.General(extension,"quancong_po","wu2","4",true)
--邀名

yaoming_po = sgs.CreateTriggerSkill{
	name = "yaoming_po", 
	events = {sgs.Damage, sgs.Damaged}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHandcardNum() > player:getHandcardNum() and player:getMark("yaoming_po_1-Clear") == 0 then
				players:append(p)
			elseif p:getHandcardNum() < player:getHandcardNum() and player:getMark("yaoming_po_2-Clear") == 0 then
				players:append(p)
			elseif p:getHandcardNum() == player:getHandcardNum() and player:getMark("yaoming_po_3-Clear") == 0 then
				players:append(p)
			end
		end
		if not room:getCurrent():hasFlag(self:objectName()..player:objectName()) then
			local target = room:askForPlayerChosen(player, players, self:objectName(), "yaoming_po-invoke", true, true)
			if target then
				room:getCurrent():setFlags(self:objectName()..player:objectName())
				if target:getHandcardNum() > player:getHandcardNum() then
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local to_throw = room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(to_throw), target, player)
						room:setPlayerMark(player,"yaoming_po_1-Clear",1)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				elseif target:getHandcardNum() < player:getHandcardNum() then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						target:drawCards(1)
						room:setPlayerMark(player,"yaoming_po_2-Clear",1)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				elseif target:getHandcardNum() == player:getHandcardNum() then
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local cards = room:askForExchange(target, self:objectName(), 2, 0, true,"@yaoming_po3")
						 if cards and not cards:getSubcards():isEmpty() then
						 	room:throwCard(cards, target, target)
						 	room:getThread():delay()
							target:drawCards(cards:getSubcards():length())
						end
						room:setPlayerMark(player,"yaoming_po_3-Clear",1)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}
quancong_po:addSkill(yaoming_po)

sgs.LoadTranslationTable{
["quancong_po"] = "界全琮",
["&quancong_po"] = "全琮",
["#quancong_po"] = "白馬王子",
["yaoming_po"] = "邀名",
[":yaoming_po"] = "每回合每個選項限一次，當你造成或受到傷害後，你可以選"..
	"擇一項：1.棄置手牌數大於你的一名角色的一張手牌；2.令手牌數小於你的一名角色摸一張牌；"..
	"3.令手牌數與你相同的一名角色棄置至多兩張牌然後摸等量的牌。",
["$yaoming_po1"] = "看我如何以無用之栗，換己所需，哈哈哈......",
["$yaoming_po2"] = "民不足食，何以養君。",
["~quancong_po"] = "患難可共濟，生死不同等...",
["yaoming_po-invoke"] = "你可以發動“邀名”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/><b提示</b>: 你可以棄置一名手牌數大於你的角色一張手牌，或是令一名手牌數小於你的角色摸一張牌。<br/>",
["@yaoming_po3"] = "你可以棄置至多兩張牌然後摸等量的牌。",
}

--于禁
yujin_po = sgs.General(extension, "yujin_po", "wei2", 4, true)
--鎮軍
zhenjun_po = sgs.CreatePhaseChangeSkill{
	name = "zhenjun_po",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:isNude() then
				players:append(p)
			end
		end
		if (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and (not players:isEmpty()) then
			local to = room:askForPlayerChosen(player, players, self:objectName(), "zhenjun_po-invoke", true, true)
			if to then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerFlag(to, "Fake_Move")
					local x = math.max((to:getHandcardNum() - math.max(to:getHp(), 0)),1)
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
					local has_equip_card = false
					for i = 0, dummy:subcardsLength() - 1, 1 do
						--room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), to, original_places:at(i), false)
						if sgs.Sanguosha:getCard(card_ids:at(i)):isKindOf("EquipCard") then
							has_equip_card = true
						end
					end
					room:setPlayerFlag(to, "-Fake_Move")
--					if dummy:subcardsLength() > 0 then
--						room:throwCard(dummy, to, player)
--					end
					if not has_equip_card then
						if x > 0 then
							local cards = room:askForExchange(player, self:objectName(), 1, 1, true, "@zhenjun_po", true)
							if cards then
								room:throwCard(cards, player, player)
							else
								--if n == 0 and not room:askForSkillInvoke(player, self:objectName()) then return false end
								to:drawCards(x, self:objectName())
							end
						end
					end
					--[[
					if n == 0 and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..n)) then
						to:drawCards(n, self:objectName())
					end
					]]--
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
yujin_po:addSkill(zhenjun_po)

sgs.LoadTranslationTable{
	["yujin_po"] = "界于禁",
	["&yujin_po"] = "于禁",
	["#yujin_po"] = "臨危不懼",
	["illustrator:yujin_po"] = "",
	["zhenjun_po"] = "鎮軍",
	[":zhenjun_po"] = "準備階段或結束階段，你可以棄置一名角色X張牌（X為其手牌數減體力值且至少為1），若其中沒有裝備牌，"..
	"你選擇一項：1.你棄一張牌；2.該角色摸等量的牌",
	["zhenjun_po:draw"] = "你想發動“鎮軍”令對方摸 %src 張牌嗎?",
	["$zhenjun_po1"] = "",
	["$zhenjun_po2"] = "",
	["~yujin_po"] = "我…無顏面對丞相了……",
	["@zhenjun_po"] = "你可以棄置一張牌，否則該角色摸等量的牌。<br/> <b>操作提示</b>: 選擇若干張牌→點擊確定<br/>",
	["zhenjun_po-invoke"] = "你可以發動“鎮軍”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
}

--朱然
zhuran_po = sgs.General(extension,"zhuran_po","wu2","4",true)
--膽守 每個回合限一次，當你成為基本牌或錦囊牌的目標後，你可以摸X張牌（X為你本回合成為牌的目標次數）；
--當前回合角色的結束階段，若你本回合沒有以此法摸牌，你可以棄置與其手牌數相同的牌數對其造成1點傷害。
danshou_po = sgs.CreateTriggerSkill{
	name = "danshou_po" ,
	events = {sgs.TargetConfirmed,sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
--			if use.to:contains(player) and player:hasSkill("danshou_po") and (not use.card:isKindOf("SkillCard")) then
			if use.to:contains(player) and player:hasSkill("danshou_po") and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) then
					if player:getMark("danshou_po_hasdraw-Clear") == 0 then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							local n = player:getMark("@danshou_po-Clear")
							player:drawCards(n, self:objectName())
							room:setPlayerMark(player,"danshou_po_hasdraw-Clear",1)
						end
					end
				--end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("danshou_po") then
						if p:getMark("danshou_po_hasdraw-Clear") == 0 then
							local n = player:getHandcardNum()
							if n > 0 and ((p:getHandcardNum() + p:getEquips():length()) >= n) then
								local cards = room:askForExchange(p, self:objectName(), n, n, true, "@danshou_po_ask", true)
								if cards then
									room:broadcastSkillInvoke(self:objectName())
									room:doAnimate(1, p:objectName(), player:objectName())
									room:throwCard(cards, p, p)
									room:damage(sgs.DamageStruct("danshou_po", p, player, 1, sgs.DamageStruct_Normal))
								end
							elseif n == 0 then
								local _data = sgs.QVariant()
								_data:setValue(player)
								if room:askForSkillInvoke(p, "danshou_po_damage", _data) then
									room:broadcastSkillInvoke(self:objectName())
									room:doAnimate(1, p:objectName(), player:objectName())
									room:damage(sgs.DamageStruct("danshou_po", p, player, 1, sgs.DamageStruct_Normal))
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

zhuran_po:addSkill(danshou_po)

sgs.LoadTranslationTable{
	["zhuran_po"] = "界朱然",
	["&zhuran_po"] = "朱然",
	["#zhuran_po"] = "不動之督",
	["illustrator:zhuran_po"] = "",
	["danshou_po"] = "膽守",
	["danshou_po_damage"] = "膽守傷害",
	[":danshou_po"] = "每個回合限一次，當你成為基本牌或錦囊牌的目標後，你可以摸X張牌（X為你本回合成為牌的目標次數）；"..
	"當前回合角色的結束階段，若你本回合沒有以此法摸牌，你可以棄置與其手牌數相同的牌數對其造成1點傷害。",
	["@danshou_po_ask"] = "你可以棄置與其手牌數相同的牌數對其造成1點傷害。<br/> <b>操作提示</b>: 選擇若干張牌→點擊確定<br/>",
	["@danshou_po"] = "膽守",
}

--界張角
zhangjiao_po = sgs.General(extension, "zhangjiao_po$", "qun2", "3", true)
--雷擊
leiji_po = sgs.CreateTriggerSkill{
	name = "leiji_po",
	events = {sgs.CardResponded,sgs.FinishJudge,sgs.CardUsed},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local card_star = data:toCardResponse().m_card
			if card_star:isKindOf("Jink") then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:getThread():delay(1000)
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = false
					judge.negative = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Lightning") then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:getThread():delay(1000)
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = false
					judge.negative = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
				end
			end
		elseif event == sgs.FinishJudge then 
			local judge = data:toJudge()
			local card = judge.card
			if judge.reason ~= "baonue" and judge.reason ~= "ol_baonue" then
				if judge.card:getSuit() == sgs.Card_Spade then
					if player:askForSkillInvoke(self:objectName(),data) then
						local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "leiji_po-invoke", true, true)
						if target then
							room:doAnimate(1, player:objectName(), target:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:damage(sgs.DamageStruct(self:objectName(), player, target, 2, sgs.DamageStruct_Thunder))
						end
					end
				elseif judge.card:getSuit() == sgs.Card_Club then
					if player:askForSkillInvoke(self:objectName(),data) then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
						local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "leiji_po-invoke", true, true)
						if target then
							room:doAnimate(1, player:objectName(), target:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
						end
					end
				end
			end
		end
	end
}

guidao_po = sgs.CreateTriggerSkill{
	name = "guidao_po" ,
	events = {sgs.AskForRetrial} ,
	can_trigger = function(self, target)
		if not (target and target:isAlive() and target:hasSkill(self:objectName())) then return false end
		if target:isKongcheng() then
			local has_black = false
			for i = 0, 3, 1 do
				local equip = target:getEquip(i)
				if equip and equip:isBlack() then
					has_black = true
					break
				end
			end
			return has_black
		else
			return true
		end
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local prompt_list = {
			"@guidao-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			tostring(judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".|black", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:broadcastSkillInvoke(self:objectName())
			room:retrial(card, player, judge, self:objectName(), true)
			if card:getSuit() == sgs.Card_Spade and (card:getNumber() >= 2 and card:getNumber() <= 9) then
				player:drawCards(1)
			end
		end
		return false
	end
}

zhangjiao_po:addSkill(leiji_po)
zhangjiao_po:addSkill(guidao_po)
zhangjiao_po:addSkill("huangtian")

sgs.LoadTranslationTable{
	["#zhangjiao_po"] = "天公將軍",
	["zhangjiao_po"] = "界張角",
	["&zhangjiao_po"] = "張角",
	["illustrator:zhangjiao_po"] = "LiuHeng",
	["leiji_po"] = "雷擊",
	[":leiji_po"] = "每當你使用或打出一張【閃】或是【閃電】時，你可以進行判定；當你進行判定後，若判定結果為：黑桃，你選擇一名角色，對其造成2點雷電傷害；梅花，你回復1點體力，然後你選擇一名角色，對其造成1點雷電傷害。",
	["leiji_po-invoke"] = "你可以發動“雷擊”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	["guidao_po"] = "鬼道",
	[":guidao_po"] = "每當一名角色的判定牌生效前，你可以打出一張黑色牌替換之；若你打出的牌是黑桃2-9，則你摸一張牌。",
	["~guidao_po"] = "選擇一張黑色牌→點擊確定",
	["huangtian"] = "黃天",
	[":huangtian"] = "主公技。階段技。其他群雄角色的出牌階段，該角色可以交給你一張【閃】或【閃電】。",
	["huangtian_attach"] = "黃天送牌",
}



--OL界典韋
dianwei_po = sgs.General(extension, "dianwei_po", "wei2", "4", true)

qiangxi_poCard = sgs.CreateSkillCard{
	name = "qiangxi_poCard", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() or to_select:getMark("qiangxi_po-Clear") > 0 then return false end--根据描述应该可以选择自己才对
		return true
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then 
			room:loseHp(effect.from)
		end
		room:setPlayerMark(effect.to,"qiangxi_po-Clear",1)
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
	end
}
qiangxi_po = sgs.CreateViewAsSkill{
	name = "qiangxi_po", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("Weapon") and not sgs.Self:isJilei(to_select)
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return qiangxi_poCard:clone()
		elseif #cards == 1 then
			local card = qiangxi_poCard:clone()
			card:addSubcard(cards[1])
			return card
		else 
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("qiangxi_poCard") < 2
	end,
}

dianwei_po:addSkill(qiangxi_po)

sgs.LoadTranslationTable{
["#dianwei_po"] = "古之惡來",
["&dianwei_po"] = "典韋",
["dianwei_po"] = "OL界典韋",
["illustrator:dianwei_po"] = "小冷",
["qiangxi_po"] = "強襲",
[":qiangxi_po"] = "出牌階段限兩次，你可以失去1點體力或棄置一張武器牌，並選擇一名本回合你未以此法選擇過的角色：若如此做，你對該角色造成1點傷害。",
}

--界何太后
hetaihou_po = sgs.General(extension, "hetaihou_po", "qun2", "3", false)

zhendu_po = sgs.CreateTriggerSkill {
	name = "zhendu_po",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then
			return false
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("zhendu_po") and p:canDiscard(p, "h") then
				if room:askForCard(p, ".", "@zhendu_po-discard", sgs.QVariant(), self:objectName()) then
					room:doAnimate(1, p:objectName(), player:objectName())
					local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
					analeptic:setSkillName(self:objectName())
					room:useCard(sgs.CardUseStruct(analeptic, player, sgs.SPlayerList(), true))
					if player:isAlive() and (p:objectName() ~= player:objectName()) then
						room:damage(sgs.DamageStruct(self:objectName(), p, player))
					end
				end
				return false
			end
		end
	end
}

qiluan_po = sgs.CreateTriggerSkill{
	name = "qiluan_po", 
	frequency = sgs.Skill_Frequent, --, NotFrequent, Compulsory, Limited, Wake 
	events = {sgs.EventPhaseChanging}, 
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			local hetaihous = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("qiluan_po-Clear") > 0 and p:hasSkill("qiluan_po") then
					hetaihous:append(p)
				end
			end
			for _,p in sgs.qlist(hetaihous) do
				if room:askForSkillInvoke(p, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					p:drawCards(p:getMark("qiluan_po-Clear"))
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

hetaihou_po:addSkill(zhendu_po)
hetaihou_po:addSkill(qiluan_po)

sgs.LoadTranslationTable{
	["#hetaihou_po"] = "弄權之蛇蠍",
	["hetaihou_po"] = "OL何太后",
	["&hetaihou_po"] = "何太后",
	["illustrator:hetaihou_po"] = "KayaK, 木美人",
	["zhendu_po"] = "鴆毒",
	[":zhendu_po"] = "一名角色的出牌階段開始時，妳可以棄置一張手牌：若如此做，視為該角色使用一張【酒】（計入次數限制），然後若該角色不為妳，妳對其造成1點傷害。",
	["@zhendu_po-discard"] = "妳可以棄置一張手牌發動“鴆毒”",
	["qiluan_po"] = "戚亂",
	[":qiluan_po"] = "每當一名角色的回合結束時，本回合每有一名角色死亡，若該角色為妳殺死，妳可以摸三張牌；否則妳可以摸一張牌。",
}

--界臥龍
wolong_po = sgs.General(extension, "wolong_po", "shu2", "3", true)

kanpo_po = sgs.CreateOneCardViewAsSkill{
	name = "kanpo_po",
	filter_pattern = ".|black|.|.",
	response_pattern = "nullification",
	view_as = function(self, first)
		local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
		ncard:addSubcard(first)
		ncard:setSkillName(self:objectName())
		return ncard
	end,
	enabled_at_nullification = function(self, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isBlack() then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:isBlack() then return true end
		end
		return false
	end
}

huoji_po = sgs.CreateOneCardViewAsSkill{
	name = "huoji_po",
	filter_pattern = ".|red|.|.",
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
		fireattack:setSkillName(self:objectName())
		fireattack:addSubcard(id)
		return fireattack
	end
}

cangzhuo = sgs.CreateTriggerSkill{
	name = "cangzhuo" ,
	frequency = sgs.Skill_Compulsory ,
	global = true ,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseEnd} ,   
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging and player:hasSkill("cangzhuo") and player:getMark("used_trick-Clear") == 0 then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
						room:setPlayerMark(player, self:objectName()..id.."-Clear" ,1)
						room:setPlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString(), false)
					end
				end
			end
		elseif event == sgs.EventPhaseEnd and player:hasSkill("cangzhuo") then
			if player:getPhase() == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if player:getMark(self:objectName()..id.."-Clear") > 0 then
						room:removePlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString().."$0")
					end
				end
			end
		end
		return false
	end
}

cangzhuomc = sgs.CreateMaxCardsSkill{
	name = "#cangzhuomc",
	extra_func = function(self, target)
		if target:hasSkill("cangzhuo") and target:getMark("used_trick-Clear") == 0 then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:isKindOf("TrickCard") then
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

wolong_po:addSkill("bazhen")
wolong_po:addSkill(huoji_po)
wolong_po:addSkill(kanpo_po)
wolong_po:addSkill(cangzhuo)
wolong_po:addSkill(cangzhuomc)

sgs.LoadTranslationTable{
["#wolong_po"] = "臥龍",
["wolong_po"] = "界臥龍",
["&wolong_po"] = "諸葛亮",
["illustrator:wolong_po"] = "北",
["bazhen"] = "八陣",
[":bazhen"] = "鎖定技。若你的裝備區沒有防具牌，視為你裝備【八卦陣】。",
["huoji_po"] = "火計",
[":huoji_po"] = "你可以將一張紅色牌當【火攻】使用。",
["kanpo_po"] = "看破",
[":kanpo_po"] = "你可以將一張黑色牌當【無懈可擊】使用。",
["cangzhuo"] = "藏拙",
[":cangzhuo"] = "鎖定技，棄牌階段開始時，若你本回合未使用過錦囊牌，你的錦囊牌不計入手牌上限。",
}

--界龐統
pangtong_po = sgs.General(extension, "pangtong_po", "shu2", "3", true)

lianhuan_po = sgs.CreateViewAsSkill{
	name = "lianhuan_po",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (to_select:getSuit() == sgs.Card_Club)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local chain = sgs.Sanguosha:cloneCard("iron_chain", cards[1]:getSuit(), cards[1]:getNumber())
			chain:addSubcard(cards[1])
			chain:setSkillName(self:objectName())
			return chain
		end
	end
}

lianhuan_poTargetMod = sgs.CreateTargetModSkill{
	name = "#lianhuan_poTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "IronChain",
	extra_target_func = function(self, player)
		if player:hasSkill("lianhuan_po") then
			return 1
		end
	end,
}

niepan_po = sgs.CreateTriggerSkill{
	name = "niepan_po",
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeaches},
	limit_mark = "@nirvana",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("pangtong_po", self:objectName())
				room:removePlayerMark(player, "@nirvana")
				player:throwAllCards()
				local maxhp = player:getMaxHp()
				local hp = math.min(3, maxhp)
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				player:drawCards(3)
				if player:isChained() then
					local damage = dying_data.damage
					if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				for _, card in sgs.qlist(player:getJudgingArea()) do
					if not card:isKindOf("SkillCard") then 
						room:throwCard(card, player)
					end
				end
				if not player:faceUp() then
					player:turnOver()
				end
				local choices = {"bazhen","huoji_po","kanpo_po"}
				local choice = room:askForChoice(player, "niepan_po", table.concat(choices, "+"))
				if choice then
					room:acquireSkill(player, choice)
				end

			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@nirvana") > 0
				end
			end
		end
		return false
	end
}

pangtong_po:addSkill(lianhuan_po)
pangtong_po:addSkill(lianhuan_poTargetMod)
pangtong_po:addSkill(niepan_po)
extension:insertRelatedSkills("lianhuan_po","#lianhuan_poTargetMod")

sgs.LoadTranslationTable{
["#pangtong_po"] = "鳳雛",
["pangtong_po"] = "界龐統",
["&pangtong_po"] = "龐統",
["lianhuan_po"] = "連環",
[":lianhuan_po"] = "你可以將一張梅花牌當【鐵索連環】使用或重鑄；你使用【鐵索連環】可以額外選擇一名目標。",
["niepan_po"] = "涅槃",
[":niepan_po"] = "限定技，當你處於瀕死狀態時，你可以棄置所有牌，然後復原你的武將牌，摸三張牌，將體力回復至3點。"..
"然後你從“八陣”、“火計”、“看破”中選擇一個技能獲得。" ,
["$NiepanAnimate"] = "image=image/animate/niepan.png",
}

--劉禪
liushan_po = sgs.General(extension, "liushan_po$", "shu2", "3", true)

fangquan_poCard = sgs.CreateSkillCard{
	name = "fangquan_po",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local _player = effect.to
		local p = _player
		local playerdata = sgs.QVariant()
		playerdata:setValue(p)
		room:setTag("fangquan_poTarget", playerdata)		
	end
}
fangquan_poVS = sgs.CreateViewAsSkill{
	name = "fangquan_po",
	response_pattern = "@@fangquan_po",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = fangquan_poCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function()
		return false
	end,
}

fangquan_po = sgs.CreateTriggerSkill{
	name = "fangquan_po" ,
	view_as_skill = fangquan_poVS,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			local invoked = false
			if player:isSkipped(sgs.Player_Play) then return false end
			if room:askForSkillInvoke(player,self:objectName(),data) then
				player:setFlags("fangquan_po")
				player:skip(sgs.Player_Play)
			end
		elseif change.to == sgs.Player_Discard then
			if player:hasFlag("fangquan_po") then
				if player:canDiscard(player, "h") then
					room:askForUseCard(player, "@@fangquan_po", "@fangquan_po-give", -1, sgs.Card_MethodDiscard)
				end
			end
		end
		return false
	end
}

fangquan_poGive = sgs.CreateTriggerSkill{
	name = "fangquan_poGive" ,
	events = {sgs.EventPhaseStart} ,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_NotActive then
			if room:getTag("fangquan_poTarget") then
				local target = room:getTag("fangquan_poTarget"):toPlayer()
				room:removeTag("fangquan_poTarget")
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
		end
		return false
	end ,
	priority = 1
}
if not sgs.Sanguosha:getSkill("fangquan_poGive") then skills:append(fangquan_poGive) end

ruoyu_po = sgs.CreateTriggerSkill{
	name = "ruoyu_po$",
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
			room:addPlayerMark(player, "ruoyu_po")
			if room:changeMaxHpForAwakenSkill(player, 1) then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("liushan_po", self:objectName())
				room:acquireSkill(player, "jijiang")
				room:acquireSkill(player, "sishu")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasLordSkill("ruoyu_po")
				and target:isAlive()
				and (target:getMark("ruoyu_po") == 0)
	end
}

sishu = sgs.CreateTriggerSkill{
	name = "sishu",
	events = {sgs.EventPhaseStart, sgs.StartJudge},
	global = true,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Play then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("@sishu") == 0 then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "sishu", "@sishu-choose", true, true)
					if s then
						room:addPlayerMark(s,"@sishu")
					end
				end
			end
		elseif event == sgs.StartJudge then
			local judge = data:toJudge()
			if player:getMark("@sishu") > 0 and judge.reason == "indulgence" then
				judge.good = not judge.good
				room:sendCompulsoryTriggerLog(player, self:objectName())
			end
		end
		return false
	end,
}

liushan_po:addSkill("xiangle")
liushan_po:addSkill(fangquan_po)
liushan_po:addSkill(ruoyu_po)

if not sgs.Sanguosha:getSkill("sishu") then skills:append(sishu) end

liushan_po:addRelateSkill("sishu")

sgs.LoadTranslationTable{
	["#liushan_po"] = "無為的真命主",
	["&liushan_po"] = "劉禪",
	["liushan_po"] = "界劉禪",
	["illustrator:liushan_po"] = "LiuHeng",

	["fangquan_po"] = "放權",
	[":fangquan_po"] = "你可以跳過出牌階段，然後棄牌階段開始時，你可以棄置一張手牌並令一名其他角色獲得一個額外的回合。",
	["@fangquan_po-give"] = "你可以棄置一張手牌令一名其他角色進行一個額外的回合",
	["~fangquan_po"] = "選擇一張手牌→選擇一名其他角色→點擊確定",

	["@fangquan_po-give"] = "你可以棄置一張手牌令一名其他角色進行一個額外的回合",
	["~fangquan_po"] = "選擇一張手牌→選擇一名其他角色→點擊確定",
	["ruoyu_po"] = "若愚",
	[":ruoyu_po"] = "主公技，覺醒技，準備階段，若你是體力值最小的角色，你加1點體力上限，回復1點體力，然後獲得「激將」和「思蜀」。",

	["sishu"] = "思蜀",
	[":sishu"] = "出牌階段開始時，你可以指定一名角色，令其本局遊戲中【樂不思蜀】判定效果反轉。",
	["@sishu-choose"] = "你可以令一名角色本局遊戲中【樂不思蜀】判定效果反轉。",
	["#Fangquan"] = "%to 將進行一個額外的回合",
}

--界孫策

sunce_po = sgs.General(extension, "sunce_po$", "wu2", "4", true)

hunzi_po = sgs.CreateTriggerSkill{
	name = "hunzi_po" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke("hunzi_po")
		room:doSuperLightbox("sunce_po","hunzi_po")
		if player:getHp() == 1 then
			local msg = sgs.LogMessage()
			msg.type = "#HunziWake"
			msg.from = player
			msg.to:append(player)
			msg.arg = self:objectName()
			room:sendLog(msg)
		end
		room:addPlayerMark(player, "hunzi_po")
		room:addPlayerMark(player, "hunzi")
		if room:changeMaxHpForAwakenSkill(player) then
			room:recover(player, sgs.RecoverStruct(player))
			room:handleAcquireDetachSkills(player, "yingzi|yinghun")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("hunzi_po") == 0)
				and (target:getPhase() == sgs.Player_Start)
				and (target:getHp() <= 1 or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}

zhiba_poCard = sgs.CreateSkillCard{
	name = "zhiba_po",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:hasLordSkill("zhiba_po") then
				if to_select:objectName() ~= sgs.Self:objectName() then
					if not to_select:isKongcheng() then
						return to_select:getMark("zhiba_po_Play") == 0
					end
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("zhiba_po_audio",1)
		room:addPlayerMark(target, "zhiba_po_Play")
		local choice = room:askForChoice(target, "zhiba_popindian", "accept+reject")
		if choice == "reject" then
			room:broadcastSkillInvoke("zhiba_po_audio",4)
			return
		end
		source:pindian(target, "zhiba_popindian", self)
		local sunces = sgs.SPlayerList()
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:hasLordSkill("zhiba_po") then
				if not p:hasFlag("ZhibaInvoked") then
					sunces:append(p)
				end
			end
		end
		if sunces:length() == 0 then
			room:addPlayerMark(source, "Forbidzhiba_po_Play")
		end
	end
}
zhiba_popindian = sgs.CreateViewAsSkill{
	name = "zhiba_popindian&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = zhiba_poCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "wu" then
			if not player:isKongcheng() then
				return player:getMark("Forbidzhiba_po_Play") == 0
			end
		end
		return false
	end
}

zhiba_poselfCard = sgs.CreateSkillCard{
	name = "zhiba_poself",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:getKingdom() == "wu" then
				if to_select:objectName() ~= sgs.Self:objectName() then
					if not to_select:isKongcheng() then
						return true
					end
				end
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("zhiba_po_audio",1)
		source:pindian(target, "zhiba_poself", self)

	end
}
zhiba_poVS = sgs.CreateViewAsSkill{
	name = "zhiba_po",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = zhiba_poselfCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zhiba_poself")
	end
}


zhiba_po = sgs.CreateTriggerSkill{
	name = "zhiba_po$",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = zhiba_poVS,
	events = {sgs.GameStart, sgs.Pindian, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart or event == sgs.EventAcquireSkill and data:toString() == self:objectName() then
			local lords = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasLordSkill(self:objectName()) then
					lords:append(p)
				end
			end
			if lords:isEmpty() then return false end

			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if not p:hasSkill("zhiba_popindian") then
					room:attachSkillToPlayer(p, "zhiba_popindian")
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "zhiba_po" then
			local lords = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasLordSkill(self:objectName()) then
					lords:append(p)
				end
			end
			if lords:length() > 0 then return false end

			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("zhiba_popindian") then
					room:detachSkillToPlayer(p, "zhiba_popindian", true)
				end
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "zhiba_popindian" then
				if pindian.to:hasLordSkill(self:objectName()) then
					if pindian.from_number <= pindian.to_number then
						room:broadcastSkillInvoke("zhiba_po_audio",2)
						local choice = room:askForChoice(pindian.to, "zhiba_popindian_obtain", "reject+obtainPindianCards")
						if choice == "obtainPindianCards" then
							pindian.to:obtainCard(pindian.from_card)
							pindian.to:obtainCard(pindian.to_card)
						end
					else
						room:broadcastSkillInvoke("zhiba_po_audio",3)
					end
				end
				--發動自身的主公技
			elseif pindian.reason == "zhiba_poself" then
				if pindian.from:hasLordSkill(self:objectName()) then
					if pindian.from_number >= pindian.to_number then
						room:broadcastSkillInvoke("zhiba_po_audio",2)
						local choice = room:askForChoice(pindian.to, "zhiba_popindian_obtain", "reject+obtainPindianCards")
						if choice == "obtainPindianCards" then
							pindian.from:obtainCard(pindian.from_card)
							pindian.from:obtainCard(pindian.to_card)
						end

					else
						room:broadcastSkillInvoke("zhiba_po_audio",3)
					end
				end
			end
		end
		return false
	end,
	priority = -1,
}

--配音部分
zhiba_po_audio = sgs.CreateTriggerSkill{
	name = "zhiba_po_audio",
	events = {},
	on_trigger = function()
	end,
}

sunce_po:addSkill("jiang")
sunce_po:addSkill(hunzi_po)
sunce_po:addSkill(zhiba_po)
sunce_po:addRelateSkill("zhiba_po_audio")

if not sgs.Sanguosha:getSkill("zhiba_popindian") then skills:append(zhiba_popindian) end
if not sgs.Sanguosha:getSkill("zhiba_po_audio") then skills:append(zhiba_po_audio) end

sgs.LoadTranslationTable{
["#sunce_po"] = "江東的小霸王",
["sunce_po"] = "界孫策",
["&sunce_po"] = "孫策",
["jiang"] = "激昂",
[":jiang"] = "每當你指定或成為紅色【殺】或【決鬥】的目標後，你可以摸一張牌。",
["hunzi_po"] = "魂姿",
[":hunzi_po"] = "覺醒技。準備階段開始時，若你的體力值為1，你失去1點體力上限並恢復一點體力，然後獲得“英姿”和“英魂”。",
["#HunziWake"] = "%from 的體力值為 <font color=\"yellow\"><b>1</b></font>，觸發“%arg”覺醒",
["$HunziAnimate"] = "image=image/animate/hunzi.png",

["zhiba_po"] = "制霸",
["zhiba_popindian"] = "制霸",
["zhiba_poself"] = "制霸",
[":zhiba_po"] = "主公技。階段技。其他吳勢力角色的出牌階段，該角色可以與你拼點(你可以拒絕此拼點)；你的出牌階段限一次，你可與其他吳勢力角色拼點。若其沒贏，你可以獲得拼點的兩張牌",
["zhiba_pindian:accept"] = "接受",
["zhiba_pindian:reject"] = "拒絕",
["zhiba_pindian_obtain"] = "制霸獲得牌",
["zhiba_pindian_obtain:obtainPindianCards"] = "獲得拼點牌",
["zhiba_pindian_obtain:reject"] = "不獲得",
["#ZhibaReject"] = "%from 拒絕 %to 發動“%arg”",
["#HunziWake"] = "%from 的體力值為 <font color=\"yellow\"><b>1</b></font>，觸發“%arg”覺醒",
}

--界袁紹
yuanshao_po = sgs.General(extension, "yuanshao_po$", "qun2")

luanji_poVS = sgs.CreateViewAsSkill{
	name = "luanji_po",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
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

luanji_po = sgs.CreateTriggerSkill{
	name = "luanji_po", 
	view_as_skill = luanji_poVS, 
	events = {sgs.PreCardUsed}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("ArcheryAttack") then
				if use.to:length() > 1 then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(use.to) do
						_targets:append(p)
					end
					room:setTag("luanji_poData", data)
					local s = room:askForPlayerChosen(player, _targets, "luanji_po", "@luanji_po_use", true)
					if s then
						if use.to:contains(s) then
							room:doAnimate(1, player:objectName(), s:objectName())
							use.to:removeOne(s)
							room:sortByActionOrder(use.to)
							data:setValue(use)
						end
					end
					room:removeTag("luanji_poData")
				end
			end
		end
	end,
}

xueyi_po = sgs.CreateTriggerSkill{
	name = "xueyi_po$",
	events = {sgs.GameStart,sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == "qun" or p:getKingdom() == "qun2" then
					n = n + 1
				end
			end
			room:setPlayerMark(player,"@xueyi_po" ,n)
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:getMark("@xueyi_po") > 0 then
				if room:askForSkillInvoke(player,"xueyi_po", data) then
					player:drawCards(1)
					player:loseMark("@xueyi_po")
				end
			end 
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasLordSkill("xueyi_po")
	end,
}

xueyi_poMax = sgs.CreateMaxCardsSkill{
	name = "#xueyi_poMax", 
	extra_func = function(self, target)
		if target:hasLordSkill("xueyi_po") then
			return target:getMark("@xueyi_po")*2
		end
	end
}


yuanshao_po:addSkill(luanji_po)
yuanshao_po:addSkill(xueyi_po)
yuanshao_po:addSkill(xueyi_poMax)

sgs.LoadTranslationTable{
["yuanshao_po"] = "界袁紹",
["&yuanshao_po"] = "袁紹",
["#yuanshao_po"] = "高貴的名門",
["luanji_po"] = "亂擊",
[":luanji_po"] = "你可以將兩張花色相同的手牌當【萬箭齊發】使用；你使用【萬箭齊發】可以少選一個目標。",
["@luanji_po_use"] = "你可以少選一個目標。",

["xueyi_po"] = "血裔",
[":xueyi_po"] = "主公技，遊戲開始時，你獲得X個“裔”標記（X為群雄勢力角色數）；回合開始時，你可以移除一個「裔」並摸一張牌；你每有一個「裔」，手牌上限+2。",
["#xueyi_poMax"] = "血裔",
["@xueyi_po"] = "裔",

["$luanji_po1"] = "放箭！放箭！",
["$luanji_po2"] = "箭支充足，儘管取用~",
["$xueyi_po1"] = "世受皇恩，威震海內！",
["$xueyi_po2"] = "四世三公，名冠天下！",
["~yuanshao_po"] = "我袁家~怎麼會輸？",
}

--界孫魯班
sunluban_po = sgs.General(extension, "sunluban_po", "wu2", "3", false)
--譖毀
zenhui_po = sgs.CreateTriggerSkill{
	name = "zenhui_po" ,
	events = {sgs.PreCardUsed} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if (room:alivePlayerCount() > 2) and (use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.card:isBlack()))
			 and not use.card:isKindOf("Nullification") and
			  not use.card:isKindOf("Collateral") and use.to:length() == 1 and player:getMark("zenhui_po_used-Clear") == 0 then

			  	local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if room:alivePlayerCount() > 2 then
						if (not use.to:contains(p)) and p:objectName() ~= use.from:objectName() then
							_targets:append(p)
						end
					end
				end

				if not _targets:isEmpty() then
					room:setPlayerFlag(player, "zenhui_potm")
					room:setTag("zenhui_po", data)	
					local s = room:askForPlayerChosen(player, _targets, "zenhui_po", "zenhui_po-invoke:".. use.to:first():objectName(), true)
					room:removeTag("zenhui_po")
					if s then
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						local card = room:askForCard(s, ".Equip", "@zenhui_po-give:"..player:objectName(), data, sgs.Card_MethodNone)
						if card then
							room:obtainCard(player,card, true)
							use.from = s
							data:setValue(use)
						else
							room:setPlayerMark(player,"zenhui_po_used-Clear",1)
							use.to:append(s)
							room:sortByActionOrder(use.to)
							data:setValue(use)
						end
					end
					room:setPlayerFlag(player, "-zenhui_potm")	
				end
			end
		end
		return false
	end
}
zenhui_potm = sgs.CreateTargetModSkill{
	name = "#zenhui_potm" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("zenhui_potm")) then
			return 1000
		end
		return 0
	end
}
--驕矜
jiaojin_po = sgs.CreateTriggerSkill{
	name = "jiaojin_po" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and use.from:isMale() then
				if use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
					if room:askForCard(player, ".Equip", "@jiaojin_po", data, self:objectName()) then
						player:setFlags("-ZhenlieTarget")
						player:setFlags("ZhenlieTarget")
						if player:isAlive() and player:hasFlag("ZhenlieTarget") then
							room:notifySkillInvoked(player, "jiaojin_po")
							room:broadcastSkillInvoke(self:objectName())
							player:setFlags("-ZhenlieTarget")
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)

							local ids = sgs.IntList()
							if use.card:isVirtualCard() then
								ids = use.card:getSubcards()
							else
								ids:append(use.card:getEffectiveId())
							end
							if ids:isEmpty() then return end
							for _, id in sgs.qlist(ids) do
								if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
							end

							room:obtainCard(player,use.card,true)
						end
					end
				end
			end
		end
		return false
	end
}

sunluban_po:addSkill(zenhui_po)
sunluban_po:addSkill(zenhui_potm)
sunluban_po:addSkill(jiaojin_po)

sgs.LoadTranslationTable{
["#sunluban_po"] = "為虎作倀",
["sunluban_po"] = "界孫魯班",
["&sunluban_po"] = "孫魯班",
["illustrator:sunluban_po"] = "FOOLTOWN",
["designer:sunluban_po"] = "CatCat44",
["zenhui_po"] = "譖毀",
[":zenhui_po"] = "出牌階段，當你使用【殺】或黑色普通錦囊牌指定唯一目標時，你可令另一名角色選擇一項：1.交給你一張牌，然後代替你成為此牌的使用者；2.也成為此牌的目標（然後此技能本回合失效）。",
["zenhui_po-invoke"] = "你可以發動“譖毀”<br/> <b>操作提示</b>: 選擇除 %src 外的一名角色→點擊確定<br/>",
["@zenhui_po-collat​​eral"] = "請選擇【借刀殺人】 %src 使用【殺】的目標",
["@zenhui_po-give"] = "請交給 %src 一張牌成為此牌的使用者，否則你成為此牌的目標",
["jiaojin_po"] = "驕矜",
[":jiaojin_po"] = "當你成為男性角色使用【殺】或普通錦囊牌的目標後，你可以棄置一張裝備牌，然後此牌對你無效並獲得此牌。",
["@jiaojin_po"] = "你可以棄置一張裝備牌發動“驕矜”令此牌對你無效並獲得此牌",
}

--界孫皓
sunhao_po = sgs.General(extension, "sunhao_po$", "wu2", "5", true)

canshi_po = sgs.CreateTriggerSkill{
	name = "canshi_po",	
	events = {sgs.DrawNCards,sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.DrawNCards then
			if room:askForSkillInvoke(player,self:objectName(), data) then
				--room:notifySkillInvoked(player, "canshi_po")
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(player,"canshi_po_invoke-Clear",1)
				local n = data:toInt()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isWounded() then
						n = n + 1
					end
				end
				data:setValue(n)
			end
		else
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
			if invoke and card then
				if (card:isKindOf("Slash") or card:isNDTrick()) and player:getMark("canshi_po_invoke-Clear") > 0 then
					room:askForDiscard(player, "canshi_po", 1, 1, false, true)
				end
			end
		end
	end,
}

chouhai_po = sgs.CreateTriggerSkill{
	name = "chouhai_po",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card:isKindOf("Slash") and player:isKongcheng() then	
			room:notifySkillInvoked(player, "chouhai_po")
			room:broadcastSkillInvoke("chouhai_po")
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#chouhai_po2"
				msg.from = player
				msg.to:append(player)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)
		end
		return false
	end
}
sunhao_po:addSkill(canshi_po)
sunhao_po:addSkill(chouhai_po)
sunhao_po:addSkill("guiming")

sgs.LoadTranslationTable{
	["#sunhao_po"] = "時日曷喪",
	["sunhao_po"] = "界孫皓", --SE神受我一拜，不過這吸毒一樣的人一看就不是萌萌噠的SE！
	["&sunhao_po"] = "孫皓", 
	["illustrator:sunhao_po"] = "Liuheng",
	["canshi_po"] = "殘蝕",
	[":canshi_po"] = "摸牌階段，你可以多摸X張牌。本回合你使用【殺】或普通錦囊牌時，棄置一張牌。 （X為已受傷角色數）",
	["@canshi-discard"] = "請棄置一張牌",
	["chouhai_po"] = "仇海",
	[":chouhai_po"] = "鎖定技，當你受到【殺】造成的傷害時，若你沒有手牌，此傷害+1。",
	["guiming"] = "歸命",
	[":guiming"] = "主公技。鎖定技。其他吳勢力角色於你的回合內視為已受傷的角色。",
	["#chouhai_po2"] = "%from 的技能 “<font color=\"yellow\"><b>仇海</b></font>” 被觸發，受到傷害由 %arg 點增加到 %arg2 點",
}

--界馬謖
masu_po = sgs.General(extension, "masu_po", "shu2", "3", true)
--散謠
sanyao_poCard = sgs.CreateSkillCard{
	name = "sanyao_po",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local n = 0
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if p:objectName() ~= sgs.Self:objectName() then
				n = math.max(n, p:getHp())
			end
		end
		--local m = 0
		--if not sgs.Sanguosha:getCard(self:getSubcards():first()):isEquipped() then m = m + 1 end
		--n = math.max(n, sgs.Self:getHandcardNum() - m)
		return to_select:getHp() == n and to_select:objectName() ~= sgs.Self:objectName() and #targets < self:subcardsLength() 
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _,p in pairs(targets) do
				room:damage(sgs.DamageStruct(self:objectName(), source, p))
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
sanyao_po = sgs.CreateViewAsSkill{
	name = "sanyao_po",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local c = sanyao_poCard:clone()
		for _,card in ipairs(cards) do
			c:addSubcard(card)
		end
		return c
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sanyao_po")
	end,
}

zhiman_po = sgs.CreateTriggerSkill{
	name = "zhiman_po",
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
			if string.find(lord:getGeneralName(), "guansuo") or string.find(lord:getGeneral2Name(), "guansuo") then
				room:broadcastSkillInvoke(self:objectName(),3)
			else
				room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
			end
			if player:getMark(self:objectName().."engine") > 0 then
				if player:canDiscard(damage.to, "hej") then
					local card = room:askForCardChosen(player, damage.to, "hej", self:objectName())
					room:obtainCard(player, card, false)
				end
				room:removePlayerMark(player, self:objectName().."engine")
				return true
			end
		end
		return false
	end
}

masu_po:addSkill(sanyao_po)
masu_po:addSkill(zhiman_po)

sgs.LoadTranslationTable{
["#masu_po"] = "恃才傲物",
["masu_po"] = "界馬謖",
["&masu_po"] = "馬謖",
["illustrator:new_masu_po"] = "張帥",
["sanyao_po"] = "散謠",
[":sanyao_po"] = "階段技。你可以棄置任意張牌，選擇體力值最多的等量名其他角色，依次對其各造成1點傷害。",
["zhiman_po"] = "制蠻",
[":zhiman_po"] = "當你對其他角色造成傷害時，你可以防止此傷害，你獲得其區域裡一張牌。",
}

--OL孫魯育
forth_rev_sunluyu = sgs.General(extension,"forth_rev_sunluyu","wu2","3",false)
--穆穆：出牌階段開始時，你可以選擇一項：1.棄置一名其他角色裝備區裡的一張牌；2.獲得一名角色裝備區裡的一張防具牌，若如此做，你本回合不能使用或打出【殺】。
mumu_forth_revCard = sgs.CreateSkillCard{
	name = "mumu_forth_rev",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:getEquips():isEmpty() and sgs.Self:canDiscard(to_select, "e")
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local id = room:askForCardChosen(effect.from, effect.to, "e", self:objectName(), false, sgs.Card_MethodDiscard)
			--if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
				local choice = room:askForChoice(effect.from, self:objectName(), "discard+obtain")
				if choice == "obtain" then
					room:addPlayerMark(effect.from, "mumu_forth_rev_obtain-Clear")
					room:obtainCard(effect.from, id)
				else
					room:addPlayerMark(effect.from, "mumu_forth_rev_discard-Clear")
					room:throwCard(sgs.Sanguosha:getCard(id), effect.to, effect.from)
				end
			--else
				--room:throwCard(sgs.Sanguosha:getCard(id), effect.to, effect.from)
			--end
		end
	end
}
mumu_forth_revVS = sgs.CreateZeroCardViewAsSkill{
	name = "mumu_forth_rev",
	view_as = function()
		return mumu_forth_revCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@mumu_forth_rev"
	end
}
mumu_forth_rev = sgs.CreateTriggerSkill{
	name = "mumu_forth_rev",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = mumu_forth_revVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local invoke = false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:getEquips():isEmpty() then
				invoke = true
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and invoke and player:hasSkill(self:objectName()) then
			if room:askForUseCard(player, "@mumu_forth_rev", "@mumu_forth_rev") then
			end
		end
	end
}

mumu_forth_revtm = sgs.CreateTargetModSkill{
	name = "#mumu_forth_revtm",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:getMark("mumu_forth_rev_obtain-Clear") > 0 then
			return -1
		elseif player:getMark("mumu_forth_rev_discard-Clear") > 0 then
			return 1
		end
	end,
}

--魅步：其他角色的出牌階段開始時，你可以棄置一張牌，令該角色於本回合內擁有“止息”。若你以此法棄置的牌不是【殺】或黑色錦囊牌，則本回合其與你距離視為1。
meibu_forth_rev = sgs.CreateTriggerSkill{
	name = "meibu_forth_rev",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:inMyAttackRange(p) then
					local card = room:askForCard(p, ".,Equip", "@meibu_forth_rev:"..player:objectName(), sgs.QVariant(), sgs.CardDiscarded)
					if card then
						room:addPlayerMark(player,"meibu_forth_rev" .. card:getSuitString() .. "-Clear")
						room:addPlayerMark(p,"meibu_forth_rev" .. card:getSuitString() .. "-Clear")
						room:notifySkillInvoked(player, self:objectName())
						room:handleAcquireDetachSkills(player, "zhixi_forth_rev", false)
						room:broadcastSkillInvoke("meibu_forth_rev")
					end
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:hasSkill("zhixi_forth_rev") then
				room:detachSkillFromPlayer(player, "zhixi_forth_rev")
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

--止息
zhixi_forth_rev = sgs.CreateTriggerSkill{
	name = "zhixi_forth_rev",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed or event == sgs.PreCardResponded then
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
			if card then
				if card:isKindOf("Slash") or card:isNDTrick() then
					local dcard = room:askForExchange(player, self:objectName(), 1, 1, false, "@zhixi_forth_rev")
					if dcard then
						if player:getMark("meibu_forth_rev" .. dcard:getSuitString() .. "-Clear") > 0 then
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if p:getMark("meibu_forth_rev" .. dcard:getSuitString() .. "-Clear") > 0 then
									p:obtainCard(dcard)
								end
							end
						else
							room:throwCard(dcard, player,player)
						end
					end
				end
			end
		end
	end,
}


forth_rev_sunluyu:addSkill(mumu_forth_rev)
forth_rev_sunluyu:addSkill(mumu_forth_revtm)
forth_rev_sunluyu:addSkill(meibu_forth_rev)

if not sgs.Sanguosha:getSkill("zhixi_forth_rev") then skills:append(zhixi_forth_rev) end

sgs.LoadTranslationTable{
	["forth_rev_sunluyu"] = "十週年孫魯育",
	["&forth_rev_sunluyu"] = "孫魯育",
	["mumu_forth_rev"] = "穆穆",
	[":mumu_forth_rev"] = "出牌階段開始時，妳可以選擇一項：1.棄置一名其他角色裝備區裡的一張牌，然後妳本回合使用【殺】的次數上限+1；2.獲得一名角色裝備區裡的一張裝備牌，然後妳本回合使用【殺】的次數上限-1。",
	["mumu_forth_rev1"] = "棄置一名其他角色裝備區裡的一張牌，然後妳本回合使用【殺】的次數上限+1",
	["mumu_forth_rev2"] = "獲得一名角色裝備區裡的一張防具牌，然後妳本回合使用【殺】的次數上限-1。",
	["@mumu_forth_rev"] = "你可以發動“穆穆”",
	["~mumu_forth_rev"] = "選擇一名有裝備牌的角色→點擊確定",
	["meibu_forth_rev"] = "魅步",
	[":meibu_forth_rev"] = "其他角色的出牌階段開始時，若妳在其攻擊範圍內，妳可以棄置一張牌，令該角色於本回合內擁有“止息”，若其本回合棄置的牌與妳棄置的牌花色相同，妳獲得之。",
	["zhixi_forth_rev"] = "止息",
	[":zhixi_forth_rev"] = "鎖定技，當你於出牌階段內使用【殺】或普通錦囊牌時，妳棄置一張手牌。",
	["@meibu_forth_rev"] = "妳可以棄置一張牌，令 %src 於本回合內擁有“止息”",
}

--張嶷
zhangyi_po = sgs.General(extension,"zhangyi_po","shu2","5",true)

furong_poCard = sgs.CreateSkillCard{
	name = "furong_po",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local card_target = room:askForCard(targets[1], ".|.|.|hand!", "@furong-show", sgs.QVariant(), sgs.Card_MethodNone)
			if card_target then
				room:showCard(source, self:getSubcards():first())
				room:showCard(targets[1], card_target:getEffectiveId())
				room:getThread():delay()
				local card_source = sgs.Sanguosha:getCard(self:getSubcards():first())
				if card_source:isKindOf("Slash") then
					if not card_target:isKindOf("Jink") then
						room:damage(sgs.DamageStruct("furong_po", source, targets[1], 1))
					end
				else
					if card_target:isKindOf("Jink") then
						if player:canDiscard(targets[1], "he") then
							local id = room:askForCardChosen(source, targets[1], "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:obtainCard(source,id, true)
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
furong_po = sgs.CreateOneCardViewAsSkill{
	name = "furong_po",
	filter_pattern = ".",
	view_as = function(self, card)
		local skillcard = furong_poCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#furong_po")
	end
}


shizhi_po = sgs.CreateFilterSkill{
	name = "shizhi_po",
	--[[
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return to_select:isKindOf("Jink") and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName("shizhi_po")
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(slash)
		return new
	end
	]]--
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		return room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand and to_select:isKindOf("Jink")
	end,
	view_as = function(self, originalCard)
		local room = sgs.Sanguosha:currentRoom()
		local id = originalCard:getEffectiveId()
		local player = room:getCardOwner(id)
		if player:getHp() == 1 and player:hasSkill("shizhi_po") then
			local peach = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			peach:setSkillName("shizhi_po")
			local card = sgs.Sanguosha:getWrappedCard(id)
			card:takeOver(peach)
			return card
		else
			return originalCard
		end
	end
}

shizhi_potrigger = sgs.CreateTriggerSkill{
	name = "#shizhi_potrigger",
	events = {sgs.GameStart,sgs.HpChanged,sgs.EventAcquireSkill, sgs.EventLoseSkill,sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.HpChanged or event == sgs.GameStart then
			room:filterCards(player, player:getCards("h"), true)
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "shizhi_po" then
				room:recover(player, sgs.RecoverStruct(player))
			end
		end
		return false
	end
}


zhangyi_po:addSkill(furong_po)
zhangyi_po:addSkill(shizhi_po)
zhangyi_po:addSkill(shizhi_potrigger)

sgs.LoadTranslationTable{
	["#zhangyi_po"] = "通壯逾古",
	["zhangyi_po"] = "界張嶷",
	["&zhangyi_po"] = "張嶷",
	["furong_po"] = "憮戎",
	[":furong_po"] = "出牌階段限一次，你可以令一名其他角色與你同時展示一張手牌：若你展示的是【殺】且該角色展示的不是【閃】，則你"
	.."對其造成1點傷害；若你展示的不是【殺】且該角色展示的是【閃】，則你獲得其一張牌。",
	["@furong-show"] = "<font color=\"yellow\">撫戎</font> 請展示一張手牌" ,
	["shizhi_po"] = "矢志",
	["shizhi_po2"] = "矢志",
	["#shizhi_po"] = "矢志",
	["#shizhi_povs"] = "矢志",
	[":shizhi_po"] = "鎖定技。當你體力為1時，你的【閃】均視為【殺】，且當你使用此「殺」造成傷害後，你回復一點體力。",
}

--高順
gaoshun_po = sgs.General(extension,"gaoshun_po","qun2","4",true)

xianzhen_poCard = sgs.CreateSkillCard{
	name = "xianzhen_po", 
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng();
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom();
		if effect.from:pindian(effect.to, "xianzhen_po",nil) then
 
			room:addPlayerMark(effect.from, "kill_caocao-Clear")
			room:addPlayerMark(effect.to, "be_killed-Clear")

			local assignee_list = effect.from:property("extra_slash_specific_assignee"):toString():split("+")
			if not table.contains(assignee_list, effect.to:objectName()) then
				room:setPlayerMark(effect.to, "be_killed_unlimited-Clear",1)
				table.insert(assignee_list, effect.to:objectName())
			end
			room:setPlayerProperty(effect.from, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
			
			room:setFixedDistance(effect.from, effect.to, 1);

			if effect.to:getMark("Armor_Nullified") == 0 then
				room:setPlayerMark(effect.to, "Armor_Nullified-Clear",1)
				room:addPlayerMark(effect.to, "Armor_Nullified")
			end
	

		else
			room:setPlayerCardLimitation(effect.from, "use", "Slash", true);
			room:addPlayerMark(effect.from, "xianzhen_po_failed-Clear");
		end
	end,
}

xianzhen_poVs = sgs.CreateZeroCardViewAsSkill{
	name = "xianzhen_po",
	view_as = function(self) 
		return xianzhen_poCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#xianzhen_po")) and (not player:isKongcheng())
	end, 
}

xianzhen_po = sgs.CreateTriggerSkill{
	name = "xianzhen_po",  
	events = {sgs.PreCardUsed}, 
	view_as_skill = xianzhen_poVs,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if (room:alivePlayerCount() > 2) and (use.card:isKindOf("Slash") or use.card:isNDTrick()) and
			  not use.card:isKindOf("Nullification") and
			  not use.card:isKindOf("Collateral") and use.to:length() == 1 then
				local invoke = false
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("xianzhen_po_target-Clear") > 0 and not use.to:contains(p) then
						invoke = true
					end
				end
				if invoke then	
					if room:askForSkillInvoke(player, self:objectName(), data) then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark("xianzhen_po_target-Clear") > 0 then
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
							end
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseChanging and player:getMark("xianzhen_po_failed-Clear") > 0 and RIGHT(self, player) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				room:setPlayerCardLimitation(player, "discard", "Slash", true)
			end
		elseif event == sgs.EventPhaseEnd and player:getMark("xianzhen_po_failed-Clear") > 0  and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Discard then
				room:removePlayerCardLimitation(player, "discard", "Slash")
			end
		end
	end,
}

xianzhen_pomc = sgs.CreateMaxCardsSkill{
	name = "#xianzhen_pomc",
	extra_func = function(self, target)
		if target:getMark("xianzhen_po_failed-Clear") > 0 then
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

gaoshun_po:addSkill(xianzhen_po)
gaoshun_po:addSkill(xianzhen_pomc)
gaoshun_po:addSkill("jinjiu")

sgs.LoadTranslationTable{
["#gaoshun_po"] = "攻無不克",
["gaoshun_po"] = "界高順",
["&gaoshun_po"] = "高順",
["designer:gaoshun_po"] = "羽柴文理",
["illustrator:gaoshun_po"] = "鄧Sir",
["xianzhen_po"] = "陷陣",
[":xianzhen_po"] = "階段技。你可以與一名其他角色拼點：若你贏，本回合，該角色的防具無效，對其使用牌無距離及次數限制，且你使用"..
"【殺】或普通錦囊牌指定唯一目標後，你可以令其也成為目標；若你沒贏，你本回合不能使用【殺】且【殺】不計入手牌上限。",
["jinjiu"] = "禁酒",
[":jinjiu"] = "鎖定技。你的【酒】視為【殺】。",
}

--界簡雍
jianyong_po = sgs.General(extension,"jianyong_po","shu2","3",true)

qiaoshui_poUseCard = sgs.CreateSkillCard{
	name = "qiaoshui_poUse" ,
	filter = function(self, targets, to_select)
		if #targets >= sgs.Self:getMark("qiaoshui_po_success") then return false end
		if to_select:hasFlag("notZangshiTarget") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			p:setFlags("zangshiTarget")
		end
	end
}

qiaoshui_poCard = sgs.CreateSkillCard{
	name = "qiaoshui_po" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "qiaoshui_po", nil)
		if (success) then
			room:addPlayerMark(source, "qiaoshui_po_success")
		else
			room:addPlayerMark(source, "qiaoshui_po_fail-Clear")
			room:setPlayerFlag(source, "Global_PlayPhaseTerminated")
		end
	end
}

qiaoshui_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "qiaoshui_po" ,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@qiaoshui_po")
	end ,
	view_as = function()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@qiaoshui_po" then
			return qiaoshui_poUseCard:clone()
		else
			return qiaoshui_poCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end, 
}

qiaoshui_po = sgs.CreateTriggerSkill{
	name = "qiaoshui_po" ,
	view_as_skill = qiaoshui_poVS ,
	events = {sgs.PreCardUsed,sgs.EventPhaseChanging,sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and
			 not use.card:isKindOf("Jink") and not use.card:isKindOf("Nullification") and
			  not use.card:isKindOf("Collateral") and player:getMark("qiaoshui_po_success") > 0 then

					room:setPlayerFlag(player, "qiaoshui_potm")
					room:setTag("qiaoshui_poData", data)	
					if room:askForUseCard(player, "@@qiaoshui_po", "@qiaoshui_po-use:::"..use.card:objectName(), -1, sgs.Card_MethodDiscard) then
						room:removeTag("qiaoshui_poData")
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
					room:setPlayerFlag(player, "-qiaoshui_potm")
					room:setPlayerMark(player,"qiaoshui_po_success",0)
			end
		elseif event == sgs.EventPhaseChanging and player:getMark("qiaoshui_po_fail-Clear") > 0  then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
						room:setPlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString(), false)
						room:setPlayerMark(player, self:objectName()..id.."-Clear",1)
					end
				end
				--room:setPlayerCardLimitation(player, "discard", "Trick", true)
			end
		elseif event == sgs.EventPhaseEnd and player:getMark("qiaoshui_po_fail-Clear") > 0 then
			if player:getPhase() == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					--if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
						if player:getMark(self:objectName()..id.."-Clear") > 0 then
						room:removePlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString().."$0")
					end
				end
				--room:removePlayerCardLimitation(player, "discard", "Trick")
			end
		end
	end,
}
qiaoshui_poTargetMod = sgs.CreateTargetModSkill{
	name = "#qiaoshui_po-target" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("qiaoshui_potm")) then
			return 1000
		end
		return 0
	end
}

qiaoshui_pomc = sgs.CreateMaxCardsSkill{
	name = "#qiaoshui_pomc",
	extra_func = function(self, target)
		if target:getMark("qiaoshui_po_fail-Clear") > 0 then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:isKindOf("TrickCard") then
					x = x + 1
				end
			end
			return x
		end
	end
}

jianyong_po:addSkill(qiaoshui_po)
jianyong_po:addSkill(qiaoshui_pomc)
jianyong_po:addSkill(qiaoshui_poTargetMod)
jianyong_po:addSkill("zongshih")

sgs.LoadTranslationTable{
["#jianyong_po"] = "優游風議",
["jianyong_po"] = "界簡雍",
["&jianyong_po"] = "簡雍",
["designer:jianyong_po"] = "Nocihoo",
["illustrator:jianyong_po"] = "紫喬",
["qiaoshui_po"] = "巧說",
["qiaoshui_poUse"] = "巧說",
["qiaoshui_pouse"] = "巧說",
[":qiaoshui_po"] = "出牌階段，你可以與一名其他角色拼點：若你贏，本回合你使用的下一張基本牌或非延時錦囊牌可以增加一個額外目標（無距離限制）或減少一名目標（若原有至少兩名目標）；若你沒贏，你結束出牌階段且本回合錦囊牌不計入手排上限。",
["qiaoshui_po:add"] = "增加一名目標",
["qiaoshui_po:remove"] = "減少一名目標",

["@qiaoshui_po-use"] = "請選擇【%arg】的額外目標，或是減少的目標",

["~qiaoshui_po"] = "選擇目標角色→點擊確定",

["zongshih"] = "縱適",
[":zongshih"] = "每當你拼點贏，你可以獲得對方的拼點牌。每當你拼點沒贏，你可以獲得你的拼點牌。",
["#QiaoshuiAdd"] = "%from 發動了“%arg”為 %card 增加了額外目標 %to",
["#QiaoshuiRemove"] = "%from 發動了“%arg”為 %card 減少了目標 %to",
}


--界董卓
ol_dongzhuo = sgs.General(extension, "ol_dongzhuo$", "qun2", 8, true)

ol_jiuchiVS = sgs.CreateViewAsSkill{
	name = "ol_jiuchi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Spade)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
			analeptic:setSkillName(self:objectName())
			analeptic:addSubcard(cards[1])
			return analeptic
		end
	end,
	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
		return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player , newanal)
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}

ol_jiuchi = sgs.CreateTriggerSkill{
	name = "ol_jiuchi" ,
	events = {sgs.EventPhaseStart,sgs.Damage} ,
	view_as_skill = ol_jiuchiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:hasFlag("drank")) then
				room:setPlayerMark(player,"Qingchengbenghuai",1)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				room:removePlayerMark(player,"Qingchengbenghuai")
			end
		end
		return false
	end,
	priority = -2
}

ol_jiuchiTM = sgs.CreateTargetModSkill{
	name = "#ol_jiuchiTM",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Analeptic",
	residue_func = function(self, player)
		if player:hasSkill("ol_jiuchi") then
			return 1000
		else
			return 0
		end
	end,
}

--暴虐
ol_baonue = sgs.CreateTriggerSkill{
	name = "ol_baonue$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.PreDamageDone},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.PreDamageDone and damage.from then
			damage.from:setTag("InvokeBaonue", sgs.QVariant(damage.from:getKingdom() == "qun" or damage.from:getKingdom() == "qun2"))
		elseif event == sgs.Damage and player:getTag("InvokeBaonue"):toBool() and player:isAlive() then
			local dongzhuos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					dongzhuos:append(p)
				end
			end
			while (not dongzhuos:isEmpty()) do
				local dongzhuo = room:askForPlayerChosen(player, dongzhuos, self:objectName(), "@baonue-to", true)
				if dongzhuo then
					dongzhuos:removeOne(dongzhuo)
					local log = sgs.LogMessage()
					log.type = "#InvokeOthersSkill"
					log.from = player
					log.to:append(dongzhuo)
					log.arg = self:objectName()
					room:sendLog(log)
					room:notifySkillInvoked(dongzhuo, self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						room:broadcastSkillInvoke(self:objectName())
						dongzhuo:obtainCard(judge.card)
						room:recover(dongzhuo, sgs.RecoverStruct(player))
					end
				else
					break
				end
			end
		end
		return false
	end,
}

ol_dongzhuo:addSkill(ol_jiuchi)
ol_dongzhuo:addSkill(ol_jiuchiTM)
ol_dongzhuo:addSkill("roulin")
ol_dongzhuo:addSkill("benghuai")
ol_dongzhuo:addSkill(ol_baonue)

sgs.LoadTranslationTable{
	["#ol_dongzhuo"] = "魔王",
	["ol_dongzhuo"] = "界董卓",
	["&ol_dongzhuo"] = "董卓",
	["ol_jiuchi"] = "酒池",
	[":ol_jiuchi"] = "你可以將一張黑桃手牌當【酒】使用；你使用【酒】無次數限制。當你使用【酒】【殺】造成傷害後，你的技能「崩壞」於本回合失效。",
	["benghuai"] = "崩壞",
	[":benghuai"] = "鎖定技。結束階段開始時，若你的體力值不為場上最少（或之一），你須選擇一項：失去1點體力，或失去1點體力上限。 ",
	["ol_baonue"] = "暴虐",
	[":ol_baonue"] = "主公技。其他群雄角色造成傷害後，該角色可以進行判定：若結果為黑桃，你回復1點體力並獲得此判定牌。",
}

--[[
界孫堅 吳勢力 體力4
英魂 準備階段，若你已受傷，你可以選擇一名其他角色並選擇一項：1.令其摸X張牌，然後棄置一張牌；2.令其摸一張牌，然後棄置X張牌。 （X為你已損失的體力值）
武烈 限定技，結束階段，你可以失去任意點體力，令等同於失去體力值數量的其他角色獲得"烈"標記；擁有"烈"標記的玩家受到一次傷害時，棄置此標記並防止該傷害。
]]--
ol_sunjian = sgs.General(extension,"ol_sunjian","wu2","5",true)

wulieCard = sgs.CreateSkillCard{
	name = "wulie",
	filter = function(self, targets, to_select, erzhang)
		return #targets < sgs.Self:getHp()
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@wulie")
		room:doSuperLightbox("ol_sunjian","wulie")
		for _,p in pairs(targets) do
			p:gainMark("@lie")
		end
		room:loseHp(source, #targets)
	end
}
wulieVS = sgs.CreateZeroCardViewAsSkill{
	name = "wulie",
	response_pattern = "@@wulie",
	view_as = function()
		return wulieCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end
}

wulie = sgs.CreateTriggerSkill{
	name = "wulie",
	view_as_skill = wulieVS,
	frequency = sgs.Skill_Limited,	
	limit_mark = "@wulie",
	events = {sgs.EventPhaseStart ,sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:getMark("@wulie") > 0 and RIGHT(self, player) then
				room:askForUseCard(player, "@@wulie", "@wulie-card")
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:getMark("@lie") > 0 then	
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local logtext
				if damage.nature == sgs.DamageStruct_Fire then
					logtext = "normal_nature" 
				elseif damage.nature == sgs.DamageStruct_Thunder then
					logtext = "thunder_nature"
				else
					logtext = "thunder_nature"
				end			
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = "wulie"
				msg.arg2 = logtext
				room:sendLog(msg)
				player:loseMark("@lie",1)
				return true
			end
			--return false
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}


ol_sunjian:addSkill("yinghun")
ol_sunjian:addSkill(wulie)


sgs.LoadTranslationTable{
["ol_sunjian"] = "界孫堅",
["&ol_sunjian"] = "孫堅",
["#ol_sunjian"] = "武烈帝",
["wulie"] = "武烈",
[":wulie"] = "限定技，結束階段，你可以失去任意點體力，令等同於失去體力值數量的其他角色獲得「烈」標記；擁有「烈」標記的玩家受到一次傷害時，棄置此標記並防止該傷害。",
	["~wulie"] = "選擇任意名角色 -> 點擊確定",
	["@lie"] = "烈",
	["@wulie-card"] = "你可以失去任意點體力，令等同於失去體力值數量的其他角色獲得「烈」標記",
}

--[[
孫休
]]--
ol_sunxiu = sgs.General(extension, "ol_sunxiu$", "wu2", 3, true)

ol_yanzhuCard = sgs.CreateSkillCard{
	name = "ol_yanzhu",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isNude()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "ol_yanzhuengine")
		if source:getMark("ol_yanzhuengine") > 0 then
			if source:getMark("ol_yanzhu_change") > 0 then
				room:setPlayerMark(targets[1],"@ol_yanzhu_PD",1)
			else
				if targets[1]:getEquips():length() > 0 then 
					if room:askForDiscard(targets[1], self:objectName(), 1, 1, true, true, "@ol_yanzhu-discard") then
						room:setPlayerMark(targets[1],"@ol_yanzhu_PD",1)
					else
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, equip in sgs.qlist(targets[1]:getEquips()) do
							 dummy:addSubcard(equip:getEffectiveId())
						end
						room:obtainCard(source, dummy)
						room:setPlayerMark(source,"ol_yanzhu_change",1)
						sgs.Sanguosha:addTranslationEntry(":ol_yanzhu", ""..string.gsub(sgs.Sanguosha:translate(":ol_yanzhu"), sgs.Sanguosha:translate(":ol_yanzhu"), sgs.Sanguosha:translate(":ol_yanzhu1")))
						sgs.Sanguosha:addTranslationEntry(":ol_xingxue", ""..string.gsub(sgs.Sanguosha:translate(":ol_xingxue"), sgs.Sanguosha:translate(":ol_xingxue"), sgs.Sanguosha:translate(":ol_xingxue1")))
					end
				else
				 	room:askForDiscard(targets[1], self:objectName(), 1, 1,false, true, "@ol_yanzhu-discard")
				 	room:setPlayerMark(targets[1],"@ol_yanzhu_PD",1)
				end
			end
			room:removePlayerMark(source, "ol_yanzhuengine")
		end
	end
}
ol_yanzhu = sgs.CreateZeroCardViewAsSkill{
	name = "ol_yanzhu",
	view_as = function()
		return ol_yanzhuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#ol_yanzhu")
	end
}

ol_yanzhu_trigger = sgs.CreateTriggerSkill{
	name = "ol_yanzhu_trigger",   
	global = true,
	events = {sgs.DamageInflicted,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()	
			if player:getMark("@ol_yanzhu_PD") > 0 then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#OlYanzho"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)
			end
			return false
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart then
				room:setPlayerMark(player,"@ol_yanzhu_PD",0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
}

if not sgs.Sanguosha:getSkill("ol_yanzhu_trigger") then skills:append(ol_yanzhu_trigger) end

ol_xingxueCard = sgs.CreateSkillCard{
	name = "ol_xingxue",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getHp()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
			effect.to:drawCards(1, self:objectName())

			if effect.to:getHandcardNum() > effect.to:getHp() then
				local card = room:askForExchange(effect.to, self:objectName(), 1, 1, true, "@ol_xingxue-put", true)
				local move = sgs.CardsMoveStruct(card:getSubcards(), effect.to, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, effect.to:objectName(), self:objectName(), ""))
				room:moveCardsAtomic(move, false)
			end
			room:removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
ol_xingxueVS = sgs.CreateZeroCardViewAsSkill{
	name = "ol_xingxue",
	response_pattern = "@@ol_xingxue",
	view_as = function()
		return ol_xingxueCard:clone()
	end
}
ol_xingxue = sgs.CreatePhaseChangeSkill{
	name = "ol_xingxue",
	view_as_skill = ol_xingxueVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			room:askForUseCard(player, "@@ol_xingxue", "@ol_xingxue")
		end
		return false
	end
}

ol_sunxiu:addSkill(ol_yanzhu)
ol_sunxiu:addSkill(ol_xingxue)
ol_sunxiu:addSkill("zhaofu")

sgs.LoadTranslationTable{
["#ol_sunxiu"] = "彌殤的景君",
["&ol_sunxiu"] = "孫休",
["ol_sunxiu"] = "界孫休",
["ol_yanzhu"] = "宴誅",
[":ol_yanzhu"] = "出牌階段限一次，你可以令一名其他角色選擇一項：1.令你獲得其裝備區裡的所有牌，你修改「宴誅」和「興學」；2.棄置一張牌且下一次受到的傷害+1直到其下個回合開始。",
[":ol_yanzhu1"] = "出牌階段限一次，你可以令一名其他角色下一次受到的傷害+1直到其下個回合開始。",
["@ol_yanzhu-discard"] = "請棄置一張牌，否則其將獲得你的所有裝備並失去“宴誅”。\n提示：如果你沒有裝備，則你必須棄置一張牌" ,
["ol_xingxue"] = "興學",
[":ol_xingxue"] = "結束階段，你可以令至多X名角色（X為你的體力值）依次摸一張牌，然後其中手牌數大於體力值的角色依次將一張牌置於牌堆頂。",
[":ol_xingxue1"] = "結束階段，你可以令至多X名角色（X為你的體力上限）依次摸一張牌，然後其中手牌數大於體力值的角色依次將一張牌置於牌堆頂。",
["@ol_xingxue-put"] = "請將一張牌置於牌堆頂" ,
["@ol_xingxue"] = "你可以發動“興學”。",
["~ol_xingxue"] = "選擇角色→點擊確定" ,
["zhaofu"] = "詔縛",
[":zhaofu"] = "主公技。鎖定技。你距離為1的角色視為在其他吳勢力角色的攻擊範圍內。",
["#OlYanzho"] = "%from 受到 “<font color=\"yellow\"><b>宴誅</b></font>”的影響，%to 對 %from 造成的傷害由 %arg 點增加到 %arg2 點",
}

--界曹休
caoxiu_po = sgs.General(extension, "caoxiu_po", "wei2", 4, true)

function GetColor(card)
	if card:isRed() then return "red" elseif card:isBlack() then return "black" end
end

--[[
qingxi_po = sgs.CreateTriggerSkill{
	name = "qingxi_po", 
	events = {sgs.TargetSpecified,sgs.DamageCaused,sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			local x = 0
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:inMyAttackRange(p) then
					x = x + 1
				end
			end
			if player:getWeapon() and x >= 4 then
				x = 4
			elseif (not player:getWeapon()) and x >= 2 then
				x = 2
			end

			if x > 0 and use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if player:askForSkillInvoke(self:objectName(), _data) then
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							if room:askForDiscard(p, self:objectName(), x, x, true, true) then
								room:broadcastSkillInvoke(self:objectName(), 1)
								if player:getWeapon() then
									room:throwCard(player:getWeapon(), player, p)
								end
							else
								room:broadcastSkillInvoke(self:objectName(), 2)
								if GetColor(use.card) == "red" or GetColor(use.card) == "black" then
									room:setPlayerMark(p, "@qianxi_"..GetColor(use.card), 1)
									room:setPlayerMark(p, "qingxi_po"..GetColor(use.card), 1)
									room:setPlayerCardLimitation(p, "use,response", ".|"..GetColor(use.card), true)
								end
								room:setCardFlag(use.card,"qingxi_po_card")
								room:setPlayerFlag(p,"qingxi_po_target")
							end
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
			return false
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("qingxi_po_card") and damage.to:hasFlag("qingxi_po_target") then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#Qingxi_po"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:hasFlag("qingxi_po_card") then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("qingxi_po_red") > 0 then
						room:setPlayerMark(p,"qingxi_po_red",0)
						room:setPlayerMark(p,"@qianxi_red",0)
					elseif p:getMark("qingxi_po_black") > 0 then
						room:setPlayerMark(p,"qingxi_po_black",0)
						room:setPlayerMark(p,"@qianxi_black",0)
					end
				end
			end
		end
	end
}
]]--

qingxi_po = sgs.CreateTriggerSkill{
	name = "qingxi_po", 
	events = {sgs.TargetSpecified,sgs.DamageCaused,sgs.TrickCardCanceling,sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified and RIGHT(self, player) then
			local use = data:toCardUse()
			local x = 0
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:inMyAttackRange(p) then
					x = x + 1
				end
			end
			if player:getWeapon() and x >= 4 then
				x = 4
			elseif (not player:getWeapon()) and x >= 2 then
				x = 2
			end

			if x > 0 and use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if player:askForSkillInvoke(self:objectName(), _data) then
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							if room:askForDiscard(p, self:objectName(), x, x, true, true) then
								room:broadcastSkillInvoke(self:objectName(), 1)
								if player:getWeapon() then
									room:throwCard(player:getWeapon(), player, p)
								end
							else
								room:broadcastSkillInvoke(self:objectName(), 2)

								local judge = sgs.JudgeStruct()
								judge.pattern = ".|red"
								judge.good = true
								judge.negative = false
								judge.play_animation = false
								judge.reason = self:objectName()
								judge.who = player
								room:judge(judge)
								if judge:isGood() then 
									room:setPlayerMark(p, "qingxi_po_can_not_res", 1)
								end
								room:setCardFlag(use.card,"qingxi_po_card")
								room:setPlayerFlag(p,"qingxi_po_target")
							end
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end

				if use.card:isKindOf("Slash") and use.card:hasFlag("qingxi_po_card") then
					local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
					local index = 1
					for _, p in sgs.qlist(use.to) do
						local _data = sgs.QVariant()
						_data:setValue(p)
						if p:getMark("qingxi_po_can_not_res") > 0 then
							jink_table[index] = 0
						end
						index = index + 1
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					player:setTag("Jink_"..use.card:toString(), jink_data)
				end
			end

			return false
		elseif event == sgs.DamageCaused and RIGHT(self, player) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("qingxi_po_card") and damage.to:hasFlag("qingxi_po_target") then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#Qingxi_po"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and RIGHT(self, effect.from) and effect.card:hasFlag("qingxi_po_card") and player:getMark("qingxi_po_can_not_res") > 0 then return true end
		elseif event == sgs.CardFinished and RIGHT(self, player) then
			local use = data:toCardUse()
			if use.card and use.card:hasFlag("qingxi_po_card") then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"qingxi_po_can_not_res",0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

caoxiu_po:addSkill("qianju")
caoxiu_po:addSkill(qingxi_po)

sgs.LoadTranslationTable{
["caoxiu_po"] = "界曹休",
["&caoxiu_po"] = "曹休",
["#caoxiu_po"] = "諸神的黃昏",
["illustrator:caoxiu_po"] = "諸神黃昏",
["qingxi_po"] = "傾襲",
--[":qingxi_po"] = "當你使用【殺】或【決鬥】指定目標後，你可令其選擇一項：1.棄置等同你攻擊範圍內的人數張手牌（最多為二，若你武器區有武器牌，則改為最多為四），然後棄置你的此武器牌；2.令此牌對其傷害值+1且不能用與此牌顏色相同的牌響應。",
[":qingxi_po"] = "當你使用【殺】或【決鬥】指定目標後，你可令其選擇一項：1.棄置等同你攻擊範圍內的人數張手牌（最多為二，若你武器區有武器牌，則改為最多為四），然後棄置你的此武器牌；2.令此牌對其傷害值+1且你判定，若為紅色，其不可響應此牌。",
["$qingxi_po1"] = "你本領再高，也鬥不過我的~",
["$qingxi_po2"] = "傾兵所有，襲敵不意！",
["~caoxiu_po"] = "孤軍深入，犯了兵家大忌！",
	["#Qingxi_po"] = "%from 的技能 “<font color=\"yellow\"><b>傾襲</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--凌統
lingtong_po = sgs.General(extension, "lingtong_po", "wu2", "4", true)

xuanfeng_po = sgs.CreateTriggerSkill{
	name = "xuanfeng_po" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not move.from) or (move.from:objectName() ~= player:objectName()) then return false end
			if (move.to_place == sgs.Player_DiscardPile) and (player:getPhase() == sgs.Player_Discard)
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				room:setPlayerMark(player,"xuanfeng_po-Clear", player:getMark("xuanfeng_po-Clear") + move.card_ids:length())
			end
			if ((player:getMark("xuanfeng_po-Clear") >= 2) and (not player:hasFlag("xuanfeng_poUsed"))) or move.from_places:contains(sgs.Player_PlaceEquip) then
				local damage_targets = sgs.SPlayerList()

				for i = 1,2,1 do
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canDiscard(p, "he") then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						local target = room:askForPlayerChosen(player, targets, self:objectName(), "xuanfeng_po-invoke", true, true)
						if target then
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								room:doAnimate(1, player:objectName(), target:objectName())
								room:notifySkillInvoked(player, self:objectName())
								room:broadcastSkillInvoke(self:objectName())
								local id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								room:throwCard(id, target, player)
								room:removePlayerMark(player, self:objectName().."engine")
								damage_targets:append(target)
							end
						end
					end
				end
				if (not damage_targets:isEmpty()) and player:getPhase() ~= sgs.Player_NotActive then
					room:setPlayerFlag(player,"xuanfeng_po_flag")
					local target = room:askForPlayerChosen(player, damage_targets, self:objectName(), "xuanfeng_po_damage-invoke", true, true)
					if target then
						room:notifySkillInvoked(player, self:objectName())
						room:damage(sgs.DamageStruct(self:objectName(), player, target))
					end
					room:setPlayerFlag(player,"-xuanfeng_po_flag")
				end
			end
		end
		return false
	end
}

lingtong_po:addSkill(xuanfeng_po)
lingtong_po:addSkill("yongjin")

sgs.LoadTranslationTable{
["#lingtong_po"] = "豪情烈膽",
["lingtong_po"] = "界凌統",
["&lingtong_po"] = "凌統",
["illustrator:lingtong_po"] = "綿Myan",
["xuanfeng_po"] = "旋風",
[":xuanfeng_po"] = "當你於棄牌階段棄置過至少兩張牌，或當你失去裝備區裡的牌後，你可以棄置至多兩名其他角色的共計兩張牌。若此時是你的回合內，你可以對其中一個目標造成1點傷害。",
["xuanfeng_po-invoke"] = "你可以發動“旋風”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["xuanfeng_po_damage-invoke"] = "你可以對其中一個目標造成1點傷害",
}

--左慈
zuoci_po = sgs.General(extension,"zuoci_po","qun2","3",true)

huashen_po = sgs.CreateTriggerSkill{
	name = "huashen_po",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:notifySkillInvoked(player, "huashen")
			if player:isMale() then
				room:broadcastSkillInvoke("huashen",math.random(1,2))
			else
				room:broadcastSkillInvoke("huashen",math.random(3,4))
			end
			AcquireGenerals(player, 3)
			room:getThread():delay()
			SelectSkill(player)
		else
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart or phase == sgs.Player_NotActive then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:notifySkillInvoked(player, self:objectName())
					if player:isMale() then
						room:broadcastSkillInvoke("huashen",math.random(1,2))
					else
						room:broadcastSkillInvoke("huashen",math.random(3,4))
					end
					SelectSkill(player)
				end
			end
		end
	end
}
huashen_poDetach = sgs.CreateTriggerSkill{
	name = "huashen_poDetach",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill},
	priority = -1,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local skill_name = data:toString()
		if skill_name == "huashen_po" then
			if player:getKingdom() ~= player:getGeneral():getKingdom() and player:getGeneral():getKingdom() ~= "god" then
				room:setPlayerProperty(player, "kingdom", sgs.QVariant(player:getGeneral():getKingdom()))
			end
			if player:getGender() ~= player:getGeneral():getGender() then
				player:setGender(player:getGeneral():getGender())
			end
			local huashen_skill = player:getTag("Huashenskill"):toString()
			if  huashen_skill ~= "" then
				room:detachSkillFromPlayer(player, huashen_skill, false, true)
			end
			player:removeTag("Huashens")
			room:setPlayerMark(player, "@huashen", 0)
		end
	end,
}

xinsheng_po = sgs.CreateTriggerSkill{
	name = "xinsheng_po",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:notifySkillInvoked(player, self:objectName())
			if player:isMale() then
				room:broadcastSkillInvoke("xinsheng",math.random(1,2))
			else
				room:broadcastSkillInvoke("xinsheng",math.random(3,4))
			end
			AcquireGenerals(player, data:toDamage().damage) --需调用ChapterH 的acquieGenerals 函数
		end
	end
}

zuoci_po:addSkill(huashen_po)
zuoci_po:addSkill(xinsheng_po)

if not sgs.Sanguosha:getSkill("huashen_poDetach") then skills:append(huashen_poDetach) end

sgs.LoadTranslationTable{
["#zuoci_po"] = "謎之仙人",
["&zuoci_po"] = "左慈",
["zuoci_po"] = "界左慈",
["illustrator:zuoci_po"] = "紫喬",
["huashen_po"] = "化身",
[":huashen_po"] ="遊戲開始前，你獲得三張未加入遊戲的武將牌，稱為“化身牌”，然後選擇一張“化身牌”的一項技能（除主公技、限定技與覺醒技）。回合開始時和回合結束後，你可以更換“化身牌”或獲得一張新的“化身牌”，然後你可以為當前“化身牌”重新選擇一項技能。你擁有你以此法選擇的技能且性別與勢力改為與“化身牌”相同。",
["xinsheng_po"] = "新生",
[":xinsheng_po"] = "每當你受到1點傷害後，你可以獲得一張“化身牌”。",
["#GetHuashen"] = "%from 獲得了 %arg 張“化身牌”，現在共有 %arg2 張“化身牌”",
["#GetHuashenDetail"] = "%from 獲得了“化身牌” %arg",
["remove_huashen"] = "移除化身",
}

--[[
界公孫瓚  體力4
趫猛 當你使用的黑色【殺】對一名角色造成傷害後，你可棄置其區域里的一張牌。若此牌為坐騎牌，你獲得之。
義從 鎖定技，若你的體力值大於2，你計算與其他角色的距離-1；若你的體力值不大於2，其他角色計算與你的距離+1。
]]--
gongsunzan_po = sgs.General(extension,"gongsunzan_po","qun2","4",true)


yicong_buff = sgs.CreateDistanceSkill{
	name = "#yicong_buff",
	frequency = sgs.Skill_Compulsory,
	correct_func = function(self, from, to)
		if from:hasSkill("yicong") and from:getHp() <= 2 then
			return - 1
		else
			return 0
		end
	end
}

function SendComLog(self, player, n, invoke)
	if invoke == nil then invoke = true end
	if invoke then
		player:getRoom():sendCompulsoryTriggerLog(player, self:objectName())
		player:getRoom():broadcastSkillInvoke(self:objectName(), n)
	end
end

qiaomeng_po = sgs.CreateTriggerSkill{
	name = "qiaomeng_po",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if not damage.to:isAllNude() and damage.to:objectName() ~= player:objectName() and player:getPhase() == sgs.Player_Play and player:getMark("zhidao_Play") == 0 then
			SendComLog(self, player)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				if not damage.to:isAllNude() then
					if room:askForSkillInvoke(player, self:objectName()) then
						room:broadcastSkillInvoke(self:objectName())
						local id = room:askForCardChosen(player, damage.to, "hej", self:objectName())
						local card = sgs.Sanguosha:getCard(id)
						room:throwCard(card, damage.to, player)
						if card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse") then
							room:obtainCard(player, card, false)
						end
					end
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
gongsunzan_po:addSkill("yicong")
gongsunzan_po:addSkill(yicong_buff)
gongsunzan_po:addSkill(qiaomeng_po)

sgs.LoadTranslationTable{
["#gongsunzan_po"] = "白馬將軍",
["gongsunzan_po"] = "界公孫瓚",
["&gongsunzan_po"] = "公孫瓚",
["illustrator:gongsunzan"] = "Vincent",
["qiaomeng_po"] = "趫猛",
[":qiaomeng_po"] = "每當你使用【殺】對一名角色造成傷害後，你可以棄置該角色區域的一張牌：若此牌為坐騎牌，此牌置入棄牌堆時你獲得之。",
}

--新OL馬謖
new_masu = sgs.General(extension, "new_masu", "shu2", "3", true)
--散謠
ol_sanyaoCard = sgs.CreateSkillCard{
	name = "ol_sanyao",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local n = 0
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			n = math.max(n, p:getHp())
		end
		local m = 0
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			m = math.max(m, p:getHandcardNum())
		end
		return #targets == 0 and
		((sgs.Self:getMark("ol_sanyao_card_Play") == 0 and to_select:getHandcardNum() == m) or 
				(sgs.Self:getMark("ol_sanyao_hp_Play") == 0 and to_select:getHp() == n))
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				n = math.max(n, p:getHp())
			end
			local m = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				m = math.max(m, p:getHandcardNum())
			end
			if targets[1]:getHp() == n and targets[1]:getHandcardNum() == m then
				room:addPlayerMark(source,"ol_sanyao_both_Play")
			elseif targets[1]:getHp() == n then
				room:addPlayerMark(source,"ol_sanyao_bp_Play")
			elseif targets[1]:getHandcardNum() == m then
				room:addPlayerMark(source,"ol_sanyao_card_Play")
			end

			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
ol_sanyao = sgs.CreateViewAsSkill{
	name = "ol_sanyao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		local c = ol_sanyaoCard:clone()
		for _,card in ipairs(cards) do
			c:addSubcard(card)
		end
		return c
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("ol_sanyao_both_Play") + player:getMark("ol_sanyao_bp_Play") + player:getMark("ol_sanyao_card_Play")) < 2
	end,
}

new_masu:addSkill(ol_sanyao)
new_masu:addSkill(zhiman_po)

sgs.LoadTranslationTable{
["#new_masu"] = "恃才傲物",
["new_masu"] = "新OL馬謖",
["&new_masu"] = "馬謖",
["illustrator:ol_new_masu"] = "張帥",
["ol_sanyao"] = "散謠",
[":ol_sanyao"] = "出牌階段各限一次，你可以棄置一張牌，然後對體力值最大/手牌數最多的一名角色造成1點傷害。",
["zhiman_po"] = "制蠻",
[":zhiman_po"] = "當你對其他角色造成傷害時，你可以防止此傷害，你獲得其區域裡一張牌。",
}


--界潘璋＆馬忠
panzhangmazhong_po = sgs.General(extension, "panzhangmazhong_po", "wu2", "4", true)

duodao_po = sgs.CreateTriggerSkill{
	name = "duodao_po" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if not use.card or not use.card:isKindOf("Slash") or not player:canDiscard(player, "he") then
			return
		end
		local _data = sgs.QVariant()
		_data:setValue(use)
		local room = player:getRoom()
		if use.from and use.from:getWeapon() and use.to:contains(player) then
			if room:askForCard(player, "..", "@duodao_po-get", _data, self:objectName()) then
				player:obtainCard(use.from:getWeapon())
			end
		end
	end
}

anjian_po = sgs.CreateTriggerSkill{
	name = "anjian_po",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.DamageCaused,sgs.DamageComplete,sgs.EnterDying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				if not p:inMyAttackRange(player) and RIGHT(self, player) then
					p:addQinggangTag(use.card)
				end
			end
		elseif event == sgs.DamageCaused then 
			local damage = data:toDamage()
			if damage.chain or damage.transfer or not damage.by_user then return false end
			if damage.from and not damage.to:inMyAttackRange(damage.from)
				and damage.card and damage.card:isKindOf("Slash") and RIGHT(self, player) then
				room:notifySkillInvoked(damage.from, self:objectName())

				room:setCardFlag(damage.card, "anjian_po_buff")
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
		elseif event == sgs.EnterDying then
			local damage = dying.damage
			if damage.card:isKindOf("Slash") and damage.card:hasFlag("anjian_po_buff") then
				room:setPlayerMark(damage.to,"can_not_use_peach-Clear",1)
			end
		elseif event == sgs.DamageComplete and RIGHT(self, player) then
			local damage = data:toDamage()
			room:setPlayerMark(damage.to,"can_not_use_peach-Clear",0)
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

anjian_poProhibit = sgs.CreateProhibitSkill{
	name = "#anjian_po",
	is_prohibited = function(self, from, to, card)
		return from:getMark("can_not_use_peach-Clear") > 0 and to:getMark("can_not_use_peach-Clear") > 0 and card:isKindOf("Peach")
	end
}

panzhangmazhong_po:addSkill(duodao_po)
panzhangmazhong_po:addSkill(anjian_po)
panzhangmazhong_po:addSkill(anjian_poProhibit)

sgs.LoadTranslationTable{
["#panzhangmazhong_po"] = "擒龍伏虎",
["panzhangmazhong_po"] = "界潘璋＆馬忠",
["&panzhangmazhong_po"] = "潘璋馬忠",
["designer:panzhangmazhong_po"] = "風殘葉落",
["illustrator:panzhangmazhong_po"] = "zzyzzyy",
["duodao_po"] = "奪刀",
[":duodao_po"] = "每當你成為其他角色【殺】的目標後，你可以棄置一張牌：然後獲得其裝備區的武器牌。",
["@duodao_po-get"] = "你可以棄置一張牌發動“奪刀”",
["anjian_po"] = "暗箭",
[":anjian_po"] = "鎖定技，當你使用【殺】指定目標後，若你不在其攻擊範圍內，則此殺無視防具且對其傷害+1，若該角色因此進入瀕死狀態，其不能使用「桃」直到結算結束。",
["#AnjianBuff"] = "%from 的“<font color=\"yellow\"><b>暗箭</b></font>”效果被觸發，傷害從 %arg 點增加至 %arg2 點" ,
}


--界法正
fazheng_po = sgs.General(extension,"fazheng_po","shu2","3",true)
--恩怨
enyuan_po = sgs.CreateTriggerSkill{
	name = "enyuan_po" ,
	events = {sgs.CardsMoveOneTime, sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and (move.to:objectName() == player:objectName()) and move.from and move.from:isAlive()
					and (move.from:objectName() ~= move.to:objectName())
					and (move.card_ids:length() >= 2)
					and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
				local _movefrom
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if move.from:objectName() == p:objectName() then
						_movefrom = p
						break
					end
				end   --我去MoveOneTime的from居然是player不是splayer，还得枚举所有splayer获取下……
				_movefrom:setFlags("enyuan_poDrawTarget")
				local invoke = room:askForSkillInvoke(player, self:objectName(), data)
				_movefrom:setFlags("-enyuan_poDrawTarget")
				if invoke then
					room:notifySkillInvoked(player, self:objectName())
					room:doAnimate(1, player:objectName(), _movefrom:objectName())
					room:broadcastSkillInvoke("enyuan_po",1)
					room:drawCards(_movefrom, 1)
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local source = damage.from
			if (not source) or (source:objectName() == player:objectName()) then return false end
			local x = damage.damage
			for i = 0, x - 1, 1 do
				if source:isAlive() and player:isAlive() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:notifySkillInvoked(player, self:objectName())
						room:doAnimate(1, player:objectName(), source:objectName())
						room:broadcastSkillInvoke("enyuan_po",2)
						local card
						if not source:isKongcheng() then
							card = room:askForExchange(source, self:objectName(), 1,1, false, "Enyuan_poGive:"..player:objectName(), true)
						end
						if card then
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
															  player:objectName(), self:objectName(), nil)
							--reason.m_playerId = player:objectName()
							room:moveCardTo(card, source, player, sgs.Player_PlaceHand, reason)
							if card:getSuit() ~= sgs.Card_Heart then
								player:drawCards(1)
							end
						else
							room:loseHp(source)
						end
					else
						break
					end
				else
					break
				end
			end
		end
		return false
	end
}

--眩惑
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

xuanhuo_poCard = sgs.CreateSkillCard{
	name = "xuanhuo_po",
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local choicelist = {"cancel"}
		local victim = room:askForPlayerChosen(source, room:getOtherPlayers(targets[1]), self:objectName(), "@dummy-slash2:" .. targets[1]:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "xuanhuo_po", "")
		room:obtainCard(targets[1], self, reason, false)

		room:setPlayerMark(source,"xuanhuo_po_fazheng-Clear",1)
		room:setPlayerMark(victim,"xuanhuo_po_victim-Clear",1)

		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choicelist, card:objectName())) then
				if card:isAvailable(targets[1]) and card:isKindOf("Slash") and targets[1]:getMark("AG_BANCard"..card:objectName()) == 0 then
					if targets[1]:canSlash(victim, nil, false) and not targets[1]:isProhibited(victim, card) then
						table.insert(choicelist, card:objectName())
					end
				end
			end
		end

		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("_"..self:objectName())
		if not targets[1]:isProhibited(victim, duel) then
			table.insert(choicelist, "duel")
		end

		local choice = room:askForChoice(targets[1], self:objectName(), table.concat(choicelist, "+"))
		if choice ~= "not_use" then
			local slash = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
			slash:setSkillName("_xuanhuo_po")
			room:useCard(sgs.CardUseStruct(slash, targets[1], victim), false)
		else
			room:obtainCard(source, targets[1]:wholeHandCards(), false)
		end
	end
}
xuanhuo_poVS = sgs.CreateViewAsSkill{
	name = "xuanhuo_po",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected < 2 then
			return true
		end
	end,
	view_as = function(self, cards)
		local skill = xuanhuo_poCard:clone()
		if #cards == 2 then
			for _, c in ipairs(cards) do
				skill:addSubcard(c)
			end
			return skill
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xuanhuo_po"
	end
}

xuanhuo_po = sgs.CreateTriggerSkill{
	name = "xuanhuo_po",
	events = {sgs.EventPhaseEnd},
	view_as_skill = xuanhuo_poVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw then
			room:askForUseCard(player, "@@xuanhuo_po", "@xuanhuo_po", -1, sgs.Card_MethodUse)
			--return false
		end
	end,
}

fazheng_po:addSkill(enyuan_po)
fazheng_po:addSkill(xuanhuo_po)

sgs.LoadTranslationTable{
["#fazheng_po"] = "蜀漢的輔翼",
["fazheng_po"] = "界法正", 
["&fazheng_po"] = "法正", 
["illustrator:fazheng_po"] = "紫喬",
["enyuan_po"] = "恩怨",
[":enyuan_po"] = "當你獲得一名其他角色至少兩張牌後，你可以令其摸一張牌；當你受到1點傷害後，除非傷害來源交給你一張手牌，否則其失去1點體力。若其交給你的牌不是紅桃，你摸一張牌",
["Enyuan_poGive"] = "請交給 %dest 1 張手牌，否則失去一點體力",
["xuanhuo_po"] = "眩惑",
[":xuanhuo_po"] = "摸牌階段結束時，你可以交給一名其他角色兩張手牌，然後該角色選擇一項：1.視為對你選擇的另一名其他角色使用任意一種【殺】或決鬥；2.或交給你所有手牌。",
["@xuanhuo_po"] = "你可以發動“眩惑”",
["~xuanhuo_po"] = "操作提示</b>: 選擇一名其他角色→點擊確定<br/>",
["xuanhuo_po_slash"] = "眩惑",
["_xuanhuo_po"] = "眩惑",
}
--界伏皇后
fuhuanghou_po = sgs.General(extension,"fuhuanghou_po","qun2","3",false)

--惴恐	其他角色的回合開始時，若你已受傷，你可與其拼點：若你贏，本回合該角色只能對自己使用牌；若你沒贏，你獲得其拼點的牌，然後其視為對你使用一張【殺】。
zhuikong_po = sgs.CreateTriggerSkill{
	name = "zhuikong_po",
	events = {sgs.EventPhaseStart,sgs.Pindian},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and not player:isKongcheng() then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill("zhuikong_po") and p:isWounded() and not p:isKongcheng() and room:askForSkillInvoke(p, self:objectName(),data) then
						room:doAnimate(1, p:objectName(), player:objectName())
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						if p:pindian(player, self:objectName(), nil) then
							local msg = sgs.LogMessage()
							msg.type = "#ComZishou"
							msg.from = player
							msg.arg = "zhuikong_po"
							room:sendLog(msg)

							room:setPlayerMark(player,"beizhan_ban-Clear",1)
						end
					end
				end
			end
			return false
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == "zhuikong_po" and RIGHT(self, player) and pindian.from:objectName() == player:objectName() then
				if pindian.from_number <= pindian.to_number then
						if (room:getCardPlace(pindian.to_card:getEffectiveId()) == sgs.Player_PlaceTable) then
							player:obtainCard(pindian.to_card)
						end

						if BeMan(room, pindian.to):canSlash(player, nil, false) then
							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							slash:setSkillName("zhuikong_po")
							room:useCard(sgs.CardUseStruct(slash, BeMan(room, pindian.to) , player))
						end
				end
			end
		end
	end	
}

--求援	當你成為【殺】的目標時，你可選擇另一名其他角色。除非該角色交給你一張除【殺】以外的基本牌，否則其也成為此【殺】的目標且該角色不能響應此【殺】。
qiuyuan_po = sgs.CreateTriggerSkill{
	name = "qiuyuan_po" ,
	events = {sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local room = player:getRoom()
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (not p:isKongcheng()) and (p:objectName() ~= use.from:objectName()) then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "qiuyuan_po-invoke", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local card = nil
				if target:getHandcardNum() > 1 then
					card = room:askForCard(target, "BasicCard^Slash|.|.|hand", "@qiuyuan_po-give:" .. player:objectName(), data, sgs.Card_MethodNone)
					if card then
						player:obtainCard(card)
					else
						if not target:isProhibited(use.from, use.card) then
							room:setPlayerMark(target,"qiuyuan_po_debuff-Clear",1)
							use.to:append(target)
							room:sortByActionOrder(use.to)
							data:setValue(use)

							local guicai = sgs.Sanguosha:getTriggerSkill("qiuyuan_po_debuff")
							guicai:trigger(event, room, use.from, data)

							room:getThread():trigger(sgs.TargetConfirming, room, target, data)
						end
					end
				end
			end
		end
		return false
	end
}

qiuyuan_po_debuff = sgs.CreateTriggerSkill{
	name = "qiuyuan_po_debuff" ,
	events = {sgs.TargetSpecified} ,
	global = true, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if p:getMark("qiuyuan_po_debuff-Clear") > 0 then
						room:setPlayerMark(p,"qiuyuan_po_debuff-Clear",0)
						local msg = sgs.LogMessage()
						msg.type = "#Qiuyuan_po_debuff"
						msg.from = p
						msg.arg = self:objectName()
						msg.arg2 = use.card:objectName()
						room:sendLog(msg)	
						jink_table[index] = 0
					--end
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		end
	end
}

if not sgs.Sanguosha:getSkill("qiuyuan_po_debuff") then skills:append(qiuyuan_po_debuff) end

fuhuanghou_po:addSkill(zhuikong_po)
fuhuanghou_po:addSkill(qiuyuan_po)

sgs.LoadTranslationTable{
["#fuhuanghou_po"] = "孤注一擲",
["fuhuanghou_po"] = "界伏皇后",
["&fuhuanghou_po"] = "伏皇后",
["illustrator:fuhuanghou_po"] = "小莘",
["zhuikong_po"] = "惴恐",
[":zhuikong_po"] = "其他角色的回合開始時，若你已受傷，你可與其拼點：若你贏，本回合該角色只能對自己使用牌；若你沒贏，你獲得其拼點的牌，然後其視為對你使用一張【殺】。",
["#zhuikong_po"] = "惴恐",
["qiuyuan_po"] = "求援",
[":qiuyuan_po"] = "當你成為【殺】的目標時，你可選擇另一名其他角色。除非該角色交給你一張除【殺】以外的基本牌，否則其也成為此【殺】的目標且該角色不能響應此【殺】。",
["qiuyuan_po-invoke"] = "你可以發動“求援”<br/> <b>操作提示</b>: 選擇除此【殺】使用者外的一名其他角色→點擊確定<br/> ",
["@qiuyuan_po-give"] = "請交給 %src 一張【殺】以外的基本牌",
["qiuyuan_po_debuff"] = "求援",
["#Qiuyuan_po_debuff"] = "%from 受到 “<font color=\"yellow\"><b> %arg </b></font>”影響，無法響應此 %arg2 ",
}

--界鄧艾
dengai_po = sgs.General(extension,"dengai_po","wei2","4",true)

tuntian_po = sgs.CreateTriggerSkill{
	name = "tuntian_po",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.FinishJudge, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_NotActive then
				if (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
					if not player:askForSkillInvoke("tuntian_po", data) then return end
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.good = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
				end
			else
				if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					local is_slash = false
					for _,id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id) and sgs.Sanguosha:getCard(id):isKindOf("Slash") then
							is_slash = true
						end
					end
					if is_slash then
						if not player:askForSkillInvoke("tuntian_po", data) then return end
						room:broadcastSkillInvoke(self:objectName())
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|heart"
						judge.good = false
						judge.reason = self:objectName()
						judge.who = player
						room:judge(judge)
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() and judge:isGood() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				player:addToPile("field", judge.card:getEffectiveId())
			end
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				player:removePileByName("field")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
	end
}

tuntian_poDistance = sgs.CreateDistanceSkill{
	name = "#tuntian_poDistance",
	correct_func = function(self, from, to)
		if from:hasSkill("tuntian_po") then
			return - from:getPile("field"):length()
		else
			return 0
		end
	end  
}

zaoxian_po = sgs.CreateTriggerSkill{
	name = "zaoxian_po" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseStart} ,
	priority = 1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("zaoxian_po") == 0 then
				if player:getPile("field"):length() >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
					room:addPlayerMark(player, "zaoxian_po")
					if room:changeMaxHpForAwakenSkill(player) then
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke("zaoxian_po")
						if player:getPile("field"):length() >= 3 then
							local msg = sgs.LogMessage()
							msg.type = "#Zaoxian_poWake"
							msg.from = player
							msg.to:append(player)
							msg.arg = player:getPile("field"):length()
							msg.arg2 = self:objectName()
							room:sendLog(msg)
						end
						room:doSuperLightbox("dengai_po","zaoxian_po")
						room:addPlayerMark(player, "zaoxian_po_wake")
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

tuntian_poGive = sgs.CreateTriggerSkill{
	name = "tuntian_poGive" ,
	events = {sgs.EventPhaseStart} ,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if player:getMark("zaoxian_po_wake") > 0 and player:getPhase() == sgs.Player_NotActive then
			room:setPlayerMark(player,"zaoxian_po_wake",0)
			room:setTag("ExtraTurn",sgs.QVariant(true))
			local msg = sgs.LogMessage()
			msg.type = "#Zaoxian_poExtra"
			msg.from = player
			msg.to:append(player)
			room:sendLog(msg)
			player:gainAnExtraTurn()
			room:setTag("ExtraTurn",sgs.QVariant(false))
		end
		return false
	end ,
	priority = 1
}
if not sgs.Sanguosha:getSkill("tuntian_poGive") then skills:append(tuntian_poGive) end

dengai_po:addSkill(zaoxian_po)
dengai_po:addSkill(tuntian_po)
dengai_po:addSkill(tuntian_poDistance)


sgs.LoadTranslationTable{
["#dengai_po"] = "矯然的壯士",
["dengai_po"] = "界鄧艾",
["&dengai_po"] = "鄧艾",
["tuntian_po"] = "屯田",
[":tuntian_po"] = "每當你於回合外失去牌後；或於回合內棄置【殺】後，你可以判定，若該牌不為紅桃，你將此判定牌置於武將牌上稱為“田”。你與其他角色的距離-X。（X為“田”的數量）",
["#tuntian_po-dist"] = "屯田",
["field"] = "田",
["zaoxian_po"] = "鑿險",
[":zaoxian_po"] = "覺醒技。準備階段開始時，若你的“田”大於或等於三張，你失去1點體力上限，然後獲得“急襲”（你可以將一張“田”當【順手牽羊】使用），且你於當前回合結束時獲得一個額外的回合。",
["$ZaoxianAnimate"] = "image=image/animate/zaoxian.png",
["jixi_po"] = "急襲",
[":jixi_po"] = "你可以將一張“屯田”牌當【順手牽羊】使用。",
["@jixi_po-target"] = "請選擇【順手牽羊】的目標角色",
["~jixi_po"] = "選擇【順手牽羊】的目標角色→點擊確定",
["#Zaoxian_poWake"] = "%from 的“田”為 %arg 張，觸發“%arg2”覺醒",
["#Zaoxian_poExtra"] = "%to 將進行一個額外的回合",
}

--界劉表
liubiao_po = sgs.General(extension,"liubiao_po","qun2","3",true)

zishou_poCard = sgs.CreateSkillCard{
	name = "zishou_po",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			room:drawCards(source, self:subcardsLength(), "zishou_po")
		end
	end
}
zishou_poVS = sgs.CreateViewAsSkill{
	name = "zishou_po",
	n = 4,
	view_filter = function(self, selected, to_select)
		for _,c in sgs.list(selected) do
			if c:getSuit() == to_select:getSuit() then return false end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zishou_po_card = zishou_poCard:clone()
		for _,card in pairs(cards) do
			zishou_po_card:addSubcard(card)
		end
		zishou_po_card:setSkillName(self:objectName())
		return zishou_po_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@@zishou_po"
	end
}

zishou_po = sgs.CreateTriggerSkill{
	name = "zishou_po" ,
	view_as_skill = zishou_poVS,
	events = {sgs.DrawNCards,sgs.DamageCaused,sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			local n = data:toInt()
			if room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(player,"zishou_po-Clear",1)
				local kingdoms = getKingdomsFuli(player)
				data:setValue(n + kingdoms)
			end
		elseif event == sgs.DamageCaused then
			if player:getMark("zishou_po-Clear") > 0 then

				local msg = sgs.LogMessage()
				msg.type = "#ZishoupoProtect"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = damage.damage
				if damage.nature == sgs.DamageStruct_Fire then
					msg.arg2 = "fire_nature"
				elseif damage.nature == sgs.DamageStruct_Thunder then
					msg.arg2 = "thunder_nature"
				elseif damage.nature == sgs.DamageStruct_Normal then
					msg.arg2 = "normal_nature"
				end
				room:sendLog(msg)

				return true
			end
			return false
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if not player:isSkipped(change.to) and change.to == sgs.Player_Finish and player:getMark("qieting") == 0 then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:askForUseCard(player, "@@zishou_po", "@zishou_po", -1, sgs.Card_MethodDiscard)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
			return false
		end
	end
}

zongshi_poban = sgs.CreateProhibitSkill{
	name = "#zongshi_poban",
	is_prohibited = function(self, from, to, card)
		return to:getHandcardNum() > to:getHp() and to:getPhase() == sgs.Player_NotActive and to:hasSkill("zongshi_po") and not card:isKindOf("SkillCard") and (card:isKindOf("DelayedTrick") or card:getSuit() == sgs.Card_NoSuit )
	end
}
	

zongshi_po = sgs.CreateMaxCardsSkill{
	name = "zongshi_po" ,
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
		if target:hasSkill(self:objectName()) then
			return extra
		else
			return 0
		end
	end
}

liubiao_po:addSkill(zishou_po)
liubiao_po:addSkill(zongshi_po)
liubiao_po:addSkill(zongshi_poban)

sgs.LoadTranslationTable{
	["liubiao_po"] = "界劉表",	
	["&liubiao_po"] = "劉表",		
	["zishou_po"] = "自守",
	[":zishou_po"] = "摸牌階段，你可以多摸X張牌,然後本回合你對其他角色造成傷害時，防止此傷害。結束階段，若你本回合沒有使用牌指定其他角色為目標，你可以棄置任意張花色不同的手牌，然後摸等量的牌。",
	["@zishou_po"] = "你可以棄置任意張花色不同的手牌，然後摸等量的牌",
	["#ZishoupoProtect"] = "%from 的「<font color=\"yellow\"><b>自守</b></font>」效果被觸發，防止了對 %to 造成的 %arg 點傷害[%arg2]",
	["zongshi_po"] = "宗室",	
	[":zongshi_po"] = "鎖定技，你的手牌上限+X（X為現存勢力數）。你的回合外，若你的手牌數大於等於手牌上限，則當你成為延時類錦囊牌或無顏色的牌的目標後，你令此牌對你無效。",
}

--界公孫淵
gongsunyuan_po = sgs.General(extension,"gongsunyuan_po","qun2","4",true)

huaiyi_poSnatchCard = sgs.CreateSkillCard{
	name = "huaiyi_poSnatch",
	filter = function(self, targets, to_select)
		return not to_select:isNude() and #targets < sgs.Self:getMark("huaiyi_num")
	end,
	on_use = function(self, room, source, targets)
		for _,p in pairs(targets) do		
			local id = room:askForCardChosen(source, p, "he", self:objectName(), false)
			room:obtainCard(source, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName()), false)
		end
		if #targets >= 2 then
			room:loseHp(source)
		end
	end
}

huaiyi_poCard = sgs.CreateSkillCard{
	name = "huaiyi_po",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:showAllCards(source)
			local cards = source:getHandcards()
			local color = cards:first():isRed()
			local same_color = true
			for _, card in sgs.qlist(cards) do
				if card:isRed() ~= color then
					same_color = false
					break
				end
			end
			if same_color then
				source:drawCards(1)
				room:addPlayerMark(source, "huaiyi_po_Play")
				sgs.Sanguosha:addTranslationEntry(":huaiyi_po", ""..string.gsub(sgs.Sanguosha:translate(":huaiyi_po"), sgs.Sanguosha:translate(":huaiyi_po"), sgs.Sanguosha:translate(":huaiyi_po1")))
				ChangeCheck(source, "gongsunyuan_po")
			else
				local choice = room:askForChoice(source, self:objectName(), "red+black")
				ChoiceLog(source, choice)

				local ids = sgs.IntList()
				for _, card in sgs.qlist(source:getHandcards()) do
					if choice == "red" then
						if card:isRed() then
							ids:append(card:getEffectiveId())
						end
					end 
					if choice == "black" then
						if card:isBlack() then
							ids:append(card:getEffectiveId())
						end
					end  
				end
				if ids:length() > 0 then
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = nil
					move.to_place = sgs.Player_DiscardPile
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, source:objectName(), nil, "huaiyi_po", nil)
					room:moveCardsAtomic(move, true)
					room:setPlayerMark(source,"huaiyi_num",ids:length())
					room:askForUseCard(source, "@@huaiyi_po!", "@huaiyi_po:"..ids:length() )
					room:setPlayerMark(source,"huaiyi_num",0)
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
huaiyi_po = sgs.CreateZeroCardViewAsSkill{
	name = "huaiyi_po",
	response_or_use = true,
	view_as = function()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return huaiyi_poCard:clone()
		else
			return huaiyi_poSnatchCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("huaiyi_po_Play") > 0 then
			return player:usedTimes("#huaiyi_po") < 2 and not player:isKongcheng()
		end
		return not player:hasUsed("#huaiyi_po") and not player:isKongcheng()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@huaiyi_po")
	end
}

gongsunyuan_po:addSkill(huaiyi_po)

sgs.LoadTranslationTable{
["#gongsunyuan_po"] = "狡徒懸海",
["&gongsunyuan_po"] = "公孫淵",
["gongsunyuan_po"] = "界公孫淵",
["huaiyi_po"] = "懷異", -- 懷孕！ ！
["huaiyi_posnatch"] = "懷異",
["huaiyi_poSnatch"] = "懷異",
[":huaiyi_po"] = "出牌階段限一次，你可以展示所有手牌，若只有一種顏色，你摸一張牌，然後此技能本階段改為「限兩次」；若有兩種顏色，你棄置其中一種顏色的牌，然後獲得至多X名其他角色的各一張牌（X為你以此法棄置的手牌數），若以此法獲得的牌大於一張，則你失去1點體力。",
["@huaiyi_po"] = "你可以選擇至多 %src 名角色，獲得他們的各一張牌。",
["~huaiyi_po"] = "選擇角色→點擊確定",
}

--界曹真
caozhen_po = sgs.General(extension,"caozhen_po","wei2","4",true)

sidi_poCard = sgs.CreateSkillCard{
	name = "sidi_po",
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local current = room:getCurrent()
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:setPlayerMark(current, "@qianxi_"..GetColor(card), 1)
			room:setPlayerMark(current, "sidi_po_"..GetColor(card), 1)
			room:setPlayerCardLimitation(current, "use, response", ".|"..GetColor(card), true)
			current:setFlags(self:objectName())
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end,
}
sidi_poVS = sgs.CreateOneCardViewAsSkill{
	name = "sidi_po", 
	response_pattern = "@@sidi_po",
	filter_pattern = ".|.|.|sidi_po",
	expand_pile = "sidi_po",
	view_as = function(self, card)
		local kf = sidi_poCard:clone()
		kf:addSubcard(card)
		return kf
	end,
}


sidi_po = sgs.CreateTriggerSkill{
	name = "sidi_po",
	global = true,
	view_as_skill = sidi_poVS,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill("sidi_po") then
			local can_invoke = false
			for _,id in sgs.qlist(player:handCards()) do
				if not sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local card = room:askForCard(player, "^BasicCard", "@sidi_po", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					player:addToPile("sidi_po", card)
				end
			end
		end
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and p:objectName() ~= player:objectName() and p:getPile("sidi_po"):length() > 0 then
				room:askForUseCard(p, "@@sidi_po", "@sidi_po-card:"..player:objectName() , -1, sgs.Card_MethodNone)
			end
			if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
				if player:hasFlag(self:objectName()) then
					if player:getMark("used_slash-Clear") == 0 and p:canSlash(player, nil, false) then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("_sidi_po")
						room:useCard(sgs.CardUseStruct(slash, p, player))
					end
					if player:getMark("used_trick-Clear") == 0 then
						p:drawCards(2)
					end
					if player:getMark("sidi_po_red") > 0 then
						room:setPlayerMark(player,"sidi_po_red",0)
						room:setPlayerMark(player,"@qianxi_red",0)
					elseif player:getMark("sidi_po_black") > 0 then
						room:setPlayerMark(player,"sidi_po_black",0)
						room:setPlayerMark(player,"@qianxi_black",0)
					end
				end
			end
		end
		return false
	end
}

caozhen_po:addSkill(sidi_po)

sgs.LoadTranslationTable{
	["caozhen_po"] = "界曹真",
	["&caozhen_po"] = "曹真",
	["sidi_po"] = "司敵",
	["_sidi_po"] = "司敵",
	[":sidi_po"] = "結束階段，你可以將一張非基本牌置於武將牌上，稱為「司敵」；其他角色的出牌階段開始時，你可以將一張「司敵」置入棄牌堆，該角色此階段內不能使用與「司」相同顏色的牌直到回合結束。此階段結束時，若其未使用：【殺】，你視為對其使用一張【殺】；錦囊牌，你摸兩張牌。",
	["@sidi_po"] = "你可以將一張非基本牌置於武將牌上，稱為「司敵」",
	["@sidi_po-card"] = "你可以棄置一張「司敵」牌，然後 %src 於此階段內不能使用或打出與此牌顏色相同的牌",
	["~sidi_po"] = "選擇一張「司敵」牌->點擊確定",
}

--界太史慈
taishici_po = sgs.General(extension, "taishici_po", "wu2",4,true)


tianyi_luaCard = sgs.CreateSkillCard{
	name = "tianyi_lua",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		if source:hasSkill("hanzhan") then

			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:addSubcard(self:getSubcards():first())
			local moves = sgs.CardsMoveList()
			local move = sgs.CardsMoveStruct(self:getSubcards(), source, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, source:objectName(), self:objectName(), ""))
			moves:append(move)

			local r_card = targets[1]:getRandomHandCard()
			slash:addSubcard(r_card:getId())

			local move = sgs.CardsMoveStruct(r_card:getEffectiveId(), targets[1], nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, targets[1]:objectName(), self:objectName(), ""))
			moves:append(move)

			room:moveCardsAtomic(moves, true)

			local pindian = sgs.PindianStruct()
			pindian.from = source
			pindian.to = targets[1]
			pindian.from_card = sgs.Sanguosha:getCard(self:getSubcards():first())
			pindian.to_card = r_card

			pindian.from_number = pindian.from_card:getNumber()
			pindian.to_number = pindian.to_card:getNumber()
			pindian.reason = "tianyi_lua"

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
			room:getThread():trigger(sgs.PindianVerifying, room, source, data)
			room:getThread():trigger(sgs.Pindian, room, source, data)

			--local move2 = sgs.CardsMoveStruct(slash:getSubcards(), nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
			--room:moveCardsAtomic(moves, true)
			room:removePlayerMark(source, self:objectName().."engine")

		else
			source:pindian(targets[1], "tianyi_lua", sgs.Sanguosha:getCard(self:getSubcards():first()))
		end
	end
}
tianyi_luaVS = sgs.CreateOneCardViewAsSkill{
	name = "tianyi_lua", 
	filter_pattern = ".|.|.|hand!",
	view_as = function(self, card)
		local aaa = tianyi_luaCard:clone()
		aaa:addSubcard(card)
		return aaa
	end,  
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tianyi_lua") and not player:isKongcheng()
	end, 
}
tianyi_lua = sgs.CreateTriggerSkill{
	name = "tianyi_lua",
	events = {sgs.Pindian},
	view_as_skill = tianyi_luaVS,
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
				room:setPlayerMark(pindian.from, "tianyi_success-Clear",1)
			elseif pindian.from_number < pindian.to_number then
				winner = pindian.to
				loser = pindian.from
				local log = sgs.LogMessage()
				log.type = "#PindianFailure"
				log.from = loser
				log.to:append(winner)
				room:sendLog(log)
				room:setPlayerCardLimitation(pindian.from, "use", "Slash", true)
			end
		end
		return false
	end, 
	can_trigger = function(self, player)
		return player and player:isAlive()
	end
}
tianyi_luaTargetMod = sgs.CreateTargetModSkill{
	name = "#tianyi_luaTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:getMark("tianyi_success-Clear") > 0 then
			return player:getMark("tianyi_success-Clear")
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player)
		if player:getMark("tianyi_success-Clear") > 0 then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player)
		if player:getMark("tianyi_success-Clear") > 0 then
			return 1
		else
			return 0
		end
	end,
}

hanzhan = sgs.CreateTriggerSkill{
	name = "hanzhan",
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Pindian then
			local pindian = data:toPindian()
							--local id = card:getEffectiveId()
				--if room:getCardPlace(id) == sgs.Player_PlaceTable then
			local max_slash_number = 0
			if pindian.from_card:isKindOf("Slash") then
				max_slash_number = pindian.from_card:getNumber()
			end
			if pindian.to_card:isKindOf("Slash") and pindian.to_card:getNumber() > max_slash_number then
				max_slash_number = pindian.to_card:getNumber()
			end

			if pindian.from_card:isKindOf("Slash") and max_slash_number == pindian.from_card:getNumber() then
				local id = pindian.from_card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
					room:notifySkillInvoked(player, "hanzhan")
					room:broadcastSkillInvoke("hanzhan")
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					room:obtainCard(player, pindian.from_card, true)
				end
			end
			if pindian.to_card:isKindOf("Slash") and pindian.to_card:getNumber() == max_slash_number then
				local id = pindian.to_card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
					room:notifySkillInvoked(player, "hanzhan")
					room:broadcastSkillInvoke("hanzhan")
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					room:obtainCard(player, pindian.to_card, true)
				end
			end
		end
		return false
	end,
}

taishici_po:addSkill(tianyi_lua)
taishici_po:addSkill(tianyi_luaTargetMod)
taishici_po:addSkill(hanzhan)

sgs.LoadTranslationTable{
["#taishici_po"] = "篤烈之士",
["&taishici_po"] = "太史慈",
["taishici_po"] = "界太史慈",
["illustrator:taishici_po"] = "Tuu.",
["tianyi_lua"] = "天義",
["#tianyi_luaTargetMod"] = "天義",
[":tianyi_lua"] = "階段技。你可以與一名其他角色拼點：若你贏，本回合，你可以額外使用一張【殺】，你使用【殺】可以額外選擇一名目標且無距離限制；若你沒贏，你不能使用【殺】，直到回合結束。",
["hanzhan"] = "酣戰",
[":hanzhan"] = "當你發起拼點時，或成為拼點的目標時，你可以令對方選擇拼點牌的方式改為隨機選擇一張手牌。當你拼點結束後，你可以獲得雙方拼點牌中點數最大的【殺】。",
}

--界韓當
handang_po = sgs.General(extension,"handang_po","wu2","4",true)

gongji_poCard = sgs.CreateSkillCard{
	name = "gongji_po" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source,"InfinityAttackRange")
		local cd = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:addPlayerMark(source, "chenglve" .. cd:getSuitString() .. "-Clear")

		if cd:isKindOf("EquipCard") then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if source:canDiscard(p, "he") then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local to_discard = room:askForPlayerChosen(source, _targets, "gongji_po", "@gongqi-discard", true)
				if to_discard then
					room:throwCard(room:askForCardChosen(source, to_discard, "he", "gongji_po", false, sgs.Card_MethodDiscard), to_discard, source)
				end
			end
		end
	end
}
gongji_po = sgs.CreateViewAsSkill{
	name = "gongji_po" ,
	n = 1 ,
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = gongji_poCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#gongji_po")
	end
}

jiefan_poCard = sgs.CreateSkillCard{
	name = "jiefan_po" ,
	filter = function(self, targets, to_select)
		return #targets == 0
	end  ,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("handang_po","jiefan_po")
		room:removePlayerMark(source, "@rescue")
		local target = targets[1]
		local _targetdata = sgs.QVariant()
		_targetdata:setValue(target)
		source:setTag("jiefan_poTarget", _targetdata)
		for _, player in sgs.qlist(room:getAllPlayers()) do
			if player:isAlive() and player:inMyAttackRange(target) then
				room:cardEffect(self, source, player)
			end
		end
		source:removeTag("jiefan_poTarget")
	end ,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local target = effect.from:getTag("jiefan_poTarget"):toPlayer()
		local data = effect.from:getTag("jiefan_poTarget")
		if target then
			if not room:askForCard(effect.to, ".Weapon", "@jiefan-discard::" .. target:objectName(), data) then
				target:drawCards(1)
			end
		end
	end
}
jiefan_poVS = sgs.CreateViewAsSkill{
	name = "jiefan_po" ,
	n = 0,
	view_as = function()
		return jiefan_poCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@rescue") >= 1
	end
}
jiefan_po = sgs.CreateTriggerSkill{
	name = "jiefan_po" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@rescue",
	events = {sgs.EventPhaseEnd},
	view_as_skill = jiefan_poVS ,

	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play then
			local lord_player
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isLord() or p:getMark("AG_firstplayer") > 0 then
					lord_player = p
					break
				end
			end
			if lord_player:getMark("@clock_time") == 1 and player:hasSkill("jiefan_po") then
				room:setPlayerMark(player,"@rescue",1)
			end
		end
	end
}

handang_po:addSkill(gongji_po)
handang_po:addSkill(jiefan_po)

sgs.LoadTranslationTable{
["handang_po"] = "界韓當",
["&handang_po"] = "韓當",
["gongji_po"] = "弓騎",
[":gongji_po"] = "出牌階段限一次，你可以棄置一張牌，然後你的攻擊範圍視為無限且使用與此牌花色相同的【殺】無次數限制直到回合結束。若你以此法棄置的牌為裝備牌，則你可以棄置一名其他角色的一張牌。",
["jiefan_po"] = "解煩",
[":jiefan_po"] = "限定技，出牌階段，你可以選擇一名角色，令攻擊範圍內含有該角色的所有角色依次選擇一項：1.棄置一張武器牌；2.令其摸一張牌。然後若遊戲輪數為1，則你於此回合結束時恢復此技能。",
}

--界韓浩史渙
hanhaoshihuan_po = sgs.General(extension,"hanhaoshihuan_po","wei2","4",true)

--慎斷
shenduan_poCard = sgs.CreateSkillCard{
	name = "shenduan_po",
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:cloneCard("supply_shortage",  sgs.Card_NoSuit, 0)
		return #targets == 0 and card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local sbs = {}
			if source:getTag("shenduan_po"):toString() ~= "" then
				sbs = source:getTag("shenduan_po"):toString():split("+")
			end
			for _,cdid in sgs.qlist(self:getSubcards()) do table.insert(sbs, tostring(cdid)) end
			source:setTag("shenduan_po", sgs.QVariant(table.concat(sbs, "+")))

			local c = sgs.Sanguosha:getCard(self:getSubcards():first())
			local card = sgs.Sanguosha:cloneCard("supply_shortage", c:getSuit(), c:getNumber())
			card:addSubcard(c:getEffectiveId())
			card:setSkillName(self:getSkillName())
			room:useCard(sgs.CardUseStruct(card, source, targets[1]), true)

			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

shenduan_poVS = sgs.CreateOneCardViewAsSkill{
	name = "shenduan_po",
	view_filter = function(self, card)
		return string.find(sgs.Self:property("shenduan_po"):toString(), tostring(card:getEffectiveId()))
	end,
	view_as = function(self, card)
		local lm = shenduan_poCard:clone()
		lm:addSubcard(card:getEffectiveId())
		lm:setSkillName(self:objectName())
		return lm
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self, player, pattern)
		return pattern == "@@shenduan_po" and player:hasSkill(self:objectName())
	end,
}
function listIndexOf(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
shenduan_po = sgs.CreateTriggerSkill{
	name = "shenduan_po",
	view_as_skill = shenduan_poVS,
	events = {sgs.BeforeCardsMove},
	--events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile then
			if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local zongxuan_card = sgs.IntList()
				for i=0, (move.card_ids:length()-1), 1 do
					local card_id = move.card_ids:at(i)
					local card = sgs.Sanguosha:getCard(card_id)

					if room:getCardOwner(card_id):getSeat() == move.from:getSeat()
						and (move.from_places:at(i) == sgs.Player_PlaceHand
						or move.from_places:at(i) == sgs.Player_PlaceEquip) and card:isBlack() and (card:isKindOf("BasicCard") or card:isKindOf("EquipCard")) then
						zongxuan_card:append(card_id)
					end
				end
				if zongxuan_card:isEmpty() then
					return
				end
				local zongxuantable = sgs.QList2Table(zongxuan_card)
				room:setPlayerProperty(player, "shenduan_po", sgs.QVariant(table.concat(zongxuantable, "+")))
				while not zongxuan_card:isEmpty() do
					if not room:askForUseCard(player, "@@shenduan_po", "@shenduan_po-use") then break end
					local subcards = sgs.IntList()
					local subcards_variant = player:getTag("shenduan_po"):toString():split("+")
					if #subcards_variant > 0 then
						for _,ids in ipairs(subcards_variant) do
							subcards:append(tonumber(ids))
						end
						local zongxuan = player:property("shenduan_po"):toString():split("+")
						for _, id in sgs.qlist(subcards) do
							zongxuan_card:removeOne(id)
							table.removeOne(zongxuan,tonumber(id))
							if move.card_ids:contains(id) then
								move.from_places:removeAt(listIndexOf(move.card_ids, id))
								move.card_ids:removeOne(id)
								data:setValue(move)
							end
							if player:isDead() then break end
						end
					end
					player:removeTag("shenduan_po")
				end
			end
		end
		return false
	end
}

shenduan_potm = sgs.CreateTargetModSkill{
	name = "#shenduan_potm" ,
	pattern = "SupplyShortage" ,
	distance_limit_func = function(self, from, card)
		if card:getSkillName() == "shenduan_po" then
			return 1000
		end
		return 0
	end
}

yonglve_po = sgs.CreateTriggerSkill{
	name = "yonglve_po",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Judge then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:canDiscard(player, "j") and p:objectName() ~= player:objectName() then
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:throwCard(room:askForCardChosen(p, player, "j", "yonglve_po", false, sgs.Card_MethodDiscard), player, p)
						room:broadcastSkillInvoke(self:objectName())
						if p:distanceTo(player) > p:getAttackRange() then
							if p:canSlash(player, nil, false) then
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:setSkillName("_yonglve_po")
								room:useCard(sgs.CardUseStruct(slash, p, player))
							end
						else
							p:drawCards(1)
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
hanhaoshihuan_po:addSkill(shenduan_po)
hanhaoshihuan_po:addSkill(shenduan_potm)
hanhaoshihuan_po:addSkill(yonglve_po)

sgs.LoadTranslationTable{
["hanhaoshihuan_po"] = "界韓浩史渙",
["&hanhaoshihuan_po"] = "韓浩史渙",
["shenduan_po"] = "慎斷",
[":shenduan_po"] = "當你的黑色基本牌或裝備牌因棄置而進入棄牌堆後，你可以將其當做【兵糧寸斷】使用（無距離限制）。",
["@shenduan_po-use"] = "你可以發動“慎斷”將其中一張牌當【兵糧寸斷】使用（無距離限制）",
["~shenduan_po"] = "選擇一張黑色基本牌→選擇【兵糧寸斷】的目標角色→點擊確定",
["yonglve_po"] = "勇略",
["_yonglve_po"] = "勇略",
[":yonglve_po"] = "其他角色的判定階段開始時，你可以棄置其判定區里的一張牌。然後若該角色在你攻擊範圍內，你摸一張牌。若其在你攻擊範圍外，視為你對其使用一張【殺】。",
}

--界張春華
zhangchunhua_po = sgs.General(extension,"zhangchunhua_po","wei2","3",false)

jueqing_po = sgs.CreateTriggerSkill{
	name = "jueqing_po",
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.damage > 0 and player:getMark("jueqing_po_change") == 0 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:handleAcquireDetachSkills(player, "-jueqing_po|jueqing" )
					room:broadcastSkillInvoke(self:objectName())
					local log = sgs.LogMessage()
					log.type = "$jueqing_poDMG"
					log.from = player
					log.arg = damage.damage + damage.damage
					room:sendLog(log)
					damage.damage = damage.damage + damage.damage
					data:setValue(damage)
					room:loseHp(player, damage.damage)
				end
			end
		end
	end,
}

zhangchunhua_po:addSkill(jueqing_po)
zhangchunhua_po:addSkill("shangshi")

sgs.LoadTranslationTable{
["#zhangchunhua_po"] = "冷血皇后",
["zhangchunhua_po"] = "界張春華",
["&zhangchunhua_po"] = "張春華",
["jueqing_po"] = "絕情",
[":jueqing_po"] = "當你對其他角色造成傷害時，你可以令此傷害值+X。若如此做，你失去X點體力，並於此傷害結算完成後修改〖絕情〗（X為傷害值）。",
["shangshi"] = "傷逝",
[":shangshi"] = "每當你的手牌數、體力值或體力上限改變後，你可以將手牌補至X張。（X為你已損失的體力值且至多為2）",
["$jueqing_poDMG"] = "%from 發動技能“絕情”，傷害值翻倍至 %arg 點",
}

--界程普
chengpu_po = sgs.General(extension,"chengpu_po","wu2","4",true)

--癘火
lihuo_poVS = sgs.CreateOneCardViewAsSkill{
	name = "lihuo_po" ,
	filter_pattern = "%slash" ,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end ,
	enabled_at_response = function(self, player, pattern)
		return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pattern == "slash"
	end ,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end ,
}

lihuo_po = sgs.CreateTriggerSkill{
	name = "lihuo_po" ,
	events = {sgs.PreDamageDone, sgs.CardFinished} ,
	view_as_skill = lihuo_poVS ,
	can_trigger = function(self, target)
		return target
	end ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:getSkillName() == self:objectName()) then
				room:setPlayerFlag(damage.from,"lihuo_po_er")
				room:setCardFlag(damage.card,"lihuo_po_card")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if (player and player:isAlive() and player:hasSkill(self:objectName())) and use.card and use.card:isKindOf("Slash") then
				if (not player:hasFlag("Global_ProcessBroken")) then
					local can_invoke = false
					if player:hasFlag("lihuo_po_er") and use.card:hasFlag("lihuo_po_card") then
						can_invoke = true
						room:setPlayerFlag(player,"-lihuo_po_er")
						room:setCardFlag(use.card,"-lihuo_po_card")
					end
					if can_invoke then
						room:loseHp(player)
					end
				end

				if player:getMark("card_used_num_Play") == 1 then
					player:addToPile("wine", use.card:getSubcards())
				end
			end
		end
		return false
	end
}
lihuo_poTargetMod = sgs.CreateTargetModSkill{
	name = "#lihuo_po-target" ,
	extra_target_func = function(self, from, card)
		if from:hasSkill("lihuo_po") and card:isKindOf("FireSlash") then
			return 1
		end
		return 0
	end ,
}

--醇醪
chunlao_poCard = sgs.CreateSkillCard{
	name = "chunlao_poCard" ,
	will_throw = false ,
	target_fixed = true ,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		source:addToPile("wine", self)
	end
}

chunlao_poWineCard = sgs.CreateSkillCard{
	name = "chunlao_poWine" ,
	mute = true ,
	target_fixed = true ,
	will_throw = false ,
	on_use = function(self, room, source, targets)
		local who = room:getCurrentDyingPlayer()
		if not who then return end
		if self:getSubcards():length() ~= 0 then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "chunlao_po", nil)
			room:throwCard(self, reason, nil)
			local analeptic = sgs.Sanguosha:cloneCard("Analeptic", sgs.Card_NoSuit, 0)
			analeptic:setSkillName("_chunlao_po")
			room:useCard(sgs.CardUseStruct(analeptic, who, who, false))

			--local c = sgs.Sanguosha:getEngineCard(id)
			local c = sgs.Sanguosha:getCard(self:getSubcards():first())
			if  c and c:isKindOf("FireSlash") then
				local recover = sgs.RecoverStruct()
				recover.who = source
				room:recover(source,recover)
			end

			if c and c:isKindOf("ThunderSlash") then
				source:drawCards(2)
			end
		end
	end
}
chunlao_poVS = sgs.CreateViewAsSkill{
	name = "chunlao_po" ,
	n = 999,
	expand_pile = "wine" ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "@@chunlao_po") or (string.find(pattern, "peach") and (not player:getPile("wine"):isEmpty()))
	end ,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@chunlao_po" then
			return to_select:isKindOf("Slash")
		else
			local pattern = ".|.|.|wine"
			if not sgs.Sanguosha:matchExpPattern(pattern, sgs.Self, to_select) then return false end
			return #selected == 0
		end
	end ,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@chunlao_po" then
			if #cards == 0 then return nil end
			local acard = chunlao_poCard:clone()
			for _, c in ipairs(cards) do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			return acard
		else
			if #cards ~= 1 then return nil end
			local wine = chunlao_poWineCard:clone()
			for _, c in ipairs(cards) do
				wine:addSubcard(c)
			end
			wine:setSkillName(self:objectName())
			return wine
		end
	end ,
}
chunlao_po = sgs.CreateTriggerSkill{
	name = "chunlao_po" ,
	events = {sgs.EventPhaseEnd,sgs.CardFinished} ,
	view_as_skill = chunlao_poVS ,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventPhaseEnd)
				and (player:getPhase() == sgs.Player_Play)
				and (not player:isKongcheng())
				and player:getPile("wine"):isEmpty() then
			room:askForUseCard(player, "@@chunlao_po", "@chunlao_po", -1, sgs.Card_MethodNone)
		end
		return false
	end
}

chengpu_po:addSkill(lihuo_po)
chengpu_po:addSkill(lihuo_poTargetMod)
chengpu_po:addSkill(chunlao_po)

sgs.LoadTranslationTable{
["#chengpu_po"] = "三朝虎臣",
["chengpu_po"] = "界程普",
["&chengpu_po"] = "程普",
["illustrator:chengpu_po"] = "紫喬",
["lihuo_po"] = "癘火",
["#lihuo_po-target"] = "癘火",
[":lihuo_po"] = "你使用普通的【殺】可以改為火【殺】，若此【殺】造成過傷害，你失去1點體力；你使用火【殺】可以多選擇一個目標。你每回合使用的第一張牌如果是【殺】，則此【殺】結算完畢後可置於你的武將牌上。",
["chunlao_po"] = "醇醪",
["_chunlao_po"] = "醇醪",
["chunlao_powine"] = "醇醪",
[":chunlao_po"] = "出牌階段結束時，若你沒有「醇」，你可以將任意張【殺】置於武將牌上，稱為「醇」；當一名角色處於瀕死狀態時，你可以移去一張「醇」，視為該角色使用一張【酒】。若移去的「醇」為火【殺】，則你回復1點體力；若移去的「醇」為雷【殺】，你摸兩張牌。",
["wine"] = "醇",
["@chunlao_po"] = "你可以發動“醇醪”",
["~chunlao_po"] = "選擇若干張【殺】→點擊確定",
}

--界周倉
zhoucang_po = sgs.General(extension, "zhoucang_po", "shu2", 4, true)
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

zhongyong_po = sgs.CreateTriggerSkill{
	name = "zhongyong_po",
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

					local help = false
					local help2 = false

					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					skill(self, room, player, false)
					local friend = room:askForPlayerChosen(player, friends, self:objectName(), "@zhongyong_po", false, true)
					if friend then
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							room:broadcastSkillInvoke(self:objectName(), 1)
							for _, i in sgs.list(ids) do
								if sgs.Sanguosha:getCard(i):isRed() then help = true end
								if sgs.Sanguosha:getCard(i):isBlack() then help2 = true end
							end
							dummy:addSubcards(ids)
							room:obtainCard(friend, dummy)
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
					room:clearAG(player)

					if not targets:isEmpty() and help then
						room:setPlayerFlag(friend, self:objectName())
						if room:askForUseSlashTo(friend, targets, "zhongyong_po_slash", false, false, false) then
							room:broadcastSkillInvoke(self:objectName(), 1)
						end
						room:setPlayerFlag(friend, "-"..self:objectName())
					end

					if help2 then
						friend:drawCards(1)
					end
				end
			end
		end
		return false
	end
}
zhoucang_po:addSkill(zhongyong_po)

sgs.LoadTranslationTable{
["zhoucang_po"] = "界周倉",
["&zhoucang_po"] = "周倉",
["#zhoucang_po"] = "披肝瀝膽",
["illustrator:zhoucang_po"] = "",
["zhongyong_po"] = "忠勇",
[":zhongyong_po"] = "當你使用【殺】後，你可以將此【殺】以及目標角色使用的【閃】交給一名其他角色，若其獲得的牌中有紅色，則其可以對你攻擊範圍內的角色使用一張【殺】。若其獲得的牌中有黑色，其摸一張牌。",
["$zhongyong_po1"] = "為將軍提刀攜馬，萬死不辭！",
["$zhongyong_po2"] = "驅刀飛血，直取寇首！",
["~zhoucang_po"] = "為將軍操刀牽馬，此生無憾...",
["@zhoucang_po"] = "將此【殺】或目標角色使用的【閃】交給一名角色",
["zhongyong_po_slash"] = "你可以對其攻擊範圍內的角色使用一張【殺】",
}

--界版郭逢
guotufengji_po = sgs.General(extension,"guotufengji_po","qun2","3",true)

jigong_po = sgs.CreateTriggerSkill{
	name = "jigong_po" ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player,self:objectName(),data) then
					room:broadcastSkillInvoke(self:objectName())
					local draw_num = {}
					for i = 1, 3 do
						table.insert(draw_num, tostring(i))
					end
					local choice = room:askForChoice(player, "jigong_po", table.concat(draw_num, "+"))
					player:drawCards(tonumber(choice))
					room:addPlayerMark(player, "jigong_po-Clear", tonumber(choice))
					
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard then
				if player:getMark("jigong_po-Clear") > 0 then
					if player:getMark("damage_record-Clear") >= player:getMark("jigong_po-Clear") then
						room:recover(player, sgs.RecoverStruct(player))
					end
				end
			end
		end
		return false
	end
}

jigong_pomc = sgs.CreateMaxCardsSkill{
	name = "#jigong_pomc", 
	frequency = sgs.Skill_Compulsory,
	fixed_func = function(self, player)
		if player:getMark("jigong_po-Clear") > 0 then
			return player:getMark("damage_record-Clear")
		end
		return -1
	end
}
guotufengji_po:addSkill(jigong_po)
guotufengji_po:addSkill(jigong_pomc)
guotufengji_po:addSkill("shifei")

sgs.LoadTranslationTable{
["guotufengji_po"] = "界郭圖逢紀",
["#guotufengji_po"] = "兇蛇兩端",
["&guotufengji_po"] = "郭圖逢紀",
["jigong_po"] = "急攻",
[":jigong_po"] = "出牌階段開始時，你可以摸至多三張牌。若如此做，此回合你的手牌上限改為X(X為你此階段造成的傷害數)，若X大於你摸的牌數，你恢復一點體力。",
}

--界祝融
ol_zhurong = sgs.General(extension,"ol_zhurong","shu2","4",false)

--長標
changbiaoVS = sgs.CreateViewAsSkill{
	name = "changbiao",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local rende =sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, c in ipairs(cards) do
				rende:addSubcard(c)
			end
			rende:setSkillName("changbiao")
			return rende
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getMark("changbiao-Clear") == 0
	end,
}
changbiao = sgs.CreateTriggerSkill{
	name = "changbiao",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = changbiaoVS, 
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.Damage, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and card:getSkillName() == self:objectName() then
				player:addMark("changbiao-Clear")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "changbiao" then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerMark(player, "changbiao_draw-Clear" , damage.card:getSubcards():length() )
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play and player:getMark("changbiao_draw-Clear") > 0 then
				player:drawCards( player:getMark("changbiao_draw-Clear") )
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) 
	end
}

ol_zhurong:addSkill("juxiang")
ol_zhurong:addSkill("lieren")
ol_zhurong:addSkill(changbiao)

sgs.LoadTranslationTable{
["#ol_zhurong"] = "野性的女王",
["ol_zhurong"] = "界祝融",
["&ol_zhurong"] = "祝融",
["changbiao"] = "長標",
[":changbiao"] = "出牌階段限一次，你可將任意張手牌當無距離限制的【殺】使用。若此【殺】對目標角色造成傷害，出牌階段結束時你摸等量的牌。"
}

--界姜維
jiangwei_po = sgs.General(extension,"jiangwei_po","shu2","4",true)
--挑釁
tiaoxin_poCard = sgs.CreateSkillCard{
	name = "tiaoxin_po" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:inMyAttackRange(sgs.Self) and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.from:hasSkill("baobian_po") then
			room:broadcastSkillInvoke("tiaoxin_po_audio",math.random(3,4))
		else
			room:broadcastSkillInvoke("tiaoxin_po_audio",math.random(1,2))
		end
		room:getThread():delay()
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to,effect.from, "@tiaoxin_po-slash:" .. effect.from:objectName())
		end
		if ((not use_slash) and effect.from:canDiscard(effect.to, "he")) or 
			(use_slash and not use_slash:hasFlag("tiaoxin_po_damage_record")) then
			room:throwCard(room:askForCardChosen(effect.from,effect.to, "he", "tiaoxin_po", false, sgs.Card_MethodDiscard), effect.to, effect.from)
			room:addPlayerMark(effect.from, "tiaoxin_po_Play")
		end

		if use_slash and use_slash:hasFlag("tiaoxin_po_damage_record") then
			room:setCardFlag( use_slash ,"-tiaoxin_po_damage_record")
		end

	end
}
tiaoxin_po = sgs.CreateViewAsSkill{
	name = "tiaoxin_po",
	n = 0 ,
	view_as = function()
		return tiaoxin_poCard:clone()
	end ,
	enabled_at_play = function(self, player)
		if player:getMark("tiaoxin_po_Play") > 0 then
			return player:usedTimes("#tiaoxin_po") < 2
		end
		return not player:hasUsed("#tiaoxin_po")
	end
}

tiaoxin_po_audio = sgs.CreateTriggerSkill{
	name = "tiaoxin_po_audio",
	events = {},
	on_trigger = function()
	end
}

if not sgs.Sanguosha:getSkill("tiaoxin_po_audio") then skills:append(tiaoxin_po_audio) end

zhiji_po = sgs.CreateTriggerSkill{
	name = "zhiji_po" ,
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
			
			room:broadcastSkillInvoke("zhiji_po")
			room:doSuperLightbox("jiangwei_po","zhiji_po")
			room:acquireSkill(player, "guanxing_po")
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
		room:addPlayerMark(player, "zhiji_po")
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("zhiji_po") == 0)
				and (target:getPhase() == sgs.Player_Start or target:getPhase() == sgs.Player_Finish)
				and (target:isKongcheng() or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}


jiangwei_po:addSkill(tiaoxin_po)
jiangwei_po:addSkill(zhiji_po)
jiangwei_po:addRelateSkill("tiaoxin_po_audio")


sgs.LoadTranslationTable{
["#jiangwei_po"] = "龍的衣缽",
["jiangwei_po"] = "界姜維",
["&jiangwei_po"] = "姜維",
["tiaoxin_po"] = "挑釁",
[":tiaoxin_po"] = "出牌階段限一次，你可以選擇一名攻擊範圍內含有你的角色，然後除非該角色對你使用一張【殺】且此【殺】對你造成傷害，否則你棄置其一張牌，然後將此技能修改為出牌階段限兩次直到回合結束。",
["@tiaoxin_po-slash"] = "%src 對你發動“挑釁”，請對其使用一張【殺】",
["tiaoxin_po_audio"] = "挑釁",
["zhiji_po"] = "志繼",
["#ZhijiWake"] = "%from 沒有手牌，觸發“%arg”覺醒",
[":zhiji_po"] = "覺醒技。準備階段或結束階段開始時，若你沒有手牌，你失去1點體力上限，然後回復1點體力或摸兩張牌，並獲得“觀星”。",

}

--界關平
guanping_po = sgs.General(extension,"guanping_po","shu2","4",true)

longyin_po = sgs.CreateTriggerSkill{
	name = "longyin_po",
	events = {sgs.CardUsed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			for _, me in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if me and me:canDiscard(me,"he") then
					local dcard = room:askForCard(me, "..", "@longyin_po", data,self:objectName()) 
					if dcard and use.m_addHistory then
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerHistory(player, use.card:getClassName(),-1)
						if use.card:isRed() then
							me:drawCards(1)
						end
						if use.card:getNumber() == dcard:getNumber() then
							if me:hasSkill("jiezhong") and me:getMark("@jiezhong") == 0 then
								room:setPlayerMark(me,"@jiezhong",1)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getPhase() == sgs.Player_Play
	end
}

jiezhong = sgs.CreateTriggerSkill{
	name = "jiezhong",
	frequency = sgs.Skill_Limited,
	limit_mark = "@jiezhong", 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Play and player:getMark("@jiezhong") > 0 then
				local n = player:getMaxHp() - player:getHandcardNum()
				if n > 0 then
					if room:askForSkillInvoke(player, "jiezhong", data) then
						room:removePlayerMark(player, "@jiezhong")
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doSuperLightbox("guanping_po","jiezhong")
						player:drawCards(n)
					end
				end
			end
		end
	end,
}

guanping_po:addSkill(longyin_po)
guanping_po:addSkill(jiezhong)

sgs.LoadTranslationTable{
["#guanping_po"] = "忠臣孝子",
["guanping_po"] = "界關平",
["&guanping_po"] = "關平",
["illustrator:guanping_po"] = "紫喬",
["longyin_po"] = "龍吟",
[":longyin_po"] = "當一名角色於其出牌階段內使用【殺】時，你可以棄置一張牌，令此【殺】不計入出牌階段的使用次數，然後若此【殺】為紅色，你摸一張牌。若你棄置的牌與【殺】點數相同，「竭忠」視為未發動過。",
["@longyin_po"] = "你可以棄置一張牌發動“龍吟”",
["jiezhong"] = "竭忠",
[":jiezhong"] = "限定技，出牌階段開始時，你可以將手牌摸至體力上限。",
}

--界蔡夫人
caifuren_po = sgs.General(extension, "caifuren_po", "qun2", 3, false)

--竊聽
qieting_po = sgs.CreateTriggerSkill{
	name = "qieting_po",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:getMark("damage_record-Clear") == 0 then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:objectName() ~= player:objectName() then
					local choicelist = {"qieting_po:draw","cancel"}
					if player:getWeapon() and p:getMark("@AbolishWeapon") == 0 and not p:getWeapon() then
						table.insert(choicelist, "qieting_po:0")
					end
					if player:getArmor() and p:getMark("@AbolishArmor") == 0 and not p:getArmor() then
						table.insert(choicelist, "qieting_po:1")
					end
					if player:getDefensiveHorse() and p:getMark("@AbolishDefensiveHorse") == 0 and not p:getDefensiveHorse() then
						table.insert(choicelist, "qieting_po:2")
					end
					if player:getOffensiveHorse() and p:getMark("@AbolishOffensiveHorse") == 0 and not p:getOffensiveHorse() then
						table.insert(choicelist, "qieting_po:3")
					end
					if player:getTreasure() and p:getMark("@AbolishTreasure") == 0 and not p:getTreasure() then
						table.insert(choicelist, "qieting_po:4")
					end

					local choice = room:askForChoice(p , "qieting_po", table.concat(choicelist, "+"))
					if choice ~= "cancel" then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						if choice == "qieting_po:draw" then
							p:drawCards(1)
						elseif choice == "qieting_po:0" then
							room:moveCardTo(player:getWeapon(), p, sgs.Player_PlaceEquip)
						elseif choice == "qieting_po:1" then
							room:moveCardTo(player:getArmor(), p, sgs.Player_PlaceEquip)
						elseif choice == "qieting_po:2" then
							room:moveCardTo(player:getDefensiveHorse(), p, sgs.Player_PlaceEquip)
						elseif choice == "qieting_po:3" then
							room:moveCardTo(player:getOffensiveHorse(), p, sgs.Player_PlaceEquip)
						elseif choice == "qieting_po:4" then
							room:moveCardTo(player:getTreasure(), p, sgs.Player_PlaceEquip)
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
--獻州
xianzhou_poCard = sgs.CreateSkillCard {
	name = "xianzhou_po",
	target_fixed = false,
	filter = function(self, targets, to_select, player, data)
		if player:hasFlag("xianzhou_po_target") then
			return #targets < player:getMark("xianzhou_po_count") and to_select:hasFlag("xianzhou_po_damage_target") and to_select:objectName() ~= player:objectName()
		end
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		if source:hasFlag("xianzhou_po_target") then
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.reason = "xianzhou_po"
			for _, p in ipairs(targets) do
				damage.to = p
				room:damage(damage)
			end
			room:setPlayerFlag(source, "-xianzhou_po_target")
			room:setPlayerMark(source, "xianzhou_po_count", 0)
		else
			room:doSuperLightbox("caifuren_po","xianzhou_po")
			local target = targets[1]
			room:removePlayerMark(source, "@handover")
			self:addSubcards(source:getEquips())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "xianzhou_po", "")
			room:moveCardTo(self, target, sgs.Player_PlaceHand, reason, false)

			local n = math.min(source:getMaxHp() - source:getHp(), self:subcardsLength())
			if n > 0 then
				local recover = sgs.RecoverStruct()
				recover.who = source
				recover.recover = n
				room:recover(source, recover)
			end

			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if target:inMyAttackRange(p) then
					n = n + 1
					room:setPlayerFlag(p,"xianzhou_po_damage_target")
				end
			end
			if n > 0 then
				room:setPlayerFlag(source,"xianzhou_po_target")
				room:setPlayerMark(source, "xianzhou_po_count", self:subcardsLength())
				room:askForUseCard(source, "@@xianzhou_po", "@xianzhou_po")
			end

			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p,"-xianzhou_po_damage_target")
			end

		end
	end,
}
xianzhou_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "xianzhou_po",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self)
		local card = xianzhou_poCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:hasEquip() and player:getMark("@handover") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xianzhou_po"
	end,
}

xianzhou_po = sgs.CreateTriggerSkill{
	name = "xianzhou_po",
	frequency = sgs.Skill_Limited,
	limit_mark = "@handover",
	view_as_skill = xianzhou_poVS,
	on_trigger = function()
	end
}
caifuren_po:addSkill(qieting_po)
caifuren_po:addSkill(xianzhou_po)

sgs.LoadTranslationTable{
["#caifuren_po"] = "襄江的蒲葦",
["caifuren_po"] = "界蔡夫人",
["&caifuren_po"] = "蔡夫人",

["qieting_po"] = "竊聽",
[":qieting_po"] = "一名其他角色的回合結束時，若其未於此回合內造成過傷害，你可以選擇一項：將其裝備區的一張牌置入自己的裝備區，或摸一張牌。",
["qieting_po:0"] = "移動武器牌",
["qieting_po:1"] = "移動防具牌",
["qieting_po:2"] = "移動+1坐騎",
["qieting_po:3"] = "移動-1坐騎",
["qieting_po:4"] = "移動寶物牌",
["qieting_po:draw"] = "摸一張牌",

["xianzhou_po"] = "獻州",
[":xianzhou_po"] = "限定技，出牌階段，你可以將裝備區裡的所有牌交給一名角色，你回復X點體力並選擇其攻擊範圍內的一至X名角色，然後你對這些角色各造成1點傷害。（X為你以此法交給其的牌數）",
["@xianzhou_po"] = "你可以對一至X名角色造成傷害",
["~xianzhou_po"] = "選擇若干名角色→點擊確定",
["$xianzhou_po1"] = "獻荊襄九郡，圖一世之安。",
["$xianzhou_po2"] = "丞相挾天威而至，吾等安敢不降？",
["~caifuren_po"] = "孤兒寡母，何必趕盡殺絕呢...",
}

--界顧雍
guyong_po = sgs.General(extension,"guyong_po","wu2","3",true)
--慎行
shenxing_poCard = sgs.CreateSkillCard{
	name = "shenxing_po",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:drawCards(1)
		if source:getMark("@shenxing_po-Clear") < 2 then
			room:addPlayerMark(source, "@shenxing_po-Clear")
		end
	end
}
shenxing_po = sgs.CreateViewAsSkill{
	name = "shenxing_po",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getMark("@shenxing_po-Clear") then return true end
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getMark("@shenxing_po-Clear") then
			local skill_card = shenxing_poCard:clone()
			for _, c in ipairs(cards) do
				skill_card:addSubcard(c)
			end
			skill_card:setSkillName(self:objectName())
			return skill_card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}

--秉壹
bingyi_poCard = sgs.CreateSkillCard{
	name = "bingyi_po",
	filter = function(self, targets, to_select)
		local all_same_color = true
		local cards = sgs.Self:getHandcards()
		if cards:first():isBlack() then
			for _, c in sgs.qlist(cards) do
				if c:isRed() then all_same_color = false end
			end
		elseif cards:first():isRed() then
			for _, c in sgs.qlist(cards) do
				if c:isBlack() then all_same_color = false end
			end
		end
		if all_same_color then
			return #targets < sgs.Self:getHandcardNum()
		end

	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:showAllCards(source)
			local cards = source:getHandcards()
			local all_same_color = true
			for _, c in sgs.qlist(cards) do
				if c:isRed() ~= cards:first():isRed() then all_same_color = false end
			end
			local all_same_number = true
			for _, c in sgs.qlist(cards) do
				if c:getNumber() ~= cards:first():getNumber() then all_same_number = false end
			end

			if all_same_color then
				for _,p in pairs(targets) do
					p:drawCards(1)
				end
			end

			if all_same_color and all_same_number then
				source:drawCards(1, self:objectName())
			end

			
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
bingyi_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "bingyi_po",
	response_pattern = "@@bingyi_po",
	view_as = function()
		return bingyi_poCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
bingyi_po = sgs.CreatePhaseChangeSkill{
	name = "bingyi_po",
	view_as_skill = bingyi_poVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			room:askForUseCard(player, "@@bingyi_po", "@bingyi_po-card")
		end
		return false
	end
}

guyong_po:addSkill(shenxing_po)
guyong_po:addSkill(bingyi_po)

sgs.LoadTranslationTable{
["#guyong_po"] = "廟堂的玉磬",
["guyong_po"] = "界顧雍",
["&guyong_po"] = "顧雍",
["shenxing_po"] = "慎行",
[":shenxing_po"] = "出牌階段，你可以棄置X張牌：若如此做，你摸一張牌。(X為你本回合發動「慎行」的次數且至多為2)",
["bingyi_po"] = "秉壹",
[":bingyi_po"] = "結束階段開始時，若你有手牌，你可以展示所有手牌：若均為同一顏色，你可以令至多X名角色各摸一張牌。（X為你的手牌數），若點數也相同，你摸一張牌",
["@bingyi_po-card"] = "你可以展示所有手牌發動“秉壹”",
["~bingyi_po"] = "若手牌均為同一顏色，選擇至多X名角色→點擊確定；否則直接點擊確定",
}

--界賈詡
jiaxu_po = sgs.General(extension,"jiaxu_po","qun2","3",true)

luanwu_poCard = sgs.CreateSkillCard{
	name = "luanwu_po",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("jiaxu","luanwu_po")
		room:removePlayerMark(source, "@chaos")
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:isAlive() then
				room:cardEffect(self, source, p)
			end
			room:getThread():delay()
		end
		local n = math.max(source:getMark("luanwu_po_not_use_slash_num"),source:getMark("luanwu_po_use_slash_num"))
		source:drawCards(n)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local players = room:getOtherPlayers(effect.to)
		local distance_list = sgs.IntList()
		local nearest = 1000
		for _,player in sgs.qlist(players) do
			local distance = effect.to:distanceTo(player)
			distance_list:append(distance)
			nearest = math.min(nearest, distance)
		end
		local luanwu_targets = sgs.SPlayerList()
		for i = 0, distance_list:length() - 1, 1 do
			if distance_list:at(i) == nearest and effect.to:canSlash(players:at(i), nil, false) then
				luanwu_targets:append(players:at(i))
			end
		end
		if luanwu_targets:length() == 0 or not room:askForUseSlashTo(effect.to, luanwu_targets, "@luanwu-slash") then
			room:loseHp(effect.to)
			room:addPlayerMark(effect.from,"luanwu_po_not_use_slash_num")
		else
			room:addPlayerMark(effect.from,"luanwu_po_use_slash_num")
		end
	end
}
luanwu_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "luanwu_po",
	view_as = function(self, cards)
		return luanwu_poCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@chaos") >= 1
	end
}
luanwu_po = sgs.CreateTriggerSkill{
	name = "luanwu_po" ,
	frequency = sgs.Skill_Limited ,
	view_as_skill = luanwu_poVS ,
	limit_mark = "@chaos" ,
	on_trigger = function()
	end
}

wansha_po = sgs.CreateTriggerSkill{
	name = "wansha_po",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches, sgs.EventPhaseChanging, sgs.Death,sgs.QuitDying},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local current = room:getCurrent()
			if current and current:isAlive() and current:hasSkill(self:objectName()) and current:getPhase() ~= sgs.Player_NotActive then
				if current:objectName() == player:objectName() then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(current, self:objectName())
					local log = sgs.LogMessage()
					log.from = current
					log.arg = self:objectName()
					if dying.who:objectName() ~= current:objectName() then
						log.type = "#WanshaTwo"
						log.to:append(dying.who)
					else
						log.type = "#WanshaOne"
					end
					room:sendLog(log)

					local log = sgs.LogMessage()
					log.from = current
					log.arg = self:objectName()
					log.type = "#WanshaThree"					
					log.to:append(dying.who)
					room:sendLog(log)

				end
				if dying.who:objectName() ~= player:objectName() and current:objectName() ~= player:objectName() then
					room:setPlayerMark(player, "Global_PreventPeach", 1)
					room:addPlayerMark(player, "@skill_invalidity")
					room:addPlayerMark(player, "wansha_po_skill_invalidity")
				end
			end

		elseif event == sgs.QuitDying then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("wansha_po_skill_invalidity") > 0 then
					room:setPlayerMark(p, "@skill_invalidity",0)
					room:setPlayerMark(p, "wansha_po_skill_invalidity",0)
				end
			end

		else
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then return false end
			elseif event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() ~= player:objectName() or death.who:getPhase() == sgs.Player_NotActive then return false end
			end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("Global_PreventPeach") > 0 then
					room:setPlayerMark(p, "Global_PreventPeach", 0)
				end
			end

			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("wansha_po_skill_invalidity") > 0 then
					room:setPlayerMark(p, "@skill_invalidity",0)
					room:setPlayerMark(p, "wansha_po_skill_invalidity",0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

weimu_po = sgs.CreateTriggerSkill{
	name = "weimu_po",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_NotActive then
			local damage = data:toDamage()
			
				local msg = sgs.LogMessage()
				msg.type = "#Weimu_poProtect"
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
}

weimu_poPS = sgs.CreateProhibitSkill{
	name = "#weimu_po",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("weimu_po") and (card:isKindOf("TrickCard") or card:isKindOf("QiceCard")) 
		and card:isBlack() and card:getSkillName() ~= "nosguhuo" --特别注意旧蛊惑
	end
}

jiaxu_po:addSkill(wansha_po)
jiaxu_po:addSkill(weimu_po)
jiaxu_po:addSkill(weimu_poPS)
jiaxu_po:addSkill(luanwu_po)

sgs.LoadTranslationTable{
["#jiaxu_po"] = "冷酷的毒士",
["jiaxu_po"] = "界賈詡",
["&jiaxu_po"] = "賈詡",
["wansha_po"] = "完殺",
[":wansha_po"] = "鎖定技。你的回合內，除瀕死角色外的其他角色不能使用【桃】，且任意瀕死角色的結算中，除了你與瀕死角色的非鎖定技無效",
["weimu_po"] = "帷幕",
[":weimu_po"] = "鎖定技。你不能被選擇為黑色錦囊牌的目標；你防止你於回合內受到的所有傷害。",
["luanwu_po"] = "亂武",
[":luanwu_po"] = "限定技。出牌階段，你可以令所有其他角色對距離最近的另一名角色使用一張【殺】，否則該角色失去1點體力；結算完畢後，你摸X張牌（X為使用殺的角色數量與不使用的角色數量中較大的值）。",
["@luanwu-slash"] = "請使用一張【殺】響應“亂武”",
["$LuanwuAnimate"] = "image=image/animate/luanwu.png",
["#WanshaOne"] = "%from 的“%arg”被觸發，只能 %from 自救",
["#WanshaTwo"] = "%from 的“%arg”被觸發，只有 %from 和 %to 才能救 %to",
["#WanshaThree"] = "受到 “%arg”影響，%from 和 %to 以外的其他角色的非鎖定技無效",
["#Weimu_poProtect"] = "%from 的「<font color=\"yellow\"><b>帷幕</b></font>」效果被觸發，防止了 %arg 點傷害[%arg2]",
}

--界魯肅
lusu_po = sgs.General(extension,"lusu_po","wu2","3",true)

haoshi_poCard = sgs.CreateSkillCard{
	name = "haoshi_poCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone ,
	filter = function(self, targets, to_select)
		if (#targets ~= 0) or to_select:objectName() == sgs.Self:objectName() then return false end
		return to_select:getHandcardNum() == sgs.Self:getMark("haoshi_po")
	end,
	on_use = function(self, room, source, targets)
		room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, false)
		room:addPlayerMark(targets[1],"@haoshi_po")
		room:addPlayerMark(source, "haoshi_po"..targets[1]:objectName().."_target" )
	end
}
haoshi_poVS = sgs.CreateViewAsSkill{
	name = "haoshi_po",
	n = 999,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		local length = math.floor(sgs.Self:getHandcardNum() / 2)
		return #selected < length
	end,
	view_as = function(self, cards)
		if #cards ~= math.floor(sgs.Self:getHandcardNum() / 2) then return nil end
		local card = haoshi_poCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@haoshi_po!"
	end
}
haoshi_po = sgs.CreateTriggerSkill{
	name = "haoshi_po",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = haoshi_poVS,
	events = {sgs.DrawNCards,sgs.AfterDrawNCards,sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if room:askForSkillInvoke(player, "haoshi_po") then
				room:setPlayerFlag(player, "haoshi_po")
				local count = data:toInt() + 2
				data:setValue(count)
			end
		elseif event == sgs.AfterDrawNCards then
			if player:hasFlag("haoshi_po") then
				player:setFlags("-haoshi_po")
				if player:getHandcardNum() <= 5 then return false end
				local least = 1000
				for _, _player in sgs.qlist(room:getOtherPlayers(player)) do
					least = math.min(_player:getHandcardNum(), least)
				end
				room:setPlayerMark(player, "haoshi_po", least)
				room:askForUseCard(player, "@@haoshi_po!", "@haoshi", -1, sgs.Card_MethodNone)
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:getMark("haoshi_po"..p:objectName().."_target") > 0 then
						local card
						if not p:isNude() then
							card = room:askForCard(p, ".", "@haoshi_po_give:"..player:objectName(), data, sgs.Card_MethodNone)
						end
						if card then
							room:doAnimate(1, player:objectName(), p:objectName())
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), self:objectName(), ""))
							room:getThread():delay()
						end
					end
				end
			end
		end
	end
}


--締盟

local json = require ("json")
dimeng_poCard = sgs.CreateSkillCard{
	name = "dimeng_po",
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then return true end
		if #targets == 1 then
			return math.abs(to_select:getHandcardNum() - targets[1]:getHandcardNum()) <= (sgs.Self:getHandcardNum() + sgs.Self:getEquips():length())
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local a = targets[1]
		local b = targets[2]
		a:setFlags("DimengTarget")
		b:setFlags("DimengTarget")
		local n1 = a:getHandcardNum()
		local n2 = b:getHandcardNum()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() ~= a:objectName() and p:objectName() ~= b:objectName() then
				room:doNotify(p, sgs.CommandType.S_COMMAND_EXCHANGE_KNOWN_CARDS, json.encode({a:objectName(), b:objectName()}))
			end
		end

		local msg = sgs.LogMessage()
		msg.type = "#Dimeng"
		msg.from = a
		msg.to:append(b)
		msg.arg = tostring(n1)
		msg.arg2 = tostring(n2)
		room:sendLog(msg)

		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(a:handCards(), b, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), "dimeng", ""))
		local move2 = sgs.CardsMoveStruct(b:handCards(), a, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), "dimeng", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
		room:moveCardsAtomic(exchangeMove, false);
	   	a:setFlags("-DimengTarget")
	   	b:setFlags("-DimengTarget")
	   	room:addPlayerMark(source ,"dimeng_po_Play")
	end
}
dimeng_poVS = sgs.CreateZeroCardViewAsSkill{
	name = "dimeng_po",
	view_as = function(self, cards)
		return dimeng_poCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#dimeng_po")
	end
}

dimeng_po = sgs.CreateTriggerSkill{
	name = "dimeng_po",
	events = {sgs.EventPhaseEnd},
	view_as_skill = dimeng_poVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			if player:getMark("dimeng_po_Play") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				local n = player:getMark("dimeng_po_Play")	
				room:askForDiscard(player, "dimeng_po", n, n, false, true)
			end
		end
	end
}

lusu_po:addSkill(haoshi_po)
lusu_po:addSkill(dimeng_po)

sgs.LoadTranslationTable{
["lusu_po"] = "界魯肅",
["haoshi_po"] = "好施",
[":haoshi_po"] = "摸牌階段開始時，你可以多摸兩張牌。然後摸牌階段結束時，若你的手牌數大於5，則你將手牌數的一半（向下取整）"..
"交給一名手牌最少其他角色並獲得如下效果直到你下回合開始：當你成為【殺】或普通錦囊牌的目標後，其可以交給你一張手牌。",
["dimeng_po"] = "締盟",
[":dimeng_po"] = "出牌階段限一次，你可令兩名滿足X≤Y的其他角色交換手牌並獲得如下效果：出牌階段結束時，你棄置X張牌"..
"（X為這兩名角色手牌數之差的絕對值；Y為你的總牌數）。",

["@haoshi_po"] = "請選擇“好施”的目標，將一半手牌（向下取整）交給該角色",
["~haoshi_po"] = "選擇需要給出的手牌→選擇一名其他角色→點擊確定",
["#Dimeng"] = "%from (原來 %arg 手牌) 與 %to (原來 %arg2 手牌) 交換了手牌",
}


--界王異
wangyi_po = sgs.General(extension,"wangyi_po","wei2","4",false)

wangyi_po:addSkill("zhenlie")
wangyi_po:addSkill("olmiji")

sgs.LoadTranslationTable{
["#wangyi_po"] = "決意的巾幗",
["wangyi_po"] = "界王異",
["&wangyi_po"] = "王異",
["illustrator:wangyi"] = "木美人",
["zhenlie"] = "貞烈",
[":zhenlie"] = "每當你成為其他角色的【殺】或非延時錦囊牌的目標後，你可以失去1點體力：若如此做，你棄置該角色的一張牌，此牌對你無效。",
["miji"] = "秘計",
[":miji"] = "結束階段開始時，若你已受傷，你可以摸至多X張牌，然後將等量的手牌任意分配給其他角色。（X為你已損失的體力值）" ,
["miji_draw"] = "秘計摸牌數",
}


sgs.Sanguosha:addSkills(skills)
