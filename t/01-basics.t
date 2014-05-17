#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Builtin::Logged qw(system my_qx);
use File::chdir;
use File::Slurp::Tiny qw(write_file);
use File::Temp qw(tempdir tempfile);
use File::Which qw(which);
use Test::More 0.96;
use UUID::Random;

plan skip_all => "Need ls and true commands"
    unless which("ls") && which("true");

# plus, ls needs to behave like 'ls -1' by default

my $dir = tempdir(CLEANUP=>1);
$CWD = $dir;
write_file("a", 1);
write_file("b", 1);
write_file("c d", 1);

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

subtest "my_qx in scalar context" => sub {
    my $res = my_qx("ls a b");
    like($res, qr/a.+b/s);
    is($?, 0);
};

subtest "my_qx in array context" => sub {
    my @res = my_qx("ls a b");
    is($?, 0);
    is(scalar(@res), 2);
};

# XXX my_qx also accepts array argument

subtest "my_qx exit code" => sub {
    my $res = my_qx($rand);
    ok(!defined($res));
    ok($?);
};

$CWD = "/";
done_testing;
