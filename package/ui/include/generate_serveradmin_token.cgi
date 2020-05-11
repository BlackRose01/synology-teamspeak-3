# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

sub generate_serveradmin_token {

	use strict;
	use warnings;
	
	use CGI;
	use CGI::Carp qw(fatalsToBrowser);

	use Net::Telnet;

	my $login="serveradmin";
	my $pw = shift;

	my $telnet = new Net::Telnet ( Timeout=>1, Errmode=>'return', Port=>10011);
	$telnet->open('localhost');
	$telnet->waitfor('/Welcome/');
	$telnet->print("login $login $pw");
	$telnet->waitfor('/error id=0 msg=ok/');
	$telnet->print('use 1');
	$telnet->waitfor('/error id=0 msg=ok/');

	my @output = $telnet->cmd(String=>"tokenadd tokentype=0 tokenid1=6 tokenid2=0", Prompt=>"/error id=0 msg=ok/");

	return $output[1];
}
;1
