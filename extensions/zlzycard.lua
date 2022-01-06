module("extensions.zlzycard", package.seeall)
extension = sgs.Package("zlzycard",sgs.Package_CardPack)

sgs.LoadTranslationTable{
	["zlzycard"] = "逐鹿卡牌",
}

local skills = sgs.SkillList()

--[[ 
解甲歸田
【解甲歸田】（逐鹿天下）錦囊/非延時錦囊(普通錦囊)
使用時機：出牌階段。
使用目標：對一名裝備區裡有牌的角色使用。
作用效果：該角色獲得其裝備區裡的所有牌。
--]]
jiejiaguitian = sgs.CreateTrickCard{
	name = "jiejiaguitian",
	class_name = "jiejiaguitian",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getEquips():length() > 0
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local ids = sgs.IntList()
		for _, jcard in sgs.qlist(tiger:getEquips()) do
			ids:append(jcard:getEffectiveId())
		end
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = tiger
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move, true)
		room:damage(sgs.DamageStruct(nil,source,tiger,1,sgs.DamageStruct_Normal))
	end
}

addcard = function(create_card, snn)
	local n = #snn
	for i=1, n, 2 do
		local tcard = create_card:clone()
		tcard:setSuit(snn[i])
		tcard:setNumber(snn[i+1])
		tcard:setParent(extension)
	end
end
--大量增加卡牌的方法 addcard(xxx ,{suit, number}) 
addcard(jiejiaguitian ,{sgs.Card_Heart, 7})

sgs.LoadTranslationTable{
	["jiejiaguitian"] = "解甲歸田",
	[":jiejiaguitian"] = "出牌階段，對一名裝備區裡有牌的角色使用。作用效果：該角色獲得其裝備區裡的所有牌",
}
--[[ 
樹上開花
【樹上開花】（逐鹿天下）錦囊/非延時錦囊(普通錦囊)
使用時機：出牌階段。
使用目標：對你使用。
作用效果：你棄置至多兩張牌，然後摸等量的牌。若你以此法棄置了裝備牌，則多摸一張牌。
--]]
shushangkaihua = sgs.CreateTrickCard{
	name = "shushangkaihua",
	class_name = "shushangkaihua",
	target_fixed = true,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 7,
	subtype = "single_target_trick",
	on_use = function(self, room, source, targets)
		room:cardEffect(self, source, source)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local to_exchange = room:askForExchange(effect.to, "shushangkaihua", 1, 2, true,"shushangkaihua")
		local n = to_exchange:length()
		room:throwCard(to_exchange,effect.to,effect.to)
		effect.to:drawCards(n)
	end
}

shushangkaihua:setParent(extension)

sgs.LoadTranslationTable{
	["shushangkaihua"] = "樹上開花",
	[":shushangkaihua"] = "你棄置至多兩張牌，然後摸等量的牌。若你以此法棄置了裝備牌，則多摸一張牌。",
}

--[[ 
逐鹿天下
【逐鹿天下】（逐鹿天下）錦囊/非延時錦囊(普通錦囊)
使用時機：出牌階段。
使用目標：對所有角色使用。
作用效果：從牌堆和棄牌堆中亮出等同於目標角色數的裝備牌，從你開始每名目標角色選擇其中一張並置於自己的裝備區裡。
--]]
function useEquip(room, player)
	--local equips = sgs.CardList()
	local equips = {}
	for _,id in sgs.qlist(room:getDrawPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
			--equips:append(sgs.Sanguosha:getCard(id))
			table.insert(equips, sgs.Sanguosha:getCard(id))
		end
	end
	for _,id in sgs.qlist(room:getDiscardPile()) do
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

zhulutianxia = sgs.CreateTrickCard{
	name = "zhulutianxia",
	class_name = "zhulutianxia",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 7,
	subtype = "global_effect",
	on_use = function(self, room, source, targets)
		room:cardEffect(self, source, source)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		useEquip(room, effect.to)
	end
}

zhulutianxia:setParent(extension)

sgs.LoadTranslationTable{
	["zhulutianxia"] = "逐鹿天下",
	[":szhulutianxia"] = "從你開始每名目標角色隨機使用一張裝備牌。",
}

--[[ 
草船借箭
【草船借箭】（逐鹿天下）錦囊/非延時錦囊(普通錦囊)
使用時機：當一張【殺】或傷害類錦囊牌對你生效前。
使用目標：對此牌使用。
作用效果：抵消此牌對你的效果，然後在此牌結算結束後，獲得之。
--]]
--caochuanjiejian

caochuanjiejian = sgs.CreateTrickCard{
	name = "caochuanjiejian",
	class_name = "caochuanjiejian",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 7,
	subtype = "global_effect",
	available = function(self, player)
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.to:setFlags("caochuanjiejianFlag")
	end
}

caochuanjiejian_trigger = sgs.CreateTriggerSkill{
	name = "caochuanjiejian_trigger" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
			 	  or use.card:isKindOf("FireAttack") or use.card:isKindOf("SavageAssault")
				  or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("Drowning")) then

				  	player:setFlags("-caochuanjiejianFlag")

				  	local hasCcard = false
					for _, card in sgs.qlist(player:getHandcards()) do
						if card:isKindOf("caochuanjiejian") then
							hasCcard = true
							break
						end
					end
					if hasCcard then
						local caochuanjiejian_card = room:askForUseCard(player,"caochuanjiejian","#caochuanjiejianCard")
						if caochuanjiejian_card then
							room:cardEffect(caochuanjiejian,player,player)

							if player:hasFlag("caochuanjiejianFlag") then
								
								player:setFlags("-ZhenlieTarget")
								player:setFlags("ZhenlieTarget")

								if player:isAlive() and player:hasFlag("ZhenlieTarget") then
									player:setFlags("-ZhenlieTarget")
									local nullified_list = use.nullified_list
									table.insert(nullified_list, player:objectName())
									use.nullified_list = nullified_list
									data:setValue(use)
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
}

