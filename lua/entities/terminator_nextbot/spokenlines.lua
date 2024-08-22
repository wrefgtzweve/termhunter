function ENT:InitializeSpeaking()
    if not self.CanSpeak then return end
    self.NextTermSpeak = 0
    self.StuffToSay = {}

end

function ENT:Term_PlaySentence( sentenceIn, conditionFunc )
    if conditionFunc then
        table.insert( self.StuffToSay, { sent = sentenceIn, conditionFunc = conditionFunc } )

    else
        if #self.StuffToSay >= 4 then return end -- don't add infinite stuff to say.
        if #self.StuffToSay >= 2 and math.random( 0, 100 ) >= 50 then return end
        table.insert( self.StuffToSay, { sent = sentenceIn } )

    end
end

function ENT:Term_SpeakSound( pathIn, conditionFunc )
    if conditionFunc then
        table.insert( self.StuffToSay, { path = pathIn, conditionFunc = conditionFunc } )

    else
        if #self.StuffToSay >= 4 then return end -- don't add infinite stuff to say.
        if #self.StuffToSay >= 2 and math.random( 0, 100 ) >= 50 then return end
        table.insert( self.StuffToSay, { path = pathIn } )

    end
end

function ENT:SpokenLinesThink()
    if not self.CanSpeak then return end
    if self.NextTermSpeak > CurTime() then return end
    if #self.StuffToSay <= 0 then
        local loopingSounds = self.IdleLoopingSounds
        if not loopingSounds or #loopingSounds <= 0 then return end

        if self.term_IdleLoopingSound and self.term_RestartIdleSound and self.term_RestartIdleSound < CurTime() then
            self.term_IdleLoopingSound:Stop()
            self.term_IdleLoopingSound = nil

        end

        if not self.term_IdleLoopingSound or not self.term_IdleLoopingSound:IsPlaying() then
            if self.term_IdleLoopingSound then
                self.term_IdleLoopingSound:Stop()
                self.term_IdleLoopingSound = nil

            end
            local pickedSound = loopingSounds[ math.random( 1, #loopingSounds ) ]
            self.term_IdleLoopingSound = CreateSound( self, pickedSound )
            self.term_IdleLoopingSound:PlayEx( 0, math.random( 95, 105 ) )
            self.term_IdleLoopingSound:ChangeVolume( 1, 1 )
            self.term_RestartIdleSound = CurTime() + SoundDuration( pickedSound ) * 3
            self:CallOnRemove( "term_cleanupidlesound", function( ent )
                if not ent.term_IdleLoopingSound then return end
                ent.term_IdleLoopingSound:Stop()
                ent.term_IdleLoopingSound = nil

            end )
        end
        return
    end

    local speakDat = table.remove( self.StuffToSay, 1 )

    local conditionFunc = speakDat.conditionFunc
    if isfunction( conditionFunc ) and not conditionFunc( self ) then return end

    local sentenceIn = speakDat.sent
    if sentenceIn then
        local sentence

        if istable( sentenceIn ) then
            sentence = sentenceIn[ math.random( 1, #sentenceIn ) ]

        elseif isstring( sentenceIn ) then
            sentence = sentenceIn

        end

        if not sentence then return end
        if isstring( self.lastSpokenSentence ) and ( sentence == self.lastSpokenSentence ) then return end

        if self.term_IdleLoopingSound then
            self.term_IdleLoopingSound:Stop()
            self.term_IdleLoopingSound = nil

        end

        self.lastSpokenSentence = sentence

        EmitSentence( sentence, self:GetShootPos(), self:EntIndex(), CHAN_AUTO, 1, 80, 0, 100 )

        local additional = math.random( 10, 15 ) / 50

        local duration = SentenceDuration( sentence ) or 1
        self.NextTermSpeak = CurTime() + ( duration + additional )
        return

    end
    local pathIn = speakDat.path
    if pathIn then
        local path

        if istable( pathIn ) then
            path = pathIn[ math.random( 1, #pathIn ) ]

        elseif isstring( pathIn ) then
            path = pathIn

        end

        if not path then return end
        if isstring( self.lastSpokenSound ) and ( sentence == self.lastSpokenSound ) then return end

        if self.term_IdleLoopingSound then
            self.term_IdleLoopingSound:Stop()
            self.term_IdleLoopingSound = nil

        end

        self.lastSpokenSound = path

        self:EmitSound( path, 80, 100, 1, CHAN_VOICE )

        local additional = math.random( 10, 15 ) / 50

        local duration = SoundDuration( path ) or 1
        self.NextTermSpeak = CurTime() + ( duration + additional )
        return

    end
end

function ENT:SpeakLine( line )
    self:EmitSound( line, 85, 100, 1, CHAN_AUTO )

end

hook.Add( "PlayerDeath", "terminator_killedenemy", function( _, _, killer )
    if not killer.OnKilledPlayerEnemyLine then return end
    killer.terminator_KilledPlayer = true

end )

hook.Add( "terminator_engagedenemywasbad", "terminator_killedenemy", function( self, enemyLost )
    if not self.OnKilledGenericEnemyLine then return end
    if not IsValid( enemyLost ) then return end
    if enemyLost:Health() <= 0 then
        if self.terminator_KilledPlayer and self.OnKilledPlayerEnemyLine then
            self.terminator_KilledPlayer = nil
            self:OnKilledPlayerEnemyLine( enemyLost )

        else
            self:OnKilledGenericEnemyLine( enemyLost )

        end
    end
end )