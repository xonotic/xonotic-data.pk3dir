#include "lightningarc.qh"

REGISTER_NET_TEMP(TE_CSQC_ARC)

#if defined(SVQC)

	void te_csqc_lightningarc(vector from, vector to)
	{
		WriteHeader(MSG_BROADCAST, TE_CSQC_ARC);

		WriteVector(MSG_BROADCAST, from);
		WriteVector(MSG_BROADCAST, to);
	}

#elif defined(CSQC)

/*
.vector fx_start;
.vector fx_end;
.float  fx_with;
.string fx_texture;
.float  fx_lifetime;

void b_draw()
{
    //Draw_CylindricLine(this.fx_start, this.fx_end, this.fx_with, this.fx_texture, 0, time * 3, '1 1 1', 0.7, DRAWFLAG_ADDITIVE, view_origin);
    Draw_CylindricLine(this.fx_start, this.fx_end, this.fx_with, this.fx_texture, (this.fx_with/256), 0, '1 1 1', 1, DRAWFLAG_ADDITIVE, view_origin);

}
void b_make(vector s,vector e, string t,float l,float z)
{
    entity b;
    b = spawn();
    b.fx_texture = t;
    b.fx_start = s;
    b.fx_end = e;
    b.fx_with = z;
    b.think = SUB_Remove;
    b.nextthink = time + l;
    b.draw = b_draw;

    //b.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
}
*/

	void cl_effects_lightningarc(vector from, vector to, float seglength, float drifts, float drifte,
	float branchfactor, float branchfactor_add)
	{
		float length = vlen(from - to);
		if (length < 1) return;

		// Use at most 16 te_lightning1 segments, as these eat up beam list segments.
		// TODO: Change this to R_BeginPolygon code, then we no longer have this limit.
		int steps = min(16, floor(length / seglength));
		if (steps < 1)
		{
			te_lightning1(NULL, from, to);
			return;
		}

		float steplength = length / steps;
		vector direction  = normalize(to - from);
		vector pos_l = from;
		if (length > seglength)
		{
			for (int i = 1; i < steps; i += 1)
			{
				float drift = drifts * (1 - (i / steps)) + drifte * (i / steps);
				vector dirnew = normalize(direction * (1 - drift) + randomvec() * drift);
				vector pos = pos_l +  dirnew * steplength;
				te_lightning1(NULL, pos_l, pos);
				// WTF endless recursion if branchfactor is 1.0 (possibly due to adding branchfactor_add). FIXME
				// if(random() < branchfactor)
				//     cl_effects_lightningarc(pos, pos + (dirnew * length * 0.25),seglength,drifts,drifte,min(branchfactor + branchfactor_add,1),branchfactor_add);

				pos_l = pos;
			}
			te_lightning1(NULL, pos_l, to);
		}
		else
		{
			te_lightning1(NULL, from, to);
		}
	}

	NET_HANDLE(TE_CSQC_ARC, bool isNew)
	{
		vector from = ReadVector();
		vector to = ReadVector();
		return = true;

		if (autocvar_cl_effects_lightningarc_simple)
		{
			te_lightning1(NULL, from, to);
		}
		else
		{
			float seglength        = autocvar_cl_effects_lightningarc_segmentlength;
			float drifts           = autocvar_cl_effects_lightningarc_drift_start;
			float drifte           = autocvar_cl_effects_lightningarc_drift_end;
			float branchfactor     = autocvar_cl_effects_lightningarc_branchfactor_start;
			float branchfactor_add = autocvar_cl_effects_lightningarc_branchfactor_add;

			cl_effects_lightningarc(from, to, seglength, drifts, drifte, branchfactor, branchfactor_add);
		}
	}

#endif
