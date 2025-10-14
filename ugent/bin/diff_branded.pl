#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(:5.10);
use File::Find;

find({
    wanted => sub {
        my $bfile = $File::Find::name;
        my $file  = $bfile;
        $file =~ s/^app\/views\/branded/app\/views/o;
        return unless -f $file;
        say "diff $file $bfile";
        my @out = `diff "$file" "$bfile"`;
        say $_ for @out;
        say "----";
    },
    no_chdir => 1,
}, "app/views/branded");
