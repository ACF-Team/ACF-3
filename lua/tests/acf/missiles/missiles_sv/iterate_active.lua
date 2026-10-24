return {
    groupName = "ACF.Missiles.IterateActive",

    beforeEach = function( State )
        State.Saved = table.Copy( ACF.ActiveMissiles )
        table.Empty( ACF.ActiveMissiles )
    end,

    afterEach = function( State )
        table.Empty( ACF.ActiveMissiles )
        table.Merge( ACF.ActiveMissiles, State.Saved )
    end,

    cases = {
        {
            name = "Yields nothing when no missile is in flight",
            func = function()
                local Count = 0

                for _ in ACF.Missiles.IterateActive() do Count = Count + 1 end

                expect( Count ).to.equal( 0 )
            end
        },

        {
            name = "Yields every missile in flight once",
            func = function()
                local A, B = {}, {}
                ACF.ActiveMissiles[A] = true
                ACF.ActiveMissiles[B] = true

                local Seen = {}
                for Missile in ACF.Missiles.IterateActive() do Seen[Missile] = ( Seen[Missile] or 0 ) + 1 end

                expect( Seen[A] ).to.equal( 1 )
                expect( Seen[B] ).to.equal( 1 )
            end
        },

        {
            name = "IsActive is true only for missiles in flight",
            func = function()
                local A = {}
                ACF.ActiveMissiles[A] = true

                expect( ACF.Missiles.IsActive( A ) ).to.beTrue()
                expect( ACF.Missiles.IsActive( {} ) ).to.beFalse()
            end
        },
    }
}
