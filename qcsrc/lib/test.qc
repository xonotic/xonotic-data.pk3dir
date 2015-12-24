#include "test.qh"

int TEST_failed;
bool TEST_ok;

void TEST_Fail(string cond)
{
	LOG_INFOF("Assertion failed: ", cond);
	// backtrace();
	++TEST_failed;
}

void TEST_OK()
{
	TEST_ok = true;
}

int TEST_RunAll_accumulated(int init);
bool TEST_RunAll()
{
	int f = TEST_RunAll_accumulated(0);
	if (f)
	{
		LOG_INFOF("%d tests failed\n", f);
		return true;
	}
	else
	{
		LOG_INFO("All tests OK\n");
		return false;
	}
}

bool TEST_Run(string s)
{
	LOG_INFOF("%s: testing...\n", s);
	TEST_failed = 0;
	TEST_ok = false;
	callfunction(strcat("_TEST_", s));
	if (TEST_failed > 0)
	{
		LOG_INFOF("%s: %d items failed.\n", s, TEST_failed);
		return false;
	}
	else if (!TEST_ok)
	{
		LOG_INFOF("%s: did not complete.\n", s);
		return false;
	}
	return true;
}
