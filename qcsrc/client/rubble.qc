#include "rubble.qh"

// LordHavoc: rewrote this file, it was really bad code

void RubbleLimit(string cname, float limit, void() deleteproc)
{SELFPARAM();
	entity e;
	entity oldest;
	float c;
	float oldesttime;

	// remove rubble of the same type if it's at the limit
	// remove multiple rubble if the limit has been decreased
	while(1)
	{
		e = findchain(classname,cname);
		if (e == world)
			break;
		// walk the list and count the entities, find the oldest
		// initialize our search with the first entity
		c = 1;
		oldest = e;
		oldesttime = e.creationtime;
		e = e.chain;
		// compare to all other matching entities
		while (e)
		{
			c = c + 1;
			if (oldesttime > e.creationtime)
			{
				oldesttime = e.creationtime;
				oldest = e;
			}
			e = e.chain;
		}

		// stop if there are less than the limit already
		if (c <= limit)
			break;

		// delete this oldest one and search again
		WITH(entity, self, oldest, deleteproc());
	}
}

entity RubbleNew(string cname)
{
	entity e;
	// spawn a new entity and return it
	e = spawn();
	e.classname = cname;
	e.creationtime = time;
	return e;
}
