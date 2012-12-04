.float skeleton_modelindex;
#define BONETYPE_LOWER 0
#define BONETYPE_UPPER 1
#define MAX_BONES 128
.float skeleton_bonetype[MAX_BONES];
.float skeleton_aimbone;
.float skeleton_numbones;

void skeleton_identifybones(entity e)
{
	float s = e.skeletonindex;
	float n = (e.skeleton_numbones = skel_get_numbones(s));
	e.skeleton_aimbone = 0;
	float i;
	for(i = 1; i <= n; ++i)
	{
		float t = BONETYPE_LOWER;
		float p = skel_get_boneparent(s, i);
		if(p > 0)
			t = e.(skeleton_bonetype[p-1]);
		string nm = skel_get_bonename(s, i);
		if(nm == "spine2")
			t = BONETYPE_UPPER;
		if(nm == "upperarm_R")
			e.skeleton_aimbone = i;
		e.(skeleton_bonetype[i-1]) = t;
	}
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
	e.lerpfrac3 = savelerpfrac;
	e.lerpfrac4 = savelerpfrac;
}
