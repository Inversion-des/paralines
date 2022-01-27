# ParaLines Ruby Gem [![version](https://badge.fury.io/rb/paralines.svg)](https://rubygems.org/gems/paralines)

Nice output to console/file from concurrent threads:

![sample output](sample_output.gif)

#### Features:
- only 170 lines of code;
- no dependencies;
- works on Linux and Windows;
- if output to file and the script crashes in the middle — it is handled with at_exit and in the file, you will find partial output not an empty file.

## Installation

    gem install paralines

or in your Gemfile

    gem 'paralines'

## Sample with all the features (output is on the gif animation)

```ruby
require 'paralines'

puts '- start -'

ParaLines.new do |plines|

    odd_line = plines.add_shared_line 'Odd: '
    even_line = plines.add_shared_line 'Even: '
    done_order_line = plines.add_shared_line 'Done order: '

    workers = (0..9).map do |n|
        Thread.new do
            if n == 0
                # special case with sub-tasks in sub-threads
                shared_line = plines.add_shared_line "Worker_#{n}: "
                (1..3).map do |sn|
                    Thread.new do
                        sleep 0.01
                        ticks_n = 5
                        part = shared_line.part_open "[subtask#{sn}…#{' '*(ticks_n-1)}] "
                        ticks_n.times do |n|
                            sleep rand
                            part.close '.' * (n+1)
                        end
                    end
                end.each &:join
                next
            else
                sleep n>5 ? 0.3 : 0.1  # make Worker_0 to be the first in the list
            end
            plines << "Worker_#{n}"
            start = Time.now
            n.odd? \
                ? (odd_part = odd_line.part_open "#{n}… ")
                : (even_part = even_line.part_open "[#{n} ")
            2.times do
                sleep rand
                plines << '.'
                fail if rand < 0.07 if !:with_fail_chanse   # remove ! here to test crashes
            end
            time = Time.now - start
            plines << "done (in %.3fs)" % time
            done_order_line << n
            odd_part&.close '+'
            even_part&.close ']'
        end
            .tap do
                if n==5
                    sleep 0.2
                    plines.add_static_line '- 5 workers added'
                elsif n==9
                    sleep 0.4
                    plines.add_static_line '- all workers added'
                end
            end
    end.each &:join

end

puts '- ready -'

```

### Usage without a block
```ruby
require 'paralines'

plines = ParaLines.new

plines.add_static_line 'Gems latest versions'
plines.add_empty_line

gems = %w[sinatra rspec paralines rails hanami]

plines.add_static_line '- Random order:'
threads = gems.map do |name|
    Thread.new do
        plines << name.ljust(15, '.')
        res = `gem list -r #{name} -e`
        plines << 'v' + res[/\((.+)\)/, 1]
    end
end
sleep 0.2
plines.add_empty_line
plines.add_static_line '- Sorted:'
threads += gems.sort.map do |name|
    sline = plines.add_shared_line name.ljust(15, '.')
    Thread.new do
        res = `gem list -r #{name} -e`
        sline << 'v' + res[/\((.+)\)/, 1]
    end
end

threads.each &:join
```

## Contributing

Bug reports and pull requests are welcome on GitHub: https://github.com/Inversion-des/paralines

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
