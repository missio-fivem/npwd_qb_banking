local QBCore = exports['qb-core']:GetCoreObject()

RegisterNUICallback("npwd:qb-banking:getBalance", function(_, cb)
  local result = lib.callback.await('npwd:qb-banking:GetBankBalance', false)
  if result then
    cb({ status = "ok", data = result })
  else
    cb({ status = "error" })
  end
end)

RegisterNUICallback("npwd:qb-banking:getAccountNumber", function(_, cb)
  local result = lib.callback.await('npwd:qb-banking:getAccountNumber', false)

  if result then
    cb({ status = "ok", data = result })
  else
    cb({ status = "error" })
  end
end)

RegisterNUICallback("npwd:qb-banking:getContacts", function(_, cb)
  local result = lib.callback.await('npwd:qb-banking:getContacts', false)

  if result then
    cb({ status = "ok", data = result })
  else
    cb({ status = "error" })
  end
end)

RegisterNUICallback("npwd:qb-banking:transferMoney", function(data, cb)
  local result = lib.callback.await('npwd:qb-banking:transferMoney', false, data.amount, data.toAccount,
    data.transferType)

  if result then
    cb({ status = "ok", data = tonumber(result) })
  else
    cb({ status = "error" })
  end
end)

RegisterNUICallback("npwd:qb-banking:getInvoices", function(_, cb)
  local result = lib.callback.await('npwd:qb-banking:getInvoices', false)

  if result then
    cb({ status = "ok", data = result })
  else
    cb({ status = "error" })
  end
end)


RegisterNUICallback("npwd:qb-banking:payInvoice", function(data, cb)
  local result = lib.callback.await('npwd:qb-banking:payInvoice', false, data)

  if result then
    cb({ status = "ok", data = result })
  else
    cb({ status = "error" })
  end
end)

RegisterNetEvent('npwd:qb-banking:updateMoney', function(balance)
  exports.npwd:sendUIMessage({ type = "npwd:qb-banking:updateMoney", payload = balance })
end)

RegisterNetEvent('npwd:qb-banking:newInvoice', function(data)
  exports.npwd:sendUIMessage({ type = "npwd:qb-banking:newInvoice", payload = data })
end)
