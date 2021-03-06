class ImportsController < ApplicationController
  before_action :set_import, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if request.xhr?
      search_text = params["search_text"] || ""
      imports = Import.all
      imports_count = imports.count
      imports = imports.order('import_at DESC, id DESC').limit(params[:length]).offset(params[:start])
      data = []
      imports.each do |s|
        amount = s.amount
        pay = s.pay_details.sum(:pay)
        data << {
          id: s.id,
          date: s.import_at.strftime('%d-%m-%Y'),
          amount: amount,
          pay: pay,
          owed: amount - pay
        }
      end
      render json: {"aaData" =>  data,"iTotalRecords"=>imports_count,"iTotalDisplayRecords"=>imports_count}, status: 200
    else

    end
  end

  def show
    products = []
    @import.import_details.each do |detail|
      products << [detail, detail.product]
    end
    render json: {:attach=>render_to_string('_view_import', :layout => false, locals:{products: products, import: @import, pay_detail: @import.pay_details.new, pay_details: @import.pay_details.order(:pay_at), payed: @import.amount - @import.pay_details.sum(:pay)})}, status: 200
  end

  def new
    @import = Import.new
    @medicines_select = Product.where(product_type_id: 1).collect{|t| [t.name, t.id]}
    @foods_select = Product.where(product_type_id: 2).collect{|t| [t.name, t.id]}
    respond_with(@import)
  end

  def edit
  end

  def create
    import = Import.new(import_params)
    begin
      import.save
      if import.errors.messages.blank?
        import.pay_details.create(pay: params[:import][:pay], pay_at: Date.today)
        success_message = "<li>Created successfully!</li>"
        render json: {messages: success_message}, status: 200
      else
        error_messages = import.errors.full_messages.map{|err| "<li>#{err}</li>"}
        render json: {messages: error_messages.join("")}, status: 422
      end
    rescue Exception => e
      p "=================="
      p e.message
      error_messages = "<li>Something went swrong</li>"
      render json: {messages: error_messages}, status: 422
    end
    
  end

  def update
    begin
      @import.update(import_params)
      if @import.errors.messages.blank?
        success_message = "<li>Updated successfully!</li>"
        render json: {messages: success_message, pay: @import.pay, owe: @import.amount - @import.pay}, status: 200
      else
        error_messages = @import.errors.full_messages.map{|err| "<li>#{err}</li>"}
        render json: {messages: error_messages.join("")}, status: 422
      end
    rescue Exception => e
      p "==============="
      p e
      render json: {messages: "<li>So qua lon</li>"}, status: 500
    end
  end

  def destroy
    @import.destroy
    respond_with(@import)
  end

  private
    def set_import
      @import = Import.find(params[:id])
    end

    def import_params
      params.require(:import).permit(:import_at, :owe,
                                    import_details_attributes:[
                                      :id, :quantity, :price, :import_id, :product_id])
    end
end
