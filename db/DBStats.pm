package DBStats;
use db::Database;
our @ISA = qw(Database);

sub new
{
    my ($class, $database, $table) = @_;
    
    my $self = $class->SUPER::new($database, $table);
    
    bless $self, $class;
    return $self;
}

sub setStat
{
    my ($self, $name, $value) = @_;
    $self->update("value='$value'", "name='$name'");
    
}

sub getStat
{
    my ($self, $name) = @_;
    return $self->select(q(value), "name='$name'", "name", 1);
}

sub getStats
{
    my ($self) = @_;
    my $res = $self->select(q(name, value),"name!=''", "name",10);

    foreach (@$res)
    {
        $stats{$_->[0]} = $_->[1];
    }
    return %stats;

}

1;
