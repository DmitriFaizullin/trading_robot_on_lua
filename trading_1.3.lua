function OnInit(script_path)
	data = {}
	data.MaxPosition = 1
	data.TekGod = 2
	id = 0
	ispolnenie = 0
	ispolneno_lotov = 0
	dofile("E:\\Program\\Lua\\trading_1.3\\setting.lua") -- ����� �� ����� ����������� ���.
	InsertTable()
	LogFile = io.open("E:\\Program\\Lua\\trading_1.3\\log.txt", "a") -- ������� log.txt ��� ��������
	LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������ ���������" .. "\n")
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
function GetNameOption() -- ���������� ��� ������� ��� ������ �� ������ � ������� ����� ����������
	-- ���������� ������ ������ ��� �������
	if data.OptNameZamenaSell == nil then
		data.GetNameOption = false
		local StrikeTekSell = getParamEx("SPBOPT", data.OptNameTekSell, "STRIKE").param_value
		local StrikeZamenaSell = StrikeTekSell + (2500 * data.FutPosTek / math.abs(data.FutPosTek)) .. ""
		StrikeZamenaSell = StrikeZamenaSell:match("%d+")
		local DtmdTekSell = getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE") -- ����� �������� ���������� ���� �� ���������� �������� �������	
		if DtmdTekSell.result == "1" then -- ���� �������� ������	
			SetCell(id, 5, 4, DtmdTekSell.param_image)
			local DtmdZamenaSell = nil
			local NameZamenaSell = nil
			if data.FutPosTek > 0 then -- ���� ������� �� �������� long �� ������� ������� Call
				MonthListSell = {"A","B","C","D","E","F","G","H","I","J","K","L"} -- ������ ������ ������� �������� Call
			else -- ���� ������� �� �������� short �� ������� Put
				if data.FutPosTek < 0 then -- ���� ������� �� �������� short �� ������� ������� Put
					MonthListSell = {"M","N","O","P","Q","R","S","T","U","V","W","X"} -- ������ ������ ������� �������� Put
				end			
			end
			for _, M in pairs(MonthListSell) do -- ������ ������ ������ ������ ��� ����� �������
				for _, W in pairs{"A","B","D","E",""} do
					NameZamenaSell = "RI" .. StrikeZamenaSell .. "B" .. M .. data.TekGod .. W -- ������� ��� �������
					DtmdZamenaSell = getParamEx("SPBOPT", NameZamenaSell, "DAYS_TO_MAT_DATE") -- ����� �������� ���������� ���� �� ���������� ��� ������� ������
					if DtmdZamenaSell.result == "1" then
						if DtmdTekSell.param_value == DtmdZamenaSell.param_value then
							data.OptNameZamenaSell = NameZamenaSell -- ��� �������
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
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������ ������ ������ ��� �������(�-� GetNameOption)" .. "\n")
			SetCell(id, 7, 6, "�� ������")
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������ �������� Dtmd_Tek �������� �������, ����� ������ (�-� GetNameOption)" .. "\n")
			SetCell(id, 7, 6, "�� ������ �������� DtmdTekSell")
		end
	end
	
	::  _1_GetNameOption ::
	
	-- ���������� ������ �������� ��� �������
	if data.OptNamePerehodSell == "��� ��������" then
		SetCell(id, 8, 2, data.OptNamePerehodSell)
	else		
		data.GetNameOption = false
		if getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE").result == "1" then -- ���� �������� ���������� ���� �� ���������� �������� ������� ������	
			if getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE").param_value+0 == 0 then -- ���� ��������� ���� ��������� �������� �������, ���������� ������ ��������
				local StrikePerehodSell = nil
				local NamePerehodSell = nil
				local DtmdPerehodSell = nil
				data.OptNamePerehodSell = nil
				
				if data.FutPosTek > 0 then -- ���� ������� �� �������� long �� ������� ������� Call
					StrikePerehodSell = math.ceil((data.FutPrice + 3750)/2500) * 2500 -- ������ ��� �������� 3750
					MonthListSell = {"A","B","C","D","E","F","G","H","I","J","K","L"} -- ������ ������ ������� �������� Call
				else -- ���� ������� �� �������� short �� ������� Put
					if data.FutPosTek < 0 then -- ���� ������� �� �������� short �� ������� ������� Put
						StrikePerehodSell = math.floor((data.FutPrice - 3750)/2500) * 2500 -- ������ ��� �������� 3750
						MonthListSell = {"M","N","O","P","Q","R","S","T","U","V","W","X"} -- ������ ������ ������� �������� Put
					end			
				end
				
				-- !!! ��������� ����� �������������� ���� ��� ��� ������ ���������
				for _, M in pairs(MonthListSell) do -- ������ ������ ������ ������ ��� ����� �������
					for _, W in pairs{"A","B","D","E",""} do
						NamePerehodSell = "RI" .. StrikePerehodSell .. "B" .. M .. data.TekGod .. W -- ������� ��� �������
						DtmdPerehodSell = getParamEx("SPBOPT", NamePerehodSell, "DAYS_TO_MAT_DATE") -- ����� �������� ���������� ���� �� ���������� ��� ������� ��������
						if DtmdPerehodSell.result == "1" then -- ���� �������� ������
							if DtmdPerehodSell.param_value+0 >= 6 and DtmdPerehodSell.param_value+0 <= 8 then -- ���� ���� ���������� 7 ���� +- 1 ����
								data.OptNamePerehodSell = NamePerehodSell -- ��� �������
								SetCell(id, 8, 2, data.OptNamePerehodSell)
								SetCell(id, 8, 3, getParamEx("SPBOPT", data.OptNamePerehodSell, "BID").param_image)
								SetCell(id, 8, 4, getParamEx("SPBOPT", data.OptNamePerehodSell, "DAYS_TO_MAT_DATE").param_image)
								data.GetNameOption = true
								goto _2_GetNameOption
							end
						end
					end
				end
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������ ������ �������� ��� ������� (�-� GetNameOption)" .. "\n")
				SetCell(id, 8, 6, "�� ������")
			else
				data.OptNamePerehodSell = "��� ��������"
				SetCell(id, 8, 2, data.OptNamePerehodSell)
				data.GetNameOption = true
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������ �������� Dtmd_Tek �������� ������� (�������), ����� �������� (�-� GetNameOption)" .. "\n")
			SetCell(id, 8, 6, "�� ������ �������� Dtmd_Tek")
		end
	end
	
	::  _2_GetNameOption ::
	
	-- ���������� ������ �������� ��� �������
	if data.OptNamePerehodBuy == "��� ��������" then
		SetCell(id, 9, 2, data.OptNamePerehodBuy)
	else		
		data.GetNameOption = false
		if getParamEx("SPBOPT", data.OptNameTekBuy, "DAYS_TO_MAT_DATE").result == "1" then -- ���� �������� ���������� ���� �� ���������� �������� ������� ������	
			if getParamEx("SPBOPT", data.OptNameTekBuy, "DAYS_TO_MAT_DATE").param_value+0 == 0 then -- ���� ��������� ���� ��������� �������� �������, ���������� ������ ��������
				local StrikePerehodBuy = nil
				local NamePerehodBuy = nil
				local DtmdPerehodBuy = nil
				data.OptNamePerehodBuy = nil
				if data.FutPosTek > 0 then -- ���� ������� �� �������� long �� ������� Put
					StrikePerehodBuy = (math.ceil((data.FutPrice + 3750)/2500) * 2500) - 7500 -- ������ ����������� ������� �� 7500 � ������ �������, ��� ��������������� ����������
					MonthListBuy = {"M","N","O","P","Q","R","S","T","U","V","W","X"} -- ������ ������ ������� �������� Put
				else -- ���� ������� �� �������� short �� ������� Put
					if data.FutPosTek < 0 then -- ���� ������� �� �������� short �� ������� Call
						StrikePerehodBuy = (math.floor((data.FutPrice - 3750)/2500) * 2500) + 7500 -- ������ ����������� ������� �� 7500 � ������ �������, ��� ��������������� ����������
						MonthListBuy = {"A","B","C","D","E","F","G","H","I","J","K","L"} -- ������ ������ ������� �������� Call
					end			
				end
				-- !!! ��������� ����� �������������� ���� ��� ��� ������ ���������
				for _, M in pairs(MonthListBuy) do -- ������ ������ ������ ������ ��� ����� �������
					for _, W in pairs{"A","B","D","E",""} do
						NamePerehodBuy = "RI" .. StrikePerehodBuy .. "B" .. M .. data.TekGod .. W -- ������� ��� �������
						DtmdPerehodBuy = getParamEx("SPBOPT", NamePerehodBuy, "DAYS_TO_MAT_DATE") -- ����� �������� ���������� ���� �� ���������� ��� ������� ��������
						if DtmdPerehodBuy.result == "1" then -- ���� �������� ������
							if DtmdPerehodBuy.param_value+0 >= 6 and DtmdPerehodBuy.param_value+0 <= 8 then -- ���� ���� ���������� 7 ���� +- 1 ����
								data.OptNamePerehodBuy = NamePerehodBuy -- ��� �������
								SetCell(id, 9, 2, data.OptNamePerehodBuy)
								SetCell(id, 9, 3, getParamEx("SPBOPT", data.OptNamePerehodBuy, "OFFER").param_image)
								SetCell(id, 9, 4, getParamEx("SPBOPT", data.OptNamePerehodBuy, "DAYS_TO_MAT_DATE").param_image)
								data.GetNameOption = true
								return
							end
						end
					end
				end
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������ ������ �������� ��� ������� (�-� GetNameOption)" .. "\n")
				SetCell(id, 9, 6, "�� ������")
			else
				data.OptNamePerehodBuy = "��� ��������"
				SetCell(id, 9, 2, data.OptNamePerehodBuy)
				data.GetNameOption = true
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������ �������� Dtmd_Tek �������� ������� (�������), ����� �������� (�-� GetNameOption)" .. "\n")
			SetCell(id, 9, 6, "�� ������ �������� Dtmd_Tek")
		end
	end
