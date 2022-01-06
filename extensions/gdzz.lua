module("extensions.gdzz", package.seeall)
extension = sgs.Package("gdzz")

sgs.LoadTranslationTable{
	["gdzz"] = "官渡",
}

local skills = sgs.SkillList()

--官渡許攸
--==============================================全局变量及函数区==============================================--

function HeavenMove(player, id, movein)  --将卡牌伪移动至&开头的私人牌堆中并限制使用或打出，以达到牌对你可见的效果 
	local room = player:getRoom()		 --参数[ServerPlayer *player：可见角色; int id：伪移动卡牌id; bool movein：值true为进入私人牌堆，值false为移出私人牌堆]
	if movein then
	  local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
	  sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "guandu_shicai", ""))
	  move.to_pile_name = "&talent"
	  local moves = sgs.CardsMoveList()
		moves:append(move)
	  local _xuyou = sgs.SPlayerList()
	  _xuyou:append(player)
	  room:notifyMoveCards(true, moves, false, _xuyou)
	  room:notifyMoveCards(false, moves, false, _xuyou)
			room:setPlayerCardLimitation(player, "use,response", "" .. id, true)
			player:setTag("HeavenMove", sgs.QVariant(id))
	else
	  local move = sgs.CardsMoveStruct(id, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "guandu_shicai", ""))
	  move.from_pile_name = "&talent"
			local moves = sgs.CardsMoveList()
			moves:append(move)
			local _xuyou = sgs.SPlayerList()
			_xuyou:append(player)
			room:notifyMoveCards(true, moves, false, _xuyou)
			room:notifyMoveCards(false, moves, false, _xuyou)
			room:removePlayerCardLimitation(player, "use,response", "" .. id .. "$1")
	end
end

-- 武将：许攸（官渡之战身份版） --
guandu_xuyou = sgs.General(extension, "guandu_xuyou", "qun2", "3", true)
-- 技能：【识才】牌堆顶的牌于你的出牌阶段内对你可见；出牌阶段，你可以弃置一张牌并获得牌堆顶的牌，若你的手牌中有此阶段内以此法获得的牌，你不能发动此技能。 --
guandu_shicaiCard = sgs.CreateSkillCard{
	name = "guandu_shicai",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(room:getDrawPile():first())
		room:obtainCard(source, card, false)
		room:setCardFlag(card, self:objectName())
	end
}
guandu_shicaiVS = sgs.CreateOneCardViewAsSkill{
	name = "guandu_shicai",
	filter_pattern = ".",
	view_as = function(self, card)
		local skillcard = guandu_shicaiCard:clone()
		skillcard:addSubcard(card:getId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:hasFlag(self:objectName()) then
				return false
			end
		end
		return player:canDiscard(player, "he")
	end
}
guandu_shicai = sgs.CreateTriggerSkill{
	name = "guandu_shicai",
	view_as_skill = guandu_shicaiVS,
	events = {sgs.EventPhaseStart, sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		local id = room:getDrawPile():first()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				HeavenMove(player, id, true)
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (move.from_places:contains(sgs.Player_DrawPile) and p:getPhase() == sgs.Player_Play and move.card_ids:contains(p:getTag("HeavenMove"):toInt()))
					or move.to_place == sgs.Player_DrawPile then
					HeavenMove(p, p:getTag("HeavenMove"):toInt(), false)
					p:setTag(self:objectName(), sgs.QVariant(true))
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getPhase() == sgs.Player_Play and p:getTag(self:objectName()):toBool() then
					HeavenMove(p, id, true)
					p:setTag(self:objectName(), sgs.QVariant(false))
				end
			end
		else
			if player:getPhase() == sgs.Player_Play then
				HeavenMove(player, player:getTag("HeavenMove"):toInt(), false)
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:hasFlag(self:objectName()) then
						room:setCardFlag(card, "-" .. self:objectName())
					end
				end
			end
		end
		return false
	end
}
guandu_xuyou:addSkill(guandu_shicai)
-- 技能：【逞功】当一名角色使用牌指定目标后，若目标数不少于2，你可以令其摸一张牌。 --
chenggong = sgs.CreateTriggerSkill{
	name = "chenggong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.to:length() > 1 and not use.card:isKindOf("SkillCard") then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if use.from:isAlive() and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("to_draw:" .. use.from:objectName())) then
					room:doAnimate(1, p:objectName(), use.from:objectName())
					room:drawCards(use.from, 1, self:objectName())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
guandu_xuyou:addSkill(chenggong)
--[[ 
	技能：【择主】出牌阶段限一次，你可以选择一至两名其他角色（若你不为主公，则其中必须有主公）。
				  你依次获得他们各一张牌（若目标角色没有牌，则改为你摸一张牌），然后分别将一张牌交给他们。 
]]--
gd_zezhuCard = sgs.CreateSkillCard{
	name = "gd_zezhu",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if sgs.Self:isLord() then
				return to_select:objectName() ~= sgs.Self:objectName()
			else
				return to_select:isLord()
			end
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		for i = 1, 2 do
			for j = 1, #targets do
				local to = targets[j]
				if to:isDead() then continue end
				if i == 1 then
					if to:isNude() then
						room:drawCards(source, 1, self:objectName())
					else
						local id = room:askForCardChosen(source, to, "he", self:objectName())
						if id ~= -1 then
							room:obtainCard(source, id, false)
						end
					end
				elseif i == 2 then
					if source:isNude() then continue end
					local card = room:askForCard(source, "..!", "@gd_zezhu-give:" .. to:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:obtainCard(to, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), to:objectName(), self:objectName(), ""), false)
					end
				end
			end
		end
	end
}
gd_zezhu = sgs.CreateZeroCardViewAsSkill{
	name = "gd_zezhu",
	view_as = function()
		return gd_zezhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#gd_zezhu")
	end
}
guandu_xuyou:addSkill(gd_zezhu)

sgs.LoadTranslationTable{
["guandu_xuyou"] = "官渡許攸",
["&guandu_xuyou"] = "許攸",
["#guandu_xuyou"] = "",
["guandu_shicai"] = "識才",
["&talent"] = "識才",
[":guandu_shicai"] = "牌堆頂的牌於你的出牌階段內對你可見；出牌階段，你可以棄置一張牌並獲得牌堆頂的牌，若你的手牌中有此階段內以此法獲得的牌，你不能發動此技能。",
["$guandu_shicai1"] = "遣輕騎以襲許都，大事可成。",
["$guandu_shicai2"] = "主公不聽吾之言，實乃障目不見泰山也！",
["chenggong"] = "逞功",
[":chenggong"] = "當一名角色使用牌指定目標後，若目標數不少於2，你可以令其摸一張牌。",
["chenggong:to_draw"] = "你可以發動“逞功”，令 %src 摸一張牌",
["gd_zezhu"] = "擇主",
[":gd_zezhu"] = "出牌階段限一次，你可以選擇一至兩名其他角色（若你不為主公，則其中必須有主公）。你依次獲得他們各一張牌（若目標角色沒有牌，則改為你摸一張牌），然後分別將一張牌交給他們。",
["@gd_zezhu-give"] = "請將一張牌交給 %src",
["~guandu_xuyou"] = "我軍之所以敗，皆因爾等指揮不當！",
}

--[[
許攸(官渡模式版)
恃才：出牌階段內，牌堆頂的牌對你可見；你可以棄置一張牌並獲得牌堆頂的牌，當該牌離開你的手牌區後，你可以再次發動此技能。
附勢：鎖定技，若場上勢力數為：群大於魏，你擁有技能“擇主”；魏大於群，你擁有技能“逞功”。

逞功：一名角色使用牌指定目標後，若目標數不小於2，你可以令其摸一張牌。
擇主：出牌階段限一次，你可以獲得雙方主帥各一張牌，然後分別交給其一張牌（若有主帥沒有牌，則將獲得其一張牌改為摸一張牌）。
]]--

guandumode_xuyou = sgs.General(extension, "guandumode_xuyou", "qun2", "3", true, true, true)

gdmode_zezhuCard = sgs.CreateSkillCard{
	name = "gdmode_zezhu",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:getMark("@LordMark") == 1
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("@LordMark") == 1
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		for i = 1, 2 do
			for j = 1, #targets do
				local to = targets[j]
				if to:isDead() then continue end
				if i == 1 then
					if to:isNude() then
						room:drawCards(source, 1, self:objectName())
					else
						local id = room:askForCardChosen(source, to, "he", self:objectName())
						if id ~= -1 then
							room:obtainCard(source, id, false)
						end
					end
				elseif i == 2 then
					if source:isNude() then continue end
					local card = room:askForCard(source, "..!", "@gd_zezhu-give:" .. to:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:obtainCard(to, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), to:objectName(), self:objectName(), ""), false)
					end
				end
			end
		end
	end
}
gdmode_zezhu = sgs.CreateZeroCardViewAsSkill{
	name = "gdmode_zezhu",
	view_as = function()
		return gdmode_zezhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#gdmode_zezhu")
	end
}

if not sgs.Sanguosha:getSkill("gdmode_zezhu") then skills:append(gdmode_zezhu) end

fushi = sgs.CreateTriggerSkill{
	name = "fushi",
	--events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.Death},
	--events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded,sgs.CardFinished},
	events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.Death,sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local n,m = 0,0,0
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if (p:getKingdom() == "wei" or p:getKingdom() == "wei2") then
				m = m + 1
			end
			if (p:getKingdom() == "qun" or p:getKingdom() == "qun2") then
				n = n + 1
			end
		end
		if m > n then
			if player:getMark("fushi_gdmode_zezhu") > 0 then
				room:detachSkillFromPlayer(player, "gdmode_zezhu")
				room:setPlayerMark(player,"fushi_gdmode_zezhu",0)
			end
			if (not player:hasSkill("chenggong")) then
				room:acquireSkill(player, "chenggong")
				room:setPlayerMark(player,"fushi_chenggong",1)
			end
		elseif n > m then
			if player:getMark("fushi_chenggong") > 0 then
				room:detachSkillFromPlayer(player, "gd_chenggong")
				room:setPlayerMark(player,"fushi_chenggong",0)
			end
			if (not player:hasSkill("gdmode_zezhu")) then
				room:acquireSkill(player, "gdmode_zezhu")
				room:setPlayerMark(player,"fushi_gdmode_zezhu",1)
			end
		else
			if player:getMark("fushi_gdmode_zezhu") > 0 then
				room:detachSkillFromPlayer(player, "gdmode_zezhu")
				room:setPlayerMark(player,"fushi_gdmode_zezhu",0)
			end
			if player:getMark("fushi_chenggong") > 0 then
				room:detachSkillFromPlayer(player, "gd_chenggong")
				room:setPlayerMark(player,"fushi_chenggong",0)
			end
		end
	end
}

