float tooltipdb;
void loadTooltips()
{
	tooltipdb = db_load("tooltips.db");
}
void unloadTooltips()
{
	db_close(tooltipdb);
	tooltipdb = -1;
}
string getZonedTooltipForIdentifier(string s)
{
	string t;
	if(s == "")
		return string_null;
	t = db_get(tooltipdb, s);
	if(t == "-")
		return string_null;
	if(t != "")
		return strzone(t);
	t = cvar_description(s);
	if(t != "" && t != "custom cvar")
		return strzone(t);
	dprint("WARNING: no tooltip set for ", s, "\n");
	return string_null;
}

void forAllDescendants(entity root, void(entity, entity) funcPre, void(entity, entity) funcPost, entity pass)
{
	depthfirst(root, parent, firstChild, nextSibling, funcPre, funcPost, pass);
}

.string cvarName;
void SUB_Null_ee(entity e1, entity e2)
{
}
void saveCvarsOf(entity ignore, entity e)
{
	if(e.saveCvars)
		e.saveCvars(e);
}
void loadCvarsOf(entity ignore, entity e)
{
	if(e.loadCvars)
		e.loadCvars(e);
}
void saveAllCvars(entity root)
{
	forAllDescendants(root, saveCvarsOf, SUB_Null_ee, NULL);
}
void loadAllCvars(entity root)
{
	forAllDescendants(root, loadCvarsOf, SUB_Null_ee, NULL);
}

.string cvarNames_Multi;
.void(entity me) saveCvars_Multi;
void saveCvarsMulti(entity me)
{
	float n, i;
	string s;

	me.saveCvars_Multi(me);
	s = cvar_string(me.cvarName);

	n = tokenize_console(me.cvarNames_Multi);
	for(i = 0; i < n; ++i)
		cvar_set(argv(i), s);
}
void makeMulti(entity e, string otherCvars)
{
	e.cvarNames_Multi = otherCvars;
	e.saveCvars_Multi = e.saveCvars;
	e.saveCvars = saveCvarsMulti;
}

.void(entity me) saveCvars_Callback;
.entity saveCvars_Callback_ent;
.void(entity me, entity cb) saveCvars_Callback_func;
void saveCvarsCallback(entity me)
{
	me.saveCvars_Callback(me);
	me.saveCvars_Callback_func(me.saveCvars_Callback_ent, me);
}
void makeCallback(entity e, entity cbent, void(entity, entity) cbfunc)
{
	e.saveCvars_Callback = e.saveCvars;
	e.saveCvars = saveCvarsCallback;
	e.saveCvars_Callback_ent = cbent;
	e.saveCvars_Callback_func = cbfunc;
}

