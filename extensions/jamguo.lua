module("extensions.jamguo", package.seeall)
extension = sgs.Package("jamguo")

sgs.LoadTranslationTable{
	["jamguo"] = "戰國",
}
--信長
jg_OdaNobunaga = sgs.General(extension, "jg_OdaNobunaga", "wei2", "4", true, true)


--焚寺：回合開始時，你可以對一名角色造成1~2點火焰屬性傷害；若該角色因此進入瀕死狀態，攻擊範圍內有你的角色可以對你使用一張「殺」
--天魔：每當你受到傷害時，你可以將一張牌當「殺」使用，若此「殺」未造成傷害，你摸一張牌
--fensi tianmo

jg_fensi = sgs.CreatePhaseChangeSkill{
	name = "jg_fensi", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "jg_fensi-invoke", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Fire))
				if target:getHp() <= 0 then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:distanceTo(player) <= p:getAttackRange() and player:isAlive() then
							room:askForUseSlashTo(p, player, "@sk_pengri:"..player:objectName(),true)
						end
					end
				end
			end
		end
	end
}

jg_tianmoVS = sgs.CreateOneCardViewAsSkill{
	name = "jg_tianmo",
	view_filter = function(self, card)
		return not card:isEquipped() and not sgs.Self:isJilei(card)
	end,
	response_or_use = true,
	view_as = function(self, card)
		local skillcard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		skillcard:addSubcard(card:getEffectiveId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@jg_tianmo"
	end
}
jg_tianmo = sgs.CreateTriggerSkill{
	name = "jg_tianmo",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = jg_tianmoVS,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			room:askForUseCard(player, "@jg_tianmo", "@jg_tianmo", -1, sgs.Card_MethodNone)
		end
		return false
	end
}

sgs.LoadTranslationTable{
    ["jg_OdaNobunaga"] = "織田信長",
	["#jg_OdaNobunaga"] = "第六天霸王",

}

--豐臣秀吉
jg_ToyotomiHideyoshi = sgs.General(extension, "jg_ToyotomiHideyoshi", "qun2", "4", true, true)

--築城
 
--大返
jg_Dafan = sgs.CreateTriggerSkill{
	name = "jg_Dafan" ,
	frequency = sgs.Skill_Limited ,
	limit_mark = "@comeback",
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local jg_ToyotomiHideyoshi = room:findPlayerBySkillName(self:objectName())
		if not jg_ToyotomiHideyoshi or jg_ToyotomiHideyoshi:objectName() == player:objectName() then return false end
		if jg_ToyotomiHideyoshi:getMark("@comeback") <= 0 then return false end
		if room:askForSkillInvoke(jg_ToyotomiHideyoshi, "jg_Dafan", data) then
			room:setPlayerFlag(jg_ToyotomiHideyoshi, "dafan")
			jg_ToyotomiHideyoshi:gainAnExtraTurn()
			room:removePlayerMark(jg_ToyotomiHideyoshi, "@comeback")
			room:setPlayerFlag(jg_ToyotomiHideyoshi, "-dafan")
		end
		return false
	end
}

jg_DafanDistance = sgs.CreateDistanceSkill{
	name = "#jg_DafanDistance",
	correct_func = function(self, from, to)
		if from:hasSkill(jg_Dafan) and from:hasFlag("dafan") then
			return -99
		else
			return 0
		end
	end  
}

jg_ToyotomiHideyoshi:addSkill(jg_Dafan)
jg_ToyotomiHideyoshi:addSkill(jg_DafanDistance)


sgs.LoadTranslationTable{
    ["jg_ToyotomiHideyoshi"] = "豐臣秀吉",
	["#jg_ToyotomiHideyoshi"] = "太閣",
	["jg_zuchen"] = "築城",
	[":jg_zuchen"] = "你的回合結束時，你可以令其他角色選擇是否放置一張牌在你的武將牌上，稱為「城」；每當你受到一點傷害時，你棄置一張「城」；你的回合開始時，若你的武將牌上有「城」，你令等量名角色摸一張牌，然後將「城」分配給任意名角色",
	["jg_Dafan"] = "大返",
	[":jg_Dafan"] = "限定技，任意角色的回合結束時，你可以立即進行一個新的回合。此回合內你打出或使用的【殺】和錦囊牌無距離限制",
	["castles"] = "城",
}

--德川家康
jg_TokugawaIeyasu = sgs.General(extension, "jg_TokugawaIeyasu", "wu2", "4", true, true)

--危盟
jg_weimon = sgs.CreateTriggerSkill{
	name = "jg_weimon" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local t = room:askForPlayerChosen(player, room:getOtherPlayers(player), "jg_weimon", "@jg_weimon-choose", true)
			if t then
				local n1 = player:getHandcardNum()
				local n2 = t:getHandcardNum()
				if n1 > n2 then
					room:drawCards(t, (n1-n2), "jg_weimon")
				elseif n2 > n1 then
					room:askForDiscard(t, "jg_weimon", (n2-n1), (n2-n1), false, false)
				end
				if (n1 - n2) > 2 or (n2 - n1) > 2 then
					room:loseHp(player)
				end
			end
		end
		return false
	end ,
}

jg_TokugawaIeyasuSub = sgs.General(extension, "jg_TokugawaIeyasuSub", "tan", 3, true, true, true)
--調兵
jg_diaobeenCard = sgs.CreateSkillCard{
	name = "jg_diaobeenCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), tiger:objectName(), "jg_diaobeen","")
		room:moveCardTo(self,tiger,sgs.Player_PlaceHand,reason)
		local _targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(tiger)) do
			if tiger:inMyAttackRange(p) then 
				_targets:append(p) 
			end
		end
		if not _targets:isEmpty() then
			local wolf = room:askForPlayerChosen(source, _targets, "str_chizhi", "@jg_diaobeen-slash", true)
			if wolf then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("jg_diaobeen")
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = tiger
				local dest = wolf
				use.to:append(dest)
				if tiger:isAlive() then
					room:useCard(use)
				end
			end
		end
	end,
}
jg_diaobeen = sgs.CreateOneCardViewAsSkill{
	name = "jg_diaobeen",
	filter_pattern = ".|.|.|.!",
	view_as = function(self,card)
		local ymc = jg_diaobeenCard:clone()
		ymc:addSubcard(card)
		ymc:setSkillName(self:objectName())
		return ymc
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#jg_diaobeenCard") < 1
	end,
}

--待發
jg_Diefa = sgs.CreateTriggerSkill{
	name = "jg_Diefa",
	frequency = sgs.Skill_Wake,
	events = {sgs.Death},
	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("Diefa") == 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "Diefa", 1)
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() then return false end
		if player:isAlive() and player:getMark("Diefa") == 1 and room:changeMaxHpForAwakenSkill(player) then
			room:doSuperLightbox("jg_TokugawaIeyasu","jg_Diefa")
			if player:getHp() < 3 then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 3 - player:getHp()
				room:recover(player, recover)
			end
			room:acquireSkill(player, "jg_diaobeen")
		end
	end,
}

jg_TokugawaIeyasu:addSkill(jg_weimon)
jg_TokugawaIeyasu:addSkill(jg_Diefa)
jg_TokugawaIeyasuSub:addSkill(jg_diaobeen)


sgs.LoadTranslationTable{
    ["jg_TokugawaIeyasu"] = "德川家康",
	["#jg_TokugawaIeyasu"] = "大將軍",
	["jg_weimon"] = "危盟",
	[":jg_weimon"] = "摸牌階段結束時，你可以令一名角色將手牌數調整至與你相同，若該角色以此法摸/棄三張以上的牌時，你失去一點體力",
	["jg_Diefa"] = "待發",
	[":jg_Diefa"] = "覺醒技。當一名角色死亡後，你失去一點體力上限，恢復體力至三點，並獲得技能「調兵」",
	["jg_diaobeen"] = "調兵",
	[":jg_diaobeen"] = "出牌階段限一次，你可以交給一名角色一張手牌，然後其視為對你指定的一名角色使用一張「殺」",
	["@jg_weimon-choose"] = "你可以令一名角色將手牌數調整至與你相同",
	["@jg_diaobeen-slash"] = "請選擇一名角色，該角色視為對其使用一張「殺」"
}

--真田幸村
jg_SanadaNobushige = sgs.General(extension, "jg_SanadaNobushige", "shu2", "4", true)

--影突
jg_yintu = sgs.CreateTriggerSkill{
	name = "jg_yintu" ,
	events = {sgs.CardResponded, sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local invoke = 0
		if event == sgs.CardResponded then
	        	local resp = data:toCardResponse()
	        	if resp.m_card:getSkillName() == "longdan" then
		            	invoke = 1
	        	end
	        else
			local use = data:toCardUse()
			if use.card:getSkillName() == "longdan" then
	                	invoke = 1
			end
	        end
		if invoke == 1 then
			if player:getMark("@jg_yintu") > 0 then
				local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "jg_yintu", "@jg_yintutext", true)
				if s then
					local choices = {"getmark", "usemark_damage","usemark_recover"}
					local choice = room:askForChoice(player, "jg_yintu1", table.concat(choices, "+"))
					if choice == "getmark" then
						player:gainMark("@jg_yintu", 1)
					elseif choice == "usemark_damage" then
						player:loseMark("@jg_yintu", 1)
						room:damage(sgs.DamageStruct("jg_yintu", player, s, 1, sgs.DamageStruct_Normal))
					elseif choice == "usemark_recover" then
						player:loseMark("@jg_yintu", 1)
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = 1
						room:recover(s, recover)
					end
				else
					player:gainMark("@jg_yintu", 1)
				end
			else
				player:gainMark("@jg_yintu", 1)
			end
		end
	        return false
	end
}

jg_SanadaNobushige:addSkill("longdan")
jg_SanadaNobushige:addSkill(jg_yintu)

sgs.LoadTranslationTable{
    ["jg_SanadaNobushige"] = "真田幸村",
	["#jg_SanadaNobushige"] = "日本第一兵",
	["jg_yintu"] = "影突",
	[":jg_yintu"] = "每當你發動〖龍膽〗時，你可以選擇一項：獲得一枚「影突」標記；或是棄置一枚「影突」標記，並對一名角色造成一點傷害或令一名角色回復一點體力",
	["@jg_yintutext"] = "你可以對一名角色發動技能「影突」",
	["@jg_yintu"] = "影突",
}

