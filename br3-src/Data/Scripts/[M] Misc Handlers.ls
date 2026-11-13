global gGame

on GetEmptyChannel t1, t2
  if t1 = VOID then
    t1 = 1
  end if
  if t2 = VOID then
    t2 = _movie.lastChannel
  end if
  repeat with i = t1 to t2
    if sprite(i).member.name = EMPTY then
      exit repeat
    end if
  end repeat
  return i
end

on GetStageSize me
  prect = _movie.stage.rect
  pwidth = prect[3] - prect[1]
  pheight = prect[4] - prect[2]
  pStageSize = [pwidth, pheight]
  return pStageSize
end

on GetExternalCasts me
  pCount = _movie.castLib.count
  PList = []
  repeat with i = 1 to pCount
    pFilename = _movie.castLib[i].fileName
    if pFilename contains ".dir" then
      next repeat
    end if
    if pFilename contains ".dcr" then
      next repeat
    end if
    if pFilename contains ".dxr" then
      next repeat
    end if
    PList.add(_movie.castLib[i].name)
  end repeat
  return PList
end

on GetInternalCasts me
  pCount = _movie.castLib.count
  PList = []
  repeat with i = 1 to pCount
    pFilename = _movie.castLib[i].fileName
    if pFilename contains ".dir" then
      PList.add(_movie.castLib[i].name)
    end if
    if pFilename contains ".dcr" then
      PList.add(_movie.castLib[i].name)
    end if
    if pFilename contains ".dxr" then
      PList.add(_movie.castLib[i].name)
    end if
  end repeat
  return PList
end

on ShowCastNames me
  pCount = _movie.castLib.count
  repeat with i = 1 to pCount
    pName = _movie.castLib(i).name
    pFilename = _movie.castLib(i).fileName
    put pName && pFilename
  end repeat
end

on EncodeAndSaveData tObject, tEncode
  if tEncode = 1 then
    pString = EncodeHard(tObject)
  else
    pString = string(tObject)
  end if
  tResult = _player.setPref(gGame.PrefFile, pString)
  return tResult
end

on DecodeAndRetrieveData tString, tDecode
  if tDecode = 1 then
    pPropList = DecodeHard(tString)
  else
    pPropList = tString
    if pPropList.ilk = #string then
      pPropList = value(pPropList)
    end if
  end if
  return pPropList
end

on EncodeHard tObject
  pString = string(tObject)
  pLength = pString.length
  pEncodedString = EMPTY
  repeat with i = 1 to pLength
    pChar = pString.char[i]
    pCharString = string(pChar.charToNum)
    if pCharString.length = 2 then
      pCharString = "0" & pCharString
    end if
    pCharString = ConvertIntegerToChar(pCharString)
    pEncodedString = pEncodedString & pCharString
  end repeat
  return pEncodedString
end

on DecodeHard tString
  if tString.ilk <> #string then
    ShowError("No string to 'hard decode'")
    exit
  end if
  pPropListString = EMPTY
  pIntList = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
  pCount = tString.length / 3
  pCounter = 1
  repeat with i = 1 to pCount
    pCnt1 = pCounter
    pCnt2 = pCounter + 2
    pCharSet = tString.char[pCnt1..pCnt2]
    pIntCharSet = EMPTY
    repeat with j = 1 to 3
      pChar = pCharSet.char[j]
      pValue = pIntList.getPos(pChar)
      if pValue = 10 then
        pValue = 0
      end if
      pStringValue = string(pValue)
      pIntCharSet = pIntCharSet & pStringValue
    end repeat
    pNum = value(pIntCharSet)
    pFinalCHar = numToChar(pNum)
    pPropListString = pPropListString & pFinalCHar
    pCounter = pCounter + 3
  end repeat
  pPropList = value(pPropListString)
  return pPropList
end

on ConvertIntegerToChar tString
  pZeroList = "asdfghjkl"
  pIntList = "qwertyuiop"
  pNewString = EMPTY
  pCount = tString.length
  repeat with i = 1 to pCount
    pValue = value(tString.char[i])
    if i = 1 then
      if pValue = 0 then
        pNewChar = pZeroList.char[random(1, 9)]
      else
        pNewChar = pIntList.char[pValue]
      end if
    else
      if pValue = 0 then
        pValue = 10
      end if
      pNewChar = pIntList.char[pValue]
    end if
    pNewString = pNewString & pNewChar
  end repeat
  return pNewString
end

on Encode tString
  if tString.ilk <> #string then
    exit
  end if
  pRandomList = "qweasdzxcrtyfghvbnuiojklmp,[]: 0192837465#" & QUOTE
  pNormalList = "abcdefghijklmnopqrstuvwxyz" & QUOTE & "#0 123456789,:[]"
  pNewString = EMPTY
  pCount = tString.length
  repeat with i = 1 to pCount
    pOldChar = tString.char[i]
    repeat with j = 1 to pNormalList.length
      pCheckChar = pNormalList.char[j]
      if pCheckChar = pOldChar then
        pNewChar = pRandomList.char[j]
        pNewString = pNewString & pNewChar
        exit repeat
        next repeat
      end if
      next repeat
    end repeat
  end repeat
  return pNewString
end

