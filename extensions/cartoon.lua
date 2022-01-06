module("extensions.cartoon", package.seeall)
extension = sgs.Package("cartoon")

sgs.LoadTranslationTable{
	["cartoon"] = "卡通包",
}

local skills = sgs.SkillList()

--[[
仙劍負面狀態：
1.隨機棄置一張牌
2.失去一點體力
3.受到一點無來源的傷害
4.橫置武將牌
5.獲得技能「封印」直到你的回合結束
6.隨機將一張延時錦囊置入你的判定區

仙劍正面狀態：
1.摸一張牌
2.回復一點體力
3.獲得一點護甲
4.獲得潜行
锁定技，你不能成为其他角色的卡牌的目标
5.棄置一點延時錦囊牌
6.重置你的武將牌
]]--

--[[
pal_jiangcheng:'姜承'
'qun',4
longhuo:'龍火',
longhuo_info:'結束階段，你可以對所有角色各造成一點火焰傷害',
fenshi:'焚世',
fenshi_info:'覺醒技，當你解除瀕死狀態時，你獲得兩點護甲，摸兩張牌，然後獲得技能龍火',
yanzhan:'炎斬',
yanzhan_info:'出牌階段限一次，你可以將一張紅色牌當作火殺使用，此殺只能用與之花色相同的閃響應；若此殺造成了傷害，
你本回合可以額外使用一張殺',

]]--
--[[
pal_jiangyunfan:'姜雲凡',
'wei',4,'xunying','liefeng'
			xunying:'迅影',
			xunying_info:'每當你使用殺對一名目標結算完畢後，你可以繼續對目標使用殺',
			liefeng:'冽風',
			liefeng_info:'鎖定技，當你在回合內使用第二張牌時，你本回合獲得【炎斬】；
			當你在回合內使用第三張牌時，你本回合獲得【天劍】；當你在回合內使用第四張牌時，你本回合獲得【御風】',
]]--
--[[
pal_tangyurou:'唐雨柔',
'shu',3,'txianqu','qiongguang'
			txianqu:'仙音',
			txianqu_info:'出牌階段限一次，當你即將造成傷害時，你可以防止之，然後摸兩張牌並回復一點體力',
			qiongguang:'穹光',
			qiongguang_info:'棄牌階段結束時，若你棄置了至少兩張牌，你可以對所有敵方角色施加一個隨機的負面效果',

]]--
--[[
pal_longkui:'龍葵',
'female','qun',3,'fenxing','diewu','lingyu'
			fenxing:'分形',
			fenxing_info:'鎖定技，準備階段，你有50%概率變身為另一形態',
			lingyu:'靈愈',
			lingyu_info:'結束階段，你可以令一名其他角色回復一點體力',
			diewu:'蝶舞',
			diewu_info:'出牌階段，你可以將一張【殺】交給一名角色，若你於此階段內首次如此做，你摸一張牌',

]]--
--[[
趙靈兒
]]--

pal_zhaoliner = sgs.General(extension, "pal_zhaoliner", "wei2", "3", false)

pal_huimeng = sgs.CreateTriggerSkill{
	name = "pal_huimeng",
	frequency = sgs.Skill_Frequent, 
	events  = {sgs.HpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			if not player:isAlive() then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(),2)
				room:drawCards(player, 2, "pal_huimeng")
			end
		end
	end
}

pal_tianshe = sgs.CreateTriggerSkill{
	name = "pal_tianshe",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted,sgs.Damage},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageInflicted then 
			local damage = data:toDamage()
			if (damage.nature == sgs.DamageStruct_Thunder or damage.nature == sgs.DamageStruct_Fire) then	
				room:notifySkillInvoked(player, "yinshi")
				room:broadcastSkillInvoke("yinshi")
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
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if (damage.nature == sgs.DamageStruct_Thunder or damage.nature == sgs.DamageStruct_Fire) then
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
		end
	end
}

pal_zhaoliner:addSkill(pal_huimeng)
pal_zhaoliner:addSkill(pal_tianshe)

sgs.LoadTranslationTable{
["pal_zhaoliner"] = "趙靈兒",
["pal_huimeng"] = "回夢",
[":pal_huimeng"] = "每當你回復一點體力，可以摸兩張牌",
["pal_tianshe"] = "天蛇",
[":pal_tianshe"] = "鎖定技，你防止即將受到的屬性傷害，每當你造成一次屬性傷害，你回復一點體力",
}

