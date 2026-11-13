global g, gData, gGame, gSound, gSystem

on BurninRubber3 me
  _movie.exitLock = gGame.LockEscape
  gData.data[#Defaultbodykit] = gData.data.bodyKit.duplicate()
  gData.data[#DefaultUpgrades] = gData.data.upgrades.duplicate()
  gData.data[#DefaultWeapons] = gData.data.Weapons.duplicate()
  LoadData()
  gSystem.Init = 1
end

on ResetGame me
  gGame.scriptList = []
  gGame[#pause] = 0
  if voidp(gGame[#Physics]) = 0 then
    gGame[#Physics].erase()
    gGame[#Physisc] = VOID
    gGame.deleteProp(#Physics)
  end if
  gGame.TimeMP = 1.0
  if getaProp(gGame, #Items3D).ilk = #propList then
    gGame.deleteProp(#Items3D)
  end if
  if getaProp(gGame, #Button3DList).ilk = #list then
    gGame.deleteProp(#Button3DList)
  end if
  if voidp(gGame[#Button3DList]) = 0 then
    deleteProp(gGame, #Button3DList)
  end if
  if getaProp(gGame, #cars).ilk = #propList then
    gGame.deleteProp(#cars)
  end if
  if getaProp(gGame, #RayCastList).ilk = #propList then
    gGame.deleteProp(#RayCastList)
  end if
  if getaProp(gGame, #camera).ilk = #propList then
    gGame.deleteProp(#camera)
  end if
  if getaProp(gGame, #FloorList).ilk = #list then
    gGame.deleteProp(#FloorList)
  end if
  if getaProp(gGame, #collisionReports).ilk = #propList then
    gGame.deleteProp(#collisionReports)
  end if
  if getaProp(gGame, #Keys).ilk = #propList then
    gGame.Keys = [:]
  end if
  if getaProp(gGame, #RootList).ilk = #list then
    gGame.deleteProp(#RootList)
  end if
  if getaProp(gGame, #WayPointList).ilk = #list then
    gGame.deleteProp(#WayPointList)
  end if
  if getaProp(gGame, #CheckPoints).ilk = #propList then
    gGame.deleteProp(#CheckPoints)
  end if
  if getaProp(gGame, #AddShaders).ilk = #list then
    gGame.deleteProp(#AddShaders)
  end if
  if getaProp(gSystem, #ScrollerList).ilk = #list then
    gSystem.deleteProp(#ScrollerList)
  end if
  if getaProp(gSystem, #RotatorList).ilk = #list then
    gSystem.deleteProp(#RotatorList)
  end if
  if getaProp(gSystem, #BillBoardList).ilk = #list then
    gSystem.deleteProp(#BillBoardList)
  end if
  if getaProp(gSystem, #InterPolatorList).ilk = #list then
    gSystem.deleteProp(#InterPolatorList)
  end if
  if getaProp(gSystem, #PointAtList).ilk = #list then
    gSystem.deleteProp(#PointAtList)
  end if
  if getaProp(gSystem, #Mimic).ilk = #list then
    gSystem.deleteProp(#Mimic)
  end if
  if voidp(gGame[#StaticRBList]) = 0 then
    gGame.deleteProp(#StaticRBList)
  end if
  if voidp(gGame[#DynamicList]) = 0 then
    gGame.deleteProp(#DynamicList)
  end if
  if voidp(gGame[#destructiveList]) = 0 then
    gGame.deleteProp(#destructiveList)
  end if
  _movie.timeoutList = []
  _movie.actorList = []
  gSystem.handlerList = []
  gGame[#timeoutList] = []
  gGame[#actorList] = []
  gGame[#timerList] = [:]
  gGame[#AddShaders] = []
  if gSound[#OldMute] <> VOID then
    if gSound[#mute] <> gSound.OldMute then
      MuteSound()
      gSound[#mute] = gSound.OldMute
    end if
  else
    gSound[#mute] = 0
  end if
end

on LoadData me
  tLocalData = _player.getPref(gGame.PrefFile)
  tList = DecodeAndRetrieveData(tLocalData, 1)
  if tList <> VOID then
    gGame.loadedData = tList
    gGame.Statistics = gGame.loadedData.Statistics
    gGame.Trophies = gGame.loadedData.Trophies
    tSW1 = (the systemDate).day
    if tList.sw1 = tSW1 then
      gGame.DailyPlayed = tList.DailyPlayed
    end if
    put "Updated the daily played tag"
    gGame.gameSaved = 1
  else
    gGame.gameSaved = 0
  end if
end

on SaveData me
  gGame.LocalSave = 1
  if (gGame.Cheat = 1) or (gGame.save = 0) or (gGame.LocalSave = 0) then
    put "Will not save because you are either a cheater or Pieter has turned it off!"
    exit
  end if
  tList = [:]
  tList[#game] = gGame.name
  tList[#version] = value(member("Version").text)[#version]
  tList[#LastDate] = the date
  tList[#LastTime] = the time
  tList[#PlayerName] = gGame.PlayerName
  tList[#Cash] = gGame.Cash
  tList[#car] = gGame.car
  tList[#DailyPlayed] = gGame.DailyPlayed
  tList[#sw1] = (the systemDate).day
  tList[#CarsList] = gGame.CarsList
  tList[#UpgradesList] = gGame.UpgradesList
  tList[#BodykitList] = gGame.BodykitList
  tList[#PrimaryWeaponsList] = gGame.PrimaryWeaponsList
  tList[#SecondaryWeaponsList] = gGame.SecondaryWeaponsList
  tList[#trackList] = gGame.trackList
  tList[#HiddenPackageList] = gGame.HiddenPackageList
  tList[#Statistics] = gGame.Statistics
  tList[#Trophies] = gGame.Trophies
  tCarList = ["BMW", "AstonMartin", "AudiR8", "Corvette", "DodgeRam", "Eclipse", "FordGT", "Marcos", "MiniCooper", "Mustang", "Nissan", "Porsche", "Seat", "Tank", "BlackTruck"]
  tCarData = [#bodyKit: [:], #upgrades: [:], #Weapons: [:]]
  repeat with i in tCarList
    tCarData[#bodyKit][symbol("Player" & i)] = gData.data.bodyKit[symbol("Player" & i)]
    tCarData[#upgrades][symbol("Player" & i)] = gData.data.upgrades[symbol("Player" & i)]
    tCarData[#Weapons][symbol("Player" & i)] = gData.data.Weapons[symbol("Player" & i)]
  end repeat
  tList[#carData] = tCarData
  EncodeAndSaveData(tList, 1)
  gGame.gameSaved = 1
  put "Data saved!"
end

on RestoreData me
  if gGame.Cheat = 1 then
    exit
  end if
  LoadData()
  if gGame.loadedData.count = 0 then
    return 0
  end if
  gGame.PlayerName = gGame.loadedData.PlayerName
  gGame.Cash = gGame.loadedData.Cash
  gGame.car = gGame.loadedData.car
  gGame.CarsList = gGame.loadedData.CarsList
  gGame.UpgradesList = gGame.loadedData.UpgradesList
  gGame.BodykitList = gGame.loadedData.BodykitList
  gGame.PrimaryWeaponsList = gGame.loadedData.PrimaryWeaponsList
  gGame.SecondaryWeaponsList = gGame.loadedData.SecondaryWeaponsList
  gGame.trackList = gGame.loadedData.trackList
  gGame.HiddenPackageList = gGame.loadedData.HiddenPackageList
  gGame.Statistics = gGame.loadedData.Statistics
  gGame.Trophies = gGame.loadedData.Trophies
  tCarList = ["BMW", "AstonMartin", "AudiR8", "Corvette", "DodgeRam", "Eclipse", "FordGT", "Marcos", "MiniCooper", "Mustang", "Nissan", "Porsche", "Seat", "Tank", "BlackTruck"]
  tCarData = [#bodyKit: [:], #upgrades: [:], #Weapons: [:]]
  repeat with i in tCarList
    gData.data.bodyKit[symbol("Player" & i)] = gGame.loadedData.carData.bodyKit[symbol("Player" & i)]
    gData.data.upgrades[symbol("Player" & i)] = gGame.loadedData.carData.upgrades[symbol("Player" & i)]
    gData.data.Weapons[symbol("Player" & i)] = gGame.loadedData.carData.Weapons[symbol("Player" & i)]
  end repeat
end

on SetupDefaultData me
  gGame.Cash = 10000
  gGame.car = "BMW"
  gGame.DailyPlayed = #new
  gGame.DailyTrack = #none
  gGame.CarsList = [#BMW: #Unlocked]
  gGame.UpgradesList = [:]
  gGame.BodykitList = [#BMW: [:], #AstonMartin: [:], #AudiR8: [:], #FordGT: [:], #Corvette: [:], #Eclipse: [:], #Mustang: [:], #Nissan: [:], #Porsche: [:], #Seat: [:], #MiniCooper: [:], #DodgeRam: [:], #Marcos: [:], #BlackTruck: [:], #Tank: [:]]
  gGame.PrimaryWeaponsList = [#noPrimary: #Unlocked, #MachineGun: #Unlocked]
  gGame.SecondaryWeaponsList = [#noSecondary: #Unlocked]
  gGame.trackList = [#CityTrack1: #new, #cityTrack2: #new, #CityTrack3: #new, #cityTrack4: #new]
  gGame.HiddenPackageList = []
  gGame.Statistics = [#time: 0, #wd: [0, 51], #played: 0, #Completed: 0, #failed: 0, #race: 0, #BattleRace: 0, #Rampage: 0, #RivalBattle: 0, #Survivor: 0, #GooseHunt: 0, #Elimination: 0, #BossBattle: 0, #Wrecked: 0, #rivalWrecked: 0, #vehicles: 0, #cars: [1, 16], #upgrades: [0, 5], #BODYKITS: [0, 50], #Weapons: [1, 8], #packages: [0, 51], #detonators: 0, #bullets: 0, #timeB: 0]
  gGame.Trophies = [#Worlddomination: 0, #ilikemoney: 0, #menacetosociety: 0, #toughguy: 0, #ibelieveicanfly: 0, #actionhero: 0, #speeddemon: 0, #GREEDY: 0, #godofwar: 0, #eyeofthetiger: 0, #thedestructor: 0, #imnoquitter: 0, #thunderstruck: 0, #monkeybusiness: 0, #pigsFTW: 0]
  gData.data.bodyKit = gData.data.Defaultbodykit.duplicate()
  gData.data.upgrades = gData.data.DefaultUpgrades.duplicate()
  gData.data.Weapons = gData.data.DefaultWeapons.duplicate()
end

on SetExitLock me
  _movie.exitLock = gGame.LockEscape
end

on closeRequest me
  if keyPressed(53) then
    exit
  end if
  _player.quit()
end

on StoreCastFilenames me
  g[#StoredCastFileNames] = []
  pCount = _movie.castLib.count
  repeat with i = 1 to pCount
    pCast = _movie.castLib[i].name
    pFilename = _movie.castLib[i].fileName
    g.StoredCastFileNames.add([pCast, pFilename])
    if pCast = "Internal" then
      next repeat
    end if
    if pCast = "Engine" then
      next repeat
    end if
    if pCast = "BurninRubber2" then
      next repeat
    end if
  end repeat
end

on RestoreCastFilenames me
  if getaProp(g, #StoredCastFileNames) = VOID then
    exit
  end if
  pCount = g.StoredCastFileNames
  repeat with i = 1 to pCount
    pName = g.StoredCastFileNames[i][1]
    pFilename = g.StoredCastFileNames[i][2]
    _movie.castLib(pName).fileName = pFilename
    alert(string(_movie.castLib(pName).fileName))
  end repeat
end

on reset tState
  ResetCasts()
  clearGlobals()
  _movie.timeoutList = []
  _movie.actorList = []
  if tState <> #nothing then
    dispatchcommand(35334)
    dispatchcommand(58370)
    dispatchcommand(4103)
    put "All is reset @ " & the time & the date & " from Message Window."
  end if
end

on ResetCasts
  ClearCast("Internal")
  ClearCast("Menu")
  ClearCast("TrackData")
  ClearCast("Shared")
  ClearCast("Cars")
  ClearCast("Tracks")
end

on PrePublish
  InitGlobals()
  load("\Data\PrePublishLoadingArray.txt")
  clearGlobals()
end

on Publish me
  reset()
  PrePublish()
  dispatchcommand(4104)
end

on UpdateVersion me
  tVersionData = value(member("Version").text)
  tNewVersion = tVersionData[#version] + 0.01
  tNewVersion = string(tNewVersion)
  tNewVersion = tNewVersion.char[1..4]
  tVersionData[#version] = value(tNewVersion)
  member("Version").text = string(tVersionData)
end

on ShowVersion me
  tVersion = value(member("Version").text)[#version]
  tVersion = string(tVersion).char[1..4]
  alert(string(gGame.name & " Version: " & tVersion))
end
