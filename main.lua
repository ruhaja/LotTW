--creator: Tempos & Caldnoc
local modinNimi = RegisterMod("inquisition",1)

local game = Game()

--SAW
local theSaw = Isaac.GetItemIdByName( "The Saw" ) 
local theSawEntity = Isaac.GetEntityTypeByName( "TheSaw" )
local theSawEntityVariant = Isaac.GetEntityVariantByName("TheSaw")

local rnd = RNG()
local rndInt
local spawned = false
local hitChance				-- arvotaan 0-100 väliltä ja plussataan siihen luck%
local proc = 67 			-- default 67? mitä korkeampi, sitä epätodennäköisemmin sahaa. Jos tämä on 100, niin sahaaminen tapahtuu 0% ajasta, sama toisinpäin
local bleedChance
local bleedProc = 73		-- default 73? mitä korkeampi, sitä epätodennäköisemmin bleedaa. Jos tämä on 100, niin bleedaaminen tapahtuu 0% ajasta, sama toisinpäin
local luckMult = 5 			-- joka luck up/down on tämän verran % lisää mahdollisuutta sahalle leikata
local familiar = nil
local inquisitorBonus = 1.0 -- kerroin joka aktivoituu/muutetaan kun inkivisitio transform on päällä
local sawAmount = 0
local flatDmg = 4
--SAW END


local whip = Isaac.GetItemIdByName("Cat-o-nine-tails")
local guillotine = Isaac.GetItemIdByName("Guillotine")
local isInquisitor = false

local pact = Isaac.GetItemIdByName("The Pact")
local isWitch = false

--passive items
local tongueTearer = Isaac.GetItemIdByName("Tongue Tearer")
local hasTongueTearerAffected = false
local broomstick = Isaac.GetItemIdByName("Broomstick")
local hereticsFork = Isaac.GetItemIdByName("Heretic's Fork")

--active items
local book = Isaac.GetItemIdByName( "Malleus Maleficarum" )
local wheel = Isaac.GetItemIdByName( "Wheel" )

--costumes
local costumeBroomstick = Isaac.GetCostumeIdByPath("gfx/characters/broomstick.anm2")
local costumeTransform = Isaac.GetCostumeIdByPath("gfx/characters/inquisitor.anm2")
--modinNimi.COSTUME_BLUE_BROOMSTICK = Isaac.GetCostumeIdByPath("gfx/characters/blue_broomstick.anm2")	--blue
--modinNimi.COSTUME_GRAY_BROOMSTICK = Isaac.GetCostumeIdByPath("gfx/characters/gray_broomstick.anm2")	--gray
--modinNimi.COSTUME_BLACK_BROOMSTICK = Isaac.GetCostumeIdByPath("gfx/characters/black_broomstick.anm2")	--black
local costumeHereticsFork = Isaac.GetCostumeIdByPath("gfx/characters/hereticsfork.anm2")
--local costumeAdded = false


--local Challenges = {
--	CHALLENGE_WITCHHUNT = Isaac.GetChallengeIdByName("Witch Hunt")
--	CHALLENGE_BEWITCHED = Isaac.GetChallengeIdByName("Be witched")
--}

--local holding = false		--wheel



local MIN_TEAR_DELAY = 5
--local costume = Isaac.GetCostumeIdByPath("gfx/characters/Tempos_TongueTearer.anm2")
--local costumeAdded = false
local tearBonus = 1


function modinNimi:init()

	isInquisitor = false
	isWitch = false
	
end

local function PlaySoundAtPos(sound, volume, pos)
  local soundDummy = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, pos, Vector(0,0), Isaac.GetPlayer(0));
  local soundDummyNPC = soundDummy:ToNPC();
  soundDummyNPC:PlaySound(sound, volume, 0, false, 1.0);
  soundDummy:Remove();
end

function modinNimi:pickupPassiveItem(player, flag)
	
	local player = Isaac.GetPlayer(0)
		
	--SAW
	if player:HasCollectible(theSaw) then
		if flag == CacheFlag.CACHE_FAMILIARS and spawned == false then
			familiar = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, theSawEntityVariant, 0, player.Position, Vector(0,0), player)
			--lineUpFamiliars()
			sawAmount = sawAmount + 1
			spawned = true
		end
	else
		spawned = false --sitä varten ettei spawnaa uudestaan
		sawAmount = 0
	end
	
	--BROOMSTICK
	if player:HasCollectible(broomstick) then
		if flag == CacheFlag.CACHE_FLYING then
			player.CanFly = true
			--if (player.GetPlayerType() == 4) then	--Blue Baby
			--blue costume
			--end
			--elseif (player.GetPlayerType() == 10 or 7) then 	--The Lost, Azazel
			--no costume change
			--end
			--elseif (player.GetPlayerType() == 14 or 15) then 	--Keeper, Apollyon
			--gray costume 
			--end
			--elseif (player.GetPlayerType() == 12 or 13) then --Black Judas, Lilith
			--black costume
			--end
			--else
			--basic costume
			player:AddNullCostume(costumeBroomstick)
			--end
		end
	end
	
	--HERETIC'S FORK
	if player:HasCollectible(hereticsFork) then
		if flag==CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed - 0.4
		end
		if flag==CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage + 1
		end
		player:AddNullCostume(costumeHereticsFork) --en ole varma onko tämä oikea paikka tälle, vai mikä on väärin, mutta kaatuu jos tämän ottaa pois kommenteista
	end
			
	
	--TONGUE TEARER
	if player:HasCollectible(tongueTearer) then --check if player has the item
		if flag==CacheFlag.CACHE_DAMAGE then
			if (player.MaxFireDelay >= (MIN_TEAR_DELAY + tearBonus)) then 
				player.MaxFireDelay = player.MaxFireDelay - tearBonus
			end
		end
			--if costumeAdded == false then
				--player:AddNullCostume(costume) --visual olis tyyliin, isaacin suusta valuu vähän verta
				--costumeAdded = true
			--end
		
	--else 
		--costumeAdded = false
	end
	
	
