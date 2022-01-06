module("extensions.yingbian", package.seeall)
extension = sgs.Package("yingbian")
extension_card = sgs.Package("yingbian_card",sgs.Package_CardPack)

sgs.LoadTranslationTable{
	["yingbian"] = "應變",
	["yingbian_card"] = "應變",
}

--[[
張春華 晉 3體力
慧識：摸牌階段，你可以放棄摸牌，改為觀看牌堆頂的X張牌，獲得其中的一半（向下取整），然後將其餘牌置入牌堆底。 
（X為牌堆數量的個位數）
清冷：一名角色的回合結束時，若其體力值與手牌數之和不小於X，你可將一張牌當無距離限制的冰屬性【殺】對其使用。 
（X為牌堆數量的個位數）
宣穆：鎖定技，隱匿技。你於其他角色的回合登場時，防止你受到的傷害直到回合結束。 xuanmu
]]--
local skills = sgs.SkillList()

yb_zhangchunhua = sgs.General(extension,"yb_zhangchunhua","jin","3",false)

function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

huishi = sgs.CreateTriggerSkill{
	name = "huishi" ,
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			if player:askForSkillInvoke(self:objectName()) then
				local count = 0
				data:setValue(count)
				room:setPlayerFlag(player,"huishi_invoke")

				local n = room:getDrawPile():length() % 10
				local card_ids = room:getNCards(n)
				room:fillAG(card_ids)
				local to_get = sgs.IntList()
				for i = 0, n/2 do
					local card_id = room:askForAG(player, card_ids, false, "shelie")
					card_ids:removeOne(card_id)
					to_get:append(card_id)--弃置剩余所有符合花色的牌(原文：throw the rest cards that matches the same suit)
					local card = sgs.Sanguosha:getCard(card_id)
					room:takeAG(player, card_id, false)
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if not to_get:isEmpty() then
					dummy:addSubcards(getCardList(to_get))
					player:obtainCard(dummy)
				end
				dummy:clearSubcards()
				if not card_ids:isEmpty() then
					--dummy:addSubcards(getCardList(to_throw))
					--local n2 = dummy:getSubcards():length()
					local n2 = card_ids:length()
					local move = sgs.CardsMoveStruct(card_ids, player, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), ""))
					room:moveCardsAtomic(move, false)
					local card_ids = room:getNCards(n2)
					room:askForGuanxing(player, card_ids, sgs.Room_GuanxingDownOnly)
				end
				dummy:deleteLater()
				room:clearAG()
			end
		end
	end
}

qingleng = sgs.CreateTriggerSkill{
	name = "qingleng",
	events = {sgs.EventPhaseChanging,sgs.DamageCaused},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:findPlayersBySkillName("qingleng")) do
					local n = room:getDrawPile():length() % 10
					if (player:getHp() + player:getHandcardNum()) >= n and p:canSlash(player, nil, false) then
						local card = room:askForCard(p, ".|.|.|hand", "@qingleng", sgs.QVariant(), sgs.Card_MethodNone)
						if card then
							local slash = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
							slash:addSubcard(card:getEffectiveId())
							slash:setSkillName("qingleng")
							room:useCard(sgs.CardUseStruct(slash, p, player))
							if p:getMark("qingleng"..player:objectName()) == 0 then
								p:drawCards(1)
							end
							room:setPlayerMark(p,"qingleng"..player:objectName(),1)
						end
					end
				end
			end
		elseif event == sgs.DamageCaused and RIGHT(self, player) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("ThunderSlash") and damage.card:getSkillName() == "qingleng" then
				if room:askForSkillInvoke(player, "qingleng_iceslash", data) then
					local log = sgs.LogMessage()
				  	log.from = player
					log.to:append(damage.to)
					log.arg = self:objectName()
					log.type = "#Yishi"
					room:sendLog(log)
					for i = 1,2,1 do
						if not damage.to:isNude() then
							local card = room:askForCardChosen(player, damage.to, "he", self:objectName())
							room:throwCard(card, damage.to, player)
						end
					end
					return true
				end
			end

		end
		return false
	end
}

yb_zhangchunhua:addSkill(huishi)
yb_zhangchunhua:addSkill(qingleng)

sgs.LoadTranslationTable{
	["yb_zhangchunhua"] = "SP張春華",
	["&yb_zhangchunhua"] = "張春華",
	["#yb_zhangchunhua"] = "",
	["huishi"] = "慧識",
	[":huishi"] = "摸牌階段，妳可以放棄摸牌，改為觀看牌堆頂的X張牌，獲得其中的一半（向下取整），然後將其餘牌置入牌堆底。（X為牌堆數量的個位數）",
	["qingleng"] = "清冷",
	[":qingleng"] = "一名角色的回合結束時，若其體力值與手牌數之和不小於X，妳可將一張牌當無距離限制的【雷殺】對其使用，若此【雷殺】造成傷害，妳可以改為棄置其兩張牌；若妳於本局未對該角色發動過「清冷」，妳摸一張牌。 （X為牌堆數量的個位數）",
	["@qingleng"]  = "妳可以將一張牌當殺對其使用",
	["jin"] = "晉",
}

--[[
司馬懿
不臣
隱匿技。你於其他角色的回合登場後，可以獲得當前回合角色的一張牌
鷹視
鎖定技，出牌階段，牌堆頂的X張牌始終對你可見（X為你的體力上限）
雄志
限定技，出牌階段，你可以展示牌堆頂的一張牌，然後你使用此牌。若如此做，重復此流程直到你無法使用。
權變
出牌階段，每當你首次使用/打出一種花色的手牌時，你可以摸一張牌或將牌堆頂X張牌中的一張置入牌堆底。若如此做，你本回合不能再使用/打出這種花色的手牌。（X為你的體力上限）
]]--
yb_simayi = sgs.General(extension,"yb_simayi","jin","3",true)

yb_yingshiCard = sgs.CreateSkillCard{
	name = "yb_yingshi",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local ids = room:getNCards(source:getMaxHp())
		room:fillAG(ids)
		room:getThread():delay()
		room:clearAG()
		room:returnToTopDrawPile(ids)
	end
}

