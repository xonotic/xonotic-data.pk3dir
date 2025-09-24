#include "scripting.qh"

#include <common/gametypes/gametype/ctf/sv_ctf.qh>
#include <common/physics/player.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <server/bot/default/bot.qh>
#include <server/bot/default/cvars.qh>
#include <server/weapons/selection.qh>
#include <server/weapons/weaponsystem.qh>

.int state;

.float bot_cmdqueuebuf_allocated;
.float bot_cmdqueuebuf;
.float bot_cmdqueuebuf_start;
.float bot_cmdqueuebuf_end;

void bot_clearqueue(entity bot)
{
	if(!bot.bot_cmdqueuebuf_allocated)
		return;
	buf_del(bot.bot_cmdqueuebuf);
	bot.bot_cmdqueuebuf_allocated = false;
	LOG_TRACE("bot ", bot.netname, " queue cleared");
}

void bot_queuecommand(entity bot, string cmdstring)
{
	if(!bot.bot_cmdqueuebuf_allocated)
	{
		bot.bot_cmdqueuebuf = buf_create();
		bot.bot_cmdqueuebuf_allocated = true;
		bot.bot_cmdqueuebuf_start = 0;
		bot.bot_cmdqueuebuf_end = 0;
	}

	bufstr_set(bot.bot_cmdqueuebuf, bot.bot_cmdqueuebuf_end, cmdstring);

	// if the command was a "sound" command, precache the sound NOW
	// this prevents lagging!
	{
		float sp;
		string parm;
		string cmdstr;

		sp = strstrofs(cmdstring, " ", 0);
		if(sp >= 0)
		{
			parm = substring(cmdstring, sp + 1, -1);
			cmdstr = substring(cmdstring, 0, sp);
			if(cmdstr == "sound")
			{
				// find the LAST word
				for (;;)
				{
					sp = strstrofs(parm, " ", 0);
					if(sp < 0)
						break;
					parm = substring(parm, sp + 1, -1);
				}
				precache_sound(parm);
			}
		}
	}

	bot.bot_cmdqueuebuf_end += 1;
}

void bot_dequeuecommand(entity bot, float idx)
{
	if(!bot.bot_cmdqueuebuf_allocated)
		error("dequeuecommand but no queue allocated");
	if(idx < bot.bot_cmdqueuebuf_start)
		error("dequeueing a command in the past");
	if(idx >= bot.bot_cmdqueuebuf_end)
		error("dequeueing a command in the future");
	bufstr_set(bot.bot_cmdqueuebuf, idx, "");
	if(idx == bot.bot_cmdqueuebuf_start)
		bot.bot_cmdqueuebuf_start += 1;
	if(bot.bot_cmdqueuebuf_start >= bot.bot_cmdqueuebuf_end)
		bot_clearqueue(bot);
}

string bot_readcommand(entity bot, float idx)
{
	if(!bot.bot_cmdqueuebuf_allocated)
		error("readcommand but no queue allocated");
	if(idx < bot.bot_cmdqueuebuf_start)
		error("reading a command in the past");
	if(idx >= bot.bot_cmdqueuebuf_end)
		error("reading a command in the future");
	return bufstr_get(bot.bot_cmdqueuebuf, idx);
}

bool bot_havecommand(entity this, int idx)
{
	if(!this.bot_cmdqueuebuf_allocated)
		return false;
	if(idx < this.bot_cmdqueuebuf_start)
		return false;
	if(idx >= this.bot_cmdqueuebuf_end)
		return false;
	return true;
}

const int MAX_BOT_PLACES = 4;
.float bot_places_count;
.entity bot_places[MAX_BOT_PLACES];
.string bot_placenames[MAX_BOT_PLACES];
entity bot_getplace(entity this, string placename)
{
	entity e;
	if(substring(placename, 0, 1) == "@")
	{
		int i, p;
		placename = substring(placename, 1, -1);
		string s, s2;
		for(i = 0; i < this.bot_places_count; ++i)
			if(this.(bot_placenames[i]) == placename)
				return this.(bot_places[i]);
		// now: i == this.bot_places_count
		s = s2 = cvar_string(placename);
		p = strstrofs(s2, " ", 0);
		if(p >= 0)
		{
			s = substring(s2, 0, p);
			//print("places: ", placename, " -> ", cvar_string(placename), "\n");
			cvar_set(placename, strcat(substring(s2, p+1, -1), " ", s));
			//print("places: ", placename, " := ", cvar_string(placename), "\n");
		}
		e = find(NULL, targetname, s);
		if(!e)
			LOG_INFO("invalid place ", s);
		if(i < MAX_BOT_PLACES)
		{
			this.(bot_placenames[i]) = strzone(placename);
			this.(bot_places[i]) = e;
			this.bot_places_count += 1;
		}
		return e;
	}
	else
	{
		e = find(NULL, targetname, placename);
		if(!e)
			LOG_INFO("invalid place ", placename);
		return e;
	}
}


