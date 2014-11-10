#!/usr/bin/env perl
use XML::LibXML;
use XML::LibXML::Reader;
use Getopt::Long qw(:config bundling);
use Date::Parse;
use strict;
use warnings;
binmode STDOUT, ":utf8";

my %opts = ( 
    name => undef,
    guild => undef,
    shard => undef,
    );

GetOptions( 
    "n|name=s" => \$opts{"name"},
    "g|guild=s" => \$opts{"guild"},
    "s|shard=s" => \$opts{"shard"},
    );

my @files = qw/Achievement ArtifactCollection Item NPC Quest Recipe/;
my @firstkeys = qw/FirstCompletedBy FirstCompletedBy FirstLootedBy FirstKilledBy FirstCompletedBy FirstLearnedBy/;
my @namekeys = qw/Name Name Name PrimaryName Name Name/;

while (my ($index, $file) = each @files) {
  my $reader = XML::LibXML::Reader->new(location => "${file}s.xml") or die $!;
  my $parser = XML::LibXML->new();
  print "\n${file}s:\n";

  while ( $reader->nextElement($file) ) {
    my $xml = $parser->parse_string($reader->readOuterXml());
    my $name = $xml->findnodes("/$file/$namekeys[$index]/English")->to_literal();
    $name =~ s/^\s+|\s+$//g;
    my $comps = $xml->findnodes("/$file/$firstkeys[$index]/*");
    foreach my $first ($comps->get_nodelist()) {
      my $player = $first->findnodes("./Name")->to_literal();
      my $guild = $first->findnodes("./Guild")->to_literal();
      my $date = $first->findnodes("./Date")->to_literal();
      my ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime($date);
      my $shard = $first->nodeName();
      $shard =~ s/Live_.._//;
      my $thresh = 0;
      if (defined $opts{'name'})  { $thresh++; if ($player eq $opts{'name'}) { $thresh--; } }
      if (defined $opts{'guild'})  { $thresh++; if ($guild eq $opts{'guild'}) { $thresh--; } }
      if (defined $opts{'shard'})  { $thresh++; if ($shard eq $opts{'shard'}) { $thresh--; } }
      
      if ($thresh <= 0) {
        print "$name: $player" . "@" . "$shard of $guild at " . (1900 + $year) . "-" . sprintf("%02d", 1 + $month) . "-$day $hh:$mm:$ss GMT\n";
      }
    }
  }
}
