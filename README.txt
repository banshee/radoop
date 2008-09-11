= Radoop


== DESCRIPTION:

To use, you subclass Radoop like this:

----
require 'rubygems'
require 'radoop'

class WordCount < Radoop
  include_package "org.apache.hadoop.io"

  output_key_class Text
  output_value_class IntWritable

  def map(k, v, output, reporter)
    values = v.to_s.split(/\W+/)
    values.each do |v|
      output.collect(v.to_hadoop_text, 1.to_int_writable)
    end
  end
end
----

And then run the radoop command (here with --verbose turned on).  No compiling, no building jars, it should just feel something like running a normal Ruby script.

Options are things like:

--radoop_file word_count.rb # The name of the file containing the Radoop subclass
--radoop_class WordCount # The name of the Radoop subclass
--output_path /tmp/j1 
--input_path /user/james/tmp/tale.txt,/user/james/tmp/tale1.txt -v

Radoop handles zipping up your jruby install directory, your gem directories, and your ruby files, and puts them on the machines running tasks using the DistributedCache mechanism.


== FEATURES/PROBLEMS:

* FIX (list of features or problems)

== SYNOPSIS:

  FIX (code sample of usage)

== REQUIREMENTS:

* FIX (list of requirements)

== INSTALL:

* FIX (sudo gem install, anything else)

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
