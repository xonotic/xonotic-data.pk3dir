#ifdef IMPLEMENTATION
#ifdef SVQC
	#include "../../../../server/antilag.qh"
#endif
#include "../../../physics.qh"


#if defined(SVQC)
void bugrigs_SetVars();
void bugrigs_AddStats();

REGISTER_MUTATOR(bugrigs, cvar("g_bugrigs"))
{
	MUTATOR_ONADD
	{
		bugrigs_SetVars();
		bugrigs_AddStats();
	}
	return false;
}
#elif defined(CSQC)
REGISTER_MUTATOR(bugrigs, true);
#endif


#ifdef CSQC

#define PHYS_BUGRIGS						getstati(STAT_BUGRIGS)
#define PHYS_BUGRIGS_ANGLE_SMOOTHING 		getstati(STAT_BUGRIGS_ANGLE_SMOOTHING)
#define PHYS_BUGRIGS_PLANAR_MOVEMENT 		getstati(STAT_BUGRIGS_PLANAR_MOVEMENT)
#define PHYS_BUGRIGS_REVERSE_SPEEDING 		getstati(STAT_BUGRIGS_REVERSE_SPEEDING)
#define PHYS_BUGRIGS_FRICTION_FLOOR 		getstatf(STAT_BUGRIGS_FRICTION_FLOOR)
#define PHYS_BUGRIGS_AIR_STEERING 			getstati(STAT_BUGRIGS_AIR_STEERING)
#define PHYS_BUGRIGS_FRICTION_BRAKE 		getstatf(STAT_BUGRIGS_FRICTION_BRAKE)
#define PHYS_BUGRIGS_ACCEL 					getstatf(STAT_BUGRIGS_ACCEL)
#define PHYS_BUGRIGS_SPEED_REF 				getstatf(STAT_BUGRIGS_SPEED_REF)
#define PHYS_BUGRIGS_SPEED_POW 				getstatf(STAT_BUGRIGS_SPEED_POW)
#define PHYS_BUGRIGS_STEER 					getstatf(STAT_BUGRIGS_STEER)
#define PHYS_BUGRIGS_FRICTION_AIR 			getstatf(STAT_BUGRIGS_FRICTION_AIR)
#define PHYS_BUGRIGS_CAR_JUMPING 			getstatf(STAT_BUGRIGS_CAR_JUMPING)
#define PHYS_BUGRIGS_REVERSE_SPINNING 		getstatf(STAT_BUGRIGS_REVERSE_SPINNING)
#define PHYS_BUGRIGS_REVERSE_STOPPING 		getstatf(STAT_BUGRIGS_REVERSE_STOPPING)

#elif defined(SVQC)

bool g_bugrigs;
bool g_bugrigs_planar_movement;
bool g_bugrigs_planar_movement_car_jumping;
float g_bugrigs_reverse_spinning;
float g_bugrigs_reverse_speeding;
float g_bugrigs_reverse_stopping;
float g_bugrigs_air_steering;
float g_bugrigs_angle_smoothing;
float g_bugrigs_friction_floor;
float g_bugrigs_friction_brake;
float g_bugrigs_friction_air;
float g_bugrigs_accel;
float g_bugrigs_speed_ref;
float g_bugrigs_speed_pow;
float g_bugrigs_steer;

