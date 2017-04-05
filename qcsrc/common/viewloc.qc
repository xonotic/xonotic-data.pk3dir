#include "viewloc.qh"
#include "util.qh"

#if defined(CSQC)
    #include "../client/defs.qh"
    #include "constants.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../server/defs.qh"
#endif

// client movement
void viewloc_PlayerPhysics(entity this)
{
	if(this.viewloc)
	{
		if(this.viewloc.goalentity == this.viewloc.enemy)
			return; // we can't side-scroll in this case

		vector old_movement = this.movement;
		this.movement_x = old_movement_y;
		this.movement_y = 0;

		if(this.movement_x < 0)
			this.movement_x = -this.movement_x;

		vector level_start, level_end;
		level_start = this.viewloc.enemy.origin;
		level_end = this.viewloc.goalentity.origin;
		vector forward, backward;
		forward = vectoangles(normalize(level_end - level_start));
		backward = vectoangles(normalize(level_start - level_end));

		if(this.movement_x < 0) // left
			this.angles_y = backward_y;
		if(this.movement_x > 0) // right
			this.angles_y = forward_y;

		if(old_movement_x > 0)
#ifdef CSQC
			input_angles_x =
#endif
			this.v_angle_x = this.angles_x = -50;
		else if(old_movement_x < 0)
#ifdef CSQC
			input_angles_x =
#endif
			this.v_angle_x = this.angles_x = 50;

		//if(!PHYS_INPUT_BUTTON_CROUCH(this) && !IS_DUCKED(this))
#ifdef SVQC
			//PHYS_INPUT_BUTTON_CROUCH(this) = (old_movement_x < 0);
			if (old_movement.x < 0)
				PHYS_INPUT_BUTTON_CROUCH(this) = true;
#elif defined(CSQC)
			if (old_movement.x < 0)
			{
				input_buttons |= BIT(4);
				this.flags |= FL_DUCKED;
			}
			//else { input_buttons &= ~16; this.flags &= ~FL_DUCKED; }
#endif
	}
}

#ifdef CSQC

void viewloc_SetTags(entity this)
{
	if(this.viewloc && wasfreed(this.viewloc))
		this.viewloc = NULL;

	if(this.viewloc.entnum != this.tag_networkviewloc)
	if(this.tag_networkviewloc == 0)
		this.viewloc = NULL;
	else
		this.viewloc = findfloat(NULL, entnum, this.tag_networkviewloc);
}

vector old_camera_angle = '0 0 0';
bool autocvar_cam_snap_close;
bool autocvar_cam_track;
bool autocvar_cam_snap_hard;
bool autocvar_cam_snap_unlock;
void viewloc_SetViewLocation()
{
	entity view = CSQCModel_server2csqc(player_localentnum - 1);
	if (!view) return;
	//NOTE: the "cam_" cvars sould probably be changed out with a spawnflag or an entity key. I have it like this for my testing -- Player_2
	if(view.viewloc && !wasfreed(view.viewloc) && view.viewloc.enemy && view.viewloc.goalentity)
	{
		bool have_sidescroll = (view.viewloc.enemy != view.viewloc.goalentity);
		vector position_a, position_b, camera_position, camera_angle = '0 0 0', forward, backward;
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


		// a tracking camera follows the player when it leaves the world box
		if (autocvar_cam_track || !have_sidescroll) {
			camera_angle = aim_vec (camera_position, view.origin);
		}

		// hard snap changes the angle as soon as it crosses over the nearest 90 degree mark
		if (autocvar_cam_snap_hard){
			camera_angle = angle_snap_vec(aim_vec(camera_position, view.origin), 90);
		}

		// tries to avoid snapping unless it *really* needs to
		if (autocvar_cam_snap_close){

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
		if (!autocvar_cam_snap_unlock) {
			camera_angle_x = 0;
			camera_angle_z = 0;
		}

#if 0
		LOG_TRACE(vtos(camera_position));
		LOG_TRACE(vtos(old_camera_angle));
		LOG_TRACE(vtos(camera_angle));
#endif

		freeze_org = getpropertyvec(VF_ORIGIN);
		freeze_ang = getpropertyvec(VF_ANGLES);
		setproperty(VF_ORIGIN, camera_position);
		setproperty(VF_ANGLES, camera_angle);

		if(have_sidescroll)
		{
			forward = vectoangles(normalize(vec_to_min(position_b, position_a) - vec_to_max(position_b, position_a)));
			backward = vectoangles(normalize(vec_to_max(position_b, position_a) - vec_to_min(position_b, position_a)));

			if(input_movevalues_y < 0) // left
				view.angles_y = backward.y;
			if(input_movevalues_y > 0) // favour right
				view.angles_y = forward.y;

			setproperty(VF_CL_VIEWANGLES, view.angles);
		}
	}
}

#endif
