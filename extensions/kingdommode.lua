module("extensions.kingdommode", package.seeall)
extension = sgs.Package("kingdommode")

sgs.LoadTranslationTable{
	["kingdommode"] = "國戰專用",
}

--曹仁
kb_caoren = sgs.General(extension, "kb_caoren", "wei", "4", true)
--據守
getKingdoms_for_kb = function(player)
	local kingdoms = {}
	for _, p in sgs.qlist(player:getRoom():getAlivePlayers()) do
		local flag = true
		for _, k in ipairs(kingdoms) do
			if p:getKingdom() == k  then
				flag = false
				break
			end
		end
		if p:getKingdom() == "god" then
			flag = false
		end

		if flag then
			table.insert(kingdoms, p:getKingdom())
		end
	end
	return #kingdoms
end

kb_jushou = sgs.CreateTriggerSkill{
	name = "kb_jushou" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		if room:askForSkillInvoke(player, "kb_jushou", data) then
			room:notifySkillInvoked(player, "kb_jushou")
			room:broadcastSkillInvoke(self:objectName())
			local n = getKingdoms_for_kb(player)
			player:drawCards(n)
			local card = room:askForCard(player,".|.|.|hand!", "@jushou", data, sgs.Card_MethodNone)
			if card then
				if card:isKindOf("EquipCard") then
					local use = sgs.CardUseStruct()
					use.card = card
					use.from = player
					use.to:append(player)
					room:useCard(use)
--					local self_weapon = player:getWeapon()
--					local self_dh = player:getDefensiveHorse()
--					local self_oh = player:getOffensiveHorse()
--					local self_armor = player:getArmor()
--					if (not self_weapon) and card:isKindOf("Weapon") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					elseif (not self_dh) and card:isKindOf("DefensiveHorse") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					elseif (not self_oh) and card:isKindOf("OffensiveHorse") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					elseif (not self_armor) and card:isKindOf("Armor") then
--						room:moveCardTo(card, player, sgs.Player_PlaceEquip)
--					else
--						room:throwCard(card, player, player)
--					end
				else
					room:throwCard(card, player, player)
				end
			end
			if n > 2 then
				player:turnOver()
			end
		end
		return false
	end
}

kb_caoren:addSkill(kb_jushou)

sgs.LoadTranslationTable{
	["kb_caoren"] = "國戰曹仁",
	["&kb_caoren"] = "曹仁",
	["#kb_caoren"] = "神勇禦敵",
	["@jushou"] = "請棄置一張手牌",
	["kb_jushou"] = "據守",
	[":kb_jushou"] = "結束階段，你可以發動此技能。然後你摸X張牌（X為此時亮明勢力數），棄置一張手牌，若以此法棄置的是裝備牌，則改為你使用之。若X大於2，則你將武將牌翻面。",
	["@kb_jushou"]="請棄置一張牌，若以此法棄置的是裝備牌，則你改為使用之",


}


-- 趙雲
kb_zhaoyun = sgs.General(extension, "kb_zhaoyun", "shu", "4", true)

