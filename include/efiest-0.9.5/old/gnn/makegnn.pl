#!/usr/bin/env perl

#version 0.03
#added error checking on input values
#improved performance of xgmml parsing by indexingg the dom
#change mysql so that the session will restart if it ever disconnects
#changed syntax -xgmml is not -ssnin
#the graph names of the output xgmmls are now based off the graph name of the input xgmml
#version 0.02
#fixed issues that would prevent cytoscape exported xgmml files from working
#version 0.01
#initial version


use Getopt::Long;
use List::MoreUtils qw{apply uniq any} ;
use XML::LibXML;
use DBD::SQLite;
use DBD::mysql;
use IO;
use XML::Writer;

sub findneighbors {
  $ac=shift @_;
  $n=shift @_;
  $dbh=shift @_;
  $fh=shift @_;
  %pfam=();
#print "select * from combined where AC='$ac'\n";
  $sth=$dbh->prepare("select * from combined where AC='$ac';");
  $sth->execute;
#print "after id search\n";
  if($sth->rows>0){
    while(my $row=$sth->fetchrow_hashref){

      $low=$row->{num}-$n;
      $high=$row->{num}+$n;
      $query="select * from combined where ID='".$row->{ID}."' and num>=$low and num<=$high";
      my $neighbors=$dbh->prepare($query);
      $neighbors->execute;
      foreach $tmp (split(",",$row->{pfam})){
	push @{$pfam{'orig'}{$tmp}}, $row->{AC};
      }
      while(my $neighbor=$neighbors->fetchrow_hashref){
        foreach $tmp (uniq split(",",$neighbor->{pfam})){
	  $distance=$neighbor->{num}-$row->{num};
	  unless($distance==0){
	    push @{$pfam{'neigh'}{$tmp}}, $neighbor->{AC};
	    push @{$pfam{'dist'}{$tmp}}, $row->{AC}.":".$neighbor->{AC}.":$distance";
	  }
	}
      }
    }
  }else{
    print $fh "$ac\n";
  }
  return \%pfam;
}

sub getcolors {
  my $dbh=shift @_;
  my %colors=();
  my $sth=$dbh->prepare("select * from colors;");
  $sth->execute;
  while(my $row=$sth->fetchrow_hashref){
    $colors{$row->{cluster}}=$row->{color};
  }
  return \%colors;
}

$result=GetOptions ("ssnin=s"		=> \$ssnin,
		    "n=s"		=> \$n,
		    "nomatch=s"		=> \$nomatch,
		    "gnn=s"		=> \$gnn,
		    "ssnout=s"		=> \$ssnout,
		    "incfrac=i"		=> \$incfrac,
		    "stats=s"		=> \$stats
		    );

$usage="usage makegnn.pl -ssnin <filename> -n <positive integer> -nomatch <filename> -gnn <filename> -ssnout <filename>\n-ssnin\t name of original ssn network to process\n-n\t distance (+/-) to search for neighbors\n-nomatch output file that contains sequences without neighbors\n-gnn\t filename of genome neighborhood network output file\n-ssnout\t output filename for colorized sequence similarity network\n";


#error checking on input values

unless(-s $ssnin){
  die "-ssnin $ssnin does not exist or has a zero size\n$usage";
}

unless($n>0){
  die "-n $n must be an integer greater than zero\n$usage";
}

unless($gnn=~/./){
  die "you must specify a gnn output file\n$usage";
}

unless($ssnout=~/./){
  die "you must specify a ssn output file\n$usage";
}

unless($nomatch=~/./){
  die "you must specify and output file for nomatches\n$usage";
}

if($incfrac=~/^\d+$/){
  $incfrac=$incfrac/100;
}else{
  if(defined $incfrac){
    die "incfrac must be an integer\n";
  }
  $incfrac=0.20;  
}

