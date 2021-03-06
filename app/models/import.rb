class Import < ActiveRecord::Base
	has_many :import_details, dependent: :destroy
	has_many :pay_details, dependent: :destroy, :class_name =>"PayDetail", as: :payable
	accepts_nested_attributes_for :import_details, allow_destroy: true
	validates_presence_of :pay, numericality: true, presence: true
	def amount
		return self.import_details.sum('price * quantity')
	end
end
