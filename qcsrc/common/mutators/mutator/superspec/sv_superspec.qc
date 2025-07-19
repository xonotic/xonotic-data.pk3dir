#include "sv_superspec.qh"

string autocvar_g_superspectate;
REGISTER_MUTATOR(superspec, expr_evaluate(autocvar_g_superspectate));

#define _SSMAGIX "SUPERSPEC_OPTIONSFILE_V1"
#define _ISLOCAL(ent) ((edict_num(1) == (ent)) ? true : false)

const int ASF_STRENGTH      = BIT(0);
const int ASF_SHIELD        = BIT(1);
const int ASF_MEGA_AR       = BIT(2);
const int ASF_MEGA_HP       = BIT(3);
const int ASF_FLAG_GRAB     = BIT(4);
const int ASF_OBSERVER_ONLY = BIT(5);
const int ASF_SHOWWHAT      = BIT(6);
const int ASF_SSIM          = BIT(7);
const int ASF_FOLLOWKILLER  = BIT(8);
const int ASF_ALL           = 0xFFFFFF;
.int autospec_flags;

const int SSF_SILENT  = BIT(0);
const int SSF_VERBOSE = BIT(1);
const int SSF_ITEMMSG = BIT(2);
.int superspec_flags;

.string superspec_itemfilter; //"classname1 classname2 ..."

bool superspec_Spectate(entity this, entity targ)
{
	Spectate(this, targ);
	return true;
}

void superspec_save_client_conf(entity this)
{
	string fn = "superspec-local.options";
	float fh;

	if (!_ISLOCAL(this))
	{
		if(this.crypto_idfp == "")
			return;

		fn = sprintf("superspec-%s.options", uri_escape(this.crypto_idfp));
	}

	fh = fopen(fn, FILE_WRITE);
	if(fh < 0)
	{
		LOG_TRACE("^1ERROR: ^7 superspec can not open ", fn, " for writing.");
	}
	else
	{
		fputs(fh, _SSMAGIX);
		fputs(fh, "\n");
		fputs(fh, itos(this.autospec_flags));
		fputs(fh, "\n");
		fputs(fh, itos(this.superspec_flags));
		fputs(fh, "\n");
		fputs(fh, this.superspec_itemfilter);
		fputs(fh, "\n");
		fclose(fh);
	}
}

void superspec_msg(string _center_title, string _con_title, entity _to, string _msg, float _spamlevel)
{
	sprint(_to, strcat(_con_title, _msg));

	if(_to.superspec_flags & SSF_SILENT)
		return;

	if(_spamlevel > 1)
		if (!(_to.superspec_flags & SSF_VERBOSE))
			return;

	centerprint(_to, strcat(_center_title, _msg));
}

