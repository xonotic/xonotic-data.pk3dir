#include "scripting.qh"

#include "bot.qh"

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
	LOG_TRACE("bot ", bot.netname, " queue cleared\n");
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

float bot_havecommand(entity bot, float idx)
{
	if(!bot.bot_cmdqueuebuf_allocated)
		return 0;
	if(idx < bot.bot_cmdqueuebuf_start)
		return 0;
	if(idx >= bot.bot_cmdqueuebuf_end)
		return 0;
	return 1;
}

const int MAX_BOT_PLACES = 4;
.float bot_places_count;
.entity bot_places[MAX_BOT_PLACES];
.string bot_placenames[MAX_BOT_PLACES];
entity bot_getplace(string placename)
{SELFPARAM();
	entity e;
	if(substring(placename, 0, 1) == "@")
	{
		int i, p;
		placename = substring(placename, 1, -1);
		string s, s2;
		for(i = 0; i < self.bot_places_count; ++i)
			if(self.(bot_placenames[i]) == placename)
				return self.(bot_places[i]);
		// now: i == self.bot_places_count
		s = s2 = cvar_string(placename);
		p = strstrofs(s2, " ", 0);
		if(p >= 0)
		{
			s = substring(s2, 0, p);
			//print("places: ", placename, " -> ", cvar_string(placename), "\n");
			cvar_set(placename, strcat(substring(s2, p+1, -1), " ", s));
			//print("places: ", placename, " := ", cvar_string(placename), "\n");
		}
		e = find(world, targetname, s);
		if(!e)
			LOG_INFO("invalid place ", s, "\n");
		if(i < MAX_BOT_PLACES)
		{
			self.(bot_placenames[i]) = strzone(placename);
			self.(bot_places[i]) = e;
			self.bot_places_count += 1;
		}
		return e;
	}
	else
	{
		e = find(world, targetname, placename);
		if(!e)
			LOG_INFO("invalid place ", placename, "\n");
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
	entity bot;

	bot = findchainflags(flags, FL_CLIENT);
	while (bot)
	{
		if(IS_BOT_CLIENT(bot))
		if(bot.netname==name)
			return bot;

		bot = bot.chain;
	}

	return world;
}

// Returns a bot by number on list
entity find_bot_by_number(float number)
{
	entity bot;
	float c = 0;

	if(!number)
		return world;

	bot = findchainflags(flags, FL_CLIENT);
	while (bot)
	{
		if(IS_BOT_CLIENT(bot))
		{
			if(++c==number)
				return bot;
		}
		bot = bot.chain;
	}

	return world;
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
			LOG_INFO("ERROR: A parameter is required for this command\n");
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
				if(bot_cmd.bot_cmd_parm_string)
					strunzone(bot_cmd.bot_cmd_parm_string);
				bot_cmd.bot_cmd_parm_string = strzone(parm);
				break;
			case BOT_CMD_PARAMETER_VECTOR:
				bot_cmd.bot_cmd_parm_vector = stov(parm);
				break;
			default:
				break;
		}
		return 1;
	}
	LOG_INFO("ERROR: No such command '", cmdstring, "'\n");
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
				stype = "float number";
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

		LOG_INFO(strcat("Command: ",bot_cmd_string[i],"\nParameter: <",stype,"> \n"));

		LOG_INFO("Description: ");
		switch(i)
		{
			case BOT_CMD_PAUSE:
				LOG_INFO("Stops the bot completely. Any command other than 'continue' will be ignored.");
				break;
			case BOT_CMD_CONTINUE:
				LOG_INFO("Disable paused status");
				break;
			case BOT_CMD_WAIT:
				LOG_INFO("Pause command parsing and bot ai for N seconds. Pressed key will remain pressed");
				break;
			case BOT_CMD_WAIT_UNTIL:
				LOG_INFO("Pause command parsing and bot ai until time is N from the last barrier. Pressed key will remain pressed");
				break;
			case BOT_CMD_BARRIER:
				LOG_INFO("Waits till all bots that have a command queue reach this command. Pressed key will remain pressed");
				break;
			case BOT_CMD_TURN:
				LOG_INFO("Look to the right or left N degrees. For turning to the left use positive numbers.");
				break;
			case BOT_CMD_MOVETO:
				LOG_INFO("Walk to an specific coordinate on the map. Usage: moveto \"x y z\"");
				break;
			case BOT_CMD_MOVETOTARGET:
				LOG_INFO("Walk to the specific target on the map");
				break;
			case BOT_CMD_RESETGOAL:
				LOG_INFO("Resets the goal stack");
				break;
			case BOT_CMD_CC:
				LOG_INFO("Execute client command. Examples: cc \"say something\"; cc god; cc \"name newnickname\"; cc kill;");
				break;
			case BOT_CMD_IF:
				LOG_INFO("Perform simple conditional execution.\n");
				LOG_INFO("Syntax: \n");
				LOG_INFO("        sv_cmd .. if \"condition\"\n");
				LOG_INFO("        sv_cmd .. 	<instruction if true>\n");
				LOG_INFO("        sv_cmd .. 	<instruction if true>\n");
				LOG_INFO("        sv_cmd .. else\n");
				LOG_INFO("        sv_cmd .. 	<instruction if false>\n");
				LOG_INFO("        sv_cmd .. 	<instruction if false>\n");
				LOG_INFO("        sv_cmd .. fi\n");
				LOG_INFO("Conditions: a=b, a>b, a<b, a\t\t(spaces not allowed)\n");
				LOG_INFO("            Values in conditions can be numbers, cvars in the form cvar.cvar_string or special fields\n");
				LOG_INFO("Fields: health, speed, flagcarrier\n");
				LOG_INFO("Examples: if health>50; if health>cvar.g_balance_laser_primary_damage; if flagcarrier;");
				break;
			case BOT_CMD_RESETAIM:
				LOG_INFO("Points the aim to the coordinates x,y 0,0");
				break;
			case BOT_CMD_AIM:
				LOG_INFO("Move the aim x/y (horizontal/vertical) degrees relatives to the bot\n");
				LOG_INFO("There is a 3rd optional parameter telling in how many seconds the aim has to reach the new position\n");
				LOG_INFO("Examples: aim \"90 0\"	// Turn 90 degrees inmediately (positive numbers move to the left/up)\n");
				LOG_INFO("          aim \"0 90 2\"	// Will gradually look to the sky in the next two seconds");
				break;
			case BOT_CMD_AIMTARGET:
				LOG_INFO("Points the aim to given target");
				break;
			case BOT_CMD_PRESSKEY:
				LOG_INFO("Press one of the following keys: forward, backward, left, right, jump, crouch, attack1, attack2, use\n");
				LOG_INFO("Multiple keys can be pressed at time (with many presskey calls) and it will remain pressed until the command \"releasekey\" is called");
				LOG_INFO("Note: The script will not return the control to the bot ai until all keys are released");
				break;
			case BOT_CMD_RELEASEKEY:
				LOG_INFO("Release previoulsy used keys. Use the parameter \"all\" to release all keys");
				break;
			case BOT_CMD_SOUND:
				LOG_INFO("play sound file at bot location");
				break;
			case BOT_CMD_DEBUG_ASSERT_CANFIRE:
				LOG_INFO("verify the state of the weapon entity");
				break;
			default:
				LOG_INFO("This command has no description yet.");
				break;
		}
		LOG_INFO("\n");
	}
}

