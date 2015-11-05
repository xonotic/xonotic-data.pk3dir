#include "random.qh"

void RandomSelection_Init()
{
	RandomSelection_totalweight = 0;
	RandomSelection_chosen_ent = NULL;
	RandomSelection_chosen_float = 0;
	RandomSelection_chosen_string = string_null;
	RandomSelection_best_priority = -1;
}

void RandomSelection_Add(entity e, float f, string s, float weight, float priority)
{
	if (priority > RandomSelection_best_priority)
	{
		RandomSelection_best_priority = priority;
		RandomSelection_chosen_ent = e;
		RandomSelection_chosen_float = f;
		RandomSelection_chosen_string = s;
		RandomSelection_totalweight = weight;
	}
	else if (priority == RandomSelection_best_priority)
	{
		RandomSelection_totalweight += weight;
		if (random() * RandomSelection_totalweight <= weight)
		{
			RandomSelection_chosen_ent = e;
			RandomSelection_chosen_float = f;
			RandomSelection_chosen_string = s;
		}
	}
}

float DistributeEvenly_amount;
float DistributeEvenly_totalweight;

void DistributeEvenly_Init(float amount, float totalweight)
{
	if (DistributeEvenly_amount)
	{
		LOG_TRACE("DistributeEvenly_Init: UNFINISHED DISTRIBUTION (", ftos(DistributeEvenly_amount), " for ");
		LOG_TRACE(ftos(DistributeEvenly_totalweight), " left!)\n");
	}
	if (totalweight == 0) DistributeEvenly_amount = 0;
	else DistributeEvenly_amount = amount;
	DistributeEvenly_totalweight = totalweight;
}

float DistributeEvenly_Get(float weight)
{
	float f;
	if (weight <= 0) return 0;
	f = floor(0.5 + DistributeEvenly_amount * weight / DistributeEvenly_totalweight);
	DistributeEvenly_totalweight -= weight;
	DistributeEvenly_amount -= f;
	return f;
}

float DistributeEvenly_GetRandomized(float weight)
{
	float f;
	if (weight <= 0) return 0;
	f = floor(random() + DistributeEvenly_amount * weight / DistributeEvenly_totalweight);
	DistributeEvenly_totalweight -= weight;
	DistributeEvenly_amount -= f;
	return f;
}

// prandom - PREDICTABLE random number generator (not seeded yet)

#ifdef USE_PRANDOM
	float prandom_seed;
	float prandom()
	{
		float c;
		c = crc16(false, strcat(ftos(prandom_seed), ftos(prandom_seed + M_PI)));
		prandom_seed = c;

	#ifdef USE_PRANDOM_DEBUG
			LOG_TRACE("RANDOM -> ", ftos(c), "\n");
	#endif

		return c / 65536;  // in [0..1[
	}

	vector prandomvec()
	{
		vector v;

		do
		{
			v.x = prandom();
			v.y = prandom();
			v.z = prandom();
		}
		while (v * v > 1);

		return v;
	}

	void psrandom(float seed)
	{
		prandom_seed = seed;
	#ifdef USE_PRANDOM_DEBUG
			LOG_TRACE("SRANDOM ", ftos(seed), "\n");
	#endif
	}

	#ifdef USE_PRANDOM_DEBUG
		void prandom_debug()
		{
			LOG_TRACE("Current random seed = ", ftos(prandom_seed), "\n");
		}
	#endif
#endif
