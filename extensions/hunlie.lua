module("extensions.hunlie", package.seeall)
extension = sgs.Package("hunlie")

sgs.LoadTranslationTable{
	["hunlie"] = "魂烈包",
}

local skills = sgs.SkillList()

--神司馬徽
sk_shensimahui = sgs.General(extension,"sk_shensimahui","god","3",true)

--隱世
sk_zhitian = sgs.CreateTriggerSkill{
	name = "sk_zhitian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then				
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart then
				room:broadcastSkillInvoke("sk_zhitian")				
				room:notifySkillInvoked(player,self:objectName())
				local s = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"@sk_zhitianchoose",true,true)
				if s then
					if s:objectName() ~= player:objectName() then
						local n2 = player:wholeHandCards()
						room:obtainCard(s, n2, true)
					end
					GetRandomskill(s,1,1)
				else
					GetRandomskill(player,1,1)						
				end
				room:loseHp(player)		
			end	
		end
		return false
	end
}

--知天
sk_yinshi = sgs.CreateTriggerSkill{
	name = "sk_yinshi",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local n = damage.damage
		room:drawCards(player, n, "sk_yinshi")			
		room:notifySkillInvoked(player, "sk_yinshi")
		room:broadcastSkillInvoke("sk_yinshi")
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
		msg.arg = self:objectName()
		msg.arg2 = logtext
		room:sendLog(msg)
		return true
	end
}

sk_shensimahui:addSkill(sk_yinshi)
sk_shensimahui:addSkill(sk_zhitian)

sgs.LoadTranslationTable{
	["sk_shensimahui"] = "sk神司馬徽",
	["&sk_shensimahui"] = "司馬徽",
	["#sk_shensimahui"] = "水鏡先生",
	["sk_zhitian"] = "知天",
	[":sk_zhitian"] = "<font color=\"blue\"><b>鎖定技，</b></font>回合開始時，你需將所有手牌交給個角色，並令其隨機獲得未加入本局遊戲的武將的一個技能（主公技、覺醒技除外），然後你失去一點體力。",
	["sk_yinshi"] = "隱世",
	[":sk_yinshi"] = "每當你受到一點傷害時，你防止之，改為從牌堆裡摸相當於傷害體力值的牌",
	["@sk_zhitianchoose"] = "選擇一名角色，令其獲得你的所有手牌以及隨機一個技能(未選擇則默認為你自己)",
	["god"] = "神",
}

--（sk神司馬懿）
sk_shensimayi = sgs.General(extension,"sk_shensimayi","god","3",true)
--極略
sk_jilueCard = sgs.CreateSkillCard{
	name = "sk_jilueCard" ,
	target_fixed = true,
	on_use = function(self,room,source,targets)
		room:drawCards(source, 1)
		local pattern = "|.|.|.|."
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("EquipCard") and not source:isLocked(cd)  then
				if cd:isAvailable(source) then
					pattern = "EquipCard,"..pattern
					break
				end
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("Analeptic") and not source:isLocked(cd)  then
				local card = sgs.Sanguosha:cloneCard("Analeptic", cd:getSuit(), cd:getNumber())
				if card:isAvailable(source) then
					pattern = "Analeptic,"..pattern
					break
				end
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("Slash") and not source:isLocked(cd)  then
				local card = sgs.Sanguosha:cloneCard("Slash", cd:getSuit(), cd:getNumber())
				if card:isAvailable(source) then
					for _,p in sgs.qlist(room:getOtherPlayers(source)) do
						if (not sgs.Sanguosha:isProhibited(source, p, cd)) and source:canSlash(p, card, true) then
							pattern = "Slash,"..pattern
							break
						end
					end
				end
				break
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("Peach") and not source:isLocked(cd)  then
				if cd:isAvailable(source) then
					pattern = "Peach,"..pattern
					break
				end
			end
		end
		for _,cd in sgs.qlist(source:getHandcards()) do
			if cd:isKindOf("TrickCard") and not source:isLocked(cd) then
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if not sgs.Sanguosha:isProhibited(source, p, cd) then 
						pattern = "TrickCard+^Nullification,"..pattern
						break
					end
				end
				break
			end
		end
		if pattern ~= "|.|.|.|." then
			local card = room:askForUseCard(source, pattern, "@sk_jilue", -1)
			if not card then
				room:askForDiscard(source, "sk_jilue", 1, 1, false, true)
				room:setPlayerMark(source, "sk_jilue-Clear",1)
			end
		else
			room:askForDiscard(source, "sk_jilue", 1, 1, false, true)
			room:setPlayerMark(source, "sk_jilue-Clear",1)
		end
	end
}

sk_jilue = sgs.CreateZeroCardViewAsSkill{
	name = "sk_jilue",
	view_as = function(self,cards)
		return sk_jilueCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("sk_jilue-Clear") == 0
	end
}
--通天
--通天衍生技能
--反馈（通天）
tongtian_fankui = sgs.CreateTriggerSkill{
	name = "tongtian_fankui",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		if not source then return false end
		if source:isNude() then return false end
		if source and player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke("tongtian_fankui")
			for i = 1, damage.damage do
				if not source:isNude() then
					local card_id = room:askForCardChosen(player, source, "he", self:objectName())
					room:obtainCard(player, card_id, false)
				else
					break
				end
			end
		end
	end
}


--制衡（通天）
tongtian_zhihengCard = sgs.CreateSkillCard{
	name = "tongtian_zhihengCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count)
		end
	end
}

tongtian_zhiheng = sgs.CreateViewAsSkill{
	name = "tongtian_zhiheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local zhiheng_card = tongtian_zhihengCard:clone()
			for _,card in pairs(cards) do
				zhiheng_card:addSubcard(card)
			end
			zhiheng_card:setSkillName(self:objectName())
			return zhiheng_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tongtian_zhihengCard")
	end
}


--觀星（通天）
tongtian_guanxing = sgs.CreateTriggerSkill{
	name = "tongtian_guanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			if player:askForSkillInvoke(self:objectName(), data) then
				local count = room:alivePlayerCount()
				if count > 5 then
					count = 5
				end
				room:broadcastSkillInvoke(self:objectName())
				local cards = room:getNCards(count)
				room:askForGuanxing(player,cards)
			end
		end
	end
}


--完杀（通天）
tongtian_wansha = sgs.CreateTriggerSkill{
	name = "tongtian_wansha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches, sgs.EventPhaseChanging, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local sima = room:getCurrent()
			if sima and sima:isAlive() and sima:hasSkill(self:objectName()) and sima:getPhase() ~= sgs.Player_NotActive then
				if sima:objectName() == player:objectName() then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(sima, self:objectName())
					local log = sgs.LogMessage()
					log.from = sima
					log.arg = self:objectName()
					if dying.who:objectName() ~= sima:objectName() then
						log.type = "#WanshaTwo"
						log.to:append(dying.who)
					else
						log.type = "#WanshaOne"
					end
					room:sendLog(log)
				end
				if dying.who:objectName() ~= player:objectName() and sima:objectName() ~= player:objectName() then
					room:setPlayerMark(player, "Global_PreventPeach", 1)
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
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


if not sgs.Sanguosha:getSkill("tongtian_fankui") then skills:append(tongtian_fankui) end
if not sgs.Sanguosha:getSkill("tongtian_zhiheng") then skills:append(tongtian_zhiheng) end
if not sgs.Sanguosha:getSkill("tongtian_guanxing") then skills:append(tongtian_guanxing) end
if not sgs.Sanguosha:getSkill("tongtian_wansha") then skills:append(tongtian_wansha) end

--通天主技能
sk_tongtianCard = sgs.CreateSkillCard{
	name = "sk_tongtianCard" ,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("sk_shensimayi","sk_tongtian")
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
			local d = c:getSuit()
			if d == sgs.Card_Heart and not source:hasSkill("guanxing") then
					room:acquireSkill(source, "tongtian_guanxing")
	   		elseif d == sgs.Card_Diamond and not source:hasSkill("zhiheng") then
					room:acquireSkill(source, "tongtian_zhiheng")
				elseif d == sgs.Card_Spade and not source:hasSkill("fankui") then
					room:acquireSkill(source, "tongtian_fankui")
				elseif d == sgs.Card_Club and not source:hasSkill("wansha") then
					room:acquireSkill(source, "tongtian_wansha")
			end
		end
		room:removePlayerMark(source, "@tongtian")
	end
}
sk_tongtianVS = sgs.CreateViewAsSkill{
	name = "sk_tongtian" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			local card1 = selected[1]
			if to_select:getSuit() ~= card1:getSuit() then
				return true
			end
		elseif #selected == 2 then
			local card1 = selected[1]
			local card2 = selected[2]
			if to_select:getSuit() ~= card1:getSuit() and to_select:getSuit() ~= card2:getSuit() then
				return true
			end
		elseif #selected == 3 then
			local card1 = selected[1]
			local card2 = selected[2]
			local card3 = selected[3]
			if to_select:getSuit() ~= card1:getSuit() and to_select:getSuit() ~= card2:getSuit() and to_select:getSuit() ~= card3:getSuit()  then
				return true
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = sk_tongtianCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and player:getMark("@tongtian") > 0
	end
}
sk_tongtian = sgs.CreateTriggerSkill{
		name = "sk_tongtian",
		frequency = sgs.Skill_Limited,
		limit_mark = "@tongtian",
		view_as_skill = sk_tongtianVS ,
		on_trigger = function() 
		end
}
sk_shensimayi:addSkill(sk_tongtian)
sk_shensimayi:addSkill(sk_jilue)
sgs.LoadTranslationTable{
	["sk_shensimayi"] = "sk神司馬懿",
	["&sk_shensimayi"] = "司馬懿",
	["#sk_shensimayi"] = "晉國之祖",
	["sk_tongtian"] = "通天",
	["sk_jilue"] = "極略",
	[":sk_tongtian"] = "限定技，出牌階段，你可以棄置任意張手牌，並根據你棄置的手牌的花色獲得以下技能：方塊--制衡，紅心--觀星，黑桃--反饋，梅花--完殺",
	[":sk_jilue"] = "出牌階段，你可以抽一張牌，然後你選擇一項：使用一張牌，或棄置一張牌。若你以此法棄置牌，本回合內你不能再發動此技能",
	["@sk_jilue"] = "請使用一張牌，否則你需棄置一張牌，且本回合內你不能再發動此技能",
	["$sk_jilue1"] = "輕舉妄為，徒招橫禍。",
	["$sk_jilue2"] = "因果有律，世間無常。",
	["$sk_jilue3"] = "萬物無一，強弱有變。",
	["$sk_tongtian"] = "反亂不除，必生枝節。",
["tongtian_fankui"] = "反饋",
[":tongtian_fankui"] = "每當你受到傷害後，你可以獲得來源的一張牌。",
["$tongtian_fankui"] = "逆勢而為，不自量力。",
["tongtian_guanxing"] = "觀星",
[":tongtian_guanxing"] = "準備階段，你可以觀看牌堆頂的X張牌（X為存活角色數且至多為5），將其中任意數量的牌以任意順序置於牌堆頂，其餘以任意順序置於牌堆底。",
["$tongtian_guanxing"] = "吾之身前，萬籟俱靜。",
["tongtian_zhiheng"] = "制衡",
[":tongtian_zhiheng"] = "<font color=\"green\"><b>階段技。</b></font>你可以棄置至少一張牌，然後摸等量的牌。",
["$tongtian_zhiheng"] = "吾之身後，了無生機。",
["tongtian_wansha"] = "完殺",
[":tongtian_wansha"] = "<font color=\"blue\"><b>鎖定技。</b></font>在你的回合，除你以外，只有處於瀕死狀態的角色才能使用【桃】。",
["$tongtian_wansha"] = "狂戰似魔，深謀如鬼。",
}
--神賈詡
sk_shenjiaxu = sgs.General(extension,"sk_shenjiaxu","god","3",true)
--順世
sk_shunshiCard = sgs.CreateSkillCard{
	name = "sk_shunshiCard" ,
	filter = function(self, targets, to_select)
		if #targets > 99 then return false end
		if to_select:hasFlag("sk_shunshiSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			p:setFlags("sk_shunshiTarget")
		end
	end
}
sk_shunshiVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_shunshi" ,
	response_pattern = "@@sk_shunshi",
	view_as = function(self, card)
		return sk_shunshiCard:clone()
	end
}
sk_shunshi = sgs.CreateTriggerSkill{
	name = "sk_shunshi" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = sk_shunshiVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Peach"))
				and use.to:contains(player) and (room:alivePlayerCount() > 2)
				and use.from:objectName() ~= player:objectName() then
			if use.card:isKindOf("Slash") then
				room:setPlayerFlag(player, "sk_shunshiSlash")
			elseif use.card:isKindOf("Peach") then
				room:setPlayerFlag(player, "sk_shunshiPeach")
			end
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = true
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) then
					can_invoke = true
				end
			end
			if can_invoke then
				local prompt = "@sungshi"
				room:setPlayerFlag(use.from, "sk_shunshiSlashSource")
				room:setPlayerProperty(player, "sk_shunshi", sgs.QVariant(use.card:toString()))
				if room:askForUseCard(player, "@@sk_shunshi", prompt, -1, sgs.Card_MethodDiscard) then
					room:setPlayerProperty(player, "sk_shunshi", sgs.QVariant())
					room:setPlayerFlag(use.from, "-sk_shunshiSlashSource")
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					for _, p in sgs.qlist(players) do
						if p:hasFlag("sk_shunshiTarget") then
							p:setFlags("-sk_shunshiTarget")
							use.to:append(p)
							room:drawCards(p, 1, "sk_shunshi")
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
						end
					end
				else
					room:setPlayerProperty(player, "sk_shunshi", sgs.QVariant())
					room:setPlayerFlag(use.from, "-sk_shunshiSlashSource")
				end
			end
		end
		return false
	end
}