yb_yingshi = sgs.CreateZeroCardViewAsSkill{
	name = "yb_yingshi",
	view_as = function()
		return yb_yingshiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

xiongzhiUseCard = sgs.CreateSkillCard{
	name = "xiongzhiUse",
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

xiongzhiCard = sgs.CreateSkillCard{
	name = "xiongzhi",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local xiongzhi_continue = true
		room:doSuperLightbox("yb_simayi","xiongzhi")
		room:removePlayerMark(source, "@xiongzhi")
		while not source:hasFlag("xiongzhi_continue_fail") do
			local to = source
			local card_ids = room:getNCards(1, false)
			local id = card_ids:first()
			local ids = sgs.IntList()
			ids:append(id)

			room:setCardFlag(id, "xiongzhi")

			room:setPlayerFlag(source, "Fake_Move")
			local _guojia = sgs.SPlayerList()
			_guojia:append(source)
			local move = sgs.CardsMoveStruct(ids, nil, source, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			room:getThread():delay()

			if sgs.Sanguosha:getCard(id):isAvailable(source) and not source:isLocked(sgs.Sanguosha:getCard(id)) then
				if not room:askForUseCard(source, "@@xiongzhi", "@xiongzhi_useCard", -1, sgs.Card_MethodUse) then
					room:setPlayerFlag(source ,"xiongzhi_continue_fail")

					local move_to = sgs.CardsMoveStruct(ids, to, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
					local moves_to = sgs.CardsMoveList()
					moves_to:append(move_to)
					room:notifyMoveCards(true, moves_to, false, _guojia)
					room:notifyMoveCards(false, moves_to, false, _guojia)
					room:setPlayerFlag(to, "-Fake_Move")
					break
				end
			else
				room:setPlayerFlag(source ,"xiongzhi_continue_fail")

				local move_to = sgs.CardsMoveStruct(ids, to, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
				local moves_to = sgs.CardsMoveList()
				moves_to:append(move_to)
				room:notifyMoveCards(true, moves_to, false, _guojia)
				room:notifyMoveCards(false, moves_to, false, _guojia)
				room:setPlayerFlag(to, "-Fake_Move")
			end

			room:setCardFlag(id, "-xiongzhi")
		end
		room:setPlayerFlag(source ,"-xiongzhi_continue_fail")
	end
}

xiongzhiVS = sgs.CreateViewAsSkill{
	n = 1,
	name = "xiongzhi",
	response_pattern = "@@xiongzhi",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@xiongzhi" then
			return to_select:hasFlag(self:objectName())
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@xiongzhi" then
			if #cards ~= 1 then return nil end
			local skillcard = xiongzhiUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
		if #cards ~= 0 then return nil end
		return xiongzhiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@xiongzhi") > 0
	end
}

xiongzhi = sgs.CreateTriggerSkill{
		name = "xiongzhi",
		frequency = sgs.Skill_Limited,
		limit_mark = "@xiongzhi",
		view_as_skill = xiongzhiVS ,
		on_trigger = function() 
		end
}

yb_quanbian = sgs.CreateTriggerSkill{
	name = "yb_quanbian",
	frequency = sgs.Skill_Frequency,
	events = {sgs.CardUsed, sgs.CardResponded,sgs.EventPhaseEnd},
	view_as_skill = yb_quanbianVS,
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
		if card and not card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
			if player:getMark("yb_quanbian_used_"..player:getMark("used_suit_num-Clear") .."-Clear") == 0 then
				local card_ids = room:getNCards(player:getHp())
				room:fillAG(card_ids,player)
				local to_get = sgs.IntList()
				local to_throw = sgs.IntList()

				for i = 0, player:getHp()-1 do--这一句不加的话 涉猎很多牌可能会bug，150可以改，数值越大，越精准，一般和你涉猎的牌数相等是没有bug的
					for _,id in sgs.qlist(card_ids) do
						local c = sgs.Sanguosha:getCard(id)
						if c:getSuit() == card:getSuit() then
							card_ids:removeOne(id)
							to_throw:append(id)
						end
					end
				end


				local card_id = room:askForAG(player, card_ids, false, "shelie")
				card_ids:removeOne(card_id)
				to_get:append(card_id)--弃置剩余所有符合花色的牌(原文：throw the rest cards that matches the same suit)

				for _,id in sgs.qlist(card_ids) do
					to_throw:append(id)
				end

				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if not to_get:isEmpty() then
					dummy:addSubcards(getCardList(to_get))
					player:obtainCard(dummy)
				end
				dummy:clearSubcards()
				if not to_throw:isEmpty() then
					dummy:addSubcards(getCardList(to_throw))
					local move = sgs.CardsMoveStruct(to_throw, player, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), ""))
					room:moveCardsAtomic(move, false)
					local card_ids_put = room:getNCards(to_throw:length())
					room:askForGuanxing(player, card_ids_put, sgs.Room_GuanxingUpOnly)
				end
				dummy:deleteLater()
				room:clearAG()
				room:setPlayerMark(player, "yb_quanbian_used_"..player:getMark("used_suit_num-Clear") .."-Clear", 1)

				if player:getMark("card_used_num_without_equip_Play") == player:getMaxHp() then
					room:setPlayerCardLimitation(player, "use", ".", false)
				end
			end
		end

		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:getMark("yb_quanbian_stop-Clear") ~= 0 then
			room:removePlayerCardLimitation(player, "use", ".")
		end
	end,
}

yb_simayi:addSkill(yb_yingshi)
yb_simayi:addSkill(xiongzhi)
yb_simayi:addSkill(yb_quanbian)

sgs.LoadTranslationTable{
	["yb_simayi"] = "SP司馬懿",
	["&yb_simayi"] = "司馬懿",
	["#yb_simayi"] = "",
	["yb_yingshi"] = "鷹視",
	[":yb_yingshi"] = "鎖定技，出牌階段，牌堆頂的X張牌始終對你可見（X為你的體力上限）",
	["xiongzhi"] = "雄志",
	[":xiongzhi"] = "限定技，出牌階段，你可以展示牌堆頂的一張牌，然後你使用此牌。若如此做，重復此流程直到你無法使用。",
	["@@xiongzhi"] = "你可以使用該牌",
	["~xiongzhi"] = "提示：點選該牌-->選擇目標",
	["yb_quanbian"] = "權變",
	[":yb_quanbian"] = "出牌階段，每當你首次使用/打出一種花色的手牌時，你可以從牌堆頂X張牌中獲得一張花色不同的牌，然後將其他的牌置於牌堆頂。出牌階段，你至多使用X張非裝備牌。（X為你的體力上限）",
}


--[[
王元姬
識人
隱匿技。你於其他角色的回合登場後，若當前回合角色有手牌，可立即對當前回合角色發動一次「宴戲」。
宴戲
出牌階段限一次，你令一名其他角色的隨機一張手牌與牌堆頂的兩張牌混合後展示，你猜測哪張牌來自其手牌。若猜對，你獲得3張牌；若猜錯，你獲得選中的牌。
zhiren
]]--
wangyuanji = sgs.General(extension,"wangyuanji","jin","3", false)

function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

yanxiCard = sgs.CreateSkillCard{
	name = "yanxi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHandcardNum() > 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local ids = room:getNCards(2, false)
			local left = sgs.IntList()
			local getback = sgs.IntList()

			local handids = getIntList(targets[1]:getHandcards())
			local handid = handids:at(math.random(0, handids:length() - 1))
			ids:append(handid)
			local showids = sgs.IntList()
			for i = 1,3,1 do
				local get_id = ids:at(math.random(1, ids:length())-1)
				showids:append(get_id)
				ids:removeOne(get_id)
			end

			room:fillAG(showids,source)
			local id = room:askForAG(source, showids, true, self:objectName())
			room:clearAG()
			if id == handid then
				for _,cid in sgs.qlist(showids) do
					getback:append(cid)
					room:addPlayerMark(source, "yanxi"..cid.."-Clear")
				end
			else
				getback:append(id)
				room:addPlayerMark(source, "yanxi"..id.."-Clear")
				showids:removeOne(id)
				showids:removeOne(handid)
				for _,cid in sgs.qlist(showids) do
					left:append(cid)
				end
			end

			if getback:length() > 0 then
				local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _,cid in sgs.qlist(getback) do
					dummy:addSubcard(cid)
				end
				room:obtainCard( source,dummy, true)
			end
			if left:length() > 0 then
				local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _,cid in sgs.qlist(left) do
					dummy:addSubcard(cid)
				end
				room:throwCard(dummy, nil, nil)
			end
			return true
		end
	end
}
yanxiVS = sgs.CreateZeroCardViewAsSkill{
	name = "yanxi",
	view_as = function(self, card)
		return yanxiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#yanxi")
	end
}

yanxi = sgs.CreateTriggerSkill{
	name = "yanxi",
	view_as_skill = yanxiVS,
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

yanximc = sgs.CreateMaxCardsSkill{
	name = "#yanximc",
	extra_func = function(self, target)
		local x = 0
		if target:hasSkill("yanxi") then
			for _, card in sgs.list(target:getHandcards()) do
				if target:getMark("yanxi"..card:getId().."-Clear") > 0 then
					x = x + 1
				end
			end
			return x
		end
	end
}

wangyuanji:addSkill(yanxi)
wangyuanji:addSkill(yanximc)

sgs.LoadTranslationTable{
	["wangyuanji"] = "王元姬",
	["&wangyuanji"] = "王元姬",
	["#wangyuanji"] = "",
	["yanxi"] = "宴戲",
	[":yanxi"] = "出牌階段限一次，你令一名其他角色的隨機一張手牌與牌堆頂的兩張牌混合後展示，你猜測哪張牌來自其手牌。若猜對，你獲得3張牌；若猜錯，你獲得選中的牌，妳以此法獲得的牌不計入手牌上限。",
}

--[[
夏侯徽
寶篋
隱匿技。你登場後，從牌堆或棄牌堆獲得一張寶物牌並裝備。
宜室
每名角色的回合限一次，每當一名其他角色於其出牌階段棄置手牌後，你可令其獲得其中的一張牌，你獲得其餘牌。
識度
出牌階段限一次，你可與一名其他角色拼點。若你贏，你獲得其所有手牌，然後將你手牌的一半（向下取整）交給其。
]]--
xiahouhui = sgs.General(extension,"xiahouhui","jin","3", false)

yb_yishi = sgs.CreateTriggerSkill{
	name = "yb_yishi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == current:objectName() and current:getPhase() == sgs.Player_Play then
			local ids = sgs.IntList()
			for _,card_id in sgs.qlist(move.card_ids) do
				local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
				if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
					ids:append(card_id)
				end
			end
			if not ids:isEmpty() and player:hasSkill("yb_yishi") then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:fillAG(ids,player)
					local id = room:askForAG(player, ids, true, self:objectName())
					room:clearAG()
					ids:removeOne(id)
					local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcard(id)
					room:obtainCard(current,dummy, true)

					if ids:length() > 0 then
						local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _,cid in sgs.qlist(ids) do
							dummy:addSubcard(cid)
						end
						room:obtainCard( player,dummy, true)
					end
				end
			end
		end
		return false
	end,
}

shiduoCard = sgs.CreateSkillCard{
	name = "shiduo",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHandcardNum() > 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if source:pindian(targets[1], self:objectName(), self) then
				room:obtainCard(source, targets[1]:wholeHandCards(), false)
				local n = source:getHandcardNum()/2
				local prompt1 = string.format("@shiduo:%s", source:objectName())
				local cards = room:askForExchange(source, self:objectName(), n, n, true, "@shiduo", prompt1)
				if cards then
					room:obtainCard(targets[1], cards, false)
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end,
}
shiduo = sgs.CreateOneCardViewAsSkill{
	name = "shiduo",
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local skillcard = shiduoCard:clone()
		skillcard:addSubcard(card:getId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#shiduo") < 1
	end,
}

xiahouhui:addSkill(yb_yishi)
xiahouhui:addSkill(shiduo)

sgs.LoadTranslationTable{
	["xiahouhui"] = "夏侯徽",
	["&xiahouhui"] = "夏侯徽",
	["#xiahouhui"] = "",
	["yb_yishi"] = "宜室",
	[":yb_yishi"] = "每名角色的回合限一次，每當一名其他角色於其出牌階段棄置手牌後，妳可令其獲得其中的一張牌，妳獲得其餘牌。",
	["shiduo"] = "識度",
	[":shiduo"] = "出牌階段限一次，妳可與一名其他角色拼點。若妳贏，妳獲得其所有手牌，然後將妳手牌的一半（向下取整）交給其。",
	["@shiduo"] = "請交给該角色（%src）妳手牌的一半",
}
--[[
張虎樂綝
襲爵
遊戲開始時，你獲得4枚"爵"標記；回合結束時，若你本回合造成了至少2點傷害或殺死至少1名角色，你獲得一枚"爵"。摸牌階段開始時，你可棄置一枚"爵"發動【突襲】，其他角色的結束階段開始時，你可以棄置一枚"爵"發動【驍果】。
]]--
zhanghuyuelin  = sgs.General(extension,"zhanghuyuelin","jin","4", true)

xijue = sgs.CreateTriggerSkill{
	name = "xijue",
	events = {sgs.EventPhaseStart,sgs.DrawNCards,sgs.AfterDrawNCards,sgs.EventPhaseChanging,sgs.GameStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p and p:hasSkill("xijue") and p:getMark("@jue") > 0 then
						if p:canDiscard(p, "h") and room:askForCard(p, ".Basic", "@xiaoguo", sgs.QVariant(), self:objectName()) then
							room:broadcastSkillInvoke(self:objectName(),math.random(5,6))
							room:removePlayerMark(p, "@jue")
							if not room:askForCard(player, ".Equip", "@xiaoguo-discard", sgs.QVariant()) then
								room:damage(sgs.DamageStruct(self:objectName(), p, player))
							else
								p:drawCards(1, self:objectName())
							end
						end
						return false
					end
				end
			end
		elseif event == sgs.DrawNCards and player:hasSkill("xijue") and player:getMark("@jue") > 0 then
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
					room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
					room:notifySkillInvoked(player, self:objectName())
					room:removePlayerMark(player, "@jue")
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
		elseif event == sgs.AfterDrawNCards then
			if player:getMark("tuxi_po") > 0 then
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
		elseif event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_Finish and player:hasSkill("xijue") and player:getMark("damage_record-Clear") > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
				player:gainMark("@jue",player:getMark("damage_record-Clear"))
			end
		elseif event == sgs.GameStart and RIGHT(self, player) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
			player:gainMark("@jue",4)
		end
	end
}

zhanghuyuelin:addSkill(xijue)

sgs.LoadTranslationTable{
	["zhanghuyuelin"] = "張虎樂綝",
	["&zhanghuyuelin"] = "張虎樂綝",
	["#zhanghuyuelin"] = "",
	["xijue"] = "襲爵",
	[":xijue"] = "遊戲開始時，你獲得4枚「爵」標記；回合結束時，若你本回合造成1點傷害，你便獲得一枚「爵」。摸牌階段開始時，你可棄置一枚「爵」發動【突襲】，其他角色的結束階段開始時，你可以棄置一枚「爵」發動【驍果】。",
	["@jue"] = "爵",
}

--[[
杜預
三陳
出牌階段限一次，你可令一名角色摸3張牌，然後棄置3張牌。若其以此法棄置的牌種類均不同，則其摸一張牌，並視為該技能未發動過(本回合不能再指定其為目標)。
詔討
覺醒技，回合開始時，若你本局遊戲發動過至少3次「三陳」，你減一點體力上限，獲得「破竹」。
破竹
出牌階段，你可棄置一張手牌並展示其他角色的一張手牌，若花色：不同，此技能無效直到回合結束；相同，你對其造成1點傷害。
]]--
duyu = sgs.General(extension,"duyu","jin","4", true)

sanchenCard = sgs.CreateSkillCard{
	name = "sanchen",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("sanchen_target-Clear") == 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			targets[1]:drawCards(3, self:objectName())
			local sanchen_throw_cards = room:askForExchange(targets[1], self:objectName(), 3, 3, true, "sanchenDiscard")
			room:throwCard(sanchen_throw_cards, targets[1], nil)
			local types = {}
			for _,id in sgs.qlist(sanchen_throw_cards:getSubcards()) do
				if not table.contains(types, sgs.Sanguosha:getCard(id):getTypeId()) then
					table.insert(types, sgs.Sanguosha:getCard(id):getTypeId())
				end
			end
			room:setPlayerMark(targets[1],"sanchen_target-Clear",1)
			room:addPlayerMark(source,"@sanchen_used_time")
			if #types == 3 then
				source:drawCards(1)
				room:addPlayerHistory(zhouyu, "#sanchen",-1)
			end
		end
	end
}
sanchen = sgs.CreateZeroCardViewAsSkill{
	name = "sanchen",
	view_as = function(self, card)
		return sanchenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#sanchen"))
	end
}

zhaotao = sgs.CreateTriggerSkill{
	name = "zhaotao",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getMark("@sanchen_used_time") >= 3 or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) then
			room:addPlayerMark(player, "zhaotao")
			if room:changeMaxHpForAwakenSkill(player) then
				room:broadcastSkillInvoke(self:objectName())
				local msg = sgs.LogMessage()
				msg.type = "#ZhaotaoWake"
				msg.from = player
				msg.to:append(player)
				msg.arg = player:getMark("@sanchen_used_time")
				msg.arg2 = self:objectName()
				room:sendLog(msg)

				room:doSuperLightbox("duyu","zhaotao")
				room:acquireSkill(player, "pozhu")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("zhaotao")
				and target:isAlive()
				and (target:getMark("zhaotao") == 0)
	end
}

function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

pozhuCard = sgs.CreateSkillCard{
	name = "pozhu",
	will_throw = true,
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local ids = getIntList(targets[1]:getHandcards())
			local id = ids:at(math.random(0, ids:length() - 1))
			room:showCard(targets[1], id)

			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit() then
				room:setPlayerMark(source,"pozhu_can_not_use-Clear",1)
			else
				room:damage(sgs.DamageStruct("pozhu", source, targets[1]))
				room:addPlayerHistory(zhouyu, "#pozhu",-1)
			end
		end
	end
}
pozhu = sgs.CreateOneCardViewAsSkill{
	name = "pozhu",
	filter_pattern = ".",
	view_as = function(self, card)
		local skill_card = pozhuCard:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#pozhu"))
	end
}

if not sgs.Sanguosha:getSkill("pozhu") then skills:append(pozhu) end

duyu:addSkill(sanchen)
duyu:addSkill(zhaotao)
duyu:addRelateSkill("pozhu")

sgs.LoadTranslationTable{
	["duyu"] = "杜預",
	[":duyu"] = "",
	["sanchen"] = "三陳",
	[":sanchen"] = "出牌階段限一次，你可令一名角色摸3張牌，然後棄置3張牌。若其以此法棄置的牌種類均不同，則其摸一張牌，並視為該技能未發動過(本回合不能再指定其為目標)。", 
	["zhaotao"] = "詔討",
	[":zhaotao"] = "覺醒技，回合開始時，若你本局遊戲發動過至少3次「三陳」，你減一點體力上限，獲得「破竹」。",
	["pozhu"] = "破竹",
	[":pozhu"] = "出牌階段，你可棄置一張手牌並展示其他角色的一張手牌，若花色：不同，此技能無效直到回合結束；相同，你對其造成1點傷害。",
	["#ZhaotaoWake"] = "%from 發動「三陳」的次數達到 %arg 次，觸發“%arg2”覺醒",
	["sanchenDiscard"] = "請棄置3張牌，若你棄置的類型不同，技能發起者可以再發動「三陳」",

}

--[[
司馬師
韜隱
隱匿技。你於其他角色的回合登場後，可令當前回合角色手牌上限-2直到回合結束。
夷滅
每名角色的回合限一次，你對其他角色造成傷害時（同竭緣），你可失去1點體力值，令此傷害增加X點（X為其體力值-本次傷害值，如果為X=0則不提示發動），傷害結算後，該角色回復X點體力。
睿略
主公技，其他晉勢力角色的出牌階段限一次，該角色可以將一張【殺】或傷害錦囊交給你。
泰然
鎖定技，回合結束時，你將體力回復至上限，將手牌補至上限；出牌階段開始時，你失去上回合結束時以此法恢復的體力值，棄置你上回合結束時以此法獲得的手牌。
]]--
yb_simashi = sgs.General(extension,"yb_simashi","jin","4", true)

yimie = sgs.CreateTriggerSkill{
	name = "yimie" ,
	events = {sgs.DamageCaused, sgs.DamageComplete} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.to and damage.to:isAlive() and damage.to:objectName() ~= player:objectName() then
				local n = damage.to:getHp() - damage.damage
				if n > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:loseHp(player,1)
						room:broadcastSkillInvoke(self:objectName())
						room:notifySkillInvoked(player, self:objectName())
						room:setPlayerMark(damage.to,"yimie-recover",n)
						damage.damage = damage.to:getHp()
						local msg = sgs.LogMessage()
						msg.type = "#YimieIncrease"
						msg.from = player
						msg.to:append(player)
						msg.arg = tostring(damage.damage - n)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and damage.to:getMark("yimie-recover") > 0 then
				room:recover(damage.to, sgs.RecoverStruct(damage.to, nil, damage.to:getMark("yimie-recover")))
			end
		end
		return false
	end
}

tairan = sgs.CreateTriggerSkill{
	name = "tairan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local n = player:getMaxHp() - player:getHp()
				if n > 0 then
					room:recover(player, sgs.RecoverStruct(player, nil, n ))
					room:setPlayerMark(player,"tairan_recover",n)
				end
				local m = player:getMaxCards() - player:getHandcardNum()
				if m > 0 then
					player:drawCards(m, self:objectName())
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, card in sgs.list(player:getHandcards()) do
					if player:getMark(self:objectName()..card:getEffectiveId()) > 0 then
						dummy:addSubcard(card:getEffectiveId())
					end
				end
				if dummy:subcardsLength() > 0 then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil), player)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end

				if player:getMark("tairan_recover") > 0 then
					room:loseHp(player, player:getMark("tairan_recover"))
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and not move.card_ids:isEmpty() and move.reason.m_skillName == "tairan" then
				for _, id in sgs.qlist(move.card_ids) do
					room:addPlayerMark(player, "tairan"..id)
				end
			end
		end
	end,
}

yb_simashi:addSkill(yimie)
yb_simashi:addSkill(tairan)

sgs.LoadTranslationTable{
	["yb_simashi"] = "司馬師",
	["&yb_simashi"] = "司馬師",
	["#yb_simashi"] = "",
	["illustrator:yb_simashi"] = "紫喬",
	["yimie"] = "夷滅",
	[":yimie"] = "每名角色的回合限一次，你對其他角色造成傷害時（同竭緣），你可失去1點體力值，令此傷害增加X點（X為其體力值-本次傷害值，如果為X=0則不提示發動），傷害結算後，該角色回復X點體力。",

	["tairan"] = "泰然",
	[":tairan"] = "鎖定技，回合結束時，你將體力回復至上限，將手牌補至上限；出牌階段開始時，你失去上回合結束時以此法恢復的體力值，棄置你上回合結束時以此法獲得的手牌。",

	["#YimieIncrease"] = "%from 發動了“<font color=\"yellow\"><b>夷滅</b></font>”，傷害點數從 %arg 點增加至 %arg2 點" ,
}

--[[
司馬昭
推弒
隱匿技。若你於其他角色的回合登場，此回合結束時，你可令其對其攻擊範圍內，你選擇的一名角色使用【殺】，若其未使用【殺】，你對其造成1點傷害。
籌伐
出牌階段限一次，你可展示一名其他角色的一張手牌，其手牌中與此牌不同類型的牌均視為殺直到其回合結束。
昭然
出牌階段開始時，你可令你的手牌對所有角色可見直到此階段結束。若如此做，你於出牌階段失去任意花色的最後一張手牌時，摸一張牌或棄置一名其他角色的一張牌。(每種花色限一次)
成務
主公技，鎖定技，其他晉勢力角色攻擊範圍內的角色均視為在你的攻擊範圍內。chengwu
]]--
yb_simazhao = sgs.General(extension,"yb_simazhao","jin","4", true)

choufaCard = sgs.CreateSkillCard{
	name = "choufa" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)	
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local id = room:askForCardChosen(source, targets[1], "h", self:objectName())
			if id ~= -1 then
				room:showCard(targets[1], id)

				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:hasSkill("#choufa_filter") then
						room:acquireSkill(p, "#choufa_filter")
					end
				end


				for _, card in sgs.qlist(targets[1]:getHandcards()) do
					if card:getTypeId() ~= sgs.Sanguosha:getCard(id):getTypeId() then
						room:addPlayerMark(targets[1], "choufa"..card:getEffectiveId().."_flag" )
					end
				end
				room:filterCards(targets[1], targets[1]:getCards("h"), true)

				local being_show_cards = {}
				for _, c in sgs.qlist(targets[1]:getHandcards()) do
					if targets[1]:getMark("choufa"..c:getEffectiveId().."_flag") > 0 then
						table.insert(being_show_cards, c:getEffectiveId())
					end
				end
				if #being_show_cards > 0 then				
					local show_card_log = sgs.LogMessage()
					show_card_log.type = "$choufa"
					show_card_log.from = targets[1]
					show_card_log.to:append(targets[1])
					show_card_log.card_str = table.concat(being_show_cards, "+")
					show_card_log.arg = "choufa"
					room:sendLog(show_card_log, targets[1])
				end

			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

choufa = sgs.CreateZeroCardViewAsSkill{
	name = "choufa",
	view_as = function(self,cards)
		return choufaCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#choufa") < 1
	end
}

choufa_filter = sgs.CreateFilterSkill{
	name = "#choufa_filter",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		return room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
	end,
	view_as = function(self, originalCard)
		local room = sgs.Sanguosha:currentRoom()
		local id = originalCard:getEffectiveId()
		local player = room:getCardOwner(id)
		if player:getMark("choufa"..id.."_flag") > 0 then
			local peach = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			peach:setSkillName("choufa_filter")
			local card = sgs.Sanguosha:getWrappedCard(id)
			card:takeOver(peach)
			return card
		else
			return originalCard
		end
	end
}


choufa_notify = sgs.CreateTriggerSkill{
	name = "choufa_notify",  
	frequency = sgs.Skill_Compulsory, 
	--events = {sgs.EventPhaseChanging},
	events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.Death,sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded,sgs.CardFinished},
	global =true,
	on_trigger = function(self, event, player, data,room) 
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive or change.to == sgs.Player_RoundStart then
				if not player:isKongcheng() then
					room:filterCards(player, player:getCards("h"), true)
					local being_show_cards = {}
					for _, c in sgs.qlist(player:getHandcards()) do
						if player:getMark("choufa"..c:getEffectiveId().."_flag") > 0 then
							table.insert(being_show_cards, c:getEffectiveId())
						end
					end
					if #being_show_cards > 0 then				
						local show_card_log = sgs.LogMessage()
						show_card_log.type = "$choufa"
						show_card_log.from = player
						show_card_log.to:append(player)
						show_card_log.card_str = table.concat(being_show_cards, "+")
						show_card_log.arg = "choufa"
						room:sendLog(show_card_log, player)
					end
				end
			end	
		end
	end,
}

if not sgs.Sanguosha:getSkill("choufa_notify") then skills:append(choufa_notify) end
if not sgs.Sanguosha:getSkill("#choufa_filter") then skills:append(choufa_filter) end


zhaoran = sgs.CreateTriggerSkill{
	name = "zhaoran",
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if player:askForSkillInvoke(self:objectName(),data) then
					room:setPlayerMark(player,"zhaoran_invoke-Clear",1)
					room:showAllCards(player)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_Play and player:getMark("zhaoran_invoke-Clear") > 0 and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
				if player:getHandcardNum() >  0 then
					room:showAllCards(player)
					room:getThread():delay()
					room:clearAG()
				end
				for _,fid in sgs.qlist(move.card_ids) do
					local can_zhaoran = true
					for _, card in sgs.qlist(player:getHandcards()) do
						if card:getSuit() == sgs.Sanguosha:getCard(fid):getSuit() then
							can_zhaoran = false
							break
						end
					end
					if can_zhaoran and player:getMark("zhaoran_suit"..sgs.Sanguosha:getCard(fid):getSuit().."-Clear") == 0 then
						room:notifySkillInvoked(player,"zhaoran")
						room:broadcastSkillInvoke("zhaoran")
						room:setPlayerMark(player, "zhaoran_suit"..sgs.Sanguosha:getCard(fid):getSuit().."-Clear", 1)

						local _targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if player:canDiscard(p, "he") then _targets:append(p) end
						end
						if not _targets:isEmpty() then
							local to_discard = room:askForPlayerChosen(player, _targets, "zhaoran", "@zhaoran-discard", true)
							if to_discard then
								room:broadcastSkillInvoke(self:objectName(), 2)
								room:doAnimate(1, player:objectName(), to_discard:objectName())
								room:throwCard(room:askForCardChosen(player, to_discard, "he", "zhaoran", false, sgs.Card_MethodDiscard), to_discard, player)
							else
								player:drawCards(1)
							end
						else
							player:drawCards(1)
						end
					end
				end
			end
		end	
		return false
	end
}

yb_simazhao:addSkill(choufa)
yb_simazhao:addSkill(zhaoran)

sgs.LoadTranslationTable{
	["yb_simazhao"] = "司馬昭",
	["#yb_simazhao"] = "",
	["choufa"] = "籌伐",
	[":choufa"] = "出牌階段限一次，你可展示一名其他角色的一張手牌，其手牌中與此牌不同類型的牌均視為殺直到其回合結束。",
	["choufa_basic"] = "籌伐",
	["choufa_trick"] = "籌伐",
	["choufa_equip"] = "籌伐",
	[":choufa_basic"] = "鎖定技，你的錦囊牌與裝備牌均視為殺直到你的回合結束",
	[":choufa_trick"] = "鎖定技，你的基本牌與裝備牌均視為殺直到你的回合結束",
	[":choufa_equip"] = "鎖定技，你的基本牌與錦囊牌均視為殺直到你的回合結束",
	["zhaoran"] = "昭然",
	[":zhaoran"] = "出牌階段開始時，你可令你的手牌對所有角色可見直到此階段結束。若如此做，你於出牌階段失去任意花色的最後一張手牌時，摸一張牌或棄置一名其他角色的一張牌。(每種花色限一次)",
	["choufa_filter"] = "籌伐",
	["@zhaoran-discard"] = "請選擇一名角色，你棄置其一張牌，否則你摸一張牌",
		["$choufa"] = "因 %arg 效果影響， %from 的手牌 %card 均視為【殺】",
}

--OL李肅
ol_lisu = sgs.General(extension,"ol_lisu","qun2","3",true)

qiaoyan = sgs.CreateTriggerSkill{
	name = "qiaoyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:getPhase() == sgs.Player_NotActive and damage.from and damage.from:isAlive()
			 and damage.from:objectName() ~= player:objectName() and damage.to and
			  damage.to:objectName() == player:objectName() then

				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				if player:getPile("qy_ball"):length() > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(player:getPile("qy_ball"))
					room:obtainCard(damage.from, dummy, false)

				else

					local msg = sgs.LogMessage()
					msg.type = "#QiaoyanProtect"
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
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:removePlayerMark(player, self:objectName().."engine")
						player:drawCards(1)
						local tuifeng_card = room:askForExchange(player, self:objectName(), 1, 1, false, "qiaoyan-invoke", true)
						local id = -1
						if tuifeng_card then
							id = tuifeng_card:getSubcards():first()
						end
						if id ~= -1 then
							player:addToPile("qy_ball", id, false)
						end
						return true
					end
				end
			end
		end
	end
}

xianzhu = sgs.CreateTriggerSkill{
	name = "xianzhu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:getPile("qy_ball"):length() > 0 then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "xianzhu-invoke", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(player:getPile("qy_ball"))
				room:obtainCard(target, dummy, false)
	
				if target:objectName() ~= player:objectName() then
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:canSlash(p, nil, false) and player:inMyAttackRange(p) then
							players:append(p)
						end
					end
					room:setPlayerFlag(player,"xianzhu_slash_flag")
					local pp = room:askForPlayerChosen(player, players, self:objectName(), "xianzhu-slash_target", true, true)
					if pp then
						room:doAnimate(1, target:objectName(), pp:objectName())
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("_xianzhu")
						room:useCard(sgs.CardUseStruct(slash, target, pp))
					end
					room:setPlayerFlag(player,"-xianzhu_slash_flag")
				end
			else
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(player:getPile("qy_ball"))
				room:obtainCard(target, dummy, false)
				room:obtainCard(player, dummy, false)
			end
		end
		return false
	end
}

ol_lisu:addSkill(qiaoyan)
ol_lisu:addSkill(xianzhu)

sgs.LoadTranslationTable{
	["ol_lisu"] = "OL李肅",
	["&ol_lisu"] = "李肅",
	["#ol_lisu"] = "",
	["qiaoyan"] = "巧言",
	[":qiaoyan"] = "鎖定技，當其他角色於你的回合外對你造成傷害時，若你：沒有「珠」，你防止此傷害，摸一張牌，然後將一張牌明置於武將牌上，稱為「珠」；有「珠」，其獲得「珠」。",
	["qiaoyan-invoke"] = "將一張牌明置於武將牌上，稱為「珠」",
	["#QiaoyanProtect"] = "%from 的「<font color=\"yellow\"><b>巧言</b></font>」效果被觸發，防止了 %arg 點傷害[%arg2]",
	["qy_ball"] = "珠",

	["xianzhu"] = "獻珠" ,
	[":xianzhu"] = "鎖定技，出牌階段開始時，你令一名角色獲得「珠」。若該角色不是你，其視為對你攻擊範圍內你指定的一名角色使用一張【殺】。",

	["xianzhu-invoke"] = "令一名角色獲得「珠」",
	[":xianzhu-slash_target"] = "其視為對你攻擊範圍內你指定的一名角色使用一張【殺】",
}


--石苞
shibao = sgs.General(extension,"shibao","jin","4",true)

zhuosheng = sgs.CreateTriggerSkill{
	name = "zhuosheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed,sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			--[[
			local move_card_can_zhuosheng = false
			for _,id in sgs.qlist(use.card:getSubcards()) do
				if player:getMark("zhuosheng_"..id.."_lun" ) > 0 then
					move_card_can_zhuosheng = true
				end
			end

			if move_card_can_zhuosheng then
			]]--
			if player:getMark("zhuosheng_"..use.card:getEffectiveId().."_lun" ) > 0 then
				if use.card:isKindOf("BasicCard") and (use.card:isKindOf("Slash") or use.card:isKindOf("Analeptic")) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
				elseif use.card:isNDTrick() and (not use.card:isKindOf("Collateral")) then
					if (sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY) then return false end
					local available_targets = sgs.SPlayerList()
					if (not use.card:isKindOf("AOE")) and (not use.card:isKindOf("GlobalEffect")) then
						room:setPlayerFlag(player, "zhuoshengExtraTarget")
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
						room:setPlayerFlag(player, "-zhuoshengExtraTarget")
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
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						local extra = nil
						extra = room:askForPlayerChosen(player, available_targets, "qiaoshui", "@qiaoshui-add:::" .. use.card:objectName())
						if extra then
							room:doAnimate(1, player:objectName(), extra:objectName())
							use.to:append(extra)
						end
						room:sortByActionOrder(use.to)
					else
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						local removed = room:askForPlayerChosen(player, use.to, "qiaoshui", "@qiaoshui-remove:::" .. use.card:objectName())
						room:doAnimate(1, player:objectName(), removed:objectName())
						use.to:removeOne(removed)
					end
					data:setValue(use)
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			--[[
			local move_card_can_zhuosheng = false
			for _,id in sgs.qlist(cards:getSubcards()) do
				if player:getMark("zhuosheng_"..id.."_lun" ) > 0 then
					move_card_can_zhuosheng = true
				end
			end
			if move_card_can_zhuosheng then
			]]--
			if player:getMark("zhuosheng_"..use.card:getEffectiveId().."_lun" ) > 0 then
				if use.card:isKindOf("EquipCard") then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
				end
			end
		end
	end
}