end

function PositionTest()
	local tab
	data.PositionTest = false
	-- �������� ������� �� ��������
	if data.FutNameTek ~= nil then
		SetCell(id, 4, 2, data.FutNameTek)
		tab = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.FutNameTek, 0)
		if tab ~= nil then
			data.FutPosTek = tab.totalnet
			SetCell(id, 4, 3, getParamEx("SPBFUT", data.FutNameTek, "LAST").param_image)
			SetCell(id, 4, 4, getParamEx("SPBFUT", data.FutNameTek, "DAYS_TO_MAT_DATE").param_image)
			SetCell(id, 4, 5, data.FutPosTek .. "")
			if math.abs(data.FutPosTek) ~= data.MaxPosition then
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ ������� �� �������� (�-� PositionTest())" .. "\n")
				SetCell(id, 4, 6, "������������ �������")
			else
				data.PositionTest = true
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ ������� �� �������� (�-� PositionTest())" .. "\n")
			SetCell(id, 4, 6, "������������ �������")
		end
	else
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ��� �������� (�-� PositionTest())" .. "\n")
		SetCell(id, 6, 6, "�� ������� ���")
	end
	
	-- �������� ������� �� ������� � ����������� �������� (��������)
	if data.OptNameTekSell ~= nil then
		SetCell(id, 5, 2, data.OptNameTekSell)
		tab = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekSell, 0)
		if tab ~= nil then
			data.OptPosTekSell = tab.totalnet
			SetCell(id, 5, 3, getParamEx("SPBOPT", data.OptNameTekSell, "OFFER").param_image)
			SetCell(id, 5, 4, getParamEx("SPBOPT", data.OptNameTekSell, "DAYS_TO_MAT_DATE").param_image)
			SetCell(id, 5, 5, data.OptPosTekSell .. "")
			if data.OptPosTekSell ~= -data.MaxPosition then
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ ������� �� �������� ���������� ������� (�-� PositionTest())" .. "\n")
				SetCell(id, 5, 6, "������������ �������")
			else
				data.PositionTest = true
			end				
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ ������� �� �������� ���������� ������� (�-� PositionTest())" .. "\n")
			SetCell(id, 5, 6, "������������ �������")
		end
	else
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ��� �������� ���������� ������� (�-� PositionTest())" .. "\n")
		SetCell(id, 5, 6, "�� ������� ���")
	end
	
	-- �������� ������� �� ������� ������ �������� (��������)
	if data.OptNameTekBuy ~= nil then
		SetCell(id, 6, 2, data.OptNameTekBuy)
		tab = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekBuy, 0)
		if tab ~= nil then
			data.OptPosTekBuy = tab.totalnet
			SetCell(id, 6, 3, getParamEx("SPBOPT", data.OptNameTekBuy, "BID").param_image)
			SetCell(id, 6, 4, getParamEx("SPBOPT", data.OptNameTekBuy, "DAYS_TO_MAT_DATE").param_image)
			SetCell(id, 6, 5, data.OptPosTekBuy .. "")
			if data.OptPosTekBuy ~= data.MaxPosition then
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ ������� �� �������� ���������� ������� (�-� PositionTest())" .. "\n")
				SetCell(id, 6, 6, "������������ �������")
			else
				data.PositionTest = true
			end				
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ ������� �� �������� ���������� ������� (�-� PositionTest())" .. "\n")
			SetCell(id, 6, 6, "������������ �������")
		end
	else
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ��� �������� ���������� ������� (�-� PositionTest())" .. "\n")
		SetCell(id, 6, 6, "�� ������� ���")
	end