// Initialize global commands list
// NOTE: New commands should be initialized here
void bot_commands_init()
{
	bot_cmd_string[BOT_CMD_NULL] = "";
	bot_cmd_parm_type[BOT_CMD_NULL] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_PAUSE] = "pause";
	bot_cmd_parm_type[BOT_CMD_PAUSE] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_CONTINUE] = "continue";
	bot_cmd_parm_type[BOT_CMD_CONTINUE] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_WAIT] = "wait";
	bot_cmd_parm_type[BOT_CMD_WAIT] = BOT_CMD_PARAMETER_FLOAT;

	bot_cmd_string[BOT_CMD_TURN] = "turn";
	bot_cmd_parm_type[BOT_CMD_TURN] = BOT_CMD_PARAMETER_FLOAT;

	bot_cmd_string[BOT_CMD_MOVETO] = "moveto";
	bot_cmd_parm_type[BOT_CMD_MOVETO] = BOT_CMD_PARAMETER_VECTOR;

	bot_cmd_string[BOT_CMD_MOVETOTARGET] = "movetotarget";
	bot_cmd_parm_type[BOT_CMD_MOVETOTARGET] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_RESETGOAL] = "resetgoal";
	bot_cmd_parm_type[BOT_CMD_RESETGOAL] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_CC] = "cc";
	bot_cmd_parm_type[BOT_CMD_CC] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_IF] = "if";
	bot_cmd_parm_type[BOT_CMD_IF] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_ELSE] = "else";
	bot_cmd_parm_type[BOT_CMD_ELSE] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_FI] = "fi";
	bot_cmd_parm_type[BOT_CMD_FI] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_RESETAIM] = "resetaim";
	bot_cmd_parm_type[BOT_CMD_RESETAIM] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_AIM] = "aim";
	bot_cmd_parm_type[BOT_CMD_AIM] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_AIMTARGET] = "aimtarget";
	bot_cmd_parm_type[BOT_CMD_AIMTARGET] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_PRESSKEY] = "presskey";
	bot_cmd_parm_type[BOT_CMD_PRESSKEY] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_RELEASEKEY] = "releasekey";
	bot_cmd_parm_type[BOT_CMD_RELEASEKEY] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_SELECTWEAPON] = "selectweapon";
	bot_cmd_parm_type[BOT_CMD_SELECTWEAPON] = BOT_CMD_PARAMETER_FLOAT;

	bot_cmd_string[BOT_CMD_IMPULSE] = "impulse";
	bot_cmd_parm_type[BOT_CMD_IMPULSE] = BOT_CMD_PARAMETER_FLOAT;

	bot_cmd_string[BOT_CMD_WAIT_UNTIL] = "wait_until";
	bot_cmd_parm_type[BOT_CMD_WAIT_UNTIL] = BOT_CMD_PARAMETER_FLOAT;

	bot_cmd_string[BOT_CMD_BARRIER] = "barrier";
	bot_cmd_parm_type[BOT_CMD_BARRIER] = BOT_CMD_PARAMETER_NONE;

	bot_cmd_string[BOT_CMD_CONSOLE] = "console";
	bot_cmd_parm_type[BOT_CMD_CONSOLE] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_SOUND] = "sound";
	bot_cmd_parm_type[BOT_CMD_SOUND] = BOT_CMD_PARAMETER_STRING;

	bot_cmd_string[BOT_CMD_DEBUG_ASSERT_CANFIRE] = "debug_assert_canfire";
	bot_cmd_parm_type[BOT_CMD_DEBUG_ASSERT_CANFIRE] = BOT_CMD_PARAMETER_FLOAT;

	bot_cmds_initialized = true;
}

// Returns first bot with matching name
entity find_bot_by_name(string name)
{
	FOREACH_CLIENT(IS_BOT_CLIENT(it) && it.netname == name,
	{
		return it;
	});

	return NULL;
}

// Returns a bot by number on list
entity find_bot_by_number(float number)
{
	entity bot;
	float c = 0;

	if(!number)
		return NULL;

	bot = findchainflags(flags, FL_CLIENT); // TODO: doesn't findchainflags loop backwards through entities?
	while (bot)
	{
		if(IS_BOT_CLIENT(bot))
		{
			if(++c==number)
				return bot;
		}
		bot = bot.chain;
	}

	return NULL;
}

float bot_decodecommand(string cmdstring)
{
	float cmd_parm_type;
	float sp;
	string parm;

	sp = strstrofs(cmdstring, " ", 0);
	if(sp < 0)
	{
		parm = "";
	}
	else
	{
		parm = substring(cmdstring, sp + 1, -1);
		cmdstring = substring(cmdstring, 0, sp);
	}

	if(!bot_cmds_initialized)
		bot_commands_init();

	int i;
	for(i=1;i<BOT_CMD_COUNTER;++i)
	{
		if(bot_cmd_string[i]!=cmdstring)
			continue;

		cmd_parm_type = bot_cmd_parm_type[i];

		if(cmd_parm_type!=BOT_CMD_PARAMETER_NONE&&parm=="")
		{
			LOG_INFO("ERROR: A parameter is required for this command");
			return 0;
		}

		// Load command into queue
		bot_cmd.bot_cmd_type = i;

		// Attach parameter
		switch(cmd_parm_type)
		{
			case BOT_CMD_PARAMETER_FLOAT:
				bot_cmd.bot_cmd_parm_float = stof(parm);
				break;
			case BOT_CMD_PARAMETER_STRING:
				strcpy(bot_cmd.bot_cmd_parm_string, parm);
				break;
			case BOT_CMD_PARAMETER_VECTOR:
				if(substring(parm, 0, 1) != "\'")
				{
					LOG_INFOF("ERROR: expected vector type \'x y z\', got %s", parm);
					return 0;
				}
				bot_cmd.bot_cmd_parm_vector = stov(parm);
				break;
			default:
				break;
		}
		return 1;
	}
	LOG_INFO("ERROR: No such command '", cmdstring, "'");
	return 0;
}

