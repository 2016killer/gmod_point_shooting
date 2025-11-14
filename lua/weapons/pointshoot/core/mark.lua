SWEP:RegisterClientToServer('CTSAddMarks')
SWEP:RegisterClientToServer('CTSExecuteRequest')

SWEP.MarksBatchSize = 5

function SWEP:CTSAddMarks(...)
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    self.Marks = self.Marks or {}
    table.Add(self.Marks, {...})
end

function SWEP:CTSExecuteRequest(...)
    if SERVER then 
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return end
        self.Marks = self.Marks or {}
        table.Add(self.Marks, {...})

        pointshoot.Marks[owner:EntIndex()] = self.Marks

        pointshoot:Execute(owner)
    elseif CLIENT then
        pointshoot.Marks = self.Marks
    end
end

if CLIENT then  
    function SWEP:AddMarkFromTrace(tr)
        local base = self:GetTable()
        table.insert(self.Marks, pointshoot:PackMark(tr))
        
        local len = #self.Marks
        local batch = base.MarksBatchSize
        local left = len % batch
        if left == 0 then
            self:CallDoubleEnd(
                'CTSAddMarks',
                unpack(
                    self.Marks, 
                    len - batch + 1, 
                    len
                )
            )
        end
    end

    function SWEP:GetLeftMasks()
        local base = self:GetTable()

        local len = #self.Marks
        local batch = base.MarksBatchSize
        local left = len % batch
        return unpack(self.Marks, len - left + 1, len)
    end
end

