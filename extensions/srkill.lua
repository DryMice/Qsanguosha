module("extensions.srkill", package.seeall)
extension = sgs.Package("srkill")

sgs.LoadTranslationTable{
	["srkill"] = "三國killSR包",	
}
--技能选择，公共技能
sr_choose = sgs.CreateTriggerSkill{
	name = "#sr_choose",
	events = {sgs.GameStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getMark(self:objectName()) == 0 then
			local choices = {}
			local general1 = player:getGeneral()
			if general1:hasSkill(self:objectName()) then	
				local skills = general1:getVisibleSkillList()
				for _,sk in sgs.qlist(skills) do
					if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() and not sk:isLordSkill() then
						table.insert(choices, "lose"..sk:objectName())
					end
				end
				--choices = choices.."losenone"
				local choice = room:askForChoice(player,self:objectName(), table.concat(choices, "+") ,data)
				if choice ~= "losenone" then
					room:addPlayerMark(player, self:objectName())				
					local skill = string.sub(choice,5)
					room:handleAcquireDetachSkills(player,"-"..skill)
					for _, ski in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill)) do
						room:handleAcquireDetachSkills(player,"-"..ski:objectName())
						if ski:objectName() == "sr_zhuizun" then
							room:setPlayerMark(player,"@srzhuizun",0)
						end
					end
				end
			end			
			if player:getGeneral2() then
				local choices = ""	
				local general2 = player:getGeneral2()
				if general2:hasSkill(self:objectName()) then	
					local skills = general2:getVisibleSkillList()
					for _,sk in sgs.qlist(skills) do
						if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() and not sk:isLordSkill() then
							choices = choices.."lose"..sk:objectName().."+"
						end
					end
				end
				choices = choices.."losenone"
				local choice = room:askForChoice(player,self:objectName(),choices,data)
				if choice ~= "losenone" then
					local skill = string.sub(choice,5)
					room:handleAcquireDetachSkills(player,"-"..skill)
					for _, ski in sgs.qlist(sgs.Sanguosha:getRelatedSkills(skill)) do
						room:handleAcquireDetachSkills(player,"-"..ski:objectName())
						if ski:objectName() == "sr_zhuizun" then
							room:setPlayerMark(player,"@srzhuizun",0)
						end
					end
				end
			end
			return false
		end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#sr_choose") then skills:append(sr_choose) end
sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
	["#sr_choose"] = "技能選擇",
}

--SR劉備
sr_liubei = sgs.General(extension,"sr_liubei$","shu",4)

sr_rende = sgs.CreateTriggerSkill{
	name = "sr_rende",
	events = {sgs.EventPhaseEnd},
	--view_as_skill = sr_rendeVS,
	on_trigger = function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local room = player:getRoom()
		local liubei = room:findPlayerBySkillName(self:objectName())
		if not liubei or liubei:isDead() then return false end
		local cards = sgs.IntList()
		for _,card in sgs.qlist(liubei:getHandcards()) do
			cards:append(card:getId())
		end
		local list = sgs.SPlayerList()
		list:append(player)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, liubei:objectName(), "", 
			"sr_rende", "")
		if not liubei:askForSkillInvoke(self:objectName(),data)	then return false end	
		room:broadcastSkillInvoke("sr_rende")		
		if player:objectName()~=liubei:objectName() and not liubei:isKongcheng() then
			room:askForYiji(liubei, cards, self:objectName(),false,false,true,-1,list,
				reason,"#sr_rende:"..player:objectName(),true)
		end 
		room:notifySkillInvoked(liubei, "sr_rende")
		local phase = player:getPhase()

		local msg = sgs.msgMessage()
		msg.type = "#ExtraPlayPhase"
		msg.from = player
		msg.arg = self:objectName()
		room:sendmsg(msg)

		player:setPhase(sgs.Player_Play)
		room:broadcastProperty(player,"phase")
		local thread = room:getThread()
		if not thread:trigger(sgs.EventPhaseStart,room,player) then			
			thread:trigger(sgs.EventPhaseProceeding,room,player)
		end		
		thread:trigger(sgs.EventPhaseEnd,room,player)
		player:setPhase(phase)
		room:broadcastProperty(player,"phase")			
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive() 
	end
}

sr_liubei:addSkill(sr_rende)
	
--仇袭
--仇袭技能
srchouxidummycard = sgs.CreateSkillCard{
	name = "srchouxidummycard",
}
sr_chouxicard = sgs.CreateSkillCard{
	name = "sr_chouxicard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		room:notifySkillInvoked(source, "sr_chouxi")
		local cardIds = sgs.IntList()
		local getcards = {}
		local dummy = srchouxidummycard:clone()
		local card_idxs = room:getNCards(2)
		for _, c in sgs.qlist(card_idxs) do
			cardIds:append(c)
		end
		assert(cardIds:length() == 2)
		local card1 = sgs.Sanguosha:getCard(cardIds:at(0))
		local card2 = sgs.Sanguosha:getCard(cardIds:at(1))
		local type1 = card1:getType()
		local type2 = card2:getType()
--		table.insert(getcards, card1)
--		table.insert(getcards, card2)
		for _,id in sgs.qlist(cardIds) do
			dummy:addSubcard(id)
			table.insert(getcards, id)
		end
		room:setTag("agcards",sgs.QVariant(table.concat( getcards, "+")))
		local move = sgs.CardsMoveStruct()
		move.card_ids = cardIds
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), 
			"", "sr_chouxi", "")
		room:moveCardsAtomic(move, true)
		room:getThread():delay()
		local cando = 0
		local players = room:getOtherPlayers(source)
		local target = room:askForPlayerChosen(source, players, "sr_chouxi")
		local types = {"BasicCard", "EquipCard", "TrickCard"}
		for _, id in sgs.qlist(cardIds) do
			local t = sgs.Sanguosha:getCard(id):getType()
			if t == "basic" then table.removeOne(types, "BasicCard") end
			if t == "equip" then table.removeOne(types, "EquipCard") end
			if t == "trick" then table.removeOne(types, "TrickCard") end
		end
		local card
		if #types ~= 0 then
			card = room:askForCard(target, table.concat(types, ","), "@srchouxi-discard", 
				sgs.QVariant(), sgs.CardDiscarded)
		end
		room:removeTag("agcards")
		if not card then cando = 1 end
		if cando == 1 then

			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			room:damage(damage)
			if target:isAlive() then
				if type1 == type2 then
--					for _,c in pairs(getcards) do
						room:obtainCard(target, dummy, true)
--					end
				else
					room:fillAG(cardIds,target)
					local card_id = room:askForAG(target, cardIds, false, "sr_chouxi")
					room:clearAG(target)
					local effective_card = sgs.Sanguosha:getCard(card_id)
					room:obtainCard(target, effective_card, true)
					cardIds:removeOne(card_id)
					room:obtainCard(source, sgs.Sanguosha:getCard(cardIds:at(0)), true)
				end
			else
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, 
					target:objectName(), "sr_chouxi", "")
				if type1 == type2 then
--					for _,c in pairs(getcards) do
						room:throwCard(dummy, reason, nil)
--					end
				else
					room:fillAG(cardIds,source)
					local card_id = room:askForAG(source, cardIds, false, "sr_chouxi")
					source:invoke("clearAG")
					room:obtainCard(source, card_id, true)
					cardIds:removeOne(card_id)
					room:throwCard(sgs.Sanguosha:getCard(cardIds:at(0)), reason, nil)
				end				
			end
		else
--			for _,c in pairs(getcards) do
				room:obtainCard(source, dummy, true)
--			end
		end	
	end
}
sr_chouxi = sgs.CreateViewAsSkill{
	name = "sr_chouxi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_chouxicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#sr_chouxicard")) and (not player:isKongcheng())
	end
}
sr_liubei:addSkill(sr_chouxi)

--拥兵
sr_yongbing = sgs.CreateTriggerSkill{
	name = "sr_yongbing$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		local srliubeis = sgs.SPlayerList()
		if card and card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					srliubeis:append(p)
				end
			end
			while not srliubeis:isEmpty() do
				local srliubei = room:askForPlayerChosen(player, srliubeis, self:objectName(), 
					"@sr_yongbing-to", true)
				if srliubei then
					room:notifySkillInvoked(srliubei, "sr_yongbing")
					room:broadcastSkillInvoke("sr_yongbing")
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = srliubei
					log.arg = self:objectName()
					room:sendLog(log)
					srliubei:drawCards(1)
					srliubeis:removeOne(srliubei)
				else
					break
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "shu")
	end
}
sr_liubei:addSkill(sr_yongbing)
sr_liubei:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_liubei"] = "SR劉備",
["&sr_liubei"] = "劉備",
["sr_rende"] = "仁德",
[":sr_rende"] = "任一角色的回合結束階段結束時，你可以將任意數量的手牌交給該角色 然後該角色進行一個額外"..
"的出牌階段",
["#sr_rende"] = "請選擇任意張手牌交給 %src(也可以不給)",
["sr_chouxi"] = "仇襲",
["sr_chouxicard"] = "仇襲",
["@srchouxi-discard"] = "請你棄置一張與之均不同類別的牌",
[":sr_chouxi"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置一張手牌並展示牌堆頂的"..
"兩張牌，然後令一名其他角色選擇一項：棄置一張與之均不同類別的牌，然後令你獲得這些牌；或者受到你造成的1"..
"點傷害並獲得其中一種類別的牌，然後你獲得其餘的牌",
["sr_yongbing"] = "擁兵",
["@sr_yongbing-to"] = "請選擇一名角色使其發動“擁兵”。",
[":sr_yongbing"] = "<font color=\"orange\"><b>主公技，</b></font>當一名其他蜀勢力角色使用【殺】造成一次"..
"傷害後，該角色可令你摸一張牌。",
["$sr_rende"] = "以德服人",
["$sr_chouxi1"] = "不滅東吳 誓不歸蜀！",
["$sr_chouxi2"] = "害我兄弟之仇，不共戴天！",
["$sr_yongbing"] = "擁兵安民，以固國之根本。",
["~sr_liubei"] = "雲長翼德，久等了！",
["losesr_chouxi"] = "失去【仇襲】",
["losesr_rende"] = "失去【仁德】",
["losenone"] = "使用全部技能",
}

--SR黄月英
sr_huangyueying = sgs.General(extension,"sr_huangyueying","shu",3,false)

--授计
sr_shoujicard = sgs.CreateSkillCard{
	name = "sr_shoujicard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			local id = self:getSubcards():first()
			local suit = sgs.Sanguosha:getCard(id):getSuit()
			if suit == sgs.Card_Spade then
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				return not targets[1]:isProhibited(to_select, duel)
			elseif suit == sgs.Card_Club then
				if to_select:getWeapon() ~= nil then
					local collateral = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
					return not targets[1]:isProhibited(to_select, collateral)
				end
			elseif suit == sgs.Card_Heart then
				if targets[1]:distanceTo(to_select) == 1 then
					if not to_select:isAllNude() then
						local snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0)
						return not targets[1]:isProhibited(to_select, snatch)
					end
				end
			elseif suit == sgs.Card_Diamond then
				if not to_select:isKongcheng() then
					local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
					return not targets[1]:isProhibited(to_select, fire_attack)
				end
			end
		elseif #targets == 2 then
			return false
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
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
		room:broadcastSkillInvoke("sr_shouji")
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, huangyueying:objectName(), 
			"", "sr_shouji", "")
		room:moveCardTo(self, huangyueying, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, huangyueying, data)
		thread:trigger(sgs.CardFinished, room, huangyueying, data)
	end,
	on_use = function(self, room, source, targets)		
		local from = targets[1]
		local to = targets[2]			
		room:notifySkillInvoked(source, "sr_shouji")
		local id = self:getSubcards():first()
		local suit = sgs.Sanguosha:getCard(id):getSuit()
		if suit == sgs.Card_Spade then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("sr_shouji")
			local use = sgs.CardUseStruct()
			use.card = duel
			use.from = from
		   	use.to:append(to)
			room:useCard(use)
			--source:removeTag("sr_shoujitarget")
		elseif suit == sgs.Card_Club then
			local slashees = sgs.SPlayerList()
			local slashee = nil
			for _,p in sgs.qlist(room:getOtherPlayers(to)) do
				if to:canSlash(p,true) then
					slashees:append(p)
				end
			end
			if not slashees:isEmpty() then
				room:notifySkillInvoked(source, "sr_shouji")
				slashee = room:askForPlayerChosen(from,slashees,"sr_shouji")
			else
				room:obtainCard(source, self, true)					
			end
			if slashee then
				local collateral = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
				collateral:setSkillName("sr_shouji")
				local use = sgs.CardUseStruct()
				use.card = collateral
				use.from = from
				use.to:append(to)
				use.to:append(slashee)
				room:useCard(use)					
			end
			--source:removeTag("luashoujitarget")				
		elseif suit == sgs.Card_Heart then
			if not to:isAllNude() then
				local snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, 0)
				snatch:setSkillName("sr_shouji")
				local use = sgs.CardUseStruct()
				use.card = snatch
				use.from = from
				use.to:append(to)
				room:useCard(use)
				--source:removeTag("sr_shoujitarget")					
			else
				room:obtainCard(source, self, true)					
			end
		elseif suit == sgs.Card_Diamond then				
			local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
			fire_attack:setSkillName("sr_shouji")
			local use = sgs.CardUseStruct()
			use.card = fire_attack
			use.from = from
		   	use.to:append(to)
			room:useCard(use)
			--source:removeTag("sr_shoujitarget")				
		end			
	end	
}
			
--视为技
sr_shouji = sgs.CreateViewAsSkill{
	name = "sr_shouji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected==0
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = sr_shoujicard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())			
			return card
		end
	end,
	enabled_at_play = function(self, player)		
		return not player:hasUsed("#sr_shoujicard")
	end
}
sr_huangyueying:addSkill(sr_shouji)

--合谋

-- sr_hemou = sgs.CreateTriggerSkill{
-- 	name = "sr_hemou", 
-- 	frequency = sgs.Skill_NotFrequent, 
-- 	events = {sgs.Damage,sgs.EventPhaseChanging},  
-- 	on_trigger = function(self, event, player, data)
-- 		if event == sgs.EventPhaseChanging then 
-- 			local change = data:toPhaseChange()
-- 			if change.from ~= sgs.Player_Play then return false end
-- 			if player:hasFlag("hemouused") then
-- 				player:getRoom():setPlayerFlag(player,"-hemouused")
-- 			end
-- 		else
-- 			local damage = data:toDamage()
-- 			local room = player:getRoom()
-- 			local srhuangyueying = room:findPlayerBySkillName(self:objectName())
-- 			if not srhuangyueying then return false end
-- 			if not srhuangyueying:hasSkill(self:objectName())then return false end
-- 			if player:objectName() == srhuangyueying:objectName() then return false end
-- 			if srhuangyueying:isKongcheng() then return false end
-- 			local current = room:getCurrent()
-- 			if not current or current:getPhase() ~= sgs.Player_Play or current:hasFlag("hemouused") then 
--return false end
-- 			if damage.card and damage.card:isKindOf("Slash") then return false end 				
-- 			local card = room:askForCard(srhuangyueying, ".", "@srhemou-discard", data, sgs.CardDiscarded)
-- 			if card then
-- 				room:setPlayerFlag(current,"hemouused")
-- 				room:notifySkillInvoked(srhuangyueying, "sr_hemou")
-- 				room:broadcastSkillInvoke("sr_hemou")
-- 				local log = sgs.LogMessage()
-- 				log.type = "#TriggerSkill"
-- 				log.from = srhuangyueying
-- 				log.arg = self:objectName()
-- 				room:sendLog(log)
-- 				local targets = sgs.SPlayerList()
-- 				targets:append(srhuangyueying)
-- 				targets:append(player)
-- 				room:sortByActionOrder(targets)
-- 				for _,p in sgs.qlist(targets) do
-- 					p:drawCards(1)
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self, target)		
-- 		return target and target:isAlive()
-- 	end
-- }
sr_hemouvs = sgs.CreateViewAsSkill{
	name = "sr_hemouvs",
	n = 1,
	view_filter = function(self,selected,to_select)		
		local n = sgs.Self:getMark("hemousuit")
		if n<=0 or #selected~=0 then return false end
		if to_select:isEquipped() then return false end
		if n == 1 then
			return to_select:getSuit() == sgs.Card_Spade
		elseif n == 2 then
			return to_select:getSuit() == sgs.Card_Club
		elseif n == 3 then
			return to_select:getSuit() == sgs.Card_Heart
		elseif n == 4 then
			return to_select:getSuit() == sgs.Card_Diamond
		else
			return false
		end
	end,
	view_as = function(self,cards)
		if #cards~=1 then return nil end
		local suit = cards[1]:getSuit()
		local number = cards[1]:getNumber()
		local card = nil
		if suit == sgs.Card_Spade then
			card = sgs.Sanguosha:cloneCard("duel",suit,number)
		elseif suit == sgs.Card_Club then
			card = sgs.Sanguosha:cloneCard("collateral",suit,number)
		elseif suit == sgs.Card_Heart then
			card = sgs.Sanguosha:cloneCard("snatch",suit,number)
		elseif suit == sgs.Card_Diamond then
			card = sgs.Sanguosha:cloneCard("fire_attack",suit,number)
		else
			return nil
		end
		if not card then return nil end
		card:addSubcard(cards[1])
		card:setSkillName("sr_hemouvs")		
		return card
	end,
	enabled_at_play = function(self,player)
		return player:getMark("hemousuit")>0 and not player:isKongcheng()
	end
}

sr_hemou = sgs.CreateTriggerSkill{
	name = "sr_hemou",
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then				
				local yueying = room:findPlayerBySkillName(self:objectName())
				if not yueying or yueying:isDead() or yueying:isKongcheng() then return false end
				--if not yueying:askForSkillInvoke(self:objectName(),data) then return false end		
				local card = room:askForCard(yueying,".","@sr_hemou:"..player:objectName(),sgs.QVariant(),
					sgs.Card_MethodNone)
				if not card then return false end
				room:notifySkillInvoked(yueying,"sr_hemou")
				room:broadcastSkillInvoke("sr_hemou")
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,yueying:objectName(),
					player:objectName(),self:objectName(),nil)
				local move = sgs.CardsMoveStruct(card:getEffectiveId(),yueying,player,sgs.Player_PlaceHand,
					sgs.Player_PlaceHand,reason)
				room:moveCardsAtomic(move,true)
				room:setPlayerMark(player,"hemousuit",tonumber(card:getSuit())+1)
				room:handleAcquireDetachSkills(player,"sr_hemouvs")
			else
				if player:getMark("hemousuit")> 0 then
					room:setPlayerMark(player,"hemousuit",0)
				end
				if player:hasSkill("sr_hemouvs") then
					room:handleAcquireDetachSkills(player,"-sr_hemouvs")
				end
			end
		else
			local use = data:toCardUse()
			if use.card:getSkillName() == "sr_hemouvs" then
				if use.from and use.from:isAlive() then
					if use.from:getMark("hemousuit")> 0 then
						room:setPlayerMark(use.from,"hemousuit",0)
					end
					if use.from:hasSkill("sr_hemouvs") then
						room:handleAcquireDetachSkills(use.from,"-sr_hemouvs")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and not target:hasSkill(self:objectName())
	end
}
sr_huangyueying:addSkill(sr_hemou)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sr_hemouvs") then skills:append(sr_hemouvs) end
sgs.Sanguosha:addSkills(skills)
--奇才
-- sr_qicai = sgs.CreateTriggerSkill{
-- 	name = "sr_qicai",  
-- 	frequency = sgs.Skill_NotFrequent, 
-- 	events = {sgs.DamageCaused,sgs.DamageInflicted},  
-- 	on_trigger = function(self, event, player, data) 
-- 		local room = player:getRoom()
-- 		local damage = data:toDamage()
-- 		if event == sgs.DamageCaused then
-- 			local target = damage.to
-- 			if target then
-- 				if target:getEquips():length() > 0 and player:canDiscard(target,"e") then
-- 					if player:askForSkillInvoke(self:objectName(), data) then
-- 						room:notifySkillInvoked(player, "sr_qicai")
-- 						room:broadcastSkillInvoke("sr_qicai")
-- 						local card_id = room:askForCardChosen(player, target, "e", self:objectName())
-- 						room:throwCard(card_id,target, player)
-- 						local msg = sgs.LogMessage()
-- 						msg.type = "#DefendDamage"
-- 						msg.from = player
-- 						msg.to:append(damage.to)
-- 						msg.arg = self:objectName()
-- 						msg.arg2 = "normal_nature"
-- 						room:sendLog(msg)
-- 						return true
-- 					end
-- 				end
-- 			end
-- 		elseif event == sgs.DamageInflicted then
-- 			local source = damage.from
-- 			if source then
-- 				if player:getEquips():length() > 0 and source:canDiscard(player,"e") then
-- 					if player:askForSkillInvoke(self:objectName(), data) then
-- 						room:notifySkillInvoked(player, "sr_qicai")
-- 						room:broadcastSkillInvoke("sr_qicai")
-- 						local card_id = room:askForCardChosen(source, player, "e", self:objectName())
-- 						room:throwCard(card_id,player, source)
-- 						local msg = sgs.LogMessage()
-- 						msg.type = "#AvoidDamage"
-- 						msg.from = player
-- 						msg.to:append(damage.from)
-- 						msg.arg = self:objectName()
-- 						msg.arg2 = "normal_nature"
-- 						room:sendLog(msg)
-- 						return true
-- 					end
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end
-- }

--[[
sr_qicai = sgs.CreateTriggerSkill{
	name = "sr_qicai",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()		
		local move = data:toMoveOneTime()
		if not move.from or not move.from:hasSkill(self:objectName()) or 
			move.from:objectName() ~= player:objectName() then return false end
		if not move.from_places:contains(sgs.Player_PlaceHand) then return false end
		if not player:askForSkillInvoke(self:objectName(),data) then return false end
		room:notifySkillInvoked(player,"sr_qicai")
		room:broadcastSkillInvoke("sr_qicai")		
		local reason = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if reason == sgs.CardMoveReason_S_REASON_USE then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.negative = false
			judge.play_animation = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			local card = judge.card
			if judge:isGood() then 
				player:drawCards(1)
			end
		else
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.negative = false
			judge.play_animation = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			local card = judge.card
			if judge:isGood() then 
				player:drawCards(1)
			end
		end
		return false
	end
}
]]--

sr_qicai = sgs.CreateTriggerSkill{
	name = "sr_qicai",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if not room:getTag("FirstRound"):toBool() and move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.negative = false
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				local card = judge.card
				if judge:isGood() then 
					player:drawCards(1, self:objectName())
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
	end
}

sr_huangyueying:addSkill(sr_qicai)
sr_huangyueying:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_huangyueying"] = "SR黃月英",
["&sr_huangyueying"] = "黃月英",
["sr_shouji"] = "授計",
[":sr_shouji"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置一張牌並選擇兩名角色，然後"..
"根據你棄置牌的花色，視為其中一名你選擇的角色對另一名角色使用一張牌：<font color=\"black\"><b>♠</b></font>" ..
"【決鬥】，<font color=\"black\"><b>♣</b></font>【借刀殺人】，<font color=\"red\"><b>♥</b>< /font>【順手牽羊"..
"】，<font color=\"red\"><b>♦</b></font>【火攻】。<font color=\"red\"><b>（選擇第一個角色作為使用來源，選擇"..
"第二個角色作為被使用目標）</b></font>",
["sr_hemou"] = "合謀",
--["@srhemou-discard"] = "你可以棄置一張手牌，然後與其各摸一張牌",
--[":sr_hemou"] = "每當一名其他角色造成一次不為【殺】的傷害後，你可以棄置一張手牌，然後與其各摸一張牌"..
--"（一名角色的出牌階段限一次）",
[":sr_hemou"] = "其他角色的出牌階段開始時，你可以將一張手牌正面朝上交給該角色，該角色本階段限一次，可將一張"..
"與之相同花色的手牌按下列規則使用：<font color=\"black\"><b>♠</b></font>【決鬥】，<font color=\"black\">< b>♣"..
"</b></font>【借刀殺人】，<font color=\"red\"><b>♥</b></font>【順手牽羊】，<font color=\"red\">< b>♦</b></fon"..
"t>【火攻】。 ",
["@sr_hemou"] = "你可以發動【合謀】交給 %src 一張手牌",
["sr_hemouvs"] = "合謀",
[":sr_hemouvs"] ="<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將一張手牌按如下方式使用："..
"<font color=\"black\"><b>♠</b></font>當【決鬥】，<font color=\"black\"><b>♣</b></font>當【借刀殺人】，"..
"<font color=\"red\"><b>♥</b></font>當【順手牽羊】，<font color=\"red\"><b>♦</b></font>當【火攻】。",
["sr_qicai"] = "奇才",
-- [":sr_qicai"] = "你可以防止你造成的一次傷害，改為棄置對方裝備區的一張牌；你可以防止你受到的一次傷害，"..
--"改為傷害來源棄置你裝備區的一張牌。",
[":sr_qicai"] = "每當你失去一次手牌時，你可以進行判定，若結果為紅色，你摸一張牌。",
["$sr_shouji"] = "還記得我給你的錦囊嗎？",
["$sr_hemou"] = "一起度過這道難關吧！",
["$sr_qicai"] = "盡在我們掌握之中。",
["~sr_huangyueying"] = "孔明大人，請一定要贏~",
["losesr_hemou"] = "失去【合謀】",
["losesr_qicai"] = "失去【奇才】",
["losesr_shouji"] = "失去【授計】",
}

--SR馬超
sr_machao = sgs.General(extension, "sr_machao", "shu", 4)

--奔袭
sr_benxi = sgs.CreateTriggerSkill{
	name = "sr_benxi", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed, sgs.SlashProceed},
	on_trigger = function(self, event, player, data) 
		if event == sgs.TargetConfirmed then
			local room = player:getRoom()
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			local targets = use.to
			if card:isKindOf("Slash") then
				if source:hasSkill(self:objectName()) then
					if targets:contains(player) then
						room:notifySkillInvoked(source, "sr_benxi")
						room:broadcastSkillInvoke("sr_benxi")
						room:sendCompulsoryTriggerLog(source, self:objectName())
						local discard = room:askForCard(player,"EquipCard", "@srbenxi-discard", data, 
							sgs.CardDiscarded)
						if not discard then
							room:setCardFlag(card, "srbenxiflag")
						end
					end
				end
			end
		elseif event == sgs.SlashProceed then
			if player:hasSkill(self:objectName()) then
				local room = player:getRoom()
				local effect = data:toSlashEffect()
				if effect.slash:hasFlag("srbenxiflag") then
					room:slashResult(effect, nil)	
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

