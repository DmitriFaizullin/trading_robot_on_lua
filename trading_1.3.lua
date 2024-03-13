function OnInit(script_path)
	data = {}
	data.MaxPosition = 1
	data.TekGod = 2
	id = 0
	ispolnenie = 0
	ispolneno_lotov = 0
	dofile("E:\\Program\\Lua\\trading_1.3\\setting.lua") -- взять из файла настроечную инф.
	InsertTable()
	LogFile = io.open("E:\\Program\\Lua\\trading_1.3\\log.txt", "a") -- открыть log.txt для дозаписи
	LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Запуск программы" .. "\n")
end
function ZapPokFile(tab, str)
	local file = io.open("E:\\Program\\Lua\\trading_1.3\\" .. str, "w")
	local ind_tab = {}
	for key,v in pairs(tab) do
		table.insert(ind_tab,key)
	end
	table.sort(ind_tab)
	for key,v in pairs(ind_tab) do
		file:write(v .. " = " .. tostring(tab[v]) .. "\n")
		--file:write(key .. " = " .. tostring(v) .. "\n")
	end
	file:close()
end
function GetNameOption() -- определяет имя опциона при замене на опцион с текущей датой экспирации
	-- определить опцион замены для продажи
	if data.OptNameZamenaSell == nil then
		data.GetNameOption = false
		local StrikeTekSell = getParamEx("SPBOPT", data.OptNameTekSell, "STRIKE").param_value
		local StrikeZamenaSell = StrikeTekSell + (2500 * data.FutPosTek / math.abs(data.FutPosTek)) .. ""
		StrikeZamenaSell = StrikeZamenaSell:match("%d+")
		local DtmdTekSell = getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE") -- взять параметр количество дней до экспирации текущего опциона	
		if DtmdTekSell.result == "1" then -- если параметр найден	
			SetCell(id, 5, 4, DtmdTekSell.param_image)
			local DtmdZamenaSell = nil
			local NameZamenaSell = nil
			if data.FutPosTek > 0 then -- если позиция по фьючерсу long то опционы продажи Call
				MonthListSell = {"A","B","C","D","E","F","G","H","I","J","K","L"} -- список шифров месяцев опционов Call
			else -- если позиция по фьючерсу short то опционы Put
				if data.FutPosTek < 0 then -- если позиция по фьючерсу short то опционы продажи Put
					MonthListSell = {"M","N","O","P","Q","R","S","T","U","V","W","X"} -- список шифров месяцев опционов Put
				end			
			end
			for _, M in pairs(MonthListSell) do -- список шифров недели месяца для имени опциона
				for _, W in pairs{"A","B","D","E",""} do
					NameZamenaSell = "RI" .. StrikeZamenaSell .. "B" .. M .. data.TekGod .. W -- собрать имя опциона
					DtmdZamenaSell = getParamEx("SPBOPT", NameZamenaSell, "DAYS_TO_MAT_DATE") -- взять параметр количество дней до экспирации для опциона замены
					if DtmdZamenaSell.result == "1" then
						if DtmdTekSell.param_value == DtmdZamenaSell.param_value then
							data.OptNameZamenaSell = NameZamenaSell -- имя найдено
							data.UrovenZameni = StrikeTekSell
							SetCell(id, 7, 2, data.OptNameZamenaSell)
							SetCell(id, 7, 3, getParamEx("SPBOPT", data.OptNameZamenaSell, "BID").param_image)
							SetCell(id, 7, 4, DtmdZamenaSell.param_image)
							SetCell(id, 1, 3, getParamEx("SPBOPT", data.OptNameTekSell, "STRIKE").param_image)
							data.GetNameOption = true
							goto _1_GetNameOption
						end
					end					
				end
			end
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найден опцион замены для продажи(ф-я GetNameOption)" .. "\n")
			SetCell(id, 7, 6, "Не найден")
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найден параметр Dtmd_Tek текущего опциона, поиск замены (ф-я GetNameOption)" .. "\n")
			SetCell(id, 7, 6, "Не найден параметр DtmdTekSell")
		end
	end
	
	::  _1_GetNameOption ::
	
	-- определить опцион перехода для продажи
	if data.OptNamePerehodSell == "Нет перехода" then
		SetCell(id, 8, 2, data.OptNamePerehodSell)
	else		
		data.GetNameOption = false
		if getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE").result == "1" then -- если параметр количество дней до экспирации текущего опциона найден	
			if getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE").param_value+0 == 0 then -- если последний день обращения текущего опциона, определить опцион перехода
				local StrikePerehodSell = nil
				local NamePerehodSell = nil
				local DtmdPerehodSell = nil
				data.OptNamePerehodSell = nil
				
				if data.FutPosTek > 0 then -- если позиция по фьючерсу long то опционы продажи Call
					StrikePerehodSell = math.ceil((data.FutPrice + 3750)/2500) * 2500 -- отступ при переходе 3750
					MonthListSell = {"A","B","C","D","E","F","G","H","I","J","K","L"} -- список шифров месяцев опционов Call
				else -- если позиция по фьючерсу short то опционы Put
					if data.FutPosTek < 0 then -- если позиция по фьючерсу short то опционы продажи Put
						StrikePerehodSell = math.floor((data.FutPrice - 3750)/2500) * 2500 -- отступ при переходе 3750
						MonthListSell = {"M","N","O","P","Q","R","S","T","U","V","W","X"} -- список шифров месяцев опционов Put
					end			
				end
				
				-- !!! ИСПРАВИТЬ ЧТОБЫ ПРОЛИСТЫВАЛОСЬ ОДИН РАЗ ДЛЯ ПОИСКА ОКОНЧАНИЯ
				for _, M in pairs(MonthListSell) do -- список шифров недели месяца для имени опциона
					for _, W in pairs{"A","B","D","E",""} do
						NamePerehodSell = "RI" .. StrikePerehodSell .. "B" .. M .. data.TekGod .. W -- собрать имя опциона
						DtmdPerehodSell = getParamEx("SPBOPT", NamePerehodSell, "DAYS_TO_MAT_DATE") -- взять параметр количество дней до экспирации для опциона перехода
						if DtmdPerehodSell.result == "1" then -- если параметр найден
							if DtmdPerehodSell.param_value+0 >= 6 and DtmdPerehodSell.param_value+0 <= 8 then -- если дата экспирации 7 дней +- 1 день
								data.OptNamePerehodSell = NamePerehodSell -- имя найдено
								SetCell(id, 8, 2, data.OptNamePerehodSell)
								SetCell(id, 8, 3, getParamEx("SPBOPT", data.OptNamePerehodSell, "BID").param_image)
								SetCell(id, 8, 4, getParamEx("SPBOPT", data.OptNamePerehodSell, "DAYS_TO_MAT_DATE").param_image)
								data.GetNameOption = true
								goto _2_GetNameOption
							end
						end
					end
				end
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найден опцион перехода для продажи (ф-я GetNameOption)" .. "\n")
				SetCell(id, 8, 6, "Не найден")
			else
				data.OptNamePerehodSell = "Нет перехода"
				SetCell(id, 8, 2, data.OptNamePerehodSell)
				data.GetNameOption = true
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найден параметр Dtmd_Tek текущего опциона (продажа), поиск перехода (ф-я GetNameOption)" .. "\n")
			SetCell(id, 8, 6, "Не найден параметр Dtmd_Tek")
		end
	end
	
	::  _2_GetNameOption ::
	
	-- определить опцион перехода для покупки
	if data.OptNamePerehodBuy == "Нет перехода" then
		SetCell(id, 9, 2, data.OptNamePerehodBuy)
	else		
		data.GetNameOption = false
		if getParamEx("SPBOPT", data.OptNameTekBuy, "DAYS_TO_MAT_DATE").result == "1" then -- если параметр количество дней до экспирации текущего опциона найден	
			if getParamEx("SPBOPT", data.OptNameTekBuy, "DAYS_TO_MAT_DATE").param_value+0 == 0 then -- если последний день обращения текущего опциона, определить опцион перехода
				local StrikePerehodBuy = nil
				local NamePerehodBuy = nil
				local DtmdPerehodBuy = nil
				data.OptNamePerehodBuy = nil
				if data.FutPosTek > 0 then -- если позиция по фьючерсу long то опционы Put
					StrikePerehodBuy = (math.ceil((data.FutPrice + 3750)/2500) * 2500) - 7500 -- страйк покупаемого опциона на 7500 в другую сторону, тип противоположный проданному
					MonthListBuy = {"M","N","O","P","Q","R","S","T","U","V","W","X"} -- список шифров месяцев опционов Put
				else -- если позиция по фьючерсу short то опционы Put
					if data.FutPosTek < 0 then -- если позиция по фьючерсу short то опционы Call
						StrikePerehodBuy = (math.floor((data.FutPrice - 3750)/2500) * 2500) + 7500 -- страйк покупаемого опциона на 7500 в другую сторону, тип противоположный проданному
						MonthListBuy = {"A","B","C","D","E","F","G","H","I","J","K","L"} -- список шифров месяцев опционов Call
					end			
				end
				-- !!! ИСПРАВИТЬ ЧТОБЫ ПРОЛИСТЫВАЛОСЬ ОДИН РАЗ ДЛЯ ПОИСКА ОКОНЧАНИЯ
				for _, M in pairs(MonthListBuy) do -- список шифров недели месяца для имени опциона
					for _, W in pairs{"A","B","D","E",""} do
						NamePerehodBuy = "RI" .. StrikePerehodBuy .. "B" .. M .. data.TekGod .. W -- собрать имя опциона
						DtmdPerehodBuy = getParamEx("SPBOPT", NamePerehodBuy, "DAYS_TO_MAT_DATE") -- взять параметр количество дней до экспирации для опциона перехода
						if DtmdPerehodBuy.result == "1" then -- если параметр найден
							if DtmdPerehodBuy.param_value+0 >= 6 and DtmdPerehodBuy.param_value+0 <= 8 then -- если дата экспирации 7 дней +- 1 день
								data.OptNamePerehodBuy = NamePerehodBuy -- имя найдено
								SetCell(id, 9, 2, data.OptNamePerehodBuy)
								SetCell(id, 9, 3, getParamEx("SPBOPT", data.OptNamePerehodBuy, "OFFER").param_image)
								SetCell(id, 9, 4, getParamEx("SPBOPT", data.OptNamePerehodBuy, "DAYS_TO_MAT_DATE").param_image)
								data.GetNameOption = true
								return
							end
						end
					end
				end
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найден опцион перехода для покупки (ф-я GetNameOption)" .. "\n")
				SetCell(id, 9, 6, "Не найден")
			else
				data.OptNamePerehodBuy = "Нет перехода"
				SetCell(id, 9, 2, data.OptNamePerehodBuy)
				data.GetNameOption = true
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найден параметр Dtmd_Tek текущего опциона (покупка), поиск перехода (ф-я GetNameOption)" .. "\n")
			SetCell(id, 9, 6, "Не найден параметр Dtmd_Tek")
		end
	end
