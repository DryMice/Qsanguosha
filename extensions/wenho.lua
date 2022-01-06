module("extensions.wenho", package.seeall)
extension = sgs.Package("wenho")

sgs.LoadTranslationTable{
	["wenho"] = "文和亂武",
}

local skills = sgs.SkillList()

--樊稠
whlw_fanchou = sgs.General(extension, "whlw_fanchou", "qun3", 4, true)

--[[
xingluan = sgs.CreateTriggerSkill{
	name = "xingluan",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecified, sgs.CardFinished, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if event == sgs.TargetSpecified and player:getPhase() == sgs.Player_Play and use.from and use.from:hasSkill(self:objectName()) and use.from:objectName() == player:objectName() and player:getMark(self:objectName().."has_used") == 0 then
			local use_to_count = 0
			for _, p in sgs.qlist(use.to) do
				use_to_count = use_to_count + 1
			end
			if use_to_count == 1 then
				room:addPlayerMark(player, self:objectName())
			end
		elseif event == sgs.CardFinished and player:hasSkill(self:objectName()) then
			if player:getMark(self:objectName()) > 0 and player:getMark(self:objectName().."has_used") == 0 then
				local point_six_card = sgs.IntList()
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):getNumber() == 6 then
						point_six_card:append(id)
					end
				end
				if not point_six_card:isEmpty() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:obtainCard(player, point_six_card:at(math.random(0,point_six_card:length()-1)), false)
					room:removePlayerMark(player, self:objectName())
					room:addPlayerMark(player, self:objectName().."has_used")
					room:broadcastSkillInvoke(self:objectName())
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getMark(self:objectName().."has_used") > 0 then
				room:removePlayerMark(player, self:objectName().."has_used")
			end
		end
		return false
	end
}
]]--

xingluan = sgs.CreateTriggerSkill{
	name = "xingluan",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecified, sgs.CardFinished, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if event == sgs.TargetSpecified and player:getPhase() == sgs.Player_Play and use.from and use.from:hasSkill(self:objectName()) and use.from:objectName() == player:objectName() and player:getMark(self:objectName().."has_used") == 0 then
			room:addPlayerMark(player, self:objectName())
		elseif event == sgs.CardFinished and player:hasSkill(self:objectName()) then
			if player:getMark(self:objectName()) > 0 and player:getMark(self:objectName().."has_used") == 0 then

				local choices = {"xingluan1", "xingluan2", "cancel"}

				local ids = sgs.IntList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					for _, card in sgs.qlist(p:getCards("ej")) do
						if card:getNumber() == 6 then
							ids:append(card:getEffectiveId())
						end
					end
				end
				if ids:length() > 0 then
					table.insert(choices,"xingluan3")
				end	

				local choice = room:askForChoice(player, "xingluan", table.concat(choices, "+"))
				if choice ~= "cancel" then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:removePlayerMark(player, self:objectName())
					room:addPlayerMark(player, self:objectName().."has_used")
					room:broadcastSkillInvoke(self:objectName())
				end
				if choice == "xingluan1" then

					local ids = sgs.IntList()
					for _,id in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(id):getNumber() == 6 then
							ids:append(id)
						end
					end
					local ag_ids = sgs.IntList()
					for i = 1,2,1 do
						if not ids:isEmpty() then
							local id = ids:at(math.random(0,ids:length()-1))
							ag_ids:append(id)
							ids:removeOne(id)
						end
					end

					if not ag_ids:isEmpty() then
						room:fillAG(ag_ids, player)
						local card_id = room:askForAG(player, ag_ids, false, self:objectName())
						if card_id ~= -1 then
							room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
						end
						room:clearAG()
					else
						player:drawCards(1)
					end
				elseif choice == "xingluan2" then
					local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "xingluan", "@xingluan2", true)
					if s then
						if not room:askForCard(s, ".|.|6|.", "@xingluan2_card", sgs.QVariant(), sgs.CardDiscarded) then
							local card = room:askForCard(s, ".!", "@feijun_give", sgs.QVariant(), sgs.Card_MethodNone)
							if card then
								room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, s:objectName(), player:objectName(), self:objectName(), ""))
							end
						end
					end

				elseif choice == "xingluan3" then
					
					if ids:length() > 0 then
						room:fillAG(ids)
						local card_id = room:askForAG(player, ids, true, self:objectName())
						if card_id ~= -1 then
							room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
						end
						room:clearAG()
					end				
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getMark(self:objectName().."has_used") > 0 then
				room:removePlayerMark(player, self:objectName().."has_used")
			end
		end
		return false
	end
}

whlw_fanchou:addSkill(xingluan)

