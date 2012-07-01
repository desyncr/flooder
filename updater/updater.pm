package Updater;
use HTML::TreeBuilder;
use HTTP::Request::Common;
use LWP;
use db::DBProxy;
use debug::Debug;

sub new
{
    my ($class, @rsrc) = @_;
    my $self = {
        rsrc => @rsrc,
        debug => new Debug('update', 1)
    };
    bless $self, $class;
    return $self;
}

sub updateDb
{
    my ($self) = @_;
    
    $self->{debug}->log('Updater started');
    my $counter = 0;
    my $db = new DBProxy('data','proxies');
    
    for $i (0..2)
    {
        $self->{debug}->log('Retrieving proxy list from: ' . $self->{rsrc}[$i]);
        $ua = LWP::UserAgent->new;
        $response = $ua->request(GET $self->{rsrc}[$i]);
        $self->{debug}->log("Resource response: " . $response->status_line);
        return 0 unless ( $response->status_line =~ "^200" );

        $tree = HTML::TreeBuilder->new_from_content($response->decoded_content);

        @elements = $tree->find('td');

        my ($ip, $port, $gotIP, $gotPort) = 0;
        foreach my $i (0..$#elements) {
            @c = $elements[$i]->content_list;

            # xxx.xxx.xxx.xxx:xxxx
            if ($c[0] =~ m/((\d{1,3}\.){3}\d{1,3})\:(\d{2,4})/)
            {
                $ip = $1; $port = $3;
                $gotIP = 1; $gotPort = 1;
            }
            
            if ($gotIP == 0){
                # xxx.xxx.xxx.xxx
                if ($c[0] =~ m/((\d{1,3}\.){3}\d{1,3})/){
                    $ip = $1;
                    $gotIP = 1;
                }
            }
            
            if ($gotPort == 0)
            {
                # xxxx
                if ($c[0] =~ m/(\d{2,4})/)
                {
                    $port = $1;
                    $gotPort = 1;
                }
            }
            if ($gotIP == 1 && $gotPort == 1)
            {
                $self->{debug}->log('Added proxy: ' . $ip . ':' . $port);
                $db->addProxy(ip => $ip, port => $port);
                $counter++;
                $gotIP = 0; $gotPort = 0;
            }
        }
        $tree->delete;
    }
    $self->{debug}->log('Updater task ended: ' . $counter . ' proxys added.');
    return $counter;
}
1;
