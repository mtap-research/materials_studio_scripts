#!perl

use strict;
use warnings;
use Getopt::Long;
use MaterialsScript qw(:all);
use IO::Handle;


my $InputFile = "C:\\Users\\xjeongjong\\Documents\\My Dropbox\\Postdoc_NU\\PROJECTS\\genetic_algorithm\\DATA\\MechanicalProperties\\gen_0\\list.dat";
my $directory = "C:\\Users\\xjeongjong\\Documents\\My Dropbox\\Postdoc_NU\\PROJECTS\\genetic_algorithm\\DATA\\MechanicalProperties\\gen_0\\";
open(INFO, $InputFile) or die("Could not open  file ".$InputFile);

# global variables
my $density;
my $File;

$File='C:\Users\xjeongjong\Documents\My Dropbox\Postdoc_NU\PROJECTS\genetic_algorithm\DATA\MechanicalProperties\gen_0\results.dat';

open(RESULT, ">",$File) or die $!;

#Set the settings
Modules->Forcite->LoadSettings('.\SMForcite_Extension_hMOF_minimizer.xms');

foreach my $file (<INFO>) {
	chomp($file);
	my $doc = Documents->Import($directory.$file);
	$doc->CalculateBonds;
        #Optimize the structure

	### Pick a forcefield ###
	#Modules->Forcite->ChangeSettings([CurrentForcefield => "Dreiding"]);
	#Modules->Forcite->ChangeSettings([CurrentForcefield => "Universal"]);
        #Modules->Forcite->ChangeSettings([InitialCharge => "Formal"]);
	#Modules->Forcite->ChangeSettings(["3DPeriodicElectrostaticSummationMethod" => "Ewald"]);

        my $opt = Modules->Forcite->GeometryOptimization;
        my $results = $opt->Run($doc,Settings(WriteLevel => "Silent"));

        $density = $doc->SymmetrySystem->Density;
	my $lattice = $doc->SymmetryDefinition;
        my $LatticeA = $lattice->LengthA;
        my $LatticeB = $lattice->LengthB;
        my $LatticeC = $lattice->LengthC;

	#Mechanical Properties
	my $opt2 = Modules->Forcite->MechanicalProperties;
	# switch on cell optimization for the pre-optimization step
	Modules->Forcite->ChangeSettings([OptimizeCell => 1]);
	Modules->Forcite->ChangeSettings([MaxStrain => 0.001]);
	Modules->Forcite->ChangeSettings([NumberStrains => 6]);
	my $results2 = $opt2->Run($doc,Settings(OptimizeStructure => "Yes", WriteLevel => "Silent"));

	$doc->Export("C:\\Users\\xjeongjong\\Documents\\My Dropbox\\Postdoc_NU\\PROJECTS\\genetic_algorithm\\DATA\\MechanicalProperties\\gen_0\\".$file);
	printf RESULT "Cell_vectors_a_b_c \t\t %6.3f \t %6.3f \t %6.3f \n", $LatticeA, $LatticeB, $LatticeC;
        printf RESULT "Density \t\t\t\t %6.3f \n", $density;
	# Extract other properties from MechProp
	my $vg=$results2->VoigtBulkModulus;
	my $rbm=$results2->ReussBulkModulus;
	my $hbm=$results2->HillBulkModulus;
	my $hsm=$results2->HillShearModulus;
	my $comp=$results2->Compressibility;
	my $ymx=$results2->YoungModulusX;
	my $ymy=$results2->YoungModulusY;
	my $ymz=$results2->YoungModulusZ;
	printf RESULT "Young_Modulus_X_Y_Z \t %6.3f \t %6.3f \t %6.3f \n", $ymx, $ymy, $ymz;
	printf RESULT "Voigt_Bulk_Modulus \t %6.3f \n", $vg;
	printf RESULT "Reuss_Bulk_Modulus \t %6.3f \n", $rbm;
	printf RESULT "Hill_Bulk_Modulus \t %6.3f \n", $hbm;
	printf RESULT "Hill_Shear_Modulus \t %6.3f \n", $hsm;
	printf RESULT "Compressibility \t %6.3f \n", $comp;
        # Extract the independent elastic constants
	for (my $i = 1; $i <= 6; ++$i) {
   		for (my $j = 1; $j <= 6; ++$j) {
       			my $key = "C" . $i . $j;
		        my $Cij;
       			eval {$Cij = $results2->$key};
		        printf RESULT "C_$i$j %6.3f \n", $Cij unless !defined $Cij;
			}
	}

	#clean up
        $doc->Close;
        $doc->Delete;
        RESULT->autoflush;

}

close(RESULT);