end

function SessionTest()
	if getInfoParam("SERVERTIME") ~= "" then
		local TradingStatus = getParamEx("SPBFUT", data.FutNameTek, "TRADINGSTATUS")
		if TradingStatus.result == "1" then
			if TradingStatus.param_value+0 == 1 then -- ������ �������
				local MonStartTime = getParamEx("SPBFUT", data.FutNameTek, "MONSTARTTIME") -- ����� �������� �������� ������
				local EnvStartTime = getParamEx("SPBFUT", data.FutNameTek, "EVNSTARTTIME") -- ����� �������� �������� ������
				local ServerTime = string.gsub(getInfoParam("SERVERTIME"), ":", "")+0
				if MonStartTime.result == "1" then
					if EnvStartTime.result == "1" then
						if ServerTime < MonStartTime.param_value + 200 then
							data.SessionTest = false
							LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �������� �������� ������ (�-� SessionTest())" .. "\n")
							SetWindowCaption(id, " �������� (����� �� �������� �������� ������)")
						else
							if ServerTime >= EnvStartTime.param_value+0 and  ServerTime < EnvStartTime.param_value + 200 then
								data.SessionTest = false
								LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �������� �������� ������ (�-� SessionTest())" .. "\n")
								SetWindowCaption(id, " �������� (����� �� �������� �������� ������)")
							else
								data.SessionTest = true
								SetWindowCaption(id, " ��������")
							end
						end
					else
						data.SessionTest = false
						LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� EnvStartTime �� ������ (�-� SessionTest())" .. "\n")
						SetWindowCaption(id, " �������� (�������� EnvStartTime �� ������)")
					end
				else
					data.SessionTest = false
					LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� MonStartTime �� ������ (�-� SessionTest())" .. "\n")
					SetWindowCaption(id, " �������� (�������� MonStartTime �� ������)")
				end
			else			
				data.SessionTest = false
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������ ������� (�-� SessionTest())" .. "\n")
				SetWindowCaption(id, " �������� (������ �������)")
			end		
		else
			data.SessionTest = false
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� TradingStatus �� ������ (�-� SessionTest())" .. "\n")
			SetWindowCaption(id, " �������� (�������� TradingStatus �� ������)")
		end
	else
		data.SessionTest = false
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� ServerTime �� ������ (�-� SessionTest())" .. "\n")
		SetWindowCaption(id, " �������� (�������� ServerTime �� ������)")
	end			
