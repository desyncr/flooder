package DBProxy;
use db::Database;
our @ISA = qw(Database);

sub new
{
    my ($class, $database, $table) = @_;
    
    my $self = $class->SUPER::new($database, $table);
    
    bless $self, $class;
    return $self;
}

sub getProxyList 
{
    my ($self, $where, $order) = @_;
    $self->getProxy($where, $order, 100);
}

sub getProxy
{
    my ($self, $where, $order, $limit) = @_;
    $where = "banned='0'" if $where == undef;
    $order = "RANDOM()" if $order == undef;
    $limit = 1 if $limit == undef;
    $self->select(q(ip,port,secure),  $where, $order, $limit);    
}

## Add and remove
sub addProxy {
    my ($self, %values) = @_;
    
    $self->insert(
            (ip=>$values{ip}, port=>$values{port}, secure => 0, banned => 0, checked => 0, lastCheck => 0, up => 0, lastUp => 0)
        );
}

sub removeProxy {
    my ($self, $where) = @_;
    
    do {
        $self->delete($where);
        
    }unless (!$where);
}

## Update proxy
sub updateProxy {
    my ($self, $update, $where) = @_;
    
    do {
        $self->update($update, $where)
    } unless (!$where || !$where);
}

########################################################################

1;
