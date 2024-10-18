#include "spawn.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <common/util.qh>
    #include <common/weapons/_all.qh>
    #include <common/stats.qh>
    #include <server/world.qh>
#endif

#ifdef SVQC

// spawner entity
// "classname" "target_spawn"
// "message" "fieldname value fieldname value ..."
// "spawnflags"
//   ON_MAPLOAD = trigger on map load

float target_spawn_initialized;
.void(entity this) target_spawn_spawnfunc;
float target_spawn_spawnfunc_field;
.entity target_spawn_activator;
.float target_spawn_id;
float target_spawn_count;

void target_spawn_helper_setmodel(entity this)
{
	_setmodel(this, this.model);
}

void target_spawn_helper_setsize(entity this)
{
	setsize(this, this.mins, this.maxs);
}

void target_spawn_edit_entity(entity this, entity e, string msg, entity kt, entity t2, entity t3, entity t4, entity act, entity trigger)
{
	float i, n, valuefieldpos;
	string key, value, valuefield, valueoffset, valueoffsetrandom;
	entity valueent;
	vector data, data2;

	n = tokenize_console(msg);

	for(i = 0; i < n-1; i += 2)
	{
		key = argv(i);
		value = argv(i+1);
		if(key == "$")
		{
			data.x = -1;
			data.y = FIELD_STRING;
		}
		else
		{
			data = stov(db_get(TemporaryDB, strcat("/target_spawn/field/", key)));
			if(data.y == 0) // undefined field, i.e., invalid type
			{
				LOG_INFO("target_spawn: invalid/unknown entity key ", key, " specified, ignored!");
				continue;
			}
		}
		if(substring(value, 0, 1) == "$")
		{
			value = substring(value, 1, strlen(value) - 1);
			if(substring(value, 0, 1) == "$")
			{
				// deferred replacement
				// do nothing
				// useful for creating target_spawns with this!
			}
			else
			{
				// replace me!
				valuefieldpos = strstrofs(value, "+", 0);
				valueoffset = "";
				if(valuefieldpos != -1)
				{
					valueoffset = substring(value, valuefieldpos + 1, strlen(value) - valuefieldpos - 1);
					value = substring(value, 0, valuefieldpos);
				}

				valuefieldpos = strstrofs(valueoffset, "+", 0);
				valueoffsetrandom = "";
				if(valuefieldpos != -1)
				{
					valueoffsetrandom = substring(valueoffset, valuefieldpos + 1, strlen(valueoffset) - valuefieldpos - 1);
					valueoffset = substring(valueoffset, 0, valuefieldpos);
				}

				valuefieldpos = strstrofs(value, ".", 0);
				valuefield = "";
				if(valuefieldpos != -1)
				{
					valuefield = substring(value, valuefieldpos + 1, strlen(value) - valuefieldpos - 1);
					value = substring(value, 0, valuefieldpos);
				}

				if(value == "self")
				{
					valueent = this;
					value = "";
				}
				else if(value == "activator")
				{
					valueent = act;
					value = "";
				}
				else if(value == "other")
				{
					valueent = trigger;
					value = "";
				}
				else if(value == "pusher")
				{
					if(time < act.pushltime)
						valueent = act.pusher;
					else
						valueent = NULL;
					value = "";
				}
				else if(value == "target")
				{
					valueent = e;
					value = "";
				}
				else if(value == "killtarget")
				{
					valueent = kt;
					value = "";
				}
				else if(value == "target2")
				{
					valueent = t2;
					value = "";
				}
				else if(value == "target3")
				{
					valueent = t3;
					value = "";
				}
				else if(value == "target4")
				{
					valueent = t4;
					value = "";
				}
				else if(value == "time")
				{
					valueent = NULL;
					value = ftos(time);
				}
				else
				{
					LOG_INFO("target_spawn: invalid/unknown variable replacement ", value, " specified, ignored!");
					continue;
				}

				if(valuefield == "")
				{
					if(value == "")
						value = ftos(etof(valueent));
				}
				else
				{
					if(value != "")
					{
						LOG_INFO("target_spawn: try to get a field of a non-entity, ignored!");
						continue;
					}
					data2 = stov(db_get(TemporaryDB, strcat("/target_spawn/field/", valuefield)));
					if(data2_y == 0) // undefined field, i.e., invalid type
					{
						LOG_INFO("target_spawn: invalid/unknown entity key replacement ", valuefield, " specified, ignored!");
						continue;
					}
					value = getentityfieldstring(data2_x, valueent);
				}

				if(valueoffset != "")
				{
					switch(data.y)
					{
						case FIELD_STRING:
							value = strcat(value, valueoffset);
							break;
						case FIELD_FLOAT:
							value = ftos(stof(value) + stof(valueoffset));
							break;
						case FIELD_VECTOR:
							value = vtos(stov(value) + stov(valueoffset));
							break;
						default:
							LOG_INFO("target_spawn: only string, float and vector fields can do calculations, calculation ignored!");
							break;
					}
				}

				if(valueoffsetrandom != "")
				{
					switch(data.y)
					{
						case FIELD_FLOAT:
							value = ftos(stof(value) + random() * stof(valueoffsetrandom));
							break;
						case FIELD_VECTOR:
							data2 = stov(valueoffsetrandom);
							value = vtos(stov(value) + random() * data2_x * '1 0 0' + random() * data2_y * '0 1 0' + random() * data2_z * '0 0 1');
							break;
						default:
							LOG_INFO("target_spawn: only float and vector fields can do random calculations, calculation ignored!");
							break;
					}
				}
			}
		}
		if(key == "$")
		{
			if(substring(value, 0, 1) == "_")
				value = strcat("target_spawn_helper", value);
			putentityfieldstring(target_spawn_spawnfunc_field, e, value);

			e.target_spawn_spawnfunc(e);

			// We called an external function, so we have to re-tokenize msg.
			n = tokenize_console(msg);
		}
		else
		{
			if(data.y == FIELD_VECTOR)
				value = strreplace("'", "", value); // why?!?
			putentityfieldstring(data.x, e, value);
		}
	}
}

