use lib "../perl/";
use lib "../perl/lib/";
use XML::Simple;
use XML::Writer;
use IO::File;
use Test;

$writer= Test::initreport("report.xml");




%statusse=Test::assert_file_same_within( "./reference/QPENE-eV.OUT",
	"rungw/QPENE-eV.OUT",1.0e-5);
 Test::writetestreport({
 		"directory"=>"test08/ ",
 		"name"=>"GW  Quasy-particle banstructure",
 		"description"=>"The test is passed if the  Quasy-particle banstructure   differs
 		 less than $tol between runlgw/QPENE-eV.OUT and reference file 
 		 reference/QPENE-eV.OUT difference=".  %statusse->{maxerror},
 		"status"=> %statusse->{status}}, $writer);

 Test::closereport($writer);
