local ESX = nil

if Config.esx == 'event' then
	Citizen.CreateThread(function()
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	end)
else
	ESX = exports["es_extended"]:getSharedObject()
end

TriggerEvent('esx_society:registerSociety', Config.jobname, Config.jobname, Config.society, Config.society, Config.society, {type = 'private'})

-- CALLBACKS

ESX.RegisterServerCallback('eske_leasing:tjekFKonto', function(source, cb)
    local firmakonto = 0
    TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account) 
        firmakonto = account.money 
    end)
    cb(firmakonto)
end)

ESX.RegisterServerCallback('eske_leasing:seLager', function(source, cb)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_cars")
    local biler = {}
    for k,v in pairs(rawdata) do
        if v.lager > 0 then
            local item = {
                antal = v.lager,
                ydelse = v.ydelse,
                model = v.model,
                klasse = v.klasse,
                indkobspris = v.indkobspris
            }
            table.insert(biler, item)
        end
    end
    cb(biler)
end)

ESX.RegisterServerCallback('eske_leasing:seLager2', function(source, cb)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_cars")
    local biler = {}
    for k,v in pairs(rawdata) do
        local item = {
            antal = v.lager,
            ydelse = v.ydelse,
            model = v.model,
            klasse = v.klasse,
            indkobspris = v.indkobspris
        }
        table.insert(biler, item)
    end
    cb(biler)
end)

ESX.RegisterServerCallback('eske_leasing:seAftaler', function(source, cb)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_leased")
    local aftaler = {}
    for _,v in pairs(rawdata) do
        if v.ydelse > 0 then
            local navn = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {['@identifier'] = v.identifier})
            local item = {
                model = v.model,
                nummerplade = v.nummerplade,
                aftalttid = math.round((v.expire-os.time())/86400),
                ydelse = v.ydelse .. ' DKK',
                startdato = os.date('%c',v.starttid),
                slutdato = os.date('%c',v.expire),
                saelger = v.saelger,
                identifier = navn[1].firstname .. ' ' .. navn[1].lastname
            }
            table.insert(aftaler, item)
        end
    end
    cb(aftaler)
end)

ESX.RegisterServerCallback('eske_leasing:seKatalog', function(source, cb)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_cars")
    local biler = {}
    for k,v in pairs(rawdata) do
        local item = {
            ydelse = v.ydelse,
            model = v.model,
            klasse = v.klasse,
        }
        table.insert(biler, item)
    end
    cb(biler)
end)

ESX.RegisterServerCallback('eske_leasing:kunde:raadTilLeasing', function(source, cb, ydelse, id)
    local xTarget = ESX.GetPlayerFromId(id)
    if xTarget ~= nil then
        if xTarget.getAccount('bank').money >= ydelse then
            cb(true)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('eske_leasing:kunde:seDisplay', function(source, cb)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_display")
    local display = {}
    for k,v in pairs(rawdata) do
        table.insert(display, {
            model = v.model
        })
    end
    cb(display)
end)

ESX.RegisterServerCallback('eske_leasing:boss:seAnsatte', function(source, cb)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM users WHERE job = @job", {['@job'] = Config.jobname})
    local ansatte = {}
    for k, v in pairs(rawdata) do
        table.insert(ansatte, {
            navn = v.firstname .. ' ' .. v.lastname,
            nummer = v.phone_number,
            identifier = v.identifier,
            grade = v.job_grade
        })
    end
    cb(ansatte)
end)

ESX.RegisterServerCallback('eske_leasing:backend:findNummerplade', function(source, cb, plate)
    MySQL.Async.fetchAll('SELECT 1 from owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        cb(result[1] ~= nil)
    end)
end)

ESX.RegisterServerCallback('eske_leasing:boss:seRanks', function(source, cb)
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM job_grades WHERE job_name = @job ORDER BY grade DESC", {['@job'] = Config.jobname})
    local ranks = {}
    for k, v in pairs(rawdata) do
        table.insert(ranks, {
            rangering = v.label,
            grade = v.grade
        })
    end
    cb(ranks)
end)

ESX.RegisterServerCallback('eske_leasing:boss:firmaKasse', function(source, cb)
    TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account) 
        if account ~= nil then
            if account.money ~= nil then
                cb(account.money)
            else
                cb(0)
            end
        else
            cb(0)
        end
    end)
end)

