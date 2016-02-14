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

spawnfunc(trigger_flipflop)
{
    if(this.spawnflags & 1)
        this.state = 1;
    this.use = flipflop_use;
    this.reset = spawnfunc_trigger_flipflop; // perfect resetter
}

#endif
