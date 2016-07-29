=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

Format - an abstract class for defining file formats

If extending this class, you _must_ supply a field order and also 
define a validation type for each field. Validation types already defined
in this module include:

* boolean
* string
* integer
* floating_point

* range
* comma_separated
* case_insensitive
* strand_integer
* strand_plusminus
* sequence
* dna_sequence
* colour
* rgb_string

Additional custom validation types can be defined in the subclass, but
should be added to this class unless they are very specialised

=cut

package Bio::EnsEMBL::IO::Format;

use strict;
use warnings;

use Bio::EnsEMBL::IO::NamedColours;

=head2 new

    Constructor
    Argument [1+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::Parser

=cut

## Default parameters needed by constructor

our %params = (
              'can_multitrack'  => 0,
              'can_metadata'    => 0,
              'metadata_info'   => {},
              'field_info'      => {},
              'field_order'     => [], 
              );

=head2 new

    Description : constructor
    Returntype  : Bio::EnsEMBL::IO::Format object

=cut

sub new {
  my ($class, $custom_params) = @_;

  my $self = {%params, %$custom_params};

  bless $self, $class;

  return $self;
}

######## BASIC ACCESSORS #############

=head2 can_multitrack 

    Description : getter for multitrack flag
    Returntype  : 1 if format can have multiple tracks, 0 if it can't 
=cut

sub can_multitrack {
  my $self = shift;
  return $self->{'can_multitrack'};
}

=head2 can_metadata 

    Description : getter for metadata flag
    Returntype  : 0 if format cannot have metadata, 1 if metadata is mandatory,
                  -1 if metadata is optional
=cut

sub can_metadata {
  my $self = shift;
  return $self->{'can_metadata'};
}

=head2 get_metadata_info 

    Description : getter for information about valid metadata
    Returntype  : Hashref

=cut

sub get_metadata_info {
  my $self = shift;
  return $self->{'metadata_info'};
}

=head2 set_field_info 

    Description : setter for information about valid fields. Needed by formats
                  that can have optional fields, e.g. BED
    Returntype  : Void 

=cut

sub set_field_info {
  my ($self, $info) = @_;
  if (ref $info eq 'HASH' && keys %$info) {
    $self->{'field_info'} = $info;
  }
  else {
    die "Input must be a non-empty hashref";
  }
}

=head2 get_field_info 

    Description : getter for information about valid fields
    Returntype  : Hashref

=cut

sub get_field_info {
  my $self = shift;
  return $self->{'field_info'};
}

=head2 set_field_order 

    Description : setter for field order. Needed by formats
                  that can have optional fields, e.g. BED
    Returntype  : Void

=cut

sub set_field_order {
  my ($self, $order) = @_;
  if (ref $order eq 'ARRAY' && scalar @$order) {
    $self->{'field_order'} = $order;
  }
  else {
    die "Input must be a non-empty arrayref";
  }
}

=head2 get_field_order 

    Description : getter for order of fields 
    Returntype  : Arrayref

=cut

sub get_field_order {
  my $self = shift;
  return $self->{'field_order'};
}

############ OTHER ACCESSORS ####################

=head2 get_info_for_field

    Description : fetch all information about a given field
    Returntype  : Hashref 

=cut

sub get_info_for_field {
  my ($self, $field) = @_;
  return unless $field;
  my $info = $self->{'field_info'}{$field};
  return $info || {};
}

=head2 get_value_for_field

    Description : fetch a specific value from a field's information
    Returntype  : Undef/String/Arrayref/Hashref

=cut

sub get_value_for_field {
  my ($self, $field, $value) = @_;
  return unless $field && $value;
  my $info = $self->{'field_info'}{$field};
  return unless $info && ref $info eq 'HASH';
  return $info->{$value};
}

########## VALIDATION METHODS #################

=head2 validate_as

    Description : wrapper around more specific validators, for easy processing
    Args        : Type - validation type
                : Value - value to be checked
                : Exemplar (optional) - a specific value or range to be compared against
    Returntype  : Boolean

=cut

sub validate_as {
  my ($self, $type, $value, $match) = @_;
  my $method = 'validate_as_'.$type;
  if ($self->can($method)) {
    return $self->$method($value, $match);
  }
  return 0;
}

=head2 validate_as_boolean 

    Description : Validator for fields that should contain either 0 or 1
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_boolean {
  my ($self, $value) = @_;
  return ($value == 0 || $value == 1) ? 1 : 0;
}

=head2 validate_as_string 

    Description : Validator for fields that should contain alphanumeric characters, 
                    punctuation and/or spaces
    Args        : Type - validation type
                : Value - value to be checked
                : Exemplar (optional) - a specific value or range to be compared against
    Returntype  : Boolean

=cut

sub validate_as_string {
  my ($self, $value, $match) = @_;
  if ($match) {
    return $value eq $match ? 1 : 0;
  }
  else {
    return $value =~ /[[:print:]]+/ ? 1 : 0;
  }
}

=head2 validate_as_integer 

    Description : Validator for fields that should contain an unsigned integer 
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_integer {
  my ($self, $value) = @_;
  return $value =~ /^-?\d+$/ ? 1 : 0;
}

=head2 validate_as_floating_point 

    Description : Validator for fields that should contain a floating point number
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_boolean {
  my ($self, $value) = @_;
  return $value =~ /^-?\d+\.?\d*$/ ? 1 : 0;
}

=head2 validate_as_range

    Description : Validator for fields that can contain a range of numerical values
    Args        : Type - validation type
                : Value - value to be checked
                : Exemplar - range to be compared against
    Returntype  : Boolean

=cut

sub validate_as_range {
  my ($self, $value, $match) = @_;
  return 0 unless ($match && ref $match eq 'ARRAY');
  my ($min, $max) = @$match;
  return ($value <= $max && $value >= $min) ? 1 : 0;
}

=head2 validate_as_comma_separated

    Description : Validator for fields that should contain alphanumeric strings and commas
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_comma_separated {
  my ($self, $value) = @_;
  return $value =~ /^(\w+,)+\w+$/ ? 1 : 0;
}

=head2 validate_as_case_insensitive 

    Description : Validator for fields that should contain a specific value but can
                    case-insensitive
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_case_insensitive {
  my ($self, $value, $match) = @_;
  return 0 unless $match;
  return $value =~ /$match/i ? 1 : 0;
}

=head2 validate_as_rgb_string

    Description : Validator for fields that should contain an RGB colour as a comma-separated string 
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_rgb_string {
  my ($self, $value) = @_;
  return $value =~ /^(\d){1,3},(\d){1,3},(\d){1,3}$/ ? 1 : 0;
}

=head2 validate_as_strand_integer

    Description : Validator for fields that should contain a strand as 0, 1 or -1
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_strand_integer {
  my ($self, $value) = @_;
  return $value =~ /^0|1|-1$/ ? 1 : 0;
}

=head2 validate_as_strand_plusminus

    Description : Validator for fields that should contain a strand as + or -
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_strand_plusminus {
  my ($self, $value) = @_;
  return $value =~ /^\+|-$/ ? 1 : 0;
}

=head2 validate_as_colour 

    Description : Validator for fields that should hold a colour, either as RGB, hex or name
    Returntype  : Boolean
=cut

sub validate_as_colour {
  my ($self, $value) = @_;

  ## Try RGB first, as that's most usual
  my $valid = $self->validate_as_rgb($value);

  ## If not, how about web-friendly hex colours, e.g. #ffcc00?
  unless ($valid) {
    $valid = 1 if $value =~ /^#?[A-Fa-f0-9]{3,6}/;
  }

  ## Fall back to checking Unix named colours
  unless ($valid) {
    my $lookup = Bio::EnsEMBL::IO::NamedColours::named_colours;
    $valid = 1 if $lookup->{$value};
  }

  return $valid;
}

=head2 validate_as_sequence

    Description : Validator for fields that should contain sequence (DNA, RNA or protein) 
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_sequence {
  my ($self, $value) = @_;
  return $value =~ /^[ACDEFGHIKLMNPQRSTUVWY]+$/i ? 1 : 0;
}

=head2 validate_as_dna_sequence

    Description : Validator for fields that should contain DNA sequence only 
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_dna_sequence {
  my ($self, $value) = @_;
  return $value =~ /^[ACGTN]+$/i ? 1 : 0;
}

1;
