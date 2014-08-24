function submit_filter_form(id){
	document.getElementById(id).submit();
};

function order(o,form){
	document.getElementById("order").value = o;
	document.getElementById(form).submit();
};
function order2(o,form){
	document.getElementById("order2").value = o;
	document.getElementById(form).submit();
};
function view(id){
  var timelogs = document.getElementById("logs");
  var overview = document.getElementById("overview");
  var transactions = document.getElementById("transactions");

  if(id == 0){
	overview.style.display = "";
	transactions.style.display = "none";
	timelogs.style.display = "none";
	document.getElementById("overview_link").className  = "selected";
	document.getElementById("transactions_link").className  = "";
	document.getElementById("timelogs_link").className  = "";
  }else if(id == 1){
	overview.style.display = "none";
	transactions.style.display = "";
	timelogs.style.display = "none";
	document.getElementById("overview_link").className  = "";
	document.getElementById("transactions_link").className  = "selected";
	document.getElementById("timelogs_link").className  = "";
  }else{
	overview.style.display = "none";
	transactions.style.display = "none";
	timelogs.style.display = "";
	document.getElementById("overview_link").className  = "";
	document.getElementById("transactions_link").className  = "";
	document.getElementById("timelogs_link").className  = "selected";
  }
}
function view_trans(id){
  var real_trans = document.getElementById("real_trans");
  var plan_trans = document.getElementById("plan_trans");

  if(id == 0){
	real_trans.style.display = "";
	plan_trans.style.display = "none";
	document.getElementById("real_link").className  = "selected";
	document.getElementById("plan_link").className  = "";
  }else{
	real_trans.style.display = "none";
	plan_trans.style.display = "";
	document.getElementById("real_link").className  = "";
	document.getElementById("plan_link").className  = "selected";
  }
}
$(function () {
    	if($('#amount_type').val() != "between"){
		$('#between').hide();
	}
    	if($('#date_type').val() != "between"){
		$('#between2').hide();
	}
	$('#amount_type').change(function(){
		if($('#amount_type').val() != "between"){
			$('#between').hide();
			$('#amount2').val('');
		}else{
			$('#between').show();
		}
	});
	$('#date_type').change(function(){
		if($('#date_type').val() != "between"){
			$('#between2').hide();
			$('#date2').val('');
		}else{
			$('#between2').show();
		}
	});
});
$(function () {
	$( "#missing_salary" ).dialog();
	$( document ).tooltip();
});
