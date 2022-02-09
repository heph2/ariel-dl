use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::Ariel',
  VERSION_FROM     => 'lib/App/ariel.pm',
  ABSTRACT_FROM    => 'lib/App/ariel.pm',
  AUTHOR           => 'Heph',
  LICENSE          => 'gpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/ariel-dl',
  ],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'WWW::Mechanize' => 0,
    'Mojo::DOM58' => 0,
    'HTTP::Cookies' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://git.mrkeebs.eu/ariel-dl/',
	web  => 'https://git.mrkeebs.eu/ariel-dl/about/',
      },
    },
  },
  clean => {
    FILES => "test target",
  },
);