end

function PositionTest()
	local tab
	data.PositionTest = false
	-- проверка позиции по фьючерсу
	if data.FutNameTek ~= nil then
		SetCell(id, 4, 2, data.FutNameTek)
		tab = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.FutNameTek, 0)
		if tab ~= nil then
			data.FutPosTek = tab.totalnet
			SetCell(id, 4, 3, getParamEx("SPBFUT", data.FutNameTek, "LAST").param_image)
			SetCell(id, 4, 4, getParamEx("SPBFUT", data.FutNameTek, "DAYS_TO_MAT_DATE").param_image)
			SetCell(id, 4, 5, data.FutPosTek .. "")
			if math.abs(data.FutPosTek) ~= data.MaxPosition then
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция по фьючерсу (ф-я PositionTest())" .. "\n")
				SetCell(id, 4, 6, "Некорректная позиция")
			else
				data.PositionTest = true
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция по фьючерсу (ф-я PositionTest())" .. "\n")
			SetCell(id, 4, 6, "Некорректная позиция")
		end
	else
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найдено имя фьючерса (ф-я PositionTest())" .. "\n")
		SetCell(id, 6, 6, "Не найдено имя")
	end
	
	-- проверка позиции по опциону в направлении фьючерса (проданый)
	if data.OptNameTekSell ~= nil then
		SetCell(id, 5, 2, data.OptNameTekSell)
		tab = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekSell, 0)
		if tab ~= nil then
			data.OptPosTekSell = tab.totalnet
			SetCell(id, 5, 3, getParamEx("SPBOPT", data.OptNameTekSell, "OFFER").param_image)
			SetCell(id, 5, 4, getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE").param_image)
			SetCell(id, 5, 5, data.OptPosTekSell .. "")
			if data.OptPosTekSell ~= -data.MaxPosition then
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция по текущему проданному опциону (ф-я PositionTest())" .. "\n")
				SetCell(id, 5, 6, "Некорректная позиция")
			else
				data.PositionTest = true
			end				
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция по текущему проданному опциону (ф-я PositionTest())" .. "\n")
			SetCell(id, 5, 6, "Некорректная позиция")
		end
	else
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найдено имя текущего проданного опциона (ф-я PositionTest())" .. "\n")
		SetCell(id, 5, 6, "Не найдено имя")
	end
	
	-- проверка позиции по опциону против фьючерса (купленый)
	if data.OptNameTekBuy ~= nil then
		SetCell(id, 6, 2, data.OptNameTekBuy)
		tab = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekBuy, 0)
		if tab ~= nil then
			data.OptPosTekBuy = tab.totalnet
			SetCell(id, 6, 3, getParamEx("SPBOPT", data.OptNameTekBuy, "BID").param_image)
			SetCell(id, 6, 4, getParamEx("SPBOPT", data.OptNameTekBuy, "DAYS_TO_MAT_DATE").param_image)
			SetCell(id, 6, 5, data.OptPosTekBuy .. "")
			if data.OptPosTekBuy ~= data.MaxPosition then
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция по текущему купленному опциону (ф-я PositionTest())" .. "\n")
				SetCell(id, 6, 6, "Некорректная позиция")
			else
				data.PositionTest = true
			end				
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция по текущему купленному опциону (ф-я PositionTest())" .. "\n")
			SetCell(id, 6, 6, "Некорректная позиция")
		end
	else
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Не найдено имя текущего купленного опциона (ф-я PositionTest())" .. "\n")
		SetCell(id, 6, 6, "Не найдено имя")
	end
