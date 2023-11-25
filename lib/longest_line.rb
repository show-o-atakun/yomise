class Array
	# Returns line No. of longest line(not the length of it).
	def longest_line = self.map(&:length).max
end