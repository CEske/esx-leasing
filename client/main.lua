local ESX = nil

if Config.esx == 'event' then
	Citizen.CreateThread(function()
		while ESX == nil do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
			Citizen.Wait(0)
		end

		while ESX.GetPlayerData().job == nil do
			Citizen.Wait(100)
		end

		ESX.PlayerData = ESX.GetPlayerData()
	end)
else
	ESX = exports["es_extended"]:getSharedObject()
	ESX.PlayerData = ESX.GetPlayerData()
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	ESX.PlayerLoaded = false
	ESX.PlayerData = {}
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

------------------------------------------------------------------------------------

function seKatalog()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seKatalog", function(result)
		local elements = {
			head = {'Bil', 'Ydelse pr. dag'},
			rows = {}
		}

		for k, v in pairs(result) do
			local bilhash = GetHashKey(v.model)
			local bilnavn = GetDisplayNameFromVehicleModel(bilhash)
			table.insert(elements.rows, {
				data = result[k],
				cols = {
					bilnavn,
					v.ydelse .. ' DKK'
				}
			})
		end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_katalog', elements, function(data, menu)
			end, function(data, menu)
				menu.close()
		end)
	end)
end

function seLager()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seLager", function(result)
		local elements = {
			head = {'Model', 'Ydelse pr. dag', 'Indkøbspris', 'Klasse', 'Antal på lager'},
			rows = {}
		}

		for k, v in pairs(result) do
			table.insert(elements.rows, {
				data = result[k],
				cols = {
					v.model,
					v.ydelse,
					v.indkobspris .. ' DKK',
					'Klasse ' .. v.klasse,
					v.antal .. ' stk'
				}
			})
		end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_lager', elements, function(data, menu)
			end, function(data, menu)
				menu.close()
		end)
	end)
end

function koebBil()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seLager2", function(result)
		local elements = {
			head = {'Model', 'Indkøbspris', 'Handling'},
			rows = {}
		}

		for k, v in pairs(result) do
			table.insert(elements.rows, {
				data = result[k],
				cols = {
					v.model,
					v.indkobspris .. ' DKK',
					'{{Køb til lager|'..v.model..'}}'
				}
			})
		end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_koeb', elements, function(data, menu)
			local bil = data.data
			TriggerServerEvent('eske_leasing:ansat:kobBilTilLager', bil.model)
			ESX.UI.Menu.CloseAll()
			end, function(data, menu)
				menu.close()
		end)
	end)
end

function saelgBil()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seLager", function(result)
		local elements = {
			head = {'Model', 'Salgspris', 'Handling'},
			rows = {}
		}

		for k, v in pairs(result) do
			table.insert(elements.rows, {
				data = result[k],
				cols = {
					v.model,
					v.indkobspris .. ' DKK',
					'{{Sælg fra lager|'..v.model..'}}'
				}
			})
		end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_saelg', elements, function(data, menu)
			local bil = data.data
			TriggerServerEvent('eske_leasing:ansat:saelgBilFraLager', bil.model)
			ESX.UI.Menu.CloseAll()
			end, function(data, menu)
				menu.close()
		end)
	end)
end

function opretFaktura()
	ESX.UI.Menu.CloseAll()
    local keyboard, id, amount, bilag = exports["nh-keyboard"]:Keyboard({
        header = "Opret faktura", 
        rows = {"Spiller ID", "Beløb (DKK)", "Bilag"}
    })

    if keyboard then
        if tonumber(id) and tonumber(amount) and bilag ~= nil then
            TriggerServerEvent('eske_leasing:ansat:sendFaktura', tonumber(id), tonumber(amount), bilag)
        end
    end
end