if not sgs.Sanguosha:getSkill("caochuanjiejian_trigger") then skills:append(caochuanjiejian_trigger) end

caochuanjiejian:setParent(extension)

sgs.LoadTranslationTable{
	["caochuanjiejian"] = "草船借箭",
	[":caochuanjiejian"] = "抵消此牌對你的效果，然後在此牌結算結束後，獲得之。",
	["#caochuanjiejianCard"] = "你可以使用一張「草船借箭」",
}

--[[ 
------------逐鹿天下贈物說明，贈物無法自己使用，直接放入其他角色裝備區裡的裝備------------
--]]
--[[ 
夜行衣
【夜行衣】（逐鹿天下）裝備/防具
技能：鎖定技，你不能成為黑色錦囊牌的目標。
--]]
function lua_armor_null_check(player)
	if #player:getTag("Qinggang"):toStringList() > 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then
		return true
	end
	return false
end

yexingyiskill = sgs.CreateProhibitSkill{
	name = "yexingyiskill", 
	is_prohibited = function(self, from, to, card)
		return to:getArmor() and to:getArmor():isKindOf("yexingyi") and (not lua_armor_null_check(to)) and card:isBlack() and card:isNDTrick() and from:objectName() ~= to:objectName()
	end
}

if not sgs.Sanguosha:getSkill("yexingyiskill") then skills:append(yexingyiskill) end

yexingyi = sgs.CreateArmor{
	name = "yexingyi",
	class_name = "yexingyi",
	suit = sgs.Card_Spade,
	number = 10,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("yexingyiskill")
		room:getThread():addTriggerSkill(skill)
	end
}
yexingyi:setParent(extension)

sgs.LoadTranslationTable{
	["yexingyi"] = "夜行衣",
	[":yexingyi"] = "鎖定技，你不能成為黑色錦囊牌的目標。",
	["yexingyiskill"] = "夜行衣",
}


--[[ 
女裝
【女裝】（逐鹿天下）裝備/贈物/防具
技能：鎖定技，當【女裝】進入或離開你的裝備區時，若你是男性，則你棄置一張其他牌。
nuzhuang
--]]

