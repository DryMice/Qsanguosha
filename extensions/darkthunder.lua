module("extensions.darkthunder", package.seeall)
extension = sgs.Package("darkthunder")

sgs.LoadTranslationTable{
	["darkthunder"] = "陰包&雷包",
}

local skills = sgs.SkillList()

--王基
wangji = sgs.General(extension, "wangji", "wei2", "3", true)
--奇制
qizhi = sgs.CreateTriggerSkill{
	name = "qizhi",
	frequency = sgs.Skill_Frequency,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.card:getTypeId() ~= sgs.Card_TypeSkill and player:getPhase() ~= sgs.Player_NotActive then
				if use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") then 
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if player:canDiscard(p, "he") and (not use.to:contains(p)) then _targets:append(p) end
					end
					if not _targets:isEmpty() then
						local to_discard = room:askForPlayerChosen(player, _targets, "qizhi", "@qizhi-invoke", true)
						if to_discard then
							room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
							room:throwCard(room:askForCardChosen(player, to_discard, "he", "qizhi", false, sgs.Card_MethodDiscard), to_discard, player)
							room:drawCards(to_discard, 1, "qizhi")
							player:gainMark("@qizhi-Clear", 1)
						end
					end
				end
			end
		end
	end,
}
jinqu = sgs.CreateTriggerSkill{
	name = "jinqu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local phase = change.to
		if phase ==  sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, "jinqu", data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
				room:drawCards(player, 2, "jinqu")
				local n = player:getHandcardNum()
				local n2 = n - player:getMark("@qizhi-Clear")
				if n2 > 0 then
					room:askForDiscard(player, "jinqu", n2, n2, false, false)
				end
			end
		end
	end
}
wangji:addSkill(qizhi)
wangji:addSkill(jinqu)
sgs.LoadTranslationTable{
	["wangji"] = "王基",
	["#wangji"] = "經行合一",
	["qizhi"] = "奇制",
	[":qizhi"] = "當你於回合內使用基本牌或錦囊牌指定目標後，你可以選擇一名不是此牌目標的角色，棄置其一張牌，然後其摸一張牌。",
	["@qizhi-invoke"] = "你可以發動“奇制”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	["@qizhi-Clear"] = "奇制",
	["jinqu"] = "進趨",
	[":jinqu"] = "結束階段開始時，你可以摸兩張牌，然後將手牌棄至X張（X為此回合內你發動“奇制”的次數）。",
	["$qizhi1"] = "聲東擊西，敵寇，一網成擒！",
	["$qizhi2"] = "吾意不在此地，已遣別部出發。",
	["$jinqu1"] = "建上昶水城，以逼夏口！",
	["$jinqu2"] = "通川聚糧，伐吳之業，當步步為營。",
}
--周妃 女, 吳,  3  體力
zhoufei = sgs.General(extension,"zhoufei","wu2","3",false)
--〖良姻〗 當有牌移出遊戲時，你可以令手牌數大於你的一名角色摸一張牌；當有牌從遊戲外加入任意角色的手牌時，你可以令手牌數小於你的一名角色棄置一張牌。
liangyin = sgs.CreateTriggerSkill{
	name = "liangyin",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if not room:getTag("FirstRound"):toBool() then
			if (move.to_place == sgs.Player_PlaceSpecial) or (move.to_place == sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_PlaceSpecial)) and (not room:getTag("FirstRound"):toBool()) then
				if move.to_place == sgs.Player_PlaceSpecial then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getHandcardNum() > player:getHandcardNum() then _targets:append(p) end
					end
					if not _targets:isEmpty() then
						local s = room:askForPlayerChosen(player, _targets, "liangyin", "@liangyin-draw", true)
						if s then
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:doAnimate(1, player:objectName(), s:objectName())
							s:drawCards(1)
						end
					end
				elseif move.to_place == sgs.Player_PlaceHand then
					local _targets2 = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getHandcardNum() < player:getHandcardNum() then _targets2:append(p) end
					end
					if not _targets2:isEmpty() then
						local s = room:askForPlayerChosen(player, _targets2, "liangyin", "@liangyin-discard", true)
						if s then
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:doAnimate(1, player:objectName(), s:objectName())
							room:askForDiscard(s, "liangyin", 1, 1, false, true)
						end
					end
				end
			end
		end
	end
}
--〖箜聲〗 準備階段，你可以將任意張牌置於武將牌上。結束階段，你使用武將牌上的裝備牌，並獲得武將牌上的其他牌。 
kongshengCard = sgs.CreateSkillCard{
	name = "kongsheng" ,
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:addToPile("music", self:getSubcards())
	end
}
kongshengVS = sgs.CreateViewAsSkill{
	name = "kongsheng" ,
	n = 999 ,
	response_pattern = "@@kongsheng",
	view_filter = function(self, cards, to_select)
		return true
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = kongshengCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}
kongsheng = sgs.CreateTriggerSkill{
	name = "kongsheng",
	view_as_skill = kongshengVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ==  sgs.Player_Start then
			room:askForUseCard(player, "@@kongsheng", "@kongsheng")
		elseif phase ==  sgs.Player_Finish then
			local id2s = sgs.IntList()
			local id3s = sgs.IntList()
			if player:getPile("music"):length() > 0 then
				local n = player:getPile("music"):length()
				for i = 1, n,1 do
					local ids = player:getPile("music")
					local id = ids:at(i-1)
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("EquipCard") then
						id3s:append(card:getEffectiveId())
					else
						id2s:append(card:getEffectiveId())
					end
				end
				local n2 = id3s:length()
				if n2 > 0 then
					for i = 1, n2,1 do
						local id = id3s:at(i-1)
						local card = sgs.Sanguosha:getCard(id)
						local use = sgs.CardUseStruct()
						use.card = card
						use.from = player
						room:useCard(use)
					end
				end
				local move = sgs.CardsMoveStruct()
				move.card_ids = id2s
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move, true)
			end
		end
	end
} 
zhoufei:addSkill(liangyin)
zhoufei:addSkill(kongsheng)

sgs.LoadTranslationTable{
	["zhoufei"] = "周妃",
	["#zhoufei"] = "軟玉溫香",
	["liangyin"] = "良姻",
	[":liangyin"] = "當有牌移出遊戲時，你可以令手牌數大於你的一名角色摸一張牌；當有牌從遊戲外加入任意角色的手牌時，你可以令手牌數小於你的一名角色棄置一張牌。",
	["kongsheng"] = "箜聲",
	[":kongsheng"] = "準備階段，你可以將任意張牌置於武將牌上。結束階段，你使用武將牌上的裝備牌，並獲得武將牌上的其他牌",
	["@liangyin-draw"] = "你可以令手牌數大於你的一名角色摸一張牌",
	["@liangyin-discard"] = "你可以令手牌數小於你的一名角色棄置一張牌",
	["@kongsheng"] = "你可以將任意張牌置於武將牌上。若如此做，結束階段，你使用武將牌上的裝備牌，並獲得武將牌上的其他牌",
	["~kongsheng"] = "點選欲放置於武將牌上的牌(包含裝備牌) -> 點擊「確定」",
	["music"] = "聲",
	["$liangyin1"] = "结得良姻，固吴基业。",
	["$liangyin2"] = "君恩之命，妾身良姻之福。",
	["$kongsheng1"] = "窈窕淑女，箜篌友之。",
	["$kongsheng2"] = "箜篌声声，琴瑟鸣鸣。",
	["~zhoufei"] = "夫君，妾身再也不能，陪你看这江南翠绿了……",
}
-- 陰 陸績 男, 吳,  3  體力
luji = sgs.General(extension,"luji","wu2","3",true)
--〖懷橘〗 鎖定技，遊戲開始時，你獲得 3 個“橘”標記。(有“橘”的角色受到傷害時，防止此傷害，然後移去一個“橘”；有“橘”的角色摸牌階段額外摸一張牌。)

huaiju = sgs.CreateTriggerSkill{
	name = "huaiju",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.DamageInflicted, sgs.DrawNCards},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.GameStart then
				if player:objectName() == p:objectName() then
					SendComLog(self, p, 1)
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						p:gainMark("@orange", 3)
						room:removePlayerMark(p, self:objectName().."engine")
					end
				end
			elseif event == sgs.DamageInflicted then
				if player:getMark("@orange") > 0 then
					SendComLog(self, p, 2)
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						player:loseMark("@orange")
						room:removePlayerMark(p, self:objectName().."engine")
					end
					return true
				end
			else
				if player:getMark("@orange") > 0 then
					SendComLog(self, p, 1)
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						data:setValue(data:toInt() + 1)
						room:removePlayerMark(p, self:objectName().."engine")
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


--〖遺禮〗 出牌階段開始時，你可以失去 1 點體力或移去一個“橘”，然後令一名其他角色獲得一個“橘”。
yili = sgs.CreateTriggerSkill{
	name = "yili",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ==  sgs.Player_Start then
			local s = room:askForPlayerChosen(player, room:getOtherPlayers(player), "yili", "@yili-orange", true)
			if s then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local choices = {"lose_Hp", "lose_Orange"}
				local choice = room:askForChoice(player, "yili", table.concat(choices, "+"))
				if choice == "lose_Hp" then
					room:loseHp(player)
				elseif choice == "lose_Orange" then
					player:loseMark("@orange",1)
				end
				s:gainMark("@orange")
			end
		end
	end
}
--〖整論〗 若你沒有“橘”，你可以跳過摸牌階段然後獲得一個“橘”。 
zhenglun = sgs.CreateTriggerSkill{
	name = "zhenglun",
	frequency = sgs.Skill_Frequency,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local phase = change.to	
		if phase == sgs.Player_Draw then
			if not player:isSkipped(sgs.Player_Draw) and player:getMark("@orange") == 0 then
				if room:askForSkillInvoke(player, "zhenglun", data) then
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					player:skip(sgs.Player_Draw)
					player:gainMark("@orange")
				end
			end
		end
	end,
}
luji:addSkill(huaiju)
luji:addSkill(yili)
luji:addSkill(zhenglun)

sgs.LoadTranslationTable{
	["luji"] = "陸積",
	["#luji"] = "瑚璉之器",
	["huaiju"] = "懷橘",
	[":huaiju"] = "鎖定技，遊戲開始時，你獲得 3 個“橘”標記。(有“橘”的角色受到傷害時，防止此傷害，然後移去一個“橘”；有“橘”的角色摸牌階段額外摸一張牌。)",
	["yili"] = "遺禮",
	[":yili"] = "出牌階段開始時，你可以失去 1 點體力或移去一個“橘”，然後令一名其他角色獲得一個“橘”。 ",
	["zhenglun"] = "整論",
	[":zhenglun"] = "若你沒有“橘”，你可以跳過摸牌階段然後獲得一個“橘”。",
	["lose_Hp"] = "失去 1 點體力",
	["lose_Orange"] = "移去一個“橘”",
	["@yili-orange"] = "你可以選擇一名其他角色獲得一個“橘”",
	["@orange"] = "橘",
	["$huaiju1"] = "袖中怀绿桔，遗母报乳哺。",
	["$huaiju2"] = "情深舐犊，怀着藏橘。",
	["$yili1"] = "违失礼仪，则俱非议。",
	["$yili2"] = "行遗礼之举，于不敬王者。",
	["$zhenglun1"] = "整论四海未泰，修文德以平。",
	["$zhenglun2"] = "今论者不务道德怀取之术，而惟尚武，窃所未安。",
}

