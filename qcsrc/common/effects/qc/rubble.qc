#include "rubble.qh"

#ifdef GAMEQC

void LimitedChildrenRubble(IntrusiveList list, string cname, int limit, void(entity) deleteproc, entity parent){
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
		IL_EACH(list, it.classname == cname,
		{
			if(!parent || parent == it.owner){
				++c;
				if(!oldest || oldesttime > it.creationtime)
				{
					oldest = it;
					oldesttime = it.creationtime;
				}
			}
		});

		// stop if there are less than the limit already
		if (c <= limit) break;

		// delete this oldest one and search again
		deleteproc(oldest);
	}
}


// This function doesn't preserve linked list order but it is not needed as creationtime is used instead of list position for comparing ages.
// IL_Replace or similiar order preserving function did not exist at the time of creating this.
entity ReplaceOldListedChildRubble(IntrusiveList list, entity child, entity oldChild){
	child.creationtime = oldChild.creationtime;
	IL_REMOVE(list, oldChild);
	IL_PUSH(list, child);
	return child;
}

entity ListNewChildRubble(IntrusiveList list, entity child){
	child.creationtime = time;
	IL_PUSH(list, child);
	return child;
}

#endif