sr_benxitm = sgs.CreateDistanceSkill{
	name = "#sr_benxitm",
	correct_func = function(self, from, to)
		if from:hasSkill("sr_benxi") then
			return -1
		end
	end,
}
sr_machao:addSkill(sr_benxi)
sr_machao:addSkill(sr_benxitm)
extension:insertRelatedSkills("sr_benxi","#sr_benxitm")

--邀战
sr_yaozhancard = sgs.CreateSkillCard{
	name = "sr_yaozhancard", 
	target_fixed = false, 
	will_throw = false, 
	-- filter = function(self, targets, to_select)
	-- 	if #targets < 1 then
	-- 		if to_select:objectName() ~= sgs.Self:objectName() then
	-- 			if not to_select:isKongcheng() then
	-- 				local weapon = sgs.Self:getWeapon()
	-- 				if weapon and weapon:getEffectiveId() == self:getEffectiveId() then
	-- 					return sgs.Self:distanceTo(to_select) == 1
	-- 				else
	-- 					local horse = sgs.Self:getOffensiveHorse()
	-- 					if horse and horse:getEffectiveId() == self:getEffectiveId() then
	-- 						return sgs.Self:distanceTo(to_select, 1) <= sgs.Self:getAttackRange()
	-- 					else
	-- 						return sgs.Self:distanceTo(to_select) <= sgs.Self:getAttackRange()
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- 	return false
	-- end,
	filter = function(self, targets, to_select)
		return not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_yaozhan")
		local success = source:pindian(targets[1], "sr_yaozhan", self)
		if success then			
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("sr_yaozhancard")
			if source:canSlash(targets[1],slash,false) then
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = source
				card_use.to:append(targets[1])
				room:useCard(card_use, false)
			end
		else
			if targets[1]:canSlash(source,false) then
				room:askForUseSlashTo(targets[1], source, "@slash_can")
			end
		end
	end,
}
sr_yaozhan = sgs.CreateViewAsSkill{
	name = "sr_yaozhan", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_yaozhancard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#sr_yaozhancard")) and (not player:isKongcheng())
	end,
}
sr_machao:addSkill(sr_yaozhan)

sr_machao:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_machao"] = "SR馬超",
["&sr_machao"] = "馬超",
["sr_benxi"] = "奔襲",
["@srbenxi-discard"] = "請棄置一張裝備牌，否則此【殺】不可被【閃】響應",
--[":sr_benxi"] = "<font color=\"blue\"><b>鎖定技，</b></font>你使用【殺】選擇目標後，目標角色須棄"..
--"置一張裝備牌，否則此【殺】不可被【閃】響應。",
[":sr_benxi"] = "<font color=\"blue\"><b>鎖定技，</b></font>你計算與其他角色的距離時始終-1；<font"..
" color=\"blue\"><b>鎖定技，</b></font>你使用【殺】選擇目標後，目標角色須棄置一張裝備牌，否則此【殺】"..
"不可被【閃】響應。",
["sr_yaozhan"] = "邀戰",
["sr_yaozhancard"] = "邀戰",
["@slash_can"] = "你可以對拼點沒贏的一方使用一張【殺】",
-- [":sr_yaozhan"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以與你攻擊範圍內的一名"..
--"其他角色拼點：若你贏，視為對其使用一張【殺】（此【殺】不計入每回合的使用限制）；若你沒贏，該角色"..
--"可以對你使用一張【殺】。",
[":sr_yaozhan"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以與一名其他角色拼點：若你贏，視為對"..
"其使用一張【殺】（此【殺】不計入每回合的使用限制）；若你沒贏，該角色可以對你使用一張【殺】。",
["$sr_benxi"] = "全軍突擊！",
["$sr_yaozhan"] = "堂堂正正的打一場吧！",
["~sr_machao"] = "可惡，絕不輕饒！",
["losesr_benxi"] = "失去【奔襲】",
["losesr_yaozhan"] = "失去【邀戰】",
}

--SR關羽
sr_guanyu = sgs.General(extension, "sr_guanyu", "shu", 4)

--温酒
--温酒视为技
sr_wenjiucard = sgs.CreateSkillCard{
	name = "sr_wenjiucard", 
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_wenjiu")
		local ids = self:getSubcards()
		for _,id in sgs.qlist(ids) do
			source:addToPile("@srjiu", id, true)
		end
	end
}
sr_wenjiuVS = sgs.CreateViewAsSkill{
	name = "sr_wenjiu", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if 	not to_select:isEquipped() then
			return to_select:isBlack()
		end
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_wenjiucard:clone()
			card:addSubcard(cards[1]:getId())
			card:setSkillName(self:objectName())
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:isKongcheng()then
			return not player:hasUsed("#sr_wenjiucard")
		end
		return false
	end
}

sr_wenjiu = sgs.CreateTriggerSkill{
	name = "sr_wenjiu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.ConfirmDamage,sgs.SlashMissed,sgs.CardFinished},
	view_as_skill = sr_wenjiuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then			
			local use = data:toCardUse()
			local source = use.from
			if not source then return false end
			if source:objectName() == player:objectName() then
				local card = use.card
				if card:isKindOf("Slash") then
					if player:getPile("@srjiu"):length() >= 1 then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:notifySkillInvoked(player, "sr_wenjiu")
							room:broadcastSkillInvoke("sr_wenjiu")
							local cards = player:getPile("@srjiu")
							local card_id = -1
							if cards:length() == 1 then
								card_id = cards:first()
							else
								room:fillAG(cards, player)
								card_id = room:askForAG(player, cards, true, self:objectName())
								room:clearAG()
							end
							if card_id ~= -1 then
								local cardthrow = sgs.Sanguosha:getCard(card_id)
								room:throwCard(cardthrow, nil,player)
								room:setPlayerMark(player, "wenjiuslash", 1)
							end
						end
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local slash = damage.card
			if player:getMark("wenjiuslash") > 0 then
				if slash and slash:isKindOf("Slash") then
					damage.damage = damage.damage + 1
					room:notifySkillInvoked(player, "sr_wenjiu")
					room:broadcastSkillInvoke("sr_wenjiu")
					local msg = sgs.LogMessage()
					msg.type = "#IncreaseDamage"
					msg.from = player
					msg.to:append(damage.to)
					msg.arg = self:objectName()					
					room:sendLog(msg)
					data:setValue(damage)
				end
			end
		elseif event == sgs.SlashMissed then
			if player:getMark("wenjiuslash") > 0 then
				room:notifySkillInvoked(player, "sr_wenjiu")
				room:broadcastSkillInvoke("sr_wenjiu")
				player:drawCards(1)
			end
		elseif event == sgs.CardFinished then
			local room = player:getRoom()
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") then
				if player:getMark("wenjiuslash") > 0 then
					room:setPlayerMark(player, "wenjiuslash", 0)
				end
			end
		-- elseif event == sgs.EventLoseSkill then
		-- 	if data:toString() == "sr_wenjiu" then
		-- 		player:clearOnePrivatePile("@srjiu")
		-- 	end
		end
		return false
	end	
}
sr_guanyu:addSkill(sr_wenjiu)

--水袭
--水袭技能卡
sr_shuixicard = sgs.CreateSkillCard{
	name = "sr_shuixicard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_shuixi")
		room:showCard(source, self:getEffectiveId())
		room:getThread():delay()
		local target = targets[1]
		local pattern = ""
		local suit = self:getSuit()
		if suit == sgs.Card_Spade then
			pattern = ".S"
		elseif suit == sgs.Card_Heart then
			pattern = ".H"
		elseif suit == sgs.Card_Club then
			pattern = ".C"
		elseif suit == sgs.Card_Diamond then
			pattern = ".D"
		end	
		local suitstring = self:getSuitString()	
		local srthrowcard = room:askForCard(target, pattern, "@srshuixithrow",sgs.QVariant(suitstring), 
			sgs.CardDiscarded)
		if not srthrowcard then
			room:loseHp(target)
			room:setPlayerCardLimitation(source, "use", "Slash", true)
		end		
	end
}
--水袭视为技
sr_shuixivs = sgs.CreateViewAsSkill{
	name = "sr_shuixi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_shuixicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sr_shuixi"
	end
}
--水袭触发技
sr_shuixi = sgs.CreateTriggerSkill{
	name = "sr_shuixi", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	view_as_skill = sr_shuixivs, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart then
			local room = player:getRoom()
			if not player:isKongcheng() then				
				room:askForUseCard(player, "@@sr_shuixi", "@srshuixicard")
			end
		end
		return false
	end
}
sr_guanyu:addSkill(sr_shuixi)

-- guanyuchoose = sgs.CreateTriggerSkill{
-- 	name = "#guanyuchoose",
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local choice = room:askForChoice(player,self:objectName(),"losewenjiu+loseshuixi+losenone",data)
-- 		if choice == "losewenjiu" then
-- 			room:handleAcquireDetachSkills(player,"-sr_wenjiu")
-- 		elseif choice == "loseshuixi" then
-- 			room:handleAcquireDetachSkills(player,"-sr_shuixi")
-- 		else
-- 			return false
-- 		end
-- 		return false
-- 	end
-- }

sr_guanyu:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_guanyu"] = "SR關羽",
["&sr_guanyu"] = "關羽",
["sr_wenjiu"] = "溫酒",
["@srjiu"] = "酒",
["#sr_wenjiubuff"] = "溫酒",
[":sr_wenjiu"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將一張黑色手牌置於你的武將牌" ..
"上，稱為“酒”。當你使用【殺】選擇目標後，你可以將一張“酒”置入棄牌堆，然後當此【殺】造成傷害時，該傷害+1；"..
"當此【殺】被【閃】響應後，你摸一張牌。",
["#IncreaseDamage"] = "%from的技能【%arg】被觸發，其對 %to 造成的傷害 +1",
["sr_shuixi"] = "水襲",
["@srshuixicard"] = "你可以發動“水襲”",
["~sr_shuixi"] = "請選擇一張手牌，然後選擇一名有手牌的其他角色，最後點擊確定",
["@srshuixithrow"] = "請棄置一張與之相同花色的手牌，否則失去1點體力",
[":sr_shuixi"] = "回合開始階段開始時，你可以展示一張手牌並選擇一名有手牌的其他角色，令其選擇一項：棄置一"..
"張與之相同花色的手牌，或失去1點體力。若該角色因此法失去體力，則此回合的出牌階段，你不能使用【殺】。",
["$sr_wenjiu1"] = "關某願取其首級，獻於帳下。",
["$sr_wenjiu2"] = "酒且放下 關某去去就來！",
["$sr_shuixi"] = "聽聽這江河的咆哮吧！",
["~sr_guanyu"] = "必將盡行大義，以示後人。",
["losesr_wenjiu"] = "失去【溫酒】",
["losesr_shuixi"] = "失去【水襲】",
}

--SR諸葛亮
sr_zhugeliang = sgs.General(extension, "sr_zhugeliang", "shu", 3)

--三分
sr_sanfencard = sgs.CreateSkillCard{
	name = "sr_sanfencard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName()		
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	about_to_use = function(self, room, cardUse)
		local zhugeliang = cardUse.from	

		local l = sgs.LogMessage()
		l.from = zhugeliang
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)

		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		
		thread:trigger(sgs.PreCardUsed, room, zhugeliang, data)
		--room:notifySkillInvoked(zhugeliang,"sr_sanfen")
		room:broadcastSkillInvoke("sr_sanfen")
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, zhugeliang:objectName(), "", 
			"sr_sanfen", "")
		room:moveCardTo(self, zhugeliang, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, zhugeliang, data)
		thread:trigger(sgs.CardFinished, room, zhugeliang, data)
	end ,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_sanfen")

		local from = targets[1]
		local to = targets[2]
		local prompt1 = string.format("@srsanfen-slash:%s", to:objectName())
		if not room:askForUseSlashTo(from, to, prompt1,false) then
			if not from:isNude() then
				local chosen = room:askForCardChosen(source, from, "he", self:objectName())
				room:throwCard(chosen, from, source)
			end
		end
		local prompt2 = string.format("@srsanfen-slash:%s", source:objectName())
		if not room:askForUseSlashTo(to, source, prompt2,false) then
			if not to:isNude() then
				local chosen = room:askForCardChosen(source, to, "he", self:objectName())
				room:throwCard(chosen, to, source)
			end
		end
	end
}
sr_sanfen = sgs.CreateViewAsSkill{
	name = "sr_sanfen",
	n = 0, 
	view_as = function(self, cards) 
		return sr_sanfencard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_sanfencard")
	end
}
sr_zhugeliang:addSkill(sr_sanfen)

--观星
sr_guanxing = sgs.CreateTriggerSkill{
	name = "sr_guanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Start and player:getPhase() ~= sgs.Player_Finish then 
			return false end
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, "sr_guanxing")
			room:broadcastSkillInvoke("sr_guanxing")
			local count = room:alivePlayerCount()
			if count > 3 then
				count = 3
			end
			local cards = room:getNCards(count)
			room:askForGuanxing(player, cards, 0)
		end		
	end
}
sr_zhugeliang:addSkill(sr_guanxing)

--帷幄
sr_weiwo = sgs.CreateTriggerSkill{
	name = "sr_weiwo",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:isKongcheng() then			
			if damage.nature == sgs.DamageStruct_Normal then
				room:notifySkillInvoked(player, "sr_weiwo")
				room:broadcastSkillInvoke("sr_weiwo")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = "normal_nature"
				room:sendLog(msg)
				return true
			end
		else			
			if damage.nature ~= sgs.DamageStruct_Normal then
				room:notifySkillInvoked(player, "sr_weiwo")
				room:broadcastSkillInvoke("sr_weiwo")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = damage.nature == sgs.DamageStruct_Fire and "fire_nature" or "thunder_nature"
				room:sendLog(msg)
				return true
			end
		end
		return false
	end
}
sr_zhugeliang:addSkill(sr_weiwo)

-- zhugeliangchoose = sgs.CreateTriggerSkill{
-- 	name = "#zhugeliangchoose",
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local choice = room:askForChoice(player,self:objectName(),"losesanfen+loseguanxing+loseweiwo+losenone",data)
-- 		if choice == "losesanfen" then
-- 			room:handleAcquireDetachSkills(player,"-sr_sanfen")
-- 		elseif choice == "loseguanxing" then
-- 			room:handleAcquireDetachSkills(player,"-sr_guanxing")
-- 		elseif choice == "loseweiwo" then
-- 			room:handleAcquireDetachSkills(player,"-sr_weiwo")
-- 		else
-- 			return false
-- 		end
-- 		return false
-- 	end
-- }

sr_zhugeliang:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_zhugeliang"] = "SR諸葛亮",
["&sr_zhugeliang"] = "諸葛亮",
["sr_sanfen"] = "三分",
["sr_sanfencard"] = "三分",
["@srsanfen-slash"] = "請對該角色（%src）使用一張【殺】，否則你被棄置一張牌",
[":sr_sanfen"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以選擇兩名其他角色，其中一名"..
"你選擇的角色須對另外一名角色使用一張【殺】，然後另外一名角色須對你使用一張【殺】，你棄置不如此做者一張"..
"牌。<font color=\"red\"><b>（選擇第一個角色為作為第一個【殺】使用者）</b></font>",
["sr_guanxing"] = "觀星",
[":sr_guanxing"] = "回合開始/結束階段開始時，你可以觀看牌堆頂的X張牌（X為存活角色的數量，且最多為3），將"..
"其中任意數量的牌以任意順序置於牌堆頂，其餘以任意順序置於牌堆底。",
["sr_weiwo"] = "帷幄",
[":sr_weiwo"] = "<font color=\"blue\"><b>鎖定技，</b></font>當你有手牌時，你防止受到的屬性傷害；當你沒有" ..
"手牌時，你防止受到非屬性傷害。",
["#AvoidDamage"] = "%from 的技能【%arg】被觸發，防止了 %to 對其造成的 %arg2 傷害",
["#DefendDamage"] = "%from 的技能【%arg】被觸發，防止了其對 %to 造成的 %arg2 傷害",
["$sr_sanfen"] = "誠如是，則漢室可興矣。",
["$sr_guanxing"] = "知天易，逆天難。",
["$sr_weiwo"] = "挫敵銳氣，靜待反擊之時！",
["~sr_zhugeliang"] = "悠悠蒼天,曷此其極！",
["losesr_sanfen"] = "失去【三分】",
["losesr_guanxing"] = "失去【觀星】",
["losesr_weiwo"] = "失去【帷幄】",
}

--SR張飛
sr_zhangfei = sgs.General(extension, "sr_zhangfei", "shu", 4)

--蓄劲
sr_xujindummycard = sgs.CreateSkillCard{
	name = "sr_xujindummycard"
}
sr_xujin = sgs.CreateTriggerSkill{
	name = "sr_xujin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, "sr_xujin")
					room:broadcastSkillInvoke("sr_xujin")
					local ids = room:getNCards(5, false)
					local left = sgs.IntList()
					local getback = sgs.IntList()
					room:fillAG(ids)
					room:getThread():delay()
					local dest = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
					local card_id = room:askForAG(dest, ids, false, self:objectName())
					room:clearAG()
					local card = sgs.Sanguosha:getCard(card_id)
					local suit = card:getSuit()
					for _,id in sgs.qlist(ids) do
						local c = sgs.Sanguosha:getCard(id)
						if c:getSuit() == suit then
							getback:append(id)
						else
							left:append(id)
						end
					end
					if getback:length() > 0 then
						room:setPlayerMark(player, "srxulimark-Clear", getback:length())
						local dummy = sr_xujindummycard:clone()
						for _,id in sgs.qlist(getback) do
							dummy:addSubcard(id)
						end
						room:obtainCard(dest, dummy, true)
					end
					if left:length() > 0 then
						local dummy = sr_xujindummycard:clone()
						for _,id in sgs.qlist(left) do
							dummy:addSubcard(id)
						end
						room:throwCard(dummy, nil, nil)
					end
					return true
				end
			end
		end
		return false	
	end
}
sr_zhangfei:addSkill(sr_xujin)
--蓄劲BUFF
sr_xujintm = sgs.CreateTargetModSkill{
	name = "#sr_xujintm",
	frequency = sgs.Skill_NotFrequent,
	residue_func = function(self, target)
		if target:hasSkill("sr_xujin") then
			if target:getMark("srxulimark-Clear") > 0 then
				local count = target:getMark("srxulimark-Clear") - 1
				return count
			end
		end
	end,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("sr_xujin") then
			if from:getMark("srxulimark-Clear") > 0 then
				local count = from:getMark("srxulimark-Clear") - 1
				if from:getWeapon() == nil then
					return count
				else
					local distance = from:getWeapon():getRealCard():toWeapon():getRange()
					if count + 1 > distance then
						return count
					end
				end
			end
		end
	end
}
sr_zhangfei:addSkill(sr_xujintm)
extension:insertRelatedSkills("sr_xujin", "#sr_xujintm")

--咆哮
-- sr_paoxiao = sgs.CreateTriggerSkill{
-- 	name = "sr_paoxiao",  
-- 	frequency = sgs.Skill_NotFrequent, 
-- 	events = {sgs.TargetConfirmed, sgs.Damage, sgs.CardFinished},  
-- 	on_trigger = function(self, event, player, data)
-- 		local room = player:getRoom()
-- 		if event == sgs.TargetConfirmed then
-- 			local use = data:toCardUse()
-- 			local source = use.from
-- 			local targets = use.to
-- 			if source and source:hasSkill(self:objectName()) then
-- 				if source:getPhase() == sgs.Player_Play then
-- 					if targets:contains(player) then
-- 						local card = use.card
-- 						if card:isKindOf("Slash") then
-- 							if not player:isNude() then
-- 								if room:askForSkillInvoke(source, self:objectName(), data) then
-- 									room:notifySkillInvoked(source, "sr_paoxiao")
-- 									room:broadcastSkillInvoke("sr_paoxiao")
-- 									local disc = room:askForCardChosen(source, player, "he", self:objectName())
-- 									room:throwCard(disc, player, source)
-- 									room:setPlayerMark(player, "srpaoxiaomark",	player:getMark("srpaoxiaomark") + 1)
-- 									room:setPlayerFlag(source,self:objectName())
-- 								end
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		if event == sgs.Damage then
-- 			if player:hasFlag(self:objectName()) then
-- 				local damage = data:toDamage()
-- 				local dest = damage.to
-- 				local card = damage.card
-- 				if not player:isNude() then
-- 					if card and card:isKindOf("Slash") then
-- 						if dest:getMark("srpaoxiaomark") > 0 then
-- 							room:setPlayerFlag(dest,"srpaoxiao")							
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		if event == sgs.CardFinished then
-- 			if player:hasFlag(self:objectName()) then
-- 				local use = data:toCardUse()
-- 				if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then					
-- 					local players = room:getAllPlayers()
-- 					for _,p in sgs.qlist(players) do
-- 						if p:getMark("srpaoxiaomark") > 0 and p:hasFlag("srpaoxiao") then
-- 							if player:isNude() then return false end
-- 							room:setPlayerMark(p, "srpaoxiaomark", p:getMark("srpaoxiaomark") - 1)
-- 							room:setPlayerFlag(player,"-"..self:objectName())
-- 							room:setPlayerFlag(p,"-srpaoxiao")							
-- 							local prompt = string.format("srpaoxiaoslash:%s", p:objectName())
-- 							if not room:askForUseCard(player, "slash", prompt) then
-- 								repeat
-- 									if player:isNude() then
-- 										room:setPlayerMark(p,"srpaoxiaomark",0)
-- 										break
-- 									end
-- 									local disc = room:askForCardChosen(p, player, "he", self:objectName())
-- 									room:notifySkillInvoked(player,"sr_paoxiao")
-- 									room:broadcastSkillInvoke("sr_paoxiao")
-- 									room:throwCard(disc, player, p)
-- 									room:setPlayerMark(p, "srpaoxiaomark", p:getMark("srpaoxiaomark") - 1)
-- 								until p:getMark("srpaoxiaomark") <= 0
-- 							else
-- 								room:setPlayerMark(p, "srpaoxiaomark", 0)	
-- 							end
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self, target)
-- 		return target
-- 	end
-- }
sr_paoxiao = sgs.CreateTriggerSkill{
	name = "sr_paoxiao",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage, sgs.DamageComplete},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:getPhase()~= sgs.Player_Play then return false end			
			if damage.chain or damage.transfer or not damage.by_user then return false end
			if not damage.card or not damage.card:isKindOf("Slash") then return false end
			room:setPlayerFlag(player,self:objectName())
			room:setPlayerMark(damage.to,"hasbeendamaged",damage.to:getMark("hasbeendamaged")+1)
		else 
			if not player:hasFlag(self:objectName()) then return false end
			local use = data:toDamage()
			if not (damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName()) then 
				return false 
			end	
			if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			room:broadcastSkillInvoke("sr_paoxiao")
			player:drawCards(1)	
			room:setPlayerFlag(player,"-"..self:objectName())
			if not room:askForUseCard(player, "slash", "#Paoxiao") then
				for _,p in sgs.qlist(use.to) do
					if p:isAlive() and p:getMark("hasbeendamaged")>0 then
						if not player:isNude() then 
							room:setPlayerMark(p, "hasbeendamaged", p:getMark("hasbeendamaged") - 1)
							repeat
								if player:isNude() or not p:canDiscard(player,"he") then
									room:setPlayerMark(p,"srpaoxiaomark",0)
									break
								end
								local disc = room:askForCardChosen(p, player, "he", self:objectName())
								-- room:notifySkillInvoked(player,"sr_paoxiao")
								-- room:broadcastSkillInvoke("sr_paoxiao")
								room:throwCard(disc, player, p)
								room:setPlayerMark(p, "hasbeendamaged", p:getMark("hasbeendamaged") - 1)
							until p:getMark("hasbeendamaged") <= 0
						else
							room:setPlayerMark(p, "hasbeendamaged", 0)	
						end
					end
				end
				for _,p in sgs.qlist(use.to) do
					if p:getMark("hasbeendamaged")>0 then
						room:setPlayerMark(p, "hasbeendamaged", 0)	
					end
				end
			else
				for _,p in sgs.qlist(use.to) do
					if p:getMark("hasbeendamaged")>0 then
						room:setPlayerMark(p, "hasbeendamaged", 0)	
					end
				end
			end				
		end
		return false
	end,
	-- can_trigger = function(self, target)
	-- 	return target
	-- end
}
sr_zhangfei:addSkill(sr_paoxiao)

-- zhangfeichoose = sgs.CreateTriggerSkill{
-- 	name = "#zhangfeichoose",
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local choice = room:askForChoice(player,self:objectName(),"losexujin+losepaoxiao+losenone",data)
-- 		if choice == "losexujin" then
-- 			room:handleAcquireDetachSkills(player,"-sr_xujin")
-- 			room:handleAcquireDetachSkills(player,"-#sr_xujintm")
-- 		elseif choice == "losepaoxiao" then
-- 			room:handleAcquireDetachSkills(player,"-sr_paoxiao")
-- 		else
-- 			return false
-- 		end
-- 		return false
-- 	end
-- }

sr_zhangfei:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_zhangfei"] = "SR張飛",
["&sr_zhangfei"] = "張飛",
["sr_xujin"] = "蓄勁",
[":sr_xujin"] = "摸牌階段，你可以放棄摸牌，改為展示牌堆頂的五張牌，並令一名角色獲得其中一種花色的所有牌，"..
"再將其餘的牌置入棄牌堆。若如此做，你本回合的攻擊範圍和可以使用的【殺】數量與此法獲得的牌的數量相同。",
["sr_paoxiao"] = "咆哮",
["#Paoxiao"] = "你需要使用一張【殺】，否則你被目標角色棄置一張牌",
--[":sr_paoxiao"] = "當你於出牌階段使用【殺】指定目標後，可以棄置目標角色的一張牌，若如此做，當此【殺】"..
--"造成傷害且結算後，你選擇一項：使用一張【殺】，或令該角色棄置你的一張牌。",
[":sr_paoxiao"] = "出牌階段，當你使用【殺】對目標角色造成一次傷害並結算完畢後，你可以摸一張牌，然後選擇一"..
"項：使用一張【殺】，或令該角色棄置你一張牌。",
["$sr_xujin"] = "休想逃，乖乖受死！",
["$sr_paoxiao"] = "都站穩了，吃我一戟！",
["~sr_zhangfei"] = "你這傢伙，好生厲害！",
["losesr_xujin"] = "失去【蓄勁】",
["losesr_paoxiao"] = "失去【咆哮】",
}

--SR趙雲
sr_zhaoyun = sgs.General(extension,"sr_zhaoyun","shu")

