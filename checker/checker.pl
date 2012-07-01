use HTTP::Request::Common;
use LWP;
use DBProxy;

$rsrc = 'http://devl.com.ar/proxy-checker';
# above url *should* accepts incomming connections from your own IP
# and return 404 not found otherwise

$ua = LWP::UserAgent->new;
$response = $ua->request(GET $rsrc);
die unless ( $response->status_line =~ "^200" );

$db = new DBProxy('data','proxies');
@list = split(/\n/, $response->decoded_content);

foreach (@list)
{
    if ($c[0] =~ m/((\d{1,3}\.){3}\d{1,3})\:(\d{2,4})/)
    {
        #print $1 . ':' . $2 . "\n";
        $db->updateProxy('secure="1"',"ip='$1' AND port='$3'");
    }
}
$tree->delete;