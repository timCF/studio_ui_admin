proto2base64 = require('base64-arraybuffer')
lodash = require('lodash')
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
	xmlhttpreq: (data, cmd, state) ->
		utils = @
		xhr = new XMLHttpRequest()
		xhr.responseType = "arraybuffer"
		xhr.open('POST', 'http://127.0.0.1:9866', true)
		xhr.onreadystatechange = () ->
			if (xhr.readyState == 4)
				response = utils.decode_proto(proto2base64.encode(xhr.response))
				console.log(response)
				console.log(utils.stringifyEnumsRecursive(response))
				if Imuta.is_string(response)
					utils.error(response)
				else
					#
					#	TODO !!!
					#
					#switch cmd
					#	when 'CMD_get_state'
					#		state.response_state =
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
		if message.$type
			lodash.forEach(message.$type.children, (child) ->
				type = lodash.get(child, 'element.resolvedType', null)
				if (type and (type.className == 'Enum') and type.children)
					metaValue = lodash.find(type.children, { id: message[child.name] })
					if (metaValue and metaValue.name)
						message[child.name] = metaValue.name)
		message
	stringifyEnumsRecursive: (message) ->
		utils = @
		message = utils.stringifyEnums(message)
		lodash.forEach(message, (subMessage, key) ->
			if (lodash.isObject(subMessage) and subMessage.$type)
				message[key] = utils.stringifyEnumsRecursive(message[key])
			else if Imuta.is_list(subMessage)
				message[key] = subMessage.map((el) -> utils.stringifyEnumsRecursive(el)))
		message