-- sr_jiuzhu = sgs.CreateTriggerSkill{
-- 	name = "sr_jiuzhu",
-- 	events = {sgs.CardsMoveOneTime},
-- 	on_trigger = function(self,event,player,data)
-- 		local move = data:toMoveOneTime()
-- 		local ids = move.card_ids
-- 		if move.to_place ~= sgs.Player_DiscardPile then return false end
-- 		local room = player:getRoom()
-- 		local zhaoyun = room:findPlayerBySkillName(self:objectName())
-- 		if not zhaoyun or zhaoyun:isDead() or not zhaoyun:hasSkill(self:objectName()) then return false end
-- 		for _,id in sgs.qlist(ids) do
-- 			local c = sgs.Sanguosha:getEngineCard(id)
-- 			if c:isKindOf("Jink") then
-- 				local pattern = "Slash,FireAttack,Duel,SavageAssault,ArcheryAttack,Drowning"
-- 				if not room:askForCard(zhaoyun,pattern,"@sr_jiuzhu:"..c:objectName(),data,self:objectName()) then 
				--continue end
-- 				room:notifySkillInvoked(zhaoyun,"sr_jiuzhu")
-- 				room:broadcastSkillInvoke("sr_jiuzhu") 
-- 				local move1 = sgs.CardsMoveStruct()
-- 				move1.card_ids:append(id)
-- 				move1.to_place = sgs.Player_PlaceHand
-- 				move1.to = zhaoyun						
-- 				room:moveCardsAtomic(move1, true)
-- 				if zhaoyun:getPhase() == sgs.Player_NotActive then
-- 					local current = room:getCurrent()
-- 					if current and current:isAlive() then
-- 						if room:askForSkillInvoke(zhaoyun,self:objectName(),data) then
-- 							room:notifySkillInvoked(zhaoyun,"sr_jiuzhu")
-- 							room:broadcastSkillInvoke("sr_jiuzhu")
-- 							local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
-- 							slash:setSkillName(self:objectName())							
-- 							current:addQinggangTag(slash)							
-- 							room:useCard(sgs.CardUseStruct(slash,zhaoyun,current))
-- 						end
-- 					end
-- 				end				
-- 			end
-- 		end
-- 		return false
-- 	end,	
-- }

sr_jiuzhuCard = sgs.CreateSkillCard{
	name = "sr_jiuzhu" ,
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self) and to_select:hasFlag("sr_jiuzhu_target")
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("sr_jiuzhu")
			for _, p in sgs.qlist(targets_list) do
				--p:drawCards(1)
				p:addQinggangTag(slash)
			end
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
sr_jiuzhuVS = sgs.CreateZeroCardViewAsSkill{
	name = "sr_jiuzhu",
	view_as = function()
		return sr_jiuzhuCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sr_jiuzhu"
	end
}

sr_jiuzhu = sgs.CreateTriggerSkill{
	name = "sr_jiuzhu",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = sr_jiuzhuVS,
	on_trigger = function(self,event,player,data)
		local move = data:toMoveOneTime()
		local ids = move.card_ids
		if move.to_place ~= sgs.Player_DiscardPile then return false end
		if room:getTag("FirstRound"):toBool() then return false end
		local room = player:getRoom()
		local zhaoyun = room:findPlayerBySkillName(self:objectName())
		if not zhaoyun or zhaoyun:isDead() or not zhaoyun:hasSkill(self:objectName()) then return false end
		for _,id in sgs.qlist(ids) do
			local c = sgs.Sanguosha:getEngineCard(id)
			if c:isKindOf("Jink") then
				local acard = room:askForCard(zhaoyun,"^Jink","@sr_jiuzhu:"..c:objectName(), data, self:objectName())
				if acard then
					room:notifySkillInvoked(zhaoyun,"sr_jiuzhu")
					room:broadcastSkillInvoke("sr_jiuzhu") 
					local move1 = sgs.CardsMoveStruct()
					move1.card_ids:append(id)
					move1.to_place = sgs.Player_PlaceHand
					move1.to = zhaoyun						
					room:moveCardsAtomic(move1, true)
					if zhaoyun:getPhase() == sgs.Player_NotActive then
						local current = room:getCurrent()
						room:setPlayerFlag(current,"sr_jiuzhu_target")
						room:askForUseCard(zhaoyun, "@@sr_jiuzhu", "@sr_jiuzhu-slash")
						room:setPlayerFlag(current,"-sr_jiuzhu_target")
					end
				end				
			end
		end
		return false
	end,	
}


sr_jiuzhuTargetMod = sgs.CreateTargetModSkill{
	name = "#sr_jiuzhu",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "sr_jiuzhu" then
			return 1000
		end
	end,
}

sr_zhaoyun:addSkill(sr_jiuzhu)
sr_zhaoyun:addSkill(sr_jiuzhuTargetMod)

sr_tuweicard = sgs.CreateSkillCard{
	name = "sr_tuweicard" ,
	filter = function(self, targets, to_select)
		if #targets >= 2 then return false end
		if not to_select:hasFlag("todiscard") then return false end
		if to_select:isNude() then return false end
		return sgs.Self:canDiscard(to_select, "he")
	end ,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"sr_tuwei")
		room:broadcastSkillInvoke("sr_tuwei")
		local map = {}
		local totaltarget = 0
		for _, sp in ipairs(targets) do
			map[sp] = 1
		end
		totaltarget = #targets
		if totaltarget == 1 then
			for _, sp in ipairs(targets) do
				map[sp] = map[sp] + 1
			end
		end
		for _, sp in ipairs(targets) do
			while map[sp] > 0 do
				if source:isAlive() and sp:isAlive() and source:canDiscard(sp, "he") then
					local card_id = room:askForCardChosen(source, sp, "he", self:objectName(), false, 
						sgs.Card_MethodDiscard)
					room:throwCard(card_id, sp, source)
				end
				map[sp] = map[sp] - 1
			end
		end
	end
}
sr_tuweiVS = sgs.CreateViewAsSkill{
	name = "sr_tuwei" ,
	n = 0 ,
	view_as = function()
		return sr_tuweicard:clone()
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@@sr_tuwei"
	end
}

-- sr_tuwei = sgs.CreateTriggerSkill{
-- 	name = "sr_tuwei",
-- 	events = {sgs.TargetConfirmed, sgs.CardsMoveOneTime},
-- 	view_as_skill = sr_tuweiVS,
-- 	on_trigger = function(self,event,player,data)
-- 		if event == sgs.TargetConfirmed then
-- 			local use = data:toCardUse()
-- 			if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then return false end
-- 			if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and 
-- 				sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("Slash") then
-- 				if (use.from:objectName() == player:objectName() or use.to:contains(player)) and 
-- 					player:hasSkill(self:objectName())	then									
-- 					local room = player:getRoom()
-- 					room:setCardFlag(use.card:getEffectiveId(), "real_Slash")
-- 					room:setPlayerFlag(use.from,"todiscard")
-- 					for _,p in sgs.qlist(use.to) do
-- 						room:setPlayerFlag(p,"todiscard")
-- 					end
-- 				end
-- 			end
-- 		else
-- 			local room = player:getRoom()
-- 			local zhaoyun = room:findPlayerBySkillName(self:objectName())
-- 			if not zhaoyun or zhaoyun:isDead() or not zhaoyun:hasSkill(self:objectName()) then return false end
-- 			local move = data:toMoveOneTime()
-- 			local ids = move.card_ids
-- 			if move.to_place ~= sgs.Player_DiscardPile then return false end						
-- 			local card = sgs.Sanguosha:getCard(ids:first())
-- 			if card:hasFlag("real_Slash") then
-- 				room:setCardFlag(card:getEffectiveId(),"-real_Slash")				
-- 				if zhaoyun:isKongcheng() then return false end				
-- 				if room:askForCard(zhaoyun,"BasicCard","@sr_tuwei:"..card:objectName(),data,self:objectName()) then
-- 					room:notifySkillInvoked(zhaoyun,"sr_tuwei")
-- 					room:broadcastSkillInvoke("sr_tuwei") 
-- 					room:askForUseCard(zhaoyun, "@@sr_tuwei", "@sr_tuwei-card")
-- 					for _,p in sgs.qlist(room:getAllPlayers()) do
-- 						if p:hasFlag("todiscard") then
-- 							room:setPlayerFlag(p,"-todiscard")
-- 						end
-- 					end
-- 				end
-- 				move.card_ids = sgs.IntList()
-- 				data:setValue(move)
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self,target)
-- 		return target and target:isAlive()
-- 	end
-- }

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

sr_tuwei = sgs.CreateTriggerSkill{
	name = "sr_tuwei",
	events = {sgs.TargetConfirmed, sgs.CardsMoveOneTime},
	view_as_skill = sr_tuweiVS,
	on_trigger = function(self,event,player,data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isVirtualCard() then return false end
			if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) and 
				sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("Slash") then
				if (use.from:objectName() == player:objectName() or use.to:contains(player)) and 
					player:hasSkill(self:objectName())	then									
					local room = player:getRoom()
					room:setCardFlag(use.card:getEffectiveId(), "real_Slash")
					room:setPlayerFlag(use.from,"todiscard")
					for _,p in sgs.qlist(use.to) do
						room:setPlayerFlag(p,"todiscard")
					end
				end
			end
		else
			local room = player:getRoom()
			local zhaoyun = room:findPlayerBySkillName(self:objectName())
			if not zhaoyun or zhaoyun:isDead() or not zhaoyun:hasSkill(self:objectName()) then return false end
			local move = data:toMoveOneTime()
			local ids = move.card_ids
			if move.to_place ~= sgs.Player_DiscardPile then return false end						
			local card = sgs.Sanguosha:getCard(ids:first())
			if card:hasFlag("real_Slash") then
				room:setCardFlag(card:getEffectiveId(),"-real_Slash")				
				if zhaoyun:isKongcheng() then return false end
				--local pattern = "Slash,FireAttack,Duel,SavageAssault,ArcheryAttack,Drowning"
				local pattern = ""
				local choices = {}
				
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:getClassName() )) then
						if player:getMark("AG_BANCard"..card:objectName()) == 0 and canCauseDamage(card) then
							table.insert(choices, card:getClassName() )
						end
					end
				end
				local pattern = table.concat(choices, ",")

				local tos = {}
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("todiscard") then
						table.insert(tos,p:getGeneralName())
					end
				end
				if #tos == 0 then return false end
				if room:askForCard(zhaoyun,pattern,"@sr_tuwei:"..card:objectName(),
					sgs.QVariant(table.concat(tos,"+")),self:objectName()) then
					room:notifySkillInvoked(zhaoyun,"sr_tuwei")
					room:broadcastSkillInvoke("sr_tuwei") 
					room:askForUseCard(zhaoyun, "@@sr_tuwei", "@sr_tuwei-card")
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if p:hasFlag("todiscard") then
							room:setPlayerFlag(p,"-todiscard")
						end
					end
				end
				move.card_ids = sgs.IntList()
				data:setValue(move)
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

sr_zhaoyun:addSkill(sr_tuwei)

sr_zhaoyun:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_zhaoyun"] = "SR趙雲",
["&sr_zhaoyun"] = "趙雲",
["sr_jiuzhu"] = "救主",
-- [":sr_jiuzhu"] = "每當一張【閃】進入棄牌堆時，你可以用一張能造成傷害的牌替換之。若此時不在你的回合"..
--"內，你可以視為對當前回合角色使用一張【殺】，你以此法使用的【殺】無視防具。",
-- ["@sr_jiuzhu"] = "你可以用一張可以造成傷害的牌替換 【%src】",
[":sr_jiuzhu"] = "每當一張非轉化的【閃】進入棄牌堆時，你可以用一張不是「閃」的牌替換之。若此時不在你"..
"的回合內，你可以視為對當前回合角色使用一張【殺】，你以此法使用的【殺】無視防具。",
["@sr_jiuzhu"] = "你可以用一張與【%src】不同花色的牌替換之",
["$sr_jiuzhu"] = "和我一起活著離開此地",
-- ["sr_tuwei"] = "突圍",
-- [":sr_tuwei"] = "每當一張【殺】進入棄牌堆時，若你是此【殺】的目標或使用者，你可以棄置一張基本牌，然"..
--"後棄置此牌的目標或使用者的共計兩張牌",
["$sr_tuwei"] = "讓我了結此戰",
-- ["@sr_tuwei"] = "你可以為 【%src】 棄置一張基本牌",
["sr_tuwei"] = "突圍",
[":sr_tuwei"] = "每當一張非轉化的【殺】進入棄牌堆時，若你是此【殺】的目標或使用者，你可以棄置一張可以"..
"造成傷害的牌，然後棄置此牌的目標或使用者的共計兩張牌",
["@sr_tuwei"] = "你可以為 【%src】 棄置一張可以造成傷害的牌",
["@sr_tuwei-card"] = "你可以發動 【突圍】",
["~sr_tuwei"] = "選擇 【殺】 的目標或使用者，棄置其共計兩張牌",
["losesr_jiuzhu"] = "失去【救主】",
["losesr_tuwei"] = "失去【突圍】",
["~sr_zhaoyun"] = "人外有人，子龍領教了！",
	["@sr_jiuzhu-slash"] = "你可以發動“救主”",
	["~sr_jiuzhu"] = "選擇當前回合角色→點擊確定",
}

--SR孫權
sr_sunquan = sgs.General(extension, "sr_sunquan$", "wu", 4)

--权衡
sr_quanhengcard = sgs.CreateSkillCard{
	name = "sr_quanhengcard", 
	target_fixed = true, 
	will_throw = false, 
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_quanheng")
		room:setPlayerMark(source, "srquanhengmark", self:subcardsLength())		
		local players = sgs.SPlayerList()
		local others = room:getOtherPlayers(source)
		for _,p in sgs.qlist(others) do
			if source:canSlash(p) then
				players:append(p)
			end
		end
		if sgs.Slash_IsAvailable(source) and not players:isEmpty()  then
			local choice = room:askForChoice(source, "sr_quanheng", "srwuzhong+srsha+srquxiao")
			if choice == "srwuzhong" then
				local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
				for _,p in sgs.qlist(self:getSubcards()) do
					ex_nihilo:addSubcard(p)
				end
				local use = sgs.CardUseStruct()
				ex_nihilo:setSkillName("sr_quanheng")
				use.card = ex_nihilo
				use.from = source
				use.to:append(source)
				room:useCard(use)
				room:setPlayerFlag(source, "srquanhengused")
			elseif choice == "srsha" then
				local slash
				local choice = room:askForChoice(source, "sr_quanheng", "srnormal+srfire+srthunder")
				if choice == "srnormal" then
					slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _,p in sgs.qlist(self:getSubcards()) do
						slash:addSubcard(p)
					end
					slash:setSkillName("sr_quanheng")
				elseif choice == "srfire" then
					slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
					for _,p in sgs.qlist(self:getSubcards()) do
						slash:addSubcard(p)
					end
					slash:setSkillName("sr_quanheng")
				elseif choice == "srthunder" then
					slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
					for _,p in sgs.qlist(self:getSubcards()) do
						slash:addSubcard(p)
					end
					slash:setSkillName("sr_quanheng")
				end
				local to = sgs.SPlayerList()
				for i=1, 1+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,slash), 1 do
					if i == 1 then
						local target = room:askForPlayerChosen(source, players, "sr_quanheng", nil, true, false)
						players:removeOne(target)
						to:append(target)
						if players:isEmpty() then break end
					else
						local target = room:askForPlayerChosen(source, players, "sr_quanheng", nil, true, false)
						if not target then break end
						players:removeOne(target)
						to:append(target)
						if players:isEmpty() then break end
					end
				end
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = source
				use.to = to
				room:useCard(use, true)
				room:setPlayerFlag(source, "srquanhengused")
			elseif choice == "srquxiao" then
				return 
			end
		else
			local choice = room:askForChoice(source, "sr_quanheng", "srwuzhong+srquxiao")
			if choice == "srwuzhong" then
				local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
				for _,p in sgs.qlist(self:getSubcards()) do
					ex_nihilo:addSubcard(p)
				end
				local use = sgs.CardUseStruct()
				ex_nihilo:setSkillName("sr_quanheng")
				use.card = ex_nihilo
				use.from = source
				use.to:append(source)
				room:useCard(use)
				room:setPlayerFlag(source, "srquanhengused")
			elseif choice == "srquxiao" then
				return 
			end
		end
	end
}
--权衡视为技
sr_quanheng = sgs.CreateViewAsSkill{
	name = "sr_quanheng", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local srquanheng_card = sr_quanhengcard:clone()
			for _,card in ipairs(cards) do
				srquanheng_card:addSubcard(card)
			end
			srquanheng_card:setSkillName("sr_quanheng")
			return srquanheng_card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasFlag("srquanhengused") and not player:isKongcheng()
	end
}

sr_quanhengclear = sgs.CreateTriggerSkill{
	name = "#sr_quanheng",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardResponded, sgs.CardUsed, sgs.CardFinished},
	-- view_as_skill = sr_quanhengvs,  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.CardResponded then			
			local card_star = data:toCardResponse().m_card			
			if not card_star:isKindOf("Jink") and not card_star:isKindOf("Nullification") then return false end			
			local srsunquan = room:findPlayerBySkillName("sr_quanheng")
			if srsunquan then
				if srsunquan:getMark("srquanhengmark") > 0 then
					srsunquan:drawCards(srsunquan:getMark("srquanhengmark"))
				end
			end
		elseif event == sgs.CardUsed then
			local srsunquan = room:findPlayerBySkillName("sr_quanheng")
			local use = data:toCardUse()
			if not use.card:isKindOf("Nullification") then return false end
			if use.from:objectName() == srsunquan:objectName() then return false end
			if use.card then
				if srsunquan:getMark("srquanhengmark") > 0 then
					if use.from:objectName() ~= srsunquan:objectName() and use.card:isKindOf("Nullification") then
						srsunquan:drawCards(srsunquan:getMark("srquanhengmark"))
						room:setPlayerMark(srsunquan, "srquanhengmark", 0)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local card = data:toCardUse().card
			local from = data:toCardUse().from
			if not (player:hasSkill(self:objectName()) and from and from:objectName() == player:objectName()) then 
				return false end
			if not card:isKindOf("Slash") and not card:isKindOf("ExNihilo") then return false end			
			if player:hasSkill(self:objectName()) and from and from:objectName() == player:objectName() then				
				if card:getSkillName() == "sr_quanheng" then									
					if player:getMark("srquanhengmark") > 0 then
						local room = player:getRoom()
						room:setPlayerMark(player, "srquanhengmark", 0)												
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
sr_sunquan:addSkill(sr_quanheng)
sr_sunquan:addSkill(sr_quanhengclear)
extension:insertRelatedSkills("sr_quanheng","#sr_quanheng")

--雄略

sr_xionglve_select = sgs.CreateSkillCard{
	name = "sr_xionglve",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)


		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
--		for _, name in ipairs(patterns) do
--			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
--			poi:setSkillName("sr_xionglve")
--			poi:addSubcard(self:getSubcards():first())
--			if poi:isAvailable(source) and source:getMark("sr_xionglve"..name) == 0 and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
--				table.insert(choices, name)
--			end
--		end
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("TrickCard") then
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
				local pattern = room:askForChoice(source, "sr_xionglve", table.concat(choices, "+"))
				if pattern and pattern ~= "cancel" then
					local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
					if poi:targetFixed() then
						poi:setSkillName("sr_xionglve")
						poi:addSubcard(self:getSubcards():first())
						room:useCard(sgs.CardUseStruct(poi, source, source),true)
					else
						pos = getPos(patterns, pattern)
						room:setPlayerMark(source, "sr_xionglvepos", pos)
						room:setPlayerProperty(source, "sr_xionglve", sgs.QVariant(self:getSubcards():first()))
						room:askForUseCard(source, "@@sr_xionglve", "@sr_xionglve:"..pattern)--%src
					end
				end
			end
		elseif sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("BasicCard") then
			for i = 0, 10000 do
				local card = sgs.Sanguosha:getEngineCard(i)
				if card == nil then break end
				if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
					if card:isAvailable(source) and source:getMark("AG_BANCard"..card:objectName()) == 0 and card:isKindOf("BasicCard") then
						table.insert(choices, card:objectName())
					end
				end
			end
			
			if next(choices) ~= nil then
				table.insert(choices, "cancel")
				local pattern = room:askForChoice(source, "sr_xionglve", table.concat(choices, "+"))
				if pattern and pattern ~= "cancel" then
					local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
					if poi:targetFixed() then
						poi:setSkillName("sr_xionglve")
						poi:addSubcard(self:getSubcards():first())
						room:useCard(sgs.CardUseStruct(poi, source, source),true)
					else
						pos = getPos(patterns, pattern)
						room:setPlayerMark(source, "sr_xionglvepos", pos)
						room:setPlayerProperty(source, "sr_xionglve", sgs.QVariant(self:getSubcards():first()))
						room:askForUseCard(source, "@@sr_xionglve", "@sr_xionglve:"..pattern)--%src
					end
				end
			end
		elseif sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("EquipCard") then
			local players = sgs.SPlayerList()
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local equip = card:getRealCard():toEquipCard()
			local equip_index = equip:location()
			for _,p in sgs.qlist(room:getOtherPlayers(source)) do
				if p:getEquip(equip_index) == nil then
					players:append(p)
				end
			end
			if (not players:isEmpty()) then
				local target = room:askForPlayerChosen(source, players, "sr_xionglveequip", nil, true, true)
				if target then
					room:moveCardTo(self, source, target, sgs.Player_PlaceEquip,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "sr_xionglve", ""))

				end
			end
		end
	end
}


