#!/usr/bin/perl

# TeamSpeak 3 Server package made by DI4bI0
# package maintained at http://www.diablos-netzwerk.de

print "Content-type: text/html\n\n";

use strict;
use warnings;

use FindBin qw($Bin);
# $Bin/lib contains the missing CGI module for Perl >= 5.24.0
use lib ("$Bin/include", "$Bin/lib");

use CGI;
use CGI::Carp qw(fatalsToBrowser);

use MIME::Base64 qw(decode_base64);

my $PKGDEST = "/var/packages/ts3server";
my $PKGSCRIPTS = "$PKGDEST/scripts";
my $UIDEST = "$PKGDEST/target/ui";

my $Database = "$PKGDEST/target/teamspeak3-server_linux/ts3server.sqlitedb";
my $Config = "$UIDEST/etc/config";
my $SynoTokenTempFile = "$UIDEST/etc/synotokentemp";
my $LicenseDir = "$PKGDEST/target/teamspeak3-server_linux";
my $LicenseFile = "$PKGDEST/target/teamspeak3-server_linux/licensekey.dat";

my $cgi = new CGI;

my $SynoTokenTemp;
my $Startparameter;

my %html;

# read $synotokentemp
open(IN, "<$SynoTokenTempFile") or die "Can't read file: '$SynoTokenTempFile' $!"; { $SynoTokenTemp = <IN>; } close(IN);

if ($SynoTokenTemp ne "") {
	$ENV{'QUERY_STRING'} = 'SynoToken='.$SynoTokenTemp;
	$ENV{'X-SYNO-TOKEN'} = $SynoTokenTemp;
}

require "check_appprivilege.cgi";
require "password_strength.cgi";
require "update_password.cgi";
require "generate_serveradmin_token.cgi";

my ($synotoken,$synouser,$is_admin) = check_privilege('SYNO.SDS._ThirdParty.App.ts3server');

# write $synotokentemp
if ($ENV{'X-SYNO-TOKEN'} ne "") { open(OUT,">$SynoTokenTempFile") or die "Can't write file: '$SynoTokenTempFile' $!"; { print OUT "$ENV{'X-SYNO-TOKEN'}"; } close(OUT); }

if ($synouser eq '') {
	print "<html><head><title>Login Required</title></head><body>Please login as admin first, before using this interface</body></html>\n";
	exit;
}

# save changes to config file
my $TS3ServerStatus = system("$PKGSCRIPTS/start-stop-status.sh status")>>8;
my $change = $cgi->param('change');
if ($change eq "changesettings") {
	if ($TS3ServerStatus eq "1") {
		if (open (OUT, ">$Config")) {
			my $Startparameter = $cgi->param('startparameter');
			my $Backuppath = $cgi->param('backuppath');
			print OUT "Startparameter=$Startparameter\n";
			print OUT "Backuppath=$Backuppath\n";
			close (OUT);
			$html{'ChangedSettings'} = "<span style=\"color:green;\">(changed)</span>";
		} else {
			$html{'ChangedSettings'} = "<span style=\"color:red;\">(unable to change the config)</span>";
		}
	} else {
		$html{'ChangedSettings'} = "<span style=\"color:red;\">(found running TS3Server, stop it first)</span>";
	}
}

# NPL license
if ($change eq "licensefile") {
	if ($TS3ServerStatus eq "1") {
		my $LicenseFileContent = $cgi->param('licensefilecontent');
		# The \s character class matches a whitespace character, the set [\ \t\r\n\f] and others
		$LicenseFileContent =~ s/\s+//g;
		if ($LicenseFileContent eq "delete") {
			unlink $LicenseFile;
			$html{'ChangedLicenseFile'} = "<span style=\"color:red;\">(licensekey.dat deleted)</span>";
		} else {
			# Check for base64 input
			if ($LicenseFileContent =~ m{^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$}) {
				$LicenseFileContent = decode_base64($LicenseFileContent);
				if (open (OUT, ">$LicenseFile")) {
					print OUT "$LicenseFileContent";
					close (OUT);
					$html{'ChangedLicenseFile'} = "<span style=\"color:green;\">(changed)</span>";
				} else {
					$html{'ChangedLicenseFile'} = "<span style=\"color:red;\">(unable to change the licensekey.dat)</span>";
				}
			} else {
				$html{'ChangedLicenseFile'} = "<span style=\"color:red;\">(no base64 input)</span>";
			}
		}
	} else {
		$html{'ChangedLicenseFile'} = "<span style=\"color:red;\">(found running TS3Server, stop it first)</span>";
	}
}

# change TS3Admin password
my $TS3ServerPassword = $cgi->param('ts3serverpassword');
if ($change eq "changets3serverpassword") {
	if ($TS3ServerStatus eq "1") {
		if (password_strength($TS3ServerPassword)) {
			my $TS3ServerPasswordUpdate = update_password($Database,$TS3ServerPassword);
			if ($TS3ServerPasswordUpdate) {
				$html{'ChangedTS3ServerPassword'} = "<span style=\"color:red;\">(unable to change the password)</span>";
			} else {
				$html{'ChangedTS3ServerPassword'} = "<span style=\"color:green;\">(your password has been changed)</span>";
			}
		} else {
			if ($TS3ServerPassword ne '') {
				$html{'ChangedTS3ServerPassword'} = "<span style=\"color:red;\">(your password does not meet the requirements)</span>";
			} else {
				$html{'ChangedTS3ServerPassword'} = "<span style=\"color:red;\">(empty password)</span>";
			}
		}
	} else {
		$html{'ChangedTS3ServerPassword'} = "<span style=\"color:red;\">(found running TS3Server, stop it first)</span>";
	}
}