void target_spawn_useon(entity e, entity this, entity actor, entity trigger)
{
	this.target_spawn_activator = actor;
	target_spawn_edit_entity(
		this,
		e,
		this.message,
		find(NULL, targetname, this.killtarget),
		find(NULL, targetname, this.target2),
		find(NULL, targetname, this.target3),
		find(NULL, targetname, this.target4),
		actor,
		trigger
	);
}

bool target_spawn_cancreate(entity this)
{
	float c;
	entity e;

	c = this.count;
	if(c == 0) // no limit?
		return true;

	++c; // increase count to not include MYSELF
	for(e = NULL; (e = findfloat(e, target_spawn_id, this.target_spawn_id)); --c)
		;

	// if c now is 0, we have AT LEAST the given count (maybe more), so don't spawn any more
	if(c == 0)
		return false;
	return true;
}

void target_spawn_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;
	if(this.target == "")
	{
		// spawn new entity
		if(!target_spawn_cancreate(this))
			return;
		entity e = spawn();
		e.spawnfunc_checked = true;
		target_spawn_useon(e, this, actor, trigger);
		e.target_spawn_id = this.target_spawn_id;
	}
	else if(this.target == "*activator")
	{
		// edit entity
		if(actor)
			target_spawn_useon(actor, this, actor, trigger);
	}
	else
	{
		// edit entity
		FOREACH_ENTITY_STRING(targetname, this.target,
		{
			target_spawn_useon(it, this, actor, trigger);
		});
	}
}

void target_spawn_spawnfirst(entity this)
{
	entity act = this.target_spawn_activator;
	if(this.spawnflags & ON_MAPLOAD)
		target_spawn_use(this, act, NULL);
}

void initialize_field_db()
{
	if(!target_spawn_initialized)
	{
		float n, i;
		string fn;
		vector prev, next;
		float ft;

		n = numentityfields();
		for(i = 0; i < n; ++i)
		{
			fn = entityfieldname(i);
			ft = entityfieldtype(i);
			next = i * '1 0 0' + ft * '0 1 0' + '0 0 1';
			prev = stov(db_get(TemporaryDB, strcat("/target_spawn/field/", fn)));
			if(prev.y == 0)
			{
				db_put(TemporaryDB, strcat("/target_spawn/field/", fn), vtos(next));
				if(fn == "target_spawn_spawnfunc")
					target_spawn_spawnfunc_field = i;
			}
		}

		target_spawn_initialized = 1;
	}
}

void target_spawn_reset(entity this)
{
	// TODO call "spawn first" again?
	this.active = ACTIVE_ACTIVE;
}

spawnfunc(target_spawn)
{
	initialize_field_db();
	this.use = target_spawn_use;
	this.active = ACTIVE_ACTIVE;
	this.reset = target_spawn_reset;
	this.message = strzone(strreplace("'", "\"", this.message));
	this.target_spawn_id = ++target_spawn_count;
	InitializeEntity(this, target_spawn_spawnfirst, INITPRIO_LAST);
}
#endif