zhuoshengtm = sgs.CreateTargetModSkill{
	name = "#zhuoshengtm",
	pattern = ".",
	residue_func = function(self, from, card)
		local n = 0
		if card:isKindOf("BasicCard") and from:hasSkill("zhuosheng") and from:getMark("zhuosheng_"..card:getEffectiveId().."_lun" ) > 0 then
			n = n + 1000
		end
		return n
	end,
	distance_limit_func = function(self, from, card)
		local n = 0
		if card:isKindOf("BasicCard") and from:hasSkill("zhuosheng") and from:getMark("zhuosheng_"..card:getEffectiveId().."_lun" ) > 0 then
			n = n + 1000
		end
		if (from:hasFlag("zhuoshengExtraTarget")) then
			n = n + 1000
		end
		return n
	end
}

shibao:addSkill(zhuosheng)
shibao:addSkill(zhuoshengtm)

sgs.LoadTranslationTable{
["shibao"] = "石苞",
["zhuosheng"] = "擢升",
[":zhuosheng"] = "出牌階段，①你使用本輪內獲得的基本牌時無次數和距離限制。②你使用本輪內獲得的普通錦囊牌選擇目標後，可令此牌的目標數+1或-1。③你使用本輪內獲得的裝備牌時可以摸一張牌（以此法獲得的牌不能觸發〖擢升〗）。",
}
--晉羊徽瑜
jin_yanghuiyu = sgs.General(extension,"jin_yanghuiyu","jin","3",false)
--慈威
ciwei = sgs.CreateTriggerSkill{
	name = "ciwei" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:getMark("card_used_num_Play") == 2 and (not use.card:isKindOf("SkillCard")) and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					local _data = sgs.QVariant()
					_data:setValue(player)
					if p:canDiscard(p, "h") and room:askForCard(p, "..", "@ciwei", _data, self:objectName()) then	
						room:broadcastSkillInvoke(self:objectName())
						if player:isAlive() then
							local nullified_list = use.nullified_list
							for _, pp in sgs.qlist(use.to) do
								table.insert(nullified_list, pp:objectName())
							end
							use.nullified_list = nullified_list
							data:setValue(use)	
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

caiyuan = sgs.CreateTriggerSkill{
	name = "caiyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Damaged, sgs.HpLost},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark("@caiyuan") == 0 and player:getMark("turn") > 1 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(2)
				end
				room:setPlayerMark(player,"@caiyuan",0)
			end
		elseif event == sgs.Damaged or event == sgs.HpLost then
			local int = 0
			if data:toDamage() and data:toDamage().damage > 0 then
				int = data:toDamage().damage
			elseif data:toInt() > 0 then
				int = data:toInt()
			end
			if int > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:addPlayerMark(player,"@caiyuan")
			end
		end
	end
}

jin_yanghuiyu:addSkill(ciwei)
jin_yanghuiyu:addSkill(caiyuan)

sgs.LoadTranslationTable{
["jin_yanghuiyu"] = "晉羊徽瑜",
["&jin_yanghuiyu"] = "羊徽瑜",
["huirong"] = "慧容",
[":huirong"] = "隱匿技，鎖定技。當你登場後，你令一名角色將手牌數摸至/棄至與體力值相同（至多摸至五張）。",
["ciwei"] = "慈威",
[":ciwei"] = "一名角色於其回合內使用第二張牌時，若此牌為基本牌或普通錦囊牌，則你可以棄置一張牌，取消此牌的所有目標。",
["@ciwei"] = "你可以棄置一張牌，取消此牌的所有目標",
["caiyuan"] = "才媛",
[":caiyuan"] = "鎖定技，當你扣減體力時，你獲得一枚「才媛」標記直到你的下回合結束。結束階段開始時，若你沒有「才媛」標記且此回合不是你的第一個回合，則你摸兩張牌。",
}

--司馬伷
simazhou = sgs.General(extension,"simazhou","jin","3",true)

--才望
caiwang = sgs.CreateTriggerSkill{
	name = "caiwang",
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
					room:setTag("caiwangData", data)
				end
				if use.card:isKindOf("Nullification") then
					local older_data = room:getTag("caiwangData")
					local older_use = older_data:toCardUse()

					card = older_use.card
					ob = use.card
					to = older_use.from

				end
			else
				if room:getTag("caiwangData") then
					local res = data:toCardResponse()
					local older_data = room:getTag("caiwangData")
					local older_use = older_data:toCardUse()

					card = older_use.card
					ob = res.m_card
					to = older_use.from
				end
			end
			if card then
				--你使用的卡牌被響應

				--if all_place_table and (event ~= sgs.CardResponded or p:objectName() == to:objectName()) and player:objectName() ~= p:objectName() and p:getMark(p:objectName().."_xuezong-Clear") > 0 and room:askForSkillInvoke(p, self:objectName(), data) then
				if (event ~= sgs.CardResponded or p:objectName() == to:objectName()) and player:objectName() ~= p:objectName() and p:getMark(p:objectName().."_xuezong-Clear") > 0 and p:canDiscard(player,"he") and GetColor(card) == GetColor(ob) then
					local _data = sgs.QVariant()
					_data:setValue(player)
					if room:askForSkillInvoke(p, self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							if p:getMark("caiwang"..player:objectName().."_start") > 0 then
								local to_throw = room:askForCardChosen(p, player, "he", "caiwang", false, sgs.Card_MethodDiscard)
								room:obtainCard(p,sgs.Sanguosha:getCard(to_throw) )

							else
								local to_throw = room:askForCardChosen(p, player, "he", "caiwang", false, sgs.Card_MethodDiscard)
								room:throwCard(sgs.Sanguosha:getCard(to_throw), player,p)
							end
							room:removePlayerMark(p, self:objectName().."engine")
						end
					end
				end
				--你響應使用的卡牌
				if to and player:objectName() == p:objectName() and p:getMark("sk_jinglun-Clear") == 0 and player:canDiscard(to,"he") and GetColor(card) == GetColor(ob) then
					local _data = sgs.QVariant()
					_data:setValue(to)
					if room:askForSkillInvoke(player, self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							if player:getMark("caiwang"..to:objectName().."_start") > 0 then
								local to_throw = room:askForCardChosen(player, to, "he", "caiwang", false, sgs.Card_MethodDiscard)
								room:obtainCard(player,sgs.Sanguosha:getCard(to_throw) )

							else
								local to_throw = room:askForCardChosen(player, to, "he", "caiwang", false, sgs.Card_MethodDiscard)
								room:throwCard(sgs.Sanguosha:getCard(to_throw),to ,player)
							end
							room:removePlayerMark(player, self:objectName().."engine")
						end
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

naxiang = sgs.CreateTriggerSkill{
	name = "naxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local dest = damage.to
		if damage.from and damage.to then
			if damage.from:objectName() == player:objectName() then
				source = player
				dest = damage.to
			else
				source = player
				dest = damage.from
			end				
			if source and dest and source:getMark("caiwang"..dest:objectName().."_start") == 0 then
				room:notifySkillInvoked(source, self:objectName())
				room:sendCompulsoryTriggerLog(source, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(source,"caiwang"..dest:objectName().."_start")
			end
		end
		return false
	end
}

simazhou:addSkill(caiwang)
simazhou:addSkill(naxiang)

sgs.LoadTranslationTable{
["simazhou"] = "司馬伷",
["caiwang"] = "才望",
[":caiwang"] = "當你使用或打出牌響應其他角色使用的牌，或其他角色使用或打出牌響應你使用的牌後，若這兩張牌顏色相同，則你可以棄置對方的一張牌。",
["naxiang"] = "納降",
[":naxiang"] = "鎖定技，當你受到其他角色造成的傷害後，或你對其他角色造成傷害後，你對其發動〖才望〗時的「棄置」改為「獲得」直到你的下回合開始。",
}

--徹里吉
cheliji = sgs.General(extension,"cheliji","qun2","4",true)

sichengliangyu = sgs.CreateTreasure{
	name = "sichengliangyu",
	class_name = "sichengliangyu",
	suit = sgs.Card_Club,
	number = 4,
	on_install = function(self,player)
		local room = player:getRoom()
	end
}

tiejixuanyu = sgs.CreateTreasure{
	name = "tiejixuanyu",
	class_name = "tiejixuanyu",
	suit = sgs.Card_Club,
	number = 4,
	on_install = function(self,player)
		local room = player:getRoom()
	end
}

feilunzhanyu = sgs.CreateTreasure{
	name = "feilunzhanyu",
	class_name = "feilunzhanyu",
	suit = sgs.Card_Club,
	number = 4,
	on_install = function(self,player)
		local room = player:getRoom()
	end
}

sichengliangyu:setParent(extension)
tiejixuanyu:setParent(extension)
feilunzhanyu:setParent(extension)

--車懸

chexuanCard = sgs.CreateSkillCard{
	name = "chexuan",
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {}
		if room:getTag("SCLY_ID"):toInt() > 0 and source:getMark("hasequip_SCLY") == 0 then
			table.insert(choices, "sichengliangyu")
		end
		if room:getTag("TJXY_ID"):toInt() > 0 and source:getMark("hasequip_TJXY") == 0 then
			table.insert(choices, "tiejixuanyu")
		end
		if room:getTag("FLZY_ID"):toInt() > 0 and source:getMark("hasequip_FLZY") == 0 then
			table.insert(choices, "feilunzhanyu")
		end
		if #choices > 0 then
			local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))

			if choice == "sichengliangyu" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_SCLY",1)
				end
				local id = room:getTag("SCLY_ID"):toInt()
				--local getcard = sgs.Sanguosha:getCard(room:getTag("SCLY_ID"):toInt())
				local move = sgs.CardsMoveStruct(id, nil, source, room:getCardPlace(id), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move, false)
			end
			if choice == "tiejixuanyu" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_TJXY",1)
				end
				local id = room:getTag("TJXY_ID"):toInt()
				--local getcard = sgs.Sanguosha:getCard(room:getTag("TJXY_ID"):toInt())
				local move = sgs.CardsMoveStruct(id, nil, source, room:getCardPlace(id), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move, false)
			end
			if choice == "feilunzhanyu" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_FLZY",1)
				end
				local id = room:getTag("FLZY_ID"):toInt()
				--local getcard = sgs.Sanguosha:getCard(room:getTag("FLZY_ID"):toInt())
				local move = sgs.CardsMoveStruct(id, nil, source, room:getCardPlace(id), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move, false)
			end
		end
	end
}
chexuanVS = sgs.CreateOneCardViewAsSkill{
	name = "chexuan",	
	filter_pattern = ".|black!",
	view_as = function(self, card)
		local chexuan_card = chexuanCard:clone()
		chexuan_card:addSubcard(card)
		chexuan_card:setSkillName(self:objectName())
		return chexuan_card
	end,
	enabled_at_play = function(self, player)
		return (not player:getTreasure())
	end
} 

chexuan = sgs.CreateTriggerSkill{
	name = "chexuan" ,
	view_as_skill = chexuanVS,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				local card_id = move.card_ids:at(i)
				if move.from_places:at(i) == sgs.Player_PlaceEquip and sgs.Sanguosha:getCard(card_id):isKindOf("Treasure") then
					if room:askForSkillInvoke(player, self:objectName()) then
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|black"
						judge.who = player
						judge.reason = self:objectName()
						judge.good = true
						room:judge(judge)
						if judge:isGood() then
							local choices = {}
							if room:getTag("SCLY_ID"):toInt() > 0 and player:getMark("hasequip_SCLY") == 0 then
								table.insert(choices, "sichengliangyu")
							end
							if room:getTag("TJXY_ID"):toInt() > 0 and player:getMark("hasequip_TJXY") == 0 then
								table.insert(choices, "tiejixuanyu")
							end
							if room:getTag("FLZY_ID"):toInt() > 0 and player:getMark("hasequip_FLZY") == 0 then
								table.insert(choices, "feilunzhanyu")
							end
							if #choices > 0 then
								local choice = choices[math.random(1,#choices)]

								if choice == "sichengliangyu" then
									for _, p in sgs.qlist(room:getAlivePlayers()) do
										room:setPlayerMark(p,"hasequip_SCLY",1)
									end
									local id = room:getTag("SCLY_ID"):toInt()
									--local getcard = sgs.Sanguosha:getCard(room:getTag("SCLY_ID"):toInt())
									local move = sgs.CardsMoveStruct(id, nil, player, room:getCardPlace(id), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
									room:moveCardsAtomic(move, false)
								end
								if choice == "tiejixuanyu" then
									for _, p in sgs.qlist(room:getAlivePlayers()) do
										room:setPlayerMark(p,"hasequip_TJXY",1)
									end
									local id = room:getTag("TJXY_ID"):toInt()
									--local getcard = sgs.Sanguosha:getCard(room:getTag("TJXY_ID"):toInt())
									local move = sgs.CardsMoveStruct(id, nil, player, room:getCardPlace(id), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
									room:moveCardsAtomic(move, false)
								end
								if choice == "feilunzhanyu" then
									for _, p in sgs.qlist(room:getAlivePlayers()) do
										room:setPlayerMark(p,"hasequip_FLZY",1)
									end
									local id = room:getTag("FLZY_ID"):toInt()
									--local getcard = sgs.Sanguosha:getCard(room:getTag("FLZY_ID"):toInt())
									local move = sgs.CardsMoveStruct(id, nil, player, room:getCardPlace(id), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
									room:moveCardsAtomic(move, false)
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

yu_equip_skill = sgs.CreateTriggerSkill{
	name = "yu_equip_skill",
	events = {sgs.EventPhaseStart},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getTreasure() and p:getTreasure():isKindOf("sichengliangyu") and p:getHandcardNum() < p:getHp() then
					if room:askForSkillInvoke(p, "sichengliangyu",data) then
						p:drawCards(2)
						room:throwCard(p:getTreasure(),p,p)
					end
				end
				if p:getTreasure() and p:getTreasure():isKindOf("tiejixuanyu") and player:getMark("damage_record-Clear") == 0 then
					if room:askForSkillInvoke(p, "tiejixuanyu",data) then
						room:askForDiscard(player, "tiejixuanyu", 2, 2, false, true)
						room:throwCard(p:getTreasure(),p,p)
					end
				end
				if p:getTreasure() and p:getTreasure():isKindOf("feilunzhanyu") and player:getMark("used_non_basic-Clear") > 0 and (not p:isNude()) and p:objectName() ~= player:objectName() then
					if room:askForSkillInvoke(p, "feilunzhanyu",data) then
						local card = room:askForCard(player, "..!", "@feilunzhanyu-give", sgs.QVariant(), sgs.Card_MethodNone)
						if card then
							room:moveCardTo(card, p, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), "feilunzhanyu", ""))
						end
						room:throwCard(p:getTreasure(),p,p)
					end
				end
			end
		end
		return false
	end,
}

qiangshou = sgs.CreateDistanceSkill{
	name = "qiangshou",
	frequency = sgs.Skill_Compulsory,
	correct_func = function(self, from, to)
		if from:hasSkill("qiangshou") and from:getTreasure() then
			return - 1
		else
			return 0
		end
	end
}

if not sgs.Sanguosha:getSkill("yu_equip_skill") then skills:append(yu_equip_skill) end

cheliji:addSkill(chexuan)
cheliji:addSkill(qiangshou)

sgs.LoadTranslationTable{
["cheliji"] = "徹里吉",
["chexuan"] = "車懸",
[":chexuan"] = "出牌階段，若你的裝備區里沒有寶物牌，你可棄置一張黑色牌，選擇一張【輿】置入你的裝備區；當你失去裝備區里的寶物牌後，你可進行判定，若結果為黑色，將一張隨機的【輿】置入你的裝備區。",
["qiangshou"] = "羌首",
[":qiangshou"] = "鎖定技，若你的裝備區內有寶物牌，你與其他角色的距離-1。",
["sichengliangyu"] = "四乘糧輿",
[":sichengliangyu"] = "一名角色的回合結束時，若你的手牌數小於體力值，你可以摸兩張牌，然後棄置此牌。",
["tiejixuanyu"] = "鐵蒺玄輿",
[":tiejixuanyu"] = "其他角色的回合結束時，若其本回合未造成過傷害，你可以令其棄置兩張牌，然後棄置此牌。",
["feilunzhanyu"] = "飛輪戰輿",
[":feilunzhanyu"] = "其他角色的回合結束時，若其本回合使用過非基本牌，你可以令其交給你一張牌，然後棄置此牌。",
["@feilunzhanyu-give"] = "請交給技能發動者一張牌",
}

--衛瓘
weiguan = sgs.General(extension,"weiguan","jin","3",true)
--忠允
zhongyun = sgs.CreateTriggerSkill{
	name = "zhongyun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.Damaged, sgs.HpRecover},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			
			if not room:getTag("FirstRound"):toBool() and ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) or (move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))) then
				if player:getMark("zhongyun_card-Clear") == 0 and player:getHandcardNum() == player:getHp() then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canDiscard(p, "he") then _targets:append(p) end
					end
					_targets:append(player)
					if not _targets:isEmpty() then
						local to_discard = room:askForPlayerChosen(player, _targets, "zhongyun", "zhongyun-discard", true)
						room:addPlayerMark(player, "zhongyun_card-Clear")
						if to_discard then
							room:notifySkillInvoked(player,"zhongyun")	
							if to_discard:objectName() ~= player:objectName() then
								room:broadcastSkillInvoke(self:objectName())
								room:doAnimate(1, player:objectName(), to_discard:objectName())
								room:throwCard(room:askForCardChosen(player, to_discard, "he", "zhongyun", false, sgs.Card_MethodDiscard), to_discard, player)
							else
								room:broadcastSkillInvoke(self:objectName())
								player:drawCards(1)
							end
						else
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		elseif event == sgs.Damaged or event == sgs.HpRecover then
			if player:getMark("zhongyun_hp-Clear") == 0 and player:getHandcardNum() == player:getHp() then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					--player:inMyAttackRange(to_select)
					if player:inMyAttackRange(p) then _targets:append(p) end
				end
				_targets:append(player)
				if not _targets:isEmpty() then
					room:setPlayerFlag(player,"zhongyun_hp")
					local target = room:askForPlayerChosen(player, _targets, "zhongyun", "zhongyun-hp", true)
					room:setPlayerFlag(player,"-zhongyun_hp")
					room:addPlayerMark(player, "zhongyun_hp-Clear")
					if target then
						room:notifySkillInvoked(player,"zhongyun")
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
		return false
	end
}
--神品
shenpin = sgs.CreateTriggerSkill{
	name = "shenpin" ,
	events = {sgs.AskForRetrial} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isKongcheng() then return false end
		local judge = data:toJudge()
		local prompt_list = {
			"@shenpin-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local forced = false
		if player:getMark("JilveEvent") == sgs.AskForRetrial then forced = true end
		local askforcardpattern = "."
		if judge.card:isBlack() then
			askforcardpattern = ".|red"
		else
			askforcardpattern = ".|black"
		end

		if forced then
			if judge.card:isBlack() then
				askforcardpattern = ".|red!"
			else
				askforcardpattern = ".|black!"
			end
		end
		local card = room:askForCard(player, askforcardpattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if forced and (card == nil) then
			card = player:getRandomHandCard()
		end
		if card then
			room:broadcastSkillInvoke(self:objectName())
			room:retrial(card, player, judge, self:objectName())
		end
		return false
	end
}

weiguan:addSkill(zhongyun)
weiguan:addSkill(shenpin)

sgs.LoadTranslationTable{
["weiguan"] = "衛瓘",
["zhongyun"] = "忠允",
[":zhongyun"] = "鎖定技。每名角色的回合限一次，你受傷/回復體力後，若你的體力值與手牌數相等，你回復一點體力或對你攻擊範圍內的一名角色造成1點傷害；每名角色的回合限一次，你獲得手牌或失去手牌後，若你的體力值與手牌數相等，你摸一張牌或棄置一名其他角色一張牌。",
["zhongyun-discard"] = "你可以棄置一名角色一張牌，否則你摸一張牌。",
["zhongyun-hp"] = "對你可以對攻擊範圍內的一名角色造成1點傷害，否則你回復一點體力",
["shenpin"] = "神品",
[":shenpin"] = "當一名角色的判定牌生效前，你可以打出一張與判定牌顏色不同的牌代替之。",
["@shenpin-card"] = "請發動「%dest」來修改 %src 的「%arg」判定",
}


--[[
鐘琰 晉 3體力
博覽 出牌階段開始時，你可從三個「出牌階段限一次」的技能中選擇一個獲得直到此階段結束；其他角色的出牌階段限一次，其可以失去1點體力，令你從三個「出牌階段限一次」的技能中選擇一個，其獲得此技能直到此階段結束。
儀法 鎖定技，其他角色使用【殺】或黑色普通錦囊牌指定你為目標後，其手牌上限-1直到其回合結束。
]]--
zhongyan = sgs.General(extension,"zhongyan","jin","3",false)

bolan = sgs.CreateTriggerSkill{
	name = "bolan",
	events = {sgs.EventPhaseStart,sgs.GameStart, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event==sgs.GameStart then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:hasSkill("bolan_bill") then
					room:attachSkillToPlayer(p,"bolan_bill")
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local all_sks = {"qingnang","lijian","quhu","tianyi_lua","lihun","qiangwu","gongxin","mingce","qice","mizhao","guose","zhiheng_po","jieyin_po","qiangxi_po","tiaoxin_po","sanchen","chuli","daoshu"}
					local sks = {}
					for i = 1, 3 do
						local sk = all_sks[math.random(1, #all_sks)]
						table.insert(sks, sk)
						table.removeOne(all_sks, sk)
					end

					local choice = room:askForChoice(player, "qianhuan", table.concat(sks, "+"))
					if not player:hasSkill(choice) then
						room:setPlayerMark(player,"bolan_use"..choice ,1)		
						room:acquireSkill(player, choice)
					end
				end
			end
		end
	end,
	priority = 10000,
}

bolanCard = sgs.CreateSkillCard{
	name = "bolan_bill",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("bolan") and to_select:getMark("bolan_Play") == 0 and to_select:getMark("bf_huashenxushi") == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "bolanengine")
		if source:getMark("bolanengine") > 0 then
			room:loseHp(source,1)
			room:addPlayerMark(targets[1], "bolan_Play")
			local all_sks = {"qingnang","lijian","quhu","tianyi_lua","lihun","qiangwu","gongxin","mingce","qice","mizhao","guose","zhiheng_po","jieyin_po","qiangxi_po","tiaoxin_po","sanchen","chuli","daoshu"}
			local sks = {}
			for i = 1, 3 do
				local sk = all_sks[math.random(1, #all_sks)]
				table.insert(sks, sk)
				table.removeOne(all_sks, sk)
			end

			local choice = room:askForChoice(targets[1], "qianhuan", table.concat(sks, "+"))
			if not source:hasSkill(choice) then
				room:setPlayerMark(source,"bolan_use"..choice ,1)				
				room:acquireSkill(source, choice)
				room:filterCards(source, source:getCards("h"), true)
			end
			room:removePlayerMark(source, "bolanengine")
		end
	end
}
bolanVS = sgs.CreateZeroCardViewAsSkill{
	name = "bolan_bill&",
	view_as = function()
		return bolanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return true
	end
}


bolan_clear = sgs.CreateTriggerSkill{
	name = "bolan_clear",
	global = true,
	events = {sgs.EventPhaseChanging},
	--view_as_skill = bolanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive or change.from == sgs.Player_Play then
				for _, skill in sgs.qlist(player:getSkillList(false, false)) do
					if player:getMark("bolan_use"..skill:objectName()) > 0 then
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

yifa = sgs.CreateTriggerSkill{
	name = "yifa" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.card:isBlack()) then
					SendComLog(self, player)
					room:addPlayerMark(use.from , "@yifa-Clear",1)					
				end
			end
		end
		return false
	end
}

yifaMC = sgs.CreateMaxCardsSkill{
	name = "#yifa", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		if target:getMark("@yifa-Clear") > 0 then
			return  - target:getMark("@yifa-Clear")
		end
	end
}

if not sgs.Sanguosha:getSkill("bolan_bill") then skills:append(bolanVS) end
if not sgs.Sanguosha:getSkill("bolan_clear") then skills:append(bolan_clear) end

zhongyan:addSkill(bolan)
zhongyan:addSkill(yifa)
zhongyan:addSkill(yifaMC)

sgs.LoadTranslationTable{
["zhongyan"]="鐘琰",
["bolan"] = "博覽",
[":bolan"] = "出牌階段開始時，妳可從三個「出牌階段限一次」的技能中選擇一個獲得直到此階段結束；其他角色的出牌階段限一次，其可以失去1點體力，令妳從三個「出牌階段限一次」的技能中選擇一個，其獲得此技能直到此階段結束。",
["bolan_bill"] = "博覽",
["bolanVS"] = "博覽",
["yifa"] = "儀法",
[":yifa"] = "鎖定技，其他角色使用【殺】或黑色普通錦囊牌指定妳為目標後，其手牌上限-1直到其回合結束。",
}

--[[
OL華歆
]]--

ol_huaxin = sgs.General(extension,"ol_huaxin","wei2",3,true,true)

--草詔
caozhao_filter = sgs.CreateFilterSkill{
	name = "#caozhao_filter",
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

		for _, mark in sgs.list(player:getMarkNames()) do
			if string.find(mark, "caozhao_card_id|"..id) and player:getMark(mark) > 0 then
				card_id = mark:split("|")[2]
				card_name = mark:split("|")[4]
					local peach = sgs.Sanguosha:cloneCard(card_name, originalCard:getSuit(), originalCard:getNumber())
					peach:setSkillName("caozhao")
					local card = sgs.Sanguosha:getWrappedCard(id)
					card:takeOver(peach)
					return card
			end
		end
		return originalCard
	end
}

if not sgs.Sanguosha:getSkill("#caozhao_filter") then skills:append(caozhao_filter) end

caozhaoCard = sgs.CreateSkillCard{
	name = "caozhao",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getHp() <= sgs.Self:getHp()
	end,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}

		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if source:getMark("caozhao"..card:objectName()) == 0  and source:getMark("AG_BANCard"..card:objectName()) == 0 and (card:isKindOf("BasicCard") or card:isNDTrick()) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "caozhao", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				ChoiceLog(source,pattern )
				room:addPlayerMark(source, "caozhao"..pattern)
				room:addPlayerMark(targets[1], "caozhao_ai|"..pattern)
				local choice_for_invoke = room:askForChoice(targets[1], "caozhao_agree", "caozhao:agree+caozhao:disagree")
				room:removePlayerMark(targets[1], "caozhao_ai|"..pattern)
				ChoiceLog(targets[1], choice_for_invoke,source)
				if choice_for_invoke == "caozhao:agree" then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:addPlayerMark(p, "caozhao_card_id|"..sgs.Sanguosha:getCard(self:getSubcards():first()):getEffectiveId().."|view_as|"..pattern)
					end

					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if not p:hasSkill("#caozhao_filter") then
							room:acquireSkill(p, "#caozhao_filter")
						end
					end

					room:filterCards(source, source:getCards("h"), true)

					for _, mark in sgs.list(source:getMarkNames()) do
						if string.find(mark, "caozhao_card_id|") and source:getMark(mark) > 0 then

							for _, c in sgs.qlist(source:getHandcards()) do


								if string.find(mark, "caozhao_card_id|"..c:getEffectiveId() ) then
									local show_card_log = sgs.LogMessage()
									show_card_log.type = "$caozhao"
									show_card_log.from = source
									show_card_log.to:append(source)
									show_card_log.card_str = c:getEffectiveId()
									show_card_log.arg = "caozhao"
									show_card_log.arg2 = mark:split("|")[4]
									room:sendLog(show_card_log)
								end
							end
						end
					end

					local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "caozhao-invoke", true, true)
					if target then
						room:obtainCard(target, self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), self:objectName(), ""), false)
					end
				elseif choice_for_invoke == "caozhao:disagree" then
					room:loseHp(targets[1],1)
				end
			end
		end
	end
}

caozhaoVS = sgs.CreateViewAsSkill{
	name = "caozhao",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local acard =caozhaoCard:clone()
			acard:addSubcard(cards[1]:getId())
			return acard
		end

	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#caozhao")
	end
}

caozhao = sgs.CreateTriggerSkill{
	name = "caozhao",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	global = true,
	view_as_skill = caozhaoVS,
	on_trigger = function(self, event, player, data,room) 
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive or change.to == sgs.Player_RoundStart then
				room:filterCards(player, player:getCards("h"), true)

					for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "caozhao_card_id|") and player:getMark(mark) > 0 then
							for _, c in sgs.qlist(player:getHandcards()) do
								if string.find(mark, "caozhao_card_id|"..c:getEffectiveId() ) then
									local show_card_log = sgs.LogMessage()
									show_card_log.type = "$caozhao"
									show_card_log.from = player
									show_card_log.to:append(player)
									show_card_log.card_str = c:getEffectiveId()
									show_card_log.arg = "caozhao"
									show_card_log.arg2 = mark:split("|")[4]
									room:sendLog(show_card_log)
								end
							end
						end
					end

			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) or move.to_place == sgs.Player_PlaceHand then
				if not player:isKongcheng() then
					room:filterCards(player, player:getHandcards(), true)

					for _, p in sgs.qlist(room:getAlivePlayers()) do
						for _, mark in sgs.list(p:getMarkNames()) do
							if string.find(mark, "caozhao_card_id|") and p:getMark(mark) > 0 then
								for _, c in sgs.qlist(p:getHandcards()) do
									if string.find(mark, "caozhao_card_id|"..c:getEffectiveId() ) then
										local show_card_log = sgs.LogMessage()
										show_card_log.type = "$caozhao"
										show_card_log.from = p
										show_card_log.to:append(p)
										show_card_log.card_str = c:getEffectiveId()
										show_card_log.arg = "caozhao"
										show_card_log.arg2 = mark:split("|")[4]
										room:sendLog(show_card_log)
									end
								end
							end
						end
					end
				end
			end

			if move.to_place == sgs.Player_DiscardPile then
				for _, id in sgs.qlist(move.card_ids) do
					for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "caozhao_card_id|"..id) and player:getMark(mark) > 0 then
							room:setPlayerMark(player,mark,0)
						end
					end
				end
			end
		end
	end,
}
--息兵
olxibing = sgs.CreateTriggerSkill{
	name = "olxibing", 
	--events = {sgs.Damage, sgs.Damaged}, 
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local target
		if event == sgs.Damage then
			target = damage.to
		elseif event == sgs.Damaged then
			target = damage.from
		end
		if target then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local choice = room:askForChoice(player, "olxibing", "olxibing1+olxibing2", data)
				if choice == "olxibing1" then
						room:setPlayerFlag(target, "Fake_Move")
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						local card_ids = sgs.IntList()
						local original_places = sgs.IntList()
						for i = 0, 1 do
							if not player:canDiscard(target, "he") then break end
							local to_throw = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							card_ids:append(to_throw)
							original_places:append(room:getCardPlace(card_ids:at(i)))
							dummy:addSubcard(card_ids:at(i))
							room:throwCard(sgs.Sanguosha:getCard(to_throw), target, player)
							room:getThread():delay()
						end
						room:setPlayerFlag(target, "-Fake_Move")
				elseif choice == "olxibing2" then
					room:askForDiscard(player,"olxibing",2,2)
				end

				if player:getHandcardNum() < target:getHandcardNum() then
					player:drawCards(2)
					room:addPlayerMark(player,"olxibing"..player:objectName().."-Clear")
				elseif player:getHandcardNum() > target:getHandcardNum() then
					target:drawCards(2)
					room:addPlayerMark(target,"olxibing"..player:objectName().."-Clear")
				end
			end
		end
		return false
	end
}

olxibingPro = sgs.CreateProhibitSkill{
	name = "olxibingPro",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("olxibing") and from:getMark("olxibing"..to:objectName().."-Clear") > 0 and not card:isKindOf("SkillCard")
	end
}

if not sgs.Sanguosha:getSkill("olxibingPro") then skills:append(olxibingPro) end

ol_huaxin:addSkill(caozhao)
ol_huaxin:addSkill(olxibing)

sgs.LoadTranslationTable{
	["ol_huaxin"] = "OL華歆",
	["&ol_huaxin"] = "華歆",
	["$caozhao"] = "因 %arg 效果影響， %from 的手牌為 %card 視為【 %arg2 】",
	["caozhao"] = "草詔",
	["caozhao_filter"] = "草詔",
	[":caozhao"] = "出牌階段限一次，你可展示一張手牌並聲明一種未以此法聲明過的基本牌或普通錦囊牌，"..
"令一名體力不大於你的其他角色選擇一項：令此牌視為你聲明的牌，或其失去1點體力。然後若此牌聲明成功，然後你可將其交給一名其他角色。",
	["olxibing"] = "息兵",
	["olxibingPro"] = "息兵",
	[":olxibing"] = "每當你受到其他角色造成的傷害後，你可棄置你或該角色兩張牌，"..
"然後你們中手牌少的角色摸兩張牌，以此法摸牌的角色不能使用牌指定你為目標直到回合結束。",
	["olxibing1"] = "棄置該角色兩張牌",
	["olxibing2"] = "棄置你兩張牌",
	["caozhao:agree"] = "令其聲明成功",
	["caozhao:disagree"] = "令其聲明失敗並失去一點體力",
	["caozhao_agree"] = "草詔",
	["caozhao-invoke"] = "你可將聲明成功的牌交給一名其他角色",
}

--左棻
zuofen = sgs.General(extension, "zuofen", "jin",3,false)
--詔頌
zhaosong = sgs.CreateTriggerSkill{
	name = "zhaosong" ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.EnterDying} ,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Draw then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill("zhaosong") and (player:getMark("@zhaosong_lei")+player:getMark("@zhaosong_fu")+player:getMark("@zhaosong_song")) == 0 and (not player:isNude()) then
						if room:askForSkillInvoke(p, self:objectName(), data) then
							room:doAnimate(1, p:objectName(), player:objectName())
						
							local id = room:askForCard(player, "..!", "@zhaosong", data, sgs.Card_MethodNone)
							if id then
								if id:isKindOf("TrickCard") then
									room:addPlayerMark(player,"@zhaosong_lei")
								elseif id:isKindOf("EquipCard") then
									room:addPlayerMark(player,"@zhaosong_fu")
								elseif id:isKindOf("BasicCard") then
									room:addPlayerMark(player,"@zhaosong_song")
								end
								room:doAnimate(1, player:objectName(), p:objectName())
								room:broadcastSkillInvoke(self:objectName())

								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), "zhaosong","")
								room:moveCardTo(id,p ,sgs.Player_PlaceHand,reason)

							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("@zhaosong_fu") > 0 then

					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canDiscard(p, "ej") then
							targets:append(p)
						end
					end
					if not targets:isEmpty() then
						local target = room:askForPlayerChosen(player, targets, "zhaosong_fu", "zhaosong_fu-invoke", true, true)
						if target then
							room:removePlayerMark(player, "@zhaosong_fu")
							room:doAnimate(1, player:objectName(), target:objectName())
							local id = room:askForCardChosen(player, target, "ej", "zhaosong_fu", false, sgs.Card_MethodDiscard)
							room:throwCard(id, target, player)
							local _data = sgs.QVariant()
							_data:setValue(change)
							if room:askForSkillInvoke(player, "zhaosong_fu_draw", _data) then
								target:drawCards(1)
							end
						end
					end
				end
			end

		elseif event == sgs.EnterDying then
			if player:getMark("@zhaosong_lei") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:removePlayerMark(player, "@zhaosong_lei")
					room:loseMaxHp(player)

					local n = 1 - player:getHp()
					if n > 0 then
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = n
						room:recover(player, recover)
					end
				end
			end
		end
		return false
	end
}