--煙滅
sk_yanmieCard = sgs.CreateSkillCard{
	name = "sk_yanmieCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng())
	end,
	on_use = function(self, room, source, targets)	
		local n = targets[1]:getHandcardNum()
		room:throwCard(targets[1]:wholeHandCards(),targets[1])
		room:drawCards(targets[1], n, "sk_yanmie")
		room:showAllCards(targets[1])
		room:setPlayerFlag(targets[1],"sk_yanmie_target")	
	end
}
sk_yanmieVS = sgs.CreateOneCardViewAsSkill{
	name = "sk_yanmie",
	filter_pattern = ".|spade!",
	view_as = function(self,card)
		local ymc = sk_yanmieCard:clone()
		ymc:addSubcard(card)
		ymc:setSkillName("sk_yanmie")
		return ymc
	end,
}

sk_yanmie = sgs.CreateTriggerSkill{
	name = "sk_yanmie",
	view_as_skill = sk_yanmieVS, 
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
				if use.card:objectName() == "sk_yanmieCard" then
				local s
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag("sk_yanmie_target") then
						s = p
					end
				end
				local n2 = 0
				local ids = sgs.IntList()
				for _, card in sgs.qlist(s:getHandcards()) do
					if not card:isKindOf("BasicCard") then
						n2 = n2 + 1
						ids:append(card:getEffectiveId())
					end
				end
				if n2 > 0 then
					local _data = sgs.QVariant()
					_data:setValue(s)
					if room:askForSkillInvoke(player, self:objectName(), _data) then


						local move = sgs.CardsMoveStruct()
						move.card_ids = ids
						move.to = nil
						move.to_place = sgs.Player_DiscardPile
						move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "sk_yanmie", nil)
						room:moveCardsAtomic(move, true)
						local damage = sgs.DamageStruct()
						damage.from = player
						damage.reason = "sk_yanmie"
						damage.damage = n2
						damage.to = s
						room:damage(damage)
						room:setPlayerFlag(s,"-sk_yanmie_target")
					end
				end
			end
		end
		return false
	end,
}


sk_shenjiaxu:addSkill(sk_shunshi)
sk_shenjiaxu:addSkill(sk_yanmie)
sgs.LoadTranslationTable{
	["sk_shenjiaxu"] = "sk神賈詡",
	["&sk_shenjiaxu"] = "賈詡",
	["#sk_shenjiaxu"] = "冷眼下瞰",
	["sk_shunshi"] = "順世",
	["sk_yanmie"] = "煙滅",
	[":sk_shunshi"] = "當你成為其他角色使用【殺】、【桃】或【梅】的目標後，你可以令你與至少一名除該角色外的其他角色各摸一張牌，然後這些角色也成為此牌的目標。",
	[":sk_yanmie"] = "出牌階段，你可以棄置一張黑桃牌，令一名其他角色先棄置所有手牌再摸等量的牌並展示之，然後你可以棄置其中所有非基本牌，並對其造成等量的傷害。",
	["@sungshi"] = "請選擇同樣成為目標的角色",
	["~sk_shunshi"] = "選擇這些角色 -> 點擊「確定」",
["$sk_yanmie1"] = "能救你的人已經不在了！",
["$sk_yanmie2"] = "留你一命，用餘生後悔去吧！",
["$sk_shunshi1"] = "死人，是不會說話的。",
["$sk_shunshi2"] = "此天意，非人力所能左右。",	
}
--貂蟬
sk_shendiaochan = sgs.General(extension,"sk_shendiaochan","god","3",false)
--魅心
sk_meixinCard = sgs.CreateSkillCard{
	name = "sk_meixinCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:isMale()
	end,
	on_use = function(self, room, source, targets)	
		room:setPlayerMark(targets[1], "strmeixin_biu",1)
	end
}

sk_meixinVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_meixin",
	view_as = function(self,cards)
		return sk_meixinCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_meixinCard") < 1
	end
}
sk_meixin = sgs.CreateTriggerSkill{
	name = "sk_meixin",
	view_as_skill = sk_meixinVS,
	events = {sgs.CardUsed,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and player:getPhase() ~= sgs.Player_NotActive then
				if use.card:isKindOf("BasicCard") then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("strmeixin_biu") > 0 then
							if not p:isNude() then
								room:broadcastSkillInvoke("sk_meixin", math.random(1,4))
								local id = room:askForCardChosen(player, p, "he", "sk_meixin")
								room:throwCard(id, p, player)
							end
						end
					end
				end
				if use.card:isKindOf("EquipCard") then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("strmeixin_biu") > 0 then
							if player:isAlive() then
								room:broadcastSkillInvoke("sk_meixin", math.random(1,4))
								room:damage(sgs.DamageStruct(self:objectName(), player, p))
							end
						end
					end
				end
				if use.card:isKindOf("TrickCard") then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("strmeixin_biu") > 0 then
							if not p:isNude() then
								room:broadcastSkillInvoke("sk_meixin", math.random(1,4))
								local id = room:askForCardChosen(player, p, "he", "sk_meixin")
								room:obtainCard(player, id, true)
							end
						end
					end
				end
			end
		end
	end,
}
--天姿
sk_tianzi = sgs.CreateTriggerSkill{
	name = "sk_tianzi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if data:toInt() > 0 then
				if room:askForSkillInvoke(player, "sk_tianzi", data) then
					room:broadcastSkillInvoke("sk_tianzi")
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:isNude() then
							local choice = room:askForChoice(p, "sk_tianzi", "sk_tianzi1+sk_tianzi2")
							if choice == "sk_tianzi1" then
								room:drawCards(player, 1, "sk_tianzi")
							elseif choice == "sk_tianzi2" then
								local id = room:askForCardChosen(p, p, "he", "sk_tianzi")
								room:obtainCard(player, id, true)
							end
						else	
							room:drawCards(player, 1, "sk_tianzi")
						end	
					end
					data:setValue(0)
				end
			end
		end
	end
}


sk_shendiaochan:addSkill(sk_tianzi)				
sk_shendiaochan:addSkill(sk_meixin)

sgs.LoadTranslationTable{
	["sk_shendiaochan"] = "sk神貂蟬",
	["&sk_shendiaochan"] = "貂蟬",
	["#sk_shendiaochan"] = "絕代風華",
	["sk_meixin"] = "魅心",
	[":sk_meixin"] = "摸牌階段限一次，你可以選擇一名其他男性角色，若如此做，本階段當你使用一張基本牌後：你棄置其一張牌，當你使用一張裝備牌後：你對其造成一點傷害，當你使用一張錦囊牌後：你獲得其一張牌",
	["sk_tianzi"] = "天姿",
	[":sk_tianzi"] = "抽牌階段，你可以放棄摸牌，令所有角色選擇一項：1.交給你一張牌，2.令你摸一張牌",
	["sk_tianzi1"] = "令其抽一張牌",
	["sk_tianzi2"] = "給其一張牌",
}
--sk神典韋
sk_shendianwei = sgs.General(extension,"sk_shendianwei","god","6",true)
--擲戟
sk_zhijiCard = sgs.CreateSkillCard{
	name = "sk_zhijiCard", 
	mute = true,
	filter = function(self, targets, to_select) 
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() then return false end--根据描述应该可以选择自己才对
		return true;
	end,
	on_use = function(self, room, source, targets)
		room:damage(sgs.DamageStruct("sk_zhiji", source, targets[1],self:getSubcards():length()))
	end
}
sk_zhijiVS = sgs.CreateViewAsSkill{
	name = "sk_zhiji", 
	n = 99, 
	enabled_at_play = function(self, player)
		return true
	end,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Weapon") and not sgs.Self:isJilei(to_select)
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local card = sk_zhijiCard:clone()
			for i = 1,#cards,1 do
				card:addSubcard(cards[i])
			end
			return card
		end
	end
}
sk_zhiji = sgs.CreateTriggerSkill{
	name = "sk_zhiji",
	events = {sgs.Damaged},
	view_as_skill = sk_zhijiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local DPHeart = sgs.IntList()
		if room:getDrawPile():length() > 0 then
			for _, id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("Weapon") then
					DPHeart:append(id)
				end
			end
		end
		if room:getDiscardPile():length() > 0 then
			for _, id in sgs.qlist(room:getDiscardPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("Weapon") then
					DPHeart:append(id)
				end
			end
		end
		if DPHeart:length() ~= 0 then
			if room:askForSkillInvoke(player, "sk_zhiji", data) then
				room:broadcastSkillInvoke("sk_zhiji",3)
				local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
				local get_card = sgs.Sanguosha:getCard(get_id)
				room:obtainCard(player, get_card)
			end		
		end
	end
}

sk_shendianwei:addSkill(sk_zhiji)

sgs.LoadTranslationTable{
	["sk_shendianwei"] = "sk神典韋",
	["&sk_shendianwei"] = "典韋",
	["#sk_shendianwei"] = "丘巒崩摧",
	["sk_zhiji"] = "擲戟",
	[":sk_zhiji"] = "出牌階段，你可以棄置至少一張武器牌，然後對一名其他角色造成等量的傷害；當你受到傷害時，你可以從棄牌堆或牌堆裡裡隨機獲得一張武器牌",
	["#sk_zhijiDamage"] = "擲戟",
}
--sk神夏候惇
sk_shenxiahoudun = sgs.General(extension,"sk_shenxiahoudun","god","5",true)
--忠睛
sk_zhongjingcard = sgs.CreateSkillCard{
	name = "sk_zhongjingcard" ,
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) 
	end,
	on_use = function(self, room, source, targets)
		targets[1]:setFlags("sk_zhongjingtarget")
		room:loseHp(source)	
		if not targets[1]:isNude() then
			local choice = room:askForChoice(source, "sk_zhongjing", "sk_zhongjing1+sk_zhongjing2")
			if choice == "sk_zhongjing1" then
				room:notifySkillInvoked(source,"sk_zhongjing")
				room:broadcastSkillInvoke("sk_zhongjing",3)
				room:drawCards(targets[1], 3, "sk_zhongjing")
			elseif choice == "sk_zhongjing2" then
				room:notifySkillInvoked(source,"sk_zhongjing")
				room:broadcastSkillInvoke("sk_zhongjing",1)
				room:askForDiscard(targets[1], "sk_zhongjing", 3, 3, false, true)
			end
		else	
			room:drawCards(targets[1], 3, "sk_zhongjing")
		end
		targets[1]:setFlags("-sk_zhongjingtarget")
	end
}

sk_zhongjing = sgs.CreateViewAsSkill{
	name = "sk_zhongjing",
	n = 0,
	view_as = function(self,cards)
		return sk_zhongjingcard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#sk_zhongjingcard")
	end
}

--忠魂
sk_zhonghun = sgs.CreateTriggerSkill{
	name = "sk_zhonghun", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local death = data:toDeath()		
		if death.who:objectName() == player:objectName() then
			local targets = room:getOtherPlayers(player)			
			if targets:length() > 0 then				
				local s = room:askForPlayerChosen(player, targets, "sk_zhonghun", "@sk_zhonghun-die", true)
				if s then
					room:doAnimate(1, player:objectName(), s:objectName())
					room:notifySkillInvoked(player, "sk_zhonghun")
					room:broadcastSkillInvoke("sk_zhonghun")
					local skill_list = player:getVisibleSkillList()
					local skills = {}
					for _,skill in sgs.qlist(skill_list) do
						room:acquireSkill(s, skill)
					end				
				end
			end
		end
		return false
	end, 
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end
}

sk_shenxiahoudun:addSkill(sk_zhongjing)
sk_shenxiahoudun:addSkill(sk_zhonghun)
sgs.LoadTranslationTable{
	["sk_shenxiahoudun"] = "sk神夏侯惇",
	["&sk_shenxiahoudun"] = "夏侯惇",
	["#sk_shenxiahoudun"] = "不滅忠候",
	["sk_zhongjing"] = "忠睛",
	[":sk_zhongjing"] = "出牌階段，你可以失去一點體力，並令一名其他角色摸三張牌或是棄三張牌",
	["sk_zhongjing1"] = "令其抽三張牌",
	["sk_zhongjing2"] = "令其棄三張牌",
	["sk_zhonghun"] = "忠魂",
	[":sk_zhonghun"]= "你死亡时，可令一名其他角色獲得你當前的所有技能。",
	["@sk_zhonghun-die"] = "選擇一名角色，其獲得你當前的所有技能",
}

--神孫權
sk_shensunquan = sgs.General(extension,"sk_shensunquan","god","4",true)
--制衡（虎踞）
hujuzhihengCard = sgs.CreateSkillCard{
	name = "hujuzhihengCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count)
		end
	end
}

hujuzhiheng = sgs.CreateViewAsSkill{
	name = "hujuzhiheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local zhiheng_card = hujuzhihengCard:clone()
			for _,card in pairs(cards) do
				zhiheng_card:addSubcard(card)
			end
			zhiheng_card:setSkillName(self:objectName())
			return zhiheng_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#hujuzhihengCard")
	end
}

if not sgs.Sanguosha:getSkill("hujuzhiheng") then skills:append(hujuzhiheng) end

--虎踞
sk_huju = sgs.CreateTriggerSkill{
	name = "sk_huju" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			for _, pp in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if pp:objectName() ~= player:objectName() then
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(pp, self:objectName())
					room:drawCards(pp, 1, "sk_huju")
				else
					local most_card = true
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getHandcardNum() > player:getHandcardNum() then
							most_card = false
							break	
						end
					end
					if most_card == true then
						local choices = {"hugi_HP", "hugi_Max"}
						local choice = room:askForChoice(player, "sk_huju", table.concat(choices, "+"))
						if choice == "hugi_HP" then
							room:loseHp(player)
						elseif choice == "hugi_Max" then
							room:doSuperLightbox("sk_shensunquan","sk_huju")
							room:loseMaxHp(player)

							room:handleAcquireDetachSkills(player, "sk_hufu|hujuzhiheng|-sk_huju", true)
						end
					end
				end
			end
		end
	end
}

--虎縛
sk_hufuCard = sgs.CreateSkillCard{
	name = "sk_hufuCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) 
	end,
	on_use = function(self, room, source, targets)		
		local n = targets[1]:getEquips():length()
		if n >0 then
			room:askForDiscard(targets[1], "sk_hufu", n, n, false, true)
		end
	end
}

sk_hufu = sgs.CreateZeroCardViewAsSkill{
	name = "sk_hufu",
	view_as = function(self,cards)
		return sk_hufuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sk_hufuCard") < 1
	end
}

if not sgs.Sanguosha:getSkill("sk_hufu") then skills:append(sk_hufu) end

sk_shensunquan:addSkill(sk_huju)
sk_shensunquan:addRelateSkill("sk_hufu")

sgs.LoadTranslationTable{
	["sk_shensunquan"] = "sk神孫權",
	["&sk_shensunquan"] = "孫權",
	["#sk_shensunquan"] = "峰林之上",
	["sk_huju"] = "虎踞",
	[":sk_huju"] = "任意其他角色的回合開始前，你抽一張牌；你的回合開始時，若你的手牌數是全場最多(或之一)你選擇1.失去一點體力2.減一點體力上限，失去技能「虎踞」，獲得技能「制衡」與「虎縛」",
	["hugi_Max"] = "減一點體力上限，並失去技能「虎踞」，獲得技能「制衡」與「虎縛」",
	["hugi_HP"] = "失去一點體力",
	["hujuzhiheng"] = "制衡",
	[":hujuzhiheng"] = "階段技。你可以棄置至少一張牌：若如此做，你摸等量的牌。",
	["sk_hufu"] = "虎縛",
	[":sk_hufu"] = "出牌階段限一次，你可以令一名角色棄置X張牌(X為其裝備區的牌的數量)",
}
--神甘寧
sk_shenganning = sgs.General(extension,"sk_shenganning","god","4",true)
--掠陣
sk_luezhen = sgs.CreateTriggerSkill{
	name = "sk_luezhen", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data) 
		if event == sgs.TargetSpecified then
			local room = player:getRoom()
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(self:objectName(), _data) then
					room:notifySkillInvoked(player, "sk_luezhen")
					room:broadcastSkillInvoke("sk_luezhen")
					local ids = room:getNCards(3)
					room:fillAG(ids)
					room:getThread():delay()
					room:clearAG()
					local n = 0
					for _,id in sgs.qlist(ids) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("BasicCard") then
							n = n + 1				
						end
					end		
					if n > 0 then
						room:doAnimate(1, player:objectName(), p:objectName())
						for i = 1,n,1 do
							if not p:isNude() then
								local id2 = room:askForCardChosen(player, p, "he", "sk_luezhen") 
								room:throwCard(id2, p, player)
								room:getThread():delay(100)
							end
						end
					end
					for _,id in sgs.qlist(ids) do
						local card = sgs.Sanguosha:getCard(id) 
						room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
						player:objectName(), "", "sk_luezhen"), true)
					end
				end
			end
		end
		return false
	end,
}
--遊龍
sk_youlongVS = sgs.CreateOneCardViewAsSkill{
	name = "sk_youlong", 
	filter_pattern = ".|black",
	view_as = function(self, card) 
		local acard = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
		acard:addSubcard(card:getId())
		acard:setSkillName(self:objectName())
		return acard
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("sk_shayi-Clear") > 0
	end, 
}
sk_youlong = sgs.CreateTriggerSkill{
	name = "sk_youlong" ,
	events = {sgs.CardsMoveOneTime} ,
	view_as_skill = sk_youlongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getDrawPile():length() < room:getDiscardPile():length() then
			room:setPlayerMark(player, "sk_youlong_can_use",1)
		else
			room:setPlayerMark(player, "sk_youlong_can_use",0)
		end
	end
}