end

function StrategiTest()
	if data.OptNamePerehodSell ~= "��� ��������" then -- ���� ��������� ������ ��������
		if string.gsub(getInfoParam("SERVERTIME"), ":", "")+0 >= 140000 then -- � 14:00 ������� �� ��������� ������
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� �� ��������� ������" .. "\n")
			CloseSellOption() -- �������� �������� ���������� �������
			CloseBuyOption() -- �������� �������� ���������� �������
			OpenSellOption(data.OptNamePerehodSell) -- �������� ������ ���������� �������
			OpenBuyOption() -- �������� ������ ���������� �������
			
			-- �������� ����� ������� ��������
			data.OptNameTekSell = data.OptNamePerehodSell
			data.OptNameTekBuy = data.OptNamePerehodBuy
			
			-- ���������� ���� setting.lua
			local file = io.open("E:\\Program\\Lua\\trading_1.3\\setting.lua", "w")
			file:write("data.FutNameTek = \"" .. data.FutNameTek .. "\"\n")
			file:write("data.OptNameTekSell = \"" .. data.OptNameTekSell .. "\"")
			file:write("data.OptNameTekBuy = \"" .. data.OptNameTekBuy .. "\"")
			file:close()
			
			-- �������� ������� ������ � ��������
			data.OptNamePerehodSell = ""
			data.OptNameZamenaSell = ""
			data.OptNamePerehodBuy = ""
			
			-- ���������� ����� ����� ������ � ��������
			GetNameOption()
			
			return
		end
	end
