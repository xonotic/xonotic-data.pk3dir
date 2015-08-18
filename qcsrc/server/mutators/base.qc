#include "base.qh"
#include "../_all.qh"

.bool() cbc_func;
.entity cbc_next;
.int cbc_order;

entity CallbackChain_New(string name)
{
	entity e = spawn();
	e.classname = "callbackchain";
	e.netname = name;
	return e;
}

bool CallbackChain_Add(entity cb, bool() func, int order)
{
	if (order & CBC_ORDER_FIRST) {
		if (order & CBC_ORDER_LAST)
			if (cb.cbc_order & CBC_ORDER_ANY)
				return false;
		if (cb.cbc_order & CBC_ORDER_FIRST)
			return false;
	} else if (order & CBC_ORDER_LAST) {
		if (cb.cbc_order & CBC_ORDER_LAST)
			return false;
	}
	entity thiscb = spawn();
	thiscb.classname = "callback";
	thiscb.cbc_func = func;
	thiscb.cbc_order = order;
	if (order & CBC_ORDER_FIRST) {
		thiscb.cbc_next = cb.cbc_next;
		cb.cbc_next = thiscb;
	} else if (order & CBC_ORDER_LAST) {
		entity e = cb;
		while (e.cbc_next) e = e.cbc_next;
		e.cbc_next = thiscb;
	} else {
		// by default we execute last, but before a possible CBC_ORDER_LAST callback
		entity e = cb;
		// we must make sure that we insert BEFORE an CBC_ORDER_LAST mutator!
		while (e.cbc_next && !(e.cbc_next.cbc_order & CBC_ORDER_LAST)) e = e.cbc_next;
		thiscb.cbc_next = e.cbc_next;
		e.cbc_next = thiscb;
	}
	cb.cbc_order |= (order | CBC_ORDER_ANY);
	return true;
}

int CallbackChain_Remove(entity cb, bool() func)
{
	int n = 0, order = 0;
	for (entity e = cb; e.cbc_next; e = e.cbc_next) {
		while (e.cbc_next.cbc_func == func) {
			// remove e.cbc_next from the chain
			entity e2 = e.cbc_next.cbc_next;
			remove(e.cbc_next);
			e.cbc_next = e2;
			++n;
		}
		// e.cbc_next is now something we want to keep
		order |= (e.cbc_next.cbc_order & CBC_ORDER_ANY);
	}
	cb.cbc_order = order;
	return n;
}

bool CallbackChain_Call(entity cb)
{
	bool r = false;
	for (entity e = cb; e.cbc_next; e = e.cbc_next) {
		CallbackChain_ReturnValue = r;
		r |= e.cbc_next.cbc_func();
	}
	return r; // callbacks return an error status, so 0 is default return value
}

const int MAX_MUTATORS = 15;
string loaded_mutators[MAX_MUTATORS];
bool Mutator_Add(mutatorfunc_t func, string name)
{
	int j = -1;
	for (int i = 0; i < MAX_MUTATORS; ++i) {
		if (name == loaded_mutators[i])
			return true; // already added
		if (!(loaded_mutators[i]))
			j = i;
	}
	if (j < 0) {
		backtrace("WARNING: too many mutators, cannot add any more\n");
		return false;
	}
	loaded_mutators[j] = name;

	if (!func(MUTATOR_ADDING)) {
		// good
		return true;
	}

	backtrace("WARNING: when adding mutator: adding failed, rolling back\n");

	if (func(MUTATOR_ROLLING_BACK)) {
		// baaaaad
		error("WARNING: when adding mutator: rolling back failed");
	}
	return false;
}
void Mutator_Remove(mutatorfunc_t func, string name)
{
	int i;
	for (i = 0; i < MAX_MUTATORS; ++i)
		if (name == loaded_mutators[i])
			break;
	if (i >= MAX_MUTATORS) {
		backtrace("WARNING: removing not-added mutator\n");
		return;
	}
	loaded_mutators[i] = string_null;

	if (func(MUTATOR_REMOVING) != 0) {
		// baaaaad
		error("Mutator_Remove: removing mutator failed");
	}
}
