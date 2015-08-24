#include "util.qh"

#if defined(CSQC)
	#include "../dpdefs/csprogsdefs.qh"
    #include "../client/defs.qh"
    #include "constants.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../server/defs.qh"
#endif

// client movement
void viewloc_PlayerPhysics()
{
	if(self.viewloc)
	{
		vector oldmovement = self.movement;
		self.movement_x = oldmovement_y;
		self.movement_y = 0;

		if(self.movement_x < 0)
			self.movement_x = -self.movement_x;

		vector level_start, level_end;
		level_start = self.viewloc.enemy.origin;
		level_end = self.viewloc.goalentity.origin;
		vector forward, backward;
		forward = vectoangles(normalize(level_end - level_start));
		backward = vectoangles(normalize(level_start - level_end));

		if(self.movement_x < 0) // left
			self.angles_y = backward_y;
		if(self.movement_x > 0) // right
			self.angles_y = forward_y;

		if(oldmovement_x > 0)
#ifdef CSQC
			input_angles_x =
#endif
			self.v_angle_x = self.angles_x = -50;
		else if(oldmovement_x < 0)
#ifdef CSQC
			input_angles_x =
#endif
			self.v_angle_x = self.angles_x = 50;

		//if(!PHYS_INPUT_BUTTON_CROUCH(self) && !IS_DUCKED(self))
#ifdef SVQC
			//self.BUTTON_CROUCH = (oldmovement_x < 0);
			if(oldmovement_x < 0)
				self.BUTTON_CROUCH = true;
#elif defined(CSQC)
			if(oldmovement_x < 0) { input_buttons |= 16; self.flags |= FL_DUCKED; } //else { input_buttons &= ~16; self.flags &= ~FL_DUCKED; }
#endif
	}
}

#ifdef CSQC

void viewloc_SetTags()
{
	if(self.viewloc && wasfreed(self.viewloc))
		self.viewloc = world;

	if(self.viewloc.entnum != self.tag_networkviewloc)
	if(self.tag_networkviewloc == 0)
		self.viewloc = world;
	else
		self.viewloc = findfloat(world, entnum, self.tag_networkviewloc);
}

vector old_camera_angle = '0 0 0';
void viewloc_SetViewLocation()
{
	entity view = CSQCModel_server2csqc(player_localentnum);
	if(!view) { return; }
	//NOTE: the "cam_" cvars sould probably be changed out with a spawnflag or an entity key. I have it like this for my testing -- Player_2
	if(view.viewloc && !wasfreed(view.viewloc) && view.viewloc.enemy && view.viewloc.goalentity)
	{
		vector position_a, position_b, camera_position, camera_angle, forward, backward;
		//vector scratch;

		position_a = view.viewloc.enemy.origin;
		position_b = view.viewloc.goalentity.origin;

#if 0
		/*TODO: have the camera only move when a player moves too much from the center of the camera
		 * basically the player can move around in a "box" in the center of th screen with out changing the camera position or angles
		*/
		if (cvar("cam_box")) {
			camera_position = vec_bounds_in(view.origin, position_a, position_b);
		}
		else
#endif
			camera_position = vec_bounds_in(view.origin, position_a, position_b);


		camera_angle = '0 0 0';

		// a tracking camera follows the player when it leaves the world box
		if (cvar("cam_track")) {
			camera_angle = aim_vec (camera_position, view.origin);
		}

		// hard snap changes the angle as soon as it crosses over the nearest 90 degree mark
		if (cvar("cam_snap_hard")){
			camera_angle = angle_snap_vec(aim_vec(camera_position, view.origin), 90);
		}

		// tries to avoid snapping unless it *really* needs to
		if (cvar("cam_snap_close")){

			// like hard snap, but don't snap angles yet.
			camera_angle = aim_vec(camera_position, view.origin);

			/* if the difference between the old and new angle is 60 degrees or more, switch angles.
			 * NOTE: bug/feature: this will use non-snaped angles for one frame.
			 * doing this resualts in less code, faster code, and a smoother transisition between angles.
			 */
			float camera_angle_diff = max(camera_angle_y, old_camera_angle_y) - min(camera_angle_y, old_camera_angle_y);

			if ( camera_angle_diff >= 60)
				old_camera_angle_y = angle_snap_f(camera_angle_y, 90);
			else
				camera_angle_y = old_camera_angle_y;
		}

		//unlocking this allows the camera to look up and down. this also allows a top-down view.
		if (!cvar("cam_snap_unlock")) {
			camera_angle_x = 0;
			camera_angle_z = 0;
		}

#if 0
		dprint(vtos(camera_position), "\n");
		dprint(vtos(old_camera_angle), "\n");
		dprint(vtos(camera_angle), "\n");
#endif

		freeze_org = getpropertyvec(VF_ORIGIN);
		freeze_ang = getpropertyvec(VF_ANGLES);
		setproperty(VF_ORIGIN, camera_position);
		setproperty(VF_ANGLES, camera_angle);

		forward = vectoangles(normalize(vec_to_min(position_b, position_a) - vec_to_max(position_b, position_a)));
		backward = vectoangles(normalize(vec_to_max(position_b, position_a) - vec_to_min(position_b, position_a)));

		if(input_movevalues_y < 0) // left
			view.angles_y = backward_y;
		if(input_movevalues_y > 0) // favour right
			view.angles_y = forward_y;

		setproperty(VF_CL_VIEWANGLES, view.angles);
	}
}

#endif
