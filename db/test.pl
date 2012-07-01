use DBProxy;
$db = new DBProxy('data', 'proxies');

$db->removeProxy('ip="127.0.0.2"');

$proxies = $db->getProxyList();
#$proxies = $db->{dbi}->selectall_arrayref("select * from proxies");

foreach (@$proxies)
{
    print $_->[0] . ':', $_->[1]."\n";
}

#$db->addProxy((ip=>'127.0.0.1', port=>80));
#$db->addProxy((ip=>'127.0.0.1', port=>81));
#$db->addProxy((ip=>'127.0.0.1', port=>82));


#use DBStats;
#$db = new DBStats('data','stats');
#$failed = $db->getStat('failed')->[0][0];
#$db->setStat('failed', ++$failed);


