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

## testing TUI
use Curses::UI;
#use Curses::UI::Grid;

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
# my $index = 1;
# my %l;
# for (@links) {
#     $l{$index} = $_;
#     print "$index  | $_\n";
#     $index++;
# }

# print "Choose video to download: ";
# my $download_link = <STDIN>;
# chomp $download_link;

## Add to an array all the links that has to be downloaded
## There are 3 types of accepted Index
## Single Download:
## 1
## 1-4  (Download from 1 to 4)
## 1,4 (Download 1 and 4)
# my @to_down;
# if ($download_link =~ /\d-\d/) {  ## range
#     my ($from) = $download_link =~ /(\d)-/;
#     my ($to) = $download_link =~ /-(\d)/;
#     my $index = $from;
#     for ($from..$to) {
#         push(@to_down, $l{$index});
#         $index++;
#     }
# }

# if ($download_link =~ /,+/) {  ## Comma-separated
#     my @x = split(/,/, $download_link);
#     for (@x) {
#         push(@to_down, $l{$_});
#     }
# }

# if ($download_link =~ /\d{1}/) {  ## Single
#     push(@to_down, $l{$download_link});
# }

# chdir $down_dir; # change directory to down

# for (@to_down) {
#     ## Output use a regexp for extract the name of the file
#     ## from the URLs
#     my ($output) = $_ =~ /mp4:(.*\.mp4)/;

#     system("ffmpeg -loglevel panic -i $_ -c:v copy -c:a copy -crf 50 $output");
#     say "DONE!";
# }


## TESTING TUI
my $debug = 0;

my $cui = new Curses::UI (
    -color_support => 1,
    -clear_on_exit => 1,
    -debug => $debug,
    );

create_promote_deps_window();
$cui->set_binding( \&exit_dialog , "\cQ");
$cui->mainloop();

sub exit_dialog {
    my $return = $cui->dialog(
        -message   => "Do you really want to quit?",
        -title     => "Confirm",
        -buttons   => ['yes', 'no'],
    );

    exit(0) if $return;
}

sub create_base_window {
    my ($name) = @_;

    $cui->add(
        $name,
        'Window', 
        -border       => 1, 
        -titlereverse => 0, 
        -padtop       => 2, 
        -padbottom    => 3, 
        -ipad         => 1,
        -title        => 'CTRL-Q to quiz',
    );
}

sub move_focus {
    my $widget = $_[0];
    my $key    = $_[1];

    if ($key eq "\t") {
        $widget->parent()->focus_next();
    }
    else {
        $widget->parent()->focus_prev();
    }
}

sub create_promote_deps_window {
    my ($name) = @_;

    my $win = create_base_window($name);

    my $grid = $win->add(
        'grid',
        'Grid',
        -height       => 14,
        -width        => -1,
        -editable     => 0,
        -border       => 1,
        -process_bindings => {
            CUI_TAB => undef,
        },
        # -bg       => "blue",
        # -fg       => "white",
    );

    $grid->add_cell(
        "Index",
        -width => 10,
        -label => "INDEX"
        );
    
    $grid->add_cell(
        "Link",
        -width => 10,
        -label => "Link"
        );

    my $button_callback = sub {
        my $this = shift;
        
        my $btn_name = $this->get();
        if ($btn_name eq "Back") {
            # give up promotion and return to promote window
            $win->focus();
        }
        elsif ($btn_name eq "PromoteWithDeps") {
        }
    };
    $win->add(
        undef,
        'Buttonbox',
        -y        => -1,
        -buttons  => [
            {
                -label   => "< Back >",
                -value   => "Back",
                -onpress => $button_callback,
            },
            {
                -label   => "< Promote w/ all deps >",
                -value   => "PromoteWithDeps",
                -onpress => $button_callback,
            },
        ],
    );
    
    foreach my $f (@links) {

        $grid->add_row(
            undef,
            # -fg    => 'black',
            # -bg    => 'yellow',
            -cells => {
                otp     => $f->[0],
                commit1 => $f->[1],
                otnp    => $f->[2],
                commit2 => $f->[3],
                overlap => $f->[4],
            }
        );
    }

    $grid->layout();
    return $win;
}

