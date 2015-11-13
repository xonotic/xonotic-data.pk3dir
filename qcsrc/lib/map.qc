#ifndef MAP_H
#define MAP_H

// Databases (hash tables)
const float DB_BUCKETS = 8192;
void db_save(float db, string pFilename)
{
	int fh = fopen(pFilename, FILE_WRITE);
	if (fh < 0)
	{
		LOG_INFO(strcat("^1Can't write DB to ", pFilename));
		return;
	}
	int n = buf_getsize(db);
	fputs(fh, strcat(ftos(DB_BUCKETS), "\n"));
	for (int i = 0; i < n; ++i)
		fputs(fh, strcat(bufstr_get(db, i), "\n"));
	fclose(fh);
}

int db_create()
{
	return buf_create();
}

void db_put(float db, string pKey, string pValue);

int db_load(string pFilename)
{
	int db = buf_create();
	if (db < 0) return -1;
	int fh = fopen(pFilename, FILE_READ);
	if (fh < 0) return db;
	string l = fgets(fh);
	if (stof(l) == DB_BUCKETS)
	{
		for (int i = 0; (l = fgets(fh)); ++i)
		{
			if (l != "") bufstr_set(db, i, l);
		}
	}
	else
	{
		// different count of buckets, or a dump?
		// need to reorganize the database then (SLOW)
		//
		// note: we also parse the first line (l) in case the DB file is
		// missing the bucket count
		do
		{
			int n = tokenizebyseparator(l, "\\");
			for (int j = 2; j < n; j += 2)
				db_put(db, argv(j - 1), uri_unescape(argv(j)));
		}
		while ((l = fgets(fh)));
	}
	fclose(fh);
	return db;
}

void db_dump(float db, string pFilename)
{
	int fh = fopen(pFilename, FILE_WRITE);
	if (fh < 0) error(strcat("Can't dump DB to ", pFilename));
	int n = buf_getsize(db);
	fputs(fh, "0\n");
	for (int i = 0; i < n; ++i)
	{
		int m = tokenizebyseparator(bufstr_get(db, i), "\\");
		for (int j = 2; j < m; j += 2)
			fputs(fh, strcat("\\", argv(j - 1), "\\", argv(j), "\n"));
	}
	fclose(fh);
}

void db_close(float db)
{
	buf_del(db);
}

string db_get(float db, string pKey)
{
	int h = crc16(false, pKey) % DB_BUCKETS;
	return uri_unescape(infoget(bufstr_get(db, h), pKey));
}

void db_put(float db, string pKey, string pValue)
{
	int h = crc16(false, pKey) % DB_BUCKETS;
	bufstr_set(db, h, infoadd(bufstr_get(db, h), pKey, uri_escape(pValue)));
}

void db_test()
{
	LOG_INFO("LOAD...\n");
	int db = db_load("foo.db");
	LOG_INFO("LOADED. FILL...\n");
	for (int i = 0; i < DB_BUCKETS; ++i)
		db_put(db, ftos(random()), "X");
	LOG_INFO("FILLED. SAVE...\n");
	db_save(db, "foo.db");
	LOG_INFO("SAVED. CLOSE...\n");
	db_close(db);
	LOG_INFO("CLOSED.\n");
}

#endif