#define PHYS_BUGRIGS						g_bugrigs
#define PHYS_BUGRIGS_ANGLE_SMOOTHING		g_bugrigs_angle_smoothing
#define PHYS_BUGRIGS_PLANAR_MOVEMENT		g_bugrigs_planar_movement
#define PHYS_BUGRIGS_REVERSE_SPEEDING		g_bugrigs_reverse_speeding
#define PHYS_BUGRIGS_FRICTION_FLOOR			g_bugrigs_friction_floor
#define PHYS_BUGRIGS_AIR_STEERING			g_bugrigs_air_steering
#define PHYS_BUGRIGS_FRICTION_BRAKE			g_bugrigs_friction_brake
#define PHYS_BUGRIGS_ACCEL					g_bugrigs_accel
#define PHYS_BUGRIGS_SPEED_REF				g_bugrigs_speed_ref
#define PHYS_BUGRIGS_SPEED_POW				g_bugrigs_speed_pow
#define PHYS_BUGRIGS_STEER					g_bugrigs_steer
#define PHYS_BUGRIGS_FRICTION_AIR			g_bugrigs_friction_air
#define PHYS_BUGRIGS_CAR_JUMPING			g_bugrigs_planar_movement_car_jumping
#define PHYS_BUGRIGS_REVERSE_SPINNING		g_bugrigs_reverse_spinning
#define PHYS_BUGRIGS_REVERSE_STOPPING		g_bugrigs_reverse_stopping

.float stat_bugrigs;
.float stat_bugrigs_angle_smoothing;
.float stat_bugrigs_planar_movement;
.float stat_bugrigs_reverse_speeding;
.float stat_bugrigs_friction_floor;
.float stat_bugrigs_air_steering;
.float stat_bugrigs_friction_brake;
.float stat_bugrigs_accel;
.float stat_bugrigs_speed_ref;
.float stat_bugrigs_speed_pow;
.float stat_bugrigs_steer;
.float stat_bugrigs_friction_air;
.float stat_bugrigs_car_jumping;
.float stat_bugrigs_reverse_spinning;
.float stat_bugrigs_reverse_stopping;

void bugrigs_SetVars()
{
	g_bugrigs = cvar("g_bugrigs");
	g_bugrigs_planar_movement = cvar("g_bugrigs_planar_movement");
	g_bugrigs_planar_movement_car_jumping = cvar("g_bugrigs_planar_movement_car_jumping");
	g_bugrigs_reverse_spinning = cvar("g_bugrigs_reverse_spinning");
	g_bugrigs_reverse_speeding = cvar("g_bugrigs_reverse_speeding");
	g_bugrigs_reverse_stopping = cvar("g_bugrigs_reverse_stopping");
	g_bugrigs_air_steering = cvar("g_bugrigs_air_steering");
	g_bugrigs_angle_smoothing = cvar("g_bugrigs_angle_smoothing");
	g_bugrigs_friction_floor = cvar("g_bugrigs_friction_floor");
	g_bugrigs_friction_brake = cvar("g_bugrigs_friction_brake");
	g_bugrigs_friction_air = cvar("g_bugrigs_friction_air");
	g_bugrigs_accel = cvar("g_bugrigs_accel");
	g_bugrigs_speed_ref = cvar("g_bugrigs_speed_ref");
	g_bugrigs_speed_pow = cvar("g_bugrigs_speed_pow");
	g_bugrigs_steer = cvar("g_bugrigs_steer");
}

void bugrigs_UpdateStats(entity this)
{
	this.stat_bugrigs = PHYS_BUGRIGS;
	this.stat_bugrigs_angle_smoothing = PHYS_BUGRIGS_ANGLE_SMOOTHING;
	this.stat_bugrigs_planar_movement = PHYS_BUGRIGS_PLANAR_MOVEMENT;
	this.stat_bugrigs_reverse_speeding = PHYS_BUGRIGS_REVERSE_SPEEDING;
	this.stat_bugrigs_friction_floor = PHYS_BUGRIGS_FRICTION_FLOOR;
	this.stat_bugrigs_air_steering = PHYS_BUGRIGS_AIR_STEERING;
	this.stat_bugrigs_friction_brake = PHYS_BUGRIGS_FRICTION_BRAKE;
	this.stat_bugrigs_accel = PHYS_BUGRIGS_ACCEL;
	this.stat_bugrigs_speed_ref = PHYS_BUGRIGS_SPEED_REF;
	this.stat_bugrigs_speed_pow = PHYS_BUGRIGS_SPEED_POW;
	this.stat_bugrigs_steer = PHYS_BUGRIGS_STEER;
	this.stat_bugrigs_friction_air = PHYS_BUGRIGS_FRICTION_AIR;
	this.stat_bugrigs_car_jumping = PHYS_BUGRIGS_CAR_JUMPING;
	this.stat_bugrigs_reverse_spinning = PHYS_BUGRIGS_REVERSE_SPINNING;
	this.stat_bugrigs_reverse_stopping = PHYS_BUGRIGS_REVERSE_STOPPING;
}