guandumode_xuyou:addSkill(guandu_shicai)
guandumode_xuyou:addSkill(fushi)

sgs.LoadTranslationTable{
["guandumode_xuyou"] = "許攸（專屬）",
["&guandumode_xuyou"] = "許攸",
["#guandumode_xuyou"] = "",

["fushi"] = "附勢",
[":fushi"] = "鎖定技，若場上勢力數為：群大於魏，你擁有技能“擇主”；魏大於群，你擁有技能“逞功”。",

["gdmode_zezhu"] = "擇主",
[":gdmode_zezhu"] = "出牌階段限一次，你可以獲得雙方主帥各一張牌，然後分別交給其一張牌（若有主帥沒有牌，則將獲得其一張牌改為摸一張牌）。",
["@gd_zezhu-give"] = "請將一張牌交給 %src",
["~guandumode_xuyou"] = "我軍之所以敗，皆因爾等指揮不當！",
}

--官渡劉曄
liuye = sgs.General(extension, "liuye", "wei2", "3", true, true)

DMG_card_recorder = sgs.CreateTriggerSkill{  --记录角色受到的上一次对其造成伤害的卡牌
	name = "DMG_card_recorder",
	global = true,
	events = {sgs.Damaged},
	on_trigger = function(self, event, splayer, data, room)
		local card = data:toDamage().card
		if card and not (card:isKindOf("DelayedTrick") or card:isKindOf("EquipCard") or card:isKindOf("SkillCard")) then
			room:setPlayerProperty(splayer, "DCR", sgs.QVariant(data:toDamage().card:objectName()))
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("DMG_card_recorder") then skills:append(DMG_card_recorder) end

polu = sgs.CreateTriggerSkill{
	name = "polu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and not (player:getWeapon() and player:getWeapon():isKindOf("ThunderclapCatapult"))
				and room:getTag("TC_ID"):toInt() > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local card = sgs.Sanguosha:getCard(room:getTag("TC_ID"):toInt())
				room:useCard(sgs.CardUseStruct(card, player, player))
			end
		else
			for i = 1, data:toDamage().damage do
				if not (player:getWeapon() and player:getWeapon():isKindOf("ThunderclapCatapult")) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:drawCards(player, 1, self:objectName())
				end
			end
		end
		return false
	end
}
liuye:addSkill(polu)
choulveVS = sgs.CreateZeroCardViewAsSkill{
	name = "choulve",
	response_or_use = true,
	response_pattern = "@@choulve",
	view_as = function(self, card)
		local DCR = sgs.Self:property("DCR"):toString()
		local skillcard = sgs.Sanguosha:cloneCard(DCR, sgs.Card_NoSuit, -1)
		skillcard:setSkillName("_choulve")
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end
}
choulve = sgs.CreatePhaseChangeSkill{
	name = "choulve",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = choulveVS,
	on_phasechange = function(self, player)
		local room, DCR = player:getRoom(), player:property("DCR"):toString()
		if player:getPhase() ~= sgs.Player_Play then return false end
		if DCR == "" then return false end
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isNude() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local to = room:askForPlayerChosen(player, targets, self:objectName(), "choulve-invoke", true, true)
			if to then
				room:broadcastSkillInvoke(self:objectName())
				local card = room:askForCard(to, ".", "@choulve-give:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, to:objectName(), player:objectName(), self:objectName(), ""), false)
					local DCR_card = sgs.Sanguosha:cloneCard(DCR, sgs.Card_NoSuit, -1)
					if DCR_card:isAvailable(player) then
						if DCR_card:targetFixed() then
							DCR_card:setSkillName("_choulve")
							if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("CL_askForUseCard:" .. DCR)) then
								room:useCard(sgs.CardUseStruct(DCR_card, player, player), true)
							end
						else
							room:askForUseCard(player, "@@choulve", "@choulve:" .. DCR, -1, sgs.Card_MethodUse, false)
						end
					end
				end
			end
		end
		return false
	end
}
liuye:addSkill(choulve)


sgs.LoadTranslationTable{
["liuye"] = "劉曄",
["&liuye"] = "劉曄",
["#liuye"] = "佐世之才",
["polu"] = "破櫓",
[":polu"] = "鎖定技，回合開始時，若你的裝備區內沒有【霹靂車】，則你使用一張【霹靂車】；當你受到1點傷害後，若你的裝備區內沒有【霹靂車】，則你摸一張牌。",
["$polu1"] = "設此發石車，可破袁軍高櫓。",
["$polu2"] = "霹靂之聲，震喪敵膽。",
["choulve"] = "籌略",
[":choulve"] = "出牌階段開始時，你可以令一名有牌的其他角色選擇是否交給你一張牌，若其選擇是，則你可以視為使用上一張對你造成傷害的不為延時錦囊的牌。",
["choulve-invoke"] = "你可以選擇其中一名角色，發動“籌略”",
["@choulve-give"] = "你可以交給 %src 一張牌",
["choulve:CL_askForUseCard"] = "你可以使用【%src】",
["@choulve"] = "請為【%src】選擇目標",
["~choulve"] = "按照此牌使用方式指定角色→點擊確定",
["$choulve1"] = "依此計行，可安軍心。",
["$choulve2"] = "破袁之策，吾已有計。",
["~liuye"] = "唉~於上不得佐君主，於下不得親同僚，吾愧為佐世人臣！",
}



--[[
呂曠呂翔 群 4體力 男
列侯：出牌階段限一次，你可以令你攻擊範圍內的一名有手牌的角色交給你一張手牌。若如此做，你需要將一張手牌交給你攻擊範圍內的另一名其他角色。
齊攻：你使用的【殺】被【閃】抵消後，可對目標再使用一張【殺】，此【殺】不可被【閃】抵消
]]--
lukuangluxiang = sgs.General(extension, "lukuangluxiang", "qun2", "4", true)

liehouCard = sgs.CreateSkillCard{
	name = "liehou",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select) and (not to_select:isKongcheng())
	end,
	on_use = function(self, room, source, targets)
		local to = targets[1]
		if to:isAlive() then
			local card = room:askForCard(to, ".!", "@liehou-give:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
			if card then
				room:obtainCard(source, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, to:objectName(), source:objectName(), self:objectName(), ""), false)
			end
		end
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if source:inMyAttackRange(p) and p:objectName() ~= to:objectName() then
				players:append(p)
			end
		end
		if (not players:isEmpty()) then
			local s = room:askForPlayerChosen(source, players, "liehou", "liehou-invoke", false, true)
			if s then
				local card2 = room:askForCard(source, ".!", "@liehou-give:" .. s:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				if card2 then
					room:obtainCard(s, card2, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), s:objectName(), self:objectName(), ""), false)
				end
			end
		end
	end
}

