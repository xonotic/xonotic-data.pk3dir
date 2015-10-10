#ifdef SVQC
float magicear_matched;
float W_Tuba_HasPlayed(entity pl, string melody, float instrument, float ignorepitch, float mintempo, float maxtempo);
string trigger_magicear_processmessage(entity ear, entity source, float teamsay, entity privatesay, string msgin)
{SELFPARAM();
	float domatch, dotrigger, matchstart, l;
	string s, msg;
	string savemessage;

	magicear_matched = false;

	dotrigger = ((IS_PLAYER(source)) && (source.deadflag == DEAD_NO) && ((ear.radius == 0) || (vlen(source.origin - ear.origin) <= ear.radius)));
	domatch = ((ear.spawnflags & 32) || dotrigger);

	if (!domatch)
		return msgin;

	if (!msgin)
	{
		// we are in TUBA mode!
		if (!(ear.spawnflags & 256))
			return msgin;

		if(!W_Tuba_HasPlayed(source, ear.message, ear.movedir_x, !(ear.spawnflags & 512), ear.movedir_y, ear.movedir_z))
			return msgin;

		magicear_matched = true;

		if(dotrigger)
		{
			activator = source;
			setself(ear);
			savemessage = self.message;
			self.message = string_null;
			SUB_UseTargets();
			self.message = savemessage;
			setself(this);
		}

		if(ear.netname != "")
			return ear.netname;

		return msgin;
	}

	if(ear.spawnflags & 256) // ENOTUBA
		return msgin;

	if(privatesay)
	{
		if(ear.spawnflags & 4)
			return msgin;
	}
	else
	{
		if(!teamsay)
			if(ear.spawnflags & 1)
				return msgin;
		if(teamsay > 0)
			if(ear.spawnflags & 2)
				return msgin;
		if(teamsay < 0)
			if(ear.spawnflags & 8)
				return msgin;
	}

	matchstart = -1;
	l = strlen(ear.message);

	if(ear.spawnflags & 128)
		msg = msgin;
	else
		msg = strdecolorize(msgin);

	if(substring(ear.message, 0, 1) == "*")
	{
		if(substring(ear.message, -1, 1) == "*")
		{
			// two wildcards
			// as we need multi-replacement here...
			s = substring(ear.message, 1, -2);
			l -= 2;
			if(strstrofs(msg, s, 0) >= 0)
				matchstart = -2; // we use strreplace on s
		}
		else
		{
			// match at start
			s = substring(ear.message, 1, -1);
			l -= 1;
			if(substring(msg, -l, l) == s)
				matchstart = strlen(msg) - l;
		}
	}
	else
	{
		if(substring(ear.message, -1, 1) == "*")
		{
			// match at end
			s = substring(ear.message, 0, -2);
			l -= 1;
			if(substring(msg, 0, l) == s)
				matchstart = 0;
		}
		else
		{
			// full match
			s = ear.message;
			if(msg == ear.message)
				matchstart = 0;
		}
	}

	if(matchstart == -1) // no match
		return msgin;

	magicear_matched = true;

	if(dotrigger)
	{
		activator = source;
		setself(ear);
		savemessage = self.message;
		self.message = string_null;
		SUB_UseTargets();
		self.message = savemessage;
		setself(this);
	}

	if(ear.spawnflags & 16)
	{
		return ear.netname;
	}
	else if(ear.netname != "")
	{
		if(matchstart < 0)
			return strreplace(s, ear.netname, msg);
		else
			return strcat(
				substring(msg, 0, matchstart),
				ear.netname,
				substring(msg, matchstart + l, -1)
			);
	}
	else
		return msgin;
}

entity magicears;
string trigger_magicear_processmessage_forallears(entity source, float teamsay, entity privatesay, string msgin)
{
	entity ear;
	string msgout;
	for(ear = magicears; ear; ear = ear.enemy)
	{
		msgout = trigger_magicear_processmessage(ear, source, teamsay, privatesay, msgin);
		if(!(ear.spawnflags & 64))
		if(magicear_matched)
			return msgout;
		msgin = msgout;
	}
	return msgin;
}

spawnfunc(trigger_magicear)
{
	self.enemy = magicears;
	magicears = self;

	// actually handled in "say" processing
	// spawnflags:
	//    1 = ignore say
	//    2 = ignore teamsay
	//    4 = ignore tell
	//    8 = ignore tell to unknown player
	//   16 = let netname replace the whole message (otherwise, netname is a word replacement if set)
	//   32 = perform the replacement even if outside the radius or dead
	//   64 = continue replacing/triggering even if this one matched
	//  128 = don't decolorize message before matching
	//  256 = message is a tuba note sequence (pitch.duration pitch.duration ...)
	//  512 = tuba notes must be exact right pitch, no transposing
	// message: either
	//   *pattern*
	// or
	//   *pattern
	// or
	//   pattern*
	// or
	//   pattern
	// netname:
	//   if set, replacement for the matched text
	// radius:
	//   "hearing distance"
	// target:
	//   what to trigger
	// movedir:
	//   for spawnflags 256, defines 'instrument+1 mintempo maxtempo' (zero component doesn't matter)

	self.movedir_x -= 1; // map to tuba instrument numbers
}
#endif
