use 5.008; # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::App::Command::critic;
$Dist::Zilla::App::Command::critic::VERSION = '0.001000';
# ABSTRACT: build your dist and run perl critic on the built files.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Dist::Zilla::App -command;






















sub execute {
  my ( $self, $opt, $arg ) = @_;

  my ( $target, $latest ) = $self->zilla->ensure_built_in_tmpdir;

  my $critic_config       = 'perlcritic.rc';

  for my $plugin (@{  $self->zilla->plugins }) {
    next unless $plugin->isa('Dist::Zilla::Plugin::Test::Perl::Critic');
    $critic_config = $plugin->critic_config if $plugin->critic_config;
  }
  
  require Path::Tiny;

  require Data::Dump;

  my $path = Path::Tiny::path($target);

  print Data::Dump::pp( $target, $latest );

  require Perl::Critic;
  require Perl::Critic::Utils;

  my $critic = Perl::Critic->new( -profile => $path->child($critic_config)->stringify );
  
  $critic->policies();

  my @files = Perl::Critic::Utils::all_perl_files( $path->child('lib')->stringify );

  for my $file ( @files ) {
    $self->zilla->log("critic> $file");
    $critic->critique("$file");
  }
  
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::critic - build your dist and run perl critic on the built files.

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

I have a hard time understanding the output of C<[Test::PerlCritic]>, its rather hard to read
and is needlessly coated in cruft due to having to run through the C<Test::> framework.

It also discards a few preferences from C<perlcritic.rc> such as those that emit colour codes.

Again, conflated by the desire to run through the test framework.

I also don't necessarily want to make the tests pass just to release.

And I also don't necessarily want to run all the other tests just to test critic.

I<TL;DR>

  dzil critic 

  ~ Happyness ~

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