void bot_cmdhelp(string scmd)
{
	int i, ntype;
	string stype;

	if(!bot_cmds_initialized)
		bot_commands_init();

	for(i=1;i<BOT_CMD_COUNTER;++i)
	{
		if(bot_cmd_string[i]!=scmd)
			continue;

		ntype = bot_cmd_parm_type[i];

		switch(ntype)
		{
			case BOT_CMD_PARAMETER_FLOAT:
				stype = "float";
				break;
			case BOT_CMD_PARAMETER_STRING:
				stype = "string";
				break;
			case BOT_CMD_PARAMETER_VECTOR:
				stype = "vector";
				break;
			default:
				stype = "none";
				break;
		}

		string desc = "";
		switch(i)
		{
			case BOT_CMD_PAUSE:
				desc = "Stops the bot completely. Any command other than 'continue' will be ignored.";
				break;
			case BOT_CMD_CONTINUE:
				desc = "Disable paused status";
				break;
			case BOT_CMD_WAIT:
				desc = "Pause command parsing and bot ai for N seconds. Pressed key will remain pressed";
				break;
			case BOT_CMD_WAIT_UNTIL:
				desc = "Pause command parsing and bot ai until time is N from the last barrier. Pressed key will remain pressed";
				break;
			case BOT_CMD_BARRIER:
				desc = "Waits till all bots that have a command queue reach this command. Pressed key will remain pressed";
				break;
			case BOT_CMD_TURN:
				desc = "Look to the right or left N degrees. For turning to the left use positive numbers.";
				break;
			case BOT_CMD_MOVETO:
				desc = "Walk to an specific coordinate on the map. Usage: moveto \'x y z\'";
				break;
			case BOT_CMD_MOVETOTARGET:
				desc = "Walk to the specific target on the map";
				break;
			case BOT_CMD_RESETGOAL:
				desc = "Resets the goal stack";
				break;
			case BOT_CMD_CC:
				desc = "Execute client command. Examples: cc say something; cc god; cc name newnickname; cc kill;";
				break;
			case BOT_CMD_IF:
				desc = "Perform simple conditional execution.\n"
					"Syntax: \n"
					"        sv_cmd .. if \"condition\"\n"
					"        sv_cmd .. 	<instruction if true>\n"
					"        sv_cmd .. 	<instruction if true>\n"
					"        sv_cmd .. else\n"
					"        sv_cmd .. 	<instruction if false>\n"
					"        sv_cmd .. 	<instruction if false>\n"
					"        sv_cmd .. fi\n"
					"Conditions: a=b, a>b, a<b, a\t\t(spaces not allowed)\n"
					"            Values in conditions can be numbers, cvars in the form cvar.cvar_string or special fields\n"
					"Fields: health, speed, flagcarrier\n"
					"Examples: if health>50; if health>cvar.g_balance_laser_primary_damage; if flagcarrier;";
				break;
			case BOT_CMD_RESETAIM:
				desc = "Points the aim to the coordinates x,y 0,0";
				break;
			case BOT_CMD_AIM:
				desc = "Move the aim x/y (horizontal/vertical) degrees relatives to the bot\n"
					"There is a 3rd optional parameter telling in how many seconds the aim has to reach the new position\n"
					"Examples: aim \"90 0\"	// Turn 90 degrees inmediately (positive numbers move to the left/up)\n"
					"          aim \"0 90 2\"	// Will gradually look to the sky in the next two seconds";
				break;
			case BOT_CMD_AIMTARGET:
				desc = "Points the aim to given target";
				break;
			case BOT_CMD_PRESSKEY:
				desc = "Press one of the following keys: forward, backward, left, right, jump, crouch, attack1, attack2, use"
					"Multiple keys can be pressed at time (with many presskey calls) and it will remain pressed until the command \"releasekey\" is called"
					"Note: The script will not return the control to the bot ai until all keys are released";
				break;
			case BOT_CMD_RELEASEKEY:
				desc = "Release previoulsy used keys. Use the parameter \"all\" to release all keys";
				break;
			case BOT_CMD_SOUND:
				desc = "play sound file at bot location";
				break;
			case BOT_CMD_DEBUG_ASSERT_CANFIRE:
				desc = "verify the state of the weapon entity";
				break;
			default:
				desc = "This command has no description yet.";
				break;
		}
		LOG_HELP("Command: ", bot_cmd_string[i], "\nParameter: <", stype, ">", "\nDescription: ", desc);
	}
}

void bot_list_commands()
{
	int i;
	string ptype;

	if(!bot_cmds_initialized)
		bot_commands_init();

	LOG_HELP("Bot commands:");

	for(i=1;i<BOT_CMD_COUNTER;++i)
	{
		switch(bot_cmd_parm_type[i])
		{
			case BOT_CMD_PARAMETER_FLOAT:
				ptype = "float";
				break;
			case BOT_CMD_PARAMETER_STRING:
				ptype = "string";
				break;
			case BOT_CMD_PARAMETER_VECTOR:
				ptype = "vector";
				break;
			default:
				ptype = "none";
				break;
		}
		if (ptype != "none")
			LOG_HELP("  ^2", bot_cmd_string[i]," ^7<", ptype, ">");
		else
			LOG_HELP("  ^2", bot_cmd_string[i]);
	}
	LOG_HELP("For help about a specific command, type bot_cmd help <command>");
}

// Commands code
.int bot_exec_status;

float bot_cmd_cc(entity this)
{
	SV_ParseClientCommand(this, bot_cmd.bot_cmd_parm_string);
	return CMD_STATUS_FINISHED;
}

