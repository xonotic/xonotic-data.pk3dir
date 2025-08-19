#include "random.qh"

ERASEABLE
void RandomSelection_Init()
{
	RandomSelection_totalweight = 0;
	RandomSelection_chosen_ent = NULL;
	RandomSelection_chosen_float = 0;
	RandomSelection_chosen_string = string_null;
	RandomSelection_best_priority = -1;
}

ERASEABLE
void RandomSelection_Add(entity e, float f, string s, vector v, float weight, float priority)
{
	if (priority > RandomSelection_best_priority)
	{
		RandomSelection_best_priority = priority;
		RandomSelection_chosen_ent = e;
		RandomSelection_chosen_float = f;
		RandomSelection_chosen_string = s;
		RandomSelection_chosen_vec = v;
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
			RandomSelection_chosen_vec = v;
		}
	}
}

float DistributeEvenly_amount;
float DistributeEvenly_totalweight;

ERASEABLE
void DistributeEvenly_Init(float amount, float totalweight)
{
	if (DistributeEvenly_amount)
		LOG_TRACE("DistributeEvenly_Init: UNFINISHED DISTRIBUTION (", ftos(DistributeEvenly_amount),
			" for ", ftos(DistributeEvenly_totalweight), " left!)");
	DistributeEvenly_amount = (totalweight) ? amount : 0;
	DistributeEvenly_totalweight = totalweight;
}

ERASEABLE
float DistributeEvenly_Get(float weight)
{
	if (weight <= 0)
		return 0;
	float f = DistributeEvenly_amount * weight / DistributeEvenly_totalweight;
	DistributeEvenly_totalweight -= weight;
	DistributeEvenly_amount -= f;
	return f;
}

ERASEABLE
float DistributeEvenly_GetRounded(float weight)
{
	if (weight <= 0)
		return 0;
	float f = floor(0.5 + DistributeEvenly_amount * weight / DistributeEvenly_totalweight);
	DistributeEvenly_totalweight -= weight;
	DistributeEvenly_amount -= f;
	return f;
}

ERASEABLE
float DistributeEvenly_GetRandomized(float weight)
{
	if (weight <= 0)
		return 0;
	float f = floor(random() + DistributeEvenly_amount * weight / DistributeEvenly_totalweight);
	DistributeEvenly_totalweight -= weight;
	DistributeEvenly_amount -= f;
	return f;
}

ERASEABLE
/// Returns a Gaussian random variate, with mean zero and standard deviation sigma 1
/// From the GNU Scientific Library
float gsl_ran_ugaussian()
{
	static float lastvalue;
	static bool lastvalue_set;
	if (lastvalue_set)
	{
		lastvalue_set = false;
		return lastvalue;
	}

	const float a = random() * (2 * M_PI);
	const float b = sqrt(-2 * log(random()));
	lastvalue = cos(a) * b;
	lastvalue_set = true;
	return sin(a) * b;
}


#ifdef USE_PRANDOM
	float prandom_seed;
	/// Predictable random number generator (not seeded yet)
	float prandom()
	{
		float c;
		c = crc16(false, strcat(ftos(prandom_seed), ftos(prandom_seed + M_PI)));
		prandom_seed = c;

	#ifdef USE_PRANDOM_DEBUG
			LOG_TRACE("RANDOM -> ", ftos(c));
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
			LOG_TRACE("SRANDOM ", ftos(seed));
	#endif
	}

	#ifdef USE_PRANDOM_DEBUG
		void prandom_debug()
		{
			LOG_TRACE("Current random seed = ", ftos(prandom_seed));
		}
	#endif
#endif
