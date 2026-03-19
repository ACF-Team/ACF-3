DROP TABLE IF EXISTS DupeData;
DROP TABLE IF EXISTS PackData;

CREATE TABLE PackData (
    packid TEXT PRIMARY KEY,
    packname TEXT NOT NULL,
    author TEXT,
    contact TEXT
);

CREATE TABLE DupeData (
    dupeid INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT NOT NULL,
    name TEXT,
    cost REAL,
    weight REAL,
    type TEXT,
    mobility TEXT,
    packid TEXT REFERENCES PackData(packid) ON DELETE SET NULL,
    description TEXT
);