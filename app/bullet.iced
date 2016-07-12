module.exports = (utils, state) ->
	render_started = false
	jf = require('jsfunky')
	newmsg = () ->
		msg = jf.clone(state.request_template)
		msg.login = state.request_template.login
		msg.password = state.request_template.password
		msg.cmd = 'CMD_ping'
		msg
	create_event = ({id: id, time_from: time_from, time_to: time_to, room_id: room_id}) ->
		m_from = moment(time_from * 1000)
		m_to = moment(time_to * 1000)
		{
			title: m_from.format('HH:mm')+" - "+m_to.format('HH:mm'),
			start: m_from.format('YYYY-MM-DD'),
			end: m_to.format('YYYY-MM-DD'),
			percentfill: (time_to - time_from) / 10800,
			room_id: room_id
		}
	long2date = (long) ->
		moment(1000 * parseInt(long.toString())).format('YYYY-MM-DD HH:mm:ss')
	# this shit is one way to refresh events on calendar ...
	utils.rerender_events_coroutine = (prevstate) ->
		# rm html elements and create new state ...
		newstate = jf.reduce(state, {}, (k,v,acc) -> (if (k in ["workday","datepair","calendar"]) then acc else jf.put_in(acc, [k], jf.clone(v))))
		if (state.calendar and not(jf.equal(prevstate, newstate)))
			$(state.calendar).fullCalendar('removeEvents')
			state.events.forEach((el) ->
				room_pred = ((el.room_id.toString() == state.ids.room.toString()) or ((state.ids.room == false) and (state.ids.location == false)))
				location_pred = ((state.ids.room == false) and ((state.rooms_of_locations[el.room_id.toString()] == state.ids.location.toString()) or (state.ids.location == false)))
				if (room_pred or location_pred) then $(state.calendar).fullCalendar( 'renderEvent', el, true ))
			console.log("re-render events ... new state is")
			console.log(state)
			setTimeout((() -> utils.rerender_events_coroutine(newstate)), 500)
		else
			setTimeout((() -> utils.rerender_events_coroutine(prevstate)), 500)
	port = ':7770' # (if location.port then ":"+location.port else "")
	bullet = $.bullet((if window.location.protocol == "https:" then "wss://" else "ws://") + location.hostname + port + location.pathname + "bullet")
	utils.bullet = bullet
	utils.to_server = (data) ->
		console.log(data)
		bullet.send( utils.encode_proto(data) )
	utils.bullet.onopen = () ->
		if ((state.request_template.login != '') and (state.request_template.password != ''))
			utils.CMD_get_state()
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
			when "RS_refresh" then (if state.response_state then utils.CMD_get_state())
			when "RS_ok_state"
				store.set("login", state.request_template.login)
				store.set("password", state.request_template.password)
				state.request_template.subject.hash = data.state.hash
				if (data.state.sessions) then (state.events = data.state.sessions.map(create_event))
				state.response_state = data.state
				state.rooms_of_locations = jf.reduce(data.state.rooms, {}, ({id: id, location_id: lid}, acc) -> jf.put_in(acc, id.toString(), lid.toString()))
		if not(render_started)
			console.log("start render")
			utils.render_coroutine()
			utils.rerender_events_coroutine(null)
			if not(state.response_state) then $('[tabindex="' + 1  + '"]').focus()
			render_started = true
	utils
