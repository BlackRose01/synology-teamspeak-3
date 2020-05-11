# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

sub password_strength {
	use strict;
	use warnings;

	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	
	my $pw = shift;
	
	return 0 unless $pw =~ /[a-z]/;    # Has at least one lowercase
	return 0 unless $pw =~ /[A-Z]/;    # Has at least one uppercase
	return 0 unless $pw =~ /\d/;       # Has at least one digit
	return 0 unless length($pw) >= 8;  # Has at least 8 chars
	return 0 if $pw =~ /\s/;           # Has no spaces
	return 1;
}
1;
