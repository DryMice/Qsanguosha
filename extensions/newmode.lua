module("extensions.newmode", package.seeall)
extension = sgs.Package("newmode")

sgs.LoadTranslationTable{
	["newmode"] = "新模式",
}

local skills = sgs.SkillList()

--神諸葛亮的七星
function getqixing(player)
	local room = player:getRoom()
	if player:hasSkill("qixing") then
		local list = sgs.IntList()
		for _, id in sgs.qlist(room:getDrawPile()) do
			list:append(id)
			if list:length() == 7 then
				break
			end
		end
		player:addToPile("stars", list)
	end

	if player:hasSkill("mingren") then
		player:drawCards(1)
		player:addToPile("ren", room:getDrawPile():first())
	end

	if player:hasSkill("huashen_po") then
		room:notifySkillInvoked(player, "huashen")
		if player:isMale() then
			room:broadcastSkillInvoke("huashen",math.random(1,2))
		else
			room:broadcastSkillInvoke("huashen",math.random(3,4))
		end
		AcquireGenerals(player, 3)
		SelectSkill(player)
	end

end

--小戰場、僵屍模式專用
smallMode = sgs.CreateTriggerSkill{
	name = "#smallMode" ,
	events = {sgs.EventPhaseChanging,sgs.DamageComplete,sgs.CardFinished} ,
	priority = 100,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_RoundStart and 
			 (string.find(room:getMode(),"_mini") ~= nil)
			 and player:getMark("AG_hasExecuteStart") == 0 then

			 	local need_to_do_GS = true
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "AG_BAN") and player:getMark(mark) > 0 then
						need_to_do_GS = false
					end
				end

				if need_to_do_GS then
				 	for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setTag("FirstRound" , sgs.QVariant(true))
						room:addPlayerMark(p,"AG_predraw",p:getHandcardNum())
						local move = sgs.CardsMoveStruct(p:handCards(), p, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, p:objectName(), self:objectName(), ""))
						room:moveCardsAtomic(move, false)

						room:setTag("FirstRound" , sgs.QVariant(false))
					end

				 	local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
					card_remover:trigger(sgs.GameStart, room, player, data)
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
						room:setPlayerMark(p, "AG_hasExecuteStart",1)
					end

					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setTag("FirstRound" , sgs.QVariant(true))
						if p:getMark("AG_predraw") > 0 then
							p:drawCards( p:getMark("AG_predraw") )
							room:setPlayerMark(p,"AG_predraw",0)
						end

						room:setTag("FirstRound" , sgs.QVariant(false))
					end
				end
			end
		end

		if event == sgs.CardFinished or event == sgs.DamageComplete or
		 event == sgs.EventPhaseChanging then
			if room:getMode() == "zombie_mode" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getGeneral2() and p:getGeneral2Name() == "zombie" and p:getMark("zombie_done") == 0 then
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
						room:setPlayerMark(p, "zombie_done",1)

						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							for _, mark in sgs.list(pp:getMarkNames()) do
								if string.find(mark, "AG_BAN") and pp:getMark(mark) > 0 then
									room:setPlayerMark(p, mark, 1)
								end
							end
						end

						for _,skill in sgs.qlist(p:getVisibleSkillList()) do
							if skill:getFrequency() == sgs.Skill_Limited then
								room:handleAcquireDetachSkills(p, "-"..skill:objectName().."|"..skill:objectName())
							end
						end

					end
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target 
	end
}

if not sgs.Sanguosha:getSkill("#smallMode") then skills:append(smallMode) end

--特權系統

--重獲生機：每回合開始後有10%、20%、30%、40%、60%（對應1-5級）概率回復一點體力；
--免減一傷：當受到傷害時有10%、20%、30%、40%、60%（對應1-5級）減少一點傷害；
--武力蓋世：在自己回合內造成傷害時有10%、20%、30%、40%、60%（對應1-5級）傷害+1；
--糧多兵足：在回合開始時有10%、20%、30%、40%、60%（對應1-5級）概率額外摸一張牌；

talent_privilege = sgs.CreateTriggerSkill{
	name = "#talent_privilege",
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.EventPhaseStart,sgs.DamageCaused,sgs.DamageInflicted},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local prate = {1,2,3,4,6}
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:getMark("@talent_privilege3") > 0 then
				if math.random(1,10) <= prate[player:getMark("@talent_privilege3")] then
					local _data = sgs.QVariant()
					_data:setValue(damage.to)
					if player:askForSkillInvoke("talent_privilege3", _data) then
						damage.damage = damage.damage + 1
						local msg = sgs.LogMessage()
						msg.type = "#Talent_privilege3"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage-1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Start then
				if player:getMark("@talent_privilege1") > 0 and player:isWounded() then
					if math.random(1,10) <= prate[player:getMark("@talent_privilege1")] then
						if player:askForSkillInvoke("talent_privilege1", data) then
							local theRecover = sgs.RecoverStruct()
							theRecover.recover = 1
							theRecover.who = player
							room:recover(player, theRecover)
							--local msg = sgs.LogMessage()
							--msg.type = "#Talent_privilege1"
							--msg.from = player
							--msg.to:append(player)
							--room:sendLog(msg)
						end
					end
				end
				if player:getMark("@talent_privilege4") > 0 then
					if math.random(1,10) <= prate[player:getMark("@talent_privilege4")] then
						if player:askForSkillInvoke("talent_privilege4", data) then
							player:drawCards(1)
							--local msg = sgs.LogMessage()
							--msg.type = "#Talent_privilege4"
							--msg.from = player
							--msg.to:append(player)
							--room:sendLog(msg)
						end
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:getMark("@talent_privilege2") > 0 then
				if math.random(1,10) <= prate[player:getMark("@talent_privilege2")] then
					if player:askForSkillInvoke("talent_privilege2", data) then
						local msg = sgs.LogMessage()
						msg.type = "#Talent_privilege2"
						msg.from = player
						msg.to:append(damage.from)
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
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}


if not sgs.Sanguosha:getSkill("#talent_privilege") then skills:append(talent_privilege) end


sgs.LoadTranslationTable{
	["talent_privilege"] = "武將特權",
	["#talent_privilege"] = "武將特權",
	["@talent_privilege1"] = "重獲生機",
	["@talent_privilege2"] = "免減一傷",
	["@talent_privilege3"] = "武力蓋世",
	["@talent_privilege4"] = "糧多兵足",
	["talent_privilege1"] = "重獲生機",
	["talent_privilege2"] = "免減一傷",
	["talent_privilege3"] = "武力蓋世",
	["talent_privilege4"] = "糧多兵足",
	["#Talent_privilegechoose"] = "%from 武將特權， %arg 選擇了 %arg2 點",
	["#Talent_privilege1"] = "%from 發動了特權“<font color=\"yellow\"><b>重獲生機</b></font>”，回復一點體力",
	["#Talent_privilege2"] = "%from 發動了特權“<font color=\"yellow\"><b>免減一傷</b></font>”，%to 造成的傷害由 %arg 點減少到"..
" %arg2 點",
	["#Talent_privilege3"] = "%from 發動了特權“<font color=\"yellow\"><b>武力蓋世</b></font>”，對 %to 造成傷害由 %arg 點增加到"..
" %arg2 點",
	["#Talent_privilege4"] = "%from 發動了特權“<font color=\"yellow\"><b>糧多兵足</b></font>”，多摸一張牌",
}

--[[
將靈們
]]--

--將靈系統
--將靈

--神周瑜（S級）
--業炎：出牌階段開始時，你有60-80%的概率可以選擇至多2名角色，對這些角色各造成2點火焰傷害
--琴音：結束階段，你有70-90%的概率可以選擇兩名角色分別失去或回復1點體力。
jl_shenzhouyu = sgs.General(extension, "jl_shenzhouyu", "god", "4",  true, true, true)

jl_yeyanCard = sgs.CreateSkillCard{
	name = "jl_yeyanCard",
	filter = function(self, targets, to_select, erzhang)
		return #targets < 2
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do 
			room:damage(sgs.DamageStruct("jl_yeyan", source, p, 2, sgs.DamageStruct_Fire))
		end
	end,
}
jl_yeyanVS = sgs.CreateZeroCardViewAsSkill{
	name = "jl_yeyan",
	response_pattern = "@@jl_yeyan",
	view_as = function()
		return jl_yeyanCard:clone()
	end,
}
jl_yeyan = sgs.CreateTriggerSkill{
	name = "jl_yeyan",
	events = {sgs.EventPhaseStart},
	view_as_skill = jl_yeyanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 70 then
				room:askForUseCard(player, "@@jl_yeyan", "@jl_yeyan-ask",-1)
			end
		end
		return false
	end
}

jl_shenzhouyu:addSkill(jl_yeyan)

jl_qinyinCard = sgs.CreateSkillCard{
	name = "jl_qinyinCard",
	filter = function(self, targets, to_select, erzhang)
		return #targets < 2
	end,
	on_use = function(self, room, source, targets)
		local choices = {"jl_qinyin:down", "jl_qinyin:up"}
		for _, p in ipairs(targets) do 
			room:doAnimate(1, source:objectName(), p:objectName())
			local choice = room:askForChoice(source, "jl_yeyan", table.concat(choices, "+"))
			if choice == "jl_qinyin:down" then
				room:doAnimate(1, source:objectName(), p:objectName())
				room:loseHp(p)		
			elseif choice == "jl_qinyin:up" then
				room:doAnimate(1, source:objectName(), p:objectName())
				local theRecover2 = sgs.RecoverStruct()
				theRecover2.recover = 1
				theRecover2.who = p
				room:recover(p, theRecover2)	
			end 
		end
	end
}
jl_qinyinVS = sgs.CreateZeroCardViewAsSkill{
	name = "jl_qinyin",
	response_pattern = "@@jl_qinyin",
	view_as = function()
		return jl_qinyinCard:clone()
	end
}
jl_qinyin = sgs.CreateTriggerSkill{
	name = "jl_qinyin",
	events = {sgs.EventPhaseStart},
	view_as_skill = jl_qinyinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if math.random(1,100) <= 80 then
				room:askForUseCard(player, "@@jl_qinyin", "@jl_qinyin-ask",-1)
			end
		end
		return false
	end
}


jl_shenzhouyu:addSkill(jl_qinyin)

sgs.LoadTranslationTable{
	["jl_shenzhouyu"] = "神周瑜",
	["#jl_shenzhouyu"] = "將靈",
	["jl_yeyan"] = "業炎",
	[":jl_yeyan"] = "出牌階段開始時，你有70%的概率可以選擇至多2名角色，對這些角色各造成2點火焰傷害",
	["@jl_yeyan-ask"] = "你可以選擇至多2名角色，對這些角色各造成2點火焰傷害",
	["~jl_yeyan"] = "選擇這些角色 -> 點擊「確定」",

	["jl_qinyin"] = "琴音",
	[":jl_qinyin"] = "結束階段，你有80%的概率可以選擇兩名角色分別失去或回復1點體力。",
	["@jl_qinyin-ask"] = "你可以選擇兩名角色分別失去或回復1點體力。",
	["jl_qinyin:up"] = "該角色回復1點體力",
	["jl_qinyin:down"] = "該角色失去1點體力",
}

--[[
神趙雲（S級）
絕境:你進入或脫離瀕死狀態時，你有80%的概率摸二至四張牌。
龍魂:你使用【殺】或【桃】時，有70%的概率此牌傷害或回復值+1~2，
且你使用【閃】或【無懈可擊】時，有70%概率棄置當前回合角色至多兩張牌。
]]--
jl_shenzhaoyun = sgs.General(extension,"jl_shenzhaoyun","god","4",true,true, true)
--絕境
jl_juejing = sgs.CreateTriggerSkill{
	name = "jl_juejing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged then
			if player:getHp() > 0 then
				if player:hasFlag("pre_dying") then
					if math.random(1,100) <= 80 then
						if room:askForSkillInvoke(player, self:objectName()) then
							player:drawCards(math.random(2,4))
						end
					end
					room:setPlayerFlag(player, "-pre_dying")
				end
			elseif player:getHp() <= 0 then
				if not player:hasFlag("pre_dying") then
					if math.random(1,100) <= 80 then
						if room:askForSkillInvoke(player, self:objectName()) then
							player:drawCards(math.random(2,4))
						end
					end
					room:setPlayerFlag(player, "pre_dying")
				end
			end
		end
	end,
}
jl_juejingMaxCard = sgs.CreateMaxCardsSkill{
	name = "#jl_juejingCard", 
	extra_func = function(self, target)
		if target:hasSkill("jl_juejing") then
			return 2
		end
	end
}

--龍魂
jl_longhun = sgs.CreateTriggerSkill{
	name = "jl_longhun",
	events = {sgs.PreHpRecover, sgs.ConfirmDamage, sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:isKindOf("Peach") then
				if math.random(1,100) <= 70 then
					if room:askForSkillInvoke(player, self:objectName()) then
						n = math.random(1,2)
						rec.recover = rec.recover + n
						local msg = sgs.LogMessage()
						msg.type = "#JlJieyuanRec"
						msg.from = player
						msg.to:append(rec.who)
						msg.arg = tostring(rec.recover - n)
						msg.arg2 = tostring(rec.recover)
						room:sendLog(msg)
						data:setValue(rec)
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				if math.random(1,100) <= 70 then
					if room:askForSkillInvoke(player, self:objectName()) then
						n = math.random(1,2)
						damage.damage = damage.damage + n
						local msg = sgs.LogMessage()
						msg.type = "#JlJieyuanPD"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - n)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
						data:setValue(damage)
					end
				end
			end
		else
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				--local response = data:toCardResponse()
				--if response.m_isUse then
				--	card = response.m_card
				--end
				card = data:toCardResponse().m_card	
			end
			if card and (card:isKindOf("Jink") or card:isKindOf("Nullification")) then
				local current = room:getCurrent()
				if current:isNude() then return false end
				if math.random(1,100) <= 70 then
					if room:askForSkillInvoke(player, self:objectName()) then
						room:doAnimate(1, player:objectName(), current:objectName())
						local id = room:askForCardChosen(player, current, "he", "jl_longhun", false, sgs.Card_MethodDiscard)
						room:throwCard(id, current, splayer)
					end
				end
			end
		end
		return false
	end
}


jl_shenzhaoyun:addSkill(jl_juejing)
jl_shenzhaoyun:addSkill(jl_longhun)

sgs.LoadTranslationTable{
	["jl_shenzhaoyun"]="神趙雲",
	["jl_longhun"] = "龍魂",
	[":jl_longhun"] = "你使用【殺】或【桃】時，有70%的概率此牌傷害或回復值+1~2，且你使用【閃】或【無懈可擊】時，有70%概率棄置當前回合角色至多兩張牌。",
	["jl_juejing"] = "絕境",
	[":jl_juejing"] = "你進入或脫離瀕死狀態時，你有80%的概率摸二至四張牌。",
	["#JlLonghunPD"] = "%from 的技能 “<font color=\"yellow\"><b>龍魂</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",

	["#JlLonghunRec"] = "%from 的技能 “<font color=\"yellow\"><b>龍魂</b></font>”被觸發， %to 的回復由 %arg 點增加到 %arg2 點",
}

--[[
年獸（S級）
反戈：當你受到傷害後，你有80%的概率摸兩張牌，然後獲得傷害來源一至兩張牌，再對傷害來源造成1點傷害。

尋獵：一名已受傷的其他角色回合結束時，你有80%的概率隨機一名角色：我方一名角色摸三張牌回復1點體力；
敵方一名角色棄置其三張牌造成1點傷害。 （每輪限觸發一次）
nianshou fange xunlie
]]--
jl_nianshou = sgs.General(extension,"jl_nianshou","god","4",true,true, true)

jl_xunlie = sgs.CreatePhaseChangeSkill{
	name = "jl_xunlie",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark("jl_xunlie_lun") == 0 then
					if math.random(1,100) <= 80 then
						if room:askForSkillInvoke(p, self:objectName()) then
							room:addPlayerMark(p, "jl_xunlie_lun")
							room:notifySkillInvoked(p, self:objectName())
						
							local choices = {"jl_xunlie:down", "jl_xunlie:up"}
							local all_alive_players = {}
							for _, q in sgs.qlist(room:getOtherPlayers(p)) do
								table.insert(all_alive_players, q)
							end
							local random_target = all_alive_players[math.random(1, #all_alive_players)]

								room:doAnimate(1, p:objectName(), random_target:objectName())
								local choice = room:askForChoice(p, "jl_xunlie", table.concat(choices, "+"))
								if choice == "jl_xunlie:down" then
									room:doAnimate(1, p:objectName(), random_target:objectName())
									room:askForDiscard(random_target, self:objectName(), 3, 3, false, true)
									room:damage(sgs.DamageStruct(self:objectName(), p, random_target))	
								elseif choice == "jl_xunlie:up" then
									room:doAnimate(1, p:objectName(), random_target:objectName())
									random_target:drawCards(3)
									local theRecover2 = sgs.RecoverStruct()
									theRecover2.recover = 1
									theRecover2.who = random_target
									room:recover(random_target, theRecover2)	
								end 
							
						end
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

jl_fange = sgs.CreateMasochismSkill{
	name = "jl_fange" ,
	on_damaged = function(self, target, damage)
		if math.random(1,100) <= 88 then
			if target:askForSkillInvoke(self:objectName(), sgs.QVariant():setValue(damage)) then
				target:drawCards(2, self:objectName())
				local room = target:getRoom()
				if damage.from then
					local n = math.random(1,2)
					for i = 1,n,1 do 
						if damage.from:canDiscard(damage.from, "he") then
							local id = room:askForCardChosen(target, damage.from, "he", "jl_fange", false, sgs.Card_MethodDiscard)
							room:obtainCard(id, target)
						end
					end
					room:damage(sgs.DamageStruct(self:objectName(), target, damage.from))
				end
			end
		end
	end
}

jl_nianshou:addSkill(jl_xunlie)
jl_nianshou:addSkill(jl_fange)

sgs.LoadTranslationTable{
	["jl_nianshou"] = "年獸",
	["#jl_nianshou"] = "將靈",
	["jl_xunlie"] = "尋獵",
	[":jl_xunlie"] = "一名已受傷的其他角色回合結束時，你有80%的概率隨機一名角色：我方一名角色摸三張牌回復1點體力；"..
"敵方一名角色棄置其三張牌造成1點傷害。 （每輪限觸發一次）",

	["jl_xunlie:up"] = "該角色摸三張牌,回復1點體力",
	["jl_xunlie:down"] = "該角色棄置其三張牌,你對其造成1點傷害",

	["jl_fange"] = "反戈",
	[":jl_fange"] = "當你受到傷害後，你有80%的概率摸兩張牌，然後獲得傷害來源一至兩張牌，再對傷害來源造成1點傷害。",
}

--[[
諸葛果將靈

祈禳：當你使用一張裝備牌時或回合內使用第一張基本牌時，你有【75%+0.8%*（當前等級-76）】的概率從牌堆或棄牌堆摸兩至三張錦囊牌
（每回合限觸發兩次）。
羽化：結束階段，你有【75%+0.8%*（當前等級-1）】的概率觀看牌堆頂Y張牌（Y為你本回合使用的錦囊牌且至少為4），然後獲得其中至多三張牌。
]]--
jl_zhugeguo = sgs.General(extension,"jl_zhugeguo","shu","4",false,true, true)

jl_qirang = sgs.CreateTriggerSkill{
	name = "jl_qirang",
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		
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
		if not true then return false end

		if (card:isKindOf("BasicCard") and player:getMark("jl_qirang_Basic-Clear") < 2 and not player:getPhase() == sgs.Player_NotActive ) or card:isKindOf("EquipCard") then
			if card:isKindOf("BasicCard") then
				room:setPlayerMark(player,"jl_qirang_Basic-Clear",1)
			end
			if math.random(1,100) <= 85 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local cd = sgs.Sanguosha:getCard(id)
							if choice == "TrickCard" and cd:isKindOf("TrickCard") then
								DPHeart:append(id)
							end
						end
					end
					if room:getDiscardPile():length() > 0 then
						for _, id in sgs.qlist(room:getDiscardPile()) do
							local cd = sgs.Sanguosha:getCard(id)
							if choice == "TrickCard" and cd:isKindOf("TrickCard") then
								DPHeart:append(id)
							end
						end
					end
					local n = math.random(2,3)
					local getList = sgs.IntList()
					for i = 1,n,1 do
						if DPHeart:length() ~= 0 then
							local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
							getList:append(get_id)
							DPHeart:removeOne(get_id)
						end
					end
					room:obtainCard(player, getList)
				end
			end
		end
	end
}

function getCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

jl_yuhua = sgs.CreateTriggerSkill{
	name = "jl_yuhua",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (use.card:isNDTrick()) then
				room:addPlayerMark(player, "jl_yuhua_usetrick")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if math.random(1,100) <= 85 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local n = math.max(player:getMark("jl_yuhua_usetrick"),4)
						local card_ids = room:getNCards()
						room:fillAG(card_ids)
						local to_get = sgs.IntList()
						local to_throw = sgs.IntList()
						while not card_ids:isEmpty() do
							local card_id = room:askForAG(player, card_ids, false, "shelie")
							card_ids:removeOne(card_id)
							to_get:append(card_id)--弃置剩余所有符合花色的牌(原文：throw the rest cards that matches the same suit)

							room:takeAG(player, card_id, false)
						end
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						if not to_get:isEmpty() then
							dummy:addSubcards(getCardList(to_get))
							player:obtainCard(dummy)
						end
						dummy:clearSubcards()
						if not to_throw:isEmpty() then
							dummy:addSubcards(getCardList(to_throw))
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(),"")
							room:throwCard(dummy, reason, nil)
						end
						dummy:deleteLater()
						room:clearAG()
						return true
					end
				end
			end
		end
	end,
}

jl_zhugeguo:addSkill(jl_qirang)
jl_zhugeguo:addSkill(jl_yuhua)

sgs.LoadTranslationTable{
["jl_zhugeguo"] = "諸葛果",
["#jl_zhugeguo"] = "將靈",
["jl_qirang"] = "祈禳",
[":jl_qirang"] = "當你使用一張裝備牌時或回合內使用第一張基本牌時，你有85%的概率從牌堆或棄牌堆摸兩至三"..
"張錦囊牌（每回合限觸發兩次）",

["jl_yuhua"] = "羽化",
[":jl_yuhua"] = "結束階段，你有85%的概率觀看牌堆頂Y張牌（Y為你本回合使用的錦囊牌且至少為4），然後獲得其中至多三張牌。",
}

--[[
籌策：當你受到傷害後，你有【85%+1%*（當前等級-76）】的概率令一名角色摸兩張牌，然後棄置一名角色至多兩張牌。
先輔：結束階段，你有【80%+1%*（當前等級-76）】的概率可以選擇一名角色，直到你的回合開始，該角色造成或受到傷害後，你回復1點體力並摸兩張牌。 （每回合限觸發一次）。
]]--
jl_xizhicai = sgs.General(extension,"jl_xizhicai","wei","4",true,true, true)

jl_chouce = sgs.CreateTriggerSkill{
	name = "jl_chouce",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if math.random(1,100) <= 85 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:notifySkillInvoked(player,self:objectName())
					local to_draw = room:askForPlayerChosen(player, room:getAlivePlayers(), "chouce1", "@chouce-draw", true)
					if to_draw then
						room:doAnimate(1, player:objectName(), to_draw:objectName())
						room:drawCards(to_draw, 2, "chouce")
					end
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canDiscard(p, "he") then _targets:append(p) end
					end
					if not _targets:isEmpty() then
						local to_discard = room:askForPlayerChosen(player, _targets, "chouce2", "@chouce-discard", true)
						if to_discard then
							room:doAnimate(1, player:objectName(), to_discard:objectName())
							for i = 1,2,1 do
								if player:canDiscard(to_discard, "he") then
									room:throwCard(room:askForCardChosen(player, to_discard, "he", "chouce", false, sgs.Card_MethodDiscard), to_discard, player)
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

jl_xianfu = sgs.CreateTriggerSkill{
	name = "jl_xianfu",
	events = {sgs.EventPhaseStart, sgs.HpRecover, sgs.Damaged},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and RIGHT(self, player) and math.random(1,100) <= 80 then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "jl_xianfu-invoke", false, sgs.GetConfig("face_game", true))
			if to then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--room:addPlayerMark(to, "@xianfu")
					room:addPlayerMark(player, "jl_xianfu"..to:objectName().."_start")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		else
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark("jl_xianfu"..player:objectName().."_start") > 0 and player:isAlive() and p:getMark("jl_xianfu-Clear") == 0 then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:doAnimate(1, player:objectName(), p:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:recover(p, sgs.RecoverStruct(p, nil, data:toRecover().recover))
					p:drawCards(2)
					room:addPlayerMark(p, "jl_xianfu-Clear")
				end
			end
		end
		return false
	end
}

jl_xizhicai:addSkill(jl_xianfu)
jl_xizhicai:addSkill(jl_chouce)

sgs.LoadTranslationTable{
	["jl_xizhicai"] = "戲志才",
	["#jl_xizhicai"] = "將靈",
	["jl_xianfu"] = "先輔",
	[":jl_xianfu"] = "結束階段，你有80%的概率可以選擇一名角色，直到你的回合開始，該角色造成或受到傷害後，你回復1點體力並摸兩張牌。(每回合限觸發一次)", 
	["jl_chouce"] = "籌略",
	[":jl_chouce"] = "當你受到傷害後，你有85%的概率令一名角色摸兩張牌，然後棄置一名角色至多兩張牌。",
	["jl_xianfu-invoke"]="到你的回合開始，該角色造成或受到傷害後，你回復1點體力並摸兩張牌。",
}

--[[
再起：摸牌階段，你有【90%+1%*（當前等級-76）】的概率亮出牌堆頂的牌，如果不是黑桃，你恢復1點體力並獲得此牌。
禍首：傷害類錦囊牌有【75%+1%*（當前等級-76）】的概率對你無效且你摸兩張牌（每回合限觸發兩次）。
]]--
jl_menghuo = sgs.General(extension,"jl_menghuo","shu","4",true,true, true)

jl_zaiqi = sgs.CreateTriggerSkill{
	name = "jl_zaiqi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 90 then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName()) then
					local has_heart = false
					local ids = room:getNCards(1, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local card_to_throw = {}
					local card_to_gotback = {}

						local id = ids:at(0)
						local card = sgs.Sanguosha:getCard(id)
						local suit = card:getSuit()
						if suit == sgs.Card_Spade then
							table.insert(card_to_throw, id)
						else
							table.insert(card_to_gotback, id)
						end

					if #card_to_throw > 0 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_throw) do
							dummy:addSubcard(id)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
						room:throwCard(dummy, reason, nil)
						has_heart = true
					end
					if #card_to_gotback > 0 then
						local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_gotback) do
							dummy2:addSubcard(id)
						end
						room:obtainCard(player, dummy2)

						local recover = sgs.RecoverStruct()
						recover.card = nil
						recover.who = player
						recover.recover = 1
						room:recover(player, recover)
					end
					return true
				end
			end
		end
		return false
	end
}

jl_huoshou = sgs.CreateTriggerSkill{
	name = "jl_huoshou",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			if player:isAlive() and math.random(1,100) <= 75 and player:getMark("jl_huoshou-Clear") < 2 then
				local use = data:toCardUse()
				if canCauseDamage(use.card) and use.card:isNDTrick()  then
					player:setFlags("-ZhenlieTarget")
					player:setFlags("ZhenlieTarget")
					if player:isAlive() and player:hasFlag("ZhenlieTarget") then
						room:notifySkillInvoked(player, self:objectName())
						player:drawCards(2)
						room:addPlayerMark(player,"jl_huoshou-Clear")
						player:setFlags("-ZhenlieTarget")
						local nullified_list = use.nullified_list
						table.insert(nullified_list, player:objectName())
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		end
		return false
	end,
}

jl_menghuo:addSkill(jl_huoshou)
jl_menghuo:addSkill(jl_zaiqi)

sgs.LoadTranslationTable{
["#jl_menghuo"] = "將靈",
["jl_menghuo"] = "孟獲",
["jl_huoshou"] = "禍首",
[":jl_huoshou"] = "傷害類錦囊牌有75%的概率對你無效且你摸兩張牌（每回合限觸發兩次）",
["jl_zaiqi"] = "再起",
[":jl_zaiqi"] = "摸牌階段，你有90%的概率亮出牌堆頂的牌，如果不是黑桃，你恢復1點體力並獲得此牌。",
}

--[[
天香：當你受到傷害時，你有【85%+1%*（當前等級-76）】的概率可以棄置一張手牌，防止此次傷害並選擇一名其他角色，令其失去1點體力，
然後其獲得你棄置的牌。 （每回合限觸發兩次）
紅顏：當你棄置牌時，你有【90%+1%*（當前等級-76）】的概率摸兩張牌（每回合限觸發兩次）
]]--
jl_xiaoqia = sgs.General(extension,"jl_xiaoqia","wu","4",false,true, true)

jl_hongyan = sgs.CreateTriggerSkill{
	name = "jl_hongyan",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and 
			(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == 
				sgs.CardMoveReason_S_REASON_DISCARD) and move.card_ids:length() > 0 and player:getMark("jl_hongyan-Clear") < 2 then
			if math.random(1,100) <= 90 then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player, "jl_hongyan-Clear")
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(2)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}

jl_tianxiangCard = sgs.CreateSkillCard{
	name = "jl_tianxiang",
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local damage = source:getTag("olTianxiangDamage"):toDamage()	--yun
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 and damage.from then
			room:loseHp(targets[1])
			if targets[1]:isAlive() then
				room:obtainCard(targets[1], self)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jl_tianxiangVS = sgs.CreateOneCardViewAsSkill{
	name = "jl_tianxiang",
	view_filter = function(self, selected)
		return not sgs.Self:isJilei(selected)
	end,
	view_as = function(self, card)
		local tianxiangCard = jl_tianxiangCard:clone()
		tianxiangCard:addSubcard(card)
		return tianxiangCard
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jl_tianxiang"
	end
}
jl_tianxiang = sgs.CreateTriggerSkill{
	name = "jl_tianxiang",
	events = {sgs.DamageInflicted},
	view_as_skill = jl_tianxiangVS,
	on_trigger = function(self, event, player, data, room)
		if player:canDiscard(player, "h") and player:getMark("jl_tianxiang-Clear") < 2 and math.random(1,100) <= 85 then
			room:addPlayerMark(player, "jl_tianxiang-Clear")
			player:setTag("olTianxiangDamage", data)	--yun
			return room:askForUseCard(player, "@@jl_tianxiang", "@jl_tianxiang", -1, sgs.Card_MethodDiscard)
		end
		return false
	end
}

sgs.LoadTranslationTable{
	["jl_xiaoqiao"] = "小喬",
	["#jl_xiaoqiao"] = "將靈",

	["jl_hongyan"] = "紅顏",
	[":jl_hongyan"] = "當你棄置牌時，你有90%的概率摸兩張牌（每回合限觸發兩次）",
	["jl_tianxiang"] = "天香",
	[":jl_tianxiang"] = "當你受到傷害時，你有85%的概率可以棄置一張手牌，防止此次傷害並選擇一名其他角色，令其失去1點體力，然後其獲得你棄置的牌。 （每回合限觸發兩次）",
	["@jl_tianxiang"] = "請選擇“天香”的目標",
	["~jl_tianxiang"] = "選擇一張<font color=\"red\">♥</font>牌→選擇一名其他角色→點擊確定",
}

--[[
烈刃：你的【殺】指定目標後，你有【90%+1%*（當前等級-76）】的概率獲得該角色一張牌並摸一張牌。
巨象：其他角色使用的傷害類錦囊牌有【75%+1%*（當前等級-76）】的概率在結算完畢進入棄牌堆時你獲得之並摸一張牌。 （每回合限觸發兩次）
]]--
jl_zhurong = sgs.General(extension,"jl_zhurong","shu","4",false,true, true)

jl_juxiang = sgs.CreateTriggerSkill{
	name = "jl_juxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if canCauseDamage(use.card)  then
				if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then return false end
				if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId())
				   and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("SavageAssault") then
					for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if math.random(1,100) <= 90 then
							room:setCardFlag(use.card:getEffectiveId(), "real_SA")
							room:setPlayerFlag(p, "get_SA")
						end
					end
				end
			end
		elseif player and player:isAlive() and player:hasFlag("get_SA") then
			local move = data:toMoveOneTime()
			if (move.card_ids:length() == 1) and move.from_places:contains(sgs.Player_PlaceTable) and (move.to_place == sgs.Player_DiscardPile)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
				local card = sgs.Sanguosha:getCard(move.card_ids:first())
				if card:hasFlag("real_SA") and (player:objectName() ~= move.from:objectName()) then
					room:setCardFlag(card:getEffectiveId(), "-real_SA")
					room:setPlayerFlag(player, "-get_SA")

					player:obtainCard(card)
					move.card_ids = sgs.IntList()
					data:setValue(move)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

jl_lieren = sgs.CreateTriggerSkill{
	name = "jl_lieren" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				if player:canDiscard(p, "he") then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if math.random(1,100) <= 95 then
						local id = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
						player:obtainCard(sgs.Sanguosha:getCard(id))
						player:drawCards(1)
					end
				end
			end
		end
	end
}

jl_zhurong:addSkill(jl_juxiang)
jl_zhurong:addSkill(jl_lieren)

sgs.LoadTranslationTable{
["#jl_zhurong"] = "將靈",
["jl_zhurong"] = "祝融",
["jl_juxiang"] = "巨象",
[":jl_juxiang"] = "其他角色使用的傷害類錦囊牌有75%的概率在結算完畢進入棄牌堆時你獲得之並摸一張牌。 （每回合限觸發兩次",
["jl_lieren"] = "烈刃",
[":jl_lieren"] = "你的【殺】指定目標後，你有90%的概率獲得該角色一張牌並摸一張牌。",
}

--[[
將靈周妃
良姻
當有牌移出遊戲或從遊戲外加入任意角色的手牌時，你有83%的概率可令一名角色摸一至三張牌（每回合限觸發兩次）。

箜聲
準備階段，你有83%的概率隨機獲得棄牌堆里的四張牌名不同的牌。結束階段若這些牌還在手牌中則棄置。
]]--
jl_zhoufei = sgs.General(extension,"jl_zhoufei","wu","4",false,true, true)

jl_liangyin = sgs.CreateTriggerSkill{
	name = "jl_liangyin",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if not room:getTag("FirstRound"):toBool() then
			if (move.to_place == sgs.Player_PlaceSpecial) or (move.to_place == sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_PlaceSpecial)) and (not room:getTag("FirstRound"):toBool()) then
				if move.to_place == sgs.Player_PlaceSpecial and math.random(1,100) <= 83 and player:getMark("jl_liangyin-Clear") < 2 then
					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "jl_liangyin", "@jl_liangyin-draw", true)
					if s then
						room:addPlayerMark(player,"jl_liangyin-Clear")
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						s:drawCards(math.random(1,3))
					end
				elseif move.to_place == sgs.Player_PlaceHand and math.random(1,100) < 83 and player:getMark("jl_liangyin-Clear") < 2 then
					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "jl_liangyin", "@jl_liangyin-draw", true)
					if s then
						room:addPlayerMark(player,"jl_liangyin-Clear")
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						s:drawCards(math.random(1,3))
					end
				end
			end
		end
	end
}

function TrueName(card)
	if card == nil then return "" end
	if (card:objectName() == "fire_slash" or card:objectName() == "thunder_slash") then return "slash" end
	return card:objectName()
end

jl_kongsheng = sgs.CreateTriggerSkill{
	name = "jl_kongsheng",
	view_as_skill = jl_kongshengVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ==  sgs.Player_Start and math.random(1,100) <= 83 then
			local GetCardList = sgs.IntList()
			local get_pattern = {}
			for i = 1,4,1 do
				local DPHeart = sgs.IntList()
				if room:getDrawPile():length() > 0 then
					for _, id in sgs.qlist(room:getDrawPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if not table.contains(get_pattern, TrueName(card)) then
							DPHeart:append(id)
						end
					end
				end
				if DPHeart:length() ~= 0 then
					local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
					GetCardList:append(get_id)
					room:addPlayerMark(player,"jl_kongsheng"..get_id.."-Clear")

					local card = sgs.Sanguosha:getCard(get_id)
					table.insert(get_pattern, TrueName(card))
				end
			end
			if GetCardList:length() ~= 0 then
				local move = sgs.CardsMoveStruct()
				move.card_ids = GetCardList
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
			end

		elseif phase ==  sgs.Player_Finish then
			local ids = sgs.IntList()
			for _, card in sgs.list(player:getHandcards()) do
				if player:getMark("jl_kongsheng"..card:getId().."-Clear") > 0 then
					ids:append(card:getId())
				end
			end
			if not ids:isEmpty() then
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "jl_kongsheng", nil)
				room:moveCardsAtomic(move, true)
			end
		end
	end
}

jl_zhoufei:addSkill(jl_liangyin)
jl_zhoufei:addSkill(jl_kongsheng)

sgs.LoadTranslationTable{
	["jl_zhoufei"] = "周妃",
	["#jl_zhoufei"] = "將靈",
	["jl_liangyin"] = "良姻",
	[":jl_liangyin"] = "當有牌移出遊戲或從遊戲外加入任意角色的手牌時，你有83%的概率可令一名角色摸一至三張牌（每回合限觸發兩次）。",
	["jl_kongsheng"] = "箜聲",
	[":jl_kongsheng"] = "準備階段，你有83%的概率隨機獲得棄牌堆里的四張牌名不同的牌。結束階段若這些牌還在手牌中則棄置。",
	["@jl_liangyin-draw"] = "你可以令手牌數大於你的一名角色摸一張牌",
}

--[[
呂布（A級）
無雙

利馭

]]--

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
jl_wushuang = sgs.CreateTriggerSkill{
	name = "jl_wushuang" ,
	events = {sgs.TargetSpecified,sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") and math.random(1,100) <= 80 and player:getMark("jl_wushuang-Clear") < 2 then
				room:setPlayerFlag(player,"jl_wushuang_get")
				room:setCardFlag(use.card,"jl_wushuang_card")
				room:addPlayerMark(player,"jl_wushuang-Clear")
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					if p:getHandcardNum() <= player:getHandcardNum() then
						local _data = sgs.QVariant()
						_data:setValue(p)
						--if player:askForSkillInvoke(self:objectName(), _data) then
							jink_table[index] = 0
						--end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:hasFlag("jl_wushuang_get")
			  and use.card:hasFlag("jl_wushuang_card") then
				local id = use.card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable then
					room:obtainCard(player, card, true)
				end
				getpatterncard(player, {"Duel"},false,true)
			end
		end
	end
}

jl_liyu = sgs.CreateTriggerSkill{
	name = "jl_liyu", 
	events = {sgs.Damage}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			local card = damage.card
			if damage.card and damage.to:isAlive() and (not damage.to:isNude()) and math.random(1,100) <= 80 and player:getMark("jl_liyu-Clear") < 3 then
				room:addPlayerMark(player,"jl_liyu-Clear")
				local _data = sgs.QVariant()
				_data:setValue(damage.to)
				if room:askForSkillInvoke(player, "jl_liyu", _data) then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForCardChosen(player, damage.to, "he", "jl_liyu")
					room:obtainCard(player, id, true)
					room:damage(sgs.DamageStruct(nil,player,damage.to,1,sgs.DamageStruct_Normal))
				end	
			end
		end		
		return false
	end
}

sgs.LoadTranslationTable{
["jl_lvbu"] = "呂布",
["#jl_lvbu"] = "將靈",
["jl_wushuang"] = "無雙",
[":jl_wushuang"] = "你使用的【殺】有80%的概率不能被抵消並無視防具，且在結算後將此【殺】收回並獲得棄牌堆中一張【決鬥】。（每回合限觸發兩次）",
["jl_liyu"] = "利馭",
[":jl_liyu"] = "當你使用牌造成傷害後，你有80%的概率獲得目標角色區域里一張牌並對其造成1點傷害。（每回合限觸發3次）",
}

--[[
曹嬰（S級）
凌人
你使用【殺】或傷害類錦囊牌指定目標後，你有75%的概率選擇其中一個目標使此牌對其傷害+1~2然後你摸1~3張牌，並且你獲得"奸雄"、「行殤」直到你下回合開始。（每回合限觸發2次）
伏間
準備階段或結束階段，你有80%的概率可以觀看一名其他角色的手牌，然後你可以獲得其中至多兩張牌，若顏色相同，對其造成1點傷害。
]]--

jl_caoying = sgs.General(extension,"jl_caoying","wei2","4",false,true,true)
--凌人
jl_lingren = sgs.CreateTriggerSkill{
	name = "jl_lingren",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetSpecified,sgs.DamageCaused,sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if canCauseDamage(use.card) and player:getPhase() == sgs.Player_Play and player:getMark("jl_lingren_Play") == 0 then
				if math.random(1,100) <= 75 and player:getMark("jl_liyu-Clear") < 2 then
					room:addPlayerMark(player,"jl_lingren-Clear")
					local s = room:askForPlayerChosen(player,use.to,self:objectName(),"@jl_lingrenask",true,true)
					if s then
						
						room:setCardFlag(use.card, "damageplus_card")
						s:setFlags("Lingzen_plus")
						player:drawCards( math.random(1,3) )
						if not player:hasSkills("jianxiong|jianxiong_po") then
							room:acquireSkill(player, "jianxiong")
							room:setPlayerMark(player,"jl_lingren_jianxiong")
						end
						if not player:hasSkills("xingshang|mobile_xingshang") then
							room:acquireSkill(player, "xingshang")
							room:setPlayerMark(player,"jl_lingren_xingshang")
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then		
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card:hasFlag("damageplus_card") and damage.to:hasFlag("Lingzen_plus") then
				room:setCardFlag(damage.card, "-damageplus_card")
				local n = math.random(1,2)
				damage.damage = damage.damage + n
				local msg = sgs.LogMessage()
				msg.type = "#jl_lingzen"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - n)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)
			end

		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				if player:hasSkill("lingren_jianxiong") and player:getMark("jl_lingren_jianxiong") > 0 then
					room:detachSkillFromPlayer(player, "jl_lingren_jianxiong")
					room:setPlayerMark(player,"jl_lingren_jianxiong",0)
				end
				if player:hasSkill("lingren_xingshang") and player:getMark("jl_lingren_xingshang") > 0 then
					room:detachSkillFromPlayer(player, "jl_lingren_xingshang")
					room:setPlayerMark(player,"jl_lingren_xingshang",0)
				end
			end	
		end
	end,
}

--伏間：鎖定技，結束階段，你隨機觀看一名角色的X張手牌（X為全場手牌數最少的角色手牌數）。
jl_fujian = sgs.CreateTriggerSkill{
	name = "jl_fujian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill(self:objectName()) and (player:getPhase() == sgs.Player_Finish or player:getPhase() == sgs.Player_Start) then
			local all_alive_players = {}
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					table.insert(all_alive_players, p)
				end
			end
			local s = room:askForPlayerChosen(player,all_alive_players,self:objectName(),"@jl_fujianask",true,true)

			local ids = sgs.IntList()
			for _, card in sgs.qlist(s:getCards("h")) do
				ids:append(card:getId())
			end
			room:fillAG(ids,player)
			local is_red = true
			for i = 1, 2 do
				local id = room:askForAG(source, ids, i ~= 1, self:objectName())
				if id == -1 then break end
				ids:removeOne(id)
				player:obtainCard(sgs.Sanguosha:getCard(id))
				room:takeAG(player, id, false)
				if ids:isEmpty() then break end
				if i == 1 then
					if sgs.Sanguosha:getCard(id):isRed() then
						is_red = true
					else
						is_red = false
					end
				elseif i == 2 then
					if sgs.Sanguosha:getCard(id):isRed() == is_red then
						room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))
					end
				end

			end
			room:clearAG()

		end
	end
}

jl_caoying:addSkill(jl_lingren)
jl_caoying:addSkill(jl_fujian)


sgs.LoadTranslationTable{
	["jl_caoying"] = "曹嬰",
	["#jl_caoying"] = "大都督",
	["jl_lingren"] = "凌人",
	[":jl_lingren"] = "你使用【殺】或傷害類錦囊牌指定目標後，你有75%的概率選擇其中一個目標使此牌對其傷害+1~2然後你摸1~3張牌，並且你獲得「奸雄」、「行殤」直到你下回合開始。（每回合限觸發2次）",
	["@jl_lingrenask"]= "選擇其中一個目標發動「凌人」",


	["jl_fujian"] = "伏間",
	[":jl_fujian"] = "準備階段或結束階段，你有80%的概率可以觀看一名其他角色的手牌，然後你可以獲得其中至多兩張牌，若顏色相同，對其造成1點傷害。",
	["#lingzen2"] = "%from 觸發技能 “<font color=\"yellow\"><b>凌人</b></font>”，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--[[
香香
結姻
出牌階段開始時，你有78%的概率令你和一名其他角色回復1點體力並摸1~2張牌。

梟姬
當你失去一張裝備區里的牌時，你有83%的概率摸1~2張牌。（每輪限四次）
]]--

sgs.LoadTranslationTable{
["jl_sunshangxiang"] = "孫尚香",
["#jl_sunshangxiang"] = "將靈",
["jl_jieyin"] = "結姻",
[":jl_jieyin"] = "階段技。你可以棄置兩張手牌並選擇一名已受傷的男性角色：若如此做，你和該角色各回复1點體力。",
["jl_xiaoji"] = "梟姬",
[":jl_xiaoji"] = "每當你失去一張裝備區的裝備牌後，你可以摸兩張牌。",
}


--[[
大喬（A級）
國色：出牌階段開始時，你有83%的概率可摸一張方塊牌並可以將此牌當【樂不思蜀】使用，
且可以棄置場上一張【樂不思蜀】。
流離：成為【殺】的目標後，你有83%的概率可棄置一張牌將此【殺】轉移給你攻擊範圍內的一
名其他角色並摸一張牌（不能是【殺】的使用者，每回合限觸發兩次）。
]]--
jl_daqiao = sgs.General(extension,"jl_daqiao","wu","4",false,true, true)

jl_guose = sgs.CreateTriggerSkill{
	name = "jl_guose" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if math.random(1,100) <= 83 then
				if player:askForSkillInvoke(self:objectName(), data) then
					local point_six_card = sgs.IntList()
					for _,id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
							point_six_card:append(id)
						end
					end
					if not point_six_card:isEmpty() then
						local players = sgs.SPlayerList()

						local card = sgs.Sanguosha:getCard(point_six_card:at(0))
						local suit = card:getSuit()
						local point = card:getNumber()
						local id = card:getId()
						local indulgence = sgs.Sanguosha:cloneCard("indulgence", suit, point)
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if not player:isProhibited(p, indulgence) then
								if not p:isKongcheng() then
									players:append(p)
								end
							end
						end
						if not players:isEmpty() then
							local to = room:askForPlayerChosen(player, players, self:objectName(), "@jl_guose-to", true, false)
							if to then
								local id = card:getEffectiveId()
								indulgence:addSubcard(id)
								indulgence:setSkillName(self:objectName())
								local use = sgs.CardUseStruct()
								use.card = indulgence
								use.from = player
								use.to:append(to)
								room:useCard(use)
							else
								room:obtainCard(player, card, false)
							end
						else
							room:obtainCard(player, card, false)
						end

						--拆的部分
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							for _, card in sgs.qlist(p:getJudgingArea()) do
								if card:isKindOf("Indulgence") then players:append(p) end
							end
						end
						if not players:isEmpty() then
							local to = room:askForPlayerChosen(player, players, self:objectName(), "@jl_guose-dis", true, false)
							if to then
								for _, card in sgs.qlist(to:getJudgingArea()) do
									if card:isKindOf("Indulgence") then
										room:throwCard(card,to,player)
									end
								end

							end
						end
					end
				end
			end
		end
	end
}

jl_liuliCard = sgs.CreateSkillCard{
	name = "jl_liuliCard" ,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if to_select:hasFlag("jl_liuliSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("jl_liuliSlashSource") then
				from = p
				break
			end
		end
		local slash = sgs.Card_Parse(sgs.Self:property("jl_liuli"):toString())
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		local card_id = self:getSubcards():first()
		local range_fix = 0
		if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == card_id) then
			local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif sgs.Self:getOffensiveHorse() and (sgs.Self:getOffensiveHorse():getId() == card_id) then
			range_fix = range_fix + 1
		end
		return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("jl_liuliTarget")
	end
}
jl_liuliVS = sgs.CreateOneCardViewAsSkill{
	name = "jl_liuli" ,
	response_pattern = "@@jl_liuli",
	filter_pattern = ".!",
	view_as = function(self, card)
		local liuli_card = jl_liuliCard:clone()
		liuli_card:addSubcard(card)
		return liuli_card
	end
}
jl_liuli = sgs.CreateTriggerSkill{
	name = "jl_liuli" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = jl_liuliVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash")
				and use.to:contains(player) and player:canDiscard(player,"he") and (room:alivePlayerCount() > 2) then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) then
					can_invoke = true
					break
				end
			end
			if player:getMark("jl_liuli-Clear") >= 2 then
				can_invoke = false
			end
			if can_invoke and math.random(1,100) <= 83 then
				local prompt = "@liuli:" .. use.from:objectName()
				room:setPlayerFlag(use.from, "jl_liuliSlashSource")
				room:setPlayerProperty(player, "jl_liuli", sgs.QVariant(use.card:toString()))
				if room:askForUseCard(player, "@@jl_liuli", prompt, -1, sgs.Card_MethodDiscard) then
					room:setPlayerProperty(player, "jl_liuli", sgs.QVariant())
					room:setPlayerFlag(use.from, "-jl_liuliSlashSource")
					for _, p in sgs.qlist(players) do
						if p:hasFlag("jl_liuliTarget") then
							room:addPlayerMark(player, "jl_liuli-Clear")
							player:drawCards(1)
							p:setFlags("-jl_liuliTarget")
							use.to:removeOne(player)
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:getThread():trigger(sgs.TargetConfirming, room, p, data)
							return false
						end
					end
				else
					room:setPlayerProperty(player, "jl_liuli", sgs.QVariant())
					room:setPlayerFlag(use.from, "-jl_liuliSlashSource")
				end
			end
		end
		return false
	end
}

jl_daqiao:addSkill(jl_guose)
jl_daqiao:addSkill(jl_liuli)

sgs.LoadTranslationTable{
	["jl_daqiao"]="大喬",
	["#jl_daqiao"]="將靈",
	["jl_guose"] = "國色",
	["@jl_guose-to"] = "你可以將此牌當【樂不思蜀】對一名角色使用",
	["@jl_guose-dis"] = "你可以棄置場上一張【樂不思蜀】",
	[":jl_guose"] = "出牌階段開始時，你有83%的概率可摸一張方塊牌並可以將此牌當【樂不思蜀】使用，且可以棄置場上一張【樂不思蜀】。",
	["jl_liuli"] = "流離",
	[":jl_liuli"] = "成為【殺】的目標後，你有83%的概率可棄置一張牌將此【殺】轉移給你攻擊範圍內的一名其他角色並摸一張牌（不能是【殺】的使用者，每回合限觸發兩次）。",
	["~jl_liuli"] = "你可棄置一張牌，將此【殺】轉移給你攻擊範圍內的一名其他角色",
}

--[[
諸葛亮（A級）

火計：出牌階段開始時，你有87%的概率可摸一張牌並可以視為使用一張【火攻】，且你可以獲得此【火攻】你棄置的牌。
看破：其他角色使用的錦囊牌對你生效前，你有77%的概率可令此錦囊對你無效，然後摸一張牌（每回合限觸發兩次）。
]]--
jl_wolong = sgs.General(extension,"jl_wolong","shu","4",true,true, true)

jl_huoji = sgs.CreateTriggerSkill{
	name = "jl_huoji" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if math.random(1,100) <= 87 then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(2)
					local players = sgs.SPlayerList()
					local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if not player:isProhibited(p, fire_attack) then
							if not p:isKongcheng() then
								players:append(p)
							end
						end
					end
					if not players:isEmpty() then
						local to = room:askForPlayerChosen(player, players,  self:objectName(), "@jl_huoji-to", true, false)
						if to then
							fire_attack:setSkillName(self:objectName())
							local use = sgs.CardUseStruct()
							use.card = fire_attack
							use.from = player
							use.to:append(to)
							room:useCard(use)
							player:drawCards(1)
						end
					end
				end
			end
		end
	end
}

jl_kanpo = sgs.CreateTriggerSkill{
	name = "jl_kanpo" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isNDTrick() and player:getMark("jl_kanpo-Clear") < 2 then
					if math.random(1,100) <= 77 then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							player:setFlags("-ZhenlieTarget")
							player:setFlags("ZhenlieTarget")
							if player:isAlive() and player:hasFlag("ZhenlieTarget") then
								player:setFlags("-ZhenlieTarget")
								room:addPlayerMark(player, "jl_kanpo-Clear")
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
		return false
	end
}

jl_wolong:addSkill(jl_huoji)
jl_wolong:addSkill(jl_kanpo)

sgs.LoadTranslationTable{
	["jl_wolong"]="諸葛亮",
	["#jl_wolong"]="將靈",
	["jl_huoji"] = "火計",
	["@jl_huoji-to"] = "你可以視為對一名角色使用「火攻」",
	--[":jl_huoji"] = "出牌階段開始時，你有87%的概率可摸一張牌並可以視為使用一張【火攻】，且你可以獲得此【火攻】你棄置的牌。",
	[":jl_huoji"] = "出牌階段開始時，你有87%的概率可摸一張牌並可以視為使用一張【火攻】，且你可以摸一張牌。",
	["jl_kanpo"] = "看破",
	[":jl_kanpo"] = "其他角色使用的錦囊牌對你生效前，你有77%的概率可令此錦囊對你無效，然後摸一張牌（每回合限觸發兩次）。",
}

--[[
靈雎（S級）
竭緣：當你造成傷害時，有75%概率傷害+1~2；當你受到傷害時，有75%概率傷害-1~2。 （每回合每項限觸發1次）
焚心：一名角色進入瀕死狀態時，你有80%的概率摸3~5張牌並回復1~2點體力。 （每回合限觸發1次）
]]--
jl_lingju = sgs.General(extension,"jl_lingju","qun","4",false,true, true)

jl_jieyuan = sgs.CreateTriggerSkill{
	name = "jl_jieyuan" ,
	events = {sgs.DamageCaused, sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.to and damage.to:isAlive() and player:getMark("jl_jieyuan_add-Clear") == 0 then
				if math.random(1,100) <= 75 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:notifySkillInvoked(player, self:objectName())
						room:addPlayerMark(player, "jl_jieyuan_add-Clear")
						n = math.random(1,2)
						damage.damage = damage.damage + n
						local msg = sgs.LogMessage()
						msg.type = "#JlJieyuanPD"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - n)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and player:getMark("jl_jieyuan_reduce-Clear") == 0 then
				if math.random(1,100) <= 40 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local n = math.random(1,2)

						local msg = sgs.LogMessage()
						msg.type = "#JlJieyuanRD"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage)
						msg.arg2 = tostring(math.max(damage.damage - n),0)
						room:sendLog(msg)	

						room:addPlayerMark(player, "jl_jieyuan_reduce-Clear")
						if damage.damage > n then
							damage.damage = damage.damage - n
							data:setValue(damage)
						else
							return true
						end
					end
				end
			end
		end
		return false
	end
}

jl_fenxin = sgs.CreateTriggerSkill{
	name = "jl_fenxin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EnterDying then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("jl_fenxin-Clear") == 0 then
						if math.random(1,100) <= 80 then
							if room:askForSkillInvoke(p, self:objectName()) then
								room:addPlayerMark(p, "jl_fenxin-Clear")
								p:drawCards(math.random(3,5))
								local theRecover = sgs.RecoverStruct()
								theRecover.recover = 1
								theRecover.who = p
								room:recover(p, theRecover)
							end
						end
					end
				end
		end
	end,
}

jl_lingju:addSkill(jl_jieyuan)
jl_lingju:addSkill(jl_fenxin)

sgs.LoadTranslationTable{
	["jl_lingju"]="靈雎",
	["#jl_lingju"]="將靈",
	["jl_jieyuan"] = "竭緣",
	[":jl_jieyuan"] = "當你造成傷害時，有75%概率傷害+1~2；當你受到傷害時，有40%概率傷害-1~2。 （每回合每項限觸發1次）",
	["#JlJieyuanPD"] = "%from 的技能 “<font color=\"yellow\"><b>竭緣</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
	["#JlJieyuanRD"] = "%from 的技能 “<font color=\"yellow\"><b>竭緣</b></font>”被觸發，對 %to 造成傷害由 %arg 點減少到 %arg2 點",
	["jl_fenxin"] = "焚心",
	[":jl_fenxin"] = "一名角色進入瀕死狀態時，你有80%的概率摸3~5張牌並回復1~2點體力。 （每回合限觸發1次）",
}

--[[
姜維（A級）
挑釁：出牌階段開始時或結束時，你有65%的概率棄置至多兩名其他角色各一張牌。
觀星：準備階段，你有75%的概率觀看牌堆頂五張牌，然後以任意順序放回牌堆頂或牌堆底。
jiangwei
tiaoxin
guanxing
]]--
jl_jiangwei = sgs.General(extension, "jl_jiangwei", "shu", "4",  true, true, true)

jl_tiaoxinCard = sgs.CreateSkillCard{
	name = "jl_tiaoxinCard",
	filter = function(self, targets, to_select, erzhang)
		return #targets < 2
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do 
			room:throwCard(room:askForCardChosen(source,p, "he", "jl_tiaoxin", false, sgs.Card_MethodDiscard), p, source)
		end
	end,
}
jl_tiaoxinVS = sgs.CreateZeroCardViewAsSkill{
	name = "jl_tiaoxin",
	response_pattern = "@@jl_tiaoxin",
	view_as = function()
		return jl_tiaoxinCard:clone()
	end,
}
jl_tiaoxin = sgs.CreateTriggerSkill{
	name = "jl_tiaoxin",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	view_as_skill = jl_tiaoxinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 65 then
				room:askForUseCard(player, "@@jl_tiaoxin", "@jl_tiaoxin-ask",-1)
			end
		end
		return false
	end
}

jl_guanxing = sgs.CreateTriggerSkill{
	name = "jl_guanxing",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if math.random(1,100) <= 75 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local count = 5

					local cards = room:getNCards(count)
					room:askForGuanxing(player,cards)
				end
			end
		end
	end
}

jl_jiangwei:addSkill(jl_tiaoxin)
jl_jiangwei:addSkill(jl_guanxing)

sgs.LoadTranslationTable{
	["jl_jiangwei"]="姜維",
	["#jl_jiangwei"]="將靈",
	["jl_tiaoxin"] = "挑釁",
	[":jl_tiaoxin"] = "出牌階段開始時或結束時，你有65%的概率棄置至多兩名其他角色各一張牌。",
	["@jl_tiaoxin-ask"] = "你可以棄置至多兩名其他角色各一張牌。",
	["~jl_tiaoxin"] = "選擇至多兩名角色 --> 點擊「確定」",
	["jl_guanxing"] = "觀星",
	[":jl_guanxing"] = "準備階段，你有75%的概率觀看牌堆頂五張牌，然後以任意順序放回牌堆頂或牌堆底。",
}

--[[
荀攸（B級）
智愚：當你受到1點傷害後，你有75%的概率可以摸1張牌，傷害來源棄置1張手牌
xunyou
zhiyu
]]--
jl_xunyou = sgs.General(extension, "jl_xunyou", "wei", "4",  true, true, true)

jl_zhiyu = sgs.CreateMasochismSkill{
	name = "jl_zhiyu" ,
	on_damaged = function(self, target, damage)
		if math.random(1,100) <= 75 then
			if target:askForSkillInvoke(self:objectName(), sgs.QVariant():setValue(damage)) then
				target:drawCards(1, self:objectName())
				local room = target:getRoom()
				if damage.from and damage.from:canDiscard(damage.from, "h") then
					room:askForDiscard(damage.from, self:objectName(), 1, 1)
				end
			end
		end
	end
}

jl_xunyou:addSkill(jl_zhiyu)

sgs.LoadTranslationTable{
	["jl_xunyou"]="荀攸",
	["#jl_xunyou"]="將靈",
	["jl_zhiyu"] = "智愚",
	[":jl_zhiyu"] = "當你受到1點傷害後，你有75%的概率可以摸1張牌，傷害來源棄置1張手牌",
}


--郭嘉（A級）
--遺計：當你受到1點傷害後，你有65-85%的概率可以摸3張牌，然後你可以將至多3張手牌交給一至三名其他角色
--天妒：當你的判定牌生效後，你有70-90%的概率獲得此牌並從牌堆額外摸2張牌
jl_guojia = sgs.General(extension, "jl_guojia", "wei", "4",  true, true, true)

jl_tiandu = sgs.CreateTriggerSkill{
	name = "jl_tiandu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
		if not player:isAlive() then return end
		if math.random(1,100) <= 75 then
			if room:askForSkillInvoke(player, self:objectName()) then
				player:drawCards((x*3))
				room:notifySkillInvoked(player,"jl_tiandu")
				--原本的手牌數
				local n1 = player:getHandcardNum()
				--可以遺計給出去的牌數
				local n2 = x*3
				while room:askForYiji(player, getIntList(player:getCards("h")), self:objectName(), true, false, true, n2, room:getAlivePlayers()) do
					local n3 = player:getHandcardNum()
					n2 = (n2 - (n1 - n3))
					n1 = player:getHandcardNum()
				end
			end
		end
		return false
	end
}
jl_guojia:addSkill(jl_tiandu)

jl_yiji = sgs.CreateTriggerSkill{
	name = "jl_yiji" ,
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if math.random(1,100) <= 80 then
			local judge = data:toJudge()
			local card = judge.card
			local card_data = sgs.QVariant()
			card_data:setValue(card)
			if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and 
			  player:askForSkillInvoke(self:objectName(), card_data) then
				player:obtainCard(card)
				player:drawCards(2)
			end
		end
	end
}


jl_guojia:addSkill(jl_yiji)

sgs.LoadTranslationTable{
	["jl_guojia"] = "郭嘉",
	["#jl_guojia"] = "將靈",
	["jl_tiandu"] = "遺計",
	[":jl_tiandu"] = "當你受到1點傷害後，你有75%的概率可以摸3張牌，然後你可以將至多3張手牌交給一至三名其他角色",
	["jl_yiji"] = "天妒",
	[":jl_yiji"] = "當你的判定牌生效後，你有80%的概率獲得此牌並從牌堆額外摸2張牌",
}
--陸遜（A級）
--連營：當你失去最後手牌後，你有70-90%的概率可以令至多X名角色各摸1張牌和1-2張【殺】（X為你失去的手牌數）
--謙遜：當你成為其他角色使用的錦囊牌和【殺】的目標後，你有60-80%的概率可以摸2張牌
jl_luxun = sgs.General(extension, "jl_luxun", "wu", "4",  true, true, true)

jl_qianxunCard = sgs.CreateSkillCard{
	name = "jl_qianxunCard",
	filter = function(self, targets, to_select, erzhang)
		return #targets < sgs.Self:getMark("lianying")
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			local point_six_card = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
					point_six_card:append(id)
				end
			end
			if not point_six_card:isEmpty() then
					room:obtainCard(p, point_six_card:at(0), false)
			end
			p:drawCards(1)
		end
	end
}
jl_qianxunVS = sgs.CreateZeroCardViewAsSkill{
	name = "jl_qianxun",
	response_pattern = "@@jl_qianxun",
	view_as = function()
		return jl_qianxunCard:clone()
	end
}
jl_qianxun = sgs.CreateTriggerSkill{
	name = "jl_qianxun",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = jl_qianxunVS,
	on_trigger = function(self, event, luxun, data)
		local room = luxun:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == luxun:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard  then
			luxun:setTag("LianyingMoveData", data)
			local count = 0
			for i = 0, move.from_places:length() - 1, 1 do
				if move.from_places:at(i) == sgs.Player_PlaceHand then
					count = count + 1
				end
			end
			room:setPlayerMark(luxun, "lianying", count)
			if math.random(1,100) <= 80 then
				room:askForUseCard(luxun, "@@jl_qianxun", "@lianying-card:::" .. tostring(count),-1)
			end
		end
		return false
	end
}

jl_luxun:addSkill(jl_qianxun)

jl_lianying = sgs.CreateTriggerSkill{
	name = "jl_lianying" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if math.random(1,100) <= 70 then
						if room:askForSkillInvoke(player, self:objectName(), data) then
								player:drawCards(2)
						end
					end
				end
			end
		end
		return false
	end
}

jl_luxun:addSkill(jl_lianying)

sgs.LoadTranslationTable{
	["jl_luxun"] = "陸遜",
	["#jl_luxun"] = "將靈",
	["jl_qianxun"] = "連營",
	[":jl_qianxun"] = "當你失去最後手牌後，你有80%的概率可以令至多X名角色各摸1張牌和1-2張【殺】（X為你失去的手牌數）",
	["jl_lianying"] = "謙遜",
	[":jl_lianying"] = "當你成為其他角色使用的錦囊牌和【殺】的目標後，你有60-80%的概率可以摸2張牌",
}

--關羽（A級）
--武聖：出牌階段，你的【殺】造成傷害時，有70-90%的概率傷害+1或2點。
--義絕：出牌階段開始時，你有55-75%的概率下一張【殺】無距離限制且不計次數，並無視目標角色的防具以及其非鎖定技失效直到回合結束
jl_guanyu = sgs.General(extension, "jl_guanyu", "shu", "4",  true, true, true)

jl_wusheng = sgs.CreateTriggerSkill{
	name = "jl_wusheng",
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
				if math.random(1,100) <= 80 then
					local _data = sgs.QVariant()
					_data:setValue(damage.to)
					if room:askForSkillInvoke(player, self:objectName(),_data) then
						room:notifySkillInvoked(player, self:objectName())
						local n = math.random(1,2)
						damage.damage = damage.damage + n
						local msg = sgs.LogMessage()
						msg.type = "#jl_wusheng"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage-n)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)
						data:setValue(damage)
					end
				end
			end
		end
	end
}
jl_guanyu:addSkill(jl_wusheng)

jl_yijue = sgs.CreateTriggerSkill{
	name = "jl_yijue" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 60 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:setPlayerFlag(player,"jl_yijue")
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						room:addPlayerMark(p, "Armor_Nullified")
						room:addPlayerMark(p, "@skill_invalidity")
						room:addPlayerMark(p, "skill_invalidity-Clear")
					end
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("jl_yijue") then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
	end
}

jl_yijuetm = sgs.CreateTargetModSkill{
	name = "#jl_yijuetm",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("jl_yijue") and player:hasFlag("jl_yijue") then
			return 1
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill("jl_yijue") and player:hasFlag("jl_yijue") then
			return 1000
		end
	end,
}
jl_guanyu:addSkill(jl_yijue)
jl_guanyu:addSkill(jl_yijuetm)

sgs.LoadTranslationTable{
	["jl_guanyu"] = "關羽",
	["#jl_guanyu"] = "將靈",
	["jl_wusheng"] = "武聖",
	[":jl_wusheng"] = "出牌階段，你的【殺】造成傷害時，有80%的概率傷害+1或2點。 ",
	["#jl_wusheng"] = "%from 發動了將靈技能“<font color=\"yellow\"><b>武聖</b></font>”，對 %to 造成傷害由 %arg 點增加到"..
" %arg2 點",
	["jl_yijue"] = "義絕",
	[":jl_yijue"] = "出牌階段開始時，你有55-75%的概率下一張【殺】無距離限制且不計次數，並無視目標角色的防具以及其非鎖定技失效直到回合結束",
}

--貂蟬（A級）
--閉月：結束階段，你有80-95%的概率摸2~3張牌
--離間：出牌階段開始時，你有45-65%的概率可以選擇一名男性角色失去2點體力
jl_diaochan = sgs.General(extension, "jl_diaochan", "qun", "4",  false, true, true)
 
jl_biyue = sgs.CreatePhaseChangeSkill{
	name = "jl_biyue",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if math.random(1,100) <= 88 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:notifySkillInvoked(player, self:objectName())
					player:drawCards(math.random(2,3), self:objectName())
				end
			end
		end
		return false
	end
}

jl_lijian = sgs.CreateTriggerSkill{
	name = "jl_lijian" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 55 then
				if player:askForSkillInvoke(self:objectName(), data) then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isMale() then
							_targets:append(p) 
						end
					end
					if not _targets:isEmpty() then
						local s = room:askForPlayerChosen(player, _targets, "jl_lijian", "@jl_lijian-ask", true)
						if s then
							room:doAnimate(1, player:objectName(), s:objectName())
							room:loseHp(s,2)
						end
					end
				end
			end
		end
	end
}

jl_diaochan:addSkill(jl_biyue)
jl_diaochan:addSkill(jl_lijian)

sgs.LoadTranslationTable{
	["jl_diaochan"] = "貂蟬",
	["#jl_diaochan"] = "將靈",
	["jl_biyue"] = "閉月",
	[":jl_biyue"] = "結束階段，你有88%的概率摸2~3張牌",
	["jl_lijian"] = "離間",
	[":jl_lijian"] = "出牌階段開始時，你有55%的概率可以選擇一名男性角色失去2點體力",
	["@jl_lijian-ask"] = "你可以選擇一名男性角色失去2點體力",
}
--華雄（B級）
--耀武：當你受到【殺】或【決鬥】造成的傷害時，你有70-90%的概率從摸2張牌。
jl_huaxiong = sgs.General(extension, "jl_huaxiong", "qun", "4",  true, true, true)

jl_yaowu = sgs.CreateTriggerSkill{
	name = "jl_yaowu" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
			if math.random(1,100) <= 80 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					player:drawCards(2)
				end
			end
						
		end
	end
}
jl_huaxiong:addSkill(jl_yaowu)

sgs.LoadTranslationTable{
	["jl_huaxiong"] = "華雄",
	["#jl_huaxiong"] = "將靈",
	["jl_yaowu"] = "耀武",
	[":jl_yaowu"] = "當你受到【殺】或【決鬥】造成的傷害時，你有8%的概率從摸2張牌",
}
--袁紹（B級）
--血裔：出牌階段開始時，你有60-80%的概率本回合手牌上限+3，並可以額外使用一張【殺】。
jl_yuanshao = sgs.General(extension, "jl_yuanshao", "qun", "4",  true, true, true)

jl_xueyi = sgs.CreateTriggerSkill{
	name = "jl_xueyi" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 70 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:setPlayerMark(player,"jl_xueyi-Clear",1)
				end
			end
		end
	end
}
jl_yuanshao:addSkill(jl_xueyi)

jl_xueyitm = sgs.CreateTargetModSkill{
	name = "#jl_xueyitm",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("jl_xueyi") and player:getMark("jl_xueyi-Clear") > 0 then
			return 1
		end
	end,
}
jl_xueyimc = sgs.CreateMaxCardsSkill{
	name = "#jl_xueyimc", 
	extra_func = function(self, target)
		if target:hasSkill("jl_xueyi") and target:getMark("jl_xueyi-Clear") > 0  then
			return 3
		end
	end
}

jl_yuanshao:addSkill(jl_xueyitm)
jl_yuanshao:addSkill(jl_xueyimc)

sgs.LoadTranslationTable{
	["jl_yuanshao"] = "袁紹",
	["#jl_yuanshao"] = "將靈",
	["jl_xueyi"] = "血裔",
	[":jl_xueyi"] = "出牌階段開始時，你有60-80%的概率本回合手牌上限+3，並可以額外使用一張【殺】。",
}
--郭皇后（B級）
--矯詔：出牌階段開始時，你有70-95%的概率隨機獲得牌堆中一張錦囊牌。
jl_guohuanghou = sgs.General(extension, "jl_guohuanghou", "wei", "4",  true, true, true)

jl_jiaozhao = sgs.CreateTriggerSkill{
	name = "jl_jiaozhao" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			local point_six_card = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
					point_six_card:append(id)
				end
			end
			if not point_six_card:isEmpty() then
				if math.random(1,100) <= 83 then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:notifySkillInvoked(player, self:objectName())
						room:obtainCard(player, point_six_card:at(math.random(1,point_six_card:length())-1), false)
					end
				end
			end
		end
	end
}
jl_guohuanghou:addSkill(jl_jiaozhao)

sgs.LoadTranslationTable{
	["jl_guohuanghou"] = "郭皇后",
	["#jl_guohuanghou"] = "將靈",
	["jl_jiaozhao"] = "矯詔",
	[":jl_jiaozhao"] = "出牌階段開始時，你有83%的概率獲得牌堆中一張錦囊牌。",
}
--曹叡（B級）
--恢拓：當你受到傷害後，你有20-40%的概率摸1張牌並回復1點體力。
jl_caorui = sgs.General(extension, "jl_caorui", "wei", "4",  true, true, true)

jl_huituo = sgs.CreateTriggerSkill{
	name = "jl_huituo" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if math.random(1,100) <= 30 then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:notifySkillInvoked(player, self:objectName())
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = 1
				theRecover.who = player
				room:recover(player, theRecover)
				player:drawCards(1)
			end		
		end
	end
}
jl_caorui:addSkill(jl_huituo)

sgs.LoadTranslationTable{
	["jl_caorui"] = "曹叡",
	["#jl_caorui"] = "將靈",
	["jl_huituo"] = "恢拓",
	[":jl_huituo"] = "當你受到傷害後，你有30%的概率摸1張牌並回復1點體力。",
}
--孫登（B級）
--匡弼：回合開始時，你有60-80%的概率獲得棄牌堆中的1-3張牌。
jl_sundeng = sgs.General(extension, "jl_sundeng", "wu", "4",  true, true, true)

jl_kuangbi = sgs.CreateTriggerSkill{
	name = "jl_kuangbi" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if math.random(1,100) <= 70 then
				local ids = room:getDiscardPile()
				local getcard_ids = sgs.IntList()
				
				if ids:length() > 0 then
					if player:askForSkillInvoke(self:objectName(), data) then
						local n = math.random(1,3)
						for i=1,n,1 do
							if ids:length() > 0 then
								local get_id = ids:at(math.random(1,ids:length())-1)
								ids:removeOne(get_id)
								getcard_ids:append(get_id)
							end
						end

						room:notifySkillInvoked(player, self:objectName())
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
}
jl_sundeng:addSkill(jl_kuangbi)

sgs.LoadTranslationTable{
	["jl_sundeng"] = "孫登",
	["#jl_sundeng"] = "將靈",
	["jl_kuangbi"] = "匡弼",
	[":jl_kuangbi"] = "回合開始時，你有70%的概率獲得棄牌堆中的1-3張牌。",
}

--關銀屏（B級）
--雪恨：當你使用紅色牌造成傷害時，你有75-95%的概率使得傷害+1並摸一張牌（每回合限觸發一次）。
jl_guanyinping = sgs.General(extension, "jl_guanyinping", "shu", "4",  true, true, true)

jl_xueji = sgs.CreateTriggerSkill{
	name = "jl_xueji",
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isRed() and player:getMark("jl_xueji-Clear") == 0 then
				if math.random(1,100) <= 85 then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:addPlayerMark(player, "jl_xueji-Clear")
						room:notifySkillInvoked(player, self:objectName())
						damage.damage = damage.damage + 1
						local msg = sgs.LogMessage()
						msg.type = "#JlXuejiPD"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
						data:setValue(damage)
						player:drawCards(1)
					end
				end
			end
		end
	end
}
jl_guanyinping:addSkill(jl_xueji)

sgs.LoadTranslationTable{
	["jl_guanyinping"] = "關銀屏",
	["#jl_guanyinping"] = "將靈",
	["jl_xueji"] = "雪恨",
	[":jl_xueji"] = "當你使用紅色牌造成傷害時，你有85%的概率使得傷害+1並摸一張牌（每回合限觸發一次）。",
	["#JlXuejiPD"] = "%from 的技能 “<font color=\"yellow\"><b>雪恨</b></font>”被觸發，"..
	"對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--蹋頓（C級）
--亂戰：當你使用【殺】或黑色錦囊牌指定目標後，你有20-30%的概率可以多選擇至多兩個目標。
jl_tadun = sgs.General(extension, "jl_tadun", "qun", "4",  true, true, true)

jl_luanzhanCard = sgs.CreateSkillCard{
	name = "jl_luanzhan",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("jl_luanzhan_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "jl_luanzhan_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets < 2 and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets < 2 and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _, p in pairs(targets) do
				room:addPlayerMark(p, self:objectName())
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
jl_luanzhanVS = sgs.CreateZeroCardViewAsSkill{
	name = "jl_luanzhan",
	response_pattern = "@@jl_luanzhan",
	view_as = function()
		return jl_luanzhanCard:clone()
	end
}
jl_luanzhan = sgs.CreateTriggerSkill{
	name = "jl_luanzhan",
	events = {sgs.PreCardUsed},
	view_as_skill = jl_luanzhanVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.card:isBlack() and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification"))) then
				if math.random(1,100) <= 25 then
					for _, p in sgs.qlist(use.to) do
						room:addPlayerMark(p, self:objectName())
					end
					if use.card:isVirtualCard() then
						room:setPlayerMark(player, "jl_luanzhan_virtual_card", 1)
						room:setPlayerMark(player, "jl_luanzhan_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
						room:askForUseCard(player, "@@jl_luanzhan", "@jl_luanzhan")
						room:setPlayerMark(player, "jl_luanzhan_virtual_card", 0)
						room:setPlayerMark(player, "jl_luanzhan_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
					elseif not use.card:isVirtualCard() then
						room:setPlayerMark(player, "jl_luanzhan_not_virtual_card", 1)
						room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
						room:askForUseCard(player, "@@jl_luanzhan", "@jl_luanzhan")
						room:setPlayerMark(player, "jl_luanzhan_not_virtual_card", 0)
						room:setPlayerMark(player, "card_id", 0)
					end
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:getMark(self:objectName()) > 0 and not room:isProhibited(player, p, use.card) then
							room:removePlayerMark(p, self:objectName())
							if not use.to:contains(p) then
								use.to:append(p)
							end
						end
					end
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
			elseif use.from:objectName() == player:objectName() and use.card:isKindOf("Collateral") and use.card:isBlack() then
				if math.random(1,100) <= 25 then
					local targets = sgs.SPlayerList()
					for i = 1, 2 do
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if use.to:contains(p) or room:isProhibited(player, p, use.card) then continue end
							if use.card:targetFilter(sgs.PlayerList(), p, player) then
								targets:append(p)
							end
						end
						if targets:isEmpty() then return false end
						local tos = {}
						for _, t in sgs.qlist(use.to) do
							table.insert(tos, t:objectName())
						end
						room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
						room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
						local used = room:askForUseCard(player, "@@ExtraCollateral", "@qiaoshui-add:::collateral")
						room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(""))
						room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant("+"))
						if not used then return false end
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							for _, p in sgs.qlist(room:getOtherPlayers(player)) do
								if p:hasFlag("ExtraCollateralTarget") then
									p:setFlags("-ExtraColllateralTarget")
									extra = p
									break
								end
							end
							if extra == nil then return false end
							use.to:append(extra)
							room:sortByActionOrder(use.to)
							data:setValue(use)
							room:removePlayerMark(player, self:objectName().."engine")
						else
							return false
						end
					end
				end
			end
		end
	end,
}



jl_luanzhantm = sgs.CreateTargetModSkill{
	name = "#jl_luanzhantm" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("jl_luanzhantm")) then
			return 1000
		end
		return 0
	end
}

jl_tadun:addSkill(jl_luanzhan)
jl_tadun:addSkill(jl_luanzhantm)

sgs.LoadTranslationTable{
	["jl_tadun"] = "蹋頓",
	["#jl_tadun"] = "將靈",
	["jl_jl_luanzhan"] = "亂戰",
	[":jl_jl_luanzhan"] = "當你使用【殺】或黑色錦囊牌指定目標後，你有25%的概率可以多選擇至多兩個目標。",
	["~jl_jl_luanzhan"] = "選擇至多兩名角色 --> 點擊「確定」",
	["@jl_jl_luanzhan"] = "你使用 %arc 可以多選擇至多兩個目標。",
}

--郭淮（C級）
--精策：結束階段，若你的手牌數小於體力值，你有40-55%的概率摸兩張牌。
jl_guohuai = sgs.General(extension, "jl_guohuai", "wei", "4",  true, true, true)

jl_jingce = sgs.CreateTriggerSkill{
	name = "jl_jingce" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:getHandcardNum() < player:getHp() then
			if math.random(1,100) <= 48 then
				if player:askForSkillInvoke(self:objectName(), data) then
					player:drawCards(2)
				end
			end
		end
	end
}

jl_guohuai:addSkill(jl_jingce)

sgs.LoadTranslationTable{
	["jl_guohuai"] = "郭淮",
	["#jl_guohuai"] = "將靈",
	["jl_jingce"] = "精策",
	[":jl_jingce"] = "結束階段，若你的手牌數小於體力值，你有48%的概率摸兩張牌",
}
--孫魯班（C級）
--驕矜：當你受到其他角色造成的傷害時，你有20-30%的概率傷害-1。
	
jl_sunluban = sgs.General(extension, "jl_sunluban", "wu", "4",  false, true, true)

jl_jiaojin = sgs.CreateTriggerSkill{
	name = "jl_jiaojin" ,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if math.random(1,100) <= 25 then
				if player:askForSkillInvoke(self:objectName(), data) then
					local msg = sgs.LogMessage()
					msg.type = "#JlJiaojin"
					msg.from = player
					msg.to:append(damage.from)
					msg.arg = tostring(damage.damage)
					msg.arg2 = tostring(damage.damage-1)
					room:sendLog(msg)
					if damage.damage > 1 then
						damage.damage = damage.damage - 1
						data:setValue(damage)
					else
						return true
					end
					
				end
			end
		end
	end,
}

jl_sunluban:addSkill(jl_jiaojin)

sgs.LoadTranslationTable{
	["jl_sunluban"] = "孫魯班",
	["#jl_sunluban"] = "將靈",
	["jl_jiaojin"] = "驕矜",
	[":jl_jiaojin"] = "當你受到其他角色造成的傷害時，你有25%的概率傷害-1。",
	["#JlJiaojin"] = "%from 的技能 “<font color=\"yellow\"><b>驕矜</b></font>”被觸發，對 %to 造成傷害由 %arg 點減少到 %arg2 點",

}
--徐盛（C級）
--破軍：你使用【殺】指定目標後，有30-50%的概率棄置其兩張牌。
jl_xusheng = sgs.General(extension, "jl_xusheng", "wu", "4",  true, true, true)

jl_pojun = sgs.CreateTriggerSkill{
	name = "jl_pojun", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data) 
		if event == sgs.TargetSpecified then
			local room = player:getRoom()
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				if math.random(1,100) <= 40 then
					local _data = sgs.QVariant()
					_data:setValue(p)
					if player:askForSkillInvoke(self:objectName(), _data) then
						for i = 1,2,1 do
							if not p:isNude() then
								local id2 = room:askForCardChosen(player, p, "he", "str_luechung") 
								room:throwCard(id2, p, player)
								room:getThread():delay(100)
							end
						end
					end
				end
			end
		end
		return false
	end,
}

jl_xusheng:addSkill(jl_pojun)

sgs.LoadTranslationTable{
	["jl_xusheng"] = "徐盛",
	["#jl_xusheng"] = "將靈",
	["jl_pojun"] = "破軍",
	[":jl_pojun"] = "你使用【殺】指定目標後，有40%的概率棄置其兩張牌。",
}
--馬忠（C級）
--撫蠻：出牌階段開始時，你有45-55%的概率獲得牌堆中的一張【殺】，並在此階段可額外使用一張【殺】。
jl_mazhong = sgs.General(extension, "jl_mazhong", "shu", "4",  true, true, true)

jl_fuman = sgs.CreateTriggerSkill{
	name = "jl_fuman" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 50 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:setPlayerFlag(player,"jl_fuman")
					local point_six_card = sgs.IntList()
					for _,id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
							point_six_card:append(id)
						end
					end
					if not point_six_card:isEmpty() then
						room:obtainCard(player, point_six_card:at(0), false)
					end
				end
			end
		end
	end
}
jl_mazhong:addSkill(jl_fuman)

jl_fumantm = sgs.CreateTargetModSkill{
	name = "#jl_fumantm",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("jl_fuman") and player:hasFlag("jl_fuman") then
			return 1
		end
	end,
}
jl_mazhong:addSkill(jl_fumantm)

sgs.LoadTranslationTable{
	["jl_mazhong"] = "馬忠",
	["#jl_mazhong"] = "將靈",
	["jl_fuman"] = "撫蠻",
	[":jl_fuman"] = "出牌階段開始時，你有45-55%的概率獲得牌堆中的一張【殺】，並在此階段可額外使用一張【殺】。",
}
--張嶷（C級）
--矢志：出牌階段開始時，你有40-60%的概率本階段出【殺】次數+2。
jl_zhangyi = sgs.General(extension, "jl_zhangyi", "shu", "4",  true, true, true)

jl_shizhi = sgs.CreateTriggerSkill{
	name = "jl_shizhi" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			if math.random(1,100) <= 50 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					room:setPlayerMark(player,"jl_shizhi-Clear",1)
				end
			end
		end
	end
}
jl_zhangyi:addSkill(jl_shizhi)

jl_shizhitm = sgs.CreateTargetModSkill{
	name = "#jl_shizhitm",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("jl_shizhi") and player:getMark("jl_shizhi-Clear") > 0 then
			return 2
		end
	end,
}
jl_zhangyi:addSkill(jl_shizhitm)

sgs.LoadTranslationTable{
	["jl_zhangyi"] = "張嶷",
	["#jl_zhangyi"] = "將靈",
	["jl_shizhi"] = "矢志",
	[":jl_shizhi"] = "出牌階段開始時，你有40-60%的概率本階段出【殺】次數+2。",
}
--張梁（D級）
--集軍：當你使用一張裝備牌時，你有30%~50%的概率摸一張牌（每回合限觸發一次）。
jl_zhangliang = sgs.General(extension, "jl_zhangliang", "qun", "4",  true, true, true)

jl_jijun = sgs.CreateTriggerSkill{
	name = "jl_jijun",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and use.card:isKindOf("EquipCard") and player:getMark("jl_jijun-Clear") == 0 then
				if math.random(1,100) <= 40 then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:addPlayerMark(player, "jl_jijun-Clear")
						room:notifySkillInvoked(player, self:objectName())
						player:drawCards(1)
					end
				end
			end
		end
	end
}
jl_zhangliang:addSkill(jl_jijun)

sgs.LoadTranslationTable{
	["jl_zhangliang"] = "張梁",
	["#jl_zhangliang"] = "將靈",
	["jl_jijun"] = "集軍",
	[":jl_jijun"] = "當你使用一張裝備牌時，你有30%~50%的概率摸一張牌（每回合限觸發一次）。",
}

--文聘（D級）
--鎮衛：每回合結束時，若你本回合受到過傷害，你有10~30%的概率獲得牌堆中一張紅色牌。
jl_wenpin = sgs.General(extension, "jl_wenpin", "wei", "4",  true, true, true)

jl_zhenwei = sgs.CreateTriggerSkill{
	name = "jl_zhenwei",
	events = {sgs.EventPhaseStart,sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:hasFlag("jl_zhenwei") then
				local point_six_card = sgs.IntList()
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isRed() then
						point_six_card:append(id)
					end
				end
				if not point_six_card:isEmpty() then
					if math.random(1,100) <= 20 then
						if player:askForSkillInvoke(self:objectName(), data) then
							room:notifySkillInvoked(player, self:objectName())
							room:obtainCard(player, point_six_card:at(0), false)
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			room:setPlayerFlag(player,"jl_zhenwei")	
		end	
	end
}
jl_wenpin:addSkill(jl_zhenwei)

sgs.LoadTranslationTable{
	["jl_wenpin"] = "文聘",
	["#jl_wenpin"] = "將靈",
	["jl_zhenwei"] = "鎮衛",
	[":jl_zhenwei"] = "每回合結束時，若你本回合受到過傷害，你有10~30%的概率獲得牌堆中一張紅色牌。",
}
--祖茂（D級）
--絕地：準備階段，你有10~30%的概率回復1點體力。
jl_zumao = sgs.General(extension, "jl_zumao", "wu", "4",  true, true, true)

jl_juedi = sgs.CreateTriggerSkill{
	name = "jl_juedi",
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and player:isWounded() then
			if math.random(1,100) <= 20 then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:notifySkillInvoked(player, self:objectName())
					local theRecover = sgs.RecoverStruct()
					theRecover.recover = 1
					theRecover.who = player
					room:recover(player, theRecover)
				end
			end
		end
	end
}
jl_zumao:addSkill(jl_juedi)

sgs.LoadTranslationTable{
	["jl_zumao"] = "祖茂",
	["#jl_zumao"] = "將靈",
	["jl_juedi"] = "絕地",
	[":jl_juedi"] = "準備階段，你有20%的概率回復1點體力。",
}

--[[
變更武將函數
]]--
function choosenewgeneral(source, n, kingdom, banned_list, controler)
	local room = source:getRoom()
	local Chosens = {}
	local generals
	if kingdom then
		if banned_list then
			generals = generate_all_general_list(source, kingdom, banned_list)
		else
			generals = generate_all_general_list(source, kingdom, {})
		end
	else
		if banned_list then
			generals = generate_all_general_list(source, false, banned_list)
		else
			generals = generate_all_general_list(source, false, {})
		end
	end
	for i = 1, n, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end
	local general
	if controler then
		general = room:askForGeneral(controler, table.concat(Chosens, "+"))
	else
		general = room:askForGeneral(source, table.concat(Chosens, "+"))
	end
	room:changeHero(source, general, false,false, false,false)
	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end

--雙將版本
function choosenewgeneral_heg(source, n, kingdom, banned_list, controler)
	local room = source:getRoom()
	local Chosens = {}
	local generals
	if kingdom then
		if banned_list then
			generals = generate_all_general_list(source, kingdom, banned_list)
		else
			generals = generate_all_general_list(source, kingdom, {})
		end
	else
		if banned_list then
			generals = generate_all_general_list(source, false, banned_list)
		else
			generals = generate_all_general_list(source, false, {})
		end
	end
	for i = 1, n, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end

	local general
	if controler then
		general = room:askForGeneral(controler, table.concat(Chosens, "+"))
	else
		general = room:askForGeneral(source, table.concat(Chosens, "+"))
	end
	room:changeHero(source, general, false,false, false,false)

	table.removeOne(Chosens, general)
	local general2
	if controler then
		general2 = room:askForGeneral(controler, table.concat(Chosens, "+"))
	else
		general2 = room:askForGeneral(source, table.concat(Chosens, "+"))
	end
	room:changeHero(source, general2, false,false, true,false)

	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end

--選擇將靈
function choosejiangling(source , n)
	local room = source:getRoom()
	local Chosens = {}
		
	local generals = {"jl_shenzhouyu","jl_nianshou","jl_shenzhaoyun","jl_daqiao",
							"jl_wolong",
						"jl_lingju","jl_jiangwei","jl_xunyou","jl_guojia","jl_luxun","jl_guanyu",
						"jl_diaochan","jl_huaxiong","jl_yuanshao","jl_guohuanghou","jl_caorui",
						"jl_sundeng","jl_guanyinping","jl_tadun","jl_guohuai","jl_sunluban",
						"jl_xusheng","jl_mazhong","jl_zhangyi","jl_zhangliang","jl_wenpin",
						"jl_zumao"}
	for i = 1, n, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end
	local choice = room:askForGeneral(source, table.concat(Chosens, "+"))
	local general = sgs.Sanguosha:getGeneral(choice)		
	for _,sk in sgs.qlist(general:getVisibleSkillList()) do
		room:acquireSkill(source,sk)
	end
end


--------------------------------------------------------------------------------
-------------------------------------鬥地主（手殺）----------------------------------
--------------------------------------------------------------------------------
--飛揚
nl_faiyang = sgs.CreateTriggerSkill{
	name = "nl_faiyang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				room:sendCompulsoryTriggerLog(player, "nl_faiyang") 
				player:drawCards(1)
			end
		end
	end
}
nl_faiyangtm = sgs.CreateTargetModSkill{
	name = "#nl_faiyangtm",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(nl_faiyang) then
			return 1
		end
	end,
}
--跋扈
hasDelayedTrickXiuluo = function(target)
	for _, card in sgs.qlist(target:getJudgingArea()) do
		if not card:isKindOf("SkillCard") then return true end
	end
	return false
end


nl_bahu = sgs.CreateTriggerSkill{
	name = "nl_bahu" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		while hasDelayedTrickXiuluo(player) and player:canDiscard(player, "h") do
			if room:askForSkillInvoke(player, "nl_bahu", data) then
				room:askForDiscard(player, "nl_bahu", 2, 2, false, true)
				local avail_list = sgs.IntList()
				local other_list = sgs.IntList()
				for _, jcard in sgs.qlist(player:getJudgingArea()) do
					if jcard:isKindOf("SkillCard") then
					else
						avail_list:append(jcard:getEffectiveId())
					end
				end
				local all_list = sgs.IntList()
				for _, l in sgs.qlist(avail_list) do
					all_list:append(l)
				end
				room:fillAG(all_list, nil, other_list)
				local id = room:askForAG(player, avail_list, false, self:objectName())
				room:clearAG()
				room:throwCard(id, nil)
				room:broadcastSkillInvoke(self:objectName())
			else
				return false
			end
		end
		return false
	end ,
	can_trigger = function(self, target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and target:canDiscard(target, "he")
				and target:getHandcardNum() + target:getEquips():length() > 2
				and hasDelayedTrickXiuluo(target)
	end
}
nl_doudizhuMode = sgs.CreateTriggerSkill{
	name = "#nl_doudizhuMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use_player = room:getPlayers():at(0)
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			if player:getRole() == "rebel" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "rebel" then
						local choice = room:askForChoice(p, "nl_supply", "draw+recover")
						if choice == "draw" then
							room:drawCards(p, 2, self:objectName())
						elseif choice == "recover" then
							local recover = sgs.RecoverStruct()
							recover.who = p
							recover.recover = 1
							room:recover(p, recover)
						end
					end
				end
			end
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase ==  sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
				card_remover:trigger(sgs.GameStart, room, player, data)
				local maxhp = player:getMaxHp() + 1
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
				room:setPlayerProperty(player, "hp", sgs.QVariant(maxhp))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					room:setPlayerMark(p, "AG_hasExecuteStart",1)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setTag("FirstRound" , sgs.QVariant(true))
					p:drawCards(4)
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_doudizhuMode") then skills:append(nl_doudizhuMode) end
if not sgs.Sanguosha:getSkill("nl_faiyang") then skills:append(nl_faiyang) end
if not sgs.Sanguosha:getSkill("#nl_faiyangtm") then skills:append(nl_faiyangtm) end
if not sgs.Sanguosha:getSkill("nl_bahu") then skills:append(nl_bahu) end


extension:insertRelatedSkills("nl_faiyang","#nl_faiyangtm")
sgs.LoadTranslationTable{
	["nl_supply"] = "補給",
	["nl_faiyang"] = "飛揚",
	[":nl_faiyang"] = "你摸牌時額外摸1張牌，你使用的「殺」數量額外加1",
	["nl_bahu"] = "跋扈",
	[":nl_bahu"] = "你可以棄置兩張牌來棄置你判定區內的牌",

	["kaihei"] = "強易",
	[":kaihei"] = "出牌階段，你可以獲得一名其他角色的至多兩張牌，然後交給其等量的牌。每名角色每局遊戲限一次。",
}


--------------------------------------------------------------------------------
-------------------------------------鬥地主（智鬥）----------------------------------
--------------------------------------------------------------------------------

--	zhidou juzhong

nl_ZhidouMode = sgs.CreateTriggerSkill{
	name = "#nl_ZhidouMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use_player = room:getPlayers():at(0)
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			if player:getRole() == "rebel" then
				room:gameOver("lord")
			end
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase ==  sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then

					local wh_targets = sgs.SPlayerList()
					local whtarget1 = player
					for i = 1, (room:alivePlayerCount()), 1 do
						wh_targets:append(whtarget1)
						whtarget1 = whtarget1:getNextAlive()
					end

					local kingdom_list = {"wei","shu","wu","qun","jin"}
					local player_kingdom_list = {}
					local teamkingdom1 = kingdom_list[math.random(1,#kingdom_list)]
					table.insert(player_kingdom_list, teamkingdom1)
					table.removeOne(kingdom_list, teamkingdom1)

					local teamkingdom2 = kingdom_list[math.random(1,#kingdom_list)]
					table.insert(player_kingdom_list, teamkingdom2)
					table.removeOne(kingdom_list, teamkingdom2)

					local teamkingdom3 = kingdom_list[math.random(1,#kingdom_list)]
					table.insert(player_kingdom_list, teamkingdom3)

					local i = 0
					for _, p in sgs.qlist(wh_targets) do
						i = i + 1
						room:setPlayerMark(p, "AG_hasExecuteStart", 1)
						local k_list = {}
						if player_kingdom_list[i] == "wei" then
							k_list = {"wei", "wei2", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
						elseif player_kingdom_list[i] == "shu" then
							k_list = {"shu", "shu2", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
						elseif player_kingdom_list[i] == "wu" then
							k_list = {"wu", "wu2", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
						elseif player_kingdom_list[i] == "qun" then
							k_list = {"qun", "qun2", "qun3", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
						elseif player_kingdom_list[i] == "jin" then
							k_list = {"jin", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("jin"))
						end
						if p:isLord() then
							choosenewgeneral_heg(p, 3 , k_list,{})
							local n = 0

							n = n + sgs.Sanguosha:getGeneral(p:getGeneralName()):getMaxHp() - 3
							n = n + sgs.Sanguosha:getGeneral(p:getGeneral2Name()):getMaxHp() - 3
							room:setPlayerMark(p , "zhidou_draw",n)
						else
							choosenewgeneral(p, 3 , k_list,{})
						end

						if player_kingdom_list[i] == "wei" then
							k_list = {"wei", "wei2", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
						elseif player_kingdom_list[i] == "shu" then
							k_list = {"shu", "shu2", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
						elseif player_kingdom_list[i] == "wu" then
							k_list = {"wu", "wu2", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
						elseif player_kingdom_list[i] == "qun" then
							k_list = {"qun", "qun2", "qun3", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
						elseif player_kingdom_list[i] == "jin" then
							k_list = {"jin", "god"}
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("jin"))
						end

					end

					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p,"gameMode_zhidou",1)
					end
					for _, p in sgs.qlist(wh_targets) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					end
					room:setPlayerMark(player, "AG_firstplayer", 1)
					room:setPlayerMark(player, "@clock_time", 1)
					room:setTag("FirstRound" , sgs.QVariant(true))
					for _, p in sgs.qlist(wh_targets) do
						p:drawCards(4 + p:getMark("zhidou_draw") )
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
				room:setPlayerMark(player, "@leader", 0)

		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}

nl_juzhong = sgs.CreateTriggerSkill{
	name = "nl_juzhong",
	events = {sgs.CardUsed,sgs.CardFinished,sgs.CardResponded,sgs.PreHpRecover,sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed or event == sgs.CardResponded then
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
			if card and (not card:isKindOf("SkillCard")) and card:isKindOf("BasicCard") then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if isSameTeam(player,p) then

						local convert_to_askforcard_name = card:objectName()
						convert_to_askforcard_name = convert_to_askforcard_name:gsub("(%l)(%w+)", function(a,b) return string.upper(a)..b end)
						convert_to_askforcard_name = string.gsub(convert_to_askforcard_name, "_", "")

						if room:askForCard(p, convert_to_askforcard_name, "@juzhong", data) then
							room:setCardFlag(card , "nl_juzhong")
							if card:isKindOf("Analeptic") then
								for _,pp in sgs.qlist(room:getOtherPlayers(player)) do
									if isSameTeam(player,pp) then
										room:addPlayerMark(pp,"nl_juzhong_buff-Clear")
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if player:getMark("nl_juzhong_buff-Clear") > 0 then
				local log = sgs.LogMessage()
				log.type = "$nl_juzhongREC"
				log.from = player
				log.arg = player:getMark("nl_juzhong_buff-Clear")
				room:sendLog(log)
				rec.recover = rec.recover + player:getMark("nl_juzhong_buff-Clear")
				data:setValue(rec)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("nl_juzhong") then
				local log = sgs.LogMessage()
				log.type = "$nl_juzhongDMG"
				log.from = player
				log.arg = 1
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end

			if player:getMark("nl_juzhong_buff-Clear") > 0 then
				local log = sgs.LogMessage()
				log.type = "$nl_juzhongDMG"
				log.from = player
				log.arg = player:getMark("nl_juzhong_buff-Clear")
				room:sendLog(log)
				damage.damage = damage.damage + player:getMark("nl_juzhong_buff-Clear")
				data:setValue(damage)
			end
		else
			local card
			if event == sgs.CardFinished then
				card = data:toCardUse().card
			end
			if card and card:isKindOf("Jink") and card:hasFlag("nl_juzhong") then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canDiscard(p, "he") then _targets:append(p) end
				end
				if not _targets:isEmpty() then
					local to_discard = room:askForPlayerChosen(player, _targets, "chouce2", "@chouce-discard", true)
					if to_discard then
						room:doAnimate(1, player:objectName(), to_discard:objectName())
						room:throwCard(room:askForCardChosen(player, to_discard, "he", "chouce", false, sgs.Card_MethodDiscard), to_discard, player)
					end
				end
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("#nl_ZhidouMode") then skills:append(nl_ZhidouMode) end
if not sgs.Sanguosha:getSkill("nl_juzhong") then skills:append(nl_juzhong) end

sgs.LoadTranslationTable{
["nl_juzhong"] = "聚眾",
[":nl_juzhong"] = "當農民的隊友使用一張基本牌時，你可以棄置一張同名基本牌強化此牌效果。"..
"【殺】強化後：傷害+1；"..
"【閃】強化後：響應的閃生效後則棄置一名角色的一張牌；"..
"【桃】強化後：此桃生效後可額外摸兩張牌；"..
"【酒】本回合農民的傷害量和回復量+1。",
["@juzhong"] = "你可以發動“聚眾”",

["$nl_juzhongREC"] = "%from 發動“聚眾”，回復值+ %arg",
["$nl_juzhongDMG"] = "%from 發動“聚眾”，傷害值+ %arg",

["doudizhu_cardPile"] = "底牌",
["online_gongshoujintui"] = "攻守進退",
["gongshoujianbei"] = "攻守兼備",
[":gongshoujianbei"] = "出牌階段，你可選擇：①將此牌當做【萬箭齊發】使用。②將此牌當做【桃園結義】使用。",
["jintuiziru"] = "進退自如",
[":jintuiziru"] = "出牌階段，你可選擇：①將此牌當做【南蠻入侵】使用。②將此牌當做【五穀豐登】使用。",
["diqi"] = "地契",
["diqi_skill"] = "地契",
[":diqi"] = "當你受到傷害時，你可以棄置此牌，防止此傷害。當此牌離開你的裝備區後，銷毀之。",
["_juzhong"] = "聚眾",
["juzhong_jiu"] = "聚眾",
["zhadan"] = "炸彈",
[":zhadan"] = "當一張牌被使用時，對此牌使用。取消此牌的所有目標，且本局遊戲的底價翻倍。",
["jiwangkailai"] = "繼往開來",
[":jiwangkailai"] = "出牌階段，對包含你自己在內的一名角色使用。目標角色選擇一項：①棄置所有手牌，然後摸等量的牌。②將所有手牌當做一張不為【繼往開來】的普通錦囊牌使用。",
}

--兵臨城下模式

sgs.LoadTranslationTable{
["zhuSkill_xiangyang"] = "襄陽",
[":zhuSkill_xiangyang"] = "回合結束時，你可獲得一個額外的出牌階段或摸牌階段。",
["zhuSkill_jiangling"] = "江陵",
[":zhuSkill_jiangling"] = "當你使用【殺】或普通錦囊牌選擇唯一目標時，你可為此牌增加一個目標（該目標不可響應此牌）。",
["zhuSkill_fancheng"] = "樊城",
[":zhuSkill_fancheng2"] = "樊城",
[":zhuSkill_fancheng"] = "限定技，出牌階段，你可摸X張牌獲得如下效果直到回合結束：每回合限X次，當你造成傷害時，此傷害+1（X為遊戲輪數）。",

["binglin_shaxue"] = "歃血",
[":binglin_shaxue"] = "鎖定技，每局遊戲限三次，當你受到隊友造成的傷害時，你防止此傷害。",
["binglin_neihong"] = "內訌",
[":binglin_neihong"] = "鎖定技，當你殺死隊友後，你所在的陣營視為遊戲失敗。",

["baiyidujiang"] = "白衣渡江",
[":baiyidujiang"] = "出牌階段，對地主使用。你選擇一項：①令其將手牌數摸至全場最多。②令其將手牌數棄置至全場最少。",
["shuiyanqijuny"] = "水淹七軍",
[":shuiyanqijuny"] = "此牌不對目標角色進行座次排序。出牌階段，對至多兩名角色使用。目標角色受到1點雷屬性傷害，然後若其：是第一個目標，其棄置一張牌；不是第一個目標，其摸一張牌。",
["luojingxiashi"] = "落井下石",
[":luojingxiashi"] = "出牌階段，對所有其他的已受傷角色使用。目標角色受到1點傷害。",
["binglinchengxia"] = "兵臨城下",
[":binglinchengxia"] = "出牌階段，對一名其他角色使用。將此牌橫置於目標角色的判定區內。目標角色於判定階段進行判定，若判定結果不為♦，則其棄置裝備區內的所有牌或受到1點傷害。",
["toushiche"] = "投石車",
["toushiche_skill"] = "投石車",
[":toushiche"] = "鎖定技，結束階段開始時，你令所有手牌數大於你的角色依次棄置一張手牌。",
["binglin_bingjin"] = "兵盡",
}



--------------------------------------------------------------------------------
-------------------------------------三英模式------------------------------------
--------------------------------------------------------------------------------
nl_sanying = sgs.CreateTriggerSkill{
	name = "#nl_sanying",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.BuryVictim,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:isLord() and (not room:getTag("ExtraTurn"):toBool()) then
				if player:getMark("@clock_time") == 0 and player:getMark("@leader") > 0 then


					local sks_all = {"sy_lvbu1", "sy_dongzhuo1", "sy_zhangjiao1", "sy_zhangrang1", "sy_weiyan1", "sy_sunhao1", "sy_caifuren1", "sy_simayi1", "berserk_miku1", "sy_yasuo1", "sy_simashi1"}
					local sks = {}
					for i = 1,4,1 do 
						local random1 = math.random(1, #sks_all)
						table.insert(sks, sks_all[random1])
						table.remove(sks_all, random1)
					end
					local choice = room:askForGeneral(player, table.concat(sks, "+"))
					room:changeHero(player, choice, false,false, false,false)
					--choosenewgeneral(player, 9)

					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						choosenewgeneral(p, 9, false, {})
					end
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p,"gameMode_sanying",1)
					end
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						if not player:isLord() then
							room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
						end
					end
					room:setPlayerMark(player, "@clock_time", 1)
					--local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
					--card_remover:trigger(sgs.GameStart, room, player, data)

					room:setTag("FirstRound" , sgs.QVariant(true))
					player:drawCards(8)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						p:drawCards(4)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
					room:setPlayerMark(player, "@leader", 0)
				end
				for _, p in sgs.qlist(room:getPlayers()) do
					if not p:isAlive() then
						if p:getMark("@sanying_turn") >= 6 then
							room:revivePlayer(p)
							if p:getMaxHp() >= 3 then
								room:setPlayerProperty(p, "hp", sgs.QVariant(3))
								p:drawCards(3)
							else
								local playermaxhp = p:getMaxHp()
								room:setPlayerProperty(p, "hp", sgs.QVariant(playermaxhp))
								p:drawCards((6-playermaxhp))
							end
							room:setPlayerMark(p,"@sanying_turn",0)
						else
							room:setPlayerMark(p,"@sanying_turn",p:getMark("@sanying_turn") + 1)	
						end
					end
				end
			elseif change.to == sgs.Player_NotActive and not room:getTag("ExtraTurn"):toBool() then
				local nextplayer = player:getNextAlive()
				if not nextplayer:isLord() and not player:isLord() then

					local lord_player
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isLord() and p:getMark("@sy_waked") == 0  then
							lord_player = p
							break
						end
					end

					if lord_player then
						room:setTag("ExtraTurn",sgs.QVariant(true))
						lord_player:gainAnExtraTurn()
						room:setTag("ExtraTurn",sgs.QVariant(false))
					end
				end
			end
		elseif event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if player:getRole() == "rebel" and splayer:getRole() == "rebel" then
				player:drawCards(1)
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
	priority = 15,
}

nl_sanyingskip = sgs.CreateTriggerSkill{
	name = "#nl_sanyingskip",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			local breakphase = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@jumpend") == 1 then
					breakphase = 1
				end
			end
			if breakphase == 1 then
				if player:getMark("@jumpend") == 1 then
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, "@jumpend", 0)
					end
				else
					room:getThread():delay(1000)
					room:throwEvent(sgs.TurnBroken)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
}

if not sgs.Sanguosha:getSkill("#nl_sanying") then skills:append(nl_sanying) end
if not sgs.Sanguosha:getSkill("#nl_sanyingskip") then skills:append(nl_sanyingskip) end

sgs.LoadTranslationTable{
	["$sanyinglimit"] = "惹了我，你們的下場....",
}

--文和亂武
--牌堆情況：本玩法中，使用軍爭卡牌。其中，桃園結義和木牛流馬替換為 斗轉星移；黑色無懈可擊替換為 偷梁換柱；紅色無懈可擊替換為 李代桃僵；移除所有樂不思蜀；兵糧寸斷替換為 文和亂武。
--擊殺獎懲：成功擊殺一名其他角色，則擊殺者獲得1點體力上限（不回復體力，只獲得體力上限），並摸3張牌

nl_wenholuanwu7skill = sgs.CreateFilterSkill{
	name = "#nl_wenholuanwu7skill", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return to_select:isKindOf("Peach") and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local duel = sgs.Sanguosha:cloneCard("poison", originalCard:getSuit(), originalCard:getNumber())
		duel:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(duel)
		return card
	end
}

if not sgs.Sanguosha:getSkill("#nl_wenholuanwu7skill") then skills:append(nl_wenholuanwu7skill) end

nl_wenholuanwu = sgs.CreateTriggerSkill{
	name = "#nl_wenholuanwu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if player:getHp() <= 0 and player:getMark("AG_firstplayer") > 0 then
			local now = player:getNextAlive()
			room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
			room:setPlayerMark(now, "AG_firstplayer", 1)

			if room:getCurrent():objectName() == player:objectName() then
				room:setPlayerMark(now, "@stop_invoke", 1)
			end
		end
		if dying.damage then
			local killer = dying.damage.from
			if player:getHp() <= 0 then
				if killer:hasSkill(self:objectName()) then
					if killer:getMark("wenholuanwu") == 2 then
						local maxhp = killer:getMaxHp() + 2
						room:setPlayerProperty(killer, "maxhp", sgs.QVariant(maxhp))
						killer:drawCards(6)
					else
						local maxhp = killer:getMaxHp() + 1
						room:setPlayerProperty(killer, "maxhp", sgs.QVariant(maxhp))
						killer:drawCards(3)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
--1、該模式下，有7條特殊規則，遊戲開始時，第一輪默認為亂武規則，之後每輪開始時隨機抽取並公佈一條特殊規則，作為本輪的特殊規則存在。
--2、特殊規則具體效果如下：
--1【亂武】從隨機一名角色開始結算亂武（所有角色，需對與自己距離最近的另一名角色使用一張【殺】，否則失去一點體力）。
--2【重賞】本輪之中，擊殺角色獎勵翻倍。
--3【破釜沉舟】每個回合開始時，當前回合角色失去一點體力，摸3張牌。
--4【橫刀躍馬】每個回合結束時，所有裝備最少的角色失去1點體力並隨機在裝備區置入一件裝備牌。
--5【橫掃千軍】本輪之中，所有即將造成的傷害+1。
--6【餓莩載道】本輪結束時，所有手牌最少的角色失去當前輪數的體力值。
--7【宴安鴆毒】本輪中，所有的桃均視為毒（毒：該牌正面朝上離開你的手牌區，則你需要失去1點體力）。

--文和亂武選將

nl_wenholuanwu2 = sgs.CreateTriggerSkill{
	name = "#nl_wenholuanwu2",
	frequency = sgs.Skill_Compulsory,
	priority = 100,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.DamageCaused,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use_player = room:getPlayers():at(0)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and (player:getMark("AG_firstplayer") > 0 or player:getMark("@leader") > 0) and (not room:getTag("ExtraTurn"):toBool()) and player:getMark("@stop_invoke") == 0 then
				if player:getMark("wenholuanwu") == 6 then
					local player_handcard = {}
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						table.insert(player_handcard, p:getHandcardNum())
					end
					local wh_targets = sgs.SPlayerList()
					local whtarget1 = player
					for i = 1, (room:alivePlayerCount()), 1 do
						wh_targets:append(whtarget1)
						whtarget1 = whtarget1:getNextAlive()
					end

					for _, p in sgs.qlist(wh_targets) do
						if p:getHandcardNum()== math.min(unpack(player_handcard)) then
							local msg = sgs.LogMessage()
							msg.type = "#wenholuanwuLostHp"
							msg.from = p
							msg.to:append(p)
							msg.arg = tostring(player:getMark("@clock_time"))
							room:sendLog(msg)
							room:loseHp(p , player:getMark("@clock_time"))
						end
					end
				elseif player:getMark("wenholuanwu") == 7 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:handleAcquireDetachSkills(p, "-#nl_wenholuanwu7skill", false)
					end
				end
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "wenholuanwu", 0)
				end
				local n = math.random(1, 7)

				if player:getMark("@clock_time") == 0 and player:getMark("@leader") > 0 then
					room:setPlayerProperty(player, "role", sgs.QVariant("renegade"))
					room:updateStateItem()
					room:resetAI(player)
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, "player_seat_original", p:getSeat())
					end

					local wh_targets = sgs.SPlayerList()
					local whtarget1 = player
					for i = 1, (room:alivePlayerCount()), 1 do
						wh_targets:append(whtarget1)
						whtarget1 = whtarget1:getNextAlive()
					end

					local banned_list = {"huatuo","nos_huatuo","liubei","ganning","daqiao","nos_daqiao",
	 "caoren","neo_caoren","bgm_caoren","yuji","ol_xiaoqiao","xiaoqiao","zhoutai","caopi","menghuo","mobile_caopi","jiaxu",
	 "dongzhuo","wolong","pangtong","wolong_po","pangtong_po","caiwenji","zuoci","shenguanyu","shenlvmeng","shenzhouyu",
	 "shenzhugeliang","shencaocao","ol_shencaocao","shenlvbu","shenzhaoyun","new_godzhaoyun","shensimayi",
	 "shensimayi_po","ol_shenzhangliao","shencaopi","shenzhenji",
	 "chengong","lugi","yuanshao_po","mobile_yuanshao","wangshuang","zhangrang","guohuanghou",
	 "dongyun","ol_dongzhuo","tadun","caoshuang","shenganning","shenluxun_sec_rev","shenliubei",
	 "shenzhangliao","ol_xiahouyuan","sunziliufang","liuyan",
	 "yuanshao","caiwenji","xunyou","manchong","sunluban","sunluban_po","zhugedan","ol_zhugedan",
	 "mobile_caozhi","caozhi",

	 "bgm_pangtong","bgm_zhangfei","bgm_lvmeng","bgm_liubei","bgm_daqiao","bgm_ganning","bgm_xiahoudun",
	 "sr_sunquan","sr_luxun","sr_ganning","sr_daqiao","sr_xuchu","sr_diaochan","sr_huatuo",
	 "yt_shencaocao","yt_caochong","jiawenhe","dengshizai","wutugu","xusheng",
	 "ol_caoren","ol_jiaxu","liaohua","liaohua_po","guansuo","ty_guansuo","sk_tainfeng",

	"sk_shencaocao","sk_shenlubu","sk_tianfeng","sk_zoushi","mobile_caopi","mobile_caiwenji",
"mobile_caozhi","mobile_manchong","mobile_chenqun","mobile_chenqun","ol_chenqun","mobile_liaohua",
"liangxing","liangxing","twyj_caohong","sr_luxun","sr_luxun","sr_ganning","sr_ganning","sr_ganning",
"sr_ganning","ol_caoren","ol_xiahouyuan","ol_xiahouyuan","ol_xiahouyuan","ol_shencaocao","zhuyin",
"zhuyin","zhuque","huoshenzhurong","yandi","qinglong","mushengoumang","taihao","baihu","sy_yasuo",
"kb_caoren","jg_FumaKotaro","jg_LadyHayakawa","jg_LadyHayakawa","jg_gracia","spyiji","sunziliufang",
"re_mifuren","re_zoushi","sk_shencaocao","ol_shencaocao","sk_shenlubu","mobile_liaohua","liaohua_po",
"liyan","ol_caoren","kb_caoren","ol_caoren","mobile_manchong","mobile_caopi","mobile_caiwenji",
"mobile_chenqun","mobile_chenqun","ol_chenqun","mobile_caozhi"}

					for _, p in sgs.qlist(wh_targets) do
						choosenewgeneral(p, 9, false, banned_list)
					end
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p,"gameMode_wenho",1)
					end
					for _, p in sgs.qlist(wh_targets) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					end
					room:setPlayerMark(player, "AG_firstplayer", 1)
					room:setPlayerMark(player, "@clock_time", 1)
					--local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
					--card_remover:trigger(sgs.GameStart, room, player, data)

					room:setTag("FirstRound" , sgs.QVariant(true))
					for _, p in sgs.qlist(wh_targets) do
						if p:getMark("@leader") > 0 then
							p:drawCards(3)
						else
							p:drawCards(4)
						end
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
					n = 1
				end
				room:setPlayerMark(player, "@leader", 0)
				room:doSuperLightbox("whlw_jiaxu","wenholuanwu"..n)

				--use_player:drawCards(1)

				local msg = sgs.LogMessage()
				msg.type = "#Wenholuanwu"
				msg.from = player
				msg.arg = "wenholuanwu"..n
				msg.arg2 = "wenholuanwu"..n.."text"
				room:sendLog(msg)
				if n == 1 then
					local startlwplayer
					startlwplayer = room:getAlivePlayers():at(math.random(1, room:getAlivePlayers():length())-1)
					room:broadcastSkillInvoke("luanwu")
					local _targets = sgs.SPlayerList()
					local lwtarget1 = startlwplayer
					for i = 1, (room:alivePlayerCount()), 1 do
						_targets:append(lwtarget1)
						lwtarget1 = lwtarget1:getNextAlive()
					end
					for _,p in sgs.qlist(_targets) do
						local distance_list = sgs.IntList()
						local nearest = 1000
						for _,q in sgs.qlist(room:getOtherPlayers(p)) do
							local distance = p:distanceTo(q)
							distance_list:append(distance)
							nearest = math.min(nearest, distance)
						end
						local luanwu_targets = sgs.SPlayerList()
						for i = 0, distance_list:length() - 1, 1 do
							if distance_list:at(i) == nearest and p:canSlash(room:getOtherPlayers(p):at(i), nil, false) then
								luanwu_targets:append(room:getOtherPlayers(p):at(i))
							end
						end
						if luanwu_targets:length() == 0 or not room:askForUseSlashTo(p, luanwu_targets, "@luanwu-slash") then
							room:loseHp(p)
						end
					end
				elseif n >= 2 then
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, "wenholuanwu", n)
						if n == 7 then
							room:handleAcquireDetachSkills(p, "#nl_wenholuanwu7skill", false)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				if player:getMark("wenholuanwu") == 3 then
					room:loseHp(player)
					player:drawCards(3)
				end
			elseif phase == sgs.Player_Finish then
				if player:getMark("wenholuanwu") == 4 then
					local player_equip = {}
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						table.insert(player_equip, p:getEquips():length())
					end

					local wh_targets = sgs.SPlayerList()
					local whtarget1 = player
					for i = 1, (room:alivePlayerCount()), 1 do
						wh_targets:append(whtarget1)
						whtarget1 = whtarget1:getNextAlive()
					end
					for _, p in sgs.qlist(wh_targets) do
						if p:getEquips():length()== math.min(unpack(player_equip)) then
							room:loseHp(p)
							local DPHeart = sgs.IntList()
							if room:getDrawPile():length() > 0 then
								for _, id in sgs.qlist(room:getDrawPile()) do
									local card = sgs.Sanguosha:getCard(id)
									if card:isKindOf("EquipCard") then
										DPHeart:append(id)
									end
								end
							end
							if room:getDiscardPile():length() > 0 then
								for _, id in sgs.qlist(room:getDiscardPile()) do
									local card = sgs.Sanguosha:getCard(id)
									if card:isKindOf("EquipCard") then
										DPHeart:append(id)
									end
								end
							end
							if DPHeart:length() ~= 0 and p:isAlive() then
								local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
								local get_card = sgs.Sanguosha:getCard(get_id)
								local use = sgs.CardUseStruct()
								use.card = get_card
								use.from = p
								room:useCard(use)
							end
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from:getMark("wenholuanwu") == 5 then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#wenholuanwuPD"
				msg.from = damage.from
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)
			end
			return false
		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if use_player and splayer:objectName() == use_player:objectName() and not player:hasFlag("dieplayed") then
				if room:alivePlayerCount() == 1 then
					room:doSuperLightbox("wenho_beauty","wenholuanwurank2")
				elseif room:alivePlayerCount() <= 3 then
					room:doSuperLightbox("wenho_beauty","wenholuanwurank3")
				elseif room:alivePlayerCount() <= 5 then
					room:doSuperLightbox("wenho_beauty","wenholuanwurank5")
				else
					room:doSuperLightbox("wenho_beauty","wenholuanwurank7")
				end
				for _, p in sgs.qlist(room:getPlayers()) do
					if p:isAlive() or p == splayer then
						room:setPlayerFlag(p, "dieplayed")
					end
				end
			end
			if room:alivePlayerCount() == 1 then
				local winner
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					winner = p:objectName()
				end
				room:getThread():delay()
				if winner then
					if winner == use_player:objectName() then
						room:doSuperLightbox("wenho_beauty","wenholuanwuwin")
						room:doLightbox("$wenholuanwulimit", 3000)
					end
					room:gameOver(winner)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
	priority = 15,
}


nl_wenholuanwuPS = sgs.CreateProhibitSkill{
	name = "nl_wenholuanwuPS",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		if from:getMark("gameMode_wenho") > 0 and (from:objectName() ~= to:objectName()) and card:isKindOf("Peach") then
			return true
		end
		return false
	end
}


--3、模式專屬錦囊：
--【斗轉星移】出牌階段，對一名其他角色使用。隨機分配你和其的體力（至少為1且無法超出上限）。
--【偷梁換柱】出牌階段，對你使用。隨機分配所有角色裝備區的牌。
--【李代桃僵】出牌階段，對一名其他角色使用。隨機分配你和其的手牌。
--【文和亂武】出牌階段，對你使用。除你以外的所有其他角色必須對與他距離最近的一名角色出【殺】，否則失去1點體力。
if not sgs.Sanguosha:getSkill("#nl_wenholuanwu") then skills:append(nl_wenholuanwu) end
if not sgs.Sanguosha:getSkill("#nl_wenholuanwu2") then skills:append(nl_wenholuanwu2) end
if not sgs.Sanguosha:getSkill("nl_wenholuanwuPS") then skills:append(nl_wenholuanwuPS) end


sgs.LoadTranslationTable{
	["wenholuanwu1"] = "文和亂武",
	["wenholuanwu2"] = "重賞",
	["wenholuanwu3"] = "破釜沉舟",
	["wenholuanwu4"] = "橫刀躍馬",
	["wenholuanwu5"] = "橫掃千軍",
	["wenholuanwu6"] = "餓莩載道",
	["wenholuanwu7"] = "宴安鴆毒",
	["nl_wenholuanwu7skill"] = "宴安鴆毒",
	[":nl_wenholuanwu7skill"] = "你無法使用桃",
	["#Wenholuanwu"] = "<font color=\"yellow\"><b>賈詡</b></font>公佈了特殊規則 %arg ，內容為 %arg2",
	["wenholuanwu1text"] = "從隨機一名角色開始結算亂武。",
	["wenholuanwu2text"] = "本輪之中，擊殺角色獎勵翻倍。",
	["wenholuanwu3text"] = "每個回合開始時，當前回合角色失去一點體力，摸3張牌。",
	["wenholuanwu4text"] = "每個回合結束時，所有裝備最少的角色失去1點體力並隨機在裝備區置入一件裝備牌。",
	["wenholuanwu5text"] = "本輪之中，所有即將造成的傷害+1。",
	["wenholuanwu6text"] = "本輪結束時，所有手牌最少的角色失去當前輪數的體力值。",
	["wenholuanwu7text"] = "本輪中，所有角色無法使用桃",
	["wenholuanwuwin"] = "入主長安",
	["$wenholuanwulimit"] = "恭喜您，成功入主長安",
	["wenholuanwurank2"] = "一人之下",
	["wenholuanwurank3"] = "名震天下",
	["wenholuanwurank5"] = "一方豪強",
	["wenholuanwurank7"] = "初出茅廬",
	["nl_wenholuanwuPS"] = "死鬥",
	[":nl_wenholuanwuPS"] = "鎖定技，你無法對其他角色使用「桃」",
	["#wenholuanwuPD"] = "%from 觸發了 “<font color=\"yellow\"><b>橫掃千軍</b></font>”的效果，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
	["#wenholuanwuLostHp"] = "%from 手牌數最少，觸發了 “<font color=\"yellow\"><b>餓莩載道</b></font>”的效果，失去 %arg 點體力",
}
--取消死亡獎懲
nl_NoDieReward = sgs.CreateTriggerSkill{
	name = "#nl_NoDieReward",
	events = {sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local reason = death.damage
		local room = player:getRoom()
		room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
		if reason then
			local killer = reason.from
			if killer and killer:isAlive() then
				if killer:hasSkill(self:objectName()) then
					room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
					player:bury()
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

--龍舟模式
nl_BoatMode = sgs.CreateTriggerSkill{
	name = "#nl_BoatMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.Damage,sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart then
				if (player:getMark("@leader") > 0 or player:getMark("AG_firstplayer") > 0) then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					end
					room:setPlayerMark(player, "@leader", 0)	
					room:setPlayerMark(player, "AG_firstplayer", 1)		
					room:setTag("FirstRound" , sgs.QVariant(true))
					player:drawCards(3)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						p:drawCards(4)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end

				if player:getMark("@clock_time") == 3 then
					local boat_loyalist = 0
					local boat_rebel = 0
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getRole() == "loyalist" then
							boat_loyalist = boat_loyalist + p:getMark("@boat")
						elseif p:getRole() == "rebel" then
							boat_rebel = boat_rebel + p:getMark("@boat")
						end
					end
					local msg = sgs.LogMessage()
					msg.type = "#BoatMode"
					msg.from = player
					msg.arg = tostring(boat_loyalist)
					msg.arg2 = tostring(boat_rebel)
					room:sendLog(msg)
					if boat_loyalist > boat_rebel then
						room:gameOver("loyalist")
					elseif boat_rebel > boat_loyalist then
						room:gameOver("rebel")
					else
						room:gameOver()
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:getRole() ~= damage.to:getRole() then
				player:gainMark("@boat",damage.damage)
				local boat_loyalist = 0
				local boat_rebel = 0
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "loyalist" then
						boat_loyalist = boat_loyalist + p:getMark("@boat")
					elseif p:getRole() == "rebel" then
						boat_rebel = boat_rebel + p:getMark("@boat")
					end
				end
				local msg = sgs.LogMessage()
				msg.type = "#BoatMode"
				msg.from = player
				msg.arg = tostring(boat_loyalist)
				msg.arg2 = tostring(boat_rebel)
				room:sendLog(msg)
			end
		elseif event == sgs.HpChanged then
			if player:getHp() <= 0 then
				room:setPlayerProperty(player, "hp", sgs.QVariant(1))
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 99,
}
if not sgs.Sanguosha:getSkill("#nl_BoatMode") then skills:append(nl_BoatMode) end
sgs.LoadTranslationTable{
	["#BoatMode"] = "<font color=\"yellow\"><b>忠臣</b></font>方共獲得 %arg 個寶船，<font color=\"green\"><b>反賊</b></font>方共獲得 %arg2 個寶船",
	["@boat"] = "寶船",
}
--舊版龍舟模式

--遊戲開始時，每個勢力的隨機一名角色得到一個龍船至寶，1號位角色所在的勢力額外獲得一個龍船至寶，場上共5枚龍船至寶。 龍船至寶是一個特殊標記。
--爭奪龍船至寶的方式：當敵人受到了你造成的傷害後，若其有龍船至寶，則你獲得其一個龍船至寶。 若你殺死了該敵人，則你獲得其所有的龍船至寶。
--獲得龍船至寶時的摸牌：除遊戲開始時外，若你從非隊友處獲得了龍船至寶，則你和隊友各摸X張牌。 （X為該次獲得的龍船至寶數；獲得隊友的龍船至寶不摸牌）
--無來源死亡時：當一名角色死亡時，若沒有傷害來源，則其持有的所有龍船至寶交給場上龍船至寶數唯一最多的角色，若沒有則隨機分配，獲得龍船至寶的角色和其隊友各摸X張牌。
--殺死隊友時：當你殺死隊友時，則將你和隊友持有的所有龍船至寶交給場上龍船至寶數唯一最多的敵人，若沒有則隨機分配，獲得龍船至寶的角色和其隊友各摸X張牌。
--擊殺獎懲： （1）殺死非隊友角色摸一張牌。(2）殺死隊友棄掉所有牌，並將你和隊友所有的龍船至寶都交給場上龍船至寶數唯一最多的敵人，若沒有則隨機分配。
nl_nosBoatMode = sgs.CreateTriggerSkill{
	name = "#nl_nosBoatMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:getRole() ~= damage.to:getRole() and damage.to:getMark("@boat") > 0 then
				player:gainMark("@boat",1)
				damage.to:loseMark("@boat",1)
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getRole() == player:getRole() then
						p:drawCards(1)
					end
				end
				local boat_loyalist = 0
				local boat_rebel = 0
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "loyalist" then
						boat_loyalist = boat_loyalist + p:getMark("@boat")
					elseif p:getRole() == "rebel" then
						boat_rebel = boat_rebel + p:getMark("@boat")
					end
				end
				local msg = sgs.LogMessage()
				msg.type = "#BoatMode"
				msg.from = player
				msg.arg = tostring(boat_loyalist)
				msg.arg2 = tostring(boat_rebel)
				room:sendLog(msg)
				if boat_loyalist == 9 then
					room:gameOver("loyalist")
				elseif boat_rebel == 9 then
					room:gameOver("rebel")
				end
			end
		elseif event == sgs.BuryVictim then
			local death = data:toDeath()


			if player:getMark("AG_firstplayer") > 0 then
				local now = player:getNextAlive()
				room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
				room:setPlayerMark(now, "AG_firstplayer", 1)
				if room:getCurrent():objectName() == player:objectName() then
					room:setPlayerMark(now, "@stop_invoke", 1)
				end
			end

			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
					if killer:getRole() ~= player:getRole() then
						killer:drawCards(1)
					end
					if player:getMark("@boat") > 0 then
						if killer:getRole() ~= player:getRole() then
							killer:gainMark("@boat",player:getMark("@boat"))
							player:loseMark("@boat",player:getMark("@boat"))
						else
							for i = 1, player:getMark("@boat"), 1 do
								local n = math.random(1,room:getAlivePlayers():length())
								local p = room:getAlivePlayers():at(n-1)
								p:gainMark("@boat",1)
								player:loseMark("@boat",1)
							end
						end
					end 
				else
					if player:getMark("@boat") > 0 then
						for i = 1, player:getMark("@boat"), 1 do
							local n = math.random(1,room:getAlivePlayers():length())
							local p = room:getAlivePlayers():at(n-1)
							p:gainMark("@boat",1)
							player:loseMark("@boat",1)
						end
					end
				end
			end
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
			player:bury()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	priority = 99,
}
if not sgs.Sanguosha:getSkill("#nl_nosBoatMode") then skills:append(nl_nosBoatMode) end


--千里單騎
--關卡 武將 血量上限 起手牌數 先動/後動
--第1關 自選 0 4+0 後動
--第2關 自選 0 4+1 先動
--第3關 自選 1 4+1 先動
--第4關 自選 1 4+2 先動
--第5關 自選 2 4+2 先動
--第6關 蔡陽 1 2 先動
str_tsaiyan = sgs.General(extension, "str_tsaiyan", "qun", "1", true, true, true)
--獎勵
function chanlidanxin_reward(source,opponent)
	local room = source:getRoom()
	local allchoicelist = {"CLDXR1","CLDXR2","CLDXR5","CLDXR6","CLDXR7","CLDXR12","CLDXR13","CLDXR14","CLDXR15","CLDXR17","CLDXR18","CLDXR19","CLDXR3","CLDXR4","CLDXR8","CLDXR9","CLDXR11","CLDXR16"} 
	local choicelist = {}
	for i = 1,3,1 do 
		local random1 = math.random(1, #allchoicelist)
		table.insert(choicelist, allchoicelist[random1])
		table.remove(allchoicelist, random1)
	end
				
	local choice = room:askForChoice(source, "chanlidanxin_reward", table.concat(choicelist, "+"))
	local msg = sgs.LogMessage()
	msg.type = "#chanlidanxin"
	msg.from = source
	msg.to:append(opponent)
	msg.arg = choice
	room:sendLog(msg)
	if choice == "CLDXR1" then
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 1
		room:recover(source, recover)
		source:drawCards(1)
	elseif choice == "CLDXR2" then
		source:drawCards(3)
	elseif choice == "CLDXR5" then
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 2
		room:recover(source, recover)
		room:askForDiscard(source, "chanlidanxin_reward", 1, 1, false, true)
	elseif choice == "CLDXR6" then
		source:drawCards(5)
		room:askForDiscard(source, "chanlidanxin_reward", 3, 3, false, true)
	elseif choice == "CLDXR7" then
		source:drawCards(5)
		opponent:drawCards(2)
	elseif choice == "CLDXR12" then
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = source:getMaxHp() - source:getHp()
		room:recover(source, recover)
		room:askForDiscard(source, "chanlidanxin_reward", 1, 1, false, true)
	elseif choice == "CLDXR13" then
		room:askForDiscard(source, "chanlidanxin_reward", 2, 2, false, true)
		source:setFlags("rewardextraround")
	elseif choice == "CLDXR14" then
		source:drawCards(1)
		opponent:turnOver()
	elseif choice == "CLDXR15" then
		source:drawCards(1)
		room:damage(sgs.DamageStruct("chanlidanxin_reward", source, opponent, 1, sgs.DamageStruct_Normal))
	elseif choice == "CLDXR17" then
		room:loseHp(source, 1)
		source:drawCards(5)
	elseif choice == "CLDXR18" then
		room:loseHp(source, (source:getHp()-1))
		source:drawCards(7)
	elseif choice == "CLDXR19" then
		room:askForDiscard(source, "chanlidanxin_reward", 1, 1, false, true)
		room:damage(sgs.DamageStruct("chanlidanxin_reward", source, opponent, 2, sgs.DamageStruct_Normal))
	elseif choice == "CLDXR3" or choice == "CLDXR4" then
		source:drawCards(1)
		local ids = room:getDrawPile()
		local ids_2 = room:getDiscardPile()
		for i2 = 1, 100,1 do
			local id
			if (i2) <= ids:length() then
				id = ids:at(i2-1)
			else
				id = ids_2:at(i2-1-ids:length())
			end
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Weapon") and choice == "CLDXR4" then
				local use = sgs.CardUseStruct()
				use.card = card
				use.from = source
				if source:isAlive() then
					room:useCard(use)
					break
				end
			elseif card:isKindOf("Armor") and choice == "CLDXR3" then
				local use = sgs.CardUseStruct()
				use.card = card
				use.from = source
				if source:isAlive() then
					room:useCard(use)
					break
				end
			end
		end
	elseif choice == "CLDXR8" or choice == "CLDXR9" then
		local n = 0
		local ids = room:getDrawPile()
		local ids_2 = room:getDiscardPile()
		for i2 = 1, 100,1 do
			local id
			if (i2) <= ids:length() then
				id = ids:at(i2-1)
			else
				id = ids_2:at(i2-1-ids:length())
			end
			local card = sgs.Sanguosha:getCard(id)
			if n == 3 then
				break 
			elseif card:isKindOf("Weapon") and (choice == "CLDXR8" or choice == "CLDXR9") and n ~= 2 then
				local use = sgs.CardUseStruct()
				use.card = card
				use.from = source
				n  = n + 2
				if source:isAlive() then
					room:useCard(use)
				end
			elseif ((card:isKindOf("Armor") and choice == "CLDXR8") or (card:isKindOf("DefensiveHorse") and choice == "CLDXR9")) and n ~= 1 then
				local use = sgs.CardUseStruct()
				use.card = card
				use.from = source
				n = n + 1
				if source:isAlive() then
					room:useCard(use)
				end
			end
		end
	elseif choice == "CLDXR11" or choice == "CLDXR16" then
		local n
		if choice == "CLDXR11" then
			n = 2
		else
			n = 5
		end
		local ids_move = sgs.IntList()
		local ids = room:getDrawPile()
		local ids_2 = room:getDiscardPile()
		for i2 = 1, 100,1 do
			local id
			if (i2) <= ids:length() then
				id = ids:at(i2-1)
			else
				id = ids_2:at(i2-1-ids:length())
			end
			local card = sgs.Sanguosha:getCard(id)
			if n == 0 then
				break
			elseif card:isKindOf("TrickCard") and choice == "CLDXR11" and n ~= 0 then
				n  = n - 1
				ids_move:append(card:getEffectiveId())
			elseif card:isKindOf("BasicCard") and choice == "CLDXR16" and n ~= 0 then
				n  = n - 1
				ids_move:append(card:getEffectiveId())
			end
		end
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids_move
		move.to = source
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move, true)
	end	
end

nl_chanlidanxin = sgs.CreateTriggerSkill{
	name = "#nl_chanlidanxin",
	events = {sgs.AskForPeachesDone,sgs.EventPhaseChanging,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local thread = room:getThread()
		local s
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getRole() == "loyalist" then
				s = p
			end
		end
		local r
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getRole() == "rebel" then
				r = p
			end
		end
		if event == sgs.AskForPeachesDone then
			local death = data:toDeath()
			if player:getHp() <= 0 and player:getRole() == "rebel" then 
				if s:getMark("game") == 6 then
					room:doLightbox("$chanlidanxinlimitwin", 3000)
					room:gameOver("loyalist")
				elseif s:getMark("game") == 5 then
					player:throwAllEquips()
					if not player:isKongcheng() then
						room:throwCard(player:wholeHandCards(), player)
					end

					for _, mark in sgs.list(player:getMarkNames()) do
						if player:getMark(mark) > 0 then
							if (not string.find(mark, "AG_")) then
								room:setPlayerMark(player, mark, 0)
							end
						end
					end
					room:setPlayerMark(player, "@goochi", 0)
					room:setPlayerMark(player, "@junlve", 0)
					room:setPlayerMark(player, "@benxi", 0)
					room:setPlayerMark(player, "@tongue", 0)
					room:setPlayerMark(player, "@ranshang", 0)

					for _, card in sgs.qlist(player:getJudgingArea()) do
						if not card:isKindOf("SkillCard") then 
							room:throwCard(card, player)
						end
					end
					room:setPlayerMark(s, "game", s:getMark("game") + 1)
					room:doLightbox("$chanlidanxinlimit"..s:getMark("game"), 3000)
					room:doSuperLightbox("str_tsaiyan","str_tsaiyan")
					room:doLightbox("$chanlidanxinstr_tsaiyan_limit", 3000)
					room:changeHero(player, "str_tsaiyan", true, true, false, true)
					room:setTag("FirstRound" , sgs.QVariant(true))
					player:drawCards(2)
					thread:trigger(sgs.GameStart, room, s, data)
					thread:trigger(sgs.DrawInitialCards, room, s, data)
					thread:trigger(sgs.AfterDrawInitialCards, room, s, data)

					thread:trigger(sgs.GameStart, room, r, data)
					thread:trigger(sgs.DrawInitialCards, room, r, data)
					thread:trigger(sgs.AfterDrawInitialCards, room, r, data)
					room:setTag("FirstRound" , sgs.QVariant(false))
					room:throwEvent(sgs.TurnBroken)
				else
					local hclist = {5,5,6,6}
					local hplist = {0,1,1,2}
					player:throwAllEquips()
					if not player:isKongcheng() then
						room:throwCard(player:wholeHandCards(), player)
					end

					for _, mark in sgs.list(player:getMarkNames()) do
						if player:getMark(mark) > 0 then
							if (not string.find(mark, "AG_")) then
								room:setPlayerMark(player, mark, 0)
							end
						end
					end

					for _,sk in sgs.qlist(player:getVisibleSkillList()) do
						if not sk:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() then
							room:handleAcquireDetachSkills(player,"-"..sk:objectName())
						end
					end
					
					local list = sgs.Sanguosha:getRandomGenerals(3)
					local general_name = room:askForGeneral(s, table.concat(list, "+"))
					room:changeHero(player, general_name, true, true, false, true)
					--重置自身武將
					--room:changeHero(s, s:getGeneralName(), false, true, false, true)
					
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+hplist[s:getMark("game")]))
					room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp()))
					room:setTag("FirstRound" , sgs.QVariant(true))
					player:drawCards(hclist[s:getMark("game")])
					room:setTag("FirstRound" , sgs.QVariant(false))
					chanlidanxin_reward(s,player)
					room:setPlayerMark(s, "game", s:getMark("game") + 1)
					room:doLightbox("$chanlidanxinlimit"..s:getMark("game"), 3000)

					thread:trigger(sgs.GameStart, room, s, data)
					--thread:trigger(sgs.GameStart, room, r, data)
					if room:getCurrent():objectName() == r:objectName() then
						s:setFlags("OpponentStart")
					end
					room:throwEvent(sgs.TurnBroken)
					if r:hasFlag("OpponentStart") then
						room:setTag("ExtraTurn",sgs.QVariant(true))
						r:gainAnExtraTurn()
						room:setTag("ExtraTurn",sgs.QVariant(false))
						r:setFlags("-OpponentStart")
					end
				end
			elseif player:getHp() <= 0 and player:getRole() == "loyalist" then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart then
				if s:getMark("game") == 0 then
					local list = sgs.Sanguosha:getRandomGenerals(3)
					local general_name = room:askForGeneral(player, table.concat(list, "+"))
					room:changeHero(r, general_name, true, false, false, false)
					room:setPlayerProperty(r, "hp", sgs.QVariant(r:getMaxHp()))
					room:setPlayerMark(s, "game", s:getMark("game") + 1)
					room:doLightbox("$chanlidanxinlimit"..1, 3000)
					room:setPlayerMark(s, "gameMode_noOx", 1)
					room:setPlayerMark(r, "gameMode_noOx", 1)
					thread:trigger(sgs.GameStart, room, s, data)
					thread:trigger(sgs.GameStart, room, r, data)
					room:setTag("FirstRound" , sgs.QVariant(true))
					s:drawCards(4)
					r:drawCards(4)
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if phase == sgs.Player_Finish then
				if s:hasFlag("rewardextraround") then
					room:setTag("ExtraTurn",sgs.QVariant(true))
					s:gainAnExtraTurn()
					room:setTag("ExtraTurn",sgs.QVariant(false))
					s:setFlags("-rewardextraround")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
if not sgs.Sanguosha:getSkill("#nl_chanlidanxin") then skills:append(nl_chanlidanxin) end

sgs.LoadTranslationTable{
	["$chanlidanxinlimit1"] = "第一關--東嶺關",
	["$chanlidanxinlimit2"] = "第二關--洛陽",
	["$chanlidanxinlimit3"] = "第三關--汜水關",
	["$chanlidanxinlimit4"] = "第四關--滎陽",
	["$chanlidanxinlimit5"] = "第五關--滑州",
	["$chanlidanxinlimit6"] = "第六關--古城",
	["$chanlidanxinstr_tsaiyan_limit"] = "你敢殺我外甥，特來取你首級！",
	["$chanlidanxinlimitwin"] = "恭喜您成功通關，不愧是當世豪傑！！",
	["str_tsaiyan"] = "蔡陽",
	["chanlidanxin_reward"] = "獎勵",
	["#chanlidanxin"] = "%from “<font color=\"yellow\"><b>獎勵</b></font>”選擇了： %arg ",
	["CLDXR1"] = "回復1點體力，並摸1張牌",
	["CLDXR2"] = "摸3張牌",
	["CLDXR5"] = "回復2點體力，並棄置1張牌",
	["CLDXR6"] = "摸5張牌，然後棄置3張牌",
	["CLDXR7"] = "摸5張牌，然後敵方摸2張牌",
	["CLDXR12"] = "回復至滿體力，然後棄置一張牌",
	["CLDXR13"] = "棄置2張牌，在當前回合結束後，進行一次額外的回合",
	["CLDXR14"] = "摸1張牌，並使敵方翻面",
	["CLDXR15"] = "摸1張牌，對敵方造成1點傷害",
	["CLDXR17"] = "流失1點體力，摸五張牌",
	["CLDXR18"] = "流失體力至1點，然後摸七張牌",
	["CLDXR19"] = "棄1張牌，對敵方造成2點傷害",
	["CLDXR3"] = "隨機裝備一個防具牌，並摸1張牌",
	["CLDXR4"] = "隨機裝備一個武器牌，並摸1張牌",
	["CLDXR8"] = "隨機裝備一個武器牌，和一個防具牌",
	["CLDXR9"] = "裝備一個防禦坐騎牌，和一個武器牌",
	["CLDXR11"] = "隨機獲得兩張錦囊牌",
	["CLDXR16"] = "隨機獲得五張基本牌",
}

--歡樂成雙
nl_fun2vs2 = sgs.CreateTriggerSkill{
	name = "#nl_fun2vs2",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			if player:getMark("AG_firstplayer") > 0 then
				local now = player:getNextAlive()
				room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
				room:setPlayerMark(now, "AG_firstplayer", 1)
				if room:getCurrent():objectName() == player:objectName() then
					room:setPlayerMark(now, "@stop_invoke", 1)
				end
			end
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == player:getRole() then
					p:drawCards(1)
				end
			end
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
				card_remover:trigger(sgs.GameStart, room, player, data)
				local i = 1
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					i = i + 1
					if i == 2 or i == 3 then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					elseif i == 4 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for i = 1, 4, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end
				local i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					choosenewgeneral(p, 10,false,{})
				end
				for _, p in sgs.qlist(_targets) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				for _, p in sgs.qlist(_targets) do
					room:setTag("FirstRound" , sgs.QVariant(true))
					i = i + 1
					if i == 1 then
						p:drawCards(3)
					elseif i == 2 or i == 3 then
						p:drawCards(4)
					elseif i == 4 then
						p:drawCards(5)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_fun2vs2") then skills:append(nl_fun2vs2) end

--殭屍模式
--主公忠臣為人類。反賊和內奸為喪屍，其中反賊的勝利條件為殺死所有人類，內奸則無勝利條件，但可以通過殺死一名人類來變成反賊。
--任意玩家殺死殭屍時，該玩家摸3張牌，生命值回復至上限。
--殭屍玩家殺死人類時，該人類玩家在死亡後成為內奸復活，生命上限為殺死他的殭屍玩家的生命上限的一半（向上去整）。復活時該玩家生命值回復至上限，主武將不變、副武將為殭屍。之後殺死人類的殭屍玩家身份若為內奸，則該玩家身份變為反賊。
--未說明的情況下，按標準三人局進行獎懲。
nl_ZonbieMode = sgs.CreateTriggerSkill{
	name = "#nl_ZonbieMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.BuryVictim},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				if player:getMark("AG_hasExecuteStart") == 0 then
					local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
					card_remover:trigger(sgs.GameStart, room, player, data)

					room:setPlayerProperty(player, "role", sgs.QVariant("lord"))
					room:updateStateItem()
					room:resetAI(player)


					local _targets = sgs.SPlayerList()
					local lwtarget1 = player
					for ii = 1, 8, 1 do
						_targets:append(lwtarget1)
						lwtarget1 = lwtarget1:getNextAlive()
					end

					for _, p in sgs.qlist(_targets) do
						room:setPlayerMark(p, "AG_hasExecuteStart", 1)
						choosenewgeneral(p, 10,false,{})
					end

					for _, p in sgs.qlist(_targets) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					end


					for _, p in sgs.qlist(_targets) do
						p:drawCards(4)
					end

					for i = 1,2,1 do
						local all_alive_players = {}
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:getMark("Zombie_die") == 0 then
								table.insert(all_alive_players, p)
							end
						end
						local random_target = all_alive_players[math.random(1, #all_alive_players)]
						room:addPlayerMark(random_target,"Zombie_die")
					end

					room:setPlayerMark(player, "AG_firstplayer", 1)
					room:setPlayerMark(player, "@clock_time", 1)
				end

				if player:getMark("Zombie_die") > 0 then
					room:killPlayer(player)
					room:revivePlayer(player)
					room:setPlayerProperty(player, "role", sgs.QVariant("rebel"))
					room:updateStateItem()
					room:resetAI(player)
					local n = player:getMaxHp()+1
					room:changeHero(player, "zombie", true, false, true, true)
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(n))
					room:setPlayerProperty(player, "hp", sgs.QVariant(n))
				end

			end
		elseif event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			if player:getMark("AG_firstplayer") > 0 then
				local now = player:getNextAlive()
				room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
				room:setPlayerMark(now, "AG_firstplayer", 1)
				if room:getCurrent():objectName() == player:objectName() then
					room:setPlayerMark(now, "@stop_invoke", 1)
				end
			end

			if reason then
				local killer = reason.from
				if killer:hasSkill(self:objectName()) then
					if player:getRole() == "rebel" then
						if (killer:getMaxHp() - killer:getHp() > 0) then
							local theRecover2 = sgs.RecoverStruct()
							theRecover2.recover = (killer:getMaxHp() - killer:getHp())
							theRecover2.who = killer
							room:recover(killer, theRecover2)
						end
					elseif (killer:getRole() == "rebel" or killer:getRole() == "renegade") and player:getRole() == "loyalist" then
						room:revivePlayer(player)
						room:changeHero(player, "zombie", true, false, true, true)
						room:setPlayerProperty(player, "maxhp", sgs.QVariant((killer:getMaxHp()+1)/2))
						room:setPlayerProperty(player, "hp", sgs.QVariant((killer:getMaxHp()+1)/2))
						room:setPlayerProperty(player, "role", sgs.QVariant("renegade"))
						room:acquireSkill(player, "#nl_ZonbieMode")
						room:updateStateItem()
						room:resetAI(player)
						if killer:getRole() == "renegade" then
							room:setPlayerProperty(killer, "role", sgs.QVariant("rebel"))
							room:updateStateItem()
							room:resetAI(killer)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("#nl_ZonbieMode") then skills:append(nl_ZonbieMode) end
sgs.LoadTranslationTable{
	["#ZonbieMode"] = "<font color=\"yellow\"><b> %from </b></font>受到殭屍攻擊，失去理智變成了殭屍",
}

--天梯

--選將
--變更武將函數（4V4天梯版本）
function choosenewgeneral4V4(source, n)
	local room = source:getRoom()
	local Chosens = {}

	local generals = {}
	local all_generals = {"sunquan","zhenji","diaochan","sunshangxiang","huangyueying","zhugeliang",
	"caocao_po","super_liubei","simayi","guanyu_po","zhouyu","lvbu_po","zhangfei_po","zhangliao_po",
"zhaoyun_po","xuchu_po","machao","ganning","guojia_po","st_xushu","lidian","xiahoudun_po","lvmeng_po",
"diaochan_po","xiahouyuan","ol_xiaoqiao","ol_huangzhong","dianwei_po","pangtong_po","taishici","wolong_po",
"ol_pangde","dongzhuo","jiaxu","sunjian","xuhuang","jiangwei","sunce","wangping","sunliang","wangji","yanyan",
"chengong","zhangchunhua","fazheng","lingtong","wuguotai",
"caozhi","xusheng","xunyou","zhonghui","ol_wangyi","madai","bulianshi","handang",
"fuhuanghou","liru","jianyong","yufan","liufeng","jvshou","caifuren","guyong","zhoucang","sunluban",
"gongsunyuan","liuchen","xiahoushi","sunxiu","quancong","liyan","sundeng","cenhun","guohuanghou",
"caiyong","wuxian","liuxie","yuejin_po","caoang","hetaihou_po","simalang","mayunlu","zhugejin",
"zhugeke","dingfeng","heqi","chengyu","wenpin","sp_wenpin","guanyinping","kanze","quyi","dongbai",
"litong","yangxiu","sunqian","sunhao","xiahouba","liuqi","luzhi","zhugeguo","sec_tangzi","whlw_guosi","caohong",
"mazhong"}
	local banned = {}

	for i=1, #all_generals, 1 do
		local can_use = true
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == all_generals[i] then
				can_use = false
			end
			if p:getGeneral2() and p:getGeneral2Name() == all_generals[i] then
				can_use = false
			end
		end
		if table.contains(banned, all_generals[i])then
			can_use = false
		end

		if can_use then
			table.insert(generals, all_generals[i])
		end
	end

	for i = 1, n, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end
	local general = room:askForGeneral(source, table.concat(Chosens, "+"))
	room:changeHero(source, general, false,false, false,false)
	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end

--對戰
nl_tanti4vs4 = sgs.CreateTriggerSkill{
	name = "#nl_tanti4vs4",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use_player = room:getPlayers():at(0)
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			if player:getMark("AG_firstplayer") > 0 then
				local now = player:getNextAlive()
				room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
				room:setPlayerMark(now, "AG_firstplayer", 1)
				if room:getCurrent():objectName() == player:objectName() then
					room:setPlayerMark(now, "@stop_invoke", 1)
				end
			end

			if player:getMark("@LordMark") == 1 and player:getRole() == "rebel" then
				room:gameOver("loyalist")
			elseif player:getMark("@LordMark") == 1 and player:getRole() == "loyalist" then
				room:gameOver("rebel")
			end
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						local n = 0
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getRole() == killer:getRole() then
								n = n - 1
							elseif p:getRole() ~= killer:getRole() then
								n = n + 1
							end
						end
						if player:getRole() ~= killer:getRole() then
							if n > 0 then
								killer:drawCards(2+n)
							else
								killer:drawCards(2)
							end
						elseif player:getRole() == killer:getRole() then
							killer:throwAllHandCardsAndEquips()
						end
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local cold_seat = {1,3,5,7,1,3,6,8,1,4,5,8,1,4,6,8,1,4,6,7}
				local warm_seat = {2,4,6,8,2,4,5,7,2,3,6,7,2,3,5,7,2,3,5,8}
				local realcold_seat = {}
				local realwarm_seat = {}
				local seat_type = math.random(1,5)
				for i= 0, 3 do
  					table.insert(realcold_seat, cold_seat[4*seat_type-i])
  					table.insert(realwarm_seat, warm_seat[4*seat_type-i])
				end   
				local i = 0
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for j = 1, 8, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end
				local cold_lord = realcold_seat[math.random(1,4)]
				local warm_lord = realwarm_seat[math.random(1,4)]
				for _,p in sgs.qlist(_targets) do
					i = i + 1
					if i == realcold_seat[1] or i == realcold_seat[2] or i == realcold_seat[3] or i == realcold_seat[4] then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
						if i == cold_lord then
							room:setPlayerMark(p, "@LordMark", 1)
						end
					elseif i == realwarm_seat[1] or i == realwarm_seat[2] or i == realwarm_seat[3] or i == realwarm_seat[4] then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
						if i == warm_lord then
							room:setPlayerMark(p, "@LordMark", 1)
						end
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					if use_player:getRole() == p:getRole() then
						choosenewgeneral4V4(p, 5)
					else
						choosenewgeneral4V4(p, 5)
					end
					if p:getMark("@LordMark") == 1 then
						local general = sgs.Sanguosha:getGeneral(p:getGeneralName())
						room:setPlayerProperty(p,"maxhp",sgs.QVariant(p:getMaxHp()+1))
						room:setPlayerProperty(p,"hp",sgs.QVariant(p:getMaxHp()))
					end
				end
				for _, p in sgs.qlist(_targets) do
					if p:getMark("@LordMark") > 0 then
						local lord = {}
						for _, skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
							if skill:isLordSkill() and not p:hasLordSkill(skill:objectName()) and not p:isLord() then
								table.insert(lord, skill:objectName())
							end
						end
						room:handleAcquireDetachSkills(p, table.concat(lord, "|"))
					end
				end
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "gameMode_noOx", 1)
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				local i = 0
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					room:setTag("FirstRound" , sgs.QVariant(true))
					if i == 1 then
						p:drawCards(3)
					elseif i == 8 then
						p:drawCards(5)
					else
						p:drawCards(4)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_tanti4vs4") then skills:append(nl_tanti4vs4) end

--手殺兩軍對壘三大戰役
--合肥之戰
nl_HefeiBattle = sgs.CreateTriggerSkill{
	name = "#nl_HefeiBattle",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local s = room:findPlayerBySkillName(self:objectName())
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and s:getMark("AG_hasExecuteStart") == 0 then
				local i = 1
				for _,p in sgs.qlist(room:getOtherPlayers(s)) do
					i = i + 1
					if i == 2 or i == 3 then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					elseif i == 4 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local _targets = sgs.SPlayerList()
				local lwtarget1 = s
				for i = 1, 4, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				local i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					room:setTag("FirstRound" , sgs.QVariant(true))
					i = i + 1
					if i == 1 then
						p:drawCards(3)
						room:changeHero(p, "lingtong", true, true, false, true)
						room:acquireSkill(p, "olzishou")
						room:acquireSkill(p, "tiaoxin")
					elseif i == 2 then
						p:drawCards(4)
						room:changeHero(p, "lidian", true, true, false, true)
						room:detachSkillFromPlayer(p, "xunxun")
						room:acquireSkill(p, "crt_yingjian")
						room:acquireSkill(p, "str_jungduang")
					elseif i == 3 then
						p:drawCards(4)
						room:changeHero(p, "zhangliao", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(3))
						room:setPlayerProperty(p, "hp", sgs.QVariant(3))
						room:handleAcquireDetachSkills(p,"-".."tuxi")
						room:acquireSkill(p, "mashu")
						room:acquireSkill(p, "yingzi")
						room:acquireSkill(p, "pojun")
					elseif i == 4 then
						p:drawCards(5)
						room:changeHero(p, "ganning", true, true, false, true)
						room:handleAcquireDetachSkills(p,"-".."qixi")
						room:handleAcquireDetachSkills(p,"-".."fenwei")
						room:acquireSkill(p, "spzhenwei")
						room:acquireSkill(p, "str_lichung")
						room:acquireSkill(p, "jiang")
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
				

			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_HefeiBattle") then skills:append(nl_HefeiBattle) end

--荊州之戰
nl_JingzhouBattle = sgs.CreateTriggerSkill{
	name = "#nl_JingzhouBattle",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local s = room:findPlayerBySkillName(self:objectName())
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and s:getMark("AG_hasExecuteStart") == 0 then
				local i = 1
				for _,p in sgs.qlist(room:getOtherPlayers(s)) do
					i = i + 1
					if i == 2 or i == 3 then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					elseif i == 4 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local _targets = sgs.SPlayerList()
				local lwtarget1 = s
				for i = 1, 4, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				local i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					i = i + 1
					room:setTag("FirstRound" , sgs.QVariant(true))
					if i == 1 then
						p:drawCards(3)
						room:changeHero(p, "guanyu", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(5))
						room:setPlayerProperty(p, "hp", sgs.QVariant(5))
						room:acquireSkill(p, "olzishou")
						room:acquireSkill(p, "zhongyong")
					elseif i == 2 then
						p:drawCards(4)
						room:changeHero(p, "caoren", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(1))
						room:setPlayerProperty(p, "hp", sgs.QVariant(1))
						room:acquireSkill(p, "buqu")
						room:acquireSkill(p, "qiuyuan")
					elseif i == 3 then
						p:drawCards(4)
						room:changeHero(p, "lvmeng", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(4))
						room:setPlayerProperty(p, "hp", sgs.QVariant(4))
						room:handleAcquireDetachSkills(p,"-".."keji")
						room:handleAcquireDetachSkills(p,"-".."qinxue")
						room:acquireSkill(p, "gongxin")
						room:acquireSkill(p, "duodao")
						room:acquireSkill(p, "huituo")
						room:acquireSkill(p, "dujin")
					elseif i == 4 then
						p:drawCards(5)
						room:changeHero(p, "guanping", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(5))
						room:acquireSkill(p, "suishi")
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
				

			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_JingzhouBattle") then skills:append(nl_JingzhouBattle) end
--赤壁之戰
nl_ChibiBattle = sgs.CreateTriggerSkill{
	name = "#nl_ChibiBattle",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local i = 1
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					i = i + 1
					if i == 2 or i == 3 or i == 6 then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					elseif i == 4 or i == 5 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for i = 1, 6, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				local i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					i = i + 1
					if i == 1 then
						room:changeHero(p, "caocao", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(6))
						room:setPlayerProperty(p, "hp", sgs.QVariant(6))
						room:handleAcquireDetachSkills(p,"-".."jianxiong")
						room:handleAcquireDetachSkills(p,"-".."hujia")
						room:acquireSkill(p, "jigong")
						room:acquireSkill(p, "junbing")
						room:acquireSkill(p, "lianhuo")
					elseif i == 2 then
						room:changeHero(p, "zhugeliang", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(4))
						room:setPlayerProperty(p, "hp", sgs.QVariant(4))
						room:handleAcquireDetachSkills(p,"-".."guanxing")
						room:handleAcquireDetachSkills(p,"-".."kongcheng")
						room:acquireSkill(p, "yingyuan")
						room:acquireSkill(p, "shuimeng")
						room:acquireSkill(p, "lianhuan")
					elseif i == 3 then
						room:changeHero(p, "zhouyu", true, true, false, true)
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(4))
						room:setPlayerProperty(p, "hp", sgs.QVariant(4))
						room:handleAcquireDetachSkills(p,"-".."yingzi")
						room:handleAcquireDetachSkills(p,"-".."fanjian")
						room:acquireSkill(p, "jianshu")
						room:acquireSkill(p, "chouce")
						room:acquireSkill(p, "huoji")
					elseif i == 4 or i == 5 then
						choosenewgeneral(p, 5 , "wei",{})
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
					elseif i == 6 then
						choosenewgeneral(p, 5 , "wu",{})
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
					end
				end
				for _, p in sgs.qlist(_targets) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(_targets) do
					p:drawCards(4)
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_ChibiBattle") then skills:append(nl_ChibiBattle) end

--2019龍舟
str_example2019 = sgs.General(extension, "str_example2019", "tan", "12",  true, true,true)
--選將
function choosenewgeneralforboat_kingdom(source, n, kingdom)
	local room = source:getRoom()
	local Chosens = {}
	local old_zuoci = room:findPlayerBySkillName("huashen")
	local Huashens1 = {}--获取山包左慈的化身武将
	if old_zuoci and old_zuoci:isAlive() then
		local Hs_String1 = old_zuoci:getTag("Huashens"):toString()
		if Hs_String1 and Hs_String1 ~= "" then
			Huashens1 = Hs_String1:split("+")
		end
	end
	local all_generals = {"nos_caocao","nos_simayi","nos_xiahoudun","nos_zhangliao","nos_xuchu","nos_guojia","nos_liubei","nos_guanyu","nos_zhangfei"
				,"nos_zhaoyun","nos_machao","nos_huangyueying","nos_ganning","nos_lvmeng","nos_huanggai","nos_luxun","nos_zhouyu"
				,"nos_daqiao","nos_huatuo","nos_lvbu","nos_diaochan","zhenji","liubei","sunquan","xiahouyuan","weiyan","zhangjiao"
				,"xiaoqiao","zhoutai","zhurong","sunjian","lusu","jiaxu","dongzhuo","xunyu","dianwei","pangtong","taishici"
				,"yanliangwenchou","pangde","dengai","jiangwei","sunce","erzhang","gongsunzan","yuanshu","sp_guanyu","str_qunmachao"}
	local generals = {}
	
	for i=1, #all_generals, 1 do
		local can_use = true
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == all_generals[i] then
				can_use = false
			end
			if p:getGeneral2() and p:getGeneral2Name() == all_generals[i] then
				can_use = false
			end
		end
		if table.contains(banned, all_generals[i])then
			can_use = false
		end

		if table.contains(AG_allbanlist, all_generals[i])then
			can_use = false
		end

		if table.contains(Huashens1, all_generals[i])then
			can_use = false
		end

		local general = sgs.Sanguosha:getGeneral(all_generals[i])
		if can_use and table.contains(kingdom, general:getKingdom()) then
			table.insert(generals, all_generals[i])
		end
	end

	all_generals = nil

	for i = 1, n, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end
	local general = room:askForGeneral(source, table.concat(Chosens, "+"))
	room:changeHero(source, general, false,false, false,false)
	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end

--技能
--魏業：回合開始時，你可以棄置一張牌，然後令一名其他勢力角色選擇一項：棄置一張牌，令你摸一張牌。
weikingdomskillfirstcard = sgs.CreateSkillCard{
	name = "weikingdomskillfirstcard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self,room,source,targets)
		room:notifySkillInvoked(source, "weikingdomskillfirst")
		room:broadcastSkillInvoke("weikingdomskillfirst")
		if not room:askForDiscard(targets[1], self:objectName(), 1, 1, true, true,"@gushePunish:"..source:objectName())then
			room:drawCards(source, 1, "weikingdomskillfirst")
		end
	end
}

weikingdomskillfirstvs = sgs.CreateViewAsSkill{
	name = "weikingdomskillfirst" ,
	response_pattern = "@@weikingdomskillfirst",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = weikingdomskillfirstcard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())			
		return card
	end,
}

weikingdomskillfirst = sgs.CreateTriggerSkill{
	name = "weikingdomskillfirst",
	events = {sgs.EventPhaseStart},
	view_as_skill = weikingdomskillfirstvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and not player:isKongcheng() then
			room:askForUseCard(player,"@@weikingdomskillfirst","@weikingdomskillfirst", -1, sgs.Card_MethodDiscard)	
		end
		return false
	end
}


--蜀義：你使用【殺】上限+1；出牌階段結束時，若你於此階段使用【殺】次數不少於2，摸一張牌。
shukingdomskillfirst = sgs.CreateTriggerSkill{
	name = "shukingdomskillfirst",
	events = {sgs.CardUsed,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and player:getPhase() == sgs.Player_Play then
				if use.card:isKindOf("Slash") then
					room:setPlayerMark(player, "shukingdomskillfirst", player:getMark("shukingdomskillfirst") + 1) 
				end
			end
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Play then
				if player:getMark("shukingdomskillfirst") >= 2 then
					room:sendCompulsoryTriggerLog(player, "shukingdomskillfirst")
					player:drawCards(1)
				end
				room:setPlayerMark(player, "shukingdomskillfirst", 0) 
			end
		end
	end,
}
shukingdomskillfirstTM = sgs.CreateTargetModSkill{
	name = "#shukingdomskillfirstTM",
	frequency = sgs.Skill_Frequent,
	pattern = "Slash",
	residue_func = function(self, from, card)
		if from:hasSkill("shukingdomskillfirst") then
			return 1
		else
			return 0
		end
	end,
}
--吳耀：回合結束時，若你的手牌數不等於你的體力值，則你摸一張牌。
wukingdomskillfirst = sgs.CreateTriggerSkill{
	name = "wukingdomskillfirst",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				if player:getHp() ~= player:getHandcardNum() then
					room:sendCompulsoryTriggerLog(player, "wukingdomskillfirst")
					player:drawCards(1)
				end
			end
		end
	end,
}
--群心：鎖定技，棄牌階段開始時，若你的手牌數比體力值多2或更多，你本回合手牌上限+1；若你已損失體力值大於1，你手牌上限+1。
qunkingdomskillfirst = sgs.CreateMaxCardsSkill{
	name = "qunkingdomskillfirst", 
	extra_func = function(self, target)
		if target:hasSkill("qunkingdomskillfirst") then
			local i = 0
			if target:getHandcardNum() - target:getHp() >= 2 then
				i = i + 1
			end
			if target:isWounded() then
				i = i + 1
			end
			return i
		end
	end
}

--晉勢：摸牌階段結束時，你可以展示你摸的牌，若這些牌的花色均不同，你摸一張牌
jinkingdomskillfirst = sgs.CreateTriggerSkill{
	name = "jinkingdomskillfirst",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Draw and move.to and move.to:objectName() == player:objectName() and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW 
			  and move.to_place == sgs.Player_PlaceHand and move.reason.m_skillName ~= "jinkingdomskillfirst" then
				local ids = sgs.IntList()
				local suits = {}
				local can_invoke = true
				for _,id in sgs.qlist(move.card_ids) do
					ids:append(id)
					if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuit()) then
						table.insert(suits, sgs.Sanguosha:getCard(id):getSuit())
					else
						can_invoke = false
					end
				end
				if can_invoke then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:fillAG(ids)
						room:getThread():delay()
						room:clearAG()
						player:drawCards(1, self:objectName())
					end
				end
			end
		end
		return false
	end
}


--許昌：你受到傷害後，摸一張牌。
weikingdomskillsecond = sgs.CreateTriggerSkill{
	name = "weikingdomskillsecond",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		room:sendCompulsoryTriggerLog(player, "weikingdomskillsecond")
		player:drawCards(1)
	end
}
--成都：你使用【殺】造成傷害後，摸一張牌。
shukingdomskillsecond = sgs.CreateTriggerSkill{
	name = "shukingdomskillsecond",
	events = {sgs.Damage},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card:isKindOf("Slash") then
			room:sendCompulsoryTriggerLog(player, "shukingdomskillsecond")
			player:drawCards(1)
		end
	end
}
--武昌：你使用每一張裝備牌，摸一張牌。
wukingdomskillsecond = sgs.CreateTriggerSkill{
	name = "wukingdomskillsecond",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("EquipCard") then
				room:sendCompulsoryTriggerLog(player, "wukingdomskillsecond")
				player:drawCards(1)
			end
		end
	end,
}
--鄴城：你使用錦囊牌指定其他角色為目標後，摸一張牌。
qunkingdomskillsecond = sgs.CreateTriggerSkill{
	name = "qunkingdomskillsecond" ,
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if use.card:isKindOf("TrickCard") and (not use.to:contains(player) or use.to:length() >= 2) then 
				room:sendCompulsoryTriggerLog(player, "qunkingdomskillsecond")
				player:drawCards(1)
			end
		end
	end
}

--洛陽：回合結束時，若你手牌的花色數小於3，你摸一張牌。

jinkingdomskillsecond = sgs.CreateTriggerSkill{
	name = "jinkingdomskillsecond",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			local suits = {}
			for _,card in sgs.qlist(player:getHandcards()) do
				if not table.contains(suits, card:getSuit()) then
					table.insert(suits, card:getSuit())
				end
			end
			if #suits < 3 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:drawCards(1)
				end
			end
		end
		return false
	end
}


if not sgs.Sanguosha:getSkill("weikingdomskillfirst") then skills:append(weikingdomskillfirst) end
if not sgs.Sanguosha:getSkill("shukingdomskillfirst") then skills:append(shukingdomskillfirst) end
if not sgs.Sanguosha:getSkill("#shukingdomskillfirstTM") then skills:append(shukingdomskillfirstTM) end
if not sgs.Sanguosha:getSkill("wukingdomskillfirst") then skills:append(wukingdomskillfirst) end
if not sgs.Sanguosha:getSkill("qunkingdomskillfirst") then skills:append(qunkingdomskillfirst) end
if not sgs.Sanguosha:getSkill("jinkingdomskillfirst") then skills:append(jinkingdomskillfirst) end
if not sgs.Sanguosha:getSkill("weikingdomskillsecond") then skills:append(weikingdomskillsecond) end
if not sgs.Sanguosha:getSkill("shukingdomskillsecond") then skills:append(shukingdomskillsecond) end
if not sgs.Sanguosha:getSkill("wukingdomskillsecond") then skills:append(wukingdomskillsecond) end
if not sgs.Sanguosha:getSkill("qunkingdomskillsecond") then skills:append(qunkingdomskillsecond) end
if not sgs.Sanguosha:getSkill("jinkingdomskillsecond") then skills:append(jinkingdomskillsecond) end

sgs.LoadTranslationTable{
	["weikingdomskillfirst"] = "魏業",
	[":weikingdomskillfirst"] = "回合開始時，你可以棄置一張牌，然後令一名其他勢力角色選擇一項：棄置一張牌，令你摸一張牌。",
	["@weikingdomskillfirst"] = "你可以棄置一張牌，然後令一名其他勢力角色選擇一項：棄置一張牌，令你摸一張牌。",
	["~weikingdomskillfirst"] = "選擇一張牌->選擇一名角色->點擊確定",
	["shukingdomskillfirst"] = "蜀義",
	[":shukingdomskillfirst"] = "你使用【殺】上限+1；出牌階段結束時，若你於此階段使用【殺】次數不少於2，摸一張牌。",
	["wukingdomskillfirst"] = "吳耀",
	[":wukingdomskillfirst"] = "回合結束時，若你的手牌數不等於你的體力值，則你摸一張牌。",
	["qunkingdomskillfirst"] = "群心",
	[":qunkingdomskillfirst"] = "鎖定技，棄牌階段開始時，若你的手牌數比體力值多2或更多，你本回合手牌上限+1；若你已損失體力值大於1，你手牌上限+1。",
	["jinkingdomskillfirst"] = "晉勢",
	[":jinkingdomskillfirst"] = "摸牌階段結束時，你可以展示你摸的牌，若這些牌的花色均不同，你摸一張牌。",

	["weikingdomskillsecond"] = "許昌",
	[":weikingdomskillsecond"] = "你受到傷害後，摸一張牌。",
	["shukingdomskillsecond"] = "成都",
	[":shukingdomskillsecond"] = "你使用【殺】造成傷害後，摸一張牌。",
	["wukingdomskillsecond"] = "武昌",
	[":wukingdomskillsecond"] = "你使用每一張裝備牌，摸一張牌。",
	["qunkingdomskillsecond"] = "鄴城",
	[":qunkingdomskillsecond"] = "你使用錦囊牌指定其他角色為目標後，摸一張牌。",
	["jinkingdomskillsecond"] = "洛陽",
	[":jinkingdomskillsecond"] = "回合結束時，若你手牌的花色數小於3，你摸一張牌。",
}

--總技能
nl_2019BoatMode = sgs.CreateTriggerSkill{
	name = "#nl_2019BoatMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeachesDone,sgs.BuryVictim,sgs.EventPhaseChanging,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeachesDone then
			local death = data:toDeath()

			if player:getMark("AG_firstplayer") > 0 then
				local now = player:getNextAlive()
				room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
				room:setPlayerMark(now, "AG_firstplayer", 1)
				if room:getCurrent():objectName() == player:objectName() then
					room:setPlayerMark(now, "@stop_invoke", 1)
				end
			end

			if player:getHp() <= 0 and player:getRole() == "rebel" then
				local no_rebel = true
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "rebel" and p ~= player then
						no_rebel = false
					end
				end
				if no_rebel then
					local realplayer
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("RealPlayer") == 1 then
							realplayer = p
						end
					end
					if realplayer:getMark("@game") < 3 then
						player:throwAllEquips()
						if not player:isKongcheng() then
							room:throwCard(player:wholeHandCards(), player)
						end
						for _, card in sgs.qlist(player:getJudgingArea()) do
							if not card:isKindOf("SkillCard") then 
								room:throwCard(card, player)
							end
						end
						for _,sk in sgs.qlist(player:getVisibleSkillList()) do
							if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() then
								room:handleAcquireDetachSkills(player,"-"..sk:objectName())
							end
						end

						local _targets = sgs.SPlayerList()
		
						local i = 0
						for _, p in sgs.qlist(room:getPlayers()) do
							i = i + 1
							if not p:isAlive() and ((i < 7 and realplayer:getMark("@game") == 1) or realplayer:getMark("@game") == 2) then	
								room:revivePlayer(p)
							end 
						end

						local kingdom_list = {"wei","shu","wu","qun","jin"}
						local player_kingdom_list = {}
						table.removeOne(kingdom_list,realplayer:getKingdom())
						table.insert(player_kingdom_list, realplayer:getKingdom())
						table.insert(player_kingdom_list, realplayer:getKingdom())
						for j = 1, 3, 1 do
							local teamkingdom = kingdom_list[math.random(1,#kingdom_list)]
							table.insert(player_kingdom_list, teamkingdom)
							table.insert(player_kingdom_list, teamkingdom)
							if #kingdom_list > 0 then
								table.removeOne(kingdom_list, teamkingdom)
							end
						end
	
						local i = 0
						for _, p in sgs.qlist(room:getPlayers()) do
							i = i + 1
							if p:isAlive() and (i == 1 or i == 2) then
								if player_kingdom_list[i] == "wei" then
									if realplayer:getMark("@game") == 2 then
										room:acquireSkill(p, "weikingdomskillsecond")
									end
								elseif player_kingdom_list[i] == "shu" then
									if realplayer:getMark("@game") == 2 then
										room:acquireSkill(p, "shukingdomskillsecond")
									end
								elseif player_kingdom_list[i] == "wu" then
									if realplayer:getMark("@game") == 2 then
										room:acquireSkill(p, "wukingdomskillsecond")
									end
								elseif player_kingdom_list[i] == "qun" then
									if realplayer:getMark("@game") == 2 then
										room:acquireSkill(p, "qunkingdomskillsecond")
									end
								elseif player_kingdom_list[i] == "jin" then
									if realplayer:getMark("@game") == 2 then
										room:acquireSkill(p, "jinkingdomskillsecond")
									end
								end
							end
							if p:isAlive() and (i > 2) then
								if player_kingdom_list[i] == "wei" then
									choosenewgeneralforboat_kingdom(p, 1 , {"wei", "wei2", "god"})
									room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
								elseif player_kingdom_list[i] == "shu" then
									choosenewgeneralforboat_kingdom(p, 1 , {"shu", "shu2", "god"})
									room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
								elseif player_kingdom_list[i] == "wu" then
									choosenewgeneralforboat_kingdom(p, 1 , {"wu", "wu2", "god"})
									room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
								elseif player_kingdom_list[i] == "qun" then
									choosenewgeneralforboat_kingdom(p, 1 , {"qun", "qun2", "qun3", "god"})
									room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
								elseif player_kingdom_list[i] == "qun" then
									choosenewgeneralforboat_kingdom(p, 1 , {"jin", "god"})
									room:setPlayerProperty(p,"kingdom",sgs.QVariant("jin"))
								end
								room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
								room:setPlayerMark(p, "AG_hasExecuteStart", 1)
								room:setPlayerFlag(p,"new_enter_game")
								room:acquireSkill(p, "#nl_2019BoatMode")
								room:acquireSkill(p, "#nl_2019BoatModeskip")
							end
						end
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasFlag("new_boatmode") then
								room:getThread():trigger(sgs.GameStart, room, p, data)
								getqixing(p)
								room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
							end
						end
						room:setPlayerMark(player, "AG_firstplayer", 1)
						room:setPlayerMark(player, "@clock_time", 1)
						room:setTag("FirstRound" , sgs.QVariant(true))
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasFlag("new_boatmode") then
								p:drawCards(4)
								room:setPlayerFlag(p,"-new_enter_game")
							end
						end
						room:setTag("FirstRound" , sgs.QVariant(false))


						room:setPlayerMark(realplayer, "@jumpend", 1)
						room:setPlayerMark(realplayer, "@game", realplayer:getMark("@game") + 1)
						room:doLightbox("$nl_2019BoatMode"..realplayer:getMark("@game"), 3000)
	
						room:getThread():trigger(sgs.GameStart, room, realplayer, data)
						getqixing(realplayer)
						room:getThread():delay(1000)
						room:throwEvent(sgs.TurnBroken)
					end
				end
			end 
		elseif event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						if killer:getRole() == "loyalist" then
							if player:getRole() == "loyalist" then
					
							elseif player:getRole() == "rebel" then
								killer:drawCards(2)
							end
						end
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				local realplayer
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("RealPlayer") == 1 then
						realplayer = p
					end
				end
				if realplayer:getMark("@game") == 3 then
					room:doLightbox("$nl_2019BoatModewin", 3000)
					room:gameOver("loyalist")
				end
			elseif rebel_win then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local i = 1
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					i = i + 1
					if i == 2 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					else
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local kingdom_list = {"wei","shu","wu","qun"}
				local player_kingdom_list = {}

				for j = 1, 4, 1 do
					local teamkingdom = kingdom_list[math.random(1,#kingdom_list)]
					table.insert(player_kingdom_list, teamkingdom)
					table.insert(player_kingdom_list, teamkingdom)
					table.removeOne(kingdom_list, teamkingdom)
				end

				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for i = 1, 8, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				local i = 0
				room:setPlayerMark(player, "RealPlayer", 1)
				room:setPlayerMark(player, "@game", 1)
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					i = i + 1
					if i > 4 then
						room:killPlayer(p)
					end
				end
				local i = 0
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					if p:isAlive() and (i == 1 or i == 2) then
						room:setTag("FirstRound" , sgs.QVariant(true))
						if player_kingdom_list[i] == "wei" then
							choosenewgeneral(p, 5 , {"wei", "wei2", "god", "tan"},{}, s)
							p:drawCards(4)
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
						elseif player_kingdom_list[i] == "shu" then
							choosenewgeneral(p, 5 , {"wei", "wei2", "god"},{}, s)
							p:drawCards(4)
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
						elseif player_kingdom_list[i] == "wu" then
							choosenewgeneral(p, 5 , {"wei", "wei2", "god"},{}, s)
							p:drawCards(4)
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
						elseif player_kingdom_list[i] == "qun" then
							choosenewgeneral(p, 5 , {"wei", "wei2", "god"},{}, s)
							p:drawCards(4)
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
						elseif player_kingdom_list[i] == "jin" then
							choosenewgeneral(p, 5 , {"jin", "god"},{}, s)
							p:drawCards(4)
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("jin"))
						end
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()+1))
						room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))

						if player_kingdom_list[i] == "wei" then
							room:acquireSkill(p, "weikingdomskillfirst")
						elseif player_kingdom_list[i] == "shu" then
							room:acquireSkill(p, "shukingdomskillfirst")
							room:acquireSkill(p, "#shukingdomskillfirstTM")
						elseif player_kingdom_list[i] == "wu" then
							room:acquireSkill(p, "wukingdomskillfirst")
						elseif player_kingdom_list[i] == "qun" then
							room:acquireSkill(p, "qunkingdomskillfirst")
						elseif player_kingdom_list[i] == "jin" then
							room:acquireSkill(p, "jinkingdomskillfirst")
						end
					end
					if p:isAlive() and (i > 2) then
						if player_kingdom_list[i] == "wei" then
							choosenewgeneralforboat_kingdom(p, 5 , {"wei", "wei2", "god"})
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
						elseif player_kingdom_list[i] == "shu" then
							choosenewgeneralforboat_kingdom(p, 5 , {"shu", "shu2", "god"})
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
						elseif player_kingdom_list[i] == "wu" then
							choosenewgeneralforboat_kingdom(p, 5 , {"wu", "wu2", "god"})
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
						elseif player_kingdom_list[i] == "qun" then
							choosenewgeneralforboat_kingdom(p, 5 , {"qun", "qun2", "qun3", "god"})
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
						elseif player_kingdom_list[i] == "jin" then
							choosenewgeneralforboat_kingdom(p, 5 , {"jin", "god"})
							room:setPlayerProperty(p,"kingdom",sgs.QVariant("jin"))
						end
					end
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					p:drawCards(4)
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
				room:doLightbox("$nl_2019BoatMode"..realplayer:getMark("@game"), 3000)

			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
nl_2019BoatModeskip = sgs.CreateTriggerSkill{
	name = "#nl_2019BoatModeskip",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_RoundStart then
				local breakphase = 0
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("@jumpend") == 1 then
						breakphase = 1
					end
				end
				if breakphase == 1 then
					if player:getMark("@jumpend") == 1 then
						room:setPlayerMark(player, "@jumpend", 0)
					else
						room:getThread():delay(1000)
						room:throwEvent(sgs.TurnBroken)
					end
				end
			end
		end
	end,

}

if not sgs.Sanguosha:getSkill("#nl_2019BoatMode") then skills:append(nl_2019BoatMode) end
if not sgs.Sanguosha:getSkill("#nl_2019BoatModeskip") then skills:append(nl_2019BoatModeskip) end
sgs.LoadTranslationTable{
	["$nl_2019BoatMode1"] = "第一關",
	["$nl_2019BoatMode2"] = "第二關",
	["$nl_2019BoatMode3"] = "第三關",
	["$nl_2019BoatModewin"] = "恭喜通關",
}

--2V2大決戰
nl_kingdom2vs2 = sgs.CreateTriggerSkill{
	name = "#nl_kingdom2vs2",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == player:getRole() then
					p:drawCards(1)
					if p:getKingdom() == "wei" then
						room:acquireSkill(p, "weikingdomskillsecond")
					elseif p:getKingdom() == "shu" then
						room:acquireSkill(p, "shukingdomskillsecond")
					elseif p:getKingdom() == "wu" then
						room:acquireSkill(p, "wukingdomskillsecond")
					elseif p:getKingdom() == "qun" then
						room:acquireSkill(p, "qunkingdomskillsecond")
					elseif p:getKingdom() == "jin" then
						room:acquireSkill(p, "jinkingdomskillsecond")
					end
				end
			end
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local i = 1
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					i = i + 1
					if i == 2 or i == 3 then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					elseif i == 4 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for i = 1, 4, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end
				local kingdom_list = {"wei","shu","wu","qun","jin"}
				local player_kingdom_list = {}

				local teamkingdom1 = kingdom_list[math.random(1,#kingdom_list)]
				table.insert(player_kingdom_list, teamkingdom1)
				table.removeOne(kingdom_list, teamkingdom1)

				local teamkingdom2 = kingdom_list[math.random(1,#kingdom_list)]
				table.insert(player_kingdom_list, teamkingdom2)
				table.insert(player_kingdom_list, teamkingdom2)
				table.insert(player_kingdom_list, teamkingdom1)

				local i = 0
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					if player_kingdom_list[i] == "wei" then
						choosenewgeneral(p, 8 , {"wei", "wei2", "god"},{})
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
					elseif player_kingdom_list[i] == "shu" then
						choosenewgeneral(p, 8 , {"shu", "shu2", "god"},{})
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
					elseif player_kingdom_list[i] == "wu" then
						choosenewgeneral(p, 8 , {"wu", "wu2", "god"},{})
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
					elseif player_kingdom_list[i] == "qun" then
						choosenewgeneral(p, 8 , {"qun", "qun2", "qun3", "god"},{})
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
					elseif player_kingdom_list[i] == "jin" then
						choosenewgeneral(p, 8 , {"jin", "god"},{})
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("jin"))
					end

					if player_kingdom_list[i] == "wei" then
						room:acquireSkill(p, "weikingdomskillfirst")
					elseif player_kingdom_list[i] == "shu" then
						room:acquireSkill(p, "shukingdomskillfirst")
						room:acquireSkill(p, "#shukingdomskillfirstTM")
					elseif player_kingdom_list[i] == "wu" then
						room:acquireSkill(p, "wukingdomskillfirst")
					elseif player_kingdom_list[i] == "qun" then
						room:acquireSkill(p, "qunkingdomskillfirst")
					elseif player_kingdom_list[i] == "jin" then
						room:acquireSkill(p, "jinkingdomskillfirst")
					end
				end

				for _, p in sgs.qlist(_targets) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)

				room:setTag("FirstRound" , sgs.QVariant(true))
				local i = 0
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					if i == 1 then
						p:drawCards(3)
					elseif i == 2 or i == 3 then
						p:drawCards(4)
					elseif i == 4 then
						p:drawCards(5)
					end
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_kingdom2vs2") then skills:append(nl_kingdom2vs2) end

--歡樂成雙 天梯版

--選將
--變更武將函數（2V2天梯版本）
function choosenewgeneral2V2(source, n)
	local room = source:getRoom()
	local Chosens = {}

	local generals = {}
	local all_generals = {"zhangrang","caoying","zhangqiying","whlw_lijue","ol_caochun",
	"ol_maliang","xurong","sunshangxiang_po","ol_zhuzhi","ol_caorui","zhangxiu","zhugezhan_sec_rev",
	"mizhu",
	"lvbu_po","haozhao","chenlin","zhangsong","simahui","ol_caoren","wanglang","xiahoudun_po",
"zhugeliang_po","chengyu","liuxie","huatuo","guojia_po","sunqian","zhangjiao_po","ol_lukang",
"liru","bgm_zhaoyun","fazheng","liubei","ganning","handang","kuaiyuekuailiang",
"ol_xiahouyuan","diaochan","nos_daqiao","caopi","kanze","sunquan","jvshou",
"madai","manchong","zhenji","gaoshun","beimihu","luxun","zhugeke","lingtong","guotufengji",
"xunyu","liyan","dongzhuo","third_rev_sunluyu","machao","nos_huanggai","nos_simayi",
"sunshangxiang","lidian","taishici","zhangjiao","yanyan","ol_masu","xunyou","fuhuanghou",
"hanhaoshihuan",
"ol_caozhen","ol_caoxiu","yj_xiahoushi","sunxiu","sunziliufang","xinxianying","fuwan",
"jsp_sunshangxiang","ol_pangde","ol_machao",
"zhugejin","ol_zumao","sp_wenpin","wutugu","ol_mayunlu","yanbaihu","litong",
"zhugeguo","wangyun","sec_tangzi","sec_sufei",
"sec_huangquan","whlw_fanchou","whlw_guosi","nos_guanyu","nos_zhangfei",
"nos_lvmeng","lvmeng","nos_zhouyu","nos_machao","nos_xiahoudun","ol_xiaoqiao",
"sunjian","zhurong","menghuo","sunliang","caozhang","liaohua","huaxiong_po",
"sunluban","yangxiu","ol_zhangbao","sp_yuejin","sp_panfeng","zhugedan","sunhao","shixie",
"tadun","guansuo","baosanniang","simalang","zhaoxiang"}
	local banned = {}
	for i=1, #all_generals, 1 do
		local can_use = true
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == all_generals[i] then
				can_use = false
			end
			if p:getGeneral2() and p:getGeneral2Name() == all_generals[i] then
				can_use = false
			end
		end
		if table.contains(banned, all_generals[i])then
			can_use = false
		end
		
		if table.contains(AG_allbanlist, all_generals[i])then
			can_use = false
		end

		if can_use then
			table.insert(generals, all_generals[i])
		end
	end

	all_generals = nil

	local general = room:askForGeneral(source, table.concat(Chosens, "+"))
	room:changeHero(source, general, false,false, false,false)
	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end

nl_tanti2vs2 = sgs.CreateTriggerSkill{
	name = "#nl_tanti2vs2",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == player:getRole() then
					p:drawCards(1)
				end
			end
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
				card_remover:trigger(sgs.GameStart, room, player, data)
				local i = 1
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					i = i + 1
					if i == 2 or i == 3 then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					elseif i == 4 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for i = 1, 4, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end
				local i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					choosenewgeneral2V2(p, 5)
				end
				for _, p in sgs.qlist(_targets) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				for _, p in sgs.qlist(_targets) do
					room:setTag("FirstRound" , sgs.QVariant(true))
					i = i + 1
					if i == 1 then
						p:drawCards(3)
					elseif i == 2 or i == 3 then
						p:drawCards(4)
					elseif i == 4 then
						p:drawCards(5)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_tanti2vs2") then skills:append(nl_tanti2vs2) end

nl_pktest = sgs.CreateTriggerSkill{
	name = "#nl_pktest",
	events = {sgs.AskForPeachesDone,sgs.EventPhaseChanging,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local thread = room:getThread()
		if event == sgs.AskForPeachesDone then
			local death = data:toDeath()
			player:gainMark("@death",1)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
				p:throwAllHandCardsAndEquips()
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				p:drawCards(4)
			end

		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
if not sgs.Sanguosha:getSkill("#nl_pktest") then skills:append(nl_pktest) end

--神武再臨

--Boss技能
--燭陰


zhuyin = sgs.General(extension,"zhuyin","qun","4",true,true,true)

xiongshou = sgs.CreateTriggerSkill{
	name = "xiongshou" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and (damage.to:getHp() < damage.from:getHp()) then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#xiongshou"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
				end
			end
		end
	end
}

xiongshouDis = sgs.CreateDistanceSkill{
	name = "#xiongshouDis",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return  -1
		else
			return 0
		end
	end  
}
zhuyin:addSkill(xiongshou)
zhuyin:addSkill(xiongshouDis)

sgs.LoadTranslationTable{
	["zhuyin"] = "燭陰",
	["xiongshou"] = "凶獸",
	["#xiongshouDis"] = "凶獸",
	["#xiongshou"] = "%from 的“<font color=\"yellow\"><b>凶獸</b></font>”效果被觸發，傷害從 %arg 點增加至 %arg2 點",
	[":xiongshou"] = "鎖定技，當你使用【殺】對體力值小於你的角色造成傷害時，傷害值+1；鎖定技，你與其他角色的距離-1；鎖定技，你不能翻面。",
}
--混沌
hundun = sgs.General(extension,"hundun","qun","19",true,true,true)

wuzang = sgs.CreateTriggerSkill{
	name = "wuzang",
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
					local n = math.max(player:getHp()/2,5)
					player:drawCards(n)
				end
			end
		end
	end
}

wuzang_Maxcards = sgs.CreateMaxCardsSkill{
	name = "#wuzang_Maxcards",
	extra_func = function(self, target)
		if target:hasSkill("wuzang") then
			return -999
		end
	end
}

xiangde = sgs.CreateTriggerSkill{
	name = "xiangde" ,
	frequency = sgs.Skill_Frequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.from and damage.from:getWeapon() then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#xiangde"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
				if damage.damage < 1 then return true end
			end
		end			
	end,
}

yinzei = sgs.CreateMasochismSkill{
	name = "yinzei" ,
	on_damaged = function(self, target, damage)
		local room = target:getRoom()
		if damage.from then
			if target:isKongcheng() then
				local loot_cards = sgs.QList2Table(damage.from:getCards("he"))
				if #loot_cards > 0 then
					room:throwCard(loot_cards[math.random(1, #loot_cards)], damage.from,target)
				end
			end
		end
	end
}

hundun:addSkill(wuzang)
hundun:addSkill(wuzang_Maxcards)
hundun:addSkill(xiangde)
if not sgs.Sanguosha:getSkill("yinzei") then skills:append(yinzei) end

sgs.LoadTranslationTable{
	["hundun"] = "混沌",
	["wuzang"] = "無臟",
	[":wuzang"] = "鎖定技，摸牌階段開始時，你放棄摸牌，然後摸X張牌；鎖定技，你的手牌上限為0。（X為你的體力值的一半且至少為5）",
	["xiangde"] = "相德",
	[":xiangde"] = "鎖定技，當其他角色對你造成傷害時，若其裝備區裡有武器牌，傷害值+1。",
	["#xiangde"] = "%from 的“<font color=\"yellow\"><b>相德</b></font>”效果被觸發，傷害從 %arg 點增加至 %arg2 點",
	["yinzei"] = "隱賊",
	[":yinzei"] = "鎖定技，當其他角色對你造成傷害後，若你沒有手牌，隨機棄置其一張牌。",
}

qiongqi = sgs.General(extension,"qiongqi","qun","15",true,true,true)

zhue = sgs.CreateTriggerSkill{
	name = "zhue" ,
	events = {sgs.Damage} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("zhue") then 
					p:drawCards(1)
					player:drawCards(1)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player ~= nil
	end,
}

futai = sgs.CreateTriggerSkill{
	name = "futai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					local recover = sgs.RecoverStruct()
					recover.who = p
					room:recover(p, recover)
				end
			end
		end
	end,
}

futaiPS = sgs.CreateProhibitSkill{
	name = "futaiPS" ,
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		local futai_ps = false 
		for _, p in sgs.qlist(from:getAliveSiblings()) do
			if p:hasSkill("futai") and p:getPhase() == sgs.Player_NotActive then
				futai_ps = true
			end
		end
		if futai_ps and card:isKindOf("Peach") then
			return true
		end
	end
}

yandu = sgs.CreatePhaseChangeSkill{
	name = "yandu",
	frequency = sgs.Skill_Compulsory,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasSkill("yandu") then
				if p:canDiscard(player, "he") then
					local id = room:askForCardChosen(player, damage.to, "he", "jielve")
					room:obtainCard(p, id, true)
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getPhase() == sgs.Player_NotActive
		and target:getMark("damage_point_round") == 0
	end
}

qiongqi:addSkill(zhue)
qiongqi:addSkill(futai)
if not sgs.Sanguosha:getSkill("yandu") then skills:append(yandu) end
if not sgs.Sanguosha:getSkill("futaiPS") then skills:append(futaiPS) end

sgs.LoadTranslationTable{
["qiongqi"] = "窮奇",
["zhue"] = "助惡",
[":zhue"] = "鎖定技，當其他角色造成傷害後，你與其各摸一張牌。",
["futai"] = "復態",
[":futai"] = "鎖定技，其他角色於你的回合外不能使用【桃】；鎖定技，回合開始時，所有角色各回復1點體力。",
["yandu"] = "厭篤",
[":yandu"] = "鎖定技，其他角色的回合結束後，若其於此回合內未造成過傷害，你獲得其一張牌。",
}

taowu = sgs.General(extension,"taowu","qun","15",true,true,true)

mingwan = sgs.CreateTriggerSkill{
	name = "mingwan" ,
	events = {sgs.Damage,sgs.CardUsed} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			if player:getMark("ming_source-Clear") == 0 and player:getPhase() == sgs.Player_Play then
				local damage = data:toDamage()
				if damage.to and damage.to:isAlive() then
					
					room:sendCompulsoryTriggerLog(player, "mingwan") 			

					room:doAnimate(1, player:objectName(), damage.to:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					room:setPlayerMark(damage.to,"ming_source-Clear",1)
					room:setPlayerMark(damage.to,"@ming-Clear",1)
				end
			end
		elseif event == sgs.CardUsed then
			if player:getMark("ming_source-Clear") > 0 and player:getPhase() == sgs.Player_Play then
				player:drawCards(1)
			end
		end
	end
}
mingwanPS = sgs.CreateProhibitSkill{
	name = "#mingwanPS" ,
	frequency = sgs.Skill_Compulsory ,
	is_prohibited = function(self, from, to, card)
		return from:hasSkill("mingwan") and from:getMark("ming_source-Clear") > 0 and (not to:getMark("@ming-Clear") > 0) and (not card:isKindOf("SkillCard"))
	end
}

nitai = sgs.CreateTriggerSkill{
	name = "nitai",
	events = {sgs.DamageInflicted},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:getPhase() == sgs.Player_NotActive and damage.nature == sgs.DamageStruct_Fire then
				damage.damage = damage.damage + 1

				local msg = sgs.LogMessage()
				msg.type = "#nitai"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	

				data:setValue(damage)
			elseif player:getPhase() ~= sgs.Player_NotActive then

				local msg = sgs.LogMessage()
				msg.type = "#AvoidDamage"
				msg.from = player
				msg.to:append(damage.from)
				msg.arg = self:objectName()
				msg.arg2 = damage.nature
				room:sendLog(msg)

				return true
			end
			return false
		end
	end,

}

luanchang = sgs.CreateTriggerSkill{
	name = "luanchang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local players = sgs.SPlayerList()
				local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not player:isProhibited(p, archery_attack) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					archery_attack:setSkillName("luanchang")
					local use = sgs.CardUseStruct()
					use.card = archery_attack
					use.from = player
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end
			elseif player:getPhase() == sgs.Player_Finish then
				local players = sgs.SPlayerList()
				local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not player:isProhibited(p, savage_assault) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					savage_assault:setSkillName("luanchang")
					local use = sgs.CardUseStruct()
					use.card = savage_assault
					use.from = player
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end
			end		
		end
	end,
}

taowu:addSkill(mingwan)
taowu:addSkill(mingwanPS)
taowu:addSkill(nitai)
if not sgs.Sanguosha:getSkill("luanchang") then skills:append(luanchang) end

sgs.LoadTranslationTable{
["taowu"] = "檮杌",
["mingwan"] = "冥頑",
[":mingwan"] = "鎖定技，當你於回合內使用牌對其他角色造成傷害後，你令其於此回合內擁有“冥”標記；鎖定技，若有角色有“冥”標記，沒有“冥”標記的其他角色不是你使用牌的合法目標；鎖定技，當你使用牌時，若有角色有“冥”標記，你摸一張牌。",
["nitai"] = "擬態",
[":nitai"] = "鎖定技，當你受到傷害時，若於你的回合：內，防止此傷害；外且為火焰傷害，傷害值+1。",
["#nitai"] = "%from 的“<font color=\"yellow\"><b>擬態</b></font>”效果被觸發，傷害從 %arg 點增加至 %arg2 點",
["luanchang"] = "亂常",
[":luanchang"] = "鎖定技，回合開始時，你視為使用【南蠻入侵】；回合結束時，你視為使用【萬箭齊發】。",
}

taotie = sgs.General(extension,"taotie","qun","19",true,true,true)

tanyu = sgs.CreateTriggerSkill{
	name = "tanyu",
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to	
			if phase == sgs.Player_Discard then
				if not player:isSkipped(sgs.Player_Discard) then
					player:skip(sgs.Player_Discard)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local player_card = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					table.insert(player_card, p:getHandcardNum())
				end
				if player:getHandcardNum() == math.max(unpack(player_card)) then
					room:loseHp(player,1)
				end
			end
		end
	end,
}

cangmu = sgs.CreateTriggerSkill{
	name = "cangmu",
	frequency = sgs.Skill_Compulsory,	
	events = {sgs.DrawNCards},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			local count = room:alivePlayerCount()
			data:setValue(count)
		end
	end,
}

jicai = sgs.CreateTriggerSkill{
	name = "jicai" ,
	events = {sgs.HpRecover} ,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("jicai") then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), math.random(5,6))
					room:notifySkillInvoked(p,self:objectName())
					p:drawCards(1)
				end
			end
			player:drawCards(1)
		end
	end
}

taotie:addSkill(tanyu)
taotie:addSkill(nitai)
if not sgs.Sanguosha:getSkill("jicai") then skills:append(jicai) end

sgs.LoadTranslationTable{
["taotie"] = "饕餮",
["tanyu"] = "貪欲",
[":tanyu"] = "鎖定技，你跳過棄牌階段；鎖定技，結束階段開始時，若你為手牌數最多的角色，你失去1點體力。",
["cangmu"] = "藏目",
[":cangmu"] = "鎖定技，你的額定摸牌數為X。（X為角色數）",
["jicai"] = "積財",
[":jicai"] = "鎖定技，當一名角色回復體力後，你與其各摸一張牌。",
["$GodModelimit"] = "啊啊啊啊啊啊",
}

sgs.LoadTranslationTable{
["boss_xiangliu"] = "相柳",
["boss_yaoshou"] = "妖獸",
[":boss_yaoshou"] = "鎖定技，你與其他角色計算-2。",
["boss_duqu"] = "毒軀",
[":boss_duqu"] = "鎖定技，你受到傷害時，傷害來源獲得1枚「蛇毒」標記；你自身不會擁有「蛇毒」標記；你的「桃」均視為「殺」。「蛇毒」標記：鎖定技，擁有「蛇毒」標記的角色回合開始時，需要選擇棄置X張牌或者失去X點體力，然後棄置一枚「蛇毒」標記。X為其擁有的「蛇毒」標記個數。",
["boss_shedu"] = "蛇毒",
["boss_jiushou"] = "九首",
[":boss_jiushou"] = "鎖定技，你的手牌上限始終為9，你的出牌階段開始時以及你的回合結束時，將手牌補至手牌上限，你始終跳過你的摸牌階段。",
["boss_echou"] = "惡臭",
[":boss_echou"] = "體力值首次減少至一半或更少時激活此技能。鎖定技，除你之外的其他角色使用「桃」或「酒」時，獲得1枚「蛇毒」標記。",
}

sgs.LoadTranslationTable{
["boss_zhuyan"] = "朱厭",
["boss_yaoshou"] = "妖獸",
[":boss_yaoshou"] = "鎖定技，你與其他角色計算-2。",

["boss_bingxian"] = "兵燹",
[":boss_bingxian"] = "鎖定技，其他角色的回合結束時，若其回合內沒有使用殺，則視為你對其使用一張「殺」。",
["boss_juyuan"] = "巨猿",
[":boss_juyuan"] = "鎖定技，你的體力上限+5，你的出牌階段內，若你的體力少於上一次你的回合結束時的體力，則你本回合使用「殺」可額外指定1個目標。",
["boss_xushi"] = "蓄勢",
[":boss_xushi"] = "體力值首次減少至一半或更少時激活此技能。鎖定技，你的出牌階段結束時，你令自己翻面；當你的武將牌從背面翻至正面時，對所有其他角色造成隨機1至2點傷害。",

}

sgs.LoadTranslationTable{
["boss_bifang"] = "畢方",
["boss_yaoshou"] = "妖獸",
[":boss_yaoshou"] = "鎖定技，你與其他角色計算-2。",

["boss_zhaohuo"] = "兆火",
[":boss_zhaohuo"] = "鎖定技，你造成的所有傷害均視為火屬性傷害；你的回合中，所有其他角色的防具牌無效；你免疫所有火屬性傷害。",
["boss_honglianx"] = "紅蓮",
[":boss_honglianx"] = "鎖定技，你的紅色牌不計入你的手牌上限；你的回合開始時，隨機獲得牌堆中0到3張紅色牌，然後隨機對3到0名其他角色各造成1點火屬性傷害。",
["boss_yanyu"] = "炎獄",
[":boss_yanyu"] = "體力值首次減少至一半或更少時激活此技能。鎖定技，其他角色回合開始時進行判定，若為紅色則受到1點火屬性傷害，並重復此過程（每個回合最多判定3次）。",
}

sgs.LoadTranslationTable{
["boss_yingzhao"] = "英招",
["boss_yaoshou"] = "妖獸",
[":boss_yaoshou"] = "鎖定技，你與其他角色計算-2。",
["boss_fengdong"] = "封凍",
[":boss_fengdong"] = "鎖定技，你的回合內，其他角色的非鎖定技無效。",
["boss_xunyou"] = "巡遊",
[":boss_xunyou"] = "鎖定技，其他角色回合開始時，你隨機獲得場上除你以外的一名角色區域內的一張牌，若你獲得的是裝備牌，則你使用之。",
["boss_sipu"] = "司圃",
[":boss_sipu"] = "體力值首次減少至一半或更少時激活此技能。鎖定技，你的出牌階段內，若你使用的牌數小於等於2張，其他角色無法使用或打出牌。",
}

sgs.LoadTranslationTable{
["TheDayIBecomeAGod"] = "神殺",
["thedayibecomeagod"] = "傳承",
[":thedayibecomeagod"] = "選擇一名其他己方角色。若其勢力非神，則改為神勢力；若其勢力為神，則將武將牌翻至正面，回復體力至體力上限，並將手牌摸至5 ",
["gubuzifeng"] = "故步自封",
[":gubuzifeng"] = "出牌階段，對一名其他角色使用。其的一個隨機技能失效直到其下個回合結束。",
}

function choosenewgeneral_GodMode(source, n)
	local room = source:getRoom()
	local Chosens = {}

	local generals =  generate_all_general_list(source,false,{"zuoci","zuoci_po"})
	local all_generals = sgs.Sanguosha:getLimitedGeneralNames()

	for i = 1, n, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end
	local godlist = {"shenguanyu","shenzhouyu","shenlvbu","new_godzhaoyun","shenzhugeliang"
	,"shenlvmeng","ol_shencaocao","shensimayi_po","shenganning"
,"shenluxun_sec_rev"
,"shenliubei"
,"ol_shenzhangliao"}
	generals = {}
	for i=1, #godlist, 1 do
		local can_use = true
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == godlist[i] then
				can_use = false
			end
			if p:getGeneral2() and p:getGeneral2Name() == godlist[i] then
				can_use = false
			end
		end
		if table.contains(banned, godlist[i])then
			can_use = false
		end
		
		if table.contains(AG_allbanlist, godlist[i])then
			can_use = false
		end

		if can_use then
			table.insert(generals, godlist[i])
		end
	end

	for i = 1, 2, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end


	local general = room:askForGeneral(source, table.concat(Chosens, "+"))
	room:changeHero(source, general, false,false, false,false)
	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end

nl_GodMode = sgs.CreateTriggerSkill{
	name = "#nl_GodMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging,sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						if player:getGeneralName() == "zhuyin" and killer:getRole() == "rebel" then
							killer:drawCards(1)
							local recover = sgs.RecoverStruct()
							recover.who = killer
							room:recover(killer, recover)
						end
						if player:getRole() == "rebel" then
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if p:getRole() == "rebel" then
									if p:getKingdom() == "god" then
										p:drawCards(3)
									else
										p:drawCards(1)
									end
									local recover = sgs.RecoverStruct()
									recover.who = p
									room:recover(p, recover)
								end
							end
						end
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local i = 1
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for i = 1, 6, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				local i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					room:setPlayerMark(p, "gameMode_godMode", 1)
					i = i + 1
					if i == 4 or i == 6 then
						room:changeHero(p, "zhuyin", false,true, false,false)
					elseif i == 5 then
						local sks_all = {"hundun","qiongqi","taowu","taotie"}
						local sks = {}
						local random1 = math.random(1, #sks_all)
						table.insert(sks, sks_all[random1])
						local general = room:askForGeneral(p, table.concat(sks, "+"))
						room:changeHero(p, general, false,false, false,false)

						room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
					end
				end

				local i = 0
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					if i == 1 or i == 2 or i == 3 then
						choosenewgeneral_GodMode(p, 5)
					end
				end
				for _, p in sgs.qlist(_targets) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				--room:setPlayerMark(player, "AG_firstplayer", 1)
				--room:setPlayerMark(player, "@clock_time", 1)
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(_targets) do
					p:drawCards(4)
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
			end
		elseif event == sgs.HpChanged then
			if player:getGeneralName() == "hundun" then
				if player:getHp() <= (player:getMaxHp()/2) and player:getMark("GodMode_newskill") == 0 then
					room:doLightbox("$GodModelimit", 3000)
					room:acquireSkill(player, "yinzei")
					room:setPlayerMark(player,"GodMode_newskill",1)
				end
			elseif player:getGeneralName() == "qiongqi" then
				if player:getHp() <= (player:getMaxHp()/2) and player:getMark("GodMode_newskill") == 0 then
					room:doLightbox("$GodModelimit", 3000)
					room:acquireSkill(player, "yandu")
					room:setPlayerMark(player,"GodMode_newskill",1)
				end
			elseif player:getGeneralName() == "taowu" then
				if player:getHp() <= (player:getMaxHp()/2) and player:getMark("GodMode_newskill") == 0 then
					room:doLightbox("$GodModelimit", 3000)
					room:acquireSkill(player, "luanchang")
								room:setPlayerMark(player,"GodMode_newskill",1)
				end
			elseif player:getGeneralName() == "taotie" then
				if player:getHp() <= (player:getMaxHp()/2) and player:getMark("GodMode_newskill") == 0 then
					room:doLightbox("$GodModelimit", 3000)
					room:acquireSkill(player, "jicai")
					room:setPlayerMark(player,"GodMode_newskill",1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}
if not sgs.Sanguosha:getSkill("#nl_GodMode") then skills:append(nl_GodMode) end



--抗秦模式


xisheng = sgs.CreateViewAsSkill{
	name = "xisheng" ,
	n = 2,
	view_filter = function(self, selected, to_select)
		return (#selected < 2)
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
		return player:isWounded() and player:getMark("xisheng-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return  (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach"))) and player:getMark("xisheng-Clear") == 0
	end,
}

xishengstart = sgs.CreateTriggerSkill{
	name = "xishengstart" ,
	events = {sgs.CardFinished} ,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card then
			if use.card:getSkillName() == "xisheng" then
				room:setPlayerMark(player, "xisheng-Clear", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:isAlive()
	end,
}

shuluCard = sgs.CreateSkillCard{
	name = "shuluCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			room:drawCards(source, self:subcardsLength(), "shulu")
		end
	end
}
shulu = sgs.CreateViewAsSkill{
	name = "shulu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zhiheng_card = shuluCard:clone()
		for _,card in pairs(cards) do
			zhiheng_card:addSubcard(card)
		end
		zhiheng_card:setSkillName(self:objectName())
		return zhiheng_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#shuluCard") and player:canDiscard(player, "he")
	end,
}

function getskill_QinMode(zuoci,n,n2)
	local room = zuoci:getRoom()
	local all_sks = {"paoxiao", "kongcheng", "longdan", "nostieji", "xiaoji", "qingguo",
	"tiandu", "qixi", "nosqianxun", "liuli", "noskurou", "keji", 
"jijiu", "qingnang", "wushuang", "noslijian", "mashu", "ol_liegong", 
"ol_shensu", "ol_jushou", "hongyan", "tianxiang", "guidao", "qiangxi", "quhu", "jieming", "lianhuan",
"bazhen", "huoji", "kanpo",
"tianyi", "mengjin", "shuangxiong", "luanji", "ol_duanliang", "xingshang", "yinghun",
"jiuchi", "roulin","juxiang","lieren", "huoshou", "zaiqi", "wansha", "luanwu", "duanchang",
"god_yongsi", "qizhi", "ol_kuanggu", "qimou", "wushen", "shelie", "gongxin", 
"qinyin", "yeyan", "ol_guixin", "feiying", "juzhan", "feijun",
"wanglie","ol_rende", "guanxing_po", "jizhi_po", "qicai",
"jieyin_po", "biyue_po", "yaowu", "wusheng_po", "tishen_po", "yajiao", "zhuhai", "jianyan",
"fenwei", "yingzi", "fanjian", "guose","jianxiong_po", "fankui", "guicai","luoshen_po",
"new_juejing","new_longhun", "kuizhu", "chezheng",
"jianxiang", "shenshi", "chenglve", "ol_shicai", "cunmu", "zuilun_sec_rev", "fuyin_sec_rev", "qianjie",
"jueyan", "huairou", "zhengu", "xiongluan", "congjian", "longnu", "jieying", "wuniang", "jianjie",
"chenghao", "yinshi", "lingren", "fujian", "ol_shanjia","zhiheng_po","bf_jili","xiying"}
	local choose_sks = {}
	for i = 1,n,1 do 
		local random1 = math.random(1, #all_sks)
		table.insert(choose_sks, all_sks[random1])
		table.remove(all_sks, random1)
	end

	local use_player
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if not p:getAI() then
			use_player = p
			break
		end
	end


	for i = 1,n2,1 do
		if not use_player:getAI() then
			room:getThread():delay(1000)
		end
		local choice = room:askForChoice(use_player, "choose_skill", table.concat(choose_sks, "+"))			
		room:acquireSkill(zuoci, choice)
		table.removeOne(choose_sks, choice)
	end
end

change_bujiang = sgs.CreateTriggerSkill{
	name = "change_bujiang",
	events = {sgs.GameStart},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if sgs.GetConfig("bujiang", true) then
			if room:askForSkillInvoke(player, "change_bujiang", data) then
				local sks_all = {"bujiang_01","bujiang_02","bujiang_03","bujiang_04",
				"bujiang_05","bujiang_06","bujiang_07","bujiang_08",
				"bujiang_09","bujiang_10","bujiang_11","bujiang_12"}
				local sks = {}

				for i = 1,5,1 do 
					local random1 = math.random(1, #sks_all)
					table.insert(sks, sks_all[random1])
					table.remove(sks_all, random1)
				end
				local general = room:askForGeneral(player, table.concat(sks, "+"))
				room:changeHero(player, general, false,false, false,false)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 11,
}





if not sgs.Sanguosha:getSkill("xisheng") then skills:append(xisheng) end 
if not sgs.Sanguosha:getSkill("shulu") then skills:append(shulu) end 
--if not sgs.Sanguosha:getSkill("change_bujiang") then skills:append(change_bujiang) end 
if not sgs.Sanguosha:getSkill("xishengstart") then skills:append(xishengstart) end 


bujiang_01 = sgs.General(extension,"bujiang_01","god","4",true,true,true)
bujiang_02 = sgs.General(extension,"bujiang_02","god","4",false,true,true)
bujiang_03 = sgs.General(extension,"bujiang_03","god","4",true,true,true)
bujiang_04 = sgs.General(extension,"bujiang_04","god","4",false,true,true)
bujiang_05 = sgs.General(extension,"bujiang_05","god","4",true,true,true)
bujiang_06 = sgs.General(extension,"bujiang_06","god","4",false,true,true)
bujiang_07 = sgs.General(extension,"bujiang_07","god","4",true,true,true)
bujiang_08 = sgs.General(extension,"bujiang_08","god","4",false,true,true)
bujiang_09 = sgs.General(extension,"bujiang_09","god","4",true,true,true)
bujiang_10 = sgs.General(extension,"bujiang_10","god","4",false,true,true)
bujiang_11 = sgs.General(extension,"bujiang_11","god","4",true,true,true)
bujiang_12 = sgs.General(extension,"bujiang_12","god","4",false,true,true)



sgs.LoadTranslationTable{
	["bujiang_01"] = "羽林內軍",
	["bujiang_02"] = "傭兵",
	["bujiang_03"] = "常山府軍",
	["bujiang_04"] = "黑綢巫女",
	["bujiang_05"] = "江夏弓騎兵",
	["bujiang_06"] = "美人計",
	["bujiang_07"] = "步兵",
	["bujiang_08"] = "婆娑匠奴",
	["bujiang_09"] = "太行山豪俠",
	["bujiang_10"] = "武庫清點",
	["bujiang_11"] = "武林山隱伏",
	["bujiang_12"] = "血婆娑巧手",
	["choose_skill"] = "選擇技能",
	["xisheng"] = "犧牲",
	[":xisheng"] = "每名其他角色回合限一次，你可以將兩張牌當做【桃】使用。",
	["shulu"] = "熟慮",
	[":shulu"] = "出牌階段限一次，若你的手牌數大於體力值，你可以棄置一張牌，然後摸一張牌。",
	["bj_moredraw"] = "技型",
["bj_slashdraw"] = "速型",
["bj_startmoredraw"] = "天賦",
["bj_startequip"] = "天賦",
["bj_get_2skill"] = "天賦",
["bj_get_3skill"] = "天賦、強化",
[":bj_moredraw"] = "摸牌階段，你多摸一張牌",
[":bj_slashdraw"] = "出牌階段，你可以多使用一張「殺」",
[":bj_startmoredraw"] = "遊戲開始時，你多摸一張牌",
[":bj_startequip"] = "遊戲開始時，你將一張裝備牌置入裝備區",
[":bj_get_2skill"] = "你可以選擇兩個技能，並獲得之",
[":bj_get_3skill"] = "你可以選擇三個技能，並獲得之",
}


--商鞅
shangyang = sgs.General(extension,"qin_shangyang","qin","4",true,true)
--變法：出牌階段限一次，你可以將任意一張普通錦囊牌當【商鞅變法】使用。

qin_bianfa = sgs.CreateOneCardViewAsSkill{
	name = "qin_bianfa",
	view_filter = function(self, card)
		if not card:isKindOf("TrickCard") then return false end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("shangyangbianfa", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return player:getMark("qin_bianfa-Clear") == 0
	end, 
}

qin_bianfastart = sgs.CreateTriggerSkill{
	name = "qin_bianfastart" ,
	events = {sgs.CardFinished} ,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card then
			if use.card:getSkillName() == "qin_bianfa" then
				room:setPlayerMark(player, "qin_bianfa-Clear", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:isAlive()
	end,
}

if not sgs.Sanguosha:getSkill("qin_bianfastart") then skills:append(qin_bianfastart) end 

--立木：鎖定技，你使用的普通錦囊牌無法被【無懈可擊】抵消

qin_limu = sgs.CreateTriggerSkill{
	name = "qin_limu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TrickCardCanceling},
	on_trigger = function(self, event, player, data, room)
		local effect = data:toCardEffect()
		if RIGHT(self, effect.from) then
			SendComLog(self, effect.from)
			room:addPlayerMark(effect.from, self:objectName().."engine")
			if effect.from:getMark(self:objectName().."engine") > 0 then
				room:removePlayerMark(effect.from, self:objectName().."engine")
				return true
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--墾草：鎖定技，你存活時，秦勢力角色每造成1點傷害，可獲得一個“功”標記。若秦勢力角色擁有大於等於3個“功”標記，則棄置所有“功”標記，
--增加1點體力上限，並回復1點體力。
qin_kencao = sgs.CreateTriggerSkill{
	name = "qin_kencao",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if player:getKingdom() == "qin" then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				player:gainMark("@qin_gong",damage.damage)
				if player:getMark("@qin_gong") >= 3 then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(player, "@qin_gong", 0)
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
					local theRecover = sgs.RecoverStruct()
					theRecover.recover = 1
					theRecover.who = player
					room:recover(player, theRecover)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target:isAlive()
	end,
}

shangyang:addSkill(qin_bianfa)
shangyang:addSkill(qin_limu)
shangyang:addSkill(qin_kencao)

sgs.LoadTranslationTable{
	["qin_shangyang"]="商鞅",
	["qin_bianfa"]="變法",
	["qin_limu"]="立木",
	["qin_kencao"]="墾草",
	[":qin_bianfa"]="出牌階段限一次，你可以將任意一張普通錦囊牌當【商鞅變法】使用。",
	[":qin_limu"]="鎖定技，你使用的普通錦囊牌無法被【無懈可擊】抵消",
	[":qin_kencao"]="鎖定技，你存活時，秦勢力角色每造成1點傷害，可獲得一個“功”標記。若秦勢力角色擁有大於等於3個“功”標記，則棄置所有“功”"..
	"標記，增加1點體力上限，並回復1點體力。",
	["@qin_gong"] = "功",
	["shangyangbianfa"]="商鞅變法",
	[":shangyangbianfa"]="造成隨機1~2點傷害，若該角色進入瀕死狀態，則進行判定，若判定結果為黑色，則該角色本次瀕死狀態無法向其他角色求桃",
}
--張儀技能：
qin_zhangyi = sgs.General(extension,"qin_zhangyi","qin","4",true,true)

--連橫：鎖定技，遊戲開始時，你令隨機一名非秦勢力的角色獲得“橫”標記。擁有“橫”標記的角色使用牌時，無法指定秦勢力角色為目標。你的回合開始時，
--場上所有角色棄置“橫”標記。若非秦勢力角色大於等於2人，則你令隨機一名非秦勢力角色獲得“橫”標記。
qin_lianheng = sgs.CreateTriggerSkill{
	name = "qin_lianheng",
	events = {sgs.GameStart,sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if (event == sgs.GameStart or (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start)) then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:setPlayerMark(p,"@qin_heng",0)
			end
			local q
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (p:getKingdom() ~= "qin") then
					_targets:append(p)
				end
			end

			local length = _targets:length()
			if length > 1 then
				local n = math.random(1, length)
				local q = _targets:at(n-1)
				if q then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(q,"@qin_heng",1)
				end
			end
		end
		return false
	end,
}

qin_lianhengPS = sgs.CreateProhibitSkill{
	name = "#qin_lianhengPS",
	is_prohibited = function(self, from, to, card)
		return
		 (from:getMark("@qin_heng") > 0 and to:getKingdom() == "qin") and (not card:isKindOf("SkillCard"))
		 or (from:getMark("@qin_heng") > 0 and from:getMark("QinModeEvent") == 2 and to:isChained()) and (not card:isKindOf("SkillCard")) 
	end
}

if not sgs.Sanguosha:getSkill("#qin_lianhengPS") then skills:append(qin_lianhengPS) end

--戲楚：鎖定技，當你成為【殺】的目標時，若其攻擊範圍內有其他角色，則該角色需要棄置一張點數為6的牌，否則此【殺】無效
qin_xichuCard = sgs.CreateSkillCard{
	name = "qin_xichu" ,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		if to_select:hasFlag("qin_xichuSlashSource") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:hasFlag("qin_xichuSlashSource") then
				from = p
				break
			end
		end
		local slash = sgs.Card_Parse(sgs.Self:property("qin_xichu"):toString())
		if not from then return false end
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		return from:distanceTo(to_select) <= from:getAttackRange()
	end,
	on_effect = function(self, effect)
		effect.to:setFlags("qin_xichuTarget")
	end
}
qin_xichuVS = sgs.CreateZeroCardViewAsSkill{
	name = "qin_xichu" ,
	response_pattern = "@@qin_xichu",
	view_as = function()
		return qin_xichuCard:clone()
	end
}

qin_xichu = sgs.CreateTriggerSkill{
	name = "qin_xichu" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = qin_xichuVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and
			 use.to:contains(player) and (room:alivePlayerCount() > 2) then
				local can_invoke = false
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if use.from:canSlash(p, use.card) and player:inMyAttackRange(p) then
						can_invoke = true
						break
					end
				end
				if can_invoke then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					local dataforai = sgs.QVariant()
					dataforai:setValue(player)
					if not room:askForCard(use.from,".|.|6|.","@qin_xichu-discard",dataforai) then
						local prompt = "@liuli:" .. use.from:objectName()
						room:setPlayerFlag(use.from, "qin_xichuSlashSource")
						room:setPlayerProperty(player, "qin_xichu-card", sgs.QVariant(use.card:toString()))
						if room:askForUseCard(player, "@@qin_xichu", prompt, -1, sgs.Card_MethodDiscard) then
							room:setPlayerProperty(player, "qin_xichu", sgs.QVariant())
							room:setPlayerFlag(use.from, "-qin_xichuSlashSource")
							for _, p in sgs.qlist(players) do
								if p:hasFlag("qin_xichuTarget") then
									p:setFlags("-qin_xichuTarget")
									use.to:removeOne(player)
									use.to:append(p)
									room:sortByActionOrder(use.to)
									data:setValue(use)
									room:getThread():trigger(sgs.TargetConfirming, room, p, data)
									return false
								end
							end
						else
							room:setPlayerProperty(player, "qin_xichu-card", sgs.QVariant())
							room:setPlayerFlag(use.from, "-qin_xichuSlashSource")
						end
					end
				end
			end
		end
	end
}

--雄辯：鎖定技，當你成為普通錦囊牌的目標或之一時，你進行判定，若點數為3-9，你令此牌無效。
qin_xiongbian = sgs.CreateTriggerSkill{
	name = "qin_xiongbian" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isNDTrick() then
					room:notifySkillInvoked(player, "qin_xiongbian")
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName())
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.reason = "qin_xiongbian"
					judge.pattern = ".|.|6|."
					judge.good = true
					room:judge(judge)
					if judge:isGood() then
						room:broadcastSkillInvoke(self:objectName())
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
		return false
	end
}

--巧舌：當一名角色進行判定時，你可以令判定結果的點數加減3以內的任意值。
qin_qiaoshe = sgs.CreateTriggerSkill{
	name = "qin_qiaoshe",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.AskForRetrial},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart or event == sgs.EventAcquireSkill then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:handleAcquireDetachSkills(p, "#qin_qiaoshe_judge", false)
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local choices = {}
				for i = 1, 13, 1 do
					if math.abs(judge.card:getNumber() - i) <= 3 then
						table.insert(choices, i)
					end
				end

				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice ~= judge.card:getNumber() then
					room:setCardFlag(judge.card, "qin_qiaoshe_judge")
					room:setPlayerMark(judge.who,"qin_qiaoshe",choice)
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
					room:setCardFlag(judge.card, "-qin_qiaoshe_judge")
					room:setPlayerMark(judge.who,"qin_qiaoshe",0)
				end
			end
		end
		return false
	end
}


qin_qiaoshe_judge = sgs.CreateFilterSkill{
	name = "#qin_qiaoshe_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("qin_qiaoshe_judge")
	end,
	view_as = function(self, originalCard)
		local room = sgs.Sanguosha:currentRoom()
		local id = originalCard:getEffectiveId()
		local player = room:getCardOwner(id)
		if player:getMark("qin_qiaoshe") > 0 then
			local card = sgs.Sanguosha:getWrappedCard(id)
			card:setNumber( player:getMark("qin_qiaoshe") )
			return card
		else
			return originalCard
		end
	end
}

if not sgs.Sanguosha:getSkill("#qin_qiaoshe_judge") then skills:append(qin_qiaoshe_judge) end



qin_zhangyi:addSkill(qin_lianheng)
qin_zhangyi:addSkill(qin_xiongbian)
qin_zhangyi:addSkill(qin_xichu)
qin_zhangyi:addSkill(qin_qiaoshe)

sgs.LoadTranslationTable{
	["qin_zhangyi"]="張儀",
	["qin_lianheng"]="連橫",
	["qin_xichu"]="戲楚",
	["qin_xiongbian"]="雄辯",
	[":qin_lianheng"]="鎖定技，遊戲開始時，你令隨機一名非秦勢力的角色獲得“橫”標記。擁有“橫”標"..
	"記的角色使用牌時，無法指定秦勢力角色為目標。你的回合開始時，場上所有角色棄置“橫”標記。若非秦勢力角色大於"..
	"等於2人，則你令隨機一名非秦勢力角色獲得“橫”標記。",
	[":qin_xichu"]="鎖定技，當你成為【殺】的目標時，若其攻擊範圍內有其他角色，則該角色需棄置一張點數為6的牌，否則此【殺】的目標轉移給其攻擊範圍內你指定的另一名角色。",
	[":qin_xiongbian"]="鎖定技，當你成為普通錦囊牌的目標後，你判定。若結果點數為6，你取消此牌的所有目標。",
	["@qin_heng"] = "橫",
	["@qin_xichu-discard"] = "你需要棄置一張點數為6的牌，否則此【殺】無效",
	["qin_qiaoshe"] = "巧舌",
	[":qin_qiaoshe"] = "當一名角色進行判定時，你可以令判定結果的點數加減3以內的任意值。",
		["#qin_qiaoshe_judge"] = "巧舌",
}

--羋月
qin_mieyue = sgs.General(extension,"qin_mieyue","qin","3",false,true)
--掌政：鎖定技，你的回合開始時，所有非秦勢力角色依次選擇：1.棄置一張手牌；2.失去1點體力。
qin_zhangzheng = sgs.CreateTriggerSkill{
	name = "qin_zhangzheng",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getKingdom() ~= "qin" then
						local card = room:askForCard(p, ".", "@qin_zhangzheng", sgs.QVariant(), sgs.Card_MethodDiscard)
						if not card then
							room:loseHp(p)
						end
					end
				end
			end
		end
		return false
	end,
}
--太后：鎖定技，男性角色對你使用【殺】或普通錦囊牌時，需要額外棄置一張同種類型的牌，否則此牌無效
qin_taihou = sgs.CreateTriggerSkill{
	name = "qin_taihou" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and use.from:isMale() then
				local caneffect = false
				if use.card:isKindOf("Slash") then
					caneffect = true
					if room:askForCard(use.from,".Basic","@qin_taihou-basic",data) then
						caneffect = false
					end
				elseif use.card:isNDTrick() then
					caneffect = true
					if room:askForCard(use.from,".Trick","@qin_taihou-trick",data) then
						caneffect = false
					end
				end
				if caneffect then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
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
		return false
	end
}
--誘滅：出牌階段限一次，你可以將一張牌交給一名角色，若如此做，直到你的下個回合開始，該角色於其回合外無法使用或打出牌。
qin_youmieCard = sgs.CreateSkillCard{
	name = "qin_youmie",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0)
	end,
	on_use = function(self, room, source, targets)
		local tiger = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), tiger:objectName(), "qin_youmie","")
		room:moveCardTo(self,tiger,sgs.Player_PlaceHand,reason, false)

		room:addPlayerMark(tiger, "@qin_youmie_prohibit")
		room:setPlayerCardLimitation(targets[1], "use,response", ".|.|.|hand", false)
	end
}

qin_youmie = sgs.CreateViewAsSkill{
	name = "qin_youmie" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = qin_youmieCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#qin_youmie")) 
	end, 
}

qin_youmie_clear = sgs.CreateTriggerSkill{
	name = "qin_youmie_clear",
	global = true,
	priority = -100,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, splayer, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_RoundStart then
			if splayer:getMark("@qin_youmie_prohibit") > 0 then
				room:setPlayerMark(splayer, "@qin_youmie_prohibit", 0)
				room:removePlayerCardLimitation(splayer, "use,response", ".|.|.|hand")
			end
		end
	end,
}

qin_youmiePS = sgs.CreateProhibitSkill{
	name = "qin_youmiePS",
	is_prohibited = function(self, from, to, card)
		return
		 (from:getMark("@qin_youmie_prohibit") > 0) and (not card:isKindOf("SkillCard"))
	end
}

if not sgs.Sanguosha:getSkill("qin_youmiePS") then skills:append(qin_youmiePS) end
if not sgs.Sanguosha:getSkill("qin_youmie_clear") then skills:append(qin_youmie_clear) end

--隱退：鎖定技，當你失去最後一張手牌時，你翻面。你的武將牌背面朝上時，若受到傷害，令此傷害-1，然後摸一張牌
qin_yintui = sgs.CreateTriggerSkill{
	name = "qin_yintui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime,sgs.EventPhaseChanging,sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.from == sgs.Player_Discard) and player:hasFlag("qin_yintuiZeroMaxCards") then
				room:setPlayerFlag(player, "-qin_yintuiZeroMaxCards")
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:turnOver()
			end
		elseif event == ssgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName()) and 
				move.from_places:contains(sgs.Player_PlaceHand) then
				if event == sgs.BeforeCardsMove then
					if player:isKongcheng() then return false end
					for _, id in sgs.qlist(player:handCards()) do
						if not move.card_ids:contains(id) then return false end
					end
					if (player:getMaxCards() == 0) and (player:getPhase() == sgs.Player_Discard) 
							and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD) then
						room:setPlayerFlag(player, "qin_yintuiZeroMaxCards")
						return false
					end
					player:addMark(self:objectName())
				else
					if player:getMark(self:objectName()) == 0 then return false end
					player:removeMark(self:objectName())
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					player:turnOver()
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if not player:faceUp() then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
				
				local msg = sgs.LogMessage()
				msg.type = "#QinYintui"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage + 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	

				if damage.damage > 1 then
					damage.damage = damage.damage - 1
					data:setValue(damage)
				else
					return true
				end
			end
			return false
		end
	end
}
qin_mieyue:addSkill(qin_zhangzheng)
qin_mieyue:addSkill(qin_taihou)
qin_mieyue:addSkill(qin_youmie)
qin_mieyue:addSkill(qin_yintui)

sgs.LoadTranslationTable{
	["qin_mieyue"]="羋月",
	["qin_zhangzheng"]="掌政",
	["qin_taihou"]="太后",
	["qin_youmie"]="誘滅",
	["qin_yintui"]="隱退",
	[":qin_zhangzheng"]="鎖定技，你的回合開始時，所有非秦勢力角色依次選擇：1.棄置一張手牌；2.失去1點體力。",
	[":qin_taihou"]="鎖定技，男性角色對你使用【殺】或普通錦囊牌時，需要額外棄置一張同種類型的牌，否則此牌無效",
	[":qin_youmie"]="出牌階段限一次，你可以將一張牌交給一名角色，若如此做，直到你的下個回合開始，該角色於其回合外無法使用或打出牌。",
	[":qin_yintui"]="鎖定技，當你失去最後一張手牌時，你翻面。你的武將牌背面朝上時，若受到傷害，令此傷害-1，然後摸一張牌",
	["@qin_zhangzheng"] = "請棄置一張手牌，否則失去1點體力。",
	["@qin_taihou-basic"] = "你需要棄置一張基本牌的牌，否則此【殺】無效",
	["@qin_taihou-trick"] = "你需要棄置一張錦囊牌的牌，否則此【殺】無效",

	["#QinYintui"] = "%from 的技能 “<font color=\"yellow\"><b>隱退</b></font>”被觸發，對 %to 造成傷害由 %arg 點減少到 %arg2 點",

}
--[[
秦軍步兵
同袍：鎖定技，若你沒有裝備防具，其他秦勢力角色使用防具牌時，你也視為使用一張同種防具牌。你通過“同袍”使用的防具牌離開你的裝備區時會被銷毀。
方陣：鎖定技，當你成為非秦勢力角色使用普通錦囊或【殺】的目標後，若其在你的攻擊範圍內，你進行判定，若為黑色，則視為你對其使用一張【殺】。
長兵：鎖定技，你的攻擊範圍+2。
]]--
qinjunbubing = sgs.General(extension,"qinjunbubing","qin","3",true,true)

qin_fangzhen = sgs.CreateTriggerSkill{
	name = "qin_fangzhen" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and
			use.from:getKingdom() ~= "qin" then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if player:distanceTo(use.from) <= player:getAttackRange() then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						local judge = sgs.JudgeStruct()
						judge.reason = self:objectName()
						judge.pattern =  ".|black"
						judge.good = true
						judge.who = player
						room:judge(judge)
						if judge:isGood() then
							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							slash:setSkillName("qin_fangzhen")
							local use2 = sgs.CardUseStruct()
							use2.card = slash
							use2.from = player
							local dest = use.from
							use2.to:append(dest)
							room:useCard(use2)
						end
					end
				end
			end
		end
		return false
	end
}
 
qin_changbing = sgs.CreateTargetModSkill{
	name = "qin_changbing",
	frequency = sgs.Skill_Compulsory,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("qin_changbing") then 
			return 2
		end
	end
}
qinjunbubing:addSkill(qin_fangzhen)
qinjunbubing:addSkill(qin_changbing)

sgs.LoadTranslationTable{
	["qinjunbubing"]="秦軍步兵",
	["qin_fangzhen"]="方陣",
	["qin_changbing"]="長兵",
	[":qin_fangzhen"]="鎖定技，當你成為非秦勢力角色使用普通錦囊或【殺】的目標後，若其在你的攻擊範圍內，你進行判"
	.."定，若為黑色，則視為你對其使用一張【殺】。",
	[":qin_changbing"]="鎖定技，你的攻擊範圍+2。",
}
--[[
秦軍騎兵：
同袍：鎖定技，若你沒有裝備防具，其他秦勢力角色使用防具牌時，你也視為使用一張同種防具牌。你通過“同袍”使用的防具牌離開你的裝備區時會被銷毀。
長劍：鎖定技，你的攻擊範圍+1，你使用【殺】指定目標後，可額外選擇一名目標，或令此殺傷害+1。
良駒：鎖定技，你使用【殺】指定目標後，令目標進行判定，若為黑桃則此殺不可被閃避；當你成為【殺】的目標後，你進行判定，若為紅桃則此殺對你無效。
]]--
qinjunqibing = sgs.General(extension,"qinjunqibing","qin","4",true,true)

qin_changjianTM = sgs.CreateTargetModSkill{
	name = "#qin_changjianTM",
	frequency = sgs.Skill_Compulsory,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("qin_changbing") then 
			return 1
		end
	end,
}


qin_changjianCard = sgs.CreateSkillCard{
	name = "qin_changjian",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("qin_changjian_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "qin_changjian_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets < 1 and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets < 1 and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _, p in pairs(targets) do
				room:addPlayerMark(p, self:objectName())
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
qin_changjianVS = sgs.CreateZeroCardViewAsSkill{
	name = "qin_changjian",
	response_pattern = "@@qin_changjian",
	view_as = function()
		return qin_changjianCard:clone()
	end
}
qin_changjian = sgs.CreateTriggerSkill{
	name = "qin_changjian",
	events = {sgs.PreCardUsed, sgs.TargetSpecified},
	view_as_skill = qin_changjianVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, self:objectName())
				end
				if use.card:isVirtualCard() then
					room:setPlayerMark(player, "qin_changjian_virtual_card", 1)
					room:setPlayerMark(player, "qin_changjian_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
					if room:askForUseCard(player, "@@qin_changjian", "@qin_changjian") then
					else
						room:setCardFlag(use.card,"qin_changjian")
					end
					room:setPlayerMark(player, "qin_changjian_virtual_card", 0)
					room:setPlayerMark(player, "qin_changjian_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
				elseif not use.card:isVirtualCard() then
					room:setPlayerMark(player, "qin_changjian_not_virtual_card", 1)
					room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
					if room:askForUseCard(player, "@@qin_changjian", "@qin_changjian") then
					else
						room:setCardFlag(use.card,"qin_changjian")
					end
					room:setPlayerMark(player, "qin_changjian_not_virtual_card", 0)
					room:setPlayerMark(player, "card_id", 0)
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark(self:objectName()) > 0 and not room:isProhibited(player, p, use.card) then
						room:removePlayerMark(p, self:objectName())
						if not use.to:contains(p) then
							use.to:append(p)
						end
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and damage.card:hasFlag("qin_changjian") then
					damage.damage = damage.damage + 1
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					local msg = sgs.LogMessage()
						msg.type = "#Changjian"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
				end
			end
		end
	end,
}

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
qin_liangju = sgs.CreateTriggerSkill{
	name = "qin_liangju" ,
	events = {sgs.TargetSpecified,sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.pattern =  ".|spade"
				judge.good = true
				judge.who = p
				room:judge(judge)
				if judge:isGood() then
					--if player:askForSkillInvoke(self:objectName(), _data) then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						local msg = sgs.LogMessage()
						msg.type = "#Liegong1"
						msg.from = player
						msg.to:append(p)
						msg.arg = self:objectName()
						msg.arg2 = use.card:objectName()
						msg.card_str = use.card:toString()
						room:sendLog(msg)
						jink_table[index] = 0
					--end
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card and use.card:isKindOf("Slash") then
					room:broadcastSkillInvoke(self:objectName())
					player:setFlags("-ZhenlieTarget")
					player:setFlags("ZhenlieTarget")
					if player:isAlive() and player:hasFlag("ZhenlieTarget") then
						local judge = sgs.JudgeStruct()
						judge.reason = self:objectName()
						judge.pattern =  ".|heart"
						judge.good = true
						judge.who = player
						room:judge(judge)
						if judge:isGood() then
							room:notifySkillInvoked(player, self:objectName())
							room:sendCompulsoryTriggerLog(player, self:objectName()) 
							room:broadcastSkillInvoke(self:objectName())
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
}

qinjunqibing:addSkill(qin_changjian)
qinjunqibing:addSkill(qin_changjianTM)
qinjunqibing:addSkill(qin_liangju)

sgs.LoadTranslationTable{
	["qinjunqibing"]="秦軍騎兵",
	["qin_changjian"]="長劍",
	["qin_liangju"]="良駒",
	[":qin_changjian"]="鎖定技，你的攻擊範圍+1，你使用【殺】指定目標後，可額外選擇一名目標，或令此殺傷害+1。",
	["#Changjian"] = "%from 的技能 “<font color=\"yellow\"><b>長劍</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
	[":qin_liangju"]="鎖定技，你使用【殺】指定目標後，令目標進行判定，若為黑桃則此殺不可被閃避；當你成為【殺】的目標後，你進行判定，若為紅桃則此殺對你無效。",
	["@qin_changjian"] = "你可以發動“良駒”，否則此殺傷害+1",
	["~qin_changjian"] = "選擇目標角色→點“確定”",
}

--[[
白起技能：
武安：鎖定技，你存活時，所有秦勢力角色每回合可使用【殺】的上限+1。
殺神：你可以將手牌中的任意一張牌當【殺】使用或打出。每回合你使用的第一張【殺】造成傷害後，摸一張牌。
伐楚：鎖定技，當你對非秦勢力角色造成傷害而導致其進入瀕死狀態後，你隨機廢除其一個裝備區。
常勝：鎖定技，你使用【殺】無距離限制。
]]--
qin_baiqi = sgs.General(extension,"qin_baiqi","qin","4",true,true)

qin_wuan = sgs.CreateTargetModSkill{
	name = "qin_wuan",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player, card)
		local invoke =false
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:getGeneralName() == "qin_baiqi" then
				invoke = true
			end
		end
		if invoke and player:getKingdom() == "qin" then
			return 1
		end
	end,
}

qin_shashenVS = sgs.CreateOneCardViewAsSkill{
	name = "qin_shashen",
	response_or_use = true,
	view_filter = function(self, card)
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
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
qin_shashen = sgs.CreateTriggerSkill{
	name = "qin_shashen",
	events = {sgs.Damage,sgs.CardUsed},
	view_as_skill = qin_shashenVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card then
				if damage.card:isKindOf("Slash") and player:getMark("qin_shashen-Clear") == 1 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerMark(player, "qin_shashen-Clear", player:getMark("qin_shashen-Clear") + 1) 
			end
		end
	end
}
--[[
function ChooseThrowEquipArea(self, player,cancel,random)
	local room = player:getRoom()
	local abolishlist = {"AbolishWeapon","AbolishArmor","AbolishHorse","AbolishTreasure"}
	local choicelist = {}
	for _,canabolish in pairs(abolishlist) do
		if player:getMark("@"..canabolish) == 0 then
			table.insert(choicelist, canabolish)
		end
	end
	if cancel then
		table.insert(choices, "cancel")
	end
	local choice
	if random then
		choice = choicelist[math.random(1,#choicelist)]
	else
		choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"))
	end
	if choice ~= "cancel" then
		room:setPlayerMark(player,"@"..choice,1)
		return choice
	end
	return -1
end


function throwEquipArea(self ,player, choice)
	local room = player:getRoom()
	room:setPlayerMark(player,"@"..choice,1)
	if choice == "AbolishWeapon" then
		if player:getWeapon() then
			room:moveCardTo(player:getWeapon(), nil, sgs.Player_DiscardPile)
		end
	elseif choice == "AbolishArmor" then

		if player:getArmor() then
			room:moveCardTo(player:getArmor(), nil, sgs.Player_DiscardPile)
		end
	elseif choice == "AbolishHorse" then
		if player:getDefensiveHorse() then
			room:moveCardTo(player:getDefensiveHorse(), nil, sgs.Player_DiscardPile)
		end
		if player:getOffensiveHorse() then
			room:moveCardTo(player:getOffensiveHorse(), nil, sgs.Player_DiscardPile)
		end
	elseif choice == "AbolishTreasure" then
		if player:getTreasure() then
			room:moveCardTo(player:getTreasure(), nil, sgs.Player_DiscardPile)
		end
	end
	local msg = sgs.LogMessage()
	msg.type = "#Abolish1Equip"
	msg.from = player
	msg.to:append(player)
	msg.arg = self:objectName()
	msg.arg2 = choice
	room:sendLog(msg)
end
]]--

qin_fachu = sgs.CreateTriggerSkill{
	name = "qin_fachu",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to:getKingdom() ~= "qin" and damage.to:getHp() <= damage.damage then
				local n = ChooseThrowEquipArea(self, damage.to,false,true)
				if n ~= -1 then
					room:broadcastSkillInvoke(self:objectName())
					throwEquipArea(self,damage.to, n)
				end
			end
		end
	end,
}

qin_changsheng = sgs.CreateTargetModSkill{	
	name = "qin_changsheng" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("qin_changsheng") then
			return 1000
		end
		return 0
	end,
}

qin_baiqi:addSkill(qin_wuan)
qin_baiqi:addSkill(qin_shashen)
qin_baiqi:addSkill(qin_fachu)
qin_baiqi:addSkill(qin_changsheng)

sgs.LoadTranslationTable{
	["qin_baiqi"]="白起",
	["qin_wuan"]="武安",
	["qin_shashen"]="殺神",
	[":qin_wuan"]="鎖定技，你存活時，所有秦勢力角色每回合可使用【殺】的上限+1。",
	[":qin_shashen"]="你可以將手牌中的任意一張牌當【殺】使用或打出。每回合你使用的第一張【殺】造成傷害後，摸一張牌。",
	["qin_fachu"]="伐楚",
	["qin_changsheng"]="常勝",
	[":qin_fachu"]="鎖定技，當你對非秦勢力角色造成傷害而導致其進入瀕死狀態後，你隨機廢除其一個裝備區。",
	[":qin_changsheng"]="鎖定技，你使用【殺】無距離限制。",
}

--[[
呂不韋技能：
巨賈：鎖定技，你的手牌上限+X；遊戲開始時，你多摸X張牌（X為你的體力上限）。
奇貨：出牌階段限一次，你可以棄置一種類型的牌，並摸等同於你棄置牌數量等量的牌。
春秋：鎖定技，每個回合你使用或打出第一張牌時，你摸一張牌。
拜相：覺醒技，你的回合開始時，若你的手牌數大於等於你當前體力的3倍，則你將體力恢復至體力上限，並獲得“仲父”技能。
仲父：鎖定技，你的回合開始時，直到你的下個回合開始為止，你隨機獲得“界奸雄”、“界仁德”、“界制衡”中的一個。
]]--
qin_lubuwei = sgs.General(extension,"qin_lubuwei","qin","3",true,true)
qin_qihuoCard = sgs.CreateSkillCard{
	name = "qin_qihuo",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			local choices = {}
			local n1 = 0
			local n2 = 0
			local n3 = 0
			local cards = source:getHandcards()
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
			table.insert(choices, "BasicCard")
			table.insert(choices, "TrickCard")
			table.insert(choices, "EquipCard")
			local choice = room:askForChoice(source, "qin_qihuo", table.concat(choices, "+"))
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
			if ids:length() > 0 then
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, source:objectName(), nil, "str_chilo", nil)
				room:moveCardsAtomic(move, true)
				room:drawCards(source, ids:length(), "qin_qihuo")
			end
		end
	end
}
qin_qihuo = sgs.CreateViewAsSkill{
	name = "qin_qihuo",
	n = 0,
	view_as = function(self, cards)
		local zhiheng_card = qin_qihuoCard:clone()
		zhiheng_card:setSkillName(self:objectName())
		return zhiheng_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#qin_qihuo") and player:canDiscard(player, "he")
	end,
}

qin_chunqiu = sgs.CreateTriggerSkill{
	name = "qin_chunqiu",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and player:getMark("qin_chunqiu-Clear") == 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1)
				room:setPlayerMark(player, "qin_chunqiu-Clear", player:getMark("qin_chunqiu-Clear") + 1) 
			end
		end
	end
}

qin_zhongfu = sgs.CreateTriggerSkill{
	name = "qin_zhongfu",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				if player:hasSkill("ol_rende") and player:getMark("qin_zhongfu_ol_rende") > 0 then
					room:detachSkillFromPlayer(player, "ol_rende")
					room:setPlayerMark(player,"qin_zhongfu_ol_rende",0)
				end
				if player:hasSkill("jianxiong_po") and player:getMark("qin_zhongfu_jianxiong_po") > 0 then
					room:detachSkillFromPlayer(player, "jianxiong_po")
					room:setPlayerMark(player,"qin_zhongfu_jianxiong_po",0)
				end
				if player:hasSkill("zhiheng_po") and player:getMark("qin_zhongfu_zhiheng_po") > 0 then
					room:detachSkillFromPlayer(player, "zhiheng_po")
					room:setPlayerMark(player,"qin_zhongfu_zhiheng_po",0)
				end


				local skilllist = {}
				if (not player:hasSkill("ol_rende")) then
					table.insert(skilllist, "ol_rende")
				end
				if (not player:hasSkill("jianxiong_po")) then
					table.insert(skilllist, "jianxiong_po")
				end
				if (not player:hasSkill("zhiheng_po")) then
					table.insert(skilllist, "zhiheng_po")
				end
				if #skilllist > 0 then
					sk = skilllist[math.random(1, #skilllist)]
					room:acquireSkill(player, sk)
					room:setPlayerMark(player,"qin_zhongfu_"..sk,1)
				end
			end	
		end
	end,
}

qin_baixiang = sgs.CreatePhaseChangeSkill{
	name = "qin_baixiang" ,
	frequency = sgs.Skill_Wake,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:notifySkillInvoked(player, self:objectName())
		room:sendCompulsoryTriggerLog(player, self:objectName()) 
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("qin_lubuwei","qin_baixiang")
		room:setPlayerMark(player,"qin_baixiang", 1)
		room:acquireSkill(player, "qin_zhongfu")
	end ,
	can_trigger = function(self,target)
		return (target and target:isAlive() and target:hasSkill(self:objectName()))
				and (target:getPhase() == sgs.Player_Start)
				and (target:getMark("qin_baixiang") == 0)
				and ((target:getHandcardNum() >= (target:getHp() * 3)) or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}

qin_lubuwei:addSkill("jugu")
qin_lubuwei:addSkill(qin_qihuo)
qin_lubuwei:addSkill(qin_chunqiu)
qin_lubuwei:addSkill(qin_baixiang)

if not sgs.Sanguosha:getSkill("qin_zhongfu") then skills:append(qin_zhongfu) end

sgs.LoadTranslationTable{
	["qin_lubuwei"]="呂不韋",
	["qin_qihuo"]="奇貨",
	["qin_chunqiu"]="春秋",
	[":qin_qihuo"]="出牌階段限一次，你可以棄置一種類型的牌，並摸等同於你棄置牌數量等量的牌。",
	[":qin_chunqiu"]="鎖定技，每個回合你使用或打出第一張牌時，你摸一張牌。",
	["qin_baixiang"]="拜相",
	["qin_zhongfu"]="仲父",
	[":qin_baixiang"]="覺醒技，你的回合開始時，若你的手牌數大於等於你當前體力的3倍，則你將體力恢復至體力上限，"
	.."並獲得“仲父”技能。",
	[":qin_zhongfu"]="鎖定技，你的回合開始時，直到你的下個回合開始為止，你隨機獲得“界奸雄”、“界仁德”、“界制"
	.."衡”中的一個。",
}

--[[
趙姬技能：
善舞：鎖定技，你使用【殺】指定目標後，你進行判定，若為黑色則該【殺】不能被抵消。當你成為【殺】的目標後，你進行判定，若為紅色此殺無效。
大期：鎖定技，你每使用或打出一張手牌、造成1點傷害、受到1點傷害，均會得到一個“期”標記。你的回合開始時，若你擁有的“期”標
記大於等於10，則棄置所有“期”，體力回復至體力上限，並將手牌補至體力上限。
獻姬：限定技，出牌階段，你可以棄置所有手牌、裝備牌和“期”標記，失去1點體力上限，然後立即發動大期的回復體力和補牌效果。
禍亂：鎖定技，你每次發動大期的回復體力和補牌效果後，你對所有其他角色造成1點傷害。
]]--
qin_zhaoji = sgs.General(extension,"qin_zhaoji","qin","3",false,true)

qin_shanwu = sgs.CreateTriggerSkill{
	name = "qin_shanwu" ,
	events = {sgs.TargetSpecified,sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				local judge = sgs.JudgeStruct()
				judge.reason = self:objectName()
				judge.pattern =  ".|black"
				judge.good = true
				judge.who = p
				room:judge(judge)
				if judge:isGood() then
					--if player:askForSkillInvoke(self:objectName(), _data) then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						local msg = sgs.LogMessage()
						msg.type = "#Liegong1"
						msg.from = player
						msg.to:append(p)
						msg.arg = self:objectName()
						msg.arg2 = use.card:objectName()
						msg.card_str = use.card:toString()
						room:sendLog(msg)
						jink_table[index] = 0
					--end
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card and use.card:isKindOf("Slash") then
					player:setFlags("-ZhenlieTarget")
					player:setFlags("ZhenlieTarget")
					if player:isAlive() and player:hasFlag("ZhenlieTarget") then
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						local judge = sgs.JudgeStruct()
						judge.reason = self:objectName()
						judge.pattern =  ".|red"
						judge.good = true
						judge.who = player
						room:judge(judge)
						if judge:isGood() then
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
}

qin_daqi = sgs.CreateTriggerSkill{
	name = "qin_daqi" ,
	events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.Damage,sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
			 	if player:getMark("@qin_chi") >= 10 then
			 		room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
			 		room:doSuperLightbox("qin_zhaoji","qin_daqi")
					player:loseAllMarks("@qin_chi")
					if player:isWounded() then
						local theRecover = sgs.RecoverStruct()
						theRecover.recover = player:getMaxHp() - player:getHp()
						theRecover.who = player
						room:recover(player, theRecover)
					end
					local n = player:getMaxHp() - player:getHandcardNum()
					if n > 0 then
						player:drawCards(n)
					end

					if player:hasSkill("qin_huoluan") then
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							room:damage(sgs.DamageStruct("qin_huoluan", player, p, 1, sgs.DamageStruct_Normal))
						end
					end
			 	end
			end
		elseif event == sgs.CardUsed or event == sgs.Damage or event == sgs.Damaged then
			if event == sgs.CardUsed then
				player:gainMark("@qin_chi")
			elseif event == sgs.Damage or event == sgs.Damaged then
				local damage = data:toDamage()
				player:gainMark("@qin_chi",damage.damage)
			end
		end
	end ,
}

qin_xianjiCard = sgs.CreateSkillCard{
	name = "qin_xianji",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			room:doSuperLightbox("qin_zhaoji","qin_xianji")
			room:removePlayerMark(source, "@qin_xianji")
			source:throwAllHandCardsAndEquips()
			source:loseAllMarks("@qin_chi")
			if source:isWounded() then
				local theRecover = sgs.RecoverStruct()
				theRecover.recover = source:getMaxHp() - source:getHp()
				theRecover.who = source
				room:recover(source, theRecover)
			end
			local n = source:getMaxHp() - source:getHandcardNum()
			if n > 0 then
				source:drawCards(n)
			end

			if source:hasSkill("qin_huoluan") then
				for _, p in sgs.qlist(room:getOtherPlayers(source)) do
					room:damage(sgs.DamageStruct("qin_huoluan", source, p, 1, sgs.DamageStruct_Normal))
				end
			end
		end
	end
}
qin_xianjiVS = sgs.CreateViewAsSkill{
	name = "qin_xianji",
	n = 0,
	view_as = function(self, cards)
		local zhiheng_card = qin_xianjiCard:clone()
		zhiheng_card:setSkillName(self:objectName())
		return zhiheng_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#qin_xianji") and player:getMark("@qin_xianji") > 0
	end,
}

qin_xianji = sgs.CreateTriggerSkill{
	name = "qin_xianji" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@qin_xianji",
	view_as_skill = qin_xianjiVS,
	on_trigger = function() 
	end
}

qin_huoluan = sgs.CreateTriggerSkill{
	name = "qin_huoluan" ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function() 
	end
}

qin_zhaoji:addSkill(qin_shanwu)
qin_zhaoji:addSkill(qin_daqi)
qin_zhaoji:addSkill(qin_xianji)
qin_zhaoji:addSkill(qin_huoluan)

sgs.LoadTranslationTable{
	["qin_zhaoji"]="趙姬",
	["qin_shanwu"]="善舞",
	["qin_daqi"]="大期",
	["qin_xianji"]="獻姬",
	["qin_huoluan"]="禍亂",
	[":qin_shanwu"]="鎖定技，你使用【殺】指定目標後，你進行判定，若為黑色則該【殺】不能被抵消。"..
	"當你成為【殺】的目標後，你進行判定，若為紅色此殺無效。",
	[":qin_daqi"]="鎖定技，你每使用或打出一張手牌、造成1點傷害、受到1點傷害，均會得到一個“期”標記。"..
	"你的回合開始時，若你擁有的“期”標記大於等於10，則棄置所有“期”，體力回復至體力上限，並將手牌補至體力上限。",
	[":qin_xianji"]= "限定技，出牌階段，你可以棄置所有手牌、裝備牌和“期”標記，失去1點體力上限，然後立即發動"
	.."大期的回復體力和補牌效果。",
	[":qin_huoluan"]="鎖定技，你每次發動大期的回復體力和補牌效果後，你對所有其他角色造成1點傷害。",
	["@qin_chi"] = "期",
}
--[[
嬴政技能：
一統：鎖定技，你使用【殺】、【過河拆橋】、【順手牽羊】、【火攻】的目標固定為所有非秦勢力角色。你使用【殺】和【順手牽羊】無距離限制
始皇：鎖定技，其他角色的回合結束後，你有X%的機率獲得一個額外的回合（X為當前輪數*6，且X最大為100）
祖龍：鎖定技，你的回合開始時，若牌堆裡有【傳國玉璽】或【真龍長劍】，且不在你的手牌區或裝備區，你獲得之；若沒有則你摸2張牌。
焚書：鎖定技，非秦勢力角色於其回合內使用的第一張普通錦囊牌無效。
（傳國玉璽：出牌階段開始時，你可以從南蠻入侵、萬箭齊發、桃園結義、五穀豐登中選擇一張使用。
真龍長劍：每回合，你使用的第一張非延時性錦囊無法被無懈可擊抵消。 ）
]]--
qin_yingzheng = sgs.General(extension,"qin_yingzheng","qin","4",true,true)

qin_yitong = sgs.CreateTriggerSkill{
	name = "qin_yitong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isKindOf("Dismantlement") or
				use.card:isKindOf("Snatch") or use.card:isKindOf("FireAttack")) then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (not use.to:contains(p)) and p:getKingdom() ~= "qin" and (not room:isProhibited(player, p, use.card)) then
						use.to:append(p)
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
		return false
	end,
}

qin_yitongTargetMod = sgs.CreateTargetModSkill{
	name = "#qin_yitongTargetMod",
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("qin_yitong") and (card:isKindOf("Slash") or card:isNDTrick()) then
			return 1000
		else
			return 0
		end
	end,
}

qin_shihuang = sgs.CreateTriggerSkill{
	name = "qin_shihuang",
	priority = -200,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and not room:getTag("ExtraTurn"):toBool() then
			local n = 0
			for _, pp in sgs.qlist(room:getAlivePlayers()) do
				if pp:isLord() or pp:getMark("AG_firstplayer") > 0 then
					n = pp:getMark("@clock_time")
					break
				end
			end

			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("qin_shihuang") and (math.random(1, 100) <= (n*6)) then
					room:setTag("ExtraTurn" , sgs.QVariant(true))
					p:gainAnExtraTurn()
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:setTag("ExtraTurn" , sgs.QVariant(false))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

qin_zulong = sgs.CreateTriggerSkill{
	name = "qin_zulong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			local draw2card = true
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("DragonSword") then
					local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
					room:moveCardsAtomic(move, false)
					draw2card = false
				end
				if sgs.Sanguosha:getCard(id):isKindOf("DragonSeal") then	
					local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
					room:moveCardsAtomic(move, false)
					draw2card = false
				end
			end
			if draw2card then
				player:drawCards(2)
			end
		end
	end
}

qin_fenshu = sgs.CreateTriggerSkill{
	name = "qin_fenshu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed,sgs.CardFinished,sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isNDTrick() and player:getMark("qin_fenshu-Clear") == 0 
				and player:getPhase() ~= sgs.Player_NotActive and player:getKingdom() ~= "qin" then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:setCardFlag(use.card, "qin_fenshu_null")	
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isNDTrick() and player:getPhase() ~= sgs.Player_NotActive and player:getKingdom() ~= "qin" then
				if player:getMark("qin_fenshu-Clear") == 0 then
					room:setPlayerMark(player, "qin_fenshu-Clear", player:getMark("qin_fenshu-Clear") + 1) 
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) then
				if use.card:isNDTrick() and use.card:hasFlag("qin_fenshu_null") then
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
	end,
	can_trigger = function(self, target)
		--return target:getKingdom() ~= "qin"
		return target:isAlive()
	end
}

qin_yingzheng:addSkill(qin_yitong)
qin_yingzheng:addSkill(qin_yitongTargetMod)
qin_yingzheng:addSkill(qin_shihuang)
qin_yingzheng:addSkill(qin_zulong)
qin_yingzheng:addSkill(qin_fenshu)

sgs.LoadTranslationTable{
	["qin_yingzheng"]="嬴政",
	["qin_yitong"]="一統",
	["qin_shihuang"]="始皇",
	["qin_zulong"]="祖龍",
	["qin_fenshu"]="焚書",
	[":qin_yitong"]="鎖定技，你使用【殺】、【過河拆橋】、【順手牽羊】、【火攻】的目標固定"..
	"為所有非秦勢力角色。你使用【殺】和【順手牽羊】無距離限制",
	[":qin_shihuang"]="鎖定技，其他角色的回合結束後，你有X%的機率獲得一個額外的回合（X為當前輪數*6，且X最大為100）",
	[":qin_zulong"]= "鎖定技，你的回合開始時，若牌堆裡有【傳國玉璽】或【真龍長劍】，且不在你的手牌區或裝備區，"
	.."你獲得之；若沒有則你摸2張牌。",
	[":qin_fenshu"]="鎖定技，非秦勢力角色於其回合內使用的第一張普通錦囊牌無效。",
}

--[[
趙高技能：
指鹿：你可以將紅色手牌當【閃】使用或打出；將黑色手牌當【殺】使用或打出。
改詔：當你成為【殺】或普通錦囊牌的目標後（借刀殺人除外），若場上有其他秦勢力角色存活，你可以將此牌的目標改為其他不是該牌目標的秦勢力角色。
害忠：鎖定技，非秦勢力角色回復體力時，其需要選擇：1.棄置一張紅色牌，2.受到你造成的X點傷害（X為該角色擁有的“害”標記，且至少為1）。
然後該角色獲得一個“害”標記。
爰歷：鎖定技，你的出牌階段開始時，你額外獲得2張普通錦囊。
]]--

qin_zhaogao = sgs.General(extension,"qin_zhaogao","qin","4",true,true)

qin_zhilu = sgs.CreateViewAsSkill{
	name = "qin_zhilu",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if (#selected > 1) or to_select:hasFlag("using") then return false end
		if #selected > 0 then
			return to_select:getSuit() == selected[1]:getSuit()
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Self:isWounded() or (to_select:getSuit() == sgs.Card_Heart) then
				return true
			elseif sgs.Slash_IsAvailable(sgs.Self) and (to_select:getSuit() == sgs.Card_Diamond) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" then
				return to_select:isRed()
			elseif pattern == "slash" then
				return to_select:isBlack()
			end
			return false
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:isRed() then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:isBlack()then
			new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			if #cards == 1 then
				new_card:setSkillName(self:objectName())
				for _, c in ipairs(cards) do
					new_card:addSubcard(c)
				end
			end
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
				or (pattern == "jink")
	end,
}

qin_gaizhao = sgs.CreateTriggerSkill{
	name = "qin_gaizhao" ,
	events = {sgs.TargetConfirming} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.to:contains(player) then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if (not use.to:contains(p)) and p:getKingdom() == "qin" then
							_targets:append(p)
						end
					end
					if not _targets:isEmpty() then
						room:setTag("sheyanData", data)
						local s = room:askForPlayerChosen(player, _targets, "sheyan", "@sheyan:"..use.card:objectName(), true)
						if s then
							room:notifySkillInvoked(player, self:objectName())
							room:sendCompulsoryTriggerLog(player, self:objectName()) 
							room:broadcastSkillInvoke(self:objectName())
							room:doAnimate(1, player:objectName(), s:objectName())
							use.to:append(s)
							use.to:removeOne(player)
							room:sortByActionOrder(use.to)
							room:getThread():trigger(sgs.TargetConfirming, room, s, data)
							data:setValue(use)
						end
					end
				end
			end
		end
		return false
	end
}

qin_haizhong = sgs.CreateTriggerSkill{
	name = "qin_haizhong" ,
	events = {sgs.HpRecover} ,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			if not player:isAlive() then return false end
			if player:getKingdom() ~= "qin" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("qin_haizhong") then
						room:sendCompulsoryTriggerLog(p, self:objectName())
						room:notifySkillInvoked(p,self:objectName())
						if not room:askForCard(player, ".|red|.|.", "@qin_haizhong:"..p:objectName(), sgs.QVariant(), sgs.Card_MethodDiscard) then
							room:damage(sgs.DamageStruct(nil,p,player,1,sgs.DamageStruct_Normal))
						end
					end
				end
			end
		end
	end,
}

qin_yuanli = sgs.CreateTriggerSkill{
	name = "qin_yuanli",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Play then
				room:broadcastSkillInvoke("qin_yuanli")
				local ids = room:getDrawPile()
				local ids_type1 = sgs.IntList()
				local ids_move = sgs.IntList()
				if room:getDrawPile():length() > 0 then
					for _, id in sgs.qlist(room:getDrawPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("TrickCard") then
							ids_type1:append(card:getEffectiveId())
						end
						card:deleteLater()
					end
				end
				for i = 1 , 2, 1 do
					if ids_type1:length() > 0 then
						local get_id = ids_type1:at(math.random(1,ids_type1:length())-1)
						ids_type1:removeOne(get_id)
						ids_move:append(get_id)
					end
				end
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids_move
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
			end
		end
	end
}

qin_zhaogao:addSkill(qin_zhilu)
qin_zhaogao:addSkill(qin_gaizhao)
qin_zhaogao:addSkill(qin_haizhong)
qin_zhaogao:addSkill(qin_yuanli)

sgs.LoadTranslationTable{
	["qin_zhaogao"]="趙高",
	["qin_zhilu"]= "指鹿",
	["qin_gaizhao"]="改詔",
	["qin_haizhong"]="害忠",
	["qin_yuanli"]="爰歷",
	[":qin_zhilu"]="你可以將紅色手牌當【閃】使用或打出；將黑色手牌當【殺】使用或打出。",
	[":qin_gaizhao"]="當你成為【殺】或普通錦囊牌的目標後（借刀殺人除外），若場上有其他秦勢力角色存活，"
	.."你可以將此牌的目標改為其他不是該牌目標的秦勢力角色。",
	[":qin_haizhong"]= "鎖定技，非秦勢力角色回復體力時，其需要選擇：1.棄置一張紅色牌，2.受到你造成的1點傷害"..
	"。然後該角色獲得一個“害”標記。",
	[":qin_yuanli"]="鎖定技，你的出牌階段開始時，你額外獲得2張普通錦囊。",
	["@qin_haizhong"]="請棄置一張紅色牌，否則您受到 %src 造成的一點傷害",
}

--主技能
nl_QinMode = sgs.CreateTriggerSkill{
	name = "#nl_QinMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						if killer:getKingdom() ~= "qin" and player:getKingdom() == "qin" then
							killer:drawCards(3)
						end
						if killer:getKingdom() == "qin" and player:getKingdom() == "qin" then
						end
						if player:getKingdom() ~= "qin" then
							for _, p in sgs.qlist(room:getAlivePlayers()) do
								if p:getKingdom() ~= "qin" then
									p:drawCards(1)
								end
							end
						end

						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	

		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				local alive_num = room:getAlivePlayers():length()
				for i = 1, alive_num, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				local i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					room:setPlayerMark(p, "gameMode_QinMode", 1)
					i = i + 1
					if p:getGeneralName() == "sujiang" then
						if p:getMark("QinMode_player") > 0 then
							local sks_all = {"bujiang_01","bujiang_02","bujiang_03","bujiang_04",
								"bujiang_05","bujiang_06","bujiang_07","bujiang_08",
							"bujiang_09","bujiang_10","bujiang_11","bujiang_12"}
							local sks = {}

							for k = 1,5,1 do 
								local random1 = math.random(1, #sks_all)
								table.insert(sks, sks_all[random1])
								table.remove(sks_all, random1)
							end
							local general = room:askForGeneral(p, table.concat(sks, "+"))
							room:changeHero(p, general, false,false, false,false)

							local choice = room:askForChoice(p, "choose_kingdom", "wei+shu+wu+qun")
							room:setPlayerProperty(p,"kingdom",sgs.QVariant(choice))

						elseif p:getMark("QinMode_soilder") > 0 then
							local sks_all = {"qinjunbubing","qinjunqibing"}
							local sks = {}
							local random1 = math.random(1, #sks_all)
							table.insert(sks, sks_all[random1])
							local general = room:askForGeneral(p, table.concat(sks, "+"))
							room:changeHero(p, general, false,false, false,false)
							room:setPlayerMark(p,"QinMode_soilder",0)
						elseif i == 1 then
							local sks_all = {"qin_shangyang","qin_zhangyi","qin_mieyue","qin_baiqi"
							,"qin_yingzheng","qin_lubuwei","qin_zhaoji","qin_zhaogao"}
							local sks = {}
							local random1 = math.random(1, #sks_all)
							table.insert(sks, sks_all[random1])
							local general = room:askForGeneral(p, table.concat(sks, "+"))
							room:changeHero(p, general, false,false, false,false)
							if p:getMark("QinModeEvent") == 0 then
								local n = math.random(1,8)
								for _, p2 in sgs.qlist(room:getAlivePlayers()) do
									room:setPlayerMark(p2, "QinModeEvent", n)
								end
							end
						else
							choosenewgeneral(p, 5,false,{})
						end
					end
				end
				for _, p in sgs.qlist(_targets) do
					if p:getMark("QinModeEvent") == 3 and p:isFemale() then
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()+1))
						room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
					end
					if p:getMark("QinModeEvent") == 4 then
						room:attachSkillToPlayer(p,"AozhanMode_skill")
					end
				end
				local n = player:getMark("QinModeEvent")
				room:doSuperLightbox("zhozi","QinModeEvent"..n)
				local msg = sgs.LogMessage()
				msg.type = "#QinModeEvent"
				msg.from = player
				msg.arg = "QinModeEvent"..n
				msg.arg2 = "QinModeEvent"..n.."text"
				room:sendLog(msg)
				
				for _, p in sgs.qlist(_targets) do
					if p:getMark("QinMode_player") > 0 then
						getskill_QinMode(p,15,3)
						room:setPlayerMark(p,"QinMode_player",0)
					end
				end

				for _, p in sgs.qlist(_targets) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(_targets) do
					p:drawCards(4)
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
				if player:getMark("QinModeEvent") == 2 and not room:getTag("ExtraTurn"):toBool() then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerProperty(p, "chained", sgs.QVariant(true))
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}

QinModeEvent1skill = sgs.CreateTargetModSkill{
	name = "QinModeEvent1skill",
	frequency = sgs.Skill_Compulsory,
	pattern = "shangyangbianfa",
	extra_target_func = function(self, player)
		if player:getGeneralName() == "qin_shangyang" and player:getMark("QinModeEvent") == 1 then
			return 1
		end
	end,
}

QinModeEvent2skill = sgs.CreateTriggerSkill{
	name = "#QinModeEvent2skill",  
	events = {sgs.TurnStart,sgs.DrawNCards,sgs.CardsMoveOneTime,sgs.Damage,sgs.Death}, 
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TurnStart then
			if player:isLord() and (not room:getTag("ExtraTurn"):toBool()) and player:getMark("QinModeEvent") == 2 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerProperty(p, "chained", sgs.QVariant(true))
				end
			end
			if player:getMark("QinModeEvent") == 3 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isLord() and p:getGeneralName() == "qin_mieyue" then
						p:drawCards(1)
					end
				end
			end
			if player:getMark("QinModeEvent") == 4 and player:getKingdom() == "qin" then
				local lord_baiqi = false
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isLord() and p:getGeneralName() == "qin_baiqi" then
						lord_baiqi = true
					end
				end
				if lord_baiqi then
					local ids = room:getDrawPile()
					local ids_type1 = sgs.IntList()
					local ids_move = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if card:isKindOf("Peach") then
								ids_type1:append(card:getEffectiveId())
							end
							card:deleteLater()
						end
					end
					if ids_type1:length() > 0 then
						local get_id = ids_type1:at(math.random(1,ids_type1:length())-1)
						ids_type1:removeOne(get_id)
						ids_move:append(get_id)
					end
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids_move
					move.to = player
					move.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(move, true)
				end
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("QinModeEvent") == 5 and player:isMale() then
				local n = data:toInt()
				n = n + 1
				data:setValue(n)
			end
		elseif event == sgs.CardsMoveOneTime then		
			local move = data:toMoveOneTime()
			if player:getMark("QinModeEvent") == 5 and player:getGeneralName() == "qin_lubuwei" then
				if (move.to:objectName() == player:objectName())
					and (move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE)
					and move.to_place == sgs.Player_PlaceHand then
					if player:getPhase() == sgs.Player_NotActive then
						if not player:hasFlag("lubuwei_event") then
							room:setPlayerFlag(player, "lubuwei_event")		
							room:drawCards(player, 1)
						else
							room:setPlayerFlag(player, "-lubuwei_event")
						end
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if player:getMark("QinModeEvent") == 6 then
				local lord_zhaoji = false
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isLord() and p:getGeneralName() == "qin_zhaoji" then
						lord_zhaoji = true
					end
				end
				if player:getMark("QinModeEvent6-Clear") == 0 and
				 ((not lord_zhaoji) and player:isMale()) or
				 (lord_zhaoji and player:getKingdom() ~= "qin")  then
					damage.to:drawCards(1)
					room:setPlayerMark(player,"QinModeEvent6-Clear",1)
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:objectName() == player:objectName() or splayer:isNude() then return false end
			if player:isAlive() and player:isLord() and player:getMark("QinModeEvent") == 8 then

				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:objectName() == "qin_zhaogao" then
						if p:objectName() == "qin_zhaogao" then
							_targets:append(p)
						end
					else
						if p:isMale() then 
							_targets:append(p)
						end
					end
				end
				if not _targets:isEmpty() then

					local cards = splayer:getCards("he")
					for _,card in sgs.qlist(cards) do
						local length = _targets:length()
						local n = math.random(1, length)
						local q = _targets:at(n-1)
						q:addToPile("QinMode",card)
					end

					for _,p in sgs.qlist(room:getAlivePlayers()) do
						local n = p:getPile("QinMode"):length()
						if n > 0 then
							for i = 1, n,1 do
								local ids = p:getPile("QinMode")
								local id = ids:at(i-1)
								local card = sgs.Sanguosha:getCard(id)
								--id2s:append(card:getEffectiveId())
							end
							local move = sgs.CardsMoveStruct()
							move.card_ids = p:getPile("QinMode")
							move.to = p
							move.to_place = sgs.Player_PlaceHand
							move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
							room:moveCardsAtomic(move, true)
						end
					end
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		return target:getMark("gameMode_QinMode") > 0
	end,
}

--鏖戰
AozhanMode_skill = sgs.CreateOneCardViewAsSkill{
	name = "AozhanMode_skill&",
	response_or_use = true,
	view_filter = function(self, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Slash_IsAvailable(sgs.Self) and (to_select:isKindOf("Peach")) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" or pattern == "slash" then
				return to_select:isKindOf("Peach")
			end
			return false
		end
		return false
	end,
	view_as = function(self,card)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern ~= "jink" then
			pattern = "slash"
		end
		local cards = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, 0)
		cards:setSkillName(self:objectName())
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash") or (pattern == "jink")
	end,
}

AozhanMode_skill_ban = sgs.CreateProhibitSkill{
	name = "#AozhanMode_skill_ban",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return from:hasSkill("AozhanMode_skill") and card:isKindOf("Peach")
	end
}

if not sgs.Sanguosha:getSkill("AozhanMode_skill") then skills:append(AozhanMode_skill) end
if not sgs.Sanguosha:getSkill("#AozhanMode_skill_ban") then skills:append(AozhanMode_skill_ban) end

sgs.LoadTranslationTable{
["qin"] = "秦",
["QinModeEvent1"] = "變法圖強",
["QinModeEvent1text"] = "牌堆中加入3張錦囊牌【商鞅變法】。若商鞅在場，則商鞅使用【商鞅變法】可額外選擇一目標。",
["QinModeEvent2"] = "合縱連橫",
["QinModeEvent2text"] = "每輪開始時，場上所有角色進入橫置狀態。若場上有張儀，則擁有“橫”標記的角色無法對橫置狀"
.."態的角色使用牌。 ",
["QinModeEvent3"] = "始太后",
["QinModeEvent3text"] = "本局遊戲中，女性角色體力值和體力上限額外+1。若羋月在場，則男性角色回合開始時需要選擇"
.."：1.讓羋月回復1點體力；2.讓羋月摸一張牌。",
["QinModeEvent4"] = "血戰長平",
["QinModeEvent4text"] = "本局遊戲始終處於鏖戰狀態，牌堆中所有的桃均視為“殺/閃”，並且所有角色成為殺的目標時，"
.."需要額外打出一張閃才能抵消該殺。若白起在場，則秦勢力角色回合開始時，額外獲得一張“殺/閃”。",
["QinModeEvent5"] = "呂氏春秋",
["QinModeEvent5text"] = "本局遊戲中，所有男性角色摸牌階段摸牌數+1。若呂不韋在場，則呂不韋的回合外，其每次從"
.."牌堆中摸牌時，額外多摸一張牌。",
["QinModeEvent6"] = "禍亂宮闈",
["QinModeEvent6text"] = "本局遊戲中，男性角色於回合內第一次造成傷害時，受到傷害的角色摸一張牌。若趙姬在場上，"
.."則此效果的適用角色改為所有非秦勢力角色。",
["QinModeEvent7"] = "橫掃六合",
["QinModeEvent7text"] = "牌堆中加入傳國玉璽和真龍長劍。若嬴政在場，則遊戲開始時嬴政裝備傳國玉璽和真龍長劍。",
["QinModeEvent8"] = "沙丘之謀",
["QinModeEvent8text"] = "本局遊戲中，所有陣亡角色的手牌和裝備牌在進入棄牌堆之後，重新隨機分配給在場的男性角色"
.."（若沒有男性角色則全部棄置）。若趙高在場，則趙高獲得之。",
["AozhanMode_skill"] = "鏖戰",
[":AozhanMode_skill"] = "本局遊戲中，你可以將桃均視為“殺/閃”使用",
["#QinModeEvent"] = "本局遊戲特殊規則為 %arg ，內容為 %arg2",
["QinMode"] = "沙丘",
["choose_kingdom"] = "選擇勢力",
}

if not sgs.Sanguosha:getSkill("#nl_QinMode") then skills:append(nl_QinMode) end
if not sgs.Sanguosha:getSkill("#QinModeEvent2skill") then skills:append(QinModeEvent2skill) end
if not sgs.Sanguosha:getSkill("QinModeEvent1skill") then skills:append(QinModeEvent1skill) end

--[[

無盡模式（將星模式）

]]--

str_wujinexample = sgs.General(extension, "str_wujinexample", "tan", "12",  true, true, true)
-- 特殊技能
--【禦陣】鎖定技，遊戲開始時，所有己方角色回復3點體力
--【盾擋】鎖定技，你受到殺的傷害-1
wujin_dundang = sgs.CreateTriggerSkill{
	name = "wujin_dundang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				local msg = sgs.LogMessage()
				msg.type = "#wujin_dundang"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage + 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	

				if damage.damage > 1 then
					damage.damage = damage.damage - 1
					data:setValue(damage)
				else
					return true
				end
			end
		end
	end,
}
str_wujinexample:addSkill(wujin_dundang)

sgs.LoadTranslationTable{
	["wujin_dundang"] = "盾擋",
	[":wujin_dundang"] = "鎖定技，你受到殺的傷害-1",
	["#wujin_dundang"] = "%from 的技能“<font color=\"yellow\"><b>盾擋</b></font>”被觸發，%to 造成的傷害由 %arg 點減少到"..
" %arg2 點",
}
--【破謀】鎖定技，你受到錦囊的傷害-1
wujin_pomou = sgs.CreateTriggerSkill{
	name = "wujin_pomou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("TrickCard") then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				local msg = sgs.LogMessage()
				msg.type = "#wujin_pomou"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage + 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	

				if damage.damage > 1 then
					damage.damage = damage.damage - 1
					data:setValue(damage)
				else
					return true
				end
			end
		end
	end,
}

str_wujinexample:addSkill(wujin_pomou)

sgs.LoadTranslationTable{
	["wujin_pomou"] = "破謀",
	[":wujin_pomou"] = "鎖定技，你受到錦囊的傷害-1",
	["#wujin_pomou"] = "%from 的技能“<font color=\"yellow\"><b>破謀</b></font>”被觸發，%to 造成的傷害由 %arg 點減少到"..
" %arg2 點",
}
--【激怒】鎖定技，其他己方角色死亡時，你回滿體力，摸三張牌，並獲得技能【破防】和【咆哮】
wujin_jinu = sgs.CreateTriggerSkill{
	name = "wujin_jinu",
	events = {sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local splayer = death.who
		if splayer:objectName() == player:objectName() then return false end
		if splayer:getRole() ~= player:getRole() then return false end
		if player:isAlive() and room:askForSkillInvoke(player, self:objectName(), data) then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:drawCards(player, 3, "wujin_jinu")
			local theRecover = sgs.RecoverStruct()
			theRecover.recover = (player:getMaxHp() - player:getHp())
			theRecover.who = player
			room:recover(player, theRecover)
			room:acquireSkill(player, "paoxiao")			
			room:acquireSkill(player, "wujin_pofang")
		end
		return false
	end
}

str_wujinexample:addSkill(wujin_jinu)

sgs.LoadTranslationTable{
	["wujin_jinu"] = "激怒",
	[":wujin_jinu"] = "鎖定技，其他己方角色死亡時，你回滿體力，摸三張牌，並獲得技能【破防】和【咆哮】",
}

--【破防】鎖定技，你使用【殺】指定目標後，此【殺】無視防具且不能被【閃】抵消
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
wujin_pofang = sgs.CreateTriggerSkill{
	name = "wujin_pofang" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					--if player:askForSkillInvoke(self:objectName(), _data) then
						room:notifySkillInvoked(player, "wujin_pofang")	
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						local msg = sgs.LogMessage()
						msg.type = "#Liegong1"
						msg.from = player
						msg.to:append(p)
						msg.arg = self:objectName()
						msg.arg2 = use.card:objectName()
						msg.card_str = use.card:toString()
						room:sendLog(msg)	
						jink_table[index] = 0
					--end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		end
	end
}
str_wujinexample:addSkill(wujin_pofang)

sgs.LoadTranslationTable{
	["wujin_pofang"] = "破防",
	[":wujin_pofang"] = "鎖定技，你使用【殺】指定目標後，此【殺】無視防具且不能被【閃】抵消",
}
--【威壓】鎖定技，出牌階段開始時，若你的手牌數是全場最多，你對每名敵方角色造成1點傷害
wujin_weiya = sgs.CreateTriggerSkill{
	name = "wujin_weiya",
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Draw then
			local player_card = {}
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				table.insert(player_card, p:getHandcardNum())
			end
			if player:getHandcardNum() == math.max(unpack(player_card)) then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:getRole() ~= p:getRole() then
						room:doAnimate(1, player:objectName(), p:objectName())
						room:damage(sgs.DamageStruct("wujin_weiya", player, p, 1, sgs.DamageStruct_Normal))
					end
				end
			end
		end
	end
}
str_wujinexample:addSkill(wujin_weiya)

sgs.LoadTranslationTable{
	["wujin_weiya"] = "威壓",
	[":wujin_weiya"] = "鎖定技，出牌階段開始時，若你的手牌數是全場最多，你對每名敵方角色造成1點傷害",
}
--【壓迫】鎖定技，敵方角色的回合結束，若其手牌數大於等於其當前體力值，你棄置其兩張手牌
wujin_yapo = sgs.CreateTriggerSkill{
	name = "wujin_yapo",
	events = {sgs.EventPhaseEnd} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getHandcardNum() > player:getHp() and player:getRole() ~= p:getRole() then
					room:askForDiscard(player, self:objectName(), 2, 2, false, false)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

str_wujinexample:addSkill(wujin_yapo)

sgs.LoadTranslationTable{
	["wujin_yapo"] = "壓迫",
	[":wujin_yapo"] = "鎖定技，敵方角色的回合結束，若其手牌數大於等於其當前體力值，你棄置其兩張手牌",
}
--【太守】鎖定技，當你受到傷害時，此傷害-1
wujin_taishou = sgs.CreateTriggerSkill{
	name = "wujin_taishou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local msg = sgs.LogMessage()
			msg.type = "#wujin_taishou"
			msg.from = player
			msg.to:append(damage.to)
			msg.arg = tostring(damage.damage + 1)
			msg.arg2 = tostring(damage.damage)
			room:sendLog(msg)	

			if damage.damage > 1 then
				damage.damage = damage.damage - 1
				data:setValue(damage)
			else
				return true
			end
		end
	end,
}
str_wujinexample:addSkill(wujin_taishou)
sgs.LoadTranslationTable{
	["wujin_taishou"] = "太守",
	[":wujin_taishou"] = "鎖定技，當你受到傷害時，此傷害-1",
	["#wujin_taishou"] = "%from 發動了技能“<font color=\"yellow\"><b>太守</b></font>”，%to 造成的傷害由 %arg 點減少到"..
" %arg2 點",
}
--【堅城】鎖定技，每名角色的回合結束時，若你的手牌數小於當前體力值，你摸兩張牌 
wujin_jiancheng = sgs.CreateTriggerSkill{
	name = "wujin_jiancheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Finish then
			for _, s in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if s:getHandcardNum() < s:getHp() then
					room:notifySkillInvoked(s, self:objectName())
					room:sendCompulsoryTriggerLog(s, self:objectName()) 
					s:drawCards(2)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
str_wujinexample:addSkill(wujin_jiancheng)
sgs.LoadTranslationTable{
	["wujin_jiancheng"] = "堅城",
	[":wujin_jiancheng"] = "鎖定技，每名角色的回合結束時，若你的手牌數小於當前體力值，你摸兩張牌",
}
--【破釜】鎖定技，摸牌階段，若你的手牌數小於等於一張，你多摸一張牌且本回合【殺】造成的傷害+1 
wujin_pofu = sgs.CreateTriggerSkill{
	name = "wujin_pofu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards,sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if event == sgs.DrawNCards then
			if player:getHandcardNum() < 2 then
				room:setPlayerFlag(player,"wujin_pofu")
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				local count = data:toInt() + 1
				data:setValue(count)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				if player:hasFlag("wujin_pofu") then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
					msg.type = "#wujin_pofu"
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
}
str_wujinexample:addSkill(wujin_pofu)

sgs.LoadTranslationTable{
	["wujin_pofu"] = "破釜",
	[":wujin_pofu"] = "鎖定技，摸牌階段，若你的手牌數小於等於一張，你多摸一張牌且本回合【殺】造成的傷害+1 ",
	["#wujin_pofu"] = "%from 發動了技能“<font color=\"yellow\"><b>破釜</b></font>”，對 %to 造成傷害由 %arg 點增加到"..
" %arg2 點",
}

--【襲擊】鎖定技，敵方角色的回合結束時，若其手牌數小於其當前體力值，你對其造成2點傷害 
wujin_xiji = sgs.CreateTriggerSkill{
	name = "wujin_xiji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		local s = room:findPlayerBySkillName(self:objectName())
		if phase == sgs.Player_Finish then
			if player:getHandcardNum() < player:getHp() and player:getRole() ~= s:getRole() then
				room:notifySkillInvoked(s, self:objectName())
				room:sendCompulsoryTriggerLog(s, self:objectName()) 
				room:doAnimate(1, player:objectName(), s:objectName())
				room:damage(sgs.DamageStruct("wujin_weiya", s, player, 1, sgs.DamageStruct_Normal))
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

str_wujinexample:addSkill(wujin_xiji)

sgs.LoadTranslationTable{
	["wujin_xiji"] = "襲擊",
	[":wujin_xiji"] = "鎖定技，敵方角色的回合結束時，若其手牌數小於其當前體力值，你對其造成2點傷害",
}

--帝刀
nl_didao = sgs.CreateTriggerSkill{
	name = "nl_didao" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.to:getHandcardNum() >= damage.from:getHandcardNum() then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#NlDidao"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
			end
			return false
		end
	end
}

--帝旗
nl_dichi = sgs.CreateTriggerSkill{
	name = "nl_dichi",	
	events = {sgs.GameStart,sgs.DrawNCards,sgs.EventPhaseStart,sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local invoke = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSameTeam(p,player) and p:hasSkill("nl_dichi") then
					invoke = true
				end
			end
			if invoke then
				local count = data:toInt() + 1
				data:setValue(count)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

nl_dichiTargetMod = sgs.CreateTargetModSkill{
	name = "nl_dichiTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, target)
		local extra = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if isSameTeam(p,target) and p:hasSkill("nl_dichi") then
				extra = extra + 1
			end
		end
		if target:hasSkill("nl_dichi") then
			extra = extra + 1
		end
		return extra
	end
}

nl_dichiMax = sgs.CreateMaxCardsSkill{
	name = "nl_dichiMax", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		local extra = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if isSameTeam(p,target) and p:hasSkill("nl_dichi") then
				extra = extra + 1
			end
		end
		if target:hasSkill("nl_dichi") then
			extra = extra + 1
		end
		return extra
	end
}

--無盡 將星 主技能
nl_GeneralStarMode = sgs.CreateTriggerSkill{
	name = "#nl_GeneralStarMode",
	--events = {sgs.EventPhaseChanging,sgs.Death,sgs.Damage},
	events = {sgs.EventPhaseChanging,sgs.Death,sgs.DamageComplete},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:isLord() and player:getMark("gs_stage") == 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "loyalist" then
						choosenewgeneral(p, 10,false,{},player)
						room:getThread():delay()
					elseif p:getRole() == "lord" then
						choosenewgeneral(p, 10,false,{})
						room:getThread():delay()
						choosejiangling(p,5,false,{})
						room:getThread():delay()
					elseif p:getRole() == "rebel" then
						choosenewgeneral(p, 1,false,{})
					end
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "loyalist" then
						p:drawCards(4)
					elseif p:getRole() == "lord" then
						p:drawCards(4)
					elseif p:getRole() == "rebel" then
						p:drawCards(2)
					end
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
				room:setPlayerMark(player, "gs_stage", 1)
				player:gainMark("@Ingots",5)
			end

			if phase == sgs.Player_RoundStart and player:isLord() then
				if player:getMark("gs_stage") > 6 then
					player:gainMark("@Ingots",3)
				else
					player:gainMark("@Ingots",2)
				end
			end

			if phase == sgs.Player_RoundStart and player:getMark("@AG_enternextstage") > 0 then
				local lord_player
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "lord" then
						lord_player = p
						break
					end
				end
				for _, p in sgs.qlist(room:getPlayers()) do 
					if p:isDead() and lord_player:getMark("gs_stage") < 11 and p:getRole() == "rebel" then
						local hclist = {4,4,5,5,6,6,7,7,8,8}
						local hplist = {0,0,0,1,1,1,2,2,2,3}
						room:revivePlayer(p)
						if lord_player:getMark("gs_stage") < 10 then
							choosenewgeneral(p, 1,false,{})
							room:getThread():trigger(sgs.GameStart, room, p, data)
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()+hplist[lord_player:getMark("gs_stage")]))
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
							room:setTag("FirstRound" , sgs.QVariant(true))
							p:drawCards(hclist[lord_player:getMark("gs_stage")])
							room:setTag("FirstRound" , sgs.QVariant(false))

							if lord_player:getMark("gs_stage") >=  5 then
								local wujinskills = {"wujin_xiji","wujin_dundang","wujin_pomou","wujin_jinu","wujin_pofang",
								"wujin_weiya","wujin_yapo","wujin_taishou","wujin_jiancheng","wujin_pofu"}		
								room:acquireSkill(p, wujinskills[math.random(1,#wujinskills)])
							end
						else
							room:changeHero(p, "sy_zhangrang2", true, true, false, true)
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(9))
							room:setPlayerProperty(p, "hp", sgs.QVariant(9))
							room:setTag("FirstRound" , sgs.QVariant(true))
							p:drawCards(10)
							room:setTag("FirstRound" , sgs.QVariant(false))


							local wujinskills = {"wujin_xiji","wujin_dundang","wujin_pomou","wujin_jinu","wujin_pofang",
							"wujin_weiya","wujin_yapo","wujin_taishou","wujin_jiancheng","wujin_pofu"}	
							room:acquireSkill(p, wujinskills[math.random(1,#wujinskills)])
						end
					end
					if (not p:isAlive()) and lord_player:getMark("gs_stage") < 11 and p:getRole() == "loyalist" and lord_player:getMark("@Ingots") >= 8 then
						if room:askForSkillInvoke(lord_player, "nl_ganlu", data) then
							room:revivePlayer(p)
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
							p:drawCards(4)
							lord_player:loseMark("@Ingots",8)
						end
					end
				end
			end
		elseif event == sgs.Death and player:isLord() then
			local death = data:toDeath()
			local splayer = death.who
			if splayer:isLord() then return false end
			if splayer:getRole() == "loyalist" then return false end
			if player:isAlive() then
				room:setPlayerMark(player, "gs_stage", player:getMark("gs_stage")+1)

				if player:getMark("gs_stage") == 6 then
					room:doLightbox("$nl_GeneralStarModelimit5", 3000)
					room:acquireSkill(player, "nl_didao")
				end
				if player:getMark("gs_stage") == 9 then
					room:doLightbox("$nl_GeneralStarModelimit8", 3000)
					room:acquireSkill(player, "nl_dichi")
				end

				if player:getMark("gs_stage") < 11 and splayer:getRole() == "rebel" then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getRole() == "loyalist" then
							local theRecover2 = sgs.RecoverStruct()
							theRecover2.recover = 1
							theRecover2.who = p
							room:recover(p, theRecover2)
						elseif p:getRole() == "lord" then
							local theRecover2 = sgs.RecoverStruct()
							theRecover2.recover = 1
							theRecover2.who = p
							room:recover(p, theRecover2)
						end
						if p:getRole() == "loyalist" or p:getRole() == "lord" then
							local pmarks = {"@talent_privilege1","@talent_privilege2",
							"@talent_privilege3","@talent_privilege4"}
							for _,pmark in pairs(pmarks) do
								if p:getMark(pmark) == 5 then
									table.removeOne(pmarks,pmark)
								end
							end
							local random1 = math.random(1, #pmarks)
							p:gainMark(pmarks[random1],1)
						end
					end
				elseif player:getMark("gs_stage") > 10 and splayer:getGeneralName() == "sy_zhangrang2" then
					room:doLightbox("$nl_GeneralStarModelimitEnd", 3000)
					room:gameOver("lord")
				end
			end
		--elseif event == sgs.Damage then
		elseif event == sgs.BeforeGameOverJudge then
			--local death = data:toDeath()
			--[[
			if player:getMark("AG_firstplayer") > 0 then
				local now = player:getNextAlive()
				room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
				room:setPlayerMark(now, "AG_firstplayer", 1)
				if room:getCurrent():objectName() == player:objectName() then
					room:setPlayerMark(now, "@stop_invoke", 1)
				end
			end
			]]--
			--if player:getHp() <= 0 and player:isLord() then
				
				local lord_player
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "lord" then
						lord_player = p
						break
					end
				end
				if lord_player:getMark("gs_stage") < 10  then	
					room:setTag("SkipGameRule",sgs.QVariant(true))

						for _,p2 in sgs.qlist(room:getPlayers()) do
							room:setPlayerMark(p2,"@AG_enternextstage",1)
						end

				end
				return false
			--end 
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}

--鼎牌系統
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end
local patterns = {}
for i = 0, 10000 do
	local card = sgs.Sanguosha:getEngineCard(i)
	if card == nil then break end
	if not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()] and (card:isKindOf("BasicCard") or card:isNDTrick()) and not table.contains(patterns, card:objectName()) then
		table.insert(patterns, card:objectName())
	end
end
function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end
local pos = 0
nl_dingpai_select = sgs.CreateSkillCard{
	name = "nl_dingpai", 
	will_throw = false, 
	target_fixed = true, 
	handling_method = sgs.Card_MethodNone, 
	on_use = function(self, room, source, targets)
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			poi:setSkillName("nl_dingpai")
			--poi:addSubcard(self:getSubcards():first())
			if poi:isAvailable(source) and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
				if name == "slash" and (source:getMark("@Ingots") >= 2) then
					table.insert(choices, name)
				elseif name == "jink" and (source:getMark("@Ingots") >= 2) then
					table.insert(choices, name)
				elseif name == "peach" and (source:getMark("@Ingots") >= 4) then
					table.insert(choices, name)
				elseif name == "amazing_grace" and (source:getMark("@Ingots") >= 4) then
					table.insert(choices, name)
				elseif name == "ex_nihilo" and (source:getMark("@Ingots") >= 6) then
					table.insert(choices, name)
				elseif name == "duel" and (source:getMark("@Ingots") >= 2) then
					table.insert(choices, name)
				elseif name == "savage_assault" and (source:getMark("@Ingots") >= 4) then
					table.insert(choices, name)
				elseif name == "archery_attack" and (source:getMark("@Ingots") >= 6) then
					table.insert(choices, name)
				elseif name == "dismantlement" and (source:getMark("@Ingots") >= 2) then
					table.insert(choices, name)
				elseif name == "snatch" and (source:getMark("@Ingots") >= 3) then
					table.insert(choices, name)
				end
			end
		end
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "nl_dingpai", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then			
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("nl_dingpai")
					--poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "nl_dingpaipos", pos)
					--room:setPlayerProperty(source, "nl_dingpai", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@nl_dingpai", "@nl_dingpai:"..pattern)--%src
				end
			end
		end
	end, 
}
nl_dingpaiCard = sgs.CreateSkillCard{
	name = "nl_dingpaiCard", 
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
			local name = room:askForChoice(user, "nl_dingpai", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		--use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("nl_dingpai")
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
			local name = room:askForChoice(card_use.from, "nl_dingpai", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("nl_dingpai")
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
nl_dingpaiVS = sgs.CreateViewAsSkill{
	name = "nl_dingpai",
	n = 0,
	response_or_use = true,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local acard = nl_dingpai_select:clone()
			return acard
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then 
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = nl_dingpaiCard:clone()
			if pattern and pattern == "@@nl_dingpai" then
				pattern = patterns[sgs.Self:getMark("nl_dingpaipos")]
				--acard:addSubcard(sgs.Self:property("nl_dingpai"):toInt())
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
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) then
				table.insert(choices, name)
			end
		end
		if player:getMark("@Ingots") < 2 then
			return false
		end
		return next(choices)
	end, 
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		for _, p in pairs(pattern:split("+"))do
			if (p == "slash") and player:getMark("@Ingots") < 2 then
				return false
			end
			if ((p == "jink") and player:getMark("@Ingots") < 2) then
				return false
			end	
			if ((p == "peach") and (not player:hasFlag("Global_PreventPeach")) and player:getMark("@Ingots") < 5) then
				return false
			end
		end
		return true
	end, 
} 

nl_dingpai = sgs.CreateTriggerSkill{
	name = "nl_dingpai", 
	view_as_skill = nl_dingpaiVS, 
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished}, 
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
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "nl_dingpai" and use.card:getTypeId() ~= 0 then
				if use.card:isKindOf("Slash") then
					player:loseMark("@Ingots",2)
				elseif use.card:isKindOf("Jink") then
					player:loseMark("@Ingots",2)
				elseif use.card:isKindOf("Peach") then
					player:loseMark("@Ingots",4)
				elseif use.card:isKindOf("AmazingGrace") then
					player:loseMark("@Ingots",4)
				elseif use.card:isKindOf("ExNihilo") then
					player:loseMark("@Ingots",6)
				elseif use.card:isKindOf("Duel") then
					player:loseMark("@Ingots",2)
				elseif use.card:isKindOf("SavageAssault") then
					player:loseMark("@Ingots",4)
				elseif use.card:isKindOf("ArcheryAttack") then
					player:loseMark("@Ingots",6)
				elseif use.card:isKindOf("Dismantlement") then
					player:loseMark("@Ingots",2)
				elseif use.card:isKindOf("Snatch") then
					player:loseMark("@Ingots",3)
				end
			end
		end
	end
}

--密卷 
--mijuan
--[[
暗度陳倉：出牌階段，對你使用。 （不能被無懈可擊響應），獲得己方其他角色的所有手牌，然後你可以交給這些角色任意張牌。
落井下石：出牌階段，對一名已受傷的角色使用。獲得其一張手牌、一張裝備區裡的牌，然後對其造成1點傷害。
舌戰群儒：出牌階段，對所有敵方角色使用。你獲得手牌數大於等於你的角色一張手牌，體力值大於等於你體力值的角色失去1點體力。
草木皆兵：出牌階段，對所有敵方角色使用，你選擇一種顏色，每名目標角色棄置所有該顏色的手牌和裝備區裡的牌。
援護：出牌階段，對所有己方角色使用。手牌數小於體力上限的角色將手牌摸至體力上限；手牌數大於等於體力上限的角色回復1點體力。
一刀斬：出牌階段，對一名體力值小於等於你的角色使用。 （不能被無懈可擊響應）對其造成X點傷害（X為你的體力值）。
anduchencang luojingxiashi shezhanqunru 
caomujiebing mj_yuanhu yidaozhan
史詩鼎牌：目前都是“秘卷”：由強力武將將其畢生所學記錄而成的精華，擁有秘卷，可以擁有相應武將的技能效果。目前有以下6種秘卷：“秘卷：補益”，“秘卷：遺計”，“秘卷：梟姬”“秘卷：完殺”“秘卷：咆哮”“秘卷：集智”目前僅可通過首次通關第125關，150關，175關，200關獲得隨機一個。
“秘卷：補益”：出牌階段，對你使用。 （不能被無懈可擊響應），你獲得技能“補益”直到你的下回合開始。 （已有補益技能則使用無效）
“秘卷：遺計”：出牌階段，對你使用。 （不能被無懈可擊響應），你獲得技能“遺計”直到你的下回合開始。 （標準版遺計、已有遺計（無論是否突破）技能則使用無效））
“秘卷：梟姬”：出牌階段，對你使用。 （不能被無懈可擊響應）本回合你獲得技能“梟姬”，最多發動十次。 （已有梟姬技能則使用無效）
“秘卷：完殺”：出牌階段，對你使用。 （不能被無懈可擊響應）本回合你獲得技能“完殺”
“秘卷：咆哮”：出牌階段，對你使用。 （不能被無懈可擊響應）本回合你可以多使用十張殺。
“秘卷：集智”：出牌階段，對你使用。 （不能被無懈可擊響應）本回合你使用錦囊牌時，摸一張牌。最多摸十次。
buyi yiji xiaoji wansha paoxiao jizhi
]]--
function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

nl_mijuanCard = sgs.CreateSkillCard{
	name = "nl_mijuan" ,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {"anduchencang","luojingxiashi","shezhanqunru","caomujiebing","mj_yuanhu",
		"yidaozhan","cancel"}
		local choice = room:askForChoice(source,self:objectName(),table.concat(choices, "+"))
		if choice ~= "cancel" then
			source:loseMark("@Ingots",8)
		end
		if choice == "anduchencang" then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					targets:append(p)
					source:obtainCard(p:getCards("h"))
				end
			end
			local n = source:getCards("he"):length()
			while room:askForYiji(source, getIntList(source:getCards("he")), self:objectName(), true, false, true, n, targets) do
				
			end
		elseif choice == "luojingxiashi" then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isWounded() then
					targets:append(p)
				end
			end
			local target = room:askForPlayerChosen(source,targets,self:objectName())
			if target then
				if source:canDiscard(target, "h") then
					local id = room:askForCardChosen(source, target, "h", "jielve")
					room:obtainCard(source, id, true)
				end
				if source:canDiscard(target, "e") then
					local id = room:askForCardChosen(source, target, "e", "jielve")
					room:obtainCard(source, id, true)
				end
				room:damage(sgs.DamageStruct(nil,source,target,1,sgs.DamageStruct_Normal))
			end
		elseif choice == "shezhanqunru" then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "rebel" then
					if p:getHandcardNum() >= source:getHandcardNum() then
						local id = room:askForCardChosen(source, p, "h", "jielve")
						room:obtainCard(source, id, true)
					end
					if p:getHp() >= source:getHp() then
						room:loseHp(p)
					end
				end
			end
		elseif choice == "caomujiebing" then
			local choices_cmjb = {"red","black"}
			local choice2 = room:askForChoice(source,self:objectName(),table.concat(choices_cmjb, "+"),data)
			if choice2 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getRole() == "rebel" then
						local ids = sgs.IntList()
						for _, id in sgs.qlist(p:getHandcards()) do 
							if id:isRed() and choice2 == "red" then
								ids:append(id:getEffectiveId())
							end
							if id:isBlack() and choice2 == "black" then
								ids:append(id:getEffectiveId())
							end
						end
						for _, id in sgs.qlist(p:getEquips()) do 
							if id:isRed() and choice2 == "red" then
								ids:append(id:getEffectiveId())
							end
							if id:isBlack() and choice2 == "black" then
								ids:append(id:getEffectiveId())
							end
						end
						if not ids:isEmpty() then
							local move = sgs.CardsMoveStruct()
							move.card_ids = ids
							move.to = nil
							move.to_place = sgs.Player_DiscardPile
							move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, p:objectName(), nil, "caomujiebing", nil)
							room:moveCardsAtomic(move, true)
						end	
					end
				end
			end
		elseif choice == "mj_yuanhu" then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					if p:getHandcardNum() < p:getMaxHp() then
						local n = p:getMaxHp() - p:getHandcardNum()
						p:drawCards(n)
					else
						room:recover(p, sgs.RecoverStruct(p, nil, 1))
					end
				end
			end
		elseif choice == "yidaozhan" then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() < source:getHp() then
					targets:append(p)
				end
			end
			local target = room:askForPlayerChosen(source,targets,self:objectName())
			if target then
				room:damage(sgs.DamageStruct(nil,source,target,source:getHp(),sgs.DamageStruct_Normal))
			end
		end
	end
}

nl_mijuan = sgs.CreateZeroCardViewAsSkill{
	name = "nl_mijuan&",
	view_as = function()
		return nl_mijuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@Ingots") >= 8
	end,
}

nl_ganluCard = sgs.CreateSkillCard{
	name = "nl_ganlu" ,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local _targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getPlayers()) do
			if ((not p:isAlive()) and p:getRole() == "loyalist") then _targets:append(p) end
		end
		if not _targets:isEmpty() then	
			local p = room:askForPlayerChosen(source, _targets, "nl_ganlu", nil, true)
			if p then
				room:revivePlayer(p)
				room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
				p:drawCards(4)
				source:loseMark("@Ingots",8)
			end
		end
	end
}

nl_ganlu = sgs.CreateZeroCardViewAsSkill{
	name = "nl_ganlu&",
	view_as = function()
		return nl_ganluCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@Ingots") >= 8
	end,
}

nl_changeheroCard = sgs.CreateSkillCard{
	name = "nl_changehero" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:getRole() == "loyalist"
	end,
	on_use = function(self, room, source, targets)
		choosenewgeneral(targets[1], 10, false,{},source)
		source:loseMark("@Ingots",4)
	end
}

nl_changehero = sgs.CreateZeroCardViewAsSkill{
	name = "nl_changehero&",
	view_as = function()
		return nl_changeheroCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@Ingots") >= 4
	end,
}

if not sgs.Sanguosha:getSkill("#nl_GeneralStarMode") then skills:append(nl_GeneralStarMode) end
if not sgs.Sanguosha:getSkill("nl_didao") then skills:append(nl_didao) end
if not sgs.Sanguosha:getSkill("nl_dichi") then skills:append(nl_dichi) end
if not sgs.Sanguosha:getSkill("nl_dichiTargetMod") then skills:append(nl_dichiTargetMod) end
if not sgs.Sanguosha:getSkill("nl_dichiMax") then skills:append(nl_dichiMax) end
if not sgs.Sanguosha:getSkill("nl_dingpai") then skills:append(nl_dingpai) end
if not sgs.Sanguosha:getSkill("nl_changehero") then skills:append(nl_changehero) end
if not sgs.Sanguosha:getSkill("nl_ganlu") then skills:append(nl_ganlu) end
if not sgs.Sanguosha:getSkill("nl_mijuan") then skills:append(nl_mijuan) end

sgs.LoadTranslationTable{
	["#nl_GeneralStarMode"] = "武將變身",
	["$nl_GeneralStarModelimit5"] = "將軍德才兼備，大漢之棟樑也，朕賜卿寶刀一支",
	["$nl_GeneralStarModelimit8"] = "將軍武勇，天下無雙，特賜御旗一面",
	["$nl_GeneralStarModelimitEnd"] = "恭喜主公，已順利平定天下！",
	["nl_didao"] = "帝刀",
	["nl_dichi"] = "帝旗",

	[":nl_didao"] = "鎖定技，你對手牌數小於你的角色造成的傷害+1",
	[":nl_dichi"] = "鎖定技，我方所有角色摸牌數+1，手牌上限+1，使用殺的數量+1",

	["#NlDidao"] = "%from 的技能 “<font color=\"yellow\"><b>帝刀</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",

	["nl_dingpai"] = "鼎牌",
	[":nl_dingpai"] = "你可以消耗元寶，並視為使用一張牌",

		["nl_mijuan"] = "密卷",
		["@Ingots"] = "元寶",
		["nl_ganlu"] = "甘露",
		["nl_changehero"] = "換將",

	["anduchencang"] = "暗度陳倉",
	["luojingxiashi"] = "落井下石",
	["shezhanqunru"] = "舌戰群儒",
	["caomujiebing"] = "草木皆兵",
	["mj_yuanhu"] = "援護",
	["yidaozhan"] = "一刀斬",

	[":anduchencang"] = "出牌階段，對你使用。 （不能被無懈可擊響應），獲得己方其他角色的所有手牌，然後你可以交給這些角色任意張牌。",
	[":luojingxiashi"] = "出牌階段，對一名已受傷的角色使用。獲得其一張手牌、一張裝備區裡的牌，然後對其造成1點傷害。",
	[":shezhanqunru"] = "出牌階段，對所有敵方角色使用。你獲得手牌數大於等於你的角色一張手牌，體力值大於等於你體力值的角色失去1點體力。",
	[":caomujiebing"] = "出牌階段，對所有敵方角色使用，你選擇一種顏色，每名目標角色棄置所有該顏色的手牌和裝備區裡的牌。",
	[":mj_yuanhu"] = "出牌階段，對所有己方角色使用。手牌數小於體力上限的角色將手牌摸至體力上限；手牌數大於等於體力上限的角色回復1點體力。",
	[":yidaozhan"] = "出牌階段，對一名體力值小於等於你的角色使用。 （不能被無懈可擊響應）對其造成X點傷害（X為你的體力值）。",
}


--[[

幻化模式

]]--

--獲得技能
function GenerateRandomskill(zuoci,n)
	local room = zuoci:getRoom()
	local Huashens = {}
	local old_zuoci = room:findPlayerBySkillName("huashen")
	local Huashens1 = {}--获取山包左慈的化身武将
	if old_zuoci and old_zuoci:isAlive() then
		local Hs_String1 = old_zuoci:getTag("Huashens"):toString()
		if Hs_String1 and Hs_String1 ~= "" then
			Huashens1 = Hs_String1:split("+")
		end
	end

	local generals = sgs.Sanguosha:getLimitedGeneralNames()
	local banned = {}
	local alives = room:getAlivePlayers()

	for i=1, #generals, 1 do
		for _,p in sgs.qlist(alives) do
			if p:getGeneralName() == generals[i] then
				--table.remove(generals, i)
				table.removeOne(generals, generals[i])
			end
			if p:getGeneral2() and p:getGeneral2Name() == generals[i] then
				--table.remove(generals, i)
				table.removeOne(generals, generals[i])
			end
		end
		if table.contains(Huashens1, generals[i]) then
			table.removeOne(generals, generals[i])
		end
		if table.contains(banned, generals[i])then
			table.removeOne(generals, generals[i])
		end
		if table.contains(AG_allbanlist, generals[i])then
			table.removeOne(generals, generals[i])
		end

	end

	--local general_name = room:askForGeneral(player, table.concat(Huashens, "+"))	
	--local general = sgs.Sanguosha:getGeneral(general_name)		
	--for _,sk in sgs.qlist(general:getVisibleSkillList()) do
	--	room:acquireSkill(player, sk)
	--end

	local sks = {}
		
	for _,general_name in ipairs(generals) do		
		local general = sgs.Sanguosha:getGeneral(general_name)		
		for _,sk in sgs.qlist(general:getVisibleSkillList()) do
			if not sk:isLordSkill() then
				if sk:getFrequency() ~= sgs.Skill_Limited then
					if sk:getFrequency() ~= sgs.Skill_Wake then
						local can_use = true
						for _,p in sgs.qlist(alives) do
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


	local choose_sks = {}
	for i = 1,n,1 do 
		local random1 = math.random(1, #sks)
		table.insert(choose_sks, sks[random1])
		table.remove(sks, random1)
	end
	return choose_sks
end


--擊殺獎勵
nl_huanhuaModekill = sgs.CreateTriggerSkill{
	name = "#nl_huanhuaModekill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if player:getHp() <= 0 and player:getMark("AG_firstplayer") > 0 then
			local now = player:getNextAlive()
			room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
			local current = room:getCurrent()
			if room:getCurrent():objectName() == player:objectName() then
				room:setPlayerMark(now, "@stop_invoke", 1)
			end
		end
		if dying.damage then
			local killer = dying.damage.from
			if player:getHp() <= 0 then
				if killer:hasSkill(self:objectName()) then
					killer:drawCards(2)
					killer:gainMark("@zongzi",2)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--選將
zzz_huanhua_01 = sgs.General(extension,"zzz_huanhua_01","wei","4",false,true,true)
zzz_huanhua_02 = sgs.General(extension,"zzz_huanhua_02","shu","4",false,true,true)
zzz_huanhua_03 = sgs.General(extension,"zzz_huanhua_03","wu","4",false,true,true)
zzz_huanhua_04 = sgs.General(extension,"zzz_huanhua_04","qun","4",false,true,true)
zzz_huanhua_05 = sgs.General(extension,"zzz_huanhua_05","wei","4",false,true,true)
zzz_huanhua_06 = sgs.General(extension,"zzz_huanhua_06","shu","4",false,true,true)
zzz_huanhua_07 = sgs.General(extension,"zzz_huanhua_07","wu","4",false,true,true)
zzz_huanhua_08 = sgs.General(extension,"zzz_huanhua_08","qun","4",false,true,true)

function choosenewgeneral_huanhua(source, n)
	local room = source:getRoom()
	local Chosens = {}

	local generals = {}
	local all_generals = {"zzz_huanhua_01","zzz_huanhua_02","zzz_huanhua_03","zzz_huanhua_04",
	"zzz_huanhua_05","zzz_huanhua_06","zzz_huanhua_07","zzz_huanhua_08"}


	local alives = room:getAlivePlayers()

	for i=1, #all_generals, 1 do
		local can_use = true
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == all_generals[i] then
				can_use = false
			end
			if p:getGeneral2() and p:getGeneral2Name() == all_generals[i] then
				can_use = false
			end
		end
		if table.contains(banned, all_generals[i])then
			can_use = false
		end

		if table.contains(Huashens1, all_generals[i])then
			can_use = false
		end
		
		if table.contains(AG_allbanlist, all_generals[i])then
			can_use = false
		end

		if can_use then
			table.insert(generals, all_generals[i])
		end
	end

	for i = 1, #generals , 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end
	local general = room:askForGeneral(source, table.concat(Chosens, "+"))
	room:changeHero(source, general, false,false, false,false)
	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end

zongzi_drawCard = sgs.CreateSkillCard{
	name = "zongzi_draw",
	target_fixed = true,
	on_use = function(self, room, source)
		local draw_num = {}
		for i = 1, source:getMark("@zongzi") do
			table.insert(draw_num, tostring(i))
		end
		local choice = room:askForChoice(source, "zongzi_draw", table.concat(draw_num, "+"))
		source:loseMark("@zongzi", tonumber(choice))
		room:drawCards(source, tonumber(choice))
		room:setPlayerMark(source,"zongzi_lose-Clear",source:getMark("zongzi_lose-Clear") + tonumber(choice))
	end
}
zongzi_draw = sgs.CreateZeroCardViewAsSkill{
	name = "zongzi_draw&",
	view_as = function()
		return zongzi_drawCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@zongzi") > 0 and (not player:hasUsed("#zongzi_draw"))
	end
}

nl_huanhuaMode = sgs.CreateTriggerSkill{
	name = "#nl_huanhuaMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.Death,sgs.Damage,sgs.Damaged,sgs.HpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use_player = room:getPlayers():at(0)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart then
				if player:getMark("@leader") > 0 then
					room:setPlayerProperty(player, "role", sgs.QVariant("renegade"))
					room:updateStateItem()
					room:resetAI(player)
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, "player_seat_original", p:getSeat())
					end

					local wh_targets = sgs.SPlayerList()
					local whtarget1 = player

					for i = 1, (room:alivePlayerCount()), 1 do
						wh_targets:append(whtarget1)
						whtarget1 = whtarget1:getNextAlive()
					end

					local i = 0
					for _, p in sgs.qlist(wh_targets) do
						i = i + 1
						if i == 7 or i == 8 then
							p:gainMark("@zongzi",3)
						else
							p:gainMark("@zongzi",2)
						end
					end

					for _, p in sgs.qlist(wh_targets) do
						huanhua_skills = {"xisheng","shulu","qingyi"}
						choosenewgeneral_huanhua(p, 1)
						local choice = room:askForChoice(p, "choose_skill", table.concat(huanhua_skills, "+"))			
						room:acquireSkill(p, choice)
					end
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						--room:setPlayerMark(p,"gameMode_wenho",1)
					end
					for _, p in sgs.qlist(wh_targets) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
												getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					end


					--local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
					--card_remover:trigger(sgs.GameStart, room, player, data)

					room:setTag("FirstRound" , sgs.QVariant(true))
					for _, p in sgs.qlist(wh_targets) do
						if p:getMark("@leader") > 0 then
							p:drawCards(3)
						else
							p:drawCards(4)
						end
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
					room:setPlayerMark(player, "@leader", 0)
				end
				--其他角色的回合開始前
				if player:getMark("@zongzi") >= 2 then
					if room:askForSkillInvoke(player, "zongzi_skill") then
						player:loseMark("@zongzi",2)
						room:setPlayerMark(player,"zongzi_lose-Clear",player:getMark("zongzi_lose-Clear") + 2)

						local random_skill_list = GenerateRandomskill(player,3)
						local choice = room:askForChoice(player, "zongzi_skill", table.concat(random_skill_list, "+"))			
						room:acquireSkill(player, choice)

						local SkillList = {}
						for _,skill in sgs.qlist(player:getVisibleSkillList()) do
							if skill:objectName() ~= "zongzi_draw" then
								table.insert(SkillList, skill:objectName())
							end
						end
						if #SkillList >= 4 then
							local choice = room:askForChoice(player, self:objectName(), table.concat(SkillList, "+"))
							room:detachSkillFromPlayer(player, choice)
						end
					end
				end
			elseif phase == sgs.Player_NotActive then
				if player:getMark("zongzi_lose-Clear") < 2  then
					player:loseMark("@zongzi",(2-player:getMark("zongzi_lose-Clear")))
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.damage > 0 then
				player:gainMark("@zongzi",damage.damage)
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.damage > 0 then
				player:loseMark("@zongzi",damage.damage)
				room:setPlayerMark(player,"zongzi_lose-Clear",player:getMark("zongzi_lose-Clear") + damage.damage)
			end
		elseif event == sgs.HpRecover then
			local rec = data:toRecover()
			if rec.who then
				rec.who:gainMark("@zongzi",rec.recover)
			end

		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			
			if room:alivePlayerCount() == 1 then
				local winner
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					winner = p:objectName()
				end
				room:getThread():delay()
				if winner then
					room:gameOver(winner)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end,
	priority = 99,
}

if not sgs.Sanguosha:getSkill("#nl_huanhuaMode") then skills:append(nl_huanhuaMode) end
if not sgs.Sanguosha:getSkill("#nl_huanhuaModekill") then skills:append(nl_huanhuaModekill) end
if not sgs.Sanguosha:getSkill("zongzi_draw") then skills:append(zongzi_draw) end

sgs.LoadTranslationTable{
	["zongzi_skill"] = "粽子技能",
	["@zongzi"] = "粽子",
	["zzz_huanhua_01"] = "士兵一",
	["zzz_huanhua_02"] = "士兵二",
	["zzz_huanhua_03"] = "士兵三",
	["zzz_huanhua_04"] = "士兵四",
	["zzz_huanhua_05"] = "士兵五",
	["zzz_huanhua_06"] = "士兵六",
	["zzz_huanhua_07"] = "士兵七",
	["zzz_huanhua_08"] = "士兵八",
	["zongzi_draw"] = "粽摸",
	["#nl_huanhuaMode"] = "幻化之戰",
}

--[[

怒焰三分模式

]]--
AngerMode = sgs.CreateTriggerSkill{
	name = "#AngerMode",
	events = {sgs.ChoiceMade, sgs.BeforeCardsMove, sgs.PreCardUsed, sgs.CardFinished, sgs.CardResponded,
	sgs.PreHpRecover, sgs.ConfirmDamage, sgs.CardUsed, sgs.Damaged, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--累積怒氣值
		if event == sgs.Damaged	then
			local damage = data:toDamage()
			if player:getMark("@anger") <= 3 then
				if player:getMark("@anger") <= 3 then
					player:gainMark("@anger", math.min(damage.damage,3 - player:getMark("@anger")))
				end
				room:notifySkillInvoked(player, self:objectName())
			end
		elseif event == sgs.ChoiceMade then
			local choices = data:toString():split(":")
			if player:getMark("@anger") > 0 then
				if room:askForSkillInvoke(player, "AngerMode", data) then
					if (choices[1] == "cardChosen" and choices[2] == "dismantlement" and choices[4] == player:objectName()) then
						player:loseMark("@anger", 1)
						room:setCardFlag(sgs.Sanguosha:getCard(choices[3]), "anger_dismantlement_card")
					end
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if (move.from and move.from:objectName() ~= player:objectName() --[[and move.from_places:contains(sgs.Player_PlaceEquip)]])and move.to_place == sgs.Player_DiscardPile then
				if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
					for _, card_id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(card_id)
						if card:hasFlag("anger_dismantlement_card") then
							player:obtainCard(card)
							if move.card_ids:contains(card_id) then
								local index = move.card_ids:indexOf(card_id)
								move.from_places:removeAt(index)
								move.card_ids:removeOne(card_id)
								data:setValue(move)
							end
						end
					end
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getMark("@anger") > 0 then
				if use.card:isKindOf("GlobalEffect") then
					if room:askForSkillInvoke(player, "AngerMode", data) then
						player:loseMark("@anger", 1)
						local removed = room:askForPlayerChosen(player, room:getAlivePlayers(), "qiaoshui:remove", "@qiaoshui-remove:::" .. use.card:objectName())
						use.to:removeOne(removed)
						local extra = room:askForPlayerChosen(player, room:getAlivePlayers(), "qiaoshui:add", "@qiaoshui-add:::" .. use.card:objectName())
						use.to:append(extra)
						data:setValue(use)
					end
				elseif use.card:isKindOf("Snatch") then
					if room:askForSkillInvoke(player, "AngerMode", data) then
						player:loseMark("@anger", 1)
						for _,p in sgs.qlist(use.to) do
							room:setTag("Dongchaee",sgs.QVariant(p:objectName()))
							room:setTag("Dongchaer",sgs.QVariant(player:objectName()))
						end
					end
				elseif use.card:isKindOf("Peach") or use.card:isKindOf("Slash") or use.card:isKindOf("Duel") then
					if room:askForSkillInvoke(player, "AngerMode", data) then
						player:loseMark("@anger", 1)
						room:setCardFlag(use.card, "anger_card")
					end
				elseif use.card:isKindOf("SingleTargetTrick") or use.card:isKindOf("Analeptic") then
					if room:askForSkillInvoke(player, "AngerMode", data) then
						player:loseMark("@anger", 1)
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Snatch") then
				room:setTag("Dongchaee",sgs.QVariant())
				room:setTag("Dongchaer",sgs.QVariant())
			end

		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:hasFlag("anger_card") then
				local log = sgs.LogMessage()
				log.type = "$anger_REC"
				log.from = player
				room:sendLog(log)
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("anger_card") then
				local log = sgs.LogMessage()
				log.type = "$anger_DMG"
				log.from = player
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("anger_card") and damage.card:isKindOf("Duel") then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
				room:recover(player, recover)
			end
		elseif event == sgs.CardResponded or event == sgs.CardUsed then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				--local response = data:toCardResponse()
				--if response.m_isUse then
				--	card = response.m_card
				--end
				card = data:toCardResponse().m_card	
			end
			if card and (card:isKindOf("Jink") or card:isKindOf("Nullification")) then
				if player:getMark("@anger") > 0 then
					if room:askForSkillInvoke(player, "AngerMode", data) then
						--if resp.m_card:isKindOf("Jink") and resp.m_who:objectName() ~= player:objectName() then
						player:loseMark("@anger", 1)
						player:drawCards(1)
					end
				end
			end
		end
		return false
	end
}

function choosenewgeneralAnger(source, n)
	local room = source:getRoom()
	local Chosens = {}

	local generals = {}
	local all_generals = {"caocao","simayi","xiahoudun","zhangliao","guojia","xuchu","zhenji","lidian",
	 "liubei","guanyu","zhangfei","zhugeliang","zhaoyun","machao","nos_huangyueying","st_xushu",
	 "sunquan","ganning","lvmeng","zhouyu","daqiao","sunshangxiang","lvbu","diaochan","xiahouyuan",
	 "ol_huangzhong","xiaoqiao","xuhuang","zhurong","sunjian","jiaxu","dongzhuo","dianwei","wolong",
	 "pangtong","taishici","yanliangwenchou","pangde","jiangwei","sunce","caozhi","fazheng","lingtong",
	 "wuguotai","xusheng","gaoshun","chengong","zhangchunhua","zhonghui","xunyou","wangyi","madai",
	 "bulianshi","handang","liubiao","caochong","jianyong","liufeng","panzhangmazhong","yufan",
	 "fuhuanghou","liru","caifuren","guyong","jvshou","zhoucang","gongsunyuan","guotufengji","liuchen",
	 "sunxiu","yj_xiahoushi","caoang","simalang","zhugeke","liuxie","yuejin",
	 "dingfeng","hetaihou","yangxiu","guanyinping","xiahouba","zhangbao","zumao","chengyu",
	 "sp_wenpin","sunhao","jsp_sunshangxiang","jsp_jiangwei","str_yanbyhu","sr_machao",
	 "bug_caoren","sr_liubei","sr_xiahoudun","ol_machao","sr_simayi","ol_mayunlu","str_qunmachao",
	 "wangji"}
	local banned = {}
	for i=1, #all_generals, 1 do
		local can_use = true
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == all_generals[i] then
				can_use = false
			end
			if p:getGeneral2() and p:getGeneral2Name() == all_generals[i] then
				can_use = false
			end
		end
		if table.contains(banned, all_generals[i])then
			can_use = false
		end

		if table.contains(Huashens1, all_generals[i])then
			can_use = false
		end
		
		if table.contains(AG_allbanlist, all_generals[i])then
			can_use = false
		end

		if can_use then
			table.insert(generals, all_generals[i])
		end
	end

	all_generals = nil
	for i = 1, n, 1 do
		if #generals > 0 then
			local j = math.random(1, #generals)
			local getGeneral = generals[j]
			table.insert(Chosens, getGeneral)
			table.remove(generals, j)
		end
	end
	local general = room:askForGeneral(source, table.concat(Chosens, "+"))
	room:changeHero(source, general, false,false, false,false)
	room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()))
end


AngerMode2 = sgs.CreateTriggerSkill{
	name = "#AngerMode2",
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			--[[
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
			local loyalist_win = true
			local rebel_win = true
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "loyalist" then
					rebel_win = false
				elseif p:getRole() == "rebel" then
					loyalist_win = false
				end
			end
			if loyalist_win then
				room:gameOver("loyalist")
			elseif rebel_win then
				room:gameOver("rebel")
			end
			]]--
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					room:setPlayerProperty(p, "role", sgs.QVariant("renegade"))
					room:updateStateItem()
					room:resetAI(p)
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					choosenewgeneralAnger(p, 5)
				end
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					p:drawCards(4)
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
if not sgs.Sanguosha:getSkill("#AngerMode") then skills:append(AngerMode) end
if not sgs.Sanguosha:getSkill("#AngerMode2") then skills:append(AngerMode2) end


sgs.LoadTranslationTable{
	["AngerMode"] = "怒焰",
	["@anger"] = "怒",
	["$anger_REC"] = "%from 使用怒氣強化，此【桃】的回復值+1",
	["$anger_DMG"] = "%from 使用怒氣強化，此【殺】的傷害值+1",
}

--[[
2020十大年獸
]]--

--[[
年獸大魏
男 7血 魏
反戈 當你受到傷害後，你可以摸兩張牌，然後若這兩張牌點數之差大於等於你當前體力值，你對傷害來源造成1點傷害（對己方角色無效）。
]]--
nianshou_wei = sgs.General(extension,"nianshou_wei","wei",7, true, true, true)

nianshou_fange = sgs.CreateMasochismSkill{
	name = "nianshou_fange",
	frequency = sgs.Skill_Frequent,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		if room:getCurrentDyingPlayer() then return false end
		local data = sgs.QVariant()
		data:setValue(damage.from)
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())

			local ids = room:getNCards(2, false)
			local c1 = sgs.Sanguosha:getCard(ids:at(0)):getNumber()
			local c2 = sgs.Sanguosha:getCard(ids:at(1)):getNumber()
			player:drawCards(2)
			if damage.from and damage.from:isAlive() and math.abs(c1-c2) >= player:getHp() and isSameTeam(player,damage.from) then
				room:damage(sgs.DamageStruct(self, player, damage.from, 1))
			end
		end
	end
}

nianshou_wei:addSkill(nianshou_fange)

sgs.LoadTranslationTable{
	["nianshou_wei"] = "年獸大魏",
	["nianshou_fange"] = "反戈",
	[":nianshou_fange"] = "當你受到傷害後，你可以摸兩張牌，然後若這兩張牌點數之差大於等於你當前體力值，你對傷害來源造成1點傷害（對己方角色無效）。",
}

--[[
年獸大蜀
男 4血 蜀
撕咬 你使用【殺】指定目標後，你可以對此【殺】目標中的敵方角色各造成1點傷害。然後此【殺】造成傷害後，受傷角色隨機棄置一張牌。
橫掃 鎖定技，出牌階段開始時，若你的手牌數為三到六張，你本階段【殺】的次數+1，目標數+1。
]]--
nianshou_shu = sgs.General(extension,"nianshou_shu","shu",4, true, true, true)

nianshou_siyao = sgs.CreateTriggerSkill{
	name = "nianshou_siyao" ,
	events = {sgs.TargetSpecified,sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			for _, p in sgs.qlist(use.to) do
				if isSameTeam(player,p) then
					room:setCardFlag(use.card, "nianshou_siyao_card")
					room:damage(sgs.DamageStruct(self, player, p, 1))
				end
			end

		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") and damage.card:hasFlag("nianshou_siyao_card") then
					local loot_cards = sgs.QList2Table(damage.to:getCards("he"))
					if #loot_cards > 0 then
						room:throwCard(loot_cards[math.random(1, #loot_cards)], damage.to ,player)
					end
					
				end
			end
		end
	end
}

nianshou_hengsao = sgs.CreateTriggerSkill{
	name = "nianshou_hengsao",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play then
			if player:getHandcardNum() >= 3 and player:getHandcardNum() <= 6 then
				room:addPlayerMark(player, "nianshou_hengsao_Play")
			end
		end
	end
}

nianshou_hengsaotm = sgs.CreateTargetModSkill{
	name = "#nianshou_hengsaotm",
	frequency = sgs.Skill_Compulsory,
	extra_target_func = function(self, from)
		if from:getMark("nianshou_hengsao_Play") > 0 then
			return 1
		end
		return 0
	end,
	residue_func = function(self, from)
		if from:getMark("nianshou_hengsao_Play") > 0 then
			return 1
		end
		return 0
	end,
}

nianshou_shu:addSkill(nianshou_siyao)
nianshou_shu:addSkill(nianshou_hengsao)
nianshou_shu:addSkill(nianshou_hengsaotm)

sgs.LoadTranslationTable{
	["nianshou_shu"] = "年獸大蜀",
	["nianshou_siyao"] = "撕咬",
	[":nianshou_siyao"] = "你使用【殺】指定目標後，你可以對此【殺】目標中的敵方角色各造成1點傷害。然後此【殺】造成傷害後，受傷角色隨機棄置一張牌。",
	["nianshou_hengsao"] = "橫掃",
	[":nianshou_hengsao"] = "鎖定技，出牌階段開始時，若你的手牌數為三到六張，你本階段【殺】的次數+1，目標數+1。",
	["#nianshou_hengsaotm"] = "橫掃",
}

--[[
年獸大吳
女 5血 吳
朱顏 鎖定技，摸牌階段，你放棄摸牌，改為從牌堆中隨機獲得四張牌。
梟姬 當你失去裝備區裡的一張牌後，你可以摸兩張牌。
]]--

nianshou_wu = sgs.General(extension,"nianshou_wu","wu",5, false, true, true)

nianshou_zhuyan = sgs.CreateTriggerSkill{
	name = "nianshou_zhuyan",
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
					local ids = room:getDrawPile()
				
					local ids_move = sgs.IntList()
					local ids_type = sgs.IntList()
					local ids_type2 = sgs.IntList()
					local ids_type3 = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							ids_type1:append(card:getEffectiveId()) 
							card:deleteLater()
						end
					end

					for i = 1 , 4, 1 do
						if ids_type1:length() > 0 then
							local get_id = ids_type1:at(math.random(1,ids_type1:length())-1)
							ids_type1:removeOne(get_id)
							ids_move:append(get_id)
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

nianshou_shu:addSkill(nianshou_zhuyan)
nianshou_shu:addSkill("xiaoji")

sgs.LoadTranslationTable{
	["nianshou_shu"] = "年獸大吳",
	["nianshou_zhuyan"] = "朱顏",
	[":nianshou_zhuyan"] = "鎖定技，摸牌階段，你放棄摸牌，改為從牌堆中隨機獲得四張牌。",
}

--[[
年獸大群
男 5血 群
群響 鎖定技，準備階段或結束階段，你視為使用一張【南蠻入侵】或【萬箭齊發】。
貪食 當你造成傷害後，你可以進行一次判定，若結果為黑色，你回復1點體力（若你體力滿則改為摸一張牌）。
]]--

nianshou_qun = sgs.General(extension,"nianshou_qun","qun",5, true, true, true)

nianshou_qunxiang = sgs.CreateTriggerSkill{
	name = "nianshou_qunxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local invoke = false
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if math.random(1,2) == 1 then
					invoke = true
				else
					room:setPlayerFlag(player,"nianshou_qunxiang_after")
				end
			elseif player:getPhase() == sgs.Player_Finish then
				if player:hasFlag("nianshou_qunxiang_after") then
					invoke = true
				end
			end
		end
		if invoke then
			if math.random(1,2) == 1 then
				local players = sgs.SPlayerList()
				local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not player:isProhibited(p, archery_attack) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					archery_attack:setSkillName("nianshou_qunxiang")
					local use = sgs.CardUseStruct()
					use.card = archery_attack
					use.from = player
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end
			else			
				local players = sgs.SPlayerList()
				local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not player:isProhibited(p, savage_assault) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					savage_assault:setSkillName("nianshou_qunxiang")
					local use = sgs.CardUseStruct()
					use.card = savage_assault
					use.from = player
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end
			end		
		end
	end,
}

nianshou_tanshi = sgs.CreateTriggerSkill{
	name = "nianshou_tanshi",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if event == sgs.Damage then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|black"
			judge.who = player
			judge.reason = self:objectName()
			judge.good = true
			room:judge(judge)
			if judge:isGood() then
				if player:isWounded() then
					player:drawCards(1)
				else
					room:recover(player, sgs.RecoverStruct(player))
				end					
			end
		end
		return false
	end
}

nianshou_qun:addSkill(nianshou_qunxiang)
nianshou_qun:addSkill(nianshou_tanshi)

sgs.LoadTranslationTable{
	["nianshou_qun"] = "年獸大群",
	["nianshou_qunxiang"] = "群響",
	[":nianshou_qunxiang"] = "鎖定技，準備階段或結束階段，你視為使用一張【南蠻入侵】或【萬箭齊發】。",
	["nianshou_tanshi"] = "貪食",
	[":nianshou_tanshi"] = "當你造成傷害後，你可以進行一次判定，若結果為黑色，你回復1點體力（若你體力滿則改為摸一張牌）。",
}

--[[
年獸魏蜀
男 5血 蜀
祛蔽 當你造成或受到傷害後，若此傷害不是【殺】造成的，你可令受傷角色或傷害來源隨機棄置一張【殺】和一張【閃】。備註：有【殺】和【閃】就隨機棄置，不需要選，只有一種就棄一種，都沒有就不棄。
化吉 鎖定技，己方角色回合結束時，若其本回合跳過了摸牌階段，你摸兩張牌；若其本回合跳過了出牌階段，你隨機對一名敵方角色造成1點火焰傷害。
]]--
nianshou_weishu = sgs.General(extension,"nianshou_weishu","shu",5, true, true, true)

nianshou_qubi = sgs.CreateTriggerSkill{
	name = "nianshou_qubi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage,sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local dest = damage.to
		if damage.from and damage.to and ((not damage.card) or (damage.card and not damage.card:isKindOf("Slash"))) then
			if damage.from:objectName() == player:objectName() then
				source = player
				dest = damage.to
			else
				source = player
				dest = damage.from
			end
			if not dest:isNude() then
				if room:askForSkillInvoke(source, self:objectName(), data) then
					room:notifySkillInvoked(source, "nianshou_qubi")
					room:broadcastSkillInvoke("nianshou_qubi")
					
					local cards = dest:getHandcards()
					local slash_ids = sgs.IntList()
					local jink_ids = sgs.IntList()
					local ids = sgs.IntList()
					for _, card in sgs.qlist(cards) do
						if choice == "Slash" then
							if card:isKindOf("BasicCard") then
								slash_ids:append(card:getEffectiveId())
							end
						end 
						if choice == "Jink" then
							if card:isKindOf("TrickCard") then
								jink_ids:append(card:getEffectiveId())
							end
						end
					end

					if slash_ids:length() > 0 then
						ids:append(slash_ids:at(math.random(1,slash_ids:length())-1))
					end
					if jink_ids:length() > 0 then
						ids:append(jink_ids:at(math.random(1,jink_ids:length())-1))
					end

					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = nil
					move.to_place = sgs.Player_DiscardPile
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, target:objectName(), nil, "str_chilo", nil)
					room:moveCardsAtomic(move, true)
				end				
			end
		end
		return false
	end
}

nianshou_huaji = sgs.CreateTriggerSkill{
	name = "nianshou_huaji",
	events = {sgs.EventPhaseSkipping,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseSkipping then
			if player:getPhase() == sgs.Player_Draw or player:getPhase() == sgs.Player_Play then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:objectName() ~= player:objectName() and isSameTeam(player,p) then
						--SendComLog(self, p)
						if player:getPhase() == sgs.Player_Draw then
							room:addPlayerMark(player, self:objectName().."skipdraw-Clear")
						else
							room:addPlayerMark(player, self:objectName().."skipplay-Clear")
						end
					end
				end
			end
			return false
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:objectName() ~= player:objectName() and isSameTeam(player,p) then
					if p:getMark(self:objectName().."skipdraw-Clear") > 0 then
						p:getMark(2)
					end
					if p:getMark(self:objectName().."skipplay-Clear") > 0 then

						local all_alive_players = {}
						for _, q in sgs.qlist(room:getOtherPlayers(p)) do
							if not isSameTeam(q,p) then
								table.insert(all_alive_players, q)
							end
						end
						if  #all_alive_players > 0 then
							local random_target = all_alive_players[math.random(1, #all_alive_players)]
							room:damage(sgs.DamageStruct(self:objectName(), p, random_target,1,sgs.DamageStruct_Fire ))
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

nianshou_weishu:addSkill(nianshou_qubi)
nianshou_weishu:addSkill(nianshou_huaji)

sgs.LoadTranslationTable{
	["nianshou_weishu"] = "年獸魏蜀",

	["nianshou_qubi"] = "祛蔽",
	[":nianshou_qubi"] = "當你造成或受到傷害後，若此傷害不是【殺】造成的，你可令受傷角色或傷害來源隨機棄置一張【殺】和一張【閃】。備註：有【殺】和【閃】就隨機棄置，不需要選，只有一種就棄一種，都沒有就不棄。",

	["nianshou_huaji"] = "化吉",
	[":nianshou_huaji"] = "鎖定技，己方角色回合結束時，若其本回合跳過了摸牌階段，你摸兩張牌；若其本回合跳過了出牌階段，你隨機對一名敵方角色造成1點火焰傷害。",
}

--[[
年獸魏吳
男 6血 魏
威嚇 當你成為【殺】的目標後，你可令此【殺】的使用者隨機棄置兩張牌。若這兩張牌是同一類型，你隨機獲得其中一張。
]]--
nianshou_weiwu = sgs.General(extension,"nianshou_weishu","wei",6, true, true, true)

nianshou_weihe = sgs.CreateTriggerSkill{
	name = "nianshou_weihe" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())

						local loot_cards = sgs.QList2Table(use.from:getCards("he"))
						local dis_cards = {}
						local n = math.random(1, #loot_cards)
						table.append(dis_cards ,loot_cards[n])
						table.removeOne(loot_cards,loot_cards[n])
						table.append(dis_cards ,loot_cards[math.random(1, #loot_cards)])

						room:throwCard(dis_cards,player,player)
						if sgs.Sanguosha:getCard(dis_cards[1]):getTypeId() == sgs.Sanguosha:getCard(dis_cards[2]):getTypeId() then
							room:obtainCard(source, dis_cards[math.random(1, #dis_cards)], false)
						end
					end
				end
			end
		end
		return false
	end
}

nianshou_weiwu:addSkill(nianshou_weihe)

sgs.LoadTranslationTable{
	["nianshou_weishu"] = "年獸魏蜀",

	["nianshou_weihe"] = "威嚇",
	[":nianshou_weihe"] = "當你成為【殺】的目標後，你可令此【殺】的使用者隨機棄置兩張牌。若這兩張牌是同一類型，你隨機獲得其中一張。",
}

--[[
年獸魏群
男 6血 群
餘響鎖定技，一名敵方角色的回合結束時，若你本回合失去過基本牌，當前回合角色隨機棄置一張手牌；若你本回合失去過錦囊牌，當前回合角色受到1點傷害；若你本回合失去過裝備牌，你摸一張牌並回復1點體力。
]]--
nianshou_weiqun = sgs.General(extension,"nianshou_weiqun","qun",6, true, true, true)

nianshou_yuxiang = sgs.CreateTriggerSkill{
	name = "nianshou_yuxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if (move.from and move.from:objectName() == p:objectName() and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == p:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
					for _,id in sgs.qlist(move.card_ids) do
						if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
							room:setPlayerMark(p, self:objectName().."BasicCard-Clear")
						end
						if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
							room:setPlayerMark(p, self:objectName().."TrickCard-Clear")
						end
						if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
							room:setPlayerMark(p, self:objectName().."EquipCard-Clear")
						end
					end

				end
			elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:objectName() ~= p:objectName() and not isSameTeam(player,p) then
				if p:getMark(self:objectName().."BasicCard-Clear") > 0 then
					local hand = player:getCards("h"):at(math.random(0, player:getCards("h"):length() - 1))
					room:throwCard(hand,player,player)
				end
				if p:getMark(self:objectName().."TrickCard-Clear") > 0 then
					room:damage(sgs.DamageStruct(self:objectName(), p, player))
				end
				if p:getMark(self:objectName().."EquipCard-Clear") > 0 then
					p:drawCards(1)
					room:recover(p, sgs.RecoverStruct(p))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

nianshou_weiqun:addSkill(nianshou_yuxiang)

sgs.LoadTranslationTable{
	["nianshou_weiqun"] = "年獸魏群",

	["nianshou_yuxiang"] = "餘響",
	[":nianshou_yuxiang"] = "鎖定技，一名敵方角色的回合結束時，若你本回合失去過基本牌，當前回合角色隨機棄置一張手牌；若你本回合失去過錦囊牌，當前回合角色受到1點傷害；若你本回合失去過裝備牌，你摸一張牌並回復1點體力。",
}

--[[
年獸蜀吳
女 8血 吳
幻靈 鎖定技，你跳過摸牌階段；出牌階段開始時，你視為依次隨機使用兩張普通錦囊牌，且目標隨機指定敵方角色。
返功 結束階段，若你本回合沒有造成過傷害，你可以摸兩張牌。備註：傷害被防止也算作沒造成傷害。
huanling fangong
]]--
nianshou_shuwu = sgs.General(extension,"nianshou_shuwu","wu",8, false, true, true)

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

nianshou_huanling = sgs.CreateTriggerSkill{
	name = "nianshou_huanling",
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if not player:isSkipped(change.to) and (change.to == sgs.Player_Draw) then
				player:skip(change.to)
			end
		elseif event == sgs.EventPhaseStart then
			for k = 1,2,1 do
				for i = 0, 10000 do
					local card = sgs.Sanguosha:getEngineCard(i)
					if card == nil then break end
					if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
						if card:isAvailable(player) and player:getMark("AG_BANCard"..card:objectName()) == 0 and card:isNDTrick() then
							table.insert(choices, card:objectName())
						end
					end
				end

				local pattern = choices[math.random(1,#choices)]
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				
				local all_alive_players = {}
				for _, q in sgs.qlist(room:getOtherPlayers(p)) do
					if not isSameTeam(q,p) then
						table.insert(all_alive_players, q)
					end
				end
				if  #all_alive_players > 0 then
					local random_target = all_alive_players[math.random(1, #all_alive_players)]
					room:useCard(sgs.CardUseStruct(poi, player, random_target))
				end
			end
		end
	end
}

nianshou_fangong = sgs.CreateTriggerSkill{
	name = "nianshou_fangong",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase ==  sgs.Player_Finish then
				room:notifySkillInvoked(player, self:objectName())
				if player:getMark("damage_point_round") == 0 then
					player:drawCards(2)
				end
			end
		end
	end
}

nianshou_shuwu:addSkill(nianshou_huanling)
nianshou_shuwu:addSkill(nianshou_fangong)

sgs.LoadTranslationTable{
	["nianshou_shuwu"] = "年獸蜀吳",
	["nianshou_huanling"] = "幻靈",
	[":nianshou_huanling"] = "鎖定技，你跳過摸牌階段；出牌階段開始時，你視為依次隨機使用兩張普通錦囊牌，且目標隨機指定敵方角色。",
	["nianshou_fangong"]= "返功",
	[":nianshou_fangong"]= "結束階段，若你本回合沒有造成過傷害，你可以摸兩張牌。",
}

--[[
年獸蜀群
男 6血 蜀
巡狩 鎖定技，準備階段，所有手牌數大於3的敵方角色隨機棄置兩張手牌。
尋獵 鎖定技，結束階段，所有體力值大於3的敵方角色受到1點傷害。
xunshou xunlie
]]--
nianshou_shuqun = sgs.General(extension,"nianshou_shuwu","shu",6, true, true, true)
--[[
年獸吳群
男 6血 群
禍重 每個出牌階段限一次，當你於回合內使用的錦囊牌進入棄牌堆後，你可以棄置一張牌然後將此錦囊牌收回手牌。若你以此法棄置的牌是裝備牌，你摸一張牌。
攢戈 鎖定技，己方有角色陣亡時，你隨機將牌堆中的一張武器牌、一張防具牌、一張+1坐騎和一張-1坐騎置入裝備區。
huozhong zange
]]--
nianshou_wuqun = sgs.General(extension,"nianshou_wuqun","qun",8, true, true, true)

--神之試煉
--------------------------------------------------------------------------------------------------------------------------------------
zhuque = sgs.General(extension, "zhuque", "god", 4, false, true)
shenyi = sgs.CreateTriggerSkill{
	name = "shenyi",
	events = {sgs.TurnOver, sgs.StartJudge},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TurnOver and player:faceUp() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			return true
		elseif event == sgs.StartJudge then
			local judge = data:toJudge()
			if judge.reason == "indulgence" or judge.reason == "lightning" or judge.reason == "supply_shortage" then
				judge.good = not judge.good
			end
			room:sendCompulsoryTriggerLog(player, self:objectName())
		end
		return false
	end
}
ol_fentian = sgs.CreateTriggerSkill{
	name = "ol_fentian",
	events = {sgs.ConfirmDamage, sgs.TrickCardCanceling, sgs.SlashProceed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			damage.nature = sgs.DamageStruct_Fire
			data:setValue(damage)
			room:sendCompulsoryTriggerLog(poi, self:objectName())
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isRed() then
				return true
			end
		else
			local effect = data:toSlashEffect()
			if effect.from:objectName() == poi:objectName() and effect.slash:isRed() then
				room:sendCompulsoryTriggerLog(poi, self:objectName())
				room:slashResult(effect, nil)
				return true
			end
		end
	end
}
zhuque:addSkill(shenyi)
zhuque:addSkill(ol_fentian)

sgs.LoadTranslationTable{
["zhuque"] = "朱雀",
["shenyi"] = "神裔",
[":shenyi"] = "鎖定技，若你的武將牌正面朝上，你不能翻面；鎖定技，你的判定區裡的牌的結果反轉。",
["$shenyi1"] = "",
["$shenyi2"] = "",
["ol_fentian"] = "焚天",
--[":ol_fentian"] = "鎖定技，你造成的傷害視為火焰傷害；鎖定技，你使用紅色牌無距離和次數限制且不能被其他角色使用【閃】和【無懈可擊】響應。" ,
[":ol_fentian"] = "出牌階段限一次，你可以選擇一名其他角色，對其造成1點火焰傷害，然後若其以此法死亡，此技能發動次數上限+1。",
[":ol_fentian_sp"] = "出牌階段限一次，你可以選擇距離1以內的一名其他角色，對其造成1點火焰傷害，然後若其以此法死亡，此技能發動次數上限+1。 ",
["$ol_fentian1"] = "",
["$ol_fentian2"] = "",
["~zhuque"] = "",
}

huoshenzhurong = sgs.General(extension, "huoshenzhurong", "god", 5, true, true)
huoshenzhurong:addSkill("shenyi")
xingxiaCard = sgs.CreateSkillCard{
	name = "xingxia",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "xingxia_turn_count", 2)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == "yanling" or p:getGeneral2Name() == "yanling" then
				room:damage(sgs.DamageStruct(self:objectName(), source, p, 2, sgs.DamageStruct_Fire))
			end
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:isYourFriend(source) and not room:askForCard(p, ".|red", "@xingxia-discard:" .. p:objectName(), sgs.QVariant(), sgs.Card_MethodDiscard) then
				room:damage(sgs.DamageStruct(self:objectName(), source, p, 1, sgs.DamageStruct_Fire))
			end
		end
	end
}
xingxia = sgs.CreateZeroCardViewAsSkill{
	name = "xingxia",
	view_as = function()
		return xingxiaCard:clone()
	end,
	enabled_at_play = function(self, target)
		return target:getMark("xingxia_turn_count") == 0
	end
}
huoshenzhurong:addSkill(xingxia)

sgs.LoadTranslationTable{
["huoshenzhurong"] = "火神祝融",
["xingxia"] = "行夏",
--[":xingxia"] = "每兩輪的出牌階段限一次，你可以對焰靈造成2點火焰傷害，然後令所有對方角色選擇一項：1.棄置一張紅色手牌；2 .受到由你造成的1點火焰傷害。",
[":xingxia"] = "鎖定技，每兩輪限一次，出牌階段開始時，你選擇一名己方其他角色，對其造成2點火焰傷害，然後令所有對方角色各選擇一項：1 .棄置一張紅色手牌；2.受到由你造成的1點火焰傷害。",
[":xingxia_sp"] = "每兩輪限一次，出牌階段開始時，你可以選擇一名其他角色，對其造成2點火焰傷害，然後其以外的所有其他角色各選擇一項：1.棄置一張紅色手牌；2.受到由你造成的1點火焰傷害。",
["$xingxia1"] = "",
["$xingxia2"] = "",
["~huoshenzhurong"] = "",
}

yanling = sgs.General(extension, "yanling", "god", 4, true, true)
huihuo = sgs.CreateTriggerSkill{
	name = "huihuo",
	events = {sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isYourFriend(player) then
				room:damage(sgs.DamageStruct(self:objectName(), player, p, 3, sgs.DamageStruct_Fire))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
yanling:addSkill(huihuo)
furan = sgs.CreateTriggerSkill{
	name = "furan",
	frequency = sgs.Skill_NotCompulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:hasSkill("furan") then
				if not p:hasSkill("furan_use") then
					room:attachSkillToPlayer(p, "furan_use")
				end
			end
		end
		return false
	end
}
yanling:addSkill(furan)
furan_use = sgs.CreateOneCardViewAsSkill{
	name = "furan_use&",
	response_or_use = true,
	filter_pattern = ".|red",
	view_as = function(self, card)
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(self:objectName())
		peach:addSubcard(card:getId())
		return peach
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("furan") and p:getHp() < 0 then
				return string.find(pattern, "peach")
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("furan_use") then skills:append(furan_use) end

sgs.LoadTranslationTable{
["yanling"] = "焰靈",
["huihuo"] = "回火",
--[":huihuo"] = "鎖定技，當你死亡時，你對所有對方角色各造成3點火焰傷害；鎖定技，你使用【殺】的次數上限+1。",
[":huihuo"] = "當你死亡後，你對所有對方角色各造成3點火焰傷害；你使用【殺】的次數上限+1。",
[":huihuo_sp"] = "當你死亡後，你選擇一名角色，對其造成3點火焰傷害；你使用【殺】的次數上限+1。",
["$huihuo1"] = "",
["$huihuo2"] = "",
["furan"] = "復燃",
--[":furan"] = "對方角色於你處於瀕死狀態時可以將一張紅色牌當【桃】使用。",
[":furan"] = "鎖定技，對方角色於你處於瀕死狀態時選擇是否將一張紅色牌當【桃】使用。",
[":furan_sp"] = "其他角色於你處於瀕死狀態時可以將一張牌當【桃】使用",
["$furan1"] = "",
["$furan2"] = "",
["~yanling"] = "",
}

yandi = sgs.General(extension, "yandi", "god", 6, true, true)
yandi:addSkill("shenyi")
shenen = sgs.CreatePhaseChangeSkill{
	name = "shenen",
	frequency = sgs.Skill_Compulsory,
	on_phasechange = function()
	end
}
yandi:addSkill(shenen)
chiyi = sgs.CreateTriggerSkill{
	name = "chiyi",
	events = {sgs.DamageInflicted, sgs.RoundStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local count = room:getTag("TurnLengthCount"):toInt()
		player:speak(count)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not damage.to:isYourFriend(p) and count >= 3 then
				room:sendCompulsoryTriggerLog(p, self:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
				end
			end
		else
			if player:hasSkill(self:objectName()) then
				if count == 5 then
				for _, pe in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:sendCompulsoryTriggerLog(pe, self:objectName())
					for _,p in sgs.qlist(room:getAllPlayers()) do
						room:damage(sgs.DamageStruct(self:objectName(), pe, p, 1, sgs.DamageStruct_Fire))
					end
				end
				elseif count == 7 then
				for _, pe in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:sendCompulsoryTriggerLog(pe, self:objectName())
					for _, p in sgs.qlist(room:getOtherPlayers(pe)) do
						if p:getGeneralName() == "yanling" or p:getGeneral2Name() == "yanling" then
							room:damage(sgs.DamageStruct(self:objectName(), pe, p, 5, sgs.DamageStruct_Fire))
						end
					end
				end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}
yandi:addSkill(chiyi)

sgs.LoadTranslationTable{
["yandi"] = "炎帝",
["shenen"] = "神恩",
[":shenen"] = "鎖定技，己方角色使用牌無距離限制；鎖定技，對方角色的額定摸牌數和手牌上限+1。",
["$shenen1"] = "",
["$shenen2"] = "",
["chiyi"] = "赤儀",
--[":chiyi"] = "鎖定技，當對方角色受到傷害時，若輪數不小於3，傷害值+1；鎖定技，第五輪開始時，你對所有角色各造成1點火焰傷害；鎖定技，第七輪開始時，你對焰靈造成5點火焰傷害。",
[":chiyi"] = "鎖定技，當對方角色受到傷害時，若輪數不小於3，傷害值+1；鎖定技，第六輪開始時，你對所有其他角色各造成1點火焰傷害；鎖定技，第九輪開始時，焰靈死亡。",
[":chiyi_sp"] = "鎖定技，當你造成傷害時，若輪數不小於3，傷害值+1；鎖定技，第六輪開始時，你對所有其他角色各造成1點火焰傷害；鎖定技，第九輪開始時，你死亡。",
["$chiyi1"] = "",
["$chiyi2"] = "",
["~yandi"] = "",
}

qinglong = sgs.General(extension, "qinglong", "god", 4, true, true)
qinglong:addSkill("shenyi")
qinglong:addSkill("olleiji")

sgs.LoadTranslationTable{
["qinglong"] = "青龍",
["tengyun"] = "騰雲",
[":tengyun"] = "鎖定技，當你受到傷害後，其他角色於此回合內對你使用牌無效。",
["$tengyun1"] = "",
["$tengyun2"] = "",
["~qinglong"] = "",
}

mushengoumang = sgs.General(extension, "mushengoumang", "god", 5, true, true)
mushengoumang:addSkill("shenyi")
buchunCard = sgs.CreateSkillCard{
	name = "buchun",
	target_fixed = false,
	filter = function(self, targets, to_select)
		local need = sgs.Self:isWounded()
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			need = p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == "shujing"
			if need then break end
		end
		if need then
			return #targets == 0 and to_select:isWounded() and OursContains(to_select)
		end
		return false
	end,
	feasible = function(self, targets)
		local need = sgs.Self:isWounded()
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
			need = p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == "shujing"
			if need then break end
		end
		if need then
			return #targets == 0
		else
			return #targets == 1
		end
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "buchun_turn_count", 2)
		if #targets == 1 then
			room:recover(targets[1], sgs.RecoverStruct(source, nil, 2))
		elseif #targets == 0 then
			room:loseHp(source)
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == "shujing" then
				local hp = p:getHp()
				room:revivePlayer(p)
				room:setPlayerProperty(p, "hp", sgs.QVariant(hp))
				room:recover(p, sgs.RecoverStruct(source, nil, 1 - hp))
				p:drawCards(2 - p:getHandcardNum(), self:objectName())
				end
			end
		end
		return false
	end
}
buchun = sgs.CreateZeroCardViewAsSkill{
	name = "buchun",
	view_as = function()
		return buchun_card:clone()
	end,
	enabled_at_play = function(self, player)
		local need = player:isWounded()
		for _, p in sgs.qlist(player:getSiblings()) do
			if need then break end
			need = (p:isDead() and p:getMaxHp() > 0 and p:getGeneralName() == "shujing") or p:isWounded()
		end
		return player:getMark("buchun_turn_count") == 0 and need
	end
}
mushengoumang:addSkill(buchun)

sgs.LoadTranslationTable{
["mushengoumang"] = "木神勾芒",
["buchun"] = "布春",
--[":buchun"] = "每兩輪的出牌階段限一次，若：有已陣亡的樹精，你可以失去1點體力，令樹精復活，然後其將體力值回復至1點，將手牌補至兩張；沒有已陣亡的樹精，你可以選擇一名已受傷的己方角色，令其回復2點體力。",
[":buchun"] = "鎖定技，每兩輪限一次，準備階段開始時，若：有已陣亡的己方角色，你令這些角色復活，各將體力值回復至1點，將手牌補至體力上限；沒有已陣亡的己方角色，你選擇一名對方角色，其失去2點體力。",
[":buchun_sp"] = "每兩輪限一次，準備階段開始時，你可以失去1點體力並選擇一名角色，若其：存活，其失去2點體力；陣亡，其複活，將體力值回復至1點，將手牌補至兩張。",
["$buchun1"] = "",
["$buchun2"] = "",
["~mushengoumang"] = "",
}

shujing = sgs.General(extension, "shujing", "god", 2, false, true)
cuidu = sgs.CreateTriggerSkill{
	name = "cuidu",
	events = {sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to:isAlive() and not damage.to:hasSkill("zhongdu") then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:acquireSkill(damage.to, "zhongdu")
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if (p:getGeneralName() == "mushengoumang") then
				room:drawCards(p, 1, self:objectName())
				end
			end
		end
	end
}
shujing:addSkill(cuidu)
zhongdu = sgs.CreateTriggerSkill{
	name = "zhongdu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.who = player
			judge.reason = self:objectName()
			judge.good = false
			room:judge(judge)
			if judge:isGood() then
				room:damage(sgs.DamageStruct(self:objectName(), nil, player))
			end
			if judge.card:getSuit() ~= sgs.Card_Spade then
				room:detachSkillFromPlayer(player, self:objectName())
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("zhongdu") then skills:append(zhongdu) end

sgs.LoadTranslationTable{
["shujing"] = "樹精",
["cuidu"] = "淬毒",
[":cuidu"] = "鎖定技，當你對對方角色造成傷害後，其獲得“中毒”，然後木神勾芒摸一張牌。",
[":cuidu_sp"] = "鎖定技，當你對其他角色造成傷害後，你選擇一名角色，其摸一張牌，然後其獲得“中毒”。",
["$cuidu1"] = "",
["$cuidu2"] = "",
["zhongdu"] = "中毒",
--[":zhongdu"] = "鎖定技，回合開始時，你判定，若結果：不為紅桃，你受到1點傷害；不為黑桃，你失去此技能。",
[":zhongdu"] = "鎖定技，準備階段開始時，你判定，若結果：為方塊，你失去1點體力；不為方塊，你失去此技能。",
["$zhongdu1"] = "",
["$zhongdu2"] = "",
["~shujing"] = "",
}

taihao = sgs.General(extension, "taihao", "god", 6,true, true)
taihao:addSkill("shenyi")
taihao:addSkill("shenen")
god_qingyi = sgs.CreateTriggerSkill{
	name = "god_qingyi",
	events = {sgs.RoundStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		local count = room:getTag("TurnLengthCount"):toInt()
		if count == 3 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:isYourFriend(player) and p:isWounded() then
				room:recover(p, sgs.RecoverStruct(player))
				end
			end
		elseif count == 5 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:isYourFriend(player) then
				room:loseHp(p)
				end
			end
		elseif count == 7 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			for _,p in sgs.qlist(room:getPlayers()) do
				if (p:getGeneralName() == "shujing" or p:getGeneralName() == "mushengoumang") and p:isDead() and p:getMaxHp() > 0 then
					room:revivePlayer(p)
					room:drawCards(p, 3, self:objectName())
					room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp() + 1))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = p
					msg.arg = 1
					room:sendLog(msg)
					room:recover(p, sgs.RecoverStruct(player, nil, 3))
				end
			end
		end
		return false
	end
}
taihao:addSkill(god_qingyi)
sgs.LoadTranslationTable{
["taihao"] = "太昊",
["god_qingyi"] = "青儀",
--[":god_qingyi"] = "鎖定技，第三輪開始時，所有己方角色各回復1點體力；鎖定技，第五輪開始時，所有對方角色各失去1點體力；鎖定技，第七輪開始時，木神勾芒和樹精復活，然後各摸三張牌，加1點體力上限，回復3點體力。",
[":god_qingyi"] = "鎖定技，第三輪開始時，所有己方角色各加1點體力上限，回復1點體力；鎖定技，第六輪開始時，所有對方角色各失去1點體力；鎖定技，第九輪開始時，己方陣亡角色復活，然後各將體力值回復至上限，摸四張牌，然後所有己方角色獲得“青囊”。",
[":god_qingyi_sp"] = "鎖定技，第三輪開始時，你加1點體力上限，回復1點體力；鎖定技，第六輪開始時，所有其他角色各失去1點體力；鎖定技，第九輪開始時，若你已死亡，你復活，然後將體力值回復至上限，摸四張牌，獲得“青囊”。",
["$god_qingyi1"] = "",
["$god_qingyi2"] = "",
["~taihao"] = "",
}

baihu = sgs.General(extension, "baihu", "god", 4,true, true)
baihu:addSkill("shenyi")
kuangxiao = sgs.CreateTriggerSkill{
	name = "kuangxiao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isYourFriend(player) and not use.to:contains(p) then
					use.to:append(p)
				end
			end
			room:sortByActionOrder(use.to)
			data:setValue(use)
			room:sendCompulsoryTriggerLog(player, self:objectName())
		end
	end
}
baihu:addSkill(kuangxiao)
---------------------------------------------------------------------------------------------------


--[[
武聖、龍膽

烈弓、暗箭、破軍、鐵騎、鳳魄、無雙、鞬出、酒池、烈刃、往烈、趫猛

勤國、神速、奮鉞

決死、亂擊、火計、黷武、強襲、離間、散謠、狼襲、膽守、絕策、驅虎、盜書、戰絕

制衡、忘隙、激昂、奇制、蒺藜、潛襲、慎行、恃才、急攻、甚賢、罪論、從諫、過論、精策、行殤、英姿、閉月、涯角、利馭、清剿、縱適

良助、放權、獻圖、明鑑、密詔、謙雅、明策、圖南、眩惑、資援、問卦、品第、陳情、佐定、弘援、安卹​​、直諫、直言、秘計、好施、英魂

詐降、天妒、據守

慷愾、傾國、持節、明哲、享樂、天命、流離、啖酪、矢北

結姻、青囊、去疾、安國、急救

遺計、稱像、奸雄、剛烈、反饋、貞烈、智愚、節命

突襲、奇襲、巧變、觀星、挑釁、攻心、鎮骨、巧說、弓騎、旋風、連環、制蠻、滅計、反間、英魂

截刀、奔襲、凌人、默識、活墨、舍宴、奇策

"wusheng_po","longdan",
"ol_liegong","anjian","olpojun","tieji","ol_fengpo","wushuang","jianchu","jiuchi","lieren_po","wanglie","qiaomeng",
"qinguo","ol_shensu","ol_fenyue",
"juesi","luanji","huoji_po","duwu","kuangxi","lijian",","sanyao_po","langxi","danshou_po","juece",","quhu","daoshu","zhanjue",

"zhiheng_po","wangxi","jiang","qizhi","bf_jili","olqianxi","shenxing","ol_shicai","jigong","shenxian","zuilun","congjian","guolun","jingce_po","xingshang","yingzi","biyue_po","yajiao_po","liyu_po","qingjiao","zongshih",

"liangzhu","fangquan","xiantu","ol_mingjian","mizhao","qianya","mingce","tunan","xuanhuo","ziyuan",問卦,"pindi","lua_chenqing","zuoding","hongyuan","anxu","zhijian","zhiyan",olmiji","haoshi","yinghun",

"zhaxiang","tiandu","ol_jushou",

"kangkai","qingguo","chijie","mingzhe","xiangle","tianming","liuli","danlao","shibei",

"jieyin_po","qingnang","quji","ol_anguo","jijiu",

"yiji_po","chengxiang","jianxiong_po","ganglie","fankui",,"zhenlie","zhiyu","jieming",

"tuxi_po","qixi","qiaobian","guanxing_po","tiaoxin","gongxin","zhengu","qiaoshui_po","gongqi","xuanfeng","lianhuan_po","zhiman_po","mieji","fanjian","yinghun",

"jiedao","benxi_po","lingren","moshi","huomo","sheyan","qice"
--]]


--怒濤 濤神 曹娥 守江
--nutao taoshen caoe shoujiang


----------------------------------------------
--神呂布虎牢關
shenlvbu2_2017_new = sgs.General(extension, "shenlvbu2_2017_new", "god", 6, true, true)
shenlvbu2_2017_new:addSkill("mashu")
shenlvbu2_2017_new:addSkill("wushuang")
shenlvbu2_2017_new:addSkill("xiuluo")


shenji_2017_new = sgs.CreateTargetModSkill{
	name = "shenji_2017_new",
	frequency = sgs.Skill_Compulsory,
	extra_target_func = function(self, from)
		if from:hasSkill(self:objectName()) and not from:getWeapon() then
			return 2
		end
		return 0
	end
}
shenlvbu2_2017_new:addSkill(shenji_2017_new)

--神威手牌上線修改
shenwei_2017_new_maxcards = sgs.CreateMaxCardsSkill{
	name = "shenwei_2017_new_maxcards",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target, player)
		local n = 0
		if target:hasSkill("shenwei_2017_new") then
			n = n + 3
		end
		return n
	end
}

acquiring_audio = sgs.CreateTriggerSkill{
	name = "acquiring_audio",
	events = {sgs.PreCardUsed},
	global = true,
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:hasSkill("shenji_2017_new") and use.card:isKindOf("Slash") then
				room:broadcastSkillInvoke("shenji_2017_new", math.random(1,2))
			end
		end
	end
}

shenji_2017_new_slashmore = sgs.CreateTargetModSkill{
	name = "shenji_2017_new_slashmore",
	frequency = sgs.Skill_Compulsory,
	pattern = ".",
	residue_func = function(self, from, card)
		if card:isKindOf("Slash") then
			if from:hasSkill("shenji_2017_new") and not from:getWeapon() then
				return 1
			end
			return 0
		end
	end
}

--把神威手牌上線修改和神戟殺次數修改技能以隱藏方式加到所有武將, 加上配音修正技能
local shenlvbu2_skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("shenji_2017_new_slashmore") then shenlvbu2_skills:append(shenji_2017_new_slashmore) end
if not sgs.Sanguosha:getSkill("shenwei_2017_new_maxcards") then shenlvbu2_skills:append(shenwei_2017_new_maxcards) end
if not sgs.Sanguosha:getSkill("acquiring_audio") then shenlvbu2_skills:append(acquiring_audio) end
sgs.Sanguosha:addSkills(shenlvbu2_skills)

lua_tieji = sgs.CreateTriggerSkill {
	name = 'lua_tieji',
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified, sgs.FinishJudge,sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			if RIGHT(self, player) then
				local use = data:toCardUse()
				if not use.card:isKindOf('Slash') then
					return false
				end
				local jink_table = sgs.QList2Table(
									   player:getTag(
										   "Jink_" .. use.card:toString())
										   :toIntList())
				local index = 1
				local tos = sgs.SPlayerList()
				for _, p in sgs.qlist(use.to) do
					if not player:isAlive() then break end
					local data2 = sgs.QVariant()
					data2:setValue(p)
					if room:askForSkillInvoke(player, self:objectName(), data2) then
						room:broadcastSkillInvoke(self:objectName())
						if not tos:contains(p) then
							room:addPlayerMark(p, "@skill_invalidity")
							room:addPlayerMark(p, "skill_invalidity-Clear")
							room:doAnimate(1, player:objectName(),
										   p:objectName())
							tos:append(p)

							for _, pl in sgs.qlist(room:getAllPlayers()) do
								room:filterCards(pl, pl:getCards('he'), true)
							end

						end

						local judge = sgs.JudgeStruct()
						judge.pattern = "."
						judge.good = true
						judge.reason = self:objectName()
						judge.who = player
						judge.play_animation = false

						room:judge(judge)

						if p:isAlive() and not p:canDiscard(p, "he") or
							not room:askForCard(p, ".|" .. judge.pattern,
												"@tieji-discard:" ..
													judge.pattern, data,
												sgs.Card_MethodDiscard) then
							local msg = sgs.LogMessage()
							msg.type = '#NoJink'
							msg.from = p
							room:sendLog(msg)
							jink_table[index] = 0
						end
					end
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
				return false
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				judge.pattern = judge.card:getSuitString()
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() or player:objectName() ~= room:getCurrent():objectName() then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("skill_invalidity-Clear") > 0 then
						room:setPlayerMark(p, "@skill_invalidity", 0)
						for _, pl in sgs.qlist(room:getAllPlayers()) do
							room:filterCards(pl, pl:getCards('he'), false)
						end
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

lua_wansha = sgs.CreateTriggerSkill{
	name = "lua_wansha",
	events = {sgs.AskForPeaches, sgs.AskForPeachesDone},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local current = room:getCurrent()
			if current and current:isAlive() and current:hasSkill(self:objectName()) and current:getPhase() ~= sgs.Player_NotActive and current:getMark("lua_wansha_voice") == 0 then
				room:addPlayerMark(current, "lua_wansha_voice")
				room:broadcastSkillInvoke(self:objectName())
			end
			if current and current:isAlive() and current:hasSkill(self:objectName()) and current:getPhase() ~= sgs.Player_NotActive then
				if dying.who and dying.who:objectName() ~= player:objectName() and current:objectName() ~= player:objectName() then
					return true
				end
				--return not (player:getSeat() == current:getSeat() or player:getSeat() == dying.who:getSeat())
			end
		elseif event == sgs.AskForPeachesDone then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("lua_wansha_voice") > 0 then
					room:setPlayerMark(p, "lua_wansha_voice", 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return true
	end
}
if not sgs.Sanguosha:getSkill("lua_tieji") then skills:append(lua_tieji) end
if not sgs.Sanguosha:getSkill("lua_wansha") then skills:append(lua_wansha) end

shenlvbuguitwentyeighteen = sgs.General(extension, "shenlvbuguitwentyeighteen", "god", 6, true, true)

shenqu = sgs.CreateTriggerSkill{
	name = "shenqu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if RIGHT(self, p) then
				if event == sgs.EventPhaseStart then
					if player:getPhase() == sgs.Player_RoundStart and p:getHandcardNum() <= p:getMaxHp() and room:askForSkillInvoke(p, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName(), 1)
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							p:drawCards(2, self:objectName())
							room:removePlayerMark(p, self:objectName().."engine")
						end
					end
				else
					if p:objectName() == data:toDamage().to:objectName() and room:askForUseCard(p, "peach", "@shenqu") then
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							room:removePlayerMark(p, self:objectName().."engine")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

shenlvbuguitwentyeighteen:addSkill("wushuang")
shenlvbuguitwentyeighteen:addSkill(shenqu)
jiwuCard_2018_new = sgs.CreateSkillCard{
	name = "jiwu_2018_new",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {"kuangxi", "tieji", "xuanfeng", "wansha"}
		local copy = {"kuangxi", "lua_tieji", "xuanfeng", "lua_wansha"}
		for i = 1, 4 do
			if source:hasSkill(choices[i]) then
				table.removeOne(copy, choices[i])
			end
		end
		if #copy > 0 then
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				local choice = room:askForChoice(source, self:objectName(), table.concat(copy, "+"))
				room:acquireSkill(source, choice)
				room:addPlayerMark(source, choice.."_skillClear")
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
jiwu_2018_new = sgs.CreateOneCardViewAsSkill{
	name = "jiwu_2018_new",
	filter_pattern = ".",
	view_as = function(self, card)
		local skill_card = jiwuCard_2018_new:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasSkill("qiangxi") or not player:hasSkill("tieji") or not player:hasSkill("xuanfeng") or not player:hasSkill("lua_wansha")
	end
}
shenlvbuguitwentyeighteen:addSkill(jiwu_2018_new)
shenlvbuguitwentyeighteen:addRelateSkill("qiangxi")
shenlvbuguitwentyeighteen:addRelateSkill("tieji")
shenlvbuguitwentyeighteen:addRelateSkill("lua_wansha")
shenlvbuguitwentyeighteen:addRelateSkill("xuanfeng")

sgs.LoadTranslationTable{
["shenlvbu2_2017_new"] = "神呂布",
["#shenlvbu2_2017_new"] = "暴怒戰神",
["illustrator:shenlvbu2_2017_new"] = "LiuHeng",
["shenwei_2017_new"] = "神威",
[":shenwei_2017_new"] = "鎖定技，摸牌階段，你多摸三張牌；鎖定技，你的手牌上限+3。",
["$shenwei_2017_new1"] = "我不會輸給任何人~",
["$shenwei_2017_new2"] = "螢燭之火也敢與日月爭輝？",
["shenji_2017_new"] = "神戟",
[":shenji_2017_new"] = "鎖定技，若你的裝備區裡沒有武器牌，你使用【殺】的額外目標數上限+2，次數上限+1。",
["$shenji_2017_new1"] = "盡想贏我？癡人說夢！",
["$shenji_2017_new2"] = "雜魚們都去死吧！",
["shenlvbuguitwentyeighteen"] = "神呂布",
["#shenlvbuguitwentyeighteen"] = "神鬼無前",
["illustrator:shenlvbuguitwentyeighteen"] = "LiuHeng",
["jiwu_2018_new"] = "極武",
[":jiwu_2018_new"] = "出牌階段，你可以棄置一張牌，令你於此回合內擁有一項：“強襲”、“鐵騎”、“旋風”、“完殺”。",
["$jiwu_2018_new1"] = "我。是不可戰勝的！",
["$jiwu_2018_new2"] = "今天，就讓你們感受一下真正的絕望~",
["$lua_wansha1"] = "螻蟻，怎容偷生！",
["$lua_wansha2"] = "沉淪吧，在這無邊的恐懼！",

["lua_tieji"] = "鐵騎",
[":lua_tieji"] = "每當你指定【殺】的目標後，你可以令該角色的非鎖定技無效直到回合結束並進行判定：若如此做，該角色須棄置一張與判定牌花色相同的牌，否則其不能使用【閃】響應此【殺】。",
["$tieji3"] = "哈哈哈，破綻百出！",
["$tieji4"] = "我要讓這虎牢關下，血流成河！",
["~shenlvbuguitwentyeighteen"] = "你們的項上人頭，我改日再取~",
["shenqu"] = "神軀",
[":shenqu"] = "一名角色的回合開始時，若你的手牌數不大於體力上限，你可以摸兩張牌；當你受到傷害後，你可以使用【桃】。",
["$shenqu1"] = "別心懷僥倖了，你們不可能贏~",
["$shenqu2"] = "虎牢關，我一人鎮守足矣~",
}

--------------------------------------------------------------------------------------------
----------------------------------------征戰虎牢關-------------------------------------------
---------------------------------------------------------------------------------------------

--龍驤軍
longxiang = sgs.General(extension, "longxiang", "qun", "4", true, true, true)

longying = sgs.CreateTriggerSkill{
	name = "longying" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSameTeam(p,player) and p:isWounded() then
					_targets:append(p)
				end
			end
			if not _targets:isEmpty() then
				local s = _targets[math.random(1,#_targets)]
					room:loseHp(player,1)
					local theRecover = sgs.RecoverStruct()
					theRecover.recover = 1
					theRecover.who = s
					room:recover(s, theRecover)
					s:drawCards(2)
			end
		end
		return false
	end
}

longxiang:addSkill(longying)

sgs.LoadTranslationTable{
["longxiang"] = "龍驤軍",
["longying"] = "龍營",
[":longying"] = "鎖定技，出牌階段開始時，若己方有其他角色已受傷，你失去1點體力，然後隨機一名己方受傷角色回復1點體力並摸兩張牌。",
}

--虎賁軍
huben = sgs.General(extension, "huben", "qun", "3", true, true, true)


--[[
huying = sgs.CreateTriggerSkill{
	name = "huying" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isLord() then
					local hand_slash_card = sgs.IntList()
					for _,id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
							hand_slash_card:append(id)
						end
					end
					if not hand_slash_card:isEmpty() then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), "ziyuan","")
						room:moveCardTo(hand_slash_card:at(math.random(0,hand_slash_card:length()-1)) ,p,sgs.Player_PlaceHand,reason)
						room:broadcastSkillInvoke(self:objectName())
					else
						room:loseHp(player,1)
						getpatterncard(p, {"Slash"} )
					end
				end
			end
		end
		return false
	end
}
]]--
huying = sgs.CreateTriggerSkill{
	name = "huying" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSameTeam(p,player) then
					_targets:append(p)
				end
			end
			if not _targets:isEmpty() then
				local s = _targets[math.random(1,#_targets)]
				if s then
					getpatterncard(s, {"Slash"} ,true,false)
					getpatterncard(s, {"Slash"} ,true,false)
				end
			end
		end

		return false
	end
}

huben:addSkill(huying)

sgs.LoadTranslationTable{
["huben"] = "虎賁軍",
["huying"] = "虎營",
[":huying"] = "鎖定技，出牌階段開始時，隨機一名己方角色獲得牌堆中的兩張【殺】。",
}

--鳳瑤軍
fengyao = sgs.General(extension, "fengyao", "qun", "3", false, true, true)

--[[
fengying = sgs.CreateProhibitSkill{
	name = "fengying",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:getMark("fengying_target") > 0 and not card:isKindOf("SkillCard")
	end
}
]]--
fengying = sgs.CreateProhibitSkill{
	name = "fengying",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:getMark("fengying_target") > 0 and not card:isKindOf("SkillCard") and card:isBlack()
	end
}

fengyao:addSkill(fengying)

sgs.LoadTranslationTable{
["fengyao"] = "鳳瑤軍",
["fengying"] = "鳳營",
[":fengying"] = "鎖定技，敵方角色使用黑色牌指定己方角色為唯一目標後，若目標角色體力值是全場最少的，則此牌對其無效。",
}

--豹掠軍
baolve = sgs.General(extension, "baolve", "qun", "3", true, true, true)

--[[
baoying = sgs.CreateTriggerSkill{
	name = "baoying",
	frequency = sgs.Skill_Limited,
	limit_mark = "@baoying",
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:getMark("@baoying") == 0 and isSameTeam(p,dying.who) then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:removePlayerMark(p, "@baoying")
					local recover = sgs.RecoverStruct()
					recover.who = dying.who
					recover.recover = 1 - dying.who:getHp()
					room:recover(p, recover)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
]]--

baoying = sgs.CreateTriggerSkill{
	name = "baoying",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if (not p:isNude()) and isSameTeam(p,dying.who) then
				local loot_cards = sgs.QList2Table(p:getCards("he"))
				if #loot_cards > 0 then
					room:throwCard(loot_cards[math.random(1, #loot_cards)], p,p)
				end
				local recover = sgs.RecoverStruct()
				recover.who = dying.who
				recover.recover = 1
				room:recover(p, recover)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

baolve:addSkill(baoying)

sgs.LoadTranslationTable{
["baolve"] = "豹掠軍",
["baoying"] = "豹營",
[":baoying"] = "鎖定技，己方有其他角色進入瀕死狀態時，你隨機棄置一張牌，然後該角色回復1點體力。",
}

--飛熊軍
feixiong_left = sgs.General(extension, "feixiong_left", "qun", "3", true, true, true)

jingqi = sgs.CreateDistanceSkill{
	name = "jingqi",
	frequency = sgs.Skill_Compulsory,
	correct_func = function(self, from, to)
		local extra = 0
		for _, p in sgs.qlist(from:getAliveSiblings()) do
			if p:hasSkill("jingqi") and isSameTeam(p,from) then
				extra = extra + 1
			end
		end
		if extra > 0 then
			return -extra
		else
			return 0
		end
	end
}

feixiong_left:addSkill(jingqi)

sgs.LoadTranslationTable{
["feixiong_left"] = "飛熊左軍",
["jingqi"] = "精騎",
[":jingqi"] = "鎖定技，己方角色與對方角色的距離-1。",
}

--貪狼軍
feixiong_right = sgs.General(extension, "feixiong_right", "qun", "2", true, true, true)

ruiqi = sgs.CreateTriggerSkill{
	name = "ruiqi",
	events = {sgs.DrawNCards},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()		
		if event == sgs.DrawNCards then
			local extra = 0
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if isSameTeam(p,player) then
					extra = extra + 1
				end
			end

			if extra > 0 then
				local n = data:toInt()
				n = n + extra
				data:setValue(n)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end				
}

feixiong_right:addSkill(ruiqi)

sgs.LoadTranslationTable{
["feixiong_right"] = "飛熊右軍",
["ruiqi"] = "銳騎",
[":ruiqi"] = "鎖定技，己方角色的額定摸牌數+1。",
}
--張濟
zhangji = sgs.General(extension, "zhangji", "qun", "4", true, true, true)

jielve = sgs.CreateTriggerSkill{
	name = "jielve" ,
	events = {sgs.Damage} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() then
				room:setPlayerFlag(player, "jidao")
				room:setPlayerFlag(player, "jidaotarget")
				
				room:sendCompulsoryTriggerLog(player, "jielve") 			

				room:doAnimate(1, player:objectName(), damage.to:objectName())
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				if player:canDiscard(damage.to, "h") then
					local id = room:askForCardChosen(player, damage.to, "h", "jielve")
					room:obtainCard(player, id, true)
				end
				if player:canDiscard(damage.to, "e") then
					local id = room:askForCardChosen(player, damage.to, "e", "jielve")
					room:obtainCard(player, id, true)
				end
				if player:canDiscard(damage.to, "j") then
					local id = room:askForCardChosen(player, damage.to, "j", "jielve")
					room:obtainCard(player, id, true)
				end
				room:loseHp(player,1)
			end
	end
}
zhangji:addSkill(jielve)

sgs.LoadTranslationTable{
["zhangji"] = "張濟",
["jielve"] = "劫掠",
[":jielve"] = "鎖定技，當你對其他角色造成傷害後，你獲得其各區域裡的一張牌，然後你失去1點體力。",
}
--樊稠
fanchou = sgs.General(extension, "fanchou", "qun", "4", true, true, true)

fangong = sgs.CreateTriggerSkill{
	name = "fangong", 
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local from = use.from
			if use.card and not use.card:isKindOf("SkillCard") then
				for _, p in sgs.qlist(use.to) do
					if p:hasSkill("fangong") and use.from:objectName() ~= p:objectName() and p:canSlash(use.from, nil, false) then
						local card = room:askForUseSlashTo(p, use.from, "#fangong:"..use.from:objectName(),false)
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, player)
		return player and player:isAlive()
	end
}
fanchou:addSkill(fangong)
sgs.LoadTranslationTable{
["fanchou"] = "樊稠",
["fangong"] = "反攻",
[":fangong"] = "當其他角色對你使用的牌結算完畢後，你可以對其使用【殺】（無距離限制）。",
["#fangong"] = "你可以對 %src 使用一張【殺】",
}
--[[
mojun = sgs.CreateTriggerSkill{
	name = "mojun", 
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card and card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("mojun") and isSameTeam(player,p) then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						for _, q in sgs.qlist(room:getAlivePlayers()) do
							if isSameTeam(player,q) then
								q:drawCards(1)
							end
						end
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
]]--
mojun = sgs.CreateTriggerSkill{
	name = "mojun", 
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card and card:isKindOf("Slash") then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("mojun") and isSameTeam(player,p) then
					if player:getHandcardNum() < damage.to:getHandcardNum() then
						p:drawCards(1)
						player:drawCards(1)
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

moqu = sgs.CreateTriggerSkill{
	name = "moqu", 
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseChanging},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("moqu") and isSameTeam(player,p) then
					if player:getHandcardNum() < 6 then
						player:drawCards((6-player:getHandcardNum()))
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

if not sgs.Sanguosha:getSkill("mojun") then skills:append(mojun) end
if not sgs.Sanguosha:getSkill("moqu") then skills:append(moqu) end

sgs.LoadTranslationTable{
["mojun"] = "魔軍",
--[":mojun"] = "鎖定技，當己方角色使用【殺】對目標角色造成傷害後，其判定，若結果為黑色，己方角色各摸一張牌。",
[":mojun"] = "鎖定技，當己方角色使用【殺】對目標角色造成傷害後，其判定，若結果為黑色，己方角色各摸一張牌。",

["moqu"] = "魔軀",
[":moqu"] = "鎖定技，一名角色的回合結束時，若你的手牌數小於體力值，你摸兩張牌；鎖定技，當己方其他角色受到傷害後，你棄置一張手牌。",
}

-------------------------------第二關-------------------------

--[[
tunjun = sgs.CreateTriggerSkill{
	name = "tunjun",
	events = {sgs.EventPhaseChanging},
	priority = -99,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("tunjun") then
						local lord_player
						for _, q in sgs.qlist(room:getAlivePlayers()) do
							if q:isLord() or (q:getMark("AG_firstplayer") > 0) then
								lord_player = q
								break
							end
						end

						if p:getMark("origin_turn") < lord_player:getMark("@clock_time") then
							room:setPlayerMark(p,"origin_tunjun", lord_player:getMark("@clock_time"))
							if p:getMaxHp() > 1 then
								room:loseMaxHp(p)
								p:drawCards(p:getMaxHp())
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}

jiaoxia = sgs.CreateTriggerSkill{
	name = "jiaoxia",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
				local invoke = false
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if isSameTeam(p,player) then
						invoke = true
					end
				end
				if invoke then
					room:setPlayerFlag(player,"jiaoxia_invoke")
					room:setPlayerCardLimitation(player, "discard", ".|black|.|hand", true)
				end
			end
		elseif event == sgs.EventPhaseEnd and player:hasFlag("jiaoxia_invoke") then
			if player:getPhase() == sgs.Player_Discard then
				room:removePlayerCardLimitation(player, "discard", ".|black|.|hand$1")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end
}

jiaoxiamc = sgs.CreateMaxCardsSkill{
	name = "#jiaoxiamc",
	extra_func = function(self, target)
		if target:hasFlag("jiaoxia_invoke") then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:isBlack() then
					x = x + 1
				end
			end
			return x
		end
	end
}

sgs.LoadTranslationTable{
["niufudongxie"] = "牛輔&董翓",
["tunjun"] = "屯軍",
[":tunjun"] = "鎖定技，新一輪開始時，若你的體力上限不為1，你減1點體力上限，然後摸X張牌。（X為你的體力上限）",
["jiaoxia"] = "狡黠",
[":jiaoxia"] = "鎖定技，己方角色的黑色手牌不計入手牌數。",
}

kuangxiCard = sgs.CreateSkillCard{
	name = "kuangxiCard", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() or to_select:getMark("kuangxi-Clear") > 0 then return false end--根据描述应该可以选择自己才对
		return true
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom() 
		room:loseHp(effect.from)
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
		if effect.to:getHp() < 0 then
			room:setPlayerMark(effect.from,"lose_kuangxi-Clear",1)
		end
	end
}
kuangxi = sgs.CreateViewAsSkill{
	name = "kuangxi", 
	n = 0, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return kuangxiCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("lose_kuangxi-Clear") > 0
	end,
}

sgs.LoadTranslationTable{
["dongyue"] = "董越",
["kuangxi"] = "狂襲",
[":kuangxi"] = "出牌階段，你可以失去1點體力並選擇一名其他角色，對其造成1點傷害，然後若其以此法進入瀕死狀態，此瀕死結算完畢後，此技能於此回合內無效。",
}

yangwu = sgs.CreateTriggerSkill{
	name = "yangwu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:broadcastSkillInvoke("yangwu")
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:damage(sgs.DamageStruct(self:objectName(), player,p))
				end
				room:loseHp(player,1)
			end
		end
	end
}

sgs.LoadTranslationTable{
["lijue"] = "李傕",
["yangwu"] = "揚武",
[":yangwu"] = "鎖定技，準備階段開始時，你對所有其他角色各造成1點傷害，然後你失去1點體力。",
}

yanglie = sgs.CreateTriggerSkill{
	name = "yanglie",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:broadcastSkillInvoke("yanglie")
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:doAnimate(1, player:objectName(), p:objectName())
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isAlive() and player:canDiscard(p, "hej") then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						local card_id = room:askForCardChosen(player, p, "hej", self:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
						room:getThread():delay(100)
					end
				end
				room:loseHp(player,1)
			end
		end
	end
}

sgs.LoadTranslationTable{
["guosi"] = "郭汜",
["yanglie"] = "揚烈",
[":yanglie"] = "鎖定技，準備階段開始時，你可以獲得所有其他角色區域裡的一張牌，然後你失去1點體力。",
}
]]--



--神策	鎖定技，己方角色的出牌階段開始時，該角色從棄牌堆獲得一張【殺】且本回合使用【殺】次數+1，出牌階段使用的第一張【殺】無視距離。
shence = sgs.CreateTriggerSkill{
	name = "shence" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local _targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSameTeam(p,player) then
					_targets:append(p)
				end
			end
			if not _targets:isEmpty() then
				local s = _targets[math.random(1,#_targets)]
				getpatterncard(s, {"Slash"} ,false,true)
				room:setPlayerMark(s,"shence-Clear",1)
			end
		end

		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

shencetm = sgs.CreateTargetModSkill{
	name = "#shencetm",
	frequency = sgs.Skill_Compulsory ,
	pattern = "Slash",
	residue_func = function(self, player, card)
		return player:getMark("shence-Clear")
	end,
	distance_limit_func = function(self, player, card)
		if player:getMark("shence-Clear") > 0 and player:getMark("used_slash-Clear") < 2 then
			return 1000
		end
		return 0
	end
}

if not sgs.Sanguosha:getSkill("shence") then skills:append(shence) end
if not sgs.Sanguosha:getSkill("#shencetm") then skills:append(shencetm) end

sgs.LoadTranslationTable{
["shence"] = "神策",
["#shencetm"] = "神策",
[":shence"] = "鎖定技，己方角色的出牌階段開始時，該角色從棄牌堆獲得一張【殺】且本回合使用【殺】次數+1，出牌階段使用的第一張【殺】無視距離。",
}

--死陣	鎖定技，你的【殺】無視目標角色防具且傷害+1。
sizhen = sgs.CreateTriggerSkill{
	name = "sizhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
			  	player:addQinggangTag(use.card)
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:isKindOf("Slash") then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#Sizhen"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
				end
			end
		end
		return false
	end,
}

if not sgs.Sanguosha:getSkill("sizhen") then skills:append(sizhen) end

sgs.LoadTranslationTable{
["sizhen"] = "死陣",
[":sizhen"] = "鎖定技，你的【殺】無視目標角色防具且傷害+1。",
["#Sizhen"] = "%from 的技能 “<font color=\"yellow\"><b>死陣</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}
--絕酒	鎖定技，你的回合內，所有角色均不能使用【酒】。
juejiu = sgs.CreateTriggerSkill{
	name = "juejiu",
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:addPlayerMark(p, "juejiu-Clear")
			end
		end
	end
}

juejiuPS = sgs.CreateProhibitSkill{
	name = "#juejiuPS" ,
	frequency = sgs.Skill_Compulsory ,
	is_prohibited = function(self, from, to, card)
		return from:getMark("juejiu-Clear") > 0 and card:isKindOf("Analeptic")
	end
}
if not sgs.Sanguosha:getSkill("juejiu") then skills:append(juejiu) end
if not sgs.Sanguosha:getSkill("#juejiuPS") then skills:append(juejiuPS) end

sgs.LoadTranslationTable{
["juejiu"] = "絕酒",
["#juejiuPS"] = "絕酒",
[":juejiu"] = "鎖定技，你的回合內，所有角色均不能使用【酒】。",
}

--軍屯	鎖定技，準備階段，若你的體力上限大於等於2，則你扣減1點體力上限，然後摸X張牌（X為你的體力上限）。
--狡黠	鎖定技，你的紅色手牌不計入手牌上限，且使用黑色牌無距離和次數限制。
dongxie = sgs.General(extension, "dongxie", "qun", "3", false, true, true)

juntun = sgs.CreateTriggerSkill{
	name = "juntun",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player:getPhase() == sgs.Player_RoundStart and player:getMaxHp() >= 2 then
				room:loseMaxHp(player)
				player:drawCards(player:getMaxHp())
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}

jiaoxia = sgs.CreateTriggerSkill{
	name = "jiaoxia",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard then
					room:setPlayerFlag(player,"jiaoxia_invoke")
					room:setPlayerCardLimitation(player, "discard", ".|red|.|hand", true)
				end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard then
				room:removePlayerCardLimitation(player, "discard", ".|red|.|hand$1")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end
}

jiaoxiamc = sgs.CreateMaxCardsSkill{
	name = "#jiaoxiamc",
	extra_func = function(self, target)
		if target:hasFlag("jiaoxia_invoke") then
			local x = 0
			for _, card in sgs.list(target:getHandcards()) do
				if card:isRed() then
					x = x + 1
				end
			end
			return x
		end
	end
}

jiaoxiatm = sgs.CreateTargetModSkill{
	name = "#jiaoxiatm",
	frequency = sgs.Skill_Compulsory ,
	residue_func = function(self, player, card)
		if player:hasSkill("jiaoxia") and card:isBlack() then
			return 1000
		end
		return 0
	end,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("jiaoxia") and card:isBlack() then
			return 1000
		end
		return 0
	end
}
dongxie:addSkill(juntun)
dongxie:addSkill(jiaoxia)
sgs.LoadTranslationTable{
["dongxie"] = "董翓",
["juntun"] = "軍屯",
[":juntun"] = "鎖定技，準備階段，若你的體力上限大於等於2，則你扣減1點體力上限，然後摸X張牌（X為你的體力上限）。",
["jiaoxia"] = "狡黠",
[":jiaoxia"] = "鎖定技，你的紅色手牌不計入手牌上限，且使用黑色牌無距離和次數限制。",
}

---------------------------------------------第三關------------------
shenlvbu1_2020 = sgs.General(extension, "shenlvbu1_2020", "qun", "16", false, true, true)
shenlvbu2_2020 = sgs.General(extension, "shenlvbu2_2020", "qun", "16", false, true, true)
--霸關	其他角色的回合結束後，你進行一個額外的回合。此額外回合的摸牌階段，你視為擁有技能「英姿」。
baguan = sgs.CreateTriggerSkill{
	name = "baguan" ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isAlive() and p:hasSkill(self:objectName()) then
						room:setTag("ExtraTurn" , sgs.QVariant(true))
						room:setPlayerMark(p,"baguan-Clear",1)
						p:gainAnExtraTurn()
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						room:setTag("ExtraTurn" , sgs.QVariant(false))
					end
				end
			elseif player:getPhase() == sgs.Player_Draw then
				if player:getMark("baguan-Clear") > 0 then
					room:handleAcquireDetachSkills(player, "yingzi", true)
				end
			end
			return false
		elseif event == EventPhaseEnd then
			if player:getPhase() == sgs.Player_Draw then
				if player:getMark("baguan-Clear") > 0 then
					room:handleAcquireDetachSkills(player, "-yingzi", true)
				end
			end
		end
	end ,
	can_trigger = function(self, target)
		return target
	end ,
	priority = 1
}

--戰甲	鎖定技，每回合限一次，當你受到大於2點的傷害時，將此傷害減至2點，然後摸兩張牌。
zhanjia = sgs.CreateTriggerSkill{
	name = "zhanjia",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.damage > 2 then
			SendComLog(self, player, 1)
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 and player:getMark(self:objectName().."-Clear") == 0 then
				room:addPlayerMark(player, self:objectName().."-Clear")
				damage.damage = 2
				player:drawCards(2)
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		data:setValue(damage)
		return false
	end
}

--蓄力	當你受到傷害後，若你的損失體力值大於當前體力值，當前事件結算完畢後，你將體力上限減至當前體力值，將手牌摸至當前體力值，然後結束當前回合，開始你的回合（進入下一階段）。
xuli = sgs.CreateTriggerSkill{
	name = "xuli",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()

			if player:isAlive() and player:hasSkill(self:objectName()) then
				if player:getLostHp() > player:getHp() then
					room:setPlayerMark(player,"xuli_invoke",1)
				end
			end
		elseif event == sgs.CardFinished then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				local n = p:getMaxHp() - p:getHp()
				if n > 0 then
					room:loseMaxHp(p,n)
				end	

				local n = p:getHp() - p:getHandcardNum()
				if n > 0 then
					p:drawCards(n)
				end
				room:throwEvent(sgs.TurnBroken)	
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--戰鎧	鎖定技，你的手牌上限為8。當你受到1點傷害後，傷害來源隨機棄置一張牌（優先裝備區），然後你摸兩張牌。
zhankai = sgs.CreateTriggerSkill{
	name = "zhankai" ,
	events = {sgs.Damagd} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.from then
				local loot_cards = sgs.QList2Table(damage.from:getCards("e"))
				if #loot_cards > 0 then
					room:throwCard(loot_cards[math.random(1, #loot_cards)], damage.from ,player)
				else
					local loot_cards = sgs.QList2Table(damage.from:getCards("h"))
					if #loot_cards > 0 then
						room:throwCard(loot_cards[math.random(1, #loot_cards)], damage.from ,player)
					end
				end				
			end
		end
	end
}
--神戟	判定階段，你可以棄置兩張手牌，然後棄置你判定區里的牌。摸牌階段，你多摸兩張牌；出牌階段，你可以多使用兩張【殺】，你的【殺】可以多指定兩名角色為目標。
ty_shenji = sgs.CreateTriggerSkill{
	name = "ty_shenji" ,
	events = {sgs.EventPhaseStart,sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Judge and player:getHandcardNum() >= 2 and hasDelayedTrickXiuluo(player) then
				while hasDelayedTrickXiuluo(player) and player:canDiscard(player, "h") do
					if room:askForSkillInvoke(player, "ty_shenji", data) then
						room:askForDiscard(player, "ty_shenji", 2, 2, false, false)
						local avail_list = sgs.IntList()
						local other_list = sgs.IntList()
						for _, jcard in sgs.qlist(player:getJudgingArea()) do
							if jcard:isKindOf("SkillCard") then
							else
								avail_list:append(jcard:getEffectiveId())
							end
						end
						local all_list = sgs.IntList()
						for _, l in sgs.qlist(avail_list) do
							all_list:append(l)
						end
						room:fillAG(all_list, nil, other_list)
						local id = room:askForAG(player, avail_list, false, self:objectName())
						room:clearAG()
						room:throwCard(id, nil)
						room:broadcastSkillInvoke(self:objectName())
					else
						return false
					end
				end
			end
			return false
		elseif event == sgs.DrawNCards then
			local count = data:toInt() + 2
			data:setValue(count)
		end
	end ,
}

ty_shenjiTargetMod = sgs.CreateTargetModSkill{
	name = "#ty_shenjiTargetMod",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill("ty_shenji") then
			return 2
		end
	end,
	extra_target_func = function(self, player)
		if player:hasSkill("ty_shenji") then
			return 2
		end
	end,
}

shenlvbu1_2020:addSkill("mashu")
shenlvbu1_2020:addSkill("wushuang")
shenlvbu1_2020:addSkill(baguan)
shenlvbu1_2020:addSkill(zhanjia)
shenlvbu1_2020:addSkill(xuli)

sgs.LoadTranslationTable{
["shenlvbu1_2020"] = "神呂布",
["shenlvbu2_2020"] = "神呂布",
["baguan"] = "霸關",
[":baguan"] = "其他角色的回合結束後，你進行一個額外的回合。此額外回合的摸牌階段，你視為擁有技能「英姿」。",
["zhanjia"] = "戰甲",
[":zhanjia"] = "鎖定技，每回合限一次，當你受到大於2點的傷害時，將此傷害減至2點，然後摸兩張牌。",
["xuli"] = "蓄力",
[":xuli"] = "當你受到傷害後，若你的損失體力值大於當前體力值，當前事件結算完畢後，你將體力上限減至當前體力值，將手牌摸至當前體力值，然後結束當前回合，開始你的回合（進入下一階段）。",
}

--主技能

nl_HulaoMode = sgs.CreateTriggerSkill{
	name = "#nl_HulaoMode",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BeforeGameOverJudge,sgs.BuryVictim,sgs.EventPhaseChanging,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeGameOverJudge then
			--local death = data:toDeath()
			--[[
			if player:getMark("AG_firstplayer") > 0 then
				local now = player:getNextAlive()
				room:setPlayerMark(now, "@clock_time", player:getMark("@clock_time"))
				room:setPlayerMark(now, "AG_firstplayer", 1)
				if room:getCurrent():objectName() == player:objectName() then
					room:setPlayerMark(now, "@stop_invoke", 1)
				end
			end
			]]--
			--if player:getHp() <= 0 and player:isLord() then
				
				local realplayer
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("RealPlayer") == 1 then
						realplayer = p
					end
				end
				if realplayer:getMark("@game") < 3 then	
					room:setTag("SkipGameRule",sgs.QVariant(true))
					local no_rebel =true
					for _,p2 in sgs.qlist(room:getAlivePlayers()) do
						if p2:getRole() == "rebel" then
							no_rebel = false
						end
					end
					if no_rebel then
						room:setPlayerMark(realplayer, "@game", realplayer:getMark("@game")+1)
						for _,p2 in sgs.qlist(room:getPlayers()) do
							room:setPlayerMark(p2,"@AG_enternextstage",1)
						end
					end
				end
			--end 


		elseif event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then
						killer:drawCards(2)

						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end	
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for i = 1, 8, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				local i = 0
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					room:setPlayerMark(p, "gameMode_HulaoMode", 1)
					if i == 1 or i == 3 or i == 5 then
						choosenewgeneral(p,9,false,{})
						choosejiangling(p,5,false,{})
					elseif i == 2 or i == 4 or i == 6 or i == 8 then
						local sks_all = {"longxiang","huben","fengyao","feixiong_left","feixiong_right"}
						for ii=1, #sks_all, 1 do
							for _,pp in sgs.qlist(room:getAlivePlayers()) do
								if pp:getGeneralName() == sks_all[ii] then
									--table.remove(generals, i)
									table.removeOne(sks_all, sks_all[ii])
								end
							end
						end
						local sks = {}
						local random1 = math.random(1, #sks_all)
						table.insert(sks, sks_all[random1])
						local general = room:askForGeneral(p, table.concat(sks, "+"))
						room:changeHero(p, general, false,true, false,false)
					elseif i == 7 then
						local sks_all = {"zhangji","fanchou","whlw_guosi","whlw_lijue"}
						local sks = {}
						local random1 = math.random(1, #sks_all)
						table.insert(sks, sks_all[random1])
						local general = room:askForGeneral(p, table.concat(sks, "+"))
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()+1))
						room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
						room:changeHero(p, general, false,true, false,false)
						room:acquireSkill(p,"mojun")
					end
				end
				for _, p in sgs.qlist(_targets) do
					room:getThread():trigger(sgs.GameStart, room, p, data)
					getqixing(p)
					room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
				end
				room:setPlayerMark(player, "AG_firstplayer", 1)
				--room:setPlayerMark(player, "@clock_time", 1)
				room:setPlayerMark(player, "@game", 1)
				room:setPlayerMark(player, "RealPlayer", 1)
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(_targets) do
					p:drawCards(4)
				end
				room:setTag("FirstRound" , sgs.QVariant(false))

--				for _,p2 in sgs.qlist(room:getAlivePlayers()) do
--					if p2:getRole() == "rebel" then
--						room:killPlayer(p2)
--					end
--				end 
			end

			if phase == sgs.Player_NotActive and player:getMark("@AG_enternextstage") > 0 then
				for _,p in sgs.qlist(room:getPlayers()) do
					room:setPlayerMark(p, "@AG_enternextstage", 0)
				end

				--[[
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "@AG_enternextstage", 0)
					if p:getRole() == "loyalist" then
						p:throwAllCards()
						if p:getJudgingArea():length() > 0 then
							for _, card in sgs.qlist(p:getJudgingArea()) do
								if not card:isKindOf("SkillCard") then 
									room:throwCard(card, p)
								end
							end
						end
						for _,sk in sgs.qlist(p:getVisibleSkillList()) do
							if not sk:inherits("SPConvertSkill") and not sk:isAttachedLordSkill() then
								room:handleAcquireDetachSkills(p,"-"..sk:objectName())
							end
						end
					end
				end
				]]--
				local realplayer
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("RealPlayer") == 1 then
						realplayer = p
					end
				end

				if realplayer:getMark("@game") == 3 then

					--[[
					local _targets = sgs.SPlayerList()
					local lwtarget1 = player
					for i = 1, 8, 1 do
						_targets:append(lwtarget1)
						lwtarget1 = lwtarget1:getNextAlive()
					end
					]]--

					local _targets = sgs.SPlayerList()
					local can_append = false
					for _, p in sgs.qlist(room:getPlayers()) do
						if p:getMark("RealPlayer") == 1 then
							can_append = not can_append
						end
						if can_append then
							_targets:append(p)
						end
					end
					local draw_targets = sgs.SPlayerList()

					local i = 0
					for _, p in sgs.qlist(_targets) do
						i = i + 1
						if i == 6 then
							room:revivePlayer(p)
							draw_targets:append(p)
							room:changeHero(p, "shenlvbu1_2020", false,true, false,false)
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()))
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
						elseif i == 2 or  i == 4 or i >= 6 then

						end
					end
					for _, p in sgs.qlist(_targets) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					end
					room:setTag("FirstRound" , sgs.QVariant(true))
					for _, p in sgs.qlist(draw_targets) do
						p:drawCards(4)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				elseif realplayer:getMark("@game") == 2 then
					--[[
					local _targets = sgs.SPlayerList()
					local lwtarget1 = player
					for i = 1, 8, 1 do
						_targets:append(lwtarget1)
						lwtarget1 = lwtarget1:getNextAlive()
					end
					]]--

					local _targets = sgs.SPlayerList()
					local can_append = false
					for _, p in sgs.qlist(room:getPlayers()) do
						if p:getMark("RealPlayer") == 1 then
							can_append = not can_append
						end
						if can_append then
							_targets:append(p)
						end
					end

					local draw_targets = sgs.SPlayerList()
					local i = 0
					for _, p in sgs.qlist(_targets) do
						i = i + 1
						if i == 4 or i == 6 then
							room:revivePlayer(p)
							draw_targets:append(p)
							local sks_all = {"gaoshun","chengong","caoxing","dongxie"}
							for ii=1, #sks_all, 1 do
								for _,pp in sgs.qlist(room:getAlivePlayers()) do
									if pp:getGeneralName() == sks_all[ii] then
										--table.remove(generals, i)
										table.removeOne(sks_all, sks_all[ii])
									end
								end
							end
							local sks = {}
							local random1 = math.random(1, #sks_all)
							table.insert(sks, sks_all[random1])
							local general = room:askForGeneral(p, table.concat(sks, "+"))
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()+2))
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
							room:changeHero(p, general, false,true, false,false)
							if p:getGeneralName()== "gaoshun" then
								room:handleAcquireDetachSkills(p, "mashu", true)
								room:handleAcquireDetachSkills(p, "sizhen", true)
								room:handleAcquireDetachSkills(p, "juejiu", true)
								room:handleAcquireDetachSkills(p, "-xianzhen")
								room:handleAcquireDetachSkills(p, "-jinjiu")
							end
							if p:getGeneralName()== "chengong" then
								room:handleAcquireDetachSkills(player, "-mingce")
								room:handleAcquireDetachSkills(player, "shence", true)
							end
								
						elseif i == 2 then
							room:revivePlayer(p)
							draw_targets:append(p)
							room:changeHero(p, "huaxiong_po", false,true, false,false)
							room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()+2))
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
							room:handleAcquireDetachSkills(p, "mojun", true)
							room:handleAcquireDetachSkills(p, "moqu", true)
						elseif i > 6 then
							
						end
					end
					for _, p in sgs.qlist(_targets) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
					end
					room:setTag("FirstRound" , sgs.QVariant(true))
					for _, p in sgs.qlist(draw_targets) do
						p:drawCards(4)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
				end

				for _,p in sgs.qlist(room:getPlayers()) do
					room:setPlayerMark(p, "@AG_enternextstage", 0)
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,

}

if not sgs.Sanguosha:getSkill("#nl_HulaoMode") then skills:append(nl_HulaoMode) end

----------------------------------------------
--虎牢關
-----------------------------------
nl_hulaoguan = sgs.CreateTriggerSkill{
	name = "#nl_hulaoguan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.BuryVictim,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:isLord() and (not room:getTag("ExtraTurn"):toBool()) then
				if player:getMark("@clock_time") == 0 and player:getMark("@leader") > 0 then

					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						choosenewgeneral(p, 9,false,{})
					end
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p,"gameMode_hulaoguan",1)
					end

					local special_equips = {"muso_halberd","long_pheasant_tail_feather_purple_gold_crown"
,"red_cotton_hundred_flower_robe","linglong_lion_rough_band"}
					for i = 1,2,1 do 
						local random1 = math.random(1, #special_equips)
						room:setPlayerMark(player,"use_hulaoguan_equip"..special_equips[random1],1)
						table.remove(special_equips, random1)
					end


					for _, p in sgs.qlist(room:getAlivePlayers()) do
						room:getThread():trigger(sgs.GameStart, room, p, data)
						getqixing(p)
						if not player:isLord() then
							room:getThread():trigger(sgs.DrawInitialCards, room, p, data)
						end
					end
					room:setPlayerMark(player, "@clock_time", 1)
					--local card_remover = sgs.Sanguosha:getTriggerSkill("card_remover")
					--card_remover:trigger(sgs.GameStart, room, player, data)

					room:setTag("FirstRound" , sgs.QVariant(true))
					player:drawCards(8)
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						p:drawCards(4)
					end
					room:setTag("FirstRound" , sgs.QVariant(false))
					room:setPlayerMark(player, "@leader", 0)
				end
				for _, p in sgs.qlist(room:getPlayers()) do
					if not p:isAlive() then
						if p:getMark("@sanying_turn") >= 6 then
							room:revivePlayer(p)
							if p:getMaxHp() >= 3 then
								room:setPlayerProperty(p, "hp", sgs.QVariant(3))
								p:drawCards(3)
							else
								local playermaxhp = p:getMaxHp()
								room:setPlayerProperty(p, "hp", sgs.QVariant(playermaxhp))
								p:drawCards((6-playermaxhp))
							end
							room:setPlayerMark(p,"@sanying_turn",0)
						else
							room:setPlayerMark(p,"@sanying_turn",p:getMark("@sanying_turn") + 1)	
						end
					end
				end
			elseif change.to == sgs.Player_NotActive and not room:getTag("ExtraTurn"):toBool() then
				local nextplayer = player:getNextAlive()
				if not nextplayer:isLord() and not player:isLord() then

					local lord_player
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:isLord() and p:getMark("@sy_waked") == 0  then
							lord_player = p
							break
						end
					end

					if lord_player then
						room:setTag("ExtraTurn",sgs.QVariant(true))
						lord_player:gainAnExtraTurn()
						room:setTag("ExtraTurn",sgs.QVariant(false))
					end
				end
			end
		elseif event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local splayer = death.who
			if player:getRole() == "rebel" and splayer:getRole() == "rebel" then
				player:drawCards(1)
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
	priority = 15,
}

nl_hulaoguanskip = sgs.CreateTriggerSkill{
	name = "#nl_hulaoguanskip",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			local breakphase = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@jumpend") == 1 then
					breakphase = 1
				end
			end
			if breakphase == 1 then
				if player:getMark("@jumpend") == 1 then
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, "@jumpend", 0)
					end
				else
					room:getThread():delay(1000)
					room:throwEvent(sgs.TurnBroken)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end ,
}

if not sgs.Sanguosha:getSkill("#nl_hulaoguan") then skills:append(nl_hulaoguan) end
if not sgs.Sanguosha:getSkill("#nl_hulaoguanskip") then skills:append(nl_hulaoguanskip) end

sgs.LoadTranslationTable{
	["$sanyinglimit"] = "惹了我，你們的下場....",
}
----------------------------------------------

--------------------------------------------------------------------------------------------
----------------------------------------守衛劍門關-------------------------------------------
---------------------------------------------------------------------------------------------

--[[
烈帝玄德 5體力
激陣 結束階段開始時，你可以令所有已受傷的友方角色摸一張牌。
靈鋒 摸牌階段，你可以放棄摸牌，亮出牌堆頂的兩張牌，然後獲得之，若這些牌的顏色不同，你可以令一名敵方角色失去1點體力。
親陣 鎖定技，友方角色於其出牌階段出殺次數+1（僅在對應陣營事件內可擁有此技能）。
jgjizhen qinzhen
]]--
jgqinzhen = sgs.CreateTargetModSkill{
	name = "jgqinzhen",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, from, card)
		for _, p in sgs.qlist(from:getAliveSiblings()) do
			if p:hasSkill("jgxiaorui") and isSameTeam(p,from) then
				return 1
			end
		end
	end,
}

if not sgs.Sanguosha:getSkill("jgqinzhen") then skills:append(jgqinzhen) end

sgs.LoadTranslationTable{
["#jg_soul_liubei"] = "季漢英魂",
["jg_soul_liubei"] = "烈帝玄德",
["illustrator:jg_soul_liubei"] = "",
["jgjizhen"] = "激陣",
[":jgjizhen"] = "鎖定技。結束階段開始時，所有已受傷的己方角色各摸一張牌。",
["jglingfeng"] = "靈鋒",
[":jglingfeng"] = "摸牌階段開始時，你可以放棄摸牌，亮出牌堆頂的兩張牌並獲得之：若亮出的牌不為同一顏色，你令一名對方角色失去1點體力。",
["@jglingfeng"] = "請選擇一名對方角色令其失去1點體力",
["jgqinzhen"] = "親陣",
[":jgqinzhen"] = "鎖定技，友方角色於其出牌階段出殺次數+1",
}
--[[
翊漢雲長 5體力
驍銳 友方角色於其回合內使用【殺】造成傷害後，其使用【殺】的次數+1。
虎臣 鎖定技，你摸牌階段摸牌數+X（X為你擊殺的敵方角色數）。
天將 鎖定技，友方角色每回合首次使用【殺】造成傷害後，其摸一張牌（僅在對應陣營事件內可擁有此技能）。
xiaorui huchen tianjiang
]]--
jg_soul_guanyu = sgs.General(extension, "jg_soul_guanyu", "shu", "5", true,true,true)

jgxiaorui = sgs.CreateTriggerSkill{
	name = "jgxiaorui", 
	events = {sgs.Damage}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage  then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("jgxiaorui") and isSameTeam(p,player) then
						room:addPlayerMark(player,"jgxiaorui-Clear")
					end
				end
			end
		end
		return false
	end,
	can_trigger=function(self,player)
		return player and player:isAlive()
	end
}

jgxiaoruiTM = sgs.CreateTargetModSkill{
	name = "#jgxiaoruiTM",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, from, card)
		return from:getMark("jgxiaorui-Clear")
	end,
}

jghuchen = sgs.CreateTriggerSkill{
	name = "jghuchen", 
	frequency = sgs.Skill_Compulsory, --, NotFrequent, Compulsory, Limited, Wake 
	events = {sgs.Death,sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return false end
			local killer = death.damage.from
			local current = room:getCurrent()
			if current and (current:isAlive() or death.who == current)
			  and current:getPhase() ~= sgs.Player_NotActive then
				if killer then
					if killer:isAlive() then
						killer:addMark(self:objectName())
					end
				end
			end
		elseif event == sgs.DrawNCards and RIGHT(self, player) then
			room:broadcastSkillInvoke(self:objectName())
			data:setValue(data:toInt() + player:getMark(self:objectName()))
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

jgtianjiang = sgs.CreateTriggerSkill{
	name = "jgtianjiang", 
	events = {sgs.Damage}, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage  then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("jgxiaorui") and isSameTeam(p,player) and player:getMark("jgtianjiang-Clear") == 0 then
						room:addPlayerMark(player,"jgtianjiang-Clear")
						player:drawCards(1)
					end
				end
			end
		end
		return false
	end,
	can_trigger=function(self,player)
		return player and player:isAlive()
	end
}

jg_soul_guanyu:addSkill(jgxiaorui)
jg_soul_guanyu:addSkill(jgxiaoruiTM)
jg_soul_guanyu:addSkill(jghuchen)

if not sgs.Sanguosha:getSkill("jgtianjiang") then skills:append(jgtianjiang) end

sgs.LoadTranslationTable{
["#jg_soul_guanyu"] = "季漢英魂",
["jg_soul_guanyu"] = "翊漢雲長",
["illustrator:jg_soul_zhugeliang"] = "",
["jgxiaorui"] = "驍銳",
[":jgxiaorui"] = "友方角色於其回合內使用【殺】造成傷害後，其使用【殺】的次數+1。",
["jghuchen"] = "虎臣",
[":jghuchen"] = "鎖定技，你摸牌階段摸牌數+X（X為你擊殺的敵方角色數）。",
["jgtianjiang"] = "天將", 
[":jgtianjiang"] = "鎖定技，友方角色每回合首次使用【殺】造成傷害後，其摸一張牌。", 
}

--[[
扶危子龍 5體力
封緘 受到你傷害的角色於其下個回合結束前，無法使用牌指定你為目標。
克定 當你使用【殺】或普通錦囊牌僅指定唯一目標時，你可以棄置任意張手牌，為其指定等量的額外目標。
龍威 每當一名友方角色進入瀕死狀態時，你可以減一點體力上限，令其體力值回復至1點（僅在對應陣營事件內可擁有此技能）
fengjian keding longwei
]]--
jg_soul_zhaoyun = sgs.General(extension, "jg_soul_zhaoyun", "shu", "5", true,true,true)

jgfengjian = sgs.CreateTriggerSkill{
	name = "jgfengjian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.to:objectName() ~= player:objectName() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--room:addPlayerMark(damage.from, self:objectName()..player:objectName())
					room:addPlayerMark(damage.to,"jgfengjian_flag")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}

jgfengjianPS = sgs.CreateProhibitSkill{
	name = "#jgfengjianPS",
	is_prohibited = function(self, from, to, card)
		return not card:isKindOf("SkillCard") and from:objectName() ~= to:objectName() and from:getMark("jgfengjian_flag") > 0 and to:hasSkill("jgfengjian")
	end
}

jgkedingCard = sgs.CreateSkillCard{
	name = "jgkeding" ,
	filter = function(self, targets, to_select)
		if #targets > self:getSubcards():length() then return false end
		if to_select:hasFlag("notZangshiTarget") or (to_select:objectName() == sgs.Self:objectName()) then return false end
		return true
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			p:setFlags("zangshiTarget")
		end
	end
}
jgkedingVS = sgs.CreateViewAsSkill{
	name = "jgkeding" ,
	n = 999,
	response_pattern = "@@jgkeding",
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		local jgkeding = jgkedingCard:clone()
		for _, c in ipairs(cards) do
			jgkeding:addSubcard(c)
		end
		return jgkeding
	end
}
jgkeding = sgs.CreateTriggerSkill{
	name = "jgkeding" ,
	events = {sgs.PreCardUsed} ,
	view_as_skill = jgkedingVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.PreCardUsed then
			if (room:alivePlayerCount() > 2) and (use.card:isKindOf("Slash") or use.card:isNDTrick())
			 and not use.card:isKindOf("Nullification") and
			  not use.card:isKindOf("Collat​​eral") and use.to:length() == 1 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.to:contains(p) or p == use.from then
						room:setPlayerFlag(p, "notZangshiTarget")
					end
				end
				room:setPlayerFlag(player, "jgkedingtm")
				room:setTag("jgkedingData", data)	
				if room:askForUseCard(player, "@@jgkeding", "@jgkeding:"..use.card:objectName(), -1, sgs.Card_MethodDiscard) then
					room:removeTag("jgkedingData")
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasFlag("zangshiTarget") and not room:isProhibited(player, p, use.card) then
							p:setFlags("-zangshiTarget")
							use.to:append(p)
							room:sortByActionOrder(use.to)
							data:setValue(use)

							local msg = sgs.LogMessage()
							msg.type = "#ExtraTarget"
							msg.from = player
							msg.to:append(p)
							msg.arg = self:objectName()
							msg.arg2 = use.card:objectName()
							room:sendLog(msg)
						end
					end
				end
				room:setPlayerFlag(player, "-jgkedingtm")	
			end
		end
		return false
	end
}

jgkedingtm = sgs.CreateTargetModSkill{
	name = "#jgkedingtm" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("jgkedingtm")) then
			return 1000
		end
		return 0
	end
}

jglongwei = sgs.CreateTriggerSkill{
	name = "jglongwei",
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			if dying.who and isSameTeam(dying.who,player) then
				if room:askForSkillInvoke(player,self:objectName(),data) then
					local recover = sgs.RecoverStruct()
					recover.recover = 1 - dying.who:getHp()
					room:recover(dying.who, recover)
				end
			end
		end
		return false
	end
}

jg_soul_zhaoyun:addSkill(jgfengjian)
jg_soul_zhaoyun:addSkill(jgfengjianPS)
jg_soul_zhaoyun:addSkill(jgkeding)
jg_soul_zhaoyun:addSkill(jgkedingtm)

if not sgs.Sanguosha:getSkill("jglongwei") then skills:append(jglongwei) end

sgs.LoadTranslationTable{
["#jg_soul_zhaoyun"] = "季漢英魂",
["jg_soul_zhaoyun"] = "扶危子龍",
["illustrator:jg_soul_zhaoyun"] = "",
["jgfengjian"] = "封緘",
[":jgfengjian"] = "受到你傷害的角色於其下個回合結束前，無法使用牌指定你為目標。",
["jgkeding"] = "克定",
[":jgkeding"] = "當你使用【殺】或普通錦囊牌僅指定唯一目標時，你可以棄置任意張手牌，為其指定等量的額外目標。",
["jglongwei"] = "龍威",
[":jglongwei"] = "每當一名友方角色進入瀕死狀態時，你可以減一點體力上限，令其體力值回復至1點。",
}

--[[
天候孔明 4體力
變天 準備階段，你可以進行一次判定，若為紅色，直到下個回合開始前，令敵方所有角色處於「狂風」狀態，若為黑桃，直到下個回合開始前，令友方所有角色處於「大霧」狀態。
八陣 鎖定技，若你的裝備區里沒有防具牌，你視為裝備著【八卦陣】。

]]--

jg_soul_zhugeliang_po = sgs.General(extension, "jg_soul_zhugeliang_po", "shu", "4", true,true,true)

jgbiantian_po = sgs.CreateTriggerSkill{
	name = "jgbiantian_po",
	events = {sgs.EventPhaseStart},
	view_as_skill = jgbiantian_poVS,
	on_trigger = function(self, event, player, data, room)
		if sgs.event == EventPhaseStart or event == sgs.Death then
			local splayer 
			if event == sgs.Death then
				local death = data:toDeath()
				splayer = death.who
			end
			if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart) then
				splayer = player
			end
			if splayer then
				local players = room:getAllPlayers()
				for _,p in sgs.qlist(players) do
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
		end
		if sgs.event == EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.reason = self:objectName()
			room:judge(judge)
			if judge.card:isRed() then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not isSameTeam(player,p) then
						p:gainMark("@gale")
						p:getRoom():setPlayerMark(p,"gale"..player:objectName(),1)
					end
				end
			elseif judge.card:getSuit() == sgs.Card_Spade then 
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if isSameTeam(player,p) then
						p:gainMark("@fog")
						p:getRoom():setPlayerMark(p,"fog"..player:objectName(),1)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player:isAlive() and player:hasSkill(self:objectName())
	end,
}

jgbiantian_po_effect = sgs.CreateTriggerSkill{
	name = "#jgbiantian_po_effect",
	events = {sgs.DamageForseen},
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageForseen then
				local damage = data:toDamage()
				local can_invoke = true
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("kuangfeng") or p:hasSkill("jgbiantian") then
						can_invoke  = false
					end
				end
				if damage.nature == sgs.DamageStruct_Fire and can_invoke and player:getMark("@gale") > 0 then
					local msg = sgs.LogMessage()
					msg.type = "#GalePower"
					msg.from = player
					msg.to:append(player)
					msg.arg = damage.damage
					msg.arg2 = damage.damage + 1
					room:sendLog(msg)
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
				if can_invoke and player:getMark("@fog") > 0 then
					local damage = data:toDamage()
					if damage.nature ~= sgs.DamageStruct_Thunder then
						room:broadcastSkillInvoke("LuaDawu")
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
			end
	end,
}


jg_soul_zhugeliang_po:addSkill(jgbiantian_po)
jg_soul_zhugeliang_po:addSkill(jgbiantian_po_effect)
jg_soul_zhugeliang_po:addSkill("bazhen")

extension:insertRelatedSkills("jgbiantian_po","#jgbiantian_po_effect")

sgs.LoadTranslationTable{
["#jg_soul_zhugeliang_po"] = "季漢英魂",
["jg_soul_zhugeliang_po"] = "天候孔明",
["illustrator:jg_soul_zhugeliang"] = "",
["jgbiantian_po"] = "變天",
[":jgbiantian_po"] = "準備階段，你可以進行一次判定，若為紅色，直到下個回合開始前，令敵方所有角色處於「狂風」狀態，若為黑桃，直到下個回合開始前，令友方所有角色處於「大霧」狀態。",
}
--[[
工神月英 4體力
工神 結束階段，若友方守城器械已受傷，你可以為其回復1點體力，否則你可以對敵方攻城器械造成1點火焰傷害。
智囊 準備階段，你可以亮出牌堆頂的三張牌，你可以將其中錦囊或裝備牌交給一名友方角色，然後將其餘牌置入棄牌堆。
精妙 鎖定技，每當敵方角色使用的【無懈可擊】生效後，你令其失去1點體力。
]]--
sgs.LoadTranslationTable{
["#jg_soul_huangyueying"] = "季漢英魂",
["jg_soul_huangyueying"] = "工神月英",
["illustrator:jg_soul_huangyueying"] = "",
["jggongshen"] = "工神",
[":jggongshen"] = "結束階段開始時，你可以選擇一項：令守城器械回復1點體力，或對攻城器械造成1點火焰傷害。",
["jggongshen:recover"] = "令守城器械回復1點體力",
["jggongshen:damage"] = "對攻城器械造成1點火焰傷害",
["jgzhinang"] = "智囊",
[":jgzhinang"] = "準備階段開始時，你可以亮出牌堆頂的三張牌，然後令一名己方角色獲得其中的非基本牌並將其餘的牌置入棄牌堆。",
["@jgzhinang"] = "請選擇一名己方角色令其獲得非基本牌",
["jgjingmiao"] = "精妙",
[":jgjingmiao"] = "鎖定技。對方角色使用【無懈可擊】結算完畢後，該角色失去1點體力。",
}
--[[
浴火士元 4體力
浴火 鎖定技，每當你受到火焰傷害時，防止此傷害。
棲梧 每當你使用梅花牌時，你可以令一名友方角色回復1點體力。
天獄 結束階段，你可以橫置所有未橫置敵方角色的武將牌。
jgqiwu_po jgtianyu_po
]]--
jg_soul_pangtong_po = sgs.General(extension, "jg_soul_pangtong_po", "shu", "4", true,true,true)

jgqiwu_po = sgs.CreateTriggerSkill{
	name = "jgqiwu_po",
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
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
		if invoke and card and (not card:isKindOf("SkillCard")) then
			if card:getSuit() == sgs.Card_Club then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if isSameTeam(p,player) and p:isWounded() then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "jgqiwu", "jgqiwu-invoke", true)
					if s then
						room:recover(s, sgs.RecoverStruct(player, nil, 1))
					end
				end
			end
		end
		return false
	end
}

jg_soul_pangtong_po:addSkill("jgyuhuo")
jg_soul_pangtong_po:addSkill(jgqiwu_po)
jg_soul_pangtong_po:addSkill("jgtianyu")

sgs.LoadTranslationTable{
["#jg_soul_pangtong_po"] = "季漢英魂",
["jg_soul_pangtong_po"] = "浴火士元",
["illustrator:jg_soul_pangtong_po"] = "",
["jgyuhuo"] = "浴火",
[":jgyuhuo"] = "鎖定技。每當你受到火焰傷害時，防止此傷害。",
["#JGYuhuoProtect"] = "%from 的“<font color=\"yellow\"><b>浴火</b></font>”被觸發，防止了%arg 點傷害[%arg2]" ,
["jgqiwu_po"] = "棲梧",
[":jgqiwu_po"] = "每當你使用梅花牌時，你可以令一名友方角色回復1點體力。",
["jgqiwu-invoke"] = "你可以發動“棲梧”<br/> <b>操作提示</b>: 選擇一名友方角色→點擊確定<br/>",
["jgtianyu"] = "天獄",
[":jgtianyu"] = "鎖定技。結束階段開始時，你橫置所有不處於連環狀態的對方角色的武將牌。",
}
--[[
魏國英魂：
枯木元讓 5體力
拔矢 每當你成為其他角色使用的殺或普通錦囊牌的目標時，你可以從正面翻至背面，若如此做，此牌對你無效。
啖睛 友方角色處於瀕死狀態時，若你的體力值大於1，你可以失去1點體力，視為對其使用一張【桃】。
統軍 鎖定技，友方攻城器械的攻擊範圍+1（僅在對應陣營事件內可擁有此技能）。
jgbashi jgdanjing tongjun 
]]--
jg_soul_xiahoudun = sgs.General(extension, "jg_soul_xiahoudun", "wei", "5", true,true,true)

jgbashi = sgs.CreateTriggerSkill{
	name = "jgbashi" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and player:faceUp() then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:setFlags("-ZhenlieTarget")
						player:setFlags("ZhenlieTarget")
						player:turnOver()
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
		return false
	end
}

jgdanjingVS = sgs.CreateViewAsSkill{
	name = "jgdanjing",
	n = 0,
	view_as = function(self, cards)
		local peach = sgs.Sanguosha:cloneCard("peach", suit, point)
		peach:setSkillName(self:objectName())
		return peach
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and player:getHp() > 1
	end
}

jgdanjing = sgs.CreateTriggerSkill{
	name = "jgdanjing",
	events = {sgs.CardFinished},
	view_as_skill = jgdanjingVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == "jgdanjing" then
				room:loseHp(player,1)
			end
		end
	end,
}

jgtongjun = sgs.CreateTargetModSkill{
	name = "jgtongjun",
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, from, card)
		local all_machine = {"jg_machine_fudibian","jg_machine_shihuosuanni","jg_machine_tuntianchiwen","jg_machine_lieshiyazi"
	,"jg_machine_yunpingqinglong","jg_machine_jileibaihu","jg_machine_chiyuzhuque","jg_machine_lingjiaxuanwu"}
		if table.contains( all_machine, from:getGeneralName()) then
			for _, p in sgs.qlist(from:getAliveSiblings()) do
				if p:hasSkill("jgtongjun") and isSameTeam(p,from) then
					return 1
				end
			end
		end
	end,
}

if not sgs.Sanguosha:getSkill("jgtongjun") then skills:append(jgtongjun) end

jg_soul_xiahoudun:addSkill(jgbashi)
jg_soul_xiahoudun:addSkill(jgdanjing)

sgs.LoadTranslationTable{
["#jg_soul_xiahoudun"] = "曹魏英魂",
["jg_soul_xiahoudun"] = "枯木元讓",
["illustrator:jg_soul_xiahoudun"] = "",
["jgbashi"] = "拔矢",
[":jgbashi"] = "每當你成為其他角色使用的殺或普通錦囊牌的目標時，你可以從正面翻至背面，若如此做，此牌對你無效。",
["jgdanjing"] = "啖睛",
[":jgdanjing"] = "友方角色處於瀕死狀態時，若你的體力值大於1，你可以失去1點體力，視為對其使用一張【桃】。",
["jgtongjun"] = "統軍",
[":jgtongjun"] = "鎖定技，友方攻城器械的攻擊範圍+1。",
}

--[[
百計文遠 5體力
繳械 出牌階段限一次，你可令至多兩名敵方守城器械交給你一張牌。
帥令 鎖定技，友方角色的摸牌階段開始時進行一次判定，若判定為黑色，其獲得此判定牌（僅在對應陣營事件內可擁有此技能）
 jiaoxie shuailing
]]--
jg_soul_zhangliao = sgs.General(extension, "jg_soul_zhangliao", "wei", "5", true,true,true)

jgjiaoxieCard = sgs.CreateSkillCard{
	name = "jgjiaoxie",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	local all_machine = {"jg_machine_fudibian","jg_machine_shihuosuanni","jg_machine_tuntianchiwen","jg_machine_lieshiyazi"
	,"jg_machine_yunpingqinglong","jg_machine_jileibaihu","jg_machine_chiyuzhuque","jg_machine_lingjiaxuanwu"}
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if table.contains( all_machine, p:getGeneralName()) and not isSameTeam(source,p) then
				room:doAnimate(1, source:objectName(), p:objectName())
			end
		end
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if table.contains( all_machine, p:getGeneralName()) and not isSameTeam(source,p) and not p:isNude() then
				local card = room:askForCard(p, "..!", "@qiai_give:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), source:objectName(), self:objectName(), ""))
				end
			end
		end
	end
}
jgjiaoxie = sgs.CreateZeroCardViewAsSkill{
	name = "jgjiaoxie",
	view_as = function()
		return jgjiaoxieCard:clone()
	end,
	enabled_at_play = function(self, player)	
		return not player:hasUsed("#jgjiaoxie")
	end,
}

jgshuailing = sgs.CreateTriggerSkill{
	name = "jgshuailing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("jgshuailing") and isSameTeam(player,p) then
						room:notifySkillInvoked(player,"jgshuailing")
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|black"
						judge.good = true
						judge.reason = self:objectName()
						judge.who = player
						judge.time_consuming = true
						room:judge(judge)
						if judge:isGood() then
							player:obtainCard(judge.card)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger=function(self,player)
		return player and player:isAlive()
	end
}

jg_soul_zhangliao:addSkill(jgjiaoxie)
if not sgs.Sanguosha:getSkill("jgshuailing") then skills:append(jgshuailing) end

sgs.LoadTranslationTable{
["#jg_soul_zhangliao"] = "曹魏英魂",
["jg_soul_zhangliao"] = "百計文遠",
["illustrator:jg_soul_zhangliao"] = "",
["jgjiaoxie"] = "繳械",
[":jgjiaoxie"] = "出牌階段限一次，你可令至多兩名敵方守城器械交給你一張牌。",
["jgshuailing"] = "帥令",
[":jgshuailing"] = "鎖定技，友方角色的摸牌階段開始時進行一次判定，若判定為黑色，其獲得此判定牌。",
}

--[[
佳人子丹 5體力
持盈 鎖定技，每當友方角色受到傷害多於1時，你防止其餘傷害。
驚帆 鎖定技，友方其他角色計算與敵方角色距離時，始終-1。
鎮西 鎖定技，每當友方角色受到傷害後，你令其下個摸牌階段摸牌數+1（僅在對應陣營事件內可擁有此技能）。
]]--

jgzhenxi = sgs.CreateTriggerSkill{
	name = "jgzhenxi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if player:getMark("jgzhenxi") > 0 then
				room:notifySkillInvoked(player, self:objectName())
				data:setValue(data:toInt() + player:getMark("jgzhenxi") )
				room:setPlayerMark(player,"jgzhenxi",0)
			end
		else
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("jgzhenxi") and isSameTeam(player,p) then
					room:addPlayerMark(player,"jgzhenxi")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, player)
		return player ~= nil
	end,
}

if not sgs.Sanguosha:getSkill("jgzhenxi") then skills:append(jgzhenxi) end

sgs.LoadTranslationTable{
["#jg_soul_caozhen"] = "曹魏英魂",
["jg_soul_caozhen"] = "佳人子丹",
["illustrator:jg_soul_caozhen"] = "",
["jgchiying"] = "持盈",
[":jgchiying"] = "鎖定技。每當己方角色受到傷害時，若此傷害大於1點，防止多餘的傷害。",
["jgjingfan"] = "驚帆",
[":jgjingfan"] = "鎖定技。其他己方角色與對方角色的距離-1。",
["#JGChiying"] = "%from 的“%arg2”被觸發，防止了%to 受到的 %arg 點傷害，減至<font color=\"yellow\"><b>1</b>< /font> 點",
["jgzhenxi"] = "鎮西",
[":jgzhenxi"] = "鎖定技，每當友方角色受到傷害後，你令其下個摸牌階段摸牌數+1。",
}
--[[
斷獄仲達 5體力
控魂 出牌階段開始時，若你已損失體力值不小於敵方角色數，你可以對所有敵方角色各造成1點雷電傷害，然後你恢復X點體力（X為受到傷害的角色數）。
反噬 鎖定技，結束階段，你失去1點體力。
玄雷 鎖定技，準備階段，令所有判定區內有牌的敵方角色受到1點雷電傷害。
]]--
sgs.LoadTranslationTable{
["#jg_soul_simayi"] = "曹魏英魂",
["jg_soul_simayi"] = "斷獄仲達",
["illustrator:jg_soul_simayi"] = "",
["jgkonghun"] = "控魂",
[":jgkonghun"] = "出牌階段開始時，若你已損失的體力值不小於X，你可以對所有對方角色各造成1點雷電傷害，"..
"然後你回復X點體力（X為對方角色數）。",
["jgfanshi"] = "反噬",
[":jgfanshi"] = "鎖定技。結束階段開始時，你失去1點體力。",
["jgxuanlei"] = "玄雷",
[":jgxuanlei"] = "鎖定技。準備階段開始時，判定區有牌的對方角色受到1點雷電傷害。",
}
--[[
絕塵妙才 5體力
穿雲 結束階段，你可以對一名體力比你多的敵方角色造成1點傷害。
雷厲 每當你的【殺】造成傷害後，你可以對另一名敵方角色造成1點雷電傷害。
風行 準備階段，你可以選擇一名敵方角色，若如此做，視為對其使用了一張【殺】。
jgchuanyun_po
]]--
sgs.LoadTranslationTable{
["#jg_soul_xiahouyuan"] = "曹魏英魂",
["jg_soul_xiahouyuan"] = "絕塵妙才",
["illustrator:jg_soul_xiahouyuan"] = "",
["jgchuanyun"] = "穿雲",
[":jgchuanyun"] = "結束階段開始時，你可以對一名體力值不小於你的角色造成1點傷害。",
["jgchuanyun-invoke"] = "你可以發動“穿雲”<br/> <b>操作提示</b>: 選擇一名體力值大於你的角色→點擊確定<br/>",
["jgleili"] = "雷厲",
[":jgleili"] = "每當你使用【殺】造成傷害後，你可以對另一名對方角色造成1點雷電傷害。",
["jgleili-invoke"] = "你可以發動“雷厲”<br/> <b>操作提示</b>: 選擇一名對方角色→點擊確定<br/>",
["jgfengxing"] = "風行",
[":jgfengxing"] = "準備階段開始時，你可以視為對一名對方角色使用一張無距離限制的【殺】。",
["jgfengxing-invoke"] = "你可以發動“風行”<br/> <b>操作提示</b>: 選擇【殺】的目標角色→點擊確定<br/>",
}
--[[
巧魁儁乂 4體力
惑敵 結束階段，若有武將牌背面朝上的友方角色，你可以令一名敵方角色將其武將牌翻面。
絕汲 鎖定技，敵方角色摸牌階段，若其已受傷，你令其少摸一張牌。
]]--
sgs.LoadTranslationTable{
["#jg_soul_zhanghe"] = "曹魏英魂",
["jg_soul_zhanghe"] = "巧魁儁乂",
["illustrator:jg_soul_zhanghe"] = "",
["jghuodi"] = "惑敵",
[":jghuodi"] = "結束階段開始時，若有武將牌背面朝上的己方角色，你可以令一名對方角色將武將牌翻面。",
["jghuodi-invoke"] = "你可以發動“惑敵”<br/> <b>操作提示</b>: 選擇一名對方角色→點擊確定<br/>",
["jgjueji"] = "絕汲",
[":jgjueji"] = "對方角色的摸牌階段，若其已受傷，你可以令其少摸一張牌。",
}
--[[
蜀國器械：
雲屏青龍 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
魔箭 鎖定技，出牌階段開始時，視為對所有敵方角色使用了一張【萬箭齊發】。
]]--
sgs.LoadTranslationTable{
["#jg_machine_yunpingqinglong"] = "守城器械",
["jg_machine_yunpingqinglong"] = "雲屏青龍",
["illustrator:jg_machine_yunpingqinglong"] = "",
["jgmojian"] = "魔箭",
[":jgmojian"] = "鎖定技。出牌階段開始時，視為你使用一張【萬箭齊發】。己方角色不被選擇為此【萬箭齊發】的目標。",
}
--[[
機雷白虎 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
鎮衛 鎖定技，對方角色計算與其他己方角色的距離時，始終+1。
奔雷 準備階段，你可以對敵方攻城器械造成2點雷電傷害。
jgbenlei_po
]]--
jgbenlei_po = sgs.CreateTriggerSkill{
	name = "jgbenlei_po",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart then
				local _targets = sgs.SPlayerList()
				local all_machine = {"jg_machine_fudibian","jg_machine_shihuosuanni","jg_machine_tuntianchiwen","jg_machine_lieshiyazi"
	,"jg_machine_yunpingqinglong","jg_machine_jileibaihu","jg_machine_chiyuzhuque","jg_machine_lingjiaxuanwu"}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if table.contains( all_machine, p:getGeneralName()) and not isSameTeam(player,p) then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "jgbenlei", "@cuike-damage", true)
					if s then
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke("jgbenlei")
						room:doAnimate(1, player:objectName(), s:objectName())
						room:damage(sgs.DamageStruct(nil,player,s, math.random(2,3) ,sgs.DamageStruct_Thunder))
					end
				end
			end
		end
	end,
	priority = 8,
}

if not sgs.Sanguosha:getSkill("jgbenlei_po") then skills:append(jgbenlei_po) end

sgs.LoadTranslationTable{
["#jg_machine_jileibaihu"] = "守城器械",
["jg_machine_jileibaihu"] = "機雷白虎",
["illustrator:jg_machine_jileibaihu"] = "",
["jgbenlei_po"] = "奔雷",
[":jgbenlei_po"] = "準備階段，你可以對敵方攻城器械造成2-3點雷電傷害。",
}
--[[
熾羽朱雀 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
浴火 鎖定技，每當你受到火焰傷害時，防止此傷害。
天隕 結束階段，你可以失去1點體力，然後對一名敵方角色造成2-3點火焰傷害並棄置其裝備區里的所有牌。
]]--

jgtianyun_po = sgs.CreateTriggerSkill{
	name = "jgtianyun_po",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not isSameTeam(player,p) then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "jgtianyun", "jgtianyun-invoke", true)
					if s then
						room:loseHp(player,1)
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke("jgtianyun")
						room:doAnimate(1, player:objectName(), s:objectName())
						room:damage(sgs.DamageStruct(nil,player,s, math.random(2,3) ,sgs.DamageStruct_Fire))
						s:throwAllEquips()
					end
				end
			end
		end
	end,
	priority = 8,
}

if not sgs.Sanguosha:getSkill("jgtianyun_po") then skills:append(jgtianyun_po) end

sgs.LoadTranslationTable{
["#jg_machine_chiyuzhuque"] = "守城器械",
["jg_machine_chiyuzhuque"] = "熾羽朱雀",
["illustrator:jg_machine_chiyuzhuque"] = "",
["jgtianyun_po"] = "天隕",
[":jgtianyun_po"] = "結束階段開始時，你可以選擇一名對方角色並失去1點體力：若如此做，該角色受到2~3點火焰傷害，然後棄置其裝備區的所有牌。 ",
["jgtianyun-invoke"] = "你可以發動“天隕”<br/> <b>操作提示</b>: 選擇一名對方角色→點擊確定<br/>",
}
--[[
靈甲玄武 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
毅重 鎖定技，若你的裝備區里沒有防具牌，黑色的【殺】對你無效。
靈愈 結束階段，你可以將自己的武將牌翻面，然後令所有已受傷的友方其他角色回復1點體力。
]]--
sgs.LoadTranslationTable{
["#jg_machine_lingjiaxuanwu"] = "守城器械",
["jg_machine_lingjiaxuanwu"] = "靈甲玄武",
["illustrator:jg_machine_lingjiaxuanwu"] = "",
["jglingyu"] = "靈愈",
[":jglingyu"] = "結束階段開始時，你可以將武將牌翻面：若如此做，所有已受傷的己方角色回復1點體力。",
}
--[[
魏國器械：
縛地狴犴 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
地動 結束階段，你可以令一名敵方角色將其武將牌翻面。
]]--
sgs.LoadTranslationTable{
["#jg_machine_fudibian"] = "攻城器械",
["jg_machine_fudibian"] = "縛地狴犴",
["illustrator:jg_machine_fudibian"] = "",
["jgdidong"] = "地動",
[":jgdidong"] = "結束階段開始時，你可以令一名對方角色將武將牌翻面。",
["jgdidong-invoke"] = "你可以發動“地動”<br/> <b>操作提示</b>: 選擇一名對方角色→點擊確定<br/>",
}
--[[
食火狻猊 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
煉獄 結束階段，你可以對所有敵方角色造成1點火焰傷害。
]]--
sgs.LoadTranslationTable{
["#jg_machine_shihuosuanni"] = "攻城器械",
["jg_machine_shihuosuanni"] = "食火狻猊",
["illustrator:jg_machine_shihuosuanni"] = "",
["jglianyu"] = "煉獄",
[":jglianyu"] = "結束階段開始時，你可以對所有對方角色各造成1點火焰傷害。",
}
--[[
吞天螭吻 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
貪食 鎖定技，結束階段開始時，你須棄置一張手牌。
吞噬 鎖定技，準備階段，對所有手牌數量大於你的敵方角色造成1點傷害。
jgtanshi_po
]]--
sgs.LoadTranslationTable{
["#jg_machine_tuntianchiwen"] = "攻城器械",
["jg_machine_tuntianchiwen"] = "吞天螭吻",
["illustrator:jg_machine_tuntianchiwen"] = "",
["jgjiguan"] = "機關",
[":jgjiguan"] = "鎖定技。你不能被選擇為【樂不思蜀】的目標。",
["jgtanshi"] = "貪食",
[":jgtanshi"] = "鎖定技。摸牌階段，你少摸一張牌。",
["jgtunshi"] = "吞噬",
[":jgtunshi"] = "鎖定技。準備階段開始時，所有手牌多於你的對方角色各受到1點傷害。",
}
--[[
裂石睚眥 5體力
機關 鎖定技，你不能成為【樂不思蜀】的目標。
奈落 結束階段，你可以將你的武將牌翻面，令所有敵方角色棄置裝備區內的所有牌。
]]--
sgs.LoadTranslationTable{
["#jg_machine_lieshiyazi"] = "攻城器械",
["jg_machine_lieshiyazi"] = "裂石睚眥",
["illustrator:jg_machine_lieshiyazi"] = "",
["jgdixian"] = "地陷",
[":jgdixian"] = "結束階段開始時，你可以將武將牌翻面：若如此做，所有對方角色棄置其裝備區的所有牌。",
}

--急襲
jgjixi = sgs.CreateOneCardViewAsSkill{
	name = "jgjixi", 
	view_filter = function(self, card)
		return card:isKindOf("TrickCard")
	end,
	view_as = function(self, originalCard) 
		local snatch = sgs.Sanguosha:cloneCard("snatch", originalCard:getSuit(), originalCard:getNumber())
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end, 
	enabled_at_play = function(self, player)
		return true
	end
}

--主技能
nl_jiangebattle = sgs.CreateTriggerSkill{
	name = "#nl_jiangebattle",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
			local n_r = 0
			local n_l = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getRole() == "rebel" then
					n_r = n_r + 1
				elseif p:getRole() == "loyalist" then
					n_l = n_l + 1
				end
			end

			if n_r == 0  then
				room:gameOver("loyalist")
			elseif n_l == 0 then
				room:gameOver("rebel")
			end
			room:setTag("SkipNormalDeathProcess",sgs.QVariant(false))
			if reason then
				local killer = reason.from
				if killer and killer:isAlive() then
					if killer:hasSkill(self:objectName()) then

						room:setTag("SkipNormalDeathProcess",sgs.QVariant(true))
						player:bury()
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_RoundStart and player:getMark("AG_hasExecuteStart") == 0 then
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)

				local i = 0
				local _targets = sgs.SPlayerList()
				local lwtarget1 = player
				for j = 1, 8, 1 do
					_targets:append(lwtarget1)
					lwtarget1 = lwtarget1:getNextAlive()
				end

				for _,p in sgs.qlist(_targets) do
					i = i + 1
					if i == 1 or i == 2 or i == 7 or i == 8 then
						room:setPlayerProperty(p, "role", sgs.QVariant("loyalist"))
					elseif i == 3 or i == 4 or i == 5 or i == 6 then
						room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
					end
					room:updateStateItem()
					room:resetAI(p)
				end
				local kingdom_list ={"shu","wei"}
				local kingdom = kingdom_list[math.random(1,2)]


				local n = math.random(1,10)
				room:doSuperLightbox("zuoci","JiangeModeEvent"..n)
				local msg = sgs.LogMessage()
				msg.type = "#JiangeModeEvent"
				msg.from = player
				msg.arg = "JiangeModeEvent"..n
				msg.arg2 = "JiangeModeEvent"..n.."text"
				room:sendLog(msg)

				--指定角色出場
				local i = 0
				local does_not_assign = true
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					if i == 4 or i == 5 or i == 8 then
						local sks_all = {}
						--只有一個位置時強制令為該英魂
						if (kingdom == "wei" and i == 8) then
							if n == 8 then
								sks_all = {"jg_soul_caozhen"}
								does_not_assign = false
							elseif n == 9 then
								sks_all = {"jg_soul_xiahoudun"}
								does_not_assign = false
							elseif n == 10 then
								sks_all = {"jg_soul_zhangliao"}
								does_not_assign = false
							end
						elseif (kingdom == "shu" and i == 8) then
							if n == 5 then
								sks_all = {"jg_soul_liubei"}
								does_not_assign = false
							elseif n == 6 then
								sks_all = {"jg_soul_guanyu"}
								does_not_assign = false
							elseif n == 7 then
								sks_all = {"jg_soul_zhaoyun"}
								does_not_assign = false
							end
							--兩個位置時隨機一個位置
						elseif kingdom == "wei" then
							if (math.random(1,2) == 1 and i == 2) or does_not_assign then
								if n == 5 then
									sks_all = {"jg_soul_liubei"}
									does_not_assign = false
								elseif n == 6 then
									sks_all = {"jg_soul_guanyu"}
									does_not_assign = false
								elseif n == 7 then
									sks_all = {"jg_soul_zhaoyun"}
									does_not_assign = false
								end
							end
						else
							if (math.random(1,2) == 1 and i == 2) or does_not_assign then
								if n == 8 then
									sks_all = {"jg_soul_caozhen"}
									does_not_assign = false
								elseif n == 9 then
									sks_all = {"jg_soul_xiahoudun"}
									does_not_assign = false
								elseif n == 10 then
									sks_all = {"jg_soul_zhangliao"}
									does_not_assign = false
								end
							end
						end
						if #sks_all > 0 then
							local general = room:askForGeneral(p, table.concat(sks_all, "+"))
							room:changeHero(p, general, false,false, false,false)

							--血量調整
							if p:getGeneralName() == "jg_soul_xiahouyuan" or p:getGeneralName() == "jg_soul_zhanghe" or
								p:getGeneralName() == "jg_soul_zhugeliang_po" or p:getGeneralName() == "jg_soul_pangtong_po" then
									room:setPlayerProperty(p, "maxhp", sgs.QVariant( 4 ))
							elseif p:getGeneralName() == "jg_soul_huangyueying" then
								room:setPlayerProperty(p, "maxhp", sgs.QVariant( 3 ))
							else
								room:setPlayerProperty(p, "maxhp", sgs.QVariant( 5 ))
							end
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
						end
					end
				end

				--其他角色出場
				i = 0
				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)

					i = i + 1
					if p:getGeneralName() == "sujiang" then

						if i == 1 or i == 7 then
							choosenewgeneral(p, 10, {kingdom,kingdom.."2"},{})
							room:setPlayerProperty(p, "kingdom", sgs.QVariant( kingdom ))
						elseif i == 2 or i == 3 or i == 6 then
							local sks_all = {}
							if (kingdom == "wei" and i == 2) or (kingdom == "shu" and i ~= 2) then
								sks_all = {"jg_machine_fudibian","jg_machine_shihuosuanni","jg_machine_tuntianchiwen","jg_machine_lieshiyazi"}
							else
								sks_all = {"jg_machine_yunpingqinglong","jg_machine_jileibaihu","jg_machine_chiyuzhuque","jg_machine_lingjiaxuanwu"}
							end
							local sks = {}
							local sks_use = {}
							for ii=1, #sks_all, 1 do
								local can_use = true
								for _,pp in sgs.qlist(room:getAlivePlayers()) do
									if pp:getGeneralName() == sks_all[ii] then
										can_use = false
									end
								end
								if can_use then
									table.insert(sks, sks_all[ii])
								end
							end
							table.insert(sks_use, sks[ math.random(1, #sks) ])
							local general = room:askForGeneral(p, table.concat(sks_use, "+"))
							room:changeHero(p, general, false,false, false,false)
							--血量調整
							if p:getGeneralName() == "jg_machine_fudibian" or p:getGeneralName() == "jg_machine_shihuosuanni" then
								room:setPlayerProperty(p, "maxhp", sgs.QVariant( 3 ))
							elseif p:getGeneralName() == "jg_machine_yunpingqinglong" or p:getGeneralName() == "jg_machine_jileibaihu" 
								or p:getGeneralName() == "jg_machine_chiyuzhuque" then
								room:setPlayerProperty(p, "maxhp", sgs.QVariant( 4 ))
							else
								room:setPlayerProperty(p, "maxhp", sgs.QVariant( 5 ))
							end
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))

						elseif i == 4 or i == 5 or i == 8 then
							local sks_all = {}
							if (kingdom == "wei" and i == 8) or (kingdom == "shu" and i ~= 8) then
								sks_all = {"jg_soul_xiahoudun","jg_soul_zhangliao","jg_soul_caozhen","jg_soul_simayi","jg_soul_xiahouyuan","jg_soul_zhanghe"}
							else
								sks_all = {"jg_soul_liubei","jg_soul_guanyu","jg_soul_zhaoyun","jg_soul_zhugeliang_po","jg_soul_huangyueying","jg_soul_pangtong_po"}
							end
							local sks = {}
							local sks_use = {}
							for ii=1, #sks_all, 1 do
								local can_use = true
								for _,pp in sgs.qlist(room:getAlivePlayers()) do
									if pp:getGeneralName() == sks_all[ii] then
										can_use = false
									end
								end
								if can_use then
									table.insert(sks, sks_all[ii])
								end
							end
							table.insert(sks_use, sks[ math.random(1, #sks) ])
							local general = room:askForGeneral(p, table.concat(sks_use, "+"))
							room:changeHero(p, general, false,false, false,false)
							--血量調整
							if p:getGeneralName() == "jg_soul_xiahouyuan" or p:getGeneralName() == "jg_soul_zhanghe" or
								p:getGeneralName() == "jg_soul_zhugeliang_po" or p:getGeneralName() == "jg_soul_pangtong_po" then
									room:setPlayerProperty(p, "maxhp", sgs.QVariant( 4 ))
							elseif p:getGeneralName() == "jg_soul_huangyueying" then
								room:setPlayerProperty(p, "maxhp", sgs.QVariant( 3 ))
							else
								room:setPlayerProperty(p, "maxhp", sgs.QVariant( 5 ))
							end
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))
						end
					end

					room:updateStateItem()
					room:resetAI(p)
				end

				--額外技能
				i = 0
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					if i == 1 or i == 7 then
						if kingdom == "wei" then
							if n == 2 then
								room:acquireSkill(p, "qigong")
							elseif n == 3 then
								room:acquireSkill(p, "jgjixi")
							elseif n == 4 then
								room:acquireSkill(p, "lizhan")
							end
						end
						if kingdom == "shu" then
							if n == 2 then
								room:acquireSkill(p, "qigong")
							elseif n == 4 then
								room:acquireSkill(p, "fangong")
							end
						end

					elseif i == 4 or i == 5 or i == 8 then
						if n == 5 then
							if p:getGeneralName() == "jg_soul_liubei" then
								room:acquireSkill(p, "jgqinzhen")
							end
						elseif n == 6 then
							if p:getGeneralName() == "jg_soul_guanyu" then
								room:acquireSkill(p, "jgtianjiang")
							end
						elseif n == 7 then
							if p:getGeneralName() == "jg_soul_zhaoyun" then
								room:acquireSkill(p, "jglongwei")
							end
						elseif n == 8 then
							if p:getGeneralName() == "jg_soul_caozhen" then
								room:acquireSkill(p, "jgzhenxi")
							end
						elseif n == 9 then
							if p:getGeneralName() == "jg_soul_xiahoudun" then
								room:acquireSkill(p, "jgtongjun")
							end
						elseif n == 10 then
							if p:getGeneralName() == "jg_soul_zhangliao" then
								room:acquireSkill(p, "jgshuailing")
							end
						end
					end

					if p:hasSkill("jgbenlei") then
						room:acquireSkill(p, "jgbenlei_po")
						room:detachSkillFromPlayer(p, "jgbenlei")
					end
					if p:hasSkill("jgtianyun") then
						room:acquireSkill(p, "jgtianyun_po")
						room:detachSkillFromPlayer(p, "jgtianyun")
					end
				end

				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "gameMode_noOx", 1)
					room:getThread():trigger(sgs.GameStart, room, p, data)
				end


				local i = 0
				room:setTag("FirstRound" , sgs.QVariant(true))
				for _, p in sgs.qlist(_targets) do
					i = i + 1
					if i == 1 then
						p:drawCards(5)
					elseif i == 8 then
						p:drawCards(5)
					elseif i == 7 then
						p:drawCards(6)
					else
						p:drawCards(4)
					end
					if (i == 1 or i == 7) and n == 1 then
						getpatterncard(p, {"Armor","Jink"} ,true,false)
					end 
					if (i == 1 or i == 7) and n == 3 and kingdom == "shu" then
						p:drawCards(1)
					end
					if (i == 1 or i == 7)  then
						room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp()+2))
						room:setPlayerProperty(p, "hp", sgs.QVariant(p:getHp()+2))
					end
				end
				room:setTag("FirstRound" , sgs.QVariant(false))
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,

}

sgs.LoadTranslationTable{
["#JiangeModeEvent"] = "本局遊戲特殊規則為 %arg ，內容為 %arg2",
["JiangeModeEvent1"] = "據守劍閣",
["JiangeModeEvent1text"] = "所有玩家開局額外獲得一張防具牌和一張閃。",
["JiangeModeEvent2"] = "兵分三路",
["JiangeModeEvent2text"] = "魏國玩家額外獲得【齊攻】技能。（你使用的殺被閃抵消後，可對目標再使用一張殺，此殺不可被閃"..
"抵消）；蜀國玩家額外獲得【度勢】技能。（出牌階段限一次，你可以將一張紅色手牌當以逸待勞）",

["JiangeModeEvent3"] = "偷渡陰平",
["JiangeModeEvent3text"] = "魏國玩家開局損失一點體力，額外獲得【急襲】技能。（可以將一張錦囊牌當順手牽羊使用）；蜀國玩家開局額外獲得1張手牌",
["JiangeModeEvent4"] = "絕地反擊",
["JiangeModeEvent4text"] = "蜀國玩家額外獲得【反攻】技能。（當你成為一名敵方角色使用牌的目標後，則此牌結算完成後，你可以對其使用一張殺（無距離限制））；魏國玩家額外獲得【勵戰】技能。。",
["JiangeModeEvent5"] = "烈帝玄德",
["JiangeModeEvent5text"] = "英魂烈帝玄德必然參戰，且額外獲得【親陣】技能。",
["JiangeModeEvent6"] = "翊漢雲長",
["JiangeModeEvent6text"] = "英魂翊漢雲長必然參戰，且額外獲得【天將】技能。",
["JiangeModeEvent7"] = "扶危子龍",
["JiangeModeEvent7text"] = "英魂扶危子龍必然參戰，且額外獲得【龍威】技能。",
["JiangeModeEvent8"] = "佳人子丹",
["JiangeModeEvent8text"] = "英魂佳人子丹必然參戰，且額外獲得【鎮西】技能。",
["JiangeModeEvent9"] = "枯目元讓",
["JiangeModeEvent9text"] = "英魂枯目元讓必然參戰，且額外獲得【統軍】技能。",
["JiangeModeEvent10"] = "百計文遠",
["JiangeModeEvent10text"] = "英魂百計文遠必然參戰，且額外獲得【帥令】技能。",
["jgjixi"] = "急襲",
[":jgjixi"] = "你可以將一張錦囊牌當順手牽羊使用",
}

--重生：限定技，當你處於瀕死狀態時，你可以棄置所有判定區牌，然後復原你的武將牌，將手牌補充至手牌體力上限（至多為5），將體力回復至體力上限。

if not sgs.Sanguosha:getSkill("jgjixi") then skills:append(jgjixi) end
if not sgs.Sanguosha:getSkill("#nl_jiangebattle") then skills:append(nl_jiangebattle) end

--------------------------------------------------------------------------------------------

--[[
公会争霸赛

囚牛【qiú niú】
體力值： 3	 定位：輔助	 環境：天空

龍弦 ①每回合限一次，你可以將一張方片牌當【樂不思蜀】使用。②每回合限一次，若環境為天空，你可以將一張草花牌當【兵糧寸斷】使用（無距離限制）。
離歌 當一名角色的判定牌生效前，你可以打出一張牌替換之。
和鳴 鎖定技，當其他角色的某個階段開始前，若其跳過前一個階段，你令一名己方其他角色摸一張牌。
集律 鎖定技，己方其他角色的判定牌生效後，你獲得之。
]]--
dg_qiuniu = sgs.General(extension, "dg_qiuniu", "god", "6", true,true,true)

dg_longxian = sgs.CreateOneCardViewAsSkill{
	name = "dg_longxian",
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("dg_longxian1-Clear") == 0 and to_select:getSuit() == sgs_Suit_Diamond then
			return true
		end
		if sgs.Self:getMark("dg_longxian2-Clear") == 0 and sgs.Self:getMark("dg_enviroment") == 1 and to_select:getSuit() == sgs_Suit_Club then
			return true
		end
		return false
	end,
	view_as = function(self, card)
		if card:getSuit() == sgs_Suit_Diamond then
			local indulgence = sgs.Sanguosha:cloneCard("indulgence",card:getSuit(),card:getNumber())
			indulgence:addSubcard(card)
			indulgence:setSkillName(self:objectName())
			return indulgence
		elseif card:getSuit() == sgs_Suit_Club then
			local shortage = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
			shortage:setSkillName(self:objectName())
			shortage:addSubcard(card)
			return shortage
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("dg_longxian1-Clear") == 0 or (player:getMark("dg_longxian2-Clear") == 0 and player:getMark("dg_enviroment") == 1)
	end,
}

dg_longxianBuff = sgs.CreateTriggerSkill{
	name = "dg_longxianBuff",
	global = true,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		local card = data:toCardUse().card
		if card and card:getSkillName() == "dg_longxian" then
			if card:getSuit() == sgs_Suit_Diamond then
				room:setPlayerMark(player,"dg_longxian1-Clear",1)
			elseif card:getSuit() == sgs_Suit_Club then
				room:setPlayerMark(player,"dg_longxian2-Clear",1)
			end
		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("dg_longxianBuff") then skills:append(dg_longxianBuff) end 

dg_lige = sgs.CreateTriggerSkill{
	name = "dg_lige" ,
	events = {sgs.AskForRetrial} ,
	can_trigger = function(self, target)
		if not (target and target:isAlive() and target:hasSkill(self:objectName())) then return false end
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local prompt_list = {
			"@dg_lige-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			tostring(judge.card:getEffectiveId())
		}
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".", prompt, data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:retrial(card, player, judge, self:objectName(), true)
		end
		return false
	end
}

dg_heming = sgs.CreateTriggerSkill{
	name = "dg_heming",
	events = {sgs.EventPhaseSkipping},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Draw or player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_Discard or player:getPhase() == sgs.Player_Judge then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local _targets = sgs.SPlayerList()
				for _, pp in sgs.qlist(room:getOtherPlayers(player)) do
					if isSameTeam(player,pp) then _targets:append(pp) end
				end
				if not _targets:isEmpty() then
					local q = room:askForPlayerChosen(p, _targets, "dg_heming", "@dg_heming", true)
					if q then
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, p:objectName(), q:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							q:drawCards(1, self:objectName())
							room:removePlayerMark(p, self:objectName().."engine")
						end
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

dg_jilu = sgs.CreateTriggerSkill{
	name = "dg_jilu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if isSameTeam(player,p) then
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					p:obtainCard(card)
				end
			end
		end
	end, 
	can_trigger = function(self, target)
		return target
	end
}

dg_qiuniu:addSkill(dg_longxian)
dg_qiuniu:addSkill(dg_lige)
dg_qiuniu:addSkill(dg_heming)
dg_qiuniu:addSkill(dg_jilu)

sgs.LoadTranslationTable{
["dg_qiuniu"] = "囚牛",
["dg_longxian"] = "龍弦",
[":dg_longxian"] = "①每回合限一次，你可以將一張方片牌當【樂不思蜀】使用。②每回合限一次，若環境為天空，你可以將一張草花牌當【兵糧寸斷】使用（無距離限制）。",
["dg_lige"] = "離歌",
[":dg_lige"] = "當一名角色的判定牌生效前，你可以打出一張牌替換之。",
["@dg_lige-card"] = "請發動「%dest」來修改 %src 的「%arg」判定",
["~dg_lige"] = "選擇一張牌→點擊確定",
["dg_heming"] = "和鳴",
[":dg_heming"] = "鎖定技，當其他角色的某個階段開始前，若其跳過前一個階段，你令一名己方其他角色摸一張牌。",
["dg_jilu"] = "集律",
[":dg_jilu"] = "鎖定技，己方其他角色的判定牌生效後，你獲得之。",
}

--[[
負屓【fù xì】
體力值： 3	 定位：進攻	 環境：天空

龍識 ①其他角色的出牌階段限一次，其可以將一張普通錦囊牌(按照在其手牌里的牌名)扣置於你的武將牌上，稱為「碑文」，然後摸一張牌。②摸牌階段，你額外摸X張牌（X為「碑」的數目）。
靈碣 出牌階段，你可以將一張牌當一張「碑文」的普通錦囊牌使用（每種錦囊牌每回合限一次）。然後，若環境為天空，你摸一張牌。
斐章 當你於出牌階段內使用普通錦囊牌選擇目標後， 若你於此階段內未發動過此技能，你可以選擇額外一個其他角色也成為此牌的目標。
博文 摸牌階段，你可以棄置一張「碑文」。若如此做，你令額定手牌上限永久+1。
longzhi lingjie feizhang bowen	beiwen
]]--
dg_fuxi = sgs.General(extension, "dg_fuxi", "god", "6", true,true,true)

dg_longzhiCard = sgs.CreateSkillCard{
	name = "dg_longzhi_bill",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("dg_longzhi") and to_select:getMark("dg_longzhi_Play") == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "dg_longzhiengine")
		if source:getMark("dg_longzhiengine") > 0 then
			room:notifySkillInvoked(source, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(targets[1], "dg_longzhi_Play")
			targets[1]:addToPile("beiwen", self:getSubcards():first() )
			source:drawCards(1)
			room:removePlayerMark(source, "dg_longzhiengine")
		end
	end
}

dg_longzhiVS = sgs.CreateOneCardViewAsSkill{
	name = "dg_longzhi_bill&",
	view_filter = function(self, selected)
		return selected:isNDTrick()
	end,
	view_as = function(self,card)
		local skillcard = dg_longzhiCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return true
	end
}

dg_longzhi = sgs.CreateTriggerSkill{
	name="dg_longzhi",
	events = {sgs.GameStart, sgs.EventAcquireSkill,sgs.DrawNCards},
	on_trigger=function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event==sgs.GameStart then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:hasSkill("dg_longzhi_bill") then
					room:attachSkillToPlayer(p,"dg_longzhi_bill")
				end
			end
		elseif event == sgs.DrawNCards then
			local count = data:toInt() + player:getPile("beiwen"):length()
			data:setValue(count)
		end
	end
}

if not sgs.Sanguosha:getSkill("dg_longzhi_bill") then skills:append(dg_longzhiVS) end

--靈碣
function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end
function generateAllCardObjectNameTablePatterns()
	local patterns = {}
	for i = 0, 10000 do
		local card = sgs.Sanguosha:getEngineCard(i)
		if card == nil then break end
		if (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) and not table.contains(patterns, card:objectName()) then
			table.insert(patterns, card:objectName())
		end
	end
	return patterns
end
function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end
local pos = 0
dg_lingjie_select = sgs.CreateSkillCard{
	name = "dg_lingjie",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, id in sgs.qlist(source:getPile("beiwen")) do
			local card = sgs.Sanguosha:getCard(id)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("dg_lingjie"..card:objectName().."-Clear") == 0  and source:getMark("AG_BANCard"..card:objectName()) == 0 and (card:isKindOf("BasicCard") or card:isNDTrick()) then
					table.insert(choices, card:objectName())
				end
			end
		end
		
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "dg_lingjie", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
				if poi:targetFixed() then
					poi:setSkillName("dg_lingjie")
					poi:addSubcard(self:getSubcards():first())
					room:useCard(sgs.CardUseStruct(poi, source, source),true)
				else
					pos = getPos(patterns, pattern)
					room:setPlayerMark(source, "dg_lingjiepos", pos)
					room:setPlayerProperty(source, "dg_lingjie", sgs.QVariant(self:getSubcards():first()))
					room:askForUseCard(source, "@@dg_lingjie", "@dg_lingjie:"..pattern)--%src
				end
			end
		end
	end
}
dg_lingjieCard = sgs.CreateSkillCard{
	name = "dg_lingjieCard",
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
				if user:getMark("dg_lingjie"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(user, "dg_lingjie", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:addSubcard(self:getSubcards():first())
		use_card:setSkillName("dg_lingjie")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if card_use.from:getMark("dg_lingjie"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(card_use.from, "dg_lingjie", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("dg_lingjie")
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
dg_lingjieVS = sgs.CreateViewAsSkill{
	name = "dg_lingjie",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@dg_lingjie" then
			return false
		else return true end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = dg_lingjie_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			local acard = dg_lingjieCard:clone()
			if pattern and pattern == "@@dg_lingjie" then
				pattern = patterns[sgs.Self:getMark("dg_lingjiepos")]
				acard:addSubcard(sgs.Self:property("dg_lingjie"):toInt())
				if #cards ~= 0 then return end
			else
				if #cards ~= 1 then return end
				acard:addSubcard(cards[1]:getId())
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		local choices = {}
		for _, id in sgs.qlist(player:getPile("beiwen")) do
			local card = sgs.Sanguosha:getCard(id)
			local name = card:objectName()
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) and player:getMark("dg_lingjie"..name.."-Clear") == 0 then
				table.insert(choices, name)
			end
		end
		return next(choices) and player:getMark("dg_lingjie-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@dg_lingjie"
	end,
}
dg_lingjie = sgs.CreateTriggerSkill{
	name = "dg_lingjie",
	view_as_skill = dg_lingjieVS,
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished},
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
			if card and card:getHandlingMethod() == sgs.Card_MethodUse then
				if card:getSkillName() == "dg_lingjie" and player:getMark("dg_lingjie"..card:objectName().."-Clear") == 0 then
					room:addPlayerMark(player, "dg_lingjie"..card:objectName().."-Clear")
				end
				if player:getMark("dg_enviroment") == 1 then
					player:drawCards(1)
				end
			end
		end
	end
}

dg_feizhangCard = sgs.CreateSkillCard{
	name = "dg_feizhang",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("dg_feizhang_virtual_card") > 0 then
			local card_name
			local card_suit
			local card_number
			for _, mark in sgs.list(sgs.Self:getMarkNames()) do
				if string.find(mark, "dg_feizhang_virtual_card_name|") and sgs.Self:getMark(mark) > 0 then
					card_name = mark:split("|")[2]
					card_suit = mark:split("|")[4]
					card_number = mark:split("|")[6]
				end
			end
			local card = sgs.Sanguosha:cloneCard(card_name, card_suit, card_number)
			return #targets < 1 and to_select:getMark(self:objectName()) == 0 and card:targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
		end
		return #targets < 1 and to_select:getMark(self:objectName()) == 0 and sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")):targetFilter(sgs.PlayerList(), to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, sgs.Sanguosha:getCard(sgs.Self:getMark("card_id")))
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _, p in pairs(targets) do
				room:addPlayerMark(p, self:objectName())
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
dg_feizhangVS = sgs.CreateZeroCardViewAsSkill{
	name = "dg_feizhang",
	response_pattern = "@@dg_feizhang",
	view_as = function()
		return dg_feizhangCard:clone()
	end
}
dg_feizhang = sgs.CreateTriggerSkill{
	name = "dg_feizhang",
	events = {sgs.PreCardUsed},
	view_as_skill = dg_feizhangVS,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getMark("dg_feizhang-Clear") == 0 and player:getPhase() == sgs.Player_Play and (use.card:isNDTrick() and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification")) then
				room:addPlayerMark(player, "dg_feizhang-Clear")
				for _, p in sgs.qlist(use.to) do
					room:addPlayerMark(p, self:objectName())
				end
				if use.card:isVirtualCard() then
					room:setPlayerMark(player, "dg_feizhang_virtual_card", 1)
					room:setPlayerMark(player, "dg_feizhang_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 1)
					room:askForUseCard(player, "@@dg_feizhang", "@dg_feizhang")
					room:setPlayerMark(player, "dg_feizhang_virtual_card", 0)
					room:setPlayerMark(player, "dg_feizhang_virtual_card_name|"..use.card:objectName().."|suit|"..use.card:getSuit().."|number|"..use.card:getNumber(), 0)
				elseif not use.card:isVirtualCard() then
					room:setPlayerMark(player, "dg_feizhang_not_virtual_card", 1)
					room:setPlayerMark(player, "card_id", use.card:getEffectiveId())
					room:askForUseCard(player, "@@dg_feizhang", "@dg_feizhang")
					room:setPlayerMark(player, "dg_feizhang_not_virtual_card", 0)
					room:setPlayerMark(player, "card_id", 0)
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark(self:objectName()) > 0 and not room:isProhibited(player, p, use.card) then
						room:removePlayerMark(p, self:objectName())
						if not use.to:contains(p) then
							use.to:append(p)
						end
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
	end,
}

dg_bowenCard = sgs.CreateSkillCard{
	name = "dg_bowen",
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:addPlayerMark(source, "@Maxcards")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end,
}
dg_bowenVS = sgs.CreateOneCardViewAsSkill{
	name = "dg_bowen", 
	response_pattern = "@@dg_bowen",
	filter_pattern = ".|.|.|beiwen",
	expand_pile = "beiwen",
	view_as = function(self, card)
		local kf = dg_bowenCard:clone()
		kf:addSubcard(card)
		return kf
	end,
}


dg_bowen = sgs.CreateTriggerSkill{
	name = "dg_bowen",
	global = true,
	view_as_skill = dg_bowenVS,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Draw and player:getPile("beiwen"):length() > 0 then
			room:askForUseCard(player, "@@dg_bowen", "@dg_bowen-card", -1, sgs.Card_MethodNone)
		end
		return false
	end
}

dg_fuxi:addSkill(dg_longzhi)
dg_fuxi:addSkill(dg_lingjie)
dg_fuxi:addSkill(dg_feizhang)
dg_fuxi:addSkill(dg_bowen)

sgs.LoadTranslationTable{
["dg_fuxi"] = "負屓",
["@dg_longzhi1"] = "是否對 %src 發動龍識？",
["dg_longzhi"] = "龍識",
["dg_longzhi_bill"] = "龍識",
[":dg_longzhi"] = "①其他角色的出牌階段限一次，其可以將一張普通錦囊牌(按照在其手牌里的牌名)扣置於你的武將牌上，稱為「碑文」，然後摸一張牌。②摸牌階段，你額外摸X張牌（X為「碑」的數目）。",
["beiwen"] = "碑文",
["dg_lingjie"] = "靈碣",
[":dg_lingjie"] = "出牌階段，你可以將一張牌當一張「碑文」的普通錦囊牌使用（每種錦囊牌每回合限一次）。然後，若環境為天空，你摸一張牌。",
["dg_feizhang"] = "斐章",
[":dg_feizhang"] = "當你於出牌階段內使用普通錦囊牌選擇目標後， 若你於此階段內未發動過此技能，你可以選擇額外一個其他角色也成為此牌的目標。",
["@dg_feizhang"] = "你可以發動“斐章”",
["~dg_feizhang"] = "選擇目標角色→點“確定”",
["dg_bowen"] = "博文",
[":dg_bowen"] = "摸牌階段，你可以棄置一張「碑文」。若如此做，你令額定手牌上限永久+1。",
["@dg_bowen-card"] = "你可以棄置一張「碑文」令額定手牌上限永久+1",
}


--[[
嘲風【cháo fēng】
體力值： 3	 定位：防禦	 環境：天空

龍鱗 出牌階段限一次，你可以展示你手牌區里的一張防具牌。若如此做，所有己方角色回復1點體力。然後，若環境為天空，所有己方角色的防具區隨機置入一張防具牌
置角 出牌階段，你可以將一張坐騎牌置入一名己方角色的裝備區里。若如此做，你和目標角色隨機獲得一張紅色牌（如果目標是自己，獲得兩張）。
止邪 當一名其他角色的回合結束時，若其於此回合內未造成過傷害，你可以獲得場上裝備區的一張裝備牌。
好險 鎖定技，結束階段開始時，若敵方所有角色裝備區內的牌數總和大於等於4 ，你令所有敵方角色依次將其裝備區里的所有牌一次性置入棄牌堆，然後你摸X張牌（X為所有以此法置入棄牌堆的牌數）。
 longlin zhijiao zhixie haoxian
]]--
dg_chaofeng = sgs.General(extension, "dg_chaofeng", "god", "6", true,true,true)

dg_longlinCard = sgs.CreateSkillCard{
	name = "dg_longlin",
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:showCard(source, self:getSubcards():first())

			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if isSameTeam(source,p) then
					room:recover(p, sgs.RecoverStruct(source, nil, 1))
				end
			end
			if source:getMark("dg_enviroment") == 1 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if isSameTeam(source,p) and not p:getArmor() and p:getMark("@AbolishArmor") == 0 then
						local equips = sgs.CardList()
						for _, id in sgs.qlist(room:getDrawPile()) do
							if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
								equips:append(sgs.Sanguosha:getCard(id))
							end
						end
						for _, id in sgs.qlist(room:getDiscardPile()) do
							if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
								equips:append(sgs.Sanguosha:getCard(id))
							end
						end
						if not equips:isEmpty() then
							local card = equips:at(math.random(0, equips:length() - 1))
							room:useCard(sgs.CardUseStruct(card, p,p))
						end
					end
				end
			end


			room:removePlayerMark(source, self:objectName().."engine")
		end
	end,
}
dg_longlin = sgs.CreateOneCardViewAsSkill{
	name = "dg_longlin", 
	view_filter = function(self, card)
		return not card:isEquipped() and card:isKindOf("Armor")
	end,
	view_as = function(self, card)
		local kf = dg_longlinCard:clone()
		kf:addSubcard(card)
		return kf
	end,
	enabled_at_play = function(self, player)
		return not self.player:hasUsed("#dg_longlin")
	end
}

function getcolorcard(player, color,from_drawpile,from_discardpile)
	local room = player:getRoom()
	local GetCardList = sgs.IntList()
		local DPHeart = sgs.IntList()
		if room:getDrawPile():length() > 0 and from_drawpile then
			for _, id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if GetColor(card) == color then
					DPHeart:append(id)
				end
			end
		end
		if room:getDiscardPile():length() > 0 and from_discardpile then
			for _, id in sgs.qlist(room:getDiscardPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if GetColor(card) == color then
					DPHeart:append(id)
				end
			end
		end
		if DPHeart:length() > 0 then
			local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
			GetCardList:append(get_id)
			local card = sgs.Sanguosha:getCard(get_id)
		end

	if GetCardList:length() ~= 0 then
		local move = sgs.CardsMoveStruct()
		move.card_ids = GetCardList
		move.to = player
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move, true)
	end
end

dg_zhijiaoCard = sgs.CreateSkillCard{
	name = "dg_zhijiao",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, erzhang)
		if #targets ~= 0 then return false end
		if not isSameTeam(to_select,erzhang) then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	on_effect = function(self, effect)
		local erzhang = effect.from
		erzhang:getRoom():moveCardTo(self, erzhang, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, erzhang:objectName(), "zhijian", ""))
		getcolorcard(erzhang,"red",true,false)
		getcolorcard(effect.to,"red",true,false)
	end
}
dg_zhijiao = sgs.CreateOneCardViewAsSkill{
	name = "dg_zhijiao",	
	view_filter = function(self, card)
		return not card:isEquipped() and (card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse"))
	end,
	view_as = function(self, card)
		local zhijian_card = dg_zhijiaoCard:clone()
		zhijian_card:addSubcard(card)
		zhijian_card:setSkillName(self:objectName())
		return zhijian_card
	end
}

--止邪(修改自 dg_zhixie )
dg_zhixieCard = sgs.CreateSkillCard{
	name = "dg_zhixie",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:getEquips():isEmpty() and sgs.Self:canDiscard(to_select, "e")
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local id = room:askForCardChosen(effect.from, effect.to, "e", self:objectName(), false, sgs.Card_MethodDiscard)
			room:obtainCard(effect.from, id)
		end
	end
}
dg_zhixieVS = sgs.CreateZeroCardViewAsSkill{
	name = "dg_zhixie",
	view_as = function()
		return dg_zhixieCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@dg_zhixie"
	end
}
dg_zhixie = sgs.CreateTriggerSkill{
	name = "dg_zhixie",
	view_as_skill = dg_zhixieVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local invoke = false
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if not p:getEquips():isEmpty() then
				invoke = true
			end
		end
		if player:getPhase() == sgs.Player_Finish and player:getMark("damage_point_round") == 0 and invoke then
			for _, p in sgs.qlist(room:findPlayersBySkillName("xionghuo")) do
				if p:objectName() ~= player:objectName() then	
					room:askForUseCard(p, "@dg_zhixie", "@dg_zhixie")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

--好險
dg_haoxian = sgs.CreateTriggerSkill{
	name = "dg_haoxian" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() ==  sgs.Player_Finish then
			local ids = sgs.IntList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not isSameTeam(p,player) then
					for _, card in sgs.qlist(p:getEquips()) do
						ids:append(card:getEffectiveId())
					end
				end
			end
			if ids:length() >= 4 then
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil, "dg_haoxian", nil)
				room:moveCardsAtomic(move, true)
			end
		end
	end
}

dg_chaofeng:addSkill(dg_longlin)
dg_chaofeng:addSkill(dg_zhijiao)
dg_chaofeng:addSkill(dg_zhixie)
dg_chaofeng:addSkill(dg_haoxian)

sgs.LoadTranslationTable{
["dg_chaofeng"] = "嘲風",
["dg_longlin"] = "龍鱗",
[":dg_longlin"] = "出牌階段限一次，你可以展示你手牌區里的一張防具牌。若如此做，所有己方角色回復1點體力。然後，若環境為天空，所有己方角色的防具區隨機置入一張防具牌。",
["dg_zhijiao"] = "置角",
[":dg_zhijiao"] = "出牌階段，你可以將一張坐騎牌置入一名己方角色的裝備區里。若如此做，你和目標角色隨機獲得一張紅色牌（如果目標是自己，獲得兩張）。",
["dg_zhixie"] = "止邪",
[":dg_zhixie"] = "當一名其他角色的回合結束時，若其於此回合內未造成過傷害，你可以獲得場上裝備區的一張裝備牌。",
["@dg_zhixie"] = "你可以發動“止邪”",
["~dg_zhixie"] = "選擇一名有裝備牌的角色→點擊確定",
["dg_haoxian"] = "好險",
[":dg_haoxian"] = "鎖定技，結束階段開始時，若敵方所有角色裝備區內的牌數總和大於等於4 ，你令所有敵方角色依次將其裝備區里的所有牌一次性置入棄牌堆，然後你摸X張牌（X為所有以此法置入棄牌堆的牌數）。",
}

--[[
螭吻【chī wěn】
體力值： 3	 定位：輔助	 環境：海洋

龍鰲  鎖定技，當己方其他角色受到屬性傷害時，若環境：不為海洋，你令此傷害-1；為海洋，你令此傷害-2。
驅炎  鎖定技，若環境不為海洋，你造成的屬性傷害+1。 若環境為海洋，則你令己方其他角色造成的屬性傷害+1。
魚火  ①你可以將一張方片手牌當火【殺】使用。②你可以將一張黑桃手牌當【鐵索連環】使用。
負兵  鎖定技，出牌階段開始時，你令隨機一名對方角色的武將牌橫置，（前後無因果關係）然後令隨機一名己方角色的武將牌重置。
longao quyan yuhuo fubing
]]--
dg_chiwen = sgs.General(extension, "dg_chiwen", "god", "6", true,true,true)

dg_longao = sgs.CreateTriggerSkill{
	name = "dg_longao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local invoke = false
			local has_skill_player
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if isSameTeam(p,player) then
					if p:hasSkill("dg_longao") then
						invoke = true
						has_skill_player = p
						break
					end
				end
			end
			if invoke and damage.nature ~= sgs.DamageStruct_Normal then
				room:notifySkillInvoked(has_skill_player, self:objectName())
				room:sendCompulsoryTriggerLog(has_skill_player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				local n = 1
				if player:getMark("dg_enviroment") == 2 then
					n = 2
				end
				local log = sgs.LogMessage()
				log.type = "#JieyuanDecrease"
				log.from = player
				log.arg = damage.damage
				log.arg2 = math.max(0,damage.damage - n)
				room:sendLog(log)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					damage.damage = damage.damage - n
					data:setValue(damage)
					if damage.damage < 1 then
						return true
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

dg_quyan = sgs.CreateTriggerSkill{
	name = "dg_quyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local invoke = false
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if isSameTeam(p,player) then
					if p:hasSkill("dg_quyan") and player:getMark("dg_enviroment") == 2 then
						invoke = true
					end
				end
			end
			if p:objectName() == player:objectName() then
				invoke = true
			end
			if invoke and damage.nature ~= sgs.DamageStruct_Normal then
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				local log = sgs.LogMessage()
				log.type = "#JieyuanIncrease"
				log.from = player
				log.arg = damage.damage
				log.arg2 = damage.damage + 1
				room:sendLog(log)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					damage.damage = damage.damage + 1
					data:setValue(damage)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

dg_yuhuo = sgs.CreateViewAsSkill{
	name = "dg_yuhuo",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Slash_IsAvailable(sgs.Self) and (to_select:getSuit() == sgs.Card_Diamond) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
			return false
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
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
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
	end,
}

dg_fubing = sgs.CreateTriggerSkill{
	name = "dg_fubing" ,
	frequency = sgs.Skill_Compulsory ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() ==  sgs.Player_Play then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke(self:objectName())
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not isSameTeam(p,player) and not p:isChained() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local pp = players:at(math.random(1,players:length())-1)
				room:doAnimate(1, player:objectName(), pp:objectName())
				room:setPlayerProperty(pp, "chained", sgs.QVariant(true))
			end

			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if isSameTeam(p,player) and p:isChained() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local pp = players:at(math.random(1,players:length())-1)
				room:doAnimate(1, player:objectName(), pp:objectName())
				room:setPlayerProperty(pp, "chained", sgs.QVariant(false))
			end
		end
	end
}

dg_chiwen:addSkill(dg_longao)
dg_chiwen:addSkill(dg_quyan)
dg_chiwen:addSkill(dg_yuhuo)
dg_chiwen:addSkill(dg_fubing)

sgs.LoadTranslationTable{
["dg_chiwen"] = "螭吻",
["dg_longao"] = "龍鰲",
[":dg_longao"] = "鎖定技，當己方其他角色受到屬性傷害時，若環境：不為海洋，你令此傷害-1；為海洋，你令此傷害-2。",
["dg_quyan"] = "驅炎",
[":dg_quyan"] = "鎖定技，若環境不為海洋，你造成的屬性傷害+1。 若環境為海洋，則你令己方其他角色造成的屬性傷害+1。",
["dg_yuhuo"] = "魚火",
[":dg_yuhuo"] = "①你可以將一張方片手牌當火【殺】使用。②你可以將一張黑桃手牌當【鐵索連環】使用。",
["dg_fubing"] = "負兵",
[":dg_fubing"] = "鎖定技，出牌階段開始時，你令隨機一名對方角色的武將牌橫置，（前後無因果關係）然後令隨機一名己方角色的武將牌重置。",
}

--[[
蒲牢【pú láo】
體力值： 3	 定位：進攻	 環境：海洋

龍吼 鎖定技，回合結束時，你視為使用一張【萬箭齊發】。
怯鯨	  鎖定技，當一名角色使用牌指定超過一個目標後，若環境：不為海洋，你棄置一張牌，然後摸一張牌；為海洋，你棄置一張牌，然後對一名敵方角色造成一點傷害。
鳴音	  鎖定技，你造成的傷害視為體力流失。
獨遠	  鎖定技，己方角色不是你使用基本牌和錦囊牌的合法目標。你的出牌階段內，你造成的所有傷害的傷害值基數均+1。（注：不能給自己/己方出桃、無中、桃園）
longhou quejing mingyin duyuan
]]--
dg_pulao = sgs.General(extension, "dg_pulao", "god", "6", true,true,true)

dg_longhou = sgs.CreateTriggerSkill{
	name = "dg_longhou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local players = sgs.SPlayerList()
				local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if not player:isProhibited(p, savage_assault) then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())

					savage_assault:setSkillName("dg_longhou")
					local use = sgs.CardUseStruct()
					use.card = savage_assault
					use.from = player
					for _,p in sgs.qlist(players) do
						use.to:append(p)
					end
					room:useCard(use)				
				end
			end		
		end
	end,
}

dg_quejing = sgs.CreateTriggerSkill{
	name = "dg_quejing" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("SkillCard") and use.to:length() > 1 then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:notifySkillInvoked(p, self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					room:askForDiscard(p, self:objectName(), 1,1, false, true)

					if player:getMark("dg_enviroment") == 2 then
						local players = sgs.SPlayerList()
						for _, pp in sgs.qlist(room:getOtherPlayers(p)) do
							if not isSameTeam(p,pp) then
								players:append(pp)
							end
						end
						if not players:isEmpty() then
							local d_target = room:askForPlayerChosen(p, room:getAlivePlayers(), "shenfu", "@shenfu-damage", true)
							if d_target then
								room:doAnimate(1, p:objectName(), d_target:objectName())
								room:damage(sgs.DamageStruct("dg_quejing", p, d_target, 1, sgs.DamageStruct_Normal))
							end
						end
					else
						p:drawCards(1)
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

dg_mingyin = sgs.CreateTriggerSkill{
	name = "dg_mingyin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		room:notifySkillInvoked(player, self:objectName())
		room:sendCompulsoryTriggerLog(player, self:objectName()) 
		room:broadcastSkillInvoke(self:objectName())
		room:loseHp(damage.to, damage.damage)
		return true
	end,
}

dg_duyuan = sgs.CreateTriggerSkill{
	name = "dg_duyuan" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if player:getPhase() == sgs.Player_Play then
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#Liegong2"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)	
				data:setValue(damage)
			end
		end
	end
}

dg_duyuanban = sgs.CreateProhibitSkill{
	name = "#dg_duyuanban",
	is_prohibited = function(self, from, to, card)
		return (from:hasSkill("dg_duyuan")) and not card:isKindOf("SkillCard") and isSameTeam(from,to)
	end
}

dg_pulao:addSkill(dg_longhou)
dg_pulao:addSkill(dg_quejing)
dg_pulao:addSkill(dg_mingyin)
dg_pulao:addSkill(dg_duyuan)
dg_pulao:addSkill(dg_duyuanban)

sgs.LoadTranslationTable{
["dg_pulao"] = "蒲牢",
["dg_longhou"] = "龍吼",
[":dg_longhou"] = "鎖定技，回合結束時，你視為使用一張【萬箭齊發】。",
["dg_quejing"] = "怯鯨",
[":dg_quejing"] = "鎖定技，當一名角色使用牌指定超過一個目標後，若環境：不為海洋，你棄置一張牌，然後摸一張牌；為海洋，你棄置一張牌，然後對一名敵方角色造成一點傷害。",
["dg_mingyin"] = "鳴音",
[":dg_mingyin"] = "鎖定技，你造成的傷害視為體力流失。",
["dg_duyuan"] = "獨遠",
["#dg_duyuanban"] = "獨遠",
[":dg_duyuan"] = "鎖定技，己方角色不是你使用基本牌和錦囊牌的合法目標。你的出牌階段內，你造成的所有傷害的傷害值基數均+1。（注：不能給自己/己方出桃、無中、桃園）",
}

--[[
贔屓【bì xì】
體力值： 3	 定位：防禦	 環境：海洋

龍玄 ①摸牌階段，你令額定摸牌數-1。②其他角色的出牌階段限一次，其可以將一張錦囊牌扣置於你的武將牌上，稱為「碑銘」，然後其回復1點體力，你的體力上限+1。③你的手牌上限-X，（X為「碑」的數目）。  
靈屓 鎖定技，當你受到一點傷害後，若你的武將牌上有「碑銘」，你將一張「碑銘」置入棄牌堆，你的體力上限-1，然後令所有己方角色各摸一張牌；若環境為海洋，改為摸二張牌。
疏流 鎖定技，每回合限一次，當你使用的普通錦囊牌結算結束後，你將此牌當作「碑銘」，扣置於你的武將牌上，然後你的體力上限+1。
介怒 鎖定技，出牌階段開始時，如果你的「碑銘」大於等於7，你回復X點體力，然後對自己造成X點傷害（X=碑銘數）。（觸發靈屓）
longxuan lingxi shuliu jienu	beiming
]]--
dg_bixi = sgs.General(extension, "dg_bixi", "god", "6", true,true,true)

dg_longxuanCard = sgs.CreateSkillCard{
	name = "dg_longxuan_bill",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("dg_longxuan") and to_select:getMark("dg_longxuan_Play") == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "dg_longxuanengine")
		if source:getMark("dg_longxuanengine") > 0 then
			room:notifySkillInvoked(source, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(targets[1], "dg_longxuan_Play")
			targets[1]:addToPile("beiming", self )
			room:setPlayerProperty(targets[1], "maxhp", sgs.QVariant(targets[1]:getMaxHp() + 1))
			local msg = sgs.LogMessage()
			msg.type = "#GainMaxHp"
			msg.from = targets[1]
			msg.arg = 1
			room:sendLog(msg)
			room:recover(source, sgs.RecoverStruct(source, nil, 1))
			room:removePlayerMark(source, "dg_longxuanengine")
		end
	end
}

dg_longxuanVS = sgs.CreateOneCardViewAsSkill{
	name = "dg_longxuan_bill&",
	view_filter = function(self, selected)
		return selected:isKindOf("TrickCard")
	end,
	view_as = function(self,card)
		local skillcard = dg_longxuanCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return true
	end
}

dg_longxuan = sgs.CreateTriggerSkill{
	name="dg_longxuan",
	events = {sgs.GameStart, sgs.EventAcquireSkill,sgs.DrawNCards},
	on_trigger=function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event == sgs.GameStart then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:hasSkill("dg_longxuan_bill") then
					room:attachSkillToPlayer(p,"dg_longxuan_bill")
				end
			end
		elseif event == sgs.DrawNCards then
			local count = data:toInt() - 1
			data:setValue(count)
		end
	end
}

if not sgs.Sanguosha:getSkill("dg_longxuan_bill") then skills:append(dg_longxuanVS) end

dg_lingxi = sgs.CreateMasochismSkill{
	name = "dg_lingxi",
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			if player:getPile("beiming"):length() > 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:throwCard(sgs.Sanguosha:getCard(player:getPile("beiming"):first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", player:objectName(), self:objectName(), ""), nil)
				room:loseMaxHp(player)
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if isSameTeam(p,player) then
						room:doAnimate(1, player:objectName(), p:objectName())
						if player:getMark("dg_enviroment") == 2 then
							p:drawCards(2)
						else
							p:drawCards(1)
						end
					end
				end
			end
		end
	end
}

dg_shuliu = sgs.CreateTriggerSkill{
	name = "dg_shuliu", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardFinished},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() then
			local id = use.card:getEffectiveId()
			--if room:getCardPlace(id) == sgs.Player_PlaceTable and player:getMark("dg_jienu-Clear") == 0 then
			if player:getMark("dg_jienu-Clear") == 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())

				room:addPlayerMark(player,"dg_jienu-Clear")
				player:addToPile("beiming", use.card )
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
				local msg = sgs.LogMessage()
				msg.type = "#GainMaxHp"
				msg.from = player
				msg.arg = 1
				room:sendLog(msg)
			end
		end
		return false
	end, 
}

dg_jienu = sgs.CreateTriggerSkill{
	name = "dg_jienu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if player:getPile("beiming"):length() >= 7 then
					room:notifySkillInvoked(player, self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName()) 
					room:broadcastSkillInvoke(self:objectName())
					local n = player:getPile("beiming")
					room:recover(player, sgs.RecoverStruct(player, nil, n))
					room:damage(sgs.DamageStruct(self:objectName(), player, player, n))
				end
			end		
		end
	end,
}

dg_bixi:addSkill(dg_longxuan)
dg_bixi:addSkill(dg_lingxi)
dg_bixi:addSkill(dg_shuliu)
dg_bixi:addSkill(dg_jienu)

sgs.LoadTranslationTable{
["dg_bixi"] = "贔屓",
["dg_longxuan"] = "龍玄",
["dg_longxuan_bill"] = "龍玄",
[":dg_longxuan"] = "①摸牌階段，你令額定摸牌數-1。②其他角色的出牌階段限一次，其可以將一張錦囊牌扣置於你的武將牌上，稱為「碑銘」，然後其回復1點體力，你的體力上限+1。③你的手牌上限-X，（X為「碑」的數目）。  ",
["dg_lingxi"] = "怯鯨",
[":dg_lingxi"] = "鎖定技，當你受到一點傷害後，若你的武將牌上有「碑銘」，你將一張「碑銘」置入棄牌堆，你的體力上限-1，然後令所有己方角色各摸一張牌；若環境為海洋，改為摸二張牌。",
["dg_shuliu"] = "疏流",
[":dg_shuliu"] = "鎖定技，每回合限一次，當你使用的普通錦囊牌結算結束後，你將此牌當作「碑銘」，扣置於你的武將牌上，然後你的體力上限+1。",
["dg_jienu"] = "介怒",
[":dg_jienu"] = "鎖定技，出牌階段開始時，如果你的「碑銘」大於等於7，你回復X點體力，然後對自己造成X點傷害（X=碑銘數）。（觸發靈屓）",
["beiming"] = "碑銘",
}

--[[
狻猊【suān ní】
體力值： 3	 定位：輔助	 環境：陸地

龍鎮  鎖定技，每回合限一次，當其他己方角色於其回合外獲得牌時，你令其摸兩張牌。
瑞煙  鎖定技，結束階段開始時，若環境：不為陸地，你摸一張牌。為陸地，你摸三張牌。
繞稜  出牌階段限兩次，你可以將一張手牌交給一名其他己方角色。
香金  出牌階段限一次，你可以令一名與你手牌數不同的其他角色將手牌摸或棄置至與你的手牌數相同。
longzhen ruiyan raoleng xiangjin
]]--
dg_suanni = sgs.General(extension, "dg_suanni", "god", "6", true,true,true)

dg_longzhen = sgs.CreateTriggerSkill{
	name = "dg_longzhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if event == sgs.CardsMoveOneTime and not room:getTag("FirstRound"):toBool() and move.to and player:hasSkill(self:objectName()) then
			for _, p in sgs.qlist(room:getOtherPlayer(player)) do
				if p:getPhase() == sgs.Player_NotActive and isSameTeam(p,player) and player:getMark("dg_longzhen-Clear") == 0 and move.to:objectName() == p:objectName() then
					for _,id in sgs.qlist(move.card_ids) do
						if room:getCardOwner(id):objectName() == p:objectName() and room:getCardPlace(id) == sgs.Player_PlaceHand then
							SendComLog(self, p, 1)
							room:addPlayerMark(player, "dg_longzhen-Clear")
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								p:drawCards(2, self:objectName())
								room:removePlayerMark(player, self:objectName().."engine")
								break
							end
						end
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

dg_ruiyan = sgs.CreatePhaseChangeSkill{
	name = "dg_ruiyan",
	frequency = sgs.Skill_Compulsory,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			room:notifySkillInvoked(player,"dg_ruiyan")
			if player:getMark("dg_enviroment") == 3 then
				player:drawCards(2, self:objectName())
			else
				player:drawCards(1, self:objectName())
			end
		end
		return false
	end
}

dg_raolengCard = sgs.CreateSkillCard{
	name = "dg_raoleng",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName() and isSameTeam(to_select,sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "dg_raoleng", "")
			room:obtainCard(targets[1], self, reason, false)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
dg_raoleng = sgs.CreateViewAsSkill{
	name = "dg_raoleng",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = dg_raolengCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#dg_raoleng") < 2 and not player:isKongcheng()
	end
}

dg_xiangjinCard = sgs.CreateSkillCard{
	name = "dg_xiangjin",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local n = source:getHandcardNum() - targets[1]:getHandcardNum()
			if n < 0 then
				room:askForDiscard(targets[1], self:objectName(), -n, -n, false, false)
			elseif n > 0 then
				targets[1]:drawCards(n, self:objectName())
			end
		end
	end
}
dg_xiangjin = sgs.CreateViewAsSkill{
	name = "dg_xiangjin", 
	n = 0, 
	view_as = function(self, cards) 
		return dg_xiangjinCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#dg_xiangjin")
	end
}

dg_suanni:addSkill(dg_longzhen)
dg_suanni:addSkill(dg_ruiyan)
dg_suanni:addSkill(dg_raoleng)
dg_suanni:addSkill(dg_xiangjin)

sgs.LoadTranslationTable{
["dg_suanni"] = "狻猊",
["dg_longzhen"] = "龍鎮",
[":dg_longzhen"] = "鎖定技，每回合限一次，當其他己方角色於其回合外獲得牌時，你令其摸兩張牌。",
["dg_ruiyan"] = "瑞煙",
[":dg_ruiyan"] = "鎖定技，結束階段開始時，若環境：不為陸地，你摸一張牌。為陸地，你摸三張牌。",
["dg_raoleng"] = "繞稜",
[":dg_raoleng"] = "出牌階段限兩次，你可以將一張手牌交給一名其他己方角色。",
["dg_xiangjin"] = "香金",
[":dg_xiangjin"] = "出牌階段限一次，你可以令一名與你手牌數不同的其他角色將手牌摸或棄置至與你的手牌數相同。",
}

--[[
睚眥【yá zì】
體力值： 3	 定位：進攻	 環境：陸地

龍烈  鎖定技，當你使用的【殺】指定目標後，若環境不為陸地，你令此【殺】不能被同顏色的【閃】響應；若環境為陸地，你令此【殺】不能被【閃】響應。
豺月  ①鎖定技，你使用的【殺】的目標始終為敵方所有角色。
狼日  鎖定技，你使用【殺】無距離限制。若環境為陸地，你使用【殺】無視防具。
必報  鎖定技，回合開始時，你失去1點體力，視為你對敵方隨機一名角色使用一張【殺】。
longlie chaiyue langri bibao
]]--
dg_yazi = sgs.General(extension, "dg_yazi", "god", "6", true,true,true)

dg_longlie = sgs.CreateTriggerSkill{
	name = "dg_longlie",
	events = {sgs.TargetSpecified,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and not use.card:isKindOf("SkillCard") and use.card:isKindOf("Slash") then
				if player:getMark("dg_enviroment") == 3 then
					local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
					local index = 1
					for _, p in sgs.qlist(use.to) do
						local _data = sgs.QVariant()
						_data:setValue(p)
						jink_table[index] = 0
						index = index + 1
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					player:setTag("Jink_"..use.card:toString(), jink_data)
				--else
				--	room:setCardFlag(use.card, "wenji")
				end
			else
				for _, p in sgs.qlist(use.to) do
					room:setPlayerCardLimitation(p, "use, response", "Jink|"..GetColor(use.card), true)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and not use.card:isKindOf("SkillCard") and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					room:removePlayerCardLimitation(p, "use, response", "Jink|"..GetColor(use.card).."$0")
				end
			end
		end
	end
}

dg_chaiyue = sgs.CreateTriggerSkill{
	name = "dg_chaiyue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (not use.to:contains(p)) and not isSameTeam(p,player) and (not room:isProhibited(player, p, use.card)) then
						use.to:append(p)
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
		return false
	end,
}

dg_langritm = sgs.CreateTargetModSkill{
	name = "#dg_langri",
	pattern = "Slash" ,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("dg_langri") and card:isKindOf("Slash") then
			return 1000
		else
			return 0
		end
	end,
}

dg_langri = sgs.CreateTriggerSkill{
	name = "dg_langri",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	priority = -200,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and player:getMark("dg_enviroment") == 3 then
			for _, p in sgs.qlist(use.to) do
				p:addQinggangTag(slash)
			end
		end
	end
}

dg_bibao = sgs.CreateTriggerSkill{
	name = "dg_bibao",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not isSameTeam(p,player) and player:canSlash(p, nil, false) then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				room:loseHp(player,1)
				local pp = players:at(math.random(1,players:length())-1)
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("dg_bibao")
				room:useCard(sgs.CardUseStruct(slash, player, pp))
			end
		end
		return false
	end
}

dg_yazi:addSkill(dg_longlie)
dg_yazi:addSkill(dg_chaiyue)
dg_yazi:addSkill(dg_langri)
dg_yazi:addSkill(dg_langritm)
dg_yazi:addSkill(dg_bibao)

sgs.LoadTranslationTable{
["dg_yazi"] = "睚眥",
["dg_longlie"] = "龍烈",
[":dg_longlie"] = "鎖定技，當你使用的【殺】指定目標後，若環境不為陸地，你令此【殺】不能被同顏色的【閃】響應；若環境為陸地，你令此【殺】不能被【閃】響應。",
["dg_chaiyue"] = "豺月",
[":dg_chaiyue"] = "①鎖定技，你使用的【殺】的目標始終為敵方所有角色。",
["dg_langri"] = "龍烈",
[":dg_langri"] = "鎖定技，你使用【殺】無距離限制。若環境為陸地，你使用【殺】無視防具。",
["dg_bibao"] = "必報",
[":dg_bibao"] = "鎖定技，回合開始時，你失去1點體力，視為你對敵方隨機一名角色使用一張【殺】。",
}

--[[
狴犴【bì àn】
體力值： 3	 定位：防禦	 環境：陸地

龍視 鎖定技，每回合限一次，當非神獸的其他角色成為基本牌的目標後，其摸一張牌。若為陸地，所有己方其他角色各摸一張牌。
訟言 鎖定技，每回合限一次，當非神獸的其他角色成為普通錦囊牌的目標後，其摸一張牌。若為陸地，所有己方其他角色各摸一張牌。
肅威 鎖定技，當你成為一名對方角色於其回合內使用的牌的目標後，你棄置其一張手牌。
畫牢 鎖定技， 如果己方其他角色總體力值小於等於3，己方其他角色不是敵方角色使用牌的合法目標。
longshi songyan suwei hualao
]]--
dg_bian = sgs.General(extension, "dg_bian", "god", "6", true,true,true)

dg_longshi = sgs.CreateTriggerSkill{
	name = "dg_longshi" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.card:isKindOf("BasicCard") and not string.startsWith(player:getGeneralName(),"dg_") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("dg_longshi") and p:getMark("dg_longshi-Clear") == 0 then
						room:addPlayerMark(p,"dg_longshi-Clear")
						room:doAnimate(1, p:objectName(), player:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1)
						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							if isSameTeam(p,pp) then
								room:doAnimate(1, p:objectName(), pp:objectName())
							end
						end
						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							if isSameTeam(p,pp) then
								pp:drawCards(1)
							end
						end
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

dg_songyan = sgs.CreateTriggerSkill{
	name = "dg_songyan" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.card:isNDTrick() and not string.startsWith(player:getGeneralName(),"dg_") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("dg_songyan") and p:getMark("dg_songyan-Clear") == 0 then
						room:addPlayerMark(p,"dg_songyan-Clear")
						room:doAnimate(1, p:objectName(), player:objectName())
						room:notifySkillInvoked(p, self:objectName())
						room:sendCompulsoryTriggerLog(p, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1)
						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							if isSameTeam(p,pp) then
								room:doAnimate(1, p:objectName(), pp:objectName())
							end
						end
						for _, pp in sgs.qlist(room:getAlivePlayers()) do
							if isSameTeam(p,pp) then
								pp:drawCards(1)
							end
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

dg_suwei = sgs.CreateTriggerSkill{
	name = "dg_suwei" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and not use.card:isKindOf("SkillCard") then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				if player:canDiscard(use.from, "h") then
					local id = room:askForCardChosen(player, use.from, "h", self:objectName(), false, sgs.Card_MethodDiscard)
					if id ~= -1 then
						room:throwCard(sgs.Sanguosha:getCard(id), use.from, player)
					end
				end
			end
		end
		return false
	end
}

dg_hualao = sgs.CreateProhibitSkill{
	name = "dg_hualao" ,
	is_prohibited = function(self, from, to, card)
		if not card:isKindOf("SkillCard") then
			for _, p in sgs.qlist(from:getAliveSiblings()) do
				if p:hasSkill(self:objectName()) then
					local n = 0
					for _, pp in sgs.qlist(p:getAliveSiblings()) do
						if isSameTeam(p,pp) then
							n = n + pp:getHp()
						end
					end
					if n <= 3 then
						if isSameTeam(p,to) and p:objectName() ~= to:objectName() then
							return true
						end
					end
				end
			end
		end
		return false
	end
}

dg_bian:addSkill(dg_longshi)
dg_bian:addSkill(dg_songyan)
dg_bian:addSkill(dg_suwei)
dg_bian:addSkill(dg_hualao)

sgs.LoadTranslationTable{
["dg_bian"] = "狴犴",
["dg_longshi"] = "龍視",
[":dg_longshi"] = "鎖定技，每回合限一次，當非神獸的其他角色成為基本牌的目標後，其摸一張牌。若為陸地，所有己方其他角色各摸一張牌。",
["dg_songyan"] = "訟言",
[":dg_songyan"] = "鎖定技，每回合限一次，當非神獸的其他角色成為普通錦囊牌的目標後，其摸一張牌。若為陸地，所有己方其他角色各摸一張牌。",
["dg_suwei"] = "肅威",
[":dg_suwei"] = "鎖定技，當你成為一名對方角色於其回合內使用的牌的目標後，你棄置其一張手牌。",
["dg_hualao"] = "必報",
[":dg_hualao"] = "鎖定技，如果己方其他角色總體力值小於等於3，己方其他角色不是敵方角色使用牌的合法目標。",
}



sgs.LoadTranslationTable{

["boss_chi"] = "魑",
["boss_mo"] = "魅",
["boss_wang"] = "魍",
["boss_liang"] = "魎",
["boss_niutou"] = "牛頭",
["boss_mamian"] = "馬面",
["boss_baiwuchang"] = "白無常",
["boss_heiwuchang"] = "黑無常",
["boss_luocha"] = "羅剎",
["boss_yecha"] = "夜叉",
["boss_zhuoguiquxie"] = "捉鬼驅邪",

["boss_nianshou"] = "年獸",
["boss_nianshou_heti"] = "年獸",
["boss_nianshou_jingjue"] = "警覺年獸",
["boss_nianshou_renxing"] = "任性年獸",
["boss_nianshou_baonu"] = "暴怒年獸",
["boss_nianshou_ruizhi"] = "睿智年獸",

["boss_shuijing"] = "水鏡先生",
["boss_huangyueying"] = "奇智女傑",
["boss_zhangchunhua"] = "冷血皇后",
["boss_satan"] = "墮落天使",
["boss_dongzhuo"] = "亂世魔王",
["boss_lvbu1"] = "最強神話",
["boss_lvbu2"] = "暴怒戰神",
["boss_lvbu3"] = "神鬼無前",
["boss_zhouyu"] = "赤壁火神",
["boss_pangtong"] = "涅槃鳳雛",
["boss_zhugeliang"] = "祭風臥龍",
["boss_zhangjiao"] = "天公將軍",
["boss_zuoci"] = "迷之仙人",
["boss_yuji"] = "琅琊道士",
["boss_liubei"] = "蜀漢烈帝",
["boss_caiwenji"] = "異鄉孤女",
["boss_huatuo"] = "藥壇聖手",
["boss_luxun"] = "蹁躚君子",
["boss_zhenji"] = "洛水仙子",
["boss_diaochan"] = "絕代妖姬",
["boss_guojia"] = "世之奇士",
["boss_caocao"] = "魏武大帝",

["boss_chiyanshilian"] = "夏之試煉",
["boss_zhuque"] = "朱雀",
["boss_huoshenzhurong"] = "火神祝融",
["boss_yanling"] = "焰靈",
["boss_yandi"] = "炎帝",

["boss_mengpohuihun"] = "回魂",
[":boss_mengpohuihun"] = "若場上有角色在本局遊戲中因孟婆的【忘魂】失去過技能，則令其恢復該技能；此牌進入棄牌堆後，會被銷毀。",
["honghuangzhili"] = "洪荒之力",
["honghuangzhili_cbg"] = "洪",
["honghuangzhili"] = "若該角色的勢力是神，你獲得其一張牌，其【神裔】無效直到其下家的回合（這個下家是動態變化的，會隨著一個人的死或者復活而變化）開始；若該角色的勢力不是神，其翻面。",

["boss_qingmushilian"] = "春之試煉",
["boss_qinglong"] = "青龍",
["boss_mushengoumang"] = "木神勾芒",
["boss_shujing"] = "樹精",
["boss_taihao"] = "太昊",

["boss_baimangshilian"] = "秋之試煉",
["boss_baihu"] = "白虎",
["boss_jinshenrushou"] = "金神蓐收",
["boss_mingxingzhu"] = "明刑柱",
["boss_shaohao"] = "少昊",

["boss_xuanlinshilian"] = "冬之試煉",
["boss_xuanwu"] = "玄武",
["boss_shuishenxuanming"] = "水神玄冥",
["boss_shuishengonggong"] = "水神共工",
["boss_zhuanxu"] = "顓頊",

["boss_lingqu"] = "靈軀",
[":boss_lingqu"] = "鎖定技，當你受到傷害後，你摸一張牌，然後手牌上限+1；防止你受到的大於1點的傷害",
["boss_zirun"] = "滋潤",
[":boss_zirun"] = "鎖定技，準備階段開始時，你令所有角色摸一張牌，若其裝備區內有牌，則其額外摸一張牌",
["boss_juehong"] = "決洪",
[":boss_juehong"] = "鎖定技，準備階段開始時，你令所有敵方角色自己棄置自己的裝備區內的所有牌，若其裝備區內沒有牌，則改為你棄置其一張手牌",
["boss_zaoyi"] = "皂儀",
[":boss_zaoyi"] = "鎖定技，只要水神玄冥存活，你不會成為敵方角色使用錦囊牌的目標，只要水神共工存活，你不會成為敵方角色使用基本牌的目標。水神玄冥和水神共工均死亡後，你摸四張牌，然後從下回合開始，每個回合開始時使體力值最少的敵方角色失去所有體力",
["boss_baiyi"] = "白儀",
[":boss_baiyi"] = "鎖定技，每名敵方角色的摸牌階段，若當前輪數小於3，其少摸一張牌；第五輪開始時，每名敵方角色棄置兩張牌；當己方角色受到的雷電傷害時，若當前輪數小於7，其防止此傷害",
["boss_qingzhu"] = "擎柱",
[":boss_qingzhu"] = "鎖定技，你跳過棄牌階段，若你沒有「殛頂」，你於出牌階段不能使用【殺】",
["boss_jiazu"] = "枷足",
[":boss_jiazu"] = "鎖定技，回合開始時，棄置你上家和下家的敵方角色的裝備區內的坐騎牌",
["boss_jiding"] = "殛頂",
[":boss_jiding"] = "鎖定技，其他己方角色受到傷害後，若傷害來源為敵方角色，則你視為對傷害來源使用雷【殺】，若此【殺】造成傷害，蓐收回復1點體力。然後你失去此技能（只有發動了才會失去，沒發動不會失去）",
["boss_xingqiu"] = "刑秋",
[":boss_xingqiu"] = "鎖定技，每兩輪的出牌階段開始時，你橫置所有敵方角色，然後使明刑柱獲得【殛頂】",
["boss_kuangxiao"] = "狂嘯",
[":boss_kuangxiao"] = "鎖定技，你的回合內，你使用【殺】沒有距離限制，且指定所有敵方角色為目標",
["boss_shenyi"] = "神裔",
[":boss_shenyi"] = "鎖定技，你的武將牌始終正面向上，你的判定區內的牌效果反轉",
["boss_shenen"] = "神恩",
[":boss_shenen"] = "鎖定技，所有己方角色使用牌無距離限制；所有敵方角色摸牌階段多摸一張牌且手牌上限+1",
["boss_fentian"] = "焚天",
[":boss_fentian"] = "鎖定技，你造成的傷害視為火焰傷害；你使用紅色牌無距離和次數限制，且不可被其他角色使用【閃】或【無懈可擊】響應",
["boss_fentian2"] = "焚天",
["boss_xingxia"] = "行夏",
[":boss_xingxia"] = "每兩輪限一次，出牌階段，你可以對焰靈造成2點火焰傷害，然後令每名敵方角色選擇一項：1.棄置一張紅色牌；2.你對其造成1點火焰傷害",
["boss_huihuo"] = "回火",
[":boss_huihuo"] = "鎖定技，當你死亡時，你對所有敵方角色各造成3點火焰傷害；出牌階段，你可以多使用一張【殺】",
["boss_furan"] = "復燃",
[":boss_furan2"] = "復燃",
["boss_furan"] = "當你瀕死時，所有敵方角色視為可以將紅色牌當【桃】對你使用",
[":boss_chiyi"] = "赤儀",
[":boss_chiyi"] = "鎖定技，從第三輪開始，敵方角色受到的傷害+1；第五輪開始時，你對所有角色各造成1點火焰傷害；第七輪開始時，你對焰靈造成5點火焰傷害",
["boss_buchun"] = "布春",
[":boss_buchun"] = "每兩輪限一次，出牌階段，若場上有死亡的樹精，你可以失去1點體力，復活所有樹精，使其回復體力至1點，補充手牌至兩張；若場上沒有死亡的樹精，你可以為一名己方角色回復2點體力",
["boss_cuidu"] = "淬毒",
[":boss_cuidu"] = "鎖定技，你對敵方角色造成傷害後，若其沒有「中毒」，你令其獲得「中毒」，然後令木神勾芒摸一張牌",
["boss_zhongdu"] = "中毒",
[":boss_zhongdu"] = "鎖定技，回合開始時，你進行判定，若結果不為紅桃，你受到1點無來源的傷害，若結果不為黑桃，你失去此技能",
["boss_qingyi"] = "青儀",
[":boss_qingyi"] = "鎖定技，第三輪開始時，己方角色各回復1點體力；第五輪開始時，敵方角色各失去1點體力；第七輪開始時，復活木神勾芒和樹精，使其各摸三張牌，各+1體力上限，然後各回復3點體力",

["boss_guimou"] = "鬼謀",
[":boss_guimou"] = "結束階段，你可以令一名隨機的其他角色進入混亂狀態直到其下一回合結束",
["boss_yuance"] = "遠策",
[":boss_yuance"] = "每當一名角色受到其他角色的傷害，你可以選擇一項並進行一次判定：1. 若結果為黑色，受傷害角色失去一點體力，否則傷害來源失去一點體力；2. 若結果為紅色，受傷害角色回復一點體力，否則傷害來源回復一點體力",
["boss_qizuo"] = "奇佐",
[":boss_qizuo"] = "你可以令你的普通錦囊牌額外結算一次",
["boss_guixin"] = "歸心",
[":boss_guixin"] = "鎖定技，其他角色摸牌時，若摸牌數不少於2，須將摸到的牌中的一張交給你",
["xiongcai"] = "雄才",
[":xiongcai"] = "鎖定技，你在回合結束後隨機獲得一個魏勢力角色的所有技能",
["xiaoxiong"] = "梟雄",
[":xiaoxiong"] = "鎖定技，每當一名其他角色使用一張基本牌或錦囊牌，你獲得一張與之同名的牌；在一名其他角色的結束階段，若其本回合沒有使用牌，你對其造成一點傷害",
["boss_zhangwu"] = "章武",
[":boss_zhangwu"] = "每當你受到一次傷害，你可以棄置任意張牌並令傷害來源選擇一項：棄置等量的牌，或受到等量的傷害",
["xiangxing"] = "禳星",
[":xiangxing"] = "鎖定技，遊戲開始時，你獲得7枚星；每當你累計扣減7點體力，你失去一枚星，並造成7點雷屬性傷害，隨機分配給其他角色；當你失去全部星後，你的體力上限變為3",
["yueyin"] = "月隱",
[":yueyin"] = "鎖定技，你的每一枚星對應的一個特定條件，當你失去星時，若滿足此條件，則不造成傷害",
["xiangxing7"] = "你沒有手牌",
["xiangxing6"] = "此次受到的是火屬性傷害",
["xiangxing5"] = "此次受到的是雷屬性傷害",
["xiangxing4"] = "此次為失去體力",
["xiangxing3"] = "一名其他角色有至少4件裝備",
["xiangxing2"] = "你的判定區內至少有2張牌",
["xiangxing1"] = "場上只有2名存活角色",
["gaiming"] = "改命",
[":gaiming"] = "鎖定技，在你的判定牌生效前，你觀看牌堆頂的7張牌並選擇一張作為判定結果，此結果不可更改",
["fengqi"] = "風起",
[":fengqi"] = "準備階段和結束階段，你可以視為使用任意一張普通錦囊牌",

["jiaoxia"] = "皎霞",
[":jiaoxia"] = "每當你成為紅色牌的目標，你可以摸一張牌",
["lingbo"] = "凌波",
[":lingbo"] = "每當你使用或打出一張閃，你可以摸兩張牌",
["tiandao"] = "天道",
[":tiandao"] = "任意一名角色的判定生效前，你可以打出一張牌替換之",
["yunshen"] = "雲身",
["yunshen"] = "每當你使用或打出一張閃時，你可以令你的防禦距離+1；準備階段，你將累計的防禦距離清零，然後摸等量的牌",
["lianji"] = "連計",
[":lianji"] = "出牌階段限一次，你可以選擇一張手牌並指定兩名角色進行拼點，拼點贏的角色獲得此牌，並對沒贏的角色造成一點傷害",
["mazui"] = "麻醉",
[":mazui"] = "出牌階段限一次，你可以將一張黑色手牌置於一名角色的武將牌上，該角色造成的下一次傷害-1，然後獲得此牌",

["boss_nbianshen"] = "變形",
[":boss_nbianshen"] = "你從第二輪開始，每一輪幻化為警覺、任性、睿智、暴怒四種隨機狀態中的一種",
["boss_mengtai"] = "萌態",
[":boss_mengtai"] = "鎖定技，若你的出牌階段被跳過，你跳過本回合的棄牌階段；若你的摸牌階段被跳過，結束階段開始時，你摸三張牌",
["boss_ruizhi"] = "睿智",
[":boss_ruizhi"] = "鎖定技，其他角色的準備階段開始時，其選擇一張手牌和一張裝備區里的牌，然後棄置其餘的牌。",
["boss_jingjue"] = "警覺",
[":boss_jingjue"] = "每當你於回合外失去牌時，你可以進行一次判定，若結果為紅色，你回復1點體力",
["boss_renxing"] = "任性",
[":boss_renxing"] = "鎖定技，你的回合外，一名角色受到1點傷害後或回復1點體力時，你摸一張牌",
["boss_nbaonu"] = "暴怒",
[":boss_nbaonu"] = "鎖定技，摸牌階段，你改為摸X張牌（X為4到你體力值間的隨機數）；若你的體力值小於5，則你使用【殺】造成的傷害+1且無次數限制",
["boss_shouyi"] = "獸裔",
[":boss_shouyi"] = "鎖定技，你使用牌無距離限制",

["boss_nianrui"] = "年瑞",
[":boss_nianrui"] = "鎖定技，摸牌階段，你額外摸兩張牌",
["boss_qixiang"] = "祺祥",
["boss_qixiang1"] = "祺祥",
["boss_qixiang2"] = "祺祥",
[":boss_qixiang"] = "樂不思蜀判定時，你的方塊判定牌視為紅桃；兵糧寸斷判定時，你的黑桃判定牌視為草花",

["qiwu"] = "棲梧",
[":qiwu"] = "鎖定技。每當你使用一張梅花牌，你回復一點體力",
["jizhen"] = "激陣",
[":jizhen"] = "結束階段，你可以令所至多兩名已受傷角色摸一張牌",

["boss_yushou"] = "馭獸",
[":boss_yushou"] = "出牌階段開始時，你可以對所有敵方角色使用一張南蠻入侵",
["boss_moyany"] = "魔炎",
[":boss_moyany"] = "每當你於回合外失去牌時，你可以進行一次判定，若結果為紅色，你對一名其他角色造成2點火焰傷害",
["boss_modao"] = "魔道",
[":boss_modao"] = "鎖定技，準備階段，你摸兩張牌",
["boss_mojian"] = "魔箭",
[":boss_mojian"] = "出牌階段開始時，你可以對所有敵方角色使用一張萬箭齊發",
["boss_danshu"] = "丹術",
[":boss_danshu"] = "每當你於回合外失去牌時，你可以進行一次判定，若結果為紅色，你回復1點體力",

["boss_zuijiu"] = "醉酒",
[":boss_zuijiu"] = "鎖定技，你因【殺】造成傷害時，此傷害+1。",
["boss_taiping"] = "太平",
[":boss_taiping"] = "鎖定技，摸牌階段摸牌時，你的摸牌數量+2",
["boss_suoming"] = "索命",
[":boss_suoming"] = "結束階段，將任意名未被橫置的其他角色的武將牌橫置",
["boss_xixing"] = "吸星",
[":boss_xixing"] = "準備階段，對任意一名橫置的其他角色造成1點雷電傷害，然後回復1點體力",

["boss_baolian"] = "暴斂",
[":boss_baolian"] = "鎖定技，結束階段，你摸兩張牌",
["boss_manjia"] = "蠻甲",
[":boss_manjia"] = "鎖定技，若你的裝備區內沒有防具牌，則你視為裝備了[藤甲]",
["boss_xiaoshou"] = "梟首",
[":boss_xiaoshou"] = "結束階段，對體力不小於你的一名其他角色造成3點傷害",
["boss_guiji"] = "詭計",
[":boss_guiji"] = "鎖定技，準備階段結束時，若你的判定區內有牌，你隨機棄置其中一張牌",
["boss_lianyu"] = "煉獄",
[":boss_lianyu"] = "結束階段，你可以對所有敵方角色造成1點火焰傷害",

["boss_guihuo"] = "鬼火",
[":boss_guihuo"] = "結束階段，你可以對一名其他角色造成1點火焰傷害",
["boss_minbao"] = "冥爆",
[":boss_minbao"] = "鎖定技，當你死亡時，對場上所有其他角色造成1點火焰傷害",
["boss_luolei"] = "落雷",
[":boss_luolei"] = "準備階段，你可以對一名其他角色造成1點雷電傷害",
["boss_beiming"] = "悲鳴",
[":boss_beiming"] = "鎖定技，當你死亡時，你令殺死你的角色棄置所有手牌",
["boss_guimei"] = "鬼魅",
[":boss_guimei"] = "鎖定技，你不能成為延時類錦囊的目標",
["boss_didong"] = "地動",
[":boss_didong"] = "結束階段，你可以選擇一名敵方角色將其武將牌翻面",
["boss_shanbeng"] = "山崩",
[":boss_shanbeng"] = "鎖定技，當你死亡時，你令所有其他角色棄置其裝備區內的所有牌",

["boss_chiyan_intro1"] = "&nbsp;第一關",
["boss_chiyan_intro1"] = "挑戰朱雀",
["boss_chiyan_intro2"] = "&nbsp;第二關",
["boss_chiyan_intro2"] = "挑戰火神祝融、焰靈",
["boss_chiyan_intro3"] = "&nbsp;第三關",
["boss_chiyan_intro3"] = "挑戰炎帝、火神祝融、焰靈",
["boss_chiyan_intro3_append"] = "每通過一關，遊戲輪數清零，陣亡角色復活，所有角色重置武將和區域內的牌，並獲得4-X張起始手牌，X為陣亡角色數",

["boss_qingmu_intro1"] = "&nbsp;第一關",
["boss_qingmu_intro1"] = "挑戰青龍",
["boss_qingmu_intro2"] = "&nbsp;第二關",
["boss_qingmu_intro2"] = "挑戰木神勾芒、樹精",
["boss_qingmu_intro3"] = "&nbsp;第三關",
["boss_qingmu_intro3"] = "挑戰太昊、木神勾芒、樹精",
["boss_qingmu_intro3_append"] = "每通過一關，遊戲輪數清零，陣亡角色復活，所有角色重置武將和區域內的牌，並獲得4-X張起始手牌，X為陣亡角色數",

["boss_xuanlin_intro1"] = "&nbsp;第一關",
["boss_xuanlin_intro1"] = "挑戰玄武",
["boss_xuanlin_intro2"] = "&nbsp;第二關",
["boss_xuanlin_intro2"] = "挑戰水神玄冥、水神共工",
["boss_xuanlin_intro3"] = "&nbsp;第三關",
["boss_xuanlin_intro3"] = "挑戰顓頊、水神玄冥、水神共工",
["boss_xuanlin_intro3_append"] = "每通過一關，遊戲輪數清零，陣亡角色復活，所有角色重置武將和區域內的牌，並獲得4-X張起始手牌，X為陣亡角色數",

["boss_baimang_intro1"] = "&nbsp;第一關",
["boss_baimang_intro1"] = "挑戰白虎",
["boss_baimang_intro2"] = "&nbsp;第二關",
["boss_baimang_intro2"] = "挑戰金神蓐收、明刑柱",
["boss_baimang_intro3"] = "&nbsp;第三關",
["boss_baimang_intro3"] = "挑戰少昊、金神蓐收、明刑柱",
["boss_baimang_intro3_append"] = "每通過一關，遊戲輪數清零，陣亡角色復活，所有角色重置武將和區域內的牌，並獲得4-X張起始手牌，X為陣亡角色數",

["boss_bianshen_intro1"] = "&nbsp;第一關",
["boss_bianshen_intro1"] = "挑戰魑、魅、魍、魎中的隨機一個",
["boss_bianshen_intro2"] = "&nbsp;第二關",
["boss_bianshen_intro2"] = "挑戰牛頭、馬面中的隨機一個",
["boss_bianshen_intro3"] = "&nbsp;第三關",
["boss_bianshen_intro3"] = "挑戰白無常、黑無常中的隨機一個",
["boss_bianshen_intro4"] = "&nbsp;第四關",
["boss_bianshen_intro4"] = "挑戰羅剎、夜叉中的隨機一個",
["// boss_bianshen2"] = "後援",
["// boss_bianshen2"] = "你死亡後，隨機召喚牛頭、馬面中的一個",
["// boss_bianshen3"] = "後援",
["// boss_bianshen3"] = "你死亡後，隨機召喚白無常、黑無常中的一個",
["// boss_bianshen4"] = "後援",
["// boss_bianshen4"] = "你死亡後，隨機召喚羅剎、夜叉中的一個",

["boss_qiangzheng"] = "強徵",
[":boss_qiangzheng"] = "鎖定技，結束階段，你獲得每個敵方角色的一張手牌",
["boss_baolin"] = "暴凌",
["guizhen"] = "歸真",
[":guizhen"] = "每當你失去最後一張手牌，你可以所有敵人失去全部手牌，沒有手牌的角色失去一點體力（不觸發技能）",
["boss_shengshou"] = "聖手",
[":boss_shengshou"] = "每當你使用一張牌，你可以進行一次判定，若為紅色，你回復一點體力",
["wuqin"] = "五禽戲",
[":wuqin"] = "結束階段，若你沒有手牌，可以摸三張牌",

["boss_konghun"] = "控心",
[":boss_konghun"] = "結束階段，你可以指定一名敵人令其進入混亂狀態（不受對方控制，並將隊友視為敵人）直到下一回合開始",
["yuehun"] = "月魂",
[":yuehun"] = "結束階段，你可以回復一點體力並摸兩張牌",
["fengwu"] = "風舞",
[":fengwu"] = "出牌階段限一次，可令除你外的所有角色依次對與其距離最近的另一名角色使用一張【殺】，無法如此做者失去1點體力。",
["boss_wange"] = "笙歌",

["huanhua"] = "幻化",
[":huanhua"] = "鎖定技，遊戲開始時，你獲得其他角色的所有技能，體力上限變為其他角色之和；其他角色於摸牌階段摸牌時，你摸等量的牌；其他角色於棄牌階段棄牌時，你棄置等量的手牌",

["boss_leiji"] = "雷擊",
[":boss_leiji"] = "每當你使用或打出一張【閃】，可令任意一名角色進行一次判定，若結果為黑色，其受到一點雷電傷害，然後你摸一張牌",
["jidian"] = "亟電",
[":jidian"] = "每當你造成一次傷害，可以指定距離受傷害角色1以內的一名其他角色進行判定，若結果為黑色，該角色受到一點雷電傷害",

["tinqin"] = "聽琴",
["boss_guihan"] = "歸漢",
[":boss_guihan"] = "限定技，瀕死階段，你可以將體力回復至體力上限，摸4張牌，令所有敵人的技能恢復，失去技能【悲歌】和【胡笳】，並獲得技能【聽琴】、【蕙質】",
["boss_huixin"] = "蕙質",
[":boss_huixin"] = "每當你於回合外失去牌，可以進行一次判定，若為黑色，當前回合角色失去一點體力，否則你回復一點體力並摸一張牌",
["boss_hujia"] = "胡笳",
[":boss_hujia"] = "結束階段，若你已受傷，可以棄置一張牌令一名其他角色的所有技能失效，若其所有技能已失效，改為令其失去一點體力上限",
["boss_honglian"] = "紅蓮",
[":boss_honglian"] = "鎖定技，結束階段，你摸兩張牌，並對所有敵人造成一點火焰傷害",
["huoshen"] = "火神",
[":huoshen"] = "鎖定技，你防止即將受到的火焰傷害，改為回復1點體力",
["boss_xianyin"] = "仙音",
[":boss_xianyin"] = "每當你於回合外失去牌，你可以進行一次判定，若為紅色，你令一名敵人失去一點體力",

["boss_yuhuo"] = "浴火",
[":boss_yuhuo"] = "覺醒技，在你涅槃後，你獲得技能【神威】、【朱羽】",
["boss_tianyu"] = "天獄",
[":boss_tianyu"] = "鎖定技，結束階段，你解除橫置狀態，除你之外的所有角色進入橫置狀態",

["boss_jizhi"] = "集智",
[":boss_jizhi"] = "每當你使用一張非轉化的非基本牌，你可以摸一張牌並展示之",
["boss_guiyin"] = "歸隱",
[":boss_guiyin"] = "鎖定技，體力值比你多的角色無法在回合內對你使用卡牌",
["boss_gongshen"] = "工神",
[":boss_gongshen"] = "鎖定技，除你之外的角色沒有裝備區；你不能成為其他角色的延時錦囊牌的目標",

["fanghua"] = "芳華",
[":fanghua"] = "結束階段，你可以令所有已翻面角色流失一點體力",
["tashui"] = "踏水",
[":tashui"] = "每當你使用或打出一張黑色牌，你可以令一名其他角色翻面",

["boss_wuxin"] = "無心",
[":boss_wuxin"] = "鎖定技，你防止即將受到的傷害，改為流失一點體力；你不能成為其他角色的延時錦囊的目標",
["shangshix"] = "傷逝",
[":shangshix"] = "鎖定技，你的手牌數至少為4，結束階段，若你的體力值大於1，你令場上所有角色流失一點體力",


["boss_qinguangwang"] = "秦廣王",
["boss_panguan"] = "判官",
[":boss_panguan"] = "鎖定技，你不能成為延時類錦囊的目標。",
["boss_juhun"] = "拘魂",
[":boss_juhun"] = "鎖定技，結束階段，你令隨機一名其他角色的武將牌翻面或橫置。",
["boss_wangxiang"] = "望鄉",
[":boss_wangxiang"] = "鎖定技，當你死亡時，你令所有其他角色棄置其裝備區內的所有牌。",

["boss_chujiangwang"] = "楚江王",
["boss_bingfeng"] = "冰封",
[":boss_bingfeng"] = "鎖定技，你死亡時，若殺死你的角色武將牌是正面朝上，你令其翻面。",

["boss_songdiwang"] = "宋帝王",
["boss_heisheng"] = "黑繩",
[":boss_heisheng"] = "鎖定技，你死亡時，橫置所有場上角色。",
["boss_shengfu"] = "繩縛",
[":boss_shengfu"] = "鎖定技，你的回合結束時，隨機棄置一張場上其他角色的坐騎牌。",

["boss_wuguanwang"] = "五官王",
["boss_zhiwang"] = "治妄",
[":boss_zhiwang"] = "鎖定技，當其他角色於摸牌階段外獲得牌時，你隨機棄置其一張手牌。",
["boss_zhiwang_planetarian"] = "注意事項",
[":boss_zhiwang_planetarian"] = "若觸發【治妄】的角色因【治妄】觸發的其他的技能（如【傷逝】【連營】等）繼續獲得了牌，則該角色將其武將牌變更為孫策。",
["boss_gongzheng"] = "公正",
[":boss_gongzheng"] = "鎖定技，準備階段，若你判定區有牌，你隨機棄置一張你判定區的牌。",
["boss_xuechi"] = "血池",
[":boss_xuechi"] = "鎖定技，你的回合結束時，令隨機一名其他角色失去2點體力。",

["boss_yanluowang"] = "閻羅王",
["boss_tiemian"] = "鐵面",
[":boss_tiemian"] = "鎖定技，你的防具區沒有牌時，視為你裝備【仁王盾】。",
["boss_zhadao"] = "鍘刀",
[":boss_zhadao"] = "鎖定技，你使用【殺】指定目標後，你令目標角色防具無效。",
["boss_zhuxin"] = "誅心",
[":boss_zhuxin"] = "鎖定技，你死亡時，你令場上血量最少的一名其他角色受到2點傷害。",

["boss_bianchengwang"] = "卞城王",
["boss_leizhou"] = "雷咒",
[":boss_leizhou"] = "鎖定技，準備階段，你對隨機一名其他角色造成1點雷屬性傷害",
["boss_leifu"] = "雷縛",
[":boss_leifu"] = "鎖定技，你的回合結束時，隨機橫置一名其他角色。",
["boss_leizhu"] = "雷誅",
[":boss_leizhu"] = "鎖定技，你死亡時，對所有其他角色造成依次造成1點雷屬性傷害。",

["boss_taishanwang"] = "泰山王",
["boss_fudu"] = "服毒",
[":boss_fudu"] = "鎖定技，其他角色使用【桃】時，你令隨機另一名其他角色失去1點體力。",
["boss_kujiu"] = "苦酒",
[":boss_kujiu"] = "鎖定技，其他角色準備階段，你令其失去1點體力，然後該角色視為使用一張【酒】。",
["boss_renao"] = "熱惱",
[":boss_renao"] = "鎖定技，你死亡時，你令隨機一名其他角色受到3點火屬性傷害。",

["boss_dushiwang"] = "都市王",
["boss_remen"] = "熱悶",
[":boss_remen"] = "鎖定技，若你的裝備區內沒有防具牌，則【南蠻入侵】、【萬箭齊發】和普通【殺】對你無效。",
["boss_zhifen"] = "炙焚",
[":boss_zhifen"] = "鎖定技，準備階段，你隨機選擇一名其他角色，獲得其1張手牌（沒有則不獲得），並對其造成1點火屬性傷害。",
["boss_huoxing"] = "火刑",
[":boss_huoxing"] = "鎖定技，你死亡時，你對所有其他角色造成1點火屬性傷害。",

["boss_pingdengwang"] = "平等王",
["boss_suozu"] = "鎖足",
[":boss_suozu"] = "鎖定技，準備階段，你令所有其他角色橫置。",
["boss_abi"] = "阿鼻",
[":boss_abi"] = "鎖定技，鎖定技，你受到傷害時，你對傷害來源造成傷害的角色造成1點隨機屬性傷害（雷或火隨機）。",
["boss_pingdeng"] = "平等",
[":boss_pingdeng"] = "鎖定技，你死亡時，你對體力最多的一名其他角色造成2點隨機屬性傷害（屬性隨機），然後再對一名體力最多的其他角色造成1點隨機屬性傷害（屬性隨機）。",

["boss_zhuanlunwang"] = "轉輪王",
["boss_lunhui"] = "輪回",
[":boss_lunhui"] = "鎖定技，準備階段，若你的體力小於等於2，則你與場上除你以外體力最高且大於2的角色交換體力值。",
["boss_wangsheng"] = "往生",
[":boss_wangsheng"] = "鎖定技，你的出牌階段開始時，視為你隨機使用一張【南蠻入侵】或【萬箭齊發】。",
["boss_zlfanshi"] = "反噬",
[":boss_zlfanshi"] = "鎖定技，每個回合你受到第一次傷害後，若再次受到傷害，則對隨機一名其他角色造成1點傷害。",

--孟婆:
["boss_mengpo"] = "孟婆",
["boss_shiyou"] = "拾憂",
[":boss_shiyou"] = "其他角色於棄牌階段棄置的牌進入棄牌堆前，你可以選擇其中任意張花色各不相同的牌獲得之。",
["boss_wanghun"] = "忘魂",
[":boss_wanghun"] = "鎖定技，你死亡時，令隨機兩名敵方角色各隨機失去一個技能（主公技除外），並在牌堆中加入2張回魂。(回魂只能在挑戰模式出現)",
["boss_wangshi"] = "往事",
[":boss_wangshi"] = "鎖定技，你存活時，敵方角色的回合開始時，令其於本回合不能使用或打出隨機一種類型的牌（基本、錦囊、裝備）。",


--地藏王:
["boss_dizangwang"] = "地藏王",
["boss_bufo"] = "不佛",
[":boss_bufo"] = "鎖定技，你的回合開始時，你對所有距離為1的其他角色造成1點火焰傷害；你受到大於等於2的傷害時，令此傷害-1。",
["boss_wuliang"] = "無量",
[":boss_wuliang"] = "鎖定技，你登場時額外摸3張牌；結束階段開始時，你摸兩張牌；你的回合開始時，若你當前體力小於3，則回復至3。",
["boss_dayuan"] = "大願",
[":boss_dayuan"] = " 當一名角色判定牌最終生效前，你可以指定該判定牌的點數和花色",
["boss_diting"] = "諦聽",
[":boss_diting"] = "鎖定技，你的坐騎區被廢除，你與別人計算距離時-1，別人與你計算距離時+1；你的坐騎牌均用於重鑄。",

--等階
["boss_sdyl_playerlevel1"] = "一階",
["boss_sdyl_playerlevel1"] = "",
["boss_sdyl_playerlevel2"] = "二階",
["boss_sdyl_playerlevel2"] = "開局隨機使用一張裝備牌，起始手牌+1",
["boss_sdyl_playerlevel3"] = "三階",
["boss_sdyl_playerlevel3"] = "出殺次數+1，體力上限+1",
["boss_sdyl_playerlevel4"] = "四階",
["boss_sdyl_playerlevel4"] = "摸牌階段多摸一張牌，起始手牌+1",
["boss_sdyl_playerlevel5"] = "重生",
["boss_sdyl_playerlevel5"] = "限定技，當你處於瀕死狀態時，你可以棄置所有判定區牌，然後復原你的武將牌，將手牌補充至手牌體力上限（至多為5），將體力回復至體力上限。",

["boss_sdyl_bosslevel1"] = "一階",
["boss_sdyl_bosslevel1"] = "",
["boss_sdyl_bosslevel2"] = "二階",
["boss_sdyl_bosslevel2"] = "登場時隨機使用一張裝備牌",
["boss_sdyl_bosslevel3"] = "三階",
["boss_sdyl_bosslevel3"] = "出殺次數+1，回合開始獲得一張【殺】，體力上限+1，起始手牌+1",
["boss_sdyl_bosslevel4"] = "四階",
["boss_sdyl_bosslevel4"] = "摸牌階段多摸一張牌，手牌上限+1",
["boss_sdyl_bosslevel5"] = "五階",
["boss_sdyl_bosslevel5"] = "登場時視為使用一張【南蠻入侵】且此【南蠻入侵】傷害+1。體力上限+1，起始手牌+1",

["boss_sunce"] = "那個男人",
["boss_hunzi"] = "魂姿",
[":boss_hunzi"] = "覺醒技，準備階段，若你的體力值為1，你減1點體力上限，失去技能【魂佑】並獲得技能【英姿】和【英魂】。",
["boss_jiang"] = "激昂",
[":boss_jiang"] = "①鎖定技，【激昂】不會無效<br>②每當你使用或打出紅色牌時，你可以摸一張牌。若你是因響應其他角色使用或打出的牌，則你獲得對方使用或打出的牌<br>③當有其他角色使用或打出紅色牌指定你為目標或響應你後，你可以摸一張牌並獲得這些牌",
["boss_hunyou"] = "魂佑",
[":boss_hunyou"] = "鎖定技，你的體力值變化和體力上限變化無效。",
["boss_taoni"] = "討逆",
[":boss_taoni"] = "鎖定技，遊戲開始時，每名角色回合開始時或你死亡時，你檢查存活角色的合法性。若有角色存在非法行為，則你終止本局遊戲。",



--第一關：挑戰秦廣王。<br>第二關：挑戰楚江王，宋帝王，五官王，閻羅王中的一個。<br>第三關：挑戰卞城王，泰山王，都市王，平等王中的一個。<br>第四關：挑戰轉輪王。<br>注：孟婆將在每局前三個階段隨機一個階段登場<br>地藏王登場規則為，50回合內通過第三關，並且在前三關中成功擊殺孟婆。<li>選陸遜左慈張春華於吉蔣費孔融自動變孫笨",



["goujiangdesidai"] = "篝醬的絲帶",
[":goujiangdesidai"] = "鎖定技，若你未擁有技能【縱絲】，則你視為擁有技能【縱絲】；若你擁有技能【縱絲】，則你將此技能改為「出牌階段限兩次」",
["goujiangdesidai_skill"] = "縱絲",
["niaobaidaowenha"] = "鳥白島文蛤",
["niaobaidaowenha_skill"] = "鳥白島文蛤",
[":niaobaidaowenha"] = "當你減少1點體力上限後，你可令一名其他角色增加1點體力上限並回復1點體力。",
["niaobaidaowenha_skill"] = "當你減少1點體力上限後，你可令一名其他角色增加1點體力上限並回復1點體力。",
["shenzhixiunvfu"] = "神之修女服",
[":shenzhixiunvfu"] = "沒什麼實際作用的衣服，僅僅是顯得像個神而已。",

["mode_boss_card_config"] = "挑戰卡牌",
["mode_boss_character_config"] = "挑戰武將",
}

--------------------------------------------------------------------------------------------
sgs.Sanguosha:addSkills(skills)