function seLeasede()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seAftaler", function(result)
		local elements = {
			head = {'Sælger', 'Låner', 'Model', 'Dage tilbage', 'Betaling per dag', 'Startdato', 'Slutdato', 'Nummerplade', 'Handlinger'},
			rows = {}
		}

		for k, v in pairs(result) do
			table.insert(elements.rows, {
				data = result[k],
				cols = {
					v.saelger,
					v.identifier,
					v.model,
					v.aftalttid .. ' dag(e)',
					v.ydelse .. ' DKK',
					v.startdato,
					v.slutdato,
					v.nummerplade,
					'{{Forlæng med 1 dag|extend}} {{Træk tilbage|withdraw}}',
				}
			})
		end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_aftaler', elements, function(data, menu)
			local bil = data.data
			if data.value == 'extend' then
				TriggerServerEvent('eske_leasing:ansat:forlaengBil', bil.nummerplade, 1)
				ESX.UI.Menu.CloseAll()
			elseif data.value == 'withdraw' then
				TriggerServerEvent('eske_leasing:ansat:trakTilbage', bil.nummerplade)
				ESX.UI.Menu.CloseAll()
			end
			end, function(data, menu)
				menu.close()
		end)
	end)
end

function ansatMenu()
    ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_ansat', {
		title    = Config.firmanavn,
		align    = 'top-left',
		elements = {
			{label = 'Liste over leasede køretøjer', value = 'current'}, 
			{label = 'Opret faktura', value = 'faktura'},
			{label = 'Se lager', value = 'lager'},
		}
	}, function(data, menu)
		if data.current.value == 'current' then 
			seLeasede()
		elseif data.current.value == 'faktura' then
			opretFaktura()
		elseif data.current.value == 'lager' then
			seLager()
		end
      end, function(data, menu)
          menu.close()
    end)
end

--------------------------------------------------------------------------------------------------------

function leaseBil()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seLager", function(result)
		local elements = {
			head = {'Model', 'Betaling per dag', 'Klasse', 'Handlinger'},
			rows = {}
		}

		for k, v in pairs(result) do
			table.insert(elements.rows, {
				data = result[k],
				cols = {
					v.model,
					v.ydelse,
					v.klasse,
					'{{Vælg|extend}}'
				}
			})
		end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_leasebil', elements, function(data, menu)
			local spillere = getNearbyPlayers()
			local elements2 = {
				head = {'Vælg en spiller'},
				rows = {}
			}
			for a, b in pairs(spillere) do
				table.insert(elements2.rows, {
					data = spillere[a],
					cols = {
						'{{Vælg '.. b ..'|'.. b ..'}}'
					}
				})
			end
			local valgtmodel = data.data.model
			local valgtydelse = data.data.ydelse
			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_leasebil2', elements2, function(data2, menu2)
				local valgtspiller = data2.data
				ESX.UI.Menu.CloseAll()
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_leasebil3', {
					title    = 'Vælg leasing aftale',
					align    = 'top-left',
					elements = {
						{label = 'Ingen rabat', value = '0'}, 
						{label = '1% rabat', value = '1'}, 
						{label = '2% rabat', value = '2'}, 
						{label = '3% rabat', value = '3'}, 
						{label = '4% rabat', value = '4'}, 
						{label = '5% rabat', value = '5'}, 
						{label = 'Firma aftale 1 (15% rabat)', value = '15'},
						{label = 'Firma aftale 1 (25% rabat)', value = '25'},
						{label = 'Personale aftale (50% rabat)', value = '50'},
					}
				}, function(data3, menu3)
					local valgtrabat = data3.current.value
					ESX.UI.Menu.CloseAll()
					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_leasebil4', {
						title    = 'Vælg antal dage',
						align    = 'top-left',
						elements = {
							{label = '1 dag', value = '1'}, 
							{label = '2 dage', value = '2'}, 
							{label = '3 dage', value = '3'}, 
							{label = '4 dage', value = '4'}, 
							{label = '5 dage', value = '5'}, 
							{label = '6 dage', value = '6'}, 
							{label = '7 dage', value = '7'}, 
							{label = '8 dage', value = '8'}, 
							{label = '9 dage', value = '9'}, 
							{label = '10 dage', value = '10'}, 
						}
					}, function(data4, menu4)
						local valgttid = data4.current.value
						ESX.TriggerServerCallback('eske_leasing:kunde:raadTilLeasing', function(result)
							if result then
								ESX.Game.SpawnVehicle(valgtmodel, Config.spawnleased.pos, Config.spawnleased.h, function(vehicle)
									while not DoesEntityExist(vehicle) do Wait(200) end
									local plate = ProduceNumberPlate()
									if Config.t1ger_keys then
										exports['t1ger_keys']:SetVehicleLocked(vehicle, 0)
									else
										SetVehicleDoorsLocked(vehicle, 1)
									end
									SetEntityCoordsNoOffset(vehicle, Config.spawnleased.pos.x, Config.spawnleased.pos.y, Config.spawnleased.pos.z)
									SetVehicleOnGroundProperly(vehicle)
									local class = GetVehicleClass(vehicle)
									SetVehicleEngineOn(vehicle, true, false, false)
									SetEntityHeading(vehicle, Config.spawnleased.h)
									SetVehicleNumberPlateText(vehicle, plate)
									if Config.mf_inventory then
										TriggerServerEvent("inventory:registerVehicleInventory",plate,class,vehicle1)
									end
									local props = ESX.Game.GetVehicleProperties(vehicle)
									props.plate = plate
									TriggerServerEvent('eske_leasing:ansat:leaseBil', valgtmodel, valgttid, valgtrabat, valgtydelse, valgtspiller, props, plate)
									ESX.UI.Menu.CloseAll()
								end)
							end
						end, valgtydelse, valgtspiller)
					  end, function(data4, menu4)
						  menu4.close()
					end)
				  end, function(data3, menu3)
					  menu3.close()
				end)
				end, function(data2, menu2)
					menu2.close()
			end)
			end, function(data, menu)
				menu.close()
		end)
	end)