ESX.RegisterServerCallback('eske_leasing:boss:seSpillere', function(source, cb)
    local spillere = ESX.GetExtendedPlayers()
    local _spillere = {}
    for _, xPlayer in pairs(spillere) do 
        table.insert(_spillere, {
            id = xPlayer.source
        })
    end
    cb(_spillere)
end)

-- EVENTS
AddEventHandler('eske_leasing:boss:tilføjMedlem')
RegisterNetEvent('eske_leasing:boss:tilføjMedlem', function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.admpersonale then
            local xTarget = ESX.GetPlayerFromId(id)
            if xTarget ~= nil then
                if xTarget.source ~= xPlayer.source then
                    xTarget.setJob(Config.jobname, 0)
                    MySQL.Async.execute('UPDATE users SET job = @job, job_grade = 0 WHERE identifier = @identifier', {
                        ['@job'] = Config.jobname,
                        ['@identifier'] = xTarget.identifier
                    }, function(...)
                        TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har ansat ' .. xTarget.getName() .. ' i ' .. Config.firmanavn .. '.', length = 10000})
                        TriggerClientEvent('mythic_notify:client:SendAlert', xTarget.source, { type = 'success', text = xPlayer.getName() .. ' ansatte dig i ' .. Config.firmanavn .. '.', length = 10000})
                        PerformHttpRequest(Config.bosswebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' ansatte ' .. xTarget.getName() .. ' i ' .. Config.firmanavn .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                    end)
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du kan ikke vælge dig selv.', length = 10000})
                end
            else
                print('[ESKE LEASING] Der skete en fejl ved ansættelse af et medlem. Kontakt support. [2]')
                PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
                    local ip =  tostring(text)
                    PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved ansættelse af et medlem. [2]', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at tilføje en person.', length = 10000})
        end
    else 
        print('[ESKE LEASING] Der skete en fejl ved ansættelse af et medlem. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved ansættelse af et medlem. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

AddEventHandler('eske_leasing:boss:tilføjPenge')
RegisterNetEvent('eske_leasing:boss:tilføjPenge', function(penge)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.admkasse then
            if xPlayer.getMoney() >= penge then
                TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account)
                    xPlayer.removeMoney(penge)
                    account.addMoney(penge)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har tilføjet ' .. penge .. ' til jeres kasse.', length = 10000})
                    PerformHttpRequest(Config.bosswebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' tilføjede ' .. penge .. ' til jeres firmakasse. Der er nu ' .. account.money + penge .. ' DKK.', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            else
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Dette har du desværre ikke råd til.', length = 10000})
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at tilføje penge til kassen.', length = 10000})
        end
    else 
        print('[ESKE LEASING] Der skete en fejl ved tilføjelse af penge. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved tilføjelse af penge. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end 
end)

AddEventHandler('eske_leasing:boss:fjernPenge')
RegisterNetEvent('eske_leasing:boss:fjernPenge', function(penge)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.admkasse then
            TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account)
                if account.money >= penge then
                    xPlayer.addMoney(penge)
                    account.removeMoney(penge)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har fjernet ' .. penge .. ' fra jeres kasse.', length = 10000})
                    PerformHttpRequest(Config.bosswebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' tog ' .. penge .. ' fra jeres firmakasse. Der er nu ' .. account.money - penge .. ' DKK.', tts = false}), { ['Content-Type'] = 'application/json' })
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Der er ikke nok penge i kassen til dette.', length = 10000})
                end
            end)
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at fjerne penge fra kassen.', length = 10000})
        end
    else 
        print('[ESKE LEASING] Der skete en fejl ved fjernelse af penge. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved fjernelse af penge. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end 
end)

