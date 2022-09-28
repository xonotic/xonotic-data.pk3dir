#include "bugrigs.qh"

#ifdef SVQC // NOTE: disabled on the client side until prediction can be fixed!

#ifdef GAMEQC

#ifdef SVQC
	#include <server/antilag.qh>
#endif
#include <common/physics/player.qh>


#if defined(SVQC)
void bugrigs_SetVars();

REGISTER_MUTATOR(bugrigs, cvar("g_bugrigs"))
{
	MUTATOR_ONADD
	{
		bugrigs_SetVars();
	}
	return false;
}
#elif defined(CSQC)
REGISTER_MUTATOR(bugrigs, true);
#endif


#if 0
#define PHYS_BUGRIGS(s)                        STAT(BUGRIGS, s)
#define PHYS_BUGRIGS_ACCEL(s)                  STAT(BUGRIGS_ACCEL, s)
#define PHYS_BUGRIGS_AIR_STEERING(s)           STAT(BUGRIGS_AIR_STEERING, s)
#define PHYS_BUGRIGS_ANGLE_SMOOTHING(s)        STAT(BUGRIGS_ANGLE_SMOOTHING, s)
#define PHYS_BUGRIGS_CAR_JUMPING(s)            STAT(BUGRIGS_CAR_JUMPING, s)
#define PHYS_BUGRIGS_FRICTION_AIR(s)           STAT(BUGRIGS_FRICTION_AIR, s)
#define PHYS_BUGRIGS_FRICTION_BRAKE(s)         STAT(BUGRIGS_FRICTION_BRAKE, s)
#define PHYS_BUGRIGS_FRICTION_FLOOR(s)         STAT(BUGRIGS_FRICTION_FLOOR, s)
#define PHYS_BUGRIGS_PLANAR_MOVEMENT(s)        STAT(BUGRIGS_PLANAR_MOVEMENT, s)
#define PHYS_BUGRIGS_REVERSE_SPEEDING(s)       STAT(BUGRIGS_REVERSE_SPEEDING, s)
#define PHYS_BUGRIGS_REVERSE_SPINNING(s)       STAT(BUGRIGS_REVERSE_SPINNING, s)
#define PHYS_BUGRIGS_REVERSE_STOPPING(s)       STAT(BUGRIGS_REVERSE_STOPPING, s)
#define PHYS_BUGRIGS_SPEED_POW(s)              STAT(BUGRIGS_SPEED_POW, s)
#define PHYS_BUGRIGS_SPEED_REF(s)              STAT(BUGRIGS_SPEED_REF, s)
#define PHYS_BUGRIGS_STEER(s)                  STAT(BUGRIGS_STEER, s)
#else
#define PHYS_BUGRIGS(s) g_bugrigs
#define PHYS_BUGRIGS_ACCEL(s) g_bugrigs_accel
#define PHYS_BUGRIGS_AIR_STEERING(s) g_bugrigs_air_steering
#define PHYS_BUGRIGS_ANGLE_SMOOTHING(s) g_bugrigs_angle_smoothing
#define PHYS_BUGRIGS_CAR_JUMPING(s) g_bugrigs_planar_movement_car_jumping
#define PHYS_BUGRIGS_FRICTION_AIR(s) g_bugrigs_friction_air
#define PHYS_BUGRIGS_FRICTION_BRAKE(s) g_bugrigs_friction_brake
#define PHYS_BUGRIGS_FRICTION_FLOOR(s) g_bugrigs_friction_floor
#define PHYS_BUGRIGS_PLANAR_MOVEMENT(s) g_bugrigs_planar_movement
#define PHYS_BUGRIGS_REVERSE_SPEEDING(s) g_bugrigs_reverse_speeding
#define PHYS_BUGRIGS_REVERSE_SPINNING(s) g_bugrigs_reverse_spinning
#define PHYS_BUGRIGS_REVERSE_STOPPING(s) g_bugrigs_reverse_stopping
#define PHYS_BUGRIGS_SPEED_POW(s) g_bugrigs_speed_pow
#define PHYS_BUGRIGS_SPEED_REF(s) g_bugrigs_speed_ref
#define PHYS_BUGRIGS_STEER(s) g_bugrigs_steer
#endif

#if defined(SVQC)

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

#endif

