require_relative '../lib/paralines'

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
				fail if rand < 0.07 if !:with_fail_chanse
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

