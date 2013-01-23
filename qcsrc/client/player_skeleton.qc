.float skeleton_modelindex;
#define BONETYPE_LOWER 0
#define BONETYPE_UPPER 1
#define MAX_BONES 128
.float skeleton_bonetype[MAX_BONES];
.float skeleton_fixrotatebone;
.float skeleton_fixtargetbone;
.float skeleton_bone;
.float skeleton_aimbone;
.float skeleton_numbones;

void skeleton_identifybones(entity e)
{
	float s = e.skeletonindex;
	float n = (e.skeleton_numbones = skel_get_numbones(s));
	e.skeleton_aimbone = 0;
	e.skeleton_fixrotatebone = 0;
	e.skeleton_fixtargetbone = 0;
	float i;
	for(i = 1; i <= n; ++i)
	{
		float t = BONETYPE_LOWER;
		float p = skel_get_boneparent(s, i);
		if(p > 0)
			t = e.(skeleton_bonetype[p-1]);
		string nm = skel_get_bonename(s, i);
		if(nm == "spine2")
		{
			e.skeleton_fixrotatebone = i;
			t = BONETYPE_UPPER;
		}
		if(nm == "weapon" || nm == "tag_weapon" || nm == "bip01 r hand")
			if(t == BONETYPE_UPPER)
				e.skeleton_fixtargetbone = i;
		if(nm == "upperarm_R")
			e.skeleton_aimbone = i;
		e.(skeleton_bonetype[i-1]) = t;
	}
}

void skel_set_bone_lerp(float skel, float bone, vector org, float strength)
{
	if(strength >= 1)
		return skel_set_bone(skel, bone, org);

	vector fo = v_forward;
	vector ri = v_right;
	vector up = v_up;
	vector oldorg = skel_get_bonerel(skel, bone);

	org = org * strength + oldorg * (1 - strength);
	v_forward = fo * strength + v_forward * (1 - strength);
	v_right = ri * strength + v_right * (1 - strength);
	v_up = up * strength + v_up * (1 - strength);
	return skel_set_bone(skel, bone, org);
}

void skeleton_fixbone(entity e, float strength, float yawonly)
{
	if(!e.skeleton_fixrotatebone)
		return;
	if(strength <= 0)
		return;
	// model:
	// T  = M_before_fixrotate * M_fixrotate  * M_after_fixrotate
	// T' = M_before_fixrotate^-1 * M_fixrotate' * M_after_fixrotate
	// M_fixrotate' = M_before_fixrotate^-1 * T' * M_after_fixrotate^-1
	float s = e.skeletonindex;

	skel_get_boneabs(s, skel_get_boneparent(s, e.skeleton_fixrotatebone));
	vector M_before_fixrotate = fixedvectoangles2(v_forward, v_up);
	skel_get_boneabs(s, e.skeleton_fixrotatebone);
	vector M_including_fixrotate = fixedvectoangles2(v_forward, v_up);
	skel_get_boneabs(s, e.skeleton_fixtargetbone);
	vector T = fixedvectoangles2(v_forward, v_up);
	vector M_after_fixrotate = AnglesTransform_LeftDivide(M_including_fixrotate, T);
	vector T_ = T;
	if(yawonly)
		T__y = 0; // undo yaw
	else
		T_ = '0 0 0'; // undo all
	vector M_fixrotate_ = AnglesTransform_LeftDivide(M_before_fixrotate, AnglesTransform_RightDivide(T_, M_after_fixrotate));
	vector org = skel_get_bonerel(s, e.skeleton_fixrotatebone);
	fixedmakevectors(M_fixrotate_);
	skel_set_bone_lerp(s, e.skeleton_fixrotatebone, org, strength);
}

void free_skeleton_from_frames(entity e)
{
	if(e.skeletonindex)
	{
		skel_delete(e.skeletonindex);
		e.skeletonindex = 0;
	}
}

void skeleton_from_frames(entity e)
{
	float m = e.modelindex;
	if(m != e.skeleton_modelindex)
	{
		if(e.skeletonindex)
		{
			skel_delete(e.skeletonindex);
			e.skeletonindex = 0;
		}
		m = (e.skeleton_modelindex = e.modelindex);
		if(m)
		{
			e.skeletonindex = skel_create(m);
			skeleton_identifybones(e);
		}
	}
	float s = e.skeletonindex;
	if(!s)
		return;
	float bone;
	float n = e.skeleton_numbones;
	float savelerpfrac = e.lerpfrac;
	float savelerpfrac3 = e.lerpfrac3;
	float savelerpfrac4 = e.lerpfrac4;
	for(bone = 0; bone < n; )
	{
		float firstbone = bone;
		float bonetype = e.skeleton_bonetype[bone];
		for(++bone; (bone < n) && (e.skeleton_bonetype[bone] == bonetype); ++bone)
			;
		if(bonetype == BONETYPE_UPPER)
		{
			// only show frames 1+3 (upper body)
			e.lerpfrac = 0;
			e.lerpfrac3 = savelerpfrac3 * 2;
			e.lerpfrac4 = 0;
		}
		else
		{
			// only show frames 2+4 (lower body)
			e.lerpfrac = savelerpfrac * 2;
			e.lerpfrac3 = 0;
			e.lerpfrac4 = savelerpfrac4 * 2;
		}
		//print(sprintf("Run: bone %d to %d, type %d\n", firstbone + 1, bone, bonetype));
		//print(sprintf("frame %d %d %d %d lerpfrac * %d %d %d\n", e.frame, e.frame2, e.frame3, e.frame4, e.lerpfrac, e.lerpfrac3, e.lerpfrac4));
		skel_build(s, e, m, 0, firstbone + 1, bone);
	}
	e.lerpfrac = savelerpfrac;
	e.lerpfrac3 = savelerpfrac3;
	e.lerpfrac4 = savelerpfrac4;

	if(autocvar__animblend_fixbone)
	{
		float l4 = e.lerpfrac4;
		float l3 = e.lerpfrac3;
		float l2 = e.lerpfrac;
		float l1 = 1 - l2 - l3 - l4;

		// how much of upper body animates same way as lower body?
		float equalamount =
			(e.frame == e.frame2) * (l1 * l2) +
			(e.frame == e.frame4) * (l1 * l4) +
			(e.frame3 == e.frame2) * (l3 * l2) +
			(e.frame3 == e.frame4) * (l3 * l4);
		float maxequalamount = (l1 + l3) * (l2 + l4);

		// now how strong is the lerp?
		float lerpstrength = 1 - equalamount / maxequalamount;

		// FIX IT
		skeleton_fixbone(e, lerpstrength, autocvar__animblend_fixbone >= 2);
	}
}