sk_shenganning:addSkill(sk_luezhen)
sk_shenganning:addSkill(sk_youlong)

sgs.LoadTranslationTable{
	["sk_shenganning"] = "sk神甘寧",
	["&sk_shenganning"] = "甘寧",
	["#sk_shenganning"] = "疾軀斬浪",
	["sk_luezhen"] = "掠陣",
	[":sk_luezhen"] = "當你用「殺」指定目標後，你可以翻開牌堆頂的三張牌，其中每有一張基本牌，你棄置目標的一張牌",
	["sk_youlong"] = "游龍",
	[":sk_youlong"] = "回合開始時，若棄牌堆的牌數多於摸牌堆，你可以將任一張黑色牌當作「順手牽羊」使用",
}
--sk神諸葛
sk_shenzhugeliang = sgs.General(extension, "sk_shenzhugeliang", "god", "3", true)
--七星
function RIGHT(self, player)
	if player and player:isAlive() and player:hasSkill(self:objectName()) then return true else return false end
end

sk_qixingCard = sgs.CreateSkillCard{
	name = "sk_qixingCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local pile = source:getPile("stars")
		local subCards = self:getSubcards()
		local to_handcard = sgs.IntList()
		local to_pile = sgs.IntList()
		local set = source:getPile("stars")
		for _,id in sgs.qlist(subCards) do
			set:append(id)
		end
		for _,id in sgs.qlist(set) do
			if not subCards:contains(id) then
				to_handcard:append(id)
			elseif not pile:contains(id) then
				to_pile:append(id)
			end
		end
		assert(to_handcard:length() == to_pile:length())
		if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then return end
		room:notifySkillInvoked(source, "sk_qixing")
		source:addToPile("stars", to_pile, false)
		local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _,id in sgs.qlist(to_handcard) do
			to_handcard_x:addSubcard(id)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName())
		room:obtainCard(source, to_handcard_x, reason, false)
	end,
}
sk_qixingVS = sgs.CreateViewAsSkill{
	name = "sk_qixing", 
	n = 998,
	response_pattern = "@@sk_qixing",
	expand_pile = "stars",
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getPile("stars"):length() then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getPile("stars"):length() then
			local c = sk_qixingCard:clone()
			for _,card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		end
		return nil
	end,
}
sk_qixing = sgs.CreateTriggerSkill{
	name = "sk_qixing",
	global = true,
	events = {sgs.EventPhaseEnd,sgs.DrawInitialCards,sgs.AfterDrawInitialCards,sgs.EventPhaseStart, sgs.Death, sgs.EventLoseSkill},
	view_as_skill = sk_qixingVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawInitialCards then
			room:sendCompulsoryTriggerLog(player, "sk_qixing")
			data:setValue(data:toInt() + 7)
		elseif event == sgs.AfterDrawInitialCards then
			local exchange_card = room:askForExchange(player, "sk_qixing", 7, 7)
			player:addToPile("stars", exchange_card:getSubcards(), false)
			exchange_card:deleteLater()
		elseif event == sgs.EventPhaseEnd then
			if player:getPile("stars"):length() > 0 and player:getPhase() == sgs.Player_Draw then
				room:broadcastSkillInvoke("sk_qixing")
				room:askForUseCard(player, "@@sk_qixing", "@qixing-exchange", -1, sgs.Card_MethodNone)
			end
		elseif sgs.event == EventPhaseStart or event == sgs.Death then
			local splayer 
			if event == sgs.Death then
				local death = data:toDeath()
				splayer = death.who
			end
			if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) then
				splayer = player
			end
			if splayer then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("gale"..splayer:objectName()) > 0 then
						room:setPlayerMark(p,"@gale",0)
						room:setPlayerMark(p,"gale"..splayer:objectName(),0)
					end
					if p:getMark("fog"..splayer:objectName()) > 0 then
						room:setPlayerMark(p,"@fog",0)
						room:setPlayerMark(p,"fog"..splayer:objectName(),0)
					end
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "sk_qixing" then
			player:clearOnePrivatePile("stars")
		end
		return false
	end,
	can_trigger = function(self, player)
		return player:isAlive() and player:hasSkill(self:objectName())
	end,
}

--狂風
sk_kuangfengCard = sgs.CreateSkillCard{
	name = "sk_kuangfengCard",
	handling_method = sgs.Card_MethodNone,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "sk_kuangfeng", "")
		effect.to:getRoom():throwCard(self, reason, nil)
		effect.from:setTag("sk_qixing_user", sgs.QVariant(true))
		effect.to:gainMark("@gale")
		effect.to:getRoom():setPlayerMark(effect.to,"gale"..effect.from:objectName(),1)
	end,
}
sk_kuangfengVS = sgs.CreateOneCardViewAsSkill{
	name = "sk_kuangfeng", 
	response_pattern = "@@sk_kuangfeng",
	filter_pattern = ".|.|.|stars",
	expand_pile = "stars",
	view_as = function(self, card)
		local kf = sk_kuangfengCard:clone()
		kf:addSubcard(card)
		return kf
	end,
}
sk_kuangfeng = sgs.CreateTriggerSkill{
	name = "sk_kuangfeng",
	events = {sgs.DamageForseen,sgs.EventPhaseStart},
	view_as_skill = sk_kuangfengVS,
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data)
		if event == sgs.DamageForseen then
			if player:getMark("@gale") > 0 then
				local room = player:getRoom()
				local damage = data:toDamage()
				room:broadcastSkillInvoke("sk_kuangfeng")
				local can_invoke = true
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("kuangfeng") or p:hasSkill("jgbiantian") then
						can_invoke  = false
					end
				end
				if damage.nature == sgs.DamageStruct_Fire and can_invoke then
					local msg = sgs.LogMessage()
					msg.type = "#GalePower"
					msg.from = player
					msg.to:append(player)
					msg.arg = damage.damage
					msg.arg2 = damage.damage + 1
					room:sendLog(msg)
					damage.damage = damage.damage + 1
					data:setValue(damage)
				elseif damage.nature == sgs.DamageStruct_Thunder then
					room:askForDiscard(player, "sk_kuangfeng", 2, 2, false, true)
					local msg = sgs.LogMessage()
					msg.type = "#GalePower_thunder"
					msg.from = player
					msg.to:append(player)
					room:sendLog(msg)
				elseif damage.nature == sgs.DamageStruct_Normal then

					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if player:getMark("gale"..p:objectName()) > 0 then
							local ids = room:getNCards(1, false)
							local id = ids:at(0)
							local card = sgs.Sanguosha:getCard(id)
							p:addToPile("stars", card)
							local msg = sgs.LogMessage()
							msg.type = "#GalePower_normal"
							msg.from = p
							msg.to:append(player)
							room:sendLog(msg)
						end
					end
				end
				return false
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:getPile("stars"):length() > 0 and RIGHT(self, player) then
					room:askForUseCard(player, "@@sk_kuangfeng", "@kuangfeng-card", -1, sgs.Card_MethodNone)
				end
			end
		end
	end,
}
--大霧
sk_dawuCard = sgs.CreateSkillCard{
	name = "sk_dawuCard",
	handling_method = sgs.Card_MethodNone,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < self:subcardsLength()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "sk_dawu", "")
		room:throwCard(self, reason, nil)
		source:setTag("sk_qixing_user", sgs.QVariant(true))
		for _,p in ipairs(targets) do
			p:gainMark("@fog")
			room:setPlayerMark(p,"fog"..source:objectName(),1)
		end
	end,
}
sk_dawuVS = sgs.CreateViewAsSkill{
	name = "sk_dawu", 
	n = 998,
	response_pattern = "@@sk_dawu",
	expand_pile = "stars",
	view_filter = function(self, selected, to_select)
		return sgs.Self:getPile("stars"):contains(to_select:getId())
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local dw = sk_dawuCard:clone()
			for _,card in pairs(cards) do
				dw:addSubcard(card)
			end
			return dw
		end
		return nil
	end,
}
sk_dawu = sgs.CreateTriggerSkill{
	name = "sk_dawu",
	events = {sgs.DamageForseen,sgs.EventPhaseStart},
	view_as_skill = sk_dawuVS,
	can_trigger = function(self, player)
		return player ~= nil 
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageForseen then
			local can_invoke = true
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("kuangfeng") or p:hasSkill("jgbiantian") then
					can_invoke  = false
				end
			end
			if can_invoke and player:getMark("@fog") > 0 then
				local damage = data:toDamage()
				if damage.nature ~= sgs.DamageStruct_Thunder then
					room:broadcastSkillInvoke("sk_dawu")
					local msg = sgs.LogMessage()
					msg.type = "#FogProtect"
					msg.from = player
					msg.to:append(player)
					msg.arg = damage.damage
					msg.arg2 = damage.nature
					room:sendLog(msg)
					return true
				else
					return false
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if player:getPile("stars"):length() > 0 and RIGHT(self, player) then
					room:askForUseCard(player, "@@sk_dawu", "@dawu-card", -1, sgs.Card_MethodNone)
				end
			end
		end
	end,
}
sk_shenzhugeliang:addSkill(sk_qixing)
sk_shenzhugeliang:addSkill(sk_kuangfeng)
sk_shenzhugeliang:addSkill(sk_dawu)

