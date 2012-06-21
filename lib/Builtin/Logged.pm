package Builtin::Logged;

use 5.010;
use strict;
use warnings;

use Log::Any '$log';
use SHARYANTO::Proc::ChildError qw(explain_child_error);
use SHARYANTO::String::Util qw(ellipsis);

# VERSION

our $Max_Log_Output = 1024;

sub system {
    if ($log->is_trace) {
        $log->tracef("system(): %s", join(" ", @_));
    }
    CORE::system(@_);
    if ($log->is_trace) {
        $log->tracef("system() child error: %d (%s)",
                     $?, explain_child_error($?));
    }
}

sub my_qx {
    my $arg = join " ", @_;
    if ($log->is_trace) {
        $log->tracef("my_qx(): %s", $_);
    }
    my $output = qx($arg);
    if ($log->is_trace) {
        $log->tracef("my_qx() child error: %d (%s)",
                     $?, explain_child_error($?));
        $log->tracef("my_qx() output (%d bytes%s): %s",
                     length($output),
                     (length($output) > $Max_Log_Output ?
                         ", $Max_Log_Output shown" : ""),
                     ellipsis($output, $Max_Log_Output+3));
    }
}

sub import {
    no strict 'refs';

    my ($self, @args) = @_;
    my $caller = caller();

    for my $arg (@args) {
        if ($arg eq 'system') {
            *{"$caller\::system"} = \&system;
        } elsif ($arg eq 'my_qx') {
            *{"$caller\::my_qx"} = \&my_qx;
        } else {
            die "$arg is not exported by ".__PACKAGE__;
        }
    }
}

1;
# ABSTRACT: Replace builtin functions with ones that log using Log::Any

=head1 SYNOPSIS

 use Builtin::Logged qw(system my_qx);

 system "blah ...";
 my $out = my_qx("blah ...");

When run, it might produce logs like:

 [TRACE] system(): blah ...
 [TRACE] system() child error: 256 (exited with value 1)
 [TRACE] my_qx(): blah ...
 [TRACE] my_qx() child error: 0 (exited with value 0)
 [TRACE] my_qx() output (200 bytes): Command output...


=head1 DESCRIPTION

This module provides replacement for some builtin functions (and operators). The
replacement behaves exactly the same, except that they are peppered with log
statements from L<Log::Any>. The log statements are at C<trace> level.

This module is useful if you already use Log::Any for your application.


=head1 EXPORTS

=over 4

=item * system

=item * my_qx

Will provide my_qx(). Use this instead of qx() or backtick. Perl currently does
not provide an easy way to override/overload qx().

=back


=head1 VARIABLES


=head1 SEE ALSO

L<Log::Any>

=cut