sr_xionglveCard = sgs.CreateSkillCard{
	name = "sr_xionglveCard",
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
				if user:getMark("sr_xionglve"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(user, "sr_xionglve", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("sr_xionglve")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if card_use.from:getMark("sr_xionglve"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(card_use.from, "sr_xionglve", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("sr_xionglve")
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
sr_xionglveVS = sgs.CreateViewAsSkill{
	name = "sr_xionglve",
	n = 1,
	expand_pile = "srlve",
	response_pattern = "@@sr_xionglve",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@sr_xionglve" then
			return false
		else return sgs.Self:getPile("srlve"):contains(to_select:getEffectiveId()) end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = sr_xionglve_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local acard = sr_xionglveCard:clone()
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern and pattern == "@@sr_xionglve" then
				pattern = patterns[sgs.Self:getMark("sr_xionglvepos")]
				acard:addSubcard(sgs.Self:property("sr_xionglve"):toInt())
				if #cards ~= 0 then return end
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return player:getPile("srlve"):length() > 0
	end,
}

sr_xionglve = sgs.CreateTriggerSkill{
	name = "sr_xionglve",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = sr_xionglveVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
		if player:getPhase() == sgs.Player_Draw then
			if room:askForSkillInvoke(player, "sr_xionglve", data) then
				room:notifySkillInvoked(player, "sr_xionglve")
				room:broadcastSkillInvoke("sr_xionglve")
				local ids = room:getNCards(2, false)
				room:fillAG(ids)
				local card_id = room:askForAG(player, ids, false, "sr_xionglve")
				room:clearAG()
				local card = sgs.Sanguosha:getCard(card_id)
				for _,id in sgs.qlist(ids) do
					local c = sgs.Sanguosha:getCard(id)
					if c:getId() == card:getId() then
						room:obtainCard(player, c, true)
					else
						player:addToPile("srlve", id, true)
					end
				end
				return true
			end
		elseif player:getPhase() == sgs.Player_Discard then
			if player:hasFlag("xionglveused") then
				room:setPlayerFlag(player,"-xionglveused")
			end
		end		
		return false	
	end
}
sr_sunquan:addSkill(sr_xionglve)

--辅政
sr_fuzhengcard = sgs.CreateSkillCard{
	name = "sr_fuzhengcard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		if #targets>=2 then return false end
		return to_select:getKingdom() == "wu" and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self,targets)
		return #targets<=2
	end,
	on_use = function(self,room,source,targets)
		room:notifySkillInvoked(source, "sr_fuzheng")
		room:broadcastSkillInvoke("sr_fuzheng")
		if #targets>0 then
			room:setTag("fuzheng_num",sgs.QVariant(#targets))
			for _,p in ipairs(targets) do
				if p:isAlive() then
					p:drawCards(1)
				end
			end			
			local card1
			local card2
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), 
				"sr_fuzheng", nil)			
			if not targets[1]:isKongcheng() then
				card1 = room:askForExchange(targets[1], "sr_fuzheng1", 1, 1, false, "srfuzhengput")
				room:removeTag("fuzheng_num")
			end
			if #targets>1 then				
				if not targets[2]:isKongcheng() then
					card2 = room:askForExchange(targets[2], "sr_fuzheng2", 1, 1, false, "srfuzhengput")
				end
			end
			if card1 then
				room:getThread():delay()
				room:moveCardTo(card1, targets[1], nil, sgs.Player_DrawPile, reason)
			end
			if card2 then
				room:getThread():delay()
				room:moveCardTo(card2, targets[2], nil, sgs.Player_DrawPile, reason)
			end
		end
	end
}

sr_fuzhengvs = sgs.CreateViewAsSkill{
	name = "sr_fuzheng",
	n = 0,
	view_as = function(self,cards)
		return sr_fuzhengcard:clone()
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "@@sr_fuzheng"
	end
}

sr_fuzheng = sgs.CreateTriggerSkill{
	name = "sr_fuzheng$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = sr_fuzhengvs,
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Start then return false end
		if not player:hasLordSkill(self:objectName()) then return false end
		local room = player:getRoom()
		local players = sgs.SPlayerList()
		local others = room:getOtherPlayers(player)
		for _,p in sgs.qlist(others) do
			if p:getKingdom() == "wu" then
				players:append(p)
			end
		end
		if players:isEmpty() then return false end
		room:getThread():delay()
		room:askForUseCard(player,"@@sr_fuzheng","@sr_fuzheng")			
		return false
	end
}
sr_sunquan:addSkill(sr_fuzheng)

sr_sunquan:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_sunquan"] = "SR孫權",
["&sr_sunquan"] = "孫權",
["sr_quanheng"] = "權衡",
["sr_quanhengcard"] = "權衡",
["srwuzhong"] = "當【無中生有】使用",
["srsha"] = "當【殺】使用",
["srquxiao"] = "取消",
["srnormal"] = "當作【普通殺】使用",
["srfire"] = "當作【火殺】使用",
["srthunder"] = "當作【雷殺】使用",
[":sr_quanheng"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將至少一張手牌當一張"..
"【無中生有】或【殺】使用，若你以此法使用的牌被【無懈可擊】或【閃】響應時，你摸等量的牌。",
["sr_xionglve"] = "雄略",
["sr_xionglvecard"] = "雄略",
["sr_xionglvebasic"] = "雄略-基本牌",
["sr_xionglveslash"] = "雄略",
["sr_xionglveequip"] = "雄略",
["sr_xionglvetrick"] = "雄略-錦囊牌",
["sr_xionglveguohe"] = "雄略",
["sr_xionglveshunshou"] = "雄略",
["sr_xionglvehuogong"] = "雄略",
["sr_xionglvejiedao"] = "雄略",
["sr_xionglvejiedao1"] = "雄略",
["sr_xionglvetiesuo"] = "雄略",
["sr_xionglvejuedou"] = "雄略",
["srlve"] = "略",
["srcanslash"] = "當【殺】使用",
["srcanfireslash"] = "當【火殺】使用",
["srcanthunderslash"] = "當【雷殺】使用",
["srcananaleptic"] = "當【酒】使用",
["srcanpeach"] = "當【桃】使用",
["srcanjuedou"] = "當【決鬥】使用",
["srcanwuzhong"] = "當【無中生有】使用",
["srcanshunshou"] = "當【順手牽羊】使用",
["srcanguohe"] = "當【過河拆橋】使用",
["srcanjiedao"] = "當【借刀殺人】使用",
["srcanhuogong"] = "當【火攻】使用",
["srcanwugu"] = "當【五穀豐登】使用",
["srcantaoyuan"] = "當【桃園結義】使用",
["srcannanman"] = "當【南蠻入侵】使用",
["srcanwanjian"] = "當【萬箭齊發】使用",
["srcantiesuo"] = "當【鐵索連環】使用",
[":sr_xionglve"] = "摸牌階段，你可以放棄摸牌，改為展示牌堆頂的兩張牌，你獲得其中一張，然後將另一張牌置於"..
"你的武將牌上，稱為“略”。出牌階段，你可以將一張基本牌或錦囊牌的“略”當與之同類別的任意一張牌（延時類錦囊"..
"牌除外）使用，將一張裝備牌的“略”置於一名其他角色裝備區內的相應位置。",
["sr_fuzheng"] = "輔政",
["srfuzhengput"] = "請選擇一張手牌，以便置於牌堆頂",
[":sr_fuzheng"] = "<font color=\"orange\"><b>主公技，</b></font>回合開始階段開始時，你可以令至多兩名其他吳"..
"勢力各摸一張牌，然後這些角色依次將一張手牌置於牌堆頂。",
["@sr_fuzheng"] = "你可以發動“輔政”",
["~sr_fuzheng"] = "選擇兩名其他吳勢力角色",
["sr_fuzheng1"] = "輔政",
["sr_fuzheng2"] = "輔政",
["$sr_quanheng"] = "容我三思。",
["$sr_xionglve1"] = "識大體，棄細物，此乃君道。",
["$sr_xionglve2"] = "知己長短方能避短就長。",
["$sr_fuzheng"] = "望諸位各司其職，各出其力。",
["~sr_sunquan"] = "父親……大哥……仲謀愧矣……",
["losesr_quanheng"] = "失去【權衡】",
["losesr_xionglve"] = "失去【雄略】",
}

--SR陸遜
sr_luxun = sgs.General(extension, "sr_luxun", "wu", 3)

--待劳
sr_dailaocard = sgs.CreateSkillCard{
	name = "sr_dailaocard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_dailao")
		local card = room:askForCard(source, ".,Equip", "@sr_dailao:"..targets[1]:objectName(), sgs.QVariant(), sgs.CardDiscarded)
		if card then
			if not targets[1]:isNude() and targets[1]:canDiscard(targets[1],"he") then
				room:askForDiscard(targets[1],"sr_dailao",1,1,false,true)
			end
		else
			if source:isAlive() then source:drawCards(1) end
			if targets[1]:isAlive() then targets[1]:drawCards(1) end
		end
		if source:isAlive() then source:turnOver() end
		if targets[1]:isAlive() then targets[1]:turnOver() end
	end
}

sr_dailao = sgs.CreateViewAsSkill{
	name = "sr_dailao", 
	n = 0, 
	view_as = function(self, cards)
		return sr_dailaocard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_dailaocard")
	end
}
sr_luxun:addSkill(sr_dailao)

--诱敌
sr_youdicard = sgs.CreateSkillCard{
	name = "sr_youdicard", 
	target_fixed = true, 
	will_throw = true, 	
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_youdi")
		room:broadcastSkillInvoke("sr_youdi")
		local n = self:subcardsLength()
		room:throwCard(self,source,source)		
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("youdisource") and p:canDiscard(p,"he") then
				if p:getCardCount() <= n then
					p:throwAllHandCardsAndEquips()
				else					
					room:askForDiscard(p,"sr_youdi",n,n,false,true)
				end
			end
		end		
	end
}
sr_youdivs = sgs.CreateViewAsSkill{
	name = "sr_youdi", 
	n = 999, 
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local sr = sr_youdicard:clone()
		for _,c in ipairs(cards) do
			sr:addSubcard(c)
		end
		sr:setSkillName(self:objectName())
		return sr
	end, 
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "@@sr_youdi"
	end
}

sr_youdi = sgs.CreateTriggerSkill{
	name = "sr_youdi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.CardAsked,sgs.CardResponded},
	view_as_skill = sr_youdivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.card:isKindOf("Slash") and use.to:contains(player) then			
				room:setPlayerFlag(use.from,"youdisource")								
			end
		elseif event == sgs.CardAsked then
			local pattern = data:toStringList()[1]
			if pattern ~= "jink" then return false end			
			if sgs.Sanguosha:getCurrentCardUseReason() ~= 1 then return false end
			if player:faceUp() then return false end			
			if not player:askForSkillInvoke(self:objectName(),data) then return false end
			room:notifySkillInvoked(player,"sr_youdi")
			room:broadcastSkillInvoke("sr_youdi")
			player:turnOver()
			local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			jink:setSkillName(self:objectName())
			room:provide(jink)
			return true
		elseif event == sgs.CardResponded then
			local card_star = data:toCardResponse().m_card
			if player:isKongcheng() then return false end
			if card_star:isKindOf("Jink") and data:toCardResponse().m_isUse and player:canDiscard(player,"h") then
				room:askForUseCard(player,"@@sr_youdi","@sr_youdi")
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("youdisource") then
						room:setPlayerFlag(p,"-youdisource")
					end
				end
			end
		end
		return false
	end,	
}
sr_luxun:addSkill(sr_youdi)

--儒雅
sr_ruya = sgs.CreateTriggerSkill{
	name = "sr_ruya",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, "sr_ruya")
				room:broadcastSkillInvoke("sr_ruya")
				player:drawCards(player:getMaxHp())
				player:turnOver()
			end
		end
		return false
	end
}

sr_luxun:addSkill(sr_ruya)
sr_luxun:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_luxun"] = "SR陸遜",
["&sr_luxun"] = "陸遜",
["sr_dailao"] = "待勞",
[":sr_dailao"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名其他角色與你各摸一張牌" ..
"或者各棄一張牌，然後你與其依次將武將牌翻面",
["@sr_dailao"] = "你可以棄置一張牌並令 %src 棄置一張牌，否則你與其各摸一張牌",
["sr_youdi"] = "誘敵",
["@sryoudi-discard"] = "你可以棄置一張牌，然後此【殺】被【閃】響應時，對方棄置所有手牌",
[":sr_youdi"] = "若你的武將牌背面朝上，你可以將其翻面來視為你使用一張閃。每當你使用閃響應一名角色使用的殺"..
"時，你可以額外棄置任意數量的手牌，然後該角色棄置等量的牌",
["@sr_youdi"] = "你可以發動【誘敵】",
["~sr_youdi"] = "選擇任意張手牌",
["sr_ruya"] = "儒雅",
[":sr_ruya"] = "當你失去最後的手牌時，你可以將手牌補至你體力上限的張數，然後你的武將牌翻面",
["$sr_dailao1"] = " 廣施方略，以觀其變。",
["$sr_dailao2"] = "散兵游勇，不攻自破。",
["$sr_youdi"] = "兵者，以詐利，以利動。",
["$sr_ruya"] = "勞謙虛己，則負之者重。",
["~sr_luxun"] = "吾尚不堪大任！",
["losesr_youdi"] = "失去【誘敵】",
["losesr_dailao"] = "失去【待勞】",
["losesr_ruya"] = "失去【儒雅】",
}

--SR周瑜
sr_zhouyu = sgs.General(extension, "sr_zhouyu", "wu", 3)

--英才
sr_yingcai = sgs.CreateTriggerSkill{
	name = "sr_yingcai", 
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, "sr_yingcai")
				room:broadcastSkillInvoke("sr_yingcai")
				local card_to_get = {}
				local card_to_throw = {}
				local suits = {}
				while true do
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
					local suit = card:getSuit()
					if table.contains(suits,suit) then
						table.insert(card_to_get, id)
					else
						if #suits < 2 then
							table.insert(suits,suit)
							table.insert(card_to_get, id)
						else
							table.insert(card_to_throw, id)
							break
						end
					end
				end
				if #card_to_throw > 0 then
					for _,card in ipairs(card_to_throw) do
						room:throwCard(card, nil, nil)
					end
				end
				if #card_to_get > 0 then
					for _,card in pairs(card_to_get) do
						room:obtainCard(player, card, true)
					end
				end
				return true
			end
		end
		return false
	end
}
sr_zhouyu:addSkill(sr_yingcai)

--伪报
sr_weibaocard = sgs.CreateSkillCard{
	name = "sr_weibaocard",
	target_fixed = true,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_weibao")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "sr_weibao", nil)
		room:moveCardTo(self, source,nil, sgs.Player_DrawPile, reason,false)		
		room:getThread():delay()
		local dest = targets[1]
		if not dest then return end
		local suit = room:askForSuit(dest, "sr_weibao")
		local log = sgs.LogMessage()
		log.type = "#ChooseSuit"
		log.from = dest
		log.arg =  sgs.Card_Suit2String(suit)
		room:sendLog(log)
		local ids = room:getNCards(1, false)
		local card = sgs.Sanguosha:getCard(ids:at(0))
		room:obtainCard(dest, card,false)
		room:showCard(dest, ids:at(0))
		if card:getSuit() ~= suit then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = dest
			room:damage(damage)
		end
	end
}
sr_weibao = sgs.CreateViewAsSkill{
	name = "sr_weibao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = sr_weibaocard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#sr_weibaocard") 
		end
		return false
	end
}
sr_zhouyu:addSkill(sr_weibao)

--筹略
sr_choulvecard = sgs.CreateSkillCard{
	name = "sr_choulvecard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName() and 
			to_select:objectName() ~= targets[1]:objectName()	
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	about_to_use = function(self, room, cardUse)
		local zhouyu = cardUse.from

		local l = sgs.LogMessage()
		l.from = zhouyu
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)

		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		
		thread:trigger(sgs.PreCardUsed, room, zhouyu, data)
		room:notifySkillInvoked(zhouyu,"sr_choulve")
		room:broadcastSkillInvoke("sr_choulve")
		
		-- local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, zhouyu:objectName(),
		-- "", "sr_choulve", "")
		-- room:moveCardTo(self, zhouyu, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, zhouyu, data)
		thread:trigger(sgs.CardFinished, room, zhouyu, data)
	end,
	on_use = function(self, room, source, targets)
		--room:notifySkillInvoked(source, "sr_choulve")		
		local first = targets[1]
		local second = targets[2]
		local pointfirst
		local pointsecond
		local card_id1
		local card_id2
		local card1
		local card2
		if source:getHandcardNum() > 0 then
			local prompt1 = string.format("srchoulvegive:%s", first:objectName())
			local cardgive1 = room:askForExchange(source, "sr_choulve1", 1, 1, false, prompt1)
			card_id1 = cardgive1:getSubcards():first()	
			card1 = sgs.Sanguosha:getCard(card_id1)
			room:obtainCard(first, card1,false)
			pointfirst = card1:getNumber()
		else			
			return 
		end
		if source:getHandcardNum() > 0 then
			local prompt2 = string.format("srchoulvegive:%s", second:objectName())
			local cardgive2 = room:askForExchange(source, "sr_choulve2", 1, 1, false, prompt2)
			card_id2 = cardgive2:getSubcards():first()	
			card2 = sgs.Sanguosha:getCard(card_id2)
			room:obtainCard(second, card2,false)
			pointsecond = card2:getNumber()
		else			
			room:obtainCard(source, card1,false)
			return 
		end
		if card_id1 and card_id2 then 
			room:showCard(first, card_id1)
			room:getThread():delay()
			room:showCard(second, card_id2)
			room:getThread():delay()
		end
		if pointfirst and pointsecond then
			if pointfirst ~= pointsecond then
				if pointfirst > pointsecond then
					room:setPlayerFlag(source, "srchoulvebuff")
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("sr_choulve")					
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = first
					use.to:append(second)
					room:useCard(use)
					room:setPlayerFlag(source, "-srchoulvebuff")
				else
					room:setPlayerFlag(source, "srchoulvebuff")
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("sr_choulve")
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = second
					use.to:append(first)
					room:useCard(use)
					room:setPlayerFlag(source, "-srchoulvebuff")
				end
			end
		end
	end
}
sr_choulvevs = sgs.CreateViewAsSkill{
	name = "sr_choulve",
	n = 0,
	view_as = function(self, cards)
		local card = sr_choulvecard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		if player:getHandcardNum() >= 2 then
			return not player:hasUsed("#sr_choulvecard") 
		end
		return false
	end
}

sr_choulve = sgs.CreateTriggerSkill{
	name = "sr_choulve", 
	--frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damage}, 
	view_as_skill = sr_choulvevs, 
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local room = player:getRoom()
		local srzhouyu = room:findPlayerBySkillName(self:objectName())
		if not srzhouyu then return false end
		if srzhouyu:hasFlag("srchoulvebuff") then 
			if damage.card and damage.card:isKindOf("Slash") then
				room:notifySkillInvoked(srzhouyu,"sr_choulve")
				room:broadcastSkillInvoke("sr_choulve")
				srzhouyu:drawCards(1)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		 return target
	end
}
sr_zhouyu:addSkill(sr_choulve)
sr_zhouyu:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_zhouyu"] = "SR周瑜",
["&sr_zhouyu"] = "周瑜",
["sr_yingcai"] = "英才",
[":sr_yingcai"] = "摸牌階段，你可以放棄摸牌，改為展示牌堆頂的一張牌，你重複此流程直到你展示出第三種花色"..
"的牌時，將這張牌置入棄牌堆，然後獲得其餘的牌。",
["sr_weibao"] = "偽報",
[":sr_weibao"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將一張手牌置於牌堆頂，然後" ..
"令一名其他角色選擇一種花色後摸一張牌並展示之，若此牌與所選花色不同，你對其造成1點傷害。",
["#sr_weibao"] = "選擇一名其他角色為目標",
["sr_choulve"] = "籌略",
["sr_choulvecard"] = "籌略",
["srchoulvegive"] = "請交給該角色（%src）一張手牌",
[":sr_choulve"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以交給兩名其他角色各一張手牌，" ..
"然後依次展示之，若點數不同，視為點數較大的一方對另一方使用一張【殺】，該【殺】造成傷害後，你摸一張牌。",
["$sr_yingcai"] = "汝等看好了。",
["$sr_weibao"] = "一步步走向絕境吧！",
["$sr_choulve"] = "一切如我所料。",
["~sr_zhouyu"] = "誰高一籌，我心中有數！",
["losesr_yingcai"] = "失去【英才】",
["losesr_weibao"] = "失去【偽報】",
["losesr_choulve"] = "失去【籌略】",
}

--SR呂蒙
sr_lvmeng = sgs.General(extension, "sr_lvmeng", "wu", 4)

--誓学
sr_shixue = sgs.CreateTriggerSkill{
	name = "sr_shixue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.CardResponded,sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			local from = use.from
			if not from or not card:isKindOf("Slash") or not from:hasSkill(self:objectName()) or
				from:objectName() ~= player:objectName() then
				return false 
			end
			if not room:askForSkillInvoke(from,self:objectName(),data) then return false end
			room:broadcastSkillInvoke("sr_shixue")
			room:setPlayerFlag(from,"shixueused")
			from:drawCards(2)
		elseif event == sgs.CardResponded then
			local res = data:toCardResponse()
			local card = res.m_card
			if card:isKindOf("Jink") and res.m_isUse then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("shixueused") and not p:isNude() then
						room:broadcastSkillInvoke("sr_shixue")
						room:notifySkillInvoked(p,"sr_shixue")
						if p:getCardCount() <= 2 then
							p:throwAllHandCardsAndEquips()
						else
							room:askForDiscard(p,self:objectName(),2,2,false,true)
						end
						room:setPlayerFlag(p,"-shixueused")
					end 
				end
			end
		else
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then			
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("shixueused") then					
						room:setPlayerFlag(p,"-shixueused")
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
sr_lvmeng:addSkill(sr_shixue)

--国士
sr_guoshi = sgs.CreateTriggerSkill{
	name = "sr_guoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local lvmeng = room:findPlayerBySkillName(self:objectName())
		if not lvmeng or lvmeng:isDead() or not lvmeng:hasSkill(self:objectName()) then return false end		
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:removeTag("srguoshicard")
			end
		else
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				if room:askForSkillInvoke(lvmeng,"sr_guoshibegin",data) then
					room:notifySkillInvoked(lvmeng,"srguoshi")
					room:broadcastSkillInvoke("sr_guoshi",1)
					local ids = room:getNCards(2)
					room:askForGuanxing(lvmeng,ids,0)
				end
			elseif phase == sgs.Player_Finish then
				local room = player:getRoom()				
				local DiscardPile = room:getDiscardPile()
				local tag = room:getTag("srguoshicard"):toString():split("+")
				room:removeTag("srguoshicard")
				if #tag == 0 then return false end
				local toGainList = sgs.IntList()				
				for _,is in ipairs(tag) do
					if is~="" and DiscardPile:contains(tonumber(is)) then
						toGainList:append(tonumber(is))
					end
				end			
				if toGainList:isEmpty() then return false end				
				if not room:askForSkillInvoke(lvmeng,"sr_guoshiend",data) then return false end	
				room:notifySkillInvoked(lvmeng,"srguoshi")			
				room:broadcastSkillInvoke("sr_guoshi",2)
				room:fillAG(toGainList)
				local card_id = room:askForAG(player, toGainList, false, "sr_guoshi")
				room:clearAG()
				if card_id ~= -1 then
					local gain_card = sgs.Sanguosha:getCard(card_id)					
					player:obtainCard(gain_card)
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

sr_guoshimove = sgs.CreateTriggerSkill{
	name = "#sr_guoshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return false end		
		local move = data:toMoveOneTime()			
		if (move.to_place == sgs.Player_DiscardPile) 
			and ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == 
				sgs.CardMoveReason_S_REASON_DISCARD) 
			or (move.reason.m_reason == sgs.CardMoveReason_S_REASON_JUDGEDONE)) then
			local oldtag = room:getTag("srguoshicard"):toString():split("+")
			local totag = {}
			for _,is in ipairs(oldtag) do
				table.insert(totag,tonumber(is))
			end					
			for _, card_id in sgs.qlist(move.card_ids) do
				table.insert(totag,card_id)
			end	
			room:setTag("srguoshicard",sgs.QVariant(table.concat(totag,"+")))
		end		
	end
}

sr_lvmeng:addSkill(sr_guoshi)
sr_lvmeng:addSkill(sr_guoshimove)
extension:insertRelatedSkills("sr_guoshi","#sr_guoshi")
sr_lvmeng:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_lvmeng"] = "SR呂蒙",
["&sr_lvmeng"] = "呂蒙",
["sr_shixue"] = "誓學",
[":sr_shixue"] = "當你使用【殺】指定目標後，你可以摸兩張牌，若如此做，則當此【殺】被【閃】響應後，你須棄置兩張牌",
["sr_guoshi"] = "國士",
[":sr_guoshi"] = "任一角色的回合開始階段開始時，你可以觀看牌堆頂的兩張牌，然後可以將其中任意張牌置於牌堆"..
"底，將其餘的牌以任意順序置於牌堆頂；任一角色的回合結束階段開始時,你可以令其獲得本回合因棄置或者判定進入"..
"棄牌堆的一張牌",
["sr_guoshibegin"] = "國士",
["sr_guoshiend"] = "國士",
["$sr_shixue"] = "不經一事，不長一智。",
["$sr_guoshi1"] = "此事需從長計議。",
["$sr_guoshi2"] = "小不忍，則亂大謀。",
["~sr_lvmeng"] = "大智難盡，吾已無計可施。",
["losesr_guoshi"] = "失去【國士】",
["losesr_shixue"] = "失去【誓學】",
}

--SR甘寧
sr_ganning = sgs.General(extension, "sr_ganning", "wu", 4)

--劫袭
sr_jiexicard = sgs.CreateSkillCard{
	name = "sr_jiexicard", 
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
		local success = source:pindian(target, "sr_jiexi", self)
		local data = sgs.QVariant()
		data:setValue(target)
		while success do
			if target:isKongcheng() then
				break
			elseif source:isKongcheng() then
				break
			elseif source:askForSkillInvoke("sr_jiexi", data) then
				local room = source:getRoom()
				room:notifySkillInvoked(source,"sr_jiexi")
				room:broadcastSkillInvoke("sr_jiexi")
				success = source:pindian(target, "sr_jiexi")
			else
				break
			end
		end
	end
}
sr_jiexivs = sgs.CreateViewAsSkill{
	name = "sr_jiexi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_jiexicard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_jiexicard")
	end
}

sr_jiexi = sgs.CreateTriggerSkill{
	name = "sr_jiexi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Pindian}, 
	view_as_skill = sr_jiexivs, 
	on_trigger = function(self, event, player, data) 
		local pindian = data:toPindian()
		if pindian.reason == "sr_jiexi" then
			if pindian.from_number > pindian.to_number then
				if pindian.from:objectName() == player:objectName() then
					if not pindian.to:isAllNude() and pindian.from:canDiscard(pindian.to,"hej") then
						local room = player:getRoom()						
						room:notifySkillInvoked(pindian.from, "sr_jiexi")						
						local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
						dismantlement:setSkillName("sr_jiexi")
						local use = sgs.CardUseStruct()
						use.card = dismantlement
						use.from = pindian.from
						use.to:append(pindian.to)
						room:useCard(use)
					end
				end
			end
		end
		return false
	end
}
sr_ganning:addSkill(sr_jiexi)

--游侠
sr_youxiacard = sgs.CreateSkillCard{
	name = "sr_youxiacard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select) 
		if (#targets >= 2) or (to_select:objectName() == sgs.Self:objectName()) then
			return false
		end
		return not to_select:isNude()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_youxia")
		room:broadcastSkillInvoke("sr_youxia",1)
		source:turnOver()
		if not source:isAlive() then return end
		local moves = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		move1.card_ids:append(room:askForCardChosen(source, targets[1], "he", "sr_youxia"))
		move1.to = source
		move1.to_place = sgs.Player_PlaceHand
		moves:append(move1)
		if #targets == 2 then
			local move2 = sgs.CardsMoveStruct()
			move2.card_ids:append(room:askForCardChosen(source, targets[2], "he", "sr_youxia"))
			move2.to = source
			move2.to_place = sgs.Player_PlaceHand
			moves:append(move2)
		end
		room:moveCardsAtomic(moves, false)
	end
}
sr_youxia = sgs.CreateViewAsSkill{
	name = "sr_youxia", 
	n = 0, 
	view_as = function(self, cards) 
		return sr_youxiacard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:faceUp()
	end
}

-- sr_youxia = sgs.CreateTriggerSkill{
-- 	name = "sr_youxia",
-- 	frequency = sgs.Skill_NotFrequent,
-- 	events = {sgs.Damage},
-- 	view_as_skill = sr_youxiavs,
-- 	on_trigger = function(self, event, player, data)
-- 		local room = player:getRoom()
-- 		local srganning = room:findPlayerBySkillName("sr_youxia")
-- 		if not srganning or srganning:isDead() then return false end		
-- 		if not srganning:hasSkill("sr_youxia") then return false end		
-- 		if player:objectName() == srganning:objectName() then return false end		
-- 		if srganning:faceUp() then return false end		
-- 		local damage = data:toDamage()
-- 		local card = damage.card
-- 		if card then
-- 			if card:isKindOf("Slash") then
-- 				if srganning:getHandcardNum() >= 2 then
-- 					if room:askForSkillInvoke(srganning, "sr_youxia", data) then
-- 						room:notifySkillInvoked(srganning, "sr_youxia")
-- 						room:broadcastSkillInvoke("sr_youxia",2)
-- 						if room:askForDiscard(srganning, "sr_youxia", 2, 2, false, false) then
-- 							srganning:turnOver()
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self, target)
-- 		return target and target:isAlive()
-- 	end
-- }
sr_youxiaPro = sgs.CreateProhibitSkill{
	name = "#sr_youxiaPro",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("sr_youxia") and (card:isKindOf("Slash") or card:isKindOf("Duel")) and not to:faceUp()
	end
}

sr_ganning:addSkill(sr_youxia)
sr_ganning:addSkill(sr_youxiaPro)
extension:insertRelatedSkills("sr_youxia","#sr_youxiaPro")
sr_ganning:addSkill("#sr_choose")
	
sgs.LoadTranslationTable{
["sr_ganning"] = "SR甘寧",
["&sr_ganning"] = "甘寧",
["sr_jiexi"] = "劫襲",
[":sr_jiexi"] = "出牌階段，你可以與一名其他角色拼點，若你贏，視為對其使用一張【過河拆橋】。你可以重複此流"..
"程直到你以此法拼點沒贏。<font color=\"green\"><b>每階段限一次。 </b></font>",
["sr_youxia"] = "遊俠",
-- [":sr_youxia"] = "出牌階段，若你的武將牌正面朝上，你可以將你的武將牌翻面，然後從一名至兩名其他角色處各"..
--"獲得一張牌；當一名其他角色使用【殺】造成傷害後，若你的武將牌背面朝上，你可以棄置兩張手牌將之翻回正面。",
[":sr_youxia"] = "出牌階段，若你的武將牌正面朝上，你可以將你的武將牌翻面，然後從一名至兩名其他角色處各獲"..
"得一張牌；<font color=\"blue\"><b>鎖定技，</b></font>若你的武將牌背面朝上，你不是【殺】或【決鬥】的合法目標。",
["$sr_jiexi"] = "伙計們，一口氣拿下！",
["$sr_youxia1"] = "給我打他個措手不及！",
["$sr_youxia2"] = "這下要再不打，可就晚了！",
["~sr_ganning"] = "壞了，這下跑不了！",
["losesr_jiexi"] = "失去【劫襲】",
["losesr_youxia"] = "失去【遊俠】",
}

