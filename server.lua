local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRPcs = {}
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vRP_casino")
vRPCasinoC = Tunnel.getInterface("vRP_casino","vRP_casino")
Tunnel.bindInterface("vRP_casino",vRPcs)

rouletteBetters = {}
slotMachinesBetters = {}
barbutPlayers = {}

rouletteBets = {
	{"Green", "Bet on <font color='green'>Green</font><br>Chance: <font color='red'>2.7%</font><br>Winnings: <font color='yellow'>x14</font>", 14, 0},
	{"Red", "Bet on <font color='red'>Red</font><br>Chance: <font color='green'>48.65%</font><br>Winnings: <font color='yellow'>x2</font>", 2, 1},
	{"Black", "Bet on <font color='grey'>Black</font><br>Chance: <font color='green'>48.65%</font><br>Multiplicador: <font color='yellow'>x2</font>", 2, 2}
}

tokenDealer = {
	{924.5140991211, -943.33154296875, 43.85},
	{924.35131835938, -942.13037109375,43.3}
}

barbutDealer = {
	{920.97149658204, -950.31079101562, 43.85},
	{920.98846435546, -957.63934326172, 43.85},
	{918.37469482422, -955.56658935546, 43.5},
	{918.54296875, -948.12005615234, 43.3}
}

roulettes = {
	{924.38452148438, -947.25469970704, 43.85},
	{924.28399658204, -954.68328857422, 43.85}
}

local casinoCasier_menu = {name="Caixa do Casino",css={top="75px", header_color="rgba(0,125,255,0.8)"}}
local casinoRoulette_menu = {name="Roleta",css={top="75px", header_color="rgba(0,125,255,0.8)"}}
local casinoBarbut_menu = {name="Dados",css={top="75px", header_color="rgba(0,125,255,0.8)"}}
local casinoBarbut1v1_menu = {name="Dados 1v1",css={top="75px", header_color="rgba(0,125,255,0.8)"}}

function round(x, n)
    n = math.pow(10, n or 0)
    x = x * n
    if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
    return x / n
end

casinoBarbut1v1_menu["🎲Create Craps Table🎲"] = {function(player, choice)
	local user_id = vRP.getUserId({player})
	if((barbutPlayers[user_id].oponent == 0) and (barbutPlayers[user_id].cota == 0)) or (barbutPlayers[user_id] == nil) then
		vRP.prompt({player, "Stake:", "Amount of Chips that each player should bet.", function(player, chips)
			if(chips ~= "" and chips ~= nil)then
				if(tonumber(chips))then
					chips = tonumber(chips)
					if(chips > 0) and (chips <= 100)then
						if vRP.tryGetInventoryItem({user_id,"casino_token",chips,false}) then
							barbutPlayers[user_id] = {oponent = 0, cota = chips}
							vRPclient.notify(player, {"[CASINO] ~g~You created a Crap Table with a stake of ~y~"..chips.." Chips"})
							vRPclient.notify(player, {"[CASINO] ~g~Wait for an opponent!"})
							vRP.closeMenu({player})
							SetTimeout(18000, function()
								if(barbutPlayers[user_id].cota ~= 0)then
									vRPclient.notify(player, {"[CASINO] ~r~The table was closed! No opponent found!"})
									barbutPlayers[user_id] = {oponent = 0, cota = 0}
									casinoBarbut1v1_menu[GetPlayerName(player)] = nil
									vRP.giveInventoryItem({user_id,"casino_token",chips,false})
								end
							end)

							casinoBarbut1v1_menu[GetPlayerName(player)] = {function(thePlayer, choice)
								local pID = vRP.getUserId({thePlayer})
								if(pID == user_id)then
									vRPclient.notify(thePlayer, {"[CASINO] ~r~You're already on a table, wait for an opponent."})
								else
									if(barbutPlayers[pID].cota ~= 0) and (barbutPlayers[pID].oponent == 0)then
										if vRP.tryGetInventoryItem({pID,"casino_token",chips,false}) then
											casinoBarbut1v1_menu[GetPlayerName(player)] = nil
											vRPclient.notify(thePlayer, {"[CASINO] ~g~You entered ~r~"..GetPlayerName(player).."'s table. Throw the dices!"})
											vRPclient.notify(player, {"[CASINO] ~r~"..GetPlayerName(thePlayer).." ~g~entered your table!"})
											vRP.closeMenu({thePlayer})
											barbutPlayers[user_id] = {oponent = pID, cota = chips}
											vRPcs.doBarbut1v1(player)
										end
									else
										vRPclient.notify(thePlayer, {"[CASINO] ~r~That table has already closed!"})
									end
								end
							end, "Opponent: <font color='red'>"..GetPlayerName(player).." ["..user_id.."]</font><br>Bet: <font color='green'>"..chips.." Chips</font><br>Winnings: <font color='green'>"..(chips*2).." Chips</font>"}
						else
							vRPclient.notify(player, {"[CASINO] ~r~You don't have enough Chips!"})
						end
					else
						vRPclient.notify(player, {"[CASINO] ~r~The max bet allowed is 100 Chips!"})
					end
				else
					vRPclient.notify(player, {"[CASINO] ~r~You must enter an amount of Chips!"})
				end
			else
				vRPclient.notify(player, {"[CASINO] ~r~You must enter the number of Chips!"})
			end
		end})
	else
		vRPclient.notify(player, {"[CASINO] ~r~You already have a table opened! Wait for an opponent!"})
	end
end, "Create a 'Craps' Table to play against an opponent."}