.void(entity) draw_setDependent;
.string cvar_setDependent;
.float cvarMin_setDependent;
.float cvarMax_setDependent;
.string cvar2_setDependent;
.float cvar2Min_setDependent;
.float cvar2Max_setDependent;
.string cvar3_setDependent;
.float cvar3Min_setDependent;
.float cvar3Max_setDependent;
.float op_setDependent;
.string cvarString_setDependent;
.string cvarValue_setDependent;
.float(entity) func_setDependent;
void setDependent_Check(entity e)
{
	float f;
	string s;
	if(e.func_setDependent)
	{
		e.disabled = !(e.func_setDependent(e));
	}
	else if(e.cvarString_setDependent)
	{
		s = cvar_string(e.cvarString_setDependent);
		e.disabled = (cvar_string(e.cvarString_setDependent) == e.cvarValue_setDependent);
	}
	else
	{
		if(e.cvar_setDependent)
		{
			f = cvar(e.cvar_setDependent);
			if(e.cvarMin_setDependent <= e.cvarMax_setDependent)
				e.disabled = ((f < e.cvarMin_setDependent) || (f > e.cvarMax_setDependent));
			else
				e.disabled = ((f >= e.cvarMax_setDependent) && (f <= e.cvarMin_setDependent));
		}
		if(e.cvar2_setDependent)
		{
			f = cvar(e.cvar2_setDependent);
			if(e.cvar2Min_setDependent <= e.cvar2Max_setDependent)
				e.disabled = (e.disabled + ((f < e.cvar2Min_setDependent) || (f > e.cvar2Max_setDependent)) > e.op_setDependent);
			else
				e.disabled = (e.disabled + ((f >= e.cvar2Max_setDependent) && (f <= e.cvar2Min_setDependent)) > e.op_setDependent);
		}
		if(e.cvar3_setDependent)
		{
			f = cvar(e.cvar3_setDependent);
			if(e.cvar3Min_setDependent <= e.cvar3Max_setDependent)
				e.disabled = (e.disabled + ((f < e.cvar3Min_setDependent) || (f > e.cvar3Max_setDependent)) > e.op_setDependent);
			else
				e.disabled = (e.disabled + ((f >= e.cvar3Max_setDependent) && (f <= e.cvar3Min_setDependent)) > e.op_setDependent);
		}
	}
}
void setDependent_Draw(entity e)
{
	setDependent_Check(e);
	e.draw_setDependent(e);
}
void setDependent(entity e, string theCvarName, float theCvarMin, float theCvarMax)
{
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = string_null;
	e.cvar3_setDependent = string_null;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentStringNotEqual(entity e, string theCvarName, string theCvarValue)
{
	e.draw_setDependent = e.draw;
	e.cvarString_setDependent = theCvarName;
	e.cvarValue_setDependent = theCvarValue;
	e.cvar_setDependent = string_null;
	e.cvar2_setDependent = string_null;
	e.cvar3_setDependent = string_null;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentAND(entity e, string theCvarName, float theCvarMin, float theCvarMax, string theCvar2Name, float theCvar2Min, float theCvar2Max)
{
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = theCvar2Name;
	e.cvar2Min_setDependent = theCvar2Min;
	e.cvar2Max_setDependent = theCvar2Max;
	e.cvar3_setDependent = string_null;
	e.op_setDependent = 0;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentOR(entity e, string theCvarName, float theCvarMin, float theCvarMax, string theCvar2Name, float theCvar2Min, float theCvar2Max)
{
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = theCvar2Name;
	e.cvar2Min_setDependent = theCvar2Min;
	e.cvar2Max_setDependent = theCvar2Max;
	e.cvar3_setDependent = string_null;
	e.op_setDependent = 1;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentAND3(entity e, string theCvarName, float theCvarMin, float theCvarMax, string theCvar2Name, float theCvar2Min, float theCvar2Max, string theCvar3Name, float theCvar3Min, float theCvar3Max)
{
	e.draw_setDependent = e.draw;
	e.cvar_setDependent = theCvarName;
	e.cvarMin_setDependent = theCvarMin;
	e.cvarMax_setDependent = theCvarMax;
	e.cvar2_setDependent = theCvar2Name;
	e.cvar2Min_setDependent = theCvar2Min;
	e.cvar2Max_setDependent = theCvar2Max;
	e.cvar3_setDependent = theCvar3Name;
	e.cvar3Min_setDependent = theCvar3Min;
	e.cvar3Max_setDependent = theCvar3Max;
	e.op_setDependent = 0;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentWeird(entity e, float(entity) func)
{
	e.draw_setDependent = e.draw;
	e.func_setDependent = func;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}

// URI SYSTEM ////////////////////////////////////////////////////////

float _Nex_ExtResponseSystem_Queried;
string _Nex_ExtResponseSystem_UpdateTo;

void URI_Get_Callback(float id, float status, string data)
{
	if (id == URI_GET_DISCARD)
	{
		// discard
	}
	else if(id == URI_GET_UPDATENOTIFICATION)
	{
		UpdateNotification_URI_Get_Callback(id, status, data);
	}
	else if(id >= URI_GET_CURL && id <= URI_GET_CURL_END)
	{
		Curl_URI_Get_Callback(id, status, data);
	}
	else
	{
		print("Received HTTP request data for an invalid id ", ftos(id), ".\n");
	}
}

void UpdateNotification_URI_Get_Callback(float id, float status, string data)
{
	float n;

	if(_Nex_ExtResponseSystem_UpdateTo)
	{
		print("error: UpdateNotification_URI_Get_Callback has been called before\n");
		return;
	}
	if(status != 0)
	{
		print(sprintf("error receiving update notification: status is %d\n", status));
		return;
	}
	if(substring(data, 0, 1) == "<")
	{
		print("error: received HTML instead of an update notification\n");
		return;
	}
	if(strstrofs(data, "\r", 0) != -1)
	{
		print("error: received carriage returns from update notification server\n");
		return;
	}

	if(data == "")
		n = 0;
	else
		n = tokenizebyseparator(data, "\n");
	
	if(n >= 1)
	{
		_Nex_ExtResponseSystem_UpdateTo = argv(0);

		if(vercmp(cvar_string("g_xonoticversion"), _Nex_ExtResponseSystem_UpdateTo) >= 0)
		{
			_Nex_ExtResponseSystem_UpdateTo = ""; // no update needed
		}
		else
		{
			// update needed
			if(n >= 2)
				print(sprintf("Update can be downloaded at:\n%s\n", argv(1)));
		}

		_Nex_ExtResponseSystem_UpdateTo = strzone(_Nex_ExtResponseSystem_UpdateTo);
	}
}

// END OF URI SYSTEM ////////////////////////////////////////////////////////

float preMenuInit()
{
	vector sz;
	vector boxA, boxB;

	MapInfo_Cache_Create();
	MapInfo_Enumerate();
	if(!MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 0, 1))
	{
		draw_reset_cropped();

		sz = eX * 0.025 + eY * 0.025 * (draw_scale_x / draw_scale_y);
		draw_CenterText('0.5 0.5 0' - 1.25 * sz_y * eY, "Autogenerating mapinfo for newly added maps...", sz, '1 1 1', 1, 0);

		boxA = '0.05 0.5 0' + 0.25 * sz_y * eY;
		boxB = '0.95 0.5 0' + 1.25 * sz_y * eY;
		draw_Fill(boxA, boxB - boxA, '1 1 1', 1);
		
		boxA += sz * 0.1;
		boxB -= sz * 0.1;
		draw_Fill(boxA, boxB - boxA, '0.1 0.1 0.1', 1);

		boxB_x = boxA_x * (1 - MapInfo_progress) + boxB_x * MapInfo_progress;
		draw_Fill(boxA, boxB - boxA, '0 0 1', 1);

		return FALSE;
	}
	return TRUE;
}

string campaign_name_previous;
float campaign_won_previous;
#ifdef WATERMARK
var string autocvar_menu_watermark = WATERMARK();
#else
var string autocvar_menu_watermark = "";
#endif
void postMenuDraw()
{
	if(autocvar_menu_watermark != "")
	{
		vector fs = '48 48 0';
		draw_CenterText('0.5 0.1 0', autocvar_menu_watermark, globalToBoxSize('32 32 0', draw_scale), '1 1 1', 0.05, 1);
	}
}
void preMenuDraw()
{
	vector fs, sz, line, mid;

	if(cvar("menu_updatecheck"))
	{
		if(!_Nex_ExtResponseSystem_Queried)
		{
			_Nex_ExtResponseSystem_Queried = 1;
			uri_get(sprintf("http://www.xonotic.org/dl/checkupdate.txt?version=%s", uri_escape(cvar_string("g_xonoticversion"))), URI_GET_UPDATENOTIFICATION);
		}
	}

	if(_Nex_ExtResponseSystem_UpdateTo != "")
	{
		// TODO rather turn this into a dialog
		fs = ((1/draw_scale_x) * eX + (1/draw_scale_y) * eY) * 12;
		line = eY * fs_y;
		sz_x = draw_TextWidth("  http://www.xonotic.com/  ", 0, fs);
		sz_y = 3 * fs_y;

		draw_alpha = sin(time * 0.112 - 0.3) * 10;
		mid = eX * (0.5 + 0.5 * (1 - sz_x) * cos(time * 0.071))
		    + eY * (0.5 + 0.5 * (1 - sz_y) * sin(time * 0.071));

		draw_Fill(mid - 0.5 * sz, sz, '1 1 0', 1);
		draw_CenterText(mid - 1 * line, strcat("Update to ", _Nex_ExtResponseSystem_UpdateTo, " now!"), fs, '1 0 0', 1, 0);
		draw_CenterText(mid - 0 * line, "http://www.xonotic.org/", fs, '0 0 1', 1, 0);
	}
	if not(campaign_name_previous)
		campaign_name_previous = strzone(strcat(campaign_name, "x")); // force unequal
	if(campaign_name == campaign_name_previous)
	{
		if(cvar(strcat("g_campaign", campaign_name, "_won")))
		{
			if(!campaign_won_previous)
			{
				m_display();
				DialogOpenButton_Click_withCoords(NULL, main.winnerDialog, '0 0 0', eX * conwidth + eY * conheight);
			}
			campaign_won_previous = 1;
		}
		else
			campaign_won_previous = 0;
	}
	else
	{
		strunzone(campaign_name_previous);
		campaign_name_previous = strzone(campaign_name);
		campaign_won_previous = cvar(strcat("g_campaign", campaign_name, "_won"));
	}
}

string resolvemod(string m)
{
	if(m == "=")
		return getcurrentmod();
	else
		return m;
}

string HUD_Panel_GetSettingName(float theSetting)
{
	switch(theSetting) {
		case HUD_MENU_ENABLE: return ""; break;
		default: return "";
	}
}