end

function skiftYdelse()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seLager", function(result)
		for k, v in pairs(result) do
			table.insert(elements, {
				label = v.model .. ' - ' .. v.ydelse .. ' DKK',
				value = v.model
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_skiftydelse', {
			title    = 'Skift ydelse',
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local keyboard, amount = exports["nh-keyboard"]:Keyboard({
				header = "Skift ydelse på " .. data.current.value, 
				rows = {"Betaling per dag (DKK)"}
			})
		
			if keyboard then
				if tonumber(amount) and tonumber(amount) ~= nil then
					ESX.UI.Menu.CloseAll()
					TriggerServerEvent('eske_leasing:ansat:skiftYdelse', data.current.value, tonumber(amount))
				end
			end
		end, function(data, menu)
			  menu.close()
		end)
	end)
end

function tagBil()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	ESX.TriggerServerCallback("eske_leasing:seKatalog", function(result)
		for k, v in pairs(result) do
			table.insert(elements, {
				label = v.model,
				value = v.model
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_skiftydelse', {
			title    = 'Vælg prøvebil',
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			ESX.UI.Menu.CloseAll()
			ESX.Game.SpawnVehicle(data.current.value, Config.spawntry.pos, Config.spawntry.h, function(vehicle)
				while not DoesEntityExist(vehicle) do Wait(200) end
				local plate = 'PRØVE'
				if Config.t1ger_keys then
					exports['t1ger_keys']:SetVehicleLocked(vehicle, 0)
				else
					SetVehicleDoorsLocked(vehicle, 1)
				end
				SetEntityCoordsNoOffset(vehicle, Config.spawntry.pos.x, Config.spawntry.pos.y, Config.spawntry.pos.z)
				SetVehicleOnGroundProperly(vehicle)
				local class = GetVehicleClass(vehicle)
				SetVehicleEngineOn(vehicle, true, false, false)
				SetEntityHeading(vehicle, Config.spawntry.h)
				SetVehicleNumberPlateText(vehicle, plate)
			end)
		end, function(data, menu)
			  menu.close()
		end)
	end)
end

function skiftDisplay()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	local elements2 = {} 
	ESX.TriggerServerCallback('eske_leasing:kunde:seDisplay', function(result)
		for k,v in pairs(result) do
			table.insert(elements, {
				label = v.model,
				value = v.model
			})
		end
		ESX.TriggerServerCallback("eske_leasing:seLager", function(result2)
			for k, v in pairs(result2) do
				table.insert(elements2, {
					label = v.model,
					value = v.model
				})
			end
	
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_skiftdisplay', {
				title    = 'Hvilken bil skal skiftes',
				align    = 'top-left',
				elements = elements
			}, function(data, menu)
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_skiftdisplay2', {
					title    = 'Hvilken bil skal stå der istedet',
					align    = 'top-left',
					elements = elements2
				}, function(data2, menu2)
					ESX.UI.Menu.CloseAll()
					TriggerServerEvent('eske_leasing:ansat:skiftDisplay', data.current.value, data2.current.value)
				end, function(data2, menu2)
					  menu2.close()
				end)
			end, function(data, menu)
				  menu.close()
			end)
		end)
	end)