AddEventHandler('eske_leasing:boss:fjernMedlem')
RegisterNetEvent('eske_leasing:boss:fjernMedlem', function(identifier)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.admpersonale then
            local xTarget = ESX.GetPlayerFromIdentifier(identifier)
            if xTarget then
                xTarget.setJob('unemployed', 0)
                MySQL.Async.execute('UPDATE users SET job = @job, job_grade = 0 WHERE identifier = @identifier', {
                    ['@job'] = 'unemployed',
                    ['@identifier'] = xTarget.identifier
                }, function(...)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har fjernet ' .. xTarget.getName() .. ' fra ' .. Config.firmanavn .. '.', length = 10000})
                    TriggerClientEvent('mythic_notify:client:SendAlert', xTarget.source, { type = 'success', text = xPlayer.getName() .. ' fjernede dig fra ' .. Config.firmanavn .. '.', length = 10000})
                    PerformHttpRequest(Config.bosswebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' fjernede ' .. xTarget.getName() .. ' fra ' .. Config.firmanavn .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            else
                MySQL.Async.execute("UPDATE users SET job_grade = @grade, job = @job, job_grade = @job_grade WHERE identifier = @identifier", {
                    ['@identifier'] = identifier, ['@grade'] = grade, ['@job'] = 'unemployed', ['@job_grade'] = 0
                }, function(...)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har fjernet medlemmet fra ' .. Config.firmanavn .. '.', length = 10000})
                    PerformHttpRequest(Config.bosswebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' fjernede ' .. identifier .. ' fra ' .. Config.firmanavn .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at fyre en person.', length = 10000})
        end
    else 
        print('[ESKE LEASING] Der skete en fejl ved fjernelse af et medlem. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved fjernelse af en ansat. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

AddEventHandler('eske_leasing:boss:skiftRangering')
RegisterNetEvent('eske_leasing:boss:skiftRangering', function(identifier, grade)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.admpersonale then
            local xTarget = ESX.GetPlayerFromIdentifier(identifier)
            if xTarget then
                xTarget.setJob(Config.jobname, grade)
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har tildelt ' .. xTarget.getName() .. ' en anden rangering.', length = 10000})
                TriggerClientEvent('mythic_notify:client:SendAlert', xTarget.source, { type = 'success', text = xPlayer.getName() .. ' tildelte en anden rangering.', length = 10000})
                PerformHttpRequest(Config.bosswebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' satte ' .. xTarget.getName() .. ' til at have rangeringsgrad ' .. grade .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
            else
                MySQL.Async.execute("UPDATE users SET job_grade = @grade WHERE identifier = @identifier", {
                    ['@identifier'] = identifier, ['@grade'] = grade
                }, function(...)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har tildelt medlemmet en ny rangering.', length = 10000})
                    PerformHttpRequest(Config.bosswebhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName() .. ' satte ' .. identifier .. ' til at have rangeringsgrad ' .. grade .. '.', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at forfremme en person.', length = 10000})
        end
    else 
        print('[ESKE LEASING] Der skete en fejl ved forfremmelse af et medlem. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved forfremmelse af en ansat. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:kobBilTilLager')
AddEventHandler('eske_leasing:ansat:kobBilTilLager', function(model)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.koblager then
            local bildata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_cars WHERE model = @model", {['@model'] = model})
            if bildata ~= nil then
                TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account) 
                    if bildata[1].indkobspris < account.money then
                        tilfojBilTilLager(model, bildata[1].indkobspris)
                        TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu indkøbt en ' .. model .. ' til jeres lager for ' .. bildata[1].indkobspris .. ' DKK.', length = 10000})
                        PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." købte en "..model.. " til lageret for " .. bildata[1].indkobspris .. " DKK." , tts = false}), { ['Content-Type'] = 'application/json' })
                    else
                        TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Firmaet har desværre ikke nok penge til at købe denne bil.', length = 10000})
                    end
                end)
            else
                print('[ESKE LEASING] Der skete en fejl ved køb af en bil til lageret. Kontakt support. [2]')
                PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
                    local ip =  tostring(text)
                    PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved køb af en bil til lageret. [2]', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du er ikke høj nok rank til at kunne købe biler til lageret.', length = 10000})
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved køb af en bil til lageret. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved køb af en bil til lageret. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:forlaengBil')
AddEventHandler('eske_leasing:ansat:forlaengBil', function(nummerplade, tid)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().name >= Config.jobname then
            MySQL.Async.execute("UPDATE eske_leasing_leased SET periode = periode+@tid, expire = expire+@expire WHERE nummerplade = @nummerplade", {
                ['@nummerplade'] = nummerplade,
                ['@tid'] = tid,
                ['@expire'] = 86400*tid
            }, function(...)
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu forlænget leasingaftalen ' .. nummerplade .. ' med ' .. tid .. ' dag.', length = 10000})
                PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." forlængede "..nummerplade.. " med " .. tid .. " dag." , tts = false}), { ['Content-Type'] = 'application/json' })
            end)
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Det er kun ansatte hos leasingfirmaet, som kan gøre dette.', length = 10000})
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved forlængelse af en bil. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved forlængelse af en bil. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:trakTilbage')
AddEventHandler('eske_leasing:ansat:trakTilbage', function(nummerplade)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().name >= Config.jobname then
            MySQL.Async.execute("UPDATE eske_leasing_leased SET expire = 1 WHERE nummerplade = @nummerplade", {
                ['@nummerplade'] = nummerplade,
            }, function(...)
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu trukket ' .. nummerplade .. ' tilbage.', length = 10000})
                PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." trak "..nummerplade.. " tilbage fra en kunde." , tts = false}), { ['Content-Type'] = 'application/json' })
            end)
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Det er kun ansatte hos leasingfirmaet, som kan gøre dette.', length = 10000})
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved tilbagetrækning af en bil. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved tilbagetrækning af en bil. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:skiftDisplay')
AddEventHandler('eske_leasing:ansat:skiftDisplay', function(gammeldisplay, nydisplay)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().name >= Config.jobname then
            MySQL.Async.execute("UPDATE eske_leasing_display SET model = @nydisplay WHERE model = @gammeldisplay", {
                ['@nydisplay'] = nydisplay,
                ['@gammeldisplay'] = gammeldisplay,
            }, function(...)
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu skiftet displaybilen ud med ' .. nydisplay, length = 10000})
                TriggerClientEvent('eske_leasing:displayBiler', -1)
                PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." skiftede en udstillingsbil: "..gammeldisplay.. " til " .. nydisplay .. "." , tts = false}), { ['Content-Type'] = 'application/json' })
            end)
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at skifte displaybilen ud.', length = 10000})
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved skift af display. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved skift af display. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:skiftYdelse')
AddEventHandler('eske_leasing:ansat:skiftYdelse', function(model, nyydelse)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.skiftydelse then
            if nyydelse > 0 then
                MySQL.Async.execute("UPDATE eske_leasing_cars SET ydelse = @ydelse WHERE model = @model", {
                    ['@ydelse'] = nyydelse,
                    ['@model'] = model,
                }, function(...)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu skiftet ydelsen på ' .. model .. ' til ' .. nyydelse .. ' DKK.', length = 10000})
                    PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." skiftede ydelsen på "..model.. " til " .. nyydelse .. " DKK." , tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            else
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du kan ikke sætte ydelsen til at være 0.', length = 10000})
                PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." forsøgte at sætte ydelsen på "..model.. " til " .. nyydelse .. " DKK." , tts = false}), { ['Content-Type'] = 'application/json' })
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at skifte ydelse på bilen.', length = 10000})
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved skift af ydelse. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved skift af ydelse. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:sendFaktura')
AddEventHandler('eske_leasing:ansat:sendFaktura', function(target, faktura, tekst)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)
    if xPlayer ~= nil and xTarget ~= nil then
        if faktura > 0 and faktura < 2000000 then
            if xPlayer.getJob().grade >= Config.faktura then
                MySQL.Async.execute("INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES(@identifier, @sender, @target_type, @target, @label, @amount)", {
                    ['@identifier'] = xTarget.identifier,
                    ['@sender'] = Config.firmanavn,
                    ['@target_type'] = 'society',
                    ['@target'] = Config.society,
                    ['@label'] = tekst,
                    ['@amount'] = faktura,
                }, function(...)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu sendt en faktura til ' .. xTarget.getName() .. ' på ' .. faktura .. ' DKK.', length = 10000})
                    TriggerClientEvent('mythic_notify:client:SendAlert', xTarget.source, { type = 'inform', text = 'Du har modtaget en faktura på ' .. faktura .. ' DKK fra ' .. Config.firmanavn, length = 10000})
                    PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." oprettede en faktura til "..xTarget.getName().. " på " .. faktura .. " DKK med teksten " .. tekst , tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            else
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at sende en faktura.', length = 10000})
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du kan ikke sende en faktura på ' .. faktura, length = 10000})
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved afsendelse af faktura. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved afsendelse af faktura. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:saelgBilFraLager')
AddEventHandler('eske_leasing:ansat:saelgBilFraLager', function(model)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        if xPlayer.getJob().grade >= Config.selglager then
            local bildata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_cars WHERE model = @model", {['@model'] = model})
            if bildata ~= nil then
                TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account) 
                    account.addMoney(bildata[1].indkobspris)
                    fjernBilFraLager(model)
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu solgt en ' .. model .. ' fra lageret for ' .. bildata[1].indkobspris .. ' DKK.', length = 10000})
                    print('[ESKE LEASING] Der er blevet solgt en ' .. model .. ' fra lageret.')
                    PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST', json.encode({content = xPlayer.getName().." solgte en "..model.. " fra lageret for " .. bildata[1].indkobspris .. " DKK." , tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            else
                print('[ESKE LEASING] Der skete en fejl ved salg af en bil fra lageret. Kontakt support. [2]')
                PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
                    local ip =  tostring(text)
                    PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved salg af bil fra lager. [2]', tts = false}), { ['Content-Type'] = 'application/json' })
                end)
            end
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Du har ikke tilladelse til at sælge en bil fra lageret.', length = 10000})
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved salg af bil fra lager. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved salg af bil fra lager. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

