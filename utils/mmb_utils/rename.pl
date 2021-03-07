#!/usr/bin/perl -w
use strict;

# Beeb Utilities to manipulate MMB and SSD files
# Copyright (C) 2012 Stephen Harris
# 
# See file "COPYING" for GPLv2 licensing

use FindBin;
use lib "$FindBin::Bin";
use BeebUtils;

@ARGV=BeebUtils::init_ssd(@ARGV);

die "Syntax: $BeebUtils::PROG SSD file1 file2\n" unless @ARGV==2 && $BeebUtils::BBC_FILE;

my $image=BeebUtils::load_external_ssd(undef,1);

BeebUtils::rename_file(\$image,$ARGV[0],$ARGV[1]);