sgs.LoadTranslationTable{
["sk_shenzhugeliang"] = "sk神諸葛亮",
["&sk_shenzhugeliang"] = "諸葛亮",
["#sk_shenzhugeliang"] = "赤壁妖術師",
["sk_qixing"] = "七星",
["luaquxing"] = "七星",
[":sk_qixing"] = "分發起始手牌時，共發你十一張牌，你選四張作為手牌，其餘的面朝下置於一旁，稱為“星”；摸牌階段結束時，你可以用任意數量的手牌等量替換這些“星”。",
["sk_kuangfeng"] = "狂風",
["sk_dawu"] = "大霧",
["luakuangfeng"] = "狂風",
["luadawu"] = "大霧",
[":sk_kuangfeng"] = "回合開始階段開始時，你可以將一張“星”置入棄牌堆並選擇一名角色，若如此做，每當該角色於你的下回合開始之前受到：火焰傷害結算開始時，此傷害+1。雷電傷害結算時，你令其棄置兩張牌；普通傷害時，你將牌堆頂置入“星”。",
[":sk_dawu"] = "結束階段開始時，你可以將X張“星”置入棄牌堆並選擇X名角色，若如此做，你的下回合開始前，每當這些角色受到的非雷電傷害結算開始時，防止此傷害。",
["~sk_dawu"] = "點擊目標角色 -> 點擊「確定」",
["~sk_kuangfeng"] = "點擊目標角色 -> 點擊「確定」",
["~sk_qixing"] = "點擊你欲放置於武將牌上成為「星」的牌 -> 點擊「確定」",

["#FogProtect"] = "%from 的“<font color=\"yellow\"><b>大霧</b></font>”效果被觸發，防止了 %arg 點傷害[%arg2] ",
["#GalePower"] = "“<font color=\"yellow\"><b>狂風</b></font>”效果被觸發，%from 的火焰傷害從 %arg 點增加至 %arg2 點",
["#GalePower_thunder"] = "“<font color=\"yellow\"><b>狂風</b></font>”效果被觸發，%from 需棄置兩張牌",
["#GalePower_normal"] = "“<font color=\"yellow\"><b>狂風</b></font>”效果被觸發，%from 獲得一個「星」",
}
--呂蒙
sk_shenlumeng = sgs.General(extension, "sk_shenlumeng", "god", "3", true)
--
sk_shelue = sgs.CreateTriggerSkill{
	name = "sk_shelue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local count = 0
			data:setValue(count)
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase ==  sgs.Player_Draw then
				if not player:isSkipped(sgs.Player_Draw) then
					--player:skip(phase)
					room:broadcastSkillInvoke("sk_shelue")
					local choices = {"TrickCard", "BasicCard", "EquipCard"}
					local ids = room:getDrawPile()
					local choice
					local n1 = 0
					local n2 = 0
					local n3 = 0
					for i = 1, 4, 1 do
						choice = room:askForChoice(player, "sk_shelue", table.concat(choices, "+"))
						if choice == "TrickCard" then
							n1 = n1 + 1
						elseif choice == "BasicCard" then
							n2 = n2 + 1
						elseif choice == "EquipCard" then
							n3 = n3 + 1			
						end
						local msg = sgs.LogMessage()
						msg.type = "#Shulue"
						msg.from = player
						msg.arg = choice
						room:sendLog(msg)
						if not player:getAI() then
							room:getThread():delay(1000)
						end
					end
					local ids_move = sgs.IntList()
					local ids_type1 = sgs.IntList()
					local ids_type2 = sgs.IntList()
					local ids_type3 = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if card:isKindOf("TrickCard") and n1 > 0 then
								ids_type1:append(card:getEffectiveId())
							end
							if card:isKindOf("BasicCard") and n2 > 0  then
								ids_type2:append(card:getEffectiveId())
							end
							if card:isKindOf("EquipCard") and n3 > 0  then
								ids_type3:append(card:getEffectiveId())
							end
							if n1 == 0 and n2 == 0 and n3 == 0 then
								break
							end 
							card:deleteLater()
						end
					end
					if n1 > 0 then
						for i = 1 , n1, 1 do
							if ids_type1:length() > 0 then
								local get_id = ids_type1:at(math.random(1,ids_type1:length())-1)
								ids_type1:removeOne(get_id)
								ids_move:append(get_id)
							end
						end
					end
					if n2 > 0 then
						for i = 1 , n2, 1 do
							if ids_type2:length() > 0 then
								local get_id = ids_type2:at(math.random(1,ids_type2:length())-1)
								ids_type2:removeOne(get_id)
								ids_move:append(get_id)
							end
						end
					end
					if n3 > 0 then
						for i = 1 , n3, 1 do
							if ids_type3:length() > 0 then
								local get_id = ids_type3:at(math.random(1,ids_type3:length())-1)
								ids_type3:removeOne(get_id)
								ids_move:append(get_id)
							end
						end
					end
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids_move
					move.to = player
					move.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(move, true)
				end
			end
		end
	end
}
--sk攻心
sk_gongxinCard = sgs.CreateSkillCard{
	name = "sk_gongxinCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() --如果不想选择没有手牌的角色就加上这一句，源码是没有这句的
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if not effect.to:isKongcheng() then--如果加上了上面的那句，这句和对应的end可以删除
			local ids = sgs.IntList()
			for _, card in sgs.qlist(effect.to:getHandcards()) do
				if card:getSuit() == sgs.Card_Heart then
					ids:append(card:getEffectiveId())
				end
			end
			local card_id = room:doGongxin(effect.from, effect.to, ids)
			if (card_id == -1) then return end
			effect.from:removeTag("sk_gongxin")
			if ids:length() == 1 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, effect.from:objectName(), nil, "sk_gongxin", nil)
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, effect.to, effect.from)
				local damage = sgs.DamageStruct()
				damage.from = effect.from
				damage.reason = "sk_gongxin"
				damage.to = effect.to
				room:damage(damage)
			elseif ids:length() > 1 then
				effect.from:setFlags("Global_GongxinOperator")
				room:obtainCard(effect.from,sgs.Sanguosha:getCard(card_id),true)
				effect.from:setFlags("-Global_GongxinOperator")
			end
		end
	end
}	
sk_gongxin = sgs.CreateZeroCardViewAsSkill{
	name = "sk_gongxin" ,
	view_as = function()
		return sk_gongxinCard:clone()
	end ,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#sk_gongxinCard")
	end
}
sk_shenlumeng:addSkill(sk_shelue)
sk_shenlumeng:addSkill(sk_gongxin)

sgs.LoadTranslationTable{
	["sk_shenlumeng"] = "sk神呂蒙",
	["&sk_shenlumeng"] = "呂蒙",
	["#sk_shenlumeng"] = "聖光國士",
		["sk_shelue"] = "涉略",
		["sk_gongxin"] = "攻心",
		[":sk_shelue"] = "鎖定技，摸牌階段，你摸4張牌，你需依次指定以此法獲得牌的類別，然後從牌堆裡獲得之",
		[":sk_gongxin"] = "出牌階段限一次，你可以展示一名角色的手牌，若該角色的紅心牌數目：為1，你棄置該牌並對其造成1點傷害；大於1，你獲得其中一張",
	["#Shulue"] = "%from <font color=\"yellow\"><b>涉略</b></font>選擇： <font color=\"yellow\"><b> %arg </b></font>",
}
--神趙雲
sk_shenzhaoyun = sgs.General(extension, "sk_shenzhaoyun", "god", "2", true)
--絕境
sk_juejing = sgs.CreateTriggerSkill{
	name = "sk_juejing" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				room:sendCompulsoryTriggerLog(p, self:objectName())
				room:broadcastSkillInvoke("sk_juejing")
				if p:getHp()==1 then
					room:drawCards(p, 1, "sk_juejing")
				elseif p:getHp() > 1 then
					room:loseHp(p)
					room:drawCards(p, 2, "sk_juejing")
				end
			end
		end
	end
}
sk_shenzhaoyun:addSkill(sk_juejing)
sk_shenzhaoyun:addSkill("longhun")

