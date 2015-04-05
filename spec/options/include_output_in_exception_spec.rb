require_relative '../spec_helper'

RSpec.describe ':include_output_in_exception option' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  describe '== true (default)' do
    describe 'includes output in exception if exception' do
      it 'when :expected_exit_status is zero' do
        expect do
          clazz.process(
            'ls /does_not_exist',
            puts_output: false,
            include_output_in_exception: true
          )
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command Output: "ls: \/does_not_exist: No such file or directory\n"/)
      end

      it 'when :expected_exit_status is nonzero' do
        expect do
          clazz.process(
            'echo stdout > /dev/stdout',
            puts_output: false,
            expected_exit_status: 1,
            include_output_in_exception: true)
        end.to raise_error(
            ProcessHelper::UnexpectedExitStatusError,
            /Command Output: "stdout\n"/)
      end
    end
  end

  describe '== false' do
    describe 'does not includes output in exception if exception' do
      it 'when :expected_exit_status is zero' do
        expect do
          clazz.process(
            'ls /does_not_exist',
            puts_output: false,
            include_output_in_exception: false)
        end
          .to raise_error(ProcessHelper::UnexpectedExitStatusError) do |e|
          expect(e.message).not_to match(/Command Output/)
          expect(e.message).not_to match(/No such file or directory/)
        end
      end

      it 'when :expected_exit_status is nonzero' do
        expect do
          clazz.process(
            'echo stdout > /dev/stdout',
            expected_exit_status: 1,
            puts_output: false,
            include_output_in_exception: false)
        end.to raise_error(ProcessHelper::UnexpectedExitStatusError) do |e|
          expect(e.message).not_to match(/Command Output:/)
          expect(e.message).not_to match(/No such file or directory/)
        end
      end
    end
  end
end