end

function SessionTest()
	if getInfoParam("SERVERTIME") ~= "" then
		local TradingStatus = getParamEx("SPBFUT", data.FutNameTek, "TRADINGSTATUS")
		if TradingStatus.result == "1" then
			if TradingStatus.param_value+0 == 1 then -- сессия открыта
				local MonStartTime = getParamEx("SPBFUT", data.FutNameTek, "MONSTARTTIME") -- время открытия утренней сессии
				local EnvStartTime = getParamEx("SPBFUT", data.FutNameTek, "EVNSTARTTIME") -- время открытия вечерней сессии
				local ServerTime = string.gsub(getInfoParam("SERVERTIME"), ":", "")+0
				if MonStartTime.result == "1" then
					if EnvStartTime.result == "1" then
						if ServerTime < MonStartTime.param_value + 200 then
							data.SessionTest = false
							LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза на откритии утренней сессии (ф-я SessionTest())" .. "\n")
							SetWindowCaption(id, " Трейдинг (пауза на откритии утренней сессии)")
						else
							if ServerTime >= EnvStartTime.param_value+0 and  ServerTime < EnvStartTime.param_value + 200 then
								data.SessionTest = false
								LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза на откритии вечерней сессии (ф-я SessionTest())" .. "\n")
								SetWindowCaption(id, " Трейдинг (пауза на откритии вечерней сессии)")
							else
								data.SessionTest = true
								SetWindowCaption(id, " Трейдинг")
							end
						end
					else
						data.SessionTest = false
						LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр EnvStartTime не найден (ф-я SessionTest())" .. "\n")
						SetWindowCaption(id, " Трейдинг (параметр EnvStartTime не найден)")
					end
				else
					data.SessionTest = false
					LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр MonStartTime не найден (ф-я SessionTest())" .. "\n")
					SetWindowCaption(id, " Трейдинг (параметр MonStartTime не найден)")
				end
			else			
				data.SessionTest = false
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Сессия закрыта (ф-я SessionTest())" .. "\n")
				SetWindowCaption(id, " Трейдинг (сессия закрыта)")
			end		
		else
			data.SessionTest = false
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр TradingStatus не найден (ф-я SessionTest())" .. "\n")
			SetWindowCaption(id, " Трейдинг (параметр TradingStatus не найден)")
		end
	else
		data.SessionTest = false
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр ServerTime не найден (ф-я SessionTest())" .. "\n")
		SetWindowCaption(id, " Трейдинг (параметр ServerTime не найден)")
	end			
