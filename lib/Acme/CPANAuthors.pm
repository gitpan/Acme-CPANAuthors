package Acme::CPANAuthors;

use strict;
use warnings;
use Carp;
use Acme::CPANAuthors::Utils qw( cpan_authors cpan_packages );

our $VERSION = '0.06';

sub new {
  my ($class, @types) = @_;

  unless ( @types ) {
    require Module::Find;
    @types = Module::Find::findsubmod( 'Acme::CPANAuthors' );
  }

  my %authors;
  foreach my $type ( @types ) {
    $type =~ s/^Acme::CPANAuthors:://;

    next if $type =~ /^(?:Register|Utils)$/;

    my $package = "Acme::CPANAuthors\::$type";
    eval "require $package";
    if ( $@ ) {
      carp "$type CPAN Authors are not registered yet: $@";
      next;
    }
    %authors = ( %authors, $package->authors );
  }
  bless \%authors, $class;
}

sub count {
  my $self = shift;

  return scalar keys %{ $self };
}

sub id {
  my ($self, $id) = @_;

  unless ( $id ) {
    return sort keys %{ $self };
  }
  else {
    return $self->{$id} ? 1 : 0;
  }
}

sub name {
  my ($self, $id) = @_;

  unless ( $id ) {
    return sort values %{ $self };
  }
  else {
    return $self->{$id};
  }
}

sub distributions {
  my ($self, $id) = @_;

  return unless $id;

  my @packages;
  foreach my $package ( cpan_packages->distributions ) {
    if ( $package->cpanid eq $id ) {
      push @packages, $package;
    }
  }

  return @packages;
}

sub latest_distributions {
  my ($self, $id) = @_;

  return unless $id;

  my @packages;
  foreach my $package ( cpan_packages->latest_distributions ) {
    if ( $package->cpanid eq $id ) {
      push @packages, $package;
    }
  }

  return @packages;
}

sub avatar_url {
  my ($self, $id, %options) = @_;

  return unless $id;

  require Gravatar::URL;
  my $author = cpan_authors->author($id);

  return Gravatar::URL::gravatar_url( email => $author->email, %options );
}

sub kwalitee {
  my ($self, $id) = @_;

  return unless $id;

  require Acme::CPANAuthors::Utils::Kwalitee;
  return  Acme::CPANAuthors::Utils::Kwalitee->fetch($id);
}

1;

__END__

=head1 NAME

Acme::CPANAuthors - We are CPAN authors

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors = Acme::CPANAuthors->new('Japanese');

    $number   = $authors->count;
    @ids      = $authors->id;
    @distros  = $authors->distributions('ISHIGAKI');
    $url      = $authors->avatar_url('ISHIGAKI');
    $kwalitee = $authors->kwalitee('ISHIGAKI');

  If you don't like this interface, just use specific authors list.

    use Acme::CPANAuthors::Japanese;

    my %authors = Acme::CPANAuthors::Japanese->authors;

    # note that ->author is context sensitive.
    # however, you can't write this without dereference
    # as "keys" checks the type (actually, the number) of args.
    for my $name (keys %{ Acme::CPANAuthors::Japanese->authors }) {
      print Acme::CPANAuthors::Japanese->authors->{$name}, "\n";
    }

=head1 DESCRIPTION

Sometimes we just want to know something to confirm we're not
alone, or to see if we're doing right things, or to look for
someone we can rely on. This module provides you some basic
information on us.

=head1 METHODS

=head2 new

creates an object and loads the subclasses you specified.
If you don't specify any subclasses, it tries to load all
the subclasses found just under the "Acme::CPANAuthors"
namespace.

=head2 count

returns how many CPAN authors are registered.

=head2 id

returns all the registered ids by default. If called with an
id, this returns if there's a registered author of the id.

=head2 name

returns all the registered authors' name by default. If called
with an id, this returns the name of the author of the id.

=head2 distributions, latest_distributions

returns an array of Parse::CPAN::Packages::Distribution objects
for the author of the id. See L<Parse::CPAN::Packages> for details.

=head2 avatar_url

returns gravatar url of the id shown at search.cpan.org.
see L<http://site.gravatar.com/site/implement> for details.

=head2 kwalitee

returns kwalitee information for the author of the id.
This information is scraped from http://kwalitee.perl.org/.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
