class Customer < ActiveRecord::Base
	has_many :animal_groups, dependent: :destroy
	has_many :sales, dependent: :destroy

	def full_name
		"#{self.last_name} #{self.first_name}"
	end
end
