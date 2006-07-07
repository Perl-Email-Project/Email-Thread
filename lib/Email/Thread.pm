package Email::Thread;
use strict;

use vars qw[$VERSION];
$VERSION = '1.00';

use Email::Simple;
use Email::Address;
use Email::MessageID;
use base qw[Class::Accessor::Fast];
__PACKAGE__->mk_accessors(qw[messages rootset]);

sub thread {
    my ($self) = @_;
    my $table    = $self->{id_table} = {};
    my $children = $self->{children_table} = {};
    my $subjects = $self->{subject_table} = {};

    foreach my $msg ( @{$self->messages} ) {
        my $mid  = $self->_get_mid($msg);
        my @refs = $self->_get_refs($msg);
        my $container = $self->_get_container($mid);
        unless ( $container->message ) {
            $container->message($msg);
            $container->references([map $self->_get_container($_), @refs]);
            if ( @refs ) {
                my $parent = $container->references->[-1];
                $container->parent($parent);
                $self->_add_child($mid, $parent);
            }
        }
    }
    
    $self->_round_children;
    my @rootset = map    {(!$_->message && @{$_->children} == 1) ? $_->children->[0] : $_ }
                  map    {$self->_group_subjects($_) || ()}
                  grep   {!$_->parent || (!$_->message && !@{$_->children})}
                  values %{$table};
    $self->_round_children;

    $self->rootset(\@rootset);
}

sub _round_children {
    my ($self) = @_;
    my $children = $self->{children_table};
    foreach my $parent ( keys %{$children} ) {
        my $container = $self->_get_container($parent);
        $container->children([
          map $self->_get_container($_), @{$children->{$parent}}
        ]);
    }
}

sub _get_mid {
    my ($self, $msg) = @_;
    my ($mid) = Email::Address->parse($msg->header('Message-ID'));
    return $mid ? $mid->address : Email::MessageID->new->address;
}

sub _get_refs {
    my ($self, $msg) = @_;
    return map $_->address,
               Email::Address->parse($msg->header('References')),
               (Email::Address->parse($msg->header('In-Reply-To')))[0];
}

sub _get_container {
    my ($self, $mid) = @_;
    return $self->{id_table}->{$mid}
      ||= Email::Thread::Message->new({message_id => $mid, children => []});
}

sub _add_child {
    my ($self, $child_mid, $parent) = @_;
    my $children = $self->{children_table}->{$parent->message_id} ||= [];
    push @{$children}, $child_mid;
}

sub _group_subjects {
    my ($self, $container) = @_;
    my $subject;
    if ( $container->message ) {
        $subject = $container->message->header('Subject');
    } else {
        foreach my $child ( @{$container->children} ) {
            last if $subject = $child->message->header('Subject');
        }
    }
    $subject =~ s/^(?:\s*Re(?:\[\d+\])?:\s*)+//gi;
    my $root = $self->{subject_table}->{$subject} ||= $container;
    return $container if $root == $container;
    $self->_add_child($container->message_id, $root);
    $container->parent($root);
    return;
}

package Email::Thread::Message;
use base qw[Class::Accessor::Fast];
__PACKAGE__->mk_accessors(qw[message message_id children references parent]);

1;

__END__
