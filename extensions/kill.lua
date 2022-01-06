module("extensions.kill", package.seeall)
extension = sgs.Package("kill")

sgs.LoadTranslationTable{
	["kill"] = "三國killSK包",	
}

local skills = sgs.SkillList()

--周倉
sk_zhoucang = sgs.General(extension,"sk_zhoucang","shu2",4, true)

sk_daoshi = sgs.CreateTriggerSkill{
	name = "sk_daoshi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:getEquips():length() > 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("sk_daoshi") then
					if p:objectName() ~= player:objectName() then
						local equip = room:askForCard(player,".|.|.|equipped","#sk_daoshi:"..p:objectName(),data,sgs.Card_MethodNone ,nil,false,self:objectName()) 			
						if not equip then return false end
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						if player:isAlive() then
							player:drawCards(1)
						end
						p:obtainCard(equip,true)
					else
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						player:drawCards(1)
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

sk_zhoucang:addSkill(sk_daoshi)

sgs.LoadTranslationTable{	
	["sk_zhoucang"] = "sk周倉",
	["&sk_zhoucang"] = "周倉",
	["#sk_zhoucang"] = "披肝瀝膽",
	["sk_daoshi"] = "刀侍",
	[":sk_daoshi"] = "其他角色的回合結束階段開始時，可以摸一張牌，然後將一張裝備牌交給你",
	["#sk_daoshi"] = "你可以將一張裝備牌交給 %src ",
	["@sk_daoshi"] = "是否發動“刀侍”？",
	["~sk_daoshi"] = "選擇一張裝備牌→選擇一名其他角色→點擊“確定”",
}

--sk許攸
sk_xuyou = sgs.General(extension,"sk_xuyou","wei2",3, true)
--夜襲
sk_yexiCard = sgs.CreateSkillCard{
	name = "sk_yexiCard",
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		
		room:broadcastSkillInvoke(self:objectName())
		room:setPlayerMark(targets[1],"can_sk_yexi",1)
	end
}
sk_yexiVS = sgs.CreateViewAsSkill{
	name = "sk_yexi" ,
	response_pattern = "@@sk_yexi",
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return (not to_select:isEquipped())
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = sk_yexiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}
sk_yexi = sgs.CreateTriggerSkill{
	name = "sk_yexi" ,
	frequency = sgs.Skill_NotFrequent ,
	view_as_skill = sk_yexiVS,
	events = {sgs.EventPhaseStart,sgs.PreCardUse} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:hasSkill("sk_yexi") and not player:isKongcheng() then
					room:askForUseCard(player, "@@sk_yexi", "@sk_yexi", -1, sgs.Card_MethodDiscard)
				elseif player:getMark("can_sk_yexi") > 0 then
					room:setPlayerMark(player,"can_sk_yexi",0)
				end
			elseif player:getPhase() == sgs.Player_Draw and player:getMark("can_sk_yexi") > 0 then
				room:setPlayerFlag(player, "can_sk_yexi")
			end
		elseif event == sgs.PreCardUse then
			local use = data:toCardUse()
			if player:hasFlag("can_sk_yexi") and use.card:isKindOf("Slash") and use.card:isRed() then
				for _, p in sgs.qlist(use.to) do
					p:addQinggangTag(use.card)
				end
			end
			return false
		end
		return false
	end
}
sk_yexitm = sgs.CreateTargetModSkill{
	name = "#sk_yexitm",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasFlag("can_sk_yexi") and card:isBlack() then
			return 1000
		end
	end,
}

--狂言
sk_kuangyan = sgs.CreateTriggerSkill{
	name = "sk_kuangyan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.damage == 1 and damage.nature == sgs.DamageStruct_Normal then
			room:notifySkillInvoked(player, "sk_kuangyan")
			room:broadcastSkillInvoke("sk_kuangyan",1)
			local msg = sgs.LogMessage()
			msg.type = "#AvoidDamage"
			msg.from = player
			msg.to:append(damage.from)
			msg.arg = self:objectName()
			msg.arg2 = damage.nature == sgs.DamageStruct_Fire and "fire_nature" or "thunder_nature"
			room:sendLog(msg)
			return true
		elseif damage.damage > 1 then
			room:notifySkillInvoked(player, "sk_kuangyan")
			room:broadcastSkillInvoke("sk_kuangyan",2)
			damage.damage = damage.damage + 1
			data:setValue(damage)
			return false
		end
		return false
	end
}
sk_xuyou:addSkill(sk_yexi)
sk_xuyou:addSkill(sk_yexitm)
sk_xuyou:addSkill(sk_kuangyan)
extension:insertRelatedSkills("sk_yexi", "sk_yexitm")

sgs.LoadTranslationTable{	
["sk_xuyou"] = "sk許攸",
["&sk_xuyou"] = "許攸",
["#sk_xuyou"] = "詭計智將",
["sk_yexi"] = "夜襲",
[":sk_yexi"] = "回合結束階段，你可以多棄一張手牌，然後指定你以外的一個角色。該角色將在他的下個出牌階段得到下述效果：1。使用黑色殺時無視距離。2.使用紅色殺無視防具。",
["@sk_yexi"] = "你可以發動“夜襲”，棄置一張手牌，並選擇一名你以外的角色。",
["~sk_yexi"] = "選擇一張手牌，並選擇一名角色",
["$sk_yexi"] = "出其不意，方可一招制敵。",
["sk_kuangyan"] = "狂言",
[":sk_kuangyan"] = "鎖定技，你受到1點無屬性傷害時，該傷害對你無效，你受到兩點或兩點以上傷害時，該傷害+1。",
["$sk_kuangyan1"] = "汝等皆匹夫爾，何足道哉？",
["$sk_kuangyan2"] = "什麼？竟敢如此對我？",
["~sk_xuyou"] = "汝等果然不可救藥！",
}

--吉平
sk_jiping = sgs.General(extension,"sk_jiping","qun",3, true)
--毒治
sk_duzhi = sgs.CreateTriggerSkill{
	name = "sk_duzhi",
	events = {sgs.HpRecover,sgs.Damage},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			local recover = data:toRecover()
			for i = 1,recover.recover do
				local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@sk_duzhi",true,true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:loseHp(target)
					room:askForUseSlashTo(target, player, "#sk_duzhi:"..player:objectName(),false)
				end
			end
		else
			local damage = data:toDamage()
			if not damage.card or not damage.card:isRed() or not damage.card:isKindOf("Slash") then return false end
			local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@sk_duzhi",true,true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(target)
				room:askForUseSlashTo(target, player, "#sk_duzhi:"..player:objectName(),false)
			end
		end
		return false
	end,

} 

sk_lieyi = sgs.CreateFilterSkill{
	name = "sk_lieyi",
	view_filter = function(self, card)
		return card:objectName() == "peach" or card:objectName() == "jink"
	end ,
	view_as = function(self, card)
		local wrap
		if card:objectName() == "peach" then
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:setSkillName(self:objectName())
			wrap = sgs.Sanguosha:getWrappedCard(card:getId())
			wrap:takeOver(slash)
		else
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
			analeptic:setSkillName(self:objectName())
			wrap = sgs.Sanguosha:getWrappedCard(card:getId())
			wrap:takeOver(analeptic)
		end
		return wrap
	end
}

sk_jiping:addSkill(sk_duzhi)
sk_jiping:addSkill(sk_lieyi)

sgs.LoadTranslationTable{
["sk_jiping"] = "sk吉平",
["&sk_jiping"] = "吉平",
["#sk_jiping"] = "太醫",
["sk_duzhi"] = "毒治",
[":sk_duzhi"] = "每當你回复1點體力或使用紅色【殺】造成一次傷害後，你可以令一名其他角色失去1點體力，然後該角色可以對你使用一張【殺】",
["@sk_duzhi"] = "你可以發動【毒治】，令一名其他角色失去1點體力，然後該角色可以對你使用一張【殺】",
["#sk_duzhi"] = "你可以對 %src 使用一張【殺】",
["sk_lieyi"] = "烈醫",
[":sk_lieyi"] = "<font color=\"blue\"><b>鎖定技，</b></font>你的【桃】均視為【殺】；你的【閃】均視為【酒】",
}

--孔融
sk_kongrong = sgs.General(extension,"sk_kongrong","qun",3, true)

sk_lirangVS = sgs.CreateViewAsSkill{
	name = "sk_lirang" ,
	n = 2,
	expand_pile = "li",
	view_filter = function(self, selected, to_select)
		return (#selected < 2) and sgs.Self:getPile("li"):contains(to_select:getEffectiveId())
	end ,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		peach:setSkillName(self:objectName())
		peach:addSubcard(cards[1])
		peach:addSubcard(cards[2])
		return peach
	end ,
	enabled_at_play = function(self, player)
		return player:isWounded() and player:getPile("li"):length()>=2
	end,
	enabled_at_response = function(self, player, pattern)
		return  (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach"))) and player:getPile("li"):length()>=2
	end,
}

sk_lirang = sgs.CreateTriggerSkill{
	name = "sk_lirang",
	events = {sgs.EventLoseSkill,sgs.EventPhaseEnd},
	view_as_skill = sk_lirangVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Start and (not player:isKongcheng()) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("sk_lirang") and (p:getPile("li"):length() < 4) then

						local pattern = ""
						local suitlist = {sgs.Card_Club,sgs.Card_Diamond,sgs.Card_Heart,sgs.Card_Spade}
		 				for _,suit in pairs(suitlist) do
							local can_use = true
							if p:getPile("li"):length() > 0 then
								local n = p:getPile("li"):length()
								for i = 1, n,1 do
									local ids = p:getPile("li")
									local id = ids:at(i-1)
									local card = sgs.Sanguosha:getCard(id)
									if card:getSuit() == suit then
										can_use = false
										break
									end
								end
							end
							if can_use then
								if suit == sgs.Card_Club then
									pattern = pattern.."club,"
								elseif suit == sgs.Card_Diamond then
									pattern = pattern.."diamond,"
								elseif suit == sgs.Card_Heart then
									pattern = pattern.."heart,"
								elseif suit == sgs.Card_Spade then
									pattern = pattern.."spade,"
								end
							end
						end
						if pattern == "" then
							 pattern = "."
						end
						pattern = ".|"..pattern.."|.|."
						room:setPlayerFlag(p,"sk_lirang_target")	
						local card = room:askForCard(player,pattern,"@sk_lirang1:"..p:objectName(),data,sgs.Card_MethodNone ,nil,false,self:objectName())
						room:setPlayerFlag(p,"-sk_lirang_target")	 
						if card then
							room:broadcastSkillInvoke("sk_lirang")
							p:addToPile("li",card)
							player:drawCards(1)
						end
					end
				end	
			end	
			return false
		elseif event == sgs.EventLoseSkill and data:toString() == "sk_lirang" then
			if not player:getPile("li"):isEmpty() then			
				player:clearOnePrivatePile("li")
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
--[[
sk_lirangPeach = sgs.CreateTriggerSkill{
	name = "#sk_lirang",
	events = {sgs.AskForPeaches,sgs.EventLoseSkill},
	view_as_skill = sk_lirangVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying = data:toDying()					
			while dying.who:getHp()<=0 do
				if player:getPile("li"):length() < 2 then return false end	
				if player:hasFlag("Global_PreventPeach") then return false end
				if not player:askForSkillInvoke("sk_lirang",data) then return false end
				if (player:getPile("li"):length() == 2) then			
					player:clearOnePrivatePile("li")
				else 
					local ids = player:getPile("li")
					for i=0,1 do 
						room:fillAG(ids, player)
						local id = room:askForAG(player, ids, false, "sk_lirang")
						ids:removeOne(id)	
						room:throwCard(id,player,player)							
						room:clearAG(player)
					end			
				end
				local peach = sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit, 0)
				peach:setSkillName("sk_lirang")
				room:useCard(sgs.CardUseStruct(peach,player,dying.who))
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "sk_lirang" then
			if not player:getPile("li"):isEmpty() then			
				player:clearOnePrivatePile("li")
			end
		end
		return false
	end,
}
]]--
sk_xianshi = sgs.CreateTriggerSkill{
	name = "sk_xianshi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local damage = data:toDamage()
		local from = damage.from
		if not from then return false end
		local room = player:getRoom()
		if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
		local choice = ""
		room:broadcastSkillInvoke(self:objectName())
		if from:isKongcheng() then 
			choice = "reduce"
		else
			choice = room:askForChoice(from,self:objectName(),"show+reduce",data)
		end
		if choice == "show" then
			room:showAllCards(from)
			room:askForDiscard(from,self:objectName(),1,1)
		else
			damage.damage = damage.damage -1
			if damage.damage <1 then
				return true
			end
			data:setValue(damage)
		end
		return false
	end
}

sk_kongrong:addSkill(sk_lirang)
--sk_kongrong:addSkill(sk_lirangPeach)
sk_kongrong:addSkill(sk_xianshi)
--extension:insertRelatedSkills("sk_lirang","#sk_lirang")

sgs.LoadTranslationTable{
["sk_kongrong"] = "sk孔融",
["#sk_kongrong"] = "凜然重義",
["&sk_kongrong"] = "孔融",
["sk_lirang"] = "禮讓",
--["#sk_lirang"] = "禮讓",
[":sk_lirang"] = "一名角色的回合開始階段結束時，該角色可以將一張手牌置於你的武將牌上，稱為“禮”，然後摸一張牌（你最多擁有四張「禮」）。每當你需要使用一張"..
"【桃】時，你可以將兩張“禮”置入棄牌堆，視為使用之",
["@sk_lirang1"] = "是否對 %src 發動禮讓？",
["li"] = "禮",
["sk_xianshi"] = "賢士",
[":sk_xianshi"] = "每當你受到一次傷害時，你可以令傷害來源選擇一項：展示所有手牌並棄置其中一張；或令此傷害-1",
["show"] = "展示手牌",
["reduce"] = "減少傷害",
}

--李嚴
sk_liyan = sgs.General(extension,"sk_liyan","shu2", 4,true)

sk_ly_yanliang = sgs.CreateTriggerSkill{
	name = "sk_ly_yanliang",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()	
		if event == sgs.EventPhaseStart then			
			if player:getPhase() ~= sgs.Player_Start then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:isAlive() and not p:isNude() then
					local card = room:askForCard(p,".|.|.|.","@sk_ly_yanliang:"..player:objectName(),data,self:objectName())
					if not card then return false end
					if card:isRed() then
						room:broadcastSkillInvoke(self:objectName(), 1)				
						room:setPlayerFlag(player,"afterplay")
					elseif card:isBlack() then
						room:broadcastSkillInvoke(self:objectName(), 2)				
						room:setPlayerFlag(player,"afterdiscard")
					end
				end
			end
		else			
			if not (player:hasFlag("afterplay") or player:hasFlag("afterdiscard")) then return false end								
			local change = data:toPhaseChange()			
			local to = change.to
			if to == sgs.Player_Draw then				
				if not player:isSkipped(to) then										
					player:skip(to)
				else
					room:setPlayerFlag(player,"SupplyShortaged")
				end				
			elseif (player:hasFlag("afterplay") and to == sgs.Player_Discard and not player:hasFlag("SupplyShortaged")) then				
				room:setPlayerFlag(player,"-afterplay")
				change.to = sgs.Player_Draw
				data:setValue(change)				
				player:insertPhase(sgs.Player_Draw)
			elseif (player:hasFlag("afterdiscard") and to == sgs.Player_Finish and not player:hasFlag("SupplyShortaged")) then
				room:setPlayerFlag(player,"-afterdiscard")
				
				change.to = sgs.Player_Draw
				data:setValue(change)				
				player:insertPhase(sgs.Player_Draw)
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
}

sk_liyan:addSkill(sk_ly_yanliang)

sgs.LoadTranslationTable{
	["sk_liyan"] = "sk李嚴",
	["&sk_liyan"] = "李嚴",
	["#sk_liyan"] = "性自矜高",
	["sk_ly_yanliang"] = "延糧",
	[":sk_ly_yanliang"] = "任一角色的回合開始階段開始時，你可以棄置一張紅色牌，令其本回合的摸牌階段於出牌階段後進行；或棄置一"..
"張黑色牌，令其本回合的摸牌階段於棄牌階段後進行",
	["@sk_ly_yanliang"] = "你可以對 %src 發動【延糧】，棄置一張紅色牌，令其本回合的摸牌階段於出牌階段後進行；或棄置一張黑色牌，令其本回合的摸牌階段於棄牌階段後進行",
}

--陳到
sk_chendao = sgs.General(extension,"sk_chendao","shu2", 4,true)

sk_zhongyong = sgs.CreateTriggerSkill{
	name = "sk_zhongyong",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging, sgs.DrawNCards,sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()		
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play then
				if player:hasFlag("sk_zhongyong") then
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do						 
						room:setFixedDistance(player, p, 1)
					end
				end
			end
			if change.from == sgs.Player_Play then
				if player:hasFlag("sk_zhongyong") then
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do 
						room:setFixedDistance(player, p, -1)
					end
				end
			end		
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerFlag(player,"-sk_zhongyong")
				if room:askForSkillInvoke(player,self:objectName(),data) then
					room:loseHp(player)
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					room:setPlayerFlag(player,"sk_zhongyong")
				end
			end
		elseif event == sgs.DrawNCards then
			if player:hasFlag("sk_zhongyong") then
				local n = data:toInt()
				n = n + player:getLostHp()
				data:setValue(n)
			end
		else
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName()) and player:getPhase() == sgs.Player_Discard and
				(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) 
				and player:hasFlag("sk_zhongyong") and not player:hasFlag("zhongyong_InTempMoving") then				
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
				if player:hasFlag("sk_zhongyong") and not lirang_card:isEmpty() then
					local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"#sk_zhongyong",true,true)											
					if target and target:isAlive() then
						room:setPlayerFlag(player, "zhongyong_InTempMoving")
						local move3 = sgs.CardsMoveStruct()
						move3.card_ids = lirang_card
						move3.to_place = sgs.Player_PlaceHand
						move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), "sk_zhijiao","")
						move3.to = target						
						room:moveCardsAtomic(move3, true)
						room:setPlayerFlag(player, "-zhongyong_InTempMoving")
						room:setPlayerFlag(player,"-sk_zhongyong")
					end
				end
			end
		end
		return false
	end					
}

sk_chendao:addSkill(sk_zhongyong)

sgs.LoadTranslationTable{
["sk_chendao"] = "sk陳到",
["&sk_chendao"] = "陳到",
["#sk_chendao"] = "白毫之烈",
["sk_zhongyong"] = "忠勇",
[":sk_zhongyong"] = "回合開始階段開始時，你可以失去1點體力，然後於此回合的摸牌階段摸牌時，可額外摸x張牌（x為你已損失的體力值）；於此回合的出牌階段，當你計算與其他角色的距離時，始終為1；於此回合的棄牌階段棄牌後，可指定一名其他角色獲得你棄置的牌",
["#sk_zhongyong"] = "選擇一名其他角色，獲得你本階段的棄牌",
}

--孫皓
sk_sunhao = sgs.General(extension,"sk_sunhao","wu2", 4,true)

sk_baoliCard = sgs.CreateSkillCard{
	name = "sk_baoliCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets==0 and (not to_select:hasEquip() or to_select:getJudgingArea():length() > 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self,room,source,targets)
		room:damage(sgs.DamageStruct("sk_baoli",source,targets[1]))
	end
}

sk_baoli = sgs.CreateViewAsSkill{
	name = "sk_baoli",
	n = 0,
	view_as = function(self,cards)
		return sk_baoliCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#sk_baoliCard")
	end
}

sk_sunhao:addSkill(sk_baoli)