end

function StrategiTest()
	if data.OptNamePerehodSell ~= "Нет перехода" then -- если определен опцион перехода
		if string.gsub(getInfoParam("SERVERTIME"), ":", "")+0 >= 140000 then -- в 14:00 переход на следующий опцион
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " переход на следующий опцион" .. "\n")
			CloseSellOption() -- закрытие текущего проданного опциона
			CloseBuyOption() -- закрытие текущего купленного опциона
			OpenSellOption(data.OptNamePerehodSell) -- открытие нового проданного опциона
			OpenBuyOption() -- открытие нового купленного опциона
			
			-- поменять имена текущих опционов
			data.OptNameTekSell = data.OptNamePerehodSell
			data.OptNameTekBuy = data.OptNamePerehodBuy
			
			-- переписать файл setting.lua
			local file = io.open("E:\\Program\\Lua\\trading_1.3\\setting.lua", "w")
			file:write("data.FutNameTek = \"" .. data.FutNameTek .. "\"\n")
			file:write("data.OptNameTekSell = \"" .. data.OptNameTekSell .. "\"")
			file:write("data.OptNameTekBuy = \"" .. data.OptNameTekBuy .. "\"")
			file:close()
			
			-- обнулить опционы замены и перехода
			data.OptNamePerehodSell = ""
			data.OptNameZamenaSell = ""
			data.OptNamePerehodBuy = ""
			
			-- определить новые имена замены и перехода
			GetNameOption()
			
			return
		end
	end
end
function CloseSellOption()
	local LogCloseSellOption = io.open("E:\\Program\\Lua\\trading_1.3\\CloseSellOption.txt", "a")
	----------------------------------------
	-- ЗАКРЫТИЕ ТЕКУЩЕГО ПРОДАННОГО ОПЦИОНА
	----------------------------------------
	local Quantity = data.MaxPosition
	local offer = nil
	local bid = nil
	local theorprice = nil
	local totalnet = nil
	local stakan = nil
	local cena_zaiavki = nil
	local kol_lotov_v_rinke = nil
	
	local transaction = {
		TRANS_ID = "1",
		CLASSCODE = "SPBOPT",
		ACCOUNT = "SPBFUT00gqr",
		ACTION = "NEW_ORDER",
		SECCODE = data.OptNameTekSell,
		TYPE = "L",
		QUANTITY = "1"
		OPERATION = "B"
	}
	
	local sch_kontr = data.MaxPosition
	
	
	while true do
		
		
		bid = getParamEx("SPBOPT", data.OptNameTekSell, "BID")
		transaction.PRICE = (bid.param_value + 10) .. ""
		local resultTransaction = sendTransaction(transaction)

		
		
		
		sleep(2000)
	end
end