--離思
lisi = sgs.CreateTriggerSkill{
	name = "lisi",
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		local is_nullification = false
		for _,id in sgs.qlist(move.card_ids) do
			if sgs.Sanguosha:getCard(id) and sgs.Sanguosha:getCard(id):isKindOf("Nullification") then
				is_nullification = true
			end
		end
		local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if player:getPhase() == sgs.Player_NotActive and move.from and move.from:objectName() == player:objectName() and (move.to_place == sgs.Player_DiscardPile or (move.to_place == 7 and is_nullification)) and (extract == sgs.CardMoveReason_S_REASON_USE) then
		--move.to_place == 7 and is_nullification為神殺處理無懈可擊的特殊狀況

			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do 
				if p:getHandcardNum() <= player:getHandcardNum() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), self:objectName().."-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					--local dummy = sgs.Sanguosha:cloneCard("slash")
					--dummy:addSubcards(move.card_ids)
					--room:moveCardTo(dummy, target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""))
					for _,id in sgs.qlist(move.card_ids) do
						move.from_places:removeAt(listIndexOf(move.card_ids, id))
						move.card_ids:removeOne(id)
						data:setValue(move)
						room:moveCardTo(sgs.Sanguosha:getCard(id), target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""))
					end
				end
			end
		end
		return false
	end
}

