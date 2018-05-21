class BaseSymbol
	attr_accessor :amount, :discrepancy, :last_appearance

	def initialize(amount=0, last_appearance)
		@amount = amount
		@discrepancy = 0
		@last_appearance = last_appearance
	end

	def update_amount_display
		amount = amount.to_i if amount.to_i == amount.to_f
	end
end

class Cash < BaseSymbol
	def deposit(amount, total)
		@amount += total
	end

	def fee(amount, total)
		@amount -= total
	end
end

class Stock < BaseSymbol
	def buy(amount, cash_obj, total_cash_value)
		@amount += amount
		cash_obj.amount -= total_cash_value
	end

	def sell(amount, cash_obj, total_cash_value)
		@amount -= amount
		cash_obj.amount += total_cash_value
	end

	def dividend(amount, cash_obj, total_cash_value)
		@amount += amount
		cash_obj.amount += total_cash_value
	end
end

def parse_amount(amount_string)
	# For display purposes:
	amount_integer = amount_string.to_i
	amount_float = amount_string.to_f
	return amount_integer == amount_float ? amount_integer : amount_float
end

def handle_position(line_segments, symbol_map, cycles)
	return if line_segments.length != 2

	symbol_name = line_segments[0].to_sym
	amount = parse_amount(line_segments[1])

	# Input assumption: If passed Day 0, then we won't come across a symbol
	# that we've never seen before in a Position section
	if symbol_map.has_key?(symbol_name)
		m_symbol = symbol_map[symbol_name]
		m_symbol.last_appearance = :pos
		m_symbol.discrepancy = amount - m_symbol.amount
	else
		# We must either be in Day 0,
		# otherwise we lost data on this position at some previous point.
		if symbol_name == :Cash
			symbol_map[symbol_name] = Cash.new(amount, :pos)
		else
			stock = Stock.new(amount, :pos)
			stock.discrepancy = amount if cycles > 0
			symbol_map[symbol_name] = stock
		end
	end
end

def handle_transaction(line_segments, symbol_map, cycles)
	return if line_segments.length != 4

	symbol_name = line_segments[0].to_sym
	code = line_segments[1].downcase
	amount = parse_amount(line_segments[2])

	# For display purposes:
	value_integer = line_segments[3].to_i
	value_float = line_segments[3].to_f
	value = value_integer == value_float ? value_integer : value_float

	m_symbol = nil

	if symbol_map.has_key?(symbol_name)
		m_symbol = symbol_map[symbol_name]
		m_symbol.last_appearance = :trn
	else
		m_symbol = Stock.new(0, :trn)
		symbol_map[symbol_name] = m_symbol
	end

	if m_symbol.respond_to?(code)
		m_symbol.send(code, amount, value) if m_symbol.class == Cash
		m_symbol.send(code, amount, symbol_map[:Cash], value) if m_symbol.class == Stock
		m_symbol.update_amount_display
	end
end

def read_input(file_path, symbol_map)
	cycles = -1
	File.foreach(file_path) do |line|
		line.strip!
		next if line.empty?

		line_segments = line.split(' ')

		if line_segments.length == 1
			cycles += 1
			next
		end

		handle_position(line_segments, symbol_map, cycles)
		handle_transaction(line_segments, symbol_map, cycles)
	end
end

def write_output(symbol_map)
	File.open('recon.out', 'w+') do |f|
		symbol_map.sort.each do |symbol_name, m_symbol|
			if m_symbol.last_appearance == :trn && m_symbol.amount > 0
				f.puts "#{symbol_name} #{-m_symbol.amount}"
			elsif m_symbol.discrepancy != 0
				f.puts "#{symbol_name} #{m_symbol.discrepancy}"
			end
		end
	end
end



def run
	symbol_map = {}
	read_input('./recon.in', symbol_map)
	write_output(symbol_map)
end

run




