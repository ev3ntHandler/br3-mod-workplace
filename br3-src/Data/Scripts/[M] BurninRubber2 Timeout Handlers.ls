global gData, gGame, gSystem, gSound, g

on PreloadCarsAndShared me
  tURL1 = _movie.path & "Data/Cars/Cars.cct"
  tURL2 = _movie.path & "Data/Shared/Shared.cct"
  tURLList = [tURL1, tURL2]
  tScript = new(script("[PS] Preload Casts"), tURLList, ["Cars", "Shared"], [#carsDownloaded, #SharedDownloaded], #carsHolder)
  if (tScript <> VOID) or (tScript <> 0) then
    _movie.actorList.add(tScript)
  end if
  cleanMemory()
  gGame.generalHolder = tScript
end

on PreloadTrackData me
  if gSystem.local = 1 then
    ClearCast("TrackData")
    ClearCast("Tracks")
    return 0
  end if
  if gGame.TrackHolder <> #none then
    tWorld = gGame.TrackHolder.returnData()
    if tWorld = gGame.world then
      put "The asset to download is the same and we are already downloading it!"
    else
      _movie.castLib("Tracks").fileName = _movie.path & "Tracks.cst"
      gGame.TrackHolder.AbortDownload()
      gGame.TrackDownloaded = 0
      tURLAsset = _movie.path & "Data/Tracks/" & gGame.world & "/" & gGame.world & ".cct"
      tScript = new(script("[PS] Preload Casts"), [tURLAsset], ["Tracks"], [#TrackDownloaded], #TrackHolder, gGame.world)
      if (tScript <> VOID) or (tScript <> 0) then
        _movie.actorList.add(tScript)
      end if
      gGame.TrackHolder = tScript
    end if
  else
    _movie.castLib("Tracks").fileName = _movie.path & "Tracks.cst"
    gGame.TrackDownloaded = 0
    tURLAsset = _movie.path & "Data/Tracks/" & gGame.world & "/" & gGame.world & ".cct"
    tScript = new(script("[PS] Preload Casts"), [tURLAsset], ["Tracks"], [#TrackDownloaded], #TrackHolder, gGame.world)
    if (tScript <> VOID) or (tScript <> 0) then
      _movie.actorList.add(tScript)
    end if
    gGame.TrackHolder = tScript
  end if
end

on UpdateCarsLoadPercentage me
  tmember = member("Main")
  if tmember.group("000%") = VOID then
    exit
  end if
  if gGame.generalHolder = #none then
    exit
  end if
  if gGame.TrackHolder = #none then
    tPercentage = 100
  else
    tPercentage = gGame.generalHolder.returnPercentage()
  end if
  tString = "00" & string(tPercentage)
  tString = tString.char[tString.length - 2..tString.length]
  repeat with i = 1 to tString.length
    tmember.model("000%_0" & i).resource = tmember.modelResource(tString.char[i])
    tmember.model("000%_0Glow" & i).resource = tmember.modelResource(tString.char[i] & "Glow")
  end repeat
end

on UpdateTrackLoadPercentage me
  tmember = member("Main")
  if tmember.group("000%") = VOID then
    exit
  end if
  if gGame.TrackHolder = #none then
    tPercentage = 100
  else
    tPercentage = gGame.TrackHolder.returnPercentage()
  end if
  tString = "00" & string(tPercentage)
  tString = tString.char[tString.length - 2..tString.length]
  repeat with i = 1 to tString.length
    tmember.model("000%_0" & i).resource = tmember.modelResource(tString.char[i])
    tmember.model("000%_0Glow" & i).resource = tmember.modelResource(tString.char[i] & "Glow")
  end repeat
end

on SetupDailyChallenge tTest
  tDailyTrack = (the systemDate).day
  if tTest <> VOID then
    tDailyTrack = tTest
  end if
  tText = member("DailyChallenges").text
  tLine = tText.line[tDailyTrack]
  SetItemDelimiter(TAB)
  gGame.DailyTrack = tLine.item[1]
  tGameMode = tLine.item[2]
  tTarget = tLine.item[3]
  ResetItemDelimiter()
  tDescription = gData.data.text[symbol("GameMode" & tGameMode)]
  tList = [#state: #Unlocked, #tracks: [:], #data: [#GameMode: [tGameMode], #target: ["120000"], #PrizeMoney: ["15000"], #rewards: ["UnlockBodyKit = Random"], #Unlockables: ["Unlocks a random bodykit part!"], #description: [tDescription]]]
  tList.tracks[symbol(gGame.DailyTrack)] = gGame.DailyPlayed
  gGame.ContinentsList[#DailyChallenge] = [:]
  gGame.ContinentsList[#DailyChallenge][#state] = #Unlocked
  gGame.ContinentsList[#DailyChallenge][#locations] = [:]
  gGame.ContinentsList[#DailyChallenge][#locations]["Daily Challenge"] = tList
  gGame.selectedContinent = "DailyChallenge"
  gGame.selectedLocation = "Daily Challenge"
  gGame.SelectedTrack = [gGame.DailyTrack, 1]
  BuildChallengeButtons()
  SetChallengeButtons()
end

on CollectSetTrackData me
  tProp = symbol(gGame.world & "Track" & gGame.track & "Data")
  put string("tProp is: " & tProp)
  tList = gData.Events[tProp]
  if tList[#fog].ilk = #integer then
    gGame.TrackData.fog = tList.fog
  end if
  if tList[#fogColor].ilk = #list then
    gGame.TrackData.fogColor = tList.fogColor
  end if
  if tList[#FogRange].ilk = #list then
    gGame.TrackData.FogRange = tList.FogRange
  end if
  if tList[#skybox].ilk = #string then
    gGame.TrackData.skybox = tList.skybox
  end if
  repeat with i = 1 to tList.count
    if tList.getPropAt(i) = #AICar then
      gGame.TrackData.AI.add(tList[i])
    end if
  end repeat
end

on EvaluateResults me
  if (gGame.GameMode = "Rampage") and (gGame.RaceResult = #Lost) then
    gGame.score = 0
  else
    gGame.score = gGame.cars[1].race.score
  end if
  gGame.totalScore = gGame.totalScore + gGame.score
  if gGame.RaceResult = #Won then
    if gGame.GameMode = "Rampage" then
      gGame.BONUS = 0
      gGame.PrizeMoney = 0
    else
      if gGame.cars[1].race.time <= gGame.target then
        gGame.BONUS = gGame.timeBonus
      else
        gGame.BONUS = 0
      end if
      gGame.totalScore = gGame.totalScore + gGame.BONUS
      gGame.totalScore = gGame.totalScore + gGame.PrizeMoney
    end if
    gGame.HighscoreMember.text = string(gGame.totalScore)
    tList = []
    tString = gGame.rewards
    if tString.ilk <> #string then
      tString = EMPTY
    end if
    the itemDelimiter = ","
    repeat with i = 1 to tString.item.count
      tItem = tString.item[i]
      tList.add(tItem)
    end repeat
    tItemList = [:]
    the itemDelimiter = "="
    repeat with i in tList
      tEntry = i.item[2]
      if tEntry.char[1] = " " then
        delete char 1 of tEntry
      end if
      tItemList.addProp(symbol(i.item[1]), i.item[2])
    end repeat
    ResetItemDelimiter()
    UnlockRewards(tItemList, gGame.trackList[symbol(gGame.world & "Track" & gGame.track)])
    event("DelayCompletedChallenge")
  else
    gGame.BONUS = 0
    gGame.PrizeMoney = 0
    event("DelayFailedChallenge")
  end if
  if gGame.DailyChallenge = 0 then
    if (gGame.RaceResult = #Won) and (gGame.trackList[symbol(gGame.world & "Track" & gGame.track)] <> #Completed) then
      gGame.Statistics.wd[1] = gGame.Statistics.wd[1] + 1
    end if
    if gGame.RaceResult = #Won then
      gGame.trackList[symbol(gGame.world & "Track" & gGame.track)] = #Completed
    else
      if gGame.trackList[symbol(gGame.world & "Track" & gGame.track)] <> #Completed then
        gGame.trackList[symbol(gGame.world & "Track" & gGame.track)] = #Unlocked
      end if
    end if
  else
    if gGame.RaceResult = #Won then
      gGame.DailyPlayed = #Completed
    else
      if gGame.DailyPlayed <> #Completed then
        gGame.DailyPlayed = #Unlocked
      end if
    end if
  end if
  gGame.Statistics.time = gGame.Statistics.time + gGame.cars[1].race.time
  if (gGame.RaceResult = #Won) and (gGame.cars[1].race.time <= gGame.target) then
    gGame.Statistics.timeB = gGame.Statistics.timeB + 1
  end if
  gGame.Statistics.played = gGame.Statistics.played + 1
  if gGame.RaceResult = #Won then
    gGame.Statistics.Completed = gGame.Statistics.Completed + 1
  else
    gGame.Statistics.failed = gGame.Statistics.failed + 1
  end if
  if gGame.RaceResult = #Won then
    gGame.Statistics[symbol(gGame.GameMode)] = gGame.Statistics[symbol(gGame.GameMode)] + 1
  end if
  UpdateCashFlow(gGame.totalScore)
  CheckTrophies()
end

on UnlockRewards tList, tTrackState
  if gGame.DailyChallenge = 1 then
    tTrackState = gGame.DailyPlayed
  end if
  gGame.items = []
  repeat with i = 1 to tList.count
    tProp = tList.getPropAt(i)
    if tProp = #UnlockTrack then
      tSymbol = symbol(tList[i])
      if (gGame.trackList.findPos(tSymbol) = VOID) and (tTrackState <> #Completed) then
        gGame.trackList[tSymbol] = #new
        gGame.items.add(gData.data.text.UnlockTrack)
      else
        gGame.items.add(gData.data.text.unlockedTrack)
      end if
    end if
    if tProp = #UnlockCar then
      tSymbol = symbol(tList[i])
      if (gGame.CarsList.findPos(tSymbol) = VOID) and (tTrackState <> #Completed) then
        if gGame.Bosses.getPos(tSymbol) <> 0 then
          tState = #Unlocked
        else
          tState = #new
        end if
        gGame.CarsList[tSymbol] = tState
        gGame.items.add(gData.data.text.UnlockCar)
        gGame.Statistics.cars[1] = gGame.Statistics.cars[1] + 1
      else
        gGame.items.add(gData.data.text.unlockedCar)
      end if
    end if
    if tProp = #UnlockBodyKit then
      tState = "Random"
      if (tState = "Random") and (tTrackState <> #Completed) then
        tState = 0
        repeat with k = 1 to gGame.CarsList.count
          tProp = gGame.CarsList.getPropAt(k)
          if gGame.Bosses.getPos(string(tProp)) <> 0 then
            put "tried to unlock random parts for a boss. Next in line"
            next repeat
          end if
          tBodyList = gGame.BodykitList[tProp]
          if tBodyList = VOID then
            next repeat
          end if
          if tBodyList.count = 5 then
            next repeat
            next repeat
          end if
          tBodyKits = [#skin2, #frontBumper2, #rearBumper2, #rims2, #spoiler]
          repeat with j = 1 to tBodyList.count
            tBodyKits.deleteOne(tBodyList.getPropAt(j))
          end repeat
          tUnlockedKit = tBodyKits[random(1, tBodyKits.count)]
          gGame.BodykitList[tProp][tUnlockedKit] = #new
          put tProp && tUnlockedKit
          tState = 1
          gGame.Statistics.BODYKITS[1] = gGame.Statistics.BODYKITS[1] + 1
          exit repeat
        end repeat
        if tState = 1 then
          gGame.items.add(gData.data.text.UnlockBodyKit)
        else
          gGame.items.add(gData.data.text.unlockedBodykit)
        end if
      else
        gGame.items.add(gData.data.text.unlockedBodykit)
      end if
    end if
    if tProp = #UnlockUpgrade then
      tSymbol = symbol(tList[i])
      if (gGame.UpgradesList.findPos(tSymbol) = VOID) and (tTrackState <> #Completed) then
        gGame.UpgradesList[tSymbol] = #Unlocked
        gGame.items.add(gData.data.text.UnlockUpgrade)
        gGame.Statistics.upgrades[1] = gGame.Statistics.upgrades[1] + 1
      else
        gGame.items.add(gData.data.text.unlockedUpgrade)
      end if
    end if
    if tProp = #UnlockPrimaryWeapon then
      tSymbol = symbol(tList[i])
      if (gGame.PrimaryWeaponsList.findPos(tSymbol) = VOID) and (tTrackState <> #Completed) then
        gGame.PrimaryWeaponsList[tSymbol] = #new
        gGame.items.add(gData.data.text.UnlockPrimaryWeapon)
        gGame.Statistics.Weapons[1] = gGame.Statistics.Weapons[1] + 1
      else
        gGame.items.add(gData.data.text.unlockedPrimaryWeapon)
      end if
    end if
    if tProp = #UnlockSecondaryWeapon then
      tSymbol = symbol(tList[i])
      if (gGame.SecondaryWeaponsList.findPos(tSymbol) = VOID) and (tTrackState <> #Completed) then
        gGame.SecondaryWeaponsList[tSymbol] = #new
        gGame.items.add(gData.data.text.UnlockSecondaryWeapon)
        gGame.Statistics.Weapons[1] = gGame.Statistics.Weapons[1] + 1
        next repeat
      end if
      gGame.items.add(gData.data.text.unlockedSecondaryWeapon)
    end if
  end repeat
end

on UpdateResultsTextures me
  tmember = member("Main")
  gGame.Result3DText = []
  tgroup = Create3DText(0, "Main", [#text: gGame.TrackName & "  ", #size: 60, #alignH: #left, #alignV: #top, #alignVRef: "Results3d", #parent: "Results3d", #shader: "WhiteFont3D_Material", #glow: 1, #glowShader: "WhiteFont3DGlow_Material", #offset: vector(0, 0, 0), #maxH: 467.19999999999998863])
  tgroup.transform.position = tgroup.transform.position + vector(0, 0, 45)
  gGame.Result3DText.add(tgroup)
  tgroup = Create3DText(0, "Main", [#text: gGame.GameMode & " ", #size: 35, #alignH: #left, #alignV: #top, #alignVRef: "Results3d", #parent: "Results3d", #shader: "DarkFont3D_Material", #glow: 1, #glowShader: "DarkFont3DGlow_Material", #offset: vector(0, 0, 0)])
  gGame.Result3DText.add(tgroup)
  tScore = FormatPrice(0, gGame.score)
  CreateTextTexture(0, "Main", [#text: tScore, #texture: "ResultsScore_Texture", #align: #right, #fontSize: 24, #lineSpacing: 20, #color: gData.data.TextColor.White, #nearFiltering: 1])
  tScore = FormatPrice(0, gGame.BONUS)
  CreateTextTexture(0, "Main", [#text: tScore, #texture: "ResultsTimeBonus_Texture", #align: #right, #fontSize: 24, #lineSpacing: 20, #color: gData.data.TextColor.White, #nearFiltering: 1])
  if gGame.RaceResult = #Won then
    tScore = FormatPrice(0, gGame.PrizeMoney)
  else
    tScore = FormatPrice(0, 0)
  end if
  CreateTextTexture(0, "Main", [#text: tScore, #texture: "ResultsPrizeMoney_Texture", #align: #right, #fontSize: 24, #lineSpacing: 20, #color: gData.data.TextColor.White, #nearFiltering: 1])
  tScore = FormatPrice(0, gGame.totalScore)
  CreateTextTexture(0, "Main", [#text: tScore, #texture: "ResultsTotalScore_Texture", #align: #right, #fontSize: 38, #lineSpacing: 33, #resize: 1, #color: gData.data.TextColor.White, #nearFiltering: 1])
  if gGame.RaceResult = #Won then
    SETVISIBLE(0, "Main", [#model: "SendHighScoreButton", #parent: "Results2D", #state: 0])
    SETVISIBLE(0, "Main", [#model: ["ResultsTotalScoreName", "ResultsTotalScore"], #parent: "Results3D", #state: 1])
    SETVISIBLE(0, "Main", [#model: "ResultsBar1", #parent: "Results3D", #state: 1])
    repeat with i = 1 to 3
      if i <= gGame.items.count then
        tText = gGame.items[i]
        CreateTextTexture(0, "Main", [#text: tText, #texture: "NewUnlocked" & i & "_Texture", #fontSize: 15, #width: 512, #color: gData.data.TextColor.Black, #nearFiltering: 1])
        SETVISIBLE(0, "Main", [#model: "NewUnlocked" & i, #parent: "ResultsBar2", #state: 1])
        next repeat
      end if
      SETVISIBLE(0, "Main", [#model: "NewUnlocked" & i, #state: 0])
    end repeat
  else
    SETVISIBLE(0, "Main", [#model: ["ResultsTotalScoreName", "ResultsTotalScore", "SendHighScoreButton"], #state: 0])
    SETVISIBLE(0, "Main", [#model: "ResultsBar1", #state: 0])
    tgroup = Create3DText(0, "Main", [#text: gData.data.text.failed & "  ", #size: 120, #alignH: #left, #alignV: #top, #alignVRef: "ResultsDefiler", #parent: "ResultsDefiler", #shader: "WhiteFont3D_Material", #glow: 1, #glowShader: "WhiteFont3DGlow_Material", #offset: vector(0, 0, 0)])
    tgroup.transform.position = tgroup.transform.position + vector(-227, -15, -20)
    gGame.Result3DText.add(tgroup)
  end if
end

on DeleteResult3DText me
  tList = gGame.Result3DText.duplicate()
  repeat with i in tList
    gGame.Result3DText.deleteOne(i)
    Delete3DText(0, "Main", [#text: i.name])
  end repeat
  gGame.Result3DText = []
end

on Detonate me, tmodel, tSender
  tParent = tmodel.parent
  tUD = tParent.userData
  repeat with i = 1 to tUD.Obstacles.count
    tRB = tUD.Obstacles[i]
    timeout().new(tRB & "Detonate", i * 150, #TimedDetonation, [tRB, 1000, tSender])
  end repeat
  gGame.Statistics.detonators = gGame.Statistics.detonators + 1
  CheckTrophies()
end

on KillLastPlayer me
  if gGame.RaceState = #Finished then
    exit
  end if
  if gGame.cars[1].race.state = #Dead then
    exit
  end if
  tTotalDeath = gGame.AIsKilled + gGame.PlayersKilled
  repeat with i in gGame.cars
    if i.race.position = (gGame.cars.count - tTotalDeath) then
      i.car.impacts.add([2500, #Elimination])
      exit repeat
    end if
  end repeat
end

on TimedDetonation tList, tTimeOut
  gGame.AreaDamageList.add(tList)
  tTimeOut.forget()
end

on CollectHiddenPackage me
  tTrack = symbol(gGame.world & "Track" & gGame.track)
  gGame.HiddenPackageList.add(tTrack)
  gGame.Statistics.packages[1] = gGame.Statistics.packages[1] + 1
  CheckTrophies()
end

on CarSpecial me
  tmember = member("car")
  tmodel = tmember.model("Car")
  tmodel.addModifier(#sds)
  tmodel.sds.depth = 1
end

on CheckTrophies me
  if (gGame.Statistics.wd[1] = gGame.Statistics.wd[2]) and (gGame.Trophies.Worlddomination = 0) then
    DoTrophy(0, #Worlddomination)
  end if
  if (gGame.Cash >= 1000000) and (gGame.Trophies.ilikemoney = 0) then
    DoTrophy(0, #ilikemoney)
  end if
  if (gGame.Statistics.vehicles = 100) and (gGame.Trophies.menacetosociety = 0) then
    DoTrophy(0, #menacetosociety)
  end if
  if (gGame.Statistics.rivalWrecked = 100) and (gGame.Trophies.toughguy = 0) then
    DoTrophy(0, #toughguy)
  end if
  if (gGame.Statistics.detonators = 50) and (gGame.Trophies.actionhero = 0) then
    DoTrophy(0, #actionhero)
  end if
  if (gGame.Statistics.timeB = 50) and (gGame.Trophies.speeddemon = 0) then
    DoTrophy(0, #speeddemon)
  end if
  if (gGame.Statistics.Survivor = 7) and (gGame.Trophies.eyeofthetiger = 0) then
    DoTrophy(0, #eyeofthetiger)
  end if
  if (gGame.Statistics.Rampage = 5) and (gGame.Trophies.thedestructor = 0) then
    DoTrophy(0, #thedestructor)
  end if
  if (gGame.Statistics.Wrecked = 100) and (gGame.Trophies.imnoquitter = 0) then
    DoTrophy(0, #imnoquitter)
  end if
  tState = 1
  tList = [#cars, #upgrades, #BODYKITS, #Weapons]
  repeat with i in tList
    if gGame.Statistics[i][1] <> gGame.Statistics[i][2] then
      tState = 0
      exit repeat
    end if
  end repeat
  if (tState = 1) and (gGame.Trophies.GREEDY = 0) then
    DoTrophy(0, #GREEDY)
  end if
  if (gGame.Statistics.packages[1] >= gGame.Statistics.packages[2]) and (gGame.Trophies.ibelieveicanfly = 0) then
    DoTrophy(0, #ibelieveicanfly)
  end if
end

on DoTrophy me, tTrophy
  put tTrophy
  gGame.Trophies[tTrophy] = 1
  if tTrophy = #ibelieveicanfly then
    gGame.CarsList[#Apache] = #Unlocked
    gGame.Statistics.cars[1] = gGame.Statistics.cars[1] + 1
    CheckTrophies()
  end if
  CreateTextTexture(0, "1PlayerInterface", [#text: gData.data.text[symbol(string(tTrophy) & "Header")], #texture: "TrophyStatusHeader_Texture", #fontSize: 15, #align: #left, #color: rgb(255, 255, 255), #nearFiltering: 1])
  CreateTextTexture(0, "1PlayerInterface", [#text: gData.data.text[symbol(string(tTrophy) & "Text")], #texture: "TrophyStatusText_Texture", #fontSize: 12, #height: 32, #width: 170, #wrap: 1, #align: #left, #color: rgb(0, 0, 0), #forceSize: [256, 32], #nearFiltering: 1])
  SETVISIBLE(0, "1PlayerInterface", [#model: "TrophyStatus", #parent: "World", #state: 1])
  DelayEvent(0, EMPTY, [#delay: 2500, #event: #HidetrophyStatus])
  PlaySound("Trophy_SFX")
end

on monkeybusiness me
  DoTrophy(0, #monkeybusiness)
end

on pigsFTW me
  DoTrophy(0, #pigsFTW)
end

on StoreMute me
  gSound[#OldMute] = gSound.mute
end

on ResetAllAnimation me
  tmember = member("Logo")
  repeat with i = 1 to tmember.model.count
    tmodel = tmember.model[i]
    tList = tmodel.modifier
    if tList.getPos(#keyframePlayer) <> 0 then
      tmodel.removeModifier(#keyframePlayer)
    end if
  end repeat
end

on PlayAllAnimation me
  tmember = member("Logo")
  repeat with i = 1 to tmember.model.count
    tmodel = tmember.model[i]
    tmodel.addModifier(#keyframePlayer)
    if tmodel.name contains "Part" then
      next repeat
    end if
    if tmodel.name contains "Glow" then
      next repeat
    end if
    if tmodel.name contains "Overlay" then
      next repeat
    end if
    if tmodel = tmember.model("Dummy Animation Node Logo_Camera") then
      tmodel.keyframePlayer.queue("Logo_Camera-Key", 0)
      next repeat
    end if
    tmodel.keyframePlayer.queue(tmodel.name & "-Key", 0)
  end repeat
  tmember.camera("DefaultView").fieldOfView = 62
  tFire = new(script("[PS] Fire"), tmember, vector(0, 0, 0), tmember.camera("DefaultView"), tmember.model("3"))
  if tFire <> VOID then
    gGame.scriptList.add(tFire)
  end if
  if gGame.Bloom = 1 then
    tCamera = tmember.camera("DefaultView")
    theTexture = member(5, 3).texture("Bloom_Texture")
    tCamera.addOverlay(theTexture, point(0, 0), 0)
    tModelList = []
    tSortedNameList = []
    tSortedNameList.sort()
    repeat with i = 1 to tmember.model.count
      tmodel = tmember.model(i)
      if tmodel.name contains "Overlay-" then
        tSortedNameList.add(tmodel.name)
        tModelList.add(tmodel)
      end if
    end repeat
    tName = tSortedNameList[tSortedNameList.count]
    repeat with j in tModelList
      if j.name = tName then
        tOverlayModel = j
      end if
    end repeat
    tOverlayModel.shaderList = tmember.shader("Bloomlogo_Material")
    tCamera.overlay[2].scale = tCamera.overlay[1].scale
    if tFire <> VOID then
      tFire.p.PerFrame = 2.5
    end if
  end if
end

on CreateInitializingTexture me, tGameMode, tTrackname
  tRatio = 2
  tGameMode = gGame.GameMode
  tTrackname = gGame.TrackName
  if member("Initializing_Texture") = VOID then
    tEmpty = castLib("Menu").findEmpty()
    tmember = new(#bitmap, member(tEmpty, "Menu"))
    tmember.name = "Initializing_Texture"
    gSystem.DynamicMembers.add(tmember)
  else
    tmember = member("Initializing_Texture")
  end if
  tImage = image(1024 * tRatio, 1024, 32)
  tBackground = member("InitializingBG_Texture")
  tImage.copyPixels(tBackground.image, tBackground.rect, tBackground.rect)
  tGameModeImage = member("Initializing" & tGameMode & "_Texture")
  tImage.copyPixels(tGameModeImage.image, rect(128, 96, 512, 288) * tRatio, tGameModeImage.rect)
  tTextMember = member("Text2")
  tTextMember.fontSize = 10 * tRatio
  tTextMember.topSpacing = 0
  tTextMember.alignment = #left
  tTextMember.fixedLineSpace = 12 * tRatio
  tTextMember.color = rgb(255, 255, 255)
  if tGameMode = "Rampage" then
    tText = convertToUpperCase(0, "Do as much damage to your environment as possible within the time limit! Reach the damage target of " & FormatPrice(0, gGame.PrizeMoney) & " to complete the challenge!")
  else
    tText = convertToUpperCase(0, gData.data.text[symbol("GameMode" & tGameMode)])
  end if
  tTextMember.text = tText
  tTextMember.wordWrap = 1
  tTextMember.width = 384 * tRatio
  tTextMember.height = 64 * tRatio
  tImage.copyPixels(tTextMember.image, rect(128, 290, 512, 354) * tRatio, tTextMember.rect)
  tTextMember.fontSize = 36 * tRatio
  tTextMember.topSpacing = 0
  tTextMember.alignment = #left
  tTextMember.fixedLineSpace = 0
  tTextMember.color = rgb(255, 255, 255)
  tTextMember.text = convertToUpperCase(0, tGameMode)
  tTextMember.wordWrap = 1
  tTextMember.width = 384 * tRatio
  tTextMember.height = 64 * tRatio
  member("ImageTemplate").image = tTextMember.image
  tTempImage = member("ImageTemplate").image
  tFilter = filter(#GlowFilter, [#BlurX: 7, #BlurY: 7, #quality: 2, #color: color(255, 255, 255), #strengthPercent: 99])
  tTempImage.applyFilter(tFilter, tTempImage.rect)
  tImage.copyPixels(tTempImage, rect(127, 58, 511, 122) * tRatio, tTempImage.rect)
  tTextMember.fontSize = 14 * tRatio
  tTextMember.topSpacing = 0
  tTextMember.alignment = #right
  tTextMember.fixedLineSpace = 12 * tRatio
  tTextMember.color = rgb(255, 255, 255)
  tTextMember.text = convertToUpperCase(0, "Initializing" && tTrackname)
  tTextMember.wordWrap = 1
  tTextMember.width = 384 * tRatio
  tTextMember.height = 32 * tRatio
  tTextMember.word[1].color = rgb(128, 128, 130)
  tImage.copyPixels(tTextMember.image, rect(246, 8, 630, 40) * tRatio, tTextMember.rect)
  tmember.image = tImage
end

on UpdateGameStatistics me
  tText = EMPTY
  repeat with i = 1 to gGame.Statistics.count
    tProp = gGame.Statistics.getPropAt(i)
    if tProp = #timeB then
      next repeat
    end if
    if gGame.Statistics[i].ilk = #list then
      tString = gGame.Statistics[i][1] & "/" & gGame.Statistics[i][2]
    else
      if tProp = #time then
        tString = formatStatsTime(0, gGame.Statistics[i])
      else
        tString = gGame.Statistics[i]
      end if
    end if
    tText = tText & tString & RETURN
  end repeat
  member("StatsResults").text = tText
  member("StatsResults").alignment = #right
  member("StatsResults").fixedLineSpace = 22
  tImage = image(512, 512, 32, 1)
  tAlpha = tImage.extractAlpha()
  tAlpha.fill(tAlpha.rect, rgb(255, 255, 255))
  tImage.setAlpha(tAlpha)
  tImage.copyPixels(member("StatsText").image, rect(25, 0, 370, 512), rect(0, 0, 384, 512))
  tImage.copyPixels(member("StatsResults").image, rect(365, 0, 507, 512), rect(370, 0, 512, 512))
  member("ImageTemplate").image = tImage
  tTempImage = member("ImageTemplate").image
  tFilter = filter(#GlowFilter, [#BlurX: 5, #BlurY: 5, #quality: 2, #color: color(132, 132, 127), #strengthPercent: 48])
  tTempImage.applyFilter(tFilter, tTempImage.rect)
  tImage.copyPixels(tTempImage, tImage.rect, tTempImage.rect)
  member("Main").texture("Statistics_Texture").image = tImage
  member("Main").texture("Statistics_Texture").renderFormat = #rgba4444
end

on formatStatsTime me, tMillisec
  sec = integer(tMillisec / 1000)
  min = integer(sec / 60)
  sec = sec - (min * 60)
  Hour = integer(min / 60)
  min = min - (Hour * 60)
  tMillisec = integer((tMillisec - (sec * 1000) - (min * 60 * 1000) - (Hour * 60 * 60 * 1000)) / 10.0)
  hourString = string(Hour) & "h"
  if min < 10 then
    minString = "0" & string(min + 100).char[3..3] & "m"
  else
    minString = string(min + 100).char[2..3] & "m"
  end if
  secString = string(sec + 100).char[2..3] & "s"
  return hourString & minString & secString
end

on UpdateTrophies me
  tImage = image(512, 512, 32, 1)
  tAlpha = tImage.extractAlpha()
  tAlpha.fill(tAlpha.rect, rgb(255, 255, 255))
  tImage.setAlpha(tAlpha)
  repeat with i = 1 to gGame.Trophies.count
    tProp = gGame.Trophies.getPropAt(i)
    tSubImage = image(512, 32, 32, 1)
    tAlpha = tSubImage.extractAlpha()
    tAlpha.fill(tAlpha.rect, rgb(255, 255, 255))
    tSubImage.setAlpha(tAlpha)
    if gGame.Trophies[i] = 1 then
      tColor = rgb(255, 255, 255)
      tTrophy = member("TrophyCompleted_Texture")
    else
      tColor = rgb(164, 164, 164)
      tTrophy = member("TrophyOpen_Texture")
    end if
    member("TrophyHeader").color = tColor
    member("TrophyText").color = tColor
    member("TrophyHeader").text = gData.data.text[symbol(string(tProp) & "Header")]
    member("TrophyText").text = gData.data.text[symbol(string(tProp) & "Text")]
    tSubImage.copyPixels(member("TrophyHeader").image, rect(5, 0, 389, 16), member("TrophyHeader").rect)
    tSubImage.copyPixels(member("TrophyText").image, rect(5, 16, 389, 26), member("TrophyText").rect)
    tSubImage.copyPixels(tTrophy.image, rect(455, -6, 487, 26), tTrophy.rect)
    tRect = rect(0, -28 + (i * 32), 512, 4 + (i * 32))
    tImage.copyPixels(tSubImage, tRect, tSubImage.rect)
  end repeat
  member("ImageTemplate").image = tImage
  tTempImage = member("ImageTemplate").image
  tFilter = filter(#GlowFilter, [#BlurX: 5, #BlurY: 5, #quality: 2, #color: color(64, 64, 64), #strengthPercent: 30])
  tTempImage.applyFilter(tFilter, tTempImage.rect)
  tImage.copyPixels(tTempImage, tImage.rect, tTempImage.rect)
  member("Main").texture("Trophies_Texture").image = tImage
  member("Main").texture("Trophies_Texture").renderFormat = #rgba4444
end

on ViewHighscore me
  gGame.HighscoreMember.text = string(0)
  StopAllSound()
  gGame.CurrentMenu = "Hub"
  sendSprite(6, #mouseDown)
  updateStage()
  sendSprite(6, #mouseUp)
end

on SubmitHighscore me
  event("EndRaceAndGoToHub")
  sendSprite(7, #mouseDown)
  updateStage()
  sendSprite(7, #mouseUp)
end

on DeFreezeIn me, tList, tDataList
  tBlend = gGame.interface.shader("Defreeze_Material").blend
  tBlend = tBlend + 6
  tBlend = min(tBlend, 100)
  gGame.interface.shader("Defreeze_Material").blend = tBlend
  if tBlend = 100 then
    timeout("DeFreezeIn").forget()
  end if
end

on DeFreezeOut me
  tBlend = gGame.interface.shader("Defreeze_Material").blend
  tBlend = tBlend - 6
  tBlend = max(tBlend, 0)
  gGame.interface.shader("Defreeze_Material").blend = tBlend
  if tBlend = 0 then
    timeout("DeFreezeOut").forget()
  end if
end

on NitroOff tList, tTimeOut
  gGame.cars[tList[1]].car.Nitro = 0
  tTimeOut.forget()
end

on UpdatePositions me
  tAliveList = []
  tDeadList = []
  tList = [#Dead: tDeadList, #alive: tAliveList]
  repeat with i in gGame.cars
    if i.race.state = #Finished then
      next repeat
    end if
    tEntry = [i.car.currentRootNr, i.race.waypoint, -i.race.perpDistance, i.general.tag, i.race.state]
    if i.race.state = #Dead then
      tList.Dead.add(tEntry)
      next repeat
    end if
    tList.alive.add(tEntry)
  end repeat
  tList.Dead.sort()
  tList.alive.sort()
  tDeadCount = tList.Dead.count
  repeat with i = 1 to tDeadCount
    tPosition = gGame.cars.count + 1 - i
    gGame.cars[tList.Dead[i][4]].race.position = tPosition
  end repeat
  tAliveCount = tList.alive.count
  repeat with i = 1 to tAliveCount
    tPosition = gGame.cars.count + 1 - i - tDeadCount
    gGame.cars[tList.alive[i][4]].race.position = tPosition
  end repeat
  tCount = gGame.cars.count
  repeat with i = 1 to tCount
    t = gGame.cars[i]
    tPosition = t.race.position
    gGame.interface.shader("Position" & tPosition & "Name_Material").texture = gGame.interface.texture("CarName" & i & "_Texture")
    if t.general.controller = #player then
      gGame.interface.model("Position" & tPosition & "Tag").resource = gGame.interface.modelResource("Position" & tPosition & "TagRed")
    else
      gGame.interface.model("Position" & tPosition & "Tag").resource = gGame.interface.modelResource("Position" & tPosition & "TagBlack")
    end if
    tmodel = gGame.interface.model("Position" & tPosition & "State")
    if (t.race.state = #Dead) or (t.race.state = #Finished) then
      tmodel.resource = gGame.interface.modelResource("PositionState" & string(t.race.state))
      tmodel.shader = gGame.interface.shader("Interface_Material")
      next repeat
    end if
    tmodel.resource = gGame.interface.modelResource("PositionState")
    tmodel.shader = gGame.interface.shader("Position" & tPosition & "State_Material")
  end repeat
end

on deactivateWindow me
  if _player.runMode = "Author" then
    exit
  end if
  if (voidp(gGame[#Scene]) = 0) and (voidp(gGame[#Input]) = 0) and (voidp(gGame[#pause]) = 0) and (voidp(gGame[#RaceState]) = 0) then
    if (gGame.Scene = "Tracks") and (gGame.Input = 1) and (gGame.pause = 0) and (gGame.RaceState = #Racing) then
      PauseGame()
      put "DEACTIVATE WINDOW"
    end if
  end if
end
