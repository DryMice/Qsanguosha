module("extensions.jitiansidi", package.seeall)
extension = sgs.Package("jitiansidi",sgs.Package_CardPack)

sgs.LoadTranslationTable{
	["jitiansidi"] = "祭天祀地",
}

local skills = sgs.SkillList()

--[[
祭天祀地：

在主公的第一個回合結束時，主公須在系統給出的兩個選項中選擇其一：

選項一：失去主公技，獲得一個「祭器」技能

選項二：失去1點體力，獲得一個「九鼎」技能（沒有主公技的非主流主當然只能選這個）
]]--

jitiansidi = sgs.CreateTriggerSkill{
	name = "jitiansidi",
	global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:getMark("turn") == 1 then
			local choices = {"jitiansidi2"}
			for _,sk in sgs.qlist(player:getVisibleSkillList()) do
				if sk:isLordSkill() then
					table.insert(choices, "jitiansidi1")
					break
				end
			end

			local choice = room:askForChoice(player, "jitiansidi", table.concat(choices, "+"))

			if choice == "jitiansidi1" then
				for _,sk in sgs.qlist(player:getVisibleSkillList()) do
					if sk:isLordSkill() then
						room:detachSkillFromPlayer(player, sk:objectName())
					end
				end

				choice_skills = {"cangji","chiji","qingji"}
				table.removeOne(choice_skills,math.random(1,#choice_skills))
				local choice_skill = room:askForChoice(player, "jitiansidi", table.concat(choice_skills, "+"))
				room:acquireSkill(player,choice_skill)

			elseif choice == "jitiansidi2" then
				room:loseHp(player)

				choice_skills = {"yangji","yongji","yuji"}
				table.removeOne(choice_skills,math.random(1,#choice_skills))
				local choice_skill = room:askForChoice(player, "jitiansidi", table.concat(choice_skills, "+"))
				room:acquireSkill(player,choice_skill)
			end
			getcolorcard(player,"red",true,false)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isLord() and (not (Set(sgs.Sanguosha:getBanPackages()))["jitiansidi"])
	end 
}

sgs.LoadTranslationTable{
	["jitiansidi1"] = "失去主公技，獲得一個「祭器」技能",
	["jitiansidi2"] = "失去1點體力，獲得一個「九鼎」技能",
}

--[[
當主公做出任一選擇後，系統會隨機從所有的「祭器/九鼎」技能中出現2個供玩家選擇獲得，並從牌堆隨機獲得一張紅色牌。

「祭器」技能
]]--


--[[
蒼祭：限定技，出牌階段，從牌堆將隨機一張武器牌、一張防具牌、一張+1馬、一張-1馬置入你的裝備區（注：不能頂替原有裝備）。
]]--
cangjiCard = sgs.CreateSkillCard{
	name = "cangji",
	target_fixed = false,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@cangji")
		local equip_type_table = {"Weapon", "Armor", "DefensiveHorse", "OffensiveHorse"}
			for _, card in sgs.qlist(source:getCards("e")) do
				if card:isKindOf("Weapon") then
					table.removeOne(equip_type_table, "Weapon")
				elseif card:isKindOf("Armor") then
					table.removeOne(equip_type_table, "Armor")
				elseif card:isKindOf("DefensiveHorse") then
					table.removeOne(equip_type_table, "DefensiveHorse")
				elseif card:isKindOf("OffensiveHorse") then
					table.removeOne(equip_type_table, "OffensiveHorse")
				end
			end

			if source:getMark("@AbolishWeapon") > 0 then
				table.removeOne(equip_type_table, "Weapon")
			end
			if source:getMark("@AbolishArmor") > 0 then
				table.removeOne(equip_type_table, "Armor")
			end
			if source:getMark("@AbolishDefensiveHorse") > 0 then
				table.removeOne(equip_type_table, "DefensiveHorse")
			end
			if source:getMark("@AbolishOffensiveHorse") > 0 then
				table.removeOne(equip_type_table, "OffensiveHorse")
			end

		while #equip_type_table > 0 do
			local equip_type_index = math.random(1, #equip_type_table)
			local equips = sgs.CardList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf(equip_type_table[equip_type_index]) then
					local equip_index = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()
				 	if source:getEquip(equip_index) == nil  then
						equips:append(sgs.Sanguosha:getCard(id))
					end
				end
			end
			if not equips:isEmpty() then
				local card = equips:at(math.random(0, equips:length() - 1))
				--room:useCard(sgs.CardUseStruct(card, source, source))
				room:moveCardTo(card, nil, source, sgs.Player_PlaceEquip)
				usable_count = usable_count - 1
			end
			table.removeOne(equip_type_table, equip_type_table[equip_type_index])
		end
	end
}
cangjiVS = sgs.CreateZeroCardViewAsSkill{
	name = "cangji",
	view_as = function()
		return cangjiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@cangji") > 0
	end
}
cangji = sgs.CreateTriggerSkill{
	name = "cangji",
	frequency = sgs.Skill_Limited,
	view_as_skill = cangjiVS,
	limit_mark = "@cangji",
	on_trigger = function()
	end
}

sgs.LoadTranslationTable{
	["cangji"] = "蒼祭",
	[":cangji"] = "限定技，出牌階段，從牌堆將隨機一張武器牌、一張防具牌、一張+1馬、一張-1馬置入你的裝備區（注：不能頂替原有裝備）。",
}

--[[
赤祭：限定技，當你處於瀕死狀態時，你可以將體力回復至2點。 
]]--

chiji = sgs.CreateTriggerSkill{
	name = "chiji",
	frequency = sgs.Skill_Limited,
	limit_mark = "@chiji",
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			if player:getMark("@chiji") > 0 then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					--room:doSuperLightbox("baosanniang","chiji")
					room:broadcastSkillInvoke(self:objectName())
					room:removePlayerMark(player, "@chiji")
					room:recover(player, sgs.RecoverStruct(player,player, 2 - player:getHp()))					
				end
			end
		end
		return false
	end
}

sgs.LoadTranslationTable{
	["chiji"] = "赤祭",
	[":chiji"] = "限定技，當你處於瀕死狀態時，你可以將體力回復至2點。 ",
}

--[[
青祭：限定技，出牌階段開始時，你造成1點傷害，摸一張牌，從牌堆隨機置入一張武器牌到你的裝備區（注：不能頂替原有裝備）。
]]--

qingji = sgs.CreateTriggerSkill{
	name = "qingji",
	frequency = sgs.Skill_Limited,
	limit_mark = "@qingji",
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play and player:getMark("@qingji") > 0 then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "qingji-invoke", true, true)
			if target then
				room:removePlayerMark(player, "@qingji")
				room:doAnimate(1, player:objectName(), target:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))

				player:drawCards(1)

				local equips = sgs.CardList()
				for _, id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("Weapon") and not player:getWeapon() then
						equips:append(sgs.Sanguosha:getCard(id))
					end
				end
				if not equips:isEmpty() then
					local card = equips:at(math.random(0, equips:length() - 1))
					room:moveCardTo(card, nil, source, sgs.Player_PlaceEquip)
				end
			end
		end
	end
}


sgs.LoadTranslationTable{
	["qingji"] = "青祭",
	[":qingji"] = "限定技，出牌階段開始時，你造成1點傷害，摸一張牌，從牌堆隨機置入一張武器牌到你的裝備區（注：不能頂替原有裝備）。",
}

--[[
「九鼎」技能
]]--


--[[
揚祭：限定技，出牌階段，你對攻擊範圍內的至多X名其他角色各造成1點傷害（X為剩餘反賊數）。
]]--

yangjiCard = sgs.CreateSkillCard {
	name = "yangji",
	target_fixed = false,
	filter = function(self, targets, to_select, player, data)		
		return #targets < player:getMark("dingpan") and player:inMyAttackRange(to_select) and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
			--room:doSuperLightbox("no_bug_caifuren","yangji")
			room:removePlayerMark(source, "@yangji")
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.reason = "yangji"
			for _, p in ipairs(targets) do
				damage.to = p
				room:damage(damage)
			end

	end,
}
yangjiVS = sgs.CreateZeroCardViewAsSkill{
	name = "yangji",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self)
		local card = yangjiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@yangji") > 0
	end,
}

yangji = sgs.CreateTriggerSkill{
	name = "yangji",
	frequency = sgs.Skill_Limited,
	limit_mark = "@yangji",
	view_as_skill = yangjiVS,
	on_trigger = function()
	end
}

sgs.LoadTranslationTable{
	["yangji"] = "揚祭",
	[":yangji"] = "限定技，出牌階段，你對攻擊範圍內的至多X名其他角色各造成1點傷害（X為剩餘反賊數）。",
}

--[[
雍祭：限定技，出牌階段開始時，你摸X張牌，然後此回合你不能使用【殺】（X為剩餘反賊數）。
]]--

yongji = sgs.CreateTriggerSkill{
	name = "yongji",
	frequency = sgs.Skill_Limited,
	limit_mark = "@yongji", 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Play and player:getMark("@yongji") > 0 then

					if room:askForSkillInvoke(player, "yongji", data) then
						room:removePlayerMark(player, "@yongji")
						room:notifySkillInvoked(player,self:objectName())
						--room:doSuperLightbox("guanping_po","yongji")
						player:drawCards( player:getMark("dingpan") )
					end
			end
		end
	end,
}

sgs.LoadTranslationTable{
	["yongji"] = "雍祭",
	[":yongji"] = "限定技，出牌階段開始時，你摸X張牌，然後此回合你不能使用【殺】（X為剩餘反賊數）。",
}

--[[
豫祭：限定技，出牌階段，選擇至多X名角色，將其中未橫置的角色橫置，然後這X名角色各摸1張牌（X為剩餘反賊數）。
]]--

yujiCard = sgs.CreateSkillCard {
	name = "yuji",
	target_fixed = false,
	filter = function(self, targets, to_select, player, data)		
		return #targets < player:getMark("dingpan") and player:inMyAttackRange(to_select) and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		--room:doSuperLightbox("no_bug_caifuren","yuji")
		room:removePlayerMark(source, "@yuji")
		for _, p in ipairs(targets) do
			if not p:isChained() then
				room:setPlayerChained(p)
			end
		end
		for _, p in ipairs(targets) do
			p:drawCards(1)
		end
	end,
}
yujiVS = sgs.CreateZeroCardViewAsSkill{
	name = "yuji",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self)
		local card = yujiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@yuji") > 0
	end,
}

yuji = sgs.CreateTriggerSkill{
	name = "yuji",
	frequency = sgs.Skill_Limited,
	limit_mark = "@yuji",
	view_as_skill = yujiVS,
	on_trigger = function()
	end
}

sgs.LoadTranslationTable{
	["yuji"] = "豫祭",
	[":yuji"] = "限定技，出牌階段，選擇至多X名角色，將其中未橫置的角色橫置，然後這X名角色各摸1張牌（X為剩餘反賊數）。",
}

--[[
cangji
chiji
qingji
yangji
yongji
yuji
]]--

if not sgs.Sanguosha:getSkill("jitiansidi") then skills:append(jitiansidi) end
if not sgs.Sanguosha:getSkill("cangji") then skills:append(cangji) end
if not sgs.Sanguosha:getSkill("chiji") then skills:append(chiji) end
if not sgs.Sanguosha:getSkill("qingji") then skills:append(qingji) end
if not sgs.Sanguosha:getSkill("yangji") then skills:append(yangji) end
if not sgs.Sanguosha:getSkill("yongji") then skills:append(yongji) end
if not sgs.Sanguosha:getSkill("yuji") then skills:append(yuji) end


sgs.Sanguosha:addSkills(skills)