--[修改]  雷	 袁術	男, 群,  4  體力
god_yuanshu = sgs.General(extension,"god_yuanshu$","qun2","4",true)
--〖庸肆〗 鎖定技，摸牌階段，你改為摸 X 張牌(X 為存活勢力數)；棄牌階段，若你本回合：1. 沒有造成傷害，將手牌摸至當前體力值；2. 造成傷害數超過 1 點，本回合手牌上限改為已損失體力值。
god_yongsi = sgs.CreateTriggerSkill{
	name = "god_yongsi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == "wei2" then
					room:setPlayerProperty(p,"kingdom",sgs.QVariant("wei"))
					local msg = sgs.LogMessage()
					msg.type = "#changeKD"
					msg.from = p
					msg.to:append(p)
					msg.arg = p:getKingdom()
					room:sendLog(msg)
				elseif p:getKingdom() == "shu2" then
					room:setPlayerProperty(p,"kingdom",sgs.QVariant("shu"))
					local msg = sgs.LogMessage()
					msg.type = "#changeKD"
					msg.from = p
					msg.to:append(p)
					msg.arg = p:getKingdom()
					room:sendLog(msg)
				elseif p:getKingdom() == "wu2" then
					room:setPlayerProperty(p,"kingdom",sgs.QVariant("wu"))
					local msg = sgs.LogMessage()
					msg.type = "#changeKD"
					msg.from = p
					msg.to:append(p)
					msg.arg = p:getKingdom()
					room:sendLog(msg)
				elseif p:getKingdom() == "qun2" or p:getKingdom() == "qun3" then
					room:setPlayerProperty(p,"kingdom",sgs.QVariant("qun"))
					local msg = sgs.LogMessage()
					msg.type = "#changeKD"
					msg.from = p
					msg.to:append(p)
					msg.arg = p:getKingdom()
					room:sendLog(msg)
				end
			end

			local kingdom_set = {}
			room:notifySkillInvoked(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				local kingdom = p:getKingdom()
				if not table.contains(kingdom_set, kingdom) then
					table.insert(kingdom_set, kingdom)
				end
			end
			if #kingdom_set > 2 then
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
			local count = #kingdom_set
			data:setValue(count)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard and player:getMark("damage_record-Clear") ~= 1 then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if player:getMark("damage_record-Clear") == 0 and player:getHandcardNum() < player:getHp() then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					player:drawCards(player:getHp() - player:getHandcardNum(), self:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			elseif player:getMark("damage_record-Clear") > 1 then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerFlag(player, self:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end
}
yongsi_buff = sgs.CreateMaxCardsSkill{
	name = "yongsi_buff",
	fixed_func = function(self, player)
		if player:hasFlag("god_yongsi") then
			return player:getLostHp()
		end
		return -1
	end
}
--〖偽帝〗 主公技，你於棄牌階段棄置的牌可以交給任意名其他群雄角色各一張。
god_weidiCard = sgs.CreateSkillCard{
	--這裡SkillCard的name不加上主公技標示"$"，因為會造成技能無法發動
	name = "god_weidi",
	will_throw = false,
	handling_method =sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark(self:objectName().."-Clear") == 0 and to_select:getKingdom() == "qun2" and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			local sbs = {}
			if source:getTag("god_weidi"):toString() ~= "" then
				sbs = source:getTag("god_weidi"):toString():split("+")
			end
			for _,cdid in sgs.qlist(self:getSubcards()) do table.insert(sbs, tostring(cdid)) end
			source:setTag("god_weidi", sgs.QVariant(table.concat(sbs, "+")))
			room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
			room:addPlayerMark(targets[1], self:objectName().."-Clear")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
god_weidiVS = sgs.CreateOneCardViewAsSkill{
	name = "god_weidi$",
	view_filter = function(self, card)
		return string.find(sgs.Self:property("god_weidi"):toString(), tostring(card:getEffectiveId()))
	end,
	view_as = function(self, cards)
		local card = god_weidiCard:clone()
		card:addSubcard(cards)
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self, player, pattern)
		return pattern == "@@god_weidi" and player:hasLordSkill(self:objectName())
	end,
}

god_weidi = sgs.CreateTriggerSkill{
	name = "god_weidi$",
	--這裡的global是為了SP袁術的偽帝
	global = true,
	view_as_skill = god_weidiVS,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and player:hasLordSkill(self:objectName()) and player:getPhase() == sgs.Player_Discard and move.to_place == sgs.Player_DiscardPile then
			if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local zongxuan_card = sgs.IntList()
				for i=0, (move.card_ids:length()-1), 1 do
					local card_id = move.card_ids:at(i)
					if room:getCardOwner(card_id):getSeat() == move.from:getSeat()
						and (move.from_places:at(i) == sgs.Player_PlaceHand
						or move.from_places:at(i) == sgs.Player_PlaceEquip) then
						zongxuan_card:append(card_id)
					end
				end
				if zongxuan_card:isEmpty() then
					return
				end
				local zongxuantable = sgs.QList2Table(zongxuan_card)
				room:setPlayerProperty(player, "god_weidi", sgs.QVariant(table.concat(zongxuantable, "+")))
				while not zongxuan_card:isEmpty() do
					if not room:askForUseCard(player, "@@god_weidi", "@god_weidiput") then break end
					local subcards = sgs.IntList()
					local subcards_variant = player:getTag("god_weidi"):toString():split("+")
					if #subcards_variant > 0 then
						for _,ids in ipairs(subcards_variant) do
							subcards:append(tonumber(ids))
						end
						local zongxuan = player:property("god_weidi"):toString():split("+")
						for _, id in sgs.qlist(subcards) do
							zongxuan_card:removeOne(id)
							table.removeOne(zongxuan,tonumber(id))
							if move.card_ids:contains(id) then
								move.from_places:removeAt(listIndexOf(move.card_ids, id))
								move.card_ids:removeOne(id)
								data:setValue(move)
							end
							if player:isDead() then break end
						end
					end
					player:removeTag("god_weidi")
				end
			end
		end
		return false
	end
}

god_yuanshu:addSkill(god_yongsi)
god_yuanshu:addSkill(god_weidi)
if not sgs.Sanguosha:getSkill("yongsi_buff") then skills:append(yongsi_buff) end

sgs.LoadTranslationTable{
	["god_yuanshu"] = "界袁術",
	["&god_yuanshu"] = "袁術",
	["#god_yuanshu"] = "仲家帝",
	["god_yongsi"] = "庸肆",
	[":god_yongsi"] = "鎖定技，摸牌階段，你改為摸 X 張牌(X 為存活勢力數)；棄牌階段，若你本回合：1. 沒有造成傷害，將手牌摸至當前體力值；2. 造成傷害數超過 1 點，本回合手牌上限改為已損失體力值。",
	["god_weidi"] = "偽帝",
	[":god_weidi"] = "主公技，你於棄牌階段棄置的牌可以交給任意名其他群雄角色各一張。",

	["$god_yongsi1"] = "看我大淮南，兵精糧足！",
	["$god_yongsi2"] = "老子明牌，不虛你們這些渣渣！",
	["$god_weidi1"] = "是明是暗，你自己選好了。",
	["$god_weidi2"] = "違朕旨意，死路一條！",
	["~god_yuanshu"] = "蜜……蜜水呢……",
	["@god_weidiput"] = "你可以發動“偽帝”",
	["~god_weidi"] = "選擇一張牌→選擇一名角色→點擊確定",
}

--孫亮
sunliang = sgs.General(extension,"sunliang$","wu2","3",true)
--〖潰誅〗 棄牌階段結束後，你可以選擇一項：令至多 X 名角色各摸一張牌；對任意名體力值之和為 X 的角色造成一點傷害，若不少於 2 名角色，你須受到一點傷害。(X 為你此階段棄置的牌數)

kuizhuCard = sgs.CreateSkillCard{
	name = "kuizhu",
	filter = function(self, targets, to_select)
		local n = sgs.Self:getMark(self:objectName())
		for i = 1, #targets do
			n = n - targets[i]:getHp()
		end
		return #targets < sgs.Self:getMark(self:objectName()) or to_select:getHp() <= n
	end,
	feasible = function(self, targets)
		local sum = 0
		for i = 1, #targets do
			sum = sum + targets[i]:getHp()
		end
		return #targets > 0 and #targets <= sgs.Self:getMark(self:objectName()) or sum == sgs.Self:getMark(self:objectName())
	end,
	on_use = function(self, room, source, targets)
		local sum = 0
		for _,p in pairs(targets) do
			sum = sum + p:getHp()
		end
		local choices = {}
		if #targets <= source:getMark(self:objectName()) then
			table.insert(choices, "kuizhu1")
		end
		if sum <= source:getMark(self:objectName()) then
			table.insert(choices, "kuizhu2")
		end
		for _,p in pairs(targets) do
			p:setFlags("KuizhuTarget")
		end
		local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
		for _,p in pairs(targets) do
			p:setFlags("-KuizhuTarget")
		end
		ChoiceLog(source, choice)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			for _,p in pairs(targets) do
				if choice == "kuizhu1" then
					p:drawCards(1, self:objectName())
				else
					room:damage(sgs.DamageStruct(self:objectName(), source, p))
				end
			end
			--[[
			if choice == "kuizhu2" and #targets >= 2 then
				room:damage(sgs.DamageStruct(self:objectName(), source, source))
			end
			]]--
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
kuizhuVS = sgs.CreateZeroCardViewAsSkill{
	name = "kuizhu",
	view_as = function(self, cards)
		return kuizhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@kuizhu")
	end
}
kuizhu = sgs.CreateTriggerSkill{
	name = "kuizhu",
	view_as_skill = kuizhuVS,
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
					room:askForUseCard(player, "@@kuizhu", "@kuizhu", -1, sgs.Card_MethodUse)
				end
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
		return false
	end
}

--〖掣政〗 鎖定技，你的出牌階段內，攻擊範圍內不包含你的角色不能成為你使用牌的目標。出牌階段結束時，若你本階段內使用的牌數小於這些角色數，你棄置其中一名角色一張牌。 
--[[										   
chezhengPS = sgs.CreateProhibitSkill{
	name = "#chezhengPS",
	is_prohibited = function(self, from, to, card)
		return from:hasSkill(self:objectName()) and from:getPhase() == sgs.Player_Play and not to:inMyAttackRange(from) and from:objectName() ~= to:objectName() and not card:isKindOf("SkillCard")
	end
}
]]--

chezheng = sgs.CreateTriggerSkill{
	name = "chezheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Play then return false end

		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if not damage.to:inMyAttackRange(player) and player:objectName() ~= damage.to:objectName() then
				local msg = sgs.LogMessage()
				msg.type = "#ChezhengProtect"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = damage.damage
				if damage.nature == sgs.DamageStruct_Fire then
					msg.arg2 = "fire_nature"
				elseif damage.nature == sgs.DamageStruct_Thunder then
					msg.arg2 = "thunder_nature"
				elseif damage.nature == sgs.DamageStruct_Normal then
					msg.arg2 = "normal_nature"
				end
				room:sendLog(msg)

				return true
			end
			return false

		elseif event == sgs.EventPhaseEnd then
			local count, targets = 0, sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:inMyAttackRange(player) then
					count = count + 1
					if player:canDiscard(p, "he") then
						targets:append(p)
					end
				end
			end
			if not targets:isEmpty() and player:getMark("used_Play") < count then
				local to = room:askForPlayerChosen(player, targets, self:objectName(), "chezheng-invoke", false, true)
				room:broadcastSkillInvoke(self:objectName())
				if to then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local id = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(id, to, player)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}

--〖立軍〗 主公技，其他吳勢力角色於其出牌階段使用【殺】結算結束後，其可將此【殺】交給你，然後你可令其摸一張牌。
lijun = sgs.CreateTriggerSkill{
	name = "lijun$",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local card = data:toCardUse().card
		if card and card:isKindOf("Slash") and room:getCardPlace(card:getEffectiveId()) == sgs.Player_DiscardPile then
			local sunliangs = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasLordSkill(self:objectName()) then
					sunliangs:append(p)
				end
			end
			if not sunliangs:isEmpty() then
				local _data = sgs.QVariant()
				for _, p in sgs.qlist(sunliangs) do
					_data:setValue(p)
					--if room:askForSkillInvoke(player, self:objectName(), _data) then
					if player:getMark("lijun_Play") == 0 and room:askForSkillInvoke(player, self:objectName(), _data) then
						room:obtainCard(p, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), self:objectName(), ""), false)
						_data:setValue(player)
						room:addPlayerMark(player, "lijun_Play")
						if room:askForSkillInvoke(p, self:objectName(), _data) then
							room:broadcastSkillInvoke(self:objectName())
							room:addPlayerMark(player, self:objectName().."engine")
							if player:getMark(self:objectName().."engine") > 0 then
								player:drawCards(1, self:objectName())
								room:removePlayerMark(player, self:objectName().."engine")
							end
						end
						break
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getKingdom() == "wu" and target:getPhase() == sgs.Player_Play
	end
}

lijunTM = sgs.CreateTargetModSkill{
	name = "#lijunTM",
	frequency = sgs.Skill_NotFrequent,
	residue_func = function(self, target)
			if target:getMark("lijun_Play") > 0 then 
				return 1 
			end
	end,
}

sunliang:addSkill(kuizhu)
sunliang:addSkill(chezheng)
sunliang:addSkill(lijun)
sunliang:addSkill(lijunTM)

sgs.LoadTranslationTable{
	["sunliang"] = "孫亮",
	["#sunliang"] = "寒江枯水",
	["&sunliang"] = "孫亮",
	["kuizhu"] = "潰誅",
	--[":kuizhu"] = "棄牌階段結束後，你可以選擇一項：令至多 X 名角色各摸一張牌；對任意名體力值之和為 X 的角色造成一點傷害，若不少於 2 名角色，你須受到一點傷害。(X 為你此階段棄置的牌數)",
	[":kuizhu"] = "棄牌階段結束後，你可以選擇一項：令至多 X 名角色各摸一張牌；對任意名體力值之和為 X 的角色造成一點傷害。(X 為你此階段棄置的牌數)",
	["chezheng"] = "掣政",
	--[":chezheng"] = "鎖定技，你的出牌階段內，攻擊範圍內不包含你的角色不能成為你使用牌的目標。出牌階段結束時，若你本階段內使用的牌數小於這些角色數，你棄置其中一名角色一張牌。",
	[":chezheng"] = "鎖定技，你的出牌階段內，防止你對攻擊範圍內不包含你的角色所造成的傷害。出牌階段結束時，若你本階段內使用的牌數小於這些角色數，你棄置其中一名角色一張牌。",
	["chezheng-invoke"] = "你可以發動「掣政」<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	["lijun"] = "立軍",
	--[":lijun"] = "主公技，其他吳勢力角色於其出牌階段使用【殺】結算結束後，其可將此【殺】交給你，然後你可令其摸一張牌。",	
	[":lijun"] = "主公技，其他吳勢力角色的出牌階段限一次，其使用【殺】結算結束後，其可將此【殺】交給你，然後你可令其摸一張牌且此階段其使用【殺】的數量+1。",	
	["@kuizhu"] = "你可以發動“潰誅”",
	["~kuizhu"] = "選擇若干名角色->點擊確定",
	["kuizhu1"] = "令一至X名角色各摸一張牌",
	["kuizhu2"] = "對至少一名體力值之和為X的角色造成1點傷害",
	--["kuizhu2"] = "對至少一名體力值之和為X的角色造成1點傷害，然後若以此法選擇的角色數不小於2，你對你造成1點傷害",
	
	["$kuizhu1"] = "子通專恣，必謀而誅之！",
	["$kuizhu2"] = "孫綝久專，不可久忍，必潰誅！",
	["$chezheng1"] = "風馳電掣，政權不怠。",
	["$chezheng2"] = "唉~廉平掣政，實為艱事。",
	["$lijun1"] = "立於朝堂，定於軍心。",
	["$lijun2"] = "君立於朝堂，軍側於四方。",
	["~sunliang"] = "今日欲誅逆臣而不得，方知機事不密則害成……",

	["#ChezhengProtect"] = "%from 的「<font color=\"yellow\"><b>掣政</b></font>」效果被觸發，防止了對 %to 造成的 %arg 點傷害[%arg2]",
}
--許攸
ol_xuyou = sgs.General(extension,"ol_xuyou","qun2","3",true)
--【成略】：轉換技：出牌階段限一次，1:你可以摸一張牌，然後棄置兩張牌/2:你可以摸兩張牌，然後棄置一張牌。若如此做，直到回合結束，你使用與你棄置的牌相同花色的牌無距離和次數限制。
function ChangeCheck(player, name)
	if player:getGeneralName() == name or player:getGeneral2Name() == name then
		local x = player:getMaxHp()
		local y = player:getHp()
		local z = player:getKingdom()
		player:getRoom():changeHero(player, name, false, true, player:getGeneral2Name() and player:getGeneral2Name() == name, false)
		player:getRoom():setPlayerProperty(player, "maxhp", sgs.QVariant(x))
		player:getRoom():setPlayerProperty(player, "hp", sgs.QVariant(math.min(y, player:getMaxHp())))
		player:getRoom():setPlayerProperty(player, "kingdom", sgs.QVariant(z))
	end
end

chenglveCard = sgs.CreateSkillCard{
	name = "chenglve" ,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		if source:getMark("@chenglve_yang") == 1 then
			room:setPlayerMark(source,"@chenglve_yang",0)
			room:setPlayerMark(source,"@chenglve_yin",1)
			sgs.Sanguosha:addTranslationEntry(":chenglve", ""..string.gsub(sgs.Sanguosha:translate(":chenglve"), sgs.Sanguosha:translate(":chenglve"), sgs.Sanguosha:translate(":chenglve2")))
			--ChangeCheck(source, "ol_xuyou")
			source:drawCards(1)	
			local cards = room:askForExchange(source, self:objectName(), math.min(source:getHandcardNum(), 2), 2, false, "@disTwo")
			if cards then
				room:throwCard(cards, source, source)
				room:addPlayerMark(source, "chenglve" .. sgs.Sanguosha:getCard(cards:getSubcards():first()):getSuitString() .. "-Clear")
				room:addPlayerMark(source, "chenglve" .. sgs.Sanguosha:getCard(cards:getSubcards():last()):getSuitString() .. "-Clear")
			end
		elseif source:getMark("@chenglve_yin") == 1 then
			room:setPlayerMark(source,"@chenglve_yang",1)
			room:setPlayerMark(source,"@chenglve_yin",0)
			sgs.Sanguosha:addTranslationEntry(":chenglve", ""..string.gsub(sgs.Sanguosha:translate(":chenglve"), sgs.Sanguosha:translate(":chenglve"), sgs.Sanguosha:translate(":chenglve1")))
			--ChangeCheck(source, "ol_xuyou")
			source:drawCards(2)	
			
			local cards = room:askForExchange(source, self:objectName(), math.min(source:getHandcardNum(), 1), 1, false, "@disOne")
			if cards then
				room:throwCard(cards, source, source)
				room:addPlayerMark(source, "chenglve" .. sgs.Sanguosha:getCard(cards:getSubcards():first()):getSuitString() .. "-Clear")
				room:addPlayerMark(source, "chenglve" .. sgs.Sanguosha:getCard(cards:getSubcards():last()):getSuitString() .. "-Clear")
			end

		end
	end
}

chenglveVS = sgs.CreateZeroCardViewAsSkill{
	name = "chenglve",
	view_as = function(self,cards)
		return chenglveCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#chenglve") < 1
	end
}
chenglve = sgs.CreateTriggerSkill{
	name = "chenglve",
	events = {sgs.GameStart,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	view_as_skill = chenglveVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart) and player:getMark("@chenglve_yin") == 0 and player:getMark("@chenglve_yang") == 0 then
			room:setPlayerMark(player,"@chenglve_yang",1)
			room:setPlayerMark(player,"@chenglve_yin",0)
			sgs.Sanguosha:addTranslationEntry(":chenglve", ""..string.gsub(sgs.Sanguosha:translate(":chenglve"), sgs.Sanguosha:translate(":chenglve"), sgs.Sanguosha:translate(":chenglve1")))
			--ChangeCheck(player, "ol_xuyou")	
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player,"@chenglve_yin",0)
			room:setPlayerMark(player,"@chenglve_yang",0)
		end
	end,
}
chenglveTM = sgs.CreateTargetModSkill{
	name = "#chenglveTM",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash,Analeptic,TrickCard",
	distance_limit_func = function(self, from, card)
		if from:getMark("chenglve" .. card:getSuitString() .. "-Clear") > 0 then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, from, card)
		if from:getMark("chenglve" .. card:getSuitString() .. "-Clear") > 0 then
			return 1000
		else
			return 0
		end
	end,
}
--【恃才】：當你使用一張牌結算結束後，若此牌與你於本回合內使用的牌類型均不同（包括裝備牌），你可以將這張牌置於牌堆頂，然後摸一張牌。

--[[
ol_shicai = sgs.CreateTriggerSkill{
	name = "ol_shicai",
	events = {sgs.CardFinished,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card  and player:hasSkill("ol_shicai")
			 and (not use.card:isKindOf("DelayedTrick")) and (not use.card:isVirtualCard()) then
				local id = use.card:getEffectiveId()
				if (room:getCardPlace(id) == sgs.Player_DiscardPile or room:getCardPlace(id) == sgs.Player_PlaceTable) 
				 and ((player:getMark("ol_shicai_Basic-Clear") == 0 and use.card:getTypeId() == sgs.Card_TypeBasic)
				 or (player:getMark("ol_shicai_Trick-Clear") == 0 and use.card:getTypeId() == sgs.Card_TypeTrick)) then
					if use.card:getTypeId() == sgs.Card_TypeBasic then
						room:setPlayerMark(player, "ol_shicai_Basic-Clear", 1) 
					elseif use.card:getTypeId() == sgs.Card_TypeEquip then
						room:setPlayerMark(player, "ol_shicai_Equip-Clear", 1)
					elseif use.card:getTypeId() == sgs.Card_TypeTrick then
						room:setPlayerMark(player, "ol_shicai_Trick-Clear", 1)
					end
					if room:askForSkillInvoke(player, "ol_shicai", data) then 
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), nil, "ol_shicai", nil)	
						room:moveCardTo(use.card, nil, nil, sgs.Player_DrawPile, reason)
						local n = use.card:getSubcards():length() 
						if n > 1 then
							local cards = room:getNCards(n)
							room:askForGuanxing(player, cards, sgs.Room_GuanxingUpOnly)
						end
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:getTypeId() ~= sgs.Card_TypeSkill and player:hasSkill("ol_shicai") and not use.card:isKindOf("DelayedTrick") then
				if use.card:isVirtualCard() then return false end
				if (player:getMark("ol_shicai_Equip-Clear") == 0 and use.card:getTypeId() == sgs.Card_TypeEquip) then
					if use.card:getTypeId() == sgs.Card_TypeBasic then
						room:setPlayerMark(player, "ol_shicai_Basic-Clear", 1) 
					elseif use.card:getTypeId() == sgs.Card_TypeEquip then
						room:setPlayerMark(player, "ol_shicai_Equip-Clear", 1)
					elseif use.card:getTypeId() == sgs.Card_TypeTrick then
						room:setPlayerMark(player, "ol_shicai_Trick-Clear", 1)
					end
					if room:askForSkillInvoke(player, "ol_shicai_equip", data) then 
						room:notifySkillInvoked(player, self:objectName())
						room:sendCompulsoryTriggerLog(player, self:objectName()) 
						room:broadcastSkillInvoke(self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), nil, "ol_shicai", nil)	
						room:moveCardTo(use.card, nil, nil, sgs.Player_DrawPile, reason)
						player:drawCards(1)
						return true
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
]]--

