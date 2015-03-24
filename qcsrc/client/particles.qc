#include "particles.qh"

void Net_ReadVortexBeamParticle()
{
	vector shotorg, endpos;
	float charge;
	shotorg.x = ReadCoord(); shotorg.y = ReadCoord(); shotorg.z = ReadCoord();
	endpos.x = ReadCoord(); endpos.y = ReadCoord(); endpos.z = ReadCoord();
	charge = ReadByte() / 255.0;

	pointparticles(particleeffectnum("nex_muzzleflash"), shotorg, normalize(endpos - shotorg) * 1000, 1);

	//draw either the old v2.3 beam or the new beam
	charge = sqrt(charge); // divide evenly among trail spacing and alpha
	particles_alphamin = particles_alphamax = particles_fade = charge;

	string s = ((charge >= 0.95 && particleeffectnum("nex_beam_charged") >= 0) ? "nex_beam_charged" : "nex_beam");

	if(autocvar_cl_particles_newvortexbeam && (getstati(STAT_ALLOW_OLDVORTEXBEAM) || isdemo()))
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum("nex_beam_new"), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	else if(autocvar_cl_particles_oldvortexbeam && (getstati(STAT_ALLOW_OLDVORTEXBEAM) || isdemo()))
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum("TE_TEI_G3NEUTRAL"), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	else
		WarpZone_TrailParticles_WithMultiplier(world, particleeffectnum(s), shotorg, endpos, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
}