sgs.LoadTranslationTable{
["whlw_fanchou"] = "樊稠",
["#whlw_fanchou"] = "庸生變難",
["xingluan"] = "興亂",
--[":xingluan"] = "出牌階段限一次，當你使用的僅指定一個目標的牌結算完成後，你可以從牌堆裡獲得一張點數為6的牌。",
[":xingluan"] = "出牌階段限一次。當你使用牌結算結束後，你可選擇一項："..
"①觀看牌堆中的兩張點數為6的牌並獲得其中一張（沒有則改為摸一張牌）；"..
"②令一名其他角色棄置一張點數為6的牌或交給你一張牌；"..
"③獲得場上的一張點數為6的牌。",
["$xingluan1"] = "大興兵爭，長安當亂。",
["$xingluan2"] = "勇猛興軍，亂世當立。",
["~whlw_fanchou"] = "唉，稚然疑心，甚重......",
["@xingluan2"] = "選擇一名角色發動興亂②",
["@xingluan2_card"] = "棄置一張點數為6的牌，或交給當前回合角色一張牌",
["xingluan1"] = "觀看牌堆中的兩張點數為6的牌並獲得其中一張（沒有則改為摸一張牌）",
["xingluan2"] = "令一名其他角色棄置一張點數為6的牌或交給你一張牌",
["xingluan3"] = "獲得場上的一張點數為6的牌",
}

--[[
出牌階段限一次。當你使用牌結算結束後，你可選擇一項：
①觀看牌堆中的兩張點數為6的牌並獲得其中一張（沒有則改為摸一張牌）；
②令一名其他角色棄置一張點數為6的牌或交給你一張牌；
③獲得場上的一張點數為6的牌。
]]--