liehou = sgs.CreateZeroCardViewAsSkill{
	name = "liehou",
	view_as = function()
		return liehouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#liehou")
	end
}

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

qigong = sgs.CreateTriggerSkill{
	name = "qigong",
	events = {sgs.SlashMissed,sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.SlashMissed and RIGHT(self, player) then
			local effect = data:toSlashEffect()
			local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "qigong-invoke", true,true)
				if to then
				room:setPlayerFlag(to, "qigong") 
				if room:askForUseSlashTo(to, effect.to, "@qigong:"..effect.to:objectName(),true) then
					room:broadcastSkillInvoke(self:objectName())
				end
				room:setPlayerFlag(to, "-qigong")
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if not player:hasFlag("qigong") or not use.card:isKindOf("Slash") then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				--p:addQinggangTag(use.card)
				jink_table[index] = 0
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			room:setPlayerFlag(player, "-qigong")
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

lukuangluxiang:addSkill(liehou)
lukuangluxiang:addSkill(qigong)


sgs.LoadTranslationTable{
	["lukuangluxiang"] = "呂曠呂翔",
	["&lukuangluxiang"] = "呂曠呂翔",
	["#lukuangluxiang"] = "",
	["liehou"] = "列侯",
	[":liehou"] = "出牌階段限一次，你可以令你攻擊範圍內的一名有手牌的角色交給你一張手牌。若如此做，你需要將一張手牌交給你攻擊範圍內的另一名其他角色。",
	["qigong"] = "齊攻",
	[":qigong"] = "你使用的【殺】被【閃】抵消後，你可以令一名角色對目標再使用一張【殺】，此【殺】不可被【閃】抵消。",

	["qigong-invoke"] = "你可以對一名角色發動「齊攻」",

	["@liehou-give"] = "請將一張牌交給 %src",
	["liehou-invoke"] = "請選擇一名角色，並交給其一張牌",
	["@qigong"] = "你可以對 %src 使用一張【殺】",
}



--[[
張郃 群 4體力 男
遠略：出牌階段限一次，你可以將一張非裝備牌交給一名角色，然後該角色可以使用該牌並令你摸一張牌。
]]--

sp_zhanghe = sgs.General(extension, "sp_zhanghe", "qun2", "4", true)

yuanlveUseCard = sgs.CreateSkillCard{
	name = "yuanlveUse",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end, 
	feasible = function(self, targets)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and card:targetsFeasible(targets_list, sgs.Self)
	end,
	about_to_use = function(self, room, use)
		--local _guojia = sgs.SPlayerList()
		--_guojia:append(use.from)
		--local move_to = sgs.CardsMoveStruct(self:getSubcards(), use.from, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
		--local moves_to = sgs.CardsMoveList()
		--moves_to:append(move_to)
		--room:notifyMoveCards(true, moves_to, false, _guojia)
		--room:notifyMoveCards(false, moves_to, false, _guojia)

		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setCardFlag(card, "-yuanlve")
		local card_for_use = sgs.Sanguosha:getCard(self:getSubcards():first())
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card_for_use) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card_for_use, use.from, targets_list))
	end
}

