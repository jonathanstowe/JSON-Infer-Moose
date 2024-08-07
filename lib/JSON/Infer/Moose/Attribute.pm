package JSON::Infer::Moose::Attribute;

use strict;
use warnings;

use Moose;
with qw(
         JSON::Infer::Moose::Role::Classes
         JSON::Infer::Moose::Role::Types
       );

use Scalar::Util qw(reftype looks_like_number);
use List::MoreUtils qw(any);

=head1 NAME

JSON::Infer::Moose::Attribute

=head1 DESCRIPTION

A description of an infered attribute

=head2 METHODS

=over 4

=item new_from_value

This is an alternate constructor that will return a new object based
on the name and attributes infered from the valie.

The third argument is the name of the class the attribute was found in
this will be used to generate the names of any new classes found.

=cut

sub  new_from_value
{
   my ( $self, $name, $value, $class ) = @_;

   my $obj = $self->new(name => $name, class => $class );

   $obj->infer_from_value($value);

   return $obj;
}

=item infer_from_value

This does the actual work of infering the type from the value provided.

=cut

sub infer_from_value
{
   my ( $self, $value ) = @_;

   my $type_constraint;
   if ( defined $value )
   {
      require JSON;
      if (JSON::is_bool($value) )
      {
         $type_constraint = 'Bool';

      }
      elsif ( ref($value) )
      {
          if (reftype($value) eq 'ARRAY')
          {
              $self->is_array(1);
             if (any { ref($_) } @{$value} )
             {
               my $obj = $self->process_object($value);
               $type_constraint = 'ArrayRef[' . $obj->name() . ']';
               $self->item_class($obj->name);
               $self->should_coerce(1);
             }
             else
             {
                $type_constraint = 'ArrayRef';
             }
          }
          else
          {
             my $obj = $self->process_object($value);
             $type_constraint = $obj->name();
             $self->is_object(1);
             $self->should_coerce(1);
          }

      }
      else
      {
         if ( looks_like_number($value) )
         {
            $type_constraint = 'Num';
         }
         else
         {
            $type_constraint = 'Str';
         }
      }
   }
   else
   {
      # take a guess at this.
      $type_constraint = 'Maybe[Str]';
   }

   $self->type_constraint($type_constraint);

}

=item process_object

This is used to process an object value returning the
JSON::Infer::Moose::Class object.

=cut

sub process_object
{
   my ( $self, $value ) = @_;

   require JSON::Infer::Moose::Class;

   my $obj = JSON::Infer::Moose::Class->new_from_data($self->child_class_name(), $value);

   $self->add_classes($obj);
   $self->add_types($obj);
   return $obj;
}

=item name

The name of the attribute

=cut

has name => (
               is => 'rw',
               isa   => 'Str',
            );

=item perl_name

=cut

has perl_name => (
    is      =>  'ro',
    isa     =>  'Str',
    lazy    =>  1,
    builder =>  '_build_perl_name',
);

sub _build_perl_name {
    my ($self) = @_;

    my $s = $self->name;

    $s =~ s{([a-zA-Z][a-zA-Z0-9]*([a-z0-9]|\b))}{
        my $replaced = 0;
        ($a = $1) =~ s<(^[A-Z]+|(?![a-z])[A-Z]+)>< $replaced = 1; "_" . lc $1; >eg;
        ($replaced ? substr $a, 1 : $a);
    }eg;
    return $s;
}



=item type_constraint

The infered type constraint.

=cut

has type_constraint  => (
                           is => 'rw',
                           isa   => 'Str',
                        );



has is_array => (
    is  =>  'rw',
    isa =>  'Bool',
    default =>  0,

);

has item_class => (
    is  =>  'rw',
    isa =>  'Str',
);

has is_object => (
    is  =>  'rw',
    isa =>  'Bool',
    default =>  0,
);

has should_coerce => (
    is  =>  'rw',
    isa =>  'Bool',
    default =>  0,
);

=item class

Name of the class that this was being constructed for.

=cut

has class   => (
                  is => 'rw',
                  isa   => 'Str',
               );

=item child_class_name

Returns the name of a class that will be used for an object type based on
this attribute.

=cut

has child_class_name => (
      is => 'rw',
      isa   => 'Str',
      lazy  => 1,
      builder  => '_get_child_class_name',
);

sub _get_child_class_name
{
   my ( $self ) = @_;

   my $name = $self->name();

   $name =~ s/_(.)/\U$1\E/g;

   return $self->class() . '::' . ucfirst($name);
}

=back

=cut

1;