zuofen:addSkill(zhaosong)
zuofen:addSkill(lisi)

sgs.LoadTranslationTable{
["zuofen"] = "左棻",
["#zuofen"] = "無寵的才女",
["zhaosong"] = "詔頌",
[":zhaosong"] = "一名其他角色於其摸牌階段結束時，若其沒有標記，你可令其正面向上交給你一張手牌，然後根據此牌的類型，"..
"令該角色獲得對應的標記：錦囊牌，「誄」標記；裝備牌，「賦」標記；基本牌，「頌」標記。進入瀕死時，你可棄置「誄」，"..
"減少一點體力上限，回復至1體力並摸1張牌；出牌階段開始時，你可棄置「賦」，棄置一名角色區域內的一張牌，然後可令其摸一張牌；"..
"你使用僅指定一個目標的【殺】時，可棄置「頌」為此【殺】額外選擇至多兩個目標，然後若此【殺】造成的傷害小於2，你失去1點體力。",
["@zhaosong_lei"] = "誄",
["@zhaosong_fu"] = "賦",
["@zhaosong_song"] = "頌",
["lisi"] = "離思",
[":lisi"] = "每當你於回合外使用牌的置入棄牌堆時，你可將其交給一名手牌數不大於你的其他角色。",
["lisi-invoke"] = "妳可以發動〖離思〗",

["zhaosong_lei"] = "詔頌(誄)",
["zhaosong_fu"] = "詔頌(賦)",
["zhaosong_song"] = "詔頌(頌)",
["@zhaosong"] = "請交給技能發動者一張手牌",
["zhaosong_fu-invoke"] = "你可以發動“詔頌--賦”",
["zhaosong_fu_draw"] = "詔頌(賦)摸牌”",
}


