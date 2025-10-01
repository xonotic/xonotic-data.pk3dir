#include "util.qh"
#include "dialog.qh"
#include "textslider.qh"

#include "../item.qh"

#include "../menu.qh"
#include <common/campaign_common.qh>
#include <common/constants.qh>
#include <common/gametypes/_mod.qh>
#include <common/util.qh>
#include <common/command/_mod.qh>
#include <menu/xonotic/gametypelist.qh>

float GL_CheckExtension(string ext)
{
	return strhasword(cvar_string("gl_info_extensions"), ext);
}

float GL_Have_TextureCompression()
{
	return GL_CheckExtension("GL_EXT_texture_compression_s3tc");
}

.entity parent, firstChild, nextSibling;
void forAllDescendants(entity root, void(entity, entity) funcPre, void(entity, entity) funcPost, entity pass)
{
	depthfirst(root, parent, firstChild, nextSibling, funcPre, funcPost, pass);
}

.string controlledCvar;
void SUB_Null_ee(entity e1, entity e2)
{
}

.void(entity) saveCvars;
void saveCvarsOf(entity ignore, entity e)
{
	if(e.saveCvars)
		e.saveCvars(e);
}

.void(entity) loadCvars;
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

.string controlledCvars_Multi;
.void(entity me) saveCvars_Multi;
string getCvarsMulti(entity me)
{
	if (me.controlledCvars_Multi)
		return me.controlledCvars_Multi;
	return string_null;
}
void saveCvarsMulti(entity me)
{
	float n, i;
	string s, cvarname;

	me.saveCvars_Multi(me);
	s = cvar_string(me.controlledCvar);

	n = tokenize_console(me.controlledCvars_Multi);
	for(i = 0; i < n; ++i)
	{
		// cvars prefixed with ! get saved with the inverted value
		if(substring(argv(i), 0, 1) == "!")
		{
			cvarname = substring(argv(i), 1, strlen(argv(i)));
			cvar_set(cvarname, ((s == "0") ? "1" : "0"));
		}
		else
		{
			cvarname = argv(i);
			cvar_set(cvarname, s);
		}

		CheckSendCvars(me, cvarname);
	}
}
void makeMulti(entity e, string otherCvars)
{
	e.controlledCvars_Multi = otherCvars;
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

/* So far this allows for:
 * A
 * A AND B
 * A AND B AND C
 * A OR B
 * A OR B OR C
 * Same but with (NOT A) instead of A
 * A can be range, function, string exactly equal
 * Must call setDependent/setDependentNOT/setDependentStringNotEqual first,
 * ... then setDependentAND/setDependentOR after
 */
.void(entity) draw_setDependent;
void setDependent_Check(entity e)
{
	bool disabled_prev = e.disabled;
	float f;
	string s;
	if (e.func_setDependent)
	{
		e.disabled = !(e.func_setDependent(e));
	}
	else if (e.cvarString_setDependent)
	{
		s = cvar_string(e.cvarString_setDependent);
		e.disabled = (cvar_string(e.cvarString_setDependent) == e.cvarValue_setDependent);
	}
	else if (e.cvar1_setDependent)
	{
		f = cvar(e.cvar1_setDependent);
		if (e.op_setDependent & BIT(1)) // NOT
			e.disabled = (f == e.cvar1Min_setDependent);
		else
		{
			if (e.cvar1Min_setDependent <= e.cvar1Max_setDependent)
				e.disabled = ((f < e.cvar1Min_setDependent) || (f > e.cvar1Max_setDependent));
			else
				e.disabled = ((f >= e.cvar1Max_setDependent) && (f <= e.cvar1Min_setDependent));
		}
	}
	int op = e.op_setDependent & BIT(0);
	if (e.cvar2_setDependent)
	{
		f = cvar(e.cvar2_setDependent);
		if (e.cvar2Min_setDependent <= e.cvar2Max_setDependent)
			e.disabled = (e.disabled + ((f < e.cvar2Min_setDependent) || (f > e.cvar2Max_setDependent)) > op);
		else
			e.disabled = (e.disabled + ((f >= e.cvar2Max_setDependent) && (f <= e.cvar2Min_setDependent)) > op);
	}
	if (e.cvar3_setDependent)
	{
		f = cvar(e.cvar3_setDependent);
		if (e.cvar3Min_setDependent <= e.cvar3Max_setDependent)
			e.disabled = (e.disabled + ((f < e.cvar3Min_setDependent) || (f > e.cvar3Max_setDependent)) > op);
		else
			e.disabled = (e.disabled + ((f >= e.cvar3Max_setDependent) && (f <= e.cvar3Min_setDependent)) > op);
	}
	if (disabled_prev != e.disabled && e.loadCvars)
		e.loadCvars(e);
}
void setDependent_Draw(entity e)
{
	setDependent_Check(e);
	e.draw_setDependent(e);
}
.void(entity) draw;
void setDependent(entity e, string theCvarName, float theCvarMin, float theCvarMax)
{
	e.draw_setDependent = e.draw;
	e.cvar1_setDependent = theCvarName;
	e.cvar1Min_setDependent = theCvarMin;
	e.cvar1Max_setDependent = theCvarMax;
	e.op_setDependent = 0;
	e.cvarString_setDependent = string_null;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentNOT(entity e, string theCvarName, float theCvarValue)
{
	e.draw_setDependent = e.draw;
	e.cvar1_setDependent = theCvarName;
	e.cvar1Min_setDependent = theCvarValue;
	e.cvar1Max_setDependent = theCvarValue;
	e.op_setDependent |= BIT(1); // NOT
	e.cvarString_setDependent = string_null;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentStringNotEqual(entity e, string theCvarName, string theCvarValue)
{
	e.draw_setDependent = e.draw;
	e.cvarString_setDependent = theCvarName;
	e.cvarValue_setDependent = theCvarValue;
	e.func_setDependent = func_null;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}
void setDependentAND(entity e, string theCvarName, float theCvarMin, float theCvarMax)
{
	if (e.cvar2_setDependent)
	{
		e.cvar3_setDependent = theCvarName;
		e.cvar3Min_setDependent = theCvarMin;
		e.cvar3Max_setDependent = theCvarMax;
	}
	else
	{
		e.cvar2_setDependent = theCvarName;
		e.cvar2Min_setDependent = theCvarMin;
		e.cvar2Max_setDependent = theCvarMax;
	}
	e.op_setDependent &= ~BIT(0); // AND
	e.func_setDependent = func_null;
	setDependent_Check(e);
}
void setDependentOR(entity e, string theCvarName, float theCvarMin, float theCvarMax)
{
	if (e.cvar2_setDependent)
	{
		e.cvar3_setDependent = theCvarName;
		e.cvar3Min_setDependent = theCvarMin;
		e.cvar3Max_setDependent = theCvarMax;
	}
	else
	{
		e.cvar2_setDependent = theCvarName;
		e.cvar2Min_setDependent = theCvarMin;
		e.cvar2Max_setDependent = theCvarMax;
	}
	e.op_setDependent |= BIT(0); // OR
	e.func_setDependent = func_null;
	setDependent_Check(e);
}
void setDependentWeird(entity e, float(entity) func)
{
	e.draw_setDependent = e.draw;
	e.func_setDependent = func;
	e.draw = setDependent_Draw;
	setDependent_Check(e);
}

void setZonedTooltip(entity e, string theTooltip, string theCvar)
{
	if(theTooltip == "") // no tooltip, use cvar description then
	{
		if(theCvar != "" && prvm_language == "en")
		{
			string t = cvar_description(theCvar);
			if(t != "" && t != "custom cvar")
				theTooltip = t;
		}
	}
	else if(theTooltip == "-") // no cvar description as tooltip
	{
		theTooltip = string_null;
	}

	strfree(e.tooltip);
	e.tooltip = (theTooltip != "") ? strzone(theTooltip) : string_null;
}

void clearTooltip(entity e)
{
	setZonedTooltip(e, string_null, string_null);
}

// URI SYSTEM ////////////////////////////////////////////////////////

float _Nex_ExtResponseSystem_Queried;
string _Nex_ExtResponseSystem_UpdateTo;
string _Nex_ExtResponseSystem_UpdateToURL;
string _Nex_ExtResponseSystem_Packs;
float _Nex_ExtResponseSystem_PacksStep;

/** engine callback */
void URI_Get_Callback(float id, float status, string data)
{
	if(url_URI_Get_Callback(id, status, data))
	{
		// handled
	}
	else if (id == URI_GET_DISCARD)
	{
		// discard
	}
	else if (id >= URI_GET_CURL && id <= URI_GET_CURL_END)
	{
		// sv_cmd curl
		Curl_URI_Get_Callback(id, status, data);
	}
	else if (id == URI_GET_UPDATENOTIFICATION)
	{
		UpdateNotification_URI_Get_Callback(id, status, data);
	}
	else
	{
		LOG_INFOF("Received HTTP request data for an invalid id %d.", id);
	}
}

void UpdateNotification_URI_Get_Callback(float id, float status, string data)
{
	float n;

	if(_Nex_ExtResponseSystem_UpdateTo)
	{
		LOG_TRACE("error: UpdateNotification_URI_Get_Callback has been called before");
		return;
	}
	if(status != 0)
	{
		LOG_TRACEF("error receiving update notification: status is %d", status);
		return;
	}
	if(substring(data, 0, 1) == "<")
	{
		LOG_TRACE("error: received HTML instead of an update notification");
		return;
	}
	if(strstrofs(data, "\r", 0) != -1)
	{
		LOG_TRACE("error: received carriage returns from update notification server");
		return;
	}

	if(data == "")
		n = 0;
	else
		n = tokenizebyseparator(data, "\n");

	float i;
	string s;

	string un_version = "";
	string un_tosversion = "";
	string un_download = "";
	string un_url = "";
	string un_bannedservers = "";
	string un_emergency_pk3s = "";
	string un_promoted = "";
	string un_recommended = "";
	string un_compatexpire = "";

	for(i = 0; i < n; ++i)
	{
		s = substring(argv(i), 2, -1);
		if(s == "") { continue; } // ignore empty lines

		switch(substring(argv(i), 0, 1))
		{
			case "V":
			{
				un_version = s;
				break;
			}
			case "T":
			{
				un_tosversion = s;
				break;
			}
			case "C":
			{
				un_compatexpire = s;
				break;
			}
			case "D":
			{
				un_download = s;
				break;
			}
			case "U":
			{
				un_url = s;
				break;
			}
			case "B":
			{
				APPEND_TO_STRING(un_bannedservers, " ", s);
				break;
			}
			case "H":
			{
				// Hotfix (version-specific pk3 supported in >= 0.8.6)
				// replaces "E" (missing-file-specific pk3 supported in <= 0.8.5)
				APPEND_TO_STRING(un_emergency_pk3s, " ", s);
				break;
			}
			case "P":
			{
				APPEND_TO_STRING(un_promoted, " ", s);
				break;
			}
			case "R":
			{
				APPEND_TO_STRING(un_recommended, " ", s);
				break;
			}
		}
	}

	if(un_version != "" && vercmp(cvar_string("g_xonoticversion"), un_version) < 0)
	{
		// update needed
		_Nex_ExtResponseSystem_UpdateTo = strzone(un_version);
		if(un_download) { LOG_INFO(_("Update can be downloaded at:"), "\n", un_download); }
		if(un_url) { _Nex_ExtResponseSystem_UpdateToURL = strzone(un_url); }
	}

	if(un_tosversion != "")
	{
		_Nex_ExtResponseSystem_NewToS = stof(un_tosversion);
	}

	if(un_bannedservers != "")
	{
		_Nex_ExtResponseSystem_BannedServers = strzone(un_bannedservers);
		_Nex_ExtResponseSystem_BannedServersNeedsRefresh = 1;
	}

	if(un_emergency_pk3s != "")
	{
		_Nex_ExtResponseSystem_Packs = strzone(un_emergency_pk3s);
		_Nex_ExtResponseSystem_PacksStep = 1;
	}

	if(un_promoted != "")
	{
		_Nex_ExtResponseSystem_PromotedServers = strzone(un_promoted);
		_Nex_ExtResponseSystem_PromotedServersNeedsRefresh = 1;
	}

	if(un_recommended != "")
	{
		_Nex_ExtResponseSystem_RecommendedServers = strzone(un_recommended);
		_Nex_ExtResponseSystem_RecommendedServersNeedsRefresh = 1;
	}
}

// END OF URI SYSTEM ////////////////////////////////////////////////////////

void updateCheck()
{
	if(!_Nex_ExtResponseSystem_Queried)
	{
		_Nex_ExtResponseSystem_Queried = 1;
		cvar_set("cl_startcount", ftos(cvar("cl_startcount") + 1));
		uri_get("https://update.xonotic.org/checkupdate.txt", URI_GET_UPDATENOTIFICATION);
	}

	if(_Nex_ExtResponseSystem_PacksStep > 0)
	{
		float n, i;
		float allgood;
		n = tokenize_console(_Nex_ExtResponseSystem_Packs);
		allgood = true;
		for(i = 0; i+1 < n; i += 2)
		{
			if(strcmp(argv(i+1), cvar_string("g_xonoticversion"))) // these aren't the versions we're looking for
				continue;
			string packfn = whichpack("hotfix-autoexec.cfg");
			if(packfn) // we have the cfg we're looking for in some pk3
			{
				if(!strncmp(packfn, "dlcache/", 8)) // it's in dlcache
					packfn = substring(packfn, 8, strlen(packfn)); // strip prefix "dlcache/"
				if(strstrofs(argv(i), packfn, strlen(argv(i)) - strlen(packfn)) > 0) // last chars of url == packfn
					continue; // the pk3 we're looking for already provides the cfg we're looking for
			}
			allgood = false;
			if(_Nex_ExtResponseSystem_PacksStep == 1) // first run
				localcmd("\ncurl --pak \"", argv(i), "\"\n");
		}
		if(allgood)
		{
			if(_Nex_ExtResponseSystem_PacksStep == 2)
			{
				if(!Menu_Active)
					cvar_set("_menu_initialized", "0");
					// HACK: cause m_hide call on next start
				//localcmd("\nmenu_restart\n"); // <= 0.8.5
				localcmd("\nexec hotfix-autoexec.cfg\n");
			}
			_Nex_ExtResponseSystem_PacksStep = 0;
		}
		else
			_Nex_ExtResponseSystem_PacksStep = 2;
	}
}

float preMenuInit()
{
	vector sz;
	vector boxA, boxB;

	updateCheck();

	MapInfo_Cache_Create();
	MapInfo_Enumerate();
	if(!_MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 0, 1))
	{
		draw_reset_cropped();

		sz = eX * 0.025 + eY * 0.025 * (draw_scale.x / draw_scale.y);
		draw_CenterText('0.5 0.5 0' - 1.25 * sz.y * eY, _("Autogenerating mapinfo for newly added maps..."), sz, '1 1 1', 1, 0);

		boxA = '0.05 0.5 0' + 0.25 * sz.y * eY;
		boxB = '0.95 0.5 0' + 1.25 * sz.y * eY;
		draw_Fill(boxA, boxB - boxA, '1 1 1', 1);

		boxA += sz * 0.1;
		boxB -= sz * 0.1;
		draw_Fill(boxA, boxB - boxA, '0.1 0.1 0.1', 1);

		boxB_x = boxA_x * (1 - MapInfo_progress) + boxB_x * MapInfo_progress;
		draw_Fill(boxA, boxB - boxA, '0 0 1', 1);

		return false;
	}
	return true;
}

string campaign_name_previous;
float campaign_won_previous;
void postMenuDraw() {}
void DialogOpenButton_Click_withCoords(entity button, entity tab, vector theOrigin, vector theSize);
.entity winnerDialog;
void preMenuDraw()
{
	vector fs, sz = '0 0 0', line, mid;

	updateCheck();

	if(_Nex_ExtResponseSystem_UpdateTo != "" && !(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)))
	{
		// TODO rather turn this into a dialog
		fs = ((1/draw_scale.x) * eX + (1/draw_scale.y) * eY) * 12;
		line = eY * fs.y;
		string l1, l2;
		l1 = sprintf(_("Update to %s now!"), _Nex_ExtResponseSystem_UpdateTo);
		l2 = "https://xonotic.org";
		if(_Nex_ExtResponseSystem_UpdateToURL)
			l2 = _Nex_ExtResponseSystem_UpdateToURL;

		sz_x = draw_TextWidth("    ", 0, fs) + max(
				draw_TextWidth(l1, 0, fs),
				draw_TextWidth(l2, 0, fs)
			);
		sz_y = 3 * fs.y;

		draw_alpha = bound(0, sin(time * 0.112 - 0.3) * 10, 1);
		mid = eX * (0.5 + 0.5 * (1 - sz.x) * cos(time * 0.071))
		    + eY * (0.5 + 0.5 * (1 - sz.y) * sin(time * 0.071));

		draw_Fill(mid - 0.5 * sz, sz, '1 1 0', 1);
		draw_CenterText(mid - 1 * line, l1, fs, '1 0 0', 1, 0);
		draw_CenterText(mid - 0 * line, l2, fs, '0 0 1', 1, 0);
	}

	if (!campaign_name_previous)
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
		strcpy(campaign_name_previous, campaign_name);
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

float updateCompression()
{
	float have_dds, have_jpg, have_tga;
	float can_dds;
	have_dds = (fexists("dds/particles/particlefont.dds"));
	have_jpg = (fexists("particles/particlefont.jpg"));
	have_tga = (fexists("particles/particlefont.tga"));
	can_dds = GL_Have_TextureCompression();
	if(have_dds && (have_jpg || have_tga))
	{
		// both? Let's only use good quality precompressed files
		// but ONLY if we actually support it!
		if(can_dds)
		{
			// these builds are meant to have GOOD quality, so let's not compress non-skinframes
			cvar_set("gl_texturecompression", "0");
			return 1;

			//cvar_set("gl_texturecompression", cvar_string("r_texture_dds_load"));
			//return 2;
		}
		else
		{
			cvar_set("gl_texturecompression", "0");
			cvar_set("r_texture_dds_load", "0");
			return 0;
		}
	}
	else if(have_dds)
	{
		// DDS only? We probably always want texture compression
		cvar_set("gl_texturecompression", "1");
		cvar_set("r_texture_dds_load", "1");
		if(!can_dds)
			LOG_INFO(_("^1ERROR: Texture compression is required but not supported.\n^1Expect visual problems."));
		return 0;
	}
	else
	{
		// TGA only? Allow runtime compression
		if(can_dds)
		{
			cvar_set("gl_texturecompression", cvar_string("r_texture_dds_load"));
			return 2;
		}
		else
		{
			cvar_set("gl_texturecompression", "0");
			cvar_set("r_texture_dds_load", "0");
			return 0;
		}
	}
}

// note: include only those that should be in the menu!
#define GAMETYPES \
	GAMETYPE(MAPINFO_TYPE_DEATHMATCH) \
	GAMETYPE(MAPINFO_TYPE_TEAM_DEATHMATCH) \
	GAMETYPE(MAPINFO_TYPE_CTF) \
	GAMETYPE(MAPINFO_TYPE_CA) \
	GAMETYPE(MAPINFO_TYPE_FREEZETAG) \
	GAMETYPE(MAPINFO_TYPE_MAYHEM) \
	GAMETYPE(MAPINFO_TYPE_TEAM_MAYHEM) \
	GAMETYPE(MAPINFO_TYPE_KEEPAWAY) \
	GAMETYPE(MAPINFO_TYPE_TEAM_KEEPAWAY) \
	GAMETYPE(MAPINFO_TYPE_KEYHUNT) \
	GAMETYPE(MAPINFO_TYPE_LMS) \
	GAMETYPE(MAPINFO_TYPE_DOMINATION) \
	GAMETYPE(MAPINFO_TYPE_NEXBALL) \
	GAMETYPE(MAPINFO_TYPE_ONSLAUGHT) \
	GAMETYPE(MAPINFO_TYPE_ASSAULT) \
	GAMETYPE(MAPINFO_TYPE_SURVIVAL) \
	/* GAMETYPE(MAPINFO_TYPE_DUEL) */ \
	/**/

// hidden gametypes come last so indexing always works correctly
#define HIDDEN_GAMETYPES \
	GAMETYPE(MAPINFO_TYPE_RACE) \
	GAMETYPE(MAPINFO_TYPE_CTS) \
	GAMETYPE(MAPINFO_TYPE_INVASION) \
	/**/

Gametype GameType_GetID(int cnt)
{
	int i = 0;
	#define GAMETYPE(it) { if (i++ == cnt) return it; }
	GAMETYPES
	HIDDEN_GAMETYPES
	#undef GAMETYPE
	return NULL;
}

int GameType_GetCount()
{
	int i = 0;
	bool showall = autocvar_menu_create_show_all;
	#define GAMETYPE(id) ++i;
	GAMETYPES
	#undef GAMETYPE
	#define GAMETYPE(it) { if (showall) ++i; }
	HIDDEN_GAMETYPES
	#undef GAMETYPE
	return i;
}

int GameType_GetTotalCount()
{
	int i = 0;
	#define GAMETYPE(id) ++i;
	GAMETYPES
	HIDDEN_GAMETYPES
	#undef GAMETYPE
	return i;
}

string GameType_GetName(int cnt)
{
	Gametype i = GameType_GetID(cnt);
	return i ? MapInfo_Type_ToText(i) : "";
}

string GameType_GetIcon(int cnt)
{
	Gametype i = GameType_GetID(cnt);
	return i ? strcat("gametype_", MapInfo_Type_ToString(i)) : "";
}

.void(entity) TR;
.void(entity, float, float, entity) TD;
.void(entity, float) TDempty;
.void(entity, float, float) gotoRC;
entity makeXonoticTextLabel(float theAlign, string theText);
entity makeXonoticTextSlider(string);
.void(entity, string, string) addValue;
.void(entity) configureXonoticTextSliderValues;
entity makeXonoticColorpickerString(string theCvar, string theDefaultCvar);
entity makeXonoticCheckBoxString(string, string, string, string);
entity makeXonoticCheckBox(float, string, string);
.bool sendCvars;

void dialog_hudpanel_main_checkbox(entity me, string panelname)
{
	entity e;

	me.TR(me);
		me.TDempty(me, 1.5);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, strzone(strcat("hud_panel_", panelname)), _("Enable")));
}