--張濟
whlw_zhangji = sgs.General(extension, "whlw_zhangji", "qun3", 4)
luemingCard = sgs.CreateSkillCard{
	name = "lueming",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getEquips():length() < sgs.Self:getEquips():length() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "@lueming_count")
		local choices = {}
		for i = 1, 13, 1 do
			table.insert(choices, i)
		end
		local choice = room:askForChoice(targets[1], self:objectName(), table.concat(choices, "+"))
		ChoiceLog(targets[1], choice)
		room:setTag("lueming_choose_number",  sgs.QVariant(choice))
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.reason = self:objectName()
		judge.who = source
		room:judge(judge)
		local lueming_judge_number = judge.card:getNumber()
		local log = sgs.LogMessage()
		log.type = "#lueming_judge"
		log.from = source
		if tonumber(choice) == lueming_judge_number then
			log.arg = "#lueming_judge_same"
		else
			log.arg = "#lueming_judge_not_same"
		end
		room:sendLog(log)
		if tonumber(choice) == lueming_judge_number then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 2))
		else
			local loot_cards = sgs.QList2Table(targets[1]:getCards("hej"))
			if #loot_cards > 0 then
				room:obtainCard(source, loot_cards[math.random(1, #loot_cards)], false)
			end
		end
	end
}
lueming = sgs.CreateZeroCardViewAsSkill{
	name = "lueming",
	view_as = function()
		return luemingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lueming")
	end
}
whlw_zhangji:addSkill(lueming)
tunjiunCard = sgs.CreateSkillCard{
	name = "tunjiun",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@tunjiun")
		room:doSuperLightbox("whlw_zhangji","tunjiun")
		local equip_type_table = {"Weapon", "Armor", "DefensiveHorse", "OffensiveHorse", "Treasure"}
			for _, card in sgs.qlist(targets[1]:getCards("e")) do
				if card:isKindOf("Weapon") then
					table.removeOne(equip_type_table, "Weapon")
				elseif card:isKindOf("Armor") then
					table.removeOne(equip_type_table, "Armor")
				elseif card:isKindOf("DefensiveHorse") then
					table.removeOne(equip_type_table, "DefensiveHorse")
				elseif card:isKindOf("OffensiveHorse") then
					table.removeOne(equip_type_table, "OffensiveHorse")
				elseif card:isKindOf("Treasure") then
					table.removeOne(equip_type_table, "Treasure")
				end
			end

			if targets[1]:getMark("@AbolishWeapon") > 0 then
				table.removeOne(equip_type_table, "Weapon")
			end
			if targets[1]:getMark("@AbolishArmor") > 0 then
				table.removeOne(equip_type_table, "Armor")
			end
			if targets[1]:getMark("@AbolishDefensiveHorse") > 0 then
				table.removeOne(equip_type_table, "DefensiveHorse")
			end
			if targets[1]:getMark("@AbolishOffensiveHorse") > 0 then
				table.removeOne(equip_type_table, "OffensiveHorse")
			end
			if targets[1]:getMark("@AbolishTreasure") > 0 then
				table.removeOne(equip_type_table, "Treasure")
			end

		local usable_count = source:getMark("@lueming_count")
		if targets[1]:getEquips():length() + usable_count > 5 then
			usable_count = 5 - targets[1]:getEquips():length()
		end
		while usable_count > 0 and #equip_type_table > 0 do
			local equip_type_index = math.random(1, #equip_type_table)
			local equips = sgs.CardList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf(equip_type_table[equip_type_index]) then
					local equip_index = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()
				 	if targets[1]:getEquip(equip_index) == nil  then
						equips:append(sgs.Sanguosha:getCard(id))
					end
				end
			end
			if not equips:isEmpty() then
				local card = equips:at(math.random(0, equips:length() - 1))
				if not room:isProhibited(targets[1], targets[1], card) then
					room:useCard(sgs.CardUseStruct(card, targets[1], targets[1]))
				end
				usable_count = usable_count - 1
			end
			table.removeOne(equip_type_table, equip_type_table[equip_type_index])
		end
	end
}
tunjiunVS = sgs.CreateZeroCardViewAsSkill{
	name = "tunjiun",
	view_as = function()
		return tunjiunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@tunjiun") > 0 and player:getMark("@lueming_count") > 0
	end
}
tunjiun = sgs.CreateTriggerSkill{
	name = "tunjiun",
	frequency = sgs.Skill_Limited,
	view_as_skill = tunjiunVS,
	limit_mark = "@tunjiun",
	on_trigger = function()
	end
}
whlw_zhangji:addSkill(tunjiun)

sgs.LoadTranslationTable{
["whlw_zhangji"] = "張濟",
["#whlw_zhangji"] = "武威雄豪",
["lueming"] = "掠命",
[":lueming"] = "出牌階段限一次，你選擇一名裝備區裝備少於你的其他角色，令其選擇一個點數，然後你進行判定：若點數相同，你對其造成2點傷害；不同，你隨機獲得其區域內的一張牌。",
["#lueming_judge_same"] = "點數相同",
["#lueming_judge_not_same"] = "點數不同",
["#lueming_judge"] = "%from 執行掠命的判定結果為 %arg",
["$lueming1"] = "劫命掠財，毫不費力。",
["$lueming2"] = "人財，皆掠之，嘿嘿。",
["tunjiun"] = "屯軍",
[":tunjiun"] = "限定技，出牌階段，你可以選擇一名角色，令其隨機使用牌堆中的X張不同類型的裝備牌（不替換原有裝備，X為你發動“掠命”的次數）",
["$tunjiun1"] = "得封侯爵，屯軍弘農。",
["$tunjiun2"] = "屯軍弘農，養精蓄銳。",
["~whlw_zhangji"] = "哪裡來的亂箭？",
}
--郭汜
whlw_guosi = sgs.General(extension, "whlw_guosi", "qun3", 4)

tanbeiCard = sgs.CreateSkillCard{
	name = "tanbei",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local choices = {"tanbei_unlimited_use"}
		local loot_cards = sgs.QList2Table(targets[1]:getCards("hej"))
		if #loot_cards > 0 then
			table.insert(choices, "tanbei_give_card")
		end
		local choice = room:askForChoice(targets[1], self:objectName(), table.concat(choices, "+"))
		ChoiceLog(targets[1], choice)
		if choice == "tanbei_give_card" then
			if #loot_cards > 0 then
				room:obtainCard(source, loot_cards[math.random(1, #loot_cards)], false)
			end
			room:addPlayerMark(source, "juzhanFrom-Clear")
			room:addPlayerMark(targets[1], "juzhanTo-Clear")
		elseif choice == "tanbei_unlimited_use" then

			room:addPlayerMark(source, "kill_caocao-Clear")
			room:addPlayerMark(targets[1], "be_killed-Clear")
			local assignee_list = source:property("extra_slash_specific_assignee"):toString():split("+")

			table.insert(assignee_list, targets[1]:objectName())

			room:setPlayerProperty(source, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
			room:setFixedDistance(source, targets[1], 1);
		end
	end
}
tanbei = sgs.CreateZeroCardViewAsSkill{
	name = "tanbei",
	view_as = function()
		return tanbeiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tanbei")
	end,
}

whlw_guosi:addSkill(tanbei)

cidao = sgs.CreateTriggerSkill{
	name = "cidao",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = cidaoVS,
	events = {sgs.CardFinished, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") and use.from and use.from:hasSkill(self:objectName()) and use.to then
				local has_used_cidao_to_other = false
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("cidao_target") > 0 then
						has_used_cidao_to_other = true
					end
				end
				for _, p in sgs.qlist(use.to) do
					if p:objectName() ~= use.from:objectName() then
						if p:getMark("cidao_target") == 0 and has_used_cidao_to_other then
							for _, pp in sgs.qlist(room:getAlivePlayers()) do
								if pp:getMark("cidao_target") > 0 then
									room:setPlayerMark(pp, "cidao_target", 0)
								end
							end
						end
						room:addPlayerMark(p, "cidao_target")
					else
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark("cidao_target") > 0 then
								room:setPlayerMark(p, "cidao_target", 0)
							end
						end
					end
				end
				for _, p in sgs.qlist(use.to) do
					if p:getMark("cidao_target") > 1 and use.from:distanceTo(p) == 1 and not (p:isNude() and p:getCards("j"):isEmpty()) then
						if not use.card:isKindOf("SkillCard") and not (use.card:isKindOf("Snatch") and use.card:getSkillName() == "cidao") and use.from:getMark("has_use_cidao") == 0 then
							local card = room:askForCard(use.from, ".|.|.|hand", "@cidao", sgs.QVariant(), sgs.Card_MethodNone)
							if card then
								local snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
								snatch:addSubcard(card:getEffectiveId())
								snatch:setSkillName(self:objectName())
								room:useCard(sgs.CardUseStruct(snatch, use.from, p))
								room:addPlayerMark(use.from, "has_use_cidao")
								for _, pp in sgs.qlist(room:getAlivePlayers()) do
									if pp:getMark("cidao_target") > 0 then
										room:setPlayerMark(pp, "cidao_target", 0)
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("cidao_target") > 0 then
					room:setPlayerMark(p, "cidao_target", 0)
				end
			end
			room:removePlayerMark(player, "has_use_cidao")
		end
		return false
	end
}
whlw_guosi:addSkill(cidao)

sgs.LoadTranslationTable{
["whlw_guosi"] = "郭汜",
["#whlw_guosi"] = "黨豺為虐",
["tanbei"] = "貪狽",
[":tanbei"] = "出牌階段限一次，你可以令一名其他角色選擇一項：1.令你隨機獲得其區域內的一張牌，此回合不能再對其使用牌；2.令你此回合對其使用牌沒有次數和距離限制。",
["$tanbei1"] = "此機，我怎麼會錯失。",
["$tanbei2"] = "你的東西，現在是我的了！",
["tanbei_give_card"] = "隨機獲得你區域內的一張牌，此回合不能再對你使用牌",
["tanbei_unlimited_use"] = "對你使用牌沒有次數和距離限制",
["cidao"] = "伺盜",
[":cidao"] = "出牌階段限一次，當你對一名其他角色連續使用兩張牌後，你可將一張手牌當【順手牽羊】對其使用（目標須合法）。",
["@cidao"] = "你可將一張手牌當【順手牽羊】對其使用",
["$cidao1"] = "連發伺動，順手可得。",
["$cidao2"] = "伺機而劫，此地可竊。",
["~whlw_guosi"] = "伍習，你......",
}
--李傕
whlw_lijue = sgs.General(extension, "whlw_lijue", "qun3", 6, true)

langxi = sgs.CreatePhaseChangeSkill{
	name = "langxi", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() <= player:getHp() and p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "langxi-invoke", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local damage_num = math.random(0,2)
				if damage_num > 0 then
					room:damage(sgs.DamageStruct(self:objectName(), player, target, damage_num))
				end
			end
		end
	end
}
whlw_lijue:addSkill(langxi)

yisuan = sgs.CreateTriggerSkill{
	name = "yisuan",
	events = {sgs.BeforeCardsMove, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local invoke = false
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
					invoke = true
				end
			end
			local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if player:getPhase() == sgs.Player_Play and move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and extract == sgs.CardMoveReason_S_REASON_USE and invoke and player:getMark("has_use_yisuan") == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:loseMaxHp(player)
				for _,id in sgs.qlist(move.card_ids) do
					move.from_places:removeAt(listIndexOf(move.card_ids, id))
					move.card_ids:removeOne(id)
					data:setValue(move)
					room:obtainCard(player, sgs.Sanguosha:getCard(id), true)
				end
				room:addPlayerMark(player, "has_use_yisuan")
			end
		elseif event == sgs.EventPhaseEnd then
			room:removePlayerMark(player, "has_use_yisuan")
		end
		return false
	end
}
whlw_lijue:addSkill(yisuan)

sgs.LoadTranslationTable{
["whlw_lijue"] = "李傕",
["#whlw_lijue"] = "奸謀惡勇",
["langxi"] = "狼襲",
[":langxi"] = "準備階段，你可以對一名體力小於或等於你的其他角色造成0-2點隨機傷害。",
["langxi-invoke"] = "你可以對一名體力小於或等於你的其他角色造成0-2點隨機傷害<br/> <b>操作提示</b>: 選擇一名體力小於或等於你且與你不同的角色→點擊確定<br/>",
["$langxi1"] = "襲奪之勢，如狼噬骨。",
["$langxi2"] = "引吾至此，怎能不襲掠之？",
["yisuan"] = "亦算",
[":yisuan"] = "出牌階段限一次，當你使用的錦囊牌進入棄牌堆時，你可以減1點體力上限，從棄牌堆獲得之。",
["$yisuan1"] = "吾亦能善算謀劃。",
["$yisuan2"] = "算計人心，我也可略施一二。",
["~whlw_lijue"] = "若無內訌，也不至如此。",
}

--徐榮
xurong = sgs.General(extension, "xurong", "qun3", "4", true)

xionghuo_Prohibit = sgs.CreateProhibitSkill{
	name = "#xionghuo_Prohibit", 
	is_prohibited = function(self, from, to, card)
		return from:getMark("xionghuo_from-Clear") > 0 and to:getMark("xionghuo_to-Clear") > 0 and card:isKindOf("Slash")
	end
}

xionghuo_Maxcards = sgs.CreateMaxCardsSkill{
	name = "xionghuo_Maxcards",
	extra_func = function(self, target)
		local n = 0
		if target:getMark("xionghuo_debuff-Clear") > 0 then
			n = n - target:getMark("xionghuo_debuff-Clear")
		end
		return n
	end
}

if not sgs.Sanguosha:getSkill("#xionghuo_Prohibit") then skills:append(xionghuo_Prohibit) end
if not sgs.Sanguosha:getSkill("xionghuo_Maxcards") then skills:append(xionghuo_Maxcards) end

--[[
	技能：【凶镬】游戏开始时，你获得3枚“暴戾”标记；出牌阶段，你可以交给一名其他角色1枚“暴戾”标记；当你对其他角色造成伤害时，若其有“暴戾”标记，此伤害+1；
				  其他角色的出牌阶段开始时，若其有“暴戾”标记，其移去所有“暴戾”标记并随机选择一项：1.受到你对其造成的1点火焰伤害，且此回合其使用【杀】不能指定你为目标；
				  2.失去1点体力，且此回合其手牌上限-1；3.你随机获得其手牌和装备区里的各一张牌。
]]--
xionghuoCard = sgs.CreateSkillCard{
	name = "xionghuo" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		effect.from:loseMark("@brutal")
		effect.to:gainMark("@brutal")
	end
}
xionghuoVS = sgs.CreateZeroCardViewAsSkill{
	name = "xionghuo",
	view_as = function()
		return xionghuoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@brutal") > 0
	end
}
xionghuo = sgs.CreateTriggerSkill{
	name = "xionghuo",
	view_as_skill = xionghuoVS,
	events = {sgs.GameStart, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:setPlayerMark(player,"@brutal", 3)
		else
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() ~= player:objectName() and damage.to:getMark("@brutal") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end
}
xionghuo_forPlay = sgs.CreatePhaseChangeSkill{
	name = "#xionghuo_forPlay",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local invoke, sources = not player:hasSkill("xionghuo"), sgs.SPlayerList()
		if player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:findPlayersBySkillName("xionghuo")) do
				if p:objectName() ~= player:objectName() then
					invoke = true
					sources:append(p)
				end
			end
			if invoke and not sources:isEmpty() then
				if sources:length() > 1 then
					room:sortByActionOrder(sourses)
				end
				local source = sources:first()
				room:sendCompulsoryTriggerLog(source, "xionghuo")
				room:broadcastSkillInvoke("xionghuo")
				player:loseAllMarks("@brutal")
				local ranNum = math.random(1, 3)
				local log = sgs.LogMessage()
				log.type = "#xionghuo_log"
				log.from = player
				if ranNum == 1 then
					--ChoiceLog(player, "xionghuo_choice1")
					log.arg = "xionghuo_choice1"
					room:sendLog(log)
					room:doAnimate(1, source:objectName(), player:objectName())
					room:damage(sgs.DamageStruct(self:objectName(), source, player, 1, sgs.DamageStruct_Fire))
					room:setPlayerMark(player, "xionghuo_from-Clear", 1)
					room:setPlayerMark(source, "xionghuo_to-Clear", 1)
				elseif ranNum == 2 then
					--ChoiceLog(player, "xionghuo_choice2")
					log.arg = "xionghuo_choice2"
					room:sendLog(log)
					room:loseHp(player)
					room:addPlayerMark(player, "xionghuo_debuff-Clear")
				else
					--ChoiceLog(player, "xionghuo_choice3")
					log.arg = "xionghuo_choice3"
					room:sendLog(log)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					if player:hasEquip() then
						local equip = player:getEquips():at(math.random(0, player:getEquips():length() - 1))
						dummy:addSubcard(equip:getEffectiveId())
					end
					if not player:isKongcheng() then
						local hand = player:getCards("h"):at(math.random(0, player:getCards("h"):length() - 1))	
						dummy:addSubcard(hand:getEffectiveId())
					end
					if dummy:subcardsLength() > 0 then
						room:obtainCard(source, dummy, false)
					end
					dummy:deleteLater()
				end
			end
		elseif player:getPhase() == sgs.Player_Discard then
			room:removePlayerMark(player, "xionghuo_debuff-Clear")
			room:removePlayerMark(player, "xionghuo_from-Clear")
		end
	end,
	can_trigger = function(self, target)
		return target and target:getMark("@brutal") > 0
	end
}
xurong:addSkill(xionghuo)
xurong:addSkill(xionghuo_forPlay)
extension:insertRelatedSkills("xionghuo", "#xionghuo_forPlay")
-- 技能：【杀绝】锁定技，当其他角色进入濒死状态时，若其体力值小于0，你获得1枚“暴戾”标记，然后若其因牌造成的伤害而进入濒死状态，你获得此牌。 --
shajue = sgs.CreateTriggerSkill{
	name = "shajue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
		local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
		room:sortByActionOrder(players)
		for _, p in sgs.qlist(players) do
			if player:getHp() < 0 then
				room:sendCompulsoryTriggerLog(p, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				p:gainMark("@brutal")
				local card = dying.damage.card
				if card then
					local id = card:getEffectiveId()
					if room:getCardPlace(id) == sgs.Player_PlaceTable then
						room:obtainCard(p, card)
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
xurong:addSkill(shajue)


sgs.LoadTranslationTable{
["xurong"] = "徐榮",
["&xurong"] = "徐榮",
["#xurong"] = "魔王之腕",
["xionghuo"] = "兇鑊",
[":xionghuo"] = "遊戲開始時，你獲得3枚“暴戾”標記；出牌階段，你可以交給一名其他角色1枚“暴戾”標記；當你對其他角色造成傷害時，若其有“暴戾”標記，此傷害+1；其他角色的出牌階段開始時，若其有“暴戾”標記，其移去所有“暴戾”標記並隨機選擇一項：1.受到你對其造成的1點火焰傷害，且此回合其使用【殺】不能指定你為目標；2.失去1點體力，且此回合其手牌上限-1；3.你隨機獲得其手牌和裝備區裡的各一張牌。",
["$xionghuo1"] = "此鑊加之於你，定有所傷！",
["$xionghuo2"] = "兇鑊沿襲，怎會輕易無傷？",
["@brutal"] = "暴戾",
["xionghuo_choice1"] = "受到你對其造成的1點火焰傷害，且此回合其使用【殺】不能指定你為目標",
["xionghuo_choice2"] = "失去1點體力，且此回合其手牌上限-1",
["xionghuo_choice3"] = "你隨機獲得其手牌和裝備區裡的各一張牌",
["#xionghuo_log"] = "%from 的兇鑊效果為 %arg",
["shajue"] = "殺絕",
[":shajue"] = "鎖定技，當其他角色進入瀕死狀態時，若其體力值小於0，你獲得1枚“暴戾”標記，然後若其因牌造成的傷害而進入瀕死狀態，你獲得此牌。",
["$shajue1"] = "殺伐決絕，不留後患。",
["$shajue2"] = "吾既出，必絕之！",
["~xurong"] = "此生無悔，心中無愧！",
}

--張邈
zhangmiao = sgs.General(extension,"zhangmiao","qun3","4",true)

--謀逆
mouniCard = sgs.CreateSkillCard{
	name = "mouni",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("mouni")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source,"mouni_has_used-Clear")
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local n = 0
			for _,card in sgs.qlist(source:getHandcards()) do
				--if card and card:isKindOf("Slash") and p:canSlash(player, card, true) then
				if card and card:isKindOf("Slash") and not source:isProhibited(targets[1], card) and targets[1]:isAlive() then
					card:setSkillName("mouni")
					--room:useCard(sgs.CardUseStruct(card, source, targets[1]), true)

					local use = sgs.CardUseStruct()
					use.card = card
					use.from = source
					local dest = targets[1]
					use.to:append(dest)
					room:useCard(use)

					n = n + 1
					room:getThread():delay()
				end
			end

			if source:getMark("mouni_card_has_damage_card_num") < n then
				room:addPlayerMark(source,"skip_play")
				room:addPlayerMark(source,"skip_discard")
				room:addPlayerMark(source,"mouni_can_not_wake-Clear")						
			end

			room:setPlayerMark(source,"mouni_card_has_damage_card_num",0)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end,
}
mouniVS = sgs.CreateZeroCardViewAsSkill{
	name = "mouni",
	view_as = function()
		return mouniCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@mouni"
	end
}
mouni = sgs.CreateTriggerSkill{
	name = "mouni",
	view_as_skill = mouniVS,
	events = {sgs.EventPhaseChanging, sgs.Damage, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local can_invoke = false
			if change.to == sgs.Player_Start then
				for _,card in sgs.qlist(player:getHandcards()) do
					if card and card:isKindOf("Slash") then
						can_invoke = true
					end
				end
				if can_invoke then
					room:askForUseCard(player, "@@mouni", "@mouni")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "mouni" then
				room:addPlayerMark(player,"mouni_card_has_damage_card_num")	
				--room:addPlayerMark(player,"@mouni_card_has_damage_card_num")	
				

--[[
				if player:getMark("mouni_can_not_wake-Clear") == 0 then
					room:addPlayerMark(player,"skip_play")
					room:addPlayerMark(player,"skip_discard")
					room:addPlayerMark(player,"mouni_can_not_wake-Clear")
					
				end
				]]--

			end
		end
	end
}

mounitm = sgs.CreateTargetModSkill{
	name = "#mounitm",
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		if card:getSkillName() == "mouni" then
			return 1000
		end
	end
}

--縱反

zongfanCard = sgs.CreateSkillCard{
	name = "zongfanCard",
	will_throw = false,
	target_fixed = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "zongfan","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		room:setPlayerMark(source,"zongfan_give_num",self:getSubcards():length())
	end
}
zongfanVS = sgs.CreateViewAsSkill{
	name = "zongfan" ,
	response_pattern = "@@zongfan",
	n = 999 ,
	view_filter = function(self, selected, to_select)
		--return (not to_select:isEquipped()) and (not sgs.Self:isJilei(to_select))
		return true
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = zongfanCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}

zongfan = sgs.CreatePhaseChangeSkill{
	name = "zongfan",
	frequency = sgs.Skill_Wake,
	view_as_skill = zongfanVS,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:broadcastSkillInvoke("zongfan")
		room:setPlayerMark(player, self:objectName(), 1)
		room:doSuperLightbox("zhangmiao","zongfan")	
		room:recover(player, sgs.RecoverStruct(player))

		room:askForUseCard(player, "@@zongfan", "@zongfan", -1)

		room:detachSkillFromPlayer(player, "mouni")
		room:acquireSkill(player, "zhangu")

		local n = player:getMark("zongfan_give_num")
		room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp() + n))
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = n
		room:recover(player, recover)

		return false
	end ,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getPhase() == sgs.Player_Finish 
		and target:getMark(self:objectName()) == 0 and
		 ((target:getMark("mouni_has_used-Clear") > 0 and target:getMark("has_skipped_play-Clear") == 0) or target:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0)
	end
}

--戰孤
zhangu = sgs.CreateTriggerSkill{
	name = "zhangu" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if (player:getHandcardNum() == 0 or player:getEquips():length() == 0) and player:getMaxHp() > 1 then
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:loseMaxHp(player)
				local GetCardList = sgs.IntList()
				local get_pattern = {}
				for i = 1,3,1 do
					local DPHeart = sgs.IntList()
					if room:getDrawPile():length() > 0 then
						for _, id in sgs.qlist(room:getDrawPile()) do
							local card = sgs.Sanguosha:getCard(id)
							if not table.contains(get_pattern, card:getTypeId() ) then
								DPHeart:append(id)
							end
						end
					end
					if DPHeart:length() ~= 0 then
						local get_id = DPHeart:at(math.random(1,DPHeart:length())-1)
						GetCardList:append(get_id)

						local card = sgs.Sanguosha:getCard(get_id)
						table.insert(get_pattern, card:getTypeId() )
					end
				end
				if GetCardList:length() ~= 0 then
					local move = sgs.CardsMoveStruct()
					move.card_ids = GetCardList
					move.to = player
					move.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(move, true)
				end
			end	
		end
	end
}

zhangmiao:addSkill(mouni)
zhangmiao:addSkill(mounitm)
zhangmiao:addSkill(zongfan)
zhangmiao:addRelateSkill("zhangu")

extension:insertRelatedSkills("mouni","#mounitm")

if not sgs.Sanguosha:getSkill("zhangu") then skills:append(zhangu) end

sgs.LoadTranslationTable{
["zhangmiao"] = "張邈",
["mouni"] = "謀逆",
["_mouni"] = "謀逆",
[":mouni"] = "準備階段，你可對一名其他角色依次使用你手牌中所有的【殺】（若其進入了瀕死狀態，則終止此流程）。然後若這些【殺】中有未造成傷害的【殺】，則你跳過本回合的出牌階段與棄牌階段。",
["@mouni"] = "你可對一名其他角色依次使用你手牌中所有的【殺】。",
["~mouni"] = "選擇一名角色→點擊確定",
["zongfan"] = "縱反",
[":zongfan"] = "覺醒技，結束階段，若你本回合內因〖謀逆〗使用過【殺】且未跳過本回合的出牌階段，則你將任意張牌交給一名其他角色，然後加X點體力上限並回復X點體力（X為你以此法給出的牌數）。最後失去〖謀逆〗並獲得〖戰孤〗。",
["@zongfan"] = "你可以交給其他角色任意張牌。",
["~zongfan"] = "選擇若干牌→選擇一名角色→點擊確定",
["zhangu"] = "戰孤",
[":zhangu"] = "鎖定技，準備階段，若你的體力上限大於1且沒有手牌/裝備區內沒有牌，則你減1點體力上限，然後從牌堆中獲得三張類型不同的牌。",
}

--段煨
duanwei = sgs.General(extension,"duanwei","qun3","4",true)

langmie = sgs.CreateTriggerSkill{
	name = "langmie", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd},  
	on_trigger = function(self, event, player, data, room) 	
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			if player:getMark("used_cardtype1-Clear") > 1 or player:getMark("used_cardtype2-Clear") > 1 or
			  player:getMark("used_cardtype3-Clear") > 1 then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if room:askForSkillInvoke(p,"langmie",data) then
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(1)
					end
				end
			end

			if player:getMark("damage_record-Clear") >= 2 then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:canDiscard(p, "h") and room:askForCard(p, "..", "@langmie", data, self:objectName()) then
						room:notifySkillInvoked(p, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:damage(sgs.DamageStruct(self:objectName(), p, player, 1 ))
					end	
				end
			end
		end
		return false
	end, 
	can_trigger = function(self,target)
		return target
	end
}

duanwei:addSkill(langmie)

sgs.LoadTranslationTable{
["duanwei"] = "段煨",
["langmie"] = "狼滅",
[":langmie"] = "其他角色的出牌階段結束時，若其本階段內使用過的牌中有相同類型的牌，則你可以"
.."摸一張牌；若其本階段內一造成超過1點的傷害，則你可以棄置一張牌並對其造成1點傷害。",
["@langmie"] = "你可以棄置一張牌，並對其造成1點傷害",
}

--梁興
liangxing = sgs.General(extension,"liangxing","qun3","4",true)
--擄掠
lulve = sgs.CreatePhaseChangeSkill{
	name = "lulve", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() <= player:getHandcardNum() and p:objectName() ~= player:objectName() and p:getHandcardNum() > 0 then
					players:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "lulve-invoke", true, true)
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local choice = room:askForChoice(target, self:objectName(), "lulve1+lulve2")
				if choice == "lulve1" then
					room:obtainCard(player, target:wholeHandCards(), false)
					player:turnOver()
				elseif choice == "lulve2" then
					target:turnOver()
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("_ol_sidi")
					room:useCard(sgs.CardUseStruct(slash, target, player))
				end
			end
		end
	end
}

--追襲
lxzhuixi = sgs.CreateTriggerSkill{
	name = "lxzhuixi",
	events = {sgs.DamageForseen},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from:hasSkill("lxzhuixi") or damage.to:hasSkill("lxzhuixi") then
			local player_card = {}
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				table.insert(player_card, p:getHandcardNum())
			end
			if damage.from:faceUp() ~= damage.to:faceUp() and (damage.from:hasSkill("lxzhuixi") or damage.to:hasSkill("lxzhuixi")) then
				if damage.from:hasSkill("lxzhuixi") then
					room:sendCompulsoryTriggerLog(damage.from, "lxzhuixi")
				elseif damage.to:hasSkill("lxzhuixi") then
					room:sendCompulsoryTriggerLog(damage.to, "lxzhuixi")
				end

				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				if damage.from:hasSkill("lxzhuixi") then
					room:broadcastSkillInvoke(self:objectName(),2)
					msg.type = "#lxzhuixi1"
 				elseif damage.to:hasSkill("lxzhuixi") then
					room:broadcastSkillInvoke(self:objectName(),1)
					msg.type = "#lxzhuixi2"
				end

				if damage.from:hasSkill("lxzhuixi")then
					msg.from = damage.from
					msg.to:append(damage.to)
 				elseif damage.to:hasSkill("lxzhuixi") then
 					msg.from = damage.to
					msg.to:append(damage.from)
				end
				msg.arg = tostring(damage.damage - 1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)
				data:setValue(damage)		
			end
		end
	end,
}

liangxing:addSkill(lulve)
liangxing:addSkill(lxzhuixi)

sgs.LoadTranslationTable{
["liangxing"] = "梁興",
["lulve"] = "擄掠",
[":lulve"] = "出牌階段開始時，你可選擇一名有手牌且手牌數少於你的角色。其選擇一項：①將所有手牌交給你，然後你將武將牌翻面。②將武將牌翻面，然後其視為對你使用一張【殺】。",
["lulve-invoke"] = "你可以發動「擄掠」",
["lulve1"] = "將所有手牌交給你，然後你將武將牌翻面。",
["lulve2"] = "將武將牌翻面，然後其視為對你使用一張【殺】。",
["lxzhuixi"] = "追襲",
[":lxzhuixi"] = "鎖定技，當你造成傷害或受到傷害時，若受傷角色的翻面狀態和傷害來源的翻面狀態不同，則此傷害+1。",
["#lxzhuixi1"] = "%from 的技能“<font color=\"yellow\"><b>追襲</b></font>”被觸發，對 %to 造成的傷害由 %arg 點增加到"..
"%arg2 點",
["#lxzhuixi2"] = "%from 的技能“<font color=\"yellow\"><b>追襲</b></font>”被觸發，%to 對 %from 造成的傷害由 %arg 點增加到"..
"%arg2 點",
}


sgs.Sanguosha:addSkills(skills)
