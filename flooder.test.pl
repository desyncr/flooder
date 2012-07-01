use HTTP::Request::Common;
use HTTP::Response;
use LWP::UserAgent;
use POSIX;
use List::Util qw(shuffle);

use DEBUG::Debug;
use IMAGE::Image;

# main conf
#   - follow threads (flood threads)
#   - random crap/
#   - random image
#   - image from folder
    %config = (
        debugVerbosity => 1,
        postFilename => 'file',
        target => {
            url => 'http://localhost/test.php'
            },
        delay => {
            current => 10,
            normal => 10,
            fullrage => 5,
            captcha => 60*5
        }
    );
    
# open db. update if necesary
    $debug = new Debug('log', $config{debugVerbosity});
        
# Start the fun
$try = 1;
$lastFailed = 0;
while (1)
{
    $debug->log("Retrying posting [$try]");

# set up connection
    $ua = LWP::UserAgent->new;

# build post (image, random crap)
    if (!$lastFailed)
    {
        $debug->log("Creating new image");
        $image = new Image($config{postFilename}, 10, 10);
        $image->create();

        # create new post
        
        %post = (
            board           => e,
            postpassword    => lolita,
            em              => 'return',
            replythread     => 0,
            MAX_FILE_SIZE   => 1024000,
            imagefile       => ["$config{postFilename}.png"]
        );
    }

# try to post
    $debug->log("Sending post information");
    $response = $ua->post($config{target}{url}, [%post]);

    $debug->log("Got response");
    $debug->log($response->decoded_content);
    if ($response->is_success)
    {
        $debug->log("Post sucessfully");
        $lastFailed = FALSE;
    }else{
        $debug->log("Post failed");
        if ($response->decoded_content =~ m/captcha/)
        {
            $debug->log("Fukken captcha!");
            $delay{current => $delay{captcha}};
            
        }
        $lastFailed = TRUE;
    }
    
    $try++;
    $debug->log("Sleeping for $delay{current} seconds\n\n");
    sleep($delay{current});
}