void bot_list_commands()
{
	int i;
	string ptype;

	if(!bot_cmds_initialized)
		bot_commands_init();

	LOG_INFO("List of all available commands:\n");
	LOG_INFO("  Command - Parameter Type\n");

	for(i=1;i<BOT_CMD_COUNTER;++i)
	{
		switch(bot_cmd_parm_type[i])
		{
			case BOT_CMD_PARAMETER_FLOAT:
				ptype = "float number";
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
		LOG_INFO(strcat("  ",bot_cmd_string[i]," - <",ptype,"> \n"));
	}
}

// Commands code
.int bot_exec_status;

void SV_ParseClientCommand(string s);
float bot_cmd_cc()
{
	SV_ParseClientCommand(bot_cmd.bot_cmd_parm_string);
	return CMD_STATUS_FINISHED;
}

float bot_cmd_impulse()
{SELFPARAM();
	self.impulse = bot_cmd.bot_cmd_parm_float;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_continue()
{SELFPARAM();
	self.bot_exec_status &= ~BOT_EXEC_STATUS_PAUSED;
	return CMD_STATUS_FINISHED;
}

.float bot_cmd_wait_time;
float bot_cmd_wait()
{SELFPARAM();
	if(self.bot_exec_status & BOT_EXEC_STATUS_WAITING)
	{
		if(time>=self.bot_cmd_wait_time)
		{
			self.bot_exec_status &= ~BOT_EXEC_STATUS_WAITING;
			return CMD_STATUS_FINISHED;
		}
		else
			return CMD_STATUS_EXECUTING;
	}

	self.bot_cmd_wait_time = time + bot_cmd.bot_cmd_parm_float;
	self.bot_exec_status |= BOT_EXEC_STATUS_WAITING;
	return CMD_STATUS_EXECUTING;
}

float bot_cmd_wait_until()
{SELFPARAM();
	if(time < bot_cmd.bot_cmd_parm_float + bot_barriertime)
	{
		self.bot_exec_status |= BOT_EXEC_STATUS_WAITING;
		return CMD_STATUS_EXECUTING;
	}
	self.bot_exec_status &= ~BOT_EXEC_STATUS_WAITING;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_barrier()
{SELFPARAM();
	entity cl;

	// 0 = no barrier, 1 = waiting, 2 = waiting finished

	if(self.bot_barrier == 0) // initialization
	{
		self.bot_barrier = 1;

		//self.colormod = '4 4 0';
	}

	if(self.bot_barrier == 1) // find other bots
	{
		FOR_EACH_CLIENT(cl) if(cl.isbot)
		{
			if(cl.bot_cmdqueuebuf_allocated)
				if(cl.bot_barrier != 1)
					return CMD_STATUS_EXECUTING; // not all are at the barrier yet
		}

		// all bots hit the barrier!
		FOR_EACH_CLIENT(cl) if(cl.isbot)
		{
			cl.bot_barrier = 2; // acknowledge barrier
		}

		bot_barriertime = time;
	}

	// if we get here, the barrier is finished
	// so end it...
	self.bot_barrier = 0;
	//self.colormod = '0 0 0';

	return CMD_STATUS_FINISHED;
}

float bot_cmd_turn()
{SELFPARAM();
	self.v_angle_y = self.v_angle.y + bot_cmd.bot_cmd_parm_float;
	self.v_angle_y = self.v_angle.y - floor(self.v_angle.y / 360) * 360;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_select_weapon()
{SELFPARAM();
	float id;

	id = bot_cmd.bot_cmd_parm_float;

	if(id < WEP_FIRST || id > WEP_LAST)
		return CMD_STATUS_ERROR;

	if(client_hasweapon(self, id, true, false))
		self.switchweapon = id;
	else
		return CMD_STATUS_ERROR;

	return CMD_STATUS_FINISHED;
}

.int bot_cmd_condition_status;

const int CMD_CONDITION_NONE = 0;
const int CMD_CONDITION_true = 1;
const int CMD_CONDITION_false = 2;
const int CMD_CONDITION_true_BLOCK = 4;
const int CMD_CONDITION_false_BLOCK = 8;

float bot_cmd_eval(string expr)
{SELFPARAM();
	// Search for numbers
	if(strstrofs("0123456789", substring(expr, 0, 1), 0) >= 0)
	{
		return stof(expr);
	}

	// Search for cvars
	if(substring(expr, 0, 5)=="cvar.")
	{
		return cvar(substring(expr, 5, strlen(expr)));
	}

	// Search for fields
	switch(expr)
	{
		case "health":
			return self.health;
		case "speed":
			return vlen(self.velocity);
		case "flagcarrier":
			return ((self.flagcarried!=world));
	}

	LOG_INFO(strcat("ERROR: Unable to convert the expression '",expr,"' into a numeric value\n"));
	return 0;
}

float bot_cmd_if()
{SELFPARAM();
	string expr, val_a, val_b;
	float cmpofs;

	if(self.bot_cmd_condition_status != CMD_CONDITION_NONE)
	{
		// Only one "if" block is allowed at time
		LOG_INFO("ERROR: Only one conditional block can be processed at time");
		bot_clearqueue(self);
		return CMD_STATUS_ERROR;
	}

	self.bot_cmd_condition_status |= CMD_CONDITION_true_BLOCK;

	// search for operators
	expr = bot_cmd.bot_cmd_parm_string;

	cmpofs = strstrofs(expr,"=",0);

	if(cmpofs>0)
	{
		val_a = substring(expr,0,cmpofs);
		val_b = substring(expr,cmpofs+1,strlen(expr));

		if(bot_cmd_eval(val_a)==bot_cmd_eval(val_b))
			self.bot_cmd_condition_status |= CMD_CONDITION_true;
		else
			self.bot_cmd_condition_status |= CMD_CONDITION_false;

  		return CMD_STATUS_FINISHED;
	}

	cmpofs = strstrofs(expr,">",0);

	if(cmpofs>0)
	{
		val_a = substring(expr,0,cmpofs);
		val_b = substring(expr,cmpofs+1,strlen(expr));

		if(bot_cmd_eval(val_a)>bot_cmd_eval(val_b))
			self.bot_cmd_condition_status |= CMD_CONDITION_true;
		else
			self.bot_cmd_condition_status |= CMD_CONDITION_false;

		return CMD_STATUS_FINISHED;
	}

	cmpofs = strstrofs(expr,"<",0);

	if(cmpofs>0)
	{
		val_a = substring(expr,0,cmpofs);
		val_b = substring(expr,cmpofs+1,strlen(expr));

		if(bot_cmd_eval(val_a)<bot_cmd_eval(val_b))
			self.bot_cmd_condition_status |= CMD_CONDITION_true;
		else
			self.bot_cmd_condition_status |= CMD_CONDITION_false;

  		return CMD_STATUS_FINISHED;
	}

	if(bot_cmd_eval(expr))
		self.bot_cmd_condition_status |= CMD_CONDITION_true;
	else
		self.bot_cmd_condition_status |= CMD_CONDITION_false;

  	return CMD_STATUS_FINISHED;
}

float bot_cmd_else()
{SELFPARAM();
	self.bot_cmd_condition_status &= ~CMD_CONDITION_true_BLOCK;
	self.bot_cmd_condition_status |= CMD_CONDITION_false_BLOCK;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_fi()
{SELFPARAM();
	self.bot_cmd_condition_status = CMD_CONDITION_NONE;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_resetaim()
{SELFPARAM();
	self.v_angle = '0 0 0';
	return CMD_STATUS_FINISHED;
}

.float bot_cmd_aim_begintime;
.float bot_cmd_aim_endtime;
.vector bot_cmd_aim_begin;
.vector bot_cmd_aim_end;

float bot_cmd_aim()
{SELFPARAM();
	// Current direction
	if(self.bot_cmd_aim_endtime)
	{
		float progress;

		progress = min(1 - (self.bot_cmd_aim_endtime - time) / (self.bot_cmd_aim_endtime - self.bot_cmd_aim_begintime),1);
		self.v_angle = self.bot_cmd_aim_begin + ((self.bot_cmd_aim_end - self.bot_cmd_aim_begin) * progress);

		if(time>=self.bot_cmd_aim_endtime)
		{
			self.bot_cmd_aim_endtime = 0;
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
		self.v_angle_x -= stof(argv(1));
		self.v_angle_y += stof(argv(0));
		return CMD_STATUS_FINISHED;
	}

	self.bot_cmd_aim_begin = self.v_angle;

	self.bot_cmd_aim_end_x = self.v_angle.x - stof(argv(1));
	self.bot_cmd_aim_end_y = self.v_angle.y + stof(argv(0));
	self.bot_cmd_aim_end_z = 0;

	self.bot_cmd_aim_begintime = time;
	self.bot_cmd_aim_endtime = time + step;

	return CMD_STATUS_EXECUTING;
}

float bot_cmd_aimtarget()
{SELFPARAM();
	if(self.bot_cmd_aim_endtime)
	{
		return bot_cmd_aim();
	}

	entity e;
	string parms;
	vector v;
	float tokens, step;

	parms = bot_cmd.bot_cmd_parm_string;

	tokens = tokenizebyseparator(parms, " ");

	e = bot_getplace(argv(0));
	if(!e)
		return CMD_STATUS_ERROR;

	v = e.origin + (e.mins + e.maxs) * 0.5;

	if(tokens==1)
	{
		self.v_angle = vectoangles(v - (self.origin + self.view_ofs));
		self.v_angle_x = -self.v_angle.x;
		return CMD_STATUS_FINISHED;
	}

	if(tokens<1||tokens>2)
		return CMD_STATUS_ERROR;

	step = stof(argv(1));

	self.bot_cmd_aim_begin = self.v_angle;
	self.bot_cmd_aim_end = vectoangles(v - (self.origin + self.view_ofs));
	self.bot_cmd_aim_end_x = -self.bot_cmd_aim_end.x;

	self.bot_cmd_aim_begintime = time;
	self.bot_cmd_aim_endtime = time + step;

	return CMD_STATUS_EXECUTING;
}

.int bot_cmd_keys;

const int BOT_CMD_KEY_NONE 		= 0;
const int BOT_CMD_KEY_FORWARD 	= 1;
const int BOT_CMD_KEY_BACKWARD 	= 2;
const int BOT_CMD_KEY_RIGHT 	= 4;
const int BOT_CMD_KEY_LEFT 		= 8;
const int BOT_CMD_KEY_JUMP 		= 16;
const int BOT_CMD_KEY_ATTACK1 	= 32;
const int BOT_CMD_KEY_ATTACK2 	= 64;
const int BOT_CMD_KEY_USE 		= 128;
const int BOT_CMD_KEY_HOOK 		= 256;
const int BOT_CMD_KEY_CROUCH 	= 512;
const int BOT_CMD_KEY_CHAT 		= 1024;

float bot_presskeys()
{SELFPARAM();
	self.movement = '0 0 0';
	self.BUTTON_JUMP = false;
	self.BUTTON_CROUCH = false;
	self.BUTTON_ATCK = false;
	self.BUTTON_ATCK2 = false;
	self.BUTTON_USE = false;
	self.BUTTON_HOOK = false;
	self.BUTTON_CHAT = false;

	if(self.bot_cmd_keys == BOT_CMD_KEY_NONE)
		return false;

	if(self.bot_cmd_keys & BOT_CMD_KEY_FORWARD)
		self.movement_x = autocvar_sv_maxspeed;
	else if(self.bot_cmd_keys & BOT_CMD_KEY_BACKWARD)
		self.movement_x = -autocvar_sv_maxspeed;

	if(self.bot_cmd_keys & BOT_CMD_KEY_RIGHT)
		self.movement_y = autocvar_sv_maxspeed;
	else if(self.bot_cmd_keys & BOT_CMD_KEY_LEFT)
		self.movement_y = -autocvar_sv_maxspeed;

	if(self.bot_cmd_keys & BOT_CMD_KEY_JUMP)
		self.BUTTON_JUMP = true;

	if(self.bot_cmd_keys & BOT_CMD_KEY_CROUCH)
		self.BUTTON_CROUCH = true;

	if(self.bot_cmd_keys & BOT_CMD_KEY_ATTACK1)
		self.BUTTON_ATCK = true;

	if(self.bot_cmd_keys & BOT_CMD_KEY_ATTACK2)
		self.BUTTON_ATCK2 = true;

	if(self.bot_cmd_keys & BOT_CMD_KEY_USE)
		self.BUTTON_USE = true;

	if(self.bot_cmd_keys & BOT_CMD_KEY_HOOK)
		self.BUTTON_HOOK = true;

	if(self.bot_cmd_keys & BOT_CMD_KEY_CHAT)
		self.BUTTON_CHAT = true;

	return true;
}


float bot_cmd_keypress_handler(string key, float enabled)
{SELFPARAM();
	switch(key)
	{
		case "all":
			if(enabled)
				self.bot_cmd_keys = power2of(20) - 1; // >:)
			else
				self.bot_cmd_keys = BOT_CMD_KEY_NONE;
		case "forward":
			if(enabled)
			{
				self.bot_cmd_keys |= BOT_CMD_KEY_FORWARD;
				self.bot_cmd_keys &= ~BOT_CMD_KEY_BACKWARD;
			}
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_FORWARD;
			break;
		case "backward":
			if(enabled)
			{
				self.bot_cmd_keys |= BOT_CMD_KEY_BACKWARD;
				self.bot_cmd_keys &= ~BOT_CMD_KEY_FORWARD;
			}
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_BACKWARD;
			break;
		case "left":
			if(enabled)
			{
				self.bot_cmd_keys |= BOT_CMD_KEY_LEFT;
				self.bot_cmd_keys &= ~BOT_CMD_KEY_RIGHT;
			}
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_LEFT;
			break;
		case "right":
			if(enabled)
			{
				self.bot_cmd_keys |= BOT_CMD_KEY_RIGHT;
				self.bot_cmd_keys &= ~BOT_CMD_KEY_LEFT;
			}
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_RIGHT;
			break;
		case "jump":
			if(enabled)
				self.bot_cmd_keys |= BOT_CMD_KEY_JUMP;
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_JUMP;
			break;
		case "crouch":
			if(enabled)
				self.bot_cmd_keys |= BOT_CMD_KEY_CROUCH;
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_CROUCH;
			break;
		case "attack1":
			if(enabled)
				self.bot_cmd_keys |= BOT_CMD_KEY_ATTACK1;
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_ATTACK1;
			break;
		case "attack2":
			if(enabled)
				self.bot_cmd_keys |= BOT_CMD_KEY_ATTACK2;
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_ATTACK2;
			break;
		case "use":
			if(enabled)
				self.bot_cmd_keys |= BOT_CMD_KEY_USE;
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_USE;
			break;
		case "hook":
			if(enabled)
				self.bot_cmd_keys |= BOT_CMD_KEY_HOOK;
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_HOOK;
			break;
		case "chat":
			if(enabled)
				self.bot_cmd_keys |= BOT_CMD_KEY_CHAT;
			else
				self.bot_cmd_keys &= ~BOT_CMD_KEY_CHAT;
			break;
		default:
			break;
	}

	return CMD_STATUS_FINISHED;
}

float bot_cmd_presskey()
{
	string key;

	key = bot_cmd.bot_cmd_parm_string;

	bot_cmd_keypress_handler(key,true);

	return CMD_STATUS_FINISHED;
}

float bot_cmd_releasekey()
{
	string key;

	key = bot_cmd.bot_cmd_parm_string;

	return bot_cmd_keypress_handler(key,false);
}

float bot_cmd_pause()
{SELFPARAM();
	self.button1        = 0;
	self.button8        = 0;
	self.BUTTON_USE     = 0;
	self.BUTTON_ATCK    = 0;
	self.BUTTON_JUMP    = 0;
	self.BUTTON_HOOK    = 0;
	self.BUTTON_CHAT    = 0;
	self.BUTTON_ATCK2   = 0;
	self.BUTTON_CROUCH  = 0;

	self.movement = '0 0 0';
	self.bot_cmd_keys = BOT_CMD_KEY_NONE;

	self.bot_exec_status |= BOT_EXEC_STATUS_PAUSED;
	return CMD_STATUS_FINISHED;
}

float bot_cmd_moveto()
{SELFPARAM();
	return self.cmd_moveto(bot_cmd.bot_cmd_parm_vector);
}

float bot_cmd_movetotarget()
{SELFPARAM();
	entity e;
	e = bot_getplace(bot_cmd.bot_cmd_parm_string);
	if(!e)
		return CMD_STATUS_ERROR;
	return self.cmd_moveto(e.origin + (e.mins + e.maxs) * 0.5);
}

float bot_cmd_resetgoal()
{SELFPARAM();
	return self.cmd_resetgoal();
}


float bot_cmd_sound()
{SELFPARAM();
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
	_sound(self, chan, sample, vol, atten);

	return CMD_STATUS_FINISHED;
}

.entity tuba_note;
float bot_cmd_debug_assert_canfire()
{SELFPARAM();
	float f;
	f = bot_cmd.bot_cmd_parm_float;

	if(self.weaponentity.state != WS_READY)
	{
		if(f)
		{
			self.colormod = '0 8 8';
			LOG_INFO("Bot ", self.netname, " using ", self.weaponname, " wants to fire, inhibited by weaponentity state\n");
		}
	}
	else if(ATTACK_FINISHED(self) > time)
	{
		if(f)
		{
			self.colormod = '8 0 8';
			LOG_INFO("Bot ", self.netname, " using ", self.weaponname, " wants to fire, inhibited by ATTACK_FINISHED (", ftos(ATTACK_FINISHED(self) - time), " seconds left)\n");
		}
	}
	else if(self.tuba_note)
	{
		if(f)
		{
			self.colormod = '8 0 0';
			LOG_INFO("Bot ", self.netname, " using ", self.weaponname, " wants to fire, bot still has an active tuba note\n");
		}
	}
	else
	{
		if(!f)
		{
			self.colormod = '8 8 0';
			LOG_INFO("Bot ", self.netname, " using ", self.weaponname, " thinks it has fired, but apparently did not; ATTACK_FINISHED says ", ftos(ATTACK_FINISHED(self) - time), " seconds left\n");
		}
	}

	return CMD_STATUS_FINISHED;
}

//

void bot_command_executed(float rm)
{SELFPARAM();
	entity cmd;

	cmd = bot_cmd;

	if(rm)
		bot_dequeuecommand(self, self.bot_cmd_execution_index);

	self.bot_cmd_execution_index++;
}

void bot_setcurrentcommand()
{SELFPARAM();
	bot_cmd = world;

	if(!self.bot_cmd_current)
	{
		self.bot_cmd_current = spawn();
		self.bot_cmd_current.classname = "bot_cmd";
		self.bot_cmd_current.is_bot_cmd = 1;
	}

	bot_cmd = self.bot_cmd_current;
	if(bot_cmd.bot_cmd_index != self.bot_cmd_execution_index || self.bot_cmd_execution_index == 0)
	{
		if(bot_havecommand(self, self.bot_cmd_execution_index))
		{
			string cmdstring;
			cmdstring = bot_readcommand(self, self.bot_cmd_execution_index);
			if(bot_decodecommand(cmdstring))
			{
				bot_cmd.owner = self;
				bot_cmd.bot_cmd_index = self.bot_cmd_execution_index;
			}
			else
			{
				// Invalid command, remove from queue
				bot_cmd = world;
				bot_dequeuecommand(self, self.bot_cmd_execution_index);
				self.bot_cmd_execution_index++;
			}
		}
		else
			bot_cmd = world;
	}
}

void bot_resetqueues()
{
	entity cl;

	FOR_EACH_CLIENT(cl) if(cl.isbot)
	{
		cl.bot_cmd_execution_index = 0;
		bot_clearqueue(cl);
		// also, cancel all barriers
		cl.bot_barrier = 0;
		for(int i = 0; i < cl.bot_places_count; ++i)
		{
			strunzone(cl.(bot_placenames[i]));
			cl.(bot_placenames[i]) = string_null;
		}
		cl.bot_places_count = 0;
	}

	bot_barriertime = time;
}

// Here we map commands to functions and deal with complex interactions between commands and execution states
// NOTE: Of course you need to include your commands here too :)
float bot_execute_commands_once()
{SELFPARAM();
	float status, ispressingkey;

	// Find command
	bot_setcurrentcommand();

	// if we have no bot command, better return
	// old logic kept pressing previously pressed keys, but that has problems
	// (namely, it means you cannot make a bot "normal" ever again)
	// to keep a bot walking for a while, use the "wait" bot command
	if(bot_cmd == world)
		return false;

	// Ignore all commands except continue when the bot is paused
	if(self.bot_exec_status & BOT_EXEC_STATUS_PAUSED)
	if(bot_cmd.bot_cmd_type!=BOT_CMD_CONTINUE)
	{
		if(bot_cmd.bot_cmd_type!=BOT_CMD_NULL)
		{
			bot_command_executed(true);
			LOG_INFO( "WARNING: Commands are ignored while the bot is paused. Use the command 'continue' instead.\n");
		}
		return 1;
	}

	// Keep pressing keys raised by the "presskey" command
	ispressingkey = !!bot_presskeys();

	// Handle conditions
	if (!(bot_cmd.bot_cmd_type==BOT_CMD_FI||bot_cmd.bot_cmd_type==BOT_CMD_ELSE))
	if(self.bot_cmd_condition_status & CMD_CONDITION_true && self.bot_cmd_condition_status & CMD_CONDITION_false_BLOCK)
	{
		bot_command_executed(true);
		return -1;
	}
	else if(self.bot_cmd_condition_status & CMD_CONDITION_false && self.bot_cmd_condition_status & CMD_CONDITION_true_BLOCK)
	{
		bot_command_executed(true);
		return -1;
	}

	// Map commands to functions
	switch(bot_cmd.bot_cmd_type)
	{
		case BOT_CMD_NULL:
			return ispressingkey;
			//break;
		case BOT_CMD_PAUSE:
			status = bot_cmd_pause();
			break;
		case BOT_CMD_CONTINUE:
			status = bot_cmd_continue();
			break;
		case BOT_CMD_WAIT:
			status = bot_cmd_wait();
			break;
		case BOT_CMD_WAIT_UNTIL:
			status = bot_cmd_wait_until();
			break;
		case BOT_CMD_TURN:
			status = bot_cmd_turn();
			break;
		case BOT_CMD_MOVETO:
			status = bot_cmd_moveto();
			break;
		case BOT_CMD_MOVETOTARGET:
			status = bot_cmd_movetotarget();
			break;
		case BOT_CMD_RESETGOAL:
			status = bot_cmd_resetgoal();
			break;
		case BOT_CMD_CC:
			status = bot_cmd_cc();
			break;
		case BOT_CMD_IF:
			status = bot_cmd_if();
			break;
		case BOT_CMD_ELSE:
			status = bot_cmd_else();
			break;
		case BOT_CMD_FI:
			status = bot_cmd_fi();
			break;
		case BOT_CMD_RESETAIM:
			status = bot_cmd_resetaim();
			break;
		case BOT_CMD_AIM:
			status = bot_cmd_aim();
			break;
		case BOT_CMD_AIMTARGET:
			status = bot_cmd_aimtarget();
			break;
		case BOT_CMD_PRESSKEY:
			status = bot_cmd_presskey();
			break;
		case BOT_CMD_RELEASEKEY:
			status = bot_cmd_releasekey();
			break;
		case BOT_CMD_SELECTWEAPON:
			status = bot_cmd_select_weapon();
			break;
		case BOT_CMD_IMPULSE:
			status = bot_cmd_impulse();
			break;
		case BOT_CMD_BARRIER:
			status = bot_cmd_barrier();
			break;
		case BOT_CMD_CONSOLE:
			localcmd(strcat(bot_cmd.bot_cmd_parm_string, "\n"));
			status = CMD_STATUS_FINISHED;
			break;
		case BOT_CMD_SOUND:
			status = bot_cmd_sound();
			break;
		case BOT_CMD_DEBUG_ASSERT_CANFIRE:
			status = bot_cmd_debug_assert_canfire();
			break;
		default:
			LOG_INFO(strcat("ERROR: Invalid command on queue with id '",ftos(bot_cmd.bot_cmd_type),"'\n"));
			return 0;
	}

	if (status==CMD_STATUS_ERROR)
		LOG_INFO(strcat("ERROR: The command '",bot_cmd_string[bot_cmd.bot_cmd_type],"' returned an error status\n"));

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
			clientcommand(self,strcat("say ^7", bot_cmd_string[bot_cmd.bot_cmd_type]," ",parms,"\n"));
		}

		bot_command_executed(true);
	}

	if(status == CMD_STATUS_FINISHED)
		return -1;

	return CMD_STATUS_ERROR;
}

// This function should be (the only) called directly from the bot ai loop
float bot_execute_commands()
{
	float f;
	do
	{
		f = bot_execute_commands_once();
	}
	while(f < 0);
	return f;
}
