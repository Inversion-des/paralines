require 'paralines'

describe ParaLines do
	context 'main_sample.rb' do
		def normalize_output(text)
			text
				.gsub(/\d/, 'N')
				.gsub(/ +$/, '')  # remove some spaces at line ends
		end

		let :expected_output do
			<<~OUT
				- start -
				Odd: N+ N+ N+ N+ N+
				Even: [N][N][N][N]
				Done order: NNNNNNNNN
				Worker_N: [subtaskN.....] [subtaskN.....] [subtaskN.....]
				Worker_N..done (in N.NNNs)
				Worker_N..done (in N.NNNs)
				Worker_N..done (in N.NNNs)
				Worker_N..done (in N.NNNs)
				Worker_N..done (in N.NNNs)
				- N workers added
				Worker_N..done (in N.NNNs)
				Worker_N..done (in N.NNNs)
				Worker_N..done (in N.NNNs)
				Worker_N..done (in N.NNNs)
				- all workers added
				- ready -
			OUT
		end

		it 'output to console is ok' do
			output = `#{Gem.ruby} spec/main_sample.rb`

			expect(normalize_output output).to eq expected_output
		end

		it 'output to file is ok' do
			fname = 'out.txt'
			output = `#{Gem.ruby} spec/main_sample.rb > #{fname}`

			expect(output).to be_empty

			file_content = File.read fname
			expect(normalize_output file_content).to eq expected_output
		end
	end
end


RSpec.configure do |c|
	c.filter_run :focus
	c.run_all_when_everything_filtered = true
	c.fail_fast = true
end