if($stats=~/\w+/){
  open STATS, ">$stats" or die "could not write to $stats\n";
}else{
  open STATS, ">/dev/null" or die "could nto dump stats info to dev null\n";
}

#use sqlite not working atm
#$db='/home/groups/efi/gnn/databases/gnn.db';
#my $dbh = DBI->connect("dbi:SQLite:$db","","");

#use mysql (faster if you index AC field)
my $dbh = DBI->connect('DBI:mysql:efi_20140729;host=10.1.1.3;port=3307', 'efignn', 'c@lcgnn', { RaiseError => 1 });
$dbh->{'AutoCommit'} = 1;
$dbh->{mysql_auto_reconnect} = 1;

%nodehash=();
%constellations=();
%supernodes=();
%pfams=();
%colors=%{getcolors($dbh)};
$hubcolor='#FFFFFF';
%accessioncolors=();
%nodenames=();
%numbermatch=();


#nodehash correlates accessions in a node to the labeled accession of a node, this is for drilling down into repnode networks
#nodehash key is an accession
#constellations maps accessions to a supernode number
#constellations key is an accession
#supernodes is a hash of arrays that contain all of the accessions within a constellation
#key for supernodes are the intergers from %constellations
#pfams contains all of the information for the gnn networks related to sequence (non meta data) including distance
#key for pams is a pfam number.
#colors is a hash where the keys are integers and the values are hexidecimal numbers for colors
#accessioncolors holds the colors assigned by the constellation number for an accession node
#nodenames maps the id from nodes to accession number, this allows you to run this script on cytoscape xgmml exports

open(GNN,">$gnn") or die "could not write to gnn output file\n";

$parser=XML::LibXML->new();
$output=new IO::File(">$ssnout");
$writer=new XML::Writer(DATA_MODE => 'true', DATA_INDENT => 2, OUTPUT => $output);

$gnnoutput=new IO::File(">$gnn");
$gnnwriter=new XML::Writer(DATA_MODE => 'true', DATA_INDENT => 2, OUTPUT => $gnnoutput);
print "parse edges and nodes from original xgmml\n";


$doc=$parser->parse_file($ssnin);
#index the document, really speeds things up
$doc->indexElements();
#print "fetch edges\n";
#@edges=$doc->getElementsByTagName('edge');
#print "fetch nodes\n";
#@nodes=$doc->getElementsByTagName('node');

print "Fetch Edges\n";
@edges=$doc->getElementsByLocalName('edge');
print "Fetch Nodes\n";
@nodes=$doc->getElementsByLocalName('node');
print "Get Network Name\n";
@graphs=$doc->getElementsByLocalName('graph');
$graph=shift @graphs;
$graphname=$graph->getAttribute('label');
print "graph name is $graphname\n";

print "parse nodes for accessions\n";
foreach $node (@nodes){
  $nodehead=$node->getAttribute('label');
  #cytoscape exports replace the id with an integer instead of the accessions
  #%nodenames correlates this integer back to an accession
  #for efiest generated networks the key is the accession and it equals an accession, no harm, no foul
  $nodenames{$node->getAttribute('id')}=$nodehead;
  @annotations=$node->findnodes('./*');
  push @{$nodehash{$nodehead}}, $nodehead;
  foreach $annotation (@annotations){
    if($annotation->getAttribute('name') eq "ACC"){
      @accessionlists=$annotation->findnodes('./*');
      foreach $accessionlist (@accessionlists){
	#make sure all accessions within the node are included in the gnn network
	push @{$nodehash{$nodehead}}, $accessionlist->getAttribute('value');
      }
    }
  }
}


