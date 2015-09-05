#ifdef SVQC
/*QUAKED spawnfunc_trigger_flipflop (.5 .5 .5) (-8 -8 -8) (8 8 8) START_ENABLED
"Flip-flop" trigger gate... lets only every second trigger event through
*/
void flipflop_use()
{SELFPARAM();
    self.state = !self.state;
    if(self.state)
        SUB_UseTargets();
}

void spawnfunc_trigger_flipflop()
{SELFPARAM();
    if(self.spawnflags & 1)
        self.state = 1;
    self.use = flipflop_use;
    self.reset = spawnfunc_trigger_flipflop; // perfect resetter
}
#endif
