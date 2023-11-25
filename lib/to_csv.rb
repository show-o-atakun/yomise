require "daru"
require "rover"

class Daru::DataFrame
	def to_csv()
		a = self.to_a.transpose
		
		ans = self.map(&:name).join ","
		self.to_a[0].each do |item|
			ans += "\n"
			ans += item.map{|k, v| v}.join(",")
		end
		
		return ans
	end
	
	def write_csv(path, encoding: nil)
		enc = encoding.nil? ? "" : ":#{encoding}"
		open(path, "w#{enc}") { _1.write to_csv }
	end

	# To avoid bug about adding column to Daru::DataFrame
	def add_vector(vecname, vec)
		self[vecname] = vec
		self.rename_vectors({vecname => vecname})
	end

	### エンコード関連 ###
	# vector_i番目のヘッダー名を読めるようにエンコード
	def encode_vector_name(vector_i)
		if self.vectors.to_a[vector_i].is_a?(String)
			self.vectors.to_a[vector_i].encode Encoding::UTF_8, Encoding::Windows_31J
		end
	end
  
	# すべての列に対し上記を実施
	def encode_vectors!
		self.vectors = Daru::Index.new(Range.new(0, self.vectors.size-1).map {|i| encode_vector_name i })
	end

	# ver.0.3.8~ Convert Daru::DF encoding
	def convert_enc!(from: "cp932", to: "utf-8")
		self.vectors.each do |col|
			self[col] = self[col].each {|val| val.encode!(to, from_encoding: from) if val.is_a?(String)}
		end
		
		self.encode_vectors!
	end
	#####################

	# rover not suppoted yet about indexing
	def set_index!(indexcolumn)
		self.index = self[indexcolumn]
	end

	# To revice pivot index
	def simplify_multi_index(vector_names_ary)
		self.vectors = Daru::Index.new(vector_names_ary)
		self.index = Daru::Vector.new(self.index.to_a.map{_1[0]})
	end

	alias_method :addvec, :add_vector
end

class Rover::DataFrame
	# Rover#to_csv is already exist.

	def write_csv(path, encoding: nil)
		enc = encoding.nil? ? "" : ":#{encoding}"
		open(path, "w#{enc}") {|f| f.write self.to_csv}
	end
end
