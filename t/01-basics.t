#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Builtin::Logged qw(system readpipe);
use File::chdir;
use File::Slurper qw(write_text);
use File::Temp qw(tempdir tempfile);
use File::Which qw(which);
use Test::More 0.96;
use UUID::Random;

plan skip_all => "Need ls and true commands"
    unless which("ls") && which("true");

# plus, ls needs to behave like 'ls -1' by default

my $dir = tempdir(CLEANUP=>1);
$CWD = $dir;
write_text("a", 1);
write_text("b", 1);
write_text("c d", 1);

my $rand = UUID::Random::generate;

subtest "system with scalar argument" => sub {
    system("ls a b");
    is($?, 0);
};

subtest "system with array argument" => sub {
    system("ls", "a", "b", "c d");
    is($?, 0);
};

subtest "failed system exit code" => sub {
    system($rand);
    ok($?);
};

subtest "readpipe in scalar context" => sub {
    my $res;

    $res = readpipe("ls a b");
    like($res, qr/a.+b/s);
    is($?, 0);

    $res = `ls a b`;
    like($res, qr/a.+b/s);
    is($?, 0);
};

subtest "readpipe in array context" => sub {
    my @res;

    @res = readpipe("ls a b");
    is($?, 0);
    is(scalar(@res), 2);

    @res = `ls a b`;
    is($?, 0);
    is(scalar(@res), 2);
};

# XXX readpipe also accepts array argument

subtest "readpipe exit code" => sub {
    my $res;

    $res = readpipe $rand;
    ok(!defined($res));
    ok($?);

    $res = `$rand`;
    ok(!defined($res));
    ok($?);
};

$CWD = "/";
done_testing;
