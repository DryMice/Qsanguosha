module("extensions.spequip", package.seeall)
extension = sgs.Package("spequip",sgs.Package_CardPack)
extension_god = sgs.Package("godequip",sgs.Package_CardPack)

sgs.LoadTranslationTable{
	["spequip"] = "特殊裝備",
	["godequip"] = "神之試煉裝備",
}

local skills = sgs.SkillList()

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

--開局隱藏卡牌
card_remover = sgs.CreateTriggerSkill{  --开局隐藏卡牌（包含销毁【霹雳车】）
	name = "card_remover",
	global = true,
	priority = 10,
	--events = {sgs.GameStart, sgs.BeforeCardsMove},
	events = {sgs.GameStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.GameStart then

			--移除牌堆
			local cardIds = sgs.IntList()

			for _, id in sgs.qlist(room:getDrawPile()) do

				if sgs.Sanguosha:getCard(id):isKindOf("ThunderclapCatapult") then
					room:setTag("TC_ID", sgs.QVariant(id))
					cardIds:append(id)
				end

				if sgs.Sanguosha:getCard(id):isKindOf("MobileThunderclapCatapult") then
					room:setTag("MTC_ID", sgs.QVariant(id))
					cardIds:append(id)
				end

				if sgs.Sanguosha:getCard(id):isKindOf("SevenGemsBlade") then
					room:setTag("SGB_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				--移除王允的錦囊
				if sgs.Sanguosha:getCard(id):isKindOf("meirenji") then
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("xiaolicangdao") then
					cardIds:append(id)
				end

				--移除毒
				if sgs.Sanguosha:getCard(id):isKindOf("poison") then
					cardIds:append(id)
				end

				--移除蒲元的裝備
				if sgs.Sanguosha:getCard(id):isKindOf("RedSword") then
					room:setTag("RS_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("LiecuiBlade") then
					room:setTag("LB_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("WaterSword") then
					room:setTag("WS_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("PoisonDagger") then
					room:setTag("PD_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("ThunderKnife") then
					room:setTag("TK_ID", sgs.QVariant(id))
					cardIds:append(id)
				end

				--移除徹里吉的車車
				if sgs.Sanguosha:getCard(id):isKindOf("sichengliangyu") then
					room:setTag("SCLY_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("tiejixuanyu") then
					room:setTag("TJXY_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("feilunzhanyu") then
					room:setTag("FLZY_ID", sgs.QVariant(id))
					cardIds:append(id)
				end

				--移除馮方女的寶梳
				if sgs.Sanguosha:getCard(id):isKindOf("qiongshu") then
					room:setTag("QS_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("xishu") then
					room:setTag("XS_ID", sgs.QVariant(id))
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("jinshu") then
					room:setTag("JS_ID", sgs.QVariant(id))
					cardIds:append(id)
				end

				--移除專屬錦囊
				if sgs.Sanguosha:getCard(id):isKindOf("binglinchengxia") then
					cardIds:append(id)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("tiaojiyanmei") then
					cardIds:append(id)
				end

				local has_shen_xunyu = false
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill("tianzuo") then
						has_shen_xunyu = true
					end
				end
				if not has_shen_xunyu then
					if sgs.Sanguosha:getCard(id):isKindOf("qizhengxiangsheng") then
						cardIds:append(id)
					end
				end

			

				--if sgs.Sanguosha:getCard(id):isKindOf("SlashJink") then
				--	cardIds:append(id)
				--end

				--移除抗秦錦囊
				if splayer:getMark("gameMode_QinMode") == 0 or splayer:getMark("QinModeEvent") ~= 1 then
					if sgs.Sanguosha:getCard(id):isKindOf("shangyangbianfa") then
						cardIds:append(id)
					end
				end
				if splayer:getMark("gameMode_QinMode") == 0 or splayer:getMark("QinModeEvent") ~= 7 then
					if sgs.Sanguosha:getCard(id):isKindOf("DragonSword") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("DragonSeal") then
						cardIds:append(id)
					end
				else
					if sgs.Sanguosha:getCard(id):isKindOf("DragonSword") then
						local has_yingzheng = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "qin_yingzheng" or p:getGeneral2Name() == "qin_yingzheng" then
								has_yingzheng = true
								godgeneral = p
							end
						end
						if has_yingzheng then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						end
					end
					if sgs.Sanguosha:getCard(id):isKindOf("DragonSeal") then
						local has_yingzheng = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "qin_yingzheng" or p:getGeneral2Name() == "qin_yingzheng" then
								has_yingzheng = true
								godgeneral = p
							end
						end
						if has_yingzheng then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						end
					end
				end

				--------------------------------------------------------------------
				--神武再世相關
				if splayer:getMark("gameMode_godMode") > 0 or (not (Set(sgs.Sanguosha:getBanPackages()))["godequip"]) then

					if splayer:getMark("gameMode_godMode") > 0 then
						--移除神武再世模式的【樂不思蜀】、【兵糧寸斷】、【無中生有】、【借刀殺人】
						--用這方式移除是因為選項 "移除無中生有和借刀殺人" 有些狀況會閃退。
						if sgs.Sanguosha:getCard(id):isKindOf("Indulgence") then
							cardIds:append(id)
						end
						if sgs.Sanguosha:getCard(id):isKindOf("SupplyShortage") then
							cardIds:append(id)
						end
						if sgs.Sanguosha:getCard(id):isKindOf("ExNihilo") then
							cardIds:append(id)
						end
						if sgs.Sanguosha:getCard(id):isKindOf("Collateral") then
							cardIds:append(id)
						end
					elseif (not (Set(sgs.Sanguosha:getBanPackages()))["godequip"]) then
						if sgs.Sanguosha:getCard(id):isKindOf("god_nihilo") then
							cardIds:append(id)
						end
						if sgs.Sanguosha:getCard(id):isKindOf("god_flower") then
							cardIds:append(id)
						end
					end
					--移除多餘的神武再世模式神裝備
					if sgs.Sanguosha:getCard(id):isKindOf("GodBlade") then
						local has_shenguanyu = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenguanyu" or p:getGeneral2Name() == "shenguanyu" then
								has_shenguanyu = true
								godgeneral = p
							end
						end
						if has_shenguanyu then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodQin") then
						local has_shenzhouyu = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhouyu" or p:getGeneral2Name() == "shenzhouyu" then
								has_shenzhouyu = true
								godgeneral = p
							end
						end
						if has_shenzhouyu then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodHalberd") then
						local has_shenlvbu = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenlvbu" or p:getGeneral2Name() == "shenlvbu" then
								has_shenlvbu = true
								godgeneral = p
							end
						end
						if has_shenlvbu then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodSword") then
						local has_shenzhaoyun = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhaoyun" or p:getGeneral2Name() == "shenzhaoyun"
							or p:getGeneralName() == "new_godzhaoyun" or p:getGeneral2Name() == "new_godzhaoyun"
							then
								has_shenzhaoyun = true
								godgeneral = p
							end
						end
						if has_shenzhaoyun then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodDiagram") then
						local has_shenzhugeliang = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhugeliang" or p:getGeneral2Name() == "shenzhugeliang" then
								has_shenzhugeliang = true
								godgeneral = p
							end
						end
						if has_shenzhugeliang then
							if not godgeneral:getArmor() then
								local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
								room:moveCardsAtomic(move, false)
							end
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodPao") then
						local has_shenlvmeng = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenlvmeng" or p:getGeneral2Name() == "shenlvmeng" then
								has_shenlvmeng = true
								godgeneral = p
							end
						end
						if has_shenlvmeng then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):objectName() == "god_horse" then
						local has_shencaocao = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shencaocao" or p:getGeneral2Name() == "shencaocao" then
								has_shencaocao = true
								godgeneral = p
							end
						end
						if has_shencaocao then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodHat") then
						local has_shensimayi = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shensimayi" or p:getGeneral2Name() == "shensimayi"
							or p:getGeneralName() == "shensimayi_po" or p:getGeneral2Name() == "shensimayi_po" then
								has_shensimayi = true
								godgeneral = p
							end
						end
						if has_shensimayi then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_book") then
						local has_shencaopi = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shencaopi" or p:getGeneral2Name() == "shencaopi" then
								has_shencaopi = true
								godgeneral = p
							end
						end
						if has_shencaopi then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end

					if sgs.Sanguosha:getCard(id):isKindOf("god_ji") then
						local has_shenzhenji = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhenji" or p:getGeneral2Name() == "shenzhenji" then
								has_shenzhenji = true
								godgeneral = p
							end
						end
						if has_shenzhenji then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_bow") then
						local has_shenganning = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenganning" or p:getGeneral2Name() == "shenganning" then
								has_shenganning = true
								godgeneral = p
							end
						end
						if has_shenganning then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):objectName() == "god_deer" then
						local has_shenluxun_sec_rev = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenluxun_sec_rev" or p:getGeneral2Name() == "shenluxun_sec_rev" then
								has_shenluxun_sec_rev = true
								godgeneral = p
							end
						end
						if has_shenluxun_sec_rev then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_harmony_sword") then
						local has_shenliubei = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenliubei" or p:getGeneral2Name() == "shenliubei" then
								has_shenliubei = true
								godgeneral = p
							end
						end
						if has_shenliubei then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end	
					if sgs.Sanguosha:getCard(id):isKindOf("god_axe") then
						local has_shenzhangliao = false
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhangliao" or p:getGeneral2Name() == "shenzhangliao" or p:getGeneralName() == "ol_shenzhangliao" or p:getGeneral2Name() == "ol_shenzhangliao" then
								has_shenzhangliao = true
								godgeneral = p
							end
						end
						if has_shenzhangliao then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						elseif (Set(sgs.Sanguosha:getBanPackages()))["godequip"] then
							cardIds:append(id)
						end

					end		
										
					--移除正常裝備
					if sgs.Sanguosha:getCard(id):isKindOf("Blade") then
						local has_shenguanyu = false
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenguanyu" or p:getGeneral2Name() == "shenguanyu" then
								has_shenguanyu = true
							end
						end
						if has_shenguanyu or (not (Set(sgs.Sanguosha:getBanPackages()))["godequip"]) then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("Fan") then
						local has_shenzhouyu = false
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhouyu" or p:getGeneral2Name() == "shenzhouyu" then
								has_shenzhouyu = true
							end
						end
						if has_shenzhouyu or (not (Set(sgs.Sanguosha:getBanPackages()))["godequip"]) then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("Halberd") then
						local has_shenlvbu = false
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenlvbu" or p:getGeneral2Name() == "shenlvbu" then
								has_shenlvbu = true
							end
						end
						if has_shenlvbu or (not (Set(sgs.Sanguosha:getBanPackages()))["godequip"]) then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("QinggangSword") then
						local has_shenzhaoyun = false
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhaoyun" or p:getGeneral2Name() == "shenzhaoyun"
							or p:getGeneralName() == "new_godzhaoyun" or p:getGeneral2Name() == "new_godzhaoyun"
							then
								has_shenzhaoyun = true
							end
						end
						if has_shenzhaoyun or (not (Set(sgs.Sanguosha:getBanPackages()))["godequip"]) then
							cardIds:append(id)
						end

					end
					if sgs.Sanguosha:getCard(id):isKindOf("EightDiagram") then
						local has_shenzhugeliang = false
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:getGeneralName() == "shenzhugeliang" or p:getGeneral2Name() == "shenzhugeliang" then
								has_shenzhugeliang = true
							end
						end
						if has_shenzhugeliang or (not (Set(sgs.Sanguosha:getBanPackages()))["godequip"]) then
							cardIds:append(id)
						end

					end
				else
					if sgs.Sanguosha:getCard(id):isKindOf("GodBlade") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodQin") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodHalberd") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodSword") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodDiagram") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodPao") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):objectName() == "god_horse" then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodHat") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_nihilo") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_flower") then
						cardIds:append(id)
					end

					if sgs.Sanguosha:getCard(id):isKindOf("god_book") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_ji") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):objectName() == "god_deer" then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_bow") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_axe") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("god_harmony_sword") then
						cardIds:append(id)
					end
				end

				----------------------------------------------------------------------------------

				--虎牢關相關
				if splayer:getMark("gameMode_hulaoguan") > 0 then

					--移除多餘的虎牢關裝備
					if sgs.Sanguosha:getCard(id):isKindOf("muso_halberd") or
						sgs.Sanguosha:getCard(id):isKindOf("long_pheasant_tail_feather_purple_gold_crown") or
						sgs.Sanguosha:getCard(id):isKindOf("red_cotton_hundred_flower_robe") or
						sgs.Sanguosha:getCard(id):isKindOf("linglong_lion_rough_band") then

						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:isLord() then
								godgeneral = p
							end
						end
						if godgeneral and godgeneral:getMark("use_hulaoguan_equip"..sgs.Sanguosha:getCard(id):objectName()) then
							local move = sgs.CardsMoveStruct(id, nil, godgeneral, sgs.Player_DrawPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
							room:moveCardsAtomic(move, false)
						else
							cardIds:append(id)
						end

					end		
										
					--移除正常裝備
					if sgs.Sanguosha:getCard(id):isKindOf("Halberd") then
						local godgeneral
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							if p:isLord() then
								godgeneral = p
							end
						end
						if godgeneral and godgeneral:getMark("use_hulaoguan_equipmuso_halberd") then
							cardIds:append(id)
						end
					end
				else
					if sgs.Sanguosha:getCard(id):isKindOf("muso_halberd") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("long_pheasant_tail_feather_purple_gold_crown") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("red_cotton_hundred_flower_robe") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("linglong_lion_rough_band") then
						cardIds:append(id)
					end
				end

				----------------------------------------------------------------------------------

				--移除文和亂舞
				if splayer:getMark("gameMode_wenho") > 0 then
					
					--移除文和亂舞模式的【樂不思蜀】、【兵糧寸斷】、【無懈可擊】、【桃園結義】、【木牛流馬】
					if sgs.Sanguosha:getCard(id):isKindOf("Indulgence") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("SupplyShortage") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("Nullification") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("GodSalvation") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("WoodenOx") then
						cardIds:append(id)
					end
				else
					if sgs.Sanguosha:getCard(id):isKindOf("wenholuanwu") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("douzhuanxingyi") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("toulianghuanzhu") then
						cardIds:append(id)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("lidaitaojiang") then
						cardIds:append(id)
					end
				end

				--無木馬的活動場
				if splayer:getMark("gameMode_noOx") > 0 then
					if sgs.Sanguosha:getCard(id):isKindOf("WoodenOx") then
						cardIds:append(id)
					end
				end
			end
			if not cardIds:isEmpty() then
				for _, id in sgs.qlist(cardIds) do
					local name = sgs.Sanguosha:getCard(id):objectName() 
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if name == "shangyangbianfa" and p:getGeneralName() == "qin_shangyang" then
						else
							room:setPlayerMark(p,"AG_BANCard"..name ,1)
						end
					end
				end
				local move = sgs.CardsMoveStruct(cardIds, nil, nil, sgs.Player_DrawPile, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move, false)
			end

			--抗秦活動場允許使用商央變法
			if splayer:getMark("gameMode_QinMode") > 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"AG_BANCardshangyangbianfa",0)
				end
			end

			--應變篇給予所有人技能
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getmark("AG_BANCardsuijiyingbian") == 0 and not p:hasSkill("suijiyingbian_skill") then
					--room:attachSkillToPlayer(p,"suijiyingbian_skill")
				end
			end

		else
			--銷毀裝備
			local move, id = data:toMoveOneTime(), room:getTag("TC_ID"):toInt()
			if move.from_places:contains(sgs.Player_PlaceEquip) and id > 0 and move.card_ids:contains(id) then
				local move1 = sgs.CardsMoveStruct(id, nil, nil, room:getCardPlace(id), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			local id2 = room:getTag("RS_ID"):toInt()
			local id3 = room:getTag("LB_ID"):toInt()
			local id4 = room:getTag("WS_ID"):toInt()
			local id5 = room:getTag("PD_ID"):toInt()
			local id6 = room:getTag("TK_ID"):toInt()
			if move.to_place == sgs.Player_DiscardPile and id2 > 0 and move.card_ids:contains(id2) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_RS",0)
				end
				local move1 = sgs.CardsMoveStruct(id2, nil, nil, room:getCardPlace(id2), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.to_place == sgs.Player_DiscardPile and id3 > 0 and move.card_ids:contains(id3) then
				local move1 = sgs.CardsMoveStruct(id3, nil, nil, room:getCardPlace(id3), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_LB",0)
				end
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.to_place == sgs.Player_DiscardPile and id4 > 0 and move.card_ids:contains(id4) then
				local move1 = sgs.CardsMoveStruct(id4, nil, nil, room:getCardPlace(id4), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_WS",0)
				end
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.to_place == sgs.Player_DiscardPile and id5 > 0 and move.card_ids:contains(id5) then
				local move1 = sgs.CardsMoveStruct(id5, nil, nil, room:getCardPlace(id5), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_PD",0)
				end
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.to_place == sgs.Player_DiscardPile and id6 > 0 and move.card_ids:contains(id6) then
				local move1 = sgs.CardsMoveStruct(id6, nil, nil, room:getCardPlace(id6), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_TK",0)
				end
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			
			--徹里吉的車車
			local id7 = room:getTag("SCLY_ID"):toInt()
			local id8 = room:getTag("TJXY_ID"):toInt()
			local id9 = room:getTag("FLZY_ID"):toInt()
			if move.from_places:contains(sgs.Player_PlaceEquip) and id7 > 0 and move.card_ids:contains(id7) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_SCLY",0)
				end
				local move1 = sgs.CardsMoveStruct(id7, nil, nil, room:getCardPlace(id7), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.from_places:contains(sgs.Player_PlaceEquip) and id8 > 0 and move.card_ids:contains(id8) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_TJXY",0)
				end
				local move1 = sgs.CardsMoveStruct(id8, nil, nil, room:getCardPlace(id8), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.from_places:contains(sgs.Player_PlaceEquip) and id9 > 0 and move.card_ids:contains(id9) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_FLZY",0)
				end
				local move1 = sgs.CardsMoveStruct(id9, nil, nil, room:getCardPlace(id9), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end

			--馮方女的寶梳

			local id_QS = room:getTag("QS_ID"):toInt()
			local id_XS = room:getTag("XS_ID"):toInt()
			local id_JS = room:getTag("JS_ID"):toInt()
			if move.from_places:contains(sgs.Player_PlaceEquip) and id_QS > 0 and move.card_ids:contains(id_QS) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_QS",0)
				end
				local move1 = sgs.CardsMoveStruct(id_QS, nil, nil, room:getCardPlace(id_QS), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.from_places:contains(sgs.Player_PlaceEquip) and id_XS > 0 and move.card_ids:contains(id_XS) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_XS",0)
				end
				local move1 = sgs.CardsMoveStruct(id_XS, nil, nil, room:getCardPlace(id_XS), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
			if move.from_places:contains(sgs.Player_PlaceEquip) and id_JS > 0 and move.card_ids:contains(id_JS) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p,"hasequip_JS",0)
				end
				local move1 = sgs.CardsMoveStruct(id_JS, nil, nil, room:getCardPlace(id_JS), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end

		end
		return false
	end
}

if not sgs.Sanguosha:getSkill("card_remover") then skills:append(card_remover) end

GSTrigger = sgs.CreateTriggerSkill{
	name = "#GSTrigger",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
	end
}
if not sgs.Sanguosha:getSkill("#GSTrigger") then skills:append(GSTrigger) end

local generals = sgs.Sanguosha:getLimitedGeneralNames()  --给系统当中的所有非完全隐藏的武将添加技能“RAFTOM_start”，没加不会正确移除专属装备
for _, name in ipairs(generals) do
	local general = sgs.Sanguosha:getGeneral(name)
	--if general and not general:isTotallyHidden() then
	if general then
		general:addSkill("#GSTrigger")
	end
end
local general = sgs.Sanguosha:getGeneral("anjiang")
general:addSkill("#GSTrigger")


--非特定模式禁用特定卡牌
--[[
banmodecard = sgs.CreateProhibitSkill{
	name = "banmodecard",
	is_prohibited = function(self, from, to, card)
		return
		 (((not from:hasSkill("jingong")) and (not from:hasSkill("mobile_jingong"))) and (card:isKindOf("xiaolicangdao") or card:isKindOf("meirenji")))
		 or (from:getMark("gameMode_wenho") == 0 and (card:isKindOf("wenholuanwu") or card:isKindOf("douzhuanxingyi") or card:isKindOf("toulianghuanzhu") or card:isKindOf("lidaitaojiang")))
		 or (from:getMark("gameMode_godMode") == 0 and (card:isKindOf("god_nihilo") or card:isKindOf("god_flower")))
	end
}
]]--
banmodecard = sgs.CreateProhibitSkill{
	name = "banmodecard",
	is_prohibited = function(self, from, to, card)
		if (card:isKindOf("xiaolicangdao") or card:isKindOf("meirenji")) then
			if (not from:hasSkill("jingong")) and (not from:hasSkill("mobile_jingong")) then
				return true
			end
		elseif card:isKindOf("suijiyingbian") then
			return true
		elseif card:isKindOf("binglinchengxia") then
			return false
		elseif card:isKindOf("tiaojiyanmei") then
			--if not from:hasSkill("mobile_kuanji") then
			return false
		else
			if not card:isKindOf("RedSword") and not card:isKindOf("LiecuiBlade") and
			 not card:isKindOf("WaterSword") and not card:isKindOf("PoisonDagger") and
			 not card:isKindOf("ThunderKnife") and not card:isKindOf("SevenGemsBlade") and
			 not card:isKindOf("ThunderclapCatapult") and not card:isKindOf("MobileThunderclapCatapult") and
			  not card:isKindOf("poison") then

			 	return from:getMark("AG_BANCard"..card:objectName()) > 0
			 end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("banmodecard") then skills:append(banmodecard) end


--王允專屬裝備

meirenji = sgs.CreateTrickCard{
	name = "meirenji",
	class_name = "meirenji",
	target_fixed = false,
	can_recast = false,
	--suit = sgs.Card_Spade,
	--number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() and to_select:isMale()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local females = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isFemale() then
					females:append(p)
				end
			end
			if not females:isEmpty() then
				room:sortByActionOrder(females)
				for _, p in sgs.qlist(females) do
					if p:isFemale() and p:isAlive() and not effect.to:isKongcheng() then
						local card_id = room:askForCardChosen(p, effect.to, "h", self:objectName())
						if card_id ~= -1 then
							room:obtainCard(p, card_id, false)
						end
						if not p:isKongcheng() and effect.from:isAlive() then
							local give_back_card = room:askForCard(p, ".|.|.|hand!", "@meirenji-give:"..effect.from:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
							if give_back_card then
								room:obtainCard(effect.from, give_back_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), effect.from:objectName(), self:objectName(), ""), false)
							end
						end
					end
				end
			end
			if effect.from:isAlive() and effect.to:isAlive() then
				local n = effect.from:getHandcardNum() - effect.to:getHandcardNum()
				if n < 0 then
					room:doAnimate(1, effect.from:objectName(), effect.to:objectName())
					room:damage(sgs.DamageStruct(self, effect.from, effect.to, 1))
				elseif n > 0 then
					room:doAnimate(1, effect.to:objectName(), effect.from:objectName())
					room:damage(sgs.DamageStruct(self, effect.to, effect.from, 1))
				end
			end
		end
	end
}
meirenji:setParent(extension)

xiaolicangdao = sgs.CreateTrickCard{
	name = "xiaolicangdao",
	class_name = "xiaolicangdao",
	target_fixed = false,
	can_recast = false,
	--suit = sgs.Card_Club,
	--number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local draw_num = math.min(5, effect.to:getLostHp())
			room:drawCards(effect.to, draw_num, self:objectName())
			if effect.to:isAlive() then
				room:damage(sgs.DamageStruct(self, effect.from:isAlive() and effect.from or nil, effect.to, 1))
			end
		end
	end
}
xiaolicangdao:setParent(extension)
--王允專屬裝備
SevenGemsBladeSkill = sgs.CreateTriggerSkill{
	name = "SevenGemsBladeSkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				local do_anim = false
				for _, p in sgs.qlist(use.to) do
					if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
						do_anim = (p:getArmor() and p:hasArmorEffect(p:getArmor():objectName())) or p:hasSkills("bazhen|linglong|bossmanjia")
						p:addQinggangTag(use.card)
					end
				end
				if do_anim then
				
				end
			end
		else
			local damage = data:toDamage()
			if not damage.to:isWounded() and damage.card and damage.card:isKindOf("Slash") and damage.by_user and not damage.chain and not damage.transfer
				and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0 then
				local log = sgs.LogMessage()
				log.type = "$hanyong"
				log.from = damage.from
				log.card_str = damage.card:toString()
				log.arg = self:objectName()
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("SevenGemsBlade")
	end
}
if not sgs.Sanguosha:getSkill("SevenGemsBladeSkill") then skills:append(SevenGemsBladeSkill) end

SevenGemsBlade = sgs.CreateWeapon{
	name = "seven_gems_blade",
	class_name = "SevenGemsBlade",
	suit = sgs.Card_Spade,
	number = 6,
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("SevenGemsBladeSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "SevenGemsBladeSkill")
	end
}
SevenGemsBlade:setParent(extension)

ThunderclapCatapultSkill = sgs.CreateTriggerSkill{
	name = "ThunderclapCatapultSkill",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to:isAlive() and damage.to:objectName() ~= player:objectName() and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if damage.to:getArmor() then
				dummy:addSubcard(damage.to:getArmor():getEffectiveId())
			end
			if damage.to:getDefensiveHorse() then
				dummy:addSubcard(damage.to:getDefensiveHorse():getEffectiveId())
			end
			local _data = sgs.QVariant()
			_data:setValue(damage.to)
			if dummy:subcardsLength() > 0 and room:askForSkillInvoke(player, self:objectName(), _data) then
				room:throwCard(dummy, damage.to, player)
			end
			dummy:deleteLater()
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("ThunderclapCatapult")
	end
}
if not sgs.Sanguosha:getSkill("ThunderclapCatapultSkill") then skills:append(ThunderclapCatapultSkill) end

ThunderclapCatapult = sgs.CreateWeapon{
	name = "thunderclap_catapult",
	class_name = "ThunderclapCatapult",
	suit = sgs.Card_Diamond,
	number = 9,
	range = 9,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("ThunderclapCatapultSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "ThunderclapCatapultSkill")
	end
}
ThunderclapCatapult:setParent(extension)

MobileThunderclapCatapultSkill = sgs.CreateTriggerSkill{
	name = "MobileThunderclapCatapultSkill",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to:isAlive() and damage.to:objectName() ~= player:objectName() and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			
			for _, equip in sgs.qlist(damage.to:getEquips()) do
				dummy:addSubcard(equip:getEffectiveId())
			end

			local _data = sgs.QVariant()
			_data:setValue(damage.to)
			if dummy:subcardsLength() > 0 and room:askForSkillInvoke(player, self:objectName(), _data) then
				room:throwCard(dummy, damage.to, player)
			end
			dummy:deleteLater()
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("MobileThunderclapCatapult")
	end
}
if not sgs.Sanguosha:getSkill("MobileThunderclapCatapultSkill") then skills:append(MobileThunderclapCatapultSkill) end

MobileThunderclapCatapult = sgs.CreateWeapon{
	name = "mobile_thunderclap_catapult",
	class_name = "MobileThunderclapCatapult",
	suit = sgs.Card_Diamond,
	number = 9,
	range = 9,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("MobileThunderclapCatapultSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "MobileThunderclapCatapultSkill")
	end
}
MobileThunderclapCatapult:setParent(extension)

sgs.LoadTranslationTable{
	["card_remover"] = "卡牌銷毀",

	["wangyun_exclusive_trick_card"] = "王允專屬錦囊",
	["meirenji"] = "美人計",
	[":meirenji"] = "錦囊牌<br /><b>時機</b>：出牌階段<br /><b>目標</b>：一名有手牌的其他男性角色< br /><b>效果</b>：每名女性角色各獲得目標角色一張手牌並將一張手牌交給你，然後比較你與目標角色的手牌數，手牌少的角色對手牌多的角色造成1點傷害。",
	["@meirenji"] = "請選擇目標",
	["~meirenji"] = "選擇一名有手牌的男性角色→點擊確定",
	["jingong-meirenji-invoke"] = "請選擇【美人計】 目標<br/> <b>操作提示</b>: 選擇一名與你不同且有手牌的男性角色→點擊確定<br />",
	["@meirenji-give"] = "請選擇一張手牌給 %src",
	["xiaolicangdao"] = "笑裡藏刀",
	[":xiaolicangdao"] = "錦囊牌<br /><b>時機</b>：出牌階段<br /><b>目標</b>：一名其他角色<br /><b >效果</b>：目標角色摸X張牌（X為目標角色已損失的體力值且至多為5），然後你對目標角色造成1點傷害。",
	["@xiaolicangdao"] = "請選擇目標",
	["~xiaolicangdao"] = "選擇一名角色→點擊確定",
	["$jingong_fail"] = "%from 執行“%arg”未造成傷害，%from 失去1點體力",
	["jingong-xiaolicangdao-invoke"] = "請選擇 【笑裡藏刀】 目標<br/> <b>操作提示</b>: 選擇一名與你不同的角色→點擊確定<br/>",
	["jingongmeirenji"] = "矜功",
	["jingongxiaolicangdao"] = "矜功",

	["wangyun_exclusive_equip_card"] = "王允專屬裝備",
	["seven_gems_blade"] = "七寶刀",
	[":seven_gems_blade"] = "裝備牌·武器<br /><b>攻擊範圍</b>：2<br /><b>武器技能</b>：鎖定技，當你使用【殺】指定一個目標後，你無視其防具；當你使用【殺】對目標角色造成傷害時，若其未受傷，此傷害+1。",
	["SevenGemsBladeSkill"] = "七寶刀",
	["$hanyong"] = " %from 執行“%arg”的效果，%card 的傷害值+1 ",

	["liuye_exclusive_card"] = "劉曄專屬裝備",
	["thunderclap_catapult"] = "霹靂車",
	[":thunderclap_catapult"] = "裝備牌·武器<br /><b>攻擊範圍</b>：9<br /><b>武器技能</b>：當你對其他角色造成傷害後，若造成傷害的是不為延時錦囊牌的牌，你可以棄置其裝備區內的防具牌和+1坐騎（不足則全棄）；當你失去裝備區裡的【霹靂車】後，你令此牌銷毀。",
	["ThunderclapCatapultSkill"] = "霹靂車",

	["mobile_thunderclap_catapult"] = "霹靂車",
	[":mobile_thunderclap_catapult"] = "裝備牌·武器<br /><b>攻擊範圍</b>：9<br /><b>武器技能</b>：當你對其他角色造成傷害後，若造成傷害的是不為延時錦囊牌的牌，你可以棄置其裝備區內的所有牌。",
	["MobileThunderclapCatapultSkill"] = "霹靂車",
}

--蒲元專屬裝備
--紅緞槍
RedSwordskill = sgs.CreateTriggerSkill{
	name = "RedSwordskill" ,
	events = {sgs.EventPhaseStart,sgs.Damage} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getWeapon() then
						if p:getWeapon():isKindOf("RedSword") then
							room:setPlayerFlag(p, "can_RedSword")
						end
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if player:getWeapon() then
				if damage.card and damage.card:isKindOf("Slash") and player:getWeapon():isKindOf("RedSword")
				 and player:getMark("RedSword_count-Clear") < 1 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:addPlayerMark(player,"RedSword_count-Clear")
						local judge = sgs.JudgeStruct()
						judge.reason = self:objectName()
						judge.who = player
						room:judge(judge)
						if judge.card:isRed() then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player, recover)
						else
							player:drawCards(2)
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
if not sgs.Sanguosha:getSkill("RedSwordskill") then skills:append(RedSwordskill) end

RedSword = sgs.CreateWeapon{
	name = "red_sword",
	class_name = "RedSword",
	suit = sgs.Card_Heart,
	number = 1,
	range = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("RedSwordskill")
		room:getThread():addTriggerSkill(skill)
	end
}
RedSword:setParent(extension)
sgs.LoadTranslationTable{
	["red_sword"] = "紅緞槍",
	["RedSwordskill"] = "紅緞槍",
	[":red_sword"] = "每回合限一次，當你使用【殺】造成傷害後，你可以進行一次判定，若結果為紅色，你回復1點體力。若結果為黑色，你摸兩張牌。",
}

--烈淬刀 LiecuiBlade
LiecuiBladeskill = sgs.CreateTriggerSkill{
	name = "LiecuiBladeskill" ,
	events = {sgs.DamageCaused}, 
	on_trigger = function(self, event, player, data)		
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and player:getMark("LiecuiBlade_count-Clear") < 2 then
			local card = room:askForCard(player, "..", "@liecui_blade-card", data, sgs.CardDiscarded)
			if card then
				room:addPlayerMark(player,"LiecuiBlade_count-Clear")
				damage.damage = damage.damage + 1
				local msg = sgs.LogMessage()
				msg.type = "#LiecuiBlade"
				msg.from = player
				msg.to:append(damage.to)
				msg.arg = tostring(damage.damage-1)
				msg.arg2 = tostring(damage.damage)
				room:sendLog(msg)						
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getWeapon() and target:getWeapon():isKindOf("LiecuiBlade")
	end,
}

LiecuiBladeskillTM = sgs.CreateTargetModSkill{
	name = "LiecuiBladeskillTM", 
	residue_func = function(self, from)
		if from:getWeapon() then
			if from:getWeapon():isKindOf("LiecuiBlade") then
				return 1
			end
		end
		return 0
	end
}

if not sgs.Sanguosha:getSkill("LiecuiBladeskill") then skills:append(LiecuiBladeskill) end
if not sgs.Sanguosha:getSkill("LiecuiBladeskillTM") then skills:append(LiecuiBladeskillTM) end

LiecuiBlade = sgs.CreateWeapon{
	name = "liecui_blade",
	class_name = "LiecuiBlade",
	suit = sgs.Card_Diamond,
	number = 1,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("LiecuiBladeskill")
		room:getThread():addTriggerSkill(skill)
	end
}
LiecuiBlade:setParent(extension)
sgs.LoadTranslationTable{
	["liecui_blade"] = "烈淬刀",
	[":liecui_blade"] = "每回合限兩次，你使用【殺】對目標角色造成傷害時，你可以棄置一張牌，令此傷害+1；出牌階段你可以多使用一張【殺】。",
	["#LiecuiBlade"] = "%from 發動“<font color=\"yellow\"><b>烈淬刀</b></font>”的效果，對%to 造成傷害由 %arg 點"..
	"增加到 %arg2 點",
	["@liecui_blade-card"] = "你可以棄一張牌，令此傷害+1",
}


--水波劍 WaterSwordskill

WaterSwordskill = sgs.CreateTriggerSkill{
	name = "WaterSwordskill" ,
	events = {sgs.PreCardUsed} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) and not use.card:isKindOf("Collateral") and not use.card:isKindOf("Nullification")  then
			local room = player:getRoom()
			if (sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY) then return false end
			local available_targets = sgs.SPlayerList()
			if (not use.card:isKindOf("AOE")) and (not use.card:isKindOf("GlobalEffect")) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then continue end
					if (use.card:targetFixed()) then
						if (not use.card:isKindOf("Peach")) or (p:isWounded()) then
							available_targets:append(p)
						end
					else
						if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
							available_targets:append(p)
						end
					end
				end
			end
			room:setTag("WaterSwordskillData", data)
			local extra = room:askForPlayerChosen(player, available_targets, "WaterSwordskill", "@qiaoshui-add:::" .. use.card:objectName(),true,true)
			if extra then
				room:addPlayerMark(player,"WaterSword_count-Clear")
				use.to:append(extra)
				room:sortByActionOrder(use.to)
			end
			room:removeTag("WaterSwordskillData")
		end
		data:setValue(use)
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("WaterSword") and target:getMark("WaterSword_count-Clear") < 2
	end
}

WaterSwordskillTargetMod = sgs.CreateTargetModSkill{
	name = "#WaterSwordskill-target" ,
	pattern = "Slash,TrickCard+^DelayedTrick" ,
	distance_limit_func = function(self, from)
		if (from:hasFlag("WaterSwordskillExtraTarget")) then
			return 1000
		end
		return 0
	end
}

WaterSwordskillTM = sgs.CreateTargetModSkill{
	name = "WaterSwordskillTM", 
	extra_target_func = function(self, from)
		if from:getWeapon() then
			if from:getWeapon():isKindOf("WaterSwordskill") then
				return 1
			end
		end
		return 0
	end
}

if not sgs.Sanguosha:getSkill("WaterSwordskill") then skills:append(WaterSwordskill) end
if not sgs.Sanguosha:getSkill("WaterSwordskillTM") then skills:append(WaterSwordskillTM) end


WaterSword = sgs.CreateWeapon{
	name = "water_sword",
	class_name = "WaterSword",
	suit = sgs.Card_Club,
	number = 1,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("WaterSwordskill")
		room:getThread():addTriggerSkill(skill)
	end
}
WaterSword:setParent(extension)
sgs.LoadTranslationTable{
	["water_sword"] = "水波劍",
	["WaterSwordskill"] = "水波劍",
	["waterswordskill"] = "水波劍",
	[":water_sword"] = "每回合限兩次，你使用普通錦囊牌或【殺】時，你可以多選一個目標。你失去裝備區裡的【水波劍】時，回復1點體力。",
	["@WaterSwordskill"] = "你可以多選擇一個目標。",
	["~WaterSwordskill"] = "選擇目標角色→點“確定”",
}
--混毒彎匕 poisondagger
PoisonDaggerskill = sgs.CreateTriggerSkill{
	name = "PoisonDaggerskill" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			if use.to:length() ~= 1 then return false end
			for _, p in sgs.qlist(use.to) do
					local _data = sgs.QVariant()
					_data:setValue(p)
					if player:askForSkillInvoke(self:objectName(), _data) then
						room:addPlayerMark(player,"PoisonDagger_count-Clear")
						local n = math.min(player:getMark("PoisonDagger_count-Clear"),5)
						room:loseHp(p,n)
					end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getWeapon() and target:getWeapon():isKindOf("PoisonDagger")
	end,
}
if not sgs.Sanguosha:getSkill("PoisonDaggerskill") then skills:append(PoisonDaggerskill) end

PoisonDagger = sgs.CreateWeapon{
	name = "poison_dagger",
	class_name = "PoisonDagger",
	suit = sgs.Card_Spade,
	number = 1,
	range = 1,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("PoisonDaggerskill")
		room:getThread():addTriggerSkill(skill)
	end
}
PoisonDagger:setParent(extension)
sgs.LoadTranslationTable{
	["poison_dagger"] = "混毒彎匕",
	["PoisonDaggerskill"] = "混毒彎匕",
	[":poison_dagger"] = "你使用【殺】指定目標後，你可以令目標角色失去X點體力（X為此武器本回合發動技能次數且最多為5）。",
}
--天雷刃 ThunderKnife
ThunderKnifeskill = sgs.CreateTriggerSkill{
	name = "ThunderKnifeskill" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then 
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			if use.to:length() ~= 1 then return false end
			for _, p in sgs.qlist(use.to) do
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(self:objectName(), _data) then
					local judge = sgs.JudgeStruct()
				    judge.who = p
				    judge.reason = "ThunderKnifeskill"
				    judge.pattern = ".|black"
					judge.good = false
					judge.negative = true
					room:judge(judge)
					if judge:isGood() then

					else
						if judge.card:getSuit() == sgs.Card_Spade then
							room:damage(sgs.DamageStruct(nil, nil, p, 3, sgs.DamageStruct_Thunder))
						elseif judge.card:getSuit() == sgs.Card_Club then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player, recover)
							room:damage(sgs.DamageStruct(nil, nil, p, 1, sgs.DamageStruct_Thunder))
							player:drawCards(1)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:getWeapon() and target:getWeapon():isKindOf("ThunderKnife")
	end,
}
if not sgs.Sanguosha:getSkill("ThunderKnifeskill") then skills:append(ThunderKnifeskill) end

ThunderKnife = sgs.CreateWeapon{
	name = "thunder_knife",
	class_name = "ThunderKnife",
	suit = sgs.Card_Spade,
	number = 1,
	range = 4,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("ThunderKnifeskill")
		room:getThread():addTriggerSkill(skill)
	end
}
ThunderKnife:setParent(extension)
sgs.LoadTranslationTable{
	["thunder_knife"] = "天雷刃",
	["ThunderKnifeskill"] = "天雷刃",
	[":thunder_knife"] = "你使用【殺】指定目標後，可令其進行一次判定，若結果為黑桃，該角色受到3點雷電傷害；若結果為梅花，該角色受到1點雷電傷害且你回復1點體力並摸一張牌。",
}



--神武牌堆
function lua_armor_null_check(player)
	if #player:getTag("Qinggang"):toStringList() > 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then
		return true
	end
	return false
end

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
GodBladeskill = sgs.CreateTriggerSkill{
	name = "GodBladeskill" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if use.card:isRed() then
				local _data = sgs.QVariant()
				_data:setValue(p)
				--if player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
					jink_table[index] = 0
				--end
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end,
	can_trigger = function(self, target)
		return target:getWeapon() and target:getWeapon():isKindOf("GodBlade")
	end,
}
if not sgs.Sanguosha:getSkill("GodBladeskill") then skills:append(GodBladeskill) end

GodBlade = sgs.CreateWeapon{
	name = "god_blade",
	class_name = "GodBlade",
	suit = sgs.Card_Spade,
	number = 5,
	range = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GodBladeskill")
		room:getThread():addTriggerSkill(skill)
	end
}
GodBlade:setParent(extension)
sgs.LoadTranslationTable{
	["god_blade"] = "鬼龍斬月刀",
	[":god_blade"] = "鎖定技，你使用的紅色【殺】不能被【閃】響應",
}

--神呂蒙-【國風玉袍】裝備/防具 鎖定技，你不能成為其他角色使用普通錦囊牌的目標。
GodPaoskill = sgs.CreateProhibitSkill{
	name = "GodPaoskill", 
	is_prohibited = function(self, from, to, card)
		return to:getArmor() and to:getArmor():isKindOf("GodPao") and (not lua_armor_null_check(to)) and card:isNDTrick() and from:objectName() ~= to:objectName()
	end
}

if not sgs.Sanguosha:getSkill("GodPaoskill") then skills:append(GodPaoskill) end

GodPao = sgs.CreateArmor{
	name = "god_pao",
	class_name = "GodPao",
	suit = sgs.Card_Spade,
	number = 9,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GodPaoskill")
		room:getThread():addTriggerSkill(skill)
	end
}
GodPao:setParent(extension)
sgs.LoadTranslationTable{
	["god_pao"] = "國風玉袍",
	[":god_pao"] = "鎖定技，你不能成為其他角色使用普通錦囊牌的目標。",
	["GodPaoskill"] = "國風玉袍",
}
--神周瑜-【赤焰鎮魂琴】（替換【朱雀羽扇】） 裝備/武器 4 鎖定技，你造成的傷害均視為具有火屬性。
--GodQin
GodQinskill = sgs.CreateTriggerSkill{
	name = "GodQinskill" ,
	events = {sgs.DamageCaused} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
			damage.nature = sgs.DamageStruct_Fire
--			 local msg = sgs.LogMessage()
--			msg.type = "#Liegong2"
--			msg.from = player
--			msg.to:append(damage.to)
--			msg.arg = tostring(damage.damage - 1)
--			msg.arg2 = tostring(damage.damage)
--			room:sendLog(msg)	
			data:setValue(damage)
		end
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("GodQin")
	end,
}

if not sgs.Sanguosha:getSkill("GodQinskill") then skills:append(GodQinskill) end

GodQin = sgs.CreateWeapon{
	name = "god_qin",
	class_name = "GodQin",
	suit = sgs.Card_Diamond,
	number = 1,
	range = 4,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GodQinskill")
		room:getThread():addTriggerSkill(skill)
	end
}
GodQin:setParent(extension)
sgs.LoadTranslationTable{
	["god_qin"] = "赤焰鎮魂琴",
	[":god_qin"] = "鎖定技，你造成的傷害均視為具有火屬性。",
}

--神諸葛亮-【奇門八卦】（替換【八卦陣】） 裝備/防具 鎖定技，其他角色使用的【殺】對你無效。
GodDiagramskill = sgs.CreateTriggerSkill{
	name = "GodDiagramskill" ,
	events = {sgs.TargetConfirmed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				if use.card:isKindOf("Slash") and (not lua_armor_null_check(player)) then
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
	end,
	can_trigger = function(self, target)
		return target:getArmor() and target:getArmor():isKindOf("GodDiagram")
	end,
}
if not sgs.Sanguosha:getSkill("GodDiagramskill") then skills:append(GodDiagramskill) end

GodDiagram = sgs.CreateArmor{
	name = "god_diagram",
	class_name = "GodDiagram",
	suit = sgs.Card_Club,
	number = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GodDiagramskill")
		room:getThread():addTriggerSkill(skill)
	end
}
GodDiagram:setParent(extension)

addcard = function(create_card, snn)
	local n = #snn
	for i=1, n, 2 do
		local tcard = create_card:clone()
		tcard:setSuit(snn[i])
		tcard:setNumber(snn[i+1])
		tcard:setParent(extension)
	end
end
--大量增加卡牌的方法 addcard(xxx ,{suit, number}) 
addcard(GodDiagram,{sgs.Card_Spade, 2})

sgs.LoadTranslationTable{
	["god_diagram"] = "奇門八卦",
	[":god_diagram"] = "鎖定技，其他角色使用的【殺】對你無效",
}
--神曹操-【絕塵金戈】（替換【絕影】） 裝備/坐騎 鎖定技，敵方角色計算與己方其他角色距離+1。
--god_horse
GodHorseSkill = sgs.CreateDistanceSkill{
	name = "GodHorseSkill",
	correct_func = function(self, from, to)
		local can_invoke = false
		for _, p in sgs.qlist(to:getAliveSiblings()) do
			if p:getDefensiveHorse() then
				if (p:getRole() == to:getRole()) and (p:getRole() ~= from:getRole()) and (p:getDefensiveHorse():objectName() == "god_horse") then
				--if (p:getDefensiveHorse():objectName() == "god_horse") then
					can_invoke = true
				end
			end
		end
		if can_invoke then
			return 1
		end
	end,
}
if not sgs.Sanguosha:getSkill("GodHorseSkill") then skills:append(GodHorseSkill) end

local GodHorse = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Spade, 5)
GodHorse:setObjectName("god_horse")
GodHorse:setParent(extension)

sgs.LoadTranslationTable{
	["god_horse"] = "絕塵金戈",
	[":god_horse"] = "鎖定技，敵方角色計算與己方其他角色距離+1",
	["GodHorseSkill"] = "絕塵金戈",
}

--神呂布-【修羅煉獄戟】（替換【方天畫戟】）裝備/武器 4 你使用【殺】可以額外指定任意名攻擊範圍內的其他角色為目標；鎖定技，你使用【殺】造成的傷害+1，然後令受到傷害的角色回复1點體力。
--GodHalberd
GodHalberdskill = sgs.CreateTriggerSkill{
	name = "GodHalberdskill" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused,sgs.Damage}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") then
					room:setPlayerFlag(damage.to, "GodHalberd_target")
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
					msg.type = "#GodHalberdtext"
					msg.from = player
					msg.to:append(damage.to)
					msg.arg = tostring(damage.damage - 1)
					msg.arg2 = tostring(damage.damage)
					room:sendLog(msg)						
					data:setValue(damage)
				end
			end		
			return false
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to:hasFlag("GodHalberd_target") then
				local recover = sgs.RecoverStruct()
				recover.who = damage.to
				recover.recover = 1
				room:recover(damage.to, recover)
				room:setPlayerFlag(damage.to, "-GodHalberd_target")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("GodHalberd")
	end
}

GodHalberdskillTM = sgs.CreateTargetModSkill{
	name = "GodHalberdskillTM", 
	extra_target_func = function(self, from)
		if from:getWeapon() then
			if from:getWeapon():isKindOf("GodHalberd") then
				return 99
			end
		end
		return 0
	end
}

if not sgs.Sanguosha:getSkill("GodHalberdskillTM") then skills:append(GodHalberdskillTM) end
if not sgs.Sanguosha:getSkill("GodHalberdskill") then skills:append(GodHalberdskill) end

GodHalberd = sgs.CreateWeapon{
	name = "god_halberd",
	class_name = "GodHalberd",
	suit = sgs.Card_Diamond,
	number = 12,
	range = 4,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GodHalberdskill")
		room:getThread():addTriggerSkill(skill)
	end
}
GodHalberd:setParent(extension)

sgs.LoadTranslationTable{
	["god_halberd"] = "修羅煉獄戟",
	[":god_halberd"] = "你使用【殺】可以額外指定任意名攻擊範圍內的其他角色為目標；鎖定技，你使用【殺】造成的傷害+1，然後令受到傷害的角色回復1點體力。",
	["#GodHalberdtext"] = "%from 的武器 “<font color=\"yellow\"><b>修羅煉獄戟</b></font>”生效，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--神司馬懿-【虛妄之冕】 裝備/寶物 鎖定技，摸牌階段，你額外摸兩張牌；你的手牌上限-1。
--GodHat
GodHatskill = sgs.CreateTriggerSkill{
	name = "GodHatskill" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			if player:getTreasure() then 
				if player:getTreasure():isKindOf("GodHat") then
					local count = data:toInt() + 2
					data:setValue(count)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("GodHat")
	end
}

GodHatskillMax = sgs.CreateMaxCardsSkill{
	name = "GodHatskillMax", 
	frequency = sgs.Skill_Compulsory ,
	extra_func = function(self, target)
		if target:getTreasure() then
			if target:getTreasure():isKindOf("GodHat") then
				return -1
			end
		end
	end
}

if not sgs.Sanguosha:getSkill("GodHatskillMax") then skills:append(GodHatskillMax) end
if not sgs.Sanguosha:getSkill("GodHatskill") then skills:append(GodHatskill) end

GodHat = sgs.CreateTreasure{
	name = "god_hat",
	class_name = "GodHat",
	suit = sgs.Card_Club,
	number = 4,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GodHatskill")
		room:getThread():addTriggerSkill(skill)
	end
}
GodHat:setParent(extension)

sgs.LoadTranslationTable{
	["god_hat"] = "虛妄之冕",
	[":god_hat"] = "鎖定技，摸牌階段，你額外摸兩張牌；你的手牌上限-1",
}
--神趙雲-【赤血青鋒】（替換【青釭劍】） 裝備/武器 2 鎖定技，你使用【殺】結算結束前，目標角色不能使用或打出手牌，且此【殺】無視其防具。
--GodSword
GodSwordskill = sgs.CreateTriggerSkill{
	name = "GodSwordskill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				local do_anim = false
				for _, p in sgs.qlist(use.to) do
					if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
						do_anim = (p:getArmor() and p:hasArmorEffect(p:getArmor():objectName())) or p:hasSkills("bazhen|linglong|bossmanjia")
						p:addQinggangTag(use.card)
					end
				end
				for _, p in sgs.qlist(use.to) do
					room:setPlayerMark(p,"ban_ur",1)
					room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
				end
				if do_anim then
				
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("GodSword")
	end,
}

if not sgs.Sanguosha:getSkill("GodSwordskill") then skills:append(GodSwordskill) end

GodSword = sgs.CreateWeapon{
	name = "god_sword",
	class_name = "GodSword",
	suit = sgs.Card_Spade,
	number = 6,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GodSwordskill")
		room:getThread():addTriggerSkill(skill)
	end
}
GodSword:setParent(extension)

sgs.LoadTranslationTable{
	["god_sword"] = "赤血青鋒",
	[":god_sword"] = "鎖定技，你使用【殺】結算結束前，目標角色不能使用或打出手牌，且此【殺】無視其防具。",
}

--禪讓詔書 黑桃K 寶物 每回合，其他角色於其回合外首次獲得牌時，你可給其一張牌，或令其給你一張牌。
--神曹丕專屬裝備
--god_book

function getIntList(cardlists)
	local list = sgs.IntList()
	for _,card in sgs.qlist(cardlists) do
		list:append(card:getId())
	end
	return list
end

function BeMan(room, player)
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:objectName() == player:objectName() then
			return p
		end
	end
end

god_bookskill = sgs.CreateTriggerSkill{
	name = "god_bookskill" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
--		if event == sgs.DrawInitialCards then
--			room:setPlayerFlag(player, "firstdraw")
--		elseif event == sgs.AfterDrawInitialCards then
--			room:setPlayerFlag(player, "-firstdraw")	
--		elseif event == sgs.CardsMoveOneTime then
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to  and move.to:objectName() ~= player:objectName() and BeMan(room, move.to):getPhase() == sgs.Player_NotActive
					and move.to_place == sgs.Player_PlaceHand
					and move.to:getMark("god_book-Clear") == 0
					then		
				room:setPlayerMark(BeMan(room, move.to),"god_book-Clear",1)
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:objectName() == move.to:objectName() then
							players:append(p)
						end
					end
					if room:askForYiji(player,getIntList(player:getCards("he")), self:objectName(), false, false, true, 1, players, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), move.to:objectName(), self:objectName(), ""), "god_book-distribute:"..move.to:objectName(), true) then

					else
						local card = room:askForCard(BeMan(room, move.to), "..!", "@god_book_give:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
						if card then
							room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, move.to:objectName(), player:objectName(), self:objectName(), ""))
						end
					end
				end
			end				
		end
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("god_book")
	end
}

if not sgs.Sanguosha:getSkill("god_bookskill") then skills:append(god_bookskill) end

god_book = sgs.CreateTreasure{
	name = "god_book",
	class_name = "god_book",
	suit = sgs.Card_Spade,
	number = 13,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("god_bookskill")
		room:getThread():addTriggerSkill(skill)
	end
}
god_book:setParent(extension)

sgs.LoadTranslationTable{
	["god_book"] = "禪讓詔書",
	["god_bookskill"] = "禪讓詔書",
	[":god_book"] = "每回合，其他角色於其回合外首次獲得牌時，你可給其一張牌，或令其給你一張牌。",
	["god_book-distribute"] = "你可以交給 %src 一张牌",
	["@god_book_give"] = "請交給 %src 一張牌",
}

--靈蛇髻 梅花Q 寶物 出牌階段結束時，你可以摸一張牌或將一張手牌放置在武將牌面上。若選擇後者，則在回合結束後你獲得此牌。
--神甄姬專屬裝備

god_jiskill = sgs.CreateTriggerSkill{
	name = "god_jiskill" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play and player:getTreasure() and player:getTreasure():isKindOf("god_ji") then
				if player:askForSkillInvoke(self:objectName(), data) then
					local card = room:askForCard(player, "..", "@god_ji", sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						player:addToPile("ji", card)
					else
						player:drawCards(1)
					end
				end
			elseif player:getPhase() == sgs.Player_Finish then
				if player:getPile("ji"):length() > 0 then
					local move = sgs.CardsMoveStruct()
					move.card_ids = player:getPile("ji")
					move.to = player
					move.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(move, true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

if not sgs.Sanguosha:getSkill("god_jiskill") then skills:append(god_jiskill) end

god_ji = sgs.CreateTreasure{
	name = "god_ji",
	class_name = "god_ji",
	suit = sgs.Card_Club,
	number = 12,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("god_jiskill")
		room:getThread():addTriggerSkill(skill)
	end
}
god_ji:setParent(extension)

sgs.LoadTranslationTable{
	["god_ji"] = "靈蛇髻",
	["god_jiskill"] = "靈蛇髻",
	["ji"] = "髻",
	[":god_ji"] = "出牌階段結束時，你可以摸一張牌或將一張手牌放置在武將牌面上。若選擇後者，則在回合結束後你獲得此牌。",
	["@god_ji"] = "你可以將一張手牌放置在武將牌面上",
}

--金烏落日弓 紅桃5 武器 攻擊範圍9
--你的出牌階段內，你一次性失去2張及以上手牌時，你可以選擇一名其他角色，並棄置其X張牌，X為你本次失去的牌的數量。
--神甘寧專屬裝備 替換麒麟弓
--god_bow
god_bowskill = sgs.CreateTriggerSkill{
	name = "god_bowskill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_Play
					and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) 
					and move.card_ids:length() >= 2 then
				local _targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isKongcheng() then
						_targets:append(p)
					end
				end
				if not _targets:isEmpty() then	
					local t = room:askForPlayerChosen(player,room:getOtherPlayers(player),"god_bow","@god_bow",true)
					if t then
						room:doAnimate(1, player:objectName(), t:objectName())
						for i = 1,move.card_ids:length(),1 do
							if player:canDiscard(t, "he") then
								local id = room:askForCardChosen(player, t, "he", "god_bow") 
								room:throwCard(id, t, player)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("god_bow")
	end,
}

if not sgs.Sanguosha:getSkill("god_bowskill") then skills:append(god_bowskill) end

god_bow = sgs.CreateWeapon{
	name = "god_bow",
	class_name = "god_bow",
	suit = sgs.Card_Heart,
	number = 5,
	range = 9,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("god_bowskill")
		room:getThread():addTriggerSkill(skill)
	end
}

god_bow:setParent(extension)

sgs.LoadTranslationTable{
	["god_bow"] = "金烏落日弓",
	[":god_bow"] = "你的出牌階段內，你一次性失去2張及以上手牌時，你可以選擇一名其他角色，並棄置其X張牌，X為你本次失去的牌的數量。",
	["@god_bow"] = "選擇一名其他角色，並棄置其X張牌",
}


--刑天破軍斧 方片5 武器  攻擊範圍4
--你的出牌階段內，當你使用牌指定唯一目標後，你可以棄置2張牌，令其本回合內無法使用或打出牌，且防具失效。
--神張遼專屬裝備 替換貫石斧
--god_axe
god_axeskill = sgs.CreateTriggerSkill{
	name = "god_axeskill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and (use.to:length() == 1) and (player:getHandcardNum() + player:getEquips():length()) > 2 and player:getPhase() == sgs.Player_Play then
				local card =room:askForExchange(player, self:objectName(), 2, 2, true, "@god_axe")
				if card then
					room:throwCard(card,player,player)
					for _, p in sgs.qlist(use.to) do
						if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
							do_anim = (p:getArmor() and p:hasArmorEffect(p:getArmor():objectName())) or p:hasSkills("bazhen|linglong|bossmanjia")
							p:addQinggangTag(use.card)
						end
					end
					for _, p in sgs.qlist(use.to) do
						room:setPlayerMark(p,"ban_ur",1)
						room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("god_axe")
	end,
}

if not sgs.Sanguosha:getSkill("god_axeskill") then skills:append(god_axeskill) end

god_axe = sgs.CreateWeapon{
	name = "god_axe",
	class_name = "god_axe",
	suit = sgs.Card_Diamond,
	number = 5,
	range = 4,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("god_axeskill")
		room:getThread():addTriggerSkill(skill)
	end
}

god_axe:setParent(extension)

sgs.LoadTranslationTable{
	["god_axe"] = "刑天破軍斧",
	[":god_axe"] = "你的出牌階段內，當你使用牌指定唯一目標後，你可以棄置2張牌，令其本回合內無法使用或打出牌，且防具失效。",
	["@god_axe"] = "你可以棄置2張牌，令其本回合內無法使用或打出牌，且防具失效。",
}


--鸞鳳和鳴劍 武器 攻擊範圍3
--你使用的【雷殺】或【火殺】指定目標後，可令對方選擇棄置一張牌或令你摸一張牌
--god_harmony_sword
god_harmony_swordskill = sgs.CreateTriggerSkill{
	name = "god_harmony_swordskill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (use.card:isKindOf("FireSlash") or use.card:isKindOf("ThunderSlash")) then
				if room:askForSkillInvoke(player,"god_harmony_sword",data) then
					for _, p in sgs.qlist(use.to) do
						if not room:askForCard(p,".|.|.|hand", "god_harmony_sword-card:"..player:objectName(), data, sgs.Card_MethodDiscard) then
							player:drawCards(1)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("god_harmony_sword")
	end,
}

if not sgs.Sanguosha:getSkill("god_harmony_swordskill") then skills:append(god_harmony_swordskill) end

god_harmony_sword = sgs.CreateWeapon{
	name = "god_harmony_sword",
	class_name = "god_harmony_sword",
	suit = sgs.Card_Diamond,
	number = 5,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("god_harmony_swordskill")
		room:getThread():addTriggerSkill(skill)
	end
}

god_harmony_sword:setParent(extension)

sgs.LoadTranslationTable{
	["god_harmony_sword"] = "鸞鳳和鳴劍",
	[":god_harmony_sword"] = "你使用的【雷殺】或【火殺】指定目標後，可令對方選擇棄置一張牌或令你摸一張牌",
	["god_harmony_sword-card"] = "%src 發動了【鸞鳳和鳴劍】效果，你須棄置一張手牌，或令 %src 摸一張牌",
}


--七彩神鹿 坐騎 -1馬
--鎖定技，你造成的屬性傷害+1

god_deerSkill = sgs.CreateTriggerSkill{
	name = "god_deerSkill" ,
	events = {sgs.DamageCaused} ,
	frequency = sgs.Skill_Compulsory,
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or (not damage.by_user) then return false end
				if damage.nature ~= sgs.DamageStruct_Normal then
					damage.damage = damage.damage + 1
					local msg = sgs.LogMessage()
						msg.type = "#GodDeer"
						msg.from = player
						msg.to:append(damage.to)
						msg.arg = tostring(damage.damage - 1)
						msg.arg2 = tostring(damage.damage)
						room:sendLog(msg)	
					data:setValue(damage)
				end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getOffensiveHorse() and target:getOffensiveHorse():objectName() == "god_deer"
	end,
}
if not sgs.Sanguosha:getSkill("god_deerSkill") then skills:append(god_deerSkill) end

local god_deer = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Spade, 5)
god_deer:setObjectName("god_deer")
god_deer:setParent(extension)

sgs.LoadTranslationTable{
	["god_deer"] = "七彩神鹿",
	[":god_deer"] = "鎖定技，你造成的屬性傷害+1",
	["god_deerSkill"] = "七彩神鹿",
	["#GodDeer"] = "%from 的裝備 “<font color=\"yellow\"><b>七彩神鹿</b></font>”被觸發，對 %to 造成傷害由 %arg 點增加到 %arg2 點",
}

--撒豆成兵
god_nihilo = sgs.CreateTrickCard{
	name = "god_nihilo",
	class_name = "god_nihilo",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Heart,
	number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() == sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			local n = math.min(effect.to:getMaxHp(),5)
			if effect.to:getKingdom() == "tan" or effect.to:getKingdom() == "god" then
				effect.to:drawCards(n)
			else
				local n = n - effect.to:getHandcardNum()
				if n > 0 then
					effect.to:drawCards(n)
				end
			end
		end
	end
}
addcard = function(create_card, snn)
	local n = #snn
	for i=1, n, 2 do
		local tcard = create_card:clone()
		tcard:setSuit(snn[i])
		tcard:setNumber(snn[i+1])
		tcard:setParent(extension)
	end
end
--大量增加卡牌的方法 addcard(xxx ,{suit, number}) 
addcard(god_nihilo ,{sgs.Card_Heart, 7, sgs.Card_Heart, 8,sgs.Card_Heart, 9,sgs.Card_Heart, 11,})

sgs.LoadTranslationTable{
	["god_nihilo"] = "撒豆成兵",
	[":god_nihilo"] = "錦囊牌<br /><b>時機</b>：出牌階段<br /><b>目標</b>：包括你在內的一名角色<br /><b>效果</b>：若勢力為“神”，摸X張牌，否則將手牌補至X張。（X為你的體力上限）",
}
--移花接木
god_flower = sgs.CreateTrickCard{
	name = "god_flower",
	class_name = "god_flower",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return (#targets == 0)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local tiger = effect.to
		local source = effect.from
		local luanwu_targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(tiger)) do
			if p:inMyAttackRange(tiger) and tiger:canSlash(p, nil, false) then
				luanwu_targets:append(p)
			end
		end
		if luanwu_targets:length() == 0 or (not room:askForUseSlashTo(tiger, luanwu_targets, "@god_flower")) then
			local dummy = room:askForExchange(tiger, "god_flower", 2, 2, true,"god_flower")
			room:moveCardTo(dummy, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, tiger:objectName(), source:objectName(), self:objectName(), ""))
		end
	end
}

god_flower:setParent(extension)
--大量增加卡牌的方法 addcard(xxx ,{suit, number}) 
addcard(god_flower ,{sgs.Card_Club, 12, sgs.Card_Club, 13})

sgs.LoadTranslationTable{
	["god_flower"] = "移花接木",
	[":god_flower"] = "錦囊牌<br /><b>時機</b>：出牌階段<br /><b>目標</b>：一名其他角色<br /><b >效果</b>：目標角色需使用【殺】，否則交給你兩張牌。",
	["@god_flower"] = "請使用【殺】，否則交給使用者兩張牌。", 
}


--文和亂武卡牌

--[[
on_use = function(self, room, source, targets)
	local players = room:getOtherPlayers(source)
	for _,p in sgs.qlist(players) do
		if p:isAlive() then
			room:cardEffect(self, source, p)
		end
		room:getThread():delay()
	end
end,
]]--

--文和亂武
wenholuanwu = sgs.CreateTrickCard{
	name = "wenholuanwu",
	class_name = "wenholuanwu",
	target_fixed = false,
	--target_fixed = true,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 10,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() == sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		--for _, target in ipairs(targets) do
			room:cardEffect(self, source, source)
		--end
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local players = room:getOtherPlayers(effect.from)
		for _,p in sgs.qlist(players) do
			if p:isAlive() then
				local players = room:getOtherPlayers(p)
				local distance_list = sgs.IntList()
				local nearest = 1000
				for _,player in sgs.qlist(players) do
					local distance = p:distanceTo(player)
					distance_list:append(distance)
					nearest = math.min(nearest, distance)
				end
				local luanwu_targets = sgs.SPlayerList()
				for i = 0, distance_list:length() - 1, 1 do
					if distance_list:at(i) == nearest and p:canSlash(players:at(i), nil, false) then
						luanwu_targets:append(players:at(i))
					end
				end
				if luanwu_targets:length() == 0 or not room:askForUseSlashTo(p, luanwu_targets, "@luanwu-slash") then
					room:loseHp(p)
				end
				room:getThread():delay()
			end
		end
		--local thread = room:getThread()
		--thread:trigger(sgs.CardFinished, room, effect.from, data)
	end
}
wenholuanwu:setParent(extension)

addcard = function(create_card, snn)
	local n = #snn
	for i=1, n, 2 do
		local tcard = create_card:clone()
		tcard:setSuit(snn[i])
		tcard:setNumber(snn[i+1])
		tcard:setParent(extension)
	end
end
--大量增加卡牌的方法 addcard(xxx ,{suit, number}) 
addcard(wenholuanwu,{sgs.Card_Club, 4})

sgs.LoadTranslationTable{
	["wenholuanwu"] = "文和亂武",
	[":wenholuanwu"] = "出牌階段，對你使用。除你以外的所有其他角色必須對與他距離最近的一名角色出【殺】，否則失去1點體力。",
}


--【斗轉星移】出牌階段，對一名其他角色使用。隨機分配你和其的體力（至少為1且無法超出上限）。
douzhuanxingyi = sgs.CreateTrickCard{
	name = "douzhuanxingyi",
	class_name = "douzhuanxingyi",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Diamond,
	number = 5,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local tiger = effect.to
		local source = effect.from
		local n1 = 1
		local n2 = 1
		local nall = source:getHp() + tiger:getHp() - 2
		for i = 1,nall,1 do 
			if math.random(1,2) == 1 then
				if n1 < source:getMaxHp() then
					n1 = n1 + 1
				else
					n2 = n2 + 1
				end
			else
				if n2 < tiger:getMaxHp() then
					n2 = n2 + 1
				else
					n1 = n1 + 1
				end
			end
		end
		room:setPlayerProperty(source, "hp", sgs.QVariant(n1))
		room:setPlayerProperty(tiger, "hp", sgs.QVariant(n2))
	end
}

douzhuanxingyi:setParent(extension)

addcard(douzhuanxingyi,{sgs.Card_Heart, 1})

sgs.LoadTranslationTable{
	["douzhuanxingyi"] = "斗轉星移",
	[":douzhuanxingyi"] = "出牌階段，對一名其他角色使用。隨機分配你和其的體力（至少為1且無法超出上限）。", 
}

--【偷梁換柱】出牌階段，對你使用。隨機分配所有角色裝備區的牌。
toulianghuanzhu = sgs.CreateTrickCard{
	name = "toulianghuanzhu",
	class_name = "toulianghuanzhu",
--	target_fixed = false,
	target_fixed = true,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 11,
	subtype = "single_target_trick",
--	filter = function(self, targets, to_select)
--		return (#targets == 0) and to_select:objectName() == sgs.Self:objectName()
--	end,
	on_use = function(self, room, source, targets)
		room:cardEffect(self, source, source)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local tiger = effect.to
		local source = effect.from

		local players0 = room:getAlivePlayers()
		local players1 = room:getAlivePlayers()
		local players2 = room:getAlivePlayers()
		local players3 = room:getAlivePlayers()
		local players4 = room:getAlivePlayers()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getWeapon() then
				local q
				q = players0:at(math.random(1, players0:length())-1)
				if p:objectName() ~= q:objectName() then
					room:setPlayerMark(p,"toulianghuanzhu0getout",1)
					room:setPlayerMark(q,"toulianghuanzhu"..p:getWeapon():getEffectiveId(),1)
				end
				players0:removeOne(q)
			elseif p:getArmor() then
				local q
				q = players1:at(math.random(1, players1:length())-1)
				if p:objectName() ~= q:objectName() then
					room:setPlayerMark(p,"toulianghuanzhu1getout",1)
					room:setPlayerMark(q,"toulianghuanzhu"..p:getArmor():getEffectiveId(),1)
				end
				players1:removeOne(q)
			elseif p:getDefensiveHorse() then
				local q
				q = players2:at(math.random(1, players2:length())-1)
				if p:objectName() ~= q:objectName() then
					room:setPlayerMark(p,"toulianghuanzhu2getout",1)
					room:setPlayerMark(q,"toulianghuanzhu"..p:getDefensiveHorse():getEffectiveId(),1)
				end
				players2:removeOne(q)
			elseif p:getOffensiveHorse() then
				local q
				q = players3:at(math.random(1, players3:length())-1)
				if p:objectName() ~= q:objectName() then
					room:setPlayerMark(p,"toulianghuanzhu3getout",1)
					room:setPlayerMark(q,"toulianghuanzhu"..p:getOffensiveHorse():getEffectiveId(),1)
				end
				players3:removeOne(q)
			elseif p:getTreasure() then
				local q
				q = players4:at(math.random(1, players4:length())-1)
				if p:objectName() ~= q:objectName() then
					room:setPlayerMark(p,"toulianghuanzhu4getout",1)
					room:setPlayerMark(q,"toulianghuanzhu"..p:getTreasure():getEffectiveId(),1)
				end
				players4:removeOne(q)
			end
		end
		local players0 = nil
		local players1 = nil
		local players2 = nil
		local players3 = nil
		local players4 = nil
		room:getThread():delay()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			for _, mark in sgs.list(p:getMarkNames()) do
				if string.find(mark, "toulianghuanzhu0getout") and p:getMark(mark) > 0 then
					room:moveCardTo(p:getWeapon(), nil, sgs.Player_DiscardPile,false)
				end
				if string.find(mark, "toulianghuanzhu1getout") and p:getMark(mark) > 0 then
					room:moveCardTo(p:getArmor(), nil, sgs.Player_DiscardPile,false)
				end
				if string.find(mark, "toulianghuanzhu2getout") and p:getMark(mark) > 0 then
					room:moveCardTo(p:getDefensiveHorse(), nil, sgs.Player_DiscardPile,false)
				end
				if string.find(mark, "toulianghuanzhu3getout") and p:getMark(mark) > 0 then
					room:moveCardTo(p:getOffensiveHorse(), nil, sgs.Player_DiscardPile,false)
				end
				if string.find(mark, "toulianghuanzhu4getout") and p:getMark(mark) > 0 then
					room:moveCardTo(p:getTreasure(), nil, sgs.Player_DiscardPile,false)
				end
			end
		end
		for _, id in sgs.qlist(room:getDiscardPile()) do
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				local card = sgs.Sanguosha:getCard(id)
				if p:getMark("toulianghuanzhu"..card:getEffectiveId()) > 0 then
					room:moveCardTo(card, p, sgs.Player_PlaceEquip,false)
				end
			end
		end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			for _, mark in sgs.list(p:getMarkNames()) do
				if string.find(mark, "toulianghuanzhu") and p:getMark(mark) > 0 then
					room:setPlayerMark(p,mark,0)
				end
			end
		end
		local thread = room:getThread()
		thread:trigger(sgs.CardFinished, room, effect.from, data)
	end,
}
toulianghuanzhu:setParent(extension)

addcard(toulianghuanzhu,{sgs.Card_Club, 12,sgs.Card_Club, 13,sgs.Card_Spade, 13})

sgs.LoadTranslationTable{
	["toulianghuanzhu"] = "偷梁換柱",
	[":toulianghuanzhu"] = "出牌階段，對你使用。隨機分配所有角色裝備區的牌。",
}

--【李代桃僵】出牌階段，對一名其他角色使用。隨機分配你和其的手牌。
lidaitaojiang = sgs.CreateTrickCard{
	name = "lidaitaojiang",
	class_name = "lidaitaojiang",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Heart,
	number = 1,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local tiger = effect.to
		local source = effect.from
		local ids = sgs.IntList()
		local ids2 = sgs.IntList()
		if not source:isKongcheng() then
			for _, card in sgs.qlist(source:getHandcards()) do 
				if math.random(1,2) == 1 then
					--ids:append(card:getEffectiveId())
				else
					ids2:append(card:getEffectiveId())
				end
			end
		end
		if not tiger:isKongcheng() then
			for _, card in sgs.qlist(tiger:getHandcards()) do 
				if math.random(1,2) == 1 then
					ids:append(card:getEffectiveId())
				else
					--ids2:append(card:getEffectiveId())
				end
			end
		end
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = source
		move.to_place = sgs.Player_PlaceHand
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, tiger:objectName(), source:objectName(), "sk_cangshu","")
		room:moveCardsAtomic(move, true)

		local move = sgs.CardsMoveStruct()
		move.card_ids = ids2
		move.to = tiger
		move.to_place = sgs.Player_PlaceHand
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), tiger:objectName(), "sk_cangshu","")
		room:moveCardsAtomic(move, true)
	end
}

lidaitaojiang:setParent(extension)

addcard(lidaitaojiang,{sgs.Card_Heart, 13})

sgs.LoadTranslationTable{
	["lidaitaojiang"] = "李代桃僵",
	[":lidaitaojiang"] = "出牌階段，對一名其他角色使用。隨機分配你和其的手牌。", 
}

--抗秦
--（錦囊）商鞅變法

shangyangbianfa = sgs.CreateTrickCard{
	name = "shangyangbianfa",
	class_name = "shangyangbianfa",
	target_fixed = false,
	can_recast = false,
	suit = sgs.Card_Spade,
	number = 7,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			if effect.to:isAlive() then
				local n = math.random(1,2)
				if effect.to:getHp() <= n then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|black"
					judge.play_animation = false
					judge.reason = "shangyangbianfa"
					judge.who = effect.from
					judge.good = true
					room:judge(judge)
					--if judge:isGood() then
						for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
							room:setPlayerMark(p, "Global_PreventPeach", 1)
						end
					--end
				end
				room:damage(sgs.DamageStruct(self, effect.from:isAlive() and effect.from or nil, effect.to, n))
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "Global_PreventPeach", 0)
				end
			end
		end
	end
}
addcard = function(create_card, snn)
	local n = #snn
	for i=1, n, 2 do
		local tcard = create_card:clone()
		tcard:setSuit(snn[i])
		tcard:setNumber(snn[i+1])
		tcard:setParent(extension)
	end
end
--大量增加卡牌的方法 addcard(xxx ,{suit, number}) 
addcard(shangyangbianfa,{sgs.Card_Spade, 5})
addcard(shangyangbianfa,{sgs.Card_Spade, 9})

shangyangbianfa:setParent(extension)	

--傳國玉璽：出牌階段開始時，你可以從南蠻入侵、萬箭齊發、桃園結義、五穀豐登中選擇一張使用。
DragonSealskill = sgs.CreateTriggerSkill{
	name = "DragonSealskill" ,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local choicelist = {"archery_attack","savage_assault","god_salvation","amazing_grace"}
				local choices = "cancel"
				for _,cando in pairs(choicelist) do
					choices = string.format("%s+%s", cando, choices)
				end
				local choice = room:askForChoice(player, "DragonSealskill", choices)
				local players = sgs.SPlayerList()			

				if choice ~= "cancel" then
					local archery_attack = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if not player:isProhibited(p, archery_attack) then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						archery_attack:setSkillName("DragonSealskill")
						local use = sgs.CardUseStruct()
						use.card = archery_attack
						use.from = player
						for _,p in sgs.qlist(players) do
							use.to:append(p)
						end
						room:useCard(use)
					end				
				end
			end
		end
		
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("DragonSeal")
	end
}

if not sgs.Sanguosha:getSkill("DragonSealskill") then skills:append(DragonSealskill) end

DragonSeal = sgs.CreateTreasure{
	name = "dragon_seal",
	class_name = "DragonSeal",
	suit = sgs.Card_Heart,
	number = 7,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("DragonSealskill")
		room:getThread():addTriggerSkill(skill)
	end
}
DragonSeal:setParent(extension)
--真龍長劍：每回合，你使用的第一張非延時性錦囊無法被無懈可擊抵消。 

DragonSwordskill = sgs.CreateTriggerSkill{
	name = "DragonSwordskill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TrickCardCanceling,sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			if effect.from:getMark("DSTrick-Clear") == 0 and effect.from:getWeapon() then
				if effect.from:getWeapon():isKindOf("DragonSword") then
					SendComLog(self, effect.from)
					return true
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from:getMark("DSTrick-Clear") == 0 and use.card:isNDTrick() then
				room:setPlayerMark(use.from, "DSTrick-Clear", 1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

if not sgs.Sanguosha:getSkill("DragonSwordskill") then skills:append(DragonSwordskill) end

DragonSword = sgs.CreateWeapon{
	name = "dragon_sword",
	class_name = "DragonSword",
	suit = sgs.Card_Heart,
	number = 2,
	range = 4,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("DragonSwordskill")
		room:getThread():addTriggerSkill(skill)
	end
}

DragonSword:setParent(extension)

sgs.LoadTranslationTable{
	["shangyangbianfa"]="商鞅變法",
	[":shangyangbianfa"]="造成隨機1~2點傷害，若該角色進入瀕死狀態，則進行判定，若判定結果為黑色，則該角色本次瀕死狀態無法向其他角色求桃",
	["dragon_seal"]="傳國玉璽",
	[":dragon_seal"]="出牌階段開始時，你可以從南蠻入侵、萬箭齊發、桃園結義、五穀豐登中選擇一張使用。",
	["dragon_sword"]="真龍長劍",
	[":dragon_sword"]="每回合，你使用的第一張非延時性錦囊無法被無懈可擊抵消。",
	["DragonSealskill"] = "傳國玉璽",
	["DragonSwordskill"]="真龍長劍",
}


--手殺專屬錦囊

binglinchengxia = sgs.CreateTrickCard{
	name = "binglinchengxia",
	class_name = "binglinchengxia",
	target_fixed = false,
	can_recast = false,
	subtype = "single_target_trick",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			if effect.to:isAlive() then
				local ids = room:getNCards(4, false)
				local ids2 = sgs.IntList()
				for _,id in sgs.qlist(ids) do
					room:getThread():delay()
					room:showCard(effect.from, id)
					local card = sgs.Sanguosha:getCard(id)
					if card and card:isKindOf("Slash") and not effect.from:isProhibited(effect.to, card) and effect.to:isAlive() then
						room:useCard(sgs.CardUseStruct(card, effect.from, effect.to))
					else
						ids2:append(id)
					end
				end
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(ids2)
				room:throwCard(dummy, nil, nil)
			end
		end
	end
}

binglinchengxia:setParent(extension)

sgs.LoadTranslationTable{
	["binglinchengxia"]="兵臨城下",
	[":binglinchengxia"]="出牌階段，對一名其他角色使用，你亮出牌堆頂的四張牌，然後依次對其使用其中的【殺】，剩餘的牌置入牌堆。",
}


tiaojiyanmei = sgs.CreateTrickCard{
	name = "tiaojiyanmei",
	class_name = "tiaojiyanmei",
	target_fixed = false,
	can_recast = true,
	suit = sgs.Card_Spade,
	number = 6,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			return to_select:objectName() ~= targets[1]:objectName() and to_select:getHandcardNum() ~= targets[1]:getHandcardNum()
		end
	end,

	on_use = function(self, room, source, targets)
		local card_num = 0
		local player_num = 0
		for _, target in ipairs(targets) do
			card_num = card_num + target:getHandcardNum()
			player_num = player_num + 1
		end
		room:setPlayerMark(source,"tiaojiyanmei_card_num" , card_num)
		room:setPlayerMark(source,"tiaojiyanmei_player_num" , player_num)
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
		room:setPlayerMark(source,"tiaojiyanmei_card_num" , 0)
		room:setPlayerMark(source,"tiaojiyanmei_player_num" , 0)

		local can_give = true
		for _,p in pairs(targets) do
			if p:getHandcardNum() ~= targets[1]:getHandcardNum() then
				can_give = false
			end
		end
		if can_give then
			local DiscardPile = room:getDiscardPile()
			local tag = room:getTag("tiaojiyanmei"):toString():split("+")
			room:removeTag("tiaojiyanmei")
			if #tag == 0 then return false end
			local toGainList = sgs.IntList()				
			for _,is in ipairs(tag) do
				if is ~= "" and DiscardPile:contains(tonumber(is)) then
					toGainList:append(tonumber(is))
				end
			end			
			if toGainList:isEmpty() then return false end
			
			local target = room:askForPlayerChosen(source,room:getOtherPlayers(source),self:objectName(),"@tiaojiyanmei-give",true,true)
			if target and target:isAlive() then
				local move3 = sgs.CardsMoveStruct()
				move3.card_ids = toGainList
				move3.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "tiaojiyanmei","")
				move3.to_place = sgs.Player_PlaceHand
				move3.to = target						
				room:moveCardsAtomic(move3, true)
			end
		end

	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local n = effect.from:getMark("tiaojiyanmei_card_num") / effect.from:getMark("tiaojiyanmei_player_num")
		if effect.to:getHandcardNum() > n then
			local cards = room:askForExchange(effect.to, self:objectName(), 1, 1, true, "@tiaojiyanmei")
			room:throwCard(cards, effect.to, effect.to)

			local oldtag = room:getTag("tiaojiyanmei"):toString():split("+")
			local totag = {}
			for _,is in ipairs(oldtag) do
				table.insert(totag,tonumber(is))
			end					
			for _,id in sgs.qlist(cards:getSubcards()) do
				table.insert(totag,card_id)
			end	
			room:setTag("tiaojiyanmei",sgs.QVariant(table.concat(totag,"+")))

		elseif effect.to:getHandcardNum() < n then
			effect.to:drawCards(1)
		end
	end

}
addcard = function(create_card, snn)
	local n = #snn
	for i=1, n, 2 do
		local tcard = create_card:clone()
		tcard:setSuit(snn[i])
		tcard:setNumber(snn[i+1])
		tcard:setParent(extension)
	end
end

sgs.LoadTranslationTable{
	["tiaojiyanmei"]="調劑鹽梅",
	[":tiaojiyanmei"]="出牌階段，對兩名手牌數不均相同的其他角色使用。若目標角色於此牌使用準備工作結束時的手牌數大於此時所"..
"有目標的平均手牌數，其棄置一張牌。若小於則其摸一張牌。此牌使用結束後，若所有目標角色的手牌數均相等，則你可令一名角色獲得"..
"所有因執行此牌效果而棄置的牌。",
	["@tiaojiyanmei"]="請棄置一張牌",
	["@tiaojiyanmei-give"]="你可以將執行此錦囊所棄的牌交給任一角色",
}

--奇正相生

qizhengxiangsheng = sgs.CreateTrickCard{
	name = "qizhengxiangsheng",
	class_name = "qizhengxiangsheng",
	target_fixed = false,
	can_recast = false,
	subtype = "single_target_trick",
	suit = sgs.Card_Spade,
	number = 2,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		if effect.to and effect.from then
			local room = effect.from:getRoom()
			room:setPlayerFlag(effect.to , "qizhengxiangsheng_target")
			local choice = room:askForChoice(effect.from, "qizhengxiangsheng", "qizhengxiangsheng1+qizhengxiangsheng2")
			room:setPlayerFlag(effect.to , "-qizhengxiangsheng_target")

			--神荀彧【天佐】可以先看
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill("tianzuo") then
					room:notifySkillInvoked(p ,"tianzuo")
					room:sendCompulsoryTriggerLog(p, "tianzuo") 
					room:broadcastSkillInvoke("tianzuo")
					if effect.to:objectName() ~= p:objectName() then
						room:showAllCards(effect.to, p)
					end
					room:getThread():delay()
					choice = room:askForChoice(p, "qizhengxiangsheng", "qizhengxiangsheng1+qizhengxiangsheng2")
				end
			end

			local card = room:askForCard(effect.to, "Slash,Jink", "@qizhengxiangsheng", sgs.QVariant(), sgs.Card_MethodNone)
			if card then
				room:showCard(effect.to, card:getEffectiveId())
			end

			ChoiceLog(effect.from, choice, effect.to)
			if choice == "qizhengxiangsheng1" and ((not card) or not card:isKindOf("Slash")) then
				room:damage(sgs.DamageStruct(self, effect.from, effect.to, 1))
			end
			if choice == "qizhengxiangsheng2" and ((not card) or not card:isKindOf("Jink")) then
				if effect.from:canDiscard(effect.to, "he") then
					local id = room:askForCardChosen(effect.from, effect.to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:obtainCard(effect.from, id, true)
				end
			end
		end
	end
}

--大量增加卡牌的方法 addcard(xxx ,{suit, number}) 
addcard(qizhengxiangsheng,{sgs.Card_Club, 3})
addcard(qizhengxiangsheng,{sgs.Card_Club, 5})
addcard(qizhengxiangsheng,{sgs.Card_Club, 7})
addcard(qizhengxiangsheng,{sgs.Card_Club, 9})
addcard(qizhengxiangsheng,{sgs.Card_Spade, 4})
addcard(qizhengxiangsheng,{sgs.Card_Spade, 6})
addcard(qizhengxiangsheng,{sgs.Card_Spade, 8})


sgs.LoadTranslationTable{
["qizhengxiangsheng"] = "奇正相生",
[":qizhengxiangsheng"] = "出牌階段，對一名其他角色使用。你將目標角色標記為「奇兵」或「正兵」（對其他角色不可見）。"
.."然後目標角色可以打出一張【殺】或【閃】。若其是「奇兵」且未打出【殺】，則你對其造成1點傷害；若其是「正兵」且未打出【閃】，則你獲得其一張牌。",
["qizhengxiangsheng1"] = "奇兵",
["qizhengxiangsheng2"] = "正兵",
[":qizhengxiangsheng1"] = "若其未打出【殺】，則你對其造成1點傷害",
[":qizhengxiangsheng2"] = "若其未打出【閃】，則你獲得其一張牌",
["@qizhengxiangsheng"] = "你可以打出一張【殺】或【閃】",
}

--毒戰三國殺用的毒

poison_effect = sgs.CreateTriggerSkill{
	name = "poison_effect",
	global = true,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		local n = 0
		for _, id in sgs.qlist(move.card_ids) do
			if move.open and sgs.Sanguosha:getCard(id):isKindOf("Poison") then
				n = n + 1
			end
		end
		if move.from and player:objectName() == move.from:objectName() and n > 0 then
			room:loseHp(player, n)
		end
	end
}

poison = sgs.CreateBasicCard{
	name = "poison",
	class_name = "poison",
	target_fixed = true,
	can_recast = false,
	suit = sgs.Card_Diamond,
	number = 6,
	available = function(self, player)
		return true
	end,
	on_effect = function(self, effect)
	end,
}


if not sgs.Sanguosha:getSkill("poison_effect") then skills:append(poison_effect) end

sgs.LoadTranslationTable{
	["poison"] = "毒",
	["poison_effect"]="毒",
	[":poison"] = "基本牌，若該牌正面朝上離開你的手牌區，則你需要失去1點體力",
}

sgs.Sanguosha:addSkills(skills)

return {extension, extension_god}