void bugrigs_AddStats()
{
	addstat(STAT_BUGRIGS, AS_INT, stat_bugrigs);
	addstat(STAT_BUGRIGS_ANGLE_SMOOTHING, AS_INT, stat_bugrigs_angle_smoothing);
	addstat(STAT_BUGRIGS_PLANAR_MOVEMENT, AS_INT, stat_bugrigs_planar_movement);
	addstat(STAT_BUGRIGS_REVERSE_SPEEDING, AS_INT, stat_bugrigs_reverse_speeding);
	addstat(STAT_BUGRIGS_FRICTION_FLOOR, AS_FLOAT, stat_bugrigs_friction_floor);
	addstat(STAT_BUGRIGS_AIR_STEERING, AS_INT, stat_bugrigs_air_steering);
	addstat(STAT_BUGRIGS_FRICTION_BRAKE, AS_FLOAT, stat_bugrigs_friction_brake);
	addstat(STAT_BUGRIGS_ACCEL, AS_FLOAT, stat_bugrigs_accel);
	addstat(STAT_BUGRIGS_SPEED_REF, AS_FLOAT, stat_bugrigs_speed_ref);
	addstat(STAT_BUGRIGS_SPEED_POW, AS_FLOAT, stat_bugrigs_speed_pow);
	addstat(STAT_BUGRIGS_STEER, AS_FLOAT, stat_bugrigs_steer);
	addstat(STAT_BUGRIGS_FRICTION_AIR, AS_FLOAT, stat_bugrigs_friction_air);
	addstat(STAT_BUGRIGS_CAR_JUMPING, AS_FLOAT, stat_bugrigs_car_jumping);
	addstat(STAT_BUGRIGS_REVERSE_SPINNING, AS_FLOAT, stat_bugrigs_reverse_spinning);
	addstat(STAT_BUGRIGS_REVERSE_STOPPING, AS_FLOAT, stat_bugrigs_reverse_stopping);
}

#endif