void dialog_hudpanel_main_settings(entity me, string panelname)
{
	float i;
	entity e;

	me.gotoRC(me, me.currentRow + 1.5, 0);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Background:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg"))));
				e.setValueSpace(e, e.valueSpace * 1.25);
				e.addValue(e, _("Default"), "");
				e.addValue(e, _("Disable"), "0");
				e.addValue(e, strzone(strcat("border_", panelname)), strzone(strcat("border_", panelname)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Color:")));
			setDependentStringNotEqual(e, strzone(strcat("hud_panel_", panelname, "_bg")), "0");
		me.TD(me, 2, 2.6, e = makeXonoticColorpickerString(strzone(strcat("hud_panel_", panelname, "_bg_color")), "hud_panel_bg_color"));
			setDependentStringNotEqual(e, strzone(strcat("hud_panel_", panelname, "_bg_color")), "");
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3.6, e = makeXonoticCheckBoxString("", "1 1 1", strzone(strcat("hud_panel_", panelname, "_bg_color")), _("Default")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Border size:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_border"))));
				e.addValue(e, _("Default"), "");
				e.addValue(e, _("Disable"), "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i * 2, 0)), strzone(ftos(i * 2)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Opacity:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_alpha"))));
				e.addValue(e, _("Default"), "");
				for(i = 1; i <= 20; ++i)
					e.addValue(e, strzone(ftos_decimals_percentage(i / 20, 0)), strzone(ftos_mindecimals(i / 20)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Team color:")));
			setDependentNOT(e, strzone(strcat("hud_panel_", panelname, "_bg_alpha")), 0);
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_color_team"))));
				e.addValue(e, _("Default"), "");
				e.addValue(e, _("Disable"), "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals_percentage(i / 10, 0)), strzone(ftos_mindecimals(i / 10)));
				e.configureXonoticTextSliderValues(e);
				setDependentNOT(e, strzone(strcat("hud_panel_", panelname, "_bg_alpha")), 0);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3.6, e = makeXonoticCheckBox(0, "hud_configure_teamcolorforced", _("Test team color in configure mode")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Padding:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_padding"))));
				e.addValue(e, _("Default"), "");
				for(i = 0; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i - 5, 0)), strzone(ftos(i - 5)));
				e.configureXonoticTextSliderValues(e);

	string hide_ondeath = strcat("hud_panel_", panelname, "_hide_ondeath");
	if(cvar_type(hide_ondeath) & CVAR_TYPEFLAG_EXISTS)
	{
		me.TR(me);
			me.TDempty(me, 0.2);
			me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, strzone(hide_ondeath), _("Hide on death")));
	}

	me.gotoRC(me, me.currentRow + 0.5, 0); me.setFirstColumn(me, me.currentColumn);
}

bool isServerSingleplayer()
{
	return (cvar_string("net_address") == "127.0.0.1" && cvar_string("net_address_ipv6") == "::1");
}

void makeServerSingleplayer()
{
	// it doesn't allow clients to connect from different machines
	localcmd("defer 0.1 \"sv_cmd settemp net_address 127.0.0.1\"\n");
	localcmd("defer 0.1 \"sv_cmd settemp net_address_ipv6 ::1\"\n");
}

float getFadedAlpha(float currentAlpha, float startAlpha, float targetAlpha)
{
	if(startAlpha < targetAlpha)
		currentAlpha = min(currentAlpha + frametime * 0.5, targetAlpha);
	else
		currentAlpha = max(currentAlpha - frametime * 0.5, targetAlpha);
	return currentAlpha;
}

void CheckSendCvars(entity me, string cvarnamestring)
{
	if(me.sendCvars)
	{
		if(gamestatus & (GAME_CONNECTED | GAME_ISSERVER))
		{
			LOG_INFOF("Sending cvar: %s -> %s", cvarnamestring, cvar_string(cvarnamestring));
			localcmd(sprintf("\nsendcvar %s\n", cvarnamestring));
		}
	}
}
