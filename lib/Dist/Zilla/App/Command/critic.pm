use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::App::Command::critic;
$Dist::Zilla::App::Command::critic::VERSION = '0.001001';
# ABSTRACT: build your dist and run Perl::Critic on the built files.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Dist::Zilla::App '-command';









































sub _print {
  my ( $self, @message ) = @_;
  print @message or $self->zilla->log_fatal('Cant write to STDOUT');
  return;
}

sub _colorize {
  my ( undef, $string, $color ) = @_;
  return $string if not defined $color;
  return $string if q[] eq $color;

  # $terminator is a purely cosmetic change to make the color end at the end
  # of the line rather than right before the next line. It is here because
  # if you use background colors, some console windows display a little
  # fragment of colored background before the next uncolored (or
  # differently-colored) line.
  my $terminator = chomp $string ? "\n" : q[];
  return Term::ANSIColor::colored( $string, $color ) . $terminator;
}

sub _colorize_by_severity {
  my ( $self, $critic, @violations ) = @_;
  return @violations if $^O =~ m/MSWin32/xms;
  return @violations if not eval {
    require Term::ANSIColor;
    require Perl::Critic::Utils::Constants;
    ## no critic (Variables::ProtectPrivateVars)
    Term::ANSIColor->VERSION($Perl::Critic::Utils::Constants::_MODULE_VERSION_TERM_ANSICOLOR);
    1;
  };

  my $config = $critic->config();
  require Perl::Critic::Utils;

  my %color_of = (
    $Perl::Critic::Utils::SEVERITY_HIGHEST => $config->color_severity_highest(),
    $Perl::Critic::Utils::SEVERITY_HIGH    => $config->color_severity_high(),
    $Perl::Critic::Utils::SEVERITY_MEDIUM  => $config->color_severity_medium(),
    $Perl::Critic::Utils::SEVERITY_LOW     => $config->color_severity_low(),
    $Perl::Critic::Utils::SEVERITY_LOWEST  => $config->color_severity_lowest(),
  );

  return map { $self->_colorize( "$_", $color_of{ $_->severity() } ) } @violations;

}

sub _report_file {
  my ( $self, $critic, undef, $rpath, @violations ) = @_;

  if ( @violations > 0 ) {
    $self->_print("\n");
  }
  $self->_print( sprintf "%s : %d violations\n", $rpath, scalar @violations );

  if ( @violations > 0 ) {
    $self->_print("\n");
  }
  my $verbosity = $critic->config->verbose;
  my $color     = $critic->config->color();

  require Perl::Critic::Violation;
  require Perl::Critic::Utils;

  ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
  Perl::Critic::Violation::set_format( Perl::Critic::Utils::verbosity_to_format($verbosity) );

  if ( not $color ) {
    $self->_print(@violations);
  }
  $self->_print( $self->_colorize_by_severity( $critic, @violations ) );
  return;
}

sub _critique_file {
  my ( $self, $critic, $file, $rpath ) = @_;
  Try::Tiny::try {
    my @violations = $critic->critique("$file");
    $self->_report_file( $critic, $file, $rpath, @violations );
  }
  Try::Tiny::catch {
    $self->zilla->log($_);
  };
  return;
}

sub _subdirs {
  my ( $self, $root, @children ) = @_;
  my @out;
  for my $child (@children) {
    my $path = $root->child($child);
    next unless -d $path;
    push @out, $path->stringify;
  }
  return @out;
}

sub execute {
  my ( $self, undef, undef ) = @_;

  my ( $target, undef ) = $self->zilla->ensure_built_in_tmpdir;

  my $critic_config = 'perlcritic.rc';

  for my $plugin ( @{ $self->zilla->plugins } ) {
    next unless $plugin->isa('Dist::Zilla::Plugin::Test::Perl::Critic');
    $critic_config = $plugin->critic_config if $plugin->critic_config;
  }

  require Path::Tiny;
  require Try::Tiny;

  my $path = Path::Tiny::path($target);

  require Perl::Critic;
  require Perl::Critic::Utils;

  my $critic = Perl::Critic->new( -profile => $path->child($critic_config)->stringify );

  $critic->policies();

  ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
  my @files = Perl::Critic::Utils::all_perl_files( $self->_subdirs( $path, qw( lib bin script ) ) );

  for my $file (@files) {
    my $rpath = Path::Tiny::path($file)->relative($path);
    $self->_critique_file( $critic, $file, $rpath );
  }
  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::critic - build your dist and run Perl::Critic on the built files.

=head1 VERSION

version 0.001001

=head1 DESCRIPTION

I have a hard time understanding the output of C<[Test::Perl::Critic]>, its rather hard to read and is needlessly coated in cruft
due to having to run through the C<Test::> framework.

It also discards a few preferences from C<perlcritic.rc> such as those that emit color codes.

Again, conflated by the need to run through the test framework.

I also don't necessarily want to make the tests pass just to release.

And I also don't necessarily want to run all the other tests just to test critic.

I<TL;DR>

  dzil critic

  ~ Happyness ~

The result will be similar to doing:

   dzil run --no-build perlcritic -p perlcritic.rc lib/

Except that is useless to me because it doesn't output the file names anywhere unless you have a verbosity level that incorporates
a file name in I<EACH> violation, which for me, is undesirable clutter when you have 20 violations in a single file. ( And the most
L<< verbose violation levels|perlcritic/verbose-N-FORMAT >>, that is, all except C<1,2,3,5,7> lack C<%f> )

=head1 CONFIGURATION

This module has little configuration at this point.

C<perlcritic.rc> is the name of the default profile to use, and it must be in your I<BUILT> tree to be used.

Alternatively, I<IF> you are using C<[Test::Perl::Critic]> in your dist, the path specified to C<perlcritic.rc> in that module
will be used.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
