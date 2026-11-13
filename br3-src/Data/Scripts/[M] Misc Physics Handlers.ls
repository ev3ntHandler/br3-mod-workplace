global gGame, g

on PhysicsExplodeChildren tmember, tModelName, tMass
  if g.Physics = VOID then
    exit
  end if
  pMember = tmember
  if pMember = VOID then
    exit
  end if
  pModelName = tModelName
  if pModelName = VOID then
    exit
  end if
  pMass = tMass
  if pMass = VOID then
    pMass = 60.0
  end if
  pmodel = pMember.model(pModelName)
  if pmodel = VOID then
    exit
  end if
  pCount = pmodel.child.count
  if (pCount = 0) or (pCount = VOID) then
    exit
  end if
  pChildList = []
  repeat with j = 1 to pCount
    pListModel = pmodel.child[j]
    pChildList.add(pListModel)
  end repeat
  repeat with i = 1 to pCount
    pChildModel = pChildList[i]
    pTransform = pChildModel.getWorldTransform()
    pChildModel.parent = pMember.group("World")
    pChildModel.transform = pTransform
    pModifierList = pChildModel.modifier
    if pModifierList.getPos(#meshDeform) = 0 then
      pChildModel.addModifier(#meshDeform)
    end if
    pRB = g.Physics.createRigidBody(pChildModel.name, pChildModel.name, #convexShape, #dynamic)
    pRB.restitution = 0.20000000000000001
    pRB.friction = 0.5
    pRB.mass = 60.0
  end repeat
end

on areaDamage me, tPosition, tData, tSender, tParent
  tList = []
  if tParent = VOID then
    tList = gGame.DynamicRBList.duplicate()
  else
    tUD = tParent.userData
    if voidp(tUD[#Obstacles]) = 0 then
      tList = tUD.Obstacles.duplicate()
    else
      tList = gGame.DynamicRBList.duplicate()
    end if
  end if
  repeat with i in gGame.cars
    tList.add(i.car.PhysicsCar)
  end repeat
  tOffset = tPosition - vector(0, 0, 4.5)
  repeat with i = 1 to tList.count
    tRB = tList[i]
    tName = tRB.name
    if tName = tSender then
      next repeat
    end if
    tDistance = tPosition.distanceTo(tRB.position)
    if tDistance <= tData[3] then
      tPerc = 1.0 - (tDistance / tData[3])
      tDamage = tData[1] + ((tData[2] - tData[1]) * tPerc)
      if tName contains "Proxy" then
        gGame.cars[symbol(tName.char[1..tName.length - 5])].car.impacts.add([tDamage, #areaDamage, tSender])
      else
        if voidp(gGame.member.model(tName).userData.Health) = 0 then
          gGame.AreaDamageList.add([tRB, tDamage, tSender])
        end if
      end if
      tVector = tRB.position - tOffset
      tVector.normalize()
      if tName contains "Proxy" then
        tMass = tRB.mass
      else
        tMass = tRB.mass * 3
      end if
      tLinVector = tVector * (tMass * tPerc)
      tLinVector.z = tLinVector.z * 2
      tRB.applyLinearImpulse(tLinVector)
      tTest = vector(tVector.x * 10000, tVector.y * 10000, 0)
      tRB.applyAngularImpulse(tTest)
    end if
  end repeat
end
