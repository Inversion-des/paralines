# *frozen_string_literal: true — should not be used here to ensure unique object_id for ''

class ParaLines

	def initialize
		set_flags!
		@line_by_key = Hash.new {|h, key| h[key] = {line:h.length, col:1, text:''.freeze} }

		# *ensure flush at exit
		if @f_to_file
			at_exit do
				flush
			end
		end

		if block_given?
			begin
				yield self
			ensure
				flush
			end
		end
	end

	# plines << "done (#{n})"
	def << (text)
		key = Thread.current
		output key, text
	end

	# plines.add_static_line '- 5 workers added'
	def add_static_line(text)
		key = text.object_id
		MUTEX.synchronize do
			d = @line_by_key[key]
			if @f_to_console
				puts text
			else  # for file
				d[:text] += text.to_s
			end
		end
	end

	# plines.add_empty_line
	def add_empty_line
		add_static_line ''
	end

	# done_order_line = plines.add_shared_line 'Done order: '
	# done_order_line << 'some text'
	# part = shared_line.part_open "#{n}… " + later: part.close '+'
	# *can output part progress by adding dots: [LS   ] [cloud2…   ] --> [LS....] [cloud2…   ] — call .close('.' * done_count) multiple times with increasing number of dots
	# *this line can be used by many threads
	def add_shared_line(text)
		key = text.object_id
		output key, text
		# < helper obj with the << and .part_open methods
		Object.new.tap do |o|
			rel = self
			line_by_key = @line_by_key
			f_to_console = @f_to_console

			o.define_singleton_method :<< do |text|
				rel.send :output, key, text
			end

			o.define_singleton_method :part_open do |text_|
				d = line_by_key[key]
				part_col = nil

				MUTEX.synchronize do
					# *we replace placeholder chars like: … or _ or just the last char (order here needed for priority to be able to have _ in text and use … as a placeholder)
					part_col = d[:col] + (text_.index('…'.freeze) || text_.index('_'.freeze) || text_.length-1)

					rel.send :output, key, text_
				end

				# < helper obj with the .close method
				Object.new.tap do |o|
					o.define_singleton_method :close do |end_text|
						# *print the closing chars in the saved position
						MUTEX.synchronize do
							if f_to_console
								rel.send :print_in_line,
									lines_up: line_by_key.count - d[:line],
									col: part_col,
									text: end_text
							else  # for file
								d[:text][part_col-1, end_text.length] = end_text
							end
						end
					end
				end
			end
		end
	end

	# plines.flush
	# *needed only when @f_to_file
	# *can be called manually if the block form was not used and all the threads are finished
	def flush
		puts @line_by_key.map {|key, d| d[:text] }  if @f_to_file
		@line_by_key.clear
	end


	# *needed for rewriting in tests
	private \
	def set_flags!
		@f_to_console = $>.tty?
		@f_to_file = !$>.tty?
	end


	private \
	def output(key, text)
		text = text.to_s
		MUTEX.sync_if_needed do

			# add line
			puts if @f_to_console && !@line_by_key.has_key?(key)

			d = @line_by_key[key]

			if @f_to_console
				print_in_line(
					lines_up: @line_by_key.count - d[:line],
					col: d[:col],
					text: text
				)
			else  # for file
				d[:text] += text
			end

			d[:col] += text.length
		end
	end


	private \
	def print_in_line(lines_up:, col:, text:)
		# \e[s — save cursor position
		# \e[nA — move n lines up
		# \e[nG — move to n-th column
		# \e[u — restore cursor position
		print <<~OUT.delete("\n")
			\e[s
			\e[#{lines_up}A
			\e[#{col}G
			#{text}
			\e[u
		OUT
	end


	MUTEX = Mutex.new
	def MUTEX.sync_if_needed
		if owned?
			yield
		else
			synchronize do
				yield
			end
		end
	end

end