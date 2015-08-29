#include "test.qh"

float TEST_failed;
float TEST_ok;

void TEST_Fail(string cond)
{
	LOG_INFOF("Assertion failed: ", cond);
	//backtrace();
	++TEST_failed;
}

void TEST_OK()
{
	TEST_ok = true;
}

float TEST_RunAll()
{
	int f = 0;
	float n = numentityfields();
	for(int i = 0; i < n; ++i)
	{
		string name = entityfieldname(i);
		if(substring(name, 0, 6) == "_TEST_")
			if(!TEST_Run(substring(name, 6, -1)))
				++f;
	}
	if(f)
	{
		LOG_INFOF("%d tests failed\n", f);
		return 1;
	}
	else
	{
		LOG_INFOF("All tests OK\n", f);
		return 0;
	}
}

float TEST_Run(string s)
{
	LOG_INFOF("%s: testing...\n", s);
	TEST_failed = TEST_ok = 0;
	callfunction(strcat("_TEST_", s));
	if(TEST_failed > 0)
	{
		LOG_INFOF("%s: %d items failed.\n", s, TEST_failed);
		return 0;
	}
	else if(!TEST_ok)
	{
		LOG_INFOF("%s: did not complete.\n", s);
		return 0;
	}
	return 1;
}
