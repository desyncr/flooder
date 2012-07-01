package Image;
use GD;
use POSIX;

sub new
{
    my ($class, $filename, $maxHeight, $maxWidth) = @_;
    my $self = {
        filename => $filename,
        maxHeight => $maxHeight,
        maxWidth => $maxWidth
    };
    
    bless $self, $class;
    return $self
}

sub create
{
    my ($self) = @_;
    open(IMG, ">$self->{filename}.png") or return 0;
    
    my $img;
    $img = new GD::Image(
        floor(rand($self->{maxHeight})+1),
        floor(rand($self->{maxWidth})+1)
        );

    $img->fill(0, 0, 
            $img->colorAllocate(
                floor(rand(256)),
                floor(rand(256)),
                floor(rand(256))

            )
        );

    binmode IMG;
    print IMG $img->png;
    close(IMG);
    
    return $self;
}


1;