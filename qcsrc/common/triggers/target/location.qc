#ifdef SVQC
spawnfunc(target_location)
{
    self.classname = "target_location";
    // location name in netname
    // eventually support: count, teamgame selectors, line of sight?
}

spawnfunc(info_location)
{
    self.classname = "target_location";
    self.message = self.netname;
}
#endif