nuzhuangskill = sgs.CreateTriggerSkill{
	name = "nuzhuangskill" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				local card_id = move.card_ids:at(i)
				if move.from_places:at(i) == sgs.Player_PlaceEquip and card_id:isKindOf("nuzhuang") then
					room:askForDiscard(player, "nuzhuang", 1, 1, false, false)
				end
			end
		end
		if move.to and move.to:objectName() == player:objectName() and move.to_places == sgs.Player_PlaceEquip then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				local card_id = move.card_ids:at(i)
				if card_id:isKindOf("nuzhuang") then
					room:askForDiscard(player, "nuzhuang", 1, 1, false, false)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

if not sgs.Sanguosha:getSkill("nuzhuangskill") then skills:append(nuzhuangskill) end

nuzhuang = sgs.CreateArmor{
	name = "nuzhuang",
	class_name = "nuzhuang",
	suit = sgs.Card_Heart,
	number = 10,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("nuzhuangskill")
		room:getThread():addTriggerSkill(skill)
	end
}

nuzhuang:setParent(extension)

sgs.LoadTranslationTable{
	["nuzhuang"] = "女裝",
	[":nuzhuang"] = "鎖定技，當【女裝】進入或離開你的裝備區時，若你是男性，則你棄置一張其他牌。",
	["nuzhuangskill"] = "女裝",
}

--[[ 
引蜂甲
【引蜂甲】（逐鹿天下）裝備/贈物/防具
技能：鎖定技，當你受到錦囊牌的傷害時，此傷害+1。
yinfengjia
--]]

yinfengjiaskill = sgs.CreateTriggerSkill{
	name = "yinfengjiaskill",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card:isKindOf("TrickCard") then	
			room:notifySkillInvoked(player, "yinfengjiaskill")
			damage.damage = damage.damage + 1
			--[[
			local msg = sgs.LogMessage()
			msg.type = "#lingzen2"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = tostring(damage.damage - 1)
			msg.arg2 = tostring(damage.damage)
			room:sendLog(msg)
			]]--
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, target)
		return target:getArmor() and target:getArmor():isKindOf("yinfengjia")
	end,
}

yinfengjia = sgs.CreateArmor{
	name = "yinfengjia",
	class_name = "yinfengjia",
	suit = sgs.Card_Diamond,
	number = 10,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("yinfengjiaskill")
		room:getThread():addTriggerSkill(skill)
	end
}

yinfengjia:setParent(extension)

sgs.LoadTranslationTable{
	["yinfengjia"] = "引蜂甲",
	[":yinfengjia"] = "鎖定技，當你受到錦囊牌的傷害時，此傷害+1。",
	["yinfengjiaskill"] = "引蜂甲",
}

--[[ 
涯角槍
【涯角槍】（逐鹿天下）裝備/武器
攻擊範圍：3
技能：當你於回合外使用黑色牌時，若此牌是你本回合第一次使用黑色牌，則當此牌結算結束後，你可以獲得之。
yajiaoqiang
--]]

yajiaoqiangskill = sgs.CreateTriggerSkill{
	name = "yajiaoqiangskill" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isBlack() and player:getMark("yajiaoqiang-Clear") == 0 and player:getPhase() == sgs.Player_NotActive then
				room:obtainCard(player, use.card, false)
			end
			room:setPlayerMark(player,"yajiaoqiang-Clear",1)
		end
	end,
	can_trigger = function(self, target)
		return target:getWeapon() and target:getWeapon():isKindOf("yajiaoqiang")
	end,
}
if not sgs.Sanguosha:getSkill("yajiaoqiangskill") then skills:append(yajiaoqiangskill) end

yajiaoqiang = sgs.CreateWeapon{
	name = "yajiaoqiang",
	class_name = "yajiaoqiang",
	suit = sgs.Card_Spade,
	number = 5,
	range = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("yajiaoqiangskill")
		room:getThread():addTriggerSkill(skill)
	end
}

yajiaoqiang:setParent(extension)

sgs.LoadTranslationTable{
	["yajiaoqiang"] = "涯角槍",
	[":yajiaoqiang"] = "當你於回合外使用黑色牌時，若此牌是你本回合第一次使用黑色牌，則當此牌結算結束後，你可以獲得之。",
}

--[[ 
折戟
【折戟】（逐鹿天下）裝備/贈物/武器
攻擊範圍：0
技能：這是一把壞掉的武器……
zheji
--]]
zheji = sgs.CreateWeapon{
	name = "zheji",
	class_name = "zheji",
	suit = sgs.Card_Club,
	number = 5,
	range = 0,
	on_install = function(self,player)
		local room = player:getRoom()
	end
}

zheji:setParent(extension)

--[[ 
無鋒劍
【無鋒劍】（逐鹿天下）裝備/贈物/武器
攻擊範圍：1
技能：鎖定技，當你使用【殺】時，你棄置一張牌。
wufengjian
--]]

wufengjianskill = sgs.CreateTriggerSkill{
	name = "wufengjianskill" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:askForDiscard(player, "wufengjianskill", 1, 1, false, false)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getWeapon() and target:getWeapon():isKindOf("wufengjian")
	end,
}
if not sgs.Sanguosha:getSkill("wufengjianskill") then skills:append(wufengjianskill) end

wufengjian = sgs.CreateWeapon{
	name = "wufengjian",
	class_name = "wufengjian",
	suit = sgs.Card_Spade,
	number = 5,
	range = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("wufengjianskill")
		room:getThread():addTriggerSkill(skill)
	end
}

wufengjian:setParent(extension)