yuanlveCard = sgs.CreateSkillCard{
	name = "yuanlve",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local to = targets[1]
		local id = self:getSubcards():first()

		local ids = sgs.IntList()
		ids:append(id)

		room:setCardFlag(id, "yuanlve")

		local move = sgs.CardsMoveStruct(ids, source, to, sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
		room:moveCardsAtomic(move, true)

		if sgs.Sanguosha:getCard(id):isAvailable(targets[1]) then
			--room:askForUseCard(targets[1], ""..id, "@yuanlve")
			if room:askForUseCard(targets[1], "@@yuanlve", "@yuanlve_useCard", -1, sgs.Card_MethodUse) then
				source:drawCards(1)
			end
		end
		room:setCardFlag(id, "-yuanlve")
	end
}

yuanlve = sgs.CreateViewAsSkill{
	n = 1,
	name = "yuanlve",
	response_pattern = "@@yuanlve",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@yuanlve" then
			return to_select:hasFlag(self:objectName())
		else
			return (not to_select:isKindOf("EquipCard"))
		end
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@yuanlve" then
			if #cards ~= 1 then return nil end
			local skillcard = yuanlveUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		else
			if #cards ~= 1 then return nil end
			local skillcard = yuanlveCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#yuanlve")
	end
}

sp_zhanghe:addSkill(yuanlve)


sgs.LoadTranslationTable{
	["sp_zhanghe"] = "官渡張郃",
	["&sp_zhanghe"] = "張郃",
	["#sp_zhanghe"] = "",
	["yuanlve"] = "遠略",
	[":yuanlve"] = "出牌階段限一次，你可以將一張非裝備牌交給一名角色，然後該角色可以使用該牌並令你摸一張牌。",
	["@yuanlve_useCard"] = "你可以發動“遠略”使用牌",
	["~yuanlve"] = "選擇一張牌→選擇目標→點擊確定",
}

--[[
淳于瓊 群 4體力 男

〖倉儲〗鎖定技，遊戲開始時，你獲得3枚「糧」標記，你的手牌上限+X（X為「糧」數）；當你於回合外獲得牌時，你獲得1枚「糧」（「糧」總數至多為場上角色數）。

〖糧營〗棄牌階段開始時，你可以摸至多X張牌，然後你可以交給等量的角色各一張牌。

〖失守〗你使用【酒】或受到1點火焰傷害後，你棄置1枚「糧」。準備階段，若你沒有「糧」，你失去1點體力。
]]--
chunyuqiong = sgs.General(extension, "chunyuqiong", "qun2", "4", true)

cangchu = sgs.CreateTriggerSkill{
	name = "cangchu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			player:gainMark("@liang", 3)
		elseif event == sgs.CardsMoveOneTime and not room:getTag("FirstRound"):toBool() then
			local move = data:toMoveOneTime()
			local start_player_count = 0
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				start_player_count = start_player_count + 1
			end
			if move.to and move.to:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive and player:getMark("@liang") < start_player_count then
			--if move.to and move.to:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive and player:getMark("@liang") < start_player_count and player:getMark("cangchu-Clear") == 0 then
				--room:addPlayerMark(player,"cangchu-Clear")
				player:gainMark("@liang", 1)
			end
		end
		return false
	end
}

cangchuMaxCard = sgs.CreateMaxCardsSkill{
	name = "#cangchuCard", 
	extra_func = function(self, target)
		if target:hasSkill("cangchu") then
			return target:getMark("@liang")
		end
	end
}
--[[
gd_liangyingCard = sgs.CreateSkillCard{
	name = "gd_liangying",
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark(self:objectName().."-Clear") == 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
			room:addPlayerMark(targets[1], self:objectName().."-Clear")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
gd_liangyingVS = sgs.CreateOneCardViewAsSkill{
	name = "gd_liangying",
	filter_pattern = ".",
	view_as = function(self, cards)
		local card = gd_liangyingCard:clone()
		card:addSubcard(cards)
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self, player, pattern)
		return pattern == "@@gd_liangying"
	end,
}
]]--


gd_liangying = sgs.CreateTriggerSkill{
	name = "gd_liangying",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if room:askForSkillInvoke(player, self:objectName()) then

					local draw_num = {}
					for i = 1, player:getMark("@liang") do
						table.insert(draw_num, tostring(i))
					end
					local choice = room:askForChoice(player, "gd_liangying", table.concat(draw_num, "+"))
					player:drawCards(tonumber(choice))

					room:notifySkillInvoked(player,"gd_liangying")
					
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark(self:objectName().."-Clear") == 0 then
							targets:append(p)
						end
					end
					--[[
					while (not targets:isEmpty()) do
						if not room:askForUseCard(player, "@@gd_liangying", "@gd_liangyingput") then break end
						if player:isDead() then break end
						local targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark(self:objectName().."-Clear") == 0 then
								targets:append(p)
							end
						end
					end
					]]--
					local n = tonumber(choice)

					while room:askForYiji(player, getIntList(player:getCards("he")), self:objectName(), false, true, false, 1, targets ) do
						n = n - 1
						if n == 0 then break end
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if  p:getMark(self:objectName().."-Clear") == 1 then
								targets:removeOne(p)
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to and move.reason.m_skillName == "gd_liangying" then
				room:addPlayerMark(BeMan(room, move.to) , self:objectName().."-Clear")
			end
		end
		return false
	end
}

sishou = sgs.CreateTriggerSkill{
	name = "sishou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.EventPhaseStart,sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Fire then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:loseMark("@liang", 1)
			end
		elseif event == sgs.EventPhaseStart and player:getMark("@liang") == 0 then
			if player:getPhase() == sgs.Player_Finish then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:loseHp(player,1)
			end
		else
			local card
			local invoke = true
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				else
					invoke = false
				end
			end
			if card and (not card:isKindOf("SkillCard")) and card:isKindOf("Analeptic") then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:loseMark("@liang", 1)
			end
		end
		return false
	end
}

chunyuqiong:addSkill(cangchu)
chunyuqiong:addSkill(cangchuMaxCard)
chunyuqiong:addSkill(gd_liangying)
chunyuqiong:addSkill(sishou)

sgs.LoadTranslationTable{
	["chunyuqiong"] = "淳于瓊",
	["&chunyuqiong"] = "淳于瓊",
	["#chunyuqiong"] = "烏巢酒仙",
	["cangchu"] = "倉儲",
	[":cangchu"] = "鎖定技，遊戲開始時，你獲得3枚「糧」標記，你的手牌上限+X（X為「糧」數）；當你於回合外獲得牌時，你獲得1枚「糧」（「糧」總數至多為場上角色數）。",
	["gd_liangying"] = "糧營",
	[":gd_liangying"] = "棄牌階段開始時，你可以摸至多X張牌，然後你交給等量的角色各一張牌。",
	["sishou"] = "失守",
	[":sishou"] = "你使用【酒】或受到1點火焰傷害後，你棄置1枚「糧」。準備階段，若你沒有「糧」，你失去1點體力。",
	["@liang"] = "糧",
	["@gd_liangyingput"] = "你可以發動“糧營”",
	["~gd_liangying"] = "選擇一張牌→選擇一名角色→點擊確定",
}

--[[
淳于瓊(官渡之戰版) 群 5體力 男
宿守：棄牌階段開始時，你可以摸X+1張牌（X為糧數），然後可以交給任意名友方角色各一張牌。
倉儲：鎖定技，遊戲開始時，你獲得3枚“糧”標記，當你受到1點火焰傷害後，你失去一枚“糧”標記。
糧營：鎖定技，若有“糧”標記，則友方角色摸牌階段摸牌數+1；當你失去所有“糧”標記後，扣減1點體力上限，然後令敵方角色各摸兩張牌。
]]--

guandu_chunyuqiong = sgs.General(extension, "guandu_chunyuqiong", "qun2", "5", true, true, true)
--[[
guandu_sushouCard = sgs.CreateSkillCard{
	name = "guandu_sushou",
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark(self:objectName().."-Clear") == 0 and to_select:getKingdom() == "qun" and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
			room:addPlayerMark(targets[1], self:objectName().."-Clear")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
guandu_sushouVS = sgs.CreateOneCardViewAsSkill{
	name = "guandu_sushou",
	filter_pattern = ".",
	view_as = function(self, cards)
		local card = guandu_sushouCard:clone()
		card:addSubcard(cards)
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self, player, pattern)
		return pattern == "@@guandu_sushou"
	end,
}
]]--

guandu_sushou = sgs.CreateTriggerSkill{
	name = "guandu_sushou",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if room:askForSkillInvoke(player, self:objectName()) then
					local x = player:getMark("@liang") + 1
					player:drawCards(x)
					room:notifySkillInvoked(player,"guandu_sushou")
					
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getKingdom() == "qun" and p:getMark(self:objectName().."-Clear") == 0 then
							targets:append(p)
						end
					end
					--[[
					while (not targets:isEmpty()) do
						if not room:askForUseCard(player, "@@guandu_sushou", "@guandu_sushouput") then break end
						if player:isDead() then break end
						local targets = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if p:getKingdom() == "qun"  and p:getMark(self:objectName().."-Clear") == 0 then
								targets:append(p)
							end
						end
					end
					]]--

					while room:askForYiji(player, getIntList(player:getCards("he")), self:objectName(), false, true, false, 1, targets ) do
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark(self:objectName().."-Clear") == 1 then
								targets:removeOne(p)
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.to and move.reason.m_skillName == "guandu_sushou" then
				room:addPlayerMark(BeMan(room, move.to) , self:objectName().."-Clear")
			end
		end
		return false
	end
}

guandu_cangchu = sgs.CreateTriggerSkill{
	name = "guandu_cangchu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			player:gainMark("@liang", 3)
		else
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Fire then
				player:loseMark("@liang", damage.damage)
			end
		end
		return false
	end
}

guandu_liangying = sgs.CreateTriggerSkill{
	name = "guandu_liangying",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if (p:getKingdom() == player:getKingdom()) and p:hasSkill("guandu_liangying") and p:getMark("@liang") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					data:setValue(data:toInt() + 1)
				end
			end
		else
			local damage = data:toDamage()
			if player:getMark("@liang") == 0 and RIGHT(self,player) and player:getMark("lose_all_liang") == 0 then
				room:addPlayerMark(player,"lose_all_liang")
				room:loseMaxHp(player)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (p:getKingdom() == "wei" or p:getKingdom() == "wei2") then
						p:drawCards(2)
					end
				end
			end	
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

guandu_chunyuqiong:addSkill(guandu_sushou)
guandu_chunyuqiong:addSkill(guandu_cangchu)
guandu_chunyuqiong:addSkill(guandu_liangying)


sgs.LoadTranslationTable{
	["guandu_chunyuqiong"] = "淳于瓊",
	["&guandu_chunyuqiong"] = "淳于瓊",
	["#guandu_chunyuqiong"] = "",
	["guandu_sushou"] = "宿守",
	[":guandu_sushou"] = "棄牌階段開始時，你可以摸X+1張牌（X為糧數），然後可以交給任意名友方角色各一張牌。",
	["guandu_cangchu"] = "倉儲",
	[":guandu_cangchu"] = "鎖定技，遊戲開始時，你獲得3枚“糧”標記，當你受到1點火焰傷害後，你失去一枚“糧”標記。",
	["guandu_liangying"] = "糧營",
	[":guandu_liangying"] = "鎖定技，若有“糧”標記，則友方角色摸牌階段摸牌數+1；當你失去所有“糧”標記後，扣減1點體力上限，然後令敵方角色各摸兩張牌。",
	["@liang"] = "糧",
	["@guandu_sushouput"] = "你可以發動“宿守”",
	["~guandu_sushou"] = "選擇一張牌→選擇一名角色→點擊確定",
}



--高覽

gaolan = sgs.General(extension, "gaolan", "qun2", "4", true)

xiying = sgs.CreateTriggerSkill{
	name = "xiying",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if room:askForCard(player, "^BasicCard", "@xiying-invoke", data, self:objectName()) then
				room:addPlayerMark(player,"xiying_invoke-Clear")
				room:notifySkillInvoked(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local players = sgs.SPlayerList()

				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:doAnimate(1, player:objectName(), p:objectName())
					if (not room:askForCard(p, "..", "@xiying-discard", data)) then
						room:addPlayerMark(p, "ban_ur")
						room:addPlayerMark(p, "@xiying-Clear")
						room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
					end
				end

			end
		elseif player:getPhase() == sgs.Player_Finish and player:getMark("xiying_invoke-Clear") > 0
		 and player:getMark("damage_recordplay-Clear") > 0 then
			local point_six_card = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if canCauseDamage(sgs.Sanguosha:getCard(id)) then
					point_six_card:append(id)
				end
			end
			if not point_six_card:isEmpty() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:obtainCard(player, point_six_card:at(math.random(0,point_six_card:length()-1)), false)
			end
		end
		return false
	end
}

gaolan:addSkill(xiying)


sgs.LoadTranslationTable{
	["gaolan"] = "高覽",
	["&gaolan"] = "高覽",
	["#gaolan"] = "",
	["xiying"] = "襲營",
	[":xiying"] = "出牌階段開始時，你可以棄置一張非基本手牌並令所有其他角色選擇一項：1.棄置一張牌；2.本回合內不能使用或打出牌；若如此做且出牌階段你造成傷害，結束階段你從牌堆裡獲得一張「殺」或傷害類錦囊牌。",
	["@xiying-invoke"] = "你可以棄置一張非基本手牌並發動「襲營」",
	["@xiying-discard"] = "請棄置一張牌，否則本回合內不能使用或打出牌。",
}

--[[
審配 群 3體力 男
剛直：鎖定技，其他角色對你造成的傷害，和你對其他角色造成的傷害均視為體力流失。
備戰：回合結束後，你可以令一名角色將手牌補至體力上限（至多為5）。該角色回合開始時，若其手牌數為全場最多，則其本回合內不能使用
牌指定其他角色為目標。
]]--
shenpei = sgs.General(extension, "shenpei", "qun2", "3", true)

gangzhi = sgs.CreateTriggerSkill{
	name = "gangzhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.from:hasSkill("gangzhi") or damage.to:hasSkill("gangzhi") then
			if damage.from:hasSkill("gangzhi") then
				room:notifySkillInvoked(damage.from, self:objectName())
				room:sendCompulsoryTriggerLog(damage.from, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
			elseif damage.to:hasSkill("gangzhi") then
				room:notifySkillInvoked(damage.to, self:objectName())
				room:sendCompulsoryTriggerLog(damage.to, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
			end
			room:loseHp(damage.to, damage.damage)
			return true
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

beizhan = sgs.CreateTriggerSkill{
	name = "beizhan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "beizhan", "@beizhan-draw", true, true)
			if s then
				room:notifySkillInvoked(player, self:objectName())
				room:doAnimate(1, player:objectName(), s:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local x = math.min(s:getMaxHp(), 5) - s:getHandcardNum()
				if x > 0 then
					room:drawCards(s, x, "beizhan")
				end
				room:setPlayerMark(s,"@beizhan_target",1)
			end
		end
	end,
}

beizhanLimit = sgs.CreateTriggerSkill{
	name = "beizhanLimit",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_RoundStart then
			if player:getMark("@beizhan_target") > 0 then
				room:setPlayerMark(player,"@beizhan_target",0)
				local beizhan_ban = true
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:getHandcardNum() < p:getHandcardNum() then
						beizhan_ban = false
					end
				end
				if beizhan_ban then

					local msg = sgs.LogMessage()
					msg.type = "#ComZishou"
					msg.from = player
					msg.arg = "beizhan"
					room:sendLog(msg)
					
					room:setPlayerMark(player,"beizhan_ban-Clear",1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

beizhanPS = sgs.CreateProhibitSkill{
	name = "beizhanPS" ,
	is_prohibited = function(self, from, to, card)
		return (from:getMark("beizhan_ban-Clear") > 0  and (from:objectName() ~= to:objectName()) and (not card:isKindOf("SkillCard")))
			
	end
}

if not sgs.Sanguosha:getSkill("beizhanLimit") then skills:append(beizhanLimit) end
if not sgs.Sanguosha:getSkill("beizhanPS") then skills:append(beizhanPS) end

shenpei:addSkill(gangzhi)
shenpei:addSkill(beizhan)

sgs.LoadTranslationTable{
	["shenpei"] = "審配",
	["&shenpei"] = "審配",
	["#shenpei"] = "",
	["gangzhi"] = "剛直",
	[":gangzhi"] = "鎖定技，其他角色對你造成的傷害，和你對其他角色造成的傷害均視為體力流失。",
	["beizhan"] = "備戰",
	["beizhanPS"] = "備戰",
	[":beizhan"] = "回合結束後，你可以令一名角色將手牌補至體力上限（至多為5）。該角色回合開始時，若其手牌數為全場最多，"..
	"則其本回合內不能使用牌指定其他角色為目標。",
	["@beizhan-draw"] = "你可以對一名角色發動「備戰」",
	["#ComZishou"] = "%from 受到 %arg 的影響，本回合內不能使用牌指定其他角色為目標。",
}

--[[
荀諶 群 3體力 男
鋒略：出牌階段開始時，你可以與一名角色拼點，若你贏，該角色將其區域內的各一張牌交給你；若你沒贏，你交給其一張牌。拼點結算後你可以令其
獲得你拼點的牌。
謀識：出牌階段限一次，你可以將一張手牌交給一名角色，若如此做，當其於其下回合的出牌階段內對一名角色造成傷害後，若是此階段其第一次
對該角色造成傷害，你摸一張牌。
]]--
xunchen = sgs.General(extension, "xunchen", "qun2", "3", true)

fenglve = sgs.CreateTriggerSkill{
	name = "fenglve",   
	events = {sgs.Pindian,sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if room:askForSkillInvoke(player, "fenglve_draw", data) then
				if pindian.from:objectName() == player:objectName() and room:getCardPlace(pindian.from_card:getEffectiveId()) == sgs.Player_PlaceTable then
					room:obtainCard(pindian.to, pindian.from_card, false)
				elseif pindian.to:objectName() == player:objectName() and room:getCardPlace(pindian.to_card:getEffectiveId()) == sgs.Player_PlaceTable then
					room:obtainCard(pindian.from, pindian.to_card, false)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isKongcheng() then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then
					local s = room:askForPlayerChosen(player, _targets, "fenglve", "fenglve-invoke", true)
					if s then
						room:broadcastSkillInvoke(self:objectName())
						room:notifySkillInvoked(player, "fenglve")
						room:doAnimate(1, player:objectName(), s:objectName())
						local success = player:pindian(s, "fenglve", nil)
						if success then
							if player:canDiscard(s, "h") then
								local id = room:askForCardChosen(player, s, "h", "fenglve")
								room:obtainCard(player, id, true)
							end
							if player:canDiscard(s, "e") then
								local id = room:askForCardChosen(player, s, "e", "fenglve")
								room:obtainCard(player, id, true)
							end
							if player:canDiscard(s, "j") then
								local id = room:askForCardChosen(player, s, "j", "fenglve")
								room:obtainCard(player, id, true)
							end
						else
							local card2 = room:askForCard(player, ".!", "@liehou-give:" .. s:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
							if card2 then
								room:obtainCard(s, card2, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), s:objectName(), self:objectName(), ""), false)
							end
						end
					end
				end
			end
		end		
	end,
}

moushiCard = sgs.CreateSkillCard{
	name = "moushi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
			room:addPlayerMark(targets[1], "@"..self:objectName().."_flag")
			room:addPlayerMark(targets[1], self:objectName()..source:objectName().."_flag")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
moushiVS = sgs.CreateOneCardViewAsSkill{
	name = "moushi",
	view_filter = function(self, card)
		return not to_select:isEquipped()
	end,
	view_as = function(self, card)
		local moushicard = moushiCard:clone()
		moushicard:addSubcard(card)
		return moushicard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#moushi")
	end
}
moushi = sgs.CreateTriggerSkill{
	name = "moushi",
	events = {sgs.Damage},
	view_as_skill = moushiVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if player:getMark("@"..self:objectName().."_flag") > 0 and damage.to:getMark("moushi_target_Play") > 0 and player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark(self:objectName()..p:objectName().."_flag") > 0 then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					p:drawCards(1, self:objectName())
					room:addPlayerMark(damage.to, "moushi_target_Play")
				end
			end
		end
		return false
	end
}

xunchen:addSkill(fenglve)
xunchen:addSkill(moushi)

sgs.LoadTranslationTable{
	["xunchen"] = "荀諶",
	["&xunchen"] = "荀諶",
	["#xunchen"] = "",
	["fenglve"] = "鋒略",
	[":fenglve"] = "出牌階段開始時，你可以與一名角色拼點，若你贏，該角色將其區域內的各一張牌交給你；若你沒贏，你交給其一張牌。"
	.."拼點結算後你可以令其獲得你拼點的牌。",
	["moushi"] = "謀識",
	[":moushi"] = "出牌階段限一次，你可以將一張手牌交給一名角色，若如此做，當其於其下回合的出牌階段內對一名角色造成傷害後，"..
	"若是此階段其第一次對該角色造成傷害，你摸一張牌。",
	["fenglve_draw"] = "你可以發動“鋒略”",
	["fenglve-invoke"]= "鋒略令其摸牌",
}

--[[
韓猛 群 4體力

截糧 其他角色的摸牌階段開始時，你可以棄置一張牌，令其本回合的摸牌階段摸牌數-1，本回合手牌上限-1。若如此做，若其本回合的棄牌階段結束時有棄牌，你可以從其棄置的牌中選擇一張獲得。

勸酒 鎖定技，你的【酗酒】均視為【殺】，你使用【酗酒】轉化的【殺】不計入【殺】的使用次數。
]]--
hanmeng = sgs.General(extension, "hanmeng", "qun2", "4", true, true)


jieliang = sgs.CreateTriggerSkill{
	name = "jieliang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime,sgs.DrawNCards,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local current = room:getCurrent()
		if event == sgs.DrawNCards then
			if player:getMark("jieliang-Clear") > 0 then
				local count = data:toInt() - player:getMark("jieliang-Clear")
				if count < 0 then
					count = 0
				end
				data:setValue(count)
			end

		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:objectName() ~= player:objectName() then
						local card = room:askForCard(p, "..", "@jieliang:"..current:objectName(), data,sgs.Card_MethodDiscard)
						if card then
							room:addPlayerMark(player,"jieliang-Clear")
							room:addPlayerMark(player,"jieliang"..p:objectName().."-Clear")

						end
					end
				end
			end

		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == current:objectName() and current:getPhase() == sgs.Player_Discard and current:getMark("jieliang"..player:objectName().."-Clear") > 0 and RIGHT(self,player) then
				local ids = sgs.IntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
						ids:append(card_id)
					end
				end
				if not ids:isEmpty() and player:hasSkill("jieliang") then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:fillAG(ids,player)
						local id = room:askForAG(player, ids, true, self:objectName())
						room:clearAG()
						ids:removeOne(id)
						local dummy  = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcard(id)
						room:obtainCard(player,dummy, true)

					end
				end
			end
			return false
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

jieliangMc = sgs.CreateMaxCardsSkill{
	name = "#jieliangMc", 
	frequency = sgs.Skill_Compulsory, 
	extra_func = function(self, target)
		if target:getMark("jieliang-Clear") > 0 then
			return -target:getMark("jieliang-Clear")
		end
	end
}

quanjiu = sgs.CreateFilterSkill{
	name = "quanjiu",
	view_filter = function(self, to_select)
		return to_select:isKindOf("Analeptic") and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName("quanjiu")
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(slash)
		return new
	end
}

quanjiuTM = sgs.CreateTargetModSkill{
	name = "#quanjiuTM",
	pattern = ".",
	residue_func = function(self, from, card)
		if card:getSkillName() == "quanjiu" then
			return n
		end		
	end,
}

hanmeng:addSkill(jieliang)
hanmeng:addSkill(jieliangMc)
hanmeng:addSkill(quanjiu)
hanmeng:addSkill(quanjiuTM)
  

sgs.LoadTranslationTable{
	["hanmeng"] = "韓猛",
	["jieliang"] = "截糧",
	[":jieliang"] = "其他角色的摸牌階段開始時，你可以棄置一張牌，令其本回合的摸牌階段摸牌數-1，本回合手牌上限-1。若如此做，若其本回合的棄牌階段結束時有棄牌，你可以從其棄置的牌中選擇一張獲得。",
	["@jieliang"] = "你可以對 %src 發動“截糧”",
	["quanjiu"] = "勸酒",
	[":quanjiu"] = "鎖定技，你的【酒】均視為【殺】，你使用【酒】轉化的【殺】不計入【殺】的使用次數。",
}

--[[
辛評 群 3體力

輔袁 當你在回合外使用或打出牌時，若當前回合的角色手牌數少於你的手牌數，你可令其摸1張牌；若當前回合的角色手牌數大於等於你，你可以摸1張牌。

忠節 當你死亡時，你可以令一名其他角色增加1點體力上限，回復1點體力，並摸一張牌。

擁嫡 限定技，回合開始時，你可令一名其他男性角色增加1點體力上限並回復1點體力，然後若其武將牌上有主公技，則獲得主公技。
]]--
xinping = sgs.General(extension, "xinping", "qun2", "3", true, true)

fuyuan = sgs.CreateTriggerSkill{
	name = "fuyuan",
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		local current = room:getCurrent()
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
		if card and (not card:isKindOf("SkillCard")) and card:getSkillName() ~= "xiongzhi" and player:getPhase() == sgs.Player_NotActive and current then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				if current:getHandcardNum() < player:getHandcardNum() then
					current:drawCards(1)
				else
					player:drawCards(1)
				end
			end
		end
		return false
	end
}

zhongjie = sgs.CreateTriggerSkill{
	name = "zhongjie", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local death = data:toDeath()		
		if death.who:objectName() == player:objectName() then
			local targets = room:getOtherPlayers(player)			
			if targets:length() > 0 then				
				local target = room:askForPlayerChosen(player, targets, self:objectName(),"zhongjie-invoke",true,true)
				if target then
					room:notifySkillInvoked(player, "zhongjie")
					room:broadcastSkillInvoke("zhongjie")
					room:doSuperLightbox("xinping", "zhongjie")

					room:setPlayerProperty(target,"maxhp",sgs.QVariant(target:getMaxHp()+1))
					local msg = sgs.LogMessage()
					msg.type = "#GainMaxHp"
					msg.from = target
					msg.arg = 1
					room:sendLog(msg)
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(target,recover)
					target:drawCards(1)				
				end
			end
		end
		return false
	end, 
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName())
	end
}

xinping:addSkill(fuyuan)
xinping:addSkill(zhongjie)
xinping:addSkill("yongdi")

sgs.LoadTranslationTable{
	["xinping"] = "辛評",
	["fuyuan"] = "輔袁",
	[":fuyuan"] = "當你在回合外使用或打出牌時，若當前回合的角色手牌數少於你的手牌數，你可令其摸1張牌；若當前回合的角色手牌數大於等於你，你可以摸1張牌。",
	["zhongjie"] = "忠節",
	[":zhongjie"] = "當你死亡時，你可以令一名其他角色增加1點體力上限，回復1點體力，並摸一張牌。",
	["zhongjie-invoke"] = "你可以發動【忠節】",
}


-- 官渡之戰

--[[
十勝十敗：本局遊戲中，使用的第整十張牌，若其不是裝備牌、延時性錦囊，且之前選擇的目標依然符合條件，則在前一次結算完畢後再結算一次
火燒烏巢：本局遊戲中，所有無屬性傷害均視為火屬性傷害
糧草匱乏：本局遊戲中，所有角色摸牌階段摸牌數-1。所有角色使用牌造成傷害後，其摸一張牌（每張牌限一次）
斬顏良誅文丑：本局遊戲中，所有角色回合開始時，需要選擇一名其他角色，視為對其進行決鬥，否則失去一點體力
]]--

GuanduModeEvent5VS = sgs.CreateOneCardViewAsSkill{
	name = "GuanduModeEvent5VS&" ,
	response_or_use = true,
	view_filter = function(self, card)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			end
		else
			return false
		end
	end ,
	view_as = function(self, card)
		if card:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:addSubcard(card)
			jink:setSkillName(self:objectName())
			return jink
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "jink"
	end
}

function choosenewgeneralguandu(source, n)
	local room = source:getRoom()
	local Chosens = {}

	local generals = {}
	if source:getRole() == "loyalist" then
		generals = {"guandumode_xuyou","sp_zhanghe","gaolan","chenlin","jvshou","guandu_chunyuqiong","shenpei","super_liubei",
"tianfeng","xunchen","yuantanyuanshang","lukuangluxiang","xinpi","hanmeng","xinping"}
	elseif source:getRole() == "rebel" then
		generals = {"xunyu","xunyou","guojia_po","ol_xuhuang","zhangliao_po","jsp_guanyu","ol_caoren","ol_caohong",
		"chengyu","liuye","zangba","manchong","litong","hanhaoshihuan_po","zhangxiu","ol_jiaxu"}
	end
	local banned = {}
	local alives = room:getAlivePlayers()
	for _,p in sgs.qlist(alives) do
		if not table.contains(banned, p:getGeneralName()) then
			table.insert(banned, p:getGeneralName())
		end
		if p:getGeneral2() and not table.contains(banned, p:getGeneral2Name()) then
			table.insert(banned, p:getGeneral2Name())
		end
	end
	for i=1, #generals, 1 do
		if table.contains(banned, generals[i]) then
			table.remove(generals, i)
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

nl_guandubattle = sgs.CreateTriggerSkill{
	name = "#nl_guandubattle",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.BuryVictim,sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BuryVictim then
			local death = data:toDeath()
			local reason = death.damage
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
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							local cards = player:getCards("he")
							for _,card in sgs.qlist(cards) do
								dummy:addSubcard(card)
							end
							if cards:length() > 0 then
								local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, killer:objectName())
								room:obtainCard(killer, dummy, reason, false)
							end
							dummy:deleteLater()
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
				room:setPlayerMark(player, "AG_firstplayer", 1)
				room:setPlayerMark(player, "@clock_time", 1)
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
				local cold_lord = 1
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

				local n = math.random(1,7)
				for _, p2 in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p2, "GuanduModeEvent", n)
				end
				local n = player:getMark("GuanduModeEvent")
				room:doSuperLightbox("zuoci","GuanduModeEvent"..n)
				local msg = sgs.LogMessage()
				msg.type = "#GuanduModeEvent"
				msg.from = player
				msg.arg = "GuanduModeEvent"..n
				msg.arg2 = "GuanduModeEvent"..n.."text"
				room:sendLog(msg)


				for _, p in sgs.qlist(_targets) do
					room:setPlayerMark(p, "AG_hasExecuteStart", 1)
					if p:getMark("@LordMark") == 1 then
						if p:getRole() == "rebel" then
							room:changeHero(p,"caocao_po", false,false, false,false)
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))

							room:setPlayerProperty(p,"maxhp",sgs.QVariant(p:getMaxHp()+1))
							room:setPlayerProperty(p,"hp",sgs.QVariant(p:getMaxHp()))
						elseif p:getRole() == "loyalist" then
							room:changeHero(p, "yuanshao_po", false,false, false,false)
							room:setPlayerProperty(p, "hp", sgs.QVariant(p:getMaxHp()))

							room:setPlayerProperty(p,"maxhp",sgs.QVariant(p:getMaxHp()+1))
							room:setPlayerProperty(p,"hp",sgs.QVariant(p:getMaxHp()))
						end
					else
						choosenewgeneralguandu(p, 2)
					end

					if p:getRole() == "rebel" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
					elseif p:getRole() == "loyalist" then
						room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
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
				end
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

				if n == 5 then
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if not p:hasSkill("GuanduModeEvent5VS") then
							room:attachSkillToPlayer(p,"GuanduModeEvent5VS")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,

}

nl_guandubattlerule = sgs.CreateTriggerSkill{
	name = "#nl_guandubattlerule",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished,sgs.Damage,sgs.DamageCaused,sgs.EventPhaseStart,sgs.DrawNCards,},
	on_trigger = function(self, event, player, data, room)
		local lord_player
		for _, pp in sgs.qlist(room:getAlivePlayers()) do
			if pp:isLord() or pp:getMark("@clock_time") > 0 then
				lord_player = pp
				break
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_NotActive and player:getMark("GuanduModeEvent") == 7 and player:getMark("used_slash-Clear") == 0 then
				room:addPlayerMark(player,"GuanduModeEvent7_draw")

			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and player:getMark("GuanduModeEvent")  == 1 then
				if (not use.card:isVirtualCard()) and (not use.card:isKindOf("SkillCard")) then
					if lord_player then
						room:addPlayerMark(lord_player,"@guandu_usedcard_num")
						if (lord_player:getMark("@guandu_usedcard_num") % 10 == 0) and (use.card:isNDTrick() or use.card:isKindOf("BasicCard"))
						  and use.to:length() > 0 then
							local use2 = sgs.CardUseStruct()
							use2.card = use.card
							use2.from = use.from
							for _, p in sgs.qlist(use.to) do
								if (not room:isProhibited(player, p, use.card)) then
									use2.to:append(p)
								end
							end
							if use2.to:length() > 0 then
								room:useCard(use2)
							end
						end
					end
				end
			end
			if player:getMark("GuanduModeEvent")  == 3 then
				if use.card then
					room:setCardFlag(use.card,"-GuanduModeEvent3_draw")
				end
			end
			if player:getMark("GuanduModeEvent")  == 5 then
				if use.card and use.card:getSkillName() == "GuanduModeEvent5VS" then
					room:addPlayerMark(player,"GuanduModeEvent5VS_lun")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if player:getMark("GuanduModeEvent")  == 3 then
				if damage.card and not damage.card:hasFlag("GuanduModeEvent3_draw") then
					player:drawCards(1)
					room:setCardFlag(damage.card,"GuanduModeEvent3_draw")
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.damage > 0 and player:getMark("GuanduModeEvent")  == 2 and damage.nature == sgs.DamageStruct_Normal then
				damage.nature = sgs.DamageStruct_Fire		
				data:setValue(damage)
			end
			if player:getMark("GuanduModeEvent")  == 6 and lord_player:getMark("@clock_time") > 4 then
				if damage.chain or damage.transfer or (not damage.by_user) then return false end
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
					msg.type = "#GuanduModeEvent6"
					msg.from = player
					msg.to:append(damage.to)
					msg.arg = tostring(damage.damage - 1)
					msg.arg2 = tostring(damage.damage)
					room:sendLog(msg)
					data:setValue(damage)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getMark("GuanduModeEvent")  == 4 and player:getPhase() == sgs.Player_RoundStart then
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)

				local _targets  = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if (not room:isProhibited(player, p, duel)) then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then

					local to_duel = room:askForPlayerChosen(player, _targets, "nl_guandubattlerule", "@nl_guandubattlerule4", true)
					if to_duel then
						duel:setSkillName("GuanduModeEvent4")
						local use = sgs.CardUseStruct()
						use.card = duel
						use.from = player
						local dest = to_duel
						use.to:append(dest)
						room:useCard(use)
					else
						room:loseHp(player,1)
					end
				else
					room:loseHp(player,1)
				end
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("GuanduModeEvent")  == 3 then
				local n = data:toInt()
				if  n >= 1 then
					data:setValue(n-1)
				end
			elseif player:getMark("GuanduModeEvent") == 7 and player:getMark("GuanduModeEvent7_draw") > 0 then
				room:setPlayerMark(player,"GuanduModeEvent7_draw",0)
				data:setValue(n+1)
			end
		end
	end,
}

if not sgs.Sanguosha:getSkill("#nl_guandubattle") then skills:append(nl_guandubattle) end
if not sgs.Sanguosha:getSkill("#nl_guandubattlerule") then skills:append(nl_guandubattlerule) end

sgs.LoadTranslationTable{
	["#GuanduModeEvent"] = "本局遊戲特殊規則為 %arg ，內容為 %arg2",
["GuanduModeEvent1"] = "十勝十敗",
["GuanduModeEvent1text"] = "本局遊戲中，使用的第整十張牌，若其不是裝備牌、延時性錦囊，且之前選擇的目標依然符合條件，則在前一次結算完畢後再結算一次",
["GuanduModeEvent2"] = "火燒烏巢",
["GuanduModeEvent2text"] = "本局遊戲中，所有無屬性傷害均視為火屬性傷害",

["GuanduModeEvent3"] = "糧草匱乏",
["GuanduModeEvent3text"] = "本局遊戲中，所有角色摸牌階段摸牌數-1。所有角色使用牌造成傷害後，其摸一張牌（每張牌限一次）",
["GuanduModeEvent4"] = "斬顏良誅文丑",
["GuanduModeEvent4text"] = "本局遊戲中，所有角色回合開始時，需要選擇一名其他角色，視為對其進行決鬥，否則失去一點體力。",
["@nl_guandubattlerule4"] = "你需要選擇一名其他角色，視為對其進行決鬥，否則失去一點體力。",

["GuanduModeEvent5"] = "堅守待戰",
["GuanduModeEvent5text"] = "你可以將一張【殺】當【閃】使用或打出；每輪限一次，你如此做後，你的下個棄牌階段手牌上限-1",
["GuanduModeEvent5VS"] = "堅守",
[":GuanduModeEvent5VS"] = "你可以將一張【殺】當【閃】使用或打出；每輪限一次，你如此做後，你的下個棄牌階段手牌上限-1",
["GuanduModeEvent6"] = "兩軍相持",
["GuanduModeEvent6text"] = "本局遊戲中，遊戲輪數小於等於4時，所有角色每輪手牌上限+1（比如第3輪則手牌上限+3）；輪數大於4時，你於自己的回合內首次使用【殺】造成的傷害+1",
["GuanduModeEvent7"] = "徐圖緩進",
["GuanduModeEvent7text"] = "本局遊戲中，若本回合的出牌階段，你未使用或打出過【殺】，則你下回合的摸牌階段摸牌數+1",

["#GuanduModeEvent6"] = "%from 觸發場地效果 “<font color=\"yellow\"><b>兩軍相持</b></font>”，對 %to 造成傷害由 %arg 點增加到 %arg2 點",

}

GuanduModeMc = sgs.CreateMaxCardsSkill{
	name = "#GuanduModeMc", 
	frequency = sgs.Skill_Compulsory, 
	extra_func = function(self, target)
		if target:getMark("GuanduModeEvent5VS_lun") > 0 then
			return -1
		end

		if target:getMark("GuanduModeEvent") == 6 then
			local lord_player
			for _, pp in sgs.qlist(target:getAliveSiblings()) do
				if pp:isLord() or pp:getMark("@clock_time") > 0 then
					lord_player = pp
					break
				end
			end
			if lord_player and lord_player:getMark("@clock_time") <= 4 then
				return lord_player:getMark("@clock_time")
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("#GuanduModeMc") then skills:append(GuanduModeMc) end

sgs.Sanguosha:addSkills(skills)