RegisterNetEvent('eske_leasing:ansat:leaseBil')
AddEventHandler('eske_leasing:ansat:leaseBil', function(model, tid, rabat, ydelse, valgtid, props, nummerplade)
    local xOwner = ESX.GetPlayerFromId(source)
    local xPlayer = ESX.GetPlayerFromId(valgtid)
    local endeligydelse = ydelse * (1 - (rabat/100))
    if xPlayer ~= nil then
        if xOwner ~= nil then
            if xOwner.getJob().name >= Config.jobname then
                if xPlayer.getAccount('bank').money >= endeligydelse then
                    MySQL.Async.execute("INSERT INTO eske_leasing_leased (model, nummerplade, periode, starttid, saelger, identifier, lastfetch, expire, ydelse) VALUES(@model, @nummerplade, @periode, @starttid, @saelger, @identifier, @lastfetch, @expire, @ydelse)", {
                        ['@model'] = model,
                        ['@nummerplade'] = nummerplade,
                        ['@periode'] = tid,
                        ['@starttid'] = os.time(),
                        ['@saelger'] = xOwner.getName(),
                        ['@identifier'] = xPlayer.identifier,
                        ['@lastfetch'] = os.time(),
                        ['@expire'] = os.time()+(tid*86400),
                        ['@ydelse'] = endeligydelse,
                    }, function(...)
                        if Config.t1ger_keys then
                            exports['t1ger_keys']:UpdateKeysToDatabase(props.plate, true)
                        end
                        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, date, model, name, leased) VALUES(@owner, @plate, @vehicle, @date, @model, @name, @leased)', {
                            ['@owner'] = xPlayer.identifier,
                            ['@plate'] = nummerplade,
                            ['@vehicle'] = json.encode(props),
                            ['@date'] = os.date("%Y-%m-%d"),
                            ['@model'] = model,
                            ['@name'] = 'Leasing Køretøj',
                            ['@leased'] = 1,
                        }, function(...)
                            fjernBilFraLager(model)
                            xPlayer.removeAccountMoney('bank', endeligydelse)
                            TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account) 
                                account.addMoney(endeligydelse)
                                TriggerClientEvent('mythic_notify:client:SendAlert', xOwner.source, { type = 'success', text = 'Du har nu leaset en ' .. model .. ' ud til en kunde.', length = 10000})
                                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'success', text = 'Du har nu leaset en ' .. model .. '. Husk at betale dine regninger.', length = 10000})
                                PerformHttpRequest('https://discord.com/api/webhooks/981578287576924256/nzrZcJvUx3t5IfHN_cEUGDnkoHNmao8C-AEO3ZsIt9aN72n7Mg7QVtz0bKo2P1ibdg54', function(err, text, headers) end, 'POST', json.encode({content = xOwner.getName().." leasede en "..model .. " til " ..xPlayer.getName().." med nummerpladen "..nummerplade.. " i " .. tid .. " dag(e) med ydelsen " .. ydelse .. " DKK med en rabat på " .. rabat .. '%.', tts = false}), { ['Content-Type'] = 'application/json' })
                            end)
                        end)
                    end)
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Kunden har ikke råd til første rate.', length = 10000})
                end
            else
                TriggerClientEvent('mythic_notify:client:SendAlert', xPlayer.source, { type = 'error', text = 'Det er kun ansatte hos leasingfirmaet, som kan gøre dette.', length = 10000})
            end
        else
            print('[ESKE LEASING] Der skete en fejl ved leasing af bil. Kontakt support. [2]')
            PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
                local ip =  tostring(text)
                PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved leasing af bil. [2]', tts = false}), { ['Content-Type'] = 'application/json' })
            end)
        end
    else
        print('[ESKE LEASING] Der skete en fejl ved leasing af bil. Kontakt support. [1]')
        PerformHttpRequest('http://api.ipify.org/', function(err, text, headers)
            local ip =  tostring(text)
            PerformHttpRequest(eskewebhook, function(err, text, headers) end, 'POST', json.encode({content = ip .. ' <> Der skete en fejl ved leasing af bil. [1]', tts = false}), { ['Content-Type'] = 'application/json' })
        end)
    end
