module("extensions.bf", package.seeall)
extension = sgs.Package("bf")

sgs.LoadTranslationTable{
	["bf"] = "邊鋒國戰包",	
}

local skills = sgs.SkillList()

function ChangeGeneral(room, player)
	local Chosens = {}
	local generals = generate_all_general_list(player, false, {})
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
	local general = room:askForGeneral(player, table.concat(Chosens, "+"))
	--local isSecondaryHero = not (sgs.Sanguosha:getGeneral(player:getGeneralName()):hasSkill("ol_fuhan"))
	--room:changeHero(player, general, false, true, isSecondaryHero)
	room:changeHero(player, general, false, true, true)
end

--凌統
bf_lingtong = sgs.General(extension, "bf_lingtong", "wu", 4, true)
--旋略
xuanlve = sgs.CreateTriggerSkill{
	name = "xuanlve",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canDiscard(p, "he") then
					targets:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "xuanlve-invoke", true, true)
			if target then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					local id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(id, target, player)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
bf_lingtong:addSkill(xuanlve)
--勇進
yongjinCard = sgs.CreateSkillCard{
	name = "yongjin",
	will_throw = false,
	filter = function(self, targets, to_select) 
		if self:subcardsLength() == 0 or #targets == 1 then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	feasible = function(self, targets)
--		if sgs.Self:hasFlag("yongjin") then
		if sgs.Self:getMark(self:objectName().."engine") > 0 then
			return #targets == 1
		end
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		if source:hasFlag("yongjin") then
			room:moveCardTo(self, source, targets[1], sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), self:objectName(), ""))
		else
			if player:getGeneralName() == "bf_lingtong" then
				room:doSuperLightbox("bf_lingtong", self:objectName())
			else
				room:doSuperLightbox("lingtong_po", self:objectName())
			end
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				room:removePlayerMark(source, "@yongjin")	
				local ids = sgs.IntList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					for _, card in sgs.qlist(p:getCards("e")) do
					ids:append(card:getId())
					end
				end
				room:fillAG(ids)
				local t = 0
				for i = 1, 3 do
					local id = room:askForAG(source, ids, i ~= 1, self:objectName())
					if id == -1 then break end
					ids:removeOne(id)
					source:obtainCard(sgs.Sanguosha:getCard(id))
					room:takeAG(source, id, false)
					room:setCardFlag(sgs.Sanguosha:getCard(id), "yongjin")
					t = i
					if ids:isEmpty() then break end
				end
				room:clearAG()
				room:setPlayerFlag(source, "yongjin")
				for i = 1, t do
					room:askForUseCard(source, "@@yongjin!", "@yongjin")
				end
				room:setPlayerFlag(source, "-yongjin")
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
yongjinVS = sgs.CreateViewAsSkill{
	name = "yongjin",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:hasFlag("yongjin")
	end,
	view_as = function(self, cards)
		local card = yongjinCard:clone()
--		if sgs.Self:hasFlag("yongjin") and cards[1] then
		if sgs.Self:getMark(self:objectName().."engine") > 0 and cards[1] then
			card:addSubcard(cards[1])
		end
		return card
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@yongjin") > 0 then
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasEquip() then
					return true
				end
			end
			return player:hasEquip()
		end
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@yongjin")
	end
}
yongjin = sgs.CreateTriggerSkill{
	name = "yongjin",
	frequency = sgs.Skill_Limited,
	view_as_skill = yongjinVS,
	limit_mark = "@yongjin",
	on_trigger = function()
	end
}
bf_lingtong:addSkill(yongjin)


sgs.LoadTranslationTable{
["bf_lingtong"] = "凌統--國",
["&bf_lingtong"] = "凌統",
["#bf_lingtong"] = "豪情烈膽",
["illustrator:bf_lingtong"] = "F.源",
["xuanlve"] = "旋略",
[":xuanlve"] = "當你失去裝備區裡的牌後，你可以棄置一名其他角色一張牌。",
["$xuanlve1"] = "",
["$xuanlve2"] = "",
["yongjin"] = "勇進",
[":yongjin"] = "限定技，出牌階段，你可以獲得場上的最多三張裝備區裡的牌，然後將這些牌置入一至三名角色的裝備區。",
["$yongjin1"] = "",
["$yongjin2"] = "",
["~bf_lingtong"] = "",
["#choice"] = "%from 選擇了 %arg",
["@yongjin"] = "请發動“勇進”",
["~yongjin"] = "選擇一張裝備牌→選擇一名角色→點擊確定",
["xuanlve-invoke"] = "你可以發動“旋略”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
}
--呂範
lvfan = sgs.General(extension, "lvfan", "wu", 3, true, true)
--調度
tiaoduCard = sgs.CreateSkillCard{
	name = "tiaodu",
	filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:objectName() == sgs.Self:objectName()
		end
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
		local card = room:askForCard(effect.to, ".Equip", "@tiaodu", sgs.QVariant(), sgs.Card_MethodNone)
		if card then
			if room:getCardPlace(card:getId()) == sgs.Player_PlaceHand then
				room:useCard(sgs.CardUseStruct(card, effect.to, effect.to))
			else
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(effect.to)) do
					for i = 1, 5 do
						if p:getEquip(i) ~= card and not targets:contains(p) then
							targets:append(p)
						end
					end
				end
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(effect.to, targets, self:objectName(), "tiaodu-invoke", true, true)
					if target then
						room:moveCardTo(card, target, sgs.Player_PlaceEquip)
					end
				end
			end
		end
			room:removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
tiaodu = sgs.CreateZeroCardViewAsSkill{
	name = "tiaodu",
	view_as = function()
		return tiaoduCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tiaodu")
	end
}
lvfan:addSkill(tiaodu)
--典財
diancai = sgs.CreateTriggerSkill{
	name = "diancai",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if (move.from and move.from:objectName() == p:objectName() and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == p:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
					room:addPlayerMark(p, self:objectName().."-Clear")
				end
			elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:objectName() ~= p:objectName() and p:getMark(self:objectName().."-Clear") >= p:getHp() and p:getMaxHp() > p:getHandcardNum() and room:askForSkillInvoke(p, self:objectName(), data) then
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					p:drawCards(p:getMaxHp() - p:getHandcardNum(), self:objectName())
					if room:askForSkillInvoke(p, "ChangeGeneral", data) then
						ChangeGeneral(room, p)
					end
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
	end, 
	can_trigger = function(self, target)
		return target
	end
}
lvfan:addSkill(diancai)

sgs.LoadTranslationTable{
["lvfan"] = "呂範",
["#lvfan"] = "忠篤亮直",
["illustrator:lvfan"] = "銘zmy",
["tiaodu"] = "調度",
[":tiaodu"] = "出牌階段限一次，你可以選擇包括你在內的至少一名角色，這些角色各可以選擇一項：1.使用裝備牌；2.將裝備區裡的一張牌置入一名角色的裝備區內。",
["$tiaodu1"] = "",
["$tiaodu2"] = "",
["diancai"] = "典財",
[":diancai"] = "其他角色的出牌階段結束時，若你於此階段內失去過至少X張牌，你可以將手牌補至上限，然後可以變更武將牌。（X為你的體力值）",
["$diancai1"] = "",
["$diancai2"] = "",
["~lvfan"] = "",
["@tiaodu"] = "你可以發動“調度”<br/> <b>操作提示</b>: 選擇一張裝備牌→點擊確定<br/>",
["ChangeGeneral"] = "變更武將牌",
}

--[[
呂範
調度——其他角色使用裝備牌時，你可以令其摸一張牌。出牌階段開始時，你可以獲得一名角色裝備區的一張牌，然後可以將此牌交給另一名角色。
典財——其他角色的出牌階段結束時，若你於此階段內失去過至少X張牌，則你可以將手牌摸至體力上限。若如此做，你可以變更副將（X為你的體力值且至少為1）。
]]--

lvfan_sec_rev = sgs.General(extension, "lvfan_sec_rev", "wu", 3, true)

tiaodu_sec_revCard = sgs.CreateSkillCard{
	name = "tiaodu_sec_rev",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:getEquips():isEmpty() and sgs.Self:canDiscard(to_select, "e")
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local id = room:askForCardChosen(effect.from, effect.to, "e", self:objectName(), false, sgs.Card_MethodDiscard)
			room:obtainCard(effect.from, id)

			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "ziyuan", "")
			room:obtainCard(source, self, reason, false)

			room:askForYiji(source, id, self:objectName(), false, false, true, -1, sgs.SPlayerList(), sgs.CardMoveReason(), "@qianya", true)
		end
	end
}
tiaodu_sec_revVS = sgs.CreateZeroCardViewAsSkill{
	name = "tiaodu_sec_rev",
	view_as = function()
		return tiaodu_sec_revCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@tiaodu_sec_rev"
	end
}
tiaodu_sec_rev = sgs.CreateTriggerSkill{
	name = "tiaodu_sec_rev",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = tiaodu_sec_revVS,
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local invoke = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:getEquips():isEmpty() then
					invoke = true
				end
			end
			if player:getPhase() == sgs.Player_Play and invoke and RIGHT(self, player) then
				room:askForUseCard(player, "@tiaodu_sec_rev", "@tiaodu_sec_rev")
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()

			if use.card and use.card:isKindOf("EquipCard") then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill("tiaodu_sec_rev") then
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForSkillInvoke(p,"tiaodu_sec_rev",_data) then
							player:drawCards(1)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}