--SR黃蓋
sr_huanggai = sgs.General(extension, "sr_huanggai", "wu", 4)

--舟焰
sr_zhouyancard = sgs.CreateSkillCard{
	name = "sr_zhouyancard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", sgs.Card_NoSuit, 0)
			return to_select:objectName() ~= sgs.Self:objectName() and 
			not sgs.Self:isProhibited(to_select, fireattack)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		while not source:hasFlag("srzhouyannotdo") do
			local dest = targets[1]
			if not dest:isAlive() then return end			
			room:notifySkillInvoked(source, "sr_zhouyan")
			room:broadcastSkillInvoke("sr_zhouyan")
			room:setPlayerFlag(source, "srzhouyannotdo")
			dest:drawCards(1)
			local fireattack = sgs.Sanguosha:cloneCard("FireAttack", sgs.Card_NoSuit, 0)
			fireattack:setSkillName("sr_zhouyan")
			fireattack:deleteLater()
			local use = sgs.CardUseStruct()
			use.card = fireattack
			use.from = source
			use.to:append(dest)
			room:useCard(use)
		end
	end
}
sr_zhouyanvs = sgs.CreateViewAsSkill{
	name = "sr_zhouyan",
	n = 0,
	view_as = function(self, cards)
		return sr_zhouyancard:clone()		
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("srzhouyannotdo")
	end
}

sr_zhouyan = sgs.CreateTriggerSkill{
	name = "sr_zhouyan",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},
	view_as_skill = sr_zhouyanvs,  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card:isKindOf("FireAttack") then
			if room:askForSkillInvoke(player,"sr_zhouyan_draw",data) then
				room:notifySkillInvoked(player,"sr_zhouyan")
				room:broadcastSkillInvoke("sr_zhouyan")
				player:drawCards(1)
			end			
			if player:hasFlag("srzhouyannotdo") then
				if card:getSkillName() == "sr_zhouyan" then
					if room:askForSkillInvoke(player,self:objectName(),data) then
						room:setPlayerFlag(player, "-srzhouyannotdo")
					end
				end
			end
		end
		return false
	end
}

sr_huanggai:addSkill(sr_zhouyan)

--诈降
-- sr_zhaxiangcard = sgs.CreateSkillCard{
-- 	name = "sr_zhaxiangcard",
-- 	target_fixed = false,
-- 	will_throw = false,
-- 	filter = function(self, targets, to_select)
-- 		if #targets == 0 then
-- 			return to_select:objectName() ~= sgs.Self:objectName() and to_select:canSlash(sgs.Self, nil, false)
-- 		end
-- 		return false
-- 	end,
-- 	on_use = function(self, room, source, targets)
-- 		room:notifySkillInvoked(source, "sr_zhaxiang")
-- 		local dest = targets[1]
-- 		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
-- 		slash:setSkillName("sr_zhaxiang")
-- 		local use = sgs.CardUseStruct()
-- 		use.card = slash
-- 		use.from = dest
-- 		use.to:append(source)
-- 		room:useCard(use)
-- 		if source:isAlive() then
-- 			if source:canSlash(dest, nil, false) then
-- 				local choice = room:askForChoice(source, "sr_zhaxiang", "srzhaxiangslash+cancel")
-- 				if choice == "srzhaxiangslash" then
-- 					source:drawCards(1)
-- 					local useback = sgs.CardUseStruct()
-- 					useback.card = slash
-- 					useback.from = source
-- 					useback.to:append(dest)
-- 					room:useCard(useback, false)
-- 				end
-- 			end
-- 		end
-- 	end
-- }
-- sr_zhaxiang = sgs.CreateViewAsSkill{
-- 	name = "sr_zhaxiang",
-- 	n = 0,
-- 	view_as = function(self, cards)
-- 		return sr_zhaxiangcard:clone()
-- 	end,
-- 	enabled_at_play = function(self, player)
-- 		return not player:hasUsed("#sr_zhaxiangcard") 
-- 	end
-- }
sr_zhaxiangcard = sgs.CreateSkillCard{
	name = "sr_zhaxiangcard",
	target_fixed =true,
	will_throw = false,	
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_zhaxiang")
		local cid = self:getSubcards():first()
		local c = sgs.Sanguosha:getCard(cid)
		room:setTag("zhaxiang",sgs.QVariant(c:objectName()))
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(),"sr_zhaxiang", nil)		
		local move = sgs.CardsMoveStruct(self:getSubcards(),source,nil,sgs.Player_PlaceHand,
			sgs.Player_DrawPile,reason)
		room:moveCardsAtomic(move,false)		
		local dest = room:askForPlayerChosen(source,room:getOtherPlayers(source),"sr_zhaxiang")
		room:removeTag("zhaxiang")
		if not dest then 
			source:obtainCard(self)
			return
		end
		local choice = ""
		if dest:isNude() then
			choice = "srshow"
		else
			choice = room:askForChoice(dest,"sr_zhaxiang","srshow+srgive")
		end
		if choice == "srgive" then
			local card = room:askForExchange(dest, "sr_zhaxiang", 1, 1, true, "#srzhaxiang:"..source:objectName())
			if not card then return end
			source:obtainCard(card)
			room:throwCard(self,nil,dest)
			return
		else
			local cardid = self:getSubcards():first()
			local card = sgs.Sanguosha:getCard(cardid)
			room:showCard(dest,cardid)
			dest:obtainCard(self)
			if card:isKindOf("Slash") then
				local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("sr_zhaxiang")
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = source
				use.to:append(dest)
				room:useCard(use,false)
			end
		end
	end
}
sr_zhaxiang = sgs.CreateViewAsSkill{
	name = "sr_zhaxiang",
	n = 1, 
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = sr_zhaxiangcard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end
}
sr_huanggai:addSkill(sr_zhaxiang)
sr_huanggai:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_huanggai"] = "SR黃蓋",
["&sr_huanggai"] = "黃蓋",
["sr_zhouyan"] = "舟焰",
["sr_zhouyancard"] = "舟焰",
[":sr_zhouyan"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名其他角色摸一張牌，若"..
"如此做，視為你對其使用一張【火攻】，你可以重複此流程直到你以此法未造成傷害。每當你使用【火攻】造成一次"..
"傷害後，你可以摸一張牌",
["sr_zhouyan_draw"] = "舟焰摸牌",
["sr_zhaxiang"] = "詐降",
["sr_zhaxiangcard"] = "詐降",
["srzhaxiangslash"] = "摸一張牌並視為對其使用一張【殺】",
-- [":sr_zhaxiang"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以指定一名其他角色，視為該"..
--"角色對你使用一張【殺】，以此法使用的【殺】結算後，你可以摸一張牌，然後視為對其使用一張【殺】。",
[":sr_zhaxiang"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將一張手牌扣置於牌堆頂，然"..
"後令一名其他角色選擇一項：交給你一張牌並棄置此牌；或展示並獲得此牌，若為【殺】，則視為你對其使用一張火"..
"屬性的【殺】（不計入出牌階段的使用限制）。",
["#srzhaxiang"] = "選擇一張交給 %src 的牌",
["srshow"] = "展示此牌",
["srgive"] = "交出一張牌",
["$sr_zhouyan"] = "待老夫來會會你！",
["$sr_zhaxiang"] = "肝腦塗地，無以為報！",
["~sr_huanggai"] = "這條老命，已是風中之燭！",
["losesr_zhouyan"] = "失去【舟焰】",
["losesr_zhaxiang"] = "失去【詐降】",
}

--SR大喬
sr_daqiao = sgs.General(extension,"sr_daqiao","wu",3,false)

--芳馨
sr_fangxincard = sgs.CreateSkillCard{
	name = "sr_fangxincard",
	target_fixed = true,
	will_throw = false,
	mute = true,	
	on_use = function(self,room,source,targets)		
		local cardid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(cardid)
		if card:getSuit() == sgs.Card_Diamond then
			local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,card:getNumber())
			indulgence:addSubcard(card)
			indulgence:setSkillName("sr_fangxin")
			room:useCard(sgs.CardUseStruct(indulgence,source,source))
		elseif card:getSuit() == sgs.Card_Club then
			local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,card:getNumber())
			supply_shortage:addSubcard(card)
			supply_shortage:setSkillName("sr_fangxin")
			room:useCard(sgs.CardUseStruct(supply_shortage,source,source))
		end
		local peach = sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit, 0)
		peach:setSkillName("sr_fangxin")		
		room:broadcastSkillInvoke("sk_fangxin")
		local dest = source
		local dying = room:getCurrentDyingPlayer()
		if dying then
			dest = dying
		end
		if not dest:isWounded() then return end
		room:useCard(sgs.CardUseStruct(peach,source,dest))		   	
	end		
}

sr_fangxin = sgs.CreateViewAsSkill{
	name = "sr_fangxin",
	n=1,
	view_filter = function(self,selected,to_select)
		if #selected >0 then return false end		
		if sgs.Self:containsTrick("indulgence") then 
			return to_select:getSuit() == sgs.Card_Club
		elseif sgs.Self:containsTrick("supply_shortage") then
			return to_select:getSuit() == sgs.Card_Diamond 
		else
			return to_select:getSuit() == sgs.Card_Club or to_select:getSuit() == sgs.Card_Diamond
		end
		return false	
	end,	
	view_as = function(self,cards)
		if #cards ~= 1 then return nil end		
		local acard = sr_fangxincard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName("sr_fangxin")		
		return acard
	end,
	enabled_at_play = function(self,player)
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
		indulgence:deleteLater()
		local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
		supply_shortage:deleteLater()
		return player:isWounded() and 
		not ((player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and 
			(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")))
	end,
	enabled_at_response = function(self,player,pattern)
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
		indulgence:deleteLater()
		local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
		supply_shortage:deleteLater()
		return string.find(pattern,"peach") and not player:hasFlag("Global_PreventPeach") and
		not ((player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and 
			(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")))
	end	
}

sr_daqiao:addSkill(sr_fangxin)

--细语
sr_xiyu = sgs.CreateTriggerSkill{
	name = "sr_xiyu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_RoundStart then return false end
		local targets = sgs.SPlayerList()
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if not p:isNude() and player:canDiscard(p,"he") then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player,targets,self:objectName(),true,true)
		if target then
			room:notifySkillInvoked(player, self:objectName())
			room:doAnimate(1, player:objectName(), target:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local to_throw = room:askForCardChosen(player,target,"he",self:objectName())
			local card = sgs.Sanguosha:getCard(to_throw)
			room:throwCard(card, target, player)
				
			local msg = sgs.msgMessage()
			msg.type = "#ExtraPlayPhase"
			msg.from = player
			msg.arg = self:objectName()
			room:sendmsg(msg)

			local phase = player:getPhase()--保存阶段
			player:setPhase(sgs.Player_NotActive)--角色设置回合外
			room:broadcastProperty(player,"phase")
			room:setCurrent(target)--设置目标为当前回合
			target:setPhase(sgs.Player_Play)		--设置目标出牌阶段
			room:broadcastProperty(target, "phase")
			local thread = room:getThread()
			if not thread:trigger(sgs.EventPhaseStart,room,target) then			
				thread:trigger(sgs.EventPhaseProceeding,room,target)
			end		
			thread:trigger(sgs.EventPhaseEnd,room,target)		
			target:setPhase(sgs.Player_NotActive)	--设置目标回合外	
			room:broadcastProperty(target,"phase")
			room:setCurrent(player) --设置当前回合为玩家
			player:setPhase(phase) --设置玩家保存的阶段
			room:broadcastProperty(player,"phase")		
			return false
		end
	end
}

sr_daqiao:addSkill(sr_xiyu)

--[[
sr_wanrou = sgs.CreateTriggerSkill{
	name = "sr_wanrou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime,sgs.BeforeCardsMove,sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()		
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.from == sgs.Player_Discard) and player:hasFlag("sr_wanrouDiamondMaxCards") then
				room:setPlayerFlag(player, "-sr_wanrouDiamondMaxCards")
				for i = 1, player:getMark(self:objectName()) ,1 do
					if player:askForSkillInvoke("sr_wanrou",data) then
						player:loseMark(self:objectName(),1)
						room:notifySkillInvoked(player, "sr_wanrou")
						room:broadcastSkillInvoke("sr_wanrou")					
						local target = room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName())
						if not target then return false end
						target:drawCards(1)
					end
				end
			end
		else
			local move = data:toMoveOneTime()		
			if move.to_place ~= sgs.Player_DiscardPile then return false end		
			local invoke = false
			local num = 0
			for i = 0, (move.card_ids:length()-1) ,1 do 
				local id = move.card_ids:at(i)
				if move.from_places:at(i) == sgs.Player_PlaceDelayedTrick then
					invoke = true
					num = num + 1		
				elseif move.from and move.from:objectName() == player:objectName() and sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
					invoke =true
					num = num + 1
				end			
			end
			if not invoke then return false end			
			if event == sgs.BeforeCardsMove then				
				if (player:getPhase() == sgs.Player_Discard) 
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD) then
					room:setPlayerFlag(player, "sr_wanrouDiamondMaxCards")
					player:gainMark(self:objectName(),num)
					return false
				end
				player:addMark(self:objectName(),num)
			else
				if player:getMark(self:objectName()) == 0 then return false end
				player:removeMark(self:objectName())
				if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
				room:notifySkillInvoked(player, "sr_wanrou")
				room:broadcastSkillInvoke("sr_wanrou")
				local target = room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName())
				if not target then return false end
				target:drawCards(1)
				return false
			end
		end
		return false
	end
}
]]--

sr_wanrou = sgs.CreateTriggerSkill{
	name = "sr_wanrou",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.to_place ~= sgs.Player_DiscardPile and move.to_place ~= sgs.Player_PlaceTable then return false end
		if not room:getTag("FirstRound"):toBool() and move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceDelayedTrick)) then
		  	for i = 0, (move.card_ids:length()-1) ,1 do 
				local id = move.card_ids:at(i)
				if (move.from_places:at(i) == sgs.Player_PlaceDelayedTrick) or sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "sr_wanrou-invoke", true, true)
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
		end
	end
}


sr_daqiao:addSkill(sr_wanrou)
sr_daqiao:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_daqiao"] = "SR大喬",
["&sr_daqiao"] = "大喬",
["sr_fangxin"] = "芳馨",
[":sr_fangxin"] = "當你需要使用一張【桃】時，你可以將一張<font color=\"black\"><b> ♣ </b></font>牌"..
"當【兵糧寸斷】或將一張<font color=\"red\"><b>♦</b></font>牌當【樂不思蜀】對自己使用，"..
"若如此做，視為你使用一張【桃】",
["sr_xiyu"] = "細語",
[":sr_xiyu"] = "你的回合開始時，你可以棄置一名角色的一張牌，然後該角色進行一個額外的出牌階段",
["sr_wanrou"] = "婉柔",
[":sr_wanrou"] = "你的<font color=\"red\"><b>♦</b></font>牌或你判定區的牌進入棄牌堆時，你可以令一名角"..
"色摸一張牌",
["sr_wanrou-invoke"] = "妳可以發動「婉柔」令一名角色摸一張牌",
["$sr_fangxin1"] = "您，累了",
["$sr_fangxin2"] = "不知您為何事煩惱",
["$sr_xiyu"] = "讓您費心了",
["$sr_wanrou"] = "我準備好了",
["~sr_daqiao"] = "青燈常伴，了此餘生",
["losesr_fangxin"] = "失去【芳馨】",
["losesr_xiyu"] = "失去【細語】",
["losesr_wanrou"] = "失去【婉柔】",
}

--SR孫尚香
sr_sunshangxiang = sgs.General(extension,"sr_sunshangxiang","wu",3,false)

--姻盟
sr_yinmengcard = sgs.CreateSkillCard{
	name = "sr_yinmengcard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName() and
			to_select:isMale() and not to_select:isKongcheng()
	end,
	on_use = function(self,room,source,targets)
		room:notifySkillInvoked(source,"sr_yinmeng")
		local id = room:askForCardChosen(source, targets[1], "h", "sr_yinmeng")
		local card1 = sgs.Sanguosha:getCard(id) 					
		room:showCard(targets[1], card1:getEffectiveId()) 
		room:setTag("yinmengid",sgs.QVariant(id))
		room:setPlayerFlag(targets[1],"yinmengname")
		local card2 = room:askForCardShow(source, source, "sr_yinmeng")
		room:removeTag("yinmengid")
		room:setPlayerFlag(targets[1],"-yinmengname")
		room:showCard(source, card2:getEffectiveId()) 
		if card1:getTypeId() == card2:getTypeId() then
			if source:isAlive() then source:drawCards(1) end
			if targets[1]:isAlive() then targets[1]:drawCards(1) end
		else
			if source:canDiscard(targets[1],card1:getEffectiveId()) then
				room:throwCard(card1,targets[1],source)
			end
		end
	end
}

sr_yinmeng = sgs.CreateViewAsSkill{
	name = "sr_yinmeng",
	n=0,
	view_as = function(self,cards)
		return sr_yinmengcard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:isKongcheng() and player:usedTimes("#sr_yinmengcard") < math.max(player:getLostHp(),1) 
	end
}

sr_sunshangxiang:addSkill(sr_yinmeng)

--习武
sr_xiwu = sgs.CreateTriggerSkill{
	name = "sr_xiwu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirmed,sgs.CardResponded,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or not use.card or not use.card:isKindOf("Slash") or 
				not use.from:hasSkill(self:objectName()) 
				or	use.from:objectName() ~= player:objectName() then return false end
			room:setPlayerFlag(use.from,"srxiwusource")
			for _,p in sgs.qlist(use.to) do
				room:setPlayerFlag(p,"srxiwutarget")
			end			
		elseif event == sgs.CardResponded then
			local card = data:toCardResponse().m_card
			if not card:isKindOf("Jink") then return false end
			if not player:hasFlag("srxiwutarget") then return false end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("srxiwusource") then
					if not p:askForSkillInvoke("sr_xiwu",data) then return false end
					room:notifySkillInvoked(p,"sr_xiwu")
					room:broadcastSkillInvoke("sr_xiwu")
					if p:isAlive() then	p:drawCards(1) end
					if p:canDiscard(player,"h") then
						local id = room:askForCardChosen(p,player,"h","sr_xiwu")
						local c = sgs.Sanguosha:getCard(id)
						room:throwCard(c,player,p)
					end
				end
			end
		else
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			if not use.from or not use.from:hasFlag("srxiwusource") then return false end
			room:setPlayerFlag(use.from,"-srxiwusource")
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("srxiwutarget") then
					room:setPlayerFlag(p,"-srxiwutarget")
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

sr_sunshangxiang:addSkill(sr_xiwu)

--决裂
sr_jueliecard = sgs.CreateSkillCard{
	name = "sr_jueliecard",
	target_fixed = false,
	will_throw = true,
	mute = true,
	filter = function(self,targets,to_select)
		return #targets == 0 and to_select:getHandcardNum() ~= sgs.Self:getHandcardNum() and
		to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self,room,source,targets)
		local choice = ""
		if source:getHandcardNum() < targets[1]:getHandcardNum() and not targets[1]:canDiscard(targets[1],"h") and
			not source:canSlash(targets[1],nil,false) then 
			room:addPlayerHistory(source,"#sr_jueliecard",-1)
			return 
		end 
		room:notifySkillInvoked(source,"sr_juelie")
		room:broadcastSkillInvoke("sr_juelie")
		if source:getHandcardNum() < targets[1]:getHandcardNum() and not targets[1]:canDiscard(targets[1],"h") then
			choice = "srslash"
		elseif not source:canSlash(targets[1],nil,false) then
			choice = "srkeepsame"
		else
			choice = room:askForChoice(targets[1],"sr_juelie","srslash+srkeepsame")
		end
		if choice == "srslash" then
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			slash:setSkillName("sr_juelie")
			room:useCard(sgs.CardUseStruct(slash,source,targets[1]),false)
		elseif choice == "srkeepsame" then
			local snum = source:getHandcardNum()
			local tnum = targets[1]:getHandcardNum()
			if snum < tnum then
				if targets[1]:canDiscard(targets[1],"h") then
					room:askForDiscard(targets[1],"sr_juelie",tnum - snum,tnum - snum)
				end
			elseif snum>tnum then
				if targets[1]:isAlive() then targets[1]:drawCards(snum-tnum) end
			else
				return
			end
		else
			room:addPlayerHistory(source,"#sr_jueliecard",-1)
			return
		end
	end
}

sr_juelie = sgs.CreateViewAsSkill{
	name = "sr_juelie",
	n = 0,
	view_as = function(self,cards)
		return sr_jueliecard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#sr_jueliecard")
	end
}

sr_sunshangxiang:addSkill(sr_juelie)
sr_sunshangxiang:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_sunshangxiang"] = "SR孫尚香",
["&sr_sunshangxiang"] = "孫尚香",
["sr_yinmeng"] = "姻盟",
[":sr_yinmeng"] = "<font color=\"green\"><b>出牌階段限X次，</b></font>若你有手牌，你可以展示一名其他男" ..
"性角色的一張手牌，然後展示你的一張手牌，若兩張類型相同，你與其各摸一張牌；若不同，你棄置其展示的牌，"..
"<font color=\"red\"><b>X為你已損失的體力且至少為1</b></font>",
["$sr_yinmeng"] = "君心知我心，君意共我意",
["sr_xiwu"] = "習武",
[":sr_xiwu"] = "當你使用的【殺】被目標角色的【閃】響應後，你可以摸一張牌，然後棄置其一張手牌",
["$sr_xiwu"] = "休要小看我",
["sr_juelie"] = "決裂",
[":sr_juelie"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名手牌數與你不同的其他"..
"角色選擇一項：將手牌數調整至與你相等；或視為你對其使用一張殺（不計入出牌階段的使用限制）",
["$sr_juelie"] = "決不允許你這般胡來",
["~sr_sunshangxiang"] = "不，我不能輸",
["srkeepsame"] = "調整手牌",
["srslash"] = "視為被殺",
["losesr_yinmeng"] = "失去【姻盟】",
["losesr_xiwu"] = "失去【習武】",
["losesr_juelie"] = "失去【決裂】",
}

--SR曹操
sr_caocao = sgs.General(extension,"sr_caocao$","wei",4)

--招降
sr_zhaoxiang = sgs.CreateTriggerSkill{
	name = "sr_zhaoxiang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed, sgs.SlashEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local srcaocao = room:findPlayerBySkillName(self:objectName())
			if not srcaocao or srcaocao:isDead() or not srcaocao:hasSkill(self:objectName()) then return false end
			local use = data:toCardUse()
			local source = use.from
			local targets = use.to
			if not source or source:objectName() == srcaocao:objectName() then return false end
			if not targets:contains(player) then return false end
			local card = use.card
			if not card:isKindOf("Slash") then return false end			
			local cando = 0
			if not room:askForSkillInvoke(srcaocao, self:objectName(), data) then return false end
			if srcaocao:inMyAttackRange(source) then
				cando = 1
			else
				if not srcaocao:isNude() then
					if room:askForCard(srcaocao, "..", "srzhaoxiangdiscard", sgs.QVariant(), 
						sgs.Card_MethodDiscard) then
						cando = 1
					end
				end
			end
			if cando ~= 1 then return false end						
			room:notifySkillInvoked(srcaocao, "sr_zhaoxiang")
			room:broadcastSkillInvoke("sr_zhaoxiang")
			if source:isKongcheng() then
				room:setPlayerFlag(player, "srzhaoxiangslashnullified")
			else
				local choice = room:askForChoice(source, self:objectName(),
				 "srzhaoxianggetcard+srzhaoxiangslashnullified",data)
				if choice == "srzhaoxianggetcard" then
					local card_id = room:askForCardChosen(srcaocao, source, "h", "sr_zhaoxiang")
					room:obtainCard(srcaocao, card_id, false)
				elseif choice == "srzhaoxiangslashnullified" then
					room:setPlayerFlag(player, "srzhaoxiangslashnullified")
				end
			end
										
		end		
		if event == sgs.SlashEffected then
			if player:hasFlag("srzhaoxiangslashnullified") then 
				room:setPlayerFlag(player, "-srzhaoxiangslashnullified")
				local effect = data:toSlashEffect()
				local msg = sgs.LogMessage()
				msg.type = "#zhaoxiang"
				msg.from = effect.from
				msg.to:append(effect.to)
				msg.arg = effect.slash:objectName()
				room:sendLog(msg)
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
sr_caocao:addSkill(sr_zhaoxiang)

--治世
sr_zhishicard = sgs.CreateSkillCard{
	name = "sr_zhishicard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_zhishi")		
		local card = room:askForCard(targets[1],"BasicCard","#srbasic" .. source:objectName())
		if not card then
			room:damage(sgs.DamageStruct("sr_zhishi",source,targets[1]))
		end
		if targets[1]:isAlive() and targets[1]:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(targets[1], recover)
		end
	end
}
sr_zhishi = sgs.CreateViewAsSkill{
	name = "sr_zhishi", 
	n = 0, 	
	view_as = function(self, cards) 
		return sr_zhishicard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_zhishicard")
	end
}
sr_caocao:addSkill(sr_zhishi)

--奸雄
sr_jianxiong = sgs.CreateTriggerSkill{
	name = "sr_jianxiong$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if not damage.from:hasLordSkill(self:objectName()) then
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
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasLordSkill(self:objectName()) and (not player:isKongcheng()) and room:getCardPlace(id) == sgs.Player_PlaceTable then
						room:setPlayerFlag(p, "sr_jianxiongtarget")
						local card2 = room:askForCard(player,".|.|.|hand", "@sr_jianxiong:"..p:objectName(), data,sgs.Card_MethodDiscard)
						room:setPlayerFlag(p, "-sr_jianxiongtarget")
						if card2 then
							room:notifySkillInvoked(p, "sr_jianxiong")
							room:broadcastSkillInvoke("sr_jianxiong")
							local log = sgs.LogMessage()
							log.type = "#TriggerSkill"
							log.from = p
							log.arg = self:objectName()
							room:sendLog(log)
							room:obtainCard(p, card, true)
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target and (target:getKingdom() == "wei")
	end
}
sr_caocao:addSkill(sr_jianxiong)
sr_caocao:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_caocao"] = "SR曹操",
["&sr_caocao"] = "曹操",
["sr_zhaoxiang"] = "招降",
["srzhaoxiangdiscard"] = "你可以棄置一張牌，以便發動招降",
["srzhaoxianggetcard"] = "你被取走一張手牌，但你使用的【殺】仍然有效",
["srzhaoxiangslashnullified"] = "你防止被取走一張手牌，但你使用的【殺】失效",
[":sr_zhaoxiang"] = "當一名其他角色使用【殺】指定目標後，若該角色在你的攻擊範圍內，你令其選擇一項：你獲得其"..
"一張手牌，或此【殺】無效。若該角色不在你的攻擊範圍內，你可以棄置一張牌，然後令其作上述選擇",
["#zhaoxiang"] = "%from 對 %to 使用的 %arg 無效",
["sr_zhishi"] = "治世",
["#sr_zhishihide"] = "治世",
[":sr_zhishi"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名其他角色選擇一項：棄置一張" ..
"基本牌，然後回復一點體力；或受到你造成的一點傷害，然後回復1點體力",
["#srbasic"] = "你可棄置一張基本牌，或是受到 %src 造成的1點傷害。然後回復1點體力。",
["sr_jianxiong"] = "奸雄",
["@sr_jianxiong"] = "你可以棄置一張牌，並發動 %src 的技能“奸雄”",

[":sr_jianxiong"] = "<font color=\"orange\"><b>主公技，</b></font>每當一名其他魏勢力角色受到不為你造成的傷害"..
"後，該角色可以棄置一張手牌，然後令你獲得對其造成傷害的牌。",
["$sr_zhaoxiang"] = "汝可願降於我，為我所用？",
["$sr_zhishi1"] = " 需得百姓親附，甲兵強盛。",
["$sr_zhishi2"] = "用人唯才，治世依法！",
["$sr_jianxiong"] = "寧教我負天下人，休教天下人負我！",
["~sr_caocao"] = "孤之霸業，竟有終結之時。",
["losesr_zhaoxiang"] = "失去【招降】",
["losesr_zhishi"] = "失去【治世】",
}