--阿市
jg_OichinoKata = sgs.General(extension, "jg_OichinoKata", "wei2", "3", false, true)
--結姻



jg_OichinoKata:addSkill("hongyan")

sgs.LoadTranslationTable{
    ["jg_OichinoKata"] = "阿市",
	["#jg_OichinoKata"] = "戰國第一美人",
}

--明智光秀（舊版）
jg_OldAkechiMitsuhide = sgs.General(extension, "jg_OldAkechiMitsuhide", "wei2", "4", true, true)
--三段
jg_OldshandianCard = sgs.CreateSkillCard{
	name = "jg_OldshandianCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local player = sgs.Self
			if player:canSlash(to_select, nil, false) then
				return true
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@sanshoot")
		local fire_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		fire_slash:setSkillName("jg_Oldshandian")
		local use = sgs.CardUseStruct()
		use.card = fire_slash
		use.from = source
		local dest = targets[1]
		use.to:append(dest)
		room:doLightbox("$shandianlimit", 3000)
		dest:addQinggangTag(fire_slash)
		if source:isAlive() then
			room:useCard(use)
		end
		if source:isAlive() then
			room:useCard(use)
		end		
		if source:isAlive() then
			room:useCard(use)
		end
		room:setPlayerFlag(source, "shandian_used")
	end
} 
jg_OldshandianVS = sgs.CreateViewAsSkill{
	name = "jg_Oldshandian",
	n = 0,
	view_as = function(self, cards)
		local card = jg_OldshandianCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@sanshoot") > 0
	end
}
jg_Oldshandian = sgs.CreateTriggerSkill{
		name = "jg_Oldshandian",
		frequency = sgs.Skill_Limited,
		limit_mark = "@sanshoot",
		view_as_skill = jg_OldshandianVS ,
		on_trigger = function() 
		end
}
--裹切
jg_liche = sgs.CreateTriggerSkill{
	name = "jg_liche",
	frequency = sgs.Skill_Wake,
	events = {sgs.Damage},
	can_trigger = function(self, target)
		return target:isAlive() and target:hasSkill(self:objectName()) and target:getMark("liche") == 0 and target:isWounded()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Fire then
			if room:changeMaxHpForAwakenSkill(player) then
				room:doSuperLightbox("jg_AkechiMitsuhide","jg_liche")
				room:acquireSkill(player, "wansha")
				room:setPlayerProperty(player, "hp", sgs.QVariant(3))
				room:setPlayerMark(player, "liche", 1)
			end
		end
	end,
}
jg_OldAkechiMitsuhide:addSkill("guicai")
jg_OldAkechiMitsuhide:addSkill(jg_Oldshandian)
jg_OldAkechiMitsuhide:addSkill(jg_liche)

sgs.LoadTranslationTable{
    ["jg_OldAkechiMitsuhide"] = "明智光秀--舊版",
    ["&jg_OldAkechiMitsuhide"] = "明智光秀",
	["#jg_OldAkechiMitsuhide"] = "魔之宰相",
	["jg_Oldshandian"] = "三段",
	[":jg_Oldshandian"] = "限定技。出牌階段你可視為對一名由你指定的其他角色連續打出三張火【殺】，此火【殺】無視距離。",
	["jg_liche"] = "裹切",
	[":jg_liche"] = "覺醒技，當你對一名角色造成火焰傷害時，若你已受傷，你需減少一點體力上限，並將體力回復至三點，然後獲得技能“完殺”。",
	["$shandianlimit"] = "聽我的號令，射擊！開槍！",
}

--明智光秀
jg_AkechiMitsuhide = sgs.General(extension, "jg_AkechiMitsuhide", "wei2", "4", true, true)
--


--三段
jg_shandian = sgs.CreateTriggerSkill{
	name = "jg_shandian" ,
	events = {sgs.CardFinished} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then 
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					if player:getMark("jg_shandian") < 3 then
						if room:askForUseSlashTo(player, p, "@jg_shandian:"..p:objectName(),true) then
							room:setPlayerMark(player,"jg_shandian",player:getMark("jg_shandian")+1)
						end
					end
				end
			end
		end
	end
}


jg_AkechiMitsuhide:addSkill(jg_shandian)
jg_AkechiMitsuhide:addSkill(jg_liche)

sgs.LoadTranslationTable{
    ["jg_AkechiMitsuhide"] = "明智光秀",
	["#jg_AkechiMitsuhide"] = "魔之宰相",
	["jg_shandian"] = "三段",
	[":jg_shandian"] = "當你對一名角色使用「殺」結算後，你可以對該角色再使用一張「殺」，你每回合以此法使用的「殺」最多三張",
	["@jg_shandian"] = "你可以對 %src 使用一張【殺】。",
	["@jg_zezhugive"] = "請交給 %src 一張牌",
}

--濃姬
jg_Nohime = sgs.General(extension, "jg_Nohime", "wei2", "3", false, true)

jg_wangyu = sgs.CreateTriggerSkill{
	name = "jg_wangyu",
	events = {sgs.DamageInflicted,sgs.Damaged},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			for _,s in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (damage.from:objectName() ==  s:objectName() or damage.to:objectName()== s:objectName()) and (not s:isKongcheng()) then
					if s:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local choices = {"wangyu_plus", "wangyu_minus"}
						local choice = room:askForChoice(s, "jg_wangyu", table.concat(choices, "+"))
						local msg = sgs.LogMessage()
						msg.type = "#JgWangyu"
						msg.from = s
						msg.to:append(damage.to)
						if choice == "wangyu_plus" then	
							damage.damage = damage.damage + 1
							room:setPlayerFlag(damage.to, "wangyu_plus")
							msg.arg = tostring(damage.damage - 1)
							msg.arg2 = tostring(damage.damage)
						elseif choice == "wangyu_minus" then
							damage.damage = damage.damage - 1
							room:setPlayerFlag(damage.to, "wangyu_minus")
							msg.arg = tostring(damage.damage - 1)
							msg.arg2 = tostring(damage.damage)
						end
						room:sendLog(msg)
						if damage.damage > 0 then
							data:setValue(damage)
						elseif damage.damage == 0 then
							return true
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			room:broadcastSkillInvoke(self:objectName())
			if damage.to:hasFlag("wangyu_plus") then
				damage.to:drawCards(damage.to:getLostHp())
				room:setPlayerFlag(damage.to, "-wangyu_plus")
			elseif damage.to:hasFlag("wangyu_minus") then
				local n = damage.to:getHp()
				room:askForDiscard(damage.to, "jg_wangyu", n, n, false, true)
				room:setPlayerFlag(damage.to, "-wangyu_minus")
			end
		end
	end,
	can_trigger=function()
		return true
	end
}

jg_nueni = sgs.CreateTriggerSkill{
	name = "jg_nueni",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory ,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			room:broadcastSkillInvoke(self:objectName())
			for _,s in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.damage >= 2 and s:isWounded() then
					room:sendCompulsoryTriggerLog(s, "jg_nueni") 
					local theRecover = sgs.RecoverStruct()
					theRecover.recover = 1
					theRecover.who = s
					room:recover(s, theRecover)
				end
			end
		end
	end,
	can_trigger=function()
		return true
	end
}

jg_Nohime:addSkill(jg_wangyu)
jg_Nohime:addSkill(jg_nueni)

sgs.LoadTranslationTable{
    ["jg_Nohime"] = "濃姬",
	["#jg_Nohime"] = "美濃之蝶",
	["jg_wangyu"] = "亡語",
	[":jg_wangyu"] = "當你受到或造成傷害時，若你有手牌，你可以令此傷害+1/-1，若為+1/-1，結算後，其摸等同其已損失體力值的牌/目標角色棄置等同其體力值的牌。",
	["jg_nueni"] = "虐溺",
	[":jg_nueni"] = "鎖定技，當一名角色造成兩點以上傷害時，你回復一點體力",
	["wangyu_plus"] = "該傷害+1",
	["wangyu_minus"] = "該傷害-1",
	["#JgWangyu"] = "%from 發動了技能 “<font color=\"yellow\"><b>亡語</b></font>”，對 %to 的傷害由 %arg 點變為 %arg2 點 ",
}

--寧寧
jg_Ningning = sgs.General(extension, "jg_Ningning", "wei2", "4", false, true)
--慈愛

sgs.LoadTranslationTable{
    ["jg_Ningning"] = "寧寧",
	["#jg_Ningning"] = "北政所",
}
--稻姬
jg_Inahime = sgs.General(extension, "jg_Inahime", "wu2", "4", false, true)

--戟舞


sgs.LoadTranslationTable{
    ["jg_Inahime"] = "稻姬",
	["#jg_Inahime"] = "弓姬",
	["jg_jiwu"] = "弓舞",
	[":jg_jiwu"] = "妳可以將兩張以上的手牌當作「殺」使用，若此牌被響應，妳摸等量的牌",
	--拒西：覺醒技，每當妳受到傷害時，若妳失去的體力超過兩點，妳減一點體力上限並將體力值恢復至體力上限，然後獲得技能「馬術」，並將「弓舞」的敘述加上「妳以此法使用的「殺」傷害+1」
}
--本多忠勝
jg_HondaTadakatsu = sgs.General(extension, "jg_HondaTadakatsu", "wu2", "4", true, true)
--戰決
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
jg_linting = sgs.CreateTriggerSkill{
	name = "jg_linting" ,
	events = {sgs.CardUsed,sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.card:isKindOf("Slash") then 
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isKongcheng() and (not use.to:contains(p)) then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "jg_linting", "@str_bingzhang-choose", true)
					if s then
						local success = player:pindian(s, "jg_linting", nil)
						if success then
							use.to:append(s)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:setPlayerFlag(player,"jg_linting")
						end
					end
				end
			end
		elseif event == sgs.TargetSpecified then
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if player:hasFlag("jg_linting") then
					local _data = sgs.QVariant()
					_data:setValue(p)
					--if player:askForSkillInvoke(self:objectName(), _data) then
						room:broadcastSkillInvoke(self:objectName())
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
	end
}
jg_HondaTadakatsu:addSkill(jg_linting)
jg_HondaTadakatsu:addSkill("mashu")