end)

-- FUNKTIONER
function tilfojBilTilLager(model, pris)
    MySQL.Sync.execute("UPDATE eske_leasing_cars SET lager = lager + 1 WHERE model = @model", {['@model'] = model})
    if pris > 0 then
        TriggerEvent('esx_addonaccount:getSharedAccount', Config.society, function(account) 
            account.removeMoney(pris)
            print('[ESKE LEASING] Der er blevet fjernet ' .. pris .. ' DKK fra firmaet.')
        end)
    end
    print('[ESKE LEASING] Der er blevet tilføjet en ' .. model .. ' til lageret.')
end

function fjernBilFraLager(model)
    MySQL.Sync.execute("UPDATE eske_leasing_cars SET lager = lager - 1 WHERE model = @model", {['@model'] = model})
    print('[ESKE LEASING] Der er blevet fjernet en ' .. model .. ' fra lageret.')
end

-- THREADING
function sendRegningerTilKunder() 
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_leased")
    if rawdata ~= nil then
        for k,v in pairs(rawdata) do
            if os.time()-rawdata[k].lastfetch > 86400 then
                MySQL.Async.execute('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)', {
                    ['@identifier'] = rawdata[k].identifier,
                    ['@sender'] = Config.firmanavn,
                    ['@target_type'] = 'society',
                    ['@target'] = Config.society,
                    ['@label'] = 'Leasing Faktura',
                    ['@amount'] = rawdata[k].ydelse
                }, function(rowsChanged)
                    MySQL.Sync.execute('UPDATE eske_leasing_leased SET lastfetch = @lastfetch WHERE nummerplade = @plate', {
                        ['@lastfetch'] = os.time(),
                        ['@plate'] = rawdata[k].nummerplade,
                    }, function(rowsChanged)
                        print('[ESKE LEASING] Der er blevet sendt en regning til ' .. rawdata[k].owner .. ' for ' .. rawdata[k].ydelse .. ' DKK.')
                        PerformHttpRequest(Config.regningerwebhook, function(err, text, headers) end, 'POST', json.encode({content = "[AUTOMATISK] Der er blevet sendt en regning til " .. rawdata[k].owner .. " for " .. rawdata[k].ydelse .. " DKK.", tts = false}), { ['Content-Type'] = 'application/json' })
                    end)
                end)
            end
        end
    end
