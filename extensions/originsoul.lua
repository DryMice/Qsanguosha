module("extensions.originsoul", package.seeall)
extension = sgs.Package("originsoul")

sgs.LoadTranslationTable{
	["originsoul"] = "原創之魂",
}

local skills = sgs.SkillList()

--李嚴
liyan = sgs.General(extension,"liyan","shu2","3",true)
--督糧
duliangCard = sgs.CreateSkillCard{
	name = "duliang",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local card = sgs.Sanguosha:getCard(room:askForCardChosen(source, targets[1], "h", self:objectName()))
			room:obtainCard(source, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName()), false)
			local choice = room:askForChoice(source, self:objectName(), "duliang1+duliang2")
			ChoiceLog(source, choice)
			if choice == "duliang1" then
				room:broadcastSkillInvoke(self:objectName(), 1)
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local ids = sgs.IntList()
				ids:append(room:drawCard())
				ids:append(room:drawCard())
				room:fillAG(ids, targets[1])
				for _, id in sgs.qlist(ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
						dummy:addSubcard(id)
					end
				end
				room:getThread():delay()
				targets[1]:obtainCard(dummy, false)
				room:clearAG()
			else
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:addPlayerMark(targets[1], self:objectName())
			end
			room:removePlayerMark(source, self:objectName().."engine")
		else
			room:broadcastSkillInvoke(self:objectName(), 2)
		end
	end
}
duliang = sgs.CreateZeroCardViewAsSkill{
	name = "duliang",
	view_as = function()
		return duliangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#duliang")
	end
}
duliangStart = sgs.CreateTriggerSkill{
	name = "duliangStart" ,
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			if player:getMark("duliang") > 0 then
				local count = data:toInt() + 1
				data:setValue(count)
				room:setPlayerMark(player, "duliang", 0)
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("duliangStart") then skills:append(duliangStart) end

--腹鱗
fulin = sgs.CreateTriggerSkill{
	name = "fulin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if player:getMark(self:objectName()..id.."-Clear") > 0 then
						room:setPlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString(), false)
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard then
				for _,id in sgs.qlist(player:handCards()) do
					if player:getMark(self:objectName()..id.."-Clear") > 0 then
						room:removePlayerCardLimitation(player, "discard", sgs.Sanguosha:getCard(id):toString().."$0")
					end
				end
			end
		end
	end
}

