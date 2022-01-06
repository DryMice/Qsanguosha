module("extensions.hulaoguancard", package.seeall)
extension = sgs.Package("hulaoguancard",sgs.Package_CardPack)

sgs.LoadTranslationTable{
	["hulaoguancard"] = "虎牢關",
}

local skills = sgs.SkillList()

function lua_armor_null_check(player)
	if #player:getTag("Qinggang"):toStringList() > 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then
		return true
	end
	return false
end

MusoHalberdSkill = sgs.CreateTriggerSkill{
	name = "MusoHalberdSkill",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0
		and damage.card and damage.card:isKindOf("Slash")
		then
			local choices = {}
			table.insert(choices, "muso_halberd_draw")
			if damage.to:isAlive() and not damage.to:isNude() then
				table.insert(choices, "muso_halberd_discard")
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			if choice == "muso_halberd_draw" then
				local msg = sgs.LogMessage()
				msg.type = "#MusoHalberdSkill_log"
				msg.from = player
				room:sendLog(msg)
				ChoiceLog(player, choice)
				player:drawCards(1, self:objectName())
			elseif choice == "muso_halberd_discard" then
				local msg = sgs.LogMessage()
				msg.type = "#MusoHalberdSkill_log"
				msg.from = player
				room:sendLog(msg)
				ChoiceLog(player, choice)
				local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
				if id ~= -1 then
					room:throwCard(sgs.Sanguosha:getCard(id), damage.to, player)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("MusoHalberd")
	end
}
if not sgs.Sanguosha:getSkill("MusoHalberdSkill") then skills:append(MusoHalberdSkill) end

MusoHalberd = sgs.CreateWeapon{
	name = "muso_halberd",
	class_name = "MusoHalberd",
	suit = sgs.Card_Diamond,
	number = 12,
	range = 4,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("MusoHalberdSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "MusoHalberdSkill")
	end
}
MusoHalberd:setParent(hulaoguan_card)

LongPheasantTailFeatherPurpleGoldCrownSkill = sgs.CreateTriggerSkill{
	name = "LongPheasantTailFeatherPurpleGoldCrownSkill",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to and change.to == sgs.Player_Start then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "LongPheasantTailFeatherPurpleGoldCrown-invoke", true, true)
			if target then
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("LongPheasantTailFeatherPurpleGoldCrown")
	end
}
if not sgs.Sanguosha:getSkill("LongPheasantTailFeatherPurpleGoldCrownSkill") then skills:append(LongPheasantTailFeatherPurpleGoldCrownSkill) end