casinoBarbut_menu["Dados"] = {function(player, choice)
	local user_id = vRP.getUserId({player})
	if(user_id ~= nil and user_id ~= "")then
		vRP.prompt({player, "Stake:", "", function(player, tokenNr)
			if(tokenNr ~= "" and tokenNr ~= nil)then
				if(tonumber(tokenNr))then
					tokenNr = tonumber(tokenNr)
					if(tokenNr > 0) and (tokenNr <= 100)then
						if vRP.tryGetInventoryItem({user_id,"casino_token",tokenNr,false}) then
							vRP.closeMenu({player})
							local whoIsFirst = math.random(1, 2)
							local brokerRoll = math.random(1, 6)
							local brokerRoll2 = math.random(1, 6)
							local playerRoll = math.random(1, 6)
							local playerRoll2 = math.random(1, 6)
							local totalBroker = tonumber(brokerRoll + brokerRoll2)
							local totalPlayer = tonumber(playerRoll + playerRoll2)
							if(whoIsFirst == 1)then
								SetTimeout(1000, function()
									vRPclient.notify(player, {"[CASINO] ~g~Dealer's Hand:\n~p~(~y~"..brokerRoll.."~r~ , ~y~"..brokerRoll2.."~p~) ~b~("..totalBroker..")"})
									SetTimeout(1000, function()
										vRPclient.notify(player, {"[CASINO] ~g~Your Hand:\n~p~(~y~"..playerRoll.."~r~ , ~y~"..playerRoll2.."~p~) ~b~("..totalPlayer..")"})
										if(totalBroker < totalPlayer)then
											vRPclient.notify(player, {"[CASINO] ~g~You won ~y~"..(tokenNr*2).." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr*2,false})
										elseif(totalPlayer < totalBroker)then
											vRPclient.notify(player, {"[CASINO] ~r~You lost, better luck next time!"})
										elseif((brokerRoll == playerRoll) and (brokerRoll2 == playerRoll2))then
											vRPclient.notify(player, {"[CASINO] ~g~This Hand was a draw! You got back ~y~"..tokenNr.." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr,false})
										elseif((brokerRoll == playerRoll2) and (brokerRoll2 == playerRoll))then
											vRPclient.notify(player, {"[CASINO] ~g~This Hand was a draw! You got back ~y~"..tokenNr.." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr,false})
										elseif (totalPlayer == totalBroker)then
											vRPclient.notify(player, {"[CASINO] ~g~This Hand was a draw! You got back ~y~"..tokenNr.." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr,false})
										end
									end)
								end)
							else
								SetTimeout(1000, function()
									vRPclient.notify(player, {"[CASINO] ~g~Your Hand:\n~p~(~y~"..playerRoll.."~r~ , ~y~"..playerRoll2.."~p~) ~b~("..totalPlayer..")"})
									SetTimeout(1000, function()
										vRPclient.notify(player, {"[CASINO] ~g~Dealer's Hand:\n~p~(~y~"..brokerRoll.."~r~ , ~y~"..brokerRoll2.."~p~) ~b~("..totalBroker..")"})
										if(totalBroker < totalPlayer)then
											vRPclient.notify(player, {"[CASINO] ~g~You won ~y~"..(tokenNr*2).." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr*2,false})
										elseif(totalPlayer < totalBroker)then
											vRPclient.notify(player, {"[CASINO] ~r~You lost, better luck next time!"})
										elseif((brokerRoll == playerRoll) and (brokerRoll2 == playerRoll2))then
											vRPclient.notify(player, {"[CASINO] ~g~This Hand was a draw! You got back ~y~"..tokenNr.." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr,false})
										elseif((brokerRoll == playerRoll2) and (brokerRoll2 == playerRoll))then
											vRPclient.notify(player, {"[CASINO] ~g~This Hand was a draw! You got back ~y~"..tokenNr.." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr,false})
										elseif (totalPlayer == totalBroker)then
											vRPclient.notify(player, {"[CASINO] ~g~This Hand was a draw! You got back ~y~"..tokenNr.." Chips"})
											vRP.giveInventoryItem({user_id,"casino_token",tokenNr,false})
										end
									end)
								end)
							end
						else
							vRPclient.notify(player, {"[CASINO] ~r~You don't have enough Chips!"})
						end
					else
						vRPclient.notify(player, {"[CASINO] ~r~The max bet allowed is 100 Chips!"})
					end
				else
					vRPclient.notify(player, {"[CASINO] ~r~You must enter an amount of Chips!"})
				end
			else
				vRPclient.notify(player, {"[CASINO] ~r~You must enter the number of Chips!"})
			end
		end})
	end
end, "Play 'Craps' against the Dealer."}

for i, v in pairs(rouletteBets) do
	casinoRoulette_menu[v[1]] = {function(player, choice)
		local user_id = vRP.getUserId({player})
		if(user_id ~= nil and user_id ~= "")then
			if(rouletteBetters[user_id] ~= nil)then
				vRPclient.notify(player, {"[CASINO] ~r~You're already playing on roulette!"})
			else
				vRP.prompt({player, "Aposta:", "", function(player, tokenNr)
					if(tokenNr ~= "" and tokenNr ~= nil)then
						if(tonumber(tokenNr))then
							tokenNr = tonumber(tokenNr)
							if(tokenNr > 0) and (tokenNr <= 100)then
								if vRP.tryGetInventoryItem({user_id,"casino_token",tokenNr,false}) then
									if(v[4] == 1)then
										vRPCasinoC.startRoulette(player, {"Red", tokenNr, 2})
										vRPclient.notify(player, {"[CASINO] ~g~Bet ~y~"..tokenNr.." Chips ~g~on ~r~Red"})
									elseif(v[4] == 2)then
										vRPCasinoC.startRoulette(player, {"Black", tokenNr, 2})
										vRPclient.notify(player, {"[CASINO] ~g~Bet ~y~"..tokenNr.." Chips ~g~on ~c~Black"})
									elseif(v[4] == 0)then
										vRPCasinoC.startRoulette(player, {"Green", tokenNr, 14})
										vRPclient.notify(player, {"[CASINO] ~g~Bet ~y~"..tokenNr.." Chips ~g~on ~b~Green"})
									end
									rouletteBetters[user_id] = true
								else
									vRPclient.notify(player, {"[CASINO] ~r~You don't have enough Chips!"})
								end
							else
								vRPclient.notify(player, {"[CASINO] ~r~The max bet allowed is 100 Chips!"})
							end
						else
							vRPclient.notify(player, {"[CASINO] ~r~You must enter an amount of Chips!"})
						end
					else
						vRPclient.notify(player, {"[CASINO] ~r~You must enter the number of Chips!"})
					end
				end})
			end
		end
	end, v[2]}
end

casinoCasier_menu["Buy Chips"] = {function(player, choice)
	local user_id = vRP.getUserId({player})
	if(user_id ~= nil and user_id ~= "")then
		vRP.prompt({player, "Buy Chips:", "1 Chip = 50.000E", function(player, tokenNr)
			if(tokenNr ~= "" and tokenNr ~= nil)then
				if(tonumber(tokenNr))then
					tokenNr = tonumber(tokenNr)
					if(tokenNr > 0) and (tokenNr <= 200)then
						local totalPrice = tokenNr * 50000
						if(vRP.tryPayment({user_id, totalPrice}))then
							vRPclient.notify(player, {"[CASINO] ~g~Paid ~r~"..totalPrice.."E ~g~for ~y~"..tokenNr.." Chips"})
							vRP.giveInventoryItem({user_id,"casino_token",tokenNr,false})
							vRP.closeMenu({player})
						else
							vRPclient.notify(player, {"[CASINO] ~r~You don't have enough money to buy ~y~"..tokenNr.." Chips"})
						end
					else
						vRPclient.notify(player, {"[CASINO] ~r~You can only buy 200 Chips at once!"})
					end
				else
					vRPclient.notify(player, {"[CASINO] ~r~You must enter an amount of Chips!"})
				end
			else
				vRPclient.notify(player, {"[CASINO] ~r~You must enter the number of Chips!"})
			end
		end})
	end
end, "<font color='green'>1 Chip </font>-> <font color='red'>50.000E</font>"}

casinoCasier_menu["Sell Chips"] = {function(player, choice)
	local user_id = vRP.getUserId({player})
	if(user_id ~= nil and user_id ~= "")then
		vRP.prompt({player, "Sell Chips:", "Fee: 20% of Chips value.", function(player, tokenNr)
			if(tokenNr ~= "" and tokenNr ~= nil)then
				if(tonumber(tokenNr))then
					tokenNr = tonumber(tokenNr)
					if(tokenNr > 0) and (tokenNr <= 200)then
						if vRP.tryGetInventoryItem({user_id,"casino_token",tokenNr,false}) then
							local tokensValue = math.floor(tokenNr * (50000 - (50000 * 0.20)))
							vRP.giveMoney({user_id, tokensValue})
							vRPclient.notify(player, {"[CASINO] ~g~Vendeu ~y~"..tokenNr.." Fichas ~g~por ~r~E"..tokensValue})
							vRP.closeMenu({player})
						else
							vRPclient.notify(player, {"[CASINO] ~r~You don't have enough Chips!"})
						end
					else
						vRPclient.notify(player, {"[CASINO] ~r~You can only sell 200 Chips at once!"})
					end
				else
					vRPclient.notify(player, {"[CASINO] ~r~You must enter an amount of Chips!"})
				end
			else
				vRPclient.notify(player, {"[CASINO] ~r~You must enter the number of Chips!"})
			end
		end})
	end
end, "<font color='green'>1 Chip</font> = <font color='red'>80%</font> of its value."}

function vRPcs.spawnTokenDealer(thePlayer)
	local casCasier_enter = function(player, area)
		local user_id = vRP.getUserId({player})
		if user_id ~= "" and user_id ~= nil then
			vRP.openMenu({player, casinoCasier_menu})
		end
	end

	local casCasier_leave = function(player, area)
		local user_id = vRP.getUserId({player})
		if user_id ~= "" and user_id ~= nil then
			vRP.closeMenu({player})
		end
	end

	for i, v in pairs(tokenDealer) do
		if(i == 1)then
			vRPCasinoC.createCasinoText(thePlayer,{v[1], v[2], v[3]+0.7, "~b~Casino Cashier"})
			vRP.setArea({thePlayer,"vRP:cashier:"..i,v[1], v[2], v[3],1.7,1.5,casCasier_enter,casCasier_leave})
		else
			vRPCasinoC.createCasinoNPCs(thePlayer,{"A_M_Y_business_01",v[1], v[2], v[3], 179.9213104248, "Mr. Michael Moore"})
		end
	end
end

function vRPcs.payRouletteWinnings(winnings, timesby)
	local thePlayer = source
	local user_id = vRP.getUserId({thePlayer})
	if user_id ~= "" and user_id ~= nil then
		local amountToPay = (winnings-1) * (timesby-1)
		vRP.giveInventoryItem({user_id,"casino_token",amountToPay,false})
		vRPclient.notify(thePlayer, {"[CASINO] ~g~Congratulations! You won ~y~"..amountToPay.." Chips"})
		rouletteBetters[user_id] = nil
	end
end

function vRPcs.didntWinRoulette()
	local thePlayer = source
	local user_id = vRP.getUserId({thePlayer})
	if user_id ~= "" and user_id ~= nil then
		rouletteBetters[user_id] = nil
	end
end

function vRPcs.spawnTheRoulettes(thePlayer)
	local casRoulette_enter = function(player, area)
		local user_id = vRP.getUserId({player})
		if user_id ~= "" and user_id ~= nil then
			vRP.openMenu({player, casinoRoulette_menu})
		end
	end

	local casRoulette_leave = function(player, area)
		local user_id = vRP.getUserId({player})
		if user_id ~= "" and user_id ~= nil then
			vRP.closeMenu({player})
		end
	end

	for i, v in pairs(roulettes)do
		vRPCasinoC.createCasinoText(thePlayer,{v[1], v[2], v[3]+0.7, "~r~Roulette"})
		vRP.setArea({thePlayer,"vRP:casino:roulette:"..i,v[1], v[2], v[3],1,1.5,casRoulette_enter, casRoulette_leave})
	end
end

function vRPcs.spawnTheBarbut(thePlayer)
	local casBarbut_enter = function(player, area)
		local user_id = vRP.getUserId({player})
		if user_id ~= "" and user_id ~= nil then
			vRP.openMenu({player, casinoBarbut_menu})
		end
	end

	local casBarbut1v1_enter = function(player, area)
		local user_id = vRP.getUserId({player})
		if user_id ~= "" and user_id ~= nil then
			vRP.openMenu({player, casinoBarbut1v1_menu})
		end
	end

	local casBarbut_leave = function(player, area)
		local user_id = vRP.getUserId({player})
		if user_id ~= "" and user_id ~= nil then
			vRP.closeMenu({player})
		end
	end

	for i, v in pairs(barbutDealer) do
		if(i == 1)then
			vRPCasinoC.createCasinoText(thePlayer,{v[1], v[2], v[3]+0.7, "~p~Craps Table 1v1"})
			vRP.setArea({thePlayer,"vRP:casino:barbut:mk:2",v[1], v[2], v[3]+0.2,2.3,1.5,casBarbut1v1_enter,casBarbut_leave})
		elseif(i == 2)then
			vRPCasinoC.createCasinoText(thePlayer,{v[1], v[2], v[3]+0.7, "~p~Craps table 1v1"})
			vRP.setArea({thePlayer,"vRP:casino:barbut:mk:3",v[1], v[2], v[3]+0.2,2.3,1.5,casBarbut1v1_enter,casBarbut_leave})
		elseif(i == 3)then
			vRPCasinoC.createCasinoNPCs(thePlayer,{"S_M_M_MovPrem_01",v[1], v[2], v[3], 267.94094848633, "Mr. David Miller"})
			vRP.setArea({thePlayer,"vRP:casino:barbut:npc:2",v[1], v[2], v[3],2.0, 1.5, casBarbut_enter, casBarbut_leave})
		elseif(i == 4)then
			vRPCasinoC.createCasinoNPCs(thePlayer,{"S_M_M_MovPrem_01",v[1], v[2], v[3], 267.94094848633, "Mr. Paul Clark"})
			vRP.setArea({thePlayer,"vRP:casino:barbut:npc:3",v[1], v[2], v[3],2.0, 1.5, casBarbut_enter, casBarbut_leave})
		end
	end
end

function vRPcs.spinSlotMachine(amount, a, b, c)
	local thePlayer = source
	local user_id = vRP.getUserId({thePlayer})
	if(slotMachinesBetters[user_id] == nil)then
		if vRP.tryGetInventoryItem({user_id,"casino_token",amount,false}) then
			slotMachinesBetters[user_id] = true
			vRPCasinoC.checkWinSlotmachine(thePlayer, {tonumber(amount),tostring(a),tostring(b),tostring(c)})
		else
			vRPclient.notify(thePlayer, {"[CASINO] ~r~You don't have enough Chips!"})
		end
	else
		vRPclient.notify(thePlayer, {"[CASINO] ~r~You're already playing on Slot Machine!"})
	end
end

function vRPcs.winSlotMachine(reward)
	local thePlayer = source
	local user_id = vRP.getUserId({thePlayer})
	if(reward > 0)then
		reward = reward-1
		vRP.giveInventoryItem({user_id,"casino_token",reward,false})
		slotMachinesBetters[user_id] = nil
		vRPclient.notify(thePlayer, {"[CASINO] ~g~You won ~b~"..reward.." Chips."})
	end
end

function vRPcs.lostSlotMachine()
	local thePlayer = source
	local user_id = vRP.getUserId({thePlayer})
	slotMachinesBetters[user_id] = nil
end

function vRPcs.doBarbut1v1(thePlayer)
	local user_id = vRP.getUserId({thePlayer})
	local opponentID = barbutPlayers[user_id].oponent
	if(opponentID ~= 0)then
		local theOpponent = vRP.getUserSource({opponentID})

		local opponentRoll = math.random(1, 6)
		local opponentRoll2 = math.random(1, 6)
		local playerRoll = math.random(1, 6)
		local playerRoll2 = math.random(1, 6)
		local totalOpponent = tonumber(opponentRoll + opponentRoll2)
		local totalPlayer = tonumber(playerRoll + playerRoll2)

		local winnings = barbutPlayers[user_id].cota
		SetTimeout(1000, function()
			vRPclient.notify(thePlayer, {"[CASINO] ~g~Your Hand: ~p~(~y~"..playerRoll.."~r~ , ~y~"..playerRoll2.."~p~) ~b~("..totalPlayer..")"})
			vRPclient.notify(theOpponent, {"[CASINO] ~g~Opponent's Hand: ~p~(~y~"..playerRoll.."~r~ , ~y~"..playerRoll2.."~p~) ~b~("..totalPlayer..")"})
			SetTimeout(1000, function()
				vRPclient.notify(thePlayer, {"[CASINO] ~g~Opponent's Hand: ~p~(~y~"..opponentRoll.."~r~ , ~y~"..opponentRoll2.."~p~) ~b~("..totalOpponent..")"})
				vRPclient.notify(theOpponent, {"[CASINO] ~g~Your Hand: ~p~(~y~"..opponentRoll.."~r~ , ~y~"..opponentRoll2.."~p~) ~b~("..totalOpponent..")"})
				if(totalOpponent < totalPlayer)then
					vRPclient.notify(theOpponent, {"[CASINO] ~r~Perdeu esta mao, tente a sua sorte novamente!"})
					vRPclient.notify(thePlayer, {"[CASINO] ~g~Ganhou esta mao! Ganhou ~y~"..(winnings*2).." Fichas"})
					vRP.giveInventoryItem({user_id,"casino_token",winnings*2,false})
				elseif(totalPlayer < totalOpponent)then
					vRPclient.notify(thePlayer, {"[CASINO] ~r~Perdeu esta mao, tente a sua sorte novamente!"})
					vRPclient.notify(theOpponent, {"[CASINO] ~g~Ganhou esta mao! Ganhou ~y~"..(winnings*2).." Chips"})
					vRP.giveInventoryItem({opponentID,"casino_token",winnings*2,false})
				elseif((opponentRoll == playerRoll) and (opponentRoll2 == playerRoll2))then
					vRPclient.notify(theOpponent, {"[CASINO] ~g~Esta mao ficou empatada! Recebeu de volta ~y~"..winnings.." Chips"})
					vRPclient.notify(thePlayer, {"[CASINO] ~g~Esta mao ficou empatada! Recebeu de volta ~y~"..winnings.." Chips"})
					vRP.giveInventoryItem({user_id,"casino_token",winnings,false})
					vRP.giveInventoryItem({opponentID,"casino_token",winnings,false})
				elseif((opponentRoll == playerRoll2) and (opponentRoll2 == playerRoll))then
					vRPclient.notify(theOpponent, {"[CASINO] ~g~Esta mao ficou empatada! Recebeu de volta ~y~"..winnings.." Chips"})
					vRPclient.notify(thePlayer, {"[CASINO] ~g~Esta mao ficou empatada! Recebeu de volta ~y~"..winnings.." Chips"})
					vRP.giveInventoryItem({user_id,"casino_token",winnings,false})
					vRP.giveInventoryItem({opponentID,"casino_token",winnings,false})
				elseif (totalPlayer == totalOpponent)then
					vRPclient.notify(theOpponent, {"[CASINO] ~g~Esta mao ficou empatada! Recebeu de volta ~y~"..winnings.." Chips"})
					vRPclient.notify(thePlayer, {"[CASINO] ~g~Esta mao ficou empatada! Recebeu de volta ~y~"..winnings.." Chips"})
					vRP.giveInventoryItem({user_id,"casino_token",winnings,false})
					vRP.giveInventoryItem({opponentID,"casino_token",winnings,false})
				end
			end)
		end)
		barbutPlayers[user_id] = {oponent = 0, cota = 0}
	end
end

AddEventHandler("vRP:playerLeave", function(user_id, source)
	rouletteBetters[user_id] = nil
	slotMachinesBetters[user_id] = nil
	barbutPlayers[user_id] = nil
end)

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	SetTimeout(1500, function()
		vRPcs.spawnTheRoulettes(source)
		vRPcs.spawnTokenDealer(source)
		vRPcs.spawnTheBarbut(source)
		rouletteBetters[user_id] = nil
		slotMachinesBetters[user_id] = nil
		barbutPlayers[user_id] = {oponent = 0, cota = 0}
		vRPclient.setNamedBlip(source, {"vRP:casino:blip", 926.05487060546,43.760063171386,80.899948120118, 214, 2, "Casino"})
	end)
end)