sgs.LoadTranslationTable{
["#sk_sunhao"] = "歸命侯",
["sk_sunhao"] = "sk孫皓",
["&sk_sunhao"] = "孫皓",
["sk_baoli"] = "暴戾",
[":sk_baoli"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以對一名裝備區沒有牌或是判定區有牌的其他角色造成1點傷害",
}

--朱然
sk_zhuran = sgs.General(extension,"sk_zhuran","wu2", 4,true)

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

sk_danshou = sgs.CreateTriggerSkill{
	name = "sk_danshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local from = use.from
			if from and not from:isKongcheng() and not player:isKongcheng() and from:objectName() ~= player:objectName() 
			  and use.to:contains(player) and use.card:isKindOf("Slash") and player:hasSkill("sk_danshou") then			
				if player:pindian(from, "sk_danshou", nil) then
					room:broadcastSkillInvoke(self:objectName(), 1)
					if player:isAlive() then
						player:drawCards(1)
					end
					if from:isAlive() and not from:isNude() and player:canDiscard(from,"he") then
						local to_throw = room:askForCardChosen(player, from, "he", self:objectName())
						local card = sgs.Sanguosha:getCard(to_throw)
						room:throwCard(card, from, player)
					end
				else
					room:setPlayerMark(player,"sk_danshou_failed",1)
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and not use.card:isKindOf("SkillCard") and use.from then
				local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if p:getMark("sk_danshou_failed") > 0 then
						jink_table[index] = 0
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_"..use.card:toString(), jink_data)
				room:setPlayerMark(player,"sk_danshou_failed",0)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

sk_yonglie = sgs.CreateTriggerSkill{
	name = "sk_yonglie",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		if not from or from:isDead() then return false end
		if not (damage.card and damage.card:isKindOf("Slash")) then return false end

		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:inMyAttackRange(player) and p:hasSkill("sk_yonglie") then
				local _data = sgs.QVariant()
				_data:setValue(from)	
				if room:askForSkillInvoke(p,self:objectName(),_data) then
					room:broadcastSkillInvoke(self:objectName())
					room:loseHp(p)
					room:damage(sgs.DamageStruct("sk_yonglie",p,from))
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target:isAlive()
	end
}

sk_zhuran:addSkill(sk_danshou)
sk_zhuran:addSkill(sk_yonglie)

sgs.LoadTranslationTable{
["sk_zhuran"] = "sk朱然",
["&sk_zhuran"] = "朱然",
["#sk_zhuran"] = "不動之督",
["sk_danshou"] = "膽守",
[":sk_danshou"] = "<font color=\"blue\"><b>鎖定技，</b></font>當一名角色使用【殺】指定你為目標後，若你有手牌，該角色須與"..
"你拼點，若你贏，你摸一張牌，然後棄置其一張牌；若你沒贏，此【殺】不可被【閃】響應",
["sk_yonglie"] = "勇烈",
[":sk_yonglie"] = "當你攻擊範圍內的一名角色受到【殺】造成的一次傷害後，你可以失去1點體力，然後對傷害來源造成1點傷害",
}

--丁奉
sk_dingfeng = sgs.General(extension,"sk_dingfeng","wu2","4",true)
--搏戰
sk_bozhan = sgs.CreateTriggerSkill{
	name = "sk_bozhan",
	frequency = sgs.Skill_NotFrequency,
	events = {sgs.CardFinished,sgs.Damaged,sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local from = use.from
			if use.card and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					if p:getMark("sk_bozhan"..use.from:objectName()) > 0 then
						room:setPlayerFlag(p,"sk_bozhan_audio")
						local card = room:askForUseSlashTo(p, use.from, "#sk_bozhan:"..use.from:objectName(),false)
						room:setPlayerFlag(p,"-sk_bozhan_audio")
						room:setPlayerMark(p,"sk_bozhan"..use.from:objectName() , 0)
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				if damage.to:getMark("sk_bozhan"..damage.from:objectName()) > 0 then
					room:setPlayerMark(damage.to,"sk_bozhan"..damage.from:objectName() , 0)
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				invoke = false
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (use.from == p or use.to:contains(p)) and p:hasSkill("sk_bozhan") then
						invoke = true
					end
				end
				if invoke then
					for _, p in sgs.qlist(use.to) do
						room:setPlayerMark(p,"sk_bozhan"..use.from:objectName() , 1)
					end
				end
			end
			if use.card:isKindOf("Slash") and use.from and use.from:hasFlag("sk_bozhan_audio") then
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
--輕襲
sk_qingxi = sgs.CreateTriggerSkill{
	name = "sk_qingxi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self,event,player,data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if player:getEquips():length() < p:getEquips():length() then
				local _data = sgs.QVariant()
				_data:setValue(p)
				--if player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player, "sk_qingxi")
					local msg = sgs.LogMessage()
					msg.type = "#SkChinxi"
					msg.from = player
					msg.to:append(p)
					msg.arg = use.card:objectName()
					room:sendLog(msg)
					jink_table[index] = 0
				--end
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}

sk_dingfeng:addSkill(sk_bozhan)
sk_dingfeng:addSkill(sk_qingxi)

sgs.LoadTranslationTable{
["sk_dingfeng"] = "sk丁奉",
["&sk_dingfeng"] = "丁奉",
["#sk_dingfeng"] = "清側重臣",
["sk_bozhan"] = "搏戰",
[":sk_bozhan"] = "當你使用或被使用一張【殺】並完成結算後，若此【殺】未造成傷害，則此【殺】的目標或你可以對你或此【殺】的使用者使用一張【殺】(無距離限制）。",
["sk_qingxi"] = "輕襲",
[":sk_qingxi"] = "<font color=\"blue\"><b>鎖定技，</b></font>當你使用【殺】指定一個目標後，若你裝備區的牌數少於該角色，則其不能使用【閃】響應此【殺】。",
["#SkChinxi"] = "%from 的技能 “<font color=\"yellow\"><b>輕襲</b></font>”被觸發，%to 無法響應此 %arg ",
["#sk_bozhan"] = "你可以對 %src 使用一張【殺】",
}

--sk郭女王
sk_guonuwang = sgs.General(extension,"sk_guonuwang","wei2","3",false)
--恭慎
sk_gongshenCard = sgs.CreateSkillCard{
	name = "sk_gongshenCard" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)	
		room:drawCards(source, 1, "sk_gongshen")
		local less_card = true
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:getHandcardNum() < source:getHandcardNum() then
				less_card = false
				break	
			end
		end
		if less_card == true then
			local theRecover = sgs.RecoverStruct()
			theRecover.recover = 1
			theRecover.who = source
			room:recover(source, theRecover)
		end
	end
}

sk_gongshen = sgs.CreateViewAsSkill{
	name = "sk_gongshen" ,
	n = 3 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected < 3 then
			return true
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 3 then return nil end
		local card = sk_gongshenCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self,player)
		return (player:getHandcardNum() + player:getEquips():length()) >= 3	
	end
}
--儉約
sk_jianyue = sgs.CreateTriggerSkill{
	name = "sk_jianyue" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local less_card = true
			local less_card_Num = 99
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() < player:getHandcardNum() then
					less_card = false
					break	
				end
				if p:getHandcardNum() < less_card_Num then
					less_card_Num = p:getHandcardNum()	
				end
			end
			if less_card == true then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("sk_jianyue") then
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForSkillInvoke(p, "sk_jianyue", _data) then
							room:broadcastSkillInvoke(self:objectName())
							local n = less_card_Num - player:getHandcardNum() + 1

							local ids = room:getDiscardPile()
							local getcard_ids = sgs.IntList()
							
							for i = 1 , n, 1 do
								if ids:length() > 0 then
									local get_id = ids:at(math.random(1,ids:length())-1)
									ids:removeOne(get_id)
									getcard_ids:append(get_id)
								end
							end
							local move = sgs.CardsMoveStruct()
							move.card_ids = getcard_ids
							move.to = player
							move.to_place = sgs.Player_PlaceHand
							room:moveCardsAtomic(move, true)
						end
					end
				end
			end
		end
		return false
	end
}
sk_guonuwang:addSkill(sk_gongshen)
sk_guonuwang:addSkill(sk_jianyue)
sgs.LoadTranslationTable{
	["sk_guonuwang"] = "sk郭女王",
	["&sk_guonuwang"] = "郭女王",
	["#sk_guonuwang"] = "文德皇后",
	["sk_gongshen"] = "恭慎",
	[":sk_gongshen"] = "出牌階段，你可以棄置三張牌，然後摸一張牌；若此時你的手牌數為全場最少（或之一），你恢復一點體力",
	["sk_jianyue"] = "儉約",
	[":sk_jianyue"] = "一名角色的回合結束階段開始時，若該角色的手牌數為全場最少（或之一），你可以令其從棄牌堆裡隨機獲得牌直到其手牌數不為最少（或之一）",
}

--張魯
sk_zhanglu = sgs.General(extension,"sk_zhanglu","qun","3",true)
--普渡
sk_puduCard = sgs.CreateSkillCard{
	name = "sk_puduCard" ,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@pudu")
		room:doSuperLightbox("sk_zhanglu","sk_pudu")
		for _, p in sgs.qlist(room:getAllPlayers()) do
			room:doAnimate(1, source:objectName(), p:objectName())
		end	
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if not p:isKongcheng() then
				room:obtainCard(source,p:wholeHandCards(),true)
			end	
		end
		for i = 0, 10, 1 do
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if p:getHandcardNum() < (source:getHandcardNum() - 1) then
					--local id = room:askForCardChosen(source, source, "h", "sk_pudu")
					--room:obtainCard(p, id, true)
					local card = room:askForCard(source, ".!", "@sk_pudu-give:"..p:objectName(), sgs.QVariant(), sgs.Card_MethodNone)	
					if not card then
						local pile = source:getHandcards()
						local length = pile:length()
						local n = math.random(1, length)
						local id = pile:at(n - 1)
						room:obtainCard(p, id, false)
					else
						room:obtainCard(p, card, false)
					end
					room:doAnimate(1, source:objectName(), p:objectName())
				end
			end
		end
	end
}

sk_puduVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_pudu",
	view_as = function(self,cards)
		return sk_puduCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@pudu") > 0
	end
}
sk_pudu = sgs.CreateTriggerSkill{
		name = "sk_pudu",
		frequency = sgs.Skill_Limited,
		limit_mark = "@pudu",
		view_as_skill = sk_puduVS ,
		on_trigger = function() 
		end
}
--義舍
sk_yisheCard = sgs.CreateSkillCard{
	name = "sk_yisheCard" ,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if to_select:getHandcardNum() > sgs.Self:getHandcardNum() then return false end
		return true 
	end,
	on_use = function(self, room, source, targets)	
		
		if targets[1]:getHandcardNum() <= source:getHandcardNum() then
			if targets[1]:isKongcheng() then
				local n2 = source:wholeHandCards() 
				room:obtainCard(targets[1], n2, true)			
			else	
				local n1 = targets[1]:wholeHandCards()
				local n2 = source:wholeHandCards()
				if targets[1]:isAlive() then 
					room:obtainCard(targets[1], n2, true)
				end
				if source:isAlive() then 
					room:obtainCard(source, n1, true)
				end
			end
		end
	end
}

sk_yishe = sgs.CreateZeroCardViewAsSkill{
	name = "sk_yishe",
	view_as = function(self,cards)
		return sk_yisheCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_yisheCard") < 1 
	end
}
--米道
sk_midaoCard = sgs.CreateSkillCard{
	name = "sk_midaoCard" ,
	target_fixed = true,
	--will_throw = false,
	on_use = function(self, room, source, targets)	
		local n = source:getHandcardNum()
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:getHandcardNum() > n then
				room:doAnimate(1, source:objectName(), p:objectName())
				local id = room:askForCardChosen(source, p, "h", "sk_midao")
				room:obtainCard(source, id, true)	
			end	
		end
		local most_card = true
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:getHandcardNum() >= source:getHandcardNum() then
				most_card = false
				break	
			end
		end
		if most_card == true then
			room:loseHp(source)
		end
	end
}
sk_midao = sgs.CreateZeroCardViewAsSkill{
	name = "sk_midao",
	view_as = function(self,cards)
		return sk_midaoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_midaoCard") < 1 
	end
}
sk_zhanglu:addSkill(sk_pudu)
sk_zhanglu:addSkill(sk_yishe)
sk_zhanglu:addSkill(sk_midao)
sgs.LoadTranslationTable{
	["sk_zhanglu"] = "sk張魯",
	["&sk_zhanglu"] = "張魯",
	["#sk_zhanglu"] = "五斗天官",
	["sk_pudu"] = "普渡",
	[":sk_pudu"] = "限定技，你可以獲得所有角色的手牌，並依序交給其他角色一張手牌，直到你的手牌不為全場最多",
	["sk_yishe"] = "義舍",
	[":sk_yishe"] = "出牌階段限一次，你可以與一名手牌不大於你的角色互換手牌",
	["sk_midao"] = "米道",
	[":sk_midao"] = "出牌階段限一次，你可以依序獲得手牌比你多的角色的一張手牌；若你的手牌是全場最多，你失去一點體力",
	["@sk_pudu-give"] = "請交給 %src 一張手牌",
}

--sk董卓
sk_dongzhuo = sgs.General(extension,"sk_dongzhuo","qun","6",true)
--暴虐
sk_baonue = sgs.CreateTriggerSkill{
	events = {sgs.EventPhaseChanging},
	name = "sk_baonue",
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Finish then
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:isAlive() then
					if p:getEquips():length() + p:getHandcardNum() >= 2 then 
						local card = room:askForCard(p, "..", "@sk_baonue:" ..player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
						if card then
							room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(), ""))
						else
							room:askForDiscard(p, self:objectName(), 2, 2, false, true)
							room:damage(sgs.DamageStruct(self:objectName(), p,player))
						end
					elseif p:getEquips():length() + p:getHandcardNum() == 1 then 
						local card = room:askForCard(p, "..!", "@sk_baonue:" ..player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
						room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(), ""))
					end
				end
			end
		end
		return false
	end
}
sk_lingnu = sgs.CreateTriggerSkill{
	name = "sk_lingnu", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase ==sgs.Player_Finish then
				if player:getMark("damaged_record-Clear") >= 2 then
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					room:loseMaxHp(player)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:isNude() and player:isAlive() then
							local id = room:askForCardChosen(player, p, "he", "sk_lingnu")
							room:obtainCard(player, id, false)
						end
					end
				end
			end
		end

	end,
}
sk_dongzhuo:addSkill(sk_baonue)
sk_dongzhuo:addSkill(sk_lingnu)
sgs.LoadTranslationTable{
	["sk_dongzhuo"] = "sk董卓",
	["&sk_dongzhuo"] = "董卓",
	["#sk_dongzhuo"] = "闇魔王",
	["sk_baonue"] = "暴虐",
	["sk_baonue1"] = "交給發起者一張牌",
	["sk_baonue2"] = "棄置二張牌，並對發起者造成一點傷害",
	[":sk_baonue"] = "鎖定技，你的回合結束時，你令所有角色選擇一項：1.交給你一張牌，2.棄置二張牌，並對你造成一點傷害",
	["sk_lingnu"] = "凌怒",
	[":sk_lingnu"] = "鎖定技，回合結束時，若你於此回合受到超過兩點的傷害，你減一點體力上限，然後從其他角色處獲得一張牌",
	["@sk_baonue"] = "請交給 %src 一張牌，否則你需棄置二張牌，並對 %src 造成一點傷害",
}
--SK司馬師
sk_simashi = sgs.General(extension,"sk_simashi","wei2","4",true)
--權略
sk_quanlue = sgs.CreateTriggerSkill{
	name = "sk_quanlue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play then
			if room:askForSkillInvoke(player, "sk_quanlue", data) then
				room:showAllCards(player)
				room:broadcastSkillInvoke(self:objectName(), 2)
				local choosesuit = room:askForSuit(player, "sk_quanlue")
				local cards = player:getHandcards()
				local n = 0
				for _, id in sgs.qlist(cards) do 
					if id:getSuit() == choosesuit then
						n = n + 1
					end
				end
				room:drawCards(player, n, "sk_quanlue")
				room:setPlayerMark(player, "sk_quanlue"..choosesuit, 1)
			end
		elseif player:getPhase() == sgs.Player_Discard then
			local suitlist = {sgs.Card_Club,sgs.Card_Diamond,sgs.Card_Heart,sgs.Card_Spade}
			local choosesuit
 			for _,suit in pairs(suitlist) do
				if player:getMark("sk_quanlue"..suit) == 1 then
					room:setPlayerMark(player, "sk_quanlue"..suit, 0)
					room:broadcastSkillInvoke(self:objectName(), 1)
					choosesuit = suit
				end
			end
			if choosesuit then
				local cards = player:getHandcards()
				local ids = sgs.IntList()
				for _, id in sgs.qlist(cards) do 
					if id:getSuit() == choosesuit then
						ids:append(id:getEffectiveId())
					end
				end
				if not ids:isEmpty() then
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = nil
					move.to_place = sgs.Player_DiscardPile
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "sk_quanlue", nil)
					room:moveCardsAtomic(move, true)
				end
			end
		end
	end
}

sk_simashi:addSkill(sk_quanlue)

sgs.LoadTranslationTable{
	["sk_simashi"] = "sk司馬師",
	["&sk_simashi"] = "司馬師",
	["#sk_simashi"] = "晉之基石",
	["sk_quanlue"] = "權略",
	[":sk_quanlue"] = "回合開始時，你可以選擇一種花色，並摸與之等量的手牌數；若如此做，回合結束時，你須棄置該花色的所有手牌",
}
--SK司馬昭
sk_simazhao = sgs.General(extension,"sk_simazhao","wei2","3",true)
--制和
sk_zhiheCard = sgs.CreateSkillCard{
	name = "sk_zhiheCard" ,
	target_fixed = true,
	on_use = function(self, room, source, targets)	
		room:showAllCards(source)
		local n = source:getHandcardNum()
		local cards = source:getHandcards()
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
		local extra = #suit_set
		source:drawCards(extra, self:objectName())
	end
}

sk_zhihe = sgs.CreateViewAsSkill{
	name = "sk_zhihe",
	n = 999, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards)
		local countD = 0
		local countC = 0
		local countH = 0
		local countS = 0
		local playercards = sgs.Self:getHandcards()
		local n = playercards:length()
		for id2 = 0,n-1,1 do
			local id = playercards:at(id2)
			if id:getSuit() == sgs.Card_Heart then
					countH = countH + 1
	   		elseif id:getSuit() == sgs.Card_Diamond then
					countD = countD + 1
				elseif id:getSuit() == sgs.Card_Spade then
					countS = countS + 1
				elseif id:getSuit() == sgs.Card_Club then
					countC = countC + 1
			end
		end
		local useD = 0
		local useC = 0
		local useH = 0
		local useS = 0
		for _, id in ipairs(cards) do 
			if id:getSuit() == sgs.Card_Heart then
					useH = useH + 1
	   		elseif id:getSuit() == sgs.Card_Diamond then
					useD = useD + 1
				elseif id:getSuit() == sgs.Card_Spade then
					useS = useS + 1
				elseif id:getSuit() == sgs.Card_Club then
					useC = useC + 1
			end
		end
		if (useD == countD - 1 or countD == 0) and
		(useH == countH - 1 or countH == 0 ) and
		(useS == countS - 1 or countS == 0 ) and
		(useC == countC - 1 or countC == 0 ) then
			local jihocard = sk_zhiheCard:clone()
			for _,card in ipairs(cards) do
				jihocard:addSubcard(card)
			end
			jihocard:setSkillName(self:objectName())
			return jihocard
		end
	end, 
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_zhiheCard") < 1
	end
}
--招心
sk_zhaoxin = sgs.CreateMasochismSkill{
	name = "sk_zhaoxin" ,
	on_damaged = function(self, target, damage)
		if target:askForSkillInvoke(self:objectName(), sgs.QVariant():setValue(damage)) then
			local room = target:getRoom()
			room:showAllCards(target)
			room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			if not target:isKongcheng() then
				local cards = target:getHandcards()
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
				extra = #suit_set
				target:drawCards(4-extra, self:objectName())
			else
				target:drawCards(4, self:objectName())
			end
		end
	end
}

sk_simazhao:addSkill(sk_zhihe)
sk_simazhao:addSkill(sk_zhaoxin)
sgs.LoadTranslationTable{
	["sk_simazhao"] = "sk司馬昭",
	["&sk_simazhao"] = "司馬昭",
	["#sk_simazhao"] = "狼子野心",
	["sk_zhihe"] = "制合",
	[":sk_zhihe"] = "出牌階段，你可以將手牌棄置至X張(X為你手牌擁有的花色數)，然後將你的手牌數翻倍",
	["sk_zhaoxin"] = "昭心",
	[":sk_zhaoxin"] = "當你受到傷害後，你可以摸X張牌(X為你缺乏的花色數)",
}

--sk田豐
sk_tianfeng = sgs.General(extension,"sk_tianfeng","qun","3",true)
--死諫
sk_sijian = sgs.CreateTriggerSkill{
	name = "sk_sijian",
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:notifySkillInvoked(player, "sk_sijian")
				room:broadcastSkillInvoke("sk_sijian")
				for i = 1, player:getHp(), 1 do
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canDiscard(p, "he") then _targets:append(p) end
					end
					if not _targets:isEmpty() then
						local to_discard = room:askForPlayerChosen(player, _targets, "sk_sijian", "@sk_sijian-discard", true)
						if to_discard then
							room:doAnimate(1, player:objectName(), to_discard:objectName())
							room:throwCard(room:askForCardChosen(player, to_discard, "he", "sk_sijian", false, sgs.Card_MethodDiscard), to_discard, player)
						else
							break
						end
					else
						break
					end
					if not player:getAI() then
						room:getThread():delay()
					end
				end
			end
		end
		return false
	end
}

--剛直
sk_gangzhi = sgs.CreateTriggerSkill{
	name = "sk_gangzhi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		--if player:askForSkillInvoke(self:objectName(), sgs.QVariant():setValue(damage)) then
		if player:askForSkillInvoke(self:objectName(), data) then
			if player:isKongcheng() then
				room:notifySkillInvoked(player, "sk_gangzhi")
				room:broadcastSkillInvoke("sk_gangzhi",2)
				room:drawCards(player, 3, "sk_jianyue")
				player:turnOver()
				return false
			else
				room:notifySkillInvoked(player, "sk_gangzhi")
				room:broadcastSkillInvoke("sk_gangzhi",1)
				room:throwCard(player:wholeHandCards(),player)
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
sk_tianfeng:addSkill(sk_sijian)
sk_tianfeng:addSkill(sk_gangzhi)
sgs.LoadTranslationTable{
	["sk_tianfeng"] = "sk田豐",
	["&sk_tianfeng"] = "田豐",
	["#sk_tianfeng"] = "剛而犯上",
	["sk_sijian"] = "死諫",
	[":sk_sijian"] = "當你失去最後一張手牌時，你可以棄置場上的X張牌(X為你的體力值)",
	["sk_gangzhi"] = "剛直",
	[":sk_gangzhi"] = "當你受到傷害時，若你有手牌，你可以棄置所有手牌，然後防止此傷害；若你沒有手牌，你可以將你的武將牌翻面，然後摸三張牌",
	["@sk_sijian-discard"] = "請選擇棄置牌的對象",
}
--sk全琮
sk_quancong = sgs.General(extension,"sk_quancong","wu2","4",true)
--邀名
sk_yaomingCard = sgs.CreateSkillCard{
	name = "sk_yaoming",
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
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to:".. card:objectName())
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("QiaobianTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
sk_yaomingVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_yaoming",
	view_as = function()
		return sk_yaomingCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sk_yaoming"
	end,
}

sk_yaoming = sgs.CreateTriggerSkill{
	name = "sk_yaoming",
	frequency = sgs.Skill_Frequency,
	events = {sgs.CardUsed, sgs.CardResponded},
	view_as_skill = sk_yaomingVS,
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
				if player:getMark("used_suit_num-Clear") == 1 and player:getMark("sk_yaoming_used_1-Clear") == 0 then
					if room:askForSkillInvoke(player,self:objectName(),data) then
						room:broadcastSkillInvoke("sk_yaoming",1)
						room:drawCards(player, 1, "sk_yaoming")
						room:setPlayerMark(player, "sk_yaoming_used_1-Clear", 1)
					end

				elseif player:getMark("used_suit_num-Clear") == 2 and player:getMark("sk_yaoming_used_2-Clear") == 0 then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:canDiscard(p, "ej") then _targets:append(p) end
					end
					if not _targets:isEmpty() then
						local s = room:askForPlayerChosen(player, _targets, "sk_yaoming", "@sk_yaoming-discard", true)
						if s then
							room:doAnimate(1, player:objectName(), s:objectName())
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke("sk_yaoming",2)
							room:throwCard(room:askForCardChosen(player, s, "ej", "sk_yaoming", false, sgs.Card_MethodDiscard), s, player)
						end
					end
					room:setPlayerMark(player, "sk_yaoming_used_2-Clear", 1)


				elseif player:getMark("used_suit_num-Clear") == 3 and player:getMark("sk_yaoming_used_3-Clear") == 0 then

					room:askForUseCard(player, "@@sk_yaoming", "@sk_yaoming", -1, sgs.Card_MethodNone)
					room:setPlayerMark(player, "sk_yaoming_used_3-Clear", 1)


				elseif player:getMark("used_suit_num-Clear") == 4 and player:getMark("sk_yaoming_used_4-Clear") == 0  then

					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "sk_yaoming", "@sk_yaoming-damage", true)
					if s then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName(),4)
						room:doAnimate(1, player:objectName(), s:objectName())
						room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))
					end
					room:setPlayerMark(player, "sk_yaoming_used_4-Clear", 1)
				end
		end
	end,
}
sk_quancong:addSkill(sk_yaoming)
sgs.LoadTranslationTable{
	["sk_quancong"] = "sk全琮",
	["&sk_quancong"] = "全琮",
	["#sk_quancong"] = "慕勢耀族",
	["sk_yaoming"] = "邀名",
	[":sk_yaoming"] = "出牌階段，若此張牌是你於此回合使用牌的第一種花色：你摸一張牌；第二種花色：你棄置場上的一張牌；第三種花色：你移動場上的一張牌；第四種花色：你對一名角色造成一點傷害",
	["@sk_yaoming-discard"] = "請選擇失去牌的角色",

	["@sk_yaoming-damage"] = "請選擇受到傷害的角色",
	["@sk_yaoming"] = "你可以移動場上的一張牌。",
	["@sk_yaoming-to"] = "請選擇移動【%arg】的目標角色",
	["~sk_yaoming"] = "選擇一張牌→選擇一名角色→點擊確定",
}
--sk麋竹
sk_mizhu = sgs.General(extension,"sk_mizhu","shu2","3",true)
--資國
sk_ziguoCard = sgs.CreateSkillCard{
	name = "sk_ziguoCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:isWounded()
	end,
	on_use = function(self, room, source, targets)	
			
		room:drawCards(targets[1], 2, "sk_ziguo")
		room:addPlayerMark(source, "sk_ziguo-Clear")
	end
}

sk_ziguo = sgs.CreateZeroCardViewAsSkill{
	name = "sk_ziguo",
	view_as = function(self,cards)
		return sk_ziguoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_ziguoCard") < 1
	end
}
sk_ziguoMax = sgs.CreateMaxCardsSkill{
	name = "#sk_ziguoMax", 
	extra_func = function(self, target)
		if target:hasSkill(sk_ziguo) and target:getMark("sk_ziguo-Clear") > 0 then
			local hp = target:getHp()
			--return math.max(-2 ,-hp)
			return (-2) * target:getMark("sk_ziguo-Clear")
		end
	end
}
--商道
sk_shangdao = sgs.CreateTriggerSkill{
	name = "sk_shangdao" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then return false end
		for _, mizu in sgs.qlist(room:getOtherPlayers(player)) do
			if mizu:hasSkill("sk_shangdao") and mizu:getHandcardNum() < player:getHandcardNum() then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local ids = room:getNCards(1)
				room:fillAG(ids)
				room:getThread():delay()
				room:clearAG()
				local card = sgs.Sanguosha:getCard(ids:at(0))
				mizu:obtainCard(card)
			end
		end
		return false
	end
}