ol_shicai = sgs.CreateTriggerSkill{
	name = "ol_shicai",
	global = true,
	events = {sgs.CardFinished, sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local card = data:toCardUse().card
			for _, mark in sgs.list(player:getMarkNames()) do
				if player:getMark("shicai"..card:getTypeId().."-Clear") == 0 and string.find(mark, "shicai_card_info_type_"..card:getTypeId().."_id_") and player:getMark(mark) > 0 and mark:split("_")[7] ~= -1 then
					local shicai_card_id = mark:split("_")[7]
					local shicai_card = sgs.Sanguosha:getCard(shicai_card_id)
					if shicai_card and player:getMark("shicai"..card:getTypeId().."-Clear") == 0 and not card:isKindOf("SkillCard")
					and not card:isKindOf("EquipCard") and not card:isKindOf("DelayedTrick")
					and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(player, self:objectName().."engine")
						if player:getMark(self:objectName().."engine") > 0 then
							local log = sgs.LogMessage()
							log.type = "#shicai_put"
							log.from = player
							log.card_str = shicai_card:toString()
							room:sendLog(log)
							room:moveCardTo(shicai_card, player, sgs.Player_DrawPile)
							player:drawCards(1, self:objectName())
							room:removePlayerMark(player, self:objectName().."engine")
						end
						room:addPlayerMark(player, "shicai"..card:getTypeId().."-Clear")
					end
				end
			end
			
			--以下若使用多張牌只會將最後出的牌置於牌堆頂
			--[[
			if player:getMark("shicai"..card:getTypeId().."-Clear") == 0 and not card:isKindOf("SkillCard")
			and not card:isKindOf("EquipCard") and not card:isKindOf("DelayedTrick") and room:getCardPlace(card:getEffectiveId()) == sgs.Player_Discard
			and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--if room:getCardPlace(card:getEffectiveId()) == sgs.Player_Discard then
						local log = sgs.LogMessage()
						log.type = "#shicai_put"
						log.from = player
						log.card_str = card:toString()
						room:sendLog(log)
					--end
					room:moveCardTo(card, player, sgs.Player_DrawPile)
					player:drawCards(1, self:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
				room:addPlayerMark(player, "shicai"..card:getTypeId().."-Clear")
			end
			]]--
			
			if card and RIGHT(self, player) then
				room:addPlayerMark(player, "shicai"..card:getTypeId().."-Clear")
			end
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			elseif event == sgs.CardResponded then
				--card = data:toCardResponse().m_card
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if not card then return false end
			local shicai_first_card_checker = true
			for _, mark in sgs.list(player:getMarkNames()) do
				if string.find(mark, "shicai_card_info_type_"..card:getTypeId().."_id_") and player:getMark(mark) > 0 then
					shicai_first_card_checker = false
				end
			end
			if shicai_first_card_checker and player:getMark("shicai"..card:getTypeId().."-Clear") == 0
			and not card:isKindOf("SkillCard") and not card:isKindOf("EquipCard") and not card:isKindOf("DelayedTrick")
			and RIGHT(self, player)
			then
				room:addPlayerMark(player, "shicai_card_info_type_"..card:getTypeId().."_id_"..card:getEffectiveId().."_-Clear")
			end
			
			if player:getMark("shicai"..card:getTypeId().."-Clear") == 0 and not card:isKindOf("SkillCard") and card:isKindOf("EquipCard") and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				
				--這裡的getThread()強制系統跳過兩個階段：指定目標階段和卡牌結算完成階段，為了就是不讓系統觸棄置現有裝備。(太陽神三國殺使用裝備時不檢查裝備牌還存不存在，直接先棄置現有的裝備)
				--感謝貼吧 田馥甄 提供的代碼
				local thread = room:getThread()
				room:getThread():trigger(sgs.TargetSpecified, room, player, data)
				room:getThread():trigger(sgs.CardFinished, room, player, data)
				
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
--					if room:getCardPlace(card:getEffectiveId()) == sgs.Player_Discard then
--						local log = sgs.LogMessage()
--						log.type = "#shicai_put"
--						log.from = player
--						log.card_str = card:toString()
--						room:sendLog(log)
--					end
					room:moveCardTo(card, player, sgs.Player_DrawPile)
					player:drawCards(1, self:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
				room:addPlayerMark(player, "shicai"..card:getTypeId().."-Clear")
				
				--這裡return true一定要有不然還是會頂掉原本裝備
				return true
			end
		end
		return false
	end
}

--【寸目】：鎖定技，你摸牌時，改為從牌堆底摸等量的牌。
cunmu = sgs.CreateTriggerSkill{
	name = "cunmu" ,
	events = {sgs.BeforeCardsMove} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()

		local yajiao_wrong_move_reason_checker = true
		if move.from and move.from:hasSkill("yajiao") then
			yajiao_wrong_move_reason_checker = false
		end

			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and 
			 move.from_places:contains(sgs.Player_DrawPile) and (not player:hasFlag("cunmu_InTempMoving")) and 
			 move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW and
			 yajiao_wrong_move_reason_checker and player:hasSkill("cunmu") and not room:getTag("FirstRound"):toBool() then
--[[
				local n = move.card_ids:length()

				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, nil, self:objectName(), "")
				local flag = true
				room:setTag("FirstRound" , sgs.QVariant(true))
				local ids = sgs.IntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(card_id)
					room:moveCardTo(card, player, sgs.Player_PlaceSpecial, reason, false)
					flag = false
				end
				for _,card_id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(card_id)
					room:moveCardTo(card, nil, nil, sgs.Player_DrawPile, reason, false)
					flag = false
				end
				if flag then
					return false
				end
				local x=move.card_ids:length()
				for i = x-1, 0, -1 do
					ids:append(move.card_ids:at(i))
					move.card_ids:removeAt(i)
				end
				data:setValue(move)
				room:setTag("FirstRound" , sgs.QVariant(false))

				room:setPlayerFlag(player, "cunmu_InTempMoving")				
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for i=1, n, 1 do
					local ids = room:getDrawPile()
					local id
					id = ids:at(ids:length()-i)
					local card = sgs.Sanguosha:getCard(id)
					--room:moveCardTo(card, player, sgs.Player_PlaceHand, false)
					dummy:addSubcard(card)
				end
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:moveCardTo(dummy, player, sgs.Player_PlaceHand, false)
				]]--
				
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName()) 
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setPlayerFlag(player, "cunmu_InTempMoving")
					local n, drawpile = move.card_ids:length(), room:getDrawPile()
					room:returnToTopDrawPile(move.card_ids)
					move.card_ids = sgs.IntList()
					for i = 1, n do
						move.card_ids:append(drawpile:at(drawpile:length() - i))
					end
					data:setValue(move)
					room:removePlayerMark(player, self:objectName().."engine")
				end

				room:setPlayerFlag(player, "-cunmu_InTempMoving")
				room:setTag("FirstRound" , sgs.QVariant(false))
			end
		end
		return false
	end,
}

ol_xuyou:addSkill(chenglve)
ol_xuyou:addSkill(chenglveTM)
ol_xuyou:addSkill(ol_shicai)
ol_xuyou:addSkill(cunmu)
extension:insertRelatedSkills("chenglve","#chenglveTM")


sgs.LoadTranslationTable{
	["ol_xuyou"] = "許攸",
	["#ol_xuyou"] = "朝秦暮楚",
	["chenglve"] = "成略",
	[":chenglve"] = "轉換技，陽：出牌階段限一次，你可以摸一張牌，然後棄置兩張手牌；陰：你可以摸兩張牌，然後棄置一張手牌。若如此做，你於此回合內使用與以此法棄置的牌相同花色的牌無距離和次數限制。",
	[":chenglve2"] = "轉換技，<font color=\"#01A5AF\"><s>陽：出牌階段限一次，你可以摸一張牌，然後棄置兩張手牌</s></font>；陰：你可以摸兩張牌，然後棄置一張手牌。若如此做，你於此回合內使用與以此法棄置的牌相同花色的牌無距離和次數限制。",
	[":chenglve1"] = "轉換技，陽：出牌階段限一次，你可以摸一張牌，然後棄置兩張手牌；<font color=\"#01A5AF\"><s>陰：你可以摸兩張牌，然後棄置一張手牌</s></font>。若如此做，你於此回合內使用與以此法棄置的牌相同花色的牌無距離和次數限制。",
	["ol_shicai"] = "恃才",
	["ol_shicai_equip"] = "恃才",
	[":ol_shicai"] = "當你使用一張牌結算結束後，若此牌與你於本回合內使用的牌類型均不同（包括裝備牌），你可以將這張牌置於牌堆頂，然後摸一張牌。",
	["cunmu"] = "寸目",
	[":cunmu"] = "鎖定技，你摸牌時，改為從牌堆底摸等量的牌。",
	["$chenglve1"] = "成略在胸，良计速出。",
	["$chenglve2"] = "吾有良略在怀，必为阿瞒所需。",
	["$ol_shicai1"] = "吾才满腹，袁本初竟不从之！",
	["$ol_shicai2"] = "阿瞒有我良计，取冀州便是易如反掌！",
	["$cunmu1"] = "哼~目光所及，短寸之间。",
	["$cunmu2"] = "狭目之间，只能窥底。",
	["~ol_xuyou"] = "阿瞒！没有我，你得不到冀州啊！",
	["#shicai_put"] = "%from 將 %card 置于牌堆頂",
	["@disOne"] = "請棄置一張手牌",
	["@disTwo"] = "請棄置兩張手牌",
}
--蒯良蒯越 3血 稱號：雍論臼謀
kuaiyuekuailiang = sgs.General(extension,"kuaiyuekuailiang","wei2","3",true)
--薦降：當你成為其他角色使用牌的目標後，你可令手牌數最少的一名角色摸一張牌。
jianxiang = sgs.CreateTriggerSkill{
	name = "jianxiang" ,
	events = {sgs.TargetConfirmed} ,
	frequency = sgs.Skill_Frequent,	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if not use.card:isKindOf("SkillCard") then
					local player_card = {}
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						table.insert(player_card, p:getHandcardNum())
					end
 					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getHandcardNum() == math.min(unpack(player_card)) then 
							_targets:append(p)
						end
					end
					local t = room:askForPlayerChosen(player, _targets, "jianxiang", "@jianxiang_draw", true)
					if t then
						room:notifySkillInvoked(player, self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), t:objectName())
						t:drawCards(1)
					end
				end
			end
		end
		return false
	end
}

