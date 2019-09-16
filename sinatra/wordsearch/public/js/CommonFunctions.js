
/// ------------- 時間整形処理関連 ----------------- //

function formatUIDate(Y, M, D) {
	Y0 = ('000' + Y).slice(-4);
	M0 = ('0' + M).slice(-2);
	D0 = ('0' + D).slice(-2);
	
	return Y0 + '-' + M0 + '-' + D0;
}

function formatUIDateObject(date) {	
	if( Object.prototype.toString.call(date) != "[object Date]") {
		throw "ArgumentFormatException";
	}
	
	return formatUIDate( date.getFullYear(), date.getMonth()+1, date.getDate());
}

function formatUIDatetimeLocal(Y, M, D, h, mi, s)
{
	date = formatUIDate(Y,M,D);
	h0 = ('0' + h).slice(-2);
	mi0 = ('0' + mi).slice(-2);
	s0 = ('0' + s).slice(-2);
	
	return date + "T" + h0 + ":" + mi0 + ":" + s0;
}

function formatUIDatetimeLocalObject(date)
{
	if( Object.prototype.toString.call(date) != "[object Date]") {
		throw "ArgumentFormatException";
	}
	
	return formatUIDatetimeLocal(date.getFullYear(), date.getMonth()+1, date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
}





