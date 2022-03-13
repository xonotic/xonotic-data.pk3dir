#include "credits.qh"

#define CREDITS(TITLE, FUNCTION, PERSON, PERSON_, NL) \
	TITLE(_("Core Team")) \
		PERSON(Rudolf "divVerent" Polzer) \
		PERSON(Ant "Antibody" Zucaro) \
		PERSON(Marvin "Mirio" Beck) \
		PERSON(Merlijn Hofstra) \
		PERSON(Ruszkai "CuBe0wL" Ákos) \
		PERSON(Tyler "-z-" Mulligan) \
		PERSON(Zac "Mario" Jardine) \
	NL() \
	TITLE(_("Extended Team")) \
		PERSON(Antonio "terencehill" Piu) \
		PERSON(bones_was_here) \
		PERSON(David "Cloudwalk" Knapp) \
		PERSON(Freddy) \
		PERSON(Halogene) \
		PERSON(Jan "zykure" Behrens) \
		PERSON(Morosophos) \
		PERSON(MrBougo) \
		PERSON(nilyt/nyov) \
		PERSON(Nitroxis) \
		PERSON(packer) \
		PERSON(Severin "sev" Meyer) \
		PERSON(SpiKe) \
		PERSON(Thomas "illwieckz" Debesse) \
		PERSON(Victor "LegendGuard" Jaume) \
		PERSON(z411) \
	NL() \
	NL() \
	FUNCTION(_("Website")) \
		PERSON(Ant "Antibody" Zucaro (web)) \
		PERSON(Merlijn Hofstra) \
		PERSON(Tyler "-z-" Mulligan (web / game)) \
	NL() \
	FUNCTION(_("Stats")) \
		PERSON(Ant "Antibody" Zucaro) \
		PERSON(Jan "zykure" Behrens) \
	NL() \
	FUNCTION(_("Art")) \
		PERSON(Severin "sev" Meyer) \
		PERSON(Sahil "DiaboliK" Singhal) \
		PERSON(Peter "Morphed" Pielak) \
		PERSON(Sam "LJFHutch" Hutchinson) \
		PERSON(Pearce "theShadow" Michal) \
		PERSON(KingPimpCommander) \
	NL() \
	FUNCTION(_("Animation")) \
		PERSON(Sahil "DiaboliK" Singhal) \
		PERSON(nifrek) \
	NL() \
	FUNCTION(_("Level Design")) \
		PERSON(Amadeusz "amade/proraide" Sławiński) \
		PERSON(Ben "MooKow" Banker) \
		PERSON(Cortez) \
		PERSON(Cuinn "Cuinnton" Herrick) \
		PERSON(Debugger) \
		PERSON(Hugo "Calinou" Locurcio) \
		PERSON(Jakob "tZork" Markström Gröhn) \
		PERSON(Konrad "Justin" Slawinski) \
		PERSON(Maddin) \
		PERSON(L0) \
		PERSON(Łukasz "kuniu the frogg" Polek) \
		PERSON(Maik "SavageX" Merten) \
		PERSON(Marvin "Mirio" Beck) \
		PERSON(MintOX) \
		PERSON(packer) \
		PERSON(Pearce "theShadow" Michal) \
		PERSON(Rasmus "FruitieX" Eskola) \
		PERSON(Ruszkai "CuBe0wL" Ákos) \
		PERSON(Severin "sev" Meyer) \
		PERSON(ShadoW) \
		PERSON(t0uYK8Ne) \
	NL() \
	FUNCTION(_("Music / Sound FX")) \
		PERSON(AquaNova (Archer)) \
		PERSON(blkrbt) \
		PERSON(chooksta) \
		PERSON(Independent.nu) \
		PERSON(Lea "TheAudioMonkey" Edwards) \
		PERSON([master]mind) \
		PERSON(Merlijn Hofstra) \
		PERSON(Mick Rippon) \
		PERSON(Nick "bitbomb" Lucca) \
		PERSON(remaxim) \
		PERSON(Saulo "mand1nga" Gil) \
		PERSON({SC0RP} - Ian "ID" Dorrell) \
		PERSON(Stephan) \
		PERSON(unfa) \
	NL() \
	FUNCTION(_("Game Code")) \
		PERSON(Antonio "terencehill" Piu) \
		PERSON(Jakob "tZork" Markström Gröhn) \
		PERSON(martin-t) \
		PERSON(Mattia "Melanosuchus" Basaglia) \
		PERSON(Matthias "matthiaskrgr" Krüger) \
		PERSON(Rasmus "FruitieX" Eskola) \
		PERSON(Rudolf "divVerent" Polzer) \
		PERSON(Samual "Ares" Lenks) \
		PERSON(TimePath) \
		PERSON(Victor "LegendGuard" Jaume) \
		PERSON(z411) \
		PERSON(Zac "Mario" Jardine) \
	NL() \
	FUNCTION(_("Marketing / PR")) \
		PERSON(Tyler "-z-" Mulligan) \
		PERSON(Ruszkai "CuBe0wL" Ákos) \
		PERSON(Samual "Ares" Lenks) \
		PERSON(Saulo "mand1nga" Gil) \
	NL() \
	FUNCTION(_("Legal")) \
		PERSON(Rudolf "divVerent" Polzer) \
		PERSON(Merlijn Hofstra) \
	NL() \
	NL() \
	TITLE(_("Game Engine")) \
		FUNCTION("DarkPlaces") \
			PERSON(Ashley Rose "LadyHavoc" Hale) \
		NL() \
		FUNCTION(_("Engine Additions")) \
			PERSON(David "Cloudwalk" Knapp) \
			PERSON(Rudolf "divVerent" Polzer) \
			PERSON(Samual "Ares" Lenks) \
		NL() \
	NL() \
	TITLE(_("Compiler")) \
		FUNCTION("GMQCC") \
			PERSON(Wolfgang "Blub\0" Bumiller) \
			PERSON(Dale "graphitemaster" Weiler) \
		NL() \
	NL() \
	TITLE(_("Other Active Contributors")) \
		PERSON(Jeff) \
		PERSON(Mircea "Taoki" Kitsune) \
		PERSON(Penguinum) \
		PERSON(slava) \
		PERSON(Victor "LegendGuard" Jaume) \
	NL() \
	NL() \
	TITLE(_("Translators")) \
		NL() \
		FUNCTION(_("Asturian")) \
			PERSON(Llumex03) \
			PERSON(Tornes "Tornes.Llume" Ḷḷume) \
			PERSON(Ximielga) \
		NL() \
		FUNCTION(_("Belarusian")) \
			PERSON(Mihail "meequz" Varantsou) \
		NL() \
		FUNCTION(_("Bulgarian")) \
			PERSON(Alexander "alex4o" Bonin) \
			PERSON(ifohancroft) \
			PERSON(lokster) \
			PERSON(set_killer) \
			PERSON(ubone) \
		NL() \
		FUNCTION(_("Chinese (China)")) \
			PERSON(Antonidas) \
			PERSON(Armcoon) \
			PERSON(kalawore) \
			PERSON(sapphireliu) \
		NL() \
		FUNCTION(_("Chinese (Taiwan)")) \
			PERSON(Alisha) \
			PERSON(Armcoon) \
			PERSON(Jeff "s8321414" Huang) \
		NL() \
		FUNCTION(_("Cornish")) \
			PERSON(Nicky "nrowe" Rowe) \
		NL() \
		FUNCTION(_("Czech")) \
			PERSON(shogun assassin/woky) \
			PERSON(Superovoce) \
			PERSON(Tomáš "CZHeron" Volavka) \
		NL() \
		FUNCTION(_("Dutch")) \
			PERSON(Alexander "freefang" van Dam) \
			PERSON(Joeke "Mappack" de Graaf) \
			PERSON(Jonathan "Jonakeys" van der Steege) \
			PERSON(PinkRobot) \
			PERSON(vegiburger) \
		NL() \
		FUNCTION(_("English (Australia)")) \
			PERSON(Laurene "sunflowers" Albrand) \
			PERSON(Stuart "Cefiar" Young) \
			PERSON(Zac "Mario" Jardine) \
		NL() \
		FUNCTION(_("Finnish")) \
			PERSON(Jonas "PowaTree" Sahlberg) \
			PERSON(Henry "Exitium" Sanmark) \
			PERSON(Rasmus "FruitieX" Eskola) \
		NL() \
		FUNCTION(_("French")) \
			PERSON(Hugo "Calinou" Locurcio) \
			PERSON(Kim "coughingmouse" Lee) \
			PERSON(Maxime "Taximus" Paradis) \
			PERSON(RedGuff) \
			PERSON(Thomas "illwieckz" Debesse) \
			PERSON(Yannick "SpiKe" Le Guen) \
		NL() \
		FUNCTION(_("German")) \
			PERSON(Brot) \
			PERSON(cvcxc) \
			PERSON(Erik "Ablu" Schilling) \
			PERSON(Jope "Sless" Withers) \
			PERSON(Marvin "Mirio" Beck) \
			PERSON(Paul "Snapper") \
			PERSON(Rudolf "divVerent" Polzer) \
			PERSON(Wuzzy) \
			PERSON(Yepoleb) \
		NL() \
		FUNCTION(_("Greek")) \
			PERSON_("Γιάννης \"Evropi\" Ανθυμίδης") \
			PERSON(Konstantinos "LDinos" Mihalenas) \
			PERSON(Savoritias) \
			PERSON(Vindex) \
		NL() \
		FUNCTION(_("Hungarian")) \
			PERSON(Ruszkai "CuBe0wL" Ákos) \
			PERSON(xaN1C4n3) \
		NL() \
		FUNCTION(_("Irish")) \
			PERSON(Kevin "kscanne" Scannell) \
		NL() \
		FUNCTION(_("Italian")) \
			PERSON(Antonio "terencehill" Piu) \
			PERSON(Felice "MaidenBeast" Sallustio) \
			PERSON(stdi) \
			PERSON(XCostaX) \
		NL() \
		FUNCTION(_("Japanese")) \
			PERSON(Victor "LegendGuard" Jaume) \
		NL() \
		FUNCTION(_("Kazakh")) \
			PERSON(Артем "bystrov.arterm" Быстров) \
		NL() \
		FUNCTION(_("Korean")) \
			PERSON(Jisoo "s6e9x" Lim) \
			PERSON(Kim "coughingmouse" Lee) \
		NL() \
		FUNCTION(_("Polish")) \
			PERSON(4m) \
			PERSON(Alex "tiprogrammierer.alex" Progger) \
			PERSON(Amadeusz "amade/proraide" Sławiński) \
			PERSON(Artur "artur9010" Motyka) \
			PERSON(Jakub "KubeQ11" Pędziszewski) \
			PERSON(Kriss7475) \
		NL() \
		FUNCTION(_("Portuguese")) \
			PERSON(Ivan Paulos "greylica" Tomé) \
			PERSON(Jean Trindade "Muleke_Trairao" Pereira) \
			PERSON(Ricardo Manuel "Hellgardia" da Cruz Coelho da Silva) \
			PERSON(xXxCHAOTICxXx) \
		NL() \
		FUNCTION(_("Romanian")) \
			PERSON(Adrian-Ciprian "adrian.tinjala" Tînjală) \
			PERSON(BusterDBK) \
			PERSON(Mircea "Taoki" Kitsune) \
			PERSON(Sorin "unic_sorin" Botirla) \
			PERSON(Tudor "TropiKo" Ionel) \
		NL() \
		FUNCTION(_("Russian")) \
			PERSON(Alex "alextalker7" Talker) \
			PERSON(Alexandr "zrg") \
			PERSON(Andrei "adem4ik" Stepanov) \
			PERSON(Andrey "dekrY" P.) \
			PERSON(gravicappa) \
			PERSON(Hot Dog) \
			PERSON(Lord Canistra) \
			PERSON(Nikoli) \
			PERSON(Sergej "Clearness High" Lutsyk) \
		NL() \
		FUNCTION(_("Scottish Gaelic")) \
			PERSON_("GunChleoc") \
		NL() \
		FUNCTION(_("Serbian")) \
			PERSON_("Саша \"salepetronije\" Петровић") \
			PERSON(Marko M. Kostić) \
			PERSON(Pendulla) \
			PERSON(Rafael "Ristovski") \
		NL() \
		FUNCTION(_("Spanish")) \
			PERSON_("0000simon") \
			PERSON(Alan "aagp" Garcia) \
			PERSON(Ari_tent) \
			PERSON(brunodeleo) \
			PERSON(Kammy) \
			PERSON(roader_gentoo) \
			PERSON(Rodrigo Mouton Laudin) \
			PERSON(SouL) \
			PERSON(Starfire24680) \
			PERSON(Victor "LegendGuard" Jaume) \
		NL() \
		FUNCTION(_("Swedish")) \
			PERSON(Karl-Oskar "machine" Rikås) \
			PERSON(marcus256) \
		NL() \
		FUNCTION(_("Ukrainian")) \
			PERSON(Dmitro "Gamebot" Sokhin) \
			PERSON(Oleh "BlaXpirit" Prypin) \
			PERSON(Vasyl "Harmata" Melnyk) \
			PERSON(Yuriy "herrniemand" Ackermann) \
		NL() \
	NL() \
	TITLE(_("Past Contributors")) \
		PERSON(Akari) \
		PERSON(Alexander "naryl" Suhoverhov) \
		PERSON(Alexander "motorsep" Zubov) \
		PERSON(Amos "torus" Dudley) \
		PERSON(Andreas "Black" Kirsch) \
		PERSON(Attila "WW3" Houtkooper) \
		PERSON(BigMac) \
		PERSON(Braden "meoblast001" Walters) \
		PERSON(Brain Younds) \
		PERSON(BuddyFriendGuy) \
		PERSON(Chris "amethyst7" Matz) \
		PERSON(Christian Ice) \
		PERSON(Clinton "Kaziganthe" Freeman) \
		PERSON(Dan "Digger" Korostelev) \
		PERSON(Dan "Wazat" Hale) \
		PERSON(Diomedes) \
		PERSON(Dokujisan) \
		PERSON(Donkey) \
		PERSON(dstrek) \
		PERSON(Dustin Geeraert) \
		PERSON(Edgenetwork) \
		PERSON(Edward "Ed" Holness) \
		PERSON(Eric "Munyul Verminard" Sambach) \
		PERSON(Erik "Ablu" Schilling) \
		PERSON(Fabien "H. Reaper" Tschirhart) \
		PERSON(Florian Paul "lda17h" Schmidt) \
		PERSON(FrikaC) \
		PERSON(Garth "Zombie" Hendy) \
		PERSON(GATTS) \
		PERSON(Gerd "Elysis" Raudenbusch) \
		PERSON(Gottfried "Toddd" Hofmann) \
		PERSON(Henning "Tymo" Janssen) \
		PERSON(Innovati) \
		PERSON(JH0nny) \
		PERSON(Jitspoe) \
		PERSON(Jody Gallagher) \
		PERSON(Jope "Sless" Withers) \
		PERSON(Jubilant) \
		PERSON(Juergen "LowDragon" Timm) \
		PERSON(KadaverJack) \
		PERSON(Kevin "Tyrann" Shanahan) \
		PERSON(Kristian "morfar" Johansson) \
		PERSON(Kurt Dereli) \
		PERSON(lcatlnx) \
		PERSON(Lee David Ash) \
		PERSON(Lee Vermeulen) \
		PERSON(leileilol) \
		PERSON(Lyberta) \
		PERSON(magorian) \
		PERSON(Marius "GreEn`mArine" Shekow) \
		PERSON(Marko "Urre" Permanto) \
		PERSON(Mathieu "Elric" Olivier) \
		PERSON(Mattrew "Tronyn" Rye) \
		PERSON(MauveBib) \
		PERSON(Mephisto) \
		PERSON(michaelb) \
		PERSON(Michael "Tenshihan" Quinn) \
		PERSON(Mepper) \
		PERSON(Munyul) \
		PERSON(Netzwerg) \
		PERSON(NoelCower) \
		PERSON(Parapraxis) \
		PERSON(parasti) \
		PERSON(Paul "Strahlemann" Evers) \
		PERSON(Paul Scott) \
		PERSON(Petithomme) \
		PERSON(PlasmaSheep) \
		PERSON(Przemysław "atheros" Grzywacz) \
		PERSON(Q1 Retexturing Project) \
		PERSON(Qantourisc) \
		PERSON(Oleh "BlaXpirit" Prypin) \
		PERSON(Rick "Rat" Kelley) \
		PERSON(Robert "ai" Kuroto) \
		PERSON(Ronan) \
		PERSON(Sajt) \
		PERSON(Samual "Ares" Lenks) \
		PERSON(Saulo "mand1nga" Gil) \
		PERSON(Shaggy) \
		PERSON(Shank) \
		PERSON(s1lence) \
		PERSON(Simon O’Callaghan) \
		PERSON(Soelen) \
		PERSON(SomeGuy) \
		PERSON(SoulKeeper_p) \
		PERSON(Spike) \
		PERSON(Spirit) \
		PERSON(Stephan "esteel" Stahl) \
		PERSON(Steve Vermeulen) \
		PERSON(Supajoe) \
		PERSON(Sydes) \
		PERSON(Tei) \
		PERSON(The player with the unnecessarily long name) \
		PERSON(Tomaz) \
		PERSON(Ulrich Galbraith) \
		PERSON(Vortex) \
		PERSON(William Libert) \
		PERSON(William "Willis" Weilep) \
		PERSON(Yves "EviLair" Allaire) \
		PERSON(Zenex) \
		PERSON(... and a goat) \
		/**/


