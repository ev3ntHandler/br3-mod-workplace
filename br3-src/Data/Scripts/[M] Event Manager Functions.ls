global g, gSystem, gLoader, gData, gSound, gGame

on AddScript tTarget, tDataList
  pValue = value(tTarget)
  if (pValue.ilk = #integer) and (pValue <> 0) then
    AddScriptToSprite(tTarget, tDataList)
  else
    AddScriptToScriptList(tTarget, tDataList)
  end if
end

on AddScriptToScriptList tTarget, tDataList
  tDataList = value(tDataList)
  pScriptName = value(tDataList)[#script]
  if (pScriptName = VOID) or (pScriptName = EMPTY) then
    ShowError("Function: AddScriptToSprite. Target: " & tTarget & " Parameters: " & tDataList & " Script was VOID.")
    exit
  end if
  pCount = _movie.castLib("Engine").member.count
  repeat with i = 1 to pCount
    pMember = _movie.castLib("Engine").member[i]
    if pMember.type = #script then
      pMemberName = _movie.castLib("Engine").member[i].name
      if pMemberName = pScriptName then
        exit repeat
      else
        if (i = pCount) and (pMemberName <> pScriptName) then
          ShowError("Function: AddScriptToSprite. Target: " & tTarget & " Parameters: " & tDataList & " Couldn't find this scriptname in 'Engine' cast.")
          exit
        end if
      end if
      next repeat
    end if
    next repeat
  end repeat
  pMember = member(tTarget)
  pMemberName = VOID
  if pMember <> VOID then
    pMemberName = pMember.name
  end if
  pSpriteNr = 1
  pDataList = tDataList[#data]
  if (pDataList = VOID) or (pDataList = EMPTY) or (pDataList.ilk <> #propList) then
    ShowError("Function: AddScript. Parameters: " & pDataList & " No correct datalist.")
    exit
  end if
  if (getaProp(pDataList, #memberName) = VOID) and (pMemberName <> VOID) then
    pDataList[#memberName] = pMemberName
  end if
  if (getaProp(pDataList, #SpriteNR) = VOID) and (pSpriteNr <> VOID) then
    pDataList[#SpriteNR] = pSpriteNr
  end if
  if tDataList[#system].ilk = #integer then
    tSystem = tDataList.system
  else
    tSystem = 0
  end if
  pScript = new(script(pScriptName), pDataList)
  if pScript <> VOID then
    if tSystem = 1 then
      gSystem.scriptList.add(pScript)
    else
      gGame.scriptList.add(pScript)
    end if
    if pDataList[#camera] = 1 then
      AddScript(pMember.name, [#script: "[PS] Camera", #data: [:]])
    end if
  end if
end

on AddScriptToSprite tTarget, tDataList
  pSpriteNr = value(tTarget)
  if (pSpriteNr = VOID) or (pSpriteNr.ilk <> #integer) then
    ShowError("Function: AddScriptToSprite. Target: " & tTarget & " Parameters: " & tDataList & " Target wasn't a integer or was VOID.")
    exit
  end if
  pSprite = sprite(pSpriteNr)
  if pSprite.member = member(0, 0) then
    ShowError("Function: AddScriptToSprite. Target: " & tTarget & " Parameters: " & tDataList & " There was no member/sprite in target channel.")
    exit
  end if
  pScriptName = value(tDataList)[#script]
  if (pScriptName = VOID) or (pScriptName = EMPTY) then
    ShowError("Function: AddScriptToSprite. Target: " & tTarget & " Parameters: " & tDataList & " Script was VOID.")
    exit
  end if
  pCount = _movie.castLib("Engine").member.count
  repeat with i = 1 to pCount
    pMember = _movie.castLib("Engine").member[i]
    if pMember.type = #script then
      pMemberName = _movie.castLib("Engine").member[i].name
      if pMemberName = pScriptName then
        exit repeat
      else
        if (i = pCount) and (pMemberName <> pScriptName) then
          ShowError("Function: AddScriptToSprite. Target: " & tTarget & " Parameters: " & tDataList & " Couldn't find this scriptname in 'Engine' cast.")
          exit
        end if
      end if
      next repeat
    end if
    next repeat
  end repeat
  pDataList = value(tDataList)[#data]
  if (pDataList = VOID) or (pDataList = EMPTY) or (pDataList.ilk <> #propList) then
    ShowError("Function: AddScriptToSprite. Parameters: " & pDataList & " No correct datalist.")
    exit
  end if
  if getaProp(pDataList, #memberName) = VOID then
    pDataList[#memberName] = pSprite.member.name
  end if
  if getaProp(pDataList, #SpriteNR) = VOID then
    pDataList[#SpriteNR] = pSpriteNr
  end if
  if (pSprite.scriptInstanceList = []) and (pSprite.member.type = #shockwave3d) then
    pScript = script("[PS] 3D Script Manager").new([#SpriteNR: pSpriteNr])
    pSprite.scriptInstanceList.add(pScript)
    AddScript(pSpriteNr, [#script: "[PS] Camera", #data: [:]])
    CreateProxyShader(pSprite.member)
    if getaProp(gGame, #FPSCounter) <> VOID then
      if gGame.FPSCounter = 1 then
        AddScript(pSpriteNr, [#script: "[PS] FPS Counter", #data: [:]])
      end if
    end if
  end if
  if pSprite.member.type = #shockwave3d then
    pSprite.scriptInstanceList[1].AddScript(pScriptName, pDataList)
  else
    pDataList[#SpriteNR] = pSpriteNr
    pScript = script(pScriptName).new(pDataList)
    pSprite.scriptInstanceList.add(pScript)
  end if
end

on DeleteScript me, tTarget, tDataList
  tDataList = value(tDataList)
  if tDataList.ilk <> #propList then
    return 0
  end if
  tList = value(tTarget)
  tList = tList.scriptList.duplicate()
  repeat with i in tList
    if voidp(i[#p]) = 0 then
      if voidp(i.p[#ScriptName]) = 0 then
        tName = i.p.ScriptName
        if tName = tDataList.name then
          tHandlers = i.handlers()
          if tHandlers.getPos(#delete) <> 0 then
            call(#delete, i)
          end if
        end if
      end if
    end if
  end repeat
end

on GetScript me, tTarget, tDataList
  if tDataList[#script].ilk = #string then
    tScript = tDataList.script
  else
    return 0
  end if
  repeat with i in gGame.scriptList
    if voidp(i[#p]) = 0 then
      if voidp(i.p[#ScriptName]) = 0 then
        if tScript = i.p.ScriptName then
          return i
        end if
      end if
    end if
  end repeat
  repeat with i in gSystem.scriptList
    if voidp(i[#p]) = 0 then
      if voidp(i.p[#ScriptName]) = 0 then
        if tScript = i.p.ScriptName then
          return i
        end if
      end if
    end if
  end repeat
  repeat with i in _movie.actorList
    if voidp(i[#p]) = 0 then
      if voidp(i.p[#ScriptName]) = 0 then
        if tScript = i.p.ScriptName then
          return i
        end if
      end if
    end if
  end repeat
end

on AddModule tTarget, tDataList
  pSpriteNr = value(tTarget)
  if (pSpriteNr = VOID) or (pSpriteNr.ilk <> #integer) then
    ShowError("Function: AddModule. Target: " & tTarget & " Parameters: " & tDataList & " Target wasn't a integer or was VOID.")
    exit
  end if
  pSprite = sprite(pSpriteNr)
  if pSprite.member = member(0, 0) then
    ShowError("Function: AddModule. Target: " & tTarget & " Parameters: " & tDataList & " There was no member/sprite in target channel.")
    exit
  end if
  pParentScriptName = value(tDataList)[#ScriptName]
  if (pParentScriptName = VOID) or (pParentScriptName = EMPTY) then
    ShowError("Function: AddModule. Target: " & tTarget & " Parameters: " & tDataList & " ScriptName was VOID. AddModule NEEDS a reference to parent script,")
    exit
  end if
  pScriptName = value(tDataList)[#script]
  if (pScriptName = VOID) or (pScriptName = EMPTY) then
    ShowError("Function: AddModule. Target: " & tTarget & " Parameters: " & tDataList & " Script was VOID.")
    exit
  end if
  pCount = _movie.castLib("Engine").member.count
  repeat with i = 1 to pCount
    pMember = _movie.castLib("Engine").member[i]
    if pMember.type = #script then
      pMemberName = _movie.castLib("Engine").member[i].name
      if pMemberName = pScriptName then
        exit repeat
      else
        if (i = pCount) and (pMemberName <> pScriptName) then
          ShowError("Function: AddModule. Target: " & tTarget & " Parameters: " & tDataList & " Couldn't find this scriptname in 'Engine' cast.")
          exit
        end if
      end if
      next repeat
    end if
    next repeat
  end repeat
  pDataList = value(tDataList)[#data]
  if (pDataList = VOID) or (pDataList = EMPTY) or (pDataList.ilk <> #propList) then
    ShowError("Function: AddScript. Parameters: " & pDataList & " No correct datalist.")
    exit
  end if
  if getaProp(pDataList, #memberName) = VOID then
    pDataList[#memberName] = pSprite.member.name
  end if
  if getaProp(pDataList, #SpriteNR) = VOID then
    pDataList[#SpriteNR] = pSpriteNr
  end if
  if pSprite.scriptInstanceList = [] then
    ShowError("Function: AddModule. Target: " & tTarget & " Parameters: " & tDataList & " Target sprite doesn't have any scripts attached to it.")
    exit
  end if
  pCount = pSprite.scriptInstanceList.count
  if pCount = 1 then
    pReturnedScriptName = pSprite.scriptInstanceList[1].p.ScriptName
    if (pReturnedScriptName <> VOID) and (pReturnedScriptName = pParentScriptName) then
      pSprite.scriptInstanceList.AddScript(pScriptName, pDataList)
    else
      if (pReturnedScriptName = "3D Script Manager") or (pReturnedScriptName = "2D Script Manager") then
        pCount2 = pSprite.scriptInstanceList[1].p.scriptList.count
        repeat with i = 1 to pCount2
          pSubReturnedScriptName = pSprite.scriptInstanceList[1].p.scriptList[i].p.ScriptName
          if pSubReturnedScriptName = pParentScriptName then
            pSprite.scriptInstanceList[1].p.scriptList[i].AddScript(pScriptName, pDataList)
            exit repeat
            next repeat
          end if
          if (i = pCount2) and (pSubReturnedScriptName <> pParentScriptName) then
            ShowError("Function: AddModule. Target: " & tTarget & " Parameters: " & tDataList & " No script with scriptname found... sorry...")
          end if
        end repeat
      end if
    end if
  end if
end

on SetAttribute tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: SetAttribute. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetAttribute. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pType = pDataList[#attribute]
  pModelName = pDataList[#ModelName]
  pString = pDataList[#string]
  if (pString = VOID) and (pModelName = VOID) then
    ShowError("Function: SetAttribute. Target: " & tTarget & " Parameters: " & tDataList & " No model (#modelName) found and #string obsolote in member (target).")
    exit
  else
    if pModelName <> VOID then
      pModelList = [pMember.model(pDataList[#ModelName])]
    end if
    if pString <> VOID then
      pModelList = GetModelList(pMember, pString)
    end if
  end if
  if pType = #floor then
    if getaProp(gGame, #FloorList) = VOID then
      gGame[#FloorList] = []
    end if
    pCount = pModelList.count
    repeat with i = 1 to pCount
      pmodel = pModelList[i]
      if pmodel = VOID then
        ShowError("Function: SetAttribute. Target: " & tTarget & " Parameters: " & tDataList & " Model does not exist in member (target).")
        next repeat
        next repeat
      end if
      gGame.FloorList.add(pmodel)
    end repeat
  end if
end

on RunHandler tTarget, tDataList
  ShowError("Function: RunHandler" && "Target" && tTarget && "DataList" && tDataList)
  pSprite = sprite(value(tTarget))
  if pSprite.member.name = EMPTY then
    ShowError("Function: RunHandler" && "Target" && tTarget && "DataList" && tDataList & " No sprite in this channel.")
    exit
  end if
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: LinkKey. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pHandler = VOID
  if getaProp(pDataList, #handler).ilk = #string then
    pHandler = pDataList[#handler]
  end if
  if pHandler = VOID then
    ShowError("Function: LinkKey. Target: " & tTarget & " Parameters: " & tDataList & " No handler.")
    exit
  end if
  pHandler = symbol(pHandler)
  pCount = pSprite.scriptInstanceList.count
  if pCount = 0 then
    ShowError("Function: LinkKey. Target: " & tTarget & " Parameters: " & tDataList & " This sprite doesn't have any scripts attached to it.")
    exit
  else
    repeat with i = 1 to pCount
      pScript = pSprite.scriptInstanceList[i]
      pHandlers = pScript.handlers()
      if pHandlers.getPos(pHandler) <> 0 then
        call(pHandler, pScript)
      end if
    end repeat
  end if
end

on DoHandler tTarget, tDataList, t1, t2
  ShowError("Function: DoHandler" && "Target" && tTarget && "DataList" && tDataList)
  do(tDataList & "(" & string(t1) & ")")
end

on goto tTarget, tDataList
  ShowError("Function: GoTo" && "Target" && tTarget && "DataList" && tDataList)
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: GoTo. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pFrame = VOID
  if getaProp(pDataList, #frame).ilk = #integer then
    pFrame = pDataList[#frame]
  end if
  if (pFrame <= 0) and (pFrame <> VOID) then
    ShowError("Function: GoTo. Target: " & tTarget & " Parameters: " & tDataList & " Frame below or equal to 0. What are you thinking...?!")
    exit
  end if
  pmarker = VOID
  if getaProp(pDataList, #marker).ilk = #string then
    pmarker = pDataList[#marker]
  end if
  pCount = _movie.markerlist().count
  repeat with i = 1 to pCount
    pMarkerToCheck = _movie.markerlist()[i]
    if pmarker = pMarkerToCheck then
      exit repeat
    end if
    if (pmarker <> pMarkerToCheck) and (i = pCount) then
      ShowError("Function: GoTo. Target: " & tTarget & " Parameters: " & tDataList & " No such maker found in score.")
      exit repeat
      exit
    end if
  end repeat
  if (pFrame = VOID) and (pmarker = VOID) then
    ShowError("Function: GoTo. Target: " & tTarget & " Parameters: " & tDataList & " Frame and marker both VOID.")
    exit
  end if
  if pFrame <> VOID then
    _movie.go(pFrame)
  end if
  if pmarker <> VOID then
    _movie.go(pmarker)
  end if
  _player.cursor(-1)
end

on CreateTimeOut tTarget, tDataList
  pTimeOUtName = tTarget
  if pTimeOUtName = VOID then
    pTimeOUtName = "GenericTimeOut" & string(_movie.timeoutList.count + 1)
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: CreateTimeOut. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pPeriod = 1.0 / gGame.tempo
  if getaProp(pDataList, #period).ilk = #integer then
    pPeriod = pDataList[#period]
  end if
  pHandler = #put
  if getaProp(pDataList, #handler).ilk = #symbol then
    pHandler = pDataList[#handler]
  end if
  PList = []
  if pDataList[#list] <> VOID then
    PList = pDataList[#list]
  end if
  timeout().new(pTimeOUtName, pPeriod, pHandler, PList)
end

on Iterate me, tTarget, tDataList
  if tTarget.ilk = #string then
    tTarget = value(tTarget)
  end if
  if tTarget.ilk <> #integer then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tEvent = VOID
  if tDataList[#event].ilk = #string then
    tEvent = tDataList.event
  end if
  repeat with i = 1 to tTarget
    gGame.Iteration = i
    event(tEvent)
  end repeat
  gGame.Iteration = VOID
  return 1
end
