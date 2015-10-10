#ifdef SVQC

spawnfunc(info_teleport_destination)
{
	self.classname = "info_teleport_destination";

	self.mangle = self.angles;
	self.angles = '0 0 0';

	//setorigin (self, self.origin + '0 0 27');	// To fix a mappers' habit as old as Quake
	setorigin (self, self.origin);

	IFTARGETED
	{
	}
	else
		objerror ("^3Teleport destination without a targetname");
}

spawnfunc(misc_teleporter_dest)
{
	spawnfunc_info_teleport_destination(this);
}

spawnfunc(target_teleporter)
{
	spawnfunc_info_teleport_destination(this);
}

#endif