--審時：轉換技，①出牌階段限一次，你可以將一張牌交給一名手牌數最多的角色，然後對其造成1點傷害。若該角色因此死亡，則你可以令一名角色將手牌摸至四張。 ②其他角色對你造成傷害後，你可以觀看該角色的手牌，然後交給其一張牌，當前回合結束時，若該角色未失去此牌，你將手牌摸至四張
shenshiCard = sgs.CreateSkillCard{
	name = "shenshi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local n = 0
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if p:objectName() ~= sgs.Self:objectName() then
				n = math.max(n, p:getHandcardNum())
			end
		end
		--local m = 0
		--if not sgs.Sanguosha:getCard(self:getSubcards():first()):isEquipped() then m = m + 1 end
		--n = math.max(n, sgs.Self:getHandcardNum() - m)
		return #targets == 0 and to_select:getHandcardNum() == n and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source,"@shenshi_yang",0)
		room:setPlayerMark(source,"@shenshi_yin",1)
		sgs.Sanguosha:addTranslationEntry(":shenshi", ""..string.gsub(sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi2")))

		room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
			if room:getTag("shenshi"):toBool() then
				room:setTag("shenshi",  sgs.QVariant(false))
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					targets:append(p)
				end
				if targets:isEmpty() then return false end
				local to = room:askForPlayerChosen(source, targets, self:objectName(), "shenshi-invoke", true)
				if to and to:getHandcardNum() < 4 then
					to:drawCards(4 - to:getHandcardNum(), self:objectName())
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
shenshiVS = sgs.CreateOneCardViewAsSkill{
	name = "shenshi",
	filter_pattern = ".",
	view_as = function(self, card)
		local first = shenshiCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@shenshi_yang") == 1 and player:getMark("@shenshi_yin") == 0 and not player:isNude()
	end
}
shenshi = sgs.CreateTriggerSkill{
	name = "shenshi",
	view_as_skill = shenshiVS,
	events = {sgs.Death, sgs.Damage, sgs.EventPhaseChanging,sgs.EventAcquireSkill,sgs.GameStart,sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if ((event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart) and player:hasSkill("shenshi") and player:getMark("@shenshi_yin") == 0 and player:getMark("@shenshi_yang") == 0 then
			room:setPlayerMark(player,"@shenshi_yang",1)
			room:setPlayerMark(player,"@shenshi_yin",0)
			sgs.Sanguosha:addTranslationEntry(":shenshi", ""..string.gsub(sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi1")))
			--ChangeCheck(player, "kuaiyuekuailiang")
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player,"@shenshi_yang",0)
			room:setPlayerMark(player,"@shenshi_yin",0)
			sgs.Sanguosha:addTranslationEntry(":shenshi", ""..string.gsub(sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi")))
		end
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.Death then
				local death = data:toDeath()
				if death.who:objectName() == player:objectName() and death.damage and death.damage.reason and death.damage.reason == self:objectName() then
					room:setTag(self:objectName(), sgs.QVariant(true))
				end
			elseif event == sgs.Damage then
				local damage = data:toDamage()
				if p and damage.to:objectName() == p:objectName() and p:getMark(self:objectName()) == 1 and damage.from and damage.from:objectName() ~= p:objectName() and not p:isNude() then
					local _data = sgs.QVariant()
					_data:setValue(damage.from)
					if room:askForSkillInvoke(player, self:objectName(), _data) then
						room:setPlayerMark(player,"@shenshi_yang",1)
						room:setPlayerMark(player,"@shenshi_yin",0)
						sgs.Sanguosha:addTranslationEntry(":shenshi", ""..string.gsub(sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi"), sgs.Sanguosha:translate(":shenshi1")))

						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							room:showAllCards(damage.from, p)
							if not p:isNude() then
								local card = room:askForCard(p, "..!", "@shenshi_give:" .. damage.from:objectName(), data, sgs.Card_MethodNone, nil, false, self:objectName())
								room:moveCardTo(card, damage.from, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), damage.from:objectName(), self:objectName(), ""))
								room:setPlayerMark(damage.from, self:objectName()..card:getEffectiveId().."-Clear", 1)
							end
							room:removePlayerMark(p, self:objectName().."engine")
						end
					end
				end
			else
				if p and data:toPhaseChange().to == sgs.Player_NotActive then
					for _, pe in sgs.qlist(room:getOtherPlayers(p)) do
						for _, mark in sgs.list(pe:getMarkNames()) do
							if string.find(mark, self:objectName()) and pe:getMark(mark) > 0 then
								for _, card in sgs.list(pe:getCards("he")) do
									if mark == self:objectName()..card:getEffectiveId().."-Clear" and p:getHandcardNum() < 4 then
										p:drawCards(4 - p:getHandcardNum(), self:objectName())
									end
								end
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

kuaiyuekuailiang:addSkill(jianxiang)
kuaiyuekuailiang:addSkill(shenshi)

sgs.LoadTranslationTable{
	["kuaiyuekuailiang"] = "蒯良蒯越",
	["#kuaiyuekuailiang"] = "雍論臼謀",
	["jianxiang"] = "薦降",
	[":jianxiang"] = "當你成為其他角色使用牌的目標後，你可令手牌數最少的一名角色摸一張牌。",
	["shenshi"] = "審時",
	[":shenshi"] = "轉換技，陽：出牌階段限一次，你可以將一張牌交給一名手牌數最多的角色，然後對其造成1點傷害。若該角色因此死亡，則你可以令一名角色將手牌摸至四張。 陰：其他角色對你造成傷害後，你可以觀看該角色的手牌，然後交給其一張牌，當前回合結束時，若該角色未失去此牌，你將手牌摸至四張",
	[":shenshi1"] = "轉換技，陽：出牌階段限一次，你可以將一張牌交給一名手牌數最多的角色，然後對其造成1點傷害。若該角色因此死亡，則你可以令一名角色將手牌摸至四張。 <font color=\"#01A5AF\"><s>陰：其他角色對你造成傷害後，你可以觀看該角色的手牌，然後交給其一張牌，當前回合結束時，若該角色未失去此牌，你將手牌摸至四張</s></font>",
	[":shenshi2"] = "轉換技，<font color=\"#01A5AF\"><s>陽：出牌階段限一次，你可以將一張牌交給一名手牌數最多的角色，然後對其造成1點傷害。若該角色因此死亡，則你可以令一名角色將手牌摸至四張。</s></font> 陰：其他角色對你造成傷害後，你可以觀看該角色的手牌，然後交給其一張牌，當前回合結束時，若該角色未失去此牌，你將手牌摸至四張",
	["@jianxiang_draw"] = "你可令手牌數最少的一名角色摸一張牌",
	["@shenshi_give"] = "你可以將此牌交給一名手牌數最多的角色，然後對其造成1點傷害",
	["@shenshi_diegive"] = "你可以令一名角色將手牌摸至四張",
	["#shenshi_give"] = "你可以發動技能「審時」，並交給 %src 一張牌",
	["illustrator:kuaiyuekuailiang"] = "北辰南",
	["$jianxiang1"] = "得遇曹公，吾之幸也。",
	["$jianxiang2"] = "曹公得荆不喜，喜得吾二人足以。",
	["$shenshi1"] = "深中足智，見時審情。",
	["$shenshi2"] = "數語之言，審時度勢。",
	["~kuaiyuekuailiang"] = "表不能善用，所憾也。",
}

--毌丘儉
guanqiujian = sgs.General(extension, "guanqiujian", "wei2", 4, true)

--徵榮：當你使用【殺】或傷害類錦囊牌指定目標後，你可以選擇其中一個手牌數大於等於你的目標角色，其一張牌置於你的武將牌上，
--稱為“榮”。
--[[
zhengrong = sgs.CreateTriggerSkill{
	name = "zhengrong",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() ~= player:objectName() and damage.to:getHandcardNum() > player:getHandcardNum() and not damage.to:isNude() and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("zhengrong-invoke:" .. damage.to:objectName())) then
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
				if id ~= -1 then
					player:addToPile("honor", id)
				end
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
]]--
zhengrong = sgs.CreateTriggerSkill{
	name = "zhengrong",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and use.from:objectName() == player:objectName()
			and use.card and not use.card:isKindOf("SkillCard") and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
			or use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("FireAttack")) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(use.to) do
					if p:getHandcardNum() > player:getHandcardNum() then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						local target = room:askForPlayerChosen(player, players, self:objectName(), "zhengrong-invoke", true, true)
						if target then
							room:broadcastSkillInvoke(self:objectName())
							local id = room:askForCardChosen(player, target, "he", self:objectName())
							if id ~= -1 then
								player:addToPile("honor", id)
							end
						end
					end
				end
			end
		end
		return false
	end
}

guanqiujian:addSkill(zhengrong)

hongjuCard = sgs.CreateSkillCard{
	name = "hongju",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local to_handcard = sgs.IntList()
		local to_pile = sgs.IntList()
		local set = source:getPile("honor")
		for _,id in sgs.qlist(self:getSubcards()) do
			set:append(id)
		end
		for _,id in sgs.qlist(set) do
			if not self:getSubcards():contains(id) then
				to_handcard:append(id)
			elseif not source:getPile("honor"):contains(id) then
				to_pile:append(id)
			end
		end
		assert(to_handcard:length() == to_pile:length())
		if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then return end
		room:notifySkillInvoked(source, "hongju")
		source:addToPile("honor", to_pile, false)
		local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, id in sgs.qlist(to_handcard) do
			to_handcard_x:addSubcard(id)
		end
		room:obtainCard(source, to_handcard_x, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName(), self:objectName(), ""))
	end
}
hongjuVS = sgs.CreateViewAsSkill{
	name = "hongju", 
	n = 999,
	response_pattern = "@@hongju",
	expand_pile = "honor",
	view_filter = function(self, selected, to_select)
		if #selected < sgs.Self:getPile("honor"):length() then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getPile("honor"):length() then
			local c = hongjuCard:clone()
			for _,card in ipairs(cards) do
				c:addSubcard(card)
			end
			return c
		end
		return nil
	end
}

hongju = sgs.CreatePhaseChangeSkill{
	name = "hongju",
	frequency = sgs.Skill_Wake,
	view_as_skill = hongjuVS,
	on_phasechange = function(self, player)
		local room = player:getRoom() 
		if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 and (player:getPile("honor"):length() >= 3 and player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0) then
			local invoke = false
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if p:isDead() then
					invoke = true
				end
			end
			if invoke or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox("guanqiujian", "hongju")	
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(player, self:objectName())
					if not player:isKongcheng() then
						room:askForUseCard(player, "@@hongju", "@hongju", -1, sgs.Card_MethodNone)
					end
					if room:changeMaxHpForAwakenSkill(player) then
						room:acquireSkill(player, "qingce")
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
guanqiujian:addSkill(hongju)

--☆清側：出牌階段，你可以獲得一張“榮”並棄置一張手牌，然後棄置場上的一張牌。
qingceCard = sgs.CreateSkillCard{
	name = "qingce",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:hasEquip() or to_select:getJudgingArea():length() > 0)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
			effect.from:obtainCard(sgs.Sanguosha:getCard(self:getSubcards():first()))
			room:askForDiscard(effect.from, self:objectName(), 1,1, false, true)
			local id = room:askForCardChosen(effect.from, effect.to, "ej", self:objectName(), false, sgs.Card_MethodDiscard)
			if id ~= -1 then
				room:throwCard(id, effect.to, effect.from)
			end
			room:removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
qingce = sgs.CreateOneCardViewAsSkill{
	name = "qingce", 
	filter_pattern = ".|.|.|honor",
	expand_pile = "honor",
	view_as = function(self, card)
		local scard = qingceCard:clone()
		scard:addSubcard(card)
		return scard
	end,
	enabled_at_play = function(self, player)
		return player:getPile("honor"):length() > 0
	end
}
if not sgs.Sanguosha:getSkill("qingce") then skills:append(qingce) end
guanqiujian:addRelateSkill("qingce")

sgs.LoadTranslationTable{
["guanqiujian"] = "毌丘儉",
["#guanqiujian"] = "鐫功名徵榮",
["zhengrong"] = "徵榮",
--[":zhengrong"] = "當你對其他角色造成傷害後，若其手牌比你多，你可以將其一張牌置於你的武將牌上，稱為“榮”。",
[":zhengrong"] = "當你使用【殺】或傷害類錦囊牌指定目標後，你可以選擇其中一個手牌數大於等於你的目標角色，其一張牌置於你的武將牌上，稱為“榮”",
["$zhengrong1"] = "東征高句麗，保遼東安穩！",
["$zhengrong2"] = "跨海東征，家國俱榮！",
["honor"] = "榮",
--["zhengrong:zhengrong-invoke"] = "你可以發動“徵榮”，將%src 的一張牌置為“榮”<br/> <b>操作提示</b>: 點擊確定<br/ >",
["zhengrong-invoke"] = "你可以選擇其中一個手牌數大於等於你的目標角色，其一張牌置於你的武將牌上",
["hongju"] = "鴻舉",
[":hongju"] = "覺醒技，準備階段開始時，若“榮”數不小於3且有已死亡的角色，你用任意張手牌替換等量的“榮”，然後減1點體力上限，獲得“清側”。",
["@hongju"] = "你可以從中將與“榮”數量相同的牌置為新的“榮”",
["~hongju"] = "選擇要替換的手牌和不需要替換的“榮”→點擊確定",
["$hongju1"] = "一舉拿下，鴻途可得！",
["$hongju2"] = "鴻飛榮陞，舉重若輕！",
["qingce"] = "清側",
--[":qingce"] = "出牌階段，你可以將一張“榮”置入棄牌堆並選擇一名裝備區或判定區有牌的角色，棄置其裝備區或判定區裡的一張牌。",
[":qingce"] = "出牌階段，你可以獲得一張“榮”並棄置一張手牌，然後棄置場上的一張牌。",
["$qingce1"] = "感明帝之恩，清君側之賊！",
["$qingce2"] = "得太后手詔，清奸佞亂臣！",
["~guanqiujian"] = "崢嶸一生，然被平民所擊射！",
}

--陳到
chendao = sgs.General(extension, "chendao", "shu2", 4, true)
--往烈
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

wanglie = sgs.CreateTriggerSkill{
	name = "wanglie",
	events = {sgs.CardUsed, sgs.CardResponded, sgs.TargetSpecified, sgs.TrickCardCanceling, sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.card and not use.card:isKindOf("SkillCard") and use.card:hasFlag("wanglie") and string.find(use.card:getClassName(), "Slash") and RIGHT(self, use.from) then
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
			end
			if use.from and use.card and not use.card:isKindOf("SkillCard") and use.card:hasFlag("wanglie") and (use.card:isKindOf("Duel") or use.card:isKindOf("SavageAssault") or use.card:isKindOf("Collateral") or use.card:isKindOf("GodFlower")) and RIGHT(self, use.from) then
				for _, p in sgs.qlist(use.to) do
					room:setPlayerCardLimitation(p, "use, response", "Slash", false)
				end
			end
			if use.from and use.card and not use.card:isKindOf("SkillCard") and use.card:hasFlag("wanglie") and use.card:isKindOf("ArcheryAttack") and RIGHT(self, use.from) then
				for _, p in sgs.qlist(use.to) do
					room:setPlayerCardLimitation(p, "use, response", "Jink", false)
				end
			end
		elseif event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from and effect.from:hasSkill(self:objectName()) and effect.card:hasFlag("wanglie") then
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:hasFlag("wanglie") then
				room:setCardFlag(use.card, "-wanglie")
				for _, p in sgs.qlist(use.to) do
					room:removePlayerCardLimitation(p, "use, response", "Slash$0")
				end
				for _, p in sgs.qlist(use.to) do
					room:removePlayerCardLimitation(p, "use, response", "Jink$0")
				end
			end
		else
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if card and not card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:setCardFlag(card, "wanglie")
					room:setPlayerCardLimitation(player, "use, response", ".|.|.|hand", false)
					room:addPlayerMark(player, self:objectName().."_replay")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

wanglietm = sgs.CreateTargetModSkill{
	name = "#wanglietm" ,
	pattern = ".",
	distance_limit_func = function(self, from)
		if from:getMark("used_Play") == 0 and from:hasSkill("wanglie") then
			return 1000
		end
		return 0
	end
}

wanglie_clear = sgs.CreateTriggerSkill{
	name = "wanglie_clear",
	global = true,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, splayer, data, room)
		if splayer:getPhase() == sgs.Player_Play then
			for _, player in sgs.qlist(room:getAlivePlayers()) do
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "_replay") and player:getMark(mark) > 0 then
						room:setPlayerMark(player, mark, 0)
						if mark == "wanglie_replay" then
							room:removePlayerCardLimitation(player, "use, response", ".|.|.|hand")
						end
					end
				end
			end
		end
	end
}

chendao:addSkill(wanglie)
chendao:addSkill(wanglietm)
extension:insertRelatedSkills("wanglie","#wanglietm")

if not sgs.Sanguosha:getSkill("wanglie_clear") then skills:append(wanglie_clear) end

sgs.LoadTranslationTable{
["chendao"] = "陳到",
["#chendao"] = "白毦督",
["illustrator:chendao"] = "王立雄",
["wanglie"] = "往烈",
[":wanglie"] = "你於出牌階段內使用的第一張牌無距離限制；當你於出牌階段內使用牌時，你可以令其他角色不能響應此牌，然後你於此階段內不能使用牌。",
["$wanglie1"] = "猛將之烈，統帥之所往。",
["$wanglie2"] = "與子龍忠勇相往，猛烈相合。",
["~chendao"] = "我的白毦兵，再也不能為先帝出力了……",
}

--盧植
luzhiy = sgs.General(extension, "luzhiy", "qun2", "3", true)
--明任
mingren = sgs.CreateTriggerSkill{
	name = "mingren",
	events = {sgs.DrawInitialCards, sgs.AfterDrawInitialCards, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawInitialCards then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				data:setValue(data:toInt() + 2)
				player:setTag("mingren", sgs.QVariant(true))
				room:removePlayerMark(player, self:objectName().."engine")
			end
		elseif event == sgs.AfterDrawInitialCards and player:getTag("mingren"):toBool() and not player:isKongcheng() then
			room:broadcastSkillInvoke(self:objectName())
			player:setTag("mingren", sgs.QVariant(false))
			local id = room:askForExchange(player, self:objectName(), 1, 1, false, "mingren_put"):getSubcards():first()
			if id ~= -1 then
				player:addToPile("ren", id)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and not player:getPile("ren"):isEmpty() and not player:isKongcheng() then
			local card = room:askForExchange(player, self:objectName(), 1, 1, false, "mingren_exchange", true)
			if card and card:getSubcards():first() ~= -1 then
				skill(self, room, player, true)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					player:addToPile("ren", card:getSubcards():first())
					local card = sgs.Sanguosha:getCard(player:getPile("ren"):first())
					room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName(), self:objectName(), ""))
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
luzhiy:addSkill(mingren)
--貞良
function GetColor(card)
	if card:isRed() then return "red" elseif card:isBlack() then return "black" end
end

zhenliangCard = sgs.CreateSkillCard{
	name = "zhenliang",
	filter = function(self, targets, to_select)
		--return #targets == 0 and math.max(1, math.abs(to_select:getHp() - sgs.Self:getHp())) == self:subcardsLength() and sgs.Self:inMyAttackRange(to_select) and sgs.Self:objectName() ~= to_select:objectName()
		return #targets == 0 and sgs.Self:inMyAttackRange(to_select) and sgs.Self:objectName() ~= to_select:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerMark(effect.from,"@zhenliang_yang",0)
		room:setPlayerMark(effect.from,"@zhenliang_yin",1)
		sgs.Sanguosha:addTranslationEntry(":zhenliang", ""..string.gsub(sgs.Sanguosha:translate(":zhenliang"), sgs.Sanguosha:translate(":zhenliang"), sgs.Sanguosha:translate(":zhenliang2")))
		--ChangeCheck(effect.from, "luzhiy")
		room:addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
			room:removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
zhenliangVS = sgs.CreateViewAsSkill{
	name = "zhenliang",
	n = 999,
	view_filter = function(self, selected, to_select)
		return GetColor(to_select) == GetColor(sgs.Sanguosha:getCard(sgs.Self:getPile("ren"):first()))
	end,
	view_as = function(self, cards)
		local skill = zhenliangCard:clone()
		if #cards ~= 0 then
			for _, c in ipairs(cards) do
				skill:addSubcard(c)
			end
		end
		return skill
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#zhenliang") and player:getMark("@zhenliang_yang") == 1 and player:getMark("@zhenliang_yin") == 0 and player:getPile("ren"):length() > 0
	end
}
zhenliang = sgs.CreateTriggerSkill{
	name = "zhenliang",
	view_as_skill = zhenliangVS,
	events = {sgs.GameStart,sgs.EventAcquireSkill,sgs.BeforeCardsMove,sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data, room)
		if ((event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart) then
			room:setPlayerMark(player,"@zhenliang_yang",1)
			room:setPlayerMark(player,"@zhenliang_yin",0)
			sgs.Sanguosha:addTranslationEntry(":zhenliang", ""..string.gsub(sgs.Sanguosha:translate(":zhenliang"), sgs.Sanguosha:translate(":zhenliang"), sgs.Sanguosha:translate(":zhenliang1")))
			--ChangeCheck(player, "luzhiy")
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player,"@zhenliang_yin",0)
			room:setPlayerMark(player,"@zhenliang_yang",0)
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local is_nullification = false
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id) and sgs.Sanguosha:getCard(id):isKindOf("Nullification") then
					is_nullification = true
				end
			end
			local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			local invoke = false
			if not player:getPile("ren"):isEmpty() then
				for _,id in sgs.qlist(move.card_ids) do
					--if sgs.Sanguosha:getCard(id):hasFlag(self:objectName()) then
					--if sgs.Sanguosha:getCard(id):getTypeId() == sgs.Sanguosha:getCard(player:getPile("ren"):first()):getTypeId() then
					if GetColor(sgs.Sanguosha:getCard(id)) == GetColor(sgs.Sanguosha:getCard(player:getPile("ren"):first())) then
						invoke = true
					end
				end
			end
			if player:getPhase() == sgs.Player_NotActive and move.from and move.from:objectName() == player:objectName() and (move.to_place == sgs.Player_DiscardPile or (move.to_place == 7 and is_nullification)) and (extract == sgs.CardMoveReason_S_REASON_USE or extract == sgs.CardMoveReason_S_REASON_RESPONSE) and player:getMark("@zhenliang_yang") == 0 and player:getMark("@zhenliang_yin") == 1 and not player:getPile("ren"):isEmpty() and invoke then
			--move.to_place == 7 and is_nullification為神殺處理無懈可擊的特殊狀況
				local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "zhenliang-invoke", true, true)
				if to then
					room:setPlayerMark(player,"@zhenliang_yang",1)
					room:setPlayerMark(player,"@zhenliang_yin",0)
					sgs.Sanguosha:addTranslationEntry(":zhenliang", ""..string.gsub(sgs.Sanguosha:translate(":zhenliang"), sgs.Sanguosha:translate(":zhenliang"), sgs.Sanguosha:translate(":zhenliang1")))
					--ChangeCheck(player, "luzhiy")
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						to:drawCards(1, self:objectName())
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}

luzhiy:addSkill(zhenliang)

sgs.LoadTranslationTable{
	["luzhiy"] = "盧植",
	["#luzhiy"] = "國之楨幹",
	["mingren"] = "明任",
	[":mingren"] = "分發起始手牌時，你多摸兩張牌，然後將一張手牌置於武將牌上，稱為“任”。結束階段開始時，你可以用一張手牌替換“任”。",
	["$mingren1"] = "得義真所救，吾任之必盡瘁以報！",
	["$mingren2"] = "吾之任，君之明舉。",
	["mingren_put"] = "請將一張手牌做為“任”",
	["mingren_exchange"] = "你可以用手牌替換“任”",
	["ren"] = "任",
	["zhenliang"] = "貞良",
	--[":zhenliang"] = "轉換技，陽：出牌階段限一次，你可以選擇一名攻擊範圍內的其他角色並棄置X張與“任”顏色相同的牌，對其造成1點傷害；陰：當你於回合外使用或打出的牌置入棄牌堆時，若此牌與“任”類別相同，你可以令一名角色摸一張牌。（X為你與其體力值之差且至少為1）",
	--[":zhenliang2"] = "轉換技，<font color=\"#01A5AF\"><s>陽：出牌階段限一次，你可以選擇一名攻擊範圍內的其他角色並棄置X張與“任”顏色相同的牌，對其造成1點傷害</s></font>；陰：當你於回合外使用或打出的牌置入棄牌堆時，若此牌與“任”類別相同，你可以令一名角色摸一張牌。（X為你與其體力值之差且至少為1）",
	--[":zhenliang1"] = "轉換技，陽：出牌階段限一次，你可以選擇一名攻擊範圍內的其他角色並棄置X張與“任”顏色相同的牌，對其造成1點傷害；< font color=\"#01A5AF\"><s>陰：當你於回合外使用或打出的牌置入棄牌堆時，若此牌與“任”類別相同，你可以令一名角色摸一張牌</s></font>。（X為你與其體力值之差且至少為1）",
	[":zhenliang"] = "轉換技，陽：出牌階段限一次，你可以選擇一名攻擊範圍內的其他角色並棄置一張與“任”顏色相同的牌，對其造成1點傷害；陰：當你於回合外使用或打出的牌置入棄牌堆時，若此牌與“任”顏色相同，你可以令一名角色摸一張牌。",
	[":zhenliang2"] = "轉換技，<font color=\"#01A5AF\"><s>陽：出牌階段限一次，你可以選擇一名攻擊範圍內的其他角色並棄置一張與“任”顏色相同的牌，對其造成1點傷害</s></font>；陰：當你於回合外使用或打出的牌置入棄牌堆時，若此牌與“任”顏色相同，你可以令一名角色摸一張牌。",
	[":zhenliang1"] = "轉換技，陽：出牌階段限一次，你可以選擇一名攻擊範圍內的其他角色並棄置一張與“任”顏色相同的牌，對其造成1點傷害；< font color=\"#01A5AF\"><s>陰：當你於回合外使用或打出的牌置入棄牌堆時，若此牌與“任”顏色相同，你可以令一名角色摸一張牌</s></font>。",
	["$zhenliang1"] = "風霜以別草木之性，危亂而見貞良之節。",
	["$zhenliang2"] = "貞節賢良，吾之本心。",
	["zhenliang-invoke"] = "你可以發動“貞良”<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	["@zhenliang-1"] = "貞良1",
	["@zhenliang-2"] = "貞良2",
	["~luzhiy"] = "泓泓眸子淵亭，不見蛾眉只見經……",
}

--嚴顏
yanyan = sgs.General(extension, "yanyan", "shu2", 4, true)
--拒戰
juzhan = sgs.CreateTriggerSkill{
	name = "juzhan",
	--frequency = sgs.Skill_Change,
	events = {sgs.GameStart,sgs.EventAcquireSkill,sgs.TargetConfirmed, sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if ((event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart) then
			room:setPlayerMark(player,"@juzhan_yang",1)
			room:setPlayerMark(player,"@juzhan_yin",0)
			sgs.Sanguosha:addTranslationEntry(":juzhan", ""..string.gsub(sgs.Sanguosha:translate(":juzhan"), sgs.Sanguosha:translate(":juzhan"), sgs.Sanguosha:translate(":juzhan1")))
			--ChangeCheck(player, "yanyan")
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player,"@juzhan_yang",0)
			room:setPlayerMark(player,"@juzhan_yin",0)
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local _data = sgs.QVariant()
			_data:setValue(use.from)
			if use.card:isKindOf("Slash") and player:getMark("@juzhan_yang") == 1 and player:getMark("@juzhan_yin") == 0 and use.from and use.to:contains(player) and use.from:objectName() ~= player:objectName() and room:askForSkillInvoke(player, self:objectName(), _data) then
				room:setPlayerMark(player,"@juzhan_yang",0)
				room:setPlayerMark(player,"@juzhan_yin",1)
				sgs.Sanguosha:addTranslationEntry(":juzhan", ""..string.gsub(sgs.Sanguosha:translate(":juzhan"), sgs.Sanguosha:translate(":juzhan"), sgs.Sanguosha:translate(":juzhan2")))
				--ChangeCheck(player, "yanyan")
				room:broadcastSkillInvoke(self:objectName(), 2)
				local players = sgs.SPlayerList()
				players:append(player)
				players:append(use.from)
				room:sortByActionOrder(players)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:drawCards(players, 1, self:objectName())
					room:addPlayerMark(use.from, "juzhanFrom-Clear")
					room:addPlayerMark(player, "juzhanTo-Clear")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		else
			local use = data:toCardUse()
			local _data = sgs.QVariant()
			for _, p in sgs.qlist(use.to) do
				_data:setValue(p)
				if use.card:isKindOf("Slash") and player:getMark("@juzhan_yang") == 0 and player:getMark("@juzhan_yin") == 1 and not p:isNude() and room:askForSkillInvoke(player, self:objectName(), _data) then
					room:setPlayerMark(player,"@juzhan_yang",1)
					room:setPlayerMark(player,"@juzhan_yin",0)
					sgs.Sanguosha:addTranslationEntry(":juzhan", ""..string.gsub(sgs.Sanguosha:translate(":juzhan"), sgs.Sanguosha:translate(":juzhan"), sgs.Sanguosha:translate(":juzhan1")))
					--ChangeCheck(player, "yanyan")
					room:broadcastSkillInvoke(self:objectName(), 1)
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						local id = room:askForCardChosen(player, p, "he", self:objectName())
						if id ~= -1 then
							room:obtainCard(player, id, false)
							room:addPlayerMark(player, "juzhanFrom-Clear")
							room:addPlayerMark(p, "juzhanTo-Clear")
						end
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
		return false
	end
}
juzhan_ban = sgs.CreateProhibitSkill{
	name = "#juzhan_ban", 
	is_prohibited = function(self, from, to, card)
		return not card:isKindOf("SkillCard") and (from:getMark("juzhanFrom-Clear") > 0 and to:getMark("juzhanTo-Clear") > 0)
	end,
}


yanyan:addSkill(juzhan)
yanyan:addSkill(juzhan_ban)

sgs.LoadTranslationTable{
	["yanyan"] = "嚴顏",
	["#yanyan"] = "斷頭將軍",
	["illustrator:yanyan"] = "Town",
	["juzhan"] = "拒戰",
	[":juzhan"] = "轉換技，陰：當你成為其他角色使用【殺】的目標後，你可以與其各摸一張牌，然後其本回合不能對你使用牌；陽：當你使用【殺】指定一名角色為目標後，你可以獲得其一張牌，然後你本回合不能對其使用牌。",
	[":juzhan2"] = "轉換技，陰：當你成為其他角色使用【殺】的目標後，你可以與其各摸一張牌，然後其本回合不能對你使用牌；<font color=\" #01A5AF\"><s>陽：當你使用【殺】指定一名角色為目標後，你可以獲得其一張牌，然後你本回合不能對其使用牌</s></font>。" ,
	[":juzhan1"] = "轉換技，<font color=\"#01A5AF\"><s>陰：當你成為其他角色使用【殺】的目標後，你可以與其各摸一張牌，然後其本回合不能對你使用牌</s></font>；陽：當你使用【殺】指定一名角色為目標後，你可以獲得其一張牌，然後你本回合不能對其使用牌。" ,
	["$juzhan1"] = "砍頭便砍頭，何為怒邪！",
	["$juzhan2"] = "我州但有斷頭將軍，無降將軍之也！",
	["~yanyan"] = "寧可斷頭死，安能屈膝降！",
}
--郝昭
haozhao = sgs.General(extension,"haozhao","wei2","4",true)
--鎮骨：結束階段，你可以選擇一名其他角色，你的回合結束時和該角色的下個回合結束時，其將手牌摸至或棄至與你手牌數相同。
zhengu = sgs.CreateTriggerSkill{
	name = "zhengu",
	frequency = sgs.Skill_NotFrequent,
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_Finish and RIGHT(self, player) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark("zhengu"..p:objectName()) > 0 then
					room:setPlayerMark(player, "zhengu"..p:objectName(), 0)
					if p:getMark("@zhengu") > 0 then
						room:setPlayerMark(p, "@zhengu", 0)
					end
				end
			end
			if RIGHT(self, player) then
				local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "zhengu-invoke", true, true)
				if to then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						room:addPlayerMark(to, "@zhengu")
						room:addPlayerMark(player, "zhengu"..to:objectName())
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			if RIGHT(self, player) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:getMark("zhengu" .. p:objectName()) > 0 and p:getMark("@zhengu") > 0 then
						room:doAnimate(1, player:objectName(), p:objectName())
						local n = player:getHandcardNum() - p:getHandcardNum()
						if n < 0 then
							room:askForDiscard(p, self:objectName(), -n, -n, false, false)
						elseif n > 0 then
							--p:drawCards(n, self:objectName())
							p:drawCards(math.min(n, 5 - p:getHandcardNum()), self:objectName())
						end
					end
				end
			elseif player:getMark("@zhengu") > 0 then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:doAnimate(1, p:objectName(), player:objectName())
					local n = p:getHandcardNum() - player:getHandcardNum()
					if n < 0 then
						room:askForDiscard(player, self:objectName(), -n, -n, false, false)
					elseif n > 0 then
						player:drawCards(math.min(n, 5 - player:getHandcardNum()), self:objectName())
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

haozhao:addSkill(zhengu)

sgs.LoadTranslationTable{
	["haozhao"] = "郝昭",
	["zhengu"] = "鎮骨",
	[":zhengu"] = "結束階段，你可以選擇一名其他角色，你的回合結束時和該角色的下個回合結束時，其將手牌摸至或棄至與你手牌數相同。",
	["@zhengu-choose"]= "選擇一名其他角色，你的回合結束時和該角色的下個回合結束時，其將手牌摸至或棄至與你手牌數相同。",
	["$zhengu1"] = "镇守城池，当以骨相拼！",
	["$zhengu2"] = "孔明计虽百算，却难抵吾镇骨千拒。",
	["zhengu-invoke"] = "你可以發動“鎮骨”",
}
--[新增]  雷	諸葛瞻   男, 蜀,  3  體力
zhugezhan = sgs.General(extension,"zhugezhan","shu2","3",true,true)
--罪論
zuilunCard = sgs.CreateSkillCard{
	name = "zuilun",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and ((sgs.Self:getMark("zuilunequip_Play") > 0 and not to_select:isKongcheng()) or (sgs.Self:getMark("zuilunhand_Play") > 0 and to_select:hasEquip()) or (sgs.Self:getMark("zuilunhand_Play") == 0 and sgs.Self:getMark("zuilunequip_Play") == 0 and not to_select:isNude()))
	end,
	on_use = function(self, room, source, targets)
		local pattern = "he"
		if source:getMark("zuilunhand_Play") > 0 then
			pattern = "e"
		elseif source:getMark("zuilunequip_Play") > 0 then
			pattern = "h"
		end
		local id = room:askForCardChosen(source, targets[1], pattern, self:objectName())
		if id ~= -1 then
			if room:getCardPlace(id) == sgs.Player_PlaceHand then
				room:addPlayerMark(source, "zuilunhand_Play")
			elseif room:getCardPlace(id) == sgs.Player_PlaceEquip then
				room:addPlayerMark(source, "zuilunequip_Play")
			end
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				room:obtainCard(source, sgs.Sanguosha:getCard(id), false)
				targets[1]:drawCards(1, self:objectName())
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
zuilun = sgs.CreateZeroCardViewAsSkill{
	name = "zuilun",
	view_as = function()
		return zuilunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("zuilunhand_Play") == 0 or player:getMark("zuilunequip_Play") == 0
	end
}
											  
--〖父蔭〗 
fuyin = sgs.CreateProhibitSkill{
	name = "fuyin",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and not to:getArmor() and from:getHandcardNum() >= to:getHandcardNum() and from:objectName() ~= to:objectName() and (card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("FireAttack"))
	end
} 

zhugezhan:addSkill(zuilun)
zhugezhan:addSkill(fuyin)

sgs.LoadTranslationTable{
	["zhugezhan"] = "諸葛瞻",
	["#zhugezhan"] = "臨難死義",
	["zuilun"] = "罪論",
	[":zuilun"] = "出牌階段，你可以獲得一名其他角色的一張牌(手牌、裝備區各限一次)，然後該角色摸一張牌。",
	["fuyin"] = "父蔭",
	[":fuyin"] = "鎖定技，若你的裝備區裡沒有防具牌，手牌數大於等於你的其他角色不能使用【殺】、【決鬥】或【火攻】指定你為目標。",
} 

--OL版本 新版技能 3勾玉
zhugezhan_sec_rev = sgs.General(extension,"zhugezhan_sec_rev","shu2","3",true)
--罪論：結束階段，你可以觀看牌堆頂三張牌，你每滿足以下一項便保留一張，然後以任意順序放回其餘的牌：1、你於此回合內造成過傷害;2、你於此回合內未棄置過牌;3、手牌數為全場最少，若均不滿足，你與一名其他角色失去1點體力。
zuilun_sec_rev = sgs.CreateTriggerSkill{
	name = "zuilun_sec_rev",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			local draw_num = 0
			if player:getMark("has_discard-Clear") == 0 then
				draw_num = draw_num + 1
			end
			if player:getMark("damage_record-Clear") > 0 then
				draw_num = draw_num + 1
			end
			local min_card_num = 1000
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				min_card_num = math.min(min_card_num, p:getHandcardNum())
			end
			if min_card_num == player:getHandcardNum() then
				draw_num = draw_num + 1
			end
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("zuilun_sec_rev_invoke:"..draw_num)) then
				local log = sgs.LogMessage()
				log.type = "#zuilun_draw_card_num"
				log.from = player
				log.arg = draw_num
				room:sendLog(log)
				
				local cards = room:getNCards(3, false)
				room:broadcastSkillInvoke(self:objectName())
				room:askForGuanxing(player, cards, sgs.Room_GuanxingUpOnly)
				if draw_num > 0 then
					for i = 1, draw_num, 1 do
						room:obtainCard(player, room:getDrawPile():first(), false)
					end
				elseif draw_num == 0 then
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "zuilun_sec_rev-invoke", false, true)
					room:loseHp(player)
					room:loseHp(target)
				end
			end
		end
	end
}
--父蔭：鎖定技，你每回合第一次成為【殺】或【決鬥】的目標後，若你的手牌數小於等於該角色，此牌對你無效
fuyin_sec_rev = sgs.CreateTriggerSkill{
	name = "fuyin_sec_rev",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to and use.to:contains(player) and player:hasSkill(self:objectName()) then
				room:addPlayerMark(player, self:objectName().."-Clear")
			end
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to and use.to:contains(player) and player:hasSkill(self:objectName())
			and use.from:getHandcardNum() >= player:getHandcardNum() and player:getMark(self:objectName().."-Clear") == 1 and player:hasSkill("fuyin_sec_rev")
			then
				room:addPlayerMark(player, self:objectName().."-Clear")
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
				room:broadcastSkillInvoke(self:objectName())
				local log = sgs.LogMessage()
				log.type = "#fuyin_Protect"
				log.from = fuyin_target
				room:sendLog(log)
			end
		end
		return false
	end
}

zhugezhan_sec_rev:addSkill(zuilun_sec_rev)
zhugezhan_sec_rev:addSkill(fuyin_sec_rev)

sgs.LoadTranslationTable{
	["zhugezhan_sec_rev"] = "OL諸葛瞻",
	["&zhugezhan_sec_rev"] = "諸葛瞻",
	["#zhugezhan_sec_rev"] = "臨難死義",
	["zuilun_sec_rev"] = "罪論",
	[":zuilun_sec_rev"] = "結束階段，你可以觀看牌堆頂三張牌，你每滿足以下一項便獲得牌堆頂一張牌，然後以任意順序放回其餘的牌：1.你於此回合內造成過傷害；2.你於此回合內未棄置過牌；3.手牌數為全場最少。若均不滿足，你與一名其他角色失去1點體力。",
	["zuilun_sec_rev:zuilun_sec_rev_invoke"] = "你想發動技能「罪論」嗎？(可以獲得牌堆頂 %src 張牌)",
	["#zuilun_draw_card_num"] = "%from 的「<font color=\"yellow\"><b>罪論</b></font>」效果被觸發，可以獲得牌堆頂 %arg 張牌",
	["zuilun_sec_rev-invoke"] = "你可以發動「罪論」<br/> <b>操作提示</b>: 選擇一名角色→點擊確定<br/>",
	["$zuilun_sec_rev1"] = "吾有三罪，未能除黃皓，制伯約，守國土。",
	["$zuilun_sec_rev2"] = "數罪當論，吾愧對先帝恩惠。",
	["fuyin_sec_rev"] = "父蔭",
	[":fuyin_sec_rev"] = "鎖定技，你每回合第一次成為【殺】或【決鬥】的目標後，若你的手牌數小於等於該角色，此牌對你無效。",
	["#fuyin_Protect"] = "%from 的「<font color=\"yellow\"><b>父蔭</b></font>」效果被觸發，此牌無效",
	["$fuyin_sec_rev1"] = "得父蔭庇，平步青雲。",
	["$fuyin_sec_rev2"] = "吾自幼心懷父誡，方不愧父親蔭庇。",
	["~sec_rev_zhugezhan"] = "臨難而死義，無愧先父。",
} 

--王平
wangping = sgs.General(extension,"wangping","shu2","4",true)
--飛軍
feijuncard = sgs.CreateSkillCard{
	name = "feijun",
	target_fixed = false,
	will_throw = true,
	--mute = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName() and 
		(to_select:getEquips():length() > sgs.Self:getEquips():length()
		or to_select:getHandcardNum() > sgs.Self:getHandcardNum())
	end,	
	on_use = function(self, room, source, targets)
		local choicelist = {}
		if targets[1]:getEquips():length() > source:getEquips():length() then
			table.insert(choicelist, "feijun2")
		end
		if targets[1]:getHandcardNum() > source:getHandcardNum() then
			table.insert(choicelist, "feijun1")
		end
		local choice = room:askForChoice(source, "feijun",  table.concat(choicelist, "+"))
		if choice == "feijun2" then
			local card = room:askForCard(targets[1], ".|.|.|equipped!", "@feijun_throw", sgs.QVariant(), sgs.Card_MethodNone)
			if card then
				room:throwCard(card, targets[1], source)
			end
		elseif choice == "feijun1" then
			local card = room:askForCard(targets[1], ".!", "@feijun_give", sgs.QVariant(), sgs.Card_MethodNone)
			if card then
				room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
			end
		end
	end		
}

feijun = sgs.CreateViewAsSkill{
	name = "feijun",
	n=1,
	view_filter = function(self,selected,to_select)
		if #selected >0 then return false end		
		return true
	end,	
	view_as = function(self,cards)
		if #cards ~= 1 then return nil end		
		local acard = feijuncard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName("feijun")		
		return acard
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#feijun") < 1
	end,	
}					  
--兵略 
binglve = sgs.CreateTriggerSkill{
	name = "binglve", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardFinished}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		if event == sgs.CardFinished then
				local use = data:toCardUse()
				if use.card:getSkillName() == "feijun" then
					for _, p in sgs.qlist(use.to) do
						if p:getMark("@crtfeijun") == 0 then
							room:sendCompulsoryTriggerLog(player, self:objectName())
							--room:getThread():delay(4200)
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(2, self:objectName())
							room:setPlayerMark(p,"@crtfeijun",1)
						end
					end
				end
			end
			return false
	end
} 

wangping:addSkill(feijun)
wangping:addSkill(binglve)

sgs.LoadTranslationTable{
	["wangping"] = "王平",
	["#wangping"] = "兵謀以致用",
	["feijun"] = "飛軍",
	[":feijun"] = "出牌階段限一次，你可以棄置一張牌，然後選擇一項：令一名手牌數大於你的角色交給你一張牌；或令一名裝備區裡牌數大於你的角色棄置一張裝備牌。",
	["binglve"] = "兵略",
	[":binglve"] = "鎖定技，當你發動〖飛軍〗時，若目標與你之前指定的目標均不相同，則你摸兩張牌。",
	["illustrator:wangping"] = "YanBai",
	[":feijun1"] = "令一名手牌數大於你的角色將一張手牌交給你",
	[":feijun2"] = "令一名裝備區裡的牌數大於你的角色棄置其裝備區裡的一張牌",
	["$feijun1"] = "無當飛軍，伐叛亂，鎮蠻夷！",
	["$feijun2"] = "山地崎嶇，也擋不住飛軍破勢！",
	["$binglve1"] = "奇略兵速，敵未能料之。",
	["$binglve2"] = "兵略者，明戰勝攻取之數、形機之勢、詐譎之變。",
	["~wangping"] = "無當飛軍，也有困於山林之時……",
	["@feijun_give"] = "請交給其一張手牌",
	["@feijun_throw"] = "請棄置裝備區裡的一張牌",
	["feijun1"] = "交出一張手牌",
	["feijun2"] = "棄置裝備區裡的一張牌",
}

--陸抗
ol_lukang = sgs.General(extension,"ol_lukang","wu2","4",true)
--謙節：鎖定技，你不能被橫置，且不能成為延時類錦囊牌的目標；當你成為其他角色拼點的目標時，你摸一張牌。
qianjie = sgs.CreateTriggerSkill{
	name = "qianjie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ChainStateChanged,sgs.Pindian},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ChainStateChanged then
			if player:isChained() then
				return true
			end
		elseif event == sgs.Pindian then
			player:drawCards(1)
		end
	end,
} 

qianjiePs = sgs.CreateProhibitSkill{
	name = "#qianjiePs",
	frequency = sgs.Skill_Compulsory,
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("qianjie") and (card:isKindOf("DelayedTrick"))
	end
}
--決堰：出牌階段限一次，你可以廢除你裝備區的一個裝備欄，然後執行對應的一項：武器欄，本回合你可以多使用三張【殺】；防具欄，摸三張牌，本回合手牌上限+3；2個坐騎欄，本回合你使用牌無距離限制；寶物欄，本回合獲得技能“集智”。
jueyanCard = sgs.CreateSkillCard{
	name = "jueyan" ,
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)	
		local choice = ChooseThrowEquipArea(self, source,true,false,true)
		if choice == "AbolishWeapon" then
			room:addPlayerMark(source, "jueyan_weapon-Clear")
		elseif choice == "AbolishArmor" then
			source:drawCards(3)
			room:addPlayerMark(source, "jueyan_armor-Clear")
		elseif choice == "AbolishHorse" then
			room:addPlayerMark(source, "jueyan_horse-Clear")
		elseif choice == "AbolishTreasure" then
			room:addPlayerMark(source, "jueyan_treasure-Clear")
			room:acquireSkill(source, "jizhi_po")
			room:addPlayerMark(source, "jizhi_po_skillClear")
		end
		if n ~= "cancel" then
			throwEquipArea(self,source, choice)
		end
	end
}

jueyan = sgs.CreateZeroCardViewAsSkill{
	name = "jueyan",
	view_as = function(self,cards)
		return jueyanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#jueyan") < 1
	end
}

jueyanTM = sgs.CreateTargetModSkill{
	name = "#jueyanTM",
	frequency = sgs.Skill_NotFrequent,
	residue_func = function(self, player)
		if player:hasSkill("jueyan") and player:getMark("jueyan_weapon-Clear") > 0 then
			return 3
		end
	end,
	distance_limit_func = function(self, from)
		if from:getMark("jueyan_horse-Clear") > 0 then
			return 1000
		end
		return 0
	end

}
jueyanMC = sgs.CreateMaxCardsSkill{
	name = "#jueyanMC", 
	extra_func = function(self, target)
		if target:getMark("jueyan_armor-Clear") > 0 then
			return 3
		end
	end
}
--(懷柔：出牌階段，你可以重鑄裝備牌。)
huairouCard = sgs.CreateSkillCard{
	name = "huairou",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:objectName(), ""))
			room:broadcastSkillInvoke("@recast")

			local log = sgs.LogMessage()
			log.type = "#SkillEffect_Recast"
			log.from = player
			log.arg = self:objectName()
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)

			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				source:drawCards(1, "recast")
				room:removePlayerMark(source, self:objectName().."engine")
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
huairou = sgs.CreateOneCardViewAsSkill{
	name = "huairou",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
		local skill_card = huairouCard:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end
}

--破勢：覺醒技，準備階段開始時，若你的裝備欄均被廢除或體力值為1，則你扣減1點體力上限，然後將手牌補至體力上限值，失去技能“決堰”並獲得技能“懷柔”。
poshi = sgs.CreateTriggerSkill{
	name = "poshi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getHp() == 1 or (player:getMark("@AbolishWeapon") > 0 and player:getMark("@AbolishOffensiveHorse") > 0 and player:getMark("@AbolishDefensiveHorse") > 0 and player:getMark("@AbolishTreasure") > 0 and player:getMark("@AbolishArmor") > 0) or player:getMark("Skill_Wake_can_direct_wake"..self:objectName()) > 0 then
			if room:changeMaxHpForAwakenSkill(player) then
				room:addPlayerMark(player, "poshi")
				room:broadcastSkillInvoke(self:objectName())	
				room:doSuperLightbox("ol_lukang","poshi")
				local n = player:getMaxHp() - player:getHandcardNum() 
				if n > 0 then
					player:drawCards(n)
				end
				room:acquireSkill(player, "huairou")
				room:detachSkillFromPlayer(player, "jueyan")
			end
		end	
	end,

	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_Start)
				and target:hasSkill("poshi")
				and target:isAlive()
				and (target:getMark("poshi") == 0)
	end
}

if not sgs.Sanguosha:getSkill("huairou") then skills:append(huairou) end

ol_lukang:addRelateSkill("huairou")
ol_lukang:addSkill(qianjie)
ol_lukang:addSkill(jueyan)
ol_lukang:addSkill(poshi)
ol_lukang:addSkill(qianjiePs)
ol_lukang:addSkill(jueyanTM)
ol_lukang:addSkill(jueyanMC)

extension:insertRelatedSkills("qianjie","#qianjiePs") 
extension:insertRelatedSkills("jueyan","#jueyanTM") 
extension:insertRelatedSkills("jueyan","#jueyanMC") 

sgs.LoadTranslationTable{
	["ol_lukang"] = "陸抗",
	["#ol_lukang"] = "社稷之瑰寶",
	["qianjie"] = "謙節",
	[":qianjie"] = "鎖定技，你不能被橫置，且不能成為延時類錦囊牌的目標；當你成為其他角色拼點的目標時，你摸一張牌。",
	["jueyan"] = "決堰",
	[":jueyan"] = "出牌階段限一次，你可以廢除你裝備區的一個裝備欄，然後執行對應的一項：武器欄，本回合你可以多使用三張【殺】；防具欄，摸三張牌，本回合手牌上限+3；2個坐騎欄，本回合你使用牌無距離限制；寶物欄，本回合獲得技能“集智”。",
	["poshi"] = "破勢",
	[":poshi"] = "覺醒技，準備階段開始時，若你的裝備欄均被廢除或體力值為1，則你扣減1點體力上限，然後將手牌補至體力上限值，失去技能“決堰”並獲得技能“懷柔”。",
	["huairou"] = "懷柔",
	[":huairou"] = "出牌階段，你可以重鑄裝備牌。",
}

--張繡
zhangxiu = sgs.General(extension,"zhangxiu","qun2","4",true)
--雄亂：限定技，出牌階段，你可以廢除你的判定區和裝備區，然後指定一名其他角色，直到回合結束，你對其使用牌無距離和次數限制，其不能使用和打出手牌。
xiongluancard = sgs.CreateSkillCard{
	name = "xiongluan",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return not to_select:objectName() ~= sgs.Self:objectName() 
		end
		return false
	end ,
	on_use = function(self, room, source, targets)
		room:doSuperLightbox("zhangxiu","xiongluan")
		throwEquipArea(self,source, "AbolishWeapon")
		throwEquipArea(self,source, "AbolishArmor")
		throwEquipArea(self,source, "AbolishHorse")
		throwEquipArea(self,source, "AbolishTreasure")
		room:addPlayerMark(source, "@AbolishJudge")

		room:addPlayerMark(targets[1], "ban_ur")
		room:setPlayerCardLimitation(targets[1], "use,response", ".|.|.|hand", false)

		room:addPlayerMark(source, "kill_caocao-Clear")
		room:addPlayerMark(targets[1], "be_killed-Clear")
		local assignee_list = source:property("extra_slash_specific_assignee"):toString():split("+")

		table.insert(assignee_list, targets[1]:objectName())
		room:setPlayerProperty(source, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
		room:setFixedDistance(source, targets[1], 1);
		room:removePlayerMark(source, "@kill_caocao")
	end
}
xiongluanVS = sgs.CreateZeroCardViewAsSkill{
	name = "xiongluan" ,
	view_as = function(self,cards)
		return xiongluancard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@kill_caocao") > 0
	end
}
xiongluan = sgs.CreateTriggerSkill{
	name = "xiongluan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kill_caocao",
	view_as_skill = xiongluanVS ,
	on_trigger = function()

	end,
}
--從諫：當你成為錦囊牌的目標時，若此牌的目標數大於1，則你可以交給其中一名目標角色一張牌，然後摸一張牌。若你給出的牌是裝備牌，改為摸兩張牌。
congjianCard = sgs.CreateSkillCard{
	name = "congjianCard" ,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:hasFlag("congjianTarget") and (to_select:objectName() ~= sgs.Self:objectName())
		end
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), "congjian","")
		room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,reason)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if card:getRealCard():isKindOf("EquipCard") then
			source:drawCards(2)
		else
			source:drawCards(1)
		end
	end
}
congjianVS = sgs.CreateViewAsSkill{
	name = "congjian" ,
	response_pattern = "@@congjian",
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return true
	end ,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = congjianCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end ,
}
congjian = sgs.CreateTriggerSkill{
	name = "congjian" ,
	events = {sgs.TargetConfirmed} ,
	view_as_skill = congjianVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.card:isKindOf("TrickCard") and use.to:length() >= 2 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.to:contains(p) then
						room:setPlayerFlag(p, "congjianTarget")
					end
				end	
				room:askForUseCard(player, "@@congjian", "@congjian", -1, sgs.Card_MethodDiscard)
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.to:contains(p) then
						room:setPlayerFlag(p, "-congjianTarget")
					end
				end
			end
		end
		return false
	end
}

