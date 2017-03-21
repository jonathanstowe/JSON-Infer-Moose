# JSON::Infer::Moose

Create Perl Moose Classes to represent JSON objects

## Synopsis

```perl

use JSON::Infer::Moose;

my $j = JSON::Infer::Moose->new(uri => 'https://jsonplaceholder.typicode.com/users', class_name => 'Users');

$j->make_classes;

```

## Description


## Install

	perl Build.PL
	./Build
	./Build test
	./Build install

## Copyright & Licence

© Jonathan Stowe 2017
