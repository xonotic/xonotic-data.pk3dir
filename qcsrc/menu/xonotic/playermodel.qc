#include "playermodel.qh"

entity makeXonoticPlayerModelSelector()
{
	entity me;
	me = NEW(XonoticPlayerModelSelector);
	me.configureXonoticImage(me, string_null, -1);
	return me;
}

const float BUFMODELS_TITLE = 0;
const float BUFMODELS_IMAGE = 1;
const float BUFMODELS_MODEL = 2;
const float BUFMODELS_SKIN = 3;
const float BUFMODELS_DESC = 4;
const float BUFMODELS_COUNT = 5;

#define XONVOTE186 1 // (nyov) removal of model text description

void XonoticPlayerModelSelector_loadModels(entity me)
{
	int i;
	string fn;

	float glob = search_begin(get_model_datafilename(string_null, -1, "txt"), true, true);
	if (glob < 0)
		return;

	float sortbuf = buf_create();
	for(i = 0; i < search_getsize(glob); ++i)
	{
		// select model #i!
		fn = search_getfilename(glob, i);
		if(!get_model_parameters(fn, -1))
			continue;
		if(get_model_parameters_hidden)
			continue;
		bufstr_add(sortbuf, sprintf("%-128s%s", get_model_parameters_name, fn), 1);
	}
	search_end(glob);
	buf_sort(sortbuf, 128, 0);
	me.numModels = buf_getsize(sortbuf);
	me.bufModels = buf_create();
	for(i = 0; i < me.numModels; ++i)
	{
		fn = substring(bufstr_get(sortbuf, i), 128, -1);
		if(!get_model_parameters(fn, -1))
			error("But it JUST worked!");
		if(get_model_parameters_hidden)
			continue;
		bufstr_set(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_TITLE, get_model_parameters_name);
		bufstr_set(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_IMAGE, strcat("/", substring(get_model_datafilename(get_model_parameters_modelname, get_model_parameters_modelskin, "tga"), 0, -5)));
		bufstr_set(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_MODEL, get_model_parameters_modelname);
		bufstr_set(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_SKIN, ftos(get_model_parameters_modelskin));
		get_model_parameters_desc = strcat(get_model_parameters_desc, "\n");
#if XONVOTE186
		if(get_model_parameters_sex)
			get_model_parameters_desc = strcat(get_model_parameters_desc, sprintf("\n%s", get_model_parameters_sex));
#else
		if(get_model_parameters_description)
			get_model_parameters_desc = strcat(get_model_parameters_desc, sprintf("\n%s\n", get_model_parameters_description));
		if(get_model_parameters_sex)
			get_model_parameters_desc = strcat(get_model_parameters_desc, sprintf("\nSex: %s", get_model_parameters_sex));
		if(get_model_parameters_weight)
			get_model_parameters_desc = strcat(get_model_parameters_desc, sprintf("\nWeight: %g kg", get_model_parameters_weight));
		if(get_model_parameters_age)
			get_model_parameters_desc = strcat(get_model_parameters_desc, sprintf("\nAge: %g", get_model_parameters_age));
#endif
		while(substring(get_model_parameters_desc, -1, 1) == "\n")
			get_model_parameters_desc = substring(get_model_parameters_desc, 0, -2);
		bufstr_set(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_DESC, get_model_parameters_desc);
	}
	buf_del(sortbuf);
	get_model_parameters(string_null, 0);
	me.loadCvars(me); // this will select the initial model, depending on the current cvars
	me.go(me, 0); // this will set the vars for the selected model
}

void XonoticPlayerModelSelector_destroy(entity me)
{
	if(me.bufModels >= 0)
	{
		buf_del(me.bufModels);
		me.bufModels = -1;
	}
}

void XonoticPlayerModelSelector_loadCvars(entity me)
{
	string skin, modelname;
	float i;

	skin = cvar_string("_cl_playerskin");
	modelname = cvar_string("_cl_playermodel");

	for(i = 0; i < me.numModels; ++i)
	{
		if(bufstr_get(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_MODEL) == modelname)
		if(bufstr_get(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_SKIN) == skin)
			break;
	}
	if(i >= me.numModels) // fail
		i = 0;
	me.idxModels = i;
}

void XonoticPlayerModelSelector_go(entity me, float d)
{
	me.idxModels = mod(me.idxModels + d + me.numModels, me.numModels);

	// select model #i!
	strcpy(me.currentModelTitle, bufstr_get(me.bufModels, BUFMODELS_COUNT*me.idxModels+BUFMODELS_TITLE));
	strcpy(me.currentModelImage, bufstr_get(me.bufModels, BUFMODELS_COUNT*me.idxModels+BUFMODELS_IMAGE));
	me.currentSkin = stof(bufstr_get(me.bufModels, BUFMODELS_COUNT*me.idxModels+BUFMODELS_SKIN));
	strcpy(me.currentModel, bufstr_get(me.bufModels, BUFMODELS_COUNT*me.idxModels+BUFMODELS_MODEL));
	strcpy(me.currentModelDescription, bufstr_get(me.bufModels, BUFMODELS_COUNT*me.idxModels+BUFMODELS_DESC));

	// fix the image
	if(draw_PictureSize(me.currentModelImage) == '0 0 0')
		me.src = "nopreview_player";
	else
		me.src = me.currentModelImage;
	me.updateAspect(me);
}

void PlayerModelSelector_Next_Click(entity btn, entity me)
{
	if (me.numModels <= 0)
		return;
	me.go(me, +1);
	me.saveCvars(me);
}

void PlayerModelSelector_Prev_Click(entity btn, entity me)
{
	if (me.numModels <= 0)
		return;
	me.go(me, -1);
	me.saveCvars(me);
}

void XonoticPlayerModelSelector_saveCvars(entity me)
{
	// we can't immediately apply here because of flood control
	cvar_set("_cl_playermodel", me.currentModel);
	cvar_set("_cl_playerskin", ftos(me.currentSkin));
}

void XonoticPlayerModelSelector_draw(entity me)
{
	float i, n;
	vector o;

	if (me.numModels <= 0)
	{
		draw_CenterText('0.5 0.5 0', _("<no model found>"), me.realFontSize, SKINCOLOR_TEXT, 0.6, false);
		return;
	}

	SUPER(XonoticPlayerModelSelector).draw(me);
	// draw text on the image, handle \n in the description

	draw_beginBoldFont();

#if XONVOTE186 // (nyov) lower name display looks better when there is no description text
	draw_CenterText('0.5 0.8 0', me.currentModelTitle, me.realFontSize * (me.titleFontSize / me.fontSize), SKINCOLOR_MODELTITLE, SKINALPHA_MODELTITLE, false);
#else
	draw_CenterText('0.5 0 0', me.currentModelTitle, me.realFontSize * (me.titleFontSize / me.fontSize), SKINCOLOR_MODELTITLE, SKINALPHA_MODELTITLE, false);
#endif

	draw_endBoldFont();

	o = '0.5 1 0' - eY * me.realFontSize.y * ((n = tokenizebyseparator(me.currentModelDescription, "\n")) + 0.5);
	for(i = 0; i < n; ++i)
	{
		draw_CenterText(o, argv(i), me.realFontSize, SKINCOLOR_TEXT, 1, false);
		o += eY * me.realFontSize.y;
	}
}

void XonoticPlayerModelSelector_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticPlayerModelSelector).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize_y = me.fontSize / absSize.y;
	me.realFontSize_x = me.fontSize / absSize.x;
}

void XonoticPlayerModelSelector_showNotify(entity me)
{
	// Reinitialize self.
	me.destroy(me);
	me.loadModels(me);
}
