package Captcha;
use LWP::UserAgent;
use strict;
use warnings;

sub new
{
	my ($class, $apikey) = @_;
	
	my $self = {
		api => $apikey,
		config => {
			constants => {
				recaptchaUrl => 'http://www.google.com/recaptcha/api/',
				recaptcha => 'http://www.google.com/recaptcha/api/noscript?k=',
				captchaLocalFileName => 'captcha.jpg',
				captchaImgRegExp => '<img width="300" height="57" alt="" src="(.+)">',
				captchaChallengeField => '<input type="hidden" name="recaptcha_challenge_field" id="recaptcha_challenge_field" value="(.+)">',
				captchaConfirmationField => '<textarea rows="5" cols="100">(.+)<\/textarea>',
				submit => 'I\'m a human'
			}
		}
	};
	
	bless $self, $class;
	return $self;
}

# Get the captcha image at the $captchaurl url (get the html then parse for the image)
#	- $response = $ua->get($captchaurl);
#	- $response->decoded_content =~ //;
#	- $ua->mirror($1, 'image.jpg');

sub getConfirmation
{
	my ($self) = @_;

	my $ua 		= LWP::UserAgent->new();
	my $response 	= $ua->get($self->{config}{constants}{recaptcha} . $self->{api});
	
	my ($captchaImgUrl, $captchaChallengeField) = '';

	if ($response->is_success) # Could get the recaptcha no-script page
	{
		if ($response->decoded_content =~ /$self->{config}{constants}{captchaImgRegExp}/)
		{
			$captchaImgUrl = $self->{config}{constants}{recaptchaUrl} . $1;
		}else{
			return -2; # could not get captcha image url out of the html (bad reg exp?)
		}
	
		if ($response->decoded_content =~ /$self->{config}{constants}{captchaChallengeField}/)
		{
			$captchaChallengeField = $1;
		}else{
			return -3; # could not get challenge field value
		}
		
		$ua->mirror($captchaImgUrl, $self->{config}{constants}{captchaLocalFileName});
		system ($self->{config}{constants}{captchaLocalFileName});
	
		my $words = <STDIN>;
		chomp($words);
	
		$response = $ua->post(
			$self->{config}{constants}{recaptcha} . $self->{api},
			Content_Type => 'form-data',
			Content => [
				recaptcha_challenge_field => $captchaChallengeField,
				recaptcha_response_field => $words,
				submit => $self->{constants}{submit}
			]
		);
	
		if ($response->is_success)	# Valid captcha
		{
			if ($response->decoded_content =~ /$self->{config}{constants}{captchaConfirmationField}/)
			{
				return $1;
			}else{
				return -4; # Could not extract confirmation code out of html
			}
			
		}else{
			return -5; # bad captcha entered
		}
	
	}else{
		return -1;# Could not get the recaptcha no-script page
	}

}

1;