use 5.008; # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::App::Command::critic;
$Dist::Zilla::App::Command::critic::VERSION = '0.001000';
# ABSTRACT: build your dist and run perl critic on the built files.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Dist::Zilla::App -command;






















sub _colorize {
    my ($self, $string, $color) = @_;
    return $string if not defined $color;
    return $string if $color eq q[];
    # $terminator is a purely cosmetic change to make the color end at the end
    # of the line rather than right before the next line. It is here because
    # if you use background colors, some console windows display a little
    # fragment of colored background before the next uncolored (or
    # differently-colored) line.
    my $terminator = chomp $string ? "\n" : q[];
    return  Term::ANSIColor::colored( $string, $color ) . $terminator;
}

sub _colorize_by_severity {
    my ( $self, $critic, @violations ) = @_;
    return @violations if $OSNAME =~ m/MSWin32/xms;
    return @violations if not eval {
        require Term::ANSIColor;
        Term::ANSIColor->VERSION( 2.02 );
        1;
    };
 
    my $config = $critic->config();
    my %color_of = (
        $SEVERITY_HIGHEST   => $config->color_severity_highest(),
        $SEVERITY_HIGH      => $config->color_severity_high(),
        $SEVERITY_MEDIUM    => $config->color_severity_medium(),
        $SEVERITY_LOW       => $config->color_severity_low(),
        $SEVERITY_LOWEST    => $config->color_severity_lowest(),
    );
 
    return map { $self->_colorize( "$_", $color_of{$_->severity()} ) } @violations;
 
}

sub _report_file {
  my ( $self, $critic, $file, @violations ) = @_;
  
  printf "%3d : %s\n", scalar @violations, $file;

  my $verbosity = $critic->config->verbose;
  my $color     = $critic->config->color();

  Perl::Critic::Violation::set_format( 
    Perl::Critic::Utils::verbosity_to_format($verbosity) 
  );

  if ( not $color ) {
    print @violations;
    return;
  }
  return print $self->_colorize_by_severity( $critic, @violations );
}

sub _critique_file {
  my ( $self, $critic, $file ) = @_;
  Try::Tiny::try {
      my @violations = $critic->critique("$file");
      $self->_report_file( $file, @violations );
  } Try::Tiny::catch {
      $self->zilla->log_warn($_);
  };
}

sub execute {
  my ( $self, $opt, $arg ) = @_;

  my ( $target, $latest ) = $self->zilla->ensure_built_in_tmpdir;

  my $critic_config       = 'perlcritic.rc';

  for my $plugin (@{  $self->zilla->plugins }) {
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

  my @files = Perl::Critic::Utils::all_perl_files( $path->child('lib')->stringify );

  for my $file ( @files ) {
    $self->zilla->log("critic> " . Path::Tiny::path($file)->relative($path) );
    
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
