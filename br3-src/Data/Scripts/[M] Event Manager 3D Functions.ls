global g, gSystem, gLoader, gData, gGame

on GetModelList tmember, tString, tIgnore
  tList = []
  if tmember = VOID then
    return tList
  end if
  if (tString = VOID) or (tString.ilk <> #string) then
    tString = EMPTY
  end if
  tCount = tmember.model.count
  repeat with i = 1 to tCount
    tmodel = tmember.model[i]
    if tmodel.name contains tIgnore then
      next repeat
    end if
    if tmodel.name contains tString then
      tList.add(tmodel)
    end if
  end repeat
  return tList
end

on getShaderList tmember, tString, tIgnore
  tList = []
  if tmember = VOID then
    return tList
  end if
  if (tString = VOID) or (tString.ilk <> #string) then
    tString = EMPTY
  end if
  tCount = tmember.shader.count
  repeat with i = 1 to tCount
    tShader = tmember.shader[i]
    if tShader.name contains tIgnore then
      next repeat
    end if
    if tShader.name contains tString then
      tList.add(tShader)
    end if
  end repeat
  return tList
end

on resetWorld me, tTarget
  if tTarget = VOID then
    return 
  end if
  ShowError(string("ResetWorld. Target:" && tTarget))
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("No such member. Target was: " & tTarget)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  pMember.resetWorld()
end

on RemoveLod tTarget, tDataList
  ShowError("RemoveLod" && "Target" && tTarget && "DataList" && tDataList)
  put tTarget
  pMember = member(tTarget)
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: BlackOut. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    pDataList = VOID
  end if
  pModelList = []
  if pMember = VOID then
    ShowError("No such member. Target was: " & tTarget)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pDataList = VOID then
    pModelList = GetModelList(pMember)
  else
    pModelList = pDataList[#modelList]
  end if
  if pModelList = VOID then
    ShowError("The modellist was empty or could not be initialized. Target was: " & tTarget & ". Datalist was: " && tDataList)
    exit
  end if
  pModelCount = pModelList.count
  repeat with j = 1 to pModelCount
    pmodel = pModelList[j]
    if pmodel = VOID then
      next repeat
    end if
    pResource = pmodel.resource
    if pResource = VOID then
      next repeat
    end if
    if pResource.type = #fromFile then
      pResource.lod.auto = 0
      pResource.lod.bias = 100
      pResource.lod.level = 100
    end if
  end repeat
end

on RemoveLodCast tTarget
  ShowError("RemoveLodCast" && "Target" && tTarget)
  pMemberCount = _movie.castLib(tTarget).member.count
  repeat with j = 1 to pMemberCount
    pMemberType = member(j, tTarget).type
    if pMemberType = #shockwave3d then
      pMember = member(j, tTarget)
      pModelCount = pMember.model.count
      repeat with i = 1 to pModelCount
        pModelName = pMember.model[i].name
        pMember.modelResource(pModelName).lod.auto = 0
        pMember.modelResource(pModelName).lod.bias = 100
        pMember.modelResource(pModelName).lod.level = 100
      end repeat
    end if
  end repeat
end

on ADDMESHMODIFIER tTarget, tDataList
  ShowError(string("AddMeshModifier" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: BlackOut. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    pDataList = VOID
  end if
  pModelList = []
  if pMember = VOID then
    ShowError("No such member. Member was: " & pMember)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pDataList = VOID then
    pModelList = GetModelList(pMember)
  else
    pModelList = pDataList[#modelList]
  end if
  if pModelList = VOID then
    ShowError("The modellist was empty or could not be initialized. Target was: " & tTarget & ". Datalist was: " && tDataList)
    exit
  end if
  pModelCount = pModelList.count
  repeat with j = 1 to pModelCount
    pmodel = pModelList[j]
    if pmodel = VOID then
      next repeat
    end if
    pmodel.addModifier(#meshDeform)
  end repeat
end

on createTexture tTarget, tDataList
  ShowError(string("CreateTexture" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  pDataList = value(tDataList)
  pCast = pDataList[#cast]
  pFilename = pDataList[#fileName]
  pFiltering = pDataList[#filtering]
  pRenderFormat = pDataList[#renderFormat]
  pNearFiltering = pDataList[#nearFiltering]
  pDownScale = pDataList[#downScale]
  pOverride = pDataList[#Override]
  if pMember = VOID then
    ShowError("No such member. Member was: " & pMember)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pDataList = [:] then
    ShowError("A datalist WAS expected. Target was: " & tTarget & " and Datalist was: " & pDataList)
    exit
  end if
  if pCast = VOID then
    pCast = pMember.cast.name
  end if
  if pFilename = VOID then
    ShowError("No filename. This is needed! DataList was: " & pDataList)
    exit
  else
    if member(pFilename) = VOID then
      ShowError("No such member for texture. DataList was: " & pDataList)
      exit
    else
      if member(pFilename).type <> #bitmap then
        ShowError("Member is no bitmap. DataList was: " & pDataList)
        exit
      end if
    end if
  end if
  if pMember.texture(pFilename) <> VOID then
    ShowError("Texture already exists. Creation is cancelled. DataList was: " & pDataList)
    exit
  end if
  if pFiltering = VOID then
    pFiltering = #high
  end if
  if member(pFilename).useAlpha = 1 then
    if pRenderFormat = VOID then
      pRenderFormat = #rgba8888
    end if
  end if
  if pRenderFormat = VOID then
    pRenderFormat = #rgba5650
  end if
  if pNearFiltering.ilk <> #integer then
    pNearFiltering = 1
  end if
  if pDownScale = VOID then
    pDownScale = 0
  end if
  if pOverride = VOID then
    pOverride = 0
  end if
  pTexture = pMember.newTexture(pFilename)
  pTexture.member = member(pFilename)
  pTexture.quality = pFiltering
  pTexture.renderFormat = pRenderFormat
  pTexture.nearFiltering = pNearFiltering
  pTexture.compressed = 0
  if pDownScale <> 0 then
    repeat with k = 1 to pDownScale
      pTexture.scaleDown()
    end repeat
  end if
  if gSystem.debug = 1 then
  else
    member(pFilename).unload()
  end if
  return pTexture
end

on ASSIGNTEXTURE tTarget, tDataList
  ShowError(string("AssignTexture" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  pDataList = value(tDataList)
  pCast = pDataList[#cast]
  pMaterial = pDataList[#material]
  pTexture1 = pDataList[#texture1]
  pTexture2 = pDataList[#texture2]
  pTexture3 = pDataList[#texture3]
  pTexture4 = pDataList[#texture4]
  pTexture5 = pDataList[#texture5]
  pTexture6 = pDataList[#texture6]
  pTexture7 = pDataList[#texture7]
  pTexture8 = pDataList[#texture8]
  pLightmap = pDataList[#lightmap]
  pAddMap = pDataList[#AddMap]
  pTextureList = [pTexture1, pTexture2, pTexture3, pTexture4, pTexture5, pTexture6, pTexture7, pTexture8]
  if pMember = VOID then
    ShowError("No such member. Member was: " & pMember)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pDataList = [:] then
    ShowError("A datalist WAS expected. Target was: " & tTarget & " and Datalist was: " & pDataList)
    exit
  end if
  if pCast = VOID then
    pCast = pMember.cast.name
  end if
  if pMaterial = VOID then
    ShowError("No material specified. This is needed for AssignTexture. Material was: " & pMaterial)
    exit
  end if
  if pMember.shader(pMaterial) = VOID then
    ShowError("No such material in this 3d member. Material was: " & pMaterial)
    exit
  end if
  pTextureList = [pTexture1, pTexture2, pTexture3, pTexture4, pTexture5, pTexture6, pTexture7, pTexture8]
  pCount = pTextureList.count
  repeat with i = 1 to pCount
    if pTextureList[i] = VOID then
      next repeat
    end if
    if pMember.texture(pTextureList[i]) = VOID then
      ShowError("No such texture in this 3d member. Texture was: " & pTextureList[i] && "AssignTexture" && pMember)
      next repeat
      next repeat
    end if
    pMember.shader(pMaterial).textureList[i] = pMember.texture(pTextureList[i])
  end repeat
  if pAddMap <> VOID then
    pMember.shader(pMaterial).flat = 1
    pMember.shader(pMaterial).blendFunctionList[1] = #replace
    pMember.shader(pMaterial).textureList[2] = pMember.texture(pAddMap)
    pMember.shader(pMaterial).blendFunctionList[2] = #add
    if pLightmap <> VOID then
      pMember.shader(pMaterial).textureList[3] = pMember.texture(pLightmap)
      pMember.shader(pMaterial).blendFunctionList[3] = #multiply
    end if
  else
    pMember.shader(pMaterial).blendFunctionList[1] = #multiply
    if pLightmap <> VOID then
      pMember.shader(pMaterial).flat = 1
      pMember.shader(pMaterial).blendFunctionList[1] = #replace
      pMember.shader(pMaterial).textureList[2] = pMember.texture(pLightmap)
      pMember.shader(pMaterial).blendFunctionList[2] = #multiply
      pMember.shader(pMaterial).transparent = 0
    end if
  end if
end

on SetTexture tTarget, tDataList
  ShowError(string("SetTexture" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  pDataList = value(tDataList)
  pCast = pDataList[#cast]
  pFilename = pDataList[#fileName]
  pFiltering = pDataList[#filtering]
  pRenderFormat = pDataList[#renderFormat]
  pNearFiltering = pDataList[#nearFiltering]
  pDownScale = pDataList[#downScale]
  if pMember = VOID then
    ShowError("No such member. Member was: " & pMember)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pDataList = [:] then
    ShowError("A datalist WAS expected. Target was: " & tTarget & " and Datalist was: " & pDataList)
    exit
  end if
  if pCast = VOID then
    pCast = pMember.cast.name
  end if
  if pFilename = VOID then
    ShowError("No filename. This is needed! DataList was: " & pDataList)
    exit
  else
    if pMember.texture(pFilename) = VOID then
      ShowError("No such texture in this 3d member. DataList was: " & pDataList && "SetTexture" && pMember)
      exit
    end if
  end if
  if pFiltering = VOID then
    pFiltering = #lowFiltered
  end if
  if pRenderFormat = VOID then
    pRenderFormat = #rgba5650
  end if
  if pNearFiltering.ilk <> #integer then
    pNearFiltering = 1
  end if
  if pDownScale = VOID then
    pDownScale = 0
  end if
  pTexture = pMember.texture(pFilename)
  pTexture.quality = pFiltering
  pTexture.renderFormat = pRenderFormat
  pTexture.nearFiltering = pNearFiltering
  pTexture.compressed = 0
  if pDownScale <> 0 then
    repeat with k = 1 to pDownScale
      pTexture.scaleDown()
    end repeat
  end if
end

on deleteTexture tTarget, tDataList
  ShowError("Function: DeleteTexture" && "Target" && tTarget && "DataList" && tDataList)
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: DeleteTexture. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: DeleteTexture. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pTextureName = VOID
  if getaProp(pDataList, #TextureName).ilk = #string then
    pTextureName = pDataList[#TextureName]
  end if
  pTexture = pMember.texture(pTextureName)
  if pTexture <> VOID then
    pMember.deleteTexture(pTextureName)
    ShowError("Function: DeleteTexture. Target: " & tTarget & " Parameters: " & tDataList & " Texture deleted.")
  end if
end

on SETMATERIAL tTarget, tDataList
  ShowError(string("SetMaterial" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  if (pMember = VOID) or (pMember.type <> #shockwave3d) then
    ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " No such member or no shockwave3d member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pMaterialName = VOID
  if getaProp(pDataList, #materialName).ilk = #string then
    pMaterialName = pDataList[#materialName]
  end if
  if pMaterialName = VOID then
    ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " No (correct) materialname.")
    exit
  end if
  pMaterial = pMember.shader(pMaterialName)
  if pMaterial = VOID then
    ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " No such material in this member.")
    exit
  end if
  pCast = pMember.cast.name
  if getaProp(pDataList, #castName).ilk = #string then
    pCast = pDataList[#castName]
  end if
  pAmbient = pMaterial.ambient
  if getaProp(pDataList, #ambient).ilk = #color then
    pMaterial.ambient = pDataList[#ambient]
  end if
  pDiffuse = pMaterial.diffuse
  if getaProp(pDataList, #diffuse).ilk = #color then
    pMaterial.diffuse = pDataList[#diffuse]
  end if
  pEmissive = pMaterial.emissive
  if getaProp(pDataList, #emissive).ilk = #color then
    pMaterial.emissive = pDataList[#emissive]
  end if
  pSpecularColor = pMaterial.specular
  if getaProp(pDataList, #specular).ilk = #color then
    pMaterial.specular = pDataList[#specular]
  end if
  pSpecularStrength = pMaterial.shininess
  if getaProp(pDataList, #shininess).ilk = #float then
    pMaterial.shininess = pDataList[#shininess]
  end if
  pUseDiffTexture = pMaterial.useDiffuseWithTexture
  if getaProp(pDataList, #useDiffuseWithTexture).ilk = #integer then
    pMaterial.useDiffuseWithTexture = pDataList[#useDiffuseWithTexture]
  end if
  pBlend = pMaterial.blend
  if getaProp(pDataList, #blend).ilk = #integer then
    pMaterial.blend = pDataList[#blend]
  end if
  pTransparent = pMaterial.transparent
  if getaProp(pDataList, #transparent).ilk = #integer then
    pMaterial.transparent = pDataList[#transparent]
  end if
  pFlat = pMaterial.flat
  if getaProp(pDataList, #flat).ilk = #integer then
    pMaterial.flat = pDataList[#flat]
  end if
  pRenderStyle = pMaterial.renderStyle
  if getaProp(pDataList, #renderStyle).ilk = #symbol then
    case pRenderStyle of
      #point:
        pMaterial.renderStyle = #point
      #wire:
        pMaterial.renderStyle = #wire
      #fill:
        pMaterial.renderStyle = #fill
      otherwise:
        ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " Unsupported renderstyle.")
    end case
  end if
  pTexture1 = pDataList[#texture1]
  pTextureMode1 = pDataList[#textureMode1]
  pBlendFunction1 = pDataList[#blendFunction1]
  pBlendSource1 = pDataList[#blendSource1]
  pBlendConstant1 = pDataList[#blendConstant1]
  pTextureRepeat1 = pDataList[#textureRepeat1]
  pTexturePosition1 = pDataList[#texturePosition1]
  pTextureScale1 = pDataList[#textureScale1]
  pTexture2 = pDataList[#texture2]
  pTextureMode2 = pDataList[#TextureMode2]
  pBlendFunction2 = pDataList[#BlendFunction2]
  pBlendSource2 = pDataList[#blendSource2]
  pBlendConstant2 = pDataList[#blendConstant2]
  pTextureRepeat2 = pDataList[#textureRepeat2]
  pTexturePosition2 = pDataList[#texturePosition2]
  pTextureScale2 = pDataList[#textureScale2]
  pTexture3 = pDataList[#texture3]
  pTextureMode3 = pDataList[#textureMode3]
  pBlendFunction3 = pDataList[#blendFunction3]
  pBlendSource3 = pDataList[#blendSource3]
  pBlendConstant3 = pDataList[#blendConstant3]
  pTextureRepeat3 = pDataList[#textureRepeat3]
  pTexturePosition3 = pDataList[#texturePosition3]
  pTextureScale3 = pDataList[#textureScale3]
  pTexture4 = pDataList[#texture4]
  pTextureMode4 = pDataList[#textureMode4]
  pBlendFunction4 = pDataList[#blendFunction4]
  pBlendSource4 = pDataList[#blendSource4]
  pBlendConstant4 = pDataList[#blendConstant4]
  pTextureRepeat4 = pDataList[#textureRepeat4]
  pTexturePosition4 = pDataList[#texturePosition4]
  pTextureScale4 = pDataList[#textureScale4]
  pTexture5 = pDataList[#texture5]
  pTextureMode5 = pDataList[#textureMode5]
  pBlendFunction5 = pDataList[#blendFunction5]
  pBlendSource5 = pDataList[#blendSource5]
  pBlendConstant5 = pDataList[#blendConstant5]
  pTextureRepeat5 = pDataList[#textureRepeat5]
  pTexturePosition5 = pDataList[#texturePosition5]
  pTextureScale5 = pDataList[#textureScale5]
  pTexture6 = pDataList[#texture6]
  pTextureMode6 = pDataList[#textureMode6]
  pBlendFunction6 = pDataList[#blendFunction6]
  pBlendSource6 = pDataList[#blendSource6]
  pBlendConstant6 = pDataList[#blendConstant6]
  pTextureRepeat6 = pDataList[#textureRepeat6]
  pTexturePosition6 = pDataList[#texturePosition6]
  pTextureScale6 = pDataList[#textureScale6]
  pTexture7 = pDataList[#texture7]
  pTextureMode7 = pDataList[#textureMode7]
  pBlendFunction7 = pDataList[#blendFunction7]
  pBlendSource7 = pDataList[#blendSource7]
  pBlendConstant7 = pDataList[#blendConstant7]
  pTextureRepeat7 = pDataList[#textureRepeat7]
  pTexturePosition7 = pDataList[#texturePosition7]
  pTextureScale7 = pDataList[#textureScale7]
  pTexture8 = pDataList[#texture8]
  pTextureMode8 = pDataList[#textureMode8]
  pBlendFunction8 = pDataList[#blendFunction8]
  pBlendSource8 = pDataList[#blendSource8]
  pBlendConstant8 = pDataList[#blendConstant8]
  pTextureRepeat8 = pDataList[#textureRepeat8]
  pTexturePosition8 = pDataList[#texturePosition8]
  pTextureScale8 = pDataList[#textureScale8]
  pTextureList = [pTexture1, pTexture2, pTexture3, pTexture4, pTexture5, pTexture6, pTexture7, pTexture8]
  pTextureModeList = [pTextureMode1, pTextureMode2, pTextureMode3, pTextureMode4, pTextureMode5, pTextureMode6, pTextureMode7, pTextureMode8]
  pBlendFunctionList = [pBlendFunction1, pBlendFunction2, pBlendFunction3, pBlendFunction4, pBlendFunction5, pBlendFunction6, pBlendFunction7, pBlendFunction8]
  pBlendSourceList = [pBlendSource1, pBlendSource2, pBlendSource3, pBlendSource4, pBlendSource5, pBlendSource6, pBlendSource7, pBlendSource8]
  pBlendConstantList = [pBlendConstant1, pBlendConstant2, pBlendConstant3, pBlendConstant4, pBlendConstant5, pBlendConstant6, pBlendConstant7, pBlendConstant8]
  PTextureRepeatList = [pTextureRepeat1, pTextureRepeat2, pTextureRepeat3, pTextureRepeat4, pTextureRepeat5, pTextureRepeat6, pTextureRepeat7, pTextureRepeat8]
  pTexturePositionList = [pTexturePosition1, pTexturePosition2, pTexturePosition3, pTexturePosition4, pTexturePosition5, pTexturePosition6, pTexturePosition7, pTexturePosition8]
  ptextureScaleList = [pTextureScale1, pTextureScale2, pTextureScale3, pTextureScale4, pTextureScale5, pTextureScale6, pTextureScale7, pTextureScale8]
  pCount = pTextureList.count
  repeat with i = 1 to pCount
    if pTextureList[i] = VOID then
      next repeat
    end if
    if (pMember.texture(pTextureList[i]) = VOID) or (pTextureList[i].ilk <> #string) then
      ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " No such texture in this member.")
      next repeat
      next repeat
    end if
    pMaterial.textureList[i] = pMember.texture(pTextureList[i])
  end repeat
  pCount = pTextureModeList.count
  repeat with i = 1 to pCount
    if pTextureModeList[i] = VOID then
      next repeat
      next repeat
    end if
    pmode = pTextureModeList[i]
    case pmode of
      #none:
        nothing()
      #wrapPlanar:
        nothing()
      #wrapCylindrical:
        nothing()
      #wrapSpherical:
        nothing()
      #reflection:
        nothing()
      #diffuseLight:
        nothing()
      #specularLight:
        nothing()
      otherwise:
        ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " Unsupported texturemode.")
        next repeat
    end case
    pMaterial.textureModeList[i] = pmode
  end repeat
  pCount = pBlendFunctionList.count
  repeat with i = 1 to pCount
    if pBlendFunctionList[i] = VOID then
      next repeat
      next repeat
    end if
    pmode = pBlendFunctionList[i]
    case pmode of
      #multiply:
        nothing()
      #add:
        nothing()
      #replace:
        nothing()
      #blend:
        nothing()
      otherwise:
        ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " Unsupported blendfunction.")
        next repeat
    end case
    pMaterial.blendFunctionList[i] = pmode
  end repeat
  pCount = pBlendSourceList.count
  repeat with i = 1 to pCount
    if pBlendSourceList[i] = VOID then
      next repeat
      next repeat
    end if
    pmode = pBlendSourceList[i]
    case pmode of
      #constant:
        nothing()
      #alpha:
        nothing()
      otherwise:
        ShowError("Function: SetMaterial. Target: " & tTarget & " Parameters: " & tDataList & " Unsupported blendsource.")
        next repeat
    end case
    pMaterial.blendSourceList[i] = pmode
  end repeat
  pCount = pBlendConstantList.count
  repeat with i = 1 to pCount
    if pBlendConstantList[i].ilk <> #integer then
      next repeat
      next repeat
    end if
    pAmount = pBlendConstantList[i]
    if pAmount.ilk <> #integer then
      pAmount = 50
    end if
    pMaterial.blendConstantList[i] = pAmount
  end repeat
  pCount = PTextureRepeatList.count
  repeat with i = 1 to pCount
    if PTextureRepeatList[i].ilk = #integer then
      pMaterial.textureRepeatList[i] = PTextureRepeatList[i]
      next repeat
    end if
    next repeat
  end repeat
  pCount = pTexturePositionList.count
  repeat with i = 1 to pCount
    if (pTexturePositionList[i] = VOID) or (pTexturePositionList[i].ilk <> #vector) then
      next repeat
      next repeat
    end if
    pVector = pTexturePositionList[i]
    if pVector.ilk <> #vector then
      pVector = vector(1.0, 1.0, 1.0)
    end if
    pMaterial.textureTransformList[i].position = pVector
  end repeat
  pCount = ptextureScaleList.count
  repeat with i = 1 to pCount
    if (ptextureScaleList[i] = VOID) or (ptextureScaleList[i].ilk <> #vector) then
      next repeat
      next repeat
    end if
    pVector = ptextureScaleList[i]
    if pVector.ilk <> #vector then
      pVector = vector(1.0, 1.0, 1.0)
    end if
    pMaterial.textureTransformList[i].scale = pVector
  end repeat
end

on CleanMaterials tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: CleanMaterials. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pMaterialList = []
  pCount = pMember.model.count
  repeat with i = 1 to pCount
    pmodel = pMember.model[i]
    pShaderCount = pmodel.shaderList.count
    repeat with j = 1 to pShaderCount
      pShader = pmodel.shaderList[j]
      if pMaterialList.getPos(pShader) = 0 then
        pMaterialList.add(pShader.name)
      end if
    end repeat
  end repeat
  pDeleteList = []
  pCount = pMember.shader.count
  repeat with i = 1 to pCount
    pShader = pMember.shader[i]
    if pMaterialList.getPos(pShader.name) = 0 then
      pDeleteList.add(pShader.name)
    end if
  end repeat
  pCount = pDeleteList.count
  repeat with i = 1 to pCount
    pMember.deleteShader(pDeleteList[i])
  end repeat
end

on CleanGroups tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: CleanGroups. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: CleanGroups. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  tGroupName = "World"
  if getaProp(pDataList, #groupName).ilk = #string then
    tGroupName = pDataList[#groupName]
  end if
  tString = EMPTY
  if getaProp(pDataList, #string).ilk = #string then
    tString = pDataList[#string]
  end if
  tList = []
  tList.add(tGroupName)
  if tString <> EMPTY then
    tCount = pMember.group.count
    repeat with i = 1 to tCount
      tGroupName = pMember.group[i].name
      if tGroupName contains tString then
        tList.add(tGroupName)
      end if
    end repeat
  end if
  repeat with i in tList
    if i = "World" then
      next repeat
    end if
    pMember.deleteGroup(i)
  end repeat
end

on setCamera tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: SetCamera. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetCamera. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pcamera = pMember.camera(pDataList[#cameraName])
  if pcamera = VOID then
    ShowError("Function: SetCamera. Target: " & tTarget & " Parameters: " & tDataList & " No such camer(name) in this member (target).")
    exit
  end if
  pHither = pDataList[#near]
  if (pHither <> VOID) and (pHither.ilk = #float) then
    pcamera.hither = pHither
  end if
  pYon = pDataList[#far]
  if (pYon <> VOID) and (pYon.ilk = #float) then
    pcamera.yon = pYon
  end if
  pFov = pDataList[#fov]
  if (pFov <> VOID) and (pFov.ilk = #float) then
    pcamera.fieldOfView = pFov
  end if
  pProjection = pDataList[#projection]
  if pProjection <> VOID then
    if (pProjection = #orthographic) or (pProjection = #perspective) then
      pcamera.projection = pProjection
    end if
  end if
  pOrthoHeight = pDataList[#orthoHeight]
  if (pOrthoHeight <> VOID) and (pOrthoHeight.ilk = #float) then
    pcamera.orthoHeight = pOrthoHeight
  end if
  pClearAtRender = pDataList[#clearAtRender]
  if pClearAtRender.ilk = #integer then
    if (pClearAtRender = 0) or (pClearAtRender = 1) then
      pcamera.colorBuffer.clearAtRender = pClearAtRender
    end if
  end if
  pClearValue = pDataList[#clearValue]
  if (pClearValue <> VOID) and (pClearValue.ilk = #color) then
    pcamera.colorBuffer.clearValue = pClearValue
  end if
  prect = pDataList[#rect]
  if (prect <> VOID) and (prect.ilk = #rect) then
    pcamera.rect = prect
  end if
end

on CloneCameras tTarget, tDataList
  ShowError(string("CloneCameras" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  pDataList = tDataList
  pCloneMember = member(pDataList[#cloneMember])
  if pMember = VOID then
    ShowError("No such member. Target was: " & tTarget)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pCloneMember = VOID then
    ShowError("No such cloneMember. DataList was: " & pDataList)
    exit
  end if
  if pCloneMember.type <> #shockwave3d then
    ShowError("No 3d cloneMember. DataList was: " & pDataList)
    exit
  end if
  if pDataList = [:] then
    ShowError("A datalist WAS expected. Target was: " & tTarget & " and Datalist was: " & pDataList)
    exit
  end if
  pCount = pCloneMember.camera.count
  repeat with i = 1 to pCount
    pCameraName = pCloneMember.camera[i].name
    if pCameraName = "DefaultView" then
      next repeat
    end if
    pOldCamera = pCloneMember.camera(pCameraName)
    pNewCamera = pMember.newCamera(pCameraName)
    pNewCamera.transform = pOldCamera.transform
    pNewCamera.hither = pOldCamera.hither
    pNewCamera.yon = pOldCamera.yon
    pNewCamera.rect = pOldCamera.rect
    pNewCamera.projection = pOldCamera.projection
    pNewCamera.fieldOfView = pOldCamera.fieldOfView
    pNewCamera.orthoHeight = pOldCamera.orthoHeight
    pNewCamera.colorBuffer.clearAtRender = pOldCamera.colorBuffer.clearAtRender
    pNewCamera.colorBuffer.clearValue = pOldCamera.colorBuffer.clearValue
    pNewCamera.fog.enabled = pOldCamera.fog.enabled
    pNewCamera.fog.near = pOldCamera.fog.near
    pNewCamera.fog.far = pOldCamera.fog.far
    pNewCamera.fog.color = pOldCamera.fog.color
    pNewCamera.fog.decayMode = pOldCamera.fog.decayMode
  end repeat
end

on ActivateCamera tTarget, tDataList
  ShowError(string("SetTexture" && "Target" && tTarget && "DataList" && tDataList))
  pSprite = sprite(value(tTarget))
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  pcamera = pSprite.member.camera(pDataList[#camera])
  if pSprite.member.name = EMPTY then
    ShowError("No sprite in target channel. Targetchannel was: " & tTarget)
    exit
  end if
  if pSprite.member.type <> #shockwave3d then
    ShowError("No 3d member. Target was: sprite(" & tTarget & ")")
    exit
  end if
  if pDataList = [:] then
    ShowError("A datalist WAS expected. Target was: " & tTarget & " and Datalist was: " & pDataList)
    exit
  end if
  if pSprite.member.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pcamera = VOID then
    ShowError("No such camera in this 3d member. DataList was: " & pDataList)
    exit
  end if
  _movie.updateStage()
  pSprite.camera = pcamera
end

on CLONEMODELS tTarget, tDataList
  ShowError(string("CloneModels" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if pDataList.ilk <> #propList then
    ShowError("Function: CloneModels. The incoming datalist was not a list.")
    exit
  end if
  pModelList = pDataList[#modelList]
  pNameList = pDataList[#NameList]
  pShaderTag = pDataList[#cloneShaderTag]
  pCloneMember = member(pDataList[#cloneMember])
  if pMember = VOID then
    ShowError("No such member. Target was: " & tTarget)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pCloneMember = VOID then
    ShowError("No such cloneMember. DataList was: " & pDataList)
    exit
  end if
  if pCloneMember.type <> #shockwave3d then
    ShowError("No 3d cloneMember. DataList was: " & pDataList)
    exit
  end if
  if pModelList = VOID then
    pModelList = []
    pModelListTemp = GetModelList(pCloneMember)
    pCount = pModelListTemp.count
    repeat with k = 1 to pCount
      pName = pModelListTemp[k].name
      pModelList.add(pName)
    end repeat
  else
    pModelList = pDataList[#modelList]
  end if
  if pNameList = VOID then
    pNameList = []
    ShowError("There was no namelist so cloned objects will not be renamed. Target was: " & tTarget & ". Datalist was: " && tDataList)
  end if
  if pModelList = VOID then
    ShowError("The modellist was empty or could not be initialized. Target was: " & tTarget & ". Datalist was: " && tDataList)
    exit
  end if
  pCount = pModelList.count
  repeat with i = 1 to pCount
    pModelName = pModelList[i]
    if pNameList <> [] then
      pNewName = pNameList[i]
    else
      pNewName = pModelName
    end if
    if pMember.model(pNewName) <> VOID then
      ShowError("Model already exists. No cloning: " & pNewName)
      next repeat
    end if
    pShaderList = pCloneMember.model(pModelName).shaderList
    pShaderListCount = pShaderList.count
    pTextureList = []
    pEntryTextureList = []
    repeat with l = 1 to pShaderListCount
      pEntryTextureList = pShaderList[l].textureList
      pTextureList.add(pEntryTextureList)
    end repeat
    pModelResourceName = pCloneMember.modelResource(pModelName).name
    pClonedModel = pMember.cloneModelFromCastmember(pNewName, pModelName, pCloneMember)
    repeat with m = 1 to pShaderListCount
      pShader = pMember.shader(pShaderList[m].name)
      pMember.model(pNewName).shaderList[m] = pShader
      pNewTextureList = []
      repeat with n = 1 to 8
        if pTextureList[m][n] = VOID then
          pEntry = VOID
        else
          pTextureName = pTextureList[m][n].name
          pEntry = pMember.texture(pTextureName)
        end if
        pNewTextureList.add(pEntry)
      end repeat
      repeat with a = 1 to 8
        if pNewTextureList[a] <> VOID then
          pShader.textureList[a] = pMember.texture(pNewTextureList[a].name)
          next repeat
        end if
        pShader.textureList[a] = VOID
      end repeat
    end repeat
    if pMember.modelResource(pModelResourceName) <> VOID then
      pClonedModel.resource = pMember.modelResource(pModelResourceName)
    end if
    pDuplicateModelResourceListCount = pMember.modelResource.count
    pDuplicateModelResourceList = []
    repeat with j = 1 to pDuplicateModelResourceListCount
      pModelResourceName = pMember.modelResource[j].name
      if pModelResourceName contains "-clone" then
        pDuplicateModelResourceList.add(pModelResourceName)
      end if
    end repeat
    pCountHOEVEEL = pDuplicateModelResourceList.count
    repeat with plop = 1 to pCountHOEVEEL
      pMember.deleteModelResource(pDuplicateModelResourceList[plop])
    end repeat
    pDuplicateShaderList = []
    pDuplicateShaderListCount = pMember.shader.count
    repeat with j = 1 to pDuplicateShaderListCount
      pShaderName = pMember.shader[j].name
      if pShaderName contains "-clone" then
        pDuplicateShaderList.add(pShaderName)
      end if
    end repeat
    pDuplicateShaderListCount = pDuplicateShaderList.count
    if pDuplicateShaderListCount <> 0 then
      repeat with k = 1 to pDuplicateShaderListCount
        pMember.deleteShader(pDuplicateShaderList[k])
      end repeat
    end if
    pDuplicateTexturesList = []
    pTextureCount = pMember.texture.count
    repeat with r = 1 to pTextureCount
      pTextureName = pMember.texture[r].name
      if pTextureName contains "-clone" then
        pDuplicateTexturesList.add(pTextureName)
      end if
    end repeat
    pDuplicateTextureListCount = pDuplicateTexturesList.count
    if pDuplicateTextureListCount <> 0 then
      repeat with w = 1 to pDuplicateTextureListCount
        pMember.deleteTexture(pDuplicateTexturesList[w])
      end repeat
    end if
    pTextureInfoList = []
    pTextureList = []
    pTextureDataList = []
    pOrigTextureCount = pCloneMember.texture.count
    repeat with e = 1 to pOrigTextureCount
      pEntry = pCloneMember.texture[e].name
      if pEntry = "DefaultTexture" then
        next repeat
      end if
      pTextureList.add(pEntry)
      pwidth = pCloneMember.texture(pEntry).width
      pheight = pCloneMember.texture(pEntry).height
      pFiltering = pCloneMember.texture(pEntry).quality
      pNearFiltering = pCloneMember.texture(pEntry).nearFiltering
      pCompressed = pCloneMember.texture(pEntry).compressed
      pRenderFormat = pCloneMember.texture(pEntry).renderFormat
      pTextureMember = pCloneMember.texture(pEntry).member
      pDataEntry = [#width: pwidth, #height: pheight, #quality: pFiltering, #nearFiltering: pNearFiltering, #compressed: pCompressed, #renderFormat: pRenderFormat, #member: pTextureMember]
      pTextureDataList.add(pDataEntry)
    end repeat
    pTextureInfoList = [pTextureList, pTextureDataList]
    pTextureListCount = pTextureList.count
    repeat with h = 1 to pTextureListCount
      pTexture = pMember.texture(pTextureInfoList[1][h])
      if pTexture = VOID then
        next repeat
        next repeat
      end if
      pTexture.quality = pTextureInfoList[2][h][#quality]
      pTexture.nearFiltering = pTextureInfoList[2][h][#nearFiltering]
      pTexture.compressed = pTextureInfoList[2][h][#compressed]
      pTexture.renderFormat = pTextureInfoList[2][h][#renderFormat]
      pTexture.member = pTextureInfoList[2][h][#member]
      if pTexture.width <> pTextureInfoList[2][h][#width] then
        pOrigWidth = pTextureInfoList[2][h][#width]
        pCurrentWidth = pTexture.width
        pNewWidth = pCurrentWidth
        pAmount = 0
        repeat with c = 1 to 100
          pNewWidth = pNewWidth / 2
          pAmount = pAmount + 1
          if pNewWidth = pOrigWidth then
            exit repeat
          end if
        end repeat
        repeat with g = 1 to pAmount
          pTexture.scaleDown()
        end repeat
      end if
    end repeat
    if pShaderTag <> VOID then
      pNewShaderList = pMember.model(pNewName).shaderList
      pNewShaderListCount = pNewShaderList.count
      repeat with t = 1 to pNewShaderListCount
        pOldShader = pNewShaderList[t]
        pNewShader = pShaderTag & pNewShaderList[t].name
        if pMember.shader(pNewShader) = VOID then
          pReturnedShader = DuplicateShader3(pMember, pOldShader, pNewShader)
          pNewShaderList[t] = pReturnedShader
        else
          pNewShaderList[t] = pMember.shader(pNewShader)
        end if
        pMember.model(pNewName).shaderList[t] = pNewShaderList[t]
      end repeat
    end if
  end repeat
  return pModelList
end

on DuplicateShader3 tmember, tOriginal, tNewName
  pOldShader = tOriginal
  pNewShader = tmember.newShader(tNewName, #standard)
  pNewShader.ambient = pOldShader.ambient
  pNewShader.diffuse = pOldShader.diffuse
  pNewShader.specular = pOldShader.specular
  pNewShader.emissive = pOldShader.emissive
  pNewShader.useDiffuseWithTexture = pOldShader.useDiffuseWithTexture
  pNewShader.shininess = pOldShader.shininess
  pNewShader.blend = pOldShader.blend
  pNewShader.transparent = pOldShader.transparent
  pNewShader.renderStyle = pOldShader.renderStyle
  pNewShader.flat = pOldShader.flat
  repeat with i = 1 to 8
    pNewShader.textureList[i] = pOldShader.textureList[i]
    pNewShader.textureModeList[i] = pOldShader.textureModeList[i]
    pNewShader.wrapTransformList[i] = pOldShader.wrapTransformList[i]
    pNewShader.textureTransformList[i] = pOldShader.textureTransformList[i]
    pNewShader.blendFunctionList[i] = pOldShader.blendFunctionList[i]
    pNewShader.blendSourceList[i] = pOldShader.blendSourceList[i]
    pNewShader.blendConstantList[i] = pOldShader.blendConstantList[i]
    pNewShader.textureRepeatList[i] = pOldShader.textureRepeatList[i]
  end repeat
  return pNewShader
end

on DuplicateShader2 tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: DuplicateShader2. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: DuplicateShader2. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pShaderName = VOID
  if pDataList[#shaderName].ilk = #string then
    pShaderName = pDataList[#shaderName]
  end if
  pShader = pMember.shader(pShaderName)
  if pShader = VOID then
    ShowError("Function: DuplicateShader2. Target: " & tTarget & " Parameters: " & tDataList & " Shader was VOID.")
    exit
  end if
  pCloneName = VOID
  if pDataList[#cloneName].ilk = #string then
    pCloneName = pDataList[#cloneName]
  end if
  if pMember.shader(pCloneName) <> VOID then
    return pMember.shader(pCloneName)
    exit
  end if
  if pCloneName = VOID then
    pCount = pMember.shader.count
    pAmount = 1
    repeat with i = 1 to pCount
      pName = pMember.shader[i].name
      if pName contains pShaderName then
        pAmount = pAmount + 1
      end if
    end repeat
    if pAmount < 10 then
      pTag = "0" & string(pAmount)
    end if
    if pAmount >= 10 then
      pTag = string(pAmount)
    end if
    pCloneName = pShaderName & pTag
  end if
  pNewShader = pMember.newShader(pCloneName, pShader.type)
  pNewShader.texture = pShader.texture
  pNewShader.textureList = pShader.textureList.duplicate()
  pNewShader.textureMode = pShader.textureMode
  pNewShader.textureTransform = pShader.textureTransform
  pNewShader.wrapTransform = pShader.wrapTransform
  pNewShader.textureRepeat = pShader.textureRepeat
  pNewShader.blendFunction = pShader.blendFunction
  pNewShader.blendSource = pShader.blendSource
  pNewShader.blendConstant = pShader.blendConstant
  pNewShader.opacityMap = pShader.opacityMap
  pNewShader.reflectionMap = pShader.reflectionMap
  pNewShader.glossMap = pShader.glossMap
  pNewShader.diffuseLightMap = pShader.diffuseLightMap
  pNewShader.specularLightMap = pShader.specularLightMap
  pNewShader.blend = pShader.blend
  pNewShader.transparent = pShader.transparent
  pNewShader.flat = pShader.flat
  pNewShader.renderStyle = pShader.renderStyle
  pNewShader.shininess = pShader.shininess
  pNewShader.emissive = pShader.emissive
  pNewShader.ambient = pShader.ambient
  pNewShader.diffuse = pShader.diffuse
  pNewShader.specular = pShader.specular
  pNewShader.useDiffuseWithTexture = pShader.useDiffuseWithTexture
  repeat with i = 1 to 8
    pNewShader.textureList[i] = pShader.textureList[i]
    pNewShader.textureModeList[i] = pShader.textureModeList[i]
    pNewShader.wrapTransformList[i] = pShader.wrapTransformList[i]
    pNewShader.textureTransformList[i] = pShader.textureTransformList[i]
    pNewShader.blendFunctionList[i] = pShader.blendFunctionList[i]
    pNewShader.blendSourceList[i] = pShader.blendSourceList[i]
    pNewShader.blendConstantList[i] = pShader.blendConstantList[i]
    pNewShader.textureRepeatList[i] = pShader.textureRepeatList[i]
  end repeat
  return pNewShader
end

on CreateGroup tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: CreateGroup. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: CreateGroup. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pGroup = pMember.group(tDataList[#groupName])
  if pGroup = VOID then
    pMember.newGroup(tDataList[#groupName])
  else
    ShowError("Function: CreateGroup. Target: " & tTarget & " Parameters: " & tDataList & " Group already exists.")
  end if
end

on AddToGroup tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: AddToGroup. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: AddToGroup. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pmodel = pMember.model(pDataList[#ModelName])
  if pmodel = VOID then
    ShowError("Function: AddToGroup. Target: " & tTarget & " Parameters: " & tDataList & " No such model found in member (target).")
    exit
  end if
  pGroup = pMember.group(pDataList[#groupName])
  if pGroup = VOID then
    ShowError("Function: AddToGroup. Target: " & tTarget & " Parameters: " & tDataList & " No such group found in member (target).")
    exit
  end if
  pmodel.parent = pGroup
end

on Defog tTarget
  pSpriteNr = value(tTarget)
  if (pSpriteNr = VOID) or (pSpriteNr.ilk <> #integer) then
    ShowError("Function: Defog. Target: " & tTarget & " Value target VOID or not an integer")
    exit
  end if
  pSprite = sprite(pSpriteNr)
  pMember = pSprite.member
  if (pSprite = VOID) or (pMember = VOID) then
    ShowError("Function: Defog. Target: " & tTarget & " Sprite or member VOID. Membername was: " & pMember.name)
    exit
  end if
  pcamera = pMember.newCamera("SkyBox_Camera")
  pSprite.addCamera(pcamera, 1)
  pStageSize = GetStageSize()
  pcamera.rect = rect(0, 0, pStageSize[1], pStageSize[2])
  pGroupName = "SkyBox_Group"
  if pMember.group(pGroupName) = VOID then
    pMember.newGroup("SkyBox_Group")
  end if
  pcamera.rootNode = pMember.group(pGroupName)
  pMember.group(pGroupName).removeFromWorld()
end

on CopyTextureCoordinates tTarget, tDataList
  ShowError(string("CopyTextureCoordinates" && "Target" && tTarget && "DataList" && tDataList))
  pMember = member(tTarget)
  pDataList = value(tDataList)
  pSrcMember = member(pDataList[#srcmember])
  pChannels = pDataList[#channels]
  if pMember = VOID then
    ShowError("No such member. Target was: " & tTarget)
    exit
  end if
  if pMember.type <> #shockwave3d then
    ShowError("No 3d member. Target was: " & tTarget)
    exit
  end if
  if pSrcMember = VOID then
    ShowError("No such SRCMember. Target was: " & pDataList)
    exit
  end if
  if pChannels = VOID then
    pChannels = 2
  end if
  if pChannels.ilk <> #integer then
    pChannels = 2
  end if
  if pSrcMember.type = #shockwave3d then
    pCount = pMember.model.count
    repeat with j = 1 to pCount
      pModelName = pMember.model[j].name
      pmodel = pMember.model(pModelName)
      if pmodel = VOID then
        next repeat
      end if
      pMeshCount = pmodel.meshDeform.mesh.count
      repeat with k = 1 to pMeshCount
        if pSrcMember.model(pModelName) = VOID then
          next repeat
        end if
        PList = []
        PList = pSrcMember.model(pModelName).meshDeform.mesh[k].textureCoordinateList
        pChannelCount = pChannels - 1
        repeat with m = 1 to pChannelCount
          pmodel.meshDeform.mesh[k].textureLayer.add()
          pmodel.meshDeform.mesh[k].textureLayer[m + 1].textureCoordinateList = PList
        end repeat
      end repeat
    end repeat
  else
    pModelList = value(pSrcMember.text)[1]
    pDataList = value(pSrcMember.text)[2]
    pCount = pModelList.count
    repeat with j = 1 to pCount
      pmodel = pMember.model(pModelList[j])
      if pmodel = VOID then
        next repeat
      end if
      pMeshCount = pmodel.meshDeform.mesh.count
      repeat with k = 1 to pMeshCount
        PList = pDataList[j][k]
        pChannelCount = pChannels - 1
        repeat with m = 1 to pChannelCount
          pmodel.meshDeform.mesh[k].textureLayer.add()
          pmodel.meshDeform.mesh[k].textureLayer[m + 1].textureCoordinateList = PList
        end repeat
      end repeat
    end repeat
  end if
end

on SetAnimationOLD tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pModelName = pDataList[#ModelName]
  if pModelName = VOID then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " Modelname needed")
    exit
  end if
  pmodel = pMember.model(pModelName)
  if pmodel = VOID then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " Model (modelname) not found in member.")
    exit
  end if
  pModifierList = pmodel.modifier
  if pModifierList.getPos(#keyframePlayer) = 0 then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " Model doesnt have modifier and thus no animation either.")
    exit
  end if
  ploop = 0
  if getaProp(pDataList, #loop).ilk = #integer then
    ploop = pDataList[#loop]
  end if
  pCurrenttime = 0
  if getaProp(pDataList, #currentTime).ilk = #integer then
    pCurrenttime = pDataList[#currentTime]
  end if
  pPlayRate = 1.0
  if getaProp(pDataList, #playRate).ilk = #float then
    pPlayRate = pDataList[#playRate]
  end if
  pmodel.keyframePlayer.loop = ploop
  pmodel.keyframePlayer.currentTime = pCurrenttime
  pmodel.keyframePlayer.playRate = pPlayRate
  pCount = pmodel.keyframePlayer.playList.count
  repeat with i = 1 to pCount
    pmodel.keyframePlayer.removeLast()
  end repeat
  pAnimation = pmodel.name & "-key"
  pmodel.keyframePlayer.queue(pAnimation, ploop)
end

on BlackOut tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: BlackOut. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: BlackOut. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pState = 1
  if getaProp(pDataList, #state).ilk = #integer then
    pState = pDataList[#state]
  end if
  pSprite = sprite(1)
  if getaProp(pDataList, #state).ilk = #integer then
    pSprite = sprite(pDataList[#sprite])
  end if
  pCameraName = pDataList[#cameraName]
  if pCameraName = VOID then
    ShowError("Function: BlackOut. Target: " & tTarget & " Parameters: " & tDataList & " No camera name...")
    exit
  end if
  pcamera = pMember.camera(pCameraName)
  if pcamera = VOID then
    if pState = 1 then
      pcamera = pMember.newCamera(pCameraName)
      pDefaultCam = pMember.camera("DefaultView")
      pcamera.transform = pDefaultCam.transform
      pcamera.fieldOfView = pDefaultCam.fieldOfView
      if pSprite.member <> member(0, 0) then
        pSprite.camera = pcamera
      end if
      ShowError("Function: BlackOut. Target: " & tTarget & " Parameters: " & tDataList & " No such camera,.. camera was created.")
    else
      ShowError("Function: BlackOut. Target: " & tTarget & " Parameters: " & tDataList & " No such camera this member. Exited.")
      exit
    end if
  end if
  pTextureName = "BlackOut_Texture"
  if getaProp(pDataList, #TextureName).ilk = #string then
    pTextureName = pDataList[#TextureName]
  end if
  pLoc = point(0, 0)
  if getaProp(pDataList, #loc).ilk = #point then
    pLoc = pDataList[#loc]
  end if
  pScale = 1
  if getaProp(pDataList, #scale).ilk = #float then
    pScale = pDataList[#scale]
  end if
  tMultiSize = 1.0
  if getaProp(pDataList, #multiSize).ilk = #float then
    tMultiSize = pDataList[#multiSize]
  end if
  if getaProp(pDataList, #multiSize).ilk = #symbol then
    tMultiSize = pDataList[#multiSize]
  end if
  if tMultiSize = #fullscreen640 then
    pScale = 0.5
    tMultiSize = float(gGame.resolution[1] / 640.0)
  end if
  tNearFiltering = 0
  if gGame.SourceRatio > 1 then
    tNearFiltering = 1
  end if
  if pState = 1 then
    if pMember.texture(pTextureName) = VOID then
      createTexture(pMember.name, [#fileName: pTextureName, #filtering: #lowFiltered, #renderFormat: #rgba8888, #Override: 1, #nearFiltering: tNearFiltering])
    end if
    pTexture = pMember.texture(pTextureName)
    if pTexture <> VOID then
      pcamera.addOverlay(pTexture, pLoc, 0)
      pcamera.overlay[1].scale = pScale * tMultiSize
    end if
  else
    pDeleteList = []
    pCount = pcamera.overlay.count
    repeat with i = 1 to pCount
      pSource = pcamera.overlay[i].source
      if pSource.name contains pTextureName then
        pDeleteList.add(pSource)
      end if
    end repeat
    pCount = pDeleteList.count
    repeat with i = 1 to pCount
      pSource = pDeleteList[i]
      pCount2 = pcamera.overlay.count
      repeat with j = 1 to pCount2
        pSourceToCheck = pcamera.overlay[j].source
        if pSourceToCheck = pSource then
          pcamera.removeOverlay(j)
          exit repeat
        end if
      end repeat
    end repeat
    if pcamera.name <> "DefaultView" then
      pMember.deleteCamera(pcamera.name)
    end if
  end if
end

on Fade tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pcamera = pMember.camera("DefaultView")
  if getaProp(pDataList, #cameraName).ilk = #string then
    pcamera = pMember.camera(pDataList[#cameraName])
  end if
  if pcamera = VOID then
    pcamera = pMember.camera("DefaultView")
  end if
  pmode = "FadeIn"
  if getaProp(pDataList, #mode).ilk = #string then
    pmode = pDataList[#mode]
  end if
  pTextureName = "BlackFade_Texture"
  if getaProp(pDataList, #TextureName).ilk = #string then
    pTextureName = pDataList[#TextureName]
  end if
  pSize = 80.0
  if getaProp(pDataList, #size).ilk = #float then
    pSize = pDataList[#size]
  end if
  pTime = 1000
  if getaProp(pDataList, #time).ilk = #integer then
    pTime = pDataList[#time]
  end if
  pHold = 0
  if getaProp(pDataList, #hold).ilk = #integer then
    pHold = pDataList[#hold]
  end if
  pToDo = EMPTY
  if getaProp(pDataList, #ToDo).ilk = #string then
    pToDo = pDataList[#ToDo]
  end if
  pGoTo = EMPTY
  if getaProp(pDataList, #goto).ilk = #string then
    pGoTo = pDataList[#goto]
  end if
  if pMember.texture(pTextureName) = VOID then
    createTexture(pMember.name, [#fileName: pTextureName, #filtering: #lowFiltered, #renderFormat: #rgba4444, #Override: 1])
  end if
  pTexture = pMember.texture(pTextureName)
  pOverlayCount = pcamera.overlay.count
  pOverlayCount = pOverlayCount + 1
  pcamera.addOverlay(pTexture, point(0, 0), 0)
  pcamera.overlay[pOverlayCount].scale = pSize
  if pmode = "FadeIn" then
    pcamera.overlay[pOverlayCount].blend = 0
  end if
  if pmode = "FadeOut" then
    pcamera.overlay[pOverlayCount].blend = 100
  end if
  pCount = _movie.timeoutList.count
  pNR = 1
  repeat with i = 1 to pCount
    pName = _movie.timeoutList[i].name
    if pName contains "fade" then
      pNR = pNR + 1
    end if
  end repeat
  pStep = 100.0 / (pTime / 25)
  PList = [#member: pMember, #camera: pcamera.name, #overlay: pOverlayCount, #mode: pmode, #step: pStep, #ToDo: pToDo, #goto: pGoTo, #hold: pHold]
  pTimeOUtName = "FaderTimeOut" & string(pNR)
  timeout().new(pTimeOUtName, 25, #FaderTimeOut, PList)
end

on FaderTimeOut tParams, tTimeOut
  pMember = tParams[#member]
  pcamera = tParams[#camera]
  pOverlay = tParams[#overlay]
  pmode = tParams[#mode]
  pStep = tParams[#step]
  pHold = tParams[#hold]
  pmarker = tParams[#goto]
  if pMember.camera(pcamera).overlay.count < pOverlay then
    pOverlay = pOverlay - 1
  end if
  pBlend = float(pMember.camera(pcamera).overlay[pOverlay].blend)
  if pmode = "FadeOut" then
    pNewBlend = pBlend - pStep
  end if
  if pmode = "FadeIn" then
    pNewBlend = pBlend + pStep
  end if
  if pNewBlend < 0 then
    pNewBlend = 0
  end if
  if pNewBlend > 100 then
    pNewBlend = 100
  end if
  pMember.camera(pcamera).overlay[pOverlay].blend = pNewBlend
  if (pNewBlend = 0) or (pNewBlend = 100) then
    if pHold = 0 then
      pMember.camera(pcamera).removeOverlay(pOverlay)
    end if
    tTimeOut.forget()
    do(tParams[#ToDo])
    if pmarker <> EMPTY then
      go(pmarker)
    end if
  end if
end

on ClearFades tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetAnimation. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pcamera = pMember.camera("DefaultView")
  if getaProp(pDataList, #cameraName).ilk = #string then
    pcamera = pMember.camera(pDataList[#cameraName])
  end if
  if pcamera = VOID then
    pcamera = pMember.camera("DefaultView")
  end if
  pCount = _movie.timeoutList.count
  repeat with i = 1 to pCount
    pTimeout = _movie.timeoutList[i]
    if pTimeout.name contains "FaderTimeOut" then
      pTimeout.forget()
    end if
  end repeat
  pCount = pcamera.overlay.count
  repeat with i = 1 to pCount
    pSource = pcamera.overlay[i].source
    if pSource.name contains "Fade" then
      pcamera.removeOverlay(i)
    end if
  end repeat
end

on AllShadersFullEmissive tTarget, tDataList
  pCount = member(tTarget).shader.count
  repeat with i = 1 to pCount
    pShader = member(tTarget).shader[i]
    if pShader.texture = VOID then
      next repeat
    end if
    pShader.emissive = rgb(255, 255, 255)
  end repeat
end

on unregisterAllEvents tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: UnregisterAllEvents. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pMember.unregisterAllEvents()
end

on registerForEvent tTarget, tDataList
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: RegisterForEvent. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: RegisterForEvent. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pMessage = pDataList[#message]
  pevent = pDataList[#event]
  pHandler = pDataList[#handler]
  if pevent <> VOID then
    g.QueuedEvent = pevent
    case pMessage of
      #animationStarted:
        pMember.registerForEvent(#animationStarted, #event, 0)
      #animationEnded:
        pMember.registerForEvent(#animationEnded, #event, 0)
    end case
  end if
  if pHandler <> VOID then
    case pMessage of
      #animationStarted:
        pMember.registerForEvent(#animationStarted, symbol(pHandler), 0)
      #animationEnded:
        pMember.registerForEvent(#animationEnded, symbol(pHandler), 0)
    end case
  end if
end

on CreateItem3D tTarget, tDataList
  ShowError("Function: CreateItem" && "Target" && tTarget && "DataList" && tDataList)
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pItems = member("Items")
  if pItems = VOID then
    ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " No items member! 3d member with CORRECT model (names) needed!")
    exit
  end if
  pModelName = VOID
  if getaProp(pDataList, #ModelName).ilk = #string then
    pModelName = pDataList[#ModelName]
  end if
  if pModelName = VOID then
    ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " No modelName.")
    exit
  end if
  pmodel = pItems.model(pModelName)
  if pmodel = VOID then
    ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " There is no model in the 'Items' member with the modelname.")
    exit
  end if
  pDistance = 3.0
  if getaProp(pDataList, #distance).ilk = #float then
    pDistance = pDataList[#distance]
  end if
  pevent = VOID
  if getaProp(pDataList, #event).ilk = #string then
    pevent = pDataList[#event]
  end if
  pRotation = vector(0.0, 0.0, 0.0)
  if getaProp(pDataList, #rotation).ilk = #vector then
    pRotation = pDataList[#rotation]
  end if
  pPositionList = VOID
  if getaProp(pDataList, #PositionList).ilk = #list then
    pPositionList = pDataList[#PositionList]
  end if
  if pPositionList = VOID then
    ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " No positionList.")
    exit
  end if
  if pMember.modelResource(pModelName) = VOID then
    CLONEMODELS(pMember, [#cloneMember: pItems.name, #modelList: [pModelName]])
    pMember.model(pModelName).removeFromWorld()
  end if
  pCount = pPositionList.count
  repeat with i = 1 to pCount
    pNewModel = pMember.newModel(pModelName & i, pMember.model(pModelName).resource)
    pNewModel.transform.position = pPositionList[i] + vector(0.0, 0.0, 1.0)
    pNewModel.shaderList = pMember.model(pModelName).shaderList
    pNewModel.pointAtOrientation = [vector(0.0, -1.0, 0.0), vector(0.0, 0.0, 1.0)]
    pNewModel.removeFromWorld()
  end repeat
  if getaProp(g, #Items3D) = VOID then
    pItemScript = new(script("[PS] 3D Item Manager"), [#member: pMember])
    _movie.actorList.add(pItemScript)
    if pItemScript = VOID then
      ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " Tried to create Item Manager script, but failed...")
      exit
    end if
  end if
  pSymbol = symbol(pModelName)
  if getaProp(g.Items3D, pSymbol) <> VOID then
    pCount = pPositionList.count
    PList = g.Items3D[pSymbol][#PositionList]
    repeat with i = 1 to pCount
      pVector = pPositionList[i]
      if PList.getPos(pVector) = 0 then
        PList.add(pVector)
      end if
    end repeat
    ShowError("Function: CreateItem. Target: " & tTarget & " Parameters: " & tDataList & " Only added new positions to an already existing item. Please use the SetITem3D function to adjust item properties. They have been ignored for now.")
  else
    g.Items3D[pSymbol] = [#distance: pDistance, #event: pevent, #rotation: pRotation, #PositionList: pPositionList]
  end if
end

on SetItem3D tTarget, tDataList
  ShowError("Function: SetItem3D" && "Target" && tTarget && "DataList" && tDataList)
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: SetItem3D. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetItem3D. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pItemName = VOID
  if getaProp(pDataList, #itemName).ilk = #string then
    pItemName = pDataList[#itemName]
  end if
  if pItemName = VOID then
    ShowError("Function: SetItem3D. Target: " & tTarget & " Parameters: " & tDataList & " Itemname VOID.")
    exit
  end if
  pItem = pMember.model(pItemName)
  if pItem = VOID then
    ShowError("Function: SetItem3D. Target: " & tTarget & " Parameters: " & tDataList & " Item VOID.")
    exit
  end if
  pTargetName = VOID
  if getaProp(pDataList, #targetName).ilk = #string then
    pTargetName = pDataList[#targetName]
  end if
  if pTargetName = VOID then
    ShowError("Function: SetItem3D. Target: " & tTarget & " Parameters: " & tDataList & " TargetName VOID.")
    exit
  end if
  pTarget = pMember.model(pTargetName)
  if pItem = VOID then
    ShowError("Function: SetItem3D. Target: " & tTarget & " Parameters: " & tDataList & " Target VOID.")
    exit
  end if
  pDistance = 3.0
  if getaProp(pDataList, #distance).ilk = #float then
    pDistance = pDataList[#distance]
  end if
  pevent = VOID
  if getaProp(pDataList, #event).ilk = #string then
    pevent = pDataList[#event]
  end if
end

on DeleteItem3D tTarget, tDataList
  ShowError("Function: DeleteItem3D" && "Target" && tTarget && "DataList" && tDataList)
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: DeleteItem3D. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pItemName = VOID
  if getaProp(pDataList, #itemName).ilk = #string then
    pItemName = pDataList[#itemName]
  end if
  if pItemName = VOID then
    ShowError("Function: DeleteItem3D. Target: " & tTarget & " Parameters: " & tDataList & " Itemname VOID.")
    exit
  end if
  pCount = g.Items3D.count
  repeat with i = 1 to pCount
    pmodel = g.Items3D[i][1]
    if pItemName = pmodel.name then
      g.Items3D.deleteAt(i)
      exit repeat
    end if
  end repeat
end

on AddButton3D tTarget, tDataList
  ShowError("Function: AddButton3D" && "Target" && tTarget && "DataList" && tDataList)
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pModelName = VOID
  if getaProp(pDataList, #ModelName).ilk = #string then
    pModelName = pDataList[#ModelName]
  end if
  if getaProp(pDataList, #ModelName).ilk = #symbol then
    pModelName = pDataList[#ModelName]
  end if
  if pModelName.ilk <> #symbol then
    if pModelName = VOID then
      ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " ModelName VOID.")
      exit
    end if
    pmodel = pMember.model(pModelName)
    if pmodel = VOID then
      ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " Item VOID.")
      exit
    end if
  end if
  pevent = VOID
  if getaProp(pDataList, #event).ilk = #string then
    pevent = pDataList[#event]
  end if
  pHandler = "Nothing"
  if getaProp(pDataList, #handler).ilk = #string then
    pHandler = pDataList[#handler]
  end if
  pAlpha = 1
  if getaProp(pDataList, #alpha).ilk = #integer then
    pAlpha = pDataList[#alpha]
  end if
  pRollOverSoundName = VOID
  if getaProp(pDataList, #rollOverSoundName).ilk = #string then
    pRollOverSoundName = pDataList[#rollOverSoundName]
  end if
  pPressedSoundName = VOID
  if getaProp(pDataList, #pressedSoundName).ilk = #string then
    pPressedSoundName = pDataList[#pressedSoundName]
  end if
  tParent = pmodel.parent
  pmodel.userData.addProp(#parent, tParent)
  tHack = 0
  if getaProp(pDataList, #hack).ilk = #integer then
    tHack = pDataList[#hack]
  end if
  if voidp(g[#Button3DList]) = 1 then
    if g[#InterfaceName] = VOID then
      pInterfaceName = "Interface"
    else
      pInterfaceName = g.InterfaceName
    end if
    pButtonScript = new(script("[PS] 3D Button Script"), [#memberName: pInterfaceName])
    if pButtonScript = VOID then
      ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " Tried to create Button Script script, but failed...")
      exit
    end if
    _movie.actorList.add(pButtonScript)
  end if
  if pModelName.ilk <> #symbol then
    pEntry = [#model: pmodel, #event: pevent, #handler: pHandler, #alpha: pAlpha, #rollOverSoundName: pRollOverSoundName, #pressedSoundName: pPressedSoundName, #hack: tHack]
    g.Button3DList.add(pEntry)
  else
    pEntry = [#model: pModelName, #event: pevent, #handler: pHandler, #alpha: pAlpha, #rollOverSoundName: pRollOverSoundName, #pressedSoundName: pPressedSoundName, #hack: tHack]
    g.Button3DList.add(pEntry)
  end if
  if pDataList[#hide] <> VOID then
    if pDataList.hide = 1 then
      pmodel.removeFromWorld()
    end if
  end if
end

on RemoveButton3D tTarget, tDataList
  ShowError("Function: AddButton3D" && "Target" && tTarget && "DataList" && tDataList)
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pModelName = VOID
  if getaProp(pDataList, #ModelName).ilk = #string then
    pModelName = pDataList[#ModelName]
  end if
  if getaProp(pDataList, #ModelName).ilk = #symbol then
    pModelName = pDataList[#ModelName]
  end if
  if pModelName.ilk <> #symbol then
    if pModelName = VOID then
      ShowError("Function: AddButton3D. Target: " & tTarget & " Parameters: " & tDataList & " ModelName VOID.")
      exit
    end if
    pCount = g.Button3DList.count
    repeat with i = 1 to pCount
      pmodel = g.Button3DList[i][1]
      if pModelName = pmodel.name then
        g.Button3DList.deleteAt(i)
        exit repeat
      end if
    end repeat
  else
    pCount = g.Button3DList.count
    repeat with i = 1 to pCount
      pmodel = g.Button3DList[i][1]
      if pModelName = pmodel then
        g.Button3DList.deleteAt(i)
        exit repeat
      end if
    end repeat
  end if
end

on BuildTileItems tmember, tGroupRoot, tType, tItemList, tItem
  pMember = tmember
  if getaProp(g, #Items3D) = VOID then
    pItemScript = new(script("[PS] 3D Item Manager"), [#member: pMember])
    _movie.actorList.add(pItemScript)
    if pItemScript = VOID then
      put "Function: BuildTileItems. Tried to create Item Manager script, but failed..."
      exit
    end if
  end if
  pRootSymbol = symbol(tGroupRoot.name)
  g.Items3D[pRootSymbol] = [:]
  g.Items3D[pRootSymbol][#hidden] = 0
  if tItem = VOID then
    exit
  end if
  tPosList = []
  repeat with i in tItemList
    tPosList.add(i.position + tGroupRoot.worldPosition)
  end repeat
  pTileItemList = [:]
  pTileItemList[tItem] = [#distance: 3.0, #event: "UpdateChallengeInterface", #PositionList: tPosList.duplicate(), #modelNames: []]
  g.Items3D[pRootSymbol] = pTileItemList.duplicate()
  g.Items3D[pRootSymbol][#hidden] = 0
  pItems = member("Items")
  if pItems = VOID then
    ShowError("Function: BuildTileItems.No items member! 3d member with CORRECT model (names) needed! Data is available but no models!")
    exit
  end if
  if tmember.model(string(tItem)) = VOID then
    event("SetupItems")
    tModelList = CLONEMODELS(tmember, [#cloneMember: "Items"])
    repeat with i in tModelList
      tmember.model(i).removeFromWorld()
    end repeat
  end if
  pTileItemList = g.Items3D[pRootSymbol].duplicate()
  pItemCount = pTileItemList.count
  if pItemCount > 0 then
    repeat with i = 1 to pItemCount
      theLastProp = pTileItemList.getPropAt(i)
      if theLastProp = #hidden then
        next repeat
      end if
      pModelName = string(tItem)
      pmodel = pMember.model(pModelName)
      pOldDelimiter = the itemDelimiter
      the itemDelimiter = "_"
      pNewTag = tGroupRoot.name.item[1]
      the itemDelimiter = pOldDelimiter
      pAllItemCount = pTileItemList[i][#PositionList].count
      repeat with j = 1 to pAllItemCount
        pNewModel = pMember.newModel(pNewTag & "_" & pModelName & j, pmodel.resource)
        pNewModel.shaderList = pMember.model(pModelName).shaderList
        pNewModel.transform.position = pTileItemList[i][#PositionList][j]
        pNewModel.pointAtOrientation = [vector(0.0, -1.0, 0.0), vector(0.0, 0.0, 1.0)]
        g.Items3D[pRootSymbol][i][#modelNames].append(pNewModel.name)
        pNewModel.removeFromWorld()
      end repeat
    end repeat
  end if
end

on BuildSkyTubes tmember, tGroupRoot, tType, tTubeList, tAmount
  if tmember.modelResource("SkyTubeBase") = VOID then
    event("SetupSkyTube")
    tModelList = CLONEMODELS(tmember, [#cloneMember: "SkyTube"])
    repeat with i in tModelList
      tmember.model(i).removeFromWorld()
    end repeat
    AddToScroller(tmember.name, [#shaderName: tmember.model("SkyTube").shader.name, #position: vector(0.0, -0.03, 0.0)])
    if g.RootList.count = 1 then
      tCheckerShader = tmember.newShader("SkyTubeChecker_Material", #standard)
      tTexture = createTexture(tmember.name, [#fileName: "OutbackCheckeredFlag_Texture"])
      tCheckerShader.texture = tTexture
      tCheckerShader.emissive = rgb(255, 255, 255)
      AddToScroller(tmember.name, [#shaderName: "SkyTubeChecker_Material", #position: vector(0.0, -0.02, 0.0)])
    end if
    tExtraShader = tmember.newShader("SkyTubePassed_Material", #standard)
    tExtraShader.texture = tmember.texture("SkyTubeRed_Texture")
    tExtraShader.emissive = rgb(100, 100, 100)
    AddToScroller(tmember.name, [#shaderName: "SkyTubePassed_Material", #position: vector(0.0, -0.03, 0.0)])
  end if
  tRootName = tGroupRoot.name
  tOldDelimiter = the itemDelimiter
  the itemDelimiter = "_"
  tRootName = tRootName.item[1]
  the itemDelimiter = tOldDelimiter
  if getaProp(g, #CheckPoints) = VOID then
    g[#CheckPoints] = [:]
  end if
  tList = []
  tCount = tTubeList.count
  repeat with i = 1 to 2
    tPosition = tTubeList[i].position
    tSkyBase = tmember.newModel(tRootName & "_" & tType & "SkyTubeBase" & i, tmember.modelResource("SkyTubeBase"))
    tSkyBase.shader = tmember.model("SkyTubeBase").shader
    tSkyBase.transform.position = tPosition - vector(0, 0, 1.5)
    tSkyBase.parent = tGroupRoot
    tSkyTube = tmember.newModel(tRootName & "_" & tType & "SkyTube" & i, tmember.modelResource("SkyTube"))
    tSkyTube.shader = tmember.model("SkyTube").shader
    if g.RootList.count = 1 then
      tSkyTube.shader = tCheckerShader
    end if
    tSkyTube.transform.position = tPosition - vector(0, 0, 1.5)
    tSkyTube.transform.rotation = vector(0.0, 0.0, -30.0)
    tSkyTube.parent = tGroupRoot
    tList.add(tSkyBase.worldPosition)
  end repeat
  tgroup = tmember.newGroup("CheckpointGroup")
  tgroup.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  tgroup.transform.position = tList[1]
  tgroup.pointAt(tList[2])
  tTransform = tgroup.transform.duplicate()
  g.CheckPoints[symbol(tRootName)] = tTransform
  tmember.deleteGroup(tgroup.name)
  if g[#CPHelpers] <> VOID then
    if g.CPHelpers = 1 then
      tDistance = tList[1].distanceTo(tList[2])
      tResource = tmember.newModelResource("Center" & g.CheckPoints.count, #cylinder)
      tResource.topRadius = 0.40000000000000002
      tResource.bottomRadius = 0.40000000000000002
      tResource.height = tDistance
      tmodel = tmember.newModel("Center" & g.CheckPoints.count, tResource)
      tmodel.transform = tTransform
      tmodel.transform.position = tmodel.transform.position + (tmodel.transform.yAxis * (tDistance / 2.0))
      tmodel.shader = tmember.shader("DefaultShader")
      tmember.shader("DefaultShader").emissive = rgb(255, 255, 255)
    end if
  end if
end

on BuildAIPaths tString
  pTrackName = tString.char[1..tString.length - 7]
  pBuildEvent = pTrackName & "Build"
  pAIPathEvent = tString
  g[#WayPointList] = []
  pTileList = []
  pOldDelimiter = the itemDelimiter
  the itemDelimiter = TAB
  pCount = g.Events[pBuildEvent].count
  repeat with i = 1 to pCount
    pString = g.Events[pBuildEvent][i]
    pMemberName = pString.item[2]
    pItem = pString.item[3]
    PList = value(pItem)
    pTile = PList[#type]
    pDeco = PList[#deco]
    if pDeco <> 1 then
      pTileList.add(pTile)
    end if
  end repeat
  pMember = member(pMemberName)
  if pMember = VOID then
    ShowError("FUnction: BuildAIPaths. Member was VOID. Incoming string was: " & tString)
    exit
  end if
  pDataList = [:]
  pCount = g.Events[pAIPathEvent].count
  repeat with i = 1 to pCount
    pString = g.Events[pAIPathEvent][i]
    pSymbol = symbol(pString.item[1])
    pVectorList = value(pString.item[3])
    pDataList[pSymbol] = pVectorList
  end repeat
  the itemDelimiter = pOldDelimiter
  pCount = pTileList.count
  repeat with i = 1 to pCount
    pSymbol = symbol(pTileList[i])
    if getaProp(pDataList, pSymbol) = VOID then
      alert("The " & g.CurrentTrack & "AIPaths event does not contain information about the following tile: " & pTileList[i] & " The root transform of this tile will be used instead. AI behavior will become unpredictable.")
      pRootTransform = pMember.group("TrackRoot" & i & "_Group").getWorldTransform()
      pWayPointPosition = pRootTransform.position
      pWayPointOrientation = pRootTransform.rotation
      g.WayPointList.append([pWayPointPosition, pWayPointOrientation])
      next repeat
    end if
    pWaypointCount = pDataList[symbol(pTileList[i])].count
    pRootTransform = pMember.group("TrackRoot" & i & "_Group").getWorldTransform()
    repeat with j = 1 to pWaypointCount
      pWayPointPosition = pRootTransform.position + pDataList[symbol(pTileList[i])][j][1]
      pWayPointOrientation = pDataList[symbol(pTileList[i])][j][2]
      g.WayPointList.append([pWayPointPosition, pWayPointOrientation])
    end repeat
  end repeat
end

on SetCheckPoints tTarget, tDataList
  ShowError("Function: SetStartFinish" && "Target" && tTarget && "DataList" && tDataList)
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: SetStartFinish. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: SetStartFinish. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
  end if
  pStartFinishModel = member("StartFinish")
  if pMember = VOID then
    ShowError("Function: SetStartFinish. Target: " & tTarget & " Parameters: " & tDataList & " No StartFinish member.")
    exit
  end if
  pStartFinishModel.resetWorld()
  createTexture("StartFinish", [#fileName: "FinishLine_Texture"])
  CLONEMODELS(pMember.name, [#cloneMember: "StartFinish"])
  pCount = pMember.group.count
  PList = []
  repeat with i = 1 to pCount
    if pMember.group[i].name contains "TrackRoot" then
      PList.add(pMember.group[i].name)
    end if
  end repeat
  if getaProp(g, #CheckPoints) = VOID then
    g[#CheckPoints] = [#start: [#rect: rect(0, 0, 0, 0), #event: VOID], #CheckPoints: [#rects: [], #event: VOID], #finish: [#rect: rect(0, 0, 0, 0), #event: VOID], #AIFinish: [#rect: rect(0, 0, 0, 0), #event: VOID]]
  end if
  pStartModel = pMember.model("StartLine")
  if pStartModel <> VOID then
    pStartModel.transform.position = pMember.group(PList[1]).getWorldTransform().position + vector(0.0, 2.5, 0.0)
    prect = GetCheckPointRect(pMember.name, [#string: "StartLine"])
    g.CheckPoints.start.rect = prect
  end if
  pFinishModel = pMember.model("FinishLine")
  if pFinishModel <> VOID then
    pFinishModel.transform.position = pMember.group(PList[PList.count]).getWorldTransform().position + vector(0.0, 2.5, 0.0)
    prect = GetCheckPointRect(pMember.name, [#string: "FinishLine"])
    g.CheckPoints.finish.rect = prect
    g.CheckPoints.AIFinish.rect = prect
  end if
  pInvWallMember = member("InvisbleWall")
  if pInvWallMember = VOID then
    exit
  end if
  pInvWallMember.resetWorld()
  if getaProp(g, #WayPointList) = VOID then
    exit
  end if
  if g.WayPointList.count = 0 then
    exit
  end if
  pGroupHelper = pMember.newGroup("GroupHelper")
  pGroupHelper.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  createTexture("InvisbleWall", [#fileName: "Crosses_Texture"])
  CLONEMODELS(pMember, [#cloneMember: "InvisbleWall", #modelList: ["InvisibleWall", "Arrows"], #NameList: ["StartInvisibleWall", "StartArrows"]])
  pStartNr = 5
  if g.WayPointList[1].count > pStartNr then
    pMember.model("StartInvisibleWall").addToWorld()
    pMember.model("StartInvisibleWall").transform.position = g.WayPointList[1][pStartNr][1]
    pMember.model("StartArrows").transform.position = g.WayPointList[1][pStartNr][1]
    pGroupHelper.pointAt(g.WayPointList[1][pStartNr + 1][1], vector(0, 0, 1))
    pMember.model("StartInvisibleWall").transform.axisAngle = pGroupHelper.transform.axisAngle
    pMember.model("StartArrows").transform.axisAngle = pGroupHelper.transform.axisAngle
    AddObstacle(0, pMember.name, [#model: "StartInvisibleWall", #type: #static, #bodyProxy: #concaveShape])
  end if
  CLONEMODELS(pMember, [#cloneMember: "InvisbleWall", #modelList: ["InvisibleWall", "Arrows"], #NameList: ["EndInvisibleWall", "EndArrows"]])
  pTotal = g.WayPointList.count
  pEndNr = g.WayPointList[pTotal].count - 5
  if (g.WayPointList.count > 5) and (pEndNr > 0) then
    pMember.model("EndInvisibleWall").addToWorld()
    pMember.model("EndInvisibleWall").transform.position = g.WayPointList[pTotal][pEndNr][1]
    pMember.model("EndArrows").transform.position = g.WayPointList[pTotal][pEndNr][1]
    pGroupHelper.pointAt(g.WayPointList[pTotal][pEndNr - 1][1], vector(0, 0, 1))
    pMember.model("EndInvisibleWall").transform.axisAngle = pGroupHelper.transform.axisAngle
    pMember.model("EndArrows").transform.axisAngle = pGroupHelper.transform.axisAngle
    AddObstacle(0, pMember.name, [#model: "EndInvisibleWall", #type: #static, #bodyProxy: #concaveShape])
  end if
  pMember.deleteGroup("GroupHelper")
end

on GetCheckPointRect tTarget, tDataList
  ShowError("Function: GetCheckPointRect" && "Target" && tTarget && "DataList" && tDataList)
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: GetCheckPointRect. Target: " & tTarget & " Parameters: " & tDataList & " No such member.")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: GetCheckPointRect. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pString = VOID
  if getaProp(pDataList, #string).ilk = #string then
    pString = pDataList[#string]
  end if
  if pString = VOID then
    ShowError("Function: GetCheckPointRect. Target: " & tTarget & " Parameters: " & tDataList & " No string.")
    exit
  end if
  pCheckPointLeftTop = GetReferenceType(pMember, pString & "Dummy_LeftTop")
  pCheckPointRightBottom = GetReferenceType(pMember, pString & "Dummy_RightBottom")
  if (pCheckPointLeftTop = VOID) or (pCheckPointRightBottom = VOID) then
    ShowError("Function: GetCheckPointRect. Target: " & tTarget & " Parameters: " & tDataList & " One of the dummies was void.")
    exit
  end if
  p1 = pCheckPointLeftTop.worldPosition.x
  p2 = pCheckPointLeftTop.worldPosition.y
  p3 = pCheckPointRightBottom.worldPosition.x
  p4 = pCheckPointRightBottom.worldPosition.y
  prect = rect(0.0, 0.0, 0.0, 0.0)
  if p1 <= p3 then
    prect = rect(p1, 0.0, p3, 0.0)
  else
    prect = rect(p3, 0.0, p1, 0.0)
  end if
  if p2 <= p4 then
    prect = rect(prect.left, p2, prect.right, p4)
  else
    prect = rect(prect.left, p4, prect.right, p2)
  end if
  return prect
end