--晉·楊艷[OL]  晉 3/3
yangyan = sgs.General(extension, "yangyan", "jin",3,false)
--選備
xuanbei = sgs.CreateTriggerSkill{
	name = "xuanbei",
	events = {sgs.BeforeCardsMove, sgs.EventPhaseEnd,sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			getpatterncard(player, {"TrickCard"},true,false)
			getpatterncard(player, {"TrickCard"},true,false)
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local invoke = false
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") or sgs.Sanguosha:getCard(id):isKindOf("Slash") then
					invoke = true
				end
			end
			local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if player:getPhase() == sgs.Player_Play and move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and extract == sgs.CardMoveReason_S_REASON_USE and invoke and player:getMark("has_use_xuanbei") == 0 then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "xuanbei-invoke", true, true)
				if target then
					room:doAnimate(1, player:objectName(), target:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					for _,id in sgs.qlist(move.card_ids) do
						move.from_places:removeAt(listIndexOf(move.card_ids, id))
						move.card_ids:removeOne(id)
						data:setValue(move)
						room:obtainCard(player, sgs.Sanguosha:getCard(id), true)
					end
					room:addPlayerMark(player, "has_use_xuanbei")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			room:removePlayerMark(player, "has_use_xuanbei")
		end
		return false
	end
}

--嫻婉
xianwanVS = sgs.CreateZeroCardViewAsSkill{
	name = "xianwan",
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
		return sgs.Slash_IsAvailable(player) and player:isChained()
	end,
	enabled_at_response = function(self, player, pattern)
		return ((pattern == "slash" and player:isChained()) or (pattern == "jink" and not player:isChained())) and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	end
}
xianwan = sgs.CreateTriggerSkill{
	name = "xianwan",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = xianwanVS, 
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
			if card:isKindOf("Slash") then
				room:broadcastProperty(player, "chained")
				room:setPlayerProperty(player, "chained", sgs.QVariant(true))
			else
				room:setPlayerProperty(player, "chained", sgs.QVariant(false))
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) 
	end
}

