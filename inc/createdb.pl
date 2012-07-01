use DBI;

$dbi = DBI->connect("dbi:SQLite:../data.db") || die "Failed to open database: $dbi->errstr";

$dbi->do("CREATE TABLE IF NOT EXISTS proxies (ip, port, secure, banned, checked, lastCheck, up, lastUp );");
$dbi->do("CREATE TABLE IF NOT EXISTS stats ( 'name', value );");

$dbi->do("INSERT INTO stats (name, value) VALUES('started', 0)");
$dbi->do("INSERT INTO stats (name, value) VALUES('lastTry', 0)");
$dbi->do("INSERT INTO stats (name, value) VALUES('lastPost', 0)");
$dbi->do("INSERT INTO stats (name, value) VALUES('totalPosts', 0)");
$dbi->do("INSERT INTO stats (name, value) VALUES('totalFailed', 0)");
$dbi->do("INSERT INTO stats (name, value) VALUES('totalCaptchas', 0)");