float superspec_filteritem(entity _for, entity _item)
{
	float i;

	if(_for.superspec_itemfilter == "")
		return true;

	if(_for.superspec_itemfilter == "")
		return true;

	float l = tokenize_console(_for.superspec_itemfilter);
	for(i = 0; i < l; ++i)
	{
		if(argv(i) == _item.classname)
			return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(superspec, ItemTouch)
{
	entity item = M_ARGV(0, entity);
	entity toucher = M_ARGV(1, entity);

	FOREACH_CLIENT(true, {
		if(!IS_SPEC(it) && !IS_OBSERVER(it))
			continue;
		if(it.superspec_flags & SSF_ITEMMSG)
			if(superspec_filteritem(it, item))
			{
				if(it.superspec_flags & SSF_VERBOSE)
					superspec_msg("", "", it, sprintf("Player %s^7 just picked up ^3%s\n", toucher.netname, item.netname), 1);
				else
					superspec_msg("", "", it, sprintf("Player %s^7 just picked up ^3%s\n^8(%s^8)\n", toucher.netname, item.netname, item.classname), 1);
				if((it.autospec_flags & ASF_SSIM) && it.enemy != toucher)
				{
					superspec_Spectate(it, toucher);
					return MUT_ITEMTOUCH_CONTINUE;
				}
			}

		if(((it.autospec_flags & ASF_SHIELD) && item.invincible_finished) ||
			((it.autospec_flags & ASF_STRENGTH) && item.strength_finished) ||
			((it.autospec_flags & ASF_MEGA_AR) && item.itemdef == ITEM_ArmorMega) ||
			((it.autospec_flags & ASF_MEGA_HP) && item.itemdef == ITEM_HealthMega) ||
			((it.autospec_flags & ASF_FLAG_GRAB) && item.classname == "item_flag_team"))
		{

			if((it.enemy != toucher) || IS_OBSERVER(it))
			{
				if((it.autospec_flags & ASF_OBSERVER_ONLY) && !IS_OBSERVER(it))
				{
					if(it.superspec_flags & SSF_VERBOSE)
						superspec_msg("", "", it, sprintf("^8Ignored that ^7%s^8 grabbed %s^8 since the observer_only option is ON\n", toucher.netname, item.netname), 2);
				}
				else
				{
					if(it.autospec_flags & ASF_SHOWWHAT)
						superspec_msg("", "", it, sprintf("^7Following %s^7 due to picking up %s\n", toucher.netname, item.netname), 2);

					superspec_Spectate(it, toucher);
				}
			}
		}
	});

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(superspec, SV_ParseClientCommand)
{
#define OPTIONINFO(flag,var,test,text,long,short) \
    var = strcat(var, ((flag & test) ? "^2[ON]  ^7" : "^1[OFF] ^7")); \
    var = strcat(var, text," ^7(^3 ", long, "^7 | ^3", short, " ^7)\n")

	if(MUTATOR_RETURNVALUE) // command was already handled?
		return;

	entity player = M_ARGV(0, entity);
	string cmd_name = M_ARGV(1, string);
	int cmd_argc = M_ARGV(2, int);

	if(IS_PLAYER(player))
		return;

	if(cmd_name == "superspec_itemfilter")
	{
		if(argv(1) == "help")
		{
			string _aspeco;
			_aspeco = "^7 superspec_itemfilter ^3\"item_classname1 item_classname2\"^7 only show thise items when ^2superspec ^3item_message^7 is on\n";
			_aspeco = strcat(_aspeco, "^3 clear^7 Remove the filter (show all pickups)\n");
			_aspeco = strcat(_aspeco, "^3 show ^7 Display current filter\n");
			superspec_msg("^3superspec_itemfilter help:\n\n\n", "\n^3superspec_itemfilter help:\n", player, _aspeco, 1);
		}
		else if(argv(1) == "clear")
		{
			if(player.superspec_itemfilter != "")
				strunzone(player.superspec_itemfilter);

			player.superspec_itemfilter = "";
		}
		else if(argv(1) == "show" || argv(1) == "")
		{
			if(player.superspec_itemfilter == "")
			{
				superspec_msg("^3superspec_itemfilter^7 is ^1not^7 set", "\n^3superspec_itemfilter^7 is ^1not^7 set\n", player, "", 1);
				return true;
			}
			float i;
			float l = tokenize_console(player.superspec_itemfilter);
			string _msg = "";
			for(i = 0; i < l; ++i)
				_msg = strcat(_msg, "^3#", ftos(i), " ^7", argv(i), "\n");
				//_msg = sprintf("^3#%d^7 %s\n%s", i, _msg, argv(i));

			_msg = strcat(_msg,"\n");

			superspec_msg("^3superspec_itemfilter is:\n\n\n", "\n^3superspec_itemfilter is:\n", player, _msg, 1);
		}
		else
		{
			if(player.superspec_itemfilter != "")
				strunzone(player.superspec_itemfilter);

			player.superspec_itemfilter = strzone(argv(1));
		}

		return true;
	}

	if(cmd_name == "superspec")
	{
		string _aspeco;

		if(cmd_argc > 1)
		{
			float i, _bits = 0, _start = 1;
			if(argv(1) == "help")
			{
				_aspeco = "use cmd superspec [option] [on|off] to set options\n\n";
				_aspeco = strcat(_aspeco, "^3 silent ^7(short^5 si^7) supresses ALL messages from superspectate.\n");
				_aspeco = strcat(_aspeco, "^3 verbose ^7(short^5 ve^7) makes superspectate print some additional information.\n");
				_aspeco = strcat(_aspeco, "^3 item_message ^7(short^5 im^7) makes superspectate print items that were picked up.\n");
				_aspeco = strcat(_aspeco, "^7    Use cmd superspec_itemfilter \"item_class1 item_class2\" to set up a filter of what to show with ^3item_message.\n");
				superspec_msg("^2Available Super Spectate ^3options:\n\n\n", "\n^2Available Super Spectate ^3options:\n", player, _aspeco, 1);
				return true;
			}

			if(argv(1) == "clear")
			{
				player.superspec_flags = 0;
				_start = 2;
			}

			for(i = _start; i < cmd_argc; ++i)
			{
				if(argv(i) == "on" || argv(i) == "1")
				{
					player.superspec_flags |= _bits;
					_bits = 0;
				}
				else if(argv(i) == "off" || argv(i) == "0")
				{
					if(_start == 1)
						player.superspec_flags &= ~_bits;

					_bits = 0;
				}
				else
				{
					if((argv(i) == "silent") || (argv(i) == "si")) _bits |= SSF_SILENT ;
					if((argv(i) == "verbose") || (argv(i) == "ve")) _bits |= SSF_VERBOSE;
					if((argv(i) == "item_message") || (argv(i) == "im")) _bits |= SSF_ITEMMSG;
				}
			}
		}

		_aspeco = "";
		OPTIONINFO(player.superspec_flags, _aspeco, SSF_SILENT, "Silent", "silent", "si");
		OPTIONINFO(player.superspec_flags, _aspeco, SSF_VERBOSE, "Verbose", "verbose", "ve");
		OPTIONINFO(player.superspec_flags, _aspeco, SSF_ITEMMSG, "Item pickup messages", "item_message", "im");

		superspec_msg("^3Current Super Spectate options are:\n\n\n\n\n", "\n^3Current Super Spectate options are:\n", player, _aspeco, 1);

		return true;
	}

/////////////////////

	if(cmd_name == "autospec")
	{
		string _aspeco;
		if(cmd_argc > 1)
		{
			if(argv(1) == "help")
			{
				_aspeco = "use cmd autospec [option] [on|off] to set options\n\n";
				_aspeco = strcat(_aspeco, "^3 strength ^7(short^5 st^7) for automatic spectate on strength powerup\n");
				_aspeco = strcat(_aspeco, "^3 shield ^7(short^5 sh^7) for automatic spectate on shield powerup\n");
				_aspeco = strcat(_aspeco, "^3 mega_health ^7(short^5 mh^7) for automatic spectate on mega health\n");
				_aspeco = strcat(_aspeco, "^3 mega_armor ^7(short^5 ma^7) for automatic spectate on mega armor\n");
				_aspeco = strcat(_aspeco, "^3 flag_grab ^7(short^5 fg^7) for automatic spectate on CTF flag grab\n");
				_aspeco = strcat(_aspeco, "^3 observer_only ^7(short^5 oo^7) for automatic spectate only if in observer mode\n");
				_aspeco = strcat(_aspeco, "^3 show_what ^7(short^5 sw^7) to display what event triggered autospectate\n");
				_aspeco = strcat(_aspeco, "^3 item_msg ^7(short^5 im^7) to autospec when item_message in superspectate is triggered\n");
				_aspeco = strcat(_aspeco, "^3 followkiller ^7(short ^5fk^7) to autospec the killer/off\n");
				_aspeco = strcat(_aspeco, "^3 all ^7(short ^5aa^7) to turn everything on/off\n");
				superspec_msg("^2Available Auto Spectate ^3options:\n\n\n", "\n^2Available Auto Spectate ^3options:\n", player, _aspeco, 1);
				return true;
			}

			float i, _bits = 0, _start = 1;
			if(argv(1) == "clear")
			{
				player.autospec_flags = 0;
				_start = 2;
			}

			for(i = _start; i < cmd_argc; ++i)
			{
				if(argv(i) == "on" || argv(i) == "1")
				{
					player.autospec_flags |= _bits;
					_bits = 0;
				}
				else if(argv(i) == "off" || argv(i) == "0")
				{
					if(_start == 1)
						player.autospec_flags &= ~_bits;

					_bits = 0;
				}
				else
				{
					if((argv(i) == "strength") || (argv(i) == "st")) _bits |= ASF_STRENGTH;
					if((argv(i) == "shield") || (argv(i) == "sh")) _bits |= ASF_SHIELD;
					if((argv(i) == "mega_health") || (argv(i) == "mh")) _bits |= ASF_MEGA_HP;
					if((argv(i) == "mega_armor") || (argv(i) == "ma")) _bits |= ASF_MEGA_AR;
					if((argv(i) == "flag_grab") || (argv(i) == "fg")) _bits |= ASF_FLAG_GRAB;
					if((argv(i) == "observer_only") || (argv(i) == "oo")) _bits |= ASF_OBSERVER_ONLY;
					if((argv(i) == "show_what") || (argv(i) == "sw")) _bits |= ASF_SHOWWHAT;
					if((argv(i) == "item_msg") || (argv(i) == "im")) _bits |= ASF_SSIM;
					if((argv(i) == "followkiller") || (argv(i) == "fk")) _bits |= ASF_FOLLOWKILLER;
					if((argv(i) == "all") || (argv(i) == "aa")) _bits |= ASF_ALL;
				}
			}
		}

		_aspeco = "";
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_STRENGTH, "Strength", "strength", "st");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_SHIELD, "Shield", "shield", "sh");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_MEGA_HP, "Mega Health", "mega_health", "mh");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_MEGA_AR, "Mega Armor", "mega_armor", "ma");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_FLAG_GRAB, "Flag grab", "flag_grab","fg");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_OBSERVER_ONLY, "Only switch if observer", "observer_only", "oo");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_SHOWWHAT, "Show what item triggered spectate", "show_what", "sw");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_SSIM, "Switch on superspec item message", "item_msg", "im");
		OPTIONINFO(player.autospec_flags, _aspeco, ASF_FOLLOWKILLER, "Followkiller", "followkiller", "fk");

		superspec_msg("^3Current auto spectate options are:\n\n\n\n\n", "\n^3Current auto spectate options are:\n", player, _aspeco, 1);
		return true;
	}

	if(cmd_name == "followpowerup")
	{
		// TODO: somehow cheaply loop through all held powerups
		FOREACH_CLIENT(IS_PLAYER(it) && (StatusEffects_active(STATUSEFFECT_Strength, it) || StatusEffects_active(STATUSEFFECT_Shield, it)), { return superspec_Spectate(player, it); });

		superspec_msg("", "", player, "No active powerup\n", 1);
		return true;
	}

	if(cmd_name == "followstrength")
	{
		FOREACH_CLIENT(IS_PLAYER(it) && StatusEffects_active(STATUSEFFECT_Strength, it), { return superspec_Spectate(player, it); });

		superspec_msg("", "", player, "No active Strength\n", 1);
		return true;
	}

	if(cmd_name == "followshield")
	{
		FOREACH_CLIENT(IS_PLAYER(it) && StatusEffects_active(STATUSEFFECT_Shield, it), { return superspec_Spectate(player, it); });

		superspec_msg("", "", player, "No active Shield\n", 1);
		return true;
	}