print "parse edges to determine clusters\n";
$newnode=1;
foreach $edge (@edges){
#print $edge->getAttribute('source').",".$edge->getAttribute('target')."\n";
  #if source exists, add target to source sc
  if(exists $constellations{$nodenames{$edge->getAttribute('source')}}){
    #if target also already existed, add target data to source 
    if(exists $constellations{$nodenames{$edge->getAttribute('target')}}){
      #check if source and target are in the same constellation, if they are, do nothing, if not, add change target sc to source and add target accessions to source accessions
      unless($constellations{$nodenames{$edge->getAttribute('target')}} eq $constellations{$nodenames{$edge->getAttribute('source')}}){
	#add accessions from target supernode to source supernode
	push @{$supernodes{$constellations{$nodenames{$edge->getAttribute('source')}}}}, @{$supernodes{$constellations{$nodenames{$edge->getAttribute('target')}}}};
	#delete target supernode
	delete $supernodes{$constellations{$nodenames{$edge->getAttribute('target')}}};
	#change the constellation number for all 
	$oldtarget=$constellations{$nodenames{$edge->getAttribute('target')}};
	foreach my $tmpkey (keys %constellations){
	  if($oldtarget==$constellations{$tmpkey}){
	    $constellations{$tmpkey}=$constellations{$nodenames{$edge->getAttribute('source')}};
	  }
	}
      }
    }else{
      #target does not exist, add it to source
      #change cluster number
      $constellations{$nodenames{$edge->getAttribute('target')}}=$constellations{$nodenames{$edge->getAttribute('source')}};
      #add accessions
      push @{$supernodes{$constellations{$nodenames{$edge->getAttribute('source')}}}}, @{$nodehash{$nodenames{$edge->getAttribute('target')}}}
      
    }
  }elsif(exists $constellations{$nodenames{$edge->getAttribute('target')}}){
    #target exists, add source to target sc
    #change cluster number
    $constellations{$nodenames{$edge->getAttribute('source')}}=$constellations{$nodenames{$edge->getAttribute('target')}};
    #add accessions
    push @{$supernodes{$constellations{$nodenames{$edge->getAttribute('target')}}}}, @{$nodehash{$nodenames{$edge->getAttribute('source')}}}
  }else{
    #neither exists, add both to same sc, and add accessions to supernode
#print $edge->getAttribute('source').",".$edge->getAttribute('target')."\n";
    $constellations{$nodenames{$edge->getAttribute('source')}}=$newnode;
    $constellations{$nodenames{$edge->getAttribute('target')}}=$newnode;
    push @{$supernodes{$newnode}}, @{$nodehash{$nodenames{$edge->getAttribute('source')}}};
    push @{$supernodes{$newnode}}, @{$nodehash{$nodenames{$edge->getAttribute('target')}}};
    #increment for next sc node
    $newnode++;
  }

}

#remove any duplicates (they are possible)
foreach $key (keys %supernodes){
  @{$supernodes{$key}}=uniq @{$supernodes{$key}};
}


print "find neighbors\n\n";

#gather neighbors of each supernode and store in the $pfams data structure
open( $nomatch_fh, ">$nomatch" ) or die "cannot write file of non-matching accessions\n";
$simplenumber=1;
foreach $key (sort {$a <=> $b} keys %supernodes){
  print "Supernode $key, ".scalar @{$supernodes{$key}}." original accessions, simplenumber $simplenumber\n";
  $numbermatch{$key}=$simplenumber;
  foreach $accession (uniq @{$supernodes{$key}}){
#    print "$accession\n";
#    print "\tsearch\n";
    $pfamsearch=findneighbors $accession, $n, $dbh, $nomatch_fh;
#    print "\tafter search\n";
    foreach $result (keys %{${$pfamsearch}{'neigh'}}){
      if(exists $pfams{$result}{$key}{'size'}){
	$pfams{$result}{$key}{'size'}+=scalar @{${$pfamsearch}{'neigh'}{$result}}       
      }else{
	$pfams{$result}{$key}{'size'}=scalar @{${$pfamsearch}{'neigh'}{$result}};
      }
      push @{$pfams{$result}{$key}{'orig'}}, @{${$pfamsearch}{'orig'}{$result}};
      push @{$pfams{$result}{$key}{'neigh'}}, @{${$pfamsearch}{'neigh'}{$result}};
      push @{$pfams{$result}{$key}{'dist'}}, @{${$pfamsearch}{'dist'}{$result}};   
      #print "\t".join(",", @{${$pfamsearch}{'dist'}{$result}})."\n";
    }

  }
  $simplenumber++;
}

