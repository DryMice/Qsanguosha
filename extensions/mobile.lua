module("extensions.mobile", package.seeall)
extension = sgs.Package("mobile")

sgs.LoadTranslationTable{
	["mobile"] = "手殺武將",
}

local skills = sgs.SkillList()

--手殺武將
--曹純
caochun = sgs.General(extension,"caochun","wei2","4",true,true)
--繕甲：出牌階段開始時，你可以先摸X張牌再棄置等量的牌，若你以此法棄置過裝備區內的牌，視為你使用了一張【殺】（X為你於本局遊戲內使用過的裝備牌數且最大為7）。
shanjiaCard = sgs.CreateSkillCard{
	name = "shanjia", 
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		for _, id in sgs.qlist(self:getSubcards())do
			if sgs.Sanguosha:getCard(id):isEquipped() then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("shanjia")
				for _, cd in sgs.qlist(self:getSubcards()) do
				slash:addSubcard(cd)
				end
				slash:deleteLater()
				return slash:targetFilter(targets_list, to_select, sgs.Self)
			end
		end
		return #targets < 0
	end, 
	feasible = function(self, targets)
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isEquipped() then return #targets > 0 end
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
			room:broadcastSkillInvoke("shanjia", 2)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		else
			room:broadcastSkillInvoke("shanjia", 1)
		end
	end
}
shanjiaVS = sgs.CreateViewAsSkill{
	name = "shanjia", 
	n = 7, 
	view_filter = function(self, selected, to_select)
		local x = math.min(sgs.Self:getMark("@shanjia"), 7)
		return #selected < x and not sgs.Self:isJilei(to_select)
	end, 
	view_as = function(self, cards)
		local x = math.min(sgs.Self:getMark("@shanjia"), 7)
		if #cards ~= x then return nil end
		local card = shanjiaCard:clone()
		for _, cd in ipairs(cards) do
			card:addSubcard(cd)
		end
		return card
	end, 
	enabled_at_play = function()
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@shanjia")
	end
}

shanjia = sgs.CreateTriggerSkill{
	name = "shanjia" ,
	view_as_skill = shanjiaVS,
	events = {sgs.EventPhaseStart,sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Play then
				if player:getMark("@shanjia") > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local n = player:getMark("@shanjia")
						player:drawCards(n)
						room:askForUseCard(player, "@@shanjia!", "shanjia_throw", -1, sgs.Card_MethodNone)
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and use.card:getTypeId() == sgs.Card_TypeEquip then
				if player:getMark("@shanjia") < 7 then
					room:setPlayerMark(player, "@shanjia", player:getMark("@shanjia") + 1) 
				end
			end
		end
	end,
}
shanjiaTargetMod = sgs.CreateTargetModSkill{
	name = "#shanjiaTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "shanjia" then
			return 1000
		end
	end,
}

caochun:addSkill(shanjia)
caochun:addSkill(shanjiaTargetMod)

sgs.LoadTranslationTable{
	["caochun"] = "曹純",
	["&caochun"] = "曹純",
	["#caochun"] = "虎豹騎首",
	["shanjia"] = "繕甲",
	[":shanjia"] = "出牌階段開始時，你可以先摸X張牌再棄置等量的牌，若你以此法棄置過裝備區內的牌，視為你使用了一張【殺】（X為你於本局遊戲內使用過的裝備牌數且最大為7）。",
	["shanjia_throw"] = "請棄置若干張牌",
	["~shanjia"] = "選擇若干張牌→點擊確定",
}

--孫茹
mol_sunru = sgs.General(extension,"mol_sunru","wu","3",false)
--【影箭】準備階段，你可以視為使用一張無距離限制的“殺”。
yingjianCard = sgs.CreateSkillCard{
	name = "yingjian",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
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
		end
	end
}
yingjianVS = sgs.CreateZeroCardViewAsSkill{
	name = "yingjian",
	view_as = function()
		return yingjianCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@yingjian"
	end
}
yingjian = sgs.CreatePhaseChangeSkill{
	name = "yingjian",
	view_as_skill = yingjianVS,
	on_phasechange = function(self, player)
		if sgs.Slash_IsAvailable(player) and player:getPhase() == sgs.Player_Start then
			player:getRoom():askForUseCard(player, "@@yingjian", "@yingjian")
		end
		return false
	end
}

yingjiantm = sgs.CreateTargetModSkill{
	name = "#yingjiantm",
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		local n = 0
		if card:getSkillName() == "yingjian" then
			return 1000
		end
	end
}
--【釋釁】鎖定技，你不會受到火焰傷害 。
mol_sunru:addSkill(yingjian)
mol_sunru:addSkill("shixin")
mol_sunru:addSkill(yingjiantm)

sgs.LoadTranslationTable{
	["mol_sunru"] = "界孫茹",
	["&mol_sunru"] = "孫茹",
	["yingjian"] = "影箭",
	["@yingjian"] = "你可以發動“影箭”",
	["~yingjian"] = "選擇若干名角色→點擊確定",
	[":yingjian"] = "準備階段，你可以視為使用一張無距離限制的“殺”。",
	["$yingjian1"] = "翩翩一云端，仿若桃花仙。",
	["$yingjian2"] = "没牌，又有何不可能的？",
}
--禰衡
miheng = sgs.General(extension,"miheng","qun3","3",true)
--狂才
kuangcai = sgs.CreatePhaseChangeSkill{
	name = "kuangcai",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				room:addPlayerMark(player, "kuangcai_replay")



				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}

kuangcai_buff = sgs.CreateTriggerSkill{
	name = "kuangcai_buff",
	events = {sgs.CardUsed, sgs.CardResponded},
	global = true,
	on_trigger = function(self, event, player, data, room)
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if card and not card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
				room:addPlayerMark(player, "used_record-Clear")
				if player:getMark("kuangcai_replay") > 0 then
					player:drawCards(1, self:objectName())
					room:addPlayerMark(player, "@kuangcaidraw_Play")
					if player:getMark("@kuangcaidraw_Play") >= 5 then
						room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
					end
				end
			end
		return false
	end
}

kuangcaiTM = sgs.CreateTargetModSkill{
	name = "#kuangcaiTM" ,
	pattern = "Slash,TrickCard" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("kuangcai") and from:getMark("kuangcai_replay") > 0 then
			return 1000
		end
		return 0
	end,
	residue_func = function(self, from)
		if from:hasSkill("kuangcai") and from:getMark("kuangcai_replay") > 0 then
			return 1000
		end
		return 0
	end,
}
--舌劍
shejian = sgs.CreateTriggerSkill{
	name = "shejian",
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
				if n > 0 then
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
						room:broadcastSkillInvoke("shejian")
						local _targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if player:canDiscard(p, "he") then _targets:append(p) end
						end
						if not _targets:isEmpty() then
							local to_discard = room:askForPlayerChosen(player, _targets, "shejian", "@str_shijen-discard", true)
							if to_discard then
								room:doAnimate(1, player:objectName(), to_discard:objectName())
								room:throwCard(room:askForCardChosen(player, to_discard, "he", "str_shijen", false, sgs.Card_MethodDiscard), to_discard, player)
							end
						end
					end
				end
			end
		end
		return false
	end					
}

miheng:addSkill(kuangcai)
miheng:addSkill(kuangcaiTM)
miheng:addSkill(shejian)

if not sgs.Sanguosha:getSkill("kuangcai_buff") then skills:append(kuangcai_buff) end



sgs.LoadTranslationTable{
	["miheng"] = "禰衡",
	["#miheng"] = "鷙鶚啄孤鳳",
	["kuangcai"] = "狂才",
	[":kuangcai"] = "出牌階段開始時，你可以進行一次判定，並令你於此階段內使用牌無距離和次數限制，若如此做，當你於此階段內使用牌時，摸一張牌，然後若你於此階段內以此法獲得過至少X張牌，結束此出牌階段（X為你判定的點數的一半（向下取整））。",
	["shejian"] = "舌劍",
	[":shejian"] = "棄牌階段結束時，若你於此階段內棄置過的你的手牌的花色均不相同，你可以棄置一名其他角色的一張牌。",
}

--陶謙
taoqian = sgs.General(extension,"taoqian","qun3","3",true)

--招禍
zhaohuo = sgs.CreateTriggerSkill{
	name = "zhaohuo",
	events = {sgs.EnterDying},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:objectName() ~= player:objectName() then
				SendComLog(self, p)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local x = p:getMaxHp() - 1
					room:loseMaxHp(p, x)
					p:drawCards(x, self:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
--義襄

yixiang = sgs.CreateTriggerSkill{
	name = "yixiang",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.from and use.to and RIGHT(self, player) and use.from:getHp() > player:getHp() and not use.card:isKindOf("SkillCard") and not room:getCurrent():hasFlag(self:objectName()..player:objectName()) and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
			room:getCurrent():setFlags(self:objectName()..player:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				local basic = {}
				for _, hand in sgs.qlist(player:getHandcards()) do
					if not table.contains(basic, TrueName(hand)) then
						table.insert(basic, TrueName(hand))
					end
				end
				local check = sgs.IntList()
				for _, id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("BasicCard") and not table.contains(basic, TrueName(card)) then
						check:append(id)
					end
				end
				--if not sgs.GetConfig("face_game", true) then
					if not check:isEmpty() then
						--player:obtainCard(sgs.Sanguosha:getCard(ids:at(math.random(0, ids:length() - 1))))
						player:obtainCard(sgs.Sanguosha:getCard(check:at(math.random(0, check:length() - 1))))
					end
					--[[
				else
					ShowManyCards(player, player:handCards())
					if check:isEmpty() then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcards(room:getDrawPile())
						room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), ""), nil)
						dummy:deleteLater()
					else
						local ids = sgs.IntList()
						while true do
							if #basic == 4 then break end
							local id = room:drawCard()
							local move = sgs.CardsMoveStruct(id, nil, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), ""))
							room:moveCardsAtomic(move, true)
							room:getThread():delay()
							local card = sgs.Sanguosha:getCard(id)
							local can_invoke = true
							if card:isKindOf("BasicCard") and not table.contains(basic, TrueName(card)) then
								room:obtainCard(player, card)
								break
							else
								ids:append(id)
							end
						end
						if not ids:isEmpty() then
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							dummy:addSubcards(ids)
							room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), ""), nil)
							dummy:deleteLater()
						end
					end
				end
				]]--
			end
			room:removePlayerMark(player, self:objectName().."engine")
		end
		return false
	end
}
--揖讓
yirang = sgs.CreatePhaseChangeSkill{
	name = "yirang",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local ids = sgs.IntList()
		local kind = {}
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMaxHp() > player:getMaxHp() then
				players:append(p)
			end
		end
		for _, card in sgs.qlist(player:getCards("he")) do
			if not card:isKindOf("BasicCard") then
				ids:append(card:getId())
				if not table.contains(kind, card:getType()) then
					table.insert(kind, card:getType())
				end
			end
		end
		if player:getPhase() == sgs.Player_Play and not ids:isEmpty() then
			local target = room:askForPlayerChosen(player, players, self:objectName(), "yirang-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(ids)
				target:obtainCard(dummy)
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(target:getMaxHp()))
				room:recover(player, sgs.RecoverStruct(player, nil, #kind))
			end
		end
		return false
	end
}
taoqian:addSkill(zhaohuo)
taoqian:addSkill(yixiang)
taoqian:addSkill(yirang)

sgs.LoadTranslationTable{
["taoqian"] = "手殺陶謙",
["&taoqian"] = "陶謙",
["#taoqian"] = "膺秉溫仁",
["zhaohuo"] = "招禍",
[":zhaohuo"] = "鎖定技，當其他角色進入瀕死狀態時，你減X點體力上限，然後摸等量的牌。（X為你的體力上限-1）",
["yixiang"] = "義襄",
[":yixiang"] = "每名角色的回合限一次，當你成為牌的目標後，若使用者的體力值大於你，你可以獲得牌堆裡隨機一張你手牌裡沒有的基本牌。",
["yirang"] = "揖讓",
[":yirang"] = "出牌階段開始時，你可以將所有非基本牌交給一名體力上限大於你的角色，然後將體力上限調整至與其相同，回复X點體力。（X為你以此法交給其的牌的類別數）",
["yirang-invoke"] = "選擇一名體力上限大於你的其他角色，你可以將所有非基本牌交給他並發動「揖讓」", 
}

--李豐
imba_lifeng = sgs.General(extension, "imba_lifeng", "shu2", "3", true)

imba_tunchu = sgs.CreateTriggerSkill{
	name = "imba_tunchu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards, sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if player:getPile("food"):length() > 0 or not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			player:setTag(self:objectName(), sgs.QVariant(true))
			room:broadcastSkillInvoke(self:objectName())
			data:setValue(data:toInt() + 2)
		else
			if not player:getTag(self:objectName()):toBool() then return false end
			player:setTag(self:objectName(), sgs.QVariant(false))
			local cards = room:askForExchange(player, self:objectName(), 999, 1, false, "@imba_tunchu", true)
			if cards then
				player:addToPile("food", cards)
			end
		end
		return false
	end
}
imba_lifeng:addSkill(imba_tunchu)

imba_shuliangCard = sgs.CreateSkillCard{
	name = "imba_shuliang",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:throwCard(sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", source:objectName(), self:objectName(), ""), nil)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
imba_shuliangVS = sgs.CreateOneCardViewAsSkill{
	name = "imba_shuliang",
	response_pattern = "@@imba_shuliang",
	filter_pattern = ".|.|.|food",
	expand_pile = "food",
	view_as = function(self, card)
		local first = imba_shuliangCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self, player)
		return false
	end
}
imba_shuliang = sgs.CreateTriggerSkill{
	name = "imba_shuliang",
	view_as_skill = imba_shuliangVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if player:getHp() > player:getHandcardNum() and p:getPile("food"):length() > 0
				and room:askForUseCard(p, "@@imba_shuliang", "@imba_shuliang", -1, sgs.Card_MethodNone) then
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					room:doAnimate(1, p:objectName(), player:objectName())
					room:drawCards(player, 2, self:objectName())
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Finish
	end
}
imba_lifeng:addSkill(imba_shuliang)

sgs.LoadTranslationTable{
["imba_lifeng"] = "李豐",
["&imba_lifeng"] = "李豐",
["#imba_lifeng"] = "繼父盡事",
["illustrator:imba_lifeng"] = "NOVART",
["imba_tunchu"] = "屯儲",
[":imba_tunchu"] = "摸牌階段，若你沒有“糧”，則你可以額外摸兩張牌，然後你可以將至少一張手牌置於武將牌上，稱為“糧”；若你有“糧”，你不能使用【殺】。",
["$imba_tunchu1"] = "屯糧事大，暫不與爾等計較。",
["$imba_tunchu2"] = "屯糧待戰，莫動刀槍。",
["@imba_tunchu"] = "你可以將至少一張手牌置為“糧”",
["imba_shuliang"] = "輸糧",
[":imba_shuliang"] = "一名角色的結束階段，若其手牌數小於體力值，你可以移去一張“糧”，令其摸兩張牌。",
["$imba_shuliang1"] = "將軍持勞，酒肉慰勞。",
["$imba_shuliang2"] = "將軍，牌來了！",
["@imba_shuliang"] = "你可以發動“輸糧”",
["~imba_shuliang"] = "選擇一張“糧”→點擊確定",
["~imba_lifeng"] = "吾有負丞相重托……",
}

--龐德公
pangdegong = sgs.General(extension, "pangdegong", "qun3", 3, true)
pingcai_wolongCard = sgs.CreateSkillCard{
	name = "pingcai_wolong",
	filter = function(self, targets, to_select)
		local invoke = string.find(sgs.Sanguosha:translate(sgs.Self:getGeneralName()).."&"..sgs.Sanguosha:translate(sgs.Self:getGeneral2Name()), sgs.Sanguosha:translate("wolong"))
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if not invoke then
				invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()).."&"..sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate("wolong"))
			end
		end
		if invoke then
			return #targets < 2
		else
			return #targets == 0
		end
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("pingcai", 2)
		for _,p in pairs(targets)do
			room:damage(sgs.DamageStruct("pingcai", source, p, 1, sgs.DamageStruct_Fire))
		end
		if source:hasSkill("pingcai_wolong") then
			room:detachSkillFromPlayer(source, "pingcai_wolong", true)
		end
		if source:hasSkill("pingcai_fengchu") then
			room:detachSkillFromPlayer(source, "pingcai_fengchu", true)
		end
		if source:hasSkill("pingcai_shuijing") then
			room:detachSkillFromPlayer(source, "pingcai_shuijing", true)
		end
		if source:hasSkill("pingcai_xuanjian") then
			room:detachSkillFromPlayer(source, "pingcai_xuanjian", true)
		end
	end
}
pingcai_wolong = sgs.CreateZeroCardViewAsSkill{
	name = "pingcai_wolong&", 
	view_as = function(self)
		return pingcai_wolongCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:hasUsed("#pingcai") and not player:hasUsed("#pingcai_wolong")
	end
}


if not sgs.Sanguosha:getSkill("pingcai_wolong") then skills:append(pingcai_wolong) end

pingcai_fengchuCard = sgs.CreateSkillCard{
	name = "pingcai_fengchu",
	filter = function(self, targets, to_select)
		local invoke = string.find(sgs.Sanguosha:translate(sgs.Self:getGeneralName()).."&"..sgs.Sanguosha:translate(sgs.Self:getGeneral2Name()), sgs.Sanguosha:translate("pangtong"))
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if not invoke then
				invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()).."&"..sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate("pangtong"))
			end
		end
		if invoke then
			return #targets < 4
		else
			return #targets < 3
		end
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("pingcai", 3)
		for _,p in pairs(targets)do
			p:setChained(true)
			room:broadcastProperty(p, "chained")
			room:setEmotion(p, "chain")
			room:getThread():trigger(sgs.ChainStateChanged, room, p)
		end
		if source:hasSkill("pingcai_wolong") then
			room:detachSkillFromPlayer(source, "pingcai_wolong", true)
		end
		if source:hasSkill("pingcai_fengchu") then
			room:detachSkillFromPlayer(source, "pingcai_fengchu", true)
		end
		if source:hasSkill("pingcai_shuijing") then
			room:detachSkillFromPlayer(source, "pingcai_shuijing", true)
		end
		if source:hasSkill("pingcai_xuanjian") then
			room:detachSkillFromPlayer(source, "pingcai_xuanjian", true)
		end
	end
}
pingcai_fengchu = sgs.CreateZeroCardViewAsSkill{
	name = "pingcai_fengchu&", 
	view_as = function(self)
		return pingcai_fengchuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:hasUsed("#pingcai") and not player:hasUsed("#pingcai_fengchu")
	end
}
if not sgs.Sanguosha:getSkill("pingcai_fengchu") then skills:append(pingcai_fengchu) end
pingcai_shuijingCard = sgs.CreateSkillCard{
	name = "pingcai_shuijing",
	filter = function(self, targets, to_select)
		local invoke = string.find(sgs.Sanguosha:translate(sgs.Self:getGeneralName()).."&"..sgs.Sanguosha:translate(sgs.Self:getGeneral2Name()), sgs.Sanguosha:translate("simahui"))
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if not invoke then
				invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()).."&"..sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate("simahui"))
			end
		end
		if #targets == 1 then
			if invoke then
				for _, card in sgs.qlist(targets[1]:getEquips()) do
				--if to_select:getEquip(card:getRealCard():toEquipCard():location()) or not to_select:hasEquipArea(card:getRealCard():toEquipCard():location()) then continue end
				if to_select:getEquip(card:getRealCard():toEquipCard():location()) or 
				((to_select:getMark("@AbolishWeapon") > 0 and card:getRealCard():toEquipCard():location() == 0) or
				(to_select:getMark("@AbolishArmor") > 0 and card:getRealCard():toEquipCard():location() == 1) or
				(to_select:getMark("@AbolishHorse") > 0 and card:getRealCard():toEquipCard():location() == 2) or
				(to_select:getMark("@AbolishHorse") > 0 and card:getRealCard():toEquipCard():location() == 3) or
				(to_select:getMark("@AbolishTreasure") > 0 and card:getRealCard():toEquipCard():location() == 4)) then continue end
					return true
				end
			else
				return not to_select:getArmor()
			end
		elseif #targets == 0 then
			if invoke then
				return to_select:hasEquip()
			else
				--return to_select:getArmor() and to_select:getArmor():getEffectiveId() ~= -1 and to_select:hasEquipArea(1)
				return to_select:getArmor() and to_select:getArmor():getEffectiveId() ~= -1 and to_select:getMark("@AbolishArmor") == 0
			end
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	about_to_use = function(self, room, use)
		room:broadcastSkillInvoke("pingcai", 4)
		local equiplist = {}
		for i = 0, 4, 1 do
			if not use.to:first():getEquip(i) then continue end
			if use.to:at(1):getEquip(i) == nil then
				table.insert(equiplist, "shuijing_"..tostring(i))
			end
		end
		if #equiplist == nil then return false end
		local _data = sgs.QVariant()
		_data:setValue(use.to:first())
		local x = "shuijing_1"
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if string.find(sgs.Sanguosha:translate(p:getGeneralName()).."&"..sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate("simahui")) then
				x = room:askForChoice(use.from, "pingcai_shuijing", table.concat(equiplist, "+"), _data)
				break
			end
		end
		local card = use.to:first():getEquip(tonumber(string.sub(x, string.len(x), string.len(x))))
		if card then
			room:moveCardTo(card, use.to:at(1), sgs.Player_PlaceEquip)
		end
		if use.from:hasSkill("pingcai_wolong") then
			room:detachSkillFromPlayer(use.from, "pingcai_wolong", true)
		end
		if use.from:hasSkill("pingcai_fengchu") then
			room:detachSkillFromPlayer(use.from, "pingcai_fengchu", true)
		end
		if use.from:hasSkill("pingcai_shuijing") then
			room:detachSkillFromPlayer(use.from, "pingcai_shuijing", true)
		end
		if use.from:hasSkill("pingcai_xuanjian") then
			room:detachSkillFromPlayer(use.from, "pingcai_xuanjian", true)
		end
	end
}
pingcai_shuijing = sgs.CreateZeroCardViewAsSkill{
	name = "pingcai_shuijing&", 
	view_as = function()
		return pingcai_shuijingCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:hasUsed("#pingcai") and not player:hasUsed("#pingcai_shuijing")
	end
}
if not sgs.Sanguosha:getSkill("pingcai_shuijing") then skills:append(pingcai_shuijing) end
pingcai_xuanjianCard = sgs.CreateSkillCard{
	name = "pingcai_xuanjian",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("pingcai", 5)
		local invoke = false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not invoke then
				invoke = string.find(sgs.Sanguosha:translate(p:getGeneralName()).."&"..sgs.Sanguosha:translate(p:getGeneral2Name()), sgs.Sanguosha:translate("xushu"))
			end
		end
		if #targets > 0 then
			targets[1]:drawCards(1, self:objectName())
			targets[1]:getRoom():recover(targets[1], sgs.RecoverStruct(source))
		end
		if invoke then
			source:drawCards(1, self:objectName())
		end
		if source:hasSkill("pingcai_wolong") then
			room:detachSkillFromPlayer(source, "pingcai_wolong", true)
		end
		if source:hasSkill("pingcai_fengchu") then
			room:detachSkillFromPlayer(source, "pingcai_fengchu", true)
		end
		if source:hasSkill("pingcai_shuijing") then
			room:detachSkillFromPlayer(source, "pingcai_shuijing", true)
		end
		if source:hasSkill("pingcai_xuanjian") then
			room:detachSkillFromPlayer(source, "pingcai_xuanjian", true)
		end
	end
}
pingcai_xuanjian = sgs.CreateZeroCardViewAsSkill{
	name = "pingcai_xuanjian&", 
	view_as = function(self)
		return pingcai_xuanjianCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:hasUsed("#pingcai") and not player:hasUsed("#pingcai_xuanjian")
	end
}
if not sgs.Sanguosha:getSkill("pingcai_xuanjian") then skills:append(pingcai_xuanjian) end
pingcaiCard = sgs.CreateSkillCard{
	name = "pingcai",
	target_fixed = true, 
	about_to_use = function(self, room, use)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:getThread():delay(3820)
			local n = math.random(1,4)
			if n == 1 and not use.from:hasSkill("pingcai_wolong") then
				room:attachSkillToPlayer(use.from, "pingcai_wolong")
			end
			room:getThread():delay(1053)
			if n == 2 and not use.from:hasSkill("pingcai_fengchu") then
				room:attachSkillToPlayer(use.from, "pingcai_fengchu")
			end
			room:getThread():delay(1351)
			if n == 3 and not use.from:hasSkill("pingcai_shuijing") then
				room:attachSkillToPlayer(use.from, "pingcai_shuijing")
			end
			room:getThread():delay(1147)
			if n == 4 and not use.from:hasSkill("pingcai_xuanjian") then
				room:attachSkillToPlayer(use.from, "pingcai_xuanjian")
			end
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
pingcai = sgs.CreateZeroCardViewAsSkill{
	name = "pingcai", 
	view_as = function(self)
		return pingcaiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#pingcai")
	end
}


pangdegong:addSkill(pingcai)
--隱世
yinship = sgs.CreateTriggerSkill{
	name = "yinship",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if not player:isSkipped(change.to) and (change.to == sgs.Player_Start or change.to == sgs.Player_Judge or change.to == sgs.Player_Finish) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				player:skip(change.to)
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}

yinshipban = sgs.CreateProhibitSkill{
	name = "#yinshipban",
	is_prohibited = function(self, from, to, card)
		return (to:hasSkill("yinship") or to:hasSkill("qianjie") or to:hasSkill("zhenlve")) and card:isKindOf("DelayedTrick")
	end
}
pangdegong:addSkill(yinship)
pangdegong:addSkill(yinshipban)

sgs.LoadTranslationTable{
["pangdegong"] = "龐德公",
["#pangdegong"] = "德懿舉世",
["pingcai"] = "評才",
[":pingcai"] = "出牌階段限一次，你可以選擇一項：1.若所有角色中有諸葛亮（火），你對一至兩名角色各造成1點火焰傷害，否則你對一名角色造成1點火焰傷害；2.若所有角色中有龐統，你橫置一至四名角色，否則你橫置一至三名角色；3.若所有角色中有司馬徽，你將一名角色裝備區裡的裝備牌置入另一名角色的裝備區，否則你將一名角色裝備區裡的防具牌置入另一名角色的裝備區；4.若所有角色中有徐庶，你令一名角色摸一張牌，其回复1點體力，然後你摸一張牌，否則你令一名角色摸一張牌，其回复1點體力。",
["pingcai_wolong"] = "臥龍",
[":pingcai_wolong"] = "出牌階段限一次，你可以對一至X名角色各造成1點火焰傷害。（若所有角色中有諸葛亮（火），X為2，否則X為1）",
["pingcai_fengchu"] = "鳳雛",
[":pingcai_fengchu"] = "出牌階段限一次，你可以橫置一至X名角色。（若所有角色中有龐統，X為4，否則X為3）",
["pingcai_shuijing"] = "水鏡",
[":pingcai_shuijing"] = "出牌階段限一次，若所有角色中：有司馬徽，你可以將一名角色裝備區裡的裝備牌置入另一名角色的裝備區；沒有司馬徽，你可以將一名角色裝備區裡的防具牌置入另一名角色的裝備區。",
["pingcai_xuanjian"] = "玄劍",
[":pingcai_xuanjian"] = "出牌階段限一次，若所有角色中：有徐庶，你可以令一名角色摸一張牌，其回复1點體力，然後你摸一張牌；沒有徐庶，你令一名角色摸一張牌，其回复1點體力。",
["$pingcai1"] = "吾有眾好友，分為臥龍、鳳雛、水鏡、元直。",
["$pingcai2"] = "孔明能藉天火之勢。",
["$pingcai3"] = "士元慮事環環相扣。",
["$pingcai4"] = "德操深諳處世之道。",
["$pingcai5"] = "元直俠客懲惡揚善。",
["yinship"] = "隱世",
[":yinship"] = "鎖定技，你跳過準備/判定/結束階段；鎖定技，你不是延時類錦囊牌的合法目標。",
["$yinship1"] = "",
["$yinship2"] = "",
["~pangdegong"] = "",
}

--趙統趙廣
zhaoguangzhaotong = sgs.General(extension, "zhaoguangzhaotong", "shu2", "4", true)

yizanUsedTimes = sgs.CreateTriggerSkill{  --记录技能“翊赞”发动次数（顺带进行连计的改变卡牌目标）
	name = "yizanUsedTimes",
	global = true,
	priority = 10,
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self, event, splayer, data, room)
		local card
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			card = use.card
			if card:getSkillName() == "m_lianjicard" and (card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack")) then
				local targetList = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag("mobile_lianji") then
						targetList:append(p)
						room:setPlayerFlag(p, "-mobile_lianji")
					end
				end
				if not targetList:isEmpty() then
					use.to = targetList
					data:setValue(use)
				end
			end
			if card:getSkillName() == "mobile_jingong" then
				room:addPlayerMark(splayer, "mobile_jingong")
				room:addPlayerMark(splayer, "mobile_jingong_Play")
			end
		else
			card = data:toCardResponse().m_card
		end
		if card and card:getSkillName() == "yizan" and splayer:getMark("@yizanUsed") < 3 then
			room:addPlayerMark(splayer, "@yizanUsed")
		end
		--順便進行技能「錦織」的紀錄
		if card and card:getSkillName() == "jinzhi" then
			room:addPlayerMark(splayer, "@jinzhi_lun")
			splayer:drawCards(1)
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("yizanUsedTimes") then skills:append(yizanUsedTimes) end


-- 技能：【翊赞】你可以将两张牌（其中至少一张基本牌）当任意基本牌使用或打出。（修改后：你可以将一张基本牌当任意基本牌使用或打出。） --
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

yizanCard = sgs.CreateSkillCard{
	name = "yizan",
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
		local card = sgs.Self:getTag("yizan"):toCard()
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
		local card = sgs.Self:getTag("yizan"):toCard()
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
		local card = sgs.Self:getTag("yizan"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_yizan = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local yizan_list = {}
			table.insert(yizan_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(yizan_list, "normal_slash")
				table.insert(yizan_list, "thunder_slash")
				table.insert(yizan_list, "fire_slash")
			end
			to_yizan = room:askForChoice(player, "yizan_slash", table.concat(yizan_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_yizan == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_yizan == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_yizan
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_yizan")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_yizan
		if user_str == "peach+analeptic" then
			local yizan_list = {}
			table.insert(yizan_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(yizan_list, "analeptic")
			end
			to_yizan = room:askForChoice(user, "yizan_saveself", table.concat(yizan_list, "+"))
		elseif user_str == "slash" then
			local yizan_list = {}
			table.insert(yizan_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(yizan_list, "normal_slash")
				table.insert(yizan_list, "thunder_slash")
				table.insert(yizan_list, "fire_slash")
			end
			to_yizan = room:askForChoice(user, "yizan_slash", table.concat(yizan_list, "+"))
		else
			to_yizan = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_yizan == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_yizan == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_yizan
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_yizan")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end
}
yizan = sgs.CreateViewAsSkill{
	name = "yizan",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			if sgs.Self:getMark("longyuan") > 0 then
				return to_select:isKindOf("BasicCard")
			else
				return true
			end
		elseif #selected == 1 and sgs.Self:getMark("longyuan") == 0 then
			if selected[1]:isKindOf("BasicCard") then
				return true
			else
				return to_select:isKindOf("BasicCard")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if (#cards ~= 1 and sgs.Self:getMark("longyuan") > 0) or (#cards ~= 2 and sgs.Self:getMark("longyuan") == 0) then return nil end
		local skillcard = yizanCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE 
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		end
		local c = sgs.Self:getTag("yizan"):toCard()
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
yizan:setGuhuoDialog("l")
zhaoguangzhaotong:addSkill(yizan)
-- 技能：【龙渊】觉醒技，当你使用或打出一张牌时，若你发动过至少三次“翊赞”，则你将其效果改为“你可以将一张基本牌当任意基本牌使用或打出”。 --
longyuan = sgs.CreateTriggerSkill{
	name = "longyuan",	
	frequency = sgs.Skill_Wake, 
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if (player:getMark("@yizanUsed") >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) and player:getMark(self:objectName()) == 0 then
			room:doSuperLightbox("zhaoguangzhaotong","longyuan")
			room:addPlayerMark(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			sgs.Sanguosha:addTranslationEntry(":yizan", "" .. string.gsub(sgs.Sanguosha:translate(":yizan"), sgs.Sanguosha:translate(":yizan"), sgs.Sanguosha:translate(":yizan-EX")))
			ChangeCheck(player, "zhaoguangzhaotong")
		end
		return false
	end
}
zhaoguangzhaotong:addSkill(longyuan)

sgs.LoadTranslationTable{
["zhaoguangzhaotong"] = "趙廣&趙統",
["&zhaoguangzhaotong"] = "趙廣趙統",
["#zhaoguangzhaotong"] = "效捷致果",
["yizan"] = "翊贊",
[":yizan"] = "你可以將兩張牌（其中至少一張基本牌）當任意基本牌使用或打出。",
[":yizan-EX"] = "你可以將一張基本牌當任意基本牌使用或打出。",
["yizan_slash"] = "翊贊",
["longyuan"] = "龍淵",
[":longyuan"] = "覺醒技，當你使用或打出一張牌時，若你發動過至少三次“翊贊”，則你將其效果改為“你可以將一張基本牌當任意基本牌使用或打出”。",
["~zhaoguangzhaotong"] = "",
}

--馬鈞 魏 3體力
majun = sgs.General(extension,"majun","wei2","3",true)
--精械:當你進入瀕死狀態時,你可以重鑄一張防具牌,然後令你的體力值回復至1。鎖定技，你的特定裝備牌具有額外效果：諸葛連弩:攻擊範圍+2；八卦陣:每當你受到【殺】以外的傷害時,你可以進行一次判定:若判定結果為紅色,則此傷害-1；仁王盾:紅桃【殺】對你無效；白銀獅子：當你失去裝備區裡的【白銀獅子】時,你摸兩張牌；藤甲：你不會被橫置

function lua_armor_null_check(player)
	if #player:getTag("Qinggang"):toStringList() > 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then
		return true
	end
	return false
end

jingxieCard = sgs.CreateSkillCard{
	name = "jingxie",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:showCard(source, self:getSubcards():first())
		local jingxie_equip_card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if jingxie_equip_card:isKindOf("Crossbow") and source:getMark("jingxie_Crossbow_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_Crossbow_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_Crossbow_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#AG_jingxie_Crossbow_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("EightDiagram") and source:getMark("jingxie_EightDiagram_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_EightDiagram_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_EightDiagram_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#AG_jingxie_EightDiagram_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("RenwangShield") and source:getMark("jingxie_RenwangShield_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_RenwangShield_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_RenwangShield_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#AG_jingxie_RenwangShield_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("SilverLion") and source:getMark("jingxie_SilverLion_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_SilverLion_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_SilverLion_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#AG_jingxie_SilverLion_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("Vine") and source:getMark("jingxie_Vine_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_Vine_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_Vine_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#AG_jingxie_Vine_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		end
	end
}
jingxieVS = sgs.CreateOneCardViewAsSkill{
	name = "jingxie",
	view_filter = function(self, card)
		return card:isKindOf("Crossbow") or card:isKindOf("Armor")
	end,
	view_as = function(self, card)
		local skillcard = jingxieCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
jingxie = sgs.CreateTriggerSkill{
	name = "jingxie",
	view_as_skill = jingxieVS,
	events = {sgs.EnterDying},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill(self:objectName()) then
			local card_id = room:askForCard(player, "Armor", "@jingxie", sgs.QVariant(), sgs.Card_MethodRecast)
			if card_id then
				room:moveCardTo(card_id, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), ""))
				room:broadcastSkillInvoke("@recast")
				local log = sgs.LogMessage()
				log.type = "#UseCard_Recast"
				log.from = player
				log.card_str = card_id:toString()
				room:sendLog(log)
				player:drawCards(1, "recast")
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1 - player:getHp()
				room:recover(player, recover)
			end
		end
		return false
	end
}
majun:addSkill(jingxie)

jingxie_armor_equip_buff = sgs.CreateTriggerSkill{
	name = "jingxie_armor_equip_buff",
	global = true,
	events = {sgs.StartJudge, sgs.SlashEffected, sgs.BeforeCardsMove, sgs.ChainStateChange},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.StartJudge and not lua_armor_null_check(player) and player:getArmor() and player:getArmor():isKindOf("EightDiagram") and player:getMark("jingxie_EightDiagram_id_"..player:getArmor():getEffectiveId()) > 0 then
			local judge = data:toJudge()
			if judge.reason == "eight_diagram" then
				judge.pattern = ".|spade"
				judge.good = false
				local log = sgs.LogMessage()
				log.type = "#AG_jingxie_EightDiagram_armor_buff"
				log.from = player
				room:sendLog(log)
			end
		end
		if event == sgs.SlashEffected and not lua_armor_null_check(player) and player:getArmor() and player:getArmor():isKindOf("RenwangShield") and player:getMark("jingxie_RenwangShield_id_"..player:getArmor():getEffectiveId()) > 0 then
			local slasheffect = data:toSlashEffect()
			if slasheffect.slash and slasheffect.slash:getSuit() == sgs.Card_Heart and not slasheffect.from:hasWeapon("qinggang_sword") then
				
				local logmsg = sgs.LogMessage()
				logmsg.type = "#AG_jingxie_RenwangShield_armor_buff"
				logmsg.from = player
				room:sendLog(logmsg)
				
				local log = sgs.LogMessage()
				log.type = "#ArmorNullify"
				log.from = player
				log.arg = "renwang_shield"
				log.arg2 = slasheffect.slash:objectName()
				room:sendLog(log)
				return true
			end
		end
		if event == sgs.BeforeCardsMove and player:getArmor() and player:getArmor():isKindOf("SilverLion") and player:getMark("jingxie_SilverLion_id_"..player:getArmor():getEffectiveId()) > 0 and player:isWounded() then
			local move = data:toMoveOneTime()
			
			local invoke = false
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("SilverLion") then
					invoke = true
				end
			end
			
			if invoke and move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
				local log = sgs.LogMessage()
				log.type = "#AG_jingxie_SilverLion_armor_buff"
				log.from = player
				room:sendLog(log)
				player:drawCards(2, self:objectName())
			end
		end
		if event == sgs.ChainStateChange and not lua_armor_null_check(player) and player:getArmor() and player:getArmor():isKindOf("Vine") and player:getMark("jingxie_Vine_id_"..player:getArmor():getEffectiveId()) > 0 then
			if not player:isChained() then
				local log = sgs.LogMessage()
				log.type = "#AG_jingxie_Vine_armor_buff"
				log.from = player
				room:sendLog(log)
				return true
			end
		end
		return false
	end
}


if not sgs.Sanguosha:getSkill("jingxie_armor_equip_buff") then skills:append(jingxie_armor_equip_buff) end


jingxieTM = sgs.CreateTargetModSkill{
	name = "#jingxieTM",
	frequency = sgs.Skill_NotFrequent,
	distance_limit_func = function(self, from, card)
		if card:isKindOf("Slash") and from:getWeapon() and from:getWeapon():isKindOf("Crossbow") and from:getMark("jingxie_Crossbow_id_"..from:getWeapon():getEffectiveId()) > 0 then
			return 2
		end
	end

}
--巧思:出牌階段限一次,你可以選擇任意項條件，然後展示一張牌，若符合條件，你可以贏取對應的牌。然後你選擇一項:1.棄置等量的牌，或2.交給一名角色其他等量的牌。

function returnpatterncard(player,pattern_list)
	local room = player:getRoom()
	local DPHeart = sgs.IntList()
	for i = 1,#pattern_list ,1 do
		local pattern = pattern_list[i]
		if room:getDrawPile():length() > 0 then
			for _, id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf(pattern) then
					DPHeart:append(id)
				end
			end
		end
		if room:getDiscardPile():length() > 0 then
			for _, id in sgs.qlist(room:getDiscardPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf(pattern) then
					DPHeart:append(id)
				end
			end
		end
	end
	if DPHeart:length() ~= 0 then
		local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
		if get_id then
			return get_id
		end
	end
	return nil
end

qiaosiCard = sgs.CreateSkillCard{
	name = "qiaosi",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local qiaosi_cards = {}

		local trick_card_counts = 0
		local equip_card_counts = 0
		local basic_card_counts = 0

		--主公
		if math.random(1,36) == 1 then
			for i = 1,2,1 do
				local id = returnpatterncard(source,{"EquipCard"})
				if id then
					table.insert(qiaosi_cards,  id )
					equip_card_counts = equip_card_counts + 1
				end
			end
		end

		--富商
		if math.random(1,36) < 21 then
			if equip_card_counts == 2 then
				local id = returnpatterncard(source,{"Slash","Analeptic"})
				if id then
					table.insert(qiaosi_cards,  id )
				end
			else
				local id = returnpatterncard(source,{"EquipCard"})
				if id then
					table.insert(qiaosi_cards,  id )
					equip_card_counts = equip_card_counts + 1
				end
			end
		end
		--鐵匠
		if math.random(1,36) < 35 then
			local id = returnpatterncard(source,{"Slash","Analeptic"})
			if id then
				table.insert(qiaosi_cards,  id )
			end
		end
		--農民
		if math.random(1,36) < 30 then
			local id = returnpatterncard(source,{"Jink","Peach"})
			if id then
				table.insert(qiaosi_cards,  id )
			end
		end
		--武將
		if math.random(1,36) < 3 then
			for i = 1,2,1 do
				local id = returnpatterncard(source,{"TrickCard"})
				if id then
					table.insert(qiaosi_cards,  id )
					trick_card_counts = trick_card_counts + 1
				end
			end
		end

		--謀士
		if math.random(1,36) < 10 then
			if trick_card_counts == 2 then
				local id = returnpatterncard(source,{"Jink","Peach"})
				if id then
					table.insert(qiaosi_cards,  id )
				end
			else
				local id = returnpatterncard(source,{"EquipCard"})
				if id then
					table.insert(qiaosi_cards,  id )
					trick_card_counts = trick_card_counts + 1
				end
			end
		end

		
		
		if #qiaosi_cards > 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _,id in ipairs(qiaosi_cards) do
				dummy:addSubcard(id)
			end
			room:obtainCard(source, dummy, true)
			
			local choice = room:askForChoice(source, self:objectName(), "qiaosi_throw+qiaosi_give")
			if choice == "qiaosi_throw" then
				room:askForDiscard(source, self:objectName(), #qiaosi_cards, #qiaosi_cards, false, true)
			else
				local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "qiaosi-invoke", false, true)
				local qiaosi_give_cards = room:askForExchange(source, self:objectName(), #qiaosi_cards, #qiaosi_cards, true, "qiaosi_exchange")
				if target and qiaosi_give_cards then
					room:obtainCard(target, qiaosi_give_cards, false)
				end
			end
		end
	end
}
qiaosi = sgs.CreateZeroCardViewAsSkill{
	name = "qiaosi",
	view_as = function(self, cards)
		return qiaosiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#qiaosi")
	end
}

--水轉六效果：(隨發動次數機率遞減，第一次斷12 第二次斷34.......)
-- 兩錦囊 不為裝備
-- 一裝備 不為梅花
-- 一張酒、殺 全
-- 一張閃、桃 全
-- 一錦囊 不為黑桃
-- 兩裝備 不為錦囊

majun:addSkill(jingxie)
majun:addSkill(jingxieTM)
majun:addSkill(qiaosi)

sgs.LoadTranslationTable{
	["majun"] = "馬鈞",
	["#majun"] = "",
	["jingxie"] = "精械",
	[":jingxie"] = "當你進入瀕死狀態時，你可以重鑄一張防具牌，然後令你的體力值回復至1。出牌階段，你可以展示一張防具牌或【諸葛連弩】然後以以下規則強化此裝備牌：\
	【諸葛連弩】攻擊範圍改至3；\
	【八卦陣】防具技能判定條件改為不為黑桃；\
	【仁王盾】防具技能增加紅桃【殺】無效；\
	【白銀獅子】觸發回復體力時摸兩張牌；\
	【藤甲】防具技能增加不會被橫置。 ",
	["$jingxie1"] = "",
	["$jingxie2"] = "",
	["@jingxie"] = "你可以重鑄一張防具牌",
	["#AG_jingxie_Crossbow_enhance"] = "因 %from 的精械技能，此房間 %card 攻擊範圍改至3",
	["#AG_jingxie_EightDiagram_enhance"] = "因 %from 的精械技能，此房間 %card 防具技能判定條件改為不為黑桃",
	["#AG_jingxie_RenwangShield_enhance"] = "因 %from 的精械技能，此房間 %card 防具技能增加紅桃【殺】無效",
	["#AG_jingxie_SilverLion_enhance"] = "因 %from 的精械技能，此房間因 %card 回復體力時摸兩張牌",
	["#AG_jingxie_Vine_enhance"] = "因 %from 的精械技能，此房間 %card 防具技能增加不會被橫置",
	["#AG_jingxie_EightDiagram_armor_buff"] = "因 %from 的【八卦陣】精械過，【八卦陣】判定條件改為不為黑桃",
	["#AG_jingxie_RenwangShield_armor_buff"] = "因 %from 的【仁王盾】精械過，【仁王盾】增加紅桃【殺】無效",
	["#AG_jingxie_SilverLion_armor_buff"] = "因 %from 的【白銀獅子】精械過，%from 因【白銀獅子】回復體力時摸兩張牌",
	["#AG_jingxie_Vine_armor_buff"] = "因 %from 的【藤甲】精械過，%from 不會被橫置",

	["qiaosi"] = "巧思",
[":qiaosi"] = "出牌階段限一次，你可以隨機獲得任意項以下效果：\
1.獲得牌堆裡兩張錦囊牌；\
2.獲得牌堆裡一張裝備牌；\
3.獲得牌堆裡一張酒或殺；\
4.獲得牌堆裡一張桃或閃；\
5.獲得牌堆裡一張錦囊牌；\
6.獲得牌堆裡兩張裝備牌；\
(若獲得的錦囊牌或裝備牌牌數大於2，其中一張牌換為任意基本牌)。 \
然後你選擇一項：1.棄置等量的牌；2.將等量的牌交給一名其他角色。 ",
["qiaosi_throw"] = "棄置等量的牌",
["qiaosi_give"] = "將等量的牌交給一名其他角色",
["qiaosi-invoke"] = "你可以發動“巧思”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["qiaosi_exchange"] = "請選擇等量的牌交給對方<br/> <b>操作提示</b>: 選擇牌直到可以點確定<br/>",

	["#JingxieMD"] = "%from 發動了技能 “<font color=\"yellow\"><b>精械減傷</b></font>”， %to 對 %from 造成的傷害由 %arg 點減少至 %arg2 點",
}

--司馬昭（魏）體力3，稱號為四海威服
mobile_simazhao = sgs.General(extension,"mobile_simazhao","wei2","3",true)
--【怠攻】每回合限一次，當你受到傷害時，你可展示所有手牌令傷害來源選擇一項：1.交給你一張你手牌中沒有的花色；2.防止此傷害。
daigong = sgs.CreateTriggerSkill{
	name = "daigong",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke("daigong")
				room:showAllCards(player)

				local cards = player:getHandcards()
				local suit_set = {}
				for _, id in sgs.qlist(cards) do 
					local flag = true
					for _, k in ipairs(suit_set) do
						if id:getSuit() == k then
							flag = false
							break
						end
					end
					if flag then table.insert(suit_set, id:getSuit()) end
				end
				local hasC = false
				local hasD = false
				local hasH = false
				local hasS = false
				for _, k in ipairs(suit_set) do
					if k == sgs.Card_Club then 
						hasC = true
					elseif k == sgs.Card_Diamond then 
						hasD = true
					elseif k == sgs.Card_Heart then 
						hasH = true
					elseif k == sgs.Card_Spade then 
						hasS = true
					end
				end

				local pattern = ".|"
				if not hasS then
					pattern = pattern.."spade,"
				end
				if not hasH then
					pattern = pattern.."heart,"
				end
				if not hasC then
					pattern = pattern.."club,"
				end
				if not hasD then
					pattern = pattern.."diamond,"
				end
				pattern = pattern.."|.|."

				local id = room:askForCard(damage.from, pattern , "@daigong-give:"..player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				if id then						
					room:obtainCard(player, id, true)
				else
					local msg = sgs.LogMessage()
					msg.type = "#daigong_Protect"
					msg.from = damage.to
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
			end
		return false
		end
	end,
}
--【昭心】出牌階段限一次，你可以將任意張牌置於你的武將牌上，稱為「望」（總數不能超過3），然後摸等量的牌，你攻擊範圍內角色的摸牌階段結束後，其可以獲得由你選擇的「望」，然後你可以對其造成一點傷害。
mobile_zhaoxinCard = sgs.CreateSkillCard{
	name = "mobile_zhaoxin",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@mobile_zhaoxin" then
			local target = room:getCurrent()
			local card_name = sgs.Sanguosha:getCard(self:getSubcards():first()):objectName()
			if target and target:isAlive() and room:askForSkillInvoke(target, self:objectName(), sgs.QVariant("obtain:"..card_name)) then
				room:obtainCard(target, self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), self:objectName(), ""), false)
				if room:askForSkillInvoke(source, "mobile_zhaoxin_damage", sgs.QVariant("damage:"..target:objectName())) then
					room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
				end
			end
		else
			source:addToPile("wang", self)
			source:drawCards(self:getSubcards():length(), self:objectName())
		end
	end
}
mobile_zhaoxinVS = sgs.CreateViewAsSkill{
	name = "mobile_zhaoxin",
	n = 3,
	expand_pile = "wang",
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@mobile_zhaoxin" then
			return sgs.Self:getPile("wang"):contains(to_select:getEffectiveId())
		else
			return not sgs.Self:getPile("wang"):contains(to_select:getEffectiveId())
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@mobile_zhaoxin" then
			if #cards ~= 1 then return nil end
			local skillcard = mobile_zhaoxinCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			skillcard:setSkillName(self:objectName())
			return skillcard
		else
			if #cards == 0 then return nil end
			if #cards + sgs.Self:getPile("wang"):length() > 3 then return nil end
			local skillcard = mobile_zhaoxinCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			skillcard:setSkillName(self:objectName())
			return skillcard
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_zhaoxin")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@mobile_zhaoxin"
	end
}
mobile_zhaoxin = sgs.CreateTriggerSkill{
	name = "mobile_zhaoxin",
	global = true,
	events = {sgs.EventPhaseEnd},
	view_as_skill = mobile_zhaoxinVS,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Draw then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not p:getPile("wang"):isEmpty() and (p:inMyAttackRange(player) or p:objectName() == player:objectName()) then
					room:askForUseCard(p, "@@mobile_zhaoxin", "@mobile_zhaoxin", -1, sgs.Card_MethodNone)
				end
			end
		end
		return false
	end
}

mobile_simazhao:addSkill(mobile_zhaoxin)
mobile_simazhao:addSkill(daigong)

sgs.LoadTranslationTable{
	["mobile_simazhao"] = "司馬昭",
	["#mobile_simazhao"] = "四海威服",
	["daigong"] = "怠攻",
	[":daigong"] = "每回合限一次，當你受到傷害時，你可展示所有手牌令傷害來源選擇一項：1.交給你一張你手牌中沒有的花色；2.防止此傷害。",
	["mobile_zhaoxin"] = "昭心",
	["wang"] = "望",
	["mobile_zhaoxintake"] = "昭心拿牌",
	["mobile_zhaoxindamage"] = "昭心造成傷害",
	[":mobile_zhaoxin"] = "出牌階段限一次，你可以將任意張牌置於你的武將牌上，稱為「望」（總數不能超過3），然後摸等量的牌，你攻擊範圍內角色的摸牌階段結束後，其可以獲得由你選擇的「望」，然後你可以對其造成一點傷害。",

	["@daigong-give"] = "請交給 %src 一張牌，否則你對其造成的傷害無效",
	["@mobile_zhaoxin"] = "你可以發動“昭心”",
	["~mobile_zhaoxin"] = "選擇一張牌→點擊確定",
	["mobile_zhaoxin:obtain"] = "你是否要獲得此“望”牌 ( %src ) ?",
	["mobile_zhaoxin_damage:damage"] = "你是否要對 %src 造成1點傷害?",
	["#daigong_Protect"] = "%from 的「<font color=\"yellow\"><b>怠攻</b></font>」效果被觸發，防止了 %arg 點傷害[%arg2]",
}

--王元姬（魏）體力3，稱號為清雅抑奢
mobile_wangyuanji = sgs.General(extension,"mobile_wangyuanji","wei2","3", false)

--【謙沖】鎖定技，如果你的裝備區所有牌均為黑色，則你獲得「帷幕」；如果你裝備區所有牌均為紅色，則你獲得「明哲」。出牌階段開始時，若你不滿足上述條件，則你選擇一種類型的牌，本回合使用此類型的牌無次數和距離限制。
qianchong = sgs.CreateTriggerSkill{
	name = "qianchong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip)) or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) then
				local colors = {}
				for _,card in sgs.qlist(player:getEquips()) do
					if not table.contains(colors, GetColor(card)) then
						table.insert(colors, GetColor(card))
					end
				end
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				--疑似handleAcquireDetachSkills函數重複使用或失去裝備時會不能獲得技能
				--測試情況：一次失去兩個裝備區的裝備牌，再使用裝備後不會獲得對應的技能
				if #colors == 1 then
					room:broadcastSkillInvoke(self:objectName())
					if colors[1] == "red" then
						equip_change_acquire_or_detach_skill(room, player, "-weimu|mingzhe")
						--room:handleAcquireDetachSkills(player, "-weimu|mingzhe", true)
					elseif colors[1] == "black"  then
						equip_change_acquire_or_detach_skill(room, player, "weimu|-mingzhe")
						--room:handleAcquireDetachSkills(player, "weimu|-mingzhe", true)
					end
				end
				if #colors >= 2 or #colors == 0 then
					equip_change_acquire_or_detach_skill(room, player, "-weimu|-mingzhe")
					--room:handleAcquireDetachSkills(player, "-weimu|-mingzhe", true)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local invoke = false
				local colors = {}
				for _,card in sgs.qlist(player:getEquips()) do
					if not table.contains(colors, GetColor(card)) then
						table.insert(colors, GetColor(card))
					end
				end
				if #colors >= 2 or #colors == 0 then
					invoke = true
				end
				if invoke then
					local choices = {"qianchong_basic", "qianchong_trick", "qianchong_equip"}
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					ChoiceLog(player, choice)
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					if choice == "qianchong_basic" then
						room:addPlayerMark(player, "qianchong_basic-Clear")
					elseif choice == "qianchong_trick" then
						room:addPlayerMark(player, "qianchong_trick-Clear")
					elseif choice == "qianchong_equip" then
						room:addPlayerMark(player, "qianchong_equip-Clear")
					end
				end
			end
		end
		return false
	end
}

qianchongTM = sgs.CreateTargetModSkill{
	name = "#qianchongTM",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash,Analeptic,TrickCard",
	distance_limit_func = function(self, from, card)
		if from and from:getMark("qianchong_basic-Clear") > 0 and card:isKindOf("BasicCard") then
			return 1000
		end
		if from and from:getMark("qianchong_trick-Clear") > 0 and card:isKindOf("TrickCard") then
			return 1000
		end
		if from and from:getMark("qianchong_equip-Clear") > 0 and card:isKindOf("EquipCard") then
			return 1000
		end
	end,
	residue_func = function(self, from, card)
		if from and from:getMark("qianchong_basic-Clear") > 0 and card:isKindOf("BasicCard") then
			return 1000
		end
		if from and from:getMark("qianchong_trick-Clear") > 0 and card:isKindOf("TrickCard") then
			return 1000
		end
		if from and from:getMark("qianchong_equip-Clear") > 0 and card:isKindOf("EquipCard") then
			return 1000
		end
	end,
}
--【尚儉】任一角色的結束階段，若你於此回合失去的牌不大於你的體力值，你可以摸等同於失去數量的牌。
shangjian = sgs.CreateTriggerSkill{
	name = "shangjian",
	global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				for _,id in sgs.qlist(move.card_ids) do
					room:addPlayerMark(player, "shangjian_lose_card_num-Clear")
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("shangjian_lose_card_num-Clear") > 0 then
						local lose_num = p:getMark("shangjian_lose_card_num-Clear")
						if lose_num > 0 and lose_num <= p:getHp() and room:askForSkillInvoke(p, self:objectName(), data) then
							room:notifySkillInvoked(p, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							p:drawCards(lose_num, self:objectName())
						end
					end
				end
			end
		end
		return false
	end
}
mobile_wangyuanji:addSkill(qianchong)
mobile_wangyuanji:addSkill(qianchongTM)
mobile_wangyuanji:addSkill(shangjian)

sgs.LoadTranslationTable{
	["mobile_wangyuanji"] = "王元姬",
	["&mobile_wangyuanji"] = "王元姬",
	["#mobile_wangyuanji"] = "清雅抑奢",
	["qianchong"] = "謙沖",
	[":qianchong"] = "鎖定技，如果你的裝備區所有牌均為黑色，則你獲得「帷幕」；如果你裝備區所有牌均為紅色，則你獲得「明哲」。出牌階段開始時，若你不滿足上述條件，則你選擇一種類型的牌，本回合使用此類型的牌無次數和距離限制。",
	["shangjian"] = "尚儉",
	[":shangjian"] = "任一角色的結束階段，若你於此回合失去的牌不大於你的體力值，你可以摸等同於失去數量的牌。",
["qianchong_basic"] = "基本牌無次數和距離限制",
["qianchong_trick"] = "錦囊牌無次數和距離限制",
["qianchong_equip"] = "裝備牌無次數和距離限制",
}

--手殺王允

mobile_wangyun = sgs.General(extension, "mobile_wangyun", "qun3", "3", true,true)
--[[
	技能：【连计】出牌阶段限一次，你可以依次指定两名其他角色。第一名角色随机使用牌堆里的一张武器牌，然后其视为对第二名角色随机使用一张
				  【杀】、【决斗】、【火攻】、【南蛮入侵】或【万箭齐发】。若此牌造成过伤害，你获得X枚“连计”标记（X为伤害值）。
]]--

function useSkillCard(self, player, targets)  --弥补about_to_use所缺失的技能卡该有的提示内容
	local room = player:getRoom()			  --参数[self：填self就行了; ServerPlayer *player：技能卡使用者; QList<ServerPlayer *> targets：技能卡目标角色列表]
	room:notifySkillInvoked(player, self:objectName())
	room:broadcastSkillInvoke(self:objectName())
	local msg = sgs.LogMessage()
	msg.type = "#useSkillCard"
	msg.from = player
	msg.to = targets
	msg.arg = self:objectName()
	room:sendLog(msg)
	for _, p in sgs.qlist(targets) do
		room:doAnimate(1, player:objectName(), p:objectName())
	end
end

function useEquipForWangYun(room, player, pattern, forWangYun)		--随机使用牌堆中的武器牌
	if pattern == nil then pattern = "EquipCard" end  --参数[ServerPlayer *player：武器使用者; QString pattern：使用的装备牌样式，默认值为“EquipCard”;
	if forWangYun == nil or room:getTag("HiddenQinggang"):toBool() then forWangYun = false end  --bool forWangYun：是否出现【七宝刀】，默认值为false]
	--local equips, QG_id = sgs.CardList(), -1
	local equips = {}
	local QG_id = -1
	for _, id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf(pattern) then
			--equips:append(sgs.Sanguosha:getCard(id))
			table.insert(equips, sgs.Sanguosha:getCard(id))
		end
		if forWangYun and sgs.Sanguosha:getCard(id):isKindOf("QinggangSword") then
			QG_id = id
		end
	end
	--if not equips:isEmpty() then
	if #equips > 0 then
		--local card = equips:at(math.random(0, equips:length() - 1))
		local card = equips[math.random(1, #equips)]
		if forWangYun and QG_id ~= -1 and math.random(1, 100) <= 20 and room:getTag("SGB_ID"):toInt() > 0 then
			room:setTag("HiddenQinggang", sgs.QVariant(true))
			local move = sgs.CardsMoveStruct(QG_id, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "mobile_lianji", ""))
			room:moveCardsAtomic(move, false)
			card = sgs.Sanguosha:getCard(room:getTag("SGB_ID"):toInt())
		end
		local equip_index = card:getRealCard():toEquipCard():location()
			room:useCard(sgs.CardUseStruct(card, player, player))
			return card
	end
	return nil
end

mobile_lianjiCard = sgs.CreateSkillCard{
	name = "mobile_lianji",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	about_to_use = function(self, room, use)
		local from, to = use.to:first(), use.to:last()
		useSkillCard(self, use.from, use.to)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			--useEquip(from, "Weapon", true)
			useEquipForWangYun(room, from, "Weapon", true)
			local lianji_cards = {"slash", "duel", "fire_attack", "savage_assault", "archery_attack"}
			local lianji_name = lianji_cards[math.random(1, #lianji_cards)]
			local lianji_card = sgs.Sanguosha:cloneCard(lianji_name, sgs.Card_NoSuit, 0)
			lianji_card:setSkillName("m_lianjicard")
			if not from:isProhibited(to, lianji_card) and lianji_card:isAvailable(from) and not (lianji_card:isKindOf("FireAttack") and to:isKongcheng()) then
				use.from:setTag(self:objectName(), sgs.QVariant(true))
				room:useCard(sgs.CardUseStruct(lianji_card, from, to))
				use.from:setTag(self:objectName(), sgs.QVariant(false))
			end
			lianji_card:deleteLater()
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
mobile_lianjiVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_lianji",
	view_as = function()
		return mobile_lianjiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_lianji")
	end
}
mobile_lianji = sgs.CreateTriggerSkill{
	name = "mobile_lianji",
	events = {sgs.Damage},
	view_as_skill = mobile_lianjiVS,
	on_trigger = function(self, event, player, data)
		local room, damage = player:getRoom(), data:toDamage()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if damage.card and damage.card:getSkillName() == "m_lianjicard" and p:getTag(self:objectName()):toBool() then
				room:addPlayerMark(p, "@mobile_lianji", damage.damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
mobile_wangyun:addSkill(mobile_lianji)
-- 技能：【谋逞】觉醒技，当一名角色造成伤害后，若你有至少三枚“连计”标记，则你增加1点体力上限并回复1点体力，然后失去“连计”，获得“矜功”。 --
mobile_moucheng = sgs.CreateTriggerSkill{
	name = "mobile_moucheng",
	priority = -1,
	frequency = sgs.Skill_Wake,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:getMark(self:objectName()) == 0 and (p:getMark("@mobile_lianji") >= 3 or p:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) then
				room:doSuperLightbox("mobile_wangyun","mobile_moucheng")
				room:addPlayerMark(p, self:objectName())
				room:sendCompulsoryTriggerLog(p, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				if room:changeMaxHpForAwakenSkill(p, 1) then
					room:recover(p, sgs.RecoverStruct(p))
					room:handleAcquireDetachSkills(p, "-mobile_lianji|mobile_jingong")
					room:setPlayerMark(p, "@mobile_lianji", 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
mobile_wangyun:addSkill(mobile_moucheng)
-- 技能：【矜功】出牌阶段限一次，你可以视为使用一张随机三种普通锦囊牌（其中一种为专属锦囊）中的一种牌。若如此做，此回合结束时，若你于此回合内未造成过伤害，则你失去1点体力。 --
--[[
local patterns = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and card:isNDTrick() and not table.contains(patterns, card:objectName()) then
		table.insert(patterns, card:objectName())
	end
end
]]--

mobile_jingong_select = sgs.CreateSkillCard{  --随机卡牌生成及选择技能卡
	name = "mobile_jingong_select",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	about_to_use = function(self, room, use)
		local source, choices = use.from, {}
		if source:getTag("mobile_jingong"):toString() ~= "" then
			local list = source:getTag("mobile_jingong"):toString():split("+")
			for _, patt in ipairs(list) do
				local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
				if poi:isAvailable(source) then
					table.insert(choices, patt)
				end
			end
		else
			local choiceList = {}
			local normal_tricks = {}
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and card:isNDTrick() and not table.contains(normal_tricks, card:objectName()) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
					table.insert(normal_tricks, card:objectName())
				end
			end
			for _, name in ipairs(normal_tricks) do
				if name == "meirenji" or name == "xiaolicangdao" then continue end
				local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
				if poi:isAvailable(source) and not (Set(sgs.Sanguosha:getBanPackages()))[poi:getPackage()] then
					table.insert(choiceList, name)
				end
			end
			if next(choiceList) ~= nil then
				for i = 1, 3 do
					if i == 3 then
						local wangyun_tricks = {"meirenji", "xiaolicangdao"}
						table.insert(choices, wangyun_tricks[math.random(1, #wangyun_tricks)])
						break
					end
					if next(choiceList) == nil then break end
					local choice = choiceList[math.random(1, #choiceList)]
					table.insert(choices, choice)
					table.removeOne(choiceList, choice)
				end
				source:setTag("mobile_jingong", sgs.QVariant(table.concat(choices, "+")))
			end
		end
		table.insert(choices, "cancel")
		local pattern = room:askForChoice(source, "mobile_jingong", table.concat(choices, "+"))
		if pattern and pattern ~= "cancel" then
			local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
			if poi:targetFixed() then
				poi:setSkillName("mobile_jingong")
				room:useCard(sgs.CardUseStruct(poi, source, source), true)
			else
				room:setPlayerProperty(source, "mobile_jingong", sgs.QVariant(pattern))
				room:askForUseCard(source, "@@mobile_jingong", "@mobile_jingong:" .. pattern)
			end
		end
	end
}
mobile_jingong = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_jingong",
	response_or_use = true,
	response_pattern = "@@mobile_jingong",
	view_as = function(self, card)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local skillcard = mobile_jingong_select:clone()
			return skillcard
		else
			local name = sgs.Self:property(self:objectName()):toString()
			local skillcard = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			skillcard:setSkillName(self:objectName())
			return skillcard
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("mobile_jingong_Play") > 0 then return false end
		if player:getTag(self:objectName()):toString() ~= "" then
			local list = player:getTag(self:objectName()):toString():split("+")
			for _, patt in ipairs(list) do
				local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
				if poi:isAvailable(player) then
					return true
				end
			end
		else
			local normal_tricks = {}
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and card:isNDTrick() and not table.contains(normal_tricks, card:objectName()) and player:getMark("AG_BANCard"..card:objectName()) == 0 then
					table.insert(normal_tricks, card:objectName())
				end
			end
			for _, name in ipairs(normal_tricks) do
				local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
				if poi:isAvailable(player) then
					return true
				end
			end
			local wangyun_tricks = {"meirenji", "xiaolicangdao"}
			for _, trick in ipairs(wangyun_tricks) do
				local poi = sgs.Sanguosha:cloneCard(trick, sgs.Card_NoSuit, -1)
				if poi:isAvailable(player) then
					return true
				end
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("mobile_jingong") then skills:append(mobile_jingong) end
mobile_wangyun:addRelateSkill("mobile_jingong")

turn_end_trigger = sgs.CreateTriggerSkill{  --回合结束时触发效果
	name = "turn_end_trigger",
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, splayer, data, room)
		local change = data:toPhaseChange()
		if splayer:getMark("mobile_jingong") > 0 and change.to == sgs.Player_NotActive then
			if splayer:getMark("damage_record-Clear") == 0 then
				room:loseHp(splayer)
			else
				room:setPlayerMark(splayer, "damage_record-Clear", 0)
			end
			room:setPlayerMark(splayer, "mobile_jingong", 0)
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("turn_end_trigger") then skills:append(turn_end_trigger) end


sgs.LoadTranslationTable{
["mobile_wangyun"] = "手殺王允",
["&mobile_wangyun"] = "王允",
["illustrator:mobile_wangyun"] = "Thinking",
["#mobile_wangyun"] = "計隨鞘出",
["mobile_lianji"] = "連計",
["m_lianjicard"] = "連計",
["@mobile_lianji"] = "連計",
[":mobile_lianji"] = "出牌階段限一次，你可以依次指定兩名其他角色。第一名角色隨機使用牌堆裡的一張武器牌，然後其視為對第二名角色隨機使用一張【殺】、【決鬥】、【火攻】、【南蠻入侵】或【萬箭齊發】。若此牌造成過傷害，你獲得X枚“連計”標記（X為傷害值）。" ,
["$mobile_lianji1"] = "兩計扣用，以摧強勢。",
["$mobile_lianji2"] = "容老夫細細思量。",
["mobile_moucheng"] = "謀逞",
[":mobile_moucheng"] = "覺醒技，當一名角色造成傷害後，若你有至少三枚“連計”標記，則你增加1點體力上限並回复1點體力，然後失去“連計” ，獲得“矜功”。",
["$mobile_moucheng1"] = "董賊伏誅，天下太平！",
["$mobile_moucheng2"] = "叫天不應，叫地不靈，今天就是你的死期。",
["mobile_jingong"] = "矜功",
[":mobile_jingong"] = "出牌階段限一次，你可以視為使用一張隨機三種普通錦囊牌（其中一種為專屬錦囊）中的一種牌。若如此做，此回合結束時，若你於此回合內未造成過傷害，則你失去1點體力。",
["$mobile_jingong1"] = "董賊舊部，可盡誅之。",
["$mobile_jingong2"] = "若無老夫之謀，爾等皆化為腐土也。",
["@mobile_jingong"] = "請為【%src】選擇目標",
["~mobile_jingong"] = "按照此牌使用方式指定角色→點擊確定",
["~mobile_wangyun"] = "努力謝關東諸公，勤以國家為念。",
["#useSkillCard"] = "%from 發動了“%arg”，目標是 %to",
}

--2019嵇康
sec_jikang = sgs.General(extension, "sec_jikang", "wei2", 3, true, true)
--清弦
sec_qingxianCard = sgs.CreateSkillCard{
	name = "sec_qingxian",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getHp() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			if target:getEquips():length() < source:getEquips():length() then
				room:recover(target, sgs.RecoverStruct(target))
			elseif target:getEquips():length() == source:getEquips():length() then
				target:drawCards(1)
			elseif target:getEquips():length() > source:getEquips():length() then
				room:loseHp(target)
			end
		end
	end,
	feasible = function(self, targets)
		if self:getSubcards():length() ~= #targets then return false end
		return true
	end
}
sec_qingxian = sgs.CreateViewAsSkill{
	name = "sec_qingxian",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = sec_qingxianCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sec_qingxian")
	end
}
sec_jikang:addSkill(sec_qingxian)
--絕響
sec_juexiang = sgs.CreateTriggerSkill{
	name = "sec_juexiang",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		if death.who and death.who:objectName() == player:objectName() then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			if death.damage and death.damage.from then
				death.damage.from:throwAllEquips()
				room:loseHp(death.damage.from)
				for _, p in sgs.qlist(players) do
					if p:objectName() == death.damage.from:objectName() then
						players:removeOne(p)
					end
				end
			end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "sec_juexiang-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:handleAcquireDetachSkills(target, "canyun", true)
				local ids = sgs.IntList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					for _, card in sgs.qlist(p:getCards("ej")) do
						if card:getSuit() == sgs.Card_Club then
							ids:append(card:getEffectiveId())
						end
					end
				end
				if ids:length() > 0 then
					room:fillAG(ids)
					local card_id = room:askForAG(target, ids, true, self:objectName())
					if card_id ~= -1 then
						room:throwCard(sgs.Sanguosha:getCard(card_id), room:getCardOwner(card_id), target)
						room:handleAcquireDetachSkills(target, "sec_juexiang", true)
					end
					room:clearAG()
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
sec_jikang:addSkill(sec_juexiang)

--殘韻
canyunCard = sgs.CreateSkillCard{
	name = "canyun",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getHp() and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("canyun_target_"..sgs.Self:objectName()) == 0
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			room:setPlayerMark(target, "canyun_target_"..source:objectName(), 1)
			if target:getEquips():length() < source:getEquips():length() then
				room:recover(target, sgs.RecoverStruct(target))
			elseif target:getEquips():length() == source:getEquips():length() then
				target:drawCards(1)
			elseif target:getEquips():length() > source:getEquips():length() then
				room:loseHp(target)
			end
		end
	end,
	feasible = function(self, targets)
		if self:getSubcards():length() ~= #targets then return false end
		return true
	end
}
canyun = sgs.CreateViewAsSkill{
	name = "canyun",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = canyunCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#canyun")
	end
}
if not sgs.Sanguosha:getSkill("canyun") then skills:append(canyun) end
sec_jikang:addRelateSkill("canyun")

sgs.LoadTranslationTable{
["sec_jikang"] = "手殺嵇康",
["&sec_jikang"] = "嵇康",
["#sec_jikang"] = "峻峰孤松",
["illustrator:sec_jikang"] = "眉毛子",
["sec_qingxian"] = "清弦",
[":sec_qingxian"] = "出牌階段限一次，你可以選擇至多X名其他角色並棄置等量的牌（X為你的體力值）。這些角色依次和你比較裝備區裡的牌數：小於你的角色回复1點體力；等於你的角色摸一張牌；大於你的角色失去1點體力。若你選擇的目標等於X，你摸一張牌。",
["$sec_qingxian1"] = "撫琴撥弦，悠然自得。",
["$sec_qingxian2"] = "寄情於琴，和於天地。",
["sec_juexiang"] = "絕響",
[":sec_juexiang"] = "當你死亡時，殺死你的角色棄置其裝備區裡的所有牌並流失1點體力，然後你可以令一名其他角色獲得“殘韻”，之後其可以棄置場上一張梅花牌，若其如此做，其獲得“絕響”。",
["$sec_juexiang1"] = "此曲，不能絕矣。",
["$sec_juexiang2"] = "一曲琴音，為我送別。",
["sec_juexiang-invoke"] = "你可以發動“絕響”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["canyun"] = "殘韻",
[":canyun"] = "出牌階段限一次，你可以選擇至多X名你未選擇過的其他角色並棄置等量的牌（X為你的體力值）。這些角色依次和你比較裝備區裡的牌數：小於你的角色回复1點體力；等於你的角色摸一張牌；大於你的角色失去1點體力。若你選擇的目標等於X，你摸一張牌。",
["$canyun1"] = "撫琴撥弦，悠然自得。",
["$canyun2"] = "寄情於琴，和於天地。",
["~sec_jikang"] = "多少遺恨俱隨琴音去……",
}

--手殺于禁
mobile_yujin = sgs.General(extension, "mobile_yujin", "wei2", "4", true, true, true)

mobile_jieyue_discardcard = sgs.CreateSkillCard{
	name = "mobile_jieyue_discard",
	will_throw = true,
	target_fixed  = true,
	handling_method = sgs.Card_MethodDiscard,
	on_use = function(self, room, source, targets)

	end
}

mobile_jieyuecard = sgs.CreateSkillCard{
	name = "mobile_jieyue", 
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		if room:askForUseCard(targets[1], "@@mobile_jieyue_discard", "@mobile_jieyue_discard") then

		else
			source:drawCards(3)
		end
	end
}

mobile_jieyuevs = sgs.CreateViewAsSkill{
	name = "mobile_jieyue", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "discard") then
			local hand_chosen = 0
			local equip_chosen = 0
			for _, cd in ipairs(selected) do
				if sgs.Sanguosha:currentRoom():getCardPlace(cd:getEffectiveId()) == sgs.Player_PlaceHand then
					hand_chosen = hand_chosen + 1
				else
					equip_chosen = equip_chosen + 1
				end
			end

			if hand_chosen < sgs.Self:getHandcardNum()-1 and equip_chosen < sgs.Self:getEquips():length() - 1 then
				return true
			elseif hand_chosen == sgs.Self:getHandcardNum()-1 then
				return to_select:isEquipped()
			else
				return not to_select:isEquipped()
			end
		else
			return true
		end
	end, 
	view_as = function(self, cards)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "discard") then
			local count = sgs.Self:getHandcardNum() - 1

			local hand_chosen = 0
			local equip_chosen = 0
			for _, c in ipairs(cards) do
				if sgs.Sanguosha:currentRoom():getCardPlace(c:getEffectiveId()) == sgs.Player_PlaceHand then
					hand_chosen = hand_chosen + 1
				else
					equip_chosen = equip_chosen + 1
				end
			end

			if hand_chosen == sgs.Self:getHandcardNum()-1 and equip_chosen == sgs.Self:getEquips():length() - 1 then
				local mobile_jieyuecard = mobile_jieyue_discardcard:clone()
				for _,card in ipairs(cards) do
					mobile_jieyuecard:addSubcard(card)
				end
				mobile_jieyuecard:setSkillName(self:objectName())
				return mobile_jieyuecard
			end
		else
			if #cards == 1 then
				local mobile_jieyuecard = mobile_jieyuecard:clone()
				for _,card in ipairs(cards) do
					mobile_jieyuecard:addSubcard(card)
				end
				mobile_jieyuecard:setSkillName(self:objectName())
				return mobile_jieyuecard
			end
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@mobile_jieyue")
	end
}

mobile_jieyue = sgs.CreateTriggerSkill{
	name = "mobile_jieyue" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = mobile_jieyuevs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			room:askForUseCard(player, "@@mobile_jieyue", "@mobile_jieyue")
		end
		return false
	end
}

mobile_yujin:addSkill(mobile_jieyue)

sgs.LoadTranslationTable{
["#mobile_yujin"] = "魏武之剛",
["mobile_yujin"] = "手殺于禁",
["&mobile_yujin"] = "于禁",
["illustrator:mobile_yujin"] = "Yi章",
["mobile_jieyue"] = "節鉞",
[":mobile_jieyue"] = "結束階段開始時，你可以將一張手牌交給一名其他角色，其選擇一項：將手牌與裝備區的牌棄置至一張；或令你摸三張牌。",
["@mobile_jieyue"] = "你可以發動“<font color=\"yellow\"><b>節鉞</b></font>”",
["~mobile_jieyue"] = "選擇一張手牌並選擇一名目標角色→點擊確定",
["@mobile_jieyue_put"] = "%src 對你發動了“<font color=\"yellow\"><b>節鉞</b></font>”，你需棄置手牌與裝備區的牌，否則  %src 摸三張牌",
}


--手殺審配 群 3體力 男
mobile_shenpei = sgs.General(extension, "mobile_shenpei", "qun3", "3", true)

--【守鄴】回合限一次，當你成為其他角色使用牌的「唯一目標」時，你可與其進行對策，若你對策成功，則此牌對你無效，且此牌進入棄牌堆時改為由你獲得。

--對策的表示方法為攻擊者與審配分別顯示兩個策略，攻擊者為【全力攻城】與【分兵圍城】，審配為【開城誘敵】和【奇襲糧道】

mobile_shouye = sgs.CreateTriggerSkill{
	name = "mobile_shouye" ,
	events = {sgs.TargetConfirmed,sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and (not use.card:isKindOf("SkillCard"))
				and use.to:length() == 1 and player:getMark("mobile_shouye-Clear") == 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:setPlayerMark(player,"mobile_shouye-Clear",1) 
						room:broadcastSkillInvoke(self:objectName())
						player:setFlags("-ZhenlieTarget")
						player:setFlags("ZhenlieTarget")
						
						local choices = {"quanligongcheng", "fenbingweicheng"}
						local choice_from = room:askForChoice(use.from, "mobile_shouye", table.concat(choices, "+"))
						local choices = {"kaichengyoudi", "qixiliangdao"}
						local choice_to = room:askForChoice(player, "mobile_shouye", table.concat(choices, "+"))
						room:doSuperLightbox(choice_from,choice_from)
						room:getThread():delay(1000)
						room:doSuperLightbox(choice_to,choice_to)


						if ((choice_from == "quanligongcheng" and choice_to == "qixiliangdao") or (choice_from == "fenbingweicheng" and choice_to == "kaichengyoudi")) and player:hasFlag("ZhenlieTarget") then
							player:setFlags("-ZhenlieTarget")
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)

							if use.card:isVirtualCard() then
								for _,id in sgs.qlist(use.card:getSubcards()) do
									room:setPlayerMark(player,self:objectName()..id,1) 
								end
							else
								room:setPlayerMark(player,self:objectName()..use.card:getEffectiveId(),1)
							end

					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then	
			local move = data:toMoveOneTime()
			local ids = sgs.IntList()
			for _,id in sgs.qlist(move.card_ids) do
				if player:getMark(self:objectName()..id) > 0 and room:getCardPlace(id) == sgs.Player_DiscardPile then
					ids:append(id)
				end
			end

			if not ids:isEmpty() then
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
			end
		end
		return false
	end
}

mobile_shouye_remove = sgs.CreateTriggerSkill{
	name = "mobile_shouye_remove",
	events = {sgs.DamageComplete, sgs.CardFinished},
	priority = -100,
	global = true,
	on_trigger = function(self, event, player, data, room)
		for _, mark in sgs.list(player:getMarkNames()) do
			if string.find(mark, "mobile_shouye") and player:getMark(mark) > 0 then
				room:setPlayerMark(player, mark, 0)
			end
		end		
	end
}


if not sgs.Sanguosha:getSkill("mobile_shouye_remove") then skills:append(mobile_shouye_remove) end


--【烈直】準備階段你可以選擇至多兩名角色，依次棄置這些角色區域內的一張牌，若你受到過傷害，則直至你下個結束階段，此技能失效。

liezhiCard = sgs.CreateSkillCard{
	name = "liezhi", 
	target_fixed = false,
	filter = function(self, targets, to_select) 
		return #targets < 2 and not to_select:isNude()
	end,
	on_effect = function(self, effect) 
		if effect.to:isNude() then return end
		local id = effect.from:getRoom():askForCardChosen(effect.from, effect.to, "he", "liezhi")
		effect.from:getRoom():throwCard(id, effect.to, effect.from)
	end,
}

liezhiVS = sgs.CreateZeroCardViewAsSkill{
	name = "liezhi",
	response_pattern = "@@liezhi",
	view_as = function(self) 
		return liezhiCard:clone()
	end, 
}

liezhi = sgs.CreateTriggerSkill{
	name = "liezhi", 
	events = {sgs.EventPhaseStart,sgs.Damaged}, 
	view_as_skill = liezhiVS,
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if event ==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("liezhi_indivity") == 0 then
				room:askForUseCard(player, "@@liezhi", "@liezhi-card")
			elseif player:getPhase() == sgs.Player_Finish then
				room:setPlayerMark(player,"liezhi_indivity",0)
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.damage > 0 then
				room:setPlayerMark(player,"liezhi_indivity",1)
			end
		end
	end,
}

mobile_shenpei:addSkill(mobile_shouye)
mobile_shenpei:addSkill(liezhi)

sgs.LoadTranslationTable{
["mobile_shenpei"] = "手殺審配",
["&mobile_shenpei"] = "審配",
["#mobile_shenpei"] = "",

["mobile_shouye"] = "守鄴",
[":mobile_shouye"] = "回合限一次，當你成為其他角色使用牌的「唯一目標」時，你可與其進行對策，若你對策成功，則此牌對你無效，且此牌進入棄牌堆時改為由你獲得。",

["quanligongcheng"] = "全力攻城",
["fenbingweicheng"] = "分兵圍城",
["kaichengyoudi"] = "開城誘敵",
["qixiliangdao"] = "奇襲糧道",

["liezhi"] = "烈直",
[":liezhi"] = "準備階段你可以選擇至多兩名角色，依次棄置這些角色區域內的一張牌，若你受到過傷害，則直至你下個結束階段，此技能失效。",
["@liezhi-card"] = "你可以發動「烈直」",
["~liezhi"] = "選擇至多兩名角色，點擊確定",

}

--手殺鮑三娘
mobile_baosanniang = sgs.General(extension,"mobile_baosanniang","shu2","3",false, true)
--姝勇

shuyong = sgs.CreateTriggerSkill{
	name = "shuyong",
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
				local target = room:askForPlayerChosen(player, players, self:objectName(), "shuyong-invoke", true, true)
				if target then
					local id = room:askForCardChosen(player, target, "he", self:objectName())
					room:obtainCard(player, id, false)
					target:drawCards(1)
					room:broadcastSkillInvoke(self:objectName())
				end
			end
		end
		return false
	end
}
--鎮南
mobile_zhennan = sgs.CreateTriggerSkill{
	name = "mobile_zhennan" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.card:isKindOf("SkillCard") and use.to:contains(player) and use.from:objectName() ~= player:objectName() and use.to:length() > 1 and use.from:getHp() < use.to:length() then
				if player:canDiscard(player, "he") and room:askForCard(player, "..", "@mobile_zhennan", data, self:objectName()) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:damage(sgs.DamageStruct("mobile_zhennan", player, use.from, 1, sgs.DamageStruct_Normal))
				end
			end
		end
		return false
	end,
}
--許身

mobile_xushenCard = sgs.CreateSkillCard{
	name = "mobile_xushen",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("mobile_baosanniang","mobile_xushen")
		room:removePlayerMark(source, "@mobile_xusian")
		local n = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isMale() then
				n = n + 1
			end
		end
		room:setPlayerFlag(source,"mobile_xushen_used")
		room:loseHp(source , n)

	end,
}
mobile_xushenVS = sgs.CreateViewAsSkill{
	name = "mobile_xushen",
	n = 0,
	view_as = function(self, cards)
		local skillcard = mobile_xushenCard:clone()
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@mobile_xusian") > 0
	end
}
--[[
mobile_xushen = sgs.CreateTriggerSkill{
	name = "mobile_xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mobile_xusian",
	view_as_skill = mobile_xushenVS,
	events = {sgs.HpChanged, sgs.HpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() > 0 then
				if player:hasFlag("pre_dying") then
					room:setPlayerFlag(player, "-pre_dying")
					room:setPlayerFlag(player, "save_dying")
				else
					room:setPlayerFlag(player, "-save_dying")
				end
			elseif player:getHp() <= 0 then
				if not player:hasFlag("pre_dying") then
					room:setPlayerFlag(player, "pre_dying")
				end
			end
		elseif event == sgs.HpRecover then
			local rec = data:toRecover()
			if player:hasFlag("save_dying") and player:hasFlag("mobile_xushen_used") then
				room:setPlayerFlag(player, "-pre_dying")
				room:setPlayerFlag(player, "-mobile_xushen_used")
				if room:askForSkillInvoke(player, "mobile_xushen", data) then
					room:acquireSkill(rec.who , "wusheng_po")
					room:acquireSkill(rec.who , "dangxian")
				end
			end
		end
	end,
}
]]--

mobile_xushen = sgs.CreateTriggerSkill{
	name = "mobile_xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mobile_xushen",
	events = {sgs.TargetConfirmed, sgs.HpChanged, sgs.AskForPeachesDone},
	view_as_skill = mobile_xushenVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local source = data:toCardUse().from
			if source and source:isMale() and source:objectName() ~= player:objectName() and player:getHp() <= 0 and data:toCardUse().card:isKindOf("Peach") and player:hasSkill(self:objectName()) then
				room:addPlayerMark(source, "mobile_xushen_healer")
			end
		elseif event == sgs.HpChanged then
			if player:getHp() < 1 and player:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("mobile_xushen_healer") > 0 then
						room:setPlayerMark(p, "mobile_xushen_healer", 0)
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local healer
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("mobile_xushen_healer") > 0 then
					healer = p
					room:removePlayerMark(p, "mobile_xushen_healer")
				end
			end
			if healer and player:getMark("@mobile_xushen") > 0 and player:hasSkill(self:objectName()) and player:hasFlag("mobile_xushen_used") then
				if room:askForSkillInvoke(player, "mobile_xushen", data) then
					room:acquireSkill(healer , "wusheng_po")
					room:acquireSkill(healer , "dangxian")
				end
			end
		end
		return false
	end
}

mobile_baosanniang:addSkill(shuyong)
mobile_baosanniang:addSkill(mobile_xushen)
mobile_baosanniang:addSkill(mobile_zhennan)
sgs.LoadTranslationTable{
	["mobile_baosanniang"] = "手殺鮑三娘",
	["&mobile_baosanniang"] = "鮑三娘",
	["shuyong"] = "姝勇",
	[":shuyong"] = "當妳使用或打出【殺】時，妳可以獲得一名其他角色的一張牌，然後其摸一張牌。",
	["shuyong-invoke"] = "妳可以獲得一名其他角色的一張牌，然後其摸一張牌<br/> <b>操作提示</b>: 選擇一名與妳不同且有手牌的角色→點擊確定<br/>",
	["$shuyong1"] = "虽为女子身，不输男儿郎",
	["$shuyong2"] = "剑舞轻盈，沙场克敌",
	["mobile_zhennan"] = "鎮南",
	[":mobile_zhennan"] = "當一張牌指定妳為目標時，若此牌的目標數大於1且大於使用者的體力值，妳可棄置一張牌，對其造成一點傷害。",
	["@mobile_zhennan"] = "妳可棄置一張牌，對其造成一點傷害。",
	["$mobile_zhennan1"] = "镇守南中，夫君无忧",
	["$mobile_zhennan2"] = "与君携手，定平蛮夷",
	["mobile_xushen"] = "許身",
	[":mobile_xushen"] = "限定技，出牌階段，妳可以失去等同於男性角色數的體力，若妳以此法進入頻死狀態，妳可以令結算中對妳使用「桃」的最後一名角色獲得技能「當先」及「武聖」",
	["$mobile_xushen1"] = "救命之恩，涌泉相报",
	["$mobile_xushen2"] = "解我危难，报君华彩",
}

--[[
胡金定
仁釋：鎖定技，當你於已受傷狀態下受到"殺"造成的傷害時，你防止此傷害並獲得此"殺"，
然後扣減一點體力上限。
武緣：出牌階段限一次，你可以交給一名其他角色一張"殺"，然後你恢復一點體力，其摸一張牌；若此殺為紅色，則其額外
恢復一點體力，若此殺為屬性殺，則其額外摸一張牌。
懷子：鎖定技，你的手牌上限等於你的體力上限。
]]--
hujinding = sgs.General(extension,"hujinding","shu2","6",false)

renshi = sgs.CreateTriggerSkill{
	name = "renshi",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card:isKindOf("Slash") and player:isWounded() then
			room:loseMaxHp(player)
			player:obtainCard(damage.card)	
			room:notifySkillInvoked(player, "renshi")
			room:broadcastSkillInvoke("renshi")
			local msg = sgs.LogMessage()
			msg.type = "#AvoidDamage"
			msg.from = player
			msg.to:append(damage.from)
			msg.arg = self:objectName()
			msg.arg2 = damage.nature == sgs.DamageStruct_Fire and "fire_nature" or "thunder_nature"
			room:sendLog(msg)
			return true
		end
		return false
	end
}

wuyuanCard = sgs.CreateSkillCard{
	name = "wuyuan" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), tiger:objectName(), "wuyuan","")
		room:moveCardTo(self,tiger,sgs.Player_PlaceHand,reason, false)

		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:recover(source, sgs.RecoverStruct(source))
		if card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") then
			room:recover(tiger, sgs.RecoverStruct(source))
		end
		if card:isRed() then
			tiger:drawCards(2)
		else
			tiger:drawCards(1)
		end
	end
}
wuyuan = sgs.CreateViewAsSkill{
	name = "wuyuan" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = wuyuanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#wuyuan") < 1
	end
}

huaizi = sgs.CreateMaxCardsSkill{
	name = "huaizi", 
	frequency = sgs.Skill_Compulsory, 
	fixed_func = function(self, target)
		if target:hasSkill("huaizi") then
			return target:getMaxHp()
		end
		return -1
	end
}

hujinding:addSkill(renshi)
hujinding:addSkill(wuyuan)
hujinding:addSkill(huaizi)

sgs.LoadTranslationTable{
	["hujinding"] = "胡金定",
	["#hujinding"] = "妙筆",
	["renshi"] = "仁釋",
	[":renshi"] = "鎖定技，當你於已受傷狀態下受到「殺」造成的傷害時，你防止此傷害並獲得此「殺」"
	.."，然後扣減一點體力上限。",
	["wuyuan"] = "武緣",
	[":wuyuan"] = "出牌階段限一次，你可以交給一名其他角色一張「殺」，然後你恢復一點體力，其摸一張牌；若此殺為紅色，"
	.."則其額外恢復一點體力，若此殺為屬性殺，則其額外摸一張牌。",
	["huaizi"] = "懷子",
	[":huaizi"] = "鎖定技，你的手牌上限等於你的體力上限。",
}

--賈逵
jiakui = sgs.General(extension, "jiakui", "wei2",3,true,true)

zhongzuo = sgs.CreateTriggerSkill{
	name = "zhongzuo",
	events = {sgs.Damage,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("zhongzuo") and (p:getMark("damage_record-Clear") > 0 or p:getMark("damaged_record-Clear") > 0) then
						local q = room:askForPlayerChosen(p, room:getAlivePlayers(), "zhongzuo", "@zhongzuo-choose", true)
						if q then 
							room:notifySkillInvoked(p,self:objectName())
							room:doAnimate(1, p:objectName(), q:objectName())
							q:drawCards(2)
							if q:isWounded() then
								p:drawCards(1)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function()
		return true
	end
}

wanlan = sgs.CreateTriggerSkill{
	name = "wanlan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@wanlan",
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if player:askForSkillInvoke(self:objectName(), data) then
			room:doSuperLightbox("jiakui","wanlan")
			room:setPlayerMark(player,"@wanlan",0)
			player:throwAllCards()
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = (1 - source:getHp())
			room:recover(source, recover)
			local current = room:getCurrent()
			if current then
				local damage2 = sgs.DamageStruct()
				damage2.from = player
				damage2.to = current
				damage2.damage = 1
				room:damage(damage2)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@wanlan") > 0
				end
			end
		end
		return false
	end
}

jiakui:addSkill(zhongzuo)
jiakui:addSkill(wanlan)

sgs.LoadTranslationTable{
	["jiakui"] = "舊版賈逵",
	["&jiakui"] = "賈逵",
	["#jiakui"] = "肅齊萬里",
	["illustrator:ol_huangfusong"] = "紫喬",
	["zhongzuo"] = "忠佐",
	[":zhongzuo"] = "一名角色的回合結束時，若你於本回合內造成傷害或受到過傷害，你可令一名角色摸兩張牌"..
	"，若其已受傷，你摸一張牌。",
	["@zhongzuo-choose"] = "你可令一名角色摸兩張牌",
	["wanlan"] = "挽瀾",
	[":wanlan"] = "<font color=\"red\"><b>限定技</b></font>，當一名角色進入瀕死狀態時，你可以棄置所有手牌"..
	"並令其回復體力至1點，然後你對當前回合角色造成一點傷害",
}

--張翼
zhangyi_2020 = sgs.General(extension, "zhangyi_2020", "shu2",4)

zhiyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "zhiyi",
	response_or_use = true,
	response_pattern = "@@zhiyi",
	view_as = function()
		local patterns = generateAllCardObjectNameTablePatterns()
		local DCR = patterns[sgs.Self:getMark("zhiyipos")]
		local shortage = sgs.Sanguosha:cloneCard(DCR, sgs.Card_NoSuit, 0)
		shortage:setSkillName("zhiyi")
		return shortage
	end,
	enabled_at_play = function(self, player)
		return false
	end
}

zhiyi = sgs.CreateTriggerSkill{
	name = "zhiyi",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = zhiyiVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist( room:findPlayersBySkillName(self:objectName())) do
					local promptlist = p:property("zhiyi"):toString():split(":")
					local available_list = {}
					local can_invoke = false
					if #promptlist > 0 then
						for i = 1,#promptlist,1 do
							local class_name = promptlist[i]
							local DCR_card = sgs.Sanguosha:cloneCard(class_name, sgs.Card_NoSuit, -1)
							if DCR_card:isKindOf("BasicCard") then
								can_invoke = true
								if DCR_card:isAvailable(p) then
									table.insert(available_list,  class_name)
								end
							end
						end

						table.insert(available_list,  "cancel")
						if can_invoke then
							local patterns = generateAllCardObjectNameTablePatterns()
							local pattern = room:askForChoice(p, "zhiyi", table.concat(available_list, "+"))
							if pattern ~= "cancel" then
								local pos = getPos(patterns, pattern)
								room:setPlayerMark(p, "zhiyipos", pos)

								if not room:askForUseCard(p, "@@zhiyi", "@zhiyi:" .. pattern, -1, sgs.Card_MethodUse, false) then
									room:notifySkillInvoked(p, self:objectName())
									room:broadcastSkillInvoke(self:objectName())
									p:drawCards(1)
								end
							else
								room:notifySkillInvoked(p, self:objectName())
								room:broadcastSkillInvoke(self:objectName())
								p:drawCards(1)
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


zhangyi_2020:addSkill(zhiyi)

sgs.LoadTranslationTable{
	["zhangyi_2020"] = "張翼",
	["#zhangyi_2020"] = "亢鋭懷忠",
	["illustrator:zhangyi_2020"] = "紫喬",
	["zhiyi"] = "執義",
	["zhiyiUse"] = "執義",
	--[":zhiyi"] = "鎖定技，當你於一回合內第一次使用或打出基本牌結算後，你選擇一項：1.於當前結算後視為使用此牌；2.摸一張牌。",
	[":zhiyi"] = "鎖定技，一名角色的結束階段開始時，若你本回合內使用或打出過基本牌，則你選擇一項：1.摸一張牌。2.視為使用一張本回合內使用或打出過的基本牌。",
	["@zhiyi"] = "你可以視為使用【%src】",
	["~zhiyi"] = "按照此牌使用方式指定角色→點擊確定",

}

--陳登
chendeng = sgs.General(extension, "chendeng", "qun3",3)


zhouxuanCard = sgs.CreateSkillCard{
	name = "zhouxuan" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)
		local patterns = {}
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and card:isKindOf("BasicCard") and not table.contains(patterns, card:objectName()) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
				table.insert(patterns, card:objectName())
			end
		end
		table.insert(patterns, "EquipCard")
		table.insert(patterns, "TrickCard")
		room:setPlayerFlag(targets[1] , "zhouxuan_target")
		local choice = room:askForChoice(source , "zhouxuan", table.concat(patterns, "+"))
		room:setPlayerFlag(targets[1] , "-zhouxuan_target")
		if choice then
			room:setPlayerMark(targets[1],"zhouxuan"..source:objectName()..choice,1)
			ChoiceLog(source, choice, targets[1])
		end
	end
}
zhouxuanVS = sgs.CreateViewAsSkill{
	name = "zhouxuan" ,
	n = 1 ,
	response_pattern = "@@zhouxuan",
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = zhouxuanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
zhouxuan = sgs.CreateTriggerSkill{
	name = "zhouxuan" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = zhouxuanVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and (not player:isNude()) then
				room:askForUseCard(player, "@@zhouxuan", "zhouxuan-use", -1, sgs.Card_MethodDiscard)
			end
		end
		return false
	end
}

zhouxuanUse = sgs.CreateTriggerSkill{
	name = "zhouxuanUse",
	global = true,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (not use.card:isKindOf("SkillCard")) then
				for _, s in sgs.qlist(room:getAlivePlayers()) do
					if s:hasSkill("zhouxuan") and
					 (use.card:isKindOf("BasicCard") and player:getMark("zhouxuan"..s:objectName()..use.card:objectName()) > 0) or 
					 (use.card:isKindOf("TrickCard") and player:getMark("zhouxuan"..s:objectName().."TrickCard") > 0) or
					 (use.card:isKindOf("EquipCard") and player:getMark("zhouxuan"..s:objectName().."EquipCard") > 0) then
						local yiji_cards = room:getNCards(3, false)
						local move = sgs.CardsMoveStruct(yiji_cards, nil, s, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
									sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, s:objectName(), self:objectName(), nil))
						local moves = sgs.CardsMoveList()
						moves:append(move)
						local _guojia = sgs.SPlayerList()
						_guojia:append(s)
						room:notifyMoveCards(true, moves, false, _guojia)
						room:notifyMoveCards(false, moves, false, _guojia)
						local origin_yiji = sgs.IntList()
						for _, id in sgs.qlist(yiji_cards) do
							origin_yiji:append(id)
						end
						while room:askForYiji(s, yiji_cards, "zhouxuan", true, false, true, -1, room:getAlivePlayers()) do
							local move = sgs.CardsMoveStruct(sgs.IntList(), s, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
									sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, s:objectName(), self:objectName(), nil))
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
							if not s:isAlive() then return end
						end
						if not yiji_cards:isEmpty() then
							local move = sgs.CardsMoveStruct(yiji_cards, s, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
									sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, s:objectName(), self:objectName(), nil))
							local moves = sgs.CardsMoveList()
							moves:append(move)
							room:notifyMoveCards(true, moves, false, _guojia)
							room:notifyMoveCards(false, moves, false, _guojia)
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							for _, id in sgs.qlist(yiji_cards) do
								dummy:addSubcard(id)
							end
							s:obtainCard(dummy, false)
						end
					end
				end
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "zhouxuan") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
					end
				end
			end
		end
	end
}


if not sgs.Sanguosha:getSkill("zhouxuanUse") then skills:append(zhouxuanUse) end 


fengji = sgs.CreateTriggerSkill{
	name = "fengji" ,
	events = {sgs.GameStart,sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setPlayerMark(player,"fengji_first_round",1)
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if player:getMark("fengji_first_round") == 1 then
					room:setPlayerMark(player,"fengji_first_round",0)
				else
					if player:getHandcardNum() > player:getMark("fengji_handcard") then
						player:drawCards(2)
						room:setPlayerMark(player,"fengji_maxcard-Clear",1)
					end
				end
			elseif player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player,"fengji_handcard",player:getHandcardNum())
			end
		end
		return false
	end
}

fengjimc = sgs.CreateMaxCardsSkill{
	name = "#fengjimc",
	frequency = sgs.Skill_Compulsory, 
	fixed_func = function(self, target)
		if target:getMark("fengji_maxcard-Clear") > 0 then
			return target:getMaxHp()
		end
		return -1
	end
}

chendeng:addSkill(zhouxuan)
chendeng:addSkill(fengji)
chendeng:addSkill(fengjimc)

sgs.LoadTranslationTable{
	["chendeng"] = "陳登",
	["#chendeng"] = "雄氣壯節",
	["illustrator:chendeng"] = "紫喬",
	["zhouxuan"] = "周旋",
	["zhouxuanUse"] = "周旋",
	["zhouxuan-use"] = "你可以棄置一張牌並發動「周旋」",
	[":zhouxuan"] = "結束階段，你可以棄置一張牌，選擇一名其他角色並選擇一種非基本牌的類別或基本牌的牌名，該角色使用下一張牌時，若與你"
	.."選擇相同，你觀看牌堆頂的三張牌並交給任意角色",
	["fengji"] = "豐積",
	[":fengji"] = "鎖定技，回合開始時，若你的手牌數不小於上回合結束時的手牌數，你摸兩張牌且本回合手牌上限為你體力上限。",
	["~zhouxuan"] = "選擇一張牌，並選擇一名角色",
}	

--楊彪
yangbiao = sgs.General(extension, "yangbiao", "qun3",3)

zhaohan = sgs.CreateTriggerSkill{
	name = "zhaohan" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if player:getMark("turn") <= 4 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+1))
					local theRecover2 = sgs.RecoverStruct()
					theRecover2.recover = 1
					theRecover2.who = player
					room:recover(player, theRecover2)
				elseif player:getMark("turn") <= 7 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:loseMaxHp(player)
				end
			end
		end
	end
}

rangjieCard = sgs.CreateSkillCard{
	name = "rangjie",
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
			room:setTag("QiaobianTarget", tag)
			--local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to" .. card:objectName())
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@rangjie-to"..card:objectName())
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
rangjieVS = sgs.CreateViewAsSkill{
	name = "rangjie",
	n = 0,
	view_as = function(self, first)
		local card = rangjieCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@rangjie"
	end,
}
rangjie = sgs.CreateTriggerSkill{
	name = "rangjie",
	view_as_skill = rangjieVS,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if room:askForUseCard(player, "@@rangjie", "@rangjie", -1, sgs.Card_MethodNone) then

		else
			local choices = {"TrickCard", "BasicCard", "EquipCard"}
			local choice = room:askForChoice(player, "rangjie", table.concat(choices, "+"))
			local DPHeart = sgs.IntList()
			if room:getDrawPile():length() > 0 then
				for _, id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if choice == "BasicCard" and card:isKindOf("BasicCard") then
						DPHeart:append(id)
					end
					if choice == "TrickCard" and card:isKindOf("TrickCard") then
						DPHeart:append(id)
					end
					if choice == "EquipCard" and card:isKindOf("EquipCard") then
						DPHeart:append(id)
					end
				end
			end
			if DPHeart:length() ~= 0 then
				local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
				local getcard = sgs.Sanguosha:getCard(get_id)
				room:obtainCard(player, getcard)
			end
		end
	end,
}


yizhengcard = sgs.CreateSkillCard{
	name = "yizheng", 
	target_fixed = false, 
	will_throw = false,
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()
		local source = effect.from
		local target = effect.to
		local success = source:pindian(target, "yizheng", self)
		local data = sgs.QVariant()
		data:setValue(target)
		if success then
			room:setPlayerMark(target, "skip_draw",1)
		else
			room:loseMaxHp(source)
		end
	end,
}
yizhengvs = sgs.CreateViewAsSkill{
	name = "yizheng", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = yizhengcard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#yizheng") < 1 and (not player:isKongcheng())
	end
}
yizheng = sgs.CreateTriggerSkill{
	name = "yizheng",
	view_as_skill = yizhengvs,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_Draw and player:getMark("skip_draw") > 0 then
				room:removePlayerMark(player, "skip_draw")
				player:skip(sgs.Player_Draw)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

yangbiao:addSkill(zhaohan)
yangbiao:addSkill(rangjie)
yangbiao:addSkill(yizheng)

sgs.LoadTranslationTable{
	["yangbiao"] = "楊彪",
	["#yangbiao"] = "德彰海內",
	["illustrator:yangbiao"] = "紫喬",
	["zhaohan"] = "昭漢",
	[":zhaohan"] = "鎖定技，前四個準備階段，你加1點體力上限並回復一點體力；之後三個準備階段，你減1點體力上限。",
	["rangjie"] = "讓節",
	["@rangjie"] = "你可以移動場上的一張裝備牌，若你選擇取消，你可以選擇一種類別，並從牌堆中隨機獲得一張該類別的牌",
	["~rangjie"] = "選擇一張牌→選擇一名角色→點擊確定",
	["@rangjie-to"] = "請選擇移動【%arg】的目標角色",
	[":rangjie"] = "當你受到1點傷害後，你可以選擇一項並摸一張牌：1.移動場上一張牌；2.隨機獲得牌堆中你選擇的一種類別的牌。",
	["yizheng"] = "義爭",
	[":yizheng"] = "出牌階段限一次，你可以與一名體力值不大於你的角色拼點，若你贏，其跳過下個摸牌階段；若你沒贏，你減1點體力上限。",
}

--董承
dongcheng = sgs.General(extension, "dongcheng", "qun3", "4", true)

chengzhaoCard = sgs.CreateSkillCard{
	name = "chengzhao", 
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and (not sgs.Self:isKongcheng())
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if source:pindian(targets[1], self:objectName(), self) then
				local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("_"..self:objectName())
				source:addQinggangTag(slash)
				room:useCard(sgs.CardUseStruct(slash, source, targets[1]))
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

chengzhaoVS = sgs.CreateOneCardViewAsSkill{
	name = "chengzhao", 
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local skillcard = chengzhaoCard:clone()
		skillcard:addSubcard(card:getId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@chengzhao"
	end,
}

chengzhao = sgs.CreateTriggerSkill{
	name = "chengzhao",
--	events = {sgs.CardsMoveOneTime,sgs.DrawInitialCards,sgs.AfterDrawInitialCards},
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	view_as_skill = chengzhaoVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
--		if event == sgs.DrawInitialCards then
--			room:setPlayerFlag(player, "firstdraw")
--		elseif event == sgs.AfterDrawInitialCards then
--			room:setPlayerFlag(player, "-firstdraw")	
--		elseif event == sgs.CardsMoveOneTime then
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and (move.to:objectName() == player:objectName()
					and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
					and move.to_place == sgs.Player_PlaceHand
--					and not player:hasFlag("firstdraw"))
					and not room:getTag("FirstRound"):toBool()) then		
				room:setPlayerMark(player,"chengzhao-Clear",player:getMark("chengzhao-Clear")+move.card_ids:length())
			end	
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive and player:getMark("chengzhao-Clear") >= 2 and player:hasSkill("chengzhao") then
				room:askForUseCard(player, "@@chengzhao", "@chengzhao", -1, sgs.Card_MethodUse)	
			end		
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

dongcheng:addSkill(chengzhao)

sgs.LoadTranslationTable{
	["dongcheng"] = "董承",
	["#dongcheng"] = "瀝膽衛漢",
	["chengzhao"] = "承詔",
	[":chengzhao"] = "一名角色的結束階段，若你於此回合獲得過兩張或更多牌，則你可以與一名角色拼點：若你贏，則視為你對其"..
	"使用一張無視防具的殺。",
	["@chengzhao"] = "你可以與一名角色拼點，若你贏，則視為你對其使用一張無視防具的殺。",
	["~chengzhao"] = "選擇一張牌，並選擇一名角色",
}

--徐晃
mobile_xuhuang = sgs.General(extension, "mobile_xuhuang", "qun3", "4", true)

mobile_zhiyanCard = sgs.CreateSkillCard{
	name = "mobile_zhiyan" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if sgs.Self:getMaxHp() < sgs.Self:getHandcardNum() and #self:getSubcards() > 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		elseif sgs.Self:getMaxHp() > sgs.Self:getHandcardNum() then
			return to_select:objectName() == sgs.Self:objectName()
		end
	end,
	on_use = function(self, room, source, targets)
		if (targets[1]:objectName() == source:objectName()) and (source:getMaxHp() > source:getHandcardNum()) then
			local n = source:getMaxHp() - source:getHandcardNum()
			room:drawCards(source, n, "mobile_zhiyan")
			room:setPlayerMark(source,"beizhan_ban-Clear",1)
			room:setPlayerMark(source,"mobile_zhiyan1_play",1)
		elseif (targets[1]:objectName() ~= source:objectName()) and (source:getMaxHp() < source:getHandcardNum()) then
			room:setPlayerMark(source,"mobile_zhiyan2_play",1)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "mobile_zhiyan","")
			room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		end
	end
}

mobile_zhiyan = sgs.CreateViewAsSkill{
	name = "mobile_zhiyan" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		local n =  sgs.Self:getHandcardNum() - sgs.Self:getMaxHp()
		if sgs.Self:getMark("mobile_zhiyan2_play") == 0 then
			if #selected < n then
				return (not to_select:isEquipped())
			end
		end
	end,
	view_as = function(self, cards) 
		if (#cards == 0 and sgs.Self:getMark("mobile_zhiyan1_play") > 0) then return nil end
		local n =  sgs.Self:getHandcardNum() - sgs.Self:getMaxHp()
		if ((#cards ~= n) and (#cards ~= 0)) then return nil end
		if (#cards == n and sgs.Self:getMark("mobile_zhiyan2_play") > 0) then return nil end

		local card = mobile_zhiyanCard:clone()
		if #cards  > 0 then
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
		end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("mobile_zhiyan1_play") == 0 and player:getMaxHp() > player:getHandcardNum()) or 
		(player:getMark("mobile_zhiyan2_play") == 0 and player:getMaxHp() < player:getHandcardNum())
	end
}

mobile_xuhuang:addSkill(mobile_zhiyan)

sgs.LoadTranslationTable{
	["mobile_xuhuang"] = "手殺SP徐晃",
	["&mobile_xuhuang"] = "徐晃",

	["#mobile_xuhuang"] = "沉詳性嚴",
	["mobile_zhiyan"] = "治嚴",
	[":mobile_zhiyan"] = "出牌階段各限一次，你可以執行一項：1.將手牌摸至體力上限，然後此階段不能對其他角色使用牌；2.將X張手牌交給一名其他角色。"..
"（X為你的手牌數減體力值）",
}

--[[
張遼
威風：鎖定技，你於出牌階段內第一次使用【殺】或傷害類錦囊牌結算結束後，你將此牌置於其中一個沒“懼”的目標的武將牌旁，稱為“懼”。
其受到傷害時，移去此“懼”，然後若造成此傷害的牌與此“懼”牌名：相同，此傷害加一；不同，你獲得其一張牌。準備階段或你死亡時，移去所有“懼”
]]--

mobile_zhangliao = sgs.General(extension, "mobile_zhangliao", "qun3", "4", true)


mobile_weifeng = sgs.CreateTriggerSkill{
	name = "mobile_weifeng",
	events = {sgs.Damage,sgs.EventPhaseChanging,sgs.DamageInflicted,sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished and RIGHT(self, player) then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
			 or use.card:isKindOf("FireAttack") or use.card:isKindOf("SavageAssault")
			 or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("Drowning")) 
			and player:getPhase() == sgs.Player_Play and player:getMark("mobile_weifeng_Play") == 0 then
			 	room:setPlayerMark(player,"mobile_weifeng_Play",1)
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getPile("mobile_afraid"):length() == 0  then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "mobile_weifeng", "@mobile_weifeng-choose", true)
					if s then
						s:addToPile("mobile_afraid",use.card)

						for _, id in sgs.qlist(use.card:getSubcards()) do
							room:setPlayerMark(s,"mobile_weifeng"..player:objectName()..id,1)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging and RIGHT(self, player) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getPile("mobile_afraid"):length() > 0  then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in sgs.qlist(p:getPile("mobile_afraid")) do
							if p:getMark("mobile_weifeng"..player:objectName()..sgs.Sanguosha:getCard(id):getEffectiveId()) > 0 then
								dummy:addSubcard(id)
							end
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", p:objectName(), self:objectName(), "")
						room:throwCard(dummy, reason, nil)
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card and player:getPile("mobile_afraid"):length() > 0  then
				local same_type = false
				for _, cd in sgs.qlist(player:getPile("mobile_afraid")) do
					if sgs.Sanguosha:getCard(cd):getTypeId() == damage.card:getTypeId() then
						same_type = true
					end
				end

				if same_type then
					room:notifySkillInvoked(player, "mobile_weifeng")

					local log = sgs.LogMessage()
					log.type = "$mobile_weifeng"
					log.from = damage.to
					log.card_str = damage.card:toString()
					log.arg = self:objectName()
					room:sendLog(log)

					damage.damage = damage.damage + 1
					data:setValue(damage)
					return false
				else
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						for _, id in sgs.qlist(player:getPile("mobile_afraid")) do
							if player:getMark("mobile_weifeng"..p:objectName()..sgs.Sanguosha:getCard(id):getEffectiveId()) > 0 then
								if p:hasSkill("mobile_weifeng") and (not player:isNude()) then
									room:obtainCard(p,room:askForCardChosen(p, player, "he", "mobile_weifeng", false, sgs.Card_MethodDiscard), true)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.Death then	
			local death = data:toDeath()		
			if death.who:objectName() == player:objectName() and RIGHT(self, player) then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getPile("mobile_afraid"):length() > 0  then
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							for _, id in sgs.qlist(p:getPile("mobile_afraid")) do
								if p:getMark("mobile_weifeng"..player:objectName()..id) > 0 then
									dummy:addSubcard(id)
								end
							end
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", p:objectName(), self:objectName(), "")
							room:throwCard(dummy, reason, nil)
						end
					end
				end
			end
			return false
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}

mobile_zhangliao:addSkill(mobile_weifeng)

sgs.LoadTranslationTable{
	["mobile_zhangliao"] = "手殺SP張遼",
	["&mobile_zhangliao"] = "張遼",

	["#mobile_zhangliao"] = "蹈風飲血",

	["mobile_weifeng"] = "威風",
	[":mobile_weifeng"] = "鎖定技，你於出牌階段內第一次使用【殺】或傷害類錦囊牌結算結束後，你將此牌置於其中一個沒“懼”的目標的武將牌旁，"..
	"“懼”。其受到傷害時，移去此“懼”，然後若造成此傷害的牌與此“懼”牌名：相同，此傷害加一；不同，你獲得其一張牌。準備階段或你死亡時，"..
	"移去所有“懼”",
	["$mobile_weifeng"] = "%from 受到 “%arg” 的影響，%card 的傷害值+1",
		["@mobile_weifeng-choose"] = "將傷害牌置於其中一個沒“懼”的目標的武將牌旁",
	["mobile_afraid"] = "懼",
}

--甘寧

mobile_ganning = sgs.General(extension, "mobile_ganning", "qun3", "4", true)

function getsuitcard(player, pattern_list)
	local room = player:getRoom()
	local GetCardList = sgs.IntList()
	for i = 1,#pattern_list ,1 do
		local pattern = pattern_list[i]
		local DPHeart = sgs.IntList()
		if room:getDrawPile():length() > 0 then
			for _, id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:getSuit() == pattern then
						DPHeart:append(id)
				end
			end
		end
		if room:getDiscardPile():length() > 0 then
			for _, id in sgs.qlist(room:getDiscardPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:getSuit() == pattern then
					DPHeart:append(id)
				end
			end
		end
		if DPHeart:length() ~= 0 then
			local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
			GetCardList:append(get_id)
			local card = sgs.Sanguosha:getCard(get_id)
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

--[[
mobile_jinfanCard = sgs.CreateSkillCard{
	name = "mobile_jinfan" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:addToPile("&mobile_ling", self:getSubcards())
	end
}
mobile_jinfanVS = sgs.CreateViewAsSkill{
	name = "mobile_jinfan" ,
	n = 999 ,
	response_pattern = "@@mobile_jinfan",
	view_filter = function(self, cards, to_select)
		return (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = mobile_jinfanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}
mobile_jinfan = sgs.CreateTriggerSkill{
	name = "mobile_jinfan",
	view_as_skill = mobile_jinfanVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event ==  sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Discard and RIGHT(self, player) then
				room:askForUseCard(player, "@@mobile_jinfan", "@mobile_jinfan")
			end
		elseif event == sgs.EventPhaseChanging then
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isAlive() and p:hasSkill(self:objectName()) then
						for _, cd in sgs.qlist(p:getPile("&mobile_ling")) do
							if p:getMark("mobile_jinfan"..cd.."-Clear") > 0 then
								room:removePlayerCardLimitation(p, "use,response", sgs.Sanguosha:getCard(cd):toString())
								--room:setPlayerCardLimitation(player, "use,respond", sgs.Sanguosha:getCard(card:getId()):toString(), false)
							end
						end
					end
				end
			end
		elseif (event == sgs.PreCardUsed or event == sgs.PreCardResponded) and RIGHT(self, player) then
			local card
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if card and (not card:isKindOf("SkillCard")) then
				
					if player:getPile("&mobile_ling"):contains(card:getEffectiveId()) and card:getSuit() <= 3 then
						local use_suit = card:getSuit()
						getsuitcard(player, {use_suit})
						for _, cd in sgs.qlist(player:getPile("&mobile_ling")) do
							if sgs.Sanguosha:getCard(cd):getSuit() == use_suit then
								--room:removePlayerCardLimitation(player, "use,response", card:toString())
								room:setPlayerMark(player,"mobile_jinfan"..cd.."-Clear",1)
								room:setPlayerCardLimitation(player, "use,response", sgs.Sanguosha:getCard(cd):toString(), false)
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
]]--
mobile_jinfanCard = sgs.CreateSkillCard{
	name = "mobile_jinfan" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:addToPile("&mobile_ling", self:getSubcards())
	end
}
mobile_jinfanVS = sgs.CreateViewAsSkill{
	name = "mobile_jinfan" ,
	n = 999 ,
	response_pattern = "@@mobile_jinfan",
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		elseif #selected > 0 and #selected < 4 then
			for _,ca in sgs.list(selected) do
				if ca:getSuit() == to_select:getSuit() then return false end
			end
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = mobile_jinfanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}
mobile_jinfan = sgs.CreateTriggerSkill{
	name = "mobile_jinfan",
	view_as_skill = mobile_jinfanVS,
	frequency = sgs.Skill_NotFrequent,
	--events = {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.PreCardUsed, sgs.PreCardResponded},
	events = {sgs.EventPhaseStart,sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		if event ==  sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Discard then
				room:askForUseCard(player, "@@mobile_jinfan", "@mobile_jinfan")
			end
			--[[
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(player:getPile("&mobile_ling")) do
					dummy:addSubcard(id)
				end
				room:obtainCard(player, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName()), false)
			end
			]]--
--[[
		elseif (event == sgs.PreCardUsed or event == sgs.PreCardResponded) then
			local card
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if card and (not card:isKindOf("SkillCard")) then
				
				--if player:getPile("&mobile_ling"):contains(card:getEffectiveId()) and card:getSuit() <= 3 and player:getPhase() == sgs.Player_NotActive then
				if player:getPile("&mobile_ling"):contains(card:getEffectiveId()) and card:getSuit() <= 3 then
					local use_suit = card:getSuit()
					getsuitcard(player, {use_suit})
				end
			end
		end
		]]--
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from_places and move.from_places:contains(sgs.Player_PlaceSpecial) then
				local can_invoke = false
				for _, id in sgs.qlist(move.card_ids) do
					if player:getPile("&mobile_ling"):contains( id ) then
						local use_suit = sgs.Sanguosha:getCard(id):getSuit()
						getsuitcard(player, {use_suit})					
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
					end
				end
			end
		end
	end,
}

--射卻
mobile_sheque = sgs.CreateTriggerSkill{
	name = "mobile_sheque",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getEquips():length() > 0 then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isAlive() and p:hasSkill(self:objectName()) then
					room:setPlayerFlag(p, "mobile_shequeSlash")
					local slash = room:askForUseSlashTo(p, player, "@mobile_sheque")
					if slash then
						player:addQinggangTag(slash)
						room:setPlayerFlag(p, "-mobile_shequeSlash")
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

mobile_shequeTargetMod = sgs.CreateTargetModSkill{
	name = "#mobile_shequeTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasFlag("mobile_shequeSlash") then
			return 1000
		end
	end,
}

mobile_ganning:addSkill(mobile_jinfan)
mobile_ganning:addSkill(mobile_sheque)
mobile_ganning:addSkill(mobile_shequeTargetMod)

sgs.LoadTranslationTable{
	["mobile_ganning"] = "手殺SP甘寧",
	["&mobile_ganning"] = "甘寧",

	["#mobile_ganning"] = "鈴震沒羽",

	["mobile_jinfan"] = "錦帆",
--	[":mobile_jinfan"] = "棄牌階段開始時，你可以將任意張不同花色的手牌置於武將牌上，稱為“鈴”；你可以將“鈴”如手牌般使"..
---	"用或打出， 若為回合外，你從牌堆中隨機獲得一張與此花色相同的牌。回合開始時，你獲得所有”鈴“",
	[":mobile_jinfan"] = "棄牌階段開始時，你可將任意張手牌置於武將牌上，稱為「鈴」（每種花色的「鈴」限一張）。當你需"..
	"要使用或打出一張手牌時，你可以使用或打出一張「鈴」。當有「鈴」移動到處理區後，你從牌堆中獲得與「鈴」花色相同的一張牌。",

	["&mobile_ling"] = "鈴",
	["@mobile_jinfan"] = "你可以將任意張牌置於武將牌上。，稱為“鈴”",
	["~mobile_jinfan"] = "點選欲放置於武將牌上的牌 -> 點擊「確定」",

	["mobile_sheque"] = "射卻",
	[":mobile_sheque"] = "一名其他角色準備階段，若其裝備區有牌，你可對其使用一張【殺】（無視防具）",
	["@mobile_sheque"] = "你可對當前回合角色使用一張【殺】（無視防具）",

}

--張郃
mobile_zhanghe = sgs.General(extension, "mobile_zhanghe", "qun3", "4", true)

mobile_zhilueUseCard = sgs.CreateSkillCard{
	name = "mobile_zhilueUse",
	filter = function(self, targets, to_select)
		if sgs.Self:hasFlag("useAsSlash") then
			local targets_list = sgs.PlayerList()
			for _, target in ipairs(targets) do
				targets_list:append(target)
			end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			slash:deleteLater()
			return slash:targetFilter(targets_list, to_select, sgs.Self)
		else
			return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
		end
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		if source:hasFlag("useAsSlash") then
			source:drawCards(1)
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
					slash:setSkillName("mobile_zhilue")
					room:useCard(sgs.CardUseStruct(slash, source, targets_list))
					room:removePlayerMark(source, self:objectName().."engine")
				end
			end
		else
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
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@mobile_zhilue-to".. card:objectName())
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
		end
	end
}

mobile_zhilueCard = sgs.CreateSkillCard{
	name = "mobile_zhilue",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source,1)
		room:setPlayerMark(source,"mobile_zhilue-Clear",1)
		local choiceList = {}
		local choiceOne, choiceTwo = false, false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not choiceOne and (p:getJudgingArea():length() > 0 or p:getEquips():length() > 0) then
				choiceOne = true
				table.insert(choiceList, "mobile_zhilue_move")
			end
			if choiceTwo then continue end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("mobile_zhilue")
			if not room:isProhibited(source, p, slash) and slash:targetFilter(sgs.PlayerList(), p, source) then
				choiceTwo = true
				table.insert(choiceList, "mobile_zhilue_slash")
			end
			slash:deleteLater()
		end
		if #choiceList > 0 then
			local choice = room:askForChoice(source, self:objectName(), table.concat(choiceList, "+"))
			ChoiceLog(source, choice)
			if choice == "mobile_zhilue_move" then
				room:askForUseCard(source, "@@mobile_zhilue!", "@mobile_zhilue_moveCard")
			else
				room:setPlayerFlag(source, "useAsSlash")
				room:askForUseCard(source, "@@mobile_zhilue!", "@mobile_zhilue_SlashCard")
				room:setPlayerFlag(source, "-useAsSlash")
			end
		end
	end,
}

mobile_zhilue = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_zhilue",
	view_as = function()
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@mobile_zhilue!" then
			return mobile_zhilueUseCard:clone()
		else
			return mobile_zhilueCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_zhilue")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@mobile_zhilue!"
	end,
}

mobile_zhilueTargetMod = sgs.CreateTargetModSkill{
	name = "#mobile_zhilueTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "mobile_zhilue" then
			return 1000
		end
	end,
}

mobile_zhiluemc = sgs.CreateMaxCardsSkill{
	name = "#mobile_zhiluemc", 
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if target:getMark("mobile_zhilue-Clear") > 0 then
			return 1
		end
	end
}

mobile_zhanghe:addSkill(mobile_zhilue)
mobile_zhanghe:addSkill(mobile_zhilueTargetMod)
mobile_zhanghe:addSkill(mobile_zhiluemc)

sgs.LoadTranslationTable{
	["mobile_zhanghe"] = "手殺SP張郃",
	["&mobile_zhanghe"] = "張郃",

	["#mobile_zhanghe"] = "羽林中郎將",

	["mobile_zhilue"] = "知略",
	[":mobile_zhilue"] = "出牌階段限一次，你可以失去一點體力並令你本回合手牌上限+1，你選擇一項：1.移動場上一張牌；2.摸一張牌並視"..
	"為使用一張不計入次數限制且無距離限制的【殺】",

	["mobile_zhilue_move"] = "移動場上一張牌",
	["mobile_zhilue_slash"] = "摸一張牌並視為使用一張不計入次數限制且無距離限制的【殺】",

	["@mobile_zhilue_moveCard"] = "你可以移動場上一張牌",
	["@mobile_zhilue_SlashCard"] = "視為使用一張不計入次數限制且無距離限制的【殺】",
	["~mobile_zhilue"] = "點擊角色 -> 按下「確定」",

	["mobile_zhilueUse"] = "知略",
	["mobile_zhilueuse"] = "知略",
	["~mobile_zhilue"] = "選擇一張牌→選擇一名角色→點擊確定",
	["@mobile_zhilue-to"] = "請選擇移動【%arg】的目標角色",
}

--[[
鄭玄

整經：出牌階段限一次，“隨機”觀看牌堆“中”3~5張牌（官方描述為整理一次經典），將其中任意張置於一名角色武將牌上，其下個
準備階段獲得這些牌並跳過判定、摸牌階段，若這個角色為你，那你獲得牌的那個回合不能使用“整經”
zhengxuan zhengjing
--]]
zhengxuan = sgs.General(extension, "zhengxuan", "qun3", "3", true,true)


zhengjingUseCard = sgs.CreateSkillCard{
	name = "zhengjingUse",
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		targets[1]:addToPile("jing", self)

		if source:getPile("zhengjing_finish"):length() > 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash")
			dummy:addSubcards(source:getPile("zhengjing_finish"))
			room:throwCard(dummy, source,source)
		end
	end
}

function TrueName(card)
	if card == nil then return "" end
	if (card:objectName() == "fire_slash" or card:objectName() == "thunder_slash") then return "slash" end
	return card:objectName()
end

zhengjingCard = sgs.CreateSkillCard{
	name = "zhengjing",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local n = math.random(3,5)
		local GetCardList = sgs.IntList()
		local get_pattern = {}
		for i = 1,n,1 do
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
				room:setCardFlag(card, self:objectName())
			end
		end

		if GetCardList:length() > 0 then

			room:setTag("FirstRound" , sgs.QVariant(true))
			source:addToPile("zhengjing_finish", GetCardList, true)
			room:setTag("FirstRound" , sgs.QVariant(false))
			room:askForUseCard(source, "@@zhengjing!", "@zhengjing_useCard")
		end


	end,
}

zhengjing = sgs.CreateViewAsSkill{
	n = 999,
	name = "zhengjing",
	expand_pile = "zhengjing_finish",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@zhengjing!" then
			return sgs.Self:getPile("zhengjing_finish"):contains(to_select:getId())
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@zhengjing!" then
			if #cards == 0 then return nil end
			local skillcard = zhengjingUseCard:clone()
			for _,card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		else
			return zhengjingCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zhengjing")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@zhengjing!"
	end,
}

zhengjing_get = sgs.CreateTriggerSkill{
	name = "zhengjing_get",
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Judge then
			if player:getPile("jing"):length() > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(player:getPile("jing"))
				room:obtainCard(player, dummy, false)
				if not player:isSkipped(sgs.Player_Judge) then
					player:skip(sgs.Player_Judge)
				end
				if not player:isSkipped(sgs.Player_Draw) then
					player:skip(sgs.Player_Draw)
				end
			end
		end
		return false
	end,
}
zhengxuan:addSkill(zhengjing)


if not sgs.Sanguosha:getSkill("zhengjing_get") then skills:append(zhengjing_get) end


sgs.LoadTranslationTable{
	["zhengxuan"] = "鄭玄",
	["&zhengxuan"] = "鄭玄",

	["#zhengxuan"] = "",

	["zhengjing"] = "整經",
	["zhengjing_finish"] = "整經",
	[":zhengjing"] = "出牌階段限一次，“隨機”觀看牌堆“中”3~5張牌（官方描述為整理一次經典），將其中任意張置於一名角色武將牌上，其下個"..
"準備階段獲得這些牌並跳過判定、摸牌階段，若這個角色為你，那你獲得牌的那個回合不能使用“整經”",

	["jing"] = "經",

	["@zhengjing_useCard"] = "將其中任意張置於一名角色武將牌上",
	["zhengjinguse"] = "整經",

}

--[[
手殺張恭

--]]

mobile_zhanggong = sgs.General(extension, "mobile_zhanggong", "wei2", "3", true, true)

mobile_qianxinbCard = sgs.CreateSkillCard{
	name = "mobile_qianxinb",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)

			local choices = {}
			for i = 1,self:getSubcards():length(),1 do
				local all_alive_players = {}
				for _, p in sgs.qlist(room:getOtherPlayers(source)) do
					if p:getMark("@mobile_qianxinb_target") == 0 then
						table.insert(all_alive_players, p)
					end
				end
				local random_target = all_alive_players[math.random(1, #all_alive_players)]

				local card_id = self:getSubcards():at(i-1)

				room:addPlayerMark(random_target, "mobile_qianxinb_"..random_target:objectName().."_"..card_id)
				room:setPlayerMark(random_target, "@mobile_qianxinb_target", 1)
				room:obtainCard(random_target,sgs.Sanguosha:getCard(card_id),true)
			end			
			--room:setPlayerMark(source, "qianxinb_drawpile", 1)
	end
}
mobile_qianxinbVS = sgs.CreateViewAsSkill{
	name = "mobile_qianxinb",
	n = 2,
	view_filter = function(self, selected, to_select)
		local n = 0
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			n = n + 1
		end
		return (not to_select:isEquipped()) and #selected < n
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = mobile_qianxinbCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#mobile_qianxinb"))
	end
}
mobile_qianxinb = sgs.CreateTriggerSkill{
	name = "mobile_qianxinb",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = mobile_qianxinbVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			
			if change.to and change.to == sgs.Player_Play then
				for _, c in sgs.list(player:getHandcards()) do
					if player:getMark("mobile_qianxinb_"..player:objectName().."_"..c:getEffectiveId()) > 0 then
						local log = sgs.LogMessage()
						log.type = "$mobile_qianxinb_card_in_hand"
						log.from = player
						log.arg = self:objectName()
						room:sendLog(log)
						break
					end
				end
			end
			if change.to and change.to == sgs.Player_Start then
				room:setPlayerMark(player, "@mobile_qianxinb_target", 0)
				for _, c in sgs.list(player:getHandcards()) do
					if player:getMark("mobile_qianxinb_"..player:objectName().."_"..c:getEffectiveId()) > 0 then
						local log = sgs.LogMessage()
						log.type = "$mobile_qianxinb_debuff"
						log.from = player
						log.arg = self:objectName()
						room:sendLog(log)
						
						room:setPlayerMark(player, "mobile_qianxinb_"..player:objectName().."_"..c:getEffectiveId(), 0)
						
						local choices = {"mobile_qianxinb_maxcard","mobile_qianxinb_draw"}
						for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
							if p:isAlive() then
								local _data = sgs.QVariant()
								_data:setValue(p)
								local choice = room:askForChoice(player, "mobile_qianxinb-draw-maxcard", table.concat(choices, "+"), _data)
								ChoiceLog(player, choice)
								if choice == "mobile_qianxinb_draw" then
									for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
										p:drawCards(2, self:objectName())
									end
								elseif choice == "mobile_qianxinb_maxcard" then
									room:setPlayerMark(player, "mobile_qianxinb_debuff-Clear", 1)
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

mobile_qianxinbMaxCard = sgs.CreateMaxCardsSkill{
	name = "#mobile_qianxinbCard", 
	extra_func = function(self, target)
		if target:getMark("mobile_qianxinb_debuff-Clear") > 0 then
			return -2
		end
	end
}

mobile_zhanggong:addSkill(mobile_qianxinb)
mobile_zhanggong:addSkill(mobile_qianxinbMaxCard)
mobile_zhanggong:addSkill("zhenxing")

sgs.LoadTranslationTable{
["#mobile_zhanggong"] = "西域長歌",
["mobile_zhanggong"] = "手殺張恭",
["&mobile_zhanggong"] = "張恭",
["illustrator:mobile_zzhanggong"] = "紫喬",
["mobile_qianxinb"] = "遣信",
[":mobile_qianxinb"] = "出牌階段限一次，你可以選擇至多兩張手牌，隨機交給等量名其他角色各一張，"..
"稱為“信”。若如此做，該角色準備階段時，若其手牌有“信”，其選擇一項：1.令你摸兩張牌；2.其本回合手牌上限-2。",
["$mobile_qianxinb_card_in_hand"] = "%from 手牌中有“信” (%arg 技能)",
["$mobile_qianxinb_debuff"] = "%from 手牌中有本回合獲得的“信”且是 %arg 技能目標",
["mobile_qianxinb-draw-maxcard"] = "遣信",
["mobile_qianxinb_draw"] = "令你摸兩張牌",
["mobile_qianxinb_maxcard"] = "本回合手牌上限-2",
["$mobile_qianxinb1"] = "兵困絕地，將至如歸！",
["$mobile_qianxinb2"] = "臨危之際，速速來援！",

["~mobile_zhanggong"] = "大漠孤煙，孤立無援啊。",
}

--新版賈逵
sec_rev_jiakui = sgs.General(extension, "sec_rev_jiakui", "wei2",4)

function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

tongqu = sgs.CreateTriggerSkill{
	name = "tongqu",	
	events = {sgs.GameStart,sgs.DrawNCards,sgs.EventPhaseStart,sgs.EnterDying,sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.GameStart then
			if player:hasSkill("tongqu") then
				room:addPlayerMark(player,"@mobile_qu")
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("@mobile_qu") > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local count = data:toInt() + player:getMark("@mobile_qu")
				data:setValue(count)
			end
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Draw then
				if player:getMark("@mobile_qu") > 0 then
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("@mobile_qu") > 0 then players:append(p) end
					end
					if not players:isEmpty() then
						room:setPlayerFlag(player, "tongqu_give")
						local to = room:askForPlayerChosen(player, players, "tongqu_give", "tongqu-invoke", true, true)
						room:setPlayerFlag(player, "-tongqu_give")
						local card
						if to then
							card = room:askForCard(player, "..!", "@kangkai_give:" .. to:objectName(), data, sgs.Card_MethodNone)
							if card then
									
								to:obtainCard(card)
								if card:getTypeId() == sgs.Card_TypeEquip and room:getCardOwner(card:getEffectiveId()):objectName() == to:objectName() and not to:isLocked(card) then
									--local xdata = sgs.QVariant()
									--xdata:setValue(card)
									--to:setTag("LuaKangkaiSlash", data)
									--to:setTag("LuaKangkaiGivenCard", xdata)
									local will_use = room:askForSkillInvoke(to, "kangkai_use", sgs.QVariant("use"))
									--to:removeTag("LuaKangkaiSlash")
									--to:removeTag("LuaKangkaiGivenCard")
									if will_use then
										room:useCard(sgs.CardUseStruct(card, to, to))
									end							
								end
							else
								room:askForDiscard(player, "tongqu", 1, 1, false, false)
							end
						else
							room:askForDiscard(player, "tongqu", 1, 1, false, false)
						end
					else
						room:askForDiscard(player, "tongqu", 1, 1, false, false)
					end
				end
			end					

		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Play then
				if player:hasSkill("tongqu") then

					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("@mobile_qu") == 0 then _targets:append(p) end
					end
					if not _targets:isEmpty() then
						
						local to_discard = room:askForPlayerChosen(player, _targets, "tongqu", "@tongqu", true)
						if to_discard then
							room:loseHp(player,1)
							room:doAnimate(1, player:objectName(), to_discard:objectName())
							room:setPlayerMark(to_discard,"@mobile_qu",1) 
						end
					end
				end
			end
		elseif event == sgs.EnterDying then
			if player:getMark("@mobile_qu") > 0 then
				room:setPlayerMark(player,"@mobile_qu",0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

sec_rev_wanlan = sgs.CreateTriggerSkill{
	name = "sec_rev_wanlan",
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local invoke = false
		if damage.damage >= damage.to:getHp() then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local ids = sgs.IntList()

				for _, card in sgs.qlist(p:getCards("e")) do
					if not card:isKindOf("BasicCard") then
						ids:append(card:getEffectiveId())
					end
				end

				if ids:length() >= 1 and (not invoke) then
					if room:askForSkillInvoke(p, "sec_rev_wanlan", data) then
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = nil
						move.to_place = sgs.Player_DiscardPile
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, p:objectName(), nil, "sec_rev_wanlan", nil)
						room:moveCardsAtomic(move, true)
						invoke = true
					end
				end
			end
		end
		if invoke then			
			if damage.nature ~= sgs.DamageStruct_Normal then
				room:notifySkillInvoked(player, "sec_rev_wanlan")
				room:broadcastSkillInvoke("sec_rev_wanlan")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage_wanlan"
				msg.from = p
				msg.to:append(damage.to)
				msg.arg = self:objectName()
				room:sendLog(msg)
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

sec_rev_jiakui:addSkill(tongqu)
sec_rev_jiakui:addSkill(sec_rev_wanlan)

sgs.LoadTranslationTable{
	["sec_rev_jiakui"] = "賈逵",
	["#sec_rev_jiakui"] = "肅齊萬里",
	["illustrator:sec_rev_jiakui"] = "紫喬",
	["tongqu"] = "通渠",
	["tongqu_give"] = "通渠",
	[":tongqu"] = "遊戲開始時，你擁有一個「渠」標記。出牌階段開始時，你可以失去一點體力，令一名沒有「渠」標記的角色獲得「渠」標記，有「渠」的角色"
	.."摸牌階段額外摸一張牌，然後將一張牌交給其他有「渠」的角色或棄置一張牌，若給出的是裝備牌則改為使用之。當有「渠」的角色進入瀕死狀態時，移除其「渠」標記。",
	["@mobile_qu"] = "渠",
	["@tongqu"] = "你可以令一名沒有「渠」標記的角色獲得「渠」標記",
	["@kangkai_give"] = "請交給 %src 一張牌",
	
["tongqu_throw"] = "棄置一張牌",
["tongqu_give"] = "將一張牌交給一名其他角色",
["tongqu-invoke"] = "你可以發動“通渠”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["tongqu_exchange"] = "請選擇一張牌交給對方<br/> <b>操作提示</b>: 選擇牌直到可以點確定<br/>",
	
	["sec_rev_wanlan"] = "挽瀾",
	[":sec_rev_wanlan"] = "當一名角色受到不小於其體力值的傷害時，你可以棄置裝備區內的所有牌並防止此傷害。",
	["#AvoidDamage_wanlan"] = "%from 發動技能【%arg】，防止了 %to 受到的傷害",
}

--[[
蘇飛—群—4勾玉

諍薦——鎖定技，結束階段，你選擇一名角色獲得「諍薦」標記。你的下個回合開始時，該角色摸X張牌並清除「諍薦」標記（X為其獲得標記後使用或打出牌的數量，至多為其體力上限數且不大於5）。

告援——當你成為【殺】的目標時，你可以棄一張牌，將此殺轉移給有「諍薦」標記的角色（不能是此【殺】的使用者）。

zhengjian gaoyuan

]]--
mobile_sufei = sgs.General(extension, "mobile_sufei", "qun3")

zhengjian = sgs.CreateTriggerSkill{
	name = "zhengjian",	
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Start then
				for _, p2 in sgs.qlist(room:getAlivePlayers()) do
					if p2:getMark("@zhengjian") == 1 and p2:getMark("zhengjian_can_draw"..player:objectName()) > 0 then 
						room:setPlayerMark(p2,"@zhengjian",0) 
						local n =math.min(p2:getMark("zhengjian_can_draw"..player:objectName()) - 1 , 5)
						room:setPlayerMark(p2,"zhengjian_can_draw"..player:objectName() ,0) 
						p2:drawCards(n)
					end
				end
			elseif phase ==  sgs.Player_Finish then
				local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "zhengjian", "@zhengjian-choose", true)
				if s then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), s:objectName())
					room:setPlayerMark(player,"@zhengjian",0) 
					room:setPlayerMark(s,"zhengjian_can_draw"..player:objectName(),1)
					room:setPlayerMark(s,"@zhengjian",1)
				end
			end 
		end
	end,
}


gaoyuanCard = sgs.CreateSkillCard{
	name = "gaoyuan" ,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if to_select:hasFlag("gaoyuanSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("gaoyuanSlashSource") then
				from = p
				break
			end
		end
		local slash = sgs.Card_Parse(sgs.Self:property("gaoyuan"):toString())
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		return to_select:getMark("@zhengjian") == 1
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("gaoyuanTarget")
	end
}
gaoyuanVS = sgs.CreateOneCardViewAsSkill{
	name = "gaoyuan" ,
	response_pattern = "@@gaoyuan",
	filter_pattern = ".!",
	view_as = function(self, card)
		local liuli_card = gaoyuanCard:clone()
		liuli_card:addSubcard(card)
		return liuli_card
	end
}
gaoyuan = sgs.CreateTriggerSkill{
	name = "gaoyuan" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = gaoyuanVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash")
				and use.to:contains(player) and player:canDiscard(player,"he") and (room:alivePlayerCount() > 2) then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local prompt = "@liuli:" .. use.from:objectName()
				room:setPlayerFlag(use.from, "gaoyuanSlashSource")
				room:setPlayerProperty(player, "gaoyuan", sgs.QVariant(use.card:toString()))
				if room:askForUseCard(player, "@@gaoyuan", prompt, -1, sgs.Card_MethodDiscard) then
					room:setPlayerProperty(player, "gaoyuan", sgs.QVariant())
					room:setPlayerFlag(use.from, "-gaoyuanSlashSource")
					for _, p in sgs.qlist(players) do
						if p:hasFlag("gaoyuanTarget") then
							p:setFlags("-gaoyuanTarget")
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
							return false
						end
					end
				else
					room:setPlayerProperty(player, "gaoyuan", sgs.QVariant())
					room:setPlayerFlag(use.from, "-gaoyuanSlashSource")
				end
			end
		end
		return false
	end
}

mobile_sufei:addSkill(zhengjian)
mobile_sufei:addSkill(gaoyuan)

sgs.LoadTranslationTable{
	["mobile_sufei"] = "SP星蘇飛",
	["&mobile_sufei"] = "蘇飛",
	["#mobile_sufei"] = "",
	["illustrator:mobile_sufei"] = "紫喬",

	["zhengjian"] = "諍薦",
	[":zhengjian"] = "鎖定技，結束階段，你選擇一名角色獲得「諍薦」標記。你的下個回合開始時，該角色摸X張牌並清除「諍薦」標記（X為其獲得標記後使用或打出牌的數量，至多為其體力上限數且不大於5）。",
	["@zhengjian"] = "諍薦",
	["@zhengjian-choose"] = "你可以選擇一名角色獲得「諍薦」標記",
	
	["gaoyuan"] = "告援",
	[":gaoyuan"] = "當你成為【殺】的目標時，你可以棄一張牌，將此殺轉移給有「諍薦」標記的角色（不能是此【殺】的使用者）。",
	["~gaoyuan"] = "選擇一張牌→選擇一名有「諍薦」的角色→點擊確定",
}

--[[
傅彤
【血衛】準備階段，你可以標記一名其他角色（僅自己可見）。若如此做，則直到你下回合開始前，你標記的角色第一次受到傷害時，
你防止此傷害並受到等量傷害，然後你對傷害來源造成等量的同屬性傷害。

【烈斥】鎖定技，當你進入瀕死狀態時，傷害來源棄置一張手牌。
]]--
futong = sgs.General(extension, "futong", "shu2")

xiewei = sgs.CreateTriggerSkill{
	name = "xiewei",
	events = {sgs.EventPhaseStart,sgs.DamageInflicted,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:hasSkill("xiewei") then

				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"xiewei"..player:objectName()..p:objectName(),0)
				end


				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xiewei-invoke", true)
				if target then
					room:broadcastSkillInvoke(self:objectName(), 1)		
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:setPlayerMark(target,"xiewei"..player:objectName()..target:objectName(),1)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark("xiewei"..p:objectName()..player:objectName()) == 1 then
					room:setPlayerMark(player,"xiewei"..p:objectName()..player:objectName(),0)

					room:broadcastSkillInvoke("xiewei", 2)
					room:notifySkillInvoked(player, "xiewei")
					room:sendCompulsoryTriggerLog(p, "xiewei")

					room:doAnimate(1, player:objectName(), p:objectName())
					local damage2 = sgs.DamageStruct()
					damage2.from = damage.from
					damage2.to = p
					damage2.damage = damage.damage
					damage2.nature = damage.nature
					room:damage(damage2)

					room:getThread():delay(1000)
					room:doAnimate(1, p:objectName(), damage.from:objectName())
					local damage3 = sgs.DamageStruct()
					damage3.from = p
					damage3.to = damage.from
					damage3.damage = 1
					room:damage(damage3)

					return true

				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

liechi = sgs.CreateTriggerSkill{
	name = "liechi",
	events = {sgs.EnterDying},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local dying  = data:toDying()
		local damage = dying.damage
		if damage.from then
			room:askForDiscard(damage.from, self:objectName(),1,1)
		end
		return false
	end,
}

futong:addSkill(xiewei)
futong:addSkill(liechi)

sgs.LoadTranslationTable{
	["futong"] = "傅彤",
	["#futong"] = "危漢烈義",
	["illustrator:mobile_sufei"] = "紫喬",

	["xiewei"] = "血衛",
	[":xiewei"] = "準備階段，你可以標記一名其他角色（僅自己可見）。若如此做，則直到你下回合開始前，你標記的角色第一次受到傷害時，你防止此傷害並受到等量傷害，然後你對傷害來源造成等量的同屬性傷害。",
	["xiewei-invoke"] = "你可以對一名角色發動血衛",
	
	["liechi"] = "烈斥",
	[":liechi"] = "鎖定技，當你進入瀕死狀態時，傷害來源棄置一張手牌。",
}

--手殺賀齊
--綺冑：鎖定技，你根據裝備區裡牌的花色數視為擁有以下技能：1種及以上-英姿；2種及以上-奇襲；3種及以上-旋風。
--閃襲：出牌階段開始時，你可以棄一張紅色基本牌並選擇一名其他角色，然後你將該角色的至多X張牌（X為你當前體力值）置於其武將牌上。回合結束時，其獲得這些牌。
--賀齊

mobile_heqi = sgs.General(extension,"mobile_heqi","wu2","4",true,true)

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

mobile_qizhou_fenwei_use_check = sgs.CreateTriggerSkill{
	name = "mobile_qizhou_fenwei_use_check",
	events = {sgs.CardUsed},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == "fenwei" and use.from and use.from:hasSkill("mobile_qizhou") then
			room:addPlayerMark(use.from, "used_fenwei")
		end
	end
}


if not sgs.Sanguosha:getSkill("mobile_qizhou_fenwei_use_check") then skills:append(mobile_qizhou_fenwei_use_check) end


mobile_qizhou = sgs.CreateTriggerSkill{
	name = "mobile_qizhou",
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
				equip_change_acquire_or_detach_skill(room, player, "yingzi|-qixi|-xuanfeng")
				if #suit >= 2 then
					equip_change_acquire_or_detach_skill(room, player, "yingzi|qixi|-xuanfeng")
					if #suit >= 3 then
						equip_change_acquire_or_detach_skill(room, player, "yingzi|qixi|xuanfeng")
					end
				end
			end
			if #suit == 0 then
				equip_change_acquire_or_detach_skill(room, player, "-yingzi|-qixi|-xuanfeng")
			end
			--以下有些狀況(尤其重複脫或裝裝備)會無法獲得技能
--			if #suit >= 1 then
--				room:broadcastSkillInvoke(self:objectName())
--				room:acquireSkill(player, "mashu")
--				if #suit >= 2 then
--					room:acquireSkill(player, "nosyingzi")
--					if #suit >= 3 then
--						room:acquireSkill(player, "duanbing")
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
--						room:detachSkillFromPlayer(player, "duanbing", false, true)
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
mobile_shanxiCard = sgs.CreateSkillCard{
	name = "mobile_shanxiCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select) and sgs.Self:canDiscard(to_select, "he")
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:setPlayerFlag(targets[1], "Fake_Move")
			local x = targets[1]:getHp()
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local card_ids = sgs.IntList()
			local original_places = sgs.IntList()
			for i = 0, x - 1 do
				if not source:canDiscard(targets[1], "he") then break end
				local to_throw = room:askForCardChosen(source, targets[1], "he", self:objectName(), false, sgs.Card_MethodDiscard)
				card_ids:append(to_throw)
				original_places:append(room:getCardPlace(card_ids:at(i)))
				room:throwCard(sgs.Sanguosha:getCard(to_throw), targets[1], source)
				dummy:addSubcard(card_ids:at(i))
				room:getThread():delay()
			end
			targets[1]:addToPile("pojun_po", dummy, false)
			room:setPlayerFlag(targets[1], "-Fake_Move")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

mobile_shanxiVS = sgs.CreateOneCardViewAsSkill{
	name = "mobile_shanxi",
	filter_pattern = "BasicCard|red",
	response_pattern = "@@mobile_shanxi",
	view_as = function(self, card)
		local aaa = mobile_shanxiCard:clone()
		aaa:addSubcard(card)
		return aaa
	end,
	enabled_at_play = function(self,player)
		return false
	end
}

mobile_shanxi = sgs.CreateTriggerSkill{
	name = "mobile_shanxi",
	view_as_skill = mobile_shanxiVS,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local invoke = false
		if player:getPhase() == sgs.Player_Play then
			room:askForUseCard(player, "@@mobile_shanxi", "@mobile_shanxi-card")
		end
		return false
	end
}

mobile_heqi:addSkill(mobile_qizhou)
mobile_heqi:addSkill(mobile_shanxi)

mobile_heqi:addRelateSkill("yingzi")
--heqi:addRelateSkill("nosyingzi")
mobile_heqi:addRelateSkill("qixi")
mobile_heqi:addRelateSkill("xuanfeng")

sgs.LoadTranslationTable{
	["mobile_heqi"] = "手殺賀齊",
	["#mobile_heqi"] = "",
	["&mobile_heqi"] = "賀齊",
	["mobile_qizhou"] = "綺冑",
	[":mobile_qizhou"] = "鎖定技，你根據裝備區裡牌的花色數視為擁有以下技能：1種及以上-英姿；2種及以上-奇襲；3種及以上-旋風。",
	["mobile_shanxi"] = "閃襲",
	[":mobile_shanxi"] = "出牌階段開始時，你可以棄一張紅色基本牌並選擇一名其他角色，然後你將該角色的至多X張牌（X為你當前體力值）置於其武將牌上。回合結束時，其獲得這些牌。",
	["$mobile_qizhou1"] = "人靠衣装，马靠鞍~",
	["$mobile_qizhou2"] = "可真是把好刀啊~",
	["$mobile_qizhou3"] = "我的船队，要让全建业城都看见~",
	["$mobile_shanxi1"] = "敌援未到，需要速战速决！",
	["$mobile_shanxi2"] = "快马加鞭，赶在敌人戒备之前！",

	["~mobile_shanxi"] = "結束階段，你可以然後令任意名已受傷的角色摸一張牌",
	["@mobile_shanxi-card"] = "你可以棄一張紅色基本牌並選擇一名其他角色發動「閃襲」",
}
--丁原
mobile_dingyuan = sgs.General(extension,"mobile_dingyuan","qun3","4",true,true)

beizhuCard = sgs.CreateSkillCard{
	name = "beizhuCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() 
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		room:showAllCards(effect.to,effect.from)
		for _, card in sgs.list(effect.to:getHandcards()) do
			--if card and card:isKindOf("Slash") and p:canSlash(player, card, true) then
			if card:isKindOf("Slash") then
				if not effect.to:isProhibited(effect.from, card) and effect.to:isAlive() then
					room:setCardFlag(card,"beizhu_card")
					room:useCard(sgs.CardUseStruct(card, effect.to, effect.from))
					use_slash = true
					room:setCardFlag(card,"-beizhu_card")
				end
			end
		end
		if not use_slash then
			room:setTag("Dongchaee",sgs.QVariant(effect.to:objectName()))
			room:setTag("Dongchaer",sgs.QVariant(effect.from:objectName()))
			local id = room:askForCardChosen(effect.from, effect.to, "he", "beizhu", false)
			room:throwCard(id, effect.to, effect.from)
			room:setTag("Dongchaee",sgs.QVariant())
			room:setTag("Dongchaer",sgs.QVariant())
			room:setPlayerFlag(effect.to,"beizhu_invoke")
		end
	end
}
beizhuVS = sgs.CreateViewAsSkill{
	name = "beizhu",
	n = 0 ,
	view_as = function()
		return beizhuCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#beizhuCard")
	end
}

beizhu = sgs.CreateTriggerSkill{
	name = "beizhu",
	view_as_skill = beizhuVS,
	events = {sgs.Damaged,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("beizhu_card") then
				player:drawCards(1)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("beizhuCard") and Player:hasFlag("beizhu_invoke") then
				local _data = sgs.QVariant()
				_data:setValue(use.to[1])
				if room:askForSkillInvoke(player, self:objectName(), _data) then
					getpatterncard(use.to[1], {"Slash"}, true,false )
				end
			end
		end
	end,
}

mobile_dingyuan:addSkill(beizhu)

sgs.LoadTranslationTable{
	["mobile_dingyuan"] = "丁原",
	["#mobile_dingyuan"] = "",
	["beizhu"] = "備誅",
	[":beizhu"] = "出牌階段限一次，你可以指定一名其他角色觀看其手牌。若其中沒有殺，你棄置其一張牌，然後你可以令其在牌堆中獲得一張殺；若其中有殺，則其對你依次使用這些殺，你每因此受到一點傷害後，便摸一張牌。",
}

--OL袁術
mobile_st_yuanshu = sgs.General(extension,"mobile_st_yuanshu","qun3","4",true)

mobile_wangzun = sgs.CreateTriggerSkill{
	name = "mobile_wangzun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then				
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill("mobile_wangzun") and p:getHp() < player:getHp() then
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						if player:isLord() or player:getMark("@LordMark") > 0 then
							p:drawCards(2)
							room:addPlayerMark(player,"mobile_wangzun_lord")
						else
							p:drawCards(1)
						end
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

mobile_wangzunMC = sgs.CreateMaxCardsSkill{
	name = "#mobile_wangzunMC", 
	extra_func = function(self, target)
		if target:getMark("mobile_wangzun_lord") > 0 then
			return - target:getMark("mobile_wangzun_lord")
		end
	end
}

mobile_tongjiCard = sgs.CreateSkillCard{
	name = "mobile_tongjiCard" ,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if to_select:hasFlag("mobile_tongjiSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("mobile_tongjiSlashSource") then
				from = p
				break
			end
		end
		local slash = sgs.Card_Parse(sgs.Self:property("mobile_tongji"):toString())
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		local card_id = self:getSubcards():first()
		local range_fix = 0
		if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == card_id) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif sgs.Self:getOffensiveHorse() and (sgs.Self:getOffensiveHorse():getId() == card_id) then
			range_fix = range_fix + 1
		end
		return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange() and to_select:hasSkill("mobile_tongji") 
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("mobile_tongjiTarget")
	end
}
mobile_tongjiVS = sgs.CreateOneCardViewAsSkill{
	name = "mobile_tongji" ,
	response_pattern = "@@mobile_tongji",
	filter_pattern = ".!",
	view_as = function(self, card)
		local liuli_card = mobile_tongjiCard:clone()
		liuli_card:addSubcard(card)
		return liuli_card
	end
}
mobile_tongji = sgs.CreateTriggerSkill{
	name = "mobile_tongji" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = mobile_tongjiVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash")
				and use.to:contains(player) and player:canDiscard(player,"he") and (room:alivePlayerCount() > 2) then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) and p:hasSkill("mobile_tongji") then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				local prompt = "@mobile_tongji:" .. use.from:objectName()
				room:setPlayerFlag(use.from, "mobile_tongjiSlashSource")
				room:setPlayerProperty(player, "mobile_tongji", sgs.QVariant(use.card:toString()))
				if room:askForUseCard(player, "@@mobile_tongji", prompt, -1, sgs.Card_MethodDiscard) then
					room:setPlayerProperty(player, "mobile_tongji", sgs.QVariant())
					room:setPlayerFlag(use.from, "-mobile_tongjiSlashSource")
					for _, p in sgs.qlist(players) do
						if p:hasFlag("mobile_tongjiTarget") then
							p:setFlags("-mobile_tongjiTarget")
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
							return false
						end
					end
				else
					room:setPlayerProperty(player, "mobile_tongji", sgs.QVariant())
					room:setPlayerFlag(use.from, "-mobile_tongjiSlashSource")
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

mobile_st_yuanshu:addSkill(mobile_wangzun)
mobile_st_yuanshu:addSkill(mobile_tongji)

sgs.LoadTranslationTable{
["#mobile_st_yuanshu"] = "野心漸增",
["mobile_st_yuanshu"] = "手殺袁術",
["&mobile_st_yuanshu"] = "袁術",
["illustrator:mobile_st_yuanshu"] = "LiuHeng",
["mobile_wangzun"] = "妄尊",
[":mobile_wangzun"] = "鎖定技，體力值大於你的角色的準備階段開始時，你摸一張牌；若其為主公，你多摸一張牌然後主公本回合手牌上限-1。",
["mobile_tongji"] = "同疾",
[":mobile_tongji"] = "其他角色成為【殺】的目標時，若你在其攻擊範圍內，其可以棄置一張牌並將此【殺】轉移給你。 ",
["~mobile_tongji"] = "選擇一張牌→選擇一名其他角色→點擊確定",
["@mobile_tongji"] = "%src 對你使用【殺】，你可以棄置一張牌發動“同疾”",
}

--司馬師
mobile_simashi = sgs.General(extension,"mobile_simashi","wei2","4",true)
--敗移：限定技，出牌階段，若你已受傷，你可以令兩名其他角色交換座次。

mobile_baiyiCard = sgs.CreateSkillCard{
	name = "mobile_baiyi" ,
	filter = function(self, targets, to_select)
		return #targets < 2  and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("mobile_simashi","mobile_baiyi")
		room:swapSeat(targets[1], targets[2])
		room:addPlayerMark(source,"mobile_baiyi_used")
		room:removePlayerMark(source, "@baiyi")
	end
}
mobile_baiyiVS = sgs.CreateViewAsSkill{
	name = "mobile_baiyi" ,
	n = 0 ,
	view_as = function(self, cards)
		return mobile_baiyiCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:isWounded() and player:getMark("@baiyi") > 0
	end
}
mobile_baiyi = sgs.CreateTriggerSkill{
		name = "mobile_baiyi",
		frequency = sgs.Skill_Limited,
		limit_mark = "@baiyi",
		view_as_skill = mobile_baiyiVS ,
		on_trigger = function() 
		end
}

--景略：出牌階段限一次，你可以觀看一名角色的手牌，然後將其中一張牌標記為“死士”。當該角色使用“死士”牌時，你令此牌無效；
--當“死士”牌不因使用而進入棄牌堆時，或該角色回合結束後“死士”牌在其區域內，你獲得之。

mobile_jinglueCard = sgs.CreateSkillCard{
	name = "mobile_jinglue" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() --and not to_select:isKongcheng() 如果不想选择没有手牌的角色就加上这一句，源码是没有这句的
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then--如果加上了上面的那句，这句和对应的end可以删除
			local ids = sgs.IntList()
			for _, card in sgs.qlist(effect.to:getHandcards()) do
				ids:append(card:getEffectiveId())
			end
			local card_id = room:doGongxin(effect.from, effect.to, ids)
			if (card_id == -1) then return end
			effect.from:removeTag("mobile_jinglue")
			
			effect.from:setFlags("Global_GongxinOperator")
			room:addPlayerMark(effect.to, self:objectName()..card_id..effect.from:objectName())
			effect.from:setFlags("-Global_GongxinOperator")

			room:addPlayerMark(effect.from,"mobile_jinglue_used"..effect.to:objectName())
		end
	end
}	
mobile_jinglueVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_jinglue" ,
	view_as = function()
		return mobile_jinglueCard:clone()
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#mobile_jinglue")
	end
}

mobile_jinglue = sgs.CreateTriggerSkill{
	name = "mobile_jinglue",
	events = {sgs.CardUsed,sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	view_as_skill = mobile_jinglueVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event  == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			local invoke = false
			if card and not card:isKindOf("SkillCard") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.from:getMark(self:objectName()..card:getId()..p:objectName()) > 0 then
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:getThread():delay(100)
						local msg = sgs.LogMessage()
						msg.type = "$mobile_jinglue"
						msg.from = use.from
						msg.to:append(p)
						msg.arg = self:objectName()
						room:sendLog(msg)
						room:removePlayerMark(use.from,self:objectName()..card:getId()..p:objectName())
						return true
					end
				end
				return false
			end
		elseif event  == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if move.to_place == sgs.Player_DiscardPile and move.from:objectName() == player:objectName() and not (extract == sgs.CardMoveReason_S_REASON_USE or extract == sgs.CardMoveReason_S_REASON_RESPONSE) then
				for _, id in sgs.qlist(move.card_ids) do
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark(self:objectName()..id..p:objectName()) > 0 then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							room:obtainCard(p,id)
							room:removePlayerMark(self:objectName()..card:getId()..p:objectName())
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				for _, id in sgs.qlist(player:getHandcards()) do
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark(self:objectName()..id:getEffectiveId()..p:objectName()) > 0 then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							room:obtainCard(p,id)
							room:removePlayerMark(self:objectName()..id:getEffectiveId()..p:objectName())
						end
					end
				end
				for _, id in sgs.qlist(player:getEquips()) do
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark(self:objectName()..id:getEffectiveId()..p:objectName()) > 0 then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							room:obtainCard(p,id)
							room:removePlayerMark(self:objectName()..id:getEffectiveId()..p:objectName())
						end
					end
				end
			end
		end
	end
}

--擅立：覺醒技，準備階段，若你對至少兩名角色發動過“景略”且“敗移”已發動，你減1點體力上限並選擇一名角色，然後其獲得由你選擇
--的一個主公技（三選一），並獲得新的專屬交互表情。
mobile_shanli = sgs.CreatePhaseChangeSkill{
	name = "mobile_shanli",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 then
			local n = 0
			for _, p in sgs.qlist(room:getPlayers()) do
				if player:getMark("mobile_jinglue_used"..p:objectName()) > 0 then
					n = n + 1
				end
			end
			if (n >= 2 and player:getMark("mobile_baiyi_used") > 0) or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
				room:doSuperLightbox("mobile_simashi","mobile_shanli")
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player, self:objectName())
					if room:changeMaxHpForAwakenSkill(player) then
						local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), self:objectName().."-invoke", true, true)
						if to then
							local lords = sgs.Sanguosha:getLords()
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								table.removeOne(lords, p:getGeneralName())
							end
							local lord_skills = {}
							for _, lord in ipairs(lords) do
								local general = sgs.Sanguosha:getGeneral(lord)
								local skills = general:getSkillList()
								for _, skill in sgs.qlist(skills) do
									if skill:isLordSkill() then
										if not player:hasSkill(skill:objectName()) then
											table.insert(lord_skills, skill:objectName())
										end
									end
								end
							end
							if #lord_skills > 0 then
								local choose_sks = {}
								for i = 1,3,1 do 
									if #lord_skills > 0 then
										local random1 = math.random(1, #lord_skills)
										table.insert(choose_sks, lord_skills[random1])
										table.remove(lord_skills, random1)
									end
								end
								local choices = table.concat(choose_sks, "+")
								local skill_name = room:askForChoice(player, self:objectName(), choices)
								local skill = sgs.Sanguosha:getSkill(skill_name)
								room:acquireSkill(to, skill)
								local jiemingEX = sgs.Sanguosha:getTriggerSkill(skill:objectName())
								jiemingEX:trigger(sgs.GameStart, room, to, sgs.QVariant())
							end
						end
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}

mobile_simashi:addSkill(mobile_baiyi)
mobile_simashi:addSkill(mobile_jinglue)
mobile_simashi:addSkill(mobile_shanli)

sgs.LoadTranslationTable{
["#mobile_simashi"] = "",
["mobile_simashi"] = "司馬師",
["mobile_baiyi"] = "敗移",
[":mobile_baiyi"] = "限定技，出牌階段，若你已受傷，你可以令兩名其他角色交換座次。",
["mobile_jinglue"] = "景略",
[":mobile_jinglue"] = "出牌階段限一次，你可以觀看一名角色的手牌，然後將其中一張牌標記為“死士”。當該角色使用“死士”牌時，"
.."你令此牌無效；當“死士”牌不因使用而進入棄牌堆時，或該角色回合結束後“死士”牌在其區域內，你獲得之。",
["mobile_shanli"] = "擅立",
[":mobile_shanli"] = "覺醒技，準備階段，若你對至少兩名角色發動過“景略”且“敗移”已發動，你減1點體力上限並選擇一名角色，"..
"然後其獲得由你選擇的一個主公技（三選一），並獲得新的專屬交互表情。",
["mobile_shanli-invoke"] = "選擇一名角色，其獲得由你選擇的一個主公技",

["$mobile_jinglue"] = "由於 %to 的技能 <font color=\"yellow\"><b>景略</b></font> 被觸發，%from 使用的牌無效",
}

--羊徽瑜
mobile_yanghuiyu = sgs.General(extension,"mobile_yanghuiyu","wei2",3,false)
--勸封

mobile_quanfeng = sgs.CreateTriggerSkill{
	name = "mobile_quanfeng" ,
	events = {sgs.Death,sgs.EnterDying} ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@mobile_quanfeng",
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() and player:getMark("@mobile_quanfeng") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:removePlayerMark(player, "@mobile_quanfeng")
					room:notifySkillInvoked(player, "mobile_quanfeng")
					room:broadcastSkillInvoke("mobile_quanfeng")
					room:doSuperLightbox("mobile_yanghuiyu","mobile_quanfeng")

					local skills = {}

					local general = sgs.Sanguosha:getGeneral(death.who:getGeneralName())		
					for _,sk in sgs.qlist(general:getVisibleSkillList()) do
						if not sk:isLordSkill() then
							if sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
								room:handleAcquireDetachSkills(player, sk:objectName(), false)
							end
						end
					end
					if player:hasSkill("mobile_hongyi") then
						room:detachSkillFromPlayer(player, "mobile_hongyi", true)
						room:filterCards(player, player:getCards("h"), true)
					end
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = player
					msg.arg = 1
					room:sendLog(msg)
					room:recover(player, sgs.RecoverStruct(player, nil, 1))
				end			
				return false
			end
		elseif event == sgs.EnterDying and player:getMark("@mobile_quanfeng") > 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:removePlayerMark(player, "@mobile_quanfeng")
				--room:notifySkillInvoked(player, "mobile_quanfeng")
				room:broadcastSkillInvoke("mobile_quanfeng")
				room:doSuperLightbox("mobile_yanghuiyu","mobile_quanfeng")

				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 2))
				local msg = sgs.LogMessage()
				msg.type = "#GainMaxHp"
				msg.from = player
				msg.arg = 2
				room:sendLog(msg)
				room:recover(player, sgs.RecoverStruct(player, nil, 4))
			end
		end
	end,
}

--弘儀

mobile_hongyiCard = sgs.CreateSkillCard{
	name = "mobile_hongyi",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:addPlayerMark(source,"mobile_hongyi"..targets[1]:objectName().."_target")
			room:addPlayerMark(targets[1],"@mobile_hongyi_target")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
mobile_hongyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_hongyi",
	view_as = function(self, cards)
		return mobile_hongyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#mobile_hongyi")
	end
}
mobile_hongyi = sgs.CreateTriggerSkill{
	name = "mobile_hongyi",
	events = {sgs.DamageInflicted},
	view_as_skill = mobile_hongyiVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from:getMark("@mobile_hongyi_target") > 0 then
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)

				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if damage.from:getMark("mobile_hongyi"..p:objectName().."_target") > 0 then
						local msg = sgs.LogMessage()
						msg.type = "#mobile_hongyi"
						msg.from = damage.from
						msg.to:append(p)
						msg.arg = self:objectName()
						room:sendLog(msg)
					end
				end

				if judge.card:isRed() then
					player:drawCards(1)
				elseif judge.card:isBlack() then
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
	end,
	can_trigger = function(self, target)
		return target
	end
}


mobile_yanghuiyu:addSkill(mobile_hongyi)
mobile_yanghuiyu:addSkill(mobile_quanfeng)

sgs.LoadTranslationTable{
["#mobile_yanghuiyu"] = "",
["mobile_yanghuiyu"] = "羊徽瑜",
["mobile_hongyi"] = "弘儀",
[":mobile_hongyi"] = "出牌階段限一次，妳可以選擇一名其他角色。妳的下回合開始前，該角色造成傷害時進行判定，若結果為：黑色，此傷害-1。紅色，受到傷害的角色摸一張牌。",
["mobile_quanfeng"] = "勸封",
[":mobile_quanfeng"] = "限定技。①其他角色死亡時，妳可失去〖弘儀〗，然後獲得其武將牌上的所有非主公技，非隱匿技，加1點體力上限並回復1點體力。②當妳處於瀕死狀態時，妳可以加2點體力上限，然後回復4點體力。",
["#mobile_hongyi"] = "由於 %from 造成傷害， %to 的技能 <font color=\"yellow\"><b>弘儀</b></font> 被觸發",
}

--手殺毌丘儉

mobile_guanqiujian = sgs.General(extension, "mobile_guanqiujian", "wei2", 4, true, true)

mobile_zhengrong = sgs.CreateTriggerSkill{
	name = "mobile_zhengrong",
	events = {sgs.CardFinished},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if player:getPhase() == sgs.Player_Play and ((use.to:contains(player) and use.to:length() > 2) or not use.to:contains(player)) then
			room:addPlayerMark(player,"mobile_zhengrong-Clear")
			if player:getMark("mobile_zhengrong-Clear") % 2 and player:hasSkill("mobile_zhengrong") then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isNude() then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xianfu-invoke", false, sgs.GetConfig("face_game", true))
					if to then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							local loot_cards = sgs.QList2Table(to:getCards("he"))
							if #loot_cards > 0 then
								player:addToPile("honor", loot_cards[math.random(1, #loot_cards)] )
							end
							room:removePlayerMark(player, self:objectName().."engine")
						end
					end
				end
			end
		end
		return false
	end
}
mobile_guanqiujian:addSkill(mobile_zhengrong)
mobile_hongjuCard = sgs.CreateSkillCard{
	name = "mobile_hongju",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local to_handcard = sgs.IntList()
		local to_pile = sgs.IntList()
		local set = source:getPile("honor")
		for _,id in sgs.qlist(self:getSubcards()) do
			set:append(id)
		end
		for _,id in sgs.qlist(set) do
			if not self:getSubcards():contains(id) then
				to_handcard:append(id)
			elseif not source:getPile("honor"):contains(id) then
				to_pile:append(id)
			end
		end
		assert(to_handcard:length() == to_pile:length())
		if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then return end
		room:notifySkillInvoked(source, "mobile_hongju")
		source:addToPile("honor", to_pile, false)
		local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, id in sgs.qlist(to_handcard) do
			to_handcard_x:addSubcard(id)
		end
		room:obtainCard(source, to_handcard_x, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName(), self:objectName(), ""))
	end
}
mobile_hongjuVS = sgs.CreateViewAsSkill{
	name = "mobile_hongju",
	n = 999,
	response_pattern = "@@mobile_hongju",
	expand_pile = "honor",
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getPile("honor"):length() then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getPile("honor"):length() then
			local c = mobile_hongjuCard:clone()
			for _,card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		end
		return nil
	end
}
mobile_hongju = sgs.CreatePhaseChangeSkill{
	name = "mobile_hongju",
	frequency = sgs.Skill_Wake,
	view_as_skill = mobile_hongjuVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 and (player:getPile("honor"):length() >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) then
			local invoke = false
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if p:isDead() then
					invoke = true
				end
			end
			if invoke or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player, self:objectName())
					if not player:isKongcheng() then
						room:askForUseCard(player, "@@mobile_hongju", "@mobile_hongju", -1, sgs.Card_MethodNone)
					end
					if room:changeMaxHpForAwakenSkill(player) then
						room:acquireSkill(player, "mobile_qingce")
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
mobile_guanqiujian:addSkill(mobile_hongju)
mobile_qingceCard = sgs.CreateSkillCard{
	name = "mobile_qingce",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:hasEquip() or to_select:getJudgingArea():length() > 0)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
			room:throwCard(sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", effect.to:objectName(), self:objectName(), ""), nil)
			local id = room:askForCardChosen(effect.from, effect.to, "ej", self:objectName(), false, sgs.Card_MethodDiscard)
			if id ~= -1 then
				room:throwCard(id, effect.to, effect.from)
			end
			room:removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
mobile_qingce = sgs.CreateOneCardViewAsSkill{
	name = "mobile_qingce",
	filter_pattern = ".|.|.|honor",
	expand_pile = "honor",
	view_as = function(self, card)
		local scard = mobile_qingceCard:clone()
		scard:addSubcard(card)
		return scard
	end,
	enabled_at_play = function(self, player)
		return player:getPile("honor"):length() > 0
	end
}
if not sgs.Sanguosha:getSkill("mobile_qingce") then skills:append(mobile_qingce) end
mobile_guanqiujian:addRelateSkill("mobile_qingce")

sgs.LoadTranslationTable{
	["mobile_guanqiujian"] = "手殺毌丘儉",
	["&mobile_guanqiujian"] = "毌丘儉",
	["#mobile_guanqiujian"] = "鐫功名徵榮",
	["mobile_zhengrong"] = "徵榮",
	[":mobile_zhengrong"] = "鎖定技，當你於出牌階段對其他角色使用牌結算後，若你本回合對其他角色使用牌的次數為偶數，你選擇一名其他角色 ，隨機將其一張牌置於武將牌上，稱為【榮】。",
	["$mobile_zhengrong1"] = "東徵高句麗，保遼東安穩！",
	["$mobile_zhengrong2"] = "跨海東徵，家國俱榮！",
	["honor"] = "榮",
	["mobile_zhengrong:mobile_zhengrong-invoke"] = "你可以發動「徵榮」，將 %src 的一張牌置為「榮」<br/> <b>操作提示</b>: 點擊確定<br/>",
	["mobile_hongju"] = "鴻舉",
	[":mobile_hongju"] = "覺醒技，準備階段開始時，若「榮」數不小於3且有已死亡的角色，你用任意張手牌替換等量的「榮」，然後減1點體力上限，獲得「清側」。",
	["@mobile_hongju"] = "你可以從中將與「榮」數量相同的牌置為新的「榮」",
	["~mobile_hongju"] = "選擇要替換的手牌和不需要替換的「榮」→點擊確定",
	["$mobile_hongju1"] = "一舉拿下，鴻途可得！",
	["$mobile_hongju2"] = "鴻飛榮升，舉重若輕！",
	["mobile_qingce"] = "清側",
	[":mobile_qingce"] = "出牌階段，你可以將一張「榮」置入棄牌堆並選擇一名裝備區或判定區有牌的角色，然後棄置其裝備區或判定區里的一張牌。",
	["$mobile_qingce1"] = "感明帝之恩，清君側之賊！",
	["$mobile_qingce2"] = "得太后手詔，清奸佞亂臣！",
	["~mobile_guanqiujian"] = "崢嶸一生，然被平民所擊射！",
}

--胡車兒
hucheer = sgs.General(extension, "hucheer", "qun3", 4, true)
--盜戟
daojiCard = sgs.CreateSkillCard{
	name = "daoji",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets==0 and to_select:hasEquip() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self,room,source,targets)
		local card = sgs.Sanguosha:getCard(room:askForCardChosen(source, targets[1], "e", self:objectName()))
		room:obtainCard(source, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName()), false)
		if room:getCardPlace(card:getId()) == sgs.Player_PlaceHand then
			room:useCard(sgs.CardUseStruct(card, source,source))
		end
		if card:isKindOf("Weapon") then
			room:damage(sgs.DamageStruct("daoji",source,targets[1]))
		end
	end
}

daoji = sgs.CreateOneCardViewAsSkill{
	name = "daoji",
	filter_pattern = "TrickCard,EquipCard|.",
	response_or_use = true,
	view_as = function(self, card)
		local skillcard = daojiCard:clone()
		skillcard:addSubcard(card)
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#daoji")
	end
}

hucheer:addSkill(daoji)

sgs.LoadTranslationTable{
	["hucheer"] = "胡車兒",
	["#hucheer"] = "",
	["daoji"] = "盜戟",
	[":daoji"] = "出牌階段限一次，你可以棄置一張非基本牌並選擇一名裝備區里有牌的其他角色，你獲得其裝備區中的一張牌並使用之。若你以此法獲得的牌是武器牌，則你使用此牌後對其造成1點傷害。",
}

--公孫康
gongsunkang = sgs.General(extension, "gongsunkang", "qun3", 4, true)

juliao = sgs.CreateDistanceSkill{
	name = "juliao",
	correct_func = function(self, from, to)
		if to:hasSkill("juliao") then
			local extra = 0
			local kingdom_set = {}
			table.insert(kingdom_set, to:getKingdom())
			for _, p in sgs.qlist(to:getSiblings()) do
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
			if to:hasSkill("juliao") then
				return extra - 1
			else
				return 0
			end
		end
		return 0
	end,
}


--討滅
taomie = sgs.CreateTriggerSkill{
	name = "taomie", 
	events = {sgs.Damage, sgs.Damaged,sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage or event == sgs.Damaged then
			local damage = data:toDamage()
			local target
			if event == sgs.Damage then
				target = damage.to
			elseif event == sgs.Damaged then
				target = damage.from
			end
			local _data = sgs.QVariant()
			_data:setValue(target)
			if target:getMark("@taomie") == 0 and target:isAlive() then
				if player:askForSkillInvoke(self:objectName(), _data) then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("@taomie") > 0 then
							room:removePlayerMark(p,"@taomie")
						end
					end
					room:addPlayerMark(target,"@taomie")
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.to:getMark("@taomie") > 0 then
				local choices = {"taomie1"}
				if player:canDiscard(damage.to, "he") then
					table.insert(choices, "taomie2")
					table.insert(choices, "taomie3")
				end
				table.insert(choices, "cancel")
				local choice = room:askForChoice(player , "taomie", table.concat(choices, "+"), data)
				if choice == "taomie1" or choice == "taomie3" then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
					msg.type = "#Taomie"
					msg.from = player
					msg.to:append(damage.to)
					msg.arg = tostring(damage.damage - 1)
					msg.arg2 = tostring(damage.damage)
					room:sendLog(msg)	
					data:setValue(damage)
				end
				if choice == "taomie2" or choice == "taomie3" then
					local ids = sgs.IntList()
					local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
					ids:append(id)
					room:obtainCard(player, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
					room:askForYiji(player, ids, self:objectName(), false, true, false, -1, room:getAlivePlayers())
				end
				if choice == "taomie3" then
					room:removePlayerMark(damage.to,"@taomie")
				end
			end
		end
		return false
	end
}

taomieDistance = sgs.CreateDistanceSkill{
	name = "#taomieDistance",
	correct_func = function(self, from, to)
		if (from:getMark("@taomie") > 0 and to:hasSkill("taomie")) or (to:getMark("@taomie") > 0 and from:hasSkill("taomie")) then
			return -999
		else
			return 0
		end
	end  
}

gongsunkang:addSkill(juliao)
gongsunkang:addSkill(taomie)
gongsunkang:addSkill(taomieDistance)

sgs.LoadTranslationTable{
	["gongsunkang"] = "公孫康",
	["juliao"] = "據遼",
	[":juliao"] = "鎖定技，其他角色計算與你的距離始終+X（X為場上勢力數-1）。",
	["taomie"] = "討滅",
	["@taomie"] = "討滅",
	["taomie1"] = "此傷害+1",
	["taomie2"] = "你獲得其區域內的一張牌並可將之交給另一名角色",
	["taomie3"] = "依次執行前兩項並於傷害結算後棄置其「討滅」標記。",
	[":taomie"] = "當你受到傷害後或當你造成傷害後，你可以令傷害來源或受傷角色獲得「討滅」標記"..
	"（如場上已有標記則轉換給該角色）；你與有「討滅」標記的角色的距離，與其對你的距離皆視為1；當你對有「討滅」標記的角色造成傷害時，選擇一項：1. 此傷害+1；2. 你獲得其區域內的"..
	"一張牌並可將之交給另一名角色；3. 依次執行前兩項並於傷害結算後棄置其「討滅」標記。",
	["#Taomie"] = "%from 的技能 “<font color=\"yellow\"><b>討滅</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--楊儀
yangyi = sgs.General(extension, "yangyi", "shu2", 3, true)

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

--度斷
duoduan = sgs.CreateTriggerSkill{
	name = "duoduan",
	global = true,
	events = {sgs.TargetConfirmed,sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from and  use.from:objectName() ~= player:objectName() and use.card and use.card:isKindOf("Slash") then

					if player:getMark("duoduan_target") > 0 and use.card:hasFlag("duoduan_card") then
						room:setCardFlag(use.card,"-duoduan_card")
						room:removePlayerMark(player,"duoduan_target")
						local msg = sgs.LogMessage()
						msg.type = "#zhuandui2"
						msg.from = player
						msg.to:append(use.from)
						msg.arg = "duoduan"
						msg.arg2 = use.card:objectName()
						room:sendLog(msg)
						local nullified_list = use.nullified_list
						table.insert(nullified_list,player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
			end
		elseif event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if p:hasSkill("duoduan") and p:getMark("duoduan_used-Clear") == 0 then
					local card = room:askForCard(p, "..", "@duoduan_recast", data, sgs.Card_MethodNone)
					if card then
						room:addPlayerMark(p,"duoduan_used-Clear")
						room:moveCardTo(card, p, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, p:objectName(), self:objectName(), ""))
						p:drawCards(1)
						room:broadcastSkillInvoke("@recast")
						room:notifySkillInvoked(p, "duoduan")
						room:broadcastSkillInvoke(self:objectName())
						local choice = room:askForChoice(p, self:objectName(), "duoduan1+duoduan2", data)
						ChoiceLog(p, choice)
						if choice == "duoduan1" then
							player:drawCards(2)
							room:setCardFlag(use.card,"duoduan_card")
							room:addPlayerMark(p,"duoduan_target")
						elseif choice == "duoduan2" then
							room:askForDiscard(player, self:objectName(), 1, 1, false, true)
							local msg = sgs.LogMessage()
							msg.type = "#zhuandui1"
							msg.from = player
							msg.to:append(p)
							msg.arg = "duoduan"
							msg.arg2 = use.card:objectName()
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
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

gongsunCard = sgs.CreateSkillCard{
	name = "gongsun",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, TrueName(card) )) then
				if (card:isKindOf("BasicCard") or card:isNDTrick()) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
					table.insert(choices, TrueName(card) )
				end
			end
		end
		
		if next(choices) ~= nil then
			local choice = room:askForChoice(source, "gongsun", table.concat(choices, "+"))
			local poi = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, -1)
			choice = poi:getClassName()
			local pattern = choice.."|.|.|hand"
			room:setPlayerCardLimitation(source, "use,response,discard", pattern, true)
			room:setPlayerCardLimitation(targets[1], "use,response,discard", pattern, true)
			room:setPlayerMark(source,"gongsun_to" .. targets[1]:objectName().. pattern, 1)
		end
	end
}

gongsunVS = sgs.CreateViewAsSkill{
	name = "gongsun",
	n = 2,
	view_filter = function(self, selected, to_select)
		return #selected < 2
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = gongsunCard:clone()
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@gongsun")
	end
}
gongsun = sgs.CreateTriggerSkill{
	name = "gongsun",
	view_as_skill = gongsunVS,
	events = {sgs.EventPhaseStart,sgs.Death},
	on_trigger = function(self, event, player, data, room)
		local gongsun_end = false
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				gongsun_end = true
			end
			if player:getPhase() == sgs.Player_Play then
				room:askForUseCard(player, "@@gongsun", "@gongsun", -1, sgs.Card_MethodUse)
			end
			return false
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				gongsun_end = true
			end
		end
		if gongsun_end then
			local patterns = generateAllCardObjectNameTablePatterns()
			local choices = {}
			
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
					if card:isAvailable(source) and (card:isKindOf("BasicCard") or card:isNDTrick()) and player:getMark("AG_BANCard"..card:objectName()) == 0 then
						table.insert(choices, card:objectName())
					end
				end
			end

			for _ , name in ipairs(choices) do
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("gongsun_to" .. p:objectName().. name) > 0 then
						room:removePlayerCardLimitation(player, "use,response,discard", name.."$1")
						room:removePlayerCardLimitation(p, "use,response,discard", name.."$1")
						room:setPlayerMark(player,"gongsun_to" .. p:objectName().. name, 0)
					end
				end
			end
		end
	end
}

yangyi:addSkill(duoduan)
yangyi:addSkill(gongsun)

sgs.LoadTranslationTable{
	["yangyi"] = "楊儀",
	["duoduan"] = "度斷",
	[":duoduan"] = "每回合限一次，當你成為【殺】的目標後，你可以重鑄一張牌。若如此做，你選擇一項：①令使用者摸兩張牌"
	.."，且此【殺】無效。②令使用者棄置一張牌，且你不能響應此【殺】。",
	["duoduan1"] = "令使用者摸兩張牌，且此【殺】無效。",
	["duoduan2"] = "令使用者棄置一張牌，且你不能響應此【殺】。",
	["gongsun"] = "共損",
	[":gongsun"] = "出牌階段開始時，你可以棄置兩張牌並指定一名其他角色。你選擇一個基本牌或普通錦囊牌的牌名。直到你的"
	.."下回合開始或你死亡，你與其不能使用或打出或棄置此名稱的牌。",
	["@gongsun"] = "你可以棄置兩張牌並指定一名其他角色發動“共損”",
	["#zhuandui1"] = "%from 發動技能【%arg】，%to 不可響應 %arg2 ",
	["#zhuandui2"] = "%from 發動技能【%arg】，%arg2 對 %from 無效 ",
	["~gongsun"] = "選擇兩張牌→選擇一名角色→點擊確定",
	["@duoduan_recast"] = "你可以重鑄一張牌並發動「度斷」",

}

--鄧芝
dengzhi = sgs.General(extension, "dengzhi", "shu2", 3, true)
--急盟
jimeng = sgs.CreateTriggerSkill{
	name = "jimeng",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:isNude() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "jimeng-invoke", true, true)
				if to then
					local id = room:askForCardChosen(player, to, "he", self:objectName(), false)
					room:obtainCard(player, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
					local n = player:getHp()
					local cards = room:askForExchange(player, self:objectName(), n, n, true, "@jimeng_giveback", true)
					room:obtainCard(to, cards, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, to:objectName()), false)
				end
			end
		end
		return false
	end
}
--率言
shuaiyan = sgs.CreatePhaseChangeSkill{
	name = "shuaiyan",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			--if not p:isKongcheng() then
			if not p:isNude() then
				players:append(p)
			end
		end
		if player:getPhase() == sgs.Player_Discard and player:getHandcardNum() > 1 and not players:isEmpty() then
			local to = room:askForPlayerChosen(player, players, self:objectName(), "shuaiyan-invoke", true, true)
			if to then
				room:showAllCards(player)
				room:doAnimate(1, player:objectName(), to:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local card = room:askForCard(to, "..!", "@qiai_give:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, to:objectName(), player:objectName(), self:objectName(), ""))
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}

dengzhi:addSkill(jimeng)
dengzhi:addSkill(shuaiyan)

sgs.LoadTranslationTable{
	["dengzhi"] = "鄧芝",
	["jimeng"] = "急盟",
	[":jimeng"] = "出牌階段開始時，你可以獲得一名其他角色的一張牌，然後交給該角色X張牌（X為你當前體力值）。",
	["jimeng-invoke"] = "你可以獲得一名其他角色的一張牌，然後交給該角色X張牌（X為你當前體力值）。",
	["shuaiyan"] = "率言",
	["shuaiyan-invoke"] = "令一名其他角色交給你一張牌",
	["@shuaiyan"] = "請交給發起者一張牌",
	[":shuaiyan"] = "棄牌階段開始時，若你的手牌數大於1，則你可以展示所有手牌，然後你令一名其他角色交給你一張牌。",
}

--手殺王粲
mobile_wangcan = sgs.General(extension, "mobile_wangcan", "wei2", 3, true, true)

--七哀
mobile_qiaiCard = sgs.CreateSkillCard{
	name = "mobile_qiai",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "mobile_qiai","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason, false)

		local choices = {"mobile_qiai2"}
		if source:isWounded() then
			table.insert(choices, "mobile_qiai1")
		end
			local choice = room:askForChoice(targets[1], self:objectName(), table.concat(choices, "+"))
			if choice == "mobile_qiai1" then
				room:recover(source, sgs.RecoverStruct(source, nil, 1))
			elseif choice == "mobile_qiai2" then
				source:drawCards(2)
			end
	end
}

mobile_qiai = sgs.CreateViewAsSkill{
	name = "mobile_qiai" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return not to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = mobile_qiaiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#mobile_qiai")) 
	end, 
}

mobile_wc_shanxi = sgs.CreateTriggerSkill{
	name = "mobile_wc_shanxi",	
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Play then
				if player:hasSkill("mobile_wc_shanxi") then
					local p = room:askForPlayerChosen(player, room:getOtherPlayers(player), "mobile_wc_shanxi", "@mobile_wc_shanxi", true)
					if p then
						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							if pp:getMark("@mobile_xi") == 0 then
								room:setPlayerMark(pp,"@mobile_xi",0)
								room:setPlayerMark(pp,"mobile_wc_shanxi"..player:objectName(),1) 
							end
						end
						room:doAnimate(1, player:objectName(), p:objectName())
						room:setPlayerMark(p,"@mobile_xi",1)
						room:setPlayerMark(p,"mobile_wc_shanxi"..player:objectName(),1) 
					end
				end
			end
		elseif event == sgs.HpRecover then
			if not player:isAlive() then return false end
			if player:getMark("@mobile_xi") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("mobile_wc_shanxi"..p:objectName()) == 1 and p:getHp() > 0 then
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:notifySkillInvoked(p,self:objectName())
						
						local cards = room:askForExchange(p, self:objectName(), 2, 2, true, "@mobile_wc_shanxi_give"..player:objectName(), true)
						if cards then
							room:obtainCard(player, cards, false)
						else
							room:loseHp(p)
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

mobile_wangcan:addSkill(mobile_qiai)
mobile_wangcan:addSkill(mobile_wc_shanxi)

sgs.LoadTranslationTable{
	["mobile_wangcan"] = "手殺王粲",
	["&mobile_wangcan"] = "王粲",
	["#mobile_wangcan"] = "詞章縱橫",
	["mobile_qiai"] = "七哀",
	[":mobile_qiai"] = "出牌階段限一次，你可以將一張非基本牌交給一名其他角色。然後其選擇一項：①你回復1點體力。②你摸兩張牌。",
	["mobile_qiai1"] = "你回復1點體力",
	["mobile_qiai2"] = "你摸兩張牌",
	["mobile_wc_shanxi"] = "善檄",
	[":mobile_wc_shanxi"] = "出牌階段開始時，你可令一名其他角色獲得「檄」標記並清除場上已有的其他「檄」標記（若有）。有「檄」標記的角色回復體力時，若其體力值大於0，則其需選擇一項：①交給你兩張牌。②失去1點體力。",
	["@mobile_wc_shanxi"] = "你可令一名其他角色獲得「檄」標記，並清除場上已有的其他「檄」標記。",
	["@mobile_wc_shanxi_give"] = "請交給 %src 兩張牌，否則你失去一點體力。",
	--["mobile_wc_shanxi1"] = "交給善檄的發動者兩張牌",
	--["mobile_wc_shanxi2"] = "失去1點體力",
	["mobile_xi"] = "檄",
}

--陳震
mobile_chenzhen = sgs.General(extension, "mobile_chenzhen", "shu2", 3, true, true)
--歃盟
mobile_shamengCard = sgs.CreateSkillCard{
	name = "mobile_shameng",
	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.from:drawCards(2)
		effect.to:drawCards(3)
	end
}
mobile_shameng = sgs.CreateViewAsSkill{
	name = "mobile_shameng",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			return GetColor(to_select) == GetColor(sgs.Sanguosha:getCard( selected[1] ))
		else
			return false
		end
	end,
	view_as = function(self, cards)
		local skill = mobile_shamengCard:clone()
		if #cards == 2 then
			for _, c in ipairs(cards) do
				skill:addSubcard(c)
			end
		end
		return skill
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#mobile_shameng")
	end
}

mobile_chenzhen:addSkill(mobile_shameng)

sgs.LoadTranslationTable{
	["mobile_chenzhen"] = "陳震",
	["#mobile_shameng"] = "歃盟使節",
	["mobile_shameng"] = "歃盟",
	[":mobile_shameng"] = "出牌階段限一次，你可棄置兩張顏色相同的手牌並選擇一名其他角色。其摸兩張牌，然後你摸三張牌。",
}

--駱統
mobile_luotong = sgs.General(extension, "mobile_luotong", "wu2", 4, true)

mobile_qinzheng = sgs.CreateTriggerSkill{
	name = "mobile_qinzheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
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
		if card and (not card:isKindOf("SkillCard")) and player:getMark("card_used_num") > 0 then
			if player:getMark("card_used_num") % 3 == 0 then
				getpatterncard(player, {"Slash","Jink"},true,false)
			end
			if player:getMark("card_used_num") % 5 == 0 then
				getpatterncard(player, {"Peach","Analeptic"},true,false)
			end
			if player:getMark("card_used_num") % 8 == 0 then
				getpatterncard(player, {"Duel","ExNihilo"},true,false)
			end
		end
		return false
	end
}

mobile_luotong:addSkill(mobile_qinzheng)

sgs.LoadTranslationTable{
	["mobile_luotong"] = "駱統",
	["mobile_qinzheng"] = "勤政",
	[":mobile_qinzheng"] = "鎖定技，當你使用或打出牌時，若你本局遊戲內使用或打出過的牌數和：為3的倍數，你從牌堆中獲得一張【殺】"..
	"或【閃】；為5的倍數，你從牌堆中獲得一張【桃】或【酒】；為8的倍數，你從牌堆中獲得一張【決鬥】或【無中生有】。",
}

--SP杜預
mobile_duyu = sgs.General(extension, "mobile_duyu", "qun3", 3, true)

--武庫
mobile_wuku = sgs.CreateTriggerSkill{
	name = "mobile_wuku",
	events = {sgs.CardUsed, sgs.CardResponded},
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
		if card and (not card:isKindOf("SkillCard")) and card:isKindOf("EquipCard") then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark("@mobile_wuku") < 3 then
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(p,"@mobile_wuku")
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive() 
	end
}
--三陳
mobile_sanchen = sgs.CreatePhaseChangeSkill{
	name = "mobile_sanchen",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if room:changeMaxHpForAwakenSkill(player, 1) then
			local msg = sgs.LogMessage()
			msg.type = "#mobile_sanchenWake"
			msg.from = player
			msg.to:append(player)
			msg.arg = player:getMark("@mobile_wuku")
			msg.arg2 = self:objectName()
			room:sendLog(msg)
			room:broadcastSkillInvoke("mobile_sanchen")
			room:setPlayerMark(player, self:objectName(), 1)
			room:doSuperLightbox("mobile_duyu","mobile_sanchen")	
			room:recover(player, sgs.RecoverStruct(player))
			room:acquireSkill(player, "mobile_miewu")
			
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish 
		and target:getMark(self:objectName()) == 0 and (target:getMark("@mobile_wuku") > 2 or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}
--滅吳
mobile_miewu_select = sgs.CreateSkillCard{
	name = "mobile_miewu",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
--		for _, name in ipairs(patterns) do
--			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
--			poi:setSkillName("mobile_miewu")
--			poi:addSubcard(self:getSubcards():first())
--			if poi:isAvailable(source) and source:getMark("mobile_miewu"..name) == 0 and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
--				table.insert(choices, name)
--			end
--		end
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source)  and source:getMark("AG_BANCard"..card:objectName()) == 0 and (card:isKindOf("BasicCard") or card:isKindOf("TrickCard") ) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "mobile_miewu", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("mobile_miewu")
					poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					local pos = 0
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "mobile_miewupos", pos)
					room:setPlayerProperty(source, "mobile_miewu", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@mobile_miewu", "@mobile_miewu:"..pattern)--%src
				end
			end
		end
	end
}
mobile_miewuCard = sgs.CreateSkillCard{
	name = "mobile_miewuCard",
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
			local name = room:askForChoice(user, "mobile_miewu", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("mobile_miewu")
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
			local name = room:askForChoice(card_use.from, "mobile_miewu", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("mobile_miewu")
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
mobile_miewuVS = sgs.CreateViewAsSkill{
	name = "mobile_miewu",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@mobile_miewu" then
			return false
		else return true end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = mobile_miewu_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = mobile_miewuCard:clone()
			if pattern and pattern == "@@mobile_miewu" then
				pattern = patterns[sgs.Self:getMark("mobile_miewupos")]
				acard:addSubcard(sgs.Self:property("mobile_miewu"):toInt())
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
			if poi:isAvailable(player) then
				table.insert(choices, name)
			end
		end
		return next(choices) and player:getMark("mobile_miewu-Clear") == 0 and player:getMark("@mobile_wuku") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or player:getMark("mobile_miewu-Clear") > 0 then return false end
		for _, p in pairs(pattern:split("+")) do
			return player:getMark("@mobile_wuku") > 0
		end
	end,
	enabled_at_nullification = function(self, player, pattern)
		return player:getMark("mobile_miewu-Clear") == 0 and player:getMark("@mobile_wuku") > 0
	end
}
mobile_miewu = sgs.CreateTriggerSkill{
	name = "mobile_miewu",
	view_as_skill = mobile_miewuVS,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "mobile_miewu" and not use.card:isKindOf("SkillCard") then
				room:removePlayerMark(player,"@mobile_wuku")
				room:addPlayerMark(player, "mobile_miewu-Clear")
				player:drawCards(1)
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("mobile_miewu") then skills:append(mobile_miewu) end

mobile_duyu:addSkill(mobile_wuku)
mobile_duyu:addSkill(mobile_sanchen)
mobile_duyu:addRelateSkill("mobile_miewu")

sgs.LoadTranslationTable{
	["mobile_duyu"] = "SP杜預",
	["&mobile_duyu"] = "杜預",
	["mobile_wuku"] = "武庫",
	["@mobile_wuku"] = "武庫",
	[":mobile_wuku"] = "鎖定技，當有角色使用裝備牌時，若你的「武庫」數小於3，則你獲得一個「武庫」。",
	["mobile_sanchen"] = "三陳",
	[":mobile_sanchen"] = "覺醒技，結束階段，若你的「武庫」數大於2，則你加1點體力上限並回復1點體力，然後獲得〖滅吳〗。",
	["#mobile_sanchenWake"] = "%from 擁有 %arg 個「武庫」標記，觸發“%arg2”覺醒",
	["mobile_miewu"] = "滅吳",
	[":mobile_miewu"] = "每回合限一次。你可棄置一枚「武庫」並將一張牌當做任意基本牌或錦囊牌使用，然後摸一張牌。",
	["@mobile_miewu"] = "請選擇【%src】的目標",
	["~mobile_miewu"] = "按照此牌使用方式指定角色→點擊確定",
}

--卞夫人
mobile_bianfuren = sgs.General(extension, "mobile_bianfuren", "wei2", 3, false)
--輓危
mobile_wanweiCard = sgs.CreateSkillCard{
	name = "mobile_wanwei" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)		
		local n = source:getHp() + 1
		room:recover(targets[1], sgs.RecoverStruct(targets[1], nil, n ))
		room:loseHp(source,n)
		room:addPlayerMark(source,"mobile_wanwei_turn",1)
	end
}

mobile_wanweiVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_wanwei",
	view_as = function(self,cards)
		return mobile_wanweiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("mobile_wanwei_turn") == 0
	end
}

mobile_wanwei = sgs.CreateTriggerSkill{
	name = "mobile_wanwei",
	events = {sgs.EnterDying},
	view_as_skill = mobile_wanweiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark("mobile_wanwei_turn") == 0 and player:objectName() ~= p:objectName() then
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local n = math.max(p:getHp() + 1,1 - player:getHp())

						room:recover(player, sgs.RecoverStruct(player, nil, n ))
						room:loseHp(p, (p:getHp() + 1) )
						room:addPlayerMark(p,"mobile_wanwei_turn",1)
					end
				end
			end
		end
		return false
	end
}

--約儉

mobile_yuejian = sgs.CreateTriggerSkill{
	name = "mobile_yuejian",
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			local cards = room:askForExchange(player, self:objectName(), 2, 2, true, "#mobile_yuejian", true)
			if cards then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:throwCard(cards,player,player)
				room:recover(player, sgs.RecoverStruct(player))
			end
		end
		return false
	end
}

mobile_yuejianmc = sgs.CreateMaxCardsSkill{
	name = "#mobile_yuejianmc",
	fixed_func = function(self, target)
		if target:hasSkill("mobile_yuejian") then
			return target:getMaxHp()
		end
		return -1
	end
}

mobile_bianfuren:addSkill(mobile_wanwei)
mobile_bianfuren:addSkill(mobile_yuejian)
mobile_bianfuren:addSkill(mobile_yuejianmc)

sgs.LoadTranslationTable{
	["mobile_bianfuren"] = "SP卞夫人",
	["&mobile_bianfuren"] = "卞夫人",
	["mobile_wanwei"] = "輓危",
	[":mobile_wanwei"] = "每輪累計限一次。①出牌階段，妳可選擇一名其他角色。②當有其他角色處於瀕死狀態時。妳可令該角色回復"..
	"X+1點體力（至少回復至1），然後妳失去X點體力。（X為妳的體力值）",
	["mobile_yuejian"] = "約儉",
	[":mobile_yuejian"] = "鎖定技，妳的手牌上限基數等於妳的體力上限。當妳處於瀕死狀態時，妳可棄置兩張牌，然後回復1點體力。",
	["#mobile_yuejian"] = "妳可棄置兩張牌，然後回復1點體力",
}

--吳景
mobile_wujing = sgs.General(extension,"mobile_wujing","wu2","4",true)

mobile_heji = sgs.CreateTriggerSkill{
	name = "mobile_heji",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Duel") or (use.card:isKindOf("Slash") and use.card:isRed())) and use.to:length() == 1 then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:setPlayerMark(p,"mobile_heji_from-Clear",1)
					room:setPlayerMark(use.to:first(),"mobile_heji_to-Clear",1)					
					local card = room:askForUseCard(p , "Duel,Slash,|.|.|.|.", "@mobile_heji" , -1)
					if card then
						room:setPlayerMark(p,"mobile_heji_from-Clear",0)
						room:setPlayerMark(use.to:first(),"mobile_heji_to-Clear",0)
						if (not use.card:isVirtualCard()) and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and 
							  sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):objectName() == use.card:objectName() then
							p:drawCards(1)
						end
					end
					room:setPlayerMark(p,"mobile_heji_from-Clear",0)
					room:setPlayerMark(use.to:first(),"mobile_heji_to-Clear",0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

mobile_hejiProhibit = sgs.CreateProhibitSkill{
	name = "#mobile_hejiProhibit",
	is_prohibited = function(self, from, to, card)
		return from:getMark("mobile_heji_from-Clear") > 0 and to:getMark("mobile_heji_to-Clear") == 0
	end
}

mobile_hejiTM = sgs.CreateTargetModSkill{
	name = "#mobile_hejiTM" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from)
		if from:getMark("mobile_heji_from-Clear") > 0 then
			return 1000
		end
		return 0
	end,
	residue_func = function(self, from)
		if from:getMark("mobile_heji_from-Clear") > 0 then
			return 1000
		end
		return 0
	end,
}

mobile_liubing = sgs.CreateFilterSkill{
	name = "mobile_liubing",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		return room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand and to_select:isKindOf("Slash")
	end,
	view_as = function(self, originalCard)
		local room = sgs.Sanguosha:currentRoom()
		local id = originalCard:getEffectiveId()
		local player = room:getCardOwner(id)
		if player:getMark("used_slash-Clear") == 0 then
			local new_card = sgs.Sanguosha:getWrappedCard(id)
			new_card:setSkillName("mobile_liubing")
			new_card:setSuit(sgs.Card_Diamond)
			new_card:setModified(true)
			return new_card
		else
			return originalCard
		end
	end
}

mobile_wujing:addSkill(mobile_heji)
mobile_wujing:addSkill(mobile_hejiProhibit)
mobile_wujing:addSkill(mobile_hejiTM)
mobile_wujing:addSkill(mobile_liubing)

sgs.LoadTranslationTable{
["mobile_wujing"] = "吳景",
["mobile_heji"] = "合擊",
[":mobile_heji"] = "當有角色使用的【決鬥】或紅色【殺】結算完成後，若此牌對應的目標數為1，則你可以對相同的目標使用一張【殺】或【決鬥】（無距離和次數限制）。若你以此法使用的牌不為轉化牌，則你從牌堆中獲得一張紅色牌。",
["@mobile_heji"] = "你可以對相同的目標使用一張【殺】或【決鬥】",

["mobile_liubing"] = "流兵",
[":mobile_liubing"] = "鎖定技，你於一回合所使用的第一張非虛擬【殺】視為方塊",
}

--糜夫人
nos_mobile_mifuren = sgs.General(extension,"nos_mobile_mifuren","shu2","3",false, true)
--存嗣
nos_mobile_cunsicard = sgs.CreateSkillCard{
	name = "nos_mobile_cunsi",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select) 
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "nos_mobile_cunsi")
		source:turnOver()
		getpatterncard(targets[1], {"Slash"},true, true)
		targets[1]:gainMark("@kannanBuff")
	end
}
nos_mobile_cunsi = sgs.CreateViewAsSkill{
	name = "nos_mobile_cunsi", 
	n = 0, 
	view_as = function(self, cards) 
		return nos_mobile_cunsicard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:faceUp() and not player:hasUsed("#nos_mobile_cunsi")
	end
}
--閨秀
nos_mobile_guixiu = sgs.CreateTriggerSkill{
	name = "nos_mobile_guixiu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.TurnedOver},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			if not player:faceUp() then
				player:turnOver()
			end
		elseif event == sgs.TurnedOver then
			if player:faceUp() then
				player:drawCards(1)
			end
		end
	end
}

nos_mobile_mifuren:addSkill(nos_mobile_cunsi)
nos_mobile_mifuren:addSkill(nos_mobile_guixiu)

sgs.LoadTranslationTable{
["nos_mobile_mifuren"] = "懷舊糜夫人",
["&nos_mobile_mifuren"] = "糜夫人",
["nos_mobile_cunsi"] = "存嗣",
[":nos_mobile_cunsi"] = "出牌階段限一次，你可將武將牌翻至背面並選擇一名其他角色。其從牌堆或棄牌堆中獲得一張【殺】，且下一張殺的傷害值基數+1。",
["nos_mobile_guixiu"] = "閨秀",
[":nos_mobile_guixiu"] = "鎖定技，當你受到傷害後，若你的武將牌背面朝上，則你將武將牌翻至正面。當你的武將牌從背面翻至正面時，你摸一張牌。",
}

--辛毗
mobile_xinpi = sgs.General(extension,"mobile_xinpi","wei2","3",true)

mobile_yinjuCard = sgs.CreateSkillCard{
	name = "mobile_yinju" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to,effect.from, "@mobile_yinju-slash:" .. effect.from:objectName(), false, false, false)
		end
		if (not use_slash) then
			room:addPlayerMark(effect.to , "skip_play")
			room:addPlayerMark(effect.to , "skip_discard")
		end
	end
}
mobile_yinju = sgs.CreateViewAsSkill{
	name = "mobile_yinju",
	n = 0 ,
	view_as = function()
		return mobile_yinjuCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_yinju")
	end
}

mobile_chijie = sgs.CreateTriggerSkill{
	name = "mobile_chijie" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and use.to:length() == 1 then
				if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and player:getMark("mobile_chijie-Clear") == 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:setFlags("-ZhenlieTarget")
						player:setFlags("ZhenlieTarget")
						if player:isAlive() and player:hasFlag("ZhenlieTarget") then
							player:setFlags("-ZhenlieTarget")
							room:addPlayerMark(player,"mobile_chijie-Clear")

							local judge = sgs.JudgeStruct()
							judge.who = player
							judge.reason = "mobile_chijie"
							judge.pattern = ".|.|6~13"
							room:judge(judge)
							if judge:isGood() then
								local nullified_list = use.nullified_list
								for _, _to in sgs.qlist(use.to) do
									table.insert(nullified_list, _to:objectName())
								end
								use.nullified_list = nullified_list
								data:setValue(use)
							end
						end
					end
				end
			end
		end
		return false
	end
}

mobile_xinpi:addSkill(mobile_yinju)
mobile_xinpi:addSkill(mobile_chijie)

sgs.LoadTranslationTable{
["mobile_xinpi"] = "手殺辛毗",
["&mobile_xinpi"] = "辛毗",
["mobile_yinju"] = "引裾",
[":mobile_yinju"] = "出牌階段限一次，你可令一名其他角色選擇一項：①對你使用一張【殺】。②其下個回合的準備階段開始時，跳過出牌階段和棄牌階段。",
["mobile_chijie"] = "持節",
[":mobile_chijie"] = "每回合限一次。當你成為其他角色使用牌的唯一目標時，你可判定。若結果大於6，則你取消此牌的所有目標。",
["@mobile_yinju-slash"] = "%src 對你發動“引裾”，請對其使用一張【殺】",
}

--神郭嘉
shen_guojia = sgs.General(extension,"shen_guojia","god","3",true)
--慧識

--[[出牌階段限一次，若你的體力上限小於10，你可進行判定牌不置入棄牌堆的判定。若判定結果與本次發動技能時的其他判定結果的花色
均不相同且你的體力上限小於10，則你加1點體力上限並重復此流程。然後你將所有位於處理區的判定牌交給一名角色。若其手牌數為全場
最多，則你減1點體力上限。
]]--

--[[
shuishiCard = sgs.CreateSkillCard{
	name = "shuishi", 
	filter = function(self, targets, to_select)
		return #targets == 0
	end, 
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, self:objectName())
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			targets[1]:drawCards(1, self:objectName())
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
shuishiVS = sgs.CreateZeroCardViewAsSkill{
	name = "shuishi", 
	view_as = function(self, cards)
		local card = shuishiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("shuishi-Clear")  == 0
	end
}

shuishi = sgs.CreateTriggerSkill{
	name = "shuishi",
	events = {sgs.BeforeCardsMove,sgs.CardsMoveOneTime},
	view_as_skill = shuishiVS,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if event == sgs.BeforeCardsMove and not room:getTag("FirstRound"):toBool() and move.to and player:hasSkill(self:objectName()) then

			if move.reason.m_skillName == "shuishi" and move.card_ids:length() == 1 then
				local move_to
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() == move.to:objectName() then
						move_to = p
					end
				end

				local same_suit = false
				for _, card in sgs.qlist(move_to:getHandcards()) do
					if sgs.Sanguosha:getCard(move.card_ids:at(0)):getSuit() == card:getSuit() then
						same_suit = true
					end
				end

				if same_suit then
					room:setPlayerFlag(move_to,"shuishi_show_card")
					--room:showAllCards(move_to)
					room:setPlayerMark(player,"shuishi-Clear",1)
					room:loseMaxHp(player)
				else
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = player
					msg.arg = 1
					room:sendLog(msg)
					if player:getMaxHp() >= 10 then
						room:setPlayerMark(player,"shuishi-Clear",1)
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime and not room:getTag("FirstRound"):toBool() and move.to and player:hasSkill(self:objectName()) then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("shuishi_show_card") then
					room:showAllCards(p)
					room:setPlayerFlag(p,"-shuishi_show_card")
				end
			end
		end
		return false
	end,
}
]]--

shuishiCard = sgs.CreateSkillCard{
	name = "shuishi", 
	target_fixed = true, 
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, self:objectName())
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local suits = {}
			local can_invoke = true
			while can_invoke do
				local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.who = source
				judge.time_consuming = true
				room:judge(judge)
				if not table.contains(suits, judge.card:getSuit() ) and source:getMaxHp() < 10 then
					table.insert(suits, judge.card:getSuit() )
					room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = source
					msg.arg = 1
					room:sendLog(msg)
				else
					can_invoke = false
					break
				end
			end

			local DiscardPile = room:getDiscardPile()
			local tag = room:getTag("shuishi"):toString():split("+")
			room:removeTag("shuishi")
			if #tag == 0 then return false end
			local toGainList = sgs.IntList()				
			for _,is in ipairs(tag) do
				if is~="" and DiscardPile:contains(tonumber(is)) then
					toGainList:append(tonumber(is))
				end
			end			
			if toGainList:isEmpty() then return false end			
			local target = room:askForPlayerChosen(source,room:getAlivePlayers(),self:objectName(),"shuishi-invoke",true,true)
			if target and target:isAlive() then
				local move3 = sgs.CardsMoveStruct()
				move3.card_ids = toGainList
				move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "shuishi","")
				move3.to_place = sgs.Player_PlaceHand
				move3.to = target						
				room:moveCardsAtomic(move3, true)

				local player_card = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					table.insert(player_card, p:getHandcardNum())
				end
				if target:getHandcardNum() == math.max(unpack(player_card)) then
					room:loseMaxHp(source)
				end
			end
		end
	end
}
shuishiVS = sgs.CreateZeroCardViewAsSkill{
	name = "shuishi", 
	view_as = function(self, cards)
		local card = shuishiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#shuishi") and player:getMaxHp() < 10
	end
}

shuishi = sgs.CreateTriggerSkill{
	name = "shuishi",
	events = {sgs.FinishJudge},
	view_as_skill = shuishiVS,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				--room:moveCardTo(judge.card, nil, nil,sgs.Player_DiscardPile,sgs.Player_PlaceTable,true)

				local oldtag = room:getTag("shuishi"):toString():split("+")
				local totag = {}
				for _,is in ipairs(oldtag) do
					table.insert(totag,tonumber(is))
				end					
				table.insert(totag , judge.card:getEffectiveId())
				room:setTag("shuishi",sgs.QVariant(table.concat(totag,"+")))
			end
		end
		return false
	end,
}

stianyi = sgs.CreatePhaseChangeSkill{
	name = "stianyi",
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 then
			local invoke = true
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("damaged_record") == 0 then
					invoke = false
				end
			end

			if invoke or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
				SendComLog(self, player)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player, self:objectName())
					room:doSuperLightbox("shen_guojia","stianyi")
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 2))
					room:recover(player, sgs.RecoverStruct(player))

					local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "stianyi-invoke")
					if to then
						room:handleAcquireDetachSkills(to, "zuoxing")
						room:setPlayerMark(to,"zuoxing_from"..player:objectName() ,1)
					end

					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}

--佐幸
local pos = 0

zuoxing_select = sgs.CreateSkillCard{
	name = "zuoxing", 
	will_throw = false, 
	target_fixed = true, 
	handling_method = sgs.Card_MethodNone, 
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
--		for _, name in ipairs(patterns) do
--			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
--			poi:setSkillName("zuoxing")
--			poi:addSubcard(self:getSubcards():first())
--			if poi:isAvailable(source) and source:getMark("zuoxing"..name) == 0 and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
--				table.insert(choices, name)
--			end
--		end
		
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
			local pattern = room:askForChoice(source, "zuoxing", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("zuoxing")
					--poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					local pos = 0
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "zuoxingpos", pos)
					--room:setPlayerProperty(source, "zuoxing", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@zuoxing", "@zuoxing:"..pattern)--%src
				end
			end
		end
	end,
}
zuoxingCard = sgs.CreateSkillCard{
	name = "zuoxingCard", 
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
			--card:addSubcard(self:getSubcards():first())
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
		--card:addSubcard(self:getSubcards():first())
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
		--card:addSubcard(self:getSubcards():first())
		return card and card:targetsFeasible(plist, sgs.Self)
	end, 
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+"))do
				table.insert(uses, name)
			end
			local name = room:askForChoice(user, "zuoxing", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		--use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("zuoxing")
		return use_card	
	end, 
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+"))do
				table.insert(uses, name)
			end
			local name = room:askForChoice(card_use.from, "zuoxing", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("zuoxing")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card)	then
				available = false
				break
			end
		end
		if not available then return nil end
		--use_card:addSubcard(self:getSubcards():first())
		return use_card	
	end, 
}
zuoxingVS = sgs.CreateViewAsSkill{
	name = "zuoxing",
	n = 0,
	response_or_use = true,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local acard = zuoxing_select:clone()
			return acard
		else
			--[[
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then 
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = zuoxingCard:clone()
			if pattern and pattern == "@@zuoxing" then
				pattern = patterns[sgs.Self:getMark("zuoxingpos")]
				--acard:addSubcard(sgs.Self:property("zuoxing"):toInt())
			else
			end
			if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then 
				pattern = "analeptic" 
			end
			acard:setUserString(pattern)
			return acard
			]]--
			local card = sgs.Sanguosha:getCard(sgs.Self:property("wanyi"):toInt())

			local patterns = generateAllCardObjectNameTablePatterns()
			local DCR = patterns[sgs.Self:getMark("wanyipos")]
			local shortage = sgs.Sanguosha:cloneCard(DCR ,card:getSuit(),card:getNumber())
			shortage:setSkillName(self:objectName())
			shortage:addSubcard(card:getId())
			return shortage
		end
	end, 
	enabled_at_play = function(self, player)
		local can_invoke = false
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if player:getMark("zuoxing_from"..p:objectName()) > 0 and p:getMaxHp() > 1 then
				can_invoke = true
			end
		end

		if player:getMark("zuoxing_from"..player:objectName()) > 0 and player:getMaxHp() > 1 then
			can_invoke = true
		end
		return can_invoke and (not player:hasUsed("#zuoxing"))
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@zuoxing"
	end, 

} 


zuoxing = sgs.CreateTriggerSkill{
	name = "zuoxing" ,
	events = {sgs.PreCardUsed} ,
	view_as_skill = zuoxingVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("TrickCard") and use.card:getSkillName() == "zuoxing" then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if player:getMark("zuoxing_from"..p:objectName()) > 0 and p:getMaxHp() > 1 then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:loseMaxHp(p,1)
					end
				end
			end
		end
		return false
	end
}


--zuoxing:setGuhuoDialog("r")


sghuishiCard = sgs.CreateSkillCard{
	name = "sghuishi" ,
	filter = function(self, targets, to_select)
		return (#targets == 0)
	end,
	on_use = function(self, room, source, targets)		
		room:removePlayerMark(source, "@sghuishi")
		room:doSuperLightbox("shen_guojia","sghuishi")

		local can_invoke = true
		for _,sk in sgs.qlist(targets[1]:getVisibleSkillList()) do
			if sk:getFrequency() == sgs.Skill_Wake then
				if targets[1]:hasSkill(sk:objectName()) and targets[1]:getMark(sk:objectName()) == 0 and source:getMaxHp() >= room:getAlivePlayers():length() then
					can_invoke = false
					room:setPlayerMark(targets[1], "Skill_Wake_can_direct_wake"..sk:objectName(), 1)
				end
			end
		end
		if can_invoke then
			room:loseMaxHp(source,2)
			targets[1]:drawCards(4)
		end
	end
}
sghuishiVS = sgs.CreateZeroCardViewAsSkill{
	name = "sghuishi",
	view_as = function(self,cards)
		return sghuishiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@sghuishi") > 0
	end
}
sghuishi = sgs.CreateTriggerSkill{
		name = "sghuishi",
		frequency = sgs.Skill_Limited,
		limit_mark = "@sghuishi",
		view_as_skill = sghuishiVS ,
		on_trigger = function() 
		end
}

shen_guojia:addSkill(shuishi)
shen_guojia:addSkill(stianyi)
shen_guojia:addSkill(sghuishi)
shen_guojia:addRelateSkill("zuoxing")

if not sgs.Sanguosha:getSkill("zuoxing") then skills:append(zuoxing) end

sgs.LoadTranslationTable{
["shen_guojia"] = "神郭嘉",
["shuishi"] = "慧識",
--[":shuishi"] = "出牌階段限一次，若你的體力上限小於10，則你可選擇一名角色。你令其摸一張牌，若其以此法獲得的牌：與該角色的其他手牌花色均不相同，則你加1點體力上限，若你的體力上限小於10，則你可以重復此流程；否則你減1點體力上限，且其展示所有手牌。",
[":shuishi"] = "出牌階段限一次，若你的體力上限小於10，你可進行判定牌不置入棄牌堆的判定。若判定結果與本次發動技能時的其他判定結果的花色均不相同且你的體力上限小於10，則你加1點體力上限並重復此流程。然後你將所有位於處理區的判定牌交給一名角色。若其手牌數為全場最多，則你減1點體力上限。",

["shuishi-invoke"] = "你可以將所有〖慧識〗牌交給一名角色",
["stianyi"] = "天翊",
["stianyi-invoke"] = "令一名角色獲得技能〖佐幸〗",
[":stianyi"] = "覺醒技，準備階段，若場上的所有存活角色均於本局遊戲內受到過傷害，則你加2點體力上限並回復1點體力，然後令一名角色獲得技能〖佐幸〗。",
["zuoxing"] = "佐幸",
[":zuoxing"] = "出牌階段限一次，若令你獲得〖佐幸〗的角色存活且體力上限大於1，則你可以令其減1點體力上限，然後你視為使用一張普通錦囊牌。",
["@zuoxing"] = "你可以視為使用【%src】",
["~zuoxing"] = "按照此牌使用方式指定角色→點擊確定",

["sghuishi"] = "輝逝",
[":sghuishi"] = "限定技，出牌階段，你可以選擇一名角色：若其有未發動過的覺醒技且你的體力上限大於等於角色數，則你令其發動這些覺醒技時無視原有條件；否則其摸四張牌。然後你減2點體力上限。"
}

--牛金
re_niujin = sgs.General(extension,"re_niujin","wei2","4",true)

--摧銳
recuoruiCard = sgs.CreateSkillCard{
	name = "recuorui",
	filter = function(self, targets, to_select)
		return not to_select:isNude() and #targets < sgs.Self:getHp()
	end,
	on_use = function(self, room, source, targets)
		for _,p in pairs(targets) do		
			local id = room:askForCardChosen(source, p, "he", self:objectName(), false)
			room:obtainCard(source, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName()), false)
		end
	end
}

recuoruiVS = sgs.CreateZeroCardViewAsSkill{
	name = "recuorui",
	response_or_use = true,
	view_as = function()
		return recuoruiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@recuorui")
	end
}

recuorui = sgs.CreateTriggerSkill{
	name = "recuorui",
	events = {sgs.EventPhaseStart},
	view_as_skill = recuoruiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("turn") == 1 then
			room:askForUseCard(player, "@@recuorui", "@recuorui:"..player:getHp() )
		end
		return false
	end,
}

--裂圍
reliewei = sgs.CreateTriggerSkill{
	name = "reliewei",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
		local dying = data:toDying()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if dying.damage and dying.damage.from and dying.damage.from:objectName() == p:objectName() and p:getMark("reliewei-Clear") < p:getHp() then
			 	if room:askForSkillInvoke(p, self:objectName(), data) then
			 		room:addPlayerMark(p,"reliewei-Clear")
					room:broadcastSkillInvoke(self:objectName())
					p:drawCards(1)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

re_niujin:addSkill(recuorui)
re_niujin:addSkill(reliewei)

sgs.LoadTranslationTable{
["re_niujin"] = "手殺牛金",
["&re_niujin"] = "牛金",
["recuorui"] = "摧銳",
[":recuorui"] = "你的第一個回合開始時，你可以依次獲得至多X名角色的各一張手牌（X為你的體力值）。",
["@recuorui"] = "你可以選擇至多 %src 名角色，獲得他們的各一張牌。",
["~recuorui"] = "選擇角色→點擊確定",
["reliewei"] = "裂圍",
[":reliewei"] = "每回合限X次（X為你的體力值），當有其他角色因你造成傷害而進入瀕死狀態時，你可以摸一張牌。",
}

--[[

王凌

]]--

nos_mobile_wangling = sgs.General(extension,"nos_mobile_wangling","wei2","4",true,true)

nos_mobile_mouli_bill = sgs.CreateOneCardViewAsSkill{
	name = "nos_mobile_mouli_bill&",
	response_or_use = true,
	view_filter = function(self, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Slash_IsAvailable(sgs.Self) and (to_select:isBlack()) then
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
				return to_select:isRed()
			elseif pattern == "slash" then
				return to_select:isBlack()
			end
			return false
		end
		return false
	end,
	view_as = function(self,card)
		local new_card = nil
		if card:isRed() then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:isBlack() then
			new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName("nos_mobile_mouli_bill")
			new_card:addSubcard(card)
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getMark("@mobile_li") >  0
	end,
	enabled_at_response = function(self, player, pattern)
		return ((pattern == "slash") or (pattern == "jink")) and player:getMark("@mobile_li") >  0
	end,
}

if not sgs.Sanguosha:getSkill("nos_mobile_mouli_bill") then skills:append(nos_mobile_mouli_bill) end

nos_mobile_mouliCard = sgs.CreateSkillCard{
	name = "nos_mobile_mouli",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:obtainCard(targets[1], sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""))
			room:setPlayerMark(targets[1],"@mobile_li",1)
			room:setPlayerMark(source,"nos_mobile_mouli"..targets[1]:objectName() ,1)
			room:attachSkillToPlayer(targets[1],"nos_mobile_mouli_bill")

			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
nos_mobile_mouliVS = sgs.CreateOneCardViewAsSkill{
	name = "nos_mobile_mouli",
	response_or_use = true,
	view_filter = function(self, card)
		return not card:isEquipped()
	end,
	view_as = function(self, card)
		local cards = nos_mobile_mouliCard:clone()
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#nos_mobile_mouli") and not player:isKongcheng()
	end
}

nos_mobile_mouli = sgs.CreateTriggerSkill{
	name="nos_mobile_mouli",
	view_as_skill = nos_mobile_mouliVS,
	events = {sgs.CardFinished},
	global = true,
	on_trigger=function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Jink")) and player:getMark("@mobile_li") >  0 then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("nos_mobile_mouli"..player:objectName()) > 0 and player:getMark("nos_mobile_mouli_has_draw") == 0  then
						room:setPlayerMark(player,"nos_mobile_mouli_has_draw",1)
						p:drawCards(3)
					end
				end
			end
		end
	end,
}

nos_mobile_zifu = sgs.CreateTriggerSkill{
	name = "nos_mobile_zifu",
	events = {sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() or player:isNude() then return false end
		if player:isAlive() and splayer:getMark("nos_mobile_mouli"..player:objectName()) > 0 then
			SendComLog(self, player)
			room:loseMaxHp(player,2)
		end
		return false
	end
}

nos_mobile_wangling:addSkill(nos_mobile_mouli)
nos_mobile_wangling:addSkill(nos_mobile_zifu)

sgs.LoadTranslationTable{
["nos_mobile_wangling"] = "懷舊王凌",
["&nos_mobile_wangling"] = "王凌",
["#nos_mobile_wangling"] = "風節格尚",
["nos_mobile_mouli"] = "謀立",
[":nos_mobile_mouli"] = "出牌階段限一次，你可將一張手牌交於一名其他角色。若如此做，直至你的下回合開始時，令其獲得「立」標記。"..
"擁有「立」標記的角色：其可以將一張黑色牌當做【殺】使用；其可以將一張紅色牌當做【閃】"..
"使用；其接下來第一次使用【殺】或【閃】結算結束後，你摸三張牌。",
["nos_mobile_mouli_bill"] = "謀立",
[":nos_mobile_mouli_bill"] = "你可以將一張黑色牌當做【殺】使用；你可將一張紅色牌當做【閃】使用",
["nos_mobile_zifu"] = "自縛",
[":nos_mobile_zifu"] = "鎖定技，當擁有「立」標記的角色死亡後，你減少2點體力上限。",
}

--[[

周群 

]]--

mobile_zhouqun = sgs.General(extension,"mobile_zhouqun","shu2","3",true)
--天算
mobile_tiansuanCard = sgs.CreateSkillCard{
	name = "mobile_tiansuan" ,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)		
		room:addPlayerMark(source,"mobile_tiansuan_lun",1)
		local choices = {"mobile_tiansuan5","mobile_tiansuan4","mobile_tiansuan3","mobile_tiansuan2","mobile_tiansuan1","cancel"}
		local choice = room:askForChoice(source, "mobile_tiansuan", table.concat(choices, "+"))
		if choice ~= "cancel" then
			table.insert(choices,choice)
		end
		local result = choices[math.random(1,#choices)]
		room:doSuperLightbox("mobile_zhouqun",result)
		ChoiceLog(source, result)
		room:setPlayerFlag(source,result)
		local s = room:askForPlayerChosen(source, room:getAlivePlayers(), "mobile_tiansuan", "@mobile_tiansuan-invoke", true)
		if s then
			room:setPlayerMark(s,"@"..result,1)


			if result == "mobile_tiansuan5" and source:canDiscard(s, "he") and source:objectName() ~= s:objectName() then
				room:setTag("Dongchaee",sgs.QVariant(s:objectName()))
				room:setTag("Dongchaer",sgs.QVariant(source:objectName()))
				local id = room:askForCardChosen(source, s, "he", "mobile_tiansuan", false)
				room:obtainCard(source, id, false)
				room:setTag("Dongchaee",sgs.QVariant())
				room:setTag("Dongchaer",sgs.QVariant())
			elseif result == "mobile_tiansuan4" and source:canDiscard(s, "he") and source:objectName() ~= s:objectName() then
				local id = room:askForCardChosen(source, s, "he", "mobile_tiansuan", false)
				room:obtainCard(source, id, false)
			end

			room:setPlayerMark(source,"mobile_tiansuan_trigger"..s:objectName() ,1)
		end
		room:setPlayerFlag(source,"-"..result)
	end,
}

mobile_tiansuan = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_tiansuan",
	view_as = function(self,cards)
		return mobile_tiansuanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("mobile_tiansuan_lun") == 0
	end
}

--and (damage.nature == sgs.DamageStruct_Fire)

mobilezq_fate = sgs.CreateTriggerSkill{
	name = "mobilezq_fate",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},
	global = true,
	on_trigger = function(self, event, player, data, room) 
		local damage = data:toDamage()
		if not damage.chain then
			if player:getMark("@mobile_tiansuan5") > 0 then
				local msg = sgs.LogMessage()
				msg.type = "#MobilezqFate5"
				msg.from = player
				msg.to:append(damage.from)
				room:sendLog(msg)
				return true
			end
			if player:getMark("@mobile_tiansuan4") > 0 then
				damage.damage = 1
				local msg = sgs.LogMessage()
				msg.type = "#MobilezqFate4"
				msg.from = player
				msg.to:append(damage.from)
				room:sendLog(msg)
				data:setValue(damage)
			end
			if player:getMark("@mobile_tiansuan3") > 0 then
				damage.nature = sgs.DamageStruct_Fire
				damage.damage = 1
				local msg = sgs.LogMessage()
				msg.type = "#MobilezqFate3"
				msg.from = player
				msg.to:append(damage.from)
				room:sendLog(msg)
				data:setValue(damage)
			end
			if player:getMark("@mobile_tiansuan1") > 0 or player:getMark("@mobile_tiansuan2") > 0 then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#MobilezqFate1"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)
			end
		end
		return false
	end
}

mobilezq_fateban = sgs.CreateProhibitSkill{
	name = "mobilezq_fateban",
	is_prohibited = function(self, from, to, card)
		if from:getMark("@mobile_tiansuan") == 1 and card:isKindOf("Peach") then
			return true
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("mobilezq_fate") then skills:append(mobilezq_fate) end
if not sgs.Sanguosha:getSkill("mobilezq_fateban") then skills:append(mobilezq_fateban) end

mobile_zhouqun:addSkill(mobile_tiansuan)

sgs.LoadTranslationTable{
	["mobile_zhouqun"] = "周群",
	["#mobile_zhouqun"] = "佔天明徵",
	["mobile_tiansuan"] = "天算",
	[":mobile_tiansuan"] = "每輪限一次，出牌階段，你抽取一個「命運簽」（在抽籤開始前，你可以悄悄作弊，額外放入一個「命"..
	"運簽」增加其抽中的機會）。然後選擇一名角色，其獲得命運簽的效果直到你的下回合開始。若其獲得的是「上上簽」，你觀看其手牌"..
	"並從其區域內獲得一張牌；若其獲得的是「上簽」，你從其處獲得一張牌。",
	["#MobilezqFate5"] = "%from 受到命運籤的影響，%to 對 %from 造成的傷害被防止",
	["#MobilezqFate4"] = "%from 受到命運籤的影響，%to 對 %from 造成的傷害改為 1 點",
	["#MobilezqFate3"] = "%from 受到命運籤的影響，%to 對 %from 造成的傷害改為 1 點火屬性傷害",
	["#MobilezqFate1"] = "%from 受到命運籤的影響，%to 對 %from 造成的傷害由 %arg 點增加到 %arg2 點",
	["mobile_tiansuan5"] = "上上籤",
	["mobile_tiansuan4"] = "上籤",
	["mobile_tiansuan3"] = "中籤",
	["mobile_tiansuan2"] = "下籤",
	["mobile_tiansuan1"] = "下下籤",
	["@mobile_tiansuan-invoke"] = "你可以令一名角色獲得命運籤的效果",
}



--[[

王甫＆趙累 蜀 4勾玉 忱忠不移

]]--
mobile_wangfuzhaolei = sgs.General(extension,"mobile_wangfuzhaolei","shu2","4",true)

mobile_xunyi = sgs.CreateTriggerSkill{
	name = "mobile_xunyi",
	events = {sgs.Damaged, sgs.Damage,sgs.Death,sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and RIGHT(self, player) then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "mobile_xunyi-invoke", false, sgs.GetConfig("face_game", true))
			if to then
				room:doAnimate(1, player:objectName(), to:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:addPlayerMark(to, "@mobile_yi")
				room:addPlayerMark(to, "mobile_xunyi_target"..player:objectName() )
			end
		elseif event == sgs.Death and RIGHT(self, player) then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			if player:isAlive() and splayer:getMark("mobile_xunyi_target"..player:objectName()) > 0 then
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "mobile_xunyi-invoke", false, sgs.GetConfig("face_game", true))
				if to then
					room:doAnimate(1, player:objectName(), to:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					room:addPlayerMark(to, "@mobile_yi")
					room:addPlayerMark(to, "mobile_xunyi_target"..player:objectName() )
				end
			end
		elseif event == sgs.Damaged or event == sgs.Damage then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill(self:objectName()) and player:getMark("mobile_xunyi_target"..p:objectName()) > 0 and player:isAlive() then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					if event == sgs.Damaged and damage.from:objectName() ~= p:objectName() then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:askForDiscard(p, self:objectName(), 1, 1, false, true)
					elseif event == sgs.Damage and damage.to:objectName() ~= p:objectName() then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(1)
					end
				end
				if player:hasSkill(self:objectName()) and p:getMark("mobile_xunyi_target"..player:objectName()) > 0 and player:isAlive() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					if event == sgs.Damaged and damage.from:objectName() ~= p:objectName() then
						room:doAnimate(1, p:objectName(), player:objectName())
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:askForDiscard(p, self:objectName(), 1, 1, false, true)
					elseif event == sgs.Damage and damage.to:objectName() ~= p:objectName() then
						room:doAnimate(1, p:objectName(), player:objectName())
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
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

mobile_wangfuzhaolei:addSkill(mobile_xunyi)

sgs.LoadTranslationTable{
	["mobile_wangfuzhaolei"] = "王甫＆趙累",
	["&mobile_wangfuzhaolei"] = "王甫趙累",
	["#mobile_wangfuzhaolei"] = "忱忠不移",
	["mobile_xunyi"] = "殉義",
	["mobile_xunyi"] = "殉義",
	[":mobile_xunyi"] = "遊戲開始時，你可選一名其他角色，令其獲得「義」標記。當你/其受到1點傷害後（傷害來源不為其/你），其/你棄置1張牌；當你/其"..
	"對出其/你以外的角色造成1點傷害後，其/你摸1張牌。當擁有「義」標記的角色死亡時，你可移動此標記。 ",
	["mobile_xunyi-invoke"] = "你可以發動「殉義」",
	["@mobile_yi"] = "義",
}



--[[
周處 吳 4勾玉 英情天逸

鄉害：鎖定技，場上所有其他角色的手牌上限-1。你手牌區所有裝備牌均視為【酒】。

除害：出牌階段限一次，你可以摸一張牌，然後與一名其他角色拼點。若你贏，你觀看其手牌，然後從牌堆或棄牌堆中獲得其手牌中擁有的牌
類型各一張；當你於此階段對其造成傷害後，你將牌堆或棄牌堆中，一張你空置裝備欄對應類型的裝備牌，置入你的裝備區。
]]--

mobile_zhouchu = sgs.General(extension,"mobile_zhouchu","wu2","4",true)

mobile_xianghai = sgs.CreateFilterSkill{
	name = "mobile_xianghai",
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return to_select:isKindOf("EquipCard") == true and place == sgs.Player_PlaceHand
	end,
	view_as = function(self, originalCard)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", originalCard:getSuit(), originalCard:getNumber())
		analeptic:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(analeptic)
		return card
	end
}

mobile_xianghaiMC = sgs.CreateMaxCardsSkill{
	name = "#mobile_xianghaiMC",
	extra_func = function(self, target)
		local n = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if p:hasSkill("mobile_xianghai") and target:objectName() ~= p:objectName() then
				n = n - 1
			end
		end
		return n
	end
}

dochuhai = function(player, card, number)
	local room = player:getRoom()
	local n = 4 - player:getEquips():length()
	if n > 0 then
		local n2 = math.min(13,number + n)
		local msg = sgs.LogMessage()
		msg.type = "#Chuhai"
		msg.from = player
		msg.to:append(player)
		msg.arg = "mobile_chuhai"
		msg.arg2 = tostring(n2)
		room:sendLog(msg)
		return (n2)
	end

end


mobile_chuhaiCard = sgs.CreateSkillCard{
	name = "mobile_chuhai",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:drawCards(1)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if not p:isKongcheng() then
					_targets:append(p)
				end
			end
			if not _targets:isEmpty() then
				local s = room:askForPlayerChosen(source, _targets, "mobile_chuhai", "mobile_chuhai-invoke", true)
				if s then
					--room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(source, "mobile_chuhai")
					room:doAnimate(1, source:objectName(), s:objectName())
					local success = source:pindian(s, "mobile_chuhai", nil)
					if success then
						room:getThread():delay()
						room:showAllCards(s, source)

						local hasBasic = false
						local hasTrick = false
						local hasEquip = false
						for _, card in sgs.qlist(s:getHandcards()) do
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

						local pattern_list = {}
						if hasBasic then
							table.insert(pattern_list , "BasicCard")
						end
						if hasTrick then
							table.insert(pattern_list , "TrickCard")
						end
						if hasEquip then
							table.insert(pattern_list , "EquipCard")
						end
						if #pattern_list  > 0 then
							getpatterncard_for_each_pattern(source, pattern_list,true,true)
						end
						room:setPlayerMark(s, "mobile_chuhai_target_Play",1)
					end
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

mobile_chuhaiVS = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_chuhai",
	view_as = function(self, cards)
		return mobile_chuhaiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_chuhai") and player:getMark("@mobile_chuhai") == 0
	end
}

mobile_chuhai = sgs.CreateTriggerSkill{
	name = "mobile_chuhai",
	events = {sgs.Damage,sgs.PindianVerifying,sgs.Pindian,sgs.CardsMoveOneTime},
	view_as_skill = mobile_chuhaiVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.to:getMark("mobile_chuhai_target_Play") > 0 and player:getMark("@mobile_chuhai") == 0 then
				local equips = sgs.CardList()
				if player:getMark("@AbolishWeapon") == 0 and not player:getWeapon() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
				end
				if equips:isEmpty() and player:getMark("@AbolishArmor") == 0 and not player:getArmor() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
				end
				if equips:isEmpty() and player:getMark("@AbolishDefensiveHorse") == 0 and not player:getDefensiveHorse() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
				end
				if equips:isEmpty() and player:getMark("@AbolishOffensiveHorse") == 0 and not player:getOffensiveHorse() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
				end
				if equips:isEmpty() and player:getMark("@AbolishTreasure") == 0 and not player:getTreasure() then
					for _, id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Treasure") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Treasure") then
							equips:append(sgs.Sanguosha:getCard(id))
						end
					end
				end
				
				if not equips:isEmpty() then
					local card = equips:at(math.random(0, equips:length() - 1))
					room:moveCardTo(card, player, sgs.Player_PlaceEquip)
				end
				return false
			end
		elseif event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			if pindian.reason == self:objectName() then
				for _,wanglang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do  --同将模式
					if wanglang:objectName() == pindian.from:objectName() then
						pindian.from_number = dochuhai(wanglang, pindian.from_card, pindian.from_number)
					end
					if wanglang:objectName() == pindian.to:objectName() then
						pindian.to_number = dochuhai(wanglang, pindian.to_card, pindian.to_number)
					end
				end
				data:setValue(pindian)
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == self:objectName() then
				if pindian.from_number <= pindian.to_number and pindian.from_number < 13 then
					if pindian.from:objectName() == player:objectName() then
						if player:getMark("@mobile_chuhai") == 0 then
							room:doSuperLightbox("mobile_zhouchu","mobile_chuhai_failed")
							room:addPlayerMark(player,"@mobile_chuhai")
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getMark("@mobile_chuhai") == 0 and player:getEquips():length() >= 3 then
				room:doSuperLightbox("mobile_zhouchu","mobile_chuhai_success")
				room:addPlayerMark(player,"@mobile_chuhai")
				room:handleAcquireDetachSkills(player, "mobile_zhangming|-mobile_xianghai")
			end
		end
	end
}

mobile_zhangming = sgs.CreateTriggerSkill{
	name = "mobile_zhangming",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.TrickCardCanceling,sgs.Damage,sgs.EventPhaseChanging,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:getSuit() == sgs.Card_Club and not use.card:isKindOf("SkillCard") and player:hasSkill("mobile_zhangming") then
				if string.find(use.card:getClassName(), "Slash") then

					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())

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
			if effect.from and effect.from:hasSkill("mobile_zhangming") and effect.card:getSuit() == sgs.Card_Club then
				room:notifySkillInvoked(effect.from, self:objectName())
				room:sendCompulsoryTriggerLog(effect.from, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and player:hasSkill("mobile_zhangming") and player:getMark("mobile_zhangming-Clear") == 0 then

				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:addPlayerMark(player,"mobile_zhangming-Clear")
					local types = {"BasicCard", "TrickCard", "EquipCard"}
					local pattern_list = {}

					if damage.to:isKongcheng() then
						pattern_list = {"BasicCard", "TrickCard", "EquipCard"} 

					else
						local ids = getIntList(damage.to:getHandcards())
						local id = ids:at(math.random(0, ids:length() - 1))
						room:throwCard(id, damage.to, damage.to )
						for i = 1,3,1 do
							if i ~= sgs.Sanguosha:getCard(id):getTypeId() then
								table.insert(pattern_list,types[i])
							end
						end
					end
					if #pattern_list > 0 then
						local GetCardList = sgs.IntList()
						for i = 1,#pattern_list ,1 do
							local pattern = pattern_list[i]
							local DPHeart = sgs.IntList()
							if room:getDrawPile():length() > 0 then
								for _, id in sgs.qlist(room:getDrawPile()) do
									local card = sgs.Sanguosha:getCard(id)
									if card:isKindOf(pattern) then
										DPHeart:append(id)
									end
								end
							end
							if room:getDiscardPile():length() > 0 then
								for _, id in sgs.qlist(room:getDiscardPile()) do
									local card = sgs.Sanguosha:getCard(id)
									if card:isKindOf(pattern) then
										DPHeart:append(id)
									end
								end
							end
							if DPHeart:length() ~= 0 then
								local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
								GetCardList:append(get_id)
								room:addPlayerMark(player, "mobile_zhangming"..get_id.."-Clear")
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
				end
			end
		elseif event == sgs.EventPhaseChanging then
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
	end,
	can_trigger = function(self, target)
		return target
	end
}

--[[
mobile_zhangming = sgs.CreateTriggerSkill{
	name = "mobile_zhangming",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseEnd,sgs.TrickCardCanceling},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging and RIGHT(self, player)  then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				room:setPlayerCardLimitation(player, "discard", ".|club|.|hand", true)
			end
		elseif event == sgs.EventPhaseEnd and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Discard then
				room:removePlayerCardLimitation(player, "discard", ".|club|.|hand$1")
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if RIGHT(self, effect.from) and effect.card:getSuit() == sgs.Card_Club then
				SendComLog(self, effect.from)
				room:addPlayerMark(effect.from, self:objectName().."engine")
				if effect.from:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(effect.from, self:objectName().."engine")
					return true
				end
			end
		end

		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


mobile_zhangmingmc = sgs.CreateMaxCardsSkill{
	name = "#mobile_zhangmingmc",
	extra_func = function(self, target)
		if target:hasSkill("mobile_zhangming") then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:getSuit() == sgs.Card_Club and target:getPhase() == sgs.Player_Discard then
					x = x + 1
				end
			end
			return x
		end
	end
}
]]--

mobile_zhangmingmc = sgs.CreateMaxCardsSkill{
	name = "#mobile_zhangmingmc",
	extra_func = function(self, target)
		local x = 0
		if target:hasSkill("mobile_zhangming") then
			for _, card in sgs.list(target:getHandcards()) do
				if target:getMark("mobile_zhangming"..card:getId().."-Clear") > 0 then
					x = x + 1
				end
			end
			return x
		end
	end
}


mobile_zhouchu:addSkill(mobile_xianghai)
mobile_zhouchu:addSkill(mobile_xianghaiMC)
mobile_zhouchu:addSkill(mobile_chuhai)
mobile_zhouchu:addRelateSkill("mobile_zhangming")

if not sgs.Sanguosha:getSkill("mobile_zhangming") then skills:append(mobile_zhangming) end
if not sgs.Sanguosha:getSkill("#mobile_zhangmingmc") then skills:append(mobile_zhangmingmc) end

sgs.LoadTranslationTable{
	["mobile_zhouchu"] = "周處",
	["#mobile_zhouchu"] = "英情天逸",
	["mobile_xianghai"] = "鄉害",
	["#mobile_xianghaiMC"] = "鄉害",
	["mobile_chuhai-invoke"] = "你可以發動「除害」，與一名其他角色拼點",
	[":mobile_xianghai"] = "鎖定技，場上所有其他角色的手牌上限-1。你手牌區所有裝備牌均視為【酒】。",
	["mobile_chuhai"] = "除害",
	--[":mobile_chuhai"] = "出牌階段限一次，你可以摸一張牌，然後與一名其他角色拼點。若你贏，你觀看其手牌，然後從牌堆或棄牌堆中獲得其手牌中擁有的牌類型各一張；當你於此階段對其造成傷害後，你將牌堆或棄牌堆中，一張你空置裝備欄對應類型的裝備牌，置入你的裝備區。",
	[":mobile_chuhai"] = "使命技，階段技，你可以摸一張牌，然後與一名其他角色拼點，你的拼點牌點數+X(X為4減去你的裝備區牌"..
	"數且最小為0)。若你贏，你觀看其手牌，然後從牌堆或棄牌堆中獲得其手牌中擁有的牌類型各一張；當你於此階段對其造成傷害後，"..
	"你將牌堆或棄牌堆中，一張你空置裝備欄對應類型的裝備牌，置入你的裝備區。"..
	"成功：當你裝備區的牌數達到三張時，你失去技能〖鄉害〗並獲得技能〖彰名〗"..
	"失敗：若你拼點失敗且點數小於K",
	["#Chuhai"] = "%from 的技能【%arg】被觸發，拼點牌視為 %arg2 點",
	["mobile_chuhai_success"] = "除害成功",
	["mobile_chuhai_failed"] = "除害失敗",
	["mobile_zhangming"] = "彰名",
	--[":mobile_zhangming"] = "鎖定技，你的梅花牌不計入手牌上限，你使用梅花普通錦囊牌不能被其他角色響應",
	[":mobile_zhangming"] = "鎖定技，你使用梅花牌不能被響應，每回合限一次，你對其他角色造成傷害時，其隨機棄置一張手牌，然後你從牌堆或棄牌堆裡隨機獲得與此牌不同類別的牌各一張（若其沒有手牌則改成所有類別各一張），這些牌本回合不計入手牌上限",
}

--手殺荀諶
mobile_xunchen = sgs.General(extension, "mobile_xunchen", "qun3", 3, true, true)

--〖危迫〗每回合限一次，出牌階段，你可以指定一名角色並指定一張【兵臨城下】或智囊的牌名，然後令其獲得一個“危迫”標記。擁有“危迫”標記的角色，其可以移去一個“危迫”，將一張【殺】當做一張你指定的牌名的牌使用。回合開始時，你移去場上所有“危迫”。

mobile_weipo_bill = sgs.CreateOneCardViewAsSkill{
	name = "mobile_weipo_bill&",
	view_filter = function(self, to_select)
		return to_select:isKindOf("Slash")
	end,

	view_as = function(self, card)
		local patterns = generateAllCardObjectNameTablePatterns()
		local DCR = patterns[sgs.Self:getMark("mobile_weipopos")]
		local shortage = sgs.Sanguosha:cloneCard(DCR ,card:getSuit(),card:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(card)
		return shortage
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@mobile_weipo") >  0
	end,
}

if not sgs.Sanguosha:getSkill("mobile_weipo_bill") then skills:append(mobile_weipo_bill) end


mobile_weipoCard = sgs.CreateSkillCard{
	name = "mobile_weipo",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:addPlayerMark(targets[1],"@mobile_weipo")

			local patterns = generateAllCardObjectNameTablePatterns()
			local choices = {}
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) and source:getMark("AG_BANCard"..card:objectName()) == 0 then
					if card:isNDTrick() and isZhinang(card) then
						table.insert(choices, card:objectName())
					end
				end
			end


			table.insert(choices, "binglinchengxia")
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "mobile_weipo", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local pos = getPos(patterns, pattern)
				room:setPlayerMark(targets[1], "mobile_weipopos", pos)

				room:attachSkillToPlayer(targets[1],"mobile_weipo_bill")
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
mobile_weipo = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_weipo",
	view_as = function(self, cards)
		return mobile_weipoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_weipo")
	end
}


--〖陳勢〗當其他角色使用【兵臨城下】指定目標後，其可以交給你一張牌,然後將牌堆頂三張牌中不為【殺】的牌置入棄牌堆;當其他角色成為【兵臨城下】的目標後，可以交給你一張牌，然後將牌堆頂三張牌中的【殺】置入棄牌堆。
mobile_chenshi = sgs.CreateTriggerSkill{
	name = "mobile_chenshi",
	events = {sgs.TargetSpecified, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("binglinchengxia") then
			if event == sgs.TargetSpecified then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					local card = room:askForCard(player, ".", "@mobile_chenshi_give1", sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:moveCardTo(card, p, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), self:objectName(), ""))
						local ids = room:getNCards(3, false)
						local ids2 = sgs.IntList()
						for _,id in sgs.qlist(ids) do
							room:showCard(player, id)
							local card = sgs.Sanguosha:getCard(id)
							if card and not card:isKindOf("Slash") then
								ids2:append(id)
							end
						end
						room:getThread():delay()
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcards(ids2)
						room:throwCard(dummy, nil, nil)
					end
				end
			elseif event == sgs.TargetConfirmed then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					local card = room:askForCard(player, ".", "@mobile_chenshi_give2", sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:moveCardTo(card, p, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), self:objectName(), ""))
						local ids = room:getNCards(3, false)
						local ids2 = sgs.IntList()
						for _,id in sgs.qlist(ids) do
							room:showCard(player, id)
							local card = sgs.Sanguosha:getCard(id)
							if card and card:isKindOf("Slash") then
								ids2:append(id)
							end
						end
						room:getThread():delay()
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcards(ids2)
						room:throwCard(dummy, nil, nil)
					end
				end			
			end
		end
	end, 
	can_trigger = function(self, target)
		return target
	end
}

--〖謀識〗鎖定技，當你受到傷害時，若造成傷害的牌與上次對你造成傷害的牌顏色相同，防止之。

mobile_moucuan = sgs.CreateTriggerSkill{
	name = "mobile_moucuan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted,sgs.EventAcquireSkill,sgs.EventLoseSkill},  
	on_trigger = function(self, event, player, data, room) 
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card and GetColor(damage.card) and player:getMark("last_damage_card"..GetColor(damage.card)) > 0 then
				room:notifySkillInvoked(player, "mobile_moucuan")
				room:broadcastSkillInvoke("mobile_moucuan")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = damage.nature == sgs.DamageStruct_Fire and "fire_nature" or "thunder_nature"
				room:sendLog(msg)
				return true
			end
			return false
		elseif event == sgs.EventAcquireSkill or event == sgs.EventLoseSkill then
			if data:toString() ~= "mobile_moucuan" then return false end
			if event == sgs.EventAcquireSkill then
				if string.find(mark, "last_damage_card") and player:getMark(mark) > 0 then				
					room:setPlayerMark(player, "@mobile_moucuan_" .. string.sub(mark, 16, string.len(mark)) , 0)
				end
			else
				if string.find(mark, "@mobile_moucuan_") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
				end
			end
		end
	end
}

mobile_xunchen:addSkill(mobile_weipo)
mobile_xunchen:addSkill(mobile_chenshi)
mobile_xunchen:addSkill(mobile_moucuan)

sgs.LoadTranslationTable{
	["mobile_xunchen"] = "手殺荀諶",
	["&mobile_xunchen"] = "荀諶",
	["#mobile_xunchen"] = "謀識無對",
	["mobile_weipo"] = "危迫",
	[":mobile_weipo"] = "每回合限一次，出牌階段，你可以指定一名角色並指定一張【兵臨城下】或智囊的牌名，然後令其獲得一個“危迫”標記。擁有“危迫”標記的角色，其可以移去一個“危迫”，將一張【殺】當做一張你指定的牌名的牌使用。回合開始時，你移去場上所有“危迫”。",
	["mobile_weipo_bill"] = "危迫",
	["mobile_chenshi"] = "陳勢",
	[":mobile_chenshi"] = "當其他角色使用【兵臨城下】指定目標後，其可以交給你一張牌,然後將牌堆頂三張牌中不為【殺】的牌置入棄牌堆;當其他角色成為【兵臨城下】的目標後，可以交給你一張牌，然後將牌堆頂三張牌中的【殺】置入棄牌堆。",
	["mobile_moucuan"] = "謀識",
	[":mobile_moucuan"] = "鎖定技，當你受到傷害時，若造成傷害的牌與上次對你造成傷害的牌顏色相同，防止之。",
	["@mobile_chenshi_give1"] = "你可以交給該角色一張牌，然後將牌堆頂三張牌中不為【殺】的牌置入棄牌堆",
	["@mobile_chenshi_give2"] = "你可以交給該角色一張牌，然後將牌堆頂三張牌中的【殺】置入棄牌堆",
}



--手殺孫邵
mobile_sunshao = sgs.General(extension, "mobile_sunshao", "wu2", 3, true, true)

mobile_dingyi = sgs.CreateTriggerSkill{
	name = "mobile_dingyi",
	events = {sgs.GameStart, sgs.DrawNCards, sgs.QuitDying},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and RIGHT(self, player) then
			local choice = room:askForChoice(player, "mobile_dingyi", "mobile_dingyi1+mobile_dingyi2+mobile_dingyi3+mobile_dingyi4")
			for _, p in sgs.qlist(room:getAlivePlayers()) do				
				room:addPlayerMark(p,"@"..choice)
			end
		elseif event == sgs.DrawNCards then
			if data:toInt() > 0 and player:getMark("@mobile_dingyi1") > 0 then
				local n = data:toInt()
				data:setValue(n + player:getMark("@mobile_dingyi1") )
			end
		elseif event == sgs.QuitDying then
			if player:getMark("@mobile_dingyi4") > 0 then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = player:getMark("@mobile_dingyi4")
				room:recover(player, recover)
			end
		end
	end
}

mobile_dingyimc = sgs.CreateMaxCardsSkill{
	name = "#mobile_dingyimc",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		return target:getMark("@mobile_dingyi2") * 2
	end
}

mobile_dingyitm = sgs.CreateTargetModSkill{
	name = "#mobile_dingyitm",
	frequency = sgs.Skill_Compulsory,
	distance_limit_func = function(self, player)
		if player:getMark("@mobile_dingyi3") > 0 then
			return player:getMark("@mobile_dingyi3")
		else
			return 0
		end
	end,
}

mobile_zuici = sgs.CreateTriggerSkill{
	name = "mobile_zuici",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		local damage = data:toDamage()
		if damage.from and damage.from:isAlive() then
			local _data = sgs.QVariant()
			_data:setValue(damage.from)	
			if room:askForSkillInvoke(player,self:objectName(),_data) then
				for _, mark in sgs.list(damage.from:getMarkNames()) do
					if string.find(mark, "@mobile_dingyi") and damage.from:getMark(mark) > 0 then
						room:setPlayerMark(damage.from, mark, 0)
					end
				end

				local choices = {}
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) and player:getMark("AG_BANCard"..card:objectName()) == 0 then
						if card:isNDTrick() and isZhinang(card) then
							table.insert(choices, card:objectName())
						end
					end
				end
				--table.insert(choices, "binglinchengxia")
				table.insert(choices, "cancel")

				local pattern = room:askForChoice(player, "mobile_zuici", table.concat(choices, "+"))

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
					local move = sgs.CardsMoveStruct()
					move.card_ids = GetCardList
					move.to = damage.from
					move.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(move, true)
				end

			end
		end
		return false
	end,
}

mobile_fubiCard = sgs.CreateSkillCard{
	name = "mobile_fubi" ,
	filter = function(self, selected, to_select)
		return #selected == 0
	end, 
	on_use = function(self, room, source, targets)		
		room:addPlayerMark(source,"mobile_fubi_lun",1)

		local allchoicelist = {"mobile_dingyi1","mobile_dingyi2","mobile_dingyi3","mobile_dingyi4"} 
		local choicelist = {}
		for i=1, #allchoicelist, 1 do
			if targets[1]:getMark("@"..allchoicelist[i]) == 0 then
				table.insert(choicelist, allchoicelist[i])
			end
		end
		table.insert(choicelist, "mobile_fubi_buff")
		local choice = room:askForChoice(source, "mobile_dingyi", table.concat(choicelist, "+"))
		if choice ~= "mobile_fubi_buff" then
			for _, mark in sgs.list(targets[1]:getMarkNames()) do
				if string.find(mark, "@mobile_dingyi") and targets[1]:getMark(mark) > 0 then
					room:setPlayerMark(targets[1], mark, 1)
				end
			end
			room:addPlayerMark(targets[1],"@"..choice)
		else
			for _, mark in sgs.list(targets[1]:getMarkNames()) do
				if string.find(mark, "@mobile_dingyi") and targets[1]:getMark(mark) > 0 then
					room:setPlayerMark(targets[1], mark, 2)
				end
			end
		end
	end,
}

mobile_fubi = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_fubi",
	view_as = function(self,cards)
		return mobile_fubiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("mobile_fubi_lun") == 0
	end
}

mobile_sunshao:addSkill(mobile_dingyi)
mobile_sunshao:addSkill(mobile_fubi)
mobile_sunshao:addSkill(mobile_zuici)

sgs.LoadTranslationTable{
	["mobile_sunshao"] = "手殺孫邵",
	["&mobile_sunshao"] = "孫邵",
	["#mobile_sunshao"] = "弼政之功",
	["mobile_dingyi"] = "定儀",
	["mobile_fubi"] = "輔弼",
	["mobile_zuici"] = "罪辭",
	[":mobile_dingyi"] = "遊戲開始時，你選擇全場角色，令其獲得如下效果之一：摸牌階段摸牌數+1/手牌上限+2/攻擊範圍+1/脫離瀕死狀態時回复1點體力。",
	[":mobile_fubi"] = "每輪限一次，出牌階段，你可以選擇一名角色,並選擇一項:1. 更換其定儀效果; 2. 你棄置1張牌並令其目前擁有的“定儀”效果數值翻倍，直到下一輪你的回合開始時。",
	[":mobile_zuici"] = "當你受到傷害後,你可以令傷害來源失去“定儀”效果，若如此做，其從牌堆中獲得一個你指定的智囊。",
	["mobile_dingyi1"] = "摸牌階段摸牌數+1",
	["mobile_dingyi2"] = "手牌上限+2",
	["mobile_dingyi3"] = "攻擊範圍+1",
	["mobile_dingyi4"] = "脫離瀕死狀態時回复1點體力",
	["mobile_fubi_buff"] = "目前擁有的“定儀”效果數值翻倍",
--[[
["mjdingyi"] = "定儀",
["mjzuici"] = "罪辭",
["mjfubi"] = "輔弼",
]]--
}

--費禕
mobile_feiyi = sgs.General(extension, "mobile_feiyi", "shu2", 3, true,true)

mobile_shengxi = sgs.CreateTriggerSkill{
	name = "mobile_shengxi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if room:askForSkillInvoke(player,self:objectName(), data) then

				local choices = {}
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) and player:getMark("AG_BANCard"..card:objectName()) == 0 then
						if card:isNDTrick() and isZhinang(card) then
							table.insert(choices, card:objectName())
						end
					end
				end

				local pattern = room:askForChoice(player, "mobile_shengxi", table.concat(choices, "+"))

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
					local move = sgs.CardsMoveStruct()
					move.card_ids = GetCardList
					move.to = player
					move.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(move, true)
				end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish 
		and target:getMark("damage_record-Clear") == 0 and target:getMark("used-Clear") > 0
	end
}

mobile_kuanji = sgs.CreateTriggerSkill{
	name = "mobile_kuanji",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			 and player:getMark("mobile_kuanji-Clear") == 0 then
				local ids = sgs.IntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						ids:append(card_id)
					end
				end

				if not ids:isEmpty() then
					room:getThread():delay()
					local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "mobile_kuanji", "@mobile_kuanji-get",true)
					if s then
						room:fillAG(ids,s)
						local id = room:askForAG(s, ids, true, self:objectName())
						room:obtainCard(s,id)
						room:clearAG()
						player:drawCards(1)
						room:addPlayerMark(player,"mobile_kuanji-Clear")
					end
				end
			end
		end
		return false
	end
}

mobile_feiyi:addSkill(mobile_shengxi)
mobile_feiyi:addSkill(mobile_kuanji)

sgs.LoadTranslationTable{
	["mobile_feiyi"] = "手殺費禕",
	["&mobile_feiyi"] = "費禕",
	["mobile_shengxi"] = "生息",
	[":mobile_shengxi"] = "結束階段，若你於此回合內使用過牌且沒有造成過傷害,你可以從遊戲外或牌堆中獲得一張【調劑鹽梅】或智囊。",
	["mobile_kuanji"] = "寬濟",
	[":mobile_kuanji"] = "每回合限一次,當你的牌因棄置而置入棄牌堆時,你可令一名其他角色獲得其中一張牌，然後你摸一張牌。",
	["@mobile_kuanji-get"] = "你可令一名其他角色獲得其中一張牌",
--[[
["mjshengxi"] = "生息",
["mjkuanji"] = "寬濟",
["tiaojiyanmei"] = "調劑鹽梅",
[":tiaojiyanmei"] = "出牌階段，對兩名手牌數不均相同的其他角色使用。若目標角色於此牌使用準備工作結束時的手牌數大於此時所
有目標的平均手牌數，其棄置一張牌。若小於則其摸一張牌。此牌使用結束後，若所有目標角色的手牌數均相等，則你可令一名角色獲得
所有因執行此牌效果而棄置的牌。",
]]--
}

--[[
神太史慈（舊版）
]]--

nos_shen_taishici = sgs.General(extension, "nos_shen_taishici", "god", 4, true, true)

nos_dulieCard = sgs.CreateSkillCard{
	name = "nos_dulieCard",
	mute = true,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < math.floor((sgs.Self:getAliveSiblings():length()+1) / 2) 
	end,
	feasible = function(self, targets)
		return #targets == math.floor((sgs.Self:getAliveSiblings():length()+1) / 2) 
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			room:addPlayerMark(p,"@mobile_wei")
		end
	end
}
nos_dulieVS = sgs.CreateZeroCardViewAsSkill{
	name = "nos_dulie",
	response_pattern = "@@nos_dulie!",
	view_as = function(self, cards)
		return nos_dulieCard:clone()
	end,
}

nos_dulie = sgs.CreateTriggerSkill{
	name = "nos_dulie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.TargetConfirmed},
	view_as_skill = nos_dulieVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:askForUseCard(player, "@@nos_dulie!", "@nos_dulie")
		elseif event == sgs.TargetConfirmed then		
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|red"
					judge.good = true
					judge.play_animation = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then						
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		end
	end
}

nos_duliemc = sgs.CreateDistanceSkill{
	name = "#nos_duliemc",
	correct_func = function(self, from, to)
		if from:hasSkill("nos_dulie") and to:getMark("@mobile_wei") == 0 then
			return - 999
		end
		return 0
	end
}

nos_tspowei = sgs.CreateTriggerSkill{
	name = "nos_tspowei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused,sgs.CardFinished,sgs.EnterDyin},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to:getMark("@mobile_wei") > 0 and player:getMark("@nos_tspowei") == 0 and damage.card and damage.card:isKindOf("Slash") then
				local log = sgs.LogMessage()
			  	log.from = player
				log.to:append(damage.to)
				log.arg = self:objectName()
				log.type = "#Yishi"
				room:sendLog(log)
				room:addPlayerMark(player, self:objectName().."engine")
				room:broadcastSkillInvoke(self:objectName())
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerMark(damage.to,"@mobile_wei",0)
					room:removePlayerMark(player, self:objectName().."engine")
					return true
				end
			end
			return false
		elseif event == sgs.CardFinished and data:toCardUse().card:isKindOf("Slash") then
			local can_invoke = true
			for _,p in sgs.qlist( room:getAlivePlayers() ) do
				if p:getMark("@mobile_wei") > 0 then
					can_invoke = false
				end
			end
			if can_invoke and player:getMark("@nos_tspowei") == 0 then
				room:doSuperLightbox("shen_taishici","nos_tspowei_success")
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player,"@nos_tspowei")
				room:acquireSkill(player, "nos_shenzhu")
			end
		elseif event == sgs.EnterDying then
			if player:getMark("@nos_tspowei") == 0 then
					room:doSuperLightbox("shen_taishici","nos_tspowei_failed")
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player,"@nos_tspowei")
					player:throwAllEquips()
					room:recover(player, sgs.RecoverStruct(player,nil, 1 - player:getHp() ))
			end
		end
	end
}

nos_shenzhu = sgs.CreateTriggerSkill{
	name = "nos_shenzhu" ,
	events = {sgs.CardUsed,sgs.EventPhaseEnd, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (not use.card:isVirtualCard()) and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and 
			  sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):objectName() == use.card:objectName() and use.card:isKindOf("Slash") then
			  	room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
			end
		end
	end,
}

nos_shenzhuTM = sgs.CreateTargetModSkill{
	name = "#nos_shenzhuTM",
	pattern = "Slash",
	residue_func = function(self, from, card)
		if from:hasSkill("nos_shenzhu") then
			return 1000
		else
			return 0
		end
	end,
}
--[[
dangmoCard = sgs.CreateSkillCard{
	name = "dangmo",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("dangmo_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "dangmo_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets < sgs.Self:getHp() - 1 and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets < sgs.Self:getHp() - 1 and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
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
dangmoVS = sgs.CreateZeroCardViewAsSkill{
	name = "dangmo",
	response_pattern = "@@dangmo",
	view_as = function()
		return dangmoCard:clone()
	end
}
]]--
dangmo = sgs.CreateTriggerSkill{
	name = "dangmo",
	events = {sgs.PreCardUsed, sgs.TargetSpecified, sgs.Damage, sgs.Damaged},
	--view_as_skill = dangmoVS,
	on_trigger = function(self, event, player, data, room)
		--[[
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getHp() - 1 > 0 and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, self:objectName())
				end
				if use.card:isVirtualCard() then
					room:setPlayerMark(player, "dangmo_virtual_card", 1)
					room:setPlayerMark(player, "dangmo_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
					room:askForUseCard(player, "@@dangmo", "@dangmo")
					room:setPlayerMark(player, "dangmo_virtual_card", 0)
					room:setPlayerMark(player, "dangmo_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
				elseif not use.card:isVirtualCard() then
					room:setPlayerMark(player, "dangmo_not_virtual_card", 1)
					room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
					room:askForUseCard(player, "@@dangmo", "@dangmo")
					room:setPlayerMark(player, "dangmo_not_virtual_card", 0)
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
		end
		]]--
	end,
}

nos_shen_taishici:addSkill(nos_dulie)
nos_shen_taishici:addSkill(nos_duliemc)
nos_shen_taishici:addSkill(nos_tspowei)
nos_shen_taishici:addSkill(dangmo)
nos_shen_taishici:addRelateSkill("nos_shenzhu")
nos_shen_taishici:addRelateSkill("#nos_shenzhuTM")
if not sgs.Sanguosha:getSkill("nos_shenzhu") then skills:append(nos_shenzhu) end
if not sgs.Sanguosha:getSkill("#nos_shenzhuTM") then skills:append(nos_shenzhuTM) end

sgs.LoadTranslationTable{
["nos_shen_taishici"] = "神太史慈(懷舊)",
["&nos_shen_taishici"] = "神太史慈",
["nos_dulie"] = "篤烈",
[":nos_dulie"] = "鎖定技。①遊戲開始時，你令X名其他角色獲得「圍」（X為遊戲人數的一半且向下取整）。②你對沒有「圍」的角色使用【殺】無距離限制。③當你成為【殺】的目標時，若使用者沒有「圍」，則你進行判定。若結果為紅色，則取消此目標。",
["nos_tspowei"] = "破圍",
[":nos_tspowei"] = "使命技。①當你因使用【殺】而對有「圍」的角色造成傷害時，你防止此傷害並移去該角色的「圍」。②使命：當你使用【殺】結算完成後，若場上沒有「圍」，則你獲得技能〖神著〗。③失敗：當你進入瀕死狀態時，你棄置裝備區的所有牌，然後將體力值回復至1點。",
["nos_tspowei_success"] = "破圍成功",
["nos_tspowei_failed"] = "破圍失敗",
["nos_shenzhu"] = "神著",
[":nos_shenzhu"] = "你使用【殺】無次數限制。當你使用有對應實體牌的非轉化【殺】結算結束後，你摸一張牌。",
["dangmo"] = "蕩魔",
[":dangmo"] = "當你於出牌階段內使用第一張【殺】選擇目標後，你可以為此牌增加至多Y-1個目標（Y為你的體力值）。",
["@mobile_wei"] = "圍",
["@dangmo"] = "你可以發動“蕩魔”",
["~dangmo"] = "選擇目標角色→點“確定”",
["@nos_dulie"] = "你可以發動“篤烈”",
["~nos_dulie"] = "選擇目標角色→點“確定”",
}

--[[
神太史慈
]]--

shen_taishici = sgs.General(extension, "shen_taishici", "god", 4, true)

dulie = sgs.CreateTriggerSkill{
	name = "dulie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.TargetConfirmed},
	view_as_skill = dulieVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			for _,p in sgs.qlist( room:getOtherPlayers(player) ) do
				room:addPlayerMark(p,"@mobile_wei")
			end
		elseif event == sgs.TargetConfirmed then		
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.good = true
					judge.play_animation = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then						
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		end
	end
}

duliemc = sgs.CreateDistanceSkill{
	name = "#duliemc",
	correct_func = function(self, from, to)
		if from:hasSkill("dulie") and to:getMark("@mobile_wei") == 0 then
			return - 999
		end
		return 0
	end
}

tspowei = sgs.CreateTriggerSkill{
	name = "tspowei",
	events = {sgs.DamageCaused,sgs.CardFinished,sgs.EnterDying},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to:getMark("@mobile_wei") > 0 and player:getMark("@tspowei") == 0 and damage.card and damage.card:isKindOf("Slash") then
				local log = sgs.LogMessage()
			  	log.from = player
				log.to:append(damage.to)
				log.arg = self:objectName()
				log.type = "#Yishi"
				room:sendLog(log)
				room:addPlayerMark(player, self:objectName().."engine")
				room:broadcastSkillInvoke(self:objectName())
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerMark(damage.to,"@mobile_wei",0)
					room:removePlayerMark(player, self:objectName().."engine")
					return true
				end
			end
			return false
		elseif event == sgs.CardFinished and data:toCardUse().card:isKindOf("Slash") then
			local can_invoke = true
			for _,p in sgs.qlist( room:getOtherPlayers(player) ) do
				if p:getMark("@mobile_wei") > 0 then
					can_invoke = false
				end
			end
			if can_invoke and player:getMark("@tspowei") == 0 then
				room:doSuperLightbox("shen_taishici","tspowei_success")
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player,"@tspowei")
				room:acquireSkill(player, "shenzhu")
			end
		elseif event == sgs.EnterDying then
			if player:getMark("@tspowei") == 0 then
					room:doSuperLightbox("shen_taishici","tspowei_failed")
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player,"@tspowei")
					room:recover(player, sgs.RecoverStruct(player,nil, 1 - player:getHp() ))
					player:throwAllEquips()
			end
		end
	end
}

shenzhu = sgs.CreateTriggerSkill{
	name = "shenzhu" ,
	events = {sgs.CardUsed,sgs.EventPhaseEnd, sgs.CardResponded} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (not use.card:isVirtualCard()) and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and 
			  sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):objectName() == use.card:objectName() and use.card:isKindOf("Slash") then
			  	room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
			end
		end
	end,
}

shenzhuTM = sgs.CreateTargetModSkill{
	name = "#shenzhuTM",
	pattern = "Slash",
	residue_func = function(self, from, card)
		if from:hasSkill("shenzhu") then
			return 1000
		else
			return 0
		end
	end,
}


shen_taishici:addSkill(dulie)
shen_taishici:addSkill(duliemc)
shen_taishici:addSkill(tspowei)
shen_taishici:addSkill(dangmo)
shen_taishici:addRelateSkill("shenzhu")
shen_taishici:addRelateSkill("#shenzhuTM")
if not sgs.Sanguosha:getSkill("shenzhu") then skills:append(shenzhu) end
if not sgs.Sanguosha:getSkill("#shenzhuTM") then skills:append(shenzhuTM) end

sgs.LoadTranslationTable{
["shen_taishici"] = "神太史慈",
["dulie"] = "篤烈",
[":dulie"] = "鎖定技。①遊戲開始時，你令所有其他角色獲得「圍」。②你對沒有「圍」的角色使用【殺】無距離限制。③當你成為【殺】的目標時，若使用者沒有「圍」，則你進行判定。若結果為紅桃，則取消此目標。",
["tspowei"] = "破圍",
[":tspowei"] = "使命技。①當你因使用【殺】而對有「圍」的角色造成傷害時，你防止此傷害並移去該角色的「圍」。②使命：當你使用【殺】結算完成後，若場上沒有「圍」，則你獲得技能〖神著〗。③失敗：當你進入瀕死狀態時，將體力值回復至1點，然後你棄置裝備區的所有牌。",
["tspowei_success"] = "破圍成功",
["tspowei_failed"] = "破圍失敗",
["shenzhu"] = "神著",
[":shenzhu"] = "你使用【殺】無次數限制。當你使用有對應實體牌的非轉化【殺】結算結束後，你摸一張牌。",
["dangmo"] = "蕩魔",
[":dangmo"] = "當你於出牌階段內使用第一張【殺】選擇目標後，你可以為此牌增加至多Y-1個目標（Y為你的體力值）。",
["@mobile_wei"] = "圍",
["@dangmo"] = "你可以發動“蕩魔”",
["~dangmo"] = "選擇目標角色→點“確定”",
["@dulie"] = "你可以發動“篤烈”",
["~dulie"] = "選擇目標角色→點“確定”",
}

--蔡貞姬
caizhenji = sgs.General(extension, "caizhenji", "wei2", 3, false)

sheyi = sgs.CreateTriggerSkill{
	name = "sheyi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if player:objectName() ~= p:objectName() and player:getHp() < p:getHp() then
				room:doAnimate(1, p:objectName(), player:objectName())
				room:setPlayerMark(player,"sheyi_target",1)
				local cards = room:askForExchange(p, self:objectName(), 9999, p:getHp() , true, "@sheyi:"..tostring(p:getHp()), true)
				room:setPlayerMark(player,"sheyi_target",0)
				if cards then					
					player:obtainCard(cards)

					local msg = sgs.LogMessage()
					msg.type = "#SheyiProtect"
					msg.from = p
					msg.to:append(player)
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
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}

tianyin = sgs.CreateTriggerSkill{
	name = "tianyin", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local types = {"BasicCard", "TrickCard", "EquipCard"}
				local can_get_types = {}
				for i = 1,3,1 do
					if player:getMark("used_cardtype"..tostring(i).."-Clear") > 0 then
						table.insert(can_get_types,types[i])
					end
				end
				if #can_get_types > 0 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					getpatterncard_for_each_pattern(player, can_get_types, true,false)
				end

			end
		end
	end
}

caizhenji:addSkill(sheyi)
caizhenji:addSkill(tianyin)


sgs.LoadTranslationTable{
["caizhenji"] = "蔡貞姬",
["sheyi"] = "捨裔",
[":sheyi"] = "當有體力值小於你的其他角色受到傷害時，你可以交給其至少X張牌並防止此傷害（X為你的體力值）。",
["@sheyi"] = "你可以交給其至少 %src 張牌並防止此傷害。",
["tianyin"] = "天音",
[":tianyin"] = "鎖定技，結束階段開始時，你從牌堆中獲得每種本回合未使用過的類型的牌各一張。",
["#SheyiProtect"] = "%from 發動「<font color=\"yellow\"><b>捨裔</b></font>」， %to 防止了 %arg 點傷害[%arg2]",
}

--向寵
xiangchong = sgs.General(extension, "xiangchong", "shu2", 3, true)

guying = sgs.CreateTriggerSkill{
	name = "guying",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local current = room:getCurrent()
		if event == sgs.CardsMoveOneTime and player:getPhase() == sgs.Player_NotActive and current:getMark("guying"..player:objectName().."_-Clear") == 0 then
			local move = data:toMoveOneTime()
			local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if move.from and move.from:objectName() == player:objectName() and move.card_ids:length() == 1 and 
			  (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and 
			  (extract == sgs.CardMoveReason_S_REASON_DISCARD or extract == sgs.CardMoveReason_S_REASON_USE or extract == sgs.CardMoveReason_S_REASON_RESPONSE) then
			  	
			  	room:addPlayerMark(player,"@mobile_gu")
			  	room:addPlayerMark(current,"guying"..player:objectName().."_-Clear" )

			  	local choice = room:askForChoice(current, self:objectName(), "guying1+guying2" )
			  	ChoiceLog(current, choice, player)
				if choice == "guying1" then
					local loot_cards = sgs.QList2Table(current:getCards("he"))
					if #loot_cards > 0 then
						room:obtainCard(player, loot_cards[math.random(1, #loot_cards)], false)
					end
				elseif choice == "guying2" then
					local ids = sgs.IntList()
					for _,id in sgs.qlist(move.card_ids) do
						if room:getCardPlace(id) == sgs.Player_DiscardPile then
							ids:append(id)
						end
					end

					if ids:length() > 0 then
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = player
						move.to_place = sgs.Player_PlaceHand
						room:moveCardsAtomic(move, true)
						local card = sgs.Sanguosha:getCard(ids:at(0))

						if card:getTypeId() == sgs.Card_TypeEquip and room:getCardOwner(card:getEffectiveId()):objectName() == player:objectName() and not player:isLocked(card) then		
							room:useCard(sgs.CardUseStruct(card, player, player))						
						end

					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local n = player:getMark("@mobile_gu")
			if player:getMark("@mobile_gu") > 0 then
				room:askForDiscard(player, self:objectName(), n, n)
				room:setPlayerMark(player,"@mobile_gu",0)
			end
		end
		return false
	end
}

muzhenCard = sgs.CreateSkillCard{
	name = "muzhen",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, erzhang)
		if self:getSubcards():length() == 1 then
			if #targets ~= 0 or to_select:objectName() == erzhang:objectName() then return false end
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local equip = card:getRealCard():toEquipCard()
			local equip_index = equip:location()
			return to_select:getEquip(equip_index) == nil
		else
			return to_select:getEquips():length() > 0
		end
	end,
	on_use = function(self, room, source, targets)
		local usetype
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isEquipped() then				
				usetype = "muzhen2"
			else
				usetype = "muzhen1"
			end
		end

		if usetype == "muzhen1" then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "muzhen","")
			room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
			if targets[1]:getEquips():length() > 0 then
				local card = room:askForCardChosen(source, targets[1], "e", self:objectName())
				room:obtainCard(source, card, false)
				room:addPlayerMark(source,"muzhen1_Play" )
			end
		elseif usetype == "muzhen2" then
			room:moveCardTo(self, source, targets[1], sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "muzhen", ""))
			if not targets[1]:isNude() then
				local card = room:askForCardChosen(source,targets[1], "he", self:objectName())
				room:obtainCard(source, card, false)
				room:addPlayerMark(source,"muzhen2_Play" )
			end
		end

	end
}
muzhen = sgs.CreateViewAsSkill{
	name = "muzhen",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			if sgs.Self:getMark("muzhen1_Play") == 0 or sgs.Self:getMark("muzhen2_Play") == 0 then
				return true
			end
		elseif #selected == 1 and not selected[1]:isEquipped() and sgs.Self:getMark("muzhen1_Play") == 0 then
			return not to_select:isEquipped()
		end
	end,
	view_as = function(self, cards)
		local usetype

		for _, c in ipairs(cards) do
			if c:isEquipped() then
				usetype = "muzhen2"
			else
				usetype = "muzhen1"
			end
		end
		if (usetype == "muzhen2" and #cards == 1) or (usetype == "muzhen1" and #cards == 2) then
			local skillcard = muzhenCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			skillcard:setSkillName(self:objectName())
			return skillcard
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("muzhen1_Play") == 0 or player:getMark("muzhen2_Play") == 0
	end
}

xiangchong:addSkill(guying)
xiangchong:addSkill(muzhen)

sgs.LoadTranslationTable{
["xiangchong"] = "向寵",
["guying"] = "固營",
[":guying"] = "鎖定技。每回合限一次，當你於回合外因使用/打出/棄置而失去牌後，若牌數為1，則你獲得一枚「固」並令當前回合角色選擇一項：①隨機交給你一張牌。②令你獲得本次失去的牌，若為裝備牌，則你使用之。準備階段開始時，你移去所有「固」並棄置等量的牌。",
["guying1"] = "隨機交給你一張牌",
["guying2"] = "令你獲得本次失去的牌，若為裝備牌，則你使用之",
["muzhen"] = "睦陣",
[":muzhen"] = "出牌階段各限一次。①你可以將兩張牌交給一名裝備區內有牌的其他角色，然後獲得其裝備區內的一張牌。②你可以將裝備區內的一張牌置於其他角色的裝備區內，然後獲得其一張牌。",
}

--手殺華歆
nos_mobile_huaxin = sgs.General(extension, "nos_mobile_huaxin", "wei2", 3, true, true, true)

hxrenshiCard = sgs.CreateSkillCard{
	name = "hxrenshi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName() and (not sgs.Self:hasUsed("#hxrenshi") or  to_select:getMark(self:objectName().."_Play") == 0)
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:addPlayerMark(source, self:objectName().."_Play", self:getSubcards():length())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "hxrenshi", "")
			room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)
			room:addPlayerMark(targets[1], self:objectName().."_Play")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end,
}

hxrenshi = sgs.CreateOneCardViewAsSkill{
	name = "hxrenshi",
	view_filter = function(self, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, card) 
		local cards = hxrenshiCard:clone()
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
}

debao = sgs.CreateTriggerSkill{
	name = "debao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
			local lord_player
			for _, pp in sgs.qlist(room:getAlivePlayers()) do
				if pp:isLord() or pp:getMark("@clock_time") > 0 then
					lord_player = pp
					break
				end
			end

		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()

			if move.to and move.to:objectName() ~= player:objectName() and move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand then
				if lord_player:getPile("mobile_ren_area"):length() < player:getMaxHp() then
					room:notifySkillInvoked( player , self:objectName())
					room:sendCompulsoryTriggerLog( player , self:objectName())
					room:broadcastSkillInvoke(self:objectName())

					local list = sgs.IntList()
					for _, id in sgs.qlist(room:getDrawPile()) do
						list:append(id)
						break
					end
					lord_player:addToPile("mobile_ren_area", list)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if not lord_player:getPile("mobile_ren_area"):isEmpty() and player:getPhase() == sgs.Player_RoundStart then
				room:notifySkillInvoked( player , self:objectName())
				room:sendCompulsoryTriggerLog( player , self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist( lord_player:getPile("mobile_ren_area") ) do
					dummy:addSubcard(id)
				end
				room:obtainCard(player, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName()), false)
				dummy:deleteLater()
			end
		end
		return false
	end,
}

buqi = sgs.CreateTriggerSkill{
	name = "buqi",
	events = {sgs.EnterDying, sgs.Death},
	--view_as_skill = buqiVS,
	can_trigger = function(self, player)
		return player ~= nil 
	end,
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end

		if event == sgs.EnterDying then

			local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
			room:sortByActionOrder(players)
			if lord_player then
				for _, p in sgs.qlist(players) do
					if lord_player:getPile("mobile_ren_area"):length() >= 2 then
						room:fillAG(lord_player:getPile("mobile_ren_area"), p)
						local dummycard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
						dummycard:deleteLater()
						local ids = lord_player:getPile("mobile_ren_area")

						for i = 1, 2 do
							local id = room:askForAG(p, ids, true, self:objectName())
							local card = sgs.Sanguosha:getCard(id)
				 			dummycard:addSubcard(card)
				 			ids:removeOne(id)
							room:takeAG(p, id, false)
						end
						room:throwCard(dummycard,p,p)
						room:clearAG(p)
						if player:isWounded() then
							room:recover(player, sgs.RecoverStruct(player, nil, 1  ))
						end
					end
				end
			end
		elseif event == sgs.Death and RIGHT(self, player) then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			if player:isAlive() and lord_player:getPile("mobile_ren_area"):length() > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist( lord_player:getPile("mobile_ren_area") ) do
					dummy:addSubcard(id)
				end
				room:throwCard(dummy,nil,player)
				dummy:deleteLater()
			end
		end
	end,
}

nos_mobile_huaxin:addSkill(hxrenshi)
nos_mobile_huaxin:addSkill(debao)
nos_mobile_huaxin:addSkill(buqi)

sgs.LoadTranslationTable{
["nos_mobile_huaxin"] = "手殺華歆--懷舊",
["&nos_mobile_huaxin"] = "華歆",
["hxrenshi"] = "仁仕",
[":hxrenshi"] = "出牌階段每名角色限一次。你可以將一張手牌交給一名其他角色。",
["debao"] = "德保",
[":debao"] = "鎖定技，當其他角色獲得你的牌後，若「仁區」的牌數小於你的體力上限，則你將牌堆頂的一張牌置於「仁區」。準備階段，你獲得所有「仁區」的牌。",
["buqi"] = "不棄",
[":buqi"] = "鎖定技，當有角色進入瀕死狀態時，若「仁區」的牌數大於1，則你移去兩張「仁區」並令其回復1點體力。一名角色死亡後，你將所有「仁區」置入棄牌堆。",
["mobile_ren_area"] = "仁區",
}
--手殺許靖
mobile_xujing = sgs.General(extension, "mobile_xujing", "shu2", 3, true)

bomingCard = sgs.CreateSkillCard{
	name = "boming",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:addPlayerMark(source, self:objectName().."-Clear",1)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "boming", "")
			room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end,
}
bomingVS = sgs.CreateOneCardViewAsSkill{
	name = "boming",
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, card) 
		local cards = bomingCard:clone()
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and player:usedTimes("#boming") < 2
	end
}

boming = sgs.CreateTriggerSkill{
	name = "boming",
	view_as_skill = bomingVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getMark(self:objectName().."-Clear") >= 2 and player:getPhase() == sgs.Player_Finish then
			room:notifySkillInvoked( player , self:objectName())
			room:sendCompulsoryTriggerLog( player , self:objectName())
			player:drawCards(1)
			
		end
	end
}

ejian = sgs.CreateTriggerSkill{
	name = "ejian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	priority = -1,
	on_trigger = function(self, event, player, data, room)

		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() ~= player:objectName() and move.from and move.from:objectName() == player:objectName() and
			 (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and
			  move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceHand and
			  move.card_ids:length() == 1 and move.reason.m_skillName and move.reason.m_skillName == "boming" and move.to:isAlive() then

				room:notifySkillInvoked( player , self:objectName())
				room:sendCompulsoryTriggerLog( player , self:objectName())
				room:broadcastSkillInvoke(self:objectName())

				for _,id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					room:setPlayerMark( BeMan(room, move.to) , "ejianTypeId" , card:getTypeId())
				end

				local n = BeMan(room, move.to):getMark("ejianTypeId")

				local ids = sgs.IntList()
				for _,c in sgs.qlist( BeMan(room, move.to):getCards("he") ) do
					if c:getTypeId() == n then
						ids:append(c:getEffectiveId())
					end
				end

				local types = {"BasicCard", "TrickCard", "EquipCard"}
				if room:askForSkillInvoke(BeMan(room, move.to), "ejian_discard", sgs.QVariant("prompt:".. types[n] )) then
					if not ids:isEmpty() then
						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = nil
						move.to_place = sgs.Player_DiscardPile
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "ejian", nil)
						room:moveCardsAtomic(move, true)
					end
				else
					room:damage(sgs.DamageStruct(nil,nil,BeMan(room, move.to),1,sgs.DamageStruct_Normal))
				end
			end
		end
		return false
	end,
}

mobile_xujing:addSkill(boming)
mobile_xujing:addSkill(ejian)

sgs.LoadTranslationTable{
["mobile_xujing"] = "手殺許靖",
["&mobile_xujing"] = "許靖",
["boming"] = "博名",
[":boming"] = "出牌階段限兩次，你可以將一張牌交給一名其他角色。結束階段，若你本回合以此法失去了兩張以上的牌，則你摸一張牌。",
["ejian"] = "惡薦",
[":ejian"] = "鎖定技，每名角色限一次。當有其他角色因〖博名〗而獲得了你的牌後，若其擁有與此牌類型相同的其他牌，則你令其選擇一項：①受到1點傷害。②展示所有手牌，並棄置所有與此牌類別相同的牌。",
["ejian_discard:prompt"] = "你可以展示所有手牌並棄置所有 %arg 牌",
}

mobile_zhongyong = sgs.CreateTriggerSkill{
	name = "mobile_zhongyong",
	events = {sgs.SlashMissed, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.SlashMissed then
			room:addPlayerMark(player, self:objectName()..data:toSlashEffect().jink:getEffectiveId())
		else
			local use = data:toCardUse()
			local friends = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not use.to:contains(player) then
					friends:append(p)
				end
			end
			for _,p in sgs.qlist(use.to) do
				friends:removeOne(p)
			end
			if use.card and use.card:isKindOf("Slash") then
				local jink, slash = sgs.IntList(), sgs.IntList()
				for _, id in sgs.list(use.card:getSubcards()) do
					if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
						slash:append(id)
					end
				end
				local has_slash_miss = false
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, self:objectName()) and player:getMark(mark) > 0 then
						local id = tonumber(string.sub(mark, 17, string.len(mark)))
						if room:getCardPlace(id) ~= sgs.Player_PlaceTable and room:getCardPlace(id) ~= sgs.Player_DiscardPile then continue end
						jink:append(id)
						room:setPlayerMark(player, mark, 0)
						has_slash_miss = true
					end
				end

				if has_slash_miss then
					local choices = {"mobile_zhongyong1"}
					if not friends:isEmpty() then
						table.insert(choices, "mobile_zhongyong2")
					end
					table.insert(choices, "cancel")

					local choice = room:askForChoice(player, "mobile_zhongyong", table.concat(choices, "+"))
					ChoiceLog(player, choice)
					if choice == "mobile_zhongyong1" then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						--skill(self, room, player, false)
						dummy:addSubcards(jink)
						room:obtainCard(player, dummy)

						if not friends:isEmpty() then
							local friend = room:askForPlayerChosen(player, friends, self:objectName(), "@mobile_zhongyong", false, true)
							if friend then
								room:broadcastSkillInvoke(self:objectName(), 1)
								local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								dummy:addSubcards(slash)
								room:obtainCard(friend, dummy)
							end
						end
					elseif choice == "mobile_zhongyong2" then
						if not friends:isEmpty() then
							local friend = room:askForPlayerChosen(player, friends, self:objectName(), "@mobile_zhongyong", false, true)
							if friend then
								room:broadcastSkillInvoke(self:objectName(), 1)
								local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								dummy:addSubcards(jink)
								room:obtainCard(friend, dummy)
							end
						end
					end
				else
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						skill(self, room, player, false)
						dummy:addSubcards(slash)
						room:obtainCard(player, dummy)
					end
				end
			end
		end
		return false
	end
}

sgs.LoadTranslationTable{
["xin_zhoucang"] = "手殺周倉",
["mobile_zhongyong"] = "忠勇",
[":mobile_zhongyong"] = "當你於出牌階段使用【殺】結算結束後，若沒有目標角色使用【閃】響應過此【殺】，則你可獲得此【殺】；否則你可選擇一項：①獲得目標角色使用的【閃】，然後可將此【殺】交給另一名其他角色。②將目標角色使用的【閃】交給另一名其他角色，然後你本回合使用【殺】的次數上限+1且下一張【殺】的傷害值基數+1。（你不能使用本回合因執行〖忠勇〗的效果獲得的牌）",
}

--[[
張仲景，群，3/3
〖病論〗出牌階段限一次，你可以選擇一名角色並棄置一張「仁」令其選擇：摸一張牌，或於其回合結束後回復1點體力。

〖療疫〗其他角色回合開始時，若其手牌數小於體力值且場上「仁」數量不小於X，則你可以令其獲得場上X張「仁」；若其手牌數
大於體力值，則令其將X張牌置於「仁」中。(X為其手牌數與體力值差值，且至多為4)

〖濟世〗鎖定技，你使用牌結算結束後，若此牌沒有造成傷害，且此牌仍在棄牌堆中。則將其置於「仁」中；當「仁」牌離開「仁」區時，
你摸一張牌。

]]--

--張仲景
zhangzhongjing = sgs.General(extension, "zhangzhongjing", "qun3", 3, true)

binglunCard = sgs.CreateSkillCard{
	name = "binglun",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)

		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end

		if lord_player:getPile("mobile_ren_area"):length() > 0 then
			room:fillAG(lord_player:getPile("mobile_ren_area"), source)
			local dummycard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			dummycard:deleteLater()
			local ids = lord_player:getPile("mobile_ren_area")

			local id = room:askForAG(source, ids, true, self:objectName())
			if id ~= -1 then
				room:throwCard(sgs.Sanguosha:getCard(id), nil, source)
				
				room:clearAG(source)

				local choice = room:askForChoice(source, "binglun" , "binglun1+binglun2")
				ChoiceLog(source, choice)
				if choice == "binglun1" then
					targets[1]:drawCards(1)
				elseif choice == "binglun2" then
					room:addPlayerMark(targets[1],"binglun_rec_flag")
				end			
			end
		end
	end
}
binglun = sgs.CreateZeroCardViewAsSkill{
	name = "binglun",
	view_as = function(self, cards)
		return binglunCard:clone()
	end,
	enabled_at_play = function(self, player)

		local lord_player
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:isLord() or p:getMark("@clock_time") > 0 then
				lord_player = p
				break
			end
		end

		if player:isLord() or player:getMark("@clock_time") > 0 then
			lord_player = player
		end
		if lord_player then
			return not player:hasUsed("#binglun") and lord_player:getPile("mobile_ren_area"):length() > 0
		end
	end
}

binglun_rec = sgs.CreateTriggerSkill{
	name = "binglun_rec",
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			if player:getMark("binglun_rec_flag") > 0 then
				room:recover(player, sgs.RecoverStruct(p, nil, 1  ))
			end
		end
	end,
}

if not sgs.Sanguosha:getSkill("binglun_rec") then skills:append(binglun_rec) end

function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

liaoyi = sgs.CreateTriggerSkill{
	name = "liaoyi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end

		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and p:objectName() ~= player:objectName() then
				local x = math.min(4, math.abs(player:getHp() - player:getHandcardNum()) )
				if player:getHp() > player:getHandcardNum() and lord_player:getPile("mobile_ren_area"):length() > x then
					local _data = sgs.QVariant()
					_data:setValue(player)
					if room:askForSkillInvoke(p, "liaoyi-get", _data) then
						room:broadcastSkillInvoke(self:objectName())
						local card_ids = lord_player:getPile("mobile_ren_area")
						room:fillAG(card_ids)
						local to_get = sgs.IntList()
						for i = 1,x,1 do
							if not card_ids:isEmpty() then
								local card_id = room:askForAG(player, card_ids, false, "shelie")
								card_ids:removeOne(card_id)
								to_get:append(card_id)
								room:takeAG(player, card_id, false)
							end
						end
						room:clearAG()

						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						if not to_get:isEmpty() then
							dummy:addSubcards(getCardList(to_get))
							player:obtainCard(dummy)
						end
					end
				else
					if player:getHp() < player:getHandcardNum() then
						local x = math.min(4, math.abs(player:getHandcardNum() - player:getHp()) )
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForSkillInvoke(p, "liaoyi-put", _data) then
							local cards = room:askForExchange(player, self:objectName(), x, x, true, "@liaoyi:"..tostring(x))
							room:broadcastSkillInvoke(self:objectName())
							lord_player:addToPile("mobile_ren_area", cards:getSubcards())

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

mobile_jishi = sgs.CreateTriggerSkill{
	name = "mobile_jishi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end

		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from_places and move.from_places:contains(sgs.Player_PlaceSpecial) then
				local can_invoke = false
				for _, id in sgs.qlist(move.card_ids) do
					if lord_player:getPile("mobile_ren_area"):contains( id ) and move.reason.m_skillName ~= "mobile_ren_area_limit" then
						can_invoke = true
					end
				end
				if can_invoke then
					room:addPlayerMark(player, self:objectName().."engine", 2)
					if player:getMark(self:objectName().."engine") > 0 then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1)
					end
				end
			end

		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and not use.card:hasFlag("damage_record") then
				local list = sgs.IntList()
				if use.card:getSubcards():length() > 0 then
					for _, id in sgs.qlist(use.card:getSubcards()) do
						if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
							list:append(id)
						end
					end
				else
					local id = use.card:getEffectiveId()
					if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DiscardPile then
						list:append(id)
					end
				end
				if list:length() > 0 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					lord_player:addToPile("mobile_ren_area", list)
				end
			end
		end
		return false
	end
}

zhangzhongjing:addSkill(binglun)
zhangzhongjing:addSkill(liaoyi)
zhangzhongjing:addSkill(mobile_jishi)

sgs.LoadTranslationTable{
["zhangzhongjing"] = "張仲景",
["#zhangzhongjing"] = "醫理聖哲",
["binglun"] = "病論",
[":binglun"] = "出牌階段限一次，你可以選擇一名角色並棄置一張「仁」令其選擇：摸一張牌，或於其回合結束後回復1點體力。",
["binglun1"] = "摸一張牌",
["binglun2"] = "於你的回合結束後回復1點體力。",
["liaoyi"] = "療疫",
[":liaoyi"] = "他角色回合開始時，若其手牌數小於體力值且場上「仁」數量不小於X，則你可以令其獲得場上X張「仁」；若其手牌數"
.."大於體力值，則令其將X張牌置於「仁」中。(X為其手牌數與體力值差值，且至多為4)",
["liaoyi-get"] = "療疫拿牌",
["liaoyi-put"] = "療疫放牌",
["@liaoyi"] = "將 %src 張牌置於「仁」中",
["mobile_jishi"] = "濟世",
[":mobile_jishi"] = "鎖定技，你使用牌結算結束後，若此牌沒有造成傷害，且此牌仍在棄牌堆中。則將其置於「仁」中；當「仁」牌不因溢出離開「仁」"
.."區時，你摸一張牌。",
}


--[[
張溫，吳，3/3
〖艾帛〗鎖定技，一名角色回復體力後，你從牌堆頂將一張牌置於「仁」中。

〖頌蜀〗一名體力值大於你的其他角色的摸牌階段開始時，若「仁」區有牌，你可以令其放棄摸牌，然後獲得X張「仁」
（X為你的體力值且最大為5）。其若如此做，本回合其使用牌時不能指定其他角色為目標。 
]]--
mobile_zhangwen = sgs.General(extension, "mobile_zhangwen", "wu2", 3, true)

gebo = sgs.CreateTriggerSkill{
	name = "gebo",
	events = {sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end

		if event == sgs.HpRecover then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local list = sgs.IntList()
				for _, id in sgs.qlist(room:getDrawPile()) do
					list:append(id)
					break
				end
				room:notifySkillInvoked(p, self:objectName())
				room:sendCompulsoryTriggerLog(p, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				lord_player:addToPile("mobile_ren_area", list)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

mobile_songshu = sgs.CreateTriggerSkill{
	name = "mobile_songshu",
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end

		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.DrawNCards and p:objectName() ~= player:objectName() then
				if player:getHp() > p:getHp() and lord_player:getPile("mobile_ren_area"):length() > 0 then
					local _data = sgs.QVariant()
					_data:setValue(player)
					if room:askForSkillInvoke(p, "mobile_songshu", _data) then
						room:broadcastSkillInvoke(self:objectName())
						local x = math.min(p:getHp(),5)
						local x = math.min(x,lord_player:getPile("mobile_ren_area"):length())
						local card_ids = lord_player:getPile("mobile_ren_area")
						room:fillAG(card_ids)
						local to_get = sgs.IntList()
						for i = 1,x,1 do
							if not card_ids:isEmpty() then
								local card_id = room:askForAG(player, card_ids, false, "shelie")
								card_ids:removeOne(card_id)
								to_get:append(card_id)
								room:takeAG(p, card_id, false)
							end
						end
						room:clearAG()

						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						if not to_get:isEmpty() then
							dummy:addSubcards(getCardList(to_get))
							player:obtainCard(dummy)
						end

						local msg = sgs.LogMessage()
						msg.type = "#ComZishou"
						msg.from = player
						msg.arg = "mobile_songshu"
						room:sendLog(msg)
						room:addPlayerMark(player, "beizhan_ban-Clear")

						data:setValue(0)
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

mobile_zhangwen:addSkill(gebo)
mobile_zhangwen:addSkill(mobile_songshu)

sgs.LoadTranslationTable{
["mobile_zhangwen"] = "手殺張溫",
["&mobile_zhangwen"] = "張溫",
["gebo"] = "艾帛",
[":gebo"] = "鎖定技，一名角色回復體力後，你從牌堆頂將一張牌置於「仁」中。",

["mobile_songshu"] = "頌蜀",
[":mobile_songshu"] = "一名體力值大於你的其他角色的摸牌階段開始時，若「仁」區有牌，你可以令其放棄摸牌，然後獲得X張「仁」"..
"（X為你的體力值且最大為5）。其若如此做，本回合其使用牌時不能指定其他角色為目標。 ",
}

--[[
橋公，吳，3/3
〖遺珠〗結束階段，你須摸2張牌，然後選擇2張牌作為「遺珠」，隨機洗入牌堆頂前2X張牌中（X場上角色數)，並記錄「遺珠」牌的牌名
；其他角色使用「遺珠」牌指定唯一目標時，你可以取消之，然後你可以重新使用此牌；或者在「遺珠」牌進入棄牌堆時，你摸1張牌。

〖鸞儔〗出牌階段限一次，你可以移除場上所有「姻」標記並選擇2名角色，令其獲得「姻」標記。擁有「姻」標記的角色，擁有技能
「共患」。

※〖共患〗鎖定技，每回合限一次，當另一名擁有「姻」標記的角色受到傷害時，若其體力值小於你，你將此傷害轉移給自己。 

]]--
qiaogong = sgs.General(extension, "qiaogong", "wu2", "3", true)

yizhuUseCard = sgs.CreateSkillCard{
	name = "yizhuUse",
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
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card_for_use) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card_for_use, use.from, targets_list))
	end
}

yizhuCard = sgs.CreateSkillCard{
	name = "yizhu",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local alive_num = room:getAlivePlayers():length()
		if room:getDrawPile():length() >= alive_num then
			local choices = {}
			for i = 1 , self:getSubcards():length(), 1 do
				local card_id = self:getSubcards():at(i-1)
				local ids = room:getNCards(math.random(1,2*alive_num), false)
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), source, sgs.Player_DrawPile)
				
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:addPlayerMark(p, self:objectName()..card_id..source:objectName())
				end

				room:returnToTopDrawPile(ids)
			end			
			--room:setPlayerMark(source, "yizhu_drawpile", 1)
		end
	end
}
yizhuVS = sgs.CreateViewAsSkill{
	name = "yizhu",
	n = 2,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@yizhu1!" then
			return #selected < 2 and not to_select:isEquipped()
		elseif pattern == "@@yizhu2" then
			return to_select:hasFlag(self:objectName())
		end
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@yizhu1!" then
			if #cards == 2 then
				local skillcard = yizhuCard:clone()
				for _, c in ipairs(cards) do
					skillcard:addSubcard(c)
				end
				skillcard:setSkillName(self:objectName())
				return skillcard
			end
		elseif pattern == "@@yizhu2" then
			if #cards == 1 then
				local skillcard = yizhuUseCard:clone()
				for _, c in ipairs(cards) do
					skillcard:addSubcard(c)
				end
				skillcard:setSkillName(self:objectName())
				return skillcard
			end
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@yizhu")
	end
}

yizhu = sgs.CreateTriggerSkill{
	name = "yizhu",
	events = {sgs.CardUsed,sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	view_as_skill = yizhuVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event  == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and (not use.card:isKindOf("SkillCard")) and (not use.card:isKindOf("EquipCard")) and use.to:length() == 1  then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.from:getMark(self:objectName()..use.card:getId()..p:objectName()) > 0 then
						room:setCardFlag(use.card , "yizhu_card")
						room:setPlayerFlag(p , "yizhu_target")
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:getThread():delay(100)
						local msg = sgs.LogMessage()
						msg.type = "$yizhu"
						msg.from = use.from
						msg.to:append(p)
						msg.arg = self:objectName()
						msg.card_str = use.card:toString()
						room:sendLog(msg)

						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							room:removePlayerMark(pp,self:objectName()..use.card:getId()..p:objectName())
						end

						local ids = sgs.IntList()
						local id = use.card:getEffectiveId()
						ids:append(id)

						local move2 = sgs.CardsMoveStruct(id, nil, nil, sgs.Player_DiscardPile, sgs.Player_DrawPile, sgs.CardMoveReason())
						room:moveCardsAtomic(move2, false)

						room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
						room:setPlayerFlag(p, "Fake_Move")
						local _guojia = sgs.SPlayerList()
						_guojia:append(p)
						local move = sgs.CardsMoveStruct(ids, nil, p, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
						local moves = sgs.CardsMoveList()
						moves:append(move)
						room:notifyMoveCards(true, moves, false, _guojia)
						room:notifyMoveCards(false, moves, false, _guojia)
						room:askForUseCard(p, "@@yizhu2", "@yizhu_useCard")
						local move_to = sgs.CardsMoveStruct(ids, p, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
						local moves_to = sgs.CardsMoveList()
						moves_to:append(move_to)
						room:notifyMoveCards(true, moves_to, false, _guojia)
						room:notifyMoveCards(false, moves_to, false, _guojia)
						room:setPlayerFlag(p, "-Fake_Move")

						room:setPlayerFlag(p, "-yizhu_target")
						room:setCardFlag(sgs.Sanguosha:getCard(id), "-yizhu_card")	

						return true
					end
				end
				return false
			end
		elseif event  == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile and move.from and move.from:objectName() == player:objectName() and move.card_ids:length() > 0 then
				for _, id in sgs.qlist(move.card_ids) do
					for _, p in sgs.qlist(room:getAlivePlayers()) do

						if player:getMark(self:objectName()..id..p:objectName()) > 0 then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							p:drawCards(1)
							for _, pp in sgs.qlist(room:getAlivePlayers()) do
								room:removePlayerMark(pp,self:objectName()..use.card:getId()..p:objectName())
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and RIGHT(self,player) then
				player:drawCards(2)
				room:askForUseCard(player, "@@yizhu1!", "@yizhu_invoke")
			end
		end
	end
}


gonghuan = sgs.CreateTriggerSkill{
	name = "gonghuan" ,
	events = {sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if player:getMark("@mobile_yin") > 0 then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getHp() > player:getHp() and p:getMark("gonghuan-Clear") == 0 then
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), p:objectName())
					room:addPlayerMark(p , "gonghuan-Clear")			
					if damage.card and damage.card:isKindOf("Slash") then
						player:removeQinggangTag(damage.card)
					end
					damage.to = p
					damage.transfer = true
					room:damage(damage)
					return true
				end
			end
		end
		return false
	end
}

luanchouCard = sgs.CreateSkillCard{
	name = "luanchou" ,
	filter = function(self, targets, to_select)
		if #targets >= 2 then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("@mobile_yin") > 0 then
				room:removePlayerMark(p,"@mobile_yin")
				room:handleAcquireDetachSkills(p, "-gonghuan", true)
			end
		end

		for _, p in ipairs(targets) do
			room:addPlayerMark(p,"@mobile_yin")
			room:handleAcquireDetachSkills(p, "gonghuan", true)
		end
	end
}
luanchou = sgs.CreateZeroCardViewAsSkill{
	name = "luanchou" ,
	view_as = function(self, card)
		return luanchouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luanchou")
	end
}

qiaogong:addSkill(yizhu)
qiaogong:addSkill(luanchou)
qiaogong:addRelateSkill("gonghuan")

if not sgs.Sanguosha:getSkill("gonghuan") then skills:append(gonghuan) end

qiaogong:addSkill(luanchou)

sgs.LoadTranslationTable{
["qiaogong"] = "喬公",
["&qiaogong"] = "喬公",
["yizhu"] = "遺珠",
[":yizhu"] = "結束階段，你須摸2張牌，然後選擇2張牌作為「遺珠」，隨機洗入牌堆頂前2X張牌中（X場上角色數)，並記錄「遺珠」"..
"牌的牌名；其他角色使用「遺珠」牌指定唯一目標時，你可以取消之，然後你可以重新使用此牌；或者在「遺珠」牌進入棄牌堆時，你摸1張牌",

["@yizhu_useCard"] = "你可以重新使用此牌",
["@yizhu_invoke"] = "你選擇2張牌作為「遺珠」",
["~yizhu"] = "選擇卡牌→點擊確定",
["$yizhu"] = "由於 %to 的技能 <font color=\"yellow\"><b>遺珠</b></font> 被觸發，%from 使用的 %card 無效",

["luanchou"] = "鸞儔",
[":luanchou"] = "出牌階段限一次，你可以移除場上所有「姻」標記並選擇2名角色，令其獲得「姻」標記。擁有「姻」標記的角色，擁有技能〖共患〗。",

["gonghuan"] = "共患",
[":gonghuan"] = "鎖定技，每回合限一次，當另一名擁有「姻」標記的角色受到傷害時，若其體力值小於你，你將此傷害轉移給自己。 ",
}



--[[
劉璋
]]--
liuzhang = sgs.General(extension,"liuzhang$","qun3","3",true,true)

jutu = sgs.CreateTriggerSkill{
	name = "jutu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			if player:getPile("mobile_sheng"):length() > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist( player:getPile("mobile_sheng") ) do
					dummy:addSubcard(id)
				end
				room:obtainCard(player,dummy,false)
			end

			local x = 0

			for _, pp in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark("yaohu"..pp:getKingdom().."_lun") > 0  then
					x = x + 1
				end
			end
			player:drawCards(x+1)

			local cards = room:askForExchange(player, self:objectName(), x, x, true, "@jutu:"..tostring(x))
			room:broadcastSkillInvoke(self:objectName())
			player:addToPile("mobile_sheng", cards:getSubcards(), false)
		end
	end,

}

yaohu = sgs.CreateTriggerSkill{
	name = "yaohu",
	events = {sgs.EventPhaseStart,sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if player:hasSkill("yaohu") and player:getMark("yaohu_lun") == 0 then
					room:broadcastSkillInvoke(self:objectName())
					local kingdoms = {}
					for _, pp in sgs.qlist(room:getAlivePlayers()) do
						local flag = true
						for _, k in ipairs(kingdoms) do
							if pp:getKingdom() == k then
								flag = false
								break
							end
						end
						if flag then table.insert(kingdoms, pp:getKingdom()) end
					end

					local choice2 = room:askForChoice(player, "yaohu", table.concat(kingdoms, "+"))
					room:addPlayerMark(player,"yaohu"..choice2.."_lun")
					room:addPlayerMark(player,"yaohu_lun")
				end
			elseif player:getPhase() == sgs.Player_Play then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getPile("mobile_sheng"):length() > 0 and p:getMark("yaohu"..player:getKingdom().."_lun") > 0 then
					 	room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())

						local _data = sgs.QVariant()
						_data:setValue(p)
						if room:askForSkillInvoke(player, "yaohu_get", _data) then
							local card_ids = p:getPile("mobile_sheng")
							room:fillAG(card_ids)
							local to_get = sgs.IntList()
							if not card_ids:isEmpty() then
								local card_id = room:askForAG(player, card_ids, false, "shelie")
								card_ids:removeOne(card_id)
								to_get:append(card_id)
								room:takeAG(player, card_id, false)
							end
							room:clearAG()
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							if not to_get:isEmpty() then
								dummy:addSubcards(getCardList(to_get))
								player:obtainCard(dummy)

								local luanwu_targets = sgs.SPlayerList()
								for _,pp in sgs.qlist(room:getOtherPlayers(player)) do
									if pp:inMyAttackRange(player) and player:canSlash(pp, nil, false) then
										luanwu_targets:append(pp)
									end
								end
								if luanwu_targets:length() > 0 then
									local target = room:askForPlayerChosen(p,  luanwu_targets ,self:objectName(),"@yaohu",false,true)
									if target then
										if room:askForUseSlashTo(player,target  , "#yaohu:"..target:objectName(),false) then

										else
											room:addPlayerMark(player , "yaohu_from_Play")
											room:addPlayerMark(p , "yaohu_to_Play")
										end
									end
								else
									room:addPlayerMark(player , "yaohu_from_Play")
									room:addPlayerMark(p , "yaohu_to_Play")
								end
							end
						end
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and RIGHT(self,player) and use.from:getMark("yaohu_from_Play") > 0
			 and player:getMark("yaohu_to_Play")  > 0 and canCauseDamage(use.card) then
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local to_exchange = room:askForExchange(use.from, self:objectName(), 2, 2, false, "@yaohuask:"..p:objectName(), true)
					if to_exchange then
						room:broadcastSkillInvoke(self:objectName(),2)
						room:moveCardTo(to_exchange, player, sgs.Player_PlaceHand, false)
					else
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
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

huaibi = sgs.CreateTriggerSkill{
	name = "huaibi$",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Discard then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
		end
	end
}

huaibimc = sgs.CreateMaxCardsSkill{
	name = "#huaibimc$",
	extra_func = function(self, target)
		if target:hasLordSkill("huaibi") then
			local n = 0
			for _, p in sgs.qlist(target:getAliveSiblings()) do
				if p:getMark("yaohu"..target:getKingdom().."_lun") > 0  then
					n = n + 1
				end
			end
			return n
		end
	end
}

liuzhang:addSkill(jutu)
liuzhang:addSkill(yaohu)
liuzhang:addSkill(huaibi)
liuzhang:addSkill(huaibimc)

--[[
sgs.LoadTranslationTable{
["liuzhang"] = "劉璋",
["xiusheng"] = "休生",
[":xiusheng"] = "鎖定技，準備階段，你須棄置所有你武將牌上的「生」，然後摸X張牌，將等量牌置於你的武將牌上，稱之為「生」"
.."(X為你「引狼」選擇勢力的角色數量）。",
["yinlang"] = "引狼",
[":yinlang"] = "每輪限一次，你的回合開始時，你須選擇場上一個勢力。被你選擇勢力的角色出牌階段開始時，其可以獲得你的一張「生」，"
.."若如此做，直至回合結束，其使用牌選擇角色為目標時，只能選擇你為目標；否則，你將一張「生」加入手牌。",
["huaibi"] = "懷璧",
[":huaibi"] = "主公技，鎖定技，你的手牌上限+X（X為你「引狼」選擇勢力的角色數量)。 ",
["mobile_sheng"] = "生",
["@xiusheng"] = "將 %src 張牌置於你的武將牌上，稱之為「生」",
["yinlang_get"] = "引狼",
}
]]--

sgs.LoadTranslationTable{
["liuzhang"] = "劉璋",
["jutu"] = "據土",
[":jutu"] = "鎖定技，準備階段，你獲得所有你武將牌上的「生」，然後摸X+1張牌，然後將X張牌置於你的武將牌上，稱為「生」（X為你因〖邀虎〗選擇勢力的角色數量)。",
["yaohu"] = "邀虎",
[":yaohu"] = "每輪限一次，你的回合開始時，你須選擇場上一個勢力。該勢力角色的出牌階段開始時，其可以獲得你的一張「生」，然後其須選擇一項：①對你指定的一名其攻擊範圍內的其他角色使用一張【殺】；②直到本階段結束時，其使用傷害類牌指定你為目標時，須交給你兩張牌，否則取消之。",
["huaibi"] = "懷璧",
[":huaibi"] = "主公技，鎖定技，你的手牌上限+X（X為你因〖邀虎〗選擇勢力的角色數量)。",
["@jutu"] = "將 %src 張牌置於你的武將牌上，稱之為「生」",
["yaohu_get"] = "邀虎",
["@yaohuask"] = "你需交給 %src 兩張牌，否則此牌無效",
["@yaohu"] = "你可以發動【毒治】，令一名其他角色失去1點體力，然後該角色可以對你使用一張【殺】",
["#yaohu"] = "你可以對 %src 使用一張【殺】",
["mobile_sheng"] = "生",
}

--[[
羊祜，群，3/3
〖明伐〗結束階段，你可以展示一張牌。若如此做，則下回合的出牌階段開始時，你可以以此牌與一名其他角色進行拼點：若你贏，你獲得其一張牌，並隨機從牌堆獲得一張點數比你亮出的拼點牌牌面點數小1點的牌；若你沒贏，本回合你使用牌不能選擇其他角色為目標；當你拼點的牌亮出後，你令此牌的點數+2。

〖戎備〗限定技，出牌階段，你可選擇一名有空置的裝備區的角色，令其每個空置的裝備區均隨機獲得並使用一張裝備。 

]]--

mobile_yanghu = sgs.General(extension,"mobile_yanghu","qun3","3",true)

domingfa = function(player, card, number)
	local room = player:getRoom()
	local n = math.min(13,number + 2)
	if n > number then
		local msg = sgs.LogMessage()
		msg.type = "#Mingfa"
		msg.from = player
		msg.to:append(player)
		msg.arg = "mingfa"
		msg.arg2 = tostring(n)
		room:sendLog(msg)
		return n
	end
end

mingfa = sgs.CreateTriggerSkill{
	name = "mingfa",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.PindianVerifying,sgs.CardsMoveOneTime},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:hasSkill("mingfa") then
			if player:getPhase() == sgs.Player_Finish then
				if not player:isKongcheng() then
					local card = room:askForCard(player, "..", "@mingfa", data, sgs.Card_MethodNone)
					if card then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						local log = sgs.LogMessage()
						log.type = "#InvokeSkill"
						log.from = player
						log.arg = self:objectName()
						room:sendLog(log)
						room:addPlayerMark(player, "mingfa_card_id_"..card:getEffectiveId())
						room:setPlayerMark(player, "@mingfa_card", 1)
					end
				end
			end
			if player:getPhase() == sgs.Player_Draw then
				for _, c in sgs.qlist(player:getCards("he")) do
					if player:getMark("mingfa_card_id_"..c:getId()) > 0 then
						
						local targets = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							if not p:isKongcheng() then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							local to = room:askForPlayerChosen(player, targets, self:objectName(), "mingfa-invoke", true, true)
							if to then
								room:broadcastSkillInvoke(self:objectName())
								room:addPlayerMark(player, self:objectName().."engine")
								if player:getMark(self:objectName().."engine") > 0 then
									local success = player:pindian(to, self:objectName(), sgs.Sanguosha:getCard(c:getId()) )
									if success then
										if not to:isNude() then
											local id = room:askForCardChosen(player, to, "he", self:objectName())
											room:obtainCard(player, id, false)
										end
										if sgs.Sanguosha:getCard(c:getId()):getNumber() > 1 then
											local point_six_card = sgs.IntList()
											for _,id in sgs.qlist(room:getDrawPile()) do
												if sgs.Sanguosha:getCard(id):getNumber() == sgs.Sanguosha:getCard(c:getId()):getNumber() - 1 then
													point_six_card:append(id)
												end
											end
											if not point_six_card:isEmpty() then
												room:sendCompulsoryTriggerLog(player, self:objectName())
												room:obtainCard(player, point_six_card:at(math.random(0,point_six_card:length()-1)), false)
											end
										end

									else

										local msg = sgs.LogMessage()
										msg.type = "#ComZishou"
										msg.from = player
										msg.arg = "mingfa"
										room:sendLog(msg)
										room:setPlayerMark(player,"beizhan_ban-Clear",1)

									end
									room:removePlayerMark(player, self:objectName())
								end
							end
						end
					end
				end
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "mingfa_card_id_") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
						room:setPlayerMark(player, "@mingfa_card", 0)
					end
				end
			end
		elseif event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			if pindian.reason == self:objectName() then
				for _,wanglang in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do  --同将模式
					if wanglang:objectName() == pindian.from:objectName() then
						pindian.from_number = domingfa(wanglang, pindian.from_card, pindian.from_number)
					end
					if wanglang:objectName() == pindian.to:objectName() then
						pindian.to_number = domingfa(wanglang, pindian.to_card, pindian.to_number)
					end
				end
				data:setValue(pindian)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
				local can_mingfa = false
				for _, c in sgs.qlist(player:getCards("he")) do
					if player:getMark("mingfa_card_id_"..c:getId()) > 0 then
						can_mingfa = true
						break
					end
				end
				if can_mingfa then
					room:setPlayerMark(player, "@mingfa_card", 1)
				else
					room:setPlayerMark(player, "@mingfa_card", 0)
				end
			end
		end
		return false
	end
}

rongbeiCard = sgs.CreateSkillCard{
	name = "rongbei",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@rongbei")
		room:doSuperLightbox("mobile_yanghu","rongbei")
		local equip_type_table = {"Weapon", "Armor", "DefensiveHorse", "OffensiveHorse", "Treasure"}
			for _, card in sgs.qlist(targets[1]:getCards("e")) do
				if card:isKindOf("Weapon") then
					table.removeOne(equip_type_table, "Weapon")
				elseif card:isKindOf("Armor") then
					table.removeOne(equip_type_table, "Armor")
				elseif card:isKindOf("DefensiveHorse") then
					table.removeOne(equip_type_table, "DefensiveHorse")
				elseif card:isKindOf("OffensiveHorse") then
					table.removeOne(equip_type_table, "OffensiveHorse")
				elseif card:isKindOf("Treasure") then
					table.removeOne(equip_type_table, "Treasure")
				end
			end

			if targets[1]:getMark("@AbolishWeapon") > 0 then
				table.removeOne(equip_type_table, "Weapon")
			end
			if targets[1]:getMark("@AbolishArmor") > 0 then
				table.removeOne(equip_type_table, "Armor")
			end
			if targets[1]:getMark("@AbolishDefensiveHorse") > 0 then
				table.removeOne(equip_type_table, "DefensiveHorse")
			end
			if targets[1]:getMark("@AbolishOffensiveHorse") > 0 then
				table.removeOne(equip_type_table, "OffensiveHorse")
			end
			if targets[1]:getMark("@AbolishTreasure") > 0 then
				table.removeOne(equip_type_table, "Treasure")
			end

		while #equip_type_table > 0 do
			local equip_type_index = math.random(1, #equip_type_table)
			local equips = sgs.CardList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf(equip_type_table[equip_type_index]) then
					local equip_index = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()
				 	if targets[1]:getEquip(equip_index) == nil  then
						equips:append(sgs.Sanguosha:getCard(id))
					end
				end
			end
			if not equips:isEmpty() then
				local card = equips:at(math.random(0, equips:length() - 1))
				room:useCard(sgs.CardUseStruct(card, targets[1], targets[1]))
			end
			table.removeOne(equip_type_table, equip_type_table[equip_type_index])
		end
	end
}
rongbeiVS = sgs.CreateZeroCardViewAsSkill{
	name = "rongbei",
	view_as = function()
		return rongbeiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@rongbei") > 0
	end
}
rongbei = sgs.CreateTriggerSkill{
	name = "rongbei",
	frequency = sgs.Skill_Limited,
	view_as_skill = rongbeiVS,
	limit_mark = "@rongbei",
	on_trigger = function()
	end
}


mobile_yanghu:addSkill(mingfa)
mobile_yanghu:addSkill(rongbei)

sgs.LoadTranslationTable{
	["mobile_yanghu"] = "手殺羊祜",
	["&mobile_yanghu"] = "羊祜",
	["#mobile_yanghu"] = "",
	["mingfa"] = "明伐",
	[":mingfa"] = "結束階段，你可以展示一張牌。若如此做，則下回合的出牌階段開始時，你可以以此牌與一名其他角色進行拼點"..
	"：若你贏，你獲得其一張牌，並隨機從牌堆獲得一張點數比你亮出的拼點牌牌面點數小1點的牌；若你沒贏，本回合你使用牌不能選擇"..
	"其他角色為目標；當你拼點的牌亮出後，你令此牌的點數+2。",
	["#Mingfa"] = "%from 的技能【%arg】被觸發，拼點牌視為 %arg2 點",
	["@mingfa"] = "你可以展示一張牌並發動明伐",
	["rongbei"] = "戎備",
	[":rongbei"] = "限定技，出牌階段，你可選擇一名有空置的裝備區的角色，令其每個空置的裝備區均隨機獲得並使用一張裝備。",
}

--[[
王凌（重鑄），魏，3/3
〖星啓〗當你使用一張除延時錦囊以外的牌時，若沒有同牌名的「備」，則記錄此牌的牌名為「備」。你的結束階段時，你可以移除一個「
備」，在牌堆中獲得一張同牌名的牌。

〖自縛〗鎖定技，出牌階段結束時，若你本階段未使用牌，你本回合手牌上限-1且移除你所有的「備」。

〖秘備〗使命技。

成功：當你使用一張牌結算結束後，若你擁有每種牌類型的「備」各兩個，你從牌堆獲得每種類型的牌各一張，然後你獲得技能「謀立」。

失敗：你成功達成使命前，若你於本回合的準備階段和棄牌階段結束時均沒有「備」，你扣減一點體力上限。

☆〖謀立〗出牌階段限一次，你可以選擇1名其他角色，其移除一個你的「備」，然後從牌堆中獲得一張同牌名的牌。 
]]--

mobile_wangling = sgs.General(extension,"mobile_wangling","wei2","4",true)

xingqi = sgs.CreateTriggerSkill{
	name = "xingqi",
	events = {sgs.CardUsed, sgs.CardResponded,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and not card:isKindOf("SkillCard") and not card:isKindOf("DelayedTrick") and player:getMark("mobile_bei"..card:objectName()) == 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player,"mobile_bei"..card:objectName() )

				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "mobile_bei" ) and player:getMark(mark) > 0 then
						local pattern = string.sub(mark, 11, string.len(mark) )
						
						local msg = sgs.LogMessage()
						msg.type = "$mibei"
						msg.from = player
						msg.to:append(player)
						msg.arg = pattern
						room:sendLog(msg)
					end
				end


			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local choices = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "mobile_bei" ) and player:getMark(mark) > 0 then
						table.insert(choices, string.sub(mark, 11, string.len(mark) ) )
					end
				end
				table.insert(choices, "cancel" )

				local choice = room:askForChoice(player, "xingqi", table.concat(choices, "+"), data)
				if choice ~= "cancel" then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local point_six_card = sgs.IntList()
					for _,id in sgs.qlist(room:getDrawPile()) do
						if choice == sgs.Sanguosha:getCard(id):objectName() then
							point_six_card:append(id)
						end
					end
					if not point_six_card:isEmpty() then
						room:obtainCard(player, point_six_card:at(math.random(0,point_six_card:length()-1)), false)
					end

					room:setPlayerMark(player , "mobile_bei"..card:objectName() , 0)
				end
			end
		end
	end
}

mobile_zifu = sgs.CreateTriggerSkill{
	name = "mobile_zifu",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("used-Clear") == 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "mobile_bei" ) and player:getMark(mark) > 0 then
						room:setPlayerMark(player,mark,0)
					end
				end
				room:addPlayerMark(player,"mobile_zifu-Clear")
			end
		end
	end
}

mobile_zifuMC = sgs.CreateMaxCardsSkill{
	name = "#mobile_zifu", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		if target:getMark("mobile_zifu-Clear") > 0 then
			return  - 1
		end
	end
}

mibei = sgs.CreateTriggerSkill{
	name = "mibei",
	events = {sgs.CardFinished,sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished and player:getMark("@mibei") == 0 then
			local e_num = 0
			local b_num = 0
			local t_num = 0
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "mobile_bei" ) and player:getMark(mark) > 0 then
					local name = string.sub(mark, 11, string.len(mark) )
					local bei_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
					if bei_card:isKindOf("BasicCard") then
						b_num = b_num + 1
					elseif bei_card:isKindOf("EquipCard") then
						e_num = e_num + 1
					elseif bei_card:isKindOf("TrickCard") then
						t_num = t_num + 1
					end
				end
			end
			if e_num > 1 and b_num > 1 and t_num > 1 then
				room:doSuperLightbox("mobile_wangling","mibei_success")
				room:acquireSkill(player,"mobile_mouli")
				room:addPlayerMark(player,"@mibei")
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				getpatterncard_for_each_pattern(player, {"BasicCard","EquipCard","TrickCard"}, true,false)
			end

		elseif event == sgs.EventPhaseStart and player:getMark("@mibei") == 0 then
			if player:getPhase() == sgs.Player_RoundStart then
				local has_mark = false
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "mobile_bei" ) and player:getMark(mark) > 0 then
						has_mark = true
					end
				end

				if (not has_mark) then
					room:addPlayerMark(player,"mibei_failed-Clear")

				end
			elseif player:getPhase() == sgs.Player_Finish  and player:getMark("mibei_failed-Clear") > 0 then
				local has_mark = false
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "mobile_bei" ) and player:getMark(mark) > 0 then
						has_mark = true
					end
				end

				if (not has_mark) then
					room:doSuperLightbox("mobile_wangling","mibei_failed")
					room:addPlayerMark(player,"@mibei")
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:loseMaxHp(player,1)
				end
			end

		end
	end
}

mobile_mouliCard = sgs.CreateSkillCard{
	name = "mobile_mouli",
	filter = function(self, selected, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and #selected == 0
	end,
	on_use = function(self, room, source, targets)
		local choices = {}
		for _, mark in sgs.list(source:getMarkNames()) do
			if string.find(mark, "mobile_bei" ) and source:getMark(mark) > 0 then
				table.insert(choices, string.sub(mark, 11, string.len(mark) ) )
			end
		end
		table.insert(choices, "cancel" )

		local choice = room:askForChoice(targets[1], "xingqi", table.concat(choices, "+"), data)
		if choice ~= "cancel" then
			local point_six_card = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if choice == sgs.Sanguosha:getCard(id):objectName() then
					point_six_card:append(id)
				end
			end
			if not point_six_card:isEmpty() then
				room:obtainCard(targets[1], point_six_card:at(math.random(0,point_six_card:length()-1)), false)
				room:setPlayerMark(source, "mobile_bei"..card:objectName() , 0)
			end
		end
	end
}
mobile_mouli = sgs.CreateZeroCardViewAsSkill{
	name = "mobile_mouli",
	view_as = function()
		return mobile_mouliCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_mouli")
	end
}

mobile_wangling:addSkill(xingqi)
mobile_wangling:addSkill(mobile_zifu)
mobile_wangling:addSkill(mobile_zifuMC)
mobile_wangling:addSkill(mibei)
mobile_wangling:addRelateSkill("mobile_mouli")

if not sgs.Sanguosha:getSkill("mobile_mouli") then skills:append(mobile_mouli) end

sgs.LoadTranslationTable{
["mobile_wangling"] = "手殺王凌",
["&mobile_wangling"] = "王凌",
["#mobile_wangling"] = "風節格尚",
["xingqi"] = "星啓",
[":xingqi"] = "當你使用一張除延時錦囊以外的牌時，若沒有同牌名的「備」，則記錄此牌的牌名為「備」。你的結束階段時，"
.."你可以移除一個「備」，在牌堆中獲得一張同牌名的牌。",
["mobile_zifu"] = "自縛",
[":mobile_zifu"] = "鎖定技，出牌階段結束時，若你本階段未使用牌，你本回合手牌上限-1且移除你所有的「備」。",
["mibei"] = "秘備",
[":mibei"] = "使命技。成功：當你使用一張牌結算結束後，若你擁有每種牌類型的「備」各兩個，你從牌堆獲得每種類型的牌各一張，"
.."然後你獲得技能「謀立」。失敗：你成功達成使命前，若你於本回合的準備階段和棄牌階段結束時均沒有「備」，你扣減一點體力上限。",
["mobile_mouli"] = "謀立",
[":mobile_mouli"] = "出牌階段限一次，你可以選擇1名其他角色，其移除一個你的「備」，然後從牌堆中獲得一張同牌名的牌。 ",
["mibei_success"] = "秘備成功",
["mibei_failed"] = "秘備失敗",
	["$mibei"] = "%from 擁有的「備」標記包含 %arg ",
}

--[[
糜夫人（重鑄），蜀，3/3
〖閨秀〗鎖定技，結束階段，若你的體力值為奇數，則摸一張牌；否則回復1點體力值。

〖清玉〗使命技。當你受到傷害時，你棄置兩張牌並防止之。

成功：準備階段,若你體力已滿且沒有手牌，你獲得「懸存※」。

失敗：你成功達成使命前，進入瀕死階段，你減少1點體力上限。

※懸存：其他角色的回合結束後，若你的體力值大於手牌數，則你可以令其摸X張牌（X為你的體力值與手牌數的差值，且最大為2）。

]]--
--糜夫人
mobile_mifuren = sgs.General(extension,"mobile_mifuren","shu2","3",false)

mobile_guixiu = sgs.CreateTriggerSkill{
	name = "mobile_guixiu",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				if player:getHp() % 2 == 0 and player:isWounded() then
					local theRecover = sgs.RecoverStruct()
					theRecover.recover = 1
					theRecover.who = player
					room:recover(player, theRecover)
				elseif player:getHp() % 2 == 1 then
					player:drawCards(1)
				end
			end
		end
	end
}

qingyu = sgs.CreateTriggerSkill{
	name = "qingyu",
	events = {sgs.DamageInflicted,sgs.EnterDying,sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)

		if event == sgs.DamageInflicted and player:getMark("@qingyu") == 0 then
			local damage = data:toDamage()
			if player:getCards("he"):length() >= 2 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:askForDiscard(player, self:objectName(), 2, 2, false, true,"@qingyu-invoke" )

				local msg = sgs.LogMessage()
				msg.type = "#qingyuProtect"
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
				return true
			end
			return false
		elseif event == sgs.EventPhaseStart and player:getMark("@qingyu") == 0 and player:getPhase() == sgs.Player_RoundStart then
			if player:getMaxHp() == player:getHp() and player:isKongcheng() then
				room:doSuperLightbox("mobile_mifuren","qingyu_success")
				room:acquireSkill(player,"xuancun")
				room:addPlayerMark(player,"@qingyu")
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
			end

		elseif event == sgs.EnterDying and player:getMark("@qingyu") == 0 then
			room:doSuperLightbox("mobile_mifuren","qingyu_failed")
			room:addPlayerMark(player,"@qingyu")
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			room:loseMaxHp(player,1)
		end
	end
}

xuancun = sgs.CreateTriggerSkill{
	name = "xuancun" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("xuancun") and p:getHp() > p:getHandcardNum() then
					local _data = sgs.QVariant()
					_data:setValue(player)
					if room:askForSkillInvoke(p, "xuancun", _data) then
						player:drawCards( math.min(2, p:getHp() - p:getHandcardNum() ) )
					end
				end
			end
		end
		return false
	end
}

mobile_mifuren:addSkill(mobile_guixiu)
mobile_mifuren:addSkill(qingyu)
mobile_mifuren:addRelateSkill("xuancun")

if not sgs.Sanguosha:getSkill("xuancun") then skills:append(xuancun) end

sgs.LoadTranslationTable{
["mobile_mifuren"] = "手殺糜夫人",
["&mobile_mifuren"] = "糜夫人",
["mobile_guixiu"] = "閨秀",
[":mobile_guixiu"] = "鎖定技，結束階段，若妳的體力值為奇數，則摸一張牌；否則回復1點體力值。",
["qingyu"] = "清玉",
[":qingyu"] = "使命技。當妳受到傷害時，妳棄置兩張牌並防止之。成功：準備階段,若妳體力已滿且沒有手牌，妳獲得「懸存」。失敗：妳成功達成使命前，進入瀕死階段，妳減少1點體力上限。",
["@qingyu-invoke"] = "技能「清玉」效果，妳需棄置兩張牌防止此傷害",
["xuancun"] = "懸存",
[":xuancun"] = "其他角色的回合結束後，若妳的體力值大於手牌數，則妳可以令其摸X張牌（X為妳的體力值與手牌數的差值，且最大為2）。 ",
["qingyu_success"] = "清玉成功",
["qingyu_failed"] = "清玉失敗",
["#qingyuProtect"] = "%from 發動「<font color=\"yellow\"><b>清玉</b></font>」，防止了 %arg 點傷害[%arg2]",
}



--[[
孔融（重鑄），群，3/3
〖名仕〗鎖定技，當你受到傷害後，若你有「謙」標記，傷害來源須棄置其區域內的一張牌；若棄置的牌為：黑色，你獲得此牌；紅色，
你回復1點體力。

〖禮讓〗其他角色的摸牌階段開始時，若你沒有「謙」標記，你可以令其多摸兩張牌。若如此做，你獲得「謙」標記，然後其棄牌
階段結束時，你可以獲得其棄置的至多兩張牌。若你有「謙」標記，你跳過摸牌階段然後移除「謙」標記。

]]--

mobile_kongrong = sgs.General(extension,"mobile_kongrong","qun3","3",true)

mobile_mingshi = sgs.CreateTriggerSkill{
	name = "mobile_mingshi",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if player:getMark("@mobile_qian") > 0 and not damage.from:isNude() then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			local mobile_mingshi_throw_cards = room:askForExchange(damage.from, self:objectName(), 1, 1, true, "mingshiDiscard")
			room:throwCard(mobile_mingshi_throw_cards, damage.from, nil)
			local cd = card:getSubcards():first()
			if cd:isBlack() then
				player:obtainCard(cd)
			else
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
		end
	end,
}

mobile_lirang = sgs.CreateTriggerSkill{
	name = "mobile_lirang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime,sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime and RIGHT(self, player)  then
			local current = room:getCurrent()
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == current:objectName() and current:getPhase() == sgs.Player_Discard then
				local ids = sgs.IntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						ids:append(card_id)
					end
				end
				if player:hasSkill("mobile_lirang") and current:getMark("mobile_lirang"..player:objectName()) > 0 then
					room:removePlayerMark(current,"mobile_lirang"..player:objectName() )
					if not ids:isEmpty() then
						if room:askForSkillInvoke(player, self:objectName(), data) then

							local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							room:fillAG(ids)
							for i = 1, 2 do
								local id = room:askForAG(player, ids, i ~= 1, self:objectName())
								if id == -1 then break end
								ids:removeOne(id)
								dummy:addSubcard(id)
								room:takeAG(player, id, false)
								if ids:isEmpty() then break end
							end
							room:clearAG()
							
							room:obtainCard( player,dummy, true)
							--[[
							if ids:length() > 0 then
								local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								for _,cid in sgs.qlist(ids) do
									dummy:addSubcard(cid)
								end
								room:obtainCard( player,dummy, true)
							end
							]]--
						end
					end
				end
			end
		elseif event == sgs.DrawNCards then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("mobile_lirang") and p:getMark("@mobile_qian") == 0 then
					local _data = sgs.QVariant()
					_data:setValue(player)
					if room:askForSkillInvoke(p, self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							room:addPlayerMark(p,"@mobile_qian")
							room:addPlayerMark(p, "skip_draw")
							room:addPlayerMark(player,"mobile_lirang"..p:objectName())
							data:setValue(data:toInt() + 2)
							room:removePlayerMark(p, self:objectName().."engine")
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
}
mobile_kongrong:addSkill(mobile_mingshi)
mobile_kongrong:addSkill(mobile_lirang)

sgs.LoadTranslationTable{
	["mobile_kongrong"] = "手殺孔融",
	["&mobile_kongrong"] = "孔融",
	["#mobile_kongrong"] = "凜然重義",
	["mobile_mingshi"] = "名士",
	--[":mobile_mingshi"] = "鎖定技，當你受到1點傷害後，傷害來源棄置一張牌。",
	[":mobile_mingshi"] = "鎖定技，當你受到傷害後，若你有「謙」標記，傷害來源須棄置其區域內的一張牌；若棄置的牌為：黑色，你獲得此牌；紅色，你回復1點體力。",
	["mobile_lirang"] = "禮讓",
	--[":mobile_lirang"] = "出牌階段限一次，你可以棄置全部手牌，然後可將其中至多x張牌（x為你的體力值）交給一名其他角色。若如此做，你摸一張牌。",
	[":mobile_lirang"] = "其他角色的摸牌階段開始時，若你沒有「謙」標記，你可以令其多摸兩張牌。若如此做，你獲得「謙」標記，然後其棄牌階段結束時，你可以獲得其棄置的至多兩張牌。若你有「謙」標記，你跳過摸牌階段然後移除「謙」標記。",
	["@mobile_qian"] = "謙",
}

--文鴦

mobile_wenyang = sgs.General(extension,"mobile_wenyang","wei2","4",true)

--卻敵
mobile_quedi = sgs.CreateTriggerSkill{
	name = "mobile_quedi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetSpecified,sgs.DamageCaused},  
	on_trigger = function(self, event, player, data, room) 
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and player:getPhase() == sgs.Player_Play and
			  player:getMark("mobile_quedi-Clear") < (player:getMark("mobile_quedi_extra_times-Clear") + 1) and use.to:length() == 1 then
			  	for _, p in sgs.qlist(use.to) do
			  		local _data = sgs.QVariant()
					_data:setValue(p)
					if room:askForSkillInvoke(player, self:objectName(), _data) then
						local choices = {"mobile_quedi1","mobile_quedi2","mobile_quedi3","cancel"}
						local choice = room:askForChoice(player , "mobile_quedi", table.concat(choices, "+"), _data)
						if choice ~= "cancel" then 
							room:broadcastSkillInvoke(self:objectName())
							room:addPlayerMark(player,"mobile_quedi-Clear")
							if choice == "mobile_quedi1" or choice == "mobile_quedi3" then
								local id = room:askForCardChosen(player, p, "he", self:objectName())
								room:obtainCard(player, sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
							end
							if choice == "mobile_quedi2" or choice == "mobile_quedi3" then
								if room:askForCard(player, "BasicCard|.", "@mobile_quedi", data, sgs.CardDiscarded) then
									room:setCardFlag(use.card, "mobile_quedi_card")
									p:setFlags("mobile_quedi_plus")
								end
							end
							if choice == "mobile_quedi3" then
								room:loseMaxHp(player)
							end
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then		
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card:hasFlag("mobile_quedi_card") and damage.to:hasFlag("mobile_quedi_plus") then
				room:setCardFlag(damage.card, "-mobile_quedi_card")
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#MobileQuedi"
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

--仇決
mobile_choujue = sgs.CreateTriggerSkill{
	name = "mobile_choujue",
	events = {sgs.Death,sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Death then
			local death = data:toDeath()
			if player:isAlive() then
				if death.damage then
					if death.damage.from and death.damage.from:objectName() == player:objectName() then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
						local msg = sgs.LogMessage()
						msg.type = "#GainMaxHp"
						msg.from = player
						msg.arg = 1
						room:sendLog(msg)
						player:drawCards(2)
						room:addPlayerMark(player,"mobile_quedi_extra_times-Clear")
					end
				end
			end
		end
	end,
}

--椎鋒
mobile_zhuifengvs = sgs.CreateViewAsSkill{
	name = "mobile_zhuifeng",
	n = 0,
	view_as = function(self, cards)
		local analeptic = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		return analeptic
	end,
	enabled_at_play = function(self, player)
		return player:getHp() > 0
	end,
}
mobile_zhuifeng = sgs.CreateTriggerSkill{
	name = "mobile_zhuifeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreCardUsed},
	view_as_skill = mobile_zhuifengvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:getSkillName() == "mobile_zhuifeng" then
				room:addPlayerMark(player,"mobile_zhuifeng-Clear")
				room:loseHp(player , player:getMark("mobile_zhuifeng-Clear"))
			end
		end
	end
}

--衝堅
mobile_chongjian_select = sgs.CreateSkillCard{
	name = "mobile_chongjian",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
--		for _, name in ipairs(patterns) do
--			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
--			poi:setSkillName("mobile_chongjian")
--			poi:addSubcard(self:getSubcards():first())
--			if poi:isAvailable(source) and source:getMark("mobile_chongjian"..name) == 0 and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
--				table.insert(choices, name)
--			end
--		end
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("AG_BANCard"..card:objectName()) == 0 and (card:isKindOf("Analeptic") or card:isKindOf("Slash")) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "mobile_chongjian", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("mobile_chongjian")
					poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					local pos = 0
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "mobile_chongjianpos", pos)
					room:setPlayerProperty(source, "mobile_chongjian", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@mobile_chongjian", "@mobile_chongjian:"..pattern)--%src
				end
			end
		end
	end
}
mobile_chongjianCard = sgs.CreateSkillCard{
	name = "mobile_chongjianCard",
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
			card:setSkillName("mobile_chongjian")
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
		card:setSkillName("mobile_chongjian")
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
		card:setSkillName("mobile_chongjian")
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
			local name = room:askForChoice(user, "mobile_chongjian", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("mobile_chongjian")
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
			local name = room:askForChoice(card_use.from, "mobile_chongjian", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("mobile_chongjian")
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
mobile_chongjianvs = sgs.CreateViewAsSkill{
	name = "mobile_chongjian",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@mobile_chongjian" then
			return false
		else
			return to_select:isKindOf("EquipCard")
		end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = mobile_chongjian_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = mobile_chongjianCard:clone()
			if pattern and pattern == "@@mobile_chongjian" then
				pattern = patterns[sgs.Self:getMark("mobile_chongjianpos")]
				acard:addSubcard(sgs.Self:property("mobile_chongjian"):toInt())
				if #cards ~= 0 then return end
			else
				if #cards ~= 1 then return end
				acard:addSubcard(cards[1]:getId())
			end
			if pattern == "analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
				pattern = "analeptic"
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) or pattern == "@@mobile_chongjian"
	end
}

mobile_chongjian = sgs.CreateTriggerSkill{
	name = "mobile_chongjian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	view_as_skill = mobile_chongjianvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "mobile_chongjian" then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)


				room:setPlayerFlag(damage.to, "Fake_Move")
				local x = damage.damage
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local card_ids = sgs.IntList()
				local original_places = sgs.IntList()
				for i = 0, x - 1 do
					if not player:canDiscard(damage.to, "e") then break end
					local to_throw = room:askForCardChosen(player, damage.to, "e", self:objectName(), false, sgs.Card_MethodDiscard)
					card_ids:append(to_throw)
					original_places:append(room:getCardPlace(card_ids:at(i)))
					room:throwCard(sgs.Sanguosha:getCard(to_throw), damage.to, player)
					dummy:addSubcard(card_ids:at(i))
					room:getThread():delay()
				end	

				if dummy:subcardsLength() > 0 then
					room:obtainCard(player, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
				end
				room:setPlayerFlag(damage.to, "-Fake_Move")
			end
		end
	end
}

mobile_chongjiantm = sgs.CreateTargetModSkill{
	name = "#mobile_chongjiantm" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if card:getSkillName() == "mobile_chongjian" then
			return 1000
		end
		return 0
	end
}

DoubleKingdomChoose = sgs.CreateTriggerSkill{
	name = "#DoubleKingdomChoose",	
	events = {sgs.GameStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.GameStart then
			--雙勢力部分
			if player:getGeneralName() == "mobile_wenyang" or player:getGeneral2Name() == "mobile_wenyang" then
				local choice = room:askForChoice(player, "choose_kingdom", "wei+wu")
				
				if choice == "wei" then
					room:setPlayerProperty(player,"kingdom",sgs.QVariant("we"))
					room:detachSkillFromPlayer(player, "mobile_chongjian")
				elseif choice == "wu" then
					room:setPlayerProperty(player,"kingdom",sgs.QVariant("wu"))
					room:detachSkillFromPlayer(player, "mobile_zhuifeng")
				end
			end
		end
	end,
}

mobile_wenyang:addSkill(mobile_quedi)
mobile_wenyang:addSkill(mobile_zhuifeng)
mobile_wenyang:addSkill(mobile_chongjian)
mobile_wenyang:addSkill(mobile_chongjiantm)
mobile_wenyang:addSkill(mobile_choujue)
mobile_wenyang:addSkill(DoubleKingdomChoose)

sgs.LoadTranslationTable{
["mobile_wenyang"] = "文鴦",
["mobile_quedi"] = "卻敵",
[":mobile_quedi"] = "每回合限一次。當你使用【殺】或【決鬥】指定唯一目標後，你可選擇："..
"①獲得目標角色的一張手牌。"..
"②棄置一張基本牌，並令此牌的傷害值基數+1。"..
"③背水：減1點體力上限，然後依次執行上述所有選項。",
["mobile_quedi1"] = "獲得目標角色的一張手牌。",
["mobile_quedi2"] = "棄置一張基本牌，並令此牌的傷害值基數+1。",
["mobile_quedi3"] = "背水：減1點體力上限，然後依次執行上述所有選項。",
["@mobile_quedi"] = "棄置一張基本牌，並令此牌的傷害值基數+1",
["#MobileQuedi"] = "%from 觸發技能 “<font color=\"yellow\"><b>卻敵</b></font>”，對 %to 造成傷害由 %arg 點增加到 %arg2 點",

["mobile_zhuifeng"] = "椎鋒",
[":mobile_zhuifeng"] = "魏勢力技。你可以失去X+1點體力，然後視為使用【決鬥】。(X為你本回合發動此技能的次數)",
["@mobile_zhuifeng"] = "請選擇目標",
["~mobile_zhuifeng"] = "選擇若干名角色→點擊確定",
["mobile_chongjian"] = "衝堅",
[":mobile_chongjian"] = "吳勢力技。你可以將一張裝備牌當做無距離限制的【殺】或【酒】使用，若你以此法造成傷害，你獲得受到傷害角色裝備區的X張牌(X為此傷害的點數)。",

["@mobile_chongjian"] = "請選擇【%src】的目標",
["~mobile_chongjian"] = "按照此牌使用方式指定角色→點擊確定",

["mobile_choujue"] = "仇決",
[":mobile_choujue"] = "鎖定技。當你殺死其他角色後，你加1點體力上限並摸兩張牌，然後本回合發動【卻敵】的次數上限+1。",
}

--譙周

mobile_qiaozhou = sgs.General(extension,"mobile_qiaozhou","shu2","3",true,true)
--知命
mobile_zhiming = sgs.CreateTriggerSkill{
	name = "mobile_zhiming",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) or
		 (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard) then
		 	if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
				local card = room:askForCard(player, "..", "@mobile_zhiming", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					local move = sgs.CardsMoveStruct(card:getEffectiveId(), player, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), ""))
					room:moveCardsAtomic(move, false)
				end
			end
		end
		return false
	end
}

--星卜

mobile_xingbu = sgs.CreateTriggerSkill{
	name = "mobile_xingbu",
	events = {sgs.EventPhaseStart,sgs.DrawNCards,sgs.CardFinished},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish) and RIGHT(self, player) then
		 	if room:askForSkillInvoke(player, self:objectName(), data) then
				local ids = room:getNCards(3)
				ShowManyCards(player, ids)
				local n = 0
				for _, id in sgs.qlist(ids) do
					if sgs.Sanguosha:getCard(id):isRed() then
						n = n + 1
					end
				end

				room:setPlayerMark(player,"mobile_xingbu_red_card_num",n)
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "mobile_xingbu-invoke", true, true)
				room:setPlayerMark(player,"mobile_xingbu_red_card_num",0)
				if to then
					room:doSuperLightbox("mobile_qiaozhou","mobile_xingbu"..tostring(n))
					room:addPlayerMark(to, "mobile_xingbu"..tostring(n).."_flag")
				end
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("mobile_xingbu3_flag") > 0 then
				room:addPlayerMark(player, "skip_discard")
				data:setValue(data:toInt() + 2)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (not use.card:isKindOf("SkillCard")) and use.card:getSkillName() ~= "xiongzhi" and player:getMark("mobile_xingbu2_flag") > 0 then
				if player:getMark("used_Play") == 1 then

					room:askForDiscard(player, self:objectName(), 1, 1, false, true)
					player:drawCards(2)
				end
			end
		end
		return false
	end
}

mobile_xingbutm = sgs.CreateTargetModSkill{
	name = "#mobile_xingbugtm",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:getMark("mobile_xingbu1_flag") > 0 or player:getMark("mobile_xingbu0_flag") > 0 then
			return -1
		elseif player:getMark("mobile_xingbu3_flag") > 0 then
			return 1
		end
	end,
}

mobile_qiaozhou:addSkill(mobile_zhiming)
mobile_qiaozhou:addSkill(mobile_xingbu)
mobile_qiaozhou:addSkill(mobile_xingbutm)

sgs.LoadTranslationTable{
["mobile_qiaozhou"] = "譙周",
["mobile_zhiming"] = "知命",
[":mobile_zhiming"] = "準備階段開始時或棄牌階段結束時，你摸一張牌，然後可以將一張牌置於牌堆頂。",
["@mobile_zhiming"] = "你可以將一張牌置於牌堆頂",
["mobile_xingbu"] = "星卜",
[":mobile_xingbu"] = "結束階段，你可以展示牌堆頂的三張牌，然後根據X值（X為這三張牌中紅色牌的數量），"..
"令一名其他角色獲得對應的效果直到其下回合結束："..
"①三張：五星連珠；其摸牌階段多摸兩張牌，使用【殺】的次數上限+1，跳過棄牌階段。"..
"②兩張：扶匡東柱；其於出牌階段使用的第一張牌結算結束後，棄置一張牌並摸兩張牌。"..
"③小於兩張：熒惑守心；其使用【殺】的次數上限-1。",
["@mobile_zhiming"] = "你可以將一張牌置於牌堆頂",
["mobile_xingbu3"] = "五星連珠",
["mobile_xingbu2"] = "扶匡東柱",
["mobile_xingbu1"] = "熒惑守心",
["mobile_xingbu0"] = "熒惑守心",
}

--手殺華歆
mobile_huaxin = sgs.General(extension, "mobile_huaxin", "wei2", 3, true)

mobile_yuanqing = sgs.CreateTriggerSkill{
	name = "mobile_yuanqing", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then

				local lord_player
				for _, pp in sgs.qlist(room:getAlivePlayers()) do
					if pp:isLord() or pp:getMark("@clock_time") > 0 then
						lord_player = pp
						break
					end
				end

				local types = {"BasicCard", "TrickCard", "EquipCard"}
				local can_get_types = {}
				for i = 1,3,1 do
					if player:getMark("used_cardtype"..tostring(i).."_Play") > 0 then
						table.insert(can_get_types,types[i])
					end
				end
				if #can_get_types > 0 then
					local GetCardList = sgs.IntList()
					for i = 1,#can_get_types ,1 do
						local pattern = can_get_types[i]
						local DPHeart = sgs.IntList()
						if room:getDiscardPile():length() > 0 then
							for _, id in sgs.qlist(room:getDiscardPile()) do
								local card = sgs.Sanguosha:getCard(id)
								if card:isKindOf(pattern) then
									DPHeart:append(id)
								end
							end
						end
						if DPHeart:length() ~= 0 then
							local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
							GetCardList:append(get_id)
							local card = sgs.Sanguosha:getCard(get_id)
						end
					end
					if GetCardList:length() ~= 0 then
						room:sendCompulsoryTriggerLog(player, self:objectName())
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						lord_player:addToPile("mobile_ren_area", GetCardList)
					end
				end

			end
		end
	end
}

mobile_shuchen = sgs.CreateTriggerSkill{
	name = "mobile_shuchen",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EnterDying},
	can_trigger = function(self, player)
		return player ~= nil 
	end,
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end

		if event == sgs.EnterDying then

			local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
			room:sortByActionOrder(players)
			if lord_player then
				for _, p in sgs.qlist(players) do
					if lord_player:getPile("mobile_ren_area"):length() >= 4 then

						room:notifySkillInvoked( p , self:objectName())
						room:sendCompulsoryTriggerLog( p, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in sgs.qlist( lord_player:getPile("mobile_ren_area") ) do
							dummy:addSubcard(id)
						end
						room:obtainCard(p, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName()), false)
						dummy:deleteLater()

						if player:isWounded() then
							room:recover(player, sgs.RecoverStruct(player, nil, 1  ))
						end

					end
				end
			end
		end
	end,
}

mobile_huaxin:addSkill(mobile_yuanqing)
mobile_huaxin:addSkill(mobile_shuchen)

sgs.LoadTranslationTable{
["mobile_huaxin"] = "手殺華歆",
["&mobile_huaxin"] = "華歆",
["mobile_yuanqing"] = "淵清",
[":mobile_yuanqing"] = "鎖定技，出牌階段結束時，你隨機將棄牌堆中你本階段使用過的牌類型的各一張牌置於「仁」區中。",
["mobile_shuchen"] = "疏陳",
[":mobile_shuchen"] = "鎖定技，當有角色進入瀕死狀態時，若「仁」區中的牌數大於四，則你獲得「仁」區中的所有牌，然後其回復1點體力。",
}

--神荀彧
shen_xunyu = sgs.General(extension, "shen_xunyu", "god", 3, true)
--天佐
tianzuo = sgs.CreateTriggerSkill{
	name = "tianzuo", 
	frequency = sgs.Skill_Compulsory,  
	on_trigger = function()

	end, 
}

--靈策
lingce = sgs.CreateTriggerSkill{
	name = "lingce",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if use.from and use.card and (use.card:isKindOf("qizhengxiangsheng") or isZhinang(use.card) or p:getMark("dinghan"..use.card:objectName()) > 0 ) then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				p:drawCards(1)
			end
		end
	end
}
--定漢
dinghan = sgs.CreateTriggerSkill{
	name = "dinghan" ,
	events = {sgs.TargetConfirmed,sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("TrickCard") and player:getMark("dinghan"..use.card:objectName()) == 0 then

					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					if player:isAlive() then
						room:addPlayerMark(player,"dinghan"..use.card:objectName())
						--local nullified_list = use.nullified_list
						--table.insert(nullified_list, player:objectName())
						--use.nullified_list = nullified_list
						use.to:removeOne(player)
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				
				local tricks_list = {}
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(tricks_list, card:objectName())) and player:getMark("AG_BANCard"..card:objectName()) == 0 then
						if card:isKindOf("TrickCard") then
							table.insert(tricks_list, card:objectName())
						end
					end
				end

				local choices = {}
				for _, trickname in ipairs(tricks_list) do
					if player:getMark("dinghan"..trickname) > 0 then
						table.insert(choices, trickname)
					end
				end

				table.insert(choices, "cancel")
				local pattern = room:askForChoice(player, "dinghan_remove", table.concat(choices, "+"))
				if pattern ~= "cancel" then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(player,"dinghan"..pattern,0)
				else
					choices = {}
					for _, trickname in ipairs(tricks_list) do
						if player:getMark("dinghan"..trickname) == 0 then
							table.insert(choices, trickname)
						end
					end

					table.insert(choices, "cancel")
					local pattern = room:askForChoice(player, "dinghan_add", table.concat(choices, "+"))
					if pattern ~= "cancel" then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player,"dinghan"..pattern)
					end
				end
			end
		end
		return false
	end
}

shen_xunyu:addSkill(tianzuo)
shen_xunyu:addSkill(lingce)
shen_xunyu:addSkill(dinghan)

sgs.LoadTranslationTable{
["shen_xunyu"] = "神荀彧",
["#shen_xunyu"] = "洞心先識",
["tianzuo"] = "天佐",
[":tianzuo"] = "①遊戲開始時，你將8張【奇正相生】加入牌堆。②當一名角色成為【奇正相生】的目標後，你可觀看其手牌，然後可以更改其標記。",
["lingce"] = "靈策",
[":lingce"] = "鎖定技。當有【定漢】紀錄的牌名、【奇正相生】或智囊被使用時，你摸一張牌。",
["dinghan"] = "定漢",
[":dinghan"] = "每種牌名限一次。當你成為錦囊牌的目標時，你紀錄此牌名，取消之；回合開始時，你可以從”定漢“記錄中增加或移除一種錦囊牌牌名。",
["dinghan_remove"] = "定漢移除",
["dinghan_add"] = "定漢增加",
}

--神孫策
shen_sunce = sgs.General(extension, "shen_sunce", "god", 6, true)
--英霸
yingbacard = sgs.CreateSkillCard{
	name = "yingba",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName() and to_select:getMaxHp() > 1
		end
		return false
	end ,
	on_use = function(self, room, source, targets)
		room:loseMaxHp(targets[1])
		room:loseMaxHp(source)
		if targets[1]:getMark("@pingding") == 0 then
			for _, p in sgs.qlist(room:findPlayersBySkillName("yingba")) do
				local assignee_list = p:property("extra_slash_specific_assignee"):toString():split("+")
				table.insert(assignee_list, targets[1]:objectName())
				room:setPlayerProperty(p, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
			end
		end
		room:addPlayerMark(targets[1],"@pingding")
	end
}
yingba = sgs.CreateZeroCardViewAsSkill{
	name = "yingba" ,
	view_as = function(self,cards)
		return yingbacard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#yingba")
	end
}

yingbamc = sgs.CreateMaxCardsSkill{
	name = "#yingbamc", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		local n = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if p:getMark("@pingding") > 0 then
				n = n + p:getMark("@pingding")
			end
		end

		if target:getMark("@pingding") > 0 then
			return n
		end
	end
}

--覆海
scfuhai = sgs.CreateTriggerSkill{
	name = "scfuhai",
	events = {sgs.CardUsed, sgs.TargetSpecified, sgs.TrickCardCanceling,sgs.CardFinished,sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local invoke = false
			for _, p in sgs.qlist(use.to) do
				if p:getMark("@pingding") > 0 then
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
				msg.type = "#scfuhai"
				msg.from = player

				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if p:getMark("@pingding") > 0 then
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
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and RIGHT(self, effect.from) and player:getMark("@pingding") > 0 then return true end

		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and not use.card:isKindOf("SkillCard") and use.from:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(use.to) do
					if p:getMark("@pingding") > 0 then

						room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+ p:getMark("@pingding") ))
						local msg = sgs.LogMessage()
						msg.type = "#GainMaxHp"
						msg.from = player
						msg.arg = p:getMark("@pingding")
						room:sendLog(msg)

						room:setPlayerMark(p,"@pingding",0)

						for _, pp in sgs.qlist(room:findPlayersBySkillName("yingba")) do
							local assignee_list = pp:property("extra_slash_specific_assignee"):toString():split("+")
							table.removeOne(assignee_list, p:objectName())
							room:setPlayerProperty(pp, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
						end

					end
				end
			end

		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() ~= player:objectName() and player:hasSkill("scfuhai") then
				if splayer:getMark("@pingding") > 0 then
					room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp() + splayer:getMark("@pingding") ))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = player
					msg.arg = splayer:getMark("@pingding")
					room:sendLog(msg)
					player:drawCards(splayer:getMark("@pingding"))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--馮河
pinghe = sgs.CreateTriggerSkill{
	name = "pinghe",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName() and (not player:isKongcheng()) then
			if room:askForSkillInvoke(player, self:objectName(), data) then

				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "pinghe", "pinghe-invoke", false, true)
				local qiaosi_give_cards = room:askForExchange(player, "pinghe", 1,1, true, "pinghe_exchange")
				if target and qiaosi_give_cards then
					room:obtainCard(target, qiaosi_give_cards, false)
				end

				room:loseMaxHp(player,1)
				local msg = sgs.LogMessage()
				msg.type = "#PingheProtect"
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

				if player:hasSkill("yingba") then
					if damage.from:getMark("@pingding") == 0 then
						for _, p in sgs.qlist(room:findPlayersBySkillName("yingba")) do
							local assignee_list = p:property("extra_slash_specific_assignee"):toString():split("+")
							table.insert(assignee_list, damage.from:objectName())
							room:setPlayerProperty(p, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
						end
					end
					room:addPlayerMark(damage.from,"@pingding")
				end

				if player:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(player, self:objectName().."engine")
					return true
				end


			end
		end
	end
}

pinghemc = sgs.CreateMaxCardsSkill{
	name = "#pinghemc", 
	frequency = sgs.Skill_Compulsory ,
	fixed_func = function(self, player)
		if player:hasSkill("pinghe") then
			return player:getLostHp()
		end
		return -1
	end
}

shen_sunce:addSkill(yingba)
shen_sunce:addSkill(yingbamc)
shen_sunce:addSkill(scfuhai)
shen_sunce:addSkill(pinghe)
shen_sunce:addSkill(pinghemc)

sgs.LoadTranslationTable{
["shen_sunce"] = "神孫策",
["#shen_sunce"] = "距江鬼雄",
["yingba"] = "英霸",
[":yingba"] = "①出牌階段限一次，你可令一名體力上限大於1的其他角色減少1點體力上限並獲得「平定」標記，然後你減少1點體力上限。②你對擁有「平定」標記的角色使用牌沒有次數限制。③擁有「平定」標記的角色手牌上限+X（X為場上的「平定」標記數）。",
["@pingding"] = "平定",
["scfuhai"] = "覆海",
[":scfuhai"] = "鎖定技。①當你使用牌指定目標後，若目標角色有「平定」標記，則其不可響應此牌。②當你使用牌結算結束後，你移除所有目標角色的「平定」標記並增加等量的體力上限。③擁有「平定」標記的角色死亡時，你增加X點體力上限並摸X張牌。（X為其擁有的「平定」標記數）。",
["#scfuhai"] = "%from 的技能 “<font color=\"yellow\"><b>覆海</b></font>”被觸發， %to 無法響應此 %card  ",

["pinghe"] = "馮河",
[":pinghe"] = "①你的手牌上限基數等於你已損失的體力值。②當你受到其他角色造成的傷害時，若你有手牌，則你可以防止此傷害，減少1點體力值上限並將1張手牌交給一名其他角色。然後若你擁有〖英霸〗，則傷害來源獲得1個「平定」標記。",
["#PingheProtect"] = "%from 的「<font color=\"yellow\"><b>馮河</b></font>」效果被觸發，防止了 %arg 點傷害[%arg2]",
["pinghe-invoke"] = "你可以發動“馮河”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
["pinghe_exchange"] = "請選擇等量的牌交給對方<br/> <b>操作提示</b>: 選擇牌直到可以點確定<br/>",
}



--陳武董襲
sp_chendong = sgs.General(extension, "sp_chendong", "wu2", 4, true)

spyilie = sgs.CreateTriggerSkill{
	name = "spyilie",
	events = {sgs.EventPhaseStart,sgs.SlashMissed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local choices = {"spyilie1","spyilie2","spyilie3","cancel"}
				local choice = room:askForChoice(player , "spyilie", table.concat(choices, "+"), data)
				if choice ~= "cancel" then 
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					if choice == "spyilie1" or choice == "spyilie3" then
						room:addPlayerMark(player, "spyilie1_Play")
					end
					if choice == "spyilie2" or choice == "spyilie3" then
						room:addPlayerMark(player, "spyilie2_Play")						
					end
					if choice == "spyilie3" then
						room:loseHp(player)
					end
				end
			end
		elseif event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if player:getMark("spyilie2_Play") > 0 then
				player:drawCards(1)
			end
		end
	end,
}

spyilieTM = sgs.CreateTargetModSkill{
	name = "#spyilieTM", 
	residue_func = function(self, from)
		if from:hasSkill("spyilie") then
			return 1
		end
		return 0
	end
}

spfenming = sgs.CreateTriggerSkill{
	name = "spfenming",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getHp() <= player:getHp() and (not p:isChained() or (p:isChained() and not p:isNude()))  then
							_targets:append(p) 
						end
					end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "spfenming", "@spfenming", true)
					if s then
						room:notifySkillInvoked(player, self:objectName())						
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						if not s:isChained() then
							room:setPlayerProperty(s, "chained", sgs.QVariant(true))
						end
						if s:isChained() and not s:isNude() then
							room:obtainCard(player,room:askForCardChosen(player, s, "he", "cuike", false, sgs.Card_MethodDiscard),true)
						end
					end
				end
			end
		end
	end,
}

sp_chendong:addSkill(spyilie)
sp_chendong:addSkill(spyilieTM)
sp_chendong:addSkill(spfenming)

sgs.LoadTranslationTable{
["sp_chendong"] = "陳武董襲",
["spyilie"] = "毅烈",
[":spyilie"] = "出牌階段開始時，你可選擇：①本階段內使用【殺】的次數上限+1。②本回合內使用【殺】被【閃】抵消時，摸一張牌。③背水：失去1點體力，然後依次執行上述所有選項。",
["spyilie1"] = "本階段內使用【殺】的次數上限+1。",
["spyilie2"] = "本回合內使用【殺】被【閃】抵消時，摸一張牌。",
["spyilie3"] = "背水：失去1點體力，然後依次執行上述所有選項。",
["spfenming"] = "奮命",
[":spfenming"] = "出牌階段限一次，你可以選擇一名體力值不大於你的角色。若其：未橫置，其橫置；已橫置，你獲得其一張牌。",
["@spfenming"] = "你可以對一名角色發動「奮命」",
}

--袁渙
yuanhuan = sgs.General(extension, "yuanhuan", "wei2", 3, true, true)

--請決
qingjue = sgs.CreateTriggerSkill{
	name = "qingjue",
	events = {sgs.TargetSpecifying},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if use.card:isKindOf("Slash") and not use.to:contains(p) and p:objectName() ~= player:objectName() and not p:isKongcheng() and not use.from:isKongcheng() and use.from:getHp() <  player:getHp() then
				if room:askForSkillInvoke(p, "qingjue", data) then
					skill(self, room, p, true)

					local msg = sgs.LogMessage()
					msg.type = "#Jianzheng"
					msg.from = p
					msg.to = use.to
					msg.arg = self:objectName()
					msg.card_str = use.card:toString()
					
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						use.to = sgs.SPlayerList()
						if p:pindian(use.from, "qingjue", nil) then
							msg.arg2 = "Jianzheng2"

						else
							msg.arg2 = "Jianzheng1"
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
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

fengjie = sgs.CreateTriggerSkill{
	name = "fengjie",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_Finish and RIGHT(self, player) then

			if RIGHT(self, player) then
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fengjie-invoke", true, true)
				if to then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:addPlayerMark(to, "@fengjie")
						room:setPlayerMark(player, "fengjie"..to:objectName().."_target",1)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@fengjie") > 0 then
					local n = player:getHp() - p:getHandcardNum()
					if n < 0 then
						room:askForDiscard(p, self:objectName(), -n, -n, false, false)
					elseif n > 0 then
						n = math.min(4,player:getHp()) - p:getHandcardNum()
						p:drawCards(n, self:objectName())
					end
				end
			end
		end
	end,
}

yuanhuan:addSkill(qingjue)
yuanhuan:addSkill(fengjie)

sgs.LoadTranslationTable{
["yuanhuan"] = "袁渙",
["qingjue"] = "請決",
[":qingjue"] = "每輪限一次。當有其他角色A使用牌指定另一名體力值小於A且不處於瀕死狀態的其他角色B為目標時，你可以摸一張牌，然後與A拼點。若你贏，你取消此目標。若你沒贏，你將此牌的目標改為自己。",
["fengjie"] = "奉節",
[":fengjie"] = "鎖定技，準備階段開始時，你選擇一名其他角色並獲得如下效果直到你下回合開始：一名角色的結束階段開始時，你將手牌摸至（至多摸至四張）或棄置至與其體力值相等。",
["fengjie-invoke"] = "你可以發動“奉節”",
}

--手殺宗預
sp_zongyu = sgs.General(extension, "sp_zongyu", "shu2", 3, true, true)

zhibian = sgs.CreateTriggerSkill{
	name = "zhibian" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ==  sgs.Player_RoundStart and not player:isKongcheng() then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					_targets:append(p)
				end
			end
			if not _targets:isEmpty() then
				local to = room:askForPlayerChosen(player, _targets, "zhibian", "zhibian-invoke", true)
				if to then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player, "zhibian")
					room:doAnimate(1, player:objectName(), to:objectName())
					local success = player:pindian(to, "zhibian", nil)
					if success then
						room:setPlayerFlag(to , "zhibian_target")
						local choices = {"zhibian1","zhibian2","zhibian3","cancel"}
						local choice = room:askForChoice(player , "zhibian", table.concat(choices, "+"), data)
						room:setPlayerFlag(to , "-zhibian_target")
						if choice ~= "cancel" then 
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							if choice == "zhibian1" or choice == "zhibian3" then
								if not to:hasEquip() and to:getJudgingArea():length() == 0 then return end
								local card_id = room:askForCardChosen(player, to, "ej", self:objectName())
								local card = sgs.Sanguosha:getCard(card_id)
								local place = room:getCardPlace(card_id)
								local equip_index = -1
								if place == sgs.Player_PlaceEquip then
									local equip = card:getRealCard():toEquipCard()
									equip_index = equip:location()
								end


								if equip_index ~= -1 then
													--if not p:getEquip(equip_index) and p:hasEquipArea(equip_index) then
									if not player:getEquip(equip_index) and
								((player:getMark("@AbolishWeapon") == 0 and equip_index == 0) or
								(player:getMark("@AbolishArmor") == 0 and equip_index == 1) or
								(player:getMark("@AbolishHorse") == 0 and equip_index == 2) or
								(player:getMark("@AbolishHorse") == 0 and equip_index == 3) or
								(player:getMark("@AbolishTreasure") == 0 and equip_index == 4)) then
										room:moveCardTo(card, to, player, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), ""))
									end
								else
									if not player:isProhibited(player, card) and not player:containsTrick(card:objectName()) then
										room:moveCardTo(card, to, player, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), ""))
									end
								end
							end
							if choice == "zhibian2" or choice == "zhibian3" then
								local theRecover = sgs.RecoverStruct()
								theRecover.recover = 1
								theRecover.who = player
								room:recover(player, theRecover)
							end
							if choice == "zhibian3" then
								room:addPlayerMark(player,"skip_draw")
							end
						end

					else

						room:loseHp(player)
					end
				end
			end
		end
	end
}

yuyan = sgs.CreateTriggerSkill{
	name = "yuyan" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.SlashEffected, sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and not use.card:isVirtualCard() and use.card:getNumber() > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:setMark("yuyan", 0)
				local dataforai = sgs.QVariant()
				dataforai:setValue(player)
				local x = use.card:getNumber()
				local prompt = string.format("@yuyan:%s:%s", player:objectName(), tostring(x))
				if not room:askForCard(use.from, ".|.|"..tostring(x).."~13|.", prompt ,dataforai) then
					player:addMark("yuyan")
				end
			end
		else
			local effect= data:toSlashEffect()
			if player:getMark("yuyan") > 0 then
				player:removeMark("yuyan")
				return true
			end
		end
	end
}

sp_zongyu:addSkill(zhibian)
sp_zongyu:addSkill(yuyan)

sgs.LoadTranslationTable{
["sp_zongyu"] = "手殺宗預",
["&sp_zongyu"] = "宗預",
["zhibian"] = "直辯",
["zhibian-invoke"] = "你可以發動“直辯”",
[":zhibian"] = "準備階段，你可以和一名其他角色拼點。若你贏，你可選擇：①將其裝備區/判定區內的一張牌移動到你的對應區域。②回復1點體力。③背水：跳過下個摸牌階段，然後依次執行上述所有選項；若你沒贏，你失去1點體力。",
["zhibian1"] = "將其裝備區/判定區內的一張牌移動到你的對應區域。",
["zhibian2"] = "回復1點體力。",
["zhibian3"] = "背水：跳過下個摸牌階段，然後依次執行上述所有選項。",
["yuyan"] = "御嚴",
[":yuyan"] = "鎖定技。當你成為非轉換的【殺】的目標時，若使用者的體力值大於你且此【殺】有點數，則你令使用者選擇一項：①交給你一張點數大於此【殺】的牌。②取消此目標。",
["@yuyan"] = "請棄置一張點數大於 %dest 的手牌，否則此【殺】無效。",
}

--傅僉
fuqian = sgs.General(extension, "fuqian", "shu2", 4, true, true)

jueyong = sgs.CreateTriggerSkill{
	name = "jueyong" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed,sgs.EventPhaseStart,sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if not use.card:isKindOf("Peach") and not use.card:isKindOf("Analeptic") and use.to:length() == 1 and use.card:getSkillName() ~= "jueyong" 
				  and (player:getPile("jueyong"):length() < player:getHp()*2) then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					if player:isAlive() and not use.card:isVirtualCard() then
						player:addToPile("jueyong", use.card)
						room:addPlayerMark(player,  "jueyong"..use.card:getEffectiveId().."|"..use.from:objectName() )
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			for _, id in sgs.qlist(player:getPile("jueyong")) do
				--if not table.contains(suit, sgs.Sanguosha:getCard(id):getSuit()) then
				--	table.insert(suit, sgs.Sanguosha:getCard(id):getSuit())
				--end

				for _, p in sgs.qlist(room:getAllPlayers()) do
					if player:getMark("jueyong"..id.."|"..p:objectName()) > 0 then

						room:removePlayerMark(player,"jueyong"..id.."|"..p:objectName())
						local use_card = sgs.Sanguosha:getCard(id)
						use_card:setSkillName(self:objectName())

						local targets_list = sgs.SPlayerList()
						if not room:isProhibited(p, player, use_card) then
							targets_list:append(player)
						end
						if targets_list:length() > 0 then

							room:useCard(sgs.CardUseStruct( use_card , p, targets_list))

						end

						room:moveCardTo(use_card, nil, sgs.Player_DiscardPile, false)
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(player:getPile("jueyong"))
				room:throward( dummy,player,player)
			end
		end
	end,
}

jueyong_remove_mark = sgs.CreateTriggerSkill{
	name = "jueyong_remove_mark",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from_places and move.from_places:contains(sgs.Player_PlaceSpecial) and player:getPile("jueyong"):length() > 0 then
				for _, id in sgs.qlist(move.card_ids) do
					if player:getPile("jueyong"):contains( id ) then
						
						for _, mark in sgs.list(player:getMarkNames()) do
							if string.find(mark, "jueyong") and string.find(mark, id) and player:getMark(mark) > 0 then
								room:setPlayerMark(p, mark, 0)
							end
						end
					end
				end
			end

		end
		return false
	end
}

poxiangCard = sgs.CreateSkillCard{
	name = "poxiang" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "poxiang","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		source:drawCards(3, "poxiang")

		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:addSubcards(source:getPile("jueyong"))
		room:throward( dummy,source,source)
		room:loseHp(source,1)
		room:addPlayerMark(source,"skip_discard")
	end
}
poxiangVS = sgs.CreateViewAsSkill{
	name = "poxiang" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected == 0 then
			return (not to_select:isEquipped())
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = poxiangCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self,player)
		return player:usedTimes("#poxiang") < 1
	end
}

poxiang = sgs.CreateTriggerSkill{
	name = "poxiang",
	events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd},
	view_as_skill = poxiangVS,
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

poxiangmc = sgs.CreateMaxCardsSkill{
	name = "#poxiangmc",
	extra_func = function(self, target)
		local x = 0
		if target:hasSkill("poxiang") then
			for _, card in sgs.list(target:getHandcards()) do
				if target:getMark("poxiang"..card:getId().."-Clear") > 0 then
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


fuqian:addSkill(jueyong)
fuqian:addSkill(poxiang)
fuqian:addSkill(poxiangmc)

if not sgs.Sanguosha:getSkill("jueyong_remove_mark") then skills:append(jueyong_remove_mark) end

sgs.LoadTranslationTable{
["fuqian"] = "傅僉",
["jueyong"] = "絕勇",
[":jueyong"] = "鎖定技。①當你不因〖絕勇〗成為唯一牌的目標時，若此牌不為轉化牌且對應的實體牌牌數為1且不為【桃】或【酒】，且「絕」的數量小於你體力值的兩倍，則你將此牌置於你的武將牌上，稱為「絕」，且取消此牌的目標。②結束階段開始時，你令所有「絕」的原使用者依次對你使用所有「絕」，將無法使用的「絕」置入棄牌堆。",
["poxiang"] = "破降",
[":poxiang"] = "出牌階段限一次。你可以將一張牌交給一名其他角色。你摸三張牌，移去所有「絕」並失去1點體力，以此法獲得的牌不計入本回合的手牌上限。",
}

--官渡劉曄
mobile_liuye = sgs.General(extension, "mobile_liuye", "wei2", "3", true)

mobile_lypolu = sgs.CreateTriggerSkill{
	name = "mobile_lypolu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and not (player:getWeapon() and player:getWeapon():isKindOf("MobileThunderclapCatapult"))
				and room:getTag("MTC_ID"):toInt() > 0 then

				local id = room:getTag("MTC_ID"):toInt()

				if room:getCardPlace(id) == sgs.Player_PlaceTable or room:getCardPlace(id) == sgs.Player_DrawPile or room:getCardPlace(id) == sgs.Player_DiscardPile or room:getCardPlace(id) == sgs.Player_PlaceSpecial then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local card = sgs.Sanguosha:getCard(id)
					room:useCard(sgs.CardUseStruct(card, player, player))
				end
			end
		else
			for i = 1, data:toDamage().damage do
				if not (player:getWeapon() and player:getWeapon():isKindOf("MobileThunderclapCatapult")) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:drawCards(player, 1, self:objectName())
					useEquipForWangYun(room, player , "Weapon")	
				end
			end
		end
		return false
	end
}

mobile_liuye:addSkill(mobile_lypolu)
mobile_liuye:addSkill("choulve")

sgs.LoadTranslationTable{
["mobile_liuye"] = "劉曄",
["&mobile_liuye"] = "劉曄",
["#mobile_liuye"] = "佐世之才",
["mobile_lypolu"] = "破櫓",
[":mobile_lypolu"] = "鎖定技，回合開始時，你獲得遊戲外、牌堆或棄牌堆中的【霹靂車】並使用之；當你受到1點傷害後，若你的裝備區內沒有【霹靂車】，則你摸一張牌，從牌堆中隨機獲得一張武器牌並使用之。",
["$mobile_lypolu1"] = "設此發石車，可破袁軍高櫓。",
["$mobile_lypolu2"] = "霹靂之聲，震喪敵膽。",
["~mobile_liuye"] = "唉~於上不得佐君主，於下不得親同僚，吾愧為佐世人臣！",
}

--[[
司馬孚
勵德：距離1以內的角色受到傷害後,你可判定,若點數:大於等於6,其獲得此判定牌;小於等於6, 來源棄置一張手牌。
臣節：當一名角色的判定牌生效前,你可以打出一張與判定牌花色相同的牌代替之,然後你摸兩張牌。
]]--
simafu = sgs.General(extension, "simafu", "wei2", "3", true)

lide = sgs.CreateTriggerSkill{
	name = "lide",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		local damage = data:toDamage()

		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if (p:distanceTo(player) == 1 or p:objectName() == player:objectName()) and p:hasSkill("lide") then
				local _data = sgs.QVariant()
				_data:setValue(player)	
				if room:askForSkillInvoke(p,self:objectName(),_data) then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|6-13"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = p
					room:judge(judge)
					if judge:isGood() then
						local card = judge.card
						if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge then
							p:obtainCard(card)
						end
					else
						if damage.from then
							room:askForDiscard(damage.from, self:objectName(), 1,1, false, false)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target:isAlive()
	end
}

chenjie = sgs.CreateTriggerSkill{
	name = "chenjie" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isKongcheng() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@chenjie-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local forced = false
		if player:getMark("JilveEvent") == sgs.AskForRetrial then forced = true end
		local askforcardpattern = "."
		if judge.card:getSuit() == sgs.Card_Spade then
			askforcardpattern = ".|spade"
		elseif judge.card:getSuit() == sgs.Card_Heart then
			askforcardpattern = ".|heart"
		elseif judge.card:getSuit() == sgs.Card_Diamond then
			askforcardpattern = ".|diamond"
		else
			askforcardpattern = ".|club"
		end

		if forced then
			if judge.card:getSuit() == sgs.Card_Spade then
				askforcardpattern = ".|spade!"
			elseif judge.card:getSuit() == sgs.Card_Heart then
				askforcardpattern = ".|heart!"
			elseif judge.card:getSuit() == sgs.Card_Diamond then
				askforcardpattern = ".|diamond!"
			else
				askforcardpattern = ".|club!"
			end
		end
		local card = room:askForCard(player, askforcardpattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if forced and (card == nil) then
			card = player:getRandomHandCard()
		end
		if card then
			room:broadcastSkillInvoke(self:objectName())
			room:retrial(card, player, judge, self:objectName())
			player:drawCards(2)
		end
		return false
	end
}

simafu:addSkill(lide)
simafu:addSkill(chenjie)

sgs.LoadTranslationTable{
["simafu"] = "司馬孚",
["&simafu"] = "司馬孚",

["lide"] = "勵德",
[":lide"] = "距離1以內的角色受到傷害後,你可判定,若點數:大於等於6,其獲得此判定牌;小於等於6, 來源棄置一張手牌。",

["chenjie"] = "臣節",
[":chenjie"] = "當一名角色的判定牌生效前,你可以打出一張與判定牌花色相同的牌代替之,然後你摸兩張牌。",
["@chenjie-card"] = "請發動「%dest」來修改 %src 的「%arg」判定",
}

--[[
閻圃
緩圖：每輪限一次,其他角色的摸牌階段開始前,若其處於你攻擊範圍內,你可以交給其一張牌,令
其跳過摸牌階段。若如此做,你可於本回合結束階段選擇一項:1. 其回復1點體力並摸兩張牌;
2. 你摸三張牌並交給其兩張手牌。
避禍：限定技,當一名角色脫離瀕死狀態時,你可以令其摸三張牌。若如此做,除其外的角色本輪計算與其的距離+X (X為角色數)
]]--
yanpu = sgs.General(extension, "yanpu", "qun3", "3", true)
--緩圖
huantu = sgs.CreateTriggerSkill{
	name = "huantu",
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (not player:isSkipped(change.to)) and change.to == sgs.Player_Draw then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:inMyAttackRange(player) and (not p:isNude()) and p:getMark("huantu_lun") == 0 then
						local id = room:askForCard(p, "..", "@huantu", data, sgs.Card_MethodNone)
						if id then
							room:doAnimate(1, player:objectName(), p:objectName())
							room:broadcastSkillInvoke(self:objectName())							
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), "huantu","")
							room:moveCardTo(id,player ,sgs.Player_PlaceHand,reason)
							player:skip(change.to)
							room:addPlayerMark(player,"huantu_used-Clear")
							room:addPlayerMark(p,"huantu_invoke-Clear")
							room:addPlayerMark(p,"huantu_lun")
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			if player:getMark("huantu_used-Clear") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("huantu_invoke-Clear") > 0 then
						local choice = room:askForChoice(p,self:objectName(),"huantu1+huantu2")
						if choice == "huantu1" then
							local theRecover = sgs.RecoverStruct()
							theRecover.recover = 1
							theRecover.who = player
							room:recover(player, theRecover)
							player:drawCards(2)

						elseif choice == "huantu2" then
							p:drawCards(3)
							local qiaosi_give_cards = room:askForExchange(p, self:objectName(), 2,2, true, "huantu_exchange")
							if qiaosi_give_cards then
								room:obtainCard(player, qiaosi_give_cards, false)
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
--避禍
bihuo = sgs.CreateTriggerSkill{
	name = "bihuo",
	events = {sgs.QuitDying},
	frequency = sgs.Skill_Limited,
	limit_mark = "@bihuo", 
	on_trigger = function(self, event, player, data, room)
		local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
		room:sortByActionOrder(players)
		for _, p in sgs.qlist(players) do			
			if p:isAlive() and p:getMark("@bihuo") > 0 then
				local _data = sgs.QVariant()
				_data:setValue(player)
				if room:askForSkillInvoke(p, self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(3)
					local alive_num = room:getAlivePlayers():length()
					room:addPlayerMark(player , "@bihuo_turn" , alive_num)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

bihuoDis = sgs.CreateDistanceSkill{
	name = "#bihuoDis",
	correct_func = function(self, from, to)
		return to:getMark( "@bihuo_turn" )
	end
}

yanpu:addSkill(huantu)
yanpu:addSkill(bihuo)
yanpu:addSkill(bihuoDis)

sgs.LoadTranslationTable{
["yanpu"] = "閻圃",

["huantu"] = "緩圖",
[":huantu"] = "每輪限一次,其他角色的摸牌階段開始前,若其處於你攻擊範圍內,你可以交給其一張牌,令其跳過摸牌階段。若如此做,你"
.."可於本回合結束階段選擇一項:1. 其回復1點體力並摸兩張牌;2. 你摸三張牌並交給其兩張手牌。",
["@huantu"] = "你可以發動「緩圖」",

["huantu1"] = "其回復1點體力並摸兩張牌",
["huantu2"] = "你摸三張牌並交給其兩張手牌",

["bihuo"] = "避禍",
[":bihuo"] = "限定技,當一名角色脫離瀕死狀態時,你可以令其摸三張牌。若如此做,除其外的角色本輪計算與其的距離+X (X為角色數)",
}


--[[
馬元義
集兵：摸牌階段,若「兵」的數量小於勢力數,你可以改為將牌堆頂兩張牌置於武將牌上,稱為「兵」。你可將一張「兵」當【殺】或【閃】使用或打出。
往京：鎖定技,當你使用或打出「兵」時,若對方是體力值最大的角色,你摸一張牌。
謀製：覺醒技,準備階段,若「兵」的數量大於等於勢力數,你減1點體力上限,獲得技能「兵禍」。
兵禍：一名角色的結束階段,若你本回合使用或打出過「兵」,你可令一名角色判定,若為黑色,你對其造成1點雷電傷害。
]]--
mayuanyi = sgs.General(extension, "mayuanyi", "qun3", "4", true)

mobile_jibingVS = sgs.CreateOneCardViewAsSkill{
	name = "mobile_jibing",
	--response_or_use = true,
	filter_pattern = ".|.|.|mobile_bing",
	expand_pile = "mobile_bing",
	view_as = function(self,card)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern ~= "jink" then
			pattern = "slash"
		end
		local cards = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
		cards:setSkillName(self:objectName())
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getPile("mobile_bing"):length() > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return ((pattern == "slash") or (pattern == "jink")) and player:getPile("mobile_bing"):length() > 0
	end,
}

mobile_jibing = sgs.CreateTriggerSkill{
	name = "mobile_jibing",
	view_as_skill = mobile_jibingVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then

			local kingdom_set = {}
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				local kingdom = p:getKingdom()
				if not table.contains(kingdom_set, kingdom) then
					table.insert(kingdom_set, kingdom)
				end
			end

			if data:toInt() > 0 and (player:getPile("mobile_bing"):length() < #kingdom_set) then
				if room:askForSkillInvoke(player, "mobile_jibing", data) then
					room:broadcastSkillInvoke("mobile_jibing")
					
					local list = sgs.IntList()
					for _, id in sgs.qlist(room:getDrawPile()) do
						list:append(id)
						if list:length() == 2 then
							break
						end
					end
					player:addToPile("mobile_bing", list)

					data:setValue(0)
				end
			end
		end
	end
}

wangjing = sgs.CreateTriggerSkill{
	name = "wangjing" ,
	events = {sgs.CardResponded, sgs.TargetSpecified} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		local max_hp = 0
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			max_hp = math.max(max_hp , pp:getHp())
		end
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_card:getSkillName() == "mobile_jibing" and resp.m_who and resp.m_who:getHp() == max_hp then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
				end
			end
		else
			local use = data:toCardUse()
			if use.card:getSkillName() == "mobile_jibing" then
				for _, p in sgs.qlist(use.to) do
					if p:getHp() == max_hp then
						if player:askForSkillInvoke(self:objectName(), data) then
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


moucuan = sgs.CreateTriggerSkill{
	name = "moucuan" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getMark("moucuan") == 0 then
				local kingdom_set = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					local kingdom = p:getKingdom()
					if not table.contains(kingdom_set, kingdom) then
						table.insert(kingdom_set, kingdom)
					end
				end

				if player:getPile("mobile_bing"):length() >= #kingdom_set or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
					if room:changeMaxHpForAwakenSkill(player) then
						room:addPlayerMark(player, "moucuan")
						room:broadcastSkillInvoke("moucuan")
						if player:getPile("mobile_bing"):length() >= #kingdom_set then
							local msg = sgs.LogMessage()
							msg.type = "#moucuanWake"
							msg.from = player
							msg.to:append(player)
							msg.arg = player:getPile("mobile_bing"):length()
							msg.arg2 = self:objectName()
							room:sendLog(msg)
						end
						room:doSuperLightbox("mayuanyi","moucuan")



						room:acquireSkill(player, "binghuo")
					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
	end
}

binghuo = sgs.CreateTriggerSkill{
	name = "binghuo",
	events = {sgs.PreCardUsed, sgs.PreCardResponded,sgs.EventPhaseStart},
	global = true,
	priority = -1,
	on_trigger = function(self, event, player, data, room)
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
			if card and (not card:isKindOf("SkillCard")) and card:getSkillName() == "mobile_jibing" then
				room:addPlayerMark(player,"binghuo-Clear")
			end
			return false
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("binghuo-Clear") > 0 and p:hasSkill("binghuo") then
						local target = room:askForPlayerChosen(p, room:getOtherPlayers(p), self:objectName(), "binghuo-invoke", true, true)
						if target then
							room:doAnimate(1, p:objectName(), target:objectName())
							room:broadcastSkillInvoke(self:objectName())

							local judge = sgs.JudgeStruct()
							judge.pattern = ".|black"
							judge.good = false
							judge.reason = self:objectName()
							judge.who = target
							room:judge(judge)
							if judge:isBad() then
								room:damage(sgs.DamageStruct(self:objectName(), p, target, 1, sgs.DamageStruct_Thunder))
							end
						end
					end
				end
			end
		end
	end
}

mayuanyi:addSkill(mobile_jibing)
mayuanyi:addSkill(wangjing)
mayuanyi:addSkill(moucuan)
mayuanyi:addRelateSkill("binghuo")
if not sgs.Sanguosha:getSkill("binghuo") then skills:append(binghuo) end

sgs.LoadTranslationTable{
["mayuanyi"] = "馬元義",

["mobile_jibing"] = "集兵",
[":mobile_jibing"] = "摸牌階段,若「兵」的數量小於勢力數,你可以改為將牌堆頂兩張牌置於武將牌上,稱為「兵」。你可將一張「兵」當【殺】或【閃】使用或打出。",
["mobile_bing"] = "兵",
["wangjing"] = "往京",
[":wangjing"] = "鎖定技,當你使用或打出「兵」時,若對方是體力值最大的角色,你摸一張牌。",
["moucuan"] = "謀篡",
[":moucuan"] = "覺醒技,準備階段,若「兵」的數量大於等於勢力數,你減1點體力上限,獲得技能「兵禍」。",
["binghuo"] = "兵禍",
[":binghuo"] = "一名角色的結束階段,若你本回合使用或打出過「兵」,你可令一名角色判定,若為黑色,你對其造成1點雷電傷害。",
["#moucuanWake"] = "%from 的“兵”為 %arg 張，觸發“%arg2”覺醒",
["binghuo-invoke"] = "你可以發動“兵禍”",
}

--[[
高覽
竣攻：出牌階段,你可棄置X+1張牌或失去X+1點體力(X為你本回合發動此技能的次數),然後視為使用一張無距離和次數限制的【殺】若此【殺】造成傷害,本回合此技能失效。
等力：當你使用【殺】指定其他角色為目標或成為其他角色使用【殺】的目標時,若你與其體力值相同,你可以摸一張牌。
]]--
mobile_gaolan = sgs.General(extension, "mobile_gaolan", "qun3", "4", true)

jungongCard = sgs.CreateSkillCard{
	name = "jungong", 
	target_fixed  = true,
	on_use = function(self, room, source, targets)
		if self:getSubcards():isEmpty() then 
			room:loseHp(source , (source:getMark("@jungong-Clear")+1) )
		end
		room:askForUseCard(source, "@@jungong", "@jungong_invoke", -1)
	end
}

jungong = sgs.CreateViewAsSkill{
	name = "jungong", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@jungong" then
			return false
		else
			return #selected < (sgs.Self:getMark("@jungong-Clear") + 1)
		end
	end, 
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@jungong" then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			return slash
		else
			if #cards == 0 then
				return jungongCard:clone()
			elseif #cards == (sgs.Self:getMark("@jungong-Clear") + 1) then
				local skillcard = jungongCard:clone()
				for _, c in ipairs(cards) do
					skillcard:addSubcard(c)
				end
				return skillcard
			else 
				return nil
			end
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("jungong_can_not_use-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jungong"
	end
}

jungongTargetMod = sgs.CreateTargetModSkill{
	name = "#jungongTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "jungong" then
			return 1000
		end
	end,
}

dengli = sgs.CreateTriggerSkill{
	name = "dengli",
	events = {sgs.TargetSpecified,sgs.TargetConfirmed},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and use.to:contains(player) and use.from:objectName() ~= player:objectName() and (not use.card:isKindOf("SkillCard")) and use.card:isKindOf("Slash") then
				if use.from:getHp() == player:getHp() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and (not use.card:isKindOf("SkillCard")) and use.card:isKindOf("Slash")  then
				for _, p in sgs.qlist(use.to) do
					if p:getHp() == player:getHp() and p:objectName() ~= player:objectName() then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		end
	end
}

mobile_gaolan:addSkill(jungong)
mobile_gaolan:addSkill(jungongTargetMod)
mobile_gaolan:addSkill(dengli)

sgs.LoadTranslationTable{
["mobile_gaolan"] = "手殺高覽",
["&mobile_gaolan"] = "高覽",

["jungong"] = "竣攻",
[":jungong"] = "出牌階段,你可棄置X+1張牌或失去X+1點體力(X為你本回合發動此技能的次數),然後視為使用一張無距離和次數限制的【殺】；若此【殺】造成傷害,本回合此技能失效。",
["@jungong_invoke"] = "你可以視為使用一張無距離和次數限制的【殺】",
["~jungong"] = "選擇【殺】的目標→點“確定”",
["dengli"] = "等力",
[":dengli"] = "當你使用【殺】指定其他角色為目標或成為其他角色使用【殺】的目標時,若你與其體力值相同,你可以摸一張牌。",
}

--[[
花蔓
象陣：鎖定技,【南蠻入侵】對你無效;【南蠻入侵】結算後,若此牌造成過傷害,你與來源各摸一張牌。
芳蹤：鎖定技,出牌階段,你使用傷害類牌不能指定你攻擊範圍內的角色為目標。攻擊範圍內有你的其他角色不能使用傷害類牌指定你為目標。結束階段,你將手牌摸至X張(X為角色數)。
嬉戰：其他角色的回合開始時,你失去1點體力,或棄置一張牌並令「芳蹤」於本回合失效,若此牌為:
,其視為使用【酒】;,你視為使用【無中生有】,你視為對其使用【鐵索連環】;,視為對其使用【殺】
]]--
mobile_huaman = sgs.General(extension, "mobile_huaman", "shu2", "3", false)

xiangzhen = sgs.CreateTriggerSkill{
	name = "xiangzhen",
	events = {sgs.CardFinished, sgs.CardEffected},
	frequency =sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("SavageAssault") and use.card:hasFlag("damage_record") then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:doAnimate(1, p:objectName(), player:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
					p:drawCards(1)
				end
			end
		elseif event == sgs.CardEffected and RIGHT(self, player) then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("SavageAssault") then
				return true
			else
				return false
			end
		end
	end,
	can_trigger = function(self, target)
		return target 
	end
}

mobile_fangzongPS = sgs.CreateProhibitSkill{
	name = "#mobile_fangzong",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		if canCauseDamage(card) and  (not card:isKindOf("SkillCard")) and from:inMyAttackRange(to) and from:objectName() ~= to:objectName() then
			return (from:hasSkill("mobile_fangzong") and from:getMark("@mobile_fangzong_invadity-Clear") == 0 and from:getPhase() == sgs.Player_Play) or 
			  (to:hasSkill("mobile_fangzong") and to:getMark("@mobile_fangzong_invadity-Clear") == 0)
		end
	end
}

mobile_fangzong = sgs.CreateTriggerSkill{
	name = "mobile_fangzong",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local alive_num = room:getAlivePlayers():length()
			local n = alive_num - player:getHandcardNum()
			if n > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(n)
			end
		end
	end,
}

xizhan = sgs.CreateTriggerSkill {
	name = "xizhan",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("xizhan") and p:objectName() ~= player:objectName() then
					local cd = room:askForCard(p, "..", "@xizhan", sgs.QVariant(), self:objectName())
					if cd then
						room:doAnimate(1, p:objectName(), player:objectName())
						room:addPlayerMark(p, "@mobile_fangzong_invadity-Clear")
						if cd:getSuit() == sgs.Card_Spade then
							local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
							analeptic:setSkillName(self:objectName())
							room:useCard(sgs.CardUseStruct(analeptic, player, sgs.SPlayerList()))
						elseif cd:getSuit() == sgs.Card_Club then
							local iron_chain = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_NoSuit, 0)
							iron_chain:setSkillName(self:objectName())
							room:useCard(sgs.CardUseStruct(iron_chain, p, player))
						elseif cd:getSuit() == sgs.Card_Diamond then
							local fire_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
							fire_slash:setSkillName(self:objectName())
							room:useCard(sgs.CardUseStruct(fire_slash, p, player))
						elseif cd:getSuit() == sgs.Card_Heart then
							local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
							ex_nihilo:setSkillName(self:objectName())
							room:useCard(sgs.CardUseStruct(ex_nihilo, p, sgs.SPlayerList()))
						end
					else
						room:loseHp(p,1)
					end
					return false
				end
			end
		end
	end
}

mobile_huaman:addSkill(xiangzhen)
mobile_huaman:addSkill(mobile_fangzong)
mobile_huaman:addSkill(mobile_fangzongPS)
mobile_huaman:addSkill(xizhan)

sgs.LoadTranslationTable{
["mobile_huaman"] = "手殺花鬘",
["&mobile_huaman"] = "花鬘",

["xiangzhen"] = "象陣",
[":xiangzhen"] = "鎖定技,【南蠻入侵】對你無效;【南蠻入侵】結算後,若此牌造成過傷害,你與來源各摸一張牌。",
["mobile_fangzong"] = "芳蹤",
[":mobile_fangzong"] = "鎖定技,出牌階段,你使用傷害類牌不能指定你攻擊範圍內的角色為目標。攻擊範圍內有你的其他角色不能使用傷害類牌指定你為目標。結束階段,你將手牌摸至X張(X為角色數)。",
["xizhan"] = "嬉戰",
[":xizhan"] = "其他角色的回合開始時,你失去1點體力,或棄置一張牌並令「芳蹤」於本回合失效,若此牌為:黑桃,其視為使用【酒】;紅桃,你視為使用【無中生有】,梅花，你視為對其使用【鐵索連環】;方塊，你視為對其使用【火殺】",
["@xizhan"] = "「嬉戰」效果影響，你需棄置一張牌，否則失去一點體力",
}


--[[
孫翊
躁厲：鎖定技,出牌階段,你只能使用或打出本回合獲得的手牌。當你使用或打出手牌時,你獲得1枚「厲」標記(至多有4枚)。回合開始時,你棄置所有「厲」,然後棄置任意張牌,摸X張牌並失去1點體力(X為你棄置「厲」數與棄置牌數之和)
]]--
sunyi = sgs.General(extension, "sunyi", "wu2", "4", true, true)

zaoliPS = sgs.CreateProhibitSkill{
	name = "#zaoliPS",
	frequency =sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return from:hasSkill("zaoli") and from:getPhase() == sgs.Player_Play and from:getMark("fulin"..card:getEffectiveId().."-Clear") == 0
	end
}

zaoliCard = sgs.CreateSkillCard{
	name = "zaoliCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			room:drawCards(source, self:subcardsLength() + source:getMark("@mobile_syli"), "zaoli")
			room:setPlayerMark(source, "@mobile_syli",0)
			room:loseHp(source,1)
		end
	end
}
zaoliVS = sgs.CreateViewAsSkill{
	name = "zaoli",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zaoli_card = zaoliCard:clone()
		for _,card in pairs(cards) do
			zaoli_card:addSubcard(card)
		end
		zaoli_card:setSkillName(self:objectName())
		return zaoli_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@@zaoli"
	end
}

zaoli = sgs.CreateTriggerSkill{
	name = "zaoli",
	view_as_skill = zaoliVS,
	events = {sgs.CardUsed, sgs.CardResponded,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
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
			if card and (not card:isKindOf("SkillCard")) and card:getSkillName() ~= "xiongzhi" and player:getMark("@mobile_syli") < 4 then
				room:addPlayerMark(player , "@mobile_syli")
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			room:askForUseCard(player, "@@zaoli", "@zaoli", -1, sgs.Card_MethodDiscard)
		end
	end
}

sunyi:addSkill(zaoli)
sunyi:addSkill(zaoliPS)

sgs.LoadTranslationTable{
["sunyi"] = "手殺孫翊",
["&sunyi"] = "孫翊",
["#sunyi"] = "驍悍激躁",

["@zaoli"] = "請發動“躁厲”",
["~zaoli"] = "選擇需要棄置的牌→點擊確定",

["zaoli"] = "躁厲",
["#zaoliPS"] = "躁厲",
["@mobile_syli"] = "厲",
[":zaoli"] = "鎖定技,出牌階段,你只能使用或打出本回合獲得的手牌。當你使用或打出手牌時,你獲得1枚「厲」標記(至多有4枚)。回合開始時,你棄置所有「厲」,然後棄置任意張牌,摸X張牌並失去1點體力(X為你棄置「厲」數與棄置牌數之和)",
}

--[[
王雙
擅械：當你受到其他角色「殺」的傷害後,若你裝備區里有武器牌,你可以獲得此【殺】,然後將此牌當普通【殺】對其使用。
異勇：出牌階段限一次,你可從牌堆中獲得一張武器牌(沒有則從場上隨機獲得一張武器牌)，你使用【殺】只能被點數大於X的【閃】 響應(X為你攻擊範圍的兩倍)
]]--
mobile_wangshuang = sgs.General(extension, "mobile_wangshuang", "wei2", "4", true)

shanxie = sgs.CreateTriggerSkill{
	name = "shanxie",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:isAlive() and player:getWeapon() then
			local ids = sgs.IntList()
			if damage.card:isVirtualCard() then
				ids = damage.card:getSubcards()
			else
				ids:append(damage.card:getEffectiveId())
			end
			if ids:isEmpty() then return end
			for _, id in sgs.qlist(ids) do
				if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
			end
			local _data = sgs.QVariant()
			_data:setValue(damage.from)
			if room:askForSkillInvoke(player, self:objectName(), _data) then

				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)

				slash:setSkillName("shanxie")
				for _, id in sgs.qlist(ids) do
					slash:addSubcard( id )
				end
				room:useCard(sgs.CardUseStruct(slash, player , damage.from))
			end
		end
		return false
	end
}

yiyongCard = sgs.CreateSkillCard{
	name = "yiyong",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		
		local GetCardList = sgs.IntList()
		local DPHeart = sgs.IntList()
		if room:getDrawPile():length() > 0 then
			for _, id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("Weapon") then
					DPHeart:append(id)
				end
			end
		end

		if DPHeart:length() == 0 then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getWeapon() then
					DPHeart:append(  p:getWeapon():getEffectiveId() )
				end
			end
		end

		if DPHeart:length() > 0 then
			local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
			GetCardList:append(get_id)
			local card = sgs.Sanguosha:getCard(get_id)
		end

		if GetCardList:length() ~= 0 then
			local move = sgs.CardsMoveStruct()
			move.card_ids = GetCardList
			move.to = source
			move.to_place = sgs.Player_PlaceHand
			room:moveCardsAtomic(move, false)
		end
	end
}
yiyongVS = sgs.CreateZeroCardViewAsSkill{
	name = "yiyong",
	view_as = function(self, cards)
		return yiyongCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#yiyong"))
	end
}

yiyong = sgs.CreateTriggerSkill{
	name = "yiyong",
	view_as_skill = yiyongVS,
	events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)

		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() and use.from:hasSkill(self:objectName()) and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					room:setPlayerMark(p , "yiyong_Play", player:getAttackRange() * 2)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			for _, p in sgs.qlist(use.to) do
				room:setPlayerMark(p, "yiyong_Play", 0)
			end
		end
		return false
	end
}

yiyongPS = sgs.CreateProhibitSkill{
	name = "#yiyongPS",
	frequency =sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return (from:getMark("yiyong_Play") > 0) and card:isKindOf("Jink") and card:getNumber() < from:getMark("yiyong_Play")
	end
}

mobile_wangshuang:addSkill(shanxie)
mobile_wangshuang:addSkill(yiyong)
mobile_wangshuang:addSkill(yiyongPS)

sgs.LoadTranslationTable{
["mobile_wangshuang"] = "手殺王雙",
["&mobile_wangshuang"] = "王雙",
["#mobile_wangshuang"] = "邊城猛兵",

["shanxie"] = "擅械",
[":shanxie"] = "當你受到其他角色「殺」的傷害後,若你裝備區里有武器牌,你可以獲得此【殺】,然後將此牌當普通【殺】對其使用。",

["yiyong"] = "異勇",
["#yiyongPS"] = "異勇",
[":yiyong"] = "出牌階段限一次,你可從牌堆中獲得一張武器牌(沒有則從場上隨機獲得一張武器牌)，你使用【殺】只能被點數大於X的【閃】 響應(X為你攻擊範圍的兩倍)",
}

sgs.Sanguosha:addSkills(skills)