end
function CloseSellOption()
	local LogCloseSellOption = io.open("E:\\Program\\Lua\\trading_1.3\\CloseSellOption.txt", "a")
	----------------------------------------
	-- �������� �������� ���������� �������
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
	-- �������� ������ �������
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
		ispolnenie = 0 -- ������� ���������� ������
		ispolneno_lotov = nil -- ����������� ���������� � ������
		
		-- �������� �����
		offer = getParamEx("SPBOPT", Option, "OFFER")
		bid = getParamEx("SPBOPT", Option, "BID")
		theorprice = getParamEx("SPBOPT", Option, "THEORPRICE")
		
		if offer.result == "1" then
			if bid.result == "1" then
				if theorprice.result == "1" then
					if (offer.param_value - bid.param_value) <= 50 then -- �������� ��������� ������ (����� ������� ��� ������ �������)
						if (offer.param_value - theorprice.param_value) <= 200 then -- ��������� �������� ���� � ������������� (�������� ���� ������������ ��� ������ �������)
							-- ���������� ������� ������� �� ������������ �������
							futuresHolding = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", Option, 0)
							if (futuresHolding == nil) or (futuresHolding.totalnet+0 <= 0 and futuresHolding.totalnet+0 > -data.MaxPosition * 2) then
								-- ���������� ���������� ����� �� �������
								if IsSubscribed_Level_II_Quotes("SPBOPT", Option) == true then -- ��������� ������� �� ������ � �������
									stakan = getQuoteLevel2("SPBOPT", Option) -- ����� ������
									if stakan.offer_count+0 > 0 then -- ��������� ���������� ��������� �������
										cena_zaiavki = stakan.offer[1].price - 50 -- ���� ������ �����: ������ ���� ������� �� ����� - 50
										if cena_zaiavki <= 0 then -- ���� ���� ���������� <= 0, �� ����� ���� 10
											cena_zaiavki = 10
										end
										LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���� ������������ ������ = " .. cena_zaiavki .. "\n")
										kol_lotov_v_rinke = 0
										for n = stakan.bid_count, 1, -1 do -- ���������� ��������� ������ �� ����� ������ ����
											if stakan.bid[n].price+0 >= cena_zaiavki then -- ����� ���� ����� ��������� �� ���� ���� ������
												kol_lotov_v_rinke = kol_lotov_v_rinke + stakan.bid[n].quantity
											else
												break
											end
										end
										LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� ����� � ����� = " .. kol_lotov_v_rinke .. "\n")
										if kol_lotov_v_rinke > 0 then -- ���� ���� ����� (������ �� �������) �� ���� ���� ������
											-- ��������� ������� ��� ������ (������� ����� � ����)
											transaction.QUANTITY = Quantity .. ""
											transaction.PRICE = cena_zaiavki .. ""
											
											-- ��������� ������ � �����
											LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������ ������� " .. transaction.QUANTITY .. " ���������� �� " .. transaction.PRICE .. "\n")
											local resultTransaction = sendTransaction(transaction)
											LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. resultTransaction .. "\n")
											
											-- �������� ���������� ������
											while true do
												LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� 1 ���." .. "\n")
												sleep(1000) -- ����� 1 �������
												if ispolnenie == 1 then -- ���� ������� ����� �� ���������� (������� ��������� ������ OnTransReply)
													LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ����� �� �-�� OnTransReply" .. "\n")
													if ispolneno_lotov ~= nil then -- ���� ��������� ����������� ���������� (������� ��������� ������ OnOrder)
														LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ����� �� �-�� OnOrder, ��������� ����� - " .. ispolneno_lotov .. "\n")
														Quantity = Quantity - ispolneno_lotov -- ������� ���������� ���������� ��� ������
														LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� ���������� - " .. Quantity .. "\n")
														
														-- ���������� ���� �� ����� ��������
														if Quantity == 0 then -- ������� ������� ���������
															Unsubscribe_Level_II_Quotes("SPBOPT", Option) -- ������� ������
															LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� �� ������� " .. data.OptNameTekSell .. " ������� ���������" .. "\n")
															LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �-�� OpenSellOption" .. "\n")
															LogOpenSellOption:close()
															return -- ����� �� �������
														else
															if Quantity < 0 then -- �������, ���� ���������
																Unsubscribe_Level_II_Quotes("SPBOPT", Option) -- ������� ������
																LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ��� �������� ������� - " .. Quantity .. "\n")
																LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �-�� OpenSellOption" .. "\n")
																LogOpenSellOption:close()
																return -- ����� �� �������
															end
														end
													end
												end
											end
										end
									else
										LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ��� ����������� �� �����" .. "\n")
									end
								else
									LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ������ �� �����������" .. "\n")
									Subscribe_Level_II_Quotes("SPBOPT", Option) -- �������� ������
								end
							else
								LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ �������" .. "\n")
							end
						else
							LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ �������� ���� - " .. (offer.param_value - theorprice.param_value) .. "\n")
						end	
					else
						LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� �������� ����� - " .. (offer.param_value - bid.param_value) .. "\n")
					end
				else
					LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� theorprice �� ������" .. "\n")
				end
			else
				LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� bid �� ������" .. "\n")
			end
		else
			LogOpenSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� offer �� ������" .. "\n")
		end
		LogCloseSellOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� 2 ���." .. "\n")
		sleep(2000)
	end
end

