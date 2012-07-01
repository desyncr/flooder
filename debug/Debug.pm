package Debug;

sub new
{
    my ($class, $logfile, $verbosity) = @_;
    open(DEBUG, ">>$logfile") or die $!;
    my $self = {
        logfile  => $logfile,
        verbosity => $verbosity,
        handle => $logfile
    };

    bless $self, $class;
    return $self;
}

sub log
{
    my ($self, $message) = @_;
    #[ Fri Nov 4 04:10:47 2011 ] Connecting through 127.0.0.1:80
    $message = '[ ' . scalar localtime(time()) . ' ] ' . $message . "\n";

    if ($self->{verbosity} >= 1)
    {
        print $message;
    }
    
    print DEBUG $message;

}

1;