end

function modinNimi:onUpdate()
	local player = Isaac.GetPlayer(0)
	
	--INQUISITOR TRANSFORM
	if not isInquisitor then
		
		local inquisitorItems = {tongueTearer, book, wheel, hereticsFork, theSaw, whip, quillotine}
		local inquisitorItemCount = 0
		
		for k,v in pairs(inquisitorItems) do
			if player:HasCollectible(v) then
				inquisitorItemCount = inquisitorItemCount + 1
			end
		end  
		
		--Isaac.RenderText("inquisitorItemCount: " ..inquisitorItemCount, 100, 90, 0, 75, 75, 255) --printti debuggia varten
		
		if inquisitorItemCount >= 3 then
				--player:AnimateHappy()
				isInquisitor = true
				player:AddHearts(1)
				player:AddNullCostume(costumeTransform)
				PlaySoundAtPos(SoundEffect.SOUND_POWERUP_SPEWER, 1.0, player.Position)
				--transform teksti jotenkin näkyviin
		end
	end
	
	--WITCH TRANSFORM
	if not isWitch then
		
		local witchItems = {pact, broomstick}
		local itemCount = 0
		
		for k,v in pairs(witchItems) do
			if player:HasCollectible(v) then
				WitchItemCount = WitchItemCount + 1
			end
		end  
		
		--Isaac.RenderText("WitchItemCount: " ..WitchItemCount, 100, 90, 0, 75, 75, 255) --printti debuggia varten
		
		if WitchItemCount >= 3 then
				isWitch = true
				player:AddHearts(1)
				--player:AddNullCostume(costumeWitchTransform) ei oo tehty vielä costumea
				PlaySoundAtPos(SoundEffect.SOUND_POWERUP_SPEWER, 1.0, player.Position)
				--transform teksti jotenkin näkyviin
		end	
	end
	
	--alla oleva koodi kaataa pelin, koska nicalis pls??
	--[[
	if player:HasCollectible(hereticsFork) then
		if costumeAdded == false then
			player:AddNullCostume(costumeHereticsFork)
			costumeAdded = true
		else 
			costumeAdded = false
		end
	end
	--]]
		
	
	if player:HasCollectible(tongueTearer) then --check if player has the item
		if hasTongueTearerAffected == false then
			if (player:GetPlayerType() == 3) then --jos player on judas, niin spawnaa judas' tongue, jotain player.PlayerType()==PLAYER_JUDAS
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, TrinketType.TRINKET_JUDAS_TONGUE , player.Position, Vector(0,0), player) --jos if on totta niin spawnaa judas' tongue
			else --spawnaa TRINKET_LUCKY_TOE
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, TrinketType.TRINKET_LUCKY_TOE, player.Position, Vector(0,0), player)
			end
			PlaySoundAtPos(SoundEffect.SOUND_BLOODBANK_SPAWN, 1.0, player.Position) --joku snipetisnapeti soundi
			hasTongueTearerAffected = true
		else
			--nothing here please
		end
	else
		hasTongueTearerAffected = false
	end
end



--[[
function modinNimi:spawnItem()                               -- Main function that contains all the code

    local itemIdNumber = 511                            -- The integer value of the item you wish to spawn (1-510 for default items) 
                                                    -- 511 is normally the id if you have added one new item (gives a random item if you don't have any modded items)

    local game = Game()                                         -- The game
    local level = game:GetLevel()                               -- The level which we get from the game
    local player = Isaac.GetPlayer(0)                           -- The player
    local pos = Isaac.GetFreeNearPosition(player.Position, 80)                                                      -- Find an empty space near the player
    if level:GetAbsoluteStage() == 1 and level.EnterDoor == -1 and player.FrameCount == 1 then                      -- Only if on the first floor and only on the first frame           
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemIdNumber, pos, pos, player)     -- Spawn an item pedestal with the correct item in the spot from earlier
    end
end
]]

