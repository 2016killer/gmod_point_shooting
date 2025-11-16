SWEP:RegisterClientToServer('CTSAddMarks')

function SWEP:CTSAddMarks(mark)
    self.Marks = self.Marks or {}
    table.insert(self.Marks, mark)
end