print "\nwrite out gnn xgmml\n";

$pfamcount=0;
$gnnwriter->startTag('graph', 'label' => "$graphname gnn", 'xmlns' => 'http://www.cs.rpi.edu/XGMML');
foreach $key (keys %pfams){
  $pfamcount++;
  @allorig=();
  @allneigh=();
#also added
  $concount=0;
  $pdbcount=0;
  $eccount=0;
  $sth=$dbh->prepare("select * from pfam_info where pfam='$key';");
  $sth->execute;
  $pfam_info=$sth->fetchrow_hashref;
  $pfam_short=$pfam_info->{short_name};
  foreach $sc (keys $pfams{$key}){
#do not dray node if incfrac<ClustrFraction
    if($incfrac<=( scalar(@{$pfams{$key}{$sc}{'dist'}})/scalar(@{$supernodes{$sc}}))){
      $concount++;
      $gnnwriter->startTag('node', 'id' => "$key;$sc", 'label' => $numbermatch{$sc});

      $gnnwriter->emptyTag('att', 'name' => 'Cluster Number', 'type' => 'integer', 'value' => $numbermatch{$sc});
      #$gnnwriter->emptyTag('att', 'name' => 'node.size', 'type' => 'string', 'value' => (int($pfams{$key}{$sc}{'size'}/10)+20));
      $gnnwriter->emptyTag('att', 'name' => 'node.size', 'type' => 'string', 'value' => int(((scalar(@{$pfams{$key}{$sc}{'dist'}})/scalar(@{$supernodes{$sc}}))*50)+20));
      $gnnwriter->emptyTag('att', 'name' => 'node.shape', 'type' => 'string', 'value' => 'circle');
      $gnnwriter->emptyTag('att', 'name' => 'Num_neighbors', 'type' => 'integer', 'value' => $pfams{$key}{$sc}{'size'});
      $gnnwriter->emptyTag('att', 'name' => 'Num_queries', 'type' => 'integer', 'value' => scalar(@{$pfams{$key}{$sc}{'dist'}}));
      $gnnwriter->emptyTag('att', 'name' => 'node.fillColor', 'type' => 'string', 'value' => $colors{$numbermatch{$sc}});
	  $gnnwriter->startTag('att', 'type' => 'list', 'name' => 'Query_Accessions');
      foreach $element (@{$pfams{$key}{$sc}{'orig'}}){
	$gnnwriter->emptyTag('att', 'type' => 'string', 'name' => 'Query_Accessions', 'value' => $element);
      }
	  $gnnwriter->endTag;
      push @allorig, @{$pfams{$key}{$sc}{'orig'}};
	  $gnnwriter->startTag('att', 'type' => 'list', 'name' => 'Neighbor_Accessions');
      foreach $element (@{$pfams{$key}{$sc}{'neigh'}}){
	$sth=$dbh->prepare("select * from annotations where accession='$element';");
	$sth->execute;
	$row=$sth->fetchrow_hashref;
	$sth=$dbh->prepare("select * from pdbhits where ACC='$element';");
	$sth->execute;
	$pdbdata=$sth->fetchrow_hashref;
	$gnnwriter->emptyTag('att', 'type' => 'string', 'name' => 'Neighbor_Accessions',  'value' => "$element:".$row->{EC}.":".$pdbdata->{PDB}.":".$pdbdata->{e}.":".$row->{STATUS});
	if($pdbdata->{PDB}=~/\w+/){
	  $pdbcount++;
	}
	#print $row->{EC}.",".$row->{accession}.",$element\n";
	if($row->{EC}=~/\w+/ and $row->{EC} ne 'None'){
	  $eccount++;
	}
      }
	  $gnnwriter->endTag();
      push @allneigh, @{$pfams{$key}{$sc}{'neigh'}};
	  $gnnwriter->startTag('att', 'type' => 'list', 'name' => 'Distance');
      $absDistSum=0;
      $distCount=0;
      foreach $element (@{$pfams{$key}{$sc}{'dist'}}){
	$gnnwriter->emptyTag('att', 'type' => 'string', 'name' => 'Distance', 'value' => $element);
	$distCount++;
	@element=split ':', $element;
	$absDistSum+=abs @element[2];
      }
	  $gnnwriter->endTag;
      $clusterfraction=int(scalar(@{$pfams{$key}{$sc}{'dist'}})/scalar(@{$supernodes{$sc}})*1000)/1000;
      $gnnwriter->emptyTag('att', 'name' => 'ClusterFraction', 'type' => 'double', 'value' => $clusterfraction);
      $gnnwriter->emptyTag('att', 'name' => 'Num_Ratio', 'type' => 'string', 'value' =>  scalar(@{$pfams{$key}{$sc}{'dist'}})."/".scalar(@{$supernodes{$sc}}));
      $gnnwriter->emptyTag('att', 'name' => 'SSNClusterSize', 'type' => 'integer', 'value' => scalar(@{$supernodes{$sc}}));
      if($pdbcount>0 and $eccount>0){
	$gnnwriter->emptyTag('att', 'name' => 'node.shape', 'type' => 'string', 'value' => 'diamond');
      }elsif($pdbcount>0){
	$gnnwriter->emptyTag('att', 'name' => 'node.shape', 'type' => 'string', 'value' => 'square');
      }elsif($eccount>0){
	$gnnwriter->emptyTag('att', 'name' => 'node.shape', 'type' => 'string', 'value' => 'triangle');
      }else{
	$gnnwriter->emptyTag('att', 'name' => 'node.shape', 'type' => 'string', 'value' => 'ellipse');
      }
	$gnnwriter->endTag();
      $gnnwriter->startTag('edge', 'label' => "$key to $key;$sc", 'source' => $key, 'target' => "$key;$sc");
        $gnnwriter->emptyTag('att', 'name' => 'SSNClusterSize', 'type' => 'string', 'value' => ( scalar(@{$pfams{$key}{$sc}{'dist'}})/scalar(@{$supernodes{$sc}})));
      $gnnwriter->endTag();
      $absAvg=int($absDistSum/$distCount*1000)/1000;
      print STATS "$numbermatch{$sc}\t$key\t$pfam_short\t$clusterfraction\t$absAvg\n";
    }
  }
#Do not Draw hub node if there are no spoke nodes
  if($concount>0){
    #$sth=$dbh->prepare("select * from pfam_info where pfam='$key';");
    #$sth->execute;
    #3$pfam_info=$sth->fetchrow_hashref;
    $gnnwriter->startTag('node', 'id' => $key, 'label' => $pfam_short);
    $gnnwriter->emptyTag('att', 'name' => 'node.shape', 'type' => 'string', 'value' => 'hexagon');
    $gnnwriter->emptyTag('att', 'name' => 'node.size', 'type' => 'string', 'value' => '70.0');
    $gnnwriter->emptyTag('att', 'name' => 'pfam', 'type' => 'string', 'value' => $key);
    $gnnwriter->emptyTag('att', 'name' => 'Pfam description', 'type' => 'string', 'value' => $pfam_info->{long_name});
    $gnnwriter->emptyTag('att', 'name' => 'node.fillColor', 'type' => 'string', 'value' => $hubcolor);
    @allorig=uniq @allorig;
    @allneigh=uniq @allneigh;
    $gnnwriter->startTag('att', 'type' => 'list', 'name' => 'Query_Accessions');
    foreach $element (@allorig){
      $gnnwriter->emptyTag('att', 'type' => 'string', 'name' => 'Query_Accessions', 'value' => "$element:TODO:qnum");
    }
    $gnnwriter->endTag();
    $gnnwriter->startTag('att', 'type' => 'list', 'name' => 'Neighbor_Accessions');
    foreach $element (@allneigh){
      $sth=$dbh->prepare("select * from annotations where accession='$element';");
      $sth->execute;
      $row=$sth->fetchrow_hashref;
      $sth=$dbh->prepare("select * from pdbhits where ACC='$element';");
      $sth->execute;
      $pdbdata=$sth->fetchrow_hashref;
      $gnnwriter->emptyTag('att', 'type' => 'string', 'name' => 'Neighbor_Accessions', 'value' => "$element:".$row->{EC}.":".$pdbdata->{PDB}.":".$pdbdata->{e}.":".$row->{STATUS});
    }
    $gnnwriter->endTag();
    $gnnwriter->emptyTag('att', 'name' => 'Num_queries', 'type' => 'integer', 'value' => scalar @allorig);
    $gnnwriter->emptyTag('att', 'name' => 'Num_neighbors', 'type' => 'integer', 'value' => scalar @allneigh);
    $gnnwriter->endTag();
  }
}
$gnnwriter->endTag();