yangyan:addSkill(xuanbei)
yangyan:addSkill(xianwan)

sgs.LoadTranslationTable{
["yangyan"] = "楊艷",
["#yangyan"] = "武元皇后",
["xuanbei"] = "選備",
--[":xuanbei"] = "遊戲開始時，你額外獲得兩張帶應變效果的牌。每回合限一次，你使用帶強化效果的牌後，你可將其交給一名其他角色。",
[":xuanbei"] = "遊戲開始時，妳額外獲得兩張錦囊牌。每回合限一次，妳使用錦囊牌或「殺」後，妳可將其交給一名其他角色。",
["xuanbei-invoke"] = "妳可以發動〖選備〗",
["xianwan"] = "嫻婉",
[":xianwan"] = "妳可橫置視為使用一張【閃】，或重置視為使用一張【殺】。",
}
	

--晉·楊芷[OL] 晉 3/3
yangzhi = sgs.General(extension, "yangzhi", "jin",3,false,true)

--婉嫕
wanyi_select = sgs.CreateSkillCard{
	name = "wanyi", 
	will_throw = true, 
	target_fixed = true, 
	handling_method = sgs.Card_MethodNone, 
	on_use = function(self, room, source, targets)
		local choices = {}

		for i = 1,4,1 do
			if source:getMark("wanyi"..tostring(i).."_-Clear") == 0 then
				table.insert(choices, "wanyi"..tostring(i))
			end
		end

		local choice = room:askForChoice(source, "wanyi", table.concat(choices, "+"))
		room:addPlayerMark(source,choice.."_-Clear")
		if choice == "wanyi1" then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if source:canDiscard(p, "hej") then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local to = room:askForPlayerChosen(source, _targets, "wanyi_1", "wanyi1-invoke", true, true)
				if to then
					if source:distanceTo(to) > 1 then
						local id = room:askForCardChosen(source, to, "hej", self:objectName())
						room:throwCard(sgs.Sanguosha:getCard(id), to, source)
					else
						local id = room:askForCardChosen(source, to, "hej", self:objectName())
						room:obtainCard(source , sgs.Sanguosha:getCard(id))
					end
				end
			end
		elseif choice == "wanyi2" then
			local cards = room:getNCards(2)
			room:askForGuanxing(source, cards, 0)
			source:drawCards(2)
		elseif choice == "wanyi3" then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if p:getHandcardNum() > 0 then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local to = room:askForPlayerChosen(source, _targets, "wanyi_3", "wanyi3-invoke", true, true)
				if to then
					local ids = getIntList(to:getHandcards())
					local id = ids:at(math.random(0, ids:length() - 1))
					room:showCard(to, id)

					if sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit() then
					else
						room:damage(sgs.DamageStruct("wanyi", source, to))
					end
				end
			end

		elseif choice == "wanyi4" then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:getEquips():length() > 0 then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local to = room:askForPlayerChosen(player, _targets, "wanyi_4", "wanyi4-invoke", true, true)
				if to then
					local choice2 = room:askForChoice(to, "wanyi_4", "drowning:damage+drowning:throw")
					if choice2 == "drowning:damage" then
						room:damage(sgs.DamageStruct("wanyi", source, to))
					else
						room:throwAllEquips(to)
					end
				end
			end
		end
	end,
}

