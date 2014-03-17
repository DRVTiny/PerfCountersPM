#!/usr/bin/perl
package Windows::PerfCounters;
use Try::Tiny;
use Ouch qw(:trytiny);
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK=qw(new pcErr pcName2Crypted);
my %errInfo;

sub pcErr {
 my %eri=%errInfo;
 %errInfo={};
 return %eri?\%eri:{};
}

sub new {
 my ($slf,$pthLPC2ID,$ID2NAME,$NAME2ID)=@_;
 my @lcl_pth;
 if (ref($pthLPC2ID) eq 'HASH') {
  @lcl_pth=map { {'locale'=>$_,'path'=>$pthLPC2ID->{$_}} } keys %{$pthLPC2ID};
 } else {
  $pthLPC2ID=~s%([^/])$%$1/%;
  my $dhLPC2ID;
  opendir($dhLPC2ID,$pthLPC2ID) || die 'Cant open directory '.$pthLPC2ID;
  @lcl_pth=map { {'locale'=>$_,'path'=>$pthLPC2ID.'pc_'.$_.'.lst' } } grep { defined($_) } map { /^pc_([a-z]{2}).lst$/ && $1 || undef } readdir($dhLPC2ID);
  closedir($dhLPC2ID);
 }
 
 foreach my $hrPath4Lcl ( @lcl_pth ) {
  my $lcl=$hrPath4Lcl->{'locale'};
  open(LPC2ID,'<',$hrPath4Lcl->{'path'}) || die 'Cant open file '.$hrPath4Lcl->{'path'};
  
  my ($fl,$id)=(1,undef);
  foreach ( grep { length($_) } map { chomp; $_=~s/^\s+|\s+$//g; $_  } <LPC2ID> ) {
   if ($fl) {
    $id=$_;
   } else {
    $ID2NAME->{$id}{$lcl}=$_;
    push @{$NAME2ID->{$lcl}{$_}},$id;
   }
   $fl^=1;
  }
  
  close(LPC2ID);
 }
 return 1;
}

sub pcName2Crypted {
 my ($pc)=scalar(shift)=~m/^(?:\s*\\)?\s*(.+?)\s*$/;
 my $locale=($_[0] and ref($_[0]) ne 'HASH')?shift:'en';
 my ($ID2NAME,$NAME2ID)=@_;
 try {
  my ($nameChapter,$nameCounter)=split(/\\/,$pc);
  die Ouch->new(101,"PerfCounter must contain backslah(es), but, hmm, we got '$pc' instead :(") unless $nameChapter && $nameCounter;
  
  ($nameChapter,my $subChapter)=($nameChapter=~m/^\s*([^\(]+?)\s*(\([^\)]+\))?\s*$/);

  my $n2iChapter=$NAME2ID->{$locale}{$nameChapter};
  die Ouch->new(102,"ProcessID counters not found for selected locale '$locale'") unless $n2iChapter;
  die Ouch->new(103,'ProcessID must be unique') if @{$n2iChapter}>1;
  my $idChapter=$n2iChapter->[0];

  (my $rxCounter=$nameCounter)=~s%\b%\\s*%g;
  my ($idCounter)=( grep { $_>$idChapter && $ID2NAME->{$_}{$locale}=~m/${rxCounter}/i } keys %{$ID2NAME} );
  die Ouch->new(103,"PerfCounter '$nameCounter' not found in the processes hive '$nameChapter'") unless $idCounter;
  return "\\${idChapter}".($subChapter || '')."\\${idCounter}";
 } catch {
  %errInfo=%{$_};
  return 0;
 }
}

1;