int CREDITS_TYPE_TITLE = 2;
int CREDITS_TYPE_FUNCTION = 1;
int CREDITS_TYPE_PERSON = 0;
int CREDITS_TYPE_NL = -1;
void credits_add_line(int fh, int n, int type, string line)
{
	if (type == CREDITS_TYPE_TITLE)
		line = strcat("**", line);
	else if (type == CREDITS_TYPE_FUNCTION)
		line = strcat("*", line);

	if (fh >= 0)
		fputs(fh, strcat(line, "\n"));
	if (n >= 0)
		bufstr_add(n, line, 0);
}

void credits_build(int fh, int n)
{
	#define CREDITS_TITLE(t) credits_add_line(fh, n, CREDITS_TYPE_TITLE, t);
	#define CREDITS_FUNCTION(f) credits_add_line(fh, n, CREDITS_TYPE_FUNCTION, f);
	#define CREDITS_PERSON(p) credits_add_line(fh, n, CREDITS_TYPE_PERSON, p);
	#define _CREDITS_PERSON(p) CREDITS_PERSON(#p)
	#define CREDITS_NL() credits_add_line(fh, n, CREDITS_TYPE_NL, "");
	CREDITS(CREDITS_TITLE, CREDITS_FUNCTION, _CREDITS_PERSON, CREDITS_PERSON, CREDITS_NL)
	#undef CREDITS_TITLE
	#undef CREDITS_FUNCTION
	#undef CREDITS_PERSON
	#undef _CREDITS_PERSON
	#undef CREDITS_NL
}