on Decode tString
  if tString.ilk <> #string then
    exit
  end if
  pRandomList = "qweasdzxcrtyfghvbnuiojklmp,[]: 0192837465#" & QUOTE
  pNormalList = "abcdefghijklmnopqrstuvwxyz" & QUOTE & "#0 123456789,:[]"
  pNewString = EMPTY
  pCount = tString.length
  repeat with i = 1 to pCount
    pOldChar = tString.char[i]
    repeat with j = 1 to pRandomList.length
      pCheckChar = pRandomList.char[j]
      if pCheckChar = pOldChar then
        pNewChar = pNormalList.char[j]
        pNewString = pNewString & pNewChar
        exit repeat
        next repeat
      end if
      next repeat
    end repeat
  end repeat
  return pNewString
end

on GetTimeString tMillisec, tFormat
  sec = integer(tMillisec / 1000)
  min = integer(sec / 60)
  sec = sec - (min * 60)
  Hour = integer(min / 60)
  min = min - (Hour * 60)
  tMillisec = integer((tMillisec - (sec * 1000) - (min * 60 * 1000) - (Hour * 60 * 60 * 1000)) / 10.0)
  if tFormat = VOID then
    tFormat = #standard
  end if
  if tFormat = #standard then
    if min < 10 then
      minString = "0" & string(min + 100).char[3..3] & ":"
    else
      minString = string(min + 100).char[3..3] & ":"
    end if
    secString = string(sec + 100).char[2..3] & "."
    if tMillisec < 10 then
      MilliString = "0" & string(tMillisec)
    else
      MilliString = string(tMillisec)
    end if
    if tMillisec = 100 then
      MilliString = "00"
    end if
    return minString & secString & MilliString
  end if
end

on HoldAndDo me, tProperties, tTimeOut
  pToDo = tProperties[#ToDo]
  if (pToDo <> VOID) or (pToDo <> EMPTY) then
    do(pToDo)
  end if
  tTimeOut.forget()
end

on HoldAndGoTo me, tProperties, tTimeOut
  pmarker = tProperties[#marker]
  if pmarker <> VOID then
    _movie.go(pmarker)
  end if
  tTimeOut.forget()
end

on ManipulateTime tTarget, tDataList
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: ManipulateTime. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete set to [:].")
    pDataList = [:]
  end if
  pTargetTime = 1.0
  if getaProp(pDataList, #targetTime).ilk = #float then
    pTargetTime = pDataList[#targetTime]
  end if
  pDefaultStep = 0.29999999999999999
  if getaProp(pDataList, #defaultStep).ilk = #float then
    pDefaultStep = pDataList[#defaultStep]
  end if
  if gGame.TimeMP = pTargetTime then
    exit
  end if
  PList = [#targetTime: pTargetTime, #defaultStep: pDefaultStep, #Counter: 0]
  pPeriod = integer(1.0 / gGame.tempo * 1000.0)
  timeout().new("ManipulateTimeTimeOut", pPeriod, #manipulateTimeTimeOut, PList)
end

on manipulateTimeTimeOut tProperties, tTimeOut
  pTargetTime = tProperties[#targetTime]
  pDefaultStep = tProperties[#defaultStep]
  pCounter = tProperties[#Counter]
  pCounter = pCounter + 1
  tProperties[#Counter] = pCounter
  py = pDefaultStep / pCounter
  if pTargetTime < gGame.TimeMP then
    py = py * -1
  end if
  if py < 0.0 then
    if gGame.TimeMP > pTargetTime then
      gGame.TimeMP = gGame.TimeMP + py
    end if
    if gGame.TimeMP < pTargetTime then
      gGame.TimeMP = pTargetTime
      tTimeOut.forget()
    end if
  else
    if gGame.TimeMP < pTargetTime then
      gGame.TimeMP = gGame.TimeMP + py
    end if
    if gGame.TimeMP > pTargetTime then
      gGame.TimeMP = pTargetTime
      tTimeOut.forget()
    end if
  end if
end

on ClearTimeOutList me
  _movie.timeoutList = []
end

on ClearActorList me
  _movie.actorList = []
end

on fullscreen me
  if gGame.fullscreen = 1 then
    ResXoff()
    SetStageSize()
    gGame.fullscreen = 0
  else
    ResXon()
    gGame.fullscreen = 1
  end if
end

on SetStageSize me
  Display = resx_getDisplayMode()
  t = rect(0, 0, Display["xResolution"], Display["yResolution"])
  t1 = (t[3] / 2) - (gGame.resolution[1] / 2)
  t2 = (t[4] / 2) - (gGame.resolution[2] / 2)
  (the stage).rect = rect(t1, t2, t1 + gGame.resolution[1], t2 + gGame.resolution[2])
end

on ResXon me
  tempList = []
  tempList = resx_getDisplayMode()
  gGame[#OrigResolution] = tempList.duplicate()
  tempList[1] = gGame.resolution[1]
  tempList[2] = gGame.resolution[2]
  x = resx_setDisplayMode(tempList)
  if x = 0 then
  else
  end if
  (the stage).rect = (the desktopRectList)[1]
end

on ResXoff me
  x = resx_setDisplayMode(gGame.OrigResolution)
end

on GameQuit me
  _player.quit()
end