sgs.LoadTranslationTable{
	["sk_shenzhaoyun"] = "sk神趙雲",
	["&sk_shenzhaoyun"] = "趙雲",
	["#sk_shenzhaoyun"] = "神氣如龍",
		["sk_juejing"] = "絕境",
		[":sk_juejing"] = "一名角色的回合結束時，若你的體力值：大於1，你失去一點體力並摸兩張牌；為1，你摸一張牌",
}
--神曹操
sk_shencaocao = sgs.General(extension, "sk_shencaocao", "god", "3", true)
--歸心
sk_guixin = sgs.CreateMasochismSkill{
	name = "sk_guixin" ,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local n = player:getMark("sk_guixinTimes")--这个标记为了ai
		player:setMark("sk_guixinTimes", 0)
		local data = sgs.QVariant()
		data:setValue(damage)
		local players = room:getOtherPlayers(player)
		local n = 0
		for i = 0, damage.damage - 1, 1 do
			player:addMark("sk_guixinTimes")
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke("sk_guixin")
				room:doSuperLightbox("sk_shencaocao","sk_guixin")
				for _, p in sgs.qlist(players) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				player:setFlags("sk_guixinUsing")
				for _, p in sgs.qlist(players) do
					if player:canDiscard(p, "hej") then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						local card_id = room:askForCardChosen(player, p, "hej", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
						room:getThread():delay(100)
					end

				end
				--local n = player:getMark("@fung")
				room:drawCards(player, p:getMark("death_count"), "sk_guixin")
				player:turnOver()
				player:setFlags("-sk_guixinUsing")
			else
				break
			end
		end
		player:setMark("sk_guixinTimes", n)
	end
}
--飛影
sk_feiying = sgs.CreateProhibitSkill{
	name = "sk_feiying",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash")) and not to:faceUp()
	end
}
sk_feiyingTargetMod = sgs.CreateTargetModSkill{
	name = "#sk_feiyingTargetMod",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("sk_feiying") and player:faceUp() then
			return 1000
		end
	end,
}
sk_shencaocao:addSkill(sk_guixin)
sk_shencaocao:addSkill(sk_feiying)
sk_shencaocao:addSkill(sk_feiyingTargetMod)

sgs.LoadTranslationTable{
	["sk_shencaocao"] = "sk神曹操",
	["&sk_shencaocao"] = "曹操",
	["#sk_shencaocao"] = "超世英傑",
		["sk_guixin"] = "歸心",
		[":sk_guixin"] = "每當你受到1点傷害後，你可以依次獲得所有其他角色區域内的一張牌，然後摸x張牌(x為已死亡角色的數量)，再將武將牌翻面。",
		["sk_feiying"] = "飛影",
		[":sk_feiying"] = "鎖定技，當你的武將牌為正面朝上時，你使用「殺」無距離限制；當你的武將牌為背面朝上時，你不能成為「殺」的目標",
}
--神周瑜
sk_shenzhouyu = sgs.General(extension, "sk_shenzhouyu", "god", "4", true)
--琴音
sk_qinyin = sgs.CreateTriggerSkill{
	name = "sk_qinyin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local phase = change.to
		if phase ==  sgs.Player_Discard then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, "sk_qinyin", data) then
				local choices = {"chinyin_losehp", "chinyin_recover"}
				local choice = room:askForChoice(player, "sk_qinyin", table.concat(choices, "+"))
				if choice == "chinyin_losehp" then
					room:drawCards(player, 2, "sk_qinyin")
					room:broadcastSkillInvoke(self:objectName(), 1)
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:doAnimate(1, player:objectName(), p:objectName())
					end
					room:loseHp(player)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						room:loseHp(p)		
					end
				end 
				if choice == "chinyin_recover" then
					room:askForDiscard(player, "sk_qinyin", 2, 2, false, true)
					room:broadcastSkillInvoke(self:objectName(), 2)
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:doAnimate(1, player:objectName(), p:objectName())
					end
					local theRecover2 = sgs.RecoverStruct()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						theRecover2.recover = 1
						theRecover2.who = p
						room:recover(p, theRecover2)	
					end
				end 	
			end
		end
	end
}
--業炎
sk_yeyanCard = sgs.CreateSkillCard{
	name = "sk_yeyanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true 
		elseif #targets == 1 then
			return to_select ~= targets[1]
		elseif #targets == 2 then
			return false
		end
		return false
	end ,
	feasible = function(self, targets)
		return #targets == 1 or #targets == 2
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
		local n2 = 0 
		room:doSuperLightbox("sk_shenzhouyu","sk_yeyan")
		local suit_set = {}
		for _, id in sgs.qlist(self:getSubcards()) do
			local c = sgs.Sanguosha:getCard(id)
	   		if not table.contains(suit_set ,c:getSuit()) then
				table.insert(suit_set ,c:getSuit() )
			end
		end
		if #suit_set < 3 then 
			room:loseHp(source,3)
		end

		room:notifySkillInvoked(source, "sk_yeyan")
		for _, p in ipairs(targets) do
			room:damage(sgs.DamageStruct("sk_yeyan", source, p, #suit_set , sgs.DamageStruct_Fire))
		end
		room:removePlayerMark(source, "@sk_yeiyan")
	end
}
sk_yeyanVS = sgs.CreateViewAsSkill{
	name = "sk_yeyan" ,
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		if #selected == 0 then
			return (not to_select:isEquipped())
		elseif #selected == 1 then
			local card1 = selected[1]
			if to_select:getSuit() ~= card1:getSuit() then
				return (not to_select:isEquipped())
			end
		elseif #selected == 2 then
			local card1 = selected[1]
			local card2 = selected[2]
			if to_select:getSuit() ~= card1:getSuit() and to_select:getSuit() ~= card2:getSuit() then
				return (not to_select:isEquipped())
			end
		elseif #selected == 3 then
			local card1 = selected[1]
			local card2 = selected[2]
			local card3 = selected[3]
			if to_select:getSuit() ~= card1:getSuit() and to_select:getSuit() ~= card2:getSuit() and to_select:getSuit() ~= card3:getSuit()  then
				return (not to_select:isEquipped())
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = sk_yeyanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "h") and player:getMark("@sk_yeiyan") > 0
	end
}
sk_yeyan = sgs.CreateTriggerSkill{
		name = "sk_yeyan",
		frequency = sgs.Skill_Limited,
		limit_mark = "@sk_yeiyan",
		view_as_skill = sk_yeyanVS ,
		on_trigger = function() 
		end
}

sk_shenzhouyu:addSkill(sk_qinyin)
sk_shenzhouyu:addSkill(sk_yeyan)


sgs.LoadTranslationTable{
	["sk_shenzhouyu"] = "sk神周瑜",
	["&sk_shenzhouyu"] = "周瑜",
	["#sk_shenzhouyu"] = "赤壁的火神",
		["sk_qinyin"] = "琴音",
		[":sk_qinyin"] = "棄牌階段開始時，你可以選擇1.摸兩張牌，並令包含你的所有角色失去一點體力，或2.棄置兩張牌，並令包含你的所有角色回復一點體力",
		["sk_yeyan"] = "業炎",
		[":sk_yeyan"] = "限定技，你可以棄置任意張手牌，然後選擇一到兩名角色，你對他們各造成x點火焰傷害(x為你棄置的牌的花色數)，若你以此法棄置的花色數小於三種，你需先失去三點體力",
	["chinyin_losehp"] = "摸兩張牌，並令包含你的所有角色失去一點體力",
	["chinyin_recover"] = "棄置兩張牌，並令包含你的所有角色回復一點體力",
}
--神關羽
sk_shenguanyu = sgs.General(extension, "sk_shenguanyu", "god", "5", true)
--武神
sk_wushen = sgs.CreateFilterSkill{
	name = "sk_wushen", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return ((to_select:isKindOf("Slash") == true) or (to_select:isKindOf("Peach") == true)) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local duel = sgs.Sanguosha:cloneCard("duel", originalCard:getSuit(), originalCard:getNumber())
		duel:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(duel)
		return card
	end
}
--索魂
sk_suohunDamage = sgs.CreateMasochismSkill{
	name = "#sk_suohun" ,
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		room:broadcastSkillInvoke("sk_suohun")
		local data = sgs.QVariant()
		data:setValue(damage)
		from:gainMark("@nightmare",damage.damage)
	end
}
sk_suohun = sgs.CreateTriggerSkill{
	name = "sk_suohun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches,sgs.PreDamageDone},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.AskForPeaches then
			local dying_data = data:toDying()
			local source = dying_data.who
			if source:objectName() == player:objectName() then
				if player:getMaxHp() >= 2 then
					if room:askForSkillInvoke(player, "sk_suohun", data) then
						room:doSuperLightbox("sk_shenguanyu","sk_suohun")
						local maxhp = (player:getMaxHp()+1)/2
						local hp = maxhp
						room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
						room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:getMark("@nightmare") > 0 then
								room:doAnimate(1, player:objectName(), p:objectName())
							end
						end
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:getMark("@nightmare") > 0 then
								local damage = sgs.DamageStruct()
								damage.from = player
								damage.reason = "sk_suohun"
								damage.damage = p:getMark("@nightmare")
								damage.nature = sgs.DamageStruct_Normal
								damage.to = p
								room:damage(damage)
								p:loseAllMarks("@nightmare")
							end
						end		
					end
				end
			end
			return false
		elseif event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.from ~= player then
				room:broadcastSkillInvoke("sk_suohun")
				damage.from:gainMark("@nightmare",damage.damage)
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return true
				end
			end
		end
		return false
	end
}
sk_shenguanyu:addSkill(sk_wushen)
sk_shenguanyu:addSkill(sk_suohun)


sgs.LoadTranslationTable{
	["sk_shenguanyu"] = "sk神關羽",
	["&sk_shenguanyu"] = "關羽",
	["#sk_shenguanyu"] = "鬼神再臨",
		["sk_suohun"] = "索魂",
		[":sk_suohun"] = "鎖定技，每當你受到1點傷害後，傷害來源(除你以外)獲得一個“夢魘”標記。當你進入瀕死狀態時，減一半(向上取整)的體力上限並回復體力至體力上限，擁有“夢魘”標記的角色依次棄置所有的“夢魘”標記，然後受到與棄置的“夢魘”標記數量相同的傷害。",
		["sk_wushen"] = "武神",
		[":sk_wushen"] = "你的「殺」與「桃」均視為「決鬥」",
}
--神呂布
sk_shenlubu = sgs.General(extension, "sk_shenlubu", "god", "5", true)

--狂暴
sk_kuangbao = sgs.CreateTriggerSkill{
	name = "sk_kuangbao" ,
	events = {sgs.GameStart, sgs.Damage, sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			player:gainMark("@wrath", 2)
		else
			local damage = data:toDamage()
			if damage.damage > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				if event == sgs.Damage and player:getMark("sk_wuqian-Clear") > 0 then
					player:gainMark("@wrath", damage.damage*2)
				else
					player:gainMark("@wrath", damage.damage)
				end
			end
		end
	end
}

--無謀
sk_wumou = sgs.CreateTriggerSkill{
	name = "sk_wumou" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isNDTrick() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local num = player:getMark("@wrath")
			if num >= 1 and room:askForChoice(player, self:objectName(), "wumoulosemark+wumoudamage") == "wumoulosemark" then
				player:loseMark("@wrath")
			else
				room:damage(sgs.DamageStruct(nil,nil,player,1,sgs.DamageStruct_Normal))
			end
		end
		return false
	end
}
--無前
sk_wuqianCard = sgs.CreateSkillCard{
	name = "sk_wuqianCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@wrath", 2)
		room:acquireSkill(source, "wushuang")
		room:addPlayerMark(source, "wushuang_skillClear")
		room:addPlayerMark(source, "sk_wuqian-Clear")
	end
}
sk_wuqian = sgs.CreateZeroCardViewAsSkill{
	name = "sk_wuqian" ,
	view_as = function()
		return sk_wuqianCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@wrath") >= 2
	end
}
--神憤
sk_shenfenCard = sgs.CreateSkillCard{
	name = "sk_shenfenCard" ,
	target_fixed = true ,
	on_use = function(self, room, source, targets)
		source:setFlags("sk_shenfenUsing")
		source:loseMark("@wrath", 6)
		room:doSuperLightbox("sk_shenlubu","sk_shenfen")
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@nightmare") > 0 then
				room:doAnimate(1, player:objectName(), p:objectName())
			end
		end
		local players = room:getOtherPlayers(source)
		for _, player in sgs.qlist(players) do
			room:damage(sgs.DamageStruct("sk_shenfen", source, player))
		end
		for _, player in sgs.qlist(players) do
			player:throwAllHandCardsAndEquips()
		end
		source:turnOver()
		source:setFlags("-sk_shenfenUsing")
	end
}
sk_shenfen = sgs.CreateZeroCardViewAsSkill{
	name = "sk_shenfen",
	view_as = function()
		return sk_shenfenCard:clone()
	end , 
	enabled_at_play = function(self,player)
		return player:getMark("@wrath") >= 6 and not player:hasUsed("#sk_shenfenCard")
	end
}
sk_shenlubu:addSkill(sk_kuangbao)
sk_shenlubu:addSkill(sk_wumou)
sk_shenlubu:addSkill(sk_shenfen)
sk_shenlubu:addSkill(sk_wuqian)

sgs.LoadTranslationTable{
	["sk_shenlubu"] = "sk神呂布",
	["&sk_shenlubu"] = "呂布",
	["#sk_shenlubu"] = "修羅之道",
	["sk_kuangbao"] = "狂暴",
	[":sk_kuangbao"] = "鎖定技。遊戲開始時，你獲得兩枚“暴怒”標記。每當你造成或受到1點傷害後，你獲得一枚“暴怒”標記。",
	["sk_wumou"] = "無謀",
	[":sk_wumou"] = "每當你使用一張非延時錦囊牌時，你須選擇一項：受到1點傷害，或棄一枚“暴怒”標記。 ",
	["sk_shenfen"] = "神憤",
	[":sk_shenfen"] = "出牌階段限一次，你可以棄六枚“暴怒”標記：若如此做，所有其他角色受到1點傷害，棄置裝備區的所有牌與所有手牌，然後你將武將牌翻面。",
	["wumoulosemark"] = "失去一點暴怒標記",
	["wumoudamage"] = "受到一點傷害",
	["sk_wuqian"] = "無前",
	[":sk_wuqian"] = "出牌階段，你可以棄兩枚“暴怒”標記，若如此做，本回合內你擁有技能“無雙”且你造成傷害時額外獲得一個“暴怒”標記",
}
--神劉備
sk_shenliubei = sgs.General(extension, "sk_shenliubei", "god", "4", true)
--君望
sk_junwang = sgs.CreateTriggerSkill{
	name = "sk_junwang" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p and p:objectName() ~= player:objectName() and p:getHandcardNum() < player:getHandcardNum() then
					room:doAnimate(1, p:objectName(), player:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					local card = room:askForCard(player, ".!", "@sk_pudu-give:"..p:objectName(), data, sgs.Card_MethodNone)
					if not card then
						local pile = player:getHandcards()
						local length = pile:length()
						local n = math.random(1, length)
						local id = pile:at(n - 1)
						room:obtainCard(p, id, false)
					else
						room:obtainCard(p, card, false)
					end
				end
			end
		end
	end
}
--激詔
sk_jizhaoCard = sgs.CreateSkillCard{
	name = "sk_jizhaoCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getMark("@zao") == 0)
	end,
	on_use = function(self, room, source, targets)	
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "sk_jizhao","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		targets[1]:gainMark("@zao",1)
	end
}

sk_jizhaoVS = sgs.CreateViewAsSkill{
	name = "sk_jizhao",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		return (not to_select:isEquipped())
	end ,
	view_as = function(self,cards)
		if #cards == 0 then return nil end
		local card = sk_jizhaoCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self,player)
		return true 
	end
}
sk_jizhao = sgs.CreateTriggerSkill{
	name = "sk_jizhao" ,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = sk_jizhaoVS,
	events = {sgs.EventPhaseStart,sgs.DamageInflicted} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then				
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("@zao") > 0 then
						room:damage(sgs.DamageStruct(self:objectName(), p,player))
						player:loseAllMarks("@zao")
						break
					end					
				end
			end
			return false
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:getMark("@zao") > 0 then
				damage.from:loseAllMarks("@zao")
			end
		end
	end
}

sk_shenliubei:addSkill(sk_junwang)
sk_shenliubei:addSkill(sk_jizhao)

sgs.LoadTranslationTable{
	["sk_shenliubei"] = "sk神劉備",
	["&sk_shenliubei"] = "劉備",
	["#sk_shenliubei"] = "烈龍之怒",
		["sk_junwang"] = "君望",
		[":sk_junwang"] = "鎖定技，一名角色的出牌階段開始時，若其手牌數大於你，其須交給你一張手牌",
		["sk_jizhao"] = "激詔",
		["@sk_zao"] = "詔",
		[":sk_jizhao"] = "出牌階段對每名角色限一次，你可以交給其至少一張手牌並令其獲得一個「詔」標記；擁有「詔」標記的武將回合結束時，若其沒有造成傷害，其受到你對其造成的一點傷害",
}
--神張飛
sk_shenzhangfei = sgs.General(extension, "sk_shenzhangfei", "god", "4", true)
--殺意
sk_shayiVS = sgs.CreateOneCardViewAsSkill{
	name = "sk_shayi",
	response_or_use = true,
	view_filter = function(self, card)
		if not card:isBlack() then return false end
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
		return sgs.Slash_IsAvailable(player) and player:getMark("sk_shayi-Clear") > 0
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and player:getMark("sk_shayi-Clear") > 0
	end
}

sk_shayi = sgs.CreateTriggerSkill{
	name = "sk_shayi",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = sk_shayiVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Start then
			local cards = player:getHandcards()
			room:showAllCards(player)
			local has_slash = false
			for _, card in sgs.qlist(cards) do
				if card:isKindOf("Slash") then
					has_slash = true
					break
				end
			end
			if has_slash == true then
				room:drawCards(player, 1, "sk_shayi")
			else
				room:setPlayerMark(player, "sk_shayi-Clear",1)
			end
		end
	end
}
sk_shayiTargetMod = sgs.CreateTargetModSkill{
	name = "#sk_shayiTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("sk_shayi") then
			return 1000
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill("sk_shayi") then
			return 1000
		end
	end,
}
--震魂
sk_zhenhun = sgs.CreateTriggerSkill{
	name = "sk_zhenhun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then --回合开始时
			if player:getPhase() == sgs.Player_Play and (not player:isNude()) then 
				local card = room:askForCard(player, ".,Equip", "@sk_zhenhun-invoke", data, sgs.CardDiscarded)
				if card then
					room:broadcastSkillInvoke(self:objectName())
					for _, dest in sgs.qlist(room:getOtherPlayers(player)) do
						room:setPlayerMark(dest, "skill_invalidity-Clear",1)
						room:setPlayerMark(dest, "@skill_invalidity",1)
						room:filterCards(dest,dest:getCards("he"),true)
	--					for _,skill in sgs.qlist(dest:getVisibleSkillList())do
	--						room:addPlayerMark(dest,"Qingcheng"..skill:objectName())
	--					end
					end
				end
			end
		end
	end
}

sk_shenzhangfei:addSkill(sk_shayi)
sk_shenzhangfei:addSkill(sk_shayiTargetMod)
sk_shenzhangfei:addSkill(sk_zhenhun)


sgs.LoadTranslationTable{
	["sk_shenzhangfei"] = "sk神張飛",
	["&sk_shenzhangfei"] = "張飛",
	["#sk_shenzhangfei"] = "橫掃千軍",
		["sk_shayi"] = "殺意",
		[":sk_shayi"] = "鎖定技，回合開始時，你需展示所有手牌：若其中有「殺」，你摸一張牌；若其中沒有「殺」，則本回合你可以將任一張黑色牌當「殺」使用，你使用「殺」無距離限制，無數量限制",
		["sk_zhenhun"] = "震魂",
		[":sk_zhenhun"] = "出牌階段開始時，你可以棄置一張牌，令所有角色的非鎖定技於本回合內失效",
	["@sk_zhenhun-invoke"] = "你可以棄置一張牌，令所有角色的非鎖定技失效",
}
--神香香
sk_shensunshangxiang = sgs.General(extension, "sk_shensunshangxiang", "god", "3", false)
--賢助
sk_xianzhu = sgs.CreateTriggerSkill{
	name = "sk_xianzhu",
	events  = {sgs.HpRecover,sgs.CardsMoveOneTime},
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			if not player:isAlive() then return false end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("sk_xianzhu") then
					local _data = sgs.QVariant()
					_data:setValue(player)
					if room:askForSkillInvoke(p, self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName(),2)
						room:drawCards(player, 2, "sk_xianzhu")
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
				for i = 0, move.card_ids:length() - 1, 1 do
					if not player:isAlive() then return false end
					if move.from_places:at(i) == sgs.Player_PlaceEquip then
						if not player:isAlive() then return false end
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasSkill("sk_xianzhu") then
								local _data = sgs.QVariant()
								_data:setValue(player)
								if room:askForSkillInvoke(p, self:objectName(), _data) then
									room:broadcastSkillInvoke(self:objectName(),1)
									player:drawCards(2)
								else
									break
								end
							end
						end
					end
				end
			end
			return false
		end
	end
}
--良緣
sk_liangyuanCard = sgs.CreateSkillCard{
	name = "sk_liangyuan" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:isMale() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)		
		room:removePlayerMark(source, "@lianyuan")
		room:doSuperLightbox("sk_shensunshangxiang","sk_liangyuan")
		room:setPlayerMark(targets[1], "lianyuan_extra", 1)
	end
}
sk_liangyuanVS = sgs.CreateZeroCardViewAsSkill{
	name = "sk_liangyuan",
	view_as = function(self,cards)
		return sk_liangyuanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@lianyuan") > 0
	end
}
sk_liangyuan = sgs.CreatePhaseChangeSkill{
	name = "sk_liangyuan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@lianyuan",
	view_as_skill = sk_liangyuanVS ,
	priority = 1 ,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive and not room:getTag("ExtraTurn"):toBool() then
			local s
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("lianyuan_extra") == 1 then
					s = p
					break
				end
			end	
			if s then
				--room:broadcastSkillInvoke(self:objectName())
				room:setTag("ExtraTurn",sgs.QVariant(true))
				s:gainAnExtraTurn()
				room:setTag("ExtraTurn",sgs.QVariant(false))
			end
		end
		return false
	end ,
}

