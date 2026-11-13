property p
global gSystem, gGame

on new me, tParams
  p = [:]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = p.sprite.member
  p[#ScriptName] = "Script Manager"
  p[#me] = me
  return me
end

on enterFrame me
  call(#enterFrame, gSystem.scriptList)
  if gGame.pause = 1 then
    if voidp(gSystem[#InterPolatorList]) = 0 then
      if gSystem.InterPolatorList.count > 0 then
        Interpolator()
      end if
      exit
    end if
  end if
  call(#enterFrame, gGame.scriptList)
  RunHandlerList()
  EvalTriggers()
  UpdateTimers()
end

on keyUp me
  KeyHandler(_key.key)
  KeyHandler(_key.keyCode)
  if _key.commandDown and _key.shiftDown and (_key.key = "a") then
    Emo(0, p.SpriteNR)
  end if
end

on keyDown me
  if voidp(gGame[#EnterName]) = 0 then
    gGame.EnterName.keyDown(_key.key, _key.keyCode)
  end if
end

on mouseUp me
end

on delete me
  p.sprite.scriptInstanceList.deleteOne(p.me)
end