fulinmc = sgs.CreateMaxCardsSkill{
	name = "#fulinmc",
	extra_func = function(self, target)
		local x = 0
		if target:hasSkill("fulin") then
			for _, card in sgs.list(target:getHandcards()) do
				if target:getMark("fulin"..card:getId().."-Clear") > 0 then
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

liyan:addSkill(duliang)
liyan:addSkill(fulin)
liyan:addSkill(fulinmc)


sgs.LoadTranslationTable{
	["liyan"] = "李嚴",
	["#liyan"] = "矜風流務",
	["duliang"] = "督糧",
	[":duliang"] = "出牌階段限一次，你可以獲得一名其他角色的一張手牌，然後選擇一項：1.令其觀看牌堆頂的兩張牌，然後獲得其中的基本牌；2.令其於下個摸牌階段額外摸一張牌。",
	["duliang1"] = "令其觀看牌堆頂的兩張牌，然後獲得其中的基本牌",
	["duliang2"] = "令其於下個摸牌階段額外摸一張牌。",
	["fulin"] = "腹鱗",
	["#fulinmc"] = "腹鱗",
	[":fulin"] = "鎖定技，棄牌階段內，你於此回合內獲得的牌不計入你的手牌數。",
	["$duliang1"] = "糧草已到，請將軍驗看~",
	["$duliang2"] = "告訴丞相，山路難走，請寬限幾天~",
	["$fulin1"] = "丞相！丞相！你們沒看見我嗎！",
	["$fulin2"] = "我乃託孤忠臣，卻在這兒搞什麼糧草！",
}

--孫資劉放
sunziliufang = sgs.General(extension,"sunziliufang","wei2","3",true)
--【譏諛】出牌階段每名角色限一次，若你有可以使用的手牌，你可以令一名角色棄置一張手牌。若如此做，你不能使用與之相同花色的牌，直到回合結束。若其以此法棄置的牌為黑桃，你翻面並令其失去1點體力。
jiyuCard = sgs.CreateSkillCard{
	name = "jiyu", 
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:getMark("jiyu_Play") == 0
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(targets[1], "jiyu_Play")
		room:notifySkillInvoked(source, self:objectName())
		room:broadcastSkillInvoke(self:objectName(), 2)
		local _data = sgs.QVariant() 
		_data:setValue(source)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if targets[1]:canDiscard(targets[1], "h") then
				local card = room:askForCard(targets[1], ".!", "@jiyu", _data)
				if card then
					room:setPlayerCardLimitation(source, "use", ".|"..card:getSuitString(), true)
					if card:getSuit() == sgs.Card_Spade then
						room:broadcastSkillInvoke(self:objectName(), 1)
						source:turnOver()
						room:loseHp(targets[1])
					end
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jiyu = sgs.CreateZeroCardViewAsSkill{
	name = "jiyu", 
	view_as = function(self, cards)
		local card = jiyuCard:clone()
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isAvailable(player) then 
				return true
			end
		end
		return false
	end
}

--【瑰藻】棄牌階段結束時，若你於此階段棄置牌的數量不小於2且它們的花色各不相同，你可以回復1點體力或摸一張牌。
guizao = sgs.CreateTriggerSkill{
	name = "guizao",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()		
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName()) and player:getPhase() == sgs.Player_Discard and
				(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) 
				and not player:hasFlag("zhongyong_InTempMoving") then				
				local i = 0
				local lirang_card = sgs.IntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						local place = move.from_places:at(i)
						if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
							lirang_card:append(card_id)
						end
					end
					i = i + 1
				end
				local n = lirang_card:length()
				if n >= 2 then
					local suit_set = {}
					for _, id in sgs.qlist(lirang_card) do 
						local flag = true
						local card = sgs.Sanguosha:getCard(id)
						for _, k in ipairs(suit_set) do
							if card:getSuit() == k then
								flag = false
								break
							end
						end
						if flag then table.insert(suit_set, card:getSuit()) end
					end
					extra = #suit_set
					if extra == n then
						room:notifySkillInvoked(player, "guizao")
						room:broadcastSkillInvoke("guizao")
						if player:isWounded() then
							local choices = {"guizaoRecover", "guizaoDraw"}
							local choice = room:askForChoice(player , "guizao", table.concat(choices, "+"))
							if choice == "guizaoRecover" then
								local recover = sgs.RecoverStruct()
								recover.who = player
								recover.recover = 1
								room:recover(player, recover)
							else
								room:drawCards(player, 1, "guizao")
							end
						else
							room:drawCards(player, 1, "guizao")
						end
					end
				end
			end
		end
		return false
	end					
}
sunziliufang:addSkill(jiyu)
sunziliufang:addSkill(guizao)

sgs.LoadTranslationTable{
	["sunziliufang"] = "孫資劉放",
	["#sunziliufang"] = "服讒搜慝",
	["jiyu"] = "譏諛",
	["@jiyu"] = "請棄置一張手牌",
	[":jiyu"] = "出牌階段每名角色限一次，若你有可以使用的手牌，你可以令一名角色棄置一張手牌。若如此做，你不能使用與之相同花色的牌，直到回合結束。若其以此法棄置的牌為黑桃，你翻面並令其失去1點體力。",
	["guizao"] = "瑰藻",
	[":guizao"] = "棄牌階段結束時，若你於此階段棄置牌的數量不小於2且它們的花色各不相同，你可以回復1點體力或摸一張牌。",
	["$guizao1"] = "這都是陛下的恩澤啊~",
	["$guizao2"] = "陛下盛寵，臣萬莫敢忘~",
	["$jiyu1"] = "陛下，此人不堪大用！",
	["$jiyu2"] = "爾等玩忽職守，依詔降職處置~",
}

--張讓
zhangrang = sgs.General(extension, "zhangrang", "qun2", "3", true)
--滔亂
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

taoluan_select = sgs.CreateSkillCard{
	name = "taoluan",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
--		for _, name in ipairs(patterns) do
--			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
--			poi:setSkillName("taoluan")
--			poi:addSubcard(self:getSubcards():first())
--			if poi:isAvailable(source) and source:getMark("taoluan"..name) == 0 and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
--				table.insert(choices, name)
--			end
--		end
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("taoluan"..card:objectName()) == 0  and source:getMark("AG_BANCard"..card:objectName()) == 0 and (card:isKindOf("BasicCard") or card:isNDTrick()) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "taoluan", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("taoluan")
					poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					local pos = 0
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "taoluanpos", pos)
					room:setPlayerProperty(source, "taoluan", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@taoluan", "@taoluan:"..pattern)--%src
				end
			end
		end
	end
}
taoluanCard = sgs.CreateSkillCard{
	name = "taoluanCard",
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
				if user:getMark("taoluan"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(user, "taoluan", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("taoluan")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if card_use.from:getMark("taoluan"..name) == 0 then
					table.insert(uses, name)
				end
			end
			local name = room:askForChoice(card_use.from, "taoluan", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("taoluan")
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
taoluanVS = sgs.CreateViewAsSkill{
	name = "taoluan",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@taoluan" then
			return false
		else return true end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = taoluan_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = taoluanCard:clone()
			if pattern and pattern == "@@taoluan" then
				pattern = patterns[sgs.Self:getMark("taoluanpos")]
				acard:addSubcard(sgs.Self:property("taoluan"):toInt())
				if #cards ~= 0 then return end
			else
				if #cards ~= 1 then return end
				acard:addSubcard(cards[1]:getId())
			end
			if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
				pattern = "analeptic"
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) and player:getMark("taoluan"..name) == 0 then
				table.insert(choices, name)
			end
		end
		return next(choices) and player:getMark("taoluan-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or player:getMark("taoluan-Clear") > 0 then return false end
		for _, p in pairs(pattern:split("+")) do
			if player:getMark(self:objectName()..p) == 0 then return true end
		end
	end,
	enabled_at_nullification = function(self, player, pattern)
		return player:getMark("taoluannullification") == 0 and player:getMark("taoluan-Clear") == 0
	end
}
taoluan = sgs.CreateTriggerSkill{
	name = "taoluan",
	view_as_skill = taoluanVS,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished},
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
			if card and card:getHandlingMethod() == sgs.Card_MethodUse then
				if card:getSkillName() == "taoluan" and player:getMark("taoluan"..card:objectName()) == 0 then
					room:addPlayerMark(player, "taoluan"..card:objectName())
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "taoluan" and use.card:getTypeId() ~= 0 then
				local types = {"BasicCard", "TrickCard", "EquipCard"}
				table.removeOne(types,types[use.card:getTypeId()])
				room:setTag("TaoluanType", sgs.QVariant(table.concat(types, ",")))
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@taoluan-ask:" .. use.card:objectName(), false, true)
				room:removeTag("TaoluanType")
				if target then
					local card
					--if not target:isKongcheng() then
					if not target:isNude() then
						card = room:askForCard(target, table.concat(types, ","), "@taoluan-give:" .. player:objectName(), data, sgs.Card_MethodNone)
					end
					if card then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), player:objectName(), self:objectName(), nil)
						reason.m_playerId = player:objectName()
						room:moveCardTo(card, target, player, sgs.Player_PlaceHand, reason)
					else
						room:loseHp(player)
						room:addPlayerMark(player, "taoluan-Clear")
					end
				end
			end
		end
	end
}

zhangrang:addSkill(taoluan)

sgs.LoadTranslationTable{
	["zhangrang"] = "張讓",
	["#zhangrang"] = "竊幸絕禋",
	["taoluan"] = "滔亂",
	[":taoluan"] = "你的回合內，你可以將任何一張牌當作一張基本牌或延時錦囊牌使用，然後你選擇一名角色，令其選擇1.交給你一張牌，或2.你失去一點體力，且「滔亂」無效直到回合結束",
	["taoluancard"] = "滔亂",
	["@taoluan-askcard"] = "請選擇一名角色，其需選擇是否交給你一張牌，否則你失去一點體力",
	["$taoluan1"] = "睜開你的眼睛看看，現在，是誰說了算",
	["$taoluan2"] = "國家承平，神氣穩固，陛下勿憂~",
	["@taoluan"] = "請選擇目標",
	["~taoluan"] = "選擇若干名角色→點擊確定",
	["@taoluan-ask"] = "請選擇一名其他角色",
	["@taoluan-give"] = "請交出 %src 一張牌，否則其失去一點體力",
}

--岑昏
cenhun = sgs.General(extension, "cenhun", "wu2", "3", true)
--極奢:出牌階段，若你的手牌上限大於0，則你可以摸一張牌，然後本回合你的手牌上限-1；結束階段，若你沒有手牌，則你可以橫置至多X名角色的武將牌（X為你的體力值）。
jishecard = sgs.CreateSkillCard{
	name = "jishe",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			source:drawCards(1, self:objectName())
			room:addPlayerMark(source, "@jishe-Clear")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jishechainedcard = sgs.CreateSkillCard{
	name = "jishe_chained", 
	filter = function(self, targets, to_select)
		return not to_select:isChained() and #targets < sgs.Self:getHp()
	end, 
	feasible = function(self, targets)
		return #targets <= sgs.Self:getHp() and #targets > 0
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine", 2)
		if source:getMark(self:objectName().."engine") > 0 then
			for _, p in ipairs(targets) do
				room:setPlayerProperty(p, "chained", sgs.QVariant(true))
			end
			room:removePlayerMark(source, self:objectName().."engine", 2)
		end
	end
}
jisheVS = sgs.CreateZeroCardViewAsSkill{
	name = "jishe", 
	view_as = function(self, cards)
		if sgs.Self:getPhase() == sgs.Player_Finish then
			return jishechainedcard:clone()
		end
		return jishecard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getMaxCards() > 0
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jishe"
	end
}
jishe = sgs.CreatePhaseChangeSkill{
	name = "jishe", 
	view_as_skill = jisheVS, 
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish and player:isKongcheng() and player:getHp() > 0 then
			player:getRoom():askForUseCard(player, "@@jishe", "@jishe")
		end
	end
}
jisheMax = sgs.CreateMaxCardsSkill{
	name = "#jisheMax", 
	extra_func = function(self, target)
		return -target:getMark("@jishe-Clear")
	end
}
--鏈禍:鎖定技，當你受到火焰傷害時，若你處於“連環狀態”且你是傳導傷害的起點，則此傷害+1
lianhuo = sgs.CreateTriggerSkill{
	name = "lianhuo",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.chain and (damage.nature == sgs.DamageStruct_Fire) and player:isChained() then	
			room:notifySkillInvoked(player, "lianhuo")
			room:broadcastSkillInvoke("lianhuo")
			damage.damage = damage.damage + 1
			local msg = sgs.LogMessage()
			msg.type = "#Lianhuo"
			msg.from = player
			msg.to:append(damage.from)
			msg.arg = tostring(damage.damage - 1)
			msg.arg2 = tostring(damage.damage)
			room:sendLog(msg)
			data:setValue(damage)
		end
		return false
	end
}

cenhun:addSkill(jishe)
cenhun:addSkill(jisheMax)
cenhun:addSkill(lianhuo)
extension:insertRelatedSkills("jishe", "#jisheMax")
sgs.LoadTranslationTable{
	["cenhun"] = "岑昏",
	["#cenhun"] = "伐梁傾邷",
	["jishe"] = "極奢",
	["jishe_chained"] = "極奢",
	[":jishe"] = "出牌階段，若你的手牌上限大於0，則你可以摸一張牌，然後本回合你的手牌上限-1；結束階段，若你沒有手牌，則你可以橫置至多X名角色的武將牌（X為你的體力值）。",
	["lianhuo"] = "鏈禍",
	[":lianhuo"] = "鎖定技，當你受到火焰傷害時，若你處於“連環狀態”且你是傳導傷害的起點，則此傷害+1",
	["#Lianhuo"] = "%from 的技能 “<font color=\"yellow\"><b>鏈禍</b></font>”被觸發，%to 對 %from 造成的傷害由 %arg 點增加到 %arg2 點",
	["$jishe1"] = "孫吳正當盛世，興些土木又何妨~",
	["$jishe2"] = "當再建新殿，揚我國威！",
	["$lianhuo1"] = "用那剩下的鐵石，正好做些工事！",
	["$lianhuo2"] = "築下這鐵鍊，江東天險牢不可破！",
}

--劉虞
liuyu = sgs.General(extension, "liuyu", "qun2", "2", true)
--止戈：出牌階段限一次，若你的手牌數大於你的體力值，你可以選擇攻擊範圍內含有你的一名其他角色，除非該角色使用一張【殺】，否則其將裝備區裡的一張牌交給你。
zhigeCard = sgs.CreateSkillCard{
	name = "zhigeCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:inMyAttackRange(sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		local luanwu_targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(targets[1])) do
			if p:inMyAttackRange(targets[1]) and targets[1]:canSlash(p, nil, false) then
				luanwu_targets:append(p)
			end
		end
		if luanwu_targets:length() == 0 or not room:askForUseSlashTo(targets[1], luanwu_targets, "@zhige_slash") then
			if targets[1]:getEquips():length() > 0 then
				local card = room:askForCard(targets[1], ".|.|.|equipped!", "@zhige_give", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
				end
			end
		end
	end
}

zhige = sgs.CreateZeroCardViewAsSkill{
	name = "zhige",
	view_as = function(self,cards)
		return zhigeCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#zhigeCard") < 1
	end
}
--宗祚：鎖定技，遊戲開始時，你加X點體力上限和體力（X為全場勢力數）；當某勢力的最後一名角色死亡後，你減1點體力上限。
zongzuo = sgs.CreateTriggerSkill{
	name = "zongzuo",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data, room) 
		if event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			local lastone = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == splayer:getKingdom() then
					lastone = false
					break
				end
			end
			if lastone then
				room:notifySkillInvoked(player, "zongzuo")
				room:broadcastSkillInvoke(self:objectName(),2)
				room:notifySkillInvoked(player, "zongzuo")
				room:sendCompulsoryTriggerLog(player, "zongzuo") 
				room:loseMaxHp(player)
			end
			return false
		end
	end,
	priority = -1,
}

liuyu:addSkill(zhige)
liuyu:addSkill(zongzuo)

sgs.LoadTranslationTable{
	["liuyu"] = "劉虞",
	["zhige"] = "止戈",
	[":zhige"] = "出牌階段限一次，若你的手牌數大於你的體力值，你可以選擇攻擊範圍內含有你的一名其他角色，除非該角色使用一張【殺】，否則其將裝備區裡的一張牌交給你。",
	["zongzuo"] = "宗祚",
	[":zongzuo"] = "鎖定技，遊戲開始時，你加X點體力上限和體力（X為全場勢力數）；當某勢力的最後一名角色死亡後，你減1點體力上限。",
	["$zhige1"] = "天下和，而平亂~ 神器寧，而止戈~",
	["$zhige2"] = "刀兵紛爭即止，國運福祚綿長~",
	["$zongzuo1"] = "盡死生之力，保大廈不傾~",
	["$zongzuo2"] = "乾坤倒，黎民苦，高祖後，豈任之？",
}

--孫登
sundeng = sgs.General(extension, "sundeng", "wu2", "4", true)
--匡弼
kuangbiCard = sgs.CreateSkillCard{
	name = "kuangbi" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) 
	end,
	on_use = function(self, room, source, targets)	
		local to_exchange = room:askForExchange(targets[1], "kuangbi", 3, 1, true, "@kuangbi")
		source:addToPile("kuang", to_exchange)
		room:addPlayerMark(source, self:objectName()..targets[1]:objectName())
		room:setPlayerMark(targets[1],"kuangbitarget",1)
	end
}

kuangbiVS = sgs.CreateZeroCardViewAsSkill{
	name = "kuangbi",
	view_as = function(self,cards)
		return kuangbiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#kuangbi") < 1
	end
}
kuangbi = sgs.CreatePhaseChangeSkill{
	name = "kuangbi",
	view_as_skill = kuangbiVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if not player:getPile("kuang"):isEmpty() and player:getPhase() == sgs.Player_RoundStart then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(player:getPile("kuang")) do
				dummy:addSubcard(id)
			end
			room:obtainCard(player, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName()), false)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark(self:objectName()..p:objectName()) > 0 then
					room:setPlayerMark(player, self:objectName()..p:objectName(), 0)
					if p:isAlive() then
						room:broadcastSkillInvoke(self:objectName(), 2)
						p:drawCards(dummy:subcardsLength(), self:objectName())
					end
				end
			end
			dummy:deleteLater()
		end
		return false
	end
}
sundeng:addSkill(kuangbi)

sgs.LoadTranslationTable{
	["sundeng"] = "孫登",
	["kuangbi"] = "匡弼",
	["kuang"] = "輔",
	[":kuangbi"] = "出牌階段限一次，你可以令一名有牌的其他角色將其一至三張牌置於你的武將牌上。若如此做，你的下回合開始時，你獲得武將牌上的所有牌，然後其摸等量的牌。",
["$kuangbi1"] = "匡人助己，輔政弼賢",
["$kuangbi2"] = "興隆大化，佐理時務",
["@kuangbi"] = "请选择一至三张牌",
}
--郭后
guohuanghou = sgs.General(extension, "guohuanghou", "wei2", 3, false)

jiaozhaoCard = sgs.CreateSkillCard{
	name = "jiaozhao", 
	will_throw = false, 
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("danxin") == 2 then
			return false
		else
			local nearest = 1000
			for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
				nearest = math.min(nearest, sgs.Self:distanceTo(p))
			end
			return #targets == 0 and sgs.Self:distanceTo(to_select) == nearest
		end
		return false
	end, 
	feasible = function(self, targets)
		if sgs.Self:getMark("danxin") == 2 then
			return #targets == 0
		else
			return #targets == 1
		end
	end, 
	on_use = function(self, room, source, targets)
		local target = source
		if targets[1] then target = targets[1] end
		room:showCard(source, self:getSubcards():first())
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local ban_list,choices = {},sgs.IntList()
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and not table.contains(ban_list, card:objectName()) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
					if (card:isKindOf("BasicCard") or card:isNDTrick()) then
						table.insert(ban_list, card:objectName())
					end
				end
			end
			local announce_table = {}
			for _,name in ipairs(ban_list) do
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					--card:getSuit() == 6 和 card:getNumber() == 14 中沒有延時錦囊和其他模式的錦囊牌
--					if card:objectName() == name and (card:isKindOf("BasicCard") or (source:getMark("danxin") > 0 and card:isNDTrick())) and card:getSuit() == 6 and card:getNumber() == 14 then
--						choices:append(i)
--					end
					if card:objectName() == name and (card:isKindOf("BasicCard") or (source:getMark("danxin") > 0 and card:isNDTrick())) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
						if not table.contains(announce_table, TrueName(card)) then
							table.insert(announce_table, TrueName(card))
							choices:append(i)
						end
					end
				end
			end
			room:fillAG(choices)
			local card_id = room:askForAG(target, choices, false, self:objectName())
			if card_id ~= -1 then
				ChoiceLog(target, sgs.Sanguosha:getCard(card_id):objectName())
				room:addPlayerMark(source, self:objectName()..sgs.Sanguosha:getCard(card_id):objectName().."-Clear")
				room:addPlayerMark(source, self:objectName()..self:getSubcards():first().."-Clear", 2)
				room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():first()), self:objectName()..sgs.Sanguosha:getCard(card_id):objectName())
			end
			room:clearAG()
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jiaozhao = sgs.CreateOneCardViewAsSkill{
	name = "jiaozhao", 
	view_filter = function(self, card)
		local writing = false
		for _, mark in sgs.list(sgs.Self:getMarkNames()) do
			if string.find(mark, self:objectName()) and sgs.Self:getMark(mark) == 1 then
				writing = string.sub(mark, 9, string.len(mark) - 6)
			end
		end
		if not writing then
			return not card:isEquipped()
		end
		return sgs.Self:getMark(self:objectName()..card:getId().."-Clear") == 2
	end, 
	view_as = function(self, card)
		local writing = false
		for _, mark in sgs.list(sgs.Self:getMarkNames()) do
			if string.find(mark, self:objectName()) and sgs.Self:getMark(mark) > 0 then
				writing = string.sub(mark, 9, string.len(mark) - 6)
			end
		end
		if writing then
			local skillcard = sgs.Sanguosha:cloneCard(writing, card:getSuit(), card:getNumber())
			skillcard:setSkillName(self:objectName())
			skillcard:addSubcard(card)
			return skillcard
		else
			local skillcard = jiaozhaoCard:clone()
			skillcard:setSkillName(self:objectName())
			skillcard:addSubcard(card)
			return skillcard
		end
	end, 
	enabled_at_play = function(self, player)
		return true
	end, 
	enabled_at_response = function(self, player, pattern)
		local writing = false
		for _, mark in sgs.list(player:getMarkNames()) do
			if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
				writing = string.sub(mark, 9, string.len(mark) - 6)
			end
		end
		return writing and (pattern == writing or string.find(pattern, writing))
	end, 
	enabled_at_nullification = function(self, player)
		local writing = false
		for _, mark in sgs.list(player:getMarkNames()) do
			if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
				writing = string.sub(mark, 9, string.len(mark) - 6)
			end
		end
		return writing and writing == "nullification"
	end
}

