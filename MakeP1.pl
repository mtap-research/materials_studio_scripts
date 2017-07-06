#!perl

use strict;
use warnings;
use Getopt::Long;
use MaterialsScript qw(:all);
use IO::Handle;

my $InputFile = "C:\\Users\\xjeongjong\\csds_data\\list.dat";
my $directory = "C:\\Users\\xjeongjong\\csds_data\\";
open(INFO, $InputFile) or die("Could not open  file ".$InputFile);

foreach my $file (<INFO>) {
   	chomp($file);
	my $doc = Documents->Import($directory.$file);
	$doc->MakeP1;
	$doc->CalculateBonds;
	$doc->Export("C:\\Users\\xjeongjong\\csds_data\\P1\\".$file);
	$doc->Close;
	$doc->Delete;
}
