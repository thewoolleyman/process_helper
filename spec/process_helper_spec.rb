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
    output = @clazz.process('echo stdout > /dev/stdout && echo stderr > /dev/null', puts_output: false)
    expect(output).to eq("stdout\n")
  end

  it "captures stderr only" do
    output = @clazz.process('echo stdout > /dev/null && echo stderr > /dev/stderr', puts_output: false)
    expect(output).to eq("stderr\n")
  end

  it "captures stdout and stderr" do
    output = @clazz.process('echo stdout > /dev/stdout && echo stderr > /dev/stderr', puts_output: false)
    expect(output).to eq("stdout\nstderr\n")
  end

  it "fails if command is nil" do
    expect { @clazz.process(nil) }.to raise_error('command must not be empty')
  end

  it "fails if command is empty" do
    expect { @clazz.process('') }.to raise_error('command must not be empty')
  end


  describe "exit status handling" do
    describe ":expected_exit_status == 0" do
      describe "when exit_status == 0" do
        it "succeeds" do
          expect { @clazz.process('echo', puts_output: false) }.to_not raise_error
        end
      end

      describe "when exit_status != 0" do
        it "fails with message" do
          expect do
            @clazz.process('ls /does_not_exist', puts_output: false)
          end.to raise_error(/Command failed, pid \d+ exit 1\. Command: #{Regexp.escape('`ls /does_not_exist`')}\./)
        end
      end
    end

    describe ":expected_exit_status != 0" do
      describe "when exit_status == 0" do
        it "fails with message" do
          expect do
            @clazz.process('echo', expected_exit_status: 1, puts_output: false)
          end.to raise_error(/Command succeeded but was expected to fail, pid \d+ exit 0 \(expected 1\). Command: #{Regexp.escape('`echo`')}\./)
        end
      end
      describe "when exit_status != 0" do
        it "succeeds" do
          expect { @clazz.process('ls /does_not_exist', expected_exit_status: 1, puts_output: false) }.to_not raise_error
        end
      end
    end
  end

  describe "options" do
    describe ":puts_output" do
      describe "== true" do
        it "puts output to stdout" do
          expect do
            @clazz.process('echo stdout > /dev/stdout', puts_output: true)
          end.to output("stdout\n").to_stdout
        end
      end

      describe "== false" do
        it "suppresses stdout" do
          expect do
            @clazz.process('echo stdout > /dev/stdout', puts_output: false)
          end.to_not output("stdout\n").to_stdout
        end
      end
    end
  end
end
