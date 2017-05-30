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

Bio::EnsEMBL::IO::Translator::BulkFetcherFeature

=head1 SYNOPSIS

=head1 DESCRIPTION

Translator for Ensembl features (Gene, Transcript, Exon, Translation)
extracted by the the bulk fetcher.

=cut

package Bio::EnsEMBL::IO::Translator::BulkFetcherFeature;

use base qw/Bio::EnsEMBL::IO::Translator/;

use strict;
use warnings;

use Carp;

use Bio::EnsEMBL::Utils::RDF qw/feature_uri/;
use Bio::EnsEMBL::Utils::RDF::Mapper;
use Bio::EnsEMBL::Utils::SequenceOntologyMapper;

my %field_callbacks = (version         => 'version',
		       production_name => 'production_name',
		       id_org_short    => 'id_org_short',
		       type            => 'type',
		       id              => 'id',
		       name            => 'name',
		       description     => 'description',
		       seq_region_name => 'seq_region_name',
		       cs_name         => 'coord_system_name',
		       cs_version      => 'coord_system_version',
		       start           => 'start',
		       end             => 'end',
		       strand          => 'strand',
		       biotype         => 'biotype',
		       rank            => 'rank',
		       taxon_id        => 'taxon_id',
		       uri             => 'uri',
		       synonyms        => 'synonyms',
		       provenance      => 'provenance',
		       homologues      => 'homologues',
		       xrefs           => 'xrefs',
		       dbname          => 'dbname',
		       homologues      => 'homologues',
		       transcripts     => 'transcripts',
		       exons           => 'exons',
		       translations    => 'translations',
		       protein_features => 'protein_features',
		       so_term         => 'so_term'
		      );

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::BulkFetcherFeature

=cut

sub new {
  my ($class, %args) = @_;
  
  my @required_args = qw/xref_mapping_file ontology_adaptor meta_adaptor/;
  my @missing_args;
  map { push @missing_args, $_ unless exists $args{$_} } @required_args;
  confess "Missing arguments required by Bio::EnsEMBL::IO::Translator::BulkFetcherFeature" . join(',', @missing_args)
    if scalar @missing_args;

  # this connects Ensembl to Identifiers.org amongst other things
  my $xref_mapping = Bio::EnsEMBL::Utils::RDF::Mapper->new($args{xref_mapping_file});
  
  my $biotype_mapper = Bio::EnsEMBL::Utils::SequenceOntologyMapper->new($args{ontology_adaptor});
  croak "Bio::EnsEMBL::IO::Translator::Feature requires a Bio::EnsEMBL::Utils::SequenceOntologyMapper"
    unless $biotype_mapper->isa('Bio::EnsEMBL::Utils::SequenceOntologyMapper');

  croak "Bio::EnsEMBL::IO::Translator::Feature requires an ontology adaptor"
    unless $args{ontology_adaptor}->isa('Bio::EnsEMBL::DBSQL::OntologyTermAdaptor');

  croak "Bio::EnsEMBL::IO::Translator::BulkFetcherFeature requires a meta adaptor"
    unless $args{meta_adaptor} and $args{meta_adaptor}->isa('Bio::EnsEMBL::DBSQL::MetaContainer');
  
  $args{ontology_cache} = {};
  $args{mapping} = $xref_mapping;
  $args{biotype_mapper} = $biotype_mapper;
  
  my $self = $class->SUPER::new(\%args);
  $self->version($self->meta_adaptor->list_value_by_key('schema_version')->[0]);
  $self->production_name($self->meta_adaptor->list_value_by_key('species.production_name')->[0]);
  
  # once we have the instance, add our customized callbacks to the translator
  $self->add_callbacks(\%field_callbacks);

  return $self;
}

sub version {
  my ($self, $version) = @_;
  
  $self->{version} = $version if $version;
  return $self->{version};
}

sub production_name {
  my ($self, $prod_name) = @_;

  $self->{production_name} = $prod_name if $prod_name;
  return $self->{production_name};
}

sub ontology_cache {
  my $self = shift;
  return $self->{ontology_cache};
}

sub ontology_adaptor {
  my $self = shift;
  return $self->{ontology_adaptor};
}

sub meta_adaptor {
  my $self = shift;
  return $self->{meta_adaptor};
}

sub ensembl_mapper {
  my $self = shift;
  return $self->{mapping};
}

sub biotype_mapper {
  my $self = shift;
  return $self->{biotype_mapper};
}

sub id_org_short {
  my ($self, $db) = @_;
  defined $db or croak "Undefined db";
  
  return $self->ensembl_mapper->identifier_org_short($db);
}

=head2 type

    Description: Wrapper around RDF feature type field
    Returntype : String

=cut

sub type {
  my ($self, $object) = @_;

  exists $object->{type} and defined $object->{type}
    or croak "Undefined type for feature ", $self->id($object);

  return $object->{type};
}

=head2 id

    Description: Wrapper around RDF feature id field
    Returntype : String

=cut

sub id {
  my ($self, $object) = @_;
  exists $object->{id} and defined $object->{id}
    or croak "Feature does not have id";
  
  return $object->{id};
}

=head2 name

    Description: Wrapper around RDF feature name field
    Returntype : String

=cut

