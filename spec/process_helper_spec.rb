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
      describe "== true (default)" do
        it "puts output to stdout" do
          expect do
            @clazz.process('echo stdout > /dev/stdout', puts_output: true)
          end.to output("stdout\n").to_stdout

          expect do
            @clazz.process('echo stdout > /dev/stdout')
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

    describe ":puts_output_only_on_exception" do
      describe "== true (default)" do
        describe "puts output to stdout if exception" do
          it "when :expected_exit_status is zero" do
            expect do
              @clazz.process('ls /does_not_exist', puts_output_only_on_exception: true)
            end.to raise_error(/Command failed/).
                and(output("ls: /does_not_exist: No such file or directory\n").to_stdout)
          end

          it "when :expected_exit_status is nonzero" do
            expect do
              @clazz.process('echo stdout > /dev/stdout',
                expected_exit_status: 1, puts_output_only_on_exception: true)
            end.to raise_error(/Command succeeded but was expected to fail/).
                and(output("stdout\n").to_stdout)
          end
        end
      end

      describe "== false and :puts_output == false" do
        describe "does not puts output to stdout if exception" do
          it "when :expected_exit_status is zero" do
            expect do
              @clazz.process('ls /does_not_exist', puts_output: false, puts_output_only_on_exception: false)
            end.to raise_error(/Command failed/).
                and(not_output.to_stdout)
          end

          it "when :expected_exit_status is nonzero" do
            expect do
              @clazz.process('echo stdout > /dev/stdout',
                expected_exit_status: 1, puts_output: false, puts_output_only_on_exception: false)
            end.to raise_error(/Command succeeded but was expected to fail/).
                and(not_output.to_stdout)
          end
        end
      end

      it "fails if :puts_output is also explicitly set to true" do
        expect do
          @clazz.process('ls', puts_output: true, puts_output_only_on_exception: true)
        end.to raise_error("'puts_output' and 'puts_output_only_on_exception' options cannot both be true")

      end
    end
  end
end