function OpenSellOption(Option)
	local LogOpenSellOption = io.open("E:\\Program\\Lua\\trading_1.3\\OpenSellOption.txt", "a")
	-----------------------------
	-- ОТКРЫТИЕ НОВОГО ОПЦИОНА
	-----------------------------
	local Quantity = data.MaxPosition * 2
	local offer = nil
	local bid = nil
	local theorprice = nil
	local totalnet = nil
	local stakan = nil
	local cena_zaiavki = nil
	local kol_lotov_v_rinke = nil
	local futuresHolding = nil
	
	local transaction = {
		TRANS_ID = "1",
		CLASSCODE = "SPBOPT",
		ACCOUNT = "SPBFUT00gqr",
		ACTION = "NEW_ORDER",
		SECCODE = Option,
		TYPE = "L",
		OPERATION = "S",
		EXECUTION_CONDITION = "KILL_BALANCE"
	}
	
	while true do
		ispolnenie = 0 -- признак исполнения заявки
		ispolneno_lotov = nil -- исполненное количество в заявке
		
		-- проверка рынка
		offer = getParamEx("SPBOPT", Option, "OFFER")
		bid = getParamEx("SPBOPT", Option, "BID")
		theorprice = getParamEx("SPBOPT", Option, "THEORPRICE")
		
		if offer.result == "1" then
			if bid.result == "1" then
				if theorprice.result == "1" then
					if (offer.param_value - bid.param_value) <= 50 then -- проверка рыночного спреда (спред широкий при низком ликвиде)
						if (offer.param_value - theorprice.param_value) <= 200 then -- сравнение рыночной цены с теоретической (рыночные цены неадекватные при низком ликвиде)
							-- определить текущую позицию по открываемому опциону
							futuresHolding = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", Option, 0)
							if (futuresHolding == nil) or (futuresHolding.totalnet+0 <= 0 and futuresHolding.totalnet+0 > -data.MaxPosition * 2) then
								-- определить количество лотов из стакана
								if IsSubscribed_Level_II_Quotes("SPBOPT", Option) == true then -- проверить заказан ли стакан с сервера
									stakan = getQuoteLevel2("SPBOPT", Option) -- взять стакан
									if stakan.offer_count+0 > 0 then -- проверить количество котировок продажи
										cena_zaiavki = stakan.offer[1].price - 50 -- цена заявки будет: лучшая цена продажи на рынке - 50
										if cena_zaiavki <= 0 then -- если цена получается <= 0, то взять цену 10
											cena_zaiavki = 10
										end
										LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Цена выставляемой заявки = " .. cena_zaiavki .. "\n")
										kol_lotov_v_rinke = 0
										for n = stakan.bid_count, 1, -1 do -- пролистать котировки спроса от самой лучшей цены
											if stakan.bid[n].price+0 >= cena_zaiavki then -- взять весь объем котировок до цены моей заявки
												kol_lotov_v_rinke = kol_lotov_v_rinke + stakan.bid[n].quantity
											else
												break
											end
										end
										LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Количество лотов в рынке = " .. kol_lotov_v_rinke .. "\n")
										if kol_lotov_v_rinke > 0 then -- если есть спрос (заявки на покупку) до цены моей заявки
											-- исправить таблицу для заявки (указать объем и цену)
											transaction.QUANTITY = Quantity .. ""
											transaction.PRICE = cena_zaiavki .. ""
											
											-- ОТПРАВИТЬ ЗАЯВКУ В РЫНОК
											LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Заявка продажа " .. transaction.QUANTITY .. " контрактов по " .. transaction.PRICE .. "\n")
											local resultTransaction = sendTransaction(transaction)
											LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. resultTransaction .. "\n")
											
											-- проверка исполнения заявки
											while true do
												LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза 1 сек." .. "\n")
												sleep(1000) -- пауза 1 секунда
												if ispolnenie == 1 then -- если получен ответ на транзакцию (функция обратного вызова OnTransReply)
													LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Получен ответ от ф-ии OnTransReply" .. "\n")
													if ispolneno_lotov ~= nil then -- если посчитано исполненное количество (функция обратного вызова OnOrder)
														LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Получен ответ от ф-ии OnOrder, исполнено лотов - " .. ispolneno_lotov .. "\n")
														Quantity = Quantity - ispolneno_lotov -- подбить оставшееся количество для заявки
														LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Оставшееся количество - " .. Quantity .. "\n")
														
														-- определить весь ли объем исполнен
														if Quantity == 0 then -- позиция открыта полностью
															Unsubscribe_Level_II_Quotes("SPBOPT", Option) -- закрыть стакан
															LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Позиция по опциону " .. data.OptNameTekSell .. " открыта полностью" .. "\n")
															LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Выход из ф-ии OpenSellOption" .. "\n")
															LogOpenSellOption:close()
															return -- выход из функции
														else
															if Quantity < 0 then -- перебор, дать сообщение
																Unsubscribe_Level_II_Quotes("SPBOPT", Option) -- закрыть стакан
																LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Перебор при закрытии позиции - " .. Quantity .. "\n")
																LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Выход из ф-ии OpenSellOption" .. "\n")
																LogOpenSellOption:close()
																return -- выход из функции
															end
														end
													end
												end
											end
										end
									else
										LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Нет предложения на рынке" .. "\n")
									end
								else
									LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Не заказан стакан по инструменту" .. "\n")
									Subscribe_Level_II_Quotes("SPBOPT", Option) -- заказать стакан
								end
							else
								LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция" .. "\n")
							end
						else
							LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Неадекватная рыночная цена - " .. (offer.param_value - theorprice.param_value) .. "\n")
						end	
					else
						LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Широкий рыночный спред - " .. (offer.param_value - bid.param_value) .. "\n")
					end
				else
					LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр theorprice не найден" .. "\n")
				end
			else
				LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр bid не найден" .. "\n")
			end
		else
			LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр offer не найден" .. "\n")
		end
		LogCloseSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза 2 сек." .. "\n")
		sleep(2000)
	end
end