sk_mizhu:addSkill(sk_ziguo)
sk_mizhu:addSkill(sk_ziguoMax)
sk_mizhu:addSkill(sk_shangdao)
extension:insertRelatedSkills("sk_ziguo","sk_ziguoMax")

sgs.LoadTranslationTable{
	["sk_mizhu"] = "sk麋竺",
	["&sk_mizhu"] = "麋竺",
	["#sk_mizhu"] = "富甲一方",
	["sk_ziguo"] = "資國",
	[":sk_ziguo"] = "出牌階段限一次，你可以令一名已受傷的角色摸兩張牌，然後你的手牌上限-2",
	["sk_shangdao"] = "商道",
	[":sk_shangdao"] = "鎖定技，其他角色的出牌階段開始時，若其手牌數大於你，你展示牌堆頂的一張牌並獲得之",
}

--sk陸抗
sk_lukang = sgs.General(extension,"sk_lukang","wu2","4",true)
--審時
sk_shenshi = sgs.CreateTriggerSkill{
	name = "sk_shenshi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local phase = change.to
		if phase ==  sgs.Player_Discard then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, "sk_shenshi", data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local n = player:getHandcardNum()
				room:drawCards(player, n, "sk_shenshi")
				room:setPlayerFlag(player, "sk_shenshi")
			end
		end
	end
}
--至交
sk_zhijiao = sgs.CreateTriggerSkill{
	name = "sk_zhijiao",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zhijao",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:removeTag("srguoshicard")
			end
		elseif event == sgs.EventPhaseStart and player:getMark("@zhijao") > 0 and player:getPhase() == sgs.Player_Finish then	
			local lirang_card = sgs.IntList()
			local DiscardPile = room:getDiscardPile()
			local tag = room:getTag("srguoshicard"):toString():split("+")
			room:removeTag("srguoshicard")
			if #tag == 0 then return false end				
			for _,is in ipairs(tag) do
				if is~="" and DiscardPile:contains(tonumber(is)) then
					lirang_card:append(tonumber(is))
				end
			end
			--為了AI
			room:setPlayerMark(player,"sk_zhijiao_cardnum",lirang_card:length())
						
			local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@sk_zhijiao-card",true,true)
			if target and target:isAlive() then
				room:notifySkillInvoked(player,"sk_zhijiao")
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				room:doSuperLightbox("sk_lukang","sk_zhijiao")
				room:removePlayerMark(player, "@zhijao")
				local move3 = sgs.CardsMoveStruct()
				move3.card_ids = lirang_card
				move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), "sk_zhijiao","")
				move3.to_place = sgs.Player_PlaceHand
				move3.to = target						
				room:moveCardsAtomic(move3, true)
			end
		end
	end,
}


sk_zhijiaomove = sgs.CreateTriggerSkill{
	name = "#sk_zhijiao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player or player:isDead() or player:getPhase() == sgs.Player_NotActive then return false end		
		local move = data:toMoveOneTime()			
		if (move.to_place == sgs.Player_DiscardPile) 
			and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
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


sk_lukang:addSkill(sk_shenshi)
sk_lukang:addSkill(sk_zhijiao)
sk_lukang:addSkill(sk_zhijiaomove)

extension:insertRelatedSkills("sk_zhijiao","#sk_zhijiao")

sgs.LoadTranslationTable{
	["sk_lukang"] = "sk陸抗",
	["&sk_lukang"] = "陸抗",
	["#sk_lukang"] = "巨川舟楫",
	["sk_shenshi"] = "審時",
	[":sk_shenshi"] = "棄牌階段開始時，你可以摸等同於手牌數的牌",
	["sk_zhijiao"] = "至交",
	["~sk_zhijiao"] = "至交",
	[":sk_zhijiao"] = "限定技，回合結束階段開始時，你可以令一名角色獲得本回合你因棄置而進入棄牌堆的牌",
	["@sk_zhijiao-card"] = "你可以將你棄置的牌交給一名你選擇的角色",
}
--sk孫乾
sk_sunqian = sgs.General(extension,"sk_sunqian","shu2","3",true)
--隨驥
sk_suijiCard = sgs.CreateSkillCard{
	name = "sk_suijiCard",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local currnet = room:getCurrent()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), currnet:objectName(), "sk_suiji","")
		room:moveCardTo(self,currnet,sgs.Player_PlaceHand,reason)
		local n1 = currnet:getHandcardNum()
		local n2 = currnet:getHp()
		--room:sendCompulsoryTriggerLog(source, "sk_suiji") --這句話表示XX被觸發
		if (n1-n2) > 0 then
			local prompt1 = string.format("sk_suijigive:%s", source:objectName())
			local to_exchange = room:askForExchange(currnet, "sk_suiji", (n1-n2), (n1-n2), false, prompt1)
			room:moveCardTo(to_exchange, source,sgs.Player_PlaceHand, false)
			room:getThread():delay()
		end
	end
}
sk_suijiVS = sgs.CreateViewAsSkill{
	name = "sk_suiji" ,
	response_pattern = "@@sk_suiji",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		return (not to_select:isEquipped())
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = sk_suijiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}

sk_suiji = sgs.CreateTriggerSkill{
	name = "sk_suiji" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = sk_suijiVS,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Discard then return false end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if (not p:isKongcheng()) and p:hasSkill("sk_suiji") then
				room:askForUseCard(p, "@@sk_suiji", "@sk_suiji:"..player:objectName(), -1)
			end
		end
		return false
	end
}
--鳳儀
sk_fengyi = sgs.CreateTriggerSkill{
	name = "sk_fengyi" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.to:length() == 1 and use.card:isNDTrick() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:drawCards(player, 1, "sk_fengyi")
				end
			end
		end
		return false
	end
}
sk_sunqian:addSkill(sk_suiji)
sk_sunqian:addSkill(sk_fengyi)
sgs.LoadTranslationTable{
	["sk_sunqian"] = "sk孫乾",
	["&sk_sunqian"] = "孫乾",
	["#sk_sunqian"] = "雍容秉忠",
	["sk_suiji"] = "隨驥",
	[":sk_suiji"] = "其他角色的棄牌階段開始時，你可以交給其任意張手牌，然後其交給你超過體力值數量的手牌",
	["sk_fengyi"] = "鳳儀",
	[":sk_fengyi"] = "當你成為非延時類錦囊牌的唯一目標時，你可以摸一張牌",
	["@sk_suiji"] = "你可以將任意張手牌交給 %src ，然後其交給你超過體力值數量的手牌",
	["sk_suijigive"] = "請交给該角色（%src）超過體力值數量的手牌",
	["~sk_suiji"] = "選擇任意手牌，然後點選一名角色",
}
--sk程昱
sk_chengyu = sgs.General(extension,"sk_chengyu","wei2","3",true)
--捧日
sk_pengriCard = sgs.CreateSkillCard{
	name = "sk_pengriCard" ,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)	
		source:drawCards(2, self:objectName())
		--room:broadcastSkillInvoke("sk_pengri", math.random(1,2))
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:distanceTo(source) <= p:getAttackRange() and source:isAlive() then
				room:askForUseSlashTo(p, source, "@sk_pengri:"..source:objectName(),true)
			end
		end
	end
}

sk_pengri = sgs.CreateZeroCardViewAsSkill{
	name = "sk_pengri",
	view_as = function(self,cards)
		return sk_pengriCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_pengriCard") < 1 
	end
}
--膽謀
sk_danmou = sgs.CreateMasochismSkill{
	name = "sk_danmou" ,
	on_damaged = function(self, target, damage)
		local room = target:getRoom()
		if damage.from then
			local data = sgs.QVariant()
			data:setValue(damage.from)
			if room:askForSkillInvoke(target, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))

				local exchangeMove = sgs.CardsMoveList()
				local move1 = sgs.CardsMoveStruct(target:handCards(), damage.from, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), damage.from:objectName(), "sk_danmou", ""))
				local move2 = sgs.CardsMoveStruct(damage.from:handCards(), target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, damage.from:objectName(), target:objectName(), "sk_danmou", ""))
				exchangeMove:append(move1)
				exchangeMove:append(move2)
				room:moveCardsAtomic(exchangeMove, false)

			end
		end
	end
}

sk_chengyu:addSkill(sk_pengri)
sk_chengyu:addSkill(sk_danmou)
sgs.LoadTranslationTable{
	["sk_chengyu"] = "sk程昱",
	["&sk_chengyu"] = "程昱",
	["#sk_chengyu"] = "籌妙絕倫",
	["sk_pengri"] = "捧日",
	[":sk_pengri"] = "出牌階段，你可以摸兩張牌，然後所有攻擊範圍內包含你的角色可依次對你使用一張殺",
	["@sk_pengri"] = "你可以對 %src 使用一張【殺】。",
	["$sk_pengri1"] = "捧泰山之日，定吾主之名!",
	["$sk_pengri2"] = "以將軍之神武，霸王之業可圖也!",
	["sk_danmou"] = "膽謀",
	[":sk_danmou"] = "當你受到傷害時，你可以與傷害來源互換手牌",
	["$sk_danmou1"] = "背水為陣，伏兵十隊!",
	["$sk_danmou2"] = "兵只七百，爾可敢來攻？",
	["~sk_chengyu"] = "知足不辱，吾當急流湧退",
}

--sk禰衡
sk_miheng = sgs.General(extension,"sk_miheng","qun","3",true)
--舌劍
sk_shejianCard = sgs.CreateSkillCard{
	name = "sk_shejianCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:getMark("sk_shejian-Clear") == 0 and not to_select:isNude() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)	
		local id = room:askForCardChosen(source, targets[1], "he", "sk_shejian") 
		room:throwCard(id, targets[1], source)
		local choices = {"shujuan_notslash"}
		if targets[1]:canSlash(source, nil, false) then
			table.insert(choices, "shujuan_slash" )
		end
		local choice = room:askForChoice(targets[1], "sk_shejian", table.concat(choices, "+"))
		if choice == "shujuan_slash" then
			if targets[1]:canSlash(source, nil, false) then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("sk_shejian")
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = targets[1]
				local dest =  source
				use.to:append(dest)
				room:useCard(use)
				
			end
		end
		room:setPlayerMark(targets[1], "sk_shejian-Clear",1)
	end
}

sk_shejian = sgs.CreateZeroCardViewAsSkill{
	name = "sk_shejian" ,
	view_as = function(self, cards)
		return sk_shejianCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return (not player:getArmor())
	end
}
--狂傲
sk_kuangao = sgs.CreateTriggerSkill{
	name = "sk_kuangao",
	frequency = sgs.Skill_NotFrequency,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if use.card and use.card:isKindOf("Slash") and use.from then
			for _, p in sgs.qlist(use.to) do
				if use.from:isAlive() and p:hasSkill("sk_kuangao") and p:isAlive() and p:objectName() ~= use.from:objectName() then
					local choices = {}

					if math.min(use.from:getMaxHp(),5) > use.from:getHandcardNum() then
						table.insert(choices, "kuangao_Draw")
					end

					if not (use.from:isKongcheng() or p:isKongcheng()) then
						table.insert(choices, "kuangao_Discard")
					end

					if #choices > 0 then
						table.insert(choices, "cancel")
						local choice = room:askForChoice(p, "sk_kuangao", table.concat(choices, "+"), data)
						if choice == "kuangao_Draw" then
							room:doAnimate(1, p:objectName(), use.from:objectName())
							local n = math.min(use.from:getMaxHp(),5) - use.from:getHandcardNum() 
							room:broadcastSkillInvoke(self:objectName(), 1)
							use.from:drawCards(n, self:objectName()) 
						elseif choice == "kuangao_Discard" then
							room:doAnimate(1, p:objectName(), use.from:objectName())
							room:broadcastSkillInvoke(self:objectName(), 2)
							room:throwCard(p:wholeHandCards(),p,p)
							room:throwCard(use.from:wholeHandCards(),use.from,p)
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
			
sk_miheng:addSkill(sk_shejian)
sk_miheng:addSkill(sk_kuangao)
sgs.LoadTranslationTable{
	["sk_miheng"] = "sk禰衡",
	["&sk_miheng"] = "禰衡",
	["#sk_miheng"] = "不可一世",
	["sk_shejian"] = "舌劍",
	[":sk_shejian"] = "每回合每名角色限一次，若你沒有防具，你可以棄置一名角色的一張牌，然後該角色可以視為對你出了一張「殺」",
	["shujuan_slash"] = "視為對該角色使用一張殺",
	["shujuan_notslash"] = "不使用之",
	["sk_kuangao"] = "狂傲",
	[":sk_kuangao"] = "當一張對你使用的「殺」結算後，你可以選擇：1.棄置所有手牌(至少一張)，然後傷害來源棄置所有手牌；2.令傷害來源將手牌數補至體力上限(最多為5張)",
	["kuangao_Draw"] = "令傷害來源將手牌數補至體力上限(最多為5張)",
	["kuangao_Discard"] = "棄置所有手牌(至少一張)，然後傷害來源棄置所有手牌",
}
--孫魯育
sk_sunluyu = sgs.General(extension,"sk_sunluyu","wu2","3",false)
--惠斂
sk_huilianCard = sgs.CreateSkillCard{
	name = "sk_huilianCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0)
	end,
	on_use = function(self, room, source, targets)	
			
		local room = source:getRoom()
		local data = sgs.QVariant()
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|heart"
		judge.good = true
		judge.reason = self:objectName()
		judge.who = targets[1]
		room:judge(judge)
		if judge:isGood() then
			local card = judge.card
			targets[1]:obtainCard(card) 
			local recover = sgs.RecoverStruct()
			recover.who = targets[1]
			room:recover(targets[1], recover)
		else
			local card = judge.card
			targets[1]:obtainCard(card)
			return true
		end
	end
}

sk_huilian = sgs.CreateZeroCardViewAsSkill{
	name = "sk_huilian",
	view_as = function(self,cards)
		return sk_huilianCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_huilianCard") < 1
	end
}
--溫良
sk_wenliang = sgs.CreateTriggerSkill{
	name = "sk_wenliang" ,
	events = {sgs.FinishJudge} ,
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if judge.card and judge.card:isRed() then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("sk_wenliang") then
					if room:askForSkillInvoke(p,"sk_wenliang",data) then
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(1, self:objectName())
					end
				end
			end
		end
		return false
	end
}

sk_sunluyu:addSkill(sk_wenliang)
sk_sunluyu:addSkill(sk_huilian)
sgs.LoadTranslationTable{
	["sk_sunluyu"] = "sk孫魯育",
	["&sk_sunluyu"] = "孫魯育",
	["#sk_sunluyu"] = "捨身飼虎",
	["sk_wenliang"] = "溫良",
	[":sk_wenliang"] = "當一名角色的判定牌生效後，若結果是紅色，你可以摸一張牌",
	["sk_huilian"] = "惠斂",
	[":sk_huilian"] = "你的回合開始時，你可以令一名角色進行一次判定並獲得其生效後的判定牌，若結果為紅桃，該角色回復一點體力",
	["sk_huilianCard"] = "惠斂判定",
}

--顏良
sk_yanliang = sgs.General(extension,"sk_yanliang","qun","4",true)
--虎步
sk_hubu = sgs.CreateTriggerSkill{
	name = "sk_hubu", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage,sgs.Damaged}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card then
			if card:isKindOf("Slash") then

				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)

				local _targets  = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if (not room:isProhibited(player, p, duel)) then
						_targets:append(p)
					end
				end

				if not _targets:isEmpty() then
					local to_duel = room:askForPlayerChosen(player, _targets, "sk_hubu", "@sk_hubu-duel", true, true)
					if to_duel then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), to_duel:objectName())
						local data = sgs.QVariant()
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|spade"
						judge.good = false
						judge.reason = self:objectName()
						judge.who = to_duel
						room:judge(judge)
						if judge:isGood() then
							duel:setSkillName("sk_hubu_audio")
							local use = sgs.CardUseStruct()
							use.card = duel
							use.from = player
							local dest = to_duel
							use.to:append(dest)
							duel:toTrick():setCancelable(false)
							room:useCard(use)
						end
					end
				end
			end
		end		
		return false
	end
}
sk_yanliang:addSkill(sk_hubu)
sgs.LoadTranslationTable{
	["sk_yanliang"] = "sk顏良",
	["#sk_yanliang"] = "猛虎出欄",
	["&sk_yanliang"] = "顏良",
	["sk_hubu"] = "虎步",
	[":sk_hubu"] = "當你用「殺」造成傷害，或是受到「殺」造成的傷害後，你可以令一名角色進行判定，若結果不為黑桃，視為你對其使用了一張決鬥，此決鬥無法被無懈",
	["@sk_hubu-duel"] = "你可以令一名角色進行判定，若結果不為黑桃，視為你對其使用了一張決鬥，此決鬥無法被無懈",
}	

--張寶
sk_zhangbao = sgs.General(extension,"sk_zhangbao","qun","3",true)
--影兵
sk_yingbingCard = sgs.CreateSkillCard{
	name = "sk_yingbing",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self) and to_select:hasFlag("sk_yingbing_target")
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
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
sk_yingbingVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_yingbing",
	view_as = function()
		return sk_yingbingCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@sk_yingbing"
	end
}

sk_yingbing = sgs.CreateTriggerSkill{
	name = "sk_yingbing" ,
	events = {sgs.FinishJudge} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if judge.card:isBlack() and p:hasSkill("sk_yingbing") then
				room:setPlayerFlag(judge.who,"sk_yingbing_target")
				room:askForUseCard(p, "@@sk_yingbing", "@sk_yingbing-slash")
				room:setPlayerFlag(judge.who,"-sk_yingbing_target")
			end
		end
		return false
	end
}
--咒縛
sk_zhoufu = sgs.CreateTriggerSkill{
	name = "sk_zhoufu" ,
	events = {sgs.EventPhaseChanging,sgs.EventLoseSkill} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					local _data = sgs.QVariant()
					_data:setValue(player)
					if p:canDiscard(p, "h") and p:hasSkill("sk_zhoufu") then
						if room:askForCard(p, ".|.|.|hand", "@zofu:"..player:objectName(), _data, self:objectName()) then	
							room:broadcastSkillInvoke(self:objectName())
							local judge = sgs.JudgeStruct()
							judge.reason = self:objectName()
							judge.who = player
							room:judge(judge)
							local card = judge.card
							if card:getSuit() == sgs.Card_Spade then
								local msg = sgs.LogMessage()
								msg.type = "#zofuLoseSkill"
								msg.from = p
								msg.to:append(player)
								room:sendLog(msg)
								room:filterCards(player,player:getCards("he"),true)
								for _,skill in sgs.qlist(player:getVisibleSkillList())do
									room:addPlayerMark(player,"Qingcheng"..skill:objectName())
									room:addPlayerMark(player,"sk_zofu"..skill:objectName())
								end
							elseif card:getSuit() == sgs.Card_Club then	
								room:askForDiscard(player, "sk_zhoufu", 2, 2, false, false)
							end
						end
					end
				end
			elseif change.to == sgs.Player_NotActive then
				for _,skill in sgs.qlist(player:getVisibleSkillList())do
					if player:getMark("sk_zofu"..skill:objectName()) > 0 then
						room:removePlayerMark(player,"Qingcheng"..skill:objectName())
						room:removePlayerMark(player,"sk_zofu"..skill:objectName())
					end
				end
			end
			--return false
		elseif event == sgs.EventLoseSkill then --失去本技能时将相应技能返还
			for _, dest in sgs.qlist(room:getOtherPlayers(player)) do 
				--if dest:getMark("str_joexin") > 0 then 
					for _,skill in sgs.qlist(dest:getVisibleSkillList())do
						room:removePlayerMark(dest,"Qingcheng"..skill:objectName())
					end
				--room:removePlayerMark(dest,"str_joexin")
				--end
			end
		end
	end
}
sk_zhangbao:addSkill(sk_yingbing)
sk_zhangbao:addSkill(sk_zhoufu)
sgs.LoadTranslationTable{
	["sk_zhangbao"] = "sk張寶",
	["&sk_zhangbao"] = "張寶",
	["#sk_zhangbao"] = "地公將軍",
	["sk_zhoufu"] = "咒縛",
	[":sk_zhoufu"] = "任意角色的回合開始前，你可以棄置一張手牌令其判定，若結果為黑桃，其於本回合失去所有技能；若結果為梅花，其棄置兩張手牌",
	["sk_yingbing"] = "影兵",
	[":sk_yingbing"] = "當一名角色的判定牌生效後，若結果是黑色，你可以視為對該角色出一張「殺」",
	["@zofu"] = "你要對  %src 發動技能「咒縛」嗎？",
	["#zofuLoseSkill"] = "受到 %from 技能「咒縛」的影響， %to 於本回合失去了所有技能",
}
--sk馬良
sk_maliang = sgs.General(extension,"sk_maliang","shu2","3",true)
--雅慮
sk_yalu = sgs.CreateTriggerSkill{
	name = "sk_yalu",
	events = {sgs.EventPhaseStart,sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play) or event == sgs.Damaged then
			if room:askForSkillInvoke(player, "sk_yalu", data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local cards = room:getNCards(2)
				local left = cards
				if not left:isEmpty() then
					room:askForGuanxing(player, left, sgs.Room_GuanxingUpOnly)
				end
				room:drawCards(player,1)
			end
			return false
		end
	end
}
--協穆
sk_xiemu = sgs.CreateTriggerSkill{
	name = "sk_xiemu" ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then 
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:canDiscard(p, "h") and p:hasSkill("sk_xiemu") then
					local _data = sgs.QVariant()
					_data:setValue(player)
					local id = room:askForCard(p, ".", "@sk_xiemu-give", _data, sgs.Card_MethodNone)
					if id then
						room:doAnimate(1, p:objectName(), player:objectName())
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						room:setPlayerFlag(player, "sk_xiemu")
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, p:objectName(), nil, "sk_xiemu", nil)
						room:moveCardTo(id, p, nil, sgs.Player_DrawPile, reason, true)
					end
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("sk_xiemu") == true then
				room:drawCards(player,1)
				room:setPlayerFlag(player, "-sk_xiemu")
			end		
		end
		return false
	end
}

sk_maliang:addSkill(sk_yalu)
sk_maliang:addSkill(sk_xiemu)
sgs.LoadTranslationTable{
	["sk_maliang"] = "sk馬良",
	["&sk_maliang"] = "馬良",
	["#sk_maliang"] = "白眉智士",
	["sk_yalu"] = "雅慮",
	["#sk_yalu"] = "雅慮",
	[":sk_yalu"] = "你的出牌階段開始時，或你受傷時，你可以觀看牌堆頂的兩張牌，並以任意順序置於牌堆頂，然後摸一張牌",
	["sk_xiemu"] = "協穆",
	[":sk_xiemu"] = "其他角色的回合開始時，你可以將一張手牌至於牌堆頂，然後該角色回合結束時摸一張牌",
	["@sk_xiemu-give"] = "你可以發動技能「協穆」，將一張手牌至於牌堆頂；若如此做，當前回合角色於回合結束時摸一張牌",
}
--SK王平
sk_wangping = sgs.General(extension,"sk_wangping","shu2",4, true)

--義諫(你可以跳过你的出牌阶段并令一名其他角色摸一张牌，然后若该角色的手牌数不少于你的手牌数，你回复1点体力。)
sk_yijian = sgs.CreateTriggerSkill{
	name = "sk_yijian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local nextphase = change.to
		local room = player:getRoom()
		if nextphase == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				if room:askForSkillInvoke(player, self:objectName(), data) then					
					local list = room:getOtherPlayers(player)
					local target = room:askForPlayerChosen(player, list, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player, self:objectName())
--					room:broadcastSkillInvoke("sk_yijian")
					room:doAnimate(1, player:objectName(), target:objectName())
					target:drawCards(1)
					if target:getHandcardNum() >=  player:getHandcardNum() then
						local recover = sgs.RecoverStruct()
						recover.card = nil
						recover.who = player
						recover.recover = 1
						room:recover(player, recover)
					end
					player:skip(sgs.Player_Play)
				end
			end
		end
		return false
	end
}
sk_wangping:addSkill(sk_yijian)

