class SalesController < ApplicationController
  before_action :set_sale, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if request.xhr?
      search_text = params["search_text"] || ""
      sales = Sale.joins(:customer).where("customers.last_name LIKE ? OR customers.first_name LIKE ?", "%#{search_text}%","%#{search_text}%");
      if params[:date_from].present? && params[:date_to].present?
        sales = sales.where("sale_at >= ? and sale_at <= ?", params[:date_from].to_date, params[:date_to].to_date)
      elsif params[:date_from].present? && !params[:date_to].present?
        sales = sales.where("sale_at >= ?", params[:date_from].to_date)
      elsif !params[:date_from].present? && params[:date_to].present?
        sales = sales.where("sale_at <= ?", params[:date_to].to_date)
      end
      sales_count = sales.count
      sales = sales.order("sales.#{params[:sort].keys.first} #{params[:sort].values.first}") if params[:sort][:sale_at]
      sales = sales.select("sales.*, customers.*, concat(customers.last_name, ' ', customers.first_name) as full_name").order("#{params[:sort].keys.first} #{params[:sort].values.first}") if params[:sort][:full_name]
      sales = sales.limit(params[:length]).offset(params[:start])
      data = []
      sales.each do |s|
        c = s.customer
        amount = s.amount
        pay = s.pay_details.sum(:pay)
        data << {
          id: s.id,
          date: s.sale_at.strftime('%d-%m-%Y'),
          customer_name:c.full_name,
          customer_id: c.id,
          amount: amount,
          pay: pay,
          owed: amount - pay
        }
      end
      render json: {"aaData" =>  data,"iTotalRecords"=>sales_count,"iTotalDisplayRecords"=>sales_count}, status: 200
    else
      # @product = product.new
      # @categories_select = productCategory.all.collect{|c| [c.name, c.id]}
      # @specifications_select = productSpecification.all.collect{|t| [t.product_specification_type.name, t.id]}
      # @specification_types_select = productSpecificationType.all.collect{|t| [t.name, t.id]}
      # @specification = productSpecification.new
      # @specification.product_specification_type = productSpecificationType.new
      # @category = productCategory.new
    end
  end

  def show
    products = []
    @sale.sale_details.each do |detail|
      products << [detail, detail.product]
    end
    render json: {:attach=>render_to_string('_view_sale', :layout => false, locals:{products: products, sale: @sale, pay_detail: @sale.pay_details.new, pay_details: @sale.pay_details.order(:pay_at), payed: @sale.amount - @sale.pay_details.sum(:pay)})}, status: 200
  end

  def new
    @sale = Sale.new
    @foods_select = Product.where(product_type_id: 2).collect{|t| [t.name, t.id]}
    @medicines_select = Product.where(product_type_id: 1).collect{|t| [t.name, t.id]}
    @customers_select = Customer.all.collect{|t| [t.full_name, t.id]}
    respond_with(@sale)
  end

  def edit
  end

  def create
    sale_params[:sale_details_attributes][:quantity] = 0 unless  sale_params[:sale_details_attributes][:quantity] or !sale_params[:sale_details_attributes][:quantity].is_a? Numeric
    sale_params[:sale_details_attributes][:price] = 0 unless  sale_params[:sale_details_attributes][:price] or !sale_params[:sale_details_attributes][:price].is_a? Numeric
    sale = Sale.new(sale_params)
    begin
      sale.save
      if sale.errors.messages.blank?
        sale.pay_details.create(pay: params[:sale][:pay], pay_at: Date.today)
        success_message = "<li>Created successfully!</li>"
        render json: {messages: success_message}, status: 200
      else
        error_messages = sale.errors.full_messages.map{|err| "<li>#{err}</li>"}
        render json: {messages: error_messages.join("")}, status: 422
      end
    rescue Exception => e
      error_messages = "<li>Something went swrong</li>"
      render json: {messages: error_messages}, status: 422
    end
  end

  def update
    begin
      @sale.update(sale_params)
      if @sale.errors.messages.blank?
        success_message = "<li>Updated successfully!</li>"
        render json: {messages: success_message, pay: @sale.pay, owe: @sale.amount - @sale.pay}, status: 200
      else
        error_messages = @sale.errors.full_messages.map{|err| "<li>#{err}</li>"}
        render json: {messages: error_messages.join("")}, status: 422
      end
    rescue Exception => e
      p "==============="
      p e
      render json: {messages: "<li>So qua lon</li>"}, status: 500
    end

  end

  def destroy
    @sale.destroy
    respond_with(@sale)
  end

  private
    def set_sale
      @sale = Sale.find(params[:id])
    end

    def sale_params
      params.require(:sale).permit(:sale_at, :owe, :customer_id,
        sale_details_attributes:[
          :id, :quantity, :price, :sale_id, :product_id ])
    end
end