end

function leaseUd()
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_leaseud', {
		title    = Config.firmanavn,
		align    = 'top-left',
		elements = {
			{label = 'Lease køretøj ud', value = 'lease'}, 
			{label = 'Skift ydelse', value = 'ydelse'},
			{label = 'Skift udstillingsbiler', value = 'display'},
			{label = 'Tag lånebil', value = 'laanebil'},
		}
	}, function(data, menu)
		if data.current.value == 'lease' then 
			leaseBil()
		elseif data.current.value == 'ydelse' then
			skiftYdelse()
		elseif data.current.value == 'display' then
			skiftDisplay()
		elseif data.current.value == 'laanebil' then
			tagBil()
		end
    end, function(data, menu)
          menu.close()
    end)
end

--------------------------

function currentAnsatte()
	ESX.UI.Menu.CloseAll()
	ESX.TriggerServerCallback('eske_leasing:boss:seAnsatte', function(result)
        if result ~= nil then
            local elements = {
                head = {'Navn', 'Nummer', 'Grad', 'Handlinger'},
                rows = {}
            }
    
            for k, v in pairs(result) do
                table.insert(elements.rows, {
                    data = result[k],
                    cols = {
                        v.navn,
                        v.nummer,
						v.grade,
                        '{{Skift rangering|skift}} {{Fjern|fjern}}'
                    }
                })
            end
            ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_admpersonalle', elements, function(data, menu)
                local spiller = data.data
                if data.value == 'skift' then
                    ESX.UI.Menu.CloseAll()
                    ESX.TriggerServerCallback('eske_leasing:boss:seRanks', function(result)
                        local elements = {}
                        for k, v in pairs(result) do
                            table.insert(elements, {
                                label = v.rangering, value = v.grade
							})
                        end
                        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_admpersonalle2', {
                            title    = Config.firmanavn,
                            align    = 'top-left',
                            elements = elements
                        }, function(data2, menu2)
                            ESX.UI.Menu.CloseAll()
                            TriggerServerEvent('eske_leasing:boss:skiftRangering', spiller.identifier, data2.current.value)
                          end, function(data2, menu2)
                              menu2.close()
                        end)
                    end, gang)
                elseif data.value == 'fjern' then
                    ESX.UI.Menu.CloseAll()
                    TriggerServerEvent('eske_leasing:boss:fjernMedlem', spiller.identifier)
                end
                end, function(data, menu)
                    menu.close()
            end)
        end
	end)
end

function nyMedarbejder()
    ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('eske_leasing:boss:seSpillere', function(result)
        local elements = {
            head = {'Vælg en spiller'},
            rows = {}
        }
        for a, b in pairs(result) do
            table.insert(elements.rows, {
                data = result[a],
                cols = {
                    '{{'..b.id..'|'.. b.id ..'}}'
                }
            })
        end
		ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'eske_leasing_nyansat', elements, function(data, menu)
            local spiller = data.data
            ESX.UI.Menu.CloseAll()
            TriggerServerEvent('eske_leasing:boss:tilføjMedlem', spiller.id)
        end, function(data, menu)
            menu.close()
        end)
    end)