lvfan_sec_rev:addSkill(tiaodu_sec_rev)
lvfan_sec_rev:addSkill("diancai")

sgs.LoadTranslationTable{
["lvfan_sec_rev"] = "呂範--二版",
["&lvfan_sec_rev"] = "呂範",
["#lvfan_sec_rev"] = "忠篤亮直",
["illustrator:lvfan_sec_rev"] = "銘zmy",
["tiaodu_sec_rev"] = "調度",
[":tiaodu_sec_rev"] = "其他角色使用裝備牌時，你可以令其摸一張牌。出牌階段開始時，你可以獲得一名角色裝備區的一張牌，然後可以將此牌交給另一名角色。",
["@tiaodu_sec_rev"] = "你可以獲得一名角色裝備區的一張牌",
["~tiaodu_sec_rev"] = "選擇一名角色 --> 點擊確定",
["$tiaodu_sec_rev1"] = "",
["$tiaodu_sec_rev2"] = "",
["~lvfan"] = "",
["@tiaodu"] = "你可以發動“調度”<br/> <b>操作提示</b>: 選擇一張裝備牌→點擊確定<br/>",
["ChangeGeneral"] = "變更武將牌",
}
--[[
法正
恩怨——鎖定技，當其他角色對你使用【桃】時，該角色摸一張牌；當你受到傷害後，傷害來源需交給你一張手牌，否則失去1點體力。
眩惑——其他角色的出牌階段限一次，若你同意，該角色可以交給你一張手牌並棄置一張牌，然後其選擇並獲得以下技能之一直到回合結束：“武聖” 、“咆哮”、“龍膽”、“鐵騎”、“烈弓”、“狂骨”（場上已有的技能無法選擇）
]]--
bf_fazheng = sgs.General(extension, "bf_fazheng", "shu", 3, true, true)

bf_xuanhuoCard = sgs.CreateSkillCard{
	name = "bf_xuanhuo_bill",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("bf_xuanhuo") and to_select:getMark("bf_xuanhuo_Play") == 0 and to_select:getMark("bf_huashenxushi") == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "bf_xuanhuoengine")
		if source:getMark("bf_xuanhuoengine") > 0 then
			room:addPlayerMark(targets[1], "bf_xuanhuo_Play")

			local choice = room:askForChoice(targets[1], "bf_xuanhuo_bill","accept+cancel")
			ChoiceLog(targets[1], choice)
			if choice ~= "cancel" then
				room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
				room:askForDiscard(source,"bf_xuanhuo",1,1)

				local five_tiger_skill = {"wusheng_po","paoxiao_po","longdan_po","tieji","ol_liegong","ol_kuanggu"}
				local sks = {}	
				for _,sk in sgs.qlist(five_tiger_skill) do
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


				local choice = room:askForChoice(source, "bf_xuanhuo", table.concat(sks, "+"))
				if not player:hasSkill(choice) then			
					room:acquireSkill(source, choice)
				end

			end
			room:removePlayerMark(source, "bf_xuanhuoengine")
		end
	end
}
bf_xuanhuoVS = sgs.CreateOneCardViewAsSkill{
	name = "bf_xuanhuo_bill&",
	filter_pattern = ".",
	view_as = function(self,card)
		local skillcard = bf_xuanhuoCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return true
	end
}


if not sgs.Sanguosha:getSkill("bf_xuanhuo_bill") then skills:append(bf_xuanhuoVS) end

bf_xuanhuo = sgs.CreateTriggerSkill{
	name="bf_xuanhuo",
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	on_trigger=function(self, event, player, data, room)
		if event == sgs.EventAcquireSkill and data:toString() == self:objectName() or event==sgs.GameStart then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if not p:hasSkill("bf_xuanhuo_bill") then
					room:attachSkillToPlayer(p,"bf_xuanhuo_bill")
				end
			end
		end
	end
}

bf_enyuan = sgs.CreateTriggerSkill{
	name = "bf_enyuan" ,
	events = {sgs.CardsMoveOneTime, sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Peach") and use.from:isAlive() then
					use.from:drawCards(1)
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			local source = damage.from
			if (not source) or (source:objectName() == player:objectName()) then return false end
				if source:isAlive() and player:isAlive() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local card
						if not source:isKongcheng() then
							card = room:askForExchange(source, self:objectName(), 1, false, "bf_enyuanGive", true)
						end
						if card then
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
															  player:objectName(), self:objectName(), nil)
							reason.m_playerId = player:objectName()
							room:moveCardTo(card, source, player, sgs.Player_PlaceHand, reason)
						else
							room:loseHp(source)
						end
					end
				end
		end
		return false
	end
}

bf_fazheng:addSkill(bf_enyuan)
bf_fazheng:addSkill(bf_xuanhuo)