function CloseBuyOption()
	local LogCloseBuyOption = io.open("E:\\Program\\Lua\\trading_1.3\\CloseBuyOption.txt", "a")
	----------------------------------------
	-- �������� �������� ���������� �������
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
		
		ispolnenie = 0 -- ������� ���������� ������
		ispolneno_lotov = nil -- ����������� ���������� � ������
		
		-- �������� �����
		offer = getParamEx("SPBOPT", data.OptNameTekBuy, "OFFER")
		bid = getParamEx("SPBOPT", data.OptNameTekBuy, "BID")
		theorprice = getParamEx("SPBOPT", data.OptNameTekBuy, "THEORPRICE")
		
		if offer.result == "1" then
			if bid.result == "1" then
				if theorprice.result == "1" then
					if (offer.param_value - bid.param_value) <= 50 then -- �������� ��������� ������ (����� ������� ��� ������ �������)
						if (offer.param_value - theorprice.param_value) <= 200 then -- ��������� �������� ���� � ������������� (�������� ���� ������������ ��� ������ �������)
							-- ���������� ������� ������� �� ������������ �������
							if getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekBuy, 0) ~= nil then
								totalnet = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNameTekBuy, 0).totalnet+0 -- ������� �������
								if totalnet > 0 then
									-- ���������� ���������� ����� �� �������
									if IsSubscribed_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) == true then -- ��������� ������� �� ������ � �������
										stakan = getQuoteLevel2("SPBOPT", data.OptNameTekBuy) -- ����� ������
										if stakan.offer_count+0 > 0 then -- ���������� ��������� �������
											-- ���������� ���� ��� ����� ������
											cena_zaiavki = stakan.offer[1].price - 50 -- ���� ������ �����: ������ ���� ������� �� ����� - 50
											if cena_zaiavki <= 0 then -- ���� ���� ���������� <= 0, �� ����� ���� 10
												cena_zaiavki = 10
											end
											LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���� ������������ ������ = " .. cena_zaiavki .. "\n")
											kol_lotov_v_rinke = 0
											for n = stakan.bid_count, 1, -1 do -- ���������� ��������� ������ �� ����� ������ ����
												if stakan.bid[n].price+0 >= cena_zaiavki then -- ����� ���� ����� ��������� �� ���� ���� ������
													kol_lotov_v_rinke = kol_lotov_v_rinke + stakan.bid[n].quantity
												else
													break
												end
											end
											LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� ����� � ����� = " .. kol_lotov_v_rinke .. "\n")
											if kol_lotov_v_rinke > 0 then -- ���� ���� ����� (������ �� �������) �� ���� ���� ������
												-- ��������� ������� ��� ������ (������� ����� � ����)
												transaction.QUANTITY = Quantity .. ""
												transaction.PRICE = cena_zaiavki .. ""
												
												-- ��������� ������ � �����
												LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������ ������� " .. transaction.QUANTITY .. " ���������� �� " .. transaction.PRICE .. "\n")
												local resultTransaction = sendTransaction(transaction)
												LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. resultTransaction .. "\n")
												
												-- �������� ���������� ������
												while true do
													LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� 1 ���." .. "\n")
													sleep(1000) -- ����� 1 �������
													if ispolnenie == 1 then -- ���� ������� ����� �� ���������� (������� ��������� ������ OnTransReply)
														LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ����� �� �-�� OnTransReply" .. "\n")
														if ispolneno_lotov ~= nil then -- ���� ��������� ����������� ���������� (������� ��������� ������ OnOrder)
															LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ����� �� �-�� OnOrder, ��������� ����� - " .. ispolneno_lotov .. "\n")
															Quantity = Quantity - ispolneno_lotov -- ������� ���������� ���������� ��� ������
															LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� ���������� - " .. Quantity .. "\n")
															
															-- ���������� ���� �� ����� ��������
															if Quantity == 0 then -- ������� �������
																Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) -- ������� ������
																LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� �� ������� " .. data.OptNameTekBuy .. " ������� ���������" .. "\n")
																LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �-�� CloseBuyOption" .. "\n")
																LogCloseBuyOption:close()
																return -- ����� �� �������
															else
																if Quantity < 0 then -- �������, ���� ���������
																	Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) -- ������� ������
																	LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ��� �������� ������� - " .. Quantity .. "\n")
																	LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �-�� CloseBuyOption" .. "\n")
																	LogCloseBuyOption:close()
																	return -- ����� �� �������
																end
															end
														else
															LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ����� �� �-�� OnOrder, ��������� ����� - " .. ispolneno_lotov .. "\n")
														end
													else
														LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ����� �� �-�� OnTransReply" .. "\n")
													end
												end
											end
										else
											LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ��� ������ �� �����" .. "\n")
										end
									else
										LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ������ �� �����������" .. "\n")
										Subscribe_Level_II_Quotes("SPBOPT", data.OptNameTekBuy) -- �������� ������
									end
								else
									LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ �������" .. "\n")
								end
							else
								LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ��� ������ � �������" .. "\n")
							end
						else
							LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ �������� ����" .. "\n")
						end	
					else
						LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� �������� �����" .. "\n")
					end
				else
					LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� theorprice �� ������" .. "\n")
				end
			else
				LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� bid �� ������" .. "\n")
			end
		else
			LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� offer �� ������" .. "\n")
		end
		LogCloseBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� 2 ���." .. "\n")
		sleep(2000)
	end
end

