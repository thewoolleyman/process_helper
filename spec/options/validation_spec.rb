require_relative '../spec_helper'

RSpec.describe 'options validation raises InvalidOptionError' do
  attr_reader :clazz

  before do
    @clazz = Clazz.new
  end

  it 'on single invalid option' do
    expect do
      clazz.process('echo', invalid_option: false)
    end.to raise_error(
        ProcessHelper::InvalidOptionsError,
        /Invalid option\(s\) 'invalid_option' given.*Valid options are.*puts_output/)
  end

  it 'on multiple invalid options' do
    expect do
      clazz.process('echo', invalid_option: false, invalid_option2: true)
    end.to raise_error(
        ProcessHelper::InvalidOptionsError,
        /Invalid option\(s\) 'invalid_option, invalid_option2' given/)
  end

  it 'when both long and short form of option is given' do
    expect do
      clazz.process('echo', puts_output: :always, out: :always)
    end.to raise_error(
        ProcessHelper::InvalidOptionsError,
        "Cannot specify both 'puts_output' and 'out'")
  end

  it 'when integer param is passed non-integer' do
    expect do
      clazz.process('echo', expected_exit_status: '0')
    end.to raise_error(
        ProcessHelper::InvalidOptionsError,
        "'expected_exit_status','exp_st' options must be an Integer")

    expect do
      clazz.process('echo', exp_st: '0')
    end.to raise_error(
        ProcessHelper::InvalidOptionsError,
        "'expected_exit_status','exp_st' options must be an Integer")
  end

  it 'when boolean param is passed non-boolean' do
    expect do
      clazz.process('echo', include_output_in_exception: '0')
    end.to raise_error(
        ProcessHelper::InvalidOptionsError,
        "'include_output_in_exception','out_ex' options must be a boolean")
  end
end