# generate TS3Admin token
if ($change eq "generatets3servertoken") {
	if ($TS3ServerStatus eq "0") {
		my $TS3ServerToken = generate_serveradmin_token($TS3ServerPassword);
		if ($TS3ServerToken) {
			$TS3ServerToken =~ s/token=//;
			my $TS3ServerTokenTitle="New TeamSpeak 3 Server Admin Token";
			my $TS3ServerTokenMessage="Admin Token: $TS3ServerToken";
			system('/usr/syno/bin/synodsmnotify', '@administrators', $TS3ServerTokenTitle, $TS3ServerTokenMessage);
			$html{'TS3ServerToken'} = "Admin Token:<br />$TS3ServerToken<br /><br />";
			$html{'GenerateTS3ServerToken'} = "<span style=\"color:green;\">(Admin Token created!)</span>";
		} else {
			$html{'GenerateTS3ServerToken'} = "<span style=\"color:red;\">(Admin Token failed! Maybe password wrong?)</span>";
		}
	} else {
		$html{'GenerateTS3ServerToken'} = "<span style=\"color:red;\">(no running TS3Server found, start it first)</span>";
	}
}

# Ts3Status
if ($TS3ServerStatus eq "0") {
	$html{'TS3ServerStatus'} = "<span style=\"color:green;\">Online</span>";
} else {
	$html{'TS3ServerStatus'} = "<span style=\"color:red;\">Offline</span>";
}

# Check NPL license
if (-f "$LicenseDir/licensekey.dat") {
	$html{'LicenseFile'} = "<span style=\"color:green;\">licensekey.dat available</span>";
} else {
	$html{'LicenseFile'} = "<span style=\"color:red;\">licensekey.dat not available</span>";
}

# read the config file
if (open (IN, "<$Config")) {
	while (<IN>) {
		chomp;
		s/#.//;
		s/^\s+//;
		s/\s+$//;
		my ($var, $value) = split(/\s*=\s*/, $_, 2);
		$html{$var}=$value;
	}
	close (IN);
} else {
	$html{'ChangedSettings'} = "<span style=\"color:red;\">(unable to load the config)</span>";
}

# Backup/Restore
my $Backuppath = $html{'Backuppath'};
my $BackupRestore = $cgi->param('backuprestore');
my $BackupName = $cgi->param('backupname');
my $BackupRestoreExitValue;

# Backup
if ($BackupRestore eq "1") {
	if ($TS3ServerStatus eq "1") {
		if (-d $Backuppath) {
			$BackupRestoreExitValue = system("sh", "$UIDEST/backup_restore.sh", "backup", "$Backuppath")>>8;
			if ($BackupRestoreExitValue eq "0") {
				$html{'BackupRestore'} = "<span style=\"color:green;\">(backup successful)</span>";
			} else {
				$html{'BackupRestore'} = "<span style=\"color:red;\">(backup failed)</span>";
			}
		} else {
			$html{'BackupRestore'} = "<span style=\"color:red;\">(backup dir not found)</span>";
		}
	} else {
		$html{'BackupRestore'} = "<span style=\"color:red;\">(found running TS3Server, stop it first)</span>";
	}
}

# Restore
if ($BackupRestore eq "2") {
	if ($TS3ServerStatus eq "1") {
		if (! $BackupName eq "") {
			$BackupRestoreExitValue = system("sh", "$UIDEST/backup_restore.sh", "restore", "$Backuppath", "$BackupName")>>8;
			if ($BackupRestoreExitValue eq "0") {
				$html{'BackupRestore'} = "<span style=\"color:green;\">(restore successful)</span>";
			} else {
				$html{'BackupRestore'} = "<span style=\"color:red;\">(restore failed)</span>";
			}
		} else {
			$html{'BackupRestore'} = "<span style=\"color:red;\">(restore file not selected)</span>";
		}
	} else {
		$html{'BackupRestore'} = "<span style=\"color:red;\">(found running TS3Server, stop it first)</span>";
	}
}

# print available backups
if (! $Backuppath eq "") {
	my @Restore = `ls -t $Backuppath`;
	@Restore = grep (/ts3server_backup_/, @Restore);
	my $i = 0;
	foreach(@Restore) {
		chomp;
		if ($i == 0) {
			$html{'RestoreOptions'} = "<select name=\"backupname\" size=\"1\" style=\"width: 260px\">";
			$html{'RestoreOptions'} .= "<option selected=\"selected\" value=\"\"></option>";
		}
		$html{'RestoreOptions'} .= "<option value=\"$_\">$_</option>";
		$i++;
	}
	if (! $html{'RestoreOptions'} eq "") {
		$html{'RestoreOptions'} .= "</select><br /><br />";
	}
}

if ($html{'RestoreOptions'} eq "") {
	$html{'RestoreOptions'} = "<span style=\"color:red;\">(no backups available)</span><br /><br />";
}

# print html page
if (open (IN, "index.html")) {
	while (<IN>) {
		s/==:([^:]+):==/$html{$1}/g;
		print $_;
	}
close (IN);
}
