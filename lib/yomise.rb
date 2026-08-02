# frozen_string_literal: true
require "csv"
require "roo-xls"
require "spreadsheet"
require "rubyXL"
require "rover"
require "daru"
require_relative "./to_csv"
require_relative "./longest_line"
require_relative "yomise/version"

## 欲しい: DateTimeをいい感じのメソッドに変える
## 2列目以降ならこんな感じ
# piv.vectors.to_a[1..].each do |c|
#	piv[c] = piv[c].map { _1.to_s.gsub("T", " ").gsub("+00:00", "")}
# end

## joinで列順変更不要のものが欲しい

# write_excelでDF横並び、縦並びも可にしたい

module Yomise
  class Error < StandardError; end
	
	module_function

	def read(path, **opt)
		return /csv$/i === path ? read_csv(path, **opt) : read_excel(path, **opt)
	end
	
	# ##Generate Array from CSV File, and convert it to Hash or DataFrame.
	# **opt candidate= line_from: 1, header: 0
	def read_csv(path, format: :rover, encoding: "utf-8", liberal_parsing: true, reconvert_utf8: false, col_sep: ",", index: nil, **opt)
		## TODO.. index: option that designate column number to generate DF index.
		## That is, revicing set_index method.

		# Get 2D Array
		begin
			if liberal_parsing
				csvd = CSV.read(path, encoding: encoding, liberal_parsing: true)
				if encoding.to_s.downcase != "utf-8" 
					csv = csvd.to_a.map {|l| l.map {|cell| cell.nil? ? nil : cell.encode("utf-8", invalid: :replace, replace: '') }}
				else
					csv = csvd
				end
				
				encoding = "utf-8"
			else
				# Old style (Not Recommended)
				# This "&:read" is not Yomise's function(defined avobe here).. parhaps File's method.
				csv = CSV.parse(File.open(path, encoding: encoding, &:read), col_sep: col_sep)
			end
		rescue
			# Try Another Encoding
			## puts "Fail Encoding #{encoding}. Trying cp932..."
			if liberal_parsing
				csvd = CSV.read(path, encoding: "cp932", liberal_parsing: true)
				if encoding.to_s.downcase != "utf-8" 
					csv = csvd.to_a.map {|l| l.map {|cell| cell.nil? ? nil : cell.encode("utf-8", invalid: :replace, replace: '') }}
				else
					csv = csvd
				end
				
				encoding = "UTF-8"
			else
				# Old style (Not Recommended)
				# This "&:read" is not Yomise's function(defined avobe here).. parhaps File's method.
				csv = CSV.parse(File.open(path, encoding: "cp932", &:read), col_sep: col_sep)
			end
			encoding = "cp932"
		end

		if reconvert_utf8
			csv = csv.map {|l| l.map {|cell| cell.nil? ? nil : cell.encode("UTF-8")}}
		end
		
		if format.to_s == "array"
			return csv
		elsif format.to_s == "hash"
			h, i = to_hash(csv, **opt)
			return h
		elsif format.to_s == "csv"
			return csv.to_csv
		elsif format.to_s == "numo"
			return csv  # Under Construction
		else # include format.nil? (in this case, convert to Daru::DF).

			h, ind_orig = to_hash(csv, index: index, **opt)
			ans = to_df(h, format: format)
			
			# Converting Encode and Setting index.. rover not supported yet
			if format.to_s == "daru"
				ans.convert_enc!(from: encoding, to: "utf-8") if encoding.to_s.downcase != "utf-8"
				begin
					ans.index = ind_orig if index
				rescue
					warn "Indexing failed (Parhaps due to duplicated index)."
				end
			end
			
			return ans
		end
	end

	# ##Generate Array from EXCEL File, and convert it to Hash or DataFrame.
	# **opt candidate= line_from: 1, header: 0)
	def read_excel(path, sheet_i: 0, format: :rover, encoding: "utf-8", index: nil, **opt)
		a2d = open_excel(path, sheet_i, encoding: encoding) # Get 2D Array

		if format.to_s == "array"
			return a2d
		elsif format.to_s == "hash"
			h, i = to_hash(a2d, **opt)
			return h
		elsif format.to_s == "csv"
			return a2d.to_csv
		elsif format.to_s == "numo"
			return a2d  # Under Construction
		else # include format.nil?
			h, ind_orig = to_hash(a2d, index: index, **opt)
			ans = to_df(h, format: format)
			if format.to_s == "daru"
				begin
					ans.index = ind_orig if index
				rescue
					warn "Indexing failed (Parhaps due to duplicated index)."
				end
			end
			return ans
		end
	end
	
	# Convert 2d Array to Hash
	## header: nil -> Default Headers(:column1, column2,...) are generated.
	## Option line_ignored, is not implemented yet.
	def to_hash(array2d, line_from: 1, line_until: nil, line_ignored: nil,
		                 column_from: nil, column_until: nil, 
		                 header: 0, symbol_header: false,
						 replaced_by_nil: [], analyze_type: true,
	                     index: nil)
				## TODO.. column_from: , column_until:
		
		# Define Read Range------------		
		lfrom, luntil = line_from, line_until
		lf_reg, lu_reg = line_from.kind_of?(Regexp), line_until.kind_of?(Regexp)
		
		if lf_reg || lu_reg
			lines_ary = array2d.map{ _1.join "," }
			lfrom = lines_ary.find_index{ line_from === _1 } if lf_reg
			luntil = (lines_ary.length-1) - lines_ary.reverse.find_index{ line_until === _1 } if lu_reg
		end

		# And get originally array-----
		output = array2d[lfrom...luntil]
		# -----------------------------

		# Then get data of index-------
		ind_orig = index ? output.map{ _1[index] } : nil
		# -----------------------------
		
		# Selecct Column---------------
		output = output.map { _1[column_from...column_until] } if column_from || column_until
			
		# Define Data Array------------
		output_transpose = output[0].zip(*output[1..])
		output_transpose = fix_array(output_transpose, replaced_by_nil, analyze_type)
		# -----------------------------

		# Define Header----------------
		if header
			hd = check_header(array2d[header])[column_from...column_until]
		else
			hd = [*0...(output.longest_line)].map{"column#{_1}"}
		end
		# hd = header.nil? ? [*0...(output.longest_line)].map{"column#{_1}"} : check_header(array2d[header])
		
		hd = hd.map { _1.intern } if symbol_header
		# -----------------------------

		# Make Hash(Header => Data Array)  
		return hd.each_with_object({}).with_index {|(hdr, hash), i| hash[hdr]=output_transpose[i]}, ind_orig
	end
	
	# Convert Hash to DataFrame
	def to_df(d, format: :rover)
		if format.to_s == "daru"
			Daru::DataFrame.new(d)
		else
			Rover::DataFrame.new(d)
		end
	end

	# Rover用: nil や nanを取り除くマスク、または二値の列(true-false value)生成
	def is_available(value, truevalue: true, falsevalue: false, blank_str_is_false: true)
		if value.nil?
			falsevalue
		else
			if value.is_a? Numeric
				!value.nan? ? truevalue : falsevalue
			elsif value.is_a? String
				if value == ""
					blank_str_is_false ? falsevalue : truevalue
				else
					truevalue
				end
			else
				truevalue
			end
		end
	end

	def available(data, truevalue: true, falsevalue: false, blank_str_is_false: true)
		if data.is_a? Rover::Vector
			data.map { |v| is_available(v, truevalue: truevalue, falsevalue: falsevalue, blank_str_is_false: blank_str_is_false) }
		elsif data.is_a? Rover::DataFrame
			dfdata = data.keys.map {|k| data[k].map { |d| is_available(d, truevalue: truevalue, falsevalue: falsevalue, blank_str_is_false: blank_str_is_false) } }
			Rover::DataFrame.new(data.keys.zip(dfdata).map{[_1, _2]}.to_h)
		end
	end

	#----------------------------
	# Private metods from here
	#----------------------------

	# Genarate Array from excel file
	def open_excel(path, sheet_i, encoding: "utf-8")
		if /xls(x|m)$/ === path
			puts "Sorry, encoding option is not supported yet for xlsx file." if encoding != "utf-8"

			book = Roo::Excelx.new(path)
			s = book.sheet(sheet_i)
			
			## bottole neck
			return s.to_a

		# xls
		else
			begin
				Spreadsheet.client_encoding = encoding
				ss = Spreadsheet.open(path)
			rescue Encoding::InvalidByteSequenceError
				puts "Fail Encoding #{encoding}. Trying Windows-31J..."
				Spreadsheet.client_encoding = "Windows-31J"
				ss = Spreadsheet.open(path)
			end

			a2d = []
			ss.worksheets[sheet_i].rows.each do |row|
				a1d = []
				row.each {|cell| a1d.push cell}
				a2d.push a1d
			end

			return a2d
		end
	end

	def write_excel(dfs, filename, sheetnames: nil)
			
		dfs = [dfs] if !dfs.is_a?(Array)
		if sheetnames.nil?
			sheetnames = dfs.map.with_index {|d, i| "sheet#{i+1}" }
		end

		workbook = RubyXL::Workbook.new

		dfs.each_with_index do |df, idx|
			worksheet = workbook.add_worksheet(
				sheetnames.length <= idx ? "sheet#{idx}" : sheetnames[idx].to_s
			)
			
			df.to_h.each_with_index do |(key, itms), coli|
				worksheet.add_cell(0, coli, key)
				itms.each_with_index do |itm, linei|
					worksheet.add_cell(linei+1, coli, itm.to_s)
				end
			end
		end

		workbook.worksheets.delete_at(0)
		workbook.write(filename)

	end

	# Fix Array (Replace specific values to nil, recognize value type and cast values to the type.)
	def fix_array(array2d, replaced_by_nil, analyze_type)
		ans = array2d
		
		## Replace Blank or User-Selected Value
		ans = ans.map do |column| 
			column.map { |cell| replaced_by_nil.include?(cell) || /^\s*$/ === cell ? nil : cell }
		end
		
		## Replace Number Values to Integer or Float
		if analyze_type
			ans = ans.map.with_index do |column, i|
				type_of_column = :any
				column.each { |cell| type_of_column = recognize_type(cell, type_of_column) }
				
				# p type_of_column
				case type_of_column
				when :int
					column.map { _1.nil? ? nil : _1.to_i }
				when :float
					column.map { _1.nil? ? nil : _1.to_f }
				else
					column
				end
			end
		end

		return ans
	end

	def recognize_type(str, expected)
		return expected if str.nil?

		order = {:any => 0, :int => 1, :float => 2, :string => 3}
		if /^\s*(-|\+)?\d+\s*$/ === str
			type_of_str = :int
		elsif /^\s*(-|\+)?\d*\.\d*\s*$/ === str || /^\s*(-|\+)?(\d*\.\d+|\d+)(e|E)(-|\+)?\d+\s*$/ === str
			type_of_str = :float
		else
			type_of_str = :string
		end
				
		# p "#{type_of_str}, #{str}" if order[type_of_str] > order[expected]

		return order[type_of_str] > order[expected] ? type_of_str : expected
	end

	# Fix blank or duplicated header
	def check_header(header_array)
		# Check Blank
		ans = header_array.map.with_index do |item, i|
			if item.nil?
				"column#{i}"
			elsif item.kind_of?(String)
				temp = /^\s*$/ === item ? "column#{i}" : item.gsub(/\s+/, "")
				/^\d+$/ === temp ? "column#{i}" : temp
			else
				item.to_s
			end
		end 

		# Check Duplicated Value
		dup_check = (0...(header_array.length)).group_by {|i| ans[i]}
		dup_check.each do |item, i_s|
			if i_s.length > 1
				i_s.each_with_index {|i, index_in_i_s| ans[i] = "#{ans[i]}_#{index_in_i_s}"}
			end
		end

		return ans
	end

	private_class_method :open_excel, :fix_array, :check_header
  
end
