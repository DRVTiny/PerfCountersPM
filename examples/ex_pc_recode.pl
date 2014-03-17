#!/usr/bin/perl
use lib '/home/drvtiny/Apps/Perl5/libs';
use Windows::PerfCounters qw(pcName2Crypted pcErr);
my (%ID2NAME,%NAME2ID);
Windows::PerfCounters->new({'en'=>'pc_en.lst','ru'=>'pc_ru.lst'},\%ID2NAME,\%NAME2ID);

#print scalar( pcName2Crypted('\CRM Async Service\Activty Propagation Operations Failed with Retry','en',\%ID2NAME,\%NAME2ID) || 'Error='.pcErr->{'message'} )."\n";
#exit(0);

open(FH,'<template.xml') || die 'Whereis your template?';
print join('',
 map { 
  index($_,'perf_counter[') and 
   s{perf_counter\[(.+?)\]}{ 
    my $pcName=$1;
    $pcName=~s%CrmService%Organization Service%g;
    'perf_counter['.(pcName2Crypted($pcName,\%ID2NAME,\%NAME2ID) || $pcName).']'
   }ge;
  $_; 
 } <FH>   );
close(FH);