zhangxiu:addSkill(xiongluan)
zhangxiu:addSkill(congjian)

sgs.LoadTranslationTable{
	["zhangxiu"] = "張繡",
	["#zhangxiu"] = "",
	["xiongluan"] = "雄亂",
	[":xiongluan"] = "限定技，出牌階段，你可以廢除你的判定區和裝備區，然後指定一名其他角色，直到回合結束，你對其使用牌無距離和次數限制，其不能使用和打出手牌。",
	["congjian"] = "從諫",
	[":congjian"] = "當你成為錦囊牌的目標時，若此牌的目標數大於1，則你可以交給其中一名目標角色一張牌，然後摸一張牌。若你給出的牌是裝備牌，改為摸兩張牌。",
	["#str_Fuji"] = "%from 的技能 “<font color=\"yellow\"><b>伏騎</b></font>”被觸發，與 %from 距離為1的其他角色 %to 無法響應此 %arg ",
	["@congjian"] = "則你可以交給其中一名目標角色一張牌，然後摸一張牌。若你給出的牌是裝備牌，改為摸兩張牌",
	["~congjian"] = "選擇一張牌->選擇其中一名目標角色->點擊「確定」",
}

--OL神甘寧
shenganning = sgs.General(extension,"shenganning","god","6",true)