sk_shensunshangxiang:addSkill(sk_xianzhu)
sk_shensunshangxiang:addSkill(sk_liangyuan)
sgs.LoadTranslationTable{
	["sk_shensunshangxiang"] = "sk神孫尚香",
	["&sk_shensunshangxiang"] = "孫尚香",
	["#sk_shensunshangxiang"] = "弓腰姬",
	["sk_xianzhu"] = "賢助",
	["$sk_xianzhu1"] = "春風復多情，吹我羅裳開。",
	["$sk_xianzhu2"] = "春林花多媚，春鳥意多哀。",
	[":sk_xianzhu"] = "當一名角色回復體力後，或失去裝備區裡的牌後，妳可以令其摸兩張牌。",
	["sk_liangyuan"] = "良緣",
	["$sk_liangyuan"] = "我心如松柏，君情復何似？",
	[":sk_liangyuan"] = "限定技，出牌階段，妳可以選擇一名其他男性角色，則於本局遊戲中，妳的自然回合結束時，該角色進行一個額外的回合。",
	["~sk_shensunshangxiang"] = "夫君，你可會記得我的好？",
}

--神郭嘉
sk_shenguojia = sgs.General(extension,"sk_shenguojia","god", "3", true)
--天啟


sk_tianqi_select = sgs.CreateSkillCard{
	name = "sk_tianqi", 
	will_throw = false, 
	target_fixed = true, 
	handling_method = sgs.Card_MethodNone, 
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
--		for _, name in ipairs(patterns) do
--			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
--			poi:setSkillName("sk_tianqi")
--			poi:addSubcard(self:getSubcards():first())
--			if poi:isAvailable(source) and source:getMark("sk_tianqi"..name) == 0 and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
--				table.insert(choices, name)
--			end
--		end
		
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("AG_BANCard"..card:objectName()) == 0 and (card:isKindOf("BasicCard") or card:isNDTrick()) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "sk_tianqi", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("sk_tianqi")
					--poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "sk_tianqipos", pos)
					--room:setPlayerProperty(source, "sk_tianqi", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@sk_tianqi", "@sk_tianqi:"..pattern)--%src
				end
			end
		end
	end,
}
sk_tianqiCard = sgs.CreateSkillCard{
	name = "sk_tianqiCard", 
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
			local name = room:askForChoice(user, "sk_tianqi", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		--use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("sk_tianqi")
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
			local name = room:askForChoice(card_use.from, "sk_tianqi", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("sk_tianqi")
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
sk_tianqiVS = sgs.CreateViewAsSkill{
	name = "sk_tianqi",
	n = 0,
	response_or_use = true,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local acard = sk_tianqi_select:clone()
			return acard
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then 
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = sk_tianqiCard:clone()
			if pattern and pattern == "@@sk_tianqi" then
				pattern = patterns[sgs.Self:getMark("sk_tianqipos")]
				--acard:addSubcard(sgs.Self:property("sk_tianqi"):toInt())
			else
			end
			if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then 
				pattern = "analeptic" 
			end
			acard:setUserString(pattern)
			return acard
		end
	end, 
	enabled_at_play = function(self, player)
		local choices = {}
		local patterns = generateAllCardObjectNameTablePatterns()
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) then
				table.insert(choices, name)
			end
		end
		if player:getHp() <= 0 then
			return false
		end
		return next(choices) and (player:getMark("sk_tianqi-Clear") == 0 or player:getPhase() == sgs.Player_NotActive)
	end, 
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		if player:getHp() <= 0 then
			return false
		end
		return (player:getMark("sk_tianqi-Clear") == 0 or player:getPhase() == sgs.Player_NotActive)
	end, 
	enabled_at_nullification = function(self, player, pattern)
		return player:getHp() > 0 and (player:getMark("sk_tianqi-Clear") == 0 or player:getPhase() == sgs.Player_NotActive)
	end
} 
sk_tianqi = sgs.CreateTriggerSkill{
	name = "sk_tianqi", 
	view_as_skill = sk_tianqiVS, 
	events = {sgs.PreCardUsed, sgs.CardResponded}, 
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
			if card and card:getSkillName() == "sk_tianqi" and card:getTypeId() ~= 0 then
				if player:getPhase() ~= sgs.Player_NotActive then
					room:addPlayerMark(player,"sk_tianqi-Clear")
				end
				local types = {"BasicCard", "TrickCard", "EquipCard"}
				table.removeOne(types,types[card:getTypeId()])
				room:removeTag("sk_tianqiType")

				local ids = room:getNCards(1, false)
				local id = ids:at(0)
				local showcard = sgs.Sanguosha:getCard(id)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				if card:getTypeId() ~= showcard:getTypeId() then
					room:loseHp(player)
				end
			end
		end
	end
}
--天機
sk_tianji=sgs.CreateTriggerSkill{
name="sk_tianji",
events=sgs.EventPhaseStart,
frequency=sgs.Skill_Frequent,
on_trigger=function(self,event,player,data)
	if player:getPhase()~=sgs.Player_Play then return false end
	local room=player:getRoom()
	local s=room:findPlayerBySkillName(self:objectName())
	if not s then return false end
	if not s:askForSkillInvoke(self:objectName(),data) then return false end
	room:broadcastSkillInvoke(self:objectName())
	local ids=sgs.IntList()
	local drawpile=room:getDrawPile()
	drawpile=sgs.QList2Table(drawpile)
	local id=drawpile[1]
	ids:append(id)
	room:fillAG(ids,s)
	room:getThread():delay()
	local flag=false
	local x=s:getHandcardNum()
	local choices={"sk_tianjitihuan","sk_tianjiget","cancel"}
	for _,p in sgs.qlist(room:getOtherPlayers(s)) do
		if p:getHandcardNum()>x then
			flag=true
			break
		end
	end
	if s:isKongcheng() then
		table.removeOne(choices,"sk_tianjitihuan")
	end
	if flag==false then
		table.removeOne(choices,"sk_tianjiget")
	end
	local choice=room:askForChoice(s,self:objectName(),table.concat(choices,"+"))
	if choice=="sk_tianjitihuan" then
		--local cards=room:askForExchange(s,self:objectName(),1,false,"Sgkgodtianjicard")
		--card_id=cards:getSubcards():first()
		--local move=sgs.CardsMoveStruct()
		--move.card_ids:append(card_id)
		--move.to_place=sgs.Player_DrawPile
		--move.reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,s:objectName(),self:objectName(),"")
		--room:moveCardsAtomic(move,true)
		--room:obtainCard(s,id,false)
		room:obtainCard(s,id,false)
		local id5 = room:askForCard(s, ".!", "Sgkgodtianjicard", sgs.QVariant(), sgs.Card_MethodNone)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, s:objectName(), nil, "sk_tianji", nil)
		room:moveCardTo(id5, s, nil, sgs.Player_DrawPile, reason, true)
	elseif choice=="sk_tianjiget" then
		room:obtainCard(s,id,false)
	end
	room:clearAG()
end,
can_trigger=function()
	return true
end
}

