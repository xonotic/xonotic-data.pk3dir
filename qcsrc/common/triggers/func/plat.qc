#ifdef SVQC
void spawnfunc_func_plat()
{
	if (self.sounds == 0)
		self.sounds = 2;

    if(self.spawnflags & 4)
        self.dmg = 10000;

    if(self.dmg && (self.message == ""))
		self.message = "was squished";
    if(self.dmg && (self.message2 == ""))
		self.message2 = "was squished by";

	if (self.sounds == 1)
	{
		precache_sound ("plats/plat1.wav");
		precache_sound ("plats/plat2.wav");
		self.noise = "plats/plat1.wav";
		self.noise1 = "plats/plat2.wav";
	}

	if (self.sounds == 2)
	{
		precache_sound ("plats/medplat1.wav");
		precache_sound ("plats/medplat2.wav");
		self.noise = "plats/medplat1.wav";
		self.noise1 = "plats/medplat2.wav";
	}

	if (self.sound1)
	{
		precache_sound (self.sound1);
		self.noise = self.sound1;
	}
	if (self.sound2)
	{
		precache_sound (self.sound2);
		self.noise1 = self.sound2;
	}

	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.classname = "plat";
	if (!InitMovingBrushTrigger())
		return;
	self.effects |= EF_LOWPRECISION;
	setsize (self, self.mins , self.maxs);

	self.blocked = plat_crush;

	if (!self.speed)
		self.speed = 150;
	if (!self.lip)
		self.lip = 16;
	if (!self.height)
		self.height = self.size_z - self.lip;

	self.pos1 = self.origin;
	self.pos2 = self.origin;
	self.pos2_z = self.origin_z - self.height;

	self.reset = plat_reset;
	plat_reset();

	plat_spawn_inside_trigger ();	// the "start moving" trigger
}
#endif