end

function admPersonale()
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_personale1', {
		title    = Config.firmanavn,
		align    = 'top-left',
		elements = {
			{label = 'Se nuværende personale', value = 'currentAnsatte'}, 
			{label = 'Ansæt ny medarbejder', value = 'ny'},
		}
	}, function(data, menu)
		if data.current.value == 'currentAnsatte' then 
			currentAnsatte()
		elseif data.current.value == 'ny' then
			nyMedarbejder()
		end
    end, function(data, menu)
          menu.close()
    end)
end

function admKasse()
	ESX.UI.Menu.CloseAll()
    ESX.TriggerServerCallback('eske_leasing:boss:firmaKasse', function(result)
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_firmakasse', {
            title    = Config.firmanavn,
            align    = 'top-left',
            elements = {
                {label = format_thousand(result) .. ' DKK', value = 'nothing'}, 
                {label = 'Læg penge i kassen', value = 'læg'},
                {label = 'Tag penge fra kassen', value = 'tag'}
            }
        }, function(data, menu)
            if data.current.value == 'læg' then 
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'eske_leasing_firmakasse1', {
                    title = 'Tilføj penge til ' .. Config.firmanavn
                }, function(data2, menu2)
                    local amount = tonumber(data2.value)

                    if amount == nil then
                        ESX.ShowNotification(_U('invalid_amount'))
                    else
                        ESX.UI.Menu.CloseAll()
                        TriggerServerEvent('eske_leasing:boss:tilføjPenge', amount)
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            elseif data.current.value == 'tag' then
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'eske_leasing_firmakasse2', {
                    title = 'Tag penge fra ' .. Config.firmanavn
                }, function(data2, menu2)
                    local amount = tonumber(data2.value)

                    if amount == nil then
                        ESX.ShowNotification(_U('invalid_amount'))
                    else
                        ESX.UI.Menu.CloseAll()
                        TriggerServerEvent('eske_leasing:boss:fjernPenge', amount)
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            end
          end, function(data, menu)
              menu.close()
        end)
    end, gang)
end

function admLager()
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_bossmenu', {
		title = Config.firmanavn,
		align = 'top-left',
		elements = {
			{label = 'Køb køretøjer til lager', value = 'koeb'},
			{label = 'Sælg køretøjer fra lager', value = 'saelg'},
		}
	}, function(data, menu)
		if data.current.value == 'koeb' then
			koebBil()
		elseif data.current.value == 'saelg' then
			saelgBil()
		end
    end, function(data, menu)
          menu.close()
    end)
end

function bossMenu()
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'eske_leasing_bossmenu', {
		title = Config.firmanavn,
		align = 'top-left',
		elements = {
			{label = 'Administrer personale', value = 'personale'},
			{label = 'Administrer firmakasse', value = 'kasse'},
			{label = 'Administrer beholdning', value = 'lager'},
		}
	}, function(data, menu)
		if data.current.value == 'personale' then 
			admPersonale()
		elseif data.current.value == 'kasse' then
			admKasse()
		elseif data.current.value == 'lager' then
			admLager()
		end
    end, function(data, menu)
          menu.close()
    end)
end

--------------------------
AddEventHandler('eske_leasing:displayBiler')
RegisterNetEvent('eske_leasing:displayBiler', function()
	ESX.TriggerServerCallback('eske_leasing:kunde:seDisplay', function(result)
		for i=1, #Config.display, 1 do
			local vehCache = getClosestVehicle(vector3(Config.display[i].pos.x,Config.display[i].pos.y,Config.display[i].pos.z))
			DeleteEntity(vehCache)
			local hashkey = GetHashKey(result[i].model)
			RequestModel(result[i].model); while not HasModelLoaded(result[i].model) do Citizen.Wait(1) end
			local vehicle = CreateVehicle(hashkey, Config.display[i].pos.x,Config.display[i].pos.y,Config.display[i].pos.z, Config.display[i].h, false, false)
			SetVehicleOnGroundProperly(vehicle)
			SetVehicleFuelLevel(vehicle, 0)
			if Config.t1ger_keys then
				exports['t1ger_keys']:SetVehicleLocked(vehicle, 1)
			else
				SetVehicleDoorsLocked(vehicle, 2)
			end
			SetEntityCoordsNoOffset(vehicle, Config.display[i].pos.x, Config.display[i].pos.y, Config.display[i].pos.z)
			SetVehicleNumberPlateText(vehicle, 'PRØVE')
		end
	end)
end)

