module.exports = (utils, state) ->
	render_started = false
	jf = require('jsfunky')
	newmsg = () ->
		msg = jf.clone(state.request_template)
		msg.login = state.request_template.login
		msg.password = state.request_template.password
		msg.cmd = 'CMD_ping'
		msg
	create_event = ({id: id, time_from: time_from, time_to: time_to, room_id: room_id, status: status, band_id: band_id}) ->
		m_from = moment(time_from * 1000)
		m_to = moment(time_to * 1000)
		percentfill = Math.abs(time_to - time_from) / 10800
		percentfill = if (percentfill > 1) then 1 else percentfill
		rooms = jf.get_in(state, ["response_state","rooms"])
		this_room = if jf.is_list(rooms) then rooms.filter(({id: rid}) -> rid.compare(room_id) == 0)[0] else null
		bands = jf.get_in(state, ["response_state","bands"])
		this_band = if jf.is_list(bands) then bands.filter(({id: id}) -> id.compare(band_id) == 0)[0] else null
		{
			id: id,
			title: m_from.format('HH:mm')+" - "+m_to.format('HH:mm')+(if this_band then (" "+this_band.name) else ""),
			start: m_from.format('YYYY-MM-DD'),
			end: m_to.format('YYYY-MM-DD'),
			percentfill: percentfill,
			room_id: room_id,
			color: if not(this_room) then state.colors.sesions[status] else (if (status == "SS_awaiting_first") then this_room.color else net.brehaut.Color(this_room.color).setAlpha(0.3).toString())
		}
	long2date = (long) ->
		moment(1000 * parseInt(long.toString())).format('YYYY-MM-DD HH:mm:ss')
	# this shit is one way to refresh events on calendar ...
	utils.rerender_events_coroutine = (prevstate) ->
		# rm html elements and create new state ...
		newstate = jf.reduce(state, {}, (k,v,acc) -> (if (k in ["workday","datepair","calendar","datepairval"]) then acc else jf.put_in(acc, [k], jf.clone(v))))
		newstate.state_calendar_flag = not(state.calendar)
		if not(jf.equal(prevstate, newstate))
			state.rnd = Math.random().toString()
			newstate.rnd = state.rnd
			if state.calendar
				$(state.calendar).fullCalendar('removeEvents')
				lst = state.events.filter((el) ->
					room_pred = ((el.room_id.toString() == state.ids.room.toString()) or ((state.ids.room == false) and (state.ids.location == false)))
					location_pred = ((state.ids.room == false) and ((state.rooms_of_locations[el.room_id.toString()] == state.ids.location.toString()) or (state.ids.location == false)))
					(room_pred or location_pred))
				$(state.calendar).fullCalendar( 'addEventSource', lst)
				console.log("re-render "+lst.length.toString()+" events ... new state is")
				console.log(state)
			setTimeout((() -> utils.rerender_events_coroutine(newstate)), 500)
		else
			setTimeout((() -> utils.rerender_events_coroutine(prevstate)), 500)
	port = ":7772"
	#port = if location.port then ":"+location.port else ""
	bullet = $.bullet((if window.location.protocol == "https:" then "wss://" else "ws://") + location.hostname + port + location.pathname + "bullet")
	utils.bullet = bullet
	utils.newmsg = newmsg
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
			when "RS_notice"
				# prevent callback on hiding popups side-effect
				state.callbacks.close_popup = false
				# hide popups side-effect
				$('#calendarday').modal('hide')
				$('#group_popup').modal('hide')
				$('#week_template_popup').modal('hide')
				utils.notice(data.message)
			when "RS_info"
				utils.notice(data.message)
			when "RS_refresh" then (if state.response_state then utils.CMD_get_state())
			when "RS_ok_state"
				if data.state.sessions then data.state.sessions = data.state.sessions.filter((el) -> el.status != "SS_canceled_soft")
				store.set("login", state.request_template.login)
				store.set("password", state.request_template.password)
				state.request_template.subject.hash = data.state.hash
				state.response_state = data.state
				if (data.state.sessions) then (state.events = data.state.sessions.map(create_event))
				state.dicts.locations = jf.reduce(data.state.locations, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.dicts.instruments = jf.reduce(data.state.instruments, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.dicts.bands = jf.reduce(data.state.bands, {}, (band, acc) -> jf.put_in(acc, [band.id.toString()], band))
				state.dicts.instruments = jf.reduce(data.state.instruments, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.dicts.rooms = jf.reduce(data.state.rooms, {}, ({id: id, name: name}, acc) -> jf.put_in(acc, [id.toString()], name.toString()))
				state.rooms_of_locations = jf.reduce(data.state.rooms, {}, ({id: id, location_id: lid}, acc) -> jf.put_in(acc, [id.toString()], lid.toString()))
				state.ids.admin = state.response_state.admins.filter((el) -> return (el.login == state.request_template.login) && (el.password == state.request_template.password))[0].id
			when "RS_statistics"
				state.statistics = data.statistics
		if state.callbacks.msg then state.callbacks.msg(state, data)
		if not(render_started)
			console.log("start render")
			utils.render_coroutine()
			utils.rerender_events_coroutine(null)
			if not(state.response_state) then $('[tabindex="' + 1  + '"]').focus()
			render_started = true
	utils