function CloseBuyOption()
	local LogCloseBuyOption = io.open("E:\\Program\\Lua\\trading_1.3\\CloseBuyOption.txt", "a")
	----------------------------------------
	-- ЗАКРЫТИЕ ТЕКУЩЕГО КУПЛЕННОГО ОПЦИОНА
	----------------------------------------
	local Quantity = data.MaxPosition
	local offer = nil
	local bid = nil
	local theorprice = nil
	local totalnet = nil
	local stakan = nil
	local cena_zaiavki = nil
	local kol_lotov_v_rinke = nil
	
	local transaction = {
		TRANS_ID = "1",
		CLASSCODE = "SPBOPT",
		ACCOUNT = "SPBFUT00gqr",
		ACTION = "NEW_ORDER",
		SECCODE = data.OptNameTekBuy,
		TYPE = "L",
		OPERATION = "S",
		EXECUTION_CONDITION = "KILL_BALANCE"
	}

	while true do
		
		ispolnenie = 0 -- признак исполнения заявки
		ispolneno_lotov = nil -- исполненное количество в заявке
		
		-- проверка рынка
		offer = getParamEx("SPBOPT", data.OptNameTekBuy, "OFFER")
		bid = getParamEx("SPBOPT", data.OptNameTekBuy, "BID")
		theorprice = getParamEx("SPBOPT", data.OptNameTekBuy, "THEORPRICE")
		
		if offer.result == "1" then
			if bid.result == "1" then
				if theorprice.result == "1" then
					if (offer.param_value - bid.param_value) <= 50 then -- проверка рыночного спреда (спред широкий при низком ликвиде)
						if (offer.param_value - theorprice.param_value) <= 200 then -- сравнение рыночной цены с теоретической (рыночные цены неадекватные при низком ликвиде)
							-- определить текущую позицию по закрываемому опциону
							if getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekBuy, 0) ~= nil then
								totalnet = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekBuy, 0).totalnet+0 -- текущая позиция
								if totalnet > 0 then
									-- определить количество лотов из стакана
									if IsSubscribed_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) == true then -- проверить заказан ли стакан с сервера
										stakan = getQuoteLevel2("SPBOPT", data.OptNameTekBuy) -- взять стакан
										if stakan.offer_count+0 > 0 then -- количество котировок продажи
											-- определить цену для своей заявки
											cena_zaiavki = stakan.offer[1].price - 50 -- цена заявки будет: лучшая цена продажи на рынке - 50
											if cena_zaiavki <= 0 then -- если цена получается <= 0, то взять цену 10
												cena_zaiavki = 10
											end
											LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Цена выставляемой заявки = " .. cena_zaiavki .. "\n")
											kol_lotov_v_rinke = 0
											for n = stakan.bid_count, 1, -1 do -- пролистать котировки спроса от самой лучшей цены
												if stakan.bid[n].price+0 >= cena_zaiavki then -- взять весь объем котировок до цены моей заявки
													kol_lotov_v_rinke = kol_lotov_v_rinke + stakan.bid[n].quantity
												else
													break
												end
											end
											LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Количество лотов в рынке = " .. kol_lotov_v_rinke .. "\n")
											if kol_lotov_v_rinke > 0 then -- если есть спрос (заявки на покупки) до цены моей заявки
												-- исправить таблицу для заявки (указать объем и цену)
												transaction.QUANTITY = Quantity .. ""
												transaction.PRICE = cena_zaiavki .. ""
												
												-- ОТПРАВИТЬ ЗАЯВКУ В РЫНОК
												LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Заявка продажа " .. transaction.QUANTITY .. " контрактов по " .. transaction.PRICE .. "\n")
												local resultTransaction = sendTransaction(transaction)
												LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. resultTransaction .. "\n")
												
												-- проверка исполнения заявки
												while true do
													LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза 1 сек." .. "\n")
													sleep(1000) -- пауза 1 секунда
													if ispolnenie == 1 then -- если получен ответ на транзакцию (функция обратного вызова OnTransReply)
														LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Получен ответ от ф-ии OnTransReply" .. "\n")
														if ispolneno_lotov ~= nil then -- если посчитано исполненное количество (функция обратного вызова OnOrder)
															LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Получен ответ от ф-ии OnOrder, исполнено лотов - " .. ispolneno_lotov .. "\n")
															Quantity = Quantity - ispolneno_lotov -- подбить оставшееся количество для заявки
															LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Оставшееся количество - " .. Quantity .. "\n")
															
															-- определить весь ли объем исполнен
															if Quantity == 0 then -- позиция закрыта
																Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) -- закрыть стакан
																LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Позиция по опциону " .. data.OptNameTekBuy .. " закрыта полностью" .. "\n")
																LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Выход из ф-ии CloseBuyOption" .. "\n")
																LogCloseBuyOption:close()
																return -- выход из функции
															else
																if Quantity < 0 then -- перебор, дать сообщение
																	Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) -- закрыть стакан
																	LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Перебор при закрытии позиции - " .. Quantity .. "\n")
																	LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Выход из ф-ии CloseBuyOption" .. "\n")
																	LogCloseBuyOption:close()
																	return -- выход из функции
																end
															end
														else
															LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Не получен ответ от ф-ии OnOrder, исполнено лотов - " .. ispolneno_lotov .. "\n")
														end
													else
														LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Не получен ответ от ф-ии OnTransReply" .. "\n")
													end
												end
											end
										else
											LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Нет спроса на рынке" .. "\n")
										end
									else
										LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Не заказан стакан по инструменту" .. "\n")
										Subscribe_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) -- заказать стакан
									end
								else
									LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция" .. "\n")
								end
							else
								LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Нет данных о позиции" .. "\n")
							end
						else
							LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Неадекватная рыночная цена" .. "\n")
						end	
					else
						LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Широкий рыночный спред" .. "\n")
					end
				else
					LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр theorprice не найден" .. "\n")
				end
			else
				LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр bid не найден" .. "\n")
			end
		else
			LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр offer не найден" .. "\n")
		end
		LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза 2 сек." .. "\n")
		sleep(2000)
	end
end