poxiCard = sgs.CreateSkillCard{
	name = "poxi",
	will_throw = false,
	filter = function(self, targets, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@poxi" or sgs.Sanguosha:getCurrentCardUsePattern() == "@poxi_less" then
			return #targets < 0
		end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@poxi" or sgs.Sanguosha:getCurrentCardUsePattern() == "@poxi_less" then
			return #targets == 0
		end
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@poxi" then
			for _,id in sgs.qlist(self:getSubcards()) do
				room:setCardFlag(sgs.Sanguosha:getCard(id), "poxi")
			end
		else
			if targets[1] then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(source, self:objectName().."engine")
				if source:getMark(self:objectName().."engine") > 0 then
					local ids = targets[1]:handCards()
					room:setPlayerFlag(source, "Fake_Move")
					local _guojia = sgs.SPlayerList()
					_guojia:append(source)
					local move = sgs.CardsMoveStruct(ids, targets[1], source, sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
					local moves = sgs.CardsMoveList()
					moves:append(move)
					room:notifyMoveCards(true, moves, false, _guojia)
					room:notifyMoveCards(false, moves, false, _guojia)
					local invoke = room:askForUseCard(source, "@poxi", "@poxi")			
					local idt = sgs.IntList()
					for _,id in sgs.qlist(targets[1]:handCards()) do
						if ids:contains(id) then
							idt:append(id)
						end
					end
					local move_to = sgs.CardsMoveStruct(idt, source, targets[1], sgs.Player_PlaceHand, sgs.Player_PlaceHand, sgs.CardMoveReason())
					local moves_to = sgs.CardsMoveList()
					moves_to:append(move_to)
					room:notifyMoveCards(true, moves_to, false, _guojia)
					room:notifyMoveCards(false, moves_to, false, _guojia)
					room:setPlayerFlag(source, "-Fake_Move")
					if invoke then
						local x = 0
						local dummy = sgs.Sanguosha:cloneCard("slash")
						local dummy_target = sgs.Sanguosha:cloneCard("slash")
						if source:getHandcardNum() + targets[1]:getHandcardNum() >= 4 then
							for _,id in sgs.qlist(source:handCards()) do
								if sgs.Sanguosha:getCard(id):hasFlag("poxi") then
									dummy:addSubcard(id)
								end
							end
							for _,id in sgs.qlist(targets[1]:handCards()) do
								if sgs.Sanguosha:getCard(id):hasFlag("poxi") then
									dummy_target:addSubcard(id)
								end
							end
							if dummy:subcardsLength() > 0 then
								room:throwCard(dummy, source)
							end
							if dummy_target:subcardsLength() > 0 then
								room:throwCard(dummy_target, targets[1], source)
							end
						end
						if dummy:subcardsLength() == 0 then
							room:loseMaxHp(source)
						elseif dummy:subcardsLength() == 1 then
							room:setPlayerFlag(source, "Global_PlayPhaseTerminated")
							room:setPlayerFlag(source, "poxi")
						elseif dummy:subcardsLength() == 3 then
							room:recover(source, sgs.RecoverStruct(source))
						elseif dummy:subcardsLength() == 4 then
							source:drawCards(4, self:objectName())
						end
					end
					room:removePlayerMark(source, self:objectName().."engine")
				end
			end
		end
	end
}	
poxi = sgs.CreateViewAsSkill{
	name = "poxi",
	n = 4,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@poxi" then
			for _,c in sgs.list(selected)do
				if c:getSuit() == to_select:getSuit() then return false end
			end
			return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
		end
		return true
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@poxi" then
			if #cards ~= 4 then return nil end
			local skillcard = poxiCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			return skillcard
		else
			if #cards ~= 0 then return nil end
			return poxiCard:clone()
		end
	end,
	enabled_at_play = function(self, target)
		return not target:hasUsed("#poxi")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@poxi"
	end
}
--〖劫營〗 遊戲開始時，你獲得 1 個“營”標記。結束階段，你可以用“營”標記 1 名角色；有“營”的角色摸牌階段多摸 1 張牌，出牌階段可以多出 1 張【殺】，手牌上限 +1，回合結束將所有手牌交給你。

jieyingy = sgs.CreateTriggerSkill{
	name = "jieyingy",
	--設定priority用來讓界鐵騎可以封劫營技能(時機相同)
	priority = 6,
	events = {sgs.TurnStart, sgs.EventPhaseStart, sgs.EventPhaseChanging},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p and p:isAlive() and p:objectName() ~= player:objectName() and player:getMark("@thiefed") > 0 then
					room:addPlayerMark(p, self:objectName().."engine")
					if p:getMark(self:objectName().."engine") > 0 then
						player:loseMark("@thiefed")
						room:broadcastSkillInvoke(self:objectName(), 2)
						room:obtainCard(p, player:wholeHandCards(), false)
						room:removePlayerMark(p, self:objectName().."engine")
					end
				end
			end
		else
			local players, targets = sgs.SPlayerList(), sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@thiefed") == 0 then
					players:append(p)
				else
					targets:append(p)
				end
			end
			if event == sgs.TurnStart and targets:isEmpty() and RIGHT(self, player) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					player:gainMark("@thiefed")
					room:removePlayerMark(player, self:objectName().."engine")
				end
			elseif event == sgs.EventPhaseStart and RIGHT(self, player) and not players:isEmpty() and player:getMark("@thiefed") > 0 and player:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(player, self:objectName(), data) then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "jieyingy-invoke", true, true)
				if target then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						player:loseMark("@thiefed")
						room:broadcastSkillInvoke(self:objectName(), 1)
						target:gainMark("@thiefed")
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

jieyingyStart = sgs.CreateTriggerSkill{
	name = "jieyingyStart" ,
	frequency = sgs.Skill_Compulsory,
	global = true, 
	events = {sgs.DrawNCards} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			if player:getMark("@thiefed") > 0 then
				local count = data:toInt() + room:findPlayersBySkillName("jieyingy"):length()
				data:setValue(count)
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("jieyingyStart") then skills:append(jieyingyStart) end

jieyingyTargetMod = sgs.CreateTargetModSkill{
	name = "#jieyingyTargetMod",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self, player)
		if player:getMark("@thiefed") > 0 then
			return 1
		end
	end,
}

jieyingyMax = sgs.CreateMaxCardsSkill{
	name = "#jieyingyMax", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		if target:getMark("@thiefed") > 0 then
			return 1
		end
	end
}

shenganning:addSkill(poxi)
shenganning:addSkill(jieyingyTargetMod)
shenganning:addSkill(jieyingyMax)
shenganning:addSkill(jieyingy)
extension:insertRelatedSkills("jieyingy","#jieyingyTargetMod")
extension:insertRelatedSkills("jieyingy","#jieyingyMax")

sgs.LoadTranslationTable{
["shenganning"]="神甘寧",
["#shenganning"] = "江表之力牧",
["poxi"] = "魄襲",
[":poxi"] = "出牌階段限一次，你可以觀看一名其他角色的手牌，然後你可以棄置你與其手里共計四張不同花色的牌。若如此做，根據此次棄置你的牌數量執行以下效果：零，體力上限減1；一張，你結束出牌階段且本回合手牌上限-1；三張，你回复1點體力；四張，你摸四張牌。",
["@thiefed"] = "營",	
["jieyingy"] = "劫營",
[":jieyingy"] = "回合開始，若沒有角色有“營”標記，你獲得1個“營”標記；結束階段，你可以將你的“營”交給一名角色；有“營”標記的角色摸牌階段多摸一張牌，其於出牌階段使用【殺】的次數上限+1，其手牌上限+1。有“營”的其他角色回合結束後，其移去“營”標記，然後你獲得其所有手牌。",
["@jieyingy-choose"] = "你可以用“營”標記 1 名角色（有“營”的角色摸牌階段多摸 1 張牌，出牌階段可以多出 1 張【殺】，手牌上限 +1，回合結束將所有手牌交給你。）",
["@poxi"] = "你可以發動“魄襲”",
["@poxi_less"] = "你可以發動“魄襲”",
["jieyingy-invoke"] = "你可以發動“劫營”",
["~poxi"] = "選擇四張花色不同的手牌→點擊確定",
["~poxi_less"] = "點擊技能→點擊確定",
["$poxi1"] = "夜襲敵軍，挫其銳氣。",
["$poxi2"] = "受主知遇，襲敵不懼。",
["$jieyingy1"] = "裹甲銜枚，劫營如如無人之境！",
["$jieyingy2"] = "劫營速戰，措手不及！",
["@poxi"] = "你可以發動“魄襲”",
["@poxi_less"] = "你可以發動“魄襲”",
["~poxi"] = "選擇四張花色不同的手牌→點擊確定",
["~poxi_less"] = "點擊技能→點擊確定",
}
--神陸遜
shenluxun_sec_rev = sgs.General(extension,"shenluxun_sec_rev","god","4",true)
--〖軍略〗 鎖定技，當你造成或受到 1 點傷害後，你獲得 1 個“軍略”標記。		　
junlve = sgs.CreateTriggerSkill{
	name = "junlve",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage,sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		room:broadcastSkillInvoke(self:objectName())
		player:gainMark("@junlve",damage.damage)
		return false
	end
}
--〖催克〗 出牌階段開始時，如果你有奇數個“軍略”，你可以對 1 名角色造成 1 點傷害；如果你有偶數個“軍略”，你可以讓 1 名角色進入“連環”狀態，並且棄置他 1 張牌。如果你的軍略超過 7 個，你可以移去全部“軍略”，對所有其他角色造成 1 點傷害。									   　
cuike = sgs.CreateTriggerSkill{
	name = "cuike",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Play then
				if player:getMark("@junlve") % 2 == 0 then
					local _targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if not p:isChained() or not p:isNude() then
							_targets:append(p) 
						end
					end
					if not _targets:isEmpty() then
						local s = room:askForPlayerChosen(player, _targets, "cuike", "@cuike-chain", true)
						if s then
							room:doAnimate(1, player:objectName(), s:objectName())
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerProperty(s, "chained", sgs.QVariant(true))
							if not s:isNude() then
								room:throwCard(room:askForCardChosen(player, s, "he", "cuike", false, sgs.Card_MethodDiscard), s, player)
							end
						end
					end
				end
				if player:getMark("@junlve") % 2 == 1 then
					local s = room:askForPlayerChosen(player, room:getAlivePlayers(), "cuike", "@cuike-damage", true)
					if s then
						room:broadcastSkillInvoke(self:objectName())
						room:doAnimate(1, player:objectName(), s:objectName())
						room:damage(sgs.DamageStruct(nil,player,s,1,sgs.DamageStruct_Normal))

						local assignee_list = player:property("extra_slash_specific_assignee"):toString():split("+")
						table.insert(assignee_list, s:objectName())
						room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(assignee_list,"+")))
						room:setPlayerMark(s, "ol_huxiao-Clear",1)
					end
				end
				if player:getMark("@junlve") > 7 then
					if room:askForSkillInvoke(player, "cuike_kill", data) then
						room:doSuperLightbox("shenluxun_sec_rev","cuike")
						room:broadcastSkillInvoke(self:objectName())
						player:loseAllMarks("@junlve")
						for _, p in sgs.qlist(room:getAllPlayers()) do
							room:doAnimate(1, player:objectName(), p:objectName())
						end
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							room:damage(sgs.DamageStruct(nil,player,p,1,sgs.DamageStruct_Normal))
						end
					end
				end
			end
		end
	end,
	priority = 8,
}
--〖綻火〗 限定技，出牌階段，你可以移去全部“軍略”，然後讓等量處在“連環”狀態的角色棄置所有裝備，然後受到 1 點火焰傷害。
function skill(self, room, player, open, n)
	local log = sgs.LogMessage()
	log.type = "#InvokeSkill"
	log.from = player
	log.arg = self:objectName()
	room:sendLog(log)
	room:notifySkillInvoked(player, self:objectName())
	if open then
		if n then
			room:broadcastSkillInvoke(self:objectName(), n)
		else
			room:broadcastSkillInvoke(self:objectName())
		end
	end