--WHEEL
function modinNimi:use_wheel()
	local player = Isaac.GetPlayer(0)
	player:AnimateCollectible(wheel, "LiftItem", "Idle")	
	holding = true
end


function modinNimi:onDamage()
	holding = false
end

-- if wheel CollidesWithGrid() do fallingAnimation left/right/up/down and despawn wheel

--MALLEUS MALEFICARUM
function modinNimi:use_book( )
	local player = Isaac.GetPlayer(0)
	
	player:AnimateCollectible(book, "UseItem", "Idle")	
	--player:GetEffects():AddCollectibleEffect(257, false)	-- Fire Mind 257
	
	--for _, entity in pairs(Isaac.GetRoomEntitities()) do
	--	if entity.Type == EntityType.ENTITY_TEAR then
	--		local TearData == entity:GetData()
	--		local Tear = entity:ToTear()
	--Tear:ChangeVariant(5)	--Fire Mind visual
	--Tear.TearFlags = TearFlags.FLAG_BURN
	--Tear.CollisionDamage = Tear.CollisionDamage + 2
		--end
	--end
	
	
	--local entities = Isaac.GetRoomEntities()
		--for i = 1, #entities do
		--	if (entities[i]:IsVulnerableEnemy()) then
		--	entities[i]:AddBurn(EntityRef(player), 124, 150)
		--	end
		--end
		
		return true
end


local function onFamiliarUpdate(_, fam)
	
	local player = Isaac.GetPlayer(0)
	local sprite = familiar:GetSprite()
	--Isaac.RenderText("positiot eri!" , 100, 90, 0, 75, 75, 255) --printti debuggia varten
	--Isaac.RenderText("rng nro: " ..rndInt, 100, 90, 0, 75, 75, 255) --printti debuggia varten
	if sprite:IsFinished("Sawing") then
		sprite:Play(sprite:GetDefaultAnimationName(), true)
	end
	
	if (player.FrameCount % 60 == 0) then
		local entities = Isaac.GetRoomEntities()
		local vulnerables = {}
		
		for i = 1, #entities do
			if entities[i]:IsVulnerableEnemy() then --and not(entities[i]:HasEntityFlags(EntityFlag.FLAG_BLEED_OUT)) removed
				vulnerables[#vulnerables+1] = entities[i]
			end
		end
		hitChance = rnd:RandomInt(100)
		bleedChance = rnd:RandomInt(100)
		--Isaac.RenderText("taulukon index: " ..#vulnerables, 100, 100, 0, 75, 75, 255) --printti debuggia varten
		if (player.Luck * luckMult * inquisitorBonus + hitChance > proc) then
			if #vulnerables > 0 then
				if #vulnerables == 1 then
					if player.Luck * luckMult * inquisitorBonus + bleedChance > bleedProc then
						vulnerables[1]:AddEntityFlags(EntityFlag.FLAG_BLEED_OUT)
					end
					vulnerables[1]:TakeDamage(inquisitorBonus * player.Damage * 0.75 + flatDmg, DamageFlag.DAMAGE_FAKE, EntityRef(vulnerables[1]),0)
				else
					rndInt = rnd:RandomInt(#vulnerables-1)
					--Isaac.RenderText("rng nro: " ..rndInt, 100, 90, 0, 75, 75, 255) --printti debuggia varten
					if player.Luck * luckMult * inquisitorBonus + bleedChance > bleedProc then
						vulnerables[1]:AddEntityFlags(EntityFlag.FLAG_BLEED_OUT)
					end
					vulnerables[rndInt+1]:TakeDamage(inquisitorBonus * player.Damage * 0.75 + flatDmg, DamageFlag.DAMAGE_FAKE, EntityRef(vulnerables[rndInt+1]),0)
				end
				
				sprite:Play("Sawing", true)
				PlaySoundAtPos(SoundEffect.SOUND_DEATH_BURST_LARGE, 1.0, player.Position)
				--EntityNPC::PlaySound( SoundEffect ID, float  	Volume, integer  	FrameDelay, boolean  	Loop, float  	Pitch) 		
			end
		end
	end
	fam:FollowParent()
end
--[[
local function onInit(_, fam)
	--local player = Isaac.GetPlayer(0)
	
end
--]]


--modinNimi:AddCallback(ModCallbacks.MC_POST_UPDATE, modinNimi.spawnItem)          -- Actually sets it up so the function will be called, it's called too often but oh well

modinNimi:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, modinNimi.pickupPassiveItem)

modinNimi:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, modinNimi.init)
modinNimi:AddCallback(ModCallbacks.MC_USE_ITEM, modinNimi.use_book, book)
modinNimi:AddCallback(ModCallbacks.MC_USE_ITEM, modinNimi.use_wheel, wheel)

modinNimi:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, onInit, theSawEntityVariant)
modinNimi:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, onFamiliarUpdate, theSawEntityVariant)

modinNimi:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, modinNimi.onDamage, EntityType.ENTITY_PLAYER)
modinNimi:AddCallback(ModCallbacks.MC_POST_UPDATE, modinNimi.onUpdate)