function OpenBuyOption()
	local LogOpenBuyOption = io.open("E:\\Program\\Lua\\trading_1.3\\OpenBuyOption.txt", "a")
	----------------------------------------
	-- ЗАКРЫТИЕ ТЕКУЩЕГО ПРОДАННОГО ОПЦИОНА
	----------------------------------------
	local Quantity = data.MaxPosition
	local offer = nil
	local bid = nil
	local theorprice = nil
	local totalnet = nil
	local stakan = nil
	local cena_zaiavki = nil
	local kol_lotov_v_rinke = nil
	local futuresHolding = nil
	
	local transaction = {
		TRANS_ID = "1",
		CLASSCODE = "SPBOPT",
		ACCOUNT = "SPBFUT00gqr",
		ACTION = "NEW_ORDER",
		SECCODE = data.OptNamePerehodBuy,
		TYPE = "L",
		OPERATION = "B",
		EXECUTION_CONDITION = "KILL_BALANCE"
	}
	
	while true do
		
		ispolnenie = 0 -- признак исполнения заявки
		ispolneno_lotov = nil -- исполненное количество в заявке
		
		-- проверка рынка
		offer = getParamEx("SPBOPT", data.OptNamePerehodBuy, "OFFER")
		bid = getParamEx("SPBOPT", data.OptNamePerehodBuy, "BID")
		theorprice = getParamEx("SPBOPT", data.OptNamePerehodBuy, "THEORPRICE")
		
		if offer.result == "1" then
			if bid.result == "1" then
				if theorprice.result == "1" then
					if (offer.param_value - bid.param_value) <= 50 then -- проверка рыночного спреда (спред широкий при низком ликвиде)
						if (offer.param_value - theorprice.param_value) <= 200 then -- сравнение рыночной цены с теоретической (рыночные цены неадекватные при низком ликвиде)
							-- определить текущую позицию по закрываемому опциону
							futuresHolding = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNamePerehodBuy, 0)
							if (futuresHolding == nil) or (futuresHolding.totalnet+0 >= 0 and futuresHolding.totalnet+0 < data.MaxPosition) then
								-- определить количество лотов из стакана
								if IsSubscribed_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) == true then -- проверить заказан ли стакан с сервера
									stakan = getQuoteLevel2("SPBOPT", data.OptNamePerehodBuy) -- взять стакан
									if stakan.bid_count+0 > 0 then -- количество котировок покупки
										-- определить цену для своей заявки
										cena_zaiavki = stakan.bid[#stakan.bid].price + 50 -- взять цену самой лучшей котировки на покупку (последняя) прибавить 50 - цена моей заявки
										LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Цена выставляемой заявки = " .. cena_zaiavki .. "\n")
										kol_lotov_v_rinke = 0 -- обнулить kol_lotov_v_rinke для нового подсчета
										for n = 1, stakan.offer_count + 0 do -- пролистать таблицу котировок продажи
											if stakan.offer[n].price+0 <= cena_zaiavki then -- взять весь объем котировок до цены моей заявки
												kol_lotov_v_rinke = kol_lotov_v_rinke + stakan.offer[n].quantity
											else
												break
											end
										end
										LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Количество лотов в рынке = " .. kol_lotov_v_rinke .. "\n")
										if kol_lotov_v_rinke > 0 then -- если есть предложение (заявки на продажу) до цены моей заявки
											-- исправить таблицу для заявки (указать объем и цену)
											transaction.QUANTITY = Quantity .. ""
											transaction.PRICE = cena_zaiavki .. ""
											
											-- ОТПРАВИТЬ ЗАЯВКУ В РЫНОК
											LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Заявка покупка " .. transaction.QUANTITY .. " контрактов по " .. transaction.PRICE .. "\n")
											local resultTransaction = sendTransaction(transaction)
											LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. resultTransaction .. "\n")
												
											-- проверка исполнения заявки
											while true do
												LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза 1 сек." .. "\n")
												sleep(1000) -- пауза 1 секунда
												if ispolnenie == 1 then -- если получен ответ на транзакцию (функция обратного вызова OnTransReply)
													LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Получен ответ от ф-ии OnTransReply" .. "\n")
													if ispolneno_lotov ~= nil then -- если посчитано исполненное количество (функция обратного вызова OnOrder)
														LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Получен ответ от ф-ии OnOrder, исполнено лотов - " .. ispolneno_lotov .. "\n")
														Quantity = Quantity - ispolneno_lotov -- подбить оставшееся количество для заявки
														LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Оставшееся количество - " .. Quantity .. "\n")
														
														-- определить весь ли объем исполнен
														if Quantity == 0 then -- позиция закрыта
															Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) -- закрыть стакан
															LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Позиция по опциону " .. data.OptNamePerehodBuy .. " открыта полностью" .. "\n")
															LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Выход из ф-ии OpenBuyOption" .. "\n")
															LogOpenBuyOption:close()
															return -- выход из функции
														else
															if Quantity < 0 then -- перебор, дать сообщение
																Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) -- закрыть стакан
																LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Перебор при открытии позиции - " .. Quantity .. "\n")
																LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Выход из ф-ии OpenBuyOption" .. "\n")
																LogOpenBuyOption:close()
																return -- выход из функции
															end
														end
													else
														LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Не получен ответ от ф-ии OnOrder, исполнено лотов - " .. ispolneno_lotov .. "\n")
													end
												else
													LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Не получен ответ от ф-ии OnTransReply" .. "\n")
												end
											end
										end
									else
										LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Нет предложения на рынке" .. "\n")
									end
								else
									LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Не заказан стакан по инструменту" .. "\n")
									Subscribe_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) -- заказать стакан
								end
							else
								LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Некорректная позиция" .. "\n")
							end
						else
							LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Неадекватная рыночная цена" .. "\n")
						end	
					else
						LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Широкий рыночный спред" .. "\n")
					end
				else
					LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр theorprice не найден" .. "\n")
				end
			else
				LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр bid не найден" .. "\n")
			end
		else
			LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Параметр offer не найден" .. "\n")
		end
		LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " Пауза 2 сек." .. "\n")
		sleep(2000)
	end
