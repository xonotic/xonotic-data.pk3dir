#ifdef SVQC
void spawnfunc_path_corner()
{
	// setup values for overriding train movement
	// if a second value does not exist, both start and end speeds are the single value specified
	if(!set_platmovetype(self, self.platmovetype))
		return;
}
#endif
