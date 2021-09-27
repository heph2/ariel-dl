#!/usr/bin/env perl

=head1 ariel-dl

ariel-dl Simply download all the video stored in a ariel.unimi.it URL

=cut

use strict;
use warnings;
use Env;
use Cwd;
use Getopt::Long;
use WWW::Mechanize;
use Mojo::DOM58;
use HTTP::Cookies;
use v5.10.0;

my $username;
my $password;
my @credentials;
our $down_dir ||= cwd;
my $url;
GetOptions ("cred=s{2}" => \@credentials,
            "dir=s" => \$down_dir,
            "url=s" => \$url)
    or die("Error in command line arguments\n");

## If URL is not passed DIE!
if (not defined $url) {
    die "Need URL\n";
}

## Check if credentials are cached
if (not @credentials) {
    my $filename = "$HOME/.cache/ariel/credentials.txt";
    if (-e $filename) {
        open my $fh, '<', $filename;
        while(<$fh>) {
            $_ =~ /login: (.*)/;
            $username = $1;
            $_ =~ /password: (.*)/;
            $password = $1;
        }
    } else {
        die "Unable to find cached credentials, please use --cred for passing them"
    }
} else {
    $username = shift @credentials;
    $password = pop @credentials;
    cache_credentials($username, $password);
}

sub cache_credentials {
    my ($username, $password) = @_;
    my $dir = "$HOME/.cache/ariel";
    unless(-e $dir or mkdir $dir) {
        die "Unable to create $dir\n";
    }

    chdir $dir;
    open my $fh, '>', "credentials.txt";
    print $fh "login: $username\n";
    print $fh "password: $password\n";
    close($fh);

}

# This simply start a "web browser", store cookies from the login_URL
# then connect to URL provided by the user, use Mojo::DOM58 and find all
# the URLs (m3u8 playlists) using CSS selectors
sub fetch_link {
    ## This hard-coded URL is just the link for login, needed for storing the cookies
    ## and actually download
    my $login_URL = "https://elearning.unimi.it/authentication/skin/portaleariel/login.aspx?url=https://ariel.unimi.it/";

    my ($username, $password) = @_;
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

    say "Link Fetched";

    return @links;
}

my @links = fetch_link( $username, $password );

## now we print a table with index and all the link
my $index = 1;
my %l;
for (@links) {
    $l{$index} = $_;
    print "$index  | $_\n";
    $index++;
}

print "Choose video to download: ";
my $download_link = <STDIN>;
chomp $download_link;

## Add to an array all the links that has to be downloaded
## There are 3 types of accepted Index
## Single Download:
## 1
## 1-4  (Download from 1 to 4)
## 1,4 (Download 1 and 4)
my @to_down;
if ($download_link =~ /\d-\d/) {  ## range
    my ($from) = $download_link =~ /(\d)-/;
    my ($to) = $download_link =~ /-(\d+)/;
    my $index = $from;

    for ($from..$to) {
        push(@to_down, $l{$index});
        $index++;
    }
}

if ($download_link =~ /,+/) {  ## Comma-separated
    my @x = split(/,/, $download_link);
    for (@x) {
        push(@to_down, $l{$_});
    }
}

if ($download_link =~ /\d{1}/) {  ## Single
    push(@to_down, $l{$download_link});
}

## Adding signal handler for INT( Ctrl-C on the keyboard ), and
## for TERM, that cause Perl to exit cleanly
## If fork fails, parent send a TERM to all child process and then exit
$SIG{INT} = $SIG{TERM} = sub { exit };

my $parent_pid = "$$";
## now use the links for execute ffmpeg and download, it will spawn a
## process for each link and download them "concurrently"
my @children;

chdir $down_dir; # change directory to down
#for my $link (@links) {
for my $link (@to_down) {
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
    #    system("ffmpeg -loglevel panic -i $link -c:v copy -c:a copy -crf 50 $output");
    system("ffmpeg -loglevel panic -i $link -c:v copy -c:a copy -crf 50 $output");
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
