function pointshoot:SetDrawTime(self)
    self.drawtime = RealTime()
    self.drawdt = self.drawtime - (self.drawtimelast or self.drawtime)
    self.drawtimelast = self.drawtime
end