function OpenBuyOption()
	local LogOpenBuyOption = io.open("E:\\Program\\Lua\\trading_1.3\\OpenBuyOption.txt", "a")
	----------------------------------------
	-- �������� �������� ���������� �������
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
		
		ispolnenie = 0 -- ������� ���������� ������
		ispolneno_lotov = nil -- ����������� ���������� � ������
		
		-- �������� �����
		offer = getParamEx("SPBOPT", data.OptNamePerehodBuy, "OFFER")
		bid = getParamEx("SPBOPT", data.OptNamePerehodBuy, "BID")
		theorprice = getParamEx("SPBOPT", data.OptNamePerehodBuy, "THEORPRICE")
		
		if offer.result == "1" then
			if bid.result == "1" then
				if theorprice.result == "1" then
					if (offer.param_value - bid.param_value) <= 50 then -- �������� ��������� ������ (����� ������� ��� ������ �������)
						if (offer.param_value - theorprice.param_value) <= 200 then -- ��������� �������� ���� � ������������� (�������� ���� ������������ ��� ������ �������)
							-- ���������� ������� ������� �� ������������ �������
							futuresHolding = getFuturesHolding("SPBFUT589000", "SPBFUT00gqr", data.OptNamePerehodBuy, 0)
							if (futuresHolding == nil) or (futuresHolding.totalnet+0 >= 0 and futuresHolding.totalnet+0 < data.MaxPosition) then
								-- ���������� ���������� ����� �� �������
								if IsSubscribed_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) == true then -- ��������� ������� �� ������ � �������
									stakan = getQuoteLevel2("SPBOPT", data.OptNamePerehodBuy) -- ����� ������
									if stakan.bid_count+0 > 0 then -- ���������� ��������� �������
										-- ���������� ���� ��� ����� ������
										cena_zaiavki = stakan.bid[#stakan.bid].price + 50 -- ����� ���� ����� ������ ��������� �� ������� (���������) ��������� 50 - ���� ���� ������
										LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���� ������������ ������ = " .. cena_zaiavki .. "\n")
										kol_lotov_v_rinke = 0 -- �������� kol_lotov_v_rinke ��� ������ ��������
										for n = 1, stakan.offer_count + 0 do -- ���������� ������� ��������� �������
											if stakan.offer[n].price+0 <= cena_zaiavki then -- ����� ���� ����� ��������� �� ���� ���� ������
												kol_lotov_v_rinke = kol_lotov_v_rinke + stakan.offer[n].quantity
											else
												break
											end
										end
										LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� ����� � ����� = " .. kol_lotov_v_rinke .. "\n")
										if kol_lotov_v_rinke > 0 then -- ���� ���� ����������� (������ �� �������) �� ���� ���� ������
											-- ��������� ������� ��� ������ (������� ����� � ����)
											transaction.QUANTITY = Quantity .. ""
											transaction.PRICE = cena_zaiavki .. ""
											
											-- ��������� ������ � �����
											LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������ ������� " .. transaction.QUANTITY .. " ���������� �� " .. transaction.PRICE .. "\n")
											local resultTransaction = sendTransaction(transaction)
											LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. resultTransaction .. "\n")
												
											-- �������� ���������� ������
											while true do
												LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� 1 ���." .. "\n")
												sleep(1000) -- ����� 1 �������
												if ispolnenie == 1 then -- ���� ������� ����� �� ���������� (������� ��������� ������ OnTransReply)
													LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ����� �� �-�� OnTransReply" .. "\n")
													if ispolneno_lotov ~= nil then -- ���� ��������� ����������� ���������� (������� ��������� ������ OnOrder)
														LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ����� �� �-�� OnOrder, ��������� ����� - " .. ispolneno_lotov .. "\n")
														Quantity = Quantity - ispolneno_lotov -- ������� ���������� ���������� ��� ������
														LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� ���������� - " .. Quantity .. "\n")
														
														-- ���������� ���� �� ����� ��������
														if Quantity == 0 then -- ������� �������
															Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) -- ������� ������
															LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� �� ������� " .. data.OptNamePerehodBuy .. " ������� ���������" .. "\n")
															LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �-�� OpenBuyOption" .. "\n")
															LogOpenBuyOption:close()
															return -- ����� �� �������
														else
															if Quantity < 0 then -- �������, ���� ���������
																Unsubscribe_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) -- ������� ������
																LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� ��� �������� ������� - " .. Quantity .. "\n")
																LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� �� �-�� OpenBuyOption" .. "\n")
																LogOpenBuyOption:close()
																return -- ����� �� �������
															end
														end
													else
														LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ����� �� �-�� OnOrder, ��������� ����� - " .. ispolneno_lotov .. "\n")
													end
												else
													LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ����� �� �-�� OnTransReply" .. "\n")
												end
											end
										end
									else
										LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ��� ����������� �� �����" .. "\n")
									end
								else
									LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �� ������� ������ �� �����������" .. "\n")
									Subscribe_Level_II_Quotes("SPBOPT", data.OptNamePerehodBuy) -- �������� ������
								end
							else
								LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ �������" .. "\n")
							end
						else
							LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������������ �������� ����" .. "\n")
						end	
					else
						LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ������� �������� �����" .. "\n")
					end
				else
					LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� theorprice �� ������" .. "\n")
				end
			else
				LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� bid �� ������" .. "\n")
			end
		else
			LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " �������� offer �� ������" .. "\n")
		end
		LogOpenBuyOption:write(os.date("%d.%m.%y %H:%M:%S") .. " ����� 2 ���." .. "\n")
		sleep(2000)
	end
