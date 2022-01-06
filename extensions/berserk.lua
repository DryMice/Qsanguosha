module("extensions.berserk", package.seeall)
extension = sgs.Package("berserk")


sgs.LoadTranslationTable{
    ["berserk"] = "王座",
}


--初音未来
berserk_miku1 = sgs.General(extension, "berserk_miku1", "god", 7, false)
berserk_miku2 = sgs.General(extension, "berserk_miku2", "god", 4, false, true, true)


--心弦：每当你受到一次有来源的伤害时，你可摸1张牌，令你与来源获得等同于伤害值的音符标记。
berserk_xinxian = sgs.CreateTriggerSkill{
    name = "berserk_xinxian",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.from then return false end
		if damage.to:objectName() ~= player:objectName() then return false end
		if not player:askForSkillInvoke(self:objectName(), data) then return false end
		room:broadcastSkillInvoke(self:objectName())
		player:drawCards(1)
		player:gainMark("@note", damage.damage)
		damage.from:gainMark("@note", damage.damage)
	end
}


berserk_miku1:addSkill(berserk_xinxian)
berserk_miku2:addSkill(berserk_xinxian)


--崩坏：锁定技。回合结束阶段，你对有音符标记的角色造成X点（X为该角色音符标记数的一半，向上取整）火焰伤害（若你有音符标记，则你失去1点体力并摸X+1张牌），然后弃置
--场上全部的音符标记。
berserk_benghuai = sgs.CreateTriggerSkill{
    name = "berserk_benghuai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local k = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		    if p:getMark("@note") > 0 then
			    k = k + p:getMark("@note")
			end
		end
		if k <= 0 then return false end
		room:sendCompulsoryTriggerLog(player, self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		local a = math.random(1, 2)
		if a == 1 then
		    room:doLightbox("berserk_benghuai1$", 1000)
		elseif a == 2 then
		    room:doLightbox("berserk_benghuai2$", 1000)
		end
		for _, t in sgs.qlist(room:getAlivePlayers()) do
		    if t:getMark("@note") > 0 then
			    if t:objectName() ~= player:objectName() then
				    room:damage(sgs.DamageStruct(self:objectName(), player, t, math.ceil(t:getMark("@note")/2), sgs.DamageStruct_Fire))
				elseif t:objectName() == player:objectName() then
				    room:loseHp(t)
					t:drawCards(1 + math.ceil(t:getMark("@note")/2))
				end
				t:loseAllMarks("@note")
			end
		end
	end
}


berserk_miku1:addSkill(berserk_benghuai)
berserk_miku2:addSkill(berserk_benghuai)


--梦幻：锁定技。摸牌阶段，你放弃摸牌，改为依次亮出牌堆顶X+3张牌（X为你已损失体力值），若颜色为：红色-你回复1点体力（否则每名角色有39%的概率获得1个音符标记）；
--黑色-你令一名角色获得1个音符标记（若选择自己为目标则改为两个），然后你获得这些牌。
berserk_menghuan = sgs.CreateTriggerSkill{
    name = "berserk_menghuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, miku, data)
	    local room = miku:getRoom()
		if miku:getPhase() ~= sgs.Player_Draw then return false end
		local a = 0
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		room:sendCompulsoryTriggerLog(miku, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		room:doLightbox("berserk_menghuan$", 1000)
		while a < 3 + miku:getLostHp() do
		    local ids = room:getNCards(1, true)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = miku
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, miku:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
			room:getThread():delay()
			local id = ids:at(0)
			local card = sgs.Sanguosha:getCard(id)
			dummy:addSubcard(id)
			if card:isRed() then
				if miku:isWounded() then
				    local re = sgs.RecoverStruct()
				    re.who = miku
				    re.recover = 1
				    room:recover(miku, re, true)
				else
				    for _, t in sgs.qlist(room:getAlivePlayers()) do
					    local r = math.random(1, 100)
					    if r >= 61 then t:gainMark("@note") end
					end
				end
			elseif card:isBlack() then
			    local p = room:askForPlayerChosen(miku, room:getAlivePlayers(), self:objectName(), "@menghuan-target2", true)
				if p then
				    if p:objectName() ~= miku:objectName() then
				        p:gainMark("@note") 
					else
					    p:gainMark("@note", 2)
					end
				end
			end
			a = a + 1
		end
		miku:obtainCard(dummy)
		dummy:deleteLater()
		return true
	end
}


berserk_miku2:addSkill(berserk_menghuan)


--激唱：限定技，当你进入濒死状态时，你可将体力值回复至1点，然后进行一次判定并获得判定牌，令所有其他角色选择一项：交给你一张与此牌花色相同的牌，或令你回复1点体力。
berserk_jichang = sgs.CreateTriggerSkill{
    name = "berserk_jichang",
	frequency = sgs.Skill_Limited,
	limit_mark = "@jichang",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local dying = data:toDying()
		local victim = dying.who
		if victim:objectName() == player:objectName() then
		    if player:getMark("@jichang") <= 0 then return false end
		    if player:askForSkillInvoke(self:objectName(), data) then
			    player:loseMark("@jichang")
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				local re = sgs.RecoverStruct()
				re.who = player
				re.recover = 1 - player:getHp()
				room:recover(player, re, true)
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.pattern = ""
				judge.play_animation = false
				room:judge(judge)
				local suitstring = judge.card:getSuitString()
				local pattern
				local suit = judge.card:getSuit()
				if suit == sgs.Card_Spade then
				    pattern = ".S"
				elseif suit == sgs.Card_Heart then
				    pattern = ".H"
				elseif suit == sgs.Card_Club then
				    pattern = ".C"
				elseif suit == sgs.Card_Diamond then
				    pattern = ".D"
				end
				player:obtainCard(judge.card)
				local prompt = string.format("@jichangask:%s:%s", player:objectName(), judge.card:getSuitString())
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				    local c = room:askForCard(p, pattern, prompt, sgs.QVariant(suitstring), sgs.Card_MethodNone)
					if c then
					    room:obtainCard(player, c, true)
					else
					    local re = sgs.RecoverStruct()
				        re.who = p
				        re.recover = 1
				        room:recover(player, re, true)
					end
				end
			end
		end
		return false
	end
}


berserk_miku2:addSkill(berserk_jichang)
berserk_miku1:addSkill("#berserk_propertyset")
berserk_miku1:addSkill("#berserk_change")
berserk_miku2:addSkill("#berserk_secondturn")


sgs.LoadTranslationTable{
	["berserk_miku1"] = "初音ミク",
	["#berserk_miku1"] = "電子歌姬",
	["berserk_miku2"] = "初音ミク",
	["#berserk_miku2"] = "終焉之聲",
	["cv:berserk_miku1"] = "藤田咲",
	["cv:berserk_miku2"] = "藤田咲",
	["~berserk_miku2"] = "發生了嚴重的系統錯誤……嚴重的系統錯誤……",
	["@note"] = "音符",
	["berserk_xinxian"] = "心弦",
	["$berserk_xinxian1"] = "心中的螺絲被緊緊地旋上。",
	["$berserk_xinxian2"] = "為了要扮演不是自己的他人。",
	["$berserk_xinxian3"] = "無法選擇自己想說的話。",
	["$berserk_xinxian4"] = "這是早已被決定好的宿命。",
	[":berserk_xinxian"] = "每當你受到一次有來源的傷害時，你可摸1張牌，令你與來源獲得等同於傷害值的音符標記。",
	["berserk_benghuai"] = "崩壞",
	["berserk_benghuai1$"] = "image=image/animate/berserk_benghuai1.jpg",
	["berserk_benghuai2$"] = "image=image/animate/berserk_benghuai2.jpg",
	["$berserk_benghuai"] = "（……對不起）",
	[":berserk_benghuai"] = "<font color = \"blue\"><b>鎖定技。</b></font>回合結束階段，你對有音符標記的角色造成X點（X為該角色音符標記數的一半，向上取整）火焰傷"..
"害（若你有音符標記，則你失去1點體力並摸X+1張牌），然後棄置場上全部的音符標記。",
	["berserk_menghuan"] = "夢幻",
	["berserk_menghuan$"] = "image=image/animate/berserk_menghuan.jpg",
	["@menghuan-target1"] = "請選擇一名其他角色，然後你令其摸1張牌並回复1點體力。",
	["@menghuan-target2"] = "請選擇一名任意角色，然後你令其獲得1個音符標記。",
	["$berserk_menghuan1"] = "對這樣一直演奏的一成不變的日子不抱一絲疑惑。",
	["$berserk_menghuan2"] = "我曾想早晨是某人給予我的禮物吧？",
	["$berserk_menghuan3"] = "即使是一瞬間也仍然相信能夠動搖景色的聲音。",
	["$berserk_menghuan4"] = "告訴我吧，只有你的世界。",
	[":berserk_menghuan"] = "<font color = \"blue\"><b>鎖定技。</b></font>摸牌階段，你放棄摸牌，改為依次亮出牌堆頂X +3張牌（X為你已損失體力值），若顏色為：紅色-"..
"你回复1點體力（否則每名角色有39%的概率獲得1個音符標記）；黑色-你令一名角色獲得1個音符標記（若選擇自己為目標則改為兩個），然後你獲得這些牌。",
	["berserk_jichang"] = "激唱",
	["@jichang"] = "激唱",
	[":berserk_jichang"] = "<font color = \"red\"><b>限定技，</b></font>當你進入瀕死狀態時，你可將體力值回復至1點，然後進行一次判定並獲得判定牌，令所有其他角色"..
"選擇一項：交給你一張與此牌花色相同的牌，或令你回复1點體力。",
	["@jichangask"] = "%src的【激唱】效果，請交給%src一張%dest牌，否則你令%src回复1點體力。",
}