=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

Translator::Gene - Translates accessor methods between gene objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::Gene;

use strict;
use warnings;

use Carp;

use base qw/Bio::EnsEMBL::IO::Translator::Feature/;

=head2 get_itemRgb

    Description:
    Returntype : String

=cut

sub get_itemRgb {
  my ($self, $gene) = @_;
  return '.' unless $self->species_defs;
  my $colours = $self->species_defs->colour('gene');
  my $colour = $colours->{$gene->biotype}{'default'};
  return $colour ? '('.join(',',$self->rgb_by_name($colour)).')' : undef;
}

1;