sgs.LoadTranslationTable{
["#bf_fazheng"] = "蜀漢的輔翼",
["bf_fazheng"] = "國戰法正",
["&bf_fazheng"] = "法正",
["designer:bf_fazheng"] = "Michael_Lee",
["illustrator:bf_fazheng"] = "紫喬",
["bf_enyuan"] = "恩怨",
[":bf_enyuan"] = "鎖定技，當其他角色對你使用【桃】時，該角色摸一張牌；當你受到傷害後，傷害來源需交給你一張手牌，否則失去1點體力。",
["bf_EnyuanGive"] = "請交給 %dest %arg 張手牌",
["bf_xuanhuo"] = "眩惑",
[":bf_xuanhuo"] = "其他角色的出牌階段限一次，若你同意，該角色可以交給你一張手牌並棄置一張牌，然後其選擇並獲得以下技能之一直到回合結束：“武聖” 、“咆哮”、“龍膽”、“鐵騎”、“烈弓”、“狂骨”（場上已有的技能無法選擇）",
["bf_xuanhuo_bill"]  = "眩惑",
}
--荀攸
bf_xunyou = sgs.General(extension, "bf_xunyou", "wei", 3, true, true)
--奇策
bf_qiceCard = sgs.CreateSkillCard{
	name = "bf_qice",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Self:getTag("bf_qice"):toCard()
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		--return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(card, qtargets)
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end,
	feasible = function(self, targets)
		local card = sgs.Self:getTag("bf_qice"):toCard()
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		local n = #targets
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if n == 0 then
			if not sgs.Self:isProhibited(sgs.Self, card) and card:isKindOf("GlobalEffect") then n = 1 end
			for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
				if not sgs.Self:isProhibited(p, card) and (card:isKindOf("AOE") or card:isKindOf("GlobalEffect")) then
					n = n + 1
				end
			end
		end
		if card and ((card:canRecast() and n == 0) or (n > sgs.Self:getHandcardNum())) then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
		use_card:addSubcards(card_use.from:getHandcards())
		use_card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p,use_card)then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(card_use.from)
		if not available then return nil end
		return use_card		
	end
}
bf_qiceVS = sgs.CreateZeroCardViewAsSkill{
	name = "bf_qice",
	view_as = function(self)
		local c = sgs.Self:getTag("bf_qice"):toCard()
		if c then
			local card = bf_qiceCard:clone()
			card:setUserString(c:objectName())
			card:addSubcards(sgs.Self:getHandcards())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#bf_qice") and not player:isKongcheng()
	end
}
bf_qice = sgs.CreateTriggerSkill{
	name = "bf_qice",
	view_as_skill = bf_qiceVS,
	global = true,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:getSkillName() == "bf_qice" and use.card:getTypeId() ~= 0 and use.from then
			if room:askForSkillInvoke(use.from, "ChangeGeneral", data) then
				ChangeGeneral(room, use.from)
			end
		end
	end
}
bf_qice:setGuhuoDialog("r")
bf_xunyou:addSkill(bf_qice)
bf_xunyou:addSkill("zhiyu")

sgs.LoadTranslationTable{
["bf_xunyou"] = "荀攸--國",
["&bf_xunyou"] = "荀攸",
["#bf_xunyou"] = "曹魏的謀主",--編一個
["illustrator:bf_xunyou"] = "心中一凜",
["bf_qice"] = "奇策",
[":bf_qice"] = "出牌階段限一次，你可以將所有手牌當目標數不大於X的非延時類錦囊牌使用(X為你的手牌數)，若如此做，你可以變更武將牌。",
["$bf_qice1"] = "傾力為國，算無遺策。",
["$bf_qice2"] = "奇策在此，誰與爭鋒。",
["~bf_xunyou"] = "主公，臣下先行告退。",
}
--卞夫人
bianhuanghou = sgs.General(extension, "bianhuanghou", "wei", 3, false, true)
--挽危
--[[wanwei = sgs.CreateTriggerSkill{
	name = "wanwei", 
	events = {sgs.BeforeCardsMove}, 
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE and move.reason.m_playerId ~= move.reason.m_targetId then
			local i = 0
			local lirang_card = sgs.IntList()
			for _,id in sgs.qlist(move.card_ids) do
				if room:getCardOwner(id):objectName() == move.from:objectName() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
					lirang_card:append(id)
				end
				i = i + 1
			end
			if not lirang_card:isEmpty() then
				local card = room:askForExchange(player, self:objectName(), lirang_card:length(), lirang_card:length(), true, "wanwei-invoke", true)
				if not card:getSubcards():isEmpty() then
					move:removeCardIds(move.card_ids)
					for _,id in sgs.qlist(card:getSubcards()) do
						move.card_ids:append(id)
						move.from_places:append(room:getCardPlace(id))
					end
					data:setValue(move)
				end
			end
		end
	end
}]]--
wanwei = sgs.CreateTriggerSkill{
    name = "wanwei",
    events = {sgs.BeforeCardsMove},
    on_trigger = function(self, event, player, data)
        local move = data:toMoveOneTime()
        local room = player:getRoom()
        --if move.from and move.from:objectName() == player:objectName() and ((move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE and move.reason.m_playerId ~= move.reason.m_targetId) or (move.to and move.to:isAlive() and move.from:objectName() ~= move.to:objectName() and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP)) then
         if move.from and move.from:objectName() == player:objectName() and ((move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE and move.reason.m_playerId ~= move.reason.m_targetId) or (move.to and move.to:isAlive() and move.from:objectName() ~= move.to:objectName() and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_USE)) then
            local toReplace = sgs.IntList()
            local i = 0
						local ids = sgs.IntList()
						if move.card_ids then
           	 for _, id in sgs.qlist(move.card_ids) do
                if room:getCardOwner(id):objectName() == move.from:objectName() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
                    toReplace:append(id)
                end
                i = i + 1
            	end
          	end
            --if not toReplace:isEmpty() then
            if toReplace and not toReplace:isEmpty() then
                local card = room:askForExchange(player, self:objectName(), toReplace:length(), toReplace:length(), true, "wanwei-invoke", true)
                if card and not card:getSubcards():isEmpty() then
                    --move:removeCardIds(toReplace)
                    --myetyet按：removeCardIds有毒，如果真的需要用请把源码Lua化
                    for _, p in sgs.qlist(toReplace) do
                        local i = move.card_ids:indexOf(p)
                        if i >= 0 then
                            move.card_ids:removeAt(i)
                            move.from_places:removeAt(i)
                            --move.from_pile_names:removeAt(i)
                            --move.open:removeAt(i)
                            --myetyet按：以上两句有毒，请勿使用
                        end
                    end
                    for _, p in sgs.qlist(card:getSubcards()) do
                        move.card_ids:append(p)
                        move.from_places:append(room:getCardPlace(p))
                    end
                    data:setValue(move)
                end
            end
        end
        return false
    end
}
bianhuanghou:addSkill(wanwei)
yuejian = sgs.CreatePhaseChangeSkill{
	name = "yuejian", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if player:getPhase() == sgs.Player_Discard and player:getMark("qietin") == 0 and room:askForSkillInvoke(p, self:objectName()) then
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					player:setFlags("yuejian_buff")
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
	end
}
yuejian_buff = sgs.CreateMaxCardsSkill{
	name = "#yuejian", 
	fixed_func = function(self, target)
		if target:hasFlag("yuejian_buff") then
			return target:getMaxHp()
		end
		return -1
	end
}
bianhuanghou:addSkill(yuejian)
bianhuanghou:addSkill(yuejian_buff)
extension:insertRelatedSkills("yuejian", "#yuejian")

sgs.LoadTranslationTable{
["bianhuanghou"] = "卞夫人--國",
["&bianhuanghou"] = "卞夫人",
["#bianhuanghou"] = "奕世之雍容",
["illustrator:bianhuanghou"] = "雪君S",
["wanwei"] = "挽危",
["@wanwei"] = "請棄置等量的牌",
[":wanwei"] = "你可以選擇被其他角色棄置或獲得的牌。",
["$wanwei1"] = "",
["$wanwei2"] = "",
["yuejian"] = "約儉",
[":yuejian"] = "一名角色的棄牌階段開始時，若其於此回合內未使用過確定目標包括除其和你外的角色的牌，你可以令其於此回合內手牌上限視為體力上限。",
["$yuejian1"] = "",
["$yuejian2"] = "",
["~bianhuanghou"] = "",
}

bf_masu = sgs.General(extension, "bf_masu", "shu", 3, true)
bf_masu:addSkill("sanyao")
bf_zhiman = sgs.CreateTriggerSkill{
	name = "bf_zhiman",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local log = sgs.LogMessage()
		  	log.from = player
			log.to:append(damage.to)
			log.arg = self:objectName()
			log.type = "#Yishi"
			room:sendLog(log)
			room:addPlayerMark(player, self:objectName().."engine")
			room:broadcastSkillInvoke(self:objectName())
			if player:getMark(self:objectName().."engine") > 0 then
				if damage.to:hasEquip() or damage.to:getJudgingArea():length() > 0 then
					local card = room:askForCardChosen(player, damage.to, "ej", self:objectName())
					room:obtainCard(player, card, false)
					if room:askForSkillInvoke(damage.to, "ChangeGeneral", data) then
						ChangeGeneral(room, damage.to)
					end
				end
				room:removePlayerMark(player, self:objectName().."engine")
				return true
			end
		end
		return false
	end
}
bf_masu:addSkill(bf_zhiman)

