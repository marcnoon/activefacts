#
# ActiveFacts tests: Parse all NORMA files and check the generated CQL.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/orm'
require 'activefacts/generate/cql'

include ActiveFacts

describe "Norma Loader" do
  ORM_CQL_FAILURES = %w{
    ServiceDirector
  }
  # Generate and return the CQL for the given vocabulary
  def cql(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::CQL.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.readlines
  end

  #Dir["examples/norma/Bl*.orm"].each do |orm_file|
  #Dir["examples/norma/Meta*.orm"].each do |orm_file|
  #Dir["examples/norma/[AC]*.orm"].each do |orm_file|
  Dir["examples/norma/*.orm"].each do |orm_file|
    expected_file = orm_file.sub(%r{/norma/(.*).orm\Z}, '/CQL/\1.cql')

    actual_file = orm_file.sub(%r{examples/norma/(.*).orm\Z}, 'spec/actual/\1.cql')

    it "should load #{orm_file} and dump CQL matching #{expected_file}" do
      pending if ORM_CQL_FAILURES.include? File.basename(orm_file, ".orm")
      vocabulary = ActiveFacts::Input::ORM.readfile(orm_file)

      cql = cql(vocabulary)
      # Save the actual file:
      File.open(actual_file, "w") { |f| f.write cql*"" }

      pending unless File.exists? expected_file
      cql.should == File.open(expected_file) {|f| f.readlines}
      File.delete(actual_file)
    end
  end
end
