#!/usr/bin/perl
#########################################################################
#                                                                       #
#                                                                       #
#                      Checksum database creator                        #
#                                                                       #
#               Description: Creates a checksum database file           #
#                            for the finddup.pl script                  #
#                                                                       #
#               (c) copyright 2012	                                #
#                 by Maniac                                             #
#                                                                       #
#                                                                       #
#########################################################################
#                       License                                         #
#  This program is free software. It comes without any warranty, to     #
#  the extent permitted by applicable law. You can redistribute it      #
#  and/or modify it under the terms of the Do What The Fuck You Want    #
#  To Public License, Version 2, as published by Sam Hocevar. See       #
#  http://sam.zoy.org/wtfpl/COPYING for more details.                   #
#########################################################################
use strict;
use warnings;
use Getopt::Std;
use File::Basename;
use Digest::MD5;
 
 
my $pversion = "0.2";
 
$SIG{INT} = \&sigint;
select STDERR; $| = 1; # make unbuffered
select STDOUT; $| = 1; # make unbuffered
 
my %parms = ();
 
my @checksums = ();
my $hasdb = 0;
getopts("i:d:hv",\%parms);
 
sub helptext {
 
        print "--------------------------------Duplicate Finder----------------------------------\n";
        print "Version: $pversion\n";
        print "\n";
        print "-d [Database]\t\tDatabase file to write files and checksums to\n";
        print "\t\t\tThis is a simple plaintext file, format: checksum|filename_with_path\n";
        print "\n";
        print "-i [inputfile]\t\tFile with all files which will be checksumd.\n";
        print "\t\t\tYou can create this list by using the GNU find command:\n";
        print "\t\t\t> find /my/path -type f > myfilelist.txt\n";
        print "\n";
        print "-h\t\t\tShow this help message\n";
	print "\n";
        print "-h\t\t\tShow version number\n";
        print "---------------------------------------------------------------------------------\n";
}
 
if (defined($parms{h})) {
        &helptext;
        exit;
}
 
if (defined($parms{v})) {
        print "Checksum DB Generator - Version: $pversion\n";
        exit;
}
 
if (!defined($parms{'i'})) {
	&helptext;
	die "-i inputfile is missing\n";
}
 
if (! -e $parms{'i'}) {
	&helptext;
	die "File ".$parms{'i'}." not found\n";
}
 
if (defined($parms{'d'})) {
	if (-f $parms{'d'}) {
		open (IN,"<",$parms{'d'}) || die "Could not read database file\n";
		my @tmp = <IN>;
		close(IN);
		foreach my $line (@tmp) {
			$line =~ s/\n|\r//g;
			push(@checksums,$line);	
		}		
 
 
	}
	open(OUT,">>",$parms{'d'}) || die "Could not write database file\n";
	$hasdb = 1;
}
else {
	die "No output database file specified! (-d [databasefile])\n";
}
 
#
# Desc: sub which get called on SIGINT (CTRL+C)
# Params: <none>
# Returns: <none>
sub sigint {
	die "Dying because I got SIGINT\n"; 
}
 
#
# Desc: Generates a md5 sum of a file useing MD5::Digest
# Params: filename
# Returns: Checksum or empty string if error
sub md5sum{
	my $file = shift;
 
	my $chksum = "";
	if (open(IN,"<",$file)) {
		my $md5 = Digest::MD5->new;
		$md5->addfile(*IN);
		$chksum = $md5->hexdigest;
		close(IN);
	}
	else {
		print STDERR "Error while processing checksum for $file\n";
		return "";
	}
	return $chksum;
}
 
#
# Desc: Check if File already logged in DB
# Params: filename
# Returns: 1 if new, 0 if old
sub is_in_db {
	if ($hasdb == 0) {
		return 1;
	}
	my $filename = shift;
	$filename = quotemeta($filename);
	my @hits = grep(/$filename/,@checksums);
	if (scalar(@hits) <= 0) {
		return 1;	
	}
	return 0;
 
}
 
 
 
my $inputfile = $parms{'i'};
open (IN,"<",$inputfile) || die "Could not read: $inputfile\n";
my @file = <IN>;
close(IN);
 
#
# Here I going through our file list and check it with the database file.
# Only new files will be checksumed again. 
# This means: modified files will not be recognized! But this safes a lot
# of time doing checksums on and on. 
print "--> Reading and comparing filenames\n";
binmode(OUT);
my %dups = ();
my $fmax = scalar(@file);
my $fcount = 0;
foreach my $line (@file) {
	$line =~ s/\n|\r//g;
	$fcount++;
	if (is_in_db($line) > 0) {
		my $md5 = md5sum($line);
		if ($md5 ne "") {
			print "$line has checksum: $md5\n";
			print OUT $line."|".$md5."\n";
		}
		else {
			print "Error computing checksum\n";
		}
	}
 
	print "File $fcount of $fmax\n";
}
 
 
#
# This part is simply to check if the files in the DB are still valid.
# That means, if the database contains a file which does no longer exists, 
# it will remove this file from the database.
# This prevents the database from being bigger than it should.
print "--> cleaning orphaned files\n";
my @newlist = ();
if (-e $parms{'d'}) {
	if (open(IN,"<",$parms{'d'}) ) {
		my @dbfile = <IN>;
		close(IN);
 
		foreach my $line (@dbfile) {
			$line =~ s/\n|\r//g;
			my ($filename,$checksum) = split(/\|/,$line);
			if ( -e $filename ) {
				push(@newlist,$line);
			}
			else {
				print "removeing orphaned file '$filename' from DB\n";
			}
		}
		print "--> Writing new dbfile: ".scalar(@newlist)." entries\n";
		if (open(OUT,">>",$parms{'d'}.".new")) {
			foreach my $line (@newlist) {
				print OUT $line."\n";
			}
			close(OUT);
		}
	}
}
 
 
print "--> finished\n";