float bot_cmd_impulse(entity this)
{
	CS(this).impulse = bot_cmd.bot_cmd_parm_float;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_continue(entity this)
{
	this.bot_exec_status &= ~BOT_EXEC_STATUS_PAUSED;
	bot_relinkplayerlist();
	return CMD_STATUS_FINISHED;
}

.float bot_cmd_wait_time;
float bot_cmd_wait(entity this)
{
	if(this.bot_exec_status & BOT_EXEC_STATUS_WAITING)
	{
		if(time>=this.bot_cmd_wait_time)
		{
			this.bot_exec_status &= ~BOT_EXEC_STATUS_WAITING;
			return CMD_STATUS_FINISHED;
		}
		else
			return CMD_STATUS_EXECUTING;
	}

	this.bot_cmd_wait_time = time + bot_cmd.bot_cmd_parm_float;
	this.bot_exec_status |= BOT_EXEC_STATUS_WAITING;
	return CMD_STATUS_EXECUTING;
}

float bot_cmd_wait_until(entity this)
{
	if(time < bot_cmd.bot_cmd_parm_float + bot_barriertime)
	{
		this.bot_exec_status |= BOT_EXEC_STATUS_WAITING;
		return CMD_STATUS_EXECUTING;
	}
	this.bot_exec_status &= ~BOT_EXEC_STATUS_WAITING;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_barrier(entity this)
{
	// 0 = no barrier, 1 = waiting, 2 = waiting finished

	if(this.bot_barrier == 0) // initialization
	{
		this.bot_barrier = 1;

		//this.colormod = '4 4 0';
	}

	if(this.bot_barrier == 1) // find other bots
	{
		FOREACH_CLIENT(it.isbot, {
			if(it.bot_cmdqueuebuf_allocated)
			if(it.bot_barrier != 1)
				return CMD_STATUS_EXECUTING; // not all are at the barrier yet
		});

		// all bots hit the barrier!

		// acknowledge barrier
		FOREACH_CLIENT(it.isbot, { it.bot_barrier = 2; });

		bot_barriertime = time;
	}

	// if we get here, the barrier is finished
	// so end it...
	this.bot_barrier = 0;
	//this.colormod = '0 0 0';

	return CMD_STATUS_FINISHED;
}

float bot_cmd_turn(entity this)
{
	this.v_angle_y = this.v_angle.y + bot_cmd.bot_cmd_parm_float;
	this.v_angle_y = this.v_angle.y - floor(this.v_angle.y / 360) * 360;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_select_weapon(entity this)
{
	float id = bot_cmd.bot_cmd_parm_float;

	if(id < WEP_FIRST || id > WEP_LAST)
		return CMD_STATUS_ERROR;

	bool success = false;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.(weaponentity).m_weapon == WEP_Null && slot != 0)
			continue;

		if(client_hasweapon(this, REGISTRY_GET(Weapons, id), weaponentity, true, false))
		{
			success = true;
			this.(weaponentity).m_switchweapon = REGISTRY_GET(Weapons, id);
		}
	}

	if(!success)
		return CMD_STATUS_ERROR;

	return CMD_STATUS_FINISHED;
}

.int bot_cmd_condition_status;

const int CMD_CONDITION_NONE = 0;
const int CMD_CONDITION_true = 1;
const int CMD_CONDITION_false = 2;
const int CMD_CONDITION_true_BLOCK = 4;
const int CMD_CONDITION_false_BLOCK = 8;

float bot_cmd_eval(entity this, string expr)
{
	// Search for numbers
	if(IS_DIGIT(substring(expr, 0, 1)))
		return stof(expr);

	// Search for cvars
	if(substring(expr, 0, 5)=="cvar.")
		return cvar(substring(expr, 5, strlen(expr)));

	// Search for fields
	// TODO: expand with support for more fields (key carrier, ball carrier, armor etc)
	switch(expr)
	{
		case "health":
			return GetResource(this, RES_HEALTH);
		case "speed":
			return vlen(this.velocity);
		case "flagcarrier":
			return ((this.flagcarried!=NULL));
	}

	LOG_INFO("ERROR: Unable to convert the expression '", expr, "' into a numeric value");
	return 0;
}

float bot_cmd_if(entity this)
{
	string expr, val_a, val_b;
	float cmpofs;

	if(this.bot_cmd_condition_status != CMD_CONDITION_NONE)
	{
		// Only one "if" block is allowed at time
		LOG_INFO("ERROR: Only one conditional block can be processed at time");
		bot_clearqueue(this);
		return CMD_STATUS_ERROR;
	}

	this.bot_cmd_condition_status |= CMD_CONDITION_true_BLOCK;

	// search for operators
	expr = bot_cmd.bot_cmd_parm_string;

	cmpofs = strstrofs(expr,"=",0);

	if(cmpofs>0)
	{
		val_a = substring(expr,0,cmpofs);
		val_b = substring(expr,cmpofs+1,strlen(expr));

		if(bot_cmd_eval(this, val_a)==bot_cmd_eval(this, val_b))
			this.bot_cmd_condition_status |= CMD_CONDITION_true;
		else
			this.bot_cmd_condition_status |= CMD_CONDITION_false;

  		return CMD_STATUS_FINISHED;
	}

	cmpofs = strstrofs(expr,">",0);

	if(cmpofs>0)
	{
		val_a = substring(expr,0,cmpofs);
		val_b = substring(expr,cmpofs+1,strlen(expr));

		if(bot_cmd_eval(this, val_a)>bot_cmd_eval(this, val_b))
			this.bot_cmd_condition_status |= CMD_CONDITION_true;
		else
			this.bot_cmd_condition_status |= CMD_CONDITION_false;

		return CMD_STATUS_FINISHED;
	}

	cmpofs = strstrofs(expr,"<",0);

	if(cmpofs>0)
	{
		val_a = substring(expr,0,cmpofs);
		val_b = substring(expr,cmpofs+1,strlen(expr));

		if(bot_cmd_eval(this, val_a)<bot_cmd_eval(this, val_b))
			this.bot_cmd_condition_status |= CMD_CONDITION_true;
		else
			this.bot_cmd_condition_status |= CMD_CONDITION_false;

  		return CMD_STATUS_FINISHED;
	}

	if(bot_cmd_eval(this, expr))
		this.bot_cmd_condition_status |= CMD_CONDITION_true;
	else
		this.bot_cmd_condition_status |= CMD_CONDITION_false;

  	return CMD_STATUS_FINISHED;
}

float bot_cmd_else(entity this)
{
	this.bot_cmd_condition_status &= ~CMD_CONDITION_true_BLOCK;
	this.bot_cmd_condition_status |= CMD_CONDITION_false_BLOCK;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_fi(entity this)
{
	this.bot_cmd_condition_status = CMD_CONDITION_NONE;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_resetaim(entity this)
{
	this.v_angle = '0 0 0';
	return CMD_STATUS_FINISHED;
}

.float bot_cmd_aim_begintime;
.float bot_cmd_aim_endtime;
.vector bot_cmd_aim_begin;
.vector bot_cmd_aim_end;

float bot_cmd_aim(entity this)
{
	// Current direction
	if(this.bot_cmd_aim_endtime)
	{
		float progress;

		progress = min(1 - (this.bot_cmd_aim_endtime - time) / (this.bot_cmd_aim_endtime - this.bot_cmd_aim_begintime),1);
		this.v_angle = this.bot_cmd_aim_begin + ((this.bot_cmd_aim_end - this.bot_cmd_aim_begin) * progress);

		if(time>=this.bot_cmd_aim_endtime)
		{
			this.bot_cmd_aim_endtime = 0;
			return CMD_STATUS_FINISHED;
		}
		else
			return CMD_STATUS_EXECUTING;
	}

	// New aiming direction
	string parms;
	float tokens, step;

	parms = bot_cmd.bot_cmd_parm_string;

	tokens = tokenizebyseparator(parms, " ");

	if(tokens<2||tokens>3)
		return CMD_STATUS_ERROR;

	step = (tokens == 3) ? stof(argv(2)) : 0;

	if(step == 0)
	{
		this.v_angle_x -= stof(argv(1));
		this.v_angle_y += stof(argv(0));
		return CMD_STATUS_FINISHED;
	}

	this.bot_cmd_aim_begin = this.v_angle;

	this.bot_cmd_aim_end_x = this.v_angle.x - stof(argv(1));
	this.bot_cmd_aim_end_y = this.v_angle.y + stof(argv(0));
	this.bot_cmd_aim_end_z = 0;

	this.bot_cmd_aim_begintime = time;
	this.bot_cmd_aim_endtime = time + step;

	return CMD_STATUS_EXECUTING;
}

float bot_cmd_aimtarget(entity this)
{
	if(this.bot_cmd_aim_endtime)
	{
		return bot_cmd_aim(this);
	}

	entity e;
	string parms;
	vector v;
	float tokens, step;

	parms = bot_cmd.bot_cmd_parm_string;

	tokens = tokenizebyseparator(parms, " ");

	e = bot_getplace(this, argv(0));
	if(!e)
		return CMD_STATUS_ERROR;

	v = e.origin + (e.mins + e.maxs) * 0.5;

	if(tokens==1)
	{
		this.v_angle = vectoangles(v - (this.origin + this.view_ofs));
		this.v_angle_x = -this.v_angle.x;
		return CMD_STATUS_FINISHED;
	}

	if(tokens<1||tokens>2)
		return CMD_STATUS_ERROR;

	step = stof(argv(1));

	this.bot_cmd_aim_begin = this.v_angle;
	this.bot_cmd_aim_end = vectoangles(v - (this.origin + this.view_ofs));
	this.bot_cmd_aim_end_x = -this.bot_cmd_aim_end.x;

	this.bot_cmd_aim_begintime = time;
	this.bot_cmd_aim_endtime = time + step;

	return CMD_STATUS_EXECUTING;
}

.int bot_cmd_keys;

const int BOT_CMD_KEY_NONE 		= 0;
const int BOT_CMD_KEY_FORWARD 	= BIT(0);
const int BOT_CMD_KEY_BACKWARD 	= BIT(1);
const int BOT_CMD_KEY_RIGHT 	= BIT(2);
const int BOT_CMD_KEY_LEFT 		= BIT(3);
const int BOT_CMD_KEY_JUMP 		= BIT(4);
const int BOT_CMD_KEY_ATTACK1 	= BIT(5);
const int BOT_CMD_KEY_ATTACK2 	= BIT(6);
const int BOT_CMD_KEY_USE 		= BIT(7);
const int BOT_CMD_KEY_HOOK 		= BIT(8);
const int BOT_CMD_KEY_CROUCH 	= BIT(9);
const int BOT_CMD_KEY_CHAT 		= BIT(10);

bool bot_presskeys(entity this)
{
	CS(this).movement = '0 0 0';
	PHYS_INPUT_BUTTON_JUMP(this) = false;
	PHYS_INPUT_BUTTON_CROUCH(this) = false;
	PHYS_INPUT_BUTTON_ATCK(this) = false;
	PHYS_INPUT_BUTTON_ATCK2(this) = false;
	PHYS_INPUT_BUTTON_USE(this) = false;
	PHYS_INPUT_BUTTON_HOOK(this) = false;
	PHYS_INPUT_BUTTON_CHAT(this) = false;

	if(this.bot_cmd_keys == BOT_CMD_KEY_NONE)
		return false;

	if(this.bot_cmd_keys & BOT_CMD_KEY_FORWARD)
		CS(this).movement_x = autocvar_sv_maxspeed;
	else if(this.bot_cmd_keys & BOT_CMD_KEY_BACKWARD)
		CS(this).movement_x = -autocvar_sv_maxspeed;

	if(this.bot_cmd_keys & BOT_CMD_KEY_RIGHT)
		CS(this).movement_y = autocvar_sv_maxspeed;
	else if(this.bot_cmd_keys & BOT_CMD_KEY_LEFT)
		CS(this).movement_y = -autocvar_sv_maxspeed;

	if(this.bot_cmd_keys & BOT_CMD_KEY_JUMP)
		PHYS_INPUT_BUTTON_JUMP(this) = true;

	if(this.bot_cmd_keys & BOT_CMD_KEY_CROUCH)
		PHYS_INPUT_BUTTON_CROUCH(this) = true;

	if(this.bot_cmd_keys & BOT_CMD_KEY_ATTACK1)
		PHYS_INPUT_BUTTON_ATCK(this) = true;

	if(this.bot_cmd_keys & BOT_CMD_KEY_ATTACK2)
		PHYS_INPUT_BUTTON_ATCK2(this) = true;

	if(this.bot_cmd_keys & BOT_CMD_KEY_USE)
		PHYS_INPUT_BUTTON_USE(this) = true;

	if(this.bot_cmd_keys & BOT_CMD_KEY_HOOK)
		PHYS_INPUT_BUTTON_HOOK(this) = true;

	if(this.bot_cmd_keys & BOT_CMD_KEY_CHAT)
		PHYS_INPUT_BUTTON_CHAT(this) = true;

	return true;
}


float bot_cmd_keypress_handler(entity this, string key, float enabled)
{
	switch(key)
	{
		case "all":
			if(enabled)
				this.bot_cmd_keys = (2 ** 20) - 1; // >:)
			else
				this.bot_cmd_keys = BOT_CMD_KEY_NONE;
		case "forward":
			if(enabled)
			{
				this.bot_cmd_keys |= BOT_CMD_KEY_FORWARD;
				this.bot_cmd_keys &= ~BOT_CMD_KEY_BACKWARD;
			}
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_FORWARD;
			break;
		case "backward":
			if(enabled)
			{
				this.bot_cmd_keys |= BOT_CMD_KEY_BACKWARD;
				this.bot_cmd_keys &= ~BOT_CMD_KEY_FORWARD;
			}
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_BACKWARD;
			break;
		case "left":
			if(enabled)
			{
				this.bot_cmd_keys |= BOT_CMD_KEY_LEFT;
				this.bot_cmd_keys &= ~BOT_CMD_KEY_RIGHT;
			}
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_LEFT;
			break;
		case "right":
			if(enabled)
			{
				this.bot_cmd_keys |= BOT_CMD_KEY_RIGHT;
				this.bot_cmd_keys &= ~BOT_CMD_KEY_LEFT;
			}
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_RIGHT;
			break;
		case "jump":
			if(enabled)
				this.bot_cmd_keys |= BOT_CMD_KEY_JUMP;
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_JUMP;
			break;
		case "crouch":
			if(enabled)
				this.bot_cmd_keys |= BOT_CMD_KEY_CROUCH;
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_CROUCH;
			break;
		case "attack1":
			if(enabled)
				this.bot_cmd_keys |= BOT_CMD_KEY_ATTACK1;
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_ATTACK1;
			break;
		case "attack2":
			if(enabled)
				this.bot_cmd_keys |= BOT_CMD_KEY_ATTACK2;
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_ATTACK2;
			break;
		case "use":
			if(enabled)
				this.bot_cmd_keys |= BOT_CMD_KEY_USE;
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_USE;
			break;
		case "hook":
			if(enabled)
				this.bot_cmd_keys |= BOT_CMD_KEY_HOOK;
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_HOOK;
			break;
		case "chat":
			if(enabled)
				this.bot_cmd_keys |= BOT_CMD_KEY_CHAT;
			else
				this.bot_cmd_keys &= ~BOT_CMD_KEY_CHAT;
			break;
		default:
			break;
	}

	return CMD_STATUS_FINISHED;
}

float bot_cmd_presskey(entity this)
{
	string key;

	key = bot_cmd.bot_cmd_parm_string;

	bot_cmd_keypress_handler(this, key,true);

	return CMD_STATUS_FINISHED;
}

float bot_cmd_releasekey(entity this)
{
	string key;

	key = bot_cmd.bot_cmd_parm_string;

	return bot_cmd_keypress_handler(this, key,false);
}

bool bot_ispaused(entity this)
{
	return(this.bot_exec_status & BOT_EXEC_STATUS_PAUSED);
}

float bot_cmd_pause(entity this)
{
	PHYS_INPUT_BUTTON_DRAG(this) = false;
	PHYS_INPUT_BUTTON_USE(this) = false;
	PHYS_INPUT_BUTTON_ATCK(this) = false;
	PHYS_INPUT_BUTTON_JUMP(this) = false;
	PHYS_INPUT_BUTTON_HOOK(this) = false;
	PHYS_INPUT_BUTTON_CHAT(this) = false;
	PHYS_INPUT_BUTTON_ATCK2(this) = false;
	PHYS_INPUT_BUTTON_CROUCH(this) = false;

	CS(this).movement = '0 0 0';
	this.bot_cmd_keys = BOT_CMD_KEY_NONE;

	this.bot_exec_status |= BOT_EXEC_STATUS_PAUSED;
	bot_relinkplayerlist();
	return CMD_STATUS_FINISHED;
}

float bot_cmd_moveto(entity this)
{
	return this.cmd_moveto(this, bot_cmd.bot_cmd_parm_vector);
}

float bot_cmd_movetotarget(entity this)
{
	entity e;
	e = bot_getplace(this, bot_cmd.bot_cmd_parm_string);
	if(!e)
		return CMD_STATUS_ERROR;
	return this.cmd_moveto(this, e.origin + (e.mins + e.maxs) * 0.5);
}

float bot_cmd_resetgoal(entity this)
{
	return this.cmd_resetgoal(this);
}


float bot_cmd_sound(entity this)
{
	string f;
	f = bot_cmd.bot_cmd_parm_string;

	float n = tokenizebyseparator(f, " ");

	string sample = f;
	float chan = CH_WEAPON_B;
	float vol = VOL_BASE;
	float atten = ATTEN_MIN;

	if(n >= 1)
		sample = argv(n - 1);
	if(n >= 2)
		chan = stof(argv(0));
	if(n >= 3)
		vol = stof(argv(1));
	if(n >= 4)
		atten = stof(argv(2));

	precache_sound(f);
	_sound(this, chan, sample, vol, atten);

	return CMD_STATUS_FINISHED;
}

.entity tuba_note;
float bot_cmd_debug_assert_canfire(entity this)
{
	float f = bot_cmd.bot_cmd_parm_float;

	int slot = 0; // TODO: unhardcode?
	.entity weaponentity = weaponentities[slot];
	if(this.(weaponentity).state != WS_READY)
	{
		if(f)
		{
			this.colormod = '0 8 8';
			LOG_INFO("Bot ", this.netname, " using ", this.(weaponentity).weaponname, " wants to fire, inhibited by weaponentity state");
		}
	}
	else if(ATTACK_FINISHED(this, weaponentity) > time)
	{
		if(f)
		{
			this.colormod = '8 0 8';
			LOG_INFO("Bot ", this.netname, " using ", this.(weaponentity).weaponname, " wants to fire, inhibited by ATTACK_FINISHED (", ftos(ATTACK_FINISHED(this, weaponentity) - time), " seconds left)");
		}
	}
	else if(this.(weaponentity).tuba_note)
	{
		if(f)
		{
			this.colormod = '8 0 0';
			LOG_INFO("Bot ", this.netname, " using ", this.(weaponentity).weaponname, " wants to fire, bot still has an active tuba note");
		}
	}
	else
	{
		if(!f)
		{
			this.colormod = '8 8 0';
			LOG_INFO("Bot ", this.netname, " using ", this.(weaponentity).weaponname, " thinks it has fired, but apparently did not; ATTACK_FINISHED says ", ftos(ATTACK_FINISHED(this, weaponentity) - time), " seconds left");
		}
	}

	return CMD_STATUS_FINISHED;
}

//

void bot_command_executed(entity this, bool rm)
{
	entity cmd;

	cmd = bot_cmd;

	if(rm)
		bot_dequeuecommand(this, this.bot_cmd_execution_index);

	this.bot_cmd_execution_index++;
}

void bot_setcurrentcommand(entity this)
{
	bot_cmd = NULL;

	if(!this.bot_cmd_current)
	{
		this.bot_cmd_current = new_pure(bot_cmd);
	}

	bot_cmd = this.bot_cmd_current;
	if(bot_cmd.bot_cmd_index != this.bot_cmd_execution_index || this.bot_cmd_execution_index == 0)
	{
		if(bot_havecommand(this, this.bot_cmd_execution_index))
		{
			string cmdstring;
			cmdstring = bot_readcommand(this, this.bot_cmd_execution_index);
			if(bot_decodecommand(cmdstring))
			{
				bot_cmd.owner = this;
				bot_cmd.bot_cmd_index = this.bot_cmd_execution_index;
			}
			else
			{
				// Invalid command, remove from queue
				bot_cmd = NULL;
				bot_dequeuecommand(this, this.bot_cmd_execution_index);
				this.bot_cmd_execution_index++;
			}
		}
		else
			bot_cmd = NULL;
	}
}

void bot_resetqueues()
{
	FOREACH_CLIENT(it.isbot, {
		it.bot_cmd_execution_index = 0;
		bot_clearqueue(it);
		// also, cancel all barriers
		it.bot_barrier = 0;
		for(int i = 0; i < it.bot_places_count; ++i)
		{
			strfree(it.(bot_placenames[i]));
		}
		it.bot_places_count = 0;
	});

	bot_barriertime = time;
}

// Here we map commands to functions and deal with complex interactions between commands and execution states
// NOTE: Of course you need to include your commands here too :)
float bot_execute_commands_once(entity this)
{
	float status, ispressingkey;

	// Find command
	bot_setcurrentcommand(this);

	// Ignore all commands except continue when the bot is paused
	if(!(this.bot_exec_status & BOT_EXEC_STATUS_PAUSED))
	{
		// if we have no bot command, better return
		// old logic kept pressing previously pressed keys, but that has problems
		// (namely, it means you cannot make a bot "normal" ever again)
		// to keep a bot walking for a while, use the "wait" bot command
		if(bot_cmd == world)
			return 0;
	}
	else if(bot_cmd.bot_cmd_type != BOT_CMD_CONTINUE)
	{
		if(bot_cmd.bot_cmd_type!=BOT_CMD_NULL)
		{
			bot_command_executed(this, true);
			LOG_INFO("WARNING: Commands are ignored while the bot is paused. Use the command 'continue' instead.");
		}
		return 1;
	}

	// Keep pressing keys raised by the "presskey" command
	ispressingkey = boolean(bot_presskeys(this));

	// Handle conditions
	if (!(bot_cmd.bot_cmd_type == BOT_CMD_FI || bot_cmd.bot_cmd_type == BOT_CMD_ELSE))
	if((this.bot_cmd_condition_status & CMD_CONDITION_true) && (this.bot_cmd_condition_status & CMD_CONDITION_false_BLOCK))
	{
		bot_command_executed(this, true);
		return -1;
	}
	else if((this.bot_cmd_condition_status & CMD_CONDITION_false) && (this.bot_cmd_condition_status & CMD_CONDITION_true_BLOCK))
	{
		bot_command_executed(this, true);
		return -1;
	}

	// Map commands to functions
	switch(bot_cmd.bot_cmd_type)
	{
		case BOT_CMD_NULL:
			return ispressingkey;
			//break;
		case BOT_CMD_PAUSE:
			status = bot_cmd_pause(this);
			break;
		case BOT_CMD_CONTINUE:
			status = bot_cmd_continue(this);
			break;
		case BOT_CMD_WAIT:
			status = bot_cmd_wait(this);
			break;
		case BOT_CMD_WAIT_UNTIL:
			status = bot_cmd_wait_until(this);
			break;
		case BOT_CMD_TURN:
			status = bot_cmd_turn(this);
			break;
		case BOT_CMD_MOVETO:
			status = bot_cmd_moveto(this);
			break;
		case BOT_CMD_MOVETOTARGET:
			status = bot_cmd_movetotarget(this);
			break;
		case BOT_CMD_RESETGOAL:
			status = bot_cmd_resetgoal(this);
			break;
		case BOT_CMD_CC:
			status = bot_cmd_cc(this);
			break;
		case BOT_CMD_IF:
			status = bot_cmd_if(this);
			break;
		case BOT_CMD_ELSE:
			status = bot_cmd_else(this);
			break;
		case BOT_CMD_FI:
			status = bot_cmd_fi(this);
			break;
		case BOT_CMD_RESETAIM:
			status = bot_cmd_resetaim(this);
			break;
		case BOT_CMD_AIM:
			status = bot_cmd_aim(this);
			break;
		case BOT_CMD_AIMTARGET:
			status = bot_cmd_aimtarget(this);
			break;
		case BOT_CMD_PRESSKEY:
			status = bot_cmd_presskey(this);
			break;
		case BOT_CMD_RELEASEKEY:
			status = bot_cmd_releasekey(this);
			break;
		case BOT_CMD_SELECTWEAPON:
			status = bot_cmd_select_weapon(this);
			break;
		case BOT_CMD_IMPULSE:
			status = bot_cmd_impulse(this);
			break;
		case BOT_CMD_BARRIER:
			status = bot_cmd_barrier(this);
			break;
		case BOT_CMD_CONSOLE:
			localcmd(strcat(bot_cmd.bot_cmd_parm_string, "\n"));
			status = CMD_STATUS_FINISHED;
			break;
		case BOT_CMD_SOUND:
			status = bot_cmd_sound(this);
			break;
		case BOT_CMD_DEBUG_ASSERT_CANFIRE:
			status = bot_cmd_debug_assert_canfire(this);
			break;
		default:
			LOG_INFOF("ERROR: Invalid command on queue with id '%s'", ftos(bot_cmd.bot_cmd_type));
			return 0;
	}

	if (status==CMD_STATUS_ERROR)
		LOG_INFOF("ERROR: The command '%s' returned an error status", bot_cmd_string[bot_cmd.bot_cmd_type]);

	// Move execution pointer
	if(status==CMD_STATUS_EXECUTING)
	{
		return 1;
	}
	else
	{
		if(autocvar_g_debug_bot_commands)
		{
			string parms;

			switch(bot_cmd_parm_type[bot_cmd.bot_cmd_type])
			{
				case BOT_CMD_PARAMETER_FLOAT:
					parms = ftos(bot_cmd.bot_cmd_parm_float);
					break;
				case BOT_CMD_PARAMETER_STRING:
					parms = bot_cmd.bot_cmd_parm_string;
					break;
				case BOT_CMD_PARAMETER_VECTOR:
					parms = vtos(bot_cmd.bot_cmd_parm_vector);
					break;
				default:
					parms = "";
					break;
			}
			clientcommand(this,strcat("say ^7", bot_cmd_string[bot_cmd.bot_cmd_type]," ",parms,"\n"));
		}

		bot_command_executed(this, true);
	}

	if(status == CMD_STATUS_FINISHED)
		return -1;

	return CMD_STATUS_ERROR;
}

// This function should be (the only) called directly from the bot ai loop
int bot_execute_commands(entity this)
{
	int f;
	do
	{
		f = bot_execute_commands_once(this);
	}
	while(f < 0);
	return f;
}