function ProduceNumberPlate()
	local plate = nil
	local found_plate = false
	
	while not found_plate do
		Citizen.Wait(1)
		math.randomseed(GetGameTimer())
		if Config.mellemrum then
			plate = string.upper(GetRandomLetter(2).." "..GetRandomNumber(5))
		else
			plate = string.upper(GetRandomLetter(2)..""..GetRandomNumber(5))
		end

		ESX.TriggerServerCallback('eske_leasing:backend:findNummerplade', function (inUse)
			if not inUse then
				found_plate = true
			end
		end, plate)

		if found_plate then break end
	end

	return plate
end

local NumChar = {}
local LetChar = {}
for i = 48,  57 do table.insert(NumChar, string.char(i)) end
for i = 65,  90 do table.insert(LetChar, string.char(i)) end
for i = 97, 122 do table.insert(LetChar, string.char(i)) end
-- Function to generate random numbers:
function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumChar[math.random(1, #NumChar)]
	else
		return ''
	end
end

-- Function to generate random letters:
function GetRandomLetter(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. LetChar[math.random(1, #LetChar)]
	else
		return ''
	end
end

function getClosestVehicle(pos)
    local closestVeh = StartShapeTestCapsule(pos, pos, 1.0, 10, 0, 7)
    local a, b, c, d, entityHit = GetShapeTestResult(closestVeh)
	if entityHit == 0 then
		entityHit = GetClosestVehicle(pos.x, pos.y, pos.z, 1.0, 0, 70)
	end
    return entityHit
end

local nearbyPlayersMatch = function(t1,t2)
	for k1,v1 in ipairs(t1) do
	  local matched = false
  
	  for k2,v2 in ipairs(t2) do
		if v1 == v2 then
		  matched = true
		  break
		end
	  end
  
	  if not matched then
		return true
	  end
	end
  
	for k1,v1 in ipairs(t2) do
	  local matched = false
  
	  for k2,v2 in ipairs(t1) do
		if v1 == v2 then
		  matched = true
		  break
		end
	  end
  
	  if not matched then
		return true
	  end
	end
  
	return false
  end

function getNearbyPlayers(curPlayers)
	local didChange
	local nearbyPlayers = {}
  
	local player  = PlayerId()
	local pos     = GetEntityCoords(PlayerPedId())  
	local players = GetActivePlayers()    
  
	for k,v in pairs(players) do
	  if v ~= player then
		local ped = GetPlayerPed(v)
		if ped > 0 and DoesEntityExist(ped) then
		  local pedPos = GetEntityCoords(ped)
		  if (pedPos.x ~= 0.0 or pedPos.y ~= 0.0 or pedPos.z ~= 0.0) then
			local dist = #(pedPos - pos)
			if dist <= 4.0 then
			  table.insert(nearbyPlayers,{
				distance = dist,
				player = v
			  })
			end
		  end
		end
	  end
	end
  
	table.sort(nearbyPlayers,function(a,b)
	  return a.distance < b.distance
	end)
  
	for i=1,#nearbyPlayers do
	  nearbyPlayers[i] = GetPlayerServerId(nearbyPlayers[i].player)
	end
  
	if (not curPlayers  and #nearbyPlayers  == 0)
	or (curPlayers      and #curPlayers     == 0    and #nearbyPlayers == 0) 
	then
	  didChange = false
	else    
	  didChange = nearbyPlayersMatch(nearbyPlayers,curPlayers or {})
	end
  
	return nearbyPlayers,didChange
end

-- THREADING
Citizen.CreateThread(function()
	blip = AddBlipForCoord(Config.blip.pos.x, Config.blip.pos.y, Config.blip.pos.z)
    SetBlipSprite(blip, Config.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, Config.blip.farve)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.blip.tekst)
    EndTextCommandSetBlipName(blip)
end)

-- TARGET
local player
local vehicle
local curVehicle
Citizen.CreateThread(function()
	while true do
		Targets()
		player = PlayerPedId()
		vehicle = GetVehiclePedIsIn(player, false)
		if vehicle then
			curVehicle = GetVehiclePedIsIn(player, false)
		end
		Citizen.Wait(5000)
	end
end)

function Targets()
    if ESX.IsPlayerLoaded() then
        if ESX.PlayerData.job.name == Config.jobname then
			if ESX.PlayerData.job.grade >= Config.chefgrade then
				for key, v in pairs(Config.targets) do
					if Config.Target == 'ft' then
						exports['fivem-target']:RemoveTargetPoint("ZalikBoss")
						exports['fivem-target']:AddTargetPoint({
							name = "ZalikMenu",
							label = Config.firmanavn,
							icon = "fas fa-folder",
							point = vector3(v.x, v.y, v.z),
							interactDistance = 2.5,
							onInteract = ZalikMenu,
							options = {
								{
									name = "ZalikAnsat",
									label = "Åben ansatmenu"
								},
								{
									name = "ZalikLeasing",
									label = "Åben leasingmenu"
								},
								{
									name = "ZalikChef",
									label = "Åben chefmenu"
								},
							},
						})
					else
						exports.qtarget:RemoveZone(key .. 'boss1')
						exports.qtarget:AddBoxZone(key .. 'boss1', vector3(v.x, v.y, v.z), 0.45, 0.35, {
							name=key .. 'boss1',
							heading=11.0,
							debugPoly=false,
							minZ=v.z-1.5,
							maxZ=v.z,
							}, {
								options = {
									{
										icon = "fas fa-folder",
										label = "Åben ansatmenu",
										action = function() ansatMenu() end
									},
									{
										icon = "fas fa-folder",
										label = "Åben leasingmenu",
										action = function() leaseUd() end
									},
									{
										icon = "fas fa-folder",
										label = "Åben chefmenu",
										action = function() bossMenu() end
									}
								},
								distance = 3.5
						})
					end
				end
			else
				for key, v in pairs(Config.targets) do
					if Config.Target == 'ft' then
						exports['fivem-target']:RemoveTargetPoint("ZalikBoss")
						exports['fivem-target']:AddTargetPoint({
							name = "ZalikMenu",
							label = Config.firmanavn,
							icon = "fas fa-folder",
							point = vector3(v.x, v.y, v.z),
							interactDistance = 2.5,
							onInteract = ZalikMenu,
							options = {
								{
									name = "ZalikAnsat",
									label = "Åben ansatmenu"
								},
								{
									name = "ZalikLeasing",
									label = "Åben leasingmenu"
								}
							},
						})
					else
						exports.qtarget:RemoveZone(key .. 'boss')
						exports.qtarget:AddBoxZone(key .. 'boss', vector3(v.x, v.y, v.z), 0.45, 0.35, {
							name=key .. 'boss',
							heading=11.0,
							debugPoly=false,
							minZ=v.z-1.5,
							maxZ=v.z,
							}, {
								options = {
									{
										icon = "fas fa-folder",
										label = "Åben ansatmenu",
										action = function() ansatMenu() end
									},
									{
										icon = "fas fa-folder",
										label = "Åben leasingmenu",
										action = function() leaseUd() end
									}
								},
								distance = 3.5
						})
					end
				end
			end
			if Config.Target == 'ft' then
				exports['fivem-target']:RemoveTargetPoint("ZalikTryCar")
				exports['fivem-target']:AddTargetPoint({
					name = "ZalikTryCar",
					label = "Fjern bil",
					icon = "fas fa-car",
					point = vector3(Config.spawntry.pos.x, Config.spawntry.pos.y, Config.spawntry.pos.z),
					interactDistance = 2.5,
					onInteract = ZalikTryCar,
					options = {
						{
							name = "ZalikTryCar",
							label = "Fjern prøvebil"
						},
					},
				})
			else
				exports.qtarget:RemoveZone("FjernBil")
				exports.qtarget:AddBoxZone("FjernBil", vector3(Config.spawntry.pos.x, Config.spawntry.pos.y, Config.spawntry.pos.z), 0.45, 0.35, {
					name="FjernBil",
					heading=11.0,
					debugPoly=false,
					minZ=Config.spawntry.pos.z-2,
					maxZ=Config.spawntry.pos.z,
					}, {
						options = {
							{
								icon = "fas fa-folder",
								label = "Fjern prøvebil",
								action = function() removeCar() end
							},
						},
						distance = 3.5
				})
			end
		end
		if Config.Target == 'ft' then
			exports['fivem-target']:RemoveTargetPoint("ZalikKatalog")
			exports['fivem-target']:AddTargetPoint({
				name = "ZalikKatalog",
				label = "Se katalog",
				icon = "fas fa-car",
				point = vector3(Config.katalog.pos.x, Config.katalog.pos.y, Config.katalog.pos.z),
				interactDistance = 2.5,
				onInteract = ZalikKatalog,
				options = {
					{
						name = "ZalikKatalog",
						label = "Se leasing kataloget"
					},
				},
			})
		else
			exports.qtarget:RemoveZone("Katalog")
			exports.qtarget:AddBoxZone("Katalog", vector3(Config.katalog.pos.x, Config.katalog.pos.y, Config.katalog.pos.z), 0.35, 0.8, {
				name="Katalog",
				heading=24.3883,
				debugPoly=false,
				minZ=Config.katalog.pos.z-2,
				maxZ=Config.katalog.pos.z+1.5,
				}, {
					options = {
						{
							icon = "fas fa-car",
							label = "Se katalog",
							action = function() seKatalog() end
						},
					},
					distance = 3.5
			})
		end
    end
end

function ZalikKatalog(targetName,optionName,vars,entityHit)
	if optionName == "ZalikKatalog" then
		ESX.UI.Menu.CloseAll()
		seKatalog()
	end
end

function ZalikMenu(targetName,optionName,vars,entityHit)
	if ESX.PlayerData.job.name == Config.jobname then
		if optionName == "ZalikAnsat" then
			ESX.UI.Menu.CloseAll()
			ansatMenu()
		elseif optionName == "ZalikLeasing" then
			ESX.UI.Menu.CloseAll()
			leaseUd()
		elseif optionName == "ZalikChef" then
			ESX.UI.Menu.CloseAll()
			bossMenu()
		end
	end
end

function ZalikTryCar(targetName,optionName,vars,entityHit)
    if ESX.PlayerData.job.name == Config.jobname then
        if optionName == "ZalikTryCar" then
            ESX.UI.Menu.CloseAll()
            TaskLeaveVehicle(player, curVehicle, 4160)
            SetVehicleDoorsLockedForAllPlayers(curVehicle, true)
            Citizen.Wait(2000)
            ESX.Game.DeleteVehicle(curVehicle)
        end
    end
end

function removeCar()
	ESX.UI.Menu.CloseAll()
	TaskLeaveVehicle(player, curVehicle, 4160)
	SetVehicleDoorsLockedForAllPlayers(curVehicle, true)
	Citizen.Wait(2000)
	ESX.Game.DeleteVehicle(curVehicle)
end

-- funktioner
function format_thousand(v)
    if not v then v = 0 end
    v = tonumber(v)
    if v > 999 then
        local s = string.format("%d", math.floor(v))
        local pos = string.len(s) % 3
        if pos == 0 then pos = 3 end
        return string.sub(s, 1, pos)
        .. string.gsub(string.sub(s, pos+1), "(...)", ".%1")
    else
        return v
    end
end