kb_longdan_buff = sgs.CreateTriggerSkill{
	name = "#kb_longdan_buff",
	events = {sgs.SlashMissed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if effect.from:isAlive() and effect.from:hasSkill(self:objectName()) and effect.slash:getSkillName() == "longdan" then
				if effect.from:askForSkillInvoke(self:objectName(), data) then
					local p = room:askForPlayerChosen(player, room:getOtherPlayers(player), "kb_longdan_damage", "@kb_longdan-damage", true)
					if p then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:damage(sgs.DamageStruct("longdan", player, p, 1, sgs.DamageStruct_Normal))
					end
				end
			elseif effect.to:isAlive() and effect.to:hasSkill(self:objectName()) and effect.jink:getSkillName() == "longdan" then
				if effect.to:askForSkillInvoke(self:objectName(), data) then
					local p = room:askForPlayerChosen(player, room:getOtherPlayers(player), "kb_longdan_rec", "@kb_longdan-rec", true)
					if p then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:recover(p, sgs.RecoverStruct(p, nil,1))
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

kb_zhaoyun:addSkill(kb_longdan_buff)
kb_zhaoyun:addSkill("longdan")

sgs.LoadTranslationTable{
	["kb_zhaoyun"] = "國戰趙雲",
	["&kb_zhaoyun"] = "趙雲",
	["#kb_zhaoyun"] = "虎威將軍",
	["kb_longdan_damage"] = "龍膽",
	["kb_longdan_rec"] = "龍膽",
	["#kb_longdan_buff"] = "龍膽",
}


--[[
b、 諸葛亮
技能：空城
①鎖定技，若你沒有手牌：1、當你成為【殺】或【決鬥】的目標時，取消之；2、你的回合外，其他角色交給你的牌置於你的武將牌上。
②鎖定技，摸牌階段開始時，你獲得你武將牌上的牌。
]]--
kb_zhugeliang = sgs.General(extension, "kb_zhugeliang", "shu", "3", true)

kb_kongcheng_buff = sgs.CreateTriggerSkill{
	name = "#kb_kongcheng_buff",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (not room:getTag("FirstRound"):toBool()) and player:getPhase() == sgs.Player_NotActive and move.from and move.to and move.from:objectName() ~= move.to:objectName() and move.to:objectName() == player:objectName() then
				local ids = sgs.IntList()
				for _,id in sgs.qlist(move.card_ids) do
					if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then
						ids:append(id)
					end
				end
				if ids:isEmpty() then return false end	
				player:addToPile("kb_kongcheng", ids)
			end
		else
			if player:getPhase() == sgs.Player_Start then
				if not player:getPile("kb_kongcheng"):isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(player:getPile("kb_kongcheng"))
					room:obtainCard(player, dummy, false)
				end
			end
		end
		return false
	end,
}

kb_zhugeliang:addSkill("kongcheng")
kb_zhugeliang:addSkill(kb_kongcheng_buff)
kb_zhugeliang:addSkill("guanxing")

sgs.LoadTranslationTable{
["#kb_zhugeliang"] = "遲暮的丞相",
["kb_zhugeliang"] = "國戰諸葛亮",
["&kb_zhugeliang"] = "諸葛亮",

["kb_kongcheng"] = "空城",
}

--[[
c、 劉備
技能：仁德
修改前：出牌階段，你可以將任意張手牌交給其他角色，然後你於此階段內給出第三張手牌時，你回复1點體力。
修改後：出牌階段，你可以將任意張手牌交給一名本階段未獲得過“仁德”牌的其他角色。當你於本階段給出第二張“仁德”牌時，你可以視為使用一張基本牌。
]]--
--[[
d、 馬超
技能：鐵騎
修改前：當你使用【殺】指定一個目標後，你可令其本回合內非鎖定技失效，然後你進行判定，除非該角色棄置與結果花色相同的一張牌，否則不能使用【閃】響應此【殺】。
修改後：當你使用【殺】指定一個目標後，你可以進行判定，然後令其本回合一張明置的武將牌的所有非鎖定技失效，除非該角色棄置與結果花色相同的一張牌，否則不能使用【閃】。
]]--
--[[
e、 甘夫人
技能：淑慎
修改前：當你回复1點體力時，你可令與你勢力相同的一名其他角色摸一張牌。
修改後：當你回复1點體力後，你可以令一名其他角色摸一張牌。
]]--
--[[
f、 張飛
技能：咆哮
修改前：出牌階段，你可明置此武將牌；鎖定技，你使用【殺】無次數限制。
修改後：鎖定技，你使用【殺】無次數限制；你在一回合內使用第二張【殺】時，摸一張牌。
]]--
kb_zhangfei = sgs.General(extension, "kb_zhangfei", "shu", "4", true)

kb_paoxiao = sgs.CreateTriggerSkill{
	name = "kb_paoxiao" ,
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
				if player:getMark("used_slash_Play") == 2 then
					player:drawCards(1)
				end
			end
		end
	end
}

kb_paoxiaoTM = sgs.CreateTargetModSkill{
	name = "#kb_paoxiaoTM",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, from, card)
		if from:hasSkill("kb_paoxiao") then
			return 1000
		else
			return 0
		end
	end,
}

kb_zhangfei:addSkill(kb_paoxiao)
kb_zhangfei:addSkill(kb_paoxiaoTM)

sgs.LoadTranslationTable{
["#kb_zhangfei"] = "萬夫不當",
["kb_zhangfei"] = "國戰張飛",
["&kb_zhangfei"] = "張飛",
["illustrator:kb_zhangfei"] = "SONGQIJIN",
["kb_paoxiao"] = "咆哮",
[":kb_paoxiao"] = "鎖定技，你使用【殺】無次數限制；你在一回合內使用第二張【殺】時，摸一張牌。",
}


--[[
3、 吳勢力
a、 孫堅
體力2改為體力2.5
b、 周泰
技能（新增）：奮激
效果：一名角色的結束階段，若其沒有手牌，你可令其摸兩張牌，然後你失去一點體力。
技能：不屈
修改前：鎖定技，當你處於瀕死狀態時，你將牌堆頂的一張牌置於你的武將牌上，稱為創，若此牌的點數與已有的創點數均不同，則你將體力回復至1點。若出現相同點數則將此牌置入棄牌堆。若你的武將牌上有創，則你的手牌上限與創的數量相等。
修改後：鎖定技，當你處於瀕死狀態時，你將牌堆頂的一張牌置於你的武將牌上，稱為"創"：若此牌點數與已有的"創"點數均不同，你將體力回復至1點；若點數相同，將此牌置入棄牌堆。
]]--
kb_zhoutai = sgs.General(extension, "kb_zhoutai", "wu", 4, true)

kb_fenji = sgs.CreateTriggerSkill{
	name = "kb_fenji",
	events = {sgs.Damaged,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if room:askForSkillInvoke(p, self:objectName(), data) then
					player:drawCards(2)
					room:loseHp(p,1)
				end
			end
		end
	end,
}

kb_buqu = sgs.CreateTriggerSkill{
	name = "kb_buqu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, zhoutai, data)
		local room = zhoutai:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() ~= zhoutai:objectName() then
			return false
		end
		if zhoutai:getHp() > 0 then return false end
		room:sendCompulsoryTriggerLog(zhoutai, self:objectName())
		local id = room:drawCard()
		local num = sgs.Sanguosha:getCard(id):getNumber()
		local duplicate = false
		for _, card_id in sgs.qlist(zhoutai:getPile("kb_buqu")) do
			if sgs.Sanguosha:getCard(card_id):getNumber() == num then
				duplicate = true
				break
			end
		end
		zhoutai:addToPile("kb_buqu", id)
		if duplicate then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
			room:throwCard(sgs.Sanguosha:getCard(id), reason, nil)
		else
			room:recover(zhoutai, sgs.RecoverStruct(zhoutai, nil, 1 - zhoutai:getHp()))
		end
		return false
	end
}

kb_zhangfei:addSkill(kb_buqu)
kb_zhangfei:addSkill(kb_fenji)

sgs.LoadTranslationTable{
["#kb_zhoutai"] = "歷戰之驅",
["kb_zhoutai"] = "國戰周泰",
["&kb_zhoutai"] = "周泰",
["illustrator:zhoutai"] = "Thinking",
["kb_buqu"] = "不屈",
[":kb_buqu"] = "鎖定技。每當你處於瀕死狀態時，你將牌堆頂的一張牌置於武將牌上：若無同點數的“不屈牌”，你回復至1點體力；否則你將此牌置入棄牌堆。",
["kb_fenji"] = "奮激",
[":kb_fenji"] = "一名角色的結束階段，若其沒有手牌，你可令其摸兩張牌，然後你失去一點體力。",
}



--[[
c、 周瑜
技能：反間
修改前：出牌階段限一次，你可以令一名其他角色選擇一種花色，然後該角色獲得你的一張手牌並展示之，若此牌的花色與其所選的花色不同，則你對其造成1點傷害。
修改後：出牌階段限一次，你可以展示一張手牌並將之交給一名其他角色，該角色選擇一項：1.展示所有手牌，然後棄置與此牌花色相同的所有牌； 2.失去1點體力。
技能：英姿
修改前：摸牌階段，你可以額外摸一張牌。
修改後：鎖定技，摸牌階段，你多摸一張牌；你的手牌上限等於X（X為你的體力上限）。
]]--
--[[
d、 黃蓋
技能：苦肉
修改前：出牌階段，你可以失去1點體力，然後摸兩張牌。
修改後：出牌階段限一次，你可以棄一張牌。若如此做，你失去1點體力，然後摸三張牌，此階段你使用【殺】的次數上限+1。
]]--
kb_huanggai = sgs.General(extension, "kb_huanggai", "wu", 4, true)

kb_kurouCard = sgs.CreateSkillCard{
	name = "kb_kurou",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source)
		source:drawCards(3)
		room:setPlayerMark(source,"kb_kurou_Play")
	end
}
kb_kurou = sgs.CreateOneCardViewAsSkill{
	name = "kb_kurou",
	filter_pattern = ".!",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kb_kurou")
	end, 
	view_as = function(self, originalCard) 
		local card = kb_kurouCard:clone()
		card:addSubcard(originalCard)
		card:setSkillName(self:objectName())
		return card
	end
}

kb_kurouTM = sgs.CreateTargetModSkill{
	name = "#kb_kurouTM",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, from, card)
		if from:getMark("kb_kurou_Play") > 0 then
			return 1
		else
			return 0
		end
	end,
}