#undef OPTIONINFO
}

MUTATOR_HOOKFUNCTION(superspec, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":SS");
}

MUTATOR_HOOKFUNCTION(superspec, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Super Spectators");
}

void superspec_hello(entity this)
{
	if(this.enemy.crypto_idfp == "")
		Send_Notification(NOTIF_ONE_ONLY, this.enemy, MSG_INFO, INFO_SUPERSPEC_MISSING_UID);

	delete(this);
}

MUTATOR_HOOKFUNCTION(superspec, ClientConnect)
{
	entity player = M_ARGV(0, entity);

	if(!IS_REAL_CLIENT(player))
		return;

	string fn = "superspec-local.options";
	float fh;

	player.superspec_flags = SSF_VERBOSE;
	player.superspec_itemfilter = "";

	entity _hello = new_pure(superspec_delayed_hello);
	_hello.enemy = player;
	setthink(_hello, superspec_hello);
	_hello.nextthink = time + 5;

	if (!_ISLOCAL(player))
	{
		if(player.crypto_idfp == "")
			return;

		fn = sprintf("superspec-%s.options", uri_escape(player.crypto_idfp));
	}

	fh = fopen(fn, FILE_READ);
	if(fh < 0)
	{
		LOG_TRACE("^1ERROR: ^7 superspec can not open ", fn, " for reading.");
	}
	else
	{
		string _magic = fgets(fh);
		if(_magic != _SSMAGIX)
		{
			LOG_TRACE("^1ERROR^7 While reading superspec options file: unknown magic");
		}
		else
		{
			player.autospec_flags = stoi(fgets(fh));
			player.superspec_flags = stoi(fgets(fh));
			player.superspec_itemfilter = strzone(fgets(fh));
		}
		fclose(fh);
	}
}

MUTATOR_HOOKFUNCTION(superspec, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	FOREACH_CLIENT(IS_SPEC(it), {
		if((it.autospec_flags & ASF_FOLLOWKILLER) && IS_PLAYER(frag_attacker) && it.enemy == frag_target)
		{
			if(it.autospec_flags & ASF_SHOWWHAT)
				superspec_msg("", "", it, sprintf("^7Following %s^7 due to followkiller\n", frag_attacker.netname), 2);

			superspec_Spectate(it, frag_attacker);
		}
	});
}

MUTATOR_HOOKFUNCTION(superspec, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	superspec_save_client_conf(player);
}
