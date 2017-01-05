=pod

=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Translator::Transcript - Translates accessor methods between transcript objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::Transcript;

use strict;
use warnings;

use Carp;

use base qw/Bio::EnsEMBL::IO::Translator::Gene/;

my %trans_field_callbacks = (
                              'thickStart'  => 'thickStart',
                              'thickEnd'    => 'thickEnd',
                              'blockCount'  => 'blockCount',
                              'blockStarts' => 'blockStarts',
                              'blockSizes'  => 'blockSizes',
                              );

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::Transcript

=cut

sub new {
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);

    # Once we have the instance, add our customized callbacks
    # to the translator
    $self->add_callbacks(\%trans_field_callbacks);

    return $self;

}


=head2 itemRgb

    Description:
    Returntype : String

=cut

sub itemRgb {
  my ($self, $transcript) = @_;
  return '0,0,0' unless $self->colourmap;
  my $colours = $self->species_defs->colour('transcript');
  my $colour = $colours->{$transcript->biotype}{'default'};
  return $colour ? join(',',$self->colourmap->rgb_by_name($colour)) : undef;
}

=head2 thickStart

    Description: Gets coding start of transcript, for BED format 
    Returntype : Integer

=cut

sub thickStart {
  my ($self, $transcript) = @_;
  return $transcript->coding_region_start;
}

=head2 thickEnd

    Description: Gets coding end of transcript, for BED format 
    Returntype : Integer

=cut

sub thickEnd {
  my ($self, $transcript) = @_;
  return $transcript->coding_region_end;
}

=head2 blockCount

    Description: Gets the number of exons, for BED format 
    Returntype : Integer

=cut

sub blockCount {
  my ($self, $transcript) = @_;
  return scalar(@{$transcript->get_all_Exons});
}

=head2 blockSizes

    Description: Gets the lengths of all exons, for BED format
    Returntype : String

=cut

sub blockSizes {
  my ($self, $transcript) = @_;
  my @sizes;
  foreach my $exon (@{$transcript->get_all_Exons}) {
      push(@sizes, $exon->length);
  }
  @sizes = reverse(@sizes) if ($transcript->strand == -1);
  return join(',', @sizes);
}

=head2 blockStarts

    Description: Gets the start coordinates of all exons, for BED format
    Returntype : String

=cut

sub blockStarts {
  my ($self, $transcript) = @_;
  my @starts;
  foreach my $exon (@{$transcript->get_all_Exons}) {
      push(@starts, $exon->start);
  }
  @starts = reverse(@starts) if ($transcript->strand == -1);
  return join(',', @starts);
}

1;