sk_shenguojia:addSkill(sk_tianqi)
sk_shenguojia:addSkill(sk_tianji)

sgs.LoadTranslationTable{
["sk_shenguojia"]="sk神郭嘉",
["&sk_shenguojia"]="郭嘉",
["#sk_shenguojia"]="天人合一",
["sk_tianqi"]="天啟",
[":sk_tianqi"]="每當你需要使用或打出一張基本牌或非延時類錦囊牌時，若你不處於瀕死狀態，你可以聲明之，然後亮出牌堆頂的一張牌，然後將此牌當你聲明的牌使用或打出，若此牌與你聲明的牌類型不同，你須先失去1點體力。（<font color=\"green\"><b>你的出牌階段限一次</b></font>）",
["$sk_tianqicard"]="%from 亮出了牌堆頂的 %card",

["#sk_tianqishengming"]="%from 聲明了 【%arg】",
["@sk_tianqi"] = "請選擇目標",
["~sk_tianqi"] = "選擇若干名角色→點擊確定",

["sk_tianji"]="天機",
[":sk_tianji"]="每當一名角色的出牌階段開始時，你可以觀看牌堆頂的一張牌，然後你可以選擇一項：1.用一張手牌替換之；2.若你的手牌數不是全場最多的(或之一)，你可以獲得之。",
["sk_tianjitihuan"]="用一張手牌替換之",
["sk_tianjiget"]="獲得之",
["Sgkgodtianjicard"]="請選擇用於交換的手牌",
["$sk_tianqi1"]="盪破天光，領得天啟！",
["$sk_tianqi2"]="謀事在人，成事在天。",
["$sk_tianji"]="天機可知卻不可說。",
["~sk_shenguojia"]="窺天意，竭心力，皆為吾主！",
["designer:sk_shenguojia"]="網路神人",
["illustrator:sk_shenguojia"]="網路神人",
["cv:sk_shenguojia"]="網路神人",
}


--神黄月英
sk_shenhuangyueying = sgs.General(extension,"sk_shenhuangyueying","god","3",false)
--知命
function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end


sk_zhiming = sgs.CreateTriggerSkill{
	name = "sk_zhiming",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()~=sgs.Player_Start then return false end
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:objectName() ~= player:objectName() and not player:isKongcheng() and p:canDiscard(p,"h") then
				local card = room:askForCard(p,".|.|.|hand","@sk_zhiming",data,self:objectName())
				if card then
					room:broadcastSkillInvoke(self:objectName())
					local ids = getIntList(player:getHandcards())
					local id = ids:at(math.random(0, ids:length() - 1))
					room:showCard(player, id)

					room:throwCard(id,player,p)
					if GetColor(card) == GetColor(sgs.Sanguosha:getCard(id)) then
						local choice = room:askForChoice(p,self:objectName(),"sk_zhimingdraw+sk_zhimingplay+cancel")
						if choice == "sk_zhimingdraw" then
							player:skip(sgs.Player_Draw)
						elseif choice == "sk_zhimingplay" then
							player:skip(sgs.Player_Play)
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

sk_suyin = sgs.CreateTriggerSkill{
	name="sk_suyin",
	events = {sgs.CardsMoveOneTime},
	on_trigger=function(self,event,player,data,room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName()==player:objectName() then
			if move.from_places:contains(sgs.Player_PlaceHand) then
				if move.is_last_handcard then
					if player:getPhase() == sgs.Player_NotActive then
						local s = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"sk_suyin-invoke",true,true)
						if s then
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							s:turnOver()
						end
					end
				end
			end
		end
	end
}

sk_shenhuangyueying:addSkill(sk_zhiming)
sk_shenhuangyueying:addSkill(sk_suyin)

sgs.LoadTranslationTable{
["sk_shenhuangyueying"]="sk神黃月英",
["&sk_shenhuangyueying"]="黃月英",
["#sk_shenhuangyueying"]="夕風霞影",
["sk_zhiming"]="知命",
[":sk_zhiming"]="每當一名其他角色的準備階段開始時，若其有手牌，你可以棄置一張手牌，然後棄置其一張手牌，若兩張牌顏色相同，你令其跳過此回合的摸牌階段或出牌階段。",
["@sk_zhiming"]="你可以棄置一張手牌發動“知命”",
["sk_zhimingdraw"]="摸牌階段",
["sk_zhimingplay"]="出牌階段",
["sk_suyin"]="夙隱",
[":sk_suyin"]="回合外，每當你失去最後的手牌後，你可令一名其他角色將其武將牌翻面。",
["sk_suyin-invoke"]="你可令一名其他角色將其武將牌翻面",
["$sk_zhiming"]="風起日落,天行有常。",
["$sk_suyin"]="欲別去歸隱,無負奢望。",
["~sk_shenhuangyueying"]="只盼明日，能共沐晨光……",
["designer:sk_shenhuangyueying"]="網路神人",
["illustrator:sk_shenhuangyueying"]="網路神人",
["cv:sk_shenhuangyueying"]="網路神人",
}

--神張角

sk_shenzhangjue = sgs.General(extension,"sk_shenzhangjue","god","3", true)

--電界
	  
sk_dianjie = sgs.CreateTriggerSkill{
	name = "sk_dianjie",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data,room)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Draw and change.to ~= sgs.Player_Play then return false end
		if player:isSkipped(change.to) then return false end

		if change.to == sgs.Player_Draw then
			if not player:askForSkillInvoke("sk_dianjie_draw",data) then return false end
		else
			if not player:askForSkillInvoke("sk_dianjie_play",data) then return false end
		end

		--if not player:askForSkillInvoke(self:objectName(),data) then return false end

		if change.to == sgs.Player_Draw then
			room:broadcastSkillInvoke(self:objectName(),1)
		else
			room:broadcastSkillInvoke(self:objectName(),2)
		end
		player:skip(change.to)
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.reason = self:objectName()
		room:judge(judge)
		if judge.card:isBlack() then 
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "sk_dianjie1", "@sk_dianjie-damage", true)
			if s then
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), s:objectName())
				room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))
			end
		else
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isChained() then
					_targets:append(p) 
				end
			end
			if not _targets:isEmpty() then
				local s = room:askForPlayerChosen(player, _targets, "sk_dianjie2", "@sk_dianjie-chain", true)
				if s then
					room:doAnimate(1, player:objectName(), s:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerProperty(s, "chained", sgs.QVariant(true))
				end
			end
		end
	end
}
--神道
sk_shendao = sgs.CreateTriggerSkill{
	name ="sk_shendao",
	events = {sgs.AskForRetrial},
	on_trigger = function(self ,event, player, data, room)
		local judge = data:toJudge()
		local ids = sgs.IntList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, card in sgs.qlist(p:getCards("ej")) do
				ids:append(card:getEffectiveId())
			end
		end

			for _, card in sgs.qlist(player:getCards("h")) do
				ids:append(card:getEffectiveId())
			end

		local prompt_list = {
			"@shenpin-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
		}

		room:setTag("sk_shendaoData", data)
		local prompt = table.concat(prompt_list, ":")

		if ids:length() > 0 then
			room:fillAG(ids)
			local card_id = room:askForAG(player, ids, true, self:objectName())
			if card_id ~= -1 then
				room:retrial( sgs.Sanguosha:getCard(card_id) , player, judge, self:objectName())
			end
			room:clearAG()
		end
		room:removeTag("sk_shendaoData")
	end
}

