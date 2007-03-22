package Email::Thread;

=head1 NAME

Email::Thread - Use JWZ's mail threading algorithm with Email::Simple objects

=cut

use Mail::Thread;
use strict;
use vars qw( @ISA $VERSION );
@ISA = qw( Mail::Thread );
$VERSION = '0.711';

sub _get_hdr {
    my ($class, $msg, $hdr) = @_;
    $msg->header($hdr);
}

sub _container_class { "Email::Thread::Container" }

package Email::Thread::Container;

use vars qw( @ISA $VERSION );
@ISA = qw( Mail::Thread::Container );
$VERSION = $Email::Thread::VERSION;

sub header { eval { $_[0]->message->header($_[1]) } }

1;
__END__

=head1 SYNOPSIS

    use Email::Thread;
    my $threader = Email::Thread->new(@messages);

    $threader->thread;

    dump_em($_,0) for $threader->rootset;

    sub dump_em {
        my ($self, $level) = @_;
        debug (' \\-> ' x $level);
        if ($self->message) {
            print $self->message->header("Subject") , "\n";
        } else {
            print "[ Message $self not available ]\n";
        }
        dump_em($self->child, $level+1) if $self->child;
        dump_em($self->next, $level) if $self->next;
    }

=head1 DESCRIPTION

Strictly speaking, this doesn't really need L<Email::Simple> objects.
It just needs an object that responds to the same API. At the time of
writing the list of classes with the Email::Simple API comprises just
Email::Simple.

Due to how it's implemented, its API is an exact clone of
L<Mail::Thread>.  Please see that module's documentation for API
details. Just mentally substitute C<Email::Thread> everywhere you see
C<Mail::Thread> and C<Email::Thread::Container> where you see
C<Mail::Thread::Container>.

=head1 PERL EMAIL PROJECT

This module is maintained by the Perl Email Project.

L<http://emailproject.perl.org/wiki/Email::Thread>

=head1 SUPPORT

Support for this module is provided via the CPAN RT system at
L<http://rt.cpan.org/>

=head1 LICENCE AND COPYRIGHT

Copyright E<copy> Iain Truskett, 2003. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS

Simon Cozens (SIMON) for encouraging me to release it, and for
Email::Simple and Mail::Thread.

Richard Clamp (RCLAMP) for the header patch.

=head1 AUTHORS

Iain Truskett <spoon@cpan.org>

=head1 SEE ALSO

L<perl>, L<Mail::Thread>, L<Email::Simple>

=cut