sgs.LoadTranslationTable{
    ["jg_HondaTadakatsu"] = "本多忠勝",
	["#jg_HondaTadakatsu"] = "德川的戰神",
	["jg_linting"] = "拎蜓",
	[":jg_linting"] = "當你用「殺」指定目標後，你可以與一名不是目標的角色進行拼點，若你贏，該角色同樣成為此「殺」的目標，且此「殺」無法被「閃」響應",
}
--柴田勝家
jg_ShibataKatsuie = sgs.General(extension, "jg_ShibataKatsuie", "wei2", "4", true, true)
--割瓶
jg_geping = sgs.CreateTriggerSkill{
	name = "jg_geping" ,
	events = {sgs.EventPhaseStart,sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local n = player:getHp()
					room:askForDiscard(player, "jg_geping", n, n, false, true)
					player:drawCards(2)
					local choices2 = {"jg_geping1","jg_geping2","jg_geping3","cancel"}
					for i = 1, n ,1 do
						local choice2 = room:askForChoice(player, "jg_geping", table.concat(choices2, "+"))
						if choice2 == "jg_geping1" then
							room:setPlayerMark(player,"jg_geping1-Clear",player:getMark("jg_geping1-Clear") + 1)
							local msg2 = sgs.LogMessage()
							msg2.type = "#MakeChoice"
							msg2.from = player
							--msg2.to:append(damage.from)
							msg2.arg = self:objectName()
							msg2.arg2 = choice2
							room:sendLog(msg2)
						elseif choice2 == "jg_geping2" then
							room:setPlayerMark(player,"jg_geping2-Clear",player:getMark("jg_geping2-Clear") + 1)
							local msg2 = sgs.LogMessage()
							msg2.type = "#MakeChoice"
							msg2.from = player
							--msg2.to:append(damage.from)
							msg2.arg = self:objectName()
							msg2.arg2 = choice2
							room:sendLog(msg2)
						elseif choice2 == "jg_geping3" then
							room:setPlayerMark(player,"jg_geping3-Clear",player:getMark("jg_geping3-Clear") + 1)
							local msg2 = sgs.LogMessage()
							msg2.type = "#MakeChoice"
							msg2.from = player
							--msg2.to:append(damage.from)
							msg2.arg = self:objectName()
							msg2.arg2 = choice2
							room:sendLog(msg2)
						elseif choice2 == "cancel" then
							break
						end
					end
				end
			elseif player:getPhase() == sgs.Player_Finish then
				local x = player:getMark("jg_geping1") + player:getMark("jg_geping2") + player:getMark("jg_geping3")
				if player:getMark("damage_point_round") < x then
					room:sendCompulsoryTriggerLog(player, "jg_geping") 
					room:loseHp(player, x - player:getMark("damage_point_round"))
				end
			end
		end
	end
}
jg_gepingTargetMod = sgs.CreateTargetModSkill{
	name = "#jg_gepingTargetMod",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(jg_geping) and player:getMark("jg_geping2-Clear") > 0 then
			return player:getMark("jg_geping2-Clear")
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(jg_geping) and player:getMark("jg_geping1-Clear") > 0 then
			return player:getMark("jg_geping1-Clear")
		end
	end,
}

jg_gepingmc = sgs.CreateMaxCardsSkill{
	name = "#jg_gepingmc", 
	extra_func = function(self, target)
		if target:hasSkill(jg_geping) and target:getMark("jg_geping3-Clear") > 0 then
			return target:getMark("jg_geping3-Clear")
		end
	end
}
--立逝
jg_yusui = sgs.CreateTriggerSkill{
	name = "jg_yusui",
	events = {sgs.Death} ,
	frequency = sgs.Skill_Compulsory ,
	can_trigger = function(self, target)
		return target ~= nil and target:hasSkill(self:objectName())
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local killer
		if death.damage then
			killer = death.damage.from
		else
			killer = nil
		end
		if killer and killer:objectName() ~= player:objectName() then
			room:notifySkillInvoked(player, self:objectName())
			room:loseHp(killer)
		end
		return false
	end
}

jg_ShibataKatsuie:addSkill(jg_geping)
jg_ShibataKatsuie:addSkill(jg_gepingTargetMod)
jg_ShibataKatsuie:addSkill(jg_gepingmc)
jg_ShibataKatsuie:addSkill(jg_yusui)

sgs.LoadTranslationTable{
    ["jg_ShibataKatsuie"] = "柴田勝家",
	["#jg_ShibataKatsuie"] = "鬼將",

	["jg_geping"] = "割瓶",
	[":jg_geping"] = "出牌階段開始時，你可以棄置X張牌並摸兩張牌，然後你可以進行至多X次選擇：1.你的「殺」可以選擇一個額外目標、2.你本回合的手牌上限+1、3.你本回合的攻擊範圍+1，回合結束時，你造成的傷害數比選擇次數每少一點，你失去一點體力",
	["jg_geping1"] = "使用殺的指定目標+1",
	["jg_geping2"] = "使用殺的距離+1",
	["jg_geping3"] = "手牌上限+1",

	["jg_yusui"] = "玉碎",
	[":jg_yusui"] = "鎖定技，殺死你的角色須失去一點體力",
}
--今川義元
jg_ImagawaYoshimoto = sgs.General(extension, "jg_ImagawaYoshimoto", "qun2", "4", true, true)
--
function RIGHT(self, player)
	if player and player:isAlive() and player:hasSkill(self:objectName()) then return true else return false end
end

jg_dujing = sgs.CreateTriggerSkill{
	name = "jg_dujing" ,
	events = {sgs.GameStart,sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and RIGHT(self, player) then
			room:setPlayerMark(player,"@dujing",1)
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("@dujing") == player:getHp() then
						if room:askForSkillInvoke(p, "jg_dujing", data) then
							room:setTag("ExtraTurn",sgs.QVariant(true))
							p:gainAnExtraTurn()
							room:setTag("ExtraTurn",sgs.QVariant(false))
							room:addPlayerMark(p,"@dujing",1)
						end
					end
				end
			end
		end	
		return false
	end
}
jg_kangluang = sgs.CreateTriggerSkill{
	name = "jg_kangluang",
	events = {sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage then
			local killer = dying.damage.from
			if player:getHp() <= 0 then
				if killer:hasSkill(self:objectName()) and killer:getMark("@dujing") > 0 then
					if room:askForSkillInvoke(killer, "jg_kangluang", data) then
						room:setPlayerMark(killer,"@dujing",1)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

jg_ImagawaYoshimoto:addSkill(jg_dujing)
jg_ImagawaYoshimoto:addSkill(jg_kangluang)

sgs.LoadTranslationTable{
    ["jg_ImagawaYoshimoto"] = "今川義元",
	["#jg_ImagawaYoshimoto"] = "名門的武士",
	["jg_dujing"] = "獨進",
	[":jg_dujing"] = "當一名體力為(1)的角色結束其回合時，你可以進行一個額外的回合，然後()內的數字+1",
	["jg_kangluang"] = "戡亂",
	[":jg_kangluang"] = "當你殺死一名角色時，你可以重置「獨進」，並摸兩張牌",
	["@dujing"] = "獨進",
}

--服部半藏
jg_HattoriHanzo = sgs.General(extension, "jg_HattoriHanzo", "wu2", "2", true, true)

--隱遁


sgs.LoadTranslationTable{
    ["jg_HattoriHanzo"] = "服部半藏",
	["#jg_HattoriHanzo"] = "忍者",
	["jg_yingdon"] = "隱遁",
	[":jg_yingdon"] = "你可將兩張牌當【閃】打出",
	["jg_rensu"] = "忍術",
	[":jg_rensu"] = "摸牌階段你額外摸一張牌；棄牌階段你至多棄X張牌，X為你當前體力值。"
}
--上杉謙信
jg_UesugiKenshin = sgs.General(extension, "jg_UesugiKenshin", "qun2", "4", true, true)
--車旋：一名角色的回合結束時，你可以棄置X張牌，令其執行一個其本回合跳過的階段；若為你，你無視「跳過」

--送鹽
jg_songyanCard = sgs.CreateSkillCard{
	name = "jg_songyanCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), tiger:objectName(), "jg_songyan","")
		room:moveCardTo(self,tiger,sgs.Player_PlaceHand,reason)
		source:drawCards(1)
	end
}
jg_songyan = sgs.CreateViewAsSkill{
	name = "jg_songyan" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = jg_songyanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
	enabled_at_play = function(self, player)
		return (player:usedTimes("#jg_songyanCard") < 1 and not player:isKongcheng())
	end
}

jg_UesugiKenshin:addSkill(jg_songyan)

sgs.LoadTranslationTable{
    ["jg_UesugiKenshin"] = "上杉謙信",
	["#jg_UesugiKenshin"] = "越後之龍",
	["jg_cheshan"] = "車旋",
	[":jg_cheshan"] = "出牌階段限一次，你可與其他角色進行拼點，若你贏，你將對方的拼點牌置於你的武將牌上，並可重複此流程直到你拼點沒贏為止，若你輸，你收回你的拼點牌。此流程結束後，你獲得武將牌上的所有牌",
	["jg_songyan"] = "送鹽",
	[":jg_songyan"] = "每回合限一次，你可以將一張基本牌交給一名其他角色，然後你摸一張牌",
}
--武田信玄
jg_TakedaHarunobu = sgs.General(extension, "jg_TakedaHarunobu", "qun2", "4", true, true)
--四略
 
--上洛
jg_shonlao = sgs.CreateTriggerSkill{
	name = "jg_shonlao",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMaxHp() - player:getHp() > 2 then
			room:addPlayerMark(player, "jg_shonlao")
			if room:changeMaxHpForAwakenSkill(player, 2) then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
				room:doSuperLightbox("jg_TakedaHarunobu","jg_shonlao")
				player:drawCards(2)
				room:acquireSkill(player, "weizhong")
				room:acquireSkill(player, "benghuai")
			end
		end
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("jg_shonlao")
				and target:isAlive()
				and (target:getMark("jg_shonlao") == 0)
	end
}
--嚴行
jg_yenxin = sgs.CreateTriggerSkill{
	name = "jg_yenxin",
	frequency = sgs.Skill_Frequency,
	events = {sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage then
			local killer = dying.damage.from
			if player:getHp() <= 0 then
				if killer:hasSkill(self:objectName()) then
					local maxhp = killer:getMaxHp() + 1
					room:setPlayerProperty(killer, "maxhp", sgs.QVariant(maxhp))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

jg_TakedaHarunobu:addSkill(jg_shonlao)
jg_TakedaHarunobu:addSkill(jg_yenxin)

sgs.LoadTranslationTable{
    ["jg_TakedaHarunobu"] = "武田信玄",
	["#jg_TakedaHarunobu"] = "甲斐之虎",
	["jg_shiloua"] = "四略",
	[":jg_shiloua"] = "回合開始時，你可以選擇下列四種效果其中一種：風--本回合你使用牌沒有距離限制，火--本回合你造成的傷害+1，林--本回合你使用「殺」無法被響應，山--本回合你手牌上限+4，每個選項限一次",
	["jg_shonlao"] = "上洛",
	[":jg_shonlao"] = "覺醒技，準備階段開始時，若你已失去的體力超過兩點，你須將加2點體力上限，然後回復1點體力或重置「四略」，並獲得技能“崩壞”和“威重”。",
	["jg_yenxin"] = "嚴行",
	[":jg_yenxin"] = "鎖定技，每當你殺死一名角色，你的體力上限便+1",
}
--伊達政忠
jg_DateMasamune = sgs.General(extension, "jg_DateMasamune", "qun2", "4", true, true)

--鐵砲：每輪限一次，當你使用牌時，你可以令此牌不能被響應
--肅率：當你殺死一名角色時，你可以獲得其所有手牌與裝備牌；若你的身份為主公，你殺死忠臣無需棄牌

sgs.LoadTranslationTable{
    ["jg_DateMasamune"] = "伊達政宗",
	["#jg_DateMasamune"] = "獨眼龍",
}
--石田三成
jg_IshidaMitsunari = sgs.General(extension, "jg_IshidaMitsunari", "shu2", "4", true, true)
--剛略：出牌階段開始時，你需將一張手牌當作你未使用過的普通錦囊牌使用，否則你失去一點體力；當你殺死一名角色後，你重置此技能


sgs.LoadTranslationTable{
    ["jg_IshidaMitsunari"] = "石田三成",
	["#jg_IshidaMitsunari"] = "剛愎的君子",

}
--島左近
jg_ShimaSakon = sgs.General(extension, "jg_ShimaSakon", "shu2", "4", true, true)

--膽略：當你的「殺」指定目標後，你令其本回合無法使用「桃」且非鎖定技失效

--絕謀：出牌階段開始時，你可以令一名角色視為對你使用「決鬥」，若如此做，你本回合對其造成的傷害+1

sgs.LoadTranslationTable{
    ["jg_ShimaSakon"] = "島左近",
	["#jg_ShimaSakon"] = "關原的戰神",
}

--島津義弘
jg_ShimazuYoshihiro = sgs.General(extension, "jg_ShimazuYoshihiro", "shu2", "4", true, true)
--釣伏
jg_diaofuCard = sgs.CreateSkillCard{
	name = "jg_diaofuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)	
		local tiger = targets[1]
		local cards = tiger:getHandcards()
		room:loseHp(source)
		room:setPlayerFlag(tiger, "diaofutarget")
	end,
}

jg_diaofuVS = sgs.CreateZeroCardViewAsSkill{
	name = "jg_diaofu",
	view_as = function(self,cards)
		return jg_diaofuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#jg_diaofuCard") < 1
	end
}
jg_diaofu = sgs.CreateTriggerSkill{
	name = "jg_diaofu" ,
	events = {sgs.PreCardUsed} ,
	view_as_skill = jg_diaofuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.PreCardUsed then
			if player:getPhase() ~= sgs.Player_Play then return false end
			if (room:alivePlayerCount() > 2) and (use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard")) and not use.to:contains(use.from) then
				room:setPlayerProperty(player, "str_zangshi", sgs.QVariant())
				for _, p in sgs.qlist(room:getPlayers()) do
					if p:hasFlag("diaofutarget") and not use.to:contains(p)  then
						use.to:append(p)
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
			end
		end
		return false
	end
}
jg_diaofuDistance = sgs.CreateDistanceSkill{
	name = "#jg_diaofuDistance",
	correct_func = function(self, from, to)
		if from:hasSkill(jg_diaofu) and to:hasFlag("diaofutarget") then
			return -99
		else
			return 0
		end
	end  
}
jg_ShimazuYoshihiro:addSkill(jg_diaofu)
jg_ShimazuYoshihiro:addSkill(jg_diaofuDistance)

sgs.LoadTranslationTable{
    ["jg_ShimazuYoshihiro"] = "島津義弘",
	["#jg_ShimazuYoshihiro"] = "鬼石曼子",
	["jg_diaofu"] = "釣伏",
	[":jg_diaofu"] = "出牌階段限一次，你可以失去一點體力並觀看一名角色的手牌；若如此做，你與該角色於本回合之間的距離視為1；你於本回合使用的「殺」與錦囊牌均指定其為額外目標",
	["@diaofu1"] = "你可以視為對一名角色使用「決鬥」",
	["~jg_diaofu"] = "選擇一名角色 -> 點擊「確定」",
}
--風魔
jg_FumaKotaro = sgs.General(extension, "jg_FumaKotaro", "qun2", "4", true, true)
--疾風
jg_jifungCard = sgs.CreateSkillCard{
	name = "jg_jifungCard" ,
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("jg_jifung")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end ,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("jg_jifung")
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
jg_jifungVS = sgs.CreateViewAsSkill{
	name = "jg_jifung" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then 
			return false
		else
			return #selected == 0 and to_select:isKindOf("EquipCard") and not sgs.Self:isJilei(to_select)
		end
	end ,
	view_as = function(self, cards)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then
			return #cards == 0 and jg_jifungCard:clone() or nil
		else
			if #cards ~= 1 then
				return nil
			end
			local card = jg_jifungCard:clone()
			for _, cd in ipairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@jg_jifung")
	end
}
jg_jifung = sgs.CreateTriggerSkill{
	name = "jg_jifung" ,
	events = {sgs.TurnedOver} ,
	view_as_skill = jg_jifungVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, "@@jg_jifung1", "@jifung1", 1) then
			return true
		end
		return false
	end
}
--掠阵
jg_luachen = sgs.CreateTriggerSkill{
	name = "jg_luachen" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local target = damage.to
		if damage.card and damage.card:isKindOf("Slash") and (not target:isNude()) and player:faceUp() then
			if room:askForSkillInvoke(player, "jg_luachen", data) then
				local id = room:askForCardChosen(player, target, "he", "jg_luachen")
				room:obtainCard(player, id, false)
				player:turnOver()
			end
		end
	end
}
jg_FumaKotaro:addSkill(jg_jifung)
jg_FumaKotaro:addSkill(jg_luachen)

sgs.LoadTranslationTable{
    ["jg_FumaKotaro"] = "風魔小太郎",
	["#jg_FumaKotaro"] = "暗黑之魂",
	["jg_jifung"] = "疾風",
	[":jg_jifung"] = "當你的武將牌翻面時，可視為你對一名角色打出一張【殺】",
	["jg_luachen"] ="掠陣",
	[":jg_luachen"] ="每當你使用的【殺】對一名角色造成一次傷害後，若你的武將牌正面朝上，你可以獲得其一張牌，並將你的武將牌翻面。",
	["@jifung1"] = "你可以視為對一名角色使用一張「殺」",
	["~jg_jifung"] = "選擇一名角色 -> 點擊「確定」",
}
--甲斐姬
jg_Kaihime = sgs.General(extension, "jg_Kaihime", "qun2", "4", false, true)
jg_KaihimeSub = sgs.General(extension, "jg_KaihimeSub", "god", 4, true, true, true)
--浪切
jg_lanchae = sgs.CreateTriggerSkill{
	name = "jg_lanchae",
	events = {sgs.TargetSpecified,sgs.SlashMissed,sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					if not p:hasFlag("lanchaeused") then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if player:askForSkillInvoke(self:objectName(), _data) then
							room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
							local id = room:askForCardChosen(player, p, "he", "jg_lanchae")
							room:obtainCard(player, id, false)
							room:setPlayerFlag(p, "lanchaeused")
						end
					end
				end
			end
		elseif event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			room:setPlayerFlag(effect.to, "lanchae_jink")
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					if p:hasFlag("lanchaeused") then
						room:setPlayerFlag(p, "-lanchaeused")
						if not p:hasFlag("lanchae_jink") then
							p:drawCards(1)
						else
							room:setPlayerFlag(p, "-lanchae_jink")
						end
					end
				end
			end
		end
	end,
}
--水拒
jg_suijuCard = sgs.CreateSkillCard{
	name = "jg_suijuCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return to_select:getEquips():length()> 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
			local tiger = targets[1]
			local duel = sgs.Sanguosha:cloneCard("drowning", sgs.Card_NoSuit, 0)
			duel:setSkillName("jg_suiju")
			local use = sgs.CardUseStruct()
			use.card = duel
			use.from = source
			local dest = tiger
			use.to:append(dest)
			room:useCard(use)
	end
}
jg_suiju = sgs.CreateZeroCardViewAsSkill{
	name = "jg_suiju",
	view_as = function()
		return jg_suijuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#jg_suijuCard") < 1
	end
}
--圍偃
jg_weiyan = sgs.CreateTriggerSkill{
	name = "jg_weiyan" ,
	frequency = sgs.Skill_Wake ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "jg_weiyan")
		if room:changeMaxHpForAwakenSkill(player) then
			room:doSuperLightbox("jg_Kaihimei","jg_weiyan")
			room:acquireSkill(player, "jg_suiju")
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getMark("jg_weiyan") == 0)
				and target:getEquips():length() >= 3
	end
}

jg_Kaihime:addSkill(jg_lanchae)
jg_Kaihime:addSkill(jg_weiyan)
jg_KaihimeSub:addSkill(jg_suiju)
sgs.LoadTranslationTable{
    ["jg_Kaihime"] = "甲斐姬",
	["#jg_Kaihime"] = "東國之姝",
	["jg_lanchae"] = "浪切",
	["jg_weiyan"] = "圍偃",
	[":jg_lanchae"] = "每當妳使用的【殺】指定目標時，妳可以獲得其一張牌；若此「殺」沒有被目標角色使用的【閃】響應，目標角色摸一張牌。每回合每名角色限一次。",
	[":jg_weiyan"] = "覺醒技，當妳將裝備牌置入裝備區時，若妳裝備區的牌大於三張，妳減1點體力上限，獲得技能「水拒」",
	["jg_suiju"] = "水拒",
	[":jg_suiju"] = "出牌階段限一次，妳可以視為對一名裝備區有牌的其他角色使用「水淹七軍」",
}

--立花誾千代
jg_TachibanaGinchiyo = sgs.General(extension, "jg_TachibanaGinchiyo", "shu2", "4", false, true)

--雷切
jg_leiqie = sgs.CreateTriggerSkill{
	name = "jg_leiqie" ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and player:getMark("acquire_card-Clear") > 0 then
				if move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_USE and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) and s:hasFlag("jg_leiqie")) then
					local n = move.card_ids:length()
					local slash = sgs.Sanguosha:cloneCard("Thunder_Slash", sgs.Card_SuitToBeDecided, 0)
					for i=0, (n-1), 1 do
						local card_id = move.card_ids:at(i)
						local card = sgs.Sanguosha:getCard(card_id)
						slash:addSubcard(card)
					end
					local players = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canSlash(p, slash, true) then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						local target = room:askForPlayerChosen(player, players, "jg_leiqie", nil, true, false)
						if target then
							slash:setSkillName("jg_leiqie")
							local use = sgs.CardUseStruct()
							use.card = slash
							use.from = player
							use.to:append(target)
							room:useCard(use)
						end
					end
				end
			end
		end
	end,
}

--雷魂：妳的殺均視為雷殺；
jg_leihun = sgs.CreateFilterSkill{
	name = "jg_leihun", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Slash") == true) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local duel = sgs.Sanguosha:cloneCard("thunder_slash", originalCard:getSuit(), originalCard:getNumber())
		duel:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(duel)
		return card
	end
}

jg_leihun_trigger = sgs.CreateTriggerSkill{
	name = "#jg_leihun" ,
	events = {sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card:getSkillName() == "jg_leiqie" and damage.card:isKindOf("Slash") and RIGHT(self, player) then
				if damage.to and damage.to:getEquip():length() >= damage.to:getHp() then
					room:throwCard(room:askForCardChosen(player, damage.to, "e", "jg_leiqie", false, sgs.Card_MethodDiscard), damage.to, player)
				end
			end
		end
	end,
}

jg_TachibanaGinchiyo:addSkill(jg_leiqie)
jg_TachibanaGinchiyo:addSkill(jg_leihun)
jg_TachibanaGinchiyo:addSkill(jg_leihun_trigger)

sgs.LoadTranslationTable{
    ["jg_TachibanaGinchiyo"] = "立花誾千代",
	["#jg_TachibanaGinchiyo"] = "雷姬",
	["jg_leiqie"] = "雷切",
	[":jg_leiqie"] = "當妳不因使用而失去牌時，若妳此回合獲得過牌，妳可以將失去的牌當「雷殺」使用。",
	["jg_leihun"] = "雷魂",
	[":jg_leihun"] = "妳的殺均視為雷殺；妳的「雷殺」造成傷害後，若受到傷害的角色其裝備區的牌數不小於體力值，妳可以棄置其裝備區一張牌",
}
--早川殿
jg_LadyHayakawa = sgs.General(extension, "jg_LadyHayakawa", "qun2", "3", false, true)
--輔治
jg_fujiCard = sgs.CreateSkillCard{
	name = "jg_fujiCard" ,
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) 
	end,
	on_use = function(self, room, source, targets)	
		local tiger = targets[1]
		if source:canDiscard(tiger, "hej") then
			local choices = {"fujidiscard", "fujiturnover"}
			local choice = room:askForChoice(source, "jg_jiwu", table.concat(choices, "+"))
			if choice == "fujiturnover" then
				tiger:turnOver()
				source:turnOver()
			end
			if choice == "fujidiscard" then
				local id = room:askForCardChosen(source, tiger, "hej", "jg_fuji") 
				room:obtainCard(source, id, false)
				source:turnOver()
			end
		else
			tiger:turnOver()
			source:turnOver()
		end
	end
}

jg_fujiVS = sgs.CreateZeroCardViewAsSkill{
	name = "jg_fuji",
	view_as = function(self,cards)
		return jg_fujiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#jg_fujiCard") < 1 
	end
}

jg_fuji = sgs.CreateTriggerSkill{
	name = "jg_fuji",  
	frequency = sgs.Skill_Compulsory,
	view_as_skill = jg_fujiVS,
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if (not player:faceUp()) and player:getHp() < damage.from:getHp() then
			damage.damage = damage.damage - 1
			data:setValue(damage)
		end
		return false
	end
}
--堅韌
jg_jenzen = sgs.CreateTriggerSkill{
	name = "jg_jenzen" ,
	events = {sgs.TurnedOver} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local q = room:askForPlayerChosen(player, room:getAlivePlayers(), "jg_jenzen", "@jg_jenzen-draw", true)
		if q then
			local maxhp2 = q:getMaxHp() 
			local card2 = q:getHandcardNum()
			room:drawCards(q, math.max(maxhp2-card2,0))
		end
	end
}
jg_LadyHayakawa:addSkill(jg_fuji)
jg_LadyHayakawa:addSkill(jg_jenzen)
sgs.LoadTranslationTable{
    ["jg_LadyHayakawa"] = "早川殿",
	["#jg_LadyHayakawa"] = "東國的名珠",
	["jg_fuji"] = "輔智",
	[":jg_fuji"] = "準備階段，妳可將妳的武將牌翻面，若如此做，妳可將場上一名武將翻面或獲得任一角色區域內的一張牌。鎖定技，當妳的武將牌背面朝上時，大於妳體力值的角色對妳造成的傷害-1",
	["fujidiscard"] = "獲得其一張牌",
	["fujiturnover"] = "令其翻面",
	["jg_jenzen"] = "堅韌",
	[":jg_jenzen"] = "當你的武将牌翻面时，你可以令一名角色將手牌數補至其體力上限",
	["@jg_jenzen-draw"] = "令一名角色將手牌數補至其體力上限",
}
--淺井長政
jg_AzaiNagamasa = sgs.General(extension, "jg_AzaiNagamasa", "qun2", "4", true, true)
--密命
jg_meming = sgs.CreateTriggerSkill{
	name = "jg_meming",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Play then
				local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "jg_meming", "@jg_meming-choose", true)
				if not s then
					local length = room:getOtherPlayers(player):length()
					local n = math.random(1, length)
					s = room:getOtherPlayers(player):at(n-1)
				end
				local msg = sgs.LogMessage()
				msg.type = "#Meming"
				msg.from = player
				msg.to:append(s)
				room:sendLog(msg)
				if not s:isKongcheng() then
					local ids = room:getNCards(1, false)
					local id = ids:at(0)
					local card2 = sgs.Sanguosha:getCard(id)
					local success = player:pindian(s, "jg_meming", card2)
					if success then
						local slash = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
						slash:setSkillName("jg_meming")
						local use = sgs.CardUseStruct()
						use.card = slash
						use.from = player
						use.to:append(s)
						room:useCard(use)
					else
						if card2:getSuit() ~= sgs.Card_Heart then
							player:drawCards(1)
							local slash = 	sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
							slash:setSkillName("jg_meming")
							local use = sgs.CardUseStruct()
							use.card = slash
							use.from = s
							use.to:append(player)
							room:useCard(use)
						else
							player:drawCards(1)
							s:drawCards(1)
						end	
					end
				else
					room:damage(sgs.DamageStruct("jg_meming", player, s, 1))
				end	
			end
		end
	end
}

jg_AzaiNagamasa:addSkill(jg_meming)
sgs.LoadTranslationTable{
    ["jg_AzaiNagamasa"] = "淺井長政",
	["#jg_AzaiNagamasa"] = "近江之鷹",
	["jg_meming"] = "密命",
	[":jg_meming"] = "鎖定技，出牌階段開始時，你需選擇一名角色：若該角色有手牌，你翻開牌堆頂的一張牌並以該牌與其拼點，若你贏，你視為對其使用一張決鬥；若你沒贏，你摸一張牌，其視為對你使用一張決鬥，若你的拼點牌為紅心，則將「其視為對你使用一張決鬥」改為「其與你各摸一張牌」；若該角色沒有手牌，你對其造成一點傷害",
	["@jg_meming-choose"] = "你選擇一名成為「密命」目標的角色",
	["#Meming"] = "%from 受到將軍的密命，對 %to 發動了突襲！",
}
--前田慶次
jg_MaedaKeiji = sgs.General(extension, "jg_MaedaKeiji", "shu2", "5", true, true)

--傾奇：鎖定技，回合開始時，你需展示所有手牌，並棄置其中的殺，然後摸等量的手牌並視為對等量的角色使用「殺」；回合結束時，若你沒有造成傷害，你失去一點體力

jg_qingqiCard = sgs.CreateSkillCard{
	name = "jg_qingqiCard",
	filter = function(self, targets, to_select, erzhang)
		return #targets < sgs.Self:getMark("jg_qingqi")
	end,
	on_use = function(self, room, source, targets)	
		source:drawCards(source:getMark("jg_qingqi"))
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("jg_qingqi")
		local use = sgs.CardUseStruct()
		use.card = duel
		use.from = source
		local dest
		for i = 1,#targets,1 do
			dest = targets[i]
			use.to:append(dest)
		end
		room:useCard(use)	
	end
}
jg_qingqiVS = sgs.CreateViewAsSkill{
	name = "jg_qingqi",
	response_pattern = "@@jg_qingqi",
	n = 999, 
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end, 
	view_as = function(self, cards)
		if #cards == sgs.Self:getMark("jg_qingqi") then
			local jihocard = jg_qingqiCard:clone()
			for _,card in ipairs(cards) do
				jihocard:addSubcard(card)
			end
			jihocard:setSkillName(self:objectName())
			return jihocard
		end
	end, 
}
jg_qingqi = sgs.CreateTriggerSkill{
	name = "jg_qingqi",
	events = {sgs.EventPhaseStart},
	view_as_skill = jg_qingqiVS,
	on_trigger = function(self, event, luxun, data)
		local room = luxun:getRoom()
		local phase = luxun:getPhase()
		if phase == sgs.Player_Play then
			local cards = luxun:getHandcards()
			local n = 0
			for _, card in sgs.qlist(cards) do
				if card:isKindOf("Slash") then
					n = n + 1
				end
			end
			room:setPlayerMark(luxun, "jg_qingqi", n)
			if n > 0 then
				room:askForUseCard(luxun, "@@jg_qingqi", "@jg_qingqi-card")
				room:setPlayerMark(luxun, "jg_qingqi", 0)
			end
		end
	end
}

jg_MaedaKeiji:addSkill(jg_qingqi)

sgs.LoadTranslationTable{
    ["jg_MaedaKeiji"] = "前田慶次",
	["#jg_MaedaKeiji"] = "傾奇者",
	["jg_qingqi"] = "傾奇",
	[":jg_qingqi"] = "出牌階段開始時，你可以展示手牌，並棄置所有的「殺」，然後摸等量的牌並視為對等量的角色使用一張「決鬥」",
	["@jg_qingqi-card"] = "你可以展示手牌，並棄置所有的「殺」，然後摸等量的牌並視為對等量的角色使用一張「決鬥」",
	["~jg_qingqi"] = "選擇所有「殺」-> 選擇成為目標的角色 -> 點選「確定」",
}


--石川五右衛門
jg_IshikawaGoemon = sgs.General(extension, "jg_IshikawaGoemon", "shu2", "4", true, true)
jg_shentou = sgs.CreateViewAsSkill{
	name = "jg_shentou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (not to_select:isEquipped()) and (to_select:getSuit() == sgs.Card_Club)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local chain = sgs.Sanguosha:cloneCard("snatch", cards[1]:getSuit(), cards[1]:getNumber())
			chain:addSubcard(cards[1])
			chain:setSkillName(self:objectName())
			return chain
		end
	end
}
jg_shentouTargetMod = sgs.CreateTargetModSkill{
	name = "#jg_shentouTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Snatch",
	distance_limit_func = function(self, player)
		if player:hasSkill(jg_shentou) then
			local maxhp = player:getMaxHp()
			local hp = player:getHp()
			return maxhp-hp
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(jg_shentou) and player:getHp()<=2 then
			return 1 
		end
	end,
}

jg_IshikawaGoemon:addSkill(jg_shentou)
jg_IshikawaGoemon:addSkill(jg_shentouTargetMod)
sgs.LoadTranslationTable{
    ["jg_IshikawaGoemon"] = "石川五右衛門",
	["#jg_IshikawaGoemon"] = "大盜",
	["jg_shentou"] = "神偷",
	[":jg_shentou"] = "你可以将一张梅花手牌当【順手牽羊】使用，你使用順手牽羊的距離減少X(X為你已經失去的生命值)，當你的生命值小於等於2時，你的順手牽羊可以額外多選擇一個目標",
}
--加拉夏
jg_gracia = sgs.General(extension,"jg_gracia","qun2","3",false, true)
--道助
jg_daoju = sgs.CreateTriggerSkill{
	name = "jg_daoju",
	events = {sgs.EventPhaseStart,sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play) or event == sgs.Damaged then
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "jg_daoju", "@jg_daoju-choose", true)
			if s then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				local judge = sgs.JudgeStruct()
				judge.pattern =  "."
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				local card = judge.card
				local suit = card:getSuit()
				if suit == sgs.Card_Heart then
	       				local theRecover = sgs.RecoverStruct()
					theRecover.recover = 1
					theRecover.who = s
					room:recover(s, theRecover)
	   			elseif suit == sgs.Card_Diamond then
					room:drawCards(s, 2, "jg_daoju")
				elseif suit == sgs.Card_Spade then
					s:turnOver()
				elseif suit == sgs.Card_Club then
					room:drawCards(s, 2, "jg_daoju")
					room:askForDiscard(s, "jg_daoju", 2, 2, false, true)
				end
			end
			return false
		end
	end
}
jg_zhuanCard = sgs.CreateSkillCard{
	name = "jg_zhuanCard" ,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return true 
	end,
	on_use = function(self, room, source, targets)	
		local n = #targets	
		local ids = room:getNCards(n, false)
		room:fillAG(ids)
		room:getThread():delay()
		for _, p in ipairs(targets) do
			p:setFlags("jg_zhuanTarget")
		end
		local _targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("jg_zhuanTarget") then _targets:append(p) end
		end
		local dest = room:askForPlayerChosen(source, _targets, "jg_zhuan", "@jg_zhuan-choose", true)
		local k = 0
		for i = 1,n,1 do
			if targets[i] == dest then
				k = i
			end
		end
		for i2 = 1,n,1 do
			local p
			if  k + i2 - 1 > n then
				p = targets[k + i2 - 1 - n]
			else
				p = targets[k + i2 - 1]
			end
			local card_id = room:askForAG(p, ids, false, self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			room:obtainCard(p, card, true)
			ids:removeOne(card_id)
			room:takeAG(p, card_id, false)
		end
		room:clearAG()
	end
}
jg_zhuan = sgs.CreateViewAsSkill{
	name = "jg_zhuan",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return true
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = jg_zhuanCard:clone()
			local cardA = cards[1]
			local cardB = cards[2]
			card:addSubcard(cardA)
			card:addSubcard(cardB)
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#jg_zhuanCard") 
	end
}

jg_gracia:addSkill(jg_daoju)
jg_gracia:addSkill(jg_zhuan)
sgs.LoadTranslationTable{
    ["jg_gracia"] = "加拉夏",
	["#jg_gracia"] = "尋道之姝",
	["jg_daoju"] = "道助",
	[":jg_daoju"] = "妳的出牌階段開始時，或妳受傷時，妳可以指定一名角色，然後進行判定：紅心：該角色恢復一點體力、方塊：該角色抽兩張牌、梅花：該角色抽兩張牌，然後棄置兩張牌、黑桃：該角色翻面",
	["jg_zhuan"] = "主恩",
	[":jg_zhuan"] = "出牌階段限一次，妳可以棄置兩張同花色的牌並選定任意名角色，然後妳展示牌堆頂的X張牌並選擇其中的一名角色，由該角色開始所有目標角色依序選擇一張牌並獲得之",
	["@jg_zhuan-choose"] = "由該角色開始所有目標角色依序選擇一張牌",
	["@jg_daoju-choose"] = "指定一名角色，令其執行道助",
}
--女忍者
jg_Kunoichi = sgs.General(extension,"jg_Kunoichi","shu2","4",false, true)
--影護
jg_yinhu = sgs.CreateTriggerSkill{
	name = "jg_yinhu",
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			for _,to in sgs.qlist(use.to) do
				if not player:isAlive() then break end
				if player:getHp() > 0 and player:hasSkill(self:objectName()) then
					local to_data = sgs.QVariant()
					to_data:setValue(to)
					local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
					if will_use then
						if player:getHp() < to:getHp() and not player:isNude() then
							room:askForDiscard(player, "jg_yinhu", 1, 1, false, true)
						else
							room:loseHp(player)
						end
						to:drawCards(2)
					end
				end
			end
		end
		return false
	end
}
jg_zhanxin = sgs.CreateTriggerSkill{
	name = "jg_zhanxin",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zhanxin",	
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:getMark("@zhanxin") > 0 then
				if room:askForSkillInvoke(player, "jg_zhanxin", data) then
					room:doSuperLightbox("jg_Kunoichi","jg_zhanxin")
					local newhp = 0 
					local ids = room:getNCards(4)
					room:fillAG(ids)
					room:getThread():delay()
					local slashs = sgs.IntList()
					local last = sgs.IntList()
					for _,id in sgs.qlist(ids) do
						local c = sgs.Sanguosha:getCard(id)
						local d = c:getSuit()
	   					if not player:hasFlag(c:getSuit()) then
	        					newhp = newhp +1
							room:setPlayerFlag(player, c:getSuit())
						end
						last:append(id)
					end	
					for _,id in sgs.qlist(last) do
						local card = sgs.Sanguosha:getCard(id) 
						room:moveCardTo(card, nil, sgs.Player_DiscardPile, 
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, 
						source:objectName(), "", "jg_zhanxin"), true)
					end
					room:setPlayerProperty(player, "hp", sgs.QVariant(newhp))
					room:removePlayerMark(player, "@zhanxin")
					room:clearAG()
				end
			end
		end
		return false
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
jg_Kunoichi:addSkill(jg_yinhu)
jg_Kunoichi:addSkill(jg_zhanxin)
sgs.LoadTranslationTable{
    ["jg_Kunoichi"] = "女忍者",
	["#jg_Kunoichi"] = "護衛的女俠",
	["jg_yinhu"] = "影護",
	["jg_zhanxin"] = "貞心",
	[":jg_yinhu"] = "每當一名角色受到傷害時，你可以失去一點體力，令其摸兩張牌；若該角色體力值比你的體力值少，你摸一張牌",
	[":jg_zhanxin"] = "限定技，當你進入頻死狀態時，你可以展示牌堆頂的四張牌，然後將體力恢復至X點(X為其中包含的花色數)",
}
--直江兼續
jg_NaoeKanetsugu = sgs.General(extension,"jg_NaoeKanetsugu","shu2","3",true)

sgs.LoadTranslationTable{
	["jg_NaoeKanetsugu"] = "直江兼續",
	["&jg_NaoeKanetsugu"] = "直江兼續",
	["#jg_NaoeKanetsugu"] = "北國名相",
}
--立花宗茂
jg_TachibanaMuneshige = sgs.General(extension,"jg_TachibanaMuneshige","shu2","4",true)
--雷道
jg_yizhen = sgs.CreateTriggerSkill{
	name = "jg_yizhen" ,
	frequency = sgs.Skill_NotFrequent ,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart} ,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local s = room:findPlayerBySkillName("jg_yizhen")
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == s:objectName() and player:objectName() == s:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
				if s:getPhase() == sgs.Player_NotActive then
					room:setPlayerMark(s, "jg_yizhen", s:getMark("jg_yizhen") + move.card_ids:length())
				end
			end
			return false
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if s:getMark("jg_yizhen") > 0 then
					local q = room:askForPlayerChosen(s,room:getOtherPlayers(s), "jg_yizhen", "@jg_yizhen-draw:::" .. tostring(s:getMark("jg_yizhen")), true)
					if q then
						q:drawCards(s:getMark("jg_yizhen"))
					end
				end
				if s:getMark("jg_yizhen") > 1 then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(s)) do
						if s:inMyAttackRange(p) then
							_targets:append(p)
						end
					end
					if not _targets:isEmpty() then
						local r = room:askForPlayerChosen(s,_targets, "jg_yizhen", "@jg_yizhen-slash", true)
						if r then
							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							slash:setSkillName("jg_yizhen")
							local use = sgs.CardUseStruct()
							use.card = slash
							use.from = s
							local dest = r
							use.to:append(dest)
							if s:isAlive() then
								room:useCard(use)
							end
						end						
					end
				end
				room:setPlayerMark(s, "jg_yizhen", 0)
			end
		end
	end
}
jg_TachibanaMuneshige:addSkill(jg_yizhen)

sgs.LoadTranslationTable{
	["jg_TachibanaMuneshige"] = "立花宗茂",
	["#jg_TachibanaMuneshige"] = "西國猛將",
	["jg_yizhen"] = "義震",
	[":jg_yizhen"] = "一名其他角色的回合結束時，若你於該回合內失去過手牌，你可以令一名其他角色摸等量的牌，若多於一張，你可以視為對攻擊範圍內的一名角色使用一張「雷殺」",
	["@jg_yizhen-draw"] = "可以令一名其他角色摸 %arg 張牌",
	["@jg_yizhen-slash"] = "你可以視為對攻擊範圍內的一名角色使用一張「雷殺」",
}

--前田利家
--jg_MaedaToshiie = sgs.General(extension,"jg_MaedaToshiie","wei2","5",true)

--宮本武藏
jg_MiyamotoMusashi = sgs.General(extension,"jg_MiyamotoMusashi","qun2","4",true)
--新版技能：你可以將兩張牌當作殺使用，若你沒有武器，你的攻擊範圍+2，若你有武器，你的「殺」、「決鬥」的目標數+1
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
jg_sungdao = sgs.CreateTriggerSkill{
	name = "jg_sungdao", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart,sgs.JinkEffect,sgs.TargetConfirmed,sgs.DamageCaused,sgs.CardUsed,sgs.SlashMissed,sgs.Damage},
	can_trigger = function(self, target)
		return target ~= nil
	end, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		local bgm_zhangfei = room:findPlayerBySkillName("jg_sungdao")
		if event == sgs.EventPhaseStart and bgm_zhangfei:objectName() == player:objectName() then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				local choices = {"sungdao1", "sungdao2","sungdao3","sungdao4","sungdao5","sungdao6"}
				local choice = room:askForChoice(player, "jg_sungdao", table.concat(choices, "+"))
				room:setPlayerFlag(player, choice)
				local msg2 = sgs.LogMessage()
				msg2.type = "#sungdao"
				msg2.from = player
				--msg2.to:append(damage.from)
				msg2.arg = self:objectName()
				msg2.arg2 = choice
				room:sendLog(msg2)
			end
		elseif event == sgs.JinkEffect then
			local jink = data:toCard()
			if bgm_zhangfei and bgm_zhangfei:isAlive() and bgm_zhangfei:hasFlag("sungdao1") then
				local hc = bgm_zhangfei:getHandcardNum()
				local ec = bgm_zhangfei:getEquips():length()	
				if hc + ec >= 2 then
					if room:askForSkillInvoke(bgm_zhangfei, "jg_sungdao", data) then
						room:askForDiscard(bgm_zhangfei, "jg_sungdao", 2, 2, false, true)
						local log = sgs.LogMessage()
						log.from = bgm_zhangfei
						log.to:append(player)
						log.type = "#DaheEffect"
						log.arg = jink:getSuitString()
						log.arg2 = "LuaDahe"
						room:sendLog(log)
				
						return true
					end
				end
			end
			return false
		elseif event == sgs.TargetConfirmed and bgm_zhangfei:objectName() == player:objectName() then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if player:hasSkill(self:objectName()) and player:hasFlag("sungdao12") then
					if use.card:isRed() then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if player:askForSkillInvoke(self:objectName(), _data) then
							jink_table[index] = 0
						end
					end
					index = index + 1
				end
				if player:hasSkill(self:objectName()) and player:hasFlag("sungdao14") then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if player:askForSkillInvoke(self:objectName(), _data) then
						jink_table[index] = 0
						p:addQinggangTag(use.card)
					end
					index = index + 1
				end
				if player:hasSkill(self:objectName()) and player:hasFlag("sungdao2") then
					if targets:contains(player) then
						if player:isMale() ~= p:isMale() then
							player:drawCards(1)
						end
					end
				end
				if player:hasSkill(self:objectName()) and player:hasFlag("sungdao7") then
					if targets:contains(player) then
						 p:addQinggangTag(use.card)
					end
				end
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		elseif event == sgs.DamageCaused and bgm_zhangfei:objectName() == player:objectName() then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			local reason = damage.card
			if reason and reason:isKindOf("Slash") then
				if damage.to and damage.to:isKongcheng() and damage.from:hasFlag("sungdao3") then
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
				if damage.to and not damage.to:isWounded() and damage.from:hasFlag("sungdao11") then
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
				if damage.to and damage.from:hasFlag("sungdao13") then
					damage.damage = damage.damage + 1
					data:setValue(damage)
					local theRecover = sgs.RecoverStruct()
					theRecover.recover = 1
					theRecover.who = damage.to
					room:recover(damage.from, theRecover)
				end
				if damage.to and (damage.to:getDefensiveHorse() or damage.to:getOffensiveHorse()) and damage.from:hasFlag("sungdao5") then
					if room:askForSkillInvoke(bgm_zhangfei, "jg_sungdao", data) then
						if damage.to:getDefensiveHorse() then
							bgm_zhangfei:obtainCard(damage.to:getDefensiveHorse())
						end
						if damage.to:getOffensiveHorse() then
							bgm_zhangfei:obtainCard(damage.to:getOffensiveHorse())
						end
					end
				end
				if damage.to and damage.from:hasFlag("sungdao8") then
					if room:askForSkillInvoke(bgm_zhangfei, "jg_sungdao", data) then
						for i = 1, 2, 1 do
							if damage.to:isNude() then
								local to_throw = room:askForCardChosen(bgm_zhangfei, damage.to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								room:throwCard(sgs.Sanguosha:getCard(to_throw), damage.to, bgm_zhangfei)
							end
						end
					end
				end
			end
			return false
		elseif event == sgs.CardUsed and bgm_zhangfei:objectName() == player:objectName() then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				if not player:hasFlag("first_slash") then
					player:drawCards(1)
					room:setPlayerFlag(player, "first_slash")
				end
				if player:hasFlag("sungdao4") then
					local suit = use.card:getSuit()
					local number = use.card:getNumber()
					use.card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
					data:setValue(use)
				end
			end
		elseif event == sgs.SlashMissed and bgm_zhangfei:objectName() == player:objectName() then
			local effect = data:toSlashEffect()
			if effect.to:isAlive() and player:hasFlag("sungdao6") then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:askForUseSlashTo(player, effect.to, "@str_pungzhi:"..effect.to:objectName(),true)
				end
			end
			return false
		elseif event == sgs.Damage and bgm_zhangfei:objectName() == player:objectName() then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") and player:hasFlag("sungdao10") then
					local all=sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
						if p:distanceTo(damage.to)== 1 then
							all:append(p)
						end
					end
					if all:isEmpty() then return false end
					local card=room:askForCard(player,".|.|.|.","@skgodfenying",sgs.QVariant(),sgs.NonTrigger)
					if not card then return false end
					local s=room:askForPlayerChosen(player,all,self:objectName(),"sgkgodfenying-invoke",false,true)
					room:throwCard(card,player,nil)
					room:broadcastSkillInvoke(self:objectName())
					local damage2=sgs.DamageStruct()
					damage2.damage=damage.damage
					damage2.nature=sgs.DamageStruct_Normal
					damage2.from=player
					damage2.to=s
					room:damage(damage2)	
				end
			end		
		return false
		end 

	end,
}
jg_sungdaoTargetMod = sgs.CreateTargetModSkill{
	name = "#jg_sungdaoTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(jg_sungdao) and player:getWeapon() then
			return 1000
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill(jg_sungdao) and player:hasFlag("sungdao9") and player:getHandcardNum() == 1 then
			return 1
		elseif player:hasSkill(jg_sungdao) and player:hasFlag("sungdao13") then
			return 1000
		end
	end,
}

jg_MiyamotoMusashi:addSkill(jg_sungdao)
jg_MiyamotoMusashi:addSkill(jg_sungdaoTargetMod)
sgs.LoadTranslationTable{
	["jg_MiyamotoMusashi"] = "宮本武藏",
	["#jg_MiyamotoMusashi"] = "二刀流",
	["jg_sungdao"] = "雙刀",
	[":jg_sungdao"] = "出牌階段，你可以選擇並獲得一個除了諸葛連弩以外的武器能力，若你同時裝備有武器牌，你的攻擊範圍無限，且你使用「殺」的數目+1。當你使用第一張「殺」後，你可以摸一張牌。",
	["sungdao1"] = "貫石斧",
	["sungdao2"] = "雌雄雙股劍",
	["sungdao3"] = "古錠刀",
	["sungdao4"] = "朱雀羽扇",
	["sungdao5"] = "麒麟弓",
	["sungdao6"] = "青龍偃月刀",
	["sungdao7"] = "青缸劍",
	["sungdao8"] = "寒冰劍",
	["sungdao9"] = "方天畫戟",
	["sungdao10"] = "三尖两刃刀",
	["sungdao11"] = "七寶刀",
	["sungdao12"] = "鬼龍斬月刀",
	["sungdao13"] = "修羅煉獄戟",
	["sungdao14"] = "赤血青鋒",
	[":sungdao1"] = "目標角色使用【閃】抵消你使用【殺】的效果時，你可以棄兩張牌，則【殺】依然造成傷害。",
	[":sungdao2"] = "你使用【殺】時，指定了一名異性角色後，在【殺】結算前，你可以從牌堆摸一張牌。",
	[":sungdao3"] = "鎖定技，當你使用的【殺】造成傷害時，若指定目標沒有手牌，則該傷害+1。",
	[":sungdao4"] = "你可以將你的任一普通殺當作具火焰傷害的殺來使用。",
	[":sungdao5"] = "你使用【殺】對目標角色造成傷害時，你可以將其裝備區裡的一匹馬棄置",
	[":sungdao6"] = "當你使用的【殺】被抵消時，你可以立即對相同的目標再使用一張【殺】",
	[":sungdao7"] = "鎖定技，每當你使用【殺】時，無視目標角色的防具。",
	[":sungdao8"] = "當你使用【殺】造成傷害時，你可以防止此傷害，改為棄置該目標角色的兩張牌",
	[":sungdao9"] = "當你使用的【殺】是你的最後一張手牌時，你可以為這張【殺】指定至多三名目標角色，然後按行動順序依次結算之。",
	[":sungdao10"] = "你使用【殺】對目標角色造成傷害後，可棄置一張手牌並對該角色距離1的另一名角色造成1點傷害。",
	[":sungdao11"] = "鎖定技，你使用【殺】無視目標防具，若目標角色未損失體力值，此【殺】傷害+1",
	[":sungdao12"] = "鎖定技，你使用的紅色【殺】不能被【閃】響應。",
	[":sungdao13"] = "你使用【殺】可以額外指定任意名攻擊範圍內的其他角色為目標；鎖定技，你使用【殺】造成的傷害+1，然後令受到傷害的角色回复1點體力。",
	[":sungdao14"] = "鎖定技，你使用【殺】結算結束前，目標角色不能使用或打出手牌，且此【殺】無視其防具。",
	["#sungdao"] = "%from %arg 選擇的武器為： %arg2",
}

--雜賀孫市
jg_SaikaMagoichi = sgs.General(extension,"jg_SaikaMagoichi","qun2","4",true,true)

--縱擒
jg_zongqin = sgs.CreateTriggerSkill{
	name = "jg_zongqin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Finish then
			local most_hp = true
			local less_hp = true
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHp() > player:getHp() then
					 most_hp = false
				end
				if p:getHp() < player:getHp() then
					 less_hp = false
				end
			end
			if most_hp then
				room:sendCompulsoryTriggerLog(player, "jg_zongqin") 
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(player)
			elseif less_hp then
				room:sendCompulsoryTriggerLog(player, "jg_zongqin")
				room:broadcastSkillInvoke(self:objectName())
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = 1
				theRecover.who = player
				room:recover(player, theRecover)
			end
		end
	end
}

--再起
jg_kuiluanCard = sgs.CreateSkillCard{
	name = "jg_kuiluanCard",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		--for _, id in sgs.qlist(self:getSubcards()) do
		--	local c = sgs.Sanguosha:getCard(id)
		--end
		local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
		local card2 = sgs.Sanguosha:getCard(self:getSubcards():at(1))
		local ids = self:getSubcards()
		room:fillAG(ids)
		room:getThread():delay()
		room:clearAG()
		if card:isRed() == card2:isRed() then
			room:broadcastSkillInvoke(self:objectName())
			local analeptic = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
			analeptic:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
			use.card = analeptic
			use.from = source
			room:useCard(use)
		end
	end
}
jg_kuiluanVS = sgs.CreateViewAsSkill{
	name = "jg_kuiluan" ,
	response_pattern = "@@jg_kuiluan",
	n = 2 ,
	view_filter = function(self, selected, to_select)
		if #selected == 0 or #selected == 1 then
			return true
		end
	end, 
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local card = jg_kuiluanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}

jg_kuiluan = sgs.CreateTriggerSkill {
	name = "jg_kuiluan",
	events = {sgs.HpLost, sgs.HpRecover},
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(self, target)
		return target
	end,
	view_as_skill = jg_kuiluanVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.HpLost and player and player:isAlive() and player:hasSkill(self:objectName())) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local ids = room:getNCards(2)
				room:fillAG(ids)
				room:getThread():delay()
				room:clearAG()

				local id = ids:at(0)
				local card = sgs.Sanguosha:getCard(id)
				local id2 = ids:at(1)
				local card2 = sgs.Sanguosha:getCard(id2)
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)

				local same_color = true
				if card:isRed() == card2:isRed() then
					room:broadcastSkillInvoke(self:objectName())
					local analeptic = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
					analeptic:setSkillName(self:objectName())
					local use = sgs.CardUseStruct()
					use.card = analeptic
					use.from = player
					room:useCard(use)
				end
			end
		elseif (event == sgs.HpRecover and player and player:isAlive() and player:hasSkill(self:objectName()) and player:getHandcardNum()+player:getEquips():length() >= 2) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "@@jg_kuiluan!", "@jg_kuiluan", -1, sgs.Card_MethodDiscard)
			end
		end
		return false
	end,
}
jg_SaikaMagoichi:addSkill(jg_zongqin)
jg_SaikaMagoichi:addSkill(jg_kuiluan)