sk_leihun = sgs.CreateTriggerSkill{
	name = "sk_leihun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Thunder then return false end
		local log = sgs.LogMessage()
		log.from = player
		log.arg = self:objectName()
		log.type = "#TriggerSkill"
		room:sendLog(log)
		room:notifySkillInvoked(player,self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		if player:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.recover = math.min(damage.damage,player:getLostHp())
			room:recover(player,recover)
		end
		return true
	end
}

sk_shenzhangjue:addSkill(sk_dianjie)
sk_shenzhangjue:addSkill(sk_shendao)
sk_shenzhangjue:addSkill(sk_leihun)

sgs.LoadTranslationTable{
["sk_shenzhangjue"]="sk神張角",
["&sk_shenzhangjue"]="張角",
["#sk_shenzhangjue"]="雷霆萬鈞",
["sk_dianjie"]="電界",
["sk_dianjie1"]="電界",
["sk_dianjie2"]="電界",
["sk_dianjie_draw"]="電界，跳過摸牌階段",
["sk_dianjie_play"]="電界，跳過出牌階段",

[":sk_dianjie"]="你可以跳過你的摸牌階段或出牌階段，然後判定：若結果為黑色，你對一名角色造成1點雷電傷害；若結果為紅色，你令至多兩名武將牌未橫置的角色將其武將牌橫置。",

["@sk_dianjie-damage"] = "你可以對ㄧ名角色造成1點傷害",
["@sk_dianjiechain"] = "你可以讓一名角色進入“連環”狀態。",

["sk_shendao"]="神道",
[":sk_shendao"]="一名角色的判定牌生效前，你可以用一張手牌或場上的牌代替之。",
["sk_leihun"]="雷魂",
[":sk_leihun"]="<font color=\"blue\"><b>鎖定技，</b></font>每當你受到雷電傷害時，你防止之，然後回復等同於此次傷害值的體力。",
["$sk_dianjie1"]="電破蒼穹，雷震九州！",
["$sk_dianjie2"]="風雷如律令，發咒顯聖靈！",
["$sk_shendao"]="人世之伎倆，與鬼神無用！",
["$sk_leihun"]="肉體凡胎,也敢擾我清靜！",
["~sk_shenzhangjue"]="吾之信仰,也將化為微塵……",
["designer:sk_shenzhangjue"]="網路神人",
["illustrator:sk_shenzhangjue"]="網路神人",
["cv:sk_shenzhangjue"]="網路神人",
}

--神張遼
sk_shenzhangliao = sgs.General(extension,"sk_shenzhangliao","god","4", true)
--逆戰
sk_nizhan = sgs.CreateTriggerSkill{
	name = "sk_nizhan",
	events = {sgs.DamageInflicted},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage = data:toDamage()
		if not damage.to:isAlive() then return false end
		if not damage.card then return false end
		if not damage.card:isKindOf("Slash") and not damage.card:isKindOf("Duel") then return false end
		for _, s in sgs.qlist(room:getAlivePlayers()) do
			if s:hasSkill("sk_nizhan") then
				--if s:askForSkillInvoke(self:objectName(),data) then
				local players = sgs.SPlayerList()
				if damage.from:objectName() ~= s:objectName() then
					players:append(damage.from)
				end
				if damage.to:objectName() ~= s:objectName() then
					players:append(damage.to)
				end
				--local target = room:askForPlayerChosen(s,players,self:objectName(),"sk_nizhan-invoke",true,true)
				local target = room:askForPlayerChosen(s,players,self:objectName(),"sk_nizhan-invoke",true,true)
				if target then
					target:gainMark("@sgkgodxi")
					room:broadcastSkillInvoke(self:objectName())
				end
				--end
			end
		end
	end,
	can_trigger=function()
		return true
	end
}
--摧鋒
sk_cuifeng=sgs.CreateTriggerSkill{
name="sk_cuifeng",
events=sgs.EventPhaseStart,
frequency=sgs.Skill_Compulsory,
on_trigger=function(self,event,player,data)
	if player:getPhase()~=sgs.Player_Finish then return false end
	local x=0
	local room=player:getRoom()
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		x=x+p:getMark("@sgkgodxi")
	end
	if x<4 then return false end
	local log=sgs.LogMessage()
	log.type="#TriggerSkill"
	log.from=player
	log.arg=self:objectName()
	room:sendLog(log)
	room:notifySkillInvoked(player,self:objectName())
	room:broadcastSkillInvoke(self:objectName())
	for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		if not player:isAlive() then break end
		if p:getMark("@sgkgodxi")>0 then
			local hand=p:getHandcardNum()
			local mark=p:getMark("@sgkgodxi")
			if hand < mark then
				room:obtainCard(player,p:wholeHandCards(),false)
				room:damage(sgs.DamageStruct(nil,player,p))
			else

				local dummy=sgs.Sanguosha:cloneCard("slash",sgs.Card_SuitToBeDecided,-1)
				local ids = getIntList(p:getHandcards())
				for i=1,mark,1 do
					local id = ids:at(math.random(0, ids:length() - 1))
					dummy:addSubcard(id)
					ids:removeOne(id)
				end
				room:obtainCard(player,dummy,false)
			end
		end
	end
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:getMark("@sgkgodxi")>0 then
			p:loseAllMarks("@sgkgodxi")
		end
	end
end
}


--威震
sk_weizhen = sgs.CreateTriggerSkill{
	name="sk_weizhen",
	events={sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase() ~= sgs.Player_Start then return false end
		local flag = false
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("@sgkgodxi") > 0 then
				flag = true
				break
			end
		end
		if flag == false then return false end
		if not player:askForSkillInvoke(self:objectName(),data) then return false end
		room:broadcastSkillInvoke(self:objectName())
		local x = 0
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("@sgkgodxi") > 0 then
				x = x + p:getMark("@sgkgodxi")
				p:loseAllMarks("@sgkgodxi")
			end
		end
		player:drawCards(x)
	end
}

sk_shenzhangliao:addSkill(sk_nizhan)
sk_shenzhangliao:addSkill(sk_cuifeng)
sk_shenzhangliao:addSkill(sk_weizhen)

sgs.LoadTranslationTable{
["sk_shenzhangliao"]="sk神張遼",
["&sk_shenzhangliao"]="張遼",
["#sk_shenzhangliao"]="威名裂膽",
["sk_nizhan"]="逆戰",
[":sk_nizhan"]="每當一名角色受到【殺】或【決鬥】造成的傷害時，你可以令該角色或傷害來源（不得為你）獲得一枚“襲”標記。",
["sk_nizhanfrom"]="傷害來源獲得“襲”標記",
["sk_nizhanto"]="受到傷害的角色獲得“襲”標記",
["sk_nizhan-invoke"] = "令一名角色獲得“襲”標記。",
["@sgkgodxi"]="襲",
["sk_cuifeng"]="摧鋒",
[":sk_cuifeng"]="<font color=\"blue\"><b>鎖定技，</b></font>結束階段開始時，若所有角色的“襲”標記總數不小於4，你須從有“襲”標記的角色處各獲得等同於其“襲”標記數的手牌（若不足則獲得其全部手牌並對其造成1點傷害），然後棄置所有角色全部的“襲”標記。",
["sk_weizhen"]="威震",
[":sk_weizhen"]="準備階段開始時，你可以棄置所有角色全部的“襲”標記，然後摸等量的牌。",
["$sk_nizhan"]="已是成敗二分之時！",
["$sk_cuifeng"]="全軍化為一體,總攻！",
["$sk_weizhen"]="讓你見識我軍的真正實力！",
["~sk_shenzhangliao"]="不求留名青史,但求無愧于心……",
["designer:sk_shenzhangliao"]="網路神人",
["illustrator:sk_shenzhangliao"]="網路神人",
["cv:sk_shenzhangliao"]="網路神人",
}

--神陸遜
sk_shenluxun = sgs.General(extension,"sk_shenluxun","god","3", true)
--劫焰
sk_jieyan = sgs.CreateTriggerSkill{
	name = "sk_jieyan" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:length() == 1 and use.to:contains(player) and use.from:objectName() ~= player:objectName() and use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:setPlayerFlag(player,"sk_jieyan_target")
					local card = room:askForCard(p, "..", "@sk_jieyan:"..player:objectName(), data, sgs.Card_MethodNone)
					room:setPlayerFlag(player,"-sk_jieyan_target")
					if card then
						room:throwCard(card,p,p)
						room:notifySkillInvoked(p, "sk_jieyan")
						room:broadcastSkillInvoke(self:objectName())
						player:setFlags("-ZhenlieTarget")
						player:setFlags("ZhenlieTarget")
						if player:isAlive() and player:hasFlag("ZhenlieTarget") then
							player:setFlags("-ZhenlieTarget")
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
							room:damage(sgs.DamageStruct("sk_jieyan",p,player,1,sgs.DamageStruct_Fire))							
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
--焚營
sk_fenyingCard = sgs.CreateSkillCard{
	name = "sk_fenying",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:hasFlag("sk_fenying_target")
	end,
	about_to_use = function(self, room, use)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, use.from:objectName(), "", self:objectName(), "")
		room:moveCardTo(self, use.from, nil, sgs.Player_DiscardPile, reason, true)
		skill(self, room, use.from, true)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			local n = use.from:getMark("sk_fenying_num")
			room:damage(sgs.DamageStruct(self:objectName(), use.from, use.to:first(), n, sgs.DamageStruct_Normal))
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
sk_fenyingVS = sgs.CreateOneCardViewAsSkill{
	name = "sk_fenying",
	filter_pattern = ".|red!",
	view_as = function(self, card)
		local first = sk_fenyingCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@sk_fenying")
	end
}

sk_fenying = sgs.CreateTriggerSkill{
	name = "sk_fenying",
	events = {sgs.PreDamageDone,sgs.Damage},
	view_as_skill = sk_fenyingVS,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.from and damage.to and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() then
				local distance = 1000
				for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
					if p:distanceTo(damage.to) < distance then
						distance = p:distanceTo(damage.to)
					end
				end

				room:setPlayerFlag(damage.to,"sk_fenying_target")
				for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
					if p:distanceTo(damage.to) == distance then
						room:setPlayerFlag(p,"sk_fenying_target")
					end
				end
			end
		elseif (event == sgs.Damage) and player:hasSkill(self:objectName()) and player:isAlive() then
			local damage = data:toDamage()
			room:setPlayerMark(player,"sk_fenying_num",damage.damage)
			if player:canDiscard(player, "he") and player:getHandcardNum() <= player:getMaxHp() then
				room:askForUseCard(player, "@@sk_fenying", "sk_fenyingi-invoke", -1, sgs.Card_MethodNone)
			end
			room:setPlayerMark(player,"sk_fenying_num",0)
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p,"-sk_fenying_target")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

sk_shenluxun:addSkill(sk_jieyan)
sk_shenluxun:addSkill(sk_fenying)

sgs.LoadTranslationTable{
["sk_shenluxun"]="sk神陸遜",
["&sk_shenluxun"]="陸遜",
["#sk_shenluxun"]="焚炎滅陣",
["sk_jieyan"]="劫焰",
[":sk_jieyan"]="每當一張紅色的「殺」或非延時錦囊牌僅指定一名角色時，你可以棄置一張牌令其無效，然後你對目標角色造成一點火焰傷害。 ",
["@sk_jieyan"]="你可以棄置一張牌令其對 %src 無效，然後對目標角色造成一點火焰傷害。",

["sk_fenying"]="焚營",
[":sk_fenying"]="每當你對一名角色造成傷害後，若你的手牌數不大於你的體力上限，你可以棄置一張紅色牌，對其或與其距離最近的另一名角色造成等量的火焰傷害。",
["sk_fenyingi-invoke"]= "棄置一張紅色牌，對其或與其距離最近的另一名角色造成等量的火焰傷害",
["~sk_fenying"]="選擇一張紅色牌→選擇一名角色→點擊確定",

["$sk_jieyan"]="炙濁之氣，已溢滿萬劍。",
["$sk_fenying"]="隨著大火,往生去吧！",
["~sk_shenluxun"]="火,終究是無情之物！",
["designer:sk_shenluxun"]="網路神人",
["illustrator:sk_shenluxun"]="網路神人",
["cv:sk_shenluxun"]="網路神人",

}

--[[
神華佗
元化：鎖定技，當你獲得【桃】後，若你已受傷，你回復一點體力，否則摸兩張牌。然後將【桃】移出遊戲。
歸元：出牌階段限一次，你可以失去1點體力，然後令所有其他角色交給你一張【桃】，若沒有角色如此做，你從棄牌堆或是牌堆中獲得一張【桃】。
重生：限定技，當一名角色進入瀕死狀態時，你可以令其回復X點體力，超出體力上限的部分改為摸牌，然後其可以從三張同勢力的武將牌中選擇一張替換之。（X為元化移出遊戲的牌且至少為1）
]]--

sk_shenhuatuo = sgs.General(extension,"sk_shenhuatuo","god",3,true)

--元化
sk_yuanhua = sgs.CreateTriggerSkill{
	name = "sk_yuanhua",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if event == sgs.CardsMoveOneTime and move.to and move.to:objectName() == player:objectName()  then
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("Peach") then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					if room:getCardOwner(id):objectName() == player:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
						if player:isWounded() then
							room:recover(player, sgs.RecoverStruct(player))
						else
							player:drawCards(2)
						end
						player:addToPile("sk_yuanhua",id)
					end					
				end
			end
		end
		return false
	end,
}

--歸元
sk_guiyuanCard = sgs.CreateSkillCard{
	name = "sk_guiyuan",
	target_fixed= true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:loseHp(source)
			local get_peach = true
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if not p:isNude() then
					local peach_cards = {}
					for _, card in sgs.qlist(p:getCards("he")) do
						if card:isKindOf("Peach") then
							table.insert(peach_cards, card)
						end
					end
					if #peach_cards > 0 then
						local card = room:askForCard(p, "Peach!", "@sk_guiyuan_give:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
						if card then
							get_peach = false
							room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), source:objectName(), self:objectName(), ""))
						end
					end
				end
			end
			if get_peach then
				getpatterncard(source, {"Peach"},true,true)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
sk_guiyuan = sgs.CreateZeroCardViewAsSkill{
	name = "sk_guiyuan",
	view_as = function()
		return sk_guiyuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sk_guiyuan")
	end
}

--重生
sk_chongsheng = sgs.CreateTriggerSkill{
	name = "sk_chongsheng",
	events = {sgs.EnterDying},
	frequency = sgs.Skill_Limited,
	limit_mark = "@sk_chongsheng",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
		room:sortByActionOrder(players)
		for _, p in sgs.qlist(players) do			
			if p:isAlive() and p:getMark("@sk_chongsheng") > 0 then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:removePlayerMark(p, "@sk_chongsheng")

					local n = math.max(p:getPile("sk_yuanhua"):length(),1)
					room:broadcastSkillInvoke(self:objectName())
					room:doSuperLightbox("sk_shenhuatuo","sk_chongsheng")

					local theRecover = sgs.RecoverStruct()
					theRecover.recover = math.min(n,player:getLostHp())
					theRecover.who = player
					room:recover(player, theRecover)
					if n > player:getLostHp() then
						player:drawCards(n - player:getLostHp() )
					end
					room:getThread():delay()
					--更換武將
					local Chosens = {}
					local generals
					local kingdom_index = math.random(1,5)
					if kingdom_index == 1 then
						generals = generate_all_general_list(player, {"wei","wei2"}, {})
					elseif kingdom_index == 2 then
						generals = generate_all_general_list(player, {"shu","shu2"}, {})
					elseif kingdom_index == 3 then
						generals = generate_all_general_list(player, {"wu","wu2"}, {})
					elseif kingdom_index == 4 then
						generals = generate_all_general_list(player, {"qun","qun2"}, {})
					elseif kingdom_index == 5 then
						generals = generate_all_general_list(player, {"god"}, {})
					end
					for i = 1, 3 , 1 do
						if #generals > 0 then
							local j = math.random(1, #generals)
							local getGeneral = generals[j]
							table.insert(Chosens, getGeneral)
							table.remove(generals, j)

							local log = sgs.LogMessage()
							log.type = "#getGeneralCard"
							log.from = player	
							log.arg = getGeneral
							room:sendLog(log)
						end
					end
					table.insert(Chosens, player:getGeneralName() )

					local general = room:askForGeneral(player, table.concat(Chosens, "+"))
					if player:getGeneralName() ~= general then
						room:changeHero(player, general, false, true, false)
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

sk_shenhuatuo:addSkill(sk_yuanhua)
sk_shenhuatuo:addSkill(sk_guiyuan)
sk_shenhuatuo:addSkill(sk_chongsheng)

sgs.LoadTranslationTable{
["sk_shenhuatuo"] = "sk神華佗",
["&sk_shenhuatuo"] = "華佗",
["sk_yuanhua"] = "元化",
[":sk_yuanhua"] = "鎖定技，當你獲得【桃】後，若你已受傷，你回復一點體力，否則摸兩張牌。然後將【桃】移出遊戲。",
["sk_guiyuan"] = "歸元",
[":sk_guiyuan"] = "出牌階段限一次，你可以失去1點體力，然後令所有其他角色交給你一張【桃】，若沒有角色如此做，你從棄牌堆或是牌堆中獲得一張【桃】。",
["sk_chongsheng"] = "重生",
[":sk_chongsheng"] = "限定技，當一名角色進入瀕死狀態時，你可以令其回復X點體力，超出體力上限的部分改為摸牌，然後其可以從三張同勢力的武將牌中選擇一張替換之。（X為元化移出遊戲的牌且至少為1）",
["@sk_guiyuan_give"] = "請交給 %src 一張【桃】",
}

sgs.Sanguosha:addSkills(skills)
