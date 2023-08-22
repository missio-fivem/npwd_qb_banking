local QBCore = exports["qb-core"]:GetCoreObject()
local bannedCharacters = { "%", "$", ";" }

local function round(num, numDecimalPlaces)
	if numDecimalPlaces and numDecimalPlaces > 0 then
		local mult = 10 ^ numDecimalPlaces
		return math.floor(num * mult + 0.5) / mult
	end
	return math.floor(num + 0.5)
end

lib.callback.register('npwd:qb-banking:GetBankBalance', function(source)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local balance = Player.Functions.GetMoney("bank")
	return balance
end)

lib.callback.register('npwd:qb-banking:getAccountNumber', function(source)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local accountNumber = Player.PlayerData.charinfo.account
	return accountNumber
end)

lib.callback.register('npwd:qb-banking:getContacts', function(source)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local contacts = MySQL.query.await(
		"SELECT * FROM npwd_phone_contacts WHERE identifier = ? ORDER BY display ASC",
		{ Player.PlayerData.citizenid }
	)
	return contacts
end)

lib.callback.register('npwd:qb-banking:getInvoices', function(source)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local invoices = MySQL.query.await(
		"SELECT * FROM phone_invoices WHERE citizenid = ?",
		{ Player.PlayerData.citizenid }
	)
	return invoices
end)

lib.callback.register('npwd:qb-banking:payInvoice', function(source, data)
	local src = source
	local SenderPlayer = QBCore.Functions.GetPlayerByCitizenId(data.sendercitizenid)
	local Player = QBCore.Functions.GetPlayer(src)
	local society = data.society
	local amount = tonumber(data.amount)
	local invoiceId = data.id
	local invoiceMailData = {}
	local balance = Player.Functions.GetMoney("bank")
	local success = true

	if balance < amount then
		success = false
	end

	Player.Functions.RemoveMoney('bank', amount, "paid-invoice")

	if not Config.BillingCommissions[society] then
		invoiceMailData = {
			sender = 'Billing Department',
			subject = 'Bill Paid',
			message = string.format('%s %s paid a bill of $%s', Player.PlayerData.charinfo.firstname,
				Player.PlayerData.charinfo.lastname, amount)
		}
	end

	if Config.BillingCommissions[society] then
		local commission = round(amount * Config.BillingCommissions[society])
		invoiceMailData = {
			sender = 'Billing Department',
			subject = 'Bill Paid',
			message = string.format('You received a commission check of $%s when %s %s paid a bill of $%s.', commission,
				Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname, amount)
		}
		if SenderPlayer then
			SenderPlayer.Functions.AddMoney('bank', commission)
		else
			local RecieverDetails = MySQL.query.await("SELECT money FROM players WHERE citizenid = ?",
				{ data.sendercitizenid })
			local RecieverMoney = json.decode(RecieverDetails[1].money)
			RecieverMoney.bank = (RecieverMoney.bank + commission)
			MySQL.update(
				"UPDATE players SET money = ? WHERE citizenid = ?",
				{ json.encode(RecieverMoney), data.sendercitizenid }
			)
		end
		amount = amount - commission
	end
	TriggerEvent('qb-phone:server:sendNewMailToOffline', data.sendercitizenid, invoiceMailData)
	exports['Renewed-Banking']:addAccountMoney(society, amount)
	MySQL.query('DELETE FROM phone_invoices WHERE id = ?', { invoiceId })
	local newBalance = Player.Functions.GetMoney("bank")

	return success and newBalance or false
end)

lib.callback.register('npwd:qb-banking:transferMoney', function(source, amount, toAccount, transferType)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local balance = Player.Functions.GetMoney("bank")
	local amount = tonumber(amount)
	local toAccount = toAccount
	local RecieverDetails
	local success

	if balance < amount then
		success = false
	end

	if transferType == "contact" then
		local phoneNumber = toAccount.number
		RecieverDetails = MySQL.query.await(
			"SELECT citizenid, money FROM players where phone_number = ?",
			{ phoneNumber }
		)
	end

	if transferType == "accountNumber" then
		for _, v in pairs(bannedCharacters) do --strip bad characters
			toAccount = string.gsub(toAccount, "%" .. v, "")
		end
		local query = '%"account":"' .. toAccount .. '"%'
		RecieverDetails = MySQL.query.await("SELECT citizenid, money FROM players WHERE charinfo LIKE ?", { query })
	end

	if RecieverDetails[1] ~= nil then
		local Reciever = QBCore.Functions.GetPlayerByCitizenId(RecieverDetails[1].citizenid)
		Player.Functions.RemoveMoney("bank", amount)
		if Reciever ~= nil then
			Reciever.Functions.AddMoney("bank", amount)
		else
			local RecieverMoney = json.decode(RecieverDetails[1].money)
			RecieverMoney.bank = (RecieverMoney.bank + amount)
			MySQL.update(
				"UPDATE players SET money = ? WHERE citizenid = ?",
				{ json.encode(RecieverMoney), RecieverDetails[1].citizenid }
			)
		end
		success = true
	else
		success = false
	end
	return success and Player.Functions.GetMoney("bank") or false
end)

AddEventHandler("QBCore:Server:OnMoneyChange", function(source, moneytype, amount, type)
	if moneytype == "bank" then
		local Player = QBCore.Functions.GetPlayer(source)
		local balance = Player.Functions.GetMoney("bank")
		TriggerClientEvent("npwd:qb-banking:updateMoney", source, balance)
	end
end)