--[[		
林月如
]]--

pal_linyueru = sgs.General(extension, "pal_linyueru", "wei2", "3", false)

pal_guiyuanCard = sgs.CreateSkillCard{
	name = "pal_guiyuan", 
	target_fixed = true, 
	will_throw= true,
	on_use = function(self, room, source, targets)
		room:recover(source, sgs.RecoverStruct(source, nil, 1))
		source:drawCards(1)
	end
}

pal_guiyuan = sgs.CreateOneCardViewAsSkill{
	name = "pal_guiyuan",
	view_filter = function(self, card)
		return card:isKindOf("Slash")
	end,
	view_as = function(self, card)
		local slash = pal_guiyuanCard:clone()
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return player:hasUsed("#pal_guiyuan")
	end,
}

pal_qijianCard = sgs.CreateSkillCard{
	name = "pal_qijian",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		if #targets < sgs.Self:getMark(self:objectName()) and slash:targetFilter(targets_list, to_select, sgs.Self) then
			return true
		end
	end,
	on_use = function(self, room, source, targets)
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
				slash:setSkillName(self:objectName())
				room:useCard(sgs.CardUseStruct(slash, source, targets_list))
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
pal_qijianVS = sgs.CreateZeroCardViewAsSkill{
	name = "pal_qijian",
	view_as = function(self, cards)
		return pal_qijianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@pal_qijian")
	end
}
pal_qijian = sgs.CreateTriggerSkill{
	name = "pal_qijian",
	view_as_skill = pal_qijianVS,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					room:addPlayerMark(player, self:objectName(), move.card_ids:length())
				end
			else
				if player:getMark(self:objectName()) > 0 then
					room:askForUseCard(player, "@@pal_qijian", "@pal_qijian", -1, sgs.Card_MethodUse)
				end
			end
		end
		return false
	end
}

pal_linyueru:addSkill(pal_guiyuan)
pal_linyueru:addSkill(pal_qijian)

sgs.LoadTranslationTable{
["pal_linyueru"] = "林月如",
["pal_guiyuan"] = "歸元",
[":pal_guiyuan"] = "出牌階段限一次，你可以棄置一張殺，然後回復一點體力並摸一張牌",
["pal_qijian"] = "氣劍",
[":pal_qijian"] = "棄牌階段結束時，你可以指定至多X名目標視為使用一張殺，X為你於此階段棄置的卡牌數",
}

--[[
李逍遙
]]--
pal_lixiaoyao = sgs.General(extension, "pal_lixiaoyao", "qun2", "4", true)

pal_tianjianVS = sgs.CreateOneCardViewAsSkill{
	name = "pal_tianjian",
	view_filter = function(self, card)
		return card:isKindOf("Slash")
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return player:getMark("pal_tianjian-Clear") == 0
	end,
}

pal_tianjian = sgs.CreateTriggerSkill{
	name = "pal_tianjian", 
	view_as_skill = pal_tianjianVS, 
	events = {sgs.Damage,sgs.PreCardUsed}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == "pal_tianjian" and damage.to and damage.to:isAlive() then
				local loot_cards = sgs.QList2Table(damage.to:getCards("he"))
				if #loot_cards > 0 then
					room:throwCard(loot_cards[math.random(1, #loot_cards)], damage.to,player)
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == self:objectName() then
				room:addPlayerMark(player,"pal_tianjian-Clear")
			end
		end
	end,
}

pal_yufeng = sgs.CreateTriggerSkill{
	name = "pal_yufeng",
	events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.MaxHpChanged, sgs.HpChanged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard then
				local changed = false
				if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
					changed = true
				end
				if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
					changed = true
				end
				if changed then
					player:addMark("pal_yufeng")
				end
				return false
			else
				local can_invoke = false
				if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
					can_invoke = true
				end
				if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
					can_invoke = true
				end
				if not can_invoke then
					return false
				end
			end
		elseif event == sgs.HpChanged or event == sgs.MaxHpChanged then
			if player:getPhase() == sgs.Player_Discard then
				player:addMark("pal_yufeng")
				return false
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from ~= sgs.Player_Discard then
				return false
			end
			if player:getMark("pal_yufeng") <= 0 then
				return false
			end
			player:setMark("pal_yufeng", 0)
		end
		if (player:getHandcardNum() < 2 and player:getPhase() ~= sgs.Player_Discard and player:askForSkillInvoke(self:objectName())) and player:getMark("pal_yufeng_invoke-Clear") < 2 then
			player:drawCards(2 - player:getHandcardNum());
			player:addMark("pal_yufeng_invoke-Clear")
		end
		return false;
	end
}

pal_lixiaoyao:addSkill(pal_tianjian)
pal_lixiaoyao:addSkill(pal_yufeng)

sgs.LoadTranslationTable{
	["pal_lixiaoyao"] = "李逍遙",
	["pal_tianjian"] = "天劍",
	[":pal_tianjian"] = "出牌階段限一次，你可以將一張殺當作萬箭齊發使用，受到傷害的角色隨機棄置一張牌",
	["pal_yufeng"] = "御風",
	[":pal_yufeng"] = "鎖定技，當你失去手牌後，若手牌數少於2，你將手牌數補至2（每回合最多發動兩次）",
}

--[[
pal_anu:'阿奴',
'female','wu',3,'pal_lingdi','pal_anwugu'
pal_lingdi:'靈笛',
pal_lingdi_info:'出牌階段，你可以棄置一張本回合與此法棄置的牌花色均不同的手牌，然後選擇一名與你距離為X的角色與其各摸一張牌，
X為本回合發動靈笛的次數（含此次）',
pal_anwugu:'巫蠱',
pal_anwugu_info:'每當你對其他角色造成一次傷害，你可以令目標獲得三枚蠱標記；擁有蠱標記的角色手牌上限-1，每回合最多使用X張牌
（X為蠱標記數），每個結束階段失去一枚蠱標記',

]]--
pal_anu = sgs.General(extension, "pal_anu", "wu2", 3, false,true)

pal_lingdiCard = sgs.CreateSkillCard{
	name = "pal_lingdi",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:distanceTo(to_select) == player:usedTimes("#pal_lingdi")
	end,
	on_effect = function(self, effect)
		room:addPlayerMark(effect.from, self:objectName()..sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit().."_Play")
		effect.from:drawCards(1)
		effect.to:drawCards(1)
	end
}
pal_lingdi = sgs.CreateOneCardViewAsSkill{
	name = "pal_lingdi",
	view_filter = function(self, card)
		--return not card:isEquipped() and sgs.Self:getMark(self:objectName()..card:getTypeId().."_Play") == 0
		return sgs.Self:getMark(self:objectName()..card:getSuit().."_Play") == 0
	end,
	view_as = function(self, card)
		local cards = pal_lingdiCard:clone()
		cards:addSubcard(card)
		cards:setUserString(dragon)
		return cards
	end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "h")
    end
}

sgs.LoadTranslationTable{
["pal_anu"] = "阿奴",
["pal_lingdi"] = "靈笛",
[":pal_lingdi"] = "出牌階段，你可以棄置一張本回合與此法棄置的牌花色均不同的手牌，然後選擇一名與你距離為X的角色與其各摸一張牌，X為本回合發動靈笛的次數（含此次）",
["pal_anwugu"] = "巫蠱",
[":pal_anwugu"] = "每當你對其他角色造成一次傷害，你可以令目標獲得三枚蠱標記；擁有蠱標記的角色手牌上限-1，每回合最多使用X張牌（X為蠱標記數），每個結束階段失去一枚蠱標記",
}


--[[

pal_hanlingsha:'韓菱紗',
'female','shu',3,['tannang','tuoqiao'
			tannang:'探囊',
			tannang_info:'出牌階段限一次，你可以將一張梅花手牌當順手牽羊使用；你的順手牽羊無距離限制',
			tuoqiao:'煙瘴',
			tuoqiao_info:'你可以將一張黑色牌當作石灰粉使用',
]]--
sgs.LoadTranslationTable{
["pal_hanlingsha"] = "韓菱紗",
["tannang"] = "探囊",
["tannang_info"] = "出牌階段限一次，你可以將一張梅花手牌當順手牽羊使用；你的順手牽羊無距離限制",
["tuoqiao"] = "煙瘴",
["tuoqiao_info"] = "你可以將一張黑色牌當作石灰粉使用",
}
--[[
pal_mingxiu:'明繡',
'male','qun',4,['xtanxi','xiaoyue'
xtanxi:'探息',
			xtanxi_info:'出牌階段限一次，你可以棄置一張手牌，然後隨機選擇一名手牌中有與之同名的牌的敵方角色，觀看其手牌並獲得任意一張',
xiaoyue:'嘯月',
			xiaoyue_info:'鎖定技，每輪開始時，若你手牌中有殺，你將手牌中的一張隨機殺對一名隨機敵方角色使用，然後獲得一點護甲',

]]--
sgs.LoadTranslationTable{
["pal_mingxiu"] = "明繡",
["xtanxi"] = "探息",
["xtanxi_info"] = "出牌階段限一次，你可以棄置一張手牌，然後隨機選擇一名手牌中有與之同名的牌的敵方角色，觀看其手牌並獲得任意一張",
["xiaoyue"] = "嘯月",
["xiaoyue_info"] = "鎖定技，每輪開始時，若你手牌中有殺，你將手牌中的一張隨機殺對一名隨機敵方角色使用，然後獲得一點護甲",
}


--天照
crt_tainzao = sgs.General(extension,"crt_tainzao","qun2","3",false,true)
--天照：出牌或結束階段開始時，你可以展示牌堆頂四張牌，你獲得其中兩張牌，然後你使用牌的點數需於兩牌之間，直到回合結束/下個回合開始。
crt_sktainzao = sgs.CreateTriggerSkill{
	name = "crt_sktainzao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish or phase == sgs.Player_Start then
			if player:getMark("@tainzao_low") > 0 and player:getMark("@tainzao_high") > 0 then
				local pattern = ".|.|1~"..player:getMark("@tainzao_low").."|."
				room:removePlayerCardLimitation(player, "use,response", pattern)
				local pattern = ".|.|"..player:getMark("@tainzao_high").."~13|."
				room:removePlayerCardLimitation(player, "use,response", pattern)
				room:setPlayerMark(player, "@tainzao_high", 0)
				room:setPlayerMark(player, "@tainzao_low", 0)
			end
		end
		if phase == sgs.Player_Finish or phase == sgs.Player_Draw then
			if room:askForSkillInvoke(player, "crt_sktainzao", data) then
				local get_list = sgs.IntList()
				local ids = room:getNCards(4)
				room:fillAG(ids)
				for i = 1,2,1 do
					local id = room:askForAG(player, ids, true, self:objectName())
					ids:removeOne(id)
					get_list:append(id)
					room:takeAG(player,id, false)
				end
				local card = sgs.Sanguosha:getCard(get_list:at(0))
				local card2 = sgs.Sanguosha:getCard(get_list:at(1))
				room:clearAG()
				local move = sgs.CardsMoveStruct()
				move.card_ids = get_list
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				room:moveCardsAtomic(move, true)
				room:setPlayerMark(player, "@tainzao_high", math.max(card:getNumber(),card2:getNumber()))
				room:setPlayerMark(player, "@tainzao_low", math.min(card:getNumber(),card2:getNumber()))
				local pattern = ".|.|1~"..player:getMark("@tainzao_low").."|."
				room:setPlayerCardLimitation(player, "use,response", pattern, false)
				local pattern = ".|.|"..player:getMark("@tainzao_high").."~13|."
				room:setPlayerCardLimitation(player, "use,response", pattern, false)
			end
		end
	end
}
--神道:當你造成/受到傷害後，你可以與對方展示一張牌，若你的牌的點數小/大於其牌的點數，你可以令你或其回復一點體力/你與其各摸一張牌。
crt_sandow = sgs.CreateTriggerSkill{
	name = "crt_sandow",
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
			if not source:isKongcheng() and not dest:isKongcheng() then				
				if room:askForSkillInvoke(source, self:objectName(), data) then
					local card = room:askForCard(source,".|.|.|.","@crt_sandow_show",sgs.QVariant(),sgs.NonTrigger)
					room:showCard(source, card:getEffectiveId())
					local card2 = room:askForCard(dest,".|.|.|.","@crt_sandow_show",sgs.QVariant(),sgs.NonTrigger)
					room:showCard(dest, card2:getEffectiveId())
					if card:getNumber() < card2:getNumber() and event == sgs.Damage then
						local choices = {"crt_sandowSource", "crt_sandowDest"}
						local choice = room:askForChoice(player, "crt_sandow", table.concat(choices, "+"))
						local rec_player
						if choice == "crt_sandowSource" then
							rec_player = source
						elseif choice == "crt_sandowDest" then
							rec_player = dest
						end
						local theRecover = sgs.RecoverStruct()
						theRecover.recover = 1
						theRecover.who = source
						room:recover(rec_player, theRecover)
					elseif card:getNumber() > card2:getNumber() and event == sgs.Damaged then
						source:drawCards(1)
						dest:drawCards(1)
					end
				end				
			end
		end
		return false
	end
}
--驅役:主公技˙當你殺死一名角色時，你可以將你裝備區的一張牌置於其區域的相應位置並移除其武將牌和身分牌，然後令其體力回復至兩點，其勝利條件改為與你相同。
crt_chiyi = sgs.CreateTriggerSkill{
	name = "crt_chiyi$",
	events = {sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local mode = room:getMode()
		--if string.sub(mode, -1) == "p" or string.sub(mode, -2) == "pd" or string.sub(mode, -2) == "pz" then
			local dying = data:toDying()
			if dying.damage then
				local killer = dying.damage.from
				if killer and killer:isLord() then
					if not player:isLord() and player:getHp() <= 0 then
						if killer:hasSkill("crt_chiyi") then
							room:setPlayerFlag(player, "FenxinTarget")
							local ai_data = sgs.QVariant()
							ai_data:setValue(player)
							if room:askForSkillInvoke(killer, self:objectName(), ai_data) then
								local card_id = room:askForCardChosen(killer, killer, "e", self:objectName())
								local card = sgs.Sanguosha:getCard(card_id)
								local equip = card:getRealCard():toEquipCard()
								local index = equip:location()
								if player:getEquip(index) == nil then
									room:setPlayerProperty(player, "role", sgs.QVariant("loyalist"))
									room:setPlayerProperty(player, "hp", sgs.QVariant(2))
									room:changeHero(player, "sujiang", false, false, false, true)
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,
									killer:objectName(), self:objectName(), "")
									room:moveCardTo(card, killer, player, sgs.Player_PlaceEquip, reason)
								end
							end
							room:setPlayerFlag(player, "-FenxinTarget")
							return false
						end
					end
				end
			--end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
crt_tainzao:addSkill(crt_sktainzao)
crt_tainzao:addSkill(crt_sandow)
crt_tainzao:addSkill(crt_chiyi)

sgs.LoadTranslationTable{
	["crt_tainzao"] = "天照",
	["crt_sktainzao"] = "天照",
	[":crt_sktainzao"] = "出牌或結束階段開始時，你可以展示牌堆頂四張牌，你獲得其中兩張牌，然後你使用牌的點數需於兩牌之間，直到回合結束/下個回合開始。",
	["crt_sandow"] = "神道",
	[":crt_sandow"] = "當你造成/受到傷害後，你可以與對方展示一張牌，若你的牌的點數小/大於其牌的點數，你可以令你或其回復一點體力/你與其各摸一張牌。",
	["crt_chiyi"] = "驅役",
	[":crt_chiyi"] = "主公技˙當你殺死一名角色時，你可以將你裝備區的一張牌置於其區域的相應位置並移除其武將牌和身分牌，然後令其體力回復至兩點，其勝利條件改為與你相同。",
	["@crt_sandow_show"] = "請展示一張牌",
	["crt_sandowSource"] = "令你回復一點體力",
	["crt_sandowDest"] = "令其回復一點體力",
}



--奧丁
crt_audin = sgs.General(extension,"crt_audin","god","4",true,true)
--恆槍：轉換技，出牌階段限一次，1.當你使用一張牌後，若此牌為基本牌，你摸兩張牌；錦囊牌，你獲得一名角色區域內的一張牌；裝備牌，你對一名角色造成一點傷害2.當你對一名角色造成傷害時，你可以令此傷害+1；若你的體力值小於該角色，此傷害再+1
crt_hunchung = sgs.CreateTriggerSkill{
	name = "crt_hunchung",
	events = {sgs.GameStart,sgs.CardUsed,sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:getMark("@hunchung_yin") == 0 and player:getMark("@hunchung_yang") == 0 then
			room:setPlayerMark(player,"@hunchung_yang",1)
			room:setPlayerMark(player,"@hunchung_yin",0)
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and player:getPhase() == sgs.Player_Play
			 and player:getMark("@hunchung_yang") == 1 and (not player:hasFlag("used_hunchung")) then
				if room:askForSkillInvoke(player, "crt_hunchung", data) then
					room:setPlayerFlag(player, "used_hunchung")
					room:setPlayerMark(player,"@hunchung_yang",0)
					room:setPlayerMark(player,"@hunchung_yin",1)
					if use.card:isKindOf("BasicCard") then 
						player:drawCards(2)
					elseif use.card:isKindOf("TrickCard") then
						local _targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if player:canDiscard(p, "hej") then _targets:append(p) end
						end
						if not _targets:isEmpty() then
							local to_discard = room:askForPlayerChosen(player, _targets, "crt_hunchung", "@crt_hunchung1", true)
							if to_discard then
								room:obtainCard(player,room:askForCardChosen(player, to_discard, "hej", "crt_hunchung", false, sgs.Card_MethodDiscard), true)
							end
						end
					elseif use.card:isKindOf("EquipCard") then
						local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "crt_hunchung", "@crt_hunchung2", true)
						if s then
							room:damage(sgs.DamageStruct("crt_hunchung", player, s, 1, sgs.DamageStruct_Normal))
						end
					end		
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if player:getMark("@hunchung_yin") == 1 and (not player:hasFlag("used_hunchung")) then
				local _data = sgs.QVariant()
				_data:setValue(damage.to)
				if room:askForSkillInvoke(player, "crt_hunchung", _data) then
					room:setPlayerFlag(player, "used_hunchung")
					room:setPlayerMark(player,"@hunchung_yang",1)
					room:setPlayerMark(player,"@hunchung_yin",0)
					damage.damage = damage.damage + 1
					if damage.to:getHp() > damage.from:getHp() then
						local s = room:askForPlayerChosen(player, room:getOtherPlayers(damage.to), "crt_hunchung", "@crt_hunchung2", true)
						if s then
							room:damage(sgs.DamageStruct("crt_hunchung", player, s, 1, sgs.DamageStruct_Normal))
						end
					end
					data:setValue(damage)
				end
			end
			return false				
		end
	end,
}
--絕志：鎖定技，當你的體力值大於1時，其他角色對你造成的傷害最多只會使你的體力值扣至1點
crt_jueji = sgs.CreateTriggerSkill{
	name = "crt_jueji",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:getHp() > 1 and player:getHp() <= damage.damage then	
			damage.damage = player:getHp() - 1
			data:setValue(damage)
		end
	end
}

crt_audin:addSkill(crt_hunchung)
crt_audin:addSkill(crt_jueji)

sgs.LoadTranslationTable{
	["crt_audin"] = "奧丁",
	["&crt_audin"] = "奧丁",
	["crt_hunchung"] = "恆槍",
	[":crt_hunchung"] = "轉換技，出牌階段限一次，1.當你使用一張牌後，若此牌為基本牌，你摸兩張牌；錦囊牌，你獲得一名角色區域內的一張牌；裝備牌，你對一名角色造成一點傷害2.當你對一名角色造成傷害時，你可以令此傷害+1；若你的體力值小於該角色，你可以對另一名角色再造成一點傷害",
	["@crt_hunchung1"] = "獲得一名角色區域內的一張牌",
	["@crt_hunchung2"] = "你對一名角色造成一點傷害",
	["crt_jueji"] = "絕志",
	[":crt_jueji"] = "鎖定技，當你的體力值大於1時，其他角色對你造成的傷害最多只會使你的體力值扣至1點",
}


--假新聞文鴦
crt_character1 = sgs.General(extension,"crt_character1","qun2","3",false,true,true)





--裸衣:若你沒有裸衣標記，摸牌階段你可以多摸至多X張牌(X為體力上限)，獲得等量裸衣標記;當你使用僅指定一名玩家的傷害牌時，你可以棄置1張牌，令此傷害+1，然後移去一個標記。

sgs.Sanguosha:addSkills(skills)

