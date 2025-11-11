function SWEP:CalcView(ply, pos, ang, fov)
    // if not ang then return end
    // if ply ~= GetViewEntity() then return end


    // local ftv = FrameTime()
    // local viewbobintensity = viewbob_intensity_cvar:GetFloat()
    // local holprog = TFA.Enum.HolsterStatus[self2.GetStatus(self)] and 1 or 0
    // self2.ViewHolProg = math.Approach(self2.ViewHolProg, holprog, ftv / 5)

    // oldangtmp = ang * 1

    // local stat = self:GetStatus()

    // local ibash = stat == TFA.Enum.STATUS_BASHING or stat == TFA.Enum.STATUS_BASHING_WAIT and self2.GetStatL(self, "ViewBob_Bash")
    // local idraw = stat == TFA.Enum.STATUS_DRAW and self2.GetStatL(self, "ViewBob_Draw")
    // local ihols = TFA.Enum.HolsterStatus[stat] and self2.GetStatL(self, "ViewBob_Holster")
    // local ifidget = stat == TFA.Enum.STATUS_FIDGET and self2.GetStatL(self, "ViewBob_Inspect")
    // local ipump = stat == TFA.Enum.STATUS_PUMP and self2.GetStatL(self, "ViewBob_Pump")
    // local ireload = TFA.Enum.ReloadStatus[stat] and self2.GetStatL(self, "ViewBob_Reload")
    // local ishoot = stat == TFA.Enum.STATUS_SHOOTING and self2.GetStatL(self, "ViewBob_Shoot") and not self:CanInterruptShooting()

    // targbool = idraw or ireload or ibash or ishoot or ipump or ifidget or (ihols and not self2.GetStatL(self, "ProceduralHolsterEnabled"))
    // targint = targbool and 1 or 0

    // if not self2.ViewBob_DontFadeOutStatus[stat] and not self2.ViewBob_DontFadeOutShootStatus[self:GetShootStatus()] then
    //     targint = math.min(targint, 1 - math.pow(math.max(vm:GetCycle() - 0.5, 0) * 2, 2))
    // end

    // progress = l_Lerp(ftv * 20, progress, targint)

    // if self2.CameraAngCache and viewbob_animated_cvar:GetBool() then
    //     self2.CameraAttachmentScale = self2.CameraAttachmentScale or 1
    //     ang:RotateAroundAxis(ang:Right(), Lerp(progress, 0, (self2.CameraAngCache.p + self2.CameraOffset.p) * viewbobintensity * -self2.CameraAttachmentScale) * viewbobintensity)
    //     ang:RotateAroundAxis(ang:Up(), Lerp(progress, 0, (self2.CameraAngCache.y + self2.CameraOffset.y) * viewbobintensity * self2.CameraAttachmentScale) * viewbobintensity)
    //     ang:RotateAroundAxis(ang:Forward(), Lerp(progress, 0, (self2.CameraAngCache.r + self2.CameraOffset.r) * viewbobintensity * self2.CameraAttachmentScale) * viewbobintensity)
    //     -- - self2.MZReferenceAngle--WorldToLocal( angpos.Pos, angpos.Ang, angpos.Pos, oldangtmp + self2.MZReferenceAngle )
    //     --* progress )
    //     --self2.ProceduralViewOffset.p = l_mathApproach(self2.ProceduralViewOffset.p, 0 , l_mathClamp( procedural_pitchrestorefac - math.min( math.abs( self2.ProceduralViewOffset.p ), procedural_pitchrestorefac ) ,1,procedural_pitchrestorefac)*ftv/5 )
    //     --self2.ProceduralViewOffset.y = l_mathApproach(self2.ProceduralViewOffset.y, 0 , l_mathClamp( procedural_pitchrestorefac - math.min( math.abs( self2.ProceduralViewOffset.y ), procedural_pitchrestorefac ) ,1,procedural_pitchrestorefac)*ftv/5 )
    //     --self2.ProceduralViewOffset.r = l_mathApproach(self2.ProceduralViewOffset.r, 0 , l_mathClamp( procedural_pitchrestorefac - math.min( math.abs( self2.ProceduralViewOffset.r ), procedural_pitchrestorefac ) ,1,procedural_pitchrestorefac)*ftv/5 )
    // else
    //     local mul = 1
    //     if ifidget then
    //         mul = -1
    //     end

    //     local att = self2.MuzzleAttachmentRaw or vm:LookupAttachment(self2.MuzzleAttachment)
    //     if not att then
    //         att = 1
    //     end

    //     local angpos = vm:GetAttachment(att)
    //     if angpos and angpos.Ang then
    //         mzang_fixed = vm:WorldToLocalAngles(angpos.Ang)
    //         mzang_fixed:Normalize()
    //     end

    //     self2.ProceduralViewOffset:Normalize()

    //     if mzang_fixed_last then
    //         local delta = mzang_fixed - mzang_fixed_last
    //         delta:Normalize()
    //         mzang_velocity = mzang_velocity + delta * (2 * (1 - self2.ViewHolProg))

    //         mzang_velocity.p = math.Approach(mzang_velocity.p, -self2.ProceduralViewOffset.p * 2, ftv * 20)
    //         mzang_velocity.p = math.Clamp(mzang_velocity.p, -procedural_vellimit, procedural_vellimit)
    //         self2.ProceduralViewOffset.p = self2.ProceduralViewOffset.p + mzang_velocity.p * ftv * mul
    //         self2.ProceduralViewOffset.p = math.Clamp(self2.ProceduralViewOffset.p, -90, 90)

    //         mzang_velocity.y = math.Approach(mzang_velocity.y, -self2.ProceduralViewOffset.y * 2, ftv * 20)
    //         mzang_velocity.y = math.Clamp(mzang_velocity.y, -procedural_vellimit, procedural_vellimit)
    //         self2.ProceduralViewOffset.y = self2.ProceduralViewOffset.y + mzang_velocity.y * ftv * mul
    //         self2.ProceduralViewOffset.y = math.Clamp(self2.ProceduralViewOffset.y, -90, 90)

    //         mzang_velocity.r = math.Approach(mzang_velocity.r, -self2.ProceduralViewOffset.r * 2, ftv * 20)
    //         mzang_velocity.r = math.Clamp(mzang_velocity.r, -procedural_vellimit, procedural_vellimit)
    //         self2.ProceduralViewOffset.r = self2.ProceduralViewOffset.r + mzang_velocity.r * ftv * mul
    //         self2.ProceduralViewOffset.r = math.Clamp(self2.ProceduralViewOffset.r, -90, 90)
    //     end
    //     mzang_fixed_last = mzang_fixed

    //     self2.ProceduralViewOffset.p = math.Approach(self2.ProceduralViewOffset.p, 0, (1 - progress) * ftv * -self2.ProceduralViewOffset.p * 20)
    //     self2.ProceduralViewOffset.y = math.Approach(self2.ProceduralViewOffset.y, 0, (1 - progress) * ftv * -self2.ProceduralViewOffset.y * 20)
    //     self2.ProceduralViewOffset.r = math.Approach(self2.ProceduralViewOffset.r, 0, (1 - progress) * ftv * -self2.ProceduralViewOffset.r * 20)

    //     local ints = viewbobintensity * 1.25
    //     ang:RotateAroundAxis(ang:Right(), Lerp(progress, 0, -self2.ProceduralViewOffset.p) * ints)
    //     ang:RotateAroundAxis(ang:Up(), Lerp(progress, 0, self2.ProceduralViewOffset.y / 2) * ints)
    //     ang:RotateAroundAxis(ang:Forward(), Lerp(progress, 0, self2.ProceduralViewOffset.r / 3) * ints)
    // end

    // return pos, LerpAngle(math.pow(self2.ViewHolProg, 2), ang, oldangtmp), fov
end