sgs.LoadTranslationTable{
["bf_masu"] = "馬謖--國",
["&bf_masu"] = "馬謖",
["#bf_masu"] = "帷幄經謀",
["illustrator:bf_masu"] = "螞蟻君",
["bf_zhiman"] = "制蠻",
[":bf_zhiman"] = "當你對其他角色造成傷害時，你可以防止此傷害，獲得其裝備區或判定區裡的一張牌，然後其可以變更武將牌。",
["$bf_zhiman1"] = "兵法諳熟於心，取胜千里之外。",
["$bf_zhiman2"] = "丞相多慮，且看我的。",
["~bf_masu"] = "敗軍之罪，萬死難贖。",
}
--沙摩柯
shamoke = sgs.General(extension, "shamoke", "shu",4)
bf_jili = sgs.CreateTriggerSkill{
	name = "bf_jili", 
	global = true, 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardUsed, sgs.CardResponded}, 
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card			 
		end
		if card and not card:isKindOf("SkillCard") then
		--if card and not card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
			room:addPlayerMark(player, self:objectName().."-Clear")
			if player:getMark(self:objectName().."-Clear") == player:getAttackRange() and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(player:getAttackRange() , self:objectName())
			end
		end
	end
}

shamoke:addSkill(bf_jili)

sgs.LoadTranslationTable{
["shamoke"] = "沙摩柯",
["#shamoke"] = "五溪蠻王",
["illustrator:shamoke"] = "LiuHeng",
["bf_jili"] = "蒺藜",
[":bf_jili"] = "當你於回合內使用或打出第X張牌時，你可以摸X張牌。（X為你的攻擊範圍）",
["$bf_jili1"] = "",
["$bf_jili2"] = "",
["~shamoke"] = "",
}


