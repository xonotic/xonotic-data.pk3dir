#ifdef SVQC

void spawnfunc_info_teleport_destination (void)
{SELFPARAM();
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

void spawnfunc_misc_teleporter_dest (void)
{
	spawnfunc_info_teleport_destination();
}

void spawnfunc_target_teleporter (void)
{
	spawnfunc_info_teleport_destination();
}

#endif
