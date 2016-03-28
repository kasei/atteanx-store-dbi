use Test::Roo;
use Test::Modern;
use Test::Exception;
use List::MoreUtils qw(all);

use v5.14;
use warnings;
no warnings 'redefine';

use Attean;
use Attean::RDF;
use AtteanX::Store::DBI;

sub create_store {
	my $self	= shift;
	my %args	= @_;
	my $quads	= $args{quads} // [];
	my @connect		= AtteanX::Store::DBI->dbi_connect_args(
		'postgresql',
		database	=> $ENV{ATTEAN_STORE_PG_DATABASE},
		host		=> $ENV{ATTEAN_STORE_PG_HOST},
		user		=> $ENV{ATTEAN_STORE_PG_USER},
		password	=> $ENV{ATTEAN_STORE_PG_PASSWORD},
	);
	my $dbh			= DBI->connect(@connect);
	my $store		= Attean->get_store('DBI')->new( dbh => $dbh );
	foreach my $g ($store->get_graphs->elements) {
		$store->drop_graph($g);
	}
	foreach my $q (@$quads) {
		$store->add_quad($q);
	}
	return $store;
}

unless (all { exists $ENV{$_} } qw(ATTEAN_STORE_PG_DATABASE ATTEAN_STORE_PG_HOST ATTEAN_STORE_PG_USER ATTEAN_STORE_PG_PASSWORD)) {
	plan skip_all => "Set the MySQL environment variables to run these tests (ATTEAN_STORE_PG_DATABASE, ATTEAN_STORE_PG_HOST, ATTEAN_STORE_PG_USER, ATTEAN_STORE_PG_PASSWORD)";
}

with 'Test::Attean::QuadStore', 'Test::Attean::MutableQuadStore';
run_me; # run these Test::Attean tests

{
	my @q;
	for my $i (0 .. 5) {
		push(@q, quad(iri('s'), iri('p'), literal($i), iri('g')));
		push(@q, quad(iri('s'), iri('p'), blank("b$i"), iri('g')));
	}
	my $store	= __PACKAGE__->create_store(quads => \@q);
	my $model	= Attean::QuadModel->new( store => $store );

	subtest 'ISLITERAL type constraint SARG' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER ISLITERAL(?o) }');
		my $default_graphs	= [iri('g')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);
	
		isa_ok($plan, 'AtteanX::Store::DBI::Plan');
		my ($sql, @bind)	= $plan->sql;
		like($sql, qr<SELECT term_id FROM term WHERE "type" = [?]>, 'generated SQL');
		is($bind[-1], 'literal');
	};

	subtest 'ISBLANK type constraint SARG' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER isBlank(?o) }');
		my $default_graphs	= [iri('g')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);
	
		isa_ok($plan, 'AtteanX::Store::DBI::Plan');
		my ($sql, @bind)	= $plan->sql;
		like($sql, qr<SELECT term_id FROM term WHERE "type" = [?]>, 'generated SQL');
		is($bind[-1], 'blank', 'bound values');
	};

	subtest 'ISIRI type constraint SARG' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER ISIRI(?o) }');
		my $default_graphs	= [iri('g')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);
	
		isa_ok($plan, 'AtteanX::Store::DBI::Plan');
		my ($sql, @bind)	= $plan->sql;
		like($sql, qr<SELECT term_id FROM term WHERE "type" = [?]>, 'generated SQL');
		is($bind[-1], 'iri');
	};

	subtest 'STRSTARTS SARG with string literal' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER STRSTARTS(?o, "foo") }');
		my $default_graphs	= [iri('g')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);
	
		isa_ok($plan, 'AtteanX::Store::DBI::Plan');
		my ($sql, @bind)	= $plan->sql;
		like($sql, qr#SELECT "t0"."subject" AS "s", "t0"."predicate" AS "p", "t0"."object" AS "o" FROM quad t0, term (\S+) WHERE [(]t0.graph IN [(][?][)][)] AND [(]"t0"."object" = \1.term_id[)] AND [(]\1."type" = [?][)] AND [(]STRPOS[(]\1.value, [?][)] = [?][)] AND [(]\1.datatype = [?][)]#, 'generated SQL');
		is_deeply([splice(@bind, 1, 3)], ['literal', 'foo', 1], 'bound values');
	};

	subtest 'STRSTARTS SARG with language literal' => sub {
		my $algebra	= Attean->get_parser('SPARQL')->parse('SELECT * WHERE { ?s ?p ?o FILTER STRSTARTS(?o, "foo"@en) }');
		my $default_graphs	= [iri('g')];
		my $planner	= Attean::IDPQueryPlanner->new();
		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);
	
		isa_ok($plan, 'AtteanX::Store::DBI::Plan');
		my ($sql, @bind)	= $plan->sql;
		like($sql, qr#SELECT "t0"."subject" AS "s", "t0"."predicate" AS "p", "t0"."object" AS "o" FROM quad t0, term (\S+) WHERE [(]t0.graph IN [(][?][)][)] AND [(]"t0"."object" = \1.term_id[)] AND [(]\1."type" = [?][)] AND [(]STRPOS[(]\1.value, [?][)] = [?][)] AND [(]\1.language = [?][)]#, 'generated SQL');
		is_deeply([splice(@bind, 1)], ['literal', 'foo', 1, 'en'], 'bound values');
	};
}

done_testing();
