global gSystem, gLoader, gData, gGame

on StringEvaluator tString
  pString = tString
  if (pString = VOID) or (pString.ilk <> #string) then
    ShowError("Function: StringEvaluator. String: " & tString & " No string or string type.")
    exit
  end if
  if pString contains "{" then
    PList = []
    pSubList = []
    repeat with i = 1 to pString.length
      pChar = pString.char[i]
      if pChar = "{" then
        pSubList.add(i)
      end if
      if pChar = "}" then
        pSubList.add(i)
        PList.add(pSubList)
        pSubList = []
      end if
    end repeat
    pVarStringList = []
    repeat with j = 1 to PList.count
      pVariable = chars(pString, PList[j][1] + 1, PList[j][2] - 1)
      pVarStringList.add(GetStringVariable(pVariable))
    end repeat
    repeat with k = PList.count down to 1
      pAmount = PList[k][2] - PList[k][1] + 1
      repeat with m = 1 to pAmount
        delete char PList[k][1] of pString
      end repeat
      put pVarStringList[k] before pString.char[PList[k][1]]
    end repeat
    if gSystem.local = 0 then
      pString = FormatURL(pString)
    end if
    return pString
  else
    if gSystem.local = 0 then
      pString = FormatURL(pString)
    end if
    return pString
  end if
end

on GetStringVariable tString
  if tString.char[1] = ":" then
    delete char 1 of tString
  end if
  tList = gGame
  if voidp(gGame[symbol(tString)]) = 0 then
    return string(gGame[symbol(tString)])
  end if
  if voidp(gSystem[symbol(tString)]) = 0 then
    return string(gSystem[symbol(tString)])
  end if
  if voidp(gLoader[symbol(tString)]) = 0 then
    return string(gLoader[symbol(tString)])
  end if
end

on FormatURL tString
  repeat with i = 1 to tString.length
    tChar = tString.char[i]
    if tChar = "\" then
      put "/" into tString.char[i]
    end if
  end repeat
  return tString
end

on SetItemDelimiter tChar
  the itemDelimiter = tChar
end

on ResetItemDelimiter
  the itemDelimiter = gSystem.itemDelimiter
end
