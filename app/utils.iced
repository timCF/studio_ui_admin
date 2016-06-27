proto2base64 = require('base64-arraybuffer')
module.exports =
	error: (mess) -> $.growl.error({ message: mess , duration: 20000})
	warn: (mess) -> $.growl.warning({ message: mess , duration: 20000})
	notice: (mess) -> $.growl.notice({ message: mess , duration: 20000})
	info: (mess) -> $.growl({ message: mess , duration: 20000})
	view_set: (state, path, ev) ->
		if (ev? and ev.target? and ev.target.value?)
			subj = ev.target.value
			Imuta.update_in(state, path, (_) -> subj)
	view_swap: (state, path) ->
		Imuta.update_in(state, path, (bool) -> not(bool))
	view_files: (state, path, ev) ->
		if (ev? and ev.target? and ev.target.files? and (ev.target.files.length > 0))
			Imuta.update_in(state, path, (_) -> [].map.call(ev.target.files, (el) -> el))
			console.log(Imuta.access_in(state, path))
	decode_proto: (data) ->
		utils = @
		try
			utils.proto.Response.decode64(data)
		catch error
			"protobuf decode error "+error+" raw data : "+data
	xmlhttpreq: (data) ->
		utils = @
		xhr = new XMLHttpRequest()
		xhr.responseType = "arraybuffer"
		xhr.open('POST', 'http://127.0.0.1:9866', true)
		xhr.onreadystatechange = () -> if (xhr.readyState == 4) then console.log(utils.decode_proto(proto2base64.encode(xhr.response)))
		xhr.send([''])
