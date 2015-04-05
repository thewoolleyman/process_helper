require_relative '../spec_helper'

RSpec.describe ':puts_output option' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  describe '== true (default)' do
    it 'puts output to stdout' do
      expect do
        clazz.process('echo stdout > /dev/stdout', puts_output: true)
      end.to output("stdout\n").to_stdout

      expect do
        clazz.process('echo stdout > /dev/stdout')
      end.to output("stdout\n").to_stdout
    end
  end

  describe '== false' do
    it 'suppresses stdout' do
      expect do
        clazz.process('echo stdout > /dev/stdout', puts_output: false)
      end.to_not output("stdout\n").to_stdout
    end
  end
end