sgs.LoadTranslationTable{
	["wufengjian"] = "無鋒劍",
	["wufengjianskill"] = "無鋒劍",
	[":wufengjian"] = "鎖定技，當你使用【殺】時，你棄置一張牌。",
}

--[[ 
駑馬
【駑馬】（逐鹿天下）裝備/贈物/坐騎
技能：鎖定技，當【駑馬】進入你的裝備區後，你棄置裝備區裡的其他牌。
--]]
numaSkill = sgs.CreateTriggerSkill{
	name = "numaSkill",
	events = {sgs.BeforeCardsMove},
	priority = -2,
	on_trigger = function(self, event, splayer, data, room)
		local move = data:toMoveOneTime()
		if move.to and move.to_place == sgs.Player_PlaceEquip then
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("numa") then
					local ids = sgs.IntList()
					for _, jcard in sgs.qlist(move.to:getEquips()) do
						ids:append(jcard:getEffectiveId())
					end
					local move2 = sgs.CardsMoveStruct()
					move2.card_ids = ids
					move2.to_place = sgs.Player_DiscardPile
					room:moveCardsAtomic(move2, true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
if not sgs.Sanguosha:getSkill("numaSkill") then skills:append(numaSkill) end

local numa = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Heart, 5)
numa:setObjectName("numa")
numa:setParent(extension)

sgs.LoadTranslationTable{
	["numa"] = "駑馬",
	["numaskill"] = "駑馬",
	[":numa"] = "鎖定技，當【駑馬】進入你的裝備區後，你棄置裝備區裡的其他牌。",
}
--[[ 
錦盒
【錦盒】（逐鹿天下）裝備/贈物/寶物
技能：1.使用【錦盒】時，觀看牌堆頂的兩張牌並扣置其中一張在【錦盒】下，稱為“禮”。
2.出牌階段，你可以將“禮”置入棄牌堆。若如此做，你同時棄置所有與此“禮”花色相同的手牌以及【錦盒】；
當【錦盒】以除此以外的方式進入棄牌堆時，你棄置所有手牌。
jinhe
--]]
jinheskill = sgs.CreateTriggerSkill{
	name = "jinheskill" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from_places:contains(sgs.Player_PlaceEquip) and move.to_place == sgs.Player_DiscardPile then
				for _,id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("jinhe") then
						if move.from:hasFlag("jinheStart") then
							local suitlist = {sgs.Card_Club,sgs.Card_Diamond,sgs.Card_Heart,sgs.Card_Spade}
							local choosesuit
				 			local choosesuit = suitlist[math.random(1,4)]
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
									move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "str_chenglue", nil)
									room:moveCardsAtomic(move, true)
								end
							end
						else
							local move = sgs.CardsMoveStruct()
							move.card_ids = player:getHandcards()
							move.to = nil
							move.to_place = sgs.Player_DiscardPile
							move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "str_chenglue", nil)
							room:moveCardsAtomic(move, true)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local room = player:getRoom()
			local phase = player:getPhase()
			if phase == sgs.Player_Play then
				if player:getTreasure():isKindOf("jinhe") then
					room:setPlayerFlag(player , "jinheStart")
					room:throwCard(player:getTreasure(), player, player)
					room:setPlayerFlag(player , "-jinheStart")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("jinhe")
	end
}

if not sgs.Sanguosha:getSkill("jinheskill") then skills:append(jinheskill) end

jinhe = sgs.CreateTreasure{
	name = "god_hat",
	class_name = "jinhe",
	suit = sgs.Card_Club,
	number = 10,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("jinheskill")
		room:getThread():addTriggerSkill(skill)
	end
}
jinhe:setParent(extension)

sgs.LoadTranslationTable{
	["jinhe"] = "錦盒",
	["jinheskill"] = "錦盒",
	[":jinhe"] = "出牌階段，你可以將“錦盒”置入棄牌堆。若如此做，你隨機棄置一種花色的手牌；當【錦盒】以除此以外的方式進入棄牌堆時，你棄置所有手牌。",
}

zengwuskill = sgs.CreateTriggerSkill{
    name = "#zengwuskill",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if (card:isKindOf("zheji") or card:isKindOf("wufengjian") or card:isKindOf("numa") or card:isKindOf("jinhe") ) then
			local dest = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName() ,"@zengwu-give")
		    if dest then			   
				local move = sgs.CardsMoveStruct(card, nil, dest, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move, false)
				return true
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

if not sgs.Sanguosha:getSkill("#zengwuskill") then skills:append(zengwuskill) end

sgs.Sanguosha:addSkills(skills)