int credits_get()
{
	int n = buf_create();
	credits_build(-1, n);
	return n;
}

void credits_export()
{
	int fh = fopen("credits.txt", FILE_WRITE);
	if(fh < 0)
		return;
	credits_build(fh, -1);
}

#undef CREDITS

entity makeXonoticCreditsList()
{
	entity me;
	me = NEW(XonoticCreditsList);
	me.configureXonoticCreditsList(me);
	return me;
}
void XonoticCreditsList_configureXonoticCreditsList(entity me)
{
	me.configureXonoticListBox(me);
	me.bufferIndex = credits_get();
	me.nItems = buf_getsize(me.bufferIndex);
	if (cvar("_menu_credits_export")) // set by the menu_credits_export alias
	{
		credits_export();
		cvar_set("_menu_credits_export", "0");
	}
}
void XonoticCreditsList_destroy(entity me)
{
	buf_del(me.bufferIndex);
}
void XonoticCreditsList_draw(entity me)
{
	if(me.scrolling)
	{
		me.scrollPos = bound(0, (time - me.scrolling) * me.itemHeight, me.nItems * me.itemHeight - 1);
		me.scrollPosTarget = me.scrollPos;
	}
	SUPER(XonoticCreditsList).draw(me);
}
void XonoticCreditsList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticCreditsList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
}
void XonoticCreditsList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;
	float theAlpha;
	vector theColor;

	s = bufstr_get(me.bufferIndex, i);

	if(substring(s, 0, 2) == "**")
	{
		s = substring(s, 2, strlen(s) - 2);
		theColor = SKINCOLOR_CREDITS_TITLE;
		theAlpha = SKINALPHA_CREDITS_TITLE;
	}
	else if(substring(s, 0, 1) == "*")
	{
		s = substring(s, 1, strlen(s) - 1);
		theColor = SKINCOLOR_CREDITS_FUNCTION;
		theAlpha = SKINALPHA_CREDITS_FUNCTION;
	}
	else
	{
		theColor = SKINCOLOR_CREDITS_PERSON;
		theAlpha = SKINALPHA_CREDITS_PERSON;
	}

	draw_CenterText(me.realUpperMargin * eY + 0.5 * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

float XonoticCreditsList_keyDown(entity me, float key, float ascii, float shift)
{
	me.scrolling = 0;
	return SUPER(XonoticCreditsList).keyDown(me, key, ascii, shift);
}
