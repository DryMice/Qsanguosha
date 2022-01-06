module("extensions.frameland", package.seeall)
extension = sgs.Package("frameland")

sgs.LoadTranslationTable{
	["frameland"] = "星火燎原",
}

local skills = sgs.SkillList()

--王粲
wangcan = sgs.General(extension, "wangcan", "qun2", "3", true)
--【散文】當你獲得牌時，若你手中有與這些牌排名相同的牌，你可以展示之，並棄置獲得的同名牌，然後摸棄牌數兩倍數量的牌。每回合限一次。
sanwen = sgs.CreateTriggerSkill{
	name = "sanwen",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if not room:getCurrent():hasFlag(self:objectName()..player:objectName()) and not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
			local show_ids = sgs.IntList()
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _,id in sgs.qlist(move.card_ids) do
				if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
					for _,card in sgs.qlist(player:getHandcards()) do
						if not move.card_ids:contains(card:getId()) and not show_ids:contains(card:getId()) and TrueName(card) == TrueName(sgs.Sanguosha:getCard(id)) then
							show_ids:append(card:getId())
							for _,i in sgs.qlist(move.card_ids) do
								if TrueName(card) == TrueName(sgs.Sanguosha:getCard(i)) and not dummy:getSubcards():contains(i) and room:getCardOwner(i):objectName() == player:objectName() and room:getCardPlace(i) == sgs.Player_PlaceHand then
									dummy:addSubcard(i)
								end
							end
						end
					end
				end
			end
			if not show_ids:isEmpty() and player:canDiscard(player, "h") and dummy:getSubcards():length() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerFlag(room:getCurrent(), self:objectName()..player:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					ShowManyCards(player, show_ids)
					room:throwCard(dummy, player, player)
					player:drawCards(dummy:getSubcards():length()*2, self:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}


--【七哀】限定技，當你進入瀕死狀態時，你可令其他每名角色交給你一張牌
qiai = sgs.CreateTriggerSkill{
	name = "qiai",
	frequency = sgs.Skill_Limited,
	limit_mark = "@qiai",
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:getMark("@qiai") > 0 then
				if room:askForSkillInvoke(player, "qiai", data) then
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("wangcan","qiai")
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isNude() then
					local card = room:askForCard(p, "..!", "@qiai_give:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(), ""))
					end
				end
			end
					room:removePlayerMark(player, "@qiai")		
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@qiai") > 0
				end
			end
		end
		return false
	end
}
--【登樓】限定技，結束階段開始時，若你沒有手牌，你可以觀看牌堆頂的四張牌，然後獲得其中的非基本牌，並使用其中的基本牌（不能使用則棄置）。
denglouCard = sgs.CreateSkillCard{
	name = "denglou",
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
denglouVS = sgs.CreateOneCardViewAsSkill{
	name = "denglou",
	view_filter = function(self, card)
		return not sgs.Self:isJilei(card) and card:hasFlag(self:objectName()) and card:isAvailable(sgs.Self)
	end,
	view_as = function(self, card)
		local skillcard = denglouCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@denglou"
	end
}
denglou = sgs.CreatePhaseChangeSkill{   --尽最大努力只能做到从左到右使用观看的基本牌ZY:poi???FM大法参上!!!!!
	name = "denglou",
	view_as_skill = denglouVS, 
	frequency = sgs.Skill_Limited,
	limit_mark = "@denglou",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:isKongcheng() and player:getMark("@denglou") > 0 and room:askForSkillInvoke(player, self:objectName()) then
			room:doSuperLightbox("wangcan","denglou")
			room:broadcastSkillInvoke(self:objectName())
			room:removePlayerMark(player, "@denglou")
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local ids = sgs.IntList()
			for _, id in sgs.qlist(room:getNCards(4, false)) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
					ids:append(id)
				else
					dummy:addSubcard(id)
				end
			end
			if dummy:subcardsLength() > 0 then
				room:obtainCard(player, dummy, false)
			end
			if not ids:isEmpty() then
				for _, id in sgs.qlist(ids) do
					room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
				end
				room:setPlayerFlag(player, "Fake_Move")
				local _guojia = sgs.SPlayerList()
				_guojia:append(player)
				local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
				local moves = sgs.CardsMoveList()
				moves:append(move)
				room:notifyMoveCards(true, moves, false, _guojia)
				room:notifyMoveCards(false, moves, false, _guojia)
				room:setPlayerProperty(player, self:objectName(), sgs.QVariant(table.concat(sgs.QList2Table(ids), "+")))
				while room:askForUseCard(player, "@denglou", "@denglou") do
					local invoke = false
					for _, id in sgs.qlist(ids) do
						local card = sgs.Sanguosha:getCard(id)
						if card:hasFlag(self:objectName()) then
							invoke = true
						end
					end
					if not invoke then break end
				end
				room:setTag(self:objectName(), sgs.QVariant())
				local move_to = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
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
		return false
	end
}

wangcan:addSkill(sanwen)
wangcan:addSkill(qiai)
wangcan:addSkill(denglou)

sgs.LoadTranslationTable{
	["wangcan"] = "王粲",
	["sanwen"] = "散文",
	[":sanwen"] = "當你獲得牌時，若你手中有與這些牌排名相同的牌，你可以展示之，並棄置獲得的同名牌，然後摸棄牌數兩倍數量的牌。每回合限一次。",
	["qiai"] = "七哀",
	[":qiai"] = "限定技，當你進入瀕死狀態時，你可令其他每名角色交給你一張牌",
	["denglou"] = "登樓",
	[":denglou"] = "限定技，結束階段開始時，若你沒有手牌，你可以觀看牌堆頂的四張牌，然後獲得其中的非基本牌，並使用其中的基本牌（不能使用則棄置）。",
	["$sanwen1"] = "文若春华，思若泉涌。",
	["$sanwen2"] = "独步汉南，散文天下。",
	["$qiai1"] = "未知身死处，何能两相完？",
	["$qiai2"] = "悟彼下泉人，喟然伤心肝。",
	["$denglou1"] = "登兹楼以四望兮，聊暇日以销忧。",
	["$denglou2"] = "惟日月之逾迈兮，俟河清其未极。",
	["@qiai_give"] = "請交給 %src 一張牌",
	["@denglou"] = "你可以使用“登樓”中的基本牌",
	["~denglou"] = "選擇一張可以使用的基本牌->點擊確定",
}
--劉焉
liuyan = sgs.General(extension, "liuyan", "qun2", "3", true)
--【圖射】當你使用牌指定目標後，若你沒有基本牌，則你可以摸X張牌（X為此牌指定的目標數）。
tushe = sgs.CreateTriggerSkill{
	name = "tushe",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getTypeId() ~= sgs.Card_TypeSkill then
			local cards = player:getHandcards()
			local no_basiccard = true
			for _, card in sgs.qlist(cards) do
				if card:isKindOf("BasicCard") then
					no_basiccard = false
				end
			end
			if no_basiccard then
				if room:askForSkillInvoke(player, "tushe", data) then
					room:broadcastSkillInvoke(self:objectName())
					local n = use.to:length()
					player:drawCards(n)
				end
			end
		end
	end,
}
--【立牧】出牌階段，你可以將一張方塊牌當樂不思蜀對自己使用，然後回復一點體力；你的判定區有牌時你對攻擊範圍內的其他角色使用牌沒有次數和距離限制。
limucard = sgs.CreateSkillCard{
	name = "limu",
	target_fixed = true,
	will_throw = false,
	mute = true,	
	on_use = function(self,room,source,targets)		
		local cardid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(cardid)
		if card:getSuit() == sgs.Card_Diamond then
			local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,card:getNumber())
			indulgence:addSubcard(card)
			indulgence:setSkillName("limu")
			room:useCard(sgs.CardUseStruct(indulgence,source,source))
		end 
		room:broadcastSkillInvoke("limu")
		local theRecover = sgs.RecoverStruct()
		theRecover.recover = 1
		theRecover.who = source
		room:recover(source, theRecover)		   	
	end		
}

limu = sgs.CreateViewAsSkill{
	name = "limu",
	n=1,
	view_filter = function(self,selected,to_select)
		if #selected >0 then return false end		
		return to_select:getSuit() == sgs.Card_Diamond 	
	end,	
	view_as = function(self,cards)
		if #cards ~= 1 then return nil end		
		local acard = limucard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName("limu")		
		return acard
	end,
	enabled_at_play = function(self,player)
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
		indulgence:deleteLater()
		return not (player:isProhibited(player,indulgence) or player:containsTrick("indulgence"))
	end,	
}

limuTargetMod = sgs.CreateTargetModSkill{
	name = "#limuTargetMod" ,
	pattern = "Slash,TrickCard" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("limu") and from:getJudgingArea():length() > 0 and (card:isKindOf("Snatch") or card:isKindOf("SupplyShortage")) then
			return (from:getAttackRange()-1)
		end
		return 0
	end,
	residue_func = function(self, from)
		if from:hasSkill("limu") and from:getJudgingArea():length() > 0 then
			return 1000
		end
		return 0
	end,
}
liuyan:addSkill(tushe)
liuyan:addSkill(limu)
liuyan:addSkill(limuTargetMod)
extension:insertRelatedSkills("limu","#limuTargetMod")

sgs.LoadTranslationTable{
	["liuyan"] = "劉焉",
	["limu"] = "立牧",
	[":limu"] = "出牌階段，你可以將一張方塊牌當樂不思蜀對自己使用，然後回復一點體力；你的判定區有牌時你對攻擊範圍內的其他角色使用牌沒有次數和距離限制。",
	["tushe"] = "圖射",
	[":tushe"] = "當你使用牌指定目標後，若你沒有基本牌，則你可以摸X張牌（X為此牌指定的目標數）",
	["$tushe1"] = "非英杰不图？吾既谋之且射毕。",
	["$tushe2"] = "汉室衰微，朝纲祸乱，必图后福。",
	["$limu1"] = "米贼作乱，吾必为益州自保。",
	["$limu2"] = "废史立牧，可得一方安定。",
}
--劉繇
liuyao = sgs.General(extension,"liuyao","qun2","4",true)
--【戡難】出牌階段，若你於此階段內發動過此技能的次數小於X（X為你的體力值），你可與你於此階段內未以此法拼點過的一名角色拼點。若：你贏，你使用的下一張【殺】的傷害值基數+1且你於此階段內不能發動此技能；其贏，其使用的下一張【殺】的傷害基數+1.
kannanCard = sgs.CreateSkillCard{
	name = "kannan",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng() and to_select:getMark(self:objectName().."_Play") == 0
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(targets[1], self:objectName().."_Play", 1)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			source:pindian(targets[1], self:objectName())
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
kannanVS = sgs.CreateZeroCardViewAsSkill{
	name = "kannan",
	view_as = function()
		return kannanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#kannan") < player:getHp() and player:getMark(self:objectName().."source_Play") == 0 and not player:isKongcheng() 
	end
}
kannan = sgs.CreateTriggerSkill{
	name = "kannan",
	global = true,
	view_as_skill = kannanVS,
	events = {sgs.Pindian, sgs.CardUsed, sgs.ConfirmDamage, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason == self:objectName() then
				local winner = nil
				if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
					winner = pindian.to
				elseif pindian.from_card:getNumber() > pindian.to_card:getNumber() then
					winner = pindian.from
				end
				if winner then
					room:addPlayerMark(winner, "@kannanBuff")
					if winner:objectName() == pindian.from:objectName() then
						room:addPlayerMark(winner, self:objectName().."source_Play")
					end
				end
			end
		elseif event == sgs.CardUsed and player:getMark("@kannanBuff") > 0 then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				use.card:setTag("kannanBuffed", sgs.QVariant(player:getMark("@kannanBuff")))
				room:setPlayerMark(player, "@kannanBuff", 0)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:getTag("kannanBuffed"):toInt() > 0 then
				local log = sgs.LogMessage()
				log.type = "$kannan"
				log.from = player
				log.card_str = damage.card:toString()
				log.arg = self:objectName()
				log.arg2 = damage.card:getTag("kannanBuffed"):toInt()
				room:sendLog(log)
				damage.damage = damage.damage + damage.card:getTag("kannanBuffed"):toInt()
				data:setValue(damage)
			end

			--馬雲祿 馬妹
			if damage.card and damage.card:getTag("ol_fengpoBuffed"):toInt() > 0 then
				local log = sgs.LogMessage()
				log.type = "$kannan"
				log.from = player
				log.card_str = damage.card:toString()
				log.arg = "ol_fengpo"
				log.arg2 = damage.card:getTag("ol_fengpoBuffed"):toInt()
				room:sendLog(log)
				damage.damage = damage.damage + damage.card:getTag("ol_fengpoBuffed"):toInt()
				data:setValue(damage)
			end

			if damage.card and damage.card:getTag("tw_fengpoBuffed"):toInt() > 0 then
				local log = sgs.LogMessage()
				log.type = "$kannan"
				log.from = player
				log.card_str = damage.card:toString()
				log.arg = "tw_fengpo"
				log.arg2 = damage.card:getTag("tw_fengpoBuffed"):toInt()
				room:sendLog(log)
				damage.damage = damage.damage + damage.card:getTag("tw_fengpoBuffed"):toInt()
				data:setValue(damage)
			end

			if damage.from and damage.to:getMark("yijue_po"..damage.from:objectName().."-Clear") > 0 and damage.card and damage.card:isKindOf("Slash") and damage.card:getSuit() == sgs.Card_Heart then
				local log = sgs.LogMessage()
				log.type = "$kannan"
				log.from = player
				log.card_str = damage.card:toString()
				log.arg = "yijue"
				log.arg2 = 1
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end

			if damage.to and damage.to:getMark("@yiseDebuff") > 0 and damage.card and damage.card:isKindOf("Slash") then
				local log = sgs.LogMessage()
				log.type = "$yise"
				log.from = damage.to
				log.card_str = damage.card:toString()
				log.arg = "yise"
				log.arg2 = damage.to:getMark("@yiseDebuff")
				room:sendLog(log)
				damage.damage = damage.damage + damage.to:getMark("@yiseDebuff")
				room:setPlayerMark(damage.to, "@yiseDebuff", 0)
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getTag("kannanBuffed"):toInt() > 0 then
				use.card:removeTag("kannanBuffed")
			end
			if use.card and use.card:getTag("ol_fengpoBuffed"):toInt() > 0 then
				use.card:removeTag("ol_fengpoBuffed")
			end
			if use.card and use.card:getTag("tw_fengpoBuffed"):toInt() > 0 then
				use.card:removeTag("tw_fengpoBuffed")
			end
			--[[
			if player:hasSkill("paoxiao") and use.card:isKindOf("Slash") then
				room:addPlayerMark(player, "paoxiaoengine", 2)
				if player:getMark("paoxiaoengine") > 0 then
					room:addPlayerMark(player, "paoxiao_buff-Clear")
					room:removePlayerMark(player, "paoxiaoengine", 2)
				end
			end
			]]--
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

liuyao:addSkill(kannan)

sgs.LoadTranslationTable{
	["liuyao"] = "劉繇",
	["kannan"] = "戡難",
	[":kannan"] = "出牌階段，若你於此階段內發動過此技能的次數小於X（X為你的體力值），你可與你於此階段內未以此法拼點過的一名角色拼點。若：你贏，你使用的下一張【殺】的傷害值基數+1且你於此階段內不能發動此技能；其贏，其使用的下一張【殺】的傷害基數+1.",
	["$kannan"] = "%from 執行「%arg」的效果，%card 的傷害值+ %arg2 ",
	["$yise"] = "%from 的效果「%arg」被觸發，%card 的傷害值+ %arg2 ",
	["@kannanBuff"] = "戡難標記",
}

--周魴
zhoufang = sgs.General(extension,"zhoufang","wu2","3",true)
--斷髮 出牌階段，你可以棄置任意張黑色牌，然後摸等量的牌（你每階段以此法棄置的牌的總數不能大於體力上限）。
duanfaCard = sgs.CreateSkillCard{
	name = "duanfa",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."_Play", self:subcardsLength())
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			source:drawCards(self:subcardsLength(), self:objectName())
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
duanfa = sgs.CreateViewAsSkill{
	name = "duanfa",
	n = 999,
	view_filter = function(self, selected, to_select)
		return #selected < sgs.Self:getMaxHp() - sgs.Self:getMark(self:objectName().."_Play") and to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local duanfacard = duanfaCard:clone()
			for _,card in pairs(cards) do
				duanfacard:addSubcard(card)
			end
			duanfacard:setSkillName(self:objectName())
			return duanfacard
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark(self:objectName().."_Play") < player:getMaxHp()
	end
}
--誘敵 結束階段，你可以令一名其他角色棄置你一張手牌，若棄置的牌不是【殺】，則你獲得其一張牌；若棄置的牌不是黑色，則你摸一張牌。
ol_youdi = sgs.CreatePhaseChangeSkill{
	name = "ol_youdi",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:canDiscard(player, "h") and not p:isNude() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "ol_youdi-invoke", true, true)
				if to then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local id = room:askForCardChosen(to, player, "h", self:objectName(), false, sgs.Card_MethodDiscard)
						if id ~= -1 then
							room:throwCard(sgs.Sanguosha:getCard(id), player, to)
						end
						room:getThread():delay()
						if not to:isNude() and not sgs.Sanguosha:getCard(id):isKindOf("Slash") then
							local id = room:askForCardChosen(player, to, "he", self:objectName())
							if id ~= -1 then
								room:obtainCard(player, id, false)
							end
						end
						if not sgs.Sanguosha:getCard(id):isBlack() then
							player:drawCards(1, self:objectName())
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}
zhoufang:addSkill(duanfa)
zhoufang:addSkill(ol_youdi)

sgs.LoadTranslationTable{
	["zhoufang"] = "周魴",
	["duanfa"] = "斷髮",
	[":duanfa"] = "出牌階段，你可以棄置任意張黑色牌，然後摸等量的牌（你每階段以此法棄置的牌的總數不能大於體力上限）。",
	["ol_youdi"] = "誘敵",
	[":ol_youdi"] = "結束階段，你可以令一名其他角色棄置你一張手牌，若棄置的牌不是【殺】，則你獲得其一張牌；若棄置的牌不是黑色，則你摸一張牌。",
	["ol_youdi-invoke"] = "你可以對一名角色發動「誘敵」",
}

--呂岱
lvdai = sgs.General(extension,"lvdai","wu2","4",true)
--【勤國】當你於回合內使用裝備牌結算結束後，你可視為使用一張殺。當你的裝備區裡的牌移動後，或裝備牌移至你的裝備區後，若你裝備區裡的牌數與你的體力值相等且與此次移動之前你裝備區裡的牌數不等，你回復一點體力。
qinguoCard = sgs.CreateSkillCard{
	name = "qinguo" ,
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
			room:broadcastSkillInvoke(self:objectName(), 1)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("_"..self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
qinguoVS = sgs.CreateZeroCardViewAsSkill{
	name = "qinguo",
	view_as = function()
		return qinguoCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@qinguo"
	end
}

qinguo = sgs.CreateTriggerSkill{
	name = "qinguo",
	frequency = sgs.Skill_Frequency,
	view_as_skill = qinguoVS,
	events = {sgs.CardFinished,sgs.BeforeCardsMove,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("EquipCard") then
				room:askForUseCard(player, "@qinguo", "@qinguo")
			end
		elseif event == sgs.BeforeCardsMove then
			room:setPlayerMark(player,"qinguo",player:getEquips():length())
		elseif event == sgs.CardsMoveOneTime then
			if player:getEquips():length() ~= player:getMark("qinguo") and player:getEquips():length() == player:getHp() then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
				room:recover(player, recover)
			end
		end
	end,
}
lvdai:addSkill(qinguo)

sgs.LoadTranslationTable{
	["lvdai"] = "呂岱",
	["qinguo"] = "勤國",
	[":qinguo"] = "當你於回合內使用裝備牌結算結束後，你可視為使用一張殺。當你的裝備區裡的牌移動後，或裝備牌移至你的裝備區後，若你裝備區裡的牌數與你的體力值相等且與此次移動之前你裝備區裡的牌數不等，你回復一點體力。",
	["@qinguo"] = "你可以發動“勤國”",
	["~qinguo"] = "選擇若干名角色→點擊確定",
}
--呂虔
lvqian_sec_rev = sgs.General(extension,"lvqian_sec_rev","wei2","4",true)
--【威虜】鎖定技，當你受到其他角色造成的傷害後，傷害來源在你的下回合出牌階段開始時失去體力值直到僅剩1點體力，然後回合結束時回復以此法失去的體力值。
weilu = sgs.CreateTriggerSkill{
	name = "weilu",
	frequency = sgs.Skill_Compulsory,
	--events = {sgs.Damaged, sgs.EventPhaseStart},
	events = {sgs.Damaged, sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() ~= player:objectName() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--room:addPlayerMark(damage.from, self:objectName()..player:objectName())
					if player:getPhase() == sgs.Player_NotActive then
						room:addPlayerMark(damage.from, self:objectName()..player:objectName().."_next_round")
					else
						room:addPlayerMark(damage.from, self:objectName()..player:objectName().."_current_round")
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark(self:objectName()..player:objectName().."_next_round") > 0 then
						room:setPlayerMark(p, self:objectName()..player:objectName().."_next_round", 0)
					end
				end
			end
			if change.to and change.to == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark(self:objectName()..player:objectName().."_current_round") > 0 then
						room:setPlayerMark(p, self:objectName()..player:objectName().."_current_round", 0)
						room:addPlayerMark(p, self:objectName()..player:objectName().."_next_round")
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local send = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				--if p:getMark(self:objectName()..player:objectName()) > 0 then
				if p:getMark(self:objectName()..player:objectName().."_next_round") > 0 then
					--room:removePlayerMark(p, self:objectName()..player:objectName())
					room:setPlayerMark(p, self:objectName()..player:objectName().."_next_round", 0)
					local x = math.max(p:getHp() - 1, 0)
					if x > 0 then
						if not send then
							send = true
							room:sendCompulsoryTriggerLog(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName(), 2)
						end
						room:loseHp(p, x)
						room:addPlayerMark(p, "@"..self:objectName().."-Clear", x)
					end
				end
			end
		end
		return false
	end
}
--【贈刀】限定技，結束階段，你可以將裝備區內任意數量的牌置於一名其他角色的武將牌旁。該角色每次造成傷害時，移去一張“贈刀”牌，然後此傷害+1。
zengdao_sec_revCard = sgs.CreateSkillCard{
	name = "zengdao_sec_rev",
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		room:doSuperLightbox("lvqian_sec_rev","zengdao_sec_rev")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), tiger:objectName(), "zengdao_sec_rev","")
		--room:moveCardTo(self,tiger,sgs.Player_PlaceHand,reason)
		tiger:addToPile("zengdao", self:getSubcards())
		room:removePlayerMark(source, "@donate_sec_rev")
	end
}
zengdao_sec_revVS = sgs.CreateViewAsSkill{
	name = "zengdao_sec_rev",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		return (to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = zengdao_sec_revCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@donate_sec_rev") > 0 and player:getEquips():length() > 0
	end
}
zengdao_sec_rev = sgs.CreateTriggerSkill{
		name = "zengdao_sec_rev",
		frequency = sgs.Skill_Limited,
		limit_mark = "@donate_sec_rev",
		view_as_skill = zengdao_sec_revVS ,
		on_trigger = function() 
		end
}
--贈刀增傷效果
zengdaoPD = sgs.CreateTriggerSkill{
	name = "#zengdaoPD",  
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local card = damage.card
			if player:getPile("zengdao"):length() > 0 then
				local ids = player:getPile("zengdao")
				local id = ids:at(0)
				local card = sgs.Sanguosha:getCard(id)
				room:moveCardTo(card, nil, sgs.Player_DiscardPile, false)
				
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#Zengdao"
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
	can_trigger = function(self, target)
		return target ~= nil
	end
}

if not sgs.Sanguosha:getSkill("#zengdaoPD") then skills:append(zengdaoPD) end

lvqian_sec_rev:addSkill(weilu)
lvqian_sec_rev:addSkill(zengdao_sec_rev)

sgs.LoadTranslationTable{
	["lvqian_sec_rev"] = "呂虔",
	["weilu"] = "威虜",
	[":weilu"] = "鎖定技，當你受到其他角色造成的傷害後，傷害來源在你的下回合出牌階段開始時失去體力值直到僅剩1點體力，然後回合結束時回復以此法失去的體力值。",
	["zengdao_sec_rev"] = "贈刀",
	["zengdao"] = "贈刀",
	[":zengdao_sec_rev"] = "限定技，出牌階段，你可以將裝備區內任意數量的牌置於一名其他角色的武將牌旁。該角色每次造成傷害時，移去一張“贈刀”牌，然後此傷害+1。",
	["#Zengdao"] = "%from 受到技能 “<font color=\"yellow\"><b>贈刀</b></font>”的影響，對 %to 造成傷害由 %arg 點增加到 "..
"%arg2 點",
	["@donate_sec_rev_sec_rev-card"] = "你可以對一名角色發動「贈刀」",
	["~zengdao_sec_rev"] = "選擇裝備區的任意張牌 -> 點選一名角色 -> 點選「確定」",
}
--杜畿
duji = sgs.General(extension,"duji","wei2","3",true)
--【應勢】出牌階段開始時，若沒有武將牌旁有“酬”的角色，你可以將所有紅桃牌置於一名其他角色的武將牌旁，稱為“酬”；若如此做，當一名角色使用【殺】對武將牌旁有“酬”的角色造成傷害後，其可以獲得一張“酬”；當武將牌旁有“酬”的角色死亡時，你獲得所有“酬”。
yingshiCard = sgs.CreateSkillCard{
	name = "yingshi",
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), tiger:objectName(), "yingshi","")
		--room:moveCardTo(self,tiger,sgs.Player_PlaceHand,reason)
		tiger:addToPile("reward", self:getSubcards())
	end
}
yingshiVS = sgs.CreateViewAsSkill{
	name = "yingshi",
	n = 999 ,
	response_pattern = "@@yingshi",
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = yingshiCard:clone()
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
yingshi = sgs.CreateTriggerSkill{
	name = "yingshi",
	events = {sgs.EventPhaseStart},
	view_as_skill = yingshiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		local invoke = true
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getPile("reward"):length() > 0 then
				invoke = false
			end
		end
		if invoke and phase == sgs.Player_Play then
			room:askForUseCard(player, "@@yingshi", "@yingshi-card")
		end
	end
}
--應勢拿牌效果
yingshiTC = sgs.CreateTriggerSkill{
	name = "#yingshiTC",  
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.Damage,sgs.Death}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card then
				if damage.to:getPile("reward"):length() > 0 and damage.card:isKindOf("Slash") then
					local ids = damage.to:getPile("reward")
					local id = ids:at(0)
					local card = sgs.Sanguosha:getCard(id)
					room:moveCardTo(card,player,sgs.Player_PlaceHand)
				end						
			end		
			return false
		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() then return false end
			if player:isAlive() and player:hasSkill("yingshi") then
				local id2s = sgs.IntList()
				if splayer:getPile("reward"):length() > 0 then
					local n = splayer:getPile("reward"):length()
					for i = 1, n,1 do
						local ids = splayer:getPile("reward")
						local id = ids:at(i-1)
						local card = sgs.Sanguosha:getCard(id)
						id2s:append(card:getEffectiveId())
					end
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = id2s
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
			end
		end		
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

if not sgs.Sanguosha:getSkill("#yingshiTC") then skills:append(yingshiTC) end
--【安東】當你受到其他角色造成的傷害時，你令傷害來源選擇一項：1.防止此傷害，本回合棄牌階段紅桃牌不計入手牌上限；2.觀看其手牌，若其中有紅桃牌則你獲得這些紅桃牌

andong = sgs.CreateTriggerSkill{
	name = "andong",
	global = true,
	events = {sgs.DamageInflicted, sgs.EventPhaseChanging,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() ~= player:objectName() and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local choices = {"andong1"}
					if not damage.from:isKongcheng() then
						table.insert(choices, "andong2")
					end
					local choice = room:askForChoice(damage.from, self:objectName(), table.concat(choices, "+"), data)
					--local choice = room:askForChoice(damage.from, self:objectName(), "andong1+andong2", data)
					--lazy(self, room, player, choice, true, tonumber(string.sub(choice, string.len(choice), string.len(choice))))
					lazy(self, room, damage.from, choice, true, tonumber(string.sub(choice, string.len(choice), string.len(choice))))
					if choice == "andong1" then
						room:addPlayerMark(damage.from, self:objectName().."-Clear")
						local log = sgs.LogMessage()
						log.type = "$andong_prevent"
						log.from = damage.from
						log.to:append(player)
						log.arg = self:objectName()
						if damage.card then
							log.card_str = damage.card:getEffectiveId()
						end
						room:sendLog(log)
						return true
					elseif choice == "andong2" then
						room:showAllCards(damage.from, player)
						local cards = sgs.IntList()
						for _, p in sgs.qlist(damage.from:getHandcards()) do
							if p:getSuit() == sgs.Card_Heart then
								cards:append(p:getEffectiveId())
							end
						end
						if cards:length() > 0 then
							local dummy = sgs.Sanguosha:cloneCard("slash")
							dummy:addSubcards(cards)
							room:obtainCard(player, dummy, false)
						end
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		else
			if player:getMark(self:objectName().."-Clear") > 0 then
				if event == sgs.EventPhaseChanging then
					local change = data:toPhaseChange()
					if change.to == sgs.Player_Discard then
						room:setPlayerCardLimitation(player, "discard", ".|heart|.|hand", true)
					end
				elseif event == sgs.EventPhaseEnd then
					if player:getPhase() == sgs.Player_Discard then
						room:removePlayerCardLimitation(player, "discard", ".|heart|.|hand$1")
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

andongmc = sgs.CreateMaxCardsSkill{
	name = "#andongmc",
	extra_func = function(self, target)
		if target:getMark("andong-Clear") > 0 then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:getSuit() == sgs.Card_Heart and target:getPhase() == sgs.Player_Discard then
					x = x + 1
				end
			end
			return x
		end
	end
}

duji:addSkill(yingshi)
duji:addSkill(andong)
duji:addSkill(andongmc)

sgs.LoadTranslationTable{
	["duji"] = "杜畿",
	["andong"] = "安東",
	[":andong"] = "當你受到其他角色造成的傷害時，你令傷害來源選擇一項：1.防止此傷害，本回合棄牌階段紅桃牌不計入手牌上限；2.觀看其手牌，若其中有紅桃牌則你獲得這些紅桃牌。",
	["yingshi"] = "應勢",
	[":yingshi"] = "出牌階段開始時，若沒有武將牌旁有“酬”的角色，你可以將所有紅桃牌置於一名其他角色的武將牌旁，稱為“酬”；若如此做，當一名角色使用【殺】對武將牌旁有“酬”的角色造成傷害後，其可以獲得一張“酬”；當武將牌旁有“酬”的角色死亡時，你獲得所有“酬”。",
	["andong1"] = "防止此傷害且你於此回合的棄牌階段內紅桃牌不計入手牌上限且不能棄置",
	["andong2"] = "其觀看你的手牌，獲得其中的紅桃牌",
	["$andong_prevent"] = "由於“%arg”，%from 對 %to 使用 %card 造成的傷害被防止",
	["$andong1"] = "勇足以當大難，智湧以安萬變。",
	["$andong2"] = "寬猛克濟，方安河東之民。",
	["@yingshi-card"] = "你可以對一名角色發動「應勢」",
	["~yingshi"] = "選擇任意張紅心牌 -> 點選一名角色 -> 點選「確定」",
	["reward"] = "酬",
	["$yingshi1"] = "应民之声，势民之根。",
	["$yingshi2"] = "应势而谋，顺民而为。",
}
--龐統
sp_pangtong = sgs.General(extension, "sp_pangtong", "wu2", "3", true)
--【過論】出牌階段限一次，你可展示一名其他角色的一張手牌A，然後你可以選擇你的一張牌B。若A的點數：小於B的點數，你與其交換這兩張牌，其摸一張牌；大於B的點數，你與其交換這兩張牌，你摸一張牌。
guolunCard = sgs.CreateSkillCard{
	name = "guolun" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local id = room:askForCardChosen(source, targets[1], "h", self:objectName())
			if id ~= -1 then
				room:showCard(targets[1], id)
				local card = room:askForCard(source, "..", "@guolun_choose", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					local exchangeMove = sgs.CardsMoveList()
					exchangeMove:append(sgs.CardsMoveStruct(card:getId(), targets[1], sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), targets[1]:objectName(), self:objectName(), "")))
					exchangeMove:append(sgs.CardsMoveStruct(id, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, targets[1]:objectName(), source:objectName(), self:objectName(), "")))
					room:moveCardsAtomic(exchangeMove, false)
					if sgs.Sanguosha:getCard(id):getNumber() < card:getNumber() then
						targets[1]:drawCards(1, self:objectName())
					elseif sgs.Sanguosha:getCard(id):getNumber() > card:getNumber() then
						source:drawCards(1, self:objectName())
					end
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

guolun = sgs.CreateZeroCardViewAsSkill{
	name = "guolun" ,
	view_as = function(self, card)
		return guolunCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#guolun") < 1
	end
}
--【展驥】鎖定技，當你於出牌階段內因摸牌且並非因此技能而得到牌時，你摸一張牌。
zhanji = sgs.CreateTriggerSkill{
	name = "zhanji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then		
			local move = data:toMoveOneTime()
			if (move.to:objectName() == player:objectName())
			 and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
			 and move.to_place == sgs.Player_PlaceHand then
				if player:getPhase() == sgs.Player_Play then
					if not player:hasFlag("zhanji") then
						room:notifySkillInvoked(player,"zhanji")
						room:broadcastSkillInvoke("zhanji")
						room:setPlayerFlag(player, "zhanji")		
						room:drawCards(player, 1, "zhanji")
					else
						room:setPlayerFlag(player, "-zhanji")
					end
				end
			end						
			return false
		end
	end,
}

--【送喪】限定技，當其他角色死亡時，若你已受傷，你可以回复1點體力；若你未受傷，你可增加1點體力上限。若如此做，你獲得技能“展驥”。
songsang = sgs.CreateTriggerSkill{
	name = "songsang",
	events = {sgs.Death},
	frequency = sgs.Skill_Limited,
	limit_mark = "@songsang",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() then return false end
		if player:getMark("@songsang") == 0 then return false end
		if player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox("sp_pangtong","songsang")

			room:removePlayerMark(player, "@songsang")
			if player:isWounded() then
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = 1
				theRecover.who = player
				room:recover(player, theRecover)
			else
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
			end
			room:acquireSkill(player, "zhanji")
		end
		return false
	end
}

sp_pangtong:addSkill(guolun)
sp_pangtong:addSkill(songsang)

if not sgs.Sanguosha:getSkill("zhanji") then skills:append(zhanji) end
sp_pangtong:addRelateSkill("zhanji")


sgs.LoadTranslationTable{
	["sp_pangtong"] = "SP龐統",
	["&sp_pangtong"] = "龐統",
	["guolun"] = "過論",
	[":guolun"] = "出牌階段限一次，你可展示一名其他角色的一張手牌A，然後你可以選擇你的一張牌B。若A的點數：小於B的點數，你與其交換這兩張牌，其摸一張牌；大於B的點數，你與其交換這兩張牌，你摸一張牌。",
	["zhanji"] = "展驥",
	[":zhanji"] = "鎖定技，當你於出牌階段內因摸牌且並非因此技能而得到牌時，你摸一張牌。",
	["songsang"] = "送喪",
	[":songsang"] = "限定技，當其他角色死亡時，若你已受傷，你可以回復1點體力；若你未受傷，你可增加1點體力上限。若如此做，你獲得技能“展驥”。",
	["$guolun1"] = "品过是非，讨评好坏。",
	["$guolun2"] = "若有天下太平时，必讨四海之内才。",
	["$songsang1"] = "送丧至东吴，使命已完。",
	["$songsang2"] = "送丧虽至，吾与孝则得相交。",
	["$zhanji1"] = "公瑾安全至吴，心安之。",
	["$zhanji2"] = "功曹之恩，吾必有展骥之机。",
	["@guolun_choose"] = "你可以選擇一張牌",
}

--太史慈
sp_taishici = sgs.General(extension,"sp_taishici","qun2","4",true)



--擊虛：出牌階段限一次，你可令體力值相同的至少一名其他角色各猜測你的手牌區裡是否有【殺】。系統公佈這些角色各自的選擇和猜測結果。若你的手牌區裡：有【殺】，當你於此階段內使用【殺】選擇目標後，你令所有選擇“否”的角色也成為此【殺】的目標；沒有【殺】，你棄置所有選擇“是”的角色的各一張牌。你摸X張牌（X為猜錯的角色數）。若沒有猜錯的角色，你結束此階段。
jixuCard = sgs.CreateSkillCard{
	name = "jixu",
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and (#targets == 0 or to_select:getHp() == targets[1]:getHp())
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke(self:objectName(), 1)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local slash = "jixu_no"
			for _, card in sgs.qlist(source:getHandcards()) do
				if card:isKindOf("Slash") then
					slash = "jixu_yes"
					break
				end
			end
			local choiceList = {}
			local n = 0
			for _,p in pairs(targets) do
				local choice = room:askForChoice(p, self:objectName(), "jixu_yes+jixu_no")
				ChoiceLog(p, choice)
				if choice ~= slash then
					room:addPlayerMark(p, slash.."_Play")
					n = n + 1
				end
			end
			for _,p in pairs(targets) do
				if slash == "jixu_no" and p:getMark(slash.."_Play") > 0 and source:canDiscard(p, "he") then
					local id = room:askForCardChosen(source, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					if id ~= -1 then
						room:throwCard(id, p, source)
					end
				end
			end
			if n > 0 then
				source:drawCards(n, self:objectName())
			else
				room:setPlayerFlag(source, "Global_PlayPhaseTerminated")
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

jixuVS = sgs.CreateZeroCardViewAsSkill{
	name = "jixu",
	view_as = function(self,cards)
		return jixuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#jixu") < 1
	end
}

jixu = sgs.CreateTriggerSkill{
	name = "jixu",
	view_as_skill = jixuVS,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.from:hasUsed("#"..self:objectName()) and use.card and use.card:isKindOf("Slash") then
			room:broadcastSkillInvoke(self:objectName(), 2)
			for _, p in sgs.qlist(room:getOtherPlayers(use.from)) do
				if p:getMark("jixu_yes_Play") > 0 and not use.to:contains(p) and not room:isProhibited(use.from, p, use.card) then
					room:doAnimate(1, use.from:objectName(), p:objectName())
					use.to:append(p)


						local msg = sgs.LogMessage()
						msg.type = "#Jixu"
						msg.from = player
						msg.to:append(p)
						msg.arg = use.card:objectName()
						room:sendLog(msg)
				end
			end
			room:sortByActionOrder(use.to)
			data:setValue(use)
		end
		return false
	end
}

sp_taishici:addSkill(jixu)

sgs.LoadTranslationTable{
	["sp_taishici"] = "SP太史慈",
	["&sp_taishici"] = "太史慈",
	["jixu"] = "擊虛",
	[":jixu"] = "當出牌階段限一次，你可令體力值相同的至少一名其他角色各猜測你的手牌區裡是否有【殺】。系統公佈這些角色各自的選擇和猜測結果。若你的手牌區裡：有【殺】，當你於此階段內使用【殺】選擇目標後，你令所有選擇“否”的角色也成為此【殺】的目標；沒有【殺】，你棄置所有選擇“是”的角色的各一張牌。你摸X張牌（X為猜錯的角色數）。若沒有猜錯的角色，你結束此階段。",
	["#Jixu"] = "%from 的技能 “<font color=\"yellow\"><b>擊虛</b></font>”影響， %arg 額外增加了目標 %to",
	["jixu_yes"] = "猜測有殺",
	["jixu_no"] = "猜測無殺",

	["#JixuResult"] = "%from “<font color=\"yellow\"><b>擊虛</b></font>” %arg",
	["JixuFinal_true"] = "有殺",
	["JixuFinal_false"] = "沒有殺",
}
--潘濬
panjun = sgs.General(extension, "panjun", "wu2", 3, true)

guanwei = sgs.CreateTriggerSkill{
	name = "guanwei", 
	events = {sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and not player:hasFlag(self:objectName()..p:objectName()) and player:getMark("used_Play") > 1 and player:getMark("guanwei_break-Clear") == 0 and room:askForCard(p, "..", "@guanwei", data, self:objectName()) then
				room:setPlayerFlag(player, self:objectName()..p:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2, self:objectName())
				local thread = room:getThread()
				local change = sgs.PhaseChangeStruct()
				change.from = sgs.Player_Play
				change.to = sgs.Player_Play
				local _data = sgs.QVariant()
				_data:setValue(change)
				room:broadcastProperty(player, "phase")
				if not thread:trigger(sgs.EventPhaseChanging, room, player, _data) then
					if not thread:trigger(sgs.EventPhaseStart, room, player) then
						thread:trigger(sgs.EventPhaseProceeding, room, player)
					end
					thread:trigger(sgs.EventPhaseEnd, room, player)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

--公清
gongqing = sgs.CreateTriggerSkill{
	name = "gongqing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.from:getAttackRange() < 3 and damage.damage > 1 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 1)
			damage.damage = 1
		elseif damage.from and damage.from:getAttackRange() > 3 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName(), 2)
			damage.damage = damage.damage + 1
		end
		data:setValue(damage)
		return false
	end
}

panjun:addSkill(guanwei)
panjun:addSkill(gongqing)

sgs.LoadTranslationTable{
["panjun"] = "潘濬",
["#panjun"] = "方嚴嫉惡",
["illustrator:panjun"] = "秋呆呆",
["guanwei"] = "觀微",
["@guanwei"] = "你可以棄置一張牌發動“觀微”<br/> <b>操作提示</b>: 選擇一張牌→點擊確定<br/>",
[":guanwei"] = "一名角色的出牌階段結束時，若其於此階段內使用過的牌數大於1且其於此回合內使用過的牌的花色均相同且你於此回合內未發動過此技能，你可以棄置一張牌，其摸兩張牌，然後其執行一個額外的出牌階段。",
["$guanwei1"] = "今日宴請諸位，有要事相商。",
["$guanwei2"] = "天下未定，請主公以大局為重。",
["gongqing"] = "公清",
[":gongqing"] = "鎖定技，當你受到傷害時，若來源的攻擊範圍：小於3，傷害值為1；大於3，傷害值+1。",
["$gongqing1"] = "爾輩何故與降擄交善！",
["$gongqing2"] = "豪將在外，增兵必成禍患啊！",
["~panjun"] = "恥失荊州……恥失荊州啊！",
}

--嚴畯
yanjun = sgs.General(extension, "yanjun", "wu2", 3, true)

function ChoiceLog(player, choice, to)
	local log = sgs.LogMessage()
	log.type = "#choice"
	log.from = player
	log.arg = choice
	if to then
		log.to:append(to)
	end
	player:getRoom():sendLog(log)
end

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

function lazy(self, room, player, choice, open, n)
	skill(self, room, player, open, n)
	ChoiceLog(player, choice)
end

function fakeNumber(x)
	if type(x) == "number" then
		if x == 1 then
			return "A"
		elseif x == 11 then
			return "J"
		elseif x == 12 then
			return "Q"
		elseif x == 13 then
			return "K"
		end
		return tostring(x)
	else
		if x == "heart" then
			return 1
		elseif x == "diamond" then
			return 2
		elseif x == "spade" then
			return 3
		elseif x == "club" then
			return 4
		else
			return 5
		end
	end
	return "Mei You Kuai Gun"
end

guanchao = sgs.CreateTriggerSkill{
	name = "guanchao",
	global = true,
	events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and RIGHT(self, player) then
			local choice = room:askForChoice(player, self:objectName(), "guanchao1+guanchao2+cancel")
			if choice ~= "cancel" then
				lazy(self, room, player, choice, true, 1)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerFlag(player, choice)
					local log = sgs.LogMessage()
					log.from = player
					log.type = "#"..choice
					room:sendLog(log)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if card and not card:isKindOf("SkillCard") then
				local num = card:getNumber()
				if (player:hasFlag("guanchao1") or player:hasFlag("guanchao2")) and player:getMark(self:objectName().."_break_replay") == 0 and player:getMark("used_Play") > 1 and player:getPhase() == sgs.Player_Play then
					local log = sgs.LogMessage()
					log.from = player
					log.arg = fakeNumber(player:getMark(self:objectName().."_Play")) .. " -> " .. fakeNumber(num)
					log.arg2 = self:objectName()
					if player:hasFlag("guanchao1") then
						if num > player:getMark(self:objectName().."_Play") then
							log.type = "#guanchao_success_1"
							room:broadcastSkillInvoke(self:objectName(), 2)
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								player:drawCards(1, self:objectName())
								room:removePlayerMark(player, self:objectName().."engine")
							end
						else
							log.type = "#guanchao_fail_1"
							room:addPlayerMark(player, self:objectName().."_break_replay")
						end
					elseif player:hasFlag("guanchao2") then
						if num < player:getMark(self:objectName().."_Play") then
							log.type = "#guanchao_success_2"
							room:broadcastSkillInvoke(self:objectName(), 2)
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								player:drawCards(1, self:objectName())
								room:removePlayerMark(player, self:objectName().."engine")
							end
						else
							log.type = "#guanchao_fail_2"
							room:addPlayerMark(player, self:objectName().."_break_replay")
						end
					end
					room:sendLog(log)
				end
				if num > 0 and num < 14 and player:getMark(self:objectName().."_break_replay") == 0 then
					room:setPlayerMark(player, self:objectName().."_Play", num)
				else
					room:addPlayerMark(player, self:objectName().."_break_replay")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

--遜賢
function listIndexOf(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end

xunxian = sgs.CreateTriggerSkill{
	name = "xunxian",
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
		if player:getPhase() == sgs.Player_NotActive and move.from and move.from:objectName() == player:objectName() and (move.to_place == sgs.Player_DiscardPile or (move.to_place == 7 and is_nullification)) and (extract == sgs.CardMoveReason_S_REASON_USE or extract == sgs.CardMoveReason_S_REASON_RESPONSE) then
		--move.to_place == 7 and is_nullification為神殺處理無懈可擊的特殊狀況
			if not room:getCurrent():hasFlag(self:objectName()..player:objectName()) then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do 
					if p:getHandcardNum() > player:getHandcardNum() then
						targets:append(p)
					end
				end
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
					room:setPlayerFlag(room:getCurrent(), self:objectName()..player:objectName())
				end
			end
		end
		return false
	end
}

yanjun:addSkill(guanchao)
yanjun:addSkill(xunxian)

sgs.LoadTranslationTable{
["yanjun"] = "嚴畯",
["#yanjun"] = "志存補益",
["illustrator:yanjun"] = "",
["guanchao"] = "觀潮",
[":guanchao"] = "出牌階段開始時，你可以選擇一項：1.當你於此回合內使用牌時，若你於出牌階段內使用過的牌的點數嚴格遞增，你摸一張牌；2.當你於此回合內使用牌時，若你於出牌階段內內使用過的牌的點數嚴格遞減，你摸一張牌。",
["guanchao1"] = "當你於此回合內使用牌時，若你於出牌階段內使用過的牌的點數嚴格遞增，你摸一張牌",
["guanchao2"] = "當你於此回合內使用牌時，若你於出牌階段內使用過的牌的點數嚴格遞減，你摸一張牌",
["#guanchao1"] = "%from 選擇了 <font color=\"yellow\"><b>遞增</b></font>",
["#guanchao2"] = "%from 選擇了 <font color=\"yellow\"><b>遞減</b></font>",
["#guanchao_success_1"] = "%from 使用的牌點數變化： %arg ，符合遞增，“%arg2”被觸發",
["#guanchao_fail_1"] = "%from 使用的牌點數變化： %arg ，不符合遞增，“%arg2”結算中止",
["#guanchao_success_2"] = "%from 使用的牌點數變化： %arg ，符合遞減，“%arg2”被觸發",
["#guanchao_fail_2"] = "%from 使用的牌點數變化： %arg ，不符合遞減，“%arg2”結算中止",
["$guanchao1"] = "朝夕之間，可知所進退。",
["$guanchao2"] = "月盈，潮起沉暮也；月虧，潮起日半也。",
["xunxian"] = "遜賢",
["xunxian-invoke"] = "你可以發動“遜賢”<br/> <b>操作提示</b>: 選擇一名手牌比你多的角色→點擊確定<br/>",
[":xunxian"] = "每名角色的回合限一次，當你於回合外使用或打出的牌置入棄牌堆時，你可以將之交給一名手牌比你多的角色。",
["$xunxian1"] = "督軍之才，子明強於我甚多。",
["$xunxian2"] = "此間重任，公卿可擔之。",
["~yanjun"] = "著作……還……沒完成……",
}

--張梁
zhangliang = sgs.General(extension, "zhangliang", "qun2", 4, true)

jijun = sgs.CreateTriggerSkill{
	name = "jijun",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecified, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (use.card:isKindOf("Weapon") or not use.card:isKindOf("EquipCard")) and not use.card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play and use.from:objectName() == player:objectName() and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:setPlayerCardLimitation(player, "response", use.card:toString(), false)
					room:setPlayerFlag(player, self:objectName())
					room:judge(judge)
					room:setPlayerFlag(player, "-"..self:objectName())
					room:removePlayerCardLimitation(player, "response", use.card:toString())--myetyet按：zy说被鬼才改之前的判定牌也要置于武将牌上，然而我觉得描述里没这个意思；ZY按：就是有这个意思！！！！！！！！！！！！！
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE and (move.reason.m_skillName == self:objectName() or move.from:hasFlag(self:objectName())) and not move.card_ids:isEmpty() then
				player:addToPile("fang", move.card_ids)
			end
		end
		return false
	end
}

fangtongCard = sgs.CreateSkillCard{
	name = "fangtong",
	will_throw = true,
	filter = function(self, targets, to_select)
		local num = 0
		for _,id in sgs.qlist(self:getSubcards()) do
			num = num + sgs.Sanguosha:getCard(id):getNumber()
		end
		if num == 36 then
			return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets <= 1
	end,
	on_use = function(self, room, source, targets)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _,id in sgs.qlist(self:getSubcards()) do
			if id ~= self:getSubcards():first() then
				dummy:addSubcard(id)
			end
		end
		room:throwCard(self:getSubcards():first(), source, source)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "", self:objectName(), ""), nil)
			if targets[1] then
				room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 3, sgs.DamageStruct_Thunder))
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
fangtongVS = sgs.CreateViewAsSkill{
	name = "fangtong",
	n = 999,
	expand_pile = "fang",
	view_filter = function(self, selected, to_select)
		return sgs.Self:canDiscard(sgs.Self, to_select:getEffectiveId()) and ((#selected == 0 and not sgs.Self:getPile("fang"):contains(to_select:getEffectiveId())) or (#selected > 0 and sgs.Self:getPile("fang"):contains(to_select:getEffectiveId())))
	end,
	view_as = function(self, cards)
		if #cards >= 2 and not sgs.Self:getPile("fang"):contains(cards[1]:getEffectiveId()) then
			local ft = fangtongCard:clone()
			for _, c in ipairs(cards) do
				ft:addSubcard(c)
			end
			ft:setSkillName(self:objectName())
			return ft
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@"..self:objectName()
	end
}
fangtong = sgs.CreateTriggerSkill{
	name = "fangtong",
	events = {sgs.EventPhaseStart},
	view_as_skill = fangtongVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish and player:getPile("fang"):length() > 0 and not player:isNude() then
			player:getRoom():askForUseCard(player, "@".. self:objectName(), "@"..self:objectName())
		end
		return false
	end
}

zhangliang:addSkill(jijun)
zhangliang:addSkill(fangtong)


sgs.LoadTranslationTable{
["zhangliang"] = "張梁",
	["#zhangliang"] = "人公將軍",
	["jijun"] = "集軍",
[":jijun"] = "當你於出牌階段內使用武器牌或不為裝備牌的牌指定目標後，若你為目標，你可以判定，當此判定牌置入棄牌堆後或因此判定的判定牌因其他牌打出代替判定而被置入棄牌堆後，你可以將這些牌置於武將牌上，稱為“方”。",
["fang"] = "方",
["fangtong"] = "方統",
[":fangtong"] = "結束階段開始時，你可以棄置一張牌，將至少一張“方”置入棄牌堆，然後若這些牌的點數之和為36，你對一名其他角色造成3點雷電傷害。",
["@fangtong"] = "你可以發動“方統”",
["~fangtong"] = "選擇一張手牌→選擇至少一張“方”→可選步驟：若“方”的點數之和等於36則選擇一名其他角色→點擊確定",
}


sgs.Sanguosha:addSkills(skills)


