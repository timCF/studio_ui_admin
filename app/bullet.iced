module.exports = (utils, state) ->
	render_started = false
	jf = require('jsfunky')
	newmsg = () ->
		msg = jf.clone(state.request_template)
		msg.login = state.request_template.login
		msg.password = state.request_template.password
		msg.cmd = 'CMD_ping'
		msg
	long2date = (long) ->
		moment(1000 * parseInt(long.toString())).format('YYYY-MM-DD HH:mm:ss')
	port = ':7770' # (if location.port then ":"+location.port else "")
	bullet = $.bullet((if window.location.protocol == "https:" then "wss://" else "ws://") + location.hostname + port + location.pathname + "bullet")
	utils.bullet = bullet
	utils.to_server = (data) ->
		console.log(data)
		bullet.send( utils.encode_proto(data) )
	utils.bullet.onopen = () ->
		if ((state.request_template.login != '') and (state.request_template.password != ''))
			utils.CMD_get_state(state)
		else
			utils.bullet.onheartbeat()
		utils.notice("соединение с сервером установлено")
	utils.bullet.ondisconnect = () -> utils.error("соединение с сервером потеряно")
	utils.bullet.onclose = () -> utils.warn("соединение с сервером закрыто")
	utils.bullet.onheartbeat = () -> utils.to_server(newmsg())
	utils.CMD_get_state = () ->
		msg = newmsg()
		msg.cmd = 'CMD_get_state'
		utils.to_server(msg)
	utils.bullet.onmessage = (data) ->
		data = utils.decode_proto(data)
		console.log(data)
		switch data.status
			when "RS_ok_void" then "ok"
			when "RS_error" then utils.error(data.message)
			when "RS_notice" then utils.notice(data.message)
			#
			#	TODO
			#
			#when "refreshstate" then (if state.auth then utils.get_state())
			when "RS_ok_state"
				store.set("login", state.request_template.login)
				store.set("password", state.request_template.password)
				state.request_template.subject.hash = data.state.hash
				state.response_state = data.state
		if not(render_started)
			console.log("start render")
			utils.render_coroutine()
			if not(state.response_state) then $('[tabindex="' + 1  + '"]').focus()
			render_started = true
	utils