kb_huanggai:addSkill(kb_kurou)
kb_huanggai:addSkill(kb_kurouTM)

sgs.LoadTranslationTable{
["#kb_huanggai"] = "輕身為國",
["kb_huanggai"] = "國戰黃蓋",
["&kb_huanggai"] = "黃蓋",
["illustrator:kb_huanggai"] = "G.G.G.",
["kb_kurou"] = "苦肉",
[":kb_kurou"] = "出牌階段限一次，你可以棄一張牌。若如此做，你失去1點體力，然後摸三張牌，此階段你使用【殺】的次數上限+1。",
}

--[[
e、 小喬
技能：天香
修改前：當你受到傷害時，你可以棄置一張紅桃手牌並選擇一名其他角色。若如此做，你將此傷害轉移給該角色，然後其摸X張牌（X為該角色已損失的體力值）。
修改後：當你受到傷害時，你可以棄置一張紅桃手牌,防止此次傷害並選擇一名其他角色，你選擇一項：令其受到1點傷害，然後摸X張牌（X為其已損失體力值且至多為5）；令其失去1點體力，然後其獲得你棄置的牌。
]]--
kb_xiaoqiao = sgs.General(extension, "kb_xiaoqiao", "wu", 3, false)

kb_xiaoqiao:addSkill("hongyan")
kb_xiaoqiao:addSkill("ol_tianxiang")