end

function returnerBiler() 
    local rawdata = MySQL.Sync.fetchAll("SELECT * FROM eske_leasing_leased")
    if rawdata ~= nil then
        for k, v in pairs(rawdata) do
            if rawdata[k].expire-os.time() < 0 then
                MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate', {
                    ['@plate'] = rawdata[k].nummerplade
                },function(...)
                    MySQL.Async.execute('DELETE FROM eske_leasing_leased WHERE nummerplade = @plate', {
                        ['@plate'] = rawdata[k].nummerplade
                    }, function(...)
                        tilfojBilTilLager(rawdata[k].model, 0)
                        print('[ESKE LEASING] Der er blevet returneret en ' .. rawdata[k].model .. ' fra ' .. rawdata[k].identifier .. '.')
                        PerformHttpRequest(Config.returwebhook, function(err, text, headers) end, 'POST', json.encode({content = "[AUTOMATISK] Der er blevet returneret en " .. rawdata[k].model .. " fra " .. rawdata[k].identifier .. ".", tts = false}), { ['Content-Type'] = 'application/json' })
                    end)
                end)
            end
        end
    end
end

Citizen.CreateThread(function()
    while true do
        sendRegningerTilKunder()
        returnerBiler()
        Citizen.Wait(1000)
    end
end)

AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('eske_leasing:displayBiler', xPlayer.source)
end)