jiaozhaoban = sgs.CreateProhibitSkill{
	name = "jiaozhaoban",
	is_prohibited = function(self, from, to, card)
		if from:hasSkill("jiaozhao") and card:getSkillName() == "jiaozhao" and from:objectName() == to:objectName() then
			return true
		end
	end
}

if not sgs.Sanguosha:getSkill("jiaozhaoban") then skills:append(jiaozhaoban) end

guohuanghou:addSkill(jiaozhao)

--殫心
danxin = sgs.CreateMasochismSkill{
	name = "danxin", 
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local choices = {"danxin1+cancel"}
		if player:getMark(self:objectName()) == 0 then
			table.insert(choices, "danxin2")
		elseif player:getMark(self:objectName()) == 1 then
			table.insert(choices, "danxin3")
		end
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
		if choice ~= "cancel" then
			lazy(self, room, player, choice, true)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				if choice == "danxin1" then
					player:drawCards(1, self:objectName())
				else
					if player:getMark(self:objectName()) == 0 then
						sgs.Sanguosha:addTranslationEntry(":danxin", ""..string.gsub(sgs.Sanguosha:translate(":danxin"), sgs.Sanguosha:translate(":danxin"), sgs.Sanguosha:translate(":danxin1")))
						sgs.Sanguosha:addTranslationEntry(":jiaozhao", ""..string.gsub(sgs.Sanguosha:translate(":jiaozhao"), sgs.Sanguosha:translate(":jiaozhao"), sgs.Sanguosha:translate(":jiaozhao1")))
					else
						sgs.Sanguosha:addTranslationEntry(":danxin", ""..string.gsub(sgs.Sanguosha:translate(":danxin"), sgs.Sanguosha:translate(":danxin"), sgs.Sanguosha:translate(":danxin2")))
						sgs.Sanguosha:addTranslationEntry(":jiaozhao", ""..string.gsub(sgs.Sanguosha:translate(":jiaozhao"), sgs.Sanguosha:translate(":jiaozhao"), sgs.Sanguosha:translate(":jiaozhao2")))
					end
					--ChangeCheck(player, "guohuanghou")
					room:addPlayerMark(player, self:objectName())
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}

guohuanghou:addSkill(danxin)

sgs.LoadTranslationTable{
["guohuanghou"] = "郭皇后",
["#guohuanghou"] = "月華驅霾",
["illustrator:guohuanghou"] = "櫻花閃亂",
["designer:guohuanghou"] = "傑米Y",
["jiaozhao"] = "矯詔",
[":jiaozhao"] = "出牌階段限一次，你可以展示一張手牌並選擇一名與你距離最近的其他角色，令其聲明任意一種基本牌，然後你可以於回合內將之當其聲明的牌使用且你不是以此法轉化的牌的合法目標。",
[":jiaozhao1"] = "出牌階段限一次，你可以展示一張手牌並選擇一名與你距離最近的其他角色，令其聲明任意一種基本牌或非延時類錦囊牌，然後你可以於回合內將之當其聲明的牌使用且你不是以此法轉化的牌的合法目標。",
[":jiaozhao2"] = "出牌階段限一次，你可以展示一張手牌並聲明任意一種基本牌或非延時類錦囊牌，然後你可以於回合內將之當其聲明的牌使用且你不是以此法轉化的牌的合法目標。",
["$jiaozhao1"] = "詔書在此，不得放肆！",
["$jiaozhao2"] = "妾身也是逼不得已，方才出此下策~",
["danxin"] = "殫心",
[":danxin"] = "當你受到傷害後，你可以選擇一項：1.摸一張牌；2.“矯詔”的描述中的“基本牌”改為“基本牌或非延時類錦囊牌”，然後令此選項改為““矯詔”的描述中的“與你距離最近的其他角色”改為“你””。",
[":danxin1"] = "當你受到傷害後，你可以選擇一項：1.摸一張牌；2.“矯詔”的描述中的“與你距離最近的其他角色”改為“你”。",
[":danxin2"] = "當你受到傷害後，你可以摸一張牌。",
["$danxin1"] = "司馬一族，其心可誅！",
["$danxin2"] = "妾身，定為我大魏，鞠躬盡瘁，死而後已~",
["~guohuanghou"] = "陛下，臣妾這就來見你~",
["danxin1"] = "摸一張牌",
["danxin2"] = "“矯詔”的描述中的“基本牌”改為“基本牌或非延時類錦囊牌”",
["danxin3"] = "“矯詔”的描述中的“與你距離最小的其他角色”改為“你”。",
["#choice"] = "%from 選擇了 %arg",
}

--黃皓
huanghao = sgs.General(extension, "huanghao", "shu2", 3, true)

