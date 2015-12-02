// the way this entity works makes it no use to CSQC, as it removes itself instantly

#ifdef SVQC
void follow_init()
{SELFPARAM();
	entity src, dst;
	src = world;
	dst = world;
	if(self.killtarget != "")
		src = find(world, targetname, self.killtarget);
	if(self.target != "")
		dst = find(world, targetname, self.target);

	if(!src && !dst)
	{
		objerror("follow: could not find target/killtarget");
		return;
	}

	if(self.jointtype)
	{
		// already done :P entity must stay
		self.aiment = src;
		self.enemy = dst;
	}
	else if(!src || !dst)
	{
		objerror("follow: could not find target/killtarget");
		return;
	}
	else if(self.spawnflags & 1)
	{
		// attach
		if(self.spawnflags & 2)
		{
			setattachment(dst, src, self.message);
		}
		else
		{
			attach_sameorigin(dst, src, self.message);
		}

		dst.solid = SOLID_NOT; // solid doesn't work with attachment
		remove(self);
	}
	else
	{
		if(self.spawnflags & 2)
		{
			dst.movetype = MOVETYPE_FOLLOW;
			dst.aiment = src;
			// dst.punchangle = '0 0 0'; // keep unchanged
			dst.view_ofs = dst.origin;
			dst.v_angle = dst.angles;
		}
		else
		{
			follow_sameorigin(dst, src);
		}

		remove(self);
	}
}

spawnfunc(misc_follow)
{
	InitializeEntity(self, follow_init, INITPRIO_FINDTARGET);
}
#endif
