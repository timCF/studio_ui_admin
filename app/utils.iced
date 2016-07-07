proto2base64 = require('base64-arraybuffer')
statestamp = new Date().getTime()
module.exports =
	error: (mess) -> $.growl.error({title: '', message: mess , duration: 20000})
	warn: (mess) -> $.growl.warning({title: '', message: mess , duration: 20000})
	notice: (mess) -> $.growl.notice({title: '', message: mess , duration: 20000})
	info: (mess) -> $.growl({title: '', message: mess , duration: 20000})
	view_put: (state, path, data) -> Imuta.update_in(state, path, (_) -> data)
	view_set: (state, path, ev) ->
		if (ev? and ev.target? and ev.target.value?)
			subj = ev.target.value
			Imuta.update_in(state, path, (_) -> subj)
	set_location: (state, ev) ->
		utils = @
		state.ids.location = false
		state.ids.room = false
		utils.render()
		utils.view_set(state, ["ids","location"], ev)
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
		xhr.open('POST', 'http://127.0.0.1:9866?random='+Math.random(), true)
		xhr.onload = () ->
			response = utils.decode_proto( proto2base64.encode(xhr.response) )
			if Imuta.is_string(response)
				utils.error(response)
			else
				switch response.status
					when 'RS_error' then utils.error(response.message)
					when 'RS_ok_state'
						store.set("login", state.request_template.login)
						store.set("password", state.request_template.password)
						# for log polling
						state.request_template.subject.hash = response.state.hash
						state.response_state = response.state
						statestamp = new Date().getTime()
			console.log(state.request_template)
			console.log(state.response_state)
		xhr.send(data)
	state_coroutine: (state) ->
		utils = @
		# if is auth AND timeout 1.5 min gone - reset hash and reconnect
		# server shuold response in 1 min always ( timeout for long polling )
		if state.request_template and (state.request_template.login != '') and (state.request_template.password != '') and (((new Date().getTime()) - statestamp) > 90000)
			utils.warn("соединение с сервером потеряно, пытаюсь переподключиться ... ")
			state.request_template.subject.hash = ''
			state.response_state = false
			utils.CMD_get_state(state)
		setTimeout((() -> utils.state_coroutine(state)), 1000)
	CMD_get_state: (state) ->
		utils = @
		req = state.request_template
		req.cmd = 'CMD_get_state'
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
	maybe_from_store: (key, defval) ->
		value = store.get(key)
		if value then value else defval
	logout: (state) ->
		store.remove("login")
		store.remove("password")
		state.response_state = false
		if state.request_template
			state.request_template.login = ''
			state.request_template.password = ''
		location.reload()
