require_relative 'spec_helper'

RSpec.describe 'input handling' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'handles a single line of STDIN' do
    expect do
      clazz.process(
        "ruby -e 'while(i=$stdin.gets) do puts i; end'",
        input_lines: ['input1']
        )
    end.to output("input1\n").to_stdout
        .and(not_output.to_stderr)
  end
end