print "write out colored ssn network\n";

$writer->startTag('graph', 'label' => "$graphname colorized", 'xmlns' => 'http://www.cs.rpi.edu/XGMML');
foreach $node (@nodes){
  #print "$node\n";
  $writer->startTag('node', 'id' => $node->getAttribute('label'), 'label' => $node->getAttribute('label'));
  #find color and add attribute
  $writer->emptyTag('att', 'name'=>'node.fillColor', 'type' => 'string', 'value'=> $colors{$numbermatch{$constellations{$node->getAttribute('label')}}});
  $writer->emptyTag('att', 'name'=>'Supercluster', 'type' => 'string', 'value'=> $numbermatch{$constellations{$node->getAttribute('label')}});
  foreach $attribute ($node->getChildnodes){
    if($attribute=~/^\s+$/){
      #print "\t badattribute: $attribute:\n";
      #the parser is returning newline xml fields, this removes it
      #code will break if we do not remove it.
    }else{
      if($attribute->getAttribute('type') eq 'list'){
	$writer->startTag('att', 'type' => $attribute->getAttribute('type'), 'name' => $attribute->getAttribute('name'));
	foreach $listelement ($attribute->getElementsByTagName('att')){
	  $writer->emptyTag('att', 'type' => $listelement->getAttribute('type'), 'name' => $listelement->getAttribute('name'), 'value' => $listelement->getAttribute('value'));
	}
	$writer->endTag;
      }elsif($attribute->getAttribute('name') eq 'interaction'){
	#do nothing
	#this tag causes problems and it is not needed, so we do not include it
      }else{
	$writer->emptyTag('att', 'type' => $attribute->getAttribute('type'), 'name' => $attribute->getAttribute('name'), 'value' => $attribute->getAttribute('value'));
      }
    }
  }
  $writer->endTag(  );
}

foreach $edge (@edges){
  $writer->startTag('edge', 'id' => $edge->getAttribute('id'), 'label' => $edge->getAttribute('label'), 'source' => $nodenames{$edge->getAttribute('source')}, 'target' => $nodenames{$edge->getAttribute('target')});
  foreach $attribute ($edge->getElementsByTagName('att')){
    if($attribute->getAttribute('name') eq 'interaction'){
      #print "do nothing\n";
      #this tag causes problems and it is not needed, so we do not include it
    }else{
      $writer->emptyTag('att', 'name' => $attribute->getAttribute('name'), 'type' => $attribute->getAttribute('type'), 'value' =>$attribute->getAttribute('value'));
    }
  }
  $writer->endTag;
}
$writer->endTag();

print "makegnn.pl finished\n";