--飞军(锁定技，出牌阶段开始时，若你的手牌数不小于你的体力值，本阶段你的攻击范围+X且可以额外使用一张【杀】(X为你当前体力值)；若你的手牌数少于你的体力值，你不能使用【杀】直到回合结束。)
sk_feijun = sgs.CreateTriggerSkill{
	name = "sk_feijun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			if player:getHandcardNum() >= player:getHp() then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke("sk_feijun",1)
				room:setPlayerFlag(player, "feijunyes")
			else
				room:setEmotion(player, "bad")
				room:broadcastSkillInvoke("sk_feijun",2)
				room:setPlayerFlag(player, "-feijunyes")
				room:setPlayerCardLimitation(player, "use,response", "Slash", true)
			end
		end
		return false
	end,
	priority = -1
}
sk_wangping:addSkill(sk_feijun)
--飞军BUFF
sk_feijunmod = sgs.CreateTargetModSkill{
	name = "#sk_feijunmod",
	frequency = sgs.Skill_NotFrequent,
	residue_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			if target:hasFlag("feijunyes") then 
				return 1 
			end
		end
	end,
	distance_limit_func = function(self, from, card)
		if from:hasFlag("feijunyes") then 
			return from:getHp()
		end
	end
}
sk_wangping:addSkill(sk_feijunmod)
extension:insertRelatedSkills("sk_feijun", "#sk_feijunmod")

sgs.LoadTranslationTable{
["sk_wangping"] = "sk王平",
["&sk_wangping"] = "王平",
["#sk_wangping"] = "無當飛將",
["sk_yijian"] = "義諫",
[":sk_yijian"] = "你可以跳過你的出牌階段並令一名其他角色摸一張牌，然後若該角色的手牌數不少於你的手牌數，你回復1點體力。",
["sk_feijun"] = "飛軍",
[":sk_feijun"] = "<font color=\"blue\"><b>鎖定技，</b></font>出牌階段開始時，若你的手牌數不小於你的體力值，本階段你的攻擊範圍+X且可以額外使用一張【殺】(X為你當前體力值)；若你的手牌數少於你的體力值，你不能使用【殺】直到回合結束。 ",
}

--SK黄月英
sk_huangyueying = sgs.General(extension,"sk_huangyueying","shu2",3,false)

--木牛
--木牛FLAG
sk_muniuflag = sgs.CreateTriggerSkill{
	name = "#sk_muniuflag", 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			room:setPlayerFlag(player, "sk_muniu_flag")
		end
		return false
	end
}
sk_huangyueying:addSkill(sk_muniuflag)
--木牛技能	
sk_muniu = sgs.CreateTriggerSkill{
	name = "sk_muniu",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardsMoveOneTime},  
	on_trigger = function(self, event, player, data) 
		if player:hasFlag("sk_muniu_flag") then 
			local room = player:getRoom()
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceEquip then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, "sk_muniu")
					local playerlist = room:getAllPlayers()
					local target = room:askForPlayerChosen(player, playerlist, self:objectName())
					room:doAnimate(1, player:objectName(), target:objectName())
					if target:isKongcheng() or target:objectName()==player:objectName()  then
						room:broadcastSkillInvoke(self:objectName(),2)
						room:drawCards(target, 1, self:objectName())
					else
						local choice = room:askForChoice(player, self:objectName(), "muniu_discard+muniu_draw")
						if choice == "muniu_discard" then
							room:broadcastSkillInvoke(self:objectName(),1)
							local card_id = room:askForCardChosen(player, target, "h", "sk_muniu")
							room:throwCard(card_id, target, player)
						elseif choice == "muniu_draw" then
							room:broadcastSkillInvoke(self:objectName(),2)
							room:drawCards(target, 1, self:objectName())
						end
					end
				end
			end
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.to_place ~= sgs.Player_PlaceEquip then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player, "sk_muniu")
					local playerlist = room:getAllPlayers()
					local target = room:askForPlayerChosen(player, playerlist, self:objectName())
					if target:isKongcheng() or target:objectName()==player:objectName()  then
						room:broadcastSkillInvoke(self:objectName(),2)
						room:drawCards(target, 1, self:objectName())
					else
						local choice = room:askForChoice(player, self:objectName(), "muniu_discard+muniu_draw")
						if choice == "muniu_discard" then
							room:broadcastSkillInvoke(self:objectName(),1)
							local card_id = room:askForCardChosen(player, target, "h", "sk_muniu")
							room:throwCard(card_id, target, player)
						elseif choice == "muniu_draw" then
							room:broadcastSkillInvoke(self:objectName(),2)
							room:drawCards(target, 1, self:objectName())
						end
					end
				end
			end
		end
		return false
	end
}
sk_huangyueying:addSkill(sk_muniu)
extension:insertRelatedSkills("sk_muniu", "#sk_muniuflag")
--流马
sk_liumacard = sgs.CreateSkillCard{
	name = "sk_liumacard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return to_select:getEquips():length() > 0
			end
		elseif #targets == 1 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return to_select:getEquips():length() > 0
			end
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets <= 2 and #targets > 0
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
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, huangyueying:objectName(), 
			"", "sk_yeyan", "")
		room:moveCardTo(self, huangyueying, nil, sgs.Player_DiscardPile, reason, true)
		thread:trigger(sgs.CardUsed, room, huangyueying, data)
		thread:trigger(sgs.CardFinished, room, huangyueying, data)
	end,
	on_use = function(self, room, source, targets)
		if #targets == 1 then
			room:notifySkillInvoked(source, "sk_liuma")
			local target1 = targets[1]
			if target1:isKongcheng() then
				local card_id = room:askForCardChosen(target1, target1, "e", "sk_liuma")
				local others = room:getOtherPlayers(target1)
				local target = room:askForPlayerChosen(target1, others, "sk_liuma")
				room:obtainCard(target, card_id,true)
			else
				local choice = room:askForChoice(target1,  "sk_liuma", "liuma_equip+liuma_hand")
				if choice == "liuma_equip" then
					local card_id = room:askForCardChosen(target1, target1, "e", "sk_liuma")
					local others = room:getOtherPlayers(target1)
					local target = room:askForPlayerChosen(target1, others, "sk_liuma")
					room:obtainCard(target, card_id,true)
				elseif choice == "liuma_hand" then
					if not target1:isKongcheng() then
						local card_id = room:askForCardChosen(target1, target1, "h", "sk_liuma")
						room:obtainCard(source, card_id,false)
					end
				end
			end
		else
			room:notifySkillInvoked(source, "sk_liuma")
			local target1 = targets[1]
			local target2 = targets[2]
			if target1:getEquips():length() > 0 then
				if target1:isKongcheng() then
					local card_id = room:askForCardChosen(target1, target1, "e", "sk_liuma")
					local others = room:getOtherPlayers(target1)
					local target = room:askForPlayerChosen(target1, others,  "sk_liuma")
					room:obtainCard(target, card_id,true)
				else
					local choice = room:askForChoice(target1,  "sk_liuma", "liuma_equip+liuma_hand")
					if choice == "liuma_equip" then
						local card_id = room:askForCardChosen(target1, target1, "e", "sk_liuma")
						local others = room:getOtherPlayers(target1)
						local target = room:askForPlayerChosen(target1, others,  "sk_liuma")
						room:obtainCard(target, card_id,true)
					elseif choice == "liuma_hand" then
						if not target1:isKongcheng() then
							local card_id = room:askForCardChosen(target1, target1, "h", "sk_liuma")
							room:obtainCard(source, card_id,false)
						end
					end
				end
			end
			if target2:getEquips():length() > 0 then
				if target2:isKongcheng() then
					local card_id = room:askForCardChosen(target2, target2, "e", "sk_liuma")
					local others = room:getOtherPlayers(target2)
					local target = room:askForPlayerChosen(target2, others,  "sk_liuma")
					room:obtainCard(target, card_id,true)
				else
					local choice = room:askForChoice(target2,  "sk_liuma", "liuma_equip+liuma_hand")
					if choice == "liuma_equip" then
						local card_id = room:askForCardChosen(target2, target2, "e", "sk_liuma")
						local others = room:getOtherPlayers(target2)
						local target = room:askForPlayerChosen(target2, others,  "sk_liuma")
						room:obtainCard(target, card_id,true)
					elseif choice == "liuma_hand" then
						if not target2:isKongcheng() then
							local card_id = room:askForCardChosen(target2, target2, "h", "sk_liuma")
							room:obtainCard(source, card_id,false)
						end
					end
				end
			else
				if not target2:isKongcheng() then
					local card_id = room:askForCardChosen(target2, target2, "h", "sk_liuma")
					room:obtainCard(source, card_id,false)
				end
			end
		end
		source:removeTag("luasgqskliumatarget")
	end
}
sk_liuma = sgs.CreateViewAsSkill{
	name = "sk_liuma", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card =  sk_liumacard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:isKongcheng() then
			return not player:hasUsed("#sk_liumacard")
		end
		return false
	end
}
sk_huangyueying:addSkill(sk_liuma)

sgs.LoadTranslationTable{
["sk_huangyueying"] = "sk黄月英",
["&sk_huangyueying"] = "黄月英",
["#sk_huangyueying"] = "巧奪天工",
["sk_muniu"] = "木牛",
[":sk_muniu"] = "你的回合内，當任意角色装備區的牌發生一次變動時，你可以選擇一名角色並選擇一項：棄置其一張手牌，或令其摸一張牌。",
["muniu_discard"] = "你棄置其一張手牌",
["muniu_draw"] = "你令其摸一张牌",
["sk_liuma"] = "流馬",
["sk_liumacard"] = "流馬",
[":sk_liuma"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置一張基本牌，然后令至多兩名至少一名装备區有牌的其他角色依次选择一项：將其装備區的一张牌交给一名其他角色，或你獲得其一張手牌。",
["liuma_equip"] = "將你裝備區的一張牌交给一名其他角色",
["liuma_hand"] = "令發起者獲得其一張手牌",
}
--sk馬騰
sk_mateng = sgs.General(extension, "sk_mateng", "qun", "4", true)

--雄異
sk_xiongyi = sgs.CreateTriggerSkill{
	name = "sk_xiongyi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase ==  sgs.Player_Start then
			local room = player:getRoom()
			if player:isKongcheng() then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:drawCards(player, 2, "sk_xiongyi")
			end
			if player:getHp() == 1 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = 1
				theRecover.who = player
				room:recover(player, theRecover)
			end
		end
	end
}

sk_mateng:addSkill(sk_xiongyi)
sk_mateng:addSkill("mashu")

sgs.LoadTranslationTable{
	["sk_mateng"] = "sk馬騰",
	["&sk_mateng"] = "馬騰",
	["#sk_mateng"] = "馳騁西陲",
	["sk_xiongyi"] = "雄異",
	[":sk_xiongyi"] = "鎖定技，回合開始時，若你的體力為1，你恢復一點體力；若你沒有手牌，你可以摸兩張牌",
}
--sk于禁
sk_yujin = sgs.General(extension, "sk_yujin", "wei2", "4", true)
--整毅回合外摸牌效果
sk_zhengyiDraw = sgs.CreateTriggerSkill{
	name = "sk_zhengyiDraw",
	global = true,
	priority = 10,
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self, event, splayer, data, room)
		local card
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			card = use.card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:getSkillName() == "sk_zhengyi" then
			if splayer:getPhase() == sgs.Player_NotActive then
				splayer:drawCards(1)
			end
		end
		return false
	end
}


if not sgs.Sanguosha:getSkill("sk_zhengyiDraw") then skills:append(sk_zhengyiDraw) end

--整毅
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

