class Array
	# Returns line No. of longest line(not the length of it).
	def longest_line = self.map(&:length).max
end

class String
	# Helpers for IRuby
	def display_ja = self.encode("utf-8")
	def send_ja = self.encode("cp932")

	alias_method :dj, :display_ja
	alias_method :sj, :send_ja
	alias_method :utf, :display_ja
	alias_method :cp, :send_ja
end

