require_relative 'spec_helper'

class Clazz
  include ProcessHelper
end

RSpec.describe do
  before do
    @clazz = Clazz.new
  end

  it "has a version number" do
    expect(::ProcessHelper::VERSION).to match(/^\d\.\d\.\d\.*\w*$/)
  end

  it "captures stdout only" do
    output = @clazz.process('echo stdout > /dev/stdout && echo stderr > /dev/null')
    expect(output).to eq("stdout\n")
  end

  it "captures stderr only" do
    output = @clazz.process('echo stdout > /dev/null && echo stderr > /dev/stderr')
    expect(output).to eq("stderr\n")
  end

  it "captures stdout and stderr" do
    output = @clazz.process('echo stdout > /dev/stdout && echo stderr > /dev/stderr')
    expect(output).to eq("stdout\nstderr\n")
  end

  it "fails if command is nil" do
    expect { @clazz.process(nil) }.to raise_error('command must not be empty')
  end

  it "fails if command is empty" do
    expect { @clazz.process('') }.to raise_error('command must not be empty')
  end
end
