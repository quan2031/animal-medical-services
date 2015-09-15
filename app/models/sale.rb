class Sale < ActiveRecord::Base
	belongs_to :customer
	has_many :sale_details, dependent: :destroy
	accepts_nested_attributes_for :sale_details, allow_destroy: true
	validates_presence_of :pay, numericality: true, presence: true
	def amount
		return self.sale_details.sum('price * quantity')
	end
end
