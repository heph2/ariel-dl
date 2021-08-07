#!/usr/bin/env perl

=head1 ariel-dl

ariel-dl Simply download all the video stored in a ariel.unimi.it URL


=cut


use strict;
use warnings;
use strict;
use WWW::Mechanize;
use Mojo::DOM58;
use HTTP::Cookies;
use v5.10.0;


## This hard-coded URL is just the link for login, needed for storing the cookies
## and actually download
my $login_URL = "https://elearning.unimi.it/authentication/skin/portaleariel/login.aspx?url=https://ariel.unimi.it/";

## Take as CMD-arguments the URL where the videolessons are stored,
## username and password of the student
my ($url, $username, $password) = @ARGV;

## If one of those fields are provided DIE
if (not defined $url || $username || $password) {
	die "Need URL\n";
}

## This simply start a "web browser", store cookies from the login_URL
## then connect to URL provided by the user, use Mojo::DOM58 and find all
## the URLs (m3u8 playlists) using CSS selectors
my $mech = WWW::Mechanize->new();
$mech->cookie_jar(HTTP::Cookies->new());
$mech->get($login_URL);
$mech->form_id('form1');
$mech->field("tbLogin", $username);
$mech->field("tbPassword", $password);
$mech->click;
$mech->get($url);
my $output_page = $mech->content();

my $dom = Mojo::DOM58->new($output_page);
my @links = $dom->find('video.lecturec source')->map(attr => 'src')->each;

say for @links;

## Adding signal handler for INT( Ctrl-C on the keyboard ), and
## for TERM, that cause Perl to exit cleanly
## If fork fails, parent send a TERM to all child process and then exit
$SIG{INT} = $SIG{TERM} = sub { exit };


my $parent_pid = "$$";

## now use the links for execute ffmpeg and download, it will spawn a
## process for each link and download them "concurrently"
my @children;
for my $link (@links) {
    my $pid = fork;
    if (!defined $pid) {
        warn "failed to fork: $!";
        kill 'TERM', @children;
        exit;
    }
    elsif ($pid) {
        push @children, $pid;
        next;
    }

    ## Output use a regexp for extract the name of the file
    ## from the URLs
    my ($output) = $link =~ /mp4:(.*\.mp4)/;
    say "Downloading $output on process $pid";

    ## Actually call fffmpeg and download the m3u8 file
    system("ffmpeg -nostdin -i $link -c:v copy -c:a copy -crf 50 $output");
    say "DONE!";

    exit;
}

## wait_children performs blocking wait call on the pids forked by the parent
wait_children();

sub wait_children {
    while (scalar @children) {
        my $pid = $children[0];
        my $kid = waitpid $pid, 0;
        warn "Reaped $pid ($kid)\n";
        shift @children;
    }
}

## Additional clean up if some zombie process spawned earlier exists
END {
    if ($parent_pid == $$) {
        wait_children();
    }
}
