# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

sub update_password {
	use strict;
	use warnings;
	
	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	
	use Digest::SHA qw(sha1_base64);
	
	my $Database = shift;
	my $Password = shift;
	
	# Encrypt the password with sha1 and base64
	my $encryptedPassword = sha1_base64($Password);
	
	# Fix padding of Base64 digests
	while (length($encryptedPassword) % 4) {
		$encryptedPassword .= '=';
	}
	
	# Update the SQLite Database with the new and encrypted password
	my $UpdatePassword = system("sqlite3", "$Database", "UPDATE clients SET client_login_password = \"$encryptedPassword\" WHERE client_id = \"1\"");
	
	return $UpdatePassword;
}
1;