sgs.LoadTranslationTable{
	["jg_SaikaMagoichi"] = "雜賀孫市",
	["#jg_SaikaMagoichi"] = "",
	["jg_zongqin"] = "縱擒",
	[":jg_zongqin"] = "鎖定技，出牌階段結束時，若你為全場體力最高/低的角色，你失去/回復一點體力",
	["jg_kuiluan"] = "再起",
	[":jg_kuiluan"] = "每當你失去/回復一點體力後，你可以摸/棄兩張牌並展示之，若顏色相同，你視為使用一張「南蠻入侵」",
	["@jg_kuiluan"] = "你可以棄兩張牌並展示之，若顏色相同，你視為使用一張「南蠻入侵」",
}


--蘭丸
jg_MoriRanmaru= sgs.General(extension,"jg_MoriRanmaru","wei2","3",true,true)
--寢情
jg_chingchinCard = sgs.CreateSkillCard{
	name = "jg_chingchinCard",
	filter = function(self, targets, to_select, erzhang)
		local lordplayer
		if sgs.Self:getRole() ~= "lord" then
			for _, p in sgs.qlist(sgs.Self:getSiblings()) do
				if p:getRole() == "lord" then
					lordplayer = p	
				end
			end
		else
			lordplayer = sgs.Self
		end
		return to_select:inMyAttackRange(lordplayer) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("jg_chingchinTarget")
	end
}
jg_chingchinVS = sgs.CreateZeroCardViewAsSkill{
	name = "jg_chingchin",
	response_pattern = "@@jg_chingchin",
	view_as = function()
		return jg_chingchinCard:clone()
	end
}