wanyi = sgs.CreateViewAsSkill{
	name = "wanyi",
	n = 1,
	response_or_use = true,
	response_pattern = "@@wanyi",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@wanyi" then
			return false
		else
			return canCauseDamage(to_select)
		end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = wanyi_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}

--埋禍
maihuo = sgs.CreateTriggerSkill{
	name = "maihuo" ,
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.TargetConfirmed,sgs.EventPhaseStart,sgs.Damage} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and RIGHT(self, player) then
				if use.card:isKindOf("Slash") and use.to:length() == 1 and use.card:getSkillName() ~= "maihuo" then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					if player:isAlive() and not use.card:isVirtualCard() then
						use.from:addToPile("yz_huo", use.card)
						player:setFlags("-hunbianTarget")
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			
			if player:getPile("yz_huo"):length() > 0 then
				for _, id in sgs.qlist(player:getPile("yz_huo")) do

					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						local use_card = sgs.Sanguosha:getCard(id)
						use_card:setSkillName(self:objectName())

						local targets_list = sgs.SPlayerList()
						if not room:isProhibited(player, p, use_card) and player:canSlash(p, nil, false) then
							targets_list:append(p)
						end
						if targets_list:length() > 0 then

							room:useCard(sgs.CardUseStruct( use_card , player, targets_list))

						end

						
						break
					end

					room:moveCardTo(id, nil, sgs.Player_DiscardPile, false)
				end
			end
		elseif event == sgs.Damage and RIGHT(self, player) then
			local damage = data:toDamage()
			if damage.to and damage.to:getPile("yz_huo") > 0 then
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(damage.to:getPile("yz_huo"))
				room:throward( dummy,damage.to,damage.to)
			end
		end
	end,
}

yangzhi:addSkill(wanyi)
yangzhi:addSkill(maihuo)

sgs.LoadTranslationTable{
["yangzhi"] = "楊芷",
["#yangzhi"] = "武悼皇后",
["wanyi"] = "婉嫕",
--[":wanyi"] = "出牌階段，你可將一張帶有應變效果的手牌當逐近棄遠/出其不意/水淹七軍/洞燭先機使用。",
[":wanyi"] = "出牌階段每個效果限一次，妳可以棄置一張傷害類手牌並發動下列效果之一："..
"1.選擇一名其他角色。若你與其距離的大於1，你棄置其區域內的一張牌；若你與其的距離等於1，你獲得其區域內的一張牌。"..
"2.觀看牌堆頂的兩張牌並將其以任意順序置於牌堆頂或牌堆底，然後摸兩張牌。"..
"3.你展示其一張手牌，若此牌與你棄置牌的花色不同，則你對其造成1點傷害。"..
"4.選擇一名其他角色。令其選擇一項：棄置裝備區的所有牌（至少一張），或受到1點傷害。",

["wanyi_1"] = "婉嫕",
["wanyi_3"] = "婉嫕",
["wanyi_4"] = "婉嫕",
["wanyi1"] = "1.選擇一名其他角色。若你與其距離的大於1，你棄置其區域內的一張牌；若你與其的距離等於1，你獲得其區域內的一張牌。",
["wanyi2"] = "2.觀看牌堆頂的兩張牌並將其以任意順序置於牌堆頂或牌堆底，然後摸兩張牌。",
["wanyi3"] = "3.你展示其一張手牌，若此牌與你棄置牌的花色不同，則你對其造成1點傷害。",
["wanyi4"] = "4.選擇一名其他角色。令其選擇一項：棄置裝備區的所有牌（至少一張），或受到1點傷害。",
["wanyi1-invoke"] = "請選擇一名其他角色發動「婉嫕(1)」",
["wanyi3-invoke"] = "請選擇一名其他角色發動「婉嫕(3)」",
["wanyi4-invoke"] = "請選擇一名其他角色發動「婉嫕(4)」",

["maihuo"] = "埋禍",
[":maihuo"] = "其他角色非因「埋禍」使用(實體非轉化的)【殺】僅指定妳為目標後，若其武將牌上沒有牌，妳可令此牌對你無效並將"..
"其置於其武將牌上，稱為「禍」。其於下個出牌階段開始時，對妳使用此【殺】(有次數及距離限制，不可使用則移去之)。妳對其他角色造成傷害後，移除其武將牌上的「禍」。",
["yz_huo"] = "禍",
}


sgs.LoadTranslationTable{
["kotori_yumo"] = "馭魔",
["kotori_yumo_gain"] = "馭魔",
[":kotori_yumo"] = "鎖定技，遊戲開始時，你獲得藍色、紅色、綠色、黃色、灰色魔物各一個。當有角色受到傷害後，若你沒有對應的標記，你根據其勢力獲得一個對應魔物：魏：藍、蜀：紅、吳：綠、群：黃、灰：晉、鍵：紫。回合開始時，你可以棄置一個對應的魔物並獲得以下技能之一直到回合結束：藍：魏業、紅：蜀義、綠：吳耀、黃：群心、灰：晉勢、紫：鍵魂。",
["kotori_huazhan"] = "花綻",
[":kotori_huazhan"] = "每回合每種魔物限一次，你可將一個藍色/紅色/綠色/黃色/紫色/灰色魔物當做【樹上開花】使用。",
}

--卡牌部分

--隨機應變
suijiyingbian_skill = sgs.CreateOneCardViewAsSkill{
	name = "suijiyingbian_skill&",
	view_filter = function(self, card)
		return card:isKindOf("suijiyingbian")
	end, 
	view_as = function(self,card)
		local DCR = sgs.Self:property("zhiyi"):toString():split(":")[1]
		local shortage = sgs.Sanguosha:cloneCard(DCR,card:getSuit(),card:getNumber())
		shortage:setSkillName("suijiyingbian_skill")
		shortage:addSubcard(card)
		return shortage
	end,
	enabled_at_play = function(self,player)
		return true
	end
}

suijiyingbian = sgs.CreateTrickCard{
	name = "suijiyingbian",
	class_name = "suijiyingbian",
	target_fixed = false,
	can_recast = false,
	--suit = sgs.Card_Spade,
	--number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)

	end,
	on_effect = function(self, effect)

	end
}

sgs.LoadTranslationTable{
["suijiyingbian"]="隨機應變",
[":suijiyingbian"]="此牌的牌名視為你本回合內使用或打出的上一張基本牌或普通錦囊牌的牌名。",
}
--逐近棄遠

zhujinqiyuan = sgs.CreateTrickCard{
	name = "zhujinqiyuan",
	class_name = "zhujinqiyuan",
	target_fixed = false,
	can_recast = false,
	--suit = sgs.Card_Spade,
	--number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isNude() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			if effect.from:distanceTo(effect.to) > 1 then
				local id = room:askForCardChosen(effect.from, effect.to, "hej", self:objectName())
				room:throwCard(sgs.Sanguosha:getCard(id), effect.to, effect.from)
			else
				local id = room:askForCardChosen(effect.from, effect.to, "hej", self:objectName())
				room:obtainCard(effect.from , sgs.Sanguosha:getCard(id))
			end
		end
	end
}

sgs.LoadTranslationTable{
["zhujinqiyuan"]="逐近棄遠",
[":zhujinqiyuan"]="出牌階段，對一名有牌的其他角色使用。若你與其距離的大於1，你棄置其區域內的一張牌；若你與其的距離等於1，你獲得其區域內的一張牌。",
}

dongzhuxianji = sgs.CreateTrickCard{
	name = "dongzhuxianji",
	class_name = "dongzhuxianji",
	target_fixed = false,
	can_recast = false,
	--suit = sgs.Card_Spade,
	--number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() == sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local cards = room:getNCards(2)
			room:askForGuanxing(effect.from, cards, 0)
			effect.from:drawCards(2)
		end
	end
}

sgs.LoadTranslationTable{
["dongzhuxianji"]="洞燭先機",
["dongzhuxianji"]="出牌階段，對包含你在內的一名角色使用。你觀看牌堆頂的兩張牌並將其以任意順序置於牌堆頂或牌堆底，然後摸兩張牌。",
}

chuqibuyi = sgs.CreateTrickCard{
	name = "chuqibuyi",
	class_name = "chuqibuyi",
	target_fixed = false,
	can_recast = false,
	--suit = sgs.Card_Spade,
	--number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() == sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local ids = getIntList(effect.to:getHandcards())
			local id = ids:at(math.random(0, ids:length() - 1))
			room:showCard(effect.to, id)

			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit() then

			else
				room:damage(sgs.DamageStruct(self, effect.from, effect.to))
			end
		end
	end
}

sgs.LoadTranslationTable{
["chuqibuyi"]="出其不意",
[":chuqibuyi"]="出牌階段，對一名有手牌的其他角色使用。你展示其一張手牌，若此牌與【出其不意】的花色不同，則你對其造成1點傷害。",
}

sgs.LoadTranslationTable{
["wuxinghelingshan"]="五行鶴翎扇",
["wuxinghelingshan"]="當你聲明使用不為神屬性的屬性【殺】時，你可將此【殺】的屬性改為不為神屬性的其他屬性。",
}

sgs.LoadTranslationTable{
["wutiesuolian"]="烏鐵鎖鏈",
[":wutiesuolian"]="鎖定技，當你使用【殺】指定目標後，若其：已橫置，你觀看其手牌。未橫置，其橫置。",
}

sgs.LoadTranslationTable{
["heiguangkai"]="黑光鎧",
["heiguangkai"]="鎖定技，當你成為【殺】或黑色普通錦囊牌的目標後，若此牌的目標數大於1，則你令此牌對你無效。",
}

sgs.LoadTranslationTable{
["tongque"]="銅雀",
[":tongque"]="鎖定技，你於一回合內使用的第一張帶有【應變】效果的牌無視條件直接生效。",
}

sgs.LoadTranslationTable{
["tianjitu"]="天機圖",
["tianjitu"]="鎖定技，當此牌進入你的裝備區時，你棄置一張不為此【天機圖】的牌。當此牌離開你的裝備區後，你將手牌摸至五張。",
}

sgs.LoadTranslationTable{
["taigongyinfu"]="太公陰符",
["taigongyinfu"]="出牌階段開始時，你可以橫置或重置一名角色。出牌階段結束時，你可以重鑄一張手牌。",
}




sgs.Sanguosha:addSkills(skills)

return {extension,extension_card}



