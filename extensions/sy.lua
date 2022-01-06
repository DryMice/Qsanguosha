module("extensions.sy", package.seeall)
extension = sgs.Package("sy")

sgs.LoadTranslationTable{
	["sy"] = "三英",
}


berserk_propertyset = sgs.CreateTriggerSkill{
	name = "#berserk_propertyset",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawInitialCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local general1 = player:getGeneral()
		if not player:getGeneral2() then
			data:setValue(data:toInt()+4)
		else
			local general2 = player:getGeneral2()
			if general1:hasSkill(self:objectName()) or general2:hasSkill(self:objectName()) then
				if general1:getMaxHp() == 7 or general2:getMaxHp() == 7 then
					room:setPlayerProperty(player, "hp", sgs.QVariant(7))
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(7))
				else
					room:setPlayerProperty(player, "hp", sgs.QVariant(8))
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(8))
				end
				data:setValue(data:toInt()+4)
			end
		end
	end
}


berserk_change = sgs.CreateTriggerSkill{
	name = "#berserk_change",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() <= 4 then
				local general1 = player:getGeneral()
				local general2 = player:getGeneral2()
				if general1:hasSkill(self:objectName()) then
					room:addPlayerMark(player,"@sy_wake")

					for _, skill in sgs.qlist(player:getSkillList(false, false)) do
						if string.find(skill:objectName(), "_skillClear") then
							room:detachSkillFromPlayer(player, skill:objectName(), true)
							room:filterCards(player, player:getCards("h"), true)
						end
					end

					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					dummy:addSubcards(player:getJudgingArea())
					room:throwCard(dummy, player)
					if not player:faceUp() then player:turnOver() end
					if player:isChained() then room:setPlayerProperty(player, "chain", sgs.QVariant(false)) end
					local first = player:getGeneralName()
					local second = player:getGeneral2Name()
					if first == "sy_lvbu1" then
						room:broadcastSkillInvoke(self:objectName(), 1)
					elseif first == "sy_dongzhuo1" then
						room:broadcastSkillInvoke(self:objectName(), 2)
					elseif first == "sy_zhangjiao1" then
			 			room:broadcastSkillInvoke(self:objectName(), 3)
					elseif first == "sy_zhangrang1" then
						room:broadcastSkillInvoke(self:objectName(), 4)
					elseif first == "sy_weiyan1" then
						room:broadcastSkillInvoke(self:objectName(), 5)
					elseif first == "sy_sunhao1" then
						room:broadcastSkillInvoke(self:objectName(), 6)
					elseif first == "sy_caifuren1" then
						room:broadcastSkillInvoke(self:objectName(), 7)
					elseif first == "sy_simayi1" then
						room:broadcastSkillInvoke(self:objectName(), 8)
					elseif first == "berserk_miku1" then
						room:broadcastSkillInvoke(self:objectName(), 9)
					elseif first == "sy_yasuo1" then
						room:broadcastSkillInvoke(self:objectName(), 10)
					elseif first == "sy_simashi1" then
						room:broadcastSkillInvoke(self:objectName(), 11)
					end
					room:doLightbox("$sanyinglimit", 3000)
					local msg = sgs.LogMessage()
					msg.from = player
					msg.type = "#berserk_second"
					room:sendLog(msg)
					if first == "sy_lvbu1" then
						room:changeHero(player, "sy_lvbu2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_lvbu1" then
						room:changeHero(player, "sy_lvbu2", true, true, true, false)
					end
					if first == "sy_dongzhuo1" then
						room:changeHero(player, "sy_dongzhuo2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_dongzhuo1" then
						room:changeHero(player, "sy_dongzhuo2", true, true, true, false)
					end
					if first == "sy_zhangjiao1" then
						room:changeHero(player, "sy_zhangjiao2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_zhangjiao1" then
						room:changeHero(player, "sy_zhangjiao2", true, true, true, false)
					end
					if first == "sy_zhangrang1" then
						room:changeHero(player, "sy_zhangrang2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_zhangrang1" then
						room:changeHero(player, "sy_zhangrang2", true, true, true, false)
					end
					if first == "sy_weiyan1" then
						room:changeHero(player, "sy_weiyan2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_weiyan1" then
						room:changeHero(player, "sy_weiyan2", true, true, true, false)
					end
					if first == "sy_caifuren1" then
						room:changeHero(player, "sy_caifuren2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_caifuren1" then
						room:changeHero(player, "sy_caifuren2", true, true, true, false)
					end
					if first == "sy_sunhao1" then
						room:changeHero(player, "sy_sunhao2", true, true, false, false)
						if player:getMark("sy_mingzheng") > 0 then 
							if not player:hasSkill("sy_shisha") then room:acquireSkill(player, "sy_shisha") end
							if player:hasSkill("sy_mingzheng") then room:detachSkillFromPlayer(player, "sy_mingzheng") end
						end
					end
					if player:getGeneral2() and second == "sy_sunhao1" then
						room:changeHero(player, "sy_sunhao2", true, true, true, false)
						if player:getMark("sy_mingzheng") > 0 then 
							if not player:hasSkill("sy_shisha") then room:acquireSkill(player, "sy_shisha") end
							if player:hasSkill("sy_mingzheng") then room:detachSkillFromPlayer(player, "sy_mingzheng") end
						end
					end
					if first == "sy_simayi1" then
						room:changeHero(player, "sy_simayi2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_simayi1" then
						room:changeHero(player, "sy_simayi2", true, true, true, false)
					end
					if first == "berserk_miku1" then
						room:changeHero(player, "berserk_miku2", true, true, false, false)
					end
					if player:getGeneral2() and second == "berserk_miku1" then
						room:changeHero(player, "berserk_miku2", true, true, true, false)
					end
					if first == "sy_simashi1" then
						room:changeHero(player, "sy_simashi2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_simashi1" then
						room:changeHero(player, "sy_simashi2", true, true, true, false)
					end
					if first == "berserk_simayi1" then
						room:changeHero(player, "berserk_simayi2", true, true, false, false)
					end
					if player:getGeneral2() and second == "berserk_simayi1" then
						room:changeHero(player, "berserk_simayi2", true, true, true, false)
					end
					if first == "berserk_miku1" then
						room:changeHero(player, "berserk_miku2", true, true, false, false)
					end
					if player:getGeneral2() and second == "berserk_miku1" then
						room:changeHero(player, "berserk_miku2", true, true, true, false)
					end
					if first == "sy_yasuo1" then
						room:changeHero(player, "sy_yasuo2", true, true, false, false)
					end
					if player:getGeneral2() and second == "sy_yasuo1" then
						room:changeHero(player, "sy_yasuo2", true, true, true, false)
					end
					room:setPlayerProperty(player, "hp", sgs.QVariant(4))
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(4))
					room:setPlayerMark(player, "@waked", 1)
					if player:getMark("gameMode_sanying") > 0 then
						room:setPlayerMark(player, "@jumpend", 1)
						room:setPlayerMark(player, "@sy_wake", 1)
						room:throwEvent(sgs.TurnBroken)
					end
				end
			end
		end
		return false
	end
}



local berserkskills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#berserk_propertyset") then berserkskills:append(berserk_propertyset) end
if not sgs.Sanguosha:getSkill("#berserk_change") then berserkskills:append(berserk_change) end
sgs.Sanguosha:addSkills(berserkskills)


sgs.LoadTranslationTable{
	["@sy_wake"] = "暴怒",
}


--神吕布
sy_lvbu1 = sgs.General(extension, "sy_lvbu1", "god", 8, true)
sy_lvbu2 = sgs.General(extension, "sy_lvbu2", "god", 4, true)


--无双
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

sy_wushuang = sgs.CreateTriggerSkill{
	name = "sy_wushuang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				if player:getGeneralName() == "sy_lvbu1" or player:getGeneral2Name() == "sy_lvbu1" then
					room:broadcastSkillInvoke(self:objectName(), 1)
				end
				if player:getGeneralName() == "sy_lvbu2" or player:getGeneral2Name() == "sy_lvbu2" then
					room:broadcastSkillInvoke(self:objectName(), 2)
				end
				if player:getGeneralName() ~= "sy_lvbu1" and player:getGeneral2Name() ~= "sy_lvbu1" and player:getGeneralName() ~= "sy_lvbu2" and player:getGeneral2Name() ~= "sy_lvbu2" then
					room:broadcastSkillInvoke(self:objectName(), 1)
				end
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			local can_invoke = false
			if effect.card:isKindOf("Duel") then				
				if effect.from and effect.from:isAlive() and (effect.from:hasSkill(self:objectName()) or effect.from:hasSkill("wushuang")) then
					can_invoke = true
				end
				if effect.to and effect.to:isAlive() and (effect.to:hasSkill(self:objectName()) or effect.to:hasSkill("wushuang")) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			if effect.card:isKindOf("Duel") then
				if room:isCanceled(effect) then
					effect.to:setFlags("Global_NonSkillNullify")
					return true;
				end
				if effect.to:isAlive() then
					local second = effect.from
					local first = effect.to
					room:setEmotion(first, "duel");
					room:setEmotion(second, "duel")
					while true do
						if not first:isAlive() then
							break
						end
						local slash
						if player:getGeneral2():hasSkill(self:objectName()) then
							room:sendCompulsoryTriggerLog(second, self:objectName())
							room:notifySkillInvoked(second, self:objectName())
							if player:getGeneral2():getGeneralName() == "sy_lvbu1" or second:getGeneral2Name() == "sy_lvbu1" then
							   room:broadcastSkillInvoke(self:objectName(), 1)
							end
						if player:getGeneral2():getGeneralName() == "sy_lvbu2" or second:getGeneral2Name() == "sy_lvbu2" then
							room:broadcastSkillInvoke(self:objectName(), 2)
						end
						if player:getGeneral2():getGeneralName() ~= "sy_lvbu1" and second:getGeneral2Name() ~= "sy_lvbu1" and second:getGeneralName() ~= "sy_lvbu2" and second:getGeneral2Name() ~= "sy_lvbu2" then
							room:broadcastSkillInvoke(self:objectName(), 1)
						end
							slash = room:askForCard(first,"slash","@wushuang-slash-1:" .. second:objectName(),data,sgs.Card_MethodResponse)
							if slash == nil then
								break
							end
							slash = room:askForCard(first, "slash", "@wushuang-slash-2:" .. second:objectName(),data,sgs.Card_MethodResponse)
							if slash == nil then
								break
							end
						else
							slash = room:askForCard(first,"slash","duel-slash:" .. second:objectName(),data,sgs.Card_MethodResponse)
							if slash == nil then
								break
							end
						end
						local temp = first
						first = second
						second = temp
					end
					local damage = sgs.DamageStruct(effect.card, second, first)
					room:damage(damage)
				end
				room:setTag("SkipGameRule",sgs.QVariant(true))
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return target
	end
}


--神威
sy_shenwei = sgs.CreateTriggerSkill{
	name = "sy_shenwei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill(self:objectName()) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			data:setValue(data:toInt()+2)
		end
	end
}

sy_shenweikeep = sgs.CreateMaxCardsSkill{
	name = "#sy_shenwei",
	extra_func = function(self, target)
		if target:hasSkill("sy_shenwei") then
			return 2
		else
			return 0
		end
	end
}


extension:insertRelatedSkills("sy_shenwei", "#sy_shenwei")


--修罗
hasDelayedTrickXiuluo = function(target)
	for _, card in sgs.qlist(target:getJudgingArea()) do
		if not card:isKindOf("SkillCard") then return true end
	end
	return false
end

containsTable = function(t, tar)
	for _, i in ipairs(t) do
		if i == tar then return true end
	end
	return false
end

sy_xiuluo = sgs.CreateTriggerSkill{
	name = "sy_xiuluo" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		while hasDelayedTrickXiuluo(player) and player:canDiscard(player, "h") do
			local suits = {}
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if not containsTable(suits, jcard:getSuitString()) then
					table.insert(suits, jcard:getSuitString())
				end
			end
			local card = room:askForCard(player, ".|" .. table.concat(suits, ",") .. "|.|hand", "@xiuluo", sgs.QVariant(), self:objectName())
			if (not card) or (not hasDelayedTrickXiuluo(player)) then break end
			local avail_list = sgs.IntList()
			local other_list = sgs.IntList()
			for _, jcard in sgs.qlist(player:getJudgingArea()) do
				if jcard:isKindOf("SkillCard") then
				elseif jcard:getSuit() == card:getSuit() then
					avail_list:append(jcard:getEffectiveId())
				else
					other_list:append(jcard:getEffectiveId())
				end
			end
			local all_list = sgs.IntList()
			for _, l in sgs.qlist(avail_list) do
				all_list:append(l)
			end
			for _, l in sgs.qlist(other_list) do
				all_list:append(l)
			end
			room:fillAG(all_list, nil, other_list)
			local id = room:askForAG(player, avail_list, false, self:objectName())
			room:clearAG()
			room:throwCard(id, nil)
			room:broadcastSkillInvoke(self:objectName())
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and target:canDiscard(target, "h")
				and hasDelayedTrickXiuluo(target)
	end
}


--神戟
sy_shenji = sgs.CreateTargetModSkill{
	name = "sy_shenji",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) and from:getWeapon() == nil and card:subcardsLength() > 0 then
			return 2
		else
			return 0
		end
	end
}


--神吕布武器重铸（老子要神戟，老子要一杀三）
W_recast = sgs.CreateTriggerSkill{
	name = "#W_recast",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if not player:hasSkill(self:objectName()) then return false end
		local card = use.card
		if use.card:isKindOf("Weapon") and use.to:at(0):objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				local move = sgs.CardsMoveStruct()
				move.card_ids:append(card:getEffectiveId())
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), "", "")
				move.to_place = sgs.Player_DiscardPile
				room:moveCardsAtomic(move, true)
				player:broadcastSkillInvoke("@recast")
				local log = sgs.LogMessage()
				log.type = "#SkillEffect_Recast"
				log.from = player
				log.arg = self:objectName()
				log.card_str = card:toString()
				room:sendLog(log)
				player:drawCards(1, "recast")
				return true
			end
		end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#W_recast") then skills:append(W_recast) end
sgs.Sanguosha:addSkills(skills)


sy_lvbu1:addSkill("#berserk_propertyset")
sy_lvbu1:addSkill("#berserk_change")
sy_lvbu1:addSkill("#W_recast")
sy_lvbu1:addSkill("mashu")
sy_lvbu1:addSkill(sy_wushuang)
sy_lvbu2:addSkill("#W_recast")
sy_lvbu2:addSkill("mashu")
sy_lvbu2:addSkill(sy_wushuang)
sy_lvbu2:addSkill(sy_xiuluo)
sy_lvbu2:addSkill(sy_shenwei)
sy_lvbu2:addSkill(sy_shenweikeep)
sy_lvbu2:addSkill("shenji")


sgs.LoadTranslationTable{
["sy_lvbu2"] = "神呂布",
["#sy_lvbu2"] = "暴怒戰神",
["sy_lvbu1"] = "神呂布",
["#sy_lvbu1"] = "最強神話",
["~sy_lvbu2"] = "我在地獄等著你們！",
["sy_shenwei"] = "神威",
["#sy_shenwei"] = "神威",
["$sy_shenwei"] = "唔唔唔唔唔唔——！！！",
[":sy_shenwei"] = "<font color=\"blue\"><b>鎖定技。</b></font>摸牌階段，你額外摸兩張牌；你的手牌上限+2 。",
["sy_wushuang"] = "無雙",
["$sy_wushuang1"] = "你的人頭，我要定了！",
["$sy_wushuang2"] = "這就讓你去死！",
[":sy_wushuang"] = "<font color=\"blue\"><b>鎖定技。</b></font>當你使用【殺】時，目標需連續使用兩張【閃】才能抵消；與你進行【決鬥】的角色每次需連續打出兩張【殺】。",
["sy_shenji"] = "神戟",
["$sy_shenji"] = "戰神之力，開！",
[":sy_shenji"] = "<font color=\"blue\"><b>鎖定技。</b></font>你沒裝備武器時，你使用的【殺】可指定至多3名角色為目標。",
["sy_xiuluo"] = "修羅",
["$sy_xiuluo"] = "不可饒恕，不可饒恕！",
[":sy_xiuluo"] = "回合開始階段，你可以棄一張手牌來棄置你判定區裡的一張延時類錦囊（必須花色相同）。",
["#W_recast"] = "武器重鑄",
["#SkillEffect_Recast"] = "%from 由於“%arg”的效果，重鑄了 %card",
}


--神董卓
sy_dongzhuo1 = sgs.General(extension, "sy_dongzhuo1", "god", 8, true)
sy_dongzhuo2 = sgs.General(extension, "sy_dongzhuo2", "god", 4, true)


--纵欲
sy_zongyuvs = sgs.CreateZeroCardViewAsSkill{
	name = "sy_zongyu",
	view_as = function(self, cards)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		return analeptic
	end,
	enabled_at_play = function(self, player)
		return sgs.Analeptic_IsAvailable(player) and player:getHp() >= 2
	end
}

sy_zongyu = sgs.CreateTriggerSkill{
	name = "sy_zongyu",
	events = {sgs.PreCardUsed},
	view_as_skill = sy_zongyuvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card:getSkillName() == "sy_zongyu" then
				room:loseHp(player)
			end
		end
		return false
	end
}


--凌虐
sy_lingnue = sgs.CreateTriggerSkill{
	name = "sy_lingnue",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer) and player:getPhase() == sgs.Player_Play then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			room:notifySkillInvoked(player, "sy_lingnue")
			room:broadcastSkillInvoke("sy_lingnue")
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.pattern = ".|black"
			judge.reason = self:objectName()
			judge.good = true
			room:judge(judge)
			if judge:isGood() then
				local card = judge.card
				player:obtainCard(card)
				local use = data:toCardUse()
				if use.m_addHistory then
					room:addPlayerHistory(player, damage.card:getClassName(),-1)
				end
			end
		end
	end
}


--暴政
sy_baozheng = sgs.CreateTriggerSkill{
	name = "sy_baozheng",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if player:getHandcardNum() > s:getHandcardNum() and player:getPhase() == sgs.Player_Draw and player:objectName() ~= s:objectName() then
			local card = room:askForCard(player, ".|diamond", "@baozheng:" .. s:objectName(), data, sgs.Card_MethodNone)
			if card then
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:broadcastSkillInvoke("sy_baozheng")
				room:notifySkillInvoked(s, "sy_baozheng")
				s:obtainCard(card)
			else
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:broadcastSkillInvoke("sy_baozheng")
				room:notifySkillInvoked(s, "sy_baozheng")
				room:damage(sgs.DamageStruct(self:objectName(), s, player))
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}


--逆施
sy_nishi = sgs.CreateTriggerSkill{
	name = "sy_nishi",
	events = {sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasSkill(self:objectName()) then
			room:notifySkillInvoked(player, "sy_nishi")
			local room = player:getRoom()
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local count = data:toInt() + (math.min(4, player:getHp()) - 2)
			data:setValue(count)
			room:broadcastSkillInvoke("sy_nishi")
		end
	end
}


--横行
sy_hengxing = sgs.CreateTriggerSkill{
	name = "sy_hengxing",
	events = {sgs.SlashEffected, sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getEquips():length() + player:getHandcardNum() >= player:getHp() then
				player:setMark("sy_hengxing", 0)
				if not room:askForSkillInvoke(player, self:objectName()) then return false end
				room:notifySkillInvoked(player, "sy_hengxing")
				room:askForDiscard(player, self:objectName(), math.max(1, player:getHp()), math.max(1, player:getHp()), false, true)
				room:broadcastSkillInvoke(self:objectName())
				player:addMark("sy_hengxing")
			end
		else
			local effect = data:toSlashEffect()
			if player:getMark("sy_hengxing") > 0 then
				player:removeMark("sy_hengxing")
				return true
			end
		end
	end
}


sy_dongzhuo1:addSkill("#berserk_propertyset")
sy_dongzhuo1:addSkill("#berserk_change")
sy_dongzhuo1:addSkill(sy_zongyu)
sy_dongzhuo1:addSkill(sy_lingnue)
sy_dongzhuo1:addSkill(sy_baozheng)
sy_dongzhuo2:addSkill(sy_zongyu)
sy_dongzhuo2:addSkill(sy_lingnue)
sy_dongzhuo2:addSkill(sy_baozheng)
sy_dongzhuo2:addSkill(sy_nishi)
sy_dongzhuo2:addSkill(sy_hengxing)


sgs.LoadTranslationTable{
["sy_dongzhuo2"] = "神董卓",
["#sy_dongzhuo2"] = "獄魔王",
["sy_dongzhuo1"] = "神董卓",
["#sy_dongzhuo1"] = "獄魔王",
["~sy_dongzhuo2"] = "那酒池肉林……都是我的……",
["sy_zongyu"] = "縱慾",
["$sy_zongyu"] = "呃……好酒！再來一壺！",
[":sy_zongyu"] = "<font color=\"green\"><b>階段技。</b></font>你可以失去一點體力，視為你使用一張【酒】。",
["sy_lingnue"] = "凌虐",
["$sy_lingnue"] = "來人！活捉了他！斬首祭旗！",
[":sy_lingnue"] = "出牌階段，每當你使用【殺】造成傷害後，你可以進行一次判定，若判定結果為黑色，你獲得該判定牌且該【殺】不計入每回合使用限制。",
["sy_baozheng"] = "暴政",
["$sy_baozheng"] = "順我者昌，逆我者亡！",
[":sy_baozheng"] = "<font color=\"blue\"><b>鎖定技。</b></font>其他角色摸牌階段結束時，若該角色手牌數大於你，則須選擇一項：給你一張方塊牌或受到你造成的1點傷害。",
["@baozheng"] = "【暴政】效果觸發，請交給 %src 一張方塊牌，否則受到一點傷害。",
["sy_nishi"] = "逆施",
["$sy_nishi"] = "看我不活剮了你們！",
[":sy_nishi"] = "<font color=\"blue\"><b>鎖定技。</b></font>摸牌階段，你摸X張牌（X為你的當前體力值且至多為4）。",
["sy_hengxing"] = "橫行",
["$sy_hengxing"] = "都被我踏平吧！哈哈哈哈哈哈哈哈！",
[":sy_hengxing"] = "當其他角色使用【殺】指定你為目標時，你可以棄置X張牌（X為你當前體力值），則該【殺】對你無效。",
}


--神张角
sy_zhangjiao1 = sgs.General(extension, "sy_zhangjiao1", "god", 7, true)
sy_zhangjiao2 = sgs.General(extension, "sy_zhangjiao2", "god", 4, true)


--布教
sy_bujiao = sgs.CreateTriggerSkill{
	name = "sy_bujiao",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if player:getHandcardNum() > 0 and player:getPhase() == sgs.Player_Play and player:objectName() ~= s:objectName() then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(s, "sy_bujiao")
			room:sendCompulsoryTriggerLog(s, self:objectName())
			local card = room:askForCard(player, ".!", "@bujiao:" .. s:objectName(), data, sgs.Card_MethodNone)
			if not card then
				local pile = player:getHandcards()
				local length = pile:length()
				local n = math.random(1, length)
				local id = pile:at(n - 1)
				room:obtainCard(s, id, false)
				player:drawCards(1)
			else
				room:obtainCard(s, card, false)
				player:drawCards(1)
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}


--太平
sy_taiping = sgs.CreateTriggerSkill{
	name = "sy_taiping",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, "sy_taiping")
			for i = 1, damage.damage, 1 do
				local dest = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				dest:gainMark("@ping")
			end
		end
	end
}

--太平：扣手牌上限
sy_taipingMaxCards = sgs.CreateMaxCardsSkill{
	name = "#sy_taipingMaxCards",
	extra_func = function(self, target)
		if target:getMark("@ping") > 0 then
			return -target:getMark("@ping")
		else
			return 0
		end
	end
}

--太平：清除标记
sy_taipingClear = sgs.CreateTriggerSkill{
	name = "#sy_taipingClear",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			player:loseAllMarks("@ping")
		end
	end,
	can_trigger = function()
		return true
	end
}


--妖惑
sy_yaohuoCard = sgs.CreateSkillCard{
	name = "sy_yaohuoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:getHandcardNum() > 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:getHandcardNum() + sgs.Self:getEquips():length() >= to_select:getHandcardNum()
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local n = effect.to:getHandcardNum()
		room:askForDiscard(effect.from, "sy_yaohuo", n, n, false, true)
		local choices = {"yaohuo_card"}
		local count = 0
		local skill_list = effect.to:getVisibleSkillList()
		local sks = {}
		for _,sk in sgs.qlist(skill_list) do
			if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() then
				if sk:getFrequency() ~= sgs.Skill_Limited then
					if sk:getFrequency() ~= sgs.Skill_Wake then
						table.insert(sks, sk:objectName())
						count = 1
					end
				end
			end
		end
		if count > 0 then
			table.insert(choices, "yaohuo_skill")
		end
		local choice = room:askForChoice(effect.from, "sy_yaohuo", table.concat(choices, "+"))
		if choice == "yaohuo_card" then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, cd in sgs.qlist(effect.to:getHandcards()) do
				dummy:addSubcard(cd)
			end
			room:obtainCard(effect.from, dummy, false)
		elseif choice == "yaohuo_skill" then
			room:handleAcquireDetachSkills(effect.from, table.concat(sks, "|"))
			room:handleAcquireDetachSkills(effect.to, "-"..table.concat(sks, "|-"))
			effect.to:setTag("sy_yaohuoSkills", sgs.QVariant(table.concat(sks, "+")))
			room:setPlayerFlag(effect.to, "yaodao")
			local skills = effect.from:getTag("Skills"):toString():split("+")
			table.insert(skills, table.concat(sks, "+"))
			effect.from:setTag("Skills", sgs.QVariant(table.concat(skills, "+")))
		end
	end
}

sy_yaohuoVs = sgs.CreateViewAsSkill{
	name = "sy_yaohuo",
	view_as = function(self, cards)
		local card = sy_yaohuoCard:clone()
		for _,c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sy_yaohuoCard")
	end
}

sy_yaohuo = sgs.CreateTriggerSkill{
	name = "sy_yaohuo",
	view_as_skill = sy_yaohuoVs,
	events = {sgs.EventPhaseEnd, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local skill_list = player:getVisibleSkillList()
		if player:getPhase() == sgs.Player_Finish then
			local skills = player:getTag("Skills"):toString():split("+")
			room:handleAcquireDetachSkills(player, "-"..table.concat(skills, "|-"))
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("yaodao") then
					local yaodao_skills = p:getTag("sy_yaohuoSkills"):toString():split("+")
					room:handleAcquireDetachSkills(p, table.concat(yaodao_skills, "|"))
				end
			end
		end
	end
}


--三治
sy_sanzhiCard = sgs.CreateSkillCard{
	name = "sy_sanzhiCard",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= sgs.Self:objectName() and #targets < self:subcardsLength()
	end,
	feasible = function(self, targets)
		return #targets == self:subcardsLength()
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			room:damage(sgs.DamageStruct("sy_sanzhi", source, p))
		end
	end,
}

sy_sanzhi = sgs.CreateViewAsSkill{
	name = "sy_sanzhi",
	n = 3,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		if #selected > 0 then
			for _,card in ipairs(selected) do
				if card:getTypeId() == to_select:getTypeId() then return false end
			end
		end
		return true
	end,
	view_as = function(self, cards)
		local card = sy_sanzhiCard:clone()
		for _,c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play=function(self, player)
		return not player:hasUsed("#sy_sanzhiCard")
	end
}


extension:insertRelatedSkills("sy_taiping","#sy_taipingMaxCards")
extension:insertRelatedSkills("sy_taiping","#sy_taipingClear")


sy_zhangjiao1:addSkill("#berserk_propertyset")
sy_zhangjiao1:addSkill("#berserk_change")
sy_zhangjiao1:addSkill(sy_bujiao)
sy_zhangjiao1:addSkill(sy_taiping)
sy_zhangjiao1:addSkill(sy_taipingMaxCards)
sy_zhangjiao1:addSkill(sy_taipingClear)
sy_zhangjiao2:addSkill(sy_bujiao)
sy_zhangjiao2:addSkill(sy_taiping)
sy_zhangjiao2:addSkill(sy_taipingMaxCards)
sy_zhangjiao2:addSkill(sy_taipingClear)
sy_zhangjiao2:addSkill(sy_yaohuo)
sy_zhangjiao2:addSkill(sy_sanzhi)


sgs.LoadTranslationTable{	
["sy_zhangjiao2"] = "神張角",
["#sy_zhangjiao2"] = "大賢良師",
["sy_zhangjiao1"] = "神張角",
["#sy_zhangjiao1"] = "大賢良師",
["~sy_zhangjiao2"] = "逆道者，必遭天譴而亡！",
["sy_bujiao"] = "布教",
["$sy_bujiao"] = "眾星熠熠，不若一日之明。",
[":sy_bujiao"] = "<font color = \"blue\"><b>鎖定技。</b></font>其他角色出牌階段開始時，其須交給你一張手牌，然後摸一張牌。",
["@bujiao"] = "【布教】效果觸發，請交給%src一張手牌。",
["sy_taiping"] = "太平",
["$sy_taiping"] = "行大舜之道，救蒼生萬民。",
[":sy_taiping"] = "每當你受到1點傷害後，你可以令一名其他角色獲得一枚“平”標記。其他角色每有一枚“平”標記，手牌上限-1。一名角色的回合結束之後，你棄置其全部的“平”標記。",
["@ping"] = "平",
["sy_yaohuo"] = "妖惑",
["sy_yaohuoCard"] = "妖惑",
["$sy_yaohuo"] = "存惡害義，善必誅之！",
[":sy_yaohuo"] = "<font color=\"green\"><b>階段技。</b></font>你可以指定一名有手牌的其他角色並棄置等同於其手牌數的牌，然後選擇一項：獲得其所有手牌；或獲得其當前的所有技能直到回合結束（限定技、覺醒技除外）。",
["yaohuo_card"] = "獲得所有手牌",
["yaohuo_skill"] = "獲得所有技能",
["sy_sanzhi"] = "三治",
["sy_sanzhiCard"] = "三治",
["$sy_sanzhi"] = "三氣集，萬物治！",
[":sy_sanzhi"] = "<font color=\"green\"><b>階段技。</b></font>你可以棄置任意種不同類別的手牌各一張，然後對等量的其他角色各造成1點傷害。",
}


--神张让
sy_zhangrang1 = sgs.General(extension, "sy_zhangrang1", "god", 7, true)
sy_zhangrang2 = sgs.General(extension, "sy_zhangrang2", "god", 4, true)


--谗陷
sy_chanxianCard = sgs.CreateSkillCard{
	name = "sy_chanxianCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, "sy_chanxian", target:objectName(), "sy_chanxian", "")
		room:obtainCard(target, self, reason, true)
		local star_card, x
		for _, icard in sgs.qlist(self:getSubcards()) do
			star_card = sgs.Sanguosha:getCard(icard)
			x = star_card:getNumber()
		end
		room:setPlayerMark(target, "AI_chanxian", x)
		local prompt = string.format("@sy_chanxian:%s:%s", source:objectName(), star_card:getNumberString())
		local c
		if x == 1 then
			c = room:askForCard(target, ".|.|2~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 2 then
			c = room:askForCard(target, ".|.|3~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 3 then
			c = room:askForCard(target, ".|.|4~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 4 then
			c = room:askForCard(target, ".|.|5~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 5 then
			c = room:askForCard(target, ".|.|6~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 6 then
			c = room:askForCard(target, ".|.|7~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 7 then
			c = room:askForCard(target, ".|.|8~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 8 then
			c = room:askForCard(target, ".|.|9~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 9 then
			c = room:askForCard(target, ".|.|10~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 10 then
			c = room:askForCard(target, ".|.|11~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 11 then
			c = room:askForCard(target, ".|.|12~13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 12 then
			c = room:askForCard(target, ".|.|13|hand", prompt, sgs.QVariant(), sgs.Card_MethodNone)
		elseif x == 13 then
			local t = room:askForPlayerChosen(target, room:getOtherPlayers(source), "sy_chanxian", "chanxian-choose")
			if t then
				room:damage(sgs.DamageStruct("sy_chanxian", target, t))
			end
			return false
		end
		if not c then
			local t = room:askForPlayerChosen(target, room:getOtherPlayers(source), "sy_chanxian", "chanxian-choose")
			if t then
				room:damage(sgs.DamageStruct("sy_chanxian", target, t))
			end
		else
			source:obtainCard(c)
			if not target:isNude() then
				room:askForDiscard(target, "sy_chanxian", 1, 1, false, true)
			end
		end
	end
}

sy_chanxian = sgs.CreateViewAsSkill{
	name = "sy_chanxian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = sy_chanxianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and (not player:hasUsed("#sy_chanxianCard"))
	end
}


--残掠
sy_canlue = sgs.CreateTriggerSkill{
	name = "sy_canlue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.to and (move.to:objectName() == player:objectName()) and move.from and move.from:isAlive()
				and (move.from:objectName() ~= move.to:objectName())
				and (move.to_place == sgs.Player_PlaceHand)
				and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE) then
			local _movefrom
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if move.from:objectName() == p:objectName() then
					_movefrom = p
					break
				end
			end
			room:setPlayerFlag(_movefrom, "canlueDamageTarget")
			local invoke = room:askForSkillInvoke(player, self:objectName(), data)
			room:setPlayerFlag(_movefrom, "-canlueDamageTarget")
			if invoke then
				room:broadcastSkillInvoke(self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, _movefrom, move.card_ids:length()))
			end
		end
		local movex = data:toMoveOneTime()
		if movex.from and movex.from:objectName() == player:objectName() and (movex.from_places:contains(sgs.Player_PlaceHand) or movex.from_places:contains(sgs.Player_PlaceEquip)) then
			if movex.to and movex.to:objectName() ~= player:objectName() and movex.to_place == sgs.Player_PlaceHand then
				local _to
				for _, _player in sgs.qlist(room:getAlivePlayers()) do
					if move.to:objectName() == _player:objectName() then
						_to = _player
						break
					end
				end
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:askForDiscard(_to, self:objectName(), movex.card_ids:length(), movex.card_ids:length(), false, true)
			end
		end
	end
}


--乱政
sy_luanzheng = sgs.CreateTriggerSkill{
	name = "sy_luanzheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, zhangrang, data)
		local room = zhangrang:getRoom()
		if room:getAlivePlayers():length() <= 2 then return false end
		local use = data:toCardUse()
		if event == sgs.TargetConfirming and use.to:contains(zhangrang) then
			if use.from:objectName() == zhangrang:objectName() then return false end
			local targets = room:getOtherPlayers(zhangrang)
			targets:removeOne(use.from)
			if (use.card:isKindOf("Duel") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch") or use.card:isKindOf("Slash")) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				room:notifySkillInvoked(zhangrang, "sy_luanzheng")
				room:sendCompulsoryTriggerLog(zhangrang, self:objectName())
				if use.card:isKindOf("Duel") then
					for _, p in sgs.qlist(targets) do
						if sgs.Sanguosha:isProhibited(use.from, p, use.card) then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
						if p:hasSkill("kongcheng") and p:isKongcheng() then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
					end
				elseif use.card:isKindOf("Slash") then
					for _, p in sgs.qlist(targets) do
						if sgs.Sanguosha:isProhibited(use.from, p, use.card) then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
						if p:hasSkill("kongcheng") and p:isKongcheng() then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
					end
				elseif use.card:isKindOf("Snatch") then
					for _, p in sgs.qlist(targets) do
						if sgs.Sanguosha:isProhibited(use.from, p, use.card) then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
						if p:isAllNude() then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
					end
				elseif use.card:isKindOf("Dismantlement") then
					for _, p in sgs.qlist(targets) do
						if sgs.Sanguosha:isProhibited(use.from, p, use.card) then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
						if p:isAllNude() then
							targets:removeOne(p)
							if targets:isEmpty() then break end
						end
					end
				end
				if targets:isEmpty() then
					room:setPlayerFlag(zhangrang, "sy_luanzheng_failed")
					return false
				end
				local choices = {"sy_luanzhengextratarget", "sy_luanzhengfail"}
				local choice = room:askForChoice(use.from, "sy_luanzheng", table.concat(choices, "+"))
				if choice == "sy_luanzhengextratarget" then
					local T = room:askForPlayerChosen(use.from, targets, "sy_luanzheng")
					if T then
						use.to:append(T)
						room:sortByActionOrder(use.to)
						data:setValue(use)
						room:getThread():trigger(sgs.TargetConfirming, room, T, data)
						return false
					else
						room:setPlayerFlag(zhangrang, "sy_luanzheng_failed")
					end
				else
					room:setPlayerFlag(zhangrang, "sy_luanzheng_failed")
				end
			end
		end
		return false
	end
}

--乱政（使卡牌无效）
sy_luanzhengFail = sgs.CreateTriggerSkill{
	name = "#sy_luanzheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, zhangrang, data)
		local room = zhangrang:getRoom()
		local effect = data:toCardEffect()
		if (effect.card:isKindOf("Snatch") or effect.card:isKindOf("Dismantlement") or effect.card:isKindOf("Duel") or effect.card:isKindOf("Slash")) then
			if effect.to:hasSkill(self:objectName()) and effect.from and effect.to:hasFlag("sy_luanzheng_failed") then
				room:setPlayerFlag(effect.to, "-sy_luanzheng_failed")
				local msg = sgs.LogMessage()
				msg.from = effect.to
				msg.to:append(effect.from)
				msg.arg = effect.card:objectName()
				msg.type = "#sy_luanzheng"
				room:sendLog(msg)
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


extension:insertRelatedSkills("sy_luanzheng", "#sy_luanzheng")


sy_zhangrang1:addSkill("#berserk_propertyset")
sy_zhangrang1:addSkill("#berserk_change")
sy_zhangrang1:addSkill(sy_chanxian)
sy_zhangrang2:addSkill(sy_chanxian)
sy_zhangrang2:addSkill(sy_luanzheng)
sy_zhangrang2:addSkill(sy_luanzhengFail)
sy_zhangrang2:addSkill(sy_canlue)


sgs.LoadTranslationTable{	
["sy_zhangrang2"] = "神張讓",
["~sy_zhangrang2"] = "小的怕是活不成了……陛下……保重……",
["#sy_zhangrang2"] = "禍亂之源",
["sy_zhangrang1"] = "神張讓",
["#sy_zhangrang1"] = "禍亂之源",
["sy_chanxian"] = "讒陷",
["sy_chanxianCard"] = "讒陷",
["@sy_chanxian"] = "請交給%src一張點數大於%dest的手牌。",
["sy_chanxianeCard"] = "讒陷",
["$sy_chanxian1"] = "懂不懂宮裡的規矩？",
["$sy_chanxian2"] = "活得不耐煩了吧？",
["chanxian-choose"] = "【饞陷】效果，請選擇一名角色，由你對其造成1點傷害。",
[":sy_chanxian"] = "<font color = \"green\"><b>階段技。</b></font>你可以展示一張手牌並將之交給一名角色，該角色選擇一項：交給你一張點數大於此牌的手牌，然後棄置一張牌；"..
"或對除你以外的一名角色造成1點傷害。",
["sy_canlue"] = "殘掠",
["$sy_canlue"] = "沒錢？沒錢，就拿命來抵吧！",
[":sy_canlue"] = "每當你從其他角色處獲得1張牌時，你可對其造成1點傷害。每當其他角色從你處獲得1張牌時，須棄置1張牌。" ,
["sy_luanzheng"] = "亂政",
["#sy_luanzheng"] = "亂政",
["$sy_luanzheng1"] = "陛下，都、都是他們幹的！",
["$sy_luanzheng2"] = "大、大、大事不好！有人造反了！",
[":sy_luanzheng"] = "<font color = \"blue\"><b>鎖定技。</b></font>若場上存活角色數不小於3，則其他角色使用的【殺】 、【順手牽羊】、【過河拆橋】、【決鬥】指定你為目標時，須額外指定一名角色（不得為此牌的使用者）"..
"為目標，否則此牌對你無效。",
["sy_luanzhengextratarget"] = "你為這張牌額外指定一名目標，該牌仍然有效",
["sy_luanzhengfail"] = "你不為這張牌額外指定目標，該牌無效",
["#sy_luanzheng"] = "%from 的【<font color = \"yellow\"><b>亂政</b></font>】觸發，%to 對%from 使用的%arg 無效。" ,
}


--神魏延
sy_weiyan1 = sgs.General(extension, "sy_weiyan1", "god", 8, true)
sy_weiyan2 = sgs.General(extension, "sy_weiyan2", "god", 4, true)


--恃傲
sy_shiaoCard = sgs.CreateSkillCard{
	name = "sy_shiao",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			slash:deleteLater()
			if slash:targetFilter(targets_list, to_select, sgs.Self) and sgs.Self:hasFlag("sy_shiao1") and to_select:getHandcardNum() < sgs.Self:getHandcardNum() then
				return true
			end
			if slash:targetFilter(targets_list, to_select, sgs.Self) and sgs.Self:hasFlag("sy_shiao2") and to_select:getHandcardNum() > sgs.Self:getHandcardNum() then
				return true
			end
			return false
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			--room:broadcastSkillInvoke(self:objectName(), 2)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		else
			--room:broadcastSkillInvoke(self:objectName(), 1)
		end
	end
}

sy_shiaoVS = sgs.CreateZeroCardViewAsSkill{
	name = "sy_shiao",
	view_as = function()
		return sy_shiaoCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@sy_shiao")
	end
}
sy_shiao = sgs.CreateTriggerSkill{
	name = "sy_shiao",
	view_as_skill = sy_shiaoVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerFlag(player,"sy_shiao1")
				room:askForUseCard(player, "@@sy_shiao", "@sy_shiao1", -1, sgs.Card_MethodNone)
				room:setPlayerFlag(player,"-sy_shiao1")
			elseif player:getPhase() == sgs.Player_Finish then
				room:setPlayerFlag(player,"sy_shiao2")
				room:askForUseCard(player, "@@sy_shiao", "@sy_shiao2", -1, sgs.Card_MethodNone)
				room:setPlayerFlag(player,"-sy_shiao2")
			end
		end
		return false
	end
}

sy_shiaoTargetMod = sgs.CreateTargetModSkill{
	name = "#sy_shiaoTargetMod",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "sy_shiao" then
			return 1000
		end
	end,
}


--反骨
sy_fangu = sgs.CreateTriggerSkill{
	name = "sy_fangu",
	events = {sgs.DamageComplete, sgs.TurnStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.to:objectName() == s:objectName() then
				room:notifySkillInvoked(player, "sy_fangu")
				room:sendCompulsoryTriggerLog(s, self:objectName())
				room:setPlayerMark(s, "sy_fangu", 1)
				room:broadcastSkillInvoke("sy_fangu")
				room:throwEvent(sgs.TurnBroken)
			end
		elseif event == sgs.TurnStart then
			if s:getMark("sy_fangu") > 0 then
				room:setPlayerMark(s, "sy_fangu", 0)
				room:setTag("ExtraTurn",sgs.QVariant(true))
				s:gainAnExtraTurn()
				room:setTag("ExtraTurn",sgs.QVariant(false))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


--狂襲
sy_kuangxi = sgs.CreateTriggerSkill{
	name = "sy_kuangxi",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:isNDTrick() and (use.to:length() > 1 or not use.to:contains(player) and use.to:length() == 1) then
			if player:askForSkillInvoke(self:objectName()) then
				local slash = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("kuangxi_slash")
				slash:deleteLater()
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				room:notifySkillInvoked(player, "sy_kuangxi")
				local msg = sgs.LogMessage()
				msg.from = player
				for _, _to in sgs.qlist(use.to) do
					msg.to:append(_to)
				end
				msg.arg = use.card:objectName()
				msg.type = "#kuangxi_slash_do"
				room:sendLog(msg)
				for _,p in sgs.qlist(use.to) do
					if player:canSlash(p, nil, false) then
						local card_use = sgs.CardUseStruct()
						card_use.from = player
						card_use.to:append(p)
						card_use.card = slash
						room:useCard(card_use, false)
					end
				end
				return true
			end
		end
	end
}


sy_weiyan1:addSkill("#berserk_propertyset")
sy_weiyan1:addSkill("#berserk_change")
sy_weiyan1:addSkill(sy_shiao)
sy_weiyan1:addSkill(sy_shiaoTargetMod)
sy_weiyan2:addSkill(sy_shiao)
sy_weiyan2:addSkill(sy_shiaoTargetMod)
sy_weiyan2:addSkill(sy_fangu)
sy_weiyan2:addSkill(sy_kuangxi)


sgs.LoadTranslationTable{	
["sy_weiyan2"] = "神魏延",
["#sy_weiyan2"] = "嗜血狂狼",
["sy_weiyan1"] = "神魏延",
["#sy_weiyan1"] = "嗜血狂狼",
["~sy_weiyan2"] = "這……就是老子追求的東西嗎？",
["sy_shiao"] = "恃傲",
["shiao-slash"] = "恃傲",
["$sy_shiao1"] = "靠手裡的傢伙來說話吧。",
["$sy_shiao2"] = "少廢話！真有本事就來打！",
[":sy_shiao"] = "回合開始階段開始時，你可以視為對手牌數小於你的一名其他角色使用一張【殺】；回合結束階段開始時，你可以視為對手牌數大於你的一名其他角色使用一張【殺】。",
["@sy_shiao1"] = "你可以視為對一名手牌數小於你的一名其他角色使用一張殺。",
["@sy_shiao2"] = "你可以視為對一名手牌數大於你的一名其他角色使用一張殺。",
["~sy_shiao"] = "選擇角色→點擊確定",

["sy_fangu"] = "反骨",
["fangu"] = "反骨",
["$sy_fangu"] = "一群膽小之輩，成天壞我大事！",
[":sy_fangu"] = "<font color=\"blue\"><b>鎖定技。</b></font>每當你受到一次傷害後，當前回合結束，你進行一個額外的回合。",
["sy_kuangxi"] = "狂襲",
["kuangxi-slash"] = "狂襲",
["#kuangxi_slash_do"] = "由於【<font color = \"yellow\"><b>狂襲</b></font>】效果，%from 對 %to 使用的 %arg 結算終止，視為 %from 對 %to 使用"..
"【<font color = \"yellow\"><b>殺</b></font>】。",
["$sy_kuangxi1"] = "敢挑戰老子，你就後悔去吧！",
["$sy_kuangxi2"] = "憑你們是阻止不了老子的！",
[":sy_kuangxi"] = "出牌階段，當你使用非延時類錦囊牌指定其他角色為目標後，你可以終止此牌的結算，改為視為對這些目標依次使用一張【殺】（不計入出牌階段的使用限制）。",
}


--神孙皓
sy_sunhao1 = sgs.General(extension, "sy_sunhao1", "god", 8, true)
sy_sunhao2 = sgs.General(extension, "sy_sunhao2", "god", 4, true)


--明政
sy_mingzheng = sgs.CreateTriggerSkill{
	name = "sy_mingzheng",
	events = {sgs.DrawNCards, sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local flag = 1
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("sy_mingzheng") > 0 then
				flag = 0
			end
		end
		if not room:findPlayerBySkillName("sy_mingzheng") then return false end
		local sunhao = room:findPlayerBySkillName("sy_mingzheng")
		if event == sgs.DrawNCards then
			if flag == 0 then return false end
			room:broadcastSkillInvoke("sy_mingzheng")
			room:sendCompulsoryTriggerLog(sunhao, self:objectName())
			room:notifySkillInvoked(sunhao, self:objectName())
			data:setValue(data:toInt() + 1)
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:objectName() ~= sunhao:objectName() then return false end
			room:addPlayerMark(sunhao, "sy_mingzheng", 999)
			room:sendCompulsoryTriggerLog(sunhao, self:objectName())
			room:notifySkillInvoked(sunhao, "sy_mingzheng")
			room:broadcastSkillInvoke("sy_mingzheng")
			if not sunhao:hasSkill("sy_mingzheng") then return false end
			if not sunhao:hasSkill("sy_shisha") then room:acquireSkill(sunhao, "sy_shisha") end
			if sunhao:hasSkill("sy_mingzheng") then room:detachSkillFromPlayer(sunhao, "sy_mingzheng") end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}


--嗜杀
sy_shisha = sgs.CreateTriggerSkill{
	name = "sy_shisha",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.TargetConfirming, sgs.SlashProceed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:objectName() ~= use.from:objectName() or (not use.card:isKindOf("Slash")) then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, "sy_shisha")
			room:broadcastSkillInvoke(self:objectName())
			player:setTag("shisha", sgs.QVariant(true))
			for _, t in sgs.qlist(use.to) do
				if t:objectName() ~= player:objectName() then
					local shishaprompt = string.format("shishadiscard:%s", player:objectName())
					if t:getEquips():length() + t:getHandcardNum() <= 1 then
						room:setPlayerFlag(t, "shisha_done")
					else
						if room:askForDiscard(t, self:objectName(), 2, 2, true, true, shishaprompt) then
							room:setPlayerFlag(t, "shisha_failed")
						else
							room:setPlayerFlag(t, "shisha_done")
						end
					end
				end
			end
		elseif event == sgs.TargetConfirming then
			local usex = data:toCardUse()
			if player:objectName() ~= usex.from:objectName() or (not usex.card:isKindOf("Slash")) then return false end
			local shisha = player:getTag("shisha"):toBool()
			if not shisha then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, "sy_shisha")
				room:broadcastSkillInvoke(self:objectName())
				for _, t in sgs.qlist(usex.to) do
					if t:objectName() ~= player:objectName() then
						local shishaprompt = string.format("shishadiscard:%s", player:objectName())
						if t:getEquips():length() + t:getHandcardNum() <= 1 then
							room:setPlayerFlag(t, "shisha_done")
						else
							if room:askForDiscard(t, self:objectName(), 2, 2, true, true, shishaprompt) then
								room:setPlayerFlag(t, "shisha_failed")
							else
								room:setPlayerFlag(t, "shisha_done")
							end
						end
					end
				end
			else
				room:removeTag("shisha")
			end
		elseif event == sgs.SlashProceed then
			local effect = data:toSlashEffect()
			if effect.from:hasSkill(self:objectName()) then
				if effect.to:hasFlag("shisha_failed") then
					room:setPlayerFlag(effect.to, "-shisha_failed")
					return true
				elseif effect.to:hasFlag("shisha_done") then
					room:setPlayerFlag(effect.to, "-shisha_done")
					room:slashResult(effect, nil)
					return true
				end
			end
		end
		return false
	end,
	priority = 10
}


--荒淫
sy_huangyin = sgs.CreateTriggerSkill{
	name = "sy_huangyin",
	frequency = sgs.NotFrequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if not player:hasSkill(self:objectName()) then return false end
		if event == sgs.BeforeCardsMove then
			if not move.from_places:contains(sgs.Player_DrawPile) or move.from then return false end
			if move.to_place == sgs.Player_PlaceHand and move.to:objectName() == player:objectName() 
					and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW 
					or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) and (not room:getTag("FirstRound"):toBool()) then
				local X = move.card_ids:length()
				if X <= 0 then return false end
				if not player:askForSkillInvoke(self:objectName(), data) then return false end
				room:setPlayerMark(player, "huangyin-AI", X) --AI
				local count = data:toInt()
				count = 0
				room:returnToTopDrawPile(move.card_ids)
				data:setValue(count)
				for i = 1, X do
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getMark("@huangyin") < p:getHandcardNum() + p:getEquips():length() then targets:append(p) end
					end
					local t = room:askForPlayerChosen(player, targets, self:objectName(), "huangyin-invoke", true)
					if not t then break end
					t:gainMark("@huangyin")
				end
				room:setPlayerMark(player, "huangyin-AI", 0)
				for _, to in sgs.qlist(room:getOtherPlayers(player)) do
					if to:getMark("@huangyin") > 0 then
						room:setPlayerFlag(to, "sy_huangyin_InTempMoving")
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
						local card_ids = sgs.IntList()
						local original_places = sgs.IntList()
						local y = to:getMark("@huangyin")
						for i = 0, y - 1, 1 do
							if not player:canDiscard(to, "he") then break end
							local c = room:askForCardChosen(player, to, "he", self:objectName())
							card_ids:append(c)
							original_places:append(room:getCardPlace(card_ids:at(i)))
							dummy:addSubcard(card_ids:at(i))
							to:addToPile("#huangyin", card_ids:at(i), false)
						end
						for i = 0, dummy:subcardsLength() - 1, 1 do
							room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i)), to, original_places:at(i), false)
						end
						room:setPlayerFlag(to, "-sy_huangyin_InTempMoving")
						to:loseAllMarks("@huangyin")
						if dummy:subcardsLength() > 0 then
							room:obtainCard(player, dummy, false)
						end
					end
				end
				room:broadcastSkillInvoke(self:objectName())
				card_ids = sgs.IntList()
				original_places = sgs.IntList()
			end
		end
	end	
}

sy_huangyinFakeMove = sgs.CreateTriggerSkill{
	name = "#sy_huangyin",
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	priority = 10,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("sy_huangyin_InTempMoving") then return true end
		end
		return false
	end,
	can_trigger = function()
		return true
	end
}


extension:insertRelatedSkills("sy_huangyin", "#sy_huangyin")


--醉酒
sy_zuijiuCard = sgs.CreateSkillCard{
	name = "sy_zuijiuCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local red_count = 0
		local black_count = 0
		for _, c in sgs.qlist(source:getHandcards()) do
			if c:isRed() then
				red_count = red_count + 1
			elseif c:isBlack() then
				black_count = black_count + 1
			end
		end
		room:showAllCards(source)
		if black_count >= red_count then
			local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			ana:setSkillName("zuijiu_ana")
			room:useCard(sgs.CardUseStruct(ana, source, source), true)
		end
	end
}

sy_zuijiu = sgs.CreateZeroCardViewAsSkill{
	name = "sy_zuijiu",
	view_filter = function()
		return true
	end,
	view_as = function(self, cards)
		return sy_zuijiuCard:clone()
	end,
	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
		return (player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)) and (not player:hasUsed("#sy_zuijiuCard")) and (not player:isKongcheng())
	end
}


--归命
sy_guiming = sgs.CreateTriggerSkill{
	name = "sy_guiming",
	frequency = sgs.Skill_Limited,
	limit_mark = "@guiming",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local god_sunhao = room:findPlayerBySkillName(self:objectName())
		if not god_sunhao or god_sunhao:isDead() or not god_sunhao:hasSkill(self:objectName()) then return false end
		if god_sunhao:getMark("@guiming") == 0 then return false end
		if dying.who:objectName() ~= god_sunhao:objectName() then return false end
		if god_sunhao:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			local _min = 9999
			local players = room:getOtherPlayers(god_sunhao)
			for _, p in sgs.qlist(players) do
				_min = math.min(p:getHp(), _min)
			end
			local foes = sgs.SPlayerList()
			for _, _player in sgs.qlist(players) do
				if _player:getHp() == _min then
					foes:append(_player)
				end
			end
			if foes:isEmpty() then return false end
			local foe
			if foes:length() == 1 then
				foe = foes:first()
			else
				foe = room:askForPlayerChosen(god_sunhao, foes, self:objectName())
			end
			if foe:isWounded() then
				local guiming_to = sgs.RecoverStruct()
				guiming_to.recover = foe:getLostHp()
				guiming_to.who = god_sunhao
				room:recover(foe, guiming_to)
			end
			local guiming_self = sgs.RecoverStruct()
			guiming_self.recover = 4 - god_sunhao:getHp()
			guiming_self.who = god_sunhao
			room:recover(god_sunhao, guiming_self)
			god_sunhao:loseMark("@guiming")
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill("sy_guiming")
	end
}


sy_sunhao1:addSkill("#berserk_propertyset")
sy_sunhao1:addSkill("#berserk_change")
sy_sunhao1:addSkill(sy_mingzheng)
sy_sunhao2:addSkill(sy_mingzheng)
sy_sunhao2:addSkill(sy_huangyin)
sy_sunhao2:addSkill(sy_huangyinFakeMove)
sy_sunhao2:addSkill(sy_zuijiu)
sy_sunhao2:addSkill(sy_guiming)

sgs.LoadTranslationTable{	
["~sy_sunhao1"] = "亂臣賊子，不得好死！",
["sy_sunhao2"] = "神孫皓",
["#sy_sunhao2"] = "末世暴君",
["sy_sunhao1"] = "神孫皓",
["#sy_sunhao1"] = "末世暴君",
["~sy_sunhao2"] = "亂臣賊子，不得好死！",
["sy_mingzheng"] = "明政",
[":sy_mingzheng"] = "<font color = \"blue\"><b>鎖定技。</b></font>任一角色摸牌階段摸牌時，額外摸1張牌。當你受到一次傷害時，失去該技能，並獲得技能【嗜殺】"..
"（<font color = \"blue\"><b>鎖定技。</b></font>你使用的【殺】不可被【閃】響應，其他角色可以棄置2張牌來抵消你對其使用的【殺】）。",
["$sy_mingzheng"] = "開倉放糧，賑濟百姓！",
["sy_shisha"] = "嗜殺",
[":sy_shisha"] = "<font color = \"blue\"><b>鎖定技。</b></font>你使用的【殺】不可被【閃】響應，其他角色可以棄置2張牌來抵消你對其使用的【殺】。",
["$sy_shisha"] = "淨是瞎了眼的傢伙！都殺！都殺！",
["shishadiscard"] = "%src的<font color = 'yellow'><b>【嗜殺】</b></font>觸發，你須棄置2張牌來令此【殺】失效，否則此【殺】不可被【閃】響應。",
["sy_zuijiu"] = "醉酒",
["$sy_zuijiu"] = "酒……酒呢！拿酒來！",
[":sy_zuijiu"] = "<font color = \"green\"><b>階段技。</b></font>你可以展示所有手牌，若黑色牌不少於紅色牌，則視為你使用一張【酒】。",
["sy_huangyin"] = "荒淫",
["@huangyin"] = "荒淫",
["huangyin-invoke"] = "請選擇【荒淫】的目標。",
["$sy_huangyin"] = "美人兒來來來，讓朕瞧瞧！",
[":sy_huangyin"] = "每當你從牌堆獲得牌前，可放棄之，改為任意名其他角色處獲得共計等量的牌。",
["sy_guiming"] = "歸命",
["@guiming"] = "歸命",
["$sy_guiming"] = "你們！難道忘了朝廷之恩嗎！",
[":sy_guiming"] = "<font color = \"red\"><b>限定技。</b></font>當你進入瀕死狀態時，你可以令體力值最少的一名其他角色將體力值補至體力上限，然後你回復體力至4點。",
}


--神蔡夫人
sy_caifuren1 = sgs.General(extension, "sy_caifuren1", "god", 7, false)
sy_caifuren2 = sgs.General(extension, "sy_caifuren2", "god", 4, false)


--诋毁
sy_dihuiCard = sgs.CreateSkillCard{
	name = "sy_dihuiCard",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local players = sgs.Self:getAliveSiblings()
			local _max = -1000
			for _, t in sgs.qlist(players) do
				_max = math.max(_max, t:getHp())
			end
			return to_select:getHp() == _max and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local players = room:getOtherPlayers(source)
		players:removeOne(target)
		local t = room:askForPlayerChosen(source, players, "sy_dihui", "dihuiothers-choose")
		if t then room:damage(sgs.DamageStruct("sy_dihui", target, t)) end
	end
}

sy_dihui = sgs.CreateZeroCardViewAsSkill{
	name = "sy_dihui",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sy_dihuiCard")
	end,
	view_as = function()
		return sy_dihuiCard:clone()
	end
}


--乱嗣
sy_luansiCard = sgs.CreateSkillCard{
	name = "sy_luansiCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			return not to_select:isKongcheng()
		elseif #targets == 2 then
			return false
		end
	end,
	feasible = function(self, targets)
		return #targets == 2 and (not targets[1]:isKongcheng()) and (not targets[2]:isKongcheng()) and targets[1]:objectName() ~= sgs.Self:objectName() and targets[2]:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local success = targets[1]:pindian(targets[2], "sy_luansi", nil)
		if success then
			if not targets[2]:isNude() then
				for i = 1, 2, 1 do
					local c = room:askForCardChosen(source, targets[2], "he", "sy_luansi")
					local card = sgs.Sanguosha:getCard(c)
					room:throwCard(card, targets[2], source)
					if targets[2]:isNude() then break end
				end
			end
		else
			if not targets[1]:isNude() then
				for i = 1, 2, 1 do
					local c = room:askForCardChosen(source, targets[1], "he", "sy_luansi")
					local card = sgs.Sanguosha:getCard(c)
					room:throwCard(card, targets[1], source)
					if targets[1]:isNude() then break end
				end
			end
		end
	end
}

sy_luansi = sgs.CreateZeroCardViewAsSkill{
	name = "sy_luansi",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sy_luansiCard")
	end,
	view_as = function()
		return sy_luansiCard:clone()
	end
}


--祸心
sy_huoxin = sgs.CreateTriggerSkill{
	name = "sy_huoxin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.to:objectName() == player:objectName() then
			room:notifySkillInvoked(player, "sy_huoxin")
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			if not damage.from:hasEquip() then
				room:loseHp(damage.from)
				return false
			else
				local choices = {"obtain_equip", "lose_hp"}
				local choice = room:askForChoice(damage.from, self:objectName(), table.concat(choices, "+"))
				if choice == "obtain_equip" then
					local equip = room:askForCardChosen(player, damage.from, "e", self:objectName())
					if equip then room:obtainCard(player, equip) end
				else
					room:loseHp(damage.from)
				end
			end
		end
	end
}


sy_caifuren1:addSkill("#berserk_propertyset")
sy_caifuren1:addSkill("#berserk_change")
sy_caifuren1:addSkill(sy_dihui)
sy_caifuren2:addSkill(sy_dihui)
sy_caifuren2:addSkill(sy_luansi)
sy_caifuren2:addSkill(sy_huoxin)


sgs.LoadTranslationTable{	
["sy_caifuren2"] = "神蔡夫人",
["#sy_caifuren2"] = "蛇蠍美人",
["sy_caifuren1"] = "神蔡夫人",
["#sy_caifuren1"] = "蛇蠍美人",
["~sy_caifuren2"] = "做鬼也不會放過你的！",
["sy_dihui"] = "詆毀",
["$sy_dihui1"] = "夫君，此人留不得！",
["$sy_dihui2"] = "養虎為患，須儘早除之！",
["$sy_luansi1"] = "教你見識一下我的手段！",
["$sy_luansi2"] = "求饒？呵呵……晚了！",
[":sy_dihui"] = "<font color = \"green\"><b>階段技。</b></font>你可令場上（除你外）體力值最多（或之一）的一名角色對另一名其他角色造成1點傷害。",
["dihuiothers-choose"] = "請再選擇一名其他角色。",
["sy_luansi"] = "亂嗣",
["sy_luansi"] = "亂嗣",
[":sy_luansi"] = "<font color = \"green\"><b>階段技。</b></font>你可以令兩名有手牌的其他角色拼點，你棄置沒贏的一方兩張牌。<font color = \"red\"><b>（你選擇"..
"的第一名角色為此拼點的發起人）</b></font>",
["sy_huoxin"] = "禍心",
["$sy_huoxin"] = "別敬酒不吃吃罰酒！",
[":sy_huoxin"] = "<font color = \"blue\"><b>鎖定技。</b></font>每當你受到一次傷害後，傷害來源須令你獲得其裝備區中的一張裝備牌，否則失去1點體力。",
["obtain_equip"] = "該角色獲得你一張裝備區的牌",
["lose_hp"] = "失去一點體力",
}


--神司马懿
sy_simayi1 = sgs.General(extension, "sy_simayi1", "god", 7, true)
sy_simayi2 = sgs.General(extension, "sy_simayi2", "god", 4, true)


--博略
sy_bolueCard = sgs.CreateSkillCard{
	name = "sy_bolueCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		local judge = sgs.JudgeStruct()
		judge.who = source
		judge.pattern = "."
		judge.reason = "sy_bolue"
		judge.play_animation = false
		room:judge(judge)
		local card = judge.card
		local suit = card:getSuit()
		source:obtainCard(card)
		if suit == sgs.Card_Heart and not source:hasSkill("sr_qicai") then
			room:acquireSkill(source, "sr_qicai")
			room:addPlayerMark(source, "sr_qicai_skillClear")
		elseif suit == sgs.Card_Diamond and not source:hasSkill("sr_quanheng") then
			room:acquireSkill(source, "sr_quanheng")
			room:addPlayerMark(source, "sr_quanheng_skillClear")
		elseif suit == sgs.Card_Spade and not source:hasSkill("qiangxi") then
			room:acquireSkill(source, "qiangxi")
			room:addPlayerMark(source, "qiangxi_skillClear")
		elseif suit == sgs.Card_Club and not source:hasSkill("luanji") then
			room:acquireSkill(source, "luanji")
			room:addPlayerMark(source, "luanji_skillClear")
		end
	end
}

sy_bolue = sgs.CreateZeroCardViewAsSkill{
	name = "sy_bolue",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sy_bolueCard")
	end,
	view_as = function()
		return sy_bolueCard:clone()
	end
}

--忍忌
sy_renji = sgs.CreateTriggerSkill{
	name = "sy_renji",
	events = {sgs.Damaged},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.from then return false end
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, "sy_renji")
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.reason = self:objectName()
			judge.pattern = "."
			judge.play_animation = false
			room:judge(judge)			
			local card = judge.card
			local suit = card:getSuit()
			player:obtainCard(card)
			if suit == sgs.Card_Heart then
				if damage.from and not damage.from:isNude() then
					for i = 1, damage.damage do
						if not damage.from:isNude() then
							room:notifySkillInvoked(player, "fankui")
							local card_id = room:askForCardChosen(player, damage.from, "he", "fankui")
							room:obtainCard(player, card_id, false)
						else
							break
						end
					end
				end
			elseif suit == sgs.Card_Diamond then
				if damage.from and not damage.from:isNude() then
					for i = 1, damage.damage do
						if not damage.from:isNude() then
							room:notifySkillInvoked(player, "fankui")
							local card_id = room:askForCardChosen(player, damage.from, "he", "fankui")
							room:obtainCard(player, card_id, false)
						else
							break
						end
					end
				end
			elseif suit == sgs.Card_Spade then
				room:notifySkillInvoked(player, "nosganglie")
				if (not damage.from) or damage.from:isDead() then return false end
				local gangliejudge = sgs.JudgeStruct()
				gangliejudge.pattern = ".|heart"
				gangliejudge.good = false
				gangliejudge.reason = "nosganglie"
				gangliejudge.who = player
				room:judge(gangliejudge)
				if gangliejudge:isGood() then
					if damage.from:getHandcardNum() < 2 or not room:askForDiscard(damage.from, "nosganglie", 2, 2, true) then
						room:damage(sgs.DamageStruct("nosganglie", player, damage.from))
					end
				end
			elseif suit == sgs.Card_Club then
				room:notifySkillInvoked(player, "fangzhu")
				damage.from:drawCards(player:getLostHp())
				damage.from:turnOver()
			end
		end
	end
}


--变天
sy_biantian = sgs.CreateTriggerSkill{
	name = "sy_biantian",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local s = room:findPlayerBySkillName(self:objectName())
		if player:getPhase() ~= sgs.Player_Judge then return false end 
		if s:objectName() == player:objectName() then return false end
		if player:isSkipped(sgs.Player_Judge) then return false end
		room:notifySkillInvoked(s, "sy_biantian")
		room:broadcastSkillInvoke(self:objectName())
		room:sendCompulsoryTriggerLog(s, self:objectName())
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.reason = "lightning"
		judge.pattern = ".|spade|2~9"
		judge.good = false
		judge.negative = true
		room:judge(judge)
		if judge:isGood() then return false end
		local lightning = sgs.Sanguosha:cloneCard("lightning", sgs.Card_NoSuit, 0)
		room:damage(sgs.DamageStruct(lightning, nil, player, 3, sgs.DamageStruct_Thunder))
	end,
	can_trigger = function(self, target)
		return target
	end
}


--天佑：回合结束将牌置于武将牌上，回合开始将其弃置
sy_tianyou = sgs.CreateTriggerSkill{
	name = "sy_tianyou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local you = player:getPile("you")
			local younum = you:length()
			if younum == 0 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:notifySkillInvoked(player, "sy_tianyou")
					room:broadcastSkillInvoke(self:objectName())
					local ids = room:getNCards(1, true)
					local id = ids:first()
					local card = sgs.Sanguosha:getCard(id)
					player:addToPile("you", card)
				end
			end
		end
		if player:getPhase() == sgs.Player_Start then
			local you = player:getPile("you")
			local younum = you:length()
			local idx = -1
			if younum > 0 then
				idx = you:first()
				room:throwCard(idx, player)
				younum = you:length()
			end
		end
	end
}

--天佑：防止同花色牌成为目标
sy_tianyouEf = sgs.CreateProhibitSkill{
	name = "#sy_tianyouEf",
	is_prohibited = function(self, from, to, card)
		if to:hasSkill(self:objectName()) then
			local you = to:getPile("you")
			local X = you:length()
			if X > 0 then
				local youid = you:first()
				local youcard = sgs.Sanguosha:getCard(youid)
				return (not from:hasSkill(self:objectName())) and (to:objectName() ~= from:objectName()) and card:sameColorWith(youcard) 
						and (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic"))
						and card:getTypeId() ~= sgs.Card_TypeSkill
			else
				return false
			end
		end
	end
}


extension:insertRelatedSkills("sy_tianyou", "#sy_tianyouEf")


sy_simayi1:addSkill("#berserk_propertyset")
sy_simayi1:addSkill("#berserk_change")
sy_simayi1:addSkill(sy_bolue)
sy_simayi2:addSkill(sy_bolue)
sy_simayi2:addSkill(sy_renji)
sy_simayi2:addSkill(sy_biantian)
sy_simayi2:addSkill(sy_tianyou)
sy_simayi2:addSkill(sy_tianyouEf)


sgs.LoadTranslationTable{		
["sy_simayi2"] = "神司馬懿",
["~sy_simayi2"] = "呃哦……呃啊……",
["sy_simayi1"] = "神司馬懿",
["#sy_simayi1"] = "三分歸晉",
["#sy_simayi2"] = "三分歸晉",
["sy_bolue"] = "博略",
["$sy_bolue1"] = "老夫，想到一些有趣之事。",
["$sy_bolue2"] = "無用之物，老夫毫無興趣。",
["$sy_bolue3"] = "殺人伎倆，偶爾一用無妨。",
["$sy_bolue4"] = "此種事態，老夫早有準備。",
[":sy_bolue"] = "<font color=\"green\"><b>階段技。</b></font>你可以判定並獲得判定牌，並根據判定結果獲得以下技能直到本回合結束：紅桃-奇才；方塊-權衡；黑桃-"..
"強襲；梅花-亂擊。",
["sy_renji"] = "忍忌",
["$sy_renji1"] = "老夫也不得不認真起來了。",
["$sy_renji2"] = "你們，是要置老夫於死地嗎？",
["$sy_renji3"] = "休要聒噪，吵得老夫頭疼！",
[":sy_renji"] = "每當你受到一次傷害後，你可以判定並獲得判定牌，並根據判定結果視為你對來源發動以下技能：紅色-反饋；黑桃-剛烈；梅花-放逐。 ",
["sy_biantian"] = "變天",
["$sy_biantian"] = "雷起！喝！",
[":sy_biantian"] = "<font color = \"blue\"><b>鎖定技。</b></font>其他角色的判定階段，須進行一次額外的【閃電】判定。",
["sy_tianyou"] = "天佑",
["$sy_tianyou"] = "好好看著吧！",
["#sy_tianyouEf"] = "天佑",
["you"] = "佑",
[":sy_tianyou"] = "回合結束階段開始時，你可以將摸牌堆頂的牌置於你的武將牌上，稱為“佑”。直到你的下個回合開始時，將之置入棄牌堆。若你的武將牌上有牌，你不能"..
"成為其他角色使用的與之顏色相同的牌的目標。"
}


--神亚索
sy_yasuo1 = sgs.General(extension, "sy_yasuo1", "god", 8, true)
sy_yasuo2 = sgs.General(extension, "sy_yasuo2", "god", 4, true)


--风斩：准备阶段，你可进行一次判定，并根据判定结果视为对一名其他角色使用：红桃-火杀；黑桃-雷杀；其他-普通杀（若无可杀的目标，你获得此判定牌）。
sy_fengzhan = sgs.CreateTriggerSkill{
	name = "sy_fengzhan",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then return false end
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.reason = self:objectName()
		judge.play_animation = false
		room:judge(judge)
		local slash
		local suit = judge.card:getSuit()
		if suit == sgs.Card_Heart then
			slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		elseif suit == sgs.Card_Spade then
			slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
		elseif suit == sgs.Card_Diamond or suit == sgs.Card_Club then
			slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		end
		slash:setSkillName(self:objectName())
		local targets = sgs.SPlayerList()
		for _, t in sgs.qlist(room:getOtherPlayers(player)) do
			if not sgs.Sanguosha:isProhibited(player, t, slash) then targets:append(t) end
		end
		if targets:isEmpty() then
			player:obtainCard(judge.card)
			slash:deleteLater()
		end
		local to = room:askForPlayerChosen(player, targets, self:objectName())
		if to then
			local card_use = sgs.CardUseStruct()
			card_use.from = player
			card_use.card = slash
			card_use.to:append(to)
			room:useCard(card_use, false)
		else
			return false
		end
		slash:deleteLater()
		targets = sgs.SPlayerList()
	end
}


sy_yasuo1:addSkill(sy_fengzhan)


--暴风：锁定技，你使用【杀】或此技能造成伤害时目标获得1个“暴风”标记，且获得第3个“暴风”标记时被击飞（若此时该角色武将牌正面朝上，则翻面）。准备阶段，你可弃置一
--张杀，然后对至多3名其他角色各造成1点伤害。
sy_baofengCard = sgs.CreateSkillCard{
	name = "sy_baofengCard",
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and #targets < 3
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets <= 3
	end,
	on_use = function(self, room, source, targets)
		for i = 1, #targets, 1 do
			room:damage(sgs.DamageStruct("sy_baofeng", source, targets[i]))
		end
	end
}

sy_baofengVS = sgs.CreateViewAsSkill{
	name = "sy_baofeng",
	n = 1,
	response_pattern = "@@sy_baofeng",
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = sy_baofengCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName("sy_baofeng")
			return card
		end
	end
}

sy_baofeng = sgs.CreateTriggerSkill{
	name = "sy_baofeng",
	view_as_skill = sy_baofengVS,
	events = {sgs.PreDamageDone, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.to:objectName() ~= player:objectName() and (damage.card:isKindOf("Slash") or damage.reason == self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				damage.to:gainMark("@fiercewind", 1)
				if damage.to:getMark("@fiercewind") >= 3 then
					if damage.to:faceUp() then damage.to:turnOver() end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, t in sgs.qlist(room:getOtherPlayers(player)) do
					if (not t:faceUp()) and t:getMark("@fiercewind") >= 3 then t:loseAllMarks("@fiercewind") end
				end
			end
			if player:getPhase() == sgs.Player_Start then
				room:askForUseCard(player, "@@sy_baofeng", "@baofeng_damage")
			end
		end
		return false
	end
}


sy_yasuo2:addSkill(sy_baofeng)


--无鞘：你成为【杀】的目标或你使用【杀】对其他角色造成伤害时，你可弃置目标一张牌。锁定技，你使用的【杀】被【闪】响应时，你摸1张牌。
sy_wuqiao = sgs.CreateTriggerSkill{
	name = "sy_wuqiao",
	events = {sgs.TargetConfirmed, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_do = false
		local to = nil
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from:objectName() ~= player:objectName() then
				if not use.to:contains(player) then return false end
				if not use.card:isKindOf("Slash") then return false end
				if use.from:isNude() then return false end
				to = use.from
				can_do = true
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()		
			if damage.from and damage.from:objectName() == player:objectName() and damage.card:isKindOf("Slash") then
				if damage.to:isNude() then return false end
				to = damage.to
				can_do = true
			end
		end
		if can_do and to ~= nil then
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local to_throw = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
			room:broadcastSkillInvoke(self:objectName())
			room:throwCard(sgs.Sanguosha:getCard(to_throw), to, player)
		end
		return false
	end
}

sy_wuqiaojink = sgs.CreateTriggerSkill{
	name = "#sy_wuqiao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local yasuo = room:findPlayerBySkillName(self:objectName())
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == yasuo:objectName() and use.card:isKindOf("Slash") then
				if not use.to:isEmpty() then room:setPlayerMark(yasuo, "wuqiao_slash", 1) end
			end
		elseif event == sgs.CardResponded then
			local card_star = data:toCardResponse().m_card			
			if card_star:isKindOf("Jink") then
				if yasuo and yasuo:getMark("wuqiao_slash") > 0 then
					room:sendCompulsoryTriggerLog(yasuo, self:objectName())
					room:notifySkillInvoked(yasuo, self:objectName())
					yasuo:drawCards(1)
				end
			end
		elseif event == sgs.CardFinished then
			local card = data:toCardUse().card
			local from = data:toCardUse().from
			if from then
				if from:objectName() == yasuo:objectName() then
					if card:isKindOf("Slash") and yasuo:getMark("wuqiao_slash") > 0 then
						room:setPlayerMark(yasuo, "wuqiao_slash", 0)
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


extension:insertRelatedSkills("sy_wuqiao", "#sy_wuqiao")
sy_yasuo1:addSkill(sy_wuqiao)
sy_yasuo1:addSkill(sy_wuqiaojink)
sy_yasuo2:addSkill(sy_wuqiao)
sy_yasuo2:addSkill(sy_wuqiaojink)


--风影：你即将受到【杀】或【决斗】的伤害时，你可将牌堆顶的3张牌置入弃牌堆，若其中有【杀】或【决斗】，你摸1张牌，然后此伤害-1。锁定技，与你距离大于1的角色不能对
--你造成伤害。
sy_fengying = sgs.CreateTriggerSkill{
	name = "sy_fengying",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:objectName() == player:objectName() then
			if damage.from then
				if damage.from:distanceTo(player) > 1 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					return true
				end
			end
			if not damage.card then return false end
			if ((not damage.card:isKindOf("Slash")) and (not damage.card:isKindOf("Duel"))) then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			if room:getDrawPile():isEmpty() then room:swapPile() end
			local cards = room:getDrawPile()
			local a = 0
			local b = 0
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			room:broadcastSkillInvoke(self:objectName())
			while b < 3 do
				local cardsid = cards:at(0)
				local move = sgs.CardsMoveStruct()
				move.card_ids:append(cardsid)
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local c = sgs.Sanguosha:getCard(cardsid)
				if c:isKindOf("Slash") or c:isKindOf("Duel") then a = a + 1 end
				dummy:addSubcard(cardsid)
				b = b + 1
				if cards:length() == 0 then room:swapPile() end
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), self:objectName(), "")
			room:moveCardTo(dummy, player, sgs.Player_DiscardPile, reason)
			dummy:deleteLater()
			if a > 0 then
				player:drawCards(1)
				damage.damage = damage.damage - 1
				data:setValue(damage)
				if damage.damage < 1 then return true end
			end
		end
	end
}


sy_yasuo2:addSkill(sy_fengying)


--真·狂风绝息斩：回合结束阶段，你可对所有被击飞的角色造成2+X点伤害（X为你已损失体力值的一半，向下取整），然后你将武将牌翻面。
sy_juexi = sgs.CreateTriggerSkill{
	name = "sy_juexi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if (not p:faceUp()) and p:getMark("@fiercewind") > 0 then targets:append(p) end
		end
		if targets:isEmpty() then return false end
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("$death_breath", 1500)
			for _, target in sgs.qlist(targets) do
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 2+math.floor(player:getLostHp()/2)))
			end
			player:turnOver()
		end
		for _, t in sgs.qlist(room:getAlivePlayers()) do
			if t:getMark("@fiercewind") > 0 then t:loseAllMarks("@fiercewind") end
		end
	end
}


sy_yasuo2:addSkill(sy_juexi)


sy_yasuo1:addSkill("#berserk_change")
sy_yasuo1:addSkill("#berserk_propertyset")


sgs.LoadTranslationTable{
["sy_yasuo2"] = "神亞索",
["~sy_yasuo2"] = "不是你死，就是我亡！",
["sy_yasuo1"] = "神亞索",
["#sy_yasuo1"] = "孤高的浪客",
["#sy_yasuo2"] = "疾行之刃",
["sy_fengzhan"] = "風斬",
["$sy_fengzhan1"] = "滅亡之路，短的超乎你的想像。",
["$sy_fengzhan2"] = "呵，汝欲赴死，易如反掌。",
["$sy_fengzhan3"] = "速戰速決。",
["$sy_fengzhan4"] = "我會給你個痛快的。",
[":sy_fengzhan"] = "準備階段，你可進行一次判定，並根據判定結果視為對一名其他角色使用：紅桃-火殺；黑桃-雷殺；其他-普通殺（若無可殺的目標，你獲得此判定牌）。",
["sy_wuqiao"] = "無鞘",
["#sy_wuqiao"] = "無鞘",
["sy_wuqiaojink"] = "無鞘",
["$sy_wuqiao1"] = "想殺我？你可以試一試。",
["$sy_wuqiao2"] = "回首往昔，更進一步。",
["$sy_wuqiao3"] = "有些失誤無法犯兩次。",
["$sy_wuqiao4"] = "有些事絕對不會無趣。",
[":sy_wuqiao"] = "你成為【殺】的目標或你使用【殺】對其他角色造成傷害時，你可棄置目標一張牌。<font color = \"blue\"><b>鎖定技。</b></font>你使用的【殺】被"..
"【閃】響應時，你摸1張牌。",
["sy_baofeng"] = "暴風",
["@fiercewind"] = "暴風",
["$sy_baofeng1"] = "hasaki",
["$sy_baofeng2"] = "殺人是種惡習，但我似乎戒不掉了。",
["$sy_baofeng3"] = "死亡而已，沒什麼大不了的。",
["$sy_baofeng4"] = "一劍，一念。",
[":sy_baofeng"] = "<font color = \"blue\"><b>鎖定技。</b></font>你使用【殺】或由此技能造成傷害時目標獲得1個“暴風”標記，且獲得第3個“暴風”標記時被擊飛（若此"..
"時該角色武將牌正面朝上，則翻面）。準備階段，你可棄置一張殺，然後對至多3名其他角色各造成1點傷害。",
["sy_fengying"] = "風影",
["$sy_fengying1"] = "面對疾風吧！",
["$sy_fengying2"] = "且隨疾風前行，身後亦需留心。",
["$sy_fengying3"] = "吾雖浪跡天涯，卻未迷失本心。",
[":sy_fengying"] = "你即將受到【殺】或【決鬥】的傷害時，你可將牌堆頂的3張牌置入棄牌堆，若其中有【殺】或【決鬥】，你摸1張牌，然後此傷害-1。<font color = \"blue\"><b>鎖定技。</b></font>"..
"與你距離大於1的角色不能對你造成傷害。",
["sy_juexi"] = "真·狂風絕息斬",
["$death_breath"] = "image=image/animate/sy_juexi.png",
["$sy_juexi1"] = "醋裂",
["$sy_juexi2"] = "索里耶給痛",
["$sy_juexi3"] = "爺給洞",
[":sy_juexi"] = "回合結束階段，你可對所有被擊飛的角色造成2+X點傷害（X為你已損失體力值的一半，向下取整），然後你將武將牌翻面。"
}


--神司马师
sy_simashi1 = sgs.General(extension, "sy_simashi1", "god", 8, true)
sy_simashi2 = sgs.General(extension, "sy_simashi2", "god", 4, true)


--权略：锁定技，其他角色摸牌阶段结束时，若其装备区的牌数不小于你，则该角色须交给你一张基本牌，否你对其造成1点伤害。
sy_quanlue = sgs.CreateTriggerSkill{
	name = "sy_quanlue",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local simashi = room:findPlayerBySkillName(self:objectName())
		if player:objectName() ~= simashi:objectName() and player:getPhase() == sgs.Player_Draw and player:getEquips():length() >= simashi:getEquips():length() then
			local prompt = string.format("@quanlue:%s:%s", simashi:objectName(), self:objectName())
			local c = room:askForCard(player, "BasicCard", prompt, data, sgs.Card_MethodNone)
			if c then
				room:sendCompulsoryTriggerLog(simashi, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(simashi, self:objectName())
				simashi:obtainCard(c)
			else
				room:sendCompulsoryTriggerLog(simashi, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(simashi, self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), simashi, player))
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}


sy_simashi1:addSkill(sy_quanlue)
sy_simashi2:addSkill(sy_quanlue)


--峻平：锁定技，准备阶段，你进行一次判定并获得判定牌，若结果为①红色-摸X张牌（X为该牌点数的1/3，向上取整）；②黑色-攻击范围内有你的所有角色弃置2张牌。
sy_junping = sgs.CreateTriggerSkill{
	name = "sy_junping",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.reason = self:objectName()
			judge.play_animation = false
			judge.pattern = "."
			room:judge(judge)
			local card = judge.card
			player:obtainCard(card)
			if card:isRed() then
				local X = math.ceil(card:getNumber()/3)
				player:drawCards(X)
			else
				for _, t in sgs.qlist(room:getOtherPlayers(player)) do
					if t:inMyAttackRange(player) then
						room:askForDiscard(t, self:objectName(), 2, 2, false, true)
					end
				end
			end
		end
	end
}


sy_simashi2:addSkill(sy_junping)


--逆元：阶段技，你可失去1点体力并对所有其他角色造成1点伤害，则直到你下个回合开始，所有其他角色受到的伤害+1。
sy_niyuanCard = sgs.CreateSkillCard{
	name = "sy_niyuanCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		room:loseHp(source)
		for _, t in sgs.qlist(room:getOtherPlayers(source)) do
			room:damage(sgs.DamageStruct("sy_niyuan", source, t))
		end
		source:gainMark("@niyuan_damage")
	end
}

sy_niyuanVS = sgs.CreateZeroCardViewAsSkill{
	name = "sy_niyuan",
	view_as = function()
		return sy_niyuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getHp() > 1 and (not player:hasUsed("#sy_niyuanCard"))
	end
}

sy_niyuan = sgs.CreateTriggerSkill{
	name = "sy_niyuan",
	view_as_skill = sy_niyuanVS,
	events = {sgs.ConfirmDamage, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not room:findPlayerBySkillName(self:objectName()) then return false end
		local simashi = room:findPlayerBySkillName(self:objectName())
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if simashi:getMark("@niyuan_damage") > 0 and damage.to and damage.to:objectName() ~= simashi:objectName() then
				room:sendCompulsoryTriggerLog(simashi, self:objectName())
				room:notifySkillInvoked(simashi, self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.EventPhaseStart then
			if simashi:getPhase() == sgs.Player_Start then
				if simashi:getMark("@niyuan_damage") > 0 then
					simashi:loseAllMarks("@niyuan_damage")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return true
	end
}


sy_simashi2:addSkill(sy_niyuan)


--死士：回合结束阶段，你可令一名有手牌的其他角色进行判定，然后对其造成X点伤害（X为该角色手牌中花色与此牌花色相同的牌数的一半，向下取整）。
sy_sishi = sgs.CreateTriggerSkill{
	name = "sy_sishi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local targets = sgs.SPlayerList()
			for _, t in sgs.qlist(room:getOtherPlayers(player)) do
				if not t:isKongcheng() then targets:append(t) end
			end
			if targets:isEmpty() then return false end
			if not player:askForSkillInvoke(self:objectName(), data) then return false end
			local target = room:askForPlayerChosen(player, targets, self:objectName())
			local judge = sgs.JudgeStruct()
			judge.who = target
			judge.pattern = "."
			judge.play_animation = false
			judge.reason = self:objectName()
			room:judge(judge)
			room:broadcastSkillInvoke(self:objectName())
			local suit = judge.card:getSuit()
			local X = 0
			for _, c in sgs.qlist(target:getHandcards()) do
				if c:getSuit() == suit then X = X + 1 end
			end
			X = math.floor(X/2)
			if X == 0 then return false end
			room:damage(sgs.DamageStruct("sy_sishi", player, target, X))
		end
	end
}


sy_simashi2:addSkill(sy_sishi)
sy_simashi1:addSkill("#berserk_propertyset")
sy_simashi1:addSkill("#berserk_change")


sgs.LoadTranslationTable{
["sy_simashi1"] = "神司馬師",
["#sy_simashi1"] = "天命王者",
["sy_simashi2"] = "神司馬師",
["#sy_simash2"] = "天命王者",
["~sy_simashi2"] = "天命……並不在……我這裡嗎……",
["sy_quanlue"] = "權略",
["@quanlue"] = "%src的【%dst】效果，你須交給%src一張基本牌。",
[":sy_quanlue"] = "<font color = \"blue\"><b>鎖定技。</b></font>其他角色摸牌階段結束時，若其裝備區的牌數不小於你，則該角色須交給你一張基本牌，否你對其造成"..
"1點傷害。",
["$sy_quanlue1"] = "最後站在頂點的人一定是我。",
["$sy_quanlue2"] = "來啊！如果你要是能打倒我的話！",
["sy_junping"] = "峻平",
["$sy_junping"] = "就讓我來看看，你不是凡夫俗子的證明！",
[":sy_junping"] = "<font color = \"blue\"><b>鎖定技。</b></font>準備階段，你進行一次判定並獲得判定牌，然後摸X張牌（ X為該牌點數的1/3，向上取整）。",
["sy_niyuan"] = "逆元",
["@niyuan_damage"] = "逆元",
[":sy_niyuan"] = "<font color = \"green\"><b>階段技。</b></font>你可失去1點體力並對所有其他角色造成1點傷害，則直到你下個回合開始，所有其他角色受到的傷害+1。",
["sy_sishi"] = "死士",
["$sy_sishi"] = "目標已經確定，接下對你的命運的裁決！",
[":sy_sishi"] = "回合結束階段，你可令一名有手牌的其他角色進行判定，然後對其造成X點傷害（X為該角色手牌中花色與此牌花色相同的牌數的一半，向下取整）。",

}


--协调技能卡录音做的白板
whiteboard = sgs.General(extension, "whiteboard", "god", "99", true, true, true)


shiao_slash = sgs.CreateTriggerSkill{
	name = "shiao_slash",
	events = {},
	on_trigger = function()
	end
}

kuangxi_slash = sgs.CreateTriggerSkill{
	name = "kuangxi_slash",
	events = {},
	on_trigger = function()
	end
}

zongyu_ana = sgs.CreateTriggerSkill{
	name = "zongyu_ana",
	events = {},
	on_trigger = function()
	end
}

zuijiu_ana = sgs.CreateTriggerSkill{
	name = "zuijiu_ana",
	events = {},
	on_trigger = function()
	end
}

whiteboard:addSkill(shiao_slash)
whiteboard:addSkill(kuangxi_slash)
whiteboard:addSkill(zongyu_ana)
whiteboard:addSkill(zuijiu_ana)
whiteboard:addSkill(sy_shisha)


sgs.LoadTranslationTable{
["shiao_slash"] = "恃傲",
["zongyu_ana"] = "縱慾",
["zuijiu_ana"] = "醉酒",
["kuangxi_slash"] = "狂襲",
["#berserk_second"] = "%from 暴怒了！即將進入<font color = \"yellow\"><b>三英模式</b></font>·<font color = \"pink\"> <b>第二階段</b></font>！",
}