#***********************************************************************#
#  check_appprivilege.pl                                                #
#  Description: Script to query the active user permission for the      #
#               called application.                                     #
#               This will allow control of the permissions for          #
#               3rdparty apps via Control Panel - Permissions           #
#               Now with query from SynoToken (DSM 4.x and onward)      #
#  Author:      QTip from the german Synology support forum             #
#  Copyright:   2012-2016 by QTip                                       #
#  License:     GNU GPLv3 (see LICENSE)                                 #
#  -------------------------------------------------------------------  #
#  Version:     0.81 - 18/09/2016                                       #
#***********************************************************************#

sub check_privilege {
	my $appname = shift;
	my $token = '';
	my $raw_data = '';
	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	use JSON::XS;
	use Data::Dumper;

	# retrieve SynoToken...
	if (defined($ENV{'REQUEST_METHOD'}) && $ENV{'REQUEST_METHOD'} eq "GET") {
		$token = `/usr/syno/synoman/webman/login.cgi`;
		$token =~ /\"SynoToken\"\s*?:\s*?\"(.*)\"/i;
		my $synotoken = ($1 ? $1 : '');
		# backup the current state of QUERY_STRING
		my $TMPENV = $ENV{'QUERY_STRING'};
		$ENV{'QUERY_STRING'} = 'SynoToken='.$synotoken;
		$ENV{'X-SYNO-TOKEN'} = $synotoken;
	}

	# and check if user logged in...
	my $synouser = `/usr/syno/synoman/webman/modules/authenticate.cgi`;
	$synouser =~ s/^\s+|\s+$//g;
	
	# if synouser empty (not logged in), return empty string
	return ('','',0) if ($synouser eq '');

	my ($initdata,$appprivilege,$is_admin);
	# get dsm build
	my $dsmbuild = `/bin/get_key_value /etc.defaults/VERSION buildnumber`;
	chomp($dsmbuild);
	if ($dsmbuild >= 7307) {
		$raw_data = `/usr/syno/bin/synowebapi --exec api=SYNO.Core.Desktop.Initdata method=get version=1 runner=$synouser`;
		$initdata = JSON::XS->new->decode($raw_data);
		$appprivilege = (defined $initdata->{'data'}->{'AppPrivilege'}->{$appname}) ? 1 : 0;
		$is_admin = (defined $initdata->{'data'}->{'Session'}->{'is_admin'} && $initdata->{'data'}->{'Session'}->{'is_admin'} == 1) ? 1 : 0;
	} else {
		$raw_data = `/usr/syno/synoman/webman/initdata.cgi`;
		$raw_data = substr($raw_data,index($raw_data,"{")-1);
		$initdata = JSON::XS->new->decode($raw_data);
		$appprivilege = (defined $initdata->{'AppPrivilege'}->{$appname}) ? 1 : 0;
		$is_admin = (defined $initdata->{'Session'}->{'is_admin'} && $initdata->{'Session'}->{'is_admin'} == 1) ? 1 : 0;
	}
	# if application not found or user not admin, return empty string
	# restore the old state of QUERY_STRING
	 if (defined($ENV{'REQUEST_METHOD'}) && $ENV{'REQUEST_METHOD'} eq "GET") {
	$ENV{'QUERY_STRING'} = $TMPENV;
	 }
	return ('','',0) unless ($appprivilege || $is_admin);
	return ($synotoken,$synouser,$is_admin);
}
1;
