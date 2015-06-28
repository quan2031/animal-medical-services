//= require iCheck/icheck.min.js
//= require jeditable/jquery.jeditable.js
//= require dataTables/jquery.dataTables.js
//= require dataTables/dataTables.bootstrap.js
//= require dataTables/dataTables.responsive.js
//= require dataTables/dataTables.tableTools.min.js
//= require jqGrid/i18n/grid.locale-el.js
//= require jqGrid/jquery.jqGrid.min.js
//= require jquery-ui/jquery-ui.min.js
var Sale = {
	init: function(){
		this.load_list();
		this.create_sale();
	},
	load_list: function(){
		var url = $('#sales-list').data('target');
		var self = this;
		var table = $('#sales-list')
      .dataTable({
        "responsive": true,
        "bFilter": true,
        "bLengthChange": true,
        "bPaginate": true,
        // "bProcessing": true,
        "iDisplayLength": 10,
         // stateSave: true,
         "oLanguage": {
          "sSearchPlaceholder": "Search",
        },
        "bInfo": true,

        "bServerSide": true,
        "autoWidth": false,
        "aoColumns": [
          {
            "sTitle": 'Date',
            "bSortable": false,
            "sClass": "left",
            "mData": "date",
          },
          {
            "sTitle": 'Customer',
            "bSortable": false,
            "sClass": "left",
            "mData": "customer_name",
          },
          {
            "sTitle": 'Amount',
            "bSortable": false,
            "sClass": "left",
            "mData": "amount",
          },
          {
            "sTitle": 'Pay',
            "bSortable": false,
            "sClass": "left",
            "mData": "pay",
          },
          {
            "sTitle": 'Owe',
            "bSortable": false,
            "sClass": "left",
            "mData": "owed",
          },
          {
            "sTitle": 'Action',
            "bSortable": false,
            "sClass": "left",
            "mData": "id",
            "mRender": self.render_action
          }

        ],
        fnServerData: function( sUrl, aoData, fnCallback ) {
          // tmp = aoData;
          // aoData = CommonFunction.parseSkuFilterParams(aoData);
          // draw = tmp[5];
          // aoData.push({"name":"search", "value": draw.value.value});
          // if(brand_name != ""){
          //   aoData.push({"name": "filter[brand_name]", "value": brand_name});
          // }
          // filter_export = aoData;
          // // Search
                    console.log(aoData);
          aoData = self.parse_data(aoData);

          $.ajax({
            type: "GET",
            url: url,
            data: aoData,
            dataType: 'json',
            success: fnCallback
          })
        },
        fnDrawCallback: function(setting){
          self.do_action();
        }
    });
	},

	parse_data: function(aoData){
		var result = [];
		var tmp = aoData[2].value[0];
		if (tmp.column == 0) {
			result.push({"name": 'sort[date]', 'value': tmp.dir});
		}else if (tmp.column == 1) {
			result.push({"name": 'sort[customer_name]', 'value': tmp.dir});
		}else if (tmp.column == 2) {
			result.push({"name": 'sort[amount]', 'value': tmp.dir});
		}
		tmp = aoData[5].value
		result.push({"name": 'search_text', 'value': tmp.value});
		tmp = aoData[3]
		result.push({"name": 'start', 'value': tmp.value});
		tmp = aoData[4]
		result.push({"name": 'length', 'value': tmp.value});
		return result;
	},

	render_action: function(data, type, full, meta){
		view_btn = "<i class='fa fa-eye view-sale' data-id = '"+data+"'></i>";
		edit_btn = "<i class='fa fa-pencil-square-o edit-sale'></i>"
		return "<div data-id = '"+data+"'>"+view_btn + edit_btn+"</div>";
	},

	do_action: function(){
		$(".view-sale").click(function(){
			id = $(this).data('id');
			$.ajax({
				type: "get",
				dataType: 'json',
				url: "/sales/"+ id,
				success: function(data){
					console.log('OK');
					$('#custom-modal').html(data.attach).show();
					$('#view-sale-detail').modal('show');
					$('#view-sale-detail').on('hidden.bs.modal', function (e) {
						  $('#custom-modal').html("").hide();
						})
				},
				error: function(data){
					console.log('ERROR');
				}
			});
		});
		$(".edit-sale").click(function(){
			console.log('edit');
		});
	},

	create_sale:function(){
    $('#create-sale').click(function(){
      $.ajax({
        type: "POST",
        url: '/sales',
        beforeSend: function(xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
        },
        data: $('#sale-form').serialize(),
        dataType: 'json',
        success: function(data){
          // $('#newSku').fadeOut('slow');
          $('#newMedicine').modal('hide');
          $('#sale-form')[0].reset();
          $('#new-sale-message').html('');
          success_msg = data.messages;
          success_html = '<div class="alert alert-success alert-dismissable">' +
          '<button aria-hidden="true" data-dismiss="alert" class="close" type="button">×</button>' +
          '<ul>'+
          success_msg +
          '</ul>' +
          '</div>' ;
          $('#alert-message').html(success_html);
          $('#sale-list').DataTable().draw();
        },
        error: function(data){
          error_html = '<div class="alert alert-danger alert-dismissable">' +
          '<button aria-hidden="true" data-dismiss="alert" class="close" type="button">×</button>' +
          '<ul>'+
          data.responseJSON.messages +
          '</ul>' +
          '</div>'
          $('#new-sale-message').html(error_html);}
    	});
    });
  },

  add_product: function(){
  	$('.add_fields').click(function(e){
  		time = new Date().getTime();
  		regexp = new RegExp($(this).data('id'), 'g');
  		$(this).closest('form .modal-footer').before(($(this).data('fields').replace(regexp, time)));
  		e.preventDefault();
  	});
  }
};

$(function(){
	Sale.init();
	Sale.add_product();
	$('.i-checks').iCheck({
    checkboxClass: 'icheckbox_square-green',
    radioClass: 'iradio_square-green',
	});
});