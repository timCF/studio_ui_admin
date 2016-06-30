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
			utils.stringifyEnums( utils.proto.Response.decode64(data) )
		catch error
			"protobuf decode error "+error+" raw data : "+data
	xmlhttpreq: (data, cmd, state) ->
		utils = @
		xhr = new XMLHttpRequest()
		xhr.responseType = "arraybuffer"
		xhr.open('POST', 'http://127.0.0.1:9866', true)
		xhr.onreadystatechange = () ->
			if (xhr.readyState == 4)
				response = utils.decode_proto( proto2base64.encode(xhr.response) )
				if Imuta.is_string(response)
					utils.error(response)
				else
					switch response.status
						when 'RS_error' then utils.error(response.message)
						when 'RS_ok_state' then state.response_state = response.state
				console.log(state.response_state)
		xhr.send(data)
	CMD_get_state: (state) ->
		utils = @
		req = new utils.proto.Request
		req.cmd = 'CMD_get_state'
		req.client_kind = 'CK_admin'
		req.login = ''
		req.password = ''
		utils.xmlhttpreq( utils.proto.Request.encode(req).toArrayBuffer(), req.cmd, state )
	stringifyEnums: (message) ->
		utils = @
		if (message and message.$type and message.$type.children)
			message.$type.children.forEach((child) ->
				field = child.name
				if (message[field] and child.element.resolvedType)
					switch child.element.resolvedType.className
						when 'Enum'
							dict = child.element.resolvedType.children.reduce(((acc, {id: id, name: name}) -> acc[id] = name ; acc), {})
							if child.repeated
								message[field] = message[field].map((el) -> if dict[el] then dict[el] else el)
							else
								if dict[message[field]] then message[field] = dict[message[field]]
						when 'Message'
							if child.repeated
								message[field] = message[field].map((el) -> utils.stringifyEnums(el))
							else
								message[field] = utils.stringifyEnums(message[field]))
		message