sk_zhengyiCard = sgs.CreateSkillCard{
	name = "sk_zhengyi",
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
		local card = sgs.Self:getTag("sk_zhengyi"):toCard()
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
		local card = sgs.Self:getTag("sk_zhengyi"):toCard()
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
		local card = sgs.Self:getTag("sk_zhengyi"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_sk_zhengyi = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local sk_zhengyi_list = {}
			table.insert(sk_zhengyi_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(sk_zhengyi_list, "normal_slash")
				table.insert(sk_zhengyi_list, "thunder_slash")
				table.insert(sk_zhengyi_list, "fire_slash")
			end
			to_sk_zhengyi = room:askForChoice(player, "sk_zhengyi_slash", table.concat(sk_zhengyi_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_sk_zhengyi == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_sk_zhengyi == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_sk_zhengyi
		end

		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_sk_zhengyi")
		if self:getSubcards():length() > 0 then
			use_card:addSubcards(self:getSubcards())
		end
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_sk_zhengyi
		if user_str == "peach+analeptic" then
			local sk_zhengyi_list = {}
			table.insert(sk_zhengyi_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(sk_zhengyi_list, "analeptic")
			end
			to_sk_zhengyi = room:askForChoice(user, "sk_zhengyi_saveself", table.concat(sk_zhengyi_list, "+"))
		elseif user_str == "slash" then
			local sk_zhengyi_list = {}
			table.insert(sk_zhengyi_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(sk_zhengyi_list, "normal_slash")
				table.insert(sk_zhengyi_list, "thunder_slash")
				table.insert(sk_zhengyi_list, "fire_slash")
			end
			to_sk_zhengyi = room:askForChoice(user, "sk_zhengyi_slash", table.concat(sk_zhengyi_list, "+"))
		else
			to_sk_zhengyi = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_sk_zhengyi == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_sk_zhengyi == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_sk_zhengyi
		end

		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_sk_zhengyi")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end
}
sk_zhengyi = sgs.CreateViewAsSkill{
	name = "sk_zhengyi",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getPhase() ~= sgs.Player_NotActive and #selected == 0 then
			if sgs.Self:getHandcardNum() == sgs.Self:getHp() + 1 then
				return not to_select:isEquipped()
			elseif sgs.Self:getHandcardNum() == sgs.Self:getHp() then
				return to_select:isEquipped()
			else
				return false
			end
		elseif sgs.Self:getPhase() == sgs.Player_NotActive then
			if sgs.Self:getHandcardNum() == sgs.Self:getHp() - 1 then
				return true
			else
				return false
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if (#cards ~= 1 and sgs.Self:getPhase() ~= sgs.Player_NotActive) or (sgs.Self:getPhase() == sgs.Player_NotActive and (sgs.Self:getHandcardNum() ~= (sgs.Self:getHp() - 1) or #cards ~= 0)) then return nil end
		local skillcard = sk_zhengyiCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE 
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if #cards > 0 then
				skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
				for _, card in ipairs(cards) do
					skillcard:addSubcard(card)
				end
				return skillcard
			end
		end
		local c = sgs.Self:getTag("sk_zhengyi"):toCard()
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
		if (player:getPhase() ~= sgs.Player_NotActive and (player:getHandcardNum() == player:getHp() + 1  or (player:getHandcardNum() == player:getHp() and player:getEquips():length() > 0)))
		or (player:getPhase() == sgs.Player_NotActive and player:getHandcardNum() == player:getHp() - 1 ) then

			for _, patt in ipairs(basic) do
				local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
				if poi and poi:isAvailable(player) and not (patt == "peach" and not player:isWounded()) then
					return true
				end
			end
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if string.startsWith(pattern, ".") or string.startsWith(pattern, "@") then return false end
		if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
		if (player:getPhase() ~= sgs.Player_NotActive and (player:getHandcardNum() == player:getHp() + 1  or (player:getHandcardNum() == player:getHp() and player:getEquips():length() > 0)))
		  or (player:getPhase() == sgs.Player_NotActive and player:getHandcardNum() == player:getHp() - 1 ) then
			return pattern ~= "nullification"
		end
		return false
	end
}
sk_zhengyi:setGuhuoDialog("l")

sk_yujin:addSkill(sk_zhengyi)

sgs.LoadTranslationTable{
	["sk_yujin"] = "sk于禁",
	["&sk_yujin"] = "于禁",
	["#sk_yujin"] = "弗克其終",
	["sk_zhengyi"] = "整毅",
	["_sk_zhengyi"] = "整毅",
	[":sk_zhengyi"] = "你的回合內，你可以棄置一張牌，使你的手牌數等於體力值，視為使用一張基本牌；你的回合外，你可以摸一張牌，使你的手牌數等於體力值，視為使用一張基本牌",
}
--sk張布
sk_zhangbu = sgs.General(extension, "sk_zhangbu", "wu2", 3, true)
--朝臣
sk_chaochenCard = sgs.CreateSkillCard{
	name = "sk_chaochenCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getMark("@skchaocheng") == 0)
	end,
	on_use = function(self, room, source, targets)	
			
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "sk_chaochen","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		room:setPlayerMark(targets[1], "@skchaocheng",1)
		room:setPlayerMark(targets[1], "skchaocheng"..source:objectName()..targets[1]:objectName(),1)
	end
}

sk_chaochenVS = sgs.CreateViewAsSkill{
	name = "sk_chaochen",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		return (not to_select:isEquipped())
	end ,
	view_as = function(self,cards)
		if #cards == 0 then return nil end
		local card = sk_chaochenCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_chaochenCard") < 1 
	end
}

sk_chaochen = sgs.CreateTriggerSkill{
	name = "sk_chaochen" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = sk_chaochenVS,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark("@skchaocheng") > 0 and player:getMark("skchaocheng"..p:objectName()..player:objectName()) > 0 and p:hasSkill("sk_chaochen") then
					if player:getHandcardNum() > player:getHp() then
						room:doAnimate(1, p:objectName(), player:objectName())
						local damage = sgs.DamageStruct()
						damage.from = p
						damage.reason = "sk_chaochen"
						damage.damage = 1
						damage.nature = sgs.DamageStruct_Normal
						damage.to = player
						room:damage(damage)
					end
					room:setPlayerMark(player, "@skchaocheng",0)
					room:setPlayerMark(player, "skchaocheng"..p:objectName()..player:objectName(),0)
				end
			end
		end
		return false
	end
}
sk_quanzheng = sgs.CreateTriggerSkill{
	name = "sk_quanzheng" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if use.from:getHandcardNum() > player:getHandcardNum() or
					 use.from:getEquips():length() > player:getEquips():length() then
						if room:askForSkillInvoke(player, self:objectName(), data) then
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

sk_zhangbu:addSkill(sk_chaochen)
sk_zhangbu:addSkill(sk_quanzheng)
sgs.LoadTranslationTable{
	["sk_zhangbu"] = "sk張布",
	["&sk_zhangbu"] = "張布",
	["#sk_zhangbu"] = "養癰貽患",
		["sk_chaochen"] = "朝臣",
		[":sk_chaochen"] = "出牌階段限一次，你可以交給一名角色任意數量的手牌。該角色的出牌階段開始時，若其手牌數大於其體力值，你對其造成一點傷害。",
		["sk_quanzheng"] = "全政",
		[":sk_quanzheng"] = "當你成為「殺」或非延時類錦囊牌的目標時，若你的手牌數或裝備區的牌數小於使用者的對應區域時，你摸一張牌",
}
--sk華雄
sk_huaxiong = sgs.General(extension, "sk_huaxiong", "qun", "5", true)
--奮威
sk_fenwei = sgs.CreateTriggerSkill{
	name = "sk_fenwei", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local card = damage.card
		if damage.card and damage.card:isKindOf("Slash") and damage.to:isKongcheng() then
			local _data = sgs.QVariant()
			_data:setValue(damage.to)
			if room:askForSkillInvoke(player, "sk_fenwei", _data) then
				room:broadcastSkillInvoke(self:objectName())
				local card = damage.to:getRandomHandCard()
				room:showCard(damage.to, card:getEffectiveId())
				if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
					player:obtainCard(card)
				else
					room:throwCard(card, damage.to, player)
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
					msg.type = "#Fenwei"
					msg.from = player
					msg.to:append(damage.to)
					msg.arg = tostring(damage.damage-1)
					msg.arg2 = tostring(damage.damage)
					room:sendLog(msg)						
					data:setValue(damage)
				end
			end
		end		
		return false
	end
}
sk_huaxiong:addSkill(sk_fenwei)
sk_huaxiong:addSkill("shiyong")
sgs.LoadTranslationTable{
	["sk_huaxiong"] = "sk華雄",
	["&sk_huaxiong"] = "華雄",
	["#sk_huaxiong"] = "魔將",
	["sk_fenwei"] = "奮威",
	[":sk_fenwei"] = "當你使用「殺」對一名角色造成傷害後，你可以展示該角色的一張手牌，若為「桃」或「酒」則你獲得之；若不為「桃」或「酒」，該「殺」傷害+1",
	["#Fenwei"] = "%from 發動了技能“<font color=\"yellow\"><b>奮威</b></font>”，對 %to 造成傷害由 %arg 點增加到"..
" %arg2 點",
}
--張任
sk_zhangren = sgs.General(extension, "sk_zhangren", "qun", "4", true)
--伏射

sk_fushe = sgs.CreateTriggerSkill{
	name = "sk_fushe" ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then 
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:inMyAttackRange(player) and p:hasSkill("sk_fushe") then
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForSkillInvoke(p, "sk_fushe", _data) then
							local choosesuit = room:askForSuit(p, "sk_fushe")
							room:setPlayerMark(player, "sk_fushe"..p:objectName()..choosesuit.."_Play", 1)
							local msg = sgs.LogMessage()
							msg.type = "#fushe"
							msg.from = p
							msg.to:append(player)
							msg.arg = sgs.Card_Suit2String(choosesuit)
							room:sendLog(msg)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then 
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("sk_fushe") and player:getMark("skfushe"..p:objectName().."success_Play") > 0 then

						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						room:doAnimate(1, p:objectName(), player:objectName())
						local damage2 = sgs.DamageStruct()
						damage2.from = p
						damage2.to = player
						damage2.damage = 1
						damage2.nature = sgs.DamageStruct_Normal
						room:damage(damage2)
						p:drawCards(1, self:objectName())
					end
				end
			end
		end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local ids = move.card_ids
			if move.to_place ~= sgs.Player_DiscardPile then return false end
			if player:getPhase() ~= sgs.Player_Play then return false end
			
			for _, id in sgs.qlist(move.card_ids) do
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("sk_fushe"..p:objectName()..sgs.Sanguosha:getCard(id):getSuit().."_Play") > 0 then
						room:setPlayerMark(player, "skfushe"..p:objectName().."success_Play", 1)
					end
				end
			end
		end
		return false
	end
}

sk_zhangren:addSkill(sk_fushe)
sgs.LoadTranslationTable{
	["sk_zhangren"] = "sk張任",
	["&sk_zhangren"] = "張任",
	["#sk_zhangren"] = "索命神射",
	["sk_fushe"] = "伏射",
	[":sk_fushe"] = "當一名在你攻擊範圍的的角色的出牌階段開始時，你可以選定一種花色，若本階段有該花色的牌進入棄牌堆，你對其造成一點傷害，然後摸一張牌",
	["sgs.Card_Spadetext"] = "黑桃",
	["sgs.Card_Diamondtext"] = "方塊",
	["sgs.Card_Clubtext"] = "梅花",
	["sgs.Card_Hearttext"] = "紅桃",
	["#fushe"] = "%from 對 %to 發動了技能 “<font color=\"yellow\"><b>伏射</b></font>”，選擇花色為：%arg "
}
--張寧
sk_zhangning = sgs.General(extension, "sk_zhangning", "qun", "3", false)
--雷祭
sk_leiji = sgs.CreateTriggerSkill{
	name = "sk_leiji",
	events = {sgs.CardResponded},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card_star = data:toCardResponse().m_card
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			local _targets = sgs.SPlayerList()
			if card_star:isKindOf("Jink") then
				for _, p in sgs.qlist(room:getOtherPlayers(p)) do
					if p:isAlive() and (not p:containsTrick("lightning")) then
						 _targets:append(p)
					 end
				end
				local lightningcard
				if room:getDrawPile():length() > 0 then
					for _, id in sgs.qlist(room:getDrawPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("Lightning") then
							lightningcard = card
							break
						end
					end
				end
				if room:getDiscardPile():length() > 0 then
					for _, id in sgs.qlist(room:getDiscardPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("Lightning") then
							lightningcard = card
							break
						end
					end
				end


				if lightningcard and not _targets:isEmpty() then
					local s = room:askForPlayerChosen(p, _targets, "sk_leiji", "@sk_leiji-discard", true)
					if s then
						if s:containsTrick("lightning") then return false end
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						room:doAnimate(1, p:objectName(), s:objectName())
						room:moveCardTo(lightningcard, s, sgs.Player_PlaceDelayedTrick, false)
					end
				end
			end
		end
	end
}
sk_shanxi = sgs.CreateTriggerSkill{
	name = "sk_shanxi" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.FinishJudge} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if judge.reason == "lightning" and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local card = judge.card
				room:doAnimate(1, player:objectName(), p:objectName())
				p:obtainCard(card)  
			end
		end
		return false
	end
}
sk_shanxiPs = sgs.CreateProhibitSkill{
	name = "#sk_shanxiPs",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("sk_shanxi") and (card:isKindOf("Lightning"))
	end
}
sk_zhangning:addSkill(sk_leiji)
sk_zhangning:addSkill(sk_shanxi)
sk_zhangning:addSkill(sk_shanxiPs)
extension:insertRelatedSkills("sk_shanxi","#sk_shanxiPs")

sgs.LoadTranslationTable{
	["sk_zhangning"] = "sk張寧",
	["&sk_zhangning"] = "張寧",
	["#sk_zhangning"] = "鬼電魅娘",
		["sk_leiji"] = "雷祭",
		[":sk_leiji"] = "每當一名角色使用「閃」時，你可以將一張「閃電」置入一名角色的判定區",
	["sk_shanxi"] = "閃戲",
	[":sk_shanxi"] = "鎖定技，你不會成為「閃電」的目標，「閃電」的判定牌生效後，你獲得之",
	["@sk_leiji-discard"]= "你要將「閃電」置入誰的判定區？",
}
--sk祖茂
sk_zumao = sgs.General(extension, "sk_zumao", "wu2", "4", true)
sk_yinbing = sgs.CreateTriggerSkill{
	name = "sk_yinbing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.from:objectName() ~= p:objectName() and use.to:contains(player) and player:objectName() ~= p:objectName() and 
					  p:inMyAttackRange(player) and player:getEquips():length() > 0 and p:hasSkill("sk_yinbing") then
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForSkillInvoke(p, self:objectName(), _data) then
							room:doAnimate(1, p:objectName(), player:objectName())		
							local id = room:askForCardChosen(p, player, "e", "sk_yinbing") 
							room:obtainCard(p, id, true)				
							room:notifySkillInvoked(p, "sk_yinbing")
							room:broadcastSkillInvoke("sk_yinbing", 1)
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
						end
					end
				end
			end
		elseif event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if (not player:isNude()) and player:hasSkill("sk_yinbing") and use.card:isKindOf("Slash") then
				local n = player:getLostHp()
				local card = room:askForCard(player, ".,Equip", "@zm_yinbin-card:::" .. tostring(n), sgs.QVariant(), sgs.CardDiscarded)
				if card then
					room:broadcastSkillInvoke("sk_yinbing", 2)
					room:drawCards(player, n, "sk_yinbing")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

sk_zumao:addSkill(sk_yinbing)

sgs.LoadTranslationTable{
	["sk_zumao"] = "sk祖茂",
	["&sk_zumao"] = "祖茂",
	["#sk_zumao"] = "血路先驅",
		["sk_yinbing"] = "引兵",
		[":sk_yinbing"] = "你攻擊範圍內的一名其他角色成為【殺】的目標時，你可以獲得其裝備區的一張牌，然後將該【殺】轉移給你（你不得是此【殺】的使用者）；當你成為【殺】的目標時，你可以棄置一張牌，然後摸X張牌（X為你已損失的體力值）。",
	["@zm_yinbin-card"] = "你可以棄一張牌，然後摸 %arg 張牌。",
}
--sk董允
sk_dongyun = sgs.General(extension, "sk_dongyun", "shu2", "3", true)
--裨補
sk_bibu = sgs.CreateTriggerSkill{
	name = "sk_bibu",
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ==  sgs.Player_Finish then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("sk_bibu") then
					if p:getHandcardNum() > p:getHp() then
						if room:askForYiji(p, p:handCards(), self:objectName(), false, false, true, 1, sgs.SPlayerList(), sgs.CardMoveReason(), "@sk_bibu", true) then
							room:broadcastSkillInvoke(self:objectName(),1)
						end
					else
						if room:askForSkillInvoke(p, "sk_bibu", data) then
							room:broadcastSkillInvoke(self:objectName(),2)
							room:drawCards(p, 1, "sk_bibu")
						end
					end
				end
			end
		end
		return false
	end,
}
--匡正
sk_kuangzheng = sgs.CreateTriggerSkill{
	name = "sk_kuangzheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local phase = change.to
		if phase ==  sgs.Player_Finish then
			local room = player:getRoom()
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "sk_kuangzheng", "@sk_kuangzheng-choose", true)
			if s then
				room:broadcastSkillInvoke(self:objectName())
				if s:isChained() then
					room:setPlayerProperty(s, "chained", sgs.QVariant(false))
				end
				if not s:faceUp() then
					s:turnOver()
				end
			end
		end
	end
}
sk_dongyun:addSkill(sk_bibu)
sk_dongyun:addSkill(sk_kuangzheng)

sgs.LoadTranslationTable{
	["sk_dongyun"] = "sk董允",
	["&sk_dongyun"] = "董允",
	["#sk_dongyun"] = "秉正匡主",
	["sk_bibu"] = "裨補",
	[":sk_bibu"] = "其他角色的回合結束時，若你的手牌數大於體力值，你可以將一張手牌交給其他角色；若你的手牌數不大於體力值，你可以摸一張牌",
	["sk_kuangzheng"] = "匡正",
	[":sk_kuangzheng"] = "你的回合結束時，你可以令一名角色將武將牌重置",
	["@sk_kuangzheng-choose"] = "請選擇一名角色，你令其將武將牌重置",
	["@sk_bibu"] = "你可以將一張手牌交給其他角色",
}
--sk楊修
sk_yangxiu = sgs.General(extension, "sk_yangxiu", "wei2", "3", true)
--才捷
sk_caijie = sgs.CreateTriggerSkill{
	name = "sk_caijie" ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if not p or p:objectName() == player:objectName() then return false end
			if (p:isKongcheng() or player:isKongcheng()) then return false end
			local _data = sgs.QVariant()
			_data:setValue(player)
			if room:askForSkillInvoke(p, "sk_caijie", _data) then
				room:broadcastSkillInvoke(self:objectName())
				local success = p:pindian(player, "sk_caijie", nil)
				if success then
					room:drawCards(p, 2, "sk_caijie")
				else
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("sk_caijie")
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = player
					local dest = p
					use.to:append(dest)
					room:useCard(use)
				end
			end
		end
		return false
	end
}
--雞肋
sk_jile = sgs.CreateMasochismSkill{
	name = "sk_jile" ,
	on_damaged = function(self, target, damage)
		local room = target:getRoom()
		if damage.from and (not damage.from:isKongcheng()) then
			local data = sgs.QVariant()
			data:setValue(damage.from)
			if room:askForSkillInvoke(target, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:showAllCards(damage.from)
				local choices = {}

				local n1 = 0
				local n2 = 0
				local n3 = 0
				local cards = damage.from:getHandcards()
				for _, card in sgs.qlist(cards) do
					if card:isKindOf("BasicCard") then
						n1 = n1 + 1
					end
					if card:isKindOf("TrickCard") then
						n2 = n2 + 1
					end
					if card:isKindOf("EquipCard") then
						n3 = n3 + 1
					end
				end
				if n1 == math.max(n1,n2,n3) then
					table.insert(choices, "BasicCard")
				end
				if n2 == math.max(n1,n2,n3) then
					table.insert(choices, "TrickCard")
				end
				if n3 == math.max(n1,n2,n3) then
					table.insert(choices, "EquipCard")
				end

				local choice = room:askForChoice(target, "sk_jile", table.concat(choices, "+"))
				local ids = sgs.IntList()
				for _, card in sgs.qlist(cards) do
					if choice == "BasicCard" then
						if card:isKindOf("BasicCard") then
							ids:append(card:getEffectiveId())
						end
					end 
					if choice == "TrickCard" then
						if card:isKindOf("TrickCard") then
							ids:append(card:getEffectiveId())
						end
					end 
					if choice == "EquipCard" then
						if card:isKindOf("EquipCard") then
							ids:append(card:getEffectiveId())
						end
					end 
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, target:objectName(), nil, "sk_jile", nil)
				room:moveCardsAtomic(move, true)
			end
		end
	end
}

sk_yangxiu:addSkill(sk_caijie)
sk_yangxiu:addSkill(sk_jile)
sgs.LoadTranslationTable{
	["sk_yangxiu"] = "sk楊修",
	["&sk_yangxiu"] = "楊修",
	["#sk_yangxiu"] = "恃才放曠",
	["sk_caijie"] = "才捷",
	[":sk_caijie"] = "一名角色的回合開始時，你可以與該角色拼點，若你贏，你摸兩張牌，若你沒贏，視為其對你使用一張「殺」",
	["sk_jile"] = "雞肋",
	[":sk_jile"] = "當你受到傷害時，你可以令其展示其手牌，然後棄置一種類型的所有牌",
}
--SK賀齊
sk_heqi = sgs.General(extension,"sk_heqi","wu2","4",true)
--送嶂
function RIGHT(self, player)
	if player and player:isAlive() and player:hasSkill(self:objectName()) then
		return true
	else
		return false
	end
end

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

sk_songzhang = sgs.CreateTriggerSkill{
	name = "sk_songzhang",
	global = true,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed or event == sgs.CardResponded then
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
				if player:hasSkill("sk_songzhang") and player:getMark("used_Play") > 1 and player:getPhase() == sgs.Player_Play then
					local log = sgs.LogMessage()
					log.from = player
					log.arg = fakeNumber(player:getMark(self:objectName().."_Play")) .. " -> " .. fakeNumber(num)
					log.arg2 = self:objectName()
					if player:hasSkill("sk_songzhang") then
						if num > player:getMark(self:objectName().."_Play") then
							log.type = "#sk_songzhang_success_1"
							room:broadcastSkillInvoke(self:objectName())
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								player:drawCards(1, self:objectName())
								room:removePlayerMark(player, self:objectName().."engine")
							end
						end
					end
					room:sendLog(log)
				end
				if num > 0 and num < 14 then
					room:setPlayerMark(player, self:objectName().."_Play", num)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

sk_heqi:addSkill(sk_songzhang)
sgs.LoadTranslationTable{
	["sk_heqi"] = "sk賀齊",
	["&sk_heqi"] = "賀齊",
	["#sk_heqi"] = "綏靜邦域",
	["sk_songzhang"] = "送嶂",
	[":sk_songzhang"] = "出牌階段，當你使用牌時，若此牌的點數大於你本回合上一張牌使用的牌，你可以摸一張牌",
	["#sk_songzhang_success_1"] = "%from 使用的牌點數變化： %arg ，符合遞增，“%arg2”被觸發",
}

--sk步騭
sk_buzhi = sgs.General(extension, "sk_buzhi", "wu2", "3", true)
--折節
sk_zhejie = sgs.CreateTriggerSkill{
	name = "sk_zhejie" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _,s in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if s and s:objectName() ~= player:objectName() and not s:isNude() then 
						local card2 = room:askForCard(s, ".,Equip", "@sk_zhejie-throw:"..player:objectName(), sgs.QVariant(), sgs.CardDiscarded)	
						if card2 then
							room:broadcastSkillInvoke(self:objectName())
							local cards = room:askForExchange(player, self:objectName(), 1, 1, true, "@disOne")
							if cards then
								room:throwCard(cards, player,player)
								local cd = cards:getSubcards():first()
								if sgs.Sanguosha:getCard(cd):isKindOf("EquipCard") and (room:getCardPlace(cd) == sgs.Player_DiscardPile or room:getCardPlace(cd) == sgs.Player_PlaceTable)  then
								--if cd:isKindOf("EquipCard") and (room:getCardPlace(cd) == sgs.Player_DiscardPile or room:getCardPlace(cd) == sgs.Player_PlaceTable)  then
									local q = room:askForPlayerChosen(s, room:getAlivePlayers(), "sk_zhejie", "@sk_zhejiechoose:"..sgs.Sanguosha:getCard(cd):objectName(), true)
									if q then
										room:doAnimate(1, s:objectName(), q:objectName())
										room:obtainCard(q,cd, true)
									end
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
sk_fengya = sgs.CreateTriggerSkill{
	name = "sk_fengya",
	events = {sgs.DamageForseen},
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, "sk_fengya", data) then
			room:broadcastSkillInvoke(self:objectName())
			room:drawCards(player, 1, "sk_fengya")
			room:setPlayerFlag(player,"strfengyatarget")
			local choices = {"fengya_draw", "cancel"}
			local choice = room:askForChoice(damage.from, "sk_fengya", table.concat(choices, "+"))
			if choice == "fengya_draw" then
				room:drawCards(damage.from, 1, "sk_fengya")
				local msg = sgs.LogMessage()
				msg.type = "#Fengya"
				msg.from = damage.from
				msg.to:append(player)
				msg.arg = tostring(damage.damage)
				msg.arg2 = tostring(damage.damage - 1)
				room:sendLog(msg)
				if damage.damage > 1 then
					damage.damage = damage.damage - 1
					data:setValue(damage)
				else
					return true
				end		
			end
			room:setPlayerFlag(player,"-strfengyatarget")
		end
		return false
	end,
}

sk_buzhi:addSkill(sk_zhejie)
sk_buzhi:addSkill(sk_fengya)
sgs.LoadTranslationTable{
	["sk_buzhi"] = "sk步騭",
	["&sk_buzhi"] = "步騭",
	["#sk_buzhi"] = "寬宏儒雅",
	["sk_zhejie"] = "折節",
	["sk_fengya"] = "風雅",
	[":sk_zhejie"] = "其他角色的棄牌階段結束時，你可以棄一張牌，令其棄一張牌。若其棄置的牌為裝備牌，你交給一名角色",
	[":sk_fengya"] = "當你受到傷害時，傷害來源可以摸一張牌，然後令傷害-1",
	["fengya_draw"] = "摸一張牌，並令傷害-1",
	["@sk_zhejie-throw"] = "你可以棄一張牌，令 %src 棄一張牌。若其棄置的牌為裝備牌，你交給一名角色",
	["@sk_zhejiechoose"] = "你可以令一名角色獲得 %src ",
	["#Fengya"] = "%from 發動了 %to 的技能 “<font color=\"yellow\"><b>風雅</b></font>”，對 %to 造成的傷害由 %arg 點減少至 %arg2 點",
}

--SK諸葛瑾
sk_zhugejin = sgs.General(extension,"sk_zhugejin","wu2","3",true)
--緩兵
sk_huanbing = sgs.CreateTriggerSkill{
	name = "sk_huanbing" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed,sgs.EventPhaseStart,sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") then
					room:broadcastSkillInvoke(self:objectName())
					player:setFlags("-hunbianTarget")
					player:setFlags("hunbianTarget")
					player:addToPile("sk_slash", use.card)
					if player:isAlive() and player:hasFlag("hunbianTarget") then
						player:setFlags("-hunbianTarget")
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			while (not player:getPile("sk_slash"):isEmpty() and player:isAlive()) do
				local ids = player:getPile("sk_slash")
				local id = ids:at(0)
				local card = sgs.Sanguosha:getCard(id)
				local data = sgs.QVariant()
				local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.pattern =  ".|red"
				judge.good = true
				judge.who = player
				room:judge(judge)
				if judge:isGood() then
					room:drawCards(player, 1)
					room:moveCardTo(card, nil, sgs.Player_DiscardPile, false)
				else
					room:loseHp(player)
					room:obtainCard(player, card)
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(player:getPile("sk_slash"))
				room:throward( dummy,player,player)
			end
		end
	end,
}

--弘援
sk_hongyuanCard = sgs.CreateSkillCard{
	name = "sk_hongyuan" ,
	filter = function(self, targets, to_select)
		return #targets == 0
	end ,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local ids = sgs.IntList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				for _, card in sgs.qlist(p:getCards("ej")) do
					ids:append(card:getId())
				end
			end
			room:fillAG(ids)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local t = 0
			for i = 1, source:getLostHp() do
				local id = room:askForAG(source, ids, i ~= 1, self:objectName())
				if id == -1 then break end
				ids:removeOne(id)

				dummy:addSubcard(id)
				room:takeAG(source, id, false)
				t = i
				if ids:isEmpty() then break end
			end
			room:clearAG()
			if dummy:subcardsLength() > 0 and targets[1]:isAlive() then
				targets[1]:obtainCard(dummy)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}

sk_hongyuan = sgs.CreateViewAsSkill{
	name = "sk_hongyuan", 
	n = 99, 
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards) 
		local n = sgs.Self:getLostHp()
		if #cards < n then
			local card = sk_hongyuanCard:clone()
			for _,acard in ipairs(cards) do
				card:addSubcard(acard)
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getLostHp() > 0 and not player:hasUsed("#sk_hongyuanCard")
	end
}

sk_zhugejin:addSkill(sk_huanbing)
sk_zhugejin:addSkill(sk_hongyuan)
sgs.LoadTranslationTable{
	["sk_zhugejin"] = "sk諸葛瑾",
	["&sk_zhugejin"] = "諸葛瑾",
	["#sk_zhugejin"] = "聯盟維繫者",
	["sk_huanbing"] = "緩兵",
	[":sk_huanbing"] = "鎖定技，當你成為「殺」的目標時，終止此「殺」的結算；改為將之置於你的武將牌上。回合開始時，你須為你的的武將牌上每一張「殺」進行一次判定，若結果為紅色，你摸一張牌；若結果為黑色，你須先失去一點體力，然後將此「殺」收入手牌",
	["sk_slash"] = "殺",
	["sk_hongyuan"] = "弘援",
	["@sk_hongyuan"] = "請選擇一名角色",
	[":sk_hongyuan"] = "出牌階段限一次，你可以棄置至多X張牌，然後選擇一名角色令其獲得場上的X張牌(X為你失去的體力值)",
}


--SK鄧芝
sk_dengzhi = sgs.General(extension,"sk_dengzhi","shu2","3",true)
--和盟：出牌階段，若你有手牌，可令一名其他角色觀看你的手牌並獲得其中一張，然後你觀看該角色的手牌並獲得其一張牌。每階段限（X+1）次，X為你此階段開始時已損失的體力值。
sk_hemengCard = sgs.CreateSkillCard{
	name = "sk_hemengCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0)
	end,
	on_use = function(self, room, source, targets)
		local ids2 = sgs.IntList()
		for _, card in sgs.qlist(source:getHandcards()) do
			ids2:append(card:getEffectiveId())
		end
		local card_id2 = room:doGongxin(targets[1], source, ids2)
		if (card_id2 == -1) then return end
		if ids2:length() > 0 then
			room:obtainCard(targets[1], sgs.Sanguosha:getCard(card_id2), false)
		end
		-- 	
		room:setTag("Dongchaee",sgs.QVariant(targets[1]:objectName()))
		room:setTag("Dongchaer",sgs.QVariant(source:objectName()))
		local id = room:askForCardChosen(source, targets[1], "he", "sk_hemeng", false)
		room:obtainCard(source, id, false)
		room:setTag("Dongchaee",sgs.QVariant())
		room:setTag("Dongchaer",sgs.QVariant())
		--
	end
}

sk_hemeng = sgs.CreateZeroCardViewAsSkill{
	name = "sk_hemeng",
	view_as = function(self,cards)
		return sk_hemengCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_hemengCard") < player:getLostHp()+1 and not player:isKongcheng()
	end
}

--素檢：每當你從其他角色處獲得一次牌時，可令一名其他角色棄置你一張牌，然後你棄置其一張牌。
sk_sujian = sgs.CreateTriggerSkill{
	name = "sk_sujian" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and (move.to:objectName() == player:objectName()) and move.from and move.from:isAlive()
					and (move.from:objectName() ~= move.to:objectName())
					and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
				if player:isNude() then return false end
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getPlayers()) do
					if (not p:isNude()) then _targets:append(p) end
				end
				if not _targets:isEmpty() then
					local invoke = room:askForSkillInvoke(player, self:objectName(), data)
					if invoke then
						local s = room:askForPlayerChosen(player,_targets,self:objectName(),"@sk_hemeng",true,true)
						if s then
							room:broadcastSkillInvoke("sk_sujian")
							local id2 = room:askForCardChosen(s, player, "he", "sk_hemeng") 
							room:throwCard(id2, player, s)
							local id = room:askForCardChosen(player, s, "he", "sk_hemeng") 
							room:throwCard(id, s, player)
						end
					end
				end
			end
		end
		--return false
	end
}
sk_dengzhi:addSkill(sk_hemeng)
sk_dengzhi:addSkill(sk_sujian)

sgs.LoadTranslationTable{
	["sk_dengzhi"] = "sk鄧芝",
	["&sk_dengzhi"] = "鄧芝",
	["#sk_dengzhi"] = "堅貞簡亮",
	["sk_sujian"] = "素檢",
	[":sk_sujian"] = "每當你從其他角色處獲得一次牌時，可令一名其他角色棄置你一張牌，然後你棄置其一張牌",
	["sk_hemeng"] = "和盟",
	[":sk_hemeng"] = "出牌階段，若你有手牌，可令一名其他角色觀看你的手牌並獲得其中一張，然後你觀看該角色的手牌並獲得其一張牌。每階段限（X+1）次，X為你此階段開始時已損失的體力值。",
	["@sk_hemeng"] = "你可令一名其他角色棄置你一張牌，然後你棄置其一張牌",
}
--sk王異
sk_wangyi = sgs.General(extension,"sk_wangyi","wei2","3",false)
--貞烈:當你成為其他角色使用的【殺】或非延時錦囊牌的目標後，你可以失去1點體力，令此牌對你無效，然後可棄置一張牌，令該角色展示所有手牌並棄置其中與之花色相同的牌。若其沒有因此棄置牌，其失去1點體力。
sk_zhenlie = sgs.CreateTriggerSkill{
	name = "sk_zhenlie" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:setFlags("-ZhenlieTarget")
						player:setFlags("ZhenlieTarget")
						room:loseHp(player)
						if player:isAlive() and player:hasFlag("ZhenlieTarget") then
							player:setFlags("-ZhenlieTarget")
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
							if player:canDiscard(player, "he") then
								local id = room:askForCard(player, ".,Equip", "@sk_zhenlie", sgs.QVariant(), sgs.CardDiscarded)
								if id then
									room:showAllCards(use.from)
									local cards = use.from:getHandcards()
									local ids = sgs.IntList()
									for _, card in sgs.qlist(cards) do
										if card:getSuit() == id:getSuit() then
											ids:append(card:getEffectiveId())
										end
									end
									if ids:length() > 0 then
										local move = sgs.CardsMoveStruct()
										move.card_ids = ids
										move.to = nil
										move.to_place = sgs.Player_DiscardPile
										move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "sk_zhenlie", nil)
										room:moveCardsAtomic(move, true)
									else
										local msg = sgs.LogMessage()
										msg.type = "#Zhenlie2"
										msg.from = player
										msg.to:append(use.from)
										room:sendLog(msg)
										room:loseHp(use.from)
									end
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
--秘計:回合開始階段開始時，若你已受傷，你可以聲明一種牌的類別，然後從牌堆隨機亮出一張此類別的牌，將之交給一名角色。回合結束階段開始時，若你的體力為全場最少（或之一），你亦可以如此做。
sk_miji = sgs.CreateTriggerSkill{
	name = "sk_miji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local phase = change.to
		local room = player:getRoom()
		local can_invoke = true
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:getHp() > p:getHp() then
				can_invoke = false
				break
			end
		end
		if (phase ==  sgs.Player_Start and player:isWounded()) or (phase == sgs.Player_Finish and can_invoke) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local choices = {"TrickCard", "BasicCard", "EquipCard"}
				local choice = room:askForChoice(player, "sk_miji", table.concat(choices, "+"))
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
					room:showCard(player, get_id)
					local s = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"@sk_mijimoveto:"..getcard:objectName(),true,true)
					if s then
						room:obtainCard(s, getcard)
					end
				end
			end
		end
	end
}

sk_wangyi:addSkill(sk_zhenlie)
sk_wangyi:addSkill(sk_miji)

sgs.LoadTranslationTable{
	["sk_wangyi"] = "sk王異",
	["&sk_wangyi"] = "王異",
	["#sk_wangyi"] = "決意的巾幗",
	["sk_zhenlie"] = "貞烈",
	[":sk_zhenlie"] = "當你成為其他角色使用的【殺】或非延時錦囊牌的目標後，你可以失去1點體力，令此牌對你無效，然後可棄置一張牌，令該角色展示所有手牌並棄置其中與之花色相同的牌。若其沒有因此棄置牌，其失去1點體力。",
	["@sk_zhenlie"] = "你可以棄置一張牌，令該角色展示所有手牌並棄置其中與之花色相同的牌。若其沒有因此棄置牌，其失去1點體力。",
	["$sk_zhenlie"] = "看看我的覺悟吧!",
	["sk_miji"] = "秘計",
	[":sk_miji"] = "回合開始階段開始時，若你已受傷，你可以聲明一種牌的類別，然後從牌堆隨機亮出一張此類別的牌，將之交給一名角色。回合結束階段開始時，若你的體力為全場最少（或之一），你亦可以如此做。",
	["$sk_miji"] = "我將盡我所能。",
	["#Zhenlie2"] = "%from 發動了技能 “<font color=\"yellow\"><b>貞烈</b></font>”， %to 失去了一點體力",
	["@sk_mijimoveto"] = "你可以令一名角色獲得 %src ",
	["~sk_wangyi"] = "我 絕不屈服！",
}
--sk管輅
sk_guanlu = sgs.General(extension,"sk_guanlu","wei2",3, true)
--縱情:摸牌階段開始時，你可以進行一次判定，若如此做，此階段摸牌後你須展示之，然後棄置其中與該判定牌顏色不同的牌。若以此法棄置的牌為黑色，視為你使用一張【酒】；若以此法棄置的牌為紅色，視為你使用一張【桃】。
sk_zongqing = sgs.CreateTriggerSkill{
	name = "sk_zongqing",
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
					room:setPlayerFlag(player, "-zongching_red")
					room:setPlayerFlag(player, "-zongching_black")
				if room:askForSkillInvoke(player, "sk_zongqing", data) then
					local judge = sgs.JudgeStruct()
					judge.pattern =  "."
					judge.play_animation = false
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					local card = judge.card
					room:setPlayerFlag(player, "sk_zongching")
					if card:isRed() then
						room:setPlayerFlag(player, "-zongching_black")
						room:setPlayerFlag(player, "zongching_red")
					elseif card:isBlack() then
						room:setPlayerFlag(player, "-zongching_red")
						room:setPlayerFlag(player, "zongching_black")
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			if player:getPhase() == sgs.Player_Draw then 
				local move = data:toMoveOneTime()
				local ids = move.card_ids
				if ids:isEmpty() then return false end
				if player:hasFlag("sk_zongching") and move.to:objectName() == player:objectName() then
					local red = sgs.IntList()
					local black = sgs.IntList()
					local card_ids = sgs.IntList()
					for _,id in sgs.qlist(ids) do
						card_ids:append(id)
						if sgs.Sanguosha:getCard(id):isRed() then 
							red:append(id)
						elseif sgs.Sanguosha:getCard(id):isBlack() then 
							black:append(id)
						end
					end
					room:fillAG(card_ids)
					room:getThread():delay()
					room:clearAG()
					if player:hasFlag("zongching_red") and not black:isEmpty() then
						room:broadcastSkillInvoke(self:objectName(), 2)
						local move2 = sgs.CardsMoveStruct()
						move2.card_ids = black
						move2.to = nil
						move2.to_place = sgs.Player_DiscardPile
						move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE,player:objectName(), nil, "sk_zongqing")
						room:moveCardsAtomic(move2, true)

						local duel = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
						duel:setSkillName("sk_zongqing_audio")
						local use = sgs.CardUseStruct()
						use.card = duel
						use.from = player
						room:useCard(use)
					
					elseif player:hasFlag("zongching_black") and not red:isEmpty() then
						room:broadcastSkillInvoke(self:objectName(), 1)
						local move2 = sgs.CardsMoveStruct()
						move2.card_ids = red
						move2.to = nil
						move2.to_place = sgs.Player_DiscardPile
						move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE,player:objectName(), nil, "sk_zongqing")
						room:moveCardsAtomic(move2, true)

						local duel = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
						duel:setSkillName("sk_zongqing_audio")
						local use = sgs.CardUseStruct()
						use.card = duel
						use.from = player
						room:useCard(use)
					else
						return false
					end
				end
			end
		end
	end,
}
--卜卦
sk_bugua = sgs.CreateTriggerSkill{
	name = "sk_bugua" ,
	events = {sgs.AskForRetrial,sgs.FinishJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if player:hasSkill("sk_bugua") then
				if player:isKongcheng() and judge.who:isKongcheng() then return false end
				local choices = {"cancel"}
				if not player:isKongcheng() then
					table.insert(choices, "player_invoke")
				end
				if not judge.who:isKongcheng() then
					table.insert(choices, "self_invoke")
				end
				room:getThread():delay(1000)
				local choice = room:askForChoice(player, "sk_bugua", table.concat(choices, "+"))
				local retrialer
				if choice == "player_invoke" then
					retrialer = player
				elseif choice == "self_invoke" then
					retrialer = judge.who
				end
				if not retrialer then return false end
				local prompt_list = {
					"@guicai-card" ,
					judge.who:objectName() ,
					self:objectName() ,
					judge.reason ,
					string.format("%d", judge.card:getEffectiveId())
				}
				local prompt = table.concat(prompt_list, ":")
				local forced = false
				if retrialer:getMark("JilveEvent") == sgs.AskForRetrial then forced = true end
				local askforcardpattern = "."
				if forced then askforcardpattern = ".!" end
				local card = room:askForCard(retrialer, askforcardpattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
				if forced and (card == nil) then
					card = retrialer:getRandomHandCard()
				end	
				if card then
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:retrial(card, retrialer, judge, self:objectName())
				end
			end
			return false
		elseif event == sgs.FinishJudge then
			for _, s in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local judge = data:toJudge()
				local _data = sgs.QVariant()
				_data:setValue(judge.who)
				if judge.card:isRed() then
					if room:askForSkillInvoke(s, "sk_bugua_red", _data) then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:drawCards(judge.who, 1, "sk_bugua")
					end
				elseif judge.card:isBlack() and (not judge.who:isNude()) then
					if room:askForSkillInvoke(s, "sk_bugua_black", _data) then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:askForDiscard(judge.who, "sk_bugua", 1, 1, false, true)
					end
				end		
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
}

sk_guanlu:addSkill(sk_zongqing)
sk_guanlu:addSkill(sk_bugua)

sgs.LoadTranslationTable{
	["sk_guanlu"] = "sk管輅",
	["&sk_guanlu"] = "管輅",
	["#sk_guanlu"] = "卦象通神",
	["sk_zongqing"] = "縱情",
	["$sk_zongqing1"] = "你們不吃，我可先吃了",
	["$sk_zongqing2"] = "來來來，喝了這碗酒再說",
	[":sk_zongqing"] = "摸牌階段開始時，你可以進行一次判定，若如此做，此階段摸牌後你須展示之，然後棄置其中與該判定牌顏色不同的牌。若以此法棄置的牌為黑色，視為你使用一張【酒】；若以此法棄置的牌為紅色，視為你使用一張【桃】。",
	["sk_bugua"] = "卜卦",
	["$sk_bugua1"] = "多行善事，保你逢凶化吉",
	["$sk_bugua2"] = "想要消災避難，你就聽我的",
	["sk_bugua_red"] = "卜卦，令其摸一張牌",
	["sk_bugua_black"] = "卜卦，令其棄一張牌",
	[":sk_bugua"] = "每當一名角色將要進行判定時，你可以展示牌堆頂牌，然後可以選擇一項：將一張手牌置於牌堆頂，或令其將一張手牌置於牌堆頂。當一名角色的判定牌為紅色且生效後，你可以令其摸一張牌；當一名角色的判定牌為黑色且生效後，你可以令其棄置一張牌。",
	["player_invoke"] = "將一張手牌置於牌堆頂",
	["self_invoke"] = "令其將一張手牌置於牌堆頂",
	["~sk_guanlu"] = "最後一卦，還是留給自己吧。",
}
--sk張繡
sk_zhangxiu = sgs.General(extension,"sk_zhangxiu","qun",4, true)

sk_huaqiangCard = sgs.CreateSkillCard{
	name = "sk_huaqiang",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)	
		room:damage(sgs.DamageStruct("sk_huaqiang", source, targets[1]))
	end
}

sk_huaqiang = sgs.CreateViewAsSkill{
	name = "sk_huaqiang",
	n = 3,
	view_filter = function(self,selected,to_select)
		local x = math.min(sgs.Self:getHp(),3)
		if #selected>=x then return false end
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			return to_select:getSuit() ~= selected[1]:getSuit() and not to_select:isEquipped()
		elseif #selected == 2 then
			return to_select:getSuit() ~= selected[1]:getSuit() and to_select:getSuit() ~= selected[2]:getSuit() and not to_select:isEquipped()
		else
			return false
		end
	end,	
	view_as = function(self,cards)
		local x = math.min(sgs.Self:getHp(),3)
		if #cards ~= x then return nil end
		local card = sk_huaqiangCard:clone()
		for _,c in ipairs(cards) do 
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#sk_huaqiang") and player:getHandcardNum()>=math.min(player:getHp(),3)
	end
}
--source:inMyAttackRange(p)
--朝凰
sk_zhaohuangCard = sgs.CreateSkillCard{
	name = "sk_zhaohuang",
	target_fixed = false,
	filter = function(self, targets, to_select)
		local player = sgs.Self
		if player:canSlash(to_select, nil, false) and player:inMyAttackRange(to_select) then
			return true
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:loseHp(source)
		for i = 1,#targets,1 do
			local fire_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			fire_slash:setSkillName("sk_zhaohuang")
			local use = sgs.CardUseStruct()
			use.card = fire_slash
			use.from = source
			local dest = targets[i]
			use.to:append(dest)
			if source:isAlive() then
				room:useCard(use)
			end
		end
	end
} 

sk_zhaohuang = sgs.CreateZeroCardViewAsSkill{
	name = "sk_zhaohuang",
	n = 0,
	view_as = function()
		return sk_zhaohuangCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#sk_zhaohuang")
	end
}

sk_zhangxiu:addSkill(sk_huaqiang)
sk_zhangxiu:addSkill(sk_zhaohuang)

sgs.LoadTranslationTable{
	["#sk_zhangxiu"] = "北地槍王",
	["sk_zhangxiu"] = "sk張繡",
	["&sk_zhangxiu"] = "張繡",
	["sk_huaqiang"] = "花槍",
	[":sk_huaqiang"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以棄置X種不同花色的手牌，然後對一名其他"..
"角色造成1點傷害（X為你的體力值且至多為3）",
	["sk_zhaohuang"] = "朝凰",
	[":sk_zhaohuang"] = "<font color=\"green\"><b>出牌階段限一次，</b></font>你可以失去1點體力，然後視為對你攻擊範圍內的"..
"任意名其他角色依次使用一張【殺】（不計入出牌階段的使用限制）",
}

--sk關羽
sk_xingguanyu = sgs.General(extension,"sk_xingguanyu","wei2", 4)

--單騎：覺醒技，回合開始階段，若你的手牌數大於你的體力值，你須自減一點體力上限，回复2點體力，並永久獲得技能“拖刀”（每當你用【閃】抵消了一次【殺】的效果時，若使用者在你的攻擊範圍內，你可以立刻對其使用一張【殺】，此【殺】無視防具且不可閃避。）
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
sk_tuodao = sgs.CreateTriggerSkill{
	name = "sk_tuodao",
	events = {sgs.SlashMissed,sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if effect.to:hasSkill(self:objectName()) then
				if effect.to:distanceTo(effect.from) <= effect.to:getAttackRange() and effect.from:objectName() ~= effect.to:objectName() and effect.to:canSlash(effect.from, nil, false) then
					room:addPlayerMark(effect.to , "sk_tuodao_from")
					room:addPlayerMark(effect.from , "sk_tuodao_to")
					room:askForUseSlashTo(effect.to, effect.from, "@sk_tuodao:"..effect.from:objectName(),true)
					room:removePlayerMark(effect.to , "sk_tuodao_from")
					room:removePlayerMark(effect.from , "sk_tuodao_to")

				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:isAlive() and player:getMark("sk_tuodao_from") > 0 then
				local can_invoke = false

				for _, p in sgs.qlist(use.to) do
					if p:getMark("sk_tuodao_to") > 0 then
						can_invoke = true
					end
				end
				if can_invoke then
					room:broadcastSkillInvoke(self:objectName())
					local jink_table = sgs.QList2Table(use.from:getTag("Jink_" .. use.card:toString()):toIntList())
					local index = 1
					local msg = sgs.LogMessage()
					msg.type = "#SkTuodao"
					msg.from = player
					for _, p in sgs.qlist(use.to) do
						p:addQinggangTag(use.card)
						local _data = sgs.QVariant()
						_data:setValue(p)
						jink_table[index] = 0
						msg.to:append(p)
						index = index + 1
					end
					msg.arg = use.card:objectName()
					room:sendLog(msg)

					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					player:setTag("Jink_"..use.card:toString(), jink_data)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
}

sk_danji = sgs.CreateTriggerSkill{
	name = "sk_danji",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Start
			and target:getMark("sk_danji") == 0 and (target:getHandcardNum() > target:getHp() or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHandcardNum() > player:getHp() then
			local msg = sgs.LogMessage()
			msg.type = "#DanjiWake"
			msg.from = player
			msg.to:append(player)
			msg.arg = tostring(player:getHandcardNum())
			msg.arg2 = tostring(player:getHp())
			room:sendLog(msg)
		end

		if room:changeMaxHpForAwakenSkill(player) then
			room:broadcastSkillInvoke(self:objectName())
			room:setPlayerMark(player, "sk_danji", 1)
			room:doSuperLightbox("sk_xingguanyu","sk_danji")
			room:acquireSkill(player, "sk_tuodao")
			local theRecover = sgs.RecoverStruct()
			theRecover.recover = 2
			theRecover.who = player
			room:recover(player, theRecover)
		end
	end,
}
sk_xingguanyu:addSkill("wusheng")
sk_xingguanyu:addSkill(sk_danji)
if not sgs.Sanguosha:getSkill("sk_tuodao") then skills:append(sk_tuodao) end
sk_xingguanyu:addRelateSkill("sk_tuodao")

sgs.LoadTranslationTable{
	["#sk_xingguanyu"] = "活心醒龍",
	["sk_xingguanyu"] = "sk星關羽",
	["&sk_xingguanyu"] = "關羽",
	["sk_tuodao"] = "拖刀",
	["@sk_tuodao"] = "你可以立即對 %src 使用一張【殺】，此【殺】無視防具且不可閃避。",
	[":sk_tuodao"] = "每當你用【閃】抵消了一次【殺】的效果時，若使用者在你的攻擊範圍內，你可以立刻對其使用一張【殺】，此【殺】無視防具且不可閃避。",
	["sk_danji"] = "單騎",
	[":sk_danji"] = "覺醒技，回合開始階段，若你的手牌數大於你的體力值，你需自減一點體力上限，回复2點體力，並永久獲得技能“拖刀”",
	["#DanjiWake"] = "%from 手牌數(%arg)大於體力值(%arg2)，觸發“<font color=\"yellow\"><b>單騎</b></font> ”覺醒",
	["#SkTuodao"] = "%from 的技能 “<font color=\"yellow\"><b> %arg </b></font>”被觸發，%to 無法響應此 %arg2 且防具無效",
}
--sk臧霸
sk_zangba = sgs.General(extension,"sk_zangba","wei2", 4,true)
--橫江
sk_hengjiang = sgs.CreateTriggerSkill{
	name = "sk_hengjiang",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()		
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if room:askForSkillInvoke(player,"sk_hengjiang",data) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					local choices = {"sk_hengjiangplus","sk_hengjiangminus"}
					local choice = room:askForChoice(player, "sk_hengjiang", table.concat(choices, "+"))
					if choice == "sk_hengjiangplus" then
						room:setPlayerFlag(player, "sk_hengjiangplus")
					elseif choice == "sk_hengjiangminus" then
						room:setPlayerFlag(player, "sk_hengjiangminus")
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName())
				and (move.to_place == sgs.Player_Discard) then
				if player:getPhase() == sgs.Player_Discard then
					room:setPlayerMark(player, "sk_hengjiang_mark-Clear", move.card_ids:length())
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard and (player:hasFlag("sk_hengjiangplus") or player:hasFlag("sk_hengjiangminus")) then
				local n = player:getMark("sk_hengjiang_mark-Clear")
				if n > 0 then
					for i = 1, n, 1 do
						local _targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if player:canDiscard(p, "ej") then _targets:append(p) end
						end
						if not _targets:isEmpty() then
							local to_discard = room:askForPlayerChosen(player, _targets, "sk_hengjiang", "@sk_hungyuan", true)
							if to_discard then
								local id = room:askForCardChosen(player, to_discard, "ej", "sk_hengjiang", false, sgs.Card_MethodDiscard)
								room:throwCard(id, player, player)
							else
								break
							end
						else
							break
						end
					end
				end
			end
		end
		return false
	end					
}

sk_hengjiangMax = sgs.CreateMaxCardsSkill{
	name = "#sk_hengjiang", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		if target:hasFlag("sk_hengjiangplus") then
			return 1
		elseif target:hasFlag("sk_hengjiangminus") then 
			return -1
		end
	end
}

sk_zangba:addSkill(sk_hengjiang)
sk_zangba:addSkill(sk_hengjiangMax)

sgs.LoadTranslationTable{
	["sk_zangba"] = "sk臧霸",
	["&sk_zangba"] = "臧霸",
	["#sk_zangba"] = "",
	["sk_hengjiang"] = "橫江",
	[":sk_hengjiang"] = "棄牌階段開始時，你可以令你的手牌上限+1或-1，若如此做，你可以棄置場上的至多X張牌(X為你此階段棄置的牌數)",
	["sk_hengjiangplus"] = "手牌上限+1",
	["sk_hengjiangminus"] = "手牌上限-1",
}

--sk公孫瓚
sk_gongsunzan = sgs.General(extension, "sk_gongsunzan", "qun", "4", true)
--募馬
sk_muma = sgs.CreateTriggerSkill{
	name = "sk_muma",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.to_place == sgs.Player_DiscardPile then
			local ids = sgs.IntList()
			local i = 0
			for _, card_id in sgs.qlist(move.card_ids) do
				local cd = sgs.Sanguosha:getCard(card_id)
				if cd and (cd:isKindOf("OffensiveHorse") or cd:isKindOf("DefensiveHorse")) and move.from_places:at(i) == sgs.Player_PlaceEquip then
					ids:append(card_id)
				end
				i = i + 1
			end
			if not ids:isEmpty() then
				room:broadcastSkillInvoke(self:objectName())
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
			end
		end
	end
}

sk_gongsunzan:addSkill("yicong")
sk_gongsunzan:addSkill(sk_muma)

sgs.LoadTranslationTable{
	["sk_gongsunzan"] = "sk公孫瓚",
	["&sk_gongsunzan"] = "公孫瓚",
	["#sk_gongsunzan"] = "馳騁遼東",
	["sk_muma"] = "募馬",
	[":sk_muma"] = "鎖定技，你的回合外，若你沒有裝備+1/-1馬，則其他角色的+1/-1馬從裝備區進入棄牌區時，你可以獲得之",
}

--sk孫策（孫笨）
sk_sunce = sgs.General(extension, "sk_sunce", "wu2", "4", true)
--昂揚
sk_angyang = sgs.CreateTriggerSkill{
	name = "sk_angyang" ,
	events = {sgs.TargetConfirmed, sgs.TargetSpecified},
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, sunce, data)
		local room = sunce:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(sunce)) then
			if use.card:isKindOf("Duel") or (use.card:isKindOf("Slash") and use.card:isRed()) then
				if sunce:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					sunce:drawCards(1, self:objectName())
					if event == sgs.TargetSpecified then
						for _, p in sgs.qlist(use.to) do
							if not p:getJudgingArea():isEmpty() then
								sunce:drawCards(2, self:objectName())
							end
						end
					elseif event == sgs.TargetConfirmed then
						if use.from and not use.from:getJudgingArea():isEmpty() then
							sunce:drawCards(2, self:objectName())
						end
					end
				end
			end
		end
		return false
	end
}
--威風
sk_weifeng = sgs.CreateTriggerSkill{
	name = "sk_weifeng",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if (not p:isKongcheng()) and (not player:isKongcheng()) then
						targets:append(p)
					end
				end
				if not targets:isEmpty() and player:getHandcardNum() < player:getHp() then
					local to = room:askForPlayerChosen(player, targets, self:objectName(), "sk_weifeng-invoke", true, true)
					if to then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							local success = player:pindian(to, self:objectName(), nil)
							if success then
								player:drawCards(2, self:objectName())
							else
								to:drawCards(2, self:objectName())
							end	
						end
					end
				end
			end
		end
		return false
	end,
}

sk_sunce:addSkill(sk_angyang)
sk_sunce:addSkill(sk_weifeng)

sgs.LoadTranslationTable{
	["sk_sunce"] = "sk孫策",
	["&sk_sunce"] = "孫策",
	["#sk_sunce"] = "",
	["sk_angyang"] = "昂揚",
	[":sk_angyang"] = "每當你指定或成為紅色【殺】或【決鬥】的目標後，你可以摸一張牌。若對方判定區有牌，你可以摸兩張牌",
	["sk_weifeng"] = "威風",
	[":sk_weifeng"] = "回合開始階段，若你的手牌數小於你的體力值，你可以與一名角色拼點，若你贏，你從牌堆摸兩張牌；若你沒贏，該角色從牌堆摸兩張牌",
	["sk_weifeng-invoke"] = "你可以發動「威風」",
}

--sk周泰
sk_zhoutai = sgs.General(extension, "sk_zhoutai", "wu2", "4",true)
--奮激
sk_fenji = sgs.CreateTriggerSkill{
	name = "sk_fenji" ,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.card:isKindOf("Slash") then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("sk_fenji") then
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForSkillInvoke(p,self:objectName(), _data) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(2)
							room:loseHp(p)
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

sk_zhoutai:addSkill("buqu")
sk_zhoutai:addSkill(sk_fenji)

sgs.LoadTranslationTable{
	["sk_zhoutai"] = "sk周泰",
	["&sk_zhoutai"] = "周泰",
	["#sk_zhoutai"] = "",
	["sk_fenji"] = "奮激",
	[":sk_fenji"] = "當一名角色成為「殺」的目標後，你可以失去1點體力，令該角色摸兩張牌",
}

--[[
sk費禕
衍息 回合開始階段開始時或回合結束階段開始時，若你的裝備區內沒有牌，你可以摸一張牌。
止戈 你可以棄置你裝備區內的所有牌(至少一張)，視為使用一張【殺】或【閃】					
]]--
sk_feiyi = sgs.General(extension, "sk_feiyi", "shu2", "3",true)

sk_yanxi = sgs.CreateTriggerSkill{
	name = "sk_yanxi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if (player:getPhase() == sgs.Player_Finish or player:getPhase() == sgs.Player_RoundStart) and player:getEquips():length() == 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
			end
		end
	end
}


sk_zhigeVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_zhige",
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
		return sgs.Slash_IsAvailable(player) and player:getEquips():length() > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink") and player:getEquips():length() > 0
	end
}
sk_zhige = sgs.CreateTriggerSkill{
	name = "sk_zhige",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = sk_zhigeVS, 
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
			player:throwAllEquips()
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) 
	end
}

sk_feiyi:addSkill(sk_yanxi)
sk_feiyi:addSkill(sk_zhige)

sgs.LoadTranslationTable{
["#sk_feiyi"] = "",
["sk_feiyi"] = "sk費禕",
["&sk_feiyi"] = "費禕",
["sk_yanxi"] = "衍息",
[":sk_yanxi"] = "回合開始階段開始時或回合結束階段開始時，若你的裝備區內沒有牌，你可以摸一張牌。",
["sk_zhige"] = "止戈",
[":sk_zhige"] = "你可以棄置你裝備區內的所有牌(至少一張)，視為使用一張【殺】或【閃】",
}

--[[
sk呂玲綺
]]--
sk_lvlingqi = sgs.General(extension, "sk_lvlingqi", "qun", "4",false)

sk_jiwu = sgs.CreateTriggerSkill{
	name = "sk_jiwu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local choices = {"cancel"}
				for i = 1, 3 do
					if player:getMark("sk_jiwu"..i) == 0 then
						table.insert(choices, "sk_jiwu"..i)
					end
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice ~= "cancel" then
					room:setPlayerMark(player,choice,1)
					room:notifySkillInvoked(player, self:objectName())
					if choice ~= "sk_jiwu1" then
						room:broadcastSkillInvoke(self:objectName(),1)
					elseif choice ~= "sk_jiwu2" then
						room:broadcastSkillInvoke(self:objectName(),2)
					elseif choice ~= "sk_jiwu3" then
						room:broadcastSkillInvoke(self:objectName(),3)
					end
				end
			end
		end
	end
}

sk_jiwuBuff = sgs.CreateTriggerSkill{
	name = "sk_jiwuBuff" ,
	events = {sgs.DamageCaused,sgs.CardUsed,sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and player:getMark("sk_jiwu3") > 0 then
					damage.damage = damage.damage + 1	
					data:setValue(damage)
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:getTypeId() ~= 0 then
				room:addPlayerHistory(player, use.card:getClassName(),-1)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:getTypeId() ~= 0 then
				room:setPlayerMark(player,"sk_jiwu1",0)
				room:setPlayerMark(player,"sk_jiwu2",0)
				room:setPlayerMark(player,"sk_jiwu3",0)
			end
		end
	end
}

sk_jiwuTM = sgs.CreateTargetModSkill{
	name = "#sk_jiwuTM",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getMark("sk_jiwu2") > 0then
			return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getMark("sk_jiwu2") > 0 then
			return 1
		else
			return 0
		end
	end,
}

if not sgs.Sanguosha:getSkill("sk_jiwuBuff") then skills:append(sk_jiwuBuff) end

sk_lvlingqi:addSkill(sk_jiwu)
sk_lvlingqi:addSkill(sk_jiwuTM)

sgs.LoadTranslationTable{
["#sk_lvlingqi"] = "",
["sk_lvlingqi"] = "sk呂玲綺",
["&sk_lvlingqi"] = "呂玲綺",
["sk_jiwu"] = "戟舞",
["sk_jiwuBuff"] = "戟舞",
[":sk_jiwu"] = "出牌階段開始時，妳可以令妳下次使用的【殺】獲得以下效果之一：1、此【殺】不計入次數限制；2、此【殺】無距離限制，且可以額外指定一個目標；3、此【殺】的傷害值+1。",
["sk_jiwu1"] = "此【殺】不計入次數限制",
["sk_jiwu2"] = "此【殺】無距離限制，且可以額外指定一個目標",
["sk_jiwu3"] = "此【殺】的傷害值+1",
["~sk_lvlingqi"] = "父親，我還是來得太遲了...",
}

--[[
sk蔣欽
尚義 出牌階段限一次，你可令一名其他角色觀看你的手牌，然後你選擇一項：觀看其手牌，並可棄置其中一張黑色牌；或觀看其身份牌。
忘私 當你受到傷害時，你可以觀看傷害來源的手牌，並可棄置其中一張紅色牌。
]]--
sk_jiangqin = sgs.General(extension, "sk_jiangqin", "wu2", "4",true)

sk_wangsi = sgs.CreateTriggerSkill{
	name = "sk_wangsi",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if not damage.from:isKongcheng() then
			local _data = sgs.QVariant()
			_data:setValue(damage.from)
			if room:askForSkillInvoke(player, self:objectName(), _data) then
				room:doAnimate(1, player:objectName(), damage.from:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:getThread():delay()
				local ids = sgs.IntList()
				for _, card in sgs.qlist(damage.from:getHandcards()) do
					if card:isRed() then
						ids:append(card:getEffectiveId())
					end
				end
				local card_id = room:doGongxin(player, damage.from, ids)
				if (card_id == -1) then return end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, self:objectName(), nil)
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, damage.from, player)
			end
		end
	end,
}

sk_jiangqin:addSkill("shangyi")
sk_jiangqin:addSkill(sk_wangsi)

sgs.LoadTranslationTable{
["#sk_jiangqin"] = "",
["sk_jiangqin"] = "sk蔣欽",
["&sk_jiangqin"] = "蔣欽",
["shangyi"] = "尚義",
[":shangyi"] = "階段技。你可以令一名其他角色觀看你的手牌，然後你選擇一項：1.觀看其手牌，然後你可以棄置其中一張黑色牌。2.觀看其身份牌。",
["shangyi:handcards"] = "手牌",
["shangyi:role"] = "身份牌",
["shangyi:remainedgenerals"] = "備選武將",
["shangyi:generals"] = "暗將",
["$ShangyiView"] = "%from 觀看了 %to 的 %arg",
["$ShangyiViewRemained"] = "%from 觀看了 %to 的備選武將 %arg",
["$ShangyiViewUnknown"] = "%from 觀看了 %to 的暗將 %arg",

["sk_wangsi"] = "忘私",
[":sk_wangsi"] = "當你受到傷害時，你可以觀看傷害來源的手牌，並可棄置其中一張紅色牌。",
}

--SK何進
sk_hejin = sgs.General(extension, "sk_hejin", "qun", "4", true)

sk_zhuanshan = sgs.CreateTriggerSkill{
	name = "sk_zhuanshan" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) then
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
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						target:drawCards(1)
						local id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
						room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_DrawPile)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}

sk_hejin:addSkill(sk_zhuanshan)

sgs.LoadTranslationTable{
["#sk_hejin"] = "",
["sk_hejin"] = "sk何進",
["&sk_hejin"] = "何進",
["sk_zhuanshan"] = "專擅",
[":sk_zhuanshan"] = "準備階段或結束階段，你可以令一名角色摸一張牌，然後將其一張牌置於牌堆頂。",
}
--sk卞夫人
sk_bianfuren = sgs.General(extension, "sk_bianfuren", "wei2", "3", false)
--化戈
sk_huageCard = sgs.CreateSkillCard{
	name = "sk_huageCard" ,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "sk_huage_discard")
		room:askForDiscard(source, "sk_huage",2,1, false, true)
		room:setPlayerFlag(source, "-sk_huage_discard")

		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:setPlayerFlag(p ,"sk_huage_discard")
			room:askForDiscard(p, "sk_huage",2, 1, false, true)
			room:setPlayerFlag(p, "-sk_huage_discard")
		end
	end
}

sk_huageVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_huage",
	view_as = function(self,cards)
		return sk_huageCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_huageCard") < 1
	end
}
sk_huage = sgs.CreateTriggerSkill{
	name = "sk_huage",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = sk_huageVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and player:hasFlag("sk_huage_discard") then
				for i=0, (move.card_ids:length()-1), 1 do
					local card_id = move.card_ids:at(i)
					local card = sgs.Sanguosha:getCard(card_id)
					if card:isKindOf("Slash") then
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
--母儀
sk_muyi = sgs.CreateTriggerSkill{
	name = "sk_muyi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("sk_muyi") then
					local to_exchange = room:askForExchange(player, self:objectName(), 2, 0, false, "@sk_muyiask:"..p:objectName(), true)
					if to_exchange then
						room:broadcastSkillInvoke(self:objectName(),2)
						room:moveCardTo(to_exchange, p, sgs.Player_PlaceHand, false)
						local n = to_exchange:getSubcards():length()
						room:setPlayerMark(p,"@sk_muyi",n)
					end
				end
			end
	 	 elseif player:getPhase() == sgs.Player_Finish then
	 	 	if player:isAlive() then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("sk_muyi") and p:getMark("@sk_muyi") > 0 then
						local n = p:getMark("@sk_muyi")
						room:broadcastSkillInvoke(self:objectName(),1)
						local to_exchange = room:askForExchange(p, self:objectName(), n, n, false, "@sk_muyiback:"..player:objectName())
						room:moveCardTo(to_exchange, player, sgs.Player_PlaceHand, false)
						room:setPlayerMark(p,"@sk_muyi",0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = -2
}
sk_bianfuren:addSkill(sk_huage)
sk_bianfuren:addSkill(sk_muyi)

sgs.LoadTranslationTable{
	["sk_bianfuren"] = "sk卞夫人",
	["&sk_bianfuren"] = "卞夫人",
	["#sk_bianfuren"] = "",
	["sk_huage"] = "化戈",
	[":sk_huage"] = "出牌階段限一次，你可以令所有角色依次棄置至少1張牌，目標角色每棄置一張「殺」則摸一張牌",
	["sk_muyi"] = "母儀",
	[":sk_muyi"] = "其他角色的回合開始階段開始時，其可以交給你一至兩張牌，然後此回合結束時，你交給其等量的牌",
	["@sk_muyiask"] = "你可以交給 %src 一至兩張牌，然後此回合結束時，其交給你等量的牌",
	["@sk_muyiback"] = "請交給 %src 等量的牌",

}

--sk陸積
sk_luji = sgs.General(extension, "sk_luji", "wu2", "3", true)
--懷橘
sk_huaiju = sgs.CreateTriggerSkill{
	name = "sk_huaiju",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Start or phase == sgs.Player_Judge or phase == sgs.Player_Draw or phase == sgs.Player_Play or phase == sgs.Player_Discard or phase == sgs.Player_Finish then
			if player:getHandcardNum() == 3 then
				if room:askForSkillInvoke(player, "sk_huaiju", data) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					local choices = {"huigue_draw", "huigue_discard"}
					local choice = room:askForChoice(player, "sk_huaiju", table.concat(choices, "+"))
					if choice == "huigue_draw" then
						room:drawCards(player, 1, "sk_huaiju")
					end
					if choice == "huigue_discard" then
						room:askForDiscard(player, "sk_huaiju", 2, 2, false, true)
					end
				end
			end
		end
	end
}
--渾天
sk_huntianCard = sgs.CreateSkillCard{
	name = "sk_huntianCard",
	target_fixed = true,
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local sbs = {}
		if source:getTag("sk_huntian"):toString() ~= "" then
			sbs = source:getTag("sk_huntian"):toString():split("+")
		end
		for _,cdid in sgs.qlist(self:getSubcards()) do table.insert(sbs, tostring(cdid))  end
		source:setTag("sk_huntian", sgs.QVariant(table.concat(sbs, "+")))
	end
}
sk_huntianVS = sgs.CreateViewAsSkill{
	name = "sk_huntian",
	n = 998,
	view_filter = function(self, selected, to_select)
		local str = sgs.Self:property("sk_huntian"):toString()
		return string.find(str, tostring(to_select:getEffectiveId())) end,
	view_as = function(self, cards)
		if #cards ~= 0 then
			local card = sk_huntianCard:clone()
			for var=1,#cards do card:addSubcard(cards[var]) end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@sk_huntian"
	end,
}
function listIndexOf(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
sk_huntian = sgs.CreateTriggerSkill{
	name = "sk_huntian",
	view_as_skill = sk_huntianVS,
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
				room:setPlayerProperty(player, "sk_huntian", sgs.QVariant(table.concat(zongxuantable, "+")))
				while not zongxuan_card:isEmpty() do
					if not room:askForUseCard(player, "@@sk_huntian", "@sk_huntianput") then break end
					local subcards = sgs.IntList()
					local subcards_variant = player:getTag("sk_huntian"):toString():split("+")
					if #subcards_variant>0 then
						for _,ids in ipairs(subcards_variant) do 
							subcards:append(tonumber(ids)) 
						end
						local zongxuan = player:property("sk_huntian"):toString():split("+")
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
							local c = sgs.Sanguosha:getCard(id)
							if c:getTypeId() == 1 then
								room:setPlayerFlag(player, "ht_Basic")
							elseif c:getTypeId() == 2 then
								room:setPlayerFlag(player, "ht_Trick")
							elseif c:getTypeId() == 3 then
								room:setPlayerFlag(player, "ht_Equip")
							end
							if not player:isAlive() then break end
						end
					end
					player:removeTag("sk_huntian")
				end
				if not (player:hasFlag("ht_Basic") and player:hasFlag("ht_Trick") and player:hasFlag("ht_Equip")) then
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if (not player:hasFlag("ht_Basic")) and card:isKindOf("BasicCard") then
								DPHeart:append(id)
							end
							if (not player:hasFlag("ht_Trick")) and card:isKindOf("TrickCard") then
								DPHeart:append(id)
							end
							if (not player:hasFlag("ht_Equip")) and card:isKindOf("EquipCard") then
								DPHeart:append(id)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
						local getcard = sgs.Sanguosha:getCard(get_id)
						room:obtainCard(player, getcard)
					end
					room:setPlayerFlag(player, "-ht_Basic")
					room:setPlayerFlag(player, "-ht_Trick")
					room:setPlayerFlag(player, "-ht_Equip")
				end
			end
		end
		return
	end,
}

sk_luji:addSkill(sk_huaiju)
sk_luji:addSkill(sk_huntian)

sgs.LoadTranslationTable{
	["sk_luji"] = "sk陸積",
	["&sk_luji"] = "陸積",
	["#sk_luji"] = "懷橘遺母",
	["sk_huaiju"] = "懷橘",
	[":sk_huaiju"] = "當你的回合任一個階段開始時，若你的手牌數為3，你可以選擇：1.摸一張牌，2.棄置兩張牌，並從牌堆獲得一張指定類型的牌",
	["huigue_draw"] = "摸一張牌",
	["huigue_discard"] = "棄置兩張牌，並從牌堆獲得一張指定類型的牌",
	["huigue_drawpile"] = "置於牌堆頂",
	["huigue_discardpile"] = "棄置該牌",
	["sk_huntian"] = "渾天",
	[":sk_huntian"] = "你的棄牌階段開始時，你可以將你的超出體力的任意張手牌置於牌堆頂，然後從牌堆獲得一張指定類型的牌",
	["@huigue-discard"] = "請選擇要棄置的牌",
	["~sk_huntian"] = "點擊你欲置於牌堆頂的牌 -> 點擊「確定」",
	["@sk_huntianput"] = "將你棄置的牌置於牌堆頂",
	
}
--sk董襲
sk_dongxi = sgs.General(extension,"sk_dongxi","wu2",4, true)

sk_duanlanCard = sgs.CreateSkillCard{
	name = "sk_duanlan" ,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local x = 0	
		for i = 1 , 3, 1 do
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if source:canDiscard(p, "hej") then _targets:append(p) end
			end
			if not _targets:isEmpty() then
				local to_discard = room:askForPlayerChosen(source, _targets, "sk_duanlan", "@sk_sijian-discard", true)
				if to_discard then
					room:doAnimate(1, source:objectName(), to_discard:objectName())
					local id = room:askForCardChosen(source, to_discard, "hej", "sk_duanlan", false, sgs.Card_MethodDiscard)
					local card = sgs.Sanguosha:getCard(id)
					room:throwCard(id, to_discard, source)
					x = x + card:getNumber()
				else
					break
				end
			end
		end
		local prompt = string.format("@sk_duanlan:%s:%s", source:objectName(), tostring(x))
		if x > 0 then
		local c
			if x == 1 then
				c = room:askForCard(source, ".|.|2~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 2 then
				c = room:askForCard(source, ".|.|3~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 3 then
				c = room:askForCard(source, ".|.|4~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 4 then
				c = room:askForCard(source, ".|.|5~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 5 then
				c = room:askForCard(source, ".|.|6~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 6 then
				c = room:askForCard(source, ".|.|7~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 7 then
				c = room:askForCard(source, ".|.|8~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 8 then
				c = room:askForCard(source, ".|.|9~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 9 then
				c = room:askForCard(source, ".|.|10~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 10 then
				c = room:askForCard(source, ".|.|11~13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x == 11 then
				c = room:askForCard(source, ".|.|12~13|.", prompt, sgs.QVariant(),sgs.CardDiscarded)
			elseif x == 12 then
				c = room:askForCard(source, ".|.|13|.", prompt, sgs.QVariant(), sgs.CardDiscarded)
			elseif x > 13 then
				c = nil
			end
			if not c then
				room:loseHp(source)
			end
		end
	end
}

sk_duanlan = sgs.CreateZeroCardViewAsSkill{
	name = "sk_duanlan",
	view_as = function(self,cards)
		return sk_duanlanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_duanlanCard") < 1
	end
}
sk_dongxi:addSkill(sk_duanlan)

sgs.LoadTranslationTable{	
["sk_dongxi"] = "sk董襲",
["&sk_dongxi"] = "董襲",
["#sk_dongxi"] = "揮刀斷虹",
["sk_duanlan"] = "斷纜",
[":sk_duanlan"] = "出牌階段限一次，你可以棄置其他角色區域內的一到三張牌，然後選擇一項：1.失去一點體力，2.棄置一張大於這些牌點數之和的牌",
["@sk_duanlan"] = "請棄置一張點數大於 %dest 的手牌，否則你失去一點體力。",
}
--sk向朗
sk_xianglang = sgs.General(extension,"sk_xianglang","shu2",3, true)
--藏書：當其他角色使用非延時類錦囊牌時，你可以交給其一張基本牌，然後獲得此牌並令其無效。
sk_cangshu = sgs.CreateTriggerSkill{
	name = "sk_cangshu",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			local use = data:toCardUse()
			if use.card:isNDTrick() and p:hasSkill(self:objectName()) then
				local invoke = false
				for _, card in sgs.qlist(s:getHandcards()) do
					if card:isKindOf("BasicCard") then
						invoke = true
						break
					end
				end
				if invoke then
					local card = room:askForCard(p, ".Basic", "@sk_cangshu1", data, sgs.Card_MethodNone)
					if card then
						room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
						room:notifySkillInvoked(player, "sk_cangshu")
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, s:objectName(), player:objectName(), "sk_cangshu","")
						room:moveCardTo(card,player,sgs.Player_PlaceHand,reason)
						room:moveCardTo(use.card,p,sgs.Player_PlaceHand)
		
						return true
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player ~= nil
	end,
}
--勘誤：當你於回合外需要使用或打出一張基本牌時，你可以棄置一張錦囊牌，視為使用或打出之
sk_kanwu = sgs.CreateTriggerSkill{
	name = "sk_kanwu",
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked then
			local pattern = data:toStringList()[1]
			if (pattern == "jink" or pattern == "slash" or pattern == "peach") and
			 not player:isKongcheng() and player:getPhase() == sgs.Player_NotActive  then
				local invoke = false
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:isKindOf("TrickCard") then
						invoke = true
						break
					end
				end
				if invoke then
					local card = room:askForCard(player, ".Trick", "@sk_kanwu1", data, sgs.CardDiscarded)
					if card then
						if pattern == "slash" then
							local jink = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							jink:setSkillName(self:objectName())
							room:provide(jink)
							return true
						elseif pattern == "jink" then
							local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
							jink:setSkillName(self:objectName())
							room:provide(jink)
							return true
						elseif pattern == "peach" then
							local jink = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
							jink:setSkillName(self:objectName())
							room:provide(jink)
							return true
						end
					end
				end
			end
		end
		return false
	end,
}

sk_xianglang:addSkill(sk_cangshu)
sk_xianglang:addSkill(sk_kanwu)

sgs.LoadTranslationTable{	
["sk_xianglang"] = "sk向朗",
["#sk_xianglang"] = "瓜田李下",
["&sk_xianglang"] = "向朗",
["sk_cangshu"] = "藏書",
[":sk_cangshu"] = "當其他角色使用非延時類錦囊牌時，你可以交給其一張基本牌，然後獲得此牌並令其無效。",
["@sk_cangshu1"] = "你可以交給其一張基本牌，然後獲得此牌並令其無效。",
["sk_kanwu"] = "勘誤",
[":sk_kanwu"] = "當你於回合外需要使用或打出一張基本牌時，你可以棄置一張錦囊牌，視為使用或打出之",
["@sk_kanwu1"] = "你可以棄置一張錦囊牌，視為使用或打出一張基本牌",
}
--sk左慈
sk_zuoci = sgs.General(extension,"sk_zuoci","qun",3, true)
function askForChooseSkill_newzuoci(zuoci)
	local room = zuoci:getRoom()
	local Huashens = {}
	local generals = generate_all_general_list(zuoci, false, {"zuoci","zuoci_po", "guzhielai", "dengshizai", "caochong", "jiangboyue", "bgm_xiahoudun"} )
	for i = 1, 3, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Huashens, getGeneral)
			table.remove(generals, j)
		end
	end

	local sks = {}
	local old_skills = {}
	local new_skills = {}
	for _,general_name in ipairs(Huashens) do
		local log = sgs.LogMessage()
		log.type = "#getGeneralCard"
		log.from = zuoci	
		log.arg = general_name
		room:sendLog(log)		
		local general = sgs.Sanguosha:getGeneral(general_name)		
		for _,sk in sgs.qlist(general:getVisibleSkillList()) do
			if not sk:isLordSkill() then
				if sk:getFrequency() ~= sgs.Skill_Limited then
					if sk:getFrequency() ~= sgs.Skill_Wake then
						local can_use = true
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasSkill(sk:objectName()) then
								can_use = false
							end
						end
						if can_use then
							table.insert(sks, sk:objectName())
						end
					end
				end
			end
		end
	end
	for _,oks3 in sgs.qlist(zuoci:getVisibleSkillList()) do
		if zuoci:hasSkill(oks3:objectName()) and zuoci:getMark("sk_qianhuan"..oks3:objectName()) == 1 then
			table.insert(sks, oks3:objectName())
			table.insert(old_skills, oks3:objectName())
		end
	end
	local x = 2
	if zuoci:getGeneral2() then x = 4 end
	if x >= #sks then			
		for _,ski in ipairs(sks) do
			table.insert(new_skills,ski)
			if not zuoci:hasSkill(ski) then
				room:acquireSkill(zuoci,ski)
				room:setPlayerMark(zuoci, "sk_qianhuan"..ski, 1)

				for _, ski2 in sgs.qlist(sgs.Sanguosha:getRelatedSkills(ski)) do
					room:handleAcquireDetachSkills(zuoci,ski2:objectName())
				end

			end
		end
	else
		for i = 1,x do
			local choice = room:askForChoice(zuoci, "sk_qianhuan", table.concat(sks, "+"))
			table.insert(new_skills,choice)
			table.removeOne(sks, choice)
			if not zuoci:hasSkill(choice) then			
				room:acquireSkill(zuoci, choice)
				room:setPlayerMark(zuoci, "sk_qianhuan"..choice, 1)

				for _, ski2 in sgs.qlist(sgs.Sanguosha:getRelatedSkills(choice)) do
					room:handleAcquireDetachSkills(zuoci,ski2:objectName())
				end
			end
			if not zuoci:getAI() then
				room:getThread():delay(200)
			end
		end
	end
	for _,oks1 in ipairs(old_skills) do
		local change = true
		for _,oks2 in ipairs(new_skills) do
			if oks1 == oks2 then
				change = false
			end
		end
		if change then
			room:detachSkillFromPlayer(zuoci, oks1)
			room:setPlayerMark(zuoci, "sk_qianhuan"..oks1, 0)
			for _, ski2 in sgs.qlist(sgs.Sanguosha:getRelatedSkills(oks1)) do
				room:handleAcquireDetachSkills(zuoci,"-"..ski2:objectName())
			end
		end
	end
end

sk_qianhuan = sgs.CreateTriggerSkill{
	name = "sk_qianhuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.GameStart},	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:getGeneral2() then
				if player:getGeneralName() == "sk_zuoci" and (player:getGeneral2Name() ~= "sujiang" or 
					player:getGeneral2Name() ~= "sujiangf") then--若主将是左慈且副将不是素将，则将副将设置成素将
					if player:getGeneral2():isMale() then
						room:changeHero(player, "sujiang", false, false, true, true)
					else
						room:changeHero(player, "sujiangf", false, false, true, true)				
					end
				elseif player:getGeneral2Name() == "sk_zuoci" and (player:getGeneralName() ~= "sujiang" or 
					player:getGeneralName() ~= "sujiangf") then--若副将是左慈，且主将不是素将，则将主将设置成素将
					if player:getGeneral():isMale() then
						room:changeHero(player, "sujiang", false, false, false, true)
					else
						room:changeHero(player, "sujiangf", false, false, false, true)
					end
				end				
				room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()-2))				
			end
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player,self:objectName())
			askForChooseSkill_newzuoci(player)
		else				
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart then						
				local phase = player:getPhase()
				room:broadcastSkillInvoke(self:objectName())				
				room:notifySkillInvoked(player,self:objectName())
				askForChooseSkill_newzuoci(player)			
			end	
		end
		return false
	end
}

sk_zuoci:addSkill(sk_qianhuan)

sgs.LoadTranslationTable{
	["sk_zuoci"] = "sk左慈",
	["&sk_zuoci"] = "左慈",
	["#sk_zuoci"] = "遁形幻千",
	["sk_qianhuan"] = "千幻",
	[":sk_qianhuan"] = "<font color=\"blue\"><b>鎖定技，</b></font>遊戲開始時或你的每個回合開始時，隨機展示三張未上場且你擁有的武將牌，你獲得其中的兩個技能（限定技、覺醒技除外）。你的每個回合開始時，你可以先選擇保留當前擁有的至多兩個技能，再獲得共計兩個技能。若該局遊戲為雙將模式，則移除你的另一名武將，將描述中的第一、第三個“兩個”改為“四個”。",
	["#getGeneralCard"] = " %from 獲得了一張武將牌“%arg”",
	["keepskill"] = "保留此技能",
	["changeskill"] = "更換此技能",
}

--[[
SK關興
【勇繼】—— 鎖定技，當你於出牌階段使用【殺】造成傷害後，你摸x張牌且你本回合可額外使用一張【殺】(x為你已損失的體力值)。
【武志】 ——鎖定技，出牌階段結束時，若你的【殺】的使用次數未達到上限，你失去一點體力並從牌堆裡獲得一張【殺】。
]]--
sk_guanxing = sgs.General(extension,"sk_guanxing","shu2",4, true)

sk_yongji = sgs.CreateTriggerSkill{
	name = "sk_yongji" ,
	events = {sgs.Damage} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card then
				if damage.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					local n = player:getLostHp()
					player:drawCards(n)
					room:addPlayerMark(player,"sk_yongji-Clear")
				end
			end
		end
	end
}

sk_yongjiTM = sgs.CreateTargetModSkill{
	name = "#sk_yongji",
	pattern = ".",
	residue_func = function(self, from, card)
		return from:getMark("sk_yongji-Clear")
	end,
}

sk_wuzhi = sgs.CreateTriggerSkill{
	name = "sk_wuzhi",  
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			if player:getMark("used_slash-Clear") < player:getMark("sk_yongji-Clear") + 1 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(player)
				getpatterncard(player, {"Slash"} ,true,false)
			end
		end
	end,
}

sk_guanxing:addSkill(sk_yongji)
sk_guanxing:addSkill(sk_yongjiTM)
sk_guanxing:addSkill(sk_wuzhi)

sgs.LoadTranslationTable{
	["sk_guanxing"] = "sk關興",
	["&sk_guanxing"] = "關興",
	["sk_yongji"] = "勇繼",
	[":sk_yongji"] = "<font color=\"blue\"><b>鎖定技，</b></font>當你於出牌階段使用【殺】造成傷害後，你摸x張牌且你本回合可額外使用一張【殺】(x為你已損失的體力值)",
	["sk_wuzhi"] = "武志",
	[":sk_wuzhi"] = "<font color=\"blue\"><b>鎖定技，</b></font>棄牌階段結束時，若你本回合的【殺】的使用次數未達到上限，你失去一點體力並從牌堆裡獲得一張【殺】。",
}

--sk糜夫人
sk_mifuren = sgs.General(extension,"sk_mifuren","shu2",3,false)

--閨秀
sk_guixiu = sgs.CreateTriggerSkill{
	name = "sk_guixiu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if data:toPhaseChange().to == sgs.Player_Discard and player:getMark("damage_record-Clear") == 0 then
			if room:askForSkillInvoke(player,self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:skip(sgs.Player_Discard)
				player:drawCards(1)
			end
		end			
		return false
	end ,
}
--存嗣
sk_cunsi = sgs.CreateTriggerSkill{
	name = "sk_cunsi", 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local death = data:toDeath()		
		if death.who:objectName() == player:objectName() then
			local targets = room:getOtherPlayers(player)			
			if targets:length() > 0 then
				local target = room:askForPlayerChosen(player, targets, self:objectName(),"sk_cunsi-invoke", true, true)
				if target then
					room:notifySkillInvoked(player, "sk_cunsi")
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("sk_mifuren", "sk_cunsi")				
					room:handleAcquireDetachSkills(target, "sk_yongjue", false)
					local list = sgs.IntList()
					for _, c in sgs.qlist(player:getCards("he")) do
						list:append(c:getEffectiveId())
					end
					target:addToPile("sk_cunsi", list)
				end
			end
			return false
		end
	end, 
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end
}
--勇決
sk_yongjue = sgs.CreateTriggerSkill{
	name = "sk_yongjue",
	events = {sgs.Death,sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Death then
			local death = data:toDeath()
			if player:isAlive() then
				if death.damage then
					if death.damage.from and death.damage.from:objectName() == player:objectName() then
						if not player:getPile("sk_cunsi"):isEmpty() then
							if player:isMale() then
								room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
							else
								room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
							end
							local dummy = sgs.Sanguosha:cloneCard("slash")
							dummy:addSubcards(player:getPile("sk_cunsi"))
							room:obtainCard(player, dummy, false)
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.by_user and not damage.chain and not damage.transfer and damage.card:isKindOf("Slash") then
				if player:isMale() then
					room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
				else
					room:broadcastSkillInvoke(self:objectName(),math.random(3,4))
				end
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#SkYongjue"
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

sk_mifuren:addSkill(sk_guixiu)
sk_mifuren:addSkill(sk_cunsi)

if not sgs.Sanguosha:getSkill("sk_yongjue") then skills:append(sk_yongjue) end

sgs.LoadTranslationTable{
["#sk_mifuren"] = "亂世沉香",
["sk_mifuren"] = "sk糜夫人",
["&sk_mifuren"] = "糜夫人",
["sk_guixiu"] = "閨秀",
[":sk_guixiu"] = "若妳本回合沒有造成傷害，妳可以跳過棄牌階段然後摸一張牌。",
["sk_cunsi"] = "存嗣",
[":sk_cunsi"] = "當妳死亡時，妳可以將區域內的所有牌移出遊戲，然後妳選擇一名角色獲得“勇決”",
["sk_cunsi-invoke"] = "妳可以發動【存嗣】",
["sk_yongjue"] = "勇決",
[":sk_yongjue"] = "鎖定技，你使用【殺】的傷害+1，當你殺死一名角色時，你獲得“存嗣”移出遊戲的牌。" ,
["$CunsiAnimate"] = "image=image/animate/cunsi.png",
["#SkYongjue"] = "%from 的技能 “<font color=\"yellow\"><b>勇決</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--[[
蒯越
異度：你的回合外每回合限一次，當你失去牌前，你可以摸X張牌(X為當前回合角色手牌中花色與這些牌相同的數量)
諸暴：你的回合內對每一名其他角色限一次，當其失去牌前，你可以摸X張牌(X為你手牌中花色與這些牌相同的數量)
]]--
sk_kuaiyue = sgs.General(extension,"sk_kuaiyue","qun",3,true)

sk_yidu = sgs.CreateTriggerSkill{
	name = "sk_yidu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and
			  move.card_ids:length() > 0 and player:getMark("sk_yidu-Clear") == 0 and player:getPhase() == sgs.Player_NotActive then
				local current = room:getCurrent()
				local give_suit_name_table = {}
				for _, id in sgs.qlist(move.card_ids) do
					local c = sgs.Sanguosha:getCard(id)
					if c:getSuitString() == "spade" then
						table.insert(give_suit_name_table, c:getSuitString())
					elseif c:getSuitString() == "club" then
						table.insert(give_suit_name_table, c:getSuitString())
					elseif c:getSuitString() == "heart" then
						table.insert(give_suit_name_table, c:getSuitString())
					elseif c:getSuitString() == "diamond" then
						table.insert(give_suit_name_table, c:getSuitString())
					end
				end

				local n = 0
				for _, patt in ipairs(give_suit_name_table) do
					for _, c in sgs.qlist(current:getHandcards()) do
						if c:getSuitString() == patt then
						n = n + 1
						end
					end
				end
				if n > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player,"sk_yidu-Clear")
						player:drawCards(n)
					end
				end
			end
		end
		return false
	end
}

sk_zhubao = sgs.CreateTriggerSkill{
	name = "sk_zhubao",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() ~= player:objectName() and
			  move.card_ids:length() > 0 and player:getMark("sk_zhubao"..move.from:objectName().."-Clear") == 0 and player:getPhase() ~= sgs.Player_NotActive then

				local give_suit_name_table = {}
				for _, id in sgs.qlist(move.card_ids) do
					local c = sgs.Sanguosha:getCard(id)
					if c:getSuitString() == "spade" then
						table.insert(give_suit_name_table, c:getSuitString())
					elseif c:getSuitString() == "club" then
						table.insert(give_suit_name_table, c:getSuitString())
					elseif c:getSuitString() == "heart" then
						table.insert(give_suit_name_table, c:getSuitString())
					elseif c:getSuitString() == "diamond" then
						table.insert(give_suit_name_table, c:getSuitString())
					end
				end

				local n = 0
				for _, patt in ipairs(give_suit_name_table) do
					for _, c in sgs.qlist(BeMan(room, move.from):getHandcards()) do
						if c:getSuitString() == patt then
							n = n + 1
						end
					end
				end
				if n > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player,"sk_zhubao"..move.from:objectName().."-Clear")
						player:drawCards(n)
					end
				end
			end
		end
		return false
	end
}

sk_kuaiyue:addSkill(sk_yidu)
sk_kuaiyue:addSkill(sk_zhubao)

sgs.LoadTranslationTable{
["sk_kuaiyue"] = "sk蒯越",
["&sk_kuaiyue"] = "蒯越",
["sk_yidu"] = "異度",
[":sk_yidu"] = "你的回合外每回合限一次，當你失去牌前，你可以摸X張牌(X為當前回合角色手牌中花色與這些牌相同的數量)",
["sk_zhubao"] = "諸暴",
[":sk_zhubao"] = "你的回合內對每一名其他角色限一次，當其失去牌前，你可以摸X張牌(X為你手牌中花色與這些牌相同的數量)",
}

--[[
鄒氏
]]--
sk_zoushi = sgs.General(extension,"sk_zoushi","qun",3,false)

sk_jiaomei = sgs.CreateTriggerSkill{
	name = "sk_jiaomei",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:objectName() == use.from:objectName() and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				for _, p in sgs.qlist(use.to) do
					if player:getMark("sk_jiaomei_Play") == 0 then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if room:askForSkillInvoke(player, self:objectName(), _data) then
							room:broadcastSkillInvoke(self:objectName())
							room:addPlayerMark(player,"sk_jiaomei_Play")
							if not p:isChained() then
								room:setPlayerProperty(p, "chained", sgs.QVariant(true))
							else
								room:setPlayerProperty(p, "chained", sgs.QVariant(false))
								p:turnOver()
							end
						end
					end
				end
			end
		end
		return false
	end
}

sk_huoshui = sgs.CreateTriggerSkill{
	name = "sk_huoshui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isChained() and not p:isNude() then
							_targets:append(p) 
						end
					end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "sk_huoshui1", "@sk_huoshui1", true)
					if s then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						room:obtainCard(player,room:askForCardChosen(player, s, "he", "cuike", false, sgs.Card_MethodDiscard),true)
					end
				end

				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:faceUp() then
						_targets:append(p) 
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "sk_huoshui2", "@sk_huoshui2", true)
					if s then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))
					end
				end
			end
		end
	end,
}

sk_zoushi:addSkill(sk_jiaomei)
sk_zoushi:addSkill(sk_huoshui)

sgs.LoadTranslationTable{
["#sk_zoushi"] = "惑心之魅",
["sk_zoushi"] = "sk鄒氏",
["&sk_zoushi"] = "鄒氏",
["sk_jiaomei"] = "嬌媚",
[":sk_jiaomei"] = "出牌階段限一次，當妳使用【殺】或普通錦囊牌指定目標後，若目標角色：未橫置，妳令其橫置；已橫置，妳令其重置並翻面",
["sk_huoshui"] = "禍水",
["sk_huoshui1"] = "禍水",
["sk_huoshui2"] = "禍水",
[":sk_huoshui"] = "回合結束階段，妳可以獲得一名橫置角色的一張牌，然後對一名背面朝上的角色造成一點傷害",
["@sk_huoshui1"] = "妳可以獲得一名橫置角色的一張牌",
["@sk_huoshui2"] = "妳可以對一名背面朝上的角色造成一點傷害",
}

--[[
盧植
經綸：每回合限一次，當你使用或打出牌響應其他角色使用的牌，或其他角色使用或打出牌響應你使用的牌後，你可以獲得其使用的牌或響應的牌
儒宗：你可以將【閃】當成【無懈可擊】使用，或是將【無懈可擊】當成【閃】使用
]]--
sk_luzhiy = sgs.General(extension,"sk_luzhiy","qun",3,true)

sk_jinglun = sgs.CreateTriggerSkill{
	name = "sk_jinglun",
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
					room:setTag("sk_jinglunData", data)
				end
				if use.card:isKindOf("Nullification") then
					if room:getTag("sk_jinglunData") then
						local older_data = room:getTag("sk_jinglunData")
						local older_use = older_data:toCardUse()

						card = older_use.card
						ob = use.card
						to = older_use.from
					end
				end
			else
				local res = data:toCardResponse()
					local older_data = room:getTag("sk_jinglunData")
					local older_use = older_data:toCardUse()

					card = older_use.card
					ob = res.m_card
					to = older_use.from
			end
			if card then
				--card為上次使用卡牌 ob為響應的卡牌 to為被響應的角色
				local all_place_table = true
				for _, id in sgs.qlist(card:getSubcards()) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
					end
				end
				--你使用的卡牌被響應
				if (event ~= sgs.CardResponded or (to and p:objectName() == to:objectName())) and player:objectName() ~= p:objectName() and p:getMark(p:objectName().."_xuezong-Clear") > 0 and p:getMark("sk_jinglun-Clear") == 0 then
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							p:obtainCard(ob)
							room:addPlayerMark(p,"sk_jinglun-Clear")
							room:removePlayerMark(p, self:objectName().."engine")
						end
					end
				end

				--你響應使用的卡牌
				if all_place_table and player:objectName() == p:objectName() and p:getMark("sk_jinglun-Clear") == 0 then
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							p:obtainCard(card)
							room:addPlayerMark(p,"sk_jinglun-Clear")
							room:removePlayerMark(p, self:objectName().."engine")
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

sk_ruzong = sgs.CreateViewAsSkill{
	name = "sk_ruzong",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:isKindOf("Nullification")
			elseif pattern == "nullification" then
				return to_select:isKindOf("Jink")
			end
			return false
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:isKindOf("Jink") then
			new_card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, 0)
		elseif card:isKindOf("Nullification") then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			if #cards == 1 then
				new_card:setSkillName(self:objectName())
			end
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "jink")
				or (pattern == "nullification")
	end,
	enabled_at_nullification = function(self, player)
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isKindOf("Jink") then count = count + 1 end
			if count >= 1 then return true end
		end
	end
}

sk_luzhiy:addSkill(sk_jinglun)
sk_luzhiy:addSkill(sk_ruzong)

sgs.LoadTranslationTable{
	["sk_luzhiy"] = "sk盧植",
	["&sk_luzhiy"] = "盧植",
	["#sk_luzhiy"] = "",
	["sk_jinglun"] = "經綸",
	[":sk_jinglun"] = "每回合限一次，當你使用或打出牌響應其他角色使用的牌，或其他角色使用或打出牌響應你使用的牌後，你可以獲得其使用的牌或響應的牌",
	["sk_ruzong"] = "儒宗",
	[":sk_ruzong"] = "你可以將【閃】當成【無懈可擊】使用，或是將【無懈可擊】當成【閃】使用",

}



--[[
于吉
蠱惑：其他角色的回合開始時，你可以與其拼點，若你贏，其視為對一名你指定的角色使用一張【決鬥】；若你沒贏，其對你造成一點傷害
符籙：當你受到一點傷害後，你可以令最近三名對你造成傷害的角色隨機棄置一張牌，最近三名令你恢復體力的角色摸一張牌

]]--
sk_yuji = sgs.General(extension,"sk_yuji","qun",3,true)

sk_guhuo = sgs.CreateTriggerSkill{
	name = "sk_guhuo" ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if not p or p:objectName() == player:objectName() then return false end
			if (p:isKongcheng() or player:isKongcheng()) then return false end
			local _data = sgs.QVariant()
			_data:setValue(player)
			if room:askForSkillInvoke(p, "sk_guhuo", _data) then
				room:broadcastSkillInvoke(self:objectName())
				local success = p:pindian(player, "sk_guhuo", nil)
				if success then
					local targets = sgs.SPlayerList()
					local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
					for _, pp in sgs.qlist(room:getAlivePlayers()) do
						if not room:isProhibited(player, pp, duel) and p:objectName() ~= pp:objectName() and player:objectName() ~= pp:objectName() then
							targets:append(pp)
						end
					end
					if targets:length() > 0 then
						local s = room:askForPlayerChosen(p, targets, "sk_guhuo", "@liyu:"..player:objectName(), false, true)
						if s then
							room:broadcastSkillInvoke(self:objectName())
							room:doAnimate(1, player:objectName(),s:objectName())
							local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
							duel:setSkillName("sk_guhuo")
							local use = sgs.CardUseStruct()
							use.card = duel
							use.from = player
							local dest = s
							use.to:append(dest)
							room:useCard(use)
						end
					end
				else
					room:damage(sgs.DamageStruct(nil,player,p,1,sgs.DamageStruct_Normal))
				end
			end
		end
		return false
	end
}

sk_fulu = sgs.CreateTriggerSkill{
	name = "sk_fulu",
	events = {sgs.HpRecover, sgs.Damaged},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from then
				local promptlist = player:property("sk_fulu_dmg"):toString():split(":")				
				table.insert(promptlist, damage.from:objectName() )
				if #promptlist > 3 then
					table.remove(promptlist,1)
				end
				room:setPlayerProperty(player, "sk_fulu_dmg", sgs.QVariant( table.concat(promptlist,":") ))
			end
			if player:hasSkill(self:objectName()) then
				room:getThread():delay()
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local dmgpromptlist = player:property("sk_fulu_dmg"):toString():split(":")
					for _, dmger in ipairs(dmgpromptlist) do
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:objectName() == dmger then
								local loot_cards = sgs.QList2Table(p:getCards("he"))
								if #loot_cards > 0 then
									room:doAnimate(1, player:objectName(), p:objectName())
									room:throwCard(loot_cards[math.random(1, #loot_cards)], p,player)
								end
							end
						end
					end
					local recpromptlist = player:property("sk_fulu_rec"):toString():split(":")

					for _, recer in ipairs(recpromptlist) do
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:objectName() == recer then
								room:doAnimate(1, player:objectName(), p:objectName())
								p:drawCards(1)
							end
						end
					end
				end
			end
		else
			local rec = data:toRecover()
			if rec.who then
				local promptlist = player:property("sk_fulu_rec"):toString():split(":")				
				table.insert(promptlist, rec.who:objectName() )
				if #promptlist > 3 then
					table.remove(promptlist,1)
				end
				room:setPlayerProperty(player, "sk_fulu_rec", sgs.QVariant( table.concat(promptlist,":") ))
			end
		end
		return false
	end
}

sk_yuji:addSkill(sk_guhuo)
sk_yuji:addSkill(sk_fulu)

sgs.LoadTranslationTable{
["sk_yuji"] = "sk于吉",
["&sk_yuji"] = "于吉",
["sk_guhuo"] = "蠱惑",
[":sk_guhuo"] = "其他角色的回合開始時，你可以與其拼點，若你贏，其視為對一名你指定的角色使用一張【決鬥】；若你沒贏，其對你造成一點傷害。",
["sk_fulu"] = "符籙",
[":sk_fulu"] = "當你受到一點傷害後，你可以令最近三名對你造成傷害的角色隨機棄置一張牌，最近三名令你恢復體力的角色摸一張牌。",
}

--[[
面殺版本三英神左慈:7體力（暴怒後4體力）
『方術』鎖定技，遊戲開始時，你將6張未加入遊戲的武將牌置入「方術牌」。然後你聲明兩個「方術牌」上記述的技能並亮出對應武將牌。當你暴怒後，你聲明三個「方術牌」上記述且你沒有的技能，並亮出你未亮出的對應武將牌，移去其餘未亮出的「方術牌」。
（其中必有2張各為一組三英神將。你不可以此法聲明技能禁配表上的技能組合。）

左幽:4體力
『部將』鎖定技，遊戲開始時，你亮出五張未加入遊戲的武將牌，聲明其中的一至三個技能並獲得。若你聲明的技能數為1/3，你計算體力上限時加/減一點體力上限。
（你以此法獲得的技能不能是技能禁配表上的技能組合。）
]]--

--配音用白板

sk_zongqing_audio = sgs.CreateTriggerSkill{
	name = "sk_zongqing_audio",
	events = {},
	on_trigger = function()
	end
}
sk_hubu_audio = sgs.CreateTriggerSkill{
	name = "sk_hubu_audio",
	events = {},
	on_trigger = function()
	end
}
if not sgs.Sanguosha:getSkill("sk_zongqing_audio") then skills:append(sk_zongqing_audio) end
if not sgs.Sanguosha:getSkill("sk_hubu_audio") then skills:append(sk_hubu_audio) end

sgs.LoadTranslationTable{
	["sk_zongqing_audio"] = "縱情",
	["sk_hubu_audio"] = "虎步",
}

sgs.Sanguosha:addSkills(skills)