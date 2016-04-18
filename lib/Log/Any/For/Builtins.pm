package Log::Any::For::Builtins;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Proc::ChildError qw(explain_child_error);
use String::Trim::More qw(ellipsis);

our $Max_Log_Output = 1024;

sub system {
    if ($log->is_trace) {
        $log->tracef("system(): %s", join(" ", @_));
    }
    my $res = CORE::system(@_);
    if ($log->is_trace) {
        $log->tracef("system() child error: %d (%s)",
                     $?, explain_child_error()) if $?;
    }
    $res;
}

sub readpipe {
    my $arg = join " ", @_;
    if ($log->is_trace) {
        $log->tracef("readpipe(): %s", $arg);
    }
    my $wa = wantarray;
    my $output;
    my @output;
    if ($wa) { @output = qx($arg) } else { $output = qx($arg) }
    if ($log->is_trace) {
        $log->tracef("readpipe() child error: %d (%s)",
                     $?, explain_child_error()) if $?;
        if ($wa) { $output = join("", @output) }
        my $len = length($output // '');
        $log->tracef("readpipe() output (%d bytes%s): %s",
                     $len,
                     ($len > $Max_Log_Output ?
                         ", $Max_Log_Output shown" : ""),
                     ellipsis($output // '', $Max_Log_Output+3));
    }
    $wa ? @output : $output;
}

sub import {
    no strict 'refs';

    my ($self, @args) = @_;
    my $caller = caller();

    for my $arg (@args) {
        if ($arg eq 'system') {
            *{"$caller\::system"} = \&system;
        } elsif ($arg eq 'my_qx') {
            # back compat
            *{"$caller\::my_qx"} = \&readpipe;
        } elsif ($arg eq 'readpipe') {
            *{"$caller\::readpipe"} = \&readpipe;
        } else {
            die "$arg is not exported by ".__PACKAGE__;
        }
    }
}

1;
# ABSTRACT: (DEPRECATED) Log builtin functions

=head1 SYNOPSIS

 use Log::Any::For::Builtins qw(system readpipe);

 system "blah ...";
 my $out = `blah ...`;

When run, it might produce logs like:

 [TRACE] system(): blah ...
 [TRACE] system() child error: 256 (exited with value 1)
 [TRACE] readpipe(): blah ...
 [TRACE] readpipe() child error: 0 (exited with value 0)
 [TRACE] readpipe() output (200 bytes): Command output...


=head1 DESCRIPTION

B<DEPRECATED:> This module is now deprecated in favor of L<IPC::System::Options>
(which can do logging and more). This module will be removed from CPAN once
there are no reverse dependencies on it.

This module provides replacement for some builtin functions (and operators). The
replacement behaves exactly the same, except that they are peppered with log
statements from L<Log::Any>. The log statements are at C<trace> level.


=head1 EXPORTS

=over 4

=item * system

Will override system() with a version that does logging.

=item * readpipe

Will override readpipe() (which means the backtick operator also) with a version
that does logging.

=back


=head1 SEE ALSO

L<Log::Any>

Other Log::Any::For::* modules.

=cut
