package Test::AtteanX::Store::DBI;

use v5.14;
use warnings;
use Test::Roo::Role;
use Test::Moose;
use Attean;
use Attean::RDF;

requires 'create_store';	# create_store( quads => \@triples )

sub test_quads {
	my @q;
	for my $i (0 .. 5) {
		push(@q, quad(iri('s'), iri('p'), literal($i), iri('g')));
		push(@q, quad(iri('s'), iri('p'), blank("b$i"), iri('g')));
	}
	return \@q;
}

test 'ISLITERAL type constraint SARG' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	my $dbh		= $store->dbh;
	my $typecol	= $dbh->quote_identifier('type');
	
	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER ISLITERAL(?o) }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	
	like($sql, qr<SELECT term_id FROM term WHERE $typecol = [?]>, 'generated SQL');
	is($bind[-1], 'literal');
};

test 'ISBLANK type constraint SARG' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	my $dbh		= $store->dbh;
	my $typecol	= $dbh->quote_identifier('type');

	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER isBlank(?o) }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	like($sql, qr<SELECT term_id FROM term WHERE $typecol = [?]>, 'generated SQL');
	is($bind[-1], 'blank', 'bound values');
};

test 'ISIRI type constraint SARG' => sub {
	my $self	= shift;
	my $store	= $self->create_store(quads => $self->test_quads);
	my $model	= Attean::QuadModel->new( store => $store );
	my $dbh		= $store->dbh;
	my $typecol	= $dbh->quote_identifier('type');

	my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER ISIRI(?o) }');
	my $default_graphs	= [iri('g')];
	my $planner	= Attean::IDPQueryPlanner->new();
	my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);

	isa_ok($plan, 'AtteanX::Store::DBI::Plan');
	my ($sql, @bind)	= $plan->sql;
	like($sql, qr<SELECT term_id FROM term WHERE $typecol = [?]>, 'generated SQL');
	is($bind[-1], 'iri');
};

1;
