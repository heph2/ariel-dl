# Ariel-dl

A simple videolessons downloader for ariel.unimi.it
Ariel-dl can easilty fetch from a given ariel.unimi.it url the list
of availables videos to download, and let user choose which one
download

## Installation

Manual install:
	perl Makefile.PL
	make
	make install
	
Docker Container:
	Requires nix installed
	docker load < $(nix-build docker.nix)
	
Ariel-dl is also available as a NUR package

## Usage

	man ariel-dl
	
## Dependencies

- HTTP::Cookies
- Getopt::Long
- WWW::Mechanize
- Mojo::DOM58

## License

GPLv3

