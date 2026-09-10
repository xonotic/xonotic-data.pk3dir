#include "playermodel.qh"

#include "textlabel.qh"

entity makeXonoticPlayerModelSelector()
{
	entity me = NEW(XonoticPlayerModelSelector);
	me.configureXonoticImage(me, string_null, -1);
	return me;
}

const int BUFMODELS_TITLE  = 0;
const int BUFMODELS_IMAGE  = 1;
const int BUFMODELS_MODEL  = 2;
const int BUFMODELS_SKIN   = 3;
const int BUFMODELS_DESC   = 4;
const int BUFMODELS_COUNT  = 5;

void XonoticPlayerModelSelector_loadModels(entity me)
{
	float glob = search_begin(get_model_datafilename(string_null, -1, "txt"), true, true);
	if (glob < 0)
		return;

	string fn;
	int i;
	float sortbuf = buf_create();
	for (i = 0; i < search_getsize(glob); ++i)
	{
		// Select model #i
		fn = search_getfilename(glob, i);
		if (!get_model_parameters(fn, -1) || get_model_parameters_hidden)
			continue;
		bufstr_add(sortbuf, sprintf("%-128s%s", get_model_parameters_name, fn), 1);
	}
	search_end(glob);

	buf_sort(sortbuf, 128, 0);
	me.numModels = buf_getsize(sortbuf);
	me.bufModels = buf_create();
	int buf_idx;
	for (i = 0; i < me.numModels; ++i)
	{
		fn = substring(bufstr_get(sortbuf, i), 128, -1);
		if (!get_model_parameters(fn, -1))
			error("But it JUST worked!");
		if (get_model_parameters_hidden)
			continue;

		buf_idx = BUFMODELS_COUNT * i;
		bufstr_set(me.bufModels, buf_idx + BUFMODELS_TITLE, get_model_parameters_name);
		bufstr_set(me.bufModels, buf_idx + BUFMODELS_IMAGE, strcat("/", substring(get_model_datafilename(get_model_parameters_modelname, get_model_parameters_modelskin, "tga"), 0, -5)));
		bufstr_set(me.bufModels, buf_idx + BUFMODELS_MODEL, get_model_parameters_modelname);
		bufstr_set(me.bufModels, buf_idx + BUFMODELS_SKIN, ftos(get_model_parameters_modelskin));

#ifdef XONVOTE186
		get_model_parameters_desc = cons_mid(get_model_parameters_desc, "\n", get_model_parameters_sex);
#else
		get_model_parameters_desc = cons_mid(get_model_parameters_desc, "\n", get_model_parameters_description);
		get_model_parameters_desc = cons_mid(get_model_parameters_desc, "\n", strcat("Sex: ", get_model_parameters_sex));
		get_model_parameters_desc = cons_mid(get_model_parameters_desc, "\n", sprintf("Weight: %g kg", get_model_parameters_weight));
		get_model_parameters_desc = cons_mid(get_model_parameters_desc, "\n", sprintf("Age: %g", get_model_parameters_age));
#endif
		bufstr_set(me.bufModels, buf_idx + BUFMODELS_DESC, get_model_parameters_desc);
	}
	buf_del(sortbuf);

	get_model_parameters(string_null, 0);
	me.loadCvars(me); // this will select the initial model, depending on the current cvars
	me.go(me, 0); // this will set the vars for the selected model
}

void XonoticPlayerModelSelector_destroy(entity me)
{
	if (me.bufModels >= 0)
	{
		buf_del(me.bufModels);
		me.bufModels = -1;
	}
}

void XonoticPlayerModelSelector_loadCvars(entity me)
{
	string skin = cvar_string("_cl_playerskin");
	string modelname = cvar_string("_cl_playermodel");

	int i;
	for (i = 0; i < me.numModels; ++i)
		if (bufstr_get(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_MODEL) == modelname
		&&  bufstr_get(me.bufModels, BUFMODELS_COUNT*i+BUFMODELS_SKIN) == skin)
			break;

	if (i >= me.numModels) // fail
		i = 0;
	me.idxModels = i;
}

void XonoticPlayerModelSelector_go(entity me, float d)
{
	me.idxModels = mod(me.idxModels + d + me.numModels, me.numModels);

	// Select model #i
	int buf_idx = BUFMODELS_COUNT * me.idxModels;
	string currentModelImage = bufstr_get(me.bufModels, buf_idx + BUFMODELS_IMAGE);
	me.currentSkin = stof(bufstr_get(me.bufModels, buf_idx + BUFMODELS_SKIN));
	strcpy(me.currentModel, bufstr_get(me.bufModels, buf_idx + BUFMODELS_MODEL));
	strcpy(me.currentModelDescription, bufstr_get(me.bufModels, buf_idx + BUFMODELS_DESC));
	strcpy(me.currentModelTitle, bufstr_get(me.bufModels, buf_idx + BUFMODELS_TITLE));

	// Set the title
	me.titleLabel.setText(me.titleLabel, me.currentModelTitle);

	// Set the description
#ifdef XONVOTE186
	me.controlledTextLabel.setText(me.controlledTextLabel, me.currentModelDescription);
#endif

	// Fix the image
	if (me.src)
		strunzone(me.src);
	me.src = strzone(draw_PictureSize(currentModelImage) == '0 0 0'
		? "nopreview_player"
		: currentModelImage);
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
	if (me.numModels <= 0)
	{
		draw_CenterText('0.5 0.5 0', _("<no model found>"), me.realFontSize, SKINCOLOR_TEXT, 0.6, false);
		return;
	}

	SUPER(XonoticPlayerModelSelector).draw(me);

#ifndef XONVOTE186
	// draw text on the image, handle \n in the description
	int n = tokenizebyseparator(me.currentModelDescription, "\n");
	vector o = vec2(0.5, 1 - me.realFontSize.y * (n + 0.5));
	for (int i = 0; i < n; ++i)
	{
		draw_CenterText(o, argv(i), me.realFontSize, SKINCOLOR_TEXT, 1, false);
		o.y += me.realFontSize.y;
	}
#endif
}

void XonoticPlayerModelSelector_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticPlayerModelSelector).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.realFontSize.y = me.fontSize / absSize.y;
	me.realFontSize.x = me.fontSize / absSize.x;
}

void XonoticPlayerModelSelector_showNotify(entity me)
{
	// Reinitialize self.
	me.destroy(me);
	me.loadModels(me);
}