--李傕郭汜
lijueguosi = sgs.General(extension, "lijueguosi", "qun", 4, true)
--兇算
xiongsuanCard = sgs.CreateSkillCard{
	name = "xiongsuan", 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end, 
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:doSuperLightbox("lijueguosi","xiongsuan")
			room:removePlayerMark(source, "@scary")
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
			source:drawCards(3, self:objectName())
			local SkillList = {}
			for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
				if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and skill:getFrequency() == sgs.Skill_Limited then
					table.insert(SkillList, skill:objectName())
				end
			end
			if #SkillList > 0 then
				local choice = room:askForChoice(source, self:objectName(), table.concat(SkillList, "+"))
				ChoiceLog(source, choice)
				room:addPlayerMark(targets[1], self:objectName()..choice)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
xiongsuanVS = sgs.CreateOneCardViewAsSkill{
	name = "xiongsuan", 
	filter_pattern = ".", 
	view_as = function(self, card) 
		local cards = xiongsuanCard:clone()
		cards:addSubcard(card)
		return cards
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@scary") > 0
	end
}
xiongsuan = sgs.CreatePhaseChangeSkill{
	name = "xiongsuan", 
	view_as_skill = xiongsuanVS, 
	frequency = sgs.Skill_Limited, 
	limit_mark = "@scary", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				if p:getMark(self:objectName()..skill:objectName()) > 0 and player:getPhase() == sgs.Player_Finish then
					room:handleAcquireDetachSkills(p, "-"..skill:objectName().."|"..skill:objectName())
				end
			end
		end
	end
}
lijueguosi:addSkill(xiongsuan)

sgs.LoadTranslationTable{
["lijueguosi"] = "李傕&郭汜",
["&lijueguosi"] = "李傕郭汜",
["#lijueguosi"] = "犯祚傾禍",
["illustrator:lijueguosi"] = "旭",
["cv:lijueguosi"] = "《三國演義》",
["#lijueguosi"] = "飛狼狂豺",
["xiongsuan"] = "兇算",
[":xiongsuan"] = "限定技，出牌階段，你可以棄置一張牌並選擇一名角色，對其造成1點傷害，然後你摸三張牌，若其擁有限定技，你可以令其中一個限定技於此回合結束後視為未發動。",
["$xiongsuan1"] = "讓他看看我的箭法~",
["$xiongsuan2"] = "我們是太師的人，太師不平反，我們就不能名正言順！ 郭將軍所言極是！",
["~lijueguosi"] = "李傕郭汜二賊火拼，兩敗俱傷~",
}

--左慈
--[[
bf_zuoci = sgs.General(extension, "bf_zuoci", "qun", 3, true, true)
cancel = sgs.General(extension, "cancel", "qun", 3, true, true, true)
bf_huashen = sgs.CreateTriggerSkill{
	name = "bf_huashen", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart, sgs.MarkChanged}, 
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local generals = sgs.Sanguosha:getLimitedGeneralNames()
			local huashenss = {}
			for _,name in pairs (generals) do
				if player:getMark("bf_huashen"..name) > 0 then
					table.removeOne(generals, name)
					table.insert(huashenss, name)
				end
			end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if table.contains(generals, p:getGeneralName()) then
					table.removeOne(generals, p:getGeneralName())
				end
				if table.contains(generals, p:getGeneral2Name()) then
					table.removeOne(generals, p:getGeneral2Name())
				end
			end
			if player:getPhase() == sgs.Player_Start and #generals > 0 and room:askForSkillInvoke(player, self:objectName()) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					local SkillList = {}
					if #huashenss < 2 then
						local huashens = {}
						for i = 1, 5 do
							local name = generals[math.random(1, #generals)]
							table.insert(huashens, name)
							table.removeOne(generals, name)
						end
						for i = 1, 2 do
							huashenss = {}
							for _,name in pairs (generals) do
								if player:getMark("bf_huashen"..name) > 0 then
									table.removeOne(generals, name)
									table.insert(huashenss, name)
								end
							end
							if #huashenss > 0 then
								table.insert(huashens, "cancel")
							end
							local general = room:askForGeneral(player, table.concat(huashens, "+"))
							if general == "cancel" then return false end
							room:addPlayerMark(player, "bf_huashen"..general)
							table.removeOne(huashens, general)
							for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
								if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
									table.insert(SkillList, skill:objectName())
								end
							end
						end
					else
						local name = generals[math.random(1, #generals)]
						local choice = room:askForGeneral(player, name.."+cancel")
						if choice ~= "cancel" then
							room:addPlayerMark(player, "bf_huashen"..name)
							local general = room:askForGeneral(player, table.concat(huashenss, "+"))
							room:removePlayerMark(player, "bf_huashen"..general)
							for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
								if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
									table.insert(SkillList, "-"..skill:objectName())
								end
							end
							for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(name):getVisibleSkillList()) do
								if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
									table.insert(SkillList, skill:objectName())
								end
							end
						end
					end
					if #SkillList > 0 then
						room:handleAcquireDetachSkills(player, table.concat(SkillList,"|"))
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		else
			local mark = data:toMark()
			if string.find(mark.name, "engine") and mark.gain > 0 then
				for _, m in sgs.list(player:getMarkNames()) do
					if player:getMark(m) > 0 and string.find(m, "bf_huashen") then
						local SkillList = {}
						for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(string.sub(m, 11, string.len(m))):getVisibleSkillList()) do
							if skill:objectName().."engine" == mark.name or skill:objectName().."Cardengine" == mark.name or skill:objectName().."cardengine" == mark.name or "#"..skill:objectName().."engine" == mark.name or string.upper(string.sub(skill:objectName(), 1, 1))..string.sub(skill:objectName(), 2, string.len(skill:objectName())).."engine" == mark.name  then
								room:removePlayerMark(player, "bf_huashen"..string.sub(m, 11, string.len(m)))
								for _,s in sgs.qlist(sgs.Sanguosha:getGeneral(string.sub(m, 11, string.len(m))):getVisibleSkillList()) do
									if not s:inherits("SPConvertSkill") and not s:isAttachedLordSkill() and not s:isLordSkill() and s:getFrequency() ~= sgs.Skill_Wake and s:getFrequency() ~= sgs.Skill_Limited and s:getFrequency() ~= sgs.Skill_Compulsory then
										table.insert(SkillList, "-"..s:objectName())
									end
								end
							end
						end
						room:handleAcquireDetachSkills(player, table.concat(SkillList,"|"))
					end
				end
			end
		end
		return false
	end
}
bf_zuoci:addSkill(bf_huashen)
bf_xinsheng = sgs.CreateMasochismSkill{
	name = "bf_xinsheng",
	frequency = sgs.Skill_Frequent, 
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		for _,name in pairs (generals) do
			if player:getMark("bf_huashen"..name) > 0 then
				table.removeOne(generals, name)
			end
		end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if table.contains(generals, p:getGeneralName()) then
				table.removeOne(generals, p:getGeneralName())
			end
			if table.contains(generals, p:getGeneral2Name()) then
				table.removeOne(generals, p:getGeneral2Name())
			end
		end
		if #generals > 0 and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				local general = generals[math.random(1, #generals)]
				ChoiceLog(player, general, player)
				room:addPlayerMark(player, "bf_huashen"..general)
				local SkillList = {}
				for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
						table.insert(SkillList, skill:objectName())
					end
				end
				room:handleAcquireDetachSkills(player, table.concat(SkillList,"|"))
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
bf_zuoci:addSkill(bf_xinsheng)

sgs.LoadTranslationTable{
	["bf_zuoci"] = "左慈",
	["#bf_zuoci"] = "迷之仙人",--编一个
	["illustrator:bf_zuoci"] = "吕阳",
	["bf_huashen"] = "化身",
	[":bf_huashen"] = "准备阶段开始时，若“化身”数：小于2，你可以观看武将牌堆顶五张牌，将其中一至两张牌扣置于你的武将牌上，称为“化身”；不小于2，你可以观看武将牌堆顶一张牌，然后将之与其中一张“化身”替换。你可以发动“化身”拥有的技能（除锁定技、转换技、限定技、觉醒技、主公技），若如此做，将那张武将牌置入武将牌堆。",
	["$bf_huashen1"] = "为仙之道,飘渺莫测~",
	["$bf_huashen2"] = "仙人之力,昭于世间~",
	["bf_xinsheng"] = "新生",
	[":bf_xinsheng"] = "当你受到伤害后，你可以将武将牌堆顶一张牌扣置于武将牌上，称为“化身”。",
	["$bf_xinsheng1"] = "感觉到了新的魂魄~",
	["$bf_xinsheng2"] = "神光不灭,仙力不绝~",
	["~bf_zuoci"] = "仙人转世，一去无返",
}
]]--

--[[
化身：遊戲開始時，你獲得兩個勢力標記。若場上沒有人處於瀕死狀態，你可以移去一個勢力標記，
然後視為使用本回合未以此法使用過的任意一張基本牌或普通錦囊牌，若此牌有目標，目標只能是此勢力的角色。
新生：當你受到傷害後， 你可以獲得一個隨機的勢力標記。
]]--


--孟達
gz_mengda = sgs.General(extension,"gz_mengda","wei2","4",true)

--求安

qiuan = sgs.CreateTriggerSkill{
	name = "qiuan",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card then
				local ids = sgs.IntList()
				if damage.card:isVirtualCard() then
					ids = damage.card:getSubcards()
				else
					ids:append(damage.card:getEffectiveId())
				end

				if not ids:isEmpty() then
					local can_invoke = true
					for _, id in sgs.qlist(ids) do
						if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
							can_invoke = false
						end
					end

					if can_invoke and player:getPile("qa_han"):length() == 0 then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:notifySkillInvoked(player, self:objectName())
							room:sendCompulsoryTriggerLog(player, self:objectName()) 
							room:broadcastSkillInvoke(self:objectName())

							local msg = sgs.LogMessage()
							msg.type = "#qiuanProtect"
							msg.from = player
							msg.arg = damage.damage
							if damage.nature == sgs.DamageStruct_Fire then
								msg.arg2 = "fire_nature"
							elseif damage.nature == sgs.DamageStruct_Thunder then
								msg.arg2 = "thunder_nature"
							elseif damage.nature == sgs.DamageStruct_Normal then
								msg.arg2 = "normal_nature"
							end
							room:sendLog(msg)
							player:addToPile("qa_han", damage.card, false)
							return true
						end
					end
				end
			end
		end
	end
}


liangfan = sgs.CreateTriggerSkill{
	name = "liangfan" ,
	events = {sgs.Damage,sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local card = data:toDamage().card
			if card and (not card:isKindOf("SkillCard")) then
				if not card:isVirtualCard() and card:getSubcards():length() > 0 then
					for _, id in sgs.qlist(card:getSubcards()) do
						if player:getMark("liangfan"..id.."_-Clear") > 0 then
							room:sendCompulsoryTriggerLog(player, self:objectName())
							if damage.to and damage.to:isAlive() and not damage.to:isNude() then
								local card = room:askForCardChosen(player, damage.to, "he", self:objectName())
								room:obtainCard(player, card, false)
							end
						end
					end
				elseif card:isVirtualCard() then
					if player:getMark("liangfan"..card:getEffectiveId().."-Clear") > 0 then
						room:sendCompulsoryTriggerLog(p, self:objectName())
						if damage.to and damage.to:isAlive() and not damage.to:isNude() then
							local card = room:askForCardChosen(player, damage.to, "he", self:objectName())
							room:obtainCard(player, card, false)
						end
					end
				end	
			end
		end
		if event == sgs.EventPhaseStart then
			if not player:getPile("qa_han"):isEmpty() and player:getPhase() == sgs.Player_RoundStart then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(player:getPile("qa_han")) do
					dummy:addSubcard(id)
					room:addPlayerMark(player,"liangfan"..sgs.Sanguosha:getCard(id):getEffectiveId().."_-Clear" )
				end
				room:loseHp(player,1)
				room:obtainCard(player, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName()), false)
				dummy:deleteLater()
			end
		end
	end,
	can_trigger = function(self,target)
		return target ~= nil
	end,
}

gz_mengda:addSkill(qiuan)
gz_mengda:addSkill(liangfan)

sgs.LoadTranslationTable{
["gz_mengda"] = "孟達",
["qiuan"] = "求安",
[":qiuan"] = "當你受到傷害後，若此傷害的渠道有對應的實體牌且你的武將牌上沒有「函」，則你可以防止此傷害"
.."並將這些牌置於你的武將牌上，稱為「函」。",
["qa_han"] = "函",
["liangfan"] = "量反",
[":liangfan"] = "鎖定技，準備階段開始時，若你的武將牌上有「函」，則你獲得這些牌，然後失去1點體力。當"..
"你於此回合內因使用實體牌中包含「函」的牌且執行這些牌的效果而對目標角色造成傷害時，你可以獲得目標角色的一"
.."張牌。",
}

--糜芳傅士仁
gz_mifangfushiren = sgs.General(extension_wind, "gz_mifangfushiren", "shu", "4", true)

--鋒勢
mffengshi = sgs.CreateTriggerSkill{
	name = "mffengshi" ,
	events = {sgs.TargetSpecified,sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("SkillCard") and use.to and use.to:length() == 1 then
				for _, p in sgs.qlist(use.to) do
					if (player:hasSkill("mffengshi") or p:hasSkill("mffengshi")) and player:canDiscard(p, "he") and player:getHandcardNum() > p:getHandcardNum() then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if player:askForSkillInvoke(self:objectName(), _data) then
							room:setCardFlag(use.card ,"mffengshi_card")
							local id = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:throwCard(id, p, player)
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			if damage.card then
				if damage.card:hasFlag("mffengshi_card") and (not damage.card:isKindOf("SkillCard")) then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#Mffengshi"
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
	can_trigger = function(self, target)
		return target
	end
}

sgs.LoadTranslationTable{
["gz_mifangfushiren"] = "糜芳傅士仁",
["mffengshi"] = "鋒勢",
["mffengshi"] = "當你使用牌指定唯一目標後，或成為其他角色使用牌的唯一目標後，若此牌使用者的手牌數大於此牌目標的手牌數，則此牌的使用者可令你棄置自己和對方的各一張牌，並令此牌的傷害值+1。",
["#Mffengshi"] = "%from 的技能 “<font color=\"yellow\"><b>烈弓</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--國戰禰衡
gz_mihun = sgs.General(extension,"gz_mihun","qun",3, true)
--狂才

gzkuangcai = sgs.CreateTriggerSkill{
	name = "gzkuangcai",
	frequency = sgs.Skill_Compulsory,
		events = {sgs.PreCardUsed,sgs.TrickCardCanceling,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getPhase() ~= sgs.Player_NotActive then
				player:addQinggangTag(use.card)
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and effect.from:hasSkill(self:objectName()) and effect.from:getPhase() ~= sgs.Player_NotActive then
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
			return false
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if player:getMark("used-Clear") > 0 and player:getMark("damage_record-Clear") == 0 then
					room:addPlayerMark(player, "gzkuangcai1-Clear",1)
				end
				if player:getMark("damage_record-Clear") >= player:getMark("used-Clear") then
					local n = player:getMaxHp() - player:getHandcardNum()
					if n > 0 then
						player:drawCards(n)
					end
					room:addPlayerMark(player, "gzkuangcai2-Clear",1)
				end
			end
		end
	end,
}

gzkuangcaimc = sgs.CreateMaxCardsSkill{
	name = "#gzkuangcaimc",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		if target:hasSkill("gzkuangcai") then
			if target:getMark("gzkuangcai1-Clear") > 0 then
				return -2
			end
			if target:getMark("gzkuangcai2-Clear") > 0 then
				return 2
			end
		end
	end
}

gzkuangcaitm = sgs.CreateTargetModSkill{
	name = "#gzkuangcaitm",
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, player)
		if player:hasSkill("gzkuangcai") and player:getPhase() ~= sgs.Player_NotActive then
			return 1000
		else
			return 0
		end
	end,
	distance_limit_func = function(self, player)
		if player:hasSkill("gzkuangcai") and player:getPhase() ~= sgs.Player_NotActive then
			return 1000
		else
			return 0
		end
	end,
}
--舌箭
gzshejian = sgs.CreateTriggerSkill{
	name = "gzshejian" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() and use.to:length() == 1 then
				if not use.card:isKindOf("SkillCard") then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:throwCard(player:wholeHandCards(), player,player)
						room:damage(sgs.DamageStruct(self:objectName(), player, use.from ))
					end
				end
			end
		end
		return false
	end
}

gz_mihun:addSkill(gzkuangcai)
gz_mihun:addSkill(gzkuangcaimc)
gz_mihun:addSkill(gzkuangcaitm)
gz_mihun:addSkill(gzshejian)

sgs.LoadTranslationTable{
["gz_mihun"] = "國戰禰衡",
["&gz_mihun"] = "禰衡",
["gzkuangcai"] = "狂才",
[":gzkuangcai"] = "鎖定技，你的回合內，你使用牌無距離和次數限制，無視防具且不能被【無懈可擊】響應；棄牌階段開始時，若你本回合使用過牌但沒造成傷害，本回合你的手牌上限-2；若你本回合造成的傷害點數不小於你使用的牌數，你將手牌摸至體力上限且本回合手牌上限+2。",
["gzshejian"] = "舌箭",
[":gzshejian"] = "當你成為其他角色使用牌的唯一目標後，你可以棄置所有手牌。若如此做，你對其造成1點傷害。",
}

--董昭
dongzhao = sgs.General(extension,"dongzhao","wei",3, true, true)

quanjinCard = sgs.CreateSkillCard{
	name = "quanjin",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("damaged_record-Clear") > 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:obtainCard(targets[1], sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""))
			local choice = room:askForChoice(targets[1], "quanjin", "quanjin1+quanjin2")
			if choice == "quanjin1" then
				room:loseHp(targets[1])
				room:drawCards(source, 1, "quanjin")
			elseif choice == "quanjin2" then
				local player_card = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					table.insert(player_card, p:getHandcardNum())
				end
				local n =  math.max(unpack(player_card))
				n = math.min(n,5)
				n = n - source:getHandcardNum()
				if n > 0 then
					room:drawCards(source, n, "quanjin")
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
quanjin = sgs.CreateOneCardViewAsSkill{
	name = "quanjin",
	view_filter = function(self, card)
		return not card:isEquipped()
	end,
	view_as = function(self, card)
		local cards = quanjinCard:clone()
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#quanjin") and not player:isKongcheng()
	end
}

zaoyunCard = sgs.CreateSkillCard{
	name = "zaoyun",
	--handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:distanceTo(to_select) == self:subcardsLength() + 1
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:damage(sgs.DamageStruct("zaoyun", source, targets[1],1 ))
			room:setPlayerMark(targets[1],"zaoyun-Clear",1)
		end
	end
}
zaoyun = sgs.CreateViewAsSkill{
	name = "zaoyun",
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	n = 99,
	view_as = function(self, cards) 
		if #cards > 0 then
			local card = zaoyunCard:clone()
			for i = 1,#cards,1 do
				card:addSubcard(cards[i])
			end
			return card
		else
			return zaoyunCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zaoyun")
	end
}

zaoyunDis = sgs.CreateDistanceSkill{
	name = "#zaoyunDis",
	frequency = sgs.Skill_Compulsory,
	correct_func = function(self, from, to)
		if from:hasSkill("zaoyun") and to:getMark("zaoyun-Clear") > 0 then
			return -999
		else
			return 0
		end
	end
}


dongzhao:addSkill(quanjin)
dongzhao:addSkill(zaoyun)
dongzhao:addSkill(zaoyunDis)

sgs.LoadTranslationTable{
["dongzhao"] = "董昭",
["quanjin"] = "勸進",
[":quanjin"] = "出牌階段限一次，你可將一張手牌交給一名本回合內受到過傷害其他角色，然後令其選擇一項：失去一點體力且令你摸一張牌；或是你將手牌摸至與全場最多相等（至多摸五張）。",
["quanjin1"] = "失去一點體力且令其摸一張牌",
["quanjin2"] = "其將手牌摸至與全場最多相等（至多摸五張）。",
["zaoyun"] = "鑿運",
[":zaoyun"] = "出牌階段限一次，你可以棄置X張牌並選擇一名距離為X+1的敵方角色。你對其造成1點傷害且至其的距離視為1至回合結束。",
}

--宗預
zongyu = sgs.General(extension,"zongyu","shu",3, true)
--氣傲
zyqiao = sgs.CreateTriggerSkill{
	name = "zyqiao" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if not use.card:isKindOf("SkillCard") then
					local _data = sgs.QVariant()
					_data:setValue(use.from)
					if room:askForSkillInvoke(player, self:objectName(), _data) then
						room:doAnimate(1, use.from:objectName(), player:objectName())
						room:broadcastSkillInvoke(self:objectName())
						if player:canDiscard(use.from, "he") then
							local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:throwCard(id, use.from, player)
						end
						room:getThread():delay()
						if use.from:canDiscard(player, "he") then
							local id = room:askForCardChosen(use.from, player, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:throwCard(id, player, use.from)
						end
					end
				end
			end
		end
		return false
	end
}

chengshang = sgs.CreateTriggerSkill{
	name = "chengshang",
	events = {sgs.CardFinished},
	frequency =sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and (not use.card:hasFlag("damage_record")) and player:getPhase() == sgs.Player_Play and player:getMark("chengshang-Clear") == 0 then
				local can_invoke = false
				for _, p in sgs.qlist(use.to) do
					if p:objectName() ~= player:objectName() then
						can_invoke = true
					end
				end
				if can_invoke then
					local GetCardList = sgs.IntList()
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if card:getSuit() == use.card:getSuit() and card:getNumber() == use.card:getNumber() then
								DPHeart:append(id)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						if room:askForSkillInvoke(player, self:objectName(), data) then
							local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
							GetCardList:append(get_id)
							local card = sgs.Sanguosha:getCard(get_id)

							player:obtainCard(card)
							room:setPlayerMark(player,"chengshang-Clear" ,1)
						end
					end
				end
			end
		end
	end
}

zongyu:addSkill(zyqiao)
zongyu:addSkill(chengshang)

sgs.LoadTranslationTable{
["zongyu"] = "宗預",
["zyqiao"] = "氣傲",
[":zyqiao"] = "每回合限兩次。當你成為其他角色使用牌的目標後，你可以棄置其一張牌，然後你棄置一張牌。",
["chengshang"] = "承賞",
[":chengshang"] = "當你於出牌階段內使用的牌結算完成後，若此牌未造成過傷害且此牌的目標包含其他角色且你本階段內未因〖承賞〗獲得過牌，則你可以從牌堆中獲得一張與此牌花色點數相同的牌。",
}

sgs.LoadTranslationTable{
["gz_key_ushio"] = "岡崎汐",
["ushio_huanxin"] = "幻心",
["ushio_huanxin"] = "當你受到傷害後/使用【殺】造成傷害後/使用裝備牌時，你可進行判定。然後你獲得判定牌並棄置一張牌。",
["ushio_xilv"] = "汐旅",
["ushio_xilv2"] = "汐旅",
["ushio_xilv"] = "鎖定技，此武將牌可作為任意單勢力武將牌的副將。當你進行判定後，你令你的手牌上限+1直至你的下個結束階段。",
}

--馬騰

re_mateng = sgs.General(extension,"re_mateng","qun",4, true)

re_xiongyiCard = sgs.CreateSkillCard{
	name = "re_xiongyi",
	mute = true,
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < 3
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("xiongyi")
		room:doSuperLightbox("mateng","re_xiongyi")
		room:removePlayerMark(source, "@arise")
		for _,p in ipairs(targets) do
			p:drawCards(3)
		end
		if #targets < 2 and source:isWounded() then
			local rec = sgs.RecoverStruct()
			rec.who = source
			room:recover(source, rec)
		end
	end
}
re_xiongyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "re_xiongyi",
	view_as = function()
		return re_xiongyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@arise") >= 1
	end
}
re_xiongyi = sgs.CreateTriggerSkill{
	name = "re_xiongyi",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart},
	limit_mark = "@arise",
	view_as_skill = re_xiongyiVS,
	on_trigger = function()
	end
}

re_mateng:addSkill(re_xiongyi)
re_mateng:addSkill("mashu")

sgs.LoadTranslationTable{
["#re_mateng"] = "馳騁西陲",
["re_mateng"] = "馬騰",
["illustrator:re_mateng"] = "DH",
["re_xiongyi"] = "雄異",
[":re_xiongyi"] = "限定技，出牌階段，你可以選擇至多三名角色，這些角色各摸三張牌；若你選擇的角色數不超過2，你回復1點體力",
["$XiongyiAnimate"] = "image=image/animate/xiongyi.png",
}

--孔融
re_kongrong = sgs.General(extension,"re_kongrong","qun",3, true)

re_mingshi = sgs.CreateTriggerSkill{
	name = "re_mingshi",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if event == sgs.DamageInflicted then
			if damage.from and damage.from:isAlive() and player:canDiscard(player, "h") and damage.from:getHp() >= player:getHp() and damage.from:objectName() ~= player:objectName() 
			  and room:askForCard(player, ".black", "@re_mingshi:"..damage.from:objectName(), data, self:objectName()) then
			  	room:doAnimate(1, player:objectName(), damage.from:objectName())
			  	room:notifySkillInvoked(player, self:objectName())
			  	room:broadcastSkillInvoke("mingshi")
				local log = sgs.LogMessage()
				log.type = "#re_Mingshi"
				log.from = player
				log.arg = damage.damage
				log.arg2 = damage.damage - 1
				room:sendLog(log)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					damage.damage = damage.damage - 1
					data:setValue(damage)
					if damage.damage < 1 then
						return true
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}

re_kongrong:addSkill(re_mingshi)
re_kongrong:addSkill("lirang")

sgs.LoadTranslationTable{
["#re_kongrong"] = "凜然重義",
["re_kongrong"] = "孔融",
["illustrator:kongrong"] = "蒼月白龍",
["re_mingshi"] = "名士",
[":re_mingshi"] = "當你受到傷害時，若傷害來源的體力值大於你，你可以棄置一張黑色手牌，令傷害值-1。",
["@re_mingshi"] = "你可以棄置一張黑色手牌，令傷害值-1",
["lirang"] = "禮讓",
[":lirang"] = "每當你的牌因棄置而置入棄牌堆時，你可以將其中至少一張牌任意分配給其他角色。",
["@lirang-distribute"] = "你可以發動“禮讓”將 %arg 張牌任意分配給其他角色",
["#re_Mingshi"] = "%from 發動“<font color=\"yellow\"><b>名士</b></font>”，傷害從 %arg 點減少至 %arg2 點",
}

--糜夫人
re_mifuren = sgs.General(extension,"re_mifuren","shu",3, false)
--存嗣
re_cunsiCard = sgs.CreateSkillCard{
	name = "re_cunsi",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:isMale()
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("cunsi")
		room:doSuperLightbox("mifuren","re_cunsi")

		room:removePlayerMark(source, "@re_cunsi")

		room:obtainCard(targets[1], source:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		room:acquireSkill(targets[1],"yongjue")
		source:turnOver()
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
re_cunsiVS = sgs.CreateZeroCardViewAsSkill{
	name = "re_cunsi",
	view_as = function(self, cards)
		return re_cunsiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and player:getMark("@re_cunsi") > 0
	end
}

re_cunsi = sgs.CreateTriggerSkill{
	name = "re_cunsi",
	frequency = sgs.Skill_Limited,
	view_as_skill = re_cunsiVS,
	limit_mark = "@re_cunsi",
	on_trigger = function()
	end
}

re_guixiu = sgs.CreateTriggerSkill{
	name = "re_guixiu",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.to:contains(player) and player:getHandcardNum() < player:getHp() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke("guixiu")
				player:drawCards(1, self:objectName())
			end
		end
		return false
	end
}

re_mifuren:addSkill(re_guixiu)
re_mifuren:addSkill(re_cunsi)

sgs.LoadTranslationTable{
["#re_mifuren"] = "亂世沉香",
["re_mifuren"] = "糜夫人",
["illustrator:re_mifuren"] = "木美人",
["re_guixiu"] = "閨秀",
[":re_guixiu"] = "當你成為【殺】的目標後，若你的手牌數小於體力值，則你可以摸一張牌。",
["re_cunsi"] = "存嗣",
[":re_cunsi"] = "限定技，出牌階段，你可以將所有手牌交給一名男性角色。該角色獲得技能【勇決】，然後你將武將牌翻面。",
["yongjue"] = "勇決",
[":yongjue"] = "若一名角色於出牌階段內使用的第一張牌為【殺】，此【殺】結算完畢後置入棄牌堆時，你可以令其獲得之。" ,
["$CunsiAnimate"] = "image=image/animate/cunsi.png",
}

--國戰董卓
sp_dongzhuo = sgs.General(extension,"sp_dongzhuo","qun",5, true)

sp_dongzhuo:addSkill("hengzheng")
sp_dongzhuo:addSkill("ol_baonue")

sgs.LoadTranslationTable{
["sp_dongzhuo"] = "SP董卓",
["&sp_dongzhuo"] = "董卓",
["illustrator:sp_dongzhuo"] = "巴薩小馬",
["hengzheng"] = "橫徵",
[":hengzheng"] = "摸牌階段開始時，若你的體力值不大於1或你沒有手牌，你可以放棄摸牌：若如此做，你依次獲得所有其他角色區域內的一張牌。",
}

--鄒氏
re_zoushi = sgs.General(extension,"re_zoushi","qun",3, false, true)


re_huoshui = sgs.CreateTriggerSkill{
	name = "re_huoshui" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_RoundStart then
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName()) 
			room:broadcastSkillInvoke("huoshui")
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				room:setPlayerMark(p, "skill_invalidity-Clear",1)
				room:setPlayerMark(p, "@skill_invalidity",1)
			end
		end
		return false
	end
}

--傾城
re_qingchengCard = sgs.CreateSkillCard{
	name = "re_qingcheng",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:broadcastSkillInvoke("qingcheng")
			targets[1]:turnOver()
			targets[1]:drawCards(2)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
re_qingcheng = sgs.CreateOneCardViewAsSkill{
	name = "re_qingcheng",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
		local aaa = re_qingchengCard:clone()
		aaa:addSubcard(card)
		return aaa
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#re_qingcheng")
	end
}

re_zoushi:addSkill(re_huoshui)
re_zoushi:addSkill(re_qingcheng)

sgs.LoadTranslationTable{
["#re_zoushi"] = "惑心之魅",
["re_zoushi"] = "鄒氏",
["illustrator:re_zoushi"] = "Tuu.",
["re_huoshui"] = "禍水",
[":re_huoshui"] = "鎖定技，準備階段，你令所有其他角色的非鎖定技失效直到回合結束。",
["re_qingcheng"] = "傾城",
[":re_qingcheng"] = "出牌階段，你可以棄置一張裝備牌，然後令一名角色翻面並摸兩張牌。",
}

--張任
re_zhangren = sgs.General(extension,"re_zhangren","qun",4, true)

function throwEquip(room, player)
	local equip_cards = {}
	for _, card in sgs.qlist(player:getCards("he")) do
		if card:isKindOf("EquipCard") then
			table.insert(equip_cards, card)
		end
	end
	if #equip_cards > 0 then
		local card = room:askForCard(player, ".Equip!", "@throw_E", sgs.QVariant(), sgs.Card_MethodNone)
		--if not card then room:showAllCards(player) end
		return card
	end
end
--鋒矢

re_fengshi = sgs.CreateTriggerSkill{
	name = "re_fengshi",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data,room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					if p:getEquips():length() > 0 then
						local _data = sgs.QVariant()
						_data:setValue(p)
						if room:askForSkillInvoke(player, self:objectName(), _data) then
							local card = throwEquip(room, p)
							if card then room:throwCard(card, p, nil) end
						end
					end
				end
			end
		end
		return false
	end
}
--穿心
re_chuanxin = sgs.CreateTriggerSkill{
	name = "re_chuanxin" ,
	events = {sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.to and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
			local _data = sgs.QVariant()
			_data:setValue(damage.to)
			if room:askForSkillInvoke(player, self:objectName(), _data) then
				room:broadcastSkillInvoke("fengshi")
				local choice = room:askForChoice(player, self:objectName(), "re_chuanxin:throw+re_chuanxin:detach")
				if choice == "re_chuanxin:throw" then
					damage.to:throwAllEquips()
					room:loseHp(damage.to)
				elseif choice == "re_chuanxin:detach" then

					local general = sgs.Sanguosha:getGeneral(damage.to:getGeneralName())		
					for _,sk in sgs.qlist(general:getVisibleSkillList()) do
						if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
							if damage.to:hasSkill( sk:objectName() ) then
								table.insert(sks, sk:objectName())
							end
						end
					end

					if damage.to:getGeneral2() then
						local general2 = sgs.Sanguosha:getGeneral(damage.to:getGeneral2Name())
						for _,sk in sgs.qlist(general2:getVisibleSkillList()) do
							if not sk:isLordSkill() and sk:getFrequency() ~= sgs.Skill_Limited and sk:getFrequency() ~= sgs.Skill_Wake then
								if damage.to:hasSkill( sk:objectName() ) then
									table.insert(sks, sk:objectName())
								end
							end
						end
					end

					if #sks > 0 then
						--local skill_choice = room:askForChoice(player,self:objectName(),table.concat(sks, "+"))
						local skill_choice = sks[math.random(1,#sks)]
						room:handleAcquireDetachSkills(player, "-"..skill_choice)
					end
				end
			end			
		end
		return false
	end
}

re_zhangren:addSkill(re_fengshi)
re_zhangren:addSkill(re_chuanxin)

sgs.LoadTranslationTable{
["#re_zhangren"] = "索命神射",
["re_zhangren"] = "張任",
["re_chuanxin_lose"] = "穿心失去技能",
["re_chuanxin:throw"] = "棄置裝備區的所有牌，失去1點體力",
["re_chuanxin:detach"] = "隨機移除主武將牌上的一個技能",

["re_fengshi"]="鋒矢",
[":re_fengshi"]="當你使用【殺】指定目標後，你可以令目標棄置裝備區內的一張牌。",
["re_chuanxin"]="穿心",
[":re_chuanxin"]="當你於出牌階段內使用【殺】或【決鬥】對目標角色造成傷害時，你可以防止此傷害。若如此做，該角色選擇一項：1.棄置裝備區里的所有牌，若如此做，其失去1點體力；2.隨機移除主武將牌上的一個技能。",
}

bf_paiyiCard = sgs.CreateSkillCard{
	name = "bf_paiyi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local powers = source:getPile("power")
		if powers:isEmpty() then return false end
		local card_id = self:getSubcards():first()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", target:objectName(), self:objectName(), "")
		room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
		room:drawCards(target, 2, self:objectName())
		if target:getHandcardNum() > source:getHandcardNum() then
			room:damage(sgs.DamageStruct(self:objectName(), source, target))
		end
	end
}
bf_paiyi = sgs.CreateOneCardViewAsSkill{
	name = "bf_paiyi",
	filter_pattern = ".|.|.|power",
	expand_pile = "power",
	view_as = function(self, card)
		local py = bf_paiyiCard:clone()
		py:addSubcard(card)
		return py
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#bf_paiyiCard") and not player:getPile("power"):isEmpty()
	end
}

sgs.LoadTranslationTable{
["#bf_zhonghui"] = "桀驁的野心家",
["bf_zhonghui"] = "野心鐘會",
[":bf_zhonghui"] = "鐘會",
["bf_quanji"] = "權計",
[":bf_quanji"] = "每當你受到1點傷害後，你可以摸一張牌，然後將一張手牌置於武將牌上，稱為“權”。每有一張“權”，你的手牌上限+1。",
["QuanjiPush"] = "請將一張手牌置於武將牌上",
["power"] = "權",
["bf_paiyi"] = "排異",
[":bf_paiyi"] = "階段技。你可以將一張“權”置入棄牌堆並選擇一名角色：若如此做，該角色摸兩張牌：若其手牌多於你，該角色受到1點傷害。",
}


sgs.Sanguosha:addSkills(skills)
