#include "components/_mod.qh"

#if !XONOTIC
	entity me;

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
		it.com_phys_gravity = 800;
	}

	void CSQC_UpdateView(float w, float h)
	{
		entity it = me;
		it.com_in_move = input_movevalues;
		it.com_in_angles = input_angles;
		it.com_in_jump = input_buttons & BIT(1);
		makevectors(it.com_in_angles);
		vector dir = normalize(it.com_in_move);
		vector upvec = '0 0 1';
		vector vel = (v_forward * dir.x + v_right * dir.y + upvec * dir.z);
		vel = vec_reflect(vel, upvec, 0);
		vel = normalize(vel);
		vel *= 360 * frametime * 8;
		it.com_phys_vel += vel;

		systems_update();

		setproperty(VF_ORIGIN, it.origin + '0 0 35');
		addentities(MASK_NORMAL);  // .drawmask
		renderscene();
		clearscene();
	}
#endif
