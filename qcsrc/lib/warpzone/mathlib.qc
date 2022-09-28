#include "mathlib.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
#endif

int fpclassify(float e)
{
	if(isnan(e))
		return FP_NAN;
	if(isinf(e))
		return FP_INFINITE;
	if(e == 0)
		return FP_ZERO;
	return FP_NORMAL;
}
bool isfinite(float e)
{
	return !(isnan(e) || isinf(e));
}
bool isinf(float e)
{
	return (e != 0) && (e + e == e);
}
bool isnan(float e)
{
	// The sane way to detect NaN is this:
	// float f = e;
	// return (e != f);
	// but darkplaces used to be compiled with -ffinite-math-only which broke it.
	// DP is fixed now but until all clients update (so after 0.8.3) we have to use the following workaround
	// or they'd have issues when connecting to newer servers.

	// Negative NaN ("-nan") is much more common but plain "nan" can be created by negating *some* -nans so we need to check both.
	// DP's QCVM and GMQCC's QCVM behave differently - one needs ftos(-(0.0 / 0.0)), the other ftos(-sqrt(-1)).
	string s = ftos(e);
	return s == "nan" || s == "-nan";
}
bool isnormal(float e)
{
	return isfinite(e);
}
bool signbit(float e)
{
	return (e < 0);
}

float acosh(float e)
{
	return log(e + sqrt(e*e - 1));
}
float asinh(float e)
{
	return log(e + sqrt(e*e + 1));
}
float atanh(float e)
{
	return 0.5 * log((1+e) / (1-e));
}
float cosh(float e)
{
	return 0.5 * (exp(e) + exp(-e));
}
float sinh(float e)
{
	return 0.5 * (exp(e) - exp(-e));
}
float tanh(float e)
{
	return sinh(e) / cosh(e);
}

float exp(float e)
{
	return pow(M_E, e);
}
float exp2(float e)
{
	return pow(2, e);
}
float expm1(float e)
{
	return exp(e) - 1;
}

vector frexp(float e)
{
	vector v;
	v.z = 0;
	v.y = ilogb(e) + 1;
	v.x = e / pow(2, v.y);
	return v;
}
int ilogb(float e)
{
	return floor(log2(fabs(e)));
}
float ldexp(float x, int e)
{
	return x * pow(2, e);
}
float logn(float e, float base)
{
	return log(e) / log(base);
}
float log10(float e)
{
	return log(e) * M_LOG10E;
}
float log1p(float e)
{
	return log(e + 1);
}
float log2(float e)
{
	return log(e) * M_LOG2E;
}
float logb(float e)
{
	return floor(log2(fabs(e)));
}
vector modf(float f)
{
	return '1 0 0' * (f - trunc(f)) + '0 1 0' * trunc(f);
}

float scalbn(float e, int n)
{
	return e * pow(2, n);
}

float cbrt(float e)
{
	return copysign(pow(fabs(e), (1.0/3.0)), e);
}
float hypot(float e, float f)
{
	return sqrt(e*e + f*f);
}

float erf(float e)
{
	// approximation taken from wikipedia
	float f;
	f = e*e;
	return copysign(sqrt(1 - exp(-f * (1.273239544735163 + 0.14001228868667 * f) / (1 + 0.14001228868667 * f))), e);
}
float erfc(float e)
{
	return 1.0 - erf(e);
}
vector lgamma(float e)
{
	// TODO improve accuracy
	if(!isfinite(e))
		return fabs(e) * '1 0 0' + copysign(1, e) * '0 1 0';
	if(e < 1 && e == floor(e))
		return nan("gamma") * '1 1 1';
	if(e < 0.1)
	{
		vector v;
		v = lgamma(1.0 - e);
		// reflection formula:
		// gamma(1-z) * gamma(z) = pi / sin(pi*z)
		// lgamma(1-z) + lgamma(z) = log(pi) - log(sin(pi*z))
		// sign of gamma(1-z) = sign of gamma(z) * sign of sin(pi*z)
		v.z = sin(M_PI * e);
		v.x = log(M_PI) - log(fabs(v.z)) - v.x;
		if(v.z < 0)
			v.y = -v.y;
		v.z = 0;
		return v;
	}
	if(e < 1.1)
		return lgamma(e + 1) - log(e) * '1 0 0';
	e -= 1;
	return (0.5 * log(2 * M_PI * e) + e * (log(e) - 1)) * '1 0 0' + '0 1 0';
}
float tgamma(float e)
{
	vector v = lgamma(e);
	return exp(v.x) * v.y;
}

/**
 * Pythonic mod:
 * TODO: %% operator?
 *
 *  1 %  2 ==  1
 * -1 %  2 ==  1
 *  1 % -2 == -1
 * -1 % -2 == -1
 */
float pymod(float e, float f)
{
	return e - f * floor(e / f);
}

float nearbyint(float e)
{
	return rint(e);
}
float trunc(float e)
{
	return (e>=0) ? floor(e) : ceil(e);
}

float fmod(float e, float f)
{
	return e - f * trunc(e / f);
}
float remainder(float e, float f)
{
	return e - f * rint(e / f);
}
vector remquo(float e, float f)
{
	vector v;
	v.z = 0;
	v.y = rint(e / f);
	v.x = e - f * v.y;
	return v;
}

float copysign(float e, float f)
{
	return fabs(e) * ((f>0) ? 1 : -1);
}

float nan(string tag)
{
	return sqrt(-1);
}
float nextafter(float e, float f)
{
	// TODO very crude
	if(e == f)
		return nan("nextafter");
	if(e > f)
		return -nextafter(-e, -f);
	// now we know that e < f
	// so we need the next number > e
	float d, a, b;
	d = max(fabs(e), 0.00000000000000000000001);
	a = e + d;
	do
	{
		d *= 0.5;
		b = a;
		a = e + d;
	}
	while(a != e);
	return b;
}
float nexttoward(float e, float f)
{
	return nextafter(e, f);
}

float fdim(float e, float f)
{
	return max(e-f, 0);
}
float fmax(float e, float f)
{
	return max(e, f);
}
float fmin(float e, float f)
{
	return min(e, f);
}
float fma(float e, float f, float g)
{
	return e * f + g;
}

int isgreater(float e, float f)
{
	return e > f;
}
int isgreaterequal(float e, float f)
{
	return e >= f;
}
int isless(float e, float f)
{
	return e < f;
}
int islessequal(float e, float f)
{
	return e <= f;
}
int islessgreater(float e, float f)
{
	return e < f || e > f;
}
int isunordered(float e, float f)
{
	return !(e < f || e == f || e > f);
}
