# process_helper

Makes it easier to spawn ruby sub-processes with proper capturing of stdout and stderr streams.

## Goals

* Always raise an exception on unexpected exit status (i.e. return code or `$!`)
* Combine STDOUT and STDERR streams into STDOUT (using [Open3.popen2e](http://ruby-doc.org/stdlib-2.1.5/libdoc/open3/rdoc/Open3.html#method-c-popen2e)),
  so you don't have to worry about how to capture the output of both streams.
* Allow override of the expected exit status (zero is expected by default)
* Provide useful options for suppressing output and including output when an exception
  is raised due to an unexpected exit status
* Support passing multi-line input to the STDIN stream via arrays of strings.
* Provide short forms of all options for terse, concise usage.

## Non-Goals

* Any explicit support for forks, multiple threads, etc.
* Support separate handling of STDOUT and STDERR streams

## Installation

Add this line to your application's Gemfile:

    gem 'process_helper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install process_helper

## Usage

ProcessHelper is a Ruby module you can include in any Ruby code, like this:

```
require 'process_helper'
include ProcessHelper
process('echo "Hello"')
```

By default, ProcessHelper will output any STDERR or STDOUT output to STDOUT, and also
return it as the result of the `#process` method:

## Pivotal Tracker Project

https://www.pivotaltracker.com/n/projects/1117814

## Contributing

1. Fork it ( https://github.com/thewoolleyman/process_helper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
