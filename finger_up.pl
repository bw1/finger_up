#!/usr/bin/perl
#
# hochladen von einem bild auf den finger server
#
use utf8;
use open ":locale";

use HTML::Form;
use LWP::UserAgent;
use HTML::Parser;
use Getopt::Std;
use DateTime;
use File::Copy qw(copy);


# die adresse des servers
$base_uri="http://www.fingers-welt.de/imghost/";

# filter der ausgegebenen urls
my %ids=(
	#codebb=>1,
	#codehtml=>1,
	codedirect=>1,
	#codebbs=>1,
	#codehtmls=>1,
	codedirects=>1
);

$Getopt::Std::STANDARD_HELP_VERSION=1;
$main::VERSION="0.0.1";

my %opts;
getopts('t13s:',\%opts);

#foreach( keys %opts) {
#	print "> $_ $opts{$_}\n";
#}

my $ft=0;
if ( exists $opts{'t'} ) {
	$ft=1;
}
if ( exists $opts{'1'} ) {
	$ft=30;
}
if ( exists $opts{'3'} ) {
	$ft=30*3;
}

# Scalierung
my $sc=0.5;
if ( exists $opts{'s'} ) {
	my $a=$opts{'s'};
	$a=int($a*10)/10;

	if ($a<=0.9 && $a>=0.1) {
		$sc=$a;
		#print "sc $sc \n";
	}
}

# Datei
my $fn =shift @ARGV;

if ( ! -f $fn ) {
	print "Error: Datei '$fn' nicht gefunden\n";
	exit(1);
}


utf8::decode($fn);

# Dateiname 
my $fna=$fn;
$fn =~ s/ä/ae/g;
$fn =~ s/ö/oe/g;
$fn =~ s/ü/ue/g;
$fn =~ s/ß/sz/g;
$fn =~ s/Ä/Ae/g;
$fn =~ s/Ö/Oe/g;
$fn =~ s/Ü/Ue/g;


if ($fna ne $fn) {
	copy $fna,$fn;
	print "copy $fna\t$fn\n";
}

# alt Text
my $alt =join(" ",@ARGV);
#print "-$alt-\n";

sub main::HELP_MESSAGE(){
	print "finger_up.pl [Optionen] <Datei> [alt Text]\n";
	print "\n";
	print "-t Verfallsdatum 1 Tag\n";
	print "-1 Verfallsdatum 1 Monat\n";
	print "-3 Verfallsdatum 3 Monate\n";
	print "-s <Skalierungsfaktor>\n";
}


my $ua = LWP::UserAgent->new;
my $re = $ua->get($base_uri);

my $form = HTML::Form->parse($re);

if ($ft !=0) {
	my $t =DateTime->now();
	$t->add( days=> $ft );
	$form->value(datumaktiv => 'on');
	$form->value(tag =>   $t->day());
	$form->value(monat => $t->month());
	$form->value(jahr =>  $t->year());
}

$form->value(alt => $alt);
$form->value(scale => $sc);
$form->value(file => $fn);

$re = $ua->request($form->click);

my $res= $re->content;

# ausgabe 

sub start() {
	if ($_[0] eq "input") {
		if (exists $ids{$_[1]{id}}) {
			#print $_[1]{id},"\n";
			print $_[1]{value},"\n";
		}
	}
}

my $p = HTML::Parser->new( 
	api_version => 3,
	start_h => [\&start, "tagname, attr"],
	marked_sections => 1,
);

$p->parse($res);
