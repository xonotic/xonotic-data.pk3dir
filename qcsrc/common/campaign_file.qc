#include "campaign_file.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/util.qh>
	#include <common/campaign_common.qh>
#endif

#ifndef SVQC
const int TR_TITLE = BIT(0);
const int TR_SHORTDESC = BIT(1);
const int TR_LONGDESC = BIT(2);
#endif

// CampaignFileLoad(offset, n)
// - Loads campaign level data (up to n entries starting at offset)
//   into the globals
// - Returns the number of entries successfully read
float CampaignFile_Load(int offset, float n)
{
	float fh;
	float lineno;
	float entlen;
	float i;
	string l, a;
	string fn;

	if(n > CAMPAIGN_MAX_ENTRIES)
		n = CAMPAIGN_MAX_ENTRIES;

	campaign_offset = offset;
	campaign_entries = 0;
	campaign_title = string_null;

	bool parse_translation_file = false;
	#ifndef SVQC
	string fn_tr = "";
	bool want_translation = false;
	int campaign_entries_save = 0;
	#endif

	fn = strcat("maps/campaign", campaign_name, ".txt");
	fh = fopen(fn, FILE_READ);

	LABEL(parse_campaign_file)
	if(fh >= 0)
	{
		for(lineno = 0; (l = fgets(fh)); )
		{
			if(strlen(l) == 0)
				continue; // empty line
			#ifndef SVQC
			if (parse_translation_file && want_translation && substring(l, 0, 5) == "//tr:")
			{
				entlen = tokenize(substring(l, 5, -1));

				a = argv(0);
				if (want_translation & TR_TITLE)
				{
					if (a != "")
						campaign_title = a;
				}
				else
				{
					if (a != "" && want_translation & TR_SHORTDESC)
						strcpy(campaign_shortdesc[campaign_entries - 1], a);
					a = argv(1);
					if (a == ",")
						a = argv(2);
					if (a != "" && want_translation & TR_LONGDESC)
						strcpy(campaign_longdesc[campaign_entries - 1], strreplace("\\n", "\n", a));
				}
				want_translation = 0;
				continue;
			}
			#endif
			if(substring(l, 0, 11) == "//campaign:")
			{
				if (!parse_translation_file)
					campaign_title = substring(l, 11, -1);
				#ifndef SVQC
				else if (substring(l, 11, -1) == campaign_title)
					want_translation = TR_TITLE;
				else
					want_translation = 0;
				#endif
				continue;
			}

			if(substring(l, 0, 2) == "//")
				continue; // comment

			#ifndef SVQC
			if (parse_translation_file)
				want_translation = 0;
			#endif

			if(lineno >= offset)
			{
				entlen = tokenize(l); // using insane tokenizer for CSV

#define CAMPAIGN_GETARG \
	a = argv(++i); \
	if(a == ",") \
		a = ""; \
	else \
		++i

				i = -1; // starts at -1 so I don't need postincrement; that is, i points to BEFORE the current arg!
				if (!parse_translation_file)
				{
					CAMPAIGN_GETARG; campaign_gametype[campaign_entries] = strzone(a);
					CAMPAIGN_GETARG; campaign_mapname[campaign_entries] = strzone(a);
					CAMPAIGN_GETARG; campaign_bots[campaign_entries] = stof(a);
					CAMPAIGN_GETARG; campaign_botskill[campaign_entries] = stof(a);
					CAMPAIGN_GETARG; campaign_fraglimit[campaign_entries] = strzone(a);
					CAMPAIGN_GETARG; campaign_timelimit[campaign_entries] = strzone(a);
					CAMPAIGN_GETARG; campaign_mutators[campaign_entries] = strzone(a);
					#ifndef SVQC
					CAMPAIGN_GETARG; campaign_shortdesc[campaign_entries] = strzone(a);
					CAMPAIGN_GETARG; campaign_longdesc[campaign_entries] = strzone(strreplace("\\n", "\n", a));
					#else
					CAMPAIGN_GETARG;
					CAMPAIGN_GETARG;
					#endif

					if (i > entlen)
						error("syntax error in campaign file: line has not enough fields");
				}
				else
				{
					#ifndef SVQC
					want_translation = 0;
					CAMPAIGN_GETARG;
					if (campaign_shortdesc[campaign_entries] == a)
						want_translation |= TR_SHORTDESC;
					CAMPAIGN_GETARG;
					if (campaign_longdesc[campaign_entries] == strreplace("\\n", "\n", a))
						want_translation |= TR_LONGDESC;
					#endif
				}

				++campaign_entries;

				if(campaign_entries >= n)
					break;
			}
			++lineno;
		}
		fclose(fh);

		#ifndef SVQC
		if (!parse_translation_file)
		{
			fn = strcat("maps/campaign", campaign_name, ".txt");
			fn_tr = language_filename(fn);
			if (fn != fn_tr)
			{
				campaign_entries_save = campaign_entries;
				campaign_entries = 0;
				fh = fopen(fn_tr, FILE_READ);
				parse_translation_file = true;
				goto parse_campaign_file;
			}
		}
		#endif
	}

	#ifndef SVQC
	if (parse_translation_file)
		campaign_entries = campaign_entries_save; // restore original number of levels
	#endif

	campaign_title = strzone(campaign_title);

	return campaign_entries;
}

void CampaignFile_Unload()
{
	if(campaign_title)
	{
		strfree(campaign_title);
		for(int i = 0; i < campaign_entries; ++i)
		{
			strfree(campaign_gametype[i]);
			strfree(campaign_mapname[i]);
			strfree(campaign_fraglimit[i]);
			strfree(campaign_timelimit[i]);
			strfree(campaign_mutators[i]);
			#ifndef SVQC
			strfree(campaign_shortdesc[i]);
			strfree(campaign_longdesc[i]);
			#endif
		}
		campaign_entries = 0;
	}
}