sub name {
  my ($self, $object) = @_;
  
  return $object->{name};
}

=head2 description

    Description: Wrapper around RDF feature description field
    Returntype : String

=cut

sub description {
  my ($self, $object) = @_;
  
  return $object->{description};
}


=head2 seq_region_name

=cut

sub seq_region_name {
  my ($self, $object) = @_;
  
  return $object->{seq_region_name};
}

=head2 coord_system_name

=cut

sub coord_system_name {
  my ($self, $object) = @_;
  
  return $object->{coord_system}{name};
}

=head2 coord_system_version

=cut

sub coord_system_version {
  my ($self, $object) = @_;
  
  return $object->{coord_system}{version};
}

=head2 start

    Description: 
    Returntype : String

=cut

sub start {
  my ($self, $object) = @_;
  
  return $object->{start};
}

=head2 end

    Description: 
    Returntype : String

=cut

sub end {
  my ($self, $object) = @_;
  
  return $object->{end};
}

=head2 strand

    Description: 
    Returntype : String

=cut

sub strand {
  my ($self, $object) = @_;
  
  return $object->{strand};
}

=head2 biotype

    Description: 
    Returntype : String

=cut

sub biotype {
  my ($self, $object) = @_;
  
  return $object->{biotype};
}

=head2 rank

    Description: 
    Returntype : String

=cut

sub rank {
  my ($self, $object) = @_;
  
  return $object->{rank};
}

=head2 taxon_id

    Description: 
    Returntype : 

=cut

sub taxon_id {
  my ($self, $object) = @_;
  
  return $self->meta_adaptor->get_taxonomy_id;
}

=head2 uri

    Description: 
    Returntype : String

=cut

sub uri {
  my ($self, $object) = @_;

  return feature_uri($self->id($object), $self->type($object));
}

=head2 synonyms

    Description: Wrapper around RDF feature synonyms field
    Returntype : ArrayRef

=cut

sub synonyms {
  my ($self, $object) = @_;
  
  return $object->{synonyms} || [];
}

=head2 provenance

    Description: Wrapper around RDF feature provenance field
    Returntype : String

=cut

sub provenance {
  my ($self, $object) = @_;

  my $type = $self->type($object);
  return 'ANNOTATED' if $type eq 'gene';
  return 'INFERRED_FROM_TRANSCRIPT' if $type eq 'transcript';
  return 'INFERRED_FROM_TRANSLATION' if $type eq 'translation';

  croak "Cannot infer provenance for feature of type $type";
}

=head2 xrefs

    Description: Wrapper around feature xrefs field
    Returntype : ArrayRef

=cut

sub xrefs {
  my ($self, $object) = @_;
  
  return $object->{xrefs};
}

=head2 dbname

    Description: 
    Returntype : String

=cut

sub dbname {
  my ($self, $object) = @_;
  
  return $object->{dbname};
}

=head2 homologues

=cut

sub homologues {
  my ($self, $object) = @_;

  return $object->{homologues} || [];
}

=head2 transcripts

=cut

sub transcripts {
  my ($self, $object) = @_;

  return $object->{transcripts} || [];
}

=head2 exons

=cut

sub exons {
  my ($self, $object) = @_;

  return $object->{exons} || [];
}

=head2 translations

=cut

sub translations {
  my ($self, $object) = @_;

  return $object->{translations} || [];
}

=head2 protein_features

=cut

sub protein_features {
  my ($self, $object) = @_;

  return $object->{protein_features} || [];
}



=head2 so_term

    Description: Accessor to look up the Ontology term for an object
    Args[1]    : Feature to loop up term for
    Returntype : String (term)
    Exceptions : If the term can't be found by the Ontology adaptor

=cut

sub so_term {
  my $self = shift;
  my $object = shift;

  my $so_term;
  my ($type, $biotype) = ($self->type($object), $self->biotype($object));
  eval { 
    if ($type eq 'gene') {
      $so_term = $self->biotype_mapper->gene_biotype_to_name($biotype);
    } elsif ($type eq 'transcript') {
      $so_term = $self->biotype_mapper->transcript_biotype_to_name($biotype);
    } else {
      $so_term = $self->_ontology_id($biotype);
    }
  };

  # TODO: better exception handling, e.g. look up ontology_cache?!
  if ($@) { 
    if (! exists $self->{ontology_cache}->{$biotype}) {
      warn sprintf "Failed to map biotype %s to SO term\n", $biotype;
      $self->{ontology_cache}->{$biotype} = undef;
    }
  }
  
  return $so_term;
}

# SO terms often required for dumping RDF
sub _ontology_id {
  my ($self, $term) = @_;
  my $ontology_cache = $self->ontology_cache;
  return $self->{$ontology_cache->{$term}} if $term and exists $self->{$ontology_cache->{$term}};

  my ($typeterm) = @{ $self->ontology_adaptor->fetch_all_by_name( $term, 'SO' ) };
    
  unless ($typeterm) {
    if($term) {
      warn "Can't find SO term for biotype '$term'";
      $self->{$ontology_cache->{$term}} = undef;  
    }
    return;
  }
    
  my $id = $typeterm->accession;
  $self->{$ontology_cache->{$term}} = $id;
  
  return $id;
}

1;