qinqingCard = sgs.CreateSkillCard{
	name = "qinqing",
	filter = function(self, targets, to_select)
		local lord = sgs.Self
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if p:isLord() then
				lord = p
			end
		end
		return (to_select:isNude() or sgs.Self:canDiscard(to_select, "he")) and to_select:inMyAttackRange(lord)
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _, p in pairs(targets) do
				if not p:isNude() then
					local to_throw = room:askForCardChosen(source, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(sgs.Sanguosha:getCard(to_throw), p, source)
				end
			end
			for _, p in pairs(targets) do
				p:drawCards(1, self:objectName())
			end
			local x = 0
			for _, p in pairs(targets) do
				if p:getHandcardNum() > room:getLord():getHandcardNum() then
					x = x + 1
				end
			end
			source:drawCards(x, self:objectName())
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
qinqingVS = sgs.CreateZeroCardViewAsSkill{
	name = "qinqing",
	view_as = function(self, cards)
		return qinqingCard:clone()
	end,
	response_pattern = "@qinqing"
}
qinqing = sgs.CreatePhaseChangeSkill{
	name = "qinqing",
	view_as_skill = qinqingVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if room:getLord() and p:inMyAttackRange(room:getLord()) and (p:objectName() ~= player:objectName()) and (player:canDiscard(p, "he") and not p:isNude()) or p:isNude() then
				players:append(p)
			end
		end
		if not players:isEmpty() and player:getPhase() == sgs.Player_Finish then
			room:askForUseCard(player, "@qinqing", "@qinqing")
		end
	end
}
huanghao:addSkill(qinqing)
huishengCard = sgs.CreateSkillCard{
	name = "huisheng",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self, room, use)
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):getTag("huisheng"):toBool() then
				sgs.Sanguosha:getCard(id):removeTag("huisheng")
			else
				sgs.Sanguosha:getCard(id):setTag("huisheng", sgs.QVariant(true))
			end
		end
	end
}
huishengVS = sgs.CreateViewAsSkill{
	name = "huisheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		if #selected > 0 and #selected < sgs.Self:getMark("huisheng_card_num") and not selected[1]:hasFlag("huisheng") then return not to_select:hasFlag("huisheng") end
		if #selected == 0 then return true end
		return nil
	end,
	response_pattern = "@@huisheng!",
	view_as = function(self, cards)
		local huisheng = huishengCard:clone()
		for _, c in ipairs(cards) do
			huisheng:addSubcard(c)
		end
		--return huisheng
		if #cards == 1 and cards[1]:hasFlag("huisheng") then
			return huisheng
		end
		if #cards == sgs.Self:getMark("huisheng_card_num") then
			return huisheng
		end
	end
}
huisheng = sgs.CreateTriggerSkill{
	name = "huisheng",
	view_as_skill = huishengVS,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:getMark("@huisheng") == 0 and damage.from:objectName() ~= player:objectName() then
			--room:addPlayerMark(damage.from, self:objectName(), damage.damage)
			room:setTag("CurrentDamageStruct", data)
			local cards = room:askForExchange(player, self:objectName(), player:getCards("he"):length(), 1, true, "@huisheng", true)
			local invoke = false
			if cards then
				local huisheng_give_cards_id_list = string.gsub(cards:toString(), "%$", "")
				room:setTag("huisheng_give_cards_id_list", sgs.QVariant(huisheng_give_cards_id_list))
				skill(self, room, player, damage.from:getAI())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
--					if damage.from:getAI() or damage.from:getState() == "robot" then
--						local choice = sgs.IntList()
--						for _, id in sgs.qlist(cards:getSubcards()) do
--							choice:append(id)
--						end
--						if damage.from:getCards("he"):length() >= cards:subcardsLength() then
--							for _, card in sgs.qlist(damage.from:getCards("he")) do
--								choice:append(card:getId())
--							end
--						end
--						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
--						for x = 1, cards:subcardsLength() do
--							room:fillAG(choice, damage.from)
--							local id = room:askForAG(damage.from, choice, false, self:objectName())
--							choice:removeOne(id)
--							for _, card in sgs.qlist(damage.from:getCards("he")) do
--								if card:getId() == id then
--									dummy:addSubcard(card:getId())
--								end
--								for _, i in sgs.qlist(cards:getSubcards()) do
--									choice:removeOne(i)
--								end
--							end
--							for _, i in sgs.qlist(cards:getSubcards()) do
--								if i == id then
--									room:obtainCard(damage.from, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, damage.from:objectName()), room:getCardPlace(id) ~= sgs.Player_PlaceHand)
--									room:clearAG(damage.from)
--									if sgs.GetConfig("huanghao_down", true) then
--										room:addPlayerMark(damage.from, "@huisheng")
--									end
--									return true
--								end
--							end
--							room:clearAG(damage.from)
--						end
--						if dummy:subcardsLength() > 0 then
--							room:throwCard(dummy, damage.from, damage.from)
--						end
--					else
						local ids = sgs.IntList()
						for _, id in sgs.qlist(cards:getSubcards()) do
							sgs.Sanguosha:getCard(id):setTag("huisheng", sgs.QVariant(true))
							ids:append(id)
						end
						room:setPlayerFlag(damage.from, "Fake_Move")
						local _guojia = sgs.SPlayerList()
						_guojia:append(damage.from)
						local move = sgs.CardsMoveStruct(ids, player, damage.from, sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
						local moves = sgs.CardsMoveList()
						moves:append(move)
						room:notifyMoveCards(true, moves, false, _guojia)
						room:notifyMoveCards(false, moves, false, _guojia)
						room:addPlayerMark(damage.from, "huisheng_card_num", ids:length())
						room:setTag("huisheng", sgs.QVariant(0))
						for _, id in sgs.qlist(ids) do
							room:setCardFlag(sgs.Sanguosha:getCard(id), "huisheng")
						end
						room:askForUseCard(damage.from, "@@huisheng!", "@@huisheng!")
						for _, id in sgs.qlist(ids) do
							room:setCardFlag(sgs.Sanguosha:getCard(id), "-huisheng")
						end
						room:setPlayerMark(damage.from, "huisheng", 0)
						local move_to = sgs.CardsMoveStruct(ids, damage.from, player, sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
						local moves_to = sgs.CardsMoveList()
						moves_to:append(move_to)
						room:notifyMoveCards(true, moves_to, false, _guojia)
						room:notifyMoveCards(false, moves_to, false, _guojia)
						room:setPlayerFlag(damage.from, "-Fake_Move")
						for _, id in sgs.qlist(ids) do
							if sgs.Sanguosha:getCard(id):getTag("huisheng"):toBool() then
								sgs.Sanguosha:getCard(id):removeTag("huisheng")
							else
								room:addPlayerMark(damage.from, "@huisheng")
								room:obtainCard(damage.from, sgs.Sanguosha:getCard(id), false)
								return true
							end
						end
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, card in sgs.qlist(damage.from:getCards("he")) do
							if card:getTag("huisheng"):toBool() then
								dummy:addSubcard(card:getId())
								card:removeTag("huisheng")
							end
						end
						room:throwCard(dummy, damage.from, damage.from)
--					end
				end
				room:removeTag("huisheng_give_cards_id_list")
				room:removePlayerMark(player, self:objectName().."engine")
			end
			room:removeTag("CurrentDamageStruct")
			room:setPlayerMark(damage.from, "huisheng_card_num", 0)
		end
		return false
	end
}
huanghao:addSkill(huisheng)

sgs.LoadTranslationTable{
["huanghao"] = "黃皓",
["#huanghao"] = "便闢佞慧",
["illustrator:huanghao"] = "2B鉛筆",
["designer:huanghao"] = "凌天翼",
["qinqing"] = "寢情",
["@qinqing"] = "你可以發動“寢情”",
["~qinqing"] = "選擇若干名角色→點擊確定",
["$qinqing1"] = "陛下勿憂~大將軍危言聳聽~",
["$qinqing2"] = "陛下，莫讓他人知曉此事！",
["huisheng"] = "賄生",
["@huisheng"] = "你可以發動“賄生”，展示至少一張牌",
["@@huisheng!"] = "你可以獲得展示的一張牌，或者棄置展示數量的牌",
["~huisheng"] = "選擇若干張牌→點擊確定",
["$huisheng1"] = "大人~這些錢···夠嗎？",
["$huisheng2"] = "嗯哼哼~~勞煩大人美言幾句",
["~huanghao"] = "魏軍竟然真殺來了！",
[":qinqing"] = "結束階段開始時，你可以選擇至少一名攻擊範圍內有主公的角色，先棄置這些角色各一張牌再摸一張牌，若如此做，你摸X張牌（X為這些角色中手牌比主公多的角色數）。",
[":huisheng"] = "當你受到其他角色造成的傷害時，你可以對其展示至少一張牌，其選擇一項：1.獲得其中一張牌，若如此做，防止此傷害，令其不是“賄生”的合法目標2.棄置等量的牌。",
}

--牌堆的牌量local n = room:getDrawPile():length()
--徐氏
xushi = sgs.General(extension, "xushi", "wu2", "3", false)
--問卦
wenguaCard = sgs.CreateSkillCard{
	name = "wengua_bill",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("wengua") and to_select:getMark("wengua_Play") == 0 and to_select:getMark("bf_huashenxushi") == 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "wenguaengine")
		if source:getMark("wenguaengine") > 0 then
			room:addPlayerMark(targets[1], "wengua_Play")
			local wenguas = {"wengua1", "wengua2"}
			if targets[1]:objectName() ~= source:objectName() then
				room:broadcastSkillInvoke("wengua", 1)
				--以下防周泰奮激
				--room:obtainCard(targets[1], self, false)
				room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
				table.insert(wenguas, 2, "cancel")
			else
				room:broadcastSkillInvoke("wengua", 2)
			end
			local choice = room:askForChoice(targets[1], "wengua", table.concat(wenguas, "+"))
			if choice ~= "cancel" then
				ChoiceLog(targets[1], choice)
				
				--以下預防選置於牌堆頂時可以看見下家摸的牌
				--room:moveCardTo(self, targets[1], sgs.Player_DrawPile)
				if targets[1]:objectName() == source:objectName() then
					local move = sgs.CardsMoveStruct(self:getSubcards():first(), source, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, source:objectName(), self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				else
					local move = sgs.CardsMoveStruct(self:getSubcards():first(), targets[1], nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, targets[1]:objectName(), self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				end
				
				if choice == "wengua1" then
					room:obtainCard(source, room:getDrawPile():last(), false)
					if targets[1]:objectName() ~= source:objectName() then
					room:obtainCard(targets[1], room:getDrawPile():last(), false)
					end
				elseif choice == "wengua2" then
					local card_ids = room:getNCards(1)
					room:askForGuanxing(source, card_ids, sgs.Room_GuanxingDownOnly)
					room:obtainCard(source, room:getDrawPile():first(), false)
					if targets[1]:objectName() ~= source:objectName() then
						room:obtainCard(targets[1], room:getDrawPile():first(), false)
					end
				end
			end
			room:removePlayerMark(source, "wenguaengine")
		end
	end
}
wenguaVS = sgs.CreateOneCardViewAsSkill{
	name = "wengua_bill&",
	filter_pattern = ".",
	view_as = function(self,card)
		local skillcard = wenguaCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return true
	end
}

if not sgs.Sanguosha:getSkill("wengua_bill") then skills:append(wenguaVS) end

wengua = sgs.CreateTriggerSkill{
	name="wengua",
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	on_trigger=function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event==sgs.GameStart then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:hasSkill("wengua_bill") then
					room:attachSkillToPlayer(p,"wengua_bill")
				end
			end
		end
	end
}
--伏誅
fuzhu = sgs.CreatePhaseChangeSkill{
	name = "fuzhu",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			--if p:inMyAttackRange(player) and player:getPhase() == sgs.Player_Finish and player:isMale() and not room:getDrawPile():isEmpty() and room:getDrawPile():length() < p:getHp() * 10 and p:askForSkillInvoke(self:objectName()) then
			if player:getPhase() == sgs.Player_Finish and player:isMale() and not room:getDrawPile():isEmpty() and room:getDrawPile():length() < p:getHp() * 10 and not p:isProhibited(player, slash) and p:askForSkillInvoke(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:doSuperLightbox("xushi","fuzhu")
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local x = 0
					for _,id in sgs.qlist(room:getDrawPile()) do
						local card = sgs.Sanguosha:getCard(id)
						--if card and card:isKindOf("Slash") and p:canSlash(player, card, true) then
						if card and card:isKindOf("Slash") and not p:isProhibited(player, card) and player:isAlive() then
							room:useCard(sgs.CardUseStruct(card, p, player))
							x = x + 1
							--if x == room:alivePlayerCount() then break end
						end
					end
					local ids = sgs.IntList()
					for _,id in sgs.qlist(room:getDrawPile()) do
						ids:append(id)
					end
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcards(ids)
					room:throwCard(dummy, nil, nil)
					if player:isDead() then
						room:broadcastSkillInvoke(self:objectName(), 1)
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end,
	can_trigger=function(self,player)
		return player and player:isAlive()
	end
}
xushi:addSkill(wengua)
xushi:addSkill(fuzhu)
sgs.LoadTranslationTable{
	["xushi"] = "徐氏",
	["#xushi"] = "節義雙全",
	["wengua"] = "問卦",
	["wengua_bill"] = "問卦",
	[":wengua"] = "其他角色/你的出牌階段限一次，其可以交給你一張牌，(若當前回合角色為你，則跳過此步驟)，你可以將此牌/一張牌置於牌堆頂或牌堆底，然後你與其/你從另一端摸一張牌。",
		["fuzhu"] = "伏誅",
		[":fuzhu"] = "一名角色的回合結束時，若牌堆的牌不太於你體力值的十倍，你可以對其使用牌堆裡的所有「殺」，然後洗牌",
	["#wengua"] = "你要交給 %src 一張牌，並發動技能「問卦」嗎？",
	["#wengua_self"] = "妳要使用一張牌發動技能「問卦」嗎？",
	["wengua1"] = "置於牌堆頂",
	["wengua2"] = "置於牌堆底",
	["GETCARD"] = "收入手牌中",
	["$wengua1"] = "卦不能佳，可须异日。",
	["$wengua2"] = "阴阳相生相克，万事周而復始。",
	["$fuzhu1"] = "我连做梦都在等这一天呢！",
	["$fuzhu2"] = "既然来了，就别想走了！",
}
--秦宓
qinmi = sgs.General(extension, "qinmi", "shu2", "3", true)
--專對
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
zhuandui = sgs.CreateTriggerSkill{
	name = "zhuandui",
	events = {sgs.TargetConfirmed,sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from and  use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") and (not player:isKongcheng()) and (not  use.from:isKongcheng()) then
					local _data = sgs.QVariant()
					_data:setValue(use.from)
					if room:askForSkillInvoke(player, "zhuandui1", _data) then
						room:notifySkillInvoked(player, "zhuandui")
						local success
						if player:hasSkill("tianbian") then
							if room:askForSkillInvoke(player, "tianbian", data) then
								room:notifySkillInvoked(player, "tianbian")
								room:broadcastSkillInvoke("tianbian")
								local ids = room:getNCards(1, false)
								local id = ids:at(0)
								local card = sgs.Sanguosha:getCard(id)
								success = player:pindian(use.from, "zhuandui", card)
							else
								success = player:pindian(use.from, "zhuandui", nil)
							end
						else
							success = player:pindian(use.from, "zhuandui", nil)
						end
						if success then
							room:getThread():delay(3000)
							local msg = sgs.LogMessage()
							msg.type = "#zhuandui2"
							msg.from = player
							msg.to:append(use.from)
							msg.arg = "zhuandui"
							msg.card_str = use.card:toString()
							room:sendLog(msg)
							room:broadcastSkillInvoke(self:objectName(), 2)
							local nullified_list = use.nullified_list
							table.insert(nullified_list,player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
						end
					end
				end
			end
		elseif event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if (not p:isKongcheng()) and (not player:isKongcheng()) then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if room:askForSkillInvoke(player, "zhuandui", _data) then
						room:notifySkillInvoked(player, "zhuandui")
						local success
						if player:hasSkill("tianbian") then
							if room:askForSkillInvoke(player, "tianbian", data) then
								room:notifySkillInvoked(player, "tianbian")
								room:broadcastSkillInvoke("tianbian")
								local ids = room:getNCards(1, false)
								local id = ids:at(0)
								local card2 = sgs.Sanguosha:getCard(id)
								success = player:pindian(p, "zhuandui", card2)
							else
								success = player:pindian(p, "zhuandui", nil)
							end
						else
							success = player:pindian(p, "zhuandui", nil)
						end
						if success then
							room:getThread():delay(3000)
							room:broadcastSkillInvoke(self:objectName(), 1)
							local msg = sgs.LogMessage()
							msg.type = "#zhuandui1"
							msg.from = player
							msg.to:append(p)
							msg.arg = "zhuandui"
							msg.card_str = use.card:toString()
							room:sendLog(msg)
							jink_table[index] = 0
						end
					end
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		end
		return false
	end,
}

--天辯
dotanbian = function(player, card, number)
	local room = player:getRoom()
	if card:getSuit() == sgs.Card_Heart then
		local msg = sgs.LogMessage()
		msg.type = "#Tanbian"
		msg.from = player
		msg.to:append(player)
		msg.arg = "tianbian"
		room:sendLog(msg)
		return 13
	else
		return number
	end
	return number
end
tianbian = sgs.CreateTriggerSkill{
	name = "tianbian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PindianVerifying},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			for _,wanglang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do  --同将模式
				if wanglang:objectName() == pindian.from:objectName() then
					pindian.from_number = dotanbian(wanglang, pindian.from_card, pindian.from_number)
				end
				if wanglang:objectName() == pindian.to:objectName() then
					pindian.to_number = dotanbian(wanglang, pindian.to_card, pindian.to_number)
				end
			end
			data:setValue(pindian)
		end
	end
}
--諫征
jianzheng = sgs.CreateTriggerSkill{
	name = "jianzheng",
	events = {sgs.TargetSpecifying},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if use.card:isKindOf("Slash") and not use.to:contains(p) and p:objectName() ~= player:objectName() and not p:isKongcheng() and use.from:inMyAttackRange(p) then
				local card = room:askForCard(p, ".|.|.|hand", "@jianzheng_put:"..use.from:objectName(), data,sgs.Card_MethodNone)
				if card then
					skill(self, room, p, true)
					--room:moveCardTo(card, player, sgs.Player_DrawPile, true)
					--以下預防選置於牌堆頂時可以看見下家摸的牌
					local move = sgs.CardsMoveStruct(card:getEffectiveId(), p, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, p:objectName(), self:objectName(), ""))
					room:moveCardsAtomic(move, true)

					local msg = sgs.LogMessage()
					msg.type = "#Jianzheng"
					msg.from = p
					msg.to = use.to
					msg.arg = self:objectName()
					msg.card_str = use.card:toString()
					
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						use.to = sgs.SPlayerList()
						if not use.card:isBlack() then
							msg.arg2 = "Jianzheng1"
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
						else
							msg.arg2 = "Jianzheng2"
						end
						room:sendLog(msg)

						data:setValue(use)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

qinmi:addSkill(zhuandui)
qinmi:addSkill(tianbian)
qinmi:addSkill(jianzheng)
sgs.LoadTranslationTable{
	["qinmi"] = "秦宓",
	["#qinmi"] = "徹天之舌",
	["zhuandui"] = "專對",
	["zhuandui1"] = "專對",
	["zhuandui2"] = "專對",
	[":zhuandui"] = "當你成為「殺」的目標，或是你使用「殺」指定目標後，你可以與殺的使用者/目標拚點，若你贏，此「殺」對你無效/對方不可用「閃」響應",
	["zhuandui_pile"] = "從牌堆頂亮出一張牌用來拼點",
	["zhuandui_self"] = "自己打出一張牌用來拼點",
	["#zhuandui1"] = "%from 發動技能【%arg】，%to 不可用「閃」響應  %card ",
	["#zhuandui2"] = "%from 發動技能【%arg】， %card 對 %from 無效 ",
	["jianzheng"] = "諫征",
	[":jianzheng"] = "當一名角色成為「殺」的目標時，若你不是目標，你可以將一張手牌置於牌堆頂；然後取消該目標；若該「殺」不為黑色，你成為目標",
	["@jianzheng-put"] = "你可以將一張手牌置於牌堆頂；然後取消該目標",
	["#Jianzheng"] = "%from 發動技能【%arg】，%card 的目標取消了 %to %arg2",
	["Jianzheng1"] = "，且自身成為目標",
	["Jianzheng2"] = "",
	["tianbian"] = "天辯",
	[":tianbian"] = "當你於「專對」拼點時，你可以改為亮出牌堆頂的一張牌拼點；鎖定技，你的紅桃牌於拼點中點數視為K",
	["#Tanbian"] = "%from 的技能【%arg】被觸發，拼點牌視為K點",
	["$jianzheng1"] = "天时不当，必难取胜。",
	["$jianzheng2"] = "且慢！此阵打不得！",
	["$zhuandui1"] = "你已无话可说了吧！",
	["$zhuandui2"] = "黄口小儿，也敢来班门弄斧？",
	["$tianbian1"] = "当今天子为刘，天亦姓刘。",
	["$tianbian2"] = "阁下知其然，而未知其所以然。",
}
--薛琮  
xuezong = sgs.General(extension, "xuezong", "wu2", "3", true)
--[[
--戒訓
jiexun = sgs.CreateTriggerSkill{
	name = "jiexun" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ==  sgs.Player_Finish then 
			local count = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, jcard in sgs.qlist(p:getJudgingArea()) do
					if jcard:getSuit() == sgs.Card_Diamond then
						count = count + 1
					end
				end
				for _, jcard in sgs.qlist(p:getEquips()) do
					if jcard:getSuit() == sgs.Card_Diamond then
						count = count + 1
					end
				end
			end
			local choose = room:askForPlayerChosen(player, room:getOtherPlayers(player), "jiexun", "@jiexun-card:::" .. tostring(count), true)
			if choose then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:drawCards(choose, count)
				local dc = player:getMark("@jiexun")
				local hc = choose:getHandcardNum()
				local ec = choose:getEquips():length()	
				local n = math.min((hc+ec) , dc)
				player:gainMark("@jiexun")
				if n > 0 then
					room:askForDiscard(choose, "jiexun", n, n, false, true)
					if n == hc+ec then
						room:detachSkillFromPlayer(player, "jiexun")
						room:setPlayerMark(player,"@funan",1)
					end
				end
			end
		end
	end,
}
--赴難
funan = sgs.CreateTriggerSkill{
	name = "funan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponded,sgs.CardFinished},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local s = room:findPlayerBySkillName("funan")
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if s:objectName() == player:objectName() then
				room:setCardFlag(use.card:getEffectiveId(), "use_card")
				room:setPlayerFlag(s,"use_by_player")
			end
		elseif event == sgs.CardResponded then
			local res = data:toCardResponse()			
			local card_star = data:toCardResponse().m_card			
			if not card_star:isKindOf("Jink") and not card_star:isKindOf("Nullification") then return false end
			if res.m_isUse then	
				if s and s:hasFlag("use_by_player") and s:objectName() ~= player:objectName() and card_star then
					if room:askForSkillInvoke(s, "funan", data) then
						room:notifySkillInvoked(s, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:moveCardTo(card_star, s, sgs.Player_PlaceHand, false)
						room:setPlayerFlag(player,"respond_by_player")	
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if s:hasFlag("use_by_player") and use.card:hasFlag("use_card") then
				local t
				for _, p in sgs.qlist(room:getOtherPlayers(s)) do
					if p:hasFlag("respond_by_player") then
						t = p
					end
				end
				if t then
					if s:getMark("@funan") == 0 then
						room:moveCardTo(use.card, t, sgs.Player_PlaceHand, false)
						room:setCardFlag(use.card:getEffectiveId(), "-respond_card")
					end	
					room:setPlayerFlag(s,"-use_by_player")
					room:setPlayerFlag(t,"-respond_by_player")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
]]--

--card為使用的牌 ob為響應的牌 to為響應角色 
funan = sgs.CreateTriggerSkill{
	name = "funan",
	events = {sgs.CardResponded, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local card
			local to
			local ob
			if event == sgs.CardUsed then
				ob = data:toCardUse().card
				local use = data:toCardUse()
				if data:toCardUse() and data:toCardUse().from then
					room:setPlayerMark(p, data:toCardUse().from:objectName().."_xuezong-Clear", 1)
					room:setTag("funanData", data)
				end
				if use.card:isKindOf("Nullification") then
					local older_data = room:getTag("funanData")
					local older_use = older_data:toCardUse()

					card = older_use.card
					ob = use.card
					to = older_use.from

				end
			else
				local res = data:toCardResponse()
					local older_data = room:getTag("funanData")
					local older_use = older_data:toCardUse()

					card = older_use.card
					ob = res.m_card
					to = older_use.from
			end
			local all_place_table = true
			if card then
				for _, id in sgs.qlist(card:getSubcards()) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
					end
				end
				--if all_place_table and (event ~= sgs.CardResponded or p:objectName() == to:objectName()) and player:objectName() ~= p:objectName() and room:askForSkillInvoke(p, self:objectName(), data) then
				if all_place_table and (event ~= sgs.CardResponded or (to and p:objectName() == to:objectName())) and player:objectName() ~= p:objectName() and p:getMark(p:objectName().."_xuezong-Clear") > 0 and room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						if p:getMark("@funan") == 0 then
							player:obtainCard(card)

							for _,c in sgs.qlist(card:getSubcards()) do

								room:addPlayerMark(player, self:objectName()..c.."-Clear")
								room:setPlayerCardLimitation(player, "use,response", sgs.Sanguosha:getCard(c):toString(), false)

							end
						end
						p:obtainCard(ob)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
				room:setPlayerMark(p, p:objectName().."_xuezong-Clear", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


jiexun = sgs.CreateTriggerSkill{
	name = "jiexun",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local n = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, card in sgs.qlist(p:getCards("ej")) do
				if card:getSuit() == sgs.Card_Diamond then
				n = n + 1
				end
			end
		end
		if event == sgs.EventPhaseStart and RIGHT(self, player) and n >= 0 and player:getPhase() == sgs.Player_Finish then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "jiexun-invoke:::" .. tostring(n), true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					target:drawCards(n, self:objectName())
					local all = false
					if player:getMark("@jiexun") > 0 then
						local ids = sgs.IntList()
						for _, c in sgs.qlist(target:getCards("he")) do
							if target:canDiscard(target, c:getEffectiveId()) then
								ids:append(c:getEffectiveId())
							end
						end
						all = ids:length() == target:getCards("he"):length() and player:getMark("@jiexun") >= target:getCards("he"):length()
						--player:speak(ids:length())
						--player:speak(target:getCards("he"):length())
						room:askForDiscard(target, self:objectName(), player:getMark("@jiexun"), player:getMark("@jiexun"), false, true)
					end
					if all then
						room:getThread():delay(3000)
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:detachSkillFromPlayer(player, self:objectName())
						sgs.Sanguosha:addTranslationEntry(":funan", ""..string.gsub(sgs.Sanguosha:translate(":funan"), sgs.Sanguosha:translate(":funan"), sgs.Sanguosha:translate(":funan1")))
						----ChangeCheck(player, "xuezong")
						room:addPlayerMark(player, "@funan")
					end
					room:addPlayerMark(player, "@jiexun")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}


xuezong:addSkill(jiexun)
xuezong:addSkill(funan)
sgs.LoadTranslationTable{
	["xuezong"] = "薛琮",
	["#xuezong"] = "彬彬之玊",

	["funan"] = "復難",
	[":funan"] = "當其他角色使用/打出牌響應你使用的牌時，你可以先令其獲得你使用的牌且其於此回合內不能使用或打出之再令你獲得其使用/打出的牌。",
	[":funan1"] = "當其他角色使用/打出牌響應你使用的牌時，你可以獲得其使用/打出的牌。",
	["$funan1"] = "禮尚往來，乃君子風範。",
	["$funan2"] = "以子之矛，攻子之盾。",

	["jiexun"] = "戒訓",
	[":jiexun"] = "結束階段，你可令一名其他角色摸等同於場上方塊牌數的牌，然後棄置 X 張牌 ( X 為此前該技能發動過的次數)。若其因此法棄置了所有牌，則你失去〖誡訓〗，然後你發動〖復難〗時，無須令其獲得你使用的牌。",
	["jiexun-invoke"] = "你可以令該角色摸%arg張牌，然後棄置X 張牌 ( X 為此前該技能發動過的次數)。若其因此法棄置了所有牌，則你失去〖誡訓〗。",
	["@jiexun"] = "誡訓",
	["$jiexun1"] = "帝王应以社稷为重，以大观为主。",
	["$jiexun2"] = "吾冒昧进谏，只求陛下思虑。",
	["~xuezong"] = "尔等……竟做如此有辱斯文之事……",
}
--蔡邕
caiyong = sgs.General(extension, "caiyong", "qun2", "3", true)
--辟撰
pizhuan = sgs.CreateTriggerSkill{
	name = "pizhuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill then
					if use.card:getSuit() == sgs.Card_Spade and player:getPile("books"):length() < 4 then
						if room:askForSkillInvoke(player, "pizhuan", data) then 
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							local ids = room:getNCards(1, false)
							local id = ids:at(0)
							local card = sgs.Sanguosha:getCard(id)
							player:addToPile("books", card)
						end
					end
			end					
		end		
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and use.card:getTypeId() ~= sgs.Card_TypeSkill then
				if use.card:getSuit() == sgs.Card_Spade and player:getPile("books"):length() < 4  then
					if room:askForSkillInvoke(player, "pizhuan", data) then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						local ids = room:getNCards(1, false)
						local id = ids:at(0)
						local card = sgs.Sanguosha:getCard(id)
						player:addToPile("books", card)
					end
				end
			end
			return false
		end
		return false
	end,
}
pizhuanMax = sgs.CreateMaxCardsSkill{
	name = "#pizhuan", 
	extra_func = function(self, target)
		if target:hasSkill("pizhuan") then
			return target:getPile("books"):length()
		end
	end
}
--通博
tongboCard = sgs.CreateSkillCard{
	name = "tongbo",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local to_handcard = sgs.IntList()
		local to_pile = sgs.IntList()
		local set = source:getPile("books")
		for _,id in sgs.qlist(self:getSubcards()) do
			set:append(id)
		end
		for _,id in sgs.qlist(set) do
			if not self:getSubcards():contains(id) then
				to_handcard:append(id)
			elseif not source:getPile("books"):contains(id) then
				to_pile:append(id)
			end
		end
		--assert(to_handcard:length() == to_pile:length())
		if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then return end
		room:notifySkillInvoked(source, "tongbo")
		source:addToPile("books", to_pile, false)
		local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, id in sgs.qlist(to_handcard) do
			to_handcard_x:addSubcard(id)
		end
		room:obtainCard(source, to_handcard_x, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName(), self:objectName(), ""))
		local suits = {}
		for _,id in sgs.qlist(source:getPile("books")) do
			if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuit()) then
				table.insert(suits, sgs.Sanguosha:getCard(id):getSuit())
			end
		end
		if #suits == 4 then
			while not source:getPile("books"):isEmpty() do
				room:setPlayerFlag(source, "Fake_Move")
				local ids = source:getPile("books")
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(ids)
				source:obtainCard(dummy)
				room:setPlayerFlag(source, "-Fake_Move")
				while room:askForYiji(source, ids, self:objectName(), false, true, false, -1, room:getOtherPlayers(source)) do
					if ids:isEmpty() then break end
				end
			end
		end
	end
}
tongboVS = sgs.CreateViewAsSkill{
	name = "tongbo",
	n = 4,
	response_pattern = "@@tongbo",
	expand_pile = "books",
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not sgs.Sanguosha:matchExpPattern(".|.|.|books", sgs.Self, to_select)
		end
		if #selected < sgs.Self:getPile("books"):length() then
			--return not to_select:isEquipped()
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getPile("books"):length() and #cards ~= 0 then
			local c = tongboCard:clone()
			for _,card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		end
		return nil
	end
}
tongbo = sgs.CreateTriggerSkill{
	name = "tongbo",
	events = {sgs.EventPhaseEnd},
	view_as_skill = tongboVS,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Draw and not player:getPile("books"):isEmpty() then
			room:askForUseCard(player, "@@tongbo", "@tongbo", -1, sgs.Card_MethodNone)
		end
		return false
	end
}

caiyong:addSkill(pizhuan)
caiyong:addSkill(pizhuanMax)
caiyong:addSkill(tongbo)
extension:insertRelatedSkills("pizhuan","#pizhuan")

sgs.LoadTranslationTable{
	["caiyong"] = "蔡邕",
	["#caiyong"] = "大鴻儒",
	["pizhuan"] = "辟撰",
	["tongbo"] = "通博",
	["books"] = "書",
	[":pizhuan"] = "當你使用黑桃牌後，或你成為其他角色使用黑桃牌的目標後，你可以將牌堆頂的一張牌置於武將牌上，稱為“書”；你至多擁有四張“書”，你的手牌上限+X ( X 為“書”的數量)。",
	[":tongbo"] = "摸牌階段結束後，你可以用任意張牌替換等量的“書”。然後若你的“書”包含四種花色，你將所有“書”交給任意名其他角色。",

	["@tongbo"] = "你可以發動“通博”",
	["~tongbo"] = "選擇欲放置至武將牌上的牌(「書」) -> 點擊「確定」",
	["$pizhuan1"] = "无墨不成书，无时不成才。",
	["$pizhuan2"] = "笔可抒情，亦可诛心！",
	["$tongbo1"] = "读万卷书，行万里路。",
	["$tongbo2"] = "博学而不穷，笃行而不倦。",
}
--嵇康
jikang = sgs.General(extension, "jikang", "wei2", "3", true)
--清弦
function useEquip(room, player)
	--local equips = sgs.CardList()
	local equips = {}
	for _,id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
			--equips:append(sgs.Sanguosha:getCard(id))
			table.insert(equips, sgs.Sanguosha:getCard(id))
		end
	end
	--if not equips:isEmpty() then
	if #equips > 0 then
		--local card = equips:at(math.random(0, equips:length() - 1))
		local card = equips[math.random(1, #equips)]
		local equip_index = card:getRealCard():toEquipCard():location()
		if ((card:isKindOf("Weapon") and player:getMark("@AbolishWeapon") == 0) or
					(card:isKindOf("Armor") and player:getMark("@AbolishArmor") == 0) or
					(card:isKindOf("DefensiveHorse") and player:getMark("@AbolishHorse") == 0 ) or
					(card:isKindOf("OffensiveHorse") and player:getMark("@AbolishHorse") == 0) or
					(card:isKindOf("Treasure") and player:getMark("@AbolishTreasure") == 0)) then 
			room:useCard(sgs.CardUseStruct(card, player, player))
			return card
		end
	end
	return nil
end
function throwEquip(room, player)
--	local invoke = ".|.|.|equipped"
--	for _, card in sgs.qlist(player:getHandcards()) do
--		if card:isKindOf("EquipCard") then
--			invoke = ".|.|.|equipped!"
--		end
--		break
--	end
--	local card = room:askForCard(player, invoke, "@throw_E", sgs.QVariant(), sgs.Card_MethodNone)
	local equip_cards = {}
	for _, card in sgs.qlist(player:getCards("he")) do
		if card:isKindOf("EquipCard") then
			table.insert(equip_cards, card)
		end
	end
	if #equip_cards > 0 then
		local card = room:askForCard(player, ".Equip!", "@throw_E", sgs.QVariant(), sgs.Card_MethodNone)
		--if not card then room:showAllCards(player) end
		return card
	end
end

qingxian = sgs.CreateTriggerSkill{
	name = "qingxian",
	events = {sgs.Damaged, sgs.HpRecover},
	on_trigger = function(self, event, player, data, room)
		--if room:getCurrentDyingPlayer() then return false end
		local target
		local choices = {}
		if event == sgs.Damaged then
			target = data:toDamage().from
			table.insert(choices, "cancel")
		end
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHp() > 0 or p:getLostHp() > 0 then
				players:append(p)
			end
		end
		if event == sgs.HpRecover and not players:isEmpty() and player:getHp() > 0 then
			target = room:askForPlayerChosen(player, players, self:objectName(), "@qingxian-invoke", true, true)
		end
		if target then
			if target:getHp() > 0 then
				table.insert(choices, "qingxian1")
			end
			if target:getLostHp() > 0 then
				table.insert(choices, "qingxian2")
			end
			target:setFlags("QingxianTarget")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
			target:setFlags("-QingxianTarget")
			if choice ~= "cancel" then
				lazy(self, room, player, choice, true)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					if choice == "qingxian1" then
						room:loseHp(target)
						if target:isAlive() then
							local card = useEquip(room, target)
							if card and card:getSuit() == sgs.Card_Club then
								player:drawCards(1, self:objectName())
							end
						end
					else
						room:recover(target, sgs.RecoverStruct(player))
						local card = throwEquip(room, target)
						if card then room:throwCard(card, target, nil) end
						if card and card:getSuit() == sgs.Card_Club then
							player:drawCards(1, self:objectName())
						end
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}
--清弦殘譜
--【絕響】當你死亡後，你可以令一名角色隨機獲得“清弦殘譜”/以下其中一個技能，然後直到其下回合開始，其不能被選擇為其他角色使用梅花牌的目標。
juexiang = sgs.CreateTriggerSkill{
	name = "juexiang",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if data:toDeath().who:objectName() == player:objectName() then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "juexiang-invoke", true, true)
			if target then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					local skills = {"jixian", "liexian", "rouxian", "hexian"}
					room:handleAcquireDetachSkills(target, skills[math.random(1, #skills)])
					room:addPlayerMark(target, "juexiang_time")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

jixian_mark_clear = sgs.CreateTriggerSkill{
	name = "jixian_mark_clear",
	global = true,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:getMark("juexiang_time") > 0 then
				room:setPlayerMark(player, "juexiang_time", 0)
			end
		end
		return false
	end
}

juexiangPS = sgs.CreateProhibitSkill{
	name = "juexiangPS" ,
	frequency = sgs.Skill_Compulsory ,
	is_prohibited = function(self, from, to, card)
		return to:getMark("juexiang_time") > 0 and card:getSuit() == sgs.Card_Club
	end
}

if not sgs.Sanguosha:getSkill("jixian_mark_clear") then skills:append(jixian_mark_clear) end
if not sgs.Sanguosha:getSkill("juexiangPS") then skills:append(juexiangPS) end

--【激弦】當你受到傷害後，你可以令傷害來源失去1點體力，隨機使用一張裝備。
jixian = sgs.CreateMasochismSkill{
	name = "jixian",
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		if room:getCurrentDyingPlayer() then return false end
		local data = sgs.QVariant()
		data:setValue(damage.from)
		if damage.from and damage.from:isAlive() and damage.from:getHp() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:doAnimate(1, player:objectName(), damage.from:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:loseHp(damage.from)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				if damage.from:isAlive() then
					useEquip(room, damage.from)
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}

--【烈弦】當你回復體力後，你可以令一名其他角色失去1點體力，隨機使用一張裝備。
liexian = sgs.CreateTriggerSkill{
	name = "liexian",
	events = {sgs.HpRecover},
	on_trigger = function(self, event, player, data, room)
		--if room:getCurrentDyingPlayer() then return false end
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHp() > 0 then
				players:append(p)
			end
		end
		if not players:isEmpty() and player:getHp() > 0 then
			local target = room:askForPlayerChosen(player, players, self:objectName(), "liexian-invoke", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(target)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					if target:isAlive() then
						useEquip(room, target)
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}
--【柔弦】當你受到傷害後，你可以令傷害來源回復1點體力，棄置一張裝備。
rouxian = sgs.CreateMasochismSkill{
	name = "rouxian",
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		if room:getCurrentDyingPlayer() then return false end
		local data = sgs.QVariant()
		data:setValue(damage.from)
		if damage.from and damage.from:isAlive() and damage.from:getLostHp() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:doAnimate(1, player:objectName(), damage.from:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:recover(damage.from, sgs.RecoverStruct(player))
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				--throwEquip(room, damage.from)
				local card = throwEquip(room, damage.from)
				if card then room:throwCard(card, damage.from, nil) end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}
--【和弦】當你回復體力後，你可以令一名其他角色回復1點體力，棄置一張裝備。

hexian = sgs.CreateTriggerSkill{
	name = "hexian",
	events = {sgs.HpRecover},
	on_trigger = function(self, event, player, data, room)
		--if room:getCurrentDyingPlayer() then return false end
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			--if p:getHp() > 0 then
			if p:getLostHp() > 0 then
				players:append(p)
			end
		end
		if not players:isEmpty() and player:getHp() > 0 then
			local target = room:askForPlayerChosen(player, players, self:objectName(), "hexian-invoke", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:recover(target, sgs.RecoverStruct(player))
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--throwEquip(room, target)
					local card = throwEquip(room, target)
					if card then room:throwCard(card, target, nil) end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}

jikang:addSkill(qingxian)
jikang:addSkill(juexiang)

if not sgs.Sanguosha:getSkill("jixian") then skills:append(jixian) end
if not sgs.Sanguosha:getSkill("liexian") then skills:append(liexian) end
if not sgs.Sanguosha:getSkill("rouxian") then skills:append(rouxian) end
if not sgs.Sanguosha:getSkill("hexian") then skills:append(hexian) end

jikang:addRelateSkill("jixian")
jikang:addRelateSkill("liexian")
jikang:addRelateSkill("rouxian")
jikang:addRelateSkill("hexian")

sgs.LoadTranslationTable{
	["jikang"] = "嵇康",
	["#jikang"] = "峻峰孤松",
	["qingxian"] = "清弦",
	[":qingxian"] = "當你受到傷害/回復體力後，你可以令傷害來源/一名其他角色執行一項：a. 失去 1 點體力，隨機使用一張裝備牌；b. 回復 1 點體力，棄置一張裝備牌。若其以此法使用或棄置的牌花色為梅花，你摸一張牌。",
	["qingxian1"] = "令其失去 1 點體力，隨機使用一張裝備牌",
	["qingxian2"] = "令其恢復一點體力，棄置一張裝備牌",
	["qingxianD1"] = "令傷害來源恢復一點體力，棄置一張裝備牌",
	["qingxianD2"] = "令傷害來源失去 1 點體力，隨機使用一張裝備牌",
	["@qingxian-invoke"] = "請選擇一名角色執行「清弦」",
	["juexiang"] = "絕響",
	[":juexiang"] = "當你死亡後，你可以令一名角色隨機獲得“清弦殘譜”/以下其中一個技能，然後直到其下回合開始，其不能被選擇為其他角色使用梅花牌的目標。",
	["jixian"] = "激弦",
	["liexian"] = "烈弦",
	["rouxian"] = "柔弦",
	["hexian"] = "和弦",
	[":jixian"] = "當你受到傷害後，你可以令傷害來源失去1點體力，隨機使用一張裝備。",
	[":liexian"] = "當你回復體力後，你可以令一名其他角色失去1點體力，隨機使用一張裝備。",
	[":rouxian"] = "當你受到傷害後，你可以令傷害來源回復1點體力，棄置一張裝備。",
	[":hexian"] = "當你回復體力後，你可以令一名其他角色回復1點體力，棄置一張裝備。",

	["$qingxian1"] = "撫琴撥弦，悠然自得。",
	["$qingxian2"] = "寄情於琴，和於天地。",
	["$juexiang1"] = "此曲，不能絕矣。",
	["$juexiang2"] = "一曲琴音，為我送別。",
	["$jixian1"] = "一彈一撥，鏗鏘有力！",
	["$liexian1"] = "一壺烈雲燒，一曲人皆醉。",
	["$rouxian1"] = "君子以琴會友，以瑟輔仁。",
	["$hexian1"] = "悠悠琴音，人人自醉。",
	["~jikang"] = "多少遺恨俱隨琴音去……",
		["@throw_E"] = "請棄置一張裝備牌",

}
--辛憲英
xinxianying = sgs.General(extension,"xinxianying","wei2","3",false)
--忠鑑
function CDM(room, player, a, b)
	local x = math.min(player:getMark(a), player:getMark(b))
	room:removePlayerMark(player, a, x)
	room:removePlayerMark(player, b, x)
end

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

zhongjianCard = sgs.CreateSkillCard{
	name = "zhongjian",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHandcardNum() > 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:showCard(source, self:getSubcards():first())
			local ids = getIntList(targets[1]:getHandcards())
			local color, num = false, false
			--local n = targets[1]:getHandcardNum() - targets[1]:getHp()
			--n = math.max(n,1)
			local n = math.min(targets[1]:getHandcardNum(),targets[1]:getHp())
			for i = 1, n do
				local id = ids:at(math.random(0, ids:length() - 1))
				room:showCard(targets[1], id)
				if GetColor(sgs.Sanguosha:getCard(id)) == GetColor(sgs.Sanguosha:getCard(self:getSubcards():first())) then color = true end
				if sgs.Sanguosha:getCard(id):getNumber() == sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() then num = true end
				ids:removeOne(id)
			end
			if color then
				--[[
				local choices = {"danxin1"}
				if source:canDiscard(targets[1], "he") then
					table.insert(choices, "zhongjian1")
				end
				local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
				ChoiceLog(source, choice)
				if choice == "danxin1" then
					source:drawCards(1, self:objectName())
				else
					local throw = room:askForCardChosen(source, targets[1], "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(sgs.Sanguosha:getCard(throw), targets[1], source)
				end
				]]--

				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(source)) do
					if source:canDiscard(p, "he") then _targets:append(p) end
				end
				if not _targets:isEmpty() then
					local to_discard = room:askForPlayerChosen(source, _targets, "zhongjian", "@zhongjian-discard", true)
					if to_discard then
						room:doAnimate(1, source:objectName(), to_discard:objectName())
						room:throwCard(room:askForCardChosen(source, to_discard, "he", "zhongjian", false, sgs.Card_MethodDiscard), to_discard, source)
					else
						source:drawCards(1)
					end
				else
					source:drawCards(1)
				end
			end
			if num then
				room:addPlayerMark(source, "zhongjian_Play")
				sgs.Sanguosha:addTranslationEntry(":zhongjian", ""..string.gsub(sgs.Sanguosha:translate(":zhongjian"), sgs.Sanguosha:translate(":zhongjian"), sgs.Sanguosha:translate(":zhongjian1")))
				--ChangeCheck(source, "xinxianying")
			end
			if not num and not color and source:getMaxCards() > 0 then
				room:addPlayerMark(source, "@zhongjian")
				CDM(room, source, "@Maxcards", "@zhongjian")
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
zhongjian = sgs.CreateOneCardViewAsSkill{
	name = "zhongjian",
	filter_pattern = ".",
	view_as = function(self, card)
		local skillcard = zhongjianCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		if player:getMark("zhongjian_Play") > 0 then
			return player:usedTimes("#zhongjian") < 2
		end
		return not player:hasUsed("#zhongjian")
	end
}
--才識
caishi = sgs.CreatePhaseChangeSkill{
	name = "caishi",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				--local choices = {"caishi1+cancel"}
				local choices = {"caishi1"}
				if player:isWounded() then
					table.insert(choices, 1, "caishi2")
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice ~= "cancel" then
					lazy(self, room, player, choice)
					if choice == "caishi1" then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:addPlayerMark(player, "@Maxcards")
						CDM(room, player, "@Maxcards", "@zhongjian")
						--for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						--	room:addPlayerMark(p, "caishi-Clear")
						--end
					else
						room:broadcastSkillInvoke(self:objectName(), 1)
						room:recover(player, sgs.RecoverStruct(player))
						room:addPlayerMark(player, "caishi-Clear")
					end
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
caishiPS = sgs.CreateProhibitSkill{
	name = "#caishiPS" ,
	is_prohibited = function(self, from, to, card)
		return (from:hasSkill("caishi") and (to:getMark("caishi-Clear") > 0) and (not card:isKindOf("SkillCard")))
	end
}


xinxianying:addSkill(zhongjian)
xinxianying:addSkill(caishi)
xinxianying:addSkill(caishiPS)

extension:insertRelatedSkills("caishi","#caishiPS")

sgs.LoadTranslationTable{
	["xinxianying"] = "辛憲英",
	["#xinxianying"] = "名門智女",
	["zhongjian"] = "忠鑑",
	--[":zhongjian"] = "出牌階段限一次，你可以展示一張手牌，然後展示手牌數大於體力值的一名其他角色X張手牌（X為其手牌數和體力值之差）。若以此法展示的牌與你展示的牌：有顏色相同的，你摸一張牌或棄置其一張牌；有點數相同的，本回合此技能改為“出牌階段限兩次”；均不同，你的手牌上限-1。",
	[":zhongjian"] = "出牌階段限一次，你可以展示一張手牌，然後展示手牌數大於體力值的一名其他角色X張手牌（X為其體力值）。若以此法展示的牌與你展示的牌：有顏色相同的，你摸一張牌或棄置一名角色的一張牌；有點數相同的，本回合此技能改為“出牌階段限兩次”；均不同，你的手牌上限-1。",
	[":zhongjian1"] = "出牌階段限兩次，你可以展示一張手牌，然後展示手牌數大於體力值的一名其他角色X張手牌（X為其體力值）。若以此法展示的牌與你展示的牌：有顏色相同的，你摸一張牌或棄置一名角色的一張牌；有點數相同的，本回合此技能改為“出牌階段限兩次”；均不同，你的手牌上限-1。",
	["caishi"] = "才識",
	--[":caishi"] = "摸牌階段開始時，你可以選擇一項：1.手牌上限+1，然後本回合你的牌不能對其他角色使用；2.回復1點體力，然後本回合你的牌不能對自己使用。",
	[":caishi"] = "摸牌階段開始時，你可以選擇一項：1.手牌上限+1；2.回復1點體力，然後本回合你的牌不能對自己使用。",
	--["caishi1"] = "手牌上限+1，然後本回合你的牌不能對其他角色使用",
	["caishi1"] = "手牌上限+1",
	["caishi2"] = "回復1點體力，然後本回合你的牌不能對自己使用",
	["zhongjian1"] = "棄置其一張牌",
	["$zhongjian1"] = "濁世風雲變幻，當以明眸洞察。",
	["$zhongjian2"] = "心中自有明鏡，可鑒奸佞忠良。",
	["$caishi1"] = "清識難尚，至德可師。",
	["$caishi2"] = "知書達禮，博古通今。",
	["~xinxianying"] = "吾一生明鑒，竟錯看於你……",
	["@zhongjian-discard"] = "請選擇一名角色，妳棄置其一張牌，否則你摸一張牌",
}
--吳莧
wuxian = sgs.General(extension,"wuxian","shu2","3",false)
--福棉
ol_fumian = sgs.CreatePhaseChangeSkill{
	name = "ol_fumian",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if (player:getMark("ol_fummian1_manmanlai") == 2 and player:getMark("ol_fummian2_manmanlai") == 1) or (player:getMark("ol_fummian2_manmanlai") == 2 and player:getMark("ol_fummian1_manmanlai") == 1) then
				room:setPlayerMark(player, "ol_fummian1_manmanlai", 0)
				room:setPlayerMark(player, "ol_fummian2_manmanlai", 0)
			end
			local choice = room:askForChoice(player, self:objectName(), "ol_fumian1+ol_fumian2+cancel")
			if choice ~= "cancel" then
				lazy(self, room, player, choice, true)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerMark(player, choice.."_manmanlai", 3)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}

ol_fumianTargetMod = sgs.CreateTargetModSkill{
	name = "#ol_fumian-target" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if from:hasFlag("fumiantm") then
			return 1000
		end
		return 0
	end
}

ol_fumianStart = sgs.CreateTriggerSkill{
	name = "ol_fumianStart" ,
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local x = 0
			if player:getMark("fumian1_manmanlai") > 0 and player:getMark("fumian1now_manmanlai") == 0 then
				x = x + 1
				if player:getMark("@fumian2") > 0 then
					x = x + 1
				end
			end
			if player:getMark("ol_fumian1_manmanlai") == 3 then
				x = x + 1
				if player:getMark("ol_fumian2_manmanlai") == 2 then
					x = x + 1
				end
			end
			local count = data:toInt() + x
			data:setValue(count)
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("ol_fumianStart") then skills:append(ol_fumianStart) end

--怠宴
ol_daiyan = sgs.CreateTriggerSkill{
	name = "ol_daiyan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local phase = change.to
		if phase == sgs.Player_Finish then
			--if room:askForSkillInvoke(player, "ol_daiyan", data) then
				local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "ol_daiyan", "@ol_daiyan-choose", true)
				if s then
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if card:isKindOf("BasicCard") and card:getSuit() == sgs.Card_Heart then
								DPHeart:append(id)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
						local get_card = sgs.Sanguosha:getCard(get_id)
						room:obtainCard(s, get_card,true)
						if s:getMark("@ol_lazy") == 1 then
							room:loseHp(s)
						end
					end
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("@ol_lazy") == 1 then 
						room:setPlayerMark(p, "@ol_lazy", 0)
					end
				end
				if s then
					room:setPlayerMark(s, "@ol_lazy", 1)
				end
			--end	
		end
	end
}

wuxian:addSkill(ol_fumian)
wuxian:addSkill(ol_fumianTargetMod)
wuxian:addSkill(ol_daiyan)
extension:insertRelatedSkills("ol_fumian","#ol_fumian-target")

sgs.LoadTranslationTable{
	["wuxian"] = "吳莧",
	["#wuxian"] = "穆皇后",
	["ol_fumian"] = "福綿",
	[":ol_fumian"] = "準備階段，你可以選擇一項：1.摸牌階段多摸一張牌；2.使用紅色牌可以多選一個目標，若你下回合選擇另一項，則該選項數值+1並復原此技能。",
	["ol_fumian1"] = "摸牌階段多摸一張牌",
	["ol_fumian2"] = "使用紅色牌可以多選一個目標",
	["ol_fumian1Plus"] = "摸牌階段多摸兩張牌",
	["ol_fumian2Plus"] = "使用紅色牌可以多選兩個目標",
	["ol_daiyan"]= "怠宴",
	[":ol_daiyan"] = "結束階段，你可以令一名其他角色從牌堆中獲得一張紅桃基本牌，然後若其於上回合成為過該技能目標，其失去1點體力",
	["@ol_daiyan-choose"] = "令一名其他角色從牌堆中獲得一張基本牌",
	["~ol_fumian"] = "選擇一名欲增加的角色 -> 點擊「確定」",

	["@ol_fumian2"] = "令一名角色成為 %src 的額外目標",
	["@ol_fumian2Plus"] = "令兩名角色成為 %src 的額外目標",

	["#Fumian"] = "%from 發動技能 “<font color=\"yellow\"><b>福綿</b></font>”， %arg 額外增加了目標 %to",
}

--曹節
caojie = sgs.General(extension, "caojie", "qun2", 3, false)

shouxi = sgs.CreateTriggerSkill{
	name = "shouxi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashEffected, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.card and use.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
				local ban_list,choices = {},sgs.IntList()
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(ban_list, TrueName(card))) then
						--if (card:isKindOf("BasicCard") or card:isNDTrick()) then
						if (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) then
							table.insert(ban_list, TrueName(card))
						end
					end
				end
				local announce_table = {}
				for _,name in ipairs(ban_list) do
					for i = 0, 10000 do
						local card = sgs.Sanguosha:getEngineCard(i)
						if card == nil then break end
							--card:getSuit() == 6 和 card:getNumber() == 14 中沒有延時錦囊和其他模式的錦囊牌
--							if card:objectName() == name and (card:isKindOf("BasicCard") or card:isNDTrick()) and card:getSuit() == 6 and card:getNumber() == 14 and player:getMark(self:objectName()..name) == 0 then
--								choices:append(i)
--							end
						if card:objectName() == name and (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) and player:getMark(self:objectName()..name) == 0 and player:getMark("AG_BANCard"..name) == 0  then
							if not table.contains(announce_table, TrueName(card)) then
								table.insert(announce_table, TrueName(card))
								choices:append(i)
							end
						end
					end
				end
				room:fillAG(choices)
				local card_id = room:askForAG(player, choices, true, self:objectName())
				if card_id ~= -1 then
					room:broadcastSkillInvoke(self:objectName())
					ChoiceLog(player, sgs.Sanguosha:getCard(card_id):objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:addPlayerMark(player, self:objectName()..sgs.Sanguosha:getCard(card_id):objectName())
						
						local convert_to_askforcard_name = sgs.Sanguosha:getCard(card_id):objectName()
						convert_to_askforcard_name = convert_to_askforcard_name:gsub("(%l)(%w+)", function(a,b) return string.upper(a)..b end)
						convert_to_askforcard_name = string.gsub(convert_to_askforcard_name, "_", "")
						
						--if not room:askForCard(use.from, sgs.Sanguosha:getCard(card_id):objectName(), "@shouxi", data) then
						if not room:askForCard(use.from, convert_to_askforcard_name, "@shouxi", data) then
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
						else
							if not player:isNude() then
								local id = room:askForCardChosen(use.from, player, "he", self:objectName(), false)
								room:obtainCard(use.from, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, use.from:objectName()), false)
							end
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
				room:clearAG()
			end
		end
	end
}
caojie:addSkill(shouxi)
huimin = sgs.CreatePhaseChangeSkill{
	name = "huimin",
	on_phasechange = function(self, player)
		local targets = sgs.SPlayerList()
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHandcardNum() < p:getHp() then
				targets:append(p)
			end
		end
		if player:getPhase() == sgs.Player_Finish and not targets:isEmpty() and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				player:drawCards(targets:length())
				local cards = room:askForExchange(player, self:objectName(), math.min(player:getHandcardNum(), targets:length()), math.min(player:getHandcardNum(), targets:length()), false, "@huimin", false)
				if cards then
					local ids = sgs.IntList()
					for _,id in sgs.qlist(cards:getSubcards()) do
						room:showCard(player, id)
						ids:append(id)
					end
					room:fillAG(ids)
					local to = room:askForPlayerChosen(player, targets, self:objectName(), "huimin-invoke", false, true)
					local start = false
					for _,p in sgs.qlist(targets) do
					if ids:isEmpty() then break end
					if p:objectName() == to:objectName() then start = true end
						if start then
							local id = room:askForAG(p, ids, false, self:objectName())
							room:takeAG(p, id, false)
							ids:removeOne(id)
							p:obtainCard(sgs.Sanguosha:getCard(id), false)
							--targets:removeOne(p)
						end
					end
					for _,p in sgs.qlist(targets) do
						if ids:isEmpty() then break end
						local id = room:askForAG(p, ids, false, self:objectName())
						room:takeAG(p, id, false)
						ids:removeOne(id)
						p:obtainCard(sgs.Sanguosha:getCard(id), false)
						--targets:removeOne(p)
					end
					room:clearAG()
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end	  
		return false
	end
}

caojie:addSkill(huimin)

sgs.LoadTranslationTable{
["caojie"] = "曹節",
["#caojie"] = "獻穆皇后",
["designer:caojie"] = "會智遲的沮授",
["illustrator:caojie"] = "小小雞仔",
["shouxi"] = "守璽",
[":shouxi"] = "當你成為【殺】的目標後，你可以令使用者選擇是否棄置一張你未以此法聲明過的基本牌或錦囊牌的牌名，若選擇：是，其獲得你的一張牌；否，此【殺】對你無效。",
["@shouxi"] = "請棄置一張聲明的牌，否則此【殺】無效<br/> <b>操作提示</b>: 選擇一張牌→點擊確定<br/>",
["$shouxi1"] = "天子之位，乃歸劉漢！",
["$shouxi2"] = "吾父功蓋皇區，然且不敢篡竊神器！",
["huimin"] = "惠民",
[":huimin"] = "結束階段開始時，你可以摸X張牌，然後展示等量的手牌並選擇所有手牌數小於體力值的角色，這些角色從你選擇的角色開始依次獲得其中的牌。（X為手牌數小於體力值的角色數）",
["huimin-invoke"] = "選擇一名角色開始獲得牌<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["@huimin"] = "請選擇等量的牌發給所有手牌數小於體力值的角色<br/> <b>操作提示</b>: 選擇若干張牌→點擊確定<br/> ",
["$huimin1"] = "懸壺濟世，施醫救民。",
["$huimin2"] = "心系百姓，惠布山陽。",
["~caojie"] = "皇天……必不祚爾……",
}

sgs.Sanguosha:addSkills(skills)

