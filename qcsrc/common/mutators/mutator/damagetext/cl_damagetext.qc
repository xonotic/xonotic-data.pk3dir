#include "cl_damagetext.qh"

CLASS(DamageText, Object)
	ATTRIB(DamageText, m_color, vector, autocvar_cl_damagetext_color);
	ATTRIB(DamageText, m_color_friendlyfire, vector, autocvar_cl_damagetext_friendlyfire_color);
	ATTRIB(DamageText, m_size, float, autocvar_cl_damagetext_size_min);
	ATTRIB(DamageText, alpha, float, autocvar_cl_damagetext_alpha_start);
	ATTRIB(DamageText, fade_rate, float, 0);
	ATTRIB(DamageText, m_shrink_rate, float, 0);
	ATTRIB(DamageText, m_group, int, 0);
	ATTRIB(DamageText, m_friendlyfire, bool, false);
	ATTRIB(DamageText, m_healthdamage, int, 0);
	ATTRIB(DamageText, m_armordamage, int, 0);
	ATTRIB(DamageText, m_potential_damage, int, 0);
	ATTRIB(DamageText, m_deathtype, int, 0);
	ATTRIB(DamageText, hit_time, float, 0);
	ATTRIB(DamageText, text, string, string_null);
	ATTRIB(DamageText, m_screen_coords, bool, false);

	STATIC_ATTRIB(DamageText, screen_count, int, 0);

	void DamageText_draw2d(DamageText this)
	{
		float since_hit = time - this.hit_time;
		// can't use `dt = hit_time - prev_update_time` because shrinking wouldn't be linear
		float size = this.m_size - since_hit * this.m_shrink_rate * this.m_size;
		float alpha_ = this.alpha - since_hit * this.fade_rate;
		bool haslifetime = (autocvar_cl_damagetext_lifetime < 0 // negative ignores lifetime
				|| (since_hit < autocvar_cl_damagetext_lifetime));
		if (alpha_ <= 0 || size <= 0 || !haslifetime)
		{
			IL_REMOVE(g_damagetext, this);
			delete(this);
			return;
		}

		vector screen_pos;
		if (this.m_screen_coords)
			screen_pos = this.origin + since_hit * autocvar_cl_damagetext_2d_velocity;
		else
		{
			vector forward, right, up;
			MAKE_VECTORS(view_angles, forward, right, up);

			vector world_offset = since_hit * autocvar_cl_damagetext_velocity_world
					+ autocvar_cl_damagetext_offset_world;
			vector world_pos = this.origin
			                 + world_offset.x * forward
			                 + world_offset.y * right
			                 + world_offset.z * up;

			screen_pos = project_3d_to_2d(world_pos)
				+ (since_hit * autocvar_cl_damagetext_velocity_screen)
				+ autocvar_cl_damagetext_offset_screen;
		}
		screen_pos.y += size / 2;

		// strip trailing spaces
		string dtext = this.text;
		int j = strlen(dtext) - 1;
		while (substring(dtext, j, 1) == " " && j >= 0)
			--j;
		if (j < strlen(dtext) - 1)
			dtext = substring(dtext, 0, j + 1);

		// strip leading spaces
		j = 0;
		while (substring(dtext, j, 1) == " " && j < strlen(dtext))
			++j;
		if (j > 0)
			dtext = substring(dtext, j, strlen(dtext) - j);

		// Center damage text
		screen_pos.x -= stringwidth(dtext, true, hud_fontsize * 2) * 0.5;

		if (screen_pos.z >= 0)
		{
			screen_pos.z = 0;
			vector rgb;
			if (this.m_friendlyfire)
				rgb = this.m_color_friendlyfire;
			else
				rgb = this.m_color;

			if (autocvar_cl_damagetext_color_per_weapon)
			{
				Weapon w = DEATH_WEAPONOF(this.m_deathtype);
				if (w != WEP_Null) rgb = w.m_color;
			}

			vector drawfontscale_save = drawfontscale;
			drawfontscale = (size / autocvar_cl_damagetext_size_max) * '1 1 0';
			screen_pos.y -= drawfontscale.x * size / 2;
			drawcolorcodedstring2_builtin(screen_pos, this.text,
					autocvar_cl_damagetext_size_max * '1 1 0',
					rgb, alpha_, DRAWFLAG_NORMAL);
			drawfontscale = drawfontscale_save;
		}
	}
	ATTRIB(DamageText, draw2d, void(DamageText), DamageText_draw2d);

	void DamageText_update(DamageText this, vector _origin, bool screen_coords,
			int _health, int _armor, int _potential_damage, int _deathtype)
	{
		this.m_healthdamage = _health;
		this.m_armordamage = _armor;
		this.m_potential_damage = _potential_damage;
		this.m_deathtype = _deathtype;
		this.hit_time = time;
		setorigin(this, _origin);
		this.m_screen_coords = screen_coords;
		if (this.m_screen_coords)
			this.alpha = autocvar_cl_damagetext_2d_alpha_start;
		else
			this.alpha = autocvar_cl_damagetext_alpha_start;

		int health           = rint(this.m_healthdamage
		                     / DAMAGETEXT_PRECISION_MULTIPLIER);
		int armor            = rint(this.m_armordamage
		                     / DAMAGETEXT_PRECISION_MULTIPLIER);
		int total            = rint((this.m_healthdamage + this.m_armordamage)
		                     / DAMAGETEXT_PRECISION_MULTIPLIER);
		int potential        = rint(this.m_potential_damage
		                     / DAMAGETEXT_PRECISION_MULTIPLIER);
		int potential_health = rint((this.m_potential_damage - this.m_armordamage)
		                     / DAMAGETEXT_PRECISION_MULTIPLIER);

		bool redundant = almost_equals_eps(this.m_healthdamage + this.m_armordamage,
				this.m_potential_damage, 5);

		string s = autocvar_cl_damagetext_format;
		s = strreplace("{armor}", (
			(this.m_armordamage == 0 && autocvar_cl_damagetext_format_hide_redundant)
				? ""
				: sprintf("%d", armor)
			), s);
		s = strreplace("{potential}", (
			(redundant && autocvar_cl_damagetext_format_hide_redundant)
				? ""
				: sprintf("%d", potential)
			), s);
		s = strreplace("{potential_health}", (
			(redundant && autocvar_cl_damagetext_format_hide_redundant)
				? ""
				: sprintf("%d", potential_health)
			), s);

		s = strreplace("{health}", (
			(health == potential_health || !autocvar_cl_damagetext_format_verbose)
				? sprintf("%d",      health)
				: sprintf("%d (%d)", health, potential_health)
			), s);
		s = strreplace("{total}", (
			(total == potential || !autocvar_cl_damagetext_format_verbose)
				? sprintf("%d",      total)
				: sprintf("%d (%d)", total, potential)
			), s);

		// futureproofing: remove any remaining (unknown) format strings
		// in case we add new ones in the future so players can use them
		// on new servers and still have working damagetext on old ones
		while (true)
		{
			int opening_pos = strstrofs(s, "{", 0);
			if (opening_pos == -1) break;
			int closing_pos = strstrofs(s, "}", opening_pos);
			if (closing_pos == -1 || closing_pos <= opening_pos) break;
			s = strcat(
				substring(s, 0, opening_pos),
				substring_range(s, closing_pos + 1, strlen(s))
			);
		}

		strcpy(this.text, s);

		this.m_size = map_bound_ranges(potential,
			autocvar_cl_damagetext_size_min_damage, autocvar_cl_damagetext_size_max_damage,
			autocvar_cl_damagetext_size_min,        autocvar_cl_damagetext_size_max);
	}

	CONSTRUCTOR(DamageText, int _group, vector _origin, bool _screen_coords,
		int _health, int _armor, int _potential_damage, int _deathtype, bool _friendlyfire)
	{
		CONSTRUCT(DamageText);
		this.m_group = _group;
		this.m_friendlyfire = _friendlyfire;
		this.m_screen_coords = _screen_coords;
		if (_screen_coords)
		{
			if (autocvar_cl_damagetext_2d_alpha_lifetime)
				this.fade_rate = 1 / autocvar_cl_damagetext_2d_alpha_lifetime;
			if (autocvar_cl_damagetext_2d_size_lifetime)
				this.m_shrink_rate = 1 / autocvar_cl_damagetext_2d_size_lifetime;
		}
		else
		{
			if (autocvar_cl_damagetext_alpha_lifetime)
				this.fade_rate = 1 / autocvar_cl_damagetext_alpha_lifetime;
			this.m_shrink_rate = 0;
		}
		DamageText_update(this, _origin, _screen_coords,
			_health, _armor, _potential_damage, _deathtype);
		IL_PUSH(g_damagetext, this);
	}

	DESTRUCTOR(DamageText)
	{
		strfree(this.text);
		--DamageText_screen_count;
	}