end


function OnTransReply(trans_reply)
	if trans_reply.trans_id == 1 then
		LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. trans_reply.result_msg .. "(OnTransReply)" .. "\n") -- �������� � ���� ��������� � ����������
		if trans_reply.status == 3 then
			ispolnenie = 1
		end
	end	
end

function OnOrder(order)
	if order.trans_id == 1 then
		 -- �������� � ���� ��������� � ������
		LogFile:write(os.date("%d.%m.%y %H:%M:%S")) -- ����, �����
		LogFile:write(" order.order_num - " .. order.order_num) -- ����� ������
		LogFile:write(" order.sec_code - " .. order.sec_code) -- ��� �����������
		LogFile:write(" order.price - " .. order.price) -- ����
		LogFile:write(" order.qty - " .. order.qty) -- ��� �����
		LogFile:write(" order.balance - " .. order.balance) -- �������
		LogFile:write(" (OnOrder)"  .. "\n")
		ispolneno_lotov = order.qty - order.balance -- ��������� �����, ��������� �����
	end
end

function InsertTable()
	id = AllocTable()
	AddColumn(id, 1, "", true, QTABLE_STRING_TYPE,15)
	AddColumn(id, 2, "��������", true, QTABLE_INT_TYPE,15)
	AddColumn(id, 3, "����", true, QTABLE_INT_TYPE,8)
	AddColumn(id, 4, "���.", true, QTABLE_INT_TYPE,5)
	AddColumn(id, 5, "���.", true, QTABLE_STRING_TYPE,5)
	AddColumn(id, 6, "����������", true, QTABLE_STRING_TYPE,10)
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
	SetCell(id, 1, 1, "������ ���")
	SetCell(id, 2, 1, "�������� ���")
	SetCell(id, 3, 1, "�������� ���")
	SetCell(id, 4, 1, "�������")
	SetCell(id, 5, 1, "������� (Sell)")
	SetCell(id, 6, 1, "������� (Buy)")
	SetCell(id, 7, 1, "������ (Sell)")
	SetCell(id, 8, 1, "������� (Sell)")
	SetCell(id, 9, 1, "������� (Buy)")
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
					if data.FutPrice > 0 then -- ���� ��� �������� ��������
						GetNameOption()
						if data.GetNameOption == true then
							StrategiTest()
						else
							LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� data.GetNameOption = " .. tostring(data.GetNameOption) .. " �-� GetNameOption() ����� ����������" .. "\n")
						end
					else
						LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ��� ���� �������� (�-� main)" .. "\n")
						SetCell(id, 2, 5, "��� ���� ��������")
					end
				else
					LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� data.PositionTest = " .. tostring(data.PositionTest) .. "\n")
				end
			else
				LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ���������� data.SessionTest = " .. tostring(data.SessionTest) .. "\n")
			end
		else
			LogFile:write(os.date("%d.%m.%y %H:%M:%S") .. " ��� �����" .. "\n")
			SetWindowCaption(id, " �������� (��� �����)")
		end
		if IsWindowClosed(id) then
			break
		else
			sleep(3000)
		end
	end
end

--������� �������
-- �������������� ���� � ������� � ����� �� ���
-- ����������� ������ �� ������� �� ���������� �������
-- � ��������� ���� ��������� �������� ���������� ����� �� ��������� ������ ��� �������� ������

--[[
	���������
	��� ������� ��������� � ����������� ������� �� ��������.
	������ ������������ ������� ������������: ������� ���� �������� +- 3750,
	������� ������� ������. � ����� ������� ������������ 7500 � ����������
	���� ������ � ����������� ������ ������� �� ��������.
	����� �������� ��������� ��������� � ��������� ��������
	���� ����� ������������.
	������ ������� �� ��������� � ��� �� �����
	���������� ��� ���������� �������. ������� �� ������ �� ���������
	����� ���������� �� �������� ����� � �������. ��������� ������ �� 
	�������� �� ����������.
--]]