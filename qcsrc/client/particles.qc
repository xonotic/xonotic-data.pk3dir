#include "particles.qh"

#include "../common/stats.qh"

#include "../lib/warpzone/common.qh"

void Net_ReadVortexBeamParticle()
{
	vector shotorg, endpos;
	float charge;
	shotorg.x = ReadCoord(); shotorg.y = ReadCoord(); shotorg.z = ReadCoord();
	endpos.x = ReadCoord(); endpos.y = ReadCoord(); endpos.z = ReadCoord();
	charge = ReadByte() / 255.0;

	pointparticles(particleeffectnum(EFFECT_VORTEX_MUZZLEFLASH), shotorg, normalize(endpos - shotorg) * 1000, 1);

	//draw either the old v2.3 beam or the new beam
	charge = sqrt(charge); // divide evenly among trail spacing and alpha
	particles_alphamin = particles_alphamax = particles_fade = charge;

	if (autocvar_cl_particles_oldvortexbeam && (getstati(STAT_ALLOW_OLDVORTEXBEAM) || isdemo()))
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum(EFFECT_VORTEX_BEAM_OLD), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	else
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum(EFFECT_VORTEX_BEAM), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
}
