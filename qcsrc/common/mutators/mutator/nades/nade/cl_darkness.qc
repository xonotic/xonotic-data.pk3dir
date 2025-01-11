#include "cl_darkness.qh"

bool darkness_fadealpha;

void HUD_DarkBlinking()
{
	vector bottomright = vec2(vid_conwidth, vid_conheight);
	drawfill('0 0 0', bottomright, NADE_TYPE_DARKNESS.m_color, darkness_fadealpha, DRAWFLAG_NORMAL);
}

MUTATOR_HOOKFUNCTION(cl_nades, HUD_Draw_overlay)
{
	if (STAT(NADE_DARKNESS_TIME) > time)
	{
		if (!darkness_fadealpha)
			sound(csqcplayer, CH_PAIN, SND_BLIND, VOL_BASE, ATTEN_NORM);
		darkness_fadealpha = min(0.986, darkness_fadealpha + frametime * 7);
	}
	else if (darkness_fadealpha > 0)
		darkness_fadealpha = max(0, darkness_fadealpha - frametime * 7);

	if (darkness_fadealpha > 0)
	{
		HUD_DarkBlinking();
		M_ARGV(1, float) = 0; // alpha_multipl 0, don't draw normal overlay
		return true;
	}
	return false;
}