--SR郭嘉
sr_guojia = sgs.General(extension,"sr_guojia","wei",3)

sr_tianshang = sgs.CreateTriggerSkill{
	name = "sr_tianshang", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local death = data:toDeath()		
		if death.who:objectName() == player:objectName() then
			local targets = room:getOtherPlayers(player)			
			if targets:length() > 0 then				
				local target = room:askForPlayerChosen(player, targets, self:objectName(),"sr_tianshang-invoke",true,true)
				if target then
					room:notifySkillInvoked(player, "sr_tianshang")
					room:broadcastSkillInvoke("sr_tianshang")
					room:doSuperLightbox("sr_guojia", "sr_tianshang")
					local skill_list = player:getVisibleSkillList()
					local skills = {}
					for _,skill in sgs.qlist(skill_list) do
						if skill:objectName() ~= "sr_tianshang" then
							table.insert(skills, skill:objectName())
						end
					end
					local choice = room:askForChoice(target, self:objectName(), table.concat(skills, "+"))					
					room:handleAcquireDetachSkills(target, choice, false)
					room:setPlayerProperty(target,"maxhp",sgs.QVariant(target:getMaxHp()+1))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = target
					msg.arg = 1
					room:sendLog(msg)
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(target,recover)					
				end
			end
		end
		return false
	end, 
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end
}
sr_guojia:addSkill(sr_tianshang)

--遗计
sr_yiji = sgs.CreateTriggerSkill{
	name = "sr_yiji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
		for i = 0, x - 1, 1 do
			if not player:isAlive() then return end
			if not room:askForSkillInvoke(player, self:objectName()) then return end
			room:broadcastSkillInvoke("sr_yiji")
			local _guojia = sgs.SPlayerList()
			_guojia:append(player)
			local yiji_cards = room:getNCards(2, false)
			local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), 
								self:objectName(), nil))
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			local origin_yiji = sgs.IntList()
			for _, id in sgs.qlist(yiji_cards) do
				origin_yiji:append(id)
			end
			while room:askForYiji(player, yiji_cards, self:objectName(), true, false, true, -1, 
				room:getAlivePlayers()) do
				local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand, 
					sgs.Player_PlaceTable,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, 
						player:objectName(), self:objectName(), nil))
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
				if not player:isAlive() then return end
			end
			if not yiji_cards:isEmpty() then
				local move = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand, 
					sgs.Player_PlaceTable,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), 
								self:objectName(), nil))
				local moves = sgs.CardsMoveList()
				moves:append(move)
				room:notifyMoveCards(true, moves, false, _guojia)
				room:notifyMoveCards(false, moves, false, _guojia)
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(yiji_cards) do
					dummy:addSubcard(id)
				end
				player:obtainCard(dummy, false)
			end
		end
		return false
	end
}
sr_guojia:addSkill(sr_yiji)

--慧觑
sr_huiquCard = sgs.CreateSkillCard{
	name = "sr_huiqu",
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
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@sr_huiqu-to".. card:objectName())
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
sr_huiquVS = sgs.CreateZeroCardViewAsSkill{
	name = "sr_huiqu",
	view_as = function()
		return sr_huiquCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@sr_huiqu"
	end,
}

sr_huiqu = sgs.CreateTriggerSkill{
	name = "sr_huiqu", 
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = sr_huiquVS,
	events = {sgs.EventPhaseStart, sgs.FinishJudge}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if not player:isKongcheng() then
					if room:askForCard(player, ".|.|.|hand", "@sr_huiqu-card", data, self:objectName()) then
						room:notifySkillInvoked(player, "sr_huiqu")
						room:broadcastSkillInvoke("sr_huiqu")
						local judge = sgs.JudgeStruct()
						judge.pattern = "."
						judge.good = true
						judge.reason = self:objectName()
						judge.who = player
						judge.time_consuming = true
						room:judge(judge)
					end
				end
			end
		elseif event == sgs.FinishJudge then 
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isRed() then
					room:askForUseCard(player, "@sr_huiqu", "@sr_huiqu", -1, sgs.Card_MethodNone)
				elseif card:isBlack() then
					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "sr_huiqudamage", "@sr_huiqu-damage", true)
					if s then
						room:doAnimate(1, player:objectName(), s:objectName())
						room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))
					end
				end
			end
		end
		return false
	end
}
sr_guojia:addSkill(sr_huiqu)
sr_guojia:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_guojia"] = "SR郭嘉",
["&sr_guojia"] = "郭嘉",
["sr_yiji"] = "遺計",
[":sr_yiji"] = "每當你受到1點傷害後，你可以觀看牌堆頂的兩張牌，然後將一張牌交給一名角色，將另一張牌交給一名角色。 ",
["$sr_yiji"] = "速戰速決吧",
["sr_tianshang"] = "天殤",
[":sr_tianshang"] = "你死亡時，可令一名其他角色獲得你當前的另一項技能,然後其增加一點體力上限並回復一點體力。",
["sr_tianshang-invoke"] = "你可以發動【天殤】",
["sr_huiqu"] = "慧覷",
["sr_huiqudamage"] = "慧覷",
["sr_huiqufirst"] = "慧覷",
[":sr_huiqu"] = "回合開始階段開始時，你可以棄置一張手牌並進行一次判定，若結果為紅色，你將場上的一張牌移動到另一個相"..
"應的位置；若結果為黑色，你對一名角色造成1點傷害，然後該角色摸一張牌。",
["$sr_tianshang"] = "唉，只能等待奇蹟。",
["$sr_huiqu"] = "且看你如何化解。",
["~sr_guojia"] = "豈能盡如人意。",
["losesr_tianshang"] = "失去【天殤】",
["losesr_huiqu"] = "失去【慧覷】",
["losesr_yiji"] = "失去【遺計】",
	["@sr_huiqu-card"] = "你可以棄置一張手牌發動技能“慧覷”",
	["@sr_huiqu-damage"] = "請選擇受到傷害的角色",
	["@sr_huiqu"] = "你可以移動場上的一張牌。",
	["@sr_huiqu-to"] = "請選擇移動【%arg】的目標角色",
	["~sr_huiqu"] = "選擇一張牌→選擇一名角色→點擊確定",
}

--SR許褚
sr_xuchu = sgs.General(extension,"sr_xuchu","wei",4)

--鏖战
sr_aozhandummycard = sgs.CreateSkillCard{
	name = "sr_aozhandummycard",
}
sr_aozhancard = sgs.CreateSkillCard{
	name = "sr_aozhancard", 
	target_fixed = true,
	will_throw = false, 
	on_use = function(self, room, source, targets)
		local cards = source:getPile("@srzhan")		
		local dummycard = sr_aozhandummycard:clone()
		for _,card_id in sgs.qlist(cards) do
			dummycard:addSubcard(card_id)
		end		
		local choice = room:askForChoice(source, "sr_aozhan", "sraozhanget+sraozhandraw")
		room:notifySkillInvoked(source, "sr_aozhan")
		if choice == "sraozhanget" then
			room:obtainCard(source, dummycard, true)
		elseif choice == "sraozhandraw" then 
			local count = dummycard:subcardsLength()
			room:throwCard(dummycard, nil,source)
			source:drawCards(count)
		end
	end
}
sr_aozhan = sgs.CreateViewAsSkill{
	name = "sr_aozhan", 
	n = 0, 
	view_as = function(self, cards)
		return sr_aozhancard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getPile("@srzhan"):length() > 0 then
			return not player:hasUsed("#sr_aozhancard")
		end
		return false
	end
}
sr_aozhanGet = sgs.CreateTriggerSkill{
	name = "#sr_aozhan", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage,sgs.Damaged}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") or card:isKindOf("Duel") then
				if room:askForSkillInvoke(player, "sr_aozhan", data) then
					room:notifySkillInvoked(player, "sr_aozhan")
					room:broadcastSkillInvoke("sr_aozhan")
					local x = damage.damage
					for i=1, x, 1 do
						local id = room:drawCard()
						player:addToPile("@srzhan", id, true)
					end
				end
			end
		end		
		return false
	end
}
sr_xuchu:addSkill(sr_aozhan)
sr_xuchu:addSkill(sr_aozhanGet)
extension:insertRelatedSkills("sr_aozhan","#sr_aozhan")

--虎啸
sr_huxiao = sgs.CreateTriggerSkill{
	name = "sr_huxiao",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local slash = damage.card
			local victim = damage.to
			if player:faceUp() then
				if victim and victim:isAlive() then
					if slash and slash:isKindOf("Slash") then
						if player:getPhase() == sgs.Player_Play then
							if room:askForSkillInvoke(player, self:objectName(), data) then
								room:notifySkillInvoked(player, "sr_huxiao")
								room:broadcastSkillInvoke("sr_huxiao")
								room:setPlayerMark(player, "usedsrhuxiao", 1)
								damage.damage = damage.damage + 1
								player:drawCards(1)	
								
								local msg = sgs.LogMessage()
								msg.type = "#Huxiao"
								msg.from = player
								msg.to:append(damage.to)
								msg.arg = tostring(damage.damage-1)
								msg.arg2 = tostring(damage.damage)
								room:sendLog(msg)						
								data:setValue(damage)					
							end
						end
					end
				end
			end
		end
	end
}

sr_huxiaodamage = sgs.CreateTriggerSkill{
	name = "sr_huxiaodamage",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardFinished}, 
	priority = -1,
	global = true,  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		if not use.from or use.from:objectName() ~= player:objectName() then return false end
		if player:isAlive() then
			if player:getMark("usedsrhuxiao") > 0 then
				room:setPlayerMark(player, "usedsrhuxiao", 0)
				player:turnOver()
				room:throwEvent(sgs.TurnBroken)	
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}

sr_xuchu:addSkill(sr_huxiao)

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sr_huxiaodamage") then skills:append(sr_huxiaodamage) end
sgs.Sanguosha:addSkills(skills)	
--[[
--虎啸造成伤害后死了……
sr_huxiaodamage = sgs.CreateTriggerSkill{
	name = "#sr_huxiaodamage",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardFinished},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		if not use.from or use.from:objectName() ~= player:objectName() then return false end
		if player:isAlive() then
			if player:getMark("usedsrhuxiao") > 0 then
				player:turnOver()
				player:setAlive(false)
				room:broadcastProperty(player, "alive")
			end
		end
	end,
	priority = -1
}	
sr_xuchu:addSkill(sr_huxiaodamage)	
--活过来了！
sr_huxiaoback = sgs.CreateTriggerSkill{
	name = "#sr_huxiaoback",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getPlayers()) do
				if p:getMark("usedsrhuxiao") > 0 and p:getHp() > 0 then
					room:setPlayerMark(p, "usedsrhuxiao", 0)
					p:setAlive(true)
					room:broadcastProperty(p, "alive")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 9
}
sr_xuchu:addSkill(sr_huxiaoback)
extension:insertRelatedSkills("sr_huxiao","#sr_huxiaodamage")
extension:insertRelatedSkills("sr_huxiao","#sr_huxiaoback")	
]]--
sr_xuchu:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_xuchu"] = "SR許褚",
["&sr_xuchu"] = "許褚",
["sr_aozhan"] = "鏖戰",
["@srzhan"] = "戰",
["sraozhanget"] = "將所有的“戰”收入手牌",
["sraozhandraw"] = "將所有的“戰”置入棄牌堆，然後摸等量的牌",
[":sr_aozhan"] = "每當你因【殺】或【決鬥】造成或受到1點傷害後，可將牌堆頂的一張牌置於你的武將牌上，稱為“戰”。 "..
"<font color=\"green\"><b>出牌階段限一次，</b></font>你可以選擇一項：將所有的“戰”收入手牌，或將所有的“戰”置入棄牌"..
"堆，然後摸等量的牌。",
["sr_huxiao"] = "虎嘯",
[":sr_huxiao"] = "出牌階段，當你使用【殺】造成傷害時，若你的武將牌正面朝上，你可以摸一張牌，然後令此傷害+1，若如此"..
"做，則此【殺】結算後，將你的武將牌翻面，並結束當前回合。",
["#Huxiao"] = "%from 發動了技能“<font color=\"yellow\"><b>虎嘯</b></font>”，對%to 造成傷害由%arg 點增加到"..
"%arg2 點",
["$sr_aozhan1"] = "哈哈哈哈哈哈哈 來送死的吧！",
["$sr_aozhan2"] = "這一招如何！",
["$sr_huxiao"] = "拿命來！",
["~sr_xuchu"] = "我還能...接著打。",
["losesr_aozhan"] = "失去【鏖戰】",
["losesr_huxiao"] = "失去【虎嘯】",
}

--SR司馬懿
sr_simayi = sgs.General(extension,"sr_simayi","wei",3)

--鬼才
sr_guicai = sgs.CreateTriggerSkill{
	name = "sr_guicai", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.AskForRetrial}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, "sr_guicai")
			local judge = data:toJudge()
			local choice
			if player:isKongcheng() then
				choice = "srguicailiangchu"
			else
				choice = room:askForChoice(player, self:objectName(), "srguicailiangchu+srguicaidachu",data)
			end
			if choice == "srguicailiangchu" then
				local card_id = room:drawCard()
				room:getThread():delay()
				local card = sgs.Sanguosha:getCard(card_id)
				room:broadcastSkillInvoke("sr_guicai")
				room:retrial(card, player, judge, self:objectName())
			elseif choice == "srguicaidachu" then	   			
	   			local prompt = "@guicai-card:"..judge.who:objectName()..":"..self:objectName()..
	   			":"..judge.reason..":"..judge.card:getEffectiveId()
				local card = room:askForCard(player,  "." , prompt, data, sgs.Card_MethodResponse, judge.who, true)
				room:broadcastSkillInvoke("sr_guicai")
				room:retrial(card, player, judge, self:objectName())
			end
			return false
		end
	end,
}
sr_simayi:addSkill(sr_guicai)

--狼顾
sr_langgu = sgs.CreateTriggerSkill{
	name = "sr_langgu",
	frequency = sgs.Skill_NotFrequent,
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
			if not dest:isNude() then				
				if room:askForSkillInvoke(source, self:objectName(), data) then
					room:notifySkillInvoked(source, "sr_langgu")
					room:broadcastSkillInvoke("sr_langgu")
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = source
					room:judge(judge)
					if judge:isGood() then
						local card_id = room:askForCardChosen(source, dest, "he", self:objectName())
						room:obtainCard(source, card_id, false)
					end
				end				
			end
		end
		return false
	end
}
sr_simayi:addSkill(sr_langgu)

--追尊
sr_zhuizun = sgs.CreateTriggerSkill{
	name = "sr_zhuizun",
	limit_mark = "@srzhuizun",
	frequency = sgs.Skill_Limited, 
	events = {sgs.Dying,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local simayi = room:findPlayerBySkillName(self:objectName())
		if not simayi or simayi:isDead() or not simayi:hasSkill(self:objectName()) then return false end
		if event == sgs.Dying then
			local dying_data = data:toDying()
			local source = dying_data.who
			if simayi:objectName() ~= player:objectName() then return false end
			if player:getMark("@srzhuizun") == 0 then return false end
			if source:objectName() == player:objectName() then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:removePlayerMark(player, "@srzhuizun")
					room:notifySkillInvoked(player, "sr_zhuizun")
					room:broadcastSkillInvoke("sr_zhuizun")
					room:doSuperLightbox("sr_simayi","sr_zhuizun")
					room:setPlayerProperty(player, "hp", sgs.QVariant(1))
					local targets = room:getOtherPlayers(player)
					local prompt = string.format("srzhuizungive:%s", player:objectName())
					for _,p in sgs.qlist(targets) do
						if not p:isKongcheng() then
							local card = room:askForExchange(p, self:objectName(), 1, 1, false, prompt)
							room:obtainCard(player, card, false)
							room:getThread():delay()
						end
					end						
					room:setPlayerMark(player, "srzhuizunudo", 1)
				end
			end			
		else
			local room = player:getRoom()			
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("srzhuizunudo") > 0 then
					room:setPlayerMark(p, "srzhuizunudo", 0)
					room:notifySkillInvoked(p, "sr_zhuizun")
					room:broadcastSkillInvoke("sr_zhuizun")
					room:setTag("ExtraTurn",sgs.QVariant(true))
					p:gainAnExtraTurn()
					room:setTag("ExtraTurn",sgs.QVariant(false))
					break
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end	
}

-- sr_zhuizunStart = sgs.CreateTriggerSkill{
-- 	name = "#sr_zhuizun",
-- 	frequency = sgs.Skill_Compulsory,
-- 	events = {sgs.GameStart},
-- 	on_trigger = function(self, event, player, data)
-- 		player:gainMark("@zhuizun")
-- 	end
-- }
sr_simayi:addSkill(sr_zhuizun)
-- sr_simayi:addSkill(sr_zhuizunStart)
-- extension:insertRelatedSkills("sr_zhuizun","#sr_zhuizun")
sr_simayi:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_simayi"] = "SR司馬懿",
["&sr_simayi"] = "司馬懿",
["sr_guicai"] = "鬼才",
["srguicailiangchu"] = "亮出牌堆頂的一張牌代替之",
["srguicaidachu"] = "打出一張手牌代替之",
["srguicaidiscard"] = "請選擇一張手牌用作改判",
[":sr_guicai"] = "在一名角色的判定牌生效前，你可以選擇一項：亮出牌堆頂的一張牌代替之，或打出一張手牌代替之。",
["sr_langgu"] = "狼顧",
[":sr_langgu"] = "每當你造成或受到一次傷害後，你可以進行一次判定，若結果為黑色，你獲得對方的一張牌。",
["@zhuizun"] = "追尊",
["sr_zhuizun"] = "追尊",
["srzhuizungive"] = "請交給該角色(%src)一張手牌",
[":sr_zhuizun"] = "<font color=\"red\"><b>限定技，</b></font>當你進入瀕死狀態時，你可以回復體力至1點，令所有其他角"..
"色依次交給你一張手牌，然後當前回合結束後，你進行一個額外的回合。",
["$sr_guicai"] = "哼，我已等待多時。",
["$sr_langgu"] = "不自量力。",
["$sr_zhuizun"] = "我才是勝者 哈哈哈哈哈哈哈！",
["~sr_simayi"] = "難道全被識破了嗎！",
["losesr_guicai"] = "失去【鬼才】",
["losesr_langgu"] = "失去【狼顧】",
["losesr_zhuizun"] = "失去【追尊】",
}

--SR甄姬
sr_zhenji = sgs.General(extension,"sr_zhenji","wei",3,false)

--流云
sr_liuyuncard = sgs.CreateSkillCard{
	name = "sr_liuyuncard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_liuyun")
		room:broadcastProperty(source, "chained")
		room:setPlayerProperty(source, "chained", sgs.QVariant(true))
		local target = targets[1]
		local gotodo = 0 
		if not target:isWounded() then
			gotodo = 2
		else
			local choice = room:askForChoice(target, "sr_liuyun", "srliuyunrecover+srliuyundrawcard")
			if choice == "srliuyunrecover" then
				gotodo = 1
			elseif choice == "srliuyundrawcard" then
				gotodo = 2
			end
		end
		if gotodo > 0 then
			if gotodo == 1 then
				local recover = sgs.RecoverStruct()
				recover.who = source
				room:recover(target, recover)
			elseif gotodo == 2 then
				target:drawCards(2)
			end
		end
	end
}
sr_liuyun = sgs.CreateViewAsSkill{
	name = "sr_liuyun", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = sr_liuyuncard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:isChained() then
			return not player:hasUsed("#sr_liuyuncard")
		end
		return false
	end
}
sr_zhenji:addSkill(sr_liuyun)

--凌波
sr_lingbo = sgs.CreateTriggerSkill{
	name = "sr_lingbo",  
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local srzhenji = room:findPlayerBySkillName(self:objectName())
			if srzhenji then
				if srzhenji:isChained() then
					local players = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:getCards("ej"):length()>0 then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						if room:askForSkillInvoke(srzhenji, self:objectName(), data) then
							room:notifySkillInvoked(srzhenji, "sr_lingbo")
							room:broadcastSkillInvoke("sr_lingbo")
							local target = room:askForPlayerChosen(srzhenji, players, self:objectName())
							local card_id = room:askForCardChosen(srzhenji, target, "ej", "sr_lingbo")
							room:removeTag("lingbocard")
							room:removeTag("lingboperson")
							local card = sgs.Sanguosha:getCard(card_id)
							room:setPlayerProperty(srzhenji, "chained", sgs.QVariant(false))
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
								srzhenji:objectName(), "sr_lingbo", nil)
							room:moveCardTo(card, target, nil, sgs.Player_DrawPile, reason)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
sr_zhenji:addSkill(sr_lingbo)

--倾城
--[[
sr_qingchengcard = sgs.CreateSkillCard{
	name = "sr_qingchengcard",
	target_fixed = false,
	will_throw = false,
	player = nil,
	on_use = function(self, room, source)
		player = source	
	end,
	filter = function(self,targets,to_select,player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = nil
		if player:isChained() then
			card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		else
			card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		end			
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and 
			not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end				
		local pattern = ""
		if not sgs.Self:isChained() then
			pattern = "slash" 
		else
			pattern = "jink"
		end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,
	
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local pattern = ""
		if not sgs.Self:isChained() then
			pattern = "slash" 
		else
			pattern = "jink"
		end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("sr_qingcheng")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	
	on_validate = function(self, card_use)
		local zhenji = card_use.from
		local room = zhenji:getRoom()		
				
		room:broadcastSkillInvoke("sr_qingcheng")	
		
		if not zhenji:isChained()  then			
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(true))
			local use_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()			
			local tos = card_use.to
			for _, to in sgs.qlist(tos) do
				local skill = room:isProhibited(card_use.from, to, use_card)
				if skill then
					local log = sgs.LogMessage()
					log.type = "#SkillAvoid"
					log.from = to
					log.arg = skill:objectName()
					log.arg2 = use_card:objectName()
					room:sendLog(log)					
					room:broadcastSkillInvoke(skill:objectName())
					card_use.to:removeOne(to)
				end
			end
			return use_card					
		else
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(false))
			local use_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()			
			local tos = card_use.to
			for _, to in sgs.qlist(tos) do
				local skill = room:isProhibited(card_use.from, to, use_card)
				if skill then
					local log = sgs.LogMessage()
					log.type = "#SkillAvoid"
					log.from = to
					log.arg = skill:objectName()
					log.arg2 = use_card:objectName()
					room:sendLog(log)					
					room:broadcastSkillInvoke(skill:objectName())
					card_use.to:removeOne(to)
				end
			end
			return use_card					
		end		
	end,
	on_validate_in_response = function(self, zhenji)
		local room = zhenji:getRoom()
		room:broadcastSkillInvoke("sr_qingcheng")			
		
		if not zhenji:isChained()  then
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(true))
			local use_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()
			return use_card						
		else
			room:setPlayerProperty(zhenji, "chained", sgs.QVariant(false))
			local use_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			use_card:setSkillName("sr_qingcheng")			
			use_card:deleteLater()
			return use_card				
		end		
	end,	
}

sr_qingcheng = sgs.CreateViewAsSkill{
	name = "sr_qingcheng",
	n = 0,
	view_as = function(self, cards)
		return sr_qingchengcard:clone()
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) then
			return not player:isChained()
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
			return not player:isChained()
		elseif pattern == "jink" then
			return player:isChained()
		end
		return false
	end
}
]]--

sr_qingchengVS = sgs.CreateZeroCardViewAsSkill{
	name = "sr_qingcheng",
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
		return sgs.Slash_IsAvailable(player) and not player:isChained()
	end,
	enabled_at_response = function(self, player, pattern)
		return ((pattern == "slash" and not player:isChained()) or (pattern == "jink" and player:isChained() ))
	end
}
sr_qingcheng = sgs.CreateTriggerSkill{
	name = "sr_qingcheng",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = sr_qingchengVS, 
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
			elseif card:isKindOf("Jink") then
				room:setPlayerProperty(player, "chained", sgs.QVariant(false))
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) 
	end
}

sr_zhenji:addSkill(sr_qingcheng)
sr_zhenji:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_zhenji"] = "SR甄姬",
["&sr_zhenji"] = "甄姬",
["sr_liuyun"] = "流雲",
["srliuyunrecover"] = "回復1點體力",
["srliuyundrawcard"] = "摸兩張牌",
[":sr_liuyun"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以橫置你的武將牌並棄置一張黑"..
"色牌，然後令一名角色選擇一項：回復1點體力，或摸兩張牌。",
["sr_lingbo"] = "凌波",
[":sr_lingbo"] = "一名角色的回合開始階段結束時，你可以重置你的武將牌，然後將場上的一張牌置於牌堆頂。",
["sr_qingcheng"] = "傾城",
[":sr_qingcheng"] = "你可以橫置你的武將牌，視為你使用或打出一張【殺】；你可以重置你的武將牌，視為你使用"..
"或打出一張【閃】",
["$sr_liuyun"] = "彷彿兮若輕雲之蔽月。",
["$sr_lingbo"] = "飄搖兮若流風之回雪。",
["$sr_qingcheng"] = "寒辭未吐，氣若幽蘭。",
["~sr_zhenji"] = "悼良會之永絕兮…哀已逝而異鄉……",
["losesr_liuyun"] = "失去【流雲】",
["losesr_lingbo"] = "失去【凌波】",
["losesr_qingcheng"] = "失去【傾城】",
}

