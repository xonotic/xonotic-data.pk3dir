#if !XONOTIC
	entity me;

	/** 6 bits provides up to 64 remembered states */
	const int SNAP_BITS = 13;
	.int snap;
	.float times[1 << SNAP_BITS];

	void CSQC_Init()
	{
		entity it = me = spawn();
		it.mins = '-16 -16 -24';
		it.maxs = '+16 +16 +45';
		it.com_phys = true;
		it.com_phys_nogravityonground = true;
		it.com_phys_stepheight = 31;
		it.com_phys_jumpvel = 260;
		it.com_phys_friction = 6;
		it.com_phys_gravity = '0 0 800';
		it.com_phys_noclip = false;

		it.com_phys_pos = '0 0 200';
	}

	void CSQC_Ent_Update(entity this, bool isnew)
	{
		int id = ReadByte();
		FOREACH(LinkedEntities, it.m_id == id, {
			if (isnew) this.classname = it.netname;
			it.m_read(this, NULL, isnew);
			break;
		});
	}

	void rec()
	{
		me.ARRAY_INDEX(float, times, me.snap) = time;
		// me.times[me.snap] = time;
		me.snap = (me.snap + 1) & BITS(SNAP_BITS);
	}

	NET_HANDLE(ENT_OBJECT, bool isnew)
	{
		if (isnew)
		{
			this.com_phys = true;
			precache_model("models/player/erebus.iqm");
			_setmodel(this, "models/player/erebus.iqm");
			this.drawmask = MASK_NORMAL;
		}
		this.com_phys_pos_prev = this.com_phys_pos;
		this.com_phys_ang_prev = this.com_phys_ang;
		serialize(ENT_OBJECT, 0, this);
		this.com_phys_pos = this.origin;
		this.com_phys_ang = this.angles;
		return true;
	}

	void CSQC_UpdateView(entity this, float w, float h)
	{
		entity it = me;
		it.com_in_move = input_movevalues;
		it.com_in_angles = input_angles;
		it.com_in_jump = input_buttons & BIT(1);
		makevectors(it.com_in_angles);
		vector dir = normalize(it.com_in_move);
		vector upvec = '0 0 1';
		vector vel = (v_forward * dir.x + v_right * dir.y + upvec * dir.z);
		if (!it.com_phys_noclip) vel = vec_reflect(vel, upvec, 0);
		vel = normalize(vel);
		vel *= 360 * frametime * 8;
		it.com_phys_vel += vel;

		systems_update();

		setproperty(VF_ORIGIN, it.origin + '0 0 35');
		addentities(MASK_NORMAL);  // .drawmask
		renderscene();
		clearscene();

		Net_Flush();
		IL_ENDFRAME();
	}
#endif
	