ENDCLASS(DamageText)

float current_alpha(entity damage_text)
{
	// alpha doesn't change - actual alpha is always calculated from the initial value
	return damage_text.alpha - (time - damage_text.hit_time) * damage_text.fade_rate;
}

NET_HANDLE(damagetext, bool isNew)
{
	make_pure(this);
	int server_entity_index = ReadByte();
	int deathtype = ReadInt24_t();
	int flags = ReadByte();
	bool friendlyfire = flags & DTFLAG_SAMETEAM;

	int health, armor, potential_damage;
	if (flags & DTFLAG_BIG_HEALTH) health = ReadInt24_t();
	else health = ReadShort();
	if (flags & DTFLAG_NO_ARMOR) armor = 0;
	else if (flags & DTFLAG_BIG_ARMOR) armor = ReadInt24_t();
	else armor = ReadShort();
	if (flags & DTFLAG_NO_POTENTIAL) potential_damage = health + armor;
	else if (flags & DTFLAG_BIG_POTENTIAL) potential_damage = ReadInt24_t();
	else potential_damage = ReadShort();

	return = true;
	if (!isNew) return;
	if (autocvar_cl_damagetext == 0) return;
	if (friendlyfire)
	{
		if (autocvar_cl_damagetext_friendlyfire == 0)
			return;

		if (autocvar_cl_damagetext_friendlyfire == 1
		&& health == 0 && armor == 0)
			return;
	}

	int client_entity_index = server_entity_index - 1;
	entity entcs = entcs_receiver(client_entity_index);

	bool can_use_3d = entcs && entcs.has_origin;
	bool too_close = vdist(entcs.origin - view_origin, <, autocvar_cl_damagetext_2d_close_range);
	bool prefer_in_view = autocvar_cl_damagetext_2d_out_of_view && !projected_on_screen(project_3d_to_2d(entcs.origin));
	bool prefer_2d = spectatee_status != -1 && autocvar_cl_damagetext_2d && (too_close || prefer_in_view);

	vector position;
	bool is2d;
	entity entDT = NULL; // which DT to update

	float alphathreshold = autocvar_cl_damagetext_accumulate_alpha_rel
	                * autocvar_cl_damagetext_alpha_start;

	// check if this entity already has a DamageText for it
	IL_EACH(g_damagetext, it.m_group == server_entity_index, {
		// if the time window where damage accumulates closes,
		// disown the parent entity from this DamageText
		// and (likely) give the entity a new DT afterwards
		// this should only cancel damage accumulation for this DT

		if (flags & DTFLAG_STOP_ACCUMULATION
			|| (current_alpha(it) < alphathreshold)
			|| ((autocvar_cl_damagetext_accumulate_lifetime >= 0) // negative never disowns
				&& (time - it.hit_time > autocvar_cl_damagetext_accumulate_lifetime)))
		{
			it.m_group = 0;
		}
		else
		{
			health += it.m_healthdamage;
			armor += it.m_armordamage;
			potential_damage += it.m_potential_damage;

			entDT = it;
		}
		break;
	});

	if (can_use_3d && !prefer_2d)
	{
		// world coords
		is2d = false;
		position = entcs.origin;

		if (entDT)
			goto updateDT;

		// 3D DamageTexts can later be changed into 2D,
		// increment this here just in case
		++DamageText_screen_count;
		goto spawnnewDT;
	}
	else if (autocvar_cl_damagetext_2d && spectatee_status != -1)
	{
		// screen coords only
		is2d = true;
		position = vec2(vid_conwidth  * autocvar_cl_damagetext_2d_pos.x,
		                vid_conheight * autocvar_cl_damagetext_2d_pos.y);

		if (entDT)
			goto updateDT;

		// offset when hitting multiple enemies, dmgtext would overlap
		position += autocvar_cl_damagetext_2d_overlap_offset * DamageText_screen_count++;
		goto spawnnewDT;
	}
	return;

LABEL(updateDT)
	DamageText_update(entDT, position, is2d, health, armor, potential_damage, deathtype);
	return;

LABEL(spawnnewDT)
	NEW(DamageText, server_entity_index, position, is2d,
		health, armor, potential_damage, deathtype, friendlyfire);
	return;
}
