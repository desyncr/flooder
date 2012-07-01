#!/usr/bin/perl -w
use HTTP::Request::Common;
use HTTP::Response;
use LWP::UserAgent;
use HTTP::Cookies;
use POSIX;
use List::Util qw(shuffle);
use String::Random;

use updater::updater;
use db::DBProxy;
use db::DBStats;
use debug::Debug;
use image::Image;
use captcha::Captcha;

# main conf
#   - follow threads (flood threads)
#   - image from folder
    %config = (
        debug => {
            verbosity => 1
        },
        proxy => {
            updateTimeout => 1,
            connectTimeout => 10,
	    userAgent		=> '',
        },
        target => {
            url => 'http://localhost/board.php',
            rsrc => ['http://www.freeproxylists.net/?c=&pt=&pr=&a%5B%5D=1&a%5B%5D=2&u=70',
                    'http://www.aliveproxy.com/anonymous-proxy-list/',
                    'http://www.aliveproxy.com/high-anonymity-proxy-list/'],
            captcha => {
                usecaptcha => 0,
                apikey => ''
            }
        },
        post => {
            board => 'ex',
            pwd => '',
            msg => '',
            name => '',
	    token => $ARGV[0]
        },
        delay => {
            current => 60*15,
            normal => 10,
            fullrage => 5,
            captcha => 60*15,
            banned => 10
        }
    );
    $str = new String::Random;

# open db. update if necesary
    $debug = new Debug('log', $config{debug}{verbosity});
    $dbStats = new DBStats('data','stats');
    
    %stats = $dbStats->getStats;

    if (time-$stats{started} > $config{proxy}{updateTimeout}) {
        $updater = new Updater($config{target}{rsrc});
        $updater->updateDb();
    }
    $stats{started} = time();
    $dbStats->setStat('started', $stats{started});

    $dbProxy = new DBProxy('data','proxies');
        
# Start the fun
my ($try, $lastFailed, $captcha, $confirmation_code) = (1, 0, new Captcha($config{target}{captcha}{apikey}), 0);
while (1) {
    $debug->log("Retrying posting [$try]");
    @proxyList = $dbProxy->getProxy();
    %proxy = (
        ip => $proxyList[0][0][0],
        port => $proxyList[0][0][1],
        url => $proxyList[0][0][0] . ':' . $proxyList[0][0][1]
    );
    $debug->log("Connecting through $proxy{url}");

# set up connection
    $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/5.0 (Windows; U; Windows NT 6.0; en; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7');
    my $cookies = HTTP::Cookies->new();

    $ua->proxy('http' => 'http://' . $proxy{url});
    $ua->timeout($config{proxy}{connectTimeout});
    
# build post (image, random crap)
    if (!$lastFailed) {
        $debug->log("Creating new image");
        $image = new Image($config{post}{filename}, $config{post}{imgW}, $config{post}{imgH});
        $image->create();

        # create new post
        %post = (
	        board       =>  $config{post}{board},
        	password    =>  $str->randpattern('......'),
	        replythread =>  0,
        	MAX_FILE_SIZE   =>  1024000,
	        email       =>  '',
        	name        =>  $str->randpattern('.........'),
	        subject     =>  '',
	        submit      =>  'Submit',
        	message     =>  $str->randpattern('............................'),
	        nofile      =>  1,
        	postpassword    =>  $str->randpattern('...............'),
        );
    }

# try to post
    if ($config{target}{captcha}{usecaptcha} && !$confirmation_code) {
        $debug->log("Enter captcha: ");
        $confirmation_code = $captcha->getConfirmation();
        if ($confirmation_code < 0) {
            $debug->log("Invalid captcha?");
        }else{
            $debug->log("Confirmation code: " . $confirmation_code);
            $post{recaptcha_challenge_field} = $confirmation_code;
            $confirmation_code = 0;
        }
    }

    $debug->log("Sending post information");
    #$cookies->set_cookie(0,'', $proxy{ip},'/','',80,0,0,86400,0);
    $ua->cookie_jar($cookies);

    $response = $ua->post($config{target}{url},
        Content_Type => 'multipart/form-data',
        Content => [%post]);

#   update stats:
    $debug->log($response->decoded_content);
    if ($response->is_success) {
        $debug->log("Post sucessfully");
        $dbStats->setStat('lastTry', time());
        if ($response->decoded_content =~ m/captcha/) {
            $debug->log("Fukken captcha!");
            $dbStats->setStat('totalFailed', ++$stats{totalFailed});
            $dbStats->setStat('totalCaptchas', ++$stats{totalCaptchas});
            $config{delay}{current} = $config{delay}{captcha};
            $lastFailed = FALSE; # do not create a new image nor post
            
        }elsif($response->decoded_content =~ m/banned/){
                $debug->log("Banned!");
                $dbStats->setStat('totalFailed', ++$stats{totalFailed});
                $dbProxy->removeProxy("ip='$proxy{ip}'");
                $config{delay}{current} = $config{delay}{banned};
                $lastFailed = TRUE;

        }else{
            $dbStats->setStat('lastPost', time());
            $dbStats->setStat('totalPosts', ++$stats{totalPosts});
            $lastFailed = FALSE;
        }
    }else{
        $debug->log("Post failed");
        $dbStats->setStat('lastTry', time());
        $dbStats->setStat('totalFailed', ++$stats{totalFailed});
        $dbProxy->removeProxy("ip='$proxy{ip}'");
        $lastFailed = FALSE;
        $config{delay}{current} = $config{delay}{fullrage};
    }
    
    $try++;
    $debug->log("Sleeping for $config{delay}{current} seconds\n\n");
    sleep($config{delay}{current});
}