LongPheasantTailFeatherPurpleGoldCrown = sgs.CreateTreasure{
	name = "long_pheasant_tail_feather_purple_gold_crown",
	class_name = "LongPheasantTailFeatherPurpleGoldCrown",
	suit = sgs.Card_Diamond,
	number = 1,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("LongPheasantTailFeatherPurpleGoldCrownSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "LongPheasantTailFeatherPurpleGoldCrownSkill")
	end
}
LongPheasantTailFeatherPurpleGoldCrown:setParent(hulaoguan_card)

function lua_armor_null_check(player)
	if #player:getTag("Qinggang"):toStringList() > 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then
		return true
	end
	return false
end

RedCottonHundredFlowerRobeSkill = sgs.CreateTriggerSkill{
	name = "RedCottonHundredFlowerRobeSkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if not lua_armor_null_check(player) and damage.nature ~= sgs.DamageStruct_Normal then
			local msg = sgs.LogMessage()
			msg.type = "#RedCottonHundredFlowerRobeProtect"
			msg.from = player
			msg.arg = damage.damage
			if damage.nature == sgs.DamageStruct_Fire then
				msg.arg2 = "fire_nature"
			elseif damage.nature == sgs.DamageStruct_Thunder then
				msg.arg2 = "thunder_nature"
			end
			room:sendLog(msg)
			return true
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getArmor() and target:getArmor():isKindOf("RedCottonHundredFlowerRobe")
	end
}
if not sgs.Sanguosha:getSkill("RedCottonHundredFlowerRobeSkill") then skills:append(RedCottonHundredFlowerRobeSkill) end

RedCottonHundredFlowerRobe = sgs.CreateArmor{
	name = "red_cotton_hundred_flower_robe",
	class_name = "RedCottonHundredFlowerRobe",
	suit = sgs.Card_Club,
	number = 1,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("RedCottonHundredFlowerRobeSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "RedCottonHundredFlowerRobeSkill")
	end
}
RedCottonHundredFlowerRobe:setParent(hulaoguan_card)

LinglongLionRoughBandSkill = sgs.CreateTriggerSkill{
	name = "LinglongLionRoughBandSkill",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not lua_armor_null_check(player) and use.from and use.from:objectName() ~= player:objectName() and use.to:length() == 1
		and use.to:contains(player) and use.card and not use.card:isKindOf("SkillCard") and room:askForSkillInvoke(player, self:objectName(), data)
		then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.who = player
			judge.reason = self:objectName()
			judge.good = true
			room:judge(judge)
			if judge:isGood() then
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
				local msg = sgs.LogMessage()
				msg.type = "#LinglongLionRoughBandProtect"
				msg.from = player
				room:sendLog(msg)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getArmor() and target:getArmor():isKindOf("LinglongLionRoughBand")
	end
}
if not sgs.Sanguosha:getSkill("LinglongLionRoughBandSkill") then skills:append(LinglongLionRoughBandSkill) end

LinglongLionRoughBand = sgs.CreateArmor{
	name = "linglong_lion_rough_band",
	class_name = "LinglongLionRoughBand",
	suit = sgs.Card_Club,
	number = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("LinglongLionRoughBandSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "LinglongLionRoughBandSkill")
	end
}
LinglongLionRoughBand:setParent(hulaoguan_card)

local LinglongLionRoughBand2 = LinglongLionRoughBand:clone()
LinglongLionRoughBand2:setSuit(sgs.Card_Spade)
LinglongLionRoughBand2:setNumber(2)
LinglongLionRoughBand2:setParent(hulaoguan_card)


sgs.LoadTranslationTable{
	["muso_halberd"] = "無雙方天戟",
	[":muso_halberd"] = "裝備牌·武器<br /><b>攻擊範圍</b>：4<br /><b>武器技能</b>：你使用【殺】對目標角色造成傷害後，你可以摸一張牌或棄置目標角色一張牌。",
	["MusoHalberdSkill"] = "無雙方天戟",
	["#MusoHalberdSkill_log"] = "%from 的“<font color=\"yellow\"><b>無雙方天戟</b></font>”效果被觸發",
	["muso_halberd_draw"] = "摸一張牌",
	["muso_halberd_discard"] = "棄置目標角色一張牌",

	["long_pheasant_tail_feather_purple_gold_crown"] = "束髮紫金冠",
	[":long_pheasant_tail_feather_purple_gold_crown"] = "裝備牌·寶物<br /><b>寶物技能</b>：準備階段，你可以對一名其他角色造成1點傷害。",
	["LongPheasantTailFeatherPurpleGoldCrown-invoke"] = "你可以對一名其他角色造成1點傷害<br/> <b>操作提示</b>: 選擇一名與你不同的角色→點擊確定<br/>" ,
	["LongPheasantTailFeatherPurpleGoldCrownSkill"] = "束髮紫金冠",

	["red_cotton_hundred_flower_robe"] = "紅棉百花袍",
	[":red_cotton_hundred_flower_robe"] = "裝備牌·防具<br /><b>防具技能</b>：鎖定技，防止你受到的屬性傷害。",
	["#RedCottonHundredFlowerRobeProtect"] = "%from 的“<font color=\"yellow\"><b>紅棉百花袍</b></font>”效果被觸發，防止了%arg 點傷害[% arg2]",

	["linglong_lion_rough_band"] = "玲瓏獅蠻帶",
	[":linglong_lion_rough_band"] = "裝備牌·防具<br /><b>防具技能</b>：當其他角色使用牌指定你為唯一目標後，你可以進行一次判定，若判定結果為紅桃，則此牌對你無效。",
	["LinglongLionRoughBandSkill"] = "玲瓏獅蠻帶",
	["#LinglongLionRoughBandProtect"] = "%from 的“<font color=\"yellow\"><b>玲瓏獅蠻帶</b></font>”效果被觸發",
}

sgs.Sanguosha:addSkills(skills)