end

zhanhuo_sec_revCard = sgs.CreateSkillCard{
	name = "zhanhuo_sec_rev",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("@junlve") and to_select:isChained()
	end,
	about_to_use = function(self, room, use)
		use.from:loseAllMarks("@junlve")
		room:doSuperLightbox("shenluxun_sec_rev","zhanhuo_sec_rev")
		skill(self, room, use.from, true)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			room:removePlayerMark(use.from, "@fire_boom_sec_rev")
			for _, p in sgs.qlist(use.to) do
				room:doAnimate(1, use.from:objectName(), p:objectName())
				p:throwAllEquips()
			end
			room:damage(sgs.DamageStruct(self:objectName(), use.from, use.to:first(), 1, sgs.DamageStruct_Fire))
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}

zhanhuo_sec_revVS = sgs.CreateZeroCardViewAsSkill{
	name = "zhanhuo_sec_rev" ,
	view_as = function(self, card)
		return zhanhuo_sec_revCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@fire_boom_sec_rev") > 0 and player:getMark("@junlve") > 0
	end
}
zhanhuo_sec_rev = sgs.CreateTriggerSkill{
		name = "zhanhuo_sec_rev",
		frequency = sgs.Skill_Limited,
		limit_mark = "@fire_boom_sec_rev",
		view_as_skill = zhanhuo_sec_revVS ,
		on_trigger = function() 
		end
}
shenluxun_sec_rev:addSkill(junlve)
shenluxun_sec_rev:addSkill(zhanhuo_sec_rev)
shenluxun_sec_rev:addSkill(cuike)

sgs.LoadTranslationTable{
["shenluxun_sec_rev"]="神陸遜",
["junlve"] = "軍略",
[":junlve"] = "鎖定技，當你造成或受到 1 點傷害後，你獲得 1 個“軍略”標記。",
["@junlve"] = "軍略",	
["cuike"] = "摧克",
[":cuike"] = "出牌階段開始時，如果你有奇數個“軍略”，你可以對 1 名角色造成 1 點傷害；如果你有偶數個“軍略”，你可以讓 1 名角色進入“連環”狀態，並且棄置他 1 張牌。如果你的軍略超過 7 個，你可以移去全部“軍略”，對所有其他角色造成 1 點傷害。",
["zhanhuo_sec_rev"] = "綻火",
[":zhanhuo_sec_rev"] = "限定技，出牌階段，你可以移去全部“軍略”，然後讓等量處在“連環”狀態的角色棄置所有裝備，然後你對其中一名角色造成 1 點火焰傷害。",
["~zhanhuo_sec_rev"] = "點擊目標角色 -> 點擊「確定」",
["@cuike-damage"] = "你可以對 1 名角色造成 1 點傷害",
["@cuike-chain"] = "你可以讓 1 名角色進入“連環”狀態，並且棄置他 1 張牌。",
["cuike_kill"] = "摧克，移去全部“軍略”，對所有其他角色造成 1 點傷害",
["@zhanhuo_sec_rev"] = "你可以發動技能「綻火」，移去全部“軍略”，然後讓等量處在“連環”狀態的角色棄置所有裝備，然後你對其中一名角色造成 1 點火焰傷害。",
["@zhanhuo_sec_rev-damage"] = "你要對哪一名角色造成1点火焰傷害？",
["$junlve1"] = "文韜武略兼備，方可破敵如破竹。",
["$junlve2"] = "軍略綿腹，制敵千里。",
["$cuike1"] = "摧敵心神，克敵計謀。",
["$cuike2"] = "克險摧難，軍略當先。",
["$zhanhuo1"] = "綻東吳業火，燒敵軍數千！",
["$zhanhuo2"] = "業火映東水，吳志綻敵營！",
}




--神劉備
shenliubei = sgs.General(extension,"shenliubei","god","6",true)
--龍怒：轉換技，鎖定技，出牌階段開始時，陽：你失去1點體力並摸一張牌，然後本回合你的紅色手牌均視為火【殺】且無距離限制；陰：你減1點體力上限並摸一張牌，然後本回合你的錦囊牌均視為雷【殺】且無次數限制。
longnu_red_clear = sgs.CreateFilterSkill{
	name = "#longnu_red_clear",
	view_filter = function(self, to_select)
		return to_select:isRed() and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		slash:setSkillName("longnu_red")
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(slash)
		return new
	end
}
longnu_trick_clear = sgs.CreateFilterSkill{
	name = "#longnu_trick_clear",
	view_filter = function(self, to_select)
		return to_select:isKindOf("TrickCard") and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
		slash:setSkillName("longnu_trick")
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(slash)
		return new
	end
}
if not sgs.Sanguosha:getSkill("#longnu_red_clear") then skills:append(longnu_red_clear) end
if not sgs.Sanguosha:getSkill("#longnu_trick_clear") then skills:append(longnu_trick_clear) end