float racecar_angle(float forward, float down)
{
	if (forward < 0)
	{
		forward = -forward;
		down = -down;
	}

	float ret = vectoyaw('0 1 0' * down + '1 0 0' * forward);

	float angle_mult = forward / (800 + forward);

	if (ret > 180)
		return ret * angle_mult + 360 * (1 - angle_mult);
	else
		return ret * angle_mult;
}

void RaceCarPhysics(entity this, float dt)
{
	// using this move type for "big rigs"
	// the engine does not push the entity!

	vector rigvel;

	vector angles_save = this.angles;
	float accel = bound(-1, PHYS_CS(this).movement.x / PHYS_MAXSPEED(this), 1);
	float steer = bound(-1, PHYS_CS(this).movement.y / PHYS_MAXSPEED(this), 1);

	if (PHYS_BUGRIGS_REVERSE_SPEEDING(this))
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

	if (IS_ONGROUND(this) || PHYS_BUGRIGS_AIR_STEERING(this))
	{
		float myspeed = this.velocity * v_forward;
		float upspeed = this.velocity * v_up;

		// responsiveness factor for steering and acceleration
		float f = 1 / (1 + ((max(-myspeed, myspeed) / PHYS_BUGRIGS_SPEED_REF(this)) ** PHYS_BUGRIGS_SPEED_POW(this)));
		//MAXIMA: f(v) := 1 / (1 + (v / PHYS_BUGRIGS_SPEED_REF(this)) ^ PHYS_BUGRIGS_SPEED_POW(this));

		float steerfactor;
		if (myspeed < 0 && PHYS_BUGRIGS_REVERSE_SPINNING(this))
			steerfactor = -myspeed * PHYS_BUGRIGS_STEER(this);
		else
			steerfactor = -myspeed * f * PHYS_BUGRIGS_STEER(this);

		float accelfactor;
		if (myspeed < 0 && PHYS_BUGRIGS_REVERSE_SPEEDING(this))
			accelfactor = PHYS_BUGRIGS_ACCEL(this);
		else
			accelfactor = f * PHYS_BUGRIGS_ACCEL(this);
		//MAXIMA: accel(v) := f(v) * PHYS_BUGRIGS_ACCEL(this);

		if (accel < 0)
		{
			if (myspeed > 0)
			{
				myspeed = max(0, myspeed - dt * (PHYS_BUGRIGS_FRICTION_FLOOR(this) - PHYS_BUGRIGS_FRICTION_BRAKE(this) * accel));
			}
			else
			{
				if (!PHYS_BUGRIGS_REVERSE_SPEEDING(this))
					myspeed = min(0, myspeed + dt * PHYS_BUGRIGS_FRICTION_FLOOR(this));
			}
		}
		else
		{
			if (myspeed >= 0)
			{
				myspeed = max(0, myspeed - dt * PHYS_BUGRIGS_FRICTION_FLOOR(this));
			}
			else
			{
				if (PHYS_BUGRIGS_REVERSE_STOPPING(this))
					myspeed = 0;
				else
					myspeed = min(0, myspeed + dt * (PHYS_BUGRIGS_FRICTION_FLOOR(this) + PHYS_BUGRIGS_FRICTION_BRAKE(this) * accel));
			}
		}
		// terminal velocity = velocity at which 50 == accelfactor, that is, 1549 units/sec
		//MAXIMA: friction(v) := PHYS_BUGRIGS_FRICTION_FLOOR(this);

		this.angles_y += steer * dt * steerfactor; // apply steering
		makevectors(this.angles); // new forward direction!

		myspeed += accel * accelfactor * dt;

		rigvel = myspeed * v_forward + '0 0 1' * upspeed;
	}
	else
	{
		float myspeed = vlen(this.velocity);

		// responsiveness factor for steering and acceleration
		float f = 1 / (1 + (max(0, myspeed / PHYS_BUGRIGS_SPEED_REF(this)) ** PHYS_BUGRIGS_SPEED_POW(this)));
		float steerfactor = -myspeed * f;
		this.angles_y += steer * dt * steerfactor; // apply steering

		rigvel = this.velocity;
		makevectors(this.angles); // new forward direction!
	}

	rigvel *= max(0, 1 - vlen(rigvel) * PHYS_BUGRIGS_FRICTION_AIR(this) * dt);
	//MAXIMA: airfriction(v) := v * v * PHYS_BUGRIGS_FRICTION_AIR(this);
	//MAXIMA: total_acceleration(v) := accel(v) - friction(v) - airfriction(v);
	//MAXIMA: solve(total_acceleration(v) = 0, v);

	if (PHYS_BUGRIGS_PLANAR_MOVEMENT(this))
	{
		vector rigvel_xy, neworigin, up;
		float mt;

		rigvel_z -= dt * PHYS_GRAVITY(this); // 4x gravity plays better
		rigvel_xy = vec2(rigvel);

		if (PHYS_BUGRIGS_CAR_JUMPING(this))
			mt = MOVE_NORMAL;
		else
			mt = MOVE_NOMONSTERS;

		tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 1024', mt, this);
		up = trace_endpos - this.origin;

		// BUG RIGS: align the move to the surface instead of doing collision testing
		// can we move?
		tracebox(trace_endpos, this.mins, this.maxs, trace_endpos + rigvel_xy * dt, mt, this);

		// align to surface
		tracebox(trace_endpos, this.mins, this.maxs, trace_endpos - up + '0 0 1' * rigvel_z * dt, mt, this);

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
					'1 0 0' * v_forward.x * trace_plane_normal.z
					+
					'0 1 0' * v_forward.y * trace_plane_normal.z
					+
					'0 0 1' * -(v_forward.x * trace_plane_normal.x + v_forward.y * trace_plane_normal.y)
					);
			SET_ONGROUND(this);
		}
		else
		{
			// now set angles_x so that the car points forward, but is tilted in velocity direction
			UNSET_ONGROUND(this);
		}

		this.velocity = (neworigin - this.origin) * (1.0 / dt);
		set_movetype(this, MOVETYPE_NOCLIP);
	}
	else
	{
		rigvel_z -= dt * PHYS_GRAVITY(this); // 4x gravity plays better
		this.velocity = rigvel;
		set_movetype(this, MOVETYPE_FLY);
	}

	trace_fraction = 1;
	tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 4', MOVE_NORMAL, this);
	if (trace_fraction != 1)
	{
		this.angles = vectoangles2(
				'1 0 0' * v_forward.x * trace_plane_normal.z
				+
				'0 1 0' * v_forward.y * trace_plane_normal.z
				+
				'0 0 1' * -(v_forward.x * trace_plane_normal.x + v_forward.y * trace_plane_normal.y),
				trace_plane_normal
				);
	}
	else
	{
		vector vel_local;

		vel_local.x = v_forward * this.velocity;
		vel_local.y = v_right * this.velocity;
		vel_local.z = v_up * this.velocity;

		this.angles_x = racecar_angle(vel_local.x, vel_local.z);
		this.angles_z = racecar_angle(-vel_local.y, vel_local.z);
	}

	// smooth the angles
	vector vf1, vu1, smoothangles;
	makevectors(this.angles);
	float f = bound(0, dt * PHYS_BUGRIGS_ANGLE_SMOOTHING(this), 1);
	if (f == 0)
		f = 1;
	vf1 = v_forward * f;
	vu1 = v_up * f;
	makevectors(angles_save);
	vf1 = vf1 + v_forward * (1 - f);
	vu1 = vu1 + v_up * (1 - f);
	smoothangles = vectoangles2(vf1, vu1);
	this.angles_x = -smoothangles.x;
	this.angles_z =  smoothangles.z;
}

#ifdef SVQC
.vector bugrigs_prevangles;
#endif
MUTATOR_HOOKFUNCTION(bugrigs, PM_Physics)
{
    entity player = M_ARGV(0, entity);
    float dt = M_ARGV(2, float);

	if(!PHYS_BUGRIGS(player) || !IS_PLAYER(player)) { return; }

#ifdef SVQC
	player.angles = player.bugrigs_prevangles;
#endif

	RaceCarPhysics(player, dt);
	return true;
}

MUTATOR_HOOKFUNCTION(bugrigs, PlayerPhysics)
{
	if(!PHYS_BUGRIGS(M_ARGV(0, entity))) { return; }
#ifdef SVQC
	entity player = M_ARGV(0, entity);
	player.bugrigs_prevangles = player.angles;

	player.disableclientprediction = 2;
#endif
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(bugrigs, ClientConnect)
{
    entity player = M_ARGV(0, entity);

	stuffcmd(player, "cl_cmd settemp chase_active 1\n");
}

MUTATOR_HOOKFUNCTION(bugrigs, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":bugrigs");
}

MUTATOR_HOOKFUNCTION(bugrigs, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Bug rigs");
}

#endif

#endif

#endif