void RaceCarPhysics(entity this)
{
	// using this move type for "big rigs"
	// the engine does not push the entity!

	vector rigvel;

	vector angles_save = this.angles;
	float accel = bound(-1, this.movement.x / PHYS_MAXSPEED(this), 1);
	float steer = bound(-1, this.movement.y / PHYS_MAXSPEED(this), 1);

	if (PHYS_BUGRIGS_REVERSE_SPEEDING)
	{
		if (accel < 0)
		{
			// back accel is DIGITAL
			// to prevent speedhack
			if (accel < -0.5)
				accel = -1;
			else
				accel = 0;
		}
	}

	this.angles_x = 0;
	this.angles_z = 0;
	makevectors(this.angles); // new forward direction!

	if (IS_ONGROUND(this) || PHYS_BUGRIGS_AIR_STEERING)
	{
		float myspeed = this.velocity * v_forward;
		float upspeed = this.velocity * v_up;

		// responsiveness factor for steering and acceleration
		float f = 1 / (1 + pow(max(-myspeed, myspeed) / PHYS_BUGRIGS_SPEED_REF, PHYS_BUGRIGS_SPEED_POW));
		//MAXIMA: f(v) := 1 / (1 + (v / PHYS_BUGRIGS_SPEED_REF) ^ PHYS_BUGRIGS_SPEED_POW);

		float steerfactor;
		if (myspeed < 0 && PHYS_BUGRIGS_REVERSE_SPINNING)
			steerfactor = -myspeed * PHYS_BUGRIGS_STEER;
		else
			steerfactor = -myspeed * f * PHYS_BUGRIGS_STEER;

		float accelfactor;
		if (myspeed < 0 && PHYS_BUGRIGS_REVERSE_SPEEDING)
			accelfactor = PHYS_BUGRIGS_ACCEL;
		else
			accelfactor = f * PHYS_BUGRIGS_ACCEL;
		//MAXIMA: accel(v) := f(v) * PHYS_BUGRIGS_ACCEL;

		if (accel < 0)
		{
			if (myspeed > 0)
			{
				myspeed = max(0, myspeed - PHYS_INPUT_TIMELENGTH * (PHYS_BUGRIGS_FRICTION_FLOOR - PHYS_BUGRIGS_FRICTION_BRAKE * accel));
			}
			else
			{
				if (!PHYS_BUGRIGS_REVERSE_SPEEDING)
					myspeed = min(0, myspeed + PHYS_INPUT_TIMELENGTH * PHYS_BUGRIGS_FRICTION_FLOOR);
			}
		}
		else
		{
			if (myspeed >= 0)
			{
				myspeed = max(0, myspeed - PHYS_INPUT_TIMELENGTH * PHYS_BUGRIGS_FRICTION_FLOOR);
			}
			else
			{
				if (PHYS_BUGRIGS_REVERSE_STOPPING)
					myspeed = 0;
				else
					myspeed = min(0, myspeed + PHYS_INPUT_TIMELENGTH * (PHYS_BUGRIGS_FRICTION_FLOOR + PHYS_BUGRIGS_FRICTION_BRAKE * accel));
			}
		}
		// terminal velocity = velocity at which 50 == accelfactor, that is, 1549 units/sec
		//MAXIMA: friction(v) := PHYS_BUGRIGS_FRICTION_FLOOR;

		this.angles_y += steer * PHYS_INPUT_TIMELENGTH * steerfactor; // apply steering
		makevectors(this.angles); // new forward direction!

		myspeed += accel * accelfactor * PHYS_INPUT_TIMELENGTH;

		rigvel = myspeed * v_forward + '0 0 1' * upspeed;
	}
	else
	{
		float myspeed = vlen(this.velocity);

		// responsiveness factor for steering and acceleration
		float f = 1 / (1 + pow(max(0, myspeed / PHYS_BUGRIGS_SPEED_REF), PHYS_BUGRIGS_SPEED_POW));
		float steerfactor = -myspeed * f;
		this.angles_y += steer * PHYS_INPUT_TIMELENGTH * steerfactor; // apply steering

		rigvel = this.velocity;
		makevectors(this.angles); // new forward direction!
	}

	rigvel *= max(0, 1 - vlen(rigvel) * PHYS_BUGRIGS_FRICTION_AIR * PHYS_INPUT_TIMELENGTH);
	//MAXIMA: airfriction(v) := v * v * PHYS_BUGRIGS_FRICTION_AIR;
	//MAXIMA: total_acceleration(v) := accel(v) - friction(v) - airfriction(v);
	//MAXIMA: solve(total_acceleration(v) = 0, v);

	if (PHYS_BUGRIGS_PLANAR_MOVEMENT)
	{
		vector rigvel_xy, neworigin, up;
		float mt;

		rigvel_z -= PHYS_INPUT_TIMELENGTH * PHYS_GRAVITY; // 4x gravity plays better
		rigvel_xy = vec2(rigvel);

		if (PHYS_BUGRIGS_CAR_JUMPING)
			mt = MOVE_NORMAL;
		else
			mt = MOVE_NOMONSTERS;

		tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 1024', mt, this);
		up = trace_endpos - this.origin;

		// BUG RIGS: align the move to the surface instead of doing collision testing
		// can we move?
		tracebox(trace_endpos, this.mins, this.maxs, trace_endpos + rigvel_xy * PHYS_INPUT_TIMELENGTH, mt, this);

		// align to surface
		tracebox(trace_endpos, this.mins, this.maxs, trace_endpos - up + '0 0 1' * rigvel_z * PHYS_INPUT_TIMELENGTH, mt, this);

		if (trace_fraction < 0.5)
		{
			trace_fraction = 1;
			neworigin = this.origin;
		}
		else
			neworigin = trace_endpos;

		if (trace_fraction < 1)
		{
			// now set angles_x so that the car points parallel to the surface
			this.angles = vectoangles(
					'1 0 0' * v_forward_x * trace_plane_normal_z
					+
					'0 1 0' * v_forward_y * trace_plane_normal_z
					+
					'0 0 1' * -(v_forward_x * trace_plane_normal_x + v_forward_y * trace_plane_normal_y)
					);
			SET_ONGROUND(this);
		}
		else
		{
			// now set angles_x so that the car points forward, but is tilted in velocity direction
			UNSET_ONGROUND(this);
		}

		this.velocity = (neworigin - this.origin) * (1.0 / PHYS_INPUT_TIMELENGTH);
		this.movetype = MOVETYPE_NOCLIP;
	}
	else
	{
		rigvel_z -= PHYS_INPUT_TIMELENGTH * PHYS_GRAVITY; // 4x gravity plays better
		this.velocity = rigvel;
		this.movetype = MOVETYPE_FLY;
	}

	trace_fraction = 1;
	tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 4', MOVE_NORMAL, this);
	if (trace_fraction != 1)
	{
		this.angles = vectoangles2(
				'1 0 0' * v_forward_x * trace_plane_normal_z
				+
				'0 1 0' * v_forward_y * trace_plane_normal_z
				+
				'0 0 1' * -(v_forward_x * trace_plane_normal_x + v_forward_y * trace_plane_normal_y),
				trace_plane_normal
				);
	}
	else
	{
		vector vel_local;

		vel_local_x = v_forward * this.velocity;
		vel_local_y = v_right * this.velocity;
		vel_local_z = v_up * this.velocity;

		this.angles_x = racecar_angle(vel_local_x, vel_local_z);
		this.angles_z = racecar_angle(-vel_local_y, vel_local_z);
	}

	// smooth the angles
	vector vf1, vu1, smoothangles;
	makevectors(this.angles);
	float f = bound(0, PHYS_INPUT_TIMELENGTH * PHYS_BUGRIGS_ANGLE_SMOOTHING, 1);
	if (f == 0)
		f = 1;
	vf1 = v_forward * f;
	vu1 = v_up * f;
	makevectors(angles_save);
	vf1 = vf1 + v_forward * (1 - f);
	vu1 = vu1 + v_up * (1 - f);
	smoothangles = vectoangles2(vf1, vu1);
	this.angles_x = -smoothangles_x;
	this.angles_z =  smoothangles_z;

	PM_ClientMovement_Move();
}

#ifdef SVQC
.vector bugrigs_prevangles;
#endif
MUTATOR_HOOKFUNCTION(bugrigs, PM_Physics)
{
	if(!PHYS_BUGRIGS || !IS_PLAYER(self)) { return false; }

#ifdef SVQC
	self.angles = self.bugrigs_prevangles;
#endif

	RaceCarPhysics(self);
	return true;
}

MUTATOR_HOOKFUNCTION(bugrigs, PlayerPhysics)
{
	if(!PHYS_BUGRIGS) { return false; }
#ifdef SVQC
	self.bugrigs_prevangles = self.angles;

	bugrigs_UpdateStats(self);
#endif
	return false;
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(bugrigs, ClientConnect)
{
	stuffcmd(self, "cl_cmd settemp chase_active 1\n");
	return false;
}

MUTATOR_HOOKFUNCTION(bugrigs, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":bugrigs");
	return false;
}

MUTATOR_HOOKFUNCTION(bugrigs, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Bug rigs");
	return false;
}

#endif
#endif
