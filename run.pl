#!/usr/bin/perl
#This script downloads all images YGO's data bases missed
#Maybe there is one easier way to do it... but already did
#this.

#UPDATE: After Links update to YGOPro, the Linux version is
#no longer supported. It was good while it last.

use DBI;
use strict;
use File::Find;
use LWP::Simple;

#Pull new scripts
system("./expansions/live2016/pulldata.pl");


#Drivers SQLite and user & pass
my $driver   = "SQLite";
my $userid = "";
my $password = "";

#Directories to search in
my @cdb_dirs = ( "./expansions/live2016/", "./expansions/" );

#This array constains the images's name I already have
my @pics = glob "./pics/*.jpg";

#Delete trash characters
foreach my $pic (@pics){
	$pic = substr($pic, 7);
	$pic = substr($pic, 0, length($pic) - 4);
}

#Searching on directory
foreach my $subdir (@cdb_dirs){
	print "----> Trying to open subdirectory: $subdir\n";
	opendir(DIR, $subdir) or die;
	print "----> Directory successfully opened\n";
	
	#Search data bases within actual directory
	my @data_bases = glob "$subdir*.cdb";

	#Do on every Data Base
	for my $cdb (@data_bases){
		print "--------> Data base found: $cdb\n";
		
		my $dsn = "DBI:$driver:dbname=$cdb";
		my $cdb_conn = DBI -> connect($dsn, $userid, $password, {RaiseError => 1}) or die $DBI::errstr;
		print "--------> Data base successfully opened!!!\n";

		my $statement = qq(SELECT id from datas;);
		my $link_stmt = $cdb_conn -> prepare( $statement );
		my $results = $link_stmt -> execute or die $DBI::errstr;

		if($results < 0){
			print "------------> Failed to execute statement on data base\n";
		}

		#Data base image id -> ids
		my @ids;
		while( my @aux = $link_stmt -> fetchrow_array()){
			push @ids, $aux[0];
		}

		#Check if db's id does not exist on ./pics/ folder
		foreach my $aux_id (@ids){
			if($aux_id ~~ @pics){
				; #Do nothing
			}else{
				print "------------> Pic $aux_id does not exists!!! ... Trying to download it...\n";
				my $url = "https://raw.githubusercontent.com/Ygoproco/Live-images/master/pics/" . $aux_id . ".jpg";
				
				if(head($url)){
					print "----------------> Cool, it does exists. Downloading it... ";
					my $file = "./pics/" . $aux_id . ".jpg";
					#create file
					getstore($url, $file);
					print "Successfully downloaded\n";
				}
				else{
					print "----------------> [FAILED!!!] Pic $aux_id does not exists!\n";
				}

			}
		}

		$cdb_conn -> disconnect();
		print "--------> Data base closed!!!\n\n";
	}

	closedir(DIR);
}

print "Launching YGOPRO executable...\n";
system("sudo ./ygopro");