longnu = sgs.CreateTriggerSkill{
	name = "longnu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.EventAcquireSkill,sgs.EventPhaseStart,sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if ((event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart) and player:getMark("@longnu_yin") == 0 and player:getMark("@longnu_yang") == 0 then
			room:setPlayerMark(player,"@longnu_yang",1)
			room:setPlayerMark(player,"@longnu_yin",0)
			sgs.Sanguosha:addTranslationEntry(":longnu", ""..string.gsub(sgs.Sanguosha:translate(":longnu"), sgs.Sanguosha:translate(":longnu"), sgs.Sanguosha:translate(":longnu1")))
			--ChangeCheck(player, "shenliubei")
		elseif (event == sgs.EventLoseSkill and data:toString() == self:objectName()) then
			room:setPlayerMark(player,"@longnu_yang",0)
			room:setPlayerMark(player,"@longnu_yin",0)
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("@longnu_yang") == 1 then
					room:setPlayerMark(player,"@longnu_yang",0)
					room:setPlayerMark(player,"@longnu_yin",1)
					room:loseHp(player)
					sgs.Sanguosha:addTranslationEntry(":longnu", ""..string.gsub(sgs.Sanguosha:translate(":longnu"), sgs.Sanguosha:translate(":longnu"), sgs.Sanguosha:translate(":longnu2")))
					--ChangeCheck(player, "shenliubei")
					room:acquireSkill(player, "#longnu_red_clear", false)
					room:filterCards(player, player:getCards("h"), true)
					player:drawCards(1)	
				elseif player:getMark("@longnu_yin") == 1 then
					room:setPlayerMark(player,"@longnu_yang",1)
					room:setPlayerMark(player,"@longnu_yin",0)
					room:loseMaxHp(player)
					sgs.Sanguosha:addTranslationEntry(":longnu", ""..string.gsub(sgs.Sanguosha:translate(":longnu"), sgs.Sanguosha:translate(":longnu"), sgs.Sanguosha:translate(":longnu1")))
					--ChangeCheck(player, "shenliubei")
					room:acquireSkill(player, "#longnu_trick_clear", false)
					room:filterCards(player, player:getCards("h"), true)
					player:drawCards(1)	
				end
			end
		end
	end
}
longnutm = sgs.CreateTargetModSkill{
	name = "#longnutm",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("#longnu_trick_clear") then 
			return 1000
		end
	end,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("#longnu_red_clear") then 
			return 1000
		end
	end
}

--結營：鎖定技，你始終處於橫置狀態；已橫置的角色手牌上限+2；結束階段，你橫置一名其他角色。
jieying = sgs.CreateTriggerSkill{
	name = "jieying",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.CardFinished,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("jieying") then
					room:setPlayerProperty(p, "chained", sgs.QVariant(true))
				end
			end
		elseif event == sgs.CardFinished then -- or event == sgs.DamageComplete then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("jieying") and (not p:isChained()) then
					room:setPlayerProperty(p, "chained", sgs.QVariant(true))
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				if player:hasSkill("jieying") then
					local p = room:askForPlayerChosen(player, room:getOtherPlayers(player), "jieying", "@jieying_chain", true)
					if p then
						room:doAnimate(1, player:objectName(), p:objectName())
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
jieyingmc = sgs.CreateMaxCardsSkill{
	name = "#jieyingmc", 
	extra_func = function(self, target)
		local extra = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if target:isChained() and p:hasSkill("jieying") then
				extra = extra + 2
			end
		end
		if target:isChained() and target:hasSkill("jieying") then
			extra = extra + 2
		end
		return extra
	end
}

shenliubei:addSkill(longnu)
shenliubei:addSkill(longnutm)
shenliubei:addSkill(jieying)
shenliubei:addSkill(jieyingmc)

extension:insertRelatedSkills("jieying","#jieyingmc")
extension:insertRelatedSkills("longnu","#longnutm")  

sgs.LoadTranslationTable{
	["shenliubei"] = "神劉備",
	["#shenliubei"] = "至仁至信",
	["longnu"] = "龍怒",
	[":longnu"] = "轉換技，鎖定技，出牌階段開始時，陽：你失去1點體力並摸一張牌，然後本回合你的紅色手牌均視為火【殺】且無距離限制；陰：你減1點體力上限並摸一張牌，然後本回合你的錦囊牌均視為雷【殺】且無次數限制。",
	[":longnu2"] = "轉換技，鎖定技，出牌階段開始時，<font color=\"#01A5AF\"><s>陽：你失去1點體力並摸一張牌，然後本回合你的紅色手牌均視為火【殺】且無距離限制</s></font>；陰：你減1點體力上限並摸一張牌，然後本回合你的錦囊牌均視為雷【殺】且無次數限制。",
	[":longnu1"] = "轉換技，鎖定技，出牌階段開始時，陽：你失去1點體力並摸一張牌，然後本回合你的紅色手牌均視為火【殺】且無距離限制；<font color=\"#01A5AF\"><s>陰：你減1點體力上限並摸一張牌，然後本回合你的錦囊牌均視為雷【殺】且無次數限制。</s></font>",
	["jieying"] = "結營",
	[":jieying"] = "鎖定技，你始終處於橫置狀態；已橫置的角色手牌上限+2；結束階段，你橫置一名其他角色。",
	["@jieying_chain"] = "橫置一名其他角色",
	["$longnu1"] = "龙怒降临，岂是尔等凡人可抗？",
	["$longnu2"] = "龙意怒火，汝皆不能逃脱！",
	["$jieying1"] = "桃园结义，营一时之交。",
	["$jieying2"] = "结草衔环，报兄弟大恩。",
	["~shenliubei"] = "桃园依旧，来世再结。",
		["longnu_red"] = "龍怒",
			["longnu_trick"] = "龍怒",
}							 

--神張遼
shenzhangliao = sgs.General(extension,"shenzhangliao","god","4",true)
--【奪銳】當你於出牌階段內對一名其他角色造成傷害後，你可以廢除你的一個裝備欄，然後選擇該角色的武將牌上的一個技能（限定技、覺醒技、主公技除外），令其於其下回合結束之前此技能無效，然後你於其下回合結束或其死亡之前擁有此技能且不能發動【奪銳】。
bukuishishen = sgs.CreateTriggerSkill{
	name = "bukuishishen",
	events = {sgs.EventPhaseStart, sgs.Damage},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local choices = {}
		local choicess = {}
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and (player:hasSkill("cuike") or player:hasSkill("zhanhuo")) then
			local ji = math.mod(player:getMark("@junlve"), 2) == 1
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if ji or not player:isChained() or player:canDiscard(p, "hej") then
					targets:append(p)
				end
			end
			local targets_c = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isChained() then
					targets_c:append(p)
				end
			end
			if not targets:isEmpty() and player:hasSkill("cuike") then
				table.insert(choices, "cuike")
			end
			if not targets_c:isEmpty() and player:hasSkill("zhanhuo") and player:getMark("@junlve") > 0 and player:getMark("@fire_boom") > 0 then
				table.insert(choices, "zhanhuo")
			end
			if #choices > 0 then
				local targets_e = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if ji or not player:isChained() or player:canDiscard(p, "hej") then
						targets_e:append(p)
					end
				end
				local targets_ch = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isChained() then
						targets_ch:append(p)
					end
				end
				local choice = room:askForChoice(player, "SKILL", table.concat(choices, "+"))
				room:addPlayerMark(player, choice)
				room:removePlayerMark(player, choice)
				if not targets_e:isEmpty() and player:hasSkill("cuike") then
					if not table.contains(choices, "cuike") then
						table.insert(choices, "cuike")
					end
				else
					if table.contains(choices, "cuike") then
						table.removeOne(choices, "cuike")
					end
				end
				if not targets_ch:isEmpty() and player:hasSkill("zhanhuo") and player:getMark("@junlve") > 0 and player:getMark("@fire_boom") > 0 then
					if not table.contains(choices, "zhanhuo") then
						table.insert(choices, "zhanhuo")
					end
				else
					if table.contains(choices, "zhanhuo") then
						table.removeOne(choices, "zhanhuo")
					end
				end
				table.removeOne(choices, choice)
				if #choices > 0 then
					local twice = room:askForChoice(player, "SKILL", table.concat(choices, "+"))
					room:addPlayerMark(player, twice)
					room:removePlayerMark(player, twice)
				end
			end
		elseif event == sgs.Damage and (player:hasSkill("duorui") or player:hasSkill("zhiti")) then
			local damage = data:toDamage()
			local duoruis = {}
			for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
				if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and string.find(skill:getDescription(), sgs.Sanguosha:translate("duorui1")) or string.find(skill:getDescription(), sgs.Sanguosha:translate("duorui2")) then
					table.insert(duoruis, skill:objectName())
				end
			end
			if player:hasSkill("duorui") and damage.to and damage.to:objectName() ~= player:objectName() and player:getPhase() == sgs.Player_Play and player:getMark("duorui_lun") == 0 and player:hasEquipArea() and #duoruis > 0 then
				table.insert(choices, "duorui")
			end
			local invoke = false
			for i = 0, 4 do
				if not invoke then
					invoke = not player:hasEquipArea(i)
				end
			end
			if player:hasSkill("zhiti") and damage.card and damage.card:isKindOf("Duel") and invoke and damage.to and damage.to:isWounded() and player:inMyAttackRange(damage.to) then
				table.insert(choices, "zhiti")
			end
			if #choices > 0 then
				local choice = room:askForChoice(player, "SKILL", table.concat(choices, "+"))
				player:setTag(choice, data)
				room:addPlayerMark(player, choice)
				room:removePlayerMark(player, choice)
				local duoruiss = {}
				for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and string.find(skill:getDescription(), sgs.Sanguosha:translate("duorui1")) or string.find(skill:getDescription(), sgs.Sanguosha:translate("duorui2")) then
						table.insert(duoruiss, skill:objectName())
					end
				end
				if player:hasSkill("duorui") and damage.to and damage.to:objectName() ~= player:objectName() and player:getPhase() == sgs.Player_Play and player:getMark("duorui_lun") == 0 and player:hasEquipArea() and #duoruiss > 0 then
					table.insert(choicess, "duorui")
				end
				local invoke = false
				for i = 0, 4 do
					if not invoke then
						invoke = not player:hasEquipArea(i)
					end
				end
				if player:hasSkill("zhiti") and damage.card and damage.card:isKindOf("Duel") and invoke and damage.to and damage.to:isWounded() and player:inMyAttackRange(damage.to) then
					table.insert(choicess, "zhiti")
				end
				table.removeOne(choicess, choice)
				if #choicess > 0 then
					local choicee = room:askForChoice(player, "SKILL", table.concat(choicess, "+"))
					player:setTag(choicee, data)
					room:addPlayerMark(player, choicee)
					room:removePlayerMark(player, choicee)
				end
			end
		end
	end
}

shenzhangliao_clear_mark = sgs.CreateTriggerSkill{
	name = "shenzhangliao_clear_mark",
	events = {sgs.Death, sgs.EventPhaseChanging},
	global = true,
	priority = -100,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, skill in sgs.qlist(player:getVisibleSkillList()) do
					if player:getMark("Duorui_to"..skill:objectName()) > 0 then


							local log = sgs.LogMessage()
							log.type = "#Duoruirec"
							log.from = player
							log.arg = skill:objectName()
							log.to:append(player)
							room:sendLog(log)

						room:removePlayerMark(player, "Qingcheng"..skill:objectName())
						--room:removePlayerMark(player, "Duorui"..skill:objectName())
						room:removePlayerMark(player, "Duorui_to"..skill:objectName())
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							local duoruis_skill_names = {}
							if p:getMark("Duorui"..skill:objectName().."from") > 0 and p:hasSkill(skill:objectName()) then
								table.insert(duoruis_skill_names, "-"..skill:objectName())
								room:setPlayerMark(p, "Duorui"..skill:objectName().."from", 0)
							end
							if #duoruis_skill_names > 0 then
								room:handleAcquireDetachSkills(p, table.concat(duoruis_skill_names, "|"))
							end
						end
					end

					if player:getMark("Shefu_po"..skill:objectName()) > 0 then


						local log = sgs.LogMessage()
						log.type = "#Duoruirec"
						log.from = player
						log.arg = skill:objectName()
						log.to:append(player)
						room:sendLog(log)

						room:removePlayerMark(player, "Qingcheng"..skill:objectName())
						room:removePlayerMark(player, "Shefu_po"..skill:objectName())

					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			for _, skill in sgs.qlist(death.who:getVisibleSkillList()) do
					if death.who:getMark("Duorui_to"..skill:objectName()) > 0 then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							local duoruis_skill_names = {}
							if p:getMark("Duorui"..skill:objectName().."from") > 0 and p:hasSkill(skill:objectName()) then
								table.insert(duoruis_skill_names, "-"..skill:objectName())
								room:setPlayerMark(p, "Duorui"..skill:objectName().."from", 0)
							end
							if #duoruis_skill_names > 0 then
								room:handleAcquireDetachSkills(p, table.concat(duoruis_skill_names, "|"))
							end
						end
					end
				end
		end
	end,
}
if not sgs.Sanguosha:getSkill("bukuishishen") then skills:append(bukuishishen) end
if not sgs.Sanguosha:getSkill("shenzhangliao_clear_mark") then skills:append(shenzhangliao_clear_mark) end

duorui = sgs.CreateTriggerSkill{
	name = "duorui",  
	events = {sgs.Damage}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.to:isAlive() and player:getPhase() == sgs.Player_Play then
				if damage.to:objectName() ~= player:objectName() then
					local _data = sgs.QVariant()
					_data:setValue(damage.to)
					if room:askForSkillInvoke(player, self:objectName(), _data) then						
						player:setTag("duorui", data)
						local choice = ChooseThrowEquipArea(self, player,true,false)

						if choice ~= "cancel" then
							throwEquipArea(self,player, choice)
							local sks = {}

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

							local skill_choice = room:askForChoice(player,self:objectName(),table.concat(sks, "+"))

							local log = sgs.LogMessage()
							log.type = "#Duoruilog"
							log.from = player
							log.to:append(damage.to)
							log.arg = skill_choice
							room:sendLog(log)

							room:addPlayerMark(damage.to, "Duorui_to"..skill_choice)
							room:addPlayerMark(damage.to, "Qingcheng"..skill_choice)
							room:addPlayerMark(damage.from, "Duorui"..skill_choice.."from")
							room:handleAcquireDetachSkills(player, skill_choice)
						end
					end	
				end
			end
		end
	end,
}
--【止啼】鎖定技，你攻擊範圍內已受傷的角色手牌上限-1；當你和這些角色拼點或【決鬥】你贏時，你恢復一個裝備欄。當你受到傷害後，若來源在你的攻擊範圍內且已受傷，你恢復一個裝備欄。
zhiti = sgs.CreateTriggerSkill{
	name = "zhiti",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Pindian,sgs.Predamage,sgs.Damaged},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local can_recover = 0
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if (pindian.from_number > pindian.to_number and pindian.from:objectName() == player:objectName()
			 and player:inMyAttackRange(pindian.to))
			  or
			   (pindian.from_number < pindian.to_number and pindian.to:objectName() == player:objectName() and 
				  player:inMyAttackRange(pindian.from)) then
				can_recover = 1
			end
		elseif event == sgs.Predamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Duel") and player:inMyAttackRange(damage.to) then
				can_recover = 1
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:isWounded() and player:inMyAttackRange(damage.from)  then
				can_recover = 1
			end
		end
		if can_recover == 1 then
			ObtainEquipArea(self, player)
		end
	end,
}

zhitiMC = sgs.CreateMaxCardsSkill{
	name = "#zhitiMC",
	extra_func = function(self, target)
		local n = 0
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if p:hasSkill("zhiti") and p:inMyAttackRange(target) and target:isWounded() and target:objectName() ~= p:objectName() then
				n = n - 1
			end
		end
		
		return n
	end
}


shenzhangliao:addSkill(duorui)
shenzhangliao:addSkill(zhiti)
shenzhangliao:addSkill(zhitiMC)

extension:insertRelatedSkills("zhiti","#zhitiMC")

sgs.LoadTranslationTable{
	["shenzhangliao"] = "神張遼",
	["duorui"] = "奪銳",
	[":duorui"] = "當你於出牌階段內對一名其他角色造成傷害後，你可以廢除你的一個裝備欄，然後選擇該角色的武將牌上的一個技能（限定技、覺醒技、主公技除外），令其於其下回合結束之前此技能無效，然後你於其下回合結束或其死亡之前擁有此技能且不能發動【奪銳】。",
	["zhiti"] = "止啼",
	[":zhiti"] = "鎖定技，你攻擊範圍內已受傷的角色手牌上限-1；當你和這些角色拼點或【決鬥】你贏時，你恢復一個裝備欄。當你受到傷害後，若來源在你的攻擊範圍內且已受傷，你恢復一個裝備欄。",
	["$duorui1"] = "奪敵軍銳氣，殺敵方士氣。",
	["$duorui2"] = "尖銳之勢，吾亦可一人奪之。",
	["$zhiti1"] = "江東小兒安敢啼哭？",
	["$zhiti2"] = "娃聞名止啼，孫損十萬休！",
	["~shenzhangliao"] = "我也有被孫仲謀所傷之時？",
	["#Duoruilog"] = "%from 對 %to 發動「奪銳」， %arg 於其下回合結束之前無效",
	["#Duoruirec"] = "%from 的 %arg 恢復效果",
}

sgs.Sanguosha:addSkills(skills)