--SR夏侯惇
sr_xiahoudun = sgs.General(extension,"sr_xiahoudun","wei")

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local patterns = {"slash", "jink", "peach", "analeptic"}
if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(patterns, 2, "thunder_slash")
	table.insert(patterns, 2, "fire_slash")
	table.insert(patterns, 2, "normal_slash")
end

local slash_patterns = {"slash", "normal_slash", "thunder_slash", "fire_slash"}

sr_xiahoucard = sgs.CreateSkillCard{
	name = "sr_xiahoucard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local xiahou
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill("sr_zhonghou") then
				xiahou = p
				break
			end
		end
		if not xiahou or xiahou:isDead() then return end		
		if not (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or 
			sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local choices={}			
			if source:isWounded() then
				table.insert(choices,"peach")
			end
			if sgs.Slash_IsAvailable(source) then
				for _,c in ipairs(patterns) do
					if string.find(c,"slash") then
						table.insert(choices,c)
					end
				end
			end
			local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
			Analeptic:deleteLater()
			if Analeptic:isAvailable(source) then
				table.insert(choices,"analeptic")
			end
			if #choices == 0 then return end
			local choice = room:askForChoice(source,"sr_xiahou",table.concat(choices,"+"))			
			if string.find(choice,"slash") then
				local victims  = sgs.SPlayerList()
				local slash = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				slash:deleteLater()
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if source:canSlash(p,slash,true) then
						victims:append(p)
					end
				end
				if victims:isEmpty() then return end
				local player = room:askForPlayerChosen(source,victims,"sr_xiahou","@sr_xiahou:"..choice,false,true)
				if player then
					local msg = sgs.LogMessage()
					msg.type = "#Guhuo"
					msg.from = source
					msg.to:append(player)
					msg.arg = choice
					msg.arg2 = "sr_xiahou"	
					room:sendLog(msg)				
					local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
					room:setPlayerFlag(source,"xiahouused")
					if c == "srcancel" then return end
					room:loseHp(xiahou)
					local slash = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
					slash:deleteLater()
					room:useCard(sgs.CardUseStruct(slash,source,player))
					return
				end
			elseif choice == "peach" then
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = choice
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou)
				local peach = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				peach:deleteLater()
				room:useCard(sgs.CardUseStruct(peach,source,source))
				return
			elseif choice == "analeptic" then
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = choice
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou)
				local analeptic = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				analeptic:deleteLater()
				room:useCard(sgs.CardUseStruct(analeptic,source,source))
				return
			end
		else									
			local pattern = room:getCurrentCardUsePattern()
			if  pattern == "slash" then
				local choices={}
				for _,c in ipairs(patterns) do
					if string.find(c,"slash") then
						table.insert(choices,c)
					end
				end
				local choice = room:askForChoice(source,"sr_xiahouresponse",table.concat(choices,"+"))
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = choice
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou)
				local slash = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
				slash:deleteLater()
				room:provide(slash)
				return
			elseif pattern == "jink" then
				local msg = sgs.LogMessage()
				msg.type = "#GuhuoNoTarget"
				msg.from = source				
				msg.arg = pattern
				msg.arg2 = "sr_xiahou"	
				room:sendLog(msg)	
				local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
				room:setPlayerFlag(source,"xiahouused")
				if c == "srcancel" then return end
				room:loseHp(xiahou)
				local jink = sgs.Sanguosha:cloneCard(pattern,sgs.Card_NoSuit,0)
				jink:deleteLater()
				room:provide(jink)
				return
			else
				local choices={}				
				if not player:hasFlag("Global_PreventPeach") then
					table.insert(choices,"peach")
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						if room:getCurrentDyingPlayer():objectName() == room:getCurrent():objectName() then
							table.insert(choices,"analeptic")
						end
					end
					local choice = room:askForChoice(source,"sr_xiahousave",table.concat(choices,"+"))
					local msg = sgs.LogMessage()
					msg.type = "#GuhuoNoTarget"
					msg.from = source				
					msg.arg = choice
					msg.arg2 = "sr_xiahou"	
					room:sendLog(msg)	
					local c = room:askForChoice(xiahou,"sr_xiahouhelp","srlosehp+srcancel")
					room:setPlayerFlag(source,"xiahouused")
					if c == "srcancel" then return end
					room:loseHp(xiahou)
					local peach = sgs.Sanguosha:cloneCard(choice,sgs.Card_NoSuit,0)
					peach:deleteLater()
					room:useCard(sgs.CardUseStruct(peach,source,room:getCurrentDyingPlayer()))
					return
				end
			end
		end
		return
	end
}

sr_xiahou = sgs.CreateViewAsSkill{
	name = "sr_xiahou",
	n = 0,
	view_as = function(self,cards)
		return sr_xiahoucard:clone()
	end,
	enabled_at_play = function(self,player)
		if player:getPhase() ~= sgs.Player_Play then return false end
		local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
		Analeptic:deleteLater()
		if (not sgs.Slash_IsAvailable(player)) and (not Analeptic:isAvailable(player)) and 
			(not player:isWounded()) then return false end
		if player:hasUsed("#sr_xiahoucard") then return false end
		if player:hasFlag("xiahouused") then return false end
		return true
	end,
	enabled_at_response = function(self,player,pattern)
		if player:getPhase() ~= sgs.Player_Play then return false end
		if player:hasFlag("xiahouused") then return false end
		if string.find(pattern,"peach") then
			return not player:hasFlag("Global_PreventPeach")
		end
		return pattern == "slash" or pattern == "jink"
	end,
}
sr_zhonghou = sgs.CreateTriggerSkill{
	name = "sr_zhonghou",
	events = {sgs.EventPhaseChanging,sgs.CardUsed,sgs.TargetConfirming,sgs.CardFinished,sgs.Death,
	sgs.EventLoseSkill,sgs.CardAsked},	
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local xiahou = room:findPlayerBySkillName(self:objectName())
		if not xiahou or xiahou:isDead() then 
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(p,"-sr_xiahou")
				end
			end
			return false 
		end	
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then				
				if player:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(player,"-sr_xiahou")
				end
				if player:hasFlag("xiahouused") then
					room:setPlayerFlag(player, "-xiahouused")
				end				
			elseif change.to == sgs.Player_Play then
				if xiahou:inMyAttackRange(player) then
					if not player:hasSkill("sr_xiahou") then
						room:handleAcquireDetachSkills(player,"sr_xiahou")
					end
				end
			end
		elseif event == sgs.TargetConfirming or event == sgs.CardUsed or event == sgs.CardFinished then			
			if player:getPhase() ~= sgs.Player_Play then return false end
			if xiahou:inMyAttackRange(player) then
				if not player:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(player,"sr_xiahou")
				end
			else
				if player:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(player,"-sr_xiahou")
				end
			end	
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= xiahou:objectName() then return false end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill("sr_xiahou") then
					room:handleAcquireDetachSkills(p,"-sr_xiahou")
				end
			end
		else
			if data:toString() == "sr_zhonghou" then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("sr_xiahou") then
						room:handleAcquireDetachSkills(p,"-sr_xiahou")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target 
	end
}

sr_xiahoudun:addSkill(sr_zhonghou)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("sr_xiahou") then skills:append(sr_xiahou) end
sgs.Sanguosha:addSkills(skills)

--刚烈
sr_ganglie = sgs.CreateTriggerSkill{
	name = "sr_ganglie",
	events = {sgs.EventPhaseStart,sgs.DamageCaused,sgs.Damage},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player,self:objectName(),data) then
					room:broadcastSkillInvoke("sr_ganglie")
					room:loseHp(player)
					if player:isAlive() then
						room:setPlayerFlag(player,"srganglieinvoked")
					end
				end
			elseif player:getPhase() == sgs.Player_Finish then
				if player:getMark("sr_ganglie") > 0 then
					room:notifySkillInvoked(player,"sr_ganglie")
					room:broadcastSkillInvoke("sr_ganglie")
					player:drawCards(player:getMark("sr_ganglie"))
					room:setPlayerMark(player,"sr_ganglie",0)
				end
			elseif player:getPhase() == sgs.Player_NotActive then
				if player:hasFlag("srganglieinvoked") then
					room:setPlayerFlag(player,"-srganglieinvoked")
				end
				if player:hasFlag("damageincreased") then
					room:setPlayerFlag(player,"-damageincreased")
				end
			end
		else 
			local damage = data:toDamage()
			if not damage.from or damage.from:isDead() or damage.from:objectName() ~= player:objectName() or
				not player:hasFlag("srganglieinvoked") or player:getPhase() == sgs.Player_NotActive then
				return false
			end
			if event == sgs.DamageCaused then
				if not player:hasFlag("damageincreased") and player:hasFlag("srganglieinvoked") then
					room:notifySkillInvoked(player,"sr_ganglie")
					room:setPlayerFlag(player,"damageincreased")
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#Srganglie"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)
					data:setValue(damage)
				end
			elseif event == sgs.Damage then
				if player:hasFlag("srganglieinvoked") then
					room:setPlayerMark(player,"sr_ganglie",player:getMark("sr_ganglie") + damage.damage)
				end
			end
		end
		return false
	end
}

sr_xiahoudun:addSkill(sr_ganglie)
sr_xiahoudun:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_xiahoudun"] = "SR夏侯惇",
["&sr_xiahoudun"] = "夏侯惇",
["sr_zhonghou"] = "忠侯",
[":sr_zhonghou"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>每當你攻擊範圍內的一名"..
"角色於其出牌階段需要使用或打出一張基本牌時，該角色可以聲明之，然後你可以失去1點體力，視為該角色使用或打出此牌",
["sr_xiahou"] = "夏侯",
["sr_xiahousave"] = "夏侯",
["sr_xiahouresponse"] = "夏侯",
["sr_xiahouhelp"] = "夏侯",
["@sr_xiahou"] = "請選擇【%src】的目標",
[":sr_xiahou"] = "當你於出牌階段需要使用或打出一張基本牌時，你可以對<font color=\"red\"><b>SR夏侯惇</b></font> "..
"發動【忠侯】",
--["@@sr_xiahou"] = "請選擇用來發動“忠侯”的目標角色",
--["~sr_xiahou"] = "選擇目標角色（可略過）→點確定",
["sr_zhonghou"] = "忠侯",
["sr_zhonghouhelp"] = "忠侯",
["srlosehp"] = "失去體力",
["srcancel"] = "取消",
--["sr_zhonghou_select"] = "忠侯",
["sr_ganglie"] = "剛烈",
[":sr_ganglie"] = "出牌階段開始時，你可以失去1點體力，若如此做，你本回合下一次造成的傷害+1。且本回合你每造成1點"..
"傷害，回合結束時你便摸一張牌",
["$sr_ganglie"] = "你能逃得掉嗎",
["@sr_ganglie"] = "剛",
["~sr_xiahoudun"] = "這仇，早晚要報",
["losesr_zhonghou"] = "失去【忠侯】",
["losesr_ganglie"] = "失去【剛烈】",
["#Srganglie"] = "%from 的技能 “<font color=\"yellow\"><b>剛烈</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--SR張遼
sr_zhangliao = sgs.General(extension,"sr_zhangliao","wei")

--无畏
-- sr_wuweicard = sgs.CreateSkillCard{
-- 	name = "sr_wuweicard",
-- 	target_fixed = true,
-- 	will_throw = true,
-- 	on_use = function(self,room,source,targets)
-- 		local ids = room:getNCards(3)
-- 		room:fillAG(ids)
-- 		room:getThread():delay()
-- 		room:clearAG()
-- 		--local basic = 0
-- 		local slashs = sgs.IntList()
-- 		local last = sgs.IntList()
-- 		for _,id in sgs.qlist(ids) do
-- 			local card = sgs.Sanguosha:getCard(id)
-- 			if card:isKindOf("BasicCard") then
-- 				slashs:append(id)				
-- 			else
-- 				last:append(id)
-- 			end
-- 		end		
-- 		if not slashs:isEmpty() then
-- 			for i = 1,slashs:length(),1 do
-- 				local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
-- 				slash:setSkillName("sr_wuwei")
-- 				slash:deleteLater()
-- 				local victims = sgs.SPlayerList()
-- 				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
-- 					if source:canSlash(p,slash,false) then
-- 						victims:append(p)
-- 					end
-- 				end
-- 				if victims:isEmpty() then break end
-- 				local target = room:askForPlayerChosen(source,victims,"sr_wuwei","#sr_wuwei",false,true)
-- 				if target then
-- 					room:useCard(sgs.CardUseStruct(slash,source,target),false)
-- 				else
-- 					break
-- 				end
-- 			end
-- 			for _,id in sgs.qlist(slashs) do
-- 				local card = sgs.Sanguosha:getCard(id) 
-- 				room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
	--sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
-- 					source:objectName(), "", "sr_wuwei"), true)
-- 			end
-- 		end		
-- 		if not last:isEmpty() then			
-- 			local n = 0
-- 			while n < 2 and not last:isEmpty() do
-- 				room:fillAG(last)
-- 				local id = room:askForAG(source,last,true,"sr_wuwei")
-- 				if id ~= -1 then
-- 					local card = sgs.Sanguosha:getCard(id)
-- 					source:obtainCard(card)
-- 					last:removeOne(id)
-- 					room:clearAG()
-- 					n = n + 1
-- 				else
-- 					room:clearAG()
-- 					break
-- 				end				
-- 			end
-- 			if not last:isEmpty() then
-- 				for _,id in sgs.qlist(last) do
-- 					local card = sgs.Sanguosha:getCard(id) 
-- 					room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
-- 					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,source:objectName(), "", "sr_wuwei"), true)
-- 				end
-- 			end
-- 		end
-- 	end
-- }

-- sr_wuwei = sgs.CreateViewAsSkill{
-- 	name = "sr_wuwei",
-- 	n = 2,
-- 	view_filter = function(self,selected,to_select)
-- 		return #selected < 2
-- 	end,
-- 	view_as = function(self,cards)
-- 		if #cards ~= 2 then return nil end
-- 		local scard = sr_wuweicard:clone()
-- 		scard:setSkillName("sr_ganglie")
-- 		for _,c in ipairs(cards) do
-- 			scard:addSubcard(c)
-- 		end
-- 		return scard
-- 	end,
-- 	enabled_at_play = function(self,player)
-- 		local caninvoke = false
-- 		local players = player:getSiblings()		
-- 		for _, p in sgs.qlist(players) do
-- 			if p:getHp() > player:getHp() then
-- 				caninvoke = true
-- 				break
-- 			end
-- 		end
-- 		if not caninvoke then return false end
-- 		return not player:hasUsed("#sr_wuweicard")
-- 	end
-- }
sr_wuweiCard = sgs.CreateSkillCard{
	name = "sr_wuwei",
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
sr_wuweiVS = sgs.CreateZeroCardViewAsSkill{
	name = "sr_wuwei",
	view_as = function()
		return sr_wuweiCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sr_wuwei"
	end
}

sr_wuwei = sgs.CreateTriggerSkill{
	name = "sr_wuwei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = sr_wuweiVS,
	on_trigger = function(self,event,player,data,room)
		if player:getPhase() ~= sgs.Player_Draw then return false end
		if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
		local ids = room:getNCards(3)
		room:fillAG(ids)
		room:getThread():delay()
		room:clearAG()
		--local basic = 0
		local slashs = sgs.IntList()
		local last = sgs.IntList()
		for _,id in sgs.qlist(ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("BasicCard") then
				slashs:append(id)				
			else
				last:append(id)
			end
		end		
		if not slashs:isEmpty() then
			for i = 1,slashs:length(),1 do
				if sgs.Slash_IsAvailable(player) then
					player:getRoom():askForUseCard(player, "@@sr_wuwei", "@sr_wuwei")
				end
			end
			for _,id in sgs.qlist(slashs) do
				local card = sgs.Sanguosha:getCard(id) 
				room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
					player:objectName(), "", "sr_wuwei"), true)
			end
		end				
		if not last:isEmpty() then
			local dummycard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			dummycard:deleteLater()			
			for _,id in sgs.qlist(last) do
				local card = sgs.Sanguosha:getCard(id)
 				dummycard:addSubcard(card)
 			end
 			if player:isAlive() then
 				player:obtainCard(dummycard)
 			end			
		end
		return true
	end
}

sr_wuweiTargetMod = sgs.CreateTargetModSkill{
	name = "#sr_wuweiTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "sr_wuwei" then
			return 1000
		end
	end,
}

sr_zhangliao:addSkill(sr_wuwei)
sr_zhangliao:addSkill(sr_wuweiTargetMod)
extension:insertRelatedSkills("sr_wuwei", "#sr_wuweiTargetMod")

--掩杀
sr_yansha = sgs.CreateTriggerSkill{
	name = "sr_yansha",
	events = {sgs.DrawNCards,sgs.EventPhaseStart,sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DrawNCards and RIGHT(self, player) then
			if room:askForSkillInvoke(player,self:objectName(),data) then
				room:broadcastSkillInvoke("sr_yansha",1)
				room:addPlayerMark(player,"sr_yansha-Clear")
				local n = data:toInt()
				data:setValue(n-1)
			end
		elseif event == sgs.EventPhaseStart and RIGHT(self, player) then
			if player:getPhase() == sgs.Player_Finish and player:getMark("sr_yansha-Clear") > 0 and not player:isKongcheng() then
				local card = room:askForCard(player,".","#sr_yansha",data,sgs.Card_MethodNone)
				if card then
					room:notifySkillInvoked(player,"sr_yansha")
					room:broadcastSkillInvoke("sr_yansha",1)
					player:addToPile("@yan",card,true)
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()		
			if use.from and use.card and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if not p:getPile("@yan"):isEmpty() and use.from:objectName() ~= p:objectName() then
						if p:askForSkillInvoke("sr_yansharob",data) then
							local id
							if p:getPile("@yan"):length() == 1 then
								id = p:getPile("@yan"):first()
							else
								room:fillAG(p:getPile("@yan"), p)
								id = room:askForAG(p, p:getPile("@yan"), true, "sr_yansha")
								room:clearAG(p)
								if id == -1 then
									return false
								end
							end
							local card = sgs.Sanguosha:getCard(id)
							room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
									sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,p:objectName(), "", "sr_yansha"), true)
							for i = 1,2,1 do
								if not use.from:isNude() then
									local cardid = room:askForCardChosen(p,use.from,"he","sr_yansha")
									local card = sgs.Sanguosha:getCard(cardid)
									p:obtainCard(card)
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}

sr_zhangliao:addSkill(sr_yansha)
sr_zhangliao:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_zhangliao"] = "SR張遼",
["&sr_zhangliao"] = "張遼",
["sr_wuwei"] = "無畏",
-- [":sr_wuwei"] ="<font color=\"green\"><b>出牌階段限一次，</b></font>若你的體力值不是全場最多的(或之一)"..
--"，你可以棄置兩張牌，若如此做，你展示牌堆頂的三張牌，其中每有一張基本牌，你便可以視為對一名其他角色使用"..
--"一張【殺】(以此法使用的【殺】不計入出牌階段的使用限制)，然後你將這些基本牌置入棄牌堆，並獲得其餘的一至兩張牌",
[":sr_wuwei"] ="摸牌階段，你可以放棄摸牌，改為展示牌堆頂的三張牌，其中每有一張基本牌，你便可以視為對一名其"..
"他角色使用一張【殺】，然後你將這些基本牌置入棄牌堆，並獲得其餘的牌",
["#sr_wuwei"] = "選擇一名【殺】的目標",
["@sr_wuwei"] = "你可以視為對一名其他角色使用一張【殺",
["~sr_wuwei"] = "選擇【殺】的目標角色→點擊確定",
["sr_yansha"] = "掩殺",
["sr_yansharob"] = "掩殺",
[":sr_yansha"] = "摸牌階段，你可以少摸一張牌，若如此做，則此回合結束階段開始時，你可以將一張手牌置於你的武"..
"將牌上，稱為“掩”。當一名其他角色使用【殺】選擇目標後，你可以將一張“掩”置入棄牌堆，然後獲得其兩張牌",
["#sr_yansha"] = "你可以將一張手牌置於武將牌上",
["@yan"] = "掩",
["losesr_wuwei"] = "失去【無畏】",
["losesr_yansha"] = "失去【掩殺】",
["$sr_yansha1"] = "兵貴神速，隨我來",
["$sr_yansha2"] = "行包圍之勢，盡數誅之",
["$sr_wuwei"] = "記住我軍的強大吧",
["~sr_zhangliao"] = "我張文遠，竟受此污名",
}

--SR貂蟬
sr_diaochan = sgs.General(extension,"sr_diaochan","qun",3,false)

