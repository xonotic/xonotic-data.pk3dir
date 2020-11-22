#include "rubble.qh"

#ifdef GAMEQC
void RubbleLimit(string cname, int limit, void(entity) deleteproc)
{
	// remove rubble of the same type if it's at the limit
	// remove multiple rubble if the limit has been decreased
	while (1)
	{
		// walk the list and count the entities, find the oldest
		// initialize our search with the first entity
		int c = 0;
		entity oldest = NULL;
		float oldesttime = 0;
		// compare to all other matching entities
		IL_EACH(g_rubble, it.classname == cname,
		{
			++c;
			if(!oldest || oldesttime > it.creationtime)
			{
				oldest = it;
				oldesttime = it.creationtime;
			}
		});

		// stop if there are less than the limit already
		if (c <= limit) break;

		// delete this oldest one and search again
		deleteproc(oldest);
	}
}

entity RubbleNew(entity e)
{
	e.creationtime = time;
	IL_PUSH(g_rubble, e);
	return e;
}
#endif