sgs.LoadTranslationTable{
	["kb_xiaoqiao"] = "國戰小喬",
	["&kb_xiaoqiao"] = "小喬",
	["#kb_xiaoqiao"] = "矯情之花",
	["illustrator:kb_xiaoqiao"] = "Town",
	--["hongyan_po"] = "紅顏",
	--[":hongyan_po"] = "鎖定技。妳的黑桃牌視為紅桃牌；當妳於回合外失去紅桃牌時，妳摸ㄧ張牌。",
	["ol_tianxiang"] = "天香",
	[":ol_tianxiang"] = "當你受到傷害時，你可以棄置一張紅桃牌並防止此傷害並選擇一名其他角色，你選擇一項：1.來源對其造成1點傷害，其摸X張牌；2.其失去1點體力，獲得你以此法棄置的牌。（X為其已損失的體力值且至多為5）",
	["$ol_tianxiang1"] = "替我擋著~",
	["$ol_tianxiang2"] = "接著哦~",
	["~ol_xiaoqiao"] = "公瑾…我先走一步……",
	["@ol_tianxiang"] = "請選擇“天香”的目標",
	["~ol_tianxiang"] = "選擇一張<font color=\"red\">♥</font>牌→選擇一名其他角色→點擊確定",
	["tianxiang1"] = "其摸X張牌",
	["tianxiang2"] = "其失去1點體力，獲得你以此法棄置的牌。",
}


--[[
f、 呂蒙
技能：克己
修改前：若你未於出牌階段內使用或打出過【殺】，則你可以跳過棄牌階段。
修改後：鎖定技，若你未於出牌階段內使用過顏色不同的牌，則你本回合的手牌上限+4。
技能（新增）：謀斷
效果：結束階段，若你於出牌階段內使用過四種花色或三種類別的牌，則你可以移動場上的一張牌。
]]--
--[[
4、 群勢力
a、 華佗
技能（刪除）：青囊
技能（新增）：除癘
效果：出牌階段限一次，你可以選擇至多三名勢力各不相同或未確定勢力的其他角色，然後你棄置你和這些角色的各一張牌。被棄置黑桃牌的角色各摸一張牌。
]]--
--[[
b、 袁紹
技能：亂擊
修改前：你可以將兩張花色相同的手牌當【萬箭齊發】使用。
修改後：出牌階段，你可以將兩張手牌當【萬箭齊發】使用（不能使用本回合發動此技能時已用過的花色） 。若如此做，當與你勢力相同的角色因響應此【萬箭齊發】而打出的【閃】結算結束時，其可以摸一張牌。
]]--
--[[
c、 龐德
技能（刪除）：猛進
技能（新增）：鞬出
效果：當你使用【殺】指定一個目標後，你可以棄置其一張牌，若棄置的牌：是裝備牌，該角色不能使用【閃】；不是裝備牌，該角色獲得此【殺】。
]]--
--[[
d、 鄒氏
技能：傾城
修改前：出牌階段，你可以棄置一張裝備牌並選擇一名武將牌均明置的其他角色，然後你暗置其一張武將牌。
修改後：出牌階段，你可以棄置一張黑色牌並選擇一名武將牌均明置的其他角色，然後你暗置其一張武將牌。然後若你以此法棄置的牌是裝備牌，則你可以再選擇另一名武將牌均明置的其他角色，暗置其一張武將牌。
]]--




