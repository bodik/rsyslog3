#!/usr/bin/perl -w
# ssh bruteforce detector, coded by bodik 2007
# based upon http://bumblebeeware.com/sshlogcheck/sshlogcheck.txt
#
#
# changelog: 
#  * 03/04/2007 - bodik - initial coding
#  * 18/04/2007 - bodik - bugfix: database of crackers was created with $today timestamps everyday
#  			  but we want to mantain original date of attack
#  * 18/04/2007 - bodik - added "Invalid user " pattern
#  * 12/12/2007 - bodik - added syslog support
#  * v1.2 14/12/2007 - bodik - added ssh syn/new conns limit to doc
#  * v1.3 04/03/2008 - bodik - adjusted rate limits
#  * v1.4 16/05/2008 - bodik - added "Failed publickey" for DSA-1571, ...
#  * v1.5 06/01/2009 - bodik - added "refused connect from" for telnet
#  * v1.6 30/03/2009 - bodik - added wrapper "support"
#  * v1.7 26/11/2009 - bodik - added Authentication failure
# 
# usage: 
#   1) create chain CRACKERS in your packetfilter and place it on the first position
#      iptables -N CRACKERS
#      iptables -I INPUT 1 -j CRACKERS
#
#      limit incomming connection to slow down attackers
#      iptables -N SHELL
#      iptables -A INPUT -m tcp -p tcp --dport 22 -j SHELL
#      iptables -A SHELL -p tcp -m tcp --dport 22 -m state --state NEW -m recent --set --name SSH --rsource
#      iptables -A SHELL -p tcp -m tcp --dport 22 -m state --state NEW -m recent --update --seconds 120 --hitcount 30 --name SSH --rsource -j DROP
#      iptables -A SHELL -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT
#
#
#   2) run this script every 10 or less minutes, it will update CRACKERS chain with DROP rules
#     */2 * * * * tools/sshcrack/sshcrack.pl
#
#   2a) zcu usage !!!
#    */4 * * * * (cd /usr/local/bin; cp /afs/zcu.cz/common/tools/sshcrack/sshcrack.pl sshcrack.pl.new && mv -f sshcrack.pl.new sshcrack.pl; /usr/local/bin/sshcrack.pl)
#
#   3) DROP rule will automatically expire with $horizont value
#
#   4) if rate limit iptables chain is used with --seconds 60 --hitcount 10
#      it drops very most of attackers before this script comes to play
#      it's also a fine solution ;))
# 
#
# caveat: 1) algorithm depends on current date because you cann't fail more than $maxfail per
#            day or you'll get banned
# 
# TODO: better caveat workaround
# TODO: "Did not recive ... aka http://aharp.ittns.northwestern.edu/software/sshdict"
# 	to react on scanning

use strict;
use Data::Dumper;
use POSIX;
use Sys::Syslog;
################################################## config

my $authlog = "/var/log/auth.log";
# format is: "<ip>,<banned on timestamp>"
my $bannedlog = "/var/cache/banned.txt";
my $DEBUG=0;
my $maxfail = 20;
my $horizont = (60*60*24)*14; # 14 days
#my $wrapper = undef;
my $wrapper = "/etc/hosts.allow";

###############################################################
my $line = undef;
my %banned; my %crackers;
my $today=time();
setlocale( LC_ALL, "C" );
my $today_str = strftime("%b %_d", localtime());
my $tmp;

# read old database of banned IPs
if( open(CLOG, "<$bannedlog") ) {
	while($line=<CLOG>) {
		chomp($line);
		my($t1,$t2) = split(",", $line);
		$banned{$t1} = $t2;
	}
	close(CLOG);
	$line=undef;
}

print "DEBUG: banned\n" if $DEBUG;
print Dumper(\%banned) if $DEBUG;

# count failed attempts
open(AUTHLOG, $authlog) || die "ERROR: cann't open authlog file\n";
while($line = <AUTHLOG>) {
	chomp($line);
	#print "DEBUG: line $line\n" if $DEBUG;
	#if( $line =~ m/^$today_str.*(Failed password|Illegal user|Failed keyboard-interactive).*/ ) {
	if( $line =~ m/^$today_str.*(ssh|telnet).*(Failed password|Illegal user|Invalid user|Failed publickey|refused connect from|uthentication failure).*/ ) {
		$line =~ s/::ffff://;
		if( $line =~ m/.*[ =]([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/ ) {
			$crackers{"$1"}++;
			print "DEBUG: line $line\n" if $DEBUG;
			print "DEBUG: adding $1\n" if $DEBUG;
		}
	}
}
close(AUTHLOG);

print Dumper(\%crackers) if $DEBUG;

# ban if ip exceeds limits
foreach $tmp (keys %crackers) {
	if( ($crackers{$tmp}) > $maxfail) {
		# if it exceeds out limit and is not previously banned
		if( not defined($banned{$tmp}) ) {
			$banned{$tmp} = $today;
			openlog("sshcrack.pl", 'cons,pid', 'auth');
			syslog('warning', "banned $tmp for $crackers{$tmp} failed ssh login attempts");
			closelog();
#			printf STDERR "$0 banned - $tmp: $crackers{$tmp} attempts\n";
		}
	}
}

my @t; my $a;
#wrapper ?
if(defined $wrapper) {
	open(W, $wrapper) || die "ERROR: cannt open wrapper config\n";
	$tmp="";
	while($tmp = <W>) {
		chomp($tmp);
		if($tmp =~/^sshd:/) { last; } 
	}
	unless($tmp) { $tmp=""; }
        @t=split(" ", $tmp);
	foreach $tmp (@t) {
		if(defined $banned{$tmp}) { 
			delete $banned{$tmp}; 
			print("WARNING: $tmp whitelisted from wrapper\n");
		}
	}
	close(W);
}

# release ip or leave it in the database & update pf rules
open(CLOG, ">$bannedlog") || die "ERROR: cann't open crackers file";
system("/sbin/iptables -F CRACKERS\n") == 0 or printf STDERR "ERROR: cann't flush iptables CRACKERS chain\n";
foreach $tmp (keys %banned) {
	# if ban is not expired
	if( $banned{$tmp} > ($today-$horizont) ) {
		print CLOG "$tmp,$banned{$tmp}\n";
		#TODO: redirect do honeypot instead of drop;)
		system("/sbin/iptables -A CRACKERS -s $tmp -j DROP") == 0 or printf STDERR "ERROR: add rule to iptables CRACKERS chain\n";
	} else {
		openlog("sshcrack.pl", 'cons,pid', 'auth');
                syslog('warning', "releasing $tmp");
                closelog();
		#printf STDERR "$0 releasing - $tmp\n";
	}
}
close(CLOG);