--离间
sr_lijiancard = sgs.CreateSkillCard{
	name = "sr_lijiancard" ,
	filter = function(self, targets, to_select, Self)
		if not to_select:isMale() then
			return false
		end
		
		local duel = sgs.Sanguosha:cloneCard("Duel", sgs.Card_NoSuit, 0) --克隆一张决斗
		if (#targets == 0) and Self:isProhibited(to_select, duel) then --如果决斗目标不能被决斗，则返回false
			return false
		end
		if (#targets == 1) and to_select:isCardLimited(duel, sgs.Card_MethodUse) then 
			return false
		end
		
		return (#targets < 2) and (to_select:objectName() ~= Self:objectName())
	end ,
	feasible = function(self, targets, Self)
		return #targets == 2 --离间牌可以使用的前提只有目标数为2
	end ,
	about_to_use = function(self, room, cardUse) 
		local diaochan = cardUse.from
		
		local l = sgs.LogMessage()
		l.from = diaochan
		for _, p in sgs.qlist(cardUse.to) do
			l.to:append(p)
		end
		l.type = "#UseCard"
		l.card_str = self:toString()
		room:sendLog(l)
		
		local data = sgs.QVariant()
		data:setValue(cardUse)
		local thread = room:getThread()
		
		thread:trigger(sgs.PreCardUsed, room, diaochan, data)
		room:broadcastSkillInvoke("sr_lijian")
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, 
			diaochan:objectName(), "", "sr_lijian", "")
		room:moveCardTo(self, diaochan, nil, sgs.Player_DiscardPile, reason, true)
		
		thread:trigger(sgs.CardUsed, room, diaochan, data)
		thread:trigger(sgs.CardFinished, room, diaochan, data)
	end ,
	on_use = function(self, room, player, targets)
		
		local to = targets[1] --决斗目标
		local from = targets[2] --决斗使用者
		
		local duel = sgs.Sanguosha:cloneCard("Duel", sgs.Card_NoSuit, 0) --真实克隆的决斗，这个才是真正要使用的
		duel:setSkillName("_" .. self:getSkillName()) --设置技能名
		
		if (not from:isCardLimited(duel, sgs.Card_MethodUse)) and (not from:isProhibited(to, duel)) then 
			room:useCard(sgs.CardUseStruct(duel, from, to)) --使用决斗
		end
	end ,
}

sr_lijian = sgs.CreateViewAsSkill{
	name = "sr_lijian",
	n = 1,
	view_filter = function(self,selected,to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards~=1 then return nil end
		local card = sr_lijiancard:clone()
		card:addSubcard(cards[1])
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_lijiancard") 
	end
}
sr_diaochan:addSkill(sr_lijian)

--曼舞
sr_manwucard = sgs.CreateSkillCard{
	name = "sr_manwucard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName() and to_select:isMale()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_manwu")
		local dest = targets[1]
		local id = room:askForCardChosen(source, dest, "h", "sr_manwu")
		local card = sgs.Sanguosha:getCard(id) 					
		room:showCard(dest, card:getEffectiveId()) 
		room:getThread():delay()
		if card:getSuit() == sgs.Card_Diamond then
			local indulgence = sgs.Sanguosha:cloneCard("indulgence",card:getSuit(),card:getNumber())
			indulgence:deleteLater()			
			if not source:isProhibited(dest, indulgence) and not dest:containsTrick("indulgence") then
				indulgence:addSubcard(card)
				indulgence:setSkillName("sr_manwu")
				local use = sgs.CardUseStruct()
				use.card = indulgence
				use.from = dest
				use.to:append(dest)
				room:useCard(use)
			end
		else
			room:obtainCard(source, card, true)
		end
	end
}
sr_manwu = sgs.CreateViewAsSkill{
	name = "sr_manwu",
	n = 0,
	view_as = function(self, cards)
		return sr_manwucard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_manwucard") 
	end
}
sr_diaochan:addSkill(sr_manwu)

--拜月
local srbaiyue_list = {}
sr_baiyue = sgs.CreateTriggerSkill{
	name = "sr_baiyue",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.BeforeCardsMove,sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeCardsMove then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() ~= sgs.Player_NotActive then
					local move = data:toMoveOneTime()
					local source = move.from
					if source and source:objectName() ~= player:objectName() then
						if move.to_place == sgs.Player_DiscardPile then
							for _,card_id in sgs.qlist(move.card_ids) do
								table.insert(srbaiyue_list, card_id)
							end
						end
					end
					if move.from_places:contains(sgs.Player_DiscardPile) then
						for _,card_id in sgs.qlist(move.card_ids) do
							if table.contains(srbaiyue_list, card_id) then
								table.removeOne(srbaiyue_list, card_id)
							end
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if #srbaiyue_list > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:notifySkillInvoked(player, "sr_baiyue")
						room:broadcastSkillInvoke("sr_baiyue")
						local cardIds = sgs.IntList()
						for _,card_id in ipairs(srbaiyue_list) do
							cardIds:append(card_id)
						end
						room:fillAG(cardIds, player)
						local card_id = room:askForAG(player, cardIds, false, self:objectName())
						local card = sgs.Sanguosha:getCard(card_id)
						room:obtainCard(player, card, true)
						room:clearAG()
					end
					srbaiyue_list = {}
				end
			end
		end
	end
}
sr_diaochan:addSkill(sr_baiyue)
sr_diaochan:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_diaochan"] = "SR貂蟬",
["&sr_diaochan"] = "貂蟬",
["sr_lijian"] = "離間",
[":sr_lijian"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置一張牌並選擇兩名男性角色，令其中"..
"一名男性角色視為對另一名男性角色使用一張【決鬥】。",
["$sr_lijian"] = "將軍，那人對妾身，好生無禮",
["sr_manwu"] = "曼舞",
["sr_manwucard"] = "曼舞",
[":sr_manwu"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以展示一名男性角色的一張手牌，若此牌"..
"為方片，將之置於該角色的判定區內，視為【樂不思蜀】；若不為方片，你獲得之。",
["sr_baiyue"] = "拜月",
[":sr_baiyue"] = "回合結束階段開始時，你可以獲得本回合其他角色進入棄牌堆的一張牌。",
["$sr_manwu"] = "讓妾身為您獻上一舞！",
["$sr_baiyue"] = "羨慕吧。",
["~sr_diaochan"] = "紅顏多薄命，幾人能白頭！",
["losesr_manwu"] = "失去【曼舞】",
["losesr_baiyue"] = "失去【拜月】",
["losesr_lijian"] = "失去【離間】",
}

--SR华佗
sr_huatuo = sgs.General(extension,"sr_huatuo","qun",3)

--行医
sr_xingyicard = sgs.CreateSkillCard{
	name = "sr_xingyicard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() 		
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_xingyi")
		local dest = targets[1]
		local id = dest:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(id)
		room:obtainCard(source, card, false)
		if dest:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(dest, recover)
		end
	end
}
sr_xingyi = sgs.CreateViewAsSkill{
	name = "sr_xingyi",
	n = 0,
	view_as = function(self, cards)
		return sr_xingyicard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sr_xingyicard") 
	end
}
sr_huatuo:addSkill(sr_xingyi)

--刮骨
srguagudummycard = sgs.CreateSkillCard{
	name = "srguagudummycard",
}
sr_guagu = sgs.CreateTriggerSkill{
	name = "sr_guagu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local target = dying.who
		if not target:isKongcheng() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, "sr_guagu")
				room:broadcastSkillInvoke("sr_guagu")
				local count = target:getHandcardNum()
				local cards = srguagudummycard:clone()
				local list = target:getHandcards()
				for _,cd in sgs.qlist(list) do
					cards:addSubcard(cd)
				end
				room:throwCard(cards, target, player)
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(target, recover)
				if count >= 2 then
					target:drawCards(1)
				end
			end
		end
		return false	
	end
}
sr_huatuo:addSkill(sr_guagu)

--五禽
sr_wuqin = sgs.CreateTriggerSkill{
	name = "sr_wuqin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()		
		if not player:isKongcheng() then
			if player:getPhase() == sgs.Player_Finish then
				if room:askForCard(player, ".Basic", "srwuqindiscard", sgs.QVariant(), sgs.Card_MethodDiscard) then
					room:notifySkillInvoked(player, "sr_wuqin")
					room:broadcastSkillInvoke("sr_wuqin")
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					local choice = room:askForChoice(player, self:objectName(), "srwuqindraw+srwuqinplay")
					if choice == "srwuqindraw" then
						player:drawCards(2)
					elseif choice == "srwuqinplay" then
						local phase = player:getPhase()--保存阶段							
						player:setPhase(sgs.Player_Play)		--设置目标出牌阶段
						room:broadcastProperty(player, "phase")
						local thread = room:getThread()
						if not thread:trigger(sgs.EventPhaseStart,room,player) then			
							thread:trigger(sgs.EventPhaseProceeding,room,player)
						end		
						thread:trigger(sgs.EventPhaseEnd,room,player)							
						player:setPhase(phase) --设置玩家保存的阶段
						room:broadcastProperty(player,"phase")		
					end
				end
			end
		end
		return false		
	end
}
sr_huatuo:addSkill(sr_wuqin)
sr_huatuo:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_huatuo"] = "SR華佗",
["&sr_huatuo"] = "華佗",
["sr_xingyi"] = "行醫",
[":sr_xingyi"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以獲得一名已受傷的其他角色一張手牌" ..
"，然後令其回復1點體力。",
["sr_guagu"] = "刮骨",
[":sr_guagu"] = "當一名角色進入瀕死狀態時，你可以棄置其所有手牌（至少一張），然後該角色回復1點體力。若你以此"..
"法棄置其兩張或者更多的手牌時，該角色摸一張牌。",
["sr_wuqin"] = "五禽",
["srwuqindiscard"] = "你可以棄置一張基本牌以便發動技能“五禽”",
["srwuqindraw"] = "摸兩張牌",
["srwuqinplay"] = "進行一個額外的出牌階段",
[":sr_wuqin"] = "回合結束階段結束時，你可以棄置一張基本牌，然後選擇一項：摸兩張牌，或進行一個額外的出牌階段。",
["$sr_xingyi"] = "病根雖除，仍需調養百日。",
["$sr_guagu"] = "郡侯身體要緊，豈能拖延！",
["$sr_wuqin"] = "流水不腐，戶樞不蠹 ",
["~sr_huatuo"] = "人可醫，國難醫啊！",
["losesr_xingyi"] = "失去【行醫】",
["losesr_guagu"] = "失去【刮骨】",
["losesr_wuqin"] = "失去【五禽】",
}

--SR呂布
sr_lvbu = sgs.General(extension,"sr_lvbu","qun",4)

--极武
sr_jiwucard = sgs.CreateSkillCard{
	name = "sr_jiwucard", 
	target_fixed = true, 
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "sr_jiwu")
		room:setPlayerMark(source, "srjiwumark", source:getMark("srjiwumark") + 1)
		room:setPlayerFlag(source,"InfinityAttackRange")
	end
}
sr_jiwuvs = sgs.CreateViewAsSkill{
	name = "sr_jiwu", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		local count = sgs.Self:getHandcardNum() - 1
		if #cards == count then
			local srjiwucard = sr_jiwucard:clone()
			for _,card in ipairs(cards) do
				srjiwucard:addSubcard(card)
			end
			srjiwucard:setSkillName(self:objectName())
			return srjiwucard
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getHandcardNum() > 1 then
			return not player:hasUsed("#sr_jiwucard")
		end
		return false
	end
}

--极武BUFF
sr_jiwu = sgs.CreateTriggerSkill{
	name = "sr_jiwu",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.ConfirmDamage,sgs.CardFinished},
	view_as_skill = sr_jiwuvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local card = damage.card
			if player:getMark("srjiwumark") > 0 then
				if card then
					if card:isKindOf("Slash") then
						room:notifySkillInvoked(player, "sr_jiwu")
						damage.damage = damage.damage + player:getMark("srjiwumark")
						local msg = sgs.LogMessage()
						msg.type = "#SrJiwu"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - player:getMark("srjiwumark"))
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)
						data:setValue(damage)
					end
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if player:getMark("srjiwumark") > 0 then
				if card then
					if card:isKindOf("Slash") then
						room:setPlayerMark(player, "srjiwumark", 0)
					end
				end
			end
		end
		return false
	end
}

sr_jiwutm = sgs.CreateTargetModSkill{
	name = "#sr_jiwutm",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill("sr_jiwu") then
			if not player:hasEquip() then
				return 2
			end
		end
	end

}

sr_lvbu:addSkill(sr_jiwu)
sr_lvbu:addSkill(sr_jiwutm)
extension:insertRelatedSkills("sr_jiwu", "#sr_jiwutm")

--射戟
sr_sheji = sgs.CreateViewAsSkill{
	name = "sr_sheji", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		local weapon = sgs.Self:getWeapon()
		if weapon then
			if to_select:objectName() == weapon:objectName() then
				if to_select:objectName() == "Crossbow" then
					return sgs.Self:canSlashWithoutCrossbow()
				end
			end
		end
		return to_select:getTypeId() == sgs.Card_TypeEquip
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
			slash:addSubcard(id)
			slash:setSkillName(self:objectName())
			return slash
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:isNude()
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and not player:isNude()
	end
}
sr_lvbu:addSkill(sr_sheji)
--攻击范围
sr_shejitm = sgs.CreateTargetModSkill{
	name = "#sr_shejitm",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("sr_sheji") then
			if card:getSkillName() == "sr_sheji" then
				return 9999
			end
		end
		return 0
	end
}
sr_lvbu:addSkill(sr_shejitm)
extension:insertRelatedSkills("sr_sheji", "#sr_shejitm")
--获得武器牌时机
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
sr_shejiget = sgs.CreateTriggerSkill{
	name = "#sr_shejiget", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage,sgs.TargetConfirmed},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local source = damage.from
			local target = damage.to
			for _, srlvbu in sgs.qlist(room:getOtherPlayers(player)) do
				if srlvbu:hasSkill("sr_sheji") and source:objectName() ~= target:objectName() then
					if source:getWeapon() ~= nil then
						if not srlvbu:isNude() then
							if room:askForCard(srlvbu, "..", "@sr_sheji:"..source:objectName(), data, self:objectName()) then
								room:notifySkillInvoked(srlvbu, "sr_sheji")
								room:broadcastSkillInvoke("sr_sheji")
								room:obtainCard(srlvbu, source:getWeapon(), true)
							end
						end
					end
				end
			end
		else
			local use = data:toCardUse()
			local slash1 = use.card				
			if slash1:isKindOf("Slash") and slash1:getSkillName() == "sr_sheji" and 
				player:hasSkill("sr_sheji") then					
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. slash1:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. slash1:toString(), jink_data)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end				
}
sr_lvbu:addSkill(sr_shejiget)
extension:insertRelatedSkills("sr_sheji", "#sr_shejiget")
sr_lvbu:addSkill("#sr_choose")

sgs.LoadTranslationTable{
["sr_lvbu"] = "SR呂布",
["&sr_lvbu"] = "呂布",
["sr_jiwu"] = "極武",
[":sr_jiwu"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將你的手牌棄置至一張，若如此做，"..
"本回合你的攻擊範圍無限，你下一次使用的【殺】造成的傷害+1。<font color=\"blue\"><b>鎖定技"..
"，</b></font>若你的裝備區沒有牌，你使用的【殺】可以至多額外指定兩名合法目標。",

["srjiwumark"] = "武",
["sr_sheji"] = "射戟",
["sr_shejiget"] = "射戟",
["#sr_shejiget"] = "射戟",
[":sr_sheji"] = "當一名裝備區有武器牌的其他角色對另外一名角色造成傷害後，你可以棄置一張牌，然後獲得該角色的"..
"武器牌。你可以將裝備牌當無距離限制的【殺】使用或打出,你以此法使用的【殺】須連續使用兩張【閃】才能抵消。",
["@sr_sheji"] = "你可以棄置一張牌並獲得 %src 的武器牌 <br/> <b>操作提示</b>: 選擇一張牌→點擊確定<br/>",
["$sr_jiwu2"] = "誰敢擋我！",
["$sr_jiwu1"] = "真是無趣，你們一起上吧！",
["$sr_sheji"] = "夠膽的話，就來試試！",
["~sr_lvbu"] = "有意思，呵呵哈哈哈哈！",
["losesr_jiwu"] = "失去【極武】",
["losesr_sheji"] = "失去【射戟】",
["#SrJiwu"] = "%from 的技能 “<font color=\"yellow\"><b>烈弓</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

sgs.LoadTranslationTable{
	["#sr_caocao"] = "亂世奸雄",
	["#sr_simayi"] = "深塚之虎",
	["#sr_xiahoudun"] = "啖睛的蒼狼",
	["#sr_zhangliao"] = "古之昭虎",
	["#sr_guojia"] = "天妒英才",
	["#sr_xuchu"] = "甘效死命",
	["#sr_zhenji"] = "月下凌波",
-- 蜀勢力
	["#sr_liubei"] = "漢昭烈帝",
	["#sr_guanyu"] = "忠義神武",
	["#sr_zhangfei"] = "豪邁勇者",
	["#sr_zhugeliang"] = "三分天下",
	["#sr_zhaoyun"] = "銀龍逆鱗",
	["#sr_machao"] = "蒼穹錦獅",
	["#sr_huangyueying"] = "靈智共鳴",
-- 吳勢力
	["#sr_sunquan"] = "東吳大帝",
	["#sr_ganning"] = "懷鈴的烏羽",
	["#sr_lvmeng"] = "國士之風",
	["#sr_zhouyu"] = "英雋異才",
	["#sr_huanggai"] = "捨命一搏",
	["#sr_uxun"] = "定計破蜀",
	["#sr_daqiao"] = "韶光易逝",
	["#sr_sunshangxiang"] = "不讓鬚眉",
-- 群雄
	["#sr_lvbu"] = "神駒飛將",
	["#sr_huatuo"] = "聖手仁心",
	["#sr_diaochan"] = "絕代風華",
}

sgs.LoadTranslationTable{
[":losesr_rende"] = "任一角色的回合結束階段結束時，你可以將任意數量的手牌交給該角色 然後該角色進行一個額外"..
"的出牌階段",
[":losesr_chouxi"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置一張手牌並展示牌堆頂的"..
"兩張牌，然後令一名其他角色選擇一項：棄置一張與之均不同類別的牌，然後令你獲得這些牌；或者受到你造成的1"..
"點傷害並獲得其中一種類別的牌，然後你獲得其餘的牌",

[":losesr_shouji"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置一張牌並選擇兩名角色，然後"..
"根據你棄置牌的花色，視為其中一名你選擇的角色對另一名角色使用一張牌：<font color=\"black\"><b>♠</b></font>" ..
"【決鬥】，<font color=\"black\"><b>♣</b></font>【借刀殺人】，<font color=\"red\"><b>♥</b>< /font>【順手牽羊"..
"】，<font color=\"red\"><b>♦</b></font>【火攻】。<font color=\"red\"><b>（選擇第一個角色作為使用來源，選擇"..
"第二個角色作為被使用目標）</b></font>",
[":losesr_hemou"] = "其他角色的出牌階段開始時，你可以將一張手牌正面朝上交給該角色，該角色本階段限一次，可將一張"..
"與之相同花色的手牌按下列規則使用：<font color=\"black\"><b>♠</b></font>【決鬥】，<font color=\"black\">< b>♣"..
"</b></font>【借刀殺人】，<font color=\"red\"><b>♥</b></font>【順手牽羊】，<font color=\"red\">< b>♦</b></fon"..
"t>【火攻】。 ",
[":losesr_qicai"] = "每當你失去一次手牌時，你可以進行判定，若結果為紅色，你摸一張牌。",

[":losesr_benxi"] = "<font color=\"blue\"><b>鎖定技，</b></font>你計算與其他角色的距離時始終-1；<font"..
" color=\"blue\"><b>鎖定技，</b></font>你使用【殺】選擇目標後，目標角色須棄置一張裝備牌，否則此【殺】"..
"不可被【閃】響應。",
[":losesr_yaozhan"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以與一名其他角色拼點：若你贏，視為對"..
"其使用一張【殺】（此【殺】不計入每回合的使用限制）；若你沒贏，該角色可以對你使用一張【殺】。",

[":losesr_wenjiu"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將一張黑色手牌置於你的武將牌" ..
"上，稱為“酒”。當你使用【殺】選擇目標後，你可以將一張“酒”置入棄牌堆，然後當此【殺】造成傷害時，該傷害+1；"..
"當此【殺】被【閃】響應後，你摸一張牌。",
[":losesr_shuixi"] = "回合開始階段開始時，你可以展示一張手牌並選擇一名有手牌的其他角色，令其選擇一項：棄置一"..
"張與之相同花色的手牌，或失去1點體力。若該角色因此法失去體力，則此回合的出牌階段，你不能使用【殺】。",

[":losesr_sanfen"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以選擇兩名其他角色，其中一名"..
"你選擇的角色須對另外一名角色使用一張【殺】，然後另外一名角色須對你使用一張【殺】，你棄置不如此做者一張"..
"牌。<font color=\"red\"><b>（選擇第一個角色為作為第一個【殺】使用者）</b></font>",
[":losesr_guanxing"] = "回合開始/結束階段開始時，你可以觀看牌堆頂的X張牌（X為存活角色的數量，且最多為3），將"..
"其中任意數量的牌以任意順序置於牌堆頂，其餘以任意順序置於牌堆底。",
[":losesr_weiwo"] = "<font color=\"blue\"><b>鎖定技，</b></font>當你有手牌時，你防止受到的屬性傷害；當你沒有" ..
"手牌時，你防止受到非屬性傷害。",

[":losesr_xujin"] = "摸牌階段，你可以放棄摸牌，改為展示牌堆頂的五張牌，並令一名角色獲得其中一種花色的所有牌，"..
"再將其餘的牌置入棄牌堆。若如此做，你本回合的攻擊範圍和可以使用的【殺】數量與此法獲得的牌的數量相同。",
[":losesr_paoxiao"] = "出牌階段，當你使用【殺】對目標角色造成一次傷害並結算完畢後，你可以摸一張牌，然後選擇一"..
"項：使用一張【殺】，或令該角色棄置你一張牌。",

[":losesr_jiuzhu"] = "每當一張非轉化的【閃】進入棄牌堆時，你可以用一張不是「閃」的牌替換之。若此時不在你"..
"的回合內，你可以視為對當前回合角色使用一張【殺】，你以此法使用的【殺】無視防具。",
[":losesr_tuwei"] = "每當一張非轉化的【殺】進入棄牌堆時，若你是此【殺】的目標或使用者，你可以棄置一張可以"..
"造成傷害的牌，然後棄置此牌的目標或使用者的共計兩張牌",

[":losesr_quanheng"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將至少一張手牌當一張"..
"【無中生有】或【殺】使用，若你以此法使用的牌被【無懈可擊】或【閃】響應時，你摸等量的牌。",
[":losesr_xionglve"] = "摸牌階段，你可以放棄摸牌，改為展示牌堆頂的兩張牌，你獲得其中一張，然後將另一張牌置於"..
"你的武將牌上，稱為“略”。出牌階段，你可以將一張基本牌或錦囊牌的“略”當與之同類別的任意一張牌（延時類錦囊"..
"牌除外）使用，將一張裝備牌的“略”置於一名其他角色裝備區內的相應位置。",

[":losesr_dailao"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名其他角色與你各摸一張牌" ..
"或者各棄一張牌，然後你與其依次將武將牌翻面",
[":losesr_youdi"] = "若你的武將牌背面朝上，你可以將其翻面來視為你使用一張閃。每當你使用閃響應一名角色使用的殺"..
"時，你可以額外棄置任意數量的手牌，然後該角色棄置等量的牌",
[":losesr_ruya"] = "當你失去最後的手牌時，你可以將手牌補至你體力上限的張數，然後你的武將牌翻面",

[":losesr_yingcai"] = "摸牌階段，你可以放棄摸牌，改為展示牌堆頂的一張牌，你重複此流程直到你展示出第三種花色"..
"的牌時，將這張牌置入棄牌堆，然後獲得其餘的牌。",
[":losesr_weibao"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將一張手牌置於牌堆頂，然後" ..
"令一名其他角色選擇一種花色後摸一張牌並展示之，若此牌與所選花色不同，你對其造成1點傷害。",

[":losesr_shixue"] = "當你使用【殺】指定目標後，你可以摸兩張牌，若如此做，則當此【殺】被【閃】響應後，你須棄置兩張牌",
[":losesr_guoshi"] = "任一角色的回合開始階段開始時，你可以觀看牌堆頂的兩張牌，然後可以將其中任意張牌置於牌堆"..
"底，將其餘的牌以任意順序置於牌堆頂；任一角色的回合結束階段開始時,你可以令其獲得本回合因棄置或者判定進入"..
"棄牌堆的一張牌",

[":losesr_jiexi"] = "出牌階段，你可以與一名其他角色拼點，若你贏，視為對其使用一張【過河拆橋】。你可以重複此流"..
"程直到你以此法拼點沒贏。<font color=\"green\"><b>每階段限一次。 </b></font>",
[":losesr_youxia"] = "出牌階段，若你的武將牌正面朝上，你可以將你的武將牌翻面，然後從一名至兩名其他角色處各獲"..
"得一張牌；<font color=\"blue\"><b>鎖定技，</b></font>若你的武將牌背面朝上，你不是【殺】或【決鬥】的合法目標。",

[":losesr_zhouyan"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名其他角色摸一張牌，若"..
"如此做，視為你對其使用一張【火攻】，你可以重複此流程直到你以此法未造成傷害。每當你使用【火攻】造成一次"..
"傷害後，你可以摸一張牌",
[":losesr_zhaxiang"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將一張手牌扣置於牌堆頂，然"..
"後令一名其他角色選擇一項：交給你一張牌並棄置此牌；或展示並獲得此牌，若為【殺】，則視為你對其使用一張火"..
"屬性的【殺】（不計入出牌階段的使用限制）。",

[":losesr_fangxin"] = "當你需要使用一張【桃】時，你可以將一張<font color=\"black\"><b> ♣ </b></font>牌"..
"當【兵糧寸斷】或將一張<font color=\"red\"><b>♦</b></font>牌當【樂不思蜀】對自己使用，"..
"若如此做，視為你使用一張【桃】",
[":losesr_xiyu"] = "你的回合開始時，你可以棄置一名角色的一張牌，然後該角色進行一個額外的出牌階段",
[":losesr_wanrou"] = "你的<font color=\"red\"><b>♦</b></font>牌或你判定區的牌進入棄牌堆時，你可以令一名角"..
"色摸一張牌",

[":losesr_yinmeng"] = "<font color=\"green\"><b>出牌階段限X次，</b></font>若你有手牌，你可以展示一名其他男" ..
"性角色的一張手牌，然後展示你的一張手牌，若兩張類型相同，你與其各摸一張牌；若不同，你棄置其展示的牌，"..
"<font color=\"red\"><b>X為你已損失的體力且至少為1</b></font>",
[":losesr_xiwu"] = "當你使用的【殺】被目標角色的【閃】響應後，你可以摸一張牌，然後棄置其一張手牌",
[":losesr_juelie"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名手牌數與你不同的其他"..
"角色選擇一項：將手牌數調整至與你相等；或視為你對其使用一張殺（不計入出牌階段的使用限制）",

[":losesr_zhaoxiang"] = "當一名其他角色使用【殺】指定目標後，若該角色在你的攻擊範圍內，你令其選擇一項：你獲得其"..
"一張手牌，或此【殺】無效。若該角色不在你的攻擊範圍內，你可以棄置一張牌，然後令其作上述選擇",
[":losesr_zhishi"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以令一名其他角色選擇一項：棄置一張" ..
"基本牌，然後回復一點體力；或受到你造成的一點傷害，然後回復1點體力",

[":losesr_yiji"] = "每當你受到1點傷害後，你可以觀看牌堆頂的兩張牌，然後將一張牌交給一名角色，將另一張牌交給一名角色。 ",
[":losesr_huiqu"] = "回合開始階段開始時，你可以棄置一張手牌並進行一次判定，若結果為紅色，你將場上的一張牌移動到另一個相"..
"應的位置；若結果為黑色，你對一名角色造成1點傷害，然後該角色摸一張牌。",

[":losesr_aozhan"] = "每當你因【殺】或【決鬥】造成或受到1點傷害後，可將牌堆頂的一張牌置於你的武將牌上，稱為“戰”。 "..
"<font color=\"green\"><b>出牌階段限一次，</b></font>你可以選擇一項：將所有的“戰”收入手牌，或將所有的“戰”置入棄牌"..
"堆，然後摸等量的牌。",
[":losesr_huxiao"] = "出牌階段，當你使用【殺】造成傷害時，若你的武將牌正面朝上，你可以摸一張牌，然後令此傷害+1，若如此"..
"做，則此【殺】結算後，將你的武將牌翻面，並結束當前回合。",

[":losesr_guicai"] = "在一名角色的判定牌生效前，你可以選擇一項：亮出牌堆頂的一張牌代替之，或打出一張手牌代替之。",
[":losesr_langgu"] = "每當你造成或受到一次傷害後，你可以進行一次判定，若結果為黑色，你獲得對方的一張牌。",
[":losesr_zhuizun"] = "<font color=\"red\"><b>限定技，</b></font>當你進入瀕死狀態時，你可以回復體力至1點，令所有其他角"..
"色依次交給你一張手牌，然後當前回合結束後，你進行一個額外的回合。",

[":losesr_liuyun"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以橫置你的武將牌並棄置一張黑"..
"色牌，然後令一名角色選擇一項：回復1點體力，或摸兩張牌。",
[":losesr_lingbo"] = "一名角色的回合開始階段結束時，你可以重置你的武將牌，然後將場上的一張牌置於牌堆頂。",
[":losesr_qingcheng"] = "你可以橫置你的武將牌，視為你使用或打出一張【殺】；你可以重置你的武將牌，視為你使用"..
"或打出一張【閃】",

[":losesr_zhonghou"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>每當你攻擊範圍內的一名"..
"角色於其出牌階段需要使用或打出一張基本牌時，該角色可以聲明之，然後你可以失去1點體力，視為該角色使用或打出此牌",
[":losesr_ganglie"] = "出牌階段開始時，你可以失去1點體力，若如此做，你本回合下一次造成的傷害+1。且本回合你每造成1點"..
"傷害，回合結束時你便摸一張牌",

[":losesr_wuwei"] ="摸牌階段，你可以放棄摸牌，改為展示牌堆頂的三張牌，其中每有一張基本牌，你便可以視為對一名其"..
"他角色使用一張【殺】，然後你將這些基本牌置入棄牌堆，並獲得其餘的牌",
[":losesr_yansha"] = "摸牌階段，你可以少摸一張牌，若如此做，則此回合結束階段開始時，你可以將一張手牌置於你的武"..
"將牌上，稱為“掩”。當一名其他角色使用【殺】選擇目標後，你可以將一張“掩”置入棄牌堆，然後獲得其兩張牌",

[":losesr_lijian"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置一張牌並選擇兩名男性角色，令其中"..
"一名男性角色視為對另一名男性角色使用一張【決鬥】。",
[":losesr_manwu"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以展示一名男性角色的一張手牌，若此牌"..
"為方片，將之置於該角色的判定區內，視為【樂不思蜀】；若不為方片，你獲得之。",
[":losesr_baiyue"] = "回合結束階段開始時，你可以獲得本回合其他角色進入棄牌堆的一張牌。",

[":losesr_xingyi"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以獲得一名已受傷的其他角色一張手牌" ..
"，然後令其回復1點體力。",
[":losesr_guagu"] = "當一名角色進入瀕死狀態時，你可以棄置其所有手牌（至少一張），然後該角色回復1點體力。若你以此"..
"法棄置其兩張或者更多的手牌時，該角色摸一張牌。",
[":losesr_wuqin"] = "回合結束階段結束時，你可以棄置一張基本牌，然後選擇一項：摸兩張牌，或進行一個額外的出牌階段。",

[":losesr_jiwu"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以將你的手牌棄置至一張，若如此做，"..
"本回合你的攻擊範圍無限，你下一次使用的【殺】造成的傷害+1。<font color=\"blue\"><b>鎖定技"..
"，</b></font>若你的裝備區沒有牌，你使用的【殺】可以至多額外指定兩名合法目標。",
[":losesr_sheji"] = "當一名裝備區有武器牌的其他角色對另外一名角色造成傷害後，你可以棄置一張牌，然後獲得該角色的"..
"武器牌。你可以將裝備牌當無距離限制的【殺】使用或打出,你以此法使用的【殺】須連續使用兩張【閃】才能抵消。",
}
