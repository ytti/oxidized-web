var number = 1;

function add_file_upload(){
	number++;
	document.getElementById('number').value = number;
	var table = document.getElementById("files");
	var row = table.insertRow(-1);
	var group = row.insertCell(0);
	group.id = "file";
	var file = row.insertCell(1);
	file.id = "file";
	group.innerHTML = '<input type="text" name="group' + number +'" value="default">';
	file.innerHTML = '<input type="file" name="file' + number +'" required >';
	
}