jg_chingchin = sgs.CreateTriggerSkill{
	name = "jg_chingchin",
	events = {sgs.EventPhaseStart},
	view_as_skill = jg_chingchinVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:askForUseCard(player, "@@jg_chingchin", "@jg_chingchin")
				local lordplayer
				if player:getRole() ~= "lord" then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getRole() == "lord" then
							lordplayer = p	
						end
					end
				else
					lordplayer = player
				end
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasFlag("jg_chingchinTarget") then
					local id = room:askForCardChosen(player, p, "he", "jg_chingchin") 
					room:throwCard(id, p, player)
					room:drawCards(p, 1, "jg_chingchin")
					if p:getHandcardNum() > lordplayer:getHandcardNum() then
						room:drawCards(player, 1)
					end
					end
				end
			end
		end
	end
}
--感服
jg_gangfu = sgs.CreateTriggerSkill{
	name = "jg_gangfu",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		if (damage.from:getMark("@gangfu") == 0) and (not player:isNude()) then
			if player:askForSkillInvoke(self:objectName(), sgs.QVariant():setValue(damage)) then
				damage.from:gainMark("@gangfu")
				local id = room:askForCard(player, ".!", "@str-pudu-give:"..damage.from:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				room:obtainCard(damage.from, id, true)
				room:notifySkillInvoked(player, "jg_gangfu")
				room:broadcastSkillInvoke("jg_gangfu")
				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				room:sendLog(msg)
				return true
			end
			return false
		end
		return false
	end
}

jg_MoriRanmaru:addSkill(jg_chingchin)
jg_MoriRanmaru:addSkill(jg_gangfu)
sgs.LoadTranslationTable{
	["jg_MoriRanmaru"] = "森蘭丸",
	["#jg_MoriRanmaru"] = "侍童",
	["jg_chingchin"] = "寢情",
	["jg_gangfu"] = "感服",
	[":jg_chingchin"] = "結束階段開始時，你可以棄置攻擊範圍內含有主公的任意名其他角色的一張牌，令其摸一張牌，然後若其手牌比主公多，你摸一張牌",
	["@jg_chingchin"] = "你可以棄置攻擊範圍內含有主公的一名其他角色的一張牌，並令其摸一張牌，然後若其手牌比主公多，你摸一張牌",
	["~jg_chingchin"] = "選擇目標角色 -> 點擊「確定」",
	[":jg_gangfu"] = "每名角色限一次，當你即將受到傷害時，你可以交給其一張牌，然後防止此傷害",
}