end


function OnTransReply(trans_reply)
	if trans_reply.trans_id == 1 then
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. trans_reply.result_msg .. "(OnTransReply)" .. "\n") -- записать в файл сообщение о транзакции
		if trans_reply.status == 3 then
			ispolnenie = 1
		end
	end	
end

function OnOrder(order)
	if order.trans_id == 1 then
		 -- записать в файл сообщение о заявке
		LogFile:write(os.date("%d.%m.%y %H:%M:%S")) -- дата, время
		LogFile:write(" order.order_num - " .. order.order_num) -- номер заявки
		LogFile:write(" order.sec_code - " .. order.sec_code) -- код инструмента
		LogFile:write(" order.price - " .. order.price) -- цена
		LogFile:write(" order.qty - " .. order.qty) -- кол лотов
		LogFile:write(" order.balance - " .. order.balance) -- остаток
		LogFile:write(" (OnOrder)"  .. "\n")
		ispolneno_lotov = order.qty - order.balance -- исполнено лотов, остальные сняты
	end
end

function InsertTable()
	id = AllocTable()
	AddColumn(id, 1, "", true, QTABLE_STRING_TYPE,15)
	AddColumn(id, 2, "Название", true, QTABLE_INT_TYPE,15)
	AddColumn(id, 3, "Цена", true, QTABLE_INT_TYPE,8)
	AddColumn(id, 4, "Пог.", true, QTABLE_INT_TYPE,5)
	AddColumn(id, 5, "Кол.", true, QTABLE_STRING_TYPE,5)
	AddColumn(id, 6, "Коментарий", true, QTABLE_STRING_TYPE,10)
	CreateWindow(id)
	InsertRow(id, -1)
	InsertRow(id, 2)
	InsertRow(id, 3)
	InsertRow(id, 4)
	InsertRow(id, 5)
	InsertRow(id, 6)
	InsertRow(id, 7)
	InsertRow(id, 8)
	InsertRow(id, 9)
	SetCell(id, 1, 1, "Замена опц")
	SetCell(id, 2, 1, "Открытие фут")
	SetCell(id, 3, 1, "Закрытие фут")
	SetCell(id, 4, 1, "Фьючерс")
	SetCell(id, 5, 1, "Текущий (Sell)")
	SetCell(id, 6, 1, "Текущий (Buy)")
	SetCell(id, 7, 1, "Замена (Sell)")
	SetCell(id, 8, 1, "Переход (Sell)")
	SetCell(id, 9, 1, "Переход (Buy)")
end
function main()
	while(true) do
		if isConnected() == 1 then
			SessionTest()
			if data.SessionTest == true then
				PositionTest()
				if data.PositionTest == true then
					data.FutPrice = 0
					data.FutPrice = getParamEx("SPBFUT", data.FutNameTek, "LAST").param_value+0
					if data.FutPrice > 0 then -- если все проверки пройдены
						GetNameOption()
						if data.GetNameOption == true then
							StrategiTest()
						else
							LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Показатель data.GetNameOption = " .. tostring(data.GetNameOption) .. " ф-я GetNameOption() плохо отработала" .. "\n")
						end
					else
						LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Нет цены фьючерса (ф-я main)" .. "\n")
						SetCell(id, 2, 5, "Нет цены фьючерса")
					end
				else
					LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Показатель data.PositionTest = " .. tostring(data.PositionTest) .. "\n")
				end
			else
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Показатель data.SessionTest = " .. tostring(data.SessionTest) .. "\n")
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " Нет связи" .. "\n")
			SetWindowCaption(id, " Трейдинг (Нет связи)")
		end
		if IsWindowClosed(id) then
			break
		else
			sleep(3000)
		end
	end
end

--окраска таблицы
-- АВТОМАТИЧЕСКИЙ ВХОД В ПОЗИЦИЮ И ВЫХОД ИЗ НЕЕ
-- ВЫСТАВЛЕНИЕ ЗАЯВОК НА ОПЦИОНЫ ДО ДОСТИЖЕНИЯ УРОВНЕЙ
-- В ПОСЛЕДНИЙ ДЕНЬ ОБРАЩЕНИЯ ОПЦИОНОВ ПЕРЕХОДИТЬ СРАЗУ НА СЛЕДУЮЩИЙ ОПЦИОН ПРИ ПРОБИТИИ УРОВНЯ

--[[
	Стратегия
	Два опциона продаются в направлении позиции по фьючерсу.
	Страйк продаваемого опциона определяется: Текущая цена фьючерса +- 3750,
	берется дальний страйк. К этому страйку прибавляется 7500 и покупается
	один опцион в направлении против позиции по фьючерсу.
	Таким обрарзом стоимость проданных и купленных опционов
	друг друга компенсирует.
	Замена опциона на следующий с той же датой
	экспирации при достижении страйка. Переход на опцион со следующей
	датой экспирации по принципу входа в позицию. Купленный опцион не 
	